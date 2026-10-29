# Área 7 — Base de conhecimento e portal do cliente

> Pesquisa clean-room: apenas documentação pública oficial. Nenhum código-fonte foi
> lido. Todo o texto abaixo está em palavras próprias; nada de strings de interface,
> chaves de configuração, nomes de tabela ou de classe.
> Confiança: **documentado** = a página citada afirma o comportamento;
> **inferido** = dedução a partir da página (ou da ausência de informação), precisa
> de confirmação. Pesquisa feita em 2026-10-26.

## 1. Problema

O PantherDesk precisa, no MVP, de:

- uma base de conhecimento (KB) básica: organização em categorias, artigos com
  ciclo de vida (rascunho → publicado → arquivado), separação entre conteúdo
  público e interno;
- um portal do cliente onde o solicitante se autentica, abre ticket, acompanha o
  histórico, responde e (se for gestor) vê os tickets da organização;
- idealmente, alguma deflexão: sugerir artigos antes de o cliente abrir um ticket.

As perguntas de projeto são: quantos níveis de hierarquia? quais estados de
artigo? como funciona a visibilidade (por artigo, por categoria, por papel)?
multi-idioma no MVP ou roadmap? login por senha ou link mágico? como o portal
trata tickets da organização e notas internas?

## 2. Comportamento documentado por projeto

### 2.1 Zammad

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Estrutura | Categorias e "respostas" (artigos). Categorias aceitam subcategorias; cada categoria tem ícone. Mover uma categoria leva junto subcategorias e artigos. Só dá para apagar categoria vazia. | https://admin-docs.zammad.org/en/latest/manage/knowledge-base.html ; https://user-docs.zammad.org/en/latest/extras/knowledge-base.html | documentado |
| Estados / visibilidade | Público (todos), interno (agentes e editores), rascunho, agendado e arquivado (só editores). Publicação agendada existe. A documentação de admin cita só rascunho/interno/público; a de usuário acrescenta agendado e arquivado. | mesmas URLs | documentado |
| Versões | Nenhuma menção a histórico de versões de artigo. | mesmas URLs | inferido (não há) — A CONFIRMAR |
| Permissões | Dois níveis globais (leitor, editor); por padrão só admin edita. Permissão por categoria, herdada pelas subcategorias; nas filhas só é possível restringir mais, nunca afrouxar. Aviso: permissão de leitura expõe conteúdo interno. | mesmas URLs | documentado |
| Multi-idioma | Admin escolhe os idiomas e um idioma padrão. Visitante vê o idioma do seu locale, ou o padrão. Artigo sem tradução no idioma escolhido fica oculto para leitores; o editor vê aviso de tradução faltante. | mesmas URLs | documentado |
| Busca na KB | Texto completo sobre título e corpo em todos os idiomas. No editor de resposta do ticket há um atalho para buscar e inserir o artigo na posição do cursor (não substitui o texto). | user-docs acima | documentado |
| Vínculo KB↔ticket | Artigo pode listar tickets relacionados (visível só a editores/preview). Links internos estilo wiki entre artigos e tickets. | user-docs acima | documentado |
| URL / tema | Publicada num caminho fixo do domínio do Zammad; domínio próprio possível em auto-hospedagem. Feeds RSS públicos e internos (o interno leva token pessoal). | admin-docs acima | documentado |
| Deflexão | Não há menção a sugestão automática de artigos ao cliente abrindo ticket. | — | inferido (não há) — A CONFIRMAR |
| Portal: cadastro/login | Auto-cadastro de cliente, recuperação de senha e login por senha são opções ligadas por padrão. Desligar auto-cadastro não impede a criação automática de conta quando chega e-mail. Login por terceiros configurável. Sem link mágico documentado. | https://admin-docs.zammad.org/en/latest/settings/security/base.html | documentado |
| Portal: abrir ticket | Cliente pode criar ticket pela interface web (ligado por padrão); admin pode restringir os grupos oferecidos (se só um, o campo some). Desligar criação não impede atualizar tickets existentes. | https://admin-docs.zammad.org/en/latest/channels/web.html | documentado |
| Portal: organização | Organização "compartilhada": todos os membros veem **e atualizam** os tickets dos colegas. Atribuição automática à organização pelo domínio do e-mail (opcional, um domínio por organização). | https://admin-docs.zammad.org/en/latest/manage/organizations/index.html | documentado |
| Portal: listas | Visões (overviews) também se aplicam a papéis de cliente, com opção de mostrar todos os tickets da organização compartilhada. | https://admin-docs.zammad.org/en/latest/manage/overviews.html | documentado |
| Portal: notas internas | Não lido explicitamente nesta pesquisa. | — | A CONFIRMAR (P-03) |

### 2.2 Chatwoot (edição comunitária)

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Modelo | "Help Center" com **portais** (um por marca/produto), cada portal com categorias e artigos; domínio próprio com SSL por portal. | https://www.chatwoot.com/hc/user-guide/articles/1677861202-how-to-setup-a-help-center ; https://chatwoot.com/features/help-center | documentado |
| Estados | Rascunho, publicado e arquivado (o glossário descreve arquivado como "não publicado, mantido no painel"). | https://www.chatwoot.com/docs/user-guide/getting-started/glossary (via busca) | documentado (parcial) |
| Autor / SEO | Autor escolhido entre os agentes; metadados de SEO por artigo. | glossário; features/help-center | documentado |
| Interno vs público | Não há conceito documentado de artigo interno — o Help Center é público por natureza. | — | inferido |
| Multi-idioma | "Locales" anunciados como funcionalidade; detalhes de configuração não encontrados na doc oficial. | https://chatwoot.com/features/help-center | documentado (existência) / A CONFIRMAR (comportamento) |
| Busca | Busca de artigos no widget e no portal. A página de produto fala de busca com IA e citações — provavelmente recurso pago (Captain). | features/help-center | documentado (existência); edição A CONFIRMAR |
| Deflexão | O widget pode mostrar artigos populares antes de o visitante iniciar a conversa; o portal é vinculado à caixa de chat ao vivo nas configurações da caixa. | https://www.chatwoot.com/hc/user-guide/articles/1757446321-how-to-embed-your-help-center-articles-in-the-live-chat-widget ; features/help-center | documentado |
| Edição | Não está claro na documentação se o Help Center é da edição comunitária (MIT) ou só paga. | https://developers.chatwoot.com/self-hosted/enterprise-edition | A CONFIRMAR EM RUNTIME |
| Portal de tickets | Chatwoot não tem portal de tickets com login; o cliente interage pelo widget/canais. | — | inferido (N/A para K-03) |

### 2.3 FreeScout

Núcleo **não** tem KB nem portal; ambos são módulos pagos (catálogo).

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| KB (módulo pago) | Uma KB por caixa de correio. Categorias e artigos; categoria com um único artigo abre o artigo direto. Categorias e artigos traduzíveis. Categorias podem ser restritas a agentes logados, ou a clientes que tenham tickets. Widget embutível (oculta categorias só-agente). Agente insere link de artigo na resposta. | https://freescout.net/module/knowledge-base/ | documentado |
| KB: estados/versões/busca/deflexão | Não mencionados na página do módulo. | idem | A CONFIRMAR |
| Portal (módulo pago) | Login **sem senha**: cliente informa o e-mail e recebe link de acesso válido por uma hora; se o cliente não existir, é criado. Formulário de envio cria ticket direto no banco (sem e-mail ao cliente); agentes só são avisados se tiverem ativado a notificação de nova conversa. Cliente vê a lista e o histórico, responde; resposta em ticket fechado reabre. Respostas do agente vão por e-mail e aparecem no portal. Login na KB vale para o portal (exceto domínio próprio). | https://freescout.net/module/end-user-portal/ | documentado |
| Portal: organização | Não mencionado. | idem | A CONFIRMAR |
| FAQ oficial | Clientes criam conversas pelo módulo de portal; o mesmo módulo oferece formulário de contato para o site. | https://github.com/freescout-help-desk/freescout/wiki/FAQ | documentado |

### 2.4 osTicket

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Estrutura | Categorias (com aninhamento pai/filho) e FAQs. Contagem da categoria-pai inclui as FAQs das filhas. | https://docs.osticket.com/en/latest/Features/Nested%20Knowledgebase%20Categories.html | documentado |
| Visibilidade | Categoria precisa ser pública para aparecer no portal; FAQ também precisa ser pública. A KB só aparece ao cliente se houver ao menos uma FAQ numa categoria pública. FAQ interna = só equipe. | idem | documentado |
| Configurações | Ligar a KB; exigir login do cliente para ler; permitir respostas prontas aos agentes. | https://docs.osticket.com/en/latest/Admin/Settings/Knowledgebase.html | documentado |
| Multi-idioma | Categorias e FAQs traduzíveis por idioma (bandeira por idioma no painel do agente). Como o cliente vê a versão traduzida não está explicado. | https://docs.osticket.com/en/latest/Guides/Translation%20Guide.html | documentado / A CONFIRMAR (K-05) |
| Estados/versões | Só "público/interno"; sem rascunho nem histórico de versões documentados. | — | inferido |
| Leitura anônima | Artigos podem ficar na página inicial para anônimos, ou exigir login. | https://docs.osticket.com/en/latest/User/Knowledgebase/Knowledgebase.html | documentado |
| Busca/deflexão | Não documentadas. | — | A CONFIRMAR (K-02, K-04) |
| Portal: abrir ticket | Formulário com dados de contato, tópico de ajuda, resumo e corpo rico; tela de confirmação. | https://docs.osticket.com/en/latest/User/Ticket/Open%20A%20Ticket.html | documentado |
| Portal: acesso | Dois modos: (a) convidado — informa e-mail + número do ticket e recebe por e-mail um link que abre **só aquele ticket**; (b) usuário registrado (confirmação por e-mail, senha) vê todos os seus tickets. Registro pode ser exigido para abrir tickets. | https://docs.osticket.com/en/latest/User/Ticket/Check%20Ticket%20Status.html ; https://docs.osticket.com/en/latest/Admin/Settings/Users.html | documentado |
| Portal: organização | Contatos primários da organização podem ser adicionados automaticamente como colaboradores em todos os tickets da organização; colaboradores veem esses tickets no portal. Usuários entram na organização por domínio de e-mail. | https://docs.osticket.com/en/latest/Agent/Users/Organizations.html | documentado |

### 2.5 Znuny

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| KB | FAQ é pacote adicional (gratuito), instalado pelo gerenciador de pacotes; não faz parte do núcleo. | https://www.znuny.org/en/blog/znuny-7-preview-update (via busca) ; https://doc.znuny.org/legacy/manual/admin/6.0/en/html/public-interface.html | documentado |
| Audiências | Três níveis por item: interno (só agentes), externo (agentes + clientes logados), público (inclusive interface pública anônima). | https://www.znuny.com/blog/reduce-ticket-volume-with-targeted-knowledge | documentado |
| Permissão por categoria | Grupos de cliente podem liberar categorias específicas (exige ligar suporte a grupos de cliente, que passa a valer também para filas). | idem | documentado |
| Interface pública | Acesso anônimo para pesquisar FAQ sem autorização. | legacy public-interface | documentado |
| Aprovação / estados / idiomas / deflexão | Não encontrados na doc atual do Znuny. (Há relatos em fórum sobre fluxo de aprovação — fonte não oficial, não usada.) | — | A CONFIRMAR (K-01, K-04, K-05) |
| Portal: login | Página de login, recuperação automática de senha, auto-registro do cliente. | https://doc.znuny.org/znuny/customerinterface/index.html | documentado |
| Portal: funções | Criar ticket, "meus tickets", "tickets da empresa", busca de tickets (com modelos salvos e exportação), iniciar processos. | idem ; https://doc.znuny.org/znuny/customerinterface/searching_tickets/index.html | documentado |
| Portal: ticket | Cliente vê dados básicos e campos dinâmicos conforme configuração; pode responder, navegar artigos, anexar e, se permitido, mudar o estado; pode reabrir. | https://doc.znuny.org/znuny/customerinterface/viewing_tickets/index.html | documentado |

### 2.6 UVdesk (Community)

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Estrutura | Três níveis: pasta → categoria → artigo. | https://docs.uvdesk.com/uvdemo/knowledgebase/folder.html | documentado |
| Estados | Pasta e categoria: publicado ou rascunho; só publicados aparecem no front. Artigo publicado aparece no front. | folder.html ; https://docs.uvdesk.com/uvdemo/knowledgebase/category.html ; https://docs.uvdesk.com/uvdemo/knowledgebase/article.html | documentado |
| Versões | Revisões salvas com data/hora; é possível restaurar uma versão anterior. | article.html | documentado |
| Outros campos | Slug e metadados de SEO; artigos relacionados; ordem de exibição de categoria. | article.html ; category.html | documentado |
| Interno vs público | Não documentado. | — | A CONFIRMAR |
| Multi-idioma / busca / deflexão | Não documentados. | — | A CONFIRMAR |
| Portal | Fornecido por um pacote de "support center" que adiciona portal do cliente (login, acompanhar tickets) e KB. Detalhes de login não documentados em docs.uvdesk.com. | https://packagist.org/packages/uvdesk/support-center-bundle (descrição do pacote) | inferido |
| Contas de cliente | Criadas automaticamente no primeiro e-mail; ou manualmente pelo agente. | https://docs.uvdesk.com/uvdemo/users/customers.html | documentado |

### 2.7 Frappe Helpdesk

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Estrutura | Categorias planas (sem subcategorias documentadas); cada artigo em exatamente uma categoria; categoria padrão "geral" que não pode ser renomeada/apagada. Excertos automáticos do 1º parágrafo (cortado). Índice "nesta página" a partir dos títulos. | https://docs.frappe.io/helpdesk/knowledge-base | documentado |
| Estados | Rascunho (só agentes), publicado, arquivado (comportamento não explicado). | idem | documentado / A CONFIRMAR (arquivado) |
| Visibilidade | Por artigo: público, só clientes logados, privado (só agentes). Categoria não tem acesso próprio, mas alterar o acesso da categoria aplica a todos os artigos. Mover artigo nunca amplia o acesso (vale o mais restrito). KB pública para anônimos só se ligada nas configurações. | idem ; https://frappe.io/helpdesk/customer-self-service | documentado |
| Operações | Mover artigo; mesclar categoria (irreversível, apaga a origem); apagar categoria move artigos para a padrão. | knowledge-base | documentado |
| Feedback / views | Voto "útil / não útil" por artigo; contagem de visualização (uma por leitor por artigo por hora; anônimo por IP; rascunho não conta). | knowledge-base | documentado |
| Busca | Busca no portal e sugestões **dependem de RediSearch** no Redis de cache; sem ele, não retornam nada. | knowledge-base | documentado |
| Deflexão | Ao digitar o assunto do novo ticket, artigos relacionados são sugeridos; "ajuda relacionada" na página do ticket. KB pode ser a página inicial do portal. | knowledge-base ; customer-self-service ; https://docs.frappe.io/helpdesk/lesson-4-knowledge-base | documentado |
| Multi-idioma | Não mencionado. | — | inferido (não há) |
| Portal: acesso | Contato convidado pelo agente recebe e-mail para definir senha; ao logar vai direto para o portal. Auto-cadastro pode ser desligado. Método de login além de senha não documentado. | https://docs.frappe.io/helpdesk/customers-contacts.md (via busca) ; customer-self-service | documentado / A CONFIRMAR |
| Portal: tickets | Cria ticket com assunto, descrição, anexos e campos extras; vê estado, equipe, prioridade e uma linha do tempo (recebido, atribuído, 1ª resposta, prazo); responde (layout de linha do tempo ou chat). Cliente pode salvar visões privadas. | customer-self-service ; https://docs.frappe.io/helpdesk/custom-views | documentado |
| Portal: organização | Contato comum vê só os próprios tickets; contato gestor vê todos da empresa. Uma página de produto diz que o cliente vê tickets de todas as organizações às quais pertence e pode filtrar por elas — divergência com a doc. | https://docs.frappe.io/helpdesk/customer ; https://frappe.io/helpdesk/customer-management ; customer-self-service | documentado, com conflito → A CONFIRMAR (P-02) |
| Fechar/avaliar | Mirror não oficial fala em fechar e avaliar pelo portal; doc oficial não confirma. | — | A CONFIRMAR |

## 3. Tabela comparativa

| Aspecto | Zammad | Chatwoot CE | FreeScout | osTicket | Znuny | UVdesk | Frappe |
|---|---|---|---|---|---|---|---|
| KB no núcleo | sim | sim (edição A CONFIRMAR) | não (módulo pago) | sim | não (pacote grátis) | sim | sim |
| Hierarquia | categoria + subcategorias | portal → categoria → artigo | categoria → artigo | categoria aninhada → FAQ | categoria → item | pasta → categoria → artigo | categoria plana → artigo |
| Rascunho | sim | sim | ? | não | ? | sim | sim |
| Arquivado | sim | sim | ? | não | ? | não doc. | sim |
| Agendamento | sim | não doc. | ? | não | ? | não | não |
| Interno vs público | por artigo + permissão por categoria | não (só público) | por categoria | por categoria **e** FAQ | 3 audiências | não doc. | por artigo (3 níveis) |
| Versões | não doc. | não doc. | não doc. | não | não doc. | **sim (restaurar)** | não doc. |
| Multi-idioma | sim, oculta sem tradução | sim (detalhe ?) | sim | sim | não doc. | não doc. | não |
| Busca KB | full-text título+corpo | sim (IA = pago?) | não doc. | não doc. | sim (pública) | não doc. | exige RediSearch |
| Deflexão | não doc. | artigos populares no widget | não doc. | não doc. | não doc. | não doc. | **sim, ao digitar o assunto** |
| Feedback de artigo | não doc. | não doc. | não doc. | não doc. | não doc. | não doc. | útil/não útil + views |
| Portal de tickets | sim | não (widget) | módulo pago | sim | sim | pacote support center | sim |
| Login portal | senha (+SSO) | — | **link mágico 1 h** | senha ou e-mail+nº ticket (link) | senha | ? | senha via convite |
| Auto-cadastro | sim (desligável) | — | implícito (cria no login) | configurável | sim | ? | desligável |
| Tickets da organização | org. compartilhada: todos veem e editam | — | não doc. | via colaborador/contato primário | "tickets da empresa" | ? | só gestor (conflito) |

## 4. A CONFIRMAR EM RUNTIME (mapeado aos cenários)

| Cenário | Projeto(s) | O que confirmar |
|---|---|---|
| K-01 | Zammad | existência de histórico de versões do artigo; diferença prática entre "arquivado" e "rascunho" |
| K-01 | Chatwoot | se o Help Center está disponível na imagem comunitária (MIT) sem licença |
| K-01 | Frappe | efeito do estado arquivado (some do portal? URL responde 404?) |
| K-01 | UVdesk | se existe visibilidade interna; como funciona a restauração de revisão |
| K-01 | Znuny | estados/aprovação do pacote FAQ na versão instalada |
| K-01 | osTicket | ausência de rascunho (FAQ nasce já pública/interna?) |
| K-02 | todos | relevância/ordenação dos resultados; anônimo vs logado vê conjuntos diferentes; busca com acento |
| K-02 | Frappe | comportamento da busca **sem** RediSearch (deve retornar vazio, segundo a doc) |
| K-03 | Zammad, osTicket, Znuny, Frappe, FreeScout(módulo, se disponível) | fluxo completo de abrir/acompanhar/responder; o que o cliente vê de notas internas (cruzar com P-03) |
| K-03 | osTicket | acesso por e-mail + nº de ticket: link expira? dá acesso a outros tickets? |
| K-03 | Frappe | método de login (senha só? OTP?) e se o cliente pode fechar/avaliar |
| K-03 / P-02 | Frappe | contato comum vê tickets de colegas? (doc conflitante) |
| K-03 / P-02 | Zammad | organização compartilhada permite **editar** ticket do colega — confirmar escopo |
| K-04 | Frappe | sugestões ao digitar assunto: critério, quantidade, se registra "deflexão" |
| K-04 | Chatwoot | artigos no widget antes da conversa |
| K-04 | Zammad, osTicket, Znuny, UVdesk | confirmar ausência |
| K-05 | Zammad | artigo sem tradução some do portal; troca de idioma |
| K-05 | osTicket | como o portal escolhe a tradução da FAQ |
| K-05 | Chatwoot | modelo de locale (artigo por locale ou tradução vinculada?) |

## 5. Recomendação preliminar para o MVP (simples e correto)

1. **Hierarquia rasa**: categoria (com no máximo um nível de subcategoria,
   opcional) → artigo. O modelo de três níveis do UVdesk e os múltiplos portais do
   Chatwoot são roadmap.
2. **Estados**: rascunho → publicado → arquivado, com transições explícitas e
   carimbo de data (publicado_em, arquivado_em). Agendamento de publicação é
   roadmap.
3. **Visibilidade por artigo** com três níveis (público / clientes autenticados /
   interno), seguindo Frappe e Znuny. Regra de segurança copiada do Frappe como
   princípio: mover artigo de categoria **nunca amplia** a audiência. Evitar a
   armadilha do Zammad (permissão de leitura que vaza conteúdo interno): a
   visibilidade "interno" nunca é servida em rota pública, sem exceção.
4. **Versões**: guardar revisões imutáveis a cada publicação (barato e evita perda
   de conteúdo); restaurar = criar nova revisão a partir de uma antiga. Diff visual
   é roadmap.
5. **Multi-idioma**: modelar desde já um campo de idioma por artigo e um vínculo
   "grupo de tradução" — mas expor só um idioma no MVP. Regra do Zammad (artigo sem
   tradução no idioma pedido não aparece / cai no idioma padrão) é a referência.
6. **Busca da KB**: PostgreSQL full-text é suficiente: coluna tsvector gerada
   (título com peso maior que corpo), índice GIN, extensão unaccent e configuração
   de idioma português; filtrar sempre por visibilidade e estado publicado. Não
   depender de serviço externo (contraexemplo: Frappe, cuja busca some sem
   RediSearch).
7. **Deflexão simples**: no formulário de novo ticket do portal, consultar a mesma
   busca com o texto do assunto (debounce) e mostrar 3–5 artigos. Registrar
   evento "artigo sugerido/aberto" para métrica futura. Voto útil/não útil é barato
   e pode entrar.
8. **Portal**: autenticação por **link mágico** (e-mail com token de uso único e
   validade curta, como no FreeScout), com senha opcional como roadmap. Evitar o
   modo "e-mail + número do ticket" do osTicket como forma principal (acesso
   parcial confuso), mas o link de acesso enviado no e-mail de resposta pode usar
   o mesmo mecanismo de token.
9. **Fluxos do portal**: listar meus tickets, ver thread **sem notas internas**
   (filtrar no servidor, nunca no cliente), responder, anexar; resposta em ticket
   resolvido reabre (consistente com T-03). Criação pelo portal deve passar pelo
   mesmo pipeline de criação/notificação dos outros canais (o FreeScout que grava
   direto no banco sem notificação é um contraexemplo).
10. **Organização**: papel "gestor" por organização vê todos os tickets da
    organização (modelo Frappe); membro comum vê só os seus. Edição de ticket
    alheio (modelo Zammad) fica fora do MVP.
