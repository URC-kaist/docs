---
title: "Joint Verification"
weight: 50
draft: false
---

# Joint SW/HW Verification and Release

[한국어]({{< ref "docs/global-update-project/ko/acceptance.md" >}})

[Briefing]({{< ref "docs/global-update-project/en/_index.md" >}})

Acceptance is a joint system activity. SW prepares the candidate and software evidence; HW integration confirms physical configuration/readiness; the rover operator coordinates operational access and physical execution. The team identifies who accepts results and authorizes release. Staffing remains with the relevant team leaders.

## Choose the required capabilities first

Agree the first-release operating profiles and classify each capability as required, deferred or experimental. Record its operational reference, scenario, expected outcome/tolerance, test equipment, participants and evidence. Do not treat UI placeholders or every configured stream as an automatically mandatory release requirement.

| Gate | Representative evidence |
| --- | --- |
| Reproduction | Clean build and setup record, source/dependency pins, independent reproduction |
| Control and Servo | Parameters/interfaces, lifecycle, command modes, units/directions/limits, stale commands and handover |
| Simulation and autonomy | Spawn/clock/sensors, TF, localization/traversability, both required mission paths and failure/cancel behavior |
| Communication/UI | Native ROS relay, commands/telemetry, disconnect/reconnect, intended deployment profiles |
| Cameras/inference/video | Required sensors and target-built model artifacts; NX encoder and agreed simultaneous workload |
| Native services | Device readiness, cold boot, restart/reconnect and sustained operation |
| Joint rover/field | Required end-to-end modes, physical behavior, operator workflow and recovery |

Choose numerical command-age, timing, latency, accuracy, resource and thermal limits from mission requirements and measured baseline behavior. Preserve evidence under comparable workload; avoid universal pass thresholds.

## What each environment can establish

Workstations establish software and simulated integration for their environment. The Nano adds native arm64/NVIDIA-stack and attached-device evidence. Only the actual NX/carrier/rover can close NX-specific hardware encoding, physical interfaces, production-load and field gates.

Record passes separately, including not-applicable checks with rationale. Software or Nano results must not silently become NX acceptance. Record source/submodule SHAs, image/BSP/kernel, runtime/dependency versions, power mode, input/configuration, commands, observed results, operator and timestamp.

## Maintenance window and recovery

Protect NX uptime during development. Before a disruptive session, review the candidate bundle, applicable Nano results, exact objectives, physical setup, stop conditions, restoration procedure, and available people/time. Include boot-firmware compatibility in recovery planning; an SSD copy alone may be insufficient.

Reserve time for restoration, diagnosis and a repeat run. Restore the operational deployment after testing unless cutover is separately agreed, then verify its required capabilities. A successful Nano recovery rehearsal does not establish NX recovery. If access is unavailable, keep the required target gate pending.

## Three different milestones

1. **Dispatch this initiation package:** make the project description, preferred approach, leader decisions and starter work visible.
2. **Accept an implementation checkpoint:** reviewed source plus evidence for its declared environment and capabilities.
3. **Cut over the rover:** required joint NX/field gates, a qualified deployment/recovery bundle, operator readiness, maintenance time and the team's release decision.

Publication of the brief does not announce milestone 3. Testing, fixes and reruns are explicit project work with their own capacity needs.
