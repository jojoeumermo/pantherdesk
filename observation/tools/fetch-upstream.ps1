<#
.SYNOPSIS
  Downloads the pinned upstream files that some lab projects build from or extend.
  Only deployment files are fetched (compose file, Dockerfile build context); they are
  kept under observation/ and never copied into specs/ or the PantherDesk code.
#>
$ErrorActionPreference = 'Stop'
$p = Resolve-Path "$PSScriptRoot/../projects"

# Zammad: official compose file, extended by projects/zammad/compose.override.yml
New-Item -ItemType Directory -Force "$p/zammad/upstream" | Out-Null
Invoke-WebRequest 'https://raw.githubusercontent.com/zammad/zammad-docker-compose/v17.5.3/docker-compose.yml' `
  -OutFile "$p/zammad/upstream/docker-compose.yml" -UseBasicParsing

# UVdesk: official community-skeleton source, built with its own Dockerfile
$zip = Join-Path $env:TEMP 'uvdesk-v1.1.8.zip'
Invoke-WebRequest 'https://github.com/uvdesk/community-skeleton/archive/refs/tags/v1.1.8.zip' -OutFile $zip -UseBasicParsing
if (Test-Path "$p/uvdesk/upstream") { Remove-Item -Recurse -Force "$p/uvdesk/upstream" }
Expand-Archive $zip -DestinationPath "$p/uvdesk/_x" -Force
Move-Item "$p/uvdesk/_x/community-skeleton-1.1.8" "$p/uvdesk/upstream"
Remove-Item -Recurse -Force "$p/uvdesk/_x", $zip
"upstream files ready"
