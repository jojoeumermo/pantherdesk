# Catálogo de cenários de observação

Cada cenário roda **igual em todos os projetos** que têm a funcionalidade, para
que as evidências sejam comparáveis. Se um projeto não tem a funcionalidade,
registre `N/A` no manifesto (isso também é evidência).

Convenções:
- Rodada: `r<N>`. Uma rodada = uma execução completa de um cenário num projeto.
- Saída: `observation/evidence/<projeto>/<cenário>/<rodada>/`.
- Cada pasta de evidência tem um `manifest.md`: versão/digest da imagem, data e
  hora (UTC), passos executados, IDs das Evidences do REA, arquivos gerados e
  **observações em linguagem própria** (nunca colar texto de interface).
- Tipos de evidência: `rea-*.json` (Evidence exportada do REA),
  `*.har`, `api-*.json` (respostas de API), `email-in/`, `email-out/`,
  `webhooks.jsonl`, `state-*.json` (estado do ticket depois de cada passo),
  `screens/` (screenshots do REA).

Atores padrão (criados em todo projeto):

| Ator | E-mail | Papel |
|---|---|---|
| admin | admin@lab.test | administrador |
| agent1 | agent1@lab.test | agente, grupo "Suporte N1" |
| agent2 | agent2@lab.test | agente, grupo "Suporte N1" |
| agent3 | agent3@lab.test | agente, grupo "Financeiro" |
| customer1..5 | customerN@lab.test | solicitantes (customer1 e 2 na organização "Acme") |
| manager1 | manager1@lab.test | solicitante, gestor na "Acme" |

Endereço de suporte: `support-<projeto>@lab.test`, buscado por IMAP em
`mail.lab.test:3143`; saída SMTP para `mail.lab.test:3025`.

---

## 1. Modelo de dados e ciclo de vida (T)

| ID | Cenário | Passos | Capturar |
|---|---|---|---|
| T-01 | Criação pelo agente | agent1 cria ticket para customer1 pela UI | HAR, `state` via API, campos obrigatórios e valores padrão |
| T-02 | Transições de estado | percorrer todos os estados disponíveis, um passo por vez | `state` depois de cada passo; quais transições a UI/API recusa |
| T-03 | Reabertura por resposta | ticket resolvido → customer1 responde por e-mail (fixture 03) | estado resultante; se zera o SLA; se reatribui |
| T-04 | Fechamento automático | resolvido sem resposta → aguardar a regra de fechamento (encurtar o prazo para minutos) | quando e como fecha; se ainda aceita resposta depois de fechado |
| T-05 | Resposta em ticket fechado | customer1 responde a um ticket fechado | reabre? cria ticket novo vinculado? |
| T-06 | Merge | mesclar dois tickets do mesmo solicitante | o que acontece com mensagens, estado, número e threading futuro |
| T-07 | Campos customizados | criar campo lista + texto; usar em ticket | tipos suportados, validação, histórico |
| T-08 | Histórico/auditoria | após T-02, ler o histórico do ticket | granularidade do log, quem/quando/antes/depois |

## 2. Entrada de e-mail (E)

Pré-condição: resposta do agente enviada; o `.eml` de saída coletado com
`fetch-mailbox.ps1`, de onde saem `REPLY_MSGID`, `REPLY_SUBJECT` e `TICKET_TAG`.

| ID | Fixture | Passos | Capturar |
|---|---|---|---|
| E-01 | 01 | enviar; aguardar polling | ticket criado, solicitante criado, corpo, estado |
| E-02 | 02 | enviar | anexos listados, inline resolvido, HTML sanitizado (o script some?) |
| E-03 | — | agent1 responde E-01 | `.eml` de saída: Message-ID, In-Reply-To, References, Reply-To, assunto, cabeçalhos anti-loop |
| E-04 | 03 | enviar | entrou no mesmo ticket? texto citado cortado? |
| E-05 | 04 | enviar | idem, só com References |
| E-06 | 05 | enviar | threading só pelo marcador no assunto |
| E-07 | 06 | enviar | ticket novo ou associado? |
| E-08 | 07 | enviar de novo a 01 | duplicou ou deduplicou? |
| E-09 | 08 | enviar | anti-loop: auto-resposta não deve gerar outra auto-resposta |
| E-10 | 09 | enviar | bounce reconhecido? marca o contato/mensagem? |
| E-11 | 10 | enviar | ticket? auto-resposta? |
| E-12 | 11 | enviar | laço detectado? |
| E-13 | 12 | enviar | respeita o flag de spam? |
| E-14 | 13 | enviar | nome, assunto e corpo decodificados corretamente |
| E-15 | 14 | enviar | manager1 vira CC/participante? recebe as próximas respostas? |
| E-16 | 15 | enviar | solicitante = agent1 ou customer5? |
| E-17 | 16 | enviar | aceita, rejeita, ou cria ticket novo? |
| E-18 | — | enviar 01 com servidor IMAP parado por 5 min, depois religar | recuperação do polling, nada perdido nem duplicado |

## 3. Canais (C)

| ID | Cenário | Capturar |
|---|---|---|
| C-01 | Formulário web público (portal ou widget) sem login | campos, criação do solicitante, confirmação por e-mail, anti-spam/captcha |
| C-02 | Widget de chat (onde houver): visitante inicia conversa, agente responde, visitante sai | WebSocket (REA `websockets`), transcrição, conversão em ticket |
| C-03 | Inventário de integrações de WhatsApp/redes sociais na UI de admin | só **quais existem e como se configuram** (não conectar contas reais) |
| C-04 | Mesmo cliente por dois canais (e-mail + formulário) | unificação do contato |

## 4. Atribuição e filas (A)

| ID | Cenário | Capturar |
|---|---|---|
| A-01 | Ticket novo sem dono | em que fila/grupo cai; quem é notificado |
| A-02 | Round-robin (onde houver): criar 6 tickets em "Suporte N1" | sequência de donos; efeito de agente ausente/offline |
| A-03 | Balanceamento por carga (onde houver) | critério usado (abertos? capacidade?) |
| A-04 | Transferência de grupo | dono é mantido ou limpo? notificações |
| A-05 | Agente desativado com tickets atribuídos | o que acontece com os tickets |

## 5. Automações (AU)

| ID | Cenário | Capturar |
|---|---|---|
| AU-01 | Gatilho na criação: assunto contém "invoice" → grupo Financeiro + tag | ordem de execução, condições disponíveis |
| AU-02 | Gatilho na atualização: cliente respondeu → estado "aberto" | evento que dispara; se roda em ações do próprio gatilho (laço) |
| AU-03 | Dois gatilhos conflitantes | ordem/prioridade, resultado final |
| AU-04 | Macro aplicada por agent1 | ações suportadas, se envia e-mail, histórico |
| AU-05 | SLA: 1ª resposta em 5 min, resolução em 15 min, calendário 24x7 | horários calculados, alerta antes de vencer, estado ao vencer |
| AU-06 | SLA com horário comercial e feriado | pausa fora do expediente; datas calculadas |
| AU-07 | SLA pausado em "pendente" | o relógio para? volta de onde estava? |
| AU-08 | Escalonamento ao vencer | ação executada, notificação |
| AU-09 | Tarefa agendada (ex.: fechar resolvidos após N) | frequência, idempotência |
| AU-10 | Auto-resposta ao cliente na criação | conteúdo, cabeçalhos anti-loop, não responde a 08/10/11 |

## 6. Permissões e multi-tenancy (P)

| ID | Cenário | Capturar |
|---|---|---|
| P-01 | agent3 (Financeiro) tenta abrir ticket de "Suporte N1" (UI e API) | status HTTP, o que vaza na resposta |
| P-02 | customer1 vê tickets da organização? customer2 vê os de customer1? | visibilidade por organização |
| P-03 | customer1 tenta ler nota interna via API/portal | a nota nunca pode aparecer |
| P-04 | Papel customizado com permissão parcial | granularidade do modelo de permissão |
| P-05 | Token de API de agente com escopo restrito | escopos disponíveis |
| P-06 | Inventário multi-empresa (marcas, múltiplas caixas, contas) | modelo de isolamento |

## 7. Base de conhecimento e portal (K)

| ID | Cenário | Capturar |
|---|---|---|
| K-01 | Criar categoria + artigo (rascunho → publicado) | estados, versões, visibilidade pública/interna |
| K-02 | Busca no portal por termo do artigo | relevância, anônimo vs. logado |
| K-03 | Portal: customer1 abre ticket, acompanha, responde | fluxos e o que o cliente vê |
| K-04 | Sugestão de artigos ao abrir ticket (deflexão) | onde existir |
| K-05 | Artigo multi-idioma | onde existir |

## 8. Busca e filtros (S)

| ID | Cenário | Capturar |
|---|---|---|
| S-01 | Busca livre por palavra presente só no corpo de uma mensagem | indexação de corpo e anexos |
| S-02 | Filtros combinados (estado + grupo + dono + data) | operadores, visões salvas |
| S-03 | Busca com acento/sem acento ("conexão" vs "conexao") | normalização |
| S-04 | Latência entre criar e aparecer na busca | indexação síncrona ou assíncrona |

## 9. Tempo real (R)

| ID | Cenário | Capturar |
|---|---|---|
| R-01 | Dois navegadores: agent1 vê a lista; agent2 atualiza ticket | REA `websockets`: protocolo, formato da mensagem, latência |
| R-02 | Detecção de colisão (dois agentes no mesmo ticket) | aviso de presença/digitação |
| R-03 | Notificação in-app ao ser atribuído | canal usado |

## 10. API e webhooks (API)

| ID | Cenário | Capturar |
|---|---|---|
| API-01 | CRUD de ticket pela API REST | autenticação, paginação, formato de erro, códigos HTTP |
| API-02 | Webhook em criação/atualização para `http://hooks.lab.test:8090/` | payload, cabeçalhos, assinatura/HMAC |
| API-03 | Webhook para `/status/500` | política de retry, backoff, desativação |
| API-04 | Webhook para `/slow/30000` | timeout |
| API-05 | Rate limit: rajada de 200 requisições | cabeçalhos e status de limite |
| API-06 | Ler a documentação pública da API do **Zendesk** (só leitura) | modelo de recursos, paginação, side-loading, webhooks — anotar como referência de mercado |

## 11. Relatórios e métricas (M)

| ID | Cenário | Capturar |
|---|---|---|
| M-01 | Após os cenários acima, abrir os relatórios padrão | métricas oferecidas, definição de cada uma (tempo de 1ª resposta, resolução, reabertura) |
| M-02 | Exportação | formatos |

## 12. Extensibilidade (X)

| ID | Cenário | Capturar |
|---|---|---|
| X-01 | Inventário de mecanismos: plugins/apps, scripts no servidor, campos, integrações | o que pode ser estendido e por qual mecanismo |
| X-02 | Instalar um plugin/módulo gratuito de exemplo (se houver) | ciclo de vida: instalar, ativar, atualizar, remover |

---

## Prioridade (MVP primeiro)

1. E-01..E-17 e T-01..T-08 (threading e ciclo de vida são o coração do MVP)
2. AU-01..AU-10 (gatilhos, macros, SLA)
3. P-01..P-05, A-01..A-05
4. K-01..K-03, API-01..API-05
5. S, R, M, C, X (servem principalmente para o roadmap)

Projetos por profundidade: Zammad, FreeScout, osTicket e Znuny são os mais
completos em e-mail/SLA e rodam todos os cenários. Chatwoot é a referência para
canais e tempo real. UVdesk e Frappe rodam o núcleo (T, E, A, AU-01..05,
P, K) e o que mais existir.
