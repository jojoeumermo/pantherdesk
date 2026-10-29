# Área 9 — Notificações em tempo real

> Estudo clean-room. Fonte: somente documentação pública oficial. Nenhum
> código-fonte foi lido. Texto em palavras próprias; não há cópia de textos de
> interface, nomes de eventos, chaves de configuração ou nomes internos.
> Confiança: **documentado** / **inferido**. **A CONFIRMAR EM RUNTIME** vai para
> os cenários R-* (seção 4). Data: 2026-10-26.

---

## 1. Problema

Com vários agentes trabalhando em paralelo, o sistema precisa:

1. **Atualizar listas e visões ao vivo**, mostrando ticket novo, mudança de estado ou de dono sem recarregar a página.
2. **Evitar colisão**, isto é, dois agentes respondendo ao mesmo ticket. As estratégias são presença ("quem está vendo"), indicador de digitação ou bloqueio exclusivo.
3. **Mostrar presença** dos agentes (online, ocupado, offline), o que se liga ao roteamento da área 4.
4. **Notificar** dentro do app (sino, contador), na área de trabalho (push do navegador), no celular e por som.
5. **Escolher o transporte:** websocket, polling AJAX, long-polling ou server-sent events. Isso afeta infraestrutura (proxy reverso, Redis, processo separado) e latência.

---

## 2. Comportamento documentado por projeto

### 2.1 Zammad

**Transporte.**
- O Zammad tem um **servidor de websocket** separado da aplicação web, numa porta própria. O proxy reverso precisa encaminhar as duas.
- A comunicação em tempo real via websocket **exige Redis**.
- Em Docker, o host e a porta do websocket são configuráveis por variáveis de ambiente.
- URLs: https://docs.zammad.org/en/latest/getting-started/configure-webserver.html, https://docs.zammad.org/en/latest/appendix/environment-variables.html, https://docs.zammad.org/en/latest/prerequisites/software.html
- Confiança: documentado. Se há fallback para polling quando o websocket falha, fica **A CONFIRMAR EM RUNTIME** (R-01).

**Detecção de colisão (presença).**
- Na barra inferior do ticket aparecem os avatares de todos os agentes que estão com aquele ticket aberto. O avatar cheio indica que o colega está olhando agora; o esmaecido, que ele tem o ticket aberto em outra aba e não está olhando; o avatar com ícone de lápis, que ele está editando.
- Além disso, há um aviso de conflito para que os agentes se coordenem antes de responder.
- O rascunho do agente é salvo automaticamente nas abas abertas.
- Rascunhos compartilhados por grupo podem ser ligados ou desligados.
- URLs: https://user-docs.zammad.org/en/latest/basics/work-with-tickets.html, https://admin-docs.zammad.org/en/latest/manage/groups/settings.html
- Confiança: documentado. **A CONFIRMAR EM RUNTIME** (R-02): latência da presença e o que dispara o aviso de conflito (edição simultânea? atualização do ticket por outro agente enquanto eu edito?).

**Atualização de visões.**
- A documentação não diz explicitamente que as visões atualizam ao vivo. Ela avisa que muitas visões tornam a atualização mais lenta ou até a interrompem, recomendando no máximo 15 a 20, e que cada visão mostra no máximo cerca de 2 mil tickets.
- Inferido: as visões são calculadas no servidor e empurradas periodicamente ou por evento.
- URL: https://admin-docs.zammad.org/en/latest/manage/overviews.html
- Confiança: inferido. **A CONFIRMAR EM RUNTIME** (R-01).

**Notificações in-app.**
- Um contador na barra lateral mostra as notificações novas.
- A grade de preferências separa a notificação interna do e-mail e permite limitar por grupo e escolher o som.
- Limpeza: notificações lidas manualmente somem em cerca de 10 min; as marcadas como lidas pelo sistema (porque o estado mudou) ficam cerca de 8 h; nada passa de 9 meses. A limpeza roda a cada 2 h.
- Há menção a colega via duplo "@", que gera notificação.
- O substituto em ausência recebe as notificações do ausente.
- URLs: https://user-docs.zammad.org/en/latest/extras/user-menu-profile-settings.html, https://user-docs.zammad.org/en/latest/basics/zammad-ui.html, https://user-docs.zammad.org/en/latest/basics/work-with-tickets.html
- Confiança: documentado. As notificações de **área de trabalho do navegador** não são descritas nas páginas lidas; é inferido que existem. **A CONFIRMAR EM RUNTIME** (R-03).

**Chat.** Agentes ligam ou desligam a disponibilidade e veem a fila de espera, os chats ativos e a lista de agentes ativos, tudo com contadores. A documentação não descreve indicador de digitação.
- URL: https://user-docs.zammad.org/en/latest/extras/chat.html
- Confiança: documentado; digitação **A CONFIRMAR EM RUNTIME** (C-02).

### 2.2 Chatwoot (edição comunitária)

**Transporte.**
- **WebSocket**, que a documentação marca como experimental. A conexão é autorizada por um token de assinatura que existe em dois tipos.
- O token de agente ou admin tem os mesmos privilégios do usuário e recebe todos os eventos da conta.
- O token de contato é gerado por sessão de contato e só recebe eventos daquela sessão: conversa, mensagem e digitação.
- Os tokens podem ser rotacionados.
- URL: https://chatwoot.com/hc/user-guide/articles/1677691027-how-to-setup-a-web_socket-connection
- Confiança: documentado.

**Categorias de evento** (descritas em palavras próprias):
- Conversa: criada, mudança de estado, reatribuição de agente ou de time, mesclagem de contatos, confirmação de leitura pelo contato.
- Mensagem: criada e editada.
- Digitação: começou e parou, para contato e para agente. Há um indicador de se o agente está escrevendo uma nota privada ou uma resposta ao cliente.
- Contato: criado e atualizado (só para agentes).
- Presença: agentes e contatos. O contato só vê o próprio status.
- Notificação: criada (só para agentes).
- URL: mesma acima.
- Confiança: documentado. Os mesmos eventos de digitação existem também como **webhook**.

**Presença.** O cliente precisa enviar um sinal de vida a cada cerca de 30 s para continuar aparecendo online. Os status são online, ocupado e offline (ver área 4).
- URLs: https://chatwoot.com/hc/user-guide/articles/1677691027-how-to-setup-a-web_socket-connection, https://www.chatwoot.com/hc/user-guide/articles/1677231493-lesson-2-dashboard-basics
- Confiança: documentado.

**Colisão.**
- A página de recursos descreve a detecção de colisão como o aviso de que um colega está digitando uma resposta, somado à visibilidade de quem está online, ao selo de dono na conversa e a notas privadas para coordenação.
- Não há trava exclusiva.
- A página de recursos não diz se tudo isso está na edição comunitária.
- URL: https://www.chatwoot.com/features/collision-detection
- Confiança: documentado (página de produto); edição **A CONFIRMAR EM RUNTIME** (R-02).

**Notificações.**
- Uma caixa de notificações in-app reúne atribuições, menções, conversas novas e alertas de SLA.
- Canais: som, que só toca com o painel aberto numa aba e é desligado por padrão, podendo tocar só com a janela inativa ou repetir a cada 30 s até ler; e-mail; e push, no navegador e no app móvel, que exige permissão do navegador ou do sistema operacional.
- URLs: https://www.chatwoot.com/hc/user-guide/articles/1677231493-lesson-2-dashboard-basics (e resultados de busca no guia do usuário)
- Confiança: documentado.

**Listas ao vivo.** As abas de conversas ("minhas", "sem dono", "todas") não dizem explicitamente que atualizam ao vivo. Inferido, pelos eventos de conversa no websocket: **atualizam**.
- **A CONFIRMAR EM RUNTIME** (R-01).

### 2.3 FreeScout

**Transporte.**
- O guia de desenvolvimento descreve um mecanismo **sem conexão persistente**: o script da página **pergunta ao servidor periodicamente, via AJAX**, se há eventos novos. Os eventos pendentes ficam guardados no servidor até serem buscados.
- Uma notificação recém-criada é retida por um instante para permitir desfazer a ação.
- O módulo de chat menciona até cerca de 10 s de atraso na entrega ao visitante, o que é coerente com polling.
- URLs: https://github.com/freescout-help-desk/freescout/wiki/Development-Guide, https://freescout.net/module/chat/
- Confiança: documentado (polling); a frequência fica **A CONFIRMAR EM RUNTIME** (R-01).

**Notificações.** Aparecem no menu de notificações in-app e, quando cabe, como **push do navegador**. Push para celular só via módulo pago do app móvel. Também há módulos de notificação via Telegram, Slack, Rocket.Chat e SMS (catálogo).
- URLs: https://github.com/freescout-help-desk/freescout/wiki/Development-Guide, https://freescout.net/modules/
- Confiança: documentado.

**Colisão.** Quando um agente está respondendo, o ícone dele ganha uma borda destacada para que os outros vejam. Notas de versão mencionam um caminho de "visualização de conversa" no tempo real, o que indica que existe presença de quem está vendo.
- URL: https://github.com/freescout-help-desk/freescout/wiki/FAQ
- Confiança: documentado (indicador de resposta); inferido ("vendo"). **A CONFIRMAR EM RUNTIME** (R-02).

### 2.4 osTicket

**Colisão por bloqueio** (o modelo é trava, não presença):
- Uma configuração define quando o ticket fica bloqueado para outros: nunca, ao abrir, ou ao começar a agir (atividade).
- Uma duração máxima de bloqueio sem atividade solta a trava sozinha. O valor zero desliga o recurso.
- Tarefas seguem a mesma lógica.
- URLs: https://docs.osticket.com/en/latest/Admin/Settings/Tickets.html, https://docs.osticket.com/en/latest/Admin/Settings/System.html
- Confiança: documentado. O que o segundo agente vê (aviso? bloqueio total da resposta?) fica **A CONFIRMAR EM RUNTIME** (R-02).

**Atualização ao vivo e transporte:** não documentados. Inferido: a lista não atualiza sozinha, ou há recarga periódica.
- **A CONFIRMAR EM RUNTIME** (R-01).

**Notificações:** essencialmente por **e-mail** (ver a matriz de alertas na área 4). Não há notificação in-app nem push documentados.
- URL: https://docs.osticket.com/en/latest/Guides/Alerts%20Guide.html
- Confiança: documentado (e-mail); inferido (ausência de in-app). **A CONFIRMAR EM RUNTIME** (R-03).

### 2.5 Znuny

**Atualização de visões.** Existe uma preferência pessoal de **intervalo de recarga** das visões: desligado (padrão) ou de poucos minutos (2 a 15, segundo o material de referência legado). Isso vale para painel, visão por fila e visão de bloqueados. Inferido: **recarga periódica da página**, sem push.
- URLs: https://doc.znuny.org/znuny_lts/agentinterface/personalsettings/index.html, https://doc.znuny.org/legacy/manual/admin/6.0/en/html/ConfigReference_Section_Frontend_Agent_View_Preferences.html
- Confiança: documentado (preferência); inferido (transporte). **A CONFIRMAR EM RUNTIME** (R-01).

**Colisão.** Feita pelo **bloqueio**: abrir a tela de resposta bloqueia o ticket para quem a abriu, e tickets bloqueados ficam fora do conjunto livre (detalhes na área 4). Presença ou digitação não são documentadas.
- URL: https://doc.znuny.org/znuny/concepts/locking/index.html
- Confiança: documentado. **A CONFIRMAR EM RUNTIME** (R-02).

**Notificações.**
- Uma notificação pode ter três transportes: e-mail; web service, imediato ou agendado; e **atividade**, que é exibida dentro da interface do agente.
- O admin decide se cada notificação é opcional ou obrigatória.
- URL: https://doc.znuny.org/znuny-7_0/admin/automation/ticket_notification/index.html
- Confiança: documentado. Se a notificação de atividade chega sem recarregar a página fica **A CONFIRMAR EM RUNTIME** (R-03).

### 2.6 UVdesk

Nada documentado sobre atualização ao vivo, presença, colisão ou notificação in-app. Os workflows enviam e-mail a agentes.
- URL: https://docs.uvdesk.com/uvdemo/productivity/workflow.html
- Confiança: inferido (ausência). **A CONFIRMAR EM RUNTIME** (R-01..R-03).

### 2.7 Frappe Helpdesk

**Transporte do framework.** O framework Frappe tem um servidor **socket.io** separado. Os processos da aplicação publicam eventos num canal pub/sub do Redis, e o servidor de tempo real os retransmite aos clientes inscritos em "salas" (por usuário, por tipo de documento, por documento).
- URL: https://docs.frappe.io/framework/user/en/api/realtime
- Confiança: documentado (para o framework).

**No Helpdesk.**
- A página do marketplace promete notificações em tempo real de atribuições, respostas e menções.
- As páginas de documentação só descrevem **e-mails**: aos atribuídos quando o contato responde, e em menções em comentário interno.
- Num tópico do fórum oficial, com cerca de dois anos, um mantenedor admitia que o tempo real não estava bem implementado no Helpdesk e que era preciso recarregar a página. A informação pode estar desatualizada.
- Presença e colisão não são documentadas.
- URLs: https://docs.frappe.io/helpdesk/email-notifications, https://docs.frappe.io/helpdesk/lesson-2understanding-ticket-view, https://cloud.frappe.io/marketplace/apps/helpdesk
- Confiança: documentado (e-mail); inferido (tempo real parcial). **A CONFIRMAR EM RUNTIME** (R-01..R-03).

---

## 3. Tabela comparativa

| Aspecto | Zammad | Chatwoot (CE) | FreeScout | osTicket | Znuny | UVdesk | Frappe HD |
|---|---|---|---|---|---|---|---|
| Transporte | WebSocket (processo próprio + Redis) | WebSocket (token por usuário ou contato) | Polling AJAX | ? (nenhum documentado) | Recarga periódica opcional | ? | socket.io do framework (uso no HD: ?) |
| Listas ao vivo | provável (com limite de visões) | provável (eventos de conversa) | via polling | ? | recarga a cada N minutos (desligada por padrão) | ? | ? (relato antigo: não) |
| Colisão | presença por avatar (vendo, em outra aba, editando) + aviso de conflito | digitação do colega + dono visível | indicador "respondendo" | bloqueio ao abrir ou ao agir, com expiração | bloqueio ao abrir a resposta | ? | ? |
| Digitação | editando (lápis) | ✔ (agente e contato; distingue nota privada) | respondendo | — | — | — | — |
| Presença de agente | por ticket | online / ocupado / offline (sinal a cada ~30 s) | ? | — | — | — | ativo / ausente / indisponível (roteamento) |
| Notificação in-app | ✔ (contador, limpeza automática) | ✔ (caixa de notificações) | ✔ (menu) | — | ✔ (transporte "atividade") | — | ? |
| Push / área de trabalho | ? (inferido) | ✔ (navegador + app) | ✔ (navegador; celular pago) | — | — | — | ? |
| Som | ✔ (escolhível) | ✔ (desligado por padrão, com repetição) | ? | — | — | — | — |
| E-mail | ✔ | ✔ | ✔ | ✔ (principal) | ✔ | ✔ | ✔ (principal) |

---

## 4. Pontos A CONFIRMAR EM RUNTIME → cenários

| # | Dúvida | Projeto(s) | Cenário |
|---|---|---|---|
| 1 | Protocolo real (websocket, polling, SSE), formato da mensagem (evento com dados completos ou só "invalide e recarregue"?), latência entre agent2 atualizar e agent1 ver | todos | R-01 |
| 2 | A visão "sem dono" atualiza contador e lista sem recarregar? | Zammad, Chatwoot, FreeScout, Frappe | R-01 |
| 3 | Fallback quando o websocket cai (proxy sem upgrade): degrada para polling? Mostra erro? | Zammad, Chatwoot, Frappe | R-01 (variante) |
| 4 | Frequência do polling do FreeScout e custo por agente ocioso | FreeScout | R-01 |
| 5 | Dois agentes no mesmo ticket: o que cada um vê; o aviso de conflito do Zammad é disparado por quê; o bloqueio do osTicket e do Znuny bloqueia a resposta ou só avisa | Zammad, osTicket, Znuny, FreeScout, Chatwoot | R-02 |
| 6 | Digitação do Chatwoot entre agentes funciona na CE? | Chatwoot | R-02 |
| 7 | Ao ser atribuído: notificação in-app, push, som, e-mail; em quanto tempo | todos | R-03 |
| 8 | A notificação "atividade" do Znuny aparece sem recarregar a página? | Znuny | R-03 |
| 9 | Frappe: notificações in-app existem hoje na interface do Helpdesk? | Frappe | R-03 |

---

## 5. Recomendação preliminar para o MVP (simples e correto)

Para o MVP basta **atualização de listas, presença por ticket e notificação in-app de atribuição**. Chat, digitação de cliente e push móvel ficam no roadmap.

1. **Transporte: Server-Sent Events (SSE) com fallback de polling.**
   - O tráfego é praticamente só servidor → cliente. As ações do agente já passam pela API REST.
   - SSE funciona sobre HTTP comum, atravessa proxies com menos configuração que websocket e se reconecta sozinho, retomando a partir do último evento recebido.
   - O fallback é polling a cada 15 a 30 s no mesmo endpoint de "eventos desde o cursor X", que é o modelo FreeScout.
   - O websocket fica para o roadmap do chat, que é bidirecional e precisa de digitação.
   - Infra: no MVP, um pub/sub simples (Redis ou o próprio banco com notificações) entre as instâncias da aplicação, como Zammad e Frappe fazem com Redis.
2. **Formato dos eventos: "invalidação" e não "estado completo".**
   - O evento diz apenas *ticket X mudou (versão N)* ou *a lista do grupo G mudou*. O cliente busca o recurso na API REST, que aplica as permissões.
   - Isso evita vazar dados por um canal paralelo e é a lição dos dois tipos de token do Chatwoot: o canal de tempo real só pode entregar o que o usuário pode ver. O canal é autorizado por sessão e os eventos são filtrados por grupo.
3. **Colisão, em duas camadas:**
   - **Presença por ticket** (modelo Zammad): quem está vendo, quem está escrevendo resposta, com sinal de vida a cada cerca de 30 s e expiração em cerca de 60 s.
   - **Concorrência otimista no servidor:** toda atualização ou resposta leva a versão do ticket. Se outro agente publicou algo nesse meio-tempo, o servidor **não rejeita em silêncio**: devolve um conflito e o cliente mostra "chegou nova mensagem ou alteração; revise antes de enviar". Isso é correto mesmo sem tempo real.
   - **Não** adotar bloqueio exclusivo (osTicket e Znuny). Ele exige expiração, desbloqueio manual e tarefa agendada, e trava o trabalho quando alguém esquece a aba aberta.
4. **Notificações in-app:**
   - Tabela própria de notificações por usuário: atribuído a mim, resposta do cliente em ticket meu, ticket novo sem dono no meu grupo, menção.
   - Contador, marcar como lida e limpeza automática das lidas (modelo Zammad).
   - Entrega via o mesmo SSE. O e-mail é paralelo, segundo as preferências da área 4.
   - Push do navegador e som ficam no MVP+1. Reaproveitam o mesmo evento, só que exigem permissão do navegador.
5. **Presença global de agente** (online, ocupado, offline): só no roadmap, junto com round-robin sensível à disponibilidade e com o chat. Atenção à contradição do Chatwoot sobre ficar offline automaticamente: definir uma regra explícita, por exemplo "offline depois de N minutos sem sinal de vida de nenhuma aba".
