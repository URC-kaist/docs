---
title: "Project and Artifacts"
weight: 40
draft: false
---

# Make Work and Evidence Visible

[한국어]({{< ref "docs/global-update-project/ko/coordination.md" >}})

[Briefing]({{< ref "docs/global-update-project/en/_index.md" >}})

Use a shared GitHub Project to connect the operational codebase, migration work, documentation, and joint verification. **A local blueprint and bilingual starter issues are prepared; the organization Project and GitHub repository have not been created.** Their ownership, access and destination remain for team setup.

Download the [Project blueprint]({{< project-resource "projects/global-update-project/project.json" >}}) and [English starter issues]({{< project-resource "projects/global-update-project/issues.en.json" >}}). These files are review drafts, not a GitHub API import payload.

## Start with a small Project

| Field | Use |
| --- | --- |
| Status | Backlog, Ready, In progress, In review, Blocked, Done |
| Workstream | Platform, Navigation/Simulation, Communication/UI, Control/CAN, Perception/Video, System verification |
| Priority | P0 prerequisite, P1 migration, P2 capability investigation |
| Required environment | Workstation, Nano, NX, joint rover/field session; an item can require several |
| Assignees | Set by the SW leader through the issue |

Keep dependencies, commands, estimate ranges, evidence and unresolved gates in the linked issue/PR. Add dates/iterations after capacity and URC 2027 milestones are agreed. Useful views are the execution board, hardware queue, and integration roadmap.

A merged PR closes implementation work; it need not close a separate NX/system-verification issue. Every pass identifies its source, environment and configuration. New changes require checking whether earlier evidence remains applicable. [GitHub Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects)

## Repository policy

The preferred direction is a history-preserving migration fork with small branches/PRs, a documented upstream-fix routine, and explicit operational/candidate environments. API changes do not technically require a fork; the benefit sought is clear collaboration and deployment separation. Team ownership, canonical issue location and the eventual destination of accepted code should be decided together. [GitHub fork model](https://docs.github.com/en/pull-requests/reference/forks)

A from-scratch rewrite requires a separate technical case: a concrete limitation, replacement design, representative prototype, parity requirements, and transition plan. It is not implied by creating the migration repository.

## Projects index artifacts; storage retains them

| Artifact | Proposed home |
| --- | --- |
| Recipes, small manifests and test summaries | Versioned repository files |
| Routine CI logs/build outputs | Actions artifacts with explicit retention |
| Selected release bundles | Release assets when limits/access fit |
| Large recovery images, bags, video and datasets | Team-managed durable storage |

Link an artifact manifest from the issue: purpose, location, source SHA, hardware/BSP/configuration, checksum, access and retention. Actions artifacts can expire and disappear with deleted runs; preserve accepted-release and recovery material independently. [Artifact lifecycle](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/remove-workflow-artifacts), [binary distribution](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)

The team selects storage and verifies shared access. Keep credentials in the appropriate access mechanism rather than embedding them in ordinary evidence bundles.

## Coordination rhythm

A short regular review should reconcile operational fixes, candidate build status, shared-interface changes, the hardware queue and the next demonstrable result. A weekly review is a starting suggestion, adjusted to actual availability. Escalate NX-window conflicts to the SW leader, HW integration and the designated release authority while other work continues.

Documentation carries the stable explanation; issues/PRs carry changing work status; test records carry the results. Link them so readers do not have to reconstruct decisions from private conversations.
