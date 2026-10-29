# Estudo de interface: Frappe Helpdesk (lado "sujo" do muro)

- **Projeto estudado:** frappe/helpdesk (GitHub), clone raso
- **Commit:** d496b4dc187fa36a66695125b2e8df77f1c438d0 (29/10/2026)
- **Licença:** GNU AGPL-3.0. Nada foi nem deve ser copiado: código, nomes, textos de interface, ícones, cores ou medidas.
- **Material lido:** frontend do agente, portal do cliente, dados de colunas padrão do backend, imagens do README. Não rodei scripts nem builds.
- **Regra de uso:** este documento traz só princípios abstratos, escritos com nossas palavras. Para o PantherDesk vale a seção 3, junto com a identidade própria (azul-marinho, azul royal, vermelho, pantera).

---

## Tecnologia do frontend, em termos gerais

- Aplicativo de página única em um framework reativo de componentes, com roteador e gerenciamento de estado leve.
- Uma **biblioteca de componentes própria do ecossistema** (botões, menus suspensos, diálogos, abas, listas, emblemas, avatares, barra lateral, estados de carregamento). Ela entrega a maior parte da consistência visual, e o app quase só monta peças prontas.
- **CSS utilitário** com um "preset" fornecido pela biblioteca. As cores não são usadas de forma literal. A interface usa **tokens semânticos** com nome de função, como "superfície", "tinta" (texto) e "contorno", cada um em uma escala de cinzas. O modo escuro só troca os valores desses tokens.
- Ícones de **um único conjunto de traço fino** (estilo contorno), mais alguns ícones próprios no mesmo traço.
- Editor de texto rico baseado em ProseMirror.
- O portal do cliente é feito em um construtor de páginas por blocos do mesmo ecossistema. Ele reaproveita a mesma biblioteca, os mesmos tokens e vários componentes compartilhados com o lado do agente, por isso os dois lados parecem da mesma família.

---

## 1. Princípios que explicam a limpeza visual

1. **A cor fica reservada para o estado.** Quase tudo é cinza neutro, quase sem saturação. A cor aparece em pontos pequenos que indicam status, em emblemas de prazo e em pouquíssimo mais. A marca quase não aparece dentro do app (só o logotipo).
2. **Superfícies planas separadas por linhas finas, não por caixas.** Quase não há sombras nem cartões empilhados. Regiões (barra lateral, cabeçalho, lista, painel lateral) se separam por uma única linha cinza muito clara. Sombra só existe em camadas flutuantes (menus, diálogos, paleta de comandos).
3. **Pouco peso tipográfico.** Há só dois pesos: normal e médio. O negrito forte é raro e tem função, como marcar um ticket não lido. A hierarquia vem da cor do texto (escuro para valores, cinza médio para rótulos e metadados), mais do que do tamanho.
4. **Uma ação primária por tela, o resto discreto.** Só o botão principal da página (criar ticket, fechar ticket no portal) é sólido e escuro. Os demais são "fantasmas" ou levemente acinzentados e só ganham fundo no hover.
5. **Informação secundária escondida por padrão.** Ações raras vão para um menu de três pontos. Ações de linha aparecem só no hover. Seções do painel lateral recolhem. Filtros, ordenação e colunas ficam atrás de botões compactos.
6. **Layout de três zonas, sempre igual.** Navegação à esquerda, conteúdo no centro, contexto à direita. A posição das coisas não muda entre telas, então o olho não precisa procurar.
7. **Alinhamento rígido em colunas.** No painel de propriedades, todos os rótulos têm a mesma largura fixa e todos os valores começam na mesma vertical. O código chega a compensar 1 ou 2 pixels para manter isso. A sensação de ordem vem desse alinhamento.
8. **Edição no próprio lugar.** Propriedades do ticket parecem texto simples, mas viram seletor ao clicar. Não há formulário com cara de formulário nem botão "salvar" para cada campo.
9. **Ícones pequenos, monocromáticos e sempre acompanhados de texto** na navegação e nos botões principais. Ícone sozinho só aparece em ações muito óbvias, como responder ou mais opções, e vem com dica ao passar o mouse.
10. **Metadados resumidos e relativos.** Datas aparecem como "há 2 horas" ou como contagem regressiva curta, e o detalhe completo fica numa dica. A prioridade é um ícone de barras em cinza, não um selo colorido.
11. **Estados vazios e de carregamento calmos.** Carregar mostra esqueletos do mesmo formato da lista, e o portal lembra quantas linhas havia para o esqueleto não "pular". O estado vazio é um ícone cinza grande, uma frase curta e, no máximo, uma dica.
12. **Movimento curto e funcional.** Seções recolhem com transição suave. O editor de resposta desliza para cima. O destaque de navegação muda na hora do clique, antes de a página carregar. Nada anima por enfeite.
13. **Teclado como atalho paralelo, não como requisito.** Letras simples agem sobre o ticket aberto, há uma paleta de comandos global e um painel que lista os atalhos. Nada disso aparece na tela além de uma pequena indicação ao lado de "Buscar".
14. **Ruído técnico some.** As barras de rolagem são finas e discretas, os títulos longos são truncados com reticências e os nomes completos ficam em dicas.
15. **Mesma linguagem para agente e cliente.** O portal reaproveita lista, pontos de status, painel de propriedades e esqueletos, só com menos opções. O cliente não percebe outro "produto".

---

## 2. Descrição por tela

### 2.1 Estrutura geral (agente)

- **Barra lateral esquerda** de largura média e recolhível até sobrar só a coluna de ícones. No topo ficam o bloco de identidade e o menu do usuário. Logo abaixo vêm duas ferramentas, busca (com indicação do atalho) e notificações (com contador cinza discreto). Depois de um respiro vem a navegação principal: início, painel, tickets, base de conhecimento, clientes e contatos. Mais abaixo ficam grupos recolhíveis de "visões salvas" (públicas e privadas), cada uma com seu ícone. No rodapé, ajuda e o botão de recolher.
- O item ativo ganha só um fundo cinza claro. Não há barra colorida, ícone colorido nem texto em negrito.
- O menu de cada visão salva (três pontos) só aparece no hover.
- **Cabeçalho do conteúdo** em uma linha fina: à esquerda fica a trilha de navegação (seção / item), à direita as ações da página. Não há barra superior global com logotipo, busca e avatar, porque essas coisas ficam na lateral.

### 2.2 Lista de tickets

- Cabeçalho: o título funciona como seletor de visão (menu que alterna entre visões padrão, salvas e públicas, e permite criar uma). À direita fica um único botão sólido escuro, "criar".
- Abaixo vem uma faixa de controles. Filtros rápidos ficam à esquerda. À direita, separados por um divisor vertical fino, ficam recarregar, filtro, ordenar, agrupar e colunas, todos discretos. Um botão para salvar a visão só aparece quando a visão foi alterada.
- **Colunas padrão** (nesta ordem, aproximadamente): seleção, ID, assunto (a coluna mais larga), status, prazo de primeira resposta, prazo de resolução, responsável, cliente, prioridade, tipo, equipe, contato, avaliação e criado em. Na prática a tela mostra as primeiras seis a oito colunas, e o restante fica fora da área visível ou desativado pelas configurações de colunas.
- Formato de cada célula:
  - Assunto: texto simples, truncado. Fica em **negrito só quando o agente ainda não viu o ticket**, que é o único destaque tipográfico da linha.
  - Status: um ponto colorido pequeno seguido do nome em texto normal.
  - Prioridade: ícone de barras em cinza (mais barras cheias = mais alta). Só "urgente" ganha um glifo diferente, também cinza.
  - Prazos (SLA): emblema pequeno e suave com a contagem regressiva curta enquanto o prazo corre. Depois vira "cumprido" em cinza ou "estourado" em vermelho suave. A data completa fica na dica.
  - Responsável: avatar pequeno e nome.
  - Data: relativa.
- Linhas baixas e uniformes, separadas por linha clara, com hover em cinza muito leve. Clicar na linha abre o ticket.
- Ao selecionar linhas, uma faixa flutuante com ações em massa (responder, atribuir, mais opções) aparece no rodapé. As ações destrutivas ficam dentro do menu.
- Rodapé com o seletor de tamanho de página (três opções), "carregar mais" e a contagem "x de y".
- Colunas redimensionáveis. Também existe um modo "agrupar por", que troca as linhas por um resumo de grupos com totais.
- Estado vazio: ícone de ticket cinza, título curto e uma descrição que muda conforme o contexto (há filtro ativo ou não, é uma visão salva ou não).

### 2.3 Tela do ticket (agente)

- **Cabeçalho:** trilha "Tickets / assunto do ticket". À direita aparecem, nesta ordem, os avatares de quem está vendo o ticket agora, eventuais ações personalizadas, um botão de **status** (ponto colorido e nome, que abre menu) e um menu de três pontos com o resto (mesclar, editar assunto etc.).
- **Coluna central** (largura flexível):
  - Uma linha de abas com ícone e rótulo: atividade (tudo), e-mails, comentários e análise (mais ligações quando o recurso está ativo). As abas filtram a mesma linha do tempo.
  - **Linha do tempo:** eventos de sistema ("fulano mudou o tipo") são linhas finas de texto cinza, agrupadas e recolhidas ("mais N atividades"). E-mails e comentários são blocos com fundo levemente acinzentado ou borda fina, com o autor e o horário relativo no topo, e as ações (responder, responder a todos, mais) à direita, em ícones fantasmas. Um fio vertical fino liga os itens, e o avatar do autor fica à esquerda com um mini-ícone do tipo de mensagem. Comentários fixados aparecem numa faixa sobreposta no topo, que não desloca o conteúdo.
  - **Editor de resposta** preso ao rodapé da coluna. Em repouso mostra só dois botões fantasmas, "responder" e "comentar". Ao clicar, o editor desliza para cima. Ctrl/Cmd+Enter envia, Esc fecha. O botão de enviar mostra o atalho no próprio rótulo. Um indicador mostra quando outra pessoa está digitando.
- **Painel lateral direito** (largura fixa, redimensionável, separado por uma linha):
  - No topo fixo: o contato (avatar grande, nome, número do ticket e canal de origem) e dois prazos de SLA em formato rótulo/valor, com cor só no valor (verde se cumprido) e um ícone de informação com dica.
  - Abaixo, uma área rolável de **seções recolhíveis** com título em peso médio e uma pequena seta. Em "visão geral" ficam o responsável, a prioridade, o tipo, o cliente, a equipe e as etiquetas. Os campos personalizados ficam numa seção separada ("mais detalhes"), seguida de tickets recentes e semelhantes do mesmo contato (assunto truncado, data · número, emblema de status suave).
  - Cada campo é uma linha com **rótulo cinza de largura fixa à esquerda e valor escuro à direita**. O valor vira seletor ao clicar.
  - O título da seção gruda no topo ao rolar. Ao recolher uma seção, a rolagem é compensada para o título clicado não sair do lugar.
- Estados: carregando mostra um único indicador centralizado (documento e linha do tempo esperam juntos, para não piscar em duas etapas). "Não encontrado" mostra um ícone cinza, uma frase e um botão sutil de voltar.

### 2.4 Portal do cliente

- **Topo simples** em vez de barra lateral: logotipo, trilha de navegação, links rápidos, alternância claro/escuro e o menu da conta.
- **Início da base de conhecimento:** faixa de boas-vindas com busca em destaque, grade de categorias e artigos populares ou recentes em abas pequenas. Se ainda não houver artigos, aparece uma ilustração leve com dois caminhos: abrir chamado ou ver meus chamados.
- **Meus chamados:** a mesma lista do agente, enxuta. Colunas padrão: ID, assunto, status, prioridade, primeira resposta, resolução, equipe e criado em. Há filtros rápidos, filtro, ordenação e colunas. Como ação em massa, só exportar.
- **Novo chamado:** um formulário único e centrado. Enquanto o cliente digita o assunto, aparecem sugestões de artigos, para ele tentar resolver sozinho antes de enviar.
- **Tela do chamado:** é o mesmo esqueleto do agente com menos peças.
  - O centro mostra a conversa em blocos (ou em "bolhas", à escolha). As mensagens do próprio cliente ficam alinhadas de um lado e num tom de cinza um pouco diferente, e as dele não levam nome.
  - O editor fica no rodapé, recolhido como um campo de uma linha que se expande.
  - O lado direito tem o cartão do solicitante e as propriedades no formato rótulo/valor (status com ponto, prioridade, cliente, equipe), além de uma **linha do tempo do SLA** em marcos (recebido, atribuído, primeira resposta, resolução), com pontos preenchidos para o que já aconteceu e um ponto vazado para o que falta. Depois vem "ajuda relacionada", com links para artigos.
  - A única ação sólida do topo é fechar/encerrar o chamado.
- No celular, o painel lateral vira gaveta e a barra lateral de artigos vira uma folha que sobe de baixo.

### 2.5 Transversais

- **Atalhos de teclado:** paleta de comandos com Ctrl/Cmd+K (busca, navegação e tickets recentes). Há atalhos de configurações, ajuda e lista de atalhos. No ticket, letras simples: responder, comentar, status, atribuir, prioridade, tipo, equipe (com Shift) e etiquetas. Há atalhos para copiar o ID ou o link e Shift+< / > para o ticket anterior ou seguinte da visão. Na lista, uma tecla abre o filtro. Os atalhos são desativados enquanto se digita e com menus ou diálogos abertos.
- **Modo escuro:** troca global por atributo no documento. Os mesmos tokens semânticos recebem outros valores, então nenhuma tela tem regra própria além de casos pontuais (conteúdo de e-mail isolado, ilustrações). O portal tem alternância visível. No agente, ela fica nas preferências.
- **Responsividade:** o agente tem layout móvel separado. A barra lateral vira gaveta, e o ticket ganha uma versão própria em que propriedades e atividade viram abas, em vez de colunas lado a lado. A lista móvel mostra só filtro e poucos controles, e os botões perdem o rótulo e ficam só com o ícone.
- **Carregamento:** esqueletos no formato final (barra de controles, cabeçalho e linhas da lista). Um indicador giratório só aparece onde não há forma previsível.
- **Notificações:** painel que desliza da lateral. Avisos curtos aparecem como "toast".

---

## 3. O que aplicar no PantherDesk (regras concretas)

### Cor e identidade
1. **Base neutra:** a interface é 90% ou mais em branco e cinzas neutros de baixa saturação. O azul-marinho entra só no logotipo/pantera e, no máximo, na barra lateral, se quisermos um tom de identidade (e aí a barra inteira, nunca em detalhes espalhados).
2. **Azul royal = ação e foco.** Use-o no único botão primário da tela, no anel de foco e em links. Nunca como fundo de seção nem em ícones decorativos.
3. **Vermelho = só problema real:** prazo estourado, ticket urgente, erro, ação destrutiva confirmada. Se o vermelho aparece em mais de 2 ou 3 linhas numa tela comum, a regra está sendo violada.
4. **No máximo 1 elemento colorido por linha da lista** (normalmente o ponto de status ou o emblema de SLA, nunca os dois fortes ao mesmo tempo). Prioridade fica em ícone cinza, e só "urgente" ganha cor.
5. Status sempre como **ponto pequeno + texto normal**, nunca pílula de fundo saturado. Emblemas, quando houver, com fundo suave e texto um tom mais escuro da mesma cor.
6. Todas as cores vêm de **tokens semânticos com nome de função** (superfície, texto, contorno, destaque, perigo), definidos para claro e escuro desde o primeiro dia.

### Layout e espaçamento
7. Três zonas fixas: **barra lateral de navegação (recolhível) | conteúdo | painel de contexto à direita**. Nenhuma tela inventa outro arranjo no desktop.
8. Separação por **linhas finas de 1px em cinza claro**, não por cartões com sombra. Sombra só em menus, diálogos e paleta de comandos.
9. Cabeçalho de página em **uma única linha baixa**: trilha à esquerda, até 3 controles à direita (o primário por último), com o resto no menu de três pontos.
10. Espaçamento em escala de passos de 4px, com respiro horizontal generoso e constante na lateral do conteúdo (igual na lista, no cabeçalho e no rodapé). As linhas da lista são baixas, mas legíveis, e têm sempre a mesma altura.

### Tipografia
11. Uma família sem serifa só, com **dois pesos (normal e médio)**. Negrito fica reservado para "não lido" na lista.
12. Hierarquia por **cor do texto**: valores e títulos em quase preto, rótulos e metadados em cinza médio, desabilitado em cinza claro. Tamanhos: no máximo 3 na tela de trabalho (corpo, pequeno para metadados, um pouco maior para títulos de seção ou página).

### Lista de tickets
13. Colunas padrão: **seleção, nº, assunto (mais larga), status, prazo, responsável, prioridade, atualizado/criado (relativo)**. Solicitante, equipe/setor, tipo e categoria entram via seletor de colunas.
14. Assunto em negrito só se não foi visto pelo técnico. Datas relativas, com a data completa na dica.
15. Ações de linha e ações em massa **só aparecem no hover ou na seleção**. A faixa de ações em massa mostra no máximo 2 ou 3 ações visíveis, e o resto vai para "mais".
16. Visões salvas ("Meus abertos", "Sem responsável", "Atrasados") na barra lateral e no seletor do título, nunca como abas extras em cima da lista.

### Tela do ticket
17. **Propriedades do ticket em um painel lateral único à direita:** rótulo cinza de largura fixa à esquerda e valor à direita, todos alinhados na mesma vertical, com edição ao clicar e salvamento imediato.
18. O painel lateral começa com o **solicitante** (avatar, nome, sala/setor) e os **prazos**. Depois vêm seções recolhíveis: "Detalhes" (aberta), "Campos extras" e "Chamados anteriores deste usuário" (recolhidas por padrão).
19. Centro: abas de filtro (Tudo / Respostas / Notas internas), a linha do tempo e o **editor preso ao rodapé, recolhido em dois botões** ("Responder" e "Nota interna") até ser acionado.
20. Eventos de sistema em linha de texto cinza, agrupados ("+N alterações"). Mensagens em blocos com fundo levemente diferente. **Notas internas com um tratamento claramente distinto, mas suave**, como fundo levemente amarelado ou faixa lateral, nunca o mesmo visual de uma resposta ao usuário.
21. O status é um botão no cabeçalho (ponto + nome) que abre um menu. Mesclar, dividir, editar assunto e excluir vão para o menu de três pontos.

### Interação, estados e movimento
22. Atalhos: Ctrl/Cmd+K (paleta), letras simples no ticket (R responder, N nota, S status, A atribuir, P prioridade), Shift+setas para o próximo ou anterior, e "?" para abrir a lista de atalhos. Desativados enquanto se digita.
23. Carregamento: **esqueleto no formato final** para listas e painéis. Spinner só como último recurso, e um só por tela.
24. Estado vazio: ícone cinza simples, uma frase e, no máximo, uma ação. O texto muda conforme a causa (sem dados ou filtro sem resultado).
25. Transições entre 150 e 300 ms, só para abrir/recolher seções, deslizar o editor e abrir gavetas. Respeitar a preferência de "reduzir movimento".
26. O destaque da navegação muda no clique, sem esperar a rota carregar.

### Portal (professores, funcionários, alunos)
27. Portal com barra superior simples (pantera + nome do serviço, trilha, alternância de tema, conta), sem barra lateral.
28. A página inicial do portal é **busca + categorias da base de conhecimento**, com "Abrir chamado" e "Meus chamados" como as duas ações claras.
29. O formulário de novo chamado é curto e sugere artigos enquanto a pessoa digita o assunto.
30. Tela do chamado no portal: o mesmo esqueleto do agente com menos campos, mais uma **linha do tempo de marcos** (recebido, atribuído, respondido, resolvido) no lado direito. A única ação sólida é "Encerrar chamado".

### Escuro e celular
31. Modo escuro trocando só os valores dos tokens. Nenhum componente com cor fixa no código.
32. No celular, a barra lateral vira gaveta e o painel de propriedades vira aba ou gaveta. Botões perdem o rótulo e ficam com ícone e dica. A lista mostra só assunto, status e data.

---

## 4. O que evitar

- Copiar qualquer coisa do projeto estudado: código, nomes de componentes, textos de interface, ícones próprios, medidas ou cores exatas. O PantherDesk tem paleta, ícone e vocabulário próprios.
- **Arco-íris de status:** pílulas saturadas para status, prioridade, tipo e SLA na mesma linha.
- Usar o vermelho da marca como cor decorativa (títulos, ícones, fundos). Ele perde o significado de alerta.
- Cartões com sombra dentro de cartões. Bordas grossas. Fundos coloridos para separar seções.
- Barra de ferramentas cheia de botões com rótulo. Mais de um botão sólido na mesma área.
- Formulário completo com "Salvar" para editar propriedades do ticket.
- Mostrar todos os campos sempre abertos. Campos raros devem ficar recolhidos.
- Ícones de estilos misturados (preenchidos e contorno, coloridos e monocromáticos) ou ícones sem rótulo na navegação principal.
- Datas absolutas longas em toda linha. Excesso de negrito.
- Spinners múltiplos ou conteúdo que "pula" ao terminar de carregar.
- Animações decorativas ou longas.
- Atalhos que disparam enquanto se digita, ou atalhos sem uma tela que os liste.
- Portal com cara de outro sistema. Agente e usuário final devem reconhecer a mesma linguagem.
