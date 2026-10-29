# Spec 13 — Requisitos da operação EARJ

Status: **rascunho v0.1** (2026-10-26). Fonte: dois documentos internos do
responsável pelo projeto, que descrevem **como a equipe de TI da EARJ trabalha
hoje** (fluxo, filas, campos, respostas prontas, regras e números de uso). Eles
são tratados como **requisitos de cliente**: dizem o que a operação precisa
fazer, não como o produto que ela usa hoje foi construído. Nenhum nome de
pessoa, e-mail ou outro dado pessoal desses documentos é reproduzido aqui.

**Precedência:** onde esta spec diverge das specs 01–12, **vale esta**. As
specs afetadas serão atualizadas para refletir os deltas da seção 3. Até lá, o
implementador segue os deltas descritos aqui.

---

## 1. Contexto da operação

- Help desk de TI de uma escola com **duas unidades** (Barra e Gávea).
  Atendem-se professores, funcionários e pais.
- Ordem de grandeza: ~16 agentes, 8 grupos, ~1.650 solicitantes e ~7.200
  tickets em 13 meses (≈ 550/mês). **80% dos tickets chegam pelo formulário web**
  do portal, ~5% por e-mail e ~2% por chat no site.
- Conta em **português**, fuso **America/Sao_Paulo**, relógio 24 h. Respostas
  prontas e conteúdo em **português e inglês**.
- O trabalho é muito presencial (o técnico vai até a sala) e depende de
  fornecedores e de outras equipes internas.
- A pesquisa de satisfação é usada de fato (~99% de satisfação em 60 dias).

---

## 2. Requisitos e onde ficam no PantherDesk

Legenda da coluna "Fase": **MVP** = entra no protótipo; **Roadmap** = depois.
A coluna "Cobertura" indica se as specs 01–12 já atendem (✔), atendem
parcialmente (◐) ou não atendem (✘).

| # | Requisito da operação | Cobertura | Onde / o que muda | Fase |
|---|---|---|---|---|
| R01 | Formulário web do portal com campos de classificação obrigatórios e **campos que aparecem conforme escolhas anteriores** (motivo → equipamento → sintoma; o local vem do cadastro e do QR, Δ33 e D51) | ◐ | Δ1, Δ2 | MVP |
| R02 | Estado **"em espera"** para quando se aguarda fornecedor ou outra equipe interna, separado de "pendente" (que aguarda o solicitante) | ✘ | Δ3 | MVP |
| R03 | Fila de triagem com o que "acabou de chegar e ninguém pegou" | ✔ | indicador "sem primeira resposta" + sem responsável (spec 01) | MVP |
| R04 | Botão para o agente **assumir** o ticket | ✔ | spec 04 | MVP |
| R05 | **Responsável obrigatório para resolver** | ✘ | Δ4 | MVP |
| R06 | **Encaminhar o ticket a outra equipe e ele voltar sozinho** ao técnico que encaminhou quando a outra equipe terminar | ✘ | Δ5 (recurso nativo; hoje isso depende de regras com etiquetas e de uma chamada externa) | MVP |
| R07 | **Seguidores** (colegas que acompanham sem estar na conversa) separados de **Cc** (pessoas que recebem e podem responder) | ◐ | Δ6 | MVP |
| R08 | Menções a colegas em notas internas, com aviso | ✘ | Δ7 | MVP |
| R09 | Tipo do ticket (pergunta, incidente, problema, tarefa, evento) | ✘ | Δ8 | MVP |
| R10 | Prioridade padrão "normal" quando não informada | ✔ | spec 01 | MVP |
| R11 | **Filas salvas compartilhadas** (≈ 9) com colunas, agrupamento, ordenação, contagem e restrição por grupo; **até 10 filas pessoais** por agente | ◐ | Δ9 | MVP |
| R12 | Trabalhar a fila **em sequência** (abrir o próximo ticket sem voltar à lista) | ✘ | Δ9 | MVP |
| R13 | **Edição em massa** (atribuir, mudar estado, aplicar resposta pronta) | ✘ | Δ9 | MVP |
| R14 | ≈ 28 **respostas prontas (macros)** compartilhadas, em PT e EN, que escrevem texto público ou nota interna, mudam estado, grupo, etiquetas e até o assunto; **macros pessoais**; só o admin edita as compartilhadas | ◐ | Δ10 | MVP |
| R15 | Variáveis nas macros (número do ticket, nome do solicitante etc.) e **alerta de variável inválida** (hoje há macro em uso com variável sem substituir) | ✘ | Δ10 | MVP |
| R16 | Estatística de uso das macros (usadas em 24 h, sem uso em 30 dias) | ✘ | Δ10 | MVP |
| R17 | Confirmação por e-mail ao abrir, com texto diferente **dentro e fora do horário comercial** | ◐ | Δ11 | MVP |
| R18 | Aviso ao solicitante quando o agente abre um ticket em nome dele | ✔ | spec 01 §4.6 (contato proativo) | MVP |
| R19 | E-mail ao solicitante e Cc a cada resposta pública; ao resolver, o e-mail traz a resposta **e** o convite da pesquisa | ◐ | Δ12 | MVP |
| R20 | Fechar automaticamente **4 dias** depois de resolvido; fechado não reabre | ✔/◐ | spec 01 já usa 4 dias; política de resposta em fechado da EARJ = `novo` (Δ13) | MVP |
| R21 | SLA com horário comercial; **aviso ao responsável 1 hora útil antes de vencer**; **aviso ao gestor 8 horas úteis depois de vencido** | ◐ | Δ14 | MVP |
| R22 | Coluna de SLA nas filas e ordenação por vencimento | ◐ | Δ9, Δ14 | MVP |
| R23 | **Pesquisa de satisfação** ao resolver, com motivo; fila "avaliados nos últimos 7 dias"; % de satisfação de 60 dias na página inicial | ✘ (estava no roadmap) | Δ15 | MVP |
| R24 | **Chat no site/app** que vira ticket, com pesquisa de satisfação no próprio chat | ✘ (estava no roadmap) | Δ16 | MVP |
| R25 | Duas caixas de e-mail de entrada | ✔ | spec 02 (várias caixas) | MVP |
| R26 | **Conversa paralela por e-mail** com fornecedor ou colega, sem expor ao solicitante | ✘ | Δ17 | MVP |
| R27 | Tela do ticket: contexto do solicitante (dados e tickets anteriores), tickets relacionados, busca de artigos para inserir na resposta | ◐ | Δ18 | MVP |
| R28 | Detecção de colisão | ✔ | spec 09 (presença) | MVP |
| R29 | Rascunho da resposta salvo automaticamente; anexos de até 50 MB; ordem da conversa (mais novos primeiro) configurável pelo agente | ◐ | Δ19 | MVP |
| R30 | Vários tickets abertos ao mesmo tempo (abas) | ✘ | Δ19 | MVP |
| R31 | Ações do ticket: mesclar, criar ticket de continuação, imprimir, marcar como spam | ◐ | Δ20 | MVP |
| R32 | Histórico completo: quem mudou o quê e quais regras rodaram | ✔ | spec 01 §7 | MVP |
| R33 | **Página inicial do agente**: números da semana, satisfação de 60 dias, tickets abertos dos meus grupos, feed de menções e atribuições | ✘ | Δ21 | MVP |
| R34 | Busca por texto e por filtros (estado, responsável = eu, etiqueta, solicitante) | ✔ | spec 08 | MVP |
| R35 | Papéis: **admin**, **agente completo**, **agente de apoio** (só lê e escreve nota interna) | ✔ | spec 06 (acesso de leitura por grupo = agente de apoio) | MVP |
| R36 | Agente comum não exclui ticket e não edita macros, filas compartilhadas, regras nem configurações | ✔ | spec 01 (sem exclusão), spec 06 | MVP |
| R37 | **Campos no cadastro do solicitante** (gestor, equipe, cargo, identificação da máquina) visíveis no ticket | ✘ (estava no roadmap) | Δ22 | MVP |
| R38 | Organizações com campo de notas | ◐ | Δ22 | MVP |
| R39 | Mesclar solicitantes duplicados | ◐ | Δ22 | MVP |
| R40 | Perfil do agente: disponibilidade, idioma, fuso, **tema escuro**, preferências de notificação | ◐ | Δ23 | MVP |
| R41 | Interface e base de conhecimento em **PT e EN** | ◐ | Δ23 | MVP |
| R42 | Base de conhecimento (hoje vazia) para impressora, projetor, som, Wi-Fi/VPN, notebooks e Google, com sugestão de artigos antes de abrir o ticket | ✔ | spec 07 (sugestão já está no MVP) | MVP |
| R43 | Painéis de relatório por **campus e local, categoria e SLA** (pedido explícito do documento) | ◐ | Δ24 | MVP |
| R44 | Marca da escola no portal (logo e cores) | ✘ | Δ25 | MVP |
| R45 | API por token; webhooks | ✔ | spec 10 | MVP |
| R46 | Resumo do ticket e melhoria de texto com IA; sugestão de responsável | ✘ | Δ26 + §6 (resumo e texto no MVP; sugestão de responsável no roadmap) | MVP (parcial) |
| R47 | Aprovações dentro do ticket (compras, trocas de equipamento) | ✘ | ligadas mas nunca usadas | Roadmap |
| R48 | Lista de tarefas obrigatórias no ticket | ✘ | nunca usadas | Roadmap |
| R49 | Cadastro de equipamentos e salas ligados aos tickets | ✘ | nunca usado | Roadmap |
| R50 | Estados personalizados ("aguardando peça", "agendado") | ✘ | só os padrão em uso; o modelo de categorias da spec 01 já prepara isso | Roadmap |
| R51 | Distribuição automática por capacidade | ◐ | desligada na EARJ; spec 04 tem rodízio | Roadmap |
| R52 | Voz (ligações viram tickets) | ✘ | 2 tickets em 13 meses | Roadmap (decidido) |
| R53 | Comunidade/fórum | ✘ | usada só para avisos | Fora de escopo |
| R54 | Importação do histórico atual (tickets, solicitantes) | ✘ | §6: fora do protótipo | Roadmap (decidido) |
| R55 | **Identidade visual da EARJ** em toda a interface: azul oficial, vermelho e verde, fonte Montserrat, logo colorido e branco | ◐ | Δ27 | MVP |
| R56 | **Atalhos de teclado** para navegar, responder, aplicar macro e enviar com estado; lista de atalhos consultável; atalhos desligáveis | ✘ | Δ28 | MVP |
| R57 | Escolher **o que acontece depois de enviar**: ficar no ticket, fechar a aba ou abrir o próximo da fila | ✘ | Δ28 | MVP |
| R58 | Menu "novo" com **tickets vistos recentemente**; busca com **atalhos de tipo** (tickets, artigos, pessoas, organizações, conversas paralelas) e vistos recentemente | ✘ | Δ28 | MVP |
| R59 | Página inicial com as listas **meus tickets, em cópia, seguindo e concluídos em 30 dias**, filtros por estado e canal e ordenação por urgência | ◐ | Δ21, Δ28 | MVP |
| R60 | Filas com **atualização manual da contagem**, **exportação CSV**, alternância **tabela/cartões**, painel de filtros e indicação de **outro agente com o ticket aberto** | ◐ | Δ9, Δ28 | MVP |
| R61 | Tela de pessoas com busca, lista de **suspensos** e perfil com os tickets da pessoa; **suspender solicitante** | ◐ | Δ22, Δ28 | MVP |
| R62 | No ticket: **hora local** e idioma do solicitante, **observações** sobre ele, filtro da conversa (tudo, públicas, internas), **ver como agente de apoio**, **salvar resposta como macro** e traduzir a conversa | ✘ | Δ28 | MVP (traduzir: roadmap) |
| R63 | Fila de **mensagens em quarentena** visível para o agente (equivalente operacional dos "suspensos") | ◐ | spec 02 §2.4, Δ28 | MVP |
| R64 | Aparência **clara, escura ou igual ao sistema** | ◐ | Δ23 | MVP |
| R65 | **Transições suaves** ao navegar entre telas e ao abrir painéis, respeitando "reduzir movimento" | ✘ | Δ29 | MVP |
| R66 | Identidade **Panthers**: azul-marinho, azul royal e vermelho (o Zendesk usa verde; a identidade é nova) | ✘ | Δ30 | MVP |
| R67 | **Login com Google** (contas da escola) para agentes e funcionários | ✘ | Δ31 | MVP |
| R68 | Portal em **help.earj.com.br** | ✘ | Δ32 | MVP |
| R69 | **QR code em cada sala** que abre o formulário com o local preenchido; cadastro de locais por campus, prédio, andar e sala | ✘ | Δ33 | MVP |
| R70 | **Formulário próprio de eventos de AV**, com calendário e prazo contado pela data do evento | ✘ | Δ34 | MVP (prazos relativos e checklist: fase 2) |
| R71 | **Ticket pai** para incidentes em massa | ✘ | Δ35 | MVP |
| R72 | **Macro por intenção com variante EN/PT** escolhida pelo idioma do solicitante | ◐ | Δ36 | MVP |
| R73 | **Prazo de SLA visível** em cada linha das filas e fila "Quase escalando" | ◐ | Δ37 | MVP |
| R74 | **"Criar artigo"** a partir de um ticket resolvido, para a base sair dos 0 artigos | ✘ | Δ38 | MVP |

---

## 3. Deltas sobre as specs 01–12

### Δ1 — Formulário do portal com campos personalizados (afeta 03 e 07)
- O formulário do portal é o **canal principal**, não um recurso opcional. Ele
  fica no portal e aceita solicitante logado (padrão) ou visitante (se a conta
  permitir).
- O admin define **um ou mais formulários**. Cada um tem nome, campos (de
  sistema e personalizados) com ordem, rótulo para o solicitante, texto de
  ajuda, obrigatoriedade e regras condicionais (Δ2). No MVP fica ativo **um
  formulário por finalidade**: um de suporte e um de evento (Δ34); um
  formulário inativo é guardado para teste.
- O ticket criado pelo formulário guarda os valores dos campos. Campos marcados
  como "só agentes" não aparecem no formulário.
- O anti-spam em camadas da spec 03 continua valendo para visitantes.

### Δ2 — Campos condicionais (afeta 01 §5)
- Um campo pode ter **condição de exibição**: aparece só quando outro campo tem
  certos valores. Exemplo: "Equipamento" aparece só quando "Motivo do contato"
  = Audiovisual, e "Sintoma" depende do equipamento escolhido (D51).
- Condições podem ser encadeadas (A → B → C), mas **não** podem formar ciclo.
  O admin não consegue salvar uma regra que gere ciclo.
- Um campo oculto **não é obrigatório**, mesmo que seja marcado como
  obrigatório. Quando o campo do qual ele depende muda e ele fica oculto, o
  valor dele é **limpo** e o evento de auditoria registra a limpeza.
- As regras valem no portal, na tela do agente e na API. Na API, enviar valor
  para um campo que deveria estar oculto é erro de validação.
- Obrigatoriedade pode ser "para abrir" (portal e agente) ou "para resolver"
  (spec 01 §4.2).

### Δ3 — Estado "em espera" (afeta 01, 04, 05, 09, 11)
- Novo estado **em espera**: a equipe aguarda **um terceiro** (fornecedor ou
  outra equipe interna), não o solicitante.

| Aspecto | pendente | em espera |
|---|---|---|
| Quem está sendo aguardado | o solicitante | um terceiro |
| Categoria de SLA | pausado (resolução) | **pausado** (resolução) |
| Aparece para o solicitante como | "aguardando sua resposta" | "em andamento" |
| Resposta do solicitante | volta para aberto | volta para aberto |
| Resposta numa conversa paralela (Δ17) | não muda | volta para aberto |
| Data de retorno opcional | sim | sim |

- Transições: aberto ↔ em espera, pendente ↔ em espera, em espera → resolvido
  e em espera → fechado são permitidas ao agente. As regras automáticas de
  "pendente" na spec 01 §4.3 valem igualmente para "em espera".
- O solicitante nunca vê o termo "em espera" no portal nem nos e-mails.

### Δ4 — Responsável obrigatório para resolver (afeta 01 §4.2)
- Configuração por conta, **ligada** para a EARJ: ir para resolvido exige
  responsável. Sem responsável, a transição é recusada com a indicação do campo.
- Resolver por macro sem responsável também é recusado, salvo se a própria
  macro atribuir alguém, porque as ações da macro são aplicadas antes da
  validação.

### Δ5 — Encaminhamento com retorno (afeta 04)
Recurso nativo para "mando para outra equipe e o ticket volta para mim":
- Um agente com escrita no ticket escolhe **encaminhar para o grupo X com
  retorno** e escreve uma nota interna obrigatória.
- Efeito: o ticket vai para o grupo X, **sem responsável**, no estado
  **aberto** (é trabalho do grupo X). O sistema registra a **origem do
  encaminhamento** (grupo e agente). Para o grupo de origem, o ticket aparece
  com a marca derivada **"encaminhado"**, que também serve de filtro de fila. O
  estado continua um só (D23). A origem mantém acesso de leitura (D24).
- O ticket fica marcado como "encaminhado por {agente} de {grupo}" nas filas
  dos dois grupos.
- Quando um agente do grupo X usa **devolver** (com nota interna), ou o resolve
  enquanto a origem estiver registrada, o ticket volta ao grupo de origem,
  **com o agente de origem como responsável**, no estado **aberto**, com a
  origem limpa. Resolver dentro do grupo X devolve com estado aberto e uma nota
  "resolvido pela equipe X". Quem fecha para o solicitante é o técnico de
  origem.
- Se o agente de origem estiver desativado ou sem escrita no grupo de origem,
  o ticket volta sem responsável, na fila do grupo de origem.
- Encaminhamentos podem ser **aninhados** no máximo 1 nível no MVP: um ticket
  encaminhado não pode ser encaminhado com retorno de novo antes de voltar. Ele
  pode, porém, ser transferido normalmente (spec 04), o que **cancela** o
  retorno, com aviso a quem encaminhou.
- O SLA continua o mesmo (não reinicia); o tempo no grupo X conta para o
  relatório desse grupo (spec 11, fato por grupo no momento do evento).

### Δ6 — Seguidores (afeta 01, 09)
- **Seguidor** = agente que acompanha o ticket. Recebe notificações (no app e,
  se quiser, por e-mail) de mensagens públicas, notas internas e mudança de
  estado, mas **não** aparece para o solicitante e não recebe os e-mails
  públicos como Cc.
- **Participante (Cc)** continua como na spec 01: pessoa que recebe as
  respostas públicas e pode responder.
- O agente pode seguir ou deixar de seguir qualquer ticket que consegue ver.
  Ser mencionado (Δ7) torna o agente seguidor, e ele pode deixar de seguir.

### Δ7 — Menções (afeta 09)
- Em nota interna, `@nome` de um agente com acesso ao ticket gera notificação
  no app (e por e-mail, conforme a preferência dele). Mencionar quem não tem
  acesso mostra um aviso ao autor e não notifica.
- Menção em resposta pública **não** é permitida (o texto iria ao solicitante).

### Δ8 — Tipo do ticket (afeta 01)
- Campo de sistema opcional: pergunta, incidente, problema, tarefa e **evento**
  (este definido pelo formulário de evento, Δ34; o tipo "incidente" não se
  confunde com o ticket pai de incidente em massa, Δ35). Sem valor
  padrão. Pode ser usado em filas, regras e relatórios.

### Δ9 — Filas salvas, modo sequência e edição em massa (afeta 08)
- **Fila salva** = filtro + colunas + agrupamento + ordenação, com nome e
  **contagem** atualizada. Colunas disponíveis: número, assunto, solicitante,
  organização, grupo, responsável, estado, prioridade, tipo, qualquer campo
  personalizado, criado em, atualizado em, **vencimento do SLA** (com
  indicação de "vence em" ou "vencido há") e última atividade do solicitante.
- **Compartilhadas** (só o admin cria e edita), com restrição de quem vê: todos
  os agentes ou só membros de certos grupos. **Pessoais**: cada agente cria até
  **10**.
- Agrupar por: estado, responsável, grupo, prioridade, tipo ou campo de lista.
  Dentro do grupo vale a ordenação da fila.
- Filtros relativos ao tempo ("resolvidos nas últimas 12 h", "avaliados nos
  últimos 7 dias") são recalculados a cada abertura da fila.
- **Modo sequência**: a partir de uma fila, o agente abre o primeiro ticket e,
  ao enviar ou pular, o próximo da fila abre sozinho. Tickets que outro agente
  está vendo são pulados, e o agente é avisado.
- **Edição em massa** sobre tickets selecionados numa fila (até 100 por vez):
  atribuir, mudar grupo, estado, prioridade, etiquetas ou aplicar macro.
  Executa ticket a ticket com as mesmas validações; o resultado mostra quantos
  foram alterados e quais falharam e por quê. Cada ticket gera seus próprios
  eventos, e as automações rodam por ticket.
- Filas compartilhadas sugeridas para a EARJ (dados de demonstração): todos os
  não resolvidos por estado; triagem; meus tickets; abertos por responsável;
  pendentes por responsável; em espera nos meus grupos (mais antigos primeiro);
  sem responsável; resolvidos nas últimas 12 h; avaliados nos últimos 7 dias.

### Δ10 — Macros (afeta 05)
- **Compartilhadas** (o admin cria e edita; podem ser restritas a grupos) e
  **pessoais** (cada agente cria as suas; só ele vê).
- Ações possíveis: inserir texto na **resposta pública** ou numa **nota
  interna**; mudar estado, prioridade, tipo, grupo, responsável (incluindo
  "eu"), campos personalizados e **assunto**; adicionar e remover etiquetas;
  adicionar seguidor; encaminhar com retorno (Δ5); devolver (Δ5).
- **Variáveis** no texto e no assunto: número do ticket, assunto, nome e
  primeiro nome do solicitante, nome do agente, nome do grupo, nome da conta,
  valores de campos personalizados e link do ticket no portal. A lista de
  variáveis é fechada, e o editor oferece autocompletar.
- Ao salvar uma macro, **variáveis desconhecidas ou texto entre marcadores
  que não corresponde a nenhuma variável** geram erro e a macro não é salva.
  Uma macro antiga com problema aparece marcada na lista. Isso resolve o caso
  atual de uma macro com marcador sem substituir.
- Aplicar a macro mostra a **prévia** no editor (texto e mudanças) antes de
  enviar, como na spec 05. Nada muda no ticket até o agente enviar.
- **Idioma**: substituído pelo Δ36 (2026-10-29). Cada macro é uma intenção
  com variantes PT e EN, e a variante do idioma do solicitante entra sozinha.
  Não há mais filtro de macros por idioma.
- **Estatística de uso**: número de usos em 24 h, 7 dias e 30 dias, e a data do
  último uso. A lista de macros pode ser ordenada por "sem uso há 30 dias".
  Desativar uma macro a esconde do editor sem apagá-la.

### Δ11 — Horário comercial em gatilhos (afeta 05)
- Gatilhos ganham a condição **"dentro do horário comercial"** ou **"fora do
  horário comercial"**, avaliada no momento do evento, com o calendário da conta
  ou do grupo.
- Exemplo usado na EARJ (dados de demonstração): na criação, se estiver dentro
  do horário, confirmação normal; se estiver fora, confirmação informando que o
  atendimento começa no próximo período útil e a etiqueta "fora do horário".
  Os dois gatilhos se excluem, e o solicitante recebe **uma** confirmação só.

### Δ12 — E-mails ao solicitante (afeta 02, 05)
- Resposta pública: e-mail ao solicitante e aos participantes (spec 02 §9).
- Resposta pública **que resolve** o ticket: um único e-mail com a resposta e
  o convite da pesquisa (Δ15). Nunca dois e-mails seguidos.
- Mudança só de estado, sem mensagem pública: não envia e-mail, salvo se um
  gatilho configurado disser o contrário.

### Δ13 — Política de resposta em fechado na EARJ (afeta 01 §4.4)
- Para a EARJ, a política de todos os grupos é **`novo`**: resposta em ticket
  fechado cria ticket novo vinculado. Isso corresponde ao uso atual ("fechado
  não reabre mais"). A janela de 14 dias continua sendo o padrão do produto
  para outras contas.
- Ação manual **"criar continuação"** num ticket fechado (agente): cria um
  ticket vinculado com o mesmo solicitante, participantes e campos.

### Δ14 — SLA com avisos absolutos e escalonamento atrasado (afeta 05)
- O aviso antes do vencimento passa a aceitar **duas formas**, escolhidas na
  política: percentual do prazo restante (padrão da spec 05) **ou tempo útil
  absoluto** ("1 hora útil antes"). Para a EARJ: **1 hora útil antes**, avisando
  o responsável (ou o grupo, sem responsável), uma única vez por métrica.
- **Escalonamento após vencimento** com atraso: "N horas úteis depois de
  vencido", avisando uma pessoa ou papel configurado (para a EARJ: o gestor de
  TI, 8 horas úteis depois), uma única vez por métrica.
- As tarefas de tempo rodam no mínimo **a cada minuto**. A precisão do aviso é
  de 1 minuto, não de 1 hora.
- As filas mostram o vencimento mais próximo entre as métricas ativas e
  permitem ordenar por ele.

### Δ15 — Pesquisa de satisfação no MVP (afeta 05, 07, 11)
- Na transição para **resolvido** (com resposta pública), o solicitante recebe
  o convite. Avalia por link no e-mail, no portal ou no chat (Δ16).
- Escala: **5 pontos** (1 a 5), com comentário opcional e **motivo** opcional
  de uma lista definida pelo admin, mostrada quando a nota é 1–3.
- "Satisfeito" = nota 4 ou 5. **% de satisfação** = satisfeitos ÷ avaliações no
  período. Tickets não avaliados não entram no denominador.
- Uma avaliação por **resolução**: se o ticket reabre e é resolvido de novo,
  um novo convite pode ser enviado (no máximo 1 convite por ticket a cada 24 h).
  A avaliação pode ser alterada pelo solicitante até o ticket fechar.
- A avaliação é exposta em filas ("avaliados nos últimos 7 dias"), na página
  inicial (Δ21), no relatório (spec 11) e na API, e gera evento de auditoria.
- O convite não é enviado a endereço inválido, a ticket marcado como spam, a
  ticket de contato proativo resolvido sem resposta do solicitante, nem quando
  o admin desliga a pesquisa no grupo.

### Δ16 — Chat no site no MVP (afeta 03, 09)
Escopo mínimo, **assíncrono** (no estilo de mensagens, sem exigir que o agente
esteja online):
- **Widget** embutível no site/app da conta, com a marca da conta. Visitante
  identificado (logado no portal, ou informando nome e e-mail) ou anônimo (se
  permitido; sem e-mail, não recebe respostas fora do widget).
- A primeira mensagem **cria um ticket** com canal "chat", no grupo padrão do
  chat. As mensagens seguintes entram no mesmo ticket enquanto ele não estiver
  resolvido. Depois de resolvido, uma mensagem nova reabre o ticket, e depois
  de fechado cria um ticket novo vinculado (política Δ13).
- O agente responde pela tela normal do ticket. A resposta pública aparece no
  widget em tempo real (spec 09) e, se o visitante não estiver com o widget
  aberto e tiver e-mail, vai **por e-mail** depois de 2 minutos sem leitura.
- Indicador "o agente está escrevendo" e "lido" no widget.
- Ao resolver, a pesquisa (Δ15) aparece no próprio widget.
- Anexos no widget: imagens e PDF até 10 MB.
- Fica para o roadmap: roteamento por disponibilidade, bots, horário de chat
  separado e transferência entre agentes durante a conversa.

### Δ17 — Conversa paralela por e-mail (afeta 01, 02)
- Dentro de um ticket, o agente abre uma **conversa paralela** com um ou mais
  endereços (fornecedor, colega de outra área), com assunto e mensagem.
- A conversa paralela é uma **linha separada** dentro do ticket: só agentes a
  veem, ela nunca vai ao solicitante e tem identificadores de e-mail próprios.
  As respostas dos destinatários entram nela, pelo threading da spec 02, e não
  na conversa principal.
- Resposta recebida numa conversa paralela: notifica o responsável e os
  seguidores e, se o ticket estiver em espera, volta para **aberto** (Δ3). Ela
  **não** conta como resposta do solicitante para o SLA nem para as métricas.
- Uma conversa paralela pode ser **encerrada** (não aceita novas respostas;
  e-mails que chegarem depois vão para a quarentena com o motivo "conversa
  paralela encerrada").
- Um ticket pode ter várias conversas paralelas.

### Δ18 — Contexto na tela do ticket (afeta 07, 08)
- Painel com os dados do solicitante (incluindo os campos do cadastro, Δ22),
  a organização e os **tickets anteriores** do solicitante (últimos 10, com
  estado).
- **Tickets relacionados**: até 5 tickets parecidos (busca pelo assunto e
  pelos campos de classificação), respeitando as permissões.
- **Artigos**: busca na base e inserção do **link** do artigo na resposta
  pública. Artigos internos podem ser lidos pelo agente, mas nunca inseridos em
  resposta pública.

### Δ19 — Editor e abas (interface)
- Rascunho da resposta e da nota salvo automaticamente por ticket e por agente
  (sobrevive a recarregar a página). Ao enviar, o rascunho é apagado.
- Formatação básica, links, emoji, anexos de até **50 MB** por arquivo (limite
  da conta) e imagem colada.
- **Enviar com estado**: o botão de enviar permite escolher o estado
  resultante (aberto, pendente, em espera, resolvido).
- Ordem da conversa (mais novas primeiro ou mais antigas primeiro) é
  preferência do agente.
- **Abas**: vários tickets, pessoas e organizações abertos ao mesmo tempo, com
  rascunhos independentes. Fechar uma aba com rascunho não o descarta.
- Gravação de áudio no editor fica no roadmap.

### Δ20 — Ações do ticket (afeta 01)
- Mesclar (spec 01 §6), criar continuação (Δ13), **imprimir** (versão de
  impressão com conversa pública e, por escolha do agente, notas internas) e
  marcar como spam (spec 01).

### Δ21 — Página inicial do agente (afeta 09, 11)
- **Meus números da semana**: tickets resolvidos, tempo mediano da primeira
  resposta e avaliações recebidas.
- **Satisfação de 60 dias**: a minha e a da conta (Δ15).
- **Abertos nos meus grupos**: contagem por estado.
- **Feed**: menções (Δ7), atribuições a mim, respostas em tickets meus e avisos
  de SLA, com lido e não lido (spec 09).

### Δ22 — Cadastro de solicitantes e organizações (afeta 01 §5)
- Campos personalizados também em **Pessoa** e **Organização**, com os mesmos
  tipos e regras da spec 01 §5. Para a EARJ: gestor, equipe, cargo e
  identificação da máquina (pessoa) e notas (organização).
- Os campos da pessoa aparecem no painel de contexto (Δ18) e podem ser usados
  em filas, regras e relatórios.
- **Mesclar pessoas duplicadas**: endereços, tickets (como solicitante e
  participante) e organização da pessoa de origem passam para a de destino; a
  origem fica marcada como mesclada, com ponteiro (mesma lógica da spec 01 §6).
  Só agente completo e admin.

### Δ23 — Preferências e idiomas (interface)
- Interface disponível em **português e inglês**; cada pessoa escolhe a sua, e
  o padrão vem da conta.
- **Tema claro e escuro**, por preferência do agente, seguindo o sistema por
  padrão.
- Fuso e formato de 24 h por pessoa, com o padrão da conta.
- Disponibilidade do agente (disponível, ausente), usada pela spec 04.
- Base de conhecimento com artigo em PT e EN como **traduções do mesmo
  artigo**. O portal mostra o idioma do visitante e cai para o idioma padrão da
  conta quando falta tradução.

### Δ24 — Relatórios por campus e local, categoria e SLA (afeta 11)
- O painel do MVP permite **filtrar e quebrar por qualquer campo de lista**
  (para a EARJ: motivo do contato e equipamento), por **campus e local** do
  cadastro de locais (Δ33, D51), além de grupo e período.
- Métricas mínimas por quebra: criados, resolvidos, tempo mediano da primeira
  resposta, tempo mediano da primeira resolução, % dentro do SLA e % de
  satisfação.
- Exportação CSV do mesmo recorte.

### Δ25 — Marca da conta no portal e no widget
- Logo, nome, cor principal e cor de destaque da conta, aplicados ao portal,
  ao widget de chat e aos e-mails ao solicitante. A cor tem contraste mínimo
  verificado (AA); se não atingir, o sistema ajusta o tom do texto
  automaticamente.
- A interface do agente mantém a identidade do PantherDesk.

### Δ26 — Recursos de IA (roadmap próximo, opcional)
- Resumo do ticket (gerar e fixar no topo), melhoria de texto do rascunho (tom
  e clareza) e sugestão de responsável, usando um provedor de IA plugável.
  Desligado sem chave de API configurada. Nada é enviado ao solicitante sem o
  agente revisar.
- Ficam fora do protótipo inicial; o design reserva o espaço na tela do ticket.

---

### Δ27 — Marca da conta × identidade do produto (revisado em 2026-10-26)
- Decisão do responsável pelo projeto: a **área do agente usa a identidade do
  PantherDesk**, com o nome do produto sozinho ("PantherDesk", sem "Help Desk"
  ou outro complemento) e o nome da conta em texto pequeno logo abaixo.
  Visual: barra lateral grafite, conteúdo claro, cartões com borda fina,
  âmbar só como detalhe (indicadores e não lidas), e modo escuro.
- A **marca da conta** (logo para fundo claro e para fundo escuro, cor
  principal, cor de destaque, cor de alerta e fonte) vale no **portal, no
  widget de chat e nos e-mails ao solicitante**. A área do agente aceita, no
  máximo, trocar a cor de destaque pela da conta.
- Para a EARJ: azul **#27348B** (principal), verde **#00B050** (destaque) e
  vermelho **#E4051F** (alerta e SLA vencido), com a fonte **Montserrat**, que
  é a fonte oficial da escola. As cores vêm dos templates institucionais. O
  arquivo da fonte é instalado junto com a aplicação, sem depender de serviço
  externo.
- **Regras de contraste** (AA): texto sobre o verde usa tinta escura, nunca
  branca (o verde com texto branco não atinge 4,5:1). O vermelho só é usado com
  texto branco em rótulos de 12 px ou mais, em negrito. Estados nunca são
  distinguidos só pela cor: sempre há o rótulo escrito.
- As cores de estado são fixas no produto e não seguem a marca, para não mudar
  de significado entre contas. A exceção: "aberto" usa a cor de alerta da
  conta.
- No modo escuro, a cor principal continua na barra superior, e as superfícies
  ficam em tons escuros derivados dela.

### Δ28 — Produtividade do agente (atalhos, depois de enviar, recentes)
- **Atalhos**: conjunto próprio do PantherDesk, consultável com `?`. As teclas
  de uma letra só funcionam fora de campos de texto, e cada agente pode
  desligá-las. Conjunto mínimo: buscar (`/`), novo ticket (`N`), ir para
  Início, Filas e Pessoas (`G` seguido de `I`, `F` ou `P`), próximo e anterior
  na lista (`J`/`K`), selecionar (`X`), responder (`R`), nota interna (`I`),
  macros (`M`), enviar (`Ctrl+Enter`), enviar como Pendente, Em espera ou
  Resolvido (`Ctrl+Shift+P/E/R`) e próximo ticket da fila (`Ctrl+Shift+↓`).
- **Depois de enviar**: preferência por agente, que pode ser trocada no próprio
  envio: ficar no ticket (padrão), fechar a aba ou abrir o próximo da fila de
  onde o ticket veio.
- **Recentes**: os últimos 10 tickets e pessoas abertos pelo agente ficam no
  menu "novo" e na busca vazia.
- **Busca com tipo**: a caixa de busca oferece filtros rápidos por tipo; a
  escolha vira o filtro da busca (spec 08).
- **Filas**: botão de atualizar a contagem, exportar o recorte em CSV (até
  10.000 linhas, só com as colunas visíveis e respeitando as permissões) e
  alternar entre tabela e cartões.
- **Ver como agente de apoio**: mostra o ticket como um agente só de leitura o
  veria, para conferir o que fica visível. Não muda nada no ticket.
- **Salvar resposta como macro**: transforma o texto do editor numa macro
  pessoal nova, com o estado escolhido no envio.
- **Suspender solicitante**: o admin ou o agente completo bloqueia a pessoa.
  Mensagens novas dela vão para a quarentena com o motivo "solicitante
  suspenso", e o portal recusa o acesso dela. Reativar desfaz o bloqueio.
- **Hora local do solicitante**: calculada pelo fuso da pessoa, com o fuso da
  conta como padrão.

### Δ29 — Transições suaves entre telas
- Toda troca de tela (menu lateral, link entre filas, abrir ticket, voltar)
  é **animada**: a moldura (barra lateral e cabeçalho) fica parada, e o
  conteúdo novo entra com um fade curto e um deslocamento vertical leve
  (cerca de 10 px). Duração de 250 a 350 ms, com curva de desaceleração.
- Blocos da mesma tela podem entrar em cascata, com atraso de até 100 ms entre
  eles. Campos condicionais que aparecem no formulário (Δ2) entram com o mesmo
  movimento, em menos tempo.
- Abertura e fechamento de painéis, menus, gavetas e da barra de edição em
  massa também são animados (deslizar e fade). Mensagens novas no chat entram
  com animação, e o indicador "escrevendo" é animado.
- A navegação não espera a animação: o conteúdo já pode ser lido e usado
  durante ela, e a animação nunca bloqueia clique nem teclado.
- Se a pessoa pediu ao sistema para **reduzir movimento**, as animações são
  desligadas e a troca é imediata.
- A transição entre telas usa a navegação do próprio navegador quando houver
  suporte a transições de página, e uma animação de entrada do conteúdo quando
  não houver. O comportamento visível é o mesmo nos dois casos.

---

**Decisões de 2026-10-29.** Os deltas Δ30 a Δ38 vêm das decisões já tomadas pelo
responsável pelo projeto e das cinco recomendações para o MVP da pesquisa de
ideias (artefato "Ideias para o PantherDesk"). Onde divergirem de um delta
anterior, valem estes.

### Δ30 — Identidade Panthers (substitui o visual do Δ27)
- Paleta do produto: **azul-marinho #0B1F4B** (moldura: barra lateral,
  cabeçalhos fortes), **azul royal #1F4FD6** (ações primárias, links, seleção) e
  **vermelho #D62839** (atenção: SLA vencido, ticket aberto sem resposta, itens
  que pedem ação). O âmbar e o grafite do Δ27 deixam de ser usados. O verde fica
  restrito a estados de sucesso (resolvido, satisfeito) e não é cor de marca.
- Nome do produto: **PantherDesk**, com o símbolo da pantera. A cor de destaque
  do símbolo passa a ser o vermelho.
- Contraste (AA): texto branco sobre azul-marinho, royal e vermelho. Texto em
  royal ou vermelho sobre fundo claro usa a própria cor, com pelo menos 4,5:1.
  No modo escuro, o royal clareia para #7090FF e o vermelho para #FF5C6C quando
  usados como texto; como fundo de botão, ficam em #3F63E6 e #E0384A.
- O vermelho nunca é a única indicação de estado: sempre há rótulo escrito.
- Continua valendo do Δ27: a marca da conta (logo e cores da escola) aparece no
  portal, no chat e nos e-mails. Para a EARJ, o portal usa a mesma paleta
  Panthers com o nome da escola.

### Δ31 — Login com Google (substitui o link mágico como entrada principal)
- **Agentes e admins** entram **somente** com conta Google do domínio da escola
  (configurável por conta; para a EARJ, `earj.com.br`). Sem senha local.
- **Solicitantes da escola** (funcionários e professores) entram no portal com
  a mesma conta Google. O e-mail da conta Google identifica a Pessoa; o
  endereço passa a **verificado** no primeiro login (amplia D38).
- **Quem não tem conta da escola** (pais, visitantes) continua usando o link de
  acesso por e-mail da spec 07, que vira a opção secundária na tela de entrada.
- Papel e grupos **não** vêm do Google no MVP: são definidos no PantherDesk pelo
  admin. Uma conta Google do domínio que nunca foi cadastrada entra como
  solicitante.
- Os parâmetros da URL de entrada (por exemplo, os do QR, Δ33) **sobrevivem** ao
  redirecionamento do login: depois de entrar, a pessoa volta exatamente à
  página e aos campos que tinha aberto.
- O adaptador de autenticação da spec 12 é o ponto de extensão; o Google é o
  primeiro provedor implementado.

### Δ32 — Endereço do portal
- O portal e todos os links enviados por e-mail (convidado, entrada, pesquisa
  de satisfação, artigos) usam o domínio próprio da conta. Para a EARJ:
  **help.earj.com.br**. A área do agente fica no mesmo domínio, em um caminho
  separado.

### Δ33 — QR code por sala e cadastro de locais
- **Cadastro de locais** em quatro níveis: campus → prédio → andar → sala. A
  Barra tem 5 andares (subsolo, térreo, 1º, 2º e cobertura). Cada sala tem
  nome, código curto estável, campus e andar, e pode ser desativada sem
  apagar o histórico. É pré-requisito do formulário condicional, da "minha
  sala", da distribuição por campus e dos relatórios por local.
- Cada sala tem um **QR** que aponta para um endereço curto e estável do
  portal com o código da sala. Ao abrir:
  - **solicitante**: o formulário abre com campus, andar e sala **já
    preenchidos e travados**, com a opção "não estou nesta sala" para trocar;
  - **agente logado**: abre a lista de tickets abertos daquela sala, com o
    botão "assumir", e a opção de abrir um ticket novo já com o local.
- O admin imprime os QR por prédio ou andar (folha com nome da sala e código).
  Trocar o nome de uma sala não muda o QR.
- O local do ticket vem do QR ou do formulário, nunca de etiquetas. As
  etiquetas antigas de campus deixam de ser necessárias.
- "Minha sala": a pessoa pode salvar no perfil as salas onde trabalha, e o
  formulário abre com a primeira delas quando não há QR.

### Δ34 — Eventos de AV: formulário próprio, calendário e prazo pela data
- **Formulário de evento**, separado do formulário de suporte, com: nome do
  evento, tipo (assembly, homecoming, tradução simultânea, evento entre campi,
  pequeno evento, outro), data, início e fim, **início da montagem**, local
  (do cadastro, Δ33), público estimado, equipamentos pedidos (lista) e
  observações. Antecedência mínima configurável (padrão: 5 dias úteis); um
  pedido mais em cima da hora é aceito, mas marcado "fora do prazo".
- O ticket de evento guarda a **data do evento** e aparece no **calendário de
  eventos** (visão de mês e de semana, filtro por campus e por tipo), além das
  filas normais.
- **Prazo pela data do evento**: o compromisso do ticket é estar pronto até o
  início da montagem. O selo de prazo (Δ37) mostra "faltam N dias para a
  montagem". Avisos ao responsável 2 dias úteis antes e no dia, e ao grupo de
  eventos se não houver responsável.
- A 1ª resposta segue o SLA comum (D40). Até o dia, o ticket pode ficar em espera ou pendente sem que o prazo de resolução comum
  corra; depois do evento, o técnico resolve normalmente.
- Fase 2: checklist de preparação com tarefas de prazo relativo ao evento;
  detecção de conflito de local e de equipamento.

### Δ35 — Ticket pai para incidentes em massa
- Um agente marca um ticket como **incidente** (pai) e **vincula** outros
  tickets a ele (filhos), na hora ou depois.
- Uma resposta pública escrita no pai é enviada a **todos os solicitantes dos
  filhos**, cada um no seu idioma quando a resposta vem de macro com
  variantes (Δ36), e registrada em cada filho.
- Resolver o pai resolve os filhos abertos, com a mesma resposta. Os filhos
  **não** disparam pesquisa de satisfação; o pai também não.
- O pai mostra a contagem de filhos e os locais afetados (do Δ33).
- Fase 2: sugestão automática de vínculo quando tickets parecidos chegam juntos,
  e dividir um ticket em dois.

### Δ36 — Macro por intenção, com variante EN/PT
- Cada macro representa **uma intenção** (por exemplo, "atendimento no
  local") e tem **variantes por idioma** (PT e EN). Ao aplicar, entra a
  variante do idioma do solicitante; o agente pode trocar na prévia.
- As 28 macros atuais viram cerca de 14 intenções com duas variantes. Macro sem
  variante no idioma do solicitante usa a do idioma da conta e mostra um aviso.
- Busca de macros pelo nome da intenção, em qualquer idioma (substitui o filtro
  por idioma do Δ10).

### Δ37 — Prazo de SLA à vista nas filas
- Cada linha das filas mostra o **selo de prazo** da próxima métrica ativa:
  "vence em …", "vencido há …" (vermelho) ou "pausado", e "faltam N dias" para
  eventos (Δ34).
- Fila compartilhada padrão **"Quase escalando"**: tickets cujo próximo prazo
  vence em até 1 hora útil, ou já vencido, mais antigos primeiro.
- Os avisos por e-mail ao responsável e ao gestor (Δ14) continuam iguais.

### Δ38 — "Criar artigo" a partir do ticket resolvido
- Num ticket resolvido, quem pode **ler** o ticket (inclusive o agente de
  apoio) usa **"Criar artigo"**: abre um rascunho na base de conhecimento com o
  **título vindo do assunto** do ticket (editável) e o **texto vindo da
  resposta pública final**, sem dados do solicitante, para revisar. O agente
  escolhe a categoria e o idioma e pode pedir a outra língua (PT/EN) como
  **rascunho de tradução do mesmo artigo** (D42). Ticket não resolvido: a ação
  não aparece e, pela API, devolve erro de validação.
- Só o admin publica (D30). O rascunho registra de qual ticket veio.
- O portal passa a sugerir esses artigos ao abrir pedido (spec 07).

## 4. Dados de demonstração do protótipo (baseados na EARJ, sem dados pessoais)

- Conta "EARJ", com o portal em help.earj.com.br (Δ32), a paleta Panthers
  (Δ30), campi **Barra** e **Gávea** no cadastro de locais (Δ33; a Barra com
  subsolo, térreo, 1º, 2º e cobertura), fuso America/Sao_Paulo e idiomas PT
  (padrão) e EN. Logo e textos da escola ficam na configuração da conta de
  demonstração, não no código do produto.
- 8 grupos, com nomes **inspirados** na divisão por unidade e tipo (suporte,
  sistemas, eventos) da operação real.
- Campos do formulário de suporte: local (do cadastro, preenchido pelo QR ou
  pela cascata campus → andar → sala; D51); tipo de solicitante (pai,
  funcionário); motivo do contato (hardware, software educacional, software
  administrativo, rede/infraestrutura, audiovisual, outros); equipamento, que
  depende do motivo = hardware; e sintoma, que depende do equipamento (ex.:
  impressora → não imprime, toner, não liga). Formulário de evento conforme o
  Δ34, com eventos de demonstração em novembro de 2026.
- 9 filas compartilhadas (Δ9), ~28 macros em PT e EN cobrindo primeira resposta,
  atendimento no local, pendências, em espera com fornecedor, outro
  departamento, encerramento, encaminhar e devolver (textos escritos por nós).
- Gatilhos de confirmação dentro e fora do horário, aviso de SLA 1 h útil
  antes, escalonamento 8 h úteis depois e fechamento 4 dias após resolvido.
- Pessoas, agentes e tickets **fictícios**: ~10 agentes (completos e de apoio),
  ~50 solicitantes e ~200 tickets em todos os estados, com avaliações, menções,
  encaminhamentos com retorno e conversas paralelas.

---

## 5. Casos de teste (critérios de aceite)

Atores: `ag1`, `ag2` (grupo Suporte Barra, completos), `ag3` (grupo Sistemas,
completo), `apoio1` (agente de apoio: leitura em todos os grupos), `admin`,
`gestor` (destinatário do escalonamento), solicitantes `ana`, `bia`.
Calendário: seg–sex 07:00–17:00, America/Sao_Paulo.

### 5.1 Formulário e campos condicionais
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| ER-01 | formulário com motivo (obrig.) → equipamento (obrig., só se motivo = hardware) | ana envia com motivo = rede e equipamento vazio | ticket criado; equipamento não exigido (revisto em v0.3, D51) |
| ER-02 | idem | ana envia com motivo = hardware e equipamento vazio | recusado; indica o equipamento |
| ER-03 | ticket com motivo = hardware e equipamento = "impressora" | ag1 muda motivo para rede | equipamento limpo; evento registra a limpeza |
| ER-04 | idem | chamada da API com motivo = rede e equipamento = "impressora" | erro de validação no campo equipamento |
| ER-05 | admin cria A depende de B e B depende de A | salvar | recusado (ciclo) |
| ER-06 | campo "só agentes" no formulário | ana abre o portal | o campo não aparece |

### 5.2 Em espera, encaminhamento com retorno
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| ER-10 | ticket aberto de ana, responsável ag1 | ag1 muda para em espera | o SLA de resolução pausa; no portal, ana vê "em andamento" |
| ER-11 | ticket em espera | ana responde por e-mail | estado aberto |
| ER-12 | ticket aberto, grupo Suporte Barra, responsável ag1 | ag1 encaminha com retorno para Sistemas, com nota | grupo Sistemas, sem responsável; origem = ag1/Suporte Barra; nota interna gravada; aparece como "encaminhado por ag1" nas duas filas |
| ER-13 | após ER-12 | ag3 assume e usa "devolver" com nota | grupo Suporte Barra, responsável ag1, estado aberto; origem limpa; ag1 notificado |
| ER-14 | após ER-12 | ag3 resolve | volta para Suporte Barra, responsável ag1, estado **aberto**, nota "resolvido pela equipe Sistemas"; nenhum e-mail ao solicitante |
| ER-15 | após ER-12, ag1 desativado | ag3 devolve | volta para Suporte Barra sem responsável |
| ER-16 | após ER-12 | ag3 tenta encaminhar com retorno para um 3º grupo | recusado (1 nível no MVP) |
| ER-17 | após ER-12 | admin transfere para Eventos sem retorno | retorno cancelado; ag1 avisado |
| ER-18 | ticket sem responsável | ag1 tenta resolver (responsável obrigatório ligado) | recusado; indica responsável |
| ER-19 | idem | ag1 aplica macro que atribui "eu" e resolve | ok: atribuído a ag1 e resolvido |

### 5.3 Macros
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| ER-20 | admin cria macro com texto "Olá {{solicitante.primeiro_nome}}, ticket #{{ticket.numero}}" | aplicar no #1234 de "Ana Ribeiro" | prévia "Olá Ana, ticket #1234"; nada gravado até enviar |
| ER-21 | macro com `[NOME_DA_ESCOLA]` ou `{{escola}}` (inexistente) | admin salva | recusado; indica o marcador |
| ER-22 | macro que muda o assunto para "Helpdesk — ticket #{{ticket.numero}}" | aplicar e enviar | assunto alterado; o marcador `[PD-N]` continua nos e-mails (spec 02) |
| ER-23 | ag1 | cria macro pessoal | só ag1 a vê; ag2 não |
| ER-24 | ag1 | tenta editar macro compartilhada | recusado |
| ER-25 | macro usada 3× hoje e 0× nos 30 dias anteriores | admin abre a lista | usos em 24 h = 3; último uso = hoje |
| ER-26 | macro "atendimento no local" com variantes PT e EN; solicitante com idioma EN | ag1 aplica a macro | a prévia mostra a variante EN; ag1 pode trocar para PT antes de enviar (revisto em v0.3: Δ36 substituiu o filtro por idioma) |
| ER-27 | macro "Sending to support"-like: nota interna + encaminhar com retorno para Sistemas | aplicar e enviar | mesmo efeito de ER-12 |

### 5.4 Horário comercial, e-mails, pesquisa
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| ER-30 | quarta 10:00 | ana abre ticket | 1 e-mail de confirmação "normal"; sem etiqueta "fora do horário" |
| ER-31 | quarta 18:30 | ana abre ticket | 1 e-mail de confirmação "fora do horário"; etiqueta "fora do horário" |
| ER-32 | sábado 09:00 | ana abre ticket | idem ER-31 |
| ER-33 | ticket aberto | ag1 envia resposta pública e resolve | **um** e-mail com a resposta e o convite da pesquisa |
| ER-34 | após ER-33 | ana dá nota 2 com motivo "demorou" | avaliação gravada; aparece na fila "avaliados nos últimos 7 dias"; evento de auditoria |
| ER-35 | 8 avaliações em 60 dias: 5, 5, 4, 4, 4, 3, 5, 1 | página inicial | satisfação = 6/8 = **75%** |
| ER-36 | ticket resolvido e avaliado, reaberto e resolvido de novo 2 h depois | — | nenhum convite novo (limite de 24 h); avaliação anterior mantida |
| ER-37 | idem, resolvido de novo 25 h depois | — | novo convite enviado |
| ER-38 | ticket marcado como spam e resolvido | — | nenhum convite |

### 5.5 SLA da EARJ (calendário seg–sex 07:00–17:00, America/Sao_Paulo)
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| ER-40 | resolução em 8 h úteis; criado seg 2026-11-09 09:00 | — | vence seg 17:00 (8 h); aviso às 16:00 (1 h útil antes) |
| ER-41 | criado seg 2026-11-09 15:00, resolução 8 h úteis | — | 2 h na segunda + 6 h na terça → vence ter 2026-11-10 13:00; aviso ter 12:00 |
| ER-42 | criado sex 2026-11-13 16:30, resolução 8 h úteis | — | 0,5 h na sexta + 7,5 h na segunda → vence seg 2026-11-16 14:30; aviso seg 13:30 |
| ER-43 | ER-40 sem resolver | o relógio passa | violação registrada seg 17:00; escalonamento ao gestor 8 h úteis depois: o expediente de terça começa às 07:00, portanto **ter 2026-11-10 15:00** |
| ER-44 | criado seg 09:00, vence seg 17:00; em espera de 10:00 a 14:00 | — | 4 h pausadas → vence ter 2026-11-10 11:00; aviso ter 10:00 |
| ER-45 | aviso já enviado | o ticket fica em espera e volta a aberto antes do novo vencimento | nenhum segundo aviso para a mesma métrica |

### 5.6 Seguidores, menções, conversa paralela, chat
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| ER-50 | ag2 segue o ticket de ana | ag1 escreve nota interna | ag2 notificado; ana não recebe nada |
| ER-51 | ag2 segue | ag1 envia resposta pública | ag2 notificado no app; o e-mail a ana **não** tem ag2 em Cc |
| ER-52 | — | ag1 escreve nota "@ag3 pode ver?" num ticket que ag3 consegue ver | ag3 notificado e vira seguidor |
| ER-53 | ag3 sem acesso ao grupo | ag1 menciona @ag3 | aviso ao ag1; ag3 não é notificado |
| ER-54 | — | ag1 tenta mencionar em resposta pública | a menção não é convertida; aviso ao autor |
| ER-55 | ticket em espera | ag1 abre conversa paralela com fornecedor@lab.test | e-mail enviado ao fornecedor com Message-ID próprio; ana não recebe nada; a conversa aparece só para agentes |
| ER-56 | após ER-55 | o fornecedor responde | a mensagem entra na conversa paralela; o ticket volta a aberto; ag1 notificado; o SLA não conta como resposta do solicitante |
| ER-57 | conversa paralela encerrada | o fornecedor responde de novo | quarentena "conversa paralela encerrada" |
| ER-58 | visitante identificado (bia) no widget | envia "projetor não liga" | ticket com canal chat, solicitante bia, grupo padrão do chat |
| ER-59 | após ER-58 | ag1 responde | aparece no widget em tempo real; se bia não ler em 2 min, vai por e-mail |
| ER-60 | após ER-59, ag1 resolve | — | a pesquisa aparece no widget; nenhum e-mail de convite duplicado |

### 5.7 Filas, sequência, massa
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| ER-70 | fila compartilhada restrita ao grupo Sistemas | ag1 (sem Sistemas) lista as filas | ag1 não vê essa fila |
| ER-71 | ag1 com 10 filas pessoais | cria a 11ª | recusado |
| ER-72 | fila "sem responsável" com 3 tickets; ag2 está vendo o 2º | ag1 entra em modo sequência e envia no 1º | abre o 3º; aviso de que o 2º foi pulado |
| ER-73 | 5 tickets selecionados, 1 deles sem responsável | edição em massa: estado → resolvido | 4 resolvidos, 1 falha (responsável obrigatório); o relatório lista o motivo |
| ER-74 | fila "resolvidos nas últimas 12 h" | ticket resolvido há 11 h 59 min e outro há 12 h 01 min | só o primeiro aparece |

---

## 6. Decisões do responsável pelo projeto (2026-10-26)

| Questão | Decisão |
|---|---|
| Importação do histórico atual (R54) | **Fora do protótipo.** O protótipo usa só dados de demonstração. Se um dia for preciso, um importador a partir de um arquivo de exportação padrão, sem acessar o produto atual. |
| Pedido sem login (Δ1, Δ16) | **Permitido** no formulário e no chat, com nome e e-mail obrigatórios e o anti-spam em camadas da spec 03. O endereço fica "não verificado" até a pessoa provar que é dona (spec 01). Sem e-mail, nada é aceito. |
| Login no portal | ~~Link por e-mail como entrada principal~~ **Revisado em 2026-10-29 (Δ31):** login com Google para agentes e funcionários; o link por e-mail fica para quem não tem conta da escola. |
| IA (R46, Δ26) | **Entra no protótipo**: resumo do ticket e melhoria de texto do rascunho. Sugestão de responsável continua no roadmap. Ver regras abaixo. |
| Voz (R52) | **Fora** (roadmap). |

Regras da IA no protótipo (substituem o Δ26):
- Provedor de IA plugável, configurado pelo admin com chave de API. Sem chave,
  os botões não aparecem e nada muda no resto do produto.
- **Resumo**: o agente pede o resumo; ele é gerado a partir das mensagens
  públicas e das notas internas que esse agente pode ver e é mostrado só para
  agentes. O agente pode fixá-lo no topo do ticket. O resumo fixado registra
  quem gerou, quando e até qual mensagem cobre, e mostra o aviso
  "desatualizado" quando chegam mensagens novas.
- **Melhorar texto**: age só sobre o rascunho do agente (tom mais formal, mais
  cordial, mais curto, corrigir). A sugestão aparece ao lado e só substitui o
  rascunho se o agente aceitar. **Nada é enviado ao solicitante sem revisão.**
- Dados de solicitantes vão para o provedor apenas no momento do pedido do
  agente; nada é enviado em segundo plano. Cada uso gera evento de auditoria
  (quem, quando, qual ticket), sem guardar o conteúdo enviado.
- Falha ou demora do provedor (limite de 20 s) mostra um erro e não bloqueia o
  ticket.

Testes adicionais:
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| ER-80 | sem chave de IA configurada | ag1 abre um ticket | os botões de resumo e de melhorar texto não aparecem |
| ER-81 | com chave; ticket com 6 mensagens | ag1 pede o resumo e fixa | o resumo aparece no topo para agentes; registra autor, hora e "até a mensagem 6"; evento de auditoria |
| ER-82 | após ER-81 | chega a 7ª mensagem | o resumo fixado mostra o aviso "desatualizado" |
| ER-83 | após ER-81 | ana abre o ticket no portal | o resumo não aparece |
| ER-84 | rascunho de ag1 | ag1 pede "mais cordial" e não aceita | o rascunho continua igual; nada é enviado |
| ER-85 | o provedor não responde em 20 s | ag1 pede o resumo | mensagem de erro; o ticket segue utilizável |
| ER-86 | visitante sem login no formulário, sem e-mail | envia | recusado: e-mail obrigatório |
| ER-87 | visitante sem login com nome e e-mail novos | envia | ticket criado; a pessoa é criada com o endereço "não verificado" |

## 7. Questões abertas para o responsável pelo projeto (originais, já decididas acima)

1. **Importação do histórico atual (R54).** Trazer os ~7.200 tickets e ~1.650
   solicitantes exigiria exportar os dados da conta atual pela exportação ou
   API oficial do fornecedor atual. É uma ação normal de cliente sobre os
   próprios dados, mas o brief proíbe analisar esse produto. Proposta: não
   fazer parte do protótipo. Se for necessária, criar um importador a partir de
   um arquivo de exportação padrão (CSV/JSON), sem acessar o produto atual.
2. **Voz (R52)**: confirmar se pode ficar fora (2 tickets em 13 meses).
3. **IA (R46)**: confirmar se resumo e melhoria de texto devem entrar no
   protótipo (exigem chave de API de um provedor de IA).
4. **Visitante anônimo no chat (Δ16)** e **formulário sem login (Δ1)**: a EARJ
   quer aceitar pedidos de quem não está identificado (pais, por exemplo), ou
   tudo exige login?
5. **Login no portal**: a escola usa contas Google (o documento cita o Google
   Suite). Login com Google deveria substituir o link mágico para funcionários?
   (Exige configurar um provedor externo; fora do protótipo, com o adaptador
   previsto na spec 12.)
