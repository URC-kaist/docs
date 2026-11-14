---
title: "English"
weight: 1
draft: false
bookCollapseSection: true
---

# MR2 Global Update: Developer Briefing

[한국어]({{< ref "docs/global-update-project/ko/_index.md" >}})

**Prepare a reproducible, maintainable Orin NX deployment on Ubuntu 24.04 / ROS 2 Jazzy while keeping the existing rover operational.** Use the fully configurable Orin Nano for native Jetson development and reserve NX interruptions for prepared integration windows.

This project supports URC 2027 preparation through reliable onboarding, repeatable development, improved package support, and joint system verification. It also creates room to evaluate useful newer capabilities. Compatibility and capability experiments have separate acceptance criteria.

## Your questions as a developer

| Question | Start here |
| --- | --- |
| What does updating to 24.04/Jazzy actually mean? | [Platform and principles]({{< ref "docs/global-update-project/en/platform.md" >}}): change the platform while preserving required behavior. |
| Where do I start, and how do Humble and Jazzy coexist? | [Developer starting card]({{< ref "docs/global-update-project/en/start.md" >}}), then [workflow]({{< ref "docs/global-update-project/en/workflow.md" >}}). |
| Can we divide the work between parallel developers? | [Work packages]({{< ref "docs/global-update-project/en/work-packages.md" >}}): sectors, dependencies, and information for staffing. |
| What can Codex do procedurally, and where do people intervene? | [Worked controller-loading example]({{< ref "docs/global-update-project/en/controller-example.md" >}}): inspect, propose, verify, and hand over. |
| What do workstation and Nano tests prove about our single NX? | [Joint verification]({{< ref "docs/global-update-project/en/acceptance.md" >}}): environment-specific evidence and prepared NX windows. |
| Can we learn and integrate newer capabilities too? | [Capability investigations]({{< ref "docs/global-update-project/en/platform.md" >}}): evaluate exact-version features alongside compatibility work. |

## Operating model

| Environment | Responsibility |
| --- | --- |
| Developer workstations | Parallel software development, clean builds, simulation, and feature investigation |
| Configurable Orin Nano | Native arm64/NVIDIA-stack integration, provisioning and recovery experiments |
| Operational Orin NX rover | Production-specific verification and field acceptance in scheduled windows |

Maintain the Humble operational line while developing the candidate. A migration fork is the preferred repository arrangement for team consideration; the prepared local repository preserves upstream history. [Development workflow]({{< ref "docs/global-update-project/en/workflow.md" >}})

## Coordination and kickoff

Current SW leader **`@yongwhan-chung`** determines assignments and capacity. A shared GitHub Project and bilingual starter issues are drafted; GitHub Project/repository creation remains pending. [Coordination and artifacts]({{< ref "docs/global-update-project/en/coordination.md" >}})

Agree the integration baseline and required operating profiles, arrange Nano retrieval/access, allocate the first reproducibility tasks, and identify HW/operator participation. Then use measured results to plan parallel porting and URC 2027 integration rehearsals. [Kickoff agenda]({{< ref "docs/global-update-project/en/agenda.md" >}})

The audit identifies the main porting boundaries; the candidate has not yet been built or qualified on either Jetson. [Technical assessment]({{< ref "docs/global-update-project/en/research.md" >}}) · [Joint verification]({{< ref "docs/global-update-project/en/acceptance.md" >}})
