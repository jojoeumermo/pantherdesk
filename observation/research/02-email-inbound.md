# Área 2 — Entrada de e-mail

Notas comportamentais do analista (clean-room). Fonte: **apenas documentação pública oficial**
(manuais, FAQ/wiki de documentação, notas de versão, fórum oficial quando indicado). Nenhum código-fonte
foi lido. Tudo reescrito com palavras próprias: sem rótulos de interface, nomes de configuração, nomes de
classes, tabelas, caminhos ou nomes de cabeçalhos proprietários dos produtos. Nomes de cabeçalhos
**padronizados** (RFC 5322/3834/3464 e convenções de mercado: Message-ID, In-Reply-To, References,
Reply-To, Auto-Submitted, Precedence, X-Loop, List-Unsubscribe, X-Spam-Flag) são citados por serem
protocolo, não texto dos projetos.

Confiança: **documentado** (a página afirma) / **inferido** (deduzido, fonte secundária ou ausência) /
**A CONFIRMAR EM RUNTIME** (vira passo dos cenários E-*).

Data da pesquisa: 2026-10-26. Peppermint excluído. Nenhuma página do Zendesk consultada.
Chatwoot: só edição comunitária.

---

## 1. Problema que a área resolve

Transformar um fluxo de mensagens RFC 5322 não confiáveis em operações corretas e **idempotentes** sobre
tickets:

1. **Classificar** cada mensagem: novo pedido, continuação (follow-up) de ticket existente, resposta
   automática, bounce, lista/massa, spam, laço do próprio sistema, ou lixo a descartar.
2. **Encadear** (threading) com robustez quando clientes de e-mail removem ou reescrevem cabeçalhos, e sem
   falsos positivos (anexar ao ticket errado vaza dados entre clientes).
3. **Identificar pessoas**: remetente → solicitante/agente; Cc → participantes; encaminhamento por agente →
   solicitante original; remetente estranho respondendo numa thread.
4. **Extrair conteúdo seguro**: escolher a parte do corpo, sanitizar HTML, resolver imagens inline,
   guardar anexos, cortar texto citado, decodificar charsets.
5. **Não perder nem duplicar** mensagens com polling instável (IMAP caído, reprocessamento, cópias).
6. **Não gerar laços** de auto-resposta com outros robôs nem consigo mesmo.

---

## 2. Comportamento documentado por projeto

### 2.1 Zammad

**Ingestão**
- Contas IMAP/POP3 (e canais dedicados Google/Microsoft); em instalação própria também é possível entregar
  por utilitário de busca externo ou por entrega local (piping). — https://admin-docs.zammad.org/en/latest/channels/email/index.html — documentado
- Por padrão a mensagem é **apagada da caixa** após importar; opcionalmente fica no servidor marcada como
  lida e só não-lidas são importadas (a doc avisa que alterações externas na caixa podem fazer perder
  mensagens). Pasta padrão é a caixa de entrada; grupo de destino definido na conta. —
  https://admin-docs.zammad.org/en/latest/channels/email/accounts/account-setup.html — documentado
- Na primeira conexão, mensagens antigas podem ser importadas em "modo arquivo" (datas originais, sem
  automações, estado alvo configurável); sem esse modo, tudo vira ticket novo e recebe auto-resposta. — mesma URL — documentado
- Limite de tamanho (padrão 10 MB, inclui anexos): mensagem maior não é importada; opcionalmente o sistema
  responde ao remetente avisando que não recebeu; senão só alerta o monitoramento. —
  https://admin-docs.zammad.org/en/latest/channels/email/settings.html — documentado
- Intervalo de polling: não documentado nas páginas lidas. — **A CONFIRMAR EM RUNTIME (E-01, E-18)**

**Pipeline**
- Há uma cadeia **ordenada** de filtros internos (não configuráveis) antes dos filtros do admin, nesta
  ordem conceitual: descartar cabeçalhos de controle vindos de canal não confiável → cripto (PGP/S/MIME) →
  detecção de auto-resposta → detecção de follow-up → redirecionamento de follow-up para ticket mesclado →
  dono do follow-up → remetente via Reply-To → **ignorar notificações do próprio sistema (anti-laço)** →
  identificação do usuário (inclui atribuir ao cliente original e-mails **encaminhados por agentes**) →
  ausência temporária → política de follow-up do grupo → bounces → filtros do admin → artigo interno →
  grupo → papel do remetente → criação/identificação do remetente. —
  https://admin-docs.zammad.org/en/latest/channels/email/filters/system-filters.html — documentado
- Filtros do admin rodam antes de virar ticket, casam remetente/assunto/corpo/cabeçalhos com regex e
  setam grupo, dono, prioridade, tag, estado e visibilidade. — https://admin-docs.zammad.org/en/latest/channels/email/filters.html — documentado
- Canal "confiável" permite que cabeçalhos proprietários na mensagem definam atributos, forcem/suprimam
  tratamento de auto-resposta ou **descartem** a mensagem; em canal não confiável esses cabeçalhos são
  removidos. — https://admin-docs.zammad.org/en/latest/channels/email/email-headers.html — documentado

**Threading**
- Base: marcador (prefixo + número) no assunto. Métodos adicionais configuráveis: (a) assunto **e**
  Message-ID batendo com o artigo inicial (padrão); (b) qualquer Message-ID referenciado batendo com
  qualquer artigo existente; (c) referências dentro de e-mails anexados (encaminhamento como anexo);
  (d) marcador no **corpo**. A doc alerta para falsos positivos dos métodos extras. —
  https://admin-docs.zammad.org/en/latest/channels/email/settings.html — documentado
- Dígito verificador opcional no número reduz falsos positivos; marcador pode ser omitido do assunto, aí
  tudo depende das outras checagens. — https://admin-docs.zammad.org/en/latest/settings/ticket.html — documentado
- Sem marcador e sem referência conhecida → ticket novo. — inferido
- Assunto "Re:" igual sem cabeçalhos (fixture 06) → ticket novo. — inferido / **A CONFIRMAR EM RUNTIME (E-07)**
- Exatamente qual combinação vale no padrão para fixture 03 vs 04 (só References). — **A CONFIRMAR EM RUNTIME (E-04, E-05, E-06)**

**Saída**
- Assunto de resposta: prefixo de resposta + assunto + marcador; assuntos longos truncados com reticências
  (padrão ~110 caracteres). Remetente exibido "agente via canal" (configurável). Notificações de sistema
  saem de um endereço no-reply. — https://admin-docs.zammad.org/en/latest/channels/email/settings.html — documentado
- Bloqueio de envio de notificações para endereços típicos de sistema (mailer-daemon, postmaster, noreply…). — mesma URL — documentado
- Formato do Message-ID de saída, In-Reply-To/References e cabeçalhos anti-laço de saída: não documentados. — **A CONFIRMAR EM RUNTIME (E-03)**

**Anti-laço / automáticos**
- Mensagem é considerada automática se tiver List-Unsubscribe, X-Loop, Precedence, Auto-Submitted ou o
  cabeçalho de supressão de auto-resposta da Microsoft; nesse caso **nenhuma auto-resposta é enviada**
  (o artigo é gravado). — https://admin-docs.zammad.org/en/latest/channels/email/filters/system-filters.html — documentado
- Mensagens cujo Message-ID contém o domínio do próprio sistema são ignoradas (fórum, mantenedor). —
  https://community.zammad.org/t/loop-protection/14700 — inferido / **A CONFIRMAR EM RUNTIME (E-12)**
- Ausência temporária (out-of-office) é anexada ao ticket certo **sem mudar o estado**. — system-filters.html — documentado

**Bounces**
- Bounce é reconhecido e anexado ao ticket original como follow-up; falha **permanente** marca o
  destinatário para suprimir notificações futuras; falha temporária é tratada como ausência. —
  system-filters.html — documentado (efeito exato no estado → **A CONFIRMAR EM RUNTIME (E-10)**)

**Spam**
- Sem tratamento nativo de X-Spam-Flag; a doc dá exemplo de filtro do admin que etiqueta como spam e fecha. —
  https://admin-docs.zammad.org/en/latest/channels/email/filters.html — documentado (E-13 deve criar ticket normal sem filtro)

**Pessoas**
- Remetente desconhecido é criado como usuário. Reply-To pode substituir o remetente (endereço apenas ou
  endereço + nome). — system-filters.html, settings.html — documentado
- E-mail enviado por agente a partir do sistema: o primeiro destinatário vira cliente (configurável). — settings.html — documentado
- Cc como participantes / quem recebe respostas futuras. — **A CONFIRMAR EM RUNTIME (E-15)**
- Remetente estranho respondendo na thread (fixture 16): provavelmente anexado (threading não depende do
  remetente) e o estranho vira usuário. — inferido / **A CONFIRMAR EM RUNTIME (E-17)**

**Conteúdo**
- Sanitização HTML, inline `cid:`, corte de citação, deduplicação por Message-ID: não documentados. —
  **A CONFIRMAR EM RUNTIME (E-02, E-04, E-08)**

### 2.2 Chatwoot (edição comunitária)

- Ingestão: (a) **encaminhamento** para um endereço de ingresso gerado por caixa (o servidor recebe via
  provedor de entrada configurado); (b) **IMAP** (polling) + SMTP; (c) OAuth Google/Microsoft. —
  https://developers.chatwoot.com/self-hosted/configuration/features/email-channel/introduction ,
  https://www.chatwoot.com/docs/product/channels/email/forward-email — documentado
- Threading: respostas usam um endereço Reply-To **por conversa** com parte local "reply+<hex aleatório>"
  no domínio de entrada; responder a ele anexa à conversa. Também lê Message-ID/References. —
  https://developers.chatwoot.com/self-hosted/configuration/features/email-channel/conversation-continuity — documentado
- Continuidade chat→e-mail: se o visitante saiu, a resposta do agente vai por e-mail e a resposta por
  e-mail volta para a mesma conversa (exige e-mail coletado no widget). — mesma URL — documentado
- Sem correspondência: não documentado (presumivelmente conversa nova). — **A CONFIRMAR EM RUNTIME (E-07, E-17)**
- Conversa resolvida reabre quando chega mensagem do contato. — https://www.chatwoot.com/hc/user-guide/articles/1677231493-lesson-2-dashboard-basics — documentado
- Anti-laço, bounce, spam, Cc, sanitização, citação, duplicidade, intervalo de polling: **não documentados**. —
  **A CONFIRMAR EM RUNTIME (E-02, E-08..E-16, E-18)**

### 2.3 FreeScout

**Ingestão**
- IMAP ou POP3 por caixa, disparado pelo agendador (cron por minuto; intervalo configurável; menos de 1
  minuto não suportado). **Busca só mensagens não lidas** — se outro cliente marcar como lida no servidor,
  ela não entra. Ferramenta manual para buscar todas as não lidas. — https://github.com/freescout-help-desk/freescout/wiki/Fetching-Emails ,
  https://github.com/freescout-help-desk/freescout/wiki/FAQ — documentado
- Data da mensagem = momento da busca, não o cabeçalho Date (só em importação especial). — FAQ — documentado
- Apagar no FreeScout não apaga do servidor. — FAQ — documentado

**Threading**
- Mecanismo de encadeamento não documentado; número da conversa no assunto **não** é recurso nativo
  documentado (há pedido de recurso). — FAQ — documentado (ausência) → **A CONFIRMAR EM RUNTIME (E-04..E-07)**

**Conteúdo**
- Resposta do cliente escrita "dentro" do texto citado não aparece (limitação conhecida); há modo
  alternativo de separação de resposta e "ver original" (rebusca no IMAP). — FAQ — documentado
- Anexos com extensão potencialmente perigosa (ex.: PDF com script) recebem extensão alterada. — FAQ — documentado

**Anti-laço**
- Reconhece como resposta automática: cabeçalhos estilo X-Autoreply/X-Autorespond, Auto-Submitted =
  auto-replied, Precedence (ou variante X-) = auto_reply/bulk/junk; laços infinitos surgem quando o robô
  remoto não manda esses cabeçalhos. — FAQ — documentado (o que exatamente é suprimido — ticket? auto-resposta? → **A CONFIRMAR EM RUNTIME (E-09, E-11)**)
- Encaminhamentos/auto-respostas configurados na própria caixa ou nos endereços dos agentes podem gerar
  laço. — Fetching-Emails — documentado
- Remetente = endereço da própria caixa: não documentado. — **A CONFIRMAR EM RUNTIME (E-12)**

**Pessoas**
- Cliente em Cc que responde **vira o cliente da conversa**. — FAQ — documentado (**E-15** deve observar a troca)
- Agente que responde a uma notificação de um endereço não vinculado à conta recebe rejeição por e-mail;
  aceitam-se só o e-mail do usuário e seus alternativos. — FAQ — documentado
- Encaminhamento por agente com marcador especial no topo cria conversa em nome do **primeiro endereço
  encontrado no corpo** (exige encaminhamento "de verdade", um único destinatário, não manda
  auto-resposta; se não achar endereço usa o From). Sem o marcador, o encaminhador vira cliente. — FAQ — documentado (E-16)
- Remetente estranho de cliente respondendo: não documentado. — **A CONFIRMAR EM RUNTIME (E-17)**

**Bounces / spam / saída**
- Bounces do Amazon SES não são vinculados à conversa; falha de envio é re-tentada de hora em hora por
  ~1 semana com aviso ao agente após 1 hora. — FAQ — documentado
- Spam: sem entrada na doc do núcleo (status "spam" manual; regras via módulo pago). — FAQ ,
  https://freescout.net/module/workflows/ — documentado (ausência)
- Cabeçalhos de saída (Message-ID, Reply-To): não documentados. — https://github.com/freescout-help-desk/freescout/wiki/Sending-Emails — **A CONFIRMAR EM RUNTIME (E-03)**

### 2.4 osTicket

**Ingestão**
- Duas vias: **piping** (local, a partir do MTA; ou remoto, via HTTP para a API com chave e IP liberado) e
  **polling POP3/IMAP** por endereço. — https://docs.osticket.com/en/latest/Getting%20Started/Email%20Piping.html ,
  https://docs.osticket.com/en/latest/Getting%20Started/Email%20Settings.html — documentado
- Polling por endereço: frequência, mensagens por rodada, pasta; depois de processar: **mover para pasta
  (recomendado)**, apagar, ou nada — neste caso o sistema guarda os Message-IDs para não rebuscar, **mas a
  doc admite que duplicatas ainda podem ocorrer**. — https://docs.osticket.com/en/latest/Admin/Emails/Emails.html — documentado
- Agendamento por cron externo ou "auto-cron" disparado pela atividade dos agentes (para quando ninguém
  está logado). — https://docs.osticket.com/en/latest/Getting%20Started/POP3-IMAP%20Settings.html — documentado
- Piping: erro de saída do script pode gerar bounce falso ao remetente mesmo com o ticket criado. — Email Piping — documentado

**Regras de aceite**
- Aceitar ou não e-mails de usuários desconhecidos (fora do diretório); aceitar ou não colaboradores
  vindos do e-mail. — https://docs.osticket.com/en/latest/Admin/Emails/Settings.html — documentado
- Lista de banimento de remetentes. — https://docs.osticket.com/en/latest/Admin%20Panel.html (índice) — documentado (comportamento exato → E-13/E-17)
- Filtros **só na criação** (por canal ou endereço específico), até 25 regras, combinação qualquer/todas,
  ordem numérica, opção de parar: rejeitar, setar departamento/estado/prioridade/SLA/tópico/agente,
  desligar auto-resposta, usar Reply-To como endereço do usuário. —
  https://docs.osticket.com/en/latest/Admin/Manage/Ticket%20Filters.html — documentado
- Limite de tickets abertos por usuário (excedente → negado + aviso). — https://docs.osticket.com/en/latest/Admin/Settings/Tickets.html — documentado

**Threading**
- Não descrito na doc oficial atual. — **A CONFIRMAR EM RUNTIME (E-04..E-07)** (expectativa: número no
  assunto + Message-ID)
- Resposta em ticket cujo estado fechado não permite reabrir → ticket novo cujo assunto referencia o
  antigo. — https://docs.osticket.com/en/latest/Admin/Manage/Lists.html — documentado

**Conteúdo**
- Anexos: aceitar ou não em tickets novos; acima do tamanho máximo o anexo é rejeitado e uma nota interna
  avisa o agente (o ticket é criado). — Tickets.html — documentado
- Rich text/HTML na thread só se habilitado; iframes de domínios não permitidos são removidos. —
  https://docs.osticket.com/en/latest/Admin/Settings/System.html — documentado
- Corte de citação: opção de remover correspondência anterior, senão usa uma linha separadora de resposta
  inserida nos e-mails de saída. — https://help.itarian.com/topic-452-1-949-13132-Email-Settings-and-Options.html
  (manual de produto derivado do osTicket) — inferido / **A CONFIRMAR EM RUNTIME (E-04)**

**Anti-laço / bounces / spam**
- Auto-respostas: ticket novo, mensagem nova (confirmação ao remetente + aviso aos demais participantes),
  excesso de limite; desligáveis por endereço, departamento, tópico e filtro. A doc **não descreve**
  supressão para mensagens automáticas, bounces ou laços. — https://docs.osticket.com/en/latest/Guides/Alerts%20Guide.html — documentado (ausência) → **A CONFIRMAR EM RUNTIME (E-09..E-12)**
- Spam: nenhum tratamento documentado de X-Spam-Flag (filtro pode casar campos, cabeçalho bruto não
  confirmado). — Ticket Filters — **A CONFIRMAR EM RUNTIME (E-13)**

### 2.5 Znuny

**Ingestão**
- Contas POP3/POP3S/IMAP/IMAPS buscadas pelo daemon (padrão a cada 10 min no manual 6.0); **a mensagem é
  apagada do servidor** (sem opção de manter). Alternativa: piping via comando que lê a mensagem da entrada
  padrão (procmail/fetchmail), podendo fixar a fila. — https://doc.znuny.org/legacy/manual/admin/6.0/en/html/email-settings.html — documentado
- Distribuição: tudo para uma fila fixa, ou pela fila vinculada ao endereço do destinatário; sem vínculo →
  fila bruta padrão. Conta "confiável" interpreta cabeçalhos proprietários de controle; filtros do admin
  rodam sempre. — mesma URL — documentado
- Limite de tamanho 16 MB; reconexão a cada 20 mensagens. HTML convertido para texto por padrão (6.0). —
  https://doc.znuny.org/legacy/manual/admin/6.0/en/html/ConfigReference_Section_Core_Email_PostMaster.html — documentado

**Threading (ordem documentada)**
1. checagem de bounce; 2. número válido no **assunto** (ligado); 3. **In-Reply-To/References** quando não há
número no assunto (ligado); 4. número no **corpo** (desligado); 5. em **anexos** (desligado); 6. no
**fonte bruto** (desligado); 7. número **externo** via filtro (desligado). — ConfigReference PostMaster — documentado
- Follow-up → estado aberto (padrão); política de fechado por fila: reabrir / rejeitar (auto-resposta de
  rejeição) / ticket novo vinculado. — https://doc.znuny.org/znuny/admin/queues/index.html — documentado
- Cliente que encaminha e-mail interno → artigo marcado interno. — ConfigReference PostMaster — documentado

**Filtros**
- Casam cabeçalhos por regex (com negação e captura), setam cabeçalhos de controle (ignorar → registrado no
  log de comunicação e apagado, sem ticket; fila; prioridade; cliente; estado…), ordem por nome, opção de
  parar. Existe filtro que delega a um comando externo (ex.: scanner de spam) e filtro de número externo. —
  https://doc.znuny.org/znuny-lts/admin/automation/postmaster_filter/index.html ,
  email-settings.html — documentado
- Cabeçalhos de spam fazem parte da lista de cabeçalhos lidos, mas **nenhuma ação automática por
  X-Spam-Flag** sem filtro. — ConfigReference PostMaster — documentado / **A CONFIRMAR EM RUNTIME (E-13)**

**Anti-laço**
- Limite de e-mails automáticos por endereço/dia (padrão 40), ajustável por endereço. — ConfigReference
  PostMaster , https://www.znuny.com/blog/loop-protection-and-znuny — documentado (o que ocorre ao estourar → **A CONFIRMAR**)
- Auto-resposta suprimida se a mensagem tem marcador de laço; remetentes tipo mailer-daemon/postmaster/abuse
  nunca recebem auto-resposta. X-Loop, Precedence e Auto-Submitted estão entre os cabeçalhos lidos. —
  https://doc.znuny.org/znuny/admin/communication/autoresponses/index.html , ConfigReference — documentado /
  inferido (mapeamento exato cabeçalho→supressão → **E-09, E-11, E-12**)

**Bounces**
- Detectados por filtro e tratados como **follow-up normal** por padrão (entram no ticket original). —
  ConfigReference PostMaster — documentado (E-10)

**Pessoas**
- Cliente desconhecido: identificador de cliente copiado do endereço do remetente. — ConfigReference — documentado
- Cc, remetente estranho em thread, encaminhamento por agente: não documentados. — **A CONFIRMAR EM RUNTIME (E-15..E-17)**
- Agente pode "devolver" (redirecionar) um e-mail a outro endereço externo preservando o remetente. —
  https://doc.znuny.org/znuny/agentinterface/ticketviews/agentticketbounce/index.html — documentado

### 2.6 UVdesk (open source)

- Caixas IMAP (só IMAP documentado), várias caixas; conversão em ticket por comando de atualização agendado
  (um agendamento por caixa, segundo issue). Opção de apagar a mensagem da caixa após converter. —
  https://docs.uvdesk.com/uvdemo/settings/mailbox.html , https://github.com/uvdesk/community-skeleton/issues/278 ,
  CHANGELOG-1.0 (cópia local) — documentado / inferido
- Lista negra/branca por e-mail, domínio ou IP: remetente bloqueado é **rejeitado** (endereço na lista
  branca vence domínio na negra). — https://docs.uvdesk.com/uvdemo/settings/block-spam.html — documentado
- Colaboradores: respostas de colaborador entram na thread; Cc no primeiro e-mail; respostas a Cc/Bcc
  pelo painel do cliente; e-mails para Cc/Bcc vão sem link do ticket (não são clientes). — CHANGELOG-1.0 ,
  https://www.uvdesk.com/en/blog/uvdesk-latest-release/ — documentado (notas de versão)
- Threading, anti-laço, bounce, X-Spam-Flag, sanitização, citação: não documentados. — **A CONFIRMAR EM RUNTIME (E-02..E-14)**

### 2.7 Frappe Helpdesk

- Contas de e-mail do framework: IMAP ou POP; **polling a cada 10 min** + botão de busca manual; sincronizar
  todas ou só não lidas; quantidade da 1ª sincronização; limite de anexo; uma conta padrão de entrada e uma
  de saída. — https://docs.frappe.io/helpdesk/settings , https://docs.frappe.io/erpnext/email-account — documentado
- Saída: Reply-To = endereço da conta padrão de entrada; respostas que chegam ali são vinculadas à
  comunicação relacionada. — https://docs.frappe.io/erpnext/email-account — documentado
- Threading: In-Reply-To primeiro; se ausente/irresolúvel, **percorre References do mais novo para o mais
  antigo** e liga à correspondência mais recente (adicionado em 2026 para corrigir tickets duplicados em
  encaminhamentos). — https://frappe.io/blog/product-updates/product-updates-for-april-2026 — documentado
- Framework oferece endereço único por documento (presente em To/Cc, não Bcc) para vincular e-mails; não
  está claro se o Helpdesk usa. — https://docs.frappe.io/erpnext/v13/user/manual/en/setting-up/email/linking-emails-to-document — inferido
- Marcador no assunto: não documentado. — **A CONFIRMAR EM RUNTIME (E-06)**
- Pesquisa de satisfação enviada **na mesma thread**. — settings — documentado
- Ticket fechado: cliente não pode responder (documentado para a interface; e-mail?). —
  https://docs.frappe.io/helpdesk/lesson-2understanding-ticket-view — **A CONFIRMAR EM RUNTIME (T-05)**
- Anti-laço, bounce, spam, Cc, sanitização, citação, duplicidade: não documentados. — **A CONFIRMAR EM RUNTIME**

---

## 3. Tabela comparativa

| Aspecto | Zammad | Chatwoot CE | FreeScout | osTicket | Znuny | UVdesk | Frappe HD |
|---|---|---|---|---|---|---|---|
| Entrada | IMAP/POP, OAuth, piping | encaminhamento p/ ingresso, IMAP, OAuth | IMAP/POP (cron) | piping (local/HTTP) + IMAP/POP | IMAP/POP (daemon) + piping | IMAP (comando agendado) | IMAP/POP (10 min) |
| Após importar | apaga (ou marca lida) | ? | deixa; só lê não-lidas | mover p/ pasta / apagar / nada | apaga sempre | opcional apagar | não-lidas ou todas |
| Marcador no assunto | sim, prefixo+nº, posição config. | não | não nativo | sim (provável) | sim, prefixo+nº | ? | ? |
| In-Reply-To/References | config. (assunto+ID inicial; ou qualquer ID) | sim + Reply-To por conversa | ? | provável | sim (se sem nº no assunto) | ? | IRT, fallback References |
| Corpo/anexo | opcional | não | não | ? | opcional (desligado) | ? | não |
| Sem nada | ticket novo | conversa nova? | ? | ticket novo | ticket novo | ? | ticket novo |
| Auto-detecção de automático | List-Unsub, X-Loop, Precedence, Auto-Submitted, supressão MS | ? | X-Autoreply, Auto-Submitted, Precedence | não doc. | marcador de laço + lista de remetentes sistema | ? | ? |
| Limite auto-respostas | não doc. | ? | ? | ? | 40/dia por endereço | ? | ? |
| Laço do próprio sistema | ignora notificações próprias; ID com domínio próprio (fórum) | ? | ? | ? | ? | ? | ? |
| Bounce | anexa ao ticket; permanente marca contato | ? | SES não vincula | não doc. | follow-up normal | ? | ? |
| Spam (X-Spam-Flag) | só via filtro | ? | manual | via filtro? | via filtro/comando | lista negra (rejeita) | ? |
| Remetente desconhecido | cria usuário | cria contato? | ? | configurável aceitar/recusar | cria cliente pelo endereço | ? | cria contato? |
| Cc | ? | ? | quem responde vira cliente | colaboradores (config.) | ? | colaboradores | ? |
| Encaminhamento por agente | atribui ao cliente original | ? | marcador explícito no topo | ? | ? | ? | ? |
| Limite tamanho | 10 MB (aviso opcional ao remetente) | ? | memória PHP | por anexo (nota interna) | 16 MB | ? | limite de anexo |

---

## 4. Divergências e pontos "A CONFIRMAR EM RUNTIME"

| ID | O que medir | Onde a doc é ambígua/silenciosa |
|---|---|---|
| E-01 | Estado inicial, criação do solicitante, intervalo real de polling | Zammad/Chatwoot/osTicket (intervalo); estado "novo" vs "aberto" |
| E-02 | Qual parte vira corpo (HTML vs texto), `<script>` removido, `cid:` resolvido, PDF listado | nenhum projeto documenta sanitização; Znuny converte HTML em texto por padrão (6.0) |
| E-03 | Formato do Message-ID de saída, In-Reply-To/References, Reply-To (Chatwoot "reply+…"; Frappe conta padrão), marcador no assunto, cabeçalhos anti-laço de saída | nenhum documenta o Message-ID de saída |
| E-04 | Encadeia pela In-Reply-To? Corte de citação | Zammad padrão exige assunto+ID inicial? FreeScout/osTicket/UVdesk sem doc |
| E-05 | Só References | Frappe documenta; Znuny documenta; Zammad depende do método configurado |
| E-06 | Só marcador no assunto | FreeScout/Chatwoot/Frappe provavelmente **não** encadeiam |
| E-07 | "Re:" igual sem nada | todos provavelmente criam ticket novo; verificar se algum casa por assunto |
| E-08 | Reenvio do mesmo Message-ID | só osTicket menciona rastrear IDs (e admite duplicatas); demais silenciosos |
| E-09 | Auto-resposta: grava? reabre? responde? | Zammad documenta supressão de resposta (grava artigo); Znuny idem por marcador; FreeScout lista cabeçalhos |
| E-10 | DSN: vira follow-up? marca contato? muda estado? | Zammad e Znuny documentam anexar ao original; demais silenciosos |
| E-11 | Precedence: bulk / List-Id | Zammad e FreeScout tratam como automático; ticket é criado? |
| E-12 | From = endereço de suporte | Zammad ignora notificações próprias; demais silenciosos |
| E-13 | X-Spam-Flag | nenhum respeita nativamente (só via filtro) — esperar ticket normal |
| E-14 | ISO-8859-1 / encoded-word | ninguém documenta |
| E-15 | Cc vira participante e recebe respostas? | FreeScout troca o cliente; osTicket colaboradores por configuração |
| E-16 | Encaminhado por agente → solicitante original? | Zammad automático; FreeScout só com marcador explícito |
| E-17 | Remetente estranho na thread | FreeScout rejeita **agentes** não vinculados; para clientes ninguém documenta |
| E-18 | IMAP fora 5 min | FreeScout (só não-lidas) e Zammad (marcar lida) podem perder se a caixa for alterada; osTicket "nada" pode duplicar |

Divergências de fundo:
- **Âncora primária do threading**: marcador no assunto (Zammad, Znuny, osTicket) vs cabeçalhos/Reply-To
  único (Chatwoot, Frappe, FreeScout). Os primeiros sobrevivem a clientes que perdem cabeçalhos; os
  segundos sobrevivem a quem edita o assunto.
- **Auto-respostas**: os que documentam (Zammad, Znuny, FreeScout) **gravam** a mensagem automática e
  apenas suprimem a resposta automática de volta; Znuny ainda limita o volume por destinatário.
- **Bounces**: Zammad/Znuny anexam ao ticket original; Zammad ainda marca o endereço como inválido.
- **Idempotência**: só osTicket documenta deduplicação por Message-ID, e com ressalva.

---

## 5. Opinião preliminar para o MVP do PantherDesk

1. **Ingestão**: começar com IMAP polling (pasta configurável) **e** um endpoint de entrega bruta (piping/
   webhook do MTA) que caiam no **mesmo pipeline**. Guardar o `.eml` bruto antes de processar
   (reprocessável, auditável). Após processar, **mover para pasta** (modelo osTicket) em vez de apagar ou
   depender de "não lida" — ambos têm modos de perda documentados.
2. **Idempotência**: chave única por (caixa, Message-ID normalizado); sem Message-ID, usar hash do conteúdo
   bruto. Reprocessar a mesma mensagem nunca cria segundo ticket nem segundo artigo (E-08, E-18).
3. **Ordem de classificação** (inspirada no pipeline do Zammad/Znuny, que é o mais explícito):
   tamanho/parse → laço próprio (From = endereço do sistema, ou Message-ID/cabeçalho de laço nosso) →
   bounce (multipart/report DSN) → automático (Auto-Submitted ≠ no, Precedence bulk/junk/list/auto_reply,
   X-Autoreply/X-Autorespond, List-Id/List-Unsubscribe, supressão MS) → spam (respeitar X-Spam-Flag: YES do
   MTA, enviando para estado `spam` sem auto-resposta; ninguém faz isso nativamente e é barato) →
   threading → identidade → conteúdo.
4. **Threading** em camadas, determinístico, sem casar por assunto parecido:
   (a) In-Reply-To, depois References do mais novo ao mais antigo, contra Message-IDs que **nós** emitimos
   ou recebemos (tabela de IDs por mensagem); (b) marcador no assunto `[#N]` validado (com dígito
   verificador ou token curto para evitar falsos positivos); (c) opcional: Reply-To com sub-endereço por
   ticket (`suporte+token@`) — cobre clientes que descartam cabeçalhos e assunto. Sem nenhum → ticket novo
   (E-07). Ticket mesclado segue o ponteiro; ticket fechado aplica a política da Área 1.
5. **Saída**: Message-ID próprio com domínio do sistema e identificador opaco do ticket/mensagem;
   In-Reply-To/References corretos; marcador no assunto; `Auto-Submitted: auto-replied` em toda
   auto-resposta/notificação (e `auto-generated` em notificações), mais um cabeçalho de laço próprio.
6. **Automáticos e bounces**: **gravar** no ticket como mensagem do sistema, **não** reabrir, **não**
   disparar auto-resposta; DSN permanente marca o endereço como inválido (suprime envios), como no Zammad.
   Limite de N auto-respostas por destinatário por dia (Znuny) como rede de segurança.
7. **Pessoas**: remetente desconhecido cria solicitante (configurável para recusar); Cc vira
   **participante** (não troca o solicitante — evitar o comportamento do FreeScout); remetente estranho
   numa thread válida entra como participante e a mensagem é anexada, mas marcada para revisão (E-17);
   encaminhamento por agente: detectar `message/rfc822` ou bloco de encaminhamento e usar o remetente
   original como solicitante (E-16).
8. **Conteúdo**: preferir HTML sanitizado por allowlist (sem script/style/event handlers/iframes), com
   texto alternativo como fallback; reescrever `cid:` para anexos internos; decodificar charsets/encoded-
   words; cortar citação por heurística conservadora (separador de saída nosso + padrões "On … wrote:")
   mantendo sempre o original disponível (lição do FreeScout: texto escrito dentro da citação some).
