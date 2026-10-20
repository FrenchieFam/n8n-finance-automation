<#
  Lightweight pre-import check for n8n workflow JSON.
  Catches: invalid JSON, forbidden nodes, missing names, placeholder credentials.
  Does NOT replace importing into n8n.
#>
param([Parameter(Mandatory = $true)][string]$Path)

if (-not (Test-Path $Path)) { Write-Error "File not found: $Path"; exit 1 }

$raw = Get-Content -Path $Path -Raw
try { $parsed = $raw | ConvertFrom-Json } catch { Write-Error "Invalid JSON: $($_.Exception.Message)"; exit 1 }

$workflows = if ($parsed -is [System.Array]) { $parsed } else { @($parsed) }
$forbidden = @('n8n-nodes-base.executeCommand')
$problems  = 0

foreach ($w in $workflows) {
    Write-Host "`nWorkflow: $($w.name)" -ForegroundColor Cyan

    if (-not $w.nodes) { Write-Warning "  No 'nodes' array"; $problems++; continue }
    if (-not $w.connections) { Write-Warning "  No 'connections' object"; $problems++ }

    foreach ($n in $w.nodes) {
        if (-not $n.name) { Write-Warning "  Node without a name (type: $($n.type))"; $problems++ }
        if ($forbidden -contains $n.type) {
            Write-Warning "  Forbidden node: '$($n.name)' [$($n.type)]"; $problems++
        }
        $json = $n.parameters | ConvertTo-Json -Depth 20 -Compress
        if ($json -match 'YOUR_|TODO|CHANGEME|example\.com|<your') {
            Write-Warning "  Placeholder value in '$($n.name)'"; $problems++
        }
    }

    $w.nodes | Group-Object type | Sort-Object Count -Descending |
        Format-Table @{n='Count';e={$_.Count}}, @{n='Node type';e={$_.Name}} -AutoSize
}

if ($problems -gt 0) {
    Write-Host "FAILED: $problems issue(s). Fix before importing." -ForegroundColor Red
    exit 1
}
Write-Host "PASSED basic checks. Import into an INACTIVE workflow in n8n next." -ForegroundColor Green
exit 0
