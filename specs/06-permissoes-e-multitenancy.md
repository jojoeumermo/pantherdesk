# Spec 06 — Permissões e multi-tenancy

Status: **rascunho v0.3 (2026-10-29)**. Baseado na documentação pública dos 7
projetos analisados. As evidências de runtime ainda estão pendentes; cada ponto
que depende delas está marcado como **[evidência pendente: cenário]**.
Vocabulário: spec 01. Automações: spec 05. Decisões transversais: spec 00
(D01–D53). Requisitos da operação EARJ: spec 13, que prevalece sobre esta.

**Mudanças na v0.3**
- **Entrada com Google** (spec 13 Δ31): agentes e admins só entram com conta
  Google do domínio da escola, sem senha local; papel e grupos vêm sempre do
  PantherDesk; conta do domínio que nunca foi cadastrada entra como
  solicitante; conta desativada não entra (§2.1).
- **Login de desenvolvimento** só em modo de desenvolvimento e só sem o
  provedor Google configurado (00-produto) (§2.1).
- A conta de uma requisição do portal ou da área do agente vem também do
  **domínio** em que ela chega (Δ32) (§9).
- **Incidente pai** (Δ35): quem marca, quem vincula filhos (inclusive de outros
  grupos), como a resposta e a resolução do pai chegam aos filhos e o que cada
  um vê (§3, §4, §6.3).
- **Locais e QR** (Δ33): cadastro de locais e impressão de QR só pelo admin;
  "minha sala" editada pela própria pessoa; QR aberto por agente mostra só os
  tickets que ele já pode ver (§4, §5.5, §10).
- **Calendário de eventos** (Δ34): só agentes e admin, com o mesmo escopo por
  grupo das filas; o solicitante vê os próprios pedidos de evento como
  tickets comuns (§4, §6.3).
- **"Criar artigo"** a partir de ticket resolvido (Δ38): qualquer agente que lê
  o ticket cria o rascunho; só o admin publica (D30) (§4).
- Novos casos PE-108 a PE-127.
- **Ajustes D40–D53**: filho invisível para quem vincula → **404**, não 422
  (D43, §3; PE-117 corrigido); desvincular com escrita no pai **ou** no filho
  (D45, novo PE-128); a resposta do pai chega aos filhos em qualquer estado,
  exceto fechado e mesclado, e entra no filho resolvido sem mudar o estado
  (D46); na resolução em cascata com responsável obrigatório, o filho sem
  responsável recebe quem resolveu o pai, se essa pessoa tem escrita no grupo
  do filho; senão o filho não é resolvido (D47, D55); locais afetados = salas do pai e dos
  filhos visíveis, sem repetição (D48; PE-120 corrigido); "Criar artigo" com
  leitura, ticket não resolvido → erro de validação (422), e a outra língua
  como tradução do mesmo artigo (D42, §4); agentes e admins só com Google,
  sem login local fora do modo de desenvolvimento (D53, §2.1). Novos casos
  PE-128 a PE-132.

**Mudanças na v0.2**
- Ordem das verificações: a **visibilidade vem antes** do papel e do escopo;
  invisível → 404 sempre; transição inválida → 422 (D05, §8; PE-60 corrigido).
- **Identidade de integração** (D04): ator não humano criado pelo admin, com
  acesso por grupo e os mesmos três escopos; o admin cria os tokens dela
  (§2, §7).
- Token com escopo maior que o papel é **recusado** na criação (D14); token de
  pessoa desativada fica suspenso e volta na reativação (§7).
- Tickets da organização com três valores — desligado, só gestores, todos os
  membros — e a marca **gestor da organização** na Pessoa (D07, §5.2).
- "Meu problema foi resolvido" no portal, só para o solicitante (D08, §4,
  §5.1).
- Notas internas em webhooks só no tipo de evento próprio; sem "público" de
  webhook (D03, §6.2; PE-36 e PE-37 reescritos).
- Notificação nunca vai ao autor (D12, PE-34 corrigido); resposta de agente a
  e-mail de notificação vira nota por padrão (D02).
- Novos sujeitos de acesso: **convidado** e **visitante** (§5.4); agente
  solicitante não entra pelo portal (§2).
- Permissões dos recursos da EARJ (spec 13): agente completo e de apoio,
  seguidores, menções, conversa paralela, encaminhamento com retorno, filas
  salvas, macros pessoais, edição em massa, mesclar pessoas, pesquisa de
  satisfação, resumo por IA (§3, §4, §6, §10).
- Base de conhecimento: rascunho para todo agente, publicação só pelo admin
  (D30, spec 07); organizações editáveis por agente completo; relatórios no
  escopo dos grupos (spec 11).
- Questões abertas respondidas removidas; novos casos PE-15 a PE-19, PE-41 a
  PE-48, PE-62 a PE-67, PE-78, PE-79 e PE-80 a PE-99.
- Ajustes D23–D37: ticket encaminhado fica **aberto** no destino, com a marca
  derivada "encaminhado" para a origem (D23); leitura do agente e do grupo de
  origem (D24; questão aberta retirada); confirmação de abertura do visitante
  pelo gatilho da spec 05 (D25, §5.4); tokens suspensos na desativação, com
  revogação pelo admin (D26); publicar, arquivar e excluir artigo só pelo
  admin, sem a marca "pode publicar" (D30, §4, §10); sem "audiência" de webhook
  (D31); "meu problema foi resolvido" sem exigir responsável nem campos
  obrigatórios, com a marca "resolvido pelo solicitante" (D33, §5.1); conversa
  paralela no evento de mensagens internas (D37, §6.2); escopo de
  administração só para integração **administrativa** (D36, §7). Novos casos
  PE-100 a PE-107.

---

## 1. Problema

O mesmo ticket é visto por públicos com direitos muito diferentes: quem
configura o sistema, quem atende certos grupos e quem pediu ajuda. O modelo de
permissões precisa garantir, sem exceção e por **todos os caminhos** (interface,
portal, widget de chat, API, e-mail, webhooks, busca, anexos, notificações):

1. que um agente só veja e altere tickets dos grupos a que tem acesso;
2. que **nota interna nunca chegue ao solicitante**, nem uma conversa
   paralela;
3. que um solicitante veja só o que é seu e, se a organização permitir, os
   tickets da organização, **sem poder alterá-los**;
4. que um token de API **nunca** tenha mais poder do que o seu dono;
5. que a resposta a um recurso proibido não revele que ele existe;
6. que dados de uma conta **nunca** apareçam em outra, mesmo que o MVP rode com
   uma conta só.

O vazamento acontece quase sempre por um caminho secundário: contagem, busca,
anexo por link direto, histórico do contato, citação em e-mail. Por isso a regra
de visibilidade fica numa única camada, aplicada a todos os caminhos.

---

## 2. Papéis e atores

Cada pessoa tem **exatamente um papel por conta**. O conjunto é fixo no MVP;
papéis personalizados ficam para o roadmap. Internamente, cada verificação é
uma permissão nomeada, para que papéis personalizados possam ser montados
depois sem reescrever as verificações.

| Papel / ator | Quem é | Acesso a tickets |
|---|---|---|
| **admin** | Configura a conta. | **Escrita em todos os grupos**, implícita e não removível. Pode ser responsável em qualquer grupo sem ser membro dele (D06). |
| **agente** | Atende tickets. | Por grupo: nenhum, leitura ou escrita (§3). |
| **solicitante** | Cliente. | Só pelo portal, pelo link de convidado e pelo widget de chat: os próprios tickets, aqueles em que é participante e, se a organização permitir, os da organização (§5). |
| **identidade de integração** | Ator **não humano** (sistema externo), criado pelo admin (D04). | Por grupo, com os mesmos níveis dos agentes; só pela API, com tokens (§7). |

- Ao contrário de um dos projetos, aqui **admin vê tickets**: um admin que
  configura grupos e gatilhos sem poder ver o resultado não consegue depurar
  nada. Isso é um papel único, não uma soma de papéis.
- **Agente completo** e **agente de apoio** (termos da operação EARJ, spec 13
  R35) não são papéis novos: agente completo é o agente com **escrita** em
  pelo menos um grupo; agente de apoio é o agente que só tem **leitura** nos
  seus grupos (lê e escreve nota interna). As ações de conta que exigem
  "agente completo" estão na matriz (§4).
- A identidade de integração aparece na tela com o **nome da integração**,
  nunca conta como humano nas métricas (spec 11), não entra na interface do
  agente, não pode ser responsável nem seguidora e não recebe notificações.
  Só recebe o escopo de administração se o admin a criar marcada como
  **administrativa** (D36, §7).
- Agente desativado não entra, os tokens dele ficam **suspensos** (D26, §7) e ele
  continua aparecendo como autor no histórico.
- Um agente pode ser o **solicitante** de um ticket (ex.: chamado interno). O
  portal não é porta de entrada para agentes (spec 07 §7.1). Na área do
  agente, valem as regras de grupo; sem acesso ao grupo do ticket, o agente
  solicitante acompanha o pedido como qualquer solicitante: pelos e-mails das
  respostas públicas e pelo link de convidado que eles trazem (§5.4), sem
  notas.
- Mudanças de papel e de acesso valem a partir da **próxima requisição**,
  inclusive para sessões já abertas e tokens.

### 2.1 Entrada e origem do papel (spec 13 Δ31)

- Cada conta configura o **domínio da escola** para a entrada com Google (na
  EARJ, `earj.com.br`). Só contas Google desse domínio entram pelo Google; o
  domínio vem da conta Google autenticada, nunca de um valor enviado pelo
  navegador.
- **Agentes e admins entram somente com Google** do domínio da conta. Não
  existe senha local nem link por e-mail para eles, na área do agente nem no
  portal (spec 07 §7.1). O endereço principal de quem tem papel de agente ou
  admin precisa ser do domínio: o admin não consegue dar esses papéis a uma
  pessoa cujo endereço principal é de outro domínio (erro de validação, 422).
- **Papel e grupos vêm do PantherDesk**, definidos pelo admin (§10). O Google
  só prova quem é a pessoa: nenhum grupo, cargo ou marca da conta Google muda
  papel, acesso a grupo ou organização no MVP.
- Na entrada, o endereço da conta Google é procurado entre as Pessoas da
  conta:
  - Pessoa **agente ou admin ativa** → sessão com esse papel.
  - Pessoa **solicitante** → sessão de solicitante (portal).
  - **Nenhuma Pessoa** com esse endereço → a Pessoa é criada como
    **solicitante**, sem organização e sem grupos. Isso vale mesmo com o
    auto-cadastro do portal desligado (spec 07 §7.2), porque o domínio já
    prova que é alguém da escola.
  - Pessoa **desativada** (qualquer papel) → entrada recusada; nada é criado
    e ela não vira solicitante.
  - Em todos os casos aceitos, o endereço passa a **verificado** (amplia D38)
    e a entrada gera evento de auditoria.
- Uma conta Google de outro domínio é recusada, sem criar Pessoa; a tela
  oferece o link por e-mail (spec 07 §7.1). Promover um solicitante a agente é
  só mudar o papel (§10); vale na próxima requisição.
- **Login de desenvolvimento** (00-produto): lista os usuários de
  demonstração e entra com um clique. Ele só existe quando a aplicação roda em
  **modo de desenvolvimento** e o provedor Google **não** está configurado. Em
  qualquer outro caso, a tela e a operação não existem (404), e nenhuma
  configuração da conta as liga. As sessões abertas por ele seguem todas as
  regras desta spec, com o papel e os grupos do usuário de demonstração.
- Fora do modo de desenvolvimento **não existe login local** de nenhum tipo
  para agentes e admins (D53). Uma instalação sem o provedor Google
  configurado **não é suportada no MVP**: nela, ninguém entra na área do
  agente.
- O provedor Google é o primeiro do adaptador de autenticação da spec 12;
  outros provedores ficam no roadmap.

---

## 3. Acesso do agente por grupo

| Nível | O que permite |
|---|---|
| **nenhum** | Nada. O ticket não existe para esse agente (§8). |
| **leitura** | Ver o ticket inteiro: mensagens públicas, notas internas, conversas paralelas, anexos, histórico, avaliação e SLA. Encontrar o ticket em listas, filas e buscas. **Adicionar nota interna**, mencionar colegas, **seguir** o ticket, imprimir. Não pode responder em público, mudar campos, ser responsável, aplicar macro, abrir conversa paralela, encaminhar, devolver nem mesclar. |
| **escrita** | Tudo de leitura + responder em público, mudar estado, prioridade, tipo, etiquetas, campos, participantes e seguidores, ser responsável, atribuir, aplicar macros, abrir e encerrar conversas paralelas, encaminhar com retorno, devolver, mesclar (escrita nos dois tickets, spec 01 §6), criar tickets no grupo e mover o ticket para outro grupo. |

- Por que leitura pode escrever nota interna: o caso típico de leitura é a
  consulta entre equipes ("o Financeiro opina num ticket do N1"). A nota não
  muda estado nem SLA (spec 01 §4.3 e spec 05 §7.6) e não sai para o cliente.
- **Responsável** precisa ter **escrita** no grupo do ticket (spec 01 §2); o
  admin tem escrita em todos (D06).
- **Mover de grupo**: quem tem escrita no grupo atual pode mover o ticket para
  qualquer grupo ativo da conta, mesmo sem acesso ao destino (é o
  encaminhamento normal N1 → Financeiro). Se o responsável não tiver escrita no
  grupo novo, o ticket fica sem responsável (spec 04). A interface avisa quando
  quem move vai perder o acesso.
- **Encaminhamento com retorno** (spec 13 Δ5, spec 04): exige escrita no grupo
  atual. O ticket encaminhado tem um único estado, **aberto**, no grupo de
  destino; para o grupo de origem ele aparece com a marca derivada
  **"encaminhado"**, que não é um estado (D23). Enquanto a origem estiver
  registrada, o **agente de origem** e quem tem leitura ou escrita no **grupo
  de origem** têm **leitura** sobre o ticket (vê, segue, escreve nota), mesmo
  sem acesso ao grupo de destino (D24). A
  escrita fica com o grupo de destino. **Devolver** exige escrita no grupo de
  destino. Quando a origem é limpa (devolução, resolução no destino ou
  transferência normal), essa leitura extra acaba na mesma hora.
- **Incidente pai** (spec 13 Δ35):
  - **Marcar** um ticket como incidente (e desmarcar) exige escrita no grupo
    dele.
  - **Vincular** um filho exige escrita no grupo do pai **e** no grupo do
    filho. Por isso, um filho de outro grupo só é vinculado por quem tem
    escrita nos dois (ou pelo admin, D06). Filho invisível para quem vincula
    → **404**, como qualquer recurso invisível (D43, D05, §8). Filho visível
    só com leitura → 403.
  - **Desvincular** exige escrita no **pai ou** no filho (D45): quem cuida de
    um só dos lados pode desfazer o vínculo. Desvincular não desfaz mensagens
    nem mudanças de estado já registradas no filho.
  - Depois do vínculo, a resposta pública e a resolução feitas no pai **chegam
    aos filhos**, mesmo aos de grupos em que o autor da ação no pai não tem
    escrita: a autorização foi dada no vínculo, por quem tinha escrita em
    algum momento nos dois. Cada filho registra a mensagem e a mudança de
    estado com o autor real e a indicação "via ticket pai #N". Isso **não** dá
    ao autor acesso aos filhos que ele não vê: eles continuam 404 para ele.
  - A **resposta** do pai vai aos filhos em qualquer estado, **exceto fechado
    e mesclado** (D46). Num filho resolvido, a mensagem entra sem mudar o
    estado (spec 01).
  - Na **resolução em cascata**, com a regra "responsável obrigatório para
    resolver" ligada (Δ4), o filho sem responsável recebe como responsável
    **quem resolveu o pai** e então é resolvido (D47). Se essa pessoa não tem
    escrita no grupo do filho, não pode ser responsável dele: esse filho **não**
    é resolvido, fica como está e o pai mostra a pendência (D55); os demais
    seguem. A atribuição fica registrada no filho com "via ticket pai #N".
  - Cada solicitante de filho recebe um **e-mail próprio**, sem os endereços
    dos outros solicitantes, e vê a mensagem só dentro do próprio ticket.
    Nenhum solicitante vê o pai, a lista de filhos nem os locais afetados.
  - O pai mostra a contagem de filhos e os **locais afetados**: as salas do
    pai e dos filhos, sem repetição (D48), considerando **só os filhos que
    quem olha pode ver** (§6.3).
- A **reabertura de ticket fechado** é exclusiva de admin (spec 01 §4.2). A
  ação "criar continuação" num ticket fechado (spec 13 Δ13) exige escrita no
  grupo do ticket fechado.
- O acesso é **por agente e por grupo**. Não há herança entre grupos nem acesso
  via equipe no MVP.

---

## 4. Matriz de permissões

Legenda: ✓ permitido; ✗ negado com 403; **404** o recurso não existe para quem
pergunta (§8); — não se aplica. "Solicitante dono" = o solicitante do ticket;
"participante" = pessoa em Cc confirmada. Convidado e visitante: §5.4.

| Ação | admin | agente escrita | agente leitura | agente nenhum | solicitante dono | participante | solicitante via org. | outro solicitante |
|---|---|---|---|---|---|---|---|---|
| Ver o ticket e as mensagens públicas | ✓ | ✓ | ✓ | 404 | ✓ (portal) | ✓ (portal) | ✓ (portal, só leitura) | 404 |
| Ver notas internas e conversas paralelas | ✓ | ✓ | ✓ | 404 | **nunca** | **nunca** | **nunca** | 404 |
| Ver histórico de auditoria | ✓ | ✓ | ✓ | 404 | ✗ | ✗ | ✗ | 404 |
| Ver SLA, prioridade, tipo, grupo, etiquetas, seguidores | ✓ | ✓ | ✓ | 404 | ✗ (não exibidos) | ✗ | ✗ | 404 |
| Responder em público | ✓ | ✓ | ✗ | 404 | ✓ | ✓ | ✗ | 404 |
| Escrever nota interna, mencionar | ✓ | ✓ | ✓ | 404 | — | — | — | — |
| Seguir / deixar de seguir | ✓ | ✓ | ✓ | 404 | — | — | — | — |
| Abrir ou encerrar conversa paralela | ✓ | ✓ | ✗ | 404 | — | — | — | — |
| Mudar campos e estado | ✓ | ✓ | ✗ | 404 | só via resposta e "meu problema foi resolvido" | só via resposta | ✗ | 404 |
| "Meu problema foi resolvido" (aberto, pendente ou em espera → resolvido, D08) | — | — | — | — | ✓ | ✗ | ✗ | 404 |
| Avaliar o atendimento (spec 05 §6.2) | — | — | — | — | ✓ | ✗ | ✗ | 404 |
| Ser responsável | ✓ | ✓ | ✗ | ✗ | — | — | — | — |
| Aplicar macro (inclui em massa, por ticket) | ✓ | ✓ | ✗ | 404 | — | — | — | — |
| Encaminhar com retorno / devolver (§3) | ✓ | ✓ | ✗ | 404 | — | — | — | — |
| Mesclar tickets | ✓ | ✓ (nos dois) | ✗ | 404 | — | — | — | — |
| Marcar como incidente pai / desmarcar (Δ35) | ✓ | ✓ | ✗ | 404 | — | — | — | — |
| Vincular filho ao incidente (Δ35, §3) | ✓ | ✓ (escrita no pai e no filho) | ✗ | 404 | — | — | — | — |
| Desvincular filho (D45, §3) | ✓ | ✓ (escrita no pai ou no filho) | ✗ | 404 | — | — | — | — |
| "Criar artigo" a partir do ticket resolvido (Δ38) | ✓ | ✓ | ✓ | 404 | ✗ | ✗ | ✗ | 404 |
| Reabrir ticket fechado | ✓ | ✗ | ✗ | 404 | via política (spec 01 §4.4) | via política | ✗ | 404 |
| Imprimir o ticket (com notas, por escolha) | ✓ | ✓ | ✓ | 404 | — | — | — | — |
| Pedir e fixar resumo por IA (spec 13 §6) | ✓ | ✓ | ✓ | 404 | ✗ (nunca vê) | ✗ | ✗ | 404 |
| Criar ticket | ✓ | ✓ no grupo | ✗ no grupo | ✗ no grupo | ✓ (portal, formulário, chat) | ✓ | ✓ | ✓ |
| Diretório de pessoas e organizações (ler) | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Criar e editar pessoas e organizações (dados, notas, campos) | ✓ | ✓ (agente completo) | ✗ (agente de apoio) | ✓ se completo | ✗ | ✗ | ✗ | ✗ |
| Mesclar pessoas duplicadas (spec 13 Δ22) | ✓ | ✓ (agente completo) | ✗ (agente de apoio) | ✓ se completo | ✗ | ✗ | ✗ | ✗ |
| Base de conhecimento: ler publicados | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Base de conhecimento: criar e editar rascunhos (spec 07 §3.4) | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Base de conhecimento: publicar, arquivar, excluir, mudar visibilidade (D30) | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Filas e macros pessoais (criar, editar as próprias) | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Filas e macros compartilhadas: usar | ✓ | se liberadas para um grupo seu | idem | idem | ✗ | ✗ | ✗ | ✗ |
| Filas e macros compartilhadas: criar e editar | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Painel de relatórios e exportação (spec 11) | ✓ (tudo) | só os grupos com leitura ou escrita | idem | — | ✗ | ✗ | ✗ | ✗ |
| Calendário de eventos (Δ34, spec 08 §9.7) | ✓ (tudo) | só os tickets de evento dos grupos com leitura ou escrita | idem | — | ✗ | ✗ | ✗ | ✗ |
| Cadastro de locais: ler salas ativas (para escolher o local) | ✓ | ✓ | ✓ | ✓ | ✓ (formulário) | ✓ | ✓ | ✓ |
| Cadastro de locais: criar, editar, desativar; imprimir QR (Δ33) | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| "Minha sala": salvar as próprias salas no perfil (Δ33) | ✓ | ✓ | ✓ | ✓ | ✓ (só as suas) | ✓ (só as suas) | ✓ (só as suas) | ✓ (só as suas) |
| Criar token de API próprio | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Configurações da conta (§10) | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

Observações:
- As linhas de pessoas, organizações, filas, macros e relatórios valem para o
  **agente**, não para o nível num grupo específico; "✓ se completo" na coluna
  "nenhum" lembra que o mesmo agente pode não ter acesso a um grupo e ter
  escrita em outro.
- O diretório de pessoas é da conta inteira: o agente precisa dele para criar
  tickets. O que é filtrado é a **lista de tickets** de cada pessoa (§6.3).
- O solicitante não vê prioridade, tipo, grupo, etiquetas, responsável,
  seguidores, SLA, resumo por IA nem histórico. Vê número, assunto, estado,
  datas, mensagens públicas com o nome de exibição do autor, anexos dessas
  mensagens, a própria avaliação e os campos personalizados marcados como
  visíveis no portal (spec 01 §5). O estado **em espera** aparece para ele como
  "em andamento" (spec 13 Δ3), no portal, na API com sessão de solicitante e
  nos e-mails.
- Uma fila compartilhada restrita a grupos só aparece para membros desses
  grupos (e para o admin). A **contagem** e o conteúdo de qualquer fila
  mostram só os tickets que quem olha pode ver (§6.3).
- **Edição em massa** (spec 13 Δ9): roda ticket a ticket com as permissões de
  quem a executa. Tickets em que ele não tem escrita entram no resultado como
  falha "sem permissão"; tickets invisíveis não podem ser selecionados.
- **"Criar artigo"** (Δ38, D42): basta **ler** o ticket (agente de apoio
  também), porque o resultado é só um rascunho da base, que todo agente pode
  criar (D30). Ticket visível, mas não resolvido → **erro de validação**
  (422), não 403: a permissão existe, falta a condição do ticket (D05). Pedir
  a outra língua cria um **rascunho de tradução do mesmo artigo** (spec 07
  §3.5), com a mesma permissão. O rascunho guarda o ticket de origem; a referência aparece só para
  quem pode ler esse ticket e nunca no portal. Publicar continua só com o
  admin.
- **Calendário de eventos** (Δ34): é uma consulta sobre tickets de evento e
  segue o escopo do §6.3. O solicitante não tem calendário: vê os próprios
  pedidos de evento em "Meus pedidos", como qualquer ticket (spec 07 §8.9).
  Pedir o calendário com sessão de solicitante → 403 (operação sobre a
  classe, §8).
- O **cadastro de locais** é configuração da conta: só o admin cria, edita,
  desativa e imprime QR. Mudar o **local de um ticket** é mudar um campo do
  ticket: exige escrita no grupo dele (§3).

---

## 5. Visibilidade do solicitante

### 5.1 Tickets próprios e em que participa
- O solicitante vê no portal os tickets de que é **solicitante** e aqueles em
  que é **participante**. O participante já recebe as respostas públicas por
  e-mail (spec 02 §9), então o portal não revela nada a mais.
- **Exceção: participante não confirmado.** Quem entrou como participante pela
  regra "remetente novo na conversa" (spec 02 §5) não recebe e-mails até a
  confirmação (spec 02 §5) e só vê o ticket no portal **depois que um agente
  revisar e retirar a marca**. Sem isso, quem recebe um e-mail encaminhado
  poderia ler o histórico público inteiro no portal.
- Só o **solicitante** usa "meu problema foi resolvido" (D08), e só a partir
  de aberto, pendente ou em espera. Nunca leva a fechado. A ação registra uma
  mensagem de sistema e um evento de origem solicitante (spec 01 §4.2). Ela
  **não** exige responsável nem os campos "obrigatórios para resolver": o
  ticket vai para resolvido com a marca **"resolvido pelo solicitante"**, e o
  fechamento automático segue normalmente (D33). A ação não dá ao solicitante
  nenhum outro poder sobre campos.
- Só o **solicitante** avalia o atendimento (spec 05 §6.2).

### 5.2 Tickets da organização (opt-in)
- Por organização, o admin escolhe um de três valores (D07): **desligado**
  (padrão), **só gestores** ou **todos os membros**.
- **Gestor da organização** é uma marca na Pessoa, dada pelo admin. Ela só tem
  efeito na organização atual da pessoa e com o valor "só gestores".
- Com "só gestores", cada gestor vê, numa lista separada do portal, os tickets
  cujo solicitante é da mesma organização. Com "todos os membros", todos os
  membros veem essa lista. Em ambos os casos, **somente leitura**: lê as
  mensagens públicas, mas não responde, não anexa, não resolve, não avalia e
  não muda nada. Para participar, um agente precisa incluí-lo como
  participante.
- A visibilidade é calculada pela organização **atual** do solicitante do
  ticket e de quem vê, e pela marca **atual** de gestor. Quem sai da
  organização ou perde a marca perde o acesso na hora.
- Desligar o compartilhamento (ou passar de "todos os membros" para "só
  gestores") remove o acesso imediatamente.
- Não há adesão automática à organização por domínio de e-mail no MVP.
- Por que somente leitura: em um dos projetos, a organização compartilhada
  permite que colegas **alterem** os tickets uns dos outros, e a própria
  documentação alerta para o risco. Somente leitura entrega a transparência
  pedida ("o que a minha empresa abriu?") sem esse risco. O valor "só
  gestores" segue o meio-termo de outro projeto, em que só o gestor do cliente
  vê os tickets da empresa.

### 5.3 Busca no portal
- A busca do portal cobre a base de conhecimento publicada e o **conteúdo
  público** dos tickets que o solicitante pode ver. Notas internas, conversas
  paralelas e mensagens de sistema internas não entram no índice usado pelo
  portal.

### 5.4 Convidado e visitante
Não são papéis: são formas de acesso sem sessão de solicitante.

| Sujeito | Como chega | O que pode |
|---|---|---|
| **Convidado** | Link do ticket no e-mail de resposta pública, próprio de cada destinatário (spec 07 §7.3) | Só **aquele ticket**, como a pessoa dona do link o veria (§4, coluna do solicitante dono ou do participante): ler e responder. Não lista tickets, não vê outros, não resolve em nome de outra pessoa. Qualquer outro ticket → 404. |
| **Link de avaliação** | Convite da pesquisa (spec 05 §6.2) | Só avaliar aquela resolução daquele ticket. Não abre a conversa. |
| **Visitante** | Portal ou widget sem login | Ler artigos **públicos** publicados (spec 07). Abrir pedido pelo formulário ou pelo chat, se a conta permitir, sempre com nome e e-mail (spec 13 §6); o endereço fica "não verificado". A confirmação de abertura vem do gatilho de criação (spec 05 §6, D25) e, para endereço não verificado, não repete o texto digitado: traz só o número e o link de convidado, no máximo 3 por endereço a cada 24 h. No widget, vê só a conversa da própria sessão. Nenhum ticket por número ou endereço → 404. |

### 5.5 QR da sala (spec 13 Δ33)
O endereço do QR não é segredo (está colado na parede) e não dá acesso a nada
por si: ele só diz qual sala foi escolhida.

| Quem abre | O que acontece |
|---|---|
| Solicitante (logado, convidado ou visitante) | Formulário com o local preenchido (spec 07 §8.8), conforme as regras de envio do formulário. **Nunca** vê tickets da sala, nem a contagem deles. |
| Agente ou admin com sessão | Lista dos tickets abertos daquela sala **que ele já pode ver** (§6.3), com "assumir" (exige escrita, §3) e "novo ticket com este local" (exige escrita no grupo escolhido). Tickets fora do escopo não aparecem nem como contagem. |
| Sem sessão | Tela de entrada (spec 07 §7.1); a sala sobrevive ao login. |

---

## 6. Nota interna nunca chega ao solicitante

### 6.1 Modelo
- Nota interna é um **tipo de mensagem**, não uma marca que se liga e desliga.
  Mensagens são imutáveis (spec 01 §2): uma nota **nunca vira pública**. Para
  tornar público o conteúdo, o agente escreve uma resposta nova (pode citar a
  nota, por ação própria).
- Mensagens de sistema também têm visibilidade. **Públicas**: as respostas
  automáticas que nós enviamos ao cliente (spec 05 §3.3). **Internas**:
  auto-respostas recebidas, bounces, avisos de entrega e de tamanho (spec 02).
  As internas seguem as mesmas regras das notas.
- **Conversa paralela** (spec 13 Δ17): todas as mensagens dela, nos dois
  sentidos, seguem as mesmas regras das notas em todos os caminhos abaixo.
- **Resumo por IA** (spec 13 §6): é gerado só com o que o agente que o pede
  pode ver e só é mostrado a agentes que podem ler o ticket. Segue as regras
  das notas.

### 6.2 Caminhos cobertos

| Caminho | Regra |
|---|---|
| Portal, widget de chat e a API que eles usam | Notas, conversas paralelas, resumo por IA e mensagens de sistema internas não são serializados. Contagens, ordenação e paginação não deixam buracos que revelem a existência deles. Os identificadores de mensagem são opacos (não sequenciais). |
| API com sessão de solicitante | Mesmo filtro do portal. Não existe parâmetro que inclua notas. |
| E-mail ao solicitante e aos participantes | Nota interna não gera e-mail para eles (spec 02 §9). O "histórico resumido" das respostas só inclui mensagens públicas da conversa principal. Seguidores não entram em Cc (spec 13 Δ6). |
| Conversa paralela | Os e-mails dela vão só aos destinatários escolhidos pelo agente, com identificadores próprios; nunca citam a conversa principal sem ação explícita do agente, nem o solicitante. |
| Variáveis em textos automáticos | Nenhuma variável expõe nota nem conversa paralela. "Última mensagem" = última mensagem pública da conversa principal (spec 05 §3.3). |
| Notificações a agentes | Notificação de nota, de menção e de conversa paralela vai só a agentes que **podem ler** o ticket (leitura ou escrita no grupo, ou leitura pela origem do encaminhamento, §3), e **nunca ao autor** (D12). Quem recebe é definido pela spec 09 (responsável, seguidores, mencionados). Seguidor que perde o acesso deixa de receber. |
| Menções (spec 13 Δ7) | Mencionar quem não pode ler o ticket mostra um aviso ao autor, não notifica e **não** dá acesso. Menção em resposta pública não é convertida. |
| Resposta de agente a e-mail de notificação | Vira **nota interna** por padrão (D02; a conta pode mudar para "pública"). Agente com só leitura: sempre nota interna, com aviso. Agente sem acesso ao ticket: a mensagem vai para a quarentena com o motivo "agente sem acesso" (spec 02 §5). |
| Anexos | O download é autorizado a cada requisição pela visibilidade da **mensagem** dona do anexo. Link direto para anexo de nota ou de conversa paralela, usado por solicitante ou agente sem acesso → 404. O link não funciona por ser difícil de adivinhar: a permissão é verificada sempre. |
| Busca | O índice guarda a visibilidade de cada trecho. Buscas de solicitante filtram pelo público; buscas de agente filtram pelos grupos legíveis (§6.3). |
| Webhooks (spec 10) | Só admins criam assinaturas. As notas internas só saem no **tipo de evento próprio** de nota interna, sempre marcadas como internas (D03). As mensagens de conversa paralela saem no mesmo tipo de evento das mensagens internas, com a indicação "conversa paralela" (D37). Os eventos de ticket e de mensagem pública nunca trazem notas, mensagens de sistema internas nem mensagens de conversa paralela. Quem não quer receber notas não assina esse tipo; não existe "audiência" nem escopo separado para isso (D31). |
| Impressão | A versão de impressão inclui notas só por escolha do agente e só para agentes (spec 13 Δ20). |
| Mescla | Notas da origem continuam notas no destino (spec 01 §6). |
| Ticket novo por resposta a fechado (política `novo`) e "criar continuação" | As notas e as conversas paralelas do ticket anterior não são copiadas. |
| Exportação | Só para agentes e admins, limitada aos grupos legíveis (spec 11). |

### 6.3 Escopo do agente em todos os caminhos
O mesmo filtro (grupos com leitura ou escrita, mais a leitura pela origem do
encaminhamento, §3) vale para: abrir o ticket, listas, filas salvas, contadores,
modo sequência, busca, sugestões ao digitar um número, histórico de tickets na
ficha da pessoa e da organização, tickets anteriores e relacionados no painel
de contexto (spec 13 Δ18), página inicial (spec 13 Δ21), anexos, notificações,
relatórios, exportação, o vínculo "continuação de #N" (spec 01 §4.4), a lista
de filhos, a contagem e os locais afetados de um incidente pai (Δ35), o
calendário de eventos (Δ34), a lista de tickets de uma sala aberta pelo QR
(Δ33), a fila padrão "Quase escalando" (Δ37) e a referência ao ticket de
origem de um rascunho de artigo (Δ38). Um ticket fora do escopo não aparece
nem como contagem.

---

## 7. Tokens de API

- **Pessoas**: só **agentes e admins** criam tokens, e só **para si mesmos**.
  Solicitantes usam a sessão do portal. Personificação ("agir como outro
  usuário") fica fora do MVP.
- **Identidade de integração** (D04): só o admin a cria, define o acesso dela
  por grupo (nenhum, leitura ou escrita) e cria, lista e revoga os tokens dela.
  É o único caso em que alguém cria token para outro ator. O admin **não**
  cria tokens para outras pessoas.
- **Permissão efetiva = permissões atuais do dono ∩ escopos do token**,
  calculada **a cada requisição**. Se o dono perde um grupo, o token perde o
  grupo; se o admin vira agente, os escopos de administração deixam de valer,
  mas o token não é apagado (D14).
- Escopos do MVP, os mesmos para pessoas e integrações:
  - **leitura**: ler tickets, mensagens, pessoas, organizações, base de
    conhecimento e relatórios, dentro dos grupos do dono;
  - **escrita**: leitura + criar e alterar tickets, responder, escrever notas,
    criar e alterar pessoas e organizações e editar artigos, sempre dentro do
    que o dono pode fazer na matriz (§4);
  - **administração**: escrita + configurações da conta; exige que o dono seja
    admin ou uma identidade de integração **administrativa** (D36).
- **Escopo maior que o papel é recusado na criação** (D14): um agente não
  recebe token com escopo de administração. Uma identidade de integração só o
  recebe se o admin a tiver criado marcada como **administrativa** (D36).
- Cada token tem nome, escopos, **validade opcional**, data de criação e
  **último uso**. O valor aparece **uma única vez**, na criação, e é guardado
  só como hash. O token pode ser revogado a qualquer momento, com efeito
  imediato e definitivo.
- **Desativação do dono**: os tokens ficam **suspensos** e deixam de autenticar
  (401) enquanto o dono estiver desativado (D26). Reativar o dono faz voltar
  os tokens que não expiraram e não foram revogados (spec 10 §3.2). Durante a
  suspensão, o admin pode revogá-los. Desativar uma identidade de integração
  tem o mesmo efeito.
- O admin vê e revoga tokens de qualquer pessoa ou integração da conta.
- Um token **não** cria, lista nem revoga tokens. Isso exige sessão interativa.
- Criação, revogação e expiração geram eventos de auditoria. Ações feitas com
  token têm origem **API** e a identificação do token (spec 01 §7); com token
  de integração, o ator é a identidade de integração.
- Restrição de token de pessoa a grupos específicos fica no roadmap; para
  limitar por grupo, usa-se uma identidade de integração.

---

## 8. 404, 403 e 422

Regra (D05): **a visibilidade é avaliada primeiro.** Recurso que quem pergunta
não pode ver → **404**, seja qual for o papel ou o escopo. Recurso visível, mas
ação proibida pelo papel, pelo nível de acesso ao grupo ou pelo escopo do
token → **403**. Regra de negócio violada → **422**. Conflito de versão →
**409** (D01, spec 10).

Ordem de verificação, sempre a mesma:

| # | Verificação | Falha |
|---|---|---|
| 1 | Autenticação (sessão ou token válido, não expirado, não revogado, dono ativo) | 401 |
| 2 | Recurso existe **na conta** de quem pergunta e é **visível** para ele | 404 |
| 3 | Papel, nível de acesso e escopo permitem a **ação** (ex.: token só de leitura tentando escrever; leitura tentando responder; agente comum reabrindo fechado; solicitante pedindo histórico de auditoria) | 403 |
| 4 | Validação de dados e de transição (spec 01 §4.2; ex.: fechado → pendente, resolver sem responsável com a regra ligada, campo oculto com valor) | 422 |
| 5 | Versão esperada desatualizada (D01) | 409 |

- Operações sobre a **classe** de recursos, sem recurso específico (ex.:
  agente listando gatilhos, solicitante criando token), não têm o que esconder
  e caem direto na verificação 3: **403**.
- A resposta 404 de um recurso proibido é **idêntica** à de um recurso
  inexistente: mesmo status, mesmo corpo, sem dicas como "mesclado", "fechado"
  ou "de outra conta".
- Referências dentro do corpo de uma requisição (ex.: grupo, responsável,
  solicitante, ticket de destino da mescla) que apontam para algo invisível ou
  de outra conta dão **erro de validação "não encontrado"** (422), igual ao de
  um identificador inexistente.
- Exceção: **vincular um filho** a um incidente (§3). O filho é o recurso
  sobre o qual se age, não um dado do corpo: filho invisível → **404** (D43),
  igual a um ticket inexistente.
- No portal, a página de um ticket que o solicitante não pode ver é a mesma
  página de "não encontrado".
- A spec 01 TL-54 (solicitante pedindo o histórico de um ticket que ele vê)
  cai na verificação 3: **403**. Agente comum reabrindo fechado (spec 01
  TL-11): **403**, porque a proibição é do papel; uma transição que nem o
  admin pode fazer: **422**.

---

## 9. Multi-tenancy

- **Toda entidade pertence a exatamente uma conta** (spec 01 §2): pessoas,
  endereços, organizações, grupos, tickets, mensagens, conversas paralelas,
  anexos, avaliações, eventos de auditoria, campos, gatilhos, macros, filas
  salvas, políticas de SLA, calendários, caixas de e-mail, formulários, widgets
  de chat, webhooks, identidades de integração e tokens.
- A conta de uma requisição vem **só** da autenticação (sessão ou token) ou,
  na entrada de e-mail, da **caixa** que recebeu a mensagem e, no widget, da
  **instalação do widget**. Nunca vem de um parâmetro enviado pelo cliente.
- O portal e a área do agente respondem no **domínio próprio da conta** (spec
  13 Δ32; na EARJ, help.earj.com.br). Antes do login, a conta é a do domínio
  em que a requisição chegou; depois, a da sessão. Uma sessão aberta no
  domínio de uma conta não vale no domínio de outra, e a entrada com Google só
  aceita o domínio da escola configurado na conta daquele endereço (§2.1).
- **Referência entre contas é impossível**: toda gravação que liga uma entidade
  a outra verifica se as duas estão na mesma conta. Se não estiverem, a
  referência é tratada como inexistente (§8). Isso vale também para
  configurações: um gatilho, macro ou fila que cita um grupo de outra conta não
  pode ser salvo.
- O mesmo e-mail pode existir como pessoa em duas contas: são pessoas
  distintas, sem ligação (spec 01 §2). Um login pertence a uma conta. Não há
  troca de conta nem usuário em várias contas no MVP. Mesclar pessoas só
  acontece dentro da mesma conta.
- Threading de e-mail ignora identificadores de outra conta (spec 02 §4.2),
  inclusive os das conversas paralelas. Anexos idênticos só compartilham
  armazenamento dentro da mesma conta (spec 02 §8). A numeração é por conta
  (spec 01 §3).
- Índices de busca, caches, filas de tarefas, arquivos, entregas de webhook e
  pedidos ao provedor de IA levam a conta. Toda tarefa em segundo plano carrega
  a conta e a confere antes de tocar numa entidade.
- O MVP roda **uma** conta, mas os testes automatizados rodam **sempre com
  duas** (A e B), para provar o isolamento desde o início.
- Administração da instalação (criar contas, operador acima das contas) fica
  fora do produto no MVP: é feita pela infraestrutura.

---

## 10. Configurações exclusivas de admin

- Caixas de e-mail, endereços de suporte, domínio de envio e quarentena (spec
  02).
- Grupos, agentes, papéis, acessos por grupo, desativação de pessoas e a marca
  **gestor da organização**.
- Publicar, arquivar e excluir artigos da base de conhecimento e mudar a
  visibilidade deles (D30, spec 07). Agentes só criam e editam rascunhos.
- O valor de compartilhamento de tickets de cada organização (§5.2). Os dados
  da organização (nome, notas, campos) podem ser editados por agente completo
  (§4).
- Campos personalizados de ticket, pessoa e organização, com as condições de
  exibição (spec 01 §5, spec 13 Δ2, Δ22), formulários do portal (spec 13 Δ1)
  e política de resposta a fechado por grupo (spec 01 §4.4).
- Gatilhos, **macros compartilhadas**, **filas compartilhadas**, políticas de
  SLA, calendários e a pesquisa de satisfação (spec 05, spec 13 Δ9, Δ15).
- Webhooks, identidades de integração (inclusive a marca **administrativa**,
  D36) e os tokens delas, e a revogação de
  tokens de terceiros (§7).
- Widget de chat, marca da conta no portal (spec 13 Δ16, Δ25) e o provedor de
  IA (spec 13 §6).
- Entrada com Google: o provedor e o **domínio da escola** (spec 13 Δ31,
  §2.1); o domínio próprio do portal (Δ32).
- **Cadastro de locais** (campus, prédio, andar, sala), desativação de salas e
  **impressão dos QR** por prédio ou andar (Δ33).
- Formulário de evento e a antecedência mínima dos pedidos de evento (Δ34).
- Parâmetros da conta: fechamento automático, responsável obrigatório para
  resolver (spec 13 Δ4), limites de auto-resposta, portal e base de
  conhecimento.
- Reabrir ticket fechado (spec 01 §4.2) e reprocessar ou descartar a quarentena.

Toda mudança de configuração gera um evento de auditoria da conta, com antes e
depois.

---

## 11. Abordagens comparadas

| Projeto | Abordagem observada (documentação) | Prós | Contras |
|---|---|---|---|
| Zammad | Três papéis de fábrica editáveis e somáveis; permissões hierárquicas por funcionalidade; admin não vê tickets sem a permissão de agente; nível por grupo com cinco graus; organização compartilhada em que colegas **veem e alteram** os tickets uns dos outros; nota interna como atributo do artigo; token por usuário, nunca acima do criador; personificação pela API. | Granularidade por grupo; token limitado ao dono. | Cinco níveis e duas formas de atribuir confundem; organização compartilhada com escrita é arriscada; nota como atributo pode ser trocada por engano. |
| Chatwoot (CE) | Várias contas por instalação; admin e agente; agente vê só as caixas de que é membro; papéis finos só na versão paga; token pessoal sem escopos; token de plataforma limitado ao que criou. | Isolamento real por conta; escopo por caixa simples. | Sem escopos de token; sem visão de organização para o cliente. |
| FreeScout | Admin e usuário; acesso por caixa; opção "só atribuídos"; clientes numa tabela única compartilhada por todas as caixas; portal e API em módulos pagos. | Simples. | Sem isolamento de contatos; correções de segurança recentes mostram vazamentos em visões restritas. |
| osTicket | Departamento primário + acesso estendido com papel por departamento; opção "só atribuídos"; colaboração automática de contatos da organização; chave de API presa a um IP e só para criar tickets e rodar tarefas. | Papel por departamento é expressivo. | Modelo pesado; API sem leitura; visibilidade por organização feita por colaboração implícita. |
| Znuny | Grupos × papéis com permissões granulares (ler, mover, criar, nota, dono, prioridade, escrita); cliente vê por padrão os tickets da empresa, com opção de negar; cliente em várias empresas; API com credenciais do usuário. | Muito expressivo; nota como permissão separada. | Complexo de administrar; padrão "vê a empresa" é permissivo. |
| UVdesk | Admin, agente, cliente; privilégio nomeado por agente; escopo de visão global, por grupo, por equipe ou individual. | Escopo de visão claro. | Organização do cliente e escopos de token não documentados. |
| Frappe Helpdesk | Admin, gestor, agente; restrição opcional por equipe; permissões do framework por tipo de documento e campo; contato comum vê os próprios tickets e o **gestor do cliente** vê os da organização; chave por usuário, autorizada como o usuário. | Gestor do cliente é um bom meio-termo; tokens agem como o usuário. | Duas camadas de permissão (produto e framework) são difíceis de auditar pela API genérica. |

### Escolha do PantherDesk

| Aspecto | Escolha | Por quê |
|---|---|---|
| Papéis | admin, agente, solicitante fixos; identidade de integração como ator não humano; permissões nomeadas internas | simples agora, extensível depois; integração sem fingir que é uma pessoa |
| Admin e tickets | admin tem escrita em todos os grupos e pode ser responsável | quem configura precisa ver o efeito |
| Escopo do agente | por grupo: nenhum, leitura (com nota), escrita; leitura temporária pela origem do encaminhamento | três níveis cobrem os casos reais, inclusive o agente de apoio; quem encaminha acompanha o que mandou |
| Nota interna | tipo de mensagem imutável, filtrada numa camada única; conversa paralela e resumo por IA seguem a mesma regra | não dá para "tornar pública por engano" |
| Organização | desligado / só gestores / todos os membros, somente leitura, padrão desligado | transparência sem o risco de colegas alterarem tickets; gestor como meio-termo |
| Tokens | por dono, interseção com escopos, avaliada a cada requisição; escopo acima do papel recusado | nunca acima do dono, nem depois de o dono perder acesso |
| 404/403/422 | visibilidade primeiro; 403 só para o visível ou para a classe; 422 para regra de negócio | não confirma existência; mantém mensagens úteis para quem já vê |
| Tenancy | conta em toda entidade desde o início; testes com duas contas | evita o modelo de contatos compartilhados e permite várias contas depois sem migração |

---

## 12. Casos de teste (critérios de aceite)

Atores: `ag1` (escrita em N1), `ag2` (escrita em N1, **leitura** em
Financeiro), `ag3` (escrita em Financeiro, nenhum acesso a N1), `apoio1`
(agente de apoio: **leitura** em N1 e em Financeiro), `admin`; integração
`int1` (leitura em N1); solicitantes `ana` e `bia` (org. Acme), `cris` (sem
org.).
Tickets: #1010 (ana, N1, com uma nota interna com anexo `interno.pdf`), #1020
(bia, N1), #1030 (cris, Financeiro), #1040 (ana, Financeiro). Compartilhamento
da Acme **desligado**, salvo indicação. Contas A (todos os acima) e B (com
`agB` e #1000 próprio).

### 12.1 Escopo do agente
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| PE-01 | — | ag3 lê #1010 pela API | 404 com corpo idêntico ao de #9999 inexistente |
| PE-02 | — | ag3 abre a URL de #1010 na área do agente | página "não encontrado" |
| PE-03 | — | ag3 busca "1010" e uma palavra que só existe em #1010 | nenhum resultado; contadores das filas não incluem tickets do N1 |
| PE-04 | — | ag3 abre a ficha de ana | vê os dados de contato; a lista de tickets mostra só #1040; a contagem é 1 |
| PE-05 | — | ag3 baixa um anexo de #1010 pelo link direto | 404 |
| PE-06 | — | ag2 abre #1030 | vê mensagens, notas e histórico |
| PE-07 | — | ag2 responde em público em #1030 | 403; nada gravado |
| PE-08 | — | ag2 escreve nota interna em #1030 | aceita; estado e SLA não mudam |
| PE-09 | — | ag2 muda a prioridade de #1030 | 403; nenhum evento |
| PE-10 | — | ag1 define ag3 como responsável de #1010 | 422: responsável sem escrita no grupo |
| PE-11 | ag1 é responsável de #1010 | ag1 move #1010 para Financeiro (transferência normal) | aceito; #1010 fica sem responsável; a próxima leitura de #1010 por ag1 dá 404 |
| PE-12 | — | admin lê e altera #1010, #1030 e #1040 | aceito em todos |
| PE-13 | ticket fechado no N1 | ag1 tenta reabrir | 403 (proibido pelo papel, spec 01 TL-11); admin consegue (TL-12) |
| PE-14 | — | ag1 tenta editar um gatilho | 403 |
| PE-15 | — | admin se define responsável de #1030 (sem ser membro do Financeiro) | aceito (D06) |
| PE-16 | ticket fechado no N1 | admin tenta mudar o estado de fechado para pendente | 422 (transição que a matriz não permite a ninguém) |
| PE-17 | — | apoio1 abre #1010, escreve nota e segue o ticket | aceito nas três ações |
| PE-18 | — | apoio1 tenta assumir #1010, responder em público e abrir conversa paralela | 403 nas três; nada gravado |
| PE-19 | ag1 com escrita só em N1 | ag1 lê #1030 depois de digitar "1030" na busca rápida | nenhuma sugestão; 404 ao abrir |

### 12.2 Solicitante e organização
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| PE-20 | — | ana lista os tickets no portal | #1010 e #1040; não #1020 |
| PE-21 | — | ana pede #1020 pela API do portal | 404 |
| PE-22 | Acme com "todos os membros" | ana abre "tickets da organização" | vê #1020 em somente leitura, só com mensagens públicas |
| PE-23 | idem | ana tenta responder em #1020 | 403; nada gravado |
| PE-24 | idem | cris lista tickets | só os próprios; nada da Acme |
| PE-25 | idem; bia sai da Acme | ana atualiza a lista | #1020 some da lista da organização |
| PE-26 | bia está em Cc de #1030 (participante) | bia abre o portal | vê #1030 |
| PE-27 | um estranho entrou em #1010 pela regra "remetente novo na conversa" | o estranho abre o portal | não vê #1010; depois que ag1 retira a marca, vê |
| PE-28 | — | ana pede o histórico de auditoria de #1010 | 403 (spec 01 TL-54) |
| PE-29 | — | ana pede os campos de #1010 | não aparecem prioridade, tipo, grupo, etiquetas, responsável, seguidores nem SLA |
| PE-80 | Acme com "só gestores"; ana é gestora, bia não | bia lista os pedidos da organização; ana lista | bia: a lista não aparece; ana: vê #1020, somente leitura |
| PE-81 | após PE-80 | admin retira a marca de gestora de ana | na requisição seguinte, ana não vê mais #1020 |
| PE-82 | #1010 em espera | ana abre #1010 no portal e pela API do portal | o estado aparece como "em andamento"; o termo "em espera" não aparece |
| PE-83 | #1010 em espera | ana usa "meu problema foi resolvido" | #1010 resolvido; mensagem de sistema; evento de origem solicitante |
| PE-84 | bia é participante de #1030 | bia tenta "meu problema foi resolvido" em #1030 | 403 |
| PE-85 | Acme com "todos os membros" | bia tenta "meu problema foi resolvido" em #1010 (de ana) | 403 |
| PE-86 | #1010 resolvido | ana tenta levar #1010 a fechado pela API do portal | 403; nenhum evento |
| PE-87 | #1030 resolvido com convite de avaliação | bia (participante) tenta avaliar | 403; cris avalia normalmente |
| PE-88 | e-mail de resposta pública de #1010 enviado a ana com o link de convidado | o link é usado sem login; depois, com o mesmo link, pede-se #1040 | #1010 abre como ana o veria; #1040 → 404 |
| PE-89 | visitante sem login | pede #1010 pelo número e um artigo interno pelo endereço exato | 404 / tela de "não encontrado" para os dois |

### 12.3 Nota interna
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| PE-30 | nota em #1010 entre duas mensagens públicas | ana abre #1010 no portal e na API do portal | só as duas mensagens públicas; sem buraco visível na contagem nem na paginação |
| PE-31 | idem | ag1 responde em público | o e-mail para ana e para os participantes não contém o texto da nota, nem no histórico resumido |
| PE-32 | idem | ana usa o link direto de `interno.pdf` | 404 |
| PE-33 | idem | ana busca no portal uma palavra que só está na nota | nenhum resultado; ag1 encontra #1010 com a mesma busca |
| PE-34 | ag2 e admin seguem #1010; ag1 é o responsável | ag1 escreve nota em #1010 | nenhum e-mail para ana nem para os participantes; ag2 e admin notificados; ag1 (autor) **não** é notificado (D12); ag3 não recebe nada |
| PE-35 | a última mensagem de #1010 é uma nota | um gatilho envia e-mail a ana com a variável "última mensagem" | o e-mail traz a última mensagem **pública** |
| PE-36 | assinatura de webhook S1 com os tipos "ticket atualizado" e "mensagem pública criada" | nota criada em #1010 | nenhuma entrega a S1 traz o conteúdo da nota (D03) |
| PE-37 | assinatura S2 com o tipo "nota interna criada" | idem | S2 recebe o evento da nota, marcado como interno; só admin consegue criar S2 |
| PE-38 | — | tentar transformar a nota em pública pela API | recusado: mensagens são imutáveis |
| PE-39 | #1011 (bia, com nota) mesclado em #1010 | ana abre #1010 no portal | as mensagens públicas de #1011 aparecem; a nota não |
| PE-40 | bounce recebido em #1010 (mensagem de sistema interna) | ana abre #1010 no portal | o bounce não aparece |
| PE-41 | conversa paralela de #1010 com um fornecedor, com uma resposta dele | ana abre #1010 no portal, busca uma palavra da resposta e recebe a próxima resposta pública | nada da conversa paralela aparece, nem na busca, nem no e-mail; ag1 e apoio1 a veem |
| PE-42 | S1 de PE-36 | o fornecedor responde na conversa paralela | nenhuma entrega a S1 traz a mensagem |
| PE-43 | bounce em #1010 | evento "mensagem pública criada" | não é emitido para o bounce (mensagem de sistema interna) |
| PE-44 | conta com o padrão D02 | ag1 responde a um e-mail de notificação de #1010; apoio1 também; ag3 também | ag1 e apoio1: nota interna (apoio1 recebe aviso); ag3: quarentena "agente sem acesso"; nada é enviado a ana |
| PE-45 | — | ag1 escreve nota mencionando ag3 em #1010 | aviso ao ag1; ag3 não é notificado e continua com 404 em #1010 |
| PE-46 | ag2 segue #1030 (leitura no Financeiro) | admin remove o acesso de ag2 ao Financeiro; ag3 escreve nota em #1030 | ag2 não é notificado; #1030 some das listas de ag2 |
| PE-47 | ag1 fixou um resumo por IA em #1010 | ana abre #1010 no portal e pela API do portal | o resumo não aparece |
| PE-48 | — | ag1 imprime #1010 sem marcar "incluir notas" | a versão de impressão não traz a nota |

### 12.4 Tokens de API
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| PE-50 | token de ag1 com escopo leitura | ler #1010 / responder em #1010 | 200 / 403 |
| PE-51 | token de ag1 com escopo escrita | ler #1030 | 404 (ag1 não tem acesso ao Financeiro) |
| PE-52 | token de ag1 com escrita | ag1 perde o acesso ao N1; o token lê #1010 | 404 na requisição seguinte |
| PE-53 | idem | ag1 é desativado; o token faz qualquer requisição | 401 |
| PE-54 | — | ag1 tenta criar token com escopo administração | recusado (403, D14); nenhum token criado |
| PE-55 | token de admin com administração | admin vira agente; o token chama uma configuração | 403; o token continua existindo e lê tickets dos grupos do dono |
| PE-56 | token qualquer | o token tenta criar ou listar tokens | 403 |
| PE-57 | token expirado / token revogado | qualquer requisição | 401 / 401, com efeito imediato após a revogação |
| PE-58 | token de ag1 com escrita | muda a prioridade de #1010 | evento de auditoria com origem API e a identificação do token; o último uso do token é atualizado |
| PE-59 | — | ana tenta criar token | 403 |
| PE-60 | token só de leitura de ag1 | escrever em #1030 (invisível para o dono) | **404** (a visibilidade vem antes do escopo, D05); nada revela se #1030 existe. Variante: escrever em #1010 (visível) → 403 pelo escopo |
| PE-61 | — | requisição sem autenticação | 401 |
| PE-62 | admin cria `int1` com leitura em N1 e um token de leitura para ela | o token lê #1010 e #1030 | 200 / 404; os eventos mostram o nome da integração |
| PE-63 | — | ag1 tenta criar uma identidade de integração | 403 |
| PE-64 | — | admin tenta criar token para ag1; depois, token com escopo administração para `int1` | recusado nos dois casos |
| PE-65 | PE-53 | ag1 é reativado; o token (não expirado, não revogado) faz uma requisição | 200 |
| PE-66 | token de leitura de ag1 | pede o painel de relatórios pela API | só números dos grupos legíveis de ag1 (N1) |
| PE-67 | token de escrita de `int1` (leitura em N1) | responde em público em #1010 | 403 (o nível do dono no grupo é leitura) |

### 12.5 Isolamento entre contas
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| PE-70 | — | admin da conta A lê o identificador interno de #1000 da conta B | 404 |
| PE-71 | — | ag1 cria ticket na conta A informando o identificador de um grupo da conta B | 422 "não encontrado", igual a identificador inexistente |
| PE-72 | — | admin da conta A salva gatilho com responsável agB | recusado |
| PE-73 | ana@ existe como pessoa nas contas A e B | ana entra no portal da conta B | não vê nenhum ticket da conta A |
| PE-74 | — | ag1 tenta mesclar #1010 num ticket da conta B | 422 "não encontrado" |
| PE-75 | — | e-mail na conta A com In-Reply-To de uma mensagem da conta B | tratado como desconhecido (spec 02 EM-10) |
| PE-76 | mesmo anexo enviado nas duas contas | — | o armazenamento não é compartilhado entre as contas |
| PE-77 | — | a busca de agB por uma palavra presente só em tickets da conta A | nenhum resultado |
| PE-78 | ana@ nas contas A e B | ag1 tenta mesclar a pessoa ana da conta A com a da conta B | 422 "não encontrado" |
| PE-79 | — | o fornecedor responde, na conta A, a uma conversa paralela da conta B | tratado como desconhecido; nada entra na conta A |

### 12.6 Recursos da operação EARJ
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| PE-90 | ag1 é responsável de #1010 | ag1 encaminha com retorno para Financeiro, com nota | #1010 no Financeiro, sem responsável, estado **aberto** (D23); ag1 e ag2 continuam vendo #1010 (leitura pela origem); ag1 escreve nota: aceito; ag1 responde em público: 403; ag3 tem escrita |
| PE-91 | após PE-90 | ag3 usa "devolver" | #1010 volta ao N1 com ag1 responsável; ag3 passa a receber 404 em #1010 |
| PE-92 | após PE-90 | ag2 (leitura no Financeiro) tenta "devolver" | 403 |
| PE-93 | após PE-90 | admin transfere #1010 para um terceiro grupo (nem N1 nem Financeiro), sem retorno | a leitura pela origem acaba: ag1 recebe 404 em #1010; ag1 é avisado do cancelamento |
| PE-94 | fila compartilhada "Financeiro aberto" restrita ao Financeiro | ag1 lista as filas; ag2 abre a fila | ag1 não vê a fila; ag2 vê a fila com a contagem só dos tickets que ele pode ver |
| PE-95 | — | ag1 tenta criar uma fila compartilhada; cria uma pessoal | 403 / aceito; a fila pessoal não aparece para ag2 |
| PE-96 | ag1 tem 10 filas pessoais | cria a 11ª | 422 |
| PE-97 | macro pessoal de ag1 | ag2 tenta aplicá-la pela API; ag1 tenta editar uma macro compartilhada | 404 / 403 |
| PE-98 | ag2 seleciona #1010, #1020 (N1, escrita) e #1030 (Financeiro, leitura) numa fila | edição em massa: prioridade → alta | #1010 e #1020 alterados; #1030 falha com "sem permissão" |
| PE-99 | — | apoio1 tenta mesclar duas pessoas e editar as notas da Acme; ag1 faz o mesmo | apoio1: 403 nas duas; ag1: aceito |
| PE-100 | após PE-90 | ag2 (escrita no N1, sem ser o agente de origem) filtra a fila do N1 por "encaminhado" | #1010 aparece com a marca "encaminhado"; estado mostrado: aberto; ag2 lê e escreve nota (D23, D24); ag2 responde em público: 403 |
| PE-101 | rascunho de artigo criado por ag1 | ag1 tenta publicar, arquivar e excluir o artigo; admin publica | ag1: 403 nas três; admin: publicado (D30); não existe marca "pode publicar" a conceder |
| PE-102 | — | admin cria `int2` marcada como administrativa e um token com escopo administração para ela; repete para `int1` (não administrativa) | `int2`: token criado e chama uma configuração com sucesso; `int1`: recusado (D36) |
| PE-103 | conta com "responsável obrigatório para resolver" ligado; campo "causa" obrigatório para resolver; #1010 e #1020 sem responsável e sem "causa" | ana usa "meu problema foi resolvido" em #1010; ag1 tenta resolver #1020 | #1010 resolvido com a marca "resolvido pelo solicitante", sem erro de validação (D33); #1020: 422 |
| PE-104 | token de ag1 suspenso (ag1 desativado, PE-53) | admin revoga o token; ag1 é reativado; o token faz uma requisição | 401; o token não volta (D26) |
| PE-105 | S1 de PE-36 e S2 de PE-37 | o fornecedor responde na conversa paralela de #1010 | S2 recebe o evento de mensagem interna, com a indicação "conversa paralela" (D37); S1 não recebe nada da mensagem |
| PE-106 | — | admin tenta criar uma assinatura de webhook informando uma "audiência" que exclua notas | o campo não existe: 422 (D31) |
| PE-107 | visitante abre 4 pedidos pelo formulário com o mesmo endereço não verificado em 24 h | — | 3 confirmações, só com número e link de convidado, sem o texto digitado; a 4ª não é enviada (D25) |

### 12.7 Entrada com Google, incidentes, locais, eventos e artigos (v0.3)
Contexto adicional: a conta A tem o provedor Google configurado com o domínio
da escola `escola.test`; ag1, ag2, ag3, apoio1 e admin têm endereço nesse
domínio; ana, bia e cris têm endereços de outros domínios. Sala `B-201`
(campus Barra, prédio A, 2º andar) com #1010 (N1) e #1030 (Financeiro) abertos
e com esse local. #1060 é um ticket de evento do Financeiro, solicitante cris.

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| PE-108 | ag1 cadastrado como agente (escrita em N1) | ag1 entra com a conta Google dele | sessão de agente com escrita em N1; evento de auditoria da entrada |
| PE-109 | — | ag1 procura entrar com senha ou pedir link por e-mail na área do agente | não há essas opções; um link pedido no portal com o endereço de ag1 não é enviado (spec 07 KB-57) |
| PE-110 | prof@escola.test não existe na conta | entra com Google | Pessoa criada como **solicitante**, sem organização e sem grupos, endereço verificado; a área do agente não abre para ela (403 pela API) |
| PE-111 | — | uma conta Google de `outro.test` tenta entrar | recusada; nenhuma Pessoa criada; a tela oferece o link por e-mail |
| PE-112 | ag1 desativado | ag1 entra com Google | recusado (401); ag1 não vira solicitante; nada é criado |
| PE-113 | após PE-110 | admin dá a prof@escola.test o papel agente com escrita em N1 | na requisição seguinte, prof abre a área do agente e vê #1010 |
| PE-114 | cris (endereço fora do domínio) | admin tenta dar a cris o papel agente | 422 (endereço principal fora do domínio da escola) |
| PE-115 | a conta Google de prof pertence, no Google, a um grupo de administradores do domínio | prof (solicitante no PantherDesk) entra | sessão de solicitante; nenhum papel ou grupo vem do Google |
| PE-116 | aplicação em modo de produção, Google não configurado; depois, modo de desenvolvimento sem Google; depois, modo de desenvolvimento com Google | abrir o login de desenvolvimento | produção: 404; desenvolvimento sem Google: lista os usuários de demonstração e entra com um clique; desenvolvimento com Google: 404 |
| PE-117 | — | ag1 marca #1010 como incidente e vincula #1020 (N1) e depois #1030 (Financeiro) | #1010 é pai; #1020 vinculado; #1030: **404** (ag1 não vê o Financeiro, D43) |
| PE-118 | #1010 pai com #1020 | ag2 (escrita em N1, leitura no Financeiro) vincula #1030; admin vincula #1030 | ag2: 403; admin: aceito |
| PE-119 | após PE-118 | ag1 envia resposta pública em #1010 | ana, bia e cris recebem cada uma o seu e-mail, sem o endereço das outras; #1020 e #1030 registram a mensagem com autor ag1 e "via ticket pai #1010"; ag1 continua recebendo 404 em #1030 |
| PE-120 | após PE-118; #1020 na sala `B-105`; #1010 e #1030 em `B-201` | ag1 e admin abrem #1010 | ag1: 1 filho (#1020); locais afetados `B-201` (do pai) e `B-105`; admin: 2 filhos; locais afetados `B-201` e `B-105`, cada um uma vez (D48) |
| PE-121 | após PE-119 | cris abre #1030 no portal | vê a resposta pública como mensagem de #1030; nada indica o pai, os outros filhos nem os outros solicitantes |
| PE-122 | — | apoio1 tenta marcar #1020 como incidente e vincular #1040 a #1010 | 403 nos dois |
| PE-123 | — | ag1 tenta criar uma sala, desativar `B-201` e imprimir os QR do prédio A; admin faz o mesmo | ag1: 403 nos três; admin: aceito |
| PE-124 | — | ag1 abre o QR de `B-201`; apoio1 abre o mesmo QR e tenta assumir #1010 | ag1: lista só #1010, com "assumir"; apoio1: lista #1010 e #1030, "assumir" → 403 |
| PE-125 | — | ana abre o QR de `B-201` com sessão do portal | formulário com o local preenchido; nenhuma lista nem contagem de tickets da sala |
| PE-126 | — | ag1, ag2 e ana pedem o calendário de eventos de novembro | ag1: #1060 não aparece nem na contagem do dia; ag2 (leitura no Financeiro): vê #1060; ana: 403 |
| PE-127 | #1010 resolvido | apoio1 usa "Criar artigo" e tenta publicar o rascunho; ag3 abre o rascunho | rascunho criado com origem #1010; publicar: 403; ag3 vê o rascunho sem a referência a #1010 |
| PE-128 | após PE-118 (admin vinculou #1030 a #1010) | ag3 (escrita só no Financeiro) desvincula #1030; depois ag1 tenta desvincular #1030 de novo do lado de #1010 | ag3: aceito (escrita no filho, D45); #1030 guarda as mensagens já recebidas. ag1: #1030 já não é filho; nada muda |
| PE-129 | #1010 pai com #1020 (N1, resolvido) e #1040 (N1, fechado) | ag1 responde em público no pai | #1020 recebe a mensagem e continua resolvido; #1040 não recebe nada (D46) |
| PE-130 | #1010 pai com #1030 (Financeiro, aberto, sem responsável), vinculado pelo admin; ag1 não vê #1030; responsável obrigatório para resolver ligado | ag1 resolve #1010 | #1030 não é resolvido: ag1 não tem escrita no Financeiro e não pode ser responsável dele; #1030 fica aberto e o pai mostra 1 filho pendente; ag1 continua recebendo 404 em #1030 (revisto: D55) |
| PE-131 | #1020 aberto; #1010 resolvido | apoio1 usa "Criar artigo" em #1020 pela API; ag3 (sem acesso ao N1) usa em #1010 | apoio1: 422 (erro de validação, D42); ag3: 404 |
| PE-132 | aplicação em modo de produção | ag1 procura qualquer entrada sem Google na área do agente (senha, link, login de desenvolvimento) | nenhuma existe; o login de desenvolvimento responde 404 (D53) |

---

## 13. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Agente fora do escopo: status, vazamento em busca, contagem, anexo, histórico | documentação parcial | cenário P-01 |
| Visibilidade por organização | divergente (ver e alterar / colaboração automática / padrão empresa / só gestor) | cenário P-02 |
| Nota interna em portal, API, e-mail, webhook | documentação sobre a existência; vazamento não documentado | cenário P-03 |
| Granularidade de papéis parciais | documentação | cenário P-04 |
| Escopos e validade de tokens | documentação parcial | cenário P-05 |
| Modelo de isolamento (contas, caixas, contatos compartilhados) | documentação parcial | cenário P-06 |
| Encaminhamento com retorno, conversa paralela, seguidores, filas salvas | requisito de cliente (spec 13), sem evidência de runtime dos projetos | — |

## 14. Questões abertas para o implementador

- O tempo de resposta de um 404 por falta de acesso deve ser comparável ao de
  um inexistente (spec 10 §6.2). Medir no teste de carga, sem impor um número
  agora.
- **Entrada de emergência do admin** (Δ31): sem senha local, uma falha do
  provedor Google ou um domínio configurado errado impede qualquer admin de
  entrar para corrigir. Decidir com o responsável pelo projeto se haverá um
  caminho de recuperação pela infraestrutura (fora do produto, como a criação
  de contas, §9) ou outro mecanismo.
