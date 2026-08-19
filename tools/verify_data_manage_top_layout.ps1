param(
  [Parameter(Mandatory = $true)]
  [string]$LayoutPath
)

function Get-BoundsTop {
  param([string]$Bounds)

  $match = [regex]::Match($Bounds, '^\[-?\d+,(-?\d+)\]\[-?\d+,-?\d+\]$')
  if (-not $match.Success) {
    throw "Invalid layout bounds: $Bounds"
  }
  return [int]$match.Groups[1].Value
}

function Find-DataManageScroll {
  param([object]$Node)

  if ($Node.attributes.type -eq 'Scroll' -and $Node.children.Count -gt 0) {
    $directChild = $Node.children[0]
    if ($directChild.attributes.type -eq 'Column') {
      return [pscustomobject]@{ Scroll = $Node; Content = $directChild }
    }
  }

  foreach ($child in $Node.children) {
    $result = Find-DataManageScroll -Node $child
    if ($null -ne $result) {
      return $result
    }
  }
  return $null
}

try {
  $layout = Get-Content -Raw -Encoding utf8 -LiteralPath $LayoutPath -ErrorAction Stop |
    ConvertFrom-Json -ErrorAction Stop
  $match = Find-DataManageScroll -Node $layout
  if ($null -eq $match) {
    throw 'No Scroll with a direct Column child was found.'
  }

  $scrollTop = Get-BoundsTop -Bounds $match.Scroll.attributes.bounds
  $contentTop = Get-BoundsTop -Bounds $match.Content.attributes.bounds
  if ([Math]::Abs($scrollTop - $contentTop) -gt 1) {
    [Console]::Error.WriteLine(
      "DataManagePage content is not top-aligned: Scroll top=$scrollTop, content top=$contentTop."
    )
    exit 1
  }

  Write-Output "DataManagePage content is top-aligned: Scroll top=$scrollTop, content top=$contentTop."
  exit 0
} catch {
  [Console]::Error.WriteLine("Unable to verify DataManagePage layout: $($_.Exception.Message)")
  exit 1
}
