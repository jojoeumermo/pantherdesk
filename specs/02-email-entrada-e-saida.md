# Spec 02 — Entrada e saída de e-mail

Status: **rascunho v0.2** (2026-10-26). Baseado na documentação pública dos 7
projetos, nas decisões transversais D01–D37 e nos requisitos da operação EARJ
(spec 13, que prevalece). Evidências de runtime pendentes, marcadas como
**[evidência pendente: cenário]**. Vocabulário: spec 01. Fixtures de teste:
`specs/fixtures/email/` (escritas por nós; os IDs `fxNN` abaixo se referem a elas).

Mudanças na v0.2:
- **Conversa paralela por e-mail** (§9.2): saída, marcador de assunto próprio,
  threading, efeito no estado (em espera → aberto), encerramento com
  quarentena (spec 13 Δ17).
- Regras de **quando o solicitante recebe e-mail** (§9.1): resposta pública,
  resposta que resolve com convite de avaliação num único e-mail, mudança só
  de estado sem e-mail (spec 13 Δ12, Δ15).
- **Chat**: respostas não lidas no widget em 2 minutos saem por e-mail,
  agrupadas, sem convite duplicado (§9.3, spec 13 Δ16).
- Seguidores nunca entram em Cc; o solicitante nunca vê "em espera"; marca da
  conta nos e-mails ao solicitante; assunto segue o assunto atual do ticket,
  inclusive quando alterado por macro (spec 13 Δ3, Δ6, Δ10, Δ25).
- Participante **não confirmado**: a mensagem dele não muda o estado, não
  conta como resposta do cliente e fica oculta no portal até a confirmação
  (achado 1.46 da revisão).
- Bounce: só invalida o endereço do relatório se ele foi destinatário da
  mensagem que falhou; EM-22 ajustado à fixture (achado 3.6).
- Auto-resposta encadeada não acrescenta o remetente como participante
  (achado 3.7).
- Calendário de reenvio SMTP definido em instantes contados a partir da 1ª
  tentativa; EM-55 refeito e EM-56 novo (achado 2.5).
- Anexos de saída acima do limite de e-mail seguem por link (o editor aceita
  até 50 MB por arquivo; spec 13 Δ19).
- Resposta de agente a e-mail de notificação continua nota interna por padrão
  (D02), agora com casos de teste.
- Novos casos EM-13, EM-14, EM-37 a EM-39, EM-44, EM-56 a EM-59, EM-60 a
  EM-69, EM-70 a EM-76 e EM-80; nova seção de questões abertas.
- Ajustes D23–D37: a confirmação de abertura é um único gatilho da spec 05 §6
  para todos os canais, com limite de 3 por endereço não verificado a cada
  24 h e sem eco do texto (D25); mensagens de conversa paralela saem nos
  webhooks no tipo de evento das notas internas, com a indicação "conversa
  paralela", nunca em eventos de mensagem pública (D37). EM-29 ajustado;
  novos casos EM-81 a EM-83; questão aberta 1 respondida e retirada.

---

## 1. Problema

Transformar um fluxo de mensagens de e-mail, que não é confiável, em operações
corretas e **idempotentes** sobre tickets:

1. **classificar** cada mensagem: pedido novo, continuação de ticket existente,
   continuação de uma conversa paralela, resposta automática, aviso de falha
   de entrega (bounce), envio em massa, spam ou laço gerado pelo próprio
   sistema;
2. **encadear** (threading) a continuação ao ticket certo, e à conversa certa
   dentro dele, mesmo quando o cliente de e-mail remove cabeçalhos ou edita o
   assunto, **sem falsos positivos**: anexar ao ticket errado vaza dados entre
   clientes;
3. **identificar as pessoas**: remetente, Cc, solicitante original de um
   e-mail encaminhado, remetente estranho numa conversa existente;
4. **extrair conteúdo seguro**: escolher o corpo, sanitizar HTML, resolver
   imagens inline, guardar anexos, decodificar charsets e separar o texto citado;
5. **não perder nem duplicar** mensagens quando o servidor de e-mail falha ou
   quando a mesma mensagem chega duas vezes;
6. **não gerar laços** de respostas automáticas com outros robôs nem consigo
   mesmo;
7. **enviar** respostas que voltem a se encadear corretamente, só para quem
   deve recebê-las.

---

## 2. Ingestão

### 2.1 Fontes
- **Caixa de entrada** configurável por conta: servidor IMAP, pasta de leitura,
  pasta de destino após processar, grupo padrão. Várias caixas podem existir
  (a EARJ usa duas); cada uma tem um **endereço de suporte** e um grupo padrão.
- **Entrega direta**: endpoint HTTP autenticado que recebe a mensagem bruta,
  para uso por um MTA ou provedor de entrada. Cai no **mesmo pipeline** do IMAP.
- Polling IMAP a cada 60 s por caixa (configurável, mínimo 30 s).

### 2.2 Ciclo de uma mensagem
1. Ler a mensagem bruta do servidor.
2. **Gravar o bruto** (bytes originais) em armazenamento durável **antes** de
   processar. Todo processamento pode ser refeito a partir desse bruto.
3. Calcular a **chave de idempotência** (§2.3). Se já foi processada, encerrar.
   Ainda assim a mensagem é movida (passo 5), sem novo efeito.
4. Processar (§3 a §8) numa transação: ticket, mensagem, anexos e auditoria
   são gravados juntos, ou nada é gravado.
5. Só depois do sucesso, **mover** a mensagem no servidor IMAP para a pasta de
   processadas.

Por que mover em vez de apagar ou de depender de "não lida": os projetos
analisados documentam modos de perda em todas essas opções. Uma mensagem
marcada como lida por outro cliente nunca entra, e apagar antes de confirmar
perde a mensagem se o processamento falhar. Um dos projetos admite gerar
duplicatas quando deixa as mensagens na caixa.

### 2.3 Idempotência
- Chave = (caixa, Message-ID normalizado). A normalização tira espaços e
  `<>` e põe o domínio em minúsculas; a parte local é preservada.
- Mensagem sem Message-ID: chave = (caixa, hash SHA-256 do bruto).
- A mesma chave nunca produz um segundo ticket nem uma segunda mensagem.
- Uma mensagem com **o mesmo Message-ID e conteúdo diferente** também é
  tratada como duplicata. Fica registrado um aviso operacional, porque isso
  indica cliente de e-mail defeituoso ou ataque.

### 2.4 Limites
- Tamanho máximo da mensagem recebida: 25 MB (configurável). Acima disso: não
  processar o conteúdo e criar uma **mensagem de sistema interna** no ticket
  encadeado, ou no novo ticket, informando que uma mensagem grande foi
  recusada, com remetente e assunto. Não responder automaticamente ao
  remetente no MVP.
- Mensagem que não pôde ser interpretada (MIME quebrado): vai para
  **quarentena** com o motivo; o admin pode reprocessá-la ou descartá-la.
- **Quarentena** (valem as mesmas regras para todos os motivos: spam,
  automática sem ticket, desconhecido recusado, agente sem acesso, formulário
  suspeito, MIME quebrado, bounce órfão, conversa paralela encerrada): guarda
  o bruto e o motivo por **30 dias** (configurável). Depois disso, o item é
  apagado automaticamente. Liberar um item reprocessa a mensagem pelo pipeline
  inteiro, pulando apenas a etapa que a colocou na quarentena.

---

## 3. Classificação (ordem fixa)

A ordem importa porque cada etapa pode encerrar o processamento. Os dois
projetos com o pipeline mais explícito seguem uma sequência parecida.

| # | Etapa | Regra | Efeito |
|---|---|---|---|
| 1 | Laço próprio | O Message-ID termina no nosso domínio de envio **ou** a mensagem traz o nosso cabeçalho de laço **ou** o remetente é um endereço de suporte da própria conta | Registrar no log de ingestão e **descartar**: nenhum ticket, nenhuma mensagem, nenhuma auto-resposta |
| 2 | Bounce | `multipart/report; report-type=delivery-status` **ou** remetente do tipo mailer-daemon/postmaster com corpo de falha | Ver §7 |
| 3 | Automático | `Auto-Submitted` presente e diferente de `no`; ou `Precedence` = bulk, junk, list ou auto_reply; ou `X-Autoreply`/`X-Autorespond`; ou `X-Auto-Response-Suppress` presente; ou `List-Id`/`List-Unsubscribe` presentes | Marcar a mensagem como **automática** e seguir para o threading com as restrições de §6 |
| 4 | Spam | `X-Spam-Flag: YES` vindo do MTA, ou remetente, domínio ou IP de origem na lista de bloqueio da conta | **Quarentena** (spam); nenhum ticket, nenhuma auto-resposta |
| 5 | Threading | §4 | Continuação (conversa principal ou paralela) ou ticket novo |
| 6 | Pessoas | §5 (não se aplica a conversas paralelas, §9.2) | Solicitante, participantes |
| 7 | Conteúdo | §8 | Corpo, anexos |

Nenhum dos projetos respeita nativamente a marca de spam do MTA; nos que
documentam o assunto, isso exige um filtro criado pelo admin. Respeitar a marca
é barato e evita poluir a fila. A quarentena permite resgatar falsos positivos.

---

## 4. Threading (encadeamento)

### 4.1 Identificadores
- Toda mensagem gravada, **recebida ou enviada**, da conversa principal ou de
  uma conversa paralela, guarda seu Message-ID e sabe a que conversa pertence.
- Mensagens **enviadas** pelo PantherDesk usam Message-ID gerado por nós, no
  formato `<{token-opaco}@{domínio-de-envio}>`. O token é aleatório (no mínimo
  128 bits) e não revela o número do ticket nem a conversa.
- Cada ticket tem um **marcador de assunto** `[PD-{número}]`. Cada conversa
  paralela tem o marcador `[PD-{número}/{k}]`, em que k é a ordem da conversa
  paralela dentro do ticket (1, 2, …). O marcador é validado: o número (e, se
  houver, a conversa k) precisa existir na conta.

### 4.2 Algoritmo (camadas, na ordem)
1. **In-Reply-To**: se contém um Message-ID conhecido na conta, a conversa
   (principal ou paralela) dona dessa mensagem é o alvo.
2. **References**: percorrer os Message-IDs **do mais recente para o mais
   antigo**; o primeiro conhecido na conta define o alvo.
3. **Marcador no assunto**: `[PD-N/k]` com N e k existentes → conversa
   paralela k do ticket N; `[PD-N]` com N existente → conversa principal do
   ticket N. Um marcador com N ou k inexistente é ignorado.
4. **Endereço por ticket** (opcional, desligado por padrão): se o destinatário
   é `suporte+{token}@domínio` e o token pertence a um ticket (ou a uma
   conversa paralela), esse é o alvo.
5. Nada encontrado → **ticket novo**.

Regras:
- **Nunca** encadear por semelhança de assunto ("Re: mesmo assunto" sem
  cabeçalho nem marcador vira ticket novo). Encadear por assunto é a principal
  fonte de falsos positivos, e os projetos que oferecem métodos extras de
  casamento alertam justamente para isso.
- Se as camadas 1–2 e a camada 3 apontarem para **alvos diferentes** (outro
  ticket, ou outra conversa do mesmo ticket), vale a dos cabeçalhos (1–2),
  porque o assunto é editável pelo usuário. Fica um aviso na mensagem para o
  agente ("o marcador no assunto aponta para #M").
- Message-IDs referenciados que pertencem a **outra conta** são ignorados,
  como se não existissem.
- Se o alvo está **mesclado**, seguir o ponteiro até o ticket final (spec 01
  §6). As conversas paralelas foram junto para o destino.
- Se o alvo é a conversa principal de um ticket **fechado**, aplicar a
  política do grupo (spec 01 §4.4). Se o alvo é uma conversa paralela, a
  política não se aplica (§9.2).

Comparação: a âncora principal varia entre os projetos. Três usam o marcador no
assunto, que sobrevive a clientes de e-mail que perdem os cabeçalhos. Outros
três usam cabeçalhos ou um Reply-To exclusivo por conversa, que sobrevivem a
quem edita o assunto. Combinar as duas âncoras, com precedência para os
cabeçalhos, cobre os dois casos.

---

## 5. Pessoas

Estas regras valem para a conversa principal. Mensagens que encadeiam numa
conversa paralela seguem a §9.2.

| Situação | Regra |
|---|---|
| Remetente desconhecido, ticket novo | Cria pessoa com o endereço (não verificado) e o nome de exibição decodificado; ela vira solicitante. Configurável por caixa: "aceitar desconhecidos" (padrão sim). Com "não", a mensagem vai para quarentena. |
| `Reply-To` diferente de `From` num ticket novo | O solicitante é o `From`; o `Reply-To` é guardado na mensagem. As respostas vão para o `Reply-To`. |
| Endereços em `Cc` (e em `To`, exceto os de suporte) | Viram **participantes** (confirmados) do ticket; pessoas desconhecidas são criadas. O solicitante **não** muda. |
| Participante responde | A mensagem entra com o participante como autor; o solicitante não muda. |
| Remetente que não é solicitante nem participante responde num ticket encadeado | A mensagem é anexada com a marca "remetente novo na conversa". O remetente entra como participante **não confirmado**: não vê o ticket no portal e não recebe e-mails até um agente confirmar. Isso impede que alguém se infiltre numa conversa só por ter um Message-ID e assim leia o histórico. Enquanto não houver confirmação, a mensagem dele **fica oculta no portal**, **não muda o estado**, não conta como resposta do cliente para SLA e métricas, não dispara automações de "mensagem do cliente" e gera uma notificação ao responsável (sem responsável, ao grupo; spec 01 §2) pedindo confirmação. Se o agente confirmar, as mensagens já gravadas passam a aparecer no portal, sem efeito retroativo no estado ou no SLA. Se recusar, a pessoa sai do ticket e a mensagem continua oculta no portal. |
| Agente com acesso só de **leitura** ao grupo responde por e-mail | A mensagem vira **nota interna** (spec 06). |
| Agente **sem acesso** ao grupo responde por e-mail | Quarentena com o motivo "agente sem acesso"; nada é gravado no ticket. |
| Agente com escrita responde a um e-mail de notificação a partir do endereço cadastrado | A mensagem vira **nota interna** por padrão (D02). Uma resposta pública acidental vaza informação para o cliente, o que é pior do que uma nota que precisa ser reenviada. A conta pode mudar o padrão para "pública". Como nota, ela não conta como primeira resposta (spec 05, spec 11); com a conta em "pública", conta. |
| E-mail chega de um endereço de agente **sem** encadear | Ver encaminhamento, abaixo. |
| **Encaminhamento por agente**: remetente é agente e a mensagem contém uma parte `message/rfc822` ou um bloco de encaminhamento reconhecível | Ticket novo com o **remetente da mensagem original** como solicitante; o agente fica registrado como quem criou; a nota do agente (texto acima do encaminhamento) vira nota interna. |
| Endereço já marcado como inválido | Continua podendo **enviar** para nós; respostas para ele não são enviadas e o agente é avisado. |

Contraste: num dos projetos analisados, quem está em Cc e responde **passa a
ser o cliente** da conversa. O PantherDesk evita isso de propósito: o
solicitante só muda por ação explícita de um agente.

---

## 6. Respostas automáticas e anti-laço

Os projetos que documentam o tema **gravam** a mensagem automática e apenas
suprimem a resposta automática de volta. Um deles limita, além disso, o volume
de auto-respostas por destinatário por dia.

Regras do PantherDesk para mensagens classificadas como **automáticas** (§3,
etapa 3):
- Encadeada a um ticket existente (ou a uma conversa paralela): gravar como
  **mensagem de sistema interna** na conversa encadeada; não muda estado, não
  conta como resposta do cliente para o SLA e **não** dispara automações de
  "cliente respondeu".
- A etapa de pessoas (§5) **não** roda para mensagens automáticas: o
  remetente não vira participante (confirmado ou não) e a marca "remetente
  novo na conversa" não se aplica, seja quem for o remetente.
- Não encadeada: **não** cria ticket. Vai para a quarentena com o motivo
  "automática sem ticket". Isso cobre newsletters e listas.
- **Nunca** dispara auto-resposta nem notificação para o remetente.

Regras para o que **nós** enviamos:
- A confirmação de abertura tem **um mecanismo só**: o gatilho de criação da
  spec 05 §6, que cobre todos os canais (e-mail, portal, formulário de
  visitante e chat; D25). Esta spec não envia nenhuma confirmação própria.
  Quando o solicitante tem endereço **não verificado**, a confirmação não
  repete o texto recebido (assunto, corpo, nome), traz só o número e o link de
  convidado e é limitada a **3 por endereço a cada 24 h**, além do limite
  geral abaixo (regras do canal na spec 03 §4.6).
- Toda auto-resposta e notificação de sistema (inclusive as confirmações de
  abertura dentro e fora do horário comercial, que são gatilhos da spec 05)
  leva `Auto-Submitted: auto-replied` (resposta a uma mensagem) ou
  `auto-generated` (notificação espontânea) e o nosso cabeçalho de laço, com o
  identificador da conta.
- Respostas escritas por agentes, inclusive em conversas paralelas, **não**
  levam `Auto-Submitted`.
- Nunca enviar auto-resposta para endereços de sistema: mailer-daemon,
  postmaster, noreply, no-reply, bounce, ou o próprio endereço de suporte.
- **Limite**: no máximo 10 auto-respostas por destinatário por 24 h por conta.
  Acima disso, suprimir e registrar evento.

---

## 7. Bounces

- O bounce é encadeado ao ticket (e à conversa) da mensagem que falhou,
  buscando o Message-ID original nos cabeçalhos devolvidos dentro do
  relatório. Entra como **mensagem de sistema interna**; o estado do ticket
  não muda.
- **Falha permanente** (código de status 5.x.x): marca como **inválido** o
  endereço do destinatário indicado no relatório, **desde que** esse endereço
  tenha sido destinatário da mensagem que falhou. Envios futuros a ele são
  suprimidos e o agente vê um aviso no ticket. Um agente pode reativar o
  endereço.
- Se o destinatário do relatório **não** foi destinatário da mensagem que
  falhou, nenhum endereço é invalidado; a mensagem de sistema leva o aviso
  "destinatário do relatório não confere com a mensagem original". Isso evita
  que um relatório forjado invalide endereços de terceiros.
- Exceção: o **link de acesso ao portal** (spec 07) é enviado mesmo para um
  endereço inválido, porque quem pediu o link foi a própria pessoa. Se o link
  for usado, o endereço volta a ser válido automaticamente, com evento de
  auditoria.
- **Falha temporária** (4.x.x): só registra; não marca o endereço.
- Bounce que não encadeia vai para a quarentena (bounce órfão).

---

## 8. Conteúdo

| Tema | Regra |
|---|---|
| Escolha do corpo | Preferir a parte HTML **sanitizada**; usar texto puro quando não houver HTML. Guardar as duas versões quando existirem. |
| Sanitização | Allowlist de tags e atributos de formatação. Remover script, style, iframe, object, embed, form, atributos de evento (`on*`), URLs `javascript:` e `data:` (exceto imagens), e imagens externas, que são substituídas por um aviso "imagem externa bloqueada" com opção de mostrar. |
| Imagens inline | Partes com `Content-ID` referenciadas por `cid:` viram anexos inline; o corpo aponta para o anexo interno. Inline não referenciado vira anexo comum. |
| Anexos | Gravados com nome original (decodificado), tipo e tamanho; conteúdo em armazenamento de objetos, com hash. Anexos idênticos (mesmo hash) na mesma conta podem compartilhar armazenamento. |
| Charset | Decodificar o corpo conforme `charset` e `Content-Transfer-Encoding`; cabeçalhos com encoded-words (RFC 2047); nomes de anexo com RFC 2231. Charset inválido ou desconhecido → tentar UTF-8, depois ISO-8859-1, e marcar a mensagem com "decodificação aproximada". |
| Texto citado | Separar, sem apagar: (1) cortar no nosso separador de resposta, que vai em todo e-mail que enviamos; (2) senão, nos padrões "Em … escreveu:" e "On … wrote:" e no bloco final de linhas iniciadas por `>`. A parte citada fica **recolhida** na interface e completa no bruto. Num dos projetos, texto escrito no meio da citação some; por isso o original sempre fica acessível. |
| Encaminhado como anexo | `message/rfc822` é guardado como anexo `.eml` e também usado na regra de encaminhamento por agente (§5). |

---

## 9. Saída

- **From**: o endereço de suporte da caixa do grupo, com nome de exibição
  "{nome do agente} via {nome da conta}". Mensagem de uma identidade de
  integração: "{nome da integração} via {nome da conta}". Notificação de
  sistema: só "{nome da conta}".
- **Reply-To**: o endereço de suporte. Com o endereço por ticket ligado, usa
  `suporte+{token}@domínio`.
- **Message-ID**: §4.1. **In-Reply-To**: o Message-ID da última mensagem pública
  do cliente nesse ticket, se houver. **References**: a cadeia conhecida do
  ticket, limitada às 20 mais recentes, terminando na mensagem respondida.
- **Assunto**: `Re: {assunto atual do ticket} [PD-{número}]`. O assunto atual
  é o do ticket no momento do envio, que um agente ou uma macro pode ter
  alterado (spec 05); o marcador nunca sai. Não duplicar `Re:` nem o marcador.
  Assunto longo é truncado em 150 caracteres antes do marcador.
- **Corpo**: começa pelo separador de resposta (uma linha curta pedindo que o
  cliente responda acima dela); depois a resposta; depois, opcionalmente, um
  histórico resumido só com mensagens públicas.
- **Marca**: e-mails ao solicitante e aos participantes levam a marca da conta
  (logo, nome e cores; spec 13 Δ25). Notificações a agentes usam a identidade
  do PantherDesk.
- **Link do ticket**: cada destinatário recebe o seu próprio link de acesso
  como convidado, que abre só aquele ticket (regras na spec 07). Por isso
  cada destinatário recebe uma cópia individual da mensagem. O Message-ID é o
  mesmo em todas as cópias; o que muda é só o link (e o convite de avaliação,
  §9.1).
- **Destinatários**: `To` = solicitante; `Cc` = participantes **confirmados**
  com endereço válido. **Seguidores nunca** entram em `To` ou `Cc` (eles
  recebem notificações, spec 09). Notas internas, mensagens de sistema
  internas e conversas paralelas **nunca** saem por e-mail para o solicitante
  nem para os participantes.
- **Anexos de saída**: o editor aceita arquivos de até 50 MB (limite da conta;
  spec 13 Δ19), mas um e-mail só leva anexos até o limite de envio (padrão
  25 MB somando todos, configurável). Se a soma passar do limite, **nenhum**
  anexo vai no e-mail: o corpo lista os arquivos e informa que estão no
  ticket, acessíveis pelo link do destinatário. Os anexos continuam no ticket.
- **Falha de envio** (SMTP temporário): novas tentativas nos instantes 1, 5,
  15 e 60 minutos contados a partir da **1ª tentativa** e, depois, a cada hora
  (120, 180, … min) até 24 h. Se a tentativa de 60 min também falhar, o
  agente é avisado. Se a última tentativa (24 h) falhar, é falha definitiva:
  aviso no ticket. Falha permanente do servidor (5.x.x na sessão SMTP) é
  definitiva na hora. Cada mensagem gera **um único** envio efetivo.

### 9.1 Quando o solicitante recebe e-mail

Regras da spec 13 Δ12, sobre o que a ação do agente envia por si mesma (os
gatilhos da spec 05 podem enviar outros e-mails, sempre como mensagens de
sistema):

| Ação | E-mail |
|---|---|
| Resposta pública | um e-mail ao solicitante e aos participantes (§9) |
| Resposta pública com mudança para **resolvido** no mesmo envio | **um único** e-mail com a resposta; a cópia do **solicitante** traz também o convite de avaliação, quando o convite se aplica (spec 13 Δ15: pesquisa ligada no grupo, endereço válido, ticket não marcado como spam, no máximo um convite por ticket a cada 24 h). Os participantes recebem a resposta sem convite. Nunca dois e-mails seguidos |
| Mudança de estado ou de campo **sem** mensagem pública (inclui resolver sem resposta) | nenhum e-mail e nenhum convite |
| Nota interna, mensagem em conversa paralela, mensagem de sistema interna | nenhum e-mail ao solicitante nem aos participantes |
| Ticket de chat | §9.3 |

- Os e-mails ao solicitante nunca mostram o termo "em espera": quando o estado
  aparece no texto, em espera aparece como "em andamento" (spec 01 §4.1).
- Menções (spec 09) não existem em resposta pública, então nunca aparecem num
  e-mail ao solicitante.

### 9.2 Conversa paralela

Linha de e-mail separada dentro do ticket, com um fornecedor ou colega de
outra área, que o solicitante nunca vê (spec 13 Δ17; vocabulário na spec 01
§2).

- **Abrir**: um agente com escrita no grupo do ticket informa um ou mais
  destinatários (`To` e `Cc`), o assunto e a primeira mensagem. Não podem ser
  destinatários o solicitante, os participantes do ticket nem os endereços de
  suporte da conta; a tentativa é recusada (422) com a indicação do endereço.
  Os destinatários não viram participantes do ticket nem são criados como
  solicitantes; o endereço é guardado na conversa paralela.
- **Saída**: From e Reply-To como em §9 (o endereço por ticket, quando ligado,
  tem token próprio da conversa paralela). Assunto
  `{assunto da conversa} [PD-{número}/{k}]`, e `Re: …` nas respostas
  seguintes. Message-ID próprio (§4.1); In-Reply-To e References usam **só**
  a cadeia da conversa paralela, nunca a da conversa principal. Uma única
  mensagem para todos os destinatários, **sem** link de convidado, sem marca
  da conta e sem histórico da conversa principal. Leva o separador de resposta.
- **Entrada**: uma resposta encadeia pela §4.2 (cabeçalhos ou marcador
  `[PD-N/k]`) e entra **na conversa paralela**, nunca na principal. A etapa de
  pessoas (§5) não roda: qualquer remetente é aceito como autor da mensagem da
  conversa paralela; quem não estava entre os destinatários recebe a marca
  "remetente novo na conversa" e não passa a receber as respostas seguintes.
  Mensagens automáticas e bounces seguem §6 e §7, dentro da conversa paralela.
- **Efeito no ticket**: uma resposta (não automática) recebida numa conversa
  paralela leva o ticket **em espera** para **aberto**; nos outros estados,
  inclusive fechado e resolvido, o estado não muda e a política de resposta em
  fechado não se aplica. Notifica o responsável e os seguidores (sem
  responsável, o grupo). **Não** conta como resposta do solicitante nem da
  equipe para SLA e métricas, e não dispara automações de "mensagem do
  cliente".
- **Acesso**: só agentes que veem o ticket veem a conversa paralela. Para
  acesso e API, as mensagens dela são tratadas como notas internas (spec 06,
  D03). Nos webhooks, saem no **mesmo tipo de evento das notas internas**, com
  a indicação "conversa paralela" e o número da conversa; **nunca** saem em
  eventos de mensagem pública nem no conteúdo dos eventos de ticket (D37,
  spec 10).
- **Encerrar**: um agente com escrita encerra a conversa paralela. Depois
  disso, e-mails que encadeiam nela vão para a **quarentena** com o motivo
  "conversa paralela encerrada" e o ticket não muda. Liberar um desses itens
  grava a mensagem na conversa encerrada, como registro, sem reabri-la. Não há
  reabertura de conversa paralela no MVP: o agente abre outra.
- Um ticket pode ter várias conversas paralelas, numeradas 1, 2, … por ticket.

### 9.3 Chat e e-mail

Para tickets de canal chat (spec 13 Δ16; spec 03):
- A resposta pública do agente aparece no widget em tempo real (spec 09).
  Se o visitante tem e-mail e não lê a resposta no widget em **2 minutos**, ela
  sai por e-mail, com as regras de §9 (assunto com `[PD-N]`, link de
  convidado).
- Respostas ainda não lidas são **agrupadas**: quando vencem os 2 minutos da
  mais antiga não lida, sai um único e-mail com todas as não lidas até aquele
  momento. Uma resposta lida no widget antes disso não vai por e-mail.
- Resposta por e-mail a esse e-mail entra no mesmo ticket pelo threading
  normal (canal da mensagem: e-mail).
- Resolução com resposta: a pesquisa aparece no widget. O e-mail da resposta
  (se ela não for lida em 2 minutos) só traz o convite se o visitante ainda
  não avaliou aquela resolução no widget. Há no máximo uma avaliação por
  resolução e um convite, seja qual for o meio.
- Visitante sem e-mail não é aceito (spec 13 §6), então todo ticket de chat
  tem um endereço para o qual a resposta pode ir.

---

## 10. Abordagens comparadas

### 10.1 Por projeto (segundo a documentação pública)

| Projeto | Ingestão | Âncora do threading | Automáticas / bounce / laço | Prós | Contras |
|---|---|---|---|---|---|
| Zammad | IMAP/POP, entrega local; apaga ou marca como lida | marcador no assunto + Message-ID; métodos extras opcionais | detecta automáticas e não responde; bounce anexado e endereço marcado; ignora notificações próprias | pipeline de filtros explícito e ordenado | métodos extras geram falsos positivos; marcar como lida pode perder mensagem |
| Chatwoot | encaminhamento para endereço de entrada, IMAP | Reply-To exclusivo por conversa + cabeçalhos | não documentado | continuidade entre chat e e-mail | quase nada documentado sobre robustez |
| FreeScout | IMAP/POP só de não lidas | não documentado; sem número no assunto | reconhece cabeçalhos de automática | simples | mensagem lida por outro cliente nunca entra; Cc que responde vira cliente |
| osTicket | piping ou polling; mover para pasta, apagar ou deixar | provável número + cabeçalhos (não documentado) | não documentado | mover para pasta é seguro; filtros na criação | admite duplicatas; filtros só na criação |
| Znuny | daemon IMAP/POP (apaga) ou piping | ordem documentada: bounce → número no assunto → cabeçalhos → corpo/anexos (opcionais) | limite diário de auto-respostas; bounce como continuação | a ordem de threading mais explícita | apaga do servidor sempre |
| UVdesk | IMAP agendado por caixa | não documentado | lista de bloqueio/permissão | bloqueio por domínio/IP | documentação escassa |
| Frappe Helpdesk | IMAP/POP a cada 10 min | In-Reply-To, depois References do mais novo ao mais antigo | não documentado | algoritmo de References claro | sem marcador no assunto documentado |

### 10.2 Escolhas do PantherDesk

| Tema | Abordagens observadas (documentação) | Escolha e motivo |
|---|---|---|
| Âncora do threading | marcador no assunto / cabeçalhos / Reply-To exclusivo por conversa | cabeçalhos + marcador, com Reply-To por ticket opcional: cobre os modos de falha de cada um |
| Casamento por assunto parecido | oferecido como opção por um projeto, com alerta de falsos positivos | proibido |
| Depois de importar | apagar / marcar lida / mover para pasta / deixar | mover depois de confirmar: é a única opção sem modo de perda documentado |
| Deduplicação | só um projeto menciona, e com ressalva | chave por Message-ID + hash |
| Automáticas | gravar e suprimir a resposta (3 projetos) | gravar (se encadeada), suprimir a resposta, nunca reabrir |
| Bounce | anexar ao ticket; marcar o contato (1 projeto) | anexar + marcar o endereço como inválido, só se ele foi destinatário da mensagem que falhou |
| Spam do MTA | ignorado sem filtro (todos) | respeitado → quarentena |
| Cc que responde | vira participante / vira cliente | participante |
| Encaminhado por agente | automático (1) / exige marcador no topo (1) | automático, pela estrutura MIME |
| Contato com terceiros | não documentado como recurso nativo nos projetos; na operação EARJ, troca de e-mails por fora do ticket | conversa paralela dentro do ticket, com identificadores e marcador próprios, para que as respostas nunca caiam na conversa com o solicitante |

---

## 11. Casos de teste (critérios de aceite)

Configuração: caixa `suporte@pd.test` → grupo N1; domínio de envio `pd.test`.
`{R}` = Message-ID da resposta do agente; `{S}` = assunto enviado. Atores da
spec 01 §9 (`ag1`, `ag2` com escrita no N1; `ag3` sem acesso ao N1; `apoio1`
com leitura). Fornecedor de teste: `fornecedor@lab.test`. Horários em
America/Sao_Paulo; tempos relativos em minutos a partir da ação.

### 11.1 Entrada e threading
| ID | Fixture | Dado | Resultado esperado |
|---|---|---|---|
| EM-01 | fx01 | — | 1 ticket aberto no N1; solicitante "Ana Ribeiro" criada com customer1 (endereço não verificado); corpo em texto; 1 mensagem pública |
| EM-02 | fx01 duas vezes (fx07) | EM-01 processado | nenhum ticket ou mensagem novos; log registra duplicata; a mensagem é movida no IMAP |
| EM-03 | fx01 | o processamento falha (banco fora) depois da leitura | a mensagem continua na pasta de entrada; no próximo ciclo é processada uma única vez |
| EM-04 | fx03 | ticket de fx01 respondido pelo agente (`{R}`, `{S}`) | a mensagem entra no mesmo ticket; o texto citado fica separado e recolhido |
| EM-05 | fx04 (só References) | idem | entra no mesmo ticket |
| EM-06 | fx05 (só marcador `[PD-N]`) | idem | entra no ticket N |
| EM-07 | fx05 com `[PD-99999]` inexistente | — | ticket novo; o assunto é mantido |
| EM-08 | fx06 (Re: mesmo assunto, sem nada) | ticket de fx01 existe | **ticket novo** |
| EM-09 | fx03 com In-Reply-To de #A e assunto com `[PD-B]` | A e B existem | entra em A; aviso de marcador divergente |
| EM-10 | fx03 com In-Reply-To de um Message-ID de outra conta | — | tratado como desconhecido → ticket novo (ou o marcador, se válido) |
| EM-11 | fx03 | o ticket alvo foi mesclado em B | entra em B |
| EM-12 | fx03 | ticket alvo fechado, política `novo` | ticket novo vinculado |
| EM-13 | ag1 (escrita no N1) responde, do endereço cadastrado, a um e-mail de notificação do ticket N | conta no padrão (D02) | nota interna no ticket N, autor ag1; nenhum e-mail a ana; a primeira resposta do ticket não é cumprida |
| EM-14 | apoio1 (leitura no N1) responde por e-mail a uma notificação do ticket N | — | nota interna no ticket N, autor apoio1; o estado não muda |

### 11.2 Classificação
| ID | Fixture | Dado | Resultado esperado |
|---|---|---|---|
| EM-20 | fx08 (auto-resposta encadeada, remetente customer3) | ticket pendente | mensagem de sistema interna; estado continua pendente; nenhuma auto-resposta enviada; o SLA não conta como resposta do cliente |
| EM-21 | fx08 sem In-Reply-To | — | quarentena (automática sem ticket); nenhum e-mail enviado |
| EM-22 | fx09 (bounce 5.1.1 referenciando `{R}`) | `{R}` foi enviada com `nobody@nowhere.lab.test` como destinatário (participante do ticket) | mensagem de sistema interna no ticket de `{R}`; o endereço `nobody@nowhere.lab.test` fica inválido; estado inalterado |
| EM-23 | fx09 com Status 4.2.2 | idem | mensagem de sistema interna; endereço **não** invalidado |
| EM-24 | fx10 (Precedence: bulk) | — | quarentena; nenhum ticket; nenhuma auto-resposta |
| EM-25 | fx11 (From = suporte@pd.test) | — | descartada; log de laço; nada gravado no ticket |
| EM-26 | e-mail com Message-ID `<x@pd.test>` (nosso domínio) vindo de fora | — | descartado como laço |
| EM-27 | fx12 (X-Spam-Flag: YES) | — | quarentena (spam); nenhum ticket |
| EM-28 | fx12 | o admin libera da quarentena | ticket criado normalmente, uma única vez |
| EM-29 | 11 auto-respostas de criação para o mesmo destinatário em 24 h | confirmação de abertura ligada; endereço do destinatário **verificado** (o limite de 3 do D25 não se aplica) | 10 enviadas; a 11ª é suprimida com evento registrado |
| EM-80 | fx09 (5.1.1 referenciando `{R}`) | `{R}` foi enviada só a ana; `nobody@nowhere.lab.test` não foi destinatário | mensagem de sistema interna com o aviso "destinatário do relatório não confere"; nenhum endereço invalidado |
| EM-81 | 4 e-mails novos (sem encadear) de dani, endereço não verificado, em 24 h | gatilho padrão de confirmação ativo | 4 tickets; 3 confirmações com número e link de convidado, **sem** o assunto nem o corpo recebidos; a 4ª suprimida com evento registrado (D25) |
| EM-82 | e-mail novo de ana, endereço verificado | gatilho padrão de confirmação ativo | **uma** confirmação, enviada pelo gatilho da spec 05 §6; nenhum outro e-mail de confirmação (D25) |

### 11.3 Pessoas
| ID | Fixture | Dado | Resultado esperado |
|---|---|---|---|
| EM-30 | fx14 (Cc manager1) | ticket de ana | manager1 vira participante; o solicitante continua ana; a próxima resposta do agente sai com Cc manager1 |
| EM-31 | resposta de manager1 na thread | após EM-30 | autor manager1; o solicitante continua ana; o ticket reabre se estava pendente |
| EM-32 | fx16 (estranho com In-Reply-To válido) | — | anexada com a marca "remetente novo na conversa"; o estranho vira participante não confirmado; a próxima resposta do agente **não** vai para ele; ele não vê o ticket no portal |
| EM-35 | fx16 | após EM-32, ag1 confirma o participante | a próxima resposta do agente inclui o estranho em Cc; a mensagem dele passa a aparecer no portal |
| EM-36 | ag3 (sem acesso ao N1) responde por e-mail a uma notificação de ticket do N1 | — | quarentena "agente sem acesso"; o ticket não muda |
| EM-33 | fx15 (agente encaminha message/rfc822) | agent1 é agente | ticket novo com solicitante customer5 (Eva Martins); a nota do agente vira nota interna; criador = agent1 |
| EM-34 | fx01 | caixa com "aceitar desconhecidos" = não | quarentena; nenhuma pessoa criada |
| EM-37 | fx16 | ticket alvo **pendente**, responsável ag1 | estado continua pendente; a mensagem fica oculta no portal; nenhuma automação de "mensagem do cliente"; ag1 notificado para confirmar |
| EM-38 | fx08 | ticket de fx01 (customer3 não está no ticket) | mensagem de sistema interna; customer3 **não** vira participante; sem marca "remetente novo na conversa" |
| EM-39 | ag2 segue o ticket de fx01 | ag1 envia resposta pública | o e-mail vai a customer1; ag2 não está em `To` nem em `Cc` |

### 11.4 Conteúdo
| ID | Fixture | Resultado esperado |
|---|---|---|
| EM-40 | fx02 | o corpo é o HTML sem `<script>`; o `cid:` aponta para o anexo inline `shot.png`; `invoice-4471.pdf` é um anexo comum com tamanho correto; a versão em texto fica guardada |
| EM-41 | fx13 (ISO-8859-1, QP, encoded-word) | remetente "João Conceição"; assunto "Configuração do acesso à VPN"; corpo com acentos corretos |
| EM-42 | mensagem de 30 MB | com limite de 25 MB: conteúdo não processado; mensagem de sistema interna com remetente e assunto; nenhuma auto-resposta |
| EM-43 | MIME com boundary quebrado | quarentena com o motivo; o admin reprocessa depois da correção |
| EM-44 | ag1 responde ao ticket de fx01 com um anexo de 40 MB (limite de envio 25 MB) | o e-mail sai sem anexo, com a lista do arquivo e o aviso de que está no ticket; o anexo fica gravado na mensagem |

### 11.5 Saída
| ID | Ação | Resultado esperado |
|---|---|---|
| EM-50 | o agente responde ao ticket de fx01 | From "Agente via Conta" <suporte@pd.test>; Message-ID no domínio pd.test com token opaco; In-Reply-To = Message-ID de fx01; References contém fx01; assunto `Re: Printer on floor 3 does not print [PD-1000]`; o corpo começa pelo separador |
| EM-51 | segunda resposta do agente | o assunto não ganha `Re: Re:` nem marcador duplicado |
| EM-52 | o agente escreve nota interna | nenhum e-mail sai para o solicitante ou os participantes |
| EM-53 | auto-resposta de criação | leva `Auto-Submitted: auto-replied` e o cabeçalho de laço |
| EM-54 | a resposta a um endereço inválido | não é enviada; aviso no ticket |
| EM-55 | SMTP fora de t=0 a t=10 min; a 1ª tentativa é em t=0 | tentativas em t=0, t=1 e t=5 falham; a de t=15 envia; um único envio efetivo; nenhum aviso ao agente |
| EM-56 | SMTP fora de t=0 a t=70 min | falham t=0, 1, 5, 15 e 60; aviso ao agente depois da falha de t=60; a de t=120 envia; um único envio efetivo |
| EM-57 | uma macro muda o assunto do ticket 1000 para "Helpdesk — ticket #1000"; o agente responde | assunto `Re: Helpdesk — ticket #1000 [PD-1000]`; uma resposta de ana a esse e-mail continua encadeando no 1000 |
| EM-58 | ticket 1000 de ana com participante manager1; pesquisa ligada no grupo; ag1 envia resposta pública e resolve | **um** e-mail: a cópia de ana traz a resposta e o convite de avaliação; a cópia de manager1 traz só a resposta; nenhum segundo e-mail |
| EM-59 | ag1 muda o ticket 1000 de aberto para pendente, sem mensagem; nenhum gatilho de e-mail | nenhum e-mail sai |

### 11.6 Conversa paralela
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| EM-60 | ticket 1000 de ana em espera, sem conversas paralelas | ag1 abre conversa paralela com fornecedor@lab.test, assunto "Peça da impressora" | 1 e-mail a fornecedor@lab.test: From "ag1 via Conta" <suporte@pd.test>, Message-ID próprio, assunto `Peça da impressora [PD-1000/1]`, sem link de convidado e sem histórico; ana não recebe nada; a conversa aparece só para agentes; o estado continua em espera |
| EM-61 | após EM-60 | o fornecedor responde com In-Reply-To da mensagem de EM-60 | a mensagem entra na conversa paralela 1, não na principal; estado aberto; ag1 e os seguidores notificados; o SLA não registra resposta do solicitante; ana não recebe nada |
| EM-62 | após EM-60 | o fornecedor responde sem cabeçalhos, com `[PD-1000/1]` no assunto | entra na conversa paralela 1 |
| EM-63 | após EM-60 | resposta com In-Reply-To da conversa paralela 1 e assunto com `[PD-1000]` | entra na conversa paralela 1 (cabeçalhos prevalecem); aviso de marcador divergente |
| EM-64 | conversa paralela 1 aberta; ticket **pendente** | o fornecedor responde | a mensagem entra na conversa paralela; estado continua pendente |
| EM-65 | ag1 encerrou a conversa paralela 1 | o fornecedor responde de novo | quarentena "conversa paralela encerrada"; o ticket não muda |
| EM-66 | ticket 1000 | ag1 tenta abrir conversa paralela com o endereço de ana | recusado (422) com indicação do endereço; nenhum e-mail |
| EM-67 | após EM-60 | chega uma auto-resposta de ausência do fornecedor, encadeada na conversa paralela 1 | mensagem de sistema interna na conversa paralela; o estado continua em espera; nenhuma notificação de resposta |
| EM-68 | após EM-60, o ticket 1000 foi mesclado em 1001 | o fornecedor responde | entra na conversa paralela que agora está em 1001 |
| EM-69 | após EM-61 | ag1 responde na conversa paralela 1 | e-mail só ao fornecedor; assunto `Re: Peça da impressora [PD-1000/1]`; References só com as mensagens da conversa paralela; sem `Auto-Submitted` |
| EM-83 | após EM-60; assinaturas de webhook para mensagem pública e para nota interna | o fornecedor responde na conversa paralela 1 | um evento no tipo de nota interna, com a indicação "conversa paralela" e o número 1; nenhum evento de mensagem pública; o evento de ticket (mudança para aberto) não traz o conteúdo da mensagem (D37) |

### 11.7 Chat e convite de avaliação
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| EM-70 | ticket de chat de bia (com e-mail), widget aberto | ag1 responde às 10:00:00; bia lê às 10:01:00 | nenhum e-mail |
| EM-71 | ticket de chat de bia, widget fechado | ag1 responde às 10:00:00 | às 10:02:00 sai **um** e-mail a bia com a resposta, assunto com `[PD-N]` e link de convidado |
| EM-72 | idem | ag1 responde às 10:00:00 e às 10:01:00; bia não lê | às 10:02:00 sai **um** e-mail com as duas respostas; nenhum e-mail às 10:03:00 |
| EM-73 | após EM-71 | bia responde a esse e-mail | a mensagem entra no mesmo ticket, com canal e-mail |
| EM-74 | ticket de chat de bia, widget aberto, pesquisa ligada | ag1 responde e resolve às 10:00:00; bia lê às 10:00:30 e avalia no widget | nenhum e-mail; uma avaliação |
| EM-75 | idem, widget fechado | ag1 responde e resolve às 10:00:00 | às 10:02:00 sai um e-mail com a resposta e o convite; se bia depois avaliar no widget e também pelo e-mail, fica **uma** avaliação (a última vale) para essa resolução |
| EM-76 | ticket de ana, endereço de ana inválido, pesquisa ligada | ag1 envia resposta pública e resolve | nenhum e-mail e nenhum convite; aviso no ticket |

---

## 12. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Message-ID e cabeçalhos de saída | nenhum projeto documenta | E-03 em todos |
| Threading por cabeçalho, References e assunto | documentado em 3 projetos | E-04, E-05, E-06, E-07 |
| Deduplicação | documentado em 1, com ressalva | E-08 |
| Automáticas, bounce, laço | documentado em 2–3 | E-09 a E-12 |
| Spam do MTA | ausência documentada | E-13 |
| Charset, sanitização, citação | nenhum documenta | E-02, E-04, E-14 |
| Cc, encaminhamento, remetente estranho | parcial | E-15, E-16, E-17 |
| Falha do IMAP | parcial | E-18 |
| Conversa paralela, e-mail do chat, convite junto da resposta | requisito de cliente (spec 13) | não se aplica: decisão de produto |

---

## 13. Questões abertas para o implementador

1. **Anexos acima do limite de envio.** A regra "nenhum anexo vai quando a
   soma passa do limite" é simples, mas tira do e-mail anexos pequenos que
   caberiam. Confirmar com a operação EARJ antes do protótipo.
