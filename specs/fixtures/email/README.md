# Fixtures de e-mail

Mensagens RFC 5322 escritas do zero para este projeto (não vêm de nenhum projeto
analisado). Servem para duas coisas:
1. **Fase 1:** injetar o mesmo estímulo em cada helpdesk observado
   (`observation/tools/send-eml.ps1`) e comparar como cada um reage.
2. **Fase 2:** usar como entrada dos testes automatizados de ingestão de e-mail
   do PantherDesk.

## Placeholders
Substituídos no momento do envio:

| Placeholder | Significado |
|---|---|
| `{{SUPPORT}}` | endereço de suporte do sistema sob teste (ex.: `suporte@pd.test`) |
| `{{RUN}}` | identificador da rodada; deixa os Message-IDs únicos entre execuções |
| `{{REPLY_MSGID}}` | Message-ID (com `<>`) da resposta do agente que o cliente está respondendo |
| `{{REPLY_SUBJECT}}` | assunto exatamente como o sistema enviou na resposta do agente |
| `{{TICKET_TAG}}` | marcador de ticket que o sistema põe no assunto (no PantherDesk: `[PD-1234]`) |

## Catálogo

| # | Arquivo | Estímulo | Pergunta que responde |
|---|---|---|---|
| 01 | 01-new-plain.eml | Mensagem nova, texto puro | Cria ticket? Como cria/associa o solicitante? Qual o estado inicial? |
| 02 | 02-new-html-attachment.eml | HTML + texto alternativo, imagem inline por `cid:`, PDF anexo, `<script>` no HTML | Tratamento de anexos e inline, sanitização do HTML, qual parte vira o corpo |
| 03 | 03-reply-in-reply-to.eml | Resposta com In-Reply-To e References | Threading pelo cabeçalho principal; corte do texto citado |
| 04 | 04-reply-references-only.eml | Resposta só com References | Threading quando falta In-Reply-To |
| 05 | 05-reply-subject-tag-only.eml | Sem cabeçalhos de thread, com o marcador do ticket no assunto | Threading pelo assunto |
| 06 | 06-reply-no-headers.eml | Mesmo assunto com "Re:", sem cabeçalhos e sem marcador | O sistema associa por assunto parecido, ou cria ticket novo? |
| 07 | 07-duplicate-message-id.eml | Cópia byte a byte da 01 | Deduplicação por Message-ID |
| 08 | 08-auto-reply.eml | Resposta automática (Auto-Submitted, X-Autoreply) | Anti-loop: grava? reabre? dispara auto-resposta de volta? |
| 09 | 09-bounce-dsn.eml | DSN de falha de entrega (multipart/report) | Detecção de bounce e efeito no ticket/contato original |
| 10 | 10-bulk-precedence.eml | Newsletter (Precedence: bulk, List-Id) | Mensagens em massa geram ticket? geram auto-resposta? |
| 11 | 11-loop-from-self.eml | Remetente = próprio endereço de suporte | Proteção contra laço de e-mail |
| 12 | 12-spam-flagged.eml | Marcada como spam por filtro anterior (X-Spam-Flag) | Respeita a marcação de spam do MTA? |
| 13 | 13-latin1-charset.eml | ISO-8859-1, quoted-printable, encoded-word no assunto e no nome | Decodificação de charset e cabeçalhos |
| 14 | 14-cc-third-party.eml | Resposta que adiciona um terceiro em Cc | Gestão de participantes/CC do ticket |
| 15 | 15-forwarded-by-agent.eml | Agente encaminha e-mail de cliente (message/rfc822) | O sistema identifica o solicitante original? |
| 16 | 16-reply-from-unknown-sender.eml | Resposta na thread vinda de remetente estranho | Política de quem pode responder a um ticket existente |
