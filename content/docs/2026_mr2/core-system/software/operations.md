---
title: "Operations"
weight: 6
draft: false
---

# Operations

This page collects the main setup, build, launch, and troubleshooting paths for
the 2026 MR2 software stack.

## Initial Setup

Clone or enter `mr2-stack`, then install dependencies by subsystem.

Rover ROS dependencies:

```bash
cd mr2-stack/rover/ros2_ws
rosdep install --from-paths src -y --ignore-src --rosdistro humble
python3 -m pip install ultralytics
```

Rover video dependencies:

```bash
sudo apt install -y \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-tools \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-plugins-bad
```

On Jetson, hardware H.264 encoding also requires:

```bash
sudo apt install -y nvidia-l4t-gstreamer
```

Base gateway:

```bash
cd mr2-stack/base/gateway
npm install
```

Dashboard:

```bash
cd mr2-stack/dashboard
npm install
cp .env.local.example .env.local
```

## Build and Check

Build the ROS workspace:

```bash
cd mr2-stack/rover/ros2_ws
source /opt/ros/humble/setup.bash
colcon build
```

Run gateway tests:

```bash
cd mr2-stack/base/gateway
npm test
```

Run dashboard checks:

```bash
cd mr2-stack/dashboard
npm run check
```

## Simulation Bring-Up

Start the simulated rover:

```bash
cd mr2-stack/rover/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 launch mr2_launch rover_sim.launch.py
```

The simulation path creates an XBEE PTY pair by default:

| Device | Meaning |
| --- | --- |
| `/tmp/xbee_sim0` | Device opened by the rover XBEE bridge. |
| `/tmp/xbee_sim1` | Peer device for external tools or the base gateway. |

Run the base gateway against the simulated peer:

```bash
cd mr2-stack/base/gateway
npm start -- --base-xbee-device /tmp/xbee_sim1 --gateway-port 8081
```

## Real Rover Bring-Up

Start the real rover with default CAN and real XBEE:

```bash
cd mr2-stack/rover/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 launch mr2_launch rover_real.launch.py \
  enable_manipulator_module:=false \
  enable_xbee_sim:=false
```

Common launch options:

| Argument | Default | Purpose |
| --- | --- | --- |
| `can_iface` | `can0` | Rover CAN interface. |
| `enable_manipulator_module` | `true` in real wrapper | Enables manipulator URDF, ros2_control, and MoveIt components. |
| `enable_autonomous_module` | `true` | Enables RealSense, front camera, autonomy, perception, and navigation-related modules. |
| `enable_science_module` | `false` | Enables science module panorama server. |
| `enable_video_streaming` | `false` | Starts rover-side H.264 RTP video streaming. |
| `video_base_host` | `MR2_BASE_IP` | Base host for UDP video streams. |
| `enable_ntrip` | `false` | Starts NTRIP client for RTCM corrections. |
| `enable_led` | `true` | Starts the LED CAN node. |
| `enable_camera_turret` | `true` | Starts the camera turret CAN node. |

## Base Station Bring-Up

Start the gateway:

```bash
cd mr2-stack/base/gateway
npm start -- \
  --base-xbee-device /dev/ttyXBEE \
  --gateway-port 8081
```

With antenna tracking:

```bash
npm start -- \
  --base-xbee-device /dev/ttyXBEE \
  --gateway-port 8081 \
  --antenna-enable true \
  --antenna-device /dev/ttyARDUINO
```

With video:

```bash
npm start -- \
  --base-xbee-device /dev/ttyXBEE \
  --gateway-port 8081 \
  --video-config ../../rover/ros2_ws/src/mr2_launch/config/video_streams.json
```

Deploy the dashboard through nginx:

```bash
cd mr2-stack/scripts
. deploy_dashboard.bash
```

## Quick Runtime Checks

CAN:

```bash
ip link show can0
```

Battery:

```bash
cd mr2-stack/scripts
./check_battery_status.bash
```

Mission Master:

```bash
ros2 topic echo /mission_status
ros2 topic hz /mission_status
```

GNSS map conversion:

```bash
ros2 service list | rg fromLL
ros2 service call /fromLL robot_localization/srv/FromLL \
  "{ll_point: {latitude: 38.5, longitude: -110.8, altitude: 0.0}}"
```

YOLO:

```bash
ros2 param get /yolo_rgbd_detector rgb_topic
ros2 topic echo /yolo/object_pose/class_0
```

Video dependencies:

```bash
gst-inspect-1.0 h264parse
gst-inspect-1.0 nvv4l2h264enc
gst-inspect-1.0 nvvidconv
```

## Known Troubleshooting

If OpenCV packages on Jetson are mismatched, ROS builds can fail with CMake
targets pointing at removed OpenCV 4.8 files. The recorded recovery path is:

```bash
sudo apt remove -y opencv-licenses
sudo dpkg --configure -a
sudo apt --fix-broken install -y
sudo apt install -y --allow-downgrades libopencv-dev=4.5.4+dfsg-9ubuntu4
```

Then rebuild the affected package:

```bash
cd mr2-stack/rover/ros2_ws
rm -rf build/mr2_rover_auto install/mr2_rover_auto
source /opt/ros/humble/setup.bash
colcon build --packages-select mr2_rover_auto
```
