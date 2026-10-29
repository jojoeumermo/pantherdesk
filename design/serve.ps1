# Minimal static file server for the design prototypes (localhost only).
# Usage: powershell -NoProfile -File design/serve.ps1 [-Port 5180] [-Root design/prototipo]
# The EARJ-branded variant stays local: -Root design/prototipo-earj
param([int]$Port = 5180, [string]$Root = (Join-Path $PSScriptRoot 'prototipo'))
$Root = (Resolve-Path $Root).Path
$types = @{ '.html'='text/html; charset=utf-8'; '.css'='text/css'; '.js'='text/javascript'; '.png'='image/png'; '.jpg'='image/jpeg'; '.svg'='image/svg+xml'; '.ttf'='font/ttf'; '.woff2'='font/woff2'; '.json'='application/json' }
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $Root at http://localhost:$Port/"
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
  if ($rel -eq '') { $rel = 'index.html' }
  $path = [System.IO.Path]::GetFullPath((Join-Path $Root $rel))
  if ($path.StartsWith($Root) -and (Test-Path $path -PathType Leaf)) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $ext = [System.IO.Path]::GetExtension($path).ToLower()
    $ctx.Response.ContentType = $(if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' })
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else { $ctx.Response.StatusCode = 404 }
  $ctx.Response.Close()
}
