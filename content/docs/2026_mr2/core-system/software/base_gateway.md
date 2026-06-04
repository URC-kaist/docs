---
title: "Base Gateway"
weight: 2
draft: false
---

# Base Gateway

The base gateway lives in `mr2-stack/base/gateway`. It is a Node.js process that
sits between the browser dashboard, the XBEE radio link, base-side services, and
video receivers.

It does five main jobs:

1. Accept dashboard commands over WebSocket and forward them over XBEE.
2. Decode rover telemetry from XBEE and rebroadcast it to dashboard clients.
3. Relay selected ROS 2 base topics over XBEE, including survey-in and RTCM.
4. Expose base-side HTTP/WebSocket utilities such as Rocket M2 status and video.
5. Optionally drive the base antenna controller from rover/base GNSS state.

## Package Layout

| Path | Purpose |
| --- | --- |
| `index.js` | Package entrypoint used by `npm start`. Loads environment, parses config, starts the app, and handles shutdown. |
| `src/app/create_gateway_app.js` | Composition root for runtime adapters, protocol helpers, and lifecycle management. |
| `src/config.js` | CLI, environment, and default configuration parsing. |
| `src/protocol/xbee.js` | MR2 XBEE frame encode/decode. |
| `src/runtime/ws_hub.js` | Dashboard WebSocket client management and broadcasting. |
| `src/runtime/http_handlers.js` | HTTP endpoints such as Rocket M2 and video metadata handlers. |
| `src/runtime/serial_link.js` | XBEE serial transport. |
| `src/runtime/ros_topic_relay.js` | Base ROS 2 topic relay into XBEE frames. |
| `src/runtime/mavproxy.js` | MAVProxy child-process management. |
| `src/runtime/rocket_m2_client.js` | Rocket M2 polling and session handling. |
| `src/runtime/ws_route_registry.js` | WebSocket route wiring. |
| `src/antenna/tracker.js` | Bearing and antenna tracking state. |
| `src/antenna/base_station.js` | Serial protocol client for the base antenna Arduino. |
| `src/video/*` | H.264 parsing, binary `/video-ws` framing, GStreamer receivers, stream registry, and stream config validation. |
| `test/*` | Node test suite for protocol, runtime, video, config, and gateway helpers. |

## Runtime Interfaces

| Interface | Direction | Purpose |
| --- | --- | --- |
| `/xbee-ws` | Browser to gateway | Dashboard control, heartbeat, drive, arm, mission, and antenna messages. |
| `/video-ws` | Browser to gateway | Binary H.264 stream delivery to browser clients. |
| `/video/streams` | Browser to gateway | Stream metadata discovered from the central video config. |
| `/rocket-m2/status` | Browser to gateway | Base station radio status endpoint. |
| `/dev/ttyXBEE` | Gateway to radio | Serial MR2 XBEE frame transport. |
| Base ROS 2 topics | Gateway to rover | RTCM and base survey-in relay over XBEE. |
| `/dev/ttyARDUINO` | Gateway to antenna controller | Optional base antenna heading commands. |
| MAVProxy | Gateway child process | Optional MAVLink forwarding from `/dev/ttySIK`. |

## Configuration

The gateway reads configuration in this order:

1. CLI flags.
2. Component-specific environment variables.
3. Top-level MR2 network environment variables.
4. Built-in defaults.

At startup, it loads root `.env`, root `.env.local`, `base/gateway/.env`, and
`base/gateway/.env.local`, with later files overriding earlier files.

Important settings:

| Setting | Default | Purpose |
| --- | --- | --- |
| `BASE_XBEE_DEVICE` / `--base-xbee-device` | `/dev/ttyXBEE` | Base radio serial port. |
| `MR2_GATEWAY_HOST` / `--gateway-host` | `0.0.0.0` | Gateway bind host. |
| `MR2_GATEWAY_PORT` / `--gateway-port` | `8081` | Gateway HTTP/WebSocket port. |
| `BASE_XBEE_HEARTBEAT_HZ` | `2` | Gateway heartbeat rate. |
| `BASE_XBEE_LINK_TIMEOUT_MS` | `2000` | Link stale threshold. |
| `VIDEO_CONFIG_PATH` / `--video-config` | `rover/ros2_ws/src/mr2_launch/config/video_streams.json` | Central stream map. |
| `BASE_ANTENNA_ENABLE` / `--antenna-enable` | `false` | Enables antenna tracking. |
| `MAVPROXY_ENABLE` / `--mavproxy-enable` | `true` | Enables MAVProxy forwarding. |

## Running

Install dependencies:

```bash
cd mr2-stack/base/gateway
npm install
```

Run the gateway with the real XBEE device:

```bash
npm start -- --base-xbee-device /dev/ttyXBEE --gateway-port 8081
```

Run with antenna tracking:

```bash
npm start -- \
  --base-xbee-device /dev/ttyXBEE \
  --gateway-port 8081 \
  --antenna-enable true \
  --antenna-device /dev/ttyARDUINO
```

Run with video receive enabled:

```bash
npm start -- \
  --base-xbee-device /dev/ttyXBEE \
  --gateway-port 8081 \
  --video-config ../../rover/ros2_ws/src/mr2_launch/config/video_streams.json
```

If the ROS 2 topic relay is enabled, source the ROS environment before starting
the gateway so `rclnodejs` can initialize.

## Tests

The gateway uses Node's built-in test runner:

```bash
cd mr2-stack/base/gateway
npm test
```
