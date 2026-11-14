---
title: "Development Workflow"
weight: 20
draft: false
---

# Develop Alongside the Operational Rover

[한국어]({{< ref "docs/global-update-project/ko/workflow.md" >}})

[Briefing]({{< ref "docs/global-update-project/en/_index.md" >}})

The **NX rover stays on its operational deployment during ordinary development**. Candidate provisioning, reflashing, service experiments, and native integration belong on the Nano. Simulation and parallel coding belong on workstations.

{{< mermaid >}}
flowchart LR
    W[Workstations] --> C[Reviewed candidate]
    N[Nano bench] --> C
    C --> Q[Scheduled NX verification]
    Q --> F[Joint system and field acceptance]
    F --> R[Agreed cutover]
{{< /mermaid >}}

## Two development lines

Keep the operational Humble line available while developing Jazzy in an isolated repository/workspace. A team-accessible migration fork is preferred for consideration; its GitHub destination and eventual canonical-repository policy remain team decisions. A local history-preserving repository is prepared at `~/mr2-stack-jazzy`, on `migration/jazzy`, with `upstream` pointing to `URC-kaist/mr2-stack` and no publishing remote.

Its starting point is audited commit `74422f36c55140519f111cf6709f1725711b536a`, also marked by local tag `audit/2026-11-14`. This is a provisional integration starting point. Decide how rover-direct work and any differences in the operational deployment join the baseline before sector ports converge.

Use small branches and reviewed PRs inside the chosen repository. Land operational fixes in the Humble line when appropriate, then reconcile them into Jazzy through an agreed merge/cherry-pick routine. Keep target-only changes on the candidate. A separate repository provides collaboration isolation; it does not require or imply a rewrite.

## Separate environments and shared contracts

Use clean 22.04/Humble and 24.04/Jazzy environments, independent shells, and separate `build`, `install`, and `log` outputs. Do not source both ROS installations or reuse binary overlays across them. Containers help reproduce user space but do not replace native BSP/device testing.

Keep development ROS graphs and command/network endpoints isolated from the operational rover. Agree shared message, TF, launch, protocol, and operating-profile changes through the integrator. Tests should exercise actual native ROS boundaries as well as mocks.

## First reproducibility exercise

The build owner prepares the provisioning recipe and a representative scenario. Another member reproduces it from a clean environment. Record source/submodule pins, dependency sources, runtime versions, exact commands, results, and remaining device checks.

The following is a **check sequence after candidate provisioning**, not a complete installation recipe or a claim that the current source already passes:

```bash
# Run in a disposable Noble/Jazzy development environment, not on the rover NX.
source /opt/ros/jazzy/setup.bash
cd ~/mr2-stack-jazzy/rover/ros2_ws
rosdep install --from-paths src --ignore-src --rosdistro jazzy -y
colcon build --symlink-install --event-handlers console_direct+
source install/setup.bash
colcon test --event-handlers console_direct+
colcon test-result --verbose
```

Review dependency failures; do not hide them behind broad skip lists. Start with one useful smoke scenario and repair its blocking baseline defects. Broader checks expand with the implementation.

## Shared Nano discipline

Reserve the bench with source revision, image, peripherals, expected duration, and planned reboots/reflashes. Identify who controls shared OS/BSP and global dependencies during that reservation. Leave either a restored reference environment or an explicit documented handoff. Use dedicated test peripherals, replay, or mocks rather than removing required equipment from the rover.

## Prepared NX windows

Investigate NX-specific support and configuration early without disrupting operation. For checks that need the actual NX, bring a reviewed candidate bundle, applicable Nano evidence, bounded objectives, stop conditions, and a firmware-aware recovery plan to a scheduled maintenance window.

Reserve restoration time and restore the operational deployment after a test session unless cutover is separately agreed. Nano practice does not prove NX recovery. If no window is available, leave NX-only gates pending and continue independent work. Final replacement of the single NX deployment cannot promise uninterrupted service throughout cutover.
