# Spec 11 — Relatórios e métricas

Status: **rascunho v0.3 (2026-10-29)**. Baseado na documentação pública dos 7
projetos analisados e nos requisitos da operação EARJ (spec 13). As evidências
de runtime ainda estão pendentes; cada ponto que depende delas está marcado
como **[evidência pendente: cenário]**. Vocabulário: spec 01. Calendário de
horário comercial e estados das métricas de SLA: spec 05. Permissões: spec 06.
Filtros da lista de tickets: spec 08. Decisões transversais: D01–D53.
Precedência: spec 13 > decisões transversais > esta spec.

Mudanças na v0.3:
- **Métricas por local** a partir do **cadastro de locais** (spec 13 Δ33):
  quebra e filtro por campus, prédio, andar e sala, com "(sem local)". As
  etiquetas de campus **não** são usadas: no histórico da operação elas
  cobrem só cerca de 360 de 7.219 tickets (§6.11; RM-130..RM-133).
- **Eventos prontos até a montagem** (Δ34): nova §6.12, com o fato "pronto
  para o evento", % de prontos até a montagem e % de pedidos fora do prazo
  (RM-140..RM-144).
- **Incidentes e filhos** (Δ35): nova §6.13, com a contagem de incidentes e
  de filhos e os locais afetados; filhos contam como tickets normais nas
  outras métricas (RM-150..RM-154).
- **Satisfação sem os filhos**: resoluções de filhos pelo pai (e a do pai)
  não geram convite e ficam fora do % de satisfação e da taxa de resposta
  (§6.9; RM-151, RM-152).
- Fatos novos em §3 (local, evento, pronto, vínculo de incidente); painel com
  blocos de eventos e incidentes (§7); colunas novas no CSV (§8).
- Questão aberta nova sobre o registro do "pronto" (§14).
- **Ajustes D40–D53**: a marca "pronto para o evento" passa a ser fato
  definido (D44): posta por agente com escrita no grupo, com quem e quando,
  desfazível só até o início da montagem; a questão aberta 3 foi removida.
  Ticket de evento tem SLA de **1ª resposta** comum e **não** tem SLA de
  resolução (D40; §6.4, §6.12; RM-145, RM-146). Locais afetados de um
  incidente: salas do pai e dos filhos, sem repetição (D48; §6.13). Filho sem
  responsável resolvido pelo pai é creditado a quem resolveu o pai (D47;
  RM-156). Exemplos de quebra por campo de lista usam **motivo** em vez de
  "unidade" (D51; RM-64..RM-67 revistos).

Mudanças na v0.2:
- Estado **em espera** (D18, spec 13 Δ3) incluído no backlog, nos eventos de
  resolução e de reabertura e nas colunas do CSV; não é descontado dos tempos.
- **Pesquisa de satisfação** saiu do roadmap e entrou no MVP (D19, Δ15): nova
  §6.9, fatos de convite e avaliação, % de satisfação e taxa de resposta.
- **Quebras por campo de lista** (Δ24): filtro e tabela por qualquer campo de
  lista, com as métricas mínimas da EARJ e exportação CSV do mesmo recorte
  (§6.10, §7.1).
- **Página inicial do agente** (Δ21): números pessoais dos últimos 7 dias,
  satisfação de 60 dias e abertos nos meus grupos (§7.2).
- **SLA**: o resultado é o estado único da métrica da spec 05, e a violação é
  permanente, inclusive depois de reabertura (D10). Saíram "definida" e
  "cancelada"; não existe ticket sem política (só "sem meta").
- **Spam**: desmarcar não reabre (D16). **Exclusão de ticket** saiu da spec
  (D17); RM-53 removido.
- 1ª resposta: resposta a e-mail de notificação vira nota interna por padrão e
  não conta (D02); mensagens de **conversa paralela** (Δ17) ficam fora de
  todas as métricas; **chat** (Δ16) conta como qualquer canal.
- **Encaminhamento com retorno** (Δ5): a devolução não é resolução nem
  reabertura; novo contador "encaminhados aguardando retorno".
- Identidade de integração conforme D04 (sem "escopo de relatórios"); a API de
  métricas e a exportação em segundo plano passaram para o roadmap.
- Casos de teste alinhados à configuração de referência da spec 05 §9.1
  (calendário C1 com almoço; Financeiro em C2); valores de RM-20 a RM-23
  recalculados.
- Questões abertas respondidas foram removidas; restam 2.
- Ajustes D23–D37: o ticket encaminhado com retorno fica **aberto** no grupo
  de destino, e "encaminhado" é só uma marca derivada para a origem (D23;
  §6.5, RM-32); ticket criado por agente tem canal **agente** e o **meio
  declarado** (telefone, presencial ou outro) no evento, na quebra por canal e
  no CSV (D34; §3, §6.10, §8); os testes usam o calendário **C1 da spec 05**,
  e quem precisa de outro o define na própria linha (D35; valores conferidos à
  mão, RM-76 refeito; RM-93..RM-95).

---

## 1. Problema

Relatórios avançados são roadmap, mas as **definições** das métricas e os
**fatos** de que elas dependem precisam existir desde o MVP. Uma métrica que não
foi definida com precisão gera números diferentes em telas diferentes. Uma
métrica que depende de um fato não gravado não pode ser calculada para o
passado. O MVP precisa responder sem ambiguidade:

1. o que conta como **primeira resposta** (nota interna? resposta automática?
   integração? ticket aberto pelo próprio agente? conversa paralela?) e de onde
   o relógio parte;
2. o que é **resolução** quando o ticket é reaberto ou encaminhado: vale a
   primeira ou a última?
3. como contar **reaberturas**: por evento ou por ticket;
4. como medir o **cumprimento de SLA** sem repetir a lógica da spec 05;
5. o que é **backlog** e como fica o **volume diário** de criados e resolvidos;
6. como medir em **tempo corrido** e em **tempo útil** (horário comercial);
7. em que **fuso** começa e termina um dia, e a que período um ticket pertence;
8. o que fazer com tickets **mesclados** e **spam** (não existe exclusão de
   ticket no MVP, spec 01 §3);
9. como medir a **satisfação** e quebrar os números por **local (cadastro de
   locais), categoria e SLA**, como pede a operação EARJ (spec 13 R43, Δ33,
   D51);
10. como garantir que todo número possa ser **recalculado** a partir do
    histórico, com o mesmo resultado.

---

## 2. Princípios

- **Tudo deriva dos eventos de auditoria** (spec 01 §7). Uma métrica é uma
  função dos eventos de um ticket mais as configurações (fuso da conta,
  calendários, políticas de SLA). Não existe métrica alimentada por um contador
  separado que possa divergir do histórico.
- **Recomputável e determinística**: com os mesmos eventos e as mesmas
  configurações, o cálculo produz sempre o mesmo resultado. Valores derivados
  podem ficar guardados no ticket por desempenho (ex.: momento da primeira
  resposta), mas são cache. Se houver divergência, **os eventos vencem** e o
  cache é refeito.
- **Primeiro por ticket, depois agregado**: cada métrica de tempo é calculada
  por ticket (uma duração) e só então agregada (mediana, média, contagem). A
  duração por ticket aparece na exportação, e qualquer número do painel pode
  ser conferido somando ou ordenando as linhas exportadas.
- **Regra do evento final**: uma medida entra no período em que ficou
  definida, isto é, no momento do evento que a encerra (a resposta, a
  resolução, o desfecho do SLA, a avaliação), não no momento da criação do
  ticket. Assim, o número de um período passado não muda quando chega uma
  resposta atrasada. As exceções (medidas **móveis**) são declaradas uma a uma.
- **Sem motor externo**: as métricas do MVP são calculadas pelo próprio
  PantherDesk, a partir do banco principal. Nenhum componente adicional é
  necessário para o painel funcionar.

---

## 3. Fatos de entrada

O cálculo usa apenas os eventos de auditoria abaixo. Todos são exigidos pela
spec 01 §7 ou pelas specs que criam o fato. Esta spec só fixa **o que cada um
precisa carregar** para servir às métricas.

| Evento | Precisa carregar |
|---|---|
| Ticket criado | momento, grupo inicial, solicitante, quem criou, canal de origem (inclusive chat, spec 13 Δ16), modo de criação por agente (spec 01 §4.6), **meio declarado** (telefone, presencial ou outro) quando o canal é `agente` (D34), origem (agente, solicitante, sistema, automação, API) |
| Mensagem criada | momento, autor, **tipo de autor no momento** (ver abaixo), visibilidade (pública ou nota interna), marca de mensagem de sistema, **linha** (conversa principal ou conversa paralela, spec 13 Δ17), origem |
| Estado alterado | momento, antes, depois, origem |
| Grupo alterado | momento, antes, depois |
| Responsável alterado | momento, antes, depois |
| Campo alterado | momento, campo (de sistema, como prioridade e tipo, ou personalizado, pela chave), antes, depois |
| Etiqueta adicionada/removida | momento, etiqueta |
| Encaminhado com retorno / devolvido / retorno cancelado | momento, grupo e agente de origem, grupo de destino (spec 13 Δ5) |
| Marcado como spam / desmarcado | momento, ator (evento próprio, spec 01 §4.1; ver §5.2) |
| Ticket mesclado | momento, origem, destino |
| SLA: aviso e SLA: violação | momento, métrica (1ª resposta ou resolução), prazo vigente, política (spec 05 §7.10–§7.12) |
| Convite de pesquisa enviado | momento, resolução a que se refere, meio (e-mail, portal ou chat) |
| Avaliação registrada / alterada | momento, convite, nota (1 a 5), motivo (se houver) |
| Local alterado | momento, sala antes e depois (do cadastro de locais, spec 13 Δ33), origem do local (QR, formulário, agente, API); o campus, o prédio e o andar vêm do cadastro, não do evento |
| Dados do evento alterados | momento, tipo de evento, data, início, fim e **início da montagem** antes e depois; marca "fora do prazo" na criação (Δ34) |
| Marcado / desmarcado "pronto para o evento" | momento, ator (agente com escrita no grupo; D44, spec 01 §5.2); desmarcar só é aceito antes do início da montagem |
| Marcado / desmarcado como incidente pai; filho vinculado / desvinculado | momento, pai, filho (Δ35); na resolução em cascata, o evento de estado de cada filho leva o pai como causa |

O **estado de cada métrica de SLA** (spec 05 §7.13) é derivado pela spec 05 a
partir desses eventos, das políticas e dos calendários. Esta spec usa esse
estado como está e não o recalcula com regras próprias.

**Tipo de autor** de uma mensagem: solicitante, participante, agente,
identidade de integração, automação ou sistema. Ele é diferente da **origem**
do evento (spec 01 §7), que diz por qual caminho a mudança entrou. Regras:
- É gravado no momento da mensagem e nunca recalculado a partir dos papéis
  atuais. Um agente desativado depois continua contando como agente nas
  mensagens antigas.
- Se o autor é o **solicitante** do ticket, o tipo é solicitante, mesmo que a
  pessoa também seja agente.
- Mensagens de **identidades de integração** (spec 12 §5) têm tipo identidade
  de integração, nunca agente: a integração nunca conta como humano (D04).
- Mensagens geradas por **automações** (gatilhos, auto-respostas de criação)
  têm tipo automação, mesmo quando aparecem assinadas com o nome de um agente.
- Uma macro aplicada **por um agente** produz mensagem com tipo agente: quem
  decidiu enviar foi uma pessoa.
- Uma resposta de agente enviada a partir do e-mail de notificação (spec 02 §5)
  tem tipo agente. Por padrão ela vira **nota interna** (D02); só é pública se
  a conta tiver mudado o padrão para "pública".
- Mensagem do visitante no widget de chat tem tipo solicitante.
- Mensagens de **conversa paralela** (spec 13 Δ17), enviadas ou recebidas,
  ficam **fora de todas as métricas**: não são resposta ao solicitante nem
  atividade do solicitante.
- Uma resposta enviada pela API com o **token pessoal** de um agente tem tipo
  agente. Robôs devem usar identidade de integração (spec 12 §5); o uso de
  token pessoal por robôs é regra de uso, não impedimento técnico.

---

## 4. Tempo, fuso e períodos

### 4.1 Relógio e precisão
- Todos os momentos são gravados em UTC, com precisão de pelo menos 1 segundo.
- Durações por ticket são calculadas em **segundos inteiros** (truncando
  frações). A agregação usa os segundos; o arredondamento só acontece na
  exibição.
- Eventos da mesma transação têm o mesmo momento; a ordem entre eles é a ordem
  de gravação.

### 4.2 Fuso da conta e limites de dia
- Cada conta tem um **fuso horário** (padrão no MVP: America/Sao_Paulo).
- Um **dia** vai das 00:00:00 (inclusive) às 00:00:00 do dia seguinte
  (exclusive), **no fuso da conta**. Em fusos com horário de verão, um dia pode
  ter 23 ou 25 horas; isso é aceito.
- Exemplo: um ticket criado em 2026-11-04T02:30Z é do dia **2026-11-03** numa
  conta em America/Sao_Paulo (23:30 local).
- Relatórios e página inicial usam **sempre o fuso da conta**, mesmo para um
  agente que escolheu outro fuso na preferência pessoal (spec 13 Δ23). A tela
  indica o fuso usado. Motivo: dois agentes olhando o mesmo período veem o
  mesmo número.
- Se o admin muda o fuso da conta, os períodos passados são recalculados no fuso
  novo. Números de dias passados podem mudar, e o painel avisa isso na tela de
  configuração do fuso (ver Questões abertas).

### 4.3 Períodos
- Todo período é um intervalo **[início, fim)** em dias inteiros do fuso da
  conta.
- Atalhos no MVP: **hoje**; **últimos 7 dias** (hoje e os 6 dias anteriores);
  **últimos 30 dias** (hoje e os 29 anteriores); **últimos 60 dias** (hoje e os
  59 anteriores; usado pela satisfação, §6.9); **mês atual**; **mês
  anterior**; **intervalo personalizado** de até 366 dias.
- Um fato entra no período se o momento do evento que o define (regra do evento
  final, §2) está dentro do intervalo.

### 4.4 Tempo corrido e tempo útil
Toda métrica de tempo tem duas variantes, calculadas sobre o **mesmo
intervalo**:

| Variante | Definição |
|---|---|
| **Tempo corrido** | Diferença simples entre fim e início. |
| **Tempo útil** | Soma dos trechos do intervalo que caem dentro do horário de trabalho do calendário, excluídos os feriados. |

- O calendário (dias da semana, janelas de horário, feriados e o fuso do próprio
  calendário) é o **calendário da spec 05 §7.3**. Esta spec não define outro.
- Qual calendário usar: o da **política de SLA vigente** no ticket **no momento
  do evento final** da métrica. Todo ticket tem uma política vigente, porque a
  política padrão não tem condições e sempre casa (spec 05 §7.1). O calendário
  vale mesmo que a política não tenha meta para a prioridade do ticket. Numa
  conta nova, a política padrão usa o calendário "sempre aberto" (spec 05
  §7.3); nesse caso tempo útil = tempo corrido.
- O cálculo usa a definição **atual** do calendário. Se o admin acrescenta um
  feriado no passado, o tempo útil de tickets antigos é recalculado (ver
  Questões abertas).
- **Pausas não descontam**: o tempo em **pendente** e em **em espera** conta
  normalmente nas métricas desta spec. A pausa por estado (spec 01 §4.1, coluna
  "categoria de SLA") vale só para os prazos de SLA da spec 05. Assim, "tempo
  de resolução" mede o que o cliente viveu, e "cumprimento de SLA" mede o
  contrato.

---

## 5. Universo de tickets

Por padrão, toda métrica e todo contador do painel considera **todos os
tickets da conta**, exceto os listados abaixo. A retirada do universo é
**retroativa**: um ticket fora do universo deixa de contar em todos os
períodos, inclusive em dias já passados, e as avaliações dele também saem.

### 5.1 Mesclados
- O ticket **origem** de uma mescla (estado mesclado, spec 01 §6) sai do
  universo: não conta como criado, não entra em tempos, reaberturas, SLA,
  satisfação nem backlog. Motivo: era uma duplicata; contá-lo inflaria o volume
  e a fila.
- O ticket **destino** conta normalmente, com **seus próprios eventos**. As
  mensagens que vieram da origem aparecem na conversa, mas não alteram o
  momento de criação nem a primeira resposta do destino (spec 01 §6 item 5).
  Uma resposta de agente dada na origem antes da mescla foi enviada ao
  solicitante da origem, não ao do destino.
- Mesclar não é resolução nem reabertura do destino.

### 5.2 Spam
- Um ticket **marcado como spam** (spec 01 §4.1) sai do universo enquanto a
  marcação valer.
- O critério é o **evento de marcação como spam** (e o de desmarcação), não a
  etiqueta `spam` sozinha. Vale o último dos dois eventos.
- As mudanças de estado gravadas na mesma transação de uma marcação (ir para
  fechado) **não** contam como resolução.
- **Desmarcar não reabre** (D16): o ticket volta ao universo, continua
  **fechado** e não entra no backlog. Se ele nunca teve um evento de resolução
  válido, fica sem 1ª resolução.
- Mensagens retidas em quarentena (spec 02 §3) nunca viraram ticket e nunca
  entram em métrica.

### 5.3 Excluídos
Removida na v0.2: **não existe exclusão de ticket no MVP** (spec 01 §3, D17).
A seção fica sem conteúdo para não renumerar as seguintes.

### 5.4 Continuações
- O ticket novo criado pela política `novo` ou `janela` (spec 01 §4.4) ou pela
  ação manual **"criar continuação"** (spec 13 Δ13) é um ticket como outro
  qualquer: conta como criado no dia da criação e tem sua própria primeira
  resposta. O ticket anterior não ganha reabertura.

---

## 6. Definições das métricas

### 6.1 Tempo de primeira resposta (1ª resposta)

| Elemento | Definição |
|---|---|
| Início | Momento de **criação do ticket**. |
| Fim | Momento da primeira **resposta humana de agente**: mensagem **pública** da conversa principal, tipo de autor **agente**, que não é mensagem de sistema. Vale qualquer canal: e-mail, portal, chat, interface ou API com token pessoal. |
| Não contam | notas internas (inclusive a resposta a e-mail de notificação no padrão da conta, D02); mensagens de sistema (resposta automática recebida, bounce); mensagens de automações (auto-resposta de criação, gatilhos); mensagens de identidades de integração; mensagens de conversa paralela; mensagens do solicitante e de participantes. |
| Aplicabilidade | A métrica vale para o ticket se a **primeira mensagem pública** dele foi escrita pelo solicitante ou por um participante. Se a primeira mensagem pública foi escrita por um agente (modo **contato proativo**, spec 01 §4.6), a métrica **não se aplica**: ninguém esperava resposta. |
| Período | Dia do fim (regra do evento final). |
| Sem resposta | Ticket resolvido ou fechado sem nenhuma resposta humana de agente fica **sem valor** de 1ª resposta e fora da mediana. A exportação mostra a coluna vazia. |

Consequências:
- **Ticket criado pelo agente** (spec 01 §4.6): no modo **registrar pedido**
  (padrão), a mensagem inicial é do solicitante, com a marca "registrada por
  {agente}"; a métrica se aplica e conta a partir da criação. No modo
  **contato proativo**, a mensagem inicial é pública do agente e o ticket fica
  fora.
- **Encaminhamento por agente** (spec 02 §5): o solicitante é o remetente
  original e a mensagem de abertura é dele. A nota do agente é interna. A
  métrica se aplica normalmente a partir da criação.
- A resposta conta no momento em que é **gravada**, mesmo que a entrega do
  e-mail falhe depois (spec 02 §9) ou que o endereço esteja inválido. No chat,
  conta quando é gravada, não quando o visitante a lê.
- A métrica é coerente com o indicador "sem primeira resposta" (spec 01 §4.1):
  o indicador desliga no mesmo evento que encerra a 1ª resposta. Uma resposta de
  integração ou automação não desliga o indicador.
- Esta definição coincide com a da spec 05 §7.6 para o SLA. As duas olham o
  mesmo evento.
- **Filho de incidente** (spec 13 Δ35): a resposta pública escrita no pai e
  registrada no filho é uma mensagem pública de agente humano **no filho**,
  enviada ao solicitante dele; ela conta como 1ª resposta do filho, no
  momento em que é gravada. Respostas do pai anteriores ao vínculo não foram
  enviadas ao solicitante do filho e não contam para ele.

### 6.2 Tempo de resolução

**Evento de resolução**: transição de **aberto, pendente ou em espera** para
**resolvido ou fechado**, inclusive pela ação do solicitante "meu problema foi
resolvido" (D08). Não são resolução:
- a passagem de resolvido para fechado (manual ou pelo fechamento automático);
- ir para mesclado;
- a mudança de estado gravada junto com a marcação como spam (§5.2);
- a **devolução** de um encaminhamento com retorno (spec 13 Δ5), inclusive
  quando o agente do grupo de destino usa "resolver": o ticket volta **aberto**
  ao grupo de origem, e a resolução só acontece quando o grupo de origem
  resolver o ticket para o solicitante.

| Métrica | Definição | Período | Estabilidade |
|---|---|---|---|
| **1ª resolução** | Da criação do ticket ao **primeiro** evento de resolução. | dia do primeiro evento de resolução | **estável**: depois de definida, nunca muda |
| **Resolução final** | Da criação do ticket ao **último** evento de resolução. Só existe enquanto o estado atual do ticket for resolvido ou fechado. | dia do último evento de resolução | **móvel**: se o ticket reabre, sai do período em que estava e só volta quando for resolvido de novo, no dia da nova resolução |

- O painel do MVP mostra a **1ª resolução**, junto com a taxa de reabertura
  (§6.3). Os dois juntos mostram o efeito das reaberturas sem fazer números de
  períodos passados oscilarem. A resolução final aparece na exportação.
- O tempo em pendente e em espera **não** é descontado (§4.4).
- A resolução de um filho pela resolução do pai (Δ35) é um evento de
  resolução **do filho**, como qualquer outro: o solicitante dele teve o
  pedido resolvido. O pai e cada filho resolvido contam em "resolvidos" do
  dia. O painel permite ver quantos desses vieram de incidentes (§6.13).

### 6.3 Reaberturas

**Evento de reabertura**: transição de **resolvido ou fechado** para **aberto,
pendente ou em espera**, por qualquer origem: resposta do solicitante, ação de
agente (resolvido → pendente também conta: a equipe desfez a própria
resolução), reabertura por admin de ticket fechado.

| Métrica | Definição |
|---|---|
| **Reaberturas do ticket** | Número de eventos de reabertura do ticket até o momento do cálculo. |
| **Reaberturas no período** | Número de eventos de reabertura cujo momento cai no período (contagem de eventos). |
| **Taxa de reabertura** | Entre os tickets cuja **1ª resolução** caiu no período, a porcentagem que tem **pelo menos uma** reabertura até o momento do cálculo. |

Não são reabertura:
- pendente ou em espera → aberto pela data de retorno (spec 01 §4.3);
- em espera → aberto por resposta recebida numa conversa paralela (Δ3, Δ17);
- a devolução de um encaminhamento com retorno (§6.2);
- a continuação por política `novo` ou por "criar continuação" (§5.4).

A taxa de um período passado pode subir quando um ticket resolvido naquele
período é reaberto depois. O painel deixa isso explícito no texto de ajuda da
métrica.

### 6.4 Cumprimento de SLA

Os prazos, a pausa por estado, os avisos e a violação são da spec 05. Esta spec
só conta os **resultados** que a spec 05 define.

| Elemento | Definição |
|---|---|
| Metas | Separadas: **1ª resposta** e **resolução**. Nunca se misturam num único percentual. |
| Resultado | Um **único resultado por métrica e por ticket** (D10): o estado da métrica da spec 05 §7.13 (em andamento, pausada, cumprida, violada, encerrada sem resposta, encerrada por mescla, encerrada por spam). Ticket sem meta para a sua prioridade na política vigente fica **sem meta** naquela métrica. |
| Violação permanente | Se a métrica violou em algum momento, o resultado é **violada** para sempre (D10, spec 05 §7.11). Resolução cumprida, depois reaberta e que passa do prazo, termina **violada**. |
| Momento do resultado | Violada: o **instante registrado da violação** (o prazo, ou o instante do recálculo numa violação imediata, spec 05 §7.12), mesmo que a resposta chegue depois. Cumprida: momento do evento que satisfez a meta (a 1ª resposta; para resolução, o evento de resolução mais recente). |
| Estabilidade | 1ª resposta cumprida e qualquer violada são **estáveis**. Resolução cumprida é **móvel**, como a resolução final (§6.2): na reabertura, a métrica volta para em andamento (spec 05 §7.8) e sai do período em que estava contada; ela volta a contar no período da nova resolução (se cumprida) ou no da violação. |
| % de cumprimento | cumpridas ÷ (cumpridas + violadas) × 100, entre os resultados cujo momento cai no período. Ficam fora: em andamento, pausada, encerrada sem resposta, encerradas por mescla ou por spam, e "sem meta". |
| Ticket de evento | A **1ª resposta** segue a política comum e entra no % de 1ª resposta como qualquer ticket. A **resolução** comum não se aplica (D40, spec 05 §7.14): o ticket de evento não tem resultado de resolução e fica fora do % de resolução, aparecendo como "sem meta" nessa métrica. O compromisso dele é medido à parte (§6.12). |

O painel também mostra dois contadores instantâneos, vindos da spec 05:
**SLA: aviso emitido** (métricas com aviso emitido, na forma percentual ou na
de tempo útil absoluto da spec 13 Δ14, ainda em andamento ou pausadas) e
**violadas em tickets ainda no backlog**.

### 6.5 Backlog por estado e por grupo

- **Backlog** num instante T = tickets do universo cujo estado em T é
  **aberto, pendente ou em espera**.
- Agrupamento por **estado em T** e por **grupo em T**. No painel, T = agora.
- O painel também mostra, no mesmo instante: tickets **resolvidos** (ainda não
  fechados, fora do backlog), tickets abertos com indicador "sem primeira
  resposta", tickets do backlog **sem responsável** e, para cada grupo de
  origem, os tickets **encaminhados com retorno aguardando devolução** (spec 13
  Δ5). O ticket encaminhado está no estado **aberto** e conta no backlog do
  **grupo de destino**, que é o grupo dele enquanto o encaminhamento durar
  ("encaminhado" é uma marca derivada da origem registrada, não um estado,
  D23); o contador de encaminhados é uma
  informação a mais para o grupo de origem e não entra no total.
- Fechados e mesclados nunca entram no backlog.
- Como o estado e o grupo em qualquer instante passado podem ser reconstruídos
  pelos eventos, o backlog de um instante passado é recomputável. A série
  histórica de backlog fica para o roadmap (§10).

### 6.6 Volume diário

Para cada dia do período, no fuso da conta:

| Série | Conta |
|---|---|
| **Criados** | tickets do universo cujo evento de criação caiu no dia |
| **Resolvidos** | **eventos de resolução** no dia (um ticket resolvido em dois dias diferentes conta nos dois) |
| **Reabertos** | eventos de reabertura no dia |

Verificação de consistência (vale para cada grupo e para a conta):
backlog no fim do dia = backlog no início do dia + criados + reabertos −
resolvidos. Passar entre aberto, pendente e em espera não altera o backlog. A
mudança de grupo de um ticket do backlog (transferência, encaminhamento ou
devolução) altera o backlog de cada grupo (sai de um, entra no outro), mas não
o total da conta.

### 6.7 Agregação e exibição

- **Mediana** é a medida principal de tempo no painel; a **média aritmética** e
  o **n** (quantos tickets entraram) aparecem junto. Motivo: poucos tickets
  esquecidos distorcem muito a média.
- Mediana com n par = média dos dois valores centrais.
- Conjunto vazio: exibir "—" (nunca 0). Percentual com denominador 0: "—".
- Exibição de durações: abaixo de 120 min, em minutos inteiros (arredondamento
  para o mais próximo, metade para cima); a partir daí, em horas com uma casa
  decimal. Percentuais com uma casa decimal, metade para cima.
- A exportação traz as durações em **segundos**, sem arredondamento.

### 6.8 Atribuição a grupo e a agente

Cada fato pertence ao **grupo do ticket no momento do evento que o define**:

| Fato | Grupo considerado | Agente considerado (página inicial, §7.2) |
|---|---|---|
| Criado | grupo ao fim do processamento da criação, já com os gatilhos de criação aplicados (spec 05) | — |
| 1ª resposta | grupo no momento da primeira resposta | **autor** da primeira resposta |
| 1ª resolução / resolução final / resolvido do dia | grupo no momento do evento de resolução correspondente | **responsável** no momento do evento de resolução; sem responsável, nenhum |
| Reabertura | grupo no momento da reabertura | — |
| Resultado de SLA | grupo no momento do resultado | — |
| Avaliação | grupo no momento da resolução que gerou o convite | responsável no momento dessa resolução |
| Backlog | grupo no instante T | — |

- "Processamento da criação" = a gravação da criação mais a passada de
  gatilhos disparada pelo evento de criação (spec 05 §3.4), que roda depois da
  gravação. Os eventos dessa passada levam a regra e o evento de origem, e é
  por eles que o cálculo os reconhece.
- Num encaminhamento com retorno, o tempo em que o ticket está no grupo de
  destino conta para o grupo de destino (spec 13 Δ5), pela mesma regra.

Agrupar pelo grupo **atual** (como faz um dos projetos) reescreveria o passado a
cada transferência; agrupar pelo momento do evento mantém os números estáveis.

### 6.9 Satisfação (pesquisa)

O envio do convite, a escala e as regras de quando não enviar são da spec 13
Δ15 (e da spec 05, que dispara o convite). Esta seção define as métricas.

| Elemento | Definição |
|---|---|
| Avaliação | Uma por **convite**, e um convite por **resolução** (no máximo 1 convite por ticket a cada 24 h, Δ15). Escala 1 a 5, motivo opcional (lista do admin, para notas 1 a 3) e comentário opcional. Vale pelo e-mail, pelo portal ou pelo widget de chat; o meio não muda a contagem. |
| Valor | A **última** nota dada àquele convite. O solicitante pode alterar até o ticket fechar (Δ15). |
| Período | Dia da **primeira** resposta àquele convite (regra do evento final). Alterar a nota muda o valor, não o período. |
| Satisfeito | Nota 4 ou 5. |
| **% de satisfação** | satisfeitos ÷ avaliações × 100, entre as avaliações do período. Convites sem resposta **não** entram no denominador. |
| **Taxa de resposta** | Entre os convites enviados no período, a porcentagem que recebeu avaliação até o momento do cálculo. Pode subir depois, como a taxa de reabertura. |
| Distribuição | Quantidade de avaliações por nota (1 a 5) e por motivo. |
| Universo | Avaliações de tickets fora do universo (mesclados na origem, spam) não contam (§5). |

- Um ticket reaberto e resolvido de novo depois de 24 h recebe novo convite;
  as duas avaliações contam, cada uma no seu período. Resolvido de novo antes
  de 24 h, não há convite novo e a avaliação anterior continua valendo.
- A avaliação de um encaminhamento devolvido não existe: a devolução não é
  resolução (§6.2) e não gera convite.
- **Sem os filhos de incidente** (spec 13 Δ35): a resolução de um filho feita
  pela resolução do pai, e a do próprio pai, **não** geram convite. Como não
  há convite, essas resoluções não entram no % de satisfação nem na taxa de
  resposta, e não existe "não avaliado" a contar por elas. Uma avaliação
  dada a uma resolução **anterior** ao vínculo (o ticket foi resolvido,
  avaliado, reaberto e só então vinculado) continua valendo no seu período:
  era uma resolução própria do ticket. Um filho **desvinculado** e resolvido
  depois, por conta própria, volta a receber convite normalmente.

### 6.10 Quebras e filtros por campo de lista

O painel filtra e quebra os números por **campo de lista** (spec 13 Δ24), além
de grupo e período.

- Campos que podem quebrar: os campos de sistema de lista (prioridade, tipo do
  ticket, canal, e o **meio declarado** dos tickets de canal `agente`, D34,
  com a linha "(sem valor)" para os demais canais) e os campos personalizados
  de **escolha única** do ticket, da
  **pessoa** solicitante e da **organização** dela (spec 13 Δ22). Campos de
  escolha múltipla servem como **filtro**, mas não como quebra no MVP: um
  ticket com dois valores apareceria em duas linhas e a soma não bateria.
- Valor considerado: o **valor atual** do campo no momento do cálculo, não o do
  momento do evento. Motivo: classificação corrigida pelo agente (ex.: motivo
  errado no formulário) deve corrigir o relatório; a transferência de grupo,
  ao contrário, é fluxo de trabalho, por isso o grupo segue o evento (§6.8). Um
  ticket fechado não muda mais de campo (spec 01 §4.1), então o valor dele se
  estabiliza.
- Ticket sem valor no campo aparece na linha **"(sem valor)"**. Opção
  desativada aparece com o rótulo atual e a marca "(inativa)".
- Campo condicional limpo por ficar oculto (spec 13 Δ2) fica sem valor.
- A linha de total é calculada direto sobre todos os tickets do recorte. A
  mediana do total **não** é a média das medianas das linhas.
- O **local** do ticket não é campo de lista: tem quebra própria (§6.11).

### 6.11 Quebras e filtros por local (spec 13 Δ33)

O painel quebra e filtra os números pelo **local do ticket**, que vem do
**cadastro de locais** (campus → prédio → andar → sala), escolhido pelo QR, pelo
formulário ou pelo agente. **Etiquetas não são usadas** para local: no
histórico da operação EARJ as etiquetas de campus cobrem só cerca de 360 de
7.219 tickets, e o Δ33 as dispensa.

- Níveis de quebra: **campus**, **prédio**, **andar** e **sala**. Na quebra por
  um nível, cada ticket cai numa linha só, a do seu local naquele nível; a
  soma das linhas, mais "(sem local)", bate com o total.
- Valor considerado: o **local atual** do ticket e a **hierarquia atual** do
  cadastro, no momento do cálculo, pela mesma razão dos campos de lista
  (§6.10): local corrigido pelo agente corrige o relatório. Renomear uma sala
  muda só o rótulo da linha; o código continua o mesmo.
- Sala **desativada** aparece com o nome atual e a marca "(inativa)"; os
  tickets dela continuam contando.
- Ticket sem local (inclusive os que só têm uma etiqueta de campus) fica na
  linha **"(sem local)"**.
- Filtro por local aceita qualquer nível; um nível acima inclui todas as
  salas dele.
- As métricas da linha são as mesmas da tabela de quebra (§7.1).

### 6.12 Eventos prontos até a montagem (spec 13 Δ34)

O compromisso de um ticket de evento é estar **pronto até o início da
montagem**. A medida depende do fato **"pronto para o evento"**, uma marca no
ticket de evento (D44, spec 01 §5.2): posta por agente com escrita no grupo,
registra quem e quando, gera evento de auditoria (§3) e pode ser desfeita até
o início da montagem. Depois da montagem, a marca ainda pode ser posta (conta
como "pronto atrasado"), mas não retirada.

| Elemento | Definição |
|---|---|
| Universo | Tickets do tipo evento (pelo formulário de evento ou por mudança de tipo, D56) do universo da §5. |
| Montagem | O **início da montagem vigente** do ticket. Se a montagem muda, vale a última gravada. |
| Período | Dia do início da montagem, no fuso da conta (regra do evento final: a medida fica definida na montagem). Montagem ainda no futuro: o evento está "em andamento" e não entra. |
| **Pronto no prazo** | A marca "pronto" está **ligada no instante do início da montagem**. Marcar e desmarcar antes da montagem não conta. Como a marca não pode ser retirada depois da montagem (D44), o resultado fica estável. |
| **Pronto atrasado** | A marca foi ligada pela primeira vez depois do início da montagem. Informativo; não é "no prazo". |
| **Não pronto** | Nenhuma marca ligada até agora. |
| Fora do denominador | Ticket de evento resolvido, fechado, mesclado ou marcado como spam **antes** da montagem sem a marca ligada (evento cancelado ou pedido duplicado). |
| **% prontos até a montagem** | prontos no prazo ÷ (eventos com montagem no período − fora do denominador) × 100. |
| **% de pedidos fora do prazo** | Entre os tickets de evento **criados** no período, a porcentagem com a marca "fora do prazo" da criação (antecedência mínima, Δ34). |

- A medida é estável depois da montagem, salvo se a data da montagem mudar
  depois (o evento muda de período, como uma métrica móvel).
- Quebras: tipo de evento e local (§6.11). Grupo: o do ticket no instante da
  montagem (§6.8).
- O selo de prazo do evento ("faltam N dias", "faltam N h", "pronto",
  "montagem sem pronto", "evento encerrado"; D40, spec 05 §7.15) e os avisos
  (spec 05 §7.14, spec 09 §7.6) não entram nesta métrica; ela olha só a marca
  no instante da montagem.
- O **tempo** de 1ª resposta (§6.1), o tempo de resolução (§6.2) e a
  satisfação continuam medidos para o ticket de evento como para qualquer
  ticket. No **SLA** (§6.4), só a 1ª resposta tem meta; a resolução comum não
  se aplica (D40). A resolução normalmente acontece depois do evento (Δ34) e
  não tem relação com "pronto".

### 6.13 Incidentes e filhos (spec 13 Δ35)

| Métrica | Definição |
|---|---|
| **Incidentes** | Tickets marcados como **pai**, contados no dia da marcação. Um ticket desmarcado como pai sai da contagem (retroativo, como o universo da §5). |
| **Filhos** | Para os incidentes do período, a soma dos filhos **vinculados no momento do cálculo** (valor atual: um desvínculo corrige o número). |
| Filhos por incidente | Mediana, com média e n, sobre os incidentes do período. |
| Locais afetados | Quantidade de salas distintas do **pai e dos filhos**, sem repetição, por incidente (D48), com os valores atuais; ticket sem local não soma. Na quebra por local (§6.11), cada incidente conta na linha do local do **pai**. |
| Resoluções por incidente | Eventos de resolução de filhos causados pela resolução do pai, no período; parte dos "resolvidos" da §6.6, mostrada à parte. |

- Pai e filhos são tickets do universo como quaisquer outros: cada filho
  conta em criados (cada solicitante abriu o seu), tem a sua 1ª resposta
  (§6.1), a sua resolução (§6.2) e o seu SLA (spec 05). O painel tem o filtro
  **"filhos de incidente": incluir (padrão) / excluir / só filhos**, que vale
  para todas as métricas, para quem quiser ver o volume sem as duplicatas de
  um incidente.
- Satisfação: ver §6.9 (sem os filhos).
- Resolução em cascata de filho **sem responsável**: o filho recebe como
  responsável quem resolveu o pai e então é resolvido (D47). Pela §6.8, a
  resolução dele conta para esse agente nos números pessoais.

---

## 7. Painel do MVP

Uma única tela, para admin e agentes.

**Filtros**
- Período (atalhos de §4.3); padrão: últimos 7 dias.
- Grupo: um grupo ou "todos os meus grupos". A lista só mostra os grupos a que
  o usuário tem acesso de leitura ou escrita (spec 06 §3).
- Campos de lista (§6.10): um ou mais valores por campo.
- Local (§6.11): campus, prédio, andar ou sala, ou "(sem local)".
- Filhos de incidente (§6.13): incluir (padrão), excluir ou só filhos.
- Alternância **tempo útil / tempo corrido**; padrão: tempo útil.

**Contadores instantâneos** (agora; dependem do filtro de grupo e dos filtros
de campo)
- Backlog total, abertos, pendentes, em espera; resolvidos ainda não fechados.
- Abertos sem primeira resposta; backlog sem responsável; encaminhados com
  retorno aguardando devolução (por grupo de origem).
- SLA: aviso emitido; violadas no backlog.
- Tabela **estado × grupo** do backlog.

**Métricas do período**
1. Mediana do tempo de 1ª resposta (com média e n).
2. Mediana do tempo de 1ª resolução (com média e n).
3. Taxa de reabertura (com o número de reaberturas no período).
4. % de cumprimento de SLA de 1ª resposta e % de resolução (com cumpridas e
   violadas).
5. % de satisfação (com n e distribuição por nota) e taxa de resposta da
   pesquisa.
6. Gráfico diário de criados, resolvidos e reabertos.
7. **Eventos** (§6.12): % prontos até a montagem (com prontos no prazo,
   atrasados, não prontos e n) e % de pedidos fora do prazo.
8. **Incidentes** (§6.13): incidentes, filhos, mediana de filhos por
   incidente e resoluções por incidente.

### 7.1 Tabela de quebra (spec 13 Δ24)
- O usuário escolhe a quebra: nenhuma, grupo, um campo de lista (§6.10) ou um
  nível de local (§6.11: campus, prédio, andar ou sala).
- Uma linha por valor, mais "(sem valor)" e o total. Colunas: criados;
  resolvidos; mediana da 1ª resposta (com n); mediana da 1ª resolução (com n);
  % de SLA de 1ª resposta; % de SLA de resolução; % de satisfação (com n).
  O "% dentro do SLA" pedido pela EARJ aparece como duas colunas, porque as
  metas nunca se misturam (§6.4).
- A tabela pode ser exportada em CSV com os mesmos filtros e a mesma quebra,
  uma linha por valor, durações em segundos. O download é imediato (a tabela é
  pequena).

### 7.2 Página inicial do agente (spec 13 Δ21)
Números da página inicial (o feed de menções, atribuições e avisos é da spec
09):
- **Meus números dos últimos 7 dias** (§4.3): eventos de resolução em que eu
  era o responsável; mediana das 1ª respostas que eu escrevi (com n);
  avaliações recebidas (atribuídas a mim pela §6.8), com a distribuição.
- **Satisfação de 60 dias**: a **minha** (avaliações atribuídas a mim) e a **da
  conta** (todas as avaliações do universo). A da conta é um único número com
  n, sem lista de tickets por trás para quem não tem acesso a todos os grupos:
  é a única exceção ao recorte por grupo, pedida pela spec 13.
- **Abertos nos meus grupos**: contagem do backlog por estado (aberto,
  pendente, em espera) nos grupos em que tenho leitura ou escrita.
- Um agente sem nenhuma resolução nem avaliação vê "—" nos números pessoais.

**Comportamento (painel e página inicial)**
- Os números podem ter até **5 minutos** de atraso em relação aos eventos. A
  tela mostra o momento do cálculo ("calculado às HH:MM").
- Cada número leva à lista de tickets que o compõem (mesmos filtros da spec 08),
  de onde se pode exportar o CSV (§8). A soma da lista bate com o número.
- O painel não tem configuração própria no MVP: não há widgets, metas nem
  cores definidos pelo usuário.
- A API de métricas fica para o roadmap (§10). No MVP, quem precisa dos números
  fora da tela usa a exportação CSV.

---

## 8. Exportação CSV de tickets

- Disponível a partir da lista de tickets e de qualquer número do painel:
  exporta **exatamente** o resultado do filtro corrente (spec 08), restrito aos
  tickets que o usuário pode ver (grupos com leitura ou escrita, spec 06 §6.2).
- **Só metadados**: nenhum corpo de mensagem, nenhuma nota interna, nenhum
  anexo, nenhum comentário de avaliação.
- Uma linha por ticket. Colunas, nesta ordem: número; assunto; estado (aberto,
  pendente, em espera, resolvido, fechado, mesclado); tipo; prioridade; grupo;
  responsável; solicitante (nome); e-mail principal do solicitante;
  organização; canal de criação; meio declarado (só para canal `agente`,
  D34); criado em; 1ª resposta em; 1ª resposta
  corrida (s); 1ª resposta útil (s); 1ª resolução em; 1ª resolução corrida (s);
  1ª resolução útil (s); última resolução em; resolução final corrida (s);
  resolução final útil (s); fechado em; reaberturas; SLA de 1ª resposta (em
  andamento, pausada, cumprida, violada, encerrada sem resposta, encerrada por
  mescla, encerrada por spam ou sem meta); SLA de resolução (idem); avaliações
  (quantidade); última nota; etiquetas; mesclado em (número do destino); spam
  (sim/não); campus; prédio; andar; sala (código e nome); origem do local
  (QR, formulário, agente, API); incidente pai (número, vazio se não é
  filho); é incidente pai (sim/não); filhos (quantidade); tipo de evento;
  início do evento; início da montagem; fora do prazo (sim/não); pronto
  (no prazo, atrasado, não pronto, em andamento ou fora do denominador; vazio
  se não é evento); depois, uma coluna por **campo personalizado ativo** do ticket, e
  em seguida os da pessoa solicitante e os da organização, com o rótulo atual
  como cabeçalho.
- Diferente do painel, a exportação **não esconde** mesclados nem spam: ela
  reflete a lista, e as colunas "mesclado em" e "spam" permitem filtrar.
- Formato: UTF-8 com marca de ordem de bytes (para planilhas abrirem os acentos
  corretamente); separador vírgula ou ponto e vírgula, escolhido na exportação.
  O padrão segue o idioma da conta: **ponto e vírgula** em português, vírgula
  em inglês, porque planilhas em português usam a vírgula como separador
  decimal. Aspas duplas conforme o padrão usual de CSV; quebras de linha dentro
  de campos preservadas entre aspas.
- Momentos em ISO 8601 no fuso da conta, com deslocamento (ex.:
  `2026-11-03T10:00:00-03:00`). Durações em segundos inteiros. Valores vazios
  quando a métrica não se aplica ou ainda não existe.
- Lista de múltipla escolha e etiquetas: valores separados por "; " dentro da
  célula.
- **Proteção contra fórmulas**: célula de texto que começa com `=`, `+`, `-`,
  `@`, tabulação ou retorno de carro recebe um apóstrofo no início.
- Limite: até **10.000 linhas**, com download imediato. Acima disso, a
  exportação é recusada com o pedido de restringir o filtro. (Referência: a
  operação EARJ teve ~7.200 tickets em 13 meses, spec 13 §1.) A geração em
  segundo plano para volumes maiores fica no roadmap.
- Toda exportação fica registrada no log de atividade da conta: quem, quando,
  filtros e número de linhas.

---

## 9. Permissões

| Ator | Painel e tabela de quebra | Página inicial | Exportação |
|---|---|---|---|
| admin | todos os grupos | sim | todos os tickets |
| agente (completo ou de apoio) | só os grupos em que tem leitura ou escrita (spec 06 §3); "todos" = todos os seus | sim; números pessoais e satisfação da conta (§7.2) | só tickets que pode ver |
| solicitante | não | não | não |
| identidade de integração (spec 12 §5) | não (não entra na interface) | não | não; no MVP, integrações leem tickets pela API (spec 10) e calculam o que precisarem |

Não existe permissão nem escopo específico de relatórios no MVP: quem vê o
ticket vê os números que dependem dele.

---

## 10. Roadmap (fora do MVP) e comportamento esperado

| Item | Comportamento esperado |
|---|---|
| **Relatórios personalizados** | Construtor com dimensões (grupo, responsável, prioridade, tipo, canal, organização, etiqueta, campo personalizado de lista) × métricas desta spec, com filtros e período. Relatórios salvos, compartilháveis por papel. Usa **as mesmas definições** desta spec; nenhuma métrica nova entra sem uma definição escrita aqui. Respeita sempre as permissões de quem vê. |
| **API de métricas** | Os mesmos números do painel e da tabela de quebra, com os mesmos filtros, pela API (spec 10), com o recorte de grupos do dono do token. |
| **Indicadores por agente para o admin** | No MVP cada agente vê só os próprios números (§7.2). Depois: o admin vê os de todos; ranking entre agentes só se o admin ligar explicitamente. Sempre com n ao lado, para não premiar quem atende poucos tickets fáceis. Mesma atribuição da §6.8. |
| **Relatórios agendados** | Envio periódico (diário, semanal, mensal) do resumo do painel e/ou do CSV para agentes e admins da conta, nunca para endereços externos. As permissões do destinatário são verificadas **no momento do envio**. O e-mail é marcado como gerado automaticamente (spec 02 §6). |
| **Exportação em segundo plano** | Acima de 10.000 linhas: geração assíncrona, notificação no sistema com link válido por 24 h que só funciona para quem pediu, até 200.000 linhas. |
| **Mais métricas de tempo** | Tempo de espera do cliente (cada resposta pública do solicitante até a próxima resposta de agente); tempo até a primeira atribuição; tempo em cada estado (inclusive em espera e tempo em encaminhamento). Mesmas regras de §4 e §6.8. |
| **Comparação com período anterior** | Variação percentual em relação ao período imediatamente anterior, de mesmo tamanho. |
| **Série histórica de backlog** | Backlog no fim de cada dia, por estado e grupo, reconstruído pelos eventos. |
| **Quebra por escolha múltipla** | Uma linha por valor, com aviso de que a soma das linhas passa do total. |
| **Outros formatos e BI** | Exportação em planilha nativa; exportação de conversas completas (com permissão específica); acesso de leitura para ferramentas externas de BI, sempre aplicando as definições desta spec. |

---

## 11. Abordagens comparadas

### 11.1 Por projeto (segundo a documentação pública)

| Projeto | Abordagem | Prós | Contras |
|---|---|---|---|
| Zammad | Tela de relatórios com filtros e perfis por condição; depende de um motor de busca externo. Os tempos de 1ª resposta e solução são definidos no SLA, com calendário e pausa em pendente. Exporta planilha limitada a alguns milhares de linhas. | Tempos com calendário por SLA; perfis restringem o que cada papel vê. | Séries do gráfico sem definição publicada; o relatório depende de componente extra; o limite de exportação corta resultados grandes. |
| Chatwoot | Relatórios de conversas, por agente, equipe, caixa e etiqueta. **Médias** sobre conversas criadas no período. 1ª resposta a partir da abertura ou da passagem do bot para um humano. Reabrir alonga a resolução. Opção de recalcular em horário comercial. Pesquisa de satisfação ao resolver. | Definições publicadas; exclui o bot da 1ª resposta; satisfação simples. | Média sensível a extremos; atribuir pelo dia da criação faz números de períodos passados mudarem; sem métrica de reabertura. |
| FreeScout | Núcleo sem relatórios; módulo pago traz produtividade, 1ª resposta (da criação até a resposta de um agente, excluindo spam e automações) e satisfação a cada resposta. Usa **mediana**. | Exclusões explícitas; mediana robusta. | Nada no núcleo; resolução e horário comercial sem definição publicada. |
| osTicket | Painel por período, departamento, tópico ou agente: abertos, atribuídos, vencidos, fechados (estado atual), **reabertos como contagem de eventos**, tempo de serviço só sem reabertura, tempo médio de resposta em todas as trocas. CSV do painel e das listas. | Reabertura contada como evento; CSV direto; quebra por tópico. | "Fechados" diminui quando reabre; agrupa pelo departamento **atual**, o que reescreve o passado; só médias. |
| Znuny | Estatísticas configuráveis (matriz, lista, estáticas), com variante em horário de trabalho para cada tempo; painel de criados × fechados por dia; exportação em vários formatos. | Muito flexível; horário útil por métrica; quebra por qualquer atributo. | Configuração complexa; o usuário precisa conhecer o modelo para obter um número confiável. |
| UVdesk | Lista de atividade por agente e lista de avaliações de clientes; sem métricas de tempo documentadas. | Simples. | Não atende tempos nem SLA. |
| Frappe Helpdesk | Página inicial do agente com médias de 1ª resposta e resolução, comparação entre períodos e avaliações de 1 a 5 estrelas; relatórios avançados num produto de BI à parte. | Comparação com período anterior; visão pessoal do agente. | Fórmulas (início, fim, média ou mediana) não documentadas. |

### 11.2 Escolhas do PantherDesk

| Tema | Abordagens observadas | Escolha e motivo |
|---|---|---|
| Fonte dos números | índice de busca externo / consultas ao banco / módulos | eventos de auditoria no próprio banco: recomputável e sem componente extra |
| 1ª resposta: o que conta | resposta externa / 1ª mensagem humana / resposta de agente excluindo automações | só resposta **pública de agente humano** na conversa principal; exclui nota, sistema, automação, integração e conversa paralela (soma das exclusões mais rígidas observadas) |
| Ticket aberto pelo agente | não documentado | o modo de criação (spec 01 §4.6) decide: registrar pedido → aplica; contato proativo → não se aplica |
| Resolução e reabertura | reabrir alonga (1) / só sem reabertura (1) | as duas: 1ª resolução (estável, no painel) e resolução final (móvel, na exportação) |
| Reabertura | contagem de eventos (1) / ausente (vários) | eventos **e** taxa por ticket |
| Período de um tempo | dia da criação (1) / não documentado | dia do evento final: números passados não oscilam por respostas atrasadas |
| Agrupamento | grupo atual (1) | grupo no momento do evento; campos de classificação pelo valor atual |
| Agregação | média (maioria) / mediana (1) | mediana principal, média e n ao lado |
| Horário comercial | calendário por SLA / chave no relatório / variante por métrica | as duas variantes sempre, com o calendário da spec 05 |
| Exportação | planilha com limite baixo / CSV / vários formatos | CSV UTF-8 de metadados, imediato até 10.000 linhas |
| Satisfação | ao resolver (1) / a cada resposta (1) / ausente | MVP: uma por resolução (spec 13 Δ15), % sobre avaliações respondidas, com taxa de resposta ao lado |
| Visão do agente | página inicial pessoal (1) / relatório por agente (vários) | página inicial com os próprios números; comparação entre agentes no roadmap |

---

## 12. Casos de teste (critérios de aceite)

Atores: `ag1` e `ag2` (grupo N1, escrita), `ag3` (grupo Financeiro, escrita),
`apoio1` (agente de apoio: leitura em N1), `admin`, solicitantes `ana` e `bia`
(org. Acme), `cris` (sem org.).

Configuração comum (salvo indicação):
- Fuso da conta: America/Sao_Paulo (UTC−03:00, sem horário de verão). Todos os
  horários abaixo são locais. Idioma da conta: português.
- Calendários e políticas da **configuração de referência da spec 05 §9.1**.
  Tickets do N1 usam P0 (ou P2, quando o solicitante é da Acme); as duas usam
  o calendário **C1 "Comercial SP"**: segunda a sexta, 09:00–12:00 e
  13:00–18:00 (480 min úteis por dia); feriados 2026-11-02 (segunda) e
  2026-11-20 (sexta). Tickets do Financeiro usam P1, com o calendário **C2
  "24x7 UTC"**: tempo útil = tempo corrido.
- Conforme D35, o calendário de referência dos testes é o **C1**. Caso que
  use outro calendário o diz na própria linha (C2 em RM-61; "sempre aberto"
  em RM-43). Um encaminhamento com retorno não troca a política (spec 05
  SL-72): o ticket de RM-32 continua em P0/C1 no Financeiro.
- Datas de referência: 2026-10-30 é sexta; 2026-10-31, sábado; 2026-11-03,
  terça; 2026-11-04, quarta; 2026-11-06, sexta; 2026-11-08, domingo.
- "Corrido" e "útil" estão em minutos.

### 12.1 Primeira resposta
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-01 | ana abre ticket por e-mail em 11-03 10:00 | ag1 envia resposta pública às 10:45 | 1ª resposta: corrido 45, útil 45; entra no dia 11-03 |
| RM-02 | ticket de ana criado em 11-03 10:00; auto-resposta de criação gravada às 10:00 | ag1 escreve nota interna às 10:05; ana responde às 10:20; ag1 responde em público às 11:30 | 1ª resposta: corrido 90, útil 90 (auto-resposta e nota ignoradas) |
| RM-03 | ticket criado em 11-03 17:30 | ag1 responde em público em 11-04 09:30 | corrido 960, útil 60 (30 min na terça + 30 min na quarta); entra no dia **11-04** |
| RM-04 | ticket criado na sexta 10-30 17:00 | ag1 responde na terça 11-03 10:00 (segunda 11-02 é feriado) | corrido 5340 (89 h), útil 120 |
| RM-05 | ticket criado no sábado 10-31 14:00 | ag2 responde às 15:00 do mesmo sábado | corrido 60, útil **0** |
| RM-06 | ticket criado na quarta 11-04 07:00 | ag1 responde às 09:15 | corrido 135, útil 15 |
| RM-07 | ticket de ana criado em 11-03 10:00 | a identidade de integração "bot-faq" envia mensagem pública às 10:10; ag2 responde em público às 10:40 | 1ª resposta = 40 (corrido e útil); o indicador "sem primeira resposta" continua ligado entre 10:10 e 10:40 |
| RM-08 | — | ag1 cria ticket para ana em 11-03 10:00 no modo **contato proativo**; ana responde às 11:00; ag1 responde às 11:20 | 1ª resposta **não se aplica**; o ticket fica fora da mediana e do n; conta 1 em criados de 11-03 |
| RM-09 | — | ag1 encaminha em 11-03 10:00 um e-mail recebido de cris (spec 02 §5); ag2 responde em público às 10:25 | solicitante cris; 1ª resposta = 25 |
| RM-10 | ticket criado em 11-03 10:00 | um gatilho envia mensagem pública às 10:01; ag1 aplica uma macro com resposta pública às 10:50 | 1ª resposta = 50 (gatilho ignorado; macro aplicada pelo agente conta) |
| RM-11 | ticket criado em 11-03 10:00 | ag1 resolve às 10:30 sem nenhuma resposta pública | 1ª resposta vazia (fora da mediana); 1ª resolução = 30 |
| RM-12 | 4 tickets no período com 1ª resposta de 10, 20, 40 e 100 min | abrir o painel | mediana 30, média 42,5, n = 4 |
| RM-13 | RM-12 + um 5º ticket com 500 min | abrir o painel | mediana 40, média 134,0, n = 5 |
| RM-14 | ticket de cris criado em 11-03 10:00; conta no padrão (D02) | ag1 responde ao e-mail de notificação às 10:20; responde em público pela interface às 10:50 | a resposta das 10:20 é nota interna e não conta; 1ª resposta = 50 |
| RM-15 | igual a RM-14, mas a conta mudou o padrão para "pública" | idem | a resposta das 10:20 é pública; 1ª resposta = 20 |
| RM-16 | — | bia escreve no widget de chat em 11-03 10:00; ag1 responde às 10:05; bia só lê às 10:30 | canal chat; 1ª resposta = 5 (vale a gravação, não a leitura) |
| RM-17 | ticket de cris criado em 11-03 10:00 | ag1 abre conversa paralela com um fornecedor às 10:10; o fornecedor responde às 10:30; ag1 responde em público a cris às 10:40 | 1ª resposta = 40; a mensagem das 10:10 não conta como resposta e a das 10:30 não conta como atividade do solicitante |
| RM-93 | — | ag1 registra pedido de cris recebido por telefone, na sexta 10-30 17:40 (modo registrar pedido, meio declarado "telefone"); ag1 responde em público na terça 11-03 09:10 | canal `agente`, meio "telefone"; a métrica se aplica; 1ª resposta: corrido 5250, útil 30 (20 na sexta + 10 na terça; segunda 11-02 é feriado em C1) (D34, D35) |

### 12.2 Resolução e reabertura
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-20 | ticket criado em 11-03 10:00 | ag1 resolve às 14:00 | 1ª resolução e resolução final: corrido 240, útil 180 (10–12 e 13–14); resolvidos de 11-03 = 1 |
| RM-21 | ticket criado em 11-03 10:00, resolvido às 16:00 | ana responde em 11-04 09:00 (volta a aberto); ag1 resolve em 11-04 11:00 | 1ª resolução: corrido 360, útil 300, no dia 11-03; resolução final: corrido 1500, útil 540 (420 na terça + 120 na quarta), no dia 11-04; reaberturas do ticket = 1; resolvidos: 11-03 = 1 e 11-04 = 1 |
| RM-22 | mesmo ticket de RM-21 | calcular em 11-04 10:00 (antes da segunda resolução) | 1ª resolução = corrido 360, útil 300, em 11-03; resolução final sem valor; o ticket está no backlog como aberto |
| RM-23 | ticket criado em 11-03 10:00 | ag1 muda para pendente às 10:30 e resolve às 15:00 | 1ª resolução: corrido 300, útil 240 (pendente não é descontado; só o almoço fica fora) |
| RM-24 | ticket criado em 11-03 10:00 | ag1 muda direto para fechado às 12:00 | evento de resolução; 1ª resolução = 120 |
| RM-25 | ticket resolvido em 11-03 12:00 | o fechamento automático o leva a fechado em 11-07 12:01 | resolvidos: 11-03 = 1, 11-07 = 0; reaberturas = 0 |
| RM-26 | ticket resolvido | ag1 muda para pendente | reaberturas do ticket = 1 |
| RM-27 | ticket fechado | admin usa "reabrir ticket fechado" (spec 01 §4.2) | reaberturas = 1; evento com origem agente e ator admin |
| RM-28 | ticket fechado; política do grupo `novo` | ana responde em 11-05 10:00 | o ticket antigo continua com 0 reaberturas; o novo conta em criados de 11-05 e tem 1ª resposta própria a partir de 11-05 10:00 |
| RM-29 | período 11-02 a 11-08. 1ª resolução no período: A (0 reaberturas), B (2), C (1), D (0); E teve a 1ª resolução em 10-30 e foi reaberto em 11-04; as reaberturas de B e C também caem no período | abrir o painel | taxa de reabertura = 2 ÷ 4 = **50,0%**; reaberturas no período = **4** (B: 2, C: 1, E: 1); E não entra no denominador da taxa |
| RM-30 | ticket pendente com data de retorno | a data é atingida e o ticket volta para aberto | reaberturas = 0 |
| RM-31 | ticket de cris criado em 11-03 10:00 | ag1 muda para em espera às 10:30; o fornecedor responde na conversa paralela às 14:00 (volta a aberto); ag1 resolve às 15:00 | 1ª resolução: corrido 300, útil 240 (em espera não é descontado); reaberturas = 0; resolvidos de 11-03 = 1 |
| RM-32 | ticket de cris em N1, criado em 11-03 09:00, responsável ag1 | ag1 encaminha com retorno ao Financeiro às 10:00; ag3 usa "resolver" às 11:00 (volta aberto a N1, com ag1); ag1 resolve às 12:00 | só **1** evento de resolução (12:00, grupo N1): 1ª resolução corrido 180, útil 180 (C1, 09–12); o "resolver" de ag3 não é resolução nem reabertura; resolvidos de Financeiro = 0; entre 10:00 e 11:00 o ticket está **aberto** e conta no backlog do Financeiro (abertos), e o painel do N1 mostra 1 encaminhado aguardando devolução, fora do backlog do N1 (D23) |
| RM-33 | ticket fechado de ana | ag1 usa "criar continuação" em 11-05 10:00 | o ticket novo conta em criados de 11-05; o fechado continua com 0 reaberturas |
| RM-34 | ticket de ana criado em 11-03 10:00 | ana usa "meu problema foi resolvido" no portal às 11:00 | evento de resolução; 1ª resolução = 60; resolvidos de 11-03 = 1 |

### 12.3 Fuso, períodos e calendário
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-40 | — | ticket criado em 2026-11-03 23:30 local (2026-11-04T02:30Z) | conta em criados de **11-03** |
| RM-41 | hoje é 2026-11-08 15:00 | período "últimos 7 dias" | intervalo [11-02 00:00, 11-09 00:00); um ticket criado em 11-01 23:59:59 fica fora; um criado em 11-02 00:00:00 fica dentro |
| RM-42 | ticket criado na quinta 11-19 16:00 | ag1 resolve na segunda 11-23 10:00 (sexta 11-20 é feriado) | 1ª resolução: corrido 5400 (90 h), útil 180 |
| RM-43 | configuração própria: conta nova, em que a política padrão ainda usa o calendário "sempre aberto" (spec 05 §7.3) | ticket de cris criado em 11-03 17:30, respondido em 11-04 09:30 | útil = corrido = 960 |
| RM-44 | RM-03 já calculado (útil 60) | admin acrescenta 2026-11-04 como feriado ao C1 | recálculo: útil 30; corrido 960 |
| RM-45 | ag2 escolheu o fuso Europe/Lisbon na preferência pessoal | ticket criado em 2026-11-03T02:30Z (02:30 em Lisboa, 23:30 de 11-02 em São Paulo); ag2 abre o painel | o ticket conta em criados de **11-02**; a tela indica America/Sao_Paulo |

### 12.4 Universo: mescla e spam
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-50 | #1010 (ana) criado em 11-03 10:00 e #1011 (bia) às 10:05, ambos em N1 | ag1 responde em público em 1011 às 10:15; mescla 1011 em 1010 às 10:20; responde em público em 1010 às 10:30 | criados de 11-03 = 1 (só 1010); 1ª resposta de 1010 = 30; 1011 não aparece em nenhuma métrica; backlog = 1 |
| RM-51 | ticket de cris criado em 11-03 09:00 | ag1 marca como spam às 09:10 | não conta em criados de 11-03, nem em resolvidos, nem no backlog |
| RM-52 | após RM-51 | admin desmarca o spam em 11-04 08:00 | volta a contar em criados de **11-03**; o ticket continua **fechado** (D16) e fora do backlog; não gera resolução em 11-03 nem reabertura em 11-04; 1ª resolução sem valor |
| RM-53 | removido em v0.2 — não existe exclusão de ticket no MVP (D17) | — | — |
| RM-54 | após RM-50 | exportar CSV da lista "todos" | 1011 aparece com "mesclado em" = 1010; o painel continua sem contá-lo |
| RM-55 | ticket avaliado com nota 5 em 11-03 | ag1 marca o ticket como spam em 11-04 | a avaliação sai do % de satisfação de 11-03 (recálculo retroativo) |

### 12.5 Backlog, volume, grupo e quebras
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-60 | agora: N1 com 3 abertos, 1 pendente e 2 resolvidos; Financeiro com 1 aberto; mais 1 mesclado e 1 spam fechado | abrir o painel com "todos os grupos" | backlog = 5 (N1: 4, Financeiro: 1); abertos 4, pendentes 1; resolvidos 2; mesclado e spam fora |
| RM-61 | ticket criado em N1 em 11-03 10:00 | movido para Financeiro às 11:00; ag3 responde em público às 11:30 e resolve às 12:00 | filtro N1: criados 1, 1ª resposta sem dado, resolvidos 0. Filtro Financeiro: criados 0, 1ª resposta 90 (útil 90, calendário C2 da P1), 1ª resolução 120 (útil 120), resolvidos 1 |
| RM-62 | backlog de N1 em 11-03 00:00 = 10 | em 11-03: 5 tickets criados em N1, um deles mesclado em outro no mesmo dia; 2 eventos de resolução; 1 reabertura de ticket resolvido em 11-02 | criados 4, resolvidos 2, reabertos 1; backlog de N1 em 11-04 00:00 = 10 + 4 + 1 − 2 = **13** |
| RM-63 | agora: N1 com 2 abertos, 1 pendente e 2 em espera | abrir o painel filtrado em N1 | backlog = 5; abertos 2, pendentes 1, em espera 2 |
| RM-64 | no período, 6 tickets criados em N1: motivo hardware (3), rede/infraestrutura (2) e 1 criado por e-mail sem motivo | quebrar por motivo | linhas hardware 3, rede/infraestrutura 2, "(sem valor)" 1; total 6 (revisto em v0.3, D51) |
| RM-65 | ticket criado em N1 em 11-03 com motivo hardware | ag1 corrige o motivo para rede/infraestrutura em 11-05; abrir o período 11-02 a 11-08 em 11-06 | criados: hardware 0, rede/infraestrutura 1 (valor atual); o grupo do fato continua N1 (revisto em v0.3, D51) |
| RM-66 | 1ª respostas no período: hardware 10, 20 e 60 min; rede/infraestrutura 30 e 50 min | quebrar por motivo | hardware: mediana 20, n = 3; rede/infraestrutura: mediana 40, n = 2; total: mediana **30**, n = 5 (não é a média das medianas) (revisto em v0.3, D51) |
| RM-67 | RM-66 | exportar a tabela de quebra | uma linha por valor, mais total; mediana de hardware = 1200 s; separador ponto e vírgula |
| RM-94 | no período, 7 tickets criados em N1: 3 por e-mail, 1 pelo portal e 3 por agente (meios declarados telefone 2, presencial 1) | quebrar por canal; depois por meio declarado | canal: e-mail 3, portal 1, agente 3; total 7. Meio: telefone 2, presencial 1, "(sem valor)" 4; total 7 (D34) |

### 12.6 SLA
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-70 | no período, metas de 1ª resposta: 8 cumpridas, 2 violadas, 1 em andamento; 3 tickets de prioridade baixa no Financeiro (P1 não tem meta para baixa). Metas de resolução: 5 cumpridas, 0 violadas | abrir o painel | % de 1ª resposta = 8 ÷ 10 = **80,0%**; % de resolução = **100,0%**; os 3 tickets "sem meta" e a meta em andamento não entram |
| RM-71 | prazo da 1ª resposta em 11-05 11:00:00 | ag1 responde às 11:00:00 | cumprida |
| RM-72 | idem | ag1 responde às 11:00:01 | violada, com resultado em 11-05 11:00:00 |
| RM-73 | prazo de 1ª resposta na sexta 11-06 17:00; resposta na segunda 11-09 09:30 | painel do período 11-02 a 11-08 e do período 11-09 a 11-15 | violada conta no primeiro período; não aparece no segundo |
| RM-74 | ticket de cris em N1, prioridade normal (P0: resolução 24 h úteis = 1440 min), criado em 11-03 09:00; resolvido às 12:00 (180 consumidos, cumprida) | cris responde em 11-04 09:00 (reabre) e ninguém resolve; o prazo restante (1260 min) vence na sexta 11-06 15:00 | intervalo 11-03 a 11-03 calculado em 11-03 13:00: resolução cumprida 1. O mesmo intervalo calculado em 11-07: cumprida 0, violada 0. Intervalo 11-06 a 11-06: violada 1. Resultado final da métrica: **violada** (D10) |
| RM-75 | no período, metas de 1ª resposta: 4 cumpridas, 1 violada, 2 encerradas sem resposta | abrir o painel | % de 1ª resposta = 4 ÷ 5 = **80,0%**; as encerradas ficam fora |
| RM-76 | configuração própria: política do N1 como a P0, com aviso **absoluto de 60 min úteis** (spec 13 Δ14), calendário C1; ticket de cris normal, criado em 11-03 09:00 (resolução 1440 min úteis = 3 dias de C1: vence qui 11-05 18:00; aviso qui 11-05 17:00) | abrir o painel em 11-05 17:30; depois ag1 resolve em 11-05 17:45 e o painel é recalculado | antes: "SLA: aviso emitido" = 1; depois: 0, e a resolução conta como cumprida |

### 12.7 Painel, exportação, permissões e recálculo
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-80 | ag3 só tem acesso ao Financeiro | ag3 abre o painel | filtro de grupo lista só Financeiro; nenhum número inclui N1 |
| RM-81 | — | ana tenta abrir o painel e a página inicial do agente | recusado nos dois casos |
| RM-82 | período sem nenhum ticket respondido | abrir o painel | mediana de 1ª resposta exibida como "—" e n = 0 |
| RM-83 | ticket X com assunto "=SOMA(A1:A9)", criado e respondido como em RM-01 (10:00 e 10:45); ticket Y com assunto "Configuração do acesso à VPN" | ag1 exporta CSV com X e Y | assunto de X na célula como `'=SOMA(A1:A9)`; assunto de Y com acentos corretos ao abrir numa planilha; "criado em" de X = `2026-11-03T10:00:00-03:00`; 1ª resposta corrida de X = 2700 |
| RM-84 | tickets com notas internas, anexos e comentários de avaliação | exportar CSV | nenhum corpo, nota, anexo ou comentário no arquivo |
| RM-85 | ag1 (só N1) | exporta a lista "todos os tickets" | só tickets de N1 no arquivo; a exportação fica no log de atividade da conta |
| RM-86 | filtro com 10.001 tickets | exportar | recusado com pedido de restringir o filtro |
| RM-87 | removido em v0.2 — a exportação em segundo plano passou para o roadmap; o limite único é o de RM-86 | — | — |
| RM-88 | conta com 1.000 tickets e valores derivados guardados | apagar todos os valores derivados e recalcular a partir dos eventos | todos os números do painel e todas as colunas do CSV são idênticos aos anteriores |
| RM-89 | valor de 1ª resposta guardado no ticket diverge dos eventos | rodar o recálculo | o valor é refeito a partir dos eventos |
| RM-90 | conta em português | ag1 exporta sem escolher separador | separador ponto e vírgula; numa conta em inglês, vírgula |
| RM-91 | ticket em espera, tipo incidente, criado pelo chat e avaliado duas vezes (notas 3 e 5) | exportar CSV | estado "em espera"; tipo "incidente"; canal "chat"; avaliações 2; última nota 5 |
| RM-92 | `apoio1` com leitura em N1 (agente de apoio) | abre o painel e exporta a lista de N1 | permitido; mesmos números e linhas que ag1 vê em N1 |
| RM-95 | ticket de RM-93; ticket de RM-01 | exportar CSV | RM-93: canal "agente", meio declarado "telefone", 1ª resposta corrida 315000 s, útil 1800 s; RM-01: canal "e-mail", meio declarado vazio (D34) |

### 12.8 Satisfação
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-110 | 8 avaliações no período: 5, 5, 4, 4, 4, 3, 5, 1 | abrir o painel | % de satisfação = 6 ÷ 8 = **75,0%**; n = 8; distribuição: 1 → 1, 2 → 0, 3 → 1, 4 → 3, 5 → 3 |
| RM-111 | 10 convites enviados no período; 8 respondidos | abrir o painel | taxa de resposta = **80,0%**; os 2 sem resposta não entram no % de satisfação |
| RM-112 | ana dá nota 2 em 11-03 15:00 e muda para 4 em 11-04 10:00 (ticket ainda resolvido) | abrir os dias 11-03 e 11-04 | uma avaliação, nota 4, satisfeita, no dia **11-03**; nada em 11-04 |
| RM-113 | ticket resolvido em 11-03 10:00 e avaliado com 3; reaberto e resolvido de novo em 11-04 11:00 (25 h depois); avaliado com 5 | período 11-02 a 11-08 | 2 avaliações; % de satisfação = 1 ÷ 2 = **50,0%** |
| RM-114 | ticket de N1 resolvido por ag1 (responsável) em 11-03; avaliado com 5 | depois o ticket é reaberto, movido para o Financeiro e reatribuído a ag3 | a avaliação continua atribuída a N1 e a ag1 |
| RM-115 | hoje é 2027-01-01 10:00 | satisfação de 60 dias | janela [2026-11-03 00:00, 2027-01-02 00:00); avaliação de 2026-11-02 23:59:59 fica fora; de 2026-11-03 00:00:00 fica dentro |
| RM-116 | ticket encaminhado com retorno e devolvido pelo Financeiro | — | nenhum convite e nenhuma avaliação ligados à devolução |

### 12.9 Página inicial do agente
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-120 | hoje é 2026-11-08 15:00; nos últimos 7 dias: 3 resoluções com ag1 responsável; 1ª respostas escritas por ag1 de 10, 30 e 50 min; 2 avaliações atribuídas a ag1 (5 e 3) | ag1 abre a página inicial | resolvidos 3; mediana da 1ª resposta 30 (n = 3); avaliações recebidas 2; a minha satisfação de 60 dias (só essas duas no período) = **50,0%** |
| RM-121 | ag3 (só Financeiro); na conta, 20 avaliações em 60 dias, 18 satisfeitas | ag3 abre a página inicial e clica na satisfação da conta | mostra 90,0% (n = 20); o clique não lista tickets do N1 |
| RM-122 | N1 com 3 abertos, 1 pendente e 2 em espera; Financeiro com 4 abertos | ag1 (só N1) abre a página inicial | abertos nos meus grupos: aberto 3, pendente 1, em espera 2 |

### 12.10 Local (spec 13 Δ33)
Cadastro: campus Barra, prédio A, salas B204 (2º andar) e B110 (1º andar);
campus Gávea, prédio Principal, sala G-LAB (térreo).

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-130 | período 11-02 a 11-08; 8 tickets criados em N1: B204 (2), B110 (1), G-LAB (2) e 3 sem local, um deles com a etiqueta "barra" | quebrar por campus; depois por sala | campus: Barra 3, Gávea 2, "(sem local)" 3; total 8 (a etiqueta não conta como Barra). Sala: B204 2, B110 1, G-LAB 2, "(sem local)" 3 |
| RM-131 | ticket criado em N1 em 11-03 com local B204 | ag1 corrige o local para G-LAB em 11-05; abrir o período 11-02 a 11-08 em 11-06 | criados: Barra 0, Gávea 1 (local atual); o grupo do fato continua N1 |
| RM-132 | RM-130 | admin renomeia B204 para "Laboratório 204" e a desativa; quebrar por sala | a linha aparece como "Laboratório 204 (inativa)", com os mesmos 2 tickets; total 8 |
| RM-133 | RM-130 | filtrar campus Barra e quebrar por andar | linhas "A / 2º" 2 e "A / 1º" 1; total 3; os tickets sem local ficam fora do filtro |

### 12.11 Eventos prontos até a montagem (spec 13 Δ34)
Período 2026-11-09 (segunda) a 2026-11-15 (domingo). Cálculo em 2026-11-16
10:00, salvo indicação. Horários locais (America/Sao_Paulo, UTC−3).

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-140 | E1: montagem qui 11-12 14:00, "pronto" ligado ter 11-10 10:00. E2: montagem qui 11-12 14:00, ligado às 14:30. E3: montagem sex 11-13 08:00, nunca ligado. E4: montagem sáb 11-14 09:00, ligado sex 11-13 16:00. E5: montagem sáb 11-14 10:00, resolvido ter 11-10 sem "pronto" | abrir o painel | prontos no prazo 2 (E1, E4); atrasado 1 (E2); não pronto 1 (E3); E5 fora do denominador; % prontos até a montagem = 2 ÷ 4 = **50,0%** |
| RM-141 | E7: montagem qui 11-12 14:00; "pronto" ligado ter 11-10 10:00 e desligado qua 11-11 15:00 | abrir o painel; depois ligar de novo qui 11-12 15:00 e recalcular | primeiro: E7 "não pronto"; depois: "pronto atrasado"; em nenhum dos dois é "no prazo" |
| RM-142 | E1 de RM-140 | abrir o painel em qua 2026-11-11 12:00 | E1 está "em andamento" (montagem no futuro) e não entra; sem outros eventos, o % aparece como "—" |
| RM-143 | E8: montagem dom 11-15 23:30 local (2026-11-16T02:30Z), "pronto" ligado dom 11-15 20:00 | período 11-09 a 11-15 | E8 conta no dia **11-15** (fuso da conta), como pronto no prazo |
| RM-144 | 10 tickets de evento criados no período, 3 com a marca "fora do prazo" | abrir o painel | % de pedidos fora do prazo = **30,0%** |
| RM-145 | E1 de RM-140, criado pelo portal seg 11-09 10:00 em N1 (P0, C1), com resposta pública de ag1 às 10:30; resolvido sex 11-13 17:00 | abrir o painel de SLA da semana | 1ª resposta de E1 entra no % de 1ª resposta, como cumprida; E1 não entra no % de resolução ("sem meta"), nem como cumprido nem como violado (D40) |
| RM-146 | E2 de RM-140 (montagem qui 11-12 14:00, "pronto" ligado às 14:30) | ag1 tenta desligar a marca qui 11-12 15:00 | recusado (D44); E2 continua "pronto atrasado" |

### 12.12 Incidentes e filhos (spec 13 Δ35)
Tickets em N1, política P0, calendário C1.

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RM-150 | #P (ana) criado em 11-03 10:00; #F1 (bia) às 10:05; #F2 (cris) às 10:10 | ag1 marca #P como pai e vincula #F1 e #F2 às 10:30; responde em público no pai às 10:40 | 1ª resposta: #P 40, #F1 35, #F2 30 (corrido e útil); incidentes de 11-03 = 1; filhos = 2; mediana de filhos por incidente 2 (n = 1) |
| RM-151 | RM-150; no dia 11-03, antes, 4 convites e 3 avaliações de outros tickets | ag1 resolve #P às 11:00 com resposta pública | 3 eventos de resolução em 11-03 (1ª resolução: #P 60, #F1 55, #F2 50); resoluções por incidente = 2; nenhum convite novo; taxa de resposta de 11-03 continua **75,0%** e o % de satisfação não muda |
| RM-152 | #F3 (cris) resolvido e avaliado com 5 em 10-30; reaberto em 11-03 09:30 | ag1 vincula #F3 a #P às 10:30; #P é resolvido às 11:00 | a avaliação de 10-30 continua contando em 10-30; nenhum convite para a resolução de 11-03; nenhuma avaliação de #F3 em 11-03 |
| RM-153 | RM-151 | filtro "filhos de incidente: excluir" no dia 11-03 | criados 1 (#P); resolvidos 1; com "só filhos": criados 2, resolvidos 2 |
| RM-154 | variante de RM-150 | ag1 desvincula #F2 às 10:50; resolve #P às 11:00; resolve #F2 às 11:30 com resposta pública | filhos = 1; resoluções por incidente = 1; resolvidos de 11-03 = 3; #F2 recebe convite pela resolução das 11:30 |
| RM-155 | RM-151, #P com local B204 e #F1 com local B110 | exportar CSV de #P e #F1 | #P: "é incidente pai" = sim, filhos = 2, incidente pai vazio; #F1: incidente pai = número de #P, "é incidente pai" = não; colunas de campus, prédio, andar e sala preenchidas pelo cadastro |
| RM-156 | RM-150, #P com responsável ag1, #F1 com responsável ag2 e #F2 sem responsável; #P com local B204, #F1 com B110 e #F2 com B204 | ag1 resolve #P em 11-03 11:00; em 11-04, abrir a página inicial de ag1 e de ag2 e ver os locais afetados de #P | #F2 resolvido com responsável ag1 (D47); "meus números dos últimos 7 dias": ag1 com 2 resoluções (#P e #F2), ag2 com 1 (#F1); locais afetados de #P = 2 (B204 e B110, sem repetir B204; D48) |

---

## 13. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Definição de 1ª resposta (nota interna, auto-resposta, bot) | documentação de 3 projetos | M-01 em todos; AU-10 (auto-resposta conta?) |
| Ticket aberto pelo agente / encaminhado | não documentado | T-01, E-16 cruzados com M-01 |
| Resolução e reabertura | documentação de 2 projetos (modelos opostos) | T-03 + M-01 (reabrir alonga, zera ou exclui?) |
| Horário comercial nas métricas | documentado em 2, cálculo não | AU-05, AU-06 cruzados com M-01 |
| Pausa em pendente | documentada só no SLA | AU-07 |
| Mescla nas métricas | não documentado | T-06 + M-01 |
| Granularidade do histórico | documentação vaga | T-08 |
| Agrupamento (grupo atual × do evento) | documentado em 1 | A-04 + M-01 |
| Exportação (formatos, limites, codificação) | parcial | M-02 em todos |
| Visibilidade de relatórios por papel | documentada em 1 | P-01, P-04 |
| Satisfação (quando envia, escala, cálculo) | documentação de 3 projetos; requisitos da spec 13 | M-01 nos que têm pesquisa |
| Local, eventos prontos até a montagem, incidentes e filhos | requisitos de cliente (spec 13 Δ33–Δ35) e números de uso da operação | nenhuma (comportamento definido por nós) |

---

## 14. Questões abertas para o implementador

1. **Versões de calendário**: o cálculo usa o calendário atual (RM-44). Se o
   negócio exigir que números fechados de meses anteriores não mudem, os
   calendários precisam de versões com data de vigência.
2. **Mudança de fuso da conta** reescreve os dias passados (§4.2). Avaliar se
   basta o aviso ou se a mudança deve ser bloqueada depois de um volume mínimo
   de tickets.
