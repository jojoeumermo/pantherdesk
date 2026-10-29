<#
.SYNOPSIS
  Saves every message in a lab mailbox (raw .eml) as evidence, e.g. what a helpdesk sent to a customer.
.EXAMPLE
  ./fetch-mailbox.ps1 -Project zammad -Mailbox customer1@lab.test -Run r1
.NOTES
  GreenMail runs with auth disabled, so any password works. Messages stay on the server.
#>
param(
  [Parameter(Mandatory)][string]$Project,
  [Parameter(Mandatory)][string]$Mailbox,
  [Parameter(Mandatory)][string]$Run,
  [string]$ImapUrl = 'imap://127.0.0.1:3143'
)
$ErrorActionPreference = 'Stop'
$root = Resolve-Path "$PSScriptRoot/../.."
$outDir = "$root/observation/evidence/$Project/email-out/$Run/$Mailbox"
New-Item -ItemType Directory -Force $outDir | Out-Null

$search = curl.exe --silent --url "$ImapUrl/INBOX" --user "${Mailbox}:x" --request 'UID SEARCH ALL'
$uids = ($search -replace '.*SEARCH', '').Trim() -split '\s+' | Where-Object { $_ }
foreach ($uid in $uids) {
  $file = Join-Path $outDir ("{0:D4}.eml" -f [int]$uid)
  curl.exe --silent --url "$ImapUrl/INBOX;UID=$uid" --user "${Mailbox}:x" --output $file
}
"saved $($uids.Count) message(s) to $outDir"
