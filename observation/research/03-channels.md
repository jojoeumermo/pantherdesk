# Área 3 — Canais

> Estudo clean-room. Fonte: somente documentação pública oficial (docs, guias de
> administração, bases de conhecimento, catálogo de módulos). Nenhum código-fonte
> foi lido. Todo o texto abaixo está em palavras próprias; não há cópia de
> textos de interface, chaves de configuração ou nomes internos.
>
> Legenda de confiança: **documentado** = a página citada afirma o comportamento;
> **inferido** = dedução a partir da documentação, sem afirmação explícita.
> Itens marcados **A CONFIRMAR EM RUNTIME** vão para os cenários C-* (seção 4).
>
> Data da pesquisa: 2026-10-26. Peppermint excluído por instrução.

---

## 1. Problema

Um helpdesk precisa receber pedidos por mais de um meio além do e-mail:

- **Formulário web público** (no portal ou embutido no site do cliente), sem exigir login, o que abre a porta para spam/bots.
- **Chat ao vivo** (widget no site), com conversa síncrona e presença de agentes.
- **Mensageria** (WhatsApp, Telegram), com regras do provedor (janela de 24 h, templates, webhooks).
- **Redes sociais** (Facebook, Instagram, X/Twitter), com APIs instáveis e políticas comerciais do provedor.
- **SMS**, via provedores como Twilio.

Para cada canal, as perguntas de projeto são:

1. Como o canal é configurado conceitualmente (credenciais do provedor, webhook de entrada, grupo de destino)?
2. Como uma mensagem do canal vira ticket/conversa (um ticket por mensagem? por contato? reabre o último aberto?).
3. Como o mesmo cliente é reconhecido entre canais (e-mail × telefone × identificador do provedor), ou seja, a unificação de contatos.
4. Que proteção anti-spam existe nos canais públicos.

---

## 2. Comportamento documentado por projeto

### 2.1 Zammad

**Canais existentes na documentação atual.** O índice do manual de administração lista: web (criação pelo portal do cliente), formulário embutível, e-mail (genérico, Google, Microsoft 365 via Graph ou IMAP), chat, SMS, Facebook, Telegram e WhatsApp. O X/Twitter **não aparece** mais no índice "latest". Uma nota anterior da própria documentação dizia que a integração com o X dependia de um nível de API caro e que sua remoção seria considerada.
- URL: https://admin-docs.zammad.org/en/latest/ (índice); busca retornou a nota sobre o X em https://admin-docs.zammad.org/en/latest/channels/twitter-x/twitter-x-note.html, mas a página hoje responde 404.
- Confiança: documentado (lista de canais); **inferido** (X removido ou descontinuado). **A CONFIRMAR EM RUNTIME** (C-03).

**Formulário web (embutível).**
- Há um único formulário por instância. O canal vem desativado e, ao ser ativado, tem um grupo de destino escolhido pelo admin. Os campos padrão são nome, e-mail e mensagem; dá para acrescentar um anexo e uma caixa de aceite com texto livre (por exemplo, aviso de privacidade).
- A aparência é ajustada num designer que gera um trecho de código para colar no site. Esse ajuste não fica salvo no servidor.
- Depois do envio, aparece uma mensagem de agradecimento com o número do ticket.
- O e-mail informado é validado por consulta de registro MX do domínio.
- **Anti-spam:** há duas camadas. A primeira é um campo-isca invisível (honeypot): se vier preenchido, o envio é rejeitado. A segunda é um CAPTCHA opcional, com vários provedores possíveis (soluções sem terceiros e serviços externos). Há também limites de volume por IP por hora, por IP por dia e um teto diário global de tickets vindos do formulário.
- A documentação recomenda bloquear o acesso ao script do formulário quando não for usado.
- URL: https://admin-docs.zammad.org/en/latest/channels/form.html
- Confiança: documentado. Como o solicitante é criado ou associado a partir do formulário **não está descrito**, então fica **A CONFIRMAR EM RUNTIME** (C-01, C-04).

**Canal web (portal do cliente).** O admin pode ligar ou desligar a criação de tickets pelo cliente logado e restringir em quais grupos o cliente pode abrir ticket. Se houver um único grupo permitido, o campo de grupo some.
- URL: https://admin-docs.zammad.org/en/latest/channels/web.html
- Confiança: documentado.

**Chat.**
- É possível ter vários canais de chat (um por site) e "tópicos" que separam assuntos ou grupos de especialistas. Cada agente escolhe os tópicos que atende.
- O widget só aparece ao visitante se houver ao menos um agente disponível e com capacidade livre. Cada agente define quantos chats simultâneos aceita e fica indisponível se desligar o recebimento ou ficar offline.
- Não há resposta automática no início: a saudação vai quando um agente aceita o chat.
- Há bloqueio por IP e por país, configurado por tópico.
- No lado do agente, os visitantes aparecem numa fila de espera, os chats em andamento numa lista própria, e há uma lista de agentes ativos. Ao encerrar o chat, o agente pode **convertê-lo manualmente em ticket**. O primeiro artigo do ticket aponta para o chat original, e existe um arquivo pesquisável de chats antigos.
- URLs: https://admin-docs.zammad.org/en/latest/channels/chat.html, https://user-docs.zammad.org/en/latest/extras/chat.html
- Confiança: documentado. O transporte é inferido como websocket a partir dos requisitos de servidor (ver área 9). **A CONFIRMAR EM RUNTIME** (C-02).

**WhatsApp.**
- Exige a API de nuvem oficial da Meta; o app comum de negócios não serve. Cada número de telefone vira um canal separado no Zammad.
- Respeita a janela de atendimento de 24 h: fora dela o agente não consegue escrever. O Zammad pode mandar um lembrete automático perto de 23 h para estimular o cliente a responder, e isso pode ser desligado.
- Templates aprovados pela Meta **não são suportados**, portanto o Zammad não inicia conversas; só responde contato iniciado pelo cliente.
- Cada envio leva no máximo um anexo, com limites de tamanho por tipo de mídia.
- URLs: https://admin-docs.zammad.org/en/latest/channels/whatsapp/index.html, https://admin-docs.zammad.org/en/latest/channels/whatsapp/limitations.html
- Confiança: documentado. O mapeamento mensagem → ticket e a identificação do cliente pelo telefone **não estão descritos**, então ficam **A CONFIRMAR EM RUNTIME** (C-03, C-04).

**Telegram.**
- Configura-se com um bot criado no Telegram (token) mais mensagem de boas-vindas, mensagem de despedida e grupo de destino. Exige instância acessível publicamente por HTTPS, porque a entrega é por webhook.
- **Mapeamento:** a primeira mensagem do cliente cria ticket; as mensagens seguintes entram no ticket aberto mais recente daquele cliente para aquele bot, até que ele seja fechado. Um comando de início só manda a saudação, sem criar ticket. Um comando de fim fecha o ticket aberto mais recente e manda a despedida.
- URL: https://admin-docs.zammad.org/en/latest/channels/telegram.html
- Confiança: documentado.

**SMS.**
- Entrada só via MessageBird ou Twilio. O provedor chama um webhook do Zammad, e o SMS recebido cria ticket no grupo escolhido; as respostas voltam por SMS.
- Existe uma conta separada só para notificações por SMS, disparadas por gatilhos ou agendador. Ela exige celular cadastrado no perfil do destinatário.
- URL: https://admin-docs.zammad.org/en/latest/channels/sms.html
- Confiança: documentado. A associação número → cliente não é descrita, então fica **A CONFIRMAR EM RUNTIME**.

**Facebook.**
- Postagens nas páginas conectadas viram tickets, e as respostas voltam como comentários. Mensagens privadas (Messenger) **não são mencionadas**.
- A configuração exige um app no painel da Meta, revisão de negócio e mudança do app para modo produção.
- URL: https://admin-docs.zammad.org/en/latest/channels/facebook.html
- Confiança: documentado (posts e comentários); inferido (sem DMs).

**Unificação de contato.** A documentação de usuários diz que usuários são globais à instância e que desativar não apaga tickets. Não há descrição de mesclagem automática entre e-mail, telefone e identificador de mensageiro.
- URL: https://admin-docs.zammad.org/en/latest/manage/users/index.html
- Confiança: inferido. **A CONFIRMAR EM RUNTIME** (C-04).

### 2.2 Chatwoot (somente edição comunitária)

**Modelo.** "Canal" é o tipo (site, e-mail, WhatsApp, etc.) e "caixa de entrada" (inbox) é uma instância configurada desse tipo. Pode haver várias do mesmo tipo, por exemplo dois números de WhatsApp. Cada caixa tem seus agentes, horário comercial, saudações, formulário pré-chat e regras de roteamento. Agentes só veem conversas de caixas às quais foram adicionados individualmente.
- URL: https://www.chatwoot.com/hc/user-guide/articles/1677492191-adding-inboxes
- Confiança: documentado.

**Canais listados:** chat no site, e-mail (contas Google/Microsoft por login ou servidor genérico), Facebook Messenger (DMs de página), Instagram DMs (conta comercial via login da Meta, hoje independente de página do Facebook), TikTok, WhatsApp (API de nuvem recomendada), SMS (Twilio ou Bandwidth), Telegram (token de bot), LINE e um **canal "API"** genérico. No canal API, o admin informa uma URL que recebe as mensagens de saída, o que permite plugar plataformas não suportadas.
- URL: mesma acima.
- Confiança: documentado. Não há canal X/Twitter na lista atual.

**Mapeamento mensagem → conversa.**
- Cada conversa pertence à caixa por onde chegou.
- Para canais sem threading nativo existe uma opção que mantém **uma única conversa aberta por contato**: novas mensagens reabrem ou continuam a existente em vez de criar outra.
- No WhatsApp, mensagens de saída fora da janela de 24 h exigem template aprovado pela Meta. Pela documentação, o Chatwoot suporta esse fluxo, ao contrário do Zammad.
- URL: https://www.chatwoot.com/hc/user-guide/articles/1677492191-adding-inboxes
- Confiança: documentado. O comportamento padrão com a opção desligada (cria conversa nova a cada mensagem? só depois de resolvida?) fica **A CONFIRMAR EM RUNTIME** (C-02/C-03).

**Chat no site.**
- Configuração por caixa: nome e domínio do site, cor, saudação, horário comercial com mensagem fora do expediente, pesquisa de satisfação ao resolver e coleta de e-mail ligada por padrão.
- **Formulário pré-chat** opcional: nome, e-mail, telefone e atributos customizados.
- O widget é instalado colando um trecho de script no site.
- Há um artigo separado sobre continuidade da conversa por e-mail, não lido em detalhe.
- URL: https://www.chatwoot.com/hc/user-guide/articles/1677580558-website-live-chat-settings-explained
- Confiança: documentado. A continuidade por e-mail quando o visitante sai é **inferida**, então fica **A CONFIRMAR EM RUNTIME** (C-02).

**Unificação de contato.**
- Contatos são da conta inteira. Um contato pode ter conversas em vários canais, e todas aparecem no perfil dele.
- Duplicatas surgem quando a pessoa escreve por dois canais antes que o sistema consiga casá-las. Nesse caso, o agente usa uma ação de **mesclar contatos**: o contato-base fica com conversas, etiquetas e atributos, e o outro é apagado definitivamente, sem possibilidade de desfazer.
- A documentação distingue *casamento de contato*, que associa registros, de *validação de identidade*. A validação é feita com uma assinatura HMAC calculada no servidor do cliente sobre o identificador do usuário. O site passa essa assinatura ao widget, e a caixa pode exigir a validação em todas as conversas, rejeitando quem não a apresenta. Sem ela, um visitante poderia se passar por outro e-mail.
- URLs: https://developers.chatwoot.com/api-reference/contacts/merge-contacts, https://www.chatwoot.com/hc/user-guide/articles/1677587479-how-to-enable-identity-validation-in-chatwoot
- Confiança: documentado. Os critérios exatos do casamento automático (e-mail? telefone?) ficam **A CONFIRMAR EM RUNTIME** (C-04).

**Anti-spam.** Fora a validação de identidade, a documentação lida **não menciona** CAPTCHA, honeypot ou limite por IP no widget.
- Confiança: inferido (ausência). **A CONFIRMAR EM RUNTIME** (C-01/C-02).

**Formulário web separado:** não existe como canal próprio. O equivalente é o pré-chat do widget.
- Confiança: inferido.

### 2.3 FreeScout

**Núcleo.** O núcleo é uma caixa compartilhada de e-mail: cada "mailbox" representa um departamento. Os clientes são compartilhados entre todas as mailboxes.
- URL: https://github.com/freescout-help-desk/freescout/wiki/FAQ
- Confiança: documentado.

**Canais via módulos** (consultados só como catálogo; todos aparecem como pagos, com licença vitalícia por instância):
- Chat ao vivo.
- Integração com WhatsApp (mensagens viram conversas).
- Telegram (mensagens ao bot viram conversas).
- Facebook (mensagens privadas da página viram conversas).
- Twitter (DMs viram conversas).
- SMS via Twilio.
- Portal do usuário final com widget de formulário de contato.
- Segurança extra, que acrescenta reCAPTCHA ao login e ao portal e permite restrição por IP.
- Filtro de spam com aprendizado.
- URL: https://freescout.net/modules/
- Confiança: documentado (catálogo).

**Portal do usuário final e formulário.**
- O cliente entra só com o e-mail e recebe um link de uso único válido por uma hora, sem senha. Se o e-mail não existir, o cliente é criado.
- Cada mailbox tem seu próprio link de portal e seu próprio código de widget.
- O ticket enviado pelo formulário vai direto para o banco: não passa pelo servidor de e-mail e **não manda e-mail ao cliente**. Os agentes só são avisados se tiverem ligado a notificação de conversa nova.
- O módulo **não traz CAPTCHA**; para isso é preciso o módulo de segurança extra.
- URL: https://freescout.net/module/end-user-portal/
- Confiança: documentado.

**Chat ao vivo (módulo).**
- Cada mailbox tem seu código de widget.
- Por padrão, as mensagens de um visitante caem numa mesma conversa. Uma opção da mailbox faz abrir conversa nova depois que a anterior foi fechada ou apagada.
- Respostas do agente voltam pelo chat e podem levar cerca de 10 s para chegar, o que sugere polling.
- Fora do horário, o widget pode mostrar um formulário de contato (exige o portal).
- O site pode pré-preencher nome, e-mail e telefone do visitante.
- O visitante **não recebe transcrição** por e-mail.
- URL: https://freescout.net/module/chat/
- Confiança: documentado; o transporte é **inferido**.

**Unificação de contato.** Os clientes são globais. Apagar um endereço de e-mail de um cliente pode gerar um cliente novo se houver conversas referenciando aquele endereço.
- URL: https://github.com/freescout-help-desk/freescout/wiki/FAQ
- Confiança: documentado (parcial). **A CONFIRMAR EM RUNTIME** (C-04).

### 2.4 osTicket

**Canais.** E-mail, portal do cliente (formulário web) e API. A documentação lida **não descreve** chat, WhatsApp, redes sociais nem SMS.
- Confiança: inferido (ausência na documentação).

**Formulário / portal.**
- O "tópico de ajuda" escolhido pelo cliente define departamento, prioridade, SLA, formulário extra de campos e se a confirmação automática vai ao cliente.
- URL: https://docs.osticket.com/en/latest/Admin/Manage/Help%20Topic.html
- Confiança: documentado.

**Anti-spam.**
- Uma opção de verificação humana põe CAPTCHA no portal do cliente (CAPTCHA de imagem gerado localmente; depende de uma biblioteca gráfica do PHP).
- Há um **limite de tickets abertos por e-mail/usuário**, apresentado como proteção contra spam e enxurrada de e-mails; ao exceder, o usuário recebe um aviso.
- URL: https://docs.osticket.com/en/latest/Admin/Settings/Tickets.html
- Confiança: documentado.

**Unificação.** O usuário é identificado pelo e-mail, e a configuração de visibilidade de colaborador controla o que ele vê no portal.
- Confiança: inferido. **A CONFIRMAR EM RUNTIME** (C-04).

### 2.5 Znuny

**Canais.** A documentação fala em canais de comunicação de **e-mail, telefone (registrado pelo agente) e interno**, este último usado inclusive pela interface do cliente. Os tickets nascem de e-mail recebido, de chamada registrada pelo agente ou do formulário do portal do cliente. Integrações externas passam pela camada genérica de web services.
- URLs: https://doc.znuny.org/znuny/annexes/entity_types/index.html, https://doc.znuny.org/znuny/concepts/articles/index.html, https://doc.znuny.org/znuny-agent-quickstart/the-basics/index.html
- Confiança: documentado. Não há chat, WhatsApp, redes sociais nem SMS na documentação do núcleo (inferido pela ausência).

**Portal do cliente.** O cliente pode se autorregistrar, criar ticket (escolhendo a fila de destino entre os campos padrão), ver o histórico e responder. A documentação lida **não menciona CAPTCHA** nem anti-spam.
- URLs: https://doc.znuny.org/znuny/customerinterface/index.html, https://doc.znuny.org/znuny/customerinterface/creating_tickets/index.html
- Confiança: documentado; a ausência de anti-spam é inferida e fica **A CONFIRMAR EM RUNTIME** (C-01).

### 2.6 UVdesk (edição open source)

**Canais.**
- O núcleo tem e-mail (mailboxes) e uma página pública de criação de ticket no centro de suporte (nome, telefone, e-mail, tipo, assunto, mensagem, anexos). Um ajuste define se é preciso estar logado para criar ticket.
- O catálogo de apps cita construtor de formulários e app de Facebook, sem dizer a edição.
- Há um módulo de WhatsApp para a edição open source que usa a Twilio como ponte e depende de um pacote adicional.
- URLs: https://docs.uvdesk.com/ (índice), https://docs.uvdesk.com/uvdemo/apps/explore_apps.html, https://www.uvdesk.com/en/apps/uvdesk-open-source-whatsapp-integration/ (catálogo), https://support.uvdesk.com/en/blog/how-to-enable-create-ticket-option-for-customer
- Confiança: documentado (e-mail e formulário); catálogo (WhatsApp e Facebook). **A CONFIRMAR EM RUNTIME** (C-03).

**Anti-spam.**
- Listas de bloqueio e de permissão por e-mail, domínio ou IP. Bloquear um IP impede inclusive o acesso ao site de suporte. Quando a mesma entrada está nas duas listas, prevalece a permissão, que é a mais específica.
- CAPTCHA: a página de recursos de marketing cita reCAPTCHA, mas a documentação técnica não confirma em qual edição.
- URL: https://docs.uvdesk.com/uvdemo/settings/block-spam.html
- Confiança: documentado (listas); CAPTCHA **A CONFIRMAR EM RUNTIME** (C-01).

### 2.7 Frappe Helpdesk

**Canais.**
- E-mail: várias contas, cada uma podendo receber, enviar ou ambos, com vários provedores suportados. E-mails recebidos viram tickets.
- Telefonia (Twilio/Exotel): o agente liga de dentro do ticket e as chamadas são registradas no ticket.
- Portal do cliente com formulário de ticket.
- Não há chat, WhatsApp, Telegram nem redes sociais na documentação oficial.
- URLs: https://frappe.io/helpdesk/integrations, https://frappe.io/helpdesk/customer-self-service
- Confiança: documentado; a ausência dos demais canais é inferida.

**Portal.**
- O formulário pede assunto, descrição, anexos e campos customizados. Enquanto o cliente digita o assunto, o portal sugere artigos da base de conhecimento (deflexão).
- O cadastro aberto pode ser desligado, deixando só usuários convidados. Gestores do lado do cliente podem convidar pessoas.
- **Anti-spam não mencionado.**
- URL: https://frappe.io/helpdesk/customer-self-service
- Confiança: documentado; anti-spam **A CONFIRMAR EM RUNTIME** (C-01).

---

## 3. Tabela comparativa

Legenda: ✔ = nativo no núcleo; M = módulo ou app (pago ou adicional); — = não documentado.

| Canal / aspecto | Zammad | Chatwoot (CE) | FreeScout | osTicket | Znuny | UVdesk | Frappe HD |
|---|---|---|---|---|---|---|---|
| E-mail | ✔ | ✔ | ✔ (núcleo) | ✔ | ✔ | ✔ | ✔ |
| Formulário web sem login | ✔ (embutível, 1 por instância) | só pré-chat | M (portal com link mágico) | ✔ (portal) | ✔ (portal, com autorregistro) | ✔ (opcional sem login) | ✔ (portal; cadastro pode ser fechado) |
| Chat ao vivo | ✔ (conversão manual em ticket) | ✔ (núcleo) | M | — | — | — | — |
| WhatsApp | ✔ (API de nuvem; sem templates) | ✔ (com templates) | M | — | — | M (via Twilio) | — |
| Telegram | ✔ (ticket aberto mais recente) | ✔ | M | — | — | — | — |
| Facebook | ✔ (posts e comentários) | ✔ (Messenger) | M (DMs) | — | — | app (edição?) | — |
| Instagram | — | ✔ | — | — | — | — | — |
| X/Twitter | removido ou em remoção (inferido) | — | M | — | — | — | — |
| SMS | ✔ (Twilio/MessageBird) | ✔ (Twilio/Bandwidth) | M (Twilio) | — | — | — | — (só voz) |
| Canal genérico via API | API REST | ✔ (canal "API") | API (módulo) | API | web services | API | API do framework |
| Anti-spam no formulário | honeypot + CAPTCHA + limites por IP e globais | validação HMAC de identidade | M (reCAPTCHA, filtro) | CAPTCHA + limite de abertos por usuário | — | listas de bloqueio e permissão | — |
| Unificação de contatos | usuário global (mescla: ?) | contato global + mesclagem manual + HMAC | cliente global | por e-mail | por login/e-mail | ? | ? |
| Granularidade do mapeamento | Telegram: 1 ticket aberto por cliente e bot | opção de 1 conversa aberta por contato | chat: 1 conversa, opcionalmente nova depois de fechada | — | — | — | — |

---

## 4. Pontos A CONFIRMAR EM RUNTIME → cenários

| # | Dúvida | Projeto(s) | Cenário |
|---|---|---|---|
| 1 | Envio do formulário sem login: o solicitante é criado na hora? É confirmado por e-mail? Um e-mail já existente é reaproveitado ou duplicado? | Zammad, FreeScout (portal), osTicket, Znuny, UVdesk, Frappe | C-01 |
| 2 | Anti-spam efetivo: o honeypot rejeita em silêncio ou com erro? Com que código HTTP o limite por IP responde? Há CAPTCHA por padrão? | Zammad, osTicket, UVdesk, Frappe, Znuny | C-01 |
| 3 | Formulário do portal FreeScout: confirmar que nenhum e-mail vai ao cliente | FreeScout | C-01 |
| 4 | Transcrição do chat, conversão em ticket (manual ou automática), transporte (websocket ou polling) e o que acontece quando o visitante sai | Zammad, Chatwoot, FreeScout | C-02 |
| 5 | Chatwoot com "uma conversa por contato" ligada e desligada: o que acontece com a mensagem nova depois de resolvida | Chatwoot | C-02 |
| 6 | Continuidade por e-mail quando o visitante do widget sai (Chatwoot) | Chatwoot | C-02 |
| 7 | Inventário real na tela de admin: X/Twitter ainda existe no Zammad? Facebook recebe DMs? Quais apps o UVdesk open source traz? | Zammad, UVdesk, Chatwoot | C-03 |
| 8 | Mesmo cliente por e-mail e formulário: um contato ou dois? Existe mesclagem e o que ela faz com os tickets? | todos | C-04 |
| 9 | Casamento automático de contatos no Chatwoot: critério (e-mail, telefone ou identificador) | Chatwoot | C-04 |
| 10 | Telefone (SMS/WhatsApp) casa com o campo de celular do usuário existente? | Zammad, Chatwoot | C-04 (variante) |

---

## 5. Recomendação preliminar para o MVP (simples e correto)

**Escopo do MVP:** e-mail (área 2) e **formulário web público** como único canal adicional. Chat, WhatsApp, redes e SMS ficam no roadmap.

1. **Modelo de canal desde já, implementação depois.** Cada ticket e cada mensagem guarda de qual canal e de qual instância de canal veio (o conceito de "inbox" do Chatwoot). Isso permite plugar chat e WhatsApp depois sem migração. Criar apenas os tipos "e-mail", "web" e "agente/telefone".
2. **Formulário público:**
   - Configurado com grupo de destino, campos mínimos (nome, e-mail, assunto, mensagem, anexo opcional) e aceite de privacidade opcional.
   - O solicitante é procurado pelo e-mail normalizado (minúsculas, sem espaços). Se não existir, é criado como "não verificado".
   - Confirmação por e-mail com número do ticket, reutilizando o pipeline de auto-resposta e anti-loop da área 2.
   - Como um formulário sem login permite que qualquer um escreva "em nome de" um e-mail, o histórico de tickets só aparece no portal depois de o dono do e-mail provar posse (link mágico por e-mail, como no FreeScout). Isso evita vazar o histórico alheio.
3. **Anti-spam em camadas (modelo Zammad, que é o mais completo e barato):**
   - Honeypot sempre ligado.
   - Limites de volume por IP (hora e dia) e um teto global diário, configuráveis.
   - Validação básica do domínio do e-mail.
   - CAPTCHA como opcional plugável, de preferência um que não exija terceiros.
   - Lista de bloqueio por e-mail, domínio ou IP, que vale também para o e-mail (modelo UVdesk).
   - Limite de tickets abertos por solicitante (modelo osTicket).
4. **Unificação de contatos:**
   - No MVP, um contato tem um e-mail primário e uma lista de identificadores secundários (outros e-mails, telefone), cada identificador único no tenant. O casamento automático usa **apenas** identificadores exatos.
   - Mesclagem manual por agente, com trilha de auditoria. Ao contrário do Chatwoot, a mesclagem deve ser **reversível ou ao menos registrada**, nunca uma exclusão silenciosa.
   - Para o roadmap: validação de identidade com HMAC no widget, como no Chatwoot, antes de confiar em e-mail declarado.
5. **Para o roadmap de mensageria:** adotar a regra "mensagem nova de um contato anexa ao ticket aberto mais recente dele naquele canal, senão cria ticket" (Telegram no Zammad, opção do Chatwoot). Tratar a janela de 24 h e os templates do WhatsApp como restrições do canal, não do ticket.
