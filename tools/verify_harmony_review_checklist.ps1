param()

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$passes = [System.Collections.Generic.List[string]]::new()

function Add-CheckResult {
  param(
    [bool]$Condition,
    [string]$Success,
    [string]$Failure
  )

  if ($Condition) {
    $passes.Add($Success)
  } else {
    $failures.Add($Failure)
  }
}

function Read-Utf8Text {
  param([string]$RelativePath)
  return [System.IO.File]::ReadAllText((Join-Path $projectRoot $RelativePath), [System.Text.Encoding]::UTF8)
}

function ConvertFrom-CodePoints {
  param([int[]]$CodePoints)
  return -join @($CodePoints | ForEach-Object { [char]$_ })
}

$expectedAppName = ConvertFrom-CodePoints @(0x5143, 0x6C14, 0x6709, 0x6570)
$reminderNotEffectivePrefix = ConvertFrom-CodePoints @(0x63D0, 0x9192, 0x672A, 0x751F, 0x6548)
$savedPhrase = ConvertFrom-CodePoints @(0x5DF2, 0x4FDD, 0x5B58)

$appProfile = (Read-Utf8Text 'AppScope/app.json5') | ConvertFrom-Json
$moduleProfile = (Read-Utf8Text 'entry/src/main/module.json5') | ConvertFrom-Json
$appStrings = (Read-Utf8Text 'AppScope/resources/base/element/string.json') | ConvertFrom-Json
$appName = ($appStrings.string | Where-Object { $_.name -eq 'app_name' } | Select-Object -First 1).value

Add-CheckResult ($appName -eq $expectedAppName) 'The app name uses the reviewed distinctive label.' 'The app name is not the reviewed distinctive label.'
Add-CheckResult ($appProfile.app.icon -eq '$media:app_icon_layered') 'AppScope uses the layered app icon.' 'AppScope does not use $media:app_icon_layered.'
Add-CheckResult ($moduleProfile.module.abilities[0].icon -eq '$media:app_icon_layered') 'The UIAbility uses the same layered app icon.' 'The UIAbility icon differs from the AppScope layered icon.'
Add-CheckResult ($moduleProfile.module.abilities[0].label -eq '$string:app_name') 'The UIAbility reuses the app-name resource.' 'The UIAbility does not reuse $string:app_name.'

$iconPairs = @(
  @('AppScope/resources/base/media/app_icon_foreground.png', 'entry/src/main/resources/base/media/app_icon_foreground.png', 'foreground'),
  @('AppScope/resources/base/media/app_icon_background.png', 'entry/src/main/resources/base/media/app_icon_background.png', 'background')
)
foreach ($pair in $iconPairs) {
  $leftPath = Join-Path $projectRoot $pair[0]
  $rightPath = Join-Path $projectRoot $pair[1]
  $sameHash = (Test-Path $leftPath) -and (Test-Path $rightPath) -and
    ((Get-FileHash -Algorithm SHA256 $leftPath).Hash -eq (Get-FileHash -Algorithm SHA256 $rightPath).Hash)
  Add-CheckResult $sameHash "The $($pair[2]) icon layer is identical in AppScope and entry." "The $($pair[2]) icon layer differs between AppScope and entry."
}

$safeAreaRules = Read-Utf8Text 'entry/src/main/ets/common/SafeAreaRules.ets'
$mainPage = Read-Utf8Text 'entry/src/main/ets/pages/MainPage.ets'
$systemBarAppearance = Read-Utf8Text 'entry/src/main/ets/common/SystemBarAppearance.ets'
$systemBarService = Read-Utf8Text 'entry/src/main/ets/services/SystemBarService.ets'
Add-CheckResult ($safeAreaRules -match 'MIN_BOTTOM_CONTROL_CLEARANCE_VP:\s*number\s*=\s*28') 'Bottom controls keep at least 28vp navigation clearance.' 'The minimum bottom-control clearance is not 28vp.'
Add-CheckResult ($mainPage -match 'minimumBottomControlInsetVp\(this\.safeAreaBottom\)') 'The main navigation uses the shared bottom safe-area rule.' 'The main navigation does not use the shared bottom safe-area rule.'
Add-CheckResult ($systemBarAppearance -match 'useImmersiveLayout:\s*true') 'Immersive window layout is enabled.' 'Immersive window layout is disabled.'
Add-CheckResult (($systemBarService -match 'safeAreaTop') -and ($systemBarService -match 'safeAreaBottom')) 'Both top and bottom system safe areas are published.' 'The system-bar service does not publish both safe areas.'

$sourceRoot = Join-Path $projectRoot 'entry/src/main/ets'
$smallFontMatches = [System.Collections.Generic.List[string]]::new()
Get-ChildItem -Path $sourceRoot -Recurse -Filter '*.ets' | ForEach-Object {
  $sourceFile = $_.FullName
  $lineNumber = 0
  Get-Content -Encoding UTF8 $sourceFile | ForEach-Object {
    $lineNumber++
    $match = [regex]::Match($_, '\.fontSize\(\s*(\d+(?:\.\d+)?)\s*\)')
    if ($match.Success -and [double]$match.Groups[1].Value -lt 10) {
      $relativePath = $sourceFile.Substring($projectRoot.Length + 1)
      $smallFontMatches.Add("${relativePath}:$lineNumber -> $($match.Groups[1].Value)fp")
    }
  }
}
Add-CheckResult ($smallFontMatches.Count -eq 0) 'No production fontSize literal is below 10fp.' ("Font sizes below 10fp: " + ($smallFontMatches -join '; '))

$themeSource = Read-Utf8Text 'entry/src/main/ets/common/Theme.ets'
Add-CheckResult (($themeSource -match 'recommendedTouchTargetSize:\s*48') -and ($themeSource -match 'minimumTouchTargetSize:\s*40')) 'Shared UI tokens distinguish the 48vp recommendation from the 40vp mandatory minimum.' 'Shared 48vp/40vp interaction-target tokens are missing.'

$touchTargetContracts = @(
  @('entry/src/main/ets/components/SegmentedControl.ets', 1),
  @('entry/src/main/ets/components/AmountInputDialog.ets', 2),
  @('entry/src/main/ets/pages/WaterHubPage.ets', 2),
  @('entry/src/main/ets/pages/BeveragePage.ets', 4),
  @('entry/src/main/ets/pages/OnboardingPage.ets', 1),
  @('entry/src/main/ets/pages/ProfilePage.ets', 7),
  @('entry/src/main/ets/ledger/pages/LedgerCategoryManagePage.ets', 8)
)
foreach ($contract in $touchTargetContracts) {
  $relativePath = $contract[0]
  $minimumReferences = [int]$contract[1]
  $touchSource = Read-Utf8Text $relativePath
  $targetReferences = [regex]::Matches($touchSource, '\.(?:width|height)\(UiTokens\.(?:minimum|recommended)TouchTargetSize\)')
  $trackIsLargeEnough = $relativePath -ne 'entry/src/main/ets/components/SegmentedControl.ets' -or
    $touchSource -match '\.height\(UiTokens\.minimumTouchTargetSize\s*\+\s*4\)'
  Add-CheckResult (($targetReferences.Count -ge $minimumReferences) -and $trackIsLargeEnough) "$relativePath sizes its audited clickable containers with a compliant shared interaction target." "$relativePath does not size every audited clickable container with a compliant shared interaction target."
}

$notificationPermissionDeclared = @($moduleProfile.module.requestPermissions | Where-Object {
  $_.name -like 'ohos.permission.NOTIFICATION*'
}).Count -gt 0
$notificationApiPattern = '@kit\.NotificationKit|@ohos\.notification|notificationManager|reminderAgentManager|publishReminder'
$notificationImplementationFound = Get-ChildItem -Path $sourceRoot -Recurse -Filter '*.ets' | Where-Object {
  ([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)) -match $notificationApiPattern
} | Select-Object -First 1

if (-not $notificationPermissionDeclared -and $null -eq $notificationImplementationFound) {
  $passes.Add('Reminder and notification capability review is not applicable to this bundle.')
} else {
  Add-CheckResult ($notificationPermissionDeclared -and $null -ne $notificationImplementationFound) 'Reminder implementation and notification permission/configuration are both present.' 'Reminder implementation and notification permission/configuration are inconsistent.'
  $waterRules = Read-Utf8Text 'entry/src/main/ets/common/WaterReminderRules.ets'
  $capabilityMessageMatch = [regex]::Match($waterRules, "REMINDER_CAPABILITY_REQUIRED_MESSAGE:\s*string\s*=\s*'([^']*)'")
  $capabilityMessage = if ($capabilityMessageMatch.Success) { $capabilityMessageMatch.Groups[1].Value } else { '' }
  Add-CheckResult (($capabilityMessage.StartsWith($reminderNotEffectivePrefix)) -and -not $capabilityMessage.Contains($savedPhrase)) 'Missing reminder capability cannot be reported as effective or saved.' 'The missing-capability message can still report a false success.'
}

$responsiveUtils = Read-Utf8Text 'entry/src/main/ets/ledger/common/ResponsiveUtils.ets'
Add-CheckResult (($mainPage -match "\.width\('100%'\)") -and ($responsiveUtils -match "return '100%';")) 'Main and compact-ledger containers use the available width.' 'A main or compact-ledger container does not use the available width.'

$darkColors = (Read-Utf8Text 'entry/src/main/resources/dark/element/color.json') | ConvertFrom-Json
$darkColorNames = @($darkColors.color | ForEach-Object { $_.name })
$ledgerSource = Get-ChildItem -Path (Join-Path $sourceRoot 'ledger') -Recurse -Filter '*.ets' |
  ForEach-Object { [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) }
$allLedgerSource = $ledgerSource -join "`n"
$ledgerColorMatches = [regex]::Matches($allLedgerSource, 'app\.color\.(ledger_[a-zA-Z0-9_]+)')
$usedLedgerColors = @($ledgerColorMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
$darkOverrideExclusions = @('ledger_system_bar_transparent') + @($usedLedgerColors | Where-Object { $_ -like 'ledger_category_palette_*' })
$requiredDarkLedgerColors = @($usedLedgerColors | Where-Object { $_ -notin $darkOverrideExclusions })
$missingDarkLedgerColors = @($requiredDarkLedgerColors | Where-Object { $_ -notin $darkColorNames })
Add-CheckResult ($missingDarkLedgerColors.Count -eq 0) 'Every used ledger semantic color has a dark-mode override.' ("Ledger dark-mode colors missing: " + ($missingDarkLedgerColors -join ', '))

$foreignFeatureTerms = @(
  (ConvertFrom-CodePoints @(0x9ED8, 0x8BA4, 0x89C6, 0x56FE)),
  (ConvertFrom-CodePoints @(0x6DFB, 0x52A0, 0x4E8B, 0x4EF6)),
  (ConvertFrom-CodePoints @(0x8282, 0x5047, 0x65E5, 0x5FEB, 0x901F, 0x6DFB, 0x52A0)),
  (ConvertFrom-CodePoints @(0x5F00, 0x59CB, 0x4E13, 0x6CE8)),
  (ConvertFrom-CodePoints @(0x65F6, 0x949F, 0x663E, 0x793A)),
  (ConvertFrom-CodePoints @(0x767D, 0x566A, 0x97F3))
)
$allProductionSource = Get-ChildItem -Path $sourceRoot -Recurse -Filter '*.ets' |
  ForEach-Object { [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) }
$allProductionText = $allProductionSource -join "`n"
$foreignFeatureHits = @($foreignFeatureTerms | Where-Object { $allProductionText.Contains($_) })
Add-CheckResult ($foreignFeatureHits.Count -eq 0) 'Event/focus/clock/white-noise findings do not belong to this bundle.' 'Foreign feature terms were found and need manual review.'

foreach ($message in $passes) {
  Write-Output "PASS: $message"
}

if ($failures.Count -gt 0) {
  foreach ($message in $failures) {
    Write-Output "FAIL: $message"
  }
  Write-Error "HarmonyOS review audit failed with $($failures.Count) issue(s)."
  exit 1
}

Write-Output "HarmonyOS review audit passed ($($passes.Count) checks)."
