# FaceScore - tiny local static server (no dependencies, no admin rights needed)
# Usage:  powershell -ExecutionPolicy Bypass -File serve.ps1 [-Port 8731]
param([int]$Port = 0, [switch]$NoOpen)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
if ([string]::IsNullOrEmpty($root)) { $root = (Get-Location).Path }
$rootFull = [System.IO.Path]::GetFullPath($root)

$ports = if ($Port -gt 0) { @($Port) } else { 8731..8780 }
$listener = $null
$chosen = 0
foreach ($p in $ports) {
  try {
    $cand = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $p)
    $cand.Start()
    $listener = $cand
    $chosen = $p
    break
  } catch { }
}
if (-not $listener) {
  Write-Host "[!] No free port in 8731-8780. Close some tools and retry." -ForegroundColor Red
  exit 1
}

$url = "http://127.0.0.1:$chosen/"
Write-Host ""
Write-Host "  FaceScore  is running" -ForegroundColor Cyan
Write-Host "  URL  : $url"
Write-Host "  Root : $rootFull"
Write-Host "  Keep this window open. Press Ctrl+C to stop."
Write-Host ""
if (-not $NoOpen) { try { Start-Process $url } catch { Write-Host "  (open $url manually)" } }

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.htm'  = 'text/html; charset=utf-8'
  '.js'   = 'text/javascript; charset=utf-8'
  '.mjs'  = 'text/javascript; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.map'  = 'application/json; charset=utf-8'
  '.wasm' = 'application/wasm'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.jpeg' = 'image/jpeg'
  '.webp' = 'image/webp'
  '.gif'  = 'image/gif'
  '.svg'  = 'image/svg+xml'
  '.ico'  = 'image/x-icon'
  '.woff2'= 'font/woff2'
  '.txt'  = 'text/plain; charset=utf-8'
  '.task' = 'application/octet-stream'
}

function Send-Text($stream, [string]$status, [string]$ctype, [string]$body) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
  $head = "HTTP/1.1 $status`r`nContent-Type: $ctype`r`nContent-Length: $($bytes.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
  $hb = [System.Text.Encoding]::ASCII.GetBytes($head)
  $stream.Write($hb, 0, $hb.Length)
  $stream.Write($bytes, 0, $bytes.Length)
}

while ($true) {
  $client = $null
  try {
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()
    $stream.ReadTimeout = 8000
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII, $false, 8192, $true)
    $line = $reader.ReadLine()
    if ([string]::IsNullOrEmpty($line)) { $client.Close(); continue }
    while ($true) {
      $h = $reader.ReadLine()
      if ([string]::IsNullOrEmpty($h)) { break }
    }
    $parts = $line.Split(' ')
    $method = $parts[0]
    $target = $parts[1]
    if ([string]::IsNullOrEmpty($target)) { $target = '/' }
    $path = $target.Split('?')[0]
    $path = [System.Uri]::UnescapeDataString($path)
    if ($path -eq '/' -or $path -eq '') { $path = '/index.html' }
    $rel = $path.TrimStart('/') -replace '/', [string][char]92
    $full = [System.IO.Path]::GetFullPath((Join-Path $rootFull $rel))
    if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
      Send-Text $stream '403 Forbidden' 'text/plain; charset=utf-8' 'Forbidden'
    } elseif (Test-Path -LiteralPath $full -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $ext = [System.IO.Path]::GetExtension($full).ToLowerInvariant()
      $ct = $mime[$ext]
      if (-not $ct) { $ct = 'application/octet-stream' }
      $head = "HTTP/1.1 200 OK`r`nContent-Type: $ct`r`nContent-Length: $($bytes.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
      $hb = [System.Text.Encoding]::ASCII.GetBytes($head)
      $stream.Write($hb, 0, $hb.Length)
      if ($method -ne 'HEAD') { $stream.Write($bytes, 0, $bytes.Length) }
    } else {
      Send-Text $stream '404 Not Found' 'text/plain; charset=utf-8' ('Not found: ' + $path)
    }
    $stream.Flush()
  } catch {
    Write-Host ("  [warn] " + $_.Exception.Message) -ForegroundColor DarkYellow
  } finally {
    if ($client) { try { $client.Close() } catch { } }
  }
}
