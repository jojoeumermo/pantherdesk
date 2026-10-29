# Área 5 — Automações, macros, SLA e auto-respostas

Notas comportamentais do analista (clean-room). Fonte: **apenas documentação pública oficial**.
Nada aqui é texto copiado: tudo foi reescrito com palavras próprias, sem rótulos de interface, nomes de configuração,
nomes de classes, tabelas ou caminhos. Cada afirmação traz URL e confiança:

- **documentado**: a página citada afirma o comportamento.
- **inferido**: deduzido do conjunto da documentação ou da ausência de algo; precisa de confirmação.
- **A CONFIRMAR EM RUNTIME**: ambíguo ou não coberto; vira passo de teste nos cenários AU-*.

Data da pesquisa: 2026-10-26. Peppermint excluído. Nenhuma página do Zendesk foi consultada.

---

## 1. Problema

Um helpdesk precisa reagir a eventos sem intervenção humana (rotear, etiquetar, responder ao cliente),
oferecer atalhos para o agente (pacotes de ações) e medir compromissos de tempo (SLA) de forma
**determinística e auditável**. Os pontos difíceis, que geram bugs em todos os produtos estudados, são:

1. **Ordem e reentrada de gatilhos**: em que ordem as regras rodam, se a alteração feita por uma regra dispara outras
   regras (ou a própria), e como se impede laço infinito.
2. **Aritmética de tempo do SLA**: horário comercial, fuso, feriados, pausa em estados de espera, mudança de
   prioridade/política no meio do caminho, reabertura, e o momento exato do alerta prévio e da violação.
3. **Auto-respostas sem laço**: não responder a respostas automáticas, listas, bounces, nem ao próprio sistema;
   limitar a frequência por remetente.
4. **Tarefas agendadas idempotentes**: rodar de novo não deve reaplicar efeitos colaterais (e-mail duplicado etc.).

---

## 2. Comportamento documentado por projeto

### 2.1 Zammad

**Gatilhos (triggers)**
- Três modos de ativação: (a) seletivo — roda numa atualização quando um atributo usado na condição mudou ou um
  novo artigo foi adicionado e a condição casa; (b) "sempre" — roda em qualquer atualização em que a condição casa,
  inclusive mudanças internas que não aparecem no histórico; (c) baseado em tempo — roda quando um lembrete,
  um alerta prévio de escalonamento ou o próprio escalonamento é atingido. A doc avisa que o modo "sempre" pode
  gerar efeitos inesperados e recomenda o seletivo. — https://admin-docs.zammad.org/en/latest/manage/trigger.html — documentado
- Quando dispara por novo artigo, o artigo avaliado é o último; estados/artigos antigos não disparam. — mesma URL — documentado
- Ações: alterar atributos do ticket (estado, prioridade, grupo, dono, tags, data de pendência relativa ou absoluta,
  título, inscrições), enviar e-mail/SMS ao cliente, ao dono ou a todos os agentes (podendo anexar os anexos do artigo
  disparador), adicionar nota interna ou pública, chamar webhook, executar agente de IA. Campos de texto aceitam
  variáveis. — mesma URL — documentado
- **Ordem de execução: alfabética pelo nome do gatilho.** — mesma URL — documentado
- Se o grupo não tem endereço de e-mail configurado, um gatilho com ação de e-mail é inteiramente ignorado. — mesma URL — documentado
- Se as alterações de um gatilho disparam outros gatilhos (reentrada) e qual a proteção contra laço: **não documentado**
  na página de gatilhos. — A CONFIRMAR EM RUNTIME (AU-02, AU-03)
- Proteção anti-loop de auto-resposta (não responder a mensagens marcadas como automáticas/lista/bulk, ou com
  identificador de mensagem do próprio sistema): não aparece na doc oficial consultada; só em fórum comunitário
  (não usado como fonte). — inferido — A CONFIRMAR EM RUNTIME (AU-10, E-09, E-12)
- Existe uma lista de bloqueio de notificações para endereços de sistema (tipo mailer-daemon/noreply) e um aviso
  ao remetente quando a mensagem é grande demais. — https://admin-docs.zammad.org/en/latest/channels/email/settings.html — documentado

**Agendador (scheduler)**
- Jobs por objeto (ticket, usuário ou organização), com condições e ações; rodam nos dias/horários marcados numa grade,
  no fuso global do sistema. Pode excluir objetos (irreversível). — https://admin-docs.zammad.org/en/latest/manage/scheduler.html — documentado
- Limite de 2000 objetos por execução, como proteção contra configuração errada. — mesma URL — documentado
- Por padrão as ações do agendador **não geram notificações**; há opção para mudar. — mesma URL — documentado
- Idempotência e se o agendador aciona gatilhos: não documentado. — A CONFIRMAR EM RUNTIME (AU-09)
- Granularidade da grade (múltiplos de 10 min?): não confirmado na página. — A CONFIRMAR EM RUNTIME (AU-09)

**Macros**
- Pacote de alterações aplicado com um clique, no ticket ou em massa a partir de listas/busca. Ações: atributos,
  notas, notificação, agente de IA. **Não há ação de resposta ao cliente** e as macros não aceitam variáveis. — https://admin-docs.zammad.org/en/latest/manage/macros.html — documentado
- Disponibilidade restrita por grupo; comportamento pós-aplicação configurável (ficar, fechar aba, ir ao próximo ticket),
  não vale em massa. — mesma URL — documentado
- Se falta atributo obrigatório que a macro não preenche, **nenhuma** ação é aplicada (atomicidade). — mesma URL — documentado
- Registro no histórico: não documentado. — A CONFIRMAR EM RUNTIME (AU-04)

**SLA**
- Três metas opcionais: primeira resposta (desde a criação, uma vez por ticket, não reinicia ao mudar de grupo),
  atualização (dois modos: intervalo entre atualizações do agente, ou prazo para o agente responder após nova mensagem
  do cliente — sem mensagem do cliente não há prazo) e solução (até um estado do tipo fechado). — https://admin-docs.zammad.org/en/latest/manage/slas.html — documentado
- Seleção por condições de objeto; a doc **não define desempate** entre SLAs sobrepostos e apenas avisa que sobreposição
  pode calcular errado. — mesma URL — documentado (o risco); desempate A CONFIRMAR EM RUNTIME (AU-05)
- Cálculo sobre o calendário associado; ex.: 16 h de SLA com jornada de 8 h = 2 dias úteis. — mesma URL — documentado
- Estados pendentes (lembrete, fechamento) e fechado **congelam** o ticket: aparece como não escalado e prazos ficam
  ocultos. **Ao reabrir, pode escalar imediatamente** conforme a idade e os intervalos. — mesma URL — documentado.
  Consequência: a pausa NÃO é um "relógio parado que retoma de onde parou" garantido — A CONFIRMAR EM RUNTIME (AU-07, T-03)
- Alerta aos agentes cerca de 15 min antes e no momento do escalonamento; e-mail depende das preferências do agente.
  Existe uma visão de tickets escalados ou que escalam em até 10 min. — mesma URL — documentado
- Na violação: ticket marcado como escalado; a doc sugere usar gatilhos/agendador para reatribuir. Não há ação embutida. — mesma URL — documentado
- Notas públicas só contam como resposta se habilitado por comando de console. — mesma URL — documentado
- Editar um SLA pode causar lentidão temporária (recálculo em massa); como tickets existentes são recalculados: não descrito. — mesma URL — documentado / A CONFIRMAR EM RUNTIME

**Calendários**
- Cada calendário tem fuso próprio; horários por dia da semana; vários intervalos por dia (sem sobreposição; fim
  depois do início). — https://admin-docs.zammad.org/en/latest/manage/calendars.html — documentado
- Feriados: assinatura de feriados públicos por país (feed iCal) ou feed próprio, mais feriados/fechamentos manuais. — mesma URL — documentado
- **Intervalo cruzando meia-noite**: a regra "fim depois do início" sugere que não é possível num único intervalo (seria
  preciso dividir em dois dias). — inferido — A CONFIRMAR EM RUNTIME (AU-06)
- Calendário padrão não pode ser excluído; SLA cujo calendário é excluído cai no padrão. — mesma URL — documentado

### 2.2 Chatwoot (somente edição comunitária)

- **Regras de automação**: eventos documentados — conversa criada, conversa atualizada, mensagem criada, conversa
  reaberta (de adiada/resolvida/pendente). Condições dependem do evento, avaliadas na ordem em que foram definidas,
  operadores igual/diferente, combinação E/OU. Ações: atribuir agente ou time, rótulo, e-mail ao time, transcrição,
  silenciar, adiar, resolver, webhook, anexo, enviar mensagem. — https://www.chatwoot.com/hc/user-guide/articles/1677689800-how-to-use-automation — documentado
- Ordem entre regras, reentrada e proteção contra laço: **não documentados**. — A CONFIRMAR EM RUNTIME (AU-02, AU-03)
- Regras só valem para eventos posteriores à sua criação/ativação. — inferido (resumo de busca na mesma fonte) — A CONFIRMAR
- Ressalva de licenciamento: páginas comerciais associam automações a planos pagos da nuvem; a edição comunitária
  auto-hospedada parece incluí-las. — https://www.chatwoot.com/use-cases/automation-routing — inferido — A CONFIRMAR EM RUNTIME
- **Macros**: sequência ordenada de ações salvas (rótulo, atribuir, responder, mudar status, adiar, enviar transcrição,
  anexo), executadas manualmente na barra lateral da conversa, com pré-visualização; privadas ou públicas. — https://www.chatwoot.com/docs/product/features/macros e https://www.chatwoot.com/hc/user-guide/articles/1677141565-chatwoot-glossary — documentado
- **Horário comercial por caixa de entrada** + mensagem de ausência enviada automaticamente quando chega mensagem fora do
  horário; **no máximo uma vez por dia por conversa**, e suprimida se um agente respondeu publicamente nos últimos 5 min.
  O horário não bloqueia recebimento. — https://www.chatwoot.com/hc/user-guide/articles/1777421876-business-hours-and-auto_responder — documentado
- Mensagem de boas-vindas separada da mensagem de ausência. — mesma URL — documentado
- **SLA**: existe (primeira resposta, próxima resposta, resolução; horário comercial opcional; aplicado via automação;
  não removível depois de aplicado; política não editável após criada), mas é recurso **pago/enterprise** —
  só catálogo, fora de escopo. — https://www.chatwoot.com/features/sla — documentado (como pago)
- Não há agendador genérico documentado na edição comunitária (há adiar/"snooze" com reabertura no prazo). — inferido

### 2.3 FreeScout

- Núcleo: **auto-resposta configurada por caixa de correio** (mailbox). — https://github.com/freescout-help-desk/freescout/wiki/FAQ — documentado
- Anti-loop: auto-respostas recebidas são reconhecidas por cabeçalhos padrão de resposta automática (estilo RFC 3834)
  e de precedência (bulk/junk/auto-reply), além de variantes não padronizadas; laços ocorrem quando o sistema externo
  não marca a resposta automática. — mesma URL — documentado
- Frequência de auto-resposta (uma por conversa? por dia por cliente?): não documentado oficialmente. — A CONFIRMAR EM RUNTIME (AU-10)
- Aviso do wiki: não deixar regras/auto-respostas na própria conta de e-mail conectada (risco de laço). — https://github.com/freescout-help-desk/freescout/wiki/Fetching-Emails — documentado
- **Sem gatilhos, macros nem SLA no núcleo**. Tudo isso vem de **módulos pagos** (catálogo):
  - Workflows (pago): automáticos (rodam em segundo plano) e manuais (aplicados pelo agente = macro); condições de
    texto/tags/estado/tempo ("aguardando desde", só quando o cliente escreveu por último); ações de resposta, nota,
    estado, atribuição, mover de caixa, tags, webhook; **limite de execuções por conversa** como proteção anti-laço;
    granularidade de tempo em horas/dias; depende de cron a cada minuto. A doc diz que serve para "SLA-like". — https://freescout.net/module/workflows/ — documentado (catálogo)
  - Office Hours (pago): restringe auto-resposta a fora do expediente. — https://freescout.net/module/office-hours/ — documentado (catálogo)
  - Saved Replies (pago/catálogo) — https://freescout.net/module/saved-replies/

### 2.4 osTicket

- **Filtros de ticket** = gatilhos **somente na criação**, por canal-alvo (qualquer, formulário web, API, e-mail,
  endereço específico). Ordem numérica de execução e opção de parar o processamento ao casar. Até 25 regras por filtro,
  casar todas/qualquer. Ações: rejeitar, usar Reply-To, desativar auto-resposta, anexar resposta pronta, definir
  departamento/estado/prioridade/SLA/tópico, atribuir a agente/time, enviar e-mail. Rejeitar invalida as outras ações;
  prioridade e SLA do filtro sobrepõem os do departamento. — https://docs.osticket.com/en/latest/Admin/Manage/Ticket%20Filters.html — documentado
- **Não há gatilhos em atualização** documentados (só criação). — inferido da mesma URL
- **Macros**: respostas prontas (canned) — texto, sem pacote de ações documentado; podem ser anexadas por filtro. — inferido (mesma URL e https://docs.osticket.com/en/latest/Admin/Agents/Roles.html)
- **SLA**: um único prazo (período de carência em horas) até o ticket ficar **atrasado (overdue) se não fechado** — é
  prazo de *resolução*, não de primeira resposta. — https://docs.osticket.com/en/latest/Admin/Manage/SLA%20Plans.html — documentado
- Atribuição de SLA: tópico de ajuda, departamento, filtro, padrão do sistema; no painel do agente, a escolha do agente
  sobrepõe; no portal, o do tópico salvo se um filtro casar; por e-mail, o do departamento do endereço salvo filtro. — mesma URL — documentado
- SLA **transitório**: pode ser substituído ao transferir departamento ou mudar tópico; não transitório mantém o SLA
  da criação. — mesma URL — documentado (o modo de recálculo do prazo: A CONFIRMAR EM RUNTIME)
- Data de vencimento manual definida pelo agente: SLA não a sobrepõe. — mesma URL — documentado
- Opção por SLA de desligar o alerta de atraso. Alerta de atraso vai ao responsável/time, gerente do departamento e
  membros do departamento, sem duplicar. — mesma URL e https://docs.osticket.com/en/latest/Guides/Alerts%20Guide.html — documentado
- **Não há alerta prévio** (antes de vencer) documentado. — inferido — A CONFIRMAR EM RUNTIME (AU-05)
- **Agendas (schedules)**: horário comercial + feriados (exceções); precedência: agenda do departamento > do SLA >
  padrão do sistema > nenhuma (aí conta tempo corrido). Fuso vazio = fuso do sistema. Ferramenta de diagnóstico mostra
  as horas úteis futuras e os feriados como horas puladas. — https://docs.osticket.com/en/latest/Admin/Manage/Schedules.html — documentado
- Cruzar meia-noite, 24x7 e cálculo para ticket criado fora do expediente: não documentados. — A CONFIRMAR EM RUNTIME (AU-06)
- Reabertura: ticket reaberto vai sempre ao último respondente. Efeito no SLA: não documentado. — https://docs.osticket.com/en/latest/Admin/Settings/Tickets.html — documentado / A CONFIRMAR (T-03)
- **Pausa em estado pendente: não existe** como conceito documentado. — inferido — A CONFIRMAR (AU-07)
- **Auto-respostas**: novo ticket, novo ticket aberto por agente (agente escolhe quem notificar), nova mensagem
  (confirmação ao remetente e aviso aos demais participantes), aviso de limite de tickets abertos (uma vez).
  Desligáveis por departamento, tópico, filtro ou endereço. — https://docs.osticket.com/en/latest/Guides/Alerts%20Guide.html — documentado
- Limite de tickets abertos por e-mail/usuário (anti-flood). — https://docs.osticket.com/en/latest/Admin/Settings/Tickets.html — documentado
- Regras anti-loop explícitas: não documentadas. — A CONFIRMAR EM RUNTIME (AU-10, E-09)
- Tarefas periódicas via cron (local ou chamada remota autenticada por chave de API). — https://docs.osticket.com/en/latest/Admin/Manage/API%20Keys.html — documentado

### 2.5 Znuny

- **Agente genérico**: modo agendado (horário/minuto/dia, afeta vários tickets que casam com a busca) ou por evento
  (ex.: criação; afeta um ticket). Executar manualmente um job de evento aplica a todos os tickets do filtro. Ações:
  alterar atributos, nota, exclusão permanente, desligar notificações de agente, módulo customizado. Limite de 4000
  tickets por execução. Notificações de agente são enviadas por padrão. — https://doc.znuny.org/znuny/admin/automation/generic_agent/index.html — documentado
- Lista de eventos disponíveis (criação de ticket, criação de artigo etc.) em anexo de referência. — https://doc.znuny.org/znuny/annexes/event_reference/index.html — documentado
- Ordem entre jobs e reentrada: não documentado. — A CONFIRMAR EM RUNTIME (AU-02, AU-03)
- **Escalonamento** (três tipos): primeira resposta (só tickets novos/abertos sem contato externo visível do agente;
  por padrão só telefone/e-mail visível ao cliente encerra), atualização (escala só se o **cliente escreveu por último**),
  solução (só se o ticket **nunca** foi fechado — ticket reaberto não volta a escalar por solução). — https://doc.znuny.org/znuny_lts/generalinformation/ticketescalation/index.html — documentado
- Prazos vêm do SLA se houver; senão da fila. Calendário escolhido por fila (e SLA). Só horas úteis e feriados do
  calendário contam. — mesma URL e https://doc.znuny.org/znuny/admin/queues/index.html — documentado
- **Recálculo** do índice de escalonamento após: mudança de SLA, fila, estado, tipo, serviço, cliente, prioridade ou
  campo dinâmico; criação; novo artigo; merge. — https://doc.znuny.org/znuny_lts/generalinformation/ticketescalation/index.html — documentado
- Verificação periódica (padrão a cada 5 min) → granularidade de detecção de violação de até 5 min. — mesma URL — documentado
- Alerta prévio configurável **em percentual** do prazo (ex.: 60 %) por tipo; eventos de "antes", "início" e "fim" do
  escalonamento consumíveis por notificações, processos, agentes genéricos e webservices. Destinatários padrão: agentes
  com escrita na fila e inscritos. — https://doc.znuny.org/znuny_lts/concepts/escalation/index.html — documentado
- **Pausa em estado pendente: não documentada** (só fechamento encerra o prazo de solução). — A CONFIRMAR EM RUNTIME (AU-07)
- **Auto-respostas por fila**, por tipo: novo e-mail; novo ticket após fechado (quando a fila cria ticket novo);
  rejeição (fila rejeita follow-up); follow-up. Supressão: cabeçalho de laço próprio do produto, expressão regular de
  endereços que nunca recebem auto-resposta, e por padrão tickets criados pela interface web não recebem. — https://doc.znuny.org/znuny/admin/communication/autoresponses/index.html — documentado
- Limite diário de e-mails automáticos por endereço: só em blog do fabricante (não doc). — https://www.znuny.com/en/blog/loop-protection-and-znuny — inferido — A CONFIRMAR (E-12)
- Macros: não há conceito equivalente documentado no núcleo (há modelos de resposta). — inferido — A CONFIRMAR (AU-04)

### 2.6 UVdesk (edição open source)

- **Workflows** = evento + condições + ações. Eventos de nível superior: ticket, agente, cliente (exemplo: ticket criado).
  Condições sobre e-mail, ticket e cliente, combinadas E/OU. Ações descritas genericamente (e-mail, atribuição,
  atualização de campos). — https://docs.uvdesk.com/uvdemo/productivity/workflow.html — documentado
- Doc da API indica tipos manual/automático e que reordenar define prioridade de execução. — https://www.uvdesk.com/en/api-doc/ — inferido (resumo de busca) — A CONFIRMAR (AU-03)
- Laço/reentrada: não documentado. — A CONFIRMAR (AU-02)
- **Respostas preparadas** = workflow manual (macro): atribuir, estado, tags, prioridade; compartilháveis com grupos e
  times; aplicadas pelo rodapé do ticket. — https://docs.uvdesk.com/uvdemo/productivity/prepared-response.html — documentado
- **SLA**: só como app do catálogo de apps; compatibilidade com a edição open source contraditória nas fontes. — https://www.uvdesk.com/en/apps/uvdesk-open-source-sla-app/ — catálogo — A CONFIRMAR (AU-05)
- Auto-resposta ao cliente: via workflow (e-mail ao cliente na criação). — inferido — A CONFIRMAR (AU-10)

### 2.7 Frappe Helpdesk

- **SLA**: seleção = condição casa **e** a tabela de prioridades da política contém a prioridade do ticket; senão tenta a
  próxima. Ordem por *rank* (menor primeiro; zero = sem rank, por último); empate → política mais antiga (para que uma
  nova política não "roube" tickets existentes). Política padrão dispensa condição, é tentada por último e também
  precisa conter a prioridade. Nenhuma política → ticket sem metas (normal). — https://docs.frappe.io/helpdesk/service-level-agreement — documentado
- Metas por prioridade (primeira resposta e resolução); exemplo de política padrão de 10h–18h seg–sex. — mesma URL — documentado
- Horas fora do expediente e datas da lista de feriados não contam; o tempo em estado "respondido/aguardando cliente"
  é excluído da resolução. — mesma URL — documentado
- Violação: ticket marcado como falho; **violação registrada permanece** mesmo que o SLA depois seja removido. — mesma URL — documentado
- Mudança de prioridade/condição/política desativada que tira o SLA → metas limpas na próxima atualização; se voltar a
  casar, **recalcula a partir de quando o SLA foi anexado pela primeira vez** (o relógio não reinicia). — mesma URL — documentado
- **Inconsistências na própria doc** (úteis como casos de teste): um exemplo rotulado como prioridade baixa usa as metas
  da média; um prazo de resolução de 24 h úteis contado a partir de segunda 18h deveria cair em quinta 18h e a doc diz
  quarta; um exemplo em estado pausado calcula a resolução como se o relógio corresse. — mesma URL — documentado (as
  inconsistências) — A CONFIRMAR EM RUNTIME (AU-06, AU-07)
- Estados têm categoria (aberto = relógio corre; pausado = para; resolvido = encerra); estados customizados possíveis;
  pelo menos um ativo por categoria. Reabertura vai para um estado de reabertura definido na política de SLA ou, na
  falta, num padrão global. — https://docs.frappe.io/helpdesk/ticket-status — documentado
- Efeito da reabertura no prazo de resolução (retoma? recomeça?): não documentado. — A CONFIRMAR (T-03, AU-07)
- Alerta prévio antes da violação: não documentado. — A CONFIRMAR (AU-05)
- Automação: regras de atribuição (por condição, rodízio ou menor carga, pulando agentes ausentes); respostas salvas que
  também podem alterar o ticket (estado, tag) = macro leve; status automático (respondido quando agente responde,
  aberto quando cliente responde). — https://docs.frappe.io/helpdesk/your-first-steps-with-frappe-helpdesk — documentado
- Gatilhos genéricos: herdados do framework (notificações, fluxos de automação em beta, scripts). — https://docs.frappe.io/framework/automations — documentado (existência); comportamento A CONFIRMAR
- Auto-resposta: e-mail de confirmação de recebimento ao cliente na criação por e-mail, opcional. Regras anti-loop: não
  documentadas. — https://docs.frappe.io/helpdesk/email-notifications — documentado / A CONFIRMAR (AU-10)

---

## 3. Tabela comparativa

| Aspecto | Zammad | Chatwoot CE | FreeScout (núcleo) | osTicket | Znuny | UVdesk OSS | Frappe HD |
|---|---|---|---|---|---|---|---|
| Gatilho na criação | sim | sim | não (módulo pago) | sim (filtros) | sim (evento) | sim | via framework |
| Gatilho na atualização | sim (seletivo/sempre) | sim | não (pago) | **não** | sim (evento) | sim | via framework |
| Ordem documentada | alfabética | não | — | numérica + parar | não | reordenação (API) | — |
| Reentrada/laço documentado | não | não | limite de execuções (pago) | n/a | não | não | não |
| Agendador | sim (grade, 2000/execução) | não | pago | cron | sim (4000/execução) | ? | framework |
| Macros | sim, sem resposta ao cliente, atômica | sim, com resposta | pago | só texto pronto | modelos de resposta | sim (resp. preparadas) | resposta salva + ações |
| Metas SLA | 1ª resp., atualização, solução | pago | pago | só resolução (atraso) | 1ª resp., atualização, solução | app | 1ª resp., resolução |
| Calendário/fuso por SLA | sim / sim | — | — | sim (agenda), precedência depto>SLA>sistema | por fila/SLA | — | sim + lista de feriados |
| Feriados | iCal + manual | — | — | sim | sim | — | lista de feriados |
| Pausa em espera | congela (pendente/fechado), pode escalar ao reabrir | — | — | não | não documentado | — | categoria "pausado" |
| Alerta prévio | ~15 min fixo | — | — | não | % do prazo | — | não documentado |
| Na violação | marca + notifica; ação via gatilho | — | — | marca atrasado + alerta | eventos para automação | — | marca falho (permanente) |
| Mudança de prioridade | A CONFIRMAR | — | — | SLA transitório | recalcula | recalcula desde o 1º anexo | — |
| Auto-resposta | gatilho | ausência por horário (1/dia/conversa) | por caixa | por depto/tópico/endereço | por fila e tipo | workflow | confirmação |
| Anti-loop documentado | bloqueio de endereços de sistema | 1/dia + 5 min após agente | cabeçalhos padrão | limite de abertos | cabeçalho próprio + regex de endereços | não | não |

---

## 4. A CONFIRMAR EM RUNTIME (mapa para cenários)

| ID | Pergunta | Projetos |
|---|---|---|
| AU-01 | Condições disponíveis na criação; ordem relativa entre gatilho e auto-resposta; o roteamento por assunto acontece antes do e-mail de confirmação? | todos |
| AU-02 | A alteração feita por um gatilho dispara outros gatilhos/a si mesmo? Há limite de iterações? Gatilho do modo "sempre" em ticket alterado por gatilho? | Zammad, Chatwoot, Znuny, UVdesk |
| AU-03 | Dois gatilhos conflitantes: vence o último aplicado (Zammad: alfabético)? Reordenação na UVdesk; ordem numérica no osTicket | Zammad, osTicket, UVdesk, Chatwoot, Znuny |
| AU-04 | Macro gera uma entrada de histórico única ou uma por campo? É atômica (Zammad diz que sim)? Envia e-mail? | Zammad, Chatwoot, UVdesk, Frappe |
| AU-05 | Instantes exatos de: prazo calculado, alerta prévio (15 min fixo no Zammad; % no Znuny), violação (atraso de detecção: verificação a cada N min). Desempate com SLAs sobrepostos | Zammad, osTicket, Znuny, Frappe |
| AU-06 | Horário comercial cruzando meia-noite (é possível configurar? como conta?), ticket criado fora do expediente, feriado no meio, fuso do calendário ≠ fuso do sistema, mudança de horário de verão | Zammad, osTicket, Znuny, Frappe |
| AU-07 | Pausa em pendente: o relógio retoma de onde parou ou o prazo continuou correndo e escala imediatamente ao reabrir (Zammad sugere o segundo)? Znuny pausa? Frappe: pausa afeta só resolução ou também 1ª resposta? | Zammad, Znuny, Frappe, osTicket |
| AU-08 | Na violação, alguma ação embutida além de marcar/notificar? Notificação repetida? | Zammad, osTicket, Znuny |
| AU-09 | Agendador: frequência real, idempotência (rodar 2x não duplica e-mail), se aciona gatilhos, limite por execução | Zammad, Znuny, osTicket |
| AU-10 | Auto-resposta: cabeçalhos de saída (marca de resposta automática?), não responde às fixtures 08/10/11, frequência por remetente/conversa | todos |
| T-03 | Reabertura: SLA de solução zera, retoma ou nunca mais escala (Znuny: nunca mais)? 1ª resposta já cumprida permanece? | todos com SLA |
| E-09/E-12 | Laço entre duas instâncias com auto-resposta | todos |

**Casos de teste de aritmética de SLA a automatizar** (derivados das lacunas acima; datas no fuso do calendário):

1. Criação dentro do expediente, meta inteira no mesmo dia (controle).
2. Criação 1 h antes do fim do expediente; meta de 4 h úteis → vence 3 h após a abertura do próximo dia útil (exemplo de terça 17h → quarta 13h com expediente 10–18h, coerente com Frappe).
3. Criação em sábado → contagem começa na abertura de segunda.
4. Feriado numa terça no meio de um prazo de 16 h → pula o dia inteiro.
5. Expediente noturno 22h–06h (cruza meia-noite) modelado como dois intervalos (22–24 e 00–06 do dia seguinte); o dia
   da semana do segundo intervalo é o dia seguinte.
6. Calendário em fuso diferente do sistema e do usuário; mudança de horário de verão dentro do prazo.
7. Pausa: ticket vai a pendente faltando 2 h; fica 3 dias; volta → restam 2 h úteis (comportamento recomendado) vs. escala imediata (Zammad).
8. Mudança de prioridade de média para alta no meio: prazo recalculado **a partir da criação** (não do momento da mudança); se o novo prazo já passou → violação imediata.
9. Reabertura após resolvido: 1ª resposta permanece cumprida; resolução retoma com o tempo já consumido (ou nova contagem — decidir).
10. Violação registrada não é apagada quando o SLA muda depois (Frappe).
11. Meta de 0 / política sem a prioridade do ticket → sem SLA (Frappe).
12. Exemplo de 24 h úteis a partir de segunda 18h com expediente de 8 h → quinta 18h (corrige a doc do Frappe).

---

## 5. Recomendação preliminar para o MVP (simples e correto)

1. **Gatilhos** só em dois eventos: ticket criado e ticket atualizado (incluindo nova mensagem do cliente/agente).
   Condições E (sem OU no MVP) sobre canal, assunto/corpo contém, remetente/domínio, grupo, prioridade, estado, tag,
   autor da última mensagem. Ações: definir grupo/dono/prioridade/estado, adicionar/remover tag, nota interna,
   e-mail ao cliente (modelo). Ordem **explícita por posição numérica** (não alfabética). Execução **em uma passada por
   evento**: as alterações feitas pelos gatilhos *não* redisparam gatilhos dentro da mesma transação; cada gatilho roda
   no máximo uma vez por evento; registrar no histórico qual gatilho alterou o quê. Isso elimina laço sem contador mágico.
2. **Macros**: lista ordenada das mesmas ações dos gatilhos + resposta pública opcional; aplicação **atômica** (tudo ou
   nada), uma entrada de histórico agrupada; visibilidade por grupo. Macros não disparam gatilhos de "atualização"
   separadamente — disparam um único evento de atualização ao final.
3. **SLA simples**: duas metas (primeira resposta e resolução) por prioridade, uma política padrão + políticas por
   condição com ordem explícita (primeira que casa vence; desempate determinístico). Um calendário por política com fuso
   IANA, intervalos por dia da semana (sem cruzar meia-noite: dividir em dois intervalos) e lista de feriados por data.
   Prazo = soma de minutos úteis a partir da **criação**; pausa em estado "aguardando cliente" **congela o tempo
   consumido** e retoma de onde parou. Mudança de prioridade/política recalcula a partir da criação, descontando pausas.
   Reabertura: primeira resposta continua cumprida; resolução retoma o tempo consumido. Alerta prévio configurável
   (minutos antes, padrão 15 % ou 15 min) e evento de violação, ambos **idempotentes** (gravados uma vez, com marca de
   tempo); violação permanece registrada. Um worker verifica a cada minuto, mas o prazo é armazenado como instante
   absoluto calculado, não derivado da periodicidade.
4. **Auto-resposta** de confirmação na criação: nunca responder a mensagens marcadas como automáticas (cabeçalhos
   padrão RFC 3834 / precedência bulk-list-junk / listas), a endereços de sistema (regex configurável), nem a mensagens
   cujo identificador pertença ao próprio domínio do sistema; limite por remetente (ex.: N por 24 h); marcar a saída como
   resposta automática.
5. Fora do MVP: agendador genérico (só o job fixo de fechar resolvidos após N dias, idempotente), escalonamento
   multinível, SLA de "próxima resposta".
