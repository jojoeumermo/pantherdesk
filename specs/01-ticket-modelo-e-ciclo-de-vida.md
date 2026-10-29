# Spec 01 — Modelo de dados e ciclo de vida do ticket

Status: **rascunho v0.3 (2026-10-29)**. Baseado na documentação pública dos 7
projetos analisados, nas decisões transversais D01–D53 e nos requisitos da
operação EARJ (spec 13, que prevalece). As evidências de runtime ainda estão
pendentes (o laboratório não subiu); cada ponto que depende delas está marcado
como **[evidência pendente: cenário]**. Esta spec define o **vocabulário comum**
usado por todas as outras.

Mudanças na v0.3:
- **Ticket pai** para incidentes em massa: marcar como pai, vincular e
  desvincular filhos, resolução em cascata, contagem de filhos e locais
  afetados (spec 13 Δ35; §4.8). Detalhe da resposta em cascata na spec 05 §4.5.
- Tipo do ticket ganha o valor **evento**, com os **campos do evento** (data,
  início e fim, **início da montagem**, local, público, equipamentos) e a marca
  derivada "fora do prazo" (Δ34; §5.2).
- **Local do ticket** vindo do **cadastro de locais** (campus → prédio → andar
  → sala), nunca de etiquetas; "minhas salas" na Pessoa (Δ33; §5.3).
- **Login com Google**: agentes só entram com conta Google do domínio da conta;
  o primeiro login do solicitante com Google **verifica** o endereço (Δ31,
  amplia D38; §2).
- Campo de controle de condição de exibição pode ser também o tipo do ticket e
  o campus do local (§5.1).
- Novos casos TL-100 a TL-118.
- **Ajustes D40–D53**: marca **"pronto para o evento"** no ticket de evento,
  posta por agente com escrita, desfazível até o início da montagem (D44;
  §5.2); a 1ª resposta do evento segue o SLA comum e só a resolução comum
  deixa de valer (D40); termo **"tipo de evento"** no lugar de "categoria do
  evento" (D53); vincular filho que o ator não vê → 404 (D43); desvincular
  exige escrita no pai **ou** no filho (D45); a resposta do pai entra em
  filho resolvido sem mudar o estado (D46); na resolução em cascata, filho
  sem responsável recebe quem resolveu o pai (D47); locais afetados reúnem
  pai e filhos, sem repetição (D48); os campos personalizados "unidade" e
  "setor/sala" saem dos exemplos e testes, trocados por motivo → equipamento
  → sintoma (D51). TL-55, TL-57, TL-58, TL-107, TL-111 e TL-114 revistos;
  novos TL-119 a TL-123; questão aberta 3 retirada.

Mudanças na v0.2:
- Novo estado **em espera** (aguarda um terceiro), entre pendente e resolvido,
  com SLA pausado; "pendente" passa a significar só "aguarda o solicitante"
  (D18, spec 13 Δ3).
- Matriz de transições refeita com em espera; códigos de recusa definidos:
  403 quando o ator não tem o direito, 422 quando a transição não existe ou
  viola regra (D05).
- **Responsável obrigatório para resolver** (configuração por conta) e regra
  única de validações para resolver (spec 13 Δ4).
- Versão do ticket conforme D01: mensagens não aumentam nem exigem versão;
  envio misto exige; API sem versão é aceita e registrada.
- Ação "meu problema foi resolvido" vale para aberto, pendente e em espera, e
  só para o solicitante (D08).
- Vocabulário novo: **seguidor**, **conversa paralela**, **tipo do ticket**,
  **origem do encaminhamento**, **avaliação**, **gestor da organização**,
  **convidado** e **visitante**; mensagem de sistema com visibilidade
  (spec 13 Δ6, Δ8, Δ5, Δ15, Δ17; D07).
- Identidade de integração alinhada à D04 (mesmo acesso por grupo e mesmos três
  escopos dos agentes); admin pode ser responsável em qualquer grupo (D06).
- "Notificar o grupo" = agentes ativos com escrita no grupo, nunca o autor
  (D09, D12); endereço verificado só por link ou login (alinhado à spec 03).
- Ticket criado por agente tem canal `agente`; o meio informado é só atributo
  (alinhado à spec 03).
- Campos condicionais (spec 13 Δ2) e campos personalizados em Pessoa e
  Organização, com mescla de pessoas (D21, spec 13 Δ22).
- Resposta em fechado: política `novo` nos dados da EARJ e ação manual **criar
  continuação**; ação **imprimir** (spec 13 Δ13, Δ20).
- Fronteira do fechamento automático definida (≥ N dias) e TL-25 refeito com
  datas; participante não confirmado não reabre o ticket.
- Novos casos de teste TL-06 a TL-08, TL-19, TL-29, TL-36 a TL-38, TL-45,
  TL-55 a TL-59, TL-60 a TL-79, TL-80 a TL-84 e TL-90 a TL-92.
- Ajustes D23–D37: ticket encaminhado tem estado único **aberto** e a marca
  derivada **"encaminhado"** para o grupo de origem (D23, D24); "meu problema
  foi resolvido" ignora responsável e campos obrigatórios e grava a marca
  **"resolvido pelo solicitante"** (D33); ticket criado por agente tem canal
  `agente` e **meio declarado** (D34). Questões abertas 1 e 2 respondidas e
  retiradas. Novos casos TL-93 a TL-97.

---

## 1. Problema

O ticket é a unidade de trabalho do helpdesk: junta a conversa entre um
solicitante e a equipe, com um responsável, um grupo, um estado e metadados. O
modelo precisa responder sem ambiguidade:

1. quem pediu, quem atende e quem mais acompanha;
2. em que ponto o pedido está, quais mudanças de estado são válidas e quais
   acontecem sozinhas;
3. o que acontece quando alguém escreve num ticket já encerrado;
4. como o ticket é identificado de forma estável (número legível, usado no
   assunto do e-mail e na busca);
5. quem mudou o quê e quando, inclusive quando a mudança foi feita por uma
   automação;
6. como juntar tickets duplicados sem quebrar o encadeamento de e-mails futuros.

---

## 2. Vocabulário e entidades (conceitual)

| Termo | Definição |
|---|---|
| **Conta** (tenant) | Fronteira de isolamento. Toda entidade pertence a exatamente uma conta. O MVP roda com uma conta, mas o modelo já carrega a referência. |
| **Pessoa** | Qualquer ser humano conhecido pelo sistema. Tem nome, idioma, fuso, um ou mais **endereços** de contato, opcionalmente valores de campos personalizados (§5) e uma lista ordenada de **minhas salas** (§5.3). Uma pessoa pode ser **mesclada** em outra (§6.2). |
| **Endereço** | Um e-mail (no futuro: telefone, identificador de rede social) ligado a uma pessoa. Um endereço pertence a no máximo uma pessoa por conta. Dois e-mails são o mesmo endereço quando coincidem **ignorando maiúsculas e minúsculas** no endereço inteiro, depois de tirar espaços nas pontas; sub-endereços (`ana+x@`) contam como endereços diferentes. Estados: **verificado** (a pessoa provou que é dona usando um link de uso único enviado a esse endereço ou entrando no portal com ele, inclusive pelo **login com Google**: o e-mail da conta Google passa a verificado no primeiro login; spec 03, spec 07, spec 13 Δ31), **não verificado** e **inválido** (bounce permanente; spec 02 §7). Responder a um e-mail nosso **não** verifica o endereço, porque o remetente de e-mail é falsificável. |
| **Solicitante** | Papel de uma pessoa em relação a um ticket: quem pediu. Cada ticket tem exatamente um. |
| **Organização** | Agrupa solicitantes (ex.: uma empresa cliente). Uma pessoa pertence a no máximo uma organização no MVP. Pode ter valores de campos personalizados (§5). |
| **Gestor da organização** | Marca na Pessoa que, conforme a configuração da organização, permite ver no portal os tickets dos outros membros, só para leitura (D07; regras nas specs 06 e 07). |
| **Agente** | Pessoa com acesso à área de atendimento. Tem, por grupo, acesso **nenhum**, **leitura** ou **escrita** (spec 06). Entra **somente** com conta Google do domínio configurado na conta, sem senha local; papel e grupos são definidos no PantherDesk pelo admin, nunca vindos do Google (spec 13 Δ31). |
| **Admin** | Agente com escrita implícita em todos os grupos; pode ser responsável em qualquer grupo sem ser membro dele (D06). |
| **Grupo** | Equipe que atende tickets (ex.: "Suporte N1", "Financeiro"). Todo ticket pertence a exatamente um grupo. |
| **Responsável** | Agente encarregado do ticket. Opcional (ticket sem responsável fica na fila do grupo), salvo para resolver quando a conta exige (§4.2). O responsável precisa estar ativo e ter acesso de **escrita** ao grupo do ticket (spec 06); o admin sempre cumpre essa condição. |
| **Participante** | Pessoa que recebe as respostas públicas do ticket e pode responder (ex.: quem veio em Cc), sem ser o solicitante. Pode estar **confirmado** (padrão) ou **não confirmado** (remetente que entrou sozinho na conversa; spec 02 §5). O não confirmado não recebe e-mails nem vê o ticket no portal até um agente confirmar. |
| **Seguidor** | Agente que acompanha o ticket internamente. Recebe notificações (spec 09) de mensagens públicas, notas internas e mudanças de estado, mas **não** aparece para o solicitante e **nunca** entra como Cc nos e-mails públicos. Qualquer agente que vê o ticket pode seguir e deixar de seguir. Ser mencionado numa nota (spec 09) torna o agente seguidor. |
| **Convidado** | Quem abre um único ticket por um link de acesso pessoal recebido por e-mail, sem entrar no portal (spec 07). Age como o solicitante ou o participante a quem o link pertence. |
| **Visitante** | Pessoa ainda não identificada que usa o formulário público, o chat ou o portal sem login. Para abrir um pedido, informa nome e e-mail; a pessoa é criada com o endereço não verificado (spec 03, spec 13). |
| **Mensagem** | Cada entrada da conversa principal. Tem autor, momento, canal de origem (tipos na spec 03), corpo, anexos e **visibilidade**: pública (o solicitante vê) ou **nota interna** (só agentes veem). Mensagens são imutáveis depois de gravadas. |
| **Mensagem de sistema** | Mensagem gerada por máquina e anexada ao ticket. Nunca conta como resposta humana. Tem visibilidade: **interna** (registro de algo que chegou ou falhou: resposta automática recebida, aviso de falha de entrega, aviso de mensagem grande recusada; tratada como nota interna para fins de acesso, spec 06) ou **pública** (texto automático que o solicitante vê: confirmação de abertura enviada por gatilho, registro da ação "meu problema foi resolvido"). |
| **Conversa paralela** | Linha de e-mail separada dentro de um ticket, aberta por um agente com um ou mais endereços externos (fornecedor, colega de outra área). Só agentes a veem; nunca vai ao solicitante nem aos participantes; tem identificadores de e-mail próprios e pode ser **encerrada**. Um ticket pode ter várias. Suas mensagens não são mensagens da conversa principal: não contam como resposta do solicitante nem da equipe para SLA e métricas. Regras de e-mail na spec 02 §9.2 (spec 13 Δ17). |
| **Anexo** | Arquivo ligado a uma mensagem, com nome, tipo, tamanho e marca de inline (referenciado dentro do corpo). |
| **Etiqueta** (tag) | Rótulo livre, gravado em minúsculas, sem espaços nas pontas e **com acentos preservados**; sem duplicatas por ticket. A busca (spec 08) ignora acentos na comparação. |
| **Campo personalizado** | Definição criada pelo admin (entidade a que pertence, tipo, rótulo, obrigatoriedade, opções, condição de exibição) + valor por registro (§5). |
| **Prioridade** | Valor de uma lista fixa no MVP: baixa, normal, alta, urgente. Padrão: normal. |
| **Tipo do ticket** | Campo de sistema opcional, de uma lista fixa no MVP: pergunta, incidente, problema, tarefa, **evento**. **Sem valor padrão** (vazio). Pode ser usado em filas, regras e relatórios (spec 13 Δ8). O tipo **evento** liga os campos do evento (§5.2) e troca o SLA comum pelo prazo do evento (spec 05 §7.14; spec 13 Δ34). |
| **Local** | Uma **sala** do **cadastro de locais**, organizado em quatro níveis: campus → prédio → andar → sala (§5.3; spec 13 Δ33). O **local do ticket** é um campo de sistema opcional que aponta para uma sala; vem do QR da sala, do formulário ou do agente, nunca de etiquetas. |
| **Ticket pai** / **filho** | Ticket **pai** = ticket marcado como incidente em massa, ao qual outros tickets (**filhos**) são **vinculados**. Um filho tem no máximo um pai; não há vários níveis. Resposta pública e resolução do pai seguem em cascata para os filhos (§4.8; spec 05 §4.5; spec 13 Δ35). |
| **Origem do encaminhamento** | Registro (grupo e agente de origem) que o ticket carrega enquanto está **encaminhado com retorno** a outro grupo. É limpo quando o ticket volta ou quando a transferência comum cancela o retorno. Enquanto existe, o ticket fica no estado **aberto**, no grupo de destino; para o grupo de origem, ele aparece com a marca derivada **"encaminhado"** (não é estado; aparece nas filas e serve de filtro), e a origem mantém acesso de leitura, podendo escrever nota interna (D23, D24). Regras na spec 04 (spec 13 Δ5). |
| **Resolvido pelo solicitante** | Marca derivada gravada no ticket quando ele vai para resolvido pela ação "meu problema foi resolvido" (§4.2, nota ⁴). Não é estado; some quando o ticket é reaberto (D33). |
| **Avaliação** | Nota de 1 a 5 dada pelo solicitante a uma **resolução** do ticket, com comentário e motivo opcionais. Não é campo nem estado: não muda o estado nem a versão. Regras de convite e cálculo nas specs 05, 07 e 11 (spec 13 Δ15). |
| **Evento de auditoria** | Registro imutável de uma mudança: quem, quando, o quê, valor anterior, valor novo e a origem. |
| **Identidade de integração** | Ator não humano criado pelo admin para um sistema externo que usa a API. Tem o **mesmo modelo de acesso por grupo** dos agentes (nenhum, leitura, escrita) e tokens com os **mesmos três escopos** (leitura, escrita, administração). Pode ser autora de mensagens e de eventos de auditoria; na tela aparece com o nome da integração; nunca conta como agente humano nas métricas (D04; specs 06, 10, 11 e 12). |

Relações principais:
- Conta 1—N Pessoa, Organização, Grupo, Ticket.
- Pessoa 1—N Endereço; Pessoa N—1 Organização (opcional); Pessoa e
  Organização 1—N Valores de campo.
- Ticket N—1 Solicitante, N—1 Grupo, N—1 Responsável (opcional), N—N
  Participantes, N—N Seguidores, N—N Etiquetas, 1—N Mensagens, 1—N Conversas
  paralelas, 1—N Avaliações, 1—N Eventos de auditoria, 1—N Valores de campo,
  0—1 Origem do encaminhamento, N—1 Ticket anterior (opcional, "continuação de
  #N"), N—1 Local (opcional), N—1 Ticket pai (opcional).
- Cadastro de locais: Campus 1—N Prédio 1—N Andar 1—N Sala. Pessoa N—N Sala
  ("minhas salas", com ordem).
- Mensagem 1—N Anexos; Mensagem guarda os **identificadores de e-mail** que
  recebeu ou emitiu (ver spec 02). Conversa paralela 1—N Mensagens próprias,
  com os mesmos atributos e identificadores.

Decisão de modelagem: **pessoa e endereço são entidades separadas desde o
início.** Juntar duas pessoas (ou descobrir que dois e-mails são da mesma
pessoa) não pode depender de reescrever tickets. Num dos projetos analisados,
acrescentar um e-mail extra a um perfil mescla clientes de forma implícita, o
que mostra o custo de não separar.

**Notificar o grupo**: sempre que esta ou outra spec disser "notifica o grupo",
os destinatários são os **agentes ativos com escrita no grupo**, **exceto o
autor da ação** (D09, D12). Canais e preferências de entrega na spec 09.

---

## 3. Numeração e versão

- Cada ticket recebe um **número legível**: inteiro sequencial por conta,
  começando em 1000, gerado de forma atômica (sem buracos causados por
  concorrência não importa; **duplicatas** são proibidas).
- O número é **imutável** e nunca reutilizado, nem depois de mescla.
- O formato não muda depois que o sistema está em uso. Um dos projetos alerta
  que trocar o formato do número em produção quebra a detecção de respostas.
- O identificador interno do ticket (usado na API) é distinto do número
  legível e opaco.
- **Versão** (D01). Cada ticket tem uma versão (inteiro):
  - só **mudança de campo ou de estado** aumenta a versão (inclui
    participantes, etiquetas, responsável, grupo, tipo, campos personalizados,
    campos do evento, local, a marca de pai, o vínculo com o pai (no filho) e
    a origem do encaminhamento). Vincular ou desvincular um filho muda a
    versão do **filho**, não a do pai: a contagem de filhos do pai é derivada;
  - acrescentar mensagem pública, nota interna, mensagem de sistema, mensagem
    de conversa paralela ou e-mail recebido **não** aumenta a versão e **não**
    a exige. Seguir, deixar de seguir e avaliar também não;
  - quando a chegada de uma mensagem provoca uma mudança automática de estado
    (ex.: pendente → aberto, §4.3), essa mudança aumenta a versão, como
    qualquer mudança de estado;
  - um envio que junta mensagem e mudança de campo ou estado **exige** a
    versão. Se ela estiver desatualizada, o envio **inteiro** é recusado como
    conflito (409): nem a mensagem nem a mudança são gravadas, e o rascunho do
    agente é preservado;
  - a interface sempre envia a versão; na API ela é **opcional** (sem versão,
    sem verificação), e o uso sem versão é registrado (spec 10). Nada é
    sobrescrito em silêncio (spec 09 e spec 10).
- **Não existe exclusão de ticket no MVP** (D17). Um ticket sai das filas
  sendo fechado, mesclado ou marcado como spam. Exclusão definitiva, por
  exemplo por pedido de privacidade, fica para o roadmap.

---

## 4. Estados e ciclo de vida

### 4.1 Estados

| Estado | Significado | Categoria de SLA (ver spec 05) | Aparece na fila de trabalho | O solicitante vê |
|---|---|---|---|---|
| **aberto** | Precisa de ação da equipe. | corre | sim | em andamento |
| **pendente** | Aguardando **o solicitante**. Pode ter uma **data de retorno** opcional. | pausado (só o prazo de resolução; o de primeira resposta continua correndo; spec 05) | não (até a data de retorno) | aguardando sua resposta |
| **em espera** | Aguardando **um terceiro** (fornecedor ou outra equipe interna), não o solicitante. Pode ter uma **data de retorno** opcional. | pausado (igual a pendente) | não (até a data de retorno); tem fila própria (spec 08) | em andamento |
| **resolvido** | A equipe considera resolvido; o solicitante ainda pode responder. | parado | não | resolvido |
| **fechado** | Encerrado definitivamente. Somente leitura para campos; ver §4.4 para respostas. | parado | não | fechado |
| **mesclado** | Terminal técnico: o ticket foi incorporado a outro (§6). | parado | não | (redireciona ao destino) |

Observações:
- "Novo" **não** é um estado no PantherDesk. Um ticket aberto que ainda não
  teve resposta pública de agente é identificado por um indicador derivado
  ("sem primeira resposta"), usado em filas e no SLA. Assim se evita a regra
  "o estado novo deixa de existir depois da primeira comunicação", que gera
  transições implícitas.
- O solicitante **nunca** vê o termo "em espera", nem no portal nem nos
  e-mails: para ele, o ticket está "em andamento" (spec 13 Δ3). Os textos da
  coluna "O solicitante vê" são o significado; a redação final é da spec 07.
- Spam **não** é estado de ticket: mensagem classificada como spam fica em
  quarentena e não vira ticket (spec 02). Um agente pode, porém, marcar um
  ticket existente como spam. O ticket ganha a marca **spam** e vai para
  **fechado**, e o remetente é bloqueado se o agente escolher. Marcar e
  desmarcar geram eventos de auditoria próprios, que as métricas usam para
  excluir o ticket (spec 11). Desmarcar tira a marca e devolve o ticket às
  métricas, mas **não reabre**: o ticket continua fechado (D16).
- O conjunto de estados é **fixo** no MVP (seis estados). Estados
  personalizados ("aguardando peça", "agendado") ficam para o roadmap, mas
  cada estado já carrega a categoria de SLA para que estados futuros se
  encaixem.

Comparação: dois dos projetos têm "resolvido" separado de "fechado"; os outros
juntam os dois em "fechado" e simulam o "resolve agora, fecha em N dias" com um
estado de espera com prazo. Ter os dois estados é mais fácil de explicar e torna
o fechamento automático trivial (§4.3). Quanto a "aguardar", Zammad e Znuny
separam os pendentes pelo que acontece na data (lembrete ou ação automática), e
o Chatwoot tem um "adiado"; nenhum separa **quem** está sendo aguardado. O
PantherDesk separa por quem é aguardado, porque isso muda o que o solicitante
vê e o que traz o ticket de volta (requisito da operação EARJ, spec 13 R02).

### 4.2 Transições permitidas

Nenhum projeto analisado publica uma matriz de transições. Isso deixa o
comportamento imprevisível. O PantherDesk valida as transições no servidor,
conforme esta matriz (linha = de, coluna = para):

| de \ para | aberto | pendente | em espera | resolvido | fechado | mesclado |
|---|---|---|---|---|---|---|
| **aberto** | — | agente | agente | agente⁵, solicitante⁴ | agente⁵ | agente (mescla) |
| **pendente** | agente, solicitante¹, sistema² | — | agente | agente⁵, solicitante⁴ | agente⁵ | agente (mescla) |
| **em espera** | agente, solicitante¹, sistema²˒⁶ | agente | — | agente⁵, solicitante⁴ | agente⁵ | agente (mescla) |
| **resolvido** | agente, solicitante¹ | agente | ✗⁷ | — | agente⁵, sistema³ | agente (mescla) |
| **fechado** | conforme política §4.4; admin ("reabrir ticket fechado") | ✗ | ✗ | ✗ | — | ✗ |
| **mesclado** | ✗ | ✗ | ✗ | ✗ | ✗ | — |

¹ Por meio de uma resposta pública (e-mail, portal ou chat) do solicitante ou
de um participante **confirmado**; nunca por mudança direta de campo.
² Quando a data de retorno é atingida (§4.3).
³ Fechamento automático (§4.3).
⁴ Somente pela ação "meu problema foi resolvido" no portal (spec 07), que
registra uma mensagem de sistema pública e grava a marca **"resolvido pelo
solicitante"**. Só o **solicitante**; participantes e convidados de
participantes não têm a ação (D08). Não exige responsável nem campos
"obrigatórios para resolver" (D33). O solicitante nunca fecha o ticket.
⁵ Aplica as **validações para resolver** (abaixo).
⁶ Também quando chega uma resposta numa conversa paralela (§4.3).
⁷ Para pôr em espera um ticket resolvido, o agente o reabre (aberto) e depois
o põe em espera. A spec 13 Δ3 lista as transições de em espera e não inclui
esta.

"agente" na matriz inclui admin, automações (spec 05), macros e a API com
escrita no grupo. Automações podem executar qualquer transição que um agente
pode, exceto as que envolvem mescla e a reabertura de fechado por admin.

**Validações para resolver** (aplicadas em toda transição de agente,
automação, macro ou API para **resolvido** ou **fechado**):
1. campos personalizados marcados como "obrigatórios para resolver" e
   **visíveis** (§5) precisam estar preenchidos;
2. se a conta liga **responsável obrigatório para resolver** (desligado por
   padrão no produto; ligado nos dados da EARJ, spec 13 Δ4), o ticket precisa
   ter responsável.

As validações usam o ticket **depois** de aplicadas todas as mudanças do mesmo
envio. Assim, uma macro (ou um envio) que atribui um responsável e resolve
passa; uma macro que só resolve um ticket sem responsável é recusada. Na
edição em massa, cada ticket é validado separadamente (spec 08). As validações
**não** se aplicam ao fechamento automático (sistema) nem à ação do
solicitante (⁴; D33): o solicitante não tem como preencher campos internos nem
atribuir. O ticket resolvido por ele segue para o fechamento automático
normalmente, mesmo sem responsável ou com campo obrigatório vazio; as
validações só voltam a valer se um agente o fechar manualmente.
"Resolver" dentro de um encaminhamento com retorno não é transição para
resolvido: devolve o ticket aberto ao grupo de origem (spec 04).

Recusa e códigos (D05):
- Transição recusada **não** grava nada (nem auditoria parcial) e indica o
  motivo; quando é uma validação, indica o campo.
- O ator não vê o ticket → **404**.
- A transição existe na matriz para outro ator, mas não para este (ex.:
  agente comum reabrindo fechado; solicitante mudando o campo de estado;
  participante usando "meu problema foi resolvido"; agente só com leitura no
  grupo) → **403**.
- A transição não existe para ninguém (✗), ou viola uma validação para
  resolver → **422**.
- Versão desatualizada → **409** (§3).

**fechado → aberto** só acontece por resposta do solicitante seguindo a
política §4.4, ou por ação explícita de **admin** ("reabrir ticket fechado").
Agente comum não reabre ticket fechado; ele pode **criar continuação** (§4.4).

### 4.3 Transições automáticas

| Gatilho | Efeito |
|---|---|
| Resposta pública do solicitante ou de um participante confirmado em ticket **pendente**, **em espera** ou **resolvido** | vai para **aberto**; a data de retorno, se houver, é descartada |
| Resposta pública do solicitante em ticket **aberto** | continua aberto (atualiza "última atividade do cliente") |
| Mensagem de participante **não confirmado** (spec 02 §5) | **não** muda o estado; não atualiza "última atividade do cliente"; não conta como resposta do cliente para SLA, métricas e automações de "mensagem do cliente"; notifica o responsável (sem responsável, o grupo) para confirmar ou recusar. Confirmar depois não tem efeito retroativo |
| Resposta recebida numa **conversa paralela** | ticket **em espera** vai para **aberto** (data de retorno descartada); nos outros estados, não muda. Notifica o responsável e os seguidores (sem responsável, o grupo). Nunca conta como resposta do solicitante (spec 13 Δ3, Δ17) |
| Data de retorno de um ticket **pendente** ou **em espera** atingida | vai para **aberto** e notifica o responsável; sem responsável, notifica o grupo (§2) |
| Ticket **resolvido** há N dias ou mais sem resposta pública do solicitante (N configurável por conta; padrão **4 dias corridos**, também o valor da EARJ) | vai para **fechado** |
| **Ticket pai** vai para **resolvido** | cada filho em **aberto**, **pendente** ou **em espera** vai para **resolvido**, numa operação própria por filho (§4.8; spec 05 §4.5). Com responsável obrigatório ligado, o filho sem responsável recebe antes, como responsável, quem resolveu o pai (D47). Filhos resolvidos, fechados ou mesclados não mudam |
| Mensagem de sistema (resposta automática, bounce) | **não** muda o estado |
| Nota interna de agente | **não** muda o estado |
| Resposta pública de agente | não muda o estado, a menos que o agente escolha o estado resultante no mesmo envio: **aberto**, **pendente**, **em espera** ou **resolvido** ("enviar com estado", spec 13 Δ19; padrão sugerido na interface: pendente). A escolha segue a matriz §4.2 e exige a versão (§3) |

Fronteira do fechamento automático: o ticket fecha na primeira execução da
tarefa em que o tempo decorrido desde a **última** transição para resolvido é
**maior ou igual** a N dias corridos (mesmo dia e mesmo horário, N dias
depois). A tarefa roda a cada minuto. Uma reabertura zera a contagem; a nova
resolução começa outra.

A tarefa de fechamento automático e a de retorno (pendente e em espera) são
**idempotentes**: rodar duas vezes no mesmo minuto produz o mesmo resultado e
um único evento de auditoria.

### 4.4 Resposta a ticket fechado

Os projetos guardam essa política em lugares diferentes: no grupo, na fila ou no
próprio estado. As opções vistas são reabrir, criar ticket novo, reabrir só
dentro de uma janela de dias e rejeitar com aviso.

**Decisão PantherDesk**: política **por grupo**, com três valores:

| Política | Comportamento |
|---|---|
| `reabrir` | O ticket volta para **aberto** e a mensagem é anexada. |
| `novo` | Cria um ticket novo, **vinculado** ao fechado ("continuação de #N"), com o mesmo solicitante, grupo e participantes. O ticket fechado não muda. |
| `janela` (padrão do produto, N = 14 dias) | Se a resposta chegar até N dias depois do fechamento, age como `reabrir`; depois disso, age como `novo`. |

- Nos dados da EARJ, a política de **todos os grupos** é `novo` ("fechado não
  reabre mais"; spec 13 Δ13). A janela de 14 dias continua sendo o padrão do
  produto.
- "Rejeitar com aviso" fica fora do MVP: gera um e-mail a mais e atrito com o
  cliente, e o ganho é pequeno.
- Em `novo`, o assunto do ticket novo é o assunto da mensagem recebida. O
  vínculo com o ticket anterior aparece para o agente e na API.
- A política vale para qualquer canal (e-mail, portal e chat). No portal, um
  ticket fechado mostra o botão "responder" apenas quando a política, naquele
  momento, resultaria em reabrir; caso contrário, oferece "abrir um novo
  pedido sobre isto". No chat, uma mensagem nova depois do fechamento segue a
  mesma política (spec 03).
- Mensagens de **conversa paralela** de um ticket fechado não seguem esta
  política: entram na conversa paralela e não mudam o estado (spec 02 §9.2).
- **Criar continuação** (ação manual de agente com escrita no grupo, só em
  ticket **fechado**; spec 13 Δ13): cria um ticket novo **aberto**, vinculado
  ao fechado, com o mesmo solicitante, participantes, grupo, prioridade, tipo
  e valores de campos personalizados. Não copia mensagens, responsável,
  seguidores nem etiquetas; o agente escreve a primeira mensagem no ticket
  novo. Em ticket que não está fechado, a ação é recusada (422).

### 4.5 Responsável e grupo na reabertura

- Na reabertura, o responsável **continua o mesmo**. Esse é o padrão
  documentado em todos os projetos que tratam do assunto.
- Se o responsável estiver desativado ou não tiver mais escrita no grupo, o
  ticket reabre **sem responsável**, na fila do grupo (spec 04).

### 4.6 Ticket criado por agente

Ao criar um ticket, o agente escolhe o modo:

| Modo | Uso | Mensagem inicial |
|---|---|---|
| **registrar pedido** (padrão) | O solicitante pediu por telefone, presencialmente ou por outro meio | Autoria do **solicitante**, com a marca "registrada por {agente}"; canal **`agente`**, mais o **meio declarado** pelo agente: telefone, presencial ou outro (obrigatório neste modo; D34, spec 03). O meio declarado pode ser usado em filas, regras e relatórios (spec 11) |
| **contato proativo** | A equipe toma a iniciativa de escrever ao solicitante | Mensagem **pública do agente**, canal `agente`, enviada por e-mail ao solicitante |

No contato proativo, o meio declarado não se aplica (a mensagem sai por
e-mail). Isso define a métrica de primeira resposta (spec 11). No primeiro modo, o
relógio corre até a primeira resposta pública de agente. No segundo, a métrica
não se aplica, e o ticket resolvido sem resposta do solicitante não recebe
convite de avaliação (spec 13 Δ15).

### 4.7 Outras ações do ticket

- **Mesclar** (§6), **criar continuação** (§4.4) e **marcar como spam**
  (§4.1).
- **Imprimir**: gera uma versão de impressão com a conversa pública. Por
  escolha do agente, inclui também as notas internas e as conversas paralelas
  (que só agentes veem). Não muda o ticket nem gera evento (spec 13 Δ20).
- **Seguir** / **deixar de seguir**: disponível a qualquer agente que vê o
  ticket; gera evento de auditoria, sem mudar a versão.
- **Abrir conversa paralela** e **encerrar conversa paralela**: agente com
  escrita no grupo (spec 02 §9.2).
- **Marcar como pai**, **desmarcar pai**, **vincular ao pai** e **desvincular**
  (§4.8).

### 4.8 Ticket pai e filhos (incidente em massa)

Regras da spec 13 Δ35.

**Marcar e desmarcar**
- Um agente com escrita no grupo marca um ticket **aberto**, **pendente** ou
  **em espera** como **pai**. A marca define o tipo como **incidente** no
  mesmo envio. Enquanto a marca existir, o tipo não pode ser trocado (422).
- Um ticket que já é filho não pode ser marcado como pai (422).
- **Desmarcar pai** só é aceito quando ele não tem nenhum filho vinculado
  (422 caso contrário; o agente desvincula antes). O tipo continua incidente.

**Vincular e desvincular**
- O agente vincula um ou mais tickets (filhos) ao pai, na hora em que marca ou
  depois. Precisa de escrita no grupo do pai **e** no grupo de cada filho; sem
  ver um deles, **404**; vendo sem escrita, **403** (D05, D43).
- Condições, verificadas por filho (422 com o motivo, e os demais filhos do
  mesmo pedido seguem):
  - o pai está aberto, pendente ou em espera (para vincular a um pai
    resolvido, o agente o reabre antes);
  - o filho está aberto, pendente, em espera ou resolvido; nunca fechado nem
    mesclado;
  - o filho não é pai e não tem outro pai (um nível só; um filho trocado de
    pai é desvinculado primeiro);
  - o filho não é o próprio pai.
- Vincular **não** muda estado, grupo, responsável, prioridade nem SLA do
  filho. Grava no filho o vínculo (evento de auditoria nos dois tickets; a
  versão do filho aumenta, §3).
- **Desvincular** exige escrita no grupo do **pai ou** no grupo do filho
  (basta um dos dois; D45). Quem não vê nenhum dos dois recebe 404; quem vê
  algum deles sem escrita em nenhum, 403. Desfaz o vínculo, com evento nos
  dois tickets. O filho continua no estado em que está.
- O pai fechado (pelo fechamento automático, §4.3) mantém os vínculos para
  consulta, mas não aceita vínculos novos.

**O que o pai mostra**
- A **contagem de filhos**, por estado, e a lista deles (respeitando o que o
  agente pode ver, spec 06).
- Os **locais afetados**: as salas do **pai e dos filhos** (§5.3), cada sala
  uma vez só, com a quantidade de tickets (pai e filhos) em cada uma,
  agrupadas por campus, e a quantidade de tickets sem local (D48).

**Cascata** (detalhe na spec 05 §4.5)
- Uma **resposta pública** escrita no pai é registrada também em cada filho
  em **qualquer estado, exceto fechado e mesclado** (aberto, pendente, em
  espera ou resolvido; D46), como resposta pública do mesmo agente com a
  marca "via ticket pai #N", e entregue pelo canal de resposta de cada filho
  (spec 03 §2.3). Num filho **resolvido**, a resposta entra **sem mudar o
  estado**, como qualquer resposta pública de agente sem estado escolhido
  (§4.3). Notas internas do pai **não** vão aos filhos.
- **Resolver o pai** resolve os filhos aberto, pendente e em espera, cada um
  numa operação própria (§4.3), com a mesma resposta, quando houver. As
  validações para resolver (§4.2) valem em cada filho; com responsável
  obrigatório ligado, o filho **sem responsável** recebe como responsável
  **quem resolveu o pai** e então é resolvido (D47). Se essa pessoa não pode
  ser responsável no grupo do filho, ou falta um campo obrigatório, o filho
  fica como estava (detalhe na spec 05 §4.5).
- A pesquisa de satisfação **não** é enviada ao pai nem aos filhos enquanto o
  vínculo existir (spec 05 §6.2).
- Mudanças de estado do pai que **não** são resolver (pendente, em espera,
  aberto) não vão aos filhos. Mensagens do solicitante de um filho entram só
  no filho e seguem a §4.3 nele; o pai não muda. Reabrir o pai não reabre os
  filhos.
- Filho com encaminhamento com retorno registrado (spec 04) que é resolvido em
  cascata vai para resolvido; a origem do encaminhamento é limpa, e quem
  encaminhou é avisado.

**Mescla**: um ticket pai com filhos, ou um filho, não pode ser origem nem
destino de mescla enquanto o vínculo existir (422); o agente desvincula antes
(§6.1).

Fica para a fase 2: sugestão automática de vínculo quando tickets parecidos
chegam juntos, e dividir um ticket em dois.

---

## 5. Campos personalizados

- Cada definição pertence a uma entidade: **ticket**, **pessoa** ou
  **organização** (D21, spec 13 Δ22). As regras abaixo valem para as três,
  salvo onde indicado.
- Tipos no MVP: texto curto, texto longo, número inteiro, decimal, data,
  caixa de seleção (sim/não), lista de escolha única, lista de escolha múltipla.
- O **tipo não pode ser alterado** depois da criação; para mudar, cria-se outro
  campo. Um dos projetos impõe a mesma regra, e ela evita migrações de dados
  ambíguas.
- Campo pode ser **desativado** (some dos formulários, valores antigos
  preservados e visíveis no histórico). Exclusão definitiva só se nenhum
  registro tiver valor.
- Campo novo começa **vazio** em todos os registros existentes.
- Opções de lista têm um valor estável (chave) e um rótulo editável; renomear
  o rótulo não altera registros.
- Validação no servidor (tipo, obrigatoriedade, opção existente, condição de
  exibição).
- **Obrigatoriedade** (campos de ticket): nenhuma, **para abrir** (portal e
  agente) ou **para resolver** (§4.2).
- Visibilidade por campo: só agentes, ou também solicitante no portal
  (somente leitura ou editável na abertura). Campo "só agentes" nunca aparece
  no formulário do portal.
- Campos de **pessoa** e **organização** são vistos e editados por agentes
  (no painel de contexto do ticket, spec 13 Δ18) e podem ser usados em filas,
  regras e relatórios. Mudanças neles geram eventos de auditoria da pessoa ou
  da organização, não do ticket, e não mudam a versão de nenhum ticket.
  Exemplos da EARJ: gestor, equipe, cargo e identificação da máquina (pessoa);
  notas (organização).

### 5.1 Condição de exibição (campos condicionais)

Regras da spec 13 Δ2, valendo para campos de ticket:
- Um campo pode ter uma **condição de exibição**: aparece só quando outro
  campo (o campo **de controle**, de lista ou caixa de seleção) tem certos
  valores. Ex.: "Equipamento" aparece só quando "Motivo do contato" =
  hardware, e "Sintoma" só quando "Equipamento" = impressora (motivo →
  equipamento → sintoma, spec 13 §4). Também servem de controle o **tipo do ticket** (os campos do
  evento dependem de tipo = evento, §5.2) e o **campus do local** (§5.3).
- Condições podem ser encadeadas (A → B → C), mas **não** podem formar ciclo.
  O admin não consegue salvar uma definição que gere ciclo (422).
- Um campo **oculto** (condição falsa) **não é obrigatório**, para abrir nem
  para resolver, mesmo que esteja marcado como obrigatório.
- Quando o campo de controle muda e um campo fica oculto, o valor dele é
  **limpo** no mesmo envio, em cascata pela cadeia (se B fica oculto e é
  controle de C, C também fica oculto e é limpo). Cada limpeza gera um evento
  de auditoria próprio, com valor anterior, valor novo vazio e o motivo
  "campo ficou oculto". O envio inteiro conta como **uma** mudança de versão.
- As regras valem no portal, na tela do agente, nas automações, nas macros e
  na API. Enviar valor para um campo que, com os demais valores do mesmo
  envio, ficaria oculto é **erro de validação (422)** no campo; nada é
  gravado.
- Desativar o campo de controle torna ocultos os campos que dependem dele.

### 5.2 Campos do evento (tipo = evento)

Regras da spec 13 Δ34. São **campos de sistema** do ticket, visíveis só quando
o tipo é **evento** (condição de exibição fixa, §5.1):

| Campo | Tipo | Obrigatório com tipo = evento |
|---|---|---|
| Tipo de evento | lista definida pelo admin (na EARJ: assembly, homecoming, tradução simultânea, evento entre campi, pequeno evento, outro) | sim |
| Data do evento | data | sim |
| Início e fim do evento | horas no dia do evento, no fuso da conta | sim |
| **Início da montagem** | data e hora | sim |
| Local | o local do ticket (§5.3) | sim |
| Público estimado | número inteiro ≥ 1 | não |
| Equipamentos pedidos | lista de escolha múltipla definida pelo admin | não |
| **Pronto para o evento** | marca (ligada/desligada), com autor e instante | não; começa desligada |

O nome do evento é o **assunto** do ticket; as observações são a mensagem.
"Tipo de evento" é o termo padrão (D53); não confundir com o **tipo do
ticket**, que vale "evento" para todos eles.

- **Validação** (422 no campo; nada gravado): fim depois do início; início da
  montagem **antes ou igual** ao início do evento; na criação, data do evento
  e início da montagem não podem estar no passado.
- **Obrigatórios sempre que visíveis**: qualquer envio (portal, agente,
  automação, macro, API) que deixe um ticket do tipo evento sem um campo
  obrigatório é recusado (422). Mudar o tipo de outro valor **para** evento
  exige os campos no mesmo envio.
- Mudar o tipo **do ticket** de evento para outro valor **limpa** os campos
  do evento (inclusive a marca "pronto"), menos o local, com os eventos de
  limpeza do §5.1, numa só mudança de versão.
- **Fora do prazo**: marca derivada, calculada quando o ticket é criado e
  recalculada quando o início da montagem muda. O pedido está **no prazo**
  quando a data local do início da montagem é igual ou posterior à data local
  da criação somada da **antecedência mínima** em dias úteis (configurável;
  padrão **5 dias úteis**). Dias úteis são as datas com expediente no
  calendário do grupo do ticket (spec 05 §7.3), sem contar a data da criação.
  Fora disso, o pedido é aceito e marcado "fora do prazo". A marca aparece
  para agentes, nas filas e nos relatórios.
- O ticket de evento aparece no **calendário de eventos** pela data do evento
  (spec 08), além das filas normais.
- **Pronto para o evento** (D44): marca posta por agente com **escrita** no
  grupo do ticket (agente de apoio e quem só tem leitura → 403). Registra
  quem e quando, gera evento de auditoria e é mudança de campo (versão, §3).
  Pode ser ligada a qualquer momento enquanto o ticket é do tipo evento e
  não está fechado nem mesclado, inclusive depois do início da montagem
  (conta como "atrasado" na spec 11 §6.12). Pode ser **desfeita** só até o
  início da montagem; depois dele, desligar é recusado (422). É o fato que a
  spec 11 conta em "% de eventos prontos até a montagem" e que o selo de prazo
  mostra (spec 05 §7.15).
- O prazo principal do ticket é o **início da montagem**, cumprido pela marca
  "pronto". A **1ª resposta** segue a política de SLA comum; a **resolução**
  comum não se aplica (D40; spec 05 §7.14). Depois do evento, o técnico
  resolve normalmente.

### 5.3 Local do ticket e cadastro de locais

Regras da spec 13 Δ33.
- **Cadastro** (só admin): campus → prédio → andar → sala. Cada **sala** tem
  nome, **código curto** único na conta e imutável, campus, prédio e andar.
  Renomear uma sala não muda o código nem o QR. Uma sala pode ser
  **desativada** sem apagar o histórico; sala com tickets não é excluída.
- O **local do ticket** é uma sala ativa. Escolher sala desativada, ou de
  outra conta, é erro de validação (422). Tickets antigos mantêm a sala
  desativada e continuam mostrando o nome atual dela.
- O local vem do **QR** da sala, da escolha no formulário (incluindo "minhas
  salas") ou do agente (spec 03 §4.9). A mensagem inicial guarda **de onde**
  veio o local (QR, minhas salas, escolha). Etiquetas nunca definem o local.
- Mudar o local é mudança de campo: evento de auditoria e versão.
- **Minhas salas**: a Pessoa guarda uma lista ordenada de salas ativas onde
  trabalha. A própria pessoa edita no portal; agentes a veem no painel de
  contexto. Uma sala desativada some da lista dela.
- O local, o campus e o andar podem ser usados em filas, regras, condições de
  exibição (campus, §5.1), distribuição (spec 04) e relatórios (spec 11).

---

## 6. Mescla (merge)

### 6.1 Mescla de tickets

- Um agente mescla o ticket **origem** em um ticket **destino**. Os dois
  precisam estar na mesma conta, e o agente precisa ter escrita em ambos.
- Efeito:
  1. Todas as mensagens da origem passam a aparecer no destino, em ordem
     cronológica, marcadas com "vinda de #N".
  2. Solicitante da origem, se for diferente do destino, vira **participante**
     do destino; participantes, **seguidores** e etiquetas são unidos.
  3. As **conversas paralelas** da origem passam para o destino, com os
     mesmos identificadores de e-mail e o mesmo estado (aberta ou encerrada).
  4. A origem vai para **mesclado**, fica somente leitura e guarda um ponteiro
     para o destino.
  5. Uma nota interna é registrada nos dois tickets.
  6. Os indicadores e marcos de tempo do destino (sem primeira resposta,
     momento da primeira resposta, prazos de SLA) **não mudam** com a mescla;
     as mensagens trazidas da origem não contam como atividade nova do destino.
  7. Uma origem do encaminhamento registrada na origem é descartada; a do
     destino se mantém.
- **Qualquer mensagem futura que resolva para a origem** (por cabeçalhos de
  e-mail, marcador no assunto ou link do portal), inclusive as de conversa
  paralela, é entregue ao **destino**, seguindo o ponteiro, inclusive em
  cadeias (A→B→C entrega em C). Dois dos projetos fazem esse
  redirecionamento.
- Não se mescla um ticket já **mesclado**, nem um ticket com ele mesmo; ciclos
  são impossíveis.
- Não se mescla um ticket **pai** com filhos nem um **filho** enquanto o
  vínculo existir, nem como origem nem como destino (422; §4.8).
- Desfazer mescla e dividir ticket ficam fora do MVP.

### 6.2 Mescla de pessoas

Para solicitantes duplicados (spec 13 Δ22):
- Um agente completo (spec 06) ou admin mescla a pessoa **origem** na pessoa
  **destino**. Não se mescla agente, nem uma pessoa com ela mesma, nem uma
  pessoa já mesclada.
- Os endereços, os tickets (como solicitante e como participante) e a
  organização da origem passam para o destino. Se o destino já tem
  organização, a dele prevalece. Valores de campos de pessoa vazios no
  destino recebem os da origem; os preenchidos não mudam.
- Cada ticket afetado ganha um evento de auditoria de mudança de solicitante
  ou de participante (o que aumenta a versão do ticket); se origem e destino
  eram ambos do mesmo ticket, ficam unidos num só papel (o de solicitante
  prevalece).
- A origem fica marcada como **mesclada**, com ponteiro para o destino.
  Mensagens futuras de um endereço que pertencia à origem já chegam ao
  destino, porque o endereço mudou de dono.
- Desfazer mescla de pessoas fica fora do MVP.

---

## 7. Auditoria

- Toda mudança em ticket gera um **evento de auditoria**, gravado na mesma
  transação da mudança: ator, momento, campo, valor anterior, valor novo e
  **origem**.
- Origens possíveis (lista fechada, usada por todas as specs):
  - **agente** (inclui admin; o ator identifica quem);
  - **solicitante** (qualquer pessoa que não é agente agindo no ticket:
    solicitante, participante ou convidado; o ator identifica quem);
  - **sistema** (tarefas de tempo, redirecionamentos, limpezas automáticas);
  - **automação** (com a identificação da regra);
  - **API** (com a identificação do token; o ator é o dono do token, agente ou
    identidade de integração).
- Além das mudanças de campo e estado, geram evento: criar mensagem (sem
  duplicar o corpo); seguir e deixar de seguir; abrir e encerrar conversa
  paralela; encaminhar com retorno, devolver e cancelar o retorno (spec 04);
  marcar e desmarcar spam; mesclar; criar continuação; registrar ou alterar
  uma avaliação; limpar valor de campo oculto (§5.1); usar um recurso de IA
  (quem, quando, qual ticket, sem guardar o conteúdo; spec 13 §6); marcar e
  desmarcar pai, vincular e desvincular filho (nos dois tickets); ligar e
  desligar "pronto para o evento" (§5.2, D44); cada mudança
  feita em cascata a partir do pai, com a marca "via ticket pai #N" (§4.8).
- Mudanças no cadastro de locais e em "minhas salas" geram eventos de
  auditoria próprios (da sala ou da pessoa), não do ticket.
- Eventos são append-only. Não há edição nem exclusão pela interface ou pela API.
- O histórico é exposto na interface do agente e na API (spec 10). O
  solicitante não vê o histórico.
- Motivo: os projetos que documentam histórico mostram "quem e quando", mas
  raramente "antes e depois". Esse dado é barato de gravar desde o início e caro
  de reconstruir depois. Também alimenta as métricas da spec 11.

---

## 8. Abordagens comparadas

### 8.1 Por projeto (segundo a documentação pública)

| Projeto | Unidade e estados | Resposta em fechado | Mescla | Prós | Contras |
|---|---|---|---|---|---|
| Zammad | ticket com mensagens tipadas; aberto, dois tipos de pendente com data, fechado, mesclado; "novo" até a 1ª resposta; sem resolvido | política por grupo: reabrir, ticket novo, ou reabrir dentro de N dias | origem marcada, respostas futuras redirecionadas ao destino | política com janela de dias; redirecionamento após mescla | "resolver e fechar depois" exige truque com pendência |
| Chatwoot | conversa (sem número no assunto): aberto, pendente, adiado, resolvido | sempre reabre | só de contatos | modelo simples, bom para chat | sem "fechado"; sem número legível no e-mail |
| FreeScout | conversa em caixa compartilhada: ativo, pendente, fechado, spam | não documentado | existe (versões recentes) | leve | quem responde em Cc vira o cliente; adiar e fechamento automático são pagos |
| osTicket | ticket com thread e eventos; estados livres mapeados para aberto/fechado | definida em cada estado fechado: reabre (e para qual estado) ou cria ticket novo referenciando o antigo | pai/filho, respostas do filho vão para o pai | política muito expressiva | configuração espalhada pelos estados |
| Znuny | ticket com mensagens; novo, aberto, pendentes (lembrete e automático), fechado, mesclado | política por fila: reabrir, rejeitar com aviso, ou ticket novo vinculado | irreversível, com registro de auditoria | histórico completo de ações | modelo complexo; "novo" some depois da comunicação |
| UVdesk | ticket com thread; aberto, pendente, respondido, resolvido, fechado | não documentado | não documentado | tem resolvido e fechado | documentação escassa |
| Frappe Helpdesk | ticket; estados livres agrupados em categorias aberto/pausado/resolvido; fechado fixo | cliente não responde em fechado (pelo portal, ao menos) | não documentado | categoria de estado ligada ao SLA; fechamento automático nativo | bloquear a resposta cria atrito |

### 8.2 Escolhas do PantherDesk

| Aspecto | Escolha | Motivo |
|---|---|---|
| Unidade de trabalho | ticket com número, mensagens com canal | número legível ajuda o cliente e o encadeamento; conversa sem número (Chatwoot) não serve para e-mail |
| Resolvido vs fechado | separados (como UVdesk e Frappe) | mais claro; fechamento automático trivial, sem truque de pendência (Zammad, Znuny) |
| Aguardando alguém | **pendente** (solicitante) separado de **em espera** (terceiro), ambos pausando o SLA (categoria "pausado", ideia vinda do Frappe) | a operação EARJ depende de fornecedores e de outras equipes; o solicitante não deve ver "aguardando sua resposta" quando quem deve é outro |
| Resposta em fechado | por grupo, com janela de N dias (inspirado no Zammad); `novo` na EARJ, como o "ticket novo vinculado" do Znuny e do osTicket | fácil de administrar; evita ressuscitar tickets antigos e duplicar respostas imediatas |
| Estados personalizados | fixos no MVP, já com categoria (ideia da categoria vinda do Frappe) | previsibilidade agora, extensível depois |
| Cc que responde | vira participante (oposto do FreeScout) | trocar o solicitante surpreende o usuário |
| Quem acompanha | **participante** (externo, recebe e-mail) separado de **seguidor** (agente, só notificação) | colocar colegas em Cc expõe nomes e endereços internos ao solicitante |
| Contato com terceiros | conversa paralela dentro do ticket | evita a troca de e-mails por fora, que se perde do histórico |
| Responsável para resolver | exigência configurável por conta | a EARJ quer saber sempre quem resolveu; outras contas podem não querer |
| Mescla | origem marcada + redirecionamento (Zammad, osTicket) | sem redirecionamento, as respostas futuras se perdem |
| Incidente em massa | ticket pai com filhos vinculados, sem juntar as conversas; resposta e resolução em cascata | cada solicitante continua no seu ticket e recebe a resposta no seu idioma (spec 13 Δ35) |
| Local | cadastro de salas com código estável, ligado ao ticket | etiquetas de campus não garantem consistência nem permitem o QR por sala (spec 13 Δ33) |
| Histórico | evento com antes/depois e origem | só "quem e quando" limita a auditoria e as métricas |

---

## 9. Casos de teste de comportamento (critérios de aceite)

Atores: `ag1` e `ag2` (escrita no grupo N1), `ag3` (escrita no grupo
Financeiro, nenhum acesso ao N1), `apoio1` (leitura em todos os grupos),
`admin` (não é membro de nenhum grupo), solicitante `ana` (org. Acme), `bia`
(org. Acme), `cris` (sem org.), `dani` (pessoa sem relação com os tickets).
Fuso: America/Sao_Paulo (UTC−3, sem horário de verão). Salvo indicação, a
conta não exige responsável para resolver.

### 9.1 Criação e numeração
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| TL-01 | conta nova | ag1 cria ticket para ana no grupo N1 | estado aberto, prioridade normal, tipo vazio, sem responsável, sem seguidores, número 1000, indicador "sem primeira resposta" ligado, 1 evento de criação |
| TL-02 | ticket 1000 existe | 50 tickets criados em paralelo | números 1001–1050 sem repetição |
| TL-03 | — | criar ticket sem grupo | erro de validação (422); nada gravado |
| TL-04 | — | criar ticket com responsável ag3 no grupo N1 | erro de validação (422): responsável sem escrita no grupo; nada gravado |
| TL-05 | ticket 1005 mesclado | criar ticket novo | o número 1005 não é reutilizado |
| TL-06 | ticket aberto no grupo Financeiro; admin não é membro | ag3 atribui o ticket ao admin | ok; responsável admin (D06) |
| TL-07 | — | ag1 cria ticket com tipo "incidente"; depois tenta criar outro com tipo "defeito" | o primeiro é criado com tipo incidente; o segundo é recusado (422: opção inexistente) |
| TL-08 | — | ag1 cria ticket para cris no modo "registrar pedido", meio declarado "telefone" | mensagem inicial com autoria de cris e marca "registrada por ag1"; canal `agente`, meio declarado "telefone" (D34) |

### 9.2 Transições
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| TL-10 | ticket aberto | ag1 muda para pendente | ok; evento com antes=aberto, depois=pendente |
| TL-11 | ticket fechado | ag1 (não admin) tenta mudar para aberto | recusado com **403**; estado continua fechado; nenhum evento |
| TL-12 | ticket fechado | admin usa "reabrir ticket fechado" | estado aberto; evento com origem agente e ator admin |
| TL-13 | ticket mesclado | ag1 tenta qualquer mudança de estado | recusada com **422** |
| TL-14 | campo "Causa" obrigatório para resolver, visível, vazio | ag1 muda para resolvido | recusado (422) com indicação do campo |
| TL-15 | ticket pendente | ana, com a sessão do portal, tenta mudar o campo de estado direto para fechado | recusado com **403** (o solicitante só muda o estado por resposta ou pela ação "resolvido") |
| TL-18 | ticket aberto de ana | ana usa "meu problema foi resolvido" no portal | estado resolvido; marca "resolvido pelo solicitante"; mensagem de sistema pública; evento com origem solicitante |
| TL-16 | ticket na versão 7 | ag1 e ag2 salvam mudanças de campo, ambos a partir da versão 7 | a primeira é gravada (versão 8); a segunda é recusada com conflito (409), nada é sobrescrito e o rascunho de ag2 é preservado |
| TL-17 | — | qualquer ator tenta excluir um ticket | operação inexistente (não há exclusão no MVP) |
| TL-19 | ticket aberto de ana; bia é participante | bia usa "meu problema foi resolvido" no portal | recusado com **403** (só o solicitante); estado continua aberto |
| TL-80 | ticket na versão 7 | ag2 grava nota interna sem informar versão; depois ag1 muda a prioridade a partir da versão 7 | nota gravada e versão continua 7; a mudança de prioridade é aceita e a versão vai a 8 |
| TL-81 | ticket na versão 8; a tela de ag1 está na versão 7 | ag1 envia resposta pública com estado pendente, a partir da versão 7 | envio inteiro recusado (409): nem a mensagem nem o estado são gravados; o rascunho é preservado |
| TL-82 | ticket na versão 8 | pela API, sem versão, um token de ag1 muda a prioridade | aceito; versão 9; o uso sem versão fica registrado |
| TL-83 | ticket fechado | admin tenta mudar para pendente | recusado com **422** (transição inexistente) |
| TL-84 | ticket aberto, versão 3 | ag1 envia resposta pública escolhendo "em espera" | mensagem gravada; estado em espera; 1 evento de estado; versão 4 |

### 9.3 Transições automáticas
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| TL-20 | ticket pendente com data de retorno D | ana responde por e-mail antes de D | estado aberto; a data de retorno é removida |
| TL-21 | ticket resolvido | bia (participante confirmada) responde | estado aberto |
| TL-22 | ticket pendente com retorno em D, sem responsável, grupo N1 | o relógio passa de D | estado aberto; notificação para ag1 e ag2 (ativos com escrita no N1), não para apoio1 nem ag3; 1 evento com origem sistema |
| TL-23 | idem | a tarefa de retorno roda 2× no mesmo minuto | 1 único evento; 1 única notificação por agente |
| TL-24 | resolvido há 4 dias e 1 minuto, sem resposta | a tarefa de fechamento roda | estado fechado |
| TL-25 | resolvido seg 2026-11-02 10:00; ana responde qua 2026-11-04 (volta a aberto); ag1 resolve de novo qui 2026-11-05 10:00 | a tarefa de fechamento roda sáb 2026-11-07 10:00, seg 2026-11-09 09:59 e seg 2026-11-09 10:00 | sáb: continua resolvido (a contagem reiniciou em 11-05; passaram 2 dias); seg 09:59: continua resolvido (3 d 23 h 59 min); seg 10:00: fechado (exatamente 4 dias) |
| TL-26 | ticket pendente | chega resposta automática de ausência na thread | estado continua pendente; a mensagem é gravada como mensagem de sistema interna |
| TL-27 | ticket aberto | ag1 escreve nota interna | estado não muda; o indicador "sem primeira resposta" continua ligado |
| TL-28 | ticket aberto, sem primeira resposta | ag1 envia resposta pública | o indicador desliga; o momento da primeira resposta fica gravado |
| TL-29 | resolvido qui 2026-11-05 10:00 (13:00Z), sem resposta | a tarefa de fechamento roda seg 2026-11-09 10:00 (13:00Z) | estado fechado (decorridos exatamente 4 dias: a regra é ≥) |
| TL-90 | ticket pendente de ana; dani entrou como participante não confirmada | dani responde por e-mail | mensagem gravada; estado continua pendente; "última atividade do cliente" não muda; o responsável é notificado para confirmar dani |
| TL-91 | após TL-90 | ag1 confirma dani; depois dani responde de novo | a primeira mensagem não muda nada retroativamente; a nova reabre o ticket (aberto) |
| TL-92 | ticket marcado como spam (fechado) | ag1 desmarca spam | marca retirada; evento próprio; o ticket continua **fechado** (D16) |

### 9.4 Resposta em ticket fechado
| ID | Política do grupo | Dado | Ação | Resultado esperado |
|---|---|---|---|---|
| TL-30 | reabrir | fechado há 30 dias | ana responde | mesmo ticket, aberto, mensagem anexada |
| TL-31 | novo | fechado há 1 dia | ana responde | ticket novo vinculado ao anterior; o anterior continua fechado; o novo tem os participantes do anterior |
| TL-32 | janela 14 | fechado há 13 dias 23 h | ana responde | reabre |
| TL-33 | janela 14 | fechado há 14 dias e 1 min | ana responde | ticket novo vinculado |
| TL-34 | janela 14 | fechado há 20 dias | ana abre o ticket no portal | o portal oferece "abrir novo pedido", não "responder" |
| TL-35 | reabrir | responsável ag2 foi desativado | ana responde | reabre sem responsável, na fila do grupo |
| TL-36 | novo (EARJ) | ticket de chat de bia fechado há 2 h | bia escreve de novo no widget | ticket novo vinculado, canal chat; o anterior continua fechado |
| TL-37 | qualquer | ticket fechado de ana, tipo incidente, campo "Produto" = `vpn`, participante bia, responsável ag2 | ag1 usa "criar continuação" | ticket novo aberto, vinculado ("continuação de #N"), solicitante ana, participante bia, mesmo grupo, tipo e "Produto"; sem responsável e sem mensagens copiadas; o fechado não muda |
| TL-38 | qualquer | ticket aberto | ag1 tenta "criar continuação" | recusado (422) |

### 9.5 Mescla
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| TL-40 | #1010 (ana) e #1011 (bia), ambos abertos | ag1 mescla 1011 em 1010 | 1011 mesclado e somente leitura; mensagens de 1011 visíveis em 1010; bia vira participante de 1010; nota interna nos dois |
| TL-41 | após TL-40 | chega e-mail de bia respondendo a uma mensagem de 1011 | a mensagem entra em 1010 |
| TL-42 | 1011→1010, depois 1010 mesclado em 1012 | chega resposta a 1011 | entra em 1012 |
| TL-43 | — | mesclar um ticket nele mesmo | recusado (422) |
| TL-44 | ag3 sem acesso ao grupo de 1010 | ag3 tenta mesclar | recusado com **404** (ag3 não vê o ticket; spec 06) |
| TL-45 | #1020 com seguidor ag2 e uma conversa paralela aberta com um fornecedor; #1021 aberto | ag1 mescla 1020 em 1021 | 1021 tem ag2 como seguidor e a conversa paralela; a próxima resposta do fornecedor entra nessa conversa em 1021 |

### 9.6 Campos e auditoria
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| TL-50 | campo lista "Produto" com opção chave `vpn`, rótulo "VPN" | renomear o rótulo para "VPN corporativa" | tickets com `vpn` mostram o novo rótulo; nenhum evento nos tickets |
| TL-51 | campo "Produto" em uso | tentar mudar o tipo para texto | recusado |
| TL-52 | campo desativado com valores | abrir ticket antigo | o valor aparece no histórico e não aparece no formulário de edição |
| TL-53 | automação "assunto contém fatura → grupo Financeiro" | ticket criado com assunto "fatura errada" | evento de mudança de grupo com origem automação e a identificação da regra |
| TL-54 | qualquer ticket | ana, com a sessão do portal, consulta o histórico do próprio ticket | recusado (403) |
| TL-55 | "Equipamento" (lista) visível só se "Motivo do contato" = hardware; "Sintoma" (lista) visível só se "Equipamento" = impressora; ticket v5 com motivo hardware, equipamento "impressora", sintoma "não imprime" | ag1 muda o motivo para rede | Equipamento e Sintoma limpos; 3 eventos (motivo, limpeza de Equipamento, limpeza de Sintoma, as limpezas com motivo "campo ficou oculto"); versão 6 (revisto em v0.3, D51) |
| TL-56 | campos A e B | admin define "A visível se B = x" e "B visível se A = y" | a segunda definição é recusada (422: ciclo) |
| TL-57 | "Equipamento" obrigatório para resolver; ticket com motivo rede | ag1 resolve | ok (campo oculto não é obrigatório) (revisto em v0.3, D51) |
| TL-58 | idem | pela API, criar ticket com motivo rede e equipamento "impressora" | recusado (422) no campo Equipamento; nada gravado (revisto em v0.3, D51) |
| TL-59 | campo de pessoa "Cargo" (texto curto) | ag1 preenche "Coordenadora" no cadastro de ana | valor gravado na pessoa; evento de auditoria da pessoa; nenhum ticket de ana muda de versão |

### 9.7 Em espera e responsável obrigatório
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| TL-60 | ticket aberto de ana, responsável ag1 | ag1 muda para em espera | ok; evento antes=aberto, depois=em espera; o prazo de resolução pausa; no portal ana vê "em andamento" |
| TL-61 | ticket em espera com data de retorno D | ana responde por e-mail antes de D | estado aberto; a data de retorno é removida |
| TL-62 | ticket em espera com retorno em D, responsável ag1 | o relógio passa de D | estado aberto; ag1 notificado; 1 evento com origem sistema |
| TL-63 | ticket em espera | ag1 muda para pendente e depois de volta para em espera | as duas transições são aceitas; 2 eventos |
| TL-64 | ticket em espera de ana | ana usa "meu problema foi resolvido" | estado resolvido (D08) |
| TL-65 | ticket resolvido | ag1 tenta mudar para em espera | recusado (422) |
| TL-66 | conta exige responsável para resolver; ticket aberto sem responsável | ag1 muda para resolvido | recusado (422) com indicação do responsável |
| TL-67 | idem | ag1 muda direto para fechado | recusado (422) com indicação do responsável |
| TL-68 | idem | ag1 envia, no mesmo envio, "responsável = eu" e estado resolvido | ok: atribuído a ag1 e resolvido (a validação usa o ticket depois das mudanças) |
| TL-69 | idem, ticket de ana | ana usa "meu problema foi resolvido" | estado resolvido, com a marca "resolvido pelo solicitante" (as validações não se aplicam ao solicitante; D33) |

### 9.8 Seguidores, conversa paralela, pessoas e ações
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| TL-70 | ticket de ana no N1, versão 4 | ag2 passa a seguir | ag2 é seguidor, não participante; evento; versão continua 4; ana não vê ag2 no portal |
| TL-71 | após TL-70 | ag1 envia resposta pública | o e-mail a ana não tem ag2 em Cc; ag2 recebe notificação (spec 09) |
| TL-72 | ticket do N1 | ag3 (sem acesso ao N1) tenta seguir | recusado com **404** |
| TL-73 | ticket do N1 que apoio1 vê (leitura) | apoio1 passa a seguir e depois deixa de seguir | as duas ações são aceitas; 2 eventos |
| TL-74 | ticket em espera com conversa paralela aberta com um fornecedor | chega a resposta do fornecedor na conversa paralela | a mensagem entra na conversa paralela, não na principal; estado aberto; responsável e seguidores notificados; o SLA não registra resposta do solicitante |
| TL-75 | ticket pendente com conversa paralela aberta | chega a resposta do fornecedor | a mensagem entra na conversa paralela; estado continua pendente |
| TL-76 | após TL-74 | ana abre o ticket no portal | a conversa paralela não aparece |
| TL-77 | pessoa "Ana R." (endereço ana.r@mail.test, solicitante de #1030, participante de #1031) duplicada de ana | ag1 mescla "Ana R." em ana | o endereço passa para ana; ana vira solicitante de #1030 e participante de #1031, com eventos nos dois tickets; "Ana R." fica mesclada, com ponteiro para ana |
| TL-78 | idem | apoio1 (agente de apoio) tenta mesclar as pessoas | recusado com **403** |
| TL-79 | ticket com 2 mensagens públicas, 1 nota interna e 1 conversa paralela | ag1 imprime sem e depois com "incluir internos" | 1ª versão: só as 2 mensagens públicas; 2ª: também a nota e a conversa paralela; o ticket não muda |

### 9.9 Ajustes D23–D37
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| TL-93 | ticket em espera de ana no N1, responsável ag1 | ag1 encaminha com retorno ao Financeiro (nota interna) | estado **aberto**, grupo Financeiro, sem responsável; origem do encaminhamento N1/ag1; nas filas do N1 o ticket aparece com a marca "encaminhado" e o filtro "encaminhado" o encontra; nenhum outro estado é gravado (D23) |
| TL-94 | após TL-93 | ag1 escreve nota interna; depois tenta mudar a prioridade | nota aceita (D24); mudança de prioridade recusada com **403** (a origem só tem leitura) |
| TL-95 | conta exige responsável para resolver; campo "Causa" obrigatório para resolver, visível, vazio; ticket aberto de ana sem responsável | ana usa "meu problema foi resolvido"; 4 dias depois roda o fechamento automático | resolvido com a marca "resolvido pelo solicitante"; depois fechado pelo sistema, sem recusa (D33) |
| TL-96 | após o primeiro passo de TL-95 | ana responde por e-mail antes do fechamento | estado aberto; a marca "resolvido pelo solicitante" some |
| TL-97 | — | ag1 cria ticket para cris no modo "registrar pedido" sem informar o meio declarado | recusado (422) no meio declarado; nada gravado (D34) |

### 9.10 Decisões de 2026-10-29 (pai, evento, local, Google)

Configuração adicional: grupo **Eventos** (ag2 com escrita), com o calendário
C5 da spec 05 §9.1 (seg–sex 07:00–17:00, America/Sao_Paulo, sem feriados em
novembro de 2026) e antecedência mínima de 5 dias úteis. Cadastro de locais:
campus Barra → prédio A → 1º andar → salas "Sala 101" (código `B101`) e
"Auditório" (`BAUD`); "Lab 2" (`BLAB2`), desativada. Login com Google ligado
para o domínio `escola.test`. 2026-11-11 é uma quarta-feira.

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| TL-100 | #1040 aberto de ana no N1, tipo vazio, versão 2 | ag1 marca #1040 como pai | marca pai gravada; tipo incidente; 2 eventos (marca e tipo) com origem agente; versão 3 |
| TL-101 | após TL-100; #1041 (bia, aberto) e #1042 (cris, em espera) no N1 | ag1 vincula #1041 e #1042 ao pai | os dois filhos guardam o vínculo; estados, responsáveis e SLA não mudam; versão de cada filho +1; versão do pai continua 3; o pai mostra 2 filhos (1 aberto, 1 em espera); eventos nos três tickets |
| TL-102 | após TL-101; #1050 marcado como pai; #1043 fechado | ag1 vincula #1041 a #1050; depois #1040 a #1050; depois #1043 a #1040 | os três recusados (422): já tem pai; um pai não pode ser filho; filho fechado |
| TL-103 | após TL-101; #1060 no Financeiro | ag1 (sem acesso ao Financeiro) tenta vincular #1060 ao pai | recusado com **404**; nada gravado |
| TL-104 | após TL-101 | ag1 tenta mesclar #1041 em #1044; depois tenta mesclar #1044 em #1040 | os dois recusados (422: vínculo de pai e filho) |
| TL-105 | após TL-101; #1044 (dani) resolvido e vinculado | ag1 envia resposta pública no pai escolhendo resolvido | pai resolvido; #1041 e #1042 resolvidos, cada um numa operação com a marca "via ticket pai #1040" e com a resposta registrada como resposta pública de ag1; #1044 continua resolvido e também recebe a resposta; nenhum convite de avaliação (spec 05 AU-184) |
| TL-106 | após TL-105 | cris responde por e-mail no filho #1042 | #1042 volta para aberto; o vínculo continua; o pai continua resolvido |
| TL-107 | pai com local Sala 101 e 4 filhos: dois na Sala 101, um no Auditório e um sem local | ag1 abre o pai | contagem 4 filhos; locais afetados, no campus Barra, cada sala uma vez: Sala 101 (3: o pai e 2 filhos) e Auditório (1); 1 ticket sem local (revisto em v0.3, D48) |
| TL-108 | após TL-101 | ag1 tenta mudar o tipo do pai para tarefa; depois tenta desmarcar o pai | as duas mudanças recusadas (422): tipo travado enquanto pai; desmarcar exige nenhum filho |
| TL-109 | após TL-108 | ag1 desvincula #1041 e #1042 e desmarca o pai | aceito; eventos de desvínculo nos três tickets; o pai perde a marca e continua com tipo incidente |
| TL-110 | pai #1040 resolvido | ag1 tenta vincular #1045 (aberto) | recusado (422): pai resolvido não aceita vínculo; depois de reaberto, aceita |
| TL-111 | qua 2026-11-11 10:00 | ag2 cria ticket no Eventos, tipo evento, "Assembly do 5º ano", tipo de evento assembly, data qui 2026-11-19, 14:00–16:00, montagem qua 2026-11-18 08:00, local Auditório | ticket criado sem a marca "fora do prazo": a data mínima é qua 2026-11-18 (qui 12, sex 13, seg 16, ter 17, qua 18) |
| TL-112 | idem, mas montagem ter 2026-11-17 08:00 | ag2 cria | ticket criado com a marca "fora do prazo" |
| TL-113 | qua 2026-11-11 10:00 | ag2 cria ticket de evento sem início da montagem; outro com montagem qui 2026-11-19 15:00 (depois do início, 14:00) | os dois recusados (422) no início da montagem; nada gravado |
| TL-114 | ticket de evento de TL-111, versão 1 | ag2 muda o tipo do ticket para tarefa | tipo de evento, data, horários, montagem, público e equipamentos limpos, cada um com evento "campo ficou oculto"; o local continua; versão 2 |
| TL-115 | ticket de tarefa sem campos do evento | ag2 muda o tipo para evento sem informar os campos | recusado (422) com os campos obrigatórios |
| TL-116 | ticket com local Sala 101 | admin renomeia a sala para "Sala 101 — Ciências" | o ticket mostra o nome novo; código `B101` igual; nenhum evento nem mudança de versão no ticket |
| TL-117 | ticket antigo com local Lab 2 (desativada) | ag1 abre o ticket; depois tenta definir Lab 2 em outro ticket | o antigo mostra Lab 2; a nova escolha é recusada (422) |
| TL-118 | Pessoa ana com `ana@escola.test` não verificado; ninguém com `novo@escola.test` | ana entra no portal com Google; depois `novo@escola.test` entra com Google | ana: mesmo cadastro, endereço passa a **verificado**, nome não muda; `novo@escola.test`: Pessoa criada como solicitante, endereço verificado, sem acesso de agente |
| TL-119 | pai #1040 no N1; #1060 e #1061, do Financeiro, vinculados a ele pelo admin | ag3 (escrita no Financeiro, sem acesso ao N1) desvincula #1060; ag1 (sem acesso ao Financeiro) desvincula #1061 | os dois aceitos (basta escrita no pai **ou** no filho, D45); evento de desvínculo nos dois tickets de cada vínculo |
| TL-120 | pai #1040 aberto; filhos #1041 aberto, #1044 resolvido e #1043 fechado (vinculado antes de fechar) | ag1 envia resposta pública no pai, sem escolher estado | #1041 e #1044 recebem a resposta, com a marca "via ticket pai #1040"; #1044 **continua resolvido**; #1043 não recebe nada (D46) |
| TL-121 | conta exige responsável para resolver; pai #1040 (responsável ag1) com #1041 sem responsável e #1042 com responsável ag1 | ag2 resolve o pai | pai resolvido; #1041 recebe **ag2** como responsável e é resolvido; #1042 resolvido, responsável ag1 inalterado (D47) |
| TL-122 | ticket de evento de TL-111 (montagem qua 2026-11-18 08:00), versão 1 | ter 2026-11-17 15:00 ag2 liga "pronto"; apoio1 tenta desligar; qua 2026-11-18 09:00 ag2 tenta desligar | ag2: marca ligada com ag2 e o instante, evento de auditoria, versão 2; apoio1: **403**; desligar depois do início da montagem: **422**, a marca continua (D44) |
| TL-123 | ticket do tipo tarefa | ag1 tenta ligar "pronto"; depois cria um ticket de evento ligando "pronto" na criação | 1º: recusado (422, campo oculto); 2º: aceito, com autor ag1 e o instante da criação |

---

## 10. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Estados e transições | documentação dos 7 projetos | todos os projetos: T-01, T-02 |
| Reabertura por resposta | documentação | T-03 (efeito na data de pendência, SLA e responsável) |
| Fechamento automático | documentação (só um projeto nativo) | T-04 |
| Resposta em fechado | documentação (três modelos) | T-05, principalmente pelo canal e-mail |
| Mescla e redirecionamento | documentação (dois projetos) | T-06 |
| Campos personalizados | documentação | T-07 |
| Granularidade do histórico | documentação vaga | T-08 |
| Em espera, seguidores, conversa paralela, campos condicionais, campos em pessoa, mescla de pessoas, responsável obrigatório | requisito de cliente (spec 13) | não se aplica: decisão de produto |
| Ticket pai, tipo evento, local do ticket, login com Google | requisito de cliente (spec 13 Δ31, Δ33–Δ35) | não se aplica: decisão de produto |

## 11. Questões abertas para o implementador

As duas questões da v0.2 inicial (validações para resolver na ação do
solicitante e estado durante o encaminhamento) foram respondidas pelas
decisões D33 e D23. A questão 3 da v0.3 (campos "unidade" e "setor/sala")
foi respondida pela D51 e retirada. Continuam abertas:

1. **Antecedência do evento** (§5.2): a spec 13 Δ34 não diz se os 5 dias úteis
   contam até a data do evento ou até o início da montagem. Esta spec conta até
   a **montagem**, que é o compromisso do ticket. Confirmar.
2. **Tipo do pai** (§4.8): marcar como pai define o tipo incidente e o trava
   enquanto a marca existir. Um ticket de tipo incidente **sem** a marca não é
   pai. Confirmar que não se quer o contrário (todo incidente ser pai).
