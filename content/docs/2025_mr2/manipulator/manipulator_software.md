---
title: "Manipulator Software"
weight: 1
draft: false
---
# Manipulator Software

This ROS2 workspace includes several packages and configuration files for controlling a robot arm.

## How to Run the Robot Arm

1. **Set the Robot Arm's Initial Position (Required)**  
   - Before powering on, the robot arm must be moved to its initial position.  
   - How to verify the initial position: When running MoveIt without connecting the robot arm, the posture shown in RViz should be at 0 degrees.

   ```bash
   source install/setup.bash
   ros2 launch rover_arm_moveit_config servo.launch.py
   ```

2. **Connect the Xbox Controller**

3. **Set the CAN Communication Bitrate**

   ```bash
   sudo ip link set can0 up type can bitrate 1000000
   ```

4. **Set the Dynamixel (J6) Latency Timer**

   ```bash
   echo 1 | sudo tee /sys/bus/usb-serial/devices/ttyUSB0/latency_timer
   ```

5. **Run the Robot Arm**

   ```bash
   ros2 launch rover_arm_moveit_config servo.launch.py
   ```

## Precautions and Areas for Improvement

- **Risk of J1 Divergence**: For the first run, disconnect the CAN connection (motor power connection is permitted).
- **It is recommended to remove the belts on J4 and J5 before running**  
  - Vibration may occur during the first run.  
  - If the initial position is set incorrectly, J4 and J5 may rotate 360 degrees.
- **If the CAN connection is lost during operation, there is a risk of the robot diverging.**

## Package Summary

| **Package Name**          | **Description**                                |
|---------------------------|------------------------------------------------|
| rover_arm_description     | Contains the robot's URDF model                |
| rover_arm                 | Cylindrical URDF model (currently unused)      |
| rover_arm_moveit_config   | MoveIt configuration and launch package        |
| rover_arm_moveit_cpp      | Contains MoveIt-related C++ nodes              |

## Detailed Package Descriptions

### 1. rover_arm_description

This package contains the robot's URDF model, created using Fusion 360. It includes STL files and collision models.

The originally used  
``fusion2urdf-ros2 <https://github.com/dheena2k2/fusion2urdf-ros2>``  
did not work, so instead the fork from  
``Robotizer-be <https://github.com/Robotizer-be/fusion2urdf-ros2>``  
is used.

**Pre-configuration Required:**

- **Clean Up STL File Names**: Remove phrases such as `(1)`  
  Example: ``link1 (1).stl`` → ``link1.stl``
- **Modify Launch File Paths**: Verify and modify the paths in ``display.launch.py``
- **Add Xacro Macro Call**: Append the following code at the end of the file ``rover_arm_macro.urdf.xacro``

   ```xml
   <xacro:rover_arm prefix=""/>
   ```

- **Fix the Issue with base_link Not Displaying**: Modify the definition of ``base_link``

   ```xml
   <link name="${prefix}base_link">
     <visual>
       <origin xyz="0 0 0" rpy="0 0 0"/>
       <geometry>
         <mesh filename="package://rover_arm_description/meshes/base_link.stl" 
               scale="0.001 0.001 0.001"/>
       </geometry>
       <material name="rover_arm_silver"/>
     </visual>
     <collision>
       <origin xyz="0 0 0" rpy="0 0 0"/>
       <geometry>
         <mesh filename="package://rover_arm_description/meshes/base_link.stl" 
               scale="0.001 0.001 0.001"/>
       </geometry>
     </collision>
   </link>
   ```

**Key Commands:**

- Verify the URDF model:

   ```bash
   ros2 launch rover_arm_description display.launch.py
   ```

### 2. rover_arm (Currently Unused)

This package contains a cylindrical URDF model. (Currently not in use)

**Key Commands:**

- Verify the URDF:

   ```bash
   ros2 launch rover_arm display.launch.py
   ```

- Run the joint angle setting slider for each joint:

   ```bash
   ros2 run joint_state_publisher_gui joint_state_publisher_gui
   ```

### 3. rover_arm_moveit_config

This package is for controlling and configuring the robot arm using MoveIt.

**Key Commands:**

- Run the robot arm with MoveIt:

   ```bash
   ros2 launch rover_arm_moveit_config servo.launch.py
   ```

- Launch the MoveIt configuration:

   ```bash
   source install/setup.bash
   ros2 launch moveit_setup_assistant setup_assistant.launch.py
   ```

- Launch MoveIt and RViz:

   ```bash
   ros2 launch rover_arm_moveit_config demo.launch.py
   ```

**Known Bug:**

- After a new configuration, the limits in the file ``rover_arm_moveit_config/config/joint_limits.yaml`` must be modified to decimal format.  
  For example: change ``1`` to ``1.0``.

### 4. rover_arm_moveit_cpp

This package contains MoveIt-related C++ nodes.

**Key Command:**

   ```bash
   ros2 run rover_arm_moveit_cpp hello_moveit
   ```
