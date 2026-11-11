Add-Type -AssemblyName System.Drawing

$raw   = Join-Path $PSScriptRoot "assets\raw"
$out   = Join-Path $PSScriptRoot "assets\opt"
New-Item -ItemType Directory -Force -Path $out | Out-Null

function Convert-Image($src, $dest, $maxDim, $isPng, $quality = 78) {
  $img = [System.Drawing.Image]::FromFile($src)
  $w = $img.Width; $h = $img.Height
  $scale = [math]::Min($maxDim / $w, $maxDim / $h)
  if ($scale -gt 1.0) { $scale = 1.0 }
  $nw = [int]($w * $scale); $nh = [int]($h * $scale)
  $bmp = New-Object System.Drawing.Bitmap($nw, $nh)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  if ($isPng) { $g.Clear([System.Drawing.Color]::Transparent) }
  $g.DrawImage($img, 0, 0, $nw, $nh)
  $g.Dispose(); $img.Dispose()
  if ($isPng) {
    $bmp.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
  } else {
    $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)
    $bmp.Save($dest, $enc, $ep)
  }
  $bmp.Dispose()
  $kb = [math]::Round((Get-Item $dest).Length / 1KB)
  Write-Output ("{0} -> {1} ({2}x{3}) {4}KB" -f (Split-Path $src -Leaf), (Split-Path $dest -Leaf), $nw, $nh, $kb)
}

# Transparent product PNGs -> 640px PNG
$pngProducts = @("frp1.png","PVC1.png","MSGI1.png","jkhigh1.png","jkextra1.png","hdpe1.png")
foreach ($p in $pngProducts) {
  Convert-Image (Join-Path $raw $p) (Join-Path $out $p) 720 $true
}

# JPG products -> 760px JPEG
$jpgProducts = @("LDPE1.jpg","sheet2.jpg","flushtank1.jpg","ptmtwhite1.jpg")
foreach ($p in $jpgProducts) {
  Convert-Image (Join-Path $raw $p) (Join-Path $out $p) 760 $false 80
}

# Logos
Convert-Image (Join-Path $raw "logo_logo.png") (Join-Path $out "logo.png") 420 $true
Convert-Image (Join-Path $raw "logo_logo1.png") (Join-Path $out "logo-lg.png") 900 $true
Convert-Image (Join-Path $raw "logo_footer-logo.png") (Join-Path $out "footer-logo.png") 420 $true

# Photos
Convert-Image (Join-Path $raw "founder2.jpg") (Join-Path $out "founder2.jpg") 900 $false 78
Convert-Image (Join-Path $raw "banner1.png") (Join-Path $out "banner1.jpg") 1600 $false 74
Convert-Image (Join-Path $raw "image-1.jpg") (Join-Path $out "image-1.jpg") 900 $false 76
Convert-Image (Join-Path $raw "about_9.jpg") (Join-Path $out "about9.jpg") 900 $false 76

# Client logos (resize small ones just in case)
Convert-Image (Join-Path $raw "GCS.jpg") (Join-Path $out "GCS.jpg") 360 $true
Convert-Image (Join-Path $raw "adani.png") (Join-Path $out "adani.png") 360 $true
Convert-Image (Join-Path $raw "realty.png") (Join-Path $out "realty.png") 360 $true
Convert-Image (Join-Path $raw "shahlon.png") (Join-Path $out "shahlon.png") 360 $true
Convert-Image (Join-Path $raw "constructions.png") (Join-Path $out "constructions.png") 360 $true
Convert-Image (Join-Path $raw "user1.png") (Join-Path $out "user1.png") 240 $true
Convert-Image (Join-Path $raw "user2.png") (Join-Path $out "user2.png") 240 $true
Convert-Image (Join-Path $raw "homeAbout.png") (Join-Path $out "homeAbout.png") 400 $true

Write-Output "ALL DONE"
