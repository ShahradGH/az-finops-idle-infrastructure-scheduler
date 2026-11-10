# Operational Runbook: FinOps in Practice: Autonomous Deallocation of Idle Non-Production Cloud Infrastructure (L2 / L3 Triage)

## 1. Scope & Ownership
- **Accountable Owner**: Principal FinOps Architect & Cloud Economics Lead
- **Primary Evaluator**: `src/Test-NonProdIdleDeallocationGate.ps1`
- **Telemetry Source**: `diagnostics/Telemetry-Queries.kql`

## 2. Triage Procedure When Veto Gate Trips
1. Inspect the structured refusal object emitted by `src/Test-NonProdIdleDeallocationGate.ps1` and correlate the timestamp in Azure Monitor Log Analytics.
2. Do not bypass or disable the pre-flight policy gate without cryptographic dual-signature approval from the Principal FinOps Architect & Cloud Economics Lead.
3. Verify remediation locally by running `Invoke-Pester -Path ./tests/Boundary-Verification.Tests.ps1 -Output Detailed`.
