---
title: "Manipulator Hardware"
weight: 1
draft: false
---
# Manipulator Hardware

## Overview
The manipulator developed for the 2025 competition was engineered around three primary objectives:

1. **Workspace Radius**: Achieve a spherical workspace with a minimum radius of 0.8 meters.  
2. **Payload Capacity**: Support a maximum payload of 5 kg.  
3. **Low Inertia**: Minimize the overall moment of inertia for improved responsiveness.

By focusing on these targets, the design balanced operational performance with compact stowage and lightweight construction.

## Design Architecture

### Link Structure and Materials
- **Primary Links (L1 & L2)**: Constructed from dual 400 mm carbon fiber tubes acting as the backbone, with 3D-printed polymer modules affixed for joint interfaces.
- **Offset Hinge Mechanism**: Allows both main links to fold completely for efficient storage without sacrificing stiffness in the extended configuration.
- **Belt-Driven Actuation for J3**: Utilizes timing belts to transmit torque from base-mounted motors, reducing distal mass and inertia.
- **Motor Cluster**: Joints J1 through J3 are powered by motors mounted near the base plate to concentrate mass and lower rotational inertia of the extended arm.

### Transmission and Actuators
- **J2 & J3 Gearboxes**:
  - Custom 1:16 planetary gearbox fabricated in-house.
  - 1:47 compound planetary gearbox (3-stage) for high torque density.
- **Motor Selection**:
  - **J1–J3**: CubeMars AK80-8, daisy-chained over CAN bus.
  - **J4–J5**: CubeMars AK60-6, daisy-chained via CAN.
  - **J6**: Robotis RX-64, interfaced with U2D2 adapter for CAN connectivity.

### End Effector Suite
- **Gripper Motor**: Dedicated DC motor for part manipulation.
- **Visual Sensors**: High-resolution camera mounted to provide multiple viewing angles of the workpiece.
- **Distance Sensing**: Infrared rangefinder to measure proximity to panels or objects.
- **Actuation Mechanism**: Rack-and-pinion assembly designed for precise keyboard key depression tasks.
- **Control Electronics**: Additional STM32 microcontroller board integrated on the end effector, communicating via CAN bus in daisy-chain topology.

## Performance Highlights
In live demonstrations and competition trials, the manipulator successfully transported and positioned a 5 kg toolbox, meeting the specified payload requirement with margin.

## Identified Challenges and Lessons Learned

1. **Motor and Gearbox Mismatch**  
   Initial use of AK80-8 motors at 24 V (rated for 48 V operation) in direct-drive configuration led to insufficient torque and frequent overcurrent shutdowns.  
   **Mitigation**: Designed and installed custom gearboxes mid-development. Future iterations will adopt industrial-grade harmonic drive units for compactness and high efficiency.

2. **Structural Deformation**  
   Rapid prototyping via PLA 3D printing (100% infill) caused deformation and cracking under high torque loads around the J2 joint. Timing belt attachment points near J3 also exhibited plastic creep and belt slippage.  
   **Mitigation**: Critical high-load components will be CNC-machined from aluminum alloy in the revised design. A rigid link-based power transmission architecture will replace belt drives where feasible.

3. **End Effector Mass Excess**  
   The initial gripper assembly was disproportionately large and heavy, overloading J4 and J5 actuators and increasing overall arm inertia.  
   **Mitigation**: Redesign the end effector with lightweight materials and a more streamlined geometry to reduce mass without compromising functionality.

## Future Development Roadmap
1. **Harmonic Drive Integration**: Implement precision harmonic reducers to achieve high torque-to-weight ratios and minimal backlash.  
2. **CNC Machining of Critical Parts**: Manufacture load-bearing joints and link interfaces from milled aluminum or steel to enhance stiffness and fatigue life.  
3. **End Effector Optimization**: Simplify the gripper and sensor assembly, exploring carbon fiber or composite materials to lower mass and inertia.
