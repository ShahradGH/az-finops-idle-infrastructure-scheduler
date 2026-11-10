# ADR-001: FinOps in Practice: Autonomous Deallocation of Idle Non-Production Cloud Infrastructure

## Status
Accepted

## Service Owner & Sign-Off Authority
Principal FinOps Architect & Cloud Economics Lead

## Dominant Artefact
Non-Production Dynamic Power-Down Scheduler & Interactive Snooze Bot

## Decision & Refusal Boundary
All production state mutations must pass deterministic pre-flight policy evaluation in `src/Test-NonProdIdleDeallocationGate.ps1` and satisfy the 16-test Pester verification contract in `tests/Boundary-Verification.Tests.ps1` before execution.
