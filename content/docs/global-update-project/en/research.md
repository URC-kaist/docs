---
title: "Technical Assessment"
weight: 60
draft: false
---

# Audit Basis and Migration Boundaries

[한국어]({{< ref "docs/global-update-project/ko/research.md" >}})

[Briefing]({{< ref "docs/global-update-project/en/_index.md" >}})

Audit date: **2026-11-14**. [URC-kaist/mr2-stack](https://github.com/URC-kaist/mr2-stack) has default branch `2026`, not `main`. The audited source is [`74422f36c55140519f111cf6709f1725711b536a`](https://github.com/URC-kaist/mr2-stack/tree/74422f36c55140519f111cf6709f1725711b536a). It contains 22 own ROS packages and 7 packages in two pinned submodules. This identifies the research snapshot; it is not an inventory of the running NX deployment.

## Highest-impact boundaries

| Boundary | Assessment and task |
| --- | --- |
| Jetson platform | Carrier BSP, CAN, cameras, multimedia and inference need native qualification as a combination. Record exact boards/images. |
| ros2_control / Servo | Review manager/spawner parameter propagation, hardware interfaces and lifecycle. Existing Servo startup/status callers need adaptation to the target API. |
| Nav2 | Reconcile plugin identifiers, progress-checker configuration, BT.CPP/XML and custom traversability behavior against exact target versions. |
| Gazebo | The code already uses modern `ros_gz_sim`/`gz_ros2_control`. Normalize mixed Ignition/Gazebo configuration and verify sensor/clock/QoS behavior. |
| Perception/video | Unpinned Python dependencies and external engine provenance need recipes; validate required simultaneous camera/encoder/inference load. |
| Web/native relay | Clean dashboard type checking reproduces duplicate declarations. Mocked gateway tests do not establish real `rclnodejs` integration. |
| Reproducibility | Existing lockfiles/gitlinks help, but a clean ROS build and complete native dependency recipe remain work to perform. |

Upstream references: [ros2_control migration](https://control.ros.org/jazzy/doc/ros2_control/doc/migration.html), [Jazzy Servo source](https://raw.githubusercontent.com/moveit/moveit2/jazzy/moveit_ros/moveit_servo/src/servo_node.cpp), [Nav2 Humble→Iron](https://docs.nav2.org/rolling/configuration_and_development/migration_guides/Humble/), [Nav2 Iron→Jazzy](https://docs.nav2.org/rolling/configuration_and_development/migration_guides/iron/Iron/), [Gazebo migration](https://gazebosim.org/docs/harmonic/migration_from_ignition/). Confirm selected released packages before implementation; moving upstream branches are references, not deployment pins.

## What was actually checked

On Ubuntu 22.04.5 amd64 / Humble: **49 gateway tests passed** using installed dependencies and mocked native boundaries. A clean dashboard dependency install succeeded; its type check reproduced nine duplicate science type aliases. Syntax checks passed for 68 Python, 21 Bash and 43 XML/Xacro/SDF files. These are bounded results, not runtime or semantic validation.

No clean ROS compile, Jazzy build, simulator execution, native Jetson test, GPU test or field acceptance was performed. A direct Noble arm64 package-index fetch failed TLS verification; this was recorded rather than interpreted as package absence. ROS release metadata establishes observed release records, not binary installation or behavior.

Evidence downloads: [source inventory]({{< project-resource "projects/global-update-project/evidence/repository-snapshot.json" >}}), [package dependencies]({{< project-resource "projects/global-update-project/evidence/package-dependencies.tsv" >}}), [gateway tests]({{< project-resource "projects/global-update-project/evidence/gateway-tests.json" >}}), [clean dashboard check]({{< project-resource "projects/global-update-project/evidence/clean-dashboard-check.json" >}}), [release metadata]({{< project-resource "projects/global-update-project/evidence/target-release-availability.json" >}}), [evidence manifest]({{< project-resource "projects/global-update-project/evidence/manifest.json" >}}).

## Relevant parallel development

[PR #81](https://github.com/URC-kaist/mr2-stack/pull/81) / [issue #80](https://github.com/URC-kaist/mr2-stack/issues/80) describe rover-direct deployment. Their historical Nano wording does not change the confirmed production NX target, and branch validation claims are not default-branch results. Decide how that work joins the integration baseline. [Issue #68](https://github.com/URC-kaist/mr2-stack/issues/68) already tracks CI needs; [#83](https://github.com/URC-kaist/mr2-stack/issues/83) concerns lightweight observability.

The terrain world uses a large mesh collision asset. Harmonic compatibility and terrain-efficiency benchmarking are separate tasks: compare equivalent assets/settings and record the loaded physics backend before attributing any speedup to the simulator.
