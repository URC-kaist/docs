---
title: "Software"
weight: 3
draft: false
bookCollapseSection: true
---

# Core System Software

The 2026 MR2 software stack lives in `mr2-stack`. It combines rover-side ROS 2
control and autonomy, a base-station gateway, a browser dashboard, STM32 and
Arduino firmware, and utility scripts for deployment and hardware bring-up.

At runtime, the system is split across the rover and base station:

- The dashboard is the operator interface for driving, mission control, science
  tasks, system status, maps, and live video.
- The base gateway bridges dashboard WebSocket traffic to the rover XBEE radio,
  receives rover telemetry, serves video to browsers, tracks Rocket M2 status,
  and can drive the base antenna controller.
- The rover ROS 2 workspace owns robot description, ros2_control hardware
  interfaces, CAN device drivers, GNSS, autonomy, perception, science payloads,
  video streaming, and the XBEE bridge.
- Firmware on the rover and base station handles hardware-specific CAN, battery,
  LED, servo, and antenna control paths.

## Codebase Map

| Path in `mr2-stack` | Purpose |
| --- | --- |
| `rover/ros2_ws` | ROS 2 Humble workspace for rover launch, control, hardware interfaces, autonomy, perception, GNSS, science, and video streaming. |
| `base/gateway` | Node.js gateway between dashboard clients, XBEE serial, ROS 2 base topics, Rocket M2, MAVProxy, antenna control, and video receivers. |
| `dashboard` | Vite + React + TypeScript operator dashboard. |
| `rover/firmware` | STM32 firmware for rover hardware such as battery telemetry, LEDs, and camera turret servo outputs. |
| `base/arduino` | Base antenna controller firmware and host protocol notes. |
| `scripts` | Bring-up, deployment, CAN, udev, diagnostics, calibration, and quick test utilities. |
| `docs` | Source notes that describe codebase-specific systems such as the video pipeline. |

## Documentation Pages

- [Rover ROS 2 Stack]({{< ref "docs/2026_mr2/core-system/software/rover.md" >}})
- [Base Gateway]({{< ref "docs/2026_mr2/core-system/software/base_gateway.md" >}})
- [Dashboard]({{< ref "docs/2026_mr2/core-system/software/dashboard.md" >}})
- [Firmware and Devices]({{< ref "docs/2026_mr2/core-system/software/firmware_and_devices.md" >}})
- [Protocols and Data Flow]({{< ref "docs/2026_mr2/core-system/software/protocols_and_data_flow.md" >}})
- [Operations]({{< ref "docs/2026_mr2/core-system/software/operations.md" >}})
