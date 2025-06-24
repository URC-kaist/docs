---
title: "Developer Documentation"
weight: 3
draft: false
---
# Rover Software Developer Documentation

This section details the code‑base structure, node interfaces, parameters, and contribution workflow.

## Packages
| Package | Summary |
|---------|---------|
| **mr2_drive** | High‑level DrivingNode / SteeringNode (C++) |
| **mr2_drive_motor** | Serial bridge to wheel‑motor MCU (C++) |
| **mr2_dynamixel** | Dynamixel servo controller (C++) |
| **mr2_jk_bms** | BMS telemetry node (Python) |
| **mr2_yolo** | YOLOv8 vision node (Python) |
| **mr2_description** | URDF/SDF robot model |
| **mr2_gazebo** | Gazebo world & launch |
| **mr2_launch** | Bring‑up & sim launch files |

### Example – DrivingNode ► interfaces
```text
Sub: /gamepad  (sensor_msgs/Joy)
Pub: /driving_node/target_twist  (geometry_msgs/Twist)
Pub: /driving_node/current_twist (geometry_msgs/Twist)
Srv: /driving_node/switch_mode   (std_srvs/SetBool)
```
Parameters include `throttle_index`, `max_vx`, `control_interval`, etc.

### Motor Serial Protocol
```text
Header0xAA55|len|mode|id|4×float|CRC16  
Modes:1=SET_SPEED,2=GET_SPEED,3=SET_PID.
```

## Contributing
1. Create a feature branch and follow ROS2 coding style.  
2. Run `colcon test` (amentlint, gtest).  
3. Test in Gazebo before hardware.  
4. Submit a PR with updated docs.  

Safety: implement an E‑Stop, respect `throttle_timeout`, and test motors off‑ground first.
