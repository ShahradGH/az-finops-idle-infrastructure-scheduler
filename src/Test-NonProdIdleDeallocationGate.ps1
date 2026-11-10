# Test-NonProdIdleDeallocationGate.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [PSCustomObject]$EnvironmentTelemetry
)

$ErrorActionPreference = 'Stop'

# 1. Hard Protection: Never touch Production or Drilled DR environments
if ($EnvironmentTelemetry.EnvironmentTag -in @('prod', 'production', 'dr')) {
    return [PSCustomObject]@{
        ResourceGroup = $EnvironmentTelemetry.ResourceGroupName
        Action        = 'VETO_PRODUCTION_ENVIRONMENT_PROTECTED'
        Deallocate    = $false
    }
}

# 2. Respect Active Developer Teams Snooze Lease
if ($EnvironmentTelemetry.HasActiveSnoozeLease -eq $true) {
    return [PSCustomObject]@{
        ResourceGroup = $EnvironmentTelemetry.ResourceGroupName
        Action        = 'SKIP_ACTIVE_DEVELOPER_SNOOZE_LEASE'
        SnoozedBy     = $EnvironmentTelemetry.SnoozeOwnerUpn
        Deallocate    = $false
    }
}

# 3. Check 60-Minute CPU, SQL Connections, and Active CI/CD Deployments
if ($EnvironmentTelemetry.AvgCpuPercent60m -gt 8.0 -or
    $EnvironmentTelemetry.ActiveSqlUserConnections -gt 2 -or
    $EnvironmentTelemetry.ActiveCiPipelineRuns -gt 0) {
    return [PSCustomObject]@{
        ResourceGroup = $EnvironmentTelemetry.ResourceGroupName
        Action        = 'SKIP_WORKLOAD_ACTIVELY_IN_USE'
        Deallocate    = $false
    }
}

return [PSCustomObject]@{
    ResourceGroup  = $EnvironmentTelemetry.ResourceGroupName
    Action         = 'EXECUTE_ORDERED_DEALLOCATION_AND_MUTE_ALERTS'
    Deallocate     = $true
    StartupOrder   = @('1_DataTier_SQL_Postgres', '2_Cache_Redis', '3_Compute_AKS_VMs')
}
