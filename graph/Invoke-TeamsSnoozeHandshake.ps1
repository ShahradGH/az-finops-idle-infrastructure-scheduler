# Invoke-TeamsSnoozeHandshake.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [PSCustomObject]$ForecastResult,
    [Parameter(Mandatory)] [string]$OwnerUpn,
    [Parameter(Mandatory)] [string]$TeamId,
    [Parameter(Mandatory)] [string]$ChannelId,
    [Parameter(Mandatory)] [string]$SubscriptionId,
    [Parameter()] [bool]$SnoozeApprovedByOwner = $false,
    [Parameter()] [string]$DependencyTiersPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config/dependency-tiers.json'),
    [Parameter()] [scriptblock]$GraphInvoker = $null,
    [Parameter()] [scriptblock]$AzRestInvoker = $null
)

$ErrorActionPreference = 'Stop'

function Invoke-GraphV2Call {
    param([string]$Method, [string]$Uri, [hashtable]$Body = $null)
    if ($null -ne $GraphInvoker) {
        return & $GraphInvoker $Method $Uri $Body
    }
    $params = @{ Method = $Method; Uri = $Uri }
    if ($null -ne $Body) {
        $params['Body'] = ($Body | ConvertTo-Json -Depth 12)
        $params['ContentType'] = 'application/json'
    }
    return Invoke-MgGraphRequest @params
}

function Invoke-AzControlPlaneCall {
    param([string]$Method, [string]$Path)
    if ($null -ne $AzRestInvoker) {
        return & $AzRestInvoker $Method $Path
    }
    $resp = Invoke-AzRestMethod -Method $Method -Path $Path
    if ($resp.StatusCode -ge 400) {
        throw "Azure REST call failed ($($resp.StatusCode)) on $Path : $($resp.Content)"
    }
    return ($resp.Content | ConvertFrom-Json)
}

if ($ForecastResult.Recommendation -eq 'VETO_PRODUCTION_PROTECTED') {
    return [PSCustomObject]@{
        ResourceGroup = $ForecastResult.ResourceGroup
        Action        = 'VETO_PRODUCTION_PROTECTED'
        Deallocated   = $false
        CardSent      = $false
    }
}

# 1. Query Work IQ / Graph v2.x User Presence
$presenceUri = "https://graph.microsoft.com/v1.0/users/$OwnerUpn/presence"
$presenceResp = Invoke-GraphV2Call -Method 'GET' -Uri $presenceUri
$availability = if ($presenceResp.availability) { [string]$presenceResp.availability } else { 'Offline' }

# 2. Dispatch Teams Adaptive Card with [Snooze 3h] Action
$card = @{
    type    = 'AdaptiveCard'
    version = '1.5'
    body    = @(
        @{
            type   = 'TextBlock'
            text   = "FinOps Idle Window: $($ForecastResult.ResourceGroup)"
            weight = 'Bolder'
            size   = 'Medium'
        },
        @{
            type  = 'FactSet'
            facts = @(
                @{ title = 'Owner Presence'; value = $availability },
                @{ title = 'Idle Confidence'; value = [string]$ForecastResult.IdleConfidence },
                @{ title = 'Est. Daily Savings'; value = "`$$($ForecastResult.EstimatedDailySave)" },
                @{ title = 'Cost Anomaly'; value = [string]$ForecastResult.IsCostAnomaly }
            )
        }
    )
    actions = @(
        @{
            type  = 'Action.Submit'
            title = 'Snooze 3h'
            data  = @{ action = 'snooze_3h'; resourceGroup = $ForecastResult.ResourceGroup }
        }
    )
}

$attId = [guid]::NewGuid().ToString()
$teamsUri = "https://graph.microsoft.com/v1.0/teams/$TeamId/channels/$ChannelId/messages"
$teamsPayload = @{
    body        = @{ contentType = 'html'; content = "<attachment id=`"$attId`"></attachment>" }
    attachments = @(@{ id = $attId; contentType = 'application/vnd.microsoft.card.adaptive'; content = ($card | ConvertTo-Json -Depth 10 -Compress) })
}
$teamsResp = Invoke-GraphV2Call -Method 'POST' -Uri $teamsUri -Body $teamsPayload

if ($SnoozeApprovedByOwner -or $ForecastResult.Abstained -or $availability -eq 'Available') {
    return [PSCustomObject]@{
        ResourceGroup   = $ForecastResult.ResourceGroup
        OwnerPresence   = $availability
        Action          = 'DEFERRED_OWNER_ACTIVE_OR_SNOOZED'
        Deallocated     = $false
        CardSent        = $true
        TeamsMessageId  = $teamsResp.id
    }
}

# 3. Execute topological shutdown via Invoke-AzRestMethod
$tiers = Get-Content $DependencyTiersPath -Raw | ConvertFrom-Json
$executedSteps = [System.Collections.Generic.List[string]]::new()
foreach ($tier in $tiers.shutdownOrder) {
    $stopPath = "/subscriptions/$SubscriptionId/resourceGroups/$($ForecastResult.ResourceGroup)/providers/Microsoft.Resources/deployments/stop-${tier}?api-version=2023-07-01"
    $null = Invoke-AzControlPlaneCall -Method 'POST' -Path $stopPath
    $executedSteps.Add($tier)
}

return [PSCustomObject]@{
    ResourceGroup  = $ForecastResult.ResourceGroup
    OwnerPresence  = $availability
    Action         = 'EXECUTED_TOPOLOGICAL_DEALLOCATION'
    Deallocated    = $true
    CardSent       = $true
    TeamsMessageId = $teamsResp.id
    ShutdownSteps  = @($executedSteps)
}
