---
title: "Mission Master and Vision"
weight: 2
draft: false
bookCollapseSection: true
---

# Mission Master and Vision

*Written by Jaeuk Kim in 2026. 03*

[한국어]({{< ref "docs/2026_mr2/navigation/ko/mission_master_and_vision.md" >}})

> These explanations were written by Jaeuk Kim around March 2026, before he left the team. They describe the design at that time and may not reflect later implementation changes. Only minor factual and conceptual corrections have been made for this publication; these chapters have not been updated to match the current implementation.

*Minor corrections: November 25, 2026.*

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

Service is more like function calls. One sends a request, and the service server processes it and returns a response, whose fields may be empty. The client can handle the response asynchronously.
These kind of implementation can be seen in our CAN interface for LED, or in navsat_transform node, for `toLL` or `fromLL` frame conversions.
They are used in more episodic, instantaneous, and discontinuous scenarios. Their message detail is defined by `.srv` files.

Actions are more enhanced.
Actions are also like function calls, but they are more suitable when the process takes longer time, and requires intermittent monitoring and intervention.
When the action server hosts the action, the process can be invoked, monitored, and intervened by an action client.
Their message detail is defined by `.action` files.

Nav2 exposes tasks such as planning and path following through action servers; other components also use services and topics. (The navigation actions are already exposed as BT nodes for our development.) While so, we implement the mastering, rule-based modules with action servers.

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
During the spiral search, when it recieves a pose from the *vision adapter*, it halts NavigateThroughPoses and orients the rover to face the object by invoking NavigateToPose.
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

### MissionMaster Node

The MissionMaster governs over the GnssOnly and CoverVision action servers as an action client.
We will look through its interface between base station and MissionMaster.
For effective control and command, we created custom message types: MissionList, MissionControl, and MissionStatus.

MissionList is an array of MissionSpec for each Autonomous Mission.

```text
# Mission specification for Mission Master
# mission_type: 0=UNKNOWN, 1=GNSS_ONLY, 2=COVER_VISION
# detection_method: 0=NONE, 1=ARUCO, 2=YOLO
# object_type (used by YOLO): 0=MALLET, 1=PICK, 2=BOTTLE
uint32 mission_id
uint8 mission_type
uint8 detection_method
int32 object_type

# WGS84 target (required for GNSS_ONLY and COVER_VISION)
float64 target_latitude
float64 target_longitude

# Coverage parameters (used by COVER_VISION)
float64 target_radius
uint32 waypoint_count
```

MissionControl is a command interface. It is implemented as topic and not a service, since we monitor its state with MissionStatus.
MissionControl topic uses SiK bridge for most reliable command and control.

```text
# Command channel for Mission Master
# command: 0=NOOP, 1=PAUSE, 2=RESUME, 3=ABORT
uint8 command

# Optional: clear costmaps when pausing or aborting
bool clear_costmap

# Optional: target mission id (0 = current mission)
uint32 mission_id
```

MissionStatus is a periodic report of the mission progress and status.

- `mission_status_led_node` of mr2_led package is subscribed to this topic to call the LED service.
Refer to `mr2_led/README.md` to see the full protocol on how LED node handles it.
- `twist_to_commands_controller` also listens to this topic for `/cmd_vel` multiplexing; if it is not RUNNING, it will listen to `/base/cmd_vel` for manual operation.

```text
# Mission Master status report
# state: 0=IDLE, 1=RUNNING, 2=PAUSED, 3=COMPLETED, 4=FAILED
builtin_interfaces/Time stamp
MissionSpec active_mission
uint8 state
bool arrival

# Coverage progress (optional)
uint32 current_waypoint_index
uint32 total_waypoints

# Nav2 feedback (meters). Use negative if unknown.
float32 distance_remaining

# Optional human-readable detail or error
string detail
```

Mission Master executes either GnssOnly or CoverVision going through the MissionList; It passes the mission details for each action servers to work. Mission Master can resume or pause, and send additional commands such as clearing costmaps.
It reports `arrival == true` for ten seconds when it finishes a mission, and reports COMPLETED when the mission list is exhausted.
PAUSED is reserved for manual teleoperation, and FAILED is invoked when we send ABORT command, or when the navigation stack fails.

## Object Position Estimation with Vision

This section will talk about how the vision pipeline works, from sensors up to CoverVision.
Layer-wise, the vision pipeline is in same level with Nav2, but it is structurally less complex so it is explained here.

Structurally, it follows the following pipeline:

1. Estimate the object position in sensor frame
2. Convert the position information into map frame
3. Filter the position estimation

### ArUco Tracker

For ArUco input, we use `front_uvc_camera.launch.py` to launch `v4l2_camera_node` and connect to `front_camera`.
Here we get `/image_raw` topic as input.

We use OpenCV ArUco Tracker library to estimate the pose of ArUco tags.
It does not require depth information as the ArUco marks exists with known dimension.
The ArUco Tracker node publishes a topic in [`aruco_opencv_msgs/msg/arucodetection`](https://docs.ros.org/en/kilted/p/aruco_opencv_msgs/msg/ArucoDetection.html) type, so it needs to be unpacked to be properly processed. This is done by `cover_vision_aruco_adapter` node.

### YOLO and Depth Map

For YOLO and depth (and IMU), we use `realsense_rgbd.launch.py` to launch `realsense2_camera_node` and connect to `rgbd_camera`.
Here we get `/color/image_raw` topic for bbox inference, and  `/aligned_depth_to_color/image_raw` topic for depth map as input.

Fine-tuned YOLO11 is used for 2D object detection.
But this will only give us the bounding box in projected camera frame, so we also incorporate the depth map data. By polling the center pixel of the bounding box, we estimate the depth of the object. This assumes the sampled depth belongs to the object; the center may instead fall on the background or ground and give an incorrect object distance.

If full localization is available, the object position is published in sensor frame. Since there are three types of objects, the node publishes three types of topic per object.
This is gated and processed by the `cover_vision_yolo_adapter` node.

### Integration to CoverVision: Adapter Nodes

The role of each adapter node is to unpack, gate and filter the incoming topics, and produce the final pose of the object in `map` frame for the CoverVision to consume.
The two can be configured independently. They support:

1. Distance gating: If the object is too far away, we ignore the input because it is likely that it was noise.
2. Jump gating: If the new smoothed object position is farther than the threshold from the previous published position, suppress the new publication and retain the previous published position as the reference. This is an imperfect heuristic against false positives.
3. Smoothing: The position is window-smoothed.

## Wrapup

Now let's see everything in a hierarchical manner, from the base station to the navigation stack and vision modules.

1. The base station directly communicates to MissionMaster to send mission lists, commands. The MissionMaster publishes the mission state.
2. The MissionMaster goes through the mission list, and invokes GnssOnly or CoverVision depending on mission type, and passes arguments.
3. GnssOnly invokes NavigateToPose to navigate to the coordinate. It reports SUCCESS when it reaches the goal.
4. CoverVision invokes NavigateToPose to move to the site, create goals in spiral pattern, and invokes NavigateThroughPoses. It aborts the navigation when vision adapter reports the filtered object position, and invokes NavigateToPose to orient the rover toward the object. It reports SUCCESS when the rover orients to the object, or when the rover completes the spiral pattern.
5. The MissionMaster reports `arrival==true` per mission SUCCESS, and reports SUCCESS by itself when the mission list is exhausted.
