$pagesPath = Join-Path $PSScriptRoot '..\entry\src\main\ets\pages'
$failures = @()
$checked = 0

Get-ChildItem -LiteralPath $pagesPath -Filter '*.ets' | ForEach-Object {
  $source = Get-Content -Raw -LiteralPath $_.FullName
  $scrollCount = ([regex]::Matches($source, 'Scroll\(\)\s*\{')).Count
  if ($scrollCount -eq 0) {
    return
  }

  $checked += $scrollCount
  $minHeightCount = ([regex]::Matches(
      $source,
      "\.constraintSize\(\{ minHeight: '100%' \}\)"
    )).Count
  $startAlignmentCount = ([regex]::Matches(
      $source,
      '\.justifyContent\(FlexAlign\.Start\)'
    )).Count

  if ($minHeightCount -lt $scrollCount -or $startAlignmentCount -lt $scrollCount) {
    $failures += "$(($_.Name)): Scroll=$scrollCount, minHeight=$minHeightCount, startAlignment=$startAlignmentCount"
  }
}

if ($failures.Count -gt 0) {
  [Console]::Error.WriteLine('Scrollable page content is not consistently top-aligned:')
  $failures | ForEach-Object { [Console]::Error.WriteLine("- $_") }
  exit 1
}

Write-Output "Verified top alignment for $checked scrollable page content container(s)."
