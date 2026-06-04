---
title: "Manipulator"
weight: 3
draft: false
bookCollapseSection: true
---

# Manipulator

The 2026 manipulator software is implemented in the rover ROS 2 workspace. It
uses a URDF/Xacro model, ros2_control position controllers, CAN device plugins
for the real actuators, and MoveIt Servo for Cartesian or joint jog commands.

## System Overview

```text
Dashboard / MoveIt Servo / direct ROS command
  -> manipulator_controller or gripper_controller
  -> mr2_can_hardware_interface
  -> AK servo or output actuator CAN firmware
  -> joint state feedback
```

The manipulator can be launched as part of the full rover or as a standalone
bench target. Real hardware uses `can0` by default; mock AK servo nodes are
available for testing controller wiring without motors.

## Packages and Files

| Package or file | Purpose |
| --- | --- |
| `mr2_rover_description/urdf/manipulator.xacro` | Six-axis arm and gripper model, joint limits, visual meshes, collision geometry, and end-effector frame. |
| `mr2_rover_description/ros2_control/rover_can.ros2_control.xacro` | Real hardware ros2_control mappings for rover drive, arm joints, and gripper. |
| `mr2_rover_description/config/controllers/*.yaml` | Controller manager and position controller configuration. |
| `mr2_devices_ak_servo` | CAN device plugin for AK servo joints plus a mock servo node. |
| `mr2_devices_output_actuator` | CAN device plugin used by the gripper output actuator. |
| `mr2_can_hardware_interface` | ros2_control `SystemInterface` that loads the CAN device plugins. |
| `mr2_moveit` | MoveIt SRDF, kinematics, joint limits, RViz launch, and MoveIt Servo configuration. |

## Robot Model

The manipulator model defines six revolute arm joints from `base_link` to
`eef_link`, plus a revolute gripper joint.

| Joint | Parent to child | Axis | Limit |
| --- | --- | --- | --- |
| `arm_j1` | `base_link` to `arm_l1` | Z | `-pi` to `pi` |
| `arm_j2` | `arm_l1` to `arm_l2` | Y | `-0.785` to `1.571` rad |
| `arm_j3` | `arm_l2` to `arm_l3` | Y | `-1.745` to `0.0` rad |
| `arm_j4` | `arm_l3` to `arm_l4` | Z | `-3.491` to `3.491` rad |
| `arm_j5` | `arm_l4` to `arm_l5` | Y | `0.0` to `3.491` rad |
| `arm_j6` | `arm_l5` to `arm_l6` | X | `-pi` to `pi` |
| `arm_gripper` | `eef_link` to `gripper_link` | Z | `0.0` to `1.309` rad |

MoveIt defines:

| MoveIt item | Value |
| --- | --- |
| Planning group | `manipulator` |
| Planning chain | `base_link` to `eef_link` |
| End-effector group | `eef` |
| End-effector link | `eef_link` |
| Virtual joint | Fixed `map` to `base_link` |
| Kinematics solver | `kdl_kinematics_plugin/KDLKinematicsPlugin` |

## ros2_control

The full rover controller config defines these controllers:

| Controller | Type | Purpose |
| --- | --- | --- |
| `joint_state_broadcaster` | `joint_state_broadcaster/JointStateBroadcaster` | Publishes joint states at 50 Hz. |
| `rover_controller` | `mr2_rover_control/TwistToCommandsController` | Drives the rover base. |
| `manipulator_controller` | `position_controllers/JointGroupPositionController` | Commands `arm_j1` through `arm_j6` in position mode. |
| `gripper_controller` | `position_controllers/JointGroupPositionController` | Commands `arm_gripper` in position mode. |

The standalone manipulator controller config uses the same pattern, with
`manipulator_controller` for arm joints and `gripper_position_controller` for
`arm_gripper`.

Real CAN mapping:

| Joint | Device plugin | Hardware ID | Origin offset |
| --- | --- | --- | --- |
| `arm_j1` | `mr2_devices_ak_servo/AkServoDevice` | motor `101` | `0.0` |
| `arm_j2` | `mr2_devices_ak_servo/AkServoDevice` | motor `102` | `0.0` |
| `arm_j3` | `mr2_devices_ak_servo/AkServoDevice` | motor `103` | `-0.7853981634` |
| `arm_j4` | `mr2_devices_ak_servo/AkServoDevice` | motor `104` | `0.0` |
| `arm_j5` | `mr2_devices_ak_servo/AkServoDevice` | motor `105` | `2.3561944902` |
| `arm_j6` | `mr2_devices_ak_servo/AkServoDevice` | motor `106` | `0.0` |
| `arm_gripper` | `mr2_devices_output_actuator/OutputActuatorDevice` | node `9` | direct angle input |

The AK servo plugin exports position, velocity, and effort state interfaces and
a position command interface. It sends extended CAN command frames and expects a
live status stream; missing or stalled status frames trigger timeout handling.
The output actuator plugin uses the NoFW-style standard-ID frame families for
angle, velocity, profile, power, limits, config, and runtime diagnostics.

## Launching

Manipulator enabled in full real rover bring-up:

```bash
cd mr2-stack/rover/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 launch mr2_launch rover_real.launch.py \
  enable_manipulator_module:=true \
  can_iface:=can0
```

Standalone manipulator CAN bring-up:

```bash
cd mr2-stack/rover/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 launch mr2_rover_description manipulator_ak_can.launch.py can_iface:=can0
```

Standalone with mock AK servos:

```bash
ros2 launch mr2_rover_description manipulator_ak_can.launch.py \
  can_iface:=vcan0 \
  use_mock_servos:=true
```

The full real rover launch spawns `joint_state_broadcaster` and
`rover_controller` first, then spawns `manipulator_controller` and
`gripper_controller` inactive. Activate the controllers only after the robot and
hardware feedback are in a known safe state.

## MoveIt Servo

MoveIt configuration is in `mr2_moveit`.

| File | Purpose |
| --- | --- |
| `config/rover.srdf` | Planning groups, end-effector group, virtual joint, passive joints, and disabled collisions. |
| `config/kinematics.yaml` | KDL solver configuration for the `manipulator` group. |
| `config/joint_limits.yaml` | MoveIt joint limits and conservative scaling defaults. |
| `config/servo.yaml` | MoveIt Servo realtime command behavior. |
| `launch/moveit_rviz.launch.py` | MoveIt RViz visualization. |
| `launch/realtime_servo.launch.py` | Starts `moveit_servo` and calls `/moveit_servo/start_servo`. |

Servo command settings:

| Setting | Value |
| --- | --- |
| Publish period | `0.02` s, or 50 Hz. |
| Command input type | `speed_units`. |
| Cartesian command topic | `~/delta_twist_cmds`. |
| Joint command topic | `~/delta_joint_cmds`. |
| Output topic | `/manipulator_controller/commands`. |
| Output message | `std_msgs/Float64MultiArray`. |
| Planning frame | `base_link`. |
| End-effector frame | `eef_link`. |
| Collision checking | Enabled at 10 Hz. |
| Smoothing | Butterworth online signal smoothing. |

Start Servo:

```bash
ros2 launch mr2_moveit realtime_servo.launch.py
```

Open MoveIt RViz:

```bash
ros2 launch mr2_moveit moveit_rviz.launch.py
```

## Manual Commands and Checks

List and inspect controllers:

```bash
ros2 control list_controllers
ros2 control list_hardware_interfaces
ros2 topic echo /joint_states
```

Send a direct arm position command:

```bash
ros2 topic pub --once /manipulator_controller/commands std_msgs/msg/Float64MultiArray \
  "{data: [0.0, 0.0, -0.5, 0.0, 1.0, 0.0]}"
```

Send a direct gripper command:

```bash
ros2 topic pub --once /gripper_controller/commands std_msgs/msg/Float64MultiArray \
  "{data: [0.4]}"
```

For the standalone manipulator launch, use
`/gripper_position_controller/commands` instead.

Monitor AK servo temperatures:

```bash
ros2 topic list | rg 'ak_servo/.*/temperature'
```

## Safety Notes

- Keep controllers inactive until CAN status feedback is present and joint
  positions look reasonable.
- Confirm `can0` or `vcan0` is up before launching hardware interfaces.
- Use mock servos or a disabled drivetrain when validating MoveIt commands.
- MoveIt Servo publishes directly to `/manipulator_controller/commands`; there
  is no FollowJointTrajectory controller for Servo to manage in this setup.
