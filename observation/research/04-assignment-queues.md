# Área 4 — Atribuição e filas

> Estudo clean-room. Fonte: somente documentação pública oficial. Nenhum
> código-fonte foi lido. Texto em palavras próprias; não há cópia de textos de
> interface, chaves de configuração ou nomes internos.
> Confiança: **documentado** / **inferido**. **A CONFIRMAR EM RUNTIME** vai para
> os cenários A-* (seção 4). Data: 2026-10-26.

---

## 1. Problema

Todo ticket precisa de uma **unidade responsável** (grupo, fila, departamento, time ou caixa) e, em algum momento, de um **dono** (agente). As decisões de projeto são:

- **Estrutura:** existe uma só dimensão (grupo) ou duas (departamento + time)? Os grupos podem ser hierárquicos?
- **Atribuição manual:** quem pode atribuir a quem (só membros do grupo?), autoatribuição ("pegar") e se responder atribui automaticamente.
- **Automática:** round-robin, balanceamento por carga ou capacidade, habilidades, prioridade da fila e janela de justiça.
- **Disponibilidade:** o que fazer com agente ausente, offline, de férias ou desativado. Os tickets dele ficam, voltam para a fila ou são redistribuídos?
- **Transferência de grupo:** o dono é mantido ou limpo, e quem é avisado.
- **Tickets sem dono:** quem é notificado e onde eles aparecem.
- **Reabertura:** o dono anterior volta ou o ticket fica sem dono?

---

## 2. Comportamento documentado por projeto

### 2.1 Zammad

**Grupos.**
- Um ticket pertence a **exatamente um grupo**. As permissões de agente são dadas por grupo (por exemplo, um grupo restrito para gestão).
- Os grupos podem ser **aninhados**, até 10 níveis, mas membros e permissões **não são herdados**.
- Um grupo desativado some para os agentes, mas ainda pode receber tickets por regras.
- URLs: https://admin-docs.zammad.org/en/latest/manage/groups/index.html, https://admin-docs.zammad.org/en/latest/manage/groups/settings.html
- Confiança: documentado.

**Configurações por grupo que afetam a atribuição.**
- **Tempo limite de atribuição:** depois de N minutos sem atividade do dono no ticket, ele volta a ficar sem dono. O relógio é corrido e ignora o horário comercial.
- **Atribuição de follow-ups:** quando um ticket fechado reabre por resposta do cliente, o padrão é o dono anterior continuar dono. A alternativa é limpar o dono.
- **Follow-up possível:** reabre (padrão), sempre cria ticket novo, ou reabre só dentro de N dias.
- URL: https://admin-docs.zammad.org/en/latest/manage/groups/settings.html
- Confiança: documentado.

**Autoatribuição.**
- Não é round-robin. Quando um agente **abre** um ticket sem dono, ele se torna o dono. O padrão vale para tickets em estado aberto, mas o admin pode restringir por condições e excluir usuários (por exemplo, o líder de time).
- O objetivo declarado é evitar que vários agentes trabalhem o mesmo ticket. O agente pode desfazer, voltando o dono para vazio.
- URL: https://admin-docs.zammad.org/en/latest/settings/ticket.html
- Confiança: documentado. A página **não diz** como escolhe entre agentes nem se considera presença online. Inferido: só existe o modo "quem abre leva".

**Round-robin e balanceamento:** não documentados no núcleo. A distribuição é feita por gatilhos (atribuir a grupo ou dono fixo).
- Confiança: inferido (ausência).

**Ausência (out of office).**
- O agente agenda um período de ausência e indica um **substituto**. O substituto passa a receber as notificações dos tickets do ausente e ganha uma visão própria desses tickets. O ausente continua recebendo notificações.
- As visões podem ser restritas a "quem está substituindo alguém", para mostrar ao substituto os tickets novos do colega.
- URLs: https://user-docs.zammad.org/en/latest/extras/user-menu-profile-settings.html, https://admin-docs.zammad.org/en/latest/manage/overviews.html
- Confiança: documentado. A documentação **não diz** que a ausência impede atribuir tickets ao agente. Inferido: **não impede**. **A CONFIRMAR EM RUNTIME** (A-02).

**Agente desativado.** O agente não consegue mais logar, os tickets dele permanecem intactos e ele continua aparecendo nas buscas, marcado como inativo. A documentação não diz se os tickets dele perdem o dono.
- URL: https://admin-docs.zammad.org/en/latest/manage/users/index.html
- Confiança: documentado (parcial). **A CONFIRMAR EM RUNTIME** (A-05).

**Notificações de tickets sem dono.**
- Por padrão, o agente recebe notificações de **todos os tickets dos seus grupos**, inclusive os atribuídos a outros, e pode limitar por grupo. A grade de preferências separa a notificação interna da notificação por e-mail.
- Inferido pela grade: há eventos de ticket novo, atualização, mudança de dono, lembrete e escalonamento, em escopos como "meus", "sem dono", "seguidos" e "todos". As linhas e colunas exatas não aparecem no texto lido.
- URL: https://user-docs.zammad.org/en/latest/extras/user-menu-profile-settings.html
- Confiança: documentado (grupo, canal); inferido (matriz de eventos). **A CONFIRMAR EM RUNTIME** (A-01).

**Transferência de grupo:** o efeito sobre o dono **não é documentado**.
- **A CONFIRMAR EM RUNTIME** (A-04).

### 2.2 Chatwoot (edição comunitária)

**Estrutura.**
- **Caixas de entrada:** os agentes são adicionados individualmente e só veem as conversas das caixas de que fazem parte.
- **Times:** agrupamentos por departamento, criados só por admin. Uma conversa pode estar ligada a um time.
- URLs: https://www.chatwoot.com/hc/user-guide/articles/1677492191-adding-inboxes, https://www.chatwoot.com/hc/user-guide/articles/1677492970-adding-teams
- Confiança: documentado.

**Round-robin.**
- Ligado por padrão, por caixa. Distribui as conversas igualmente entre os agentes *disponíveis* da caixa.
- Se ninguém estiver disponível, a conversa fica **sem dono**.
- URL: https://www.chatwoot.com/hc/user-guide/articles/1677696868-assigning-conversations-in-a-round_robin-fashion
- Confiança: documentado.

**Políticas de atribuição (versão nova).**
- Uma política define a ordem de atribuição, a prioridade (a conversa criada há mais tempo primeiro, ou a que espera resposta há mais tempo primeiro) e um **limite de justiça**: máximo de conversas por agente numa janela de tempo (padrão de 100 por hora).
- Na edição comunitária, **só o round-robin**. Balanceamento por carga e capacidade são da edição Enterprise e foram **ignorados** neste estudo.
- URL: https://www.chatwoot.com/hc/user-guide/articles/1763978164-chatwoot-assignment-v2
- Confiança: documentado. O que acontece ao estourar o limite de justiça (fica sem dono?) é inferido. **A CONFIRMAR EM RUNTIME** (A-02).

**Capacidade por agente** (limite de conversas abertas por caixa): segundo outra página do guia, exige Enterprise. **Fora do escopo.** Fica registrado como referência de comportamento: agentes no limite são pulados, e se todos estiverem no limite a conversa fica sem dono até alguém liberar espaço.
- URLs: https://www.chatwoot.com/hc/user-guide/articles/1741998212-agent-capacity, https://www.chatwoot.com/hc/user-guide/articles/1677238266-lesson-4-complete-your-customer-engagement-suite
- Confiança: documentado (marcado como pago).

**Disponibilidade.**
- O agente escolhe entre online, ocupado e offline. Online entra na autoatribuição; ocupado e offline são pulados.
- O admin pode mudar o status de qualquer agente.
- Uma página diz que o sistema põe o agente **offline automaticamente** ao fechar a aba ou ficar ocioso. Outra diz que a mudança é só manual. As duas se contradizem.
- URLs: https://www.chatwoot.com/hc/user-guide/articles/1677231493-lesson-2-dashboard-basics, https://www.chatwoot.com/hc/user-guide/articles/1677482414-adding-agents
- Confiança: documentado, com contradição. **A CONFIRMAR EM RUNTIME** (A-02).

**Times e transferência.**
- Com a autoatribuição do time ligada, atribuir a conversa a um time escolhe automaticamente um membro como dono.
- **Se o dono atual não é membro do novo time, ele é limpo** para que a autoatribuição escolha alguém válido.
- Com a autoatribuição do time desligada, a conversa fica no time, sem dono, e qualquer membro pode pegá-la.
- Remover um agente do time não tira dele as conversas atuais, mas ele deixa de receber novas daquele time.
- URL: https://www.chatwoot.com/hc/user-guide/articles/1677492970-adding-teams
- Confiança: documentado. **A CONFIRMAR EM RUNTIME** (A-04).

**Agente excluído.** As conversas abertas dele viram **sem dono** e **não são redistribuídas automaticamente**. Um processo em segundo plano o remove de times e caixas. A documentação recomenda reatribuir antes de excluir.
- URL: https://www.chatwoot.com/hc/user-guide/articles/1677482414-adding-agents
- Confiança: documentado. **A CONFIRMAR EM RUNTIME** (A-05).

**Visão de sem dono.** A lista de conversas tem abas "minhas", "sem dono" e "todas".
- URL: https://www.chatwoot.com/hc/user-guide/articles/1677231493-lesson-2-dashboard-basics
- Confiança: documentado.

**Automações.** Regras podem atribuir a um agente ou a um time e rodam na ordem listada; se duas atribuem times diferentes, vale a última. Uma reatribuição manual ou por macro sobrepõe a autoatribuição.
- URL: https://www.chatwoot.com/hc/user-guide/articles/1677238266-lesson-4-complete-your-customer-engagement-suite
- Confiança: documentado.

### 2.3 FreeScout

**Estrutura.**
- Departamentos são **mailboxes**. Times existem só via módulo pago.
- Um admin pode restringir um agente a ver **só as conversas atribuídas a ele**. Nesse caso, o agente não vê a pasta de sem dono.
- Um agente pode mover uma conversa para uma mailbox a que não tem acesso.
- Admins podem ser escondidos da lista de possíveis donos de uma mailbox.
- URL: https://github.com/freescout-help-desk/freescout/wiki/FAQ
- Confiança: documentado.

**Módulo de times** (catálogo): atribuir ao time funciona como atribuir a uma pessoa. Os membros são notificados na atribuição, na resposta do cliente e na resposta ou nota de um colega. **Não menciona round-robin.**
- URL: https://freescout.net/module/teams/
- Confiança: documentado (catálogo).

**Round-robin e balanceamento:** não existem no núcleo nem como módulo listado. O módulo de workflows (pago) atribui por condições.
- URLs: https://freescout.net/modules/, https://freescout.net/module/workflows/
- Confiança: inferido.

**Módulo de ausência** (catálogo): o agente marcado como ausente não pode receber atribuição manual de colegas e aparece marcado na lista de donos. **Se o cliente responde a uma conversa de um agente ausente, a conversa vira sem dono.** A trava não vale para atribuições feitas pela API ou por workflows.
- URL: https://freescout.net/module/out-of-office/
- Confiança: documentado (catálogo).

**Usuário excluído.** A API de exclusão de usuário aceita um mapa "por mailbox, para quem vão as conversas do excluído". Sem esse mapa, o comportamento padrão não é documentado; um relato antigo indica que as conversas viram sem dono.
- URL: https://api-docs.freescout.net/
- Confiança: documentado (opção); inferido (padrão). **A CONFIRMAR EM RUNTIME** (A-05).

**Notificações.** São configuradas por usuário no perfil (conversa nova, atribuída a mim, respostas, entre outras). Admins recebem notificações de todas as mailboxes, e qualquer usuário pode silenciar uma mailbox.
- URLs: https://github.com/freescout-help-desk/freescout/wiki/FAQ, https://freescout.net/module/end-user-portal/
- Confiança: documentado. **A CONFIRMAR EM RUNTIME** (A-01).

### 2.4 osTicket

**Estrutura.**
- **Departamentos**, que podem ser hierárquicos: quem acessa o pai vê os filhos, mas não o contrário. Cada um tem gerente opcional, membros primários e membros com acesso estendido.
- **Times** atravessam departamentos e têm um líder opcional.
- **Tópicos de ajuda** e **filtros de ticket** roteiam para um departamento e podem **autoatribuir a um agente ou time fixo**.
- URLs: https://docs.osticket.com/en/latest/Admin/Agents/Departments.html, https://docs.osticket.com/en/latest/Admin/Manage/Help%20Topic.html, https://docs.osticket.com/en/latest/Admin/Manage/Ticket%20Filters.html, https://docs.osticket.com/en/v1.15.8/Admin/Agents/Teams.html
- Confiança: documentado.

**Atribuição manual e implícita.**
- **Atribuição ao responder:** se ligada, um ticket sem dono passa a ser do agente que responde. Pode ser desligada por departamento.
- Tickets **reabertos voltam para o último agente que respondeu**. Isso pode ser desligado por departamento.
- Um departamento pode restringir a atribuição aos seus próprios membros.
- Atribuir, transferir e liberar a atribuição são permissões separadas por papel.
- URLs: https://docs.osticket.com/en/latest/Admin/Settings/Tickets.html, https://docs.osticket.com/en/latest/Admin/Agents/Departments.html, https://docs.osticket.com/en/latest/Admin/Agents/Roles.html
- Confiança: documentado.

**Referência (encaminhamento sem transferência).** Dá a outro agente, time ou departamento acesso de leitura e de nota interna sem transferir a responsabilidade.
- URL: https://docs.osticket.com/en/latest/Features/Ticket%20Referral.html
- Confiança: documentado.

**Round-robin e balanceamento:** não documentados.
- Confiança: inferido (ausência).

**Disponibilidade.**
- Agentes bloqueados ou desativados não logam e **somem das listas de atribuição e autoatribuição**.
- **Modo férias:** o agente ainda loga, mas, como o bloqueado, não aparece para atribuição nem autoatribuição e não recebe alertas. O modo é ligado e desligado manualmente, pelo próprio agente ou por um admin.
- URL: https://docs.osticket.com/en/latest/Admin/Agents/Agents.html
- Confiança: documentado. O que acontece com os tickets **já atribuídos** a quem entra em férias ou é desativado não está documentado. **A CONFIRMAR EM RUNTIME** (A-05).

**Alertas** (o modelo mais detalhado entre os sete):

| Alerta | Quem recebe |
|---|---|
| Ticket novo | E-mail do admin; gerente do departamento; membros do departamento, **só se o ticket não foi autoatribuído** (se foi, vai o alerta de atribuição); gerente da conta da organização |
| Mensagem nova do cliente | Último agente que respondeu; dono ou time, se ninguém respondeu ainda; gerente do departamento como último recurso |
| Atividade interna | Regra análoga à da mensagem nova |
| Atribuição | O agente atribuído; ou, se for para um time, o líder e todos os membros |
| Transferência | Dono atual; gerente do departamento de destino; membros do destino |
| Atraso de SLA | Dono ou time; gerente; membros |

  Alertas duplicados para a mesma pessoa são suprimidos. O departamento escolhe o público dos alertas (ninguém, só o admin, membros primários, ou primários mais estendidos). O alerta do departamento primário de um agente não pode ser desligado pelo próprio agente.
- URL: https://docs.osticket.com/en/latest/Guides/Alerts%20Guide.html
- Confiança: documentado.

**Transferência.**
- Um departamento ativo pode receber transferências; um arquivado não pode.
- Para um departamento desativado, nada é transferido, e o roteamento automático manda para o departamento padrão.
- O efeito da transferência sobre o dono não é dito; só que o dono atual é alertado.
- URLs: https://docs.osticket.com/en/latest/Admin/Agents/Departments.html, https://docs.osticket.com/en/latest/Guides/Alerts%20Guide.html
- Confiança: documentado (parcial). **A CONFIRMAR EM RUNTIME** (A-04).

### 2.5 Znuny

**Estrutura.**
- **Filas**, cada uma ligada a um **grupo de permissão**: o agente precisa de leitura e escrita no grupo para ver a fila.
- A fila define escalonamentos (primeira resposta, atualização, solução), calendário, endereço remetente, saudação e assinatura, e política de follow-up (reabrir, rejeitar, ou criar ticket novo ligado ao antigo).
- URL: https://doc.znuny.org/znuny_lts/admin/queues/index.html
- Confiança: documentado.

**Bloqueio (lock) + dono.** Este é o modelo central do Znuny:
- Bloquear torna o agente dono e sinaliza "estou trabalhando". Abrir a tela de resposta bloqueia o ticket automaticamente, e cancelar a resposta desbloqueia. Enviar a resposta, por padrão, **não** desbloqueia.
- Mover o ticket de fila ou de agente pode desbloquear. Fechar normalmente desbloqueia.
- Um ticket desbloqueado está "disponível, precisa de atenção", **mesmo que ainda tenha um dono**. Os tickets bloqueados ficam fora do conjunto de tickets livres.
- URL: https://doc.znuny.org/znuny/concepts/locking/index.html
- Confiança: documentado.

**Tempo de desbloqueio por fila.**
- Se o agente bloqueia e não fecha dentro do prazo, o ticket é desbloqueado por uma tarefa periódica, que só conta horário comercial.
- O prazo reinicia com artigo externo novo ou com reatribuição.
- Há uma notificação padrão avisando que o ticket foi desbloqueado. A própria documentação cita como caso de uso o agente ausente com tickets bloqueados.
- URLs: https://doc.znuny.org/znuny/concepts/locking/index.html, https://doc.znuny.org/znuny-7_0/admin/automation/ticket_notification/index.html
- Confiança: documentado (o funcionamento vem de material de referência legado; confirmar na versão atual).

**Round-robin e balanceamento:** não documentados no núcleo. O modelo é de **puxar**: os agentes pegam tickets livres das "minhas filas".
- Confiança: inferido.

**Ausência.** O agente cadastra o período de ausência nas preferências; isso também pode ser feito por web service, em lote. Cada notificação tem uma opção de ser enviada ou não a agentes ausentes. A documentação avisa que a ausência é por data, o que pode adiantar ou atrasar o início em equipes de fusos diferentes.
- URLs: https://doc.znuny.org/znuny_lts/agentinterface/personalsettings/index.html, https://doc.znuny.org/znuny-7_0/admin/automation/ticket_notification/index.html
- Confiança: documentado. Se a ausência aparece na escolha de dono ou desbloqueia tickets, fica **A CONFIRMAR EM RUNTIME** (A-02).

**Agente inválido.** A documentação só diz que serve para tirar o acesso.
- URL: https://doc.znuny.org/znuny/admin/usermanagement/users/index.html
- **A CONFIRMAR EM RUNTIME** (A-05).

**Notificações.** O agente escolhe suas "minhas filas", e a notificação de ticket novo vai para quem assina a fila. Entre as padrão estão:
- Ticket novo.
- Desbloqueio por prazo.
- Ticket movido de fila ("outro time te passou um ticket").
- Follow-up em ticket bloqueado e em desbloqueado.
- Mudança de dono e de responsável.
- Lembrete de pendência.
- Escalonamento e aviso de escalonamento.
- Menção.

O Znuny também tem um papel de **responsável**, distinto do dono. As notificações têm filtros e podem ser obrigatórias ou opcionais para o agente.
- URLs: https://doc.znuny.org/znuny-7_0/admin/automation/ticket_notification/index.html, https://doc.znuny.org/znuny_lts/agentinterface/personalsettings/index.html
- Confiança: documentado.

### 2.6 UVdesk

**Estrutura.** **Grupos** classificam agentes por especialidade, e **times** são subgrupos dentro dos grupos. O agente é colocado em grupos e depois em times. Conversas podem ser roteadas para um time inteiro em vez de para uma pessoa.
- URLs: https://docs.uvdesk.com/uvdemo/users/groups.html, https://docs.uvdesk.com/uvdemo/users/teams.html, https://docs.uvdesk.com/uvdemo/users/agents.html
- Confiança: documentado.

**Atribuição.**
- Manual, controlada por privilégios: atribuir ao grupo é uma permissão específica.
- Os workflows (evento, condição, ação) e as "respostas preparadas" podem atribuir.
- Não há round-robin documentado.
- URLs: https://docs.uvdesk.com/uvdemo/users/privileges.html, https://docs.uvdesk.com/uvdemo/productivity/workflow.html, https://docs.uvdesk.com/uvdemo/productivity/prepared-response.html
- Confiança: documentado (manual, workflows); inferido (sem round-robin).

**Agente desativado.** Existe um status de conta ativo/inativo, mas o efeito sobre os tickets não é descrito.
- **A CONFIRMAR EM RUNTIME** (A-05).

### 2.7 Frappe Helpdesk

**Times.**
- Os agentes podem estar em vários times. Criar um time **gera automaticamente uma regra de atribuição** para ele, que é atualizada quando os membros mudam: atribuir o ticket ao time escolhe um membro.
- **Ao trocar o time do ticket, ele é reatribuído a um agente do novo time.**
- As regras têm uma condição opcional de "desatribuir": remove o dono quando o ticket muda de time, para que a regra do novo time o pegue.
- URLs: https://docs.frappe.io/helpdesk/lesson-3-agents-teams, https://frappe.io/helpdesk/assignment-rules
- Confiança: documentado. **A CONFIRMAR EM RUNTIME** (A-04).

**Regras de atribuição.**
- Dois métodos: **rodízio** ou **por carga**, que manda para quem tem menos tickets abertos.
- Cada regra tem condição de aplicação, lista de agentes, dias da semana e prioridade (vale a de maior prioridade quando várias casam).
- Lógica extra pode ser feita com scripts de servidor.
- URLs: https://frappe.io/helpdesk/assignment-rules, https://docs.frappe.io/helpdesk/lesson-3-agents-teams
- Confiança: documentado. **A CONFIRMAR EM RUNTIME** (A-02, A-03).

**Disponibilidade.**
- Uma página diz que há estados ativo, ausente e indisponível: os tickets vão primeiro para os ativos, depois para os ausentes, e **se todos estiverem indisponíveis o ticket é atribuído mesmo assim**, "para nunca ficar sem dono".
- O guia de configuração diz apenas que agentes ausentes são pulados.
- As duas descrições se contradizem.
- URLs: https://frappe.io/helpdesk/assignment-rules, https://frappe.io/helpdesk/setup-guide
- Confiança: documentado, com contradição. **A CONFIRMAR EM RUNTIME** (A-02).

**Visibilidade por time.**
- Uma opção restringe o agente aos tickets dos times de que faz parte.
- Uma subopção mantém tickets **sem time** visíveis para todos até que recebam time.
- Outra subopção restringe a **atribuição** a membros do time do ticket. Sem ela, mesmo com a visibilidade restrita, é possível atribuir a alguém de fora.
- URL: https://docs.frappe.io/helpdesk/settings
- Confiança: documentado.

**Notificações.** Os agentes atribuídos recebem e-mail quando o contato responde, e menções em comentário interno também geram e-mail. Notificação de ticket sem dono não é documentada.
- URLs: https://docs.frappe.io/helpdesk/email-notifications, https://docs.frappe.io/helpdesk/lesson-2understanding-ticket-view
- Confiança: documentado. **A CONFIRMAR EM RUNTIME** (A-01).

---

## 3. Tabela comparativa

| Aspecto | Zammad | Chatwoot (CE) | FreeScout | osTicket | Znuny | UVdesk | Frappe HD |
|---|---|---|---|---|---|---|---|
| Unidade de fila | Grupo (1 por ticket; aninhável, sem herança) | Caixa + time | Mailbox (+ time pago) | Departamento (hierárquico) + time | Fila ligada a grupo de permissão | Grupo → times | Time |
| Atribuição manual | ✔ | ✔ | ✔ | ✔ (permissões separadas) | ✔ (bloquear = dono) | ✔ (por privilégio) | ✔ |
| Autoatribuição implícita | quem abre um ticket sem dono vira dono (configurável) | — | — | quem responde vira dono (configurável) | abrir a resposta bloqueia | — | — |
| Round-robin | — | ✔ (padrão por caixa e time) | — | — | — | — | ✔ |
| Por carga / capacidade | — | só Enterprise | — | — | — | — | ✔ (menos abertos) |
| Habilidades | — (gatilhos) | — | — | — (tópicos e filtros) | — | — | — (scripts) |
| Justiça / janela | — | ✔ (máximo por janela) | — | — | — | — | — |
| Agente ausente | substituto recebe notificações; **não** bloqueia atribuição (inferido) | ocupado e offline pulados | módulo: impede atribuição manual; resposta do cliente limpa o dono | férias: some da atribuição e dos alertas | por notificação; prazo de desbloqueio | ? | ausente vai para o fim da fila ou é pulado (contraditório) |
| Volta automática à fila | prazo de inatividade do dono | — | ao responder um ausente (módulo) | — | prazo de desbloqueio (horário comercial) | — | — |
| Agente desativado / excluído | não loga; tickets ficam (dono?) | excluído: conversas ficam sem dono, sem redistribuição | API permite mapear novo dono | some das listas; tickets? | ? | ? | ? |
| Troca de grupo/time | ? | limpa o dono se ele não é membro e autoatribui | ? | alerta o dono atual e o destino | pode desbloquear | ? | reatribui no novo time (desatribuição configurável) |
| Reabertura | mantém o dono (ou limpa, por opção) | ? | ? | último que respondeu (ou desliga) | bloqueia para o último dono (opção) | ? | e-mail aos atribuídos |
| Aviso de sem dono | grade de notificação por grupo | aba "sem dono" | conversa nova (perfil) | alerta a membros e gerente se não autoatribuído | assinantes das "minhas filas" | workflow | ? |

---

## 4. Pontos A CONFIRMAR EM RUNTIME → cenários

| # | Dúvida | Projeto(s) | Cenário |
|---|---|---|---|
| 1 | Ticket novo sem dono: onde aparece, quem é notificado (agent1 e agent2 de "Suporte N1"? agent3 não?), por qual canal | todos | A-01 |
| 2 | Matriz exata de notificações do Zammad (evento × escopo) | Zammad | A-01 |
| 3 | Sequência de donos em 6 tickets; efeito de agent2 em offline, ocupado ou ausente | Chatwoot, Frappe | A-02 |
| 4 | Frappe: com todos indisponíveis, atribui mesmo assim ou fica sem dono? | Frappe | A-02 |
| 5 | Chatwoot: o agente fica offline sozinho ao fechar a aba? Ao estourar o limite por janela, a conversa fica sem dono? | Chatwoot | A-02 |
| 6 | Ausência no Zammad e no Znuny impede atribuir? O substituto vê o quê? | Zammad, Znuny | A-02 |
| 7 | Prazo de atribuição do Zammad (1 min no laboratório) e prazo de desbloqueio do Znuny: ticket volta para a fila? Quem é notificado? | Zammad, Znuny | A-02 (variante) |
| 8 | Critério "por carga" do Frappe: conta abertos de todos os estados não fechados? Por time ou global? | Frappe | A-03 |
| 9 | Transferir de "Suporte N1" para "Financeiro" com dono agent1 (que não é membro do destino): o dono é mantido ou limpo? Quem é notificado? | todos | A-04 |
| 10 | Desativar agent1 com tickets: o dono permanece? Os tickets aparecem como sem dono? Há aviso? | todos | A-05 |
| 11 | FreeScout: exclusão de usuário pela interface oferece escolha de novo dono? | FreeScout | A-05 |
| 12 | Reabertura de resolvido: o dono volta? (cruza com T-03) | Zammad, osTicket, Znuny, Chatwoot | A-04/T-03 |

---

## 5. Recomendação preliminar para o MVP (simples e correto)

**Escopo do MVP:** grupos, dono, atribuição manual e notificação de sem dono. O round-robin é opcional, mas barato; carga, capacidade e habilidades ficam no roadmap.

1. **Modelo de dados:**
   - O ticket tem `grupo` (obrigatório, exatamente um) e `dono` (opcional, um agente). O dono **precisa ter acesso ao grupo**; essa invariante é verificada no servidor.
   - Grupos planos no MVP. Hierarquia só no roadmap e, se vier, sem herança implícita (lição do Zammad).
   - Não adotar o "bloqueio" do Znuny como conceito separado. Dono mais indicador de presença (área 9) resolve com menos estados.
2. **Atribuição manual:**
   - Atribuir a si mesmo ("pegar"), atribuir a outro membro do grupo e devolver à fila.
   - Opção por grupo "responder atribui a quem respondeu, se estiver sem dono" (osTicket), ligada por padrão. É simples e evita tickets respondidos sem dono.
3. **Transferência de grupo** (regra explícita, documentada e testada):
   - Se o dono atual tem acesso ao grupo de destino, **mantém o dono**.
   - Se não tem, **limpa o dono**. Esse é o modelo Chatwoot; ele preserva a invariante.
   - Em qualquer caso, notificar o antigo dono e o grupo de destino (modelo osTicket).
   - Registrar a mudança no histórico.
4. **Reabertura:** mantém o dono anterior se ele ainda estiver ativo e tiver acesso; senão volta para a fila. Pode haver opção por grupo para sempre limpar.
5. **Agente desativado:**
   - Some das listas de atribuição.
   - Seus tickets **abertos voltam para a fila do grupo, sem dono**, com notificação ao grupo e registro no histórico.
   - A desativação mostra antes quantos tickets serão devolvidos, com opção de reatribuir em lote para outro agente, como faz a API do FreeScout. Nunca deixar ticket aberto com dono que não pode logar.
6. **Ausência (pode ficar para o MVP+1):**
   - Um indicador de "ausente até a data X" impede atribuição manual e automática (modelo osTicket de férias).
   - Opcionalmente, o ticket volta para a fila quando o cliente responde a um ticket de agente ausente (FreeScout).
   - Evitar o substituto silencioso do Zammad, que só redireciona notificações.
7. **Notificações de fila:**
   - Ticket novo sem dono notifica os membros do grupo.
   - Ticket atribuído notifica só o dono, e **não** os membros (regra osTicket que evita ruído).
   - Resposta do cliente notifica o dono; se não houver dono, notifica o grupo.
   - Preferência por usuário (in-app × e-mail) e por grupo. Visões padrão: "meus", "sem dono no meu grupo" e "todos do meu grupo".
8. **Round-robin (opcional no MVP, por grupo):**
   - Distribui só entre agentes ativos, não ausentes e "disponíveis".
   - Se ninguém estiver elegível, **fica sem dono** e notifica o grupo. Não forçar a atribuição como uma das versões da documentação do Frappe descreve.
   - Guardar o ponteiro de rodízio por grupo de forma transacional, para que tickets simultâneos não caiam no mesmo agente.
   - **Roadmap:** por carga, contando abertos não pendentes (Frappe); limite por janela (Chatwoot); capacidade; habilidades.
9. **Devolução por inatividade** (prazo do Zammad, desbloqueio do Znuny): roadmap, implementável como tarefa agendada da área de automações.
