# Spec 09 — Notificações e atualização em tempo real

Status: **rascunho v0.3 (2026-10-29)**. Baseado na documentação pública dos 7
projetos analisados e nos requisitos da operação EARJ (spec 13). As evidências
de runtime ainda estão pendentes (o laboratório não subiu); cada ponto que
depende delas está marcado como **[evidência pendente: cenário]**.
Vocabulário: spec 01. Permissões: spec 06. API: spec 10. Decisões
transversais: spec 00-decisoes-transversais (D01..D53). Precedência: spec 13 >
decisões transversais > esta spec.

**Mudanças na v0.3**
- **Avisos de montagem de evento** (spec 13 Δ34): dois tipos novos de
  notificação, "evento: montagem em 2 dias úteis" e "evento: montagem hoje",
  ao responsável ou, sem ele, ao público do grupo; regras de momento, de
  mudança de data e de pedido fora do prazo (§7.1, §7.6; RT-97..RT-103).
- **Incidente pai** (Δ35): resposta pública no pai chega ao widget de cada
  filho de canal chat, sem pesquisa nos filhos; tipo novo "incidente" com uma
  notificação por pessoa por operação; evento de tempo real "filhos
  alterados" (§3.2, §7.1, §7.3, §9.1; RT-104..RT-108).
- **Página da sala pelo QR** para o agente (Δ33): lista em tempo real dos
  tickets abertos da sala, aviso "esta sala tem N tickets abertos" e aviso ao
  abrir ticket novo numa sala que já tem tickets (§10.1; RT-109..RT-112).
- Categorias novas em "ticket atualizado": local, evento e incidente (§3.2).
- Fila "Quase escalando" e selo de prazo (Δ37) recalculados pelo tempo, sem
  evento (§10; RT-113).
- Sessão do agente vem do login com Google, única entrada de agentes e admins
  (Δ31, D53); o canal de eventos continua só com a sessão do PantherDesk; links dos e-mails
  usam o domínio da conta e sobrevivem ao login (Δ32; §3.1, §8; RT-114,
  RT-115).
- Evidências e questões abertas atualizadas.
- **Ajustes D40–D53**: os momentos dos avisos de montagem, inclusive o aviso
  que sai na hora quando o ticket nasce ou muda de data dentro da janela, ficam
  na spec 05 §7.14; o §7.6 só aponta para ela (D41; RT-99 e RT-101 revistos).
  Ticket de evento tem 1ª resposta de SLA comum e selo/fila "Quase escalando"
  conforme D40; a marca "pronto para o evento" entra na categoria evento de
  "ticket atualizado" (D44). Resposta do pai chega também a filho resolvido
  (D46); filho sem responsável resolvido em cascata recebe quem resolveu o pai,
  sem notificação de atribuição (D47). Agentes só entram com Google (D53).
  Casos novos RT-116..RT-119; questões 5 e 6 removidas (respondidas pela D41).

**Mudanças na v0.2**
- Versão do ticket conforme D01: só mudança de campo ou estado aumenta a versão;
  mensagem pura não exige versão (§4, §6.2, RT-30..RT-33, RT-37, RT-38).
- Resposta a e-mail de notificação vira **nota interna** por padrão (D02; §8,
  RT-52).
- "Ticket na fila do grupo" (inclui ticket novo sem responsável) entra no MVP
  (D09); definido um único **público do grupo** (§7.2), igual ao "notificar o
  grupo" da spec 01 §2, com recurso aos admins quando ele fica vazio.
- Novos tipos de notificação: nota interna no seu ticket, **menção** (Δ7),
  **ticket seguido** (Δ6), **resposta em conversa paralela** (Δ17),
  **devolução** e **cancelamento de encaminhamento** (Δ5), **escalonamento de
  SLA** (Δ14) e retirada de responsável.
- "Pendência venceu" passa a "data de retorno atingida" e vale também para o
  estado **em espera** (D18, Δ3).
- Nomes dos avisos de SLA alinhados à spec 05 ("SLA: aviso" / "SLA: violação");
  aviso por tempo útil absoluto aceito (Δ14).
- Uma notificação por pessoa por evento, com precedência entre tipos (§7.3).
- **Tempo real no widget de chat** (Δ16, D20): novo §9, com "a equipe está
  escrevendo", "lido" e e-mail depois de 2 minutos sem leitura.
- Presença considera **abas internas** (Δ19) e é usada pelo **modo sequência**
  (Δ9); feed da página inicial e contagens de filas salvas (Δ21, Δ9) no §10.
- Garantia do tempo real reescrita como melhor esforço com janela de retomada
  (alinhada à spec 12 §4.4).
- Casos novos RT-27..RT-29, RT-37..RT-38, RT-56..RT-71, RT-80..RT-89,
  RT-90..RT-93; questões abertas respondidas foram removidas.
- Ajustes D23–D37: ticket encaminhado com retorno fica **aberto** no grupo de
  destino, e a marca derivada "encaminhado" vale para a origem (D23); a origem
  mantém leitura e continua recebendo os eventos de tempo real do ticket
  (D24); o público do grupo inclui os agentes marcados como ausentes, nunca o
  autor, com recurso aos admins (D27, §7.2) (RT-94..RT-96).

---

## 1. Problema

Vários agentes trabalham ao mesmo tempo sobre as mesmas filas. Sem tempo real,
cada um vê uma fotografia velha: responde a um ticket que um colega acabou de
resolver, pega um ticket que já tem responsável, ou só descobre que foi
atribuído quando recarrega a página. O sistema precisa:

1. **avisar a interface do agente que algo mudou** (ticket criado ou alterado,
   mensagem nova, atribuição), sem recarregar a página e sem abrir um segundo
   caminho de leitura de dados que fuja das permissões;
2. **evitar colisão**: mostrar quem mais está vendo ou respondendo um ticket e,
   no servidor, **nunca** sobrescrever em silêncio uma alteração de campo ou de
   estado feita por outra pessoa no meio-tempo;
3. **notificar** o agente sobre o que é dele (atribuição, resposta do cliente,
   menção, ticket que segue, SLA prestes a vencer), dentro do app e, se ele
   quiser, por e-mail, com estado de lida/não lida;
4. **levar ao visitante do chat** as respostas da equipe em tempo real (Δ16);
5. **sobreviver a quedas de conexão** sem exigir que o agente perceba que caiu;
6. funcionar atrás de um proxy reverso comum, sem infraestrutura exótica.

Fora do MVP (roadmap): presença global do agente (online/ocupado/offline)
ligada ao roteamento, indicador de digitação **do visitante** para o agente,
push do navegador ou do sistema operacional, som, app móvel, tempo real no
portal do cliente (fora do widget de chat), rascunho compartilhado no servidor.

---

## 2. Princípios

| # | Princípio | Consequência |
|---|---|---|
| P1 | **O evento diz "o quê mudou", nunca "como ficou".** | Eventos carregam apenas tipos e identificadores (ticket, mensagem, versão). A interface busca os dados pela API REST (spec 10), que aplica as permissões. A regra de acesso existe num lugar só. |
| P2 | **Filtrado por permissão no momento da entrega.** | Um agente só recebe eventos de tickets que ele pode ler **naquele instante**. Mesmo sendo só identificadores, isso evita revelar movimento em grupos alheios. |
| P3 | **Correção não depende do tempo real.** | A concorrência otimista (§6) protege contra sobrescrita mesmo que o canal de eventos esteja fora. O tempo real só melhora a experiência. |
| P4 | **Gerado na mesma transação da mudança.** | Eventos de tempo real e notificações nascem dos eventos de domínio e de auditoria (spec 01 §7, spec 12 §4.1), gravados juntos. Não existe mudança sem evento nem evento sem mudança. |
| P5 | **Um transporte simples, com degradação explícita.** | Server-sent events (SSE) como canal principal; polling no mesmo contrato como alternativa. |

---

## 3. Canal de eventos

### 3.1 Transporte

- A interface do agente abre **uma conexão SSE** com o servidor, autenticada
  pela **sessão** do agente (mesma origem, cookie de sessão). O identificador
  de sessão **nunca** vai na URL. A sessão é sempre emitida pelo PantherDesk,
  depois do login com Google, única entrada de agentes e admins (spec 13 Δ31,
  D53, spec 12 §6.5); nenhuma credencial do provedor externo é aceita pelo
  canal. O link de acesso por e-mail é só do portal do solicitante e não abre
  sessão de agente.
- Tokens de API (pessoais ou de identidade de integração, spec 10) **não**
  abrem o canal de eventos no MVP. Integrações usam webhooks ou o feed de
  eventos (spec 10). Motivo: o canal é um detalhe da interface, não um
  contrato público estável.
- O servidor envia um **sinal de vida** a cada 25 s quando não há eventos, para
  manter proxies e balanceadores com a conexão aberta.
- O servidor informa ao cliente o intervalo inicial de reconexão (3 s).
- Entre instâncias da aplicação, os eventos circulam por um pub/sub interno
  (fila/cache já presente na pilha do MVP). O agente pode estar conectado a
  qualquer instância.
- **Polling** (fallback): o mesmo contrato exposto como pedido comum "eventos
  desde o cursor X", com resposta imediata (sem segurar a conexão). Intervalo
  padrão 20 s. Cada resposta traz no máximo 200 eventos; se houver mais,
  responde como "cursor antigo demais" (§3.4).
- O widget de chat usa um canal próprio, com as mesmas regras de transporte e
  outro escopo (§9).

### 3.2 Tipos de evento (MVP)

| Tipo | Carrega | Quem recebe | O que a interface faz |
|---|---|---|---|
| ticket criado | id do ticket, grupo, versão | agentes com leitura no grupo | atualiza listas e contadores afetados |
| ticket atualizado | id do ticket, nova versão, **categorias** do que mudou (estado, responsável, grupo, prioridade, tipo, etiquetas, campos, participantes, encaminhamento, **local** (Δ33), **evento** (data, horários, montagem e marca "pronto para o evento", Δ34, D44), **incidente** (vínculo do filho ao pai, Δ35)) | agentes com leitura no grupo **antes ou depois** da mudança | se o ticket está aberto na tela, rebusca; atualiza listas, o calendário de eventos e a página da sala (§10.1); se a rebusca der 404, remove o ticket da tela e das listas |
| filhos alterados | id do ticket pai | agentes com leitura no pai | rebusca a contagem de filhos e os locais afetados do pai aberto na tela (Δ35); não muda a versão do pai |
| mensagem nova | id do ticket, id da mensagem, visibilidade (pública, nota interna ou conversa paralela) | agentes com leitura no ticket | acrescenta a mensagem na conversa aberta (buscando-a pela API); atualiza "última atualização" nas listas |
| seguidores alterados | id do ticket | agentes com leitura no ticket | rebusca a lista de seguidores do ticket aberto |
| mensagem lida | id do ticket, id da mensagem | agentes com leitura no ticket | mostra "lido" na resposta pública lida no widget de chat (§9.2) |
| avaliação registrada | id do ticket | agentes com leitura no ticket | rebusca a avaliação (Δ15) e as contagens de filas que dependem dela |
| ticket mesclado | id da origem, id do destino | agentes com leitura em qualquer dos dois | na tela da origem, oferece ir para o destino |
| notificação | id da notificação, contador de não lidas | o destinatário | atualiza o sino, o feed da página inicial e a lista (§7, §10) |
| notificação lida | ids, contador de não lidas | o destinatário | sincroniza o estado entre abas |
| presença | id do ticket, id do agente, estado (§5) | agentes com leitura no ticket | atualiza os avatares do ticket |
| recarregar | motivo | o cliente afetado | descarta o estado local e recarrega listas e o ticket aberto |

Regras:
- "Atribuição a mim" chega por dois caminhos: como **ticket atualizado**
  (categoria responsável), para todos os que veem o ticket, e como
  **notificação** só para o novo responsável.
- O evento de ticket atualizado **não** diz o valor novo nem o anterior (por
  exemplo, não diz "estado = em espera"). As categorias servem só para a
  interface decidir o que rebuscar.
- Só mudança de campo ou de estado gera "ticket atualizado" e aumenta a versão
  (§4). Mensagens, seguidores, avaliações e a lista de filhos de um incidente
  têm eventos próprios, sem versão nova; a repetição desses eventos é
  descartada pelo id da mensagem ou pela rebusca idempotente.
- **Incidente pai** (Δ35): vincular ou desvincular um filho muda um campo do
  **filho** (o pai dele), que recebe "ticket atualizado" com a categoria
  incidente e versão nova; o pai recebe só "filhos alterados". Uma resposta
  pública no pai gera "mensagem nova" no pai e uma em **cada filho** (a
  mensagem registrada nele); resolver o pai gera "ticket atualizado" em cada
  filho resolvido junto. Cada evento segue o filtro por permissão do próprio
  ticket (§3.3).
- O autor da mudança também recebe o evento nas outras abas. A aba que fez a
  mudança reconhece a versão (ou o id da mensagem) que ela mesma gravou e não
  rebusca.
- **Coalescência**: várias mudanças no mesmo ticket dentro de 1 s podem ser
  entregues como um único "ticket atualizado" com a versão mais recente e a
  união das categorias. Eventos de mensagem nova **não** são coalescidos.
- A interface **limita a rebusca** de uma mesma lista (ou contagem de fila) a
  no máximo uma a cada 2 s, para que uma rajada de eventos não vire uma rajada
  de pedidos à API.

### 3.3 Filtragem por permissão

- O servidor avalia, para cada evento e cada conexão, se o agente pode ler o
  ticket **no momento da entrega**, com as regras de acesso da spec 06 §3
  (agente: grupos com leitura ou escrita; admin: todos).
- Ticket que **sai** do alcance do agente (ex.: movido de N1 para Financeiro):
  quem tinha acesso antes recebe um último "ticket atualizado"; ao rebuscar,
  recebe 404 e remove o ticket da tela. Depois disso, não recebe mais nada
  sobre ele.
- Ticket que **entra** no alcance: o agente recebe "ticket atualizado" e o
  ticket aparece nas listas a que pertence.
- Ticket **encaminhado com retorno** (Δ5): o agente e o grupo de origem
  mantêm leitura até o retorno ou o cancelamento (D24), então **não** recebem
  o 404 do item acima; continuam recebendo "ticket atualizado" e "mensagem
  nova", e o ticket aparece nas listas da origem com a marca derivada
  "encaminhado" (D23). Ele **não** tem um estado próprio: está aberto no grupo
  de destino. No retorno ou no cancelamento, valem as regras de saída e
  entrada de alcance.
- Mensagens de **conversa paralela** (Δ17) e notas internas só vão a agentes;
  nunca ao canal do widget (§9).
- Agente desativado ou sessão revogada: a conexão é encerrada pelo servidor em
  até 60 s; a reconexão recebe 401 e a interface vai para a tela de login, sem
  laço de reconexão.
- Solicitantes não têm canal de eventos no portal no MVP. A única exceção é o
  visitante do widget de chat, com escopo restrito (§9).

### 3.4 Reconexão e recuperação de eventos perdidos

- Cada evento tem um **id** opaco, crescente dentro da conta. O cliente guarda o
  último id recebido.
- Ao reconectar, o cliente informa o último id. O servidor reenvia, em ordem, os
  eventos posteriores que o agente pode ver.
- O servidor guarda eventos para retomada por **15 minutos** (ou os 10.000 mais
  recentes da conta, o que for menor). Se o id informado for mais antigo que
  isso, ou desconhecido, o servidor envia **recarregar**, seguido do id atual. O
  cliente recarrega listas e o ticket aberto pela API e continua a partir daí.
- Reconexão com recuo: 3 s, 6 s, 12 s, 24 s, até 60 s, com variação aleatória
  de ±20% (evita que todos os agentes reconectem no mesmo segundo após uma
  queda do servidor).
- Após **3 falhas seguidas** de SSE, o cliente passa para polling (§3.1) e tenta
  voltar para SSE a cada 5 min. A troca é invisível para o agente, exceto por um
  indicador discreto de "atualização a cada 20 s".
- Sem conexão nenhuma por mais de 60 s, a interface mostra um aviso "você está
  offline; os dados podem estar desatualizados". O aviso some na reconexão.
- Ao voltar de uma aba inativa ou do computador suspenso, o cliente reconecta
  com o último id; o caminho é o mesmo.
- **Garantia**: o tempo real é de **melhor esforço com janela de retomada**
  (alinhado à spec 12 §4.4). Dentro da janela de 15 min, cada evento chega ao
  cliente **pelo menos uma vez**; fora dela não há reentrega, e o cliente
  recarrega o estado pela API. Repetição é inofensiva: um "ticket atualizado"
  com versão igual ou menor que a já exibida é ignorado, e uma mensagem já
  exibida (mesmo id) não é acrescentada de novo. Nenhuma regra de correção
  depende dessa entrega (P3).

### 3.5 Limites

- No máximo **10 conexões simultâneas por agente** (abas e dispositivos). A 11ª
  derruba a mais antiga, que passa para polling. Abas internas da interface
  (Δ19) compartilham a conexão da aba do navegador.
- O canal só transporta eventos para a conta da sessão; não há eventos entre
  contas.

---

## 4. Versão do ticket

Conforme D01 e spec 01 §3:

- Todo ticket tem uma **versão**: um inteiro que aumenta **só** quando muda um
  **campo** ou o **estado** do ticket, qualquer que seja a origem (agente,
  automação, tarefa agendada, API, ou o efeito automático de um e-mail
  recebido, como a reabertura de um pendente).
- Acrescentar mensagem pública, nota interna, mensagem de sistema, mensagem de
  conversa paralela ou e-mail recebido **não** aumenta a versão. Seguir,
  deixar de seguir e registrar avaliação também não.
- A versão está presente na leitura do ticket pela API e nos eventos "ticket
  criado" e "ticket atualizado".
- É a mesma versão usada pela concorrência otimista (§6) e pela API (spec 10
  §8).

---

## 5. Presença no ticket

### 5.1 Estados

| Estado | Quando | Exibição para os colegas |
|---|---|---|
| **vendo** | o ticket está na aba interna ativa (Δ19) de uma aba do navegador visível | avatar cheio |
| **em segundo plano** | o ticket está aberto numa aba interna inativa, ou numa aba do navegador que não está visível | avatar esmaecido |
| **respondendo** (público) | o editor de resposta pública tem texto não enviado | avatar com marca "respondendo"; aviso no topo do editor dos colegas: "ag2 também está respondendo" |
| **escrevendo nota** | o editor de nota interna tem texto não enviado | avatar com marca "nota"; **sem** aviso no editor |
| ausente | nenhum sinal há mais de 75 s | avatar some |

### 5.2 Regras

- A interface envia um **sinal de presença** ao abrir o ticket, ao mudar de
  estado e, depois, a cada 30 s enquanto o ticket estiver aberto. Sem sinal por
  75 s, o agente sai da presença daquele ticket.
- Ao fechar o ticket, a aba interna ou a aba do navegador, a interface envia
  "saí" (melhor esforço); se não chegar, vale a expiração.
- Várias abas do mesmo agente no mesmo ticket aparecem como **um** avatar, com
  o estado mais forte: respondendo > escrevendo nota > vendo > em segundo plano.
- O agente não vê a própria presença.
- Presença é **efêmera**: não gera evento de auditoria, não é gravada no banco
  principal, não aparece em relatórios nem na API pública.
- Presença é filtrada por permissão (§3.3): só quem pode ler o ticket vê quem
  está nele.
- Presença **não bloqueia** gravação. Ela informa; quem protege contra
  sobrescrita é a §6.
- **Modo sequência** (Δ9, spec 08): ao escolher o próximo ticket da fila, o
  servidor **pula** os tickets em que outro agente está **vendo**,
  **respondendo** ou **escrevendo nota**, e a interface avisa quais foram
  pulados. "Em segundo plano" não faz pular (uma aba esquecida não deve
  esconder trabalho da fila).
- O estado **respondendo** de qualquer agente num ticket de canal chat alimenta
  o indicador "a equipe está escrevendo" do widget (§9).
- O sinal de presença é enviado pela API com a sessão do agente; tokens não
  enviam presença.

Motivo da escolha (presença + concorrência otimista, sem trava): bloqueio
exclusivo exige expiração, desbloqueio manual e tarefa agendada, e trava o
trabalho quando alguém esquece uma aba aberta. Presença sozinha não basta porque
falha quando o canal está fora. As duas juntas cobrem os dois casos.

---

## 6. Concorrência otimista

### 6.1 Regra geral

- A interface do agente **sempre** envia a **versão esperada** (a versão que o
  agente tinha na tela) em toda gravação sobre um ticket (D01).
- O servidor verifica a versão quando a gravação **muda campo ou estado**,
  sozinha ou junto com uma mensagem. Se a versão atual for diferente, recusa o
  envio **inteiro** com erro de **conflito** (spec 10: 409
  `conflito_de_versao`) e devolve a versão atual e um resumo do que mudou desde
  a versão esperada: categorias de campo alteradas e, para contexto, ids das
  mensagens gravadas no meio-tempo, com autor e visibilidade.
- **Nada é gravado** na recusa (nem a mensagem, nem auditoria parcial),
  seguindo spec 01 §4.2.
- **Nunca** há sobrescrita silenciosa de campo ou estado, nem "o último ganha".
- Acréscimos puros (mensagem sem mudança de campo ou estado) não são
  verificados. A versão enviada pela interface é ignorada nesse caso.

### 6.2 O que exige a versão

| Operação | Versão verificada? | Motivo |
|---|---|---|
| Alterar campos (estado, responsável, grupo, prioridade, tipo, etiquetas, campos personalizados, participantes) | sim | é o caso clássico de sobrescrita |
| Envio que junta mensagem (pública ou nota) e mudança de campo ou estado, inclusive "enviar com estado" (Δ19) | sim, para o envio inteiro | a mudança de estado precisa partir do estado que o agente viu |
| Resposta pública **sem** mudança de campo ou estado | **não** (D01) | é um acréscimo; ver o aviso não bloqueante abaixo |
| Nota interna sem mudança de campo ou estado | **não** | é só um acréscimo, invisível ao cliente |
| Aplicar macro (enviar depois da prévia, spec 05) | sim, se a macro muda campo ou estado; senão, como mensagem pura | uma macro com ações é uma gravação com várias mudanças |
| Mesclar | sim (nos dois tickets) | muda o estado da origem; operação irreversível |
| Encaminhar com retorno e devolver (Δ5) | sim | mudam grupo e responsável e deixam o ticket aberto (D23) |
| Seguir ou deixar de seguir; abrir, responder ou encerrar conversa paralela | não | não mudam campo nem estado do ticket |
| E-mail recebido, resposta no portal, mensagem de chat, automações, tarefas agendadas | não | são acréscimos ou regras do servidor; são serializados no servidor e aumentam a versão só quando mudam campo ou estado |

**Aviso não bloqueante para mensagens**: como a resposta pura não é recusada,
a interface protege contra "responder sem ler" de outro jeito. Quando chega um
evento de mensagem nova pública no ticket aberto enquanto o editor tem texto, o
topo do editor mostra "ana respondeu enquanto você escrevia". A interface
também informa ao enviar o id da última mensagem que a tela mostrava; a
resposta do servidor lista as mensagens públicas gravadas depois dela, e a
interface mostra o mesmo aviso. Nada é recusado.

### 6.3 Experiência no conflito

- O rascunho do agente **é preservado** (nunca descartado por causa de um
  conflito).
- A interface rebusca o ticket e mostra o que mudou: "ana respondeu e o ticket
  voltou para aberto", "ag2 mudou o estado para resolvido".
- O agente decide: revisar e **enviar mesmo assim** (a interface reenvia com a
  nova versão) ou desistir. Nenhum reenvio é automático.
- Para mudanças de campo, o reenvio leva só os campos que o agente alterou. Se
  o colega alterou o **mesmo** campo, a interface mostra os dois valores e pede
  escolha.

### 6.4 Rascunhos

- No MVP o rascunho da resposta e o da nota ficam salvos **no navegador**, por
  ticket e por agente, automaticamente (Δ19). Sobrevivem a recarga, a conflito
  e ao fechamento da aba interna; abas internas diferentes têm rascunhos
  independentes. Ao enviar com sucesso, o rascunho é apagado.
- Rascunho compartilhado no servidor (entre dispositivos) fica para o roadmap.

---

## 7. Notificações in-app

### 7.1 Tipos (MVP)

| Tipo | Quem recebe | Quando |
|---|---|---|
| **atribuído a você** | o novo responsável | o ticket passa a ter esse agente como responsável, por outro agente, por automação, pela API ou por atribuição automática (spec 04). **Não** notifica quando o agente atribui a si mesmo (D12). |
| **deixou de ser seu** | o responsável anterior | outra pessoa (ou automação) o tirou do ticket: reatribuição, devolução à fila ou transferência que limpou o responsável (spec 04 §10) |
| **ticket na fila do grupo** | o público do grupo (§7.2) | o ticket entra na fila **sem responsável**: criado sem responsável depois das automações e do rodízio (D09), devolvido, transferido, encaminhado com retorno (Δ5), reaberto ou de volta da data de retorno sem responsável (spec 04 §10) |
| **resposta no seu ticket** | o responsável; sem responsável, o público do grupo | chega mensagem **pública** do solicitante ou de um participante (por e-mail, portal ou chat). Mensagem de participante **não confirmado** (spec 02 §5) também notifica, com a marca "remetente não confirmado", para que o agente confirme ou recuse. Mensagens de sistema (resposta automática, bounce) **não** notificam. |
| **nota interna no seu ticket** | o responsável | um colega escreve nota interna num ticket do qual ele é responsável |
| **menção** | o agente mencionado (Δ7) | uma nota interna menciona o agente, que está ativo e tem leitura ou escrita no grupo do ticket |
| **ticket que você segue** | os seguidores (Δ6) | mensagem pública, nota interna ou mudança de estado num ticket que o agente segue |
| **resposta em conversa paralela** | o responsável e os seguidores | chega resposta de um destinatário numa conversa paralela do ticket (Δ17) |
| **ticket devolvido a você** | o agente de origem do encaminhamento | o grupo de destino devolve ou resolve um ticket encaminhado com retorno e ele volta com esse agente como responsável (Δ5) |
| **encaminhamento cancelado** | o agente de origem do encaminhamento | o ticket encaminhado é transferido sem retorno, o que cancela o retorno (Δ5) |
| **SLA: aviso** | o responsável; sem responsável, o público do grupo | o ticket atinge o limiar de aviso da política (spec 05 §7.10): percentual da meta ou tempo útil absoluto, como "1 hora útil antes" (Δ14) |
| **SLA: violação** | idem; e os admins, se a política tiver essa opção (spec 05 §7.11) | o prazo de uma métrica passa sem cumprimento |
| **SLA: escalonamento** | a pessoa ou o papel configurado na política (Δ14) | passam N horas úteis depois da violação sem cumprimento (EARJ: 8 h úteis, ao gestor de TI) |
| **data de retorno atingida** | o responsável; sem responsável, o público do grupo | a data de retorno de um ticket **pendente** ou **em espera** é atingida e ele volta para aberto (spec 01 §4.3, Δ3) |
| **evento: montagem em 2 dias úteis** | o responsável do ticket de evento; sem responsável, o público do grupo do ticket (para a EARJ, o grupo de eventos) | chega o momento do aviso antecipado de um ticket de evento, ou o ticket nasce ou muda de data já dentro da janela desse aviso (Δ34, D41; §7.6) |
| **evento: montagem hoje** | idem | chega o momento do aviso do dia da montagem, ou o ticket nasce ou muda de data já dentro dessa janela (Δ34, D41; §7.6) |
| **incidente** | os responsáveis e os seguidores do pai e dos filhos, exceto o autor | um ticket que a pessoa acompanha é vinculado a um incidente pai, o pai recebe uma resposta pública enviada aos filhos, ou o pai é resolvido e resolve os filhos (Δ35); **uma** notificação por pessoa por operação, mesmo que ela acompanhe vários tickets envolvidos (§7.3) |
| **webhook desativado** | todos os admins | uma assinatura de webhook é desativada automaticamente (spec 10 §13.5) |

Cada aviso de SLA (aviso, violação, escalonamento) sai **no máximo uma vez por
métrica por ticket** (spec 05 §7.10 e Δ14). Uma pausa em espera e o retorno a
aberto não geram um segundo aviso da mesma métrica.

Roadmap: substituto durante ausência; avaliação recebida como notificação (no
MVP ela aparece só nos números da página inicial, §10).

### 7.2 Público do grupo

Quando uma notificação vai "para o grupo", o público é o mesmo em todos os
tipos ("notificar o grupo" da spec 01 §2, D09, D27):

- agentes **ativos** com acesso de **escrita** ao grupo do ticket (spec 06 §3),
  incluindo admins que sejam membros com escrita;
- **exceto** o autor da ação (D12);
- os agentes marcados como **ausentes** (spec 04 §8) **fazem parte** do
  público: a ausência só afeta a distribuição automática, não os avisos (D27);
- agentes só com **leitura** (agente de apoio) não fazem parte do público do
  grupo;
- se o público ficar vazio, a notificação vai para os **admins** da conta
  (exceto o autor). Nenhum ticket entra na fila em silêncio.

### 7.3 Regras

- A notificação é gerada a partir do evento de auditoria, na mesma transação
  (P4). Processar o mesmo evento duas vezes **não** cria duas notificações
  (spec 01, TL-23).
- **Nunca** notificar o autor da ação (D12): se ag1 responde e muda o estado,
  ag1 não recebe nada, mesmo sendo seguidor ou responsável; uma menção a si
  mesmo não notifica.
- **Uma notificação por pessoa por evento.** Se a pessoa se encaixa em vários
  tipos para o mesmo evento, recebe só o de maior precedência: menção >
  atribuído a você > ticket devolvido a você > resposta no seu ticket > nota
  interna no seu ticket > resposta em conversa paralela > incidente > ticket
  na fila do grupo > ticket que você segue.
- **Incidente** (Δ35): uma operação no pai (vincular vários filhos, resposta
  pública replicada, resolução em cascata) é **um** evento para fins de
  notificação. Quem acompanha o pai e três filhos recebe uma única
  notificação "incidente", e não "ticket que você segue" por ticket. A
  notificação aponta para o **pai** quando a pessoa pode lê-lo; se ela só lê
  algum filho, aponta para o primeiro filho que ela lê e não mostra nada do
  pai (nem número, nem assunto). As respostas dos solicitantes dos filhos
  continuam gerando "resposta no seu ticket" no filho, como em qualquer
  ticket.
- Só recebe notificação sobre um ticket quem pode lê-lo naquele instante
  (spec 06 §6.3). Isso vale também para seguidores e mencionados.
- **Menções** (Δ7): só em nota interna. Mencionar agente sem acesso ao ticket,
  ou desativado, não notifica e mostra um aviso ao autor; a nota é gravada
  mesmo assim. Mencionado com acesso passa a ser **seguidor** e pode deixar de
  seguir. Em resposta pública, o texto com "@" não vira menção, nada é
  notificado e o autor recebe um aviso antes de enviar.
- **Seguidores** (Δ6): o agente segue ou deixa de seguir qualquer ticket que
  consegue ver. Seguidor não é participante: não recebe os e-mails públicos
  como Cc e não aparece para o solicitante. Quem perde o acesso ao ticket
  deixa de receber notificações dele.
- Agrupamento: se já existe uma notificação **não lida** do mesmo tipo, para o
  mesmo destinatário e o mesmo ticket, ela é **atualizada** (contagem e momento
  mais recente) e volta ao topo, em vez de criar outra. Ex.: ana responde três
  vezes → uma notificação "3 respostas". Menções não são agrupadas (cada uma
  aponta para uma nota).
- A notificação guarda tipo, destinatário, ticket, momento, contagem e estado
  (lida/não lida). O título exibido (assunto, número) é obtido pela API no
  momento da exibição, com as permissões atuais.
- Ticket que o agente não pode mais ler: a notificação **some da lista** (não é
  apagada; volta se o acesso voltar). Isso evita mostrar o assunto de um ticket
  de outro grupo.
- Agente desativado não recebe notificações.
- "Atribuído a você" e "ticket devolvido a você" não podem ser desligados no
  in-app, só no e-mail (spec 04 §10). O agente pode silenciar no in-app os
  avisos "ticket na fila do grupo" de um grupo específico.

### 7.4 Lida e não lida

- Cada notificação está **não lida** ou **lida**.
- Fica lida quando o agente: clica nela; marca como lida; usa "marcar todas
  como lidas"; ou **abre o ticket** a que ela se refere (todas as não lidas
  daquele ticket ficam lidas).
- O agente pode marcar uma lida de volta como não lida.
- O contador mostra o número de não lidas (acima de 99, mostra "99+").
- Mudança de estado de leitura é sincronizada entre abas e com o feed da
  página inicial (§10) pelo evento "notificação lida".

### 7.5 Retenção

- Lidas: apagadas 30 dias depois de lidas.
- Não lidas: apagadas 90 dias depois de criadas.
- Limpeza diária, idempotente.

### 7.6 Avisos de montagem de evento (Δ34)

O ticket de evento guarda a data do evento e o **início da montagem**; o
compromisso é estar pronto até a montagem (marca "pronto para o evento", D44).
**Os momentos dos dois avisos são da spec 05 §7.14** (D41), inclusive:
- o calendário usado (o do grupo do ticket) e o fuso da conta;
- o aviso que sai **imediatamente, uma vez**, quando o ticket nasce ou muda de
  data já dentro da janela de um aviso (2 dias úteis antes, ou no dia), o que
  cobre o pedido fora do prazo (Δ34);
- o aviso "no dia" quando a montagem cai em dia sem expediente ou começa antes
  da abertura do expediente;
- o recálculo quando o início da montagem muda e a regra de "uma vez por
  ticket e por início da montagem";
- os estados em que o aviso não sai (resolvido, fechado, mesclado, ou o ticket
  deixou de ser do tipo evento). Pendente ou em espera **não** suspendem o
  aviso.

Esta spec define só a entrega:
- Tipos "evento: montagem em 2 dias úteis" e "evento: montagem hoje" (§7.1). O
  nome do tipo é o mesmo quando o aviso sai na hora por estar dentro da janela.
- O destinatário é avaliado **no momento do aviso** (responsável ou público
  do grupo, §7.2). Nunca há autor a excluir: o aviso é do sistema.
- A tarefa que emite os avisos roda no mínimo **a cada minuto** (como os
  avisos de SLA, Δ14) e é idempotente: rodar duas vezes não duplica.
- Os avisos de montagem **não** são avisos de SLA: não aparecem como "SLA:
  aviso" nem contam para as métricas de SLA. A **1ª resposta** do ticket de
  evento segue a política de SLA comum (D40) e gera os avisos de SLA normais
  do §7.1; a resolução comum não se aplica. O selo de prazo do evento nas
  filas (D40, §10) é calculado pela interface e não gera evento.

---

## 8. Notificações por e-mail para agentes

- Cada agente configura, **por tipo** (§7.1), se também quer e-mail. A
  notificação in-app é sempre gerada (salvo silêncio por grupo, §7.3).
- Padrão para agente novo:

| E-mail ligado por padrão | E-mail desligado por padrão |
|---|---|
| atribuído a você; menção; ticket devolvido a você; encaminhamento cancelado; SLA: violação; SLA: escalonamento; data de retorno atingida; evento: montagem em 2 dias úteis; evento: montagem hoje | deixou de ser seu; ticket na fila do grupo; resposta no seu ticket; nota interna no seu ticket; ticket que você segue; resposta em conversa paralela; incidente; SLA: aviso |

  Os desligados são os de volume alto para quem já trabalha na tela.
  "Webhook desativado" sempre vai por e-mail para os admins, sem opção de
  desligar.
- **Atraso de cortesia**: o e-mail sai 2 minutos depois da notificação. Se nesse
  tempo a notificação já tiver sido lida no app, o e-mail **não** sai. Isso evita
  e-mail para quem está com a tela aberta.
- Notificações agrupadas (§7.3) geram no máximo **um e-mail por notificação
  enquanto ela continuar não lida**: atualizações posteriores do agrupamento não
  geram novos e-mails.
- O e-mail segue as regras de saída da spec 02: `Auto-Submitted: auto-generated`
  e cabeçalho de laço; identificadores de encadeamento do ticket, para que uma
  resposta do agente a esse e-mail entre no ticket (spec 02 §5). Conforme D02,
  essa resposta vira **nota interna** por padrão; a conta pode mudar o padrão
  para "pública". O e-mail avisa, em uma linha, o efeito vigente: "responder a
  este e-mail adiciona uma nota interna" (ou "envia uma resposta pública ao
  cliente", se a conta mudou o padrão).
- O link do ticket usa o **domínio próprio da conta**, no caminho da área do
  agente (Δ32; para a EARJ, help.earj.com.br). Quem clica sem sessão passa
  pelo login (Δ31) e volta exatamente ao ticket do link.
- Os e-mails de montagem trazem o nome e o tipo do evento, o local (Δ33) e o
  início da montagem no fuso da conta. O e-mail "incidente" traz o número do
  pai e a contagem de filhos, só se o destinatário puder ler o pai (§7.3).
- O conteúdo inclui número, assunto, tipo e link para o ticket. Para "resposta
  no seu ticket", inclui o trecho da mensagem pública. **Nunca** inclui texto de
  nota interna nem de conversa paralela: os e-mails de menção, de nota interna
  e de ticket seguido dizem quem escreveu e onde, sem o texto.
- Endereço do agente marcado como inválido (spec 02 §7): o e-mail não sai; a
  notificação in-app continua.

---

## 9. Tempo real no widget de chat

O chat no site entra no MVP (D20, Δ16) em modo **assíncrono**: o agente
responde pela tela normal do ticket, e o visitante vê a resposta no widget.

### 9.1 Canal do visitante

- O widget é autenticado pelo **token de conversa** da spec 03 §6.3 (ou pela
  sessão do portal, quando roda dentro do portal), trocado por uma sessão do
  canal de chat na origem do PantherDesk. A credencial **nunca** vai na URL e
  não é token de API. O visitante sempre informou nome e e-mail (spec 03 §6.2).
- O widget abre um canal SSE próprio, com as mesmas regras de transporte,
  sinal de vida, retomada de 15 min, recuo e polling de §3.1 e §3.4. No máximo
  **5 conexões** por token de conversa; a 6ª derruba a mais antiga.
- **Escopo**: só o ticket ao qual o token de conversa aponta (spec 03 §6.3).
  Nada de outros tickets, nem do mesmo solicitante por outros canais. Quando o
  token passa a apontar para um ticket novo (resposta em fechado com política
  `novo`), o canal recebe "recarregar".
- **Conteúdo** (P1): só ids e tipos. O widget busca o texto pela API do canal
  de chat (spec 03), que aplica o mesmo filtro do portal (spec 06 §6.2).

| Evento do widget | Quando |
|---|---|
| mensagem pública nova | resposta pública de agente no ticket do chat |
| a equipe está escrevendo / parou | algum agente entra ou sai do estado de presença **respondendo** no ticket (§5.2) |
| pesquisa disponível | o ticket foi resolvido e há convite de pesquisa (Δ15); nunca para um **filho** de incidente resolvido pelo pai (Δ35) |

- **Filho de incidente** (Δ35): a resposta pública escrita no pai e
  registrada num filho de canal chat chega ao widget daquele filho como
  "mensagem pública nova", na variante de idioma que o filho recebeu (Δ36), e
  segue as regras de "lido" e do e-mail depois de 2 minutos (§9.2, §9.3). O
  widget nunca recebe nada que identifique o pai ou os outros filhos.

- O widget **nunca** recebe nota interna, mensagem de conversa paralela,
  mensagem de sistema interna, presença "vendo" ou "escrevendo nota", nome de
  grupo ou outra informação interna. O indicador mostra o nome de exibição do
  agente que está respondendo, como nas mensagens públicas; com vários, mostra
  "a equipe está escrevendo".

### 9.2 Lido

- Conforme a spec 03 §6.4: a resposta do agente fica **lida** quando o widget
  a exibe aberto e visível. O widget avisa o servidor, e os agentes que veem o
  ticket recebem o evento **mensagem lida** (§3.2); a tela mostra "lido" na
  mensagem pública.
- As marcas de leitura não mudam campo nem estado e não aumentam a versão.

### 9.3 E-mail quando o visitante não lê

- Cada resposta pública num ticket de chat espera **2 minutos** (spec 03
  §6.4). Se ao fim desse prazo ela não estiver lida e o solicitante tiver
  endereço válido, ela sai por e-mail (spec 02 §9), **uma vez**. Cada resposta
  tem o seu prazo; uma resposta lida dentro do prazo não sai por e-mail.
- Endereço inválido (spec 02 §7): nada sai; a resposta espera no widget.
- Resposta que **resolve** o ticket (Δ12, Δ15): se o visitante a ler no widget
  dentro dos 2 minutos, a pesquisa aparece no widget e **nenhum** e-mail sai;
  se não ler, sai **um** e-mail com a resposta e o convite. É o mesmo convite
  da resolução (no máximo um por resolução); ele continua disponível no widget.
  Num filho resolvido pelo pai (Δ35) não há convite: o e-mail, se sair, leva
  só a resposta.

---

## 10. Página inicial do agente e filas

- O **feed** da página inicial (Δ21) é uma visão da mesma lista de
  notificações do §7, filtrada pelos tipos menção, atribuído a você, resposta
  no seu ticket, avisos de SLA (aviso, violação, escalonamento), avisos de
  montagem de evento e incidente. Ler no feed ou no sino é a mesma coisa
  (§7.4).
- O **selo de prazo** de cada linha das filas (Δ37: "vence em …", "vencido há
  …", "pausado"; para eventos, conforme D40: "faltam N dias" ou "faltam N h"
  antes da montagem, "pronto" com a marca, "montagem sem pronto" em vermelho
  se a montagem começou sem a marca, "evento encerrado" depois do fim do
  evento; valores na spec 05 §7.15) é calculado pela interface a partir do
  instante do prazo, da marca "pronto" e do estado que a API devolve; a
  interface o redesenha a cada minuto. Pausas, mudanças de estado e a marca
  "pronto" chegam por "ticket atualizado". Nenhum evento é emitido só porque
  o prazo se aproximou ou a montagem começou.
- A fila compartilhada **"Quase escalando"** (Δ37) tem filtro relativo ao
  tempo: segue a regra das filas relativas ao tempo abaixo. Inclui o ticket de
  evento cuja montagem começa em até 1 hora útil sem a marca "pronto", ou já
  começou sem ela (D40); pôr a marca tira o ticket da fila na recontagem
  seguinte.
- O **calendário de eventos** (Δ34) aberto na tela é atualizado por "ticket
  criado" e por "ticket atualizado" com a categoria evento ou local, com a
  mesma limitação de rebusca.
- **Abertos nos meus grupos** (contagem por estado) e as **contagens das filas
  salvas** (Δ9, spec 08) são atualizados por "ticket criado" e "ticket
  atualizado", com a mesma limitação de uma rebusca a cada 2 s (§3.2).
- Filas com filtro relativo ao tempo ("resolvidos nas últimas 12 h") são
  recalculadas a cada abertura e, com a fila aberta, a cada minuto; nenhum
  evento é emitido só porque o tempo passou.
- **Meus números da semana** e **satisfação de 60 dias** (spec 11) não são
  tempo real: são recalculados ao abrir a página inicial e a cada 5 min com ela
  aberta.

### 10.1 Página da sala aberta pelo QR (Δ33)

Quando um **agente com sessão** abre o endereço do QR de uma sala, ele vê a
página da sala, não o formulário do solicitante.

- A página lista os tickets **aberto, pendente ou em espera** daquela sala
  que o agente pode ler (§3.3), com estado, responsável, selo de prazo e o
  botão "assumir". Tickets de grupos que ele não lê **não** aparecem nem
  entram na contagem: nada indica que existem (P2).
- No topo, quando a lista não está vazia, o aviso **"esta sala tem N tickets
  abertos"** (N = tamanho da lista que ele vê); quando está vazia, "nenhum
  ticket aberto nesta sala" e o botão de abrir ticket novo com o local já
  preenchido.
- A lista é **tempo real**: entra e sai ticket por "ticket criado" e "ticket
  atualizado" (categorias local, estado, grupo, responsável), com a mesma
  limitação de uma rebusca a cada 2 s. A presença (§5) aparece na lista como
  nas filas.
- "Assumir" é uma mudança de responsável com a versão que a página mostrava
  (§6): se outro agente assumiu antes, o agente recebe o conflito e vê quem
  assumiu; nada é sobrescrito.
- **Ticket novo numa sala com tickets**: ao abrir ticket novo pela página da
  sala (ou escolher, na tela do agente, uma sala que tem tickets abertos que
  ele lê), o formulário mostra o aviso "esta sala já tem N tickets abertos",
  com os links, para evitar duplicata ou sugerir o vínculo a um incidente
  (Δ35). O aviso não bloqueia a criação.
- Esse aviso é **da tela**, não uma notificação do §7: não entra no sino, no
  feed nem no e-mail.
- O **solicitante** que abre o mesmo QR vê só o formulário (Δ33). Ele nunca vê
  a lista nem a contagem de tickets da sala, que podem ser de outras pessoas.

---

## 11. Abordagens comparadas

| Projeto | Abordagem observada (documentação) | Prós | Contras |
|---|---|---|---|
| **Zammad** | Servidor de websocket separado, com dependência de cache/pub-sub; presença por avatar no ticket (vendo, em outra aba, editando) e aviso de conflito; rascunho salvo automaticamente; notificações in-app com contador e limpeza automática; preferências separando app e e-mail | presença rica e clara; notificações maduras | processo e porta extras no proxy; não está documentado se cai para polling [evidência pendente: R-01] |
| **Chatwoot** | Websocket autorizado por token, com um tipo de token para agentes (todos os eventos da conta) e outro para contatos (só a própria sessão); eventos de conversa, mensagem, digitação, presença e notificação; sinal de vida a cada ~30 s; caixa de notificações; som e push | catálogo de eventos completo; separação de tokens mostra que o canal precisa ser filtrado | o token de agente recebe **todos** os eventos da conta, sem filtro por time documentado; marcado como experimental |
| **FreeScout** | Sem conexão persistente: a página pergunta ao servidor periodicamente se há eventos; os eventos esperam no servidor; indicador de "respondendo" no avatar; menu de notificações e push do navegador | simples, atravessa qualquer proxy | latência de segundos; custo por agente ocioso [evidência pendente: R-01] |
| **osTicket** | Colisão por **bloqueio** do ticket (ao abrir ou ao agir), com expiração por inatividade; notificação essencialmente por e-mail | impede resposta dupla de forma dura | trava trabalho legítimo; exige expiração; sem tempo real nem notificação in-app documentados [evidência pendente: R-02, R-03] |
| **Znuny** | Recarga periódica opcional das visões (desligada por padrão); colisão por bloqueio ao abrir a resposta; notificação com transportes e-mail, serviço web e "atividade" na interface | modelo de notificação flexível | sem push documentado; bloqueio com os mesmos contras do osTicket |
| **UVdesk** | Nada documentado sobre tempo real, presença ou notificação in-app; e-mail por workflows | — | ausência total [evidência pendente: R-01..R-03] |
| **Frappe Helpdesk** | O framework tem servidor de tempo real com salas por usuário e por documento; o Helpdesk documenta só e-mails; relato antigo de que era preciso recarregar a página | infraestrutura de salas por documento é boa base | uso no Helpdesk incerto [evidência pendente: R-01, R-03] |

**Escolha do PantherDesk e motivos**

| Tema | Escolha | Por quê |
|---|---|---|
| Transporte | SSE + polling no mesmo contrato, também no widget de chat | o tráfego é quase todo servidor → cliente (as ações já vão pela API); SSE usa HTTP comum, atravessa proxy sem configuração especial e tem retomada por último id embutida; o chat do MVP é assíncrono, e as mensagens do visitante vão por pedido comum, então websocket não é necessário |
| Conteúdo do evento | só ids e versão ("algo mudou") | a permissão é aplicada uma vez, na API; o canal não vira um segundo caminho de leitura (lição dos dois tipos de token do Chatwoot) |
| Filtro | por permissão no momento da entrega; widget com escopo da própria sessão | ninguém aprende sobre movimento em grupos alheios; o visitante só vê o próprio chat (separação de canais como no Chatwoot, mas com filtro também do lado do agente) |
| Colisão | presença (modelo Zammad) + concorrência otimista para campo e estado; aviso não bloqueante para mensagens; sem bloqueio | correto mesmo com o canal fora; não trava trabalho como os bloqueios do osTicket e do Znuny; segue D01 |
| Notificações | lista própria com lida/não lida, agrupamento e limpeza (modelo Zammad), e-mail opcional por tipo, uma por pessoa por evento | cobre o MVP sem push; menções e seguidores atendem a operação EARJ (spec 13) |
| Público "do grupo" | ativos com escrita, exceto o autor, com recurso aos admins se vazio | um único conjunto para todos os avisos de fila e de SLA (D09, spec 01 §2, spec 04) |
| Push, som, digitação do visitante | roadmap | exigem permissão do navegador ou bidirecionalidade; reaproveitarão os mesmos eventos |

---

## 12. Casos de teste (critérios de aceite)

Atores: `ag1` e `ag2` (grupo N1, escrita), `ag3` (grupo Financeiro, escrita),
`apoio1` (agente de apoio: leitura em todos os grupos), `admin`, `gestor`
(destinatário do escalonamento de SLA), solicitantes `ana` e `bia` (org. Acme),
`cris` (sem org.). Salvo indicação, ag1 e ag2 estão com a interface aberta, o
canal SSE conectado, e a conta usa o padrão
"nota interna" para respostas a e-mail de notificação.

### 12.1 Canal de eventos e permissões
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RT-01 | ag1 vendo a fila do N1 | ag2 cria ticket para ana no N1 | ag1 recebe "ticket criado" com id e versão, sem assunto nem corpo; a fila de ag1 mostra o ticket em até 2 s sem recarregar |
| RT-02 | ag3 conectado | ag2 cria ticket no N1 | ag3 não recebe nenhum evento |
| RT-03 | ticket #1000 no N1, aberto na tela de ag1 | ag2 muda a prioridade para alta | ag1 recebe "ticket atualizado" com categoria prioridade e nova versão, sem o valor; a tela rebusca pela API e mostra "alta" |
| RT-04 | #1000 aberto na tela de ag1 | ag2 move #1000 para o grupo Financeiro | ag1 recebe um último "ticket atualizado"; a rebusca devolve 404; o ticket some da tela e da fila; ag3 passa a receber eventos de #1000 |
| RT-05 | #1000 no N1 | ana responde por e-mail | ag1 recebe "mensagem nova" com id do ticket, id da mensagem e visibilidade pública; a conversa mostra a mensagem buscada pela API |
| RT-06 | #1000 no N1 | ag2 escreve nota interna | ag1 recebe "mensagem nova" com visibilidade nota interna; ag3 não recebe nada |
| RT-07 | ag1 com 2 abas abertas | ag1 muda o estado na aba A | a aba B atualiza; a aba A não rebusca (reconhece a versão que gravou) |
| RT-08 | ag1 conectado | admin desativa ag1 | o servidor encerra a conexão em até 60 s; a reconexão recebe 401; a interface vai para o login, sem laço de reconexão |
| RT-09 | automação muda 3 campos de #1000 em 300 ms | — | ag1 recebe 1 ou mais "ticket atualizado"; o último tem a versão final e a união das categorias; a interface faz no máximo 1 rebusca da fila a cada 2 s |

### 12.2 Reconexão e polling
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RT-10 | ag1 recebeu o evento de id E | a rede de ag1 cai por 30 s; nesse tempo ag2 faz 3 mudanças no N1 | ao reconectar com o último id E, ag1 recebe os 3 eventos, em ordem, uma única vez cada |
| RT-11 | ag1 offline por 20 min | reconecta com o último id | o servidor envia "recarregar"; a interface recarrega fila e ticket aberto pela API e continua do id atual |
| RT-12 | proxy que não mantém SSE | ag1 abre a interface | após 3 falhas, a interface passa a polling a cada 20 s; mudanças de ag2 aparecem em até ~20 s; nova tentativa de SSE a cada 5 min |
| RT-13 | ag1 em polling, 250 eventos pendentes desde o cursor | ag1 faz o polling | resposta de "cursor antigo demais"; a interface recarrega tudo |
| RT-14 | ag1 sem conexão nenhuma por 61 s | — | aviso "você está offline"; some quando reconectar |
| RT-15 | ag1 recebe de novo um "ticket atualizado" com versão já exibida | — | ignorado; nenhuma rebusca |
| RT-16 | servidor reiniciado com 20 agentes conectados | — | as reconexões se espalham no tempo (recuo com variação); nenhum agente perde evento dentro da janela de 15 min |

### 12.3 Presença
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RT-20 | ag1 e ag2 abrem #1000 | — | cada um vê o avatar do outro como "vendo"; nenhum vê o próprio |
| RT-21 | idem | ag2 começa a escrever resposta pública | ag1 vê ag2 como "respondendo" e o aviso "ag2 também está respondendo" no topo do editor |
| RT-22 | idem | ag2 escreve nota interna | ag1 vê a marca "nota" no avatar de ag2, sem aviso no editor |
| RT-23 | ag2 com #1000 aberto | o navegador de ag2 trava (sem "saí") | o avatar de ag2 some para ag1 em até 75 s |
| RT-24 | ag3 tenta enviar sinal de presença em #1000 (N1) | — | recusado com 404; ninguém vê ag3 |
| RT-25 | ag2 com #1000 em 2 abas, uma vendo e outra respondendo | — | ag1 vê um avatar só, como "respondendo" |
| RT-26 | presença ativa em #1000 | consultar o histórico de auditoria | nenhum evento de presença registrado |
| RT-27 | fila "sem responsável" com #1001, #1002, #1003; ag2 está **vendo** #1002 | ag1 entra em modo sequência e envia em #1001 | abre #1003; aviso de que #1002 foi pulado |
| RT-28 | idem, mas ag2 tem #1002 só **em segundo plano** | ag1 envia em #1001 | abre #1002 (segundo plano não faz pular); ag1 vê o avatar esmaecido de ag2 |
| RT-29 | ag2 com #1000 numa aba interna inativa e #1001 na aba interna ativa | — | ag1, em #1000, vê ag2 "em segundo plano"; em #1001, "vendo" |

### 12.4 Concorrência otimista
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RT-30 | ag1 e ag2 carregam #1000 (aberto) na versão 7 | ag2 muda o estado para pendente (v8); ag1 envia resposta pública com "enviar com estado: resolvido", esperando v7 | ag1 recebe conflito com versão atual 8 e resumo "estado alterado por ag2"; nada é gravado (nem a mensagem); o rascunho de ag1 continua no editor |
| RT-31 | após RT-30 | ag1 revisa e escolhe "enviar mesmo assim" | a resposta e a mudança para resolvido são gravadas com versão esperada 8; versão final 9 |
| RT-32 | ag1 com #1000 (aberto) na v7, editor com texto | ana responde por e-mail; ag1 envia resposta pública **sem** mudança de estado | a resposta de ag1 é gravada sem conflito; a versão continua 7 (D01); antes do envio, o editor de ag1 mostrava "ana respondeu enquanto você escrevia"; o e-mail de ana nunca é recusado |
| RT-33 | ag1 com #1000 na v7 | ag2 adiciona etiqueta (v8); ag1 adiciona nota interna | a nota é gravada; nenhum conflito; a versão continua 8 |
| RT-34 | ag1 e ag2 na v7 | os dois mudam o responsável ao mesmo tempo | exatamente um é gravado (v8); o outro recebe conflito; nunca os dois |
| RT-35 | ag1 e ag2 na v7 | ag2 muda a prioridade; ag1 muda o estado (campo diferente) esperando v7 | ag1 recebe conflito; ao reenviar, só o estado é enviado e a prioridade de ag2 é preservada |
| RT-36 | ag1 com canal SSE fora | ag2 altera um campo de #1000; ag1 salva uma mudança de campo | conflito mesmo sem evento recebido (a correção não depende do tempo real) |
| RT-37 | ag1 com #1000 na v7 | ag2 muda a prioridade (v8); ag1 envia resposta pública pura, informando v7 | gravada sem conflito; versão continua 8; a resposta do servidor não lista mensagens novas |
| RT-38 | #1000 **pendente** na v7, aberto na tela de ag1 | ana responde por e-mail (o ticket volta para aberto, v8); ag1 muda a prioridade esperando v7 | conflito; o resumo indica a categoria estado e a mensagem nova de ana |

### 12.5 Notificações in-app e e-mail
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RT-40 | #1001 sem responsável | ag2 atribui a ag1 | ag1 recebe notificação "atribuído a você"; contador +1; ag2 não recebe nada |
| RT-41 | #1001 sem responsável | ag1 atribui a si mesmo | nenhuma notificação |
| RT-42 | ag1 responsável por #1001 | ana responde 3 vezes antes de ag1 ler | uma única notificação "resposta no seu ticket" com contagem 3, no topo |
| RT-43 | ag1 responsável por #1001 (pendente) | chega resposta automática de ausência (spec 02) | nenhuma notificação |
| RT-44 | ag1 com 2 notificações não lidas de #1001 | ag1 abre #1001 | as duas ficam lidas; contador atualiza em todas as abas |
| RT-45 | ag1 com notificação lida | marca como não lida | volta a contar |
| RT-46 | ag1 com notificação de #1001 | #1001 é movido para Financeiro | a notificação some da lista de ag1; o assunto não aparece |
| RT-47 | #1002 pendente sem responsável, retorno em D; N1 tem ag1 e ag2 (escrita) e apoio1 (leitura) | o relógio passa de D | o ticket volta para aberto; ag1 e ag2 recebem 1 notificação "data de retorno atingida" cada; apoio1 não recebe; a tarefa rodando 2× não duplica |
| RT-48 | SLA de 1ª resposta com aviso antes do vencimento (spec 05), ag1 responsável | o limiar é atingido | ag1 recebe "SLA: aviso"; ao vencer, "SLA: violação" |
| RT-49 | ag1 com e-mail ligado para "atribuído a você" | ag2 atribui #1003 a ag1; ag1 não lê em 2 min | 1 e-mail sai com `Auto-Submitted: auto-generated`, cabeçalho de laço, número, assunto, link e a linha "responder a este e-mail adiciona uma nota interna" |
| RT-50 | idem | ag1 lê a notificação no app 1 min depois | nenhum e-mail sai |
| RT-51 | ag1 com e-mail desligado para "resposta no seu ticket" | ana responde | só a notificação in-app |
| RT-52 | ag1 recebe o e-mail de RT-49 | responde a ele do endereço cadastrado | a resposta entra em #1003 como **nota interna** de ag1 (D02, spec 02 §5); ana não recebe nada; com a conta no padrão "pública", entraria como resposta pública |
| RT-53 | e-mail de notificação de "resposta no seu ticket" | — | contém trecho da mensagem pública de ana; nunca contém texto de nota interna |
| RT-54 | notificação lida há 30 dias e 1 h | limpeza diária roda | apagada; rodar de novo não tem efeito |
| RT-55 | webhook desativado automaticamente (spec 10) | — | todos os admins recebem a notificação in-app e o e-mail; agentes não |
| RT-56 | rodízio desligado no N1 | ana abre ticket pelo portal no N1, sem responsável | ag1 e ag2 recebem "ticket na fila do grupo" (D09); apoio1 não; e-mail só para quem o ligou |
| RT-57 | idem | ag2 cria ticket no N1 sem responsável | ag1 recebe "ticket na fila do grupo"; ag2 não (D12) |
| RT-58 | ag1 e ag2 desativados (N1 sem agente ativo com escrita) | ana abre ticket no N1 sem responsável | os admins recebem "ticket na fila do grupo"; num cenário em que ag1 e ag2 estão só marcados como ausentes, os dois recebem normalmente |
| RT-59 | ag2 segue #1000 de ana (responsável ag1) | ag1 escreve nota interna | ag2 recebe "ticket que você segue"; ag1 não recebe nada; ana não recebe nada |
| RT-60 | ag2 segue #1000 | ag1 envia resposta pública | ag2 recebe "ticket que você segue" no app; o e-mail a ana **não** tem ag2 em Cc |
| RT-61 | #1000 no N1, responsável ag1 | ag1 escreve nota "@apoio1 pode ver?" | apoio1 recebe "menção" e passa a seguir #1000; o e-mail de menção (se ligado) não traz o texto da nota |
| RT-62 | ag3 sem acesso ao N1 | ag1 escreve nota em #1000 mencionando @ag3 | a nota é gravada; ag1 vê aviso de que ag3 não tem acesso; ag3 não é notificado nem vira seguidor |
| RT-63 | — | ag1 escreve "@ag2" numa resposta pública de #1000 | a menção não é convertida; aviso ao ag1 antes de enviar; ag2 não recebe "menção" |
| RT-64 | ag2 é responsável por #1000 e seguidor | ag1 escreve nota mencionando @ag2 | ag2 recebe **uma** notificação, do tipo "menção" |
| RT-65 | ag1 menciona a si mesmo numa nota | — | nenhuma notificação |
| RT-66 | #1000 em espera, responsável ag1, seguidor ag2, conversa paralela aberta com um fornecedor | o fornecedor responde | ag1 e ag2 recebem "resposta em conversa paralela"; "mensagem nova" com visibilidade conversa paralela só para agentes; o ticket volta para aberto (v+1); ana e o widget não recebem nada |
| RT-67 | #1000 no N1, responsável ag1 | ag1 encaminha com retorno para Financeiro | ag3 recebe "ticket na fila do grupo"; ag1 não recebe nada |
| RT-68 | após RT-67 | ag3 usa "devolver" com nota | ag1 recebe "ticket devolvido a você"; ag3 não recebe nada |
| RT-69 | após RT-67 | admin transfere #1000 para outro grupo sem retorno | ag1 recebe "encaminhamento cancelado" |
| RT-70 | calendário seg–sex 07:00–17:00 (America/Sao_Paulo); resolução 8 h úteis, aviso "1 hora útil antes", escalonamento "8 horas úteis depois" ao gestor; ticket criado seg 2026-11-09 09:00 (12:00Z), responsável ag1, sem resolução | o relógio passa | ag1 recebe "SLA: aviso" seg 16:00 (19:00Z), uma vez; "SLA: violação" seg 17:00 (20:00Z); o gestor recebe "SLA: escalonamento" ter 2026-11-10 15:00 (18:00Z) (07:00 + 8 h úteis), uma vez |
| RT-71 | #1001 de ana, responsável ag1 | um remetente que não é solicitante nem participante responde no encadeamento (spec 02 §5) | ag1 recebe "resposta no seu ticket" com a marca "remetente não confirmado" |
| RT-94 | #1000 **pendente** no N1, responsável ag1; ag1 e ag2 conectados | ag1 encaminha com retorno para Financeiro; depois ag3 muda a prioridade | ag1 e ag2 recebem "ticket atualizado"; a rebusca dá 200 (não 404); #1000 aparece nas listas do N1 com a marca "encaminhado" e estado aberto (não "encaminhado" como estado); a mudança de ag3 também chega a ag1 e ag2 (D23, D24) |
| RT-95 | ag3, único agente com escrita no Financeiro, marcado como **ausente** | ag1 encaminha #1000 com retorno para Financeiro | ag3 recebe "ticket na fila do grupo"; com o rodízio ligado, ele não escolhe ag3; os admins não recebem (D27) |
| RT-96 | ag3 é o único agente ativo com escrita no Financeiro | ag3 cria ticket no Financeiro sem responsável | ag3 não recebe nada (D12); o público fica vazio e os admins recebem "ticket na fila do grupo" (D27) |

### 12.6 Widget de chat
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RT-80 | bia identificada no widget; ticket #1050 de canal chat, responsável ag1 | ag1 envia resposta pública | o widget recebe "mensagem pública nova" só com ids e mostra a resposta em até 2 s, buscada pela API do canal |
| RT-81 | idem | ag1 escreve nota interna em #1050 | o widget não recebe nada |
| RT-82 | idem | ag1 começa a escrever resposta pública | o widget mostra que ag1 está escrevendo; some quando ag1 envia ou apaga o texto |
| RT-83 | idem | ag1 escreve nota interna (presença "escrevendo nota") | o widget não mostra indicador |
| RT-84 | widget de bia aberto e visível; ag2 vendo #1050 | ag1 responde em #1050 | a resposta fica lida; ag1 e ag2 recebem "mensagem lida" e a tela mostra "lido" |
| RT-85 | bia com e-mail, widget fechado | ag1 responde às 10:00:00 | às 10:02:00, 1 e-mail com a resposta (spec 02 §9) |
| RT-86 | bia com o widget aberto e visível | ag1 responde às 10:00:00 | a resposta fica lida; nenhum e-mail sai; ag1 vê "lido" |
| RT-87 | bia com e-mail, widget fechado | ag1 responde às 10:00:00 e às 10:00:30 | um e-mail por resposta, às 10:02:00 e às 10:02:30; cada resposta sai uma vez só |
| RT-88 | bia com e-mail, widget fechado | ag1 envia resposta pública que resolve #1050 | às 2 min, um único e-mail com a resposta e o convite da pesquisa; ao abrir o widget, bia vê a mesma pesquisa; nenhum segundo convite |
| RT-89 | bia com endereço inválido, widget fechado | ag1 responde | nenhum e-mail; a resposta aparece quando bia voltar ao widget |

### 12.7 Página inicial e filas
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RT-90 | ag1 com a página inicial aberta | ag1 é mencionado numa nota de #1000 | o feed mostra a menção como não lida em até 2 s; o sino conta +1 |
| RT-91 | após RT-90 | ag1 marca a menção como lida no sino | o item do feed fica lido em todas as abas |
| RT-92 | ag1 vendo a contagem da fila salva "sem responsável nos meus grupos" = 3 | ag2 assume um desses tickets | a contagem passa a 2 sem recarregar, com no máximo 1 rebusca a cada 2 s |
| RT-93 | ag1 com a fila "resolvidos nas últimas 12 h" aberta; ticket resolvido há 11 h 59 min | passam 2 min | na recontagem do minuto seguinte, o ticket sai da fila; nenhum evento de tempo real foi emitido por isso |
| RT-113 | ag1 com a fila "Quase escalando" aberta às 10:00 (dentro do expediente); #1006 com próximo prazo às 11:01, sem pausa no meio | passa 1 min | às 10:00 #1006 não está na fila (faltam 61 min úteis); na recontagem de 10:01 (faltam 60 min) entra; o selo mostra "vence em 1 h"; nenhum evento de tempo real foi emitido por isso (Δ37) |
| RT-114 | e-mail de RT-49 | ag1, sem sessão, clica no link do ticket | o link está no domínio da conta (help.earj.com.br), no caminho da área do agente; ag1 passa pelo login com Google e volta a #1003, não à página inicial (Δ31, Δ32) |
| RT-115 | ag1 entrou com Google e está conectado | (a) admin desativa ag1; (b) um cliente tenta abrir o canal com uma credencial do Google no lugar da sessão | (a) como RT-08: conexão encerrada em até 60 s e 401 na reconexão; (b) 401; o canal só aceita a sessão do PantherDesk |

### 12.8 Avisos de montagem de evento (Δ34)
Calendário do grupo Eventos: seg–sex 07:00–17:00, America/Sao_Paulo (UTC−3),
sem feriados no período. `ev1` e `ev2`: grupo Eventos, escrita. Datas: 2026-11-04
é quarta; 2026-11-09, segunda; 2026-11-12, quinta; 2026-11-14, sábado.

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RT-97 | ticket de evento #1300 no Eventos, responsável ev1, criado qua 2026-11-04 10:00; montagem qui 2026-11-12 14:00 | o relógio passa | ev1 recebe "evento: montagem em 2 dias úteis" ter 2026-11-10 07:00 (10:00Z) e "evento: montagem hoje" qui 2026-11-12 07:00 (10:00Z), uma vez cada; ev2 não recebe nada; e-mail sai para ev1 (padrão ligado) se não ler em 2 min |
| RT-98 | idem, sem responsável | o relógio passa | ev1 e ev2 recebem cada um os dois avisos nos mesmos momentos; ag1 (N1) não recebe nada |
| RT-99 | #1301, responsável ev1, montagem **sáb** 2026-11-14 09:00 | o relógio passa | "montagem em 2 dias úteis" qui 2026-11-12 07:00 (sex 11-13 é o 1º dia útil anterior, qui 11-12 o 2º); "montagem hoje" sex 2026-11-13 07:00, abertura do último dia útil anterior (spec 05 §7.14, caso equivalente SL-78), uma vez, para ev1 (revisto em v0.3, D41: o instante é da spec 05) |
| RT-100 | #1300 de RT-97, aviso de 2 dias úteis já emitido ter 11-10 07:00 | ev1 muda a montagem, ter 2026-11-10 09:00, para seg 2026-11-16 14:00 | o "montagem hoje" de qui 11-12 não sai; novo "montagem em 2 dias úteis" qui 2026-11-12 07:00 (sex 11-13 é o 1º, qui 11-12 o 2º); novo "montagem hoje" seg 2026-11-16 07:00; cada um uma vez |
| RT-101 | sem responsável | (a) solicitante cria #1302 qua 2026-11-11 15:00 com montagem qui 2026-11-12 14:00; (b) cria #1303 qui 2026-11-12 09:00 com montagem às 14:00 do mesmo dia | (a) o ticket nasce dentro da janela do aviso de 2 dias úteis (ter 11-10 07:00 já passou): "evento: montagem em 2 dias úteis" sai **na hora**, qua 2026-11-11 15:00 (18:00Z), uma vez, para ev1 e ev2; "montagem hoje" sai qui 2026-11-12 07:00 (10:00Z); (b) os dois instantes já passaram: sai só "montagem hoje", na hora, qui 09:00 (12:00Z) (revisto em v0.3, D41) |
| RT-102 | #1300 de RT-97 em espera desde qua 2026-11-04 11:00 | o relógio passa | os dois avisos saem normalmente: em espera não suspende o compromisso com a montagem |
| RT-103 | #1304, responsável ev1, montagem qui 2026-11-12 14:00, resolvido seg 2026-11-09 16:00; a tarefa de avisos roda duas vezes por minuto | o relógio passa | nenhum aviso; nenhuma notificação duplicada em nenhum caso desta tabela |
| RT-116 | #1300 de RT-97 (montagem qui 2026-11-12 14:00, sem a marca "pronto"); ag1 com a fila "Quase escalando" aberta e ev2 com #1300 aberto na tela | (a) o relógio chega a qui 13:00 (16:00Z); (b) qui 13:10, ev1 põe a marca "pronto" | (a) na recontagem de 13:00 (falta 1 hora útil) #1300 entra na fila, sem evento de tempo real por isso; (b) ev2 recebe "ticket atualizado" com a categoria evento e nova versão; a rebusca mostra o selo "pronto"; na recontagem seguinte da fila, #1300 sai (D40, D44) |
| RT-117 | #1305 de evento no Eventos, responsável ev1, criado por ana pelo portal seg 2026-11-09 10:00 (13:00Z), sem resposta; política com 1ª resposta de 120 min úteis e aviso "1 hora útil antes" | o relógio passa | ev1 recebe "SLA: aviso" seg 11:00 (14:00Z) e "SLA: violação" seg 12:00 (15:00Z), uma vez cada; nenhum aviso de resolução (D40) |

### 12.9 Incidente pai (Δ35)
#1100 é incidente pai no N1, responsável ag1. Filhos: #1101 (ana, idioma PT,
e-mail, responsável ag2), #1102 (bia, idioma EN, canal chat, sem
responsável), #1104 (cris, grupo Financeiro, responsável ag3).

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RT-104 | ag2 e ag3 conectados; widget de bia aberto | ag1 envia resposta pública em #1100 aplicando uma macro com variantes PT e EN (Δ36) | ag2 recebe "mensagem nova" de #1100, #1101 e #1102; ag3 recebe só a de #1104 (nada de #1100); o widget de bia recebe "mensagem pública nova" e mostra a variante EN; ag2 recebe **uma** notificação "incidente", apontando para #1100; ag3 recebe uma, apontando para #1104, sem número nem assunto de #1100; ag1 não recebe nada |
| RT-105 | ag2 segue #1100 e é responsável por #1101 | ag1 escreve resposta pública em #1100 | ag2 recebe exatamente uma notificação, do tipo "incidente"; nenhuma "ticket que você segue" |
| RT-106 | widget de bia fechado; bia com e-mail válido | ag1 resolve #1100 com resposta pública | #1101, #1102 e #1104 recebem "ticket atualizado" (resolvidos); o widget de bia não recebe "pesquisa disponível"; 2 min depois sai **um** e-mail a bia com a resposta e sem convite de pesquisa |
| RT-107 | #1105 (N1, aberto, responsável ag2, versão 4); ag1 com #1100 aberto na tela | ag1 vincula #1105 a #1100 | #1105: "ticket atualizado" com a categoria incidente, versão 5; ag1 recebe "filhos alterados" de #1100, cuja versão não muda, e a tela mostra 4 filhos; ag2 recebe "incidente" |
| RT-108 | após RT-104 | ana responde por e-mail em #1101 | ag2 recebe "resposta no seu ticket" em #1101; ninguém recebe "incidente" por isso |
| RT-118 | #1101 já **resolvido** (individualmente) por ag2; ag2 conectado | ag1 envia resposta pública em #1100 | ag2 recebe "mensagem nova" de #1101; #1101 continua resolvido (nenhum "ticket atualizado" de #1101 por isso); ag2 recebe **uma** notificação "incidente" (D46) |
| RT-119 | #1102 sem responsável; ag2 conectado | ag1 resolve #1100 com resposta pública | #1102 recebe "ticket atualizado" com as categorias responsável e estado: ag1 passa a responsável e o ticket fica resolvido (D47); ag1 não recebe "atribuído a você" (atribuição ao próprio autor, D12) nem "ticket na fila do grupo" |

### 12.10 Página da sala pelo QR (Δ33)
Sala B204 (Barra). #1401 (N1, aberto, B204), #1402 (N1, pendente, B204, versão
5), #1403 (Financeiro, aberto, B204), #1404 (N1, resolvido, B204).

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| RT-109 | ag1 (só N1) com sessão | abre o endereço do QR de B204 | página da sala com #1401 e #1402 e o aviso "esta sala tem 2 tickets abertos"; #1403 (outro grupo) e #1404 (resolvido) não aparecem nem contam |
| RT-110 | ag1 com a página de B204 aberta | ag2 cria #1405 no N1 com local B204; depois muda o local de #1401 para B110 | #1405 aparece em até 2 s sem recarregar (aviso: 3); depois #1401 sai (aviso: 2); no máximo 1 rebusca a cada 2 s |
| RT-111 | ag1 e ag2 com a página de B204 aberta | ag2 assume #1402 (versão 6); ag1 clica em "assumir" em #1402 com a versão 5 | ag1 recebe conflito e vê que ag2 assumiu; #1402 continua com ag2 |
| RT-112 | ag1 na página de B204 (2 abertos) | ag1 abre ticket novo pela página e envia; ana abre o mesmo QR | o formulário de ag1 mostra "esta sala já tem 2 tickets abertos", com os links, e o local B204 preenchido; o ticket é criado; o aviso não gera notificação no sino nem e-mail; ana vê só o formulário, sem lista nem contagem |

---

## 13. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Protocolo, formato do evento (dados completos vs. invalidação), latência | documentação de 3 projetos; inferência nos outros | R-01 em todos |
| Atualização da fila sem dono sem recarregar | inferido | R-01 |
| Comportamento quando o websocket cai | não documentado | R-01 (variante com proxy sem upgrade) |
| Frequência e custo do polling | documentado só o mecanismo (FreeScout) | R-01 |
| O que cada agente vê com dois no mesmo ticket; o que dispara o aviso de conflito; se o bloqueio impede a resposta ou só avisa | documentação parcial | R-02 |
| Digitação entre agentes na edição comunitária do Chatwoot | página de produto | R-02 |
| Canal e tempo da notificação de atribuição | documentação parcial | R-03 |
| Notificação "atividade" sem recarregar (Znuny); notificações in-app no Frappe Helpdesk | não documentado | R-03 |
| Filtro de eventos por permissão de grupo | não documentado em nenhum projeto | R-01 com agent3 conectado; P-01 |
| Seguidores, menções, encaminhamento com retorno, widget de chat | requisitos de cliente (spec 13) | nenhuma (comportamento definido por nós) |
| Avisos de montagem, incidente pai, página da sala pelo QR, selo de prazo | requisitos de cliente (spec 13 Δ33–Δ37) | nenhuma (comportamento definido por nós) |

---

## 14. Questões abertas para o implementador

1. **Muitas abas**: navegadores limitam conexões por domínio em HTTP/1.1. Servir
   a aplicação com HTTP/2 resolve; alternativa é uma aba compartilhar a conexão
   com as outras. Escolher na implementação.
2. Janela de retomada (15 min), intervalos (25 s, 30 s, 75 s, 20 s), atraso do
   e-mail do chat (2 min), limites de conexão (10 por agente, 5 por token de
   conversa) e retenção (30/90 dias) são propostas; registrar nas decisões do
   projeto se mudarem.
3. **Precedência entre tipos** (§7.3) e padrões de e-mail por tipo (§8) são
   propostas de produto; confirmar com a operação EARJ depois do piloto.
4. **"Lido" no chat** (§9.2): basta o widget estar aberto e visível, sem medir
   rolagem. Se a operação quiser precisão maior (mensagem efetivamente na área
   visível), a regra muda só no widget.
