Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$opt  = Join-Path $root "assets\opt"

# ---------- crop founder2 (remove quote band at bottom) ----------
$srcImg = [System.Drawing.Image]::FromFile((Join-Path $opt "founder2.jpg"))
$millW = 900; $millH = 400
$mill = New-Object System.Drawing.Bitmap($millW, $millH)
$mg = [System.Drawing.Graphics]::FromImage($mill)
$mg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$mg.DrawImage($srcImg, (New-Object System.Drawing.Rectangle(0,0,$millW,$millH)), (New-Object System.Drawing.Rectangle(0,0,900,420)), [System.Drawing.GraphicsUnit]::Pixel)
$millJpg = Join-Path $opt "mill.jpg"
$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]80)
$mill.Save($millJpg, $enc, $ep)
$mg.Dispose(); $mill.Dispose(); $ep.Dispose()
Write-Output ("mill.jpg: {0}KB" -f [math]::Round((Get-Item $millJpg).Length/1KB))

# ---------- mill flip variant (distinct framing for factory step 5) ----------
$srcImg2 = [System.Drawing.Image]::FromFile((Join-Path $opt "founder2.jpg"))
$mill2 = New-Object System.Drawing.Bitmap(760, 348)
$mg2 = [System.Drawing.Graphics]::FromImage($mill2)
$mg2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$mtx = New-Object System.Drawing.Drawing2D.Matrix(-1, 0, 0, 1, 760, 0)
$mg2.Transform = $mtx
$mg2.DrawImage($srcImg2, (New-Object System.Drawing.Rectangle(0,0,760,348)), (New-Object System.Drawing.Rectangle(20,10,880,404)), [System.Drawing.GraphicsUnit]::Pixel)
$mg2.Transform = (New-Object System.Drawing.Drawing2D.Matrix)
$mill2Jpg = Join-Path $opt "mill2.jpg"
$ep2 = New-Object System.Drawing.Imaging.EncoderParameters(1)
$ep2.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]75)
$mill2.Save($mill2Jpg, $enc, $ep2)
$mg2.Dispose(); $mill2.Dispose(); $srcImg2.Dispose(); $ep2.Dispose()
Write-Output ("mill2.jpg: {0}KB" -f [math]::Round((Get-Item $mill2Jpg).Length/1KB))

function B64($name){
  $p = Join-Path $opt $name
  if(-not (Test-Path $p)){ throw "missing asset: $name" }
  $bytes = [IO.File]::ReadAllBytes($p)
  $ext = [IO.Path]::GetExtension($name).ToLower()
  $mime = switch($ext){ '.png' {'image/png'} '.jpg' {'image/jpeg'} '.jpeg' {'image/jpeg'} default { throw "bad ext $ext" } }
  return "data:$mime;base64," + [Convert]::ToBase64String($bytes)
}

# ---------- assemble html ----------
$head = [IO.File]::ReadAllText((Join-Path $root "src_css.html"))
$body = [IO.File]::ReadAllText((Join-Path $root "src_body.html"))
$js   = [IO.File]::ReadAllText((Join-Path $root "src_js.html"))

$html = $head + "`n" + $body + "`n" + $js

# ---------- IMG json ----------
$imgKeys = @{
  'badge' = 'badge.png'
  'logo' = 'logo.png'
  'p_ldpe' = 'LDPE1.jpg'; 'p_frp' = 'frp1.png'; 'p_pvc' = 'PVC1.png'; 'p_msgi' = 'MSGI1.png'
  'p_jkhigh' = 'jkhigh1.png'; 'p_jkextra' = 'jkextra1.png'; 'p_hdpe' = 'hdpe1.png'
  'p_flush' = 'flushtank1.jpg'; 'p_ptmt' = 'ptmtwhite1.jpg'
  'c_gcs' = 'GCS.jpg'; 'c_adani' = 'adani.png'; 'c_realty' = 'realty.png'; 'c_shahlon' = 'shahlon.png'; 'c_constructions' = 'constructions.png'
  'u1' = 'user1.png'; 'u2' = 'user2.png'
  'f_mill' = 'mill.jpg'; 'f_weld' = 'about9.jpg'
}
$jsonPairs = @()
foreach ($k in ($imgKeys.Keys | Sort-Object)) { $jsonPairs += ('  "' + $k + '": "' + (B64 $imgKeys[$k]) + '"') }
$imgJson = "{`n" + ($jsonPairs -join ",`n") + "`n}"

$html = $html.Replace('{{IMG_JSON}}', $imgJson)

# ---------- inline {{ASSET:x}} usage in markup ----------
$assetMap = @{
  'badge' = 'badge.png'; 'logo' = 'logo.png'
  'p_ldpe' = 'LDPE1.jpg'; 'p_frp' = 'frp1.png'; 'p_pvc' = 'PVC1.png'; 'p_msgi' = 'MSGI1.png'
  'p_jkhigh' = 'jkhigh1.png'; 'p_jkextra' = 'jkextra1.png'; 'p_hdpe' = 'hdpe1.png'
  'p_flush' = 'flushtank1.jpg'; 'p_ptmt' = 'ptmtwhite1.jpg'
  'c_gcs' = 'GCS.jpg'; 'c_adani' = 'adani.png'; 'c_realty' = 'realty.png'; 'c_shahlon' = 'shahlon.png'; 'c_constructions' = 'constructions.png'
  'u1' = 'user1.png'; 'u2' = 'user2.png'
  'f_mill' = 'mill.jpg'; 'f_weld' = 'about9.jpg'
}
foreach ($k in $assetMap.Keys) { $html = $html.Replace(('{{ASSET:' + $k + '}}'), (B64 $assetMap[$k])) }
# mark repeated big data-uri sources ( cloning done in JS )  — nothing needed

# leftover placeholder guard
if($html -match '\{\{(ASSET|IMG_){1}') { throw 'unreplaced placeholders remain!' }

$outPath = Join-Path $root "index.html"
[IO.File]::WriteAllText($outPath, $html, (New-Object System.Text.UTF8Encoding($false)))
$kb = [math]::Round((Get-Item $outPath).Length/1KB)
Write-Output "BUILD OK -> index.html ($kb KB)"
