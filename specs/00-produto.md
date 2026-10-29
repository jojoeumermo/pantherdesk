# PantherDesk — requisitos de produto para a Fase 2

Este arquivo registra decisões do responsável pelo projeto que valem para a
implementação. Não é resultado da análise; é instrução direta.

## Nome
O sistema se chama **PantherDesk**. Use esse nome no código, na interface e na
documentação. Identidade visual própria, sem semelhança com nenhum projeto
analisado nem com o Zendesk.

## Cliente de referência: EARJ
O primeiro cliente é o help desk de TI da EARJ (escola com unidades Barra e
Gávea). O que a operação faz hoje está em `13-requisitos-da-operacao-earj.md`,
e **o protótipo deve cobrir tudo o que está marcado como MVP lá**. Isso amplia
o escopo original: o chat no site, a pesquisa de satisfação e os campos no
cadastro de pessoas entram no MVP. Onde a spec 13 diverge das demais, vale a
spec 13. Os dados de demonstração seguem a §4 da spec 13, com pessoas
fictícias.

## O protótipo precisa abrir no localhost
Critério de aceite da entrega: a partir de um clone limpo, um único comando
documentado no README sobe tudo (backend, frontend, PostgreSQL, fila/cache e um
servidor de e-mail de teste). Depois disso o protótipo deve abrir no navegador em
um endereço `http://localhost:<porta>`, com:
- dados de demonstração carregados (organização, agentes, grupos, solicitantes,
  tickets em todos os estados, artigos da base de conhecimento);
- usuários de teste para os três papéis (admin, agente, solicitante), listados
  no login de desenvolvimento e no README;
- o portal do cliente acessível no mesmo host.

Como o login de produção é com Google (spec 13 Δ31), o ambiente local oferece
um **login de desenvolvimento** que lista os usuários de demonstração e entra
com um clique. Ele só existe quando a aplicação roda em modo de
desenvolvimento e some quando o provedor Google está configurado. O endereço de
produção do portal é help.earj.com.br (Δ32); no localhost, o portal fica no
mesmo host da aplicação.

## Identidade visual (revisado em 2026-10-29)
Paleta **Panthers**: azul-marinho, azul royal e vermelho (spec 13 Δ30). Ela
substitui o grafite com âmbar usado nos primeiros protótipos.

A entrega só termina depois de verificar no navegador que a aplicação abre e que
os fluxos principais funcionam.

## Stack (decidida em 2026-10-29)
- **Backend em Go**, entregue como **um único executável** que também serve o
  frontend já compilado. O mesmo executável instala e migra o banco (de forma
  idempotente) e não sobe se houver migração pendente.
- **PostgreSQL** como única fonte de verdade: busca em português pelo
  full-text do próprio banco (com trigramas para nomes e números), fila de
  tarefas no banco e avisos em tempo real por notificação do banco. Redis só
  entra se a medição mostrar necessidade.
- **Frontend em Vue 3 com TypeScript**, Vite, Tailwind e componentes próprios;
  traduções PT/EN em arquivos de mensagens.
- Tempo real por WebSocket só para o ticket aberto, a presença e as contagens;
  as listas se atualizam por consulta que responde vazio quando nada mudou.
- O que precisa ser durável (e-mail de saída e de entrada, webhooks) passa por
  uma fila com nova tentativa e histórico de entregas.
- Deve funcionar com mais de uma instância do servidor; nada de estado só em
  memória.

## Princípios de interface (revisados em 2026-10-29)
O usuário é técnico ou analista e quer ver o problema e resolver. Regras:
1. **Cor só com significado.** O único botão sólido da tela é azul-marinho;
   azul royal para link, foco e seleção; vermelho só para prazo estourado,
   urgente ou erro. O resto é cinza neutro, definido por tokens com nome de
   função (superfície, texto, contorno, destaque, perigo) para claro e escuro.
2. **Áreas planas separadas por linhas finas.** Sombra só em menus e diálogos.
   Nada de pílulas coloridas, gradientes, emojis ou brilhos de "IA".
3. **Três zonas fixas:** navegação clara e recolhível à esquerda (com as
   visões salvas), conteúdo no centro e, no ticket, um único painel de
   propriedades à direita, em seções recolhíveis, com rótulo cinza de largura
   fixa e valor alinhado que vira seletor ao clicar.
4. **Uma ação principal por tela.** O resto vai para o menu "⋯" ou aparece no
   hover.
5. **Lista de tickets em tabela de largura total:** seleção, nº, assunto,
   estado (ponto + texto), 1ª resposta e resolução (emblema suave com contagem
   curta), responsável, prioridade (ícone de barras cinza) e criado (relativo).
   Negrito só para não lido; ações em massa só com seleção. O ticket abre em
   página própria.
6. **Conversa em linha do tempo** com fio vertical fino, abas Atividade /
   Respostas / Notas internas e eventos de sistema como linhas cinza curtas.
   Nota interna com tratamento distinto e suave.
7. **Editor recolhido em dois botões** ("Responder" e "Nota interna") preso ao
   rodapé; abre ao clicar ou com R; Ctrl+Enter envia e Esc fecha. Macros, anexo
   e revisão de texto como ícones discretos.
8. **IA como ferramenta, não como enfeite:** resumo e revisão de texto ficam no
   menu "⋯" ou como ícone, sem destaque visual.
9. **Teclado primeiro:** Ctrl+K abre "Ir para" (tickets, filas, telas); R
   responde, I abre nota interna, Esc fecha.
10. Textos de apoio curtos; nada de frases que expliquem o óbvio.

## Design da interface: usar os artefatos do Claude
O design do PantherDesk (telas do agente, portal do cliente, base de
conhecimento, admin) deve ser feito com os **artefatos do Claude** (Artifact
tool / tipo Design, quando disponível), antes de implementar o frontend:
1. Criar o design system (cores, tipografia, espaçamento, componentes) e os
   protótipos das telas principais como artefatos.
2. Revisar com o responsável pelo projeto.
3. Implementar o frontend em TypeScript seguindo esses artefatos, com
   componentes próprios.

Os artefatos são o ponto de partida do design; o código do frontend continua
sendo escrito por nós.
