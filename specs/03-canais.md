# Spec 03 — Canais

Status: **rascunho v0.3 (2026-10-29)**. Baseado na documentação pública dos 7
projetos e nos requisitos da operação EARJ (spec 13). Evidências de runtime
pendentes, marcadas como **[evidência pendente: cenário]**. Vocabulário: spec
01. E-mail: spec 02. Decisões transversais: D01–D53. Precedência: spec 13 > decisões transversais > esta spec.
Esta spec tem duas partes: **MVP** (§2 a §7) e **roadmap** (§8), separadas de
propósito. O roadmap descreve comportamento esperado e as costuras que o MVP
precisa deixar prontas, não o detalhe de implementação.

Mudanças na v0.3:
- **Entrada pelo QR da sala** (spec 13 Δ33; §4.9): o solicitante abre o
  formulário com o local preenchido e travado; o agente logado vê os tickets
  não resolvidos da sala. O local vem do cadastro de locais, nunca de
  etiquetas; "minhas salas" preenche o local quando não há QR.
- **Formulário de evento** como segundo formulário ativo do portal, com
  antecedência mínima e marca "fora do prazo" (Δ34; §4.1, §4.10). Regra "um
  formulário ativo por vez" passa a valer **por finalidade** (suporte, evento).
- **Identidade pelo Google** (Δ31; §4.5, §5): funcionários entram no portal
  com a conta Google da escola, o que identifica a Pessoa e verifica o
  endereço no primeiro login; quem não tem conta da escola usa o link por
  e-mail; os parâmetros do QR sobrevivem ao login.
- CH-54 ajustado (formulários de suporte); novos casos CH-81 a CH-97.
- **Ajustes D40–D53**: agentes e admins entram **só com Google**; fora do modo
  de desenvolvimento não há entrada local para eles, e instalação sem Google
  configurado não é suportada no MVP (D53; §4.5). No formulário de evento, o
  termo é **"tipo de evento"** (D53; §4.10). Os campos personalizados
  "unidade" e "setor/sala" saem dos exemplos: o local vem só do cadastro de
  locais, e o exemplo de condição passa a ser motivo → equipamento → sintoma
  (D51; §4.1, §4.2). CH-50 a CH-52 e CH-90 revistos; novos CH-98 e CH-99.

Mudanças na v0.2:
- O formulário do portal passa a ser o **canal principal** (spec 13 Δ1): um ou
  mais formulários definidos pelo admin, um ativo por vez, com campos de
  sistema e personalizados, ordem, rótulo, ajuda e **campos condicionais**
  (Δ2). O mesmo formulário atende o solicitante logado (canal `portal`) e o
  visitante sem login (canal `formulario`).
- **Chat no site** sai do roadmap e entra no MVP (D20, Δ16), em forma
  assíncrona: nova §6, tipo de canal `chat`, despachante de chat e testes
  CH-60 a CH-76.
- Pedido sem login exige **nome e e-mail** no formulário e no chat (decisão do
  responsável, spec 13 §6). Chat anônimo vai para o roadmap.
- O e-mail de confirmação deixa de ser um mecanismo próprio: é o **gatilho de
  confirmação** da spec 05 §6 (inclusive na versão dentro e fora do horário,
  Δ11). Esta spec só fixa as restrições do canal (sem eco do conteúdo, limite
  por endereço).
- O link da confirmação passa a ser o **link de convidado** da spec 07 §7.3; o
  link próprio de 7 dias foi removido.
- "Endereço verificado" alinhado à spec 01 §2 (D38): só o link de uso único
  ou a entrada no portal verificam; responder a e-mail, formulário e chat nunca
  verificam.
- Ticket criado por agente: o canal `agente` com meio declarado é a forma
  desta spec de gravar o "canal informado pelo agente" da spec 01 §4.6, com os
  dois modos da 01 (registrar pedido, contato proativo).
- Estado **em espera** (D18, Δ3) entra no limite de tickets não resolvidos por
  endereço e no mapeamento de mensageria do roadmap.
- Conversa paralela (Δ17): mensagens com canal `email`, nunca entram no
  cálculo do canal de resposta ao solicitante.
- Mesclar pessoas sai do roadmap (Δ22); as regras ficam na spec 01.
- CAPTCHA: o MVP entrega a costura; uma implementação é opcional.
- Testes: CH-10 e CH-46 usam a atriz nova `dani` (inexistente na conta);
  CH-29, CH-40, CH-41, CH-44 e CH-46 com resultados atualizados; novos CH-49 a
  CH-59 (formulário e verificação) e CH-60 a CH-76 (chat).
- Ajustes D23–D37: esta spec não tem mais confirmação própria; a §4.6 aponta
  para o gatilho de criação da spec 05 §6, que cobre todos os canais, inclusive
  o chat, e guarda só as regras para endereço não verificado (sem eco, só
  número e link de convidado, 3 por endereço a cada 24 h em qualquer canal;
  D25). Ticket criado por agente: canal `agente` com **meio declarado**
  obrigatório no modo registrar pedido (D34). Novos casos CH-77 a CH-80.

---

## 1. Problema

Pedidos chegam por mais de um meio. No MVP são três de entrada pública
(e-mail, formulário do portal para visitante sem login e chat no site), mais o
mesmo formulário para o solicitante logado no portal, a criação pelo agente e
a API. Depois virão WhatsApp, SMS e redes sociais. O sistema precisa responder
sem ambiguidade:

1. **de onde veio** cada ticket e cada mensagem, de forma estável e
   consultável, sem que isso mude as regras de estado da spec 01;
2. **por onde sai** a resposta do agente;
3. como aceitar pedidos de **qualquer pessoa na internet** pelo formulário e
   pelo chat sem abrir a porta para robôs, enxurradas e uso do sistema como
   disparador de e-mail contra terceiros;
4. como **identificar o solicitante** que só declarou um e-mail, sem criar
   duplicatas e sem entregar o histórico de outra pessoa a quem digitou o
   endereço dela;
5. como **confirmar** o recebimento sem criar laço nem spam;
6. como acrescentar canais novos depois **sem migração** do modelo e sem
   reescrever o pipeline de entrada.

---

## 2. Canal de origem (conceitual)

### 2.1 Termos

| Termo | Definição |
|---|---|
| **Tipo de canal** | O meio: `email`, `formulario`, `portal`, `chat`, `agente`, `api`, `sistema`. No roadmap: `whatsapp`, `sms`, `social`, `generico`. Lista fechada, ampliada só por versão do produto. Filtros e relatórios aceitam todos os valores do MVP (spec 08, spec 11). |
| **Instância de canal** | Uma configuração concreta de um tipo: uma caixa de entrada de e-mail (spec 02 §2.1), um formulário do portal (§4.1), um widget de chat (§6.1), no futuro um número de WhatsApp. Pertence a uma conta, tem nome, grupo padrão e pode ser desativada. Os tipos `portal`, `agente`, `api` e `sistema` têm uma instância implícita por conta. |
| **Canal da mensagem** | Par (tipo, instância) gravado em cada **Mensagem** no momento da criação. Imutável, como a própria mensagem. Diz onde a mensagem foi **escrita**. |
| **Canal de origem do ticket** | O canal da **primeira mensagem** do ticket. Imutável. Usado em filas, filtros, relatórios e automações (spec 05). |
| **Canal de resposta** | Por onde sai a próxima resposta pública do agente. Calculado no envio (§2.3), nunca guardado como verdade fixa. |
| **Entrega** | Por onde uma resposta pública **efetivamente** chegou ao solicitante: e-mail, widget de chat, ou os dois (§6.4). Registrada por mensagem, separada do canal da mensagem. |
| **Identificador externo** | Identificador da mensagem no meio de origem: o Message-ID no e-mail, o token de envio no formulário, o identificador da mensagem gerado pelo widget no chat, no futuro o identificador do provedor. Junto com a instância, forma a chave de idempotência. |
| **Visitante** | Pessoa que usa o formulário (§4) ou o chat (§6) **sem sessão no portal**. Ela só declara nome e e-mail; nada do que declara é tomado como prova de identidade (§4.5). Não confundir com o **convidado** da spec 07 §7.3, que entra por um link enviado a ele. |

### 2.2 Regras

- Toda Mensagem tem canal. Não existe mensagem "sem canal".
- Atribuição do canal por situação:

| Situação | Canal da mensagem |
|---|---|
| Mensagem que entrou pelo pipeline de e-mail (spec 02) | `email` + caixa de entrada |
| Envio do formulário por visitante (§4) | `formulario` + formulário |
| Solicitante logado envia o formulário ou responde pelo portal, inclusive por link de convidado (spec 07) | `portal` |
| Mensagem do solicitante escrita no widget de chat (§6) | `chat` + widget |
| Agente cria ticket no modo **registrar pedido** (spec 01 §4.6) | `agente`, mais o **meio declarado** (telefone, presencial ou outro; D34), gravado na mensagem e no ticket e disponível para filas, regras e relatórios (spec 11). A mensagem tem autoria do solicitante, com a marca "registrada por {agente}". |
| Agente cria ticket no modo **contato proativo**, responde ou escreve nota interna na interface | `agente` |
| Mensagem criada pela API REST (spec 10) | `api` + identificação do token |
| Mensagem de sistema (resposta automática recebida, bounce, aviso) | o canal por onde o fato chegou (ex.: `email` para um bounce); `sistema` quando gerada internamente |
| Resposta pública gerada por automação (spec 05) | `sistema`; a auditoria registra a regra |
| Resposta do agente enviada a partir de um e-mail de notificação (spec 02 §5) | `email` + caixa de entrada; por padrão vira nota interna (D02) |
| Mensagem de uma **conversa paralela** (spec 13 Δ17), enviada ou recebida | `email` + caixa de entrada; só agentes a veem |

- O canal **não altera** nenhuma regra de estado, transição ou política de
  resposta em ticket fechado da spec 01. Essas regras dependem apenas de quem
  escreveu (solicitante, participante, agente, sistema) e da visibilidade.
- Uma mescla (spec 01 §6) preserva o canal de cada mensagem. O canal de origem
  do destino não muda.
- Desativar uma instância de canal impede novas entradas por ela; os tickets e
  as mensagens existentes continuam com o canal gravado e legível.
- O canal de origem e o canal de cada mensagem são expostos ao agente e na API.
  O solicitante não vê o canal.

### 2.3 Canal de resposta no MVP

- Regra: o canal de resposta é o canal da **última mensagem pública do
  solicitante** no ticket, se esse canal tiver despachante que possa entregar
  naquele momento; senão, **e-mail**. Mensagens de conversa paralela, notas e
  mensagens de sistema não contam.
- No MVP existem dois despachantes: **e-mail** e **chat**. Na prática:
  - última mensagem do solicitante pelo chat → a resposta vai ao widget, com a
    regra de entrega por e-mail do §6.4;
  - qualquer outro caso (`email`, `formulario`, `portal`, `agente`, `api`) →
    e-mail ao solicitante, com os participantes em Cc, seguindo a spec 02 §9.
- Toda resposta pública também fica visível no portal, qualquer que seja a
  entrega.
- A caixa de saída é a caixa de entrada ligada ao grupo do ticket. Se o grupo
  não tiver caixa, usa-se a caixa padrão da conta.
- Se o solicitante não tem endereço válido (inválido por bounce, spec 02 §7),
  a resposta é gravada e fica visível no portal (e no widget, se for o caso),
  mas não sai por e-mail; o agente vê um aviso.
- A interface mostra ao agente, antes do envio, por onde a resposta vai sair e
  para quem.

---

## 3. E-mail

O canal de e-mail é inteiramente definido pela spec 02. Esta spec só
acrescenta:

- Cada caixa de entrada é uma **instância** do tipo `email`. O grupo padrão da
  caixa é o grupo do ticket novo.
- A chave de idempotência da spec 02 §2.3 é o caso particular, para e-mail, da
  regra geral (instância, identificador externo).
- A **lista de bloqueio** da conta (spec 02 §3, etapa 4) é **única para todos
  os canais**: entradas por endereço e por domínio valem para e-mail,
  formulário e chat; entradas por IP valem para o formulário e o chat.
- Conversas paralelas (spec 13 Δ17) usam as caixas de entrada e o threading da
  spec 02, mas formam uma linha separada dentro do ticket e nunca mudam o canal
  de resposta ao solicitante (§2.3).

---

## 4. Formulário do portal

### 4.1 Formulários e configuração

- O formulário é o **canal principal** de abertura de pedidos (spec 13 Δ1). Ele
  fica numa página do portal e atende dois públicos:
  - **solicitante logado** (sempre): canal `portal` (§5);
  - **visitante sem login**: canal `formulario`, só se a conta ligar "aceitar
    pedidos de visitantes" (padrão do produto: desligado; EARJ: ligado,
    spec 13 §6). Com a opção desligada, quem não tem sessão vê o pedido de
    entrada no portal (link por e-mail, spec 07 §7.1).
- O admin define **um ou mais formulários**. Cada um tem nome, **finalidade**
  (**suporte** ou **evento**, escolhida na criação e imutável), grupo de
  destino (obrigatório) e uma lista ordenada de campos (§4.2). **No MVP fica
  ativo no máximo um formulário por finalidade**: um de suporte e um de evento
  ao mesmo tempo (spec 13 Δ34). Ativar um desativa o anterior **da mesma
  finalidade**, na mesma operação. Os inativos ficam guardados.
- O formulário de **suporte** é o padrão do portal e o que o QR da sala abre
  (§4.9). O formulário de **evento** tem regras próprias (§4.10).
- **Pré-visualização**: o admin abre qualquer formulário, ativo ou inativo, em
  modo de teste. O modo de teste aplica as mesmas condições e validações, mas
  não grava nada e não cria ticket.
- Conta nova vem com um formulário de suporte padrão ativo (assunto,
  mensagem e anexos) e nenhum formulário de evento.
- O formulário pode ser embutido no site da conta por moldura (iframe)
  apontando para essa página. O MVP não oferece script de incorporação do
  formulário; a marca da conta (logo e cores, spec 13 Δ25) vale para a página.
- Opções do admin: aceitar anexos (padrão sim); exigir caixa de aceite de
  privacidade, com texto escrito pelo admin (padrão não); exigir CAPTCHA
  (padrão não, §4.4); limites de volume (§4.4). A confirmação por e-mail é um
  gatilho (§4.6), não uma opção do formulário.
- **Grupo do ticket**: se o formulário mostra o **tipo de pedido** (spec 07
  §8.2), o grupo vem da escolha; senão, é o grupo de destino do formulário.
  Roteamento mais fino é feito por automações de criação (spec 05), usando os
  campos do formulário (na EARJ: o campus do local e o motivo do contato) ou
  o canal de origem como condição. Unidade e sala nunca são campos
  personalizados: vêm do local (D51).

### 4.2 Campos e validação

Cada campo do formulário tem: rótulo para o solicitante e texto de ajuda (um
por idioma da conta; falta de tradução cai no idioma padrão, spec 13 Δ23),
posição, obrigatoriedade "para abrir" e, opcionalmente, uma **condição de
exibição** (spec 01 §5, spec 13 Δ2).

| Campo | Regra |
|---|---|
| Nome | Só visitante. Obrigatório, 1–120 caracteres após remover espaços nas pontas. |
| E-mail | Só visitante. **Obrigatório** (sem e-mail, nada é aceito). Sintaxe de endereço válida; domínio com registro MX, ou A/AAAA na falta de MX (§4.4, camada 3). Máximo 254 caracteres. |
| Assunto | Campo de sistema, sempre presente e obrigatório, 1–150 caracteres (o mesmo limite de truncagem do assunto de saída, spec 02 §9). |
| Mensagem | Campo de sistema, sempre presente e obrigatório, 1–20 000 caracteres. Para o **visitante**, texto puro: não aceita HTML e o corpo é exibido como texto, sem interpretação. Para o solicitante logado, vale o texto da spec 07 §8.2. |
| Anexos | Opcional, se ligado. Visitante: até 5 arquivos, até 10 MB cada, até 25 MB no total (o limite de tamanho de mensagem da spec 02 §2.4). Solicitante logado: limites da spec 07 §8.2. |
| Tipo do ticket | Campo de sistema opcional (spec 13 Δ8), se o admin o incluir, no formulário de suporte (sem o valor evento). Sem valor padrão. No formulário de evento, o tipo é sempre **evento** e não aparece. |
| Local | Campo de sistema do local do ticket (spec 01 §5.3), se o admin o incluir; obrigatório no formulário de evento. Escolha em cascata: campus → prédio → andar → sala, só salas ativas. Pode vir preenchido pelo QR (travado, §4.9) ou por "minhas salas" (não travado). |
| Tipo de pedido | Escolha do grupo (spec 07 §8.2), se o admin o incluir. |
| Campos personalizados | Os campos de ticket marcados como "visíveis ao solicitante, editáveis na abertura" (spec 01 §5) que o admin incluir, com a mesma validação do servidor. Campos "só agentes" **nunca** aparecem, mesmo que estejam na lista. Prioridade, grupo direto, responsável e etiquetas nunca são campos do formulário. |
| Aceite de privacidade | Obrigatório marcar, se ligado. O momento do aceite e a versão do texto ficam gravados na mensagem. |
| Campo-isca | Só visitante. Campo invisível para pessoas (§4.4, camada 4). Não é um campo do ticket. |

Regras dos campos condicionais (detalhe na spec 01 §5):
- Um campo com condição só aparece quando o campo do qual depende tem um dos
  valores escolhidos. Condições podem ser encadeadas (motivo → equipamento →
  sintoma; D51), sem ciclos.
- Um campo **oculto não é obrigatório**, mesmo marcado como obrigatório para
  abrir.
- Quando o solicitante muda uma escolha e um campo fica oculto, o valor dele é
  limpo no próprio formulário antes do envio.
- O servidor reavalia as condições sobre os valores recebidos. Valor enviado
  para um campo que deveria estar oculto, ou para um campo que não está no
  formulário, é **erro de validação** naquele campo.
- Obrigatoriedade "para resolver" (spec 01 §4.2) não vale no formulário.

- Toda validação é feita no servidor. Erro de validação devolve a lista de
  campos com problema e **não grava nada**.
- Os dados técnicos do envio (IP de origem, agente do navegador, momento) ficam
  como metadados da mensagem, visíveis a agentes e admin, nunca ao solicitante
  (retenção em §4.8).

### 4.3 Fluxo de um envio de visitante (ordem fixa)

A ordem importa: cada etapa pode encerrar o processamento, e as camadas mais
baratas vêm primeiro. Inspirado no pipeline de classificação da spec 02 §3. O
envio do solicitante logado segue a §5.

| # | Etapa | Regra | Efeito se falhar |
|---|---|---|---|
| 1 | Visitantes aceitos | A conta aceita pedidos de visitantes e há formulário de **suporte** ativo | Sem formulário de suporte ativo: **404**. Visitantes não aceitos, ou envio ao formulário de evento (que exige sessão, §4.10): **401** com o pedido de entrada no portal. Nada gravado |
| 2 | Limite de volume | Limites por IP e teto global da conta (§4.4, camada 1) | **429** com mensagem genérica; nada gravado; evento operacional |
| 3 | Token de envio | O envio traz um token emitido quando a página foi exibida, assinado pelo servidor, ligado ao formulário, de uso único, com idade entre 3 s e 24 h | Token já usado: responde **igual a um envio aceito**, sem novo efeito (§4.7). Token vencido, ausente ou de um formulário que não está mais ativo: **422** pedindo para recarregar a página. Token com menos de 3 s: quarentena (etapa 7) |
| 4 | Validação | §4.2, incluindo condições de exibição e a verificação do domínio do e-mail | **422** com os campos; nada gravado |
| 5 | CAPTCHA | Se ligado, a prova precisa ser válida | **422**; nada gravado |
| 6 | Sinais de robô e bloqueio | Campo-isca preenchido; IP, endereço ou domínio na lista de bloqueio; endereço declarado é um endereço de suporte da própria conta | Quarentena (etapa 7) |
| 7 | Quarentena | Envios suspeitos vão para a **quarentena** (spec 02) com o motivo | Resposta **igual a um envio aceito**; nenhum ticket, nenhuma pessoa, nenhum e-mail |
| 8 | Limite de tickets não resolvidos | O endereço declarado já tem 5 ou mais tickets **aberto**, **pendente** ou **em espera** criados pelo formulário | Quarentena com o motivo "limite de abertos"; resposta igual a um envio aceito |
| 9 | Pessoa | §4.5 | — |
| 10 | Criação | Ticket no grupo do §4.1, estado **aberto**, prioridade normal, sem responsável, com os valores dos campos; uma Mensagem pública com canal `formulario`; anexos; evento de auditoria com origem solicitante e canal `formulario`. Tudo numa transação | Falha interna: **500**; nada gravado; o token **não** é consumido, e o usuário pode reenviar |
| 11 | Automações e atribuição | Gatilhos de criação (spec 05), inclusive o de confirmação (§4.6), e atribuição (spec 04) | — |

- Liberar um envio da quarentena executa as etapas 9 a 11 uma única vez. Um
  envio liberado duas vezes não cria dois tickets.
- O envio aceito e o envio em quarentena produzem **a mesma resposta** ao
  navegador: a mesma página de agradecimento, com o mesmo código de sucesso e
  tempo de resposta parecido. Por isso a página de agradecimento **não mostra o
  número do ticket**; o número vai no e-mail de confirmação. Assim o robô não
  aprende qual camada o barrou, e ninguém descobre pela tela se um endereço já
  tem tickets.

### 4.4 Anti-spam em camadas

Vale para visitantes do formulário (spec 13 Δ1) e, nas camadas indicadas,
para o chat (§6.6).

| Camada | Padrão | Comportamento |
|---|---|---|
| 1. Volume | ligado | Por IP: 5 envios por hora e 20 por dia. Teto global da conta: 200 envios aceitos por dia. Todos configuráveis. Ao atingir o teto global, o admin recebe **um** aviso por dia. O IP considerado é o do cliente conforme os proxies confiáveis configurados na instalação, nunca um cabeçalho arbitrário. |
| 2. Token de envio | sempre | Uso único, assinado, com idade mínima e máxima (§4.3, etapa 3). Barra reenvio duplicado, repetição de requisições capturadas e robôs que enviam no mesmo instante em que carregam a página. |
| 3. Domínio do e-mail | ligado | O domínio precisa ter MX, ou A/AAAA na falta de MX. Se a consulta DNS não responder em 2 s, **aceita** (falha aberta), para não barrar pessoas reais por instabilidade de DNS. |
| 4. Campo-isca | sempre | Campo escondido de pessoas e de leitores de tela (rótulo neutro, fora do fluxo de tabulação). Preenchido → quarentena. |
| 5. CAPTCHA | desligado | Plugável. O MVP entrega o ponto de encaixe; uma implementação é opcional. Sem implementação instalada, a opção não aparece. Preferir uma solução que rode na própria instalação, sem enviar dados do visitante a terceiros. |
| 6. Lista de bloqueio | vazia | Única da conta (§3). Endereço, domínio ou IP bloqueado → quarentena. Uma entrada de **permissão** explícita para o mesmo endereço vence o bloqueio por domínio (a regra mais específica vence). |
| 7. Não resolvidos por endereço | 5 | §4.3, etapa 8. Configurável; 0 desliga. |

- As camadas são independentes: desligar uma não altera as outras.
- Cada barramento gera um evento operacional com a camada e o motivo, sem o
  conteúdo da mensagem. Admin vê contadores por camada.
- O conteúdo não passa por filtro bayesiano nem por lista de palavras no MVP.

### 4.5 Identificação do solicitante

O formulário e o chat não provam nada sobre quem enviou: qualquer pessoa pode
digitar o e-mail de outra. As regras partem disso.

| Situação | Regra |
|---|---|
| Endereço declarado não existe na conta | Cria uma **Pessoa** com o nome declarado e um **Endereço** de e-mail **não verificado**. Ela vira o solicitante. |
| Endereço declarado já pertence a uma Pessoa | Essa Pessoa vira o solicitante. O nome cadastrado **não** é alterado; o nome declarado fica gravado na mensagem ("nome informado"). Nenhuma outra Pessoa é criada. |
| Comparação de endereços | A da spec 01 §2: endereço inteiro sem diferença de maiúsculas e minúsculas, sem espaços nas pontas; sub-endereço é outro endereço. O endereço é guardado como foi digitado na primeira vez. |
| Endereço pertence a um agente | Aceito como solicitante comum. O envio **nunca** concede nenhum direito de agente nem cria resposta de agente. |
| Endereço marcado como inválido (bounce) | Aceito; o ticket é criado; nenhum e-mail automático é enviado; o agente vê o aviso de endereço inválido. |
| Organização | A Pessoa nova fica sem organização. A Pessoa existente mantém a sua. |
| Participantes | O formulário e o chat não aceitam Cc nem outros destinatários. |
| Solicitante com sessão aberta pelo **login com Google** (spec 13 Δ31) | Não é visitante: a identidade vem da conta Google, não de uma declaração. O e-mail da conta Google, comparado como acima, identifica a Pessoa. Se nenhuma Pessoa tem o endereço, uma é criada com o nome da conta Google, como **solicitante**. O endereço passa a **verificado** no primeiro login; o nome cadastrado de uma Pessoa existente não muda. Papel e grupos nunca vêm do Google. |

- **Login com Google** (spec 13 Δ31): só aceita contas do **domínio**
  configurado na conta (na EARJ, o domínio da escola). Conta de outro domínio
  é recusada na entrada, com a oferta do link por e-mail (spec 07 §7.1), que
  continua sendo o caminho de quem não tem conta da escola (pais, visitantes).
  Para agentes e admins, o Google é a **única** entrada (spec 01 §2, D53):
  eles não usam o link por e-mail nem senha local. Fora do modo de
  desenvolvimento não existe entrada local para eles, e uma instalação sem
  Google configurado não é suportada no MVP. O provedor entra pelo adaptador
  de autenticação da spec 12.
- **Endereço verificado** (spec 01 §2, D38): o endereço só passa a verificado
  quando o dono usa um link de uso único do portal enviado a esse endereço
  (link de entrada ou link de convidado, spec 07) ou entra no portal com ele,
  inclusive pelo login com Google.
  **Responder a um e-mail nosso não verifica**, mesmo que a resposta se encadeie
  por um identificador que nós geramos: o remetente de e-mail é falsificável e
  os identificadores aparecem em cabeçalhos citados e encaminhados.
  
  Um envio de formulário ou uma mensagem de chat também **nunca** verifica o
  endereço, nem um e-mail novo enviado à caixa de suporte.
- **Histórico**: o portal só mostra a lista de tickets de uma Pessoa a quem
  comprovou a posse de um endereço dela. Quem só preencheu o formulário não vê
  nada além da tela de agradecimento; quem está no chat vê só a conversa
  daquele widget (§6.3).
- A confirmação de abertura (§4.6, spec 05 §6) é o caminho natural de
  comprovação: o link de convidado nela leva ao ticket no portal e verifica o
  endereço ao ser usado.

### 4.6 Confirmação de abertura

- Esta spec **não** tem confirmação própria. A confirmação de abertura é o
  gatilho de criação da spec 05 §6, mecanismo único que cobre todos os canais
  de entrada pública: `email`, `portal`, `formulario` e `chat` (D25). Na EARJ
  são dois gatilhos que se excluem, dentro e fora do horário comercial (spec 13
  Δ11). Formato, cabeçalhos, envio e desativação estão na spec 05 §6 e na spec
  02 §6 e §9. O link que ela leva é o link de convidado (spec 07 §7.3); usá-lo
  verifica o endereço (§4.5).
- Ticket de origem `agente` ou `api` não recebe confirmação pelo gatilho
  padrão (§5).

Regras do canal para solicitante com endereço **não verificado** (valem para a
confirmação, em qualquer canal):
- **Sem eco**: a confirmação não reproduz texto escrito pelo remetente:
  assunto, mensagem, nome informado e campos de texto livre. Traz só o número
  do ticket e o link de convidado, além do texto fixo do modelo do gatilho. As
  variáveis correspondentes saem vazias e o gatilho registra o fato. Isso
  impede que o formulário ou o chat sirvam para mandar texto arbitrário a
  terceiros em nome da conta.
- Em ticket de origem `formulario` ou `chat` com endereço não verificado,
  **nenhum** outro e-mail automático (outros gatilhos) reproduz esse texto;
  campos de lista (opções definidas pelo admin) podem aparecer.
- **Limite**: no máximo **3 confirmações por endereço não verificado a cada
  24 h**, somando todos os canais, além do limite geral de 10 auto-respostas
  por destinatário por 24 h (spec 02 §6). Acima de qualquer um, a confirmação é
  suprimida, o ticket continua criado e um evento é registrado.
- Nunca vai a endereços de sistema (lista da spec 02 §6) nem a endereços
  inválidos.

### 4.7 Respostas ao navegador

| Caso | Código | O que o visitante vê |
|---|---|---|
| Aceito, em quarentena ou token repetido | 200 | página de agradecimento, idêntica nos três casos |
| Validação, CAPTCHA, token vencido ou de formulário inativo | 422 | o formulário de volta com os erros, preservando o que foi digitado (exceto anexos) |
| Visitantes não aceitos pela conta | 401 | pedido de entrada no portal |
| Limite de volume | 429 | mensagem genérica pedindo para tentar mais tarde |
| Nenhum formulário ativo | 404 | página não encontrada |
| Falha interna | 500 | mensagem genérica; nada foi gravado |

### 4.8 Privacidade e retenção

- IP e agente do navegador ficam guardados por 90 dias e depois são apagados
  dos metadados da mensagem. A mensagem em si permanece. Vale também para o
  chat.
- Envios em quarentena ficam 30 dias e depois são descartados (spec 02 §2.4).
- O texto de aceite de privacidade é versionado; cada mensagem guarda a versão
  aceita.

### 4.9 Entrada pelo QR da sala

Regras da spec 13 Δ33; cadastro de locais na spec 01 §5.3.
- Cada sala tem um **QR** que aponta para um **endereço curto e estável** do
  portal com o **código da sala**. Trocar o nome da sala não muda o QR. O
  admin imprime os QR por prédio ou por andar (uma folha com o nome e o código
  de cada sala).
- O QR **não é um canal**: o ticket aberto por ele tem o canal do caminho
  usado (`portal` com sessão, `formulario` sem sessão). A mensagem inicial
  guarda que o local veio do QR (spec 01 §5.3).
- Ao abrir o endereço:

| Quem abre | Resultado |
|---|---|
| Solicitante com sessão no portal | O **formulário de suporte** abre com campus, prédio, andar e sala **preenchidos e travados**. A opção "não estou nesta sala" destrava o local para outra escolha; nesse caso, a origem do local passa a ser "escolha". |
| Sem sessão | A tela de entrada do portal: login com Google, link por e-mail e, se a conta aceita visitantes, "continuar sem entrar". Por qualquer caminho, a pessoa volta ao formulário com a sala travada: o código da sala **sobrevive** ao redirecionamento do login (spec 13 Δ31). O visitante segue o §4.3 com o local já preenchido. |
| Agente com sessão na área do agente | A lista dos tickets **não resolvidos** (aberto, pendente, em espera) com aquela sala como local, só os que o agente pode ver (spec 06), com a ação **assumir** (spec 04), e a opção de **abrir ticket novo** já com o local (spec 01 §4.6). |

- **Código desconhecido ou sala desativada**: o formulário abre **sem local**,
  com um aviso de que a sala não foi encontrada, e a pessoa escolhe o local.
  Não é erro: um QR antigo colado na parede não deve impedir o pedido.
- **Validação no servidor**: o local enviado precisa ser uma sala ativa da
  conta (422 no campo, caso contrário). "Travado" é comportamento da tela; o
  servidor só confere a sala.
- **Minhas salas**: sem QR, o formulário de suporte abre com a **primeira**
  sala de "minhas salas" do solicitante logado, sem travar. Visitante não tem
  "minhas salas".
- O endereço do QR não leva dados pessoais, só o código da sala.

### 4.10 Formulário de evento

Regras da spec 13 Δ34; campos na spec 01 §5.2.
- Segundo formulário do portal, de finalidade **evento**, ativo junto com o
  de suporte (§4.1). Grupo de destino obrigatório (na EARJ, o grupo de
  eventos). Cria ticket com tipo **evento**, canal `portal`.
- **Exige sessão** de solicitante no portal (login com Google ou link por
  e-mail; o link por e-mail é só para solicitantes, D53). Sem
  sessão, a pessoa é levada à entrada e volta ao formulário depois (os
  parâmetros sobrevivem ao login). Não há envio de visitante: sem campo-isca,
  sem CAPTCHA; valem o token de envio e o limite de volume por Pessoa (§5).
- Campos fixos do formulário: nome do evento (vira o assunto, 1–150
  caracteres), **tipo de evento** (D53), data, início e fim, início da montagem,
  local (do cadastro; "minhas salas" sugere a primeira, sem travar), público
  estimado, equipamentos pedidos e observações (vira a mensagem, opcional;
  vazia, a mensagem inicial mostra só os valores dos campos). O admin pode
  acrescentar campos personalizados, como no §4.2.
- Validação: a do §4.2 e a da spec 01 §5.2 (fim depois do início; montagem
  antes ou igual ao início do evento; nada no passado). Erro → 422, nada
  gravado.
- **Antecedência mínima** (padrão 5 dias úteis, configurável; spec 01 §5.2):
  antes do envio, o formulário avisa quando a montagem fica abaixo dela. O
  pedido é **aceito** mesmo assim e o ticket nasce com a marca "fora do
  prazo". A marca é visível só para agentes.
- A confirmação de abertura é o gatilho de criação da spec 05 §6.1, como em
  qualquer canal; o prazo do evento e os avisos ficam na spec 05 §7.14.

---

## 5. Portal autenticado e criação pelo agente

- **Entrada no portal** (spec 13 Δ31): funcionários e professores entram com
  a conta Google da escola (§4.5); quem não tem conta da escola entra pelo
  link por e-mail (spec 07 §7.1), opção secundária na tela de entrada. Os
  parâmetros da página de origem (por exemplo, o código da sala do QR, §4.9)
  sobrevivem ao redirecionamento do login.
- **Portal** (detalhe na spec 07): o solicitante logado usa o **mesmo
  formulário de suporte ativo** (§4.1, §4.2), e também o de evento (§4.10),
  sem nome e sem e-mail (vêm da sessão). O
  tipo de pedido e os limites de texto e anexo são os da spec 07 §8.2. Não há
  campo-isca nem CAPTCHA; o token de envio continua valendo; há limite de
  volume por Pessoa (padrão 20 tickets por dia). A confirmação segue §4.6.
  Respostas pelo portal têm canal `portal` e seguem as transições da spec 01.
- **Agente** (spec 01 §4.6): cria ticket para um solicitante existente ou novo
  (informando o e-mail), em um dos dois modos:
  - **registrar pedido** (padrão): canal `agente` com meio declarado
    obrigatório (telefone, presencial ou outro; D34);
    a mensagem inicial é do solicitante, marcada "registrada por {agente}".
    Nenhuma confirmação automática ao solicitante (o gatilho padrão da spec 05
    §6 não cobre a origem `agente`).
  - **contato proativo**: a primeira mensagem é pública do agente, canal
    `agente`, e sai por e-mail ao solicitante (§2.3). É o aviso ao solicitante
    da spec 13 R18.

---

## 6. Chat no site (MVP)

Escopo mínimo e **assíncrono** (spec 13 Δ16): funciona como troca de
mensagens, sem exigir que algum agente esteja online.

### 6.1 Widget e configuração

- **Widget** embutível no site ou app da conta, uma instância por site, cada
  uma com nome, grupo padrão (obrigatório) e a marca da conta (logo, cores,
  spec 13 Δ25). Vem desativado; o admin ativa.
- O widget também pode rodar dentro do portal; nesse caso usa a sessão do
  portal.
- Desativar o widget impede conversas novas e mensagens novas por ele; os
  tickets continuam e podem ser respondidos por e-mail.

### 6.2 Identificação

- **Solicitante logado no portal** (widget dentro do portal): é a Pessoa da
  sessão. Nada é pedido.
- **Visitante**: informa **nome e e-mail**, obrigatórios, antes da primeira
  mensagem. Sem e-mail, nada é aceito (spec 13 §6). O endereço segue o §4.5:
  reaproveita a Pessoa existente, ou cria uma com endereço não verificado; o
  chat nunca verifica o endereço.
- Chat anônimo (sem e-mail) e identidade assinada pelo site da conta ficam no
  roadmap (§8.2).

### 6.3 Conversa e ticket

- A primeira mensagem **cria um ticket**: canal de origem `chat` + widget,
  estado aberto, prioridade normal, sem responsável, no grupo padrão do widget,
  com evento de auditoria de origem solicitante. Passa pelo mesmo caminho de
  criação dos outros canais (gatilhos, atribuição da spec 04, SLA,
  notificações). Não existe arquivo de chats separado nem conversão manual: a
  transcrição é a própria lista de mensagens.
- O widget guarda no navegador um **token de conversa**, ligado ao ticket. Com
  ele, o visitante vê e continua aquela conversa; ele **nunca** vê outros
  tickets da Pessoa. Sem o token (outro navegador, dados apagados), começa uma
  conversa nova.
- Mensagens seguintes do visitante entram no **mesmo ticket**, com canal
  `chat`, e seguem a spec 01 como qualquer resposta pública do solicitante:
  - aberto → continua aberto;
  - pendente ou em espera → vai para aberto (spec 01 §4.3, spec 13 Δ3);
  - resolvido → reabre (aberto);
  - fechado → política de resposta em fechado do grupo (spec 01 §4.4). Com a
    política `novo` (a da EARJ, spec 13 Δ13), cria um ticket novo vinculado, e
    o token de conversa passa a apontar para o ticket novo.
- Notas internas, conversas paralelas e mensagens de sistema internas
  **nunca** aparecem no widget. O widget mostra só as mensagens públicas do
  ticket, com o nome de exibição do autor.
- O solicitante nunca vê o estado "em espera" no widget (spec 13 Δ3).

### 6.4 Resposta do agente e entrega

- O agente responde pela **tela normal do ticket**. Pela regra do §2.3, se a
  última mensagem pública do solicitante veio pelo chat, a resposta vai ao
  widget.
- A resposta aparece no widget **em tempo real** (spec 09) se ele estiver
  aberto.
- **Entrega por e-mail**: se a resposta não for **lida** no widget em
  **2 minutos** e o solicitante tiver endereço válido, ela sai por e-mail
  (spec 02 §9), uma vez, com o marcador do ticket. Lida dentro dos 2 minutos,
  não sai e-mail. A entrega fica registrada na mensagem (widget, e-mail ou os
  dois).
- **Lido**: a mensagem do agente é marcada como lida quando é exibida num
  widget aberto e visível. O agente vê a marca na mensagem.
- **"O agente está escrevendo"**: o widget mostra o indicador enquanto um
  agente digita uma resposta pública naquele ticket. O indicador é passageiro:
  não é mensagem nem evento de auditoria, e nunca aparece para nota interna.
- Se o solicitante responder ao e-mail, a mensagem entra com canal `email`, e
  o canal de resposta passa a ser e-mail até ele voltar a escrever pelo widget.
- **Pesquisa de satisfação** (spec 13 Δ15): quando o ticket vai para resolvido
  com resposta pública, a pesquisa aparece **no próprio widget**, junto com a
  resposta. Se a resposta não for lida em 2 minutos, sai **um** e-mail com a
  resposta e o convite (spec 13 Δ12); nunca dois convites para a mesma
  resolução.

### 6.5 Anexos no widget

- O visitante envia imagens e PDF, até **10 MB** por arquivo. Outros tipos ou
  tamanhos maiores são recusados no envio do arquivo, com a mensagem do motivo,
  sem gravar nada.
- Anexos das respostas do agente aparecem no widget como arquivos para baixar,
  autorizados pela visibilidade da mensagem (spec 06).

### 6.6 Anti-spam e limites do chat

- Valem as camadas de **volume** por IP e teto global (§4.4, camada 1),
  contadas separadamente do formulário e aplicadas a **conversas novas**, e a
  **lista de bloqueio** (camada 6). Endereço, domínio ou IP bloqueado →
  quarentena; o widget mostra a mesma confirmação de mensagem recebida de um
  envio aceito.
- Dentro de uma conversa: no máximo 20 mensagens por minuto. Acima disso,
  **429**, e o widget pede para aguardar.
- Verificação do domínio do e-mail (camada 3) vale no pré-chat.
- O limite de 5 tickets não resolvidos por endereço (camada 7) não se aplica
  ao chat, porque cada conversa continua no mesmo ticket.

### 6.7 Fora do MVP (chat)

Roteamento por disponibilidade de agentes, bots, horário de chat separado,
transferência entre agentes **durante** a conversa ao vivo (a reatribuição
comum da spec 04 continua valendo), chat anônimo e identidade assinada (§8.2).

---

## 7. Regras transversais do MVP

- **Idempotência**: a chave (instância de canal, identificador externo) nunca
  produz um segundo ticket nem uma segunda mensagem, em qualquer canal.
- **Transação**: ticket, mensagem, anexos, pessoa criada e auditoria são
  gravados juntos ou nada é gravado, em qualquer canal.
- **Nota interna** nunca sai por nenhum canal para o solicitante ou
  participantes, nem aparece no widget.
- **Automações e SLA** recebem o canal de origem como dado de condição, mas o
  SLA (spec 05) não varia por canal no MVP.

---

## 8. Roadmap (fora do MVP)

### 8.1 Costuras que o MVP precisa deixar

1. **Canal na mensagem e no ticket** (§2), com o tipo numa lista ampliável.
2. **Endereço com tipo**: o MVP só usa e-mail, mas o Endereço já tem tipo, e a
   unicidade é por (conta, tipo, valor normalizado). Tipos previstos: telefone
   (formato internacional E.164), identificador de provedor (por instância de
   canal), identificador de visitante anônimo do chat (por widget).
3. **Pipeline de entrada em etapas reutilizáveis**: idempotência →
   classificação → encadeamento específico do canal → pessoas → conteúdo →
   transação. Cada canal novo implementa só a etapa de encadeamento e o
   tradutor de conteúdo.
4. **Saída por despachante de canal**: o envio de uma resposta pública passa
   por um componente por tipo de canal que pode **recusar antes de enviar**
   (fora da janela permitida, mídia grande demais) e devolver o motivo ao
   agente. No MVP existem os despachantes de e-mail e de chat.
5. **Estado de entrega por mensagem** (enviada, entregue, lida, falhou),
   atualizado por retorno do provedor. No MVP é preenchido pelo chat (lida,
   entregue por e-mail), pela falha de envio e pelo bounce (spec 02).
6. **Entrada autenticada por instância**: cada instância de canal externo terá
   um ponto de entrada próprio, com segredo e verificação de assinatura do
   provedor, no mesmo padrão da entrega direta de e-mail (spec 02 §2.1).
7. **Regras de estado neutras quanto ao canal** (§2.2): nenhum canal novo pode
   exigir mudar a spec 01.

### 8.2 Chat avançado

- **Chat anônimo**: sem e-mail, com um Endereço do tipo "visitante do chat"
  ligado ao widget; o visitante só recebe respostas no widget.
- **Identidade assinada**: o site da conta envia uma assinatura calculada no
  servidor dele sobre o identificador do usuário; com assinatura válida, a
  identidade é aceita como verificada. A instância pode exigir assinatura em
  toda conversa.
- **Roteamento por disponibilidade**: o widget oferece conversa ao vivo só
  quando há agente do grupo disponível para chat (presença, spec 09); sem
  ninguém, continua no modo assíncrono.
- Bots, horário de chat próprio e transferência ao vivo entre agentes.

### 8.3 WhatsApp e SMS

- Uma instância por número, ligada a um provedor oficial.
- **Mapeamento**: a mensagem nova de uma Pessoa entra no ticket mais recente
  dela **naquela instância** que esteja aberto, pendente, em espera ou
  resolvido. Se o mais recente estiver fechado, vale a política de resposta em
  fechado do grupo (spec 01 §4.4). Se não houver ticket, cria um. Não há
  cabeçalhos de encadeamento, então essa é a única regra.
- O telefone vira um Endereço do tipo telefone, normalizado em E.164.
- **Janela de atendimento do provedor** (no WhatsApp, 24 h desde a última
  mensagem do cliente): é uma restrição do **despachante** do canal, não do
  ticket. Fora da janela, a resposta em texto livre é recusada antes do envio e
  o agente vê o motivo; o envio de modelos pré-aprovados pelo provedor é uma
  segunda etapa do roadmap.
- Limites de mídia do provedor são verificados antes do envio.
- Recibos de entrega e leitura atualizam o estado de entrega da mensagem;
  falha definitiva gera mensagem de sistema, como o bounce.

### 8.4 Redes sociais

- Só **mensagens privadas** de páginas ou contas comerciais, com o mesmo
  mapeamento do §8.3. Publicações e comentários públicos ficam fora até haver
  demanda clara: responder em público exige outra política de visibilidade.
- Cada integração depende de revisão comercial do provedor e de APIs que mudam;
  um dos projetos analisados está deixando de suportar uma rede por custo de
  API. Por isso o **canal genérico** vem antes das redes específicas.
- **Canal genérico**: instância com ponto de entrada para mensagens recebidas
  e um endereço de saída configurado pelo admin, para onde o PantherDesk entrega
  as respostas públicas. Permite plugar qualquer meio sem código no núcleo.

### 8.5 Unificação de contatos entre canais

- **Casamento automático só por identificador idêntico do mesmo tipo**: e-mail
  com e-mail (comparação do §4.5), telefone E.164 com telefone, identificador de
  provedor com o mesmo provedor. Nunca por nome, nunca entre tipos diferentes.
- O MVP já permite ao agente **acrescentar um endereço de e-mail** a uma
  Pessoa, desde que o endereço não pertença a outra Pessoa da conta.
- **Mesclar pessoas** está no MVP (spec 13 Δ22), com as regras da spec 01:
  endereços e tickets da origem passam ao destino; a origem fica marcada como
  mesclada, com ponteiro, sem exclusão definitiva. Esta spec só acrescenta: a
  mescla é sempre manual.
- Identidade declarada (formulário, chat) nunca dispara mescla automática.

---

## 9. Abordagens comparadas

### 9.1 Por projeto (segundo a documentação pública)

| Projeto | Abordagem de canais | Prós | Contras |
|---|---|---|---|
| Zammad | Muitos canais no núcleo (e-mail, web, formulário embutível, chat, SMS, Telegram, WhatsApp, Facebook). Formulário único por instância com isca, CAPTCHA opcional, limites por IP e teto diário. Mensageria: mensagens seguidas entram no ticket aberto mais recente do cliente. Chat convertido em ticket manualmente. | Anti-spam em camadas mais completo; regra clara de mapeamento na mensageria | Criação do solicitante pelo formulário não descrita; chat e ticket são mundos separados até a conversão; WhatsApp sem modelos não inicia conversa |
| Chatwoot | O canal é o tipo e cada caixa é uma instância; muitos canais, inclusive um genérico via API. Opção de uma única conversa aberta por contato. Contatos globais com mescla manual e validação de identidade por assinatura no widget. | Separação tipo × instância; canal genérico; identidade assinada | Sem formulário próprio; sem anti-spam documentado no widget; mescla de contatos apaga o outro registro sem volta |
| FreeScout | Núcleo só de e-mail; demais canais e portal são módulos pagos. Portal entra por link de uso único; o formulário grava direto, sem e-mail ao cliente e sem CAPTCHA no módulo. | Simples; link de uso único evita senha | Sem confirmação ao cliente; anti-spam depende de outro módulo; clientes compartilhados entre caixas |
| osTicket | E-mail, portal e API. A categoria escolhida pelo cliente define departamento, prioridade e confirmação. CAPTCHA opcional e limite de tickets abertos por usuário. | Limite de abertos por usuário é barato e eficaz | Poucos canais; CAPTCHA local de qualidade baixa; aviso ao exceder o limite revela informação |
| Znuny | E-mail, telefone registrado pelo agente e canal interno; portal com autorregistro; integrações por web services genéricos. | Registra o meio da mensagem desde sempre | Sem anti-spam documentado no portal; nenhum canal de mensageria no núcleo |
| UVdesk | E-mail e página pública de criação (login opcional); WhatsApp por módulo; listas de bloqueio e permissão por e-mail, domínio e IP, com a permissão vencendo. | Listas com precedência clara | CAPTCHA incerto; pouco documentado sobre identificação |
| Frappe Helpdesk | E-mail, telefonia ligada ao ticket e portal com sugestão de artigos enquanto o cliente digita; cadastro aberto pode ser desligado. | Deflexão na abertura; cadastro fechado por convite | Sem anti-spam documentado; sem mensageria |

### 9.2 Escolhas do PantherDesk

| Tema | Abordagens observadas | Escolha e motivo |
|---|---|---|
| Modelo de canal | tipo × instância (1); meio gravado por mensagem (1); canal implícito (outros) | tipo + instância em cada mensagem, desde o MVP: permite canais novos sem migração |
| Canais no MVP | de 3 a 9 no núcleo | e-mail + formulário do portal + chat assíncrono + agente + API; mensageria no roadmap. O chat entra porque a operação EARJ o usa (spec 13 R24) |
| Formulário | formulário único por instância (1); categoria do cliente define o destino (1); página pública simples ou nenhuma (outros) | vários formulários guardados, um ativo, com campos condicionais: atende a classificação encadeada da EARJ sem um formulário por grupo |
| Anti-spam do formulário | camadas com isca, CAPTCHA e limites (1); CAPTCHA + limite de abertos (1); listas (1); nada (3) | camadas baratas sempre ligadas (volume, token, isca, domínio, lista, não resolvidos) e CAPTCHA plugável desligado: protege sem atrito para o cliente |
| Resposta ao robô | rejeição explícita (vários) | resposta idêntica para aceito e quarentena; o número vai só no e-mail |
| Solicitante do formulário e do chat | criado pelo e-mail (provável em todos; não documentado) | reaproveita a Pessoa pelo endereço, sem alterar o nome; endereço novo nasce não verificado; histórico só com posse comprovada |
| Confirmação | por categoria (1); nenhuma (1); não documentada (outros) | gatilho padrão de confirmação (spec 05), sem eco do conteúdo para endereço não verificado, com limite por endereço: confirma sem virar disparador de spam |
| Chat × ticket | conversão manual (1); conversa é a unidade (1) | o chat é ticket desde a primeira mensagem, assíncrono, com e-mail quando o visitante não lê em 2 minutos |
| Mensageria | ticket aberto mais recente (1); uma conversa aberta por contato (1) | roadmap: ticket mais recente não fechado na instância, depois política de fechado da spec 01 |
| Unificação | contato global + mescla destrutiva (1); por e-mail (vários) | casamento só por identificador idêntico; mescla manual de pessoas, com ponteiro e sem exclusão (spec 01) |

---

## 10. Casos de teste (critérios de aceite)

Configuração: conta com formulário do portal ativo (assunto, mensagem, anexos)
e "aceitar pedidos de visitantes" ligado, grupo de destino N1; caixa
`suporte@pd.test` ligada ao N1; gatilho padrão de confirmação ativo; limites
padrão do §4.4. Widget de chat "Site" ativo, grupo padrão N1. Política de
resposta em fechado do N1 = `janela` (padrão), salvo indicação. Atores: `ag1` e
`ag2` (escrita no N1), `ag3` (escrita no Financeiro), `admin`, `ana` e `bia`
(org. Acme, endereços `ana@acme.test` e `bia@acme.test`), `cris` (sem org.,
`cris@mail.test`), `dani` (não existe na conta; usa `dani@mail.test`).
"Envio válido" = token com mais de 3 s, campos válidos, isca vazia, sem
sessão no portal.

### 10.1 Canal de origem
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| CH-01 | — | ana envia e-mail novo para suporte@pd.test | ticket com canal de origem `email` + caixa suporte@pd.test; a mensagem tem o mesmo canal |
| CH-02 | ticket CH-01 | ag1 responde pela interface; ana responde pelo portal | mensagens com canais `agente` e `portal`; o canal de origem continua `email` |
| CH-03 | — | ag1 cria ticket para cris no modo registrar pedido, informando meio "telefone" | canal de origem `agente`; meio declarado "telefone" visível ao agente e na API; mensagem inicial com autoria de cris, marcada "registrada por ag1"; nenhuma confirmação a cris |
| CH-04 | — | ticket criado pela API com o token de ag1 | canal `api`; a auditoria identifica o token |
| CH-05 | ticket de origem `formulario` | ag1 envia resposta pública | a resposta sai por e-mail para o endereço declarado (canal de resposta = e-mail) e aparece no portal |
| CH-06 | #A (origem `email`) mesclado em #B (origem `formulario`) | consultar #B | cada mensagem mantém seu canal; a origem de #B continua `formulario` |
| CH-07 | ticket de origem `formulario` | ana consulta o ticket pelo portal e pela API de solicitante | o canal não aparece para ela |

### 10.2 Envio do formulário
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| CH-10 | dani não existe na conta | envio válido de dani | Pessoa "dani" criada com endereço não verificado; ticket aberto no N1, sem responsável; 1 mensagem pública `formulario`; resposta 200 sem número do ticket |
| CH-11 | ana existe com nome "Ana Ribeiro" | envio válido com e-mail `ANA@Acme.test ` e nome "A. R." | solicitante é a Pessoa ana existente; nenhuma Pessoa nova; o nome cadastrado continua "Ana Ribeiro"; "A. R." gravado como nome informado |
| CH-12 | — | envio com assunto de 151 caracteres | 422 com o campo assunto; nada gravado |
| CH-13 | — | envio com mensagem contendo `<script>alert(1)</script>` | ticket criado; o corpo é exibido como texto literal, sem execução e sem HTML interpretado |
| CH-14 | anexos ligados | envio com 6 arquivos | 422; nada gravado |
| CH-15 | aceite de privacidade exigido | envio sem marcar o aceite | 422; com o aceite marcado, a mensagem guarda o momento e a versão do texto |
| CH-16 | envio válido aceito | o navegador reenvia a mesma requisição (mesmo token) | 200 com a mesma página; continua existindo um único ticket |
| CH-17 | nenhum formulário ativo | qualquer envio | 404; nada gravado |
| CH-18 | o banco falha na etapa de criação | envio válido; depois reenvio com o mesmo token | primeira resposta 500 sem nada gravado; o reenvio cria um único ticket |
| CH-19 | automação "canal de origem = formulario e assunto contém fatura → grupo Financeiro" | envio válido com assunto "fatura em dobro" | ticket no Financeiro; evento de mudança de grupo com origem automação |
| CH-50 | formulário com "Motivo do contato" (lista, obrigatório) e "Equipamento" (obrigatório, só se motivo = hardware) | envio válido com motivo = rede e Equipamento vazio | ticket criado; Equipamento não exigido e sem valor (revisto em v0.3, D51) |
| CH-51 | idem | envio com motivo = hardware e Equipamento vazio | 422 indicando Equipamento; nada gravado (revisto em v0.3, D51) |
| CH-52 | idem | envio forjado com motivo = rede e Equipamento = "impressora" | 422 no campo Equipamento (campo oculto); nada gravado (revisto em v0.3, D51) |
| CH-53 | campo personalizado "só agentes" incluído na lista do formulário | dani abre o formulário; depois um envio forjado traz valor para esse campo | o campo não aparece; o envio forjado recebe 422 nesse campo |
| CH-54 | formulário de suporte A ativo; dani abriu a página de A | admin ativa o formulário de suporte B; dani envia A | A fica inativo e B ativo na mesma operação; o envio de dani recebe 422 pedindo para recarregar, com o que ela digitou preservado |
| CH-55 | formulário B inativo | admin usa a pré-visualização de B e envia | validações aplicadas; nenhum ticket, nenhuma Pessoa, nenhum e-mail |
| CH-56 | ana com sessão no portal | ana envia o formulário ativo | solicitante ana; canal `portal`; nome e e-mail não pedidos; sem isca e sem CAPTCHA |
| CH-57 | "aceitar pedidos de visitantes" desligado | envio sem sessão | 401 com o pedido de entrada no portal; nada gravado |
| CH-58 | — | envio de visitante sem e-mail | 422 no campo e-mail; nada gravado (spec 13 ER-86) |

### 10.3 Anti-spam
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| CH-20 | — | envio com o campo-isca preenchido | 200 com a página idêntica à de um envio aceito; quarentena com motivo "isca"; nenhum ticket, nenhuma Pessoa, nenhum e-mail |
| CH-21 | — | envio 1 s depois de exibir a página | quarentena com motivo "rápido demais"; resposta 200 idêntica |
| CH-22 | — | envio com token emitido há 25 h | 422 pedindo para recarregar; nada gravado |
| CH-23 | mesmo IP fez 5 envios aceitos na última hora | 6º envio válido | 429; nada gravado; evento operacional da camada 1 |
| CH-24 | teto global 200 atingido hoje | 201º envio, de outro IP | 429; o admin recebe um único aviso no dia, mesmo com novos envios barrados |
| CH-25 | — | envio com e-mail `x@dominio-sem-mx.test` (sem MX nem A) | 422 no campo e-mail |
| CH-26 | o DNS não responde | envio válido | aceito (falha aberta); ticket criado |
| CH-27 | domínio `spam.test` na lista de bloqueio | envio de `z@spam.test` | quarentena com motivo "bloqueio"; resposta 200 idêntica |
| CH-28 | domínio `acme.test` bloqueado e `ana@acme.test` com permissão explícita | envio de ana | aceito; ticket criado |
| CH-29 | cris tem 5 tickets do formulário não resolvidos: 3 abertos, 1 pendente e 1 em espera | 6º envio válido de cris | quarentena "limite de abertos"; resposta 200 idêntica; nenhuma confirmação |
| CH-30 | — | envio declarando `suporte@pd.test` como e-mail | quarentena "endereço da própria conta"; nenhum e-mail enviado |
| CH-31 | uma implementação de CAPTCHA instalada e ligada | envio sem prova válida | 422; nada gravado |
| CH-32 | envio de CH-20 em quarentena | admin libera duas vezes | um único ticket criado; confirmação enviada uma vez |

### 10.4 Confirmação e identificação
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| CH-40 | — | envio válido de cris | o gatilho de confirmação envia um e-mail a cris@mail.test com o número e `[PD-{número}]` no assunto, Message-ID no domínio pd.test, `Auto-Submitted: auto-replied`, cabeçalho de laço e o link de convidado do ticket; o corpo **não** contém o assunto, a mensagem nem o nome informado |
| CH-41 | CH-40; endereço de cris não verificado | cris responde ao e-mail de confirmação | a resposta entra no mesmo ticket (In-Reply-To com o Message-ID da confirmação); o endereço de cris **continua não verificado** (D38) |
| CH-42 | — | 4 envios válidos de cris em 24 h (IPs diferentes) | 4 tickets; 3 confirmações; a 4ª suprimida com evento registrado |
| CH-43 | endereço de bia marcado inválido | envio válido de bia | ticket criado; nenhuma confirmação; aviso de endereço inválido no ticket |
| CH-44 | gatilho de confirmação desativado pelo admin | envio válido | ticket criado; nenhum e-mail ao solicitante |
| CH-45 | ana tem 3 tickets antigos; alguém envia o formulário com o e-mail de ana | o visitante tenta ver tickets no portal sem link nem login | nenhum ticket de ana é mostrado; a tela de agradecimento é a única resposta |
| CH-46 | CH-10 | dani usa o link de convidado da confirmação | o endereço de dani passa a verificado; dani vê aquele ticket no portal |
| CH-47 | — | envio válido declarando o e-mail de ag1 | ticket com ag1 como solicitante; nenhuma mensagem com papel de agente; endereço continua não verificado pelo formulário |
| CH-48 | Pessoa cris com `cris@mail.test` | ag1 acrescenta `cris@outro.test` a cris; depois tenta acrescentar `ana@acme.test` | o primeiro é aceito; o segundo é recusado (endereço já pertence a ana) |
| CH-49 | CH-10; endereço de dani não verificado | chega um e-mail de dani@mail.test sem In-Reply-To nem References, só com `[PD-{número}]` no assunto | a mensagem segue a spec 02 (entra no ticket pelo marcador); o endereço **continua** não verificado |
| CH-59 | gatilhos de confirmação dentro e fora do horário (calendário seg–sex 07:00–17:00, America/Sao_Paulo) | envio válido de cris na quarta 2026-11-11 18:30 | um único e-mail de confirmação, o de fora do horário; sem eco do assunto nem da mensagem |

### 10.5 Chat no site
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| CH-60 | — | dani informa nome e e-mail no widget e envia "projetor não liga" | ticket com canal de origem `chat` + widget "Site", estado aberto, grupo N1, sem responsável; Pessoa dani criada com endereço não verificado; 1 mensagem pública `chat` |
| CH-61 | — | visitante tenta iniciar conversa sem e-mail | recusado; nada gravado |
| CH-62 | após CH-60, ticket aberto | dani envia outra mensagem | entra no mesmo ticket, canal `chat`; nenhum ticket novo |
| CH-63 | após CH-60, widget de dani aberto | ag1 envia resposta pública | aparece no widget em tempo real; marcada "lida"; nenhum e-mail sai |
| CH-64 | após CH-60, widget fechado | ag1 responde às 10:00:00 | às 10:01:59 nenhum e-mail; às 10:02:00 sai **um** e-mail a dani@mail.test com a resposta e `[PD-{número}]`; a entrega registra "e-mail" |
| CH-65 | após CH-64 | dani responde ao e-mail | a mensagem entra no ticket com canal `email`; a próxima resposta de ag1 sai por e-mail |
| CH-66 | ticket de chat resolvido | dani escreve no widget | o ticket volta para aberto |
| CH-67 | ticket de chat fechado; política do N1 = `novo` | dani escreve no widget | ticket novo vinculado ("continuação de #N"), canal de origem `chat`; o widget passa a mostrar o ticket novo; o fechado não muda |
| CH-68 | ticket de chat aberto, widget de dani aberto | ag1 envia resposta pública e resolve | a resposta e a pesquisa aparecem no widget; nenhum e-mail de convite |
| CH-69 | idem, widget fechado | ag1 envia resposta pública e resolve; 2 min sem leitura | **um** e-mail com a resposta e o convite da pesquisa; nenhum segundo e-mail |
| CH-70 | — | dani anexa um PDF de 9 MB; depois um PDF de 11 MB; depois um arquivo executável de 1 MB | o primeiro é aceito; o segundo e o terceiro são recusados com o motivo, sem gravar nada |
| CH-71 | ag1 digitando resposta pública no ticket de dani | — | o widget mostra "o agente está escrevendo"; nenhum evento de auditoria; ao escrever nota interna, o indicador não aparece |
| CH-72 | ticket de chat com nota interna de ag1 e uma conversa paralela | dani abre o widget | só as mensagens públicas aparecem |
| CH-73 | ticket de chat em espera | dani escreve no widget | estado aberto; no widget, dani nunca vê "em espera" |
| CH-74 | mesmo IP iniciou 5 conversas na última hora | 6ª conversa nova | 429; nada gravado |
| CH-75 | domínio `spam.test` bloqueado | visitante inicia conversa com `z@spam.test` | quarentena "bloqueio"; o widget mostra a mesma confirmação de mensagem recebida; nenhum ticket |
| CH-76 | ana com sessão no portal; widget dentro do portal | ana envia mensagem | solicitante ana, sem pedir nome nem e-mail; canal `chat` |

### 10.6 Ajustes D23–D37
| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| CH-77 | — | dani (visitante) inicia conversa no widget com nome e e-mail | ticket de canal `chat`; **uma** confirmação pelo gatilho da spec 05 §6, com número e link de convidado, sem o texto digitado por dani (D25) |
| CH-78 | endereço de cris não verificado | em 24 h, cris faz 2 envios válidos pelo formulário e inicia 2 conversas no chat | 4 tickets; 3 confirmações; a 4ª suprimida com evento registrado (o limite soma os canais) |
| CH-79 | — | ag1 cria ticket para cris no modo registrar pedido sem informar o meio declarado | recusado (422) no meio declarado; nada gravado (D34) |
| CH-80 | — | ag1 cria ticket para cris no modo registrar pedido, meio "presencial" | canal `agente`, meio declarado "presencial"; o filtro por meio declarado (spec 08) e o relatório por canal (spec 11) mostram o ticket como `agente` / presencial |

### 10.7 Decisões de 2026-10-29 (QR, formulário de evento, Google)

Configuração adicional: login com Google para o domínio `escola.test`;
endereços `ana@escola.test` (ana, verificado) e `ze@escola.test` (Pessoa "Zé",
criada por um envio de visitante, **não verificado**). Cadastro de locais da
spec 01 §9.10: salas "Sala 101" (`B101`) e "Auditório" (`BAUD`) ativas, "Lab 2"
(`BLAB2`) desativada. Formulário de suporte ativo com o campo Local;
formulário de evento ativo, grupo Eventos, antecedência de 5 dias úteis no
calendário C5 da spec 05 (seg–sex 07:00–17:00, America/Sao_Paulo).
2026-11-11 é uma quarta-feira.

| ID | Dado | Ação | Resultado esperado |
|---|---|---|---|
| CH-81 | ana com sessão no portal | ana abre o QR de `B101` e envia o formulário | formulário com campus Barra, prédio A, 1º andar e Sala 101 travados; ticket com local Sala 101, canal `portal`; a mensagem registra a origem "QR" |
| CH-82 | idem | ana escolhe "não estou nesta sala", escolhe Auditório e envia | local Auditório; origem "escolha" |
| CH-83 | ana sem sessão | ana abre o QR de `B101` e entra com Google | depois da entrada, ana volta ao formulário com a Sala 101 travada |
| CH-84 | Sala 101 com 3 tickets: um aberto no N1, um em espera no Financeiro, um resolvido no N1 | ag1 (escrita no N1, sem acesso ao Financeiro) abre o QR de `B101` | lista com 1 ticket (o aberto do N1), com "assumir"; a opção de ticket novo abre a criação com local Sala 101 |
| CH-85 | — | alguém abre o QR com o código `XYZ` (inexistente) e depois o de `BLAB2` (desativada) | nos dois casos, o formulário abre sem local e com o aviso de sala não encontrada; nenhuma resposta 404 |
| CH-86 | ana com sessão | envio forjado com local = `BLAB2` | 422 no campo local; nada gravado |
| CH-87 | ana com "minhas salas" = Auditório, Sala 101 | ana abre o formulário de suporte sem QR | local Auditório preenchido, **não** travado; origem "minhas salas" ao enviar |
| CH-88 | admin renomeia a Sala 101 para "Sala 101 — Ciências" | ana abre o mesmo QR de `B101` | o formulário mostra o nome novo; o QR impresso continua válido |
| CH-89 | — | dani (visitante) abre o QR de `B101` e escolhe "continuar sem entrar" | formulário de visitante com a Sala 101 travada; envio válido cria ticket `formulario` com local Sala 101 |
| CH-90 | ana com sessão; qua 2026-11-11 10:00 | ana envia o formulário de evento: "Assembly do 5º ano", tipo de evento assembly, qui 2026-11-19 14:00–16:00, montagem qua 2026-11-18 08:00, Auditório | ticket tipo evento no grupo Eventos, canal `portal`, assunto "Assembly do 5º ano", sem a marca "fora do prazo" (5º dia útil depois de qua 11 = qua 18) |
| CH-91 | idem | montagem ter 2026-11-17 08:00 | o formulário avisa antes do envio; ticket criado com a marca "fora do prazo"; ana não vê a marca no portal |
| CH-92 | idem | envio com montagem às 15:00 do dia do evento (depois do início, 14:00); outro com data do evento seg 2026-11-09 | os dois recusados (422); nada gravado |
| CH-93 | — | visitante sem sessão envia o formulário de evento | 401 com o pedido de entrada; nada gravado |
| CH-94 | formulário de suporte A e formulário de evento E ativos | admin ativa o formulário de suporte C | A fica inativo; C e E ativos |
| CH-95 | — | alguém tenta entrar no portal com Google usando `x@outro.test` | recusado; a tela oferece o link por e-mail; nada é criado |
| CH-96 | Pessoa "Zé" com `ze@escola.test` não verificado e 1 ticket do formulário | Zé entra no portal com Google | mesma Pessoa, endereço passa a **verificado**; Zé vê o ticket no portal; nome cadastrado inalterado |
| CH-97 | ninguém tem `novo@escola.test` | a pessoa entra com Google e envia o formulário de suporte | Pessoa criada com o nome da conta Google, endereço verificado, papel solicitante; ticket `portal`; a confirmação (spec 05 §6.1) segue as regras de endereço verificado |
| CH-98 | ag1 é agente com endereço `ag1@escola.test` | ag1 pede o link por e-mail na tela de entrada; depois entra com Google | o pedido do link recebe a resposta comum, e **nenhum** e-mail é enviado (spec 07 KB-57); pelo Google, ag1 entra na área do agente (D53) |
| CH-99 | formulário de suporte com o campo Local e com motivo → equipamento → sintoma; ana abre o QR de `B101` | ana escolhe motivo hardware, equipamento impressora, sintoma "não imprime" e envia | ticket com local Sala 101 (origem "QR") e os três campos; nenhum campo personalizado de unidade ou sala existe no formulário (D51) |

---

## 11. Evidências

| Tema | Fonte atual | Evidência de runtime pendente |
|---|---|---|
| Campos do formulário, criação do solicitante, confirmação | documentação parcial (criação do solicitante não descrita em nenhum) | C-01 |
| Anti-spam efetivo (isca, CAPTCHA, limites, código de resposta) | documentado em 3 projetos; ausência em 3 | C-01 |
| Formulário sem e-mail ao cliente (um projeto) | documentação | C-01 |
| Chat: transcrição, conversão em ticket, saída do visitante, e-mail de fallback | documentação | C-02 |
| Uma conversa aberta por contato | documentação (opção de um projeto) | C-02 |
| Inventário de mensageria e redes | documentação e catálogos | C-03 |
| Mesmo cliente por e-mail e formulário; mescla de contatos | documentação parcial | C-04 |
| Telefone casando com contato existente | não documentado | C-04 (variante) |
| Formulário com campos condicionais e uso real do formulário e do chat | requisitos de cliente (spec 13) | não se aplica |
| QR por sala, formulário de evento, login com Google | requisitos de cliente (spec 13 Δ31, Δ33, Δ34) | não se aplica |

## 12. Questões abertas para o implementador

- **Entradas de permissão na lista de bloqueio**: a spec 02 §3 já tem
  bloqueio por endereço, domínio e IP; as entradas de **permissão** que vencem
  o bloqueio por domínio (§4.4, camada 6) só existem nesta spec. Confirmar que
  valem também para o e-mail.
- Os limites (5/h e 20/dia por IP, 200/dia global, 5 não resolvidos, 20
  mensagens de chat por minuto, 2 minutos para a entrega por e-mail) são
  propostas. O limite de 3 confirmações por endereço não verificado foi fixado
  pela D25. Ajustáveis por conta.
- Tipos de anexo permitidos e antivírus não estão definidos para o e-mail nem
  para o formulário (o chat aceita só imagens e PDF).
- Confirmar com o responsável se a página de agradecimento sem número é
  aceitável. Mostrar o número enfraquece a resposta uniforme ao robô.
- Respostas seguidas do agente não lidas no chat: esta spec manda um e-mail
  por resposta. Agrupar várias respostas num único e-mail reduziria o volume,
  mas atrasaria a primeira. Decidir com o uso real.
- **Formulário de evento sem login** (§4.10): esta spec exige sessão, porque
  quem pede eventos é a equipe da escola. Confirmar que pais e visitantes não
  pedem eventos pelo portal.
- **QR para o agente** (§4.9): a spec 13 Δ33 fala em "tickets abertos" da sala;
  esta spec lê como **não resolvidos** (aberto, pendente e em espera).
  Confirmar.
