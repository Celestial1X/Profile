$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add('http://localhost:8080/')
$listener.Start()
Start-Process 'http://localhost:8080/profile%20(2).html'
Write-Host 'Profile server running at http://localhost:8080/profile%20(2).html'
Write-Host 'Keep this window open while listening to music. Press Ctrl+C to stop.'

while ($listener.IsListening) {
  $context = $listener.GetContext()
  $relative = [uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
  if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'profile (2).html' }
  $path = [System.IO.Path]::GetFullPath((Join-Path $root $relative))
  if (-not $path.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $context.Response.StatusCode = 404
    $context.Response.Close()
    continue
  }
  $types = @{ '.html'='text/html; charset=utf-8'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.png'='image/png'; '.webp'='image/webp'; '.css'='text/css; charset=utf-8'; '.js'='application/javascript; charset=utf-8' }
  $ext = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
  $context.Response.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { 'application/octet-stream' }
  $bytes = [System.IO.File]::ReadAllBytes($path)
  $context.Response.ContentLength64 = $bytes.Length
  $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $context.Response.Close()
}
