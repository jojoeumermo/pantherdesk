# Área 12 — Extensibilidade (notas comportamentais)

> Estudo clean-room para o PantherDesk. Fonte: **somente documentação pública**.
> Nada de código-fonte. Texto em palavras próprias; nomes de funções, classes,
> chaves de configuração e caminhos foram **omitidos de propósito**.
> Confiança: **documentado** / **inferido** / **A CONFIRMAR EM RUNTIME**.
> Data da pesquisa: 2026-10-26.

---

## 1. Problema

Um helpdesk precisa ser adaptado sem fork: campos próprios do negócio, regras de
formulário, automações, integrações com ferramentas (chat, CRM, issue trackers,
telefonia, armazenamento), painéis embutidos na tela do agente e, no limite,
código de terceiros rodando no servidor. As perguntas de design são:

- **O que pode ser estendido** (dados, UI, comportamento, canais, autenticação, storage)?
- **Por qual mecanismo** (configuração declarativa, script em sandbox, pacote/plugin com código, app externo via API+webhook, iframe na UI)?
- **Ciclo de vida** (instalar, ativar, configurar, atualizar, desativar, remover — e o que acontece com os dados e o schema)?
- **Isolamento** (o código de terceiro roda no mesmo processo? com quais permissões? pode quebrar upgrades?).

Os 7 projetos cobrem o espectro inteiro: desde "plugins = código PHP no mesmo
processo" (osTicket, FreeScout, UVdesk) até "apps de framework com hooks" (Frappe),
"pacotes com schema e versão de framework" (Znuny) e "extensão principalmente
externa via API + iframe" (Chatwoot).

---

## 2. Comportamento documentado por projeto

### 2.1 Zammad

| Mecanismo | Comportamento | Confiança | URL |
|---|---|---|---|
| Campos customizados ("atributos de objeto") | Em **ticket, usuário, organização e grupo**. Alterações ficam **pendentes** até o admin aplicar a atualização do banco (ou descartar); depois é **obrigatório reiniciar** o serviço — planejar janela de manutenção. Posição numérica controla ordem; registros existentes ficam vazios; **excluir é arriscado** se o atributo é referenciado — preferir desativar. Tipos de campo em página separada. | documentado | https://admin-docs.zammad.org/en/latest/system/objects.html |
| Core Workflows | Regras declarativas sobre formulários: mostrar/ocultar, tornar obrigatório/somente leitura, restringir opções de seleção, definir valores — conforme objeto, contexto (criação/edição), condições "selecionadas" (valor no formulário ainda não salvo) vs "salvas", e papéis. Avaliadas por prioridade e depois por nome. Doc alerta para comportamento inesperado da UI e recomenda testar. | documentado | https://admin-docs.zammad.org/en/latest/system/core-workflows.html |
| Gatilhos / agendadores / webhooks | Automação declarativa; webhooks são ações dessas regras (ver Área 10). | documentado | https://admin-docs.zammad.org/en/latest/manage/webhook.html |
| Integrações nativas | Telefonia (CTI genérico e provedores), identidade/clientes (LDAP/AD, Exchange, Clearbit), criptografia de e-mail (S/MIME, PGP), monitoramento (Checkmk), issue trackers (GitHub, GitLab), CMDB (i-doit), busca (Elasticsearch). Ligadas/desligadas e configuradas pelo admin. | documentado | https://admin-docs.zammad.org/en/latest/system/integrations.html |
| Pacotes (add-ons) | Área administrativa para instalar e gerenciar pacotes; **a doc pública não descreve** formato, upgrade, remoção nem isolamento. | documentado (existência) / A CONFIRMAR | https://admin-docs.zammad.org/en/latest/system/packages.html |
| Script no servidor | Nenhum mecanismo de script de usuário documentado. | inferido (ausente) | — |
| Extensão de UI | Nenhuma área de "apps" embutidas documentada. | inferido (ausente) | — |
| Isolamento | Não documentado; pacotes provavelmente rodam no mesmo processo. | inferido | — |

### 2.2 Chatwoot (edição comunitária)

| Mecanismo | Comportamento | Confiança | URL |
|---|---|---|---|
| Atributos customizados | Dois alvos: **contato** e **conversa**; tipos de exibição como texto, número, data, lista, checkbox, link; podem ir para webhooks/integrações. | documentado (oficial parcial + guia do usuário) | https://www.chatwoot.com/docs/user-guide/features/custom-attributes |
| Dashboard Apps | **Extensão de UI por iframe**: o admin registra uma URL externa que aparece como aba na tela da conversa; o app recebe contexto (conversa, contato) por **mensagem entre janelas** e pode pedir atualização do contexto enviando mensagem ao pai. Requer HTTPS e que o app permita ser emoldurado. Sem código no servidor do helpdesk. | documentado | https://www.chatwoot.com/docs/product/others/dashboard-apps/ |
| Agent Bots | Bot externo registrado com URL de saída: recebe eventos e responde via API — extensão de comportamento **fora do processo**. | documentado (parcial) | https://www.chatwoot.com/docs/webhooks |
| Webhooks + API | Ver Área 10; API "Platform" permite provisionar contas/usuários a partir de sistemas externos. | documentado | https://developers.chatwoot.com/api-reference/introduction |
| Integrações | Hub de integrações configuráveis pelo admin (ex.: Slack bidirecional, Dialogflow, Linear, CRMs). Lista exata da edição comunitária a confirmar. | documentado (parcial) / A CONFIRMAR | https://www.chatwoot.com/features/slack-integration |
| Macros / automações | Regras declarativas (evento → condições → ações). | inferido (fora do escopo das páginas lidas) | — |
| Plugins de servidor / scripts | **Nenhum sistema de plugin de código** documentado; customização de servidor = fork. | inferido | — |
| Isolamento | Forte por construção: extensões são externas (iframe, HTTP). | inferido | — |

### 2.3 FreeScout

| Mecanismo | Comportamento | Confiança | URL |
|---|---|---|---|
| Filosofia | Núcleo mínimo; quase tudo é **módulo** (gratuito ou pago) para manter o app pequeno e instalável em hospedagem compartilhada. | documentado | https://github.com/freescout-helpdesk/freescout/wiki/Development-Guide (wiki = documentação) |
| Modelo de extensão | **Sistema de hooks** com dois tipos: "ações" (executam código num ponto, sem retorno) e "filtros" (recebem um valor, alteram e devolvem). Módulo é código no mesmo processo. Front-end de módulo deve respeitar a CSP do núcleo (sem handlers inline; scripts externos precisam ser liberados). | documentado | idem |
| Catálogo | Módulos oficiais incluem campos customizados (conversa), campos de usuário, workflows, API & webhooks, rebranding, pastas, base de conhecimento, portal do cliente, CRM, comandos por e-mail, Slack, Jira, busca rápida, IA (grátis), S3 (grátis). Pagos com **licença vitalícia por instância**. | documentado | https://freescout.net/modules/ |
| Instalação | Módulos oficiais são **baixados pela própria instância** a partir do servidor do projeto (a instância precisa de acesso à internet); ativação com **chave de licença amarrada ao domínio**; atualizações também pelo painel. Módulos da comunidade: copiados para a pasta de módulos e ativados no painel. | documentado / inferido (comunidade) | https://freescout.net/modules-faq/ |
| Ambiente isolado (air-gapped) | Baixar em outra instância conectada e copiar; ativação via proxy temporário. | documentado | idem |
| Transferência de licença | Botão para desativar a licença (de qualquer instância, só com a chave). | documentado | idem |
| Remoção | Pouco documentada (desativar/excluir no painel). Efeito nos dados/tabelas não descrito. | A CONFIRMAR EM RUNTIME | idem |
| Modificar módulo | Permitido; suporte só para bugs confirmados; customização é perdida em atualização (inferido). | documentado / inferido | idem |
| Isolamento | Nenhum: mesmo processo e mesmo banco. | inferido | — |

### 2.4 osTicket

| Mecanismo | Comportamento | Confiança | URL |
|---|---|---|---|
| Formulários e campos | Formulários customizáveis anexados a **tópicos de ajuda**, tickets, usuários e organizações; formulários embutidos (contato, detalhes do ticket/tarefa, organização, empresa). Tipos: texto curto (com validadores, inclusive regex), texto longo (opcional HTML), data/hora, telefone, checkbox, escolhas (multi), upload de arquivo, quebra de seção, texto informativo, campos embutidos (prioridade, departamento, responsável) e **lista customizada**. Flags por campo: habilitado, visível, obrigatório, editável por quem, e "exigir para fechar". | documentado | https://docs.osticket.com/en/latest/Admin/Manage/Forms.html |
| Listas | Listas customizadas criadas à parte e reutilizadas por campos (widget typeahead, dropdown ou texto). | documentado | idem |
| Plugins | Instalação = **copiar o plugin para a pasta de plugins** do servidor; ele aparece no painel admin, onde é configurado (cada plugin tem suas configurações). Plugins documentados: anexos em S3, anexos em sistema de arquivos, auditoria, 2FA, políticas de senha. | documentado | https://docs.osticket.com/en/latest/Admin/Manage/Plugins.html |
| Ciclo de vida | Habilitar/desabilitar, **instâncias múltiplas de um plugin** e remoção não descritos na página. | A CONFIRMAR EM RUNTIME | idem |
| Pontos de extensão | Pelos plugins listados, inferem-se slots para **armazenamento de anexos**, **autenticação** (2FA, políticas de senha) e auditoria. | inferido | idem |
| API como extensão | Só criação de ticket + cron remoto (ver Área 10). | documentado | https://docs.osticket.com/en/latest/Developer%20Documentation/API%20Docs.html |
| Isolamento | Nenhum: código no mesmo processo. | inferido | — |

### 2.5 Znuny

| Mecanismo | Comportamento | Confiança | URL |
|---|---|---|---|
| Campos dinâmicos | Objetos: **ticket, artigo, cliente (empresa) e usuário-cliente**; tipos: checkbox, data, data/hora, dropdown, multiselect, texto, área de texto e **dropdown/multiselect alimentados por web service**. Campos de artigo não servem para busca/estatística; posicionamento em telas só configurável para campos de ticket; campos de cliente exigem mapeamento em configuração. Pacotes podem adicionar **novos tipos de campo ou objetos**. | documentado | https://doc.znuny.org/znuny/admin/dynamicfields/index.html |
| Gerenciador de pacotes | Pacotes (arquivo de pacote próprio) instalados a partir de **repositório online** (atualizar a lista antes) ou **upload**; também por linha de comando (caminho local, URL ou repositório). Upload pode ser proibido pelo admin; suporta proxy. | documentado | https://doc.znuny.org/znuny-7_2/admin/packagemanagement/index.html |
| Upgrade | Botão de atualizar a partir do repositório ou upload de versão nova. | documentado | idem |
| Reinstalar | Restaura os arquivos do pacote (inclusive arquivos marcados como modificados) **sem mexer em dados nem configurações**. | documentado | idem |
| Desinstalar | Remove funcionalidades **e apaga as tabelas criadas pelo pacote** — fazer backup e confirmar que ninguém usa. | documentado | idem |
| Saúde do pacote | Tela mostra status de instalação, status por arquivo (ausente/modificado), diff e as alterações de código e banco executadas na instalação/remoção; checksum. Metadados incluem versão de framework exigida e pacote que é substituído/mesclado. | documentado | idem |
| Ambientes | Recomenda promover pacotes testados de outra instância; customizações em área separada para sobreviver a upgrades. | documentado | idem |
| Assinatura/verificação de origem | Página atual não distingue pacotes verificados de não verificados. | A CONFIRMAR | idem |
| GenericInterface | Integrações de entrada/saída por **configuração** (transporte, mapeamento, invokers com condições), sem código na maioria dos casos (ver Área 10). | documentado | https://doc.znuny.org/doc/manual/admin/6.0/en/html/genericinterface.html |
| Automação | GenericAgent (tarefas agendadas/por evento), gestão de processos com ações de transição (inclusive executar invoker). | documentado | https://doc.znuny.org/znuny/admin/webservices/index.html |
| Isolamento | Nenhum; pacotes alteram arquivos e schema da aplicação. | inferido | — |

### 2.6 UVdesk (open source)

| Mecanismo | Comportamento | Confiança | URL |
|---|---|---|---|
| Arquitetura | Aplicação montada de pacotes (bundles): núcleo, automação, mailbox, central de suporte, API; inclui um **framework de extensões** para pacotes de terceiros. | documentado | https://packagist.org/packages/uvdesk/community-skeleton |
| Apps | Menu "Apps → Explorar apps": buscar, adicionar e salvar; apps pré-instalados aparecem ali; apps comprados na loja do fornecedor. Desativar/remover não documentado. | documentado / A CONFIRMAR | https://docs.uvdesk.com/uvdemo/apps/explore_apps.html |
| Campos customizados | **Não estão no núcleo**: app pago do fornecedor (campos em formulário de ticket, obrigatórios/dependentes). Instalação envolve descompactar e rodar comandos de configuração de extensões, assets e **migração de banco**. | documentado (página do fornecedor) | https://store.webkul.com/uvdesk-open-source-custom-fields-app.html |
| Workflows | Evento (ticket, agente, cliente) → condições (e-mail, ticket, cliente; E/OU) → ações (notificar por e-mail, atribuir, atualizar campos). Sem ação HTTP documentada. | documentado | https://docs.uvdesk.com/uvdemo/productivity/workflow.html |
| Integrações | Conectores de e-commerce (buscar pedidos), canais (Telegram, WhatsApp), apps Microsoft — majoritariamente pagos. | documentado (catálogo) | https://store.webkul.com/UVdesk/UVdesk-Open-Source.html |
| Isolamento | Nenhum; extensões são pacotes no mesmo processo com migração de schema. | inferido | — |

### 2.7 Frappe Helpdesk (Frappe Framework)

| Mecanismo | Comportamento | Confiança | URL |
|---|---|---|---|
| Apps | O Helpdesk **é** um app sobre o framework; apps são pacotes com módulos, tipos de documento (DocTypes), assets, templates e páginas. Um app é **instalado por site**; instalação cria as tabelas dos tipos de documento do app. | documentado | https://docs.frappe.io/framework/user/en/basics/apps |
| Hooks | Arquivo de hooks do app permite se ligar a eventos do framework, **estender ou sobrescrever** comportamento padrão, inclusive eventos de documentos de outros apps. Hooks de ciclo de vida: antes/depois de instalar, desinstalar e migrar. | documentado | https://docs.frappe.io/framework/user/en/python-api/hooks |
| Upgrade | Migração aplica alterações de schema e **patches** de dados listados, cada um executado uma única vez, em ordem. | documentado | https://docs.frappe.io/framework/user/en/basics/apps |
| Customize Form / campos customizados | Sobrescrever propriedades de um tipo de documento e **adicionar campos customizados pela UI**, sem alterar o tipo original (gravado como objetos de customização separados). | documentado | https://docs.frappe.io/framework/user/en/basics/doctypes/customize |
| Server Scripts | Python **em sandbox restrito** (biblioteca de Python restrito + lista de métodos permitidos). Tipos: evento de documento (antes/depois de inserir, validar, salvar, enviar, cancelar, excluir…), **endpoint de API** (com acesso convidado opcional e rate limit por IP), e outros. **Desligados por padrão desde a v15**, habilitáveis por configuração do servidor; proibidos em hospedagem compartilhada; só papel de gerente do sistema cria/edita. | documentado | https://docs.frappe.io/framework/user/en/desk/scripting/server-script |
| Client Scripts | JavaScript no navegador ligado a um tipo de documento (eventos do formulário); validações de client script não valem para API — para isso, server script. | documentado | https://docs.frappe.io/framework/user/en/desk/scripting/client-script |
| Webhooks | Por tipo de documento + evento (ver Área 10). | documentado | https://docs.frappe.io/framework/user/en/guides/integration/webhooks |
| Isolamento | Apps: nenhum (mesmo processo). Server scripts: sandbox de linguagem, desativado por padrão por causa do risco em ambientes compartilhados. | documentado (scripts) / inferido (apps) | idem |
| Desinstalação | Hooks de desinstalação existem; efeito sobre dados/tabelas não descrito nas páginas lidas. | A CONFIRMAR EM RUNTIME | hooks |

---

## 3. Tabela comparativa

| Aspecto | Zammad | Chatwoot | FreeScout | osTicket | Znuny | UVdesk | Frappe HD |
|---|---|---|---|---|---|---|---|
| Campos custom no núcleo | sim (ticket, usuário, org, grupo) | sim (contato, conversa) | **não (módulo pago)** | sim (formulários) | sim (ticket, artigo, cliente, usuário-cliente) | **não (app pago)** | sim (Customize Form, qualquer tipo) |
| Mudança de schema ao criar campo | sim + restart | inferido não | ? | inferido não (EAV) | inferido não | sim (migração) | sim (coluna) |
| Regras de formulário | Core Workflows | não | via módulo | flags por campo | ACL/telas (fora do escopo) | não | client script |
| Automação declarativa | gatilhos/agendador | macros/automação | módulo Workflows | filtros (inferido) | GenericAgent/processos | workflows | regras + server script |
| Script no servidor | não | não | não | não | não (só pacote) | não | **sim, sandbox, off por padrão** |
| Plugin com código | pacotes (pouco doc.) | **não** | módulos (hooks ações/filtros) | plugins (pasta) | pacotes (repo/upload) | bundles/apps | apps (hooks) |
| Instalação | painel | — | download pela instância + licença | copiar pasta | repo, upload, CLI | descompactar + comandos | linha de comando por site |
| Upgrade | ? | — | painel | manual | painel/CLI | manual + migração | migração + patches |
| Remoção apaga dados | ? | — | ? | ? | **sim (tabelas)** | ? | ? |
| Verificação de integridade | ? | — | licença | não | **status por arquivo + diff** | não | não doc. |
| Extensão de UI | não doc. | **iframe c/ contexto** | módulos (mesmo app) | plugins | pacotes | apps | client scripts / páginas |
| Bots externos | não | **Agent Bots** | não | não | não | não | não |
| Isolamento | nenhum (inf.) | **externo (HTTP/iframe)** | nenhum | nenhum | nenhum | nenhum | sandbox p/ scripts; nenhum p/ apps |
| Marketplace | não | não | sim (pago) | não (comunidade) | repositórios | loja do fornecedor | marketplace do framework (inf.) |

---

## 4. A CONFIRMAR EM RUNTIME (mapeado aos cenários)

| Cenário | Projeto | O que observar |
|---|---|---|
| X-01 | todos | Inventário real na versão de imagem testada: quais mecanismos aparecem no painel admin (campos, regras, integrações, pacotes/módulos/apps, scripts). Registrar ausência como evidência. |
| X-01 | Zammad | Tipos de atributo disponíveis; se criar atributo exige mesmo restart no container; existência e conteúdo da tela de pacotes. |
| X-01 | Chatwoot | Lista de integrações na edição comunitária; dados enviados ao Dashboard App (forma do contexto); tipos de atributo. |
| X-01 | FreeScout | Quais módulos gratuitos estão disponíveis sem licença; se a lista de módulos carrega no lab sem internet (provável **não** → registrar). |
| X-01 | osTicket | Pontos de extensão por plugin visíveis (auth, storage, auditoria); armazenamento dos campos (sem alteração de schema?). |
| X-01 | Znuny | Repositórios padrão; tipos de campo dinâmico; existência de verificação de pacotes. |
| X-01 | UVdesk | O que "Explorar apps" mostra no open source sem compra. |
| X-01 | Frappe HD | Server scripts desligados por padrão na imagem? Custom field em ticket do helpdesk aparece na UI do agente (front-end próprio do Helpdesk) ou só na UI genérica do framework? |
| X-02 | FreeScout | Instalar um módulo gratuito (ex.: armazenamento S3 ou IA) — ativar, desativar, excluir; ver se tabelas/configs ficam. |
| X-02 | osTicket | Instalar plugin oficial (ex.: anexos em filesystem) — habilitar, criar instância, desabilitar, remover. |
| X-02 | Znuny | Instalar pacote gratuito (ex.: FAQ ou time accounting) por upload/repositório; upgrade; reinstalar; desinstalar e confirmar remoção de tabelas. |
| X-02 | Frappe HD | Instalar/desinstalar um app de exemplo num site; efeito em dados; migração. |
| X-02 | Zammad | Se houver pacote gratuito disponível, observar o ciclo; senão, N/A. |
| X-02 | Chatwoot, UVdesk | Chatwoot: registrar Dashboard App e Agent Bot (ciclo = criar/editar/remover). UVdesk: N/A se não houver app gratuito. |

---

## 5. Recomendação preliminar para o PantherDesk

MVP = **REST API + webhooks** (Área 10). Plugins de código ficam no roadmap. Mas
alguns **"seams" (costuras) precisam existir desde o primeiro dia**, porque
retrofitá-los custa caro:

**Desenhar já (MVP)**
1. **Campos customizados declarativos** em ticket, usuário e organização, com tipos básicos (texto, número, data, booleano, lista simples/múltipla), sem alterar schema em tempo de execução (armazenamento em coluna JSON indexável ou tabela de valores), sem restart (anti-padrão Zammad). Exclusão = arquivar (soft) para não quebrar regras/relatórios. Expostos na API, nos filtros, nos webhooks e nas automações.
2. **Barramento interno de eventos de domínio** (ticket criado/atualizado/atribuído, mensagem criada, etc.) com payload versionado — a mesma fonte alimenta webhooks, automações, auditoria e, no futuro, plugins. É a costura mais importante.
3. **Outbox transacional + worker** de entrega (já exigido pelos webhooks) — futuras integrações e plugins assíncronos reutilizam.
4. **Tokens de API com escopos** e a noção de "principal de integração" (um app/integração identificado, não só um usuário) — facilita bots e apps externos no estilo Chatwoot (Agent Bots).
5. **Interfaces de provedor substituíveis** (ports/adapters) nos pontos que todos os projetos acabaram abrindo para plugins: **armazenamento de anexos** (local/S3), **autenticação** (local, depois SSO/LDAP), **canais de entrada/saída** (e-mail primeiro). No MVP só uma implementação cada, mas atrás de interface.
6. **Automação declarativa simples** (evento → condições → ações), incluindo a ação "chamar webhook" — cobre a maior parte do que se faz com plugins nos concorrentes.

**Roadmap curto (pós-MVP)**
7. **Extensão de UI por iframe** com contrato de contexto por mensagens entre janelas (modelo Chatwoot): baixo risco, isolamento natural, zero código no servidor. Definir desde já um **registro de apps** (nome, URL, escopos, onde aparece).
8. **Regras de formulário** (mostrar/ocultar/obrigatório por condição) sobre os campos customizados.

**Roadmap longo (plugins com código) — premissas a manter**
9. Preferir **extensão fora do processo** (apps externos via API + eventos + iframe) a plugins in-process. Se houver scripts no servidor, só com **sandbox real** (processo/WASM isolado, limites de CPU/memória/tempo, sem rede por padrão) e **desligados por padrão** (lição do Frappe).
10. Ciclo de vida explícito com manifesto: versão, compatibilidade com a versão do núcleo, permissões declaradas, migrações versionadas, **verificação de integridade/assinatura** (ponto forte do Znuny), e semântica clara de remoção: "desativar" preserva dados; "remover" pede confirmação e informa que apaga dados (Znuny documenta isso; os demais não).
11. Evitar dependência de rede para instalar/ativar (FreeScout exige internet + licença por domínio — ruim para self-hosted isolado).

**Não fazer**: hooks arbitrários "ações/filtros" no mesmo processo sem contrato (FreeScout/osTicket/UVdesk) — quebram em todo upgrade e não têm isolamento.
