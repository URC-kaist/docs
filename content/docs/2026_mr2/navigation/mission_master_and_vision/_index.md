---
title: "Mission Master and Vision"
weight: 2
draft: false
bookCollapseSection: true
---

# Mission Master and Vision

*Written by Jaeuk Kim in 2026. 03*

## Behavior Trees and Actions: Governing Over Navigation Pipeline

That is a bold title, but it is never brash. Navigation is merely a submodule for *Autonomous* Navigation.
Basically, we want to command the navigation stack, pause and resume as much as we want, but *automated*.
The idea is simple, but implementation does not look straightforward.
But luckily, Nav2 and ROS2 provides us with tools so we can extend further.

### Behavior Trees (of Nav2)

First, I highly advise you to read the behavior tree (BT) tutorial parts in Nav2,
along with some BehaviorTree.cpp documentation to get the gist of it.
You may also refer to Probabilitsic Robotics, if you feel fancy.

When you read the tutorial for BT, you may think it will be a great idea to substitute your finite state machine (FSM) implementation entirely with BT, just to follow the trend. That would be theoretically possible, but development and maintanace-wise, it will be a horrible nightmare.
Quite teasingly, **BT is not suitable for hierarchical exception handling.** More informally, BT sucks with logic control. If you have more logic than just simple progress states, then you must use FSM, which is to use plain coding.

BT is great with structured, predictable, cycled pipeline, such as navigation pipeline; That is exactly how Nav2 is implemented!
First, all the nav2 components are 'brought up', ready to be deployed. And then, the BT tree action kicks in to execute the navigation.
Here, the planner creates path, and controller creates velocity command, and this continues on every tick.

BTs are defined as an xml file, and it is to be invoked externally to do its job, following the description.
By default, Nav2 provides *two* handles for two BT trees, namely NavigateToPose, and NavigateThroughPoses.
We can copy and modify the default setup to be more suitable to our tasks.

### Action Servers (of ROS2)

In *ROS2*, there are topics, services, and then there are actions.
But why the distinction in the first place?

Topics are simple. One publishes and other subscribes. This is to broadcast information for others to process.

Service is more like function calls. One calls a service, and other who hosts that service does its thing and optionally returns.
These kind of implementation can be seen in our CAN interface for LED, or in navsat_transform node, for `toLL` or `fromLL` frame conversions.
They are used in more episodic, instantaneous, and discontinuous scenarios. Their message detail is defined by `.srv` files.

Actions are more enhanced.
Actions are also like function calls, but they are more suitable when the process takes longer time, and requires intermittent monitoring and intervention.
When the action server hosts the action, the process can be invoked, monitored, and intervened by an action client.
Their message detail is defined by `.action` files.

Nav2 components (or 'servers') are all implemented as action servers. (This is not an important detail as they are already exposed as BT nodes for our development.) While so, we implement the mastering, rule-based modules with action servers.

## Behavior Tree Setup

Nav2 provides us with two behavior tree handles by default, namely NavigateToPose and NavigateThroughPoses.

### NavigateToPose

NavigateToPose recieves single goal, and it is considered SUCCESS when the rover reaches the goal. So this will be useful when we want 'to go from A to B'. For further detail, please refer to our implementation, `my_navigate_to_pose.xml`.

### NavigateThroughPoses

NavigateThroughPoses recieves an array of goals, and it is considered SUCCESS when the goal array is exhausted. In default BT implementation, it removes the goal when it reaches it. We further enhance this with RemovePassedGoals Node. For further detail, please refer to our implementation, `my_navigate_through_poses.xml`.

## Action Server Setup

Now we need some entity to invoke the correct BT and pass a goal (or an array of goals) to it.
Here, we can finally program with Autonomous Navigation mission in mind.

The mission can be defined into two categories: "GNSS-only", and "Coverage and Vision".
The former is plain "to go from A to B", while latter requires extra steps and more planning.

### GnssOnly Action Server

GnssOnly recieves a goal coordinate, and invokes NavigateToPose.
The following is the action interface definition, `GnssOnly.action`:

```text
# GnssOnly.action definitions
# Goal - GPS coordinate to navigate to
float64 target_latitude
float64 target_longitude
---
# Result - Final outcome
int32 navigation_result    # 1 = SUCCESS, 0 = NOT SUCCESS
---
# Feedback - BT execution status
int32 bt_status           # 1 = RUNNING, 0 = NOT RUNNING
```

Please refer to full implementation of GnssOnly action node for full detail.

### CoverVision Action Server

CoverVision recieves a goal coordinate, search method, search radius, and object type.
It first invokes NavigateToPose, generates a goal in spiral pattern, and then invokes NavigateThroughPoses.
During the spiral search, when it recieves a pose from the *vision adapter*, it halts navigation and orients the rover to face the object.
The following is the action interface definition, `CoverVision.action`:

```text
# CoverVision.action definitions
# Goal - GPS coordinate, radius, detection method
uint8 detection_method  # 0 = NONE, 1 = ARUCO, 2 = YOLO
float64 target_latitude
float64 target_longitude
float64 target_radius       # in meters
int32 object_type          # optional semantic class or tag id
---
# Result - Final outcome with waypoint completion info
int32 mission_result        # 1 = SUCCESS, 0 = FAILURE
int32 waypoints_completed    # How many waypoints were successfully visited
---
# Feedback - Coverage mission progress
int32 bt_status             # 1 = RUNNING, 0 = NOT_RUNNING
int32 total_waypoints       # Total waypoints generated
int32 current_waypoint_index # Current waypoint being navigated to
```

Please refer to full implementation of CoverVision action node for full detail.

### MissionMaster Action Client

The MissionMaster governs over the GnssOnly and CoverVision action servers as an action client.
For effective commanding and monitoring, we created custom messages, that is MissionList and MissionCommand;

MissionList contains the full description of the Autonomous Mission; Coordinates,


## Object Position Estimation with Vision

### ArUco Tracker

### YOLO and Depth Map

### Integration to CoverVision: Adapter Node

## Wrapup