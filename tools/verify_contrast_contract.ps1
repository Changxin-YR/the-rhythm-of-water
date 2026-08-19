$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$failures = New-Object System.Collections.Generic.List[string]

function Get-Source {
  param([string]$RelativePath)
  $path = Join-Path $projectRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path)) {
    $failures.Add("Missing file: $RelativePath")
    return ''
  }
  return Get-Content -Encoding UTF8 -Raw -LiteralPath $path
}

function ConvertTo-LinearSrgb {
  param([int]$Channel)
  $value = $Channel / 255.0
  if ($value -le 0.04045) { return $value / 12.92 }
  return [Math]::Pow(($value + 0.055) / 1.055, 2.4)
}

function Get-Contrast {
  param([string]$Foreground, [string]$Background)
  $luminance = {
    param([string]$Color)
    $r = ConvertTo-LinearSrgb ([Convert]::ToInt32($Color.Substring(1, 2), 16))
    $g = ConvertTo-LinearSrgb ([Convert]::ToInt32($Color.Substring(3, 2), 16))
    $b = ConvertTo-LinearSrgb ([Convert]::ToInt32($Color.Substring(5, 2), 16))
    return 0.2126 * $r + 0.7152 * $g + 0.0722 * $b
  }
  $first = & $luminance $Foreground
  $second = & $luminance $Background
  return ([Math]::Max($first, $second) + 0.05) / ([Math]::Min($first, $second) + 0.05)
}

function Assert-Contains {
  param([string]$Content, [string]$Label, [string]$Pattern)
  if ($Content -notmatch $Pattern) { $failures.Add("$Label is missing: $Pattern") }
}

$theme = Get-Source 'entry/src/main/ets/common/Theme.ets'
$themeExpectations = @{
  blue = '#0066CC'
  green = '#1E6F32'
  purple = '#6A1B9A'
  orange = '#7A3C00'
  pink = '#880E4F'
  teal = '#00665B'
}
foreach ($name in $themeExpectations.Keys) {
  Assert-Contains $theme "Theme.ets $name primaryText" "case '$name'.*primaryText: isDark \? '[^']+' : '$([regex]::Escape($themeExpectations[$name]))'"
}

foreach ($foreground in $themeExpectations.Values) {
  foreach ($background in @('#E5F2FF', '#E8F6EC', '#E9E9EE')) {
    if ((Get-Contrast $foreground $background) -le 4.5) {
      $failures.Add("$foreground does not exceed 4.5:1 on $background")
    }
  }
}

$contrast = Get-Source 'entry/src/main/ets/common/ColorContrast.ets'
Assert-Contains $contrast 'ColorContrast.ets' '\{6\}.*\{8\}'
Assert-Contains $contrast 'ColorContrast.ets' 'composite'
Assert-Contains $contrast 'ColorContrast.ets' 'contrastRatioOverSurface'
Assert-Contains $contrast 'ColorContrast.ets' 'hasMinimumIconOrTitleContrast'

$rules = Get-Source 'entry/src/ohosTest/ets/test/WaterReminderRules.test.ets'
foreach ($surface in @('selectedSurface', 'positiveSurface', 'surface', 'input')) {
  Assert-Contains $rules 'WaterReminderRules.test.ets' $surface
}

$dataManage = Get-Source 'entry/src/main/ets/pages/DataManagePage.ets'
if ($dataManage.Contains('.backgroundColor(this.themeColors.success)')) {
  $failures.Add('DataManagePage must not place body-sized white text on the semantic success color.')
}

$stats = Get-Source 'entry/src/main/ets/ledger/pages/LedgerStatisticsPage.ets'
if ($stats.Contains("`$r('app.color.ledger_primary_color')")) {
  $failures.Add('LedgerStatisticsPage must resolve its month-navigation color through LedgerTheme.')
}

$ledgerTheme = Get-Source 'entry/src/main/ets/ledger/common/LedgerTheme.ets'
Assert-Contains $ledgerTheme 'LedgerTheme.ets ledger_primary_color' "case 'ledger_primary_color': return dark \? '#0A84FF' : '#007AFF'"

$baseColors = Get-Source 'entry/src/main/resources/base/element/color.json'
$resourceExpectations = @{
  ledger_income_green = '#217D37'
  ledger_expense_red = '#D70015'
  ledger_tab_inactive = '#5C5C63'
  ledger_streak_gold = '#8A4B00'
  ledger_muted = '#5C5C63'
  ledger_accent = '#30B0C7'
}
foreach ($name in $resourceExpectations.Keys) {
  $pattern = '(?s)"name"\s*:\s*"' + [regex]::Escape($name) + '".*?"value"\s*:\s*"' + [regex]::Escape($resourceExpectations[$name]) + '"'
  if ($baseColors -notmatch $pattern) { $failures.Add("base color resource $name is not synchronized") }
}

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Host "[FAIL] $_" -ForegroundColor Red }
  throw "Contrast contract failed with $($failures.Count) issue(s)."
}

Write-Host 'Contrast contract passed.' -ForegroundColor Green
