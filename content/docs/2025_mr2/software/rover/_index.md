---
title: "Rover"
weight: 1
draft: false
bookCollapseSection: true
---
# Rover Software Overview

**The MR2 Rover’s software** is a ROS2Humble–based system that controls the rover’s mobility, sensors, and communications. It is composed of multiple ROS2 packages, each responsible for a specific aspect of the rover’s functionality. The software enables both manual teleoperation via a gamepad and prepares for future autonomous control modes. Key components include motor control nodes for driving, a Dynamixel controller for servo actuators, computer‑vision processing, a battery‑management interface, and communication bridges for a remote dashboard. All these components work together so the rover can be driven remotely and monitored in realtime.

## Main Software Components
- **mr2_drive** – High‑level drive control (DrivingNode&SteeringNode).  
- **mr2_drive_motor** – Low‑level wheel‑motor interface.  
- **mr2_dynamixel** – Dynamixel servo controller.  
- **mr2_jk_bms&mr2_jk_bms_interfaces** – Battery‑management telemetry.  
- **mr2_yolo** – YOLOv8 object‑detection node.  
- **mr2_description** – URDF/SDF robot model.  
- **mr2_gazebo** – Gazebo simulation assets.  
- **mr2_launch** – Launch files for real robot and simulation.  
- **External tools** – `rosbridge_server`, `web_video_server`, `usb_cam`, etc.

## System Architecture
Teleoperation data flow:

```
Gamepad ─▶ DrivingNode ─▶ SteeringNode ─▶ (Wheel speeds) ─▶ MotorMCU
                             │
                             ├─▶ Dynamixel servos (steering / mechanism)
                             └─▶ JointState feedback streams
```

Sensors publish data back to ROS2; a web dashboard connects via **rosbridge** (port 9090) and **web_video_server** (port 8080) for telemetry and camera video.

## NextSteps
*Head to the sub‑pages below for full usage and developer details.*

- [UserGuide]({{<ref"rover_user_guide.md">}})  
- [Developer Docs]({{<ref"rover_developer.md">}})  
- [APIReference]({{<ref"rover_api.md">}})  
