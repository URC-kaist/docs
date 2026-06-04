---
title: "Firmware and Devices"
weight: 4
draft: false
---

# Firmware and Devices

Firmware and hardware-facing software live in both the rover and base-station
parts of `mr2-stack`. The ROS 2 layer should treat these as device protocols:
CAN nodes and hardware interfaces translate firmware frames into ROS messages,
services, or ros2_control joints.

## Rover Firmware

| Path | Target | Purpose |
| --- | --- | --- |
| `rover/firmware/battery_firmware` | STM32H523 | Polls a Makita XGT battery pack over a single-wire diagnostic bus and publishes pack telemetry on classic CAN. |
| `rover/firmware/led_firmware` | STM32 NUCLEO-G431KB | Listens on classic CAN for LED mode and camera turret servo commands. |

### Battery Firmware

The battery firmware uses USART2 on PA2 in half-duplex mode to speak the Makita
single-wire diagnostic protocol. After each polling cycle, it publishes a fixed
set of classic CAN frames on FDCAN1 at 500 kbit/s.

Frame catalogue:

| CAN ID | Contents |
| --- | --- |
| `0x300` | Summary: state of charge, health, temperature, voltage, cycle counter low bits. |
| `0x301` | Metadata: cell capacity, parallel count, cell count, lifetime charge cycles, cycle counter high bits. |
| `0x310` to `0x314` | Cell voltage pairs for cells 1 through 10. |

The ROS package `mr2_battery_monitor` consumes these frames and publishes
`mr2_battery_monitor/msg/PackTelemetry`. It also includes an emulator script for
testing without hardware.

### LED and Camera Turret Firmware

The LED firmware receives only. It accepts standard 11-bit CAN IDs `0x123` and
`0x124` at 500 kbit/s.

| CAN ID | Sender package | Payload |
| --- | --- | --- |
| `0x123` | `mr2_led` | LED mode in `Data[0]`: off, autonomous red, manual blue, success green blink. |
| `0x124` | `mr2_camera_turret` | Four-byte joystick payload for X/Y servo position. |

`mr2_led` exposes `mr2_led/srv/SetLedMode` and includes
`mission_status_led_node`, which maps Mission Master state to LED mode.
`mr2_camera_turret` subscribes to `/camera_turret/command`
(`geometry_msgs/msg/Vector3`) and maps normalized X/Y values to the 12-bit
joystick-style payload expected by the firmware.

## Base Antenna Firmware

`base/arduino` contains the base antenna controller firmware and its host
protocol. The host talks to the device over UART or USB serial using binary
frames:

```text
SOF 0xAA55 | LEN | SEQ | CMD | PAYLOAD | CRC16/CCITT-FALSE
```

Main host commands:

| Command | Meaning |
| --- | --- |
| `0x01 HOMING_START` | Start the antenna homing sequence. |
| `0x02 MOVE_TO_RAD` | Move to a target angle in Q16.16 radians. |

Device responses are `ACK (0x80)`, `DONE (0x81)`, and `ERROR (0x82)`.
The base gateway's antenna runtime can enable tracking, compute desired
bearing, and send movement commands to this controller through `/dev/ttyARDUINO`.

## ROS Hardware Boundary

| ROS package | Device boundary |
| --- | --- |
| `mr2_can_hardware_interface` | ros2_control boundary for CAN actuator plugins. |
| `mr2_devices_ak_servo` | AK servo CAN device plugin and mock servo node. |
| `mr2_devices_output_actuator` | Unified output actuator CAN plugin and status messages. |
| `mr2_battery_monitor` | Battery firmware CAN telemetry consumer. |
| `mr2_led` | LED mode service over CAN. |
| `mr2_camera_turret` | Camera turret command publisher over CAN. |
| `mr2_xbee_bridge` | Serial radio protocol boundary. |

## Utility Scripts

The `scripts` directory contains bring-up and hardware diagnostics. Important
groups include:

| Script group | Examples | Purpose |
| --- | --- | --- |
| CAN setup | `can0.bash`, `vcan0.bash` | Bring real or virtual CAN interfaces up. |
| Udev setup | `install_udev_serial_rules.bash`, `install_udev_base_station_rules.bash`, `99-mr2-serial.rules`, `99-mr2-base-station.rules` | Stable device names such as `/dev/ttyXBEE` and `/dev/ttyARDUINO`. |
| Device checks | `check_battery_status.bash`, `check_ak_actuator_status.bash`, `watch_rover_joints_from_can.bash` | Inspect live CAN or ROS state. |
| Actuator commands | `zero_steering.bash`, `drive_wheel_slow.bash`, `camera_turret_move.bash`, `steering_90_cansend.bash` | Manual bench commands. |
| Deployment | `deploy_dashboard.bash`, `nginx/*` | Dashboard build and nginx host mapping. |
| Navigation helpers | `wgs84_shift.py` | Convert east/north meter offsets into approximate WGS84 latitude/longitude shifts. |
