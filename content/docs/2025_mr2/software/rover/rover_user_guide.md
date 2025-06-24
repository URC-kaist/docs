---
title: "User Guide"
weight: 2
draft: false
---
# Rover Software User Guide

This guide explains how to **install, configure, launch, and operate** the MR2 rover software, both on hardware and in simulation. Sections include prerequisites, building the workspace, one‑time system configuration, running on the real rover, running in Gazebo, teleoperation controls, and troubleshooting.

## 1. Installation & Setup
1. **Prerequisites:** Ubuntu 22.04 LTS + ROS 2 Humble.  
2. **Clone workspace:** `git clone https://github.com/URC-kaist/ros2_ws ~/ros2_ws`  
3. **Install dependencies:**  
   ```bash
   cd ~/ros2_ws
   rosdep install --from-paths src --ignore-src -r -y
   ```
4. **Build:** `colcon build --symlink-install` → then `source install/local_setup.bash`  
5. **Serial permissions:** `sudo usermod -a -G dialout $USER` (re‑login).  
6. *(Optional)* Enable hotspot, startup service, Wake‑on‑LAN, or RT kernel as needed.

## 2. Launching
### 2.1 Real Rover
```bash
source /opt/ros/humble/setup.bash
source ~/ros2_ws/install/local_setup.bash
ros2 run joy joy_node          # joystick driver
ros2 launch mr2_launch real_launch.py
```
The launch file starts drive, motor, servo, camera, BMS, rosbridge, and video nodes.

### 2.2 Simulation (Gazebo)
```bash
ros2 launch mr2_launch mr2_launch.py   # starts Gazebo + bridge
ros2 launch mr2_launch real_launch.py  # (in new terminal) start high‑level nodes
```
Teleoperate with the same joystick or keyboard teleop.

## 3. Teleoperation
Default mappings (Xbox‑style):

| Control | Axis/Button | Function |
|---------|--------------|----------|
| RT      | axis 5        | Throttle(+vx) |
| LT      | axis 4        | Brake / reverse |
| Left‑stick H | axis 0   | Steering (ω) |
| **Modeswitch** | service `/driving_node/switch_mode` | Manual ↔ Autonomous |

## 4Troubleshooting
- **No joystick:** ensure `joy_node` topic `/gamepad` publishes.  
- **No movement:** check MotorInterface logs, serial port name, wheel JointState.  
- **No video:** verify `usb_cam` topic and browse `http://<ip>:8080/stream?topic=/image_raw`.  
- **Battery data empty:** confirm BMS serial port (`/dev/ttyUSB1`) and CRC logs.  

See the Developer Docs for deeper diagnostics.
