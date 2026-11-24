---
title: "Platform and Principles"
weight: 10
draft: false
---

# What Are We Updating?

[한국어]({{< ref "docs/global-update-project/ko/platform.md" >}})

[Briefing]({{< ref "docs/global-update-project/en/_index.md" >}})

The useful unit of migration is a working robot deployment. An OS upgrade changes the dependencies beneath ROS nodes, native libraries, device drivers, GPU inference, multimedia, and services. Treat the target as a combination to qualify:

**Module + carrier → JetPack/BSP → Ubuntu → ROS and native dependencies → application behavior.**

## Candidate platform

| Layer | Existing repository intent | Migration candidate |
| --- | --- | --- |
| Ubuntu | 22.04 **Jammy** | 24.04 **Noble** |
| ROS 2 | Humble | **Jazzy** |
| Gazebo pairing | Fortress | Harmonic |
| Production computer | Orin NX; installed image to inventory | Orin NX with a carrier-compatible candidate image |
| Native development bench | — | Confirmed configurable Orin Nano |

Jammy is an Ubuntu codename, not the ROS target. NVIDIA lists Orin support and an Ubuntu 24.04 base in **JetPack 7.2.1 / Jetson Linux 39.2.1**. This is the image candidate to investigate, subject to the actual Nano/NX carrier and peripheral requirements. [NVIDIA release](https://developer.nvidia.com/embedded/jetpack/downloads/archive-7.2.1), [module coverage](https://developer.nvidia.com/embedded/jetpack-archive)

On the audit date, 2026-11-14, Ubuntu 22.04 standard maintenance and ROS Humble support extend to May 2027. Ubuntu 24.04 and Jazzy extend to May 2029. The project is a planned support transition; existing Orin NX hardware does not itself impose an immediate OS replacement. [Ubuntu lifecycle](https://ubuntu.com/about/release-cycle), [ROS platform policy](https://raw.githubusercontent.com/ros-infrastructure/rep/master/rep-2000.rst)

The current Gazebo table lists Fortress through May 2027 and Harmonic through May 2029. Use the supported Jazzy/Harmonic pairing as the initial target. [Gazebo releases](https://gazebosim.org/docs/harmonic/releases/), [ROS pairing](https://gazebosim.org/docs/harmonic/ros_installation/)

## Preserve contracts; qualify behavior

Keep command units/signs, joint ordering and limits, frame conventions, protocol encodings, mode transitions, and stale-command behavior explicit. A new API may require implementation changes to preserve the same operator-visible behavior. Different numerical trajectories can be acceptable when they meet agreed mission tolerances.

Compare the candidate with an **identified operational reference**: deployed source/build, profiles, dependencies, calibration, models, and observed capabilities. The audited default branch is evidence about source, not proof of the NX deployment's exact contents.

## Nano and NX are related test environments

The Nano can establish native installation, arm64 build, NVIDIA-stack and attached-device results. It cannot certify a different carrier, the full NX workload, or the NX's hardware encoder. Orin Nano lacks NVENC; use an explicit reduced software-encoding profile when testing transport/browser behavior there. [NVIDIA encoding guide](https://docs.nvidia.com/jetson/archives/r36.4.4/DeveloperGuide/SD/Multimedia/SoftwareEncodeInOrinNano.html)

Share source models and build recipes. Generate and qualify deployment-specific inference artifacts instead of assuming a Nano-built TensorRT engine is an accepted NX artifact.

## Evaluate new capabilities deliberately

[Issue #55](https://github.com/URC-kaist/mr2-stack/issues/55#issuecomment-3891126618) motivates newer Nav2 functionality. The audit found `nav2_route` in Jazzy release metadata and source tag `1.3.14`; it did not find `RemoveInCollisionGoals` paths or Planner Server's `allow_partial_planning` parameter in that tag. Confirm exact installed-package behavior before committing to a feature. [Release source](https://github.com/ros-navigation/navigation2/tree/1.3.14), [Jazzy metadata](https://raw.githubusercontent.com/ros/rosdistro/master/jazzy/distribution.yaml)

Start each experiment from a mission problem and expected outcome. Skipping a blocked waypoint, moving a goal, and returning a partial path are different behaviors. Keep terrain-collision efficiency benchmarking separate from basic simulator compatibility.
