# Start-PreWarmSequence.ps1
[CmdletBinding()]
param([Parameter(Mandatory)][string]$EnvironmentName)
Set-StrictMode -Version Latest
return [PSCustomObject]@{ Environment = $EnvironmentName; Sequence = @('1-DataTier', '2-PrivateDnsVerify', '3-AksSystemPool', '4-AksUserPool'); ReadyByUtc = '07:30' }
