# Área 6 — Permissões e multi-tenancy

Notas comportamentais do analista (clean-room). Fonte: **apenas documentação pública oficial**, reescrita com palavras
próprias (sem rótulos de interface, chaves de configuração, nomes internos de papéis/tabelas/classes).
Confiança: **documentado** (a página afirma) / **inferido** (dedução) / **A CONFIRMAR EM RUNTIME** (vira teste P-*).
Data: 2026-10-26. Peppermint excluído; nada do Zendesk consultado.

---

## 1. Problema

O helpdesk mistura três públicos com direitos muito diferentes sobre o mesmo ticket: administradores (configuram),
agentes (trabalham tickets de certos grupos/filas/departamentos) e solicitantes (veem só o que é seu, e às vezes o da
sua organização). Os riscos de segurança recorrentes são:

1. **Vazamento entre grupos**: agente de um grupo lê ticket de outro via API, busca, contagem, histórico do contato,
   anexos ou notificações.
2. **Vazamento de nota interna** ao solicitante (portal, API, e-mail de notificação, citação em resposta).
3. **Visibilidade por organização** mal definida (colega vê ticket sensível do outro).
4. **Tokens de API** que herdam mais poder do que o necessário.
5. **Isolamento multiempresa/multimarca**: o que é compartilhado (contatos, base de conhecimento, configurações) entre
   caixas/marcas/contas.

---

## 2. Comportamento documentado por projeto

### 2.1 Zammad

- Três papéis de fábrica (admin, agente, cliente), editáveis; papéis customizados ilimitados; papéis não são excluídos,
  só desativados (desativar retira as permissões de quem o tem). Usuário pode ter vários papéis; permissões somam. — https://admin-docs.zammad.org/en/latest/manage/roles/index.html — documentado
- Permissões são **chaves de funcionalidade hierárquicas** (marcar o pai concede os filhos): administração por área,
  trabalho em tickets como agente, chat, telefonia, base de conhecimento (leitor/editor), relatórios, preferências
  do usuário, ser cliente de ticket. **Permissões de administração não dão acesso a tickets**; é preciso a de agente
  também. Algumas são perigosas (exclusão de dados, gestão de usuários permite sequestrar sessão). — https://admin-docs.zammad.org/en/latest/manage/roles/permissions.html — documentado
- **Nível por grupo** (só para agentes): ler (ver/buscar), criar (criar e mover para o grupo), alterar, visão geral
  (ver em listas sem abrir detalhes) e completo (tudo + pode ser dono + recebe notificações). Atribuível por papel ou
  por usuário (doc recomenda escolher um só método). Quem só tem "criar" deixa de ver o ticket após salvar. — https://admin-docs.zammad.org/en/latest/manage/groups/group-permissions.html — documentado
- Como se combinam permissão de grupo via papel e via usuário: não documentado. — A CONFIRMAR EM RUNTIME (P-04)
- Agente que também é cliente e não tem leitura no grupo do ticket vê a **visão reduzida de cliente**. — https://admin-docs.zammad.org/en/latest/manage/roles/index.html — documentado
- **Organização compartilhada**: membros veem **e atualizam** tickets dos colegas; doc alerta para o risco com
  departamentos sensíveis. Atribuição automática à organização por domínio de e-mail (um domínio por organização;
  não usar domínios gratuitos). Flag VIP utilizável em regras. — https://admin-docs.zammad.org/en/latest/manage/organizations/index.html — documentado
- **Notas internas**: visibilidade é atributo de cada artigo (interno/público); padrão das notas configurável, e pode-se
  exigir confirmação ao tornar um artigo público. — https://admin-docs.zammad.org/en/latest/misc/composer.html — documentado
  (que o cliente nunca vê o interno por portal/API: inferido — A CONFIRMAR, P-03)
- **Tokens de API**: criados pelo próprio usuário (exige permissão para isso); **nunca têm mais permissões que o
  criador**; recomenda-se um token por aplicação. — https://admin-docs.zammad.org/en/latest/manage/roles/permissions.html e https://user-docs.zammad.org/en/latest/extras/user-menu-profile-settings.html — documentado
- Se o token permite escolher subconjunto de permissões e validade: não confirmado na doc lida. — A CONFIRMAR (P-05)
- API aceita autenticação básica (desaconselhada, pode ser desligada), token e OAuth2; um administrador de usuários pode
  **agir em nome de outro usuário** via cabeçalho de requisição. — https://docs.zammad.org/en/latest/api/intro.html — documentado
- Multi-tenancy: **instância única**; separação por grupos (cada grupo com endereço de e-mail/assinatura). Não há
  conceito de marca/conta isolada documentado. — inferido — A CONFIRMAR (P-06)

### 2.2 Chatwoot (edição comunitária)

- **Contas**: uma instalação hospeda várias contas (workspaces) com caixas, agentes, contatos, conversas e configurações
  próprias — é o modelo de tenancy. Super administrador da instalação gerencia contas por um console separado. — https://www.chatwoot.com/hc/user-guide/articles/1677141565-chatwoot-glossary e https://developers.chatwoot.com/self-hosted/monitoring/super-admin-sidekiq — documentado
- Usuário em várias contas e troca entre elas: não confirmado. — A CONFIRMAR (P-06)
- Papéis de fábrica: **administrador** (tudo na conta) e **agente** (atende conversas das caixas de que é membro). Só
  membros de uma caixa veem/respondem conversas dela; entrar na conta não dá acesso a todas as caixas. — https://www.chatwoot.com/hc/user-guide/articles/1677482414-adding-agents — documentado
- Times dão acesso a conversas? Blog antigo fala em mover acesso para times; não confirmado. — https://www.chatwoot.com/blog/team-permissions — A CONFIRMAR (P-01)
- **Papéis customizados** (todas as conversas / não atribuídas + próprias / só participando / contatos / relatórios /
  base de conhecimento) = **enterprise/pago** → só catálogo. — https://www.chatwoot.com/features/roles-permissions — documentado (como pago)
- **Notas privadas**: só para uso interno da equipe na janela da conversa. — glossário — documentado (não aparecer no
  widget/API cliente: A CONFIRMAR, P-03)
- Cliente não tem portal de "meus tickets"; contato fala por widget/canal. Visibilidade por organização (empresa do
  contato) não documentada. — inferido — P-02 provavelmente N/A
- **API**: três famílias — de aplicação (token pessoal do usuário, mesmas permissões do usuário, sem escopos), de
  cliente (identificadores de caixa e de contato, sem token), de plataforma (só auto-hospedado; token de "app de
  plataforma" criado no console do super admin, que **só alcança objetos que ele criou ou que lhe foram concedidos**).
  Bots têm token próprio. — https://developers.chatwoot.com/api-reference/introduction e https://developers.chatwoot.com/contributing-guide/chatwoot-apis — documentado

### 2.3 FreeScout (núcleo)

- Dois papéis: **administrador** (acessa todas as caixas, recebe notificações de todas) e **usuário**; usuário acessa
  as caixas que lhe forem concedidas. Departamentos são modelados como caixas. — https://github.com/freescout-help-desk/freescout/wiki/FAQ — documentado
- Por caixa há uma página de permissões (ex.: esconder administradores da lista de atribuição). — mesma URL — documentado
  (granularidade exata por caixa — editar configurações, auto-resposta, assinatura: A CONFIRMAR, P-04)
- Opção por usuário não admin: **ver só conversas atribuídas a ele** (sem ver não atribuídas; contadores só corretos
  na pasta "minhas"). Mesmo assim **vê todos os clientes**. — mesma URL — documentado
- **Clientes são uma tabela única compartilhada por todas as caixas**; há opção de ocultar clientes de não admins (pode
  deixar buscas lentas). — mesma URL — documentado. Consequência: não há isolamento real de contatos entre caixas/marcas.
- Correções de segurança recentes nas notas de versão tratam vazamento de "conversas anteriores" para usuários
  restritos a atribuídas — sinal de que esse é um ponto frágil. — https://github.com/freescout-help-desk/freescout/releases — inferido — P-01
- Notas internas: existem; visibilidade não documentada no FAQ. — A CONFIRMAR (P-03)
- Portal do cliente e API/webhooks: **módulos pagos** (catálogo). — https://github.com/freescout-help-desk/freescout/wiki/FAQ — documentado (catálogo); P-02/P-05 N/A no núcleo

### 2.4 osTicket

- Agente tem **departamento primário + papel primário**, e **acesso estendido** a outros departamentos com **papel
  diferente por departamento**. — https://docs.osticket.com/en/latest/Admin/Agents/Agents.html — documentado
- Papéis = conjunto de permissões **por departamento**: tickets (atribuir, fechar, criar, excluir, editar, editar
  conversa, vincular, marcar respondido, mesclar, responder, encaminhar/referir, liberar, transferir), tarefas
  (análogas), respostas prontas. — https://docs.osticket.com/en/latest/Admin/Agents/Roles.html — documentado
- Permissões fora de departamento ficam no agente: diretório de usuários, organizações, base de conhecimento, lista de
  bloqueio, busca em todos os tickets, ver estatísticas de colegas, ver metadados de tickets sem acesso. — mesma URL e Agents — documentado
- Opção **limitar a tickets atribuídos** (ao agente ou ao seu time), independentemente do departamento; ao fechar, a
  atribuição é liberada e o agente perde acesso. — https://docs.osticket.com/en/latest/Admin/Agents/Agents.html — documentado
- Papel de fallback para quem recebe ticket por atribuição/referência sem ter acesso ao departamento; sem ele, só
  visualização + nota interna. — mesma URL — documentado
- Departamentos aninhados: acesso ao pai dá acesso aos filhos, não o contrário. — https://docs.osticket.com/en/latest/Admin/Agents/Departments.html — documentado
- Administrador = flag que dá acesso ao painel de administração. — Agents — documentado
- **Organização**: contatos primários podem ser colaboradores automáticos em todos os tickets da organização (ou todos
  os membros), e assim veem esses tickets no portal; adesão automática por domínio. Configuração global define se o
  usuário vê no portal **todos os tickets em que participa** ou só os próprios (padrão: todos em que participa). — https://docs.osticket.com/en/latest/Agent/Users/Organizations.html e https://docs.osticket.com/en/latest/Features/Collaborators.html — documentado
- Notas internas: visíveis só a agentes. — inferido — A CONFIRMAR (P-03)
- **Chaves de API**: vinculadas a **um endereço IP**; permissões só de **criar tickets** e **executar cron**. — https://docs.osticket.com/en/latest/Admin/Manage/API%20Keys.html — documentado. Não há API de leitura de tickets no núcleo → P-05 parcialmente N/A.
- Multi-tenancy: instância única; separação por departamentos + endereços de e-mail + tópicos. — inferido (P-06)

### 2.5 Znuny

- Modelo **grupos (recursos) × papéis (pacotes de permissões)**: cada fila pertence a **um** grupo; agentes recebem
  permissões no grupo diretamente ou via papel (recomendado). — https://doc.znuny.org/znuny/admin/usermanagement/index.html e https://doc.znuny.org/znuny-7_2/concepts/groups/index.html — documentado
- Permissões por grupo granulares (só leitura, mover para, criar, nota, dono, prioridade, leitura-escrita); o conjunto é
  extensível; leitura-escrita **não** equivale a administração — vale só para os objetos do grupo. — https://doc.znuny.org/legacy/manual/admin/6.0/en/html/administration.html e grupos 7.2 — documentado
- Para ser dono, precisa da permissão de dono (ou escrita) na fila; a lista de donos só mostra quem a tem. — https://doc.znuny.org/znuny/concepts/owner/index.html — documentado
- É possível conceder administração parcial (só alguns módulos de admin). — https://doc.znuny.org/znuny/admin/miniadmin/index.html — documentado
- **Clientes**: usuário-cliente pertence a uma empresa; por padrão vê os tickets **da própria empresa**; há opção para
  negar acesso a tickets da empresa que ele não criou; pode ser ligado a **várias empresas** (consultores). Grupos de
  cliente: acesso exige que a permissão de grupo **e** a relação empresa/usuário sejam satisfeitas; contexto "mesma
  empresa" ou "outras empresas". Criação permitida nas filas com escrita no grupo, salvo ACL. — https://doc.znuny.org/znuny/concepts/customers/index.html e https://doc.znuny.org/znuny/admin/usermanagement/customer_user_customer/index.html — documentado
- ACLs permitem restringir opções por contexto. — mesma fonte — documentado (detalhe: A CONFIRMAR, P-04)
- Notas internas: artigos têm flag de visibilidade ao cliente. — inferido — A CONFIRMAR (P-03)
- API: interface genérica de webservices autenticada com credenciais de agente ou cliente (permissões do usuário);
  escopos de token não documentados. — inferido — A CONFIRMAR (P-05)
- Multi-tenancy: instância única; separação por filas/grupos, endereços de sistema por fila, multiempresa do lado
  do cliente. — inferido (P-06)

### 2.6 UVdesk (OSS)

- Papéis: dono/administrador, agente, cliente. Agente recebe um **privilégio** nomeado (conjunto de permissões de
  ticket — criar, excluir, editar, atribuir grupo, mudar prioridade — e avançadas) que também define quais módulos
  aparecem. — https://docs.uvdesk.com/uvdemo/users/privileges.html — documentado
- **Escopo de visão de tickets** por agente: global, grupo, time ou individual (só atribuídos). — https://docs.uvdesk.com/uvdemo/users/agents.html e https://www.uvdesk.com/en/api-doc/ — documentado
- Grupos e times atribuídos na ficha do agente. — mesmas URLs — documentado
- Organização do cliente e visibilidade compartilhada: não documentado. — A CONFIRMAR (P-02)
- Notas internas e API (tokens): existem tokens de API; escopos não documentados. — A CONFIRMAR (P-03, P-05)
- Multicaixa: várias caixas de e-mail ilimitadas na edição open source; isolamento de marcas não documentado. — https://www.uvdesk.com/en/feature-compare/ — documentado (caixas) / P-06

### 2.7 Frappe Helpdesk

- Papéis do produto: administrador, gestor de agentes, agente (nomes variam entre páginas da doc). Gestor altera times,
  SLAs e regras de atribuição. — https://docs.frappe.io/helpdesk/lesson-3-agents-teams e https://docs.frappe.io/helpdesk/your-first-steps-with-frappe-helpdesk — documentado
- **Restrição por time** (opcional): ticket visível só aos membros do time atribuído; opção complementar mantém não
  atribuídos visíveis a todos; e opção de restringir atribuição a agentes do time (requer a primeira). — https://docs.frappe.io/helpdesk/settings — documentado
- Base do framework: permissões **por tipo de documento × papel** (ler, escrever, criar, excluir, relatório, exportar,
  importar, imprimir, e-mail, compartilhar), regra "só se for o criador", **níveis de permissão por campo**, e
  **permissões de usuário** que filtram registros pelo valor de um vínculo. — https://docs.frappe.io/framework/user/en/basics/users-and-permissions — documentado
  (como o Helpdesk combina isso com a restrição por time na API REST genérica: A CONFIRMAR, P-01)
- **Clientes**: contato comum só cria e gerencia os próprios tickets; um **gestor do cliente** vê todos os tickets da
  organização e pode promover outros; o contato primário é sempre gestor. — https://docs.frappe.io/helpdesk/customers-contacts — documentado
  (se o portal mostra os tickets da organização ao gestor: A CONFIRMAR, P-02)
- Portal do cliente para abrir e acompanhar tickets. — https://docs.frappe.io/helpdesk/customer-portal — documentado
- **API**: par chave+segredo gerado por usuário; toda requisição é registrada e autorizada **como aquele usuário**;
  recomenda-se usuário dedicado; OAuth com bearer token; escopos não descritos. — https://docs.frappe.io/framework/user/en/api/rest — documentado
- Multi-tenancy: o framework suporta vários sites por instalação (bancos separados) — isolamento por site. — inferido — A CONFIRMAR (P-06)

---

## 3. Tabela comparativa

| Aspecto | Zammad | Chatwoot CE | FreeScout | osTicket | Znuny | UVdesk | Frappe HD |
|---|---|---|---|---|---|---|---|
| Papéis de fábrica | admin/agente/cliente | admin/agente | admin/usuário | agente (+flag admin)/usuário | agente/cliente (+admin por grupo) | admin/agente/cliente | admin/gestor/agente/contato |
| Papéis customizados | sim | pago | não | sim (por depto) | sim (papéis + grupos) | sim (privilégios) | sim (framework) |
| Unidade de escopo do agente | grupo | caixa (inbox) | caixa | departamento | fila→grupo | global/grupo/time/individual | time (opcional) |
| Granularidade por escopo | ler/criar/alterar/visão/completo | membro sim/não | acesso + opções por caixa | papel por departamento | ro/mover/criar/nota/dono/prioridade/rw | privilégio global + escopo | doctype×papel + filtro |
| "Só atribuídos" | via níveis | pago | sim (por usuário) | sim (por agente) | via ACL? | individual | não documentado |
| Cliente vê tickets da organização | opcional (e altera!) | n/a | n/a (portal pago) | via colaboração automática | padrão sim (desligável); multiempresa | não doc. | só gestor do cliente |
| Nota interna | flag por artigo | nota privada | nota | nota interna | flag de visibilidade | nota | comentário interno |
| Token de API | por usuário, ≤ permissões do criador | por usuário (sem escopo); plataforma restrita ao que criou | pago | por IP; criar ticket/cron | credenciais de usuário | token | chave+segredo do usuário |
| Personificação via API | sim (admin de usuários) | — | — | — | — | — | — |
| Tenancy | instância única | **várias contas por instalação** | instância; clientes compartilhados | instância | instância; multiempresa no cliente | instância; várias caixas | vários sites (framework) |

---

## 4. A CONFIRMAR EM RUNTIME (mapa para cenários)

| ID | Pergunta | Projetos |
|---|---|---|
| P-01 | agent3 abrindo ticket de outro grupo: status HTTP (403 vs 404), se vaza título/contagem em busca, listas, histórico do contato, anexo por URL direta, notificação. FreeScout "só atribuídos" + conversas anteriores; Frappe REST genérica com restrição por time; Chatwoot com times | todos |
| P-02 | customer2 vê tickets de customer1 na mesma organização? Zammad (organização compartilhada permite **alterar**), osTicket (colaboração automática), Znuny (padrão empresa), Frappe (só gestor). manager1 como gestor | Zammad, osTicket, Znuny, Frappe, UVdesk |
| P-03 | Nota interna nunca aparece: portal, API do cliente, e-mails de notificação, citação na próxima resposta, exportação, webhook para o cliente | todos |
| P-04 | Papel customizado parcial: combinação papel+usuário no Zammad (união?), ACL no Znuny, papel por departamento no osTicket, privilégio no UVdesk, páginas de permissão por caixa no FreeScout | Zammad, Znuny, osTicket, UVdesk, FreeScout, Frappe |
| P-05 | Escopos: Zammad (seleção de permissões e validade no token?), Chatwoot (token pessoal sem escopo; plataforma limitada), osTicket (IP + criar/cron), Frappe (herda papéis), Znuny (credenciais) | todos |
| P-06 | Inventário: Chatwoot contas (usuário em várias contas? dados cruzam?), FreeScout clientes compartilhados entre caixas, Znuny multiempresa do cliente, Frappe multi-site | todos |

---

## 5. Recomendação preliminar para o MVP (simples e correto)

1. **Três papéis fixos**: administrador (configura tudo **e** vê todos os tickets), agente, solicitante. Sem papéis
   customizados no MVP, mas modelar as verificações como permissões nomeadas internas para permitir papéis depois.
2. **Escopo do agente por grupo** com dois níveis apenas: *ler* e *trabalhar* (trabalhar = alterar, responder, ser dono).
   Agente sem acesso ao grupo recebe **404** (não 403) para não confirmar existência; o mesmo filtro de escopo aplicado
   em uma única camada (consulta) para lista, busca, contadores, anexos, histórico do contato, exportação e webhooks.
   Mover para grupo sem acesso de leitura é permitido só a quem tem "trabalhar" no grupo de destino.
3. **Notas internas**: tipo de mensagem separado (não um flag que pode ser alternado por engano); nunca serializado em
   nenhuma visão de solicitante, e-mail de saída, citação de resposta ou payload destinado ao cliente — com teste
   automatizado de "nota nunca vaza" em cada endpoint de solicitante.
4. **Organização**: solicitante vê só os próprios tickets; um flag por organização "membros veem tickets da organização"
   (**somente leitura**, diferente do Zammad que permite alterar) e/ou papel de gestor da organização (modelo Frappe).
   Sem adesão automática por domínio no MVP (ou só com domínios explicitamente cadastrados, nunca gratuitos).
5. **Tokens de API**: por usuário, nunca acima das permissões do dono, com escopo simples (leitura / leitura+escrita),
   validade opcional, revogáveis, último uso registrado. Sem personificação no MVP.
6. **Tenancy**: instância de **uma empresa**, mas com *tenant_id* em todas as entidades desde o início (contatos
   inclusive — evitar o modelo FreeScout de clientes compartilhados), permitindo evoluir para o modelo de contas do
   Chatwoot sem migração dolorosa. Múltiplas caixas de e-mail mapeadas para grupos.
