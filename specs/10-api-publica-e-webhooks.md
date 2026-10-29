# Spec 10 — API pública e webhooks

Status: **rascunho v0.3 (2026-10-29)**. Baseado na documentação pública dos 7
projetos analisados, nos requisitos da operação EARJ (spec 13) e, como
referência de mercado, na documentação pública de desenvolvedor do Zendesk. As
evidências de runtime ainda estão pendentes (o laboratório não subiu); cada
ponto que depende delas está marcado como **[evidência pendente: cenário]**.
Vocabulário: spec 01. Permissões: spec 06. Tempo real: spec 09. Decisões
transversais: D01..D53. Precedência: spec 13 > decisões transversais > esta
spec.

**Mudanças na v0.3**
- **Autenticação** (spec 13 Δ31): o login com Google é da interface (agentes,
  admins e solicitantes da escola); a API continua **só por token** pessoal ou
  de identidade de integração. Credencial do Google na API → 401 (§3.1;
  AP-103).
- **Locais** (Δ33): recurso novo com campus → prédio → andar → sala, código
  curto estável, desativação sem apagar, endereço do QR e "minhas salas" da
  pessoa; local do ticket com origem (QR, formulário, agente, API); filtros
  por local (§4, §5.2; AP-90..AP-94).
- **Eventos** (Δ34): bloco de evento no ticket (tipo, data, início, fim,
  início da montagem, local, público, equipamentos, observações), marca "fora
  do prazo", formulário de evento separado e **calendário de eventos** pela
  busca comum de tickets (D50) (§4, §5.2; AP-95..AP-97).
- **Incidente pai** (Δ35): marcar como pai, vincular e desvincular filhos com
  resultado por item, resposta pública replicada nos filhos, resolução em
  cascata sem pesquisa (§4; AP-98..AP-101).
- **Macros por intenção com variantes PT/EN** (Δ36): busca pelo nome em
  qualquer idioma (o filtro por idioma sai antes do lançamento da v1), prévia
  com a variante do idioma do solicitante e aviso `variante_ausente` (§4;
  AP-102).
- **Selo de prazo** na representação do ticket (Δ37) e ação **"criar
  artigo"** a partir de ticket resolvido (Δ38) (§4; AP-104).
- Webhooks: alterações de local, evento e vínculo de incidente em "ticket
  atualizado"; novos tipos "local criado / atualizado" e "evento: aviso de
  montagem"; resposta replicada num incidente gera um evento por ticket com o
  mesmo identificador de operação (§11.3; WH-44..WH-47).
- Novos códigos: `local_inativo`, `incidente_aninhado`,
  `filho_ja_vinculado`, `montagem_depois_do_inicio`, `variante_duplicada`,
  `sem_convite` (§6.1).
- **Ajustes D40–D53**: ticket de evento com 1ª resposta de SLA comum, sem
  resolução comum, e selo de evento (`faltam`, `pronto`,
  `montagem_sem_pronto`, `evento_encerrado`) (D40); marca **"pronto para o
  evento"** com quem e quando, desfazível até o início da montagem (D44);
  avisos de montagem que saem na hora dentro da janela (D41, spec 05 §7.14);
  "criar artigo" com **leitura** no ticket, erro de validação fora de
  resolvido/fechado, título do assunto e outra língua como **tradução do
  mesmo artigo** (D42); filho invisível → 404 (D43); desvincular com escrita
  no pai **ou** no filho (D45); resposta do pai também em filho resolvido,
  sem mudar o estado (D46); filho sem responsável recebe quem resolveu o pai
  (D47); variante no idioma padrão da conta obrigatória na macro (D49); o
  calendário de eventos deixa de ser recurso próprio e vira a busca comum
  (D50); exemplos de campo condicional com motivo → equipamento (D51); feed de
  eventos confirmado no MVP (D52). AP-67, AP-75, AP-97, AP-102 e AP-104 revistos;
  casos novos AP-106..AP-112 e WH-48; questões 5 e 6 removidas.

**Mudanças na v0.2**
- Versão conforme D01: só mudança de campo ou estado; mensagem pura não é
  verificada; pré-condição opcional na API, e o uso sem versão é registrado
  (§8; AP-51..AP-55).
- **Identidade de integração** conforme D04 substitui a "conta de serviço";
  tokens pessoais só para si mesmo; token com escopo maior que o papel é
  **recusado** na criação (D14) (§3; AP-08 refeito, AP-14..AP-19).
- Ordem 404 × 403 × 422 × 409 conforme D05; página acima de 100 → 400 (D15).
- Recursos novos para paridade com a interface e com a spec 13: mescla,
  encaminhamento com retorno e devolução, continuação, "meu problema foi
  resolvido" (D08), seguidores, conversas paralelas, avaliações, macros com
  prévia, filas salvas, formulários, notificações, quarentena, feed de eventos
  (§4; AP-60..AP-79).
- Estado `em_espera`, tipo do ticket, campos condicionais e responsável
  obrigatório para resolver na API (G5, G8, §4).
- Ordenações alinhadas à spec 08 §7, com desempate pelo número do ticket
  (§5.2; AP-38, AP-39).
- Catálogo de webhooks: mensagens de sistema internas só no tipo de nota
  interna (D03); conversa paralela no mesmo tipo (D37); novos tipos de
  avaliação, SLA, pessoa mesclada e definição de campo (§11.3; WH-15..WH-19).
- **Webhook como ação de gatilho** no MVP, com o envelope padrão (D13; §11.4;
  WH-38..WH-40).
- Supressão de eco por identidade de integração dona da assinatura (alinhada à
  spec 12 §4.6).
- **Receptor de teste próprio** do PantherDesk substitui o receptor do
  laboratório (D22; §13.7; WH-22, WH-23 refeitos, WH-41).
- WH-25 refeito com tempos absolutos; regra de 429/503 que absorve momentos do
  calendário (WH-43).
- Questões abertas respondidas foram removidas.
- Ajustes D23–D37: ticket encaminhado fica **aberto** no grupo de destino, com
  a marca derivada "encaminhado" na representação e nos filtros (D23), e a
  origem mantém leitura e nota interna (D24); tokens de pessoa desativada ficam
  **suspensos** e voltam na reativação, e o admin pode revogá-los (D26); cursor
  inválido → 400 (D28); aplicar macro pela API (D29); publicar, despublicar e
  arquivar artigo só com administração, sem a marca "pode publicar" (D30);
  nenhuma "audiência" de webhook (D31); ordenações iguais às das filas, com
  desempate pelo número, e operação de **edição em massa** (D32); identidade
  de integração **administrativa** só se criada assim (D36); mensagens de
  conversa paralela no tipo "nota interna criada", com a indicação "conversa
  paralela" (D37) (§3, §4, §5.2, §11.3, §12.3; AP-64 e WH-18 refeitos,
  AP-80..AP-89).

Esta spec descreve **comportamento e decisões**. Os nomes concretos de caminhos,
parâmetros, campos e cabeçalhos próprios do PantherDesk serão definidos na
referência da API pelo implementador, seguindo as regras daqui.

---

## 1. Problema

Integradores (CRM, ERP, BI, bots, plataformas de automação) precisam ler e
alterar o helpdesk e ser avisados quando algo acontece. Para isso esperam:

1. uma **API REST previsível**: recursos claros, autenticação por token ligada a
   um ator, paginação estável em listas grandes, filtros explícitos, um único
   formato de erro, códigos HTTP corretos, limites de taxa comunicados,
   criação idempotente, controle de concorrência e versionamento sem surpresas;
2. **webhooks confiáveis**: catálogo de eventos, envelope estável, assinatura
   verificável com proteção contra replay, entrega que não se perde nem trava o
   ticket, novas tentativas com prazos conhecidos, desativação de destinos
   quebrados e log de entregas;
3. **honestidade sobre garantias**: entrega "pelo menos uma vez", sem ordem
   garantida, com o que o receptor precisa para lidar com isso;
4. **segurança**: um token nunca pode mais do que o seu dono; notas internas
   nunca chegam a quem não é agente; o servidor não pode ser usado para atacar a
   rede interna (SSRF).

---

## 2. Princípios gerais da API

| # | Regra |
|---|---|
| G1 | **Caminho versionado**: toda rota pública começa por um prefixo de versão maior (v1). |
| G2 | **JSON** em UTF-8 no corpo de pedidos e respostas. Pedido com outro tipo de conteúdo → 415. |
| G3 | **Identificadores opacos** (texto) para todos os recursos. O número legível do ticket (spec 01 §3) é um **campo** e um **filtro**, não o identificador. |
| G4 | **Datas em UTC**, ISO-8601, com sufixo de UTC e precisão de milissegundos. Na entrada, aceitar qualquer deslocamento explícito e normalizar para UTC; data **sem** deslocamento → 422. |
| G5 | **Valores enumerados** usam as chaves estáveis das specs: estados `aberto`, `pendente`, `em_espera`, `resolvido`, `fechado`, `mesclado`; prioridades `baixa`, `normal`, `alta`, `urgente`; tipos do ticket `pergunta`, `incidente`, `problema`, `tarefa`, `evento` (sem padrão; D56); políticas `reabrir`, `novo`, `janela`; tipos de canal da spec 03 §2.1 (`email`, `formulario`, `portal`, `chat`, `agente`, `api`, `sistema`); tipos de evento de AV `assembly`, `homecoming`, `traducao_simultanea`, `entre_campi`, `pequeno_evento`, `outro` (Δ34); níveis de local `campus`, `predio`, `andar`, `sala` (Δ33); origem do local `qr`, `formulario`, `agente`, `api`; idiomas de variante `pt`, `en` (Δ36). |
| G6 | **Atualização parcial**: uma alteração muda só os campos enviados. Campo enviado como nulo limpa o valor, quando o campo admite vazio. |
| G7 | **Campos desconhecidos no pedido → 400**, com o nome do campo nos detalhes. Parâmetros de consulta desconhecidos → 400. Nada é ignorado em silêncio. |
| G8 | **Mesmas regras de negócio da interface**: toda validação da spec 01 (matriz de transições com em espera, validações para resolver, inclusive **responsável obrigatório** quando a conta exige, responsável com escrita no grupo, campos condicionais, mescla) vale igual na API. A interface do agente e o portal usam esta mesma API. |
| G9 | **Toda mudança feita pela API gera evento de auditoria** com origem API e a identificação do token (spec 01 §7). Mudanças feitas pela interface com sessão têm origem agente ou solicitante. |
| G10 | **Identificador de requisição**: toda resposta, de sucesso ou erro, traz um identificador único da requisição num cabeçalho, repetido no corpo de erro, para suporte. |
| G11 | **Somente HTTPS** fora do ambiente local de desenvolvimento. Pedido HTTP em produção é recusado, não redirecionado. |
| G12 | **Avisos não bloqueantes**: uma resposta de sucesso pode trazer uma lista de **avisos** com código de máquina (ex.: `mencao_sem_acesso`, `mencao_em_publica`, `mensagens_novas`). Avisos nunca substituem erros. |

---

## 3. Autenticação e autorização

### 3.1 Formas de autenticação

| Forma | Quem usa | Observação |
|---|---|---|
| **Sessão** (cookie, mesma origem, com proteção contra CSRF) | interface do agente, portal do cliente | emitida pelo PantherDesk depois do login com Google (agentes, admins e solicitantes do domínio da conta) ou do link de acesso por e-mail (solicitantes sem conta da escola), conforme spec 13 Δ31 e spec 12 §6.5; também é a única forma aceita pelo canal de eventos e pela presença (spec 09) |
| **Token pessoal** | um agente ou admin, para uso próprio (scripts) | enviado **somente** no cabeçalho padrão de autorização do HTTP, esquema "bearer" (RFC 6750) |
| **Token de identidade de integração** | sistemas externos (D04, §3.5) | mesmo envio do token pessoal |

- OAuth2 para aplicativos de terceiros fica para o roadmap. O modelo interno já
  é "credencial → ator + escopos", para que OAuth2 entre sem mudar a
  autorização.
- Basic com usuário e senha **não** é aceito pela API.
- **Login com Google é para a interface** (spec 13 Δ31). Quem usa a API se
  autentica **por token** do PantherDesk (pessoal ou de identidade de
  integração), como antes. Um token, asserção ou credencial emitida pelo
  Google (ou por qualquer provedor externo) enviada à API → **401**, sem
  aviso de vazamento (não é token do PantherDesk). O agente que entra só com
  Google cria os seus tokens pessoais numa sessão interativa obtida pelo
  Google, como em §3.2; não existe senha local de agente.
- Token na URL (parâmetro de consulta) é **recusado** com 400 e o dono do token
  recebe aviso de que ele vazou. O token não é usado nessa requisição.
- O widget de chat e a entrega direta de e-mail **não** usam esta API pública:
  são pontos de entrada de canal (spec 03 §6, spec 02 §2.1), com credenciais
  próprias, e não aceitam tokens.

### 3.2 Token pessoal

- Pertence a **uma pessoa** com papel **admin** ou **agente**. Solicitantes não
  criam tokens no MVP: o portal usa sessão.
- É criado **só pelo próprio dono**, numa **sessão interativa** (spec 06 §7).
  Um token não cria, lista nem revoga tokens. O admin vê e revoga tokens de
  qualquer pessoa da conta, mas **não** cria tokens para outras pessoas; para
  integrações, cria uma identidade de integração (§3.5).
- Tem nome, escopos, data de criação, expiração opcional (máximo 2 anos), data
  do último uso e IP do último uso.
- O segredo é exibido **uma única vez**, na criação. É guardado apenas como hash.
  Um prefixo curto e não secreto identifica o token na listagem e nos logs.
- **Revogação** imediata: o próximo pedido com o token recebe 401.
- Pessoa desativada → todos os tokens dela ficam **suspensos** (401), sem
  precisar revogar um por um (D26, spec 06 §2). Reativar a pessoa faz voltar a
  funcionar os tokens que não expiraram nem foram revogados. Enquanto estão
  suspensos, o admin vê e pode revogar esses tokens; um token revogado não
  volta na reativação.
- **Permissão efetiva = permissões atuais do dono ∩ escopos do token**. Calculada
  a cada pedido: se ag1 sai do grupo N1, o token dele deixa de ver o N1 no pedido
  seguinte. Um token **nunca** pode mais do que o seu dono.
- **Escopo maior que o papel** (D14): é **recusado na criação** (403
  `papel_insuficiente`); um agente não cria token com escopo administração. Um
  dono **rebaixado** depois da criação não perde o token, mas perde o poder: o
  escopo administração deixa de ter efeito enquanto ele não for admin.
- "Agir em nome de outro usuário" (impersonação) fica **fora** do MVP.

### 3.3 Escopos

Os mesmos três escopos para tokens pessoais e de identidade de integração (D04):

| Escopo | Permite |
|---|---|
| **leitura** | ler qualquer recurso a que o dono tem acesso |
| **escrita** | leitura + criar e alterar tickets, mensagens, notas internas, seguidores, conversas paralelas, pessoas (inclusive mescla), etiquetas, macros e filas pessoais, rascunhos de artigo (inclusive a partir de ticket), vínculos de incidente, "minhas salas" de pessoas, conforme o acesso do dono |
| **administração** | escrita + configurações exclusivas de admin (spec 06 §10): grupos, agentes, identidades de integração, organizações, campos personalizados, formulários, cadastro de locais, macros e filas compartilhadas, publicação da base de conhecimento, quarentena, webhooks e eventos de auditoria da conta inteira; só tem efeito se o dono for admin (ou identidade de integração administrativa, §3.5) |

- Token sem escopo explícito recebe **leitura**.
- O escopo não amplia o acesso do dono por grupo: um agente de apoio (só
  leitura nos grupos, spec 06 §3) com token de escrita cria nota interna, mas
  não responde em público nem muda campos (403).
- Artigos da base (D30): criar e alterar **rascunho** exige escrita; publicar,
  despublicar, republicar, arquivar, excluir artigo nunca publicado e
  gerenciar categorias exigem **administração** (dono admin). Não existe
  permissão de publicar para agentes.

### 3.4 Visibilidade de notas internas

- Notas internas, mensagens de sistema internas (spec 01 §2) e mensagens de
  conversa paralela aparecem só para agentes, admins e identidades de
  integração com acesso ao grupo, sempre com a visibilidade explícita na
  representação da mensagem.
- Uma sessão de solicitante **nunca** recebe nada disso: listagens as omitem
  (inclusive na contagem), e leitura direta pelo id → 404.
- Nenhuma representação que um solicitante possa ler (ticket, mensagem,
  histórico) contém trecho de nota interna, nem como "última mensagem".
- Para a sessão de solicitante, o estado `em_espera` é apresentado como
  `aberto` (o portal mostra "em andamento"; spec 13 Δ3). O solicitante nunca vê
  o termo "em espera".
- Tickets da organização no portal (D07): conforme a configuração da
  organização (desligado, só gestores, todos os membros), a sessão do
  solicitante lista e lê esses tickets **só para leitura**; responder a um
  ticket de outro membro → 403.

### 3.5 Identidade de integração

Conforme D04 e spec 01 §2:

- Ator **não humano**, criado e alterado só pelo **admin** (escopo
  administração). Tem nome, descrição, admin responsável e estado (ativa ou
  desativada).
- Tem o **mesmo modelo de acesso por grupo** dos agentes: nenhum, leitura ou
  escrita, configurado pelo admin. Só uma identidade que o admin **cria**
  marcada como **administrativa** (D36) recebe o escopo administração: ela tem
  escrita em todos os grupos e o escopo administração tem efeito, como para um
  admin. A marca é escolhida na criação e não é acrescentada depois.
- Seus tokens têm os **mesmos três escopos** (§3.3) e as mesmas regras de
  segredo, prefixo, revogação imediata e último uso do token pessoal. São
  criados pelo admin numa sessão interativa. Validade obrigatória (padrão 365
  dias, máximo 2 anos), até 2 tokens ativos por identidade, para troca sem
  interrupção (spec 12 §5). Escopo administração para identidade não
  administrativa é recusado na criação (403 `papel_insuficiente`; D14, D36).
- Desativar a identidade deixa todos os tokens dela **suspensos** (401);
  reativá-la faz voltar os que não expiraram nem foram revogados (como D26).
- Não entra na interface, não é responsável nem seguidor de ticket, não mescla
  tickets (como as automações, spec 01 §4.2) e não reabre ticket fechado.
- Toda ação gera auditoria com ator = a identidade e origem API, com o prefixo
  do token. Mensagens dela têm tipo de autor integração; na tela aparecem com o
  nome da integração (D04); para o solicitante, conforme a spec 02 §9. Nunca
  conta como humano nas métricas (spec 11): não é primeira resposta.
- Ticket fora dos grupos a que ela tem acesso se comporta como inexistente
  (404).

---

## 4. Recursos (MVP)

| Recurso | Operações | Regras específicas |
|---|---|---|
| **Tickets** | listar, ler, criar, alterar | estado só muda conforme a matriz da spec 01 §4.2 (inclui `em_espera`); resolver exige as validações da spec 01 (campos obrigatórios para resolver, **responsável obrigatório** quando a conta exige, Δ4) → 422 com o campo; campos condicionais (Δ2): valor para campo que deveria estar oculto → 422 `campo_oculto`; campo que fica oculto é limpo e a limpeza aparece nas alterações; criação por agente informa o modo (registrar pedido ou contato proativo, spec 01 §4.6); a representação para agentes inclui tipo, seguidores, origem do encaminhamento, a marca derivada "encaminhado" (D23; não é um estado), avaliação atual, o meio declarado de ticket de canal `agente` (D34) e o vínculo "continuação de #N"; leitura de ticket **mesclado** devolve o ticket com o ponteiro para o destino; não há operação de exclusão de ticket (D17); **local** (Δ33): a sala do cadastro, com campus, prédio e andar derivados dela e a **origem do local** (`qr`, `formulario`, `agente`, `api`); sala desativada ou que não é do nível sala → 422 `local_inativo` / `validacao`; nunca derivado de etiquetas; **evento** (Δ34): bloco presente sempre que o tipo do ticket é `evento`, seja pelo formulário de evento ou por mudança de tipo feita por agente (D56), com nome, tipo, data, início, fim, início da montagem, público estimado, equipamentos pedidos e observações, e a marca **"fora do prazo"** (só leitura, calculada pela antecedência mínima da conta, Δ34), além da marca **"pronto para o evento"** (D44): posta e retirada por agente com escrita no grupo, com quem e quando, gera evento de auditoria e mudança de campo (versão, D01); retirar depois do início da montagem → 422 `validacao`; o ticket de evento tem a métrica de **1ª resposta** da política comum e não tem a de resolução (D40, spec 05 §7.14); início da montagem depois do início do evento ou fim antes do início → 422 `montagem_depois_do_inicio` / `validacao`; mudar data ou horários é mudança de campo (versão, D01); **incidente** (Δ35): marca de pai, ou o id do pai quando é filho; no pai, a contagem de filhos (total e ainda não resolvidos) e os **locais afetados** (salas distintas do pai e dos filhos); **selo de prazo** (Δ37, D40): métrica, instante e situação do próximo prazo ativo (`vence_em`, `vencido`, `pausado`; para eventos, `faltam` antes da montagem, `pronto` com a marca, `montagem_sem_pronto` se a montagem começou sem ela e `evento_encerrado` depois do fim do evento; valores na spec 05 §7.15), calculado no momento da leitura, só para agentes |
| Tickets — ações | mesclar; encaminhar com retorno; devolver; criar continuação; marcar e desmarcar spam; confirmar ou recusar participante não confirmado | mesclar exige escrita nos dois e versão (spec 01 §6); encaminhar com retorno exige nota interna e destino (Δ5) e deixa o ticket no estado **aberto** no grupo de destino, sem responsável, com a marca "encaminhado" para a origem (D23); enquanto isso, o agente e o grupo de origem leem o ticket e escrevem nota interna, mas qualquer outra alteração deles → 403 (D24); um ticket já encaminhado não pode ser encaminhado de novo → 422 `encaminhamento_aninhado`; devolver sem origem registrada → 422; criar continuação só em ticket fechado (Δ13); desmarcar spam não reabre (D16) |
| Tickets — incidente (Δ35) | marcar e desmarcar como pai; vincular filhos; desvincular filho; listar filhos | marcar, desmarcar e vincular exigem escrita no pai e, para vincular, escrita em cada filho; **desvincular** exige escrita no pai **ou** no filho (D45); **vincular** recebe até 100 ids e devolve o **resultado por item** (vinculado, ou falha com o código), como a edição em massa; um ticket tem no máximo um pai; pai não pode ser filho e filho não pode ser pai (1 nível) → 422 `incidente_aninhado`; filho de outro pai → 422 `filho_ja_vinculado`; ticket fechado ou mesclado → 422 `transicao_invalida`; ticket que o ator não vê → 404 no item (D43, D05); vincular e desvincular mudam um campo do **filho** (versão nova dele) e **não** a versão do pai; desmarcar um pai com filhos → 422 (desvincular antes); **mensagem pública no pai** é registrada também em cada filho em **qualquer estado, exceto fechado e mesclado**; num filho resolvido, entra sem mudar o estado (D46); cada uma na variante do idioma do solicitante do filho quando vem de macro com variantes (Δ36); a resposta traz a quantidade de filhos atingidos; **resolver o pai** resolve os filhos ainda não resolvidos com a mesma resposta; filho sem responsável recebe como responsável **quem resolveu o pai** e então é resolvido (D47), e um filho que falhe em outra validação fica como estava; a resposta traz o resultado por filho; nem o pai nem os filhos resolvidos por ele recebem convite de pesquisa |
| Tickets — criar artigo (Δ38) | criar rascunho de artigo a partir do ticket | basta **leitura** no ticket, inclusive para o agente de apoio (D42; spec 06 §4); ticket **resolvido** ou fechado com pelo menos uma mensagem pública de agente, senão 422 `validacao` (D42; spec 07 §3.5); cria um **artigo novo em rascunho** com **título = assunto** do ticket (editável) e **texto = última resposta pública de agente**, **sem** nome, endereço ou outro dado do solicitante, com categoria e idioma escolhidos e o vínculo "criado a partir de #N"; pode pedir também a outra língua (PT/EN), criada como **rascunho de tradução do mesmo artigo**, não como artigo separado (D42); publicar continua só com administração (D30) |
| Tickets — ação do solicitante | "meu problema foi resolvido" | só com a sessão do **solicitante** do ticket, de aberto, pendente ou em espera para resolvido, nunca para fechado (D08); participante → 403; de outro estado → 422; **não** exige responsável nem os campos obrigatórios para resolver, e o ticket recebe a marca "resolvido pelo solicitante" (D33); registra mensagem de sistema pública e evento de origem solicitante. Fora isso, o solicitante não muda estado diretamente (403) |
| **Mensagens** (do ticket) | listar, ler, criar | criar pública ou nota interna, opcionalmente com mudança de campo ou estado no mesmo pedido ("enviar com estado", §8); mensagens são **imutáveis** (spec 01): não há alteração nem exclusão; criar mensagem em ticket mesclado → 422 com o id do destino nos detalhes (sem redirecionar em silêncio); menções só em nota interna (Δ7): menção a agente sem acesso → aviso `mencao_sem_acesso`, menção em pública → não convertida, aviso `mencao_em_publica` |
| **Seguidores** (do ticket) | listar; seguir e deixar de seguir; adicionar e remover outro agente | o próprio agente segue qualquer ticket que vê; adicionar outro agente exige escrita e que ele tenha acesso ao ticket; não muda a versão (spec 01 §3) |
| **Conversas paralelas** (do ticket) | listar, ler, abrir, enviar mensagem, encerrar | só agentes com escrita no ticket; nunca visíveis ao solicitante; e-mail conforme spec 02 (Δ17) |
| **Avaliações** | listar, ler | agentes leem as avaliações dos tickets que veem, com filtro por período; o solicitante registra e altera a própria avaliação pela sessão do portal ou pelo chat até o ticket fechar (Δ15); avaliar uma resolução sem convite (ex.: filho resolvido pelo pai, Δ35) → 422 `sem_convite`; nunca muda a versão |
| **Anexos** | enviar arquivo, ler metadados, baixar | o arquivo é enviado antes e referenciado na criação da mensagem; download exige autenticação e a mesma permissão da mensagem; limite de tamanho da conta (spec 02 §2.4; 50 MB na EARJ, Δ19) → 413 |
| **Pessoas** | listar, ler, criar, alterar; adicionar e remover endereços; mesclar | um endereço pertence a no máximo uma pessoa por conta: duplicado → 422; campos personalizados de pessoa (Δ22); mesclar pessoas exige escrita e não está disponível ao agente de apoio (Δ22, spec 01 §6.2); **minhas salas** (Δ33): lista ordenada de salas ativas da pessoa, alterável pela própria pessoa na sessão do portal e por agentes com escrita; o **idioma** da pessoa escolhe a variante das macros (Δ36); a forma de entrada (Google ou link) não aparece na API |
| **Organizações** | listar, ler; criar e alterar com administração | configuração exclusiva de admin (spec 06 §10); campos personalizados de organização (Δ22); configuração de visibilidade no portal (D07) |
| **Locais** (Δ33) | listar (filtros: nível, campus, prédio, andar, ativo; busca por nome ou código), ler; criar, alterar, desativar e reativar com administração; ler o **endereço do QR** de uma sala | hierarquia campus → prédio → andar → sala; a sala tem nome, **código curto** único na conta e **imutável**, campus, prédio e andar; renomear não muda código nem QR; **não há exclusão**: desativar esconde a sala dos formulários e de tickets novos (→ 422 `local_inativo`), e os tickets antigos continuam mostrando a sala, marcada como inativa; desativar um nível acima desativa a escolha das salas dele; o endereço do QR é curto, estável, no domínio da conta (Δ32), e leva só o código da sala; a folha de impressão por prédio ou andar é só da interface; a sessão do solicitante lista só as salas ativas, sem dados internos |
| **Grupos** | listar, ler; criar e alterar com administração | inclui a política de resposta em fechado (spec 01 §4.4) |
| **Agentes** | listar, ler; alterar papel, grupos e ativação com administração | um agente é uma pessoa com acesso à área de atendimento; os dados pessoais seguem o recurso Pessoas; a disponibilidade (spec 04 §8) é legível |
| **Identidades de integração** | listar, ler, criar, alterar, desativar com administração | tokens delas só são criados em sessão interativa (§3.5) |
| **Etiquetas** | listar (com contagem de uso); adicionar e remover no ticket | normalizadas em minúsculas, sem duplicata (spec 01) |
| **Campos personalizados** | listar, ler; criar, alterar e desativar com administração | de ticket, pessoa ou organização; o tipo não muda depois de criado (spec 01 §5) → 422; condição que formaria ciclo → 422 `ciclo_de_condicao` |
| **Formulários do portal** | listar, ler; criar, alterar e ativar com administração | um formulário tem um tipo, **suporte** ou **evento** (Δ34); no MVP, um ativo por tipo (Δ1 ajustado pelo Δ34) |
| **Macros** | listar (busca pelo **nome da intenção em qualquer idioma**, Δ36), ler, **prévia** para um ticket; criar e alterar pessoais com escrita, compartilhadas com administração | cada macro é **uma intenção** com **variantes por idioma** (PT, EN): texto e assunto por variante, ações comuns à intenção; a variante no **idioma padrão da conta** (PT na EARJ) é **obrigatória** e a outra é opcional: macro sem ela → 422 `validacao` com detalhe `obrigatorio` na variante do idioma padrão, ao criar ou ao remover essa variante (D49); duas variantes do mesmo idioma → 422 `variante_duplicada`; o filtro por idioma do Δ10 não existe (sai antes do lançamento da v1); a prévia usa a variante do **idioma do solicitante**, ou a variante pedida no parâmetro opcional de idioma; sem variante no idioma do solicitante, usa a do idioma da conta e traz o aviso `variante_ausente`; a estatística de uso é por intenção, com a quebra por variante; a prévia devolve o texto com as variáveis substituídas e as mudanças, sem gravar nada (Δ10); **aplicar** (D29) é um envio de mensagem comum que informa a macro usada: o servidor aplica as ações da macro com as mesmas regras da interface (escrita, versão quando há mudança de campo ou estado, D01; validações para resolver), o evento de auditoria registra a macro **e a variante** usada e o uso conta na estatística; macro que o dono do token não vê → 404; variável desconhecida ou marcador sem variável, em qualquer variante → 422 `variavel_desconhecida` ao salvar |
| **Filas salvas** | listar (as que o dono vê), ler, executar, contar; criar e alterar pessoais com escrita, compartilhadas com administração | executar usa o contrato de listagem (§5); compartilhada restrita a grupos não aparece para quem não é membro; 11ª fila pessoal → 422 `limite_de_filas` (Δ9) |
| **Artigos e categorias da base de conhecimento** | listar, ler; criar, listar e alterar **rascunhos** com escrita; publicar, despublicar, republicar, arquivar, excluir nunca publicado e gerenciar categorias com administração | só o admin publica (D30); agente publicando → 403; permissões no §3.3 e na spec 07 |
| **Edição em massa** (D32) | executar sobre uma lista de tickets | até 100 tickets por pedido (acima → 400, nada executado); as mesmas ações da interface (spec 08 §9.5): atribuir, mudar grupo, estado ou prioridade, etiquetas, aplicar macro; execução **ticket a ticket**, cada um atômico e com as validações de uma alteração individual; cada item pode trazer a versão esperada (D01); a resposta traz o resultado por ticket (alterado ou falha com o código do erro); auditoria marcada "via edição em massa" |
| **Notificações** | listar, marcar como lida ou não lida, marcar todas | só as do dono da sessão ou do token pessoal (spec 09 §7); não existem para identidade de integração |
| **Quarentena** | listar, ler, liberar, descartar com administração | regras na spec 02 |
| **Webhooks** | listar, ler, criar, alterar, desativar, reativar, excluir, girar segredo, testar, listar entregas, reenviar entrega | só com administração (§11) |
| **Eventos de auditoria** | listar e ler, **somente leitura** | por ticket (agente com acesso ao ticket) ou da conta inteira (administração); nunca para solicitante (spec 01 TL-54 → 403) |
| **Feed de eventos** | listar com cursor | eventos de domínio dos últimos **30 dias** (spec 12 §4.7), no mesmo envelope dos webhooks (§12.1), filtrados pelas permissões de quem lê |
| **Eu** | ler | pessoa ou identidade de integração, papel, acesso por grupo, escopos e expiração do token em uso |
| **Mudanças desde** | listar | ver §5.3 |

- A **edição em massa** (Δ9, D32) é a operação de lote geral da v1; ela
  executa ticket a ticket, como na interface. As operações de incidente
  (vincular filhos, resposta e resolução no pai, Δ35) também atuam em vários
  tickets e seguem o mesmo modelo: cada ticket é atômico, com as suas
  validações, e a resposta traz o resultado por ticket. Filas salvas, rascunhos de
  artigo e a ação do solicitante "meu problema foi resolvido" também estão
  na API (D32).
- **Imprimir** (Δ20) é só da interface.
- **Calendário de eventos** (Δ34, D50): **não** há recurso próprio. É a
  listagem comum de tickets com o filtro "é ticket de evento" e o intervalo
  da data do evento, ordenada pela **data do evento** (spec 08 §9.7, §7),
  com o mesmo contrato (§5), os mesmos filtros (campus, tipo de evento etc.) e
  as mesmas permissões. As visões de mês e de semana são só da interface.

### 4.1 Inclusão de relacionados

- Leitura e listagem aceitam um pedido de **inclusão** de relacionados, de uma
  **lista fechada** por recurso (ex.: ticket → solicitante, responsável, grupo,
  organização). Pedido de inclusão fora da lista → 400.
- Relacionados vêm numa seção separada da resposta, uma vez cada, mesmo que
  vários itens apontem para o mesmo (sem duplicação).
- Relacionados a que o usuário não tem acesso simplesmente não são incluídos; a
  referência por id continua no item principal.

---

## 5. Listagens

### 5.1 Paginação por cursor

- Todas as listagens usam **cursor opaco**. Não existe paginação por número de
  página nem por deslocamento.
- Tamanho padrão 25, máximo 100. Pedido acima de 100 → **400** (não é reduzido
  em silêncio; D15).
- A resposta traz os itens, o cursor da próxima página e um indicador "há mais".
  Na última página, não há cursor.
- A **ordem é estável**: o critério pedido mais um desempate (§5.2).
- O cursor é ligado aos filtros e à ordenação que o geraram. Usar um cursor com
  filtros diferentes → 400. Cursor adulterado ou de outra conta → 400. Todo
  cursor inválido é **400**, na API e na busca (D28).
- Cursor vale por 24 h; depois disso → 400 com código próprio, e o cliente
  recomeça.
- **Total** não vem por padrão. Pode ser pedido explicitamente; é exato até
  10.000 e, acima disso, informado como "mais de 10.000".
- Itens alterados durante a paginação podem **mudar de página**. Na ordenação
  por "atualizado em", um item alterado reaparece mais adiante (duplicata
  possível, perda nunca). Isso é documentado para o integrador.

### 5.2 Filtros e ordenação

- Cada recurso publica sua lista de filtros. Para tickets, no MVP: estado (um ou
  vários), grupo, responsável (inclusive "sem responsável"), solicitante,
  organização, etiqueta, prioridade, tipo, canal de origem, número legível,
  seguidor, marca "encaminhado" (D23), campos personalizados de lista, criado
  entre, atualizado entre, avaliado entre; **local** (sala, andar, prédio ou
  campus, Δ33; um nível acima inclui todas as salas dele; "sem local");
  **incidente** (é pai; filho de um pai dado; tem pai), Δ35; **evento** (é
  ticket de evento, tipo de evento, data do evento entre, montagem entre, fora
  do prazo), Δ34. Etiquetas nunca substituem o filtro por local.
- Filtros diferentes se combinam com E; vários valores num mesmo filtro, com OU.
- Ordenações de tickets (D32): as mesmas das filas — **criado**,
  **atualizado**, **vencimento do SLA**, **prioridade**, **número** e **na fila
  há mais tempo** e **data do evento** (definições na spec 08 §7) —, crescente
  ou decrescente; com
  texto livre, também relevância (spec 08). Padrão: atualizado, decrescente.
  Outras → 400.
- **Desempate**: para tickets, pelo **número do ticket, decrescente** (spec 08
  §7); para os demais recursos, pelo identificador.
- Filtro desconhecido ou valor inválido (ex.: estado inexistente) → 400 com o
  filtro nos detalhes.
- Busca textual livre segue a spec 08; a API a expõe pelo mesmo contrato de
  listagem.
- Toda listagem já vem **filtrada por permissão**: ag3 listando tickets nunca vê
  os do N1, e nada indica que eles existem (nem no total).

### 5.3 Mudanças desde (sincronização)

- Listagem especial que devolve os tickets (e, separadamente, pessoas e
  organizações) **alterados a partir de um instante**, em ordem de "atualizado
  em" + id, com cursor.
- Serve para integrações que querem espelhar dados e para recuperar o que se
  perdeu além da janela do feed de eventos (§4) e do log de webhooks (§13).
- Mesmas regras de permissão. Retorna o estado **atual** do recurso, não o
  histórico de cada mudança (para isso, feed de eventos ou eventos de
  auditoria).

---

## 6. Erros

### 6.1 Envelope único

Todo erro, de qualquer recurso e status, usa o mesmo envelope, com:
- um **código de máquina** estável, em minúsculas com sublinhado, que nunca muda
  de significado dentro da versão (ex.: `validacao`, `transicao_invalida`,
  `conflito_de_versao`, `escopo_insuficiente`, `papel_insuficiente`,
  `limite_de_taxa`, `encaminhamento_aninhado`, `limite_de_filas`,
  `incidente_aninhado`, `filho_ja_vinculado`, `sem_convite`);
- uma **mensagem** para humanos, no idioma do usuário quando conhecido (não é
  contrato: o integrador decide pelo código);
- uma lista de **detalhes por campo**, cada um com o caminho do campo, um código
  de máquina do problema (ex.: `obrigatorio`, `tipo_invalido`, `opcao_inexistente`,
  `sem_acesso_ao_grupo`, `campo_oculto`, `ciclo_de_condicao`,
  `variavel_desconhecida`, `local_inativo`, `montagem_depois_do_inicio`,
  `variante_duplicada`) e uma mensagem;
- o **identificador da requisição** (G10).

Regras:
- **Nunca** stack trace, nome de classe, SQL ou caminho de arquivo no erro.
- **Nunca** erro com status 200.
- Erros de validação listam **todos** os campos inválidos de uma vez, não só o
  primeiro.
- Erros gerados antes da aplicação (proxy, balanceador) podem não seguir o
  envelope; o integrador deve se guiar pelo status nesse caso.

### 6.2 Política de status HTTP

| Status | Quando |
|---|---|
| 200 | leitura ou alteração com sucesso |
| 201 | criação com sucesso; a resposta traz o recurso criado e a localização dele |
| 204 | sucesso sem corpo (ex.: remover etiqueta, excluir webhook) |
| 304 | leitura condicional sem mudança (§8) |
| 400 | pedido malformado: JSON inválido, campo ou parâmetro desconhecido, cursor inválido, tamanho de página acima do máximo, ordenação não permitida, token na URL |
| 401 | sem credencial, credencial inválida, expirada ou revogada, dono desativado, ou credencial de provedor externo (ex.: Google) no lugar de um token do PantherDesk |
| 403 | o recurso **é visível** ao ator, mas a ação não é permitida pelo papel, pelo acesso ao grupo ou pelo escopo: escopo insuficiente, agente comum reabrindo ticket fechado, agente de apoio respondendo em público, solicitante mudando estado direto, participante usando "meu problema foi resolvido", solicitante lendo histórico, agente criando token com escopo administração, agente publicando artigo (D30), origem de encaminhamento alterando campo (D24) |
| 404 | o recurso **não existe** ou **não é visível** ao ator (ex.: ag3 lendo ticket do N1; solicitante lendo nota interna). Os dois casos são **indistinguíveis**: mesmo código, mesma mensagem, mesmo tempo de resposta aproximado |
| 405 | método não suportado no recurso (ex.: alterar mensagem) |
| 409 | conflito de versão (§8); outra requisição com a mesma chave de idempotência ainda em andamento (§7) |
| 413 | corpo ou anexo acima do limite |
| 415 | tipo de conteúdo não suportado |
| 422 | pedido bem formado mas que viola regra de negócio: validação de campo, transição de estado que não existe, validação para resolver (inclusive responsável obrigatório), campo oculto, responsável sem acesso ao grupo, mescla inválida, encaminhamento aninhado, incidente aninhado ou filho já vinculado, sala inativa, montagem depois do início do evento, variante de macro duplicada ou sem a variante do idioma padrão, marca "pronto" retirada depois do início da montagem, "criar artigo" em ticket não resolvido, avaliação sem convite, chave de idempotência reutilizada com outro corpo, data sem fuso |
| 429 | limite de taxa excedido (§9) |
| 500 | erro inesperado; nada foi gravado parcialmente |
| 503 | indisponibilidade temporária; vem com o cabeçalho padrão de "tentar depois" |

Ordem de decisão (D05): primeiro a autenticação (401); depois a
**visibilidade** do recurso: o que o ator não pode ver → **404**, seja qual for
o escopo do token. Só para recurso visível se avalia a ação: proibida pelo
papel, pelo acesso ao grupo ou pelo escopo → **403**; regra de negócio → **422**;
versão desatualizada → **409**. Ações sobre a classe inteira de recursos, que
não revelam nenhum recurso específico (ex.: agente criando webhook), dão 403.

---

## 7. Idempotência

- Todo **POST** de criação aceita uma **chave de idempotência** opcional, enviada
  num cabeçalho próprio do PantherDesk (texto de até 255 caracteres, escolhido
  pelo cliente; recomenda-se um UUID).
- A chave vale por **24 horas** e é única por (conta, token ou sessão, chave).
- Mesmo par chave + corpo idêntico dentro da janela → o servidor **não executa
  de novo**: devolve a mesma resposta (status e corpo) da primeira vez, com um
  indicador de que é uma repetição.
- Mesma chave + corpo diferente → 422 com código próprio; nada é gravado.
- Mesma chave enquanto a primeira requisição ainda está sendo processada → 409;
  o cliente tenta depois.
- Respostas de erro 4xx de validação **não** ficam guardadas (o cliente pode
  corrigir e reenviar com a mesma chave); respostas 2xx e 409 de versão ficam.
  Erro 5xx não fica guardado (a operação não foi gravada).
- A chave não aparece no recurso criado nem na auditoria.
- Por que 24 h, e não 2 h como na referência de mercado: integradores com fila
  própria costumam retentar ao longo de horas (ex.: depois de uma madrugada com o
  destino fora). Guardar chaves por um dia custa pouco.
- PUT/PATCH/DELETE já são idempotentes por natureza ou protegidos pela versão
  (§8); não usam chave.

---

## 8. Concorrência otimista

Conforme D01 e spec 01 §3:

- Todo recurso alterável tem uma **versão**. Para tickets, ela só aumenta com
  mudança de **campo** ou **estado** (inclui o efeito automático de uma
  mensagem, como pendente → aberto); mensagens, seguidores e avaliações não a
  mudam. A leitura devolve a versão no corpo e uma **ETag** (cabeçalho padrão
  do HTTP, RFC 9110).
- A ETag do ticket muda com **qualquer** mudança da representação (inclusive
  mensagem nova), para que a leitura condicional seja correta. Ela contém a
  versão; na pré-condição de escrita, o servidor compara **só a versão** contida
  nela.
- Uma alteração pode trazer a versão esperada como pré-condição (cabeçalho
  padrão **If-Match** com a ETag). Se a versão atual for outra → **409** com
  código `conflito_de_versao`, a versão atual e o resumo do que mudou (spec 09
  §6.1). Nada é gravado.
- Na API a pré-condição é **opcional** (D01). Sem ela não há verificação: vale a
  atualização parcial (G6), só os campos enviados mudam, e o evento de
  auditoria registra que a mudança foi feita **sem verificação de versão**. A
  interface do agente sempre envia a versão (spec 09 §6).
- **Criar mensagem**:
  - mensagem pura (pública ou nota, sem mudança de campo ou estado): a
    pré-condição, se enviada, **não** é avaliada; a resposta traz a versão
    atual. O cliente pode informar a última mensagem que conhecia; a resposta
    traz o aviso `mensagens_novas` com as mensagens públicas gravadas depois
    dela (spec 09 §6.2);
  - mensagem com mudança de campo ou estado no mesmo pedido: a pré-condição
    vale para o pedido **inteiro**; desatualizada → 409, e nem a mensagem nem a
    mudança são gravadas.
- Leitura condicional (cabeçalho padrão de "se não mudou") devolve 304 quando a
  ETag é a mesma; não conta para o limite de taxa.

---

## 9. Limite de taxa

- Limite **por ator** (pessoa ou identidade de integração; soma de todos os
  tokens e sessões dele) numa janela deslizante de 60 s. Padrão: **300 pedidos
  por minuto**. Pedidos não autenticados: 30 por minuto por IP.
- Escritas em um **mesmo ticket**: no máximo 30 por minuto (protege contra laços
  de integração que atualizam o mesmo ticket sem parar).
- Configurável pelo admin da instalação. Nenhum IP é isento por padrão
  (inclusive localhost), para que o comportamento medido em teste seja o de
  produção.
- Toda resposta traz três cabeçalhos próprios: limite da janela, pedidos
  restantes e segundos até a janela liberar. Unidade sempre **segundos**.
- Excedido → **429** com código `limite_de_taxa` e o cabeçalho padrão de "tentar
  depois" em segundos. O pedido recusado não é executado.
- Pedidos com 304 (§8) não contam.

---

## 10. Versionamento e compatibilidade

- Dentro de v1 **não há mudança incompatível**. São permitidos apenas:
  acrescentar recursos, campos de resposta, parâmetros **opcionais**, filtros,
  tipos de evento de webhook, avisos e códigos de erro novos.
- O integrador deve **tolerar** campos e valores enumerados desconhecidos nas
  respostas (isso é dito na documentação desde o primeiro dia). Um valor
  enumerado novo num campo **de entrada** é aceito apenas se o cliente o
  enviar; nunca muda o padrão.
- São mudanças incompatíveis (só numa versão nova): remover ou renomear campo,
  mudar tipo ou significado, tornar obrigatório algo opcional, mudar status ou
  código de erro de um caso existente, mudar o envelope de webhook.
- Uma versão antiga continua funcionando por pelo menos **12 meses** depois do
  lançamento da seguinte. Respostas da versão em descontinuação trazem os
  cabeçalhos padrão de depreciação e de data de desligamento (RFC 9745 e RFC
  8594), e os donos de tokens que a usam recebem aviso.

---

## 11. Webhooks — assinaturas

### 11.1 Quem e o quê

- Webhooks são **integrações de nível administrativo**: só admins (ou tokens com
  escopo administração de um admin ou de identidade de integração
  administrativa) criam, alteram ou veem assinaturas (D03).
- Uma **assinatura** tem: nome, URL de destino, lista de tipos de evento (ou
  "todos"), estado (ativa, desativada manualmente, desativada automaticamente),
  segredo de assinatura, **identidade de integração dona** (opcional), lista de
  atores ignorados (tokens ou identidades de integração) e datas de criação,
  última entrega bem sucedida e última falha.
- **Supressão de eco** (spec 12 §4.6): uma assinatura com identidade dona
  **não** recebe, por padrão, os eventos cujo ator é essa identidade; o admin
  pode ligar o recebimento. A lista de atores ignorados cobre os outros casos
  (ex.: um token pessoal usado por um script).
- Várias assinaturas por conta. Cada uma recebe os eventos de **toda a conta**
  que correspondem aos tipos escolhidos; não há filtro por grupo no MVP.
- O tipo de destino é sempre "POST JSON assinado". Payload por modelo
  personalizável e formatos para ferramentas de chat ficam no roadmap.
- Não há público, audiência ou escopo separado para notas internas (D03, D31):
  a assinatura não tem esse atributo, e quem não quer notas não assina o tipo
  de nota interna (§12.3).

### 11.2 URL de destino e segurança de saída

- Somente **HTTPS** com certificado válido. HTTP é aceito apenas para hosts na
  lista de permissões do admin da instalação (necessária para o receptor de
  teste, §13.7, e o desenvolvimento local).
- **Proteção contra SSRF**: por padrão, destinos que resolvem para loopback,
  redes privadas, link-local ou endereços de metadados de nuvem são recusados. A
  checagem é feita **na hora de cada envio**, depois da resolução de DNS, e não
  só no cadastro. A lista de permissões do admin da instalação é a única
  exceção.
- Redirecionamentos **não** são seguidos (contam como falha).
- Autenticação adicional no destino (cabeçalho com segredo fixo, Basic ou
  bearer) é opcional e configurada por assinatura; não substitui a assinatura
  HMAC.

### 11.3 Catálogo de eventos (MVP)

| Tipo | Quando | Recurso no envelope |
|---|---|---|
| ticket criado | ticket criado por qualquer canal | ticket |
| ticket atualizado | qualquer mudança de campo ou estado do ticket (estado, responsável, grupo, prioridade, tipo, etiquetas, campos, participantes, origem do encaminhamento, **local**, dados do **evento** (inclusive a marca "pronto para o evento", D44), **pai do incidente** no filho), inclusive por automação ou tarefa agendada | ticket + lista de alterações (o local aparece com código e nome antes e depois) |
| ticket mesclado | a origem foi mesclada no destino | ticket origem + id do destino |
| mensagem pública criada | mensagem pública de agente, solicitante, participante ou identidade de integração, por qualquer canal (inclusive chat), ou mensagem de sistema **pública** (ex.: confirmação automática enviada) | mensagem + id do ticket |
| nota interna criada | nota interna de agente ou de identidade de integração; mensagem de sistema **interna** (resposta automática recebida, bounce, aviso de tamanho; spec 01 §2); mensagem enviada ou recebida numa **conversa paralela** (Δ17, D37), e a abertura e o encerramento da conversa | mensagem (marcada interna, com o tipo de autor e os agentes mencionados; na conversa paralela, com a indicação "conversa paralela" e o id da conversa) + id do ticket |
| avaliação registrada / avaliação alterada | o solicitante avalia ou muda a avaliação de uma resolução (Δ15) | avaliação + id do ticket |
| SLA: aviso / SLA: violação | os eventos da spec 05 §7.10 e §7.11 (mesma origem da spec 12 §4.2) | ticket + métrica, prazo e instante |
| evento: aviso de montagem | um ticket de evento atinge o aviso "montagem em 2 dias úteis" ou "montagem hoje", inclusive o aviso que sai na hora quando o ticket nasce ou muda de data dentro da janela (Δ34, D41; instantes na spec 05 §7.14) | ticket + qual aviso, início da montagem e instante do aviso |
| local criado / local atualizado | o admin cria, renomeia, desativa ou reativa um campus, prédio, andar ou sala (Δ33) | local, com nível, código e caminho na hierarquia |
| pessoa criada / pessoa atualizada / pessoa mesclada | | pessoa (na mescla, origem + id do destino) |
| organização criada / organização atualizada | | organização |
| definição de campo alterada | criação, alteração ou desativação de um campo personalizado | definição do campo |
| artigo publicado / artigo atualizado / artigo despublicado | | artigo |
| teste | o admin pede um envio de teste | nenhum (só o envelope) |

Decisões:
- **Não** há eventos especializados para atribuição ou mudança de estado no MVP.
  Eles seriam redundantes com "ticket atualizado", e o integrador que assinasse
  os dois receberia o mesmo fato duas vezes. A lista de alterações diz
  exatamente o que mudou.
- Seguidores, marcas de leitura do chat e presença **não** geram eventos de
  webhook (não mudam a versão do ticket).
- Uma única gravação que muda vários campos gera **um** "ticket atualizado" com
  todas as alterações. Uma resposta pública com mudança de estado no mesmo
  envio gera **dois** eventos: "mensagem pública criada" e "ticket atualizado".
- **Incidente** (Δ35): não há tipo próprio. Vincular ou desvincular aparece
  como "ticket atualizado" do **filho** (alteração do pai). Uma resposta no
  pai gera "mensagem pública criada" no pai e em cada filho atingido (inclusive resolvido, D46), cada
  uma com a indicação "replicada do incidente" e o id do pai; resolver o pai
  gera "ticket atualizado" no pai e em cada filho resolvido. Todos levam o
  **mesmo identificador de operação** (spec 12 §4.2).
- Marcar uma sala como inativa não gera "ticket atualizado" nos tickets que a
  usam: o local deles não mudou.

### 11.4 Webhook como ação de gatilho (D13)

- No MVP, um gatilho (spec 05 §3.3) pode ter a ação **entregar a uma
  assinatura**, escolhendo uma assinatura existente.
- O conteúdo é sempre o **envelope padrão** (§12.1) do evento que iniciou a
  passada de gatilhos (ex.: o "ticket atualizado" do fechamento automático).
  Não há corpo livre nem modelo de payload.
- A entrega é criada mesmo que a assinatura não assine aquele tipo. Se ela já
  o assina, há **uma** entrega só para aquele evento (a chave é evento +
  assinatura).
- As mudanças feitas pelo próprio gatilho geram os seus eventos normais, que só
  vão às assinaturas que os assinam.
- A entrega nasce na caixa de saída depois que o gatilho é aplicado, com o
  mesmo motor de entrega, assinatura e log; o log mostra o motivo "gatilho" e
  qual gatilho. Uma falha no destino **não** desfaz o gatilho.
- Assinatura desativada ou inexistente no momento da execução conta como
  **falha da ação**: o gatilho inteiro não é aplicado, o erro é registrado e os
  gatilhos seguintes continuam (D11). A operação original nunca é desfeita.

---

## 12. Webhooks — envelope e conteúdo

### 12.1 Envelope

Todo evento, de qualquer tipo, tem o mesmo envelope, com:
- **id do evento**: único e estável; é o mesmo em todas as tentativas e
  reenvios. É a chave de deduplicação do receptor;
- **tipo** do evento;
- **versão do envelope** (começa em 1; muda só com versão nova da API);
- **ocorrido em**: instante da mudança, em UTC (G4);
- **identificador de operação**: o mesmo em todos os eventos gerados por uma
  única operação (spec 12 §4.2), como a resposta replicada num incidente;
- **conta**: identificador da conta;
- **ator**: tipo (agente, solicitante, identidade de integração, sistema,
  automação), id da pessoa ou da identidade quando houver, e **origem** como na
  auditoria (spec 01 §7): id da regra quando for automação, prefixo do token
  quando for API;
- **recurso**: tipo, id e **versão** do recurso depois da mudança;
- **retrato**: a representação do recurso **no momento do evento**, a mesma da
  leitura pela API v1, vista por um admin;
- **alterações** (só em "atualizado"): para cada campo alterado, o valor
  anterior e o novo; a limpeza de um campo que ficou oculto aparece como
  alteração com o motivo.

Cada **tentativa** de entrega também leva, em cabeçalhos próprios: id do evento,
id da entrega, número da tentativa, instante do envio, motivo da entrega
(assinatura ou gatilho) e assinatura (§12.4).

### 12.2 Retrato ou só ids: decisão

**Decisão: retrato do recurso + alterações.**

Motivos:
- O integrador típico (planilha, CRM, chat da equipe) quer agir sem uma segunda
  chamada. Exigir uma busca pela API para cada evento multiplica o tráfego,
  consome o limite de taxa e obriga toda integração a ter um token.
- Como a ordem não é garantida (§13), o retrato com a **versão** permite ao
  receptor descartar eventos mais velhos do que o estado que já tem.
- O retrato é **do momento do evento**, não do envio: retentativas e reenvios
  mandam o mesmo conteúdo. Quem precisa do estado atual busca pela API.
- No tempo real (spec 09) a escolha foi o contrário (só ids), porque lá os
  destinatários têm permissões diferentes. No webhook o destinatário é sempre a
  integração do admin, com uma única visão; o problema de permissão não existe
  da mesma forma.

Limites do retrato:
- O retrato do ticket **não** contém corpos de mensagens, só contagens e o id da
  última mensagem pública. O conteúdo de mensagens só vai nos eventos de
  mensagem.
- Anexos vão **por referência** (nome, tipo, tamanho, link que exige
  autenticação), nunca o arquivo.
- Envelope com mais de 256 KB: o corpo da mensagem é truncado e marcado como
  truncado; o receptor busca o resto pela API.
- Campos personalizados entram todos, inclusive vazios e ocultos (vazio =
  nulo), para que a ausência nunca seja ambígua.
- Dados de autenticação de pessoas (senha, tokens) nunca entram.

### 12.3 Notas internas: decisão

**Decisão (D03): webhooks são integrações de admin e incluem notas internas,
sempre marcadas como internas, num tipo de evento próprio.**

- O texto de uma nota, e de uma mensagem de sistema interna, só sai no evento
  **nota interna criada**, com a visibilidade interna explícita na mensagem.
  Mensagens de conversa paralela saem nesse mesmo tipo, com a indicação
  "conversa paralela", e nunca em "mensagem pública criada" (D37). Nenhum outro
  evento carrega esses textos (o retrato do ticket não carrega corpos, §12.2).
- Quem não quer notas fora do sistema (ex.: um webhook que posta num canal de
  chat aberto a terceiros) simplesmente **não assina** esses tipos.
- Motivo: a maior parte das integrações de admin (BI, auditoria, espelho no
  CRM) precisa do histórico completo; esconder as notas obrigaria a uma segunda
  integração por API. Separar o tipo deixa a decisão explícita e visível na tela
  da assinatura, em vez de um filtro escondido.
- Não existem webhooks com escopo de solicitante no MVP. Se vierem (roadmap),
  **nunca** terão os tipos internos disponíveis.

### 12.4 Assinatura

- Cada assinatura tem um **segredo** gerado pelo servidor (no mínimo 256 bits
  aleatórios), mostrado uma vez na criação e em cada rotação.
- Cada tentativa é assinada com **HMAC-SHA256** sobre a concatenação do instante
  do envio, um ponto e o **corpo bruto** exato enviado. A assinatura vai em
  hexadecimal, num cabeçalho próprio, junto com o instante.
- A assinatura é **recalculada a cada tentativa**, com o instante daquele envio.
  Assim uma retentativa de 12 h depois continua dentro da janela de replay.
- **Janela de replay** recomendada ao receptor: recusar envios cujo instante
  difira mais de **5 minutos** do relógio dele; comparar assinaturas em tempo
  constante; guardar ids de evento já processados por pelo menos 72 h. A
  documentação da API descreve esse procedimento passo a passo.
- **Rotação**: o admin gira o segredo; o novo passa a valer na hora e o antigo
  continua válido por **24 h**. Nesse período, cada envio leva **duas**
  assinaturas (uma com cada segredo) no mesmo cabeçalho; o receptor aceita se
  qualquer uma conferir. O admin pode encerrar o período antes ("revogar o
  antigo agora"), por exemplo após vazamento.
- O envio de teste é assinado do mesmo jeito.

---

## 13. Webhooks — entrega

### 13.1 Outbox transacional

- O evento de webhook nasce do evento de domínio (spec 12 §4.1) e é gravado
  numa **caixa de saída** na **mesma transação** da mudança (spec 01 §7). Se a
  mudança não for gravada, não há evento; se for, o evento não se perde mesmo
  que o processo caia logo depois.
- Um processo de entrega lê a caixa de saída e cria uma **entrega** para cada
  assinatura ativa que corresponde ao tipo, mais as pedidas por gatilho
  (§11.4). A entrega é sempre **assíncrona**: um destino lento ou fora do ar
  **nunca** atrasa nem desfaz a gravação do ticket.
- Eventos que ocorrem enquanto uma assinatura está **desativada** não geram
  entrega para ela. A recuperação é pelo feed de eventos (30 dias, §4), pela
  listagem "mudanças desde" (§5.3) ou por reenvio manual (§13.6).
- No máximo **5 entregas simultâneas** por assinatura, para não sobrecarregar o
  receptor.

### 13.2 Garantias declaradas

- **Pelo menos uma vez.** O mesmo evento pode chegar mais de uma vez. Casos
  típicos: o receptor processou mas respondeu depois do timeout; o processo de
  entrega caiu depois de enviar e antes de registrar o sucesso; o admin reenviou
  manualmente. O receptor deduplica pelo **id do evento**.
- **Sem ordem garantida.** Retentativas e entregas paralelas embaralham a
  ordem: um "ticket atualizado" da versão 9 pode chegar antes do da versão 8. O
  receptor usa a **versão do recurso** do envelope para descartar o mais velho.
- **Perda** só acontece se a assinatura estiver desativada ou se todas as
  tentativas falharem; os dois casos ficam no log.

### 13.3 Tentativa e sucesso

- **Timeout total de 10 s** por tentativa (conexão de no máximo 5 s, incluída
  nos 10 s). Timeout conta como falha e gera retentativa.
- **Sucesso** = qualquer status 2xx. O corpo da resposta é ignorado (guardado no
  log, truncado).
- 3xx = falha **definitiva** (redirecionamento não é seguido nem retentado; o
  admin precisa corrigir a URL).
- Falha **retentável**: timeout, erro de rede, DNS ou TLS, 408, 409, 425, 429 e
  qualquer 5xx.
- Falha **definitiva** (sem retentativa): demais 4xx. Conta como falha para a
  desativação automática.
- **410 (Gone)**: a assinatura é desativada imediatamente, com notificação ao
  admin (o receptor disse que o destino não existe mais).

### 13.4 Calendário de retentativas

| Tentativa | Momento (a partir da 1ª tentativa) |
|---|---|
| 1 | imediata |
| 2 | +1 min |
| 3 | +5 min |
| 4 | +30 min |
| 5 | +2 h |
| 6 | +6 h |
| 7 | +12 h |
| 8 | +24 h (última) |

- Cada momento recebe variação aleatória de ±10%.
- Se o destino responder 429 ou 503 com "tentar depois", a próxima tentativa é
  no **maior** entre o momento seguinte do calendário e o instante da resposta
  mais o pedido do destino, limitado a **1 h depois** do momento do calendário.
  Momentos do calendário que caiam antes da tentativa adiada são **absorvidos**
  por ela (não acontecem separadamente); as tentativas seguintes continuam nos
  momentos do calendário. Assim o total nunca passa de 8, mas pode ser menor.
- Depois da última falha, a entrega fica **falha** no log e pode ser reenviada
  manualmente.

### 13.5 Desativação automática

- Uma assinatura é **desativada automaticamente** quando, ao mesmo tempo:
  houve pelo menos **20 tentativas seguidas com falha** (de quaisquer eventos)
  **e** a última entrega bem-sucedida foi há mais de **24 h** (ou nunca houve
  sucesso e a primeira falha foi há mais de 24 h).
- A dupla condição evita desativar por um pico curto (muitos eventos durante 10
  minutos de queda) e também evita manter viva por dias uma assinatura que nunca
  funciona.
- Ao desativar: entregas pendentes dessa assinatura param e ficam **suspensas**;
  todos os admins recebem notificação in-app e e-mail (spec 09 §7.1, "webhook
  desativado"); um evento de auditoria é gravado com origem sistema.
- **Reativação** só manual, pelo admin. Ao reativar, o admin escolhe reenviar as
  entregas suspensas que ainda estão dentro da retenção do log, ou descartá-las.
  A reativação zera a contagem de falhas.

### 13.6 Log de entregas e reenvio manual

- Para cada entrega: id do evento, tipo, id da entrega, motivo (assinatura ou
  gatilho), estado (pendente, entregue, falha, suspensa), e cada tentativa com
  instante, status HTTP ou tipo de erro (timeout, DNS, TLS, conexão recusada,
  bloqueado por SSRF), latência, cabeçalhos e corpo enviados, e até 2 KB do
  corpo da resposta.
- **Retenção de 14 dias**; limpeza diária. Depois disso a entrega não pode mais
  ser reenviada (o integrador usa o feed de eventos, até 30 dias, ou "mudanças
  desde").
- O log pode ser lido pela API e na tela da assinatura, filtrado por estado e
  por intervalo de tempo.
- **Reenvio manual**: o admin reenvia uma entrega, ou todas as falhas de um
  intervalo. O reenvio usa o **mesmo id de evento** e o mesmo conteúdo, com id
  de entrega novo e marca de "reenvio manual". Reenvio para assinatura
  desativada é recusado.
- **Teste**: envia um evento do tipo teste, aparece no log e não conta para a
  desativação automática.

### 13.7 Receptor de teste (D22)

Os testes de webhook não dependem de nada fora do PantherDesk. O próprio
produto traz um **receptor de teste**, ligado só em ambiente de desenvolvimento
e de teste (nunca em produção) e incluído na lista de permissões dessa
instalação.

- Aceita entregas num endereço por cenário. O cenário diz o **status** a
  responder (ex.: 200, 301, 400, 410, 429, 500, 503), a **demora** antes de
  responder (ex.: 30 s) e, opcionalmente, o valor de "tentar depois" e uma
  sequência (ex.: "falhar 2 vezes com 500, depois 200").
- **Registra** cada pedido recebido: instante de chegada, cabeçalhos e corpo
  bruto, para os testes consultarem e conferirem assinatura, envelope e
  calendário.
- Pode receber o segredo de uma assinatura para conferir o HMAC e marcar cada
  pedido como "assinatura confere" ou não.
- O registro é limpo no início de cada suíte de teste.

---

## 14. Abordagens comparadas

### 14.1 API REST

| Projeto | Abordagem observada (documentação) | Prós | Contras |
|---|---|---|---|
| **Zammad** | REST JSON sob prefixo de versão; token pessoal, OAuth2 e Basic (desativável); impersonação por admin; paginação por número de página com teto rígido e total opcional; expansão de relações; busca por condições | autenticação completa; total opcional evita custo | paginação por página degrada em listas grandes; erro e limite de taxa não documentados [evidência pendente: API-01, API-05] |
| **Chatwoot** | Três famílias de API (conta, cliente final, administração da instalação); token de usuário sem escopos; recursos aninhados na conta; listagem com contagens por aba; limite por IP (~60/min) configurável | separação clara entre automação de conta e widget do cliente | token sem escopos; limite por IP, não por usuário; cabeçalhos de limite não descritos |
| **FreeScout** | API em módulo pago; chave por usuário ou global, aceita até na URL; paginação por página com totais; "embutir" relacionados; erro com **lista por campo**; status HTTP bem documentados; datas ISO em UTC | melhor formato de erro dentre os projetos | chave global e chave na URL são riscos; sem limite, idempotência ou versionamento documentados |
| **osTicket** | Só criação de ticket; chave presa a um IP; aceita JSON, XML ou e-mail bruto; erro em texto | simples para "abrir ticket a partir de outro sistema" | não lê nem altera; insuficiente para integração |
| **Znuny** | Framework configurável de serviços web; credenciais por chamada ou sessão; mapeamento de dados; erro com código no corpo e **status 200** | flexibilidade máxima | sem contrato estável; erro com 200 quebra clientes HTTP comuns; exportação de configuração com senhas em claro |
| **UVdesk** | Pacote separado; tokens nomeados criados pelo admin; paginação por página com listas de referência fixas | tokens administráveis | escopos, erros e limites não documentados |
| **Frappe Helpdesk** | CRUD genérico do framework por tipo de registro; chave+segredo do usuário, sessão ou OAuth2; filtros E/OU; offset+limite; limite de taxa com 429; erro com tipo da exceção e stack trace | ações rodam com os papéis do usuário; limite de taxa existe | sem API própria do helpdesk; stack trace vaza detalhes; offset em listas grandes |
| **Referência de mercado (documentação pública do Zendesk)** | Versão no caminho; JSON com datas ISO em UTC; OAuth2 recomendado e token "senha-equivalente" em depreciação; **cursor** recomendado e offset limitado; inclusão de relacionados no nível superior; 409 para conflito e 422 para regra de negócio; limite por plano com 429 e cabeçalhos; chave de idempotência na criação de ticket com validade de 2 h | é o que integradores esperam; cursor e idempotência evitam problemas reais | superfície muito grande para um MVP |

**Escolha do PantherDesk e motivos (API)**

| Tema | Escolha | Por quê |
|---|---|---|
| Autenticação | sessão (UI e portal) + token pessoal só para si + identidade de integração do admin, com os mesmos três escopos, só em cabeçalho; sem Basic, sem chave global, sem token na URL | o token nunca pode mais que o dono (Frappe, Zammad); escopos suprem a falta do Chatwoot; a identidade de integração evita usar um agente humano como robô (tokens nomeados do admin, como no UVdesk, mas com acesso por grupo); evita os riscos de chave global e de chave na URL (FreeScout, Znuny) |
| Paginação | só cursor, máximo 100 (acima → 400), total opcional | offset profundo é lento e inconsistente; o mercado migrou para cursor |
| Ordenação | as das filas (D32): criado, atualizado, vencimento do SLA, prioridade, número, na fila há mais tempo; desempate pelo número | a interface e a API listam do mesmo jeito; filas salvas dependem de prazo de SLA e prioridade |
| Erro | envelope único com código e detalhes por campo; nunca 200 nem stack trace | junta o melhor do FreeScout e evita os anti-padrões do Znuny e do Frappe |
| 404 × 403 | visibilidade primeiro (404); 403 só para ação proibida sobre recurso visível (D05) | não confirmar a existência de tickets de outros grupos |
| Limite de taxa | por ator, com cabeçalhos em segundos e 429 | por IP (Chatwoot) pune NAT compartilhado e não protege contra token vazado |
| Idempotência | chave opcional em todo POST, 24 h | nenhum projeto analisado tem; retries de integradores criam tickets duplicados |
| Concorrência | versão de campo e estado + ETag/If-Match, 409; opcional na API (D01) | mesma regra da interface (spec 09); mensagens nunca são recusadas por versão |

### 14.2 Webhooks

| Projeto | Abordagem observada (documentação) | Prós | Contras |
|---|---|---|---|
| **Zammad** | Webhook é uma ação de gatilho ou agendador; retrato do ticket + último artigo; payload customizável; HMAC-SHA1 do corpo; id único de entrega; até 4 retentativas; log recente com requisição e resposta | reaproveita o motor de automação; log detalhado | sem assinatura de eventos direta; sem anti-replay; intervalos e desativação não documentados [evidência pendente: API-02, API-03] |
| **Chatwoot** | Assinatura por conta com escolha de eventos; payload com objetos aninhados e alterações (antes/depois); HMAC-SHA256 sobre instante + corpo; recomenda janela de ~5 min | melhor modelo de assinatura e de alterações | retry, timeout e desativação não documentados [evidência pendente: API-03, API-04] |
| **FreeScout** | Webhooks gerenciáveis pela API; eventos de conversa e cliente; corpo = representação da API; HMAC-SHA1 em base64 com segredo **global**; até 10 tentativas em ~2 h; log de 3 dias | retry e log documentados; payload igual à API | segredo único para todos os webhooks; sem anti-replay; janela de retry curta |
| **osTicket** | Sem webhooks nativos | — | ausência |
| **Znuny** | Saída por serviço web disparada por eventos com condições; pode alterar o ticket com a resposta; assíncrono opcional; sem HMAC | muito flexível | síncrono por padrão pode travar a gravação; sem assinatura; retry não padronizado |
| **UVdesk** | Sem webhooks documentados | — | ausência |
| **Frappe Helpdesk** | Webhook por tipo de registro + evento do ciclo de vida, com condição; corpo por modelo; HMAC-SHA256 em base64 do corpo; log só de sucessos | simples de configurar | sem anti-replay; retry e timeout não documentados; falhas não ficam no log |
| **Referência de mercado (documentação pública do Zendesk)** | Dois modos (assinatura de eventos e ação de gatilho); HMAC-SHA256 sobre instante + corpo com segredo rotacionável; timeout de 12 s; retentativas por tipo de falha; disjuntor por taxa de erro; entrega de melhor esforço, possivelmente duplicada; log de 7 dias | garantias declaradas com honestidade; disjuntor protege o sistema | pode perder eventos com o disjuntor aberto; dois modos imutáveis confundem |

**Escolha do PantherDesk e motivos (webhooks)**

| Tema | Escolha | Por quê |
|---|---|---|
| Modelo | assinatura de eventos (modelo Chatwoot) + ação de gatilho que entrega a uma assinatura existente, com o mesmo envelope (D13) | o catálogo estável é mais fácil de manter que um payload por gatilho (Zammad, Frappe); um motor só; ao contrário da referência de mercado, os dois caminhos usam a mesma assinatura e o mesmo envelope, então não há modo a escolher na criação |
| Payload | envelope fixo + retrato na representação da API + alterações antes/depois | dispensa segunda chamada; versão resolve a falta de ordem |
| Notas internas | incluídas, só nos tipos internos, sempre marcadas (D03) | integração de admin precisa do histórico; a decisão fica explícita na assinatura |
| Eco | identidade dona com supressão por padrão + atores ignorados | evita o laço integração → webhook → integração |
| Assinatura | HMAC-SHA256 sobre instante + corpo, por assinatura, com rotação de 24 h e dupla assinatura | anti-replay (Chatwoot, Zendesk); segredo por assinatura (contra o segredo global do FreeScout); rotação sem janela de quebra |
| Entrega | outbox transacional, assíncrona, timeout de 10 s | não perde evento e nunca trava o ticket (contra o modelo síncrono do Znuny) |
| Retentativas | 8 tentativas em ~24 h com variação | cobre uma noite inteira de queda (FreeScout: só 2 h) |
| Desativação | 20 falhas seguidas **e** 24 h sem sucesso; 410 desativa na hora; aviso aos admins | mais simples que um disjuntor por taxa de erro e não desativa por picos curtos |
| Log | 14 dias, por tentativa, com reenvio manual; feed de 30 dias | dobro do mercado; dá tempo de investigar depois de um fim de semana |
| Testes | receptor de teste dentro do produto (D22) | os critérios de aceite rodam sem infraestrutura externa |

---

## 15. Casos de teste (critérios de aceite)

Atores: `ag1` e `ag2` (grupo N1, escrita), `ag3` (grupo Financeiro, escrita),
`apoio1` (agente de apoio: leitura em todos os grupos), `admin`, solicitantes
`ana` e `bia` (org. Acme), `cris` (sem org.). `T1` = token de ag1 com escopo
escrita; `T3` = token de ag3 com escopo escrita; `TA` = token de admin com
escopo administração; `TP` = token de apoio1 com escopo escrita; `INT` =
identidade de integração com escrita no N1 e token `TI` (escrita). A conta tem
"responsável obrigatório para resolver" **ligado** (EARJ). Destino de teste:
o **receptor de teste** (§13.7), na lista de permissões da instalação.

### 15.1 Autenticação e permissões
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AP-01 | ag1 cria token com escopo leitura | ler o token na listagem | o segredo não aparece; só nome, prefixo, escopos e datas |
| AP-02 | — | pedido sem credencial | 401 com o envelope de erro e id da requisição |
| AP-03 | T1 revogado | pedido com T1 | 401 |
| AP-04 | ag1 desativado | pedido com T1 | 401; ao reativar ag1, T1 volta a funcionar |
| AP-05 | token de leitura de ag1 | criar ticket | 403 `escopo_insuficiente`; nada gravado |
| AP-06 | ticket #1000 no N1 | T3 lê #1000 | 404 idêntico ao de um id inexistente (mesmo código e mensagem) |
| AP-07 | ag1 removido do N1 | T1 lê #1000 | 404 já no pedido seguinte |
| AP-08 | ag1 é agente | ag1, na sessão, tenta criar token com escopo administração | 403 `papel_insuficiente`; nenhum token criado (D14) |
| AP-09 | — | T1 enviado como parâmetro de consulta | 400; o token não é usado; ag1 recebe aviso de vazamento |
| AP-10 | ticket #1000 de ana, com nota interna | sessão de ana lista as mensagens | a nota não aparece nem conta no total; ler a nota pelo id → 404 |
| AP-11 | #1000 pendente, de ana | sessão de ana tenta mudar o campo de estado para aberto | 403 (spec 01 §4.2) |
| AP-12 | #1000 de ana | sessão de ana lê o histórico de auditoria | 403 (spec 01 TL-54) |
| AP-13 | T1 altera a prioridade de #1000 | ler a auditoria | evento com origem API e prefixo do token T1 |
| AP-14 | admin criou TA; depois é rebaixado a agente com escrita no N1 | TA cria webhook; TA lê #1000 | criar webhook → 403; ler #1000 → 200; ao voltar a admin, TA cria webhook normalmente (D14) |
| AP-15 | token de leitura de ag1; #1030 no Financeiro | alterar #1030 | **404** (a visibilidade vem antes do escopo, D05) |
| AP-16 | token de leitura de ag1 | alterar #1000 (visível) | 403 `escopo_insuficiente` |
| AP-17 | INT com escrita no N1 | TI cria mensagem pública em #1000; TI lê #1030 (Financeiro) | 201, tipo de autor integração, auditoria com ator INT e origem API; #1030 → 404 |
| AP-18 | — | TA (token) tenta criar um token; admin, na sessão, tenta criar token pessoal para ag1 | os dois → 403; nenhum token criado |
| AP-19 | organização Acme com "todos os membros"; #1005 de bia | sessão de ana lista os tickets e tenta responder #1005 | #1005 aparece na lista, só leitura; a resposta → 403 (D07) |
| AP-80 | ag1 com T1 e um segundo token T1b; admin desativa ag1 | admin lista os tokens de ag1 e revoga T1b; depois reativa ag1 | enquanto ag1 está desativado, T1 e T1b → 401 e aparecem como suspensos; após a reativação, T1 → 200 e T1b → 401 (D26) |
| AP-81 | INT criada sem a marca administrativa; INT-ADM criada pelo admin marcada como administrativa | admin, na sessão, cria token com escopo administração para INT e para INT-ADM; o token de INT-ADM cria webhook | INT → 403 `papel_insuficiente`, nenhum token criado; INT-ADM → token criado; webhook → 201 (D36) |
| AP-103 | ag1 entra na interface só com Google (sem senha local) | (a) na sessão obtida pelo Google, ag1 cria o token T1c com escopo escrita; (b) um script envia à API, no cabeçalho de autorização, uma credencial emitida pelo Google para ag1; (c) Basic com o e-mail de ag1 | (a) 201, segredo exibido uma vez; T1c funciona como qualquer token pessoal; (b) 401, sem aviso de vazamento; (c) 401 (Δ31) |

### 15.2 Recursos, validação e erros
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AP-20 | — | T1 cria ticket no N1 para ana | 201 com o recurso e sua localização; id opaco; número legível como campo; datas em UTC com sufixo; tipo vazio |
| AP-21 | — | T1 cria ticket sem grupo e com prioridade "máxima" | 422 `validacao` com **dois** detalhes: grupo `obrigatorio` e prioridade `opcao_inexistente` |
| AP-22 | — | T1 cria ticket com responsável ag3 no N1 | 422 com detalhe `sem_acesso_ao_grupo` |
| AP-23 | #1000 fechado | T1 tenta mudar para aberto | 403 (papel: só admin reabre fechado); nenhum evento de auditoria |
| AP-24 | #1000 fechado | T1 tenta mudar para pendente | 422 `transicao_invalida` |
| AP-25 | — | criar ticket com campo desconhecido | 400 com o nome do campo |
| AP-26 | — | data de retorno enviada sem fuso | 422 |
| AP-27 | mensagem existente | tentar alterá-la | 405 |
| AP-28 | #1011 mesclado em #1010 | T1 cria mensagem em #1011 | 422 com o id de #1010 nos detalhes; nada gravado |
| AP-29 | erro interno forçado | qualquer pedido | 500 com o envelope; sem stack trace, sem nome de classe |
| AP-60 | #1000 de ana, pendente | sessão de ana usa "meu problema foi resolvido" | 200; estado resolvido; mensagem de sistema pública; evento de origem solicitante (D08) |
| AP-61 | #1000 de ana, bia participante | sessão de bia usa "meu problema foi resolvido" | 403 |
| AP-62 | #1001 aberto, sem responsável | T1 muda para resolvido | 422 com detalhe responsável `obrigatorio` (Δ4); nada gravado |
| AP-63 | #1000 aberto de ana | T1 muda para em espera; ana lê #1000 pela sessão | 200 com estado `em_espera`; para ana, o estado vem como `aberto` |
| AP-64 | #1000 no N1, responsável ag1 | T1 encaminha com retorno para Financeiro sem nota; depois com nota | sem nota → 422 (nota `obrigatorio`); com nota → 200: grupo Financeiro, sem responsável, estado `aberto`, marca "encaminhado", origem do encaminhamento = ag1/N1, nota interna gravada (D23) |
| AP-65 | após AP-64 | T3 devolve com nota | grupo N1, responsável ag1, estado aberto, origem limpa |
| AP-66 | após AP-64 | T3 encaminha com retorno para um 3º grupo | 422 `encaminhamento_aninhado` |
| AP-67 | campo "Equipamento" visível só se "Motivo" = hardware | T1 cria ticket com Motivo = rede e Equipamento = "impressora" | 422 com detalhe `campo_oculto` em Equipamento (revisto em v0.3, D51) |
| AP-68 | — | TA cria campo A que depende de B e B que depende de A | 422 `ciclo_de_condicao` no segundo |
| AP-69 | ag3 sem acesso ao N1 | T1 cria nota em #1000 mencionando ag3; depois cria mensagem pública com "@ag2" | as duas → 201; a nota traz aviso `mencao_sem_acesso`; a pública traz aviso `mencao_em_publica` e nenhuma menção |
| AP-70 | apoio1 com leitura no N1 | TP cria mensagem pública em #1000; TP cria nota em #1000 | pública → 403; nota → 201 |
| AP-71 | — | TA cria macro compartilhada com o marcador de uma variável inexistente | 422 `variavel_desconhecida` com o marcador nos detalhes; nada salvo |
| AP-72 | macro com variável de primeiro nome do solicitante e de número do ticket | T1 pede a prévia para #1000 de ana | texto "Olá Ana, ticket #1000" e lista de mudanças; #1000 não muda (versão igual) |
| AP-73 | ag1 com 10 filas pessoais | T1 cria a 11ª | 422 `limite_de_filas` |
| AP-74 | fila compartilhada restrita ao Financeiro | T1 lista as filas salvas | a fila não aparece; ler pelo id → 404 |
| AP-75 | #1003 fechado de ana, com participante bia e campo Motivo = hardware | T1 cria continuação | 201; ticket novo vinculado a #1003, solicitante ana, participante bia, Motivo = hardware; #1003 não muda (exemplo revisto em v0.3, D51) |
| AP-76 | #1000 na versão 7 | T1 segue #1000; T3 tenta seguir #1000 | T1 → 200, ag1 na lista de seguidores, versão continua 7; T3 → 404 |
| AP-77 | #1000 de ana | T1 abre conversa paralela com um fornecedor; a sessão de ana lista as mensagens | 201; ana não vê a conversa nem as mensagens dela |
| AP-78 | #1000 resolvido | sessão de ana avalia com nota 2 e motivo; T1 lista avaliações do dia | 201; a avaliação aparece para T1; versão de #1000 não muda |
| AP-79 | pessoas "ana" e "ana (duplicada)" | T1 mescla a duplicada em ana; TP tenta a mesma mescla | T1 → 200, endereços e tickets passam para ana; TP → 403 |
| AP-82 | — | T1 cria rascunho de artigo e o altera; T1 tenta publicá-lo; TA publica | criar → 201 e alterar → 200, como rascunho; publicar com T1 → 403; com TA → 200, artigo publicado (D30) |
| AP-83 | #1000 **pendente** no N1, responsável ag1 | T1 encaminha com retorno para Financeiro (com nota); depois T1 lê #1000, cria nota interna e tenta mudar a prioridade | encaminhar → 200, estado `aberto`, grupo Financeiro, marca "encaminhado"; ler → 200; nota → 201; prioridade → 403 (D23, D24) |
| AP-84 | macro M (resposta pública "Olá {primeiro nome}", estado → pendente, etiqueta "aguardando-peca"); #1000 de ana aberto, v7 | T1 cria mensagem informando M, com a versão 7 | 201; mensagem pública "Olá Ana"; estado pendente e etiqueta adicionada; versão 8; auditoria registra a macro M; uso de M +1 (D29) |
| AP-85 | #1000 (aberto, responsável ag1), #1001 (aberto, sem responsável), #1030 (Financeiro) | T1 pede edição em massa: estado → resolvido nos três | resultado por ticket: #1000 alterado; #1001 falha com responsável `obrigatorio`; #1030 falha como inexistente (404); auditoria de #1000 marcada "via edição em massa" (D32) |
| AP-86 | idem com 101 ids | T1 pede edição em massa | 400; nenhum ticket alterado |
| AP-87 | #1001 de ana, pendente, sem responsável, com campo obrigatório para resolver vazio | sessão de ana usa "meu problema foi resolvido" | 200; estado resolvido, marca "resolvido pelo solicitante"; nenhum 422 (D33) |
| AP-90 | — | TA cria campus Barra, prédio A, andar "2º" e a sala "Sala 204" com código B204; T1 tenta criar a sala B205; TA cria outra sala com código B204 | as quatro criações de TA → 201 (a sala com caminho Barra / A / 2º); T1 → 403; código repetido → 422 `validacao` com detalhe no código |
| AP-91 | sala B204 de AP-90 | TA renomeia para "Laboratório 204"; T1 lê o endereço do QR antes e depois; TA tenta mudar o código | o endereço do QR é o mesmo antes e depois, no domínio da conta, e contém só o código B204; mudar o código → 422 |
| AP-92 | #1000 com local B204 | TA desativa B204; T1 cria ticket com local B204; T1 lê #1000 | criação → 422 `local_inativo`; #1000 continua com B204, marcada como inativa; nenhum "ticket atualizado" em #1000 |
| AP-94 | — | T1 cria ticket para ana com local B110 e origem `qr`; sessão de ana lista os locais | 201; o ticket traz campus Barra, prédio, andar e sala B110, origem `qr`; ana vê só salas ativas, sem a contagem de tickets |
| AP-95 | antecedência mínima da conta: 5 dias úteis | (a) T1 cria pelo formulário de evento, seg 2026-11-09 10:00, um evento na ter 2026-11-17 de 19:00 a 21:00, montagem 14:00, local B204, tipo `assembly`; (b) cria qua 2026-11-11 10:00 um evento na qui 2026-11-12 | (a) 201; o bloco de evento traz início 2026-11-17T22:00:00.000Z, fim 2026-11-18T00:00:00.000Z e montagem 2026-11-17T17:00:00.000Z; (b) 201, com a marca "fora do prazo" (o pedido é aceito) |
| AP-96 | — | T1 cria evento com montagem às 20:00 e início às 19:00; depois com a montagem "2026-11-17T14:00:00" sem deslocamento | 422 `montagem_depois_do_inicio`; 422 (data sem fuso, G4) |
| AP-98 | #1100 aberto no N1; #1101 e #1102 abertos no N1; #1030 no Financeiro | T1 marca #1100 como pai e vincula #1101, #1102 e #1030 | resultado por item: #1101 e #1102 vinculados (versão de cada um +1), #1030 → 404; versão de #1100 não muda; #1100 mostra 2 filhos e os locais afetados |
| AP-99 | após AP-98; #1110 marcado como pai | T1 vincula #1100 a #1110; T1 vincula #1101 a #1110; T1 desmarca #1100 como pai | 422 `incidente_aninhado`; 422 `filho_ja_vinculado`; 422 (tem filhos) |
| AP-100 | após AP-98; ana (idioma PT) é solicitante de #1101 e bia (idioma EN) de #1102; macro M com variantes PT "Olá {primeiro nome}" e EN "Hello {primeiro nome}" | T1 cria mensagem pública em #1100 informando M | 201; a resposta indica 2 filhos atingidos; #1101 registra "Olá Ana" e #1102 "Hello Bia"; auditoria de cada um registra M e a variante |
| AP-101 | após AP-98; #1101 e #1102 com responsável | T1 resolve #1100 com resposta pública; depois a sessão de ana tenta avaliar #1101 | resultado por filho: #1101 e #1102 resolvidos; nenhum convite de pesquisa no pai nem nos filhos; a avaliação → 422 `sem_convite` |
| AP-102 | conta com idioma padrão PT | TA cria a macro "Atendimento no local" com variantes PT e EN e nome EN "On-site visit"; tenta acrescentar outra variante PT; T1 busca "on-site"; T1 pede a prévia para #1003, de cris (idioma EN), de uma macro só com variante PT; repete pedindo a variante PT; TA cria uma macro só com variante EN; TA remove a variante PT de "Atendimento no local" | 201; segunda PT → 422 `variante_duplicada`; a busca encontra a macro; prévia com a variante PT (idioma da conta) e aviso `variante_ausente`; pedida a PT explicitamente, sem aviso; pedir o filtro por idioma → 400 (parâmetro desconhecido); macro só EN → 422 `validacao` com a variante PT `obrigatorio`; remover a PT → 422, nada gravado (revisto em v0.3, D49) |
| AP-104 | #1000 resolvido, assunto "Impressora não imprime", com resposta pública final de ag1; #1001 aberto | T1 cria artigo a partir de #1000, categoria "Impressoras", idioma PT, pedindo também a outra língua (EN); depois a partir de #1001; T1 tenta publicar o rascunho | 201: **um** artigo em rascunho com título "Impressora não imprime", texto da resposta final de ag1 sem nome ou e-mail de ana, "criado a partir de #1000", e uma **tradução EN em rascunho no mesmo artigo**; nenhum segundo artigo; a partir de #1001 → 422 `validacao`; publicar com T1 → 403 (D30) (revisto em v0.3, D42) |
| AP-105 | salas B204 e B110 ativas; B300 inativa | sessão de ana grava as suas salas [B204, B110]; depois [B300]; depois tenta alterar as salas de bia | 200, na ordem gravada; [B300] → 422 `local_inativo`; bia → 404 |
| AP-106 | #1104 (Financeiro, responsável ag3) vinculado a #1100 (N1); ag3 sem acesso ao N1 | T3 desvincula #1104; depois T3 tenta vincular #1104 de novo a #1100 | desvincular → 200 (escrita no filho basta, D45), versão de #1104 +1, versão de #1100 não muda; vincular → 404 (ag3 não vê o pai, D05) |
| AP-107 | após AP-98; #1102 com responsável ag2 | T1 tenta vincular a #1100 um ticket #1130 do Financeiro, que ag1 não vê, junto com #1131 do N1 | resultado por item: #1130 → 404, indistinguível de inexistente; #1131 vinculado (D43) |
| AP-108 | após AP-98; #1101 **resolvido**; #1102 **fechado** | T1 cria mensagem pública em #1100 | 201; a resposta indica 1 filho atingido; #1101 registra a mensagem e continua resolvido, sem mudança de versão; #1102 não recebe nada (D46) |
| AP-109 | após AP-98; #1101 sem responsável, #1102 com responsável ag2; regra "responsável obrigatório para resolver" ligada; ag1 tem escrita nos grupos dos filhos (D55) | T1 resolve #1100 com resposta pública | resultado por filho: #1101 resolvido com responsável ag1; #1102 resolvido com responsável ag2; nenhum 422 `obrigatorio` (D47) |
| AP-110 | evento #1310 de AP-97, montagem qui 2026-11-12 14:00, no N1 | (a) seg 2026-11-09 10:00, T1 põe a marca "pronto"; (b) TP tenta retirá-la; (c) T1 retira; (d) T1 põe de novo; (e) qui 2026-11-12 15:00, T1 tenta retirá-la | (a) 200, a marca traz ag1 e 2026-11-09T13:00:00.000Z, evento de auditoria registrado, versão +1, selo `pronto`; (b) 403 (apoio1 só lê); (c) 200, selo `faltam`; (d) 200; (e) 422 `validacao` (montagem já começou, D44) |
| AP-111 | evento #1311 de AP-97 (montagem ter 2026-11-17 14:00, fim às 21:00), sem a marca "pronto", criado pelo portal sem resposta | T1 lê o selo ter 2026-11-17 15:00 e qua 2026-11-18 08:00; lê as métricas | `montagem_sem_pronto` e depois `evento_encerrado`; a métrica de 1ª resposta existe, a de resolução não (D40) |
| AP-112 | #1000 resolvido, com resposta pública final de ag1 | TP (apoio1, só leitura no N1) cria artigo a partir de #1000 | 201, rascunho criado (leitura basta, D42) |

### 15.3 Listagens
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AP-30 | 120 tickets no N1 | T1 lista sem tamanho | 25 itens, cursor e "há mais" |
| AP-31 | idem | percorrer com tamanho 100 até o fim | 120 itens sem repetição nem buraco; a última página não tem cursor |
| AP-32 | — | tamanho 500 | 400 (D15) |
| AP-33 | cursor de uma lista filtrada por estado aberto | usar com filtro estado pendente | 400 |
| AP-34 | tickets no N1 e no Financeiro | T3 lista com total | só tickets do Financeiro; o total não conta os do N1 |
| AP-35 | — | filtro inexistente | 400 com o filtro nos detalhes |
| AP-36 | ordenação por "atualizado em"; ag2 altera um ticket da página 1 durante a paginação | continuar | o ticket reaparece numa página seguinte; nenhum ticket é perdido |
| AP-37 | 3 tickets alterados depois do instante X | "mudanças desde X" | exatamente esses 3, no estado atual |
| AP-38 | #1001 (prazo de SLA 10:00), #1002 (prazo 10:00), #1003 (prazo 11:00), #1004 (sem prazo) | T1 lista por prazo de SLA crescente | #1002, #1001, #1003, #1004 (empate desfeito por número decrescente; sem prazo no fim) |
| AP-39 | — | T1 lista ordenando por assunto | 400 |
| AP-88 | #1001 e #1002 criados no mesmo instante; #1003 criado depois | T1 lista por criado, crescente; depois por número, crescente; depois usa um cursor adulterado | criado: #1002, #1001, #1003 (empate pelo número, decrescente); número: #1001, #1002, #1003; cursor adulterado → 400 (D28, D32) |
| AP-89 | após AP-83 | T1 lista os tickets do N1 com o filtro da marca "encaminhado"; T3 lista os do Financeiro sem responsável, por "na fila há mais tempo" | T1 vê #1000 com a marca "encaminhado" e estado `aberto`; T3 vê #1000 na fila do Financeiro (D23, D32) |
| AP-93 | no N1: #1201 (B204, 2º andar do prédio A da Barra), #1202 (B110, 1º andar), #1203 (sala da Gávea), #1204 (sem local, com a etiqueta "barra") | T1 lista com local = andar 2º do prédio A; depois com local = campus Barra; depois "sem local" | só #1201; #1201 e #1202 (#1204 não entra: a etiqueta não é local); só #1204 |
| AP-97 | eventos no N1: #1310 em qui 2026-11-12 (Barra), #1311 em ter 2026-11-17 19:00 (Barra) e #1312 em ter 2026-11-17 (Gávea); #1000 não é evento | T1 lista tickets com o filtro de evento, data do evento de 2026-11-01 a 2026-11-30, campus Barra, ordenados por data do evento crescente; depois de 2026-11-01 a 2027-01-15 | #1310 e #1311, nessa ordem, pelo contrato comum de listagem; #1000 e #1312 não aparecem; o segundo pedido → 200 (sem limite próprio de intervalo); não existe recurso "calendário" (revisto em v0.3, D50) |

### 15.4 Idempotência, concorrência e limites
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| AP-40 | — | T1 cria ticket com chave K; repete o mesmo pedido 3 vezes | 1 ticket; as 4 respostas são iguais (201, mesmo id); as repetições levam o indicador de repetição |
| AP-41 | após AP-40 | mesma chave K com assunto diferente | 422; nada gravado |
| AP-42 | — | dois pedidos simultâneos com a mesma chave | um 201 e um 409 (em andamento); 1 ticket |
| AP-43 | primeira tentativa com K devolveu 422 | corrigir e reenviar com K | 201 |
| AP-44 | chave K usada há 24 h e 1 min | repetir com K | executado como pedido novo |
| AP-45 | T1 lê #1000 (versão 7, ETag) | ag2 altera um campo de #1000 (v8); T1 altera com pré-condição da versão 7 | 409 `conflito_de_versao` com versão atual 8 e resumo; nada gravado |
| AP-46 | idem | T1 altera só a prioridade **sem** pré-condição | 200; só a prioridade muda; a alteração de ag2 continua |
| AP-47 | — | leitura condicional com a ETag atual | 304; não conta no limite |
| AP-48 | limite 300/min | ag1 faz 301 pedidos em 60 s com dois tokens diferentes | o 301º recebe 429 com "tentar depois" em segundos; os cabeçalhos de restante chegam a 0; o pedido não é executado |
| AP-49 | — | 31 alterações em #1000 em 1 min | a 31ª recebe 429 |
| AP-50 | — | pedido vindo de localhost acima do limite | 429 (nenhum IP isento por padrão) |
| AP-51 | #1000 na versão 7 | T1 muda a prioridade sem pré-condição | 200; versão 8; o evento de auditoria registra "sem verificação de versão" (D01) |
| AP-52 | T1 leu #1000 (v7, ETag E) | ag2 cria mensagem pública (versão continua 7); T1 altera a prioridade com If-Match E | 200 (só a versão é comparada); versão 8 |
| AP-53 | T1 com ETag da v7; #1000 já na v8 | T1 cria mensagem pública com mudança para pendente, If-Match da v7 | 409; nem a mensagem nem o estado são gravados |
| AP-54 | idem | T1 cria mensagem pública **sem** mudança de estado, com If-Match da v7 | 201; a pré-condição não é avaliada; a resposta traz versão 8 |
| AP-55 | T1 com ETag E de #1000 | ag2 cria nota interna; T1 faz leitura condicional com E | 200 com a representação nova (a ETag mudou); versão continua a mesma |

### 15.5 Webhooks — assinatura e conteúdo
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| WH-01 | — | T1 (agente) cria webhook | 403 |
| WH-02 | — | TA cria webhook para um endereço de rede privada fora da lista de permissões | 422; na hora do envio, um DNS que passe a resolver para rede privada → tentativa bloqueada e registrada como SSRF |
| WH-03 | assinatura de "ticket criado" | ag1 cria ticket | 1 entrega com envelope: id do evento, tipo, versão do envelope, ocorrido em UTC, conta, ator agente ag1, recurso com versão, retrato igual à leitura pela API |
| WH-04 | assinatura de "ticket atualizado" | ag1 muda estado e prioridade numa só gravação | **um** evento com duas alterações, cada uma com antes e depois |
| WH-05 | assinatura de "ticket atualizado" | ag2 atribui #1000 a ag1 | evento com a alteração de responsável; não existe evento separado de atribuição |
| WH-06 | assinatura de "mensagem pública criada" e "ticket atualizado" | ag1 responde e muda para pendente no mesmo envio | dois eventos, um de cada tipo |
| WH-07 | assinatura **sem** "nota interna criada" | ag1 escreve nota | nenhuma entrega; nenhum evento de ticket contém o texto da nota |
| WH-08 | assinatura **com** "nota interna criada" | ag1 escreve nota | entrega com a mensagem marcada como interna |
| WH-09 | mensagem de 1 MB | evento de mensagem | envelope ≤ 256 KB; corpo truncado e marcado como truncado |
| WH-10 | — | receptor recalcula HMAC-SHA256 de "instante.corpo" com o segredo | confere; com 1 byte alterado no corpo, não confere |
| WH-11 | — | receptor recebe envio com instante de 6 min atrás | o procedimento documentado manda recusar |
| WH-12 | TA gira o segredo | próximas entregas nas 24 h | cada envio leva as duas assinaturas; após 24 h, só a nova |
| WH-13 | após WH-12 | admin escolhe "revogar o antigo agora" | o envio seguinte leva só a nova assinatura |
| WH-14 | assinatura com T1 na lista de atores ignorados | T1 altera #1000 | nenhuma entrega para essa assinatura; alterações por ag2 continuam sendo entregues |
| WH-15 | assinaturas de "mensagem pública criada" e de "nota interna criada" | chega um bounce de uma resposta de #1000 (spec 02 §7) | só "nota interna criada", marcada interna, com tipo de autor sistema; nenhum "mensagem pública criada" |
| WH-16 | assinatura de "mensagem pública criada" | um gatilho envia a confirmação automática de abertura | evento com a mensagem de sistema pública, tipo de autor sistema |
| WH-17 | assinatura com identidade dona INT | TI altera #1000; depois ag1 altera #1000 | nenhuma entrega pela mudança de TI (eco suprimido por padrão); a de ag1 é entregue |
| WH-18 | assinaturas de "mensagem pública criada" e de "nota interna criada" | o fornecedor responde a uma conversa paralela de #1000 | só "nota interna criada", marcada interna, com a indicação "conversa paralela" e o id da conversa; nenhum "mensagem pública criada" (D37) |
| WH-19 | assinatura de "SLA: aviso" | #1000 atinge o limiar de aviso | entrega com o ticket, a métrica, o prazo e o instante do aviso |
| WH-44 | assinatura de "ticket atualizado" | T1 muda o local de #1000 de B204 para B110 | um evento com a alteração de local, antes B204 e depois B110, com código e nome |
| WH-45 | assinaturas de "local atualizado" e de "ticket atualizado"; #1000 com local B204 | TA desativa B204 | um "local atualizado" com B204 inativa; nenhum "ticket atualizado" em #1000 |
| WH-46 | assinatura de "evento: aviso de montagem"; evento #1300 com montagem qui 2026-11-12 14:00 (calendário seg–sex 07:00–17:00) | o relógio chega a ter 2026-11-10 07:00 | uma entrega com o ticket, o aviso "montagem em 2 dias úteis", a montagem 2026-11-12T17:00:00.000Z e o instante 2026-11-10T10:00:00.000Z |
| WH-47 | assinaturas de "mensagem pública criada" e de "nota interna criada"; situação de AP-98 | T1 envia resposta pública em #1100 | três "mensagem pública criada" (#1100, #1101, #1102) com o mesmo identificador de operação; as dos filhos com a indicação "replicada do incidente" e o id de #1100; nenhuma "nota interna criada" |
| WH-48 | assinatura de "evento: aviso de montagem"; calendário de WH-46 | T1 cria, qua 2026-11-11 15:00, evento #1302 com montagem qui 2026-11-12 14:00 | uma entrega imediata do aviso "montagem em 2 dias úteis", com o instante 2026-11-11T18:00:00.000Z, e outra do "montagem hoje" em 2026-11-12T10:00:00.000Z; cada uma uma vez (D41) |

### 15.6 Webhooks — entrega
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| WH-20 | destino fora do ar | ag1 cria ticket | o ticket é gravado normalmente e sem atraso; a entrega fica pendente |
| WH-21 | processo da aplicação morre logo após gravar o ticket | o processo volta | o evento está na caixa de saída e é entregue |
| WH-22 | receptor de teste respondendo sempre 500 | evento ocorre | o registro do receptor mostra tentativas em ~0, 1 min, 5 min, 30 min, 2 h, 6 h, 12 h e 24 h (±10%); depois, entrega falha no log |
| WH-23 | receptor de teste com demora de 30 s | evento ocorre | a tentativa é encerrada em 10 s, registrada como timeout e retentada |
| WH-24 | destino responde 400 | evento ocorre | sem retentativa; entrega falha; conta para a desativação |
| WH-25 | receptor de teste responde 500 à 1ª tentativa (t = 0) e 429 com "tentar depois" de 600 s à 2ª (t = 1 min) | — | 3ª tentativa em t = 11 min (maior entre 5 min e 1 + 10 min; dentro do limite de 5 + 60 = 65 min); 4ª em t = 30 min, pelo calendário; total de tentativas continua 8 (sem contar a variação de ±10%) |
| WH-26 | destino responde 301 | — | o redirecionamento não é seguido; falha definitiva, sem retentativa; registrada no log e contada para a desativação |
| WH-27 | destino responde 410 | — | assinatura desativada na hora; admins notificados |
| WH-28 | destino sempre 500; 20 tentativas falhas em 1 h, último sucesso há 2 h | — | assinatura **continua ativa** (ainda não há 24 h sem sucesso) |
| WH-29 | mesma assinatura, 24 h sem sucesso e ≥ 20 falhas seguidas | próxima falha | desativada automaticamente; entregas pendentes suspensas; notificação in-app e e-mail para todos os admins; evento de auditoria com origem sistema |
| WH-30 | após WH-29 | ag1 cria ticket | nenhuma entrega para a assinatura desativada |
| WH-31 | após WH-29 | admin reativa e escolhe reenviar suspensas | as suspensas são entregues com os mesmos ids de evento; contagem de falhas zerada |
| WH-32 | destino responde 200 depois de 11 s, mas processa | retentativa | o receptor recebe o mesmo id de evento duas vezes (duplicata documentada) |
| WH-33 | duas alterações seguidas em #1000 (v8, v9); a entrega de v8 falha uma vez | — | v9 pode chegar antes de v8; os dois envelopes trazem a versão do recurso |
| WH-34 | entrega falha de 3 dias atrás | admin reenvia manualmente | nova entrega com o mesmo id de evento, id de entrega novo e marca de reenvio manual |
| WH-35 | entrega de 15 dias atrás | tentar reenviar | indisponível (fora da retenção de 14 dias); o evento ainda está no feed (30 dias) |
| WH-36 | — | admin pede envio de teste para destino quebrado | tentativa no log; não conta para a desativação |
| WH-37 | uma assinatura e 50 eventos simultâneos | — | no máximo 5 entregas em paralelo para esse destino |
| WH-38 | gatilho "estado mudou para fechado → entregar à assinatura S"; S assina só "ticket criado" | a tarefa de fechamento automático fecha #1000 | 1 entrega a S com o envelope do "ticket atualizado" do fechamento e motivo "gatilho"; o fechamento não depende da entrega |
| WH-39 | como WH-38, mas S também assina "ticket atualizado" | idem | **uma** entrega a S para esse evento |
| WH-40 | como WH-38, mas S está desativada; o mesmo gatilho também muda a prioridade | idem | o gatilho inteiro não é aplicado (prioridade não muda); erro registrado; #1000 continua fechado (D11) |
| WH-41 | receptor de teste com o segredo de S | ag1 cria ticket | o registro do receptor mostra instante, cabeçalhos, corpo e "assinatura confere" |
| WH-42 | T1 lê o feed de eventos | eventos do N1 e do Financeiro nos últimos 30 dias, um de 31 dias atrás | só os do N1 (incluindo notas internas, que ag1 pode ler); o de 31 dias não aparece |
| WH-43 | receptor de teste responde 500 à 1ª tentativa e 429 com "tentar depois" de 7.200 s à 2ª (t = 1 min) | — | 3ª tentativa em t = 65 min (limite de 1 h depois do momento de 5 min); o momento de 30 min é absorvido; seguintes em 2 h, 6 h, 12 h e 24 h; total 7 tentativas |

---

## 16. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Formato de erro, status HTTP, paginação real, total | documentação de 3 projetos; ausência nos outros | API-01 em todos |
| 403 × 404 para recurso de outro grupo | não documentado | API-01 com agent3; P-01 |
| Nota interna via API e portal | não documentado | P-03 |
| Escopos de token | parcial | P-05 |
| Payload, cabeçalhos e assinatura de webhook | documentação de 4 projetos | API-02 |
| Retry, backoff e desativação | documentado em 2 projetos (contagem) | API-03 |
| Timeout de webhook; se a entrega trava a gravação do ticket | não documentado | API-04 |
| Limite de taxa e cabeçalhos | documentado em 2 projetos | API-05 (rodar de outro IP do laboratório, porque localhost pode ser isento) |
| Referência de mercado | documentação pública de desenvolvedor do Zendesk | API-06 (concluída na pesquisa, só leitura) |
| Recursos da operação EARJ (encaminhamento, seguidores, conversa paralela, avaliação, filas, macros) | requisitos de cliente (spec 13) | nenhuma (comportamento definido por nós) |
| Locais e QR, eventos, incidente pai, macros com variantes, criar artigo, login com Google só na interface | requisitos de cliente (spec 13 Δ31–Δ38) | nenhuma (comportamento definido por nós) |

---

## 17. Questões abertas para o implementador

1. **Mensagem via API em ticket mesclado**: a spec 01 §6 redireciona e-mail e
   portal para o destino; a API recusa com 422 e aponta o destino (§4). A
   diferença é intencional (integração deve ser explícita), mas pode surpreender.
   Alternativa: redirecionar também na API, informando o destino na resposta.
2. **3xx como falha definitiva** (§13.3, WH-26): escolhido porque um
   redirecionamento quase sempre é URL errada. A alternativa é retentar, caso o
   receptor esteja em migração temporária.
3. **Retrato visto por um admin**: se no futuro houver campos visíveis só a
   alguns admins, o retrato precisará de um perfil de visão explícito por
   assinatura.
4. Limites (300/min, 30/min por ticket, 24 h de idempotência, 256 KB, 10 s, 8
   tentativas, 20 falhas + 24 h, 14 dias de log, 30 dias de feed, 100 filhos
   por pedido de vínculo) são propostas; registrar nas decisões do projeto se
   mudarem.
