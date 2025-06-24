---
title: "API Reference"
weight: 4
draft: false
---
# Rover Software API Reference

## Custom Messages
### `mr2_drive_motor/msg/Pid`
```plaintext
float32 p
float32 i
float32 d
float32 a
```
PID controller gains.

### `mr2_jk_bms_interfaces/msg/BMSData`
```plaintext
std_msgs/Header header
float32[] cell_voltages
float32 temperature_fet
float32 temperature_probe_1
float32 temperature_probe_2
float32 global_voltage
float32 current
uint8   capacity
```

## CustomServices
### `mr2_drive_motor/srv/PidParams`
```plaintext
float32 p
float32 i
float32 d
float32 a
---
bool success
```

## Key Topics & Services (Major)
| Name | Type | Provider |
|------|------|----------|
| `/gamepad` | sensor_msgs/Joy | joy_node |
| `/driving_node/target_twist` | geometry_msgs/Twist | DrivingNode |
| `/steering_node/joint_states` | sensor_msgs/JointState | SteeringNode |
| `/mr2_drive_motor_interface/current_speed` | sensor_msgs/JointState | MotorInterface |
| `/bms_metrics` | *BMSData | BMSNode |
| `/set_pid_params` | *PidParams (srv) | MotorInterface |

