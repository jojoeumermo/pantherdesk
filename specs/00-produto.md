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
