---
title: "Protocols and Data Flow"
weight: 5
draft: false
---

# Protocols and Data Flow

The MR2 software stack uses ROS 2 for on-rover composition, WebSocket and HTTP
for browser/base-station traffic, XBEE serial frames for the radio link, CAN for
device buses, and RTP/H.264 for low-latency video.

## End-to-End Control Path

```text
Operator
  -> browser dashboard
  -> base gateway WebSocket
  -> MR2 XBEE binary frame
  -> rover mr2_xbee_bridge
  -> ROS 2 topics/services/actions
  -> controllers, device nodes, autonomy, and payload nodes
```

The reverse telemetry path uses the same gateway and XBEE bridge in the opposite
direction, then fans out to dashboard clients.

## XBEE Protocol

The rover package `mr2_xbee_bridge` and the base gateway share the MR2 XBEE
protocol. Each packet is a compact binary frame:

```text
magic 0xA5 | msg_id | length | seq | payload | crc16
```

Encoding rules:

- Multi-byte fields are little-endian.
- CRC is CRC-16/CCITT-FALSE over header and payload.
- Payload sizes are fixed for the known message types.
- The bridge applies configurable slew-rate limiting to drive and arm command
  families before publishing to ROS.

Message families:

| ID | Name | Direction | ROS meaning |
| --- | --- | --- | --- |
| `0x01` | `CMD_DRIVE` | Base to rover | `geometry_msgs/Twist` drive command. |
| `0x02` | `CMD_ARM_TWIST` | Base to rover | `geometry_msgs/TwistStamped` manipulator twist command. |
| `0x03` | `HEARTBEAT` | Both directions | Link liveness and deadman input. |
| `0x04` | `MISSION_CONTROL` | Base to rover | `mr2_action_interface/msg/MissionControl`. |
| `0x05` | `CMD_ARM_GRIPPER` | Base to rover | Gripper command payload. |
| `0x06` | `CMD_ARM_JOINT` | Base to rover | Manipulator joint command payload. |
| `0x10`, `0x11` | `TELEM_BATTERY_1`, `TELEM_BATTERY_2` | Rover to base | Battery telemetry frames. |
| `0x20` | `TELEM_NAV` | Rover to base | Rover navigation telemetry. |
| `0x30` | `BASE_SVIN` | Base to rover | Base survey-in ECEF and validity state. |
| `0x31` | `BASE_RTCM` | Base to rover | Raw RTCM correction bytes. |

Heartbeat loss triggers soft-stop behavior. Zero commands produced by timeout
use the same smoothing path as normal commands, so commands ramp down instead
of stepping abruptly.

## Mission Data Flow

Dashboard mission actions can travel through rosbridge or the XBEE gateway,
depending on the operation mode. On the rover, Mission Master owns execution
state.

| Topic | Type | Purpose |
| --- | --- | --- |
| `/mission_list` | `mr2_action_interface/msg/MissionList` | Ordered list of missions to execute. |
| `/mission_control` | `mr2_action_interface/msg/MissionControl` | Pause, resume, abort, and clear-costmap control. |
| `/mission_status` | `mr2_action_interface/msg/MissionStatus` | Mission Master state, arrival, progress, and debug status. |

Mission enum values currently used by the codebase:

| Field | Values |
| --- | --- |
| `mission_type` | `0=UNKNOWN`, `1=GNSS_ONLY`, `2=COVER_VISION` |
| `detection_method` | `0=NONE`, `1=ARUCO`, `2=YOLO` |
| `object_type` | `0=MALLET`, `1=PICK`, `2=BOTTLE` |
| `command` | `0=NOOP`, `1=PAUSE`, `2=RESUME`, `3=ABORT` |

## GNSS and Corrections

The base station can relay survey-in and RTCM correction data over XBEE:

```text
Base GNSS / ROS 2 topic
  -> base gateway ros_topic_relay
  -> BASE_SVIN or BASE_RTCM XBEE frame
  -> rover mr2_xbee_bridge
  -> rover GNSS/localization consumers
```

The rover uses `ublox_dgnss`, `rtcm_msgs`, NTRIP launch options, and
`robot_localization` conversion services. GNSS-only missions rely on
`robot_localization/srv/FromLL` to convert WGS84 goals into map coordinates.

## Video Pipeline

Video is intentionally split into three stages:

1. Rover ROS 2 or V4L2 source to GStreamer H.264 encoder.
2. Base gateway GStreamer receiver to gateway stream registry.
3. Browser WebSocket to WebCodecs decoder.

The central stream mapping is:

```text
rover/ros2_ws/src/mr2_launch/config/video_streams.json
```

The intended mapping rule is:

```text
1 source = 1 H.264 stream = 1 UDP port = 1 dashboard stream ID
```

Rover-side streams are sent as RTP/H.264 over UDP to the base host. The base
gateway receives each configured stream, groups H.264 access units, and sends
fresh video chunks to browser subscribers over `/video-ws`. The design favors
freshness and low latency over buffering old frames.

## Browser and Gateway Data Flow

| Browser path | Backing code | Purpose |
| --- | --- | --- |
| `/rosbridge-ws` | External rosbridge server | Direct ROS topic/service access from dashboard. |
| `/xbee-ws` | `base/gateway/src/runtime/ws_hub.js` | Gateway telemetry and command channel. |
| `/video-ws` | `base/gateway/src/video/*` | Binary video delivery. |
| `/video/streams` | Gateway HTTP handlers | Stream metadata from the central config. |
| `/rocket-m2/status` | Gateway HTTP handlers and Rocket M2 client | Base radio status. |

## CAN Data Flow

CAN is used for rover hardware devices. The common pattern is:

```text
ROS node or ros2_control interface
  -> mr2_can_bus_core / SocketCAN
  -> classic CAN frame
  -> STM32 or actuator firmware
```

Important standard IDs:

| CAN ID | Consumer | Meaning |
| --- | --- | --- |
| `0x123` | LED firmware | LED mode select. |
| `0x124` | LED/servo firmware | Camera turret X/Y servo command. |
| `0x300` to `0x314` | `mr2_battery_monitor` | Battery summary, metadata, and cell voltage telemetry. |

Actuator-specific IDs and layouts are owned by their device plugins and
firmware, then exposed to the rest of ROS through ros2_control interfaces and
status messages.
