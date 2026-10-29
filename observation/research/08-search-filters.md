# Área 8 — Busca e filtros

> Pesquisa clean-room: apenas documentação pública oficial, palavras próprias.
> Sem código-fonte, sem strings de UI, sem chaves de configuração.
> Confiança: **documentado** / **inferido**. Pesquisa feita em 2026-10-26.

## 1. Problema

O agente precisa achar tickets por qualquer pedaço de texto (assunto, corpo das
mensagens, eventualmente anexos e dados do contato) e montar listas de trabalho
filtradas e ordenadas (estado + grupo + dono + data), salvando-as como visões.
Decisões de projeto:

- o motor: banco relacional (PostgreSQL) ou índice externo (Elasticsearch,
  Meilisearch, RediSearch)?
- escopo do índice: assunto, corpo, anexos, contatos, organizações?
- sintaxe: texto livre só, ou operadores (campo:valor, E/OU/NÃO, curingas,
  intervalos de data)?
- normalização de acento e caixa ("conexão" = "conexao");
- latência de indexação (síncrona vs assíncrona);
- visões salvas: pessoais, compartilhadas, por papel; ordenação.

## 2. Comportamento documentado por projeto

### 2.1 Zammad

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Motor | Elasticsearch é **opcional mas fortemente recomendado**. Sem ele o Zammad funciona, mas a busca fica lenta e muito limitada. ES serve para: busca mais rápida, recursos avançados como relatórios, e busca dentro do conteúdo de anexos de e-mail. Banco suportado: PostgreSQL. | https://docs.zammad.org/en/latest/prerequisites/software.html | documentado |
| Escopo indexado | Tickets (título, número, tags, estado, prioridade, dono, cliente, organização, grupo, datas, campos de SLA), mensagens (corpo em texto puro, assunto, remetente, destinatários, cópia, flag interno), usuários, organizações, grupos, logs de telefonia, sessões de chat. Campos customizados entram. Datas em UTC. | https://docs.zammad.org/en/latest/install/elasticsearch/indexed-attributes.html | documentado |
| Anexos | Nome do arquivo e conteúdo do arquivo pesquisáveis; filtro por tipo MIME. | https://user-docs.zammad.org/en/latest/advanced/search.html | documentado |
| Sintaxe | Estilo Lucene: campo:valor (inclusive campos aninhados como dados do cliente ou da mensagem), frases entre aspas, E / OU, parênteses, negação, curinga, busca aproximada (fuzzy), expressões regulares, intervalos numéricos e de data, datas relativas ("agora menos 1 hora"). Busca no título com várias palavras faz E entre elas. | user-docs search | documentado |
| Acento / caixa | Não documentado (depende do analisador do ES). | — | A CONFIRMAR (S-03) |
| Latência | Não documentada na doc oficial; indexação é feita por trabalho em segundo plano (inferido pela existência de reconstrução do índice). | — | inferido — A CONFIRMAR (S-04) |
| Visões salvas | "Overviews": listas definidas pelo admin com condições combináveis, colunas, ordenação e agrupamento; atribuídas a papéis (e opcionalmente usuários); valem também para clientes. Colunas/ordenação são as mesmas para todos que veem a visão; o usuário só pode reordenar a lista de visões. Limite de ~2.100 itens por visão; recomendação de 15–20 visões no total. | https://admin-docs.zammad.org/en/latest/manage/overviews.html | documentado |
| Busca salva pessoal | Não documentada na página de busca. | — | A CONFIRMAR (S-02) |
| Permissão | Resultados respeitam a permissão do usuário sobre o ticket. | overviews | documentado |

### 2.2 Chatwoot (edição comunitária)

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Busca global | Conversas (conteúdo da mensagem, assunto, número), contatos (nome, e-mail, telefone, identificador) e artigos do Help Center. | https://www.chatwoot.com/hc/user-guide/articles/1677237449-lesson-3-b-mastering-core-features | documentado |
| Motor | Não documentado. Filtros avançados de mensagem (por remetente, caixa, período) anunciados como recurso de **planos pagos**, inclusive auto-hospedado. | https://www.chatwoot.com/blog/advanced-search | documentado (restrição) / motor A CONFIRMAR |
| Sintaxe | Não documentada (texto livre). | — | inferido |
| Filtros | Filtro de conversas com atributo + operador (igual, diferente, presente, ausente) + valor. Combinação E/OU não documentada. | https://www.chatwoot.com/hc/user-guide/articles/1677698771-group-chats-with-filters-save-as-folders | documentado |
| Visões salvas | Filtro salvo vira "pasta" na barra lateral; pode ser apagado. Se é pessoal ou compartilhado não está claro. Contatos têm o equivalente ("segmentos"). | idem ; https://www.chatwoot.com/hc/user-guide/articles/1677748953-group-your-contacts-using-filters-and-save-them-as-custom-segments | documentado / A CONFIRMAR |
| Ordenação | Última atividade, data de criação, prioridade (urgente→baixa, sem prioridade no fim), e "aguardando resposta" (quem espera há mais tempo primeiro). | https://www.chatwoot.com/hc/user-guide/articles/1740546374-how-does-sorting-work | documentado |
| Acento / latência | Não documentados. | — | A CONFIRMAR (S-03, S-04) |

### 2.3 FreeScout

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Motor (núcleo) | Busca padrão no banco de dados. Em volumes grandes pode ficar lenta ou expirar; a FAQ sugere CPU melhor ou o módulo pago de busca rápida. | https://github.com/freescout-help-desk/freescout/wiki/FAQ | documentado |
| Escopo / particularidades | Resultados incluem conversas excluídas por padrão (filtrar por estado). Busca por número com prefixo cerquilha. | idem | documentado |
| Módulo pago de busca rápida | Usa **Meilisearch** externo; indexa threads (mensagens do cliente, respostas e notas) em segundo plano via cron; novas conversas aparecem em segundos a 1 minuto; indexação inicial de minutos a horas. Várias palavras = qualquer uma delas (OU); casamento parcial dentro da palavra por padrão; aspas forçam correspondência exata. Sem busca em campos de cliente. Se o Meilisearch cair, volta para a busca padrão. | https://freescout.net/module/faster-search/ | documentado |
| Anexos | Busca por anexos aparece no catálogo de módulos. | (catálogo, via busca) | inferido |
| Visões salvas | Núcleo tem pastas fixas (minhas, não atribuídas, fechadas, etc.). Pastas customizadas por condição (tag, estado, dono) são módulo pago e exigem o módulo de tags. | https://freescout.net/module/custom-folders/ ; FAQ | documentado |
| Acento / sintaxe do núcleo | Não documentados. | — | A CONFIRMAR (S-03) |

### 2.4 osTicket

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Busca avançada | Critérios sobre dados do ticket, usuário, organização e formulários. Busca pode ser salva com nome e editada; colunas customizáveis (renomear, escolher quais são ordenáveis); filtros rápidos definidos pelo admin. | https://docs.osticket.com/en/latest/Agent/Tickets/Advanced%20Search.html ; https://docs.osticket.com/en/latest/Guides/Data%20Extraction%20Guide.html | documentado |
| Filas pessoais | Agente cria filas pessoais com colunas e filtros rápidos. | https://docs.osticket.com/en/latest/Agent%20Panel.html | documentado |
| Escopo textual / sintaxe / motor | Não documentados (se busca no corpo/anexo, operadores, uso de full-text do MySQL). | — | A CONFIRMAR (S-01, S-03) |
| Exportação da busca | Resultado da fila/busca exportável em CSV (só metadados do cabeçalho). | Data Extraction Guide | documentado |

### 2.5 Znuny

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Entrada | Busca de tickets no menu, barra de busca de texto completo (se configurada) ou link nas visões. Padrão é texto completo, refinável por atributos. | https://doc.znuny.org/znuny/agentinterface/ticketviews/agentticketsearch/index.html | documentado |
| Perfis | Perfis de busca salvos, recarregáveis, atualizáveis e com link direto (marcador). | idem | documentado |
| Operadores | Curinga, OU, E, agrupamento com parênteses, exclusão — valem em todos os campos de texto quando condições estendidas estão ligadas (padrão para agentes). | idem | documentado |
| Exportação | Resultado em tela, PDF, CSV ou XLSX (campos exportados configuráveis). | idem | documentado |
| Motor | Busca no banco; existe um projeto oficial separado de integração com Elasticsearch (exige ES 7+), não coberto pela doc principal. | (resultado de busca sobre projeto oficial; não lido) | inferido — A CONFIRMAR |
| Cliente | Cliente busca seus tickets, salva modelos e exporta. Escopo (próprios vs empresa) não documentado. | https://doc.znuny.org/znuny/customerinterface/searching_tickets/index.html | documentado / A CONFIRMAR |
| Acento / latência / anexos | Não documentados. | — | A CONFIRMAR |

### 2.6 UVdesk

Nada sobre busca ou filtros em docs.uvdesk.com (a navegação não tem seção).
Tudo **A CONFIRMAR EM RUNTIME** (S-01..S-04). Fonte: https://docs.uvdesk.com/

### 2.7 Frappe Helpdesk

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Visões | Quatro visões padrão (SLA vencendo, meu feedback, atribuídos recentemente, pendentes) — ocultáveis, não apagáveis. Visões customizadas guardam filtros + ordenação + colunas. Tipos: padrão do usuário, pública (só gestor de agentes cria/edita), salva pessoal, privada fixada na lateral. Valor especial "eu" no filtro de atribuído permite uma visão pública que mostra a cada agente os seus tickets. Cliente salva visões privadas no portal. | https://docs.frappe.io/helpdesk/custom-views | documentado |
| Busca na KB | Depende de RediSearch no Redis; sem ele não há resultado. | https://docs.frappe.io/helpdesk/knowledge-base | documentado |
| Busca de tickets (texto livre) | Não documentada. | — | A CONFIRMAR (S-01) |
| Exportação | Não documentada no Helpdesk. | — | A CONFIRMAR |

## 3. Tabela comparativa

| Aspecto | Zammad | Chatwoot CE | FreeScout | osTicket | Znuny | UVdesk | Frappe |
|---|---|---|---|---|---|---|---|
| Motor | ES opcional (degradado sem) | não doc. | BD; Meilisearch (pago) | não doc. | BD (ES via projeto separado?) | não doc. | RediSearch (KB) |
| Corpo da mensagem | sim | sim | sim | ? | sim (texto completo) | ? | ? |
| Conteúdo de anexo | sim (com ES) | não doc. | módulo? | ? | ? | ? | ? |
| Contatos | via atributos do ticket; usuários indexados | sim | não (no módulo rápido) | por critério | por atributo | ? | ? |
| Operadores | Lucene completo | não | aspas (módulo) | critérios estruturados | E/OU/NÃO/curinga | ? | filtros estruturados |
| Acento/caixa | ? | ? | ? | ? | ? | ? | ? |
| Latência | assíncrona (inferido) | ? | 1 s–1 min (módulo) | ? | ? | ? | ? |
| Visões salvas | admin, por papel | pastas | pastas (pago) | buscas salvas + filas pessoais | perfis de busca | ? | pessoais + públicas |
| Ordenação | por visão (fixa p/ todos) | 4 modos | ? | colunas ordenáveis | ? | ? | salva na visão |
| Exportar resultado | (ver Área 11) | ? | módulo pago | CSV | PDF/CSV/XLSX | ? | ? |

## 4. A CONFIRMAR EM RUNTIME (mapeado aos cenários)

| Cenário | Projeto(s) | O que confirmar |
|---|---|---|
| S-01 | Zammad | com e sem ES: palavra só no corpo é achada? conteúdo de anexo (PDF/DOCX) só com ES? |
| S-01 | osTicket, UVdesk, Frappe, Chatwoot | se o corpo das mensagens é pesquisado; se notas internas entram no resultado (e se cliente consegue achá-las — cruzar com P-03) |
| S-01 | FreeScout | busca do núcleo encontra texto do corpo? conversas excluídas aparecem? |
| S-02 | Zammad | combinação estado+grupo+dono+data em overview e na busca; existe busca salva pessoal? |
| S-02 | Chatwoot | pastas: pessoais ou da conta? E/OU entre condições? |
| S-02 | osTicket | buscas salvas: pessoais ou compartilháveis? |
| S-02 | Frappe | visão pública com valor "eu" funcionando por agente |
| S-03 | **todos** | "conexão" vs "conexao" e maiúsculas — nenhuma doc trata; teste obrigatório |
| S-04 | Zammad | tempo entre criar ticket e aparecer na busca (trabalho em segundo plano) |
| S-04 | FreeScout | núcleo (deve ser imediato) vs módulo Meilisearch (segundos a 1 min, se disponível) |
| S-04 | demais | idem |

## 5. Recomendação preliminar para o MVP (simples e correto)

1. **PostgreSQL full-text basta para o MVP.** Nenhum dos projetos exige motor
   externo para a funcionalidade básica; os que usam (Zammad/ES, FreeScout/Meili,
   Frappe/RediSearch) pagam com complexidade operacional, latência assíncrona e
   modos de falha (Frappe: sem RediSearch a busca simplesmente não retorna nada).
2. **Esquema sugerido**: uma coluna tsvector por mensagem (corpo em texto puro) e
   por ticket (assunto com peso maior), mantida **na mesma transação** da escrita
   (coluna gerada ou trigger) → busca imediatamente consistente (S-04 = 0). Índice
   GIN. Consulta agrega por ticket.
3. **Normalização**: configuração de busca baseada em português + extensão
   unaccent (dicionário encadeado), garantindo "conexão" = "conexao" e
   insensibilidade a caixa (S-03). Para nomes/e-mails/números de ticket, usar busca
   por prefixo/igualdade em colunas normais e índice trigram (pg_trgm) para
   substring de e-mail.
4. **Escopo do MVP**: assunto, corpo das mensagens, nome/e-mail do solicitante,
   número do ticket. **Anexos: roadmap** — exige extração de texto assíncrona
   (fila de trabalho), que quebraria a garantia de consistência imediata.
5. **Segurança**: a busca aplica as mesmas regras de permissão das listas (grupo
   do agente); notas internas nunca entram em busca feita no portal do cliente.
6. **Sintaxe**: texto livre com aspas para frase e prefixo "-" para excluir
   (o que a função de consulta "estilo web" do Postgres já oferece). Operadores
   campo:valor ficam para a camada de filtros estruturados, não para a caixa de
   texto.
7. **Filtros e visões**: filtros estruturados (estado, grupo, dono, solicitante,
   organização, prioridade, tag, intervalo de criação/atualização) combinados por
   E; visões salvas **pessoais** e **compartilhadas por grupo/papel**, cada visão
   guardando filtros + ordenação + colunas (modelo Frappe/osTicket). Incluir o
   valor dinâmico "eu" para dono. Visões padrão: minhas abertas, não atribuídas,
   do meu grupo, aguardando cliente.
8. **Ordenação**: criação, última atualização, prioridade, e "aguardando
   resposta há mais tempo" (modelo Chatwoot) — esta última é muito útil e barata
   se o ticket tiver o carimbo da última mensagem do cliente.
9. **Gatilho para migrar a motor externo (roadmap)**: busca em anexos, fuzzy,
   relevância multi-idioma ou volume em que o GIN não atenda. Desenhar a busca
   atrás de uma interface para trocar o backend sem mexer na API.
