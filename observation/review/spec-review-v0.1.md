# Revisão das specs PantherDesk — v0.1

Data: 2026-10-26. Escopo: `specs/00-produto.md`, `specs/01` a `specs/12`,
`specs/LICENSES.md`, `specs/fixtures/email/README.md` e as 16 fixtures `.eml`
(lidas para conferir os casos EM-xx). Nenhum arquivo de spec foi alterado.

Base de autoridade: spec 01 (vocabulário, estados, transições, mescla,
auditoria) e spec 02 (e-mail). Spec 06 é a referência de papéis e de acesso
por grupo (nenhum / leitura / escrita).

Severidade:
- **alta**: a implementação sai errada ou casos de teste falham, qualquer que
  seja a escolha do implementador;
- **média**: ambiguidade que obriga o implementador a adivinhar;
- **baixa**: redação, nomenclatura, dados de teste inconsistentes sem efeito
  de comportamento.

Resumo de contagens:

| Seção | alta | média | baixa | total |
|---|---|---|---|---|
| 1. Contradições entre specs | 17 | 27 | 2 | 46 |
| 2. Valores esperados errados | 1 | 3 | 1 | 5 |
| 3. Casos que contradizem a própria spec | 2 | 2 | 4 | 8 |
| 4. Vocabulário fora da spec 01 | 0 | 6 | 6 | 12 |
| 5. Clean room | 0 | 0 | 4 | 4 |
| 6. Escopo do MVP | 1 | 3 | 3 | 7 |
| 7. Questões abertas | — | — | — | 77 questões (ver tabela) |

---

## 1. Contradições entre specs

**1.1 — alta — Admin pode ser responsável?**
- 04 §2.2: "Para ser responsável, porém, o admin precisa ser membro com
  *trabalhar* no grupo"; AS-13 espera recusa quando o admin (sem associação)
  atribui a si mesmo.
- 06 §2: admin tem "Escrita em todos os grupos, implícita e não removível";
  06 §4, linha "Ser responsável": admin ✓; 01 §2 exige só "acesso de escrita
  ao grupo (spec 06)".
- Efeito: AS-13 falha se 06 for seguida; a invariante 04 §2.3 fica errada para
  admin.

**1.2 — alta — Tickets da organização: valores e "gestor".**
- 06 §5.2: dois valores, **nenhum** (padrão) ou **membros veem os tickets da
  organização**; "Não há 'gestor da organização' no MVP (roadmap)"; 06 §14
  repete que gestor é pós-MVP.
- 07 §8.1: três valores, **desligado / gestores / todos os membros**; KB-70
  testa o modo "gestores"; 07 §12 Q1(b) assume a marca "gestor da
  organização". 08 BU-73 usa o rótulo "todos os membros".

**1.3 — alta — Ação "meu problema foi resolvido" no portal.**
- 01 §4.2 (nota ⁴ na matriz: aberto/pendente → resolvido pelo solicitante) e
  TL-18: existe no MVP, gera mensagem de sistema e evento de origem
  solicitante.
- 07 §8.4: "O solicitante **não** muda estado diretamente (não há 'fechar' nem
  'resolver' no portal)"; 07 §12 Q4 diz que "fica fora do MVP".
- 06 §4 ("Mudar campos e estado — solicitante: só via resposta") e 10 §4
  ("solicitante não muda estado diretamente") também não preveem a ação; a API
  não tem operação para ela.

**1.4 — alta — Automação com ação de atribuição inválida.**
- 04 §4: "tem **essa ação ignorada** … As outras ações da mesma regra
  continuam"; 04 §8 item 2: automação não pode escolher agente ausente.
- 05 §3.6: "Atomicidade por gatilho … o gatilho **inteiro** é desfeito";
  AU-108 espera G10 desfeito inteiro (sem a etiqueta x). 05 §3.3 ("Definir
  responsável") só exige ativo + escrita, sem a regra de disponibilidade da
  04 §8.

**1.5 — alta — Notificações de fila (ticket sem responsável).**
- 04 §10: ticket criado sem responsável notifica os membros com *trabalhar*
  disponíveis; resposta de cliente em ticket sem responsável notifica o grupo;
  entrada na fila por devolução, transferência etc. notifica o grupo; fallback
  para admins. Casos AS-01, AS-06, AS-23, AS-44, AS-52, AS-53.
- 09 §7.1: lista fechada de tipos in-app do MVP (atribuído a você, resposta no
  seu ticket — **só o responsável** —, SLA, pendência venceu, webhook
  desativado). "ticket novo sem responsável no meu grupo" está no **roadmap**.
- Efeito: AS-01/AS-52 exigem notificações que a 09 não define.

**1.6 — média — Quem é "o grupo" ao notificar.**
- 01 §4.3 e TL-22, 09 §7.1/§12 Q4 e RT-47: "cada agente ativo do grupo".
- 04 §10: membros com *trabalhar* **disponíveis**, exceto quem agiu; vazio →
  admins.
- 05 §7.10/§7.11: "agentes com acesso ao grupo" (inclui leitura).
- Três conjuntos diferentes para o mesmo aviso (pendência vencida, SLA).

**1.7 — alta — Notificação de nota interna.**
- 06 §6.2 ("O e-mail de notificação de nota vai só a agentes com leitura no
  grupo") e PE-34: a nota de ag1 em #1010 notifica "ag1, ag2, admin".
- 09 §7.1 não tem tipo de notificação para nota (menção em nota é roadmap);
  09 §7.2 "**Nunca** notificar o autor da ação"; 04 §10 "exceto quem executou
  a ação". PE-34 inclui o próprio autor ag1.

**1.8 — alta — Resposta do agente a um e-mail de notificação.**
- 02 §5: vira **nota interna por padrão**; a conta pode mudar para "pública".
- 09 §8: o e-mail diz que "responder a este e-mail envia uma resposta pública
  ao cliente"; RT-52 espera resposta pública; 09 §12 Q5 descreve a regra da
  02 como "vira resposta pública".
- 05 §7.6 e SL-55 contam essa resposta como 1ª resposta (só é verdade com a
  conta em "pública"); 11 §3 idem. 06 §14 Q2 diz que a 02 "hoje diz 'pública,
  por padrão'", o que não confere com o texto atual da 02.

**1.9 — alta — Versão do ticket: quando aumenta e quando é exigida.**
- 01 §3: a versão "aumenta a cada mudança de campo ou de estado";
  "Acrescentar mensagem, nota interna ou e-mail recebido **não exige
  versão**".
- 09 §4: aumenta também com mensagem nova, nota interna, e-mail recebido;
  09 §6.2: **enviar resposta pública exige versão esperada** (RT-30, RT-32,
  RT-33 contam v8→v9 por nota).
- 10 §8: pré-condição opcional pela API, mas "Criar mensagem pública aceita a
  mesma pré-condição".
- Efeito: TL-16 e RT-30..33 pressupõem regras diferentes; contagens de versão
  em RT-31/RT-33 dependem de qual vale.

**1.10 — alta — Notas internas em webhooks: três modelos.**
- 06 §6.2: cada webhook tem um **público** — "externo" (padrão) **remove**
  notas e mensagens de sistema internas; "interno" só o admin escolhe. PE-36,
  PE-37.
- 10 §12.3: sem conceito de público; a nota só sai no tipo de evento "nota
  interna criada", e quem não quer **não assina**. WH-07, WH-08.
- 12 §4.5: webhooks recebem notas "apenas com o escopo de notas internas";
  EX-14.

**1.11 — média — Mensagens de sistema internas no webhook "mensagem pública
criada".** 10 §11.3 inclui "ou mensagem de sistema" no evento público, sem
separar as internas (bounce, auto-resposta recebida, aviso de tamanho), que
06 §6.1 manda tratar como notas.

**1.12 — alta — Webhook como ação de automação.**
- 05 §3.3 (ação "Chamar webhook"), §3.6, AU-113 ("webhook enfileirado"): MVP.
- 10 §11.1: "Disparar webhook como **ação de automação** fica no roadmap
  curto".

**1.13 — alta — Token de agente com escopo administração.**
- 06 §7: "Um agente não consegue criar token com esse escopo"; PE-54:
  recusado.
- 10 §3.3: "Um escopo maior que o papel do dono é **aceito na criação**, mas
  só vale até o limite do papel"; AP-08 parte de um token de agente com esse
  escopo e espera 403 no uso.

**1.14 — média — Admin criando token para outra pessoa.** 06 §7: o admin "não
cria tokens para outros". 10 §3.2: token "criado pelo próprio usuário (ou por
admin para uma conta de serviço …)".

**1.15 — média — Tokens depois da reativação do agente.** 10 §3.2 e AP-04:
reativar a pessoa reativa os tokens não expirados. 04 §9.1 item 1: na
desativação, "sessões e tokens **revogados**"; 06 §7 e 10 §3.2 definem
revogação como definitiva e imediata.

**1.16 — alta — Ordem 403 × 404.**
- 06 §8: verificação 2 (papel/escopo para o tipo de operação → 403) **antes**
  da 3 (visibilidade → 404); PE-60 espera 403 para token só leitura escrevendo
  em #1030 invisível.
- 10 §6.2: "primeiro se decide se o recurso é visível … Se não for, 404,
  mesmo que a ação também fosse proibida". Pela 10, PE-60 seria 404.

**1.17 — média — Código de transição recusada.** 01 §4.2: "Transição recusada
devolve erro de validação". 06 PE-13 e 10 §6.2/AP-23: agente comum reabrindo
fechado → **403**. 10 §17 Q7 registra o conflito sem resolução.

**1.18 — alta — Tamanho de página acima de 100.** 08 §10: reduzido para 100 e
a resposta informa (BU-54). 10 §5.1: **400** (AP-32). 08 §2/§4.3 e 10 §5.2
dizem que a busca é exposta pelo mesmo contrato de listagem da API; BU-54 ou
AP-32 falha.

**1.19 — média — Cursor inválido.** 08 §10 e BU-56: "erro de validação" (422
pela tabela 10 §6.2). 10 §5.1: 400. Validade de 24 h só existe na 10.

**1.20 — média — Ordenações e desempate.** 08 §7: seis ordenações (inclui
prioridade, aguardando há mais tempo, prazo de SLA), desempate por **número
do ticket decrescente**. 10 §5.2: só "criado em" e "atualizado em" (outras →
400), desempate pelo **identificador**.

**1.21 — alta — Modelo de identidade de integração.**
- 01 §2 e 12 §5: "Identidade de integração" que **não é Pessoa nem Agente**,
  criada só por admin, com 8 escopos próprios (ler tickets, escrever
  mensagens públicas, ler notas internas, relatórios e exportação …) e lista
  de grupos permitidos; até 2 tokens; validade obrigatória.
- 06 §7: "Só **agentes e admins** criam tokens … Para integrações,
  recomenda-se um agente dedicado"; escopos só leitura / escrita /
  administração.
- 10 §3.2: "conta de serviço, que é um agente comum dedicado à integração".
- 11 §9 usa um "escopo de relatórios" que só existe na 12.

**1.22 — média — Supressão de eco.** 12 §4.6: ligada **por padrão** para
webhook que "pertence a uma identidade de integração". 10 §11.1: webhooks são
do admin; "ignorar eventos causados por um token X" é opção explícita
(WH-14).

**1.23 — média — Catálogo de eventos.** 12 §4.2 inclui alerta e violação de
SLA e "definição de campo alterada", e diz que webhooks consomem o mesmo
fluxo. 10 §11.3 não tem esses tipos e tem tipos que a 12 não lista (artigo
publicado/atualizado/despublicado, teste).

**1.24 — média — Feed de eventos da API.** 12 §4.7, EX-16 e EX-17: feed de
eventos de domínio por 30 dias, com cursor. 10 §4 não tem esse recurso. O
recurso "mudanças desde" (10 §5.3) devolve o estado atual, não eventos, e a
10 §13.6 manda usá-lo para recuperar o que passou dos 14 dias de log.

**1.25 — média — Como a mensagem de integração aparece ao solicitante.** 12 §5
e EX-24: "assinada com o nome da conta". 02 §9: From "{nome da integração} via
{nome da conta}".

**1.26 — média — Canal da mensagem inicial de ticket criado por agente.** 01
§4.6: "canal = o informado pelo agente" (telefone, presencial …). 03 §2.2 e
CH-03: canal `agente`; o meio declarado é só atributo informativo. "telefone"
não é tipo de canal na 03 §2.1.

**1.27 — média — Como um endereço passa a verificado.** 01 §2: "link do portal
usado **ou resposta a um e-mail nosso**". 03 §4.5 e §11 Q2: só por link de
uso único ou login; "o remetente de e-mail é falsificável". CH-41 (cris
responde à confirmação) verifica o endereço ou não, conforme a spec seguida.

**1.28 — média — Confirmação de recebimento: dois mecanismos.**
- 03 §4.6 e §5: confirmação própria do formulário e do portal, com modelo da
  conta, limite próprio de 3 por endereço por 24 h e chave do admin
  (CH-40, CH-42, CH-44).
- 05 §6: "Não há um mecanismo separado"; gatilho padrão de confirmação para
  "evento criado; origem solicitante; canal e-mail **ou portal**".
- Ticket aberto pelo portal recebe duas confirmações, ou o implementador
  precisa escolher uma. 07 KB-73 espera "auto-resposta de criação" no portal.

**1.29 — média — Link da confirmação do formulário.** 03 §4.6: link de uso
único, válido por **7 dias**, que verifica o endereço (CH-46). 07 §7 define só
o link mágico (30 min, uso único) e o link de convidado (30 dias, por
destinatário e por ticket). O terceiro tipo não tem regras na 07.

**1.30 — média — Campos do novo pedido no portal.** 03 §5: "mesmo conjunto de
campos do formulário" (mensagem em texto puro; até 5 arquivos de 10 MB). 07
§8.2: descrição em texto rico sanitizado; anexos com o limite do e-mail
(25 MB).

**1.31 — média — Agente como solicitante no portal.** 06 §2: "No portal, ele vê
esse ticket como qualquer solicitante". 07 §7.1 e KB-57: o link só é enviado
a Pessoa que não seja agente nem admin. O agente solicitante (03 CH-47) não
tem como entrar no portal.

**1.32 — média — Quem edita e publica na base.**
- 06 §4: "Base de conhecimento: editar" ✓ para agente escrita, leitura e
  **nenhum**, sem marca extra; 06 §10 põe "base de conhecimento (publicação)"
  entre as configurações exclusivas de admin.
- 07 §3.4: agente cria e edita rascunho; publicar exige a marca por agente
  "pode publicar na base".
- 10 §3.3/§4: criar, alterar e publicar artigos só com escopo administração,
  que só vale para admin. Um agente com a marca não publica pela API.

**1.33 — média — Organizações: quem cria e altera.** 06 §10: "Organizações e o
opt-in de visibilidade" são configuração exclusiva de admin. 10 §3.3: o
escopo **escrita** "cria e altera … organizações" (vale para agentes).

**1.34 — média — Visões padrão e "aguardando há mais tempo".** 04 §3: "Meus
tickets" (aberto + pendente), "Fila dos meus grupos", "Todos dos meus grupos";
"aguardando há mais tempo" = momento em que entrou na fila. 08 §9.1: "Meus
abertos", "Sem responsável nos meus grupos", "Meus pendentes", "Aguardando
resposta"; 08 §7 define "aguardando há mais tempo" pela última mensagem
pública do cliente.

**1.35 — alta — Desfecho de SLA de resolução depois da reabertura.**
- 05 §7.8 e §7.13: "cumprida" não é final para resolução; na reabertura a
  métrica volta a "em andamento" e "o resultado final é o da próxima
  resolução".
- 11 §6.4 e RM-74: "Conta o **primeiro** desfecho definitivo"; um novo ciclo
  que vence não altera o "cumprida" já contado.
- O % de cumprimento do painel e o estado da métrica no ticket divergem para
  o mesmo ticket.

**1.36 — média — Estados da métrica de SLA.** 05 §7.13: em andamento, pausada,
cumprida, violada, encerrada sem resposta, encerrada por mescla/spam. 11 §3,
§6.4 e §8: definida, cumprida, violada, **cancelada**, em andamento, "sem
SLA". "Cancelada" não existe na 05; as "encerradas" da 05 não existem na 11
(nem como valor da coluna do CSV).

**1.37 — média — "Ticket sem política de SLA".** 11 §4.4, §6.4, RM-43 e RM-70
("3 tickets sem política"). 05 §7.1: sempre existe a política padrão, sem
condições, na última posição. Só é possível ficar "sem meta para a
prioridade". A situação dos testes da 11 não pode ser montada sob a 05.

**1.38 — alta — Desmarcar spam reabre?** 01 §4.1: "Desmarcar tira a marca, mas
**não reabre** o ticket". 11 §5.2 ("voltar para aberto") e RM-52 ("o ticket
volta para aberto … está no backlog como aberto").

**1.39 — alta — Exclusão de ticket.** 01 §3: "Não existe exclusão de ticket no
MVP"; TL-17; 10 §4 ("exclusão não existe na API v1"). 11 §3 (evento "Ticket
excluído"), §5.3, §8 e **RM-53** ("admin exclui um deles em 11-06").

**1.40 — média — Exportação CSV.** 08 §10.1 põe "Exportação de resultados
(spec 11)" no roadmap. 11 §7/§8 e RM-83..RM-87 a exigem no MVP, a partir da
lista de tickets. 06 §6.2 também trata a exportação como caminho existente.

**1.41 — média — Valores do filtro `canal`.** 08 §4.2 aceita email, portal,
api, agente. 03 §2.1 define também `formulario` e `sistema`, e CH-19 roteia
por `formulario`. A busca não filtra o canal do formulário público.

**1.42 — média — Calendário de referência com o mesmo nome e definições
diferentes.** 11 §12: calendário "Comercial" (spec 05), seg–sex 09:00–18:00
**sem almoço**, usado por N1 **e Financeiro**. 05 §9.1: C1 "Comercial SP"
09:00–12:00 e 13:00–18:00; o Financeiro usa P1 com C2 (24x7 UTC). Um seed de
teste comum não satisfaz as duas suítes.

**1.43 — média — Provedor de autenticação local.** 12 §6.5: "e-mail e senha,
regras da spec 06". 07 §7.1: o link mágico é o método base e a senha é
opcional, com regras na própria 07; a 06 não tem regras de senha.

**1.44 — baixa — Prazo de revogação.** 06 §7 e 10 §3.2: revogação imediata
(o próximo pedido recebe 401). 12 §5: revogação de token de integração "em
até 60 s" (EX-25).

**1.45 — baixa — Garantia do tempo real.** 12 §4.4: "O tempo real é melhor
esforço … não depende de reentrega". 09 §3.4: o servidor reenvia os eventos
dos últimos 15 min na reconexão, "pelo menos uma vez".

**1.46 — média — Resposta de participante não confirmado.** 01 §4.3: resposta
pública "do solicitante ou de um participante" em pendente/resolvido reabre.
02 §5: o remetente estranho entra como participante **não confirmado**. Não
está dito se a mensagem dele reabre o ticket, dispara "mensagem do cliente"
(05 §3.1), notifica (04 §10, 09 §7.1) ou afeta o SLA.

---

## 2. Valores esperados errados

Todas as contas de SLA e de métricas das specs 05 e 11 foram refeitas.
Conferidos e **corretos**: SL-01 a SL-15, SL-20 a SL-26, SL-30 a SL-37, SL-40
a SL-42, SL-57; RM-01 a RM-13, RM-20 a RM-29, RM-40 a RM-44, RM-50, RM-60 a
RM-62, RM-70, RM-83. Também conferidos: CH-23, CH-24, CH-42, AS-20, AS-26,
AU-110, AU-111, AU-141, KB-54, KB-59, KB-61, KB-80, TL-02, TL-32, TL-33, EM-41
(decodificação de =E3, =E7, =E0 e =E1), RT-11, RT-13, AP-31, BU-53, WH-28 e o
exemplo de fuso da 11 §4.2. Datas: 2026-10-26 é segunda (fixtures); 11-02 é
segunda, 11-03 terça, 11-07 sábado, 11-20 sexta; 2026-03-29 é domingo (início
do horário de verão de Lisboa, 01:00Z).

Exemplos de contas conferidas: SL-21 (qui 480 + sex 09–12 = 180 + 13–17 = 240
→ 900 consumidos, restam 540 = seg 480 + ter 60 → ter 10:00 = 13:00Z); RM-42
(qui 16:00 → seg 10:00 = 8 + 24 + 24 + 24 + 10 = 90 h = 5400 min; útil 120 +
60 = 180); SL-14 (sáb 12:00Z + 24 h = dom 12:00Z = 13:00 WEST).

**2.1 — alta — BU-24 (08 §12.2): contagem errada.**
- Consulta: `responsavel:nenhum grupo:"Suporte N1"`; esperado: só #1001.
- Base: #1001 (N1, bia, pendente, sem responsável) e **#1003 (N1, ana,
  fechado, sem responsável)**.
- 08 §7: só mesclados ficam fora por padrão; não há filtro de estado na
  consulta. #1003 também casa.
- Valor correto: #1001 e #1003. Além disso, a base da 08 não diz que o nome
  do grupo N1 é "Suporte N1".

**2.2 — média — TL-25 (01 §9.3): fronteira de "há N dias".**
- Segunda resolução no dia 3; N = 4 dias corridos; 3 + 4 = dia 7 **no mesmo
  horário** da resolução.
- Rodando no dia 7 em horário anterior ou igual ao da resolução, o tempo
  decorrido é ≤ 4 d e o ticket não fecha. "Dia 7: fechado" só vale se a regra
  for ≥ e a tarefa rodar depois desse horário.
- TL-24 usa "4 dias e 1 minuto", o que sugere "> N". O caso precisa do
  horário ou da regra de comparação.

**2.3 — média — WH-25 (10 §15.6): referência de tempo ambígua.**
- Calendário 10 §13.4, contado a partir da 1ª tentativa: 0, +1, +5, +30 min ….
- 429 na 1ª tentativa (t=0): a próxima pelo calendário é t=1 min, não 5 min.
- 429 na 2ª tentativa (t=1 min): a próxima pelo calendário é t=5 min
  (absoluto, 4 min depois); "10 min" a partir da resposta dá t=11 min.
- "Próxima tentativa em 10 min (não em 5 min)" mistura tempo relativo e
  absoluto. O caso precisa dizer qual tentativa recebeu o 429.

**2.4 — média — 05 §7.10: arredondamento do aviso.** "O valor é arredondado
para baixo, em minutos inteiros", sem dizer qual valor.
- Meta 16 min, 20 %: restante 3,2 → 3 → aviso aos **13** min consumidos;
  consumido 12,8 → 12 → aviso aos **12** min.
- Todos os casos (240→192, 60→48, 15→12, 1440→1152) usam valores exatos e não
  distinguem as duas leituras.

**2.5 — baixa — EM-55 (02 §11.5): calendário de reenvio SMTP.** "Backoff (1,
5, 15, 60 min …)" pode ser instante absoluto ou intervalo.
- SMTP fora por 10 min: leitura absoluta → falha em 1 e 5, envia em 15; por
  intervalo → falha em 1 e 6, envia em 21.
- O esperado ("novas tentativas em 1 e 5 min") só cabe na leitura absoluta e
  não diz quando sai o envio efetivo.

---

## 3. Casos de teste que contradizem a própria spec

**3.1 — alta — SL-20, SL-22, SL-23, SL-24, SL-25 e SL-26 (05 §9.3): quem é a
solicitante?**
- 05 §9.1: "Salvo indicação, os tickets são de `cris` no grupo N1 (política
  P0)". Os casos dizem "ana responde"/"ana reabre", e ana não é solicitante
  nem participante.
- Se ana for estranha: pela 02 §5 vira participante não confirmada, e não
  está definido se a resposta dela reabre (ver 1.46).
- Se ana for a solicitante: ela é da Acme e vale **P2** (normal 2 h / 16 h),
  não P0, e os valores esperados mudam. Ex. SL-20 em P2: 480 consumidos na
  pausa (ter 420 + qua 60), restam 960 − 480 = 480; retomada seg 11-09 15:00 →
  seg 180 + ter 09–12 180 + 13–15 120 → **ter 11-10 15:00**, não qua 11-11
  15:00.
- O caso não passa em nenhuma das duas leituras sem ajuste.

**3.2 — alta — RM-53 (11 §12.4) contra 11 §5.3.** §5.3 é condicional ("Se a
exclusão de tickets existir (ver Questões abertas)"), mas RM-53 afirma a
exclusão como ação disponível. Também contraria 01 §3 (ver 1.39).

**3.3 — média — RM-27 (11 §12.2) contra 11 §3.** O caso espera "evento com
origem admin", mas a 11 §3 usa as origens da spec 01 §7 (agente, solicitante,
sistema, automação, API). A 01 TL-12 grava "origem agente e ator admin".

**3.4 — média — AU-116 (05 §9.7) contra 05 §3.5.** AU-116 afirma que "a
mudança de prioridade não inicia outra passada". A exceção da 05 §3.5 diz que,
quando uma ação de gatilho muda a prioridade e isso produz aviso ou violação
de SLA, esse evento de SLA inicia uma passada própria. Normal → alta encurta a
meta de resolução e pode gerar aviso ou violação imediata (05 §7.7). O caso
precisa fixar o consumido ou ressalvar a exceção.

**3.5 — baixa — CH-10 (03 §9.2).** "cris não existe na conta", mas a
configuração da 03 §9 define a atriz `cris` com `cris@mail.test`.

**3.6 — baixa — EM-22 (02 §11.2) e fx09.** O bounce referencia `{R}` (resposta
do agente a ana, customer1), mas o `Final-Recipient` é
`nobody@nowhere.lab.test`, que não está no ticket. O resultado esperado é
coerente com a fixture, mas o cenário não é realista. A 02 §7 também não diz
qual destinatário invalidar quando o relatório e o ticket divergem.

**3.7 — baixa — EM-20 (02 §11.2) e fx08.** A auto-resposta vem de Carla Souza
(customer3), que não é solicitante nem participante do ticket de fx01. Pela
ordem da 02 §3 ela é classificada como automática antes da etapa de pessoas,
então o resultado esperado se mantém. Fica indefinido se a regra "remetente
novo na conversa" se aplica.

**3.8 — baixa — Dados de teste com o mesmo número e significados diferentes.**
- #1020: bia/N1 na 06 §12 × "no Financeiro" na 12 EX-23.
- #1011: bia na 01 TL-40 e na 11 RM-50 × solicitante ana na 07 KB-81.
- #1000: 08 §12 (N1, ana, aberto, ag1) × 10/09 (ana, pendente em AP-11).
- Não quebra cada suíte isolada, mas impede um seed único.

---

## 4. Termos fora do vocabulário da spec 01

**4.1 — média — Níveis "ler / trabalhar".** 04 §2.1, §2.2, §4, §6.2, §7, §9.2,
§10 e §13 (todos os AS-xx) e 08 §14 Q1 usam os níveis antigos. A 06 §3 e a
01 §2 usam **nenhum / leitura / escrita**. Mapeamento: ler → leitura,
trabalhar → escrita; "membro" sem nível ≠ "nenhum". A 05 já usa "escrita".

**4.2 — média — "Origem admin".** 11 RM-27. A 01 §7 não tem essa origem (ver
3.3).

**4.3 — média — Enumerações de ator e autor divergentes.**
- 01 §7 (origens): agente, solicitante, sistema, automação, API.
- 10 §12.1 (ator do webhook): agente, solicitante, sistema, automação, API.
- 12 §4.3 (ator do evento): agente, solicitante, sistema, automação,
  **integração**.
- 11 §3 (tipo de autor): solicitante, **participante**, agente, integração,
  automação, sistema.

**4.4 — média — "Conta de serviço".** 10 §3.2: "agente comum dedicado". 12 §5:
"identidade de integração", que "não é Pessoa nem Agente". O mesmo termo tem
dois significados.

**4.5 — média — "Convidado" e "visitante".** 07 §7.3, 08 §8 e 03 usam
**convidado** (acesso por link a um ticket) e **visitante** (anônimo) como
sujeitos de acesso. Nenhum dos dois está na 01 §2 nem na matriz da 06 §4,
embora a 06 §1 diga cobrir "todos os caminhos".

**4.6 — média — "Gestor da organização".** 07 §8.1 e §12 usam o termo. A 01
não o define, e a 06 §5.2 o declara fora do MVP.

**4.7 — baixa — Nomes dos valores do compartilhamento da organização.** 06:
"nenhum" / "membros veem os tickets da organização". 07/08: "desligado" /
"gestores" / "todos os membros".

**4.8 — baixa — Nomes dos eventos de SLA.** 05: "SLA: aviso" / "SLA:
violação". 09: "SLA prestes a vencer" / "SLA vencido". 12 §4.2: "alerta de
SLA". 11: "em risco".

**4.9 — baixa — "Limite de encadeamento entre automações".** 12 §4.6 diz que o
limite "é o da spec 05", mas a 05 §3.5 diz que não há encadeamento nem
contador ("o laço é impossível por construção").

**4.10 — baixa — "Agentes do grupo".** 09 §7.1 não diz o nível de acesso
(nenhum / leitura / escrita da 06). Ver 1.6.

**4.11 — baixa — "Permissão de relatórios" e "escopo de relatórios".** 11 §7 e
§9. Não estão entre as permissões da 06 nem entre os escopos da 06 §7 e da 10
§3.3.

**4.12 — baixa — Definição de "mensagem de sistema".** 01 §2: mensagem de
máquina "anexada ao ticket para registro (resposta automática recebida, aviso
de falha de entrega)". 05 §3.3 e 06 §6.1 estendem o termo para e-mails
automáticos **enviados** ("mensagem de sistema pública"). A 01 deveria
admitir a visibilidade pública ou a 05 deveria usar outro termo.

---

## 5. Clean room

Não foram encontrados código, SQL, nomes de classe ou de função, chaves de
configuração nem textos de interface dos sistemas analisados nas specs. As
tabelas comparativas descrevem comportamento com palavras próprias. Pontos
residuais:

**5.1 — baixa — `specs/LICENSES.md` contém URLs e caminhos dos projetos.** Ele
vai para a Fase 2 junto com `specs/`. Contém:
- URLs de repositório (`github.com/zammad/zammad` e os demais);
- referências de imagem (`ghcr.io/zammad/zammad` 7.2.2,
  `chatwoot/chatwoot:v4.19.1-ce`);
- o caminho de diretório do repositório do Chatwoot `enterprise/`;
- `developer.zendesk.com`;
- caminhos da Fase 1 que a Fase 2 não recebe (`observation/README.md`,
  `observation/evidence/`).

É um registro jurídico, não comportamento. Aceitar explicitamente ou mover
para fora de `specs/`.

**5.2 — baixa — `specs/fixtures/email/README.md` cita a Fase 1.** Cita
`observation/tools/send-eml.ps1`, o endereço de exemplo
`support-zammad@lab.test` e o exemplo de marcador `[#1234]`, que reproduz o
formato de marcador de assunto de um dos projetos analisados. O PantherDesk
usa `[PD-N]`. Trocar os exemplos antes da entrega à Fase 2.

**5.3 — baixa — WH-22 e WH-23 dependem do laboratório da Fase 1.** Os caminhos
`/status/500` e `/slow/30000` e o host `hooks.lab.test` são do receptor de
webhooks do laboratório (`observation/lab/webhook-sink/server.mjs`, código
nosso). Não é violação, mas a Fase 2 não recebe esse receptor. A spec
precisaria descrevê-lo.

**5.4 — baixa — Texto de bounce de MTA na fx09.** A fx09 reproduz o texto
padrão de bounce de um MTA comum ("Undelivered Mail Returned to Sender", "This
is the mail system at host …"). Não vem de nenhum dos projetos listados. O
README afirma que as fixtures foram "escritas do zero", então vale trocar por
texto próprio.

Verificado e **não** considerado violação: `Auto-Submitted` (RFC 3834),
`List-Id` e `List-Unsubscribe` (RFC 2919/2369), `Precedence`, `X-Autoreply`,
`X-Autorespond`, `X-Auto-Response-Suppress`, `X-Spam-Flag` (cabeçalhos de fato
de MTAs e clientes de e-mail), ETag/If-Match (RFC 9110), Bearer (RFC 6750),
cabeçalhos de depreciação (RFC 9745/8594), o esquema HMAC-SHA256 de
"instante.corpo" (genérico), os códigos de erro em português da 10 §6.1, o
marcador `[PD-N]` e o teste `{{ 7*7 }}` (sonda genérica de injeção de modelo).

---

## 6. Escopo do MVP

Itens obrigatórios do brief, todos presentes:

| Item | Onde |
|---|---|
| ciclo de vida do ticket | 01 §4 |
| threading de e-mail | 02 §4 |
| atribuição | 04 |
| comentários públicos e internos | 01 §2, 06 §6 |
| macros e gatilhos | 05 §3, §4 |
| SLA simples com aviso | 05 §7.10 |
| portal e base básica | 07 |
| REST e webhooks | 10 |
| papéis admin, agente e solicitante | 06 §2 |

Itens de roadmap do brief corretamente fora do MVP: chat (03 §7.2, 09 §1),
WhatsApp, SMS e redes (03 §7.3–7.4), plugins e apps (12 §9), relatórios
personalizados e CSAT (11 §10).

**6.1 — alta — Webhook como ação de automação.** Está no MVP pela 05 e no
roadmap pela 10 (ver 1.12).

**6.2 — média — Relatórios além do "simples".** A 11 põe no MVP um painel com
métricas de período (medianas, alternância útil/corrido), API de métricas e
exportação CSV assíncrona de até 200.000 linhas com notificação e link de
24 h. Relatórios avançados são roadmap no brief. O painel básico é defensável;
a exportação assíncrona e a API de métricas são extras. A 08 §10.1 põe a
exportação no roadmap (ver 1.40).

**6.3 — média — Extensibilidade além das costuras.** A 12 põe no MVP:
- identidades de integração com 8 escopos e lista de grupos;
- um feed de eventos de domínio de 30 dias;
- 4 adaptadores com suítes de aceite próprias;
- duas implementações de armazenamento (disco e objetos) e duas de saída de
  e-mail (SMTP e API HTTP de provedor);
- estado de saúde por adaptador.

O brief pede só os itens do MVP, e isso conflita com 06/10 (1.21). O sistema
de apps está corretamente no roadmap.

**6.4 — média — Superfície da API incompleta para a paridade declarada.** 12
§7 diz que "toda ação disponível ao agente na interface está disponível na
API", e 10 §2 G8 diz que a interface usa a mesma API. Mesmo assim, a 10 §4 não
lista operações para:
- mesclar (EX-40 mescla pela API);
- aplicar macro (AU-135: "aplicar pela API é recusado");
- a ação de solicitante "meu problema foi resolvido" (01 TL-18);
- categorias da base;
- visões salvas (BU-61 abre visão "pela API");
- notificações e lida/não lida;
- confirmar ou recusar participante não confirmado (02 §5);
- liberar ou descartar itens da quarentena;
- o modo de criação de ticket por agente (01 §4.6).

**6.5 — baixa — Base de conhecimento acima de "básica".** A 07 inclui no MVP:
revisões com restauração, deflexão, teto de visibilidade por categoria, link
mágico com senha opcional e links de convidado por destinatário. Não são
itens de roadmap do brief, mas pesam no prazo.

**6.6 — baixa — Itens não pedidos pelo brief.**
- 03 §4: formulário público com 7 camadas anti-spam e uma implementação
  própria de CAPTCHA obrigatória.
- 04 §6: rodízio (opcional, desligado).

Não são roadmap no brief.

**6.7 — baixa — Tempo real para agentes (09).** SSE, presença e notificações
in-app são tempo real **para agentes**, não "chat em tempo real". Não é
vazamento de escopo; registrado para deixar claro que a 09 não abre o chat.

---

## 7. Questões abertas

Legenda: **respondida** (outra spec já decide, sem conflito); **respondida com
conflito** (outra spec decide, mas de forma diferente da que a questão supõe);
**parcial**; **aberta**.

### Spec 01 §11
| # | Questão | Situação |
|---|---|---|
| 1 | N = 4 dias (fechamento) e 14 dias (janela) são propostas | aberta (decisão de produto; 05 §5 e 11 RM-25 só usam os valores) |

### Spec 02
Não tem seção de questões abertas.

### Spec 03 §11
| # | Questão | Situação |
|---|---|---|
| 1 | Comparação de endereços igual entre 02 e 03 | respondida: 01 §2 (endereço inteiro sem diferença de maiúsculas, sem espaços nas pontas; sub-endereço é outro endereço) |
| 2 | "Endereço verificado" não existe na 01 | respondida com conflito: 01 §2 já tem verificado / não verificado / inválido, mas aceita "resposta a um e-mail nosso" como prova (ver 1.27) |
| 3 | Lista de bloqueio por IP e entradas de permissão | parcial: 02 §3 etapa 4 já inclui IP; entradas de permissão continuam só na 03 |
| 4 | Retenção da quarentena (30 dias) | respondida: 02 §2.4 (30 dias, para todos os motivos, inclusive "formulário suspeito") |
| 5 | Limites propostos | aberta |
| 6 | Tipos de anexo e antivírus | aberta (nenhuma spec define) |
| 7 | Página de agradecimento sem número | aberta (decisão de produto) |

### Spec 04 §15
| # | Questão | Situação |
|---|---|---|
| 1 | Spec 06 inexistente; ler/trabalhar | respondida com conflito: 06 §3 (leitura/escrita equivalem), mas admin pode ser responsável sem associação (1.1) |
| 2 | Transferir sem acesso ao destino | respondida: 06 §3 ("mesmo sem acesso ao destino") |
| 3 | "Origem admin" em TL-12 | respondida: 01 TL-12 já diz "origem agente e ator admin" (questão desatualizada) |
| 4 | Retorno de pendência com responsável ausente | aberta (01 §4.3 continua mandando notificar o responsável) |
| 5 | Ação de atribuição inválida em automação | respondida com conflito: 05 §3.6 desfaz o gatilho inteiro (1.4) |
| 6 | Chave do rodízio | aberta (proposta aceitável) |
| 7 | Fuso da data de fim da ausência visto pelo admin | aberta |

### Spec 05 §11
| # | Questão | Situação |
|---|---|---|
| 1 | 1ª resposta não pausa em pendente | respondida: 01 §4.1 (tabela de estados) já diz isso |
| 2 | Feriado em calendário noturno | aberta (confirmação de produto) |
| 3 | SLA de ticket liberado da quarentena | aberta |
| 4 | Um único aviso por métrica na vida do ticket | aberta |
| 5 | Valores propostos | aberta |
| 6 | "Origem admin" em TL-12 | respondida: TL-12 já usa origem agente (questão desatualizada) |
| 7 | Tela mostrar a ordem dos gatilhos antes de salvar | aberta (requisito de interface, sem conflito) |

### Spec 06 §14
| # | Questão | Situação |
|---|---|---|
| 1 | E-mail ao participante não confirmado | respondida: 02 §5, EM-32 e EM-35 (não recebe e-mails até confirmação) |
| 2 | Agente sem escrita respondendo por e-mail | respondida: 02 §5 (leitura → nota interna; sem acesso → quarentena; resposta a notificação = nota por padrão); a questão cita a 02 errado; a 09 contradiz (1.8) |
| 3 | Responsável precisa de escrita | respondida: 01 §2 já diz "escrita (spec 06)" |
| 4 | "Origem admin" em TL-12 | respondida: desatualizada |
| 5 | Gestor da organização e token por grupo | aberta (roadmap), mas a 07 já põe gestor no MVP (1.2) |
| 6 | Tempo de resposta do 404 | parcial: 10 §6.2 exige "mesmo tempo de resposta aproximado"; sem número |

### Spec 07 §12
| # | Questão | Situação |
|---|---|---|
| 1 | Premissas sobre a 06 (a–d) | parcial com conflito: (a) e (b) contrariam a 06 §5.2 (1.2); (c) a 06 não tem "pode publicar na base" (1.32); (d) 404 respondida na 06 §8 |
| 2 | Link mágico para endereço inválido | respondida: 02 §7 já contém a exceção e a revalidação |
| 3 | Link de convidado no e-mail de saída | respondida: 02 §9 ("Link do ticket") |
| 4 | Solicitante resolver o próprio pedido | respondida com conflito: 01 §4.2 nota ⁴ e TL-18 já incluem no MVP; a 07 §8.4 precisa mudar (1.3) |
| 5 | Credenciais de demonstração | aberta (depende da senha opcional ligada; 00-produto exige credenciais no README) |
| 6 | Validade dos links | aberta; a 03 §4.6 acrescenta um link de 7 dias (1.29) |
| 7 | Exclusão de artigo já publicado | aberta |
| 8 | Multi-idioma | aberta (roadmap) |

### Spec 08 §14
| # | Questão | Situação |
|---|---|---|
| 1 | Nível usado pela busca | respondida: 06 §6.3 (grupos com leitura ou escrita) |
| 2 | Quem cria visões compartilhadas | respondida: 06 §2 tem papéis fixos e não tem líder de grupo; fica só o admin |
| 3 | Acentos em etiquetas | respondida: 01 §2 ("com acentos preservados"; a busca ignora acentos), igual à recomendação |
| 4 | Texto citado fora da busca | aberta |
| 5 | Falsos positivos do radical | aberta |
| 6 | Limites | aberta; a 10 trata página > 100 de outro jeito (1.18) |

### Spec 09 §12
| # | Questão | Situação |
|---|---|---|
| 1 | Spec 06 inexistente | respondida: 06 §3, §8 (por grupo, 404) |
| 2 | Versão não definida na 01 | respondida com conflito: 01 §3 define a versão, com outras regras de incremento e exigência (1.9) |
| 3 | Limiar de "SLA prestes a vencer" | respondida: 05 §7.10 (20 % da meta restante, padrão; sem a alternativa "30 min antes") |
| 4 | Notificação "para o grupo" | respondida com conflito: 01 §4.3 diz "cada agente ativo do grupo"; a 04 §10 diz outra coisa (1.6) |
| 5 | Resposta ao e-mail de notificação | respondida com conflito: 02 §5 já faz o padrão ser nota interna; a 09 §8 e RT-52 contrariam (1.8) |
| 6 | Muitas abas e HTTP/2 | aberta (implementação) |
| 7 | Parâmetros | aberta |

### Spec 10 §17
| # | Questão | Situação |
|---|---|---|
| 1 | 404 × 403 | respondida com conflito: 06 §8 põe a verificação de escopo antes da de visibilidade (1.16) |
| 2 | TL-15 e TL-54 "pela API" | respondida: 01 TL-15 e TL-54 já dizem "com a sessão do portal" |
| 3 | Versão na 01 | respondida: 01 §3 (com as divergências de 1.9) |
| 4 | Mensagem via API em ticket mesclado | aberta (divergência intencional; a 01 §6 não cobre a API) |
| 5 | Exclusão de ticket | respondida: 01 §3 ("Não existe exclusão de ticket no MVP"; a numeração já diz "nem depois de mescla") |
| 6 | 3xx como falha definitiva | aberta |
| 7 | Código de transição recusada | aberta: a 01 diz validação, a 06 e a 10 dizem 403 (1.17) |
| 8 | Retrato visto por admin | aberta (futuro) |
| 9 | Limites | aberta |

### Spec 11 §14
| # | Questão | Situação |
|---|---|---|
| 1 | Autor da mensagem de abertura do ticket criado por agente | respondida: 01 §4.6 (modos "registrar pedido" e "contato proativo") |
| 2 | Spam como evento próprio | respondida: 01 §4.1 (marcar e desmarcar geram eventos próprios; as métricas os usam) |
| 3 | Exclusão de ticket | respondida: 01 §3 (sem exclusão no MVP); a 11 §5.3 e RM-53 precisam sair (1.39) |
| 4 | Mescla e o indicador "sem primeira resposta" | respondida: 01 §6 item 5 (indicadores do destino não mudam) |
| 5 | Desfechos de SLA como eventos | parcial com conflito: 05 §7.11 grava a violação como evento e 05 §7.13 define os estados, mas a 05 §7.8 diz que o resultado da resolução é o da próxima resolução (1.35); eventos de "cumprida" e "cancelada" não estão definidos |
| 6 | Grupo na criação com gatilhos | parcial: 05 §3.4 item 7 diz que a passada roda depois da gravação da operação de origem (não na mesma transação); a marcação pedida pela 11 continua necessária |
| 7 | Versões de calendário | aberta |
| 8 | Resolvido → pendente é reabertura? | aberta (a 01 permite a transição; a contagem é decisão da 11) |
| 9 | Tokens pessoais em robôs | aberta (igual à 12 Q3) |
| 10 | Separador do CSV | aberta |
| 11 | Mudança de fuso da conta | aberta |

### Spec 12 §13
| # | Questão | Situação |
|---|---|---|
| 1 | Campos em pessoa e organização | aberta (01 §5 põe no roadmap) |
| 2 | Ator do tipo integração | respondida: 01 §2 (identidade de integração pode ser autora de mensagens e de eventos de auditoria); as enumerações continuam divergentes (4.3) |
| 3 | Limitar tokens pessoais | aberta |
| 4 | Retenção do feed | aberta |
| 5 | Tamanho do corpo nos eventos | parcial: 10 §12.2 fixa 256 KB para webhooks; eventos de domínio sem limite |
| 6 | Solicitante criado por provedor externo | aberta (SSO é roadmap pela 07 §7.1) |
| 7 | Duplicidade no transporte de saída | aberta |
| 8 | Assinatura da mensagem de integração | respondida com conflito: 02 §9 já define "{nome da integração} via {nome da conta}" (1.25) |

Totais (77 questões): respondida 25; respondida com conflito 9; parcial 6;
aberta 37.
