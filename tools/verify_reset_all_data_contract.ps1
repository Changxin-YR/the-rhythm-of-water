param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Read-Utf8Text {
  param([string]$RelativePath)
  [System.IO.File]::ReadAllText((Join-Path $projectRoot $RelativePath), [System.Text.Encoding]::UTF8)
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

$backupService = Read-Utf8Text 'entry/src/main/ets/services/BackupService.ets'
$databaseHelper = Read-Utf8Text 'entry/src/main/ets/ledger/services/DatabaseHelper.ets'
$dataManagePage = Read-Utf8Text 'entry/src/main/ets/pages/DataManagePage.ets'
$ledgerWarning = -join @(0x8D26, 0x5355, 0x3001, 0x9884, 0x7B97, 0x548C, 0x81EA, 0x5B9A, 0x4E49, 0x5206, 0x7C7B | ForEach-Object { [char]$_ })

Assert-Matches $backupService "import \{[^}]*DatabaseHelper[^}]*\} from '../ledger/services/DatabaseHelper'" 'The all-data reset service imports the ledger database helper.'
Assert-Matches $backupService 'await DatabaseHelper\.getInstance\(\)\.resetAll\(this\.context\)' 'The all-data reset flow resets ledger data.'
Assert-Matches $databaseHelper 'async resetAll\(context: Context\): Promise<void>' 'The ledger database exposes one reset operation.'
Assert-Matches $databaseHelper 'await store\.delete\(new relationalStore\.RdbPredicates\(Constants\.TABLE_BILL\)\)' 'Ledger reset deletes bill records through the supported API.'
Assert-Matches $databaseHelper 'await store\.delete\(new relationalStore\.RdbPredicates\(Constants\.TABLE_BUDGET\)\)' 'Ledger reset deletes budgets through the supported API.'
Assert-Matches $databaseHelper 'await store\.delete\(new relationalStore\.RdbPredicates\(Constants\.TABLE_CATEGORY\)\)' 'Ledger reset deletes custom categories through the supported API.'
Assert-Matches $databaseHelper 'await store\.delete\(new relationalStore\.RdbPredicates\(Constants\.TABLE_STREAK\)\)' 'Ledger reset deletes streak state through the supported API.'
Assert-Not-Matches $databaseHelper 'beginTrans\(|commit\(txId\)|rollback\(txId\)' 'Ledger reset avoids unsupported transaction APIs.'
Assert-Matches $databaseHelper 'await this\.insertDefaultCategories\(context\)' 'Ledger reset restores default categories.'
Assert-Matches $databaseHelper 'await store\.executeSql\(INSERT_EMPTY_STREAK\)' 'Ledger reset restores empty streak state.'
Assert-Matches $databaseHelper 'DataChangeNotifier\.notify\(LedgerDataChange\.BillChanged\)' 'Ledger reset refreshes bill-dependent views.'
Assert-Matches $databaseHelper 'DataChangeNotifier\.notify\(LedgerDataChange\.CategoryChanged\)' 'Ledger reset refreshes category-dependent views.'
Assert-Matches $dataManagePage $ledgerWarning 'The reset warning tells users that ledger data is deleted.'

if ($failures.Count -gt 0) {
  Write-Error "All-data reset contract failed with $($failures.Count) issue(s)."
  exit 1
}

Write-Output 'All-data reset contract passed.'
