# Estudo de fonte — outros projetos (varredura rápida)

Data: 2026-10-29. Lado "sujo" do muro clean-room: só conhecimento abstrato. Não há trechos de código, nomes de identificadores, arquivos, caminhos, tabelas nem textos de interface copiados. Os repositórios foram clonados raso (só para leitura, sem build nem execução) em um diretório temporário fora do projeto.

---

## 1. Peppermint (Peppermint-Lab/peppermint)

- **Licença:** o arquivo de licença da raiz é **misto e ambíguo**. Ele declara copyright da empresa mantenedora e diz que o conteúdo "dentro do diretório do repositório" está sob uma *licença comercial*, mas não define essa licença e a referência é circular (aponta para o próprio repositório). Diz ainda que o restante fica sob **AGPLv3**, cujo texto integral vem em seguida. O subprojeto de frontend traz o texto da AGPLv3. O subprojeto de API traz um MIT de terceiro, aparentemente herdado de um template. Por isso o GitHub mostra a licença como "não identificada". **Conclusão:** trate como AGPLv3 ou comercial, ou seja, só como inspiração; nada pode ser reaproveitado.
- **Stack:** monorepo TypeScript; API em Node com Fastify e Prisma sobre PostgreSQL; cliente em Next.js/React com Tailwind e shadcn; i18n; Docker e PM2.
- **Ideia central:** helpdesk interno ou de serviço com chamados, portal do solicitante, filas de e-mail (IMAP) que viram chamados, base de conhecimento ou "notebook", webhooks e SSO (OAuth, OIDC e SAML).
- **Ideias aproveitáveis:**
  1. **E-mail de resposta vira comentário limpo.** Ao ingerir uma resposta por e-mail, o sistema descarta o texto citado, a assinatura e os trechos ocultos, e grava só a parte nova. Isso evita que a conversa do chamado fique poluída.
  2. **Permissões granulares no formato "recurso + ação"** (chamado: criar, ler, atribuir, transferir, comentar; e o mesmo padrão para usuários, equipes, KB, configurações e apontamento de horas), agrupadas em papéis. É um bom modelo para separar técnico, coordenador e secretaria.
  3. **Flags simples no chamado:** *oculto* (some das listas sem ser apagado), *travado* (não aceita novas edições), *seguidores* (quem recebe notificação sem ser o responsável) e *chamados vinculados*. São baratas de implementar e muito úteis no dia a dia.
  4. **Paleta de comandos com atalho de teclado** (Ctrl/Cmd+K) para navegar e criar chamados, além de uma lista específica para celular.
  5. **Tipo do chamado separado do status** (incidente, solicitação de serviço, manutenção, acesso, feedback etc.) e apontamento de tempo por chamado.
- **Antipadrões a evitar:** credenciais padrão fracas na instalação e verificação de certificado TLS desligada na conexão IMAP.

## 2. Gerev (GerevAI/gerev)

- **Licença:** MIT (2023, Gerev Inc.). Projeto aparentemente parado desde o fim de 2023.
- **Stack:** Python com FastAPI, SQLAlchemy/SQLite e Alembic; busca com BM25 e índice vetorial FAISS; modelos sentence-transformers (bi-encoder e cross-encoders) e um modelo de QA extrativo; UI em React; conectores para Slack, Confluence, Jira, Google Drive, GitLab, Mattermost, RocketChat e BookStack. Envia telemetria por padrão.
- **Ideia central:** busca corporativa "para o pessoal do help desk", que indexa conversas e documentos de várias fontes e devolve o *trecho* que responde à pergunta.
- **Ideias aproveitáveis:**
  1. **Busca híbrida em cascata:** junta candidatos da busca lexical (BM25) com os da busca semântica (embeddings), reordena com um modelo pequeno e depois com um maior sobre poucos candidatos. Na CPU, os números de candidatos são bem menores. Esse padrão serve para a KB e para "chamados parecidos" do PantherDesk.
  2. **Indexar por parágrafo, não por documento.** Parágrafos curtos são agrupados até um tamanho mínimo, e o título do documento é anexado ao texto antes de gerar o embedding, o que melhora a relevância.
  3. **Destacar a frase-resposta** dentro do parágrafo (QA extrativo) e mostrar só um pequeno contexto depois dela.
  4. **Link profundo com âncora de texto:** o resultado abre a página original já rolada até o trecho, usando o recurso de fragmento de texto dos navegadores.
  5. **Conectores plugáveis com indexação incremental em segundo plano**, por meio de uma fila. É uma boa arquitetura para futuramente indexar Google Drive/Classroom da escola.
- **Cuidado:** desligar a telemetria e ponderar o custo de rodar modelos no servidor da escola. Os mesmos ganhos podem vir de BM25 com embeddings leves.

## 3. mayasrl/helpdesk

- **Licença:** **nenhum arquivo de licença**; o manifesto do pacote declara ISC, mas isso não vale como licença do repositório. Juridicamente fica como "todos os direitos reservados", então serve só para olhar ideias.
- **Stack:** Node/Express, Prisma e PostgreSQL, JWT; frontend React com Vite, Tailwind, shadcn, Recharts e validação de formulários com esquema.
- **Ideia central:** projeto de curso com três perfis (admin, técnico, cliente), três status (aberto, em andamento, fechado), catálogo de serviços com preço somado no chamado e um dashboard por perfil.
- **Ideias aproveitáveis:**
  1. **Catálogo de serviços** ligado ao chamado (o chamado pode ter vários itens de serviço). Para a escola, sem preço: tipos de atendimento padronizados (troca de toner, reset de senha, empréstimo de projetor).
  2. **Horários de disponibilidade por técnico**, para atribuir chamados ou agendar visitas à sala.
  3. **Dashboard diferente para cada perfil.**
- Fora isso, nada além do básico.

## 4. AugustoMello09/Help-Desk

- **Licença:** MIT (2023).
- **Stack:** Java 17 com Spring Boot 3, Spring Security e JWT, MySQL, testes JUnit 5, OpenAPI/Swagger; frontend Angular; deploy na AWS (S3, Elastic Beanstalk, RDS).
- **Ideia central:** CRUD mínimo de chamados entre cliente e técnico. O técnico "aceita" o chamado, que passa a "em andamento", e depois o fecha; cada transição dispara um e-mail ao cliente.
- **Ideias aproveitáveis:**
  1. **Registrar o resultado de cada envio de e-mail** (enviado ou erro) junto ao evento. Isso permite auditar e reenviar notificações que falharam.
  2. **Passo explícito de "aceitar" o chamado**, para que o solicitante saiba que alguém assumiu.
  3. **Documentação da API gerada automaticamente** (OpenAPI).
- O restante não é relevante.

## 5. JohnPetros/tech-guardian

- **Licença:** MIT (2023).
- **Stack:** Node com renderização no servidor por templates EJS, Knex e PostgreSQL, Jest, webpack, PM2.
- **Ideia central:** papéis "quem relata" e "quem resolve" mais o admin, com chamados ligados a um **patrimônio** (ativo) da empresa.
- **Ideias aproveitáveis:**
  1. **Chamado vinculado a um patrimônio** (cadastro de ativos administrado pelo admin), com filtro por patrimônio. Para a escola: número de patrimônio do equipamento ou da sala.
  2. **Regras de transição explícitas e boas de copiar como especificação:** só fecha se houver solução registrada; só reabre se estiver fechado; só quem abriu pode fechar ou reabrir; não se aceita solução em chamado fechado.
  3. **Requisitos escritos como checklist "deve/não deve"**, um formato bom para os critérios de aceite das specs do PantherDesk.
  4. **Filtros combináveis** (título, patrimônio, data, status) com paginação.
- O README anuncia uma seção de acessibilidade, mas ela não existe, e o código quase não usa atributos de acessibilidade.

## 6. Tópicos do GitHub (só listagem, sem clonar)

Fontes: tópico *helpdesk-tools* (38 repositórios) e tópico *helpdesk* filtrado por HTML e ordenado por atualização (91 repositórios); só as primeiras páginas foram vistas. Os itens a seguir se destacam como **ideias**; não foram verificados em código nem quanto à licença.

- **yuki-kat/it-ticket-board:** quadro de service desk com cronômetro de SLA visível, escalonamento e inventário de ativos na mesma tela. A ideia é mostrar o tempo restante do SLA no próprio cartão do chamado.
- **derbaroser-eng/support-triage:** classificador **baseado em regras** (sem IA) que separa mensagens em bug, pedido, urgente ou ruído. Serve para fazer a triagem inicial de e-mails da escola de forma barata e explicável.
- **MiguelCarino/Desk:** biblioteca de **respostas prontas** pesquisável, com cópia em um clique.
- **KevinZelman/process-tree:** **árvore de decisão interativa de triagem** que guia o atendente até a categoria certa e o texto do chamado. Útil para estagiários e monitores.
- **jeffcaldwellca/LDAPFrontOffice** e **yvnggodemis/Chimera:** ferramentas que deixam pessoas não técnicas fazer tarefas pontuais de diretório (atualizar atributos, desbloquear conta) com escopo limitado. É uma ideia para o futuro: ações de autoatendimento seguras ligadas ao Google Workspace ou ao AD da escola.
- Também aparecem dashboards de SLA e tendências (Smart-support-analytics-dashboard) e conversão de e-mail em chamado com IA local (mehwetpolat/Ticket-Service).

---

## Top ideias para o PantherDesk

1. **Busca híbrida (lexical + semântica) por parágrafo, com destaque do trecho-resposta e link profundo**, para a KB e para sugerir "chamados parecidos" ao abrir um novo. (Gerev)
2. **Ingestão de e-mail que guarda só a parte nova da resposta**, sem citação nem assinatura, e registra o resultado de cada notificação enviada (enviado ou erro) para permitir reenvio. (Peppermint, AugustoMello09)
3. **Permissões "recurso + ação" agrupadas em papéis** (técnico, coordenação, secretaria, solicitante). (Peppermint)
4. **Chamado vinculado ao patrimônio ou à sala**, com histórico por equipamento. (tech-guardian)
5. **Máquina de estados com regras explícitas** (aceitar → em andamento; fechar exige solução; reabrir só se fechado e só pelo autor ou pela equipe) e critérios de aceite escritos como checklist "deve/não deve". (tech-guardian, AugustoMello09)
6. **Flags leves no chamado:** seguidores, vinculados, travado e oculto (sem apagar); e o tipo do chamado separado do status. (Peppermint)
7. **Triagem sem IA:** regras de classificação de e-mails, árvore de decisão para atendentes e respostas prontas pesquisáveis. (tópicos)
8. **SLA visível no cartão do chamado**, com paleta de comandos (Ctrl/Cmd+K) e catálogo de serviços padronizados. (tópicos, Peppermint, mayasrl)
