# Spec 07 — Base de conhecimento e portal do cliente

Status: **rascunho v0.3 (2026-10-29)**. Baseado na documentação pública dos 7
projetos analisados. As evidências de runtime ainda estão pendentes; cada ponto
que depende delas está marcado como **[evidência pendente: cenário]**.
Vocabulário: spec 01. E-mail: spec 02. Canais e formulário: spec 03. Busca:
spec 08. Permissões: spec 06. Decisões transversais: spec 00-decisoes (D01–D53).
Requisitos da operação EARJ: spec 13, que prevalece sobre esta.

Mudanças na v0.3:
- **Entrada com Google** do domínio da escola passa a ser a principal; o link
  por e-mail fica como alternativa para quem não tem conta da escola; a senha
  opcional passa a vir **desligada** por padrão (spec 13 Δ31) (§7.1, §7.2).
  Substitui a decisão da v0.2 de link mágico como base.
- Os parâmetros da página de entrada (por exemplo, a sala do QR)
  **sobrevivem ao login**, por Google ou por link (Δ31) (§7.1).
- **Domínio próprio** do portal em todos os links enviados (na EARJ,
  help.earj.com.br) (Δ32) (§7.8).
- **QR da sala** com local preenchido e travado e a opção "não estou nesta
  sala"; **"minha sala"** no perfil; campo de local no formulário (Δ33) (§7.5,
  §8.2, §8.8).
- **Formulário de evento** separado do de suporte, com antecedência mínima e
  marca "fora do prazo" (Δ34) (§8.9).
- **Incidente pai**: a resposta do pai chega ao solicitante de cada filho como
  mensagem do próprio ticket; filhos não recebem convite de pesquisa (Δ35)
  (§8.3, §8.7).
- **"Criar artigo"** a partir de ticket resolvido e sugestão desses artigos no
  formulário, também pelos campos de classificação (Δ38) (§3.5, §6.2).
- Envio sem login permitido na EARJ (spec 13 §6); questões abertas 1 e 4
  retiradas (a credencial de demonstração passa a ser o login de
  desenvolvimento do 00-produto).
- Novos casos KB-144 a KB-170.
- **Ajustes D40–D53**: "Criar artigo" com leitura no ticket (inclusive o
  agente de apoio), título do **assunto** e texto da **resposta pública
  final**; ticket não resolvido → erro de validação; a outra língua é um
  **rascunho de tradução do mesmo artigo**, nunca um artigo separado (D42,
  §3.5; KB-165 ajustado). Agentes e admins só entram com Google; fora do modo
  de desenvolvimento não há login local (D53, §7.1). Os campos personalizados
  "Unidade" e "Setor/sala" saem dos exemplos: o local vem só do cadastro de
  locais, e o exemplo de campo condicional passa a ser motivo → equipamento →
  sintoma (D51, §8.2; KB-100 a KB-105 reescritos). Formulário de evento com o
  termo "tipo de evento" (D53, §8.9). KB-59 com a senha opcional ligada
  explícita. Novos casos KB-171 a KB-173.

Mudanças na v0.2:
- Formulário do portal como canal principal, com formulários definidos pelo
  admin e campos condicionais (spec 13 Δ1, Δ2) (§8.2).
- Estado **em espera** no portal: aparece como "em andamento" e o termo nunca
  é mostrado ao solicitante (D18, Δ3) (§8.3, §8.4).
- Ação **"meu problema foi resolvido"** no MVP, só para o solicitante (D08)
  (§8.6); sai a questão aberta correspondente.
- **Pesquisa de satisfação** no portal e por link no e-mail (D19, Δ15) (§8.7).
- Tickets da organização com três valores, **desligado / só gestores / todos
  os membros**, e a marca "gestor da organização" na Pessoa (D07) (§8.1).
- Publicar, despublicar, arquivar e mudar visibilidade passam a ser **só do
  admin**, como na spec 06; sai a marca "pode publicar na base" (§3.4).
- Artigos com **traduções** PT/EN e interface do portal nos dois idiomas
  (Δ23) (§2.5, §7.6); sai do roadmap.
- **Marca da conta** no portal com contraste verificado (Δ25) (§7.7).
- Vocabulário de acesso (visitante, solicitante logado, convidado) e o
  **link de acompanhamento** de 7 dias da confirmação (spec 03 §4.6) (§7.0,
  §7.4).
- Agente ou admin solicitante entra no portal com a própria sessão (spec 06 §2)
  (§7.1).
- Uma única confirmação de recebimento por pedido do portal; campos e anexos do
  pedido seguem a spec 03 (§8.2).
- Números de ticket dos casos de teste trocados para a faixa #17xx (seed único).
- Questões abertas respondidas foram retiradas.
- Ajustes D23–D37: publicar, arquivar e excluir artigo são só do admin;
  agentes criam e editam rascunhos, sem a marca "pode publicar" (D30, §3.4).
  A confirmação de abertura é o gatilho de criação da spec 05 §6, mecanismo
  único para portal, formulário de visitante, e-mail e chat; leva o **link de
  convidado**, e o link de acompanhamento de 7 dias sai (§7.4 removido em
  v0.2); para endereço não verificado, sem eco do texto digitado e no máximo 3
  por endereço a cada 24 h (D25, §7.3, §8.2). "Meu problema foi resolvido" não
  exige responsável nem campos obrigatórios para resolver e grava a marca
  "resolvido pelo solicitante" (D33, §8.6; questão aberta retirada). Ticket
  encaminhado com retorno fica aberto e aparece como "em andamento" (D23,
  §8.3). KB-63 e KB-64 removidos; KB-73, KB-92 e KB-115 atualizados; novos
  casos KB-137 a KB-143.

---

## 1. Problema

O solicitante precisa de um lugar próprio, fora do e-mail, para duas coisas:
achar a resposta sozinho e, quando não achar, pedir e acompanhar ajuda. Na
EARJ, esse lugar é o **canal principal**: 80% dos pedidos chegam pelo
formulário do portal (spec 13 §1). Do lado da equipe, o mesmo conteúdo precisa
servir de referência interna sem vazar. A spec precisa responder sem
ambiguidade:

1. como o conteúdo da base de conhecimento (KB) é organizado e quantos níveis de
   hierarquia existem;
2. em que estado um artigo está, quem o vê em cada estado e o que acontece com o
   endereço (URL) quando ele é renomeado, movido ou arquivado;
3. quem vê cada artigo (visitante anônimo, solicitante logado, agente) e como
   garantir que conteúdo interno **nunca** seja servido a quem não pode vê-lo,
   inclusive em busca, sugestões, trechos e imagens;
4. como o solicitante se autentica no portal, como a conta dele nasce e como
   isso convive com as pessoas criadas automaticamente pelo e-mail (spec 02 §5);
5. quais tickets o solicitante vê (os seus, aqueles em que participa, os da
   organização) e o que ele vê dentro de cada ticket;
6. como criar e responder pelo portal sem criar um segundo caminho de regras:
   o portal é só mais um canal, sujeito ao mesmo ciclo de vida (spec 01 §4);
7. como evitar tickets desnecessários sugerindo artigos (deflexão);
8. como o solicitante declara o pedido resolvido e avalia o atendimento.

---

## 2. Base de conhecimento: estrutura

### 2.1 Entidades (conceitual)

| Termo | Definição |
|---|---|
| **Base de conhecimento** | Uma por conta no MVP. Tem um idioma padrão (o da conta), a lista de idiomas aceitos (no MVP: português e inglês) e uma chave "acessível sem login" (padrão: ligada). |
| **Categoria** | Agrupa artigos. Tem nome (por idioma), descrição curta, slug, posição de ordenação e um **teto de visibilidade** (§2.3). Categorias são planas no MVP: não há subcategoria. |
| **Artigo** | Unidade de conteúdo. Pertence a exatamente uma categoria. Tem identificador, categoria, posição dentro da categoria, **visibilidade** (§2.3), autor e uma ou mais **traduções** (§2.5). |
| **Tradução** | Versão do artigo num idioma. Tem título, resumo (opcional), corpo em texto rico, slug, **estado** (§3) e uma lista de **revisões** (§4). |
| **Revisão** | Cópia imutável de título, resumo e corpo de uma tradução num momento de publicação. |
| **Imagem/anexo de artigo** | Arquivo ligado ao artigo. Herda a visibilidade do artigo, sempre (§2.4). |

Decisão sobre hierarquia: **categoria → artigo, dois níveis, sem seções nem
subcategorias no MVP.** Os projetos vão de categoria plana até três níveis
(pasta → categoria → artigo) ou vários portais por marca. Cada nível a mais
exige regras de herança de visibilidade, de mover em cascata e de exclusão de
nível vazio, e uma KB de MVP raramente passa de algumas dezenas de artigos (a
da EARJ começa vazia, com temas como impressora, projetor, som, Wi-Fi/VPN,
notebooks e contas Google). Subcategorias ficam no roadmap; o teto de
visibilidade por categoria (§2.3) já foi desenhado para ser herdado por um
nível filho no futuro (o filho só pode restringir mais, nunca afrouxar).

### 2.2 Regras de categoria

- Existe sempre a categoria **Geral**, criada com a conta, que não pode ser
  excluída. O nome dela pode ser mudado.
- Só se exclui categoria **vazia**. Para excluir uma categoria com artigos, o
  admin escolhe uma categoria de destino; todos os artigos são movidos para ela
  (aplicando §2.3) e depois a categoria é excluída, numa única operação.
- Uma categoria aparece para um leitor somente se o teto dela permite esse
  leitor **e** ela contém ao menos um artigo publicado visível para ele.
  Categoria sem nada visível não aparece nem como título vazio.
- A ordem das categorias e dos artigos dentro de cada categoria é manual
  (posição). Empate de posição: ordem alfabética do título no idioma exibido.
- Nome de categoria sem tradução no idioma do leitor: usa o nome no idioma
  padrão.

### 2.3 Visibilidade

Três níveis, do mais amplo ao mais restrito:

| Nível | Quem vê o artigo publicado |
|---|---|
| **público** | qualquer pessoa, inclusive visitante anônimo (se a KB estiver "acessível sem login") |
| **clientes logados** | qualquer solicitante autenticado no portal da conta, mais agentes e admin |
| **interno** | somente agentes e admin, e somente na área de atendimento |

Regras:
- A visibilidade é **por artigo** (vale para todas as traduções dele). A
  categoria tem um **teto**: o nível mais amplo que os artigos dela podem ter.
  Padrão do teto: público.
- **Invariante**: a visibilidade de um artigo nunca é mais ampla que o teto da
  sua categoria. O servidor recusa qualquer gravação que quebre o invariante.
- **Mover um artigo nunca amplia a audiência dele.** Ao mover para uma
  categoria com teto mais restrito que o artigo, a visibilidade do artigo
  **baixa** para o teto. Ao mover para uma categoria com teto mais amplo, a
  visibilidade do artigo **não muda**. Ampliar depois exige uma edição explícita
  da visibilidade do artigo.
- **Restringir o teto** de uma categoria baixa, na mesma operação, a
  visibilidade de todos os artigos dela que estavam acima do novo teto (um
  evento de auditoria por artigo alterado).
- **Ampliar o teto** de uma categoria **não** amplia nenhum artigo. O admin
  amplia artigo por artigo (ou seleciona vários e amplia em lote, o que é uma
  ação explícita sobre aqueles artigos).
- Tentar dar a um artigo visibilidade mais ampla que o teto da categoria:
  erro de validação indicando o teto; nada é gravado.
- Se a chave "acessível sem login" estiver desligada, o visitante anônimo não
  vê nenhum artigo; artigos públicos passam a exigir login, como os de clientes
  logados. A visibilidade gravada dos artigos não muda.
- Audiência por organização (artigo só para a Acme) fica no roadmap.

Por que por artigo com teto na categoria: um dos projetos define acesso só por
artigo e documenta a regra de que mover nunca amplia; outros definem acesso por
categoria. Só por categoria impede ter um artigo interno ao lado dos públicos;
só por artigo não deixa o admin criar uma área inteira de procedimentos
internos com garantia. O teto junta as duas vantagens e torna a regra "mover
nunca amplia" verificável.

### 2.4 Conteúdo interno nunca sai por rota pública

- Um artigo **interno** nunca é servido pelo portal, pela busca do portal,
  pelas sugestões de deflexão, pelo widget de chat (spec 03), por feed, nem
  pela API com credencial de solicitante ou sem credencial. Para esses
  consumidores, ele **não existe**: a resposta é "não encontrado", igual à de
  um artigo inexistente.
- Um artigo de **clientes logados** acessado por visitante anônimo leva à tela
  de login sem mostrar título nem trecho. Depois do login, se o artigo for
  visível, ele abre; se não for (ex.: virou interno), "não encontrado".
- Imagens e anexos de artigo seguem a visibilidade **efetiva** do artigo no
  momento do pedido (não no momento do upload). O endereço de um arquivo nunca
  permite acesso sozinho: cada download confere a visibilidade do artigo dono.
- Trechos de busca, resumos e títulos exibidos ao solicitante vêm **somente da
  revisão publicada** da tradução exibida, nunca de um rascunho em edição.
- Um dos projetos alerta que a permissão de leitura da sua KB expõe conteúdo
  interno; o PantherDesk não tem nenhuma permissão de leitura de KB além das
  três acima, justamente para não haver combinação que abra o interno.

### 2.5 Traduções (MVP, spec 13 Δ23)

- Um artigo em português e em inglês é **um artigo com duas traduções**, não
  dois artigos. Identificador, categoria, posição e visibilidade são do artigo;
  título, resumo, corpo, slug, estado e revisões são de cada tradução.
- A tradução no **idioma padrão da conta** é a base. Uma tradução em outro
  idioma só pode ser publicada se a base estiver publicada. Despublicar ou
  arquivar a base despublica ou arquiva, na mesma operação, todas as traduções
  (um evento de auditoria por tradução alterada).
- Idioma de exibição: o idioma do leitor (§7.6). Se o artigo não tiver tradução
  **publicada** nesse idioma, o portal mostra a base, com a indicação do idioma
  em que ela está. Nunca se mostra rascunho de tradução.
- Na lista de uma categoria, na busca e nas sugestões, cada artigo aparece
  **uma vez**, na tradução de exibição.
- A comparação de que uma tradução está desatualizada em relação à base (aviso
  "a base mudou depois desta tradução") fica no roadmap.

---

## 3. Ciclo de vida do artigo

### 3.1 Estados

O estado é de cada tradução (§2.5). Ao longo desta seção, "artigo" quer dizer
"tradução do artigo" quando o assunto é estado ou revisão.

| Estado | Significado | Quem vê |
|---|---|---|
| **rascunho** | Nunca publicado, ou despublicado. | agentes e admin, na área de atendimento |
| **publicado** | Disponível para a audiência da visibilidade. | conforme §2.3 |
| **arquivado** | Retirado de circulação, preservado. | agentes e admin, com aviso "arquivado" |

### 3.2 Transições

| de \ para | rascunho | publicado | arquivado |
|---|---|---|---|
| **rascunho** | — | publicar | arquivar |
| **publicado** | despublicar | — | arquivar |
| **arquivado** | ✗ | republicar | — |

- Toda transição gera **evento de auditoria** (ator, momento, antes, depois),
  como na spec 01 §7. A data da primeira publicação, da última publicação e do
  arquivamento ficam gravadas na tradução.
- **Republicar** um arquivado o devolve exatamente à última revisão publicada,
  com a visibilidade que o artigo tinha (sujeita ao teto atual da categoria,
  §2.3).
- **Exclusão definitiva** só existe para artigo que **nunca** foi publicado em
  nenhum idioma. Artigo que já foi publicado só pode ser arquivado: links para
  ele podem estar em tickets, e-mails enviados e sites externos.
- Agendamento de publicação fica no roadmap.

### 3.3 Arquivado, por fora

- Para quem tinha permissão de ver o artigo quando publicado, o endereço de um
  artigo arquivado responde com a página "este artigo não está mais
  disponível" e um link para a KB (não um erro genérico). Para os demais,
  "não encontrado".
- Artigo arquivado sai da busca do portal, das sugestões e das listas de
  categoria **imediatamente** (spec 08 §6).
- Na área de atendimento, a busca de KB não mostra arquivados por padrão; um
  filtro os inclui.

### 3.4 Quem edita

Alinhado à D30 e à spec 06 (§4, linhas da base de conhecimento, e §10,
publicação entre as configurações exclusivas de admin):

- **Admin**: tudo (categorias, tetos, publicar, despublicar, arquivar,
  republicar, visibilidade, excluir artigo nunca publicado).
- **Agente** (qualquer agente ativo, seja qual for o acesso dele por grupo):
  cria artigos e traduções em rascunho, edita rascunhos e a edição em andamento
  de um artigo publicado (§4), e restaura revisões como edição em andamento.
  **Não** publica, não despublica, não arquiva, não exclui, não muda
  visibilidade nem categoria. Quando a edição dele está pronta, um admin a
  publica. Não existe no MVP marca que dê a um agente o poder de publicar
  (D30).
- **Solicitante**: nunca edita.
- Pela API, as mesmas regras valem com o escopo correspondente (spec 10).
- Ao criar um artigo (inclusive pelo §3.5), o agente escolhe a categoria; a
  visibilidade inicial é o teto dela. Mudar categoria ou visibilidade depois
  continua sendo só do admin.

### 3.5 "Criar artigo" a partir de um ticket resolvido (spec 13 Δ38)

A base da EARJ começa vazia; o jeito mais barato de enchê-la é aproveitar
respostas que já resolveram problemas.
- Disponível num ticket **resolvido** ou **fechado** (fechado é um resolvido
  cujo prazo passou) que tenha pelo menos uma **mensagem pública de agente**
  na conversa principal. Em outro estado, ou sem resposta de agente (por
  exemplo, resolvido só pela ação do solicitante, §8.6), a ação não aparece e
  o servidor a recusa (erro de validação, D42). Quem pode usar: spec 06 §4
  (basta **ler** o ticket, inclusive o agente de apoio; D42).
- Cria um **artigo novo em rascunho**, com uma tradução no idioma escolhido
  pelo agente (PT ou EN):
  - título: o assunto do ticket, editável;
  - corpo: a **resposta pública final**, isto é, a última mensagem pública de
    agente da conversa principal.
    Notas internas, conversas paralelas, mensagens do solicitante e anexos
    nunca são copiados;
  - **sem dados do solicitante**: o sistema retira do texto o nome, o primeiro
    nome, os endereços de e-mail e os telefones do solicitante e dos
    participantes, a linha de saudação e a assinatura do agente, e marca os
    pontos retirados para o agente conferir. O agente revisa antes de salvar;
    a retirada automática é uma ajuda, não uma garantia.
- O agente escolhe a categoria (a visibilidade inicial é o teto dela, §3.4) e
  o idioma. Se o idioma escolhido não for o padrão da conta, a tradução base é
  criada vazia, em rascunho, porque a regra do §2.5 continua valendo.
- **Outra língua** (D42): o agente pode pedir o outro idioma (PT/EN). Ele é
  criado como **rascunho de tradução do mesmo artigo** (§2.5), com o mesmo
  título e texto de partida para ele traduzir; nunca como um artigo separado.
  Se a tradução nesse idioma já existe, a interface abre a existente.
  Tradução automática fica no roadmap.
- O rascunho registra o **ticket de origem** e os valores dos campos de
  classificação do ticket (na EARJ, motivo, equipamento e sintoma) como
  **temas** do artigo, editáveis pelo admin. A referência ao ticket aparece só
  para quem pode ler o ticket (spec 06 §4) e nunca no portal.
- Se já existe um rascunho criado a partir do mesmo ticket, a interface avisa e
  oferece abri-lo; criar outro continua permitido.
- Só o admin publica (D30). Depois de publicado, o artigo é um artigo comum e
  entra na busca e nas sugestões (§6.2).

---

## 4. Revisões (MVP)

Decisão: **revisões entram no MVP**, na forma mais simples.

- Uma tradução publicada tem uma **revisão atual** (a que o público vê) e pode
  ter uma **edição em andamento** (rascunho de alteração), visível só na área
  de atendimento. Salvar uma edição em andamento **não** altera o que o
  público vê.
- **Publicar** a edição em andamento cria uma nova revisão imutável, que passa
  a ser a atual. Cada revisão guarda autor e momento.
- **Restaurar** uma revisão antiga cria uma **nova edição em andamento** com o
  conteúdo dela; nada é reescrito no histórico. Para valer, é preciso publicar.
- Só pode existir uma edição em andamento por tradução. Se dois agentes editam
  ao mesmo tempo, quem salvar por último a partir de uma versão desatualizada
  recebe erro de conflito e precisa recarregar (nada é sobrescrito em silêncio).
- Comparação visual entre revisões (diff) fica no roadmap.
- Mudanças de categoria, visibilidade e posição **não** criam revisão; geram
  evento de auditoria.

Por quê: dos sete projetos, só um documenta revisões com restauração; os
outros, ao que tudo indica, editam o conteúdo publicado no lugar. Editar o
publicado direto expõe texto pela metade e perde conteúdo sem volta. Guardar a
revisão a cada publicação é barato e resolve os dois problemas
**[evidência pendente: K-01]**.

---

## 5. Endereços (slugs) estáveis

- Cada categoria e cada artigo têm um **identificador numérico estável**,
  atribuído na criação e nunca reutilizado, e um **slug** legível por tradução.
- O slug é gerado a partir do título: minúsculas, sem acentos, palavras
  separadas por hífen, sem pontuação, no máximo 80 caracteres. Ex.: o título
  "Configuração do acesso à VPN" gera o slug "configuracao-do-acesso-a-vpn".
- O endereço público de um artigo contém o idioma, o identificador **e** o
  slug. O servidor resolve o artigo **pelo identificador**. Se o slug do pedido
  não for o slug atual da tradução pedida, a resposta é um redirecionamento
  permanente para o endereço canônico. Endereço sem idioma usa o idioma do
  leitor (§7.6). Endereço com um idioma sem tradução publicada mostra a base
  (§2.5).
- Renomear o artigo **não** muda o slug automaticamente; o editor pode
  regenerá-lo ou editá-lo de forma explícita. Mesmo quando muda, os endereços
  antigos continuam funcionando pelo redirecionamento acima.
- A categoria **não** faz parte do endereço do artigo. Mover o artigo de
  categoria não muda o endereço dele.
- Slug não precisa ser único (o identificador garante a unicidade), mas o
  editor é avisado quando já existe outro artigo publicado com o mesmo slug.
- Todo endereço de artigo também passa pela checagem de visibilidade (§2.4):
  um endereço antigo nunca dá acesso a algo que o endereço atual não daria.

---

## 6. Busca na KB e deflexão

### 6.1 Busca

- Usa o mesmo motor e as mesmas regras de normalização da spec 08: sem
  diferença de acento nem de maiúsculas ("conexao" acha "Conexão"), radical no
  idioma da tradução ("impressoras" acha "impressora"; "printers" acha
  "printer").
- Campos pesquisados, em ordem de peso: título, resumo, corpo. O nome da
  categoria entra com o peso mais baixo.
- Só entram artigos **publicados** cuja visibilidade efetiva inclui o leitor
  (§2.3). Para o solicitante e o visitante, a busca considera só a revisão
  atual da **tradução de exibição** (§2.5); o texto de uma edição em andamento
  nunca é encontrado nem aparece em trecho.
- Ordenação: relevância; empate desempatado pela última publicação mais
  recente.
- Resultado: título, categoria, trecho com os termos destacados. Até 20 por
  página.
- Na área de atendimento, inclusive no painel de contexto da tela do ticket
  (spec 13 Δ18, spec 08 §9.6), o agente busca na KB inteira (todos os níveis,
  todos os idiomas e, com filtro, rascunhos e arquivados) e pode **inserir o
  link** de um artigo na resposta que está escrevendo. Artigo **interno** pode
  ser lido pelo agente, mas o link dele **nunca** entra numa resposta
  **pública**: a interface avisa e o servidor recusa o envio enquanto o link
  estiver lá. Link de artigo "clientes logados" é permitido: o solicitante
  passará pelo login. O link inserido aponta para a tradução no idioma do
  solicitante, se houver, ou para a base.

### 6.2 Deflexão (MVP)

Decisão: **entra no MVP**, porque reaproveita a busca acima sem custo novo.

- No formulário de novo pedido do portal (§8.2), enquanto o solicitante digita
  o assunto, o portal mostra até **5** artigos sugeridos. A busca dispara a
  partir de 4 caracteres e depois de uma pausa curta de digitação; trocar o
  assunto atualiza a lista.
- As sugestões obedecem às mesmas regras de visibilidade e de idioma da busca
  do portal para aquele leitor (solicitante logado ou visitante).
- Abrir uma sugestão não apaga o formulário: o artigo abre sem perder o que já
  foi digitado (incluindo os campos condicionais já preenchidos).
- **Pelos temas** (§3.5, Δ38): quando o solicitante escolhe no formulário
  valores de classificação que coincidem com os temas de um artigo publicado
  (por exemplo, equipamento = impressora e sintoma = não imprime), o artigo é
  sugerido mesmo antes de ele digitar o assunto. Artigos que casam pelos temas
  e pelo assunto vêm primeiro; o total continua limitado a 5, e cada artigo
  aparece uma vez.
- Sem resultado, nada é mostrado (nem mensagem de "nenhum artigo").
- O sistema registra, por formulário, quais artigos foram sugeridos, quais
  foram abertos e se o pedido acabou enviado. Esses registros alimentam
  métricas futuras (spec 11). Nenhuma métrica é exibida no MVP.
- Voto "útil / não útil" e contagem de visualizações ficam no roadmap.

Comparação: um projeto sugere artigos ao digitar o assunto; outro mostra
artigos populares antes de o visitante iniciar a conversa; os demais não
documentam nada **[evidência pendente: K-04]**.

---

## 7. Portal: identidade e acesso

### 7.0 Quem acessa o portal (vocabulário)

| Termo | Definição |
|---|---|
| **Visitante** | Quem acessa o portal sem sessão e sem link de acesso. Pode ler artigos públicos (se a KB estiver acessível sem login) e, se a conta permitir, enviar o formulário como visitante (§8.2, spec 03 §4). Não vê ticket nenhum. É o mesmo termo usado para quem fala pelo widget de chat sem estar logado (spec 03). |
| **Solicitante logado** | Pessoa com sessão do portal (§7.1). Vê os tickets do §8.1. |
| **Convidado** | Quem abre um ticket pelo link de acesso de um destinatário (§7.3). Age como aquela pessoa, só naquele ticket. |

A matriz de permissões da spec 06 §4 cobre solicitante logado e convidado nas
colunas de solicitante (o convidado com o escopo de um único ticket); o
visitante só tem as linhas de leitura de KB publicada e de criação de ticket.

### 7.1 Autenticação do solicitante

Opções consideradas:

| Opção | Prós | Contras |
|---|---|---|
| Só senha | conhecida; funciona sem acesso ao e-mail no momento | exige fluxo de recuperação, política de senha, bloqueio por tentativas; o solicitante esquece a senha porque usa o portal raramente |
| Só link mágico | nenhuma senha para guardar ou vazar; prova a posse do e-mail, que é a identidade real do solicitante (spec 02 §5) | depende do e-mail chegar; atrapalha quem acessa sempre; dificulta credenciais de demonstração |
| Link mágico + senha opcional | o link continua sendo a base e a recuperação; quem quiser define senha | mais uma tela e regras de força de senha |
| Google do domínio da escola + link para os demais | funcionários e professores já têm a conta da escola; nada novo para lembrar; o endereço é provado pelo Google | depende de um provedor externo; não serve para pais e visitantes |

Decisão (revista em v0.3, spec 13 Δ31): **a entrada principal é o Google do
domínio da escola; o link mágico por e-mail é a alternativa para quem não tem
conta da escola** (pais, visitantes, fornecedores). A senha continua existindo
como opção da conta, mas fica **desligada por padrão** (e desligada na EARJ).
Esta seção é a referência das regras de link e de senha do portal (o provedor
de autenticação local da spec 12 aponta para cá).

**Tela de entrada.** Mostra primeiro "entrar com Google" e, abaixo, "não tem
conta da escola? receba um link por e-mail". Com o envio sem login permitido
(§8.2), mostra também "continuar sem entrar" quando a pessoa veio de um
formulário.

**Entrada com Google** (regras de papel e de criação de Pessoa: spec 06 §2.1):
- Só contas Google do **domínio da escola** configurado na conta. Conta de
  outro domínio é recusada, e a tela oferece o link por e-mail.
- O endereço da conta Google identifica a Pessoa. Se ela já existe (criada
  pelo e-mail, pelo formulário, pelo chat, por um agente ou pela API), é a
  mesma Pessoa; nunca se cria uma segunda. Se não existe, é criada como
  solicitante. Em ambos os casos o endereço passa a **verificado**.
- Agente ou admin que entra pelo Google no portal tem a sessão dele, tratada
  como abaixo ("agente ou admin como solicitante").
- Endereço do domínio da escola **não recebe link mágico**: quem tem conta da
  escola entra pelo Google. Ao pedir o link com um endereço desse domínio, a
  tela orienta a usar o Google, sem dizer se a pessoa existe (o domínio é
  público, então isso não revela nada).

**Parâmetros sobrevivem ao login** (Δ31):
- Quem chega a uma página que exige entrada (por exemplo, o QR da sala, §8.8,
  ou o endereço de um artigo para clientes logados) é levado à tela de entrada
  com o **destino** guardado. Depois de entrar, por Google ou por link, a
  pessoa volta exatamente àquela página, com os mesmos parâmetros (sala,
  formulário escolhido, campos pré-preenchidos).
- No link por e-mail, o destino vai dentro do próprio link, para funcionar
  mesmo que ele seja aberto em outro navegador ou aparelho.
- O destino só pode ser uma página do próprio portal ou da área do agente da
  mesma conta. Qualquer outro destino (outro site, outro domínio) é ignorado,
  e a pessoa vai para a página inicial do portal.
- O que foi digitado no formulário antes de a pessoa sair para entrar é
  guardado no navegador e restaurado na volta, quando possível; os parâmetros
  do endereço são restaurados sempre.

**Link mágico** (para quem não tem conta da escola):

- **Pedir link**: o solicitante informa o e-mail. A resposta da tela é sempre a
  mesma ("se houver uma conta para este endereço, enviamos um link"), exista ou
  não a pessoa, para não revelar quem é cliente.
- O link é de **uso único**, vale **30 minutos** e fica inválido assim que
  outro link mágico é pedido para o mesmo endereço. Usar o link abre uma sessão
  e torna o endereço **verificado** (spec 01 §2).
- O link só é enviado se o endereço pertencer a uma **Pessoa** que não seja
  agente nem admin e não for do domínio da escola. Agentes e admin entram
  somente com Google (spec 06 §2.1); o link por e-mail nunca é porta de
  entrada para eles.
- **Agente ou admin como solicitante** (spec 06 §2): uma sessão válida da área
  de atendimento também vale no portal. Ali, o agente é tratado como
  solicitante comum: vê só os tickets de que é solicitante ou participante,
  sem notas internas nem campos de agente, mesmo que na área de atendimento
  ele tenha acesso a esses tickets. Para ver o resto, ele usa a área de
  atendimento.
- Limite: no máximo 5 pedidos de link por endereço por hora e 20 por IP por
  hora. Acima disso, a resposta da tela é a mesma, e nada é enviado.
- **Senha** (só quando a conta a ligar; padrão desligada; nunca para agentes,
  admins ou endereços do domínio da escola): só pode ser definida **depois** de
  um login por link (assim a posse do e-mail é provada primeiro). "Esqueci a senha" é simplesmente pedir
  um link. Mínimo de 10 caracteres. Depois de 10 tentativas erradas em 15 min,
  a senha daquele endereço fica bloqueada por 15 min; o link continua
  funcionando.
- Com a senha desligada pela conta, senhas já definidas deixam de ser aceitas
  (não são apagadas, para o caso de religar).
- Sessão do portal (aberta por Google ou por link): expira após 14 dias sem
  uso. O solicitante pode encerrar todas as sessões dele.
- Desativar a pessoa (spec 06) encerra as sessões, impede a entrada pelo
  Google e invalida todos os links dela (mágico, de convidado e de avaliação).
- O Google é o primeiro provedor do adaptador de autenticação da spec 12;
  outros provedores (SSO de outras escolas) ficam no roadmap.
- No ambiente local, o **login de desenvolvimento** do 00-produto substitui a
  entrada com Google enquanto o provedor não está configurado; ele não existe
  fora do modo de desenvolvimento (spec 06 §2.1). Fora desse modo, agentes e
  admins **só** entram com Google, e uma instalação sem o Google configurado
  não é suportada no MVP (D53). O link por e-mail e a senha do portal são só
  de solicitantes sem conta da escola.

Comparação: um projeto usa só link por e-mail com validade de uma hora; os
outros usam senha, às vezes com convite por e-mail para definir a senha
**[evidência pendente: K-03]**. A entrada com Google vem do requisito da
operação (spec 13 Δ31), não da comparação.

### 7.2 Criação de conta

- A Pessoa pode já existir: criada pelo e-mail (spec 02 §5), pelo formulário
  (spec 03 §4.5), pelo chat (spec 03), por um agente ou pela API. Nesse caso,
  pedir link no portal **usa a pessoa existente**; nunca se cria uma segunda
  pessoa para o mesmo endereço.
- **Auto-cadastro** (padrão: ligado, configurável por conta): quem não existe
  informa nome e e-mail; o sistema envia um link de confirmação; a Pessoa só é
  **criada quando o link é usado**. Pedidos de cadastro nunca confirmados não
  deixam rastro de pessoa.
- **Entrada com Google** do domínio da escola cria a Pessoa (solicitante) no
  primeiro login, **sem** depender do auto-cadastro: o domínio já prova que é
  alguém da escola (spec 06 §2.1). O auto-cadastro governa só quem chega pelo
  link por e-mail.
- Com o auto-cadastro desligado, quem não existe não consegue entrar pelo
  link por e-mail. Isso
  **não** impede que o e-mail crie pessoas: a criação pelo e-mail é governada
  pela caixa (spec 02 §5, "aceitar desconhecidos"). Quem foi criado pelo e-mail
  consegue entrar no portal por link mesmo com o auto-cadastro desligado.
- Organização: o portal não associa a pessoa a uma organização por conta
  própria (associação automática por domínio fica fora do MVP; spec 06 §5.2).
- **Endereço inválido**: como a spec 02 §7 prevê, o link mágico é enviado
  mesmo assim, porque o próprio solicitante pediu. Se ele usar o link, a
  entrega está provada e o endereço volta a ser válido, com evento de
  auditoria.

### 7.3 Acesso de convidado a um único ticket (link assinado)

Decisão: **existe no MVP.**

- Toda resposta pública enviada por e-mail (spec 02 §9) ao solicitante e a
  cada participante leva um link "ver este pedido no portal", **próprio de
  cada destinatário**. A confirmação de abertura (gatilho da spec 05 §6, D25)
  leva o link de convidado do solicitante.
- O link carrega um token opaco, aleatório, ligado a (ticket, pessoa). Ele não
  contém número do ticket nem e-mail.
- O link abre **somente aquele ticket**, sem login, como aquela pessoa, por
  **30 dias** a partir do envio do e-mail. O convidado pode ler e responder;
  não vê lista de tickets, não vê outros tickets, não edita perfil, não define
  senha. Se a pessoa dona do link for o solicitante, o convidado também pode
  usar "meu problema foi resolvido" (§8.6) e avaliar (§8.7).
- O convidado vê o ticket exatamente como a pessoa dona do link veria (§8.3).
  A resposta enviada por ali entra como mensagem pública daquela pessoa, canal
  portal.
- O link deixa de valer quando: expira; a pessoa sai do ticket (deixa de ser
  solicitante ou participante); a pessoa é desativada; ou um agente usa
  "invalidar links de acesso" no ticket.
- Se o ticket foi **mesclado**, o link leva ao ticket de destino (spec 01 §6),
  desde que a pessoa tenha acesso a ele (pela regra de mescla, o solicitante da
  origem vira participante do destino, então em geral tem).
- O link oferece "entrar no portal" para ver os outros pedidos; isso leva à
  tela de entrada normal (§7.1): Google para quem tem conta da escola, link
  por e-mail para os demais.
- Usar o link de convidado **verifica** o endereço da pessoa dona do link,
  porque prova que o e-mail chegou a ele (spec 03 §4.5). Ele não abre sessão
  do portal: o convidado continua restrito àquele ticket.

Por quê: um projeto oferece acesso por e-mail + número do ticket, que dá acesso
a um único pedido. Funciona, mas pedir o número é atrito, e o número é
adivinhável. O link assinado dá o mesmo escopo sem atrito e sem nada
adivinhável. O risco é o e-mail encaminhado: quem recebe o encaminhamento
consegue responder como o solicitante. Esse risco já existe no próprio e-mail
(qualquer um pode responder à thread), por isso foi aceito, com a validade de
30 dias e a invalidação manual como mitigação.

### 7.4 Link de acompanhamento — removido em v0.2

Removido pela D25: a confirmação de abertura é o gatilho de criação da spec 05
§6 e leva o **link de convidado** (§7.3). Não há mais um link próprio de 7
dias. Quem quiser ver os outros pedidos entra pela tela de entrada (§7.1).

Resumo dos links do portal:

| Link | Validade | Uso | Escopo | Verifica o endereço |
|---|---|---|---|---|
| mágico (§7.1) | 30 min; o último pedido invalida os anteriores | único | sessão completa | sim |
| convidado (§7.3) | 30 dias | vários | um ticket, como aquela pessoa | sim |
| avaliação (§8.7) | até o ticket fechar | vários | avaliar aquela resolução | não |

A entrada com Google (§7.1) não é um link enviado: abre a mesma sessão
completa do link mágico e também verifica o endereço. Todos os links da tabela
usam o domínio próprio da conta (§7.8).

### 7.5 Pessoas e seus dados no portal

- O solicitante vê e edita no portal o próprio nome, o idioma e o fuso. Os
  endereços são geridos pela equipe (spec 06).
- Campos personalizados de Pessoa (spec 13 Δ22) não aparecem no portal no
  MVP; eles são de uso da equipe (painel de contexto, filas, regras).
- **Minha sala** (Δ33): a pessoa salva no perfil, em ordem, as salas onde
  trabalha (só salas ativas do cadastro de locais). Quando o formulário de
  suporte abre **sem QR**, o local vem preenchido com a primeira delas,
  **editável** (não travado). Se uma sala salva for desativada, ela sai da
  lista da pessoa e o formulário usa a próxima. Agentes também têm "minha
  sala" no próprio perfil.

### 7.6 Idioma do portal (spec 13 Δ23)

- A interface do portal existe em **português e inglês**.
- Idioma de exibição, nesta ordem: o idioma escolhido pelo leitor no seletor
  do portal; para solicitante logado, o idioma da Pessoa; para visitante, o
  idioma preferido declarado pelo navegador, se for um idioma aceito; por fim,
  o idioma padrão da conta.
- Escolher o idioma no seletor, logado, grava o idioma da Pessoa (é o mesmo
  dado que define o idioma dos e-mails a ela).
- O conteúdo dos tickets não é traduzido; só a interface e a KB (§2.5).

### 7.7 Marca da conta (spec 13 Δ25)

- O portal mostra o logo, o nome, a cor principal e a cor de destaque da conta.
  A mesma marca vale para o widget de chat e para os e-mails ao solicitante
  (specs 02 e 03).
- Toda combinação de texto sobre cor da marca precisa ter contraste mínimo
  **AA**: 4,5:1 para texto normal e 3:1 para texto grande. Ao salvar as cores,
  o sistema calcula o contraste; se não atingir, ele **ajusta o tom do texto**
  (claro ou escuro, ou escurecendo/clareando o texto) até atingir, sem mudar a
  cor escolhida pelo admin, e mostra ao admin o resultado.
- Sem marca configurada, o portal usa a identidade padrão do PantherDesk. A
  área de atendimento mantém sempre a identidade do PantherDesk.
- Na EARJ, o portal usa a paleta Panthers com o nome da escola (spec 13 Δ30).

### 7.8 Endereço do portal (spec 13 Δ32)

- O portal responde no **domínio próprio da conta** (na EARJ,
  help.earj.com.br). A área do agente fica no mesmo domínio, num caminho
  separado; uma única entrada com Google serve às duas.
- **Todos os links enviados** ao solicitante usam esse domínio: link mágico,
  convidado, avaliação, confirmação de abertura, artigos inseridos em
  respostas (§6.1) e o endereço curto dos QR (§8.8). Nenhum link enviado usa um
  endereço interno da instalação.
- Sem domínio próprio configurado, vale o endereço da instalação. No ambiente
  local (00-produto), o portal fica no mesmo host da aplicação.
- Trocar o domínio da conta faz os links novos usarem o domínio novo. Os links
  já enviados no domínio antigo só continuam funcionando se a infraestrutura
  mantiver o domínio antigo apontando para a conta; isso fica fora do produto.

---

## 8. Portal: tickets

### 8.1 Quais tickets o solicitante vê

| Origem do acesso | Vê | Pode responder |
|---|---|---|
| É o **solicitante** do ticket | sim | sim |
| É **participante** confirmado do ticket (spec 06 §5.1) | sim | sim |
| É membro de uma organização com compartilhamento que vale para ele (abaixo), e o ticket é de um colega da mesma organização | sim, **somente leitura** | não |
| Nenhuma das anteriores | não ("não encontrado") | não |

**Tickets da organização** (D07; spec 06 §5.2):
- Configuração por organização, com três valores: **desligado** (padrão),
  **só gestores** (só pessoas com a marca **gestor da organização** veem os
  tickets dos colegas) e **todos os membros**.
- **Gestor da organização** é uma marca na Pessoa, dada pela equipe. Só tem
  efeito enquanto a pessoa pertence à organização e o valor for "só gestores".
- "Tickets da organização" = tickets cujo **solicitante** pertence à
  organização **no momento da consulta**. Se a pessoa sai da organização, o
  acesso dela aos tickets dos ex-colegas some na hora, e os tickets dela somem
  da visão dos ex-colegas. Tirar a marca de gestor tem o mesmo efeito imediato.
- Acesso pela organização é **somente leitura**: ver mensagens públicas,
  baixar anexos de mensagens públicas. Não responde, não anexa, não usa "meu
  problema foi resolvido", não avalia e não muda nada. Diferente de um dos
  projetos, em que membros de organização compartilhada também alteram tickets
  dos colegas; isso espalha a autoria e surpreende quem abriu o pedido.
- Um membro que precisar falar no ticket do colega pede ao agente para ser
  incluído como participante.

Listas do portal:
- **Meus pedidos**: solicitante ou participante. Padrão: ordenada pela última
  atividade, mais recente primeiro, com filtro **em andamento** (aberto,
  pendente, em espera) / **encerrados** (resolvido, fechado) / todos. Entram os
  tickets de qualquer canal (e-mail, formulário, portal, chat, agente).
- **Pedidos da organização**: só aparece se o compartilhamento valer para a
  pessoa; mesma ordenação e filtros, mais o nome do solicitante.
- Tickets **mesclados** não aparecem em lista; quem abre o endereço de um
  mesclado é levado ao destino (se tiver acesso a ele) ou recebe "não
  encontrado".
- Busca nas listas: spec 08 §8.

### 8.2 Abrir pedido pelo formulário do portal (spec 13 Δ1, Δ2)

**Formulários.** O formulário do portal é o canal principal de entrada.
- O admin define **um ou mais formulários**. Cada um tem nome, grupo de
  destino e uma lista ordenada de campos (de sistema e personalizados), cada
  campo com rótulo para o solicitante, texto de ajuda, obrigatoriedade e
  condição de exibição (abaixo).
- Há dois tipos de formulário: **suporte** (este parágrafo) e **evento**
  (§8.9, spec 13 Δ34). No MVP, fica ativo **um formulário de cada tipo** por
  vez; a página inicial do portal oferece "pedir suporte" e "pedir evento"
  (este só se houver formulário de evento ativo). Os inativos ficam guardados;
  o admin pode abrir a **pré-visualização** de um inativo para testá-lo, e o
  envio de teste a partir da pré-visualização não cria ticket. Solicitantes e
  visitantes nunca veem um formulário inativo.
- **Local** (Δ33): campo de sistema com escolha encadeada **campus → prédio →
  andar → sala**, só com salas ativas do cadastro de locais. Ele pode ser
  obrigatório e é preenchido, nesta ordem, pelo QR (§8.8), pela "minha sala"
  (§7.5) ou pela pessoa. O ticket guarda a sala e a **origem do local** (QR,
  minha sala ou escolha manual), usada em relatórios. O local nunca vem de
  etiquetas.
- Campos de sistema que podem entrar no formulário: assunto e descrição
  (sempre presentes e obrigatórios), anexos, **equipe** (escolha do grupo, com
  nomes de exibição definidos pelo admin para cada grupo liberado), prioridade
  e tipo do ticket (spec 13 Δ8). O campo "equipe" é diferente do **tipo do
  ticket** (pergunta, incidente, problema, tarefa, evento). Se o formulário não tiver o
  campo "equipe", o ticket vai para o grupo de destino do formulário; as
  automações de criação (spec 05) podem rotear depois pelos valores dos campos
  (na EARJ, pelo motivo do contato e pelo campus do local, que vem do
  cadastro de locais, nunca de um campo personalizado; D51).
- Campos personalizados entram se estiverem marcados como "visível ao
  solicitante, editável na abertura" (spec 01 §5). Campos "só agentes" **nunca**
  aparecem no formulário.
- Regras de assunto, descrição e anexos: as do formulário da spec 03 §4.2
  (hoje: assunto até 150 caracteres, descrição em texto puro, até 5 arquivos de
  10 MB e 25 MB no total). O portal não tem regra própria.

**Campos condicionais.**
- Um campo pode ter **condição de exibição**: aparece só quando outro campo tem
  certos valores (ex.: "Equipamento" aparece só quando "Motivo" = hardware;
  "Sintoma" só quando "Equipamento" = impressora; D51). As condições podem ser encadeadas, mas não formam ciclo; a
  regra é definida e validada na spec 01 §5.
- Um campo oculto **não é obrigatório**, mesmo marcado como obrigatório.
- Quando o solicitante muda o campo do qual outro depende e o dependente fica
  oculto, o valor do dependente é **limpo** no formulário e não é enviado.
- O servidor reavalia as condições com os valores recebidos: falta de campo
  visível obrigatório é erro de validação que indica o campo; **valor enviado
  para um campo que deveria estar oculto também é erro de validação** (mesma
  regra da API, Δ2). Nada é gravado.

**Quem envia.**
- **Solicitante logado** (padrão): solicitante = pessoa da sessão; canal
  `portal`; nome e e-mail não são pedidos. Não há campo-isca nem CAPTCHA; há o
  limite de volume por Pessoa da spec 03 §5.
- **Visitante**, só se a conta permitir envio sem login: o formulário pede
  também nome e e-mail, e o envio segue o fluxo do formulário público da spec 03
  §4 (anti-spam em camadas, identificação do solicitante, canal `formulario`).
  Com o envio sem login desligado, o formulário leva à tela de entrada (§7.1)
  antes de aparecer, e volta a ele depois do login. Na EARJ, o envio sem login
  é **permitido**, com nome e e-mail obrigatórios (spec 13 §6). A permissão é
  por formulário: o formulário de evento exige login por padrão (§8.9).
- O **convidado** (§7.3) não abre pedido novo por esse link; ele recebe a opção
  "entrar no portal".

**Criação.**
- O ticket guarda os valores dos campos do formulário e passa pelo **mesmo
  caminho de criação** dos outros canais: numeração, auditoria, gatilhos,
  atribuição, SLA e notificações (specs 01, 04, 05, 09). Um dos projetos grava
  o pedido do portal direto, sem passar pelas notificações; o PantherDesk não
  tem esse atalho.
- O solicitante recebe **uma única** confirmação de recebimento por pedido. Ela
  é o gatilho de criação da spec 05 §6, mecanismo único para todos os canais
  (D25); o texto e a escolha entre a versão "dentro do horário" e "fora do
  horário" vêm desses gatilhos (spec 13 Δ11), e o portal não envia um e-mail
  próprio além dela. A confirmação leva o link de convidado (§7.3).
- Para **endereço não verificado** (visitante, §7.0), a confirmação não repete
  nada do que foi digitado (assunto, descrição, campos de texto livre, nome
  informado): traz só o número do ticket e o link de convidado, e vale no
  máximo **3 por endereço a cada 24 h** (D25, spec 05 §6.1).
- Envio duplicado (duplo clique, reenvio após falha de rede) com o mesmo token
  de formulário cria **um** ticket só.
- A deflexão (§6.2) roda neste formulário.
- Incluir participantes pelo portal fica no roadmap.

### 8.3 O que o solicitante vê dentro do ticket

| Elemento | Mostrado ao solicitante |
|---|---|
| Número, assunto, data de criação, última atividade | sim |
| Estado | sim, com o nome de exibição do portal: aberto → "em andamento"; pendente → "aguardando sua resposta"; **em espera → "em andamento"**; resolvido → "resolvido"; fechado → "fechado". O termo "em espera" nunca aparece (Δ3) |
| Data de retorno (pendente ou em espera) | não |
| Grupo, responsável, prioridade, tipo, etiquetas | não |
| Encaminhamento com retorno (Δ5) | não; o ticket encaminhado está **aberto** (D23) e aparece como "em andamento"; a marca "encaminhado" nunca é mostrada |
| Marca "resolvido pelo solicitante" (D33) | não; o solicitante vê o estado "resolvido" e a mensagem de sistema do §8.6 |
| Seguidores (Δ6) | **nunca** |
| Local (campus, prédio, andar, sala; Δ33) | sim; a origem do local, não |
| Dados do evento (Δ34): nome, tipo, data, horários, montagem, local, público, equipamentos, observações | sim, para tickets de evento; a marca "fora do prazo" e o prazo da montagem, não |
| Incidente pai e filhos (Δ35) | não; uma resposta escrita no pai aparece como mensagem pública do próprio ticket, com o nome do agente; o pai, os outros filhos, os outros solicitantes e os locais afetados nunca aparecem |
| Campos personalizados | só os marcados como visíveis ao solicitante (spec 01 §5) e que estejam visíveis pela condição de exibição |
| Mensagens públicas (de qualquer autor) | sim, em ordem cronológica, com nome do autor; para agentes, o nome de exibição do agente |
| Mensagens de sistema públicas (ex.: confirmação de recebimento enviada, spec 05 §3.3) | sim |
| Notas internas e menções (Δ7) | **nunca** |
| Conversas paralelas e seus e-mails (Δ17) | **nunca** |
| Mensagens de sistema internas (resposta automática recebida, bounce, aviso de mensagem grande) | não |
| Anexos | só os de mensagens públicas; o download confere a permissão a cada pedido |
| Eventos de auditoria / histórico | **nunca** (spec 01 §7) |
| Participantes | nomes e endereços dos participantes confirmados (já estão em Cc no e-mail) |
| Vínculo "continuação de #N" | sim, se o solicitante tiver acesso ao ticket #N |
| Indicação "vinda de #N" em mensagens de mescla | sim, como texto, sem link se não tiver acesso a #N |
| Avaliação da resolução (§8.7) | sim, para o solicitante |

Regras:
- A filtragem é feita **no servidor**, em toda resposta destinada a
  solicitante ou convidado (portal e API com credencial de solicitante). O
  cliente nunca recebe o dado para depois esconder. Isso inclui o estado: a
  resposta ao solicitante traz só o estado de exibição, nunca "em espera".
- Um anexo inline de nota interna ou de conversa paralela não pode ser baixado
  por solicitante, nem com o endereço exato: "não encontrado".
- Uma nota interna citada dentro de uma resposta pública só aparece se o
  agente a colou no corpo da resposta (é então conteúdo público, escolha do
  agente).

### 8.4 Responder pelo portal

- A resposta é uma mensagem **pública**, canal portal, com o mesmo efeito de
  uma resposta por e-mail (spec 01 §4.3): em **pendente**, **em espera** ou
  **resolvido**, o ticket vai para **aberto** e a data de retorno é descartada;
  em aberto, continua aberto.
- Cópia para os participantes por e-mail, como qualquer mensagem pública
  (spec 02 §9).
- O solicitante não muda campos nem estado diretamente. A única mudança de
  estado que ele faz sem responder é "meu problema foi resolvido" (§8.6).

### 8.5 Ticket fechado no portal (spec 01 §4.4)

- O portal mostra **responder** apenas quando a política do grupo, naquele
  momento, resultaria em reabrir (`reabrir`, ou `janela` dentro dos N dias).
  Caso contrário, mostra **abrir um novo pedido sobre isto**.
- Na EARJ, a política de todos os grupos é `novo` (spec 13 Δ13): ticket
  fechado sempre mostra "abrir um novo pedido sobre isto".
- "Abrir um novo pedido sobre isto" abre o formulário do §8.2 com o assunto do
  ticket anterior preenchido (editável); o ticket criado fica **vinculado** ao
  fechado ("continuação de #N"), com o mesmo solicitante, grupo e
  participantes, e o fechado não muda, como na política `novo`.
- A política é **reavaliada no servidor no momento do envio**. Se a tela foi
  aberta dentro da janela e o envio chegou depois dela, a mensagem vira um
  ticket novo vinculado (exatamente como faria pelo e-mail), e o portal mostra
  ao solicitante o número do ticket novo.
- Ticket **mesclado** é somente leitura e não é mostrado (§8.1).

### 8.6 "Meu problema foi resolvido" (D08)

- Disponível só para o **solicitante** do ticket (na sessão do portal ou pelo
  link de convidado dele, e pela API com credencial de solicitante, spec 10).
  Participantes e membros da organização não têm a ação.
- Transições: aberto, pendente ou em espera → **resolvido** (spec 01 §4.2,
  nota ⁴). Nunca para fechado. Em resolvido, fechado ou mesclado, a ação não
  aparece; se chegar ao servidor, é recusada sem gravar nada.
- O solicitante pode escrever um comentário opcional. Com comentário, ele
  entra como mensagem pública do solicitante; em qualquer caso, a ação registra
  uma **mensagem de sistema** ("o solicitante informou que o problema foi
  resolvido") e um evento de auditoria com origem solicitante.
- A ação **não** exige responsável (mesmo com a regra Δ4 ligada) nem os
  campos "obrigatórios para resolver", que o solicitante não consegue
  preencher (D33). O ticket vai para resolvido com a marca **"resolvido pelo
  solicitante"**, visível só para a equipe (filas, busca e relatórios).
- Depois dela valem as regras normais de resolvido: o fechamento automático
  conta a partir daí, e uma resposta pública posterior reabre.
- Ela **não** dispara convite de pesquisa: o convite exige resolução com
  resposta pública da equipe (Δ15).

### 8.7 Pesquisa de satisfação (D19, spec 13 Δ15)

- Quando o ticket vai para **resolvido com resposta pública**, o solicitante
  recebe o convite (no mesmo e-mail da resposta, Δ12) e, no portal, o ticket
  resolvido mostra a avaliação. Se o ticket veio do chat, o convite aparece no
  widget (spec 03).
- Só o **solicitante** avalia. Participantes, membros da organização e o
  convidado de um participante não veem a avaliação nem a podem fazer.
- Escala de **1 a 5**, com comentário opcional. Para nota 1, 2 ou 3, o portal
  mostra também o **motivo** opcional, de uma lista definida pelo admin; para
  4 ou 5, o motivo não é pedido.
- **Link de avaliação no e-mail**: o e-mail traz as cinco notas, cada uma com um
  link pessoal do solicitante para aquela resolução. O link abre, sem login, a
  página de avaliação com a nota pré-selecionada; a avaliação só é **gravada
  quando o solicitante confirma** na página. Abrir o link não grava nada,
  porque filtros de e-mail costumam abrir links automaticamente.
- Uma avaliação por **resolução**. Enquanto o ticket não estiver fechado, o
  solicitante pode alterar a avaliação; cada alteração gera evento de
  auditoria. Depois de fechado, a avaliação fica somente leitura e o link
  responde que o prazo terminou.
- Se o ticket reabre e é resolvido de novo, um novo convite só é enviado se o
  anterior tiver mais de 24 h; sem convite novo, o portal continua mostrando a
  avaliação anterior. Com convite novo, a nova resolução tem a sua própria
  avaliação, e a anterior fica preservada no histórico.
- O convite não é enviado (e o portal não mostra a avaliação) nos casos da
  Δ15: endereço inválido, ticket marcado como spam, contato proativo resolvido
  sem resposta do solicitante, pesquisa desligada no grupo. Também não é
  enviado para um **incidente pai** nem para os **filhos** vinculados a ele
  (Δ35).
- A pesquisa saiu do roadmap desta spec (D19).

### 8.8 QR da sala (spec 13 Δ33)

- Cada sala ativa tem um QR que aponta para um **endereço curto e estável** do
  portal com o **código da sala** (§7.8). Renomear a sala, mudá-la de andar ou
  trocar o texto da folha impressa não muda o QR.
- Ao abrir o QR (permissões: spec 06 §5.5):
  - **Solicitante com sessão**: abre o formulário de **suporte** com campus,
    prédio, andar e sala **preenchidos e travados**. A opção **"não estou
    nesta sala"** destrava e limpa os quatro campos; a pessoa escolhe outro
    local (ou deixa a "minha sala", §7.5). Os outros campos funcionam
    normalmente.
  - **Sem sessão**: tela de entrada (§7.1), com a sala guardada no destino. Com
    o envio sem login permitido, "continuar sem entrar" abre o mesmo
    formulário travado, com nome e e-mail.
  - **Agente ou admin com sessão**: abre na área do agente a lista de tickets
    abertos daquela sala (spec 08 §9.8), com "assumir" e "novo ticket com este
    local".
- O ticket enviado sem usar "não estou nesta sala" fica com o local do QR e a
  origem **QR**. O servidor confere que a sala existe e está ativa; o
  travamento é da tela, não uma garantia de onde a pessoa está.
- Sala **desativada** ou código **desconhecido**: o formulário abre sem local,
  destravado, com o aviso "esta sala não foi encontrada; escolha o local". Os
  tickets antigos daquela sala mantêm o local.
- O QR de sala não abre o formulário de evento; o formulário de evento aceita
  o mesmo local por escolha (§8.9).

### 8.9 Formulário de evento (spec 13 Δ34)

- Separado do formulário de suporte (§8.2), com o seu grupo de destino (na
  EARJ, o grupo de eventos). Campos de sistema:
  - **nome do evento** (vira o assunto do ticket), obrigatório;
  - **tipo de evento** (D53): assembly, homecoming, tradução simultânea, evento entre campi,
    pequeno evento, outro; obrigatório;
  - **data**, **início** e **fim**, obrigatórios; o fim é depois do início;
  - **início da montagem** (data e hora), obrigatório, no máximo igual ao
    início do evento;
  - **local** (do cadastro, §8.2), obrigatório;
  - **público estimado** (número inteiro positivo), **equipamentos pedidos**
    (lista de escolha múltipla definida pelo admin) e **observações**
    (descrição).
  - O admin pode acrescentar campos personalizados, como no suporte.
- Datas e horas do evento são sempre no **fuso da conta** (o evento acontece
  na escola), não no fuso de quem preenche.
- Um evento com início da montagem **no passado** é recusado (erro de
  validação no campo).
- **Antecedência mínima**: configurável pelo admin; padrão **5 dias úteis**,
  pelo calendário do grupo de destino (ou da conta). Conta-se o número de dias
  úteis **depois** do dia do envio até o dia do início da montagem, inclusive.
  Abaixo do mínimo, o pedido é **aceito**, mas o ticket recebe a marca **"fora
  do prazo"**, visível só para a equipe (filas, busca, calendário). Antes de
  enviar, o portal avisa o solicitante que o pedido está em cima da hora e
  pode não ser atendido por completo.
- O ticket de evento guarda os dados acima, é marcado como **ticket de
  evento** e entra no calendário de eventos (spec 08 §9.7) e nas filas
  normais. O prazo dele é o início da montagem (spec 13 Δ34; selo na spec 08
  §9.3).
- Por padrão, o formulário de evento **exige sessão** (funcionários e
  professores); o admin pode permitir o envio sem login, com as mesmas regras
  do §8.2.
- O solicitante acompanha o pedido em "Meus pedidos" como qualquer ticket e
  vê os dados do evento (§8.3). Mudanças de data ou de horário são pedidas por
  resposta; quem altera os campos é o agente.
- Fase 2 (fora do MVP): checklist de preparação com prazos relativos ao evento
  e detecção de conflito de local e de equipamento.

---

## 9. Abordagens comparadas

| Projeto | Abordagem (documentação pública) | Prós | Contras |
|---|---|---|---|
| **Zammad** | KB com categorias e subcategorias; estados rascunho, interno, público, agendado e arquivado; permissão por categoria herdada (filho só restringe); vários idiomas; portal com senha e auto-cadastro; organização compartilhada em que membros veem **e alteram** tickets dos colegas | herança de permissão segura; multi-idioma maduro | estado e visibilidade misturados no mesmo eixo; permissão de leitura que expõe interno; colega alterando ticket alheio |
| **Chatwoot** | central de ajuda pública, com vários portais por marca e por idioma; rascunho, publicado e arquivado; sem artigo interno; artigos populares no widget antes da conversa; pesquisa de satisfação no fim da conversa; sem portal de tickets com login | simples; boa deflexão no chat | sem conteúdo interno; sem portal de tickets; disponibilidade na edição comunitária incerta |
| **FreeScout** | KB e portal só como módulos pagos; KB por caixa; restrição por categoria; portal com login **sem senha**, por link válido por uma hora; pedido do portal gravado sem passar pelas notificações | link mágico elimina senhas | KB e portal fora do núcleo; atalho de criação que pula notificações |
| **osTicket** | categorias aninhadas e artigos; público ou interno por categoria **e** por artigo; sem rascunho nem revisões; portal com usuário registrado (senha) ou convidado (e-mail + número do ticket abre só aquele ticket); formulários com campos por tema de ajuda; contatos primários veem os tickets da organização como colaboradores | acesso de convidado a um único ticket; formulário por tema | sem rascunho; o número do ticket é adivinhável e é atrito |
| **Znuny** | KB como pacote adicional; três audiências por item (interno, clientes logados, público); interface pública anônima; portal com senha, auto-registro, "meus tickets" e "tickets da empresa"; campos dinâmicos no formulário do cliente | as três audiências são exatamente as necessárias | KB fora do núcleo; estados e aprovação pouco documentados |
| **UVdesk** | três níveis (pasta, categoria, artigo); publicado ou rascunho; revisões com restauração; slug e metadados por artigo; portal por pacote separado | revisões restauráveis; slugs | hierarquia funda para o tamanho típico; visibilidade interna não documentada |
| **Frappe Helpdesk** | categorias planas; rascunho, publicado, arquivado; visibilidade por artigo (público, clientes logados, privado); mover nunca amplia; deflexão ao digitar o assunto; busca depende de um módulo externo de cache (sem ele, nada retorna); portal com senha via convite; gestor vê tickets da empresa; avaliação do atendimento pelo cliente | visibilidade por artigo com regra de mover segura; deflexão | busca quebra sem o serviço externo; documentação contraditória sobre tickets da organização |

**Escolha PantherDesk e motivos**:
- **Hierarquia**: categoria plana → artigo (como Frappe). Menos regras, com o
  teto de visibilidade já pronto para um nível filho no roadmap.
- **Visibilidade**: três níveis por artigo (como Znuny e Frappe) com **teto
  por categoria** e "mover nunca amplia" (generalizando a regra do Frappe e a
  herança restritiva do Zammad). Interno nunca é servido por rota pública.
- **Estados**: rascunho, publicado, arquivado, separados da visibilidade
  (diferente do Zammad, que mistura os dois).
- **Revisões**: no MVP, imutáveis a cada publicação, com restauração (como
  UVdesk), mais edição em andamento que não toca o publicado.
- **Idiomas**: traduções do mesmo artigo, com a base no idioma padrão e queda
  para ela quando falta tradução (próximo do modelo do Zammad, sem portais
  separados por idioma como no Chatwoot).
- **Busca e deflexão**: no MVP, no PostgreSQL, sem serviço externo (o
  contraexemplo do Frappe mostra o custo da dependência).
- **Autenticação** (revista em v0.3): Google do domínio da escola como entrada
  principal (requisito da operação, spec 13 Δ31); link mágico (como FreeScout)
  para quem não tem conta da escola; senha opcional, desligada por padrão,
  definida só depois de provar o e-mail.
- **Convidado**: link assinado por destinatário em cada e-mail (escopo do
  convidado do osTicket, sem o número adivinhável).
- **Organização**: opt-in por organização, somente leitura (contrário do
  Zammad), com opção de restringir a gestores (como Frappe).
- **Criação pelo portal**: formulários com campos condicionais (como os
  formulários por tema do osTicket e os campos dinâmicos do Znuny), pelo mesmo
  pipeline dos outros canais (contrário do atalho do FreeScout).
- **Pesquisa de satisfação**: gravada só na confirmação da página, nunca ao
  abrir o link, para não registrar notas dadas por robôs de e-mail.

---

## 10. Casos de teste (critérios de aceite)

Atores: `ag1` e `ag2` (grupo N1, "Suporte N1"), `ag3` (grupo Financeiro),
`admin`, solicitantes `ana` e `bia` (org. Acme), `cris` (sem org.), e
`visitante` (anônimo, sem sessão). Salvo indicação, a KB está "acessível sem
login" com idioma padrão português, a senha opcional está ligada (o padrão do
produto passou a ser desligada em v0.3, §7.1), o
auto-cadastro está ligado, o envio do formulário sem login está desligado, a
Acme tem compartilhamento **desligado**, a política de fechado do N1 é
`janela` 14, o responsável obrigatório para resolver está desligado e a
pesquisa está ligada. Tickets desta suíte: #1700 (N1, solicitante ana,
responsável ag1) e #1701 (N1, solicitante bia). Horários em America/Sao_Paulo
(UTC−3).

### 10.1 Estrutura, estados e revisões
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-01 | conta nova | listar categorias como admin | existe só "Geral", teto público |
| KB-02 | "Geral" existe | admin tenta excluir "Geral" | recusado; nada muda |
| KB-03 | categoria "VPN" com 3 artigos | admin exclui "VPN" escolhendo "Geral" como destino | os 3 artigos ficam em "Geral"; "VPN" deixa de existir; 3 eventos de mudança de categoria |
| KB-04 | ag1 (agente) | ag1 cria artigo e tenta publicar | o artigo é criado em rascunho; a publicação é recusada (só admin publica) |
| KB-05 | artigo em rascunho, público | visitante abre o endereço do artigo | "não encontrado" |
| KB-06 | artigo em rascunho | admin publica | estado publicado; revisão 1 criada; data da primeira publicação gravada; evento antes=rascunho, depois=publicado |
| KB-07 | artigo publicado, revisão 1 com corpo "texto A" | admin salva edição em andamento com "texto B" sem publicar | visitante continua vendo "texto A"; agente vê a edição em andamento |
| KB-08 | após KB-07 | visitante busca "texto B" | nenhum resultado; nenhum trecho com "texto B" |
| KB-09 | após KB-07 | admin publica a edição | revisão 2 é a atual; visitante vê "texto B" |
| KB-10 | revisões 1 e 2 | admin restaura a revisão 1 | nova edição em andamento com o conteúdo da revisão 1; o público continua vendo a revisão 2; as revisões 1 e 2 continuam intactas |
| KB-11 | edição em andamento carregada por ag1 e por admin | admin salva; depois ag1 salva a partir da versão antiga | o salvamento de ag1 é recusado com conflito; nada do admin é perdido |
| KB-12 | artigo publicado e já publicado antes | admin tenta excluir definitivamente | recusado; oferece arquivar |
| KB-13 | artigo nunca publicado | admin exclui | o artigo deixa de existir; o identificador não é reutilizado |
| KB-14 | artigo público publicado | admin arquiva | visitante: página "não está mais disponível"; some da busca e da lista da categoria no mesmo instante |
| KB-15 | artigo arquivado | admin republica | volta com a última revisão publicada e a mesma visibilidade |
| KB-16 | artigo publicado | ag1 salva uma edição em andamento | aceito; o público não vê a edição; ag1 não consegue publicá-la; admin publica e a revisão nova tem autor ag1 |
| KB-17 | ag1 | ag1 tenta mudar a visibilidade de um artigo ou mover de categoria | recusado; nada gravado |
| KB-18 | artigo "Wi-Fi" com base PT em rascunho e tradução EN pronta | admin tenta publicar a tradução EN | recusado: a base precisa estar publicada |
| KB-19 | "Wi-Fi" com PT e EN publicadas | admin arquiva a tradução PT (base) | PT e EN arquivadas; 2 eventos de auditoria |

### 10.2 Visibilidade
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-20 | artigos publicados P (público), L (clientes logados), I (interno) na "Geral" | visitante lista a KB e busca uma palavra presente nos três | vê e acha só P |
| KB-21 | idem | ana (logada) lista e busca | vê e acha P e L; nunca I |
| KB-22 | idem | ana abre o endereço exato de I | "não encontrado", mesma resposta de um identificador inexistente |
| KB-23 | idem | visitante abre o endereço exato de L | tela de login, sem título nem trecho; depois do login de ana, L abre |
| KB-24 | I tem uma imagem embutida | visitante e ana pedem o arquivo da imagem pelo endereço exato | "não encontrado" para os dois; ag1 consegue baixar |
| KB-25 | categoria "Interno" com teto interno; artigo P público na "Geral" | admin move P para "Interno" | P fica interno; evento de mudança de visibilidade; visitante deixa de ver P |
| KB-26 | após KB-25 | admin move P de volta para "Geral" (teto público) | P continua **interno** |
| KB-27 | categoria "Geral" teto público com P (público) e L (logados) | admin muda o teto para clientes logados | P passa a clientes logados; L não muda; 1 evento só (em P) |
| KB-28 | após KB-27 | admin devolve o teto para público | P e L continuam clientes logados |
| KB-29 | categoria com teto clientes logados | admin tenta deixar um artigo dela público | erro de validação indicando o teto; nada gravado |
| KB-30 | KB com "acessível sem login" desligada; P público | visitante abre a KB e o endereço de P | tela de login; a visibilidade gravada de P continua público |
| KB-31 | categoria "Rede" só com artigos internos | visitante e ana listam categorias | "Rede" não aparece |
| KB-32 | I (interno) com tradução EN publicada | visitante abre o endereço de I em EN | "não encontrado" (a visibilidade é do artigo, vale para todas as traduções) |

### 10.3 Endereços e busca
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-35 | — | admin cria o artigo "Configuração do acesso à VPN" | slug "configuracao-do-acesso-a-vpn" |
| KB-36 | após KB-35, publicado | admin renomeia para "Acesso remoto pela VPN" | o slug não muda; o endereço continua igual |
| KB-37 | após KB-36 | admin regenera o slug; visitante abre o endereço antigo | redirecionamento permanente para o endereço com o slug novo |
| KB-38 | artigo publicado na "Geral" | admin move para "VPN" | o endereço do artigo não muda |
| KB-39 | endereço com o identificador de I (interno) e o slug de um artigo público | ana abre | "não encontrado" (a resolução é pelo identificador e a visibilidade é conferida) |
| KB-40 | artigo público com título "Conexão lenta na impressora" | visitante busca "CONEXAO impressoras" | o artigo aparece |
| KB-41 | artigo A com "impressora" no título; B com "impressora" só no corpo | visitante busca "impressora" | A antes de B |
| KB-42 | ag1 escreve resposta pública com o link de I (interno) | ag1 envia | envio recusado com aviso; nada enviado nem gravado |
| KB-43 | ag1 na tela de #1700 | ag1 busca "vpn" no painel de artigos e abre I | ag1 lê I; a opção de inserir o link de I na resposta pública não é oferecida |
| KB-44 | P com traduções PT e EN; solicitante de #1700 com idioma EN | ag1 insere o link de P na resposta | o link aponta para a tradução EN |

### 10.4 Deflexão
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-45 | P, L e I tratam de "VPN" | ana digita "vpn" no assunto do novo pedido | nenhuma sugestão (menos de 4 caracteres) |
| KB-46 | idem | ana digita "acesso vpn" | sugestões incluem P e L; nunca I; no máximo 5 |
| KB-47 | após KB-46 | ana abre P a partir da sugestão e volta | o assunto, a descrição e os campos já preenchidos continuam no formulário |
| KB-48 | após KB-47 | ana envia o pedido | ticket criado; ficam registrados os artigos sugeridos, o aberto (P) e o envio |
| KB-49 | P com PT e EN; visitante com navegador em inglês, envio sem login ligado | digita "printer not working" | sugestões na tradução EN; P aparece uma vez só |

### 10.5 Autenticação e conta
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-50 | ana existe (criada pelo e-mail) | pede link com o e-mail dela | link enviado; usá-lo abre sessão como a mesma pessoa ana (nenhuma pessoa nova) |
| KB-51 | endereço desconhecido, auto-cadastro desligado | pede link | a tela responde igual ao KB-50; nenhum e-mail enviado; nenhuma pessoa criada |
| KB-52 | auto-cadastro ligado | dani@exemplo.test se cadastra e não confirma | nenhuma pessoa criada |
| KB-53 | após KB-52 | dani usa o link de confirmação | pessoa dani criada, sem organização; sessão aberta |
| KB-54 | link de ana emitido há 31 min | ana usa o link | recusado; pede um novo |
| KB-55 | link usado uma vez | o mesmo link é usado de novo | recusado |
| KB-56 | ana pede o link 2 vezes | usa o primeiro | recusado (só o último vale) |
| KB-57 | ag1 tem e-mail de agente | pede link no portal | resposta igual ao KB-50; nenhum e-mail enviado |
| KB-58 | ana nunca entrou por link | tenta definir senha | não é possível sem sessão aberta por link |
| KB-59 | senha opcional **ligada** pela conta; ana com senha definida | 10 senhas erradas em 5 min, depois a senha certa | a 11ª tentativa é recusada por bloqueio; o link mágico continua funcionando |
| KB-60 | endereço de cris marcado como inválido (bounce) | cris pede link e o usa | link enviado; login ok; o endereço volta a válido com evento de auditoria |
| KB-61 | 6 pedidos de link para ana em 1 hora | — | 5 e-mails enviados; o 6º não envia; a tela responde igual |
| KB-62 | ag2 é solicitante de #1702 (N1, chamado interno), tem escrita no N1 e está logado na área de atendimento | ag2 abre o portal | entra sem link; vê #1702 em "Meus pedidos" sem notas internas; #1700 não aparece no portal |
| KB-63 | removido em v0.2 (D25: não há mais link de acompanhamento; ver KB-138) | — | — |
| KB-64 | removido em v0.2 (D25; ver KB-138) | — | — |

### 10.6 Tickets no portal
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-65 | ticket #1700 de ana com mensagem pública, nota interna de ag1 e mensagem de sistema (bounce) | ana abre #1700 no portal e pela API com credencial dela | vê só a mensagem pública; a resposta não contém o texto da nota nem do bounce; nenhum histórico; nenhum grupo, responsável, prioridade ou etiqueta |
| KB-66 | #1700 com campo "Produto" visível ao solicitante e campo "Causa" só para agentes | ana abre #1700 | vê "Produto"; não vê "Causa" |
| KB-67 | nota interna de #1700 com imagem inline | ana pede o arquivo da imagem pelo endereço exato | "não encontrado" |
| KB-68 | #1701 de bia; Acme com compartilhamento desligado | ana abre #1701 | "não encontrado"; #1701 não aparece em lista nenhuma de ana |
| KB-69 | Acme com compartilhamento "todos os membros" | ana lista "Pedidos da organização" e abre #1701 | vê #1701 em somente leitura; sem opção de responder; tentativa de responder pela API é recusada |
| KB-70 | Acme com "só gestores"; ana tem a marca de gestora, bia não | bia lista os pedidos da organização; ana abre #1701 | para bia, a lista não aparece; ana vê #1701 em somente leitura |
| KB-71 | após KB-69, bia sai da Acme | ana tenta abrir #1701 | "não encontrado" |
| KB-72 | cris é participante de #1700 | cris abre #1700 no portal e responde | resposta pública com autora cris; o solicitante continua ana |
| KB-73 | ana logada; formulário ativo com o campo "equipe", N1 ("Suporte") e Financeiro ("Cobrança") liberados | ana abre pedido escolhendo "Cobrança" | ticket no grupo Financeiro, canal portal, solicitante ana; gatilhos, SLA e atribuição aplicados como em e-mail; **uma** confirmação de recebimento, pelo gatilho de criação (D25), com o link de convidado de ana |
| KB-74 | formulário ativo sem o campo "equipe", grupo de destino N1 | ana abre o formulário | não há escolha de equipe; o ticket vai para o N1 |
| KB-75 | formulário preenchido | ana envia duas vezes com o mesmo token de formulário | um único ticket |
| KB-76 | #1700 pendente com data de retorno | ana responde pelo portal | estado aberto; data de retorno descartada; e-mail com a resposta vai para os participantes |
| KB-77 | #1700 aberto | ana tenta mudar o campo estado para resolvido pela API, sem usar a ação do §8.6 | recusado (spec 01 TL-15) |
| KB-78 | #1700 fechado há 13 dias; política `janela` 14 | ana abre #1700 | mostra "responder" |
| KB-79 | #1700 fechado há 20 dias; política `janela` 14 | ana abre #1700 | mostra "abrir um novo pedido sobre isto"; ao enviar, nasce um ticket novo vinculado a #1700, com o mesmo grupo e participantes; #1700 continua fechado |
| KB-80 | #1700 fechado há 13 dias e 23 h 59 min; política `janela` 14 | ana abre a tela e envia a resposta 2 min depois | ticket novo vinculado; o portal mostra o número novo; #1700 continua fechado |
| KB-81 | #1711 mesclado em #1710 | ana (solicitante de #1711) abre o endereço de #1711 | é levada a #1710; #1711 não aparece na lista dela |
| KB-82 | #1700 em espera (aguardando fornecedor), com data de retorno | ana abre #1700 no portal e pela API com credencial dela | estado exibido "em andamento"; nenhum texto "em espera" nem data de retorno; #1700 aparece no filtro "em andamento" |
| KB-83 | #1700 em espera | ana responde pelo portal | estado aberto; data de retorno descartada |
| KB-84 | #1700 com ag2 seguidor, nota com menção a ag3 e uma conversa paralela com um fornecedor | ana abre #1700 | não vê ag2, a nota, a menção nem a conversa paralela; os anexos da conversa paralela dão "não encontrado" |

### 10.7 Acesso de convidado
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-85 | ag1 responde #1700 (ana solicitante, cris participante) | inspecionar os dois e-mails de saída | cada um tem um link de acesso diferente; nenhum link contém o número do ticket nem o e-mail |
| KB-86 | link de ana de KB-85, sem sessão | abrir o link | vê só #1700 como ana; responder cria mensagem pública de ana, canal portal |
| KB-87 | idem | a partir do convidado, tentar a lista de pedidos e #1701 | lista exige login; #1701 "não encontrado" |
| KB-88 | link enviado há 31 dias | abrir | recusado; oferece a tela de entrada (§7.1) |
| KB-89 | cris é removida dos participantes de #1700 | cris abre o link dela | recusado |
| KB-90 | ag1 usa "invalidar links de acesso" em #1700 | ana abre o link de KB-85 | recusado |
| KB-91 | link de convidado de cris (participante) em #1700 aberto | cris procura "meu problema foi resolvido" e a avaliação | nenhuma das duas aparece |
| KB-92 | endereço de ana não verificado | ana abre o link de convidado | ticket aberto, sem sessão do portal; o endereço passa a verificado (spec 03 §4.5) |

### 10.8 Formulário do portal e campos condicionais
Formulário ativo "Pedido de TI" com: Local (campo de sistema do cadastro de
locais, opcional neste formulário), Motivo (lista hardware / acesso / rede /
outro, obrigatória), Equipamento (lista computador / impressora / projetor,
obrigatória, só se Motivo = hardware), Sintoma (lista não liga / não imprime /
outro, opcional, só se Equipamento = impressora) e "Causa" (só agentes). Não
há campos personalizados de unidade nem de setor/sala (D51).

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-100 | ana logada | envia com Motivo = acesso e Equipamento vazio | ticket criado; o equipamento não é exigido (reescrito em v0.3, D51) |
| KB-101 | idem | envia com Motivo = hardware e Equipamento vazio | recusado; o erro indica o equipamento; nada gravado (reescrito em v0.3, D51) |
| KB-102 | idem | abre o formulário | "Causa" não aparece; Equipamento e Sintoma só aparecem quando as condições valem; não há campo de unidade nem de setor/sala |
| KB-103 | ana escolheu Motivo = hardware, Equipamento = impressora e Sintoma = não imprime | muda o Motivo para acesso e envia | Equipamento e Sintoma somem e são limpos (a condição é encadeada); o ticket não tem valor de equipamento nem de sintoma (reescrito em v0.3, D51) |
| KB-104 | idem | um envio manipulado chega com Motivo = acesso e Equipamento = impressora | erro de validação no campo de equipamento; nada gravado (reescrito em v0.3, D51) |
| KB-105 | ana, Motivo = hardware, Equipamento = impressora | envia sem Sintoma, que não é obrigatório | ticket criado com Motivo e Equipamento gravados, sem Sintoma (reescrito em v0.3, D51) |
| KB-106 | formulário "Pedido v2" inativo | admin abre a pré-visualização e envia um teste; ana abre o portal | nenhum ticket criado; ana vê só "Pedido de TI" |
| KB-107 | envio sem login desligado | visitante abre o formulário | é levado à tela de entrada (Google ou link por e-mail, §7.1); o formulário não aparece antes do login |
| KB-108 | envio sem login ligado | visitante informa nome, e-mail e campos e envia | ticket com canal `formulario`, fluxo e anti-spam da spec 03 §4; os valores dos campos ficam gravados |
| KB-109 | quarta 2026-11-11 18:30; calendário da conta seg–sex 07:00–17:00; gatilhos de confirmação dentro e fora do horário (Δ11) | ana envia pelo portal | um único e-mail de confirmação, na versão "fora do horário" |

### 10.9 "Meu problema foi resolvido"
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-110 | #1700 pendente | ana usa "meu problema foi resolvido" sem comentário | estado resolvido; mensagem de sistema registrada; evento com origem solicitante; nenhum convite de pesquisa |
| KB-111 | #1700 em espera | ana usa a ação com o comentário "voltou a funcionar" | estado resolvido; mensagem pública de ana com o comentário, mais a mensagem de sistema |
| KB-112 | #1700 resolvido | ana abre o ticket | a ação não aparece; um pedido direto ao servidor é recusado sem gravar nada |
| KB-113 | Acme "todos os membros"; #1701 de bia aberto | ana tenta a ação em #1701 | não aparece; pela API, recusado |
| KB-114 | após KB-110, ninguém responde | 4 dias e 1 min depois | fechamento automático (spec 01 §4.3) |
| KB-115 | responsável obrigatório ligado (Δ4); #1701 sem responsável | bia usa a ação | aceita (D33): #1701 resolvido, sem responsável, com a marca "resolvido pelo solicitante"; o fechamento automático conta a partir daí |

### 10.10 Pesquisa de satisfação
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-120 | #1700 aberto | ag1 envia resposta pública e resolve | ana recebe **um** e-mail com a resposta e o convite; no portal, #1700 mostra a avaliação |
| KB-121 | após KB-120 | um filtro de e-mail abre o link da nota 1 | nada gravado |
| KB-122 | após KB-120 | ana abre o link da nota 2 e confirma com motivo "demorou" | avaliação 2 com motivo gravada; evento de auditoria |
| KB-123 | após KB-120 | ana escolhe nota 5 no portal | o motivo não é pedido; avaliação 5 gravada |
| KB-124 | após KB-122, #1700 ainda resolvido | ana muda para nota 4 | avaliação 4; o motivo é descartado; novo evento |
| KB-125 | após KB-122, #1700 fechado | ana abre o link de avaliação | avaliação somente leitura; nada muda |
| KB-126 | cris participante de #1700 | cris abre #1700 no portal | não vê a avaliação |
| KB-127 | convite em ter 2026-11-10 10:00; reaberto e resolvido de novo qua 2026-11-11 09:00 (23 h depois) | — | nenhum convite novo; o portal mostra a avaliação anterior |
| KB-128 | idem, resolvido de novo qua 2026-11-11 11:00 (25 h depois) | — | novo convite; a nova resolução tem avaliação própria; a anterior fica no histórico |
| KB-129 | pesquisa desligada no grupo N1 | ag1 resolve #1700 com resposta pública | nenhum convite; o portal não mostra a avaliação |

### 10.11 Idiomas e marca
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-130 | "Wi-Fi" com PT e EN publicadas; ana com idioma EN | ana abre a categoria | vê o título EN; o artigo aparece uma vez |
| KB-131 | "Projetor" só com PT publicada | ana (EN) abre o artigo | vê a tradução PT, com a indicação do idioma |
| KB-132 | "Wi-Fi" com EN em rascunho | visitante com navegador em inglês abre o artigo | vê a PT; o rascunho EN não aparece |
| KB-133 | visitante sem preferência aceita no navegador | abre o portal | interface em português (idioma da conta) |
| KB-134 | ana logada | escolhe inglês no seletor | interface em inglês; o idioma de ana passa a EN |
| KB-135 | admin escolhe cor principal amarelo claro, com texto branco nos botões | salva a marca | contraste abaixo de 4,5:1 detectado; o texto dos botões passa a escuro; a cor escolhida é mantida; o admin vê o ajuste |
| KB-136 | marca configurada | ag1 abre a área de atendimento | identidade do PantherDesk, não a da conta |

### 10.12 Ajustes D23–D37
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-137 | rascunho nunca publicado criado por ag1 | ag1 tenta excluí-lo e arquivá-lo; admin o exclui | ag1: recusado nas duas; admin: excluído (D30) |
| KB-138 | envio sem login ligado; dani@exemplo.test não existe na conta | dani envia o formulário com assunto "Projetor da sala 12"; abre o link da confirmação | **uma** confirmação, pelo gatilho de criação, só com o número e o link de convidado; nem o assunto nem o nome aparecem; o link abre só aquele ticket, sem sessão, e o endereço passa a verificado (D25) |
| KB-139 | endereço de dani não verificado | dani envia o formulário 4 vezes em 24 h | 4 tickets; 3 confirmações; a 4ª é suprimida com evento de auditoria (D25) |
| KB-140 | campo "Causa" obrigatório para resolver; #1700 pendente, sem "Causa" | ana usa "meu problema foi resolvido" | #1700 resolvido, com a marca "resolvido pelo solicitante"; "Causa" continua vazio; ana não vê a marca (D33) |
| KB-141 | após KB-140 | ag1 abre #1700 e o filtra na fila por resolvido | a marca "resolvido pelo solicitante" aparece para ag1 |
| KB-142 | ag1 encaminha #1700 com retorno para o Financeiro (Δ5) | ana abre #1700 no portal e pela API com credencial dela | estado exibido "em andamento"; nada indica grupo, encaminhamento nem a marca "encaminhado" (D23) |
| KB-143 | ana (endereço verificado) envia pelo portal | — | **uma** confirmação, no texto do gatilho, com o link de convidado; nenhum outro e-mail do portal (D25) |

### 10.13 Entrada com Google, domínio, QR, eventos, incidentes e "Criar artigo" (v0.3)
Contexto adicional: a conta tem o provedor Google com o domínio da escola
`escola.test` e o domínio próprio do portal `help.escola.test`; ana, bia e cris
têm endereços de outros domínios. Cadastro de locais com as salas `B-201`
(campus Barra, prédio A, 2º andar) e `B-105` (campus Barra, prédio A, térreo).
Formulário de suporte ativo com o campo Local obrigatório; formulário de
evento ativo para o grupo Eventos, antecedência mínima de 5 dias úteis,
calendário seg–sex 07:00–17:00 sem feriados, America/Sao_Paulo (UTC−3).

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| KB-144 | prof@escola.test não existe; auto-cadastro desligado | entra no portal com Google | Pessoa criada como solicitante, sem organização, endereço verificado; sessão do portal aberta |
| KB-145 | prof2@escola.test existe (criada por e-mail, endereço não verificado) | entra com Google | sessão como a mesma Pessoa (nenhuma nova); endereço passa a verificado |
| KB-146 | — | alguém pede link por e-mail com prof@escola.test | nenhum e-mail enviado; a tela orienta a entrar com Google, sem dizer se a pessoa existe |
| KB-147 | — | conta Google de `outro.test` tenta entrar no portal | recusada; a tela oferece o link por e-mail; nenhuma Pessoa criada |
| KB-148 | conta da demonstração EARJ | ag1 responde #1700 e insere o link de um artigo público | o link de convidado, o link de avaliação e o link do artigo usam help.earj.com.br |
| KB-149 | prof sem sessão | abre o QR de `B-201`, entra com Google | volta ao formulário de suporte com campus Barra, prédio A, 2º andar e `B-201` preenchidos e travados |
| KB-150 | ana sem sessão; envio sem login desligado | abre o QR de `B-201`, pede o link por e-mail e o abre em outro navegador | o formulário abre com `B-201` travada (o destino veio dentro do link) |
| KB-151 | após KB-149 | prof envia sem mexer no local | ticket com local `B-201` e origem QR |
| KB-152 | após KB-149 | prof usa "não estou nesta sala", escolhe `B-105` e envia | os quatro campos são destravados e limpos; ticket com local `B-105` e origem escolha manual |
| KB-153 | admin renomeia `B-201` para "Laboratório de Robótica" | prof abre o mesmo QR impresso | o formulário mostra o nome novo; o código e o QR são os mesmos |
| KB-154 | `B-201` desativada, com tickets antigos nela | prof abre o QR de `B-201`; depois abre o QR com um código inexistente | nos dois: formulário sem local, destravado, com o aviso; os tickets antigos continuam com `B-201` |
| KB-155 | endereço de entrada com destino apontando para um site de fora | ana entra pelo link por e-mail | vai para a página inicial do portal; nenhum redirecionamento externo |
| KB-156 | ana salvou `B-105` e depois `B-201` em "minha sala" | abre "pedir suporte" sem QR; depois abre o QR de `B-201` | sem QR: `B-105` preenchida e editável; com QR: `B-201` travada |
| KB-157 | envio seg 2026-11-09 10:00 | ana envia evento com montagem sex 2026-11-13 08:00 | o portal avisa antes de enviar; ticket criado com a marca "fora do prazo" (10, 11, 12 e 13 = 4 dias úteis); ana não vê a marca no portal |
| KB-158 | envio seg 2026-11-09 10:00 | ana envia evento com montagem seg 2026-11-16 08:00 | ticket criado sem a marca (10, 11, 12, 13 e 16 = 5 dias úteis) |
| KB-159 | envio seg 2026-11-09 10:00 | ana envia evento com montagem seg 2026-11-09 08:00; outro com fim antes do início; outro com montagem depois do início do evento | os três recusados, cada um indicando o campo; nada gravado |
| KB-160 | formulário de evento exige sessão (padrão) | visitante abre "pedir evento" | tela de entrada; depois do login, volta ao formulário de evento |
| KB-161 | após KB-158 | ana abre "Meus pedidos" e o ticket | o evento aparece como pedido, com nome, tipo, data, horários, montagem, local e equipamentos; sem prazo nem grupo |
| KB-162 | #1702 incidente pai com os filhos #1700 (ana) e #1701 (bia) | ag1 responde em público no pai | ana e bia recebem e-mails separados, sem o endereço uma da outra; no portal, ana vê a mensagem em #1700 e nada do pai nem de bia |
| KB-163 | após KB-162 | ag1 resolve o pai | #1700 e #1701 resolvidos; nenhum convite de pesquisa para ana, bia nem para o pai |
| KB-164 | #1700 resolvido; última resposta pública de ag1: "Olá Ana, reinicie o roteador da sala. Qualquer coisa, ana@acme.test pode responder. Att., ag1" | ag1 usa "Criar artigo", categoria "Rede", idioma PT | rascunho com título = assunto de #1700; corpo sem "Ana", sem o endereço, sem a saudação e sem a assinatura, com os pontos retirados marcados; origem #1700; visibilidade = teto de "Rede"; nada aparece no portal |
| KB-165 | após KB-164 | ag1 pede a outra língua (EN) | rascunho de **tradução EN do mesmo artigo**, com o mesmo título e texto de partida; nenhum artigo novo é criado (D42) |
| KB-166 | após KB-164 | ag1 tenta publicar; admin publica a PT | ag1: recusado (D30); admin: publicado; a referência a #1700 nunca aparece no portal |
| KB-167 | #1701 aberto; #1703 resolvido só pela ação do solicitante, sem resposta de agente | ag1 procura "Criar artigo" nos dois | a ação não aparece; pela API, erro de validação |
| KB-168 | artigo de KB-166 com temas equipamento = impressora, sintoma = não imprime | ana escolhe esses valores no formulário, sem digitar o assunto | o artigo é sugerido; no máximo 5 sugestões |
| KB-169 | após KB-164 | ag1 usa "Criar artigo" de novo em #1700 | aviso de que já existe um rascunho dele, com a opção de abri-lo; criar outro é permitido |
| KB-170 | ag1 com sessão | abre o QR de `B-201` | é levado à lista de tickets abertos de `B-201` na área do agente, com "assumir" e "novo ticket com este local" |
| KB-171 | #1700 resolvido; apoio1 é agente de apoio com **leitura** no N1 | apoio1 usa "Criar artigo" em #1700 | rascunho criado com título = assunto de #1700 e o texto da resposta pública final (D42) |
| KB-172 | após KB-165 | ag1 pede de novo a outra língua (EN) no mesmo artigo | abre a tradução EN existente; nenhuma tradução nem artigo novo |
| KB-173 | aplicação fora do modo de desenvolvimento | ag1 pede, na tela de entrada do portal, link por e-mail ou senha com o endereço dele | nenhuma das duas o deixa entrar; só a entrada com Google abre sessão para ele (D53) |

---

## 11. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Estados do artigo, revisões, efeito de arquivar | documentação (revisões em 1 projeto; arquivado pouco explicado) | K-01 |
| Visibilidade pública/interna, anônimo vs logado | documentação de 5 projetos | K-01, K-02 |
| Busca na KB (relevância, acento) | documentação parcial | K-02, S-03 |
| Fluxo do portal (abrir, acompanhar, responder) | documentação de 5 projetos | K-03 |
| Login (senha, link, convidado por número) | documentação | K-03 |
| Tickets da organização | documentação com conflito em 1 projeto | P-02 |
| Nota interna nunca visível ao solicitante | não lido explicitamente | P-03 |
| Deflexão | documentação de 2 projetos | K-04 |
| Multi-idioma | documentação de 4 projetos | K-05 |
| Formulário, campos condicionais, pesquisa e marca | requisitos da operação EARJ (spec 13) | — |

---

## 12. Questões abertas para o implementador

1. Validade do link mágico (30 min) e do link de convidado (30 dias) são
   propostas. Registrar no registro de decisões do projeto se mudarem.
2. Exclusão definitiva de artigo já publicado (por exemplo, por pedido legal)
   não existe no MVP. Decidir se o admin terá essa ação, com o aviso de que os
   links quebram.
3. **Antecedência do evento** (§8.9): esta spec conta os dias úteis até o
   **início da montagem**, porque é o compromisso do ticket (Δ34). Confirmar
   com o responsável pelo projeto se a conta deve ser até a data do evento.
4. **Troca do domínio do portal** (§7.8): os QR impressos e os links já
   enviados apontam para o domínio antigo. Decidir se a troca exige reimprimir
   os QR ou se a infraestrutura mantém o domínio antigo redirecionando.
5. **Retirada de dados no "Criar artigo"** (§3.5): a retirada automática do
   nome, endereços e telefones é heurística; nomes de terceiros citados no
   texto não são detectados. A revisão do agente e a publicação pelo admin são
   a garantia. Avaliar com os primeiros artigos da EARJ se isso basta.
