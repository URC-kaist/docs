---
title: "Developer Starting Card"
weight: 15
draft: false
---

# Where Do I Start?

Use this card when taking a migration task. [Briefing]({{< ref "docs/global-update-project/en/_index.md" >}}) · [한국어]({{< ref "docs/global-update-project/ko/start.md" >}})

## Pick the right workspace and environment

| Item | Starting point |
| --- | --- |
| Candidate source | Local `~/mr2-stack-jazzy`, branch `migration/jazzy`; verify its current revision before work |
| Reference source | Audited upstream `2026` at `74422f36…`; actual operational NX deployment is a separate inventory task |
| Development environment | Isolated Humble or Noble/Jazzy workstation environment; separate shells and build outputs |
| Native candidate tests | Configurable Nano, after retrieval, provisioning and bench access are established |
| NX rover | Existing operational deployment; disruptive testing only in coordinated maintenance windows |
| Coordination | SW leader allocates work; integrator reviews shared interfaces; HW/operator joins physical-test planning |

The local candidate currently contains baseline application code plus migration handoff documentation. A prepared repository does not establish a provisioned Jazzy environment.

## Start now with inspection and task preparation

These commands inspect the local candidate without installing dependencies, launching devices or changing branches:

```bash
git -C ~/mr2-stack-jazzy status --short --branch
git -C ~/mr2-stack-jazzy log -1 --oneline
git -C ~/mr2-stack-jazzy submodule status
```

Read the relevant source/configuration and upstream migration guidance. Identify its input/output contract and propose one representative check. Use [GU-00 through GU-12]({{< project-resource "projects/global-update-project/issues.en.json" >}}) to select the related work item with the leader. Inventory, source inspection, test design and recipe drafting can proceed before a physical test slot exists.

## Confirm before implementation or shared-bench changes

- Task outcome, owner/reviewer, exact baseline, required operating profile and shared-interface changes.
- Which environment is provisioned and who controls its shared configuration/peripherals.
- Expected evidence and remaining workstation/Nano/NX gates.

Repository destination, final integration baseline, candidate image and release capability selection remain team decisions. Record assumptions and keep dependent work pending when a decision affects it. Do not wait for every unrelated decision to complete useful investigation.

## Return a reviewable result

Supply the branch/SHA and small diff or proposal; environment and dependency/configuration versions; exact reproduction commands; expected and observed results; logs/artifact manifest; remaining target checks; and next action. Label unrun procedures as proposals. A failed test with a reproducible explanation is useful evidence.

For a software-only task, close only its declared software gate. Physical verification remains linked and pending where required. Keep a proposed API migration separate from planner tuning, protocol redesign or other behavioral changes unless the task explicitly includes them.

## Know when to involve someone

Use Codex for bounded source investigation, edits, builds, tests and evidence preparation. Involve the integrator when contracts cross sectors; the bench custodian before shared Nano reconfiguration; HW/operator before device or motion tests; and the designated release authority for NX cutover.

For a concrete model of the task and handoff, follow the [controller-loading example]({{< ref "docs/global-update-project/en/controller-example.md" >}}). It is a proposed migration exercise, not an already executed patch.
