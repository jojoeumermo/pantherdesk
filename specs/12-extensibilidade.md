# Spec 12 — Extensibilidade

Status: **rascunho v0.3 (2026-10-29)**. Baseado na documentação pública dos 7
projetos analisados e nos requisitos da operação EARJ (spec 13). As evidências
de runtime ainda estão pendentes; cada ponto que depende delas está marcado
como **[evidência pendente: cenário]**. Vocabulário: spec 01. Automações e SLA:
spec 05. Permissões: spec 06. Portal e autenticação do solicitante: spec 07.
Tempo real: spec 09. API e webhooks: spec 10. Métricas: spec 11. Decisões
transversais: D01–D53. Precedência: spec 13 > decisões transversais > esta
spec.

Mudanças na v0.3:
- **Provedor de autenticação** (spec 13 Δ31): o **Google** é o primeiro
  provedor externo implementado, no MVP: única entrada de agentes e admins e
  entrada dos solicitantes do domínio da conta. O **link de acesso por
  e-mail** continua como segundo método, para quem não tem conta da escola.
  Agentes não têm senha local. Regras de domínio, primeiro acesso, retorno à
  página de origem (QR) e provedor de teste (§6.5; EX-37 refeito,
  EX-67..EX-75).
- Local do ticket (Δ33) e dados do evento (Δ34) como **campos de sistema**,
  fora do limite de campos personalizados (§3).
- Lista interna de eventos com local criado e atualizado, aviso de montagem
  e vínculo de incidente (§4.2; EX-76); paridade da API com as ações novas
  da spec 13 (§7).
- Questões abertas: saem a senha de agentes e o primeiro acesso pelo
  provedor externo (respondidas pelo Δ31); entram a contingência quando o
  Google está fora e o feed de eventos (§13).
- **Ajustes D40–D53**: o **feed de eventos** volta ao **MVP**, como na spec
  10 §4 (D52; §4.7, §9.2; EX-77). Agentes e admins entram **só com Google**;
  fora do modo de desenvolvimento não há login local para eles, e instalação
  sem Google configurado não é suportada no MVP (D53; §6.5; EX-78). A marca
  "pronto para o evento" entra nos dados do evento (D44) e o aviso de
  montagem segue a spec 05 §7.14 (D41) (§4.2). Exemplos de campo condicional
  com motivo → equipamento, sem os campos "unidade" e "setor" (D51; EX-06 e
  EX-07 revistos). Questões 3 e 5 removidas (respondidas pela D53 e pela D52).

Mudanças na v0.2:
- **Identidade de integração** refeita conforme D04: mesmo modelo de acesso
  por grupo dos agentes (nenhum, leitura, escrita) e os mesmos três escopos de
  token (leitura, escrita, administração); saíram os 8 escopos próprios e a
  lista de grupos. O termo "conta de serviço" não é mais usado.
- **Notas internas em eventos** conforme D03: só no tipo de evento próprio;
  não há escopo de notas. Conversas paralelas (spec 13 Δ17) seguem a mesma
  regra de conteúdo interno.
- **Catálogo de eventos**: o catálogo dos webhooks é o da spec 10 §11.3; a
  lista interna (§4.2) ganhou os fatos novos da spec 13 (encaminhamento com
  retorno, seguidores, menções, avaliação, conversa paralela, mesclar pessoas).
- **Feed de eventos da API** passou para o roadmap; a recuperação no MVP usa
  as retentativas e o log de entregas da spec 10 e o recurso "mudanças desde".
- **Supressão de eco** deixou de ser automática: é a opção da assinatura
  "ignorar eventos causados por um token" (spec 10 §11.1).
- Tempo real alinhado à spec 09 §3.4 (retomada de 15 min, pelo menos uma vez);
  revogação de token passou a ser imediata (spec 10 §3.2).
- **Campos personalizados em Pessoa e Organização** e **campos condicionais**
  entram no MVP (D21, spec 13 Δ2 e Δ22).
- Escopo de adaptadores reduzido no MVP: disco local e SMTP; armazenamento de
  objetos e API HTTP de provedor de envio passaram para o roadmap. Provedor de
  autenticação local alinhado à spec 07 §7.1.
- Novo adaptador **provedor de IA** (§6.6), no MVP conforme as decisões da
  spec 13 §6.
- Mensagem de integração vista pelo solicitante segue a spec 02 §9.
- Proibições esclarecidas para o widget de chat e a marca da conta (spec 13
  Δ16 e Δ25).
- Casos de teste usam os tickets #1200 e #1201, para não colidir com números
  de outras specs; EX-17 removido; questões abertas respondidas removidas.
- Ajustes D23–D37: mensagens de conversa paralela saem no tipo **nota interna
  criada**, com a indicação "conversa paralela" (D37; §4.2, §4.5); sem
  "audiência" de webhook (D31); o escopo administração só vale para a
  identidade **criada como administrativa** (D36; §5); tokens de identidade
  desativada ficam suspensos e voltam na reativação (como D26); paridade da
  API cobre prévia e aplicação de macro, rascunhos de artigo e a ação do
  solicitante (D29, D32; §7) (EX-18 refeito, EX-63..EX-66).

---

## 1. Problema

Cada cliente de um helpdesk quer adaptar o produto: guardar dados próprios do
negócio, ligar o helpdesk ao CRM, ao chat da equipe, ao sistema de cobrança,
trocar onde os anexos ficam, entrar com a conta da empresa. Se isso só for
possível alterando o código, cada instalação vira um fork. Se for possível
rodando código de terceiros dentro do servidor, cada instalação passa a
depender de código sem isolamento, que quebra a cada atualização.

O plugin system é roadmap. Mesmo assim, o MVP precisa deixar prontas as
**costuras** (pontos de extensão) que custam caro para acrescentar depois:

1. como o admin acrescenta **dados próprios** sem mudar o esquema nem
   reiniciar;
2. de onde vêm os **fatos** que integrações, webhooks, tempo real e automações
   consomem, e como garantir que todos vejam a mesma coisa;
3. **quem** é uma integração, com que permissões age e como aparece no
   histórico;
4. que peças de infraestrutura (armazenamento, e-mail, autenticação, IA) são
   **substituíveis** e que contrato cada implementação precisa cumprir;
5. o que a **API pública** garante a quem constrói em cima dela;
6. o que é **proibido** no MVP, e por quê;
7. como deve se comportar o **sistema de apps** do roadmap, para que as
   decisões do MVP não o impeçam.

---

## 2. Princípios

- **A API pública é o mecanismo principal de extensão.** Toda integração do
  MVP usa a API REST e os webhooks (spec 10). Não existe API "interna" com mais
  poderes para a funcionalidade de tickets.
- **Uma única fonte de fatos.** Webhooks, atualização em tempo real, automações
  e notificações consomem o mesmo fluxo de eventos de domínio (§4). Nenhum
  desses consumidores inventa eventos por outro caminho.
- **Declarativo antes de código.** O que pode ser resolvido por configuração
  (campos, condições de exibição, formulários, regras, gatilhos, macros, marca
  da conta) não exige código.
- **Código de terceiros fora do processo.** No MVP, nenhum código de terceiros
  roda no servidor do PantherDesk. No roadmap, apps rodam fora do processo
  principal ou em iframes isolados.
- **Toda ação tem autor.** Qualquer mudança feita por integração aparece na
  auditoria (spec 01 §7) com a identidade da integração e o token usado.

---

## 3. Campos personalizados como costura

A definição dos campos (tipos, imutabilidade do tipo, desativação, opções com
chave estável) está na **spec 01 §5**; as condições de exibição, na spec 13
Δ2; os formulários do portal, na spec 13 Δ1. Esta seção acrescenta só o que
importa para extensão.

- Entidades alvo no MVP: **ticket**, **pessoa** e **organização** (D21, spec
  13 Δ22), com os mesmos tipos e regras. A definição carrega a entidade alvo.
- Cada campo tem uma **chave** definida pelo admin na criação: letras
  minúsculas sem acento, dígitos e sublinhado, única por entidade alvo na
  conta, **imutável**. O rótulo pode mudar; a chave não. A chave é o que
  aparece na API, nos eventos, nas condições de automação, nas condições de
  exibição e no CSV (spec 11 §8, que usa o rótulo só como cabeçalho).
- Criar, desativar ou reativar um campo **não muda o esquema do banco**, não
  exige reinício e não tem etapa de "aplicar alterações". O campo fica
  disponível em todos os canais (interface, portal, API, automações, eventos)
  assim que é salvo.
- As **mesmas validações** valem para qualquer origem: interface, portal, API,
  automação, integração. Um valor inválido é recusado e nada é gravado.
- **Condições de exibição** (spec 13 Δ2) fazem parte da validação comum:
  - a condição referencia outro campo pela chave e uma lista de valores;
  - enviar valor para um campo que, pelas condições, está **oculto** é erro de
    validação, também pela API;
  - um campo oculto não é obrigatório;
  - quando uma mudança oculta um campo, o valor dele é limpo **na mesma
    operação**, e a limpeza aparece na lista de mudanças do evento, com a mesma
    origem da mudança que a causou;
  - uma condição que formaria ciclo é recusada ao salvar a definição.
- Valor de campo desativado continua aparecendo nas leituras da API e nos
  eventos, marcado como inativo, mas não pode ser escrito.
- A lista de definições de campos, com entidade alvo, visibilidade e
  condições, é exposta na API, para que uma integração descubra os campos da
  conta sem configuração manual.
- Mudanças nas **definições** (criar, renomear rótulo, desativar, acrescentar
  opção, mudar condição) geram eventos de domínio próprios (§4), para que
  consumidores internos se atualizem.
- Limites do MVP: até 200 campos por entidade alvo por conta; até 1.000
  opções por lista.
- O **tipo do ticket** (pergunta, incidente, problema, tarefa, evento; spec 13 Δ8) é
  campo de sistema, não personalizado: tem nome fixo na API e não ocupa o
  limite.
- O **local** do ticket (spec 13 Δ33) também é campo de sistema, ligado ao
  **cadastro de locais** (campus → prédio → andar → sala), e não um campo de
  lista personalizado nem uma etiqueta. O mesmo vale para os dados de que
  dependem o calendário, os avisos e as métricas de eventos (Δ34): nome e
  tipo do evento, início, fim e início da montagem. Os demais campos do
  formulário de evento (público estimado, equipamentos, observações) seguem
  a spec 01 §5. O vínculo de **incidente pai** (Δ35) é uma relação de
  sistema entre tickets.

---

## 4. Fluxo interno de eventos de domínio

### 4.1 Origem única
- Toda operação que muda dados grava, **na mesma transação**, os eventos de
  auditoria (spec 01 §7) e os **eventos de domínio** correspondentes, numa
  fila de saída (outbox). Se a transação falha, nenhum evento existe.
- O evento de domínio é a versão **publicável** do que a auditoria registra:
  um fato de negócio ("mensagem pública criada", "ticket atualizado"), com a
  lista das mudanças de campo (antes/depois) tiradas dos eventos de auditoria
  da mesma transação.
- Os consumidores leem só essa fila: **webhooks** (spec 10), **tempo real**
  (spec 09), **automações** (spec 05) e **notificações** a agentes (spec 09).
  As métricas (spec 11) leem os eventos de auditoria, que são a mesma origem.
- O outbox de webhooks da spec 10 §13.1 é este mesmo fluxo, não um segundo.

### 4.2 Tipos de evento no MVP
Lista **interna** (todos os consumidores internos podem usá-la):
- ticket criado; ticket atualizado (estado, grupo, responsável, prioridade,
  tipo, etiquetas, participantes, seguidores, campos, local, dados do evento,
  inclusive a marca "pronto para o evento" (D44), pai do incidente no filho);
  ticket mesclado;
- incidente pai marcado ou desmarcado; filho vinculado ou desvinculado (spec
  13 Δ35);
- evento: aviso de montagem (spec 13 Δ34; instantes na spec 05 §7.14, D41;
  entrega na spec 09 §7.6);
- local criado ou atualizado, inclusive desativado e reativado (spec 13 Δ33);
- mensagem pública criada (inclusive mensagens de sistema públicas); nota
  interna criada (inclusive mensagens de sistema internas, que seguem a regra
  das notas, spec 06 §6.1, e mensagens de conversa paralela, enviadas ou
  recebidas, com a indicação "conversa paralela", spec 13 Δ17, D37);
- encaminhado com retorno, devolvido e retorno cancelado (spec 13 Δ5);
- menção em nota interna (spec 13 Δ7);
- convite de pesquisa enviado; avaliação registrada ou alterada (spec 13 Δ15);
- SLA: aviso e SLA: violação (spec 05 §7.10–§7.11);
- pessoa criada, atualizada ou mesclada (spec 13 Δ22); organização criada ou
  atualizada;
- artigo publicado, atualizado ou despublicado (spec 07);
- definição de campo alterada.

O **catálogo dos webhooks** é o da spec 10 §11.3, que é um subconjunto desta
lista mais o evento de teste. Um tipo interno só passa a sair por webhook
quando a spec 10 o acrescenta ao catálogo, como mudança aditiva (§7).

- Uma operação que faz várias coisas produz um evento por fato, todos com o
  mesmo **identificador de operação**. Exemplo: o agente responde e muda o
  estado para pendente no mesmo envio → "mensagem pública criada" e "ticket
  atualizado", nessa ordem (igual à spec 10 §11.3).
- Novos tipos de evento podem surgir dentro da mesma versão; consumidores
  ignoram tipos que não conhecem.

### 4.3 Conteúdo de um evento
Todo evento traz:
- identificador único e opaco; tipo; **versão do esquema do evento**;
- conta; momento (UTC); identificador de operação;
- **ator**, com os mesmos tipos das origens da spec 01 §7 (agente,
  solicitante, sistema, automação, API) e os identificadores que se aplicam:
  da pessoa, da regra (automação), do token e da identidade de integração
  (API). É o mesmo modelo do ator no envelope do webhook (spec 10 §12.1);
- entidade (tipo, identificador interno e, para ticket, número legível),
  **versão** do recurso depois da mudança (spec 01 §3, D01) e **número de
  sequência** interno da entidade (§4.4);
- lista de mudanças (campo, antes, depois; campos personalizados pela chave);
- estado da entidade **depois** da mudança;
- para mensagens: visibilidade, linha (conversa principal ou conversa
  paralela), tipo de autor (spec 11 §3), corpo sanitizado (spec 02 §8) e
  metadados dos anexos. O conteúdo do anexo nunca vai no evento; é baixado pela
  API, com verificação de permissão.
- Corpo acima de **256 KB** vai truncado e marcado como truncado, como no
  webhook (spec 10 §12.2); o completo fica na API.

### 4.4 Garantias
- **Entrega pelo menos uma vez** a cada consumidor durável (webhooks,
  automações). O consumidor descarta repetições pelo identificador do evento.
  As automações registram os eventos já tratados, e por isso o **efeito** de
  uma automação acontece uma única vez.
- **Ordem por entidade no fluxo interno**: o número de sequência de cada
  ticket cresce de 1 em 1, sem lacunas, porque as mudanças num mesmo ticket são
  serializadas. Ele existe porque a versão do ticket só muda com campo ou
  estado (D01), e mensagens também precisam de ordem. Entre entidades
  diferentes não há garantia de ordem.
- Na entrega dos **webhooks** a ordem não é garantida (spec 10 §13.2): o
  receptor usa a versão do recurso para descartar o que é mais velho.
- **Tempo real** (spec 09 §3.4): entrega pelo menos uma vez; o servidor guarda
  15 minutos de eventos para retomada. Uma tela que ficou desconectada por mais
  tempo recebe "recarregar" e busca o estado pela API.
- Meta de latência: 95% dos eventos disponíveis aos consumidores em até 5 s
  depois da gravação.

### 4.5 Visibilidade
- Um evento só chega a um consumidor que poderia ler aquele dado pela API.
- Consumidores que atuam para um **solicitante** (portal e widget de chat em
  tempo real) nunca recebem notas internas, mensagens de sistema internas,
  mensagens de conversa paralela, campos visíveis só a agentes, seguidores,
  menções nem o histórico de auditoria. O estado "em espera" chega a eles como
  "em andamento" (spec 13 Δ3).
- **Webhooks** (D03): o texto de uma nota interna só sai no tipo de evento
  **nota interna criada**, sempre marcado como interno. Os eventos de ticket e
  de mensagem pública nunca trazem conteúdo de nota. Quem não quer notas não
  assina esse tipo; não existe escopo, "público" nem "audiência" separado
  para isso (D31). Mensagens de conversa paralela são conteúdo interno pela
  mesma regra: saem em "nota interna criada", com a indicação "conversa
  paralela", e nunca em "mensagem pública criada" (D37).
- **Identidades de integração** leem pela API o que um agente com o mesmo
  acesso ao grupo leria (D04): com leitura ou escrita no grupo, veem as notas
  internas, marcadas como internas.

### 4.6 Laços e eco
- Eventos gerados por automação levam a regra de origem. Automações **não**
  disparam outras automações: não há encadeamento nem contador (spec 05 §3.5).
- **Eco de integração**: para evitar o laço "integração escreve → webhook
  avisa a integração → integração escreve de novo", a assinatura de webhook
  tem a opção "ignorar eventos causados por um token X" (spec 10 §11.1),
  desligada por padrão. Como as assinaturas são do admin (D03), é o admin quem
  liga a opção para os tokens da identidade de integração em questão.
- Automações podem usar o ator e a origem como condição (por exemplo, "não
  executar se o ator é a identidade de integração X").

### 4.7 Feed de eventos (MVP, D52)
- A API tem, **no MVP**, o **feed de eventos** da spec 10 §4: lista lida com
  cursor dos eventos de domínio dos últimos **30 dias**, no mesmo envelope dos
  webhooks (spec 10 §12.1), filtrada pelas permissões de quem lê (§4.5). Ele
  usa o mesmo fluxo da §4.1, sem mudar o formato dos eventos.
- Quem perdeu eventos recupera, nesta ordem: pelo feed, dentro dos 30 dias;
  pelas retentativas da spec 10 §13.4 e pelo reenvio do log de entregas,
  dentro dos 14 dias de retenção (spec 10 §13.6); depois disso, pelo recurso
  "mudanças desde" (spec 10 §5.3), que devolve o estado atual; e pelos
  eventos de auditoria por ticket (spec 10 §4), que são permanentes.

---

## 5. Identidades de integração

Uma **identidade de integração** representa um sistema externo, não uma
pessoa (spec 01 §2, D04).

| Regra | Comportamento |
|---|---|
| Criação | Só admin. Nome, descrição, admin responsável, estado (ativa/desativada). |
| Natureza | Ator não humano. Não é Pessoa nem Agente: não entra na interface, não tem senha, não ocupa vaga de agente, não pode ser **Responsável** de ticket, seguidor nem mencionado, e não entra no rodízio. |
| Acesso | O **mesmo modelo de acesso por grupo** dos agentes (spec 06 §3): nenhum, leitura ou escrita, grupo a grupo. Ticket de grupo com acesso nenhum não existe para ela (404, D05). |
| Escopos | Os **mesmos três escopos** de token (spec 06 §7, spec 10 §3.3): leitura, escrita e administração. Permissão efetiva = acesso atual da identidade ∩ escopos do token, a cada requisição. O escopo administração só pode ser concedido a um token de identidade que o admin **criou marcada como administrativa** (D36; spec 10 §3.5); para as demais, é recusado na criação do token. A marca é escolhida na criação da identidade, e a tela avisa que ela dá acesso a configurações. |
| Restrições fixas no MVP | Não mescla tickets nem pessoas (como as automações, spec 01 §4.2), não reabre ticket fechado (ação de admin humano), não cria, lista nem revoga tokens (spec 06 §7), não age **em nome** de um agente. |
| Tokens | Até 2 tokens ativos por identidade, para troca sem interrupção. Valor mostrado **uma única vez**, guardado só como hash, com prefixo curto e não secreto para identificação (spec 10 §3.2). Validade obrigatória para identidades: padrão 365 dias, máximo 2 anos; o admin responsável é avisado 14 dias antes do vencimento. |
| Revogação | **Imediata**: a próxima requisição com o token recebe 401 (spec 10 §3.2). Desativar a identidade deixa todos os tokens dela **suspensos** (401); ao reativá-la, voltam os que não expiraram nem foram revogados (como D26 para agentes). |
| Último uso | Registrado por token e visível ao admin. |
| Auditoria | Toda ação gera eventos com origem API, com o identificador do token e da identidade (spec 01 §7). Na tela, o autor aparece com o nome da integração. |
| Mensagens | Tipo de autor identidade de integração (spec 11 §3). Para os agentes, aparece com o nome da integração e uma marca de integração. Para o solicitante, o e-mail sai com o nome de exibição "{nome da integração} via {nome da conta}" (spec 02 §9). **Não** é resposta humana: não desliga o indicador "sem primeira resposta" e não conta como 1ª resposta (spec 11 §6.1). |
| Exclusão | Identidade com eventos no histórico não pode ser excluída, só desativada; o histórico continua mostrando o nome dela. |
| Limites | Limite de requisições por identidade (spec 10 §9). |

Tokens pessoais de agente (spec 10 §3.2) continuam existindo para uso pessoal
(um script do próprio agente). O que é feito com eles tem o agente como autor.
Integrações de sistemas devem usar identidades de integração.

---

## 6. Adaptadores substituíveis

### 6.1 Regras comuns
- Cinco peças ficam atrás de um **contrato de comportamento**: armazenamento de
  anexos, transporte de saída de e-mail, fonte de entrada de e-mail, provedor
  de autenticação e provedor de IA.
- No MVP, as implementações **vêm com o produto** e são escolhidas por
  configuração (da instalação ou do admin, conforme a peça). Terceiros não
  instalam implementações novas no MVP.
- Cada contrato tem uma **suíte de testes de aceite** própria. Toda
  implementação, atual ou futura, precisa passar na mesma suíte.
- Segredos de configuração (senhas, chaves) são guardados cifrados, só podem ser
  escritos (a API nunca os devolve) e nunca aparecem em logs nem em mensagens
  de erro.
- Cada adaptador expõe um **estado de saúde** ao admin: último sucesso, último
  erro e quantas falhas seguidas.

### 6.2 Armazenamento de anexos
Escolhido por instalação. Implementação no MVP: **disco local**. O
armazenamento de objetos compatível com o padrão de mercado fica no roadmap,
com este mesmo contrato.

| Aspecto | Contrato |
|---|---|
| Gravar | Recebe o conteúdo e o hash; devolve uma referência opaca. Só confirma depois que o conteúdo está **durável**. Gravar duas vezes o mesmo conteúdo é idempotente (permite o compartilhamento por hash da spec 02 §8). |
| Ler | Pela referência, em fluxo contínuo; ler logo depois de gravar sempre encontra o conteúdo. Arquivos até o limite da conta (spec 02 §2.4 e spec 13 Δ19) passam em fluxo, sem carregar o arquivo inteiro na memória. |
| Remover | Só pela rotina de retenção do PantherDesk, nunca durante uma operação de usuário. |
| Acesso | O adaptador **nunca** gera link público permanente. O download passa pela verificação de permissão do PantherDesk; quando o adaptador suporta, o PantherDesk gera um link assinado válido por no máximo 5 minutos, depois de verificar a permissão. |
| Falha | Falha ao gravar faz falhar a operação inteira. Na ingestão de e-mail, a mensagem continua na caixa e é reprocessada (spec 02 §2.2). |
| Uso | Guarda também o bruto dos e-mails recebidos (spec 02 §2.2), os anexos do widget de chat (spec 13 Δ16) e o logo da conta (spec 13 Δ25). |
| Troca (roadmap, junto com o armazenamento de objetos) | Migração em segundo plano: copia, confere o hash, troca a referência. Durante a migração, a leitura procura no destino e, se não encontrar, na origem. A troca não gera eventos nos tickets. |

### 6.3 Transporte de saída de e-mail
Escolhido por caixa de e-mail. Implementação no MVP: **SMTP**. A API HTTP de
um provedor de envio fica no roadmap, com este mesmo contrato.

| Aspecto | Contrato |
|---|---|
| Entrada | Mensagem **completa**, montada pelo núcleo conforme a spec 02 §9 (cabeçalhos, Message-ID, assunto, corpo), inclusive as mensagens de conversa paralela, com identificadores próprios (spec 13 Δ17). |
| Fidelidade | O adaptador **não** altera Message-ID, In-Reply-To, References, assunto nem os cabeçalhos anti-laço. Se o provedor reescrever o Message-ID, o adaptador informa o identificador novo e o núcleo o grava também, para que as respostas continuem se encadeando. |
| Resultado | Uma única tentativa, com resultado classificado: **aceita** (com o identificador do provedor), **falha temporária** ou **falha permanente**. |
| Novas tentativas | São do núcleo, com o calendário da spec 02 §9. O adaptador não tenta de novo por conta própria. |
| Duplicidade | O núcleo passa uma chave de entrega. Se o provedor aceita chave de idempotência, o adaptador a usa. SMTP não aceita: uma queda entre o aceite e o registro pode gerar um envio duplicado. No MVP esse risco é **aceito e documentado**; o destinatário recebe duas cópias com o mesmo Message-ID, e o threading não se perde. |
| Bounces | Chegam pela fonte de entrada (spec 02 §7). Receber bounces pelo provedor fica para o roadmap. |

### 6.4 Fonte de entrada de e-mail
Escolhida por caixa de e-mail. Implementações no MVP: IMAP e entrega direta por
HTTP (spec 02 §2.1).

| Aspecto | Contrato |
|---|---|
| Entrega | Entrega os **bytes originais** da mensagem, sem alteração. |
| Confirmação | Confirma o consumo (mover para a pasta de processadas, ou responder com sucesso à entrega direta) **só depois** que o núcleo gravou tudo. |
| Garantia | Pelo menos uma vez. A deduplicação é do núcleo (spec 02 §2.3). |
| Falha | Erro de conexão não perde nem duplica mensagens. Depois de 15 minutos de falhas seguidas, o admin é avisado. |

### 6.5 Provedor de autenticação
Escolhido por conta, separadamente para a **área do agente** e para o
**portal**. No MVP há duas implementações (spec 13 Δ31):

| Implementação | Quem usa | Observação |
|---|---|---|
| **Google** (primeiro provedor externo implementado) | agentes e admins (**único** método da área do agente); solicitantes do domínio da conta (funcionários e professores), no portal | a conta configura o **domínio** aceito (para a EARJ, o domínio da escola); sem senha local para agentes |
| **Link de acesso por e-mail** (provedor local, segundo método) | solicitantes sem conta do domínio (pais, visitantes), no portal | regras da spec 07; aparece como opção secundária na tela de entrada; a senha opcional do solicitante segue a spec 07 |

Outros provedores externos por padrões de mercado (OIDC genérico, SAML, LDAP)
continuam no roadmap, por este mesmo contrato. **Agentes e admins entram só
com Google** (D53): fora do modo de desenvolvimento não existe login local
para eles (nem senha, nem link por e-mail), e uma instalação sem Google
configurado para a área do agente **não é suportada no MVP**. O provedor
local (link de acesso por e-mail) serve só ao portal do solicitante.

Regras do Google no MVP:
- **Domínio**: a área do agente e a entrada "conta da escola" no portal
  aceitam só identidades que o **provedor confirma** como do domínio
  configurado. O sufixo do e-mail sozinho não basta. Identidade de outro
  domínio: na área do agente, recusada; no portal, recusada com a indicação
  do link por e-mail.
- **Primeiro acesso**: o e-mail confirmado pelo Google identifica a Pessoa
  (vínculo pelo par provedor + identificador externo, abaixo). Se não existe
  Pessoa com esse endereço, cria-se um **solicitante**; um agente nunca é
  criado no primeiro acesso: papel e grupos são definidos pelo admin no
  PantherDesk (Δ31). No primeiro login o endereço passa a **verificado**
  (amplia D38).
- **Agente cadastrado**: entra pelo Google se a Pessoa dele tem o endereço do
  domínio. Um agente **não** entra pelo link por e-mail quando a conta usa o
  Google na área do agente.
- **Retorno à página de origem**: o endereço de entrada, com os parâmetros
  (por exemplo, o código da sala do QR, Δ33), é guardado antes do
  redirecionamento e devolvido depois da entrada, exatamente como estava. O
  retorno só aceita endereços do **domínio da conta** (Δ32); qualquer outro é
  ignorado e a pessoa vai para a página inicial do portal ou da área do
  agente.
- **Dados guardados**: só o identificador externo, o e-mail confirmado, o
  nome e o domínio. O PantherDesk não guarda credenciais de acesso do Google
  depois da entrada e não pede permissões além de identidade e e-mail.
- **Falha do provedor**: as sessões já abertas continuam valendo; novas
  entradas pelo Google falham com mensagem clara; o estado de saúde (§6.1)
  registra a falha. Não há caminho alternativo para agentes, nem acesso de
  emergência por link ou senha (D53): o risco é aceito no MVP.
- **Provedor de teste**: só no **modo de desenvolvimento** e em ambiente de
  teste (nunca em produção; D53), um provedor de teste do próprio PantherDesk faz o papel do
  Google, para que os dados fictícios de demonstração (spec 13 §4) e os
  critérios de aceite funcionem sem contas reais. Ele passa na mesma suíte
  do contrato.

| Aspecto | Contrato |
|---|---|
| Resultado | Dada uma credencial ou uma asserção externa, devolve uma **identidade verificada** (provedor, identificador externo estável, e-mail, se o e-mail foi verificado pelo provedor, domínio confirmado pelo provedor quando houver, nome) ou uma falha. |
| Vínculo com Pessoa | Pelo par (provedor, identificador externo). No primeiro acesso, vincula a uma Pessoa existente só se o e-mail foi **verificado** pelo provedor e coincide com um Endereço dessa pessoa. Caso contrário, recusa (agente) ou cria um solicitante novo (portal, se a conta permitir). |
| Autorização | Papéis, grupos e acesso ficam **sempre** no PantherDesk. O provedor só diz quem é a pessoa. Agentes não são criados automaticamente no primeiro acesso. |
| Bloqueio | Pessoa desativada no PantherDesk, ou solicitante suspenso (spec 13 Δ28), não entra, mesmo que o provedor aceite. |
| Sessão | Emitida pelo PantherDesk, com as regras da spec 06 (agentes) e da spec 07 §7.1 (solicitantes). É a mesma sessão qualquer que seja o provedor; o canal de eventos e a API com sessão não distinguem um do outro. |
| Auditoria | Cada entrada registra pessoa, provedor e momento; o primeiro vínculo de uma identidade externa a uma Pessoa e as recusas (domínio errado, e-mail não verificado, pessoa desativada) também, sem guardar credenciais. |
| Integrações e API | Identidades de integração nunca autenticam por este adaptador, só por token (§5). A API pública não aceita credenciais do provedor externo: quem usa a API usa token (spec 10 §3.1). |

### 6.6 Provedor de IA
No MVP conforme as decisões da spec 13 §6: resumo do ticket e melhoria de texto
do rascunho. A sugestão de responsável fica no roadmap. Escolhido por conta;
o admin configura o provedor e a chave.

| Aspecto | Contrato |
|---|---|
| Desligado | Sem chave configurada, o adaptador não existe para o resto do produto: nenhum botão aparece e nenhuma chamada sai. |
| Entrada | Um pedido de um tipo fechado (resumir, melhorar texto com um tom da lista fechada) e o conteúdo montado pelo núcleo: para o resumo, as mensagens públicas e as notas internas que **o agente que pediu** pode ver; para melhorar texto, só o rascunho dele. Anexos e mensagens de conversa paralela não são enviados no MVP. |
| Quando | Só no momento do pedido do agente. Nada é enviado em segundo plano. |
| Resultado | Texto sugerido ou falha. Tempo máximo de **20 s**; acima disso, falha. A falha mostra um erro e não bloqueia o ticket. |
| Efeito | O adaptador nunca grava nada no ticket. O resumo só aparece para agentes; a sugestão de texto só substitui o rascunho se o agente aceitar. **Nada é enviado ao solicitante sem revisão.** |
| Auditoria | Cada uso gera evento de auditoria (quem, quando, qual ticket, tipo de pedido), sem guardar o conteúdo enviado nem o recebido. |

---

## 7. API pública estável

- **Paridade**: toda ação disponível ao agente na interface está disponível na
  API, com as mesmas validações, as mesmas permissões e os mesmos eventos. A
  interface do agente usa a própria API pública. A lista de recursos e
  operações é da spec 10 §4; as ações novas da spec 13 (encaminhar com retorno
  e devolver, seguir, conversa paralela, edição em massa, filas salvas,
  avaliação, mesclar pessoas, prévia e aplicação de macro, rascunhos de
  artigo e "meu problema foi resolvido") seguem este princípio (D29, D32),
  assim como as das decisões de 2026-10-29: cadastro de locais e QR,
  eventos e calendário, incidente pai, macros com variantes e "criar
  artigo" (spec 13 Δ33–Δ38). A exceção é a **entrada** na interface: o
  login com Google e o link por e-mail criam sessão, não tokens, e a API
  continua só por token (spec 10 §3.1).
- **Versão explícita** em toda chamada. Dentro de uma versão, só entram mudanças
  **aditivas**: campos novos na resposta, parâmetros opcionais novos, tipos de
  evento novos. Clientes devem ignorar campos que não conhecem.
- **Valores novos em enumerações** (um estado novo, um tipo de autor novo)
  podem quebrar clientes. Por isso são anunciados com 90 dias de antecedência no
  registro público de mudanças, mesmo dentro da mesma versão. Os valores
  trazidos pela spec 13 (estado em espera, canal chat, tipo do ticket) entram
  **já na versão 1** e não dependem desse aviso.
- **Mudança incompatível** (remover ou renomear campo, mudar significado) só em
  versão nova. A versão anterior continua funcionando por **pelo menos 12
  meses** depois do lançamento da nova. As respostas da versão em
  descontinuação informam a data de desligamento.
- Campos personalizados aparecem pela **chave** (§3).
- Os eventos de domínio têm versão de esquema própria, com a mesma política.
- Idempotência na criação, paginação, formato de erro e ordem 404 × 403: spec
  10 e D05.

---

## 8. O que NÃO é permitido no MVP

| Proibido | Motivo (riscos observados) |
|---|---|
| **Código arbitrário no servidor**: scripts de usuário, linguagens de expressão que executam código, ação "executar código" em automações, modelos com lógica além da troca de marcadores de uma lista fechada (spec 05, spec 13 Δ10) | O único projeto analisado que oferece scripts de servidor os roda num ambiente restrito e, mesmo assim, passou a mantê-los **desligados por padrão** e os proíbe em hospedagem compartilhada. Se nem com ambiente restrito o risco foi aceito por padrão, um produto novo não deve começar por aí. |
| **Plugins no mesmo processo**: carregar pacotes, módulos ou ganchos que executam código ou transformam valores dentro do servidor | Em três projetos, extensões rodam no mesmo processo e no mesmo banco, sem isolamento: um módulo defeituoso derruba o sistema ou lê qualquer dado, e as personalizações se perdem nas atualizações. Ganchos sem contrato quebram a cada versão. |
| **Mudar o esquema do banco em tempo de execução**, ou exigir reinício para configurar | Um projeto exige aplicar uma atualização do banco e **reiniciar** o serviço para criar um campo. Outro instala extensões com migração de banco, e um terceiro **apaga tabelas** ao desinstalar um pacote. |
| **JavaScript, HTML ou CSS personalizado** injetado na área do agente, no portal ou no widget | Um projeto exige que módulos contornem a política de segurança de conteúdo do núcleo. Código injetado na interface tem acesso à sessão do agente. A marca da conta (spec 13 Δ25) é **configuração**: logo, nome e duas cores, com contraste verificado. O widget de chat (spec 13 Δ16) é código do próprio PantherDesk que a conta embute no **site dela**; o caminho inverso não existe. |
| **Acesso direto ao banco** por integrações | Contorna permissões, auditoria e a política de versões da API. |
| **Webhooks síncronos** que bloqueiam ou vetam uma operação | Um sistema externo lento ou fora do ar travaria o atendimento. Webhooks são avisos depois da gravação (spec 10). |
| **Integração agindo em nome de um agente** | Mistura autoria humana e de máquina na auditoria e nas métricas (spec 11 §6.1). |
| **Instalação ou ativação que dependa de internet ou de licença** | Um projeto baixa extensões pela própria instância e amarra a licença ao domínio, o que não funciona em instalações isoladas. O provedor de IA (§6.6) é opcional: sem ele o produto funciona igual. |

---

## 9. Roadmap: sistema de apps

Fora do MVP. Esta seção fixa o comportamento esperado para que as decisões do
MVP não o impeçam.

### 9.1 Manifesto
Todo app declara, num manifesto:
- identidade (identificador único, nome, editor, versão semântica) e endereço de
  contato do editor;
- **compatibilidade**: faixa de versões da API PantherDesk que usa;
- **permissões**: os mesmos escopos e o mesmo acesso por grupo das identidades
  de integração (§5), além dos pontos de extensão de interface que usa;
- eventos que assina;
- configurações do app (esquema declarativo, com campos marcados como segredo);
- endereços externos que os iframes do app carregam;
- dados que o app guarda no PantherDesk e o que acontece com eles na remoção.

### 9.2 Ciclo de vida
| Etapa | Comportamento |
|---|---|
| Instalar | O admin vê **todas** as permissões declaradas e aprova ou recusa. Se recusar, nada é criado. Se aprovar, o PantherDesk cria uma identidade de integração do app com exatamente esse acesso e esses escopos e entrega o token ao app por um aviso de instalação assinado, enviado por HTTPS ao endereço do app. Nenhum código é enviado ao PantherDesk. |
| Desativar | Tokens suspensos, assinaturas de eventos paradas (os eventos não ficam acumulados), painéis escondidos. **Dados preservados.** |
| Reativar | Tokens e painéis voltam. O app recupera o período desativado pelo feed de eventos (§4.7, no MVP desde a D52), dentro dos 30 dias, ou, além disso, por "mudanças desde" (spec 10 §5.3). |
| Atualizar | Versão nova **com as mesmas permissões ou menos**: aplicada automaticamente, se o admin escolheu isso, ou com um clique. Versão nova **com permissões a mais**: exige aprovação. Até lá, a versão anterior continua funcionando com as permissões antigas. Voltar à versão anterior é permitido se ela ainda for compatível. |
| Remover | O admin vê o que será apagado antes de confirmar. Tokens revogados, assinaturas e painéis removidos na hora. Configurações e dados guardados pelo app no PantherDesk são apagados depois de **30 dias**; reinstalar dentro desse prazo os recupera. O que o app escreveu nos tickets (mensagens, notas, valores de campo, etiquetas) **permanece**: são dados do ticket e fazem parte da auditoria. |

### 9.3 Isolamento
- Apps **nunca** rodam no processo do PantherDesk. Rodam no servidor do editor
  ou, em instalações próprias, num serviço separado, e falam com o PantherDesk
  só pela API pública e pelos eventos.
- A interface de um app roda em **iframe** de origem diferente da do
  PantherDesk, com permissões mínimas do navegador (sem acesso à página do
  agente, sem abrir janelas sem gesto do usuário) e política de conteúdo que só
  permite os endereços declarados no manifesto.
- Limites do lado do PantherDesk: limite de requisições por app e tempo máximo
  de resposta nos avisos enviados ao app.

### 9.4 Pontos de extensão de interface
- Primeiro ponto: **painel lateral do ticket** (iframe), na tela do agente, ao
  lado do painel de contexto da spec 13 Δ18. Depois: página própria do app no
  menu e botão de ação no ticket, que abre uma janela com iframe. O portal do
  cliente e o widget de chat não recebem extensões de interface na primeira
  versão.
- **Contexto assinado**: ao abrir o painel, o PantherDesk entrega ao iframe um
  contexto assinado com o segredo da instalação, válido por **5 minutos**: conta,
  instalação, agente, ticket, idioma, fuso e validade. O app verifica a
  assinatura no próprio servidor. O contexto **não** traz conteúdo do ticket.
- **Token delegado**: junto com o contexto vai um token curto (15 minutos,
  renovável pelo iframe) cujas permissões são a **interseção** entre as
  permissões do app e as do agente que está vendo. Assim o painel nunca mostra
  ao agente algo que ele não poderia ver, mesmo que o app tenha acesso mais
  amplo.
- A conversa entre o iframe e a página usa mensagens entre janelas do navegador,
  com verificação de origem nos dois lados, e aceita só um conjunto pequeno de
  pedidos: renovar o contexto, ajustar a altura, abrir um ticket, **inserir um
  rascunho** no editor de resposta. Nenhum pedido envia mensagem: o agente
  sempre revisa e envia.

### 9.5 Versões e compatibilidade
- O manifesto declara a versão mínima da API. Quando uma versão da API é
  desligada (§7), os apps que dependem dela são marcados como incompatíveis. Os
  admins são avisados 90 dias antes, e os apps são desativados (não removidos)
  na data.
- O PantherDesk nunca atualiza um app para uma versão que pede mais permissões
  sem aprovação.

### 9.6 Distribuição
- Instalação a partir do endereço do manifesto ou de arquivo de manifesto
  enviado pelo admin. Instalações sem internet funcionam com apps hospedados na
  mesma rede.
- Manifestos assinados pelo editor, com verificação no PantherDesk, entram
  junto com o catálogo.
- O núcleo não faz controle de licença dos apps.

### 9.7 Script no servidor (longo prazo, sem compromisso)
Só será considerado com ambiente de execução isolado **fora do processo**, sem
rede por padrão, com limites de CPU, memória e tempo, **desligado por padrão**
e sujeito a uma spec própria.

---

## 10. Abordagens comparadas

### 10.1 Por projeto (segundo a documentação pública)

| Projeto | Abordagem | Prós | Contras |
|---|---|---|---|
| Zammad | Campos em ticket, usuário, organização e grupo; regras declarativas de formulário; gatilhos com webhooks; integrações nativas ligadas pelo admin; área de pacotes pouco documentada. | Muito resolvido por configuração; campos em várias entidades. | Criar campo exige atualizar o banco e **reiniciar**; a própria documentação alerta para comportamento inesperado das regras de formulário; ciclo de vida dos pacotes não documentado. |
| Chatwoot | Atributos personalizados em contato e conversa; **apps de painel por iframe** que recebem o contexto da conversa por mensagens entre janelas; bots externos que recebem eventos e respondem pela API; sem plugins de servidor. | Isolamento forte por construção; nenhum código de terceiro no servidor. | Personalizar o servidor exige fork; o contexto do iframe não é assinado (na documentação lida). |
| FreeScout | Núcleo mínimo; quase tudo em **módulos** no mesmo processo, ligados a ganchos que executam código ou transformam valores; módulos oficiais baixados pela instância, com licença por domínio. | Núcleo pequeno; catálogo amplo. | Sem isolamento; recursos básicos (campos, API) são módulos pagos; instalação exige internet; efeito da remoção sobre os dados não documentado. |
| osTicket | Formulários e campos configuráveis com obrigatoriedade para fechar; plugins copiados para uma pasta do servidor e configurados no painel (armazenamento de anexos, autenticação, auditoria). | Pontos de extensão claros para armazenamento e autenticação. | Código no mesmo processo; ciclo de vida (desativar, remover) não documentado; API muito limitada. |
| Znuny | Campos dinâmicos (inclusive alimentados por serviço externo); gerenciador de pacotes com repositório, envio de arquivo e linha de comando; verificação de integridade por arquivo; integrações por configuração. | Ciclo de vida explícito; reinstalar preserva dados; integridade verificável. | Pacotes alteram arquivos e esquema da aplicação; **desinstalar apaga as tabelas** do pacote; sem isolamento. |
| UVdesk | Aplicação montada de pacotes, com framework de extensões; campos personalizados e várias integrações são apps pagos que exigem comandos e migração de banco. | Arquitetura modular. | Campos fora do núcleo; instalação manual com migração; sem isolamento; remoção não documentada. |
| Frappe Helpdesk | App sobre um framework: campos personalizados pela interface, ganchos de ciclo de vida e de documentos, scripts de cliente e **scripts de servidor em ambiente restrito, desligados por padrão**. | Extremamente flexível; migrações com correções de dados ordenadas. | Apps rodam no mesmo processo; scripts de servidor considerados arriscados pelo próprio projeto; validações de script de cliente não valem para a API. |

### 10.2 Escolhas do PantherDesk

| Tema | Abordagens observadas | Escolha e motivo |
|---|---|---|
| Campos personalizados | no núcleo com reinício / no núcleo sem reinício / módulo pago | no núcleo, em ticket, pessoa e organização, sem mudança de esquema nem reinício, com chave estável (spec 01 §5) |
| Regras de formulário | regras declarativas com efeitos inesperados (1) / scripts de cliente que não valem na API (1) | condições de exibição declarativas, validadas no servidor para todas as origens, sem ciclos (spec 13 Δ2) |
| Fonte de eventos | gatilhos e webhooks separados / eventos do framework | um fluxo único com fila de saída transacional para todos os consumidores |
| Quem é a integração | token de usuário (maioria) / bot registrado (1) | identidade de integração com o mesmo acesso por grupo e os mesmos escopos dos agentes, e autoria própria na auditoria |
| Infraestrutura substituível | plugins de armazenamento e autenticação (1) / módulos (1) | adaptadores com contrato e suíte de testes; uma implementação embutida por peça no MVP (duas na entrada de e-mail e duas na autenticação: Google e link por e-mail) |
| Extensão de interface | iframe com contexto (1) / código no mesmo app (vários) | iframe com contexto **assinado** e token delegado (roadmap) |
| Código de terceiros | mesmo processo (5) / ambiente restrito desligado (1) / só externo (1) | só externo: API, eventos e iframe |
| Ciclo de vida | remoção apaga tabelas (1) / não documentado (vários) | desativar preserva; remover avisa o que apaga e tem 30 dias de carência |
| Distribuição | download pela instância com licença (1) / repositório (1) / cópia de pasta (2) | endereço ou arquivo de manifesto; sem dependência de internet nem licença |

---

## 11. Casos de teste (critérios de aceite)

Atores: `ag1` e `ag2` (grupo N1, escrita), `ag3` (grupo Financeiro, escrita),
`admin`, solicitantes `ana` e `bia` (org. Acme), `cris` (sem org.). Identidade
de integração `crm`: **escrita** em N1, **nenhum** acesso aos outros grupos;
token com escopo **escrita**, salvo indicação. Tickets: **#1200** (N1,
solicitante ana, aberto) e **#1201** (Financeiro, solicitante cris).

### 11.1 Campos personalizados
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| EX-01 | — | admin cria o campo lista "Produto" no ticket, com chave `produto` | disponível na interface, na API, nas automações e nos eventos sem reinício; tickets existentes com valor vazio; evento "definição de campo alterada" emitido |
| EX-02 | EX-01 | admin muda o rótulo para "Produto contratado" | API, eventos e condições de automação continuam usando `produto`; a tentativa de mudar a chave é recusada |
| EX-03 | EX-01 | `crm` grava em `produto` uma opção inexistente | recusado com o mesmo erro da interface; nenhum evento |
| EX-04 | campo `produto` desativado, ticket com valor `vpn` | ler o ticket pela API e tentar gravar `produto` | o valor aparece marcado como inativo; a gravação é recusada |
| EX-05 | — | admin cria o campo texto "Gestor" na **pessoa**, chave `gestor`; `crm` grava `gestor` em ana | sem reinício; a leitura de ana pela API traz `gestor`; evento "pessoa atualizada" com a mudança pela chave |
| EX-06 | campos `motivo` e `equipamento` (visível só com `motivo` = hardware) | `crm` cria um ticket com `motivo` = rede e `equipamento` preenchido | erro de validação no campo `equipamento`; nada gravado; nenhum evento (revisto em v0.3, D51) |
| EX-07 | #1200 com `motivo` = hardware, `equipamento` = "impressora" e `sintoma` = "não imprime" (visível só com `equipamento` = impressora) | ag1 muda `motivo` para rede | um único "ticket atualizado" com três mudanças (`motivo` e a limpeza de `equipamento` e de `sintoma`), mesmo identificador de operação, origem agente (revisto em v0.3, D51) |

### 11.2 Eventos de domínio
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| EX-10 | webhook assinando "ticket atualizado"; ag2 com a lista aberta | ag1 muda #1200 de aberto para pendente | um único evento, com um identificador; o webhook, a tela de ag2 e as automações recebem o mesmo identificador; mudança antes=aberto, depois=pendente |
| EX-11 | — | ag1 envia resposta pública e muda #1200 para pendente no mesmo envio | dois eventos ("mensagem pública criada" e depois "ticket atualizado") com o mesmo identificador de operação e sequências consecutivas |
| EX-12 | — | uma mudança falha na validação (spec 01 TL-11) | nenhum evento; nada chega ao webhook nem ao tempo real |
| EX-13 | #1200 com sequência 7 | três mudanças seguidas | sequências 8, 9 e 10; uma reentrega do webhook traz o mesmo identificador do evento original |
| EX-14 | ana com o portal aberto em #1200; webhook W1 assinando "mensagem pública criada" e "ticket atualizado"; webhook W2 assinando também "nota interna criada" | ag1 escreve nota interna em #1200 | o portal de ana não recebe nada; W1 não recebe nada; W2 recebe "nota interna criada", marcada como interna |
| EX-15 | webhook W3 com a opção "ignorar eventos causados pelo token de `crm`" ligada | `crm` grava uma nota; depois ag1 grava uma nota | W3 não recebe o evento da nota de `crm`; recebe o da nota de ag1 |
| EX-16 | o receptor do webhook ficou fora do ar por 2 h | o receptor volta | as entregas pendentes chegam pelas retentativas da spec 10 §13.4, com o identificador original; o receptor descarta as mais velhas pela versão do recurso; nenhuma entrega se perde |
| EX-17 | removido em v0.2 — o feed de eventos da API tinha passado para o roadmap; em v0.3 ele volta ao MVP (D52) e é coberto por EX-77 | — | — |
| EX-18 | ana com o portal aberto em #1200; W1 de EX-14 | ag1 abre conversa paralela com um fornecedor em #1200 e o fornecedor responde | ana não recebe nada; W1 não recebe as mensagens da conversa paralela; W2 de EX-14 as recebe em "nota interna criada", marcadas como internas e com a indicação "conversa paralela" (D37); a tela de ag2 recebe os eventos |
| EX-63 | webhook W4 assinando só "mensagem pública criada" e "ticket atualizado"; o admin procura na assinatura uma opção de "audiência" ou de público | ag1 abre conversa paralela em #1200 e o fornecedor responde | a opção não existe (D31); W4 não recebe nada sobre a conversa paralela (D37) |
| EX-19 | `crm` com **leitura** em N1 | `crm` lê as mensagens de #1200, que tem uma nota interna | a nota aparece, marcada como interna (mesmo acesso de um agente de apoio) |
| EX-76 | #1200 marcado como incidente pai; #1202 (N1, aberto) | ag1 vincula #1202 a #1200 | eventos internos "filho vinculado" e "ticket atualizado" de #1202 (mudança do pai), com o mesmo identificador de operação; a versão de #1200 não muda; o webhook só recebe o "ticket atualizado" (spec 10 §11.3) |
| EX-77 | ag1 muda #1200 e ag3 muda #1201; um evento de #1200 tem 31 dias | `crm` lê o feed de eventos pela API, com cursor, desde 40 dias atrás | recebe as mudanças de #1200 no envelope dos webhooks, com os mesmos identificadores de evento; nada de #1201 (sem acesso ao Financeiro); o evento de 31 dias não aparece (D52) |

### 11.3 Identidades de integração
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| EX-20 | — | admin cria `crm` e um token | o token aparece uma única vez; tentativa de entrar na interface como `crm` é recusada; `crm` não aparece na lista de possíveis responsáveis |
| EX-21 | — | `crm` grava nota interna em #1200 (N1) | nota gravada; evento com origem API, o identificador do token e o da identidade; na tela, autor "crm" |
| EX-22 | token de `crm` só com escopo **leitura** | `crm` tenta gravar nota em #1200 | 403 (ticket visível, ação proibida pelo escopo, D05); nada gravado |
| EX-23 | #1201 no Financeiro | `crm` tenta ler #1201 | 404, sem indicar que o ticket existe |
| EX-24 | #1200 aberto sem primeira resposta | `crm` envia resposta pública | o e-mail a ana sai com o nome "crm via {nome da conta}" (spec 02 §9); o indicador "sem primeira resposta" continua ligado; a spec 11 não a conta como 1ª resposta |
| EX-25 | token de `crm` em uso | admin revoga o token | a próxima chamada com ele recebe 401 |
| EX-26 | `crm` com eventos no histórico | admin tenta excluir `crm` | recusado; só desativar; o histórico continua mostrando "crm" |
| EX-27 | `crm` com escrita em N1 | `crm` tenta mesclar dois tickets de N1 | recusado (integrações não mesclam no MVP) |
| EX-28 | — | `crm` tenta criar um token novo usando o próprio token | recusado (token não cria tokens, spec 06 §7) |
| EX-29 | — | ag1 escreve em #1200 a nota "@crm confere?" | a menção não é convertida (`crm` não é agente); aviso ao autor; ninguém é notificado |
| EX-64 | `crm` criada **sem** a marca administrativa; `erp` criada pelo admin marcada como administrativa | admin cria para cada uma um token com escopo administração; o token de `erp` cria um campo personalizado | `crm` → recusado, nenhum token criado; `erp` → token criado; o campo é criado (D36) |
| EX-65 | token de `crm` válido | admin desativa `crm`; depois a reativa | desativada: chamadas com o token → 401; reativada: o mesmo token volta a funcionar, sem token novo |

### 11.4 Adaptadores
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| EX-30 | armazenamento fora do ar | chega o e-mail fx02 (com anexos, spec 02) | a ingestão falha inteira: nenhum ticket ou mensagem parcial; a mensagem continua na caixa e é processada uma única vez quando o armazenamento volta |
| EX-31 | anexo de uma nota interna | ana tenta baixá-lo pela API ou pelo portal | recusado |
| EX-32 | ag1 obtém o link assinado de um anexo | o link é usado 6 minutos depois | recusado (expirado) |
| EX-33 | roadmap (critério para quando o armazenamento de objetos existir): 1.000 anexos em disco local | admin troca para armazenamento de objetos e roda a migração | todos os anexos legíveis durante e depois da migração, com hashes conferidos; nenhum evento nos tickets |
| EX-34 | transporte SMTP com falha temporária | ag1 responde em #1200 | o núcleo tenta de novo conforme a spec 02 §9; a mensagem que finalmente sai tem o Message-ID, o assunto e os cabeçalhos gerados pelo núcleo, sem alteração |
| EX-35 | fonte IMAP | o processo cai depois de gravar a mensagem e antes de movê-la | no ciclo seguinte a mensagem é lida de novo, reconhecida como duplicata (spec 02 §2.3) e movida; nada duplicado |
| EX-36 | IMAP fora do ar | 15 minutos de falhas seguidas | o admin é avisado; o estado de saúde mostra o último sucesso |
| EX-37 | provedor Google (no teste, o provedor de teste) devolve o e-mail de ag1 **sem** marca de verificado | primeiro acesso | não vincula a ag1; acesso de agente recusado; recusa registrada na auditoria |
| EX-38 | ag2 desativado no PantherDesk | o provedor aceita a credencial de ag2 | acesso recusado |
| EX-39 | provedor de IA configurado; ag1 com leitura em #1200, que tem 3 mensagens públicas, 1 nota interna, 1 anexo e 1 conversa paralela | ag1 pede o resumo | o provedor recebe as 3 mensagens e a nota, sem o anexo e sem a conversa paralela; evento de auditoria com ag1, o momento, #1200 e o tipo "resumo", sem o conteúdo |
| EX-67 | conta com Google na área do agente e no portal, domínio da escola; ag1 cadastrado como agente com endereço do domínio, ainda não verificado | ag1 entra pelo Google pela primeira vez; o provedor confirma o domínio e o e-mail | vincula a ag1 (par provedor + identificador externo); o endereço passa a verificado; entra como agente; auditoria do primeiro vínculo |
| EX-68 | mesma conta | uma conta do domínio que nunca foi cadastrada entra pelo Google na área do agente e depois no portal | área do agente: recusado; portal: cria um solicitante com o endereço verificado; nenhum agente é criado |
| EX-69 | mesma conta | uma identidade de outro domínio tenta a área do agente e a entrada "conta da escola" do portal; outra traz o e-mail com o sufixo do domínio, mas o provedor não confirma o domínio | as três recusadas; no portal, a recusa indica o link por e-mail |
| EX-70 | mesma conta; pessoa "pai1" sem conta do domínio | pai1 pede o link por e-mail no portal e o usa | entra no portal pelo link (spec 07) |
| EX-71 | mesma conta | ag1 pede o link por e-mail na área do agente | recusado: a área do agente só aceita o Google |
| EX-72 | ana (solicitante do domínio) sem sessão | ana abre o endereço do QR da sala B204, entra pelo Google e volta | volta ao formulário com o local B204 preenchido e travado, como estava antes do login (Δ31, Δ33) |
| EX-73 | — | o pedido de entrada traz um endereço de retorno em outro domínio | o retorno é ignorado; depois da entrada a pessoa vai para a página inicial do portal |
| EX-74 | ag1 com sessão aberta obtida pelo Google | o provedor fica fora do ar; ag2 tenta entrar | ag1 continua trabalhando; ag2 recebe a mensagem de falha; o estado de saúde do adaptador mostra o erro |
| EX-75 | instalação de produção; instalação de teste | procurar o provedor de teste em cada uma | só existe na de teste; na de produção não há como ligá-lo |
| EX-78 | instalação de produção cuja conta não configurou o Google para a área do agente | admin tenta entrar na área do agente por senha ou por link por e-mail; procura uma opção de login local para agentes | nenhuma entrada local existe nem pode ser ligada; a área do agente só oferece o Google, e o estado de saúde aponta a configuração ausente (D53) |

### 11.5 API e proibições do MVP
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| EX-40 | — | mesclar um ticket nele mesmo pela API com token pessoal de ag1 | recusado com a mesma regra da interface (spec 01 TL-43) |
| EX-41 | cliente da versão atual da API | o PantherDesk acrescenta um campo novo à resposta de ticket | o cliente continua funcionando; nenhuma mudança de versão |
| EX-42 | admin cria uma macro com o texto `{{ 7*7 }}` | salvar | recusado por marcador desconhecido; nenhuma expressão é avaliada |
| EX-43 | — | procurar, na interface de admin e na API, onde enviar um pacote de código, um script de servidor ou JavaScript personalizado | não existe; nenhuma rota aceita esse tipo de conteúdo |
| EX-44 | — | admin configura a marca da conta | só aceita logo, nome, cor principal e cor de destaque; não há campo de CSS, HTML ou script |
| EX-45 | — | o admin lê a configuração do provedor de IA pela API | a chave não é devolvida, só a indicação de que está configurada |
| EX-66 | macro compartilhada M (resposta pública e estado → pendente); #1200 aberto | `crm` pede a prévia de M para #1200 e depois envia a mensagem aplicando M | prévia sem gravar nada; o envio grava a resposta e muda o estado com as mesmas regras da interface; o evento registra M e o ator `crm` (D29) |

### 11.6 Sistema de apps (roadmap; critérios para quando for implementado)
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| EX-50 | manifesto pede leitura em N1 e escopo escrita | admin recusa a instalação | nada criado: nenhuma identidade, token ou painel |
| EX-51 | app instalado na versão 1.0 com escopo leitura | sai a 1.1 pedindo também escopo escrita | a 1.0 continua com as permissões antigas até o admin aprovar |
| EX-52 | app instalado com dados guardados | admin desativa e reativa 3 dias depois | dados preservados; o app recupera os 3 dias pelo feed de eventos (ou por "mudanças desde") |
| EX-53 | app que gravou notas em tickets | admin remove o app | as notas continuam nos tickets; os dados do app somem após 30 dias; reinstalar no dia 10 recupera os dados |
| EX-54 | painel lateral aberto | o app recebe um contexto assinado com 6 minutos de idade, ou com o ticket alterado | o app rejeita (expirado ou assinatura inválida) |
| EX-55 | app com acesso a N1 e Financeiro | ag3 (só Financeiro) abre o painel num ticket do Financeiro e o app tenta ler um ticket de N1 com o token delegado | recusado (interseção de permissões) |
| EX-56 | painel lateral aberto | o iframe pede para enviar uma resposta | só um rascunho aparece no editor; nada é enviado até ag1 clicar em enviar |

### 11.7 Provedor de IA
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| EX-60 | sem chave de IA configurada | ag1 abre #1200 e tenta chamar o resumo pela API | nenhum botão na tela; a API recusa o pedido como recurso indisponível; nenhuma chamada sai para o provedor |
| EX-61 | provedor que não responde | ag1 pede "melhorar texto" | falha depois de 20 s; o rascunho continua igual; o ticket segue utilizável |
| EX-62 | ag1 pede "mais cordial" e aceita a sugestão | — | só o rascunho muda; nenhuma mensagem é gravada nem enviada até ag1 enviar |

---

## 12. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Inventário de mecanismos de extensão | documentação dos 7 projetos | X-01 em todos (registrar ausências) |
| Ciclo de vida de plugins, módulos e pacotes | documentado em 1 (remoção apaga tabelas), pouco nos outros | X-02 (FreeScout, osTicket, Znuny, Frappe Helpdesk) |
| Campos personalizados (reinício, esquema, validação, condições) | documentação | T-07, X-01 |
| iframe com contexto e bots externos | documentação de 1 projeto | X-01 (Chatwoot: forma do contexto, ciclo do registro) |
| Scripts de servidor desligados por padrão | documentação de 1 projeto | X-01 (Frappe Helpdesk) |
| Eventos para webhooks e tempo real | documentação | API-02, API-03, R-01 |
| Escopos de token | documentação parcial | P-05, API-01 |
| Automações sobre eventos e laços | documentação | AU-01, AU-02 |
| Falha da fonte de entrada | parcial | E-18 |
| Armazenamento de anexos | documentado como plugin em 1 projeto | E-02, X-02 (osTicket) |
| Login com Google, domínio, retorno ao QR, link por e-mail como segundo método | requisitos de cliente (spec 13 Δ31–Δ33) | nenhuma (comportamento definido por nós) |

---

## 13. Questões abertas para o implementador

1. **Tokens pessoais em robôs**: nada impede tecnicamente que um robô use o
   token pessoal de um agente e conte como resposta humana (spec 11 §3).
   Avaliar limitar escopos de tokens pessoais ou exigir validade curta.
2. **Provedor de IA e dados pessoais**: definir se a conta precisa aceitar um
   termo antes de ligar o provedor, e se há exigência sobre retenção dos dados
   pelo provedor externo.
3. **Duração da sessão de agentes** com entrada pelo Google: a spec 06 não a
   define. Proposta: a mesma duração e as mesmas regras de revogação já usadas
   para agentes, independentemente do provedor.
