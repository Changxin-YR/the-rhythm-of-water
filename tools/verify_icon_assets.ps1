param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing

function Assert-PngSize {
  param([string]$RelativePath, [int]$Width, [int]$Height)
  $path = Join-Path $projectRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Missing icon asset: $RelativePath"
  }
  $image = [System.Drawing.Bitmap]::FromFile($path)
  try {
    if ($image.Width -ne $Width -or $image.Height -ne $Height) {
      throw "$RelativePath must be ${Width}x${Height}, found $($image.Width)x$($image.Height)."
    }
  }
  finally {
    $image.Dispose()
  }
}

$module = Get-Content -LiteralPath (Join-Path $projectRoot 'entry/src/main/module.json5') -Raw -Encoding UTF8 | ConvertFrom-Json
$entryAbility = @($module.module.abilities | Where-Object { $_.name -ceq 'EntryAbility' })
if ($entryAbility.Count -ne 1 -or $entryAbility[0].startWindowIcon -cne '$media:start_icon') {
  throw 'EntryAbility must reference the dedicated $media:start_icon startup asset.'
}

Assert-PngSize 'AppScope/resources/base/media/app_icon_background.png' 1024 1024
Assert-PngSize 'AppScope/resources/base/media/app_icon_foreground.png' 1024 1024
Assert-PngSize 'entry/src/main/resources/base/media/app_icon_background.png' 1024 1024
Assert-PngSize 'entry/src/main/resources/base/media/app_icon_foreground.png' 1024 1024
Assert-PngSize 'entry/src/main/resources/base/media/start_icon.png' 216 216

Write-Output 'WaterReminder icon asset contract passed.'
