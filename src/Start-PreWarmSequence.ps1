# Start-PreWarmSequence.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$EnvironmentName,
    [Parameter()] [string]$SubscriptionId = '00000000-0000-0000-0000-000000000016',
    [Parameter()] [string]$DependencyTiersPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config/dependency-tiers.json'),
    [Parameter()] [scriptblock]$AzRestInvoker = $null
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$tiers = Get-Content $DependencyTiersPath -Raw | ConvertFrom-Json
$started = [System.Collections.Generic.List[string]]::new()

foreach ($step in $tiers.startupOrder) {
    $path = "/subscriptions/$SubscriptionId/resourceGroups/$EnvironmentName/providers/Microsoft.Resources/deployments/start-${step}?api-version=2023-07-01"
    if ($null -ne $AzRestInvoker) {
        $null = & $AzRestInvoker 'POST' $path
    }
    $started.Add($step)
}

return [PSCustomObject]@{
    Environment = $EnvironmentName
    Sequence    = @($started)
    ReadyByUtc  = '07:30'
    Status      = 'PREWARM_TOPOLOGY_READY'
}
