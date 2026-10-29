# Área 1 — Modelo de dados e ciclo de vida do ticket

Notas comportamentais do analista (clean-room). Fonte: **apenas documentação pública oficial**
(manuais de admin/usuário, FAQ/wiki de documentação, notas de versão). Nenhum código-fonte foi lido.
Tudo está reescrito com palavras próprias: sem rótulos de interface, nomes de configuração, nomes de
classes, tabelas ou caminhos. Cada afirmação traz URL e confiança:

- **documentado**: a página citada afirma o comportamento.
- **inferido**: deduzido do conjunto da documentação, de fonte secundária (fórum oficial, notas de versão)
  ou da ausência de algo; precisa de confirmação.
- **A CONFIRMAR EM RUNTIME**: ambíguo ou não coberto; vira passo de teste nos cenários T-*.

Data da pesquisa: 2026-10-26. Peppermint excluído. Nenhuma página do Zendesk consultada.
Chatwoot: só a edição comunitária (recursos de IA/pagos ignorados).

---

## 1. Problema que a área resolve

O ticket é a unidade de trabalho do helpdesk: agrega uma sequência de mensagens entre um solicitante e a
equipe, com um dono, um grupo/fila, um estado e metadados. O modelo precisa responder, sem ambiguidade:

1. **Quem** pediu (solicitante, organização), **quem** atende (agente, grupo) e **quem mais** participa (CC).
2. **Em que ponto** o pedido está (estado), quais mudanças de estado são válidas e quais acontecem sozinhas
   (resposta do cliente reabre; prazo de espera vence; fechamento automático após resolvido).
3. **O que acontece depois do fim**: resposta em ticket fechado reabre, cria outro ticket ou é rejeitada.
4. **Identidade estável** (número legível usado no assunto do e-mail e na busca) e **trilha de auditoria**
   (quem mudou o quê, quando, valor anterior/novo — incluindo mudanças feitas por automações).
5. Operações estruturais: **mesclar** duplicados e **dividir** um ticket que virou dois assuntos, sem
   quebrar o encadeamento futuro de e-mails.

---

## 2. Comportamento documentado por projeto

### 2.1 Zammad

**Entidades**
- Ticket contém "artigos" (mensagens). Cada artigo tem tipo (e-mail, nota, telefone, chat…), um papel de
  remetente (agente, cliente, sistema) e um flag de visibilidade interna. Anexos pertencem ao artigo.
  — https://admin-docs.zammad.org/en/latest/channels/email/filters/system-filters.html (papel de remetente e
  artigo interno) — documentado / inferido (modelo geral)
- Usuários têm papéis (cliente, agente, admin); cliente pode pertencer a organização; tickets pertencem a um
  grupo; existem tags. — https://admin-docs.zammad.org/en/latest/channels/email/filters.html — inferido
- Campos customizados ("atributos de objeto") para ticket, usuário, organização e grupo. Tipos: booleano,
  data, data-hora, inteiro (mín/máx), seleção simples/múltipla, árvore simples/múltipla (até 6 níveis),
  texto curto (com subtipo e-mail/telefone/URL), texto longo, fonte de dados externa. **O tipo não pode ser
  alterado depois de aplicado**; a recomendação é desativar em vez de excluir; campo novo começa vazio nos
  registros existentes. — https://admin-docs.zammad.org/en/latest/system/objects/types.html ,
  https://admin-docs.zammad.org/en/pre-release/system/objects.html — documentado

**Estados**
- Estados-base: novo (sem 1ª resposta ainda), aberto, pendente-lembrete (some das visões e volta numa data),
  pendente-fechamento (fecha sozinho na data), fechado, mesclado. Pendentes não contam tempo de SLA.
  — https://user-docs.zammad.org/en/6.4/basics/service-ticket/settings/state.html — documentado
- Não há estado "resolvido" separado; o "fechar depois de N dias" é feito com pendente-fechamento ou com
  tarefa agendada. — mesma URL + https://admin-docs.zammad.org/en/latest/manage/scheduler.html — inferido
- Restrições de transição: não documentadas. — **A CONFIRMAR EM RUNTIME (T-02)**

**Resposta do cliente / ticket fechado**
- Configuração **por grupo** do que fazer com resposta a ticket fechado: (a) reabrir (padrão); (b) criar
  ticket novo contendo só a resposta, mantendo o antigo fechado; (c) reabrir apenas se a resposta chegar
  até N dias após o último fechamento, senão criar ticket novo. Não há opção "rejeitar" documentada.
  — https://admin-docs.zammad.org/en/latest/manage/groups/settings.html — documentado
- Na reabertura, por padrão o ticket continua com o último dono; opcionalmente o dono é removido.
  — mesma URL — documentado
- Resposta do cliente em ticket pendente-lembrete volta para aberto e a data de pendência se perde
  (relato de fórum). — https://community.zammad.org/t/set-pending-reached-tickets-to-open-via-trigger-or-even-automatically/139
  — inferido / **A CONFIRMAR EM RUNTIME (T-03)**
- Respostas automáticas de ausência (out-of-office) são anexadas ao ticket **sem mudar o estado**.
  — https://admin-docs.zammad.org/en/latest/channels/email/filters/system-filters.html — documentado

**Numeração**
- Formatos: contador incremental (prefixado por um ID de sistema, com tamanho mínimo e zeros à esquerda) ou
  baseado em data (ano-mês-dia + ID de sistema + contador). Dígito verificador opcional para reduzir falsos
  positivos na detecção de follow-up. **Trocar o formato em produção quebra a detecção de follow-up.**
  — https://admin-docs.zammad.org/en/latest/settings/ticket.html — documentado
- O número aparece no assunto com um prefixo configurável, à direita (padrão), à esquerda ou omitido.
  — mesma URL — documentado

**Merge / split**
- Merge: abre-se o duplicado e mescla-se no original; todas as mensagens e notas migram para o destino; o
  ticket de origem permanece, com estado "mesclado", conteúdo substituído por um marcador e vínculo de
  "pai" para o destino. — https://user-docs.zammad.org/en/latest/advanced/ticket-actions/merge.html — documentado
- Follow-ups enviados ao ticket mesclado são redirecionados ao ticket sobrevivente.
  — https://admin-docs.zammad.org/en/latest/channels/email/filters/system-filters.html — documentado
- Não há desfazer merge (fórum). — https://community.zammad.org/t/un-merge-tickets/13016 — inferido
- Split: por artigo; abre criação de ticket novo pré-preenchida; os dois ficam vinculados.
  — https://user-docs.zammad.org/de/latest/_sources/advanced/ticket-actions/split.rst.txt — documentado

**Histórico**
- Histórico por ticket acessível na barra lateral; desde a 6.1 mostra o nome do gatilho que fez a mudança
  automática. Granularidade (antes/depois) não detalhada na doc. — https://zammad.com/en/product/features/historization-of-changes
  — inferido / **A CONFIRMAR EM RUNTIME (T-08)**

### 2.2 Chatwoot (edição comunitária)

**Entidades**
- Modelo orientado a **conversa** (não "ticket"): conversa pertence a uma caixa de entrada (canal), tem um
  contato, mensagens, agente responsável, time, etiquetas e atributos customizados. Sem número de ticket no
  assunto; identificação por ID numérico da conversa. — https://developers.chatwoot.com/api-reference/conversations/conversation-details
  — inferido

**Estados**
- Quatro estados: aberto (padrão), pendente, adiado (snoozed) e resolvido. Adiado pode ter data-limite ou
  ficar "até a próxima resposta do contato"; **conversa adiada sempre reabre quando o contato responde**.
  — https://developers.chatwoot.com/api-reference/conversations/toggle-status — documentado
- Resolvida sai da fila aberta; **se o cliente escrever de novo, reabre automaticamente**.
  — https://www.chatwoot.com/hc/user-guide/articles/1677231493-lesson-2-dashboard-basics — documentado
- Não há estado "fechado" distinto de "resolvido"; portanto não existe a noção "resposta em fechado cria
  ticket novo". — inferido
- Resolução automática por inatividade: não encontrada na doc pública da edição comunitária.
  — **A CONFIRMAR EM RUNTIME (T-04)**
- A doc da API de atualização lista só três estados (sem adiado), divergindo da de alternância de estado.
  — https://developers.chatwoot.com/api-reference/conversations/update-conversation — documentado (divergência)

**Merge / histórico / campos**
- Merge de conversas: não documentado (há merge de **contatos**). — **A CONFIRMAR EM RUNTIME (T-06)**
- Histórico: mudanças aparecem como mensagens de atividade dentro da conversa. — inferido /
  **A CONFIRMAR EM RUNTIME (T-08)**

### 2.3 FreeScout

**Entidades**
- Modelo "caixa de correio compartilhada" (estilo Help Scout): caixa (mailbox) → conversas → threads
  (mensagens/notas); cliente identificado por um ou mais e-mails; usuários (agentes); tags e campos
  customizados existem via módulos. — https://github.com/freescout-help-desk/freescout/wiki/FAQ — inferido
- Clientes com vários e-mails: adicionar e-mail extra a um perfil **mescla clientes automaticamente**
  (conversas migram; dados do perfil não). Remover um e-mail faz conversas com aquele e-mail gerarem
  cliente novo. — mesma URL — documentado

**Estados**
- Estados: ativo, pendente, fechado e spam (mais "excluído" como pasta). Não há plano de criar
  "resolvido"; a orientação é usar tags/campos. — https://github.com/freescout-help-desk/freescout/wiki/FAQ ,
  https://freescout.net/module/workflows/ — documentado
- Adiar (snooze) e fechamento automático só via módulos (pagos). — https://freescout.net/module/snooze/ ,
  https://freescout.net/module/workflows/ — documentado (fora do núcleo)
- Resposta do cliente a conversa pendente/fechada: a doc do FreeScout **não diz**; o produto imita o Help
  Scout, em que a resposta torna a conversa ativa. — **A CONFIRMAR EM RUNTIME (T-03, T-05)**
- Quando um cliente em CC responde, o **cliente da conversa passa a ser quem respondeu** (por desenho).
  — https://github.com/freescout-help-desk/freescout/wiki/FAQ — documentado

**Numeração / merge / histórico**
- Número da conversa sequencial, com início configurável; busca por número com prefixo "#". Número no
  assunto do e-mail ao cliente não é recurso documentado. — mesma URL — documentado
- Merge de várias conversas de uma vez desde 1.8.110 (notas de versão). — https://installatron.com/updatefeed/freescout_1_8_110
  — inferido / **A CONFIRMAR EM RUNTIME (T-06)**
- Histórico: eventos (atribuição, estado) aparecem na linha do tempo da conversa. — **A CONFIRMAR EM RUNTIME (T-08)**

### 2.4 osTicket

**Entidades**
- Ticket com thread (mensagens do usuário, respostas de agente, notas internas e **eventos** de thread),
  usuário (solicitante) e organização, colaboradores (participantes), departamento, tópico de ajuda,
  equipe, SLA, prioridade, formulários customizados com campos e listas customizadas.
  — https://docs.osticket.com/en/latest/Admin/Manage/Lists.html ,
  https://docs.osticket.com/en/latest/Admin/Manage/Ticket%20Filters.html — documentado
- Limite opcional de tickets abertos por usuário; acima do limite o ticket novo é negado com aviso.
  — https://docs.osticket.com/en/latest/Admin/Settings/Tickets.html — documentado

**Estados**
- Estados-base "aberto" e "fechado"; estados customizados ilimitados, cada um mapeado para um dos dois
  (as versões trazem ainda arquivado/excluído, não descritos na página). — https://docs.osticket.com/en/latest/Admin/Manage/Lists.html — documentado
- Cada estado do tipo fechado define **se uma resposta do usuário reabre** o ticket e **para qual estado
  aberto** ele volta. Se o estado for marcado como não reabrível, a resposta do usuário (dono ou
  colaborador) **cria ticket novo** cujo assunto referencia o número antigo. — mesma URL — documentado
- Só agentes com permissão de fechar veem estados fechados. — mesma URL — documentado
- Estado inicial: padrão do sistema, ou do tópico de ajuda, sobrescrevível por filtro. — mesma URL — documentado
- Ticket reaberto é sempre atribuído ao **último agente que respondeu**; "assumir ao responder" atribui
  ticket sem dono ao agente que responde. — https://docs.osticket.com/en/latest/Admin/Settings/Tickets.html — documentado
- Fechamento automático após resolvido: não documentado (não há estado "resolvido" nativo).
  — **A CONFIRMAR EM RUNTIME (T-04)**

**Numeração**
- Formato com máscara de dígitos (texto fixo é preservado) e sequência aleatória ou sequencial.
  — https://docs.osticket.com/en/latest/Admin/Settings/Tickets.html — documentado

**Merge / link**
- Merge pai/filho: o ticket do topo é o pai; o pai não pode ser mesclado em outro. Visualização combinada
  (cronológica) ou separada. Filhos permanecem como registro histórico (fora da fila, visíveis na busca),
  ou podem ser apagados (o pai guarda um evento de merge). Participantes do filho viram colaboradores do
  pai (padrão) ou só o usuário. **Respostas enviadas a um filho são roteadas ao pai.** Vincular (link) não
  combina threads. Desfazer merge não documentado. —
  https://docs.supportsystem.com/en/latest/Features/Ticket%20Merge%20&%20Link.html (doc da versão hospedada
  oficial do osTicket) — inferido (fonte do mesmo fabricante)

**Histórico**
- Eventos de thread (mudança de estado, atribuição, merge) aparecem na própria thread; existe plugin de
  auditoria. — https://docs.osticket.com/en/latest/ (seção de plugins) — inferido / **A CONFIRMAR EM RUNTIME (T-08)**

### 2.5 Znuny

**Entidades**
- Ticket com artigos (cada artigo tem canal — e-mail, telefone, nota interna, chat — e tipo de remetente
  agente/cliente/sistema, e visibilidade para o cliente), usuário-cliente e empresa-cliente, agente dono e
  agente responsável, observadores, fila (hierárquica), tipo, serviço, SLA, prioridade e campos dinâmicos
  (texto, área de texto, caixa, data, data-hora, lista, multiseleção, web service).
  — https://doc.znuny.org/znuny/admin/ticketclassification/index.html ,
  https://de1.doc.znuny.org/legacy/manual/admin/6.0/en/html/ticket-settings.html — documentado

**Estados**
- Tipos de estado: novo, aberto, fechado, pendente-lembrete (dispara lembrete na data, **sem mudar o estado**),
  pendente-automático (na data, muda sozinho para um estado-alvo configurado por estado), removido (arquivado,
  oculto) e mesclado (somente leitura, vinculado ao destino). Estados internos não podem ser excluídos, só
  invalidados. — https://doc.znuny.org/znuny/admin/ticketclassification/state.html — documentado
- Na instalação padrão (manual 6.0) há fechado com sucesso / sem sucesso e pendente-auto-fechamento positivo
  e negativo. — https://de1.doc.znuny.org/legacy/manual/admin/6.0/en/html/ticket-settings.html — documentado
- "Novo" deixa de ser selecionável depois que houve comunicação. — state.html acima — documentado
- Follow-up recebido leva o ticket para "aberto" por padrão; para tickets fechados há um ajuste separado
  (desligado por padrão) que define o estado após follow-up; um cabeçalho pode preservar o estado atual.
  — https://doc.znuny.org/legacy/manual/admin/6.0/en/html/ConfigReference_Section_Core_Email_PostMaster.html — documentado

**Resposta em ticket fechado (por fila)**
- Três opções: possível (reabre), rejeitar (não reabre; envia auto-resposta de rejeição) ou ticket novo
  (cria e **vincula** ao antigo; follow-ups seguintes sempre criam ticket novo). Opção de bloquear o ticket
  reaberto para o último dono. Sem janela de tempo nativa (há add-on comercial para isso).
  — https://doc.znuny.org/znuny/admin/queues/index.html ,
  https://doc.znuny.org/znuny/admin/communication/autoresponses/index.html ,
  https://www.znuny.com/product/add-ons/followuptime — documentado

**Numeração**
- Geradores: incremental (ID de sistema + contador), por data, por data com dígito verificador (padrão
  histórico), aleatório. Número no assunto com prefixo e separador configuráveis.
  — https://community.znuny.org/viewtopic.php?p=52404 (citações do texto de ajuda da configuração)
  — inferido

**Merge / split / histórico**
- Merge irreversível; comunicações e **histórico** vão para o destino; fica um vínculo com "artigo fantasma"
  para auditoria; opção de notificar o cliente; por padrão só lista tickets abertos do mesmo cliente.
  — https://doc.znuny.org/znuny/agentinterface/ticketviews/agentticketmerge/index.html — documentado
- Split: de um artigo cria ticket novo (telefone, e-mail ou processo). —
  https://doc.znuny.org/znuny-agent-quickstart/_sources/interface/article-menu/index.rst — documentado
- Histórico: lista de todas as ações com autor e data, filtrável por termo. Antes/depois não detalhado.
  — https://doc.znuny.org/znuny/agentinterface/ticketviews/agenttickethistory/index.html — documentado

### 2.6 UVdesk (open source)

**Entidades**
- Ticket com thread (respostas, notas, encaminhamentos), cliente, agente, grupos, times, tipos de ticket,
  tags, prioridade, colaboradores (agente ou cliente pode adicionar; respostas de colaborador entram na
  thread com o nome dele). — https://docs.uvdesk.com/ (seções Users/Productivity) ,
  https://support.uvdesk.com/en/blog/how-to-add-collaborators-in-ticket ,
  https://www.uvdesk.com/en/blog/uvdesk-latest-release/ — documentado
- Campos customizados: só via app/form builder (não documentado na doc open source). — **A CONFIRMAR EM RUNTIME (T-07)**

**Estados**
- Estados selecionáveis ao responder: aberto, pendente, respondido, resolvido, fechado (e spam na lista).
  — https://support.uvdesk.com/en/blog/how-to-add-collaborators-in-ticket (seção de resposta) — documentado
  (fonte da versão SaaS; **A CONFIRMAR EM RUNTIME** na open source)
- Resposta do cliente por e-mail reabre? Há correção antiga de "ticket não abre quando cliente responde por
  e-mail", sugerindo que deve reabrir. — CHANGELOG-1.0 do projeto (cópia em
  `observation/projects/uvdesk/upstream/`) — inferido / **A CONFIRMAR EM RUNTIME (T-03, T-05)**
- Fechamento automático: não documentado (só via workflow, se houver evento temporal). — **A CONFIRMAR EM RUNTIME (T-04)**

**Merge / histórico**
- Merge: não documentado na open source. — **A CONFIRMAR EM RUNTIME (T-06)**
- Relatório de atividade de agente existe; histórico por ticket não documentado. —
  https://docs.uvdesk.com/uvdemo/reports/agent-activity.html — inferido

### 2.7 Frappe Helpdesk

**Entidades**
- Ticket, contato (pessoa), cliente (agrupa contatos; um contato pode estar em vários clientes; contatos do
  mesmo cliente podem ver tickets uns dos outros — gestor vê todos), agente, time, tipo de ticket,
  prioridade, SLA, comunicações (e-mails) e comentários privados. —
  https://docs.frappe.io/helpdesk/contact , https://docs.frappe.io/helpdesk/customer ,
  https://docs.frappe.io/helpdesk/lesson-2understanding-ticket-view — documentado
- Campos extras: o ticket é um documento do framework, logo campos customizados vêm do mecanismo genérico
  de customização. — inferido / **A CONFIRMAR EM RUNTIME (T-07)**

**Estados**
- Estados customizáveis, cada um numa **categoria**: aberto (SLA corre), pausado (SLA pausa) ou resolvido
  (SLA para). Sempre deve existir ao menos um estado ativo por categoria. "Fechado" é fixo, da categoria
  resolvido, não pode ser excluído. Estado inicial e **estado de reabertura** definidos globalmente e
  sobrescrevíveis por política de SLA. — https://docs.frappe.io/helpdesk/ticket-status — documentado
- Modelo clássico (tutorial): aberto → respondido (agente respondeu; resolução pausa) → resolvido → fechado.
  Resposta do cliente em respondido ou resolvido **volta para aberto**. **Fechado: o cliente não pode mais
  responder**; só agente reabre. — https://docs.frappe.io/helpdesk/lesson-2understanding-ticket-view — documentado
  (não fica claro se a proibição vale para e-mail ou só para o portal → **A CONFIRMAR EM RUNTIME (T-05)**)
- Ao responder, o estado pode mudar sozinho para "respondido" (opcional). —
  https://docs.frappe.io/helpdesk/settings — documentado
- Fechamento automático: ativável; escolhe-se o estado de origem e o nº de dias sem resposta do cliente
  (ex.: resolvido há 3 dias → fechado). — https://docs.frappe.io/helpdesk/settings — documentado
- Pesquisa de satisfação enviada na mesma thread de e-mail ao chegar em resolvido ou fechado. — mesma URL — documentado

**Merge / histórico**
- Merge/split: não documentados. — **A CONFIRMAR EM RUNTIME (T-06)**
- Histórico: o framework mantém versões/atividade por documento; não descrito na doc do helpdesk.
  — inferido / **A CONFIRMAR EM RUNTIME (T-08)**

---

## 3. Tabela comparativa

| Aspecto | Zammad | Chatwoot CE | FreeScout | osTicket | Znuny | UVdesk | Frappe HD |
|---|---|---|---|---|---|---|---|
| Unidade | ticket + artigos | conversa + mensagens | conversa + threads | ticket + thread (com eventos) | ticket + artigos | ticket + thread | ticket + comunicações |
| Estado "resolvido" ≠ "fechado" | não | não (só resolvido) | não | não nativo (custom) | não (fechado com/sem sucesso) | sim | sim |
| Espera com data | pendente-lembrete / pendente-fechar | adiado (data ou até resposta) | módulo pago | não nativo | pendente-lembrete / pendente-auto | ? | categoria "pausado" |
| Resposta reabre | sim (exceto fechado, conforme grupo) | sim, sempre | ? (provável) | conforme cada estado fechado | sim → aberto (fechado conforme fila) | provável | sim (exceto fechado) |
| Resposta em fechado | grupo: reabrir / novo / janela N dias | reabre | ? | estado: reabrir / ticket novo referenciando o antigo | fila: reabrir / rejeitar / novo vinculado | ? | bloqueada ao cliente (canal?) |
| Fechamento automático | via pendente-fechar ou agendador | ? (CE) | módulo pago | não documentado | via pendente-auto | ? | nativo (estado + dias) |
| Dono na reabertura | mantém (opção: limpa) | ? | ? | último que respondeu | opção: bloqueia no último dono | ? | ? |
| Numeração | incremental ou data, verificador opcional | ID numérico | sequencial, início configurável | máscara, aleatória ou sequencial | incremental / data / data+verif. / aleatório | ? | ID do documento |
| Merge | sim, origem vira "mesclado" + redirecionamento de follow-up | só contatos | sim (1.8.110+) | pai/filho, filho redireciona ao pai | sim, irreversível, ghost link | ? | ? |
| Split | por artigo, com vínculo | não | ? | ? | por artigo | ? | ? |
| Campos custom | 11 tipos, tipo imutável | atributos custom | módulo | formulários + listas | campos dinâmicos | app | customização do framework |
| Histórico | por ticket, mostra gatilho autor | atividades na conversa | linha do tempo | eventos na thread + plugin | ações com autor/data, filtrável | ? | versões do framework |

`?` = não documentado → teste em runtime.

---

## 4. Divergências e pontos "A CONFIRMAR EM RUNTIME"

| ID | Pergunta | Projetos | Por quê |
|---|---|---|---|
| T-01 | Estado inicial de ticket criado pelo agente (novo vs aberto) e se o solicitante é obrigatório | todos | Zammad distingue "novo" (sem 1ª resposta); Frappe usa estado padrão configurável; osTicket depende do tópico |
| T-02 | Transições recusadas (ex.: voltar a "novo", fechar sem campo obrigatório, pular de pendente para fechado) | todos | nenhuma doc publica matriz de transições; Znuny diz que "novo" fica indisponível após comunicação; osTicket exige tópico para fechar se configurado |
| T-03 | Resposta em resolvido/pendente: estado resultante, dono mantido, SLA zerado ou retomado, data de pendência perdida | todos | Zammad (pendência perdida — fórum), FreeScout e UVdesk sem doc, Frappe volta para estado de reabertura configurável |
| T-04 | Fechamento automático: quem faz (estado com prazo vs tarefa agendada), frequência, e se gera notificação | Zammad, Znuny, Frappe (nativo); Chatwoot, osTicket, UVdesk, FreeScout (?) | só Frappe tem "fechar após N dias em estado X" explícito |
| T-05 | Resposta em fechado por **e-mail**: reabre, cria novo (vinculado? assunto?), rejeita com aviso? | todos | três modelos distintos (Zammad por grupo com janela; osTicket por estado; Znuny por fila com rejeição); Frappe diz que cliente não responde — só no portal? |
| T-06 | Merge: número sobrevivente, estado da origem, participantes, e **para onde vai uma resposta futura ao e-mail do ticket mesclado** | todos | Zammad e osTicket redirecionam ao destino (documentado); Znuny/FreeScout/Frappe silenciosos |
| T-07 | Tipos de campo, validação server-side, valores em histórico, mudar tipo depois | todos | Zammad proíbe mudar tipo; demais não dizem |
| T-08 | Granularidade do histórico (antes/depois por campo? autor = gatilho?) e se é exposto na API | todos | Zammad mostra o gatilho; Znuny filtra por termo; demais vagos |

Divergências conceituais relevantes:
- **Resolvido vs fechado**: Frappe e UVdesk têm os dois; Zammad, Znuny, FreeScout e osTicket colapsam em
  "fechado" e usam espera com prazo para simular "resolvido → fechado".
- **Política de resposta em fechado** fica em lugares diferentes: no grupo (Zammad), na fila (Znuny), no
  próprio estado (osTicket). A do osTicket é a mais expressiva; a do Zammad (janela de N dias) a mais útil.
- **Mudança de solicitante por CC** (FreeScout troca o cliente para quem respondeu) é o oposto dos demais,
  que tratam CC como participante.

---

## 5. Opinião preliminar para o MVP do PantherDesk

1. **Entidades mínimas**: Ticket, Message (com `kind` público/nota interna, autor, direção, anexos por
   mensagem), Requester (pessoa com N e-mails), Organization, Agent, Group, Tag, Participant (CC do ticket),
   CustomField (definição) + valores no ticket, AuditEvent. Separar pessoa de endereço de e-mail desde o
   início (FreeScout mostra o custo de não fazer: merges de cliente implícitos).
2. **Estados fixos no MVP**, com categoria explícita: `new`, `open`, `pending` (com data opcional),
   `resolved`, `closed`, mais `merged`/`spam` como terminais técnicos. Ter "resolvido" separado de "fechado"
   (modelo Frappe/UVdesk) é mais simples de explicar e permite o fechamento automático trivial
   ("resolvido há N dias sem resposta → fechado"), sem truques de pendência com prazo. Estados customizados
   ficam para depois, mas já modelar a **categoria** (aberto/pausado/resolvido) para o SLA.
3. **Matriz de transições explícita** e validada no servidor (o mercado não documenta a sua, e isso gera
   comportamento surpreendente). Resposta do cliente: `pending`/`resolved` → `open`; `closed` → política.
4. **Política para resposta em fechado** configurável por grupo, com três valores: reabrir, criar ticket
   novo **vinculado** (assunto referencia o antigo, como osTicket) e reabrir dentro de N dias senão novo
   (Zammad). Padrão recomendado: janela de N dias (ex.: 14) → evita ressuscitar tickets antigos e evita
   tickets duplicados para respostas imediatas. Rejeitar fica fora do MVP (gera e-mail extra e atrito).
5. **Dono na reabertura**: manter o último dono (todos que documentam fazem isso por padrão).
6. **Numeração**: contador sequencial global, imutável, gerado de forma atômica; nunca trocar formato depois
   (Zammad avisa que quebra o encadeamento). Usar o número no marcador de assunto, mas não depender só dele.
7. **Merge**: origem vira `merged` (somente leitura) com ponteiro para o destino; mensagens movidas;
   participantes unidos; **qualquer resolução de thread que caia no ticket mesclado segue o ponteiro**
   (Zammad/osTicket). Sem "desfazer" no MVP. Split por mensagem com vínculo pode esperar.
8. **Auditoria desde o dia 1**: evento append-only com ator (agente, cliente, sistema, automação + id da
   regra), campo, valor anterior, valor novo e timestamp. Barato agora, caríssimo depois.
