# Spec 04 — Atribuição e filas

Status: **rascunho v0.2 (2026-10-26)**. Baseado na documentação pública dos 7
projetos e nos requisitos da operação EARJ (spec 13). Evidências de runtime
pendentes, marcadas como **[evidência pendente: cenário]**. Vocabulário: spec
01. Papéis e acesso por grupo: spec 06 (resumo em §2.2). Decisões
transversais: D01–D37. Precedência: spec 13 > decisões transversais > esta
spec.

Mudanças na v0.2:
- Níveis de acesso com o vocabulário da spec 06: **nenhum / leitura /
  escrita** (antes "ler / trabalhar").
- O **admin pode ser responsável** em qualquer grupo, sem associação (D06).
  AS-13 passa a esperar aceite.
- Automação com atribuição inválida: o **gatilho inteiro** falha (D11), não só
  a ação.
- Notificação de fila alinhada a D09 e D12: o público é o dos **agentes ativos
  com escrita no grupo**, nunca o autor; in-app sempre, e-mail conforme a
  preferência. A ausência deixa de tirar o agente desse público; os admins
  recebem o aviso quando esse público fica vazio (D27).
- Estado **em espera** (D18, Δ3) incluído em fila, rodízio, ausência,
  desativação e transferência.
- **Responsável obrigatório para resolver** (Δ4): interação com "responder
  atribui" e com o encaminhamento (§5.6).
- **Encaminhamento com retorno** e **devolver** (Δ5): nova §8 e testes AS-60 a
  AS-73. Para não confundir com "devolver", a antiga "devolver à fila" passa a
  se chamar **liberar**.
- **Atribuição em lote** com os limites da edição em massa (Δ9): até 100
  tickets, ticket a ticket, com relatório de falhas.
- Visões padrão saem desta spec: filas salvas são da spec 08 (e Δ9). Fica aqui
  só a definição da fila do grupo.
- Desativação: as sessões terminam e os tokens ficam **suspensos** enquanto o
  agente estiver desativado (spec 06 §2, D26), em vez de "revogados".
- Questões abertas respondidas pela spec 06 e por D06/D11 foram removidas.
- Ajustes D23–D37: ticket encaminhado com estado único **aberto** e marca
  derivada **"encaminhado"** para a origem, sem "em espera" (D23), com leitura
  para a origem (D24); tokens suspensos na desativação, revogáveis pelo admin
  (D26); público dos avisos de fila com os ausentes e admins só quando o
  público fica vazio (D27); macro de encaminhamento pela API (D29); ordenação
  "na fila há mais tempo" (D32). AS-23, AS-44 e AS-61 ajustados; novos AS-74 a
  AS-79.

---

## 1. Problema

Todo ticket pertence a um grupo e, em algum momento, precisa de um agente que
cuide dele. As regras de atribuição precisam garantir:

1. que **nenhum ticket fique esquecido**: sem responsável e sem ninguém
   avisado, ou com um responsável que não pode trabalhar nele (desativado, sem
   escrita no grupo, ausente);
2. que **dois agentes não peguem o mesmo ticket** sem saber;
3. regras **explícitas e testáveis** para os casos que os projetos analisados
   deixam vagos: troca de grupo, agente desativado, agente ausente, reabertura;
4. que um ticket mandado a **outra equipe volte sozinho** a quem o mandou,
   quando a outra equipe terminar (spec 13 R06);
5. quem pode atribuir quem, de forma coerente com os papéis admin, agente e
   solicitante;
6. notificações suficientes para a fila andar, sem ruído que faça os agentes
   desligarem tudo;
7. uma distribuição automática simples, previsível e segura sob concorrência.

---

## 2. Conceitos

### 2.1 Termos

| Termo | Definição |
|---|---|
| **Grupo** (fila) | Spec 01. No PantherDesk, o grupo **é** a fila: não existe uma entidade de fila separada. A **fila do grupo** é o conjunto dos seus tickets **abertos sem responsável**. Filas salvas com filtro, colunas e ordenação são outra coisa (spec 08, spec 13 Δ9). |
| **Acesso ao grupo** | Nível de um agente num grupo: **nenhum**, **leitura** ou **escrita** (spec 06 §3; resumo em §2.2). |
| **Associação explícita** | Registro de que um agente (ou admin) faz parte do grupo, com data de entrada. Para agentes, é o que dá leitura ou escrita. Para o admin, não muda o acesso (que já é total), mas o inclui no rodízio e nos avisos de fila daquele grupo. |
| **Responsável** | Spec 01. No máximo um por ticket. |
| **Seguidor** | Agente que acompanha o ticket sem ser responsável (spec 13 Δ6; notificações na spec 09). Seguir não atribui. |
| **Pegar** (assumir) | Ação do agente de se tornar responsável por um ticket sem responsável. |
| **Liberar** | Remover o responsável, deixando o ticket na fila do grupo. (Na v0.1, "devolver à fila".) |
| **Transferir** | Mudar o grupo do ticket. |
| **Encaminhar com retorno** | Transferir para outro grupo registrando a **origem** (grupo e agente), para que o ticket volte a ela (§8). |
| **Devolver** | Encerrar um encaminhamento com retorno: o ticket volta ao grupo e ao agente de origem (§8). |
| **Rodízio** | Distribuição automática, por grupo, entre agentes elegíveis (§6). |
| **Disponibilidade** | Estado declarado do agente no perfil: **disponível** ou **ausente** (com data de fim opcional) (spec 13 Δ23). Não é presença online (spec 09). |
| **Agente ativo** | Agente que pode entrar no sistema. O agente **desativado** perde o acesso e mantém o histórico. |
| **Grupo padrão da conta** | Grupo para onde vão os tickets que não teriam grupo válido. Obrigatório; não pode ser desativado. |

### 2.2 Níveis de acesso por grupo (resumo da spec 06)

| Nível | Pode |
|---|---|
| nenhum | nada: o ticket não existe para o agente (404) |
| leitura | ver, buscar, ver histórico; escrever **nota interna**; seguir o ticket |
| escrita | tudo de leitura + responder em público, mudar campos e estado, transferir, encaminhar, devolver, atribuir, **ser responsável** |

O admin tem escrita implícita em todos os grupos e **pode ser responsável** em
qualquer grupo, sem associação (D06).

### 2.3 Invariante do responsável

Em todo ticket que não está fechado nem mesclado, se há responsável, ele é:
**(a)** ativo e **(b)** admin ou agente com **escrita** no grupo do ticket.

- A invariante é verificada no servidor em **toda** gravação que muda
  responsável, grupo, acesso ao grupo, papel ou o estado ativo do agente. Toda
  operação que a violaria é recusada **ou** limpa o responsável, conforme as
  regras das seções abaixo. Nunca fica um ticket aberto com responsável
  inválido.
- Ausência **não** viola a invariante: um agente ausente pode continuar
  responsável pelos tickets que já tinha (§9).
- Tickets fechados e mesclados guardam o último responsável como registro
  histórico e não são alterados.
- Um ticket **resolvido** pode ficar sem responsável (por liberação ou
  desativação) mesmo com a regra do §5.6 ligada: a regra vale para a
  **transição** para resolvido, não para o estado.

---

## 3. Grupos como filas

- Grupos são **planos** no MVP: sem hierarquia e sem herança de acesso.
- Todo ticket tem exatamente um grupo (spec 01). O grupo vem da instância de
  canal (spec 03), da escolha do solicitante no portal (spec 07), da escolha do
  agente ou de automação.
- **Desativar grupo**: recusado enquanto houver ticket aberto, pendente, em
  espera ou resolvido nele, enquanto algum ticket encaminhado tiver esse grupo
  como origem (§8), ou enquanto alguma caixa de entrada, formulário ou widget
  de chat apontar para ele. Automações que o referenciam passam a ser
  inválidas (spec 05). Tickets fechados continuam no grupo desativado.
- Se uma resposta reabriria ou criaria ticket num grupo desativado (spec 01
  §4.4), o ticket vai para o **grupo padrão da conta**, com evento de auditoria
  de origem sistema.
- **Entrada na fila**: o ticket entra na fila quando passa a estar aberto e
  sem responsável (criação, liberação, transferência, encaminhamento,
  reabertura, retorno de pendente ou em espera, ausência, desativação). O
  momento da entrada fica registrado no evento de auditoria.
- Pendente e em espera sem responsável **não** aparecem na fila até a data de
  retorno (spec 01 §4.1). Ao voltar para aberto, entram na fila.
- As listas que o agente usa (meus tickets, sem responsável nos meus grupos,
  em espera nos meus grupos etc.) são filas salvas da spec 08 §9 e da spec 13
  Δ9, inclusive a ordenação **"na fila há mais tempo"** (spec 08 §7, D32),
  que também se aplica à lista de em espera: conta a partir do último momento
  em que o ticket entrou na fila do grupo ou ficou em espera nele.
- Contadores são calculados pelo mesmo filtro de acesso das listas (spec 06):
  um agente nunca vê o número de tickets de um grupo ao qual não tem acesso.

---

## 4. Quem pode atribuir quem

| Ação | Solicitante | Agente com leitura | Agente com escrita no grupo do ticket | Admin | Automação (spec 05) | API (spec 10) |
|---|---|---|---|---|---|---|
| Ver quem é o responsável | não | sim | sim | sim | — | como o dono do token |
| Pegar | não | não | sim (§5.1) | sim | — | como o dono do token |
| Atribuir a outro agente com escrita no grupo, ou a um admin | não | não | sim | sim | sim | como o dono do token |
| Reatribuir (trocar um responsável existente) | não | não | sim | sim | sim | como o dono do token |
| Liberar | não | não | sim | sim | sim | como o dono do token |
| Transferir de grupo | não | não | sim, para qualquer grupo ativo (§7) | sim | sim | como o dono do token |
| Encaminhar com retorno, devolver (§8) | não | não | sim | sim | por macro (spec 05) | como o dono do token |
| Atribuir em lote | não | não | sim, ticket a ticket com as mesmas regras | sim | — | como o dono do token |
| Mudar disponibilidade | — | a própria | a própria | de qualquer agente | não | a própria |

Regras:
- Agente com acesso **nenhum** ao grupo do ticket não vê o ticket (spec 06:
  404), portanto não executa nenhuma ação sobre ele. Com leitura, a tentativa
  de atribuir recebe 403 (D05).
- O **alvo** de uma atribuição precisa satisfazer a invariante (§2.3) e estar
  **disponível** (§9). Se não satisfizer, a ação é recusada com erro de
  validação (422) que indica o motivo, e nada é gravado.
- Exceção: um agente ausente pode **pegar** um ticket para si (§9).
- Uma ação de atribuição de automação que viola essas regras é uma **falha da
  ação**: o gatilho é atômico, então **nenhuma** ação daquele gatilho é
  aplicada, o erro é registrado na execução da regra e os gatilhos seguintes
  continuam. A operação original nunca é desfeita (D11; detalhe na spec 05).
- **Atribuição em lote** (edição em massa, spec 13 Δ9): até 100 tickets por
  vez. Cada ticket é processado sozinho, com as mesmas validações e os mesmos
  eventos de uma atribuição individual; o resultado informa quantos foram
  alterados e quais falharam, com o motivo. Uma falha não impede os outros.
- O solicitante nunca vê nem muda o responsável ou o grupo. No portal ele vê os
  autores das mensagens públicas, mas não quem é o responsável.
- Toda mudança de responsável ou de grupo gera **evento de auditoria** com
  antes, depois e origem (spec 01 §7): agente (o admin aparece como origem
  agente, com o ator registrado), sistema (com o motivo, ex.: rodízio,
  desativação, ausência, retorno de encaminhamento), automação (com a regra) ou
  API (com o token).

---

## 5. Atribuição manual

### 5.1 Pegar
- Só é aceito se o ticket está **sem responsável** no momento da gravação. Se
  outro agente pegou antes, a ação é recusada com **conflito** (409) e o
  ticket mostra quem pegou. Duas tentativas simultâneas: exatamente uma vence.
- Ticket com responsável não é "pego": o agente usa **reatribuir para mim**,
  que é uma reatribuição comum (§5.2) e notifica o responsável anterior.
- **Abrir** ou ler um ticket nunca atribui. Seguir um ticket também não.

### 5.2 Atribuir e reatribuir
- Atribuir a si mesmo ou a outro agente com escrita no grupo (ou a um admin),
  disponível.
- Reatribuir troca o responsável. A última gravação vence, com evento de
  auditoria. A API aceita, opcionalmente, o responsável esperado; se não
  coincidir com o atual, recusa com conflito (409).
- Mudar o responsável é mudança de campo: aumenta a versão do ticket e, na
  interface, é enviada com a versão (D01).
- Atribuir não muda o estado do ticket.

### 5.3 Liberar
- Remove o responsável. O ticket volta à fila do grupo se estiver aberto.
- Notifica o grupo (§11). **Não** dispara o rodízio (§6.3), para evitar que o
  ticket volte para o mesmo agente ou fique pulando de um agente para outro.

### 5.4 Responder atribui
- Opção **por grupo**, **ligada por padrão**: quando um agente com escrita (ou
  um admin) envia uma **resposta pública** num ticket **sem responsável**, ele
  se torna o responsável na mesma transação.
- Nota interna não atribui. Resposta de automação não atribui. Resposta do
  agente a partir de um e-mail de notificação só atribui se virar resposta
  pública (D02).
- Se o ticket já tem responsável, responder não muda o responsável.

### 5.5 Estados
- Tickets **fechados** e **mesclados** não aceitam mudança de responsável nem
  de grupo (spec 01: fechado é somente leitura para campos).
- Tickets **resolvidos**, **pendentes** e **em espera** aceitam atribuição e
  transferência. O estado não muda com elas.

### 5.6 Responsável obrigatório para resolver (spec 13 Δ4)
- Configuração por conta (desligada por padrão no produto; **ligada** na
  EARJ). Ligada, a transição para **resolvido** exige responsável; sem ele, o
  envio inteiro é recusado (422) com a indicação do campo, e o rascunho é
  preservado (D01).
- A validação roda **depois** das atribuições do próprio envio:
  - "responder atribui" (§5.4): resposta pública + resolver num ticket sem
    responsável atribui quem respondeu e então resolve;
  - macro que atribui alguém e resolve (spec 05, spec 13 ER-19).
- Ir de resolvido para fechado (manual ou automático) não exige responsável.
- "Resolver" um ticket encaminhado com retorno vira **devolver** (§8.3) e o
  resultado é aberto, então essa regra não se aplica a ele.

---

## 6. Rodízio

### 6.1 Decisão: MVP, opcional por grupo, desligado por padrão

O rodízio entra no MVP na forma mais simples: **rodízio puro**, sem carga, sem
capacidade e sem habilidades. Motivos:
- Dois dos sete projetos têm rodízio nativo, e a falta dele costuma ser suprida
  com regras fixas que concentram tickets numa pessoa.
- Na forma simples, o custo é baixo: um ponteiro por grupo e uma lista de
  elegíveis. O comportamento é fácil de explicar e de testar.
- Os riscos conhecidos (atribuir a quem não está trabalhando, forçar a
  atribuição quando ninguém pode) são resolvidos por duas regras: só conta
  quem está **disponível**, e **sem elegível o ticket fica na fila**.
- Fica **desligado por padrão** porque muitas equipes pequenas preferem que os
  agentes peguem tickets da fila. O admin liga por grupo. Na EARJ fica
  desligado (spec 13 R51).

### 6.2 Elegibilidade
Um agente é elegível no grupo quando é, ao mesmo tempo: ativo; associado ao
grupo com **escrita** (o admin, só com associação explícita); **disponível**; e
**participante do rodízio** naquele grupo (marca por associação, padrão sim; o
admin pode tirar, por exemplo, o líder).

### 6.3 Quando roda
O rodízio roda quando um ticket **fica aberto e sem responsável** num grupo com
rodízio ligado, por um destes eventos de **ticket individual**:

| Evento | Roda? |
|---|---|
| Criação, por qualquer canal, depois das automações de criação | sim |
| Transferência que deixou o ticket sem responsável (§7) | sim, no grupo de destino |
| Encaminhamento com retorno (§8) | sim, no grupo de destino |
| Retorno de encaminhamento sem responsável (§8.3) | sim, no grupo de origem |
| Reabertura sem responsável (spec 01 §4.5) | sim |
| Retorno de pendente ou de em espera sem responsável (data de retorno, resposta do solicitante, resposta numa conversa paralela) | sim |
| Solicitante responde com responsável ausente (§9) | sim |
| Liberação manual (§5.3) | **não** |
| Desativação de agente ou perda de escrita no grupo (§10) | **não**: são operações em lote; o admin redistribui |
| Atribuição em lote (§4) | **não** |

Se uma automação de criação já atribuiu um responsável, o rodízio não roda.

### 6.4 Escolha
- Os elegíveis são ordenados por uma chave estável: o momento da associação ao
  grupo (desempate pelo identificador interno).
- O grupo guarda o **ponteiro**: a chave do último agente escolhido. O próximo
  é o primeiro elegível com chave maior que o ponteiro; depois do último, volta
  ao começo.
- Se o agente do ponteiro saiu do grupo ou ficou inelegível, a regra continua
  valendo, porque o ponteiro é a chave e não a pessoa.
- Escolha e atualização do ponteiro acontecem na mesma transação da
  atribuição, com o ponteiro do grupo travado: tickets simultâneos nunca caem
  no mesmo agente por corrida.
- **Sem elegível**: o ticket fica **sem responsável**, na fila, e o grupo é
  notificado (§11). Não se força a atribuição.
- O rodízio não olha carga: um agente com 40 tickets recebe a vez igual a um
  com 2. Isso é aceito no MVP e tratado no roadmap (§12).
- Atribuição por rodízio gera evento com origem sistema, motivo "rodízio", e
  notifica só o novo responsável.

---

## 7. Transferência de grupo

Regra única, aplicada a toda transferência (agente, admin, automação, API):

| Situação do responsável atual | Efeito no responsável |
|---|---|
| Sem responsável | continua sem responsável; rodízio do destino, se ligado |
| Responsável é admin, ou agente com escrita no grupo de destino | **mantido** |
| Responsável não tem escrita no destino | **limpo**; rodízio do destino, se ligado |
| A transferência informa um novo responsável | o novo responsável precisa satisfazer a invariante no destino; senão a transferência inteira é recusada |

- Grupo e responsável mudam na **mesma transação**, com um evento de auditoria
  para cada campo.
- O destino precisa estar **ativo**. Transferir para o próprio grupo não faz
  nada e não gera evento.
- Quem transfere precisa de **escrita** no grupo de **origem**. Não precisa de
  acesso ao destino (spec 06 §3). Se não tiver acesso ao destino, perde o
  acesso ao ticket a partir desse momento e a resposta da ação informa isso.
- Estado, participantes, seguidores, etiquetas e mensagens não mudam. A
  política de resposta em ticket fechado passa a ser a do grupo de destino
  (spec 01 §4.4). O efeito no SLA é definido na spec 05.
- Transferir um ticket que está **encaminhado com retorno** cancela o retorno
  (§8.4).
- Notificações em §11.

---

## 8. Encaminhamento com retorno (spec 13 Δ5)

Recurso nativo para "mando para outra equipe e o ticket volta para mim".

### 8.1 Encaminhar
- Quem tem escrita no grupo atual (ou é admin) escolhe **encaminhar para o
  grupo X com retorno** e escreve uma **nota interna obrigatória**. Sem nota,
  recusado (422).
- X precisa estar ativo e ser diferente do grupo atual.
- Efeito, numa transação:
  1. o grupo passa a ser X e o ticket fica **sem responsável** (o rodízio de X
     roda, se ligado);
  2. o estado passa a **aberto** (é trabalho da equipe X);
  3. o ticket registra a **origem do encaminhamento**: grupo e agente que
     encaminhou;
  4. a nota interna é gravada; os eventos de auditoria registram grupo,
     responsável, estado e origem.
- Enquanto a origem estiver registrada:
  - o ticket aparece com o indicador "encaminhado por {agente} de {grupo}"
    nas listas dos **dois** grupos;
  - o ticket tem **um único estado**, **aberto**, no grupo X (D23). Para o
    grupo de origem, ele aparece com a marca derivada **"encaminhado"**,
    calculada a partir da origem registrada: não é um estado, aparece nas
    filas e pode ser usada em filtros (spec 08). Não existe "em espera" para
    o grupo de origem;
  - os agentes com leitura ou escrita no grupo de origem, e o agente de
    origem, têm **leitura** no ticket (ver, seguir, nota interna), mesmo sem
    acesso a X, até o retorno ou o cancelamento (D24);
  - o SLA continua o mesmo, sem reiniciar; o tempo em X conta para o
    relatório de X (spec 11, fato por grupo no momento do evento);
  - os agentes de X podem trabalhar o ticket normalmente (pegar, responder,
    pendente, em espera, conversa paralela).
- **Um nível** no MVP: um ticket com origem registrada não pode ser
  encaminhado com retorno de novo antes de voltar (422).

### 8.2 Devolver
- Quem tem escrita em X (ou é admin) usa **devolver**, com nota interna
  obrigatória.
- Efeito, numa transação: o ticket volta ao grupo de origem, com o **agente de
  origem como responsável**, no estado **aberto**, e a origem é limpa. O
  agente de origem é notificado.
- Se o agente de origem estiver **desativado**, **sem escrita** no grupo de
  origem ou **ausente**, o ticket volta **sem responsável**, na fila do grupo
  de origem (rodízio, se ligado), e o grupo é avisado. O agente ausente recebe
  o aviso de que o ticket voltou.

### 8.3 Resolver dentro de X
- Enquanto a origem estiver registrada, "resolver" equivale a **devolver**: o
  ticket volta ao grupo de origem com o agente de origem, no estado
  **aberto**, com a nota interna "resolvido pela equipe {X}".
- Não há resolução para o solicitante: nenhum e-mail de resolução e nenhum
  convite de pesquisa (spec 13 Δ15). Uma resposta pública enviada no mesmo
  envio sai normalmente, como resposta.
- **Fechar** diretamente um ticket com origem registrada é recusado (422):
  quem fecha para o solicitante é o técnico de origem.

### 8.4 Cancelamento
- **Transferir** o ticket de forma normal (§7), por qualquer pessoa ou
  automação, **cancela** o retorno: a origem é limpa e o agente de origem é
  avisado. Isso vale também para transferir de volta ao grupo de origem sem
  usar "devolver".
- Mesclar o ticket ou marcá-lo como spam também limpa a origem, com o mesmo
  aviso.
- Com a origem limpa, o acesso derivado do §8.1 deixa de existir.

### 8.5 Macros
Macros podem encaminhar com retorno e devolver (spec 13 Δ10), com as mesmas
regras; a nota interna da macro conta como a nota obrigatória. Isso vale também
para a macro aplicada pela API (D29): mesmas regras da interface, e o evento
registra a macro usada.

---

## 9. Agente ausente

- O agente marca-se **ausente** no perfil, com data e hora de fim opcional, no
  seu fuso. O admin pode marcar ou desmarcar qualquer agente.
- Na data de fim, volta a **disponível** automaticamente. A tarefa é idempotente.
- Efeitos enquanto ausente:
  1. não é elegível ao rodízio;
  2. não pode ser escolhido como responsável por **outros** agentes, por
     automações, pela API nem pelo retorno de encaminhamento: recusa com o
     motivo "agente ausente até {data}";
  3. **pode** pegar ou atribuir tickets **para si**, se resolver trabalhar;
  4. continua responsável pelos tickets que já tinha: a ausência não esvazia a
     carteira, porque costuma ser curta e a devolução em massa cria ruído;
  5. quando o solicitante ou um participante envia **resposta pública** num
     ticket cujo responsável está ausente, o ticket **volta para a fila** (o
     responsável é limpo), o grupo é notificado e o rodízio roda, se ligado.
     O mesmo vale quando um ticket pendente ou em espera dele chega à data de
     retorno. O ausente recebe uma notificação de que o ticket foi liberado;
  6. continua no público dos avisos de fila do grupo (D09): recebe no app e,
     por e-mail, conforme a preferência dele (§11).
- Mostrar a ausência: a lista de possíveis responsáveis mostra o ausente marcado
  e desabilitado.

---

## 10. Agente desativado e perda de escrita

### 10.1 Desativação
- Antes de confirmar, o admin vê quantos tickets abertos, pendentes, em espera
  e resolvidos o agente tem, por grupo, e pode escolher, **por grupo**, um
  agente de destino para reatribuí-los em lote. O destino precisa satisfazer a
  invariante e estar disponível.
- Ao desativar, na mesma transação:
  1. o agente perde o acesso: as sessões terminam e os tokens dele ficam
     **suspensos** enquanto estiver desativado (spec 06 §2, spec 10, D26). O
     admin pode revogá-los;
  2. cada ticket aberto, pendente, em espera ou resolvido dele vai para o
     destino escolhido para aquele grupo ou, sem destino, fica **sem
     responsável**, na fila do grupo;
  3. cada mudança gera evento de auditoria de origem agente (o admin), com o
     motivo "desativação de agente".
- Tickets encaminhados com retorno cuja origem é esse agente: a origem
  continua registrada; no retorno, vale o §8.2 (volta sem responsável).
- Notificação: **uma** notificação resumida por grupo afetado ("N tickets
  voltaram para a fila"), não uma por ticket. Cada destino escolhido recebe uma
  notificação resumida.
- O rodízio não roda (§6.3).
- Tickets fechados e mesclados mantêm o agente como responsável histórico.
- O agente desativado continua aparecendo como autor das suas mensagens e
  ainda pode ser encontrado na busca, marcado como inativo. Não aparece em
  nenhuma lista de atribuição.
- Reativar o agente não devolve os tickets. Os tokens suspensos (e não
  revogados) voltam a valer.
- Reabertura de ticket cujo responsável foi desativado: sem responsável (spec
  01 §4.5).

### 10.2 Perda de escrita no grupo
- Saída do grupo ou rebaixamento de escrita para leitura: mesmo tratamento da
  desativação, restrito aos tickets daquele grupo. O admin vê a contagem, pode
  escolher destino, e os tickets restantes ficam sem responsável. Isso decorre
  da invariante (§2.3).

---

## 11. Notificações

Público de grupo: "o grupo" é sempre o conjunto dos **agentes ativos com
escrita no grupo** (associação explícita; admins só se associados),
**inclusive os marcados como ausentes**, menos o autor da ação (D09, D12,
D27). A ausência afeta só a distribuição automática, não os avisos. A notificação in-app é sempre gerada; o e-mail segue
a preferência de cada agente (spec 09 §8).

| Evento | Quem recebe |
|---|---|
| Ticket criado **sem responsável** (depois das automações e do rodízio) | o grupo |
| Ticket criado **com responsável** | só o responsável, exceto se ele mesmo criou. O grupo **não** é avisado |
| Ticket entra na fila por liberação, transferência, encaminhamento, reabertura, retorno de pendente ou em espera, ausência ou retorno de encaminhamento sem responsável | o grupo em que o ticket está |
| Atribuição ou reatribuição | o novo responsável, exceto se ele mesmo fez a ação; o anterior, se outra pessoa o tirou |
| Transferência de grupo | o responsável anterior, se foi limpo; o responsável mantido, se outra pessoa transferiu; o grupo de destino, se o ticket chegou sem responsável |
| Encaminhamento com retorno | o grupo X (ticket na fila); o responsável anterior, se não foi ele quem encaminhou |
| Devolução ou resolução dentro de X | o agente de origem, que volta como responsável; sem ele, o grupo de origem |
| Retorno cancelado (§8.4) | o agente de origem, exceto se ele mesmo cancelou |
| Resposta pública do solicitante ou de participante | o responsável; sem responsável, o grupo |
| Desativação ou perda de escrita | resumo por grupo (§10) |

Regras:
- **Público vazio**: se o público de grupo ficar vazio (ninguém ativo com
  escrita no grupo além do autor), o aviso vai aos **admins** da conta, menos
  o autor (D27). Ausentes contam no público: um grupo só com ausentes avisa os
  ausentes, não os admins. Nenhum ticket entra na fila sem alguém avisado.
- **Nunca** notificar o autor da própria ação (D12).
- **Uma notificação por pessoa por evento**, mesmo que ela se encaixe em mais de
  uma linha, inclusive somando as notificações de seguidor e de menção da
  spec 09.
- Agentes desativados nunca recebem notificações. Quem não pode mais ver o
  ticket não recebe notificação dele.
- Preferências por agente: por tipo de evento, e-mail ligado ou desligado; o
  agente pode desligar o **e-mail** dos avisos de fila de um grupo. O in-app
  não é desligável.
- Os tipos usados aqui correspondem aos da spec 09 §7.1: "atribuído a você",
  "resposta no seu ticket" e "ticket sem responsável no seu grupo" (este último
  também para a entrada na fila e para a resposta em ticket sem responsável,
  com o motivo).
- Seguidores (spec 13 Δ6) e menções (Δ7) são tratados na spec 09.
- Notificação não é Mensagem: não aparece na conversa. O fato que a causou está
  na auditoria.
- E-mails de notificação seguem a spec 02 (§6: `Auto-Submitted:
  auto-generated`; §5: o agente pode responder a partir deles, o que gera nota
  interna por padrão, D02). A entrega in-app em tempo real segue a spec 09.
- Lembretes de "ticket sem responsável há X minutos" e escalonamentos são
  automações (spec 05), não regras desta spec.

---

## 12. Roadmap (fora do MVP)

| Item | Comportamento esperado | Costura no MVP |
|---|---|---|
| Distribuição por carga | escolhe o elegível com menos tickets abertos (não pendentes nem em espera) no grupo; desempate pelo rodízio | elegibilidade e ponteiro já isolados como passo próprio |
| Capacidade por agente | elegível só abaixo de N tickets abertos; todos no limite → fica na fila (spec 13 R51) | idem |
| Limite por janela | no máximo N atribuições por agente por hora | evento de auditoria de rodízio permite contar |
| Presença online | elegível só com presença ativa (spec 09), com regra explícita de "offline após N minutos sem sinal" | disponibilidade já é um conceito separado da presença |
| Habilidades | condição por etiqueta ou campo restringe os elegíveis | — |
| Sugestão de responsável por IA | sugere um responsável; o agente confirma (spec 13 §6) | atribuição já é uma ação explícita, com auditoria |
| Devolução por inatividade | responsável sem ação no ticket por N horas úteis → volta à fila | é uma automação agendada (spec 05) |
| Substituto na ausência | um colega indicado recebe os avisos dos tickets do ausente | notificações já calculadas por evento |
| Encaminhamento em mais de um nível | X encaminha para Y com retorno, e o ticket volta a X e depois à origem | a origem já é um registro próprio do ticket |
| Consulta sem transferir | dar a outro grupo leitura e nota interna num ticket, sem mudar o grupo | níveis leitura/escrita já separados; o acesso derivado do §8.1 já existe |
| Grupos hierárquicos | grupos dentro de grupos, sem herança implícita de acesso | grupo tem identidade própria, sem nome composto |
| Visão "só os meus" | agente que só vê os tickets de que é responsável | filtro de acesso numa única camada (spec 06) |

---

## 13. Abordagens comparadas

### 13.1 Por projeto (segundo a documentação pública)

| Projeto | Abordagem | Prós | Contras |
|---|---|---|---|
| Zammad | Um grupo por ticket, grupos aninháveis sem herança. Quem abre um ticket sem dono vira dono (configurável). Prazo de inatividade devolve à fila. Ausência com substituto, que só redireciona avisos. Reabertura mantém o dono, por padrão. | Grupo único é simples; prazo de inatividade evita tickets presos | Abrir para ler já atribui; a ausência não impede atribuir; efeito da troca de grupo não documentado |
| Chatwoot | Caixas e times; rodízio ligado por padrão entre disponíveis; sem disponível, fica sem dono. Na troca de time, limpa o dono que não é membro. Agente excluído deixa conversas sem dono, sem redistribuir. | Regras explícitas para troca de time e para "ninguém disponível" | Contradição sobre ficar offline sozinho; recursos de carga e capacidade só na edição paga |
| FreeScout | Caixa compartilhada por departamento; atribuição manual; ausência por módulo impede atribuição manual, e resposta do cliente a um ausente limpa o dono; exclusão por API com mapa de novo dono. | Ausência com efeito real; mapa de destino na exclusão | Trava da ausência não vale para API e automações; sem rodízio; times só pagos |
| osTicket | Departamentos hierárquicos e times; atribuição ao responder; reaberto volta ao último que respondeu; férias tiram o agente das listas e dos alertas; matriz de alertas detalhada. | Atribuir ao responder; alertas evitam ruído (atribuído não avisa o departamento) | Efeito da transferência no dono não documentado; permissões de atribuição muito fragmentadas |
| Znuny | Fila ligada a grupo de permissão; bloqueio separado do dono; abrir a resposta bloqueia; desbloqueio por prazo em horário comercial; modelo de puxar. | Sinaliza claramente "alguém está trabalhando nisto" | Dois conceitos (dono e bloqueio) confundem; ticket desbloqueado com dono é ambíguo |
| UVdesk | Grupos com times internos; atribuição manual por privilégio; automações atribuem. | Simples | Efeito de desativação e de troca de grupo não documentado; sem rodízio |
| Frappe Helpdesk | Times com regra de atribuição gerada automaticamente; rodízio ou por carga; troca de time reatribui no novo time; opção de restringir atribuição a membros. | Distribuição automática pronta; carga simples | Contradição sobre atribuir quando todos estão indisponíveis; atribuir fora do time é possível por padrão |

### 13.2 Escolhas do PantherDesk

| Tema | Abordagens observadas | Escolha e motivo |
|---|---|---|
| Unidade de fila | grupo / caixa + time / departamento + time / fila + grupo de permissão | grupo plano = fila: uma dimensão só, coerente com a spec 01 |
| Dono × bloqueio | dono só (6) / dono + bloqueio (1) | só responsável; colisão é tratada por presença (spec 09) |
| Atribuição implícita | ao abrir (1) / ao responder (1) / nenhuma (5) | ao responder, por grupo, ligada: abrir para ler não deve atribuir |
| Rodízio | nativo (2) / ausente (5) | MVP, rodízio puro, opcional e desligado; sem elegível fica na fila |
| Troca de grupo | limpa se não for membro (1) / reatribui no destino (1) / não documentado (5) | mantém se tiver escrita no destino, senão limpa; rodízio do destino |
| Encaminhar e voltar | não documentado como recurso nativo; a operação EARJ simula com regras e etiquetas (spec 13 R06) | nativo, um nível, com origem registrada, leitura para a origem e volta ao agente de origem |
| Desativação | sem dono (1) / mapa de destino (1) / não documentado (5) | devolve à fila com opção de destino por grupo, aviso resumido |
| Ausência | só avisos (1) / impede atribuição (2) / pulado no rodízio (2) | impede atribuição por terceiros, pula no rodízio, libera o ticket quando o cliente responde |
| Avisos | matriz por evento e escopo (2) / por caixa (1) / mínimo (outros) | matriz curta por evento; atribuído não avisa o grupo; ausentes continuam avisados; admins quando o público fica vazio |
| Quem atribui | permissões separadas (1) / por privilégio (1) / membro (outros) | quem tem escrita no grupo atribui; o alvo precisa ter escrita (ou ser admin) |

---

## 14. Casos de teste (critérios de aceite)

Atores: `ag1` e `ag2` (agentes com escrita no grupo N1), `ag3` (escrita no
Financeiro), `admin` (sem associação a grupos, salvo indicação), solicitantes
`ana` e `bia` (org. Acme) e `cris` (sem org.). Grupos ativos N1, Financeiro e
Comercial. Rodízio desligado, "responder atribui" ligado e "responsável
obrigatório para resolver" desligado, salvo indicação.

### 14.1 Fila e atribuição manual
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AS-01 | — | ana envia e-mail novo para a caixa do N1 | ticket aberto no N1, sem responsável, na fila do N1; ag1 e ag2 notificados; ag3 não é notificado e não vê o ticket nem o contador |
| AS-02 | ticket na fila do N1 | ag1 pega | responsável ag1; evento com antes=vazio, depois=ag1, origem agente; o ticket sai da fila |
| AS-03 | ticket na fila do N1 | ag1 e ag2 pegam ao mesmo tempo | exatamente um vence; o outro recebe conflito (409); um único evento de atribuição |
| AS-04 | ticket do N1 sem responsável | ag1 atribui a ag3 | recusado (422): ag3 não tem escrita no N1; nada gravado |
| AS-05 | ticket do N1 com responsável ag1 | ag2 reatribui para si | responsável ag2; ag1 notificado; evento registrado |
| AS-06 | ticket do N1 com responsável ag1 | ag1 libera | sem responsável; ag2 notificado; ag1 não; o rodízio não roda mesmo se ligado |
| AS-07 | ticket do N1 sem responsável | ag1 abre e lê o ticket | continua sem responsável |
| AS-08 | ticket do N1 sem responsável | ag1 escreve nota interna | continua sem responsável |
| AS-09 | ticket do N1 sem responsável | ag1 envia resposta pública | responsável ag1, na mesma transação da mensagem |
| AS-10 | "responder atribui" desligado no N1 | ag1 envia resposta pública num ticket sem responsável | continua sem responsável |
| AS-11 | ana é solicitante do ticket | ana tenta mudar o responsável pela API | recusado; ana não vê o responsável no portal nem na API |
| AS-12 | ag3 recebe acesso de leitura ao N1 | ag3 tenta pegar um ticket do N1 | recusado (403); ag3 consegue escrever nota interna |
| AS-13 | admin não é associado ao N1 | admin atribui ticket do N1 a ag2; depois atribui a si mesmo | as duas ações aceitas; responsável final admin (D06) |
| AS-14 | ticket fechado com responsável ag1 | ag2 tenta reatribuir | recusado; nada gravado |
| AS-15 | "responsável obrigatório para resolver" ligado; ticket do N1 sem responsável | ag1 envia resposta pública escolhendo o estado resolvido | responsável ag1 ("responder atribui") e estado resolvido, no mesmo envio |
| AS-16 | idem, com "responder atribui" desligado | ag1 envia resposta pública escolhendo resolvido | envio inteiro recusado (422) indicando o responsável; nenhuma mensagem gravada; rascunho preservado |
| AS-17 | ticket em espera do N1, responsável ag1 | ag2 reatribui para si | aceito; responsável ag2; estado continua em espera |
| AS-18 | 4 tickets selecionados: 3 abertos do N1 e 1 fechado | ag1 atribui em lote a ag2 | 3 atribuídos a ag2, cada um com seu evento; 1 falha (ticket fechado) listada com o motivo |
| AS-19 | 101 tickets selecionados | ag1 atribui em lote | recusado: no máximo 100 por vez; nada gravado |

### 14.2 Rodízio
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AS-20 | rodízio ligado no N1, ponteiro vazio; ag1 entrou no grupo antes de ag2 | 6 tickets criados em sequência | responsáveis ag1, ag2, ag1, ag2, ag1, ag2; só o responsável de cada um é notificado |
| AS-21 | idem | 6 tickets criados em paralelo | 3 para ag1 e 3 para ag2; nenhum ticket com dois eventos de rodízio |
| AS-22 | rodízio ligado; ag2 ausente | 3 tickets criados | os 3 para ag1 |
| AS-23 | rodízio ligado; ag1 e ag2 ausentes | 1 ticket criado | sem responsável, na fila; ag1 e ag2 recebem o aviso no app (continuam no público, D27); os admins **não** recebem, porque o público não está vazio |
| AS-24 | rodízio ligado; ag2 fora do rodízio por decisão do admin | 2 tickets criados | os 2 para ag1 |
| AS-25 | rodízio ligado; automação de criação atribui a ag2 tickets com assunto "VIP" | ticket "VIP" criado | responsável ag2 pela automação; o ponteiro do rodízio não avança |
| AS-26 | rodízio ligado; ponteiro em ag2 (último escolhido) | ag2 sai do N1; 1 ticket criado | responsável ag1 (o rodízio volta ao começo) |
| AS-27 | rodízio ligado no N1; admin sem associação | 2 tickets criados | ag1 e ag2; o admin nunca é escolhido |
| AS-28 | rodízio ligado; ticket em espera do N1 sem responsável, com data de retorno hoje 10:00 | a tarefa roda às 10:00 | estado aberto; o rodízio atribui ao próximo elegível |

### 14.3 Transferência
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AS-30 | ticket do N1 com responsável ag1 | ag1 transfere para o Financeiro | grupo Financeiro; responsável limpo; dois eventos na mesma transação; ag3 notificado (chegou sem responsável); ag1 perde o acesso ao ticket e a resposta da ação informa isso |
| AS-31 | ag1 também tem escrita no Financeiro | ag2 transfere o ticket de ag1 para o Financeiro | responsável ag1 mantido; ag1 notificado da transferência; ag3 não é notificado |
| AS-32 | ticket do N1 | ag1 transfere para o Financeiro informando responsável ag2 | recusado inteiro (ag2 não tem escrita no Financeiro); grupo e responsável inalterados |
| AS-33 | rodízio ligado no Financeiro | ag1 transfere ticket com responsável ag1 para o Financeiro | responsável ag3 pelo rodízio; ag3 notificado como responsável, sem aviso de fila |
| AS-34 | ticket fechado no N1 | ag1 tenta transferir | recusado |
| AS-35 | grupo "Antigo" desativado | ag1 tenta transferir para "Antigo" | recusado |
| AS-36 | ticket transferido para o Financeiro, depois fechado; política do Financeiro = `novo` | ana responde | ticket novo vinculado, no Financeiro (vale a política do grupo atual) |
| AS-37 | ag3 com leitura no N1 | ag3 tenta transferir um ticket do N1 | recusado (403); nada gravado |
| AS-38 | ticket pendente do N1 com responsável ag1 | ag1 transfere para o Financeiro | estado continua pendente; responsável limpo |

### 14.4 Ausência, desativação e reabertura
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AS-40 | ag2 ausente até amanhã | ag1 tenta atribuir um ticket a ag2 | recusado com o motivo "agente ausente" e a data |
| AS-41 | ag2 ausente | ag2 pega um ticket da fila para si | aceito |
| AS-42 | ag2 ausente, responsável por ticket pendente de ana | ana responde por e-mail | estado aberto (spec 01); responsável limpo; ag1 notificado (fila); ag2 recebe uma única notificação (ticket liberado a partir dele); evento com origem sistema, motivo "ausência" |
| AS-43 | ag2 ausente até 10:00 | a tarefa de fim de ausência roda às 10:00 e de novo às 10:01 | ag2 disponível; um único evento |
| AS-44 | ag1 responsável por 3 tickets abertos e 1 fechado no N1 | admin desativa ag1 sem destino | os 3 ficam sem responsável na fila; o fechado mantém ag1; uma única notificação resumida ao N1 (para ag2); ag1 sem acesso e com os tokens suspensos (não revogados) |
| AS-45 | idem | admin desativa ag1 com destino ag2 para o N1 | os 3 passam para ag2; ag2 recebe uma notificação resumida; os eventos têm motivo "desativação de agente" |
| AS-46 | ag1 desativado | qualquer agente abre a lista de possíveis responsáveis | ag1 não aparece; nas mensagens antigas ag1 aparece como autor, marcado inativo |
| AS-47 | ag1 responsável por 2 tickets abertos no N1 | admin muda ag1 para leitura no N1 | os 2 ficam sem responsável; ag2 notificado com resumo |
| AS-48 | ticket resolvido, responsável ag1 ativo e com escrita | ana responde | reabre com responsável ag1 (spec 01 §4.5); ag1 notificado da resposta |
| AS-49 | ticket fechado (política `reabrir`), responsável ag2 desativado; rodízio ligado no N1 | ana responde | reabre; o rodízio atribui a ag1 |
| AS-55 | ag2 ausente, responsável por ticket em espera com data de retorno hoje 14:00 | a tarefa roda às 14:00 | estado aberto; responsável limpo; ag1 notificado (fila); ag2 notificado da liberação |

### 14.5 Notificações
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AS-50 | — | ag1 cria ticket para cris no N1, com responsável ag1 | nenhuma notificação (ag1 é o autor); ag2 não é avisado |
| AS-51 | — | ag1 cria ticket para cris no N1, com responsável ag2 | só ag2 é notificado |
| AS-52 | ticket sem responsável no N1 | bia (participante) responde | ag1 e ag2 notificados uma única vez cada |
| AS-53 | ag2 desligou o e-mail dos avisos de fila do N1 | ticket novo sem responsável no N1 | ag1 e ag2 notificados no app; só ag1 recebe e-mail (se o dele estiver ligado); quando ag2 for atribuído depois, recebe o aviso de atribuição |
| AS-54 | ag1 com e-mail de notificação ligado | ag1 é atribuído por ag2 | o e-mail sai com `Auto-Submitted: auto-generated` e a notificação in-app aparece |
| AS-56 | grupo Comercial só com ag3 em leitura (ninguém com escrita) | ticket novo sem responsável no Comercial | ag3 não é notificado; os admins recebem o aviso |
| AS-57 | ag2 segue um ticket do N1 sem responsável | ana responde | ag2 recebe uma única notificação, mesmo estando no público de grupo e entre os seguidores |

### 14.6 Encaminhamento com retorno
Dado comum: ticket #1200 de ana, aberto no N1, responsável ag1, prazo de
resolução do SLA fixado; ag2 sem acesso ao Financeiro.

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AS-60 | #1200 | ag1 encaminha com retorno para o Financeiro, com nota | grupo Financeiro, sem responsável, estado aberto; origem = ag1/N1; nota interna gravada; ag3 notificado (fila); ag1 não é notificado; indicador "encaminhado por ag1 de N1" nas listas dos dois grupos |
| AS-61 | após AS-60 | ag2 abre #1200 | vê o ticket no estado aberto, com a marca "encaminhado" (D23); escreve nota interna; resposta pública e mudança de campo recusadas (403) |
| AS-62 | após AS-60 | ag3 pega e devolve, com nota | grupo N1, responsável ag1, estado aberto; origem limpa; nota gravada; ag1 notificado; o acesso derivado acaba (ag2 volta a ter escrita pelo N1) |
| AS-63 | após AS-60 | ag3 resolve | volta ao N1, responsável ag1, estado **aberto**, nota interna "resolvido pela equipe Financeiro"; nenhum e-mail ao solicitante; nenhum convite de pesquisa |
| AS-64 | após AS-60, ag1 desativado | ag3 devolve | volta ao N1 sem responsável, na fila; ag2 notificado (fila) |
| AS-65 | após AS-60, ag1 ausente | ag3 devolve | volta ao N1 sem responsável; ag1 e ag2 notificados (ag1 do retorno, ag2 da fila) |
| AS-66 | após AS-60 | ag3 tenta encaminhar com retorno para o Comercial | recusado (422: um nível no MVP); nada muda |
| AS-67 | após AS-60 | admin transfere para o Comercial, sem retorno | grupo Comercial; origem limpa (retorno cancelado); ag1 avisado; ag2 perde o acesso derivado |
| AS-68 | #1200 | ag1 tenta encaminhar sem nota interna | recusado (422); nada muda |
| AS-69 | #1200 | ag1 tenta encaminhar com retorno para o próprio N1 | recusado (422) |
| AS-70 | após AS-60 e AS-62 | consultar o SLA | o prazo de resolução é o mesmo de antes do encaminhamento; nenhum reinício |
| AS-71 | ag3 com leitura no N1 | ag3 tenta encaminhar #1200 | recusado (403) |
| AS-72 | após AS-60 | ag3 tenta fechar #1200 | recusado (422); quem fecha é o técnico de origem |
| AS-73 | após AS-60 | ag3 pega, põe em espera e depois devolve | em espera no Financeiro; ao devolver, grupo N1, responsável ag1, estado aberto |
| AS-74 | após AS-60 | ag2 filtra as filas do N1 pela marca "encaminhado" e depois pelo estado em espera | #1200 aparece no filtro "encaminhado", com estado aberto; não aparece no filtro em espera (D23) |
| AS-75 | após AS-62 | ag2 filtra pela marca "encaminhado" | #1200 não aparece (origem limpa) |
| AS-76 | ag1 com token de escrita; ag1 desativado (AS-44) | admin reativa ag1; ag1 usa o token | o token volta a valer (estava suspenso, D26); os tickets não voltam a ag1 |
| AS-77 | ag1 desativado com token; admin revoga o token; admin reativa ag1 | ag1 usa o token | recusado: token revogado |
| AS-78 | grupo Comercial só com ag3 em escrita | ag3 libera um ticket do Comercial | ag3 não é notificado (autor); o público fica vazio, então os admins recebem o aviso (D27) |
| AS-79 | macro compartilhada "Encaminhar ao Financeiro" (encaminha com retorno, com nota interna) | ag1 aplica a macro a #1200 pela API | mesmo efeito de AS-60; o evento registra a macro usada (D29) |

---

## 15. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Ticket novo sem responsável: fila e quem é avisado | documentação (matriz completa em 1 projeto) | A-01 |
| Rodízio, sequência e efeito de ausência ou offline | documentado em 2 projetos, com contradições | A-02 |
| Distribuição por carga (roadmap) | documentado em 1 projeto | A-03 |
| Troca de grupo e efeito no responsável | documentado em 2; não documentado em 5 | A-04 |
| Agente desativado com tickets | documentado em 2 de forma parcial | A-05 |
| Reabertura e responsável | documentação | A-04 e T-03 |
| Isolamento entre grupos (contador, 404) | documentação | P-01 |
| Notificação in-app de atribuição | documentação | R-03 |
| Encaminhamento com retorno | requisito de cliente (spec 13 R06, Δ5) | não se aplica |

## 16. Questões abertas para o implementador

- **Retorno de pendente ou em espera com responsável ausente** (§9, item 5)
  estende a spec 01 §4.3, que manda notificar o responsável. Proposta:
  acrescentar a exceção na spec 01.
- O momento da associação ao grupo como chave do rodízio é uma proposta;
  qualquer chave estável serve, desde que documentada.
- O fuso usado para a data de fim da ausência é o do agente; confirmar se o
  admin, ao marcar outro agente, vê a data no fuso do agente.
- **Cancelar o encaminhamento pela origem**: o agente de origem, que só tem
  leitura enquanto o ticket está em X, não consegue puxar o ticket de volta;
  hoje só quem tem escrita em X (ou o admin) devolve ou transfere. Confirmar
  com a EARJ se a origem precisa de um "cancelar encaminhamento".
