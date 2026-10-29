# Área 11 — Relatórios e métricas

> Pesquisa clean-room: apenas documentação pública oficial, palavras próprias.
> Sem código-fonte, sem strings de UI, sem chaves de configuração ou nomes de
> atributo copiados. Confiança: **documentado** / **inferido**. Data: 2026-10-26.

## 1. Problema

Relatórios avançados são roadmap, mas o **modelo de dados do MVP** precisa gravar
os fatos certos desde o dia 1, senão as métricas não poderão ser calculadas
retroativamente. Precisamos de definições precisas para:

- tempo de primeira resposta (o que conta como "resposta"? inclui nota interna?
  resposta automática? de onde começa o relógio?);
- tempo de resolução (até "resolvido" ou "fechado"? e se reabrir?);
- taxa de reabertura;
- horário comercial vs tempo corrido;
- média vs mediana;
- CSAT (quando pedir, escala, fórmula);
- exportação (formato, limite).

## 2. Comportamento documentado por projeto

### 2.1 Zammad

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Relatório nativo | Tela de relatórios com filtros por estado/contagem, canal de criação e tipo de comunicação; intervalo e período selecionáveis (ex.: mês); gráfico; prévia dos tickets e download. Exige permissão específica. | https://user-docs.zammad.org/en/latest/extras/reporting.html | documentado |
| Perfis de relatório | Admin define perfis = condição de filtro sobre tickets (ex.: organização X, criados no último mês), restritos por papel. Aviso: permissão de relatório pode vazar informação. | https://admin-docs.zammad.org/en/latest/manage/report-profiles.html | documentado |
| Definições de métricas do gráfico | A doc não define as séries (criados, fechados, reabertos, etc.). | — | A CONFIRMAR (M-01) |
| Dependência | Relatórios estão entre os "recursos avançados" providos pelo Elasticsearch. | https://docs.zammad.org/en/latest/prerequisites/software.html | documentado |
| Exportação | Planilha .xlsx, até 6.000 linhas, só quando o filtro de contagem está ativo. | user-docs reporting | documentado |
| Externo | Para análises além do nativo, a doc indica ferramentas externas (ex.: Grafana) lendo o índice do ES. | https://docs.zammad.org/en/latest/appendix/reporting-tools-thirdparty.html | documentado |
| 1ª resposta (SLA) | Intervalo até a primeira resposta externa (chamada ou e-mail), contado da criação do ticket; não reinicia com troca de grupo. | https://admin-docs.zammad.org/en/latest/manage/slas.html | documentado |
| Atualização (SLA) | Intervalo entre respostas; dois modos: entre atualizações do agente (independe do cliente) ou "agente deve responder após o cliente" (só conta se o cliente falou por último). | idem | documentado |
| Solução (SLA) | Até o ticket ir a um estado do tipo fechado; atualizações intermediárias ignoradas. | idem | documentado |
| Horário comercial | SLAs usam calendário (um geral ou um por SLA); ex.: 16 h de SLA com dia de 8 h = 2 dias úteis. | idem | documentado |
| Pausa | Por padrão, estados pendentes e fechado ficam fora do cálculo (relógio congelado, escalonamento oculto); ao reabrir pode escalar na hora, dependendo da idade. | idem | documentado |
| CSAT | Não há pesquisa de satisfação nativa documentada (existe pedido da comunidade). | — | inferido (não há) |

### 2.2 Chatwoot (edição comunitária)

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Relatórios | Visão geral em tempo real; conversas; por agente, etiqueta, caixa e equipe (mesmas métricas, agrupadas); bots; CSAT. Relatórios de SLA são da edição Enterprise (ignorar). | https://chatwoot.com/hc/user-guide/en/categories/reports ; https://developers.chatwoot.com/self-hosted/enterprise-edition | documentado |
| Conversas | Contadas pela data de criação no período; reabertas de períodos anteriores não contam de novo. | https://chatwoot.com/hc/user-guide/articles/1724140319-how-to-read-conversations-report | documentado |
| 1ª resposta (FRT) | **Média**, sobre conversas criadas no período, entre a última atividade não humana (abertura da conversa ou passagem do bot para humano) e a primeira mensagem humana. | idem | documentado |
| Resolução | Média, sobre conversas criadas no período, entre a primeira abertura e a resolução. **Reabertura não cria nova conversa**: se reabrir e resolver depois, o tempo de resolução cresce. | idem | documentado |
| Contagem de resoluções | Resolvidas por dia no período. | idem | documentado |
| Espera do cliente | Como FRT, mas considerando todas as mensagens enviadas (tempo que o cliente esperou por cada resposta). | idem | documentado |
| Mensagens | Recebidas e enviadas (enviadas incluem bot). | idem | documentado |
| Taxa de reabertura | Não há métrica documentada. | — | inferido (não há) |
| Horário comercial | Chave para recalcular as métricas só dentro do horário comercial configurado. | https://www.chatwoot.com/hc/user-guide/articles/1677694691-reading-conversations-agents-labels-inbox-and-team-reports | documentado (existência) / cálculo A CONFIRMAR |
| Tendência | Variação percentual vs período anterior de mesmo tamanho. Período padrão: últimos 7 dias; agrupamento depende do intervalo. | idem | documentado |
| Tempo real | Abertas, sem atendimento, sem atribuição; status dos agentes; mapa de calor de horários (7 dias); carga por agente. | https://chatwoot.com/hc/user-guide/articles/1677693459-how-to-read-overview-reports-realtime | documentado |
| CSAT: disparo | Ativado **por caixa** (desligado por padrão); enviado quando o agente **resolve** a conversa. Escala emoji ou 5 estrelas; comentário opcional após a nota; mensagem customizável (curta). Pode ser condicionado a etiquetas presentes/ausentes. | https://www.chatwoot.com/hc/user-guide/articles/1677503828-how-to-enable-csat-surveys | documentado |
| CSAT: métricas | Total de respostas; satisfação = notas positivas ÷ respostas × 100; taxa de resposta = respostas ÷ pesquisas enviadas × 100; distribuição por nota. Filtros: período e agentes. | https://chatwoot.com/hc/user-guide/articles/1677693868-how-to-read-csat-reports | documentado |
| Exportação | Não documentada nas páginas lidas. | — | A CONFIRMAR (M-02) |

### 2.3 FreeScout

Núcleo não tem relatórios; tudo é módulo pago (catálogo).

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Módulo de relatórios | Conversas (horário mais movimentado, respondidas, nº de clientes), produtividade por agente (clientes atendidos, respostas, fechadas, tempos), satisfação (requer módulo de avaliações), tempo registrado (requer módulo), campos customizados. | https://freescout.net/module/reports/ | documentado |
| 1ª resposta | Da criação do ticket até a primeira resposta de um agente; respostas de spam e de automações (workflows) excluídas. | idem | documentado |
| Tempo de resposta | Usa valor **mediano** (para reduzir efeito de extremos). | idem | documentado |
| Fechadas | Conversas fechadas no período (pode divergir da contagem da busca). | idem | documentado |
| Resolução / horário comercial | Não definidos na página. | — | A CONFIRMAR |
| Exportação | Não faz parte dos relatórios; há módulo separado de exportação de conversas. | idem | documentado |
| CSAT (módulo pago) | Ativado por caixa; link de avaliação vai **em cada resposta** do agente por e-mail (pode restringir a respostas marcadas ou desligar por resposta). Não é enviado quando o agente cria a conversa nem ao fechar. Nova avaliação do cliente sobrescreve a anterior para a mesma mensagem. Só e-mail. Avaliação visível na conversa e no relatório. | https://freescout.net/module/satisfaction-ratings/ | documentado |

### 2.4 osTicket

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Painel | Visão histórica filtrável por período, departamento, tópico de ajuda ou agente; exporta CSV. | https://docs.osticket.com/en/latest/Agent/Dashboard/Dashboard.html | documentado |
| Abertos | Tickets abertos no departamento/tópico; na visão por agente, os que ele abriu manualmente. | idem | documentado |
| Atribuídos | Atribuições no período (manual, "pegar", filtro, tópico, organização); exclui atribuição automática a quem já respondeu; atribuição a equipe não conta para agentes. | idem | documentado |
| Vencidos | Tickets marcados como atrasados por estourar o plano de SLA e seguir abertos. | idem | documentado |
| Fechados | Tickets **atualmente** fechados; reabrir diminui a contagem. | idem | documentado |
| Reabertos | **Número de vezes** que tickets foram reabertos no período (evento, não ticket distinto). | idem | documentado |
| Tempo de serviço | Média em horas desde a abertura até o fechamento **sem reabertura**. | idem | documentado |
| Tempo de resposta | Média em horas entre a mensagem do usuário e a resposta do agente (todas as trocas, não só a primeira). | idem | documentado |
| Agrupamento | Linhas refletem a associação **atual** do ticket ao grupo. | idem | documentado |
| Horário comercial | Não definido para as métricas do painel. | — | A CONFIRMAR |
| Exportação | CSV do painel; CSV das filas/buscas só com metadados do cabeçalho (campos escolhidos). Sem limite documentado. | https://docs.osticket.com/en/latest/Guides/Data%20Extraction%20Guide.html | documentado |
| CSAT | Não documentado. | — | inferido (não há) |

### 2.5 Znuny

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Estatísticas | Três tipos: matriz dinâmica (eixos X/Y + filtros → gráfico de barra/linha/pizza, CSV ou Excel; pode virar widget do painel), lista dinâmica (tickets que casam os filtros, colunas escolhidas), estática (fixas, vindas de pacotes). Módulos: tempo registrado, acumulação (contagem), tempo de solução/resposta (média). Permissão por grupo; importação/exportação de definições; cache opcional; fuso horário configurável. | https://doc.znuny.org/znuny/agentinterface/statistics/index.html | documentado |
| Atributos de tempo | Para 1ª resposta, atualização e solução existem: data/hora real, minutos desde a criação, diferença entre previsto e real, data-alvo de escalonamento, indicador de escalonado, e variante contada **só em horário de trabalho**. Também idade, criação, fechamento, última alteração, primeiro bloqueio, tempo registrado. | https://doc.znuny.org/znuny/annexes/stat_values/index.html | documentado |
| Horário comercial | Existem variantes de horário de trabalho vs relógio para cada métrica (a doc só define explicitamente as de horário de trabalho). | idem | documentado / inferido (calendário) |
| Painel | Gráfico de criados vs fechados por dia (7 dias), escalonados, próximos a vencer, visão por fila/estado, novos sem interação. | https://doc.znuny.org/znuny/agentinterface/dashboards/index.html | documentado |
| Exportação | Estatísticas em CSV/Excel/gráfico; resultado de busca em PDF/CSV/XLSX. | statistics ; https://doc.znuny.org/znuny/agentinterface/ticketviews/agentticketsearch/index.html | documentado |
| Agendamento por e-mail | Não descrito na página. | — | A CONFIRMAR |
| CSAT | Existe pacote de pesquisa (Survey) mencionado na comunidade; sem doc oficial lida. | — | A CONFIRMAR |
| Reabertura | Sem métrica explícita documentada. | — | A CONFIRMAR |

### 2.6 UVdesk

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Atividade do agente | Lista por ticket: ID, assunto, cliente, total de respostas, última resposta do agente. Filtros e exportação não documentados. | https://docs.uvdesk.com/uvdemo/reports/agent-activity.html | documentado |
| Kudos (satisfação) | Avaliações de clientes sobre agentes, com ticket, cliente, e-mail e horário; filtros por agente, grupo, equipe, tipo, prioridade, cliente e origem. Escala e momento do pedido não documentados. | https://docs.uvdesk.com/uvdemo/reports/kudos.html | documentado / A CONFIRMAR |
| Tempos (1ª resposta, resolução) | Não documentados. | — | inferido (não há) |

### 2.7 Frappe Helpdesk

| Tema | Comportamento | Fonte | Confiança |
|---|---|---|---|
| Página inicial do agente | Widgets: média de 1ª resposta, média de resolução, comparação lado a lado (3 m / 6 m / 1 a), meus tickets, pendentes (alertas de SLA). Variação percentual vs período anterior. Fórmula (média/mediana, eventos de início/fim) **não documentada**. | https://docs.frappe.io/helpdesk/other-features/agent-home-page | documentado / A CONFIRMAR |
| Avaliações | Widget com média de estrelas (1–5), total, rótulo de desempenho e distribuição; carrossel ordenável positivo/negativo; filtros de período. Na ficha do contato, aba de feedback com nota e comentário; média por cliente. | idem ; https://frappe.io/helpdesk/customer-management | documentado |
| Quando o cliente avalia | Não documentado oficialmente (há relato de comunidade de que a opção não aparece ao fechar). | — | A CONFIRMAR |
| Visão padrão de feedback | Uma das quatro visões padrão é "meu feedback". | https://docs.frappe.io/helpdesk/custom-views | documentado |
| Relatórios avançados | Integração com o produto de BI da mesma empresa para relatórios customizados. | https://frappe.io/helpdesk/insights-reporting (via busca) | documentado (existência) |
| Exportação / horário comercial | Não documentados no Helpdesk. | — | A CONFIRMAR |

## 3. Tabela comparativa

| Métrica / aspecto | Zammad | Chatwoot CE | FreeScout (pago) | osTicket | Znuny | UVdesk | Frappe |
|---|---|---|---|---|---|---|---|
| Relatório nativo | sim (precisa ES) | sim | módulo | painel | estatísticas configuráveis | 2 listas | widgets |
| 1ª resposta: início | criação | abertura ou handoff do bot | criação | (só resposta média) | criação | — | ? |
| 1ª resposta: o que conta | resposta externa (e-mail/chamada) | 1ª mensagem humana | resposta de agente, exclui spam/automação | — | 1ª resposta | — | ? |
| Agregação | — | média | **mediana** | média (horas) | média | — | ? |
| Resolução | até estado fechado (SLA) | 1ª abertura → resolução; reabrir alonga | ? | abertura → fechamento sem reabrir | tempo de solução | — | média (?) |
| Reabertura | ? | não | ? | **contagem de eventos** | ? | — | ? |
| Horário comercial | calendário por SLA | chave no relatório | ? | ? | variante por métrica | — | ? |
| Pausa em pendente | sim (SLA) | — | ? | ? | ? | — | ? |
| CSAT | não | sim, ao resolver, por caixa | sim, em cada resposta (e-mail) | não | pacote? | "kudos" | estrelas 1–5 |
| Fórmula CSAT | — | % positivas; taxa de resposta | ? | — | ? | ? | média de estrelas |
| Exportação | xlsx ≤ 6.000 | ? | módulo separado | CSV | CSV/Excel/PDF/XLSX | ? | ? |

## 4. A CONFIRMAR EM RUNTIME (mapeado aos cenários)

| Cenário | Projeto(s) | O que confirmar |
|---|---|---|
| M-01 | Zammad | definição de cada série do gráfico (criados, fechados, reabertos, 1ª solução, escalonados); se nota interna conta como 1ª resposta; se auto-resposta (AU-10) conta |
| M-01 | Zammad | comportamento do relatório **sem** Elasticsearch |
| M-01 | Chatwoot | como a chave de horário comercial recalcula (cruzar com AU-06); se nota privada conta como 1ª resposta humana |
| M-01 | FreeScout | se módulos pagos estiverem disponíveis: definição de resolução; mediana confirmada |
| M-01 | osTicket | "tempo de resposta" usa horário comercial do SLA? a resposta automática conta? reabertura após T-03 incrementa "reabertos" e tira de "fechados" |
| M-01 | Znuny | valores de minutos até 1ª resposta com calendário de horário comercial vs relógio (cruzar com AU-05/AU-06) |
| M-01 | Frappe | fórmula da média de 1ª resposta e resolução; início (criação vs atribuição) |
| M-01 | Chatwoot, FreeScout, Frappe, UVdesk | CSAT: momento do envio, escala, se reabertura dispara novo pedido, o que acontece com notas duplicadas |
| M-01 / T-03 | todos | reabertura: alonga resolução (Chatwoot) ou zera/exclui (osTicket)? |
| M-02 | todos | formatos (CSV/XLSX/PDF), limites de linhas, se exporta conteúdo ou só metadados, codificação (UTF-8, acentos) |

## 5. Recomendação preliminar para o MVP (simples e correto)

Relatórios são roadmap; o MVP deve **gravar os fatos** e expor só o mínimo.

1. **Log de eventos imutável por ticket** (já necessário para T-08): criação,
   mudança de estado (de→para), atribuição, mensagem pública do agente, mensagem
   do cliente, nota interna, resposta automática — cada um com timestamp UTC e
   autor/tipo de autor. Todas as métricas abaixo derivam disso.
2. **Carimbos desnormalizados no ticket** (baratos, evitam recalcular):
   primeira_resposta_em, primeiro_resolvido_em, ultimo_resolvido_em,
   fechado_em, contagem_reaberturas, ultima_mensagem_cliente_em.
3. **Definições propostas (documentar no produto)**:
   - *1ª resposta* = da criação do ticket até a primeira mensagem **pública** de um
     **agente humano**; não contam nota interna, auto-resposta, automação nem
     spam (combina Chatwoot + FreeScout). Ticket criado pelo agente: começa na
     primeira mensagem do cliente após a criação — ou é excluído (decidir; A
     CONFIRMAR como os outros tratam).
   - *Resolução* = da criação até a **última** transição para resolvido; reportar
     também "resolvido na 1ª vez" (modelo Chatwoot: reabrir alonga; modelo
     osTicket: tempo de serviço só sem reabertura) — guardar ambos os carimbos
     permite as duas visões.
   - *Reabertura* = evento resolvido/fechado → aberto; taxa = tickets com ≥1
     reabertura ÷ tickets resolvidos no período (e, separadamente, nº de eventos,
     como o osTicket).
   - *Agregação*: guardar a duração por ticket; relatório mostra **mediana e
     média** (mediana do FreeScout é mais robusta).
   - *Horário comercial*: calcular as duas variantes (relógio e horário útil) com
     o mesmo calendário do SLA (modelo Znuny). No MVP basta tempo corrido; o
     calendário entra junto com AU-06.
4. **CSAT**: roadmap, mas reservar o modelo: uma pesquisa por resolução (modelo
   Chatwoot, mais simples que "em toda resposta" do FreeScout), escala 1–5,
   comentário opcional, token de uso único no link do e-mail, última nota vale.
   Métricas: % satisfeitos (4–5) e taxa de resposta.
5. **MVP visível**: um painel simples (abertos por estado/grupo, criados vs
   resolvidos por dia, mediana de 1ª resposta e de resolução nos últimos 7/30
   dias) com **consultas SQL diretas no PostgreSQL** — sem motor externo (ao
   contrário do Zammad, cujo relatório depende do ES). Exportação CSV UTF-8 da
   lista de tickets filtrada (mesmos filtros da Área 8), metadados apenas.
6. **Roadmap**: relatórios por agente/grupo/tag, SLA cumprido/violado,
   agendamento por e-mail, XLSX, construtor de relatórios (modelo Znuny) e
   integração com BI externo.
