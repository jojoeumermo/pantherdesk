# Ambiente de observação (Fase 1)

Laboratório local para **observar o comportamento** dos 7 helpdesks open source
com o REA, sem copiar código. Licenças e restrições: [`../specs/LICENSES.md`](../specs/LICENSES.md).
Cenários a executar: [`scenarios.md`](scenarios.md).

> **Alvos autorizados:** só as instâncias locais deste laboratório e a
> documentação pública (inclusive a da API do Zendesk, só leitura). **Nunca**
> apontar o REA ou qualquer captura para o Zendesk nem para hosts externos.

## Arquitetura do laboratório

```
 navegador / REA (host)                    rede "lab" (internal: sem internet)
 ────────────────────────                  ──────────────────────────────────────
 127.0.0.1:8101..8107 ──► proxy (Caddy) ──► zammad / chatwoot / freescout / osticket
                                             znuny / uvdesk / frappe
 127.0.0.1:3025 SMTP  ──► mail (GreenMail) ◄── SMTP de saída e IMAP de entrada dos helpdesks
 127.0.0.1:3143 IMAP
 127.0.0.1:8090       ──► webhook-sink    ◄── webhooks dos helpdesks
```

- Os helpdesks só entram na rede `obslab_lab`, que é `internal: true`: sem
  telemetria, sem e-mail real saindo, sem chamadas externas.
- Só o proxy, o servidor de e-mail e o webhook-sink têm portas no host, e
  todas em `127.0.0.1`.
- Tudo que exige internet (baixar releases, `composer`, `bench get-app`)
  acontece no **build** da imagem, nunca em tempo de execução.
- Relógio em UTC em todos os containers (SLAs reproduzíveis).

| Projeto | URL | Pasta |
|---|---|---|
| Zammad | http://127.0.0.1:8101 | `projects/zammad` |
| Chatwoot (CE) | http://127.0.0.1:8102 | `projects/chatwoot` |
| FreeScout | http://127.0.0.1:8103 | `projects/freescout` |
| osTicket | http://127.0.0.1:8104 | `projects/osticket` |
| Znuny | http://127.0.0.1:8105/otrs/installer.pl | `projects/znuny` |
| UVdesk | http://127.0.0.1:8106 | `projects/uvdesk` |
| Frappe Helpdesk | http://127.0.0.1:8107/helpdesk | `projects/frappe-helpdesk` |
| GreenMail (API/UI) | http://127.0.0.1:8089 | `lab` |

## 1. Pré-requisitos

- Windows 11 com **Docker Desktop** (backend WSL2), Compose v2.24 ou mais novo
  (o override do Zammad usa `!reset`). Em Docker Desktop → Settings →
  Resources, reserve **pelo menos 8 GB** de RAM para o WSL.
- 16 GB de RAM no host: rode **um projeto por vez**, junto com o `lab`.
  Zammad (com Elasticsearch) e Frappe são os mais pesados (~3–4 GB).
- ~30 GB livres em disco para imagens e builds.
- Chrome instalado (o REA usa no modo `launch`):
  `C:\Program Files\Google\Chrome\Application\chrome.exe`.
- REA registrado no Claude Code; diagnóstico:
  `npx -y rea-agents@6.7.0 doctor --client claude_code --json`
  (resultado de 2026-10-26: registro alinhado, Ghidra/JDK ok; Hopper/IDA/JADX
  ausentes e desnecessários para este projeto).

## 2. Subir o laboratório

Todos os comandos partem da raiz do repositório.

```powershell
# Uma vez: baixa os arquivos de deploy oficiais fixados (compose do Zammad, fonte do UVdesk)
./observation/tools/fetch-upstream.ps1

# Infra compartilhada
docker compose -f observation/lab/compose.yml up -d

# Conferir o isolamento: precisa FALHAR (sem rota para a internet)
docker run --rm --network obslab_lab alpine:3.22 wget -q -T 5 -O- http://example.com
```

## 3. Subir cada projeto

Um por vez. Para trocar: `docker compose ... stop` no atual antes do próximo.
Os volumes preservam o estado entre paradas; `down -v` zera a instância.

### Zammad
```powershell
docker compose -p obs-zammad -f observation/projects/zammad/upstream/docker-compose.yml -f observation/projects/zammad/compose.override.yml up -d
```
Primeiro acesso: assistente de configuração em http://127.0.0.1:8101 → criar
admin@lab.test. Canal de e-mail: IMAP `mail.lab.test:3143` sem SSL, usuário
`support-zammad@lab.test`, qualquer senha; SMTP `mail.lab.test:3025` sem SSL.

### Chatwoot (community edition)
```powershell
docker compose -f observation/projects/chatwoot/compose.yml up -d postgres redis
docker compose -f observation/projects/chatwoot/compose.yml run --rm prepare
docker compose -f observation/projects/chatwoot/compose.yml up -d rails sidekiq
```
Primeiro acesso cria o super admin. Inbox de e-mail: IMAP `mail.lab.test:3143`
e SMTP `mail.lab.test:3025`, endereço `support-chatwoot@lab.test`.

### FreeScout
```powershell
docker compose -f observation/projects/freescout/compose.yml up -d --build
```
Instalador web: banco `db` / `freescout` / `obs-lab-only`. Mailbox
`support-freescout@lab.test`: recebimento IMAP `mail.lab.test:3143`, envio SMTP
`mail.lab.test:3025`.

### osTicket
```powershell
docker compose -f observation/projects/osticket/compose.yml up -d --build
```
Instalador em http://127.0.0.1:8104/setup/: MySQL `db` / `osticket` /
`obs-lab-only`. Depois da instalação, remover a pasta de setup:
`docker compose -f observation/projects/osticket/compose.yml exec web rm -rf /var/www/html/setup`.
E-mail: Admin → Emails → `support-osticket@lab.test`, IMAP + SMTP no `mail.lab.test`.
O container `cron` roda as tarefas periódicas a cada minuto.

### Znuny
```powershell
docker compose -f observation/projects/znuny/compose.yml up -d --build web db
```
Conferir no log de build o relatório de módulos Perl. Instalador:
http://127.0.0.1:8105/otrs/installer.pl, banco MySQL host `db`, root
`obs-lab-only`. Terminada a instalação, ligar o daemon (busca de e-mail,
escalonamentos):
```powershell
docker compose -f observation/projects/znuny/compose.yml --profile after-install up -d daemon
```
Conta de e-mail: Admin → PostMaster Mail Accounts, IMAP `mail.lab.test:3143`,
`support-znuny@lab.test`.

### UVdesk
```powershell
docker compose -f observation/projects/uvdesk/compose.yml up -d --build
```
Instalador em http://127.0.0.1:8106: banco `localhost` / `uvdesk` /
`obs-lab-only` (o MySQL roda dentro do container). Criar o mailbox
`support-uvdesk@lab.test` (IMAP + SMTP no `mail.lab.test`); o próprio container
faz o polling a cada minuto.

### Frappe Helpdesk
```powershell
docker compose -f observation/projects/frappe-helpdesk/compose.yml up -d --build
```
O build demora (instala o bench e os apps). Na primeira execução o container
cria o site `helpdesk.localhost` (Administrator / `admin`). Acessar
http://127.0.0.1:8107/helpdesk. E-mail: Email Account com IMAP/SMTP no
`mail.lab.test`, endereço `support-frappe@lab.test`.

## 4. Coletar evidências

Layout: `observation/evidence/<projeto>/<cenário>/<rodada>/` com `manifest.md`
(modelo em `scenarios.md`).

### E-mail (cenários E-*)
```powershell
# Injetar fixture
./observation/tools/send-eml.ps1 -Project zammad -Fixture 01 -Run r1
# Coletar o que o helpdesk mandou para o cliente (cabeçalhos de threading)
./observation/tools/fetch-mailbox.ps1 -Project zammad -Mailbox customer1@lab.test -Run r1
# Responder ao e-mail do agente
./observation/tools/send-eml.ps1 -Project zammad -Fixture 03 -Run r1 -Vars @{ REPLY_MSGID='<...>'; REPLY_SUBJECT='...' }
```
Fixtures documentadas em `specs/fixtures/email/README.md`.

### Navegador e rede com o REA (cenários de UI)
O agente usa `capture_browser_scenario` no modo `launch` com o Chrome local,
`start_url` = URL do projeto e as ações declaradas do cenário (login, clicar,
preencher). Captura recomendada:

- `capture.events`: `["network", "websockets", "console", "page-errors"]`
- `capture.network`: `request_body`, `response_body` e `header_values` = `true`
- `capture.after_each_step`: `["url", "screenshot"]`
- senhas sempre via `secrets` (variável de ambiente), nunca literais

Depois, `export_evidence_bundle` grava a Evidence em
`evidence/<projeto>/<cenário>/<rodada>/rea-bundle.json`, e o ID da Evidence vai
para o manifesto.

Para um fluxo feito à mão (por exemplo, o assistente de instalação), exportar
um HAR no DevTools do Chrome e inspecionar com `inspect_web_network_capture`
(`format: "har"`, `detail: "summary"`).

### API e estado do ticket
Depois de cada passo, salvar o JSON do ticket pela API do próprio projeto em
`state-<passo>.json` (as credenciais de API do laboratório ficam em variáveis
de ambiente, fora do repositório).

### Webhooks
Tudo o que chega em `http://hooks.lab.test:8090/...` é gravado em
`observation/evidence/_webhooks/requests.jsonl`. `/status/<código>` e
`/slow/<ms>` simulam falha e lentidão (cenários API-03 e API-04).

## 5. Regras clean room durante a coleta

1. `observation/evidence/` pode conter textos de interface e dados dos
   projetos e **nunca vai para a Fase 2**.
2. Os manifestos descrevem o comportamento com palavras próprias.
3. As specs citam evidência só pela referência (`zammad/E-04/r1`), sem
   reproduzir o conteúdo.
4. Leitura de código-fonte só para entender a intenção de uma regra, e nunca
   no diretório enterprise do Chatwoot.

## 6. Desligar e limpar

```powershell
docker compose -f observation/projects/<projeto>/compose.yml down        # mantém dados
docker compose -f observation/projects/<projeto>/compose.yml down -v     # apaga a instância
docker compose -f observation/lab/compose.yml down
```

## Estado deste ambiente

- 2026-10-26: arquivos escritos. Imagens, tags e URLs de download conferidos
  (todos existem). **Ainda não executado**: o Docker não estava instalado na
  máquina. Ajustes que aparecerem na primeira subida serão registrados aqui.
