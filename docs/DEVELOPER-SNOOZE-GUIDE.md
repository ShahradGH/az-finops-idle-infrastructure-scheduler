# Developer Snooze & Topological Deallocation Runbook

## 1. Philosophy: Zero-Surprise FinOps Automation

Aggressive auto-shutdown scripts fail when they treat developer environments as stateless batch jobs. Killing an AKS cluster or PostgreSQL Flexible Server while an engineer is actively debugging a pull request destroys trust and causes teams to re-tag `dev` resource groups as `prod`.

This scheduler solves that tension with a three-layer safety model:
1. **Hard Production & DR Veto**: Any resource group tagged `prod`, `production`, or `dr` is unconditionally rejected (`VETO_PRODUCTION_ENVIRONMENT_PROTECTED`) by both `src/Test-NonProdIdleDeallocationGate.ps1` and `ai/Predict-IdleDeallocationWindow.ps1`.
2. **Multi-Signal AI Forecasting**: Rather than relying solely on CPU thresholds, `ai/Predict-IdleDeallocationWindow.ps1` fuses FinOps Toolkit **FOCUS 1.0** cost telemetry, Azure Monitor CPU/SQL metrics, GitHub/Azure DevOps commit velocity, and **Work IQ / Microsoft Graph v2.x** presence signals.
3. **Human-in-the-Loop `[Snooze 3h]` Handshake**: Before executing shutdown, `graph/Invoke-TeamsSnoozeHandshake.ps1` queries `GET /v1.0/users/{ownerUpn}/presence` and posts a Microsoft Teams Adaptive Card with a `[Snooze 3h]` action. If the owner is `Available` or clicks `[Snooze 3h]`, deallocation is deferred immediately.

## 2. Topological Shutdown & Pre-Warm Order

Shutting down databases before compute causes Kubernetes `CrashLoopBackOff` storms and noisy Azure Monitor alerts. `config/dependency-tiers.json` enforces strict ordering via `Invoke-AzRestMethod`:

- **Evening Shutdown Order**:
  1. `AksUserNodePools` (scale user pools to 0)
  2. `AksClusterStop` (stop control-plane compute)
  3. `AppServiceNonProd` (stop non-prod App Service plans)
  4. `DatabasePause` (pause PostgreSQL/SQL Flexible Servers last)
- **Morning Pre-Warm Order (`07:30 UTC`)**:
  1. `DatabaseResume`
  2. `KeyVaultConnectivityCheck`
  3. `AksClusterStart`
  4. `AksUserNodePools`

## 3. L2 Troubleshooting

- **False-Negative Abstention**: If `Predict-IdleDeallocationWindow.ps1` returns `ABSTAIN_DEFER_TO_HUMAN_SNOOZE`, inspect the `Signals` array—mixed signals (e.g., low CPU but active PR checks) intentionally abstain below `0.74` confidence.
- **Cost Anomaly Flag**: When `EffectiveCost / BaselineHourlyCost >= 1.8`, the forecaster emits `DEALLOCATE_AND_FLAG_COST_ANOMALY` so FinOps teams can investigate runaway SKU scaling alongside idle waste.
