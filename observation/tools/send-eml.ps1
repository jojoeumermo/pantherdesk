<#
.SYNOPSIS
  Injects one e-mail fixture into the lab SMTP server, filling in the placeholders.
.EXAMPLE
  ./send-eml.ps1 -Project zammad -Fixture 01 -Run r1
  ./send-eml.ps1 -Project zammad -Fixture 03 -Run r1 -Vars @{ REPLY_MSGID='<abc@zammad>'; REPLY_SUBJECT='[Ticket#10001] Printer...' }
.NOTES
  The filled-in copy is saved as evidence under observation/evidence/<project>/email-in/.
#>
param(
  [Parameter(Mandatory)][string]$Project,
  [Parameter(Mandatory)][string]$Fixture,
  [Parameter(Mandatory)][string]$Run,
  [hashtable]$Vars = @{},
  [string]$SmtpUrl = 'smtp://127.0.0.1:3025'
)
$ErrorActionPreference = 'Stop'
$root = Resolve-Path "$PSScriptRoot/../.."
$src = Get-ChildItem "$root/specs/fixtures/email" -Filter "$Fixture*.eml" | Select-Object -First 1
if (-not $src) { throw "Fixture $Fixture not found" }

$values = @{ SUPPORT = "support-$Project@lab.test"; RUN = $Run } + $Vars
$text = [IO.File]::ReadAllText($src.FullName)
foreach ($k in $values.Keys) { $text = $text.Replace("{{$k}}", [string]$values[$k]) }
if ($text -match '\{\{(\w+)\}\}') { throw "Unfilled placeholder {{$($Matches[1])}} in $($src.Name)" }

$outDir = "$root/observation/evidence/$Project/email-in"
New-Item -ItemType Directory -Force $outDir | Out-Null
$out = Join-Path $outDir "$Run-$($src.Name)"
[IO.File]::WriteAllText($out, $text)

$from = if ($text -match '(?m)^From:.*<([^>]+)>') { $Matches[1] } elseif ($text -match '(?m)^From:\s*(\S+@\S+)') { $Matches[1] }
curl.exe --silent --show-error --url $SmtpUrl --mail-from $from --mail-rcpt $values.SUPPORT --upload-file $out
if ($LASTEXITCODE -ne 0) { throw "SMTP delivery failed" }
"sent $($src.Name) -> $($values.SUPPORT) (saved $out)"
