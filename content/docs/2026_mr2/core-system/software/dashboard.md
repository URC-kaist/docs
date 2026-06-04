---
title: "Dashboard"
weight: 3
draft: false
---

# Dashboard

The dashboard lives in `mr2-stack/dashboard`. It is a Vite + React +
TypeScript browser application for base-station operators. It combines ROS
topics/services from rosbridge with the MR2 base gateway's WebSocket, HTTP, and
video endpoints.

## Runtime Model

The dashboard talks to two external systems:

| External system | Used for |
| --- | --- |
| `rosbridge` | ROS diagnostics, mission topics, `/toLL` map-coordinate conversion, science capture services, autonomy visualization, and selected ROS status topics. |
| Base gateway | XBEE telemetry, drive/arm/mission commands, battery and link status, antenna state, Rocket M2 state, and browser video streams. |

If environment variables are not supplied, the dashboard assumes it is served
behind the same host that proxies these paths:

- `/rosbridge-ws`
- `/xbee-ws`
- `/video-ws`
- `/video/streams`

## Package Structure

| Path | Purpose |
| --- | --- |
| `src/App.tsx` | Top-level application shell and tab layout. |
| `src/main.tsx` | React entrypoint. |
| `src/components` | Operator UI panels and cards for control, autonomy, science, system status, video, map preview, missions, manipulator, and radio state. |
| `src/hooks` | Runtime hooks for ROS bridge, XBEE gateway, video streams, map preview, manipulator state, and status cards. |
| `src/lib` | Transport clients, message models, mission helpers, map helpers, video protocol, and system status helpers. |
| `src/types` | Ambient browser/global declarations. |
| `public` | Vendored browser assets such as `roslib.min.js`. |
| `package.json` | Vite, TypeScript, lint, build, and check scripts. |

## Major UI Areas

| Area | Main code |
| --- | --- |
| Manual controls | `ControlPanel`, `DeliveryPanel`, `CameraTurretCard`, `ArmServoCard`, `ManipulatorViewer`. |
| Autonomy | `AutonomousTabPanel`, `MissionMasterPanel`, `MissionPanels`, `AutonomyHealthCard`, `RecentObjectsCard`, `MapPreview`. |
| Science | `ScienceTabPanel`, `SpectrophotometerCard`, `MicroscopeViewCard`, `CentrifugeCard`. |
| System status | `SystemStatusPanel`, `SystemStatusCards`, `GnssStatusCard`, `RocketM2Card`. |
| Video | `LiveFeedTabPanel`, `ConfiguredVideoGrid`, `VideoStreamCard`. |

## Transport Helpers

| Module | Responsibility |
| --- | --- |
| `lib/rosBridge.ts` and `hooks/useRosBridge.ts` | Connect to rosbridge and expose ROS topic/service access. |
| `lib/xbeeGateway.ts` and `hooks/useXbeeGateway.ts` | Connect to the base gateway for telemetry, link state, mission control, heartbeats, drive/arm commands, antenna state, and Rocket M2 status. |
| `lib/videoGateway.ts`, `lib/videoProtocol.ts`, and `hooks/useVideoStreams.ts` | Discover streams, subscribe over `/video-ws`, parse gateway video framing, and feed browser-side video rendering. |
| `lib/rosMessages.ts` | Shared ROS payload models used by UI components. |
| `lib/missions.ts` | Mission list and control payload helpers. |

## Environment Variables

| Variable | Purpose | Default if unset |
| --- | --- | --- |
| `VITE_ROSBRIDGE_URL` | Full rosbridge WebSocket URL. | `ws(s)://<current-host>/rosbridge-ws` |
| `VITE_XBEE_WS_URL` | Full base gateway WebSocket URL. | `ws(s)://<current-host>/xbee-ws` |
| `VITE_VIDEO_WS_URL` | Full video WebSocket URL. | `ws(s)://<current-host>/video-ws` |
| `VITE_VIDEO_STREAMS_URL` | Video metadata endpoint. | `http(s)://<current-origin>/video/streams` |
| `VITE_SPECTRO_CALIBRATION_PATH` | Metadata written into spectrometer CSV exports. | `unknown` unless supplied by the service response. |

Use `dashboard/.env.local.example` as the template for local overrides.

## Development Commands

```bash
cd mr2-stack/dashboard
npm install
npm run dev
```

Useful package scripts:

| Script | Purpose |
| --- | --- |
| `npm run dev` | Starts the Vite dev server. |
| `npm run build` | Builds the production bundle. |
| `npm run preview` | Serves the built bundle locally. |
| `npm run lint` | Runs ESLint. |
| `npm run typecheck` | Runs the TypeScript checker. |
| `npm run check` | Runs typecheck, lint, and build. |

Production deployment is handled by `scripts/deploy_dashboard.bash`, which
builds the dashboard and updates the nginx-hosted bundle.
