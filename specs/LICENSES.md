# Licenças dos projetos analisados

Registro das licenças dos sistemas estudados na Fase 1 (análise). Nenhum código,
asset, texto de interface, tradução ou schema desses projetos é copiado para o
nosso sistema; eles são usados apenas como **objeto de observação de
comportamento** em instâncias locais e como leitura de documentação. Por isso,
as obrigações de copyleft (GPL/AGPL/OSL) **não** se propagam ao nosso código,
desde que o isolamento clean room descrito em `observation/README.md` seja
respeitado.

Verificado em 2026-10-26 pela API pública do GitHub (campo de licença do
repositório) e, quando o campo veio como `NOASSERTION`, pela leitura do arquivo
de licença na raiz do repositório.

| Projeto | Repositório oficial | Licença (SPDX) | Versão de referência para observação | Stack (motivo da restrição de tecnologia) |
|---|---|---|---|---|
| Zammad | github.com/zammad/zammad | AGPL-3.0 | imagem `ghcr.io/zammad/zammad` 7.2.2 (via zammad-docker-compose v17.5.3) | Ruby on Rails, Vue |
| Chatwoot | github.com/chatwoot/chatwoot | MIT (núcleo) + licença proprietária "Chatwoot Enterprise" no diretório `enterprise/` | imagem `chatwoot/chatwoot:v4.19.1-ce` (edição comunitária) | Ruby on Rails, Vue |
| FreeScout | github.com/freescout-help-desk/freescout | AGPL-3.0 | release 1.8.248 | PHP / Laravel |
| osTicket | github.com/osTicket/osTicket | GPL-2.0 | release v1.18.4 | PHP |
| Znuny | github.com/znuny/Znuny | GPL-3.0 | tag rel-7_3_8 | Perl |
| UVdesk | github.com/uvdesk/community-skeleton (+ uvdesk/core-framework) | OSL-3.0 | release v1.1.8 | PHP / Symfony |
| Frappe Helpdesk | github.com/frappe/helpdesk | AGPL-3.0 | release v1.31.0 sobre Frappe Framework v15 | Python / Frappe, Vue |

Referência externa somente leitura:

| Fonte | Uso permitido | Uso proibido |
|---|---|---|
| Zendesk (documentação pública da API, developer.zendesk.com) | Ler a documentação para entender o modelo de API que o mercado espera | Qualquer captura, análise, scraping ou engenharia reversa do produto, site, apps ou binários (os termos de uso proíbem) |

## Notas e restrições por projeto

### Chatwoot — núcleo MIT, diretório enterprise proprietário
O arquivo de licença da raiz diz que tudo fora de `enterprise/` é MIT e que o
conteúdo de `enterprise/` segue a "Chatwoot Enterprise License". Essa licença
só permite uso em produção com assinatura, mas autoriza copiar e modificar
"para desenvolvimento e testes".

Regra adotada:
- Observamos somente a imagem `-ce` (community edition).
- **Não lemos o código do diretório `enterprise/`** e não descrevemos nas specs
  recursos que só existem na edição paga. Se um comportamento observado depender
  de recurso enterprise, ele é descartado como evidência.

### Peppermint — excluído da análise
Estava na lista original (github.com/Peppermint-Lab/peppermint). A licença é
ambígua: o cabeçalho do arquivo de licença atribui uma licença comercial ao
repositório inteiro e, logo em seguida, declara AGPLv3 para o conteúdo "fora"
dessa restrição; o GitHub a classifica como `NOASSERTION`. Além disso, o
repositório foi arquivado em setembro de 2025.

**Decisão do responsável pelo projeto (2026-10-26): Peppermint fica fora.** Não
foi instalado, observado nem lido. A análise segue com 7 projetos.

### FreeScout — módulos pagos
O núcleo é AGPL-3.0. Os módulos comerciais (vendidos à parte) não são instalados
nem analisados.

### UVdesk — OSL-3.0
A OSL-3.0 é copyleft que também alcança uso via rede ("External Deployment").
Isso não nos afeta, porque nenhum código é derivado. O registro serve para
deixar claro que o mesmo cuidado de isolamento vale aqui.

### Zammad, Frappe Helpdesk — AGPL-3.0; osTicket — GPL-2.0; Znuny — GPL-3.0
Copyleft forte. A leitura de código-fonte é permitida pela metodologia somente
para entender a **intenção** de uma regra de negócio. Nenhum trecho, nome de
símbolo, caminho, SQL ou estrutura de tabela é transcrito para `specs/`.

## Regras de isolamento derivadas destas licenças

1. `specs/` contém só descrição de comportamento, decisões e casos de teste,
   escritos com palavras próprias.
2. `observation/evidence/` (capturas HAR, JSON de API, e-mails, screenshots) pode
   conter textos de interface e dados dos projetos. **Essa pasta nunca é entregue
   à Fase 2.** As specs citam evidências só pelo identificador
   (`<projeto>/<cenário>/<arquivo>`), sem reproduzir o conteúdo.
3. As fixtures de e-mail em `specs/fixtures/` são escritas por nós, do zero, e
   podem ir para a Fase 2.
4. A Fase 2 recebe somente `specs/`.
