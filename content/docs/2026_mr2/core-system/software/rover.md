---
title: "Rover ROS 2 Stack"
weight: 1
draft: false
---

# Rover ROS 2 Stack

The rover software is a ROS 2 Humble workspace under `mr2-stack/rover/ros2_ws`.
It is the on-vehicle runtime for robot description, simulation, hardware
interfaces, CAN device drivers, GNSS, navigation, autonomy, perception, science
payloads, video streaming, and XBEE command/telemetry bridging.

## Workspace Structure

| Package | Role |
| --- | --- |
| `mr2_launch` | Top-level launch entrypoints, environment loading, video stream config, RViz configs, sim and real composition. |
| `mr2_rover_description` | URDF/Xacro, meshes, Gazebo worlds, ros2_control configuration, sim and real robot bring-up. |
| `mr2_rover_control` | Controller that converts `/cmd_vel` style twist commands into wheel and steering commands. |
| `mr2_can_hardware_interface` | ros2_control `SystemInterface` that loads CAN device plugins and exposes joints. |
| `mr2_can_bus_core` | Shared SocketCAN transport and CAN utility layer used by CAN-facing packages. |
| `mr2_devices_ak_servo` | CAN device plugin and mock node for AK servo joints. |
| `mr2_devices_output_actuator` | CAN output actuator plugin plus status messages for actuator config, angle, velocity, travel limits, and diagnostics. |
| `mr2_battery_monitor` | Reads battery CAN telemetry from the misc firmware and publishes `PackTelemetry`. |
| `mr2_led` | CAN LED service and mission-status-to-LED bridge. |
| `mr2_camera_turret` | Classic CAN camera turret command driver. |
| `mr2_xbee_bridge` | Serial XBEE protocol bridge between base station commands/telemetry frames and ROS topics. |
| `mr2_action_interface` | Mission, status, action, and control message definitions shared by autonomy and dashboard paths. |
| `mr2_rover_auto` | Mission master, GNSS-only and cover-vision actions, map conversion, traversability, localization, and navigation adapters. |
| `mr2_nav2_plugins` | Custom Nav2 plugin code. |
| `mr2_yolo_perception` | YOLO RGB-D detector that publishes class-specific 3D poses. |
| `mr2_panorama` | Direct V4L2 panorama action server. |
| `mr2_spectrophotometer` | ROS 2 wrapper for the spectrophotometer toolkit. |
| `mr2_spectrophotometer_msgs` | Spectrum message and service definitions. |
| `mr2_system_status` | Python system status publisher using `psutil`. |
| `mr2_video_streaming` | Rover-side GStreamer H.264 RTP/UDP streaming node. |
| `mr2_moveit` | MoveIt and servo configuration for manipulator integration. |
| `ublox_dgnss/*` | u-blox GNSS, UBX message, high-precision NavSatFix, and NTRIP/RTCM support. |
| `rtcm_msgs` | RTCM message type used for correction data. |

## Launch Model

The primary entrypoints live in `mr2_launch/launch`.

| Launch file | Purpose |
| --- | --- |
| `rover.launch.py` | Shared composition root for sim and real modes. Starts system status, robot description, XBEE bridge, optional manipulator, optional autonomy, optional video, YOLO, ArUco, and related modules. |
| `rover_sim.launch.py` | Simulation wrapper around `rover.launch.py` with Gazebo/RViz defaults and XBEE PTY simulation. |
| `rover_real.launch.py` | Real rover wrapper with hardware defaults for CAN, GNSS, NTRIP, LEDs, camera turret, science, and video options. |
| `navigation.launch.py` | Autonomous mission navigation composition. |
| `video_streaming.launch.py` | Starts rover-side video streaming from the central JSON stream map. |
| `xbee_sim.launch.py` | Creates a `socat` PTY pair for simulated XBEE testing. |
| `realsense_rgbd.launch.py` and `front_uvc_camera.launch.py` | Camera bring-up for autonomy and video sources. |
| `ublox_*` launch files | Rover and base GNSS configurations. |

Typical sim bring-up:

```bash
cd mr2-stack/rover/ros2_ws
source install/setup.bash
ros2 launch mr2_launch rover_sim.launch.py
```

Typical real rover bring-up:

```bash
cd mr2-stack/rover/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 launch mr2_launch rover_real.launch.py \
  enable_manipulator_module:=false \
  enable_xbee_sim:=false
```

## Control and Hardware

The rover uses ros2_control to expose joints and controllers for both simulated
and real hardware. `mr2_rover_description` provides the robot model and
controller configuration, while `mr2_can_hardware_interface` connects multiple
CAN device plugins to the controller manager.

CAN-facing packages are deliberately split by responsibility:

- `mr2_can_bus_core` owns common SocketCAN access.
- `mr2_can_hardware_interface` owns the ros2_control system boundary.
- `mr2_devices_ak_servo` and `mr2_devices_output_actuator` translate specific
  actuator firmware protocols into joint state and command interfaces.
- `mr2_led`, `mr2_camera_turret`, and `mr2_battery_monitor` handle device-level
  peripherals that are not modeled as primary drive joints.

Real mode defaults to `can0`. Simulation and bench testing can use `vcan0` or
mock servo nodes depending on the launch arguments.

## Autonomy, Perception, and GNSS

Autonomy centers on `mr2_rover_auto` and `mr2_action_interface`. The Mission
Master consumes mission lists and mission control commands, publishes mission
status, and delegates work to GNSS-only or cover-vision action paths.

Mission-level topics:

| Topic | Type | Direction |
| --- | --- | --- |
| `/mission_list` | `mr2_action_interface/msg/MissionList` | Input to Mission Master. |
| `/mission_control` | `mr2_action_interface/msg/MissionControl` | Pause, resume, abort, and clear-costmap control. |
| `/mission_status` | `mr2_action_interface/msg/MissionStatus` | Mission state, progress, and arrival status. |

Cover-vision missions consume detection topics selected by mission
`detection_method`:

| Detection path | Topic |
| --- | --- |
| ArUco | `cover_vision/object_pose/aruco` |
| YOLO | `cover_vision/object_pose/yolo` |
| Coverage debug path | `cover_vision/coverage_path` |

YOLO perception is implemented by `mr2_yolo_perception/yolo_rgbd_detector.py`.
It reads RGB, depth, and camera-info topics, then publishes class-specific poses
such as `yolo/object_pose/class_0` and optional annotated images.

GNSS support uses the vendored `ublox_dgnss` packages, named rover launch files,
RTCM messages, optional NTRIP, and `robot_localization` map conversion services
such as `/fromLL`.

## Video and Science

Rover video is configured by
`mr2_launch/config/video_streams.json`. Each stream maps one source to one H.264
RTP stream, UDP port, and dashboard stream ID. Sources may be ROS image topics
or direct V4L2 devices. The rover-side `mr2_video_streaming` node encodes and
sends streams to the base station.

Science payload software includes:

- `mr2_panorama` for direct V4L2 panorama capture.
- `mr2_spectrophotometer` and `mr2_spectrophotometer_msgs` for spectrum capture
  services and messages.

## Local Dependencies

After `rosdep install --from-paths src -y --ignore-src --rosdistro humble`, the
workspace still has known manual dependencies:

- `python3 -m pip install ultralytics` for YOLO inference.
- GStreamer development/runtime packages for rover-side video.
- Jetson hardware encoding requires NVIDIA's `nvidia-l4t-gstreamer` package.
