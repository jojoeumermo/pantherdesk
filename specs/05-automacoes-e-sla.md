# Spec 05 — Automações, macros, tarefas agendadas e SLA

Status: **rascunho v0.3 (2026-10-29)**. Baseado na documentação pública dos 7
projetos analisados. As evidências de runtime ainda estão pendentes; cada ponto
que depende delas está marcado como **[evidência pendente: cenário]**.
Vocabulário: spec 01. E-mail e anti-laço: spec 02. Permissões: spec 06.
Decisões transversais: spec 00 (D01–D53). Requisitos da operação EARJ: spec 13,
que prevalece sobre esta.

**Mudanças na v0.3**
- **Macro por intenção** com **variantes PT/EN**: entra a variante do idioma
  do solicitante, trocável na prévia; sem a variante, a do idioma da conta com
  aviso; busca pelo nome da intenção em qualquer idioma. Substitui o filtro
  por idioma da v0.2 (spec 13 Δ36; §4, §4.3). AU-164 removido.
- **Ticket pai**: resposta pública e resolução em **cascata** para os filhos,
  com a variante de cada solicitante; sem pesquisa de satisfação no pai nem
  nos filhos (Δ35; §4.5, §6.2, §7.6).
- **Prazo do evento**: o compromisso do ticket de evento é o início da
  montagem, com avisos **2 dias úteis antes** e **no dia** (Δ34; §7.14, §5).
  Revisto pela D40: a 1ª resposta comum continua valendo (ver "Ajustes
  D40–D53").
- **Selo de prazo** de cada ticket e fila padrão **"Quase escalando"** (prazo
  em até 1 hora útil ou vencido) (Δ37; §7.15).
- Novos casos AU-177 a AU-187 e SL-77 a SL-87.
- **Ajustes D40–D53**: o ticket de evento **mantém a 1ª resposta** da política
  comum e só perde a resolução; o prazo da montagem é cumprido pela marca
  **"pronto para o evento"** (D40, D44; §7.14). Selo do evento: "faltam N
  dias" ou "faltam N h", "pronto", "montagem sem pronto" (vermelho) e "evento
  encerrado"; a fila "Quase escalando" inclui o evento sem "pronto" com
  montagem em até 1 hora útil ou já iniciada (D40; §7.15). Aviso de montagem
  cuja janela já abriu sai **imediatamente, uma vez**; esta spec é a fonte da
  regra, e a spec 09 aponta para ela (D41; §7.14). Resposta do pai entra em
  filho resolvido sem mudar o estado (D46); filho sem responsável recebe quem
  resolveu o pai (D47; §4.5); a variante no idioma da conta é obrigatória
  também pela API (D49; §4.3). AU-125 refeito sem os campos "unidade" e
  "setor" (D51). SL-77, SL-81, SL-84 e SL-85 revistos; novos AU-188, AU-189 e
  SL-88 a SL-92. Questões abertas sobre cascata, aviso "no dia" e evento sem
  "pronto" retiradas (D41, D44, D47).

**Mudanças na v0.2**
- Estado **em espera** (spec 13 Δ3, D18): categoria de SLA **pausado**, com o
  mesmo efeito de pendente nas métricas e nas tarefas de retorno (§5, §7.4).
- Falha de gatilho atômica e atribuição inválida como falha (D11, §3.6);
  **chamar webhook** é ação de gatilho do MVP, com o envelope padrão (D13, §3.3).
- Gatilhos: condição dentro/fora do horário com o calendário da conta ou do
  grupo (Δ11), tipo do ticket (Δ8), campos condicionais (Δ2), novos eventos
  "resposta em conversa paralela" e "avaliação recebida"; o autor da ação nunca
  é notificado (D12).
- Confirmação de recebimento: um único mecanismo, por gatilho, para todos os
  canais de entrada do solicitante, com par dentro/fora do horário (§6.1).
- **Pesquisa de satisfação** no MVP (Δ15, D19), enviada no mesmo e-mail da
  resposta que resolve (Δ12) (§6.2).
- Macros: compartilhadas e **pessoais**, variáveis com lista fechada e recusa
  de variável desconhecida, idioma, estatística de uso, novas ações (tipo,
  assunto, seguidor, encaminhar com retorno, devolver) e aplicação em massa
  (Δ9, Δ10, §4).
- Responsável obrigatório para resolver (Δ4) em gatilhos e macros.
- SLA: aviso por **tempo útil absoluto** além do percentual, regra de
  arredondamento explícita, **escalonamento N horas úteis depois da violação**
  (Δ14, §7.10, §7.11); política mantida no encaminhamento com retorno (Δ5,
  §7.1).
- Resultado único e permanente por métrica após reabertura (D10, §7.8);
  "todo ticket tem política" (§7.1).
- Resposta a e-mail de notificação é nota interna por padrão e só conta como
  primeira resposta com a conta em "pública" (D02, §7.6, SL-55, SL-58).
- Casos SL-20 e SL-22 a SL-26 corrigidos (a solicitante é `cris`); AU-116
  corrigido; novos casos SL-27, SL-49, SL-58, SL-60 a SL-76, AU-121 a AU-129,
  AU-139, AU-143 a AU-144, AU-150 a AU-159, AU-160 a AU-169.
- Ajustes D23–D37: a confirmação de abertura é um gatilho de criação que
  cobre e-mail, portal, formulário de visitante e **chat**; para endereço não
  verificado, sem repetir o texto digitado e no máximo 3 por endereço a cada
  24 h (D25, §6.1); "notificar agentes do grupo" inclui os ausentes e cai nos
  admins quando o conjunto fica vazio (D27, §3.3); macro aplicada pela API
  (D29, §4.1); C1 como calendário de referência dos testes (D35, §9.1).
  AU-111 e AU-121 ajustados; novos AU-170 a AU-176.

---

## 1. Problema

O helpdesk precisa reagir a acontecimentos sem intervenção humana (rotear,
etiquetar, avisar, responder ao cliente), oferecer atalhos ao agente e medir
compromissos de tempo. Tudo isso tem de ser **determinístico e auditável**:

1. em que **ordem** as regras rodam e o que acontece quando duas regras se
   contradizem;
2. como impedir que a alteração feita por uma regra dispare outra regra, ou a
   ela mesma, em **laço**;
3. o que acontece quando uma regra **falha** no meio;
4. como aplicar um pacote de ações do agente (macro) **de uma vez só**, ou não
   aplicar nada;
5. como rodar tarefas periódicas sem **duplicar** efeitos (e-mail repetido,
   evento repetido);
6. como responder automaticamente ao cliente **sem conversar com robôs**;
7. como calcular prazos de SLA com horário comercial, fuso, feriados, pausa,
   mudança de prioridade, reabertura e mescla, e registrar o **aviso**, a
   **violação** e o **escalonamento** uma única vez;
8. como pedir a avaliação do cliente sem mandar e-mails demais.

Os projetos analisados documentam pouco sobre ordem, reentrada e aritmética de
prazo. Onde a documentação se cala, esta spec decide.

---

## 2. Conceitos

| Termo | Definição |
|---|---|
| **Operação** | Uma ação de origem única sobre um ticket: um envio do agente (resposta + mudança de estado no mesmo envio), uma mensagem recebida, uma chamada de API, a aplicação de uma macro, uma transição feita por tarefa agendada, um aviso ou violação de SLA, uma avaliação do solicitante. Toda operação tem uma **origem** (spec 01 §7). |
| **Evento** | O que a operação produziu, classificado em tipos (§3.1). Uma operação gera um único evento, que pode ter mais de um tipo (ex.: "resposta de agente" + "campos alterados"). |
| **Gatilho** | Regra do admin: tipos de evento que escuta + condições + ações, com **posição** numérica. |
| **Passada** | A avaliação de todos os gatilhos ativos, em ordem, para um evento. |
| **Macro** | Pacote de ações aplicado manualmente por um agente a um ticket, com pré-visualização. **Compartilhada** (do admin) ou **pessoal** (do agente). Cada macro representa **uma intenção** (ex.: "atendimento no local") e tem **variantes por idioma** para o texto (§4.3). |
| **Variante** | Versão de uma macro num idioma (PT ou EN): nome da intenção, texto e, se a macro muda o assunto, o assunto naquele idioma. As ações de campo são da intenção, iguais em todas as variantes. |
| **Prazo do evento** | Compromisso de um ticket do tipo evento: estar **pronto** (marca "pronto para o evento" ligada) até o **início da montagem** (§7.14; spec 01 §5.2; D40, D44). Não é métrica de SLA. |
| **Selo de prazo** | Resumo do próximo prazo de um ticket, mostrado em cada linha das filas: "vence em …", "vencido há …", "pausado" ou, para eventos, "faltam N dias", "faltam N h", "pronto", "montagem sem pronto" ou "evento encerrado" (§7.15). |
| **Tarefa agendada** | Processo do sistema que roda periodicamente (retorno de pendente e de em espera, fechamento automático, verificação de SLA). |
| **Política de SLA** | Conjunto de metas por prioridade, um calendário, condições de seleção, a regra de aviso e, opcionalmente, o escalonamento depois da violação. |
| **Calendário** | Fuso horário (nome IANA) + intervalos semanais de atendimento + feriados. |
| **Calendário da conta** / **do grupo** | O calendário que a conta indica como seu horário comercial (padrão: "sempre aberto") e, opcionalmente, um calendário próprio de um grupo. Sem calendário próprio, o grupo usa o da conta. |
| **Métrica** | Cada meta acompanhada no ticket: **primeira resposta** e **resolução**. |
| **Tempo útil consumido** | Minutos reais que caíram dentro dos intervalos do calendário enquanto o relógio daquela métrica corria. |
| **Prazo** | Instante absoluto (UTC) em que o tempo útil consumido atinge a meta. |
| **Convite de avaliação** | Pedido de avaliação enviado ao solicitante quando o ticket é resolvido com resposta pública (§6.2). |

---

## 3. Gatilhos

### 3.1 Eventos (tipos)

| Tipo | Quando ocorre |
|---|---|
| **criado** | Ticket criado, por qualquer canal ou pela API. |
| **mensagem do cliente** | Mensagem pública do solicitante ou de um participante na conversa principal. |
| **resposta de agente** | Mensagem pública de um agente. |
| **nota interna** | Nota interna de um agente. |
| **campos alterados** | Mudou estado, prioridade, tipo, grupo, responsável, etiquetas, participantes, seguidores ou campo personalizado. |
| **resposta em conversa paralela** | Chegou uma mensagem de um destinatário numa conversa paralela do ticket (spec 13 Δ17). |
| **avaliação recebida** | O solicitante deu ou alterou a avaliação de satisfação (§6.2). |
| **SLA: aviso** | Uma métrica atingiu o limiar de aviso (§7.10). |
| **SLA: violação** | Uma métrica passou do prazo (§7.11). |

- **Mensagem de sistema não gera evento de gatilho.** Respostas automáticas
  recebidas, bounces e avisos de entrega não disparam "mensagem do cliente"
  (spec 02 §6 e §7).
- A mensagem que abre o ticket faz parte do evento **criado**; não gera também
  "mensagem do cliente".
- A resposta numa conversa paralela **nunca** é "mensagem do cliente": ela não
  vem do solicitante nem de um participante da conversa principal.
- Um gatilho escuta um ou mais tipos. Na passada, ele é avaliado se o evento
  tiver pelo menos um dos tipos que ele escuta.
- Nas notificações (spec 09), "SLA: aviso" e "SLA: violação" aparecem como
  "SLA prestes a vencer" e "SLA vencido". São os mesmos eventos.

### 3.2 Condições

- Lista de condições combinadas com **E**. Cada condição aceita um conjunto de
  valores ("está em"), o que cobre o caso comum de "OU" dentro de um mesmo
  atributo. Combinações livres de E/OU ficam para o roadmap.
- Atributos disponíveis: canal; assunto; corpo da mensagem do evento;
  endereço e domínio do remetente; organização do solicitante; campos
  personalizados da pessoa e da organização do solicitante (spec 13 Δ22);
  grupo; responsável (inclusive "vazio"); prioridade; **tipo** (inclusive
  "vazio"); estado; etiquetas; campos personalizados do ticket; **origem** da
  operação (agente, solicitante, sistema, automação, API); **dentro / fora do
  horário comercial** (§3.2.1); para eventos de SLA, a métrica (primeira
  resposta ou resolução); para "avaliação recebida", a nota (1 a 5) e o motivo.
- Operadores: é, não é, está em, não está em, contém, não contém, está vazio,
  não está vazio; para números (nota), menor ou igual e maior ou igual. Para o
  tipo **campos alterados**: mudou, mudou para, mudou de.
- Comparações de texto ignoram maiúsculas/minúsculas e acentos.
- **"mudou", "mudou para" e "mudou de" olham só para as mudanças da operação
  de origem.** Mudanças feitas por gatilhos anteriores na mesma passada não
  contam como "mudou".
- As demais condições olham para o **estado atual** do ticket, já com as
  alterações dos gatilhos anteriores da mesma passada (§3.4).

#### 3.2.1 Dentro / fora do horário comercial

- A condição indica o calendário: um calendário escolhido, o **calendário da
  conta** ou o **calendário do grupo do ticket** (que cai no da conta quando o
  grupo não tem um próprio).
- É avaliada no **instante da operação de origem** (para e-mail, o da
  gravação, como no SLA, §7.5), no fuso do calendário. "Dentro" = o instante
  cai num intervalo do calendário e não num feriado; "fora" = o contrário.
- Um instante exatamente no início de um intervalo está dentro; exatamente no
  fim está fora (intervalos fechados no início e abertos no fim).
- Dois gatilhos com a mesma condição, um com "dentro" e outro com "fora" do
  mesmo calendário, **se excluem**: para qualquer evento, casa no máximo um.

### 3.3 Ações

| Ação | Regras |
|---|---|
| Definir estado | Respeita a matriz da spec 01 §4.2 (inclui **em espera**). Não mescla, não reabre ticket fechado e exige os campos obrigatórios para resolver. Com a regra "responsável obrigatório para resolver" ligada (spec 13 Δ4), resolver sem responsável é falha. |
| Definir prioridade | — |
| Definir tipo | Pergunta, incidente, problema, tarefa, evento ou vazio (spec 13 Δ8, Δ34). Mudar para evento sem os campos obrigatórios do evento, ou mudar o tipo de um ticket pai, é falha (spec 01 §4.8, §5.2). |
| Definir grupo | O grupo precisa estar ativo. Se o responsável atual não tiver escrita no novo grupo, ele é removido (spec 06). É uma transferência normal: se o ticket tinha um encaminhamento com retorno registrado, o retorno é **cancelado** e quem encaminhou é avisado (spec 13 Δ5, spec 04). |
| Definir responsável | O agente precisa estar ativo, ter **escrita** no grupo do ticket (spec 06) e cumprir as regras de atribuição automática da spec 04 (ex.: disponibilidade). Atribuição inválida é **falha** do gatilho (D11). |
| Adicionar / remover etiqueta | — |
| Definir campo personalizado | Validação da spec 01 §5, inclusive as condições de exibição (spec 13 Δ2): definir valor num campo que, com os valores finais do ticket, ficaria oculto é falha. Mudar um campo do qual outros dependem **limpa** os dependentes que ficarem ocultos, com evento de auditoria da limpeza. |
| Adicionar nota interna | Texto do admin, com as variáveis do §4.2. Menções (`@`) em nota de gatilho não são convertidas e não notificam ninguém. |
| Enviar e-mail ao solicitante | Ver §6. Fica registrado no ticket como **mensagem de sistema pública**: o solicitante a vê no portal, mas ela nunca conta como resposta de agente (§7.6). |
| Notificar agentes | O responsável, os **seguidores**, os agentes ativos com **escrita** no grupo do ticket (mesmo conjunto da D09 e da D27: inclui os marcados como ausentes; se, sem o autor, o conjunto ficar vazio, recebem os admins), ou agentes nomeados. A notificação vai pela área do agente e, conforme a preferência de cada um, por e-mail; só chega a agentes que podem ler o ticket (spec 06). **Nunca** notifica o agente autor da operação de origem (D12). |
| Chamar webhook | Entrega à **assinatura de webhook existente** escolhida no gatilho, com o **envelope padrão** do evento que disparou a passada (spec 10). Não há corpo livre nem URL avulsa (D13). A assinatura precisa estar ativa quando o gatilho é salvo; se for desativada depois, a ação é ignorada com registro. |

- Variáveis de substituição em textos enviados ao cliente **nunca** trazem o
  conteúdo de notas internas nem de conversas paralelas. A variável "última
  mensagem" significa a última mensagem **pública** da conversa principal
  (spec 06).
- Ações são validadas quando o gatilho é salvo: grupo, agente, campo ou
  assinatura de webhook inexistente, inativo ou de outra conta impede o
  salvamento. Texto com variável desconhecida também (§4.2).
- Encaminhar com retorno e devolver (spec 13 Δ5) são ações de **agente**
  (interface, API, macro), não de gatilho, no MVP.

### 3.4 Ordem de execução

1. Cada gatilho tem uma **posição** inteira e única na conta. A passada avalia
   os gatilhos ativos em **ordem crescente de posição**. Não há ordem
   alfabética nem ordem de criação.
2. Para cada gatilho: avaliar as condições sobre o estado atual (§3.2); se
   casarem, aplicar **todas** as ações do gatilho, na ordem em que aparecem
   nele.
3. O gatilho seguinte enxerga as alterações do anterior. Assim, "gatilho 10
   move para Financeiro" seguido de "gatilho 20: se grupo = Financeiro, atribuir
   a ag3" funciona na mesma passada. Inverter as posições muda o resultado, e
   isso é intencional e previsível.
4. Conflito: se dois gatilhos alteram o mesmo atributo, vale o **último**
   aplicado. As duas alterações ficam na auditoria.
5. A passada usa a versão dos gatilhos vigente no início dela. Editar um
   gatilho durante a passada só vale para as passadas seguintes.
6. Um gatilho criado ou reativado só vale para eventos posteriores. Não há
   aplicação retroativa.
7. A passada roda logo depois que a operação de origem foi gravada. A operação
   de origem **nunca** é desfeita por falha de gatilho (uma mensagem recebida
   não se perde porque uma regra falhou).
8. Como a ordem muda o resultado (AU-103/AU-104), a tela de edição mostra a
   **ordem resultante** antes de o admin salvar uma mudança de posição.

### 3.5 Sem reentrada

- **Alterações feitas por gatilhos não geram novos eventos de gatilho.** Cada
  gatilho roda no máximo **uma vez por evento**. Não existe contador de
  iterações nem profundidade máxima: o laço é impossível por construção.
- A nota interna e o e-mail criados por um gatilho também não geram evento.
- Operações **posteriores** de outras origens (agente, solicitante, tarefa
  agendada, API) geram suas próprias passadas normalmente.
- **Exceção controlada: eventos de SLA.** Quando uma ação de gatilho muda a
  prioridade ou o grupo e isso produz um aviso ou uma violação de SLA, esse
  evento de SLA inicia uma passada própria. Isso é finito, porque cada aviso e
  cada violação acontecem no máximo uma vez por métrica e por ticket (§7.10,
  §7.11). Se a mudança não produz aviso nem violação, nenhuma passada nova
  começa.
- Notificações do sistema (ex.: "você foi atribuído", spec 04) e webhooks
  (spec 10) **não são gatilhos**: refletem também as alterações feitas por
  automação, mas não iniciam passadas.

### 3.6 Falhas

- **Atomicidade por gatilho** (D11): as ações de um gatilho são aplicadas
  todas juntas, ou nenhuma. Se uma ação falha (responsável inválido, transição
  inválida, campo obrigatório vazio, responsável obrigatório ausente, campo
  oculto), **nenhuma** ação daquele gatilho é aplicada, e a passada
  **continua** com o próximo gatilho.
- A falha gera um **evento de auditoria** de falha (origem automação, regra,
  motivo). Os admins recebem um alerta, no máximo um por gatilho por dia.
- Efeitos externos (e-mail, webhook) são enfileirados e só saem depois que a
  passada foi gravada. Gatilho com falha não envia nada.
- Falha de envio de e-mail segue a spec 02 §9; falha de entrega de webhook
  segue a spec 10. Nenhuma das duas desfaz alterações de campo já gravadas.
- Gatilho que falha 50 vezes seguidas é **desativado** automaticamente, com
  alerta aos admins.

### 3.7 Ticket fechado ou mesclado

- Ticket **mesclado**: nenhuma passada.
- Ticket que está **fechado** depois da operação de origem (ex.: o fechamento
  automático): a passada roda, mas ações que alteram campos ou estado são
  **ignoradas**, com registro "ignorada: ticket fechado". E-mail, notificação e
  webhook rodam normalmente.

### 3.8 Auditoria

- Toda alteração feita por gatilho gera um evento de auditoria com origem
  **automação**, a identificação do gatilho e a versão dele (spec 01 §7).
- Cada passada deixa um **registro de execução** visível para admins no
  ticket: quais gatilhos casaram, quais ações foram aplicadas, ignoradas ou
  falharam. O registro dos gatilhos que não casaram fica guardado por 30 dias.

---

## 4. Macros

- **Compartilhadas**: criadas e editadas só pelo **admin**. Cada uma fica
  disponível para todos os grupos ou só para grupos escolhidos.
- **Pessoais**: cada agente cria, edita e apaga as suas. Só o dono as vê e
  aplica. As regras de ação e de validação são as mesmas das compartilhadas.
- Ações: as de campo dos gatilhos (estado, prioridade, **tipo**, grupo,
  responsável, etiquetas, campos), **"atribuir a mim"**, **assunto**,
  adicionar e remover **seguidor**, **encaminhar com retorno** e **devolver**
  (spec 13 Δ5, spec 04) e **um** texto, que vai para a resposta pública **ou**
  para uma nota interna, escrito em cada **variante** de idioma (§4.3).
  Macros não chamam webhook, não enviam e-mail fora da resposta, não abrem
  conversa paralela, não mesclam e não vinculam tickets a um pai.
- Quem aplica: agente com **escrita** no grupo do ticket (spec 06), em ticket
  que não está fechado nem mesclado, e só macros disponíveis para o grupo (as
  pessoais, em qualquer grupo em que o dono tenha escrita).
- Mudar o assunto não muda o marcador de assunto nem os identificadores de
  e-mail do ticket (spec 02 §9).
- Uma macro **desativada** some da lista do editor, mas não é apagada e
  continua na estatística.

### 4.1 Pré-visualização e aplicação

1. O agente escolhe a macro. O sistema mostra a **pré-visualização** no editor:
   cada campo com valor atual → valor novo e o texto da resposta ou nota já com
   as variáveis substituídas, na **variante** escolhida pelo §4.3. O agente
   pode trocar a variante e editar o texto antes de enviar.
2. Nada é gravado até o agente **enviar**. Cancelar não deixa rastro.
3. No envio, as ações da macro são aplicadas sobre o ticket e **só então** o
   resultado é validado, como **uma única operação**, atomicamente: se
   qualquer validação falhar (transição inválida, campo obrigatório para
   resolver vazio, responsável obrigatório ausente, responsável sem escrita no
   grupo), **nada** é aplicado, nem a resposta é enviada, e o agente vê a lista
   dos motivos. Por isso uma macro que atribui "a mim" e resolve funciona num
   ticket sem responsável (spec 13 Δ4).
4. Se o ticket mudou entre a pré-visualização e o envio, a pré-visualização é
   refeita e o agente confirma de novo (a versão do ticket, D01).
5. Auditoria: eventos com origem **agente** (o autor é quem aplicou), agrupados
   e marcados "via macro {nome}".
6. A operação gera **um** evento e, portanto, **uma** passada de gatilhos, com
   os tipos correspondentes ("resposta de agente", "nota interna" e/ou "campos
   alterados").
7. A resposta pública de macro é uma resposta de agente: sai por e-mail (spec
   02 §9) e conta como primeira resposta (§7.6).
8. Macro com encaminhar com retorno exige que o texto seja uma **nota
   interna**, porque o encaminhamento exige nota (spec 13 Δ5). O efeito é o
   mesmo do encaminhamento manual.
9. **Pela API** (spec 10, D29): a pré-visualização é uma operação própria, que
   não grava nada, e um envio pode aplicar a macro. Valem as mesmas regras dos
   itens 1 a 8 (disponibilidade da macro para o grupo, permissões, validação
   atômica, versão do ticket conforme D01); os eventos registram a macro usada
   e a origem API, com o token.

### 4.2 Variáveis

- A lista é **fechada**: número do ticket, assunto, nome e primeiro nome do
  solicitante, nome do agente que aplica, nome do grupo, nome da conta, valor
  de qualquer campo personalizado (do ticket, da pessoa ou da organização) e
  link do ticket no portal. O editor oferece autocompletar.
- Valem no texto e no assunto, em macros e em gatilhos.
- Ao salvar, qualquer **marcador de variável desconhecido** e qualquer texto
  entre os delimitadores de variável que não corresponda a uma variável da
  lista é **erro**, com a indicação do trecho, e nada é salvo.
- Macros e gatilhos antigos que passaram a ter variável inválida (ex.: campo
  personalizado desativado) aparecem **marcados** na lista. Aplicar uma macro
  marcada mostra o problema na pré-visualização; o agente só envia depois de
  corrigir o texto.
- Variável sem valor no ticket (ex.: campo vazio) vira texto vazio, nunca o
  marcador cru.

### 4.3 Intenção, variantes de idioma e estatística de uso

Regras da spec 13 Δ36, que substituem o "idioma da macro" e o filtro por
idioma da v0.2 (Δ10).
- Cada macro é **uma intenção**, com uma **variante** por idioma (PT e EN no
  MVP). As ações de campo pertencem à intenção; cada variante tem o nome da
  intenção, o texto e, quando a macro muda o assunto, o assunto naquele
  idioma.
- Macro com texto precisa ter a variante no **idioma padrão da conta** (PT na
  EARJ); sem ela, não é salva, pela interface nem pela API (422, D49). A
  variante no outro idioma é **opcional**. Macro sem texto (só ações de campo) não tem variantes de texto, mas
  tem o nome em cada idioma da conta, se o admin quiser.
- **Escolha da variante** ao aplicar: a do **idioma do solicitante** (o da
  Pessoa; vazio, o da conta). Se a macro não tem essa variante, entra a do
  idioma da conta, e a pré-visualização mostra um aviso. O agente pode trocar
  a variante na pré-visualização; o que sai é o que foi mostrado.
- **Busca**: a lista de macros do editor é buscada pelo **nome da intenção em
  qualquer idioma** (comparação sem maiúsculas e sem acentos). Não há filtro
  por idioma.
- As variáveis (§4.2) valem em todas as variantes e são verificadas em cada
  uma ao salvar.
- **Estatística**: por macro, o número de aplicações nas últimas **24 h**,
  **7 dias** e **30 dias** e a data do último uso, somando as variantes, com a
  divisão por variante. Uma aplicação conta quando é enviada, não quando é
  pré-visualizada; uma aplicação no ticket pai conta uma vez, não uma por
  filho. A lista pode ser ordenada por "sem uso há 30 dias".
- Nos dados da EARJ, as cerca de 28 macros atuais viram cerca de 14 intenções
  com duas variantes.

### 4.4 Aplicação em massa

- A partir de uma fila (spec 08), o agente aplica uma macro a até **100**
  tickets selecionados (spec 13 Δ9).
- Cada ticket é uma **operação atômica independente**, com as mesmas
  validações do §4.1, os próprios eventos de auditoria e a própria passada de
  gatilhos. A falha de um ticket não impede os outros.
- A pré-visualização mostra as mudanças e o texto com as variáveis do primeiro
  ticket selecionado **de cada idioma** presente na seleção: cada ticket
  recebe a variante do idioma do seu solicitante (§4.3). Uma edição feita numa
  variante vale para todos os tickets daquele idioma. O texto não é editado
  por ticket; as variáveis são substituídas em cada um.
- O resultado informa quantos tickets foram alterados e quais falharam, com o
  motivo de cada um. Cada aplicação conta na estatística.

### 4.5 Ticket pai: resposta e resolução em cascata

Regras da spec 13 Δ35; vínculo e condições na spec 01 §4.8.
- **Resposta pública no pai**: é gravada no pai e, em seguida, em cada filho
  **aberto, pendente, em espera ou resolvido**, como resposta pública do mesmo
  agente, com a marca "via ticket pai #N". Filhos fechados ou mesclados não
  recebem (D46). Num filho **resolvido**, a resposta entra **sem mudar o
  estado** (spec 01 §4.3): ele continua resolvido. Cada filho é uma **operação própria**, com os seus eventos de
  auditoria (origem agente, marca "via ticket pai") e a sua passada de
  gatilhos, como na aplicação em massa (§4.4). A falha num filho não impede
  os outros nem desfaz o pai.
- **Idioma**: se a resposta vem de uma macro com variantes, cada filho recebe
  a variante do idioma do **seu** solicitante, com as variáveis do **próprio
  filho** (número, nome do solicitante). A pré-visualização no pai mostra cada
  variante que vai sair (uma por idioma presente no pai e nos filhos), e cada
  uma pode ser editada; o que sai é o que foi mostrado. Resposta sem macro
  sai com o mesmo texto para todos.
- **Entrega**: cada filho entrega a resposta pelo seu canal de resposta (spec
  03 §2.3), ao seu solicitante e aos seus participantes confirmados, com o
  marcador e os identificadores de e-mail do próprio filho (spec 02 §9). A
  mesma pessoa em dois filhos recebe um e-mail por ticket.
- A resposta propagada é resposta de agente no filho: conta como **primeira
  resposta** do filho (§7.6) e não passa pela guarda de mensagens automáticas
  (§6).
- **Notas internas** e anexos de notas do pai não vão aos filhos.
- **Resolução em cascata**: quando o pai vai para resolvido (com ou sem
  resposta pública), cada filho aberto, pendente ou em espera vai para
  resolvido, numa operação própria, junto com a resposta, quando houver. As
  **validações para resolver** (spec 01 §4.2) valem em cada filho, com uma
  regra (D47): com "responsável obrigatório" ligado, um filho **sem
  responsável** recebe como responsável **quem resolveu o pai** e então é
  resolvido, na mesma operação. Se essa pessoa não pode ser responsável no
  grupo do filho (sem escrita nele; o admin sempre pode, D06), o filho
  falha. Um filho que falha (sem responsável possível, campo obrigatório
  vazio) fica como estava; o pai é resolvido mesmo assim, e o
  agente vê a lista dos filhos que falharam e o motivo.
- Mudanças do pai para aberto, pendente ou em espera **não** vão aos filhos
  (spec 01 §4.8).
- **Pesquisa de satisfação**: nem o pai nem os filhos recebem convite (§6.2).
- **SLA** dos filhos: cada filho mantém a sua política e as suas métricas. A
  resposta propagada cumpre a primeira resposta do filho no instante da
  gravação nele, e a resolução em cascata cumpre a resolução do filho, se
  estiver no prazo. O SLA do pai é medido como o de qualquer ticket.

---

## 5. Tarefas agendadas

No MVP só existem tarefas do sistema. Agendador genérico configurado pelo admin
fica para o roadmap.

| Tarefa | Comportamento | Definida em |
|---|---|---|
| Retorno de pendente e de em espera | pendente ou em espera → aberto na data de retorno | spec 01 §4.3 (não redefinida aqui; spec 13 Δ3) |
| Fechamento automático | resolvido há N dias → fechado | spec 01 §4.3 (não redefinida aqui) |
| Verificação de SLA | registra avisos, violações e escalonamentos | §7.10–§7.12 |
| Avisos de evento | avisa 2 dias úteis antes e no dia do início da montagem | §7.14 |

Regras comuns:
- Rodam **a cada minuto**. O atraso entre o instante devido e o efeito é de no
  máximo 2 minutos em operação normal; a precisão dos avisos é de 1 minuto
  (spec 13 Δ14).
- **Idempotência por chave lógica**: cada efeito é identificado por (ticket,
  tarefa, instante lógico). O instante lógico é a data de retorno, o momento da
  resolução, o prazo da métrica, o instante do escalonamento ou, nos avisos de
  evento, o tipo do aviso e o início da montagem. Rodar duas
  vezes, em paralelo ou depois de uma falha, produz um único efeito, um único
  evento de auditoria e uma única notificação.
- Transições feitas por tarefa têm origem **sistema** e geram uma passada de
  gatilhos (tipo "campos alterados").
- **Lotes**: cada execução processa no máximo 500 tickets por tarefa; o resto
  fica para as execuções seguintes, na ordem do instante devido. Nada se perde
  e nada se processa duas vezes.
- **Recuperação**: se as tarefas ficaram paradas (ex.: 3 h fora do ar), na
  volta tudo o que venceu é processado. Violações de SLA são registradas com o
  **instante do prazo**, não com o da detecção (§7.12). Notificações atrasadas
  saem uma vez, marcadas como atrasadas.

---

## 6. Respostas automáticas

Não há um mecanismo separado: uma resposta automática é um **gatilho com a ação
"enviar e-mail ao solicitante"**. Uma resposta "fora do expediente" é um
gatilho com a condição "fora do horário comercial" (§3.2.1).

Toda mensagem automática ao cliente passa por uma **guarda central**, que vale
mesmo que o gatilho esteja mal configurado. A guarda é a da spec 02 §6, mais
uma regra:

1. nunca responder a mensagem classificada como **automática**, bounce, spam
   ou laço (spec 02 §3). Na prática, esses casos nem geram evento (§3.1);
2. nunca enviar a endereços de sistema nem ao próprio endereço de suporte
   (spec 02 §6);
3. nunca enviar a endereço marcado como inválido (spec 02 §7);
4. no máximo **10 mensagens automáticas por destinatário a cada 24 h**, por
   conta (spec 02 §6). O contador é único para todos os gatilhos;
5. **regra nova**: no máximo **1 e-mail por gatilho, por ticket, a cada 24 h**.
   Isso protege contra o robô externo que responde sem marcar a mensagem como
   automática: ele entra como "mensagem do cliente", mas não recebe uma
   resposta automática por mensagem;
6. a saída leva os cabeçalhos de mensagem automática e o nosso cabeçalho de
   laço (spec 02 §6), além do marcador de assunto e dos identificadores da spec
   02 §9, para que a resposta do cliente se encadeie.

Envio suprimido pela guarda gera evento de auditoria com o motivo. O gatilho
não é considerado com falha.

Mudança só de estado, sem mensagem pública, **não** envia e-mail ao
solicitante, a menos que um gatilho configurado o faça (spec 13 Δ12).

### 6.1 Confirmação de recebimento

- A confirmação de recebimento é **um mecanismo só** (D25): um gatilho de
  **criação**, para todos os canais em que o solicitante abre o pedido:
  e-mail, portal, **formulário de visitante** e **chat** (spec 13 Δ1, Δ16).
  Os canais não têm confirmação própria; a spec 03 deixa de ter a sua e usa
  este mecanismo.
- Toda conta nova vem com **um** gatilho de confirmação (evento criado; origem
  solicitante; canal e-mail, portal, formulário de visitante ou chat) na
  **última posição**, para que o roteamento já tenha acontecido quando a
  confirmação sair. O texto pode usar a variável do link do ticket no portal.
- **Endereço não verificado** (D25): a confirmação **não repete nada do que
  foi digitado** (assunto, corpo, campos do formulário, nome informado). Traz
  só o **número** do ticket e o **link de convidado**; o texto do gatilho é
  trocado por esse texto mínimo do sistema, no idioma da conta. Vale no
  máximo **3 confirmações por endereço não verificado a cada 24 h**; as
  seguintes são suprimidas pela guarda, com evento de auditoria do motivo.
  Esse limite é contado junto com o de 10 mensagens automáticas.
- Para ter texto diferente dentro e fora do horário (spec 13 Δ11), o admin
  troca o gatilho padrão por **dois**, com a mesma condição de canal e
  "dentro" / "fora do horário comercial" do mesmo calendário. Eles se excluem
  (§3.2.1): o solicitante recebe **uma** confirmação só. O gatilho "fora" pode
  também adicionar a etiqueta "fora do horário".
- A confirmação passa pela guarda central (limite de 10 por destinatário a
  cada 24 h).

### 6.2 Pesquisa de satisfação

Entra no MVP (spec 13 Δ15, D19).

- **Quando**: na transição para **resolvido** feita junto com uma **resposta
  pública** de agente (no mesmo envio, por macro ou pela API). O convite vai
  **dentro do mesmo e-mail** da resposta, nunca num e-mail à parte (spec 13
  Δ12). Resolução sem resposta pública (duplicado, gatilho, tarefa, "meu
  problema foi resolvido" do solicitante, D08) não envia convite.
- **Para quem**: só o **solicitante**. Os participantes recebem o e-mail da
  resposta sem o convite.
- **Onde se avalia**: pelo link do e-mail (sem login, válido só para aquele
  ticket, aquele solicitante e aquela resolução, até o ticket fechar), pelo
  portal e, em tickets de chat, no próprio widget (spec 13 Δ16). Num ticket de
  chat, o convite aparece no widget junto com a resposta; se a resposta cair
  no envio por e-mail (spec 03), o convite vai nesse e-mail. É **um** convite
  em qualquer caso.
- **Escala**: nota de **1 a 5**, comentário opcional e **motivo** opcional de
  uma lista definida pelo admin. O motivo só é oferecido e só é aceito para
  notas 1 a 3; enviado com nota 4 ou 5, é erro de validação. "Satisfeito" =
  nota 4 ou 5 (o cálculo do percentual fica na spec 11).
- **Uma avaliação por resolução**. O solicitante pode **alterar** a avaliação
  até o ticket **fechar**; depois disso, a avaliação fica congelada e o link
  mostra que o pedido foi encerrado.
- **No máximo 1 convite por ticket a cada 24 h**. Se o ticket reabre e é
  resolvido de novo com resposta pública menos de 24 h depois do último
  convite, não há convite novo, e a avaliação anterior continua valendo e
  alterável. Depois de 24 h, um novo convite é enviado e abre uma nova
  avaliação, ligada à nova resolução. As avaliações anteriores ficam no
  histórico.
- **Não há convite** quando: o endereço do solicitante é inválido; o ticket
  está marcado como spam; o ticket é de contato proativo (spec 01 §4.6) e foi
  resolvido sem nenhuma resposta do solicitante; o admin desligou a pesquisa
  no grupo do ticket; a conta desligou a pesquisa; o ticket é **pai** (marcado,
  spec 01 §4.8); ou o ticket está **vinculado a um pai** no momento da
  resolução, seja em cascata (§4.5), seja resolvido sozinho (spec 13 Δ35). Um
  ticket desvinculado volta à regra comum nas resoluções seguintes.
- A avaliação **não muda o estado** do ticket, não reabre, não é mensagem da
  conversa e não conta como resposta do solicitante para o SLA nem para o
  fechamento automático. O comentário aparece para os agentes junto da
  avaliação.
- Dar ou alterar a avaliação grava um evento de auditoria (origem
  solicitante) e gera o evento de gatilho **avaliação recebida** (§3.1), para
  o admin montar avisos como "nota 1 ou 2 → notificar o gestor".
- O convite não passa pelo limite de 10 mensagens automáticas (ele viaja na
  resposta do agente), mas respeita as regras 2 e 3 da guarda central.

---

## 7. SLA

### 7.1 Políticas e seleção

- Uma conta tem uma **política padrão** (sem condições, sempre a última) e,
  opcionalmente, políticas com condições, cada uma com uma **posição**.
  Portanto **todo ticket tem uma política vigente**; o que pode faltar é a
  meta para a prioridade dele (abaixo).
- Condições de política no MVP: **grupo está em** e/ou **organização do
  solicitante está em**. Com as duas preenchidas, valem as duas (E).
- Seleção: percorrer as políticas por posição; **a primeira cujas condições
  casam é a vigente**. Não há sobreposição ambígua: a posição desempata.
- A política vigente é reavaliada quando mudam o grupo, o solicitante ou a
  prioridade do ticket. Mudar a organização de uma pessoa não reavalia tickets
  existentes; só tickets criados depois.
- **Exceção: encaminhamento com retorno** (spec 13 Δ5). Encaminhar com
  retorno e devolver **não** reavaliam a política: o ticket mantém a política
  e o calendário que tinha no grupo de origem, e o SLA não reinicia. Uma
  transferência normal, que cancela o retorno, reavalia como qualquer mudança
  de grupo.
- Ticket sem meta para a sua prioridade na política vigente fica **sem aquela
  métrica**. A seleção **não** passa para a política seguinte: quem escolhe a
  política é a condição, não a prioridade.

### 7.2 Metas

- Por prioridade (baixa, normal, alta, urgente), cada política define, de
  forma independente e opcional:
  - **primeira resposta**: minutos úteis até a primeira resposta pública de
    agente (§7.6);
  - **resolução**: minutos úteis até o ticket chegar a resolvido ou fechado.
- Metas em minutos inteiros, maiores que zero. Meta ausente = sem métrica.
- **Próxima resposta** (prazo para responder cada nova mensagem do cliente)
  **não está no MVP**. Ela exige definir "qual mensagem do cliente está
  pendente" em conversas com vários participantes e mensagens automáticas, e
  dois dos projetos que a oferecem divergem sobre isso. Fica no roadmap.

### 7.3 Calendários

- Cada calendário tem um **fuso IANA** (ex.: America/Sao_Paulo, UTC), uma
  lista de **intervalos por dia da semana** e uma lista de **feriados**.
- Intervalos em horário local, de minuto a minuto, com início < fim, sem
  sobreposição no mesmo dia. O fim pode ser 24:00. Um dia pode ter vários
  intervalos (ex.: 09:00–12:00 e 13:00–18:00).
- **Intervalo que cruza a meia-noite** é guardado como dois intervalos: o
  trecho até 24:00 no dia em que começa e o trecho a partir de 00:00 **no dia
  seguinte**. A interface pode aceitar "22:00–06:00" e fazer a divisão sozinha.
  Cada trecho pertence ao **dia local** em que acontece, para efeito de dia da
  semana e de feriado.
- **Feriado** = data local inteira (no fuso do calendário), sem atendimento.
  Pode repetir todo ano (data fixa). Fechamentos de meio dia ficam para o
  roadmap.
- Todo calendário precisa ter pelo menos um intervalo na semana.
- Toda conta tem o calendário **"sempre aberto"** (00:00–24:00 todos os dias,
  no fuso da conta), usado pela política padrão e como calendário da conta até
  o admin trocar.
- **Horário de verão**: os intervalos são de relógio local e o tempo útil é
  medido em **minutos reais** decorridos dentro deles. No dia da mudança, o dia
  00:00–24:00 tem 23 h ou 25 h reais. (America/Sao_Paulo não tem horário de
  verão desde 2019; o caso é testado com outro fuso.)
- Excluir um calendário em uso (por política, como calendário da conta ou de
  grupo, ou em condição de gatilho) é proibido. Editar (ex.: acrescentar um
  feriado) recalcula os prazos em aberto (§7.7).

### 7.4 Quando o relógio de cada métrica corre

Categorias de SLA dos estados (spec 01 §4.1, D18): aberto = **corre**;
pendente e **em espera** = **pausado**; resolvido, fechado e mesclado =
**parado**.

| Categoria | Primeira resposta | Resolução |
|---|---|---|
| corre (aberto) | corre | corre |
| pausado (pendente, em espera) | **corre** | pausa: o tempo consumido congela e é retomado na volta |
| parado (resolvido, fechado, mesclado) | para | para; ao entrar aqui, a métrica é **cumprida** se estiver no prazo |

Por que a primeira resposta não pausa em pendente nem em em espera: "pendente"
significa aguardar o cliente, o que pressupõe que já falamos com ele; "em
espera" significa aguardar um terceiro, o que não responde ao cliente. Se o
ticket foi para um desses estados sem nenhuma resposta pública (ex.: só com uma
nota interna), o cliente continua sem resposta, e pausar o relógio permitiria
esconder atraso.

O relógio também só avança **dentro dos intervalos do calendário**. Fora deles,
nenhuma métrica consome tempo, em qualquer estado.

O **encaminhamento com retorno** não muda a categoria: o estado real do ticket
no grupo de destino é aberto (spec 13 Δ5), então a resolução continua
correndo. "Resolver" dentro do grupo de destino devolve o ticket como
**aberto** ao grupo de origem e, portanto, **não** cumpre a resolução.

### 7.5 Cálculo do prazo

- **Início**: o instante de criação do ticket no PantherDesk. Para e-mail, é
  o momento da gravação, não o cabeçalho de data da mensagem. Ticket criado
  fora do horário começa a consumir na abertura do próximo intervalo.
- **Tempo consumido** de uma métrica = soma dos minutos reais dentro dos
  intervalos do calendário enquanto o relógio da métrica corria, desde o
  início. É sempre função de duas coisas: o **histórico de estados** do ticket
  (auditoria) e a **política vigente** (metas + calendário).
- **Prazo** = o instante em que o tempo consumido atinge a meta, supondo que o
  relógio siga correndo. Se isso coincide com o fim de um intervalo, o prazo é
  **esse fim** (ex.: 12:00), não a abertura do intervalo seguinte.
- Enquanto a resolução está pausada, ela **não tem prazo**: mostra-se
  "pausada, restam X min úteis". Na retomada, o novo prazo é calculado a partir
  do instante da retomada, com os minutos que restavam.
- O prazo é gravado como **instante absoluto em UTC** e exibido no fuso de
  quem vê. Ele não depende da frequência da verificação.
- As filas mostram o **vencimento mais próximo** entre as métricas ativas do
  ticket ("vence em" / "vencido há") e permitem ordenar por ele (spec 08,
  spec 13 Δ9). Métrica pausada não tem vencimento para esse efeito. O selo de
  cada linha e a fila "Quase escalando" estão no §7.15.
- Precisão: instantes em segundos; metas em minutos. Resposta com instante
  **≤ prazo** cumpre a meta; resposta 1 s depois, não.

### 7.6 O que conta como primeira resposta

Conta **somente** a primeira **mensagem pública cujo autor é um agente**,
criada na conversa principal depois da criação do ticket, por qualquer meio:
interface, macro (§4), API com token de agente, resposta pelo chat, resposta
propagada de um ticket pai para o filho (§4.5; conta no filho, no instante em
que é gravada nele) e resposta por e-mail a uma notificação **quando** a conta
configurou essa resposta como pública (spec 02 §5, D02).

Não contam:
- nota interna, inclusive a que nasce, por padrão, da resposta de um agente a
  um e-mail de notificação (D02);
- mensagem de sistema de qualquer tipo, inclusive as **respostas automáticas
  que nós enviamos** (§6) e as recebidas;
- e-mail enviado por gatilho;
- mensagem de agente numa **conversa paralela** (ela não vai ao solicitante);
- a mensagem inicial de um ticket criado por agente em nome do cliente (ela
  descreve o pedido, não responde a ele);
- mensagem de agente em outro ticket, inclusive em tickets mesclados no destino
  (§7.9).

A primeira resposta, depois de cumprida, **nunca** volta a ser medida no mesmo
ticket.

Se o ticket entra em categoria **parado** sem nenhuma resposta pública (ex.:
resolvido como duplicado), a métrica de primeira resposta fica **encerrada sem
resposta**: não é cumprida nem violada. Se o ticket reabrir, ela volta a correr
com o tempo que já tinha consumido.

### 7.7 Mudanças no meio do caminho

Regra única: **o prazo é sempre recalculado a partir da criação**, com o
histórico de estados do ticket e a política vigente **agora**.

- **Mudança de prioridade**: a nova meta vale como se estivesse lá desde a
  criação. Se o tempo já consumido for maior que a nova meta, a métrica é
  **violada imediatamente**, com o instante da mudança registrado como instante
  da violação e o motivo "mudança de prioridade".
- **Mudança de grupo ou de solicitante** que troca a política: as metas **e o
  calendário** da nova política passam a valer, e o tempo consumido é
  recalculado desde a criação no novo calendário. Se isso já ultrapassa a meta,
  a violação é imediata, como acima. (Encaminhar com retorno e devolver não
  trocam a política, §7.1.)
- **Edição da política ou do calendário** pelo admin: recalcula, de forma
  assíncrona (minutos), os tickets com métricas em andamento ou pausadas. Pode
  gerar avisos e violações. Métricas já cumpridas, violadas ou encerradas não
  mudam.
- Métrica **violada** continua violada para sempre (§7.11). O recálculo muda
  só o prazo exibido, nunca o resultado.
- Métrica **cumprida** de primeira resposta não é reavaliada com a nova meta.
- Ticket que **ganha** uma métrica que não tinha (ex.: baixa → normal numa
  política em que baixa não tem resolução): ela é calculada desde a criação,
  pela mesma regra.
- Ticket que **perde** uma métrica (a nova prioridade não tem meta): a métrica
  some; violação já registrada permanece.

### 7.8 Reabertura e resultado final

Vale para qualquer volta de categoria parado para aberto: resposta do cliente
em resolvido, reabertura de fechado pela política `reabrir` ou `janela` (spec 01
§4.4), ou reabertura por admin.
- **Primeira resposta**: se foi cumprida, continua cumprida. Se estava
  encerrada sem resposta, volta a correr (§7.6).
- **Resolução**: volta a correr com o **tempo já consumido** (não recomeça do
  zero). O registro "cumprida" da resolução anterior fica no histórico, mas o
  estado da métrica volta para "em andamento".
- Se a resolução já estava **violada**, continua violada; nenhum novo aviso,
  violação ou escalonamento dessa métrica é registrado.
- **Resultado final** (D10): cada métrica de cada ticket tem **um único
  resultado**, usado pela spec 11. Se a métrica violou em algum momento, o
  resultado é **violada**, mesmo que um ciclo anterior tenha sido cumprido.
  Ex.: resolvido dentro do prazo, reaberto e depois passa do prazo → violada.
  Se nunca violou, o resultado é o do último ciclo (cumprida, encerrada ou em
  andamento).
- Na política `novo` (spec 01 §4.4, que é a da EARJ, spec 13 Δ13), o ticket
  novo tem SLA próprio, desde a sua criação.

### 7.9 Mescla

- **Origem** (vai para mesclado): as métricas em andamento ficam **encerradas
  por mescla**, sem cumprimento nem violação. Avisos e violações já
  registrados permanecem.
- **Destino**: o SLA não muda. As mensagens trazidas da origem não contam como
  primeira resposta nem alteram o tempo consumido do destino.

### 7.10 Aviso antes da violação

- A política escolhe **uma** forma de aviso, que vale para todas as suas metas
  (spec 13 Δ14):
  - **percentual da meta** (padrão **20 %**, de 0 % = aviso desligado a 50 %);
  - **tempo útil absoluto antes do prazo** (ex.: "1 hora útil antes"), em
    minutos inteiros maiores que zero.
- **Limiar** = tempo restante em que o aviso dispara. Na forma percentual, o
  limiar é percentual × meta, **arredondado para baixo** em minutos inteiros;
  na forma absoluta, é o próprio valor. O aviso dispara quando o tempo
  **restante** fica ≤ limiar, ou seja, quando o consumido atinge meta − limiar.
  - Ex.: meta de 4 h (240 min), 20 % → limiar 48 min → aviso aos 192 min
    consumidos.
  - Ex.: meta de 16 min, 20 % → 3,2 → limiar 3 min → aviso aos **13** min
    consumidos.
  - Ex.: meta de 8 h úteis, "1 hora útil antes" → aviso aos 420 min
    consumidos.
- Por que as duas formas: um percentual funciona igual para metas de 15
  minutos e de 3 dias, e é o padrão; mas uma operação que pensa em "1 hora
  antes" precisa poder dizer isso diretamente.
- Se o limiar é **maior ou igual à meta** (ex.: aviso de 1 h com meta de
  30 min), o restante já começa abaixo do limiar: o aviso sai no instante em
  que a métrica começa a consumir tempo.
- O aviso é medido em tempo útil. Se o limiar cai fora do expediente, o aviso
  sai na hora em que o tempo útil o atinge, ou seja, depois da abertura.
- **No máximo um aviso por métrica por ticket**, em toda a vida do ticket
  (spec 13 Δ14). Se o restante já está abaixo do limiar no momento de uma
  retomada ou de uma mudança de prioridade, o aviso sai imediatamente (se
  ainda não saiu). Depois de uma reabertura ou de uma pausa, a métrica não
  avisa de novo.
- Efeito: notificação ao responsável ou, sem responsável, aos agentes ativos
  com **escrita** no grupo do ticket; e evento de gatilho **SLA: aviso**.

### 7.11 Violação e escalonamento

- A violação é registrada **uma única vez por métrica por ticket**: evento de
  auditoria com métrica, prazo, instante da violação e política vigente. O
  registro é **permanente**: não some se a prioridade, a política ou o
  calendário mudarem depois, nem se o SLA for removido.
- Efeitos imediatos da violação:
  1. notificação ao responsável ou, sem responsável, aos agentes ativos com
     **escrita** no grupo do ticket e, se a política tiver essa opção
     marcada, também aos admins;
  2. evento de gatilho **SLA: violação**, para que o admin monte a ação que
     quiser (subir a prioridade, mover de grupo, avisar alguém) com gatilhos
     comuns.
- **Escalonamento depois da violação** (opcional por política, spec 13 Δ14):
  "N horas úteis depois de vencido, avisar {destinatário}". O destinatário é
  um agente nomeado, os admins, ou o responsável (ou os agentes com escrita
  no grupo, sem responsável).
  - O instante do escalonamento = instante da violação + N horas úteis,
    contadas no calendário da política vigente com as **mesmas regras de
    relógio** da métrica: pendente e em espera suspendem a contagem da
    resolução; fora do expediente nada conta.
  - **Uma única vez por métrica por ticket.** Não sai se, antes do instante,
    a métrica atingir o objetivo (primeira resposta pública enviada; ticket
    resolvido, fechado ou mesclado). Se o ticket reabrir depois disso, não há
    novo escalonamento.
  - Efeito: notificação ao destinatário e evento de auditoria. Se o
    destinatário não puder ler o ticket (spec 06), a notificação não é
    entregue, e o evento registra "destinatário sem acesso".
  - O escalonamento não gera evento de gatilho no MVP.
- Não há reatribuição embutida nem escalonamento em vários níveis no MVP.
- Um ticket com violação aparece num filtro de "SLA violado" e mantém um
  indicador visível só para agentes.

### 7.12 Detecção

- A tarefa de verificação (§5) roda a cada minuto e registra avisos,
  violações e escalonamentos cujo instante já passou.
- Instante registrado da violação = **o prazo** (instante teórico), mesmo que a
  detecção tenha atrasado. Exceção: violação imediata por recálculo (§7.7), que
  registra o instante do recálculo.
- Uma resposta gravada antes da detecção, mas depois do prazo, **não** cumpre a
  meta: vale o instante da resposta comparado com o prazo.
- Idempotência: chave (ticket, métrica, tipo aviso/violação/escalonamento).
  Rodar a verificação de novo não duplica evento nem notificação.

### 7.13 Estados de uma métrica

| Estado | Significado | Final? |
|---|---|---|
| em andamento | relógio correndo ou parado só por estar fora do expediente | não |
| pausada | só resolução, em pendente ou em espera | não |
| cumprida | atingiu o objetivo dentro do prazo | primeira resposta: sim; resolução: não (pode voltar para em andamento na reabertura) |
| violada | prazo passou antes do objetivo | **sim** |
| encerrada sem resposta | primeira resposta, ticket parado sem resposta pública | não (volta a correr na reabertura) |
| encerrada por mescla / por spam | ticket mesclado, ou fechado como spam (spec 01 §4.1) | sim |

- A falta de meta para a prioridade não é um estado: o ticket simplesmente
  **não tem** aquela métrica (§7.1). Relatórios podem chamá-la de "sem meta".
- As duas formas de "encerrada" não contam nem como cumprida nem como
  violada. A spec 11 agrupa as duas como "encerrada" para os percentuais.

### 7.14 Prazo do evento

Regras da spec 13 Δ34 e das decisões D40, D41 e D44; campos do evento e marca
"pronto" na spec 01 §5.2.
- **SLA do ticket de evento** (D40): a **primeira resposta** segue a política
  de SLA comum (o pedido precisa ser acolhido), com prazo, aviso, violação e
  escalonamento como em qualquer ticket. A **resolução** comum **não** se
  aplica: o ticket de evento não tem essa métrica, qualquer que seja a
  política vigente. Até o dia, ele pode ficar pendente ou em espera sem que
  nenhum prazo de resolução corra. Mudar o tipo do ticket **para** evento faz
  o ticket perder a métrica de resolução (violação já registrada permanece);
  a primeira resposta segue como estava. Mudar **de** evento para outro tipo
  faz o ticket ganhar a resolução desde a criação, pelas regras do §7.7
  (inclusive a violação imediata).
- O **prazo do evento** é o **início da montagem** (instante absoluto),
  cumprido pela marca **"pronto para o evento"** (D44; spec 01 §5.2): o evento
  está pronto no prazo quando a marca está ligada no instante do início da
  montagem (spec 11 §6.12). Montagem iniciada sem a marca **não** registra
  violação de SLA: aparece no selo "montagem sem pronto" (§7.15), na fila
  "Quase escalando" e no relatório da spec 11. Depois do evento, o técnico
  resolve normalmente.
- **Dias úteis**: datas com expediente no calendário do grupo do ticket (o da
  conta, se o grupo não tem um próprio; §7.3), sem feriado.
- **Avisos** (tarefa do §5), ao responsável; sem responsável, aos agentes
  ativos com escrita no grupo do ticket (o mesmo conjunto da D27; na EARJ, o
  grupo de eventos):
  - **2 dias úteis antes**: na abertura do expediente (início do primeiro
    intervalo do calendário) do **2º dia útil anterior** à data local da
    montagem;
  - **no dia**: na abertura do expediente do dia da montagem. Se esse dia não
    tem expediente, ou se a montagem começa antes da abertura, o aviso sai no
    último horário útil anterior à montagem, isto é, na abertura do
    expediente do **último dia útil anterior** (D41).
- **Janela já aberta** (D41): se o ticket nasce, ou o início da montagem
  muda, quando o instante de um aviso já passou e a montagem ainda não
  começou, esse aviso sai **imediatamente, uma vez**. Se os dois instantes já
  passaram, sai só o "no dia". Com a montagem já iniciada, nenhum aviso sai.
  Esta seção é a fonte da regra; a spec 09 §7.6 aponta para ela.
- Mudar o início da montagem recalcula os dois avisos; avisos já enviados para
  a data anterior não impedem os da data nova. Nenhum aviso sai se, no
  instante dele, o ticket estiver resolvido, fechado, mesclado ou não for
  mais do tipo evento.
- Cada aviso sai **uma vez** por ticket e por início da montagem (chave do
  §5). Os avisos de evento não geram evento de gatilho no MVP.
- Fase 2: checklist de preparação com tarefas de prazo relativo ao evento e
  detecção de conflito de local e de equipamento.

### 7.15 Selo de prazo e fila "Quase escalando"

Regras da spec 13 Δ37. A exibição é da spec 08; esta seção define os valores.
- **Métricas consideradas**: as que ainda não atingiram o objetivo, isto é, em
  andamento ou **violadas** com o objetivo ainda pendente (ex.: resolução
  violada num ticket ainda aberto). Métricas pausadas entram só no "pausado".
- **Selo** de cada ticket, nesta ordem:
  1. ticket do tipo evento (D40), no fuso da conta, na primeira linha que
     valer:
     - depois do fim do evento: "evento encerrado";
     - com a marca "pronto" ligada: "pronto";
     - montagem iniciada sem a marca: "montagem sem pronto", em **vermelho**,
       sempre com o texto;
     - antes da montagem, faltando **24 h ou mais**: "faltam N dias para a
       montagem", com N = data local da montagem − data local de hoje, em
       dias corridos (N ≥ 1);
     - antes da montagem, faltando **menos de 24 h**: "faltam N h para a
       montagem", com N = horas inteiras de tempo real restantes,
       arredondadas para baixo; abaixo de 1 h, "falta menos de 1 h para a
       montagem". Com N = 1, o singular: "falta 1 dia", "falta 1 h".
     A primeira resposta do evento não aparece no selo: ela entra na fila
     "Quase escalando" e na ordenação por vencimento como em qualquer ticket;
  2. com métrica considerada: a de prazo mais próximo, como "vence em …"
     (prazo no futuro) ou "vencido há …" (no passado, em vermelho, sempre com
     o texto), com o tempo real até o prazo ou desde ele;
  3. só com métricas pausadas: "pausado";
  4. sem nenhuma métrica: sem selo.
- **"Quase escalando"**: fila compartilhada padrão (spec 08). Contém os
  tickets **aberto, pendente ou em espera** que cumprem pelo menos uma destas
  condições:
  - a métrica considerada de prazo mais próximo está **vencida** ou tem
    **tempo útil restante ≤ 60 minutos**, medido no calendário da política
    vigente (vale também para a 1ª resposta de um ticket de evento);
  - ticket do tipo evento **sem** a marca "pronto" cuja montagem começa em
    **até 60 minutos úteis**, medidos no calendário do grupo do ticket
    (§7.14), ou **já começou**, enquanto o evento não terminou (D40).
  O prazo de cada ticket na fila é o da métrica ou o início da montagem, o
  que vier antes. Ordem: prazo crescente (o vencido há mais tempo primeiro),
  desempate pelo número. Recalculada a cada abertura da fila (spec 13 Δ9).
- A condição "prazo vence em até N minutos úteis ou vencido" fica disponível
  como filtro de fila; a fila padrão usa N = 60.
- Os avisos ao responsável (§7.10) e o escalonamento ao gestor (§7.11)
  continuam iguais.

---

## 8. Abordagens comparadas

| Projeto | Abordagem observada (documentação) | Prós | Contras |
|---|---|---|---|
| Zammad | Gatilhos em criação/atualização e por tempo, com um modo que só roda quando um atributo da condição mudou e outro que roda em qualquer atualização; **ordem alfabética** pelo nome; agendador em grade com limite por execução; macros atômicas **sem** resposta ao cliente; SLA com primeira resposta, atualização e solução sobre calendário com fuso, feriados por feed; alerta ~15 min antes; estados de espera congelam e o ticket pode escalar logo ao reabrir. | Modelo completo; macros atômicas; calendário rico. | Ordem alfabética é frágil (renomear muda o comportamento); reentrada não documentada; desempate entre SLAs sobrepostos indefinido; alerta fixo único não serve a metas longas. |
| Chatwoot (CE) | Regras por evento (criada, atualizada, mensagem, reaberta) com condições E/OU; macros com resposta e pré-visualização; resposta de ausência por horário da caixa, no máximo 1 por dia por conversa; pesquisa de satisfação ao resolver a conversa; SLA só na versão paga. | Macros com pré-visualização; limite de resposta de ausência por conversa; pesquisa integrada à conversa. | Ordem entre regras e reentrada não documentadas; sem SLA na edição aberta. |
| FreeScout | Núcleo: só auto-resposta por caixa, que reconhece cabeçalhos de resposta automática. Gatilhos, macros, pesquisa e "quase SLA" só em módulos pagos, com limite de execuções por conversa. | Anti-laço por cabeçalhos padrão. | Sem automação nem SLA no núcleo; o anti-laço do módulo é um contador. |
| osTicket | Filtros **só na criação**, ordem numérica, opção de parar ao casar; SLA = um único prazo de resolução, depois do qual o ticket fica vencido; agendas com feriados e precedência entre departamento, SLA e sistema; sem alerta prévio; sem pausa. | Ordem numérica explícita; simples. | Sem gatilho em atualização; sem primeira resposta; sem pausa; sem alerta prévio. |
| Znuny | Jobs por evento ou agendados com limite por execução; escalonamento com primeira resposta, atualização e solução; calendário por fila ou SLA; recálculo em muitas mudanças (prioridade, fila, estado, mescla); alerta prévio **em percentual**; verificação a cada 5 min; solução não volta a escalar depois de reaberto. | Alerta percentual; recálculo bem definido; eventos de "antes" e "depois" consumíveis por automação. | Reentrada não documentada; pausa em pendente não documentada; detecção com até 5 min de atraso. |
| UVdesk | Workflows evento + condições E/OU; reordenação define prioridade; workflow manual faz o papel de macro; SLA como app à parte. | Modelo evento/condição/ação claro. | Laço não documentado; SLA fora do núcleo. |
| Frappe Helpdesk | SLA com metas por prioridade (primeira resposta, resolução); seleção por condição + posição, com desempate pela política mais antiga; categorias de estado (corre/pausa/encerra); feriados por lista; violação permanente; recálculo desde o primeiro anexo do SLA; avaliação do cliente ao resolver; exemplos da documentação com contas erradas. | Categorias de estado; violação permanente; desempate determinístico. | Pausa só documentada para resolução; sem alerta prévio documentado; exemplos inconsistentes mostram como é fácil errar a aritmética. |

### Escolha do PantherDesk

| Aspecto | Escolha | Por quê |
|---|---|---|
| Ordem dos gatilhos | posição numérica explícita, sequencial, último a escrever vence | previsível; renomear não muda nada (problema da ordem alfabética) |
| Reentrada | alterações de gatilho não geram eventos; 1 vez por gatilho por evento | elimina o laço por construção, sem contador mágico |
| Falha | atômica por gatilho; a passada continua; a origem nunca é desfeita | uma regra quebrada não pode perder um e-mail nem travar o roteamento |
| Webhook | ação de gatilho que entrega o envelope padrão a uma assinatura existente | um formato só de evento; nada de corpo livre para validar |
| Macros | atômicas, com pré-visualização, com resposta pública; compartilhadas e pessoais; variáveis de lista fechada; uma intenção com variantes PT/EN | junta a atomicidade de um projeto com a pré-visualização de outro; variável errada não chega ao cliente; metade das macros para manter e o idioma certo sem o agente procurar |
| Agendador | só tarefas do sistema, idempotentes por chave lógica | o MVP não precisa de agendador genérico; idempotência vem de graça |
| Auto-resposta | é um gatilho + guarda central (spec 02 §6) + 1 por gatilho/ticket/24 h | um mecanismo só, também para a confirmação; protege contra robôs que não se identificam |
| Pesquisa | convite no e-mail da resposta que resolve; 1 por ticket a cada 24 h | o cliente recebe um e-mail só; reabrir e resolver em sequência não vira spam |
| Seleção de SLA | primeira política por posição; condições só grupo e organização | sem sobreposição ambígua; cobre "cliente VIP" e "equipe 24x7" |
| Metas | primeira resposta + resolução; próxima resposta no roadmap | as duas que todos os projetos com SLA concordam |
| Pausa | resolução pausa em pendente e em espera e retoma de onde parou; primeira resposta não pausa | é o comportamento que o cliente espera; evita esconder atraso |
| Mudança de prioridade/política | recalcula desde a criação; violação imediata se já passou; encaminhamento com retorno mantém a política | regra única, igual a dois dos projetos; o pedido "volta para mim" não muda o compromisso com o cliente |
| Reabertura | primeira resposta mantida; resolução retoma o tempo consumido; resultado violado é permanente | não perdoa atraso nem pune duas vezes |
| Aviso | percentual da meta (20 %) ou tempo útil absoluto; uma vez por métrica | o percentual serve a metas curtas e longas; o absoluto atende a quem pensa em "1 hora antes" |
| Violação | registrada uma vez, permanente, com o instante do prazo; escalonamento opcional N horas úteis depois | métricas confiáveis (spec 11); o gestor só é chamado quando o atraso persiste |

---

## 9. Casos de teste (critérios de aceite)

Atores: `ag1` e `ag2` (grupo N1), `ag3` (grupo Financeiro), `admin`,
`gestor` (agente com leitura em todos os grupos, destinatário de
escalonamento), solicitantes `ana` e `bia` (org. Acme) e `cris` (sem org.).
Salvo indicação, a conta tem a regra "responsável obrigatório para resolver"
**desligada** e a pesquisa de satisfação **ligada**.

Convenção de IDs: `AU-1xx` são casos de teste desta spec. Os cenários de
observação do catálogo são citados sempre como "cenário AU-0N".

### 9.1 Configuração de referência para SLA

Calendários:
- **C1 "Comercial SP"**: America/Sao_Paulo (UTC−3 o ano todo); seg–sex
  09:00–12:00 e 13:00–18:00 (480 min úteis por dia); feriados 2026-11-02 (seg)
  e 2026-11-20 (sex).
- **C2 "24x7 UTC"**: UTC; todos os dias 00:00–24:00; sem feriados.
- **C3 "Noturno SP"**: America/Sao_Paulo; seg–sex 22:00–24:00 e ter–sáb
  00:00–06:00 (turnos de seg→ter até sex→sáb); feriados conforme o caso.
- **C4 "24x7 Lisboa"**: Europe/Lisbon; todos os dias 00:00–24:00.
- **C5 "Escolar SP"**: America/Sao_Paulo; seg–sex 07:00–17:00 (600 min úteis
  por dia), sem intervalo de almoço; sem feriados em novembro de 2026. É o
  calendário da operação EARJ (spec 13 §5).

**C1 é o calendário de referência** dos testes desta spec e das specs 11 e 13
(D35). Um teste que usa outro calendário o indica na própria tabela ou no
título da seção, como as seções 9.10 e 9.11 (C5) e os casos com C2, C3 e C4.

Políticas, em ordem de posição (aviso padrão de 20 %):

| Política | Condição | Calendário | urgente (1ª / res.) | alta | normal | baixa |
|---|---|---|---|---|---|---|
| P1 "Financeiro" | grupo = Financeiro | C2 | 15 min / 1 h | 15 min / 2 h | 30 min / 4 h | — / — |
| P2 "Acme" | organização = Acme | C1 | 30 min / 4 h | 1 h / 8 h | 2 h / 16 h | 4 h / — |
| P0 padrão | — | C1 | 1 h / 8 h | 2 h / 16 h | 4 h / 24 h | 8 h / — |

Política **P3 "Escolar"** (usada só nas seções 9.10 e 9.11, numa conta de
teste em que ela é a padrão): calendário C5; urgente 30 min / 4 h, alta 1 h /
8 h, normal 2 h / 8 h, baixa 4 h / 16 h; aviso **absoluto de 60 min úteis**;
escalonamento **8 horas úteis** depois da violação para `gestor`.

Salvo indicação, os tickets são de `cris` no grupo N1 (política P0, calendário
C1). Horários sem "Z" estão em America/Sao_Paulo; o equivalente UTC vem entre
parênteses. 2026-11-03 é uma terça-feira; 2026-11-09 é uma segunda-feira.

### 9.2 Aritmética de prazo

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| SL-01 | P0, normal | ticket criado ter 2026-11-03 10:00 | 1ª resposta: prazo ter 03/11 15:00 (18:00Z), descontando o almoço; resolução (1440 min): sex 2026-11-06 10:00 (13:00Z) |
| SL-02 | P0, normal | criado ter 2026-11-03 17:00 | 1ª resposta: qua 2026-11-04 12:00 (15:00Z): 60 min na terça + 180 min na quarta; o prazo é o fim do intervalo (12:00), não 13:00 |
| SL-03 | P0, alta | criado sáb 2026-11-07 14:00 | a contagem começa seg 09:00; 1ª resposta: seg 2026-11-09 11:00 (14:00Z) |
| SL-04 | P0, urgente | criado ter 2026-11-03 07:30 | 1ª resposta: ter 03/11 10:00 (13:00Z) |
| SL-05 | P0, urgente | criado ter 2026-11-03 12:30 (almoço) | 1ª resposta: ter 03/11 14:00 (17:00Z) |
| SL-06 | P0, normal; seg 02/11 é feriado | criado sex 2026-10-30 16:00 | 1ª resposta: ter 2026-11-03 11:00 (14:00Z): 120 min na sexta, fim de semana e feriado pulados, 120 min na terça |
| SL-07 | P0, alta; sex 20/11 é feriado | criado qui 2026-11-19 10:00 | resolução (960 min): ter 2026-11-24 10:00 (13:00Z): qui 420 + seg 480 + ter 60 |
| SL-08 | P0, normal | criado seg 2026-11-09 18:00 (no fechamento) | 1ª resposta: ter 2026-11-10 14:00 (17:00Z); resolução (24 h úteis): qui 2026-11-12 18:00 (21:00Z), e não sex 09:00 |
| SL-09 | ticket de cris no grupo Financeiro (P1, C2), normal | criado 2026-11-03 23:50Z (20:50 em SP) | 1ª resposta: 2026-11-04 00:20Z (03/11 21:20 em SP); resolução: 2026-11-04 03:50Z (04/11 00:50 em SP) |
| SL-10 | política de teste com C3, meta de 1ª resposta 4 h | criado seg 2026-11-09 23:00 | prazo ter 2026-11-10 03:00 (06:00Z): 60 min no trecho de segunda + 180 min no trecho de terça |
| SL-11 | idem | criado seg 2026-11-09 20:00 | a contagem começa 22:00; prazo ter 2026-11-10 02:00 (05:00Z) |
| SL-12 | C3, meta de 2 h | criado sáb 2026-11-07 05:00 | 60 min no trecho de sábado 05:00–06:00; sábado não tem 22:00–24:00; domingo nada; prazo seg 2026-11-09 23:00 (2026-11-10 02:00Z) |
| SL-13 | C3 com feriado em qua 2026-11-04, meta 4 h | criado ter 2026-11-03 23:00 | ter 23:00–24:00 = 60 min; os trechos de quarta (00:00–06:00 e 22:00–24:00) caem no feriado; prazo qui 2026-11-05 03:00 (06:00Z) |
| SL-14 | C4 (Lisboa), meta 24 h; o horário de verão começa em 2026-03-29 01:00Z | criado sáb 2026-03-28 12:00 local (12:00Z) | prazo dom 2026-03-29 13:00 local (12:00Z): 24 h reais, e não 12:00 local |
| SL-15 | prazo de 1ª resposta ter 03/11 15:00 (SL-01) | ag1 responde em público às 15:00:00 | cumprida. Variante: resposta às 15:00:01 → violada, com instante da violação 15:00:00 |

### 9.3 Pausa, retomada e reabertura

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| SL-20 | P0 normal criado ter 2026-11-03 10:00; ag1 responde às 11:00 | ag1 põe em pendente qua 2026-11-04 10:00; cris responde seg 2026-11-09 15:00 (volta a aberto) | consumido até a pausa: 480 min (ter 420 + qua 60; restam 960); enquanto pendente, sem prazo ("pausada, restam 960 min"); novo prazo de resolução qua 2026-11-11 15:00 (18:00Z): seg 180 + ter 480 + qua 300 |
| SL-21 | P0 normal criado qui 2026-11-05 09:00 (resolução original seg 09/11 18:00) | pendente sex 2026-11-06 17:00, com data de retorno seg 2026-11-09 08:00; a tarefa reabre às 08:00 | consumido 900 min, restam 540; prazo de resolução ter 2026-11-10 10:00 (13:00Z): só os 60 min úteis de sexta ficaram pausados |
| SL-22 | P0 normal criado ter 2026-11-03 10:00, sem resposta | ag1 escreve nota interna e põe em pendente às 11:00; cris responde às 16:00 | a 1ª resposta **não** pausa: prazo continua ter 15:00; violação registrada com instante 15:00, durante o pendente |
| SL-23 | P0 normal criado ter 2026-11-03 10:00; ag1 responde às 11:00; resolvido às 14:00 | cris responde qui 2026-11-05 10:00 (reabre) | 1ª resposta continua cumprida (11:00); resolução: o registro "cumprida" fica no histórico, consumido 180 min, restam 1260; novo prazo seg 2026-11-09 16:00 (19:00Z) |
| SL-24 | P0 normal criado ter 2026-11-03 10:00 | ag1 resolve às 11:00 sem resposta pública (duplicado); cris responde qua 2026-11-04 10:00 | ao resolver: 1ª resposta "encerrada sem resposta" (nem cumprida nem violada); na reabertura, volta a correr com 60 min consumidos; prazo qua 2026-11-04 14:00 (17:00Z) |
| SL-25 | cris no Financeiro (P1), normal, criado 2026-11-03 12:00Z; resolução vence 16:00Z | ninguém resolve até 17:00Z; resolvido 17:00Z; cris reabre 2026-11-04 09:00Z; resolvido de novo 10:00Z | uma única violação de resolução (instante 16:00Z); depois da reabertura não há novo aviso nem nova violação; resultado final da resolução: violada |
| SL-26 | ticket fechado, política do grupo `reabrir`, resolução cumprida com 300 min consumidos | cris responde | igual a SL-23: resolução volta a correr com 300 min consumidos |
| SL-27 | P0 normal criado ter 2026-11-03 10:00; ag1 responde às 11:00; resolvido às 14:00 (180 min, cumprida) | cris reabre qui 2026-11-05 10:00 e ninguém resolve até o novo prazo seg 2026-11-09 16:00 | violação registrada com instante seg 16:00; resultado final da resolução: **violada** (D10), apesar do "cumprida" anterior no histórico |

### 9.4 Mudanças no meio do caminho

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| SL-30 | P0 normal criado ter 2026-11-03 10:00, sem resposta | às 11:30 ag1 muda a prioridade para urgente | 1ª resposta: 90 min consumidos > 60 → **violada na hora**, instante 11:30, motivo "mudança de prioridade"; resolução urgente (480 min): qua 2026-11-04 10:00 (13:00Z) |
| SL-31 | P0 urgente criado ter 2026-11-03 10:00 (1ª resposta 11:00, aviso 10:48) | às 10:30 ag1 muda para normal | nenhum aviso às 10:48; 1ª resposta 15:00 (18:00Z); novo aviso aos 192 min consumidos = 14:12 (17:12Z); resolução sex 06/11 10:00 |
| SL-32 | P0 urgente criado ter 2026-11-03 10:00; 1ª resposta violada às 11:00 | às 11:30 muda para baixa | continua **violada**; nenhum novo aviso nem violação de 1ª resposta; baixa não tem resolução → a métrica de resolução some |
| SL-33 | cris no N1 (P0, C1), normal, criado ter 2026-11-03 10:00 (13:00Z) | às 11:00 (14:00Z) ag1 move para Financeiro → P1 (C2) | recalculado desde a criação em C2: 60 min consumidos > 30 → 1ª resposta violada às 14:00Z; resolução (4 h): 2026-11-03 17:00Z (14:00 em SP) |
| SL-34 | ana (Acme) abre ticket no grupo Financeiro | criado | política vigente P1 (primeira na ordem), não P2 |
| SL-35 | bia (Acme) abre ticket no N1, prioridade normal | criado ter 2026-11-03 10:00 | P2: 1ª resposta ter 12:00 (15:00Z); resolução (960 min): qui 2026-11-05 10:00 (13:00Z), com terça 420 + quarta 480 + quinta 60 |
| SL-36 | ticket baixa em P0 | criado | só a métrica de 1ª resposta (8 h); nunca há violação de resolução |
| SL-37 | P0 normal aberto, resolução vence sex 06/11 10:00 | admin cadastra feriado em qui 2026-11-05 no C1 | recálculo em até alguns minutos; novo prazo seg 2026-11-09 10:00 (13:00Z) |

### 9.5 Aviso, violação, detecção e mescla

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| SL-40 | P0 normal criado ter 2026-11-03 10:00 | o relógio passa | aviso de 1ª resposta às 14:12 (17:12Z), 192 de 240 min; aviso de resolução qui 2026-11-05 14:12 (17:12Z), 1152 de 1440 min |
| SL-41 | P0 urgente criado ter 2026-11-03 17:30 | o relógio passa | 1ª resposta vence qua 2026-11-04 09:30 (12:30Z); aviso aos 48 de 60 min = qua 09:18 (12:18Z): 30 min na terça + 18 min na quarta |
| SL-42 | cris no Financeiro (P1), alta, criado 2026-11-03 12:00Z | o relógio passa | 1ª resposta vence 12:15Z; aviso 12:12Z (20 % de 15 = 3 min) |
| SL-43 | política com aviso 0 % | o relógio passa | nenhum aviso; a violação acontece normalmente |
| SL-44 | violação de 1ª resposta às 15:00 | a verificação roda 15:00, 15:01 e duas vezes em paralelo às 15:02 | 1 evento de violação; 1 notificação ao responsável (ou aos agentes com escrita no N1); 1 passada de gatilhos "SLA: violação" |
| SL-45 | tarefas fora do ar das 14:00 às 17:00; prazo 15:00 | as tarefas voltam às 17:00 | violação registrada com instante 15:00; notificação sai às 17:00 marcada como atrasada, uma vez |
| SL-46 | prazo 15:00; a resposta de ag1 é gravada às 15:00:30, antes da verificação das 15:01 | verificação 15:01 | violada (15:00:30 > 15:00:00) |
| SL-47 | #1011 com 1ª resposta em andamento | ag1 mescla 1011 em 1010 | métricas de 1011 "encerradas por mescla", sem violação posterior; SLA de 1010 inalterado; as mensagens de agente trazidas de 1011 não cumprem a 1ª resposta de 1010 |
| SL-48 | ticket com violação de resolução registrada | admin remove a meta de resolução da política | a violação continua no histórico e nas métricas |
| SL-49 | política de teste em C2 com 1ª resposta de 16 min e aviso de 20 % | ticket criado 2026-11-03 12:00Z | limiar 3,2 → 3 min; aviso 12:13Z (13 min consumidos); prazo 12:16Z |

### 9.6 O que conta como primeira resposta

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| SL-50 | ticket aberto sem resposta | ag1 escreve nota interna | 1ª resposta continua em andamento |
| SL-51 | ticket criado por e-mail; o gatilho de confirmação envia e-mail | — | a confirmação é mensagem de sistema pública; não cumpre a 1ª resposta |
| SL-52 | ticket pendente | chega auto-resposta de ausência (fx08) | mensagem de sistema; nada muda no SLA (spec 02 EM-20) |
| SL-53 | ag1 cria ticket em nome de cris com descrição | — | a descrição não cumpre a 1ª resposta; o relógio começa na criação |
| SL-54 | ag1 aplica macro com resposta pública | envia | 1ª resposta cumprida no instante do envio |
| SL-55 | conta com o padrão de resposta a notificação (nota interna, D02) | ag1 responde ao e-mail de notificação | a mensagem entra como **nota interna**; a 1ª resposta continua em andamento |
| SL-56 | gatilho "criado → nota interna + e-mail ao solicitante" | ticket criado | nenhum dos dois cumpre a 1ª resposta |
| SL-57 | ticket criado sáb 2026-11-07 10:00 (prazo seg 09/11 11:00 em P0 alta) | ag1 responde sáb 11:00 | cumprida, com 0 min úteis consumidos |
| SL-58 | conta configurada com resposta a notificação "pública" | ag1 responde ao e-mail de notificação | a mensagem entra como resposta pública de agente; 1ª resposta cumprida |

### 9.7 Gatilhos

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AU-101 | G10 "assunto contém fatura → grupo Financeiro + etiqueta financeiro"; confirmação de recebimento na última posição | ana envia e-mail "Fatura errada" | grupo Financeiro, etiqueta financeiro, 2 eventos com origem automação e a regra G10; 1 e-mail de confirmação, enviado depois do roteamento |
| AU-102 | G10 "criado → prioridade alta"; G20 "criado → prioridade baixa" | ticket criado | prioridade final baixa; 2 eventos de auditoria (normal→alta por G10, alta→baixa por G20) |
| AU-103 | G10 "assunto contém fatura → grupo Financeiro"; G20 "grupo = Financeiro → responsável ag3" | ticket "fatura" criado | grupo Financeiro e responsável ag3 na mesma passada |
| AU-104 | as mesmas regras de AU-103, com posições trocadas (a regra de atribuição em 10) | ticket "fatura" criado | grupo Financeiro, **sem** responsável (na avaliação da regra de atribuição o grupo ainda era N1) |
| AU-105 | G10 "campos alterados, prioridade mudou → etiqueta revisar"; G20 "criado → prioridade alta" | ticket criado | prioridade alta, **sem** etiqueta revisar (a mudança de G20 não gera evento); depois, ag1 muda a prioridade → etiqueta revisar adicionada |
| AU-106 | G10 "campos alterados → nota interna 'conferir'"; G20 "nota interna → etiqueta nota" | ag1 muda o estado | exatamente 1 nota; G20 não roda; nenhuma passada nova |
| AU-107 | G10 "campos alterados → prioridade alta"; G20 "campos alterados, prioridade mudou → notificar ag2" | ag1 muda para pendente | prioridade alta; ag2 **não** é notificado ("mudou" só vê a mudança de estado feita por ag1) |
| AU-108 | G10 "grupo = Financeiro → etiqueta x + responsável ag2" (ag2 sem escrita no Financeiro); G20 "grupo = Financeiro → etiqueta y" | ticket criado no Financeiro | G10 falha inteiro (sem etiqueta x, D11); evento de falha com o motivo; alerta aos admins; etiqueta y aplicada |
| AU-109 | G10 "mensagem do cliente → notificar responsável" | fx08 (auto-resposta) encadeia num ticket pendente | nenhuma passada; nenhuma notificação; estado continua pendente |
| AU-110 | G10 "mensagem do cliente → e-mail ao solicitante" | um robô externo sem cabeçalhos de automático responde 15 vezes em 1 h | 1 e-mail enviado; os 14 seguintes suprimidos com evento "limite por gatilho" |
| AU-111 | confirmação de recebimento ligada; remetente com endereço **verificado** | o mesmo remetente abre 11 tickets em 24 h | 10 confirmações; a 11ª suprimida com evento (spec 02 EM-29). Para endereço não verificado, ver AU-171 |
| AU-112 | campo "Causa" obrigatório para resolver, vazio; G10 "mensagem do cliente contém 'pode fechar' → resolvido + etiqueta auto" | ana escreve "pode fechar" | G10 falha inteiro: continua aberto, sem etiqueta; evento de falha |
| AU-113 | G10 "estado mudou para fechado → webhook S1 + prioridade baixa" | a tarefa de fechamento automático fecha o ticket | entrega a S1 enfileirada; prioridade não muda, com registro "ignorada: ticket fechado" |
| AU-114 | G10 criado às 10:00 | ticket criado às 09:00 é atualizado às 09:30, antes de G10 existir | G10 não se aplica a eventos anteriores à sua criação |
| AU-115 | G10 desativado | evento que casaria | G10 não roda; o registro de execução não o mostra como casado |
| AU-116 | G10 "SLA: violação de 1ª resposta e prioridade normal → prioridade alta + notificar ag2"; ticket P0 normal criado ter 2026-11-03 10:00, sem resposta | a 1ª resposta é violada às 15:00 (240 min consumidos nas duas métricas) | prioridade alta; ag2 notificado 1 vez; a 1ª resposta continua violada (sem nova violação); resolução alta (960 min) recalculada para qui 2026-11-05 10:00 (13:00Z), restam 720 > limiar 192 → nenhum aviso nem violação, portanto **nenhuma** outra passada (§3.5) |
| AU-117 | G10 "criado e fora do horário de C1 → e-mail 'recebido fora do expediente'" | ana abre ticket sáb 2026-11-07 10:00; outro ter 2026-11-03 10:00 | 1º ticket: e-mail enviado; 2º: não |
| AU-118 | G10 "resposta de agente e estado = pendente → etiqueta aguardando" | ag1 envia resposta pública escolhendo pendente no mesmo envio | uma passada; G10 casa (o estado já é pendente); a etiqueta é aplicada uma vez |
| AU-119 | admin tenta salvar G10 com responsável ag3 e grupo inativo | salvar | recusado com o motivo |
| AU-120 | G10 falha em 50 passadas seguidas | 50ª falha | G10 desativado; alerta aos admins |
| AU-121 | calendário da conta = C5; o gatilho padrão de confirmação foi trocado por G90 "criado; canal e-mail, portal, formulário de visitante ou chat; dentro do horário da conta → e-mail 'recebemos'" e G91 "idem, fora do horário → e-mail 'fora do horário' + etiqueta fora do horário" | ana abre ticket pelo portal qua 2026-11-11 10:00; outro qua 2026-11-11 18:30; outro sáb 2026-11-14 09:00 | 1º: só o e-mail de G90, sem etiqueta; 2º e 3º: só o e-mail de G91 e a etiqueta "fora do horário"; cada ticket recebe **uma** confirmação |
| AU-122 | G90/G91 de AU-121 | ticket criado qua 2026-11-11 07:00:00 e outro às 17:00:00 | 07:00 está dentro (G90); 17:00 está fora (G91) |
| AU-123 | G10 "criado e prioridade urgente → chamar webhook S1"; S1 assina o tipo "ticket criado" | ticket urgente criado | uma entrega a S1 com o envelope padrão do evento (spec 10); sem corpo livre. Variante: admin tenta salvar G10 com uma assinatura desativada → recusado |
| AU-124 | regra "responsável obrigatório para resolver" ligada; G10 "mensagem do cliente contém 'resolvido' → resolvido + etiqueta auto"; ticket sem responsável | cris escreve "já está resolvido" | G10 falha inteiro (sem etiqueta, estado aberto); evento de falha "responsável obrigatório" |
| AU-125 | campo "Motivo do contato" com dependente "Equipamento" (só visível com motivo = hardware), e este com dependente "Sintoma" (só visível com equipamento = impressora); ticket com motivo hardware, equipamento "impressora" e sintoma "não imprime"; G10 "criado → motivo = rede" e G20 "criado → equipamento = projetor" | ticket criado com esses valores | G10 aplicado: Equipamento e Sintoma limpos, cada um com evento de limpeza; G20 falha (campo oculto) e nada de G20 é aplicado (revisto em v0.3, D51) |
| AU-126 | G10 "resposta de agente → notificar responsável"; ag1 é o responsável | ag1 responde em público | G10 casa; ag1 **não** é notificado (D12); nenhuma notificação enviada |
| AU-127 | G10 "criado e tipo = incidente → prioridade alta" | ticket criado com tipo incidente; outro sem tipo | 1º: prioridade alta; 2º: normal |
| AU-128 | ticket em espera com conversa paralela aberta; G10 "mensagem do cliente → etiqueta cliente-respondeu"; G20 "resposta em conversa paralela → etiqueta fornecedor-respondeu" | o fornecedor responde na conversa paralela | estado em espera → aberto (origem sistema); G20 aplicado; G10 não casa |
| AU-129 | G10 "avaliação recebida e nota ≤ 2 → notificar gestor" | cris avalia com nota 2; depois altera para 4 | 1ª avaliação: gestor notificado 1 vez; alteração para 4: G10 não casa |

### 9.8 Macros

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AU-130 | macro "Aguardando cliente": resposta pública com o nome do solicitante + pendente + etiqueta aguardando | ag1 escolhe a macro em ticket de ana | pré-visualização com aberto→pendente, a etiqueta e o texto com "Ana"; nada gravado ainda |
| AU-131 | após AU-130 | ag1 envia | uma operação: mensagem pública (autor ag1), estado pendente, etiqueta; eventos marcados "via macro"; 1 e-mail para ana; 1 passada de gatilhos; 1ª resposta cumprida |
| AU-132 | após AU-130 | ag1 cancela | nenhum evento, nenhum e-mail |
| AU-133 | macro "Resolver" com resposta + resolvido; "Causa" obrigatória vazia | ag1 envia | **nada** aplicado; nenhum e-mail; erro indicando o campo |
| AU-134 | macro que define responsável ag3 | ag1 aplica em ticket do N1 | recusada inteira (ag3 sem escrita no N1) |
| AU-135 | macro disponível só para o Financeiro | ag1 em ticket do N1 | a macro não aparece; aplicar pela API é recusado |
| AU-136 | ag2 com leitura no Financeiro | ag2 tenta aplicar macro em ticket do Financeiro | recusado (spec 06) |
| AU-137 | ticket fechado | qualquer macro | indisponível |
| AU-138 | ag2 altera a prioridade entre a pré-visualização e o envio de ag1 | ag1 envia | a pré-visualização é refeita mostrando o novo valor atual; exige nova confirmação |
| AU-139 | ag1 cria a macro pessoal "Visita agendada" | ag1 e ag2 abrem a lista de macros num ticket do N1 | ag1 vê a macro; ag2 não; ag2 não consegue aplicá-la pela API |
| AU-160 | macro compartilhada "Aguardando cliente" | ag1 tenta editar | recusado (só admin edita compartilhadas) |
| AU-161 | — | admin salva macro com o texto "Olá {variável inexistente}" ou com um marcador entre delimitadores que não é variável | recusado; o erro indica o trecho. Variante: macro antiga que usa um campo desativado aparece marcada na lista |
| AU-162 | macro com "Olá {primeiro nome do solicitante}, ticket #{número}" | ag1 aplica no #1234 de "Ana Ribeiro" | pré-visualização "Olá Ana, ticket #1234"; nada gravado até enviar |
| AU-163 | macro que muda o assunto para "Helpdesk — ticket #{número}" | ag1 aplica e envia no #1234 | assunto alterado; o marcador `[PD-1234]` continua nos e-mails (spec 02) |
| AU-164 | — | — | **removido em v0.3** — o filtro por idioma deu lugar à macro por intenção com variantes (spec 13 Δ36); ver AU-177 a AU-179 |
| AU-165 | macro aplicada 3 vezes hoje e nenhuma nos 30 dias anteriores; outra sem uso há 40 dias | admin abre a lista ordenada por "sem uso há 30 dias" | 1ª macro: 24 h = 3, 7 dias = 3, 30 dias = 3, último uso hoje; a 2ª aparece primeiro na ordenação. Pré-visualizar sem enviar não conta |
| AU-166 | regra "responsável obrigatório para resolver" ligada; ticket sem responsável | ag1 aplica macro "Resolver" (resposta + resolvido) | recusada inteira; erro indica o responsável. Variante: macro "Atribuir a mim e resolver" → atribuída a ag1 e resolvida |
| AU-167 | macro "Encaminhar para Financeiro": nota interna + encaminhar com retorno para Financeiro | ag1 aplica e envia em ticket do N1 | mesmo efeito do encaminhamento manual (spec 04): grupo Financeiro, sem responsável, origem registrada (ag1 / N1), nota gravada. Variante: macro com encaminhar com retorno e texto de resposta pública → recusada ao salvar |
| AU-168 | macro desativada | ag1 abre a lista | a macro não aparece; o admin ainda a vê na lista de administração, com a estatística |
| AU-169 | regra "responsável obrigatório" ligada; 5 tickets do N1 selecionados numa fila, 1 sem responsável | ag1 aplica em massa a macro "Resolver" | 4 tickets resolvidos, cada um com a sua operação e a sua passada; 1 falha com o motivo "responsável obrigatório"; o resultado mostra 4 alterados e 1 falha |

### 9.9 Tarefas agendadas

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AU-140 | 3 tickets pendentes com retorno às 14:00 e 2 metas vencendo às 15:00 | tarefas paradas 14:00–17:00 e depois religadas | 3 reaberturas (origem sistema, 1 evento cada), 2 violações com instante 15:00, notificações atrasadas, cada uma uma vez |
| AU-141 | 1200 tickets resolvidos vencem o fechamento automático no mesmo minuto | as tarefas rodam | 500 + 500 + 200 em três execuções; todos fechados; nenhum evento duplicado |
| AU-142 | fechamento automático (spec 01 TL-24) | a tarefa roda | passada de gatilhos com origem sistema, tipo "campos alterados" (estado mudou para fechado) |
| AU-143 | ticket em espera com data de retorno seg 2026-11-09 08:00, responsável ag1 | a tarefa roda às 08:00 | em espera → aberto, origem sistema, 1 evento; ag1 notificado; passada "campos alterados" |
| AU-144 | escalonamento devido às 15:00 (SL-63) | a verificação roda às 15:00 e duas vezes em paralelo às 15:01 | 1 evento de escalonamento; 1 notificação a `gestor` |

### 9.10 SLA da operação EARJ (P3, calendário C5)

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| SL-60 | P3 normal (resolução 480 min) criado seg 2026-11-09 09:00 | o relógio passa | resolução vence seg 17:00 (20:00Z); aviso seg 16:00 (19:00Z), 420 de 480 min |
| SL-61 | P3 normal criado seg 2026-11-09 15:00 | o relógio passa | resolução: 120 min na segunda + 360 na terça → vence ter 2026-11-10 13:00 (16:00Z); aviso ter 12:00 (15:00Z) |
| SL-62 | P3 normal criado sex 2026-11-13 16:30 | o relógio passa | resolução: 30 min na sexta + 450 na segunda → vence seg 2026-11-16 14:30 (17:30Z); aviso seg 13:30 (16:30Z) |
| SL-63 | SL-60 sem resolver; 1ª resposta cumprida | o relógio passa | violação de resolução com instante seg 17:00; escalonamento a `gestor` 8 h úteis depois: o expediente de terça começa às 07:00, portanto **ter 2026-11-10 15:00 (18:00Z)** |
| SL-64 | P3 normal criado seg 2026-11-09 09:00 (vence seg 17:00); em espera das 10:00 às 14:00 | o relógio passa | 60 min consumidos antes da pausa; 4 h pausadas; retomada às 14:00 com 420 restantes: seg 180 + ter 240 → vence ter 2026-11-10 11:00 (14:00Z); aviso ter 10:00 (13:00Z) |
| SL-65 | SL-60: aviso enviado seg 16:00 | às 16:10 (430 consumidos) ag1 põe em espera; o fornecedor responde ter 2026-11-10 08:00 (volta a aberto) | novo prazo ter 08:50 (11:50Z); o restante (50 min) já está abaixo do limiar, mas **nenhum** segundo aviso sai para a resolução |
| SL-66 | P3 urgente (1ª resposta 30 min, aviso de 60 min ≥ meta) | ticket criado seg 2026-11-09 06:00 | a contagem começa às 07:00; aviso de 1ª resposta às 07:00 (10:00Z); prazo 07:30 (10:30Z) |
| SL-67 | SL-63, mas ag1 resolve ter 2026-11-10 14:00 | o relógio passa | a violação de seg 17:00 permanece; **nenhum** escalonamento (a métrica atingiu o objetivo antes de ter 15:00) |
| SL-68 | SL-63; o ticket fica em espera ter 2026-11-10 09:00–11:00 | o relógio passa | a contagem do escalonamento suspende na espera: ter 07:00–09:00 = 2 h + 11:00–17:00 = 6 h → escalonamento ter 17:00 (20:00Z) |
| SL-69 | escalonamento P3 com destinatário `gestor`; `gestor` perde o acesso ao N1 antes do instante | o relógio passa | evento de escalonamento com "destinatário sem acesso"; nenhuma notificação entregue |

### 9.11 Em espera, encaminhamento e conversa paralela

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| SL-70 | P0 normal criado ter 2026-11-03 10:00; ag1 responde às 11:00 | ag1 põe em espera qua 2026-11-04 10:00 e abre conversa paralela com o fornecedor; o fornecedor responde seg 2026-11-09 15:00 (volta a aberto) | igual a SL-20: 480 min consumidos, "pausada, restam 960 min" durante a espera; novo prazo de resolução qua 2026-11-11 15:00 (18:00Z) |
| SL-71 | P0 normal criado ter 2026-11-03 10:00, sem resposta | ag1 escreve nota interna e põe em espera às 11:00 | a 1ª resposta **não** pausa: violação registrada com instante 15:00, durante a espera |
| SL-72 | cris no N1 (P0), normal, criado ter 2026-11-03 10:00 | às 11:00 ag1 encaminha com retorno para Financeiro | a política continua P0 (C1), **não** P1: 1ª resposta ter 15:00, resolução sex 2026-11-06 10:00, sem violação imediata (compare SL-33) |
| SL-73 | após SL-72 | ag3 "resolve" no Financeiro qua 2026-11-04 10:00 | o ticket volta ao N1, aberto, responsável ag1; a resolução **não** é cumprida e continua correndo com 480 min consumidos; prazo inalterado sex 10:00 |
| SL-74 | P0 normal criado ter 2026-11-03 10:00, sem resposta | ag1 envia mensagem ao fornecedor numa conversa paralela às 10:30 | a 1ª resposta continua em andamento (prazo 15:00) |
| SL-75 | ticket pendente com conversa paralela | o fornecedor responde | estado continua pendente (spec 13 Δ3); nada muda no SLA; a resposta não conta como resposta do solicitante |
| SL-76 | P0 normal criado qui 2026-11-05 09:00 | em espera sex 2026-11-06 17:00, com data de retorno seg 2026-11-09 08:00; a tarefa reabre às 08:00 | igual a SL-21: restam 540; prazo de resolução ter 2026-11-10 10:00 (13:00Z) |

### 9.12 Pesquisa de satisfação

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AU-150 | ticket aberto de cris, com ana como participante | ag1 envia resposta pública escolhendo resolvido | **um** e-mail para cris com a resposta e o convite; ana recebe o e-mail da resposta sem convite; nenhum outro e-mail |
| AU-151 | ticket aberto | ag1 muda o estado para resolvido sem mensagem pública | nenhum e-mail; nenhum convite |
| AU-152 | após AU-150 | cris dá nota 2 com o motivo "demorou" pelo link do e-mail | avaliação gravada; evento de auditoria (origem solicitante); evento de gatilho "avaliação recebida"; o estado continua resolvido |
| AU-153 | após AU-150 | pela API do portal, cris envia nota 5 com um motivo | erro de validação: motivo só para notas 1 a 3 |
| AU-154 | após AU-152 | cris altera para nota 4; depois o ticket fecha e cris tenta alterar de novo | 1ª alteração aceita, com evento; 2ª recusada, o link mostra que o pedido foi encerrado |
| AU-155 | ticket resolvido com convite às 10:00 e avaliado; cris reabre e ag1 resolve de novo com resposta pública às 12:00 | — | nenhum convite novo (menos de 24 h); a avaliação anterior é mantida e continua alterável |
| AU-156 | idem, resolvido de novo 25 h depois do convite | — | novo convite no e-mail da resposta; a nova avaliação fica ligada à nova resolução; a anterior continua no histórico |
| AU-157 | (a) ticket marcado como spam; (b) contato proativo resolvido sem resposta do solicitante; (c) endereço de cris inválido; (d) pesquisa desligada no grupo | ag1 envia resposta pública e resolve | nenhum convite em nenhum dos casos (em (c) também nenhum e-mail) |
| AU-158 | ticket avaliado com nota 1 e comentário | — | a avaliação não reabre o ticket, não é mensagem da conversa e não adia o fechamento automático |
| AU-159 | ticket de chat de bia | ag1 responde e resolve; bia não lê a resposta em 2 min | a pesquisa aparece no widget com a resposta; o e-mail de reserva (spec 03) leva a resposta e o mesmo convite; **um** convite no total |

### 9.13 Ajustes D23–D37

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AU-170 | gatilho padrão de confirmação; bia com endereço verificado | bia abre um ticket pelo chat; depois outro pelo formulário de visitante | uma confirmação para cada ticket, pelo mesmo gatilho de criação (D25); nenhuma confirmação própria do canal |
| AU-171 | gatilho padrão de confirmação; endereço não verificado | o endereço abre 4 tickets pelo formulário de visitante em 24 h | 3 confirmações; a 4ª suprimida com evento "limite de endereço não verificado"; os 4 tickets são criados normalmente |
| AU-172 | idem; texto do gatilho com o assunto e o primeiro nome do solicitante | o endereço não verificado abre ticket com assunto "Projetor da sala 12" | a confirmação traz só o número do ticket e o link de convidado; nem o assunto nem o nome digitado aparecem |
| AU-173 | G90/G91 de AU-121; endereço não verificado | ticket criado pelo formulário de visitante qua 2026-11-11 18:30 | G91 casa (fora do horário de C5); sai **uma** confirmação no texto mínimo (número e link de convidado); a etiqueta "fora do horário" é aplicada |
| AU-174 | macro "Aguardando cliente" de AU-130; ag1 com token de escrita | ag1 pede a pré-visualização pela API e depois envia aplicando a macro | a pré-visualização não grava nada; o envio tem o mesmo efeito de AU-131; os eventos registram a macro usada e a origem API (D29) |
| AU-175 | G10 "criado → notificar agentes com escrita no grupo"; ag2 ausente | ana abre ticket no N1 | ag1 e ag2 notificados (D27: ausência não tira dos avisos); os admins não |
| AU-176 | G10 de AU-175; grupo Comercial sem nenhum agente com escrita | ana abre ticket no Comercial | o conjunto fica vazio: os admins recebem a notificação (D27) |

### 9.14 Decisões de 2026-10-29 (intenção, pai, evento, "Quase escalando")

Configuração adicional: idioma da conta PT; ana e cris com idioma PT, bia com
idioma EN. Macro compartilhada **"Atendimento no local"** com variantes PT
("Atendimento no local") e EN ("On-site visit"), texto público com o primeiro
nome do solicitante e o número do ticket. Ticket pai **#1040** (ana, N1,
responsável ag1) com os filhos **#1041** (bia, aberto, sem responsável),
**#1042** (cris, em espera) e **#1043** (dani, fechado depois de vinculado),
todos no N1. Para SL-77 a SL-85: conta EARJ de teste com P3 como política
padrão e calendário C5; grupo **Eventos** com ag2 (escrita) e ag4 (escrita,
ausente); 2026-11-09 e 2026-11-16 são segundas-feiras.

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AU-177 | ticket aberto de bia (EN) | ag1 aplica "Atendimento no local"; troca para a variante PT na pré-visualização; envia | a pré-visualização abre na variante EN, com o primeiro nome de bia e o número do ticket; sai a variante PT; a estatística conta 1 aplicação, na variante PT |
| AU-178 | macro "Aguardando peça" só com a variante PT; ticket de bia (EN) | ag1 aplica | entra a variante PT, com aviso de que falta a variante EN |
| AU-179 | — | ag1 busca "on-site", depois "ATENDIMENTO", depois "Visit" | as três buscas encontram "Atendimento no local" (nome em qualquer idioma, sem maiúsculas nem acentos); não existe filtro por idioma |
| AU-180 | — | admin salva macro com texto só na variante EN; depois uma com variante PT válida e variante EN com variável desconhecida | as duas recusadas: falta a variante do idioma da conta; variável desconhecida, com a indicação da variante e do trecho |
| AU-181 | 3 tickets selecionados numa fila: de ana (PT), cris (PT) e bia (EN) | ag1 aplica em massa "Atendimento no local", editando o texto da variante PT na pré-visualização | a pré-visualização mostra a variante PT e a EN; ana e cris recebem a PT editada, cada uma com o seu nome e número; bia recebe a EN original; 3 operações; estatística +3 |
| AU-182 | pai e filhos da configuração | ag1 aplica no pai "Atendimento no local" e envia a resposta pública, sem mudar o estado | ana recebe PT com "#1040"; bia recebe EN com "#1041"; cris recebe PT com "#1042"; #1043 (fechado) não recebe nada; cada filho tem a resposta registrada como de ag1, marcada "via ticket pai #1040", com a sua passada de gatilhos; estados inalterados (#1042 continua em espera); a estatística conta 1 aplicação |
| AU-183 | idem | ag1 escreve nota interna no pai | nada é gravado nos filhos; nenhuma notificação aos solicitantes |
| AU-184 | idem | ag1 envia resposta pública no pai escolhendo resolvido | pai, #1041 e #1042 resolvidos; ana, bia e cris recebem **um** e-mail cada, com a resposta e **sem** convite de avaliação; nenhum convite em nenhum dos tickets |
| AU-185 | regra "responsável obrigatório" ligada; além dos filhos da configuração, #1046 (Financeiro, sem responsável) vinculado pelo admin | ag1 resolve o pai | #1041 recebe ag1 como responsável e é resolvido; #1042 resolvido; #1046 falha (ag1 sem escrita no Financeiro) e continua como estava; o pai é resolvido; ag1 vê a lista com #1046 e o motivo "responsável obrigatório" |
| AU-186 | #1041 vinculado ao pai aberto | ag1 resolve #1041 sozinho, com resposta pública; depois desvincula; bia responde (reabre); ag1 resolve de novo com resposta pública | 1ª resolução: nenhum convite (vinculado); 2ª: convite enviado normalmente |
| AU-187 | G10 "resposta de agente → etiqueta respondido" | ag1 envia resposta pública no pai (como AU-182) | uma passada no pai e uma em cada filho que recebeu a resposta (#1041, #1042); a etiqueta entra nos três; cada ticket tem o seu registro de execução |
| AU-188 | além da configuração, #1044 (dani, resolvido) vinculado ao pai | ag1 envia resposta pública no pai, sem mudar o estado | #1044 recebe a resposta, marcada "via ticket pai #1040", e **continua resolvido**; #1043 (fechado) não recebe (D46) |
| AU-189 | regra "responsável obrigatório" ligada; filhos da configuração; ag2 com escrita no N1 | ag2 resolve o pai (responsável do pai: ag1) | #1041 recebe **ag2** (quem resolveu) como responsável e é resolvido; #1042, que já tinha responsável, é resolvido sem troca de responsável; nenhum filho falha (D47) |
| SL-77 | qua 2026-11-11 10:00, ticket de evento no Eventos, montagem qua 2026-11-18 08:00, responsável ag2 | o relógio passa | 1ª resposta pela P3 normal (120 min): vence qua 12:00 (15:00Z); sem métrica de resolução (D40); selo em qua 11/11: "faltam 7 dias para a montagem"; avisos a ag2 seg 2026-11-16 07:00 (10:00Z) e qua 2026-11-18 07:00 (10:00Z), uma vez cada |
| SL-78 | ticket de evento com montagem sáb 2026-11-21 09:00 | o relógio passa | aviso de 2 dias úteis: qui 2026-11-19 07:00 (10:00Z); aviso do dia: sábado não tem expediente → sex 2026-11-20 07:00 (10:00Z) |
| SL-79 | ticket de evento criado qua 2026-11-04, montagem seg 2026-11-16 06:30 | o relógio passa | a montagem começa antes da abertura: aviso do dia sex 2026-11-13 07:00 (10:00Z); aviso de 2 dias úteis qui 2026-11-12 07:00 (10:00Z) |
| SL-80 | SL-77 sem responsável | o relógio passa | os avisos vão a ag2 e ag4 (o ausente também recebe, D27), nos mesmos instantes de SL-77 |
| SL-81 | ticket de evento criado ter 2026-11-17 10:00, montagem qua 2026-11-18 08:00 | criação | marca "fora do prazo"; o aviso de 2 dias úteis (seg 16 07:00) já passou e a montagem não começou → sai na criação, ter 10:00 (13:00Z), uma vez (D41); aviso do dia qua 2026-11-18 07:00 (10:00Z) |
| SL-82 | ticket de evento criado sex 2026-11-20 08:00, montagem sex 2026-11-20 10:00 | criação | os dois instantes já passaram: sai só o aviso do dia, às 08:00 (11:00Z) |
| SL-83 | SL-77 depois do aviso de seg 16 07:00 | seg 2026-11-16 10:00, ag2 muda a montagem para qua 2026-11-25 08:00 | o aviso do dia 18 não sai; novos avisos seg 2026-11-23 07:00 (10:00Z) e qua 2026-11-25 07:00 (10:00Z) |
| SL-84 | ticket de evento P3 normal criado qua 2026-11-11 10:00, sem resposta | qua 11:00, ag2 muda o tipo do ticket para tarefa | a 1ª resposta (120 min), que já corria desde a criação (D40), continua com prazo qua 12:00 (15:00Z); o ticket ganha a resolução desde a criação (480 min): qua 420 + qui 60 → qui 2026-11-12 08:00 (11:00Z) (revisto em v0.3, D40) |
| SL-85 | seg 2026-11-09 16:30; tickets P3: A aberto com 1ª resposta vencendo ter 2026-11-10 07:20; B aberto com resolução vencida seg 14:30; C aberto com prazo ter 08:00; D pendente só com a resolução pausada; E de evento, com a 1ª resposta cumprida, sem "pronto" e com montagem seg 18:00 (fim do evento 21:00) | admin abre a fila "Quase escalando" | a fila mostra B, E e A, nessa ordem (prazos seg 14:30, seg 18:00, ter 07:20). A: restam 30 + 20 = 50 min úteis ≤ 60; C: 30 + 60 = 90, fora; D pausado; E: até a montagem restam 30 min úteis (16:30–17:00), sem "pronto" → entra (D40). Selos: A "vence em 14 h 50 min"; B "vencido há 2 h"; C "vence em 15 h 30 min"; D "pausado"; E "falta 1 h para a montagem" (1 h 30 min reais, arredondado para baixo) (revisto em v0.3, D40) |
| SL-86 | #1041 com P0 normal criado ter 2026-11-03 10:00, sem resposta, vinculado a um pai | ag1 envia resposta pública no pai às 11:00; resolve o pai qua 2026-11-04 10:00 | 1ª resposta de #1041 cumprida às 11:00; resolução de #1041 cumprida qua 10:00 (prazo sex 2026-11-06 10:00, como SL-01) |
| SL-87 | P0 normal criado ter 2026-11-03 10:00, sem resposta; ag1 escreve nota e põe em pendente às 10:30 | ag1 olha a fila às 11:00 | selo "vence em 4 h" (1ª resposta, prazo 15:00, que não pausa); não "pausado" |
| SL-88 | ticket de evento no Eventos, evento qua 2026-11-18 09:00–11:00, montagem qua 08:00, sem "pronto", 1ª resposta cumprida | ag2 olha a fila seg 2026-11-16 10:00, ter 2026-11-17 07:00, ter 10:00, qua 07:30, qua 08:30 e qua 11:30 | selos: "faltam 2 dias para a montagem" (46 h); "falta 1 dia para a montagem" (25 h); "faltam 22 h para a montagem"; "falta menos de 1 h para a montagem"; "montagem sem pronto" em vermelho; "evento encerrado" (D40) |
| SL-89 | SL-88, mas ag2 liga "pronto" ter 2026-11-17 15:00 | ag2 olha a fila ter 15:01, qua 08:30 e qua 11:30 | "pronto"; "pronto"; "evento encerrado". O ticket não entra na fila "Quase escalando" pela montagem; nenhuma violação de SLA é registrada (D40, D44) |
| SL-90 | ter 2026-11-17 16:30, tickets de evento no Eventos (C5), todos abertos e com a 1ª resposta cumprida: W sem "pronto", montagem ter 14:00, evento ter 15:00–18:00; X sem "pronto", montagem qua 2026-11-18 07:30; Y sem "pronto", montagem qua 08:30; Z com "pronto", montagem qua 07:00 | admin abre a fila "Quase escalando" | a fila mostra W e depois X. W: montagem iniciada sem "pronto", evento não terminou; X: 30 (ter 16:30–17:00) + 30 (qua 07:00–07:30) = 60 min úteis ≤ 60; Y: 30 + 90 = 120, fora; Z: tem "pronto", fora. Selos: W "montagem sem pronto" (vermelho); X "faltam 15 h para a montagem"; Y "faltam 16 h para a montagem"; Z "pronto" (D40) |
| SL-91 | SL-80 (sem responsável) | ticket de evento criado qua 2026-11-11 15:00 com montagem qui 2026-11-12 14:00 | o instante do aviso de 2 dias úteis (ter 2026-11-10 07:00: qua 11 é o 1º dia útil anterior, ter 10 o 2º) já passou e a montagem não começou → sai na criação, qua 15:00 (18:00Z), a ag2 e ag4, uma vez; aviso do dia qui 2026-11-12 07:00 (10:00Z) (D41) |
| SL-92 | ticket de evento P3 normal criado qua 2026-11-11 10:00, sem resposta, montagem qua 2026-11-25 08:00, responsável ag2 | o relógio passa sem resposta | 1ª resposta: aviso qua 11:00 (14:00Z), violação qua 12:00 (15:00Z), escalonamento a `gestor` 8 h úteis depois, qui 2026-11-12 10:00 (13:00Z); o ticket entra na fila "Quase escalando" às 11:00; o selo continua "faltam 14 dias para a montagem"; nenhuma métrica de resolução (D40) |

---

## 10. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Ordem e condições de gatilhos na criação | documentação (ordem alfabética em 1, numérica em 1, reordenação em 1) | cenário AU-01, AU-03 |
| Reentrada e laço de gatilhos | não documentado em nenhum projeto | cenário AU-02 |
| Macros: atomicidade, histórico, e-mail | documentação (atomicidade em 1) | cenário AU-04 |
| Instantes de prazo, aviso e violação; desempate | documentação parcial | cenário AU-05 |
| Horário comercial, feriado, meia-noite, fuso | documentação parcial; meia-noite não documentada | cenário AU-06 |
| Pausa em pendente | divergente entre projetos | cenário AU-07, T-03 |
| Escalonamento na violação | documentação (só marcar/notificar) | cenário AU-08 |
| Idempotência de tarefas agendadas | não documentada | cenário AU-09, T-04 |
| Auto-resposta e anti-laço | documentação parcial | cenário AU-10, E-09, E-11, E-12 |
| Efeito da reabertura no SLA | divergente | cenário T-03 |
| Em espera, encaminhamento com retorno, pesquisa, aviso absoluto | requisito de cliente (spec 13), sem evidência de runtime dos projetos | — |
| Macro por intenção, cascata do pai, prazo do evento, "Quase escalando" | requisito de cliente (spec 13 Δ34–Δ37) | — |

## 11. Questões abertas para o implementador

- Feriado em calendário noturno (SL-13): o trecho depois da meia-noite pertence
  à data seguinte e cai se essa data for feriado. Isso é simples e explícito,
  mas um turno que começa na véspera do feriado perde a sua segunda metade.
  Confirmar com o produto.
- Ticket liberado da quarentena (spec 02 EM-28): o SLA começa na criação do
  ticket (na liberação), não no recebimento do e-mail. Avaliar se o recebimento
  seria mais justo com o cliente.
- Encaminhamento com retorno mantém a política do grupo de origem (§7.1). É
  a leitura desta spec para "o SLA continua o mesmo" (spec 13 Δ5); confirmar
  com o produto se o grupo de destino deveria impor as próprias metas.
- Valores propostos (aviso de 20 %, lote de 500, limite de 1 e-mail por
  gatilho/ticket/24 h, desativação após 50 falhas, registro de 30 dias) são
  ajustáveis. Registrar mudanças em `docs/decisions.md`.
- As questões da v0.3 sobre a cascata com responsável obrigatório, o aviso
  "no dia" do evento e o evento sem "pronto" foram respondidas pelas decisões
  D47, D41 e D44/D40 e retiradas.
- **Ordem da fila "Quase escalando"** (§7.15): "mais antigos primeiro" foi
  lido como prazo mais antigo primeiro. Confirmar que não é a data de
  criação.
