# Estudo de fonte — Zammad (zammad/zammad)

- **Data do estudo:** 2026-10-29
- **Commit estudado:** `dd45341b1b089d8c1813d8891e95344078d917e6` (commit de 2026-10-29, clone raso do ramo padrão; versão declarada da série 7.3)
- **Licença:** **GNU AGPL-3.0**. Nada deste repositório pode ser copiado para o PantherDesk.
- **Postura:** este é o lado "sujo" do muro clean-room. O texto traz só conhecimento abstrato: comportamento, arquitetura e escolhas de tecnologia, descritos com palavras nossas. Não há trechos de código, SQL, GraphQL, nomes de funções, classes, tipos, arquivos, caminhos, tabelas, chaves de configuração nem textos de interface. O repositório foi clonado num diretório temporário fora do projeto e só foi lido; nada foi construído nem executado.
- **Foco:** o novo frontend de agente para desktop (Vue 3 + TypeScript) e o que o backend oferece para o técnico resolver rápido.
- **Tamanho aproximado:** cerca de 680 arquivos no frontend antigo (CoffeeScript), cerca de 670 componentes Vue e 2.600 arquivos TypeScript no frontend novo (desktop + celular + compartilhado), backend Rails grande, com cerca de 50 tipos de job e dezenas de traduções.

---

## 1. Resumo

O Zammad é um helpdesk maduro, omnicanal (e-mail, telefone, chat, SMS, WhatsApp, Telegram, redes sociais, formulário web), com backend em **Ruby on Rails**, **PostgreSQL** como fonte de verdade, **Redis** para o canal de tempo real e **Elasticsearch** como motor de busca opcional (também usado como banco vetorial para IA). O projeto vive uma transição longa: o frontend que está em produção ainda é o antigo (CoffeeScript + jQuery, falando REST), enquanto um frontend novo (Vue 3 + TypeScript + Vite, falando GraphQL com assinaturas por websocket) cresce ao lado, em duas aplicações separadas (desktop e celular) que compartilham uma camada comum. O desktop novo ainda é oferecido como "beta" que o usuário liga e desliga.

O desenho da tela de ticket do desktop novo é bom e coerente: uma coluna central com a conversa em "balões", uma barra superior com o cabeçalho do ticket que encolhe ao rolar, uma barra inferior fixa com o botão de salvar, quem está vendo e as macros, e um painel lateral com abas de ícone (informações do ticket, cliente, organização, checklist, resumo por IA, anexos, integrações externas). Os atributos do ticket ficam no painel lateral e são salvos junto com a resposta num único envio. A fila de trabalho é baseada em "visões" (listas salvas com filtros) e as entidades abertas viram abas persistentes no servidor.

O que é excelente: abas de trabalho persistidas no servidor (com o rascunho dentro), presença de quem está vendo e editando derivada dessas abas, regras de formulário avaliadas no servidor, checklist com tickets referenciados que se marcam sozinhos, rascunhos compartilhados com a equipe, resumo por IA estruturado e guardado em cache, e notificações que dizem por que você as recebeu. O que é poluído: três frontends convivendo, muitas camadas de "plugin" para coisas simples, configuração espalhada (gatilhos, macros, fluxos de formulário, visões, SLAs, agendadores — cada um com seu editor de condições), e várias pendências visíveis no frontend novo (opções comentadas esperando funcionalidade, "TODO" em pontos centrais, atrasos fixos para contornar rolagem).

---

## 2. Funções que ajudam o técnico a resolver rápido

**Conversa em balões com início e fim visíveis.** A tela carrega só as primeiras mensagens do ticket (o pedido original, que costuma ter o contexto) e as últimas dezenas; o meio fica recolhido atrás de um marcador "carregar mais". Assim um ticket longo abre rápido, o técnico vê o problema e o estado atual sem rolar, e o histórico intermediário vem sob demanda. Mensagens do sistema (mudanças automáticas) e avisos de falha de entrega aparecem como linhas distintas, menores, e não como balões, para não poluir a leitura.

**Distinção visual clara entre interno e público.** Notas internas têm estilo próprio, e há ação por mensagem para alternar entre interna e pública depois de enviada. No botão flutuante principal, o atalho padrão para um agente é "nota interna", não "responder ao cliente" — a escolha segura é a mais fácil.

**Barra de ferramentas flutuante na conversa.** Um pequeno grupo de botões fica sempre no canto da conversa: ir ao topo, ir ao fim, pular para a próxima mensagem não lida (com contador) e abrir a caixa de resposta. Quando chega mensagem nova e o técnico não está no fim da conversa, ela entra na contagem de não lidas em vez de empurrar a tela; se ele já está no fim, a mensagem simplesmente aparece. As setas esquerda/direita do teclado pulam entre mensagens quando o foco não está num campo.

**Resposta fixável.** A caixa de resposta pode ficar "presa" na parte de baixo da tela enquanto se rola a conversa, ou solta no fim da conversa. A preferência é lembrada no navegador. Isso permite ler o histórico e escrever ao mesmo tempo.

**Atributos e resposta salvos num só gesto.** O formulário do ticket (estado, prioridade, grupo, responsável, campos personalizados) e a mensagem nova são um único formulário lógico, mostrado em dois lugares da tela. Um único "atualizar" grava tudo. Campos alterados mostram uma marca de "sujo", e há um botão para descartar as alterações com confirmação. Se a validação falhar, a tela abre sozinha a aba lateral certa ou rola até a resposta.

**Regras de formulário no servidor.** Cada mudança num campo manda ao servidor o estado do formulário, e o servidor devolve quais campos ficam visíveis, obrigatórios, somente leitura, quais opções aparecem e quais valores mudam. Isso cobre coisas como "ao escolher pendente, exigir data de lembrete", "o responsável só pode ser alguém do grupo escolhido", detecção de ticket duplicado na abertura, e exigir registro de tempo antes de fechar. A lógica fica num só lugar e vale igualmente para todos os frontends.

**Bloqueios inteligentes ao fechar.** Ao tentar fechar um ticket com checklist incompleto, o sistema pergunta se o técnico quer resolver os itens (e abre o checklist) ou fechar mesmo assim. Se a contabilização de tempo é exigida, abre-se um painel para registrar o tempo, com opção de pular. O servidor sinaliza o motivo com um código, e o cliente reenvia o pedido marcando aquela verificação como já tratada.

**Comportamento depois de salvar.** O técnico escolhe nas preferências o que acontece depois de atualizar: ficar na aba, fechar a aba, ou fechar só se o ticket foi fechado. Macros podem impor seu próprio comportamento (por exemplo, fechar e ir para a próxima tarefa). Isso elimina cliques repetidos no fluxo "resolver e seguir".

**Macros no botão de salvar.** O botão de atualizar é dividido: a parte principal salva, e a seta abre a lista de macros e a opção de salvar como rascunho compartilhado. Uma macro aplica várias mudanças de uma vez (estado, tags, nota, etc.) e salva. As macros disponíveis dependem do grupo do ticket.

**Módulos de texto e respostas da base de conhecimento dentro do editor.** No editor de resposta, digitar uma sequência curta de caracteres abre um seletor de textos prontos filtrado pelo que se digita (nome e palavras-chave), restrito ao grupo do ticket; o texto é inserido já com as variáveis preenchidas (nome do cliente, número do ticket, etc.). Outra sequência abre a busca na base de conhecimento para inserir um artigo, e outra menciona um colega (que passa a acompanhar o ticket). A busca usa atraso curto entre teclas para não sobrecarregar o servidor.

**Rascunhos compartilhados.** Um técnico pode salvar a resposta em andamento como rascunho visível para os colegas do grupo. Quem abre o ticket vê um aviso de que existe rascunho, pode pré-visualizá-lo, aplicá-lo (com confirmação se já houver texto) ou apagá-lo. Ao salvar por cima de um rascunho alheio, aparece um diálogo de conflito. Há também rascunhos de abertura de ticket por grupo. Bom para turnos e para revisão de resposta por um colega mais experiente.

**Rascunho pessoal que sobrevive a tudo.** Como cada aba aberta é guardada no servidor com o estado do formulário, a resposta pela metade sobrevive a recarregar a página, a trocar de computador e a fechar o navegador.

**Abas de trabalho persistentes.** Tickets, criação de ticket, buscas, usuários e organizações abertos viram abas numa barra lateral, guardadas no servidor por usuário. Cada aba mostra se tem alterações não salvas e se o ticket mudou desde a última vez que foi visto. Abas fechadas recentemente ficam numa lista para reabrir. Abas cujo objeto sumiu ou ficou sem permissão mostram uma tela própria em vez de quebrar.

**Quem está vendo e quem está editando.** Na barra inferior aparecem os avatares dos colegas que estão com o mesmo ticket aberto, indicando quem está apenas olhando, quem está digitando/alterando, quem está ocioso e se está no celular ou no desktop. A informação vem das próprias abas persistidas: cada aba registra o último contato e se o formulário foi alterado, e o servidor agrega por ticket e empurra a lista por assinatura. Também mostra quando um agente de IA está processando o ticket.

**Edição rápida do título.** O título do ticket é editável no próprio cabeçalho, com gravação imediata separada do formulário principal.

**Marca-texto nas mensagens.** O técnico pode destacar trechos de mensagens com cores (amarelo, verde, etc.) e apagar destaques, como num livro. Os destaques são salvos no servidor. Útil para marcar o número de série, o erro exato ou o pedido central numa conversa longa.

**Tradução de mensagens.** Cada mensagem pode ser traduzida para o idioma do técnico com um clique e voltar ao original; o idioma detectado aparece nos metadados. As traduções vivem enquanto a aba estiver aberta.

**Painel lateral modular.** Cada aba do painel lateral é um módulo independente com ícone, ordem, permissões e condição de disponibilidade (por exemplo, só aparece se a função estiver ativada). O painel mostra: atributos do ticket, tags, vínculos com outros tickets, quem acompanha o ticket, tempo contabilizado, conhecimento relacionado; dados do cliente e da organização com seus outros tickets; checklist; resumo por IA; todos os anexos do ticket juntos; e integrações (CMDB, rastreadores de issues). A posição de rolagem de cada aba é lembrada.

**Tickets relacionados ao alcance.** Abaixo do cabeçalho há listas de tickets recentes do mesmo cliente e de tickets vistos recentemente pelo técnico. Isso responde rápido a "esse usuário já abriu isso antes?".

**Vínculos entre tickets.** Tickets podem ser ligados como "relacionado" (simétrico) ou como pai/filho. Há também fusão de tickets (o fundido aponta para o principal) e divisão de uma mensagem em ticket novo. O cabeçalho mostra um selo quando outros tickets referenciam este por checklist.

**Checklist por ticket com modelos.** Cada ticket pode ter um checklist com até cerca de cem itens, criado do zero ou a partir de modelos reutilizáveis (que também podem ser aplicados por gatilho). Se um item contém o número de outro ticket, ele vira referência: o item se marca sozinho quando o ticket referenciado é fechado. O cabeçalho mostra o progresso. Isso transforma o checklist num mini-gerenciador de dependências.

**Acompanhar ("assinar") um ticket.** Qualquer agente pode passar a acompanhar um ticket sem ser o responsável, recebendo notificações dele; mencionar um colega no texto o inscreve automaticamente. Existe uma visão padrão com os tickets que eu acompanho.

**Visões (filas) prontas e configuráveis.** As filas são listas salvas com condições, ordenação, agrupamento e colunas, atribuídas a papéis ou usuários. Vêm prontas visões como "meus tickets", "abertos sem dono", "meus pendentes vencidos", "acompanhados", "escalonados" e "tickets que estou cobrindo" (substituição de férias). Cada usuário pode reordenar as visões para si. As contagens aparecem no menu.

**Ações em massa por arrastar e soltar.** Na lista, o técnico segura uma linha (ou várias marcadas) e arrasta: em cima aparece uma gaveta com macros aplicáveis, embaixo uma gaveta com grupos e agentes para atribuir. Acima de certo número de tickets pede confirmação, e a execução acontece em segundo plano com indicador de progresso. Há também edição em massa por painel.

**Busca rápida com memória.** A busca rápida (no topo da navegação) procura tickets, usuários, organizações e artigos da base de conhecimento ao mesmo tempo, guarda buscas recentes (removíveis) e mostra as abas fechadas recentemente. A busca detalhada vira uma aba, com filtros por entidade e a consulta refletida no endereço da página, para compartilhar.

**SLA visível no ticket.** O ticket guarda três prazos calculados: primeira resposta, atualização (ou resposta) e solução, contados em horário comercial com calendário de feriados por SLA, e o próximo prazo que vence. Há indicador de escalonamento nas listas e no cabeçalho, notificação de aviso antes de vencer e de escalonamento ao vencer.

**Notificações que explicam o motivo.** Cada notificação informa por que a pessoa a recebeu (é responsável, foi mencionada, é do grupo, está cobrindo um colega ausente). Não notifica quem fez a própria alteração, não notifica atualização sem mudança relevante, e cada usuário escolhe por tipo de evento (novo, atualizado, lembrete, escalonamento) e escopo (meus, sem dono, acompanhados, todos) se quer aviso no navegador e/ou por e-mail. Avisos de lembrete e escalonamento disparam no máximo uma vez por dia por ticket.

**Ausência com substituto.** O agente marca período de ausência e um substituto; as notificações dos tickets dele vão também para o substituto, que tem uma visão própria com esses tickets.

**IA como assistente, não como piloto.** Há: resumo do ticket no painel lateral (pedido do cliente em uma frase, resumo da conversa em poucos parágrafos, perguntas ainda sem resposta, próximos compromissos com data, humor do cliente), gerado no idioma do técnico e guardado para não ser refeito sem necessidade; ferramentas de texto no editor (corrigir ortografia, simplificar, expandir um rascunho, resumir, traduzir), definidas pelo administrador; sugestão de artigos da base de conhecimento por similaridade semântica; geração de rascunho de artigo da base a partir de um ticket resolvido; e tradução de mensagens. Cada resultado traz aviso de conferir e um mecanismo de avaliação/regeneração. O administrador escolhe por grupo quando o resumo é gerado (ao abrir o ticket ou só ao abrir o painel).

**Agentes de IA disparados por regras.** Há tipos prontos de agente que rodam como ação de gatilho: classificar, priorizar, escolher o grupo, sugerir tags, reescrever o título e extrair dados do texto para campos. Recebem como contexto as opções válidas dos campos, para responder dentro do vocabulário do sistema.

**Atalhos de teclado.** No frontend antigo há um conjunto completo e documentado num painel de ajuda: navegar entre áreas, abrir nova criação, fechar e alternar abas, abrir nota, responder à última mensagem, alternar interno/público, salvar como fechado, navegar entre mensagens, copiar o número do ticket, alternar tema e formatação do editor. No desktop novo, por enquanto, só existe parte disso (navegação entre mensagens, digitação para buscar em listas, atalhos do editor) — o conjunto completo ainda não foi portado.

---

## 3. Decisões técnicas

**Monólito Rails com camada de serviços.** A regra de negócio está em modelos com muitos módulos de comportamento acoplados (cada modelo "inclui" dezenas de comportamentos: histórico, busca, notificação de clientes, auditoria) e, cada vez mais, em objetos de serviço de responsabilidade única. Autorização por políticas por objeto, verificadas também nas assinaturas em tempo real (só aparece na presença quem o usuário pode ver).

**GraphQL para o frontend novo, REST para o antigo.** O frontend novo usa consultas, mutações e assinaturas GraphQL com tipos TypeScript gerados a partir do esquema. As assinaturas trafegam por websocket (ActionCable sobre Redis). Há agrupamento de requisições e cache de fragmentos no servidor. O backend mantém as duas APIs em paralelo, o que dobra a superfície.

**Tempo real seletivo.** O detalhe do ticket, as mensagens novas, a presença, o checklist, os vínculos, as contagens de notificação e a configuração chegam por assinatura. Já as listas das visões **não** são empurradas: o cliente consulta periodicamente, com intervalo maior quando a aba está em segundo plano, e envia uma "assinatura" do conjunto que já tem; se nada mudou no servidor, a resposta vem vazia. O resultado da visão é guardado em cache no servidor por alguns segundos. É uma decisão pragmática: listas mudam muito e o custo de empurrar diff de lista é alto.

**Presença derivada das abas persistidas.** Não há um serviço de presença separado: cada aba aberta é um registro no banco com último contato e indicador de alteração; ao mudar, o servidor recalcula as abas relacionadas ao mesmo objeto e notifica. Simples e robusto, mas acopla presença a escrita no banco a cada interação.

**Regras de formulário dirigidas pelo servidor.** Um "atualizador de formulário" recebe o estado atual e devolve o esquema efetivo (visibilidade, obrigatoriedade, opções, valores), combinando permissões, regras configuráveis pelo administrador e casos especiais em código. O mesmo mecanismo aplica modelos de ticket, rascunhos compartilhados, estado salvo da aba e divisão de mensagem. O frontend é um motor genérico de formulários orientado a esquema.

**Gatilhos e automação.** Gatilhos têm condições e ações e podem ser disparados por ação (criação/atualização) ou por tempo (lembrete vencido, escalonamento, aviso de escalonamento). Há modo "só quando a condição passou a ser verdadeira" versus "sempre que for verdadeira". Gatilhos de tempo usam trava diária por ticket para não repetir. Ações incluem alterar campos, enviar e-mail/SMS/webhook, adicionar nota, aplicar checklist de modelo e rodar agente de IA. Os eventos de um pedido são acumulados e despachados depois da transação, em ordem.

**SLA calculado no salvamento.** Após cada gravação de ticket, recalculam-se os prazos com base no SLA que casa com as condições do ticket e no calendário (horário comercial, feriados, fuso). Estados do tipo pendente pausam a contagem. Os prazos ficam gravados no ticket, o que torna listas e filtros por escalonamento baratos.

**Jobs em segundo plano em filas separadas.** Processos dedicados para jobs gerais, jobs agendados, entrada de comunicação (e-mail etc.) e uma fila só para IA. Isso impede que uma chamada lenta a um provedor de IA atrase o processamento de e-mails.

**Busca em duas camadas.** Com Elasticsearch configurado (versão 8.15 ou superior), a busca e parte dos filtros vão para ele, incluindo sintaxe de campo e curingas; sem ele, cai para busca SQL por semelhança. Os documentos são indexados de forma assíncrona. O mesmo Elasticsearch é reaproveitado como banco vetorial para a IA (embeddings de tickets e da base de conhecimento, com estratégias de fatiamento por frase e recursiva).

**IA com resultado guardado e analítica.** Cada recurso de IA é uma "feature" com instruções de sistema e usuário em modelo de texto, provedor configurável, resultado guardado com versão (para não chamar o provedor de novo sem necessidade), estratégia "guardado ou novo", regeneração explícita e registro de uso e de avaliação do usuário. As instruções pedem resposta em JSON estruturado, o que permite à interface montar seções fixas.

**i18n.** Todas as frases da interface são marcadas para tradução na origem e extraídas para catálogos no formato gettext, mantidos numa plataforma de tradução comunitária; o cliente recebe o catálogo do idioma pelo servidor. Há regras de estilo para frases-fonte (frases completas, sem fragmentos). Existe português do Brasil.

**Frontend novo.** Vue 3 com composição, Pinia, Apollo, Tailwind, editor rico baseado em ProseMirror/Tiptap com extensões próprias (menções, módulos de texto, base de conhecimento, ferramentas de IA, tabelas, assinatura). Muita injeção de contexto entre componentes (o ticket, o formulário, o painel), "plugins" descobertos automaticamente por pasta para painel lateral, tipos de mensagem, ações por mensagem, abas e resultados de busca. Muitos esqueletos de carregamento. Atenção a acessibilidade (rótulos para botões só de ícone, navegação por teclado em listas, digitar para focar opção).

---

## 4. O que levar para o PantherDesk

- **Abas de trabalho persistidas no servidor, com o rascunho dentro.** Para um técnico que é interrompido o tempo todo (o professor chega na mesa, o telefone toca), não perder a resposta pela metade é ouro. Fazer do jeito simples: cada ticket aberto pelo técnico vira um registro com o rascunho e o último contato.
- **Presença no ticket** (quem está vendo, quem está escrevendo), derivada desse mesmo registro. Evita dois técnicos atendendo o mesmo chamado — problema real numa equipe pequena.
- **Abrir mostrando o começo e o fim da conversa**, com o meio recolhido. Contador de não lidas e botão "pular para a próxima não lida".
- **Atributos e resposta num único "salvar"**, com marca de campo alterado e descarte com confirmação.
- **Escolha do que acontece depois de salvar** (ficar, fechar aba, fechar só se resolvido) e macros que aplicam várias mudanças e já levam ao próximo.
- **Nota interna como ação padrão mais fácil**, com estilo visual inconfundível.
- **Textos prontos inseridos por digitação no editor**, filtrados por equipe, com variáveis preenchidas; e inserção de artigo da base de conhecimento do mesmo jeito.
- **Checklist por ticket com modelos**, e a ideia do item que referencia outro ticket e se marca sozinho quando ele fecha. Ótimo para "trocar projetor da sala 12" que depende de "compra aprovada".
- **Bloqueio gentil ao fechar** com checklist incompleto (pergunta, não proíbe).
- **Acompanhar um ticket sem ser o dono** e menção que inscreve o colega.
- **Rascunho compartilhado** para revisão entre colegas ou passagem de turno.
- **Lista de tickets recentes do mesmo solicitante** junto ao ticket.
- **Notificação com o motivo** e sem notificar quem fez a ação; preferências por tipo de evento e escopo; substituto durante ausência.
- **SLA com prazos gravados no ticket**, calendário escolar (horário de aula, feriados, recesso) e pausa em pendente.
- **Visões prontas e sensatas** (meus, sem dono, pendentes vencidos, acompanhados, escalonados) com contagem, e ordem pessoal das visões.
- **Listas por consulta periódica com "nada mudou"**, em vez de empurrar tudo em tempo real; tempo real só no ticket aberto e na presença.
- **Regras de formulário no servidor**, mas em versão pequena: só as regras de que precisamos (pendente exige data, responsável dentro da equipe).
- **Busca rápida unificada com buscas recentes e abas fechadas recentes.** Começar com busca do próprio banco; motor de busca externo só se precisar.
- **IA, se entrar, como assistente com resultado guardado**: resumo estruturado do ticket (pedido, o que já foi feito, perguntas abertas) e tradução; sempre com aviso de conferência e fila de processamento separada.
- **Frases de interface marcadas para tradução desde o primeiro dia**, mesmo que só exista português.

## O que não levar

- **Vários frontends em paralelo** (antigo, desktop novo, celular) e duas APIs. Um frontend responsivo e uma API só.
- **Omnicanalidade de rede social** (Facebook, X/Twitter, Telegram etc.) e integrações de telefonia: não servem ao help desk de TI de uma escola e pesam em todo o código da tela de ticket.
- **Uma linguagem de condições para cada motor** (gatilhos, macros, visões, SLAs, regras de formulário, agendadores, agentes de IA), cada um com seu editor. Para nós, poucos tipos de automação com o mesmo editor de condições.
- **Agentes de IA que alteram campos sozinhos** por gatilho. Num ambiente escolar pequeno, o custo de confiança é maior que o ganho; manter IA só sugerindo.
- **Modelos com dezenas de comportamentos acoplados** e callbacks em cascata após gravar (recalcular SLA em outra cópia do registro, tocar registros relacionados, notificar clientes). Preferir passos explícitos.
- **Camadas de "plugin" por pasta para tudo** (painel lateral, tipos de mensagem, ações, abas). Para um produto pequeno, uma lista explícita no código é mais legível.
- **Contornos com atraso fixo** para rolagem e espera de efeitos assíncronos, e funcionalidades meio portadas (opções comentadas esperando outra parte, atalhos de teclado só no frontend antigo). Se lançar, lançar inteiro.
- **Excesso de opções de IA configuráveis** (provedores, modelos, quando gerar, por grupo, ferramentas de texto personalizáveis, analítica de uso). Uma configuração simples e um provedor.
- **Marca-texto colorido em várias cores** é charmoso, mas é secundário; se entrar, uma cor só.
- **Dependência de Elasticsearch** como peça quase obrigatória (busca + vetores). Para o volume de uma escola, o banco relacional basta.
