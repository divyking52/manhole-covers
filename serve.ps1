$root = "D:\divyanssh\manhole covers"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:3311/")
$listener.Start()
Write-Output "Serving $root on http://127.0.0.1:3311/"
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $path = $ctx.Request.Url.AbsolutePath
    if ($ctx.Request.HttpMethod -eq 'POST' -and $path -like '/save*') {
      $reader = New-Object System.IO.StreamReader($ctx.Request.InputStream, [System.Text.Encoding]::UTF8)
      $body = $reader.ReadToEnd() | Out-String
      $reader.Close()
      # body may be a data URI; strip prefix
      if ($body -match '^data:image/(png|jpeg|jpg|webp);base64,(.+)') {
        $type = $Matches[1]; $data = $Matches[2]
        $name = 'snapshot.' + ($(if ($type -eq 'jpeg') {'jpg'} else {$type}))
        $dest = Join-Path $root ("assets\gen\" + $name)
        [IO.File]::WriteAllBytes($dest, [Convert]::FromBase64String($data))
        $bts = [System.Text.Encoding]::UTF8.GetBytes("saved")
        $ctx.Response.ContentType = 'text/plain'
        $ctx.Response.OutputStream.Write($bts, 0, $bts.Length)
      } else { $ctx.Response.StatusCode = 400 }
    } else {
      if ($path -eq "/") { $path = "/index.html" }
      $file = Join-Path $root ($path -replace '/', '\')
      if (Test-Path $file -PathType Leaf) {
        $bytes = [IO.File]::ReadAllBytes($file)
        $ctx.Response.ContentType = "text/html; charset=utf-8"
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        $ctx.Response.StatusCode = 404
        $msg = [System.Text.Encoding]::UTF8.GetBytes("404")
        $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
      }
    }
    $ctx.Response.OutputStream.Close()
  } catch [System.Net.HttpListenerException] { }
}
