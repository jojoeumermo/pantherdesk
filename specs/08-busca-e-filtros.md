# Spec 08 — Busca, filtros e filas salvas

Status: **rascunho v0.3 (2026-10-29)**. Baseado na documentação pública dos 7
projetos analisados. As evidências de runtime ainda estão pendentes; cada ponto
que depende delas está marcado como **[evidência pendente: cenário]**.
Vocabulário: spec 01. Portal e KB: spec 07. Filas e atribuição: spec 04.
Permissões: spec 06. API: spec 10. Decisões transversais: spec 00-decisoes
(D01–D53). Requisitos da operação EARJ: spec 13, que prevalece sobre esta.

Mudanças na v0.3:
- **Selo de prazo** em toda linha de fila, sempre visível: "vence em",
  "vencido há", "pausado" ou, para eventos, "faltam N dias para a montagem"
  (spec 13 Δ37, Δ34) (§9.3).
- Fila padrão **"Quase escalando"** e filtro `sla` (vencido, pausado, nenhum,
  vence em até N horas úteis) (Δ37) (§4.2, §9.1).
- Filtros de **local** (`campus`, `predio`, `andar`, `sala`) (Δ33); de
  **evento** (`evento`, `tipo-evento`, `data-evento`, `tem:fora-do-prazo`)
  (Δ34); de **incidente** pai e filhos (Δ35) (§4.2). Colunas, agrupamentos e
  a ordenação por data do evento correspondentes (§7, §9.3).
- **Calendário de eventos** com visão de mês e de semana (Δ34) (§9.7) e lista
  de tickets de uma sala aberta pelo QR (Δ33) (§9.8).
- Novos casos BU-170 a BU-185.
- **Ajustes D40–D53**: o ticket de evento tem a **1ª resposta** do SLA comum
  e não tem a resolução comum; o prazo principal é o início da montagem,
  cumprido pela marca **"pronto para o evento"** (D40, D44). Selo do evento:
  "faltam N dias" ou "faltam N h", "pronto", "montagem sem pronto" (vermelho)
  e "evento encerrado"; "Quase escalando" inclui o evento sem "pronto" com
  montagem em até 1 hora útil ou já iniciada (§4.2, §7, §9.1, §9.3; BU-174
  corrigido). Filtro `tem:pronto` (D44). Vermelho também para **aberto sem
  resposta** (spec 13 Δ30, §9.3). Locais afetados do incidente = salas do pai
  e dos filhos (D48, §9.3). Calendário na API é a busca comum, sem recurso
  próprio (D50, §9.7). Sem os campos personalizados "unidade" e "setor/sala":
  agrupamento e relacionados usam o local do cadastro ou motivo, equipamento
  e sintoma (D51; BU-124 e BU-163 reescritos). Exemplo de e-mail em domínio
  de teste. Questão aberta 4 retirada (respondida pela D40). Novos casos
  BU-186 a BU-190.

Mudanças na v0.2:
- Estado **em espera** nos filtros, nas filas e no portal (D18, Δ3).
- "Visões salvas" passam a se chamar **filas salvas**, com colunas,
  agrupamento, ordenação, contagem e restrição por grupo; até **10** pessoais
  por agente (Δ9) (§9).
- **Modo sequência** e **edição em massa** (até 100 tickets) (Δ9) (§9.4,
  §9.5).
- **Contexto na tela do ticket**: tickets anteriores do solicitante e tickets
  relacionados (Δ18) (§9.6).
- Filtros novos: tipo (Δ8), seguidor (Δ6), encaminhado (Δ5), resolvido,
  avaliado e avaliação (Δ15), `grupo:meus`, campos de Pessoa e Organização
  (Δ22) e horas relativas (`12h`) (§4.2).
- Ordenação por **vencimento do SLA** definida pela métrica ativa mais próxima
  (Δ14); "aguardando há mais tempo" separado em "na fila há mais tempo" e
  "aguardando resposta há mais tempo" (§7).
- Visões padrão alinhadas à spec 04 §3 (§9.1).
- Página acima de 100 itens → **400** na API; a interface nunca pede mais
  (D15). Cursor inválido → 400, validade de 24 h, como na spec 10 (§10).
- Filtro `canal` com todos os tipos de canal da spec 03, incluindo `formulario`,
  `sistema` e `chat` (§4.2).
- Exportação CSV sai do roadmap: é a da spec 11, sobre a mesma consulta (§10.1).
- Busca de texto também na forma simples (sem radical), para tickets em inglês;
  KB pesquisada no idioma da tradução (Δ23) (§3.2).
- Caso BU-24 corrigido (#1801 e #1803); números de ticket da suíte trocados
  para a faixa #18xx (seed único).
- Questões abertas respondidas foram retiradas.
- Ajustes D23–D37: o ticket encaminhado com retorno tem **um único estado**
  (aberto, no grupo de destino); para a origem vale a marca derivada
  "encaminhado", usada como filtro (`encaminhado:meus`, nome do grupo); sai a
  regra dos "dois lugares" com em espera na origem (D23, §4.2, §9.3). A busca
  inclui a leitura do agente e do grupo de origem (D24, §5). Ordenação por
  **número** e lista de ordenações igual na API, com desempate pelo número
  (D32, §7). Filtro `tem:resolvido-pelo-solicitante` (D33, §4.2). Cursor
  inválido → 400 confirmado (D28). BU-106 e BU-107 atualizados; novos casos
  BU-109 a BU-115.

---

## 1. Problema

O agente passa o dia em filas: "meus abertos", "sem responsável no N1",
"aguardando o cliente há mais de 3 dias", "em espera com fornecedor". E, várias
vezes por dia, precisa achar um ticket por um pedaço de texto: uma frase do
cliente, um número de pedido citado no corpo, o e-mail de quem ligou, a
identificação de uma máquina. A busca precisa:

1. achar texto em **qualquer lugar relevante** do ticket (assunto, mensagens,
   notas internas, dados do solicitante, etiquetas, campos);
2. funcionar em **português de verdade**: "conexao" acha "Conexão",
   "IMPRESSORAS" acha "impressora"; e não falhar com texto em inglês;
3. ter uma sintaxe **pequena** que se aprende em um minuto;
4. **nunca** devolver o que o usuário não pode ver, nem como resultado, nem
   como contagem, nem como trecho;
5. achar um ticket **imediatamente** depois que ele foi criado ou alterado;
6. permitir salvar filtros como **filas** pessoais e compartilhadas, com
   colunas, agrupamento e contagem, e trabalhar a fila em sequência ou em massa;
7. paginar sem duplicar nem pular itens;
8. no portal, deixar o solicitante achar os próprios pedidos e os artigos que
   ele pode ler, e nada além disso.

---

## 2. Motor: decisão

**PostgreSQL**, com três recursos nativos ou de extensão padrão:
- **busca de texto completo** com dicionário por idioma (radicais e palavras
  vazias);
- **remoção de acentos** aplicada igualmente ao texto indexado e à consulta;
- **índice de trigramas** para trechos de nome, e-mail e identificadores, onde
  a busca por palavra não ajuda (ex.: "acme.te" achando "ana@acme.test").

Motivos:
- **Consistência imediata**: o índice é atualizado na **mesma transação** que
  grava o ticket ou a mensagem. Não existe janela em que o ticket existe e a
  busca não o acha (§6). Os projetos que usam um índice externo atualizam esse
  índice em segundo plano, com atraso de segundos a um minuto, e precisam de
  rotina de reconstrução.
- **Permissão no mesmo lugar dos dados**: o filtro de permissão é aplicado na
  mesma consulta que a busca (§5). Com índice externo, as permissões precisam
  ser copiadas para lá, e ficam desatualizadas.
- **Um componente a menos** para operar. Um dos projetos simplesmente não
  devolve resultado quando o serviço externo de busca não está presente; outro
  funciona sem ele, mas de forma "lenta e limitada", segundo a própria
  documentação.
- **Suficiente para o MVP**: os projetos que fazem busca no banco relacional
  atendem a funcionalidade básica; o motor externo só se paga para conteúdo de
  anexos, busca aproximada e volumes grandes, que ficam no roadmap (§10.1).

A busca é acessada pelo resto do sistema por uma interface própria (consulta →
resultados paginados), para que trocar o motor no futuro não mude a API
(spec 10) nem a interface. Filas salvas, painel de contexto, edição em massa,
página inicial do agente (spec 13 Δ21) e exportação (spec 11) usam essa mesma
interface.

Esta spec descreve comportamento; estrutura de índice e consultas ficam a
critério do implementador, desde que os casos de teste do §12 passem.

---

## 3. Escopo da busca do agente

### 3.1 O que é pesquisado

| Origem | Como entra | Peso na relevância |
|---|---|---|
| **Número do ticket** | igualdade exata. Aceita "1000", "#1000" e "PD-1000" (o marcador da spec 02 §4.1), sem diferença de maiúsculas | casamento exato vai sempre para o topo |
| **Assunto** | texto completo | alto |
| **Mensagens públicas** (corpo em texto puro, sem a parte citada recolhida, spec 02 §8) | texto completo | médio |
| **Notas internas** | texto completo, só para agentes e admin | médio |
| **Conversas paralelas** (spec 13 Δ17): assunto e mensagens | texto completo, só para agentes e admin | médio |
| **Nome do arquivo de anexo** | texto completo | baixo |
| **Solicitante**: nome e endereços | palavra e trecho (trigramas) | médio |
| **Solicitante**: campos personalizados de texto da Pessoa (Δ22; ex.: identificação da máquina) | palavra e trecho | baixo |
| **Participantes**: endereços | trecho (trigramas) | baixo |
| **Organização do solicitante**: nome | palavra | baixo |
| **Etiquetas** | igualdade com a etiqueta normalizada (spec 01 §2) | médio |
| **Campos personalizados** do ticket de texto curto e texto longo | texto completo | baixo |

Fora do escopo:
- **Conteúdo de anexos** (texto dentro de PDF, DOCX etc.): **roadmap**. Exige
  extração de texto em segundo plano, que quebraria a garantia do §6. Quando
  entrar, deve ser documentado como a única parte com atraso.
- **Mensagens de sistema** (resposta automática recebida, bounce, confirmação
  enviada): não entram na busca de texto. São ruído; um agente que precisa
  delas abre o ticket.
- **A parte citada** de um e-mail (spec 02 §8): não entra, para que uma frase
  citada não faça todos os tickets de uma thread longa aparecerem duas vezes.
  O corpo bruto continua disponível no ticket.
- **Mensagens em quarentena** (spec 02 §3): não são tickets e não aparecem na
  busca de tickets; o admin tem uma lista própria de quarentena.
- Campos de lista, número, data e caixa de seleção: entram por **filtro**
  (§4.2), não por texto livre.

### 3.2 Normalização

- Sem diferença de **maiúsculas** e de **acentos**, nos dois sentidos:
  "conexão", "conexao", "CONEXÃO" e "Conexao" são a mesma palavra, no texto e
  na consulta.
- **Radical no idioma padrão da conta** (português na EARJ): plural e
  variações simples casam ("impressoras" acha "impressora"; "configurações"
  acha "configuração").
- **Forma simples**: além do radical, o texto dos tickets é indexado palavra
  por palavra, sem radical. Assim, uma palavra de outro idioma (a EARJ atende
  também em inglês) é achada quando a consulta usa a mesma palavra: "printer"
  acha "printer". Radical em inglês para o texto de tickets fica no roadmap.
- **Palavras vazias** do idioma padrão ("de", "o", "para") são ignoradas na
  busca por palavra. Uma consulta feita só de palavras vazias não filtra por
  texto: devolve o mesmo que a consulta sem texto (só os filtros), e a
  interface avisa que os termos foram ignorados.
- Endereços de e-mail, números e códigos (ex.: "NF-4471") são preservados
  inteiros como termos, além de quebrados em partes, para que "NF-4471" e
  "4471" achem o mesmo ticket.
- Na KB (spec 07 §6), cada tradução é indexada com o dicionário do **idioma
  dela** (português ou inglês).
- A mesma normalização vale para a busca da KB e do portal (§8).

---

## 4. Sintaxe da consulta

A caixa de busca aceita **texto livre** e **filtros de campo**, misturados em
qualquer ordem. Não há operadores OU entre termos, parênteses, curingas,
expressões regulares nem busca aproximada no MVP.

### 4.1 Texto livre

| Forma | Significado |
|---|---|
| `vpn lenta` | ticket que contém **todas** as palavras (E), em qualquer campo do §3.1, não necessariamente no mesmo campo |
| `"acesso negado"` | a frase exata (palavras vizinhas, na ordem), depois da normalização |
| `-impressora` | ticket que **não** contém a palavra |
| `1000`, `#1000`, `PD-1000` | também testa o número do ticket (§3.1) |

- Várias palavras = E. A escolha é deliberada: um dos projetos usa OU entre as
  palavras, o que aumenta muito o número de resultados irrelevantes numa
  caixa de entrada grande.
- Aspas não fechadas: tratadas como se fechassem no fim da consulta.
- Consulta só com exclusões (`-impressora`): devolve os tickets visíveis que
  não contêm o termo, ordenados como se não houvesse texto (§7).

### 4.2 Filtros de campo

Forma: `campo:valor`. Vários valores no mesmo filtro, separados por vírgula,
valem como **OU dentro do campo** (`estado:aberto,pendente`).

| Filtro | Valores aceitos |
|---|---|
| `estado` | aberto, pendente, em-espera (também `"em espera"`), resolvido, fechado, mesclado |
| `grupo` | nome do grupo; `meus` (grupos em que quem consulta tem leitura ou escrita; para admin, todos) |
| `responsavel` | e-mail ou nome do agente; `eu`; `nenhum` |
| `seguidor` | e-mail ou nome do agente; `eu` (spec 13 Δ6) |
| `encaminhado` | `sim` (tem encaminhamento com retorno ativo, Δ5); `eu` (encaminhado por quem consulta); `meus` (o grupo de origem é um dos grupos em que quem consulta tem leitura ou escrita); nome do grupo de origem |
| `solicitante` | e-mail ou nome |
| `organizacao` | nome; `nenhuma` |
| `etiqueta` | etiqueta (normalizada); `nenhuma` |
| `prioridade` | baixa, normal, alta, urgente |
| `tipo` | pergunta, incidente, problema, tarefa, evento; `nenhum` (spec 13 Δ8, D56) |
| `canal` | canal de origem do ticket (spec 03 §2.1): email, formulario, portal, chat, agente, api, sistema |
| `criado`, `atualizado`, `resolvido`, `avaliado` | data `AAAA-MM-DD` (o dia inteiro), intervalo `AAAA-MM-DD..AAAA-MM-DD`, com uma das pontas aberta (`..AAAA-MM-DD`, `AAAA-MM-DD..`), ou relativo em dias (`7d`) ou horas (`12h`) |
| `avaliacao` | 1, 2, 3, 4, 5; `satisfeito` (4 ou 5); `insatisfeito` (1 a 3); `nenhuma` (spec 13 Δ15) |
| `numero` | número do ticket |
| `tem` | `anexo`, `nota` (tem nota interna), `conversa-paralela`, `sem-resposta` (indicador "sem primeira resposta", spec 01 §4.1), `resolvido-pelo-solicitante` (a última ida para resolvido foi a ação do solicitante, D33), `fora-do-prazo` (pedido de evento enviado abaixo da antecedência mínima, spec 07 §8.9), `pronto` (ticket de evento com a marca "pronto para o evento", D44, spec 01 §5.2) |
| `campus`, `predio`, `andar` | nome do nível no cadastro de locais (spec 13 Δ33); `nenhum` (ticket sem local) |
| `sala` | código da sala ou nome atual; `nenhuma` |
| `sla` | `vencido` (alguma métrica ativa, não pausada, passou do vencimento e não foi cumprida); `Nhu`, ex. `1hu` (a próxima métrica ativa vence nas próximas N horas **úteis**, sem incluir as vencidas); `pausado` (só métricas pausadas); `nenhum` (sem métrica ativa nem pausada). Para ticket de evento, a 1ª resposta é uma métrica comum, e o **prazo da montagem** conta como métrica ativa enquanto não houver a marca "pronto": vence no início da montagem e deixa de contar com a marca ou no fim do evento (D40, §9.3) |
| `evento` | `sim` (ticket de evento, spec 07 §8.9); `nao` |
| `tipo-evento` | assembly, homecoming, traducao-simultanea, entre-campi, pequeno-evento, outro |
| `data-evento` | data do evento: `AAAA-MM-DD`, intervalo com pontas opcionais (como `criado`), `Nd` (de hoje − N dias até hoje) ou `+Nd` (de hoje até hoje + N dias), sempre em dias inteiros |
| `incidente` | `pai` (ticket marcado como incidente); `filho` (vinculado a um pai); número do pai (os filhos dele) (spec 13 Δ35) |

Significado dos filtros de momento:
- `criado`: criação do ticket. `atualizado`: última mudança (§7).
- `resolvido`: a **última** ida do ticket para resolvido, seja qual for o
  estado atual. Ticket nunca resolvido não casa.
- `avaliado`: o momento em que a avaliação atual do ticket foi gravada ou
  alterada pela última vez (spec 07 §8.7).
- Relativo: `Nd` = de agora menos N × 24 h, **inclusive**, até agora; `Nh` = de
  agora menos N horas, inclusive, até agora. "Agora" é o momento em que a
  consulta é executada: uma fila com filtro relativo é recalculada a cada
  abertura.

Regras:
- Nomes de filtro e valores fixos aceitam acento ou não e qualquer caixa
  (`Organização:` = `organizacao:`).
- Datas são interpretadas no **fuso do usuário** que consulta; "o dia inteiro"
  vai de 00:00 a 23:59:59 nesse fuso.
- **Filtros diferentes combinam por E.** Repetir o mesmo filtro
  (`estado:aberto estado:pendente`) também combina por E (e, nesse exemplo,
  não devolve nada); a interface sugere a forma com vírgula.
- Valor desconhecido para filtro de lista fixa (`estado:xyz`) ou data inválida:
  **erro na consulta** que indica o filtro e os valores aceitos; nenhuma busca
  é executada. Na API, a resposta é **400** com o filtro nos detalhes
  (spec 10 §5.2).
- Valor que aponta para entidade inexistente (`grupo:Marketing`, sem esse
  grupo): não é erro; o filtro casa com nada, e o resultado é vazio.
- Prefixo desconhecido (`cor:azul`): **não** é erro; o texto inteiro é tratado
  como texto livre.
- Valor com espaço vai entre aspas: `grupo:"Suporte N1"`.
- `grupo:meus` para admin: todos os grupos, porque o admin tem escrita em
  todos (D06).
- Campos personalizados do ticket entram como filtro pelo nome estável (a
  chave) do campo: `produto:vpn` para lista (pela chave da opção, spec 01 §5),
  com os mesmos formatos de data e número dos filtros acima para os outros
  tipos.
- Campos personalizados da **Pessoa** do solicitante e da **Organização**
  (Δ22) entram com prefixo: `solicitante.cargo:professor`,
  `organizacao.segmento:fornecedor`. Mesmas regras de tipo dos campos de
  ticket. O local do ticket nunca é campo personalizado: usa os filtros de
  local abaixo (D51).
- **Local** (Δ33): o filtro usa o local gravado no ticket. `sala` aceita o
  código (estável) ou o **nome atual** da sala; o nome antigo de uma sala
  renomeada não casa mais. Sala desativada continua casando com os tickets
  que a têm. `campus`, `predio` e `andar` casam com todas as salas daquele
  nível. Nome de nível ou sala inexistente: casa com nada, sem erro (como
  `grupo`).
- **`sla:Nhu`** (Δ37): as horas úteis são contadas, a partir de agora, pelo
  calendário da política de SLA da métrica (spec 05); para o prazo de evento,
  pelo calendário do grupo do ticket. N é inteiro de 1 a 99. Métrica pausada
  não casa com `Nhu` nem com `vencido`.
- **`data-evento`** é uma data no **fuso da conta** (o evento acontece na
  escola, spec 07 §8.9), não no fuso de quem consulta; os valores relativos
  contam dias inteiros a partir de hoje nesse fuso, com as duas pontas
  inclusive.
- **`incidente`** devolve só tickets visíveis (§5): `incidente:1810` traz os
  filhos de #1810 que quem consulta pode ver, e nada se #1810 for invisível.

**Ticket encaminhado com retorno** (spec 13 Δ5, D23): o ticket tem **um único
estado**. Enquanto o encaminhamento estiver ativo, ele está **aberto** (ou no
estado em que o grupo de destino o puser) e pertence ao grupo de **destino**:
`grupo` e `estado` casam só com esses valores reais, e ele nunca conta como em
espera nem como do grupo de origem. Para o grupo de origem, ele aparece pela
marca derivada **"encaminhado"**, calculada do registro de origem: o filtro
`encaminhado` (`sim`, `eu`, `meus` ou o nome do grupo de origem) é a forma de
montar a fila da origem. Em qualquer resultado em que apareça, o ticket aparece
**uma vez só**, com a marca "encaminhado por {agente} de {grupo}". Quem
consegue ver o ticket é definido pela spec 06 §3 (D24); a busca só aplica essa
regra.

### 4.3 Filtros estruturados (interface e API)

Os mesmos filtros do §4.2 existem como controles na interface e como
parâmetros na API (spec 10). A caixa de texto e os controles produzem a
**mesma consulta**: qualquer combinação montada nos controles pode ser
representada como texto, e vice-versa. Isso permite colar uma consulta num chat
e obter o mesmo resultado.

---

## 5. Permissões nos resultados

- A busca aplica **as mesmas regras de acesso** das listas e da abertura de
  ticket (spec 06 §6.3): o agente vê os tickets dos grupos em que tem
  **leitura ou escrita**, mais os tickets encaminhados com retorno em que ele é
  o agente de origem ou tem leitura ou escrita no grupo de origem, enquanto o
  encaminhamento estiver ativo (D24, spec 06 §3); o admin vê todos. Um recurso
  sem acesso responde como inexistente (D05).
- O filtro de permissão é aplicado **antes** de contar, ordenar, agrupar,
  paginar e montar trechos. Em consequência:
  - um ticket invisível nunca aparece, nem em outra página;
  - o **total**, as contagens por fila e por grupo de agrupamento incluem só
    tickets visíveis;
  - nenhum trecho, título ou nome vem de ticket invisível.
- A busca pelo número exato de um ticket invisível responde igual à busca por
  um número inexistente (lista vazia), sem indicar que ele existe.
- Retirar o agente de um grupo tem efeito **na próxima consulta**: nada de
  cache de resultado ou de permissão que sobreviva à mudança.
- Filas compartilhadas (§9) são executadas **com as permissões de quem
  visualiza**, nunca de quem criou.
- Os mesmos princípios valem na API, com o token limitado às permissões atuais
  do dono (D14; spec 06 §7, spec 10).

---

## 6. Consistência da indexação

- Uma mudança gravada (ticket criado, mensagem adicionada, assunto, etiqueta,
  campo, grupo, responsável, estado, seguidor, encaminhamento, avaliação,
  mescla, campo da Pessoa, local, dados do evento, vínculo de incidente,
  renomeação de sala) está refletida na busca **para qualquer consulta que
  comece depois do fim da transação** que a gravou.
- Não há tarefa em segundo plano de indexação no MVP, nem comando de
  "reindexar" exposto ao admin; se o implementador precisar de uma rotina de
  reconstrução por motivo técnico, ela não pode deixar a busca incompleta
  enquanto roda.
- Uma mudança desfeita (transação abortada) **nunca** aparece na busca.
- Mescla (spec 01 §6): na mesma transação, o texto das mensagens da origem
  passa a contar para o **destino**; a origem fica com estado mesclado.
- A busca da KB segue a mesma regra: publicar, arquivar ou mudar a visibilidade
  de um artigo vale na próxima consulta (spec 07 §3.3).

---

## 7. Relevância e ordenação

- **Com texto livre**, o padrão é **relevância**: casamento exato de número
  primeiro; depois a soma ponderada dos campos (§3.1), em que um termo no
  assunto vale mais que o mesmo termo em uma mensagem; frase exata vale mais
  que palavras espalhadas; casamento por radical e pela forma simples somam.
- **Sem texto livre**, o padrão é **última atualização**, mais recente primeiro.
- Opções de ordenação, em qualquer caso:

| Ordenação | Definição |
|---|---|
| relevância | acima (só disponível com texto livre) |
| última atualização | momento da última mudança no ticket (mensagem, campo ou estado) |
| criação | momento da criação |
| prioridade | urgente → baixa |
| número | número do ticket (D32) |
| na fila há mais tempo | momento em que o ticket passou, pela última vez, a estar sem responsável no grupo atual, mais antigo primeiro; tickets com responsável vão para o fim (é a ordem da fila da spec 04 §3) |
| aguardando resposta há mais tempo | tickets cuja última mensagem pública é do solicitante ou de um participante, pela espera mais antiga primeiro; os demais vão para o fim |
| última atividade do solicitante | momento da última mensagem pública do solicitante ou de um participante; sem nenhuma, vai para o fim |
| no estado atual há mais tempo | momento da última mudança de estado, mais antigo primeiro |
| vencimento do SLA | o vencimento **mais próximo entre as métricas ativas** do ticket (Δ14; métricas na spec 05): métrica em andamento, inclusive a que já venceu e ainda não foi cumprida. Para ticket de evento, contam a 1ª resposta e o prazo da montagem, este enquanto não houver a marca "pronto" e o evento não tiver terminado, com vencimento no início da montagem (D40, §4.2, §9.3). Vencido há mais tempo primeiro, depois os que vencem mais cedo. Métrica pausada não tem vencimento enquanto estiver pausada; ticket só com métricas pausadas, ou sem SLA, vai para o fim |
| data do evento | início do evento (data e hora, fuso da conta); tickets que não são de evento vão para o fim (Δ34) |
| coluna da fila | qualquer coluna do §9.3 com ordem natural (texto em ordem alfabética sem diferença de acento; número; data; listas na ordem das opções) |

- Cada ordenação pode ser crescente ou decrescente, exceto relevância. "Para o
  fim" vale nos dois sentidos.
- **Desempate** sempre pelo número do ticket, decrescente. A ordem é total e
  estável: a mesma consulta, sobre os mesmos dados, devolve sempre a mesma
  sequência. Na API, o número faz o papel de desempate estável da spec 10 §5.2.
- A **API oferece as mesmas ordenações** desta tabela, inclusive vencimento do
  SLA, prioridade, número, na fila há mais tempo e data do evento, com o mesmo
  desempate (D32). Ordenação desconhecida na API → **400**.
- Tickets **mesclados** ficam fora dos resultados, a menos que a consulta peça
  `estado:mesclado`. Tickets fechados como spam (spec 01 §4.1) aparecem como
  qualquer fechado.
- Cada resultado traz: número, assunto, estado, grupo, responsável,
  solicitante, última atualização e, com texto livre, **um trecho** com os
  termos destacados, tirado do campo de maior peso que casou. Se o trecho vier
  de uma nota interna ou de uma conversa paralela, ele é marcado como tal.

---

## 8. Busca no portal (solicitante)

Quem é visitante, solicitante logado e convidado: spec 07 §7.0.

- O solicitante tem **uma caixa de busca** que devolve duas seções: **pedidos**
  e **artigos**.
- **Pedidos**: só os tickets que ele pode ver pelo portal (spec 07 §8.1: os
  seus, aqueles em que participa como participante confirmado e, se o
  compartilhamento da organização valer para ele, "só gestores" ou "todos os
  membros", os da organização). O texto pesquisado é só: número, assunto,
  mensagens **públicas**, campos marcados como visíveis ao solicitante, o
  nome atual da sala do ticket (Δ33) e os dados de evento que ele vê (spec 07
  §8.3).
  **Nunca** notas internas, conversas paralelas, mensagens de sistema internas,
  etiquetas, nomes de grupo, seguidores, campos só de agente, campos da Pessoa,
  nem dados de outras pessoas além dos que ele já vê no ticket.
- Trechos para o solicitante vêm só de texto que ele pode ver.
- Sintaxe no portal: só texto livre, aspas e exclusão (§4.1), mais o filtro de
  estado da lista: **em andamento** (aberto, pendente, em espera) /
  **encerrados** (resolvido, fechado) / todos. Os filtros de campo do §4.2 são
  tratados como texto livre. O resultado mostra o estado de exibição do portal
  (spec 07 §8.3): "em espera" nunca aparece.
- **Artigos**: artigos publicados visíveis para ele (spec 07 §2.3), pela
  revisão atual da tradução de exibição (spec 07 §2.5), com o dicionário do
  idioma dessa tradução.
- **Visitante anônimo**: só artigos públicos (e só se a KB estiver acessível
  sem login). Não há busca de pedidos.
- **Convidado** de um único ticket (spec 07 §7.3): sem busca de pedidos; artigos
  como o visitante anônimo.
- Agente ou admin no portal como solicitante (spec 07 §7.1): mesmas regras do
  solicitante; nada da área de atendimento entra.
- Ordenação: relevância; sem texto, a ordem das listas do portal.

---

## 9. Filas salvas e trabalho em fila

### 9.1 Conceito

Uma **fila salva** (chamada de "visão" na v0.1) é uma consulta salva com nome:
texto livre e filtros (§4), uma ordenação (§7), as colunas exibidas, na ordem,
e um agrupamento opcional (§9.3). Abrir a fila executa a consulta agora, com as
permissões de quem abre (§5), e mostra a **contagem**.

| Tipo | Quem cria e edita | Quem vê |
|---|---|---|
| **Pessoal** | o próprio agente; até **10** por agente | só ele |
| **Compartilhada** | só o admin | todos os agentes, ou só os membros (leitura ou escrita) dos grupos escolhidos pelo admin; o admin vê todas |
| **Padrão** | o sistema (o admin pode ocultar, não excluir) | todos os agentes |

Filas padrão (todas excluem mesclados; as três primeiras são as visões da spec
04 §3, a quarta vem da spec 13 Δ37):
1. **Meus tickets**: `responsavel:eu estado:aberto,pendente,em-espera`,
   ordenada por última atividade do solicitante, mais antiga primeiro.
2. **Fila dos meus grupos**: `responsavel:nenhum estado:aberto grupo:meus`,
   ordenada por "na fila há mais tempo".
3. **Todos dos meus grupos**: `grupo:meus`, ordenada por última atualização,
   mais recente primeiro.
4. **Quase escalando** (spec 13 Δ37): `sla:vencido,1hu`, ordenada por
   vencimento do SLA, crescente (o vencido há mais tempo primeiro, depois o
   que vence mais cedo). Tickets resolvidos e fechados não têm métrica ativa e
   nunca entram. Um ticket de evento entra pela 1ª resposta, como qualquer
   ticket, ou quando, **sem a marca "pronto"**, a montagem começa em até 1
   hora útil (calendário do grupo do ticket) ou já começou e o evento ainda não
   terminou (D40). O limiar de 1 hora útil é o do aviso da EARJ (Δ14); os avisos
   por e-mail ao responsável e ao gestor não mudam.

Filas compartilhadas dos dados de demonstração da EARJ (spec 13 Δ9 e §4):

| Fila | Consulta | Agrupamento e ordem |
|---|---|---|
| Não resolvidos por estado | `estado:aberto,pendente,em-espera` | por estado; última atualização |
| Triagem | `responsavel:nenhum estado:aberto tem:sem-resposta` | na fila há mais tempo |
| Meus tickets | `responsavel:eu estado:aberto,pendente,em-espera` | última atividade do solicitante |
| Abertos por responsável | `estado:aberto` | por responsável; vencimento do SLA |
| Pendentes por responsável | `estado:pendente` | por responsável; no estado atual há mais tempo |
| Em espera nos meus grupos | `estado:em-espera grupo:meus` | no estado atual há mais tempo (mais antigos primeiro) |
| Sem responsável | `responsavel:nenhum estado:aberto,pendente,em-espera` | na fila há mais tempo |
| Resolvidos nas últimas 12 h | `resolvido:12h` | última atualização |
| Avaliados nos últimos 7 dias | `avaliado:7d` | por avaliação, de 1 a 5; última atualização |

### 9.2 Regras

- O valor `eu` (e `grupo:meus`) é resolvido **para quem abre** a fila. Uma
  única fila compartilhada "Meus tickets" mostra a cada agente os seus.
- Cada agente pode mudar ordenação, colunas e agrupamento **ao abrir** uma
  fila compartilhada; isso não altera a fila para os outros. "Salvar como
  pessoal" cria uma cópia pessoal com essas mudanças (contando no limite de
  10).
- Só o admin cria, altera ou exclui uma fila compartilhada. A alteração vale
  para todos na próxima abertura. Agente que tenta é recusado (403, D05).
- Fila compartilhada restrita a grupos: um agente que não é membro de nenhum
  desses grupos não a vê na lista e, ao abri-la pelo endereço ou pela API,
  recebe "não encontrado". Deixar de ser membro tem efeito na próxima consulta.
- A contagem é calculada com as permissões de quem vê (§5) e recalculada a
  cada abertura; a lista de filas mostra a contagem de cada fila visível.
  Filtros relativos ao tempo (§4.2) são recalculados a cada abertura.
- Se um filtro de fila aponta para algo que deixou de existir (grupo
  excluído, agente desativado, opção de campo removida), a fila continua
  abrindo; aquele filtro casa com nada, e a interface mostra um aviso para
  quem pode editar a fila. A fila nunca passa a mostrar **mais** tickets por
  causa disso.
- Fila com filtro inválido para os valores atuais (ex.: estado que deixou de
  existir num futuro com estados personalizados) também segue a regra acima.
- Limites: até **10** filas pessoais por agente (Δ9) e 100 compartilhadas por
  conta. Acima do limite, a criação é recusada com a indicação do limite.
- No portal, o solicitante não salva filas no MVP (roadmap).

### 9.3 Colunas e agrupamento

Colunas disponíveis: número, assunto, solicitante, organização, grupo,
responsável, estado, prioridade, tipo, qualquer campo personalizado do ticket,
criado em, atualizado em, **selo de prazo** (antes "vencimento do SLA"),
última atividade do solicitante, **local** (sala, com campus e andar), **data
do evento**, **tipo de evento** e **incidente**.
- **Selo de prazo** (spec 13 Δ37): aparece em **toda linha** de toda fila, na
  tabela e nos cartões, e não pode ser retirado das colunas (na tabela, o
  agente só muda a posição dele). Mostra o prazo da próxima métrica ativa, o
  mesmo valor da ordenação do §7:
  - "vence em X" ou "vencido há X", com X = diferença em **tempo corrido** entre
    agora e o vencimento, em minutos, horas ou dias. "Vencido há" usa o
    **vermelho** de atenção (spec 13 Δ30) e sempre o texto escrito (a cor
    nunca é a única indicação);
  - "pausado", quando só há métricas pausadas;
  - vazio, sem SLA;
  - **ticket de evento** (Δ34, D40), nesta ordem:
    1. depois do fim do evento: "evento encerrado";
    2. com a marca "pronto para o evento" (D44): "pronto";
    3. montagem já iniciada sem a marca: "montagem sem pronto", em vermelho;
    4. antes do início da montagem, com os valores da spec 05 §7.15 (D54):
       faltando 24 h ou mais, "faltam N dias para a montagem" (N = data local
       da montagem − data local de hoje, em dias corridos, no fuso da conta);
       faltando menos de 24 h, "faltam N h para a montagem" (horas inteiras
       restantes, arredondadas para baixo); abaixo de 1 h, "falta menos de 1 h
       para a montagem"; com N = 1, o singular.

    A 1ª resposta do evento não muda o selo: enquanto ela falta, a linha
    mostra o indicador "sem resposta" (abaixo), e o prazo dela conta em
    `sla`, na ordenação e em "Quase escalando". Pedido "fora do prazo" mostra
    também essa marca.
- **Aberto sem resposta** (spec 13 Δ30): ticket **aberto** com o indicador
  "sem primeira resposta" (spec 01 §4.1, filtro `tem:sem-resposta`) mostra, na
  coluna de estado e nos cartões, o rótulo "sem resposta" em vermelho, sempre
  escrito. Some na primeira resposta pública de agente.
- **Incidente**: no pai, "incidente · N filhos", com N = filhos que quem olha
  pode ver (spec 06 §3); no filho, "filho de #N", com o número só se o pai for
  visível. A tela do pai mostra os **locais afetados**: as salas do pai e dos
  filhos visíveis, sem repetição (D48).
- O ticket encaminhado com retorno (§4.2) mostra, na coluna de estado, o
  estado real e a marca "encaminhado por {agente} de {grupo}", em qualquer
  fila em que apareça (do destino ou da origem, D23).
- O ticket resolvido pela ação do solicitante mostra, na coluna de estado, a
  marca "resolvido pelo solicitante" (D33).

Agrupar por: estado, responsável, grupo, prioridade, tipo, campus, sala, tipo
de evento ou campo personalizado de lista de escolha única. Campus e sala
seguem a ordem do cadastro de locais, com "sem local" no fim; tipo de evento
segue a ordem da lista do §4.2, com "não é evento" no fim. Regras:
- Cada grupo de agrupamento mostra a sua contagem; dentro dele vale a
  ordenação da fila.
- Ordem dos grupos: estado na ordem da spec 01 (aberto, pendente, em espera,
  resolvido, fechado, mesclado); prioridade de urgente a baixa; tipo e listas
  na ordem das opções, com "sem valor" no fim; responsável com "sem
  responsável" primeiro e depois os nomes em ordem alfabética; grupo em ordem
  alfabética.
- No agrupamento por estado ou por grupo, o ticket encaminhado com retorno
  entra pelo estado real e pelo grupo de destino, como qualquer ticket (D23);
  a marca "encaminhado" não forma grupo próprio.
- A paginação percorre os grupos em ordem, sem repetir nem pular tickets.

### 9.4 Modo sequência (Δ9)

- A partir de uma fila, o agente entra em **modo sequência**: abre o primeiro
  ticket da fila e, ao **enviar** (resposta ou nota, com ou sem mudança de
  estado) ou **pular**, o próximo abre sozinho, sem voltar à lista.
- "Próximo" = a fila é executada de novo naquele momento, com as permissões
  atuais, e abre o primeiro ticket na ordem da fila que ainda não foi aberto
  nem pulado nesta sequência. Assim, tickets que saíram da fila (ex.: foram
  atribuídos) não voltam, e tickets novos entram na posição que a ordem der.
- Ticket que **outro agente está vendo** naquele momento (presença, spec 09) é
  **pulado** e conta como pulado nesta sequência; o agente recebe um aviso com
  o número dele.
- Quando não sobra ticket, a sequência termina e mostra em quantos o agente
  enviou e quantos foram pulados (por ele ou por presença), voltando à lista.
- Sair da sequência a qualquer momento não desfaz nada. O rascunho de cada
  ticket segue as regras do editor (Δ19).

### 9.5 Edição em massa (Δ9)

- Sobre tickets selecionados numa fila ou num resultado de busca, **até 100
  por vez** (o mesmo máximo de página, D15). Seleção acima disso é recusada
  antes de executar, sem alterar nada.
- Ações: atribuir (a um agente, a "eu" ou a ninguém), mudar grupo, estado ou
  prioridade, adicionar e remover etiquetas, aplicar macro (spec 05, Δ10).
- Execução **ticket a ticket**, cada um com as mesmas validações e efeitos de
  uma ação individual: permissão de escrita (spec 06), matriz de transições e
  campos obrigatórios (spec 01 §4.2), responsável obrigatório (Δ4), regras de
  atribuição (spec 04). Cada ticket é uma operação atômica; a falha de um não
  afeta os outros.
- A seleção guarda a **versão** de cada ticket como estava na lista (D01). Um
  ticket alterado por outra pessoa depois disso falha com "alterado por outra
  pessoa" e entra na lista de falhas.
- Aplicar macro em massa: a prévia mostra as ações da macro e o texto com as
  variáveis de um ticket de exemplo; depois de confirmar, as variáveis são
  resolvidas **por ticket**. Uma macro com resposta pública envia um e-mail por
  ticket.
- Cada ticket gera os **seus** eventos de auditoria (marcados "via edição em
  massa"), a sua passada de gatilhos e as suas notificações (sem notificar o
  autor, D12).
- O resultado mostra quantos foram alterados e a lista dos que falharam, cada
  um com o motivo.

### 9.6 Contexto na tela do ticket (Δ18)

O painel de contexto usa a mesma interface de busca e as permissões de quem
está vendo o ticket:
- **Tickets anteriores do solicitante**: os últimos 10 tickets dele, por
  criação, mais recente primeiro, com estado, excluindo o ticket atual e os
  mesclados. Só entram tickets visíveis a quem vê; não há indicação de quantos
  ficaram de fora.
- **Tickets relacionados**: até 5 tickets visíveis, excluindo o atual, os
  mesclados e os que já estão em "tickets anteriores". Candidatos: tickets que
  têm ao menos uma palavra significativa do assunto do atual (depois da
  normalização do §3.2, sem palavras vazias). Pontuação: número de palavras
  do assunto em comum, mais 1 por campo de classificação com o mesmo valor
  (campos personalizados de lista que estão no formulário do portal; na EARJ,
  motivo, equipamento e sintoma; o local vem do cadastro e não é campo
  personalizado, D51). Empate: última atualização mais
  recente.
- **Artigos**: busca na KB com as regras da spec 07 §6.1 (artigo interno pode
  ser lido, mas não inserido em resposta pública).
- Dados e campos da Pessoa e da Organização (Δ22): não são busca; vêm do
  cadastro (spec 01).

### 9.7 Calendário de eventos (spec 13 Δ34)

- É uma **visão** sobre a consulta `evento:sim` mais o intervalo de
  `data-evento` da tela, executada com as permissões de quem vê (§5; spec 06
  §6.3). Só agentes e admin; o solicitante não tem calendário.
- Visões de **mês** e de **semana**. A semana vai de segunda a domingo. Datas e
  horas no **fuso da conta** (§4.2).
- Cada evento aparece no dia do início, com nome, horário, local, estado e o
  selo de prazo (§9.3); na visão de semana, a faixa da montagem aparece antes
  do evento. Um evento que passa da meia-noite aparece só no dia do início,
  com o horário de fim.
- Na visão de mês, cada dia mostra até **3** eventos, por horário de início, e
  "mais N" para o resto; a contagem do dia inclui só eventos visíveis.
- Filtros da tela: **campus** e **tipo de evento**, mais qualquer filtro do
  §4.2 (por exemplo, `responsavel:eu` ou `tem:fora-do-prazo`). Todos os estados
  aparecem, exceto mesclado; um filtro rápido esconde resolvidos e fechados.
- Abrir um evento abre o ticket. O ticket de evento também aparece nas filas
  normais; o calendário não é uma fila e não tem modo sequência nem edição em
  massa.
- Na API, o calendário é a **busca comum** de tickets com `evento:sim` e um
  período em `data-evento`, ordenada pela data do evento (§7). Não existe
  recurso separado de calendário (D50).

### 9.8 Lista da sala (QR aberto por agente, spec 13 Δ33)

- Quando um agente abre o QR de uma sala (spec 07 §8.8), a área do agente
  mostra a consulta `sala:<código> estado:aberto,pendente,em-espera`, ordenada
  por vencimento do SLA, com as permissões dele (§5) e o selo de prazo.
- Cada linha tem "assumir"; a tela tem "novo ticket com este local". Ticket
  que o agente não pode ver não aparece nem na contagem.

---

## 10. Paginação

- Paginação por **cursor**: cada página traz um cursor opaco para a próxima.
  Tamanho padrão de página 25; máximo 100. Na API, pedido acima de 100 →
  **400** (D15, spec 10 §5.1); a interface nunca pede mais que 100.
- Com ordem total e estável (§7), avançar páginas com cursor **não duplica nem
  pula** tickets que não mudaram durante a navegação.
- Um ticket que muda o valor da chave de ordenação durante a navegação (por
  exemplo, recebe mensagem numa lista por "última atualização") pode aparecer
  de novo numa página seguinte ou não aparecer; isso é aceito e documentado na
  API. Tickets criados depois da primeira página não entram nas páginas
  seguintes de uma ordenação decrescente por criação.
- O **total** é exato até 10.000; acima disso, a resposta informa "mais de
  10.000" sem o número exato.
- O cursor é ligado à consulta e à ordenação que o geraram e vale por
  **24 h**. Cursor vencido, adulterado, de outra conta ou de outra consulta:
  **400** na API (spec 10 §5.1); nunca devolve dados de outra consulta. A
  interface recomeça a lista do início.
- Desempenho esperado no MVP (meta, não critério de aceite automatizado):
  com 500 mil tickets e 5 milhões de mensagens, primeira página em até 1 s no
  percentil 95.

### 10.1 Roadmap da busca
- Conteúdo de anexos, com indicação de atraso de indexação.
- Busca aproximada (tolerância a erro de digitação) e sugestão "você quis
  dizer".
- Operadores OU e parênteses.
- Radical em inglês (e outros idiomas) para o texto de tickets.
- Motor externo, atrás da mesma interface (§2), quando o volume ou os
  recursos acima justificarem.
- Filas salvas pelo solicitante no portal.

A exportação CSV de uma lista de tickets **não** é roadmap: é a da spec 11, e
usa a mesma consulta, as mesmas permissões e a mesma ordem desta spec.

---

## 11. Abordagens comparadas

| Projeto | Abordagem (documentação pública) | Prós | Contras |
|---|---|---|---|
| **Zammad** | índice de busca externo opcional, mas fortemente recomendado; sem ele a busca fica limitada. Indexa tickets, mensagens, pessoas, organizações e conteúdo de anexos. Sintaxe rica, com campo:valor, OU, curingas, busca aproximada e datas relativas. Listas de trabalho definidas pelo admin por papel, com colunas, agrupamento e ordenação iguais para todos; ações em massa | escopo amplo; anexos pesquisáveis; listas com agrupamento | um serviço a mais para operar; indexação em segundo plano; sintaxe difícil para a maioria dos agentes; sem lista pessoal documentada |
| **Chatwoot** | busca de conversas, contatos e artigos por texto livre; filtros por atributo e operador; filtro salvo vira pasta lateral; quatro modos de ordenação, incluindo "aguardando resposta"; ações em massa sobre conversas; filtros avançados de mensagem em planos pagos | ordenação "aguardando" muito útil; filtros salvos simples | sintaxe e motor não documentados; parte dos filtros fora da edição comunitária |
| **FreeScout** | busca no banco por padrão, que fica lenta em volume; módulo pago com motor externo, indexação em segundo plano (segundos a um minuto), palavras combinadas por OU; pastas fixas no núcleo, pastas por condição em módulo pago; resultados incluem conversas excluídas por padrão | o núcleo não depende de serviço externo | OU entre palavras gera ruído; listas por condição pagas; excluídos aparecem por padrão |
| **osTicket** | busca avançada por critérios de ticket, usuário, organização e formulários; buscas salvas com nome; filas pessoais com colunas; exportação em planilha | buscas salvas e filas pessoais com colunas | escopo de texto e normalização não documentados |
| **Znuny** | busca de texto completo refinável por atributos; perfis de busca salvos com link direto; E, OU, curinga e exclusão; ação em massa sobre tickets selecionados; exportação em vários formatos; o cliente também busca e salva modelos | perfis salvos; ação em massa; exportação | sintaxe extensa; motor externo só por projeto separado |
| **UVdesk** | nada documentado sobre busca e filtros | — | comportamento desconhecido até o runtime |
| **Frappe Helpdesk** | visões com filtros, ordenação e colunas; pessoais, públicas (só gestor de agentes cria) e fixadas; valor "eu" no filtro de responsável; cliente salva visões no portal; a busca da KB depende de serviço externo e não devolve nada sem ele | modelo de visões completo; "eu" dinâmico | busca de texto de tickets não documentada; dependência externa na KB |

**Escolha PantherDesk e motivos**:
- **Motor**: PostgreSQL, com texto completo no idioma da conta mais a forma
  simples, remoção de acentos e trigramas (§2). Consistência imediata e
  permissão na mesma consulta, sem serviço externo, ao contrário de Zammad,
  FreeScout (módulo) e Frappe.
- **Escopo**: assunto, mensagens, notas e conversas paralelas (para agentes),
  pessoas, etiquetas, campos e nome de anexo. Conteúdo de anexo no roadmap,
  porque é o que exige indexação assíncrona.
- **Sintaxe**: pequena: palavras combinadas por E, aspas, exclusão e uma lista
  fixa de filtros `campo:valor`. Fica entre o texto livre puro (Chatwoot,
  FreeScout) e a sintaxe completa de Zammad e Znuny.
- **Ordenação**: relevância e as ordens de trabalho, incluindo "aguardando
  resposta há mais tempo" (como Chatwoot) e vencimento do SLA.
- **Filas**: pessoais e compartilhadas, com "eu" dinâmico (como Frappe),
  colunas (como osTicket) e agrupamento (como Zammad), executadas com as
  permissões de quem vê; edição em massa ticket a ticket (como as ações em
  massa de Zammad, Chatwoot e Znuny), com resultado por ticket.
- **Portal**: o solicitante busca só os próprios pedidos e os permitidos, e só
  em texto público.

---

## 12. Casos de teste (critérios de aceite)

Atores: `ag1` e `ag2` (grupo N1, de nome "Suporte N1", escrita), `ag3` (grupo
Financeiro, escrita), `admin`, solicitantes `ana` e `bia` (org. Acme), `cris`
(sem org.), e `visitante` (anônimo). Fuso dos usuários: America/Sao_Paulo
(UTC−3). Base de dados, salvo indicação:
- #1800 (Suporte N1, ana, aberto, responsável ag1): assunto "Conexão lenta na
  VPN"; mensagem pública de ana "a VPN cai toda tarde"; nota interna de ag1
  "verificar firewall-xz9 no roteador"; etiqueta "vpn".
- #1801 (Suporte N1, bia, pendente, sem responsável): assunto "Impressora do 3º
  andar"; mensagem pública "a impressora não imprime frente e verso".
- #1802 (Financeiro, cris, aberto, responsável ag3): assunto "Fatura NF-4471
  duplicada"; anexo "fatura-4471.pdf".
- #1803 (Suporte N1, ana, fechado, sem responsável): assunto "Senha expirada".

### 12.1 Escopo e normalização
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-01 | base | ag1 busca "conexao" | #1800 |
| BU-02 | base | ag1 busca "CONEXÃO" | #1800 |
| BU-03 | base | ag1 busca "impressoras" | #1801 |
| BU-04 | base | ag1 busca "cai toda tarde" (só no corpo) | #1800 |
| BU-05 | base | ag1 busca "firewall-xz9" (só na nota interna) | #1800, com trecho marcado como nota interna |
| BU-06 | base | ag1 busca "ana@acme" (trecho do e-mail da solicitante) | #1800 e #1803 |
| BU-07 | base | admin busca "PD-1802", "#1802" e "1802" | #1802 em primeiro lugar nas três |
| BU-08 | base | admin busca "4471" e depois "NF-4471" | #1802 nas duas |
| BU-09 | base | admin busca "fatura-4471" (nome do anexo) | #1802 |
| BU-10 | #1801 recebe um bounce com a palavra "mailbox-full-777" | ag1 busca "mailbox-full-777" | nenhum resultado (mensagem de sistema fora da busca) |
| BU-11 | resposta de ana em #1800 cita "texto-antigo-555" só na parte citada | ag1 busca "texto-antigo-555" | nenhum resultado (a parte citada não é pesquisada) |
| BU-12 | base | ag1 busca "de para o" | mesmo resultado da consulta vazia, com aviso de termos ignorados |
| BU-13 | #1804 (Suporte N1, ana) com mensagem "the printer is broken" | ag1 busca "printer" | #1804 (forma simples) |
| BU-14 | Pessoa ana com campo "identificação da máquina" = "NB-0457" | ag1 busca "NB-0457" | #1800 e #1803 (tickets de ana visíveis a ag1) |

### 12.2 Sintaxe
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-15 | base | ag1 busca "vpn tarde" | #1800 (E entre palavras) |
| BU-16 | base | ag1 busca "vpn impressora" | nenhum resultado |
| BU-17 | base | ag1 busca "\"frente e verso\"" | #1801 |
| BU-18 | base | ag1 busca "\"verso e frente\"" | nenhum resultado |
| BU-19 | base | ag1 busca "estado:aberto,pendente -impressora" | #1800 |
| BU-20 | base | ag1 busca "estado:xyz" | erro que indica o filtro e lista os estados aceitos, incluindo em espera; pela API, 400 |
| BU-21 | base | ag1 busca "grupo:Marketing" (grupo inexistente) | lista vazia, sem erro |
| BU-22 | base | ag1 busca "cor:azul" | tratado como texto livre "cor azul"; sem erro |
| BU-23 | base | ag1 busca "responsavel:eu" | #1800 |
| BU-24 | base | ag1 busca "responsavel:nenhum grupo:\"Suporte N1\"" | #1801 e #1803 (sem filtro de estado, o fechado também casa) |
| BU-25 | base | ag1 busca "Organização:Acme etiqueta:VPN" | #1800 |
| BU-26 | #1800 criado em 2026-10-20 10:00 (fuso do ag1) | ag1 busca "criado:2026-10-20" e depois "criado:..2026-10-19" | primeira: inclui #1800; segunda: não inclui |
| BU-27 | base | ag1 busca "estado:aberto estado:pendente" | lista vazia (mesmo filtro repetido combina por E) |
| BU-28 | base | ag1 busca "canal:formulario" e depois "canal:xyz" | primeira: os tickets criados pelo formulário público; segunda: erro que lista os canais aceitos |
| BU-29 | Pessoa bia com campo "cargo" = professor | ag1 busca "solicitante.cargo:professor" | #1801 |

### 12.3 Permissões
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-30 | base | ag3 busca "vpn" | lista vazia; total 0 |
| BU-31 | base | ag3 busca "1800" | lista vazia, igual à busca por "99999" |
| BU-32 | base | ag1 busca "fatura" | nenhum resultado (#1802 é do Financeiro) |
| BU-33 | base | admin busca "fatura" | #1802 |
| BU-34 | ag1 tem acesso ao Suporte N1 | admin retira ag1 do Suporte N1; ag1 repete "vpn" logo em seguida | lista vazia |
| BU-35 | fila compartilhada "Todos abertos" (`estado:aberto`) criada pelo admin | ag3 abre a fila | só #1802; contagem 1 |
| BU-36 | base | ag1 pede pela API a busca "estado:aberto" | #1800 apenas; total 1 |
| BU-37 | ag2 com **leitura** (não escrita) no Financeiro | ag2 busca "fatura" | #1802 (leitura basta para achar) |

### 12.4 Consistência e mescla
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-40 | — | ag1 cria ticket com assunto "token-recem-criado"; ao fim da gravação, ag2 busca o termo | o ticket é encontrado na primeira tentativa |
| BU-41 | — | uma mensagem com "palavra-rollback" é gravada e a transação é abortada | busca por "palavra-rollback" não devolve nada |
| BU-42 | #1800 | ag1 troca a etiqueta "vpn" por "rede"; ag2 busca "etiqueta:rede" | #1800 imediatamente; "etiqueta:vpn" não o devolve mais |
| BU-43 | #1814 (Suporte N1, ana) com mensagem "palavra-origem-31" | ag1 mescla #1814 em #1800; busca "palavra-origem-31" | #1800; #1814 não aparece |
| BU-44 | após BU-43 | busca "palavra-origem-31 estado:mesclado" | #1814 |
| BU-45 | #1800 | ag1 muda #1800 para em espera; ag2 busca "estado:em-espera" logo em seguida | #1800 |

### 12.5 Relevância, ordenação e paginação
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-50 | #A com "roteador" no assunto; #B com "roteador" só numa mensagem | ag1 busca "roteador" | #A antes de #B |
| BU-51 | #1800 com última mensagem pública de ana há 3 h; #1805 (Suporte N1, aberto) com última mensagem pública de cliente há 1 h; #1806 (Suporte N1, aberto) com última mensagem pública de agente | ag1 ordena `estado:aberto` por "aguardando resposta há mais tempo" | #1800, #1805, depois #1806 |
| BU-52 | dois tickets com o mesmo momento de atualização | ordenar por última atualização | o de número maior primeiro, sempre na mesma ordem |
| BU-53 | 60 tickets visíveis no Suporte N1 | ag1 pagina com tamanho 25 | páginas de 25, 25 e 10; nenhum número repetido; nenhum faltando; total 60 |
| BU-54 | idem | ag1 pede pela API tamanho 500 | **400**; nenhum dado devolvido |
| BU-55 | 12.000 tickets visíveis | consulta sem filtro | o total é informado como "mais de 10.000" |
| BU-56 | cursor de uma consulta "estado:aberto" | usado pela API numa consulta "estado:fechado", ou adulterado, ou 24 h e 1 min depois de emitido | **400** nos três casos |
| BU-57 | base | busca sem texto | ordenada por última atualização decrescente; sem trechos |
| BU-58 | agora = qua 2026-11-11 10:00; #1810 com resolução vencida às 08:00; #1811 com resolução que vence às 11:00; #1812 só com métrica pausada (em espera); #1813 sem SLA | ag1 ordena por vencimento do SLA, crescente | #1810, #1811, #1813, #1812 (os dois sem vencimento no fim, pelo desempate de número decrescente); colunas: "vencido há 2 h", "vence em 1 h", "pausado", vazio |
| BU-59 | #1807 (Suporte N1, aberto) ficou sem responsável às 09:00; #1815 (Suporte N1, aberto) às 08:00 | ag1 ordena `responsavel:nenhum estado:aberto` por "na fila há mais tempo" | #1815, depois #1807 |

### 12.6 Filas salvas
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-60 | fila compartilhada "Meus abertos" (`responsavel:eu estado:aberto`) | ag1 e ag3 abrem | ag1 vê #1800; ag3 vê #1802 |
| BU-61 | fila pessoal de ag1 | ag2 tenta abrir pela API | "não encontrado" |
| BU-62 | ag1 abre a fila compartilhada e muda a ordenação | ag2 abre a mesma fila | ag2 vê a ordenação original |
| BU-63 | ag1 tenta editar uma fila compartilhada | — | recusado |
| BU-64 | fila compartilhada com `grupo:Financeiro` | admin exclui o grupo Financeiro (depois de mover os tickets) | a fila abre, devolve vazio e mostra aviso ao admin |
| BU-65 | base + #1807 (Suporte N1, aberto, sem responsável) | ag1 abre a fila padrão "Fila dos meus grupos" | #1807; #1801 não aparece (está pendente) |
| BU-66 | ag1 com 10 filas pessoais | tenta criar a 11ª | recusado com indicação do limite |
| BU-67 | base; ag1 é membro só do Suporte N1 | ag1 abre "Meus tickets" depois de pôr #1800 em espera | #1800 aparece (a fila padrão inclui em espera) |
| BU-68 | admin sem ser membro de nenhum grupo | admin abre "Todos dos meus grupos" | #1800, #1801, #1802 e #1803 (`grupo:meus` vale todos os grupos para admin) |

### 12.7 Portal
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-70 | base | ana busca "firewall-xz9" no portal e pela API com credencial dela | nenhum pedido; nenhum trecho com o termo |
| BU-71 | base | ana busca "conexao" | pedido #1800 |
| BU-72 | Acme com compartilhamento desligado | ana busca "impressora" | nenhum pedido (#1801 é de bia) |
| BU-73 | Acme com compartilhamento "todos os membros" | ana busca "impressora" | #1801, em somente leitura |
| BU-74 | cris é participante confirmada de #1800 | cris busca "vpn" | #1800 |
| BU-75 | base | ana busca "etiqueta:vpn" | tratado como texto livre ("etiqueta" E "vpn"); a etiqueta do ticket nunca é consultada; como a palavra "etiqueta" não está no texto público, nenhum resultado |
| BU-76 | artigos publicados P (público), L (clientes logados) e I (interno) com "vpn" | ana busca "vpn" | artigos P e L; nunca I |
| BU-77 | idem | visitante busca "vpn" | só o artigo P; nenhuma seção de pedidos |
| BU-78 | artigo P com edição em andamento contendo "segredo-rascunho" | visitante e ana buscam "segredo-rascunho" | nenhum resultado |
| BU-79 | admin arquiva P | visitante busca "vpn" logo em seguida | P não aparece |
| BU-80 | #1800 em espera | ana busca "vpn" com o filtro "em andamento" | #1800, com estado exibido "em andamento" |
| BU-81 | Acme com "só gestores"; ana gestora, bia não | bia busca "conexao"; ana busca "impressora" | bia: nenhum pedido; ana: #1801 em somente leitura |
| BU-82 | P com tradução EN "VPN access" publicada; ana com idioma EN | ana busca "access" | P aparece uma vez, na tradução EN |
| BU-83 | ag2 seguidor de #1800; conversa paralela em #1800 com "orcamento-777" | ana busca "orcamento-777" | nenhum pedido |

### 12.8 Estados e filtros novos
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-100 | #1808 (Suporte N1, cris, em espera, responsável ag2) | ag1 busca "estado:em-espera" e depois `estado:"em espera"` | #1808 nas duas |
| BU-101 | idem | ag1 busca "estado:aberto,pendente" | #1808 não aparece |
| BU-102 | #1800 com tipo incidente; #1801 sem tipo | ag1 busca "tipo:incidente" e depois "tipo:nenhum grupo:\"Suporte N1\"" | primeira: #1800; segunda: inclui #1801 e não inclui #1800 |
| BU-103 | ag2 segue #1800 | ag2 busca "seguidor:eu" | #1800 |
| BU-104 | agora = qua 2026-11-11 20:00; #1816 resolvido às 08:01 (há 11 h 59 min); #1817 resolvido às 07:59 (há 12 h 01 min) | ag1 busca "resolvido:12h" | #1816; #1817 não |
| BU-105 | agora = qua 2026-11-11 20:00; #1821 avaliado com nota 2 em 2026-11-09; #1822 avaliado com nota 5 em 2026-11-01 | ag1 busca "avaliado:7d" e depois "avaliacao:insatisfeito" | primeira: só #1821 (a janela começa em 2026-11-04 20:00); segunda: só #1821 |
| BU-106 | ag1 encaminha #1800 com retorno do Suporte N1 para o Financeiro (Δ5) | ag3 busca "grupo:Financeiro estado:aberto"; ag1 busca `grupo:"Suporte N1" estado:em-espera` e depois "encaminhado:eu" | ag3: #1800; ag1: a primeira busca **não** devolve #1800 (estado único aberto, no Financeiro, D23); "encaminhado:eu" devolve #1800, com estado aberto e a marca "encaminhado por ag1 de Suporte N1"; #1800 aparece uma vez em cada resultado |
| BU-107 | após BU-106 | ag3 devolve #1800 | "encaminhado:eu" de ag1 fica vazio; #1800 volta a casar com `grupo:"Suporte N1" estado:aberto` e com "responsavel:eu" de ag1 |
| BU-108 | ticket criado pelo widget de chat | ag1 busca "canal:chat" | o ticket aparece |
| BU-109 | após BU-106 | ag2 (Suporte N1, não é o agente de origem) busca "encaminhado:meus" e `encaminhado:"Suporte N1"`; ag3 busca "encaminhado:meus" | ag2: #1800 nas duas, com a marca; ag3: nada (o Financeiro não é a origem) (D23) |
| BU-110 | após BU-106 | ag2 busca "firewall-xz9" (só na nota interna de #1800) | #1800, pela leitura da origem (D24); se, em vez de devolver, ag3 transferir #1800 normalmente para um terceiro grupo (o que cancela o retorno), a mesma busca de ag2 fica vazia |
| BU-111 | #1800, #1801, #1802 e #1803 visíveis ao admin | admin ordena `grupo:meus` por número, crescente e decrescente | #1800, #1801, #1802, #1803 / a ordem inversa (D32) |
| BU-112 | #1800 e #1801 com prioridade alta; #1805 urgente | ag1 ordena por prioridade, decrescente | #1805, #1801, #1800 (empate desfeito pelo número, decrescente, D32) |
| BU-113 | bia usa "meu problema foi resolvido" em #1801 (pendente, sem responsável) | ag1 busca "tem:resolvido-pelo-solicitante" | #1801, estado resolvido, com a marca "resolvido pelo solicitante" na coluna de estado (D33) |
| BU-114 | base | pela API, ag1 pede `estado:aberto` ordenada por vencimento do SLA, por na fila há mais tempo e por "cor" | as duas primeiras aceitas, com a mesma ordem da interface; a terceira: **400** (D32) |
| BU-115 | após BU-106 | admin abre `estado:aberto` agrupada por grupo | #1800 só no grupo Financeiro, contagem 1 nele; nenhum grupo "Suporte N1" com #1800 (D23) |

### 12.9 Colunas e agrupamento
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-120 | fila compartilhada restrita ao grupo Financeiro | ag1 (sem Financeiro) lista as filas e depois tenta abri-la pela API | não aparece na lista; "não encontrado" pela API; ag3 e admin a veem |
| BU-121 | base + #1807 (Suporte N1, aberto, sem responsável) | admin abre `estado:aberto` agrupada por responsável | grupos na ordem: "sem responsável" (#1807, contagem 1), ag1 (#1800, 1), ag3 (#1802, 1) |
| BU-122 | idem | ag1 abre a mesma fila | grupos "sem responsável" (#1807) e ag1 (#1800); nenhum grupo nem contagem com #1802 |
| BU-123 | fila "Resolvidos nas últimas 12 h" com #1816 (resolvido 08:01) | ag1 abre às 20:00 e de novo às 20:05 | às 20:00 contém #1816; às 20:05 não contém (12 h 04 min) |
| BU-124 | cadastro de locais com os campi Barra e Gávea, nessa ordem; 3 tickets abertos com local em Gávea, em Barra e sem local | agrupar por campus | ordem: Barra, Gávea, "sem local" (reescrito em v0.3, D51) |
| BU-125 | conta de demonstração da EARJ | admin lista as filas compartilhadas | as 9 filas do §9.1, cada uma com contagem |
| BU-126 | ag1 com 10 filas pessoais | ag1 usa "salvar como pessoal" numa fila compartilhada | recusado com indicação do limite |

### 12.10 Modo sequência e edição em massa
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-140 | fila "Sem responsável" com T1, T2 e T3, nessa ordem; ag2 está vendo T2 | ag1 entra em modo sequência e envia uma resposta em T1 | abre T3; aviso de que T2 foi pulado |
| BU-141 | após BU-140 | ag1 pula T3 | nenhum ticket restante; resumo: 1 enviado (T1), 2 pulados (T2 por presença, T3); volta à lista |
| BU-142 | fila "Sem responsável" com T1 e T2; durante a sequência entra T4, que fica depois de T2 na ordem | ag1 envia em T1 e depois em T2 | abre T2 e depois T4 |
| BU-143 | 5 tickets selecionados, 1 sem responsável; responsável obrigatório ligado (Δ4) | edição em massa: estado → resolvido | 4 resolvidos, 1 falha com o motivo "responsável obrigatório"; 4 conjuntos de eventos "via edição em massa"; gatilhos rodam nos 4 |
| BU-144 | 101 tickets selecionados | qualquer ação em massa | recusado antes de executar; nenhum ticket alterado |
| BU-145 | seleção com #1800 (escrita) e #1802, em que ag1 tem só leitura | ag1 adiciona a etiqueta "revisar" em massa | #1800 alterado; #1802 falha com "sem permissão" |
| BU-146 | seleção de #1800 (ana) e #1808 (cris) | ag1 aplica em massa uma macro com resposta pública que usa o primeiro nome do solicitante | dois e-mails, um com "Ana" e outro com "Cris"; cada ticket com seus eventos |
| BU-147 | #1800 selecionado; ag2 muda a prioridade de #1800 antes da execução | ag1 executa a edição em massa | #1800 falha com "alterado por outra pessoa"; os demais seguem |

### 12.11 Contexto na tela do ticket
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-160 | ana com 12 tickets no Suporte N1 além do atual | ag1 abre um ticket de ana | "tickets anteriores" mostra os 10 mais recentes, com estado; o atual não aparece |
| BU-161 | ana com tickets no Suporte N1 e um no Financeiro | ag3 abre o ticket de ana no Financeiro | "tickets anteriores" não mostra nenhum do Suporte N1 nem indica que existem |
| BU-162 | #1801 "Impressora do 3º andar"; #1818 "Impressora sem toner" (Suporte N1); #1819 "Impressora travada" (Financeiro) | ag1 abre #1801 | relacionados incluem #1818; nunca #1819; nunca #1801 |
| BU-163 | #1801, #1818 e #1820 com Motivo = hardware; #1818 e #1820 com uma palavra do assunto em comum com #1801; só #1820 tem o mesmo Equipamento (impressora) | ag1 abre #1801 | #1820 antes de #1818 (reescrito em v0.3, D51) |

### 12.12 Local, eventos, incidentes, selo de prazo e "Quase escalando" (v0.3)
Contexto adicional: salas `B-201` (campus Barra, prédio A, 2º andar) e `G-12`
(campus Gávea, prédio Central, térreo). Fuso da conta America/Sao_Paulo
(UTC−3). Calendário de SLA seg–sex 07:00–17:00, sem feriados. Tickets de evento
no Suporte N1, salvo indicação.

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| BU-170 | #1830 em `B-201`; #1831 em `G-12`; #1832 sem local | ag1 busca "campus:Barra", `andar:"2º andar"`, "sala:B-201", "sala:nenhuma" e "campus:Marte" | #1830; #1830; #1830; inclui #1832 e não inclui #1830 nem #1831; vazio, sem erro |
| BU-171 | após BU-170, admin renomeia `B-201` para "Laboratório de Robótica" e depois a desativa | ag1 busca `sala:"Laboratório de Robótica"`, o nome antigo e "sala:B-201" | #1830; nada; #1830 (código estável; sala desativada continua casando) |
| BU-172 | agora = qua 2026-11-18 10:00; #1840 assembly em 2026-11-25 14:00; #1841 homecoming em 2026-12-05 09:00; #1845 pequeno evento em 2026-11-12 | ag1 busca "data-evento:+7d", "data-evento:7d", "data-evento:2026-11-01..2026-11-30", "tipo-evento:homecoming" e "evento:nao" | #1840 (18 a 25); #1845 (11 a 18); #1840 e #1845; #1841; nenhum dos três |
| BU-173 | #1846 evento em qua 2026-11-25 22:30 (UTC−3), ou seja, 2026-11-26 01:30 UTC; ag2 com fuso pessoal UTC+0 | ag2 busca "data-evento:2026-11-25" e abre o calendário da semana | #1846 nas duas, no dia 25 (a data do evento é no fuso da conta) |
| BU-174 | agora = qua 2026-11-11 10:00; #1842 com montagem sex 2026-11-13 08:00; #1843 com montagem qua 2026-11-11 15:00; #1844 com montagem ter 2026-11-10 08:00, evento até qua 2026-11-11 18:00, sem a marca "pronto" | ag1 abre uma fila com os três | selos: "faltam 2 dias para a montagem"; "faltam 5 h para a montagem"; "montagem sem pronto", em vermelho (corrigido em v0.3, D40: o evento não tem resolução comum) |
| BU-175 | agora = sex 2026-11-13 16:30; #1860 vence seg 2026-11-16 07:20; #1861 vence seg 07:40; #1862 venceu sex 15:00; #1863 só com métrica pausada (em espera); #1864 sem SLA; #1865 resolvido | ag1 abre "Quase escalando" | #1862 e depois #1860. #1860 entra (30 min na sexta + 20 min na segunda = 50 min úteis); #1861 não (30 + 40 = 70 min úteis). Selos: #1862 "vencido há 1 h 30 min"; #1860 "vence em" com o tempo corrido (2 dias, 14 h e 50 min) |
| BU-176 | após BU-175, #1867 (Financeiro) vencido | ag1 e ag3 abrem "Quase escalando" | ag1 não vê #1867 nem na contagem; ag3 vê #1867 e nenhum ticket do Suporte N1 |
| BU-177 | — | ag1 busca "sla:xyz" e "sla:0hu" | erro que indica o filtro e os valores aceitos; pela API, 400 |
| BU-178 | #1866 venceu sex 2026-11-13 15:00 e foi posto em espera às 16:00 | ag1 abre "Quase escalando" às 16:30 e busca "sla:pausado" | #1866 não está na fila; aparece em "sla:pausado" |
| BU-179 | #1850 incidente pai (Suporte N1) com os filhos #1851 (Suporte N1) e #1852 (Financeiro) | ag1 busca "incidente:pai", "incidente:1850" e "incidente:filho"; admin busca "incidente:1850" | ag1: #1850; #1851; #1851; coluna do pai "incidente · 1 filho". admin: #1851 e #1852; coluna "incidente · 2 filhos" |
| BU-180 | após BU-179 | ag3 busca "incidente:filho" e "incidente:1850" | #1852, com a coluna "filho de incidente", sem número; segunda busca: vazio |
| BU-181 | 5 eventos visíveis em 2026-11-25 (08:00, 09:00, 10:00, 14:00 e 22:30) e #1847 (Financeiro) no mesmo dia | ag1 abre o calendário de novembro de 2026 | o dia 25 mostra os eventos das 08:00, 09:00 e 10:00 e "mais 2"; #1847 não aparece nem entra na contagem; ag3 vê #1847 |
| BU-182 | eventos #1845, #1840, #1846 e #1841 de BU-172 e BU-173, mais #1800 (não é evento) | ag1 ordena `grupo:meus` por data do evento, crescente, na interface e pela API | #1845, #1840, #1846, #1841, depois #1800; a mesma ordem nos dois |
| BU-183 | #1842 enviado abaixo da antecedência mínima (spec 07 §8.9) | ag1 busca "tem:fora-do-prazo" e abre o calendário | #1842; no calendário e na fila, o selo mostra também "fora do prazo" |
| BU-184 | admin salva uma fila compartilhada sem a coluna de prazo | ag1 abre a fila | o selo de prazo continua em cada linha |
| BU-185 | #1830 (`B-201`, Suporte N1, aberto), #1833 (`B-201`, Financeiro, aberto) e #1834 (`B-201`, Suporte N1, resolvido) | ag1 abre o QR de `B-201`; ana (solicitante de #1830) busca "Robótica" no portal depois de o admin renomear `B-201` para "Laboratório de Robótica" (sala ativa) | ag1: lista só #1830, contagem 1; ana: #1830 |
| BU-186 | agora = qua 2026-11-11 10:00; #1848 com montagem ter 2026-11-10 08:00, evento até qua 2026-11-11 18:00, com a marca "pronto"; #1849 com evento encerrado ter 2026-11-10 22:00, sem a marca | ag1 abre uma fila com os dois e busca "tem:pronto" | selos: "pronto"; "evento encerrado"; a busca devolve #1848 |
| BU-187 | após BU-175; #1868 evento sem "pronto", montagem seg 2026-11-16 07:10; #1869 evento com "pronto", montagem seg 07:10; #1870 evento sem "pronto", montagem sex 2026-11-13 14:00, evento até sex 22:00; todos com a 1ª resposta já dada | ag1 abre "Quase escalando" (sex 16:30) | #1870, #1862, #1868, #1860. #1868 entra (30 min na sexta + 10 min na segunda = 40 min úteis); #1869 não (tem "pronto"). Selos: #1870 "montagem sem pronto"; #1868 "faltam 3 dias para a montagem" (D40) |
| BU-188 | #1871 evento, montagem seg 2026-11-30 08:00, criado sex 2026-11-13 16:00, sem resposta; a 1ª resposta da política vence seg 2026-11-16 07:20 | ag1 abre "Quase escalando" sex 16:30 e busca "sla:1hu" | #1871 está nos dois, pela 1ª resposta (30 min na sexta + 20 min na segunda = 50 min úteis); selo "faltam 17 dias para a montagem" e o rótulo "sem resposta" em vermelho (D40, Δ30) |
| BU-189 | #1800 aberto, sem primeira resposta; #1801 pendente, com resposta | ag1 abre "Todos dos meus grupos" | #1800 com o rótulo "sem resposta" em vermelho na coluna de estado; #1801 sem o rótulo; depois que ag1 responde #1800, o rótulo some |
| BU-190 | #1850 incidente pai em `B-201`; filhos #1851 em `B-201` e #1852 (Financeiro) em `G-12` | ag1 e admin abrem #1850 | ag1: locais afetados `B-201`, uma vez; admin: `B-201` e `G-12` (D48) |

---

## 13. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Corpo das mensagens e anexos na busca | documentação de 3 projetos | S-01 |
| Notas internas na busca do agente e do cliente | não documentado | S-01, P-03 |
| Filtros combinados e filas salvas (pessoais/compartilhadas, "eu") | documentação de 5 projetos | S-02 |
| Acento e maiúsculas | **nenhum** projeto documenta | S-03 (obrigatório em todos) |
| Latência de indexação | documentado em 1 módulo; inferido nos demais | S-04 |
| Permissão nos resultados | documentado em 1 projeto | P-01 |
| Busca do cliente no portal (escopo próprio × organização) | documentado em 1 projeto | K-02, P-02 |
| Busca na KB (relevância, anônimo × logado) | documentação parcial | K-02 |
| Filas da EARJ, sequência, massa e contexto | requisitos da operação EARJ (spec 13) | — |

---

## 14. Questões abertas para o implementador

1. **Spec 02 §8** guarda a parte citada separada; esta spec a exclui da busca.
   Se um cliente escrever a resposta no meio da citação (caso conhecido de
   perda de texto), essa parte pode não ser encontrada. Avaliar com as
   fixtures da spec 02 se o separador de citação está correto antes de fechar
   esta decisão.
2. O dicionário de radicais do português pode juntar palavras diferentes com
   o mesmo radical. Se os testes de aceite mostrarem falsos positivos
   frequentes, a forma simples (§3.2) pode ganhar peso maior que a forma por
   radical.
3. Limites ainda propostos (total exato até 10.000, 100 filas compartilhadas,
   validade do cursor de 24 h, 10 tickets anteriores e 5 relacionados) e a
   pontuação dos relacionados (§9.6). Registrar no registro de decisões do
   projeto se mudarem. O máximo de 100 por página e o limite de 10 filas
   pessoais já estão decididos (D15, Δ9).
4. Limites propostos do calendário (3 eventos por dia na visão de mês, semana
   de segunda a domingo) e o limite de N em `sla:Nhu` (1 a 99).
