# Área 10 — API pública e webhooks (notas comportamentais)

> Estudo clean-room para o PantherDesk. Fonte: **somente documentação pública**.
> Nada de código-fonte. Texto em palavras próprias. Nomes de parâmetros, cabeçalhos,
> chaves de configuração, eventos e caminhos foram **omitidos de propósito** e
> descritos de forma conceitual.
> Confiança: **documentado** = afirmado na página citada; **inferido** = dedução a
> partir da documentação ou ausência dela; **A CONFIRMAR EM RUNTIME** = ambíguo,
> precisa ser medido nos cenários API-*.
> Data da pesquisa: 2026-10-26.

---

## 1. Problema

Integradores (CRMs, ERPs, bots, iPaaS como n8n/Make/Zapier, BI) esperam de um
helpdesk:

1. **API REST previsível**: recursos claros (tickets, mensagens/artigos, usuários,
   organizações, grupos, campos), autenticação por token com escopo de usuário,
   paginação estável em listas grandes, filtros e ordenação, expansão de relacionados
   para evitar N+1, formato de erro uniforme, códigos HTTP corretos, limites de taxa
   comunicados por cabeçalho, idempotência em criação e versionamento explícito.
2. **Webhooks confiáveis**: catálogo de eventos, payload estável, assinatura HMAC
   verificável (com proteção a replay), política de retry com backoff, timeout
   curto, desativação/“circuit breaker” de destinos quebrados, log de entregas e
   semântica de entrega honesta (na prática "pelo menos uma vez", sem garantia de
   ordem).

Os projetos analisados variam de "API só para criar ticket" (osTicket) até
"framework genérico de web services" (Znuny) e "CRUD automático por tipo de
documento" (Frappe). Webhooks variam de inexistentes a bem especificados.

---

## 2. Comportamento documentado por projeto

### 2.1 Zammad

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Estilo | REST JSON sob prefixo versionado (v1); UTF-8; parâmetros de query codificados em URL. | documentado | https://docs.zammad.org/en/latest/api/intro.html |
| Autenticação | Três modos: usuário+senha (Basic, desaconselhado e desativável pelo admin), **token de acesso pessoal** criado pelo próprio usuário nas preferências, e **OAuth2** (bearer) para apps de terceiros. | documentado | idem |
| Impersonação | Um cabeçalho permite agir "em nome de" outro usuário (identificado por id, login ou e-mail); exige permissão administrativa de usuários; vale para todos os endpoints. | documentado | idem |
| Paginação | **Offset por número de página + tamanho de página**; existe teto rígido de itens por página que o admin não pode aumentar. Contagem total **não** vem por padrão — é opcional (pedir junto ou só a contagem). | documentado | idem |
| Expansão | Por padrão a resposta traz IDs das relações; um parâmetro de expansão acrescenta os nomes/atributos legíveis das relações. Em busca, um modo "completo" devolve todos os assets relacionados + total (pode ser muito grande). | documentado | idem |
| Busca/ordenação | Busca por texto por recurso e busca global multi-objeto; busca por condições estruturadas (mesmo modelo de condições de gatilhos/visões) via POST; ordenação por campo e direção. | documentado | idem |
| Formato de erro | Não descrito na introdução. | A CONFIRMAR EM RUNTIME | idem |
| Rate limit | Não documentado na introdução da API. | A CONFIRMAR EM RUNTIME | idem |
| Versionamento | Só o prefixo de versão no caminho; sem política de depreciação descrita. | documentado (ausência) | idem |
| Idempotência | Não documentada. | inferido (inexistente) | idem |

**Webhooks (Zammad)**

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Modelo de disparo | Webhook **não é assinado a eventos diretamente**: é uma *ação* de um Gatilho (trigger) ou de um Agendador (scheduler). Ou seja, o evento + condições vêm do motor de automação. Passa pela mesma fila/prioridade dos gatilhos de e-mail, podendo atrasar. | documentado | https://admin-docs.zammad.org/en/latest/manage/webhook.html |
| Payload | Padrão: retrato JSON do ticket (atributos, estado, prioridade, grupo, dono, datas), pessoas/organização envolvidas e o **artigo mais recente** com links de anexos (anexos não vão no corpo). Campos customizados entram; vazios são omitidos; atributos sensíveis do usuário são removidos. Payload pode ser **customizado** (modelo com variáveis). | documentado | https://admin-docs.zammad.org/en/latest/manage/webhook/payload.html |
| Modelos prontos | Tipos pré-definidos para ferramentas de chat (Slack, Mattermost, Teams, Rocket.Chat) com payload específico; tipo não muda após criado. | documentado | https://admin-docs.zammad.org/en/latest/manage/webhook/add.html |
| Cabeçalhos | Identificação do produto (user-agent), nome do gatilho que disparou, **ID único de entrega** (útil para deduplicação) e assinatura (quando configurada). | documentado | payload.html (acima) |
| Assinatura | Token secreto opcional → **HMAC-SHA1 do corpo** num cabeçalho estilo "hub signature". Não criptografa; recomenda HTTPS. | documentado | add.html |
| Autenticação no destino | Basic (campos próprios; credenciais embutidas na URL são ignoradas), Bearer token ou nenhuma. | documentado | add.html |
| TLS | Verificação de certificado ligada por padrão; pode ser desligada (alerta de risco). | documentado | add.html |
| Retry | Até **4 novas tentativas** em falha; intervalo/backoff não descrito. | documentado (contagem) / A CONFIRMAR (intervalos) | webhook.html |
| Timeout | Não documentado. | A CONFIRMAR EM RUNTIME | — |
| Desativação | Manual (ativo/inativo); inativo não pode ser escolhido em gatilhos e não dispara, sem bloquear as outras ações do gatilho. **Sem desativação automática documentada.** | documentado / inferido | add.html |
| Log | "Logs recentes" por webhook: URL, método, status, cabeçalhos e corpo de requisição e resposta, horário. | documentado | https://admin-docs.zammad.org/en/latest/manage/webhook/log.html |
| Ordem/garantia | Não documentado. | A CONFIRMAR EM RUNTIME | — |

### 2.2 Chatwoot (edição comunitária)

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Famílias de API | Três: **Application** (automação no nível da conta, para agentes/admins), **Client** (para construir interfaces de chat do usuário final — identificada por inbox + contato) e **Platform** (administração da instalação: usuários, contas, papéis; só self-hosted). | documentado | https://developers.chatwoot.com/api-reference/introduction |
| Autenticação | Application: token de acesso do usuário (perfil). Client: identificador público da inbox + identificador do contato. Platform: token de um "Platform App" criado pelo super-admin; esse token só enxerga objetos que ele criou ou recebeu permissão explícita (senão 401). | documentado | idem |
| Recursos | Multi-tenant: recursos aninhados sob a conta (conversas, mensagens, contatos, inboxes, agentes, times, etiquetas, atributos customizados…). | documentado | idem / https://developers.chatwoot.com/api-reference/conversations/conversations-list |
| Paginação | Listagem de conversas é paginada; resposta envelopa dados + bloco "meta" com **contagens por aba** (minhas, não atribuídas, atribuídas, todas). Parâmetro exato de página não confirmado na página oficial; fontes secundárias indicam número de página iniciando em 1. | documentado (existência) / A CONFIRMAR (mecânica, tamanho) | conversations-list |
| Rate limit | Self-hosted: limitação por IP via middleware, **padrão ~60 req/min por IP** (localhost isento), limites mais rígidos em cadastro, login e reset de senha; configurável por variáveis de ambiente (ligar/desligar, limite, aplicar ou não ao widget). Cabeçalhos de resposta não descritos. | documentado | https://developers.chatwoot.com/self-hosted/monitoring/rate-limiting |
| Erros / versionamento | Não descritos na introdução; prefixo de versão no caminho. | A CONFIRMAR EM RUNTIME | — |

**Webhooks (Chatwoot)**

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Escopo | Por **conta**; vários por conta; cada um escolhe a lista de eventos assinados. Configurado em Integrações. | documentado | https://www.chatwoot.com/docs/product/features/webhooks |
| Eventos | Conversa criada, conversa atualizada (com a lista de atributos alterados, valor anterior e atual), mudança de status da conversa, mensagem criada, mensagem atualizada, widget aberto pelo visitante, indicador de digitação ligado/desligado (com flag de nota privada). | documentado | idem |
| Payload | JSON com campo de tipo de evento + objetos aninhados (conta, inbox, contato, usuário, conversa, mensagem). | documentado | idem |
| Assinatura | **HMAC-SHA256** sobre "timestamp + separador + corpo cru", com segredo do webhook; cabeçalhos de assinatura, timestamp e ID de entrega (quando disponível). Doc recomenda comparação em tempo constante e rejeitar timestamps com mais de ~5 min (anti-replay). | documentado | idem |
| Retry / timeout / desativação | Não descritos. | A CONFIRMAR EM RUNTIME | — |
| Agent bots | Bots recebem eventos por webhook (URL de saída) e respondem pela API — um segundo canal de eventos, parecido com webhook. | documentado (parcial) | https://www.chatwoot.com/docs/webhooks |

### 2.3 FreeScout

API e webhooks **não fazem parte do núcleo**: dependem do módulo pago "API & Webhooks" (licença vitalícia por instância; código AGPL).

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Autenticação | **Chave de API** passada de três formas alternativas: parâmetro de query, usuário do Basic auth, ou cabeçalho próprio. Existem chaves **por usuário** e uma **chave global**, com comportamentos diferentes (ex.: "quem sou eu" só com chave de usuário). | documentado | https://api-docs.freescout.net/ |
| Recursos | Conversas, threads (mensagens/notas), campos customizados, clientes, caixas de correio, pastas, tags, registros de tempo, usuários, relatórios, webhooks; alguns exigem módulos adicionais. | documentado | idem |
| Verbos | GET/POST/PUT/DELETE + OPTIONS para CORS (origem permitida configurável). | documentado | idem |
| Paginação | **Offset por página + tamanho** (padrão 50); resposta traz objeto de página com tamanho, total de elementos, total de páginas e número atual. | documentado | idem |
| Filtros/ordenação | Filtros por parâmetros + campo e direção de ordenação. | documentado | idem |
| Expansão | Parâmetro de "embutir" relacionados (threads, tempos, tags) — estilo HAL, relacionados em sub-objeto separado. | documentado | idem |
| Erro | Corpo com mensagem, código de erro e **lista de erros por campo** (caminho do campo, mensagem, valor rejeitado, origem). | documentado | idem |
| Status HTTP | 200/201 (com cabeçalho de ID do recurso ou Location)/204; 400, 401 (chave ausente/inválida), 403, 404, 405, 409, 412, 413, 415; 500 e 504 (504 seguro para retentar após breve espera). | documentado | idem |
| Datas | ISO 8601 em UTC. | documentado | idem |
| Rate limit | Não documentado. | A CONFIRMAR EM RUNTIME | — |
| Idempotência / versionamento | Não documentados. | inferido (inexistente) | — |

**Webhooks (FreeScout)**

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Gestão | Webhooks podem ser criados/listados/excluídos pela UI e **pela própria API**; cada um tem URL, eventos assinados e escopo opcional por caixa de correio; listagem mostra última execução e último erro. | documentado | https://api-docs.freescout.net/ |
| Eventos | Família "conversa" (criada, atribuída, movida, status alterado, resposta do cliente, resposta do agente, nota adicionada, excluída, excluída definitivamente, restaurada) e família "cliente" (criado, atualizado). | documentado | https://freescout.net/module/api-webhooks/ |
| Payload | Corpo é o objeto Conversa ou Cliente em JSON (mesma representação da API). Cabeçalho indica o nome do evento. | documentado | idem |
| Assinatura | **HMAC-SHA1 do corpo cru, codificado em base64**, com segredo global do módulo. | documentado | idem |
| Sucesso | Somente status 2xx; corpo da resposta ignorado. | documentado | idem |
| Retry | Até **10 tentativas** com intervalo crescente ao longo de **~2 horas**. | documentado | idem |
| Log | Logs de entrega mantidos por **3 dias**. | documentado | idem |
| Timeout / desativação automática | Não documentados. | A CONFIRMAR EM RUNTIME | — |

### 2.4 osTicket

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Escopo | API HTTP mínima: **apenas criação de ticket** (não lê, não altera, não exclui) + disparo remoto da tarefa de cron. | documentado | https://docs.osticket.com/en/latest/Developer%20Documentation/API%20Docs.html |
| Autenticação | Chave de API criada no painel admin, **amarrada a um IP de origem**; atrás de proxy usa o IP do cabeçalho de encaminhamento. Chave vai num cabeçalho. Escopos/permissões por chave não descritos na página. | documentado / A CONFIRMAR (permissões) | idem |
| Formatos | Corpo em XML, JSON **ou e-mail cru (MIME)**; formato escolhido pela extensão do endpoint. Também há rota local de "pipe" de e-mail sem chave. | documentado | https://docs.osticket.com/en/latest/Developer%20Documentation/API/Tickets.html |
| Campos | Obrigatórios: e-mail e nome do solicitante, assunto, mensagem (texto ou HTML). Opcionais: IP, prioridade, origem, tópico de ajuda, flags para **suprimir alerta à equipe e auto-resposta**, e campos customizados dos formulários pelo nome do campo. | documentado | idem |
| Anexos | Em JSON, cada anexo é um **data URL (RFC 2397)**; em XML, subelementos com nome, tipo e flag base64. | documentado | idem |
| Resposta | **201** com o número externo do ticket no corpo; erro com status HTTP apropriado e descrição em texto. | documentado | idem |
| Cron remoto | Endpoint de tarefas aceita somente o tipo "cron" via POST. | documentado | https://docs.osticket.com/en/latest/Developer%20Documentation/API/Tasks.html |
| Paginação, rate limit, versionamento | Não aplicável/não documentado. | documentado (ausência) | — |
| Webhooks | **Não há webhooks no núcleo** documentados; somente via plugins de terceiros. | inferido | — |

### 2.5 Znuny (GenericInterface)

Znuny não tem "uma API REST" fixa: tem um **framework de web services** configurável, em que o admin monta serviços de entrada (provider) e de saída (requester).

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Camadas | Transporte de rede (SOAP ou REST) → mapeamento de dados (pode renomear campos/valores nos dois sentidos, inclusive via XSLT) → controlador → operações (entrada) / invokers (saída). | documentado | https://doc.znuny.org/doc/manual/admin/6.0/en/html/genericinterface.html |
| Provider (entrada) | Recebe chamada, mapeia, verifica acesso do usuário, executa operação, devolve resposta mapeada. REST mapeia rota + verbo HTTP → operação, com variáveis de caminho. | documentado | idem |
| Conector de tickets (exemplo) | Serviço de exemplo importável com operações de sessão (criar/obter/encerrar), criar/obter/buscar/atualizar ticket e histórico. | documentado | https://doc.znuny.org/znuny/admin/webservices/examples/GenericTicketConnectorREST/index.html |
| Autenticação | Credenciais (login+senha) em cada chamada **ou** criar sessão e reutilizar o ID de sessão; versões recentes aceitam credenciais em cabeçalhos ou parâmetros. Sessão expira pelo timeout normal. Recomenda HTTPS porque credenciais/sessão podem ir na query. Agentes e clientes usam suas próprias contas. | documentado | idem + https://doc.znuny.org/znuny/admin/webservices/index.html |
| Erros | Objeto de erro com **código prefixado pelo nome da operação** + mensagem; o exemplo de acesso negado retorna **HTTP 200** com o erro no corpo. | documentado | GenericTicketConnectorREST |
| Busca/paginação | Busca devolve **lista de IDs**; filtros por estado, fila, prioridade, datas e campos dinâmicos; clientes só veem os próprios tickets. Paginação/ordenação não descritas na página. | documentado / A CONFIRMAR | idem |
| Rate limit / idempotência / versionamento | Não documentados (versionamento = configuração exportável e com histórico de versões do web service, que pode ser revertido). | documentado (histórico) / inferido | genericinterface.html |
| Debug | Log de comunicação por web service com limiar de detalhe; tela de depuração com filtro por direção, data, IP. **Exportação de configuração contém senhas em texto claro.** | documentado | genericinterface.html |

**Saída "tipo webhook" (Znuny requester)**

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Disparo | Invokers ligados a **eventos** (ticket criado, artigo criado, etc.) com condições (igualdade, regex, módulo customizado; combinação E/OU/XOU; avaliação complexa via jq). Também acionáveis por GenericAgent, por ações de processos e como transporte de notificações. | documentado | https://doc.znuny.org/znuny/admin/webservices/invoker/index.html |
| Tipos de invoker | Um invoker de ticket genérico (ticket completo + artigos, sem anexos; eventos de artigo incluem o artigo novo e anexos em base64; atualizações podem incluir o estado anterior) e um invoker **pass-through** (repassa os dados do evento sem mapear) — o mais próximo de webhook. | documentado | idem |
| Resposta | Mapeamento de resposta pode **alterar o ticket** (título, estado, dono, fila, histórico, novo artigo) e encadear outro invoker assíncrono. | documentado | idem |
| Síncrono/assíncrono | Evento pode ser marcado assíncrono → executado pelo daemon em segundo plano. | documentado | genericinterface.html |
| Autenticação no destino | Certificado cliente, Basic, chave de API em cabeçalho, OAuth2 (token). Cabeçalhos customizados (podendo sobrescrever os padrão). JSON padrão; form-urlencoded e XML opcionais. | documentado | https://doc.znuny.org/znuny/admin/webservices/requester/index.html |
| TLS | Verificação de hostname pode ser desligada. | documentado | idem |
| Assinatura HMAC | **Não documentada** (só autenticação). | inferido (ausente) | — |
| Retry | Documentação de API de desenvolvedor indica que requisição assíncrona com erro pode ser **reagendada** se o invoker sinalizar; não há política padrão descrita no manual do admin. | inferido | https://doc.znuny.org/znuny-dev-api/API/Kernel/GenericInterface/Requester.html |
| Timeout / desativação | Não documentados no manual. | A CONFIRMAR EM RUNTIME | — |

### 2.6 UVdesk (open source)

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Pacote | API é um pacote/bundle separado que precisa ser integrado ao projeto. | documentado | https://docs.uvdesk.com/uvdemo/settings/api.html |
| Tokens | Admin cria tokens nomeados em Configurações → API, podendo habilitar, desabilitar ou excluir; também é possível trocar credenciais do usuário por token numa chamada de login e invalidá-lo no logout. Uso como Bearer. Escopos não descritos. | documentado | idem + https://packagist.org/packages/uvdesk/api-bundle |
| Recursos | Tickets (listar, obter, criar, atualizar, excluir); clientes e agentes citados genericamente. | documentado | idem |
| Paginação | Listagem com metadados de página (atual, total de páginas, itens por página, total de itens, faixa de páginas) → **offset por página**. A listagem também devolve listas de referência (status, prioridades, tipos, grupos, times, agentes, origens) — uma forma de "sideload" fixo. | documentado | packagist (README) |
| Erros, rate limit, versionamento | Não documentados. | A CONFIRMAR EM RUNTIME | — |
| Webhooks | **Não documentados**; workflows (evento → condições → ações) não citam ação HTTP. | inferido (ausente) / A CONFIRMAR | https://docs.uvdesk.com/uvdemo/productivity/workflow.html |

### 2.7 Frappe Helpdesk (sobre Frappe Framework)

O Helpdesk herda a API do framework: **todo tipo de documento (DocType) ganha CRUD REST automático**, mais métodos RPC "liberados" pelo app.

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Autenticação | (a) chave+segredo de API por usuário num cabeçalho de autorização (ações rodam como esse usuário, com seus papéis); (b) sessão por cookie após login; (c) **OAuth2 bearer**. | documentado | https://docs.frappe.io/framework/user/en/api/rest |
| CRUD genérico | Criar, ler, atualizar parcialmente e excluir por tipo + nome do registro. | documentado | idem |
| Seleção de campos | Por padrão a lista devolve só o identificador; parâmetro escolhe os campos. | documentado | idem |
| Expansão | Parâmetros para expandir links (substituir o valor de um campo de vínculo pelo registro vinculado) na lista e na leitura. | documentado | idem |
| Filtros | Filtros com E e conjunto alternativo com OU; ordenação por campo/direção. | documentado | idem |
| Paginação | **Offset + limite** (início e tamanho de página). | documentado | idem |
| RPC | Funções do servidor expostas se marcadas como liberadas; GET para leitura, POST para escrita (commit automático). | documentado | idem |
| Erros | Resposta de erro carrega tipo da exceção e **stack trace** (atenção: vazamento de detalhes). Status HTTP não detalhados na página. | documentado / A CONFIRMAR (status) | idem |
| Rate limit | Dois mecanismos: (1) limite **por tempo de processamento** no site inteiro (janela fixa; desligado por padrão); (2) limite por endpoint (por chave/IP, janela configurável). Excesso → **429** com cabeçalho de "tentar após"; cabeçalhos de limite/restante/usado (doc fala em microssegundos — inconsistência a medir). | documentado | https://docs.frappe.io/framework/user/en/rate-limiting |
| API do Helpdesk | Docs oficiais do Helpdesk são guia de usuário; não há referência de API própria — usa-se CRUD genérico do tipo "ticket do helpdesk" + métodos do app. | inferido | https://docs.frappe.io/helpdesk |
| Versionamento | Não detalhado na página (há prefixos distintos para recursos e métodos). | A CONFIRMAR EM RUNTIME | — |

**Webhooks (Frappe)**

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Disparo | Webhook amarrado a um **tipo de documento + evento do ciclo de vida** (inserção, atualização, envio, cancelamento, exclusão…), com condição opcional; só habilitados disparam. | documentado | https://docs.frappe.io/framework/user/en/guides/integration/webhooks |
| Requisição | URL e método configuráveis (POST padrão), cabeçalhos customizados; corpo **form** (mapa campo→chave) ou **JSON por template** (Jinja). | documentado | idem |
| Assinatura | Segredo opcional → **HMAC-SHA256 do payload em base64** num cabeçalho próprio. | documentado | idem |
| Log | Registro de requisição por entrega bem-sucedida. | documentado | idem |
| Retry / timeout / fila / desativação | Não documentados. | A CONFIRMAR EM RUNTIME | — |

---

## 2.8 Referência de mercado — Zendesk (somente developer.zendesk.com)

Lido apenas documentação pública de desenvolvedor. Serve como "o que um integrador espera".

| Tópico | Comportamento | Confiança | URL |
|---|---|---|---|
| Autenticação | **OAuth2 bearer recomendado** (token por instância; apps multi-cliente usam tokens globais). Token de API (Basic com e-mail+token) **marcado como depreciado** por equivaler a senha que pode personificar qualquer usuário. HTTPS com TLS 1.2+ obrigatório. | documentado | https://developer.zendesk.com/api-reference/introduction/security-and-auth/ |
| Formato | JSON, nomes sensíveis a maiúsculas, datas ISO 8601 UTC; versão no caminho (v2). | documentado | https://developer.zendesk.com/api-reference/introduction/requests/ |
| Status | GET/PUT 200, POST 201 (+Location), DELETE 204; 400 genérico; 403 sem permissão; **409 conflito por alteração concorrente** (serializar e retentar); **422 entidade não processável** (ex.: fechar ticket já fechado); 429 limite; 503 com "retry-after" para falhas transitórias; ID de requisição em cabeçalho para suporte. Erros de negócio em JSON; erros de plataforma podem vir em texto. | documentado | idem |
| Paginação | **Cursor recomendado** (tamanho de página + link "próximo" + flag "há mais"); offset por página ainda é padrão mas **limitado às 100 primeiras páginas (~10 mil registros)** — além disso, 400 apontando para cursor. Teto de 100 itens/página. Exportações incrementais usam variante de cursor por tempo. | documentado | https://developer.zendesk.com/api-reference/introduction/pagination/ |
| Sideloading | Parâmetro de inclusão com lista de relacionados; relacionados vêm em **arrays de nível superior** ao lado do recurso principal; cada endpoint aceita só os sideloads listados; em busca, sideload é por tipo. | documentado | https://developer.zendesk.com/documentation/ticketing/using-the-zendesk-api/side_loading/ |
| Rate limit | Por plano (dezenas a centenas req/min por conta; add-on de alto volume), limites específicos por endpoint (ex.: atualizações do mesmo ticket), teto de jobs simultâneos, salvaguarda global. Cabeçalhos com limite e restante; **429 + retry-after em segundos**. | documentado | https://developer.zendesk.com/api-reference/introduction/rate-limits/ |
| Idempotência | Cabeçalho de chave de idempotência na **criação de ticket**: mesma chave + mesmo corpo → resposta em cache (com cabeçalho indicando "hit"); mesma chave + corpo diferente → 400; chave expira em **2 h**; não é gravada no ticket. | documentado | https://developer.zendesk.com/api-reference/ticketing/introduction/ |
| Webhooks — conexão | Dois modos exclusivos e imutáveis: **assinatura de eventos** do sistema (usuários, organizações, central de ajuda…; sempre POST JSON) ou **ação de gatilho/automação** (eventos de ticket; payload customizável, vários métodos/formatos). | documentado | https://developer.zendesk.com/documentation/webhooks/creating-and-monitoring-webhooks/ |
| Webhooks — auth no destino | Chave de API em cabeçalho, Basic ou Bearer (só sobre HTTPS); assinatura é camada separada. | documentado | https://developer.zendesk.com/documentation/webhooks/webhook-security-and-authentication/ |
| Webhooks — assinatura | **HMAC-SHA256 sobre timestamp + corpo**, base64, com cabeçalhos de assinatura e de timestamp; segredo consultável e rotacionável via API; segredo estático para testes antes de criar. | documentado | https://developer.zendesk.com/documentation/webhooks/verifying/ |
| Webhooks — timeout/retry | **Timeout de 12 s**; timeout → até 5 retentativas; 409 → até 3; 429/503 com retry-after curto → retentado. | documentado | idem (resultado de busca no domínio) |
| Webhooks — circuit breaker | Abre se ≥70% de erros em 5 min ou >1000 erros em 5 min (com mínimo de ~100 requisições); pausa curta e testa de novo até sucesso. | documentado | https://developer.zendesk.com/api-reference/webhooks/introduction/ |
| Webhooks — garantia | **Melhor esforço, possivelmente duplicado**, e pode perder eventos com o circuito aberto → receptor deve ser idempotente. Ordem não garantida (não afirmada). | documentado / inferido (ordem) | creating-and-monitoring-webhooks |
| Webhooks — observabilidade | Log de invocações e de cada tentativa por **7 dias**, filtrável por status; API para listar invocações. | documentado | idem |

---

## 3. Tabela comparativa

| Aspecto | Zammad | Chatwoot | FreeScout | osTicket | Znuny | UVdesk | Frappe HD | Zendesk (ref.) |
|---|---|---|---|---|---|---|---|---|
| API no núcleo | sim | sim | **módulo pago** | só criar ticket | framework configurável | bundle separado | sim (genérica) | sim |
| Auth | token pessoal, OAuth2, Basic | token usuário / inbox / platform | chave (usuário ou global) | chave + IP | sessão ou credenciais | Bearer token | chave+segredo, sessão, OAuth2 | OAuth2 (token depreciado) |
| Impersonação | sim (cabeçalho, admin) | não doc. | não doc. | n/a | n/a | não | não doc. | n/d |
| Paginação | offset/página, total opcional | página (meta c/ contagens) | offset/página c/ totais | n/a | IDs, não doc. | offset/página | offset/limite | **cursor** (offset limitado) |
| Expansão | expand / full | aninhado fixo | embed (HAL) | n/a | mapeamento | listas de referência | expand links + campos | sideload top-level |
| Erro estruturado | ? | ? | **sim, por campo** | texto | código+msg c/ HTTP 200 | ? | exceção+trace | JSON + 409/422 |
| Rate limit | ? | 60/min/IP (cfg) | ? | — | ? | ? | 429 + retry-after | por plano, 429 + headers |
| Idempotência | não | não | não | não | não | não | não | **chave 2 h** |
| Webhook nativo | sim (ação de gatilho) | sim (eventos assinados) | sim (módulo) | não | invoker (sem HMAC) | não | sim (evento de doc) | sim (2 modos) |
| HMAC | SHA1 corpo | **SHA256 ts+corpo** | SHA1 b64 corpo | — | — | — | SHA256 b64 | **SHA256 ts+corpo** |
| Anti-replay | não | timestamp | não | — | — | — | não | timestamp |
| ID de entrega | sim | sim (às vezes) | não doc. | — | — | — | não doc. | invocação/tentativa |
| Retry | 4× | ? | **10× / ~2 h** | — | reagendamento opcional | — | ? | 5× timeout, por código |
| Timeout | ? | ? | ? | — | ? | — | ? | **12 s** |
| Auto-desativação | não doc. | ? | não doc. | — | ? | — | ? | circuit breaker |
| Log de entregas | recentes | ? | 3 dias | — | debugger | — | só sucessos | 7 dias |
| Payload customizável | sim (template) | não | não | — | sim (XSLT) | — | sim (Jinja) | sim (gatilho) |

`?` = não documentado → medir em runtime.

---

## 4. A CONFIRMAR EM RUNTIME (mapeado aos cenários)

| Cenário | Projeto(s) | O que medir |
|---|---|---|
| API-01 | Zammad | Formato do corpo de erro (validação, 404, 401, 403, 422?); se há total na paginação quando pedido; teto real de itens/página. |
| API-01 | Chatwoot | Nome/tamanho de página da listagem de conversas; se há total; formato de erro; status em validação. |
| API-01 | FreeScout | Confirmar envelope de erro por campo e 201 com cabeçalho de ID; comportamento de PUT parcial. |
| API-01 | osTicket | Corpo do erro (texto?); o que a chave permite (criar ticket vs cron); rejeição de IP diferente. |
| API-01 | Znuny | Erros sempre com HTTP 200? Paginação/limite da busca; expiração de sessão. |
| API-01 | UVdesk | Formato de erro, status HTTP, se criação/exclusão existem de fato no bundle instalado. |
| API-01 | Frappe HD | Status HTTP de validação/permissão; se stack trace aparece em produção; CRUD do tipo ticket do helpdesk vs métodos do app. |
| API-02 | Zammad | Cabeçalhos reais (assinatura SHA1, ID de entrega, nome do gatilho); payload padrão em criação e atualização. |
| API-02 | Chatwoot | Assinatura HMAC-SHA256 com timestamp presente na versão testada (doc é recente); ID de entrega. |
| API-02 | FreeScout | Assinatura SHA1 base64; cabeçalho de evento; payload = representação da API. |
| API-02 | Znuny | Invoker pass-through: forma do corpo e cabeçalhos; ausência de assinatura. |
| API-02 | Frappe HD | Assinatura SHA256 base64; corpo template; se disparo é síncrono ou em fila. |
| API-02 | osTicket, UVdesk | Confirmar N/A (sem webhook nativo). |
| API-03 | Zammad | Intervalos das 4 retentativas; se o webhook fica inativo depois. |
| API-03 | Chatwoot | Existe retry? Quantos? Desativa? |
| API-03 | FreeScout | Curva de backoff (10× em ~2 h); registro no "último erro"; desativação? |
| API-03 | Znuny | Retry em modo assíncrono sem configuração adicional? |
| API-03 | Frappe HD | Retry? Log de falha (doc só fala de sucesso). |
| API-04 | todos c/ webhook | Timeout efetivo (Zendesk documenta 12 s como referência); se timeout conta como falha e gera retry; se bloqueia a transação do ticket (especialmente Frappe/Znuny síncronos). |
| API-05 | Chatwoot | 429 após ~60/min/IP? Cabeçalhos? Localhost isento pode mascarar o teste — rodar de outro IP do lab. |
| API-05 | Frappe HD | Ativar limite e medir 429 + cabeçalhos (unidade: s ou µs?). |
| API-05 | Zammad, FreeScout, UVdesk, Znuny, osTicket | Existe algum limite? Se não, registrar "sem limite" como evidência. |
| API-06 | Zendesk (docs) | Concluído nesta pesquisa (seção 2.8); apenas leitura de developer.zendesk.com. |

---

## 5. Recomendação preliminar para o MVP do PantherDesk

Princípio: **simples e correto**, alinhado à expectativa de mercado (Zendesk) mas sem a superfície toda.

**API REST**
1. **Recursos MVP**: tickets, mensagens (públicas e notas internas) do ticket, anexos, usuários (agentes e solicitantes), organizações, grupos, definições de campos customizados, webhooks (gestão via API, como FreeScout). Prefixo de versão no caminho (v1) + política escrita de depreciação (aviso por cabeçalho antes de remover).
2. **Autenticação**: tokens de API **por usuário** (ações herdam permissões do dono, como Frappe/Zammad), armazenados com hash, com nome, expiração opcional, último uso e revogação; transmitidos **somente em cabeçalho** (nunca query, ao contrário de FreeScout/Znuny). OAuth2 fica para roadmap, mas o modelo de "credencial → principal com escopos" deve existir desde já. Escopos mínimos: leitura / escrita / admin. Impersonação ("em nome de") apenas para tokens admin, auditada.
3. **Paginação**: **cursor opaco** como padrão (limite padrão 25, máximo 100, link/valor "próximo" + flag "há mais"), ordenação estável (data + id). Total só sob pedido. Evitar offset profundo (lição do Zendesk).
4. **Filtros**: conjunto pequeno e explícito (status, grupo, responsável, solicitante, organização, atualizado desde/até, tag). Um endpoint de "mudanças desde X" (export incremental por cursor de tempo) é muito pedido por integradores e simplifica sincronização.
5. **Expansão**: parâmetro de inclusão com lista fechada por recurso; relacionados em seção separada no nível superior (sideload) para evitar duplicação.
6. **Erros**: envelope único com código estável legível por máquina, mensagem, lista de erros por campo (inspirado em FreeScout) e ID de requisição (também em cabeçalho). **Nunca stack trace.** Status corretos: 400 malformado, 401, 403, 404, 409 conflito de versão (usar ETag/versão otimista em update), 422 validação, 429, 5xx. **Jamais erro com 200** (anti-padrão do Znuny).
7. **Rate limit**: por token (e por IP para não autenticado), janela deslizante simples; cabeçalhos de limite/restante/reset em **segundos**; 429 com retry-after.
8. **Idempotência**: cabeçalho de chave de idempotência em todos os POST de criação (ticket, mensagem), guardado ~24 h com hash do corpo; mesma chave + corpo diferente → 422/409. Custo baixo, evita tickets duplicados por retry de integradores.

**Webhooks**
1. **Modelo duplo, mas com um único motor de entrega**: (a) assinaturas de eventos de domínio (ticket criado/atualizado/status alterado/atribuído, mensagem criada, usuário/organização criados/atualizados) com payload **estável e versionado**; (b) ação "chamar webhook" nas automações (roadmap curto), reutilizando a mesma fila, assinatura e log.
2. **Payload**: envelope fixo com ID do evento (único, para dedupe), tipo, versão do schema, instante, ator, e o recurso na mesma representação da API; em updates, lista de campos alterados (antes/depois — padrão Chatwoot). Anexos por link, nunca inline.
3. **Assinatura**: HMAC-SHA256 sobre "timestamp + corpo cru", cabeçalhos de assinatura, timestamp e ID de entrega; segredo por webhook, rotacionável com período de dois segredos válidos. Documentar verificação com comparação em tempo constante e janela de 5 min.
4. **Entrega**: sempre assíncrona via **outbox transacional** (evento gravado na mesma transação da mudança → worker entrega), para não perder evento nem travar o ticket. Timeout de conexão+resposta ~10 s. Sucesso = 2xx; redirecionamento não seguido.
5. **Retry**: backoff exponencial com jitter, ~8 tentativas ao longo de ~24 h (meio-termo entre FreeScout 2 h e mercado); respeitar retry-after em 429/503; não retentar 4xx exceto 408/409/429.
6. **Desativação**: após N falhas consecutivas por um período (ex.: 24 h sem sucesso) → webhook desativado automaticamente + notificação ao admin; reativação manual com botão "reenviar/testar".
7. **Garantias declaradas**: "pelo menos uma vez", **sem garantia de ordem** (incluir número de sequência/versão do recurso para o receptor descartar eventos velhos).
8. **Observabilidade**: log por entrega e por tentativa (status, latência, corpo truncado da resposta) por 7–14 dias; reenvio manual; endpoint de teste ("ping").
9. **Segurança de saída**: bloquear por padrão destinos em redes privadas/loopback (proteção SSRF) com allowlist configurável pelo admin (necessária para o lab `hooks.lab.test`); TLS verificado por padrão.

**Fora do MVP**: OAuth2 completo, GraphQL, bulk/jobs assíncronos, payload por template (Jinja/XSLT), SOAP.
