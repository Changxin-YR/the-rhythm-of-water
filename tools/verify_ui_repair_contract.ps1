param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Read-Utf8Text {
  param([string]$RelativePath)
  [System.IO.File]::ReadAllText((Join-Path $projectRoot $RelativePath), [System.Text.Encoding]::UTF8)
}

function Assert-Contains {
  param([string]$Text, [string]$Expected, [string]$Name)
  if ($Text.Contains($Expected)) {
    Write-Output "PASS: $Name"
  } else {
    $failures.Add($Name)
    Write-Output "FAIL: $Name"
  }
}

function Assert-Matches {
  param([string]$Text, [string]$Pattern, [string]$Name)
  if ($Text -match $Pattern) {
    Write-Output "PASS: $Name"
  } else {
    $failures.Add($Name)
    Write-Output "FAIL: $Name"
  }
}

function Assert-Not-Matches {
  param([string]$Text, [string]$Pattern, [string]$Name)
  if ($Text -notmatch $Pattern) {
    Write-Output "PASS: $Name"
  } else {
    $failures.Add($Name)
    Write-Output "FAIL: $Name"
  }
}

function ConvertFrom-CodePoints {
  param([int[]]$CodePoints)
  return -join @($CodePoints | ForEach-Object { [char]$_ })
}

$pages = Read-Utf8Text 'entry/src/main/resources/base/profile/main_pages.json'
Assert-Contains $pages 'pages/StatsPage' 'The statistics page is registered for router navigation.'
Assert-Contains $pages 'pages/AchievementPage' 'The achievement page is registered for router navigation.'
if ($pages.Contains('pages/SettingsPage')) {
  $failures.Add('The embedded settings tab is incorrectly registered as a routed page.')
  Write-Output 'FAIL: The embedded settings tab is incorrectly registered as a routed page.'
} else {
  Write-Output 'PASS: The embedded settings tab is not registered as a routed page.'
}

$statsPage = Read-Utf8Text 'entry/src/main/ets/pages/StatsPage.ets'
$achievementPage = Read-Utf8Text 'entry/src/main/ets/pages/AchievementPage.ets'
$settingsPage = Read-Utf8Text 'entry/src/main/ets/pages/SettingsPage.ets'
Assert-Contains $statsPage '@Entry' 'The registered statistics page is a router entry.'
Assert-Contains $achievementPage '@Entry' 'The registered achievement page is a router entry.'
Assert-Not-Matches $statsPage '@Entry\s+@Component\s+export struct' 'The statistics entry avoids the unsupported exported-entry preview form.'
Assert-Not-Matches $achievementPage '@Entry\s+@Component\s+export struct' 'The achievement entry avoids the unsupported exported-entry preview form.'
if ($settingsPage.Contains('@Entry')) {
  $failures.Add('The embedded settings tab is incorrectly declared as a router entry.')
  Write-Output 'FAIL: The embedded settings tab is incorrectly declared as a router entry.'
} else {
  Write-Output 'PASS: The embedded settings tab is not declared as a router entry.'
}
if ($achievementPage.Contains('@Prop')) {
  $failures.Add('The routed achievement page still declares an unsupported @Prop.')
  Write-Output 'FAIL: The routed achievement page still declares an unsupported @Prop.'
} else {
  Write-Output 'PASS: The routed achievement page has no unsupported @Prop.'
}
Assert-Contains $statsPage 'SystemSafeAreaBackground' 'The statistics page paints the system safe area.'
Assert-Contains $statsPage 'PageHeader({' 'The statistics page provides a standard page header.'
Assert-Contains $statsPage 'onBack: () => { router.back() }' 'The statistics page has a return action.'
Assert-Contains $achievementPage 'SystemSafeAreaBackground' 'The achievement page paints the system safe area.'
Assert-Contains $achievementPage 'PageHeader({' 'The achievement page provides a standard page header.'
Assert-Contains $achievementPage 'onBack: () => { router.back() }' 'The achievement page has a return action.'

$overviewPage = Read-Utf8Text 'entry/src/main/ets/pages/OverviewPage.ets'
$mainPage = Read-Utf8Text 'entry/src/main/ets/pages/MainPage.ets'
Assert-Contains $overviewPage 'onOpenSettings: () => void' 'The overview accepts a settings-tab action.'
Assert-Contains $overviewPage 'this.options.onOpenSettings()' 'The overview opens settings through the main-tab action.'
if ($overviewPage.Contains("router.pushUrl({ url: 'pages/SettingsPage' })")) {
  $failures.Add('The overview gear still routes to the embedded settings tab.')
  Write-Output 'FAIL: The overview gear still routes to the embedded settings tab.'
} else {
  Write-Output 'PASS: The overview gear does not route to the embedded settings tab.'
}
Assert-Contains $mainPage 'onOpenSettings: () => { this.currentIndex = 3 }' 'The main page switches to settings for the overview gear.'

$budgetPage = Read-Utf8Text 'entry/src/main/ets/ledger/pages/LedgerBudgetPage.ets'
Assert-Matches $budgetPage "\.fontColor\(ledgerColor\('ledger_ink'\)\)\s+\.placeholderColor\(ledgerColor\('ledger_text_secondary'\)\)" 'The budget input explicitly uses readable text and placeholder colors.'
Assert-Contains $budgetPage "ctx.font = 'bold 48px sans-serif';" 'The budget percentage uses an enlarged canvas font size.'
Assert-Contains $budgetPage "ctx.font = '22px sans-serif';" 'The budget caption uses an enlarged canvas font size.'

$categoryPage = Read-Utf8Text 'entry/src/main/ets/ledger/pages/LedgerCategoryManagePage.ets'
Assert-Matches $categoryPage "\.fontColor\(ledgerColor\('ledger_ink'\)\)\s+\.placeholderColor\(ledgerColor\('ledger_text_secondary'\)\)" 'The category input explicitly uses readable text and placeholder colors.'

$protocolPage = Read-Utf8Text 'entry/src/main/ets/pages/ProtocolPage.ets'
$userAgreement = ConvertFrom-CodePoints @(0x7528, 0x6237, 0x534F, 0x8BAE)
$serviceContent = ConvertFrom-CodePoints @(0x4E00, 0x3001, 0x670D, 0x52A1, 0x5185, 0x5BB9)
$agreementChanges = ConvertFrom-CodePoints @(0x534F, 0x8BAE, 0x53D8, 0x66F4)
Assert-Contains $protocolPage "@StorageProp('safeAreaTop')" 'The user agreement observes the top system safe area.'
Assert-Contains $protocolPage "Text('$userAgreement')" 'The page is explicitly titled User Agreement.'
Assert-Contains $protocolPage "this.ProtocolCard('$serviceContent'" 'The agreement documents actual application services.'
Assert-Matches $protocolPage "this\.ProtocolCard\('[^']*$agreementChanges'" 'The agreement includes its change policy without requiring a fixed chapter number.'
Assert-Not-Matches $protocolPage '@Entry\s+@Component\s+export struct' 'The agreement entry avoids the unsupported exported-entry preview form.'
if ($protocolPage.Contains('JiZhangBen')) {
  $failures.Add('The agreement still contains the legacy JiZhangBen import wording.')
  Write-Output 'FAIL: The agreement still contains the legacy JiZhangBen import wording.'
} else {
  Write-Output 'PASS: The agreement no longer contains legacy import wording.'
}

$homePage = Read-Utf8Text 'entry/src/main/ets/pages/HomePage.ets'
$undoStart = $homePage.IndexOf('if (this.showUndoBar && this.undoRecord)')
$undoEnd = if ($undoStart -ge 0) { $homePage.IndexOf('.transition(', $undoStart) } else { -1 }
$undoBlock = if ($undoStart -ge 0 -and $undoEnd -gt $undoStart) { $homePage.Substring($undoStart, $undoEnd - $undoStart) } else { '' }
Assert-Contains $undoBlock '.fontColor(this.themeColors.textPrimary)' 'The undo message uses a readable semantic text color.'
Assert-Contains $undoBlock '.fontColor(this.themeColors.primaryText)' 'The undo action uses a readable semantic action color.'
Assert-Contains $undoBlock '.zIndex(1)' 'The undo bar is rendered above scrollable drinking content.'

if ($failures.Count -gt 0) {
  Write-Error "UI repair contract failed with $($failures.Count) issue(s)."
  exit 1
}

Write-Output 'UI repair contract passed.'
