---
title: "Work Packages"
weight: 30
draft: false
---

# Delegate Outcomes and Evidence

[한국어]({{< ref "docs/global-update-project/ko/work-packages.md" >}})

[Briefing]({{< ref "docs/global-update-project/en/_index.md" >}})

**SW leader `@yongwhan-chung` assigns people and capacity.** This brief proposes responsibility groups and dependencies. A person can cover several groups; the table is not a fixed headcount request. The requester asks Yongwhan to retrieve the confirmed configurable Nano; retrieval and readiness are not yet reported complete.

| Workstream | Deliverable and skills | Dependencies / parallel work | URC 2027 contribution |
| --- | --- | --- | --- |
| Platform/build | Clean Humble/Jazzy recipes, pins, CI and Nano setup; Linux/Jetson/build skills | Starts with baseline/reference capture and Nano retrieval; enables all sectors | Reproducible onboarding and deployment |
| Navigation/simulation | Jazzy Nav2/BT configuration, localization/traversability, Harmonic | Workstation scenarios proceed alongside native integration; agrees control/sensor contracts | Repeatable autonomy rehearsals and assessed new capabilities |
| Communication/UI | Gateway/dashboard, native ROS relay, radio/proxy/services | Mocks and clean web builds run independently; end-to-end profiles require integration | Reliable operator control and observability |
| Manipulator/CAN/control | ros2_control, drive/steering, MoveIt Servo and CAN interfaces | Mock/lifecycle tests start early; physical checks need HW/operator collaboration | Verified motion and mode transitions |
| Perception/video | Camera SDK/wrapper, model recipes, inference, GStreamer | Nano after provisioning; NX encoding and simultaneous load remain target-specific | Reproducible sensing and operator video |
| System acceptance/release | Joint test matrix, operator procedures, release/recovery bundle | Planned early; prepared physical sessions and reruns are serialized | Integrated rover readiness |

One integrator coordinates shared launch files, messages, TF frames, URDF, operating profiles, and platform pins. Each work item needs an accountable owner and a reviewer. Review and HW/operator time are part of capacity planning.

## First three assignments to allocate

1. **Reference and scope:** identify the operational deployment and agree required first-release operating profiles/capabilities with SW, HW integration, and the rover operator.
2. **Nano bench:** retrieve and inventory it, establish access and isolated endpoints, identify test peripherals, and document provisioning/recovery.
3. **Reproducibility:** clean baseline/target build attempts and one representative native smoke scenario, with a second-member reproduction and evidence.

These can overlap. Their results resolve practical dependencies and support credible estimates for sector porting. Existing unmerged deployment work needs an explicit integration decision, not an assumption that the audited branch already includes it.

## Time and staffing information to collect

For each work item, ask its proposed owner for available hours/week, hands-on effort as a range, estimate confidence, prerequisites, and external waiting time. Separate implementation effort from review, bench reservation, parts, and NX-window delays. Update estimates after the first environment/porting exercise.

Plan backward from the team's actual URC 2027 readiness dates and integration rehearsals. Reserve time for joint testing, diagnosis, fixes, reruns, documentation, and recovery rehearsal. No competition date, delivery date, or staffing commitment is invented by this brief.

## What to delegate to Codex

Bounded tasks can include dependency inventory, environment recipes, documented API/configuration ports, meaningful tests, builds, failure investigation, and focused PR drafts. State the source revision, environment, interface to change, required result, and evidence location.

Humans provide physical configuration and calibration, supervise motion/device tests, decide acceptable mission behavior, and accept system results. A successful build cannot establish steering direction, real obstacle handling, or reliable full-load operation.

## Task handoff format

Record the outcome, reason, prerequisites, owner/reviewer, source/environment, commands or procedure, acceptance evidence, and recovery/stop conditions. Before an absence or pause, leave the last result, branch/SHA, remaining question, and next action. Integrate a small end-to-end scenario early so sector boundaries are exercised before the final rover session.

Use the [developer starting card]({{< ref "docs/global-update-project/en/start.md" >}}) when taking a task and the [controller-loading example]({{< ref "docs/global-update-project/en/controller-example.md" >}}) as a model for a bounded migration handoff.
