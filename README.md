# FinOps in Practice: Autonomous Deallocation of Idle Non-Production Cloud Infrastructure

[![Pester Verification](https://img.shields.io/badge/pester-16%2F16%20passing-brightgreen)](tests/IdleScheduler.Tests.ps1)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Architecture Deep-Dive](https://img.shields.io/badge/blog-alerasoul.net-0a1128)](https://alerasoul.net/finops-idle-infrastructure-dynamic-scheduler/)

> **Primary Governance Artefact:** Non-Production Dynamic Power-Down Scheduler & Interactive Snooze Bot  
> **Accountable Service Owner:** Principal FinOps Architect & Cloud Economics Lead  
> **Full Architectural Deep-Dive:** [https://alerasoul.net/finops-idle-infrastructure-dynamic-scheduler/](https://alerasoul.net/finops-idle-infrastructure-dynamic-scheduler/)

---

## Repository Layout (10 Files)

```text
├── .gitignore
├── LICENSE
├── README.md
├── config/dependency-tiers.json
├── docs/DEVELOPER-SNOOZE-GUIDE.md
├── queries/Idle-Compute-Candidates.kql
├── schemas/teams-snooze-card.json
├── src/Start-PreWarmSequence.ps1
├── src/Test-NonProdIdleDeallocationGate.ps1
└── tests/IdleScheduler.Tests.ps1
```

## Quickstart & Offline Verification

```powershell
# 1. Execute the primary PowerShell 7 evaluator
pwsh -NoProfile -File ./src/Test-NonProdIdleDeallocationGate.ps1

# 2. Run the 16-test Pester verification contract
Invoke-Pester -Path ./tests/IdleScheduler.Tests.ps1 -Output Detailed
```

## License

Released under the [MIT License](LICENSE). Authored by **Shahrad Alerasoul** ([alerasoul.net](https://alerasoul.net)).
