# Estudo de fonte — Libredesk (abhinavxd/libredesk)

- **Data do estudo:** 2026-10-29
- **Commit estudado:** `41bcf70f5cb7da202e597db95e94263867b20982` (commit de 2026-10-28, clone raso do ramo padrão)
- **Licença:** **GNU AGPL-3.0**. Parte da infraestrutura declara ser adaptada do listmonk, que também é AGPL-3.0.
- **Postura:** este é o lado "sujo" do muro clean-room. O texto traz só conhecimento abstrato: comportamento, arquitetura e escolhas de tecnologia. Não há trechos de código, SQL, nomes de funções, tipos, variáveis, tabelas, colunas, arquivos, caminhos, chaves de configuração, cabeçalhos próprios do projeto nem textos de interface. O repositório foi clonado num diretório temporário fora do projeto e só foi lido; nada foi construído nem executado.
- **Tamanho aproximado:** cerca de 22 mil linhas de Go na camada HTTP, 40 mil no núcleo de domínio, uma centena de arquivos de teste no backend, frontend Vue com testes de componente e de ponta a ponta, e 13 idiomas (incluindo pt-BR e pt-PT).

---

## 1. Resumo da arquitetura

O Libredesk é um helpdesk omnicanal (e-mail, chat no site e WhatsApp) entregue como **um único binário Go** que já contém o frontend compilado, os arquivos de tradução, o esquema do banco, os modelos de e-mail e o script do widget de chat. Ele depende de dois serviços externos: **PostgreSQL** (fonte de verdade de tudo) e **Redis** (sessões, cache HTTP, limite de taxa, uma fila durável específica e estado efêmero do widget).

O processo único faz tudo: serve a API HTTP e os websockets, lê caixas IMAP, envia por SMTP, avalia SLA, roda automações, reatribui conversas, entrega webhooks e notificações e executa o agente de IA. Cada responsabilidade é um "gerenciador" de domínio no núcleo, criado na inicialização com injeção explícita de dependências. Os laços de segundo plano rodam como goroutines dentro do mesmo processo. A camada HTTP é um pacote plano de handlers que recebe um contexto global da aplicação com todos os gerenciadores. Não há framework de ORM: cada módulo de domínio tem seu próprio arquivo de consultas SQL nomeadas, embutido no binário e preparado na inicialização.

O mesmo binário funciona como ferramenta de administração por flags de linha de comando: instala o esquema (de forma idempotente), aplica atualizações de banco, redefine a senha do usuário de sistema e mostra a versão. O deploy oficial é um docker-compose com três contêineres (app, Postgres e Redis). O comando de inicialização do contêiner do app encadeia instalar, atualizar e servir, então subir uma versão nova consiste em trocar a imagem e reiniciar.

O frontend é um monorepo pnpm com **duas aplicações Vue 3** (o painel dos agentes e o widget de chat do site), uma biblioteca de UI compartilhada no estilo shadcn-vue e um pequeno script de carregamento em JavaScript puro, que o site cliente inclui para injetar o widget num iframe.

---

## 2. Temas

### 2.1 Binário único e configuração

- **Embutir arquivos:** depois de compilar o Go, uma ferramenta de terceiros (stuffbin) anexa ao final do executável um sistema de arquivos virtual com o frontend, as traduções, o esquema, os modelos de e-mail e os arquivos públicos. Em tempo de execução, o app lê esse sistema virtual. Uma flag permite sobrepor um diretório local para personalizar arquivos estáticos sem recompilar. A compilação é estática (sem CGO), com versão e commit injetados por flags do linker.
- **Fuso horário embutido:** o binário inclui a base de fusos do próprio Go, então não depende do sistema operacional. Isso importa para o SLA.
- **Configuração em duas camadas:** um arquivo TOML mais variáveis de ambiente (via koanf) definem a infraestrutura: banco, Redis, porta, chave de criptografia, número de workers e tamanho das filas. A **configuração funcional** (nome do helpdesk, idioma, URL raiz, provedores etc.) fica numa tabela chave→JSON no Postgres, é editada pela interface e carregada na mesma árvore de configuração ao iniciar. Algumas mudanças pedem reinício, e o app sinaliza isso para o administrador.
- **Extras:** verificação de atualização contra o repositório público (pode ser desligada), endpoint de profiling opcional em porta separada, servidor HTTP com limites explícitos de corpo, buffers e timeouts, desligamento gracioso que fecha websockets antes do HTTP, e suporte a socket Unix.

### 2.2 Organização do backend

- **Camadas:** (a) o ponto de entrada monta tudo e registra cerca de 300 rotas; (b) os handlers HTTP fazem validação, autorização e serialização; (c) os gerenciadores de domínio (conversa, caixa de entrada, usuário, equipe, papel, SLA, horário útil, automação, macro, modelos, mídia, IA, webhooks, notificações, relatórios, central de ajuda, campos personalizados etc.) concentram a regra de negócio e o acesso ao banco.
- **Dependências entre módulos** são declaradas como interfaces pequenas no módulo consumidor, e dependências circulares (como automação↔conversa ou websocket↔conversa) são resolvidas com "setters" depois da construção.
- **HTTP:** fasthttp com um roteador/envelope leve (fastglue), respostas num envelope JSON padronizado (dados ou erro tipado) e middlewares compostos por função: autenticação, permissão, limite de taxa e URL assinada.
- **SQL à mão:** consultas nomeadas em arquivos .sql por módulo (padrão "yesql"), executadas com sqlx. Filtros dinâmicos de listas e visões salvas passam por um construtor que traduz um JSON de filtros em cláusulas WHERE parametrizadas, **aceitando só campos de uma lista branca** por modelo e limitando a quantidade de grupos.
- **Segurança transversal:** saneamento de HTML (bluemonday), proteção contra SSRF nas chamadas de saída (webhooks, OIDC, IA, importação de URLs), criptografia AES-256-GCM dos segredos guardados no banco (senhas de IMAP/SMTP, tokens OAuth, segredos de webhook) com chave vinda da configuração, e mídia servida por URL assinada com validade.

### 2.3 PostgreSQL: esquema, migrações e busca

- **Esquema:** um arquivo SQL único cria tudo do zero. Ele usa bastante **tipos ENUM** nativos (canal, tipo e status de mensagem, métricas de SLA, tipos de notificação, eventos de webhook etc.), **CHECK de tamanho** em quase todo campo de texto, chaves estrangeiras com política explícita (cascata, anular ou restringir), UUID público além do id serial interno, **número de referência legível** gerado por função no banco e **JSONB** para tudo que é flexível: metadados, campos personalizados, regras de automação, ações de macro, filtros de visão, horários e feriados, configurações de provedor. Os papéis guardam as permissões como array de texto.
- **Denormalização deliberada:** a linha da conversa guarda a última mensagem (texto, remetente, horário), a última interação, o próximo prazo de SLA, "aguardando desde", "adiada até" e o último contato recebido. Isso deixa a lista de conversas e a ordenação baratas, ao custo de manter esses campos atualizados em cada evento. Há índices em praticamente todas as colunas usadas para ordenar ou filtrar.
- **Garantias no banco:** índice único parcial para que só exista um SLA "pendente" por conversa, e `FOR UPDATE` / `SKIP LOCKED` em pontos de concorrência (fila de e-mails de notificação, recálculo de prazo de SLA).
- **Migrações:** o esquema base continua sendo a fonte da instalação nova. Atualizações são **funções Go por versão semântica**, idempotentes (usam "se não existir" e verificações), registradas numa lista ordenada. O app grava no banco a última versão aplicada, roda as pendentes com uma flag de atualização (pedindo backup e confirmação, salvo flag) e **recusa iniciar** se houver migração pendente. Algumas migrações fazem mais que DDL (reprocessam dados, leem configuração).
- **Busca:**
  - Conversas: por número de referência exato ou e-mail do contato.
  - Mensagens: **trigramas (pg_trgm) com índice GIN** sobre o texto puro da mensagem, que é guardado ao lado do HTML. A busca é por substring e devolve um recorte em volta do termo.
  - Contatos: trigramas em e-mail e telefone.
  - Artigos da central de ajuda: **full-text search do Postgres** com coluna tsvector gerada e pesos diferentes para título, resumo e corpo, configuração de idioma escolhida por locale, corpo truncado antes de indexar (por causa do limite de tamanho do tsvector) e trigramas como apoio.
  - Todas as buscas aplicam no SQL as mesmas regras de visibilidade das permissões.
- **Vetores sem pgvector:** os embeddings ficam como bytes no Postgres, mas a busca semântica é feita **em memória no processo** (índice carregado na inicialização, similaridade por cosseno, reconciliação periódica). Simples para bases pequenas, mas não escala e não funciona com várias instâncias.

### 2.4 Filas e jobs em segundo plano

Não há broker dedicado. O padrão dominante é **canal em memória + pool de goroutines + varredura periódica do banco**:

- **Envio de mensagens:** a resposta do agente é gravada no banco como "pendente", e uma varredura muito frequente (dezenas de milissegundos por padrão) pega as pendentes e manda para um pool de envio. O que está "em processamento" fica marcado em memória para não pegar duas vezes. Como o estado vive no banco, a saída é **durável**: se o processo cair, a mensagem continua pendente.
- **Entrada de mensagens:** os leitores de canal colocam a mensagem num canal em memória com tamanho fixo, consumido por workers. No e-mail, a durabilidade vem de reler a caixa por janela de tempo e descartar duplicatas pelo Message-ID, não da fila.
- **Fila durável de verdade:** só um canal (o WhatsApp, cujo webhook precisa responder rápido) usa **Redis Streams com consumer group**, entrega "pelo menos uma vez", reivindicação de mensagens órfãs, limite de tentativas e stream de dead-letter. Os handlers são obrigatoriamente idempotentes.
- **Outros laços periódicos:** avaliação de SLA, envio das notificações de SLA agendadas, gatilhos de tempo das automações (de hora em hora), atribuição automática, reabertura de conversas adiadas, limpeza de rascunhos, mídia órfã e notificações antigas, detecção de agentes offline (que pode reatribuir as conversas deles), e-mail de continuidade para quem saiu do chat, sincronização de modelos do WhatsApp, notificações push e e-mail, além dos workers de webhook e do agente de IA.
- **Consequência:** como quase tudo está em memória, o desenho supõe **uma única instância**. Várias réplicas duplicariam laços (SLA, atribuição, varredura) e quebrariam o tempo real.

### 2.5 E-mail: entrada, saída e threading

- **Entrada (IMAP):** usa go-imap v2 e enmime para o MIME. Faz **polling** a cada N minutos (sem IDLE), com busca por data numa janela configurável para trás. **Não depende da flag "lida"**: a deduplicação é feita pelo Message-ID já gravado. Assim, várias caixas podem ler a mesma conta e o sistema tolera reprocessar.
- **Filtros de entrada:** ignora respostas automáticas (cabeçalhos padrão de auto-submissão), detecta laço (mensagem que o próprio sistema enviou, marcada com um cabeçalho próprio) e processa e-mails de verificação de aliases (prova de posse de endereço extra).
- **Anexos:** separa inline e anexo, e reescreve imagens inline entre os formatos do editor e o "cid:" do e-mail nos dois sentidos.
- **Threading, em camadas:**
  1. **Endereço "plus"** na resposta (caixa+identificador-da-conversa@domínio): se o destinatário traz o identificador, a mensagem vai direto para a conversa. Esse caminho também serve para "promover" um visitante anônimo do chat a contato quando o e-mail confere.
  2. **In-Reply-To e References:** procura qualquer mensagem já gravada com um desses IDs.
  3. Se nada casar, cria uma conversa nova.
- **Saída (SMTP):** pool de conexões SMTP por caixa (smtppool), vários servidores possíveis com balanceamento ponderado, TLS ou STARTTLS. Monta Message-ID próprio, In-Reply-To, References acumuladas e Reply-To (com endereço plus opcional). A mensagem é renderizada dentro de um **modelo de e-mail editável** (template Go) com o histórico citado.
- **OAuth no e-mail:** suporta XOAUTH2 (Google e Microsoft) no IMAP e no SMTP, com renovação de token e recriação do pool quando o token muda. Também sinaliza na interface quando o provedor rejeita as credenciais.

### 2.6 Tempo real (websocket)

- **Hub em memória** no processo: conexões por usuário e assinaturas por conversa de dois tipos, "a lista que estou vendo" (substituída em bloco quando a lista muda) e "a conversa aberta" (uma por conexão). Toda assinatura passa por autorização: o servidor filtra os identificadores que o agente pode ver.
- **Eventos:** mensagem nova, mudança de propriedades da conversa, digitando, atualização de contato e notificações. Também é possível derrubar todas as conexões de um usuário quando ele é desativado ou perde o papel.
- **Cliente:** reconexão com backoff e ping periódico; ao reconectar, ressincroniza o que estava aberto.
- **Widget:** tem um canal websocket separado, autenticado por token de visitante, que recebe mensagens e indicador de digitação.
- **Limite:** sem pub/sub entre processos (o Redis não é usado para isso), então o tempo real só funciona com uma instância.

### 2.7 SLA e horário útil

- **Política de SLA:** tempos de primeira resposta, resolução e próxima resposta (esta opcional), em texto de duração, mais uma lista de notificações (aviso antes do prazo e alerta de estouro, com destinatários).
- **Aplicação:** a política é aplicada a uma conversa por automação ou manualmente, e gera um registro com os prazos calculados. A "próxima resposta" vira um evento separado, criado de novo a cada mensagem do cliente que espera resposta. Os prazos e o "próximo prazo" ficam denormalizados na conversa para ordenar e filtrar.
- **Cálculo do prazo:** se o horário é "sempre aberto", basta somar. Senão, percorre o tempo no **fuso configurado**, consumindo minutos só dentro do expediente de cada dia da semana e pulando feriados, com um teto de iterações para não travar em configuração ruim. O horário útil e o fuso podem vir da **equipe** atribuída, com o padrão global como reserva.
- **Avaliação:** laços periódicos marcam cumprido ou estourado e agendam as notificações numa tabela de "enviar em", processada por outro laço. Uma mudança relevante na conversa reavalia o SLA na hora, sem esperar a próxima varredura.
- **Atenção:** o prazo é fixado na aplicação. Mudar o horário útil depois não recalcula prazos já aplicados, e não há "pausar SLA" enquanto a conversa espera o cliente, além do que o status em categoria "aguardando" já cobre.

### 2.8 Automações e regras

- **Três tipos:** ao criar conversa, ao atualizar conversa (com eventos específicos: atribuição de usuário ou equipe, mudança de status ou prioridade, mensagem recebida ou enviada) e gatilho de tempo (varredura de hora em hora sobre conversas recentes, com janela configurável).
- **Estrutura da regra (JSONB):** grupos de condições com operador E/OU dentro de cada grupo e um operador entre os grupos. Cada condição tem campo, tipo de campo (conversa ou campo personalizado do contato), operador (igual, diferente, contém, não contém, começa com, maior, menor, definido, não definido) e opção de diferenciar maiúsculas. Há condições sobre o **valor anterior** do campo, para regras do tipo "mudou de X para Y".
- **Ações:** atribuir equipe ou usuário, definir status, prioridade ou SLA, adicionar, definir ou remover tags, nota privada, resposta ao cliente, enviar pesquisa de satisfação, notificar pessoas, adiar e disparar webhook.
- **Ordem:** peso das regras (ordenação por arrastar) e modo de execução por tipo: "todas que casarem" ou "só a primeira".
- **Execução:** as regras ficam em cache na memória e são recarregadas quando editadas. A avaliação é feita em Go por um pool de workers alimentado por um canal limitado. As ações rodam como o **usuário de sistema**. Há supressão temporária por conversa para evitar laços (uma ação de automação dispara um evento que redispararia a regra), e cada ação está mapeada para a permissão equivalente.
- **Atribuição automática** é um módulo separado: round-robin ponderado por equipe, que respeita disponibilidade (online, ausente) e capacidade máxima por agente, rodando a cada N minutos.

### 2.9 Permissões e papéis

- **RBAC simples:** papel é nome mais lista de permissões no formato "objeto:ação" (cerca de cem). O usuário pode ter vários papéis, e a união das permissões é carregada com ele. A checagem é só "a lista contém a string".
- **Visibilidade de conversas** em degraus que se somam a uma permissão básica de leitura: ver todas; ver as atribuídas a mim; ver as da minha equipe que ainda não têm responsável; ver todas da minha equipe; ver as sem equipe e sem responsável. O mesmo predicado é aplicado nas listas, na busca, no websocket e na mídia.
- **Permissões finas de escrita:** mudar responsável, equipe, status, prioridade e tags; responder; nota privada; escrever como contato. Há permissões de gestão por área de administração.
- **Equipes** têm horário útil, fuso, modo de atribuição e limite por agente. Macros e visões têm visibilidade "todos / equipe / só eu", garantida por CHECK no banco.
- **Registro de atividade** (login, logout, ausência, mudança de permissões do papel, exclusão ou exportação de contato) para auditoria.

### 2.10 Macros

- Uma macro combina **texto de resposta** (com variáveis de modelo) e **lista de ações** do mesmo vocabulário das automações (em JSONB).
- Tem visibilidade (todos, equipe ou usuário) e **contexto de uso**: ao responder, ao iniciar conversa ou ao escrever nota privada. Assim cada macro só aparece onde faz sentido.
- No painel, é aplicada pela paleta de comandos e pré-visualizada antes de executar. As ações passam pela checagem de permissão do agente que aplica.

### 2.11 Campos personalizados

- **Definições** numa tabela própria: nome, chave, a que se aplica (contato ou conversa), tipo de dado (texto, número, lista, data, booleano etc.), valores permitidos e **validação por expressão regular com dica**. Chave única por alvo.
- **Valores** num JSONB na própria linha do contato ou da conversa, sem tabela EAV. Aparecem nos filtros, nas visões, nas condições de automação e nas variáveis de modelo.
- O widget de chat pode pedir alguns desses campos num **formulário pré-chat**.

### 2.12 Chat no site (widget)

- **Carregamento:** um script pequeno e minificado, colado no site, cria o botão flutuante e um **iframe** com a aplicação Vue do widget servida pelo próprio binário. Os dois conversam por postMessage. O layout se adapta a celular e tem modo expandido.
- **Configuração por caixa de chat:** marca, cores e tema, mensagens de boas-vindas, formulário pré-chat (diferente para visitante e usuário identificado), restrição por domínio de origem e por IP, horário de atendimento exibido no widget, e reabertura de conversa recente em vez de criar outra.
- **Identidade:** o visitante anônimo recebe um token opaco com sessão no Redis. Para **usuários logados no site cliente**, o site gera um **JWT assinado com um segredo da caixa**, o widget troca esse JWT por uma sessão, e o contato fica verificado. Um visitante pode virar contato quando prova o e-mail (ver threading).
- **Continuidade:** se o visitante sai com resposta pendente, recebe e-mail com o histórico e pode continuar por e-mail. Também é possível baixar a transcrição.
- **Extras:** campanhas proativas (mensagem disparada por regra de página ou tempo), artigos da central de ajuda dentro do widget e entrega da conversa da IA para um humano com formulário.

### 2.13 IA

- **Provedor único** compatível com a API da OpenAI, com **URL base configurável**, ou seja, qualquer servidor compatível, inclusive local. Usa os endpoints de chat e de embeddings. Contagem de tokens local (tiktoken) para não estourar o contexto.
- **Recursos para o agente humano:**
  - prompts de reescrita (corrigir gramática, tornar mais empático, encurtar etc.), editáveis;
  - **copiloto** por conversa, com histórico próprio;
  - sugestão de perguntas frequentes a partir de conversas resolvidas.
- **Agente autônomo (assistente de IA como "usuário"):** responde conversas atribuídas a ele, num laço de chamadas de ferramenta com limite de passos e de mensagens de histórico. Fundamenta as respostas numa base de conhecimento de trechos e nos artigos da central de ajuda (RAG por embeddings), com citações. Pode chamar **ferramentas HTTP configuráveis** (com autenticação e parâmetros declarados) e há **aprovação humana** para ferramentas sensíveis. Inclui verificação de identidade por código único antes de ações sensíveis e encaminhamento para humano.
- **Base de conhecimento:** importação de URL (extração de conteúdo legível), fragmentação, impressão digital para não reprocessar o que não mudou e reconciliação periódica.

### 2.14 Autenticação

- **Login local** com senha (pode ser desativado) e limite de taxa nas rotas de autenticação.
- **OIDC genérico** (go-oidc): vários provedores cadastrados pela interface, com teste de conexão, recarga em tempo real e rejeição de e-mail vazio. O usuário precisa existir antes (não há provisionamento automático por padrão).
- **Sessões** em cookie, guardadas no Redis com índice por usuário. Isso permite derrubar todas as sessões de alguém, como ao trocar a senha ou desativar a conta, com tempo de vida configurável.
- **CSRF** pelo padrão "double submit" (cookie + cabeçalho) nas requisições que alteram estado.
- **Chave de API por usuário** (par chave/segredo) via Basic ou Token, com as mesmas permissões do usuário dono. Há também usuário de sistema para ações automáticas.

### 2.15 API e webhooks

- **API REST** sob um prefixo versionado. É a mesma API que o painel usa (não há API "pública" separada) e **não há especificação OpenAPI** no repositório; a documentação fica no site do projeto.
- **Webhooks:** cadastrados pela interface, com eventos assinados de uma lista fixa (conversa criada, atribuída, mudança de status, mensagem criada etc.). O corpo é JSON assinado com **HMAC-SHA256** e segredo cifrado no banco. Há botão de teste e toggle. A entrega usa um pool de workers com fila em memória e timeout, com **proteção contra SSRF**.
- **Limites dos webhooks:** **sem nova tentativa** após falha, **sem registro persistente de entregas**, e se a fila encher o evento é descartado.

### 2.16 Empacotamento e deploy

- **Imagem Docker mínima:** Alpine com certificados e fusos, mais o binário e o arquivo de configuração de exemplo. A imagem não compila nada: o binário vem pronto do pipeline de release.
- **Compose** com Postgres 17 e Redis 7 (portas presas ao localhost), volume para uploads e senha inicial do usuário de sistema por variável de ambiente.
- **Instalação idempotente e upgrade automático** no comando do contêiner.
- **Mídia** em disco local ou S3 (cliente S3 simples), com URLs assinadas e expiração.
- **Testes:** testes de integração do backend contra um Postgres de teste, Vitest e Cypress no frontend (componentes e E2E, incluindo o chat).

### 2.17 Frontend

- **Stack:** Vue 3 (JavaScript, sem TypeScript), Vite, pnpm workspace, Tailwind 3 com **tokens de tema em variáveis CSS** (claro e escuro), componentes no **padrão shadcn-vue** (primitivos reka-ui/radix-vue copiados para uma pasta de UI compartilhada, não importados de um pacote) e ícones lucide.
- **Bibliotecas-chave:** TipTap como editor rico (menções, tabelas, imagens, links), TanStack Table e TanStack Virtual para listas longas, vee-validate com zod para formulários (inclusive formulários gerados automaticamente por esquema), Unovis para gráficos, CodeMirror para editar HTML de modelos, sonner para avisos, VueUse, axios e mitt como barramento de eventos.
- **Estado:** Pinia, com um store por domínio (conversas, contatos, macros, visões, SLA, equipes, usuários, notificações, conexão etc.). O store de conversas é o centro: lista paginada, conversa aberta, mensagens e aplicação dos eventos do websocket.
- **Roteamento:** vue-router com áreas de caixa de entrada (minhas, não atribuídas, por equipe, por visão salva), conversa, contatos, busca, relatórios, conta e uma área de administração grande com uma rota por entidade. Há guardas por permissão.
- **Organização:** pastas por "feature" (admin, conversa, contato, relatórios, busca, SLA, visão, paleta de comandos), composables para lógica reaproveitável (rascunhos, ações em lote, filtros, upload, atalhos, inatividade, push) e um guia de design interno que define tokens e uso de componentes.
- **i18n:** vue-i18n. Os **mesmos arquivos JSON de tradução servem backend e frontend**: o painel baixa do servidor o idioma configurado ao iniciar. São 13 idiomas, incluindo pt-BR.
- **Outros:** PWA com notificação push (Web Push com chaves VAPID), atalhos de teclado com diálogo de ajuda e paleta de comandos.

---

## 3. O que levar para o PantherDesk

**Stack e forma de entrega**

1. **Binário único em Go com o frontend embutido** é uma ótima escolha para a TI de uma escola: um arquivo, um contêiner e upgrade trocando a imagem. No PantherDesk dá para fazer isso com o recurso nativo do Go de embutir arquivos, sem ferramenta externa.
2. **O mesmo binário como ferramenta de administração:** subcomandos para instalar, migrar, criar o primeiro administrador e verificar a saúde do sistema. E **recusar iniciar com migração pendente**.
3. **Postgres como única fonte de verdade.** Avaliar se o Redis é mesmo necessário: para o porte de uma escola, sessões, limite de taxa e uma fila durável cabem no Postgres (tabela de jobs com `SKIP LOCKED`, notificação com LISTEN/NOTIFY). Um serviço a menos para manter.
4. **SQL explícito por módulo** (consultas nomeadas ou um gerador tipado), sem ORM pesado. Filtros dinâmicos traduzidos de JSON para SQL só com **lista branca de campos**.
5. **Frontend Vue 3 com Vite, Pinia, vue-router e vue-i18n, Tailwind com tokens CSS e componentes no padrão shadcn-vue.** Recomendo TypeScript desde o início, que o projeto estudado não usa.

**Abordagem de domínio**

6. **Esquema com ENUMs ou CHECKs, limites de tamanho, chaves estrangeiras com política explícita, UUID público mais id interno e número de chamado legível.** JSONB para campos personalizados, regras e filtros. Denormalizar na linha do chamado o que a lista precisa (última mensagem, próximo prazo de SLA, "aguardando desde").
7. **Migrações versionadas e idempotentes**, aplicadas por subcomando e registradas no banco. Podemos usar arquivos SQL numerados (mais simples de revisar) em vez de funções por versão.
8. **Busca:** full-text do Postgres com pesos e configuração em português para KB e chamados, mais trigramas para e-mail, nome, patrimônio e substring. As regras de visibilidade precisam valer também na busca.
9. **E-mail:** dedupe por Message-ID, sem confiar na flag "lida"; threading em camadas (endereço plus com o id do chamado, depois In-Reply-To/References, depois assunto com número do chamado como reserva); ignorar respostas automáticas e detectar laço; OAuth2 para Microsoft 365 e Google, porque a escola provavelmente usa um dos dois. Preferir IMAP IDLE com polling de reserva.
10. **Saída durável:** gravar a resposta como "pendente" e deixar um worker enviar. Nunca enviar dentro da requisição HTTP. Estender a mesma durabilidade à **entrada** e aos **webhooks** (com nova tentativa, backoff e registro de entregas), que é onde o Libredesk falha.
11. **SLA:** cálculo de prazo caminhando pelo expediente no fuso da escola, com feriados (calendário letivo e recesso!) e horário por equipe. Prazos denormalizados, avaliação periódica, notificações agendadas numa tabela e reavaliação imediata em eventos. Acrescentar **pausa enquanto aguarda o solicitante**.
12. **Automações** com grupos E/OU, condições sobre o valor anterior, ordem por peso, modo "primeira que casar / todas", ações executadas como usuário de sistema e **proteção contra laço**. Esse modelo cobre bem os casos da escola (encaminhar para a equipe de redes por palavra-chave, prioridade alta para a diretoria).
13. **Permissões "objeto:ação"** agrupadas em papéis, mais os **degraus de visibilidade** (todos, da minha equipe, atribuídos a mim, sem dono), aplicados num único predicado reutilizado em lista, busca, tempo real e anexos.
14. **Macros com contexto de uso** (resposta, nota, novo chamado) e o mesmo vocabulário de ações das automações.
15. **Campos personalizados** com definição tipada e regex de validação, valores em JSONB e uso automático em filtros, automações e formulários.
16. **Tempo real** por websocket com assinatura autorizada por lista e por item, reconexão com ressincronização. Se um dia houver mais de uma instância, distribuir por LISTEN/NOTIFY do Postgres.
17. **Autenticação:** OIDC genérico (Google Workspace / Entra ID da escola), sessões revogáveis por usuário, CSRF double-submit e chaves de API por usuário com escopo. Considerar provisionamento automático por domínio de e-mail institucional.
18. **IA opcional e plugável** via API compatível com OpenAI e URL base configurável, para poder usar um modelo local ou um provedor contratado. Começar por "reescrever resposta" e "sugerir artigo da KB". Busca vetorial no Postgres (pgvector) em vez de índice em memória.
19. **Widget/portal:** iframe mais script de carga, identidade verificada por JWT assinado pelo portal da escola e continuidade por e-mail. Para a escola, provavelmente basta um **portal de abertura de chamados** autenticado por SSO; o chat ao vivo pode ficar para depois.
20. **i18n com um único catálogo** compartilhado entre backend (e-mails) e frontend, com pt-BR como idioma principal.

---

## 4. Limites e riscos observados

- **Uma instância só:** fila de entrada, automações, webhooks e notificações em canais na memória; hub de websocket sem pub/sub; índice vetorial em memória; laços periódicos sem eleição de líder. Escalar horizontalmente duplicaria trabalho e quebraria o tempo real.
- **Perda de eventos em queda ou sobrecarga:** filas em memória com tamanho fixo descartam ou perdem itens. Webhooks não têm nova tentativa nem histórico de entregas. Automações em execução no momento do desligamento podem se perder.
- **Polling agressivo do banco:** a varredura de mensagens de saída roda a cada dezenas de milissegundos, um custo constante mesmo ocioso. LISTEN/NOTIFY ou uma fila com aviso evitaria isso.
- **IMAP só por polling** (minutos de atraso, sem IDLE), com janela de releitura por data: se o sistema ficar parado mais tempo que a janela, e-mails antigos não lidos são ignorados.
- **Threading sem reserva por assunto:** se o cliente de e-mail remover In-Reply-To/References e o endereço plus não estiver ativo, a resposta vira conversa nova.
- **Busca limitada:** mensagens só por substring com trigramas (sem ranking nem radical em português); conversas só por número ou e-mail. O full-text "de verdade" existe apenas nos artigos.
- **SLA:** prazos fixados ao aplicar (mudar o expediente não recalcula), sem pausa explícita e com cálculo iterativo minuto a minuto pelo expediente.
- **Camada HTTP grande e plana** (dezenas de milhares de linhas num só pacote, com o contexto global da aplicação), dependências circulares resolvidas com setters e algumas compatibilidades legadas na configuração. A dívida tende a crescer.
- **Sem especificação OpenAPI**, API pública igual à interna e chaves de API com todas as permissões do usuário (sem escopo menor).
- **Frontend em JavaScript sem tipos**, com primitivos de duas bibliotecas de UI parecidas convivendo (migração em andamento).
- **IA restrita ao formato OpenAI;** o agente autônomo e as ferramentas HTTP ampliam a superfície de ataque (injeção de prompt levando a chamadas externas), o que exige aprovação humana e proteção contra SSRF, que o projeto implementa mas que pedem cuidado.
- **Ainda faltam** (segundo o roadmap): 2FA no login por senha, mesclagem de contatos e portal do cliente para acompanhar chamados. Para uma escola, o portal do solicitante é essencial.
- **Licença AGPL-3.0:** nada de código, SQL, textos ou arquivos pode ir para o PantherDesk. Este documento é a única ponte permitida.
