param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Read-Utf8Text {
  param([string]$RelativePath)
  return [System.IO.File]::ReadAllText((Join-Path $projectRoot $RelativePath), [System.Text.Encoding]::UTF8)
}

function Assert-Contains {
  param([string]$Text, [string]$Expected, [string]$Name)
  if ($Text.Contains($Expected)) { Write-Output "PASS: $Name"; return }
  $failures.Add($Name)
  Write-Output "FAIL: $Name"
}

function Assert-Not-Matches {
  param([string]$Text, [string]$Pattern, [string]$Name)
  if ($Text -notmatch $Pattern) { Write-Output "PASS: $Name"; return }
  $failures.Add($Name)
  Write-Output "FAIL: $Name"
}

$theme = Read-Utf8Text 'entry/src/main/ets/common/Theme.ets'
$mainPage = Read-Utf8Text 'entry/src/main/ets/pages/MainPage.ets'
$appBackground = Read-Utf8Text 'entry/src/main/ets/components/AppBackground.ets'
$glassCard = Read-Utf8Text 'entry/src/main/ets/components/GlassCard.ets'
$waterProgress = Read-Utf8Text 'entry/src/main/ets/components/WaterWaveProgress.ets'
$dataManage = Read-Utf8Text 'entry/src/main/ets/pages/DataManagePage.ets'

Assert-Contains $theme 'cardRadius: 16' 'Cards use the restrained 16vp radius.'
Assert-Contains $theme 'bottomBarHeight: 64' 'The tab bar uses the compact 64vp content height.'
Assert-Contains $theme "primaryBlue: '#007AFF'" 'The default action color uses Apple system blue.'
Assert-Contains $theme "background: '#F2F2F7'" 'The light canvas uses a neutral grouped background.'
Assert-Contains $mainPage "sys.symbol.drop_fill" 'The water tab uses an SDK system symbol.'
Assert-Contains $mainPage "sys.symbol.wallet_fill" 'The ledger tab uses an SDK system symbol.'
Assert-Contains $mainPage "withAlpha(this.themeColors.card, 'F2')" 'The translucent tab surface uses ArkUI AARRGGBB ordering.'
Assert-Not-Matches $appBackground '\.blur\(' 'The application background has no decorative blur.'
Assert-Not-Matches $glassCard '\.shadow\(' 'Shared cards have no default shadow.'
Assert-Not-Matches $glassCard '\.border\(' 'Shared cards have no default border.'
Assert-Not-Matches $waterProgress '\bGauge\(' 'The water ring has no gauge pointer.'
$legacyDataIcons = @([char]0x2191, [char]0x232B, [char]0x25A3)
foreach ($icon in $legacyDataIcons) {
  Assert-Not-Matches $dataManage ([regex]::Escape("Text('$icon')")) 'Data management uses system symbols instead of text glyphs.'
}

$uiRoots = @(
  'entry/src/main/ets/pages',
  'entry/src/main/ets/components',
  'entry/src/main/ets/ledger/pages',
  'entry/src/main/ets/ledger/components'
)
$emojiPattern = '[\u2600-\u27BF]|[\uD83C-\uDBFF][\uDC00-\uDFFF]'
$emojiFiles = @()
$alphaSuffixFiles = @()
foreach ($root in $uiRoots) {
  $absoluteRoot = Join-Path $projectRoot $root
  $emojiFiles += Get-ChildItem -LiteralPath $absoluteRoot -Filter '*.ets' -File -Recurse | Where-Object {
    $_.Name -ne 'AppSymbol.ets' -and ([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) -match $emojiPattern)
  }
  $alphaSuffixFiles += Get-ChildItem -LiteralPath $absoluteRoot -Filter '*.ets' -File -Recurse | Where-Object {
    [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) -match "\+\s*'[0-9A-Fa-f]{2}'"
  }
}
if ($emojiFiles.Count -eq 0) {
  Write-Output 'PASS: Production UI files contain no hard-coded Emoji icons.'
} else {
  $failures.Add('Production UI files still contain hard-coded Emoji icons.')
  Write-Output "FAIL: Production UI files still contain hard-coded Emoji icons: $($emojiFiles.FullName -join ', ')"
}

if ($alphaSuffixFiles.Count -eq 0) {
  Write-Output 'PASS: Production UI colors use ArkUI AARRGGBB ordering.'
} else {
  $failures.Add('Production UI colors still append alpha after RGB.')
  Write-Output "FAIL: Production UI colors still append alpha after RGB: $($alphaSuffixFiles.FullName -join ', ')"
}

if ($failures.Count -gt 0) {
  Write-Error "Apple UI contract failed with $($failures.Count) issue(s)."
  exit 1
}

Write-Output 'Apple UI contract passed.'
