---
title: "Navigation"
weight: 2
draft: false
bookCollapseSection: true
---

# Navigation

The 2026 navigation stack is implemented in `mr2-stack/rover/ros2_ws/src` and
centers on the `mr2_rover_auto` and `mr2_nav2_plugins` ROS 2 packages. It
combines GNSS/IMU/wheel localization, Nav2 planning and control, a depth-based
traversability costmap layer, and mission-level action servers for GNSS-only and
cover-vision tasks.

## System Overview

```text
Sensors and state
  -> robot_localization / GNSS heading / NavSat transform
  -> Nav2 map, planners, controller, and costmaps
  -> Mission Master and action servers
  -> rover_controller /cmd_vel path
```

The navigation stack assumes the rover base bring-up is already running so
`robot_state_publisher`, ros2_control, wheel odometry, cameras, GNSS, and the
XBEE bridge are available.

## Packages and Files

| Package or file | Purpose |
| --- | --- |
| `mr2_rover_auto` | Launch, config, mission/action servers, localization helpers, map conversion, and traversability pipeline nodes. |
| `mr2_nav2_plugins` | Custom Nav2 `TraversabilityLayer` costmap plugin. |
| `mr2_action_interface` | Mission list, mission control, mission status, and navigation actions. |
| `ublox_dgnss` | u-blox GNSS, RTCM, NTRIP, and high-precision NavSatFix support. |
| `mr2_yolo_perception` | RGB-D object pose detection for cover-vision missions. |
| `mr2_launch` | Top-level rover launch integration and camera/perception enable flags. |

## Launch Entry Points

| Launch file | Role |
| --- | --- |
| `mr2_rover_auto/launch/navigation.launch.py` | Main navigation composition: traversability pipeline, Nav2, mission/action servers, and path-to-GeoPath conversion. |
| `mr2_rover_auto/launch/localization.launch.py` | Dual-GNSS heading, NavSat transform, local EKF, global EKF, and real-robot datum handling. |
| `mr2_rover_auto/launch/nav2.launch.py` | Modified Nav2 bring-up using MR2 maps, behavior trees, and `nav2_params.yaml`. |
| `mr2_rover_auto/launch/action.launch.py` | Starts `gnss_only_server`, `cover_vision_server`, YOLO/ArUco adapters, `mission_master`, and `map_cropper`. |
| `mr2_rover_auto/launch/traversability_pipeline.launch.py` | Starts pointcloud-to-heightmap and grid-map filter nodes. |
| `mr2_rover_auto/launch/path_to_geopath.launch.py` | Converts map-frame paths to WGS84 `GeoPath` topics for dashboard rendering. |

Typical launch:

```bash
cd mr2-stack/rover/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 launch mr2_rover_auto navigation.launch.py mode:=sim
```

For real field runs, bring up the rover first with `mr2_launch rover_real`, then
run navigation with `mode:=real` or `use_sim_time:=false`.

## Localization

`localization.launch.py` provides the transform and odometry backbone for Nav2.

| Node | Purpose |
| --- | --- |
| `gps_heading_gps_node` | Computes rover yaw from dual-GNSS baseline and publishes it into the GPS odometry path. |
| `base_datum_setter` | In real mode, sets `navsat_transform` datum from base station survey-in, with provisional/fix fallback options. |
| `navsat_transform_node` | Converts GNSS fixes into `/odometry/gps/raw` and exposes map/WGS84 conversion services. |
| `ekf_local` | Publishes the local odometry estimate and `odom -> base_link` transform. |
| `ekf_global` | Publishes the global estimate and `map -> odom` transform. |
| `d435i_filter` | Real mode IMU filter for the RealSense D435i IMU frame. |

Primary topics and services:

| Name | Use |
| --- | --- |
| `/left_gnss/navsat` | Default GNSS fix input. |
| `/odometry/gps/raw` | NavSat transform output. |
| `/odometry/filtered/local` | Local EKF output. |
| `/odometry/filtered/global` | Global EKF output. |
| `/navsat_transform/datum` | Datum service, used by base datum setter. |
| `/fromLL` and `/toLL` | WGS84/map coordinate conversion services used by missions and dashboard tooling. |

## Nav2 Configuration

`nav2_params.yaml` is based on Nav2 bring-up parameters with MR2-specific
controllers, maps, behavior trees, costmaps, planners, and velocity limits.

Important defaults:

| Area | Configuration |
| --- | --- |
| Frames | `map`, `odom`, and `base_link`. |
| Controller | MPPI `FollowPath` controller at 10 Hz. |
| Velocity limits | Max `[0.8, 0.6, 0.9]` for x, y, yaw; min x is `-0.35`. |
| Goal checker | `SimpleGoalChecker` with `xy_goal_tolerance: 0.4` and `yaw_goal_tolerance: 0.05`. |
| Local costmap | Rolling 8 m by 8 m costmap at 0.1 m resolution. |
| Global costmap | Static map plus traversability at 0.4 m resolution. |
| Planners | Navfn, Smac 2D, Smac Hybrid, and Theta Star plugins are configured. |
| Behavior trees | `my_navigate_to_pose.xml` and `my_navigate_through_poses.xml`. |

The Nav2 launch rewrites map and behavior-tree paths at launch time so the stack
can use package-installed paths instead of hard-coded development paths.

## Traversability Pipeline

The traversability path turns RealSense depth into costmap data:

```text
/rgbd_camera/depth/color/points
  -> pc2_to_heightmap_node
  -> /height_gridmap
  -> grid_map_filters
  -> /traversability_gridmap
  -> mr2_nav2_plugins::TraversabilityLayer
  -> local/global Nav2 costmaps
```

`trav_pipeline.yaml` configures:

| Stage | Behavior |
| --- | --- |
| Pointcloud heightmap | Uses `base_link` frame, 3.0 m forward by 4.0 m width, 0.1 m resolution, and 6 Hz publish rate. |
| Inpainting and smoothing | Fills missing elevation cells and smooths local height noise. |
| Surface normals | Estimates slope from elevation. |
| Roughness | Compares inpainted elevation to smoothed elevation. |
| Traversability | Combines slope and roughness into a 0 to 1 layer, then clamps the range. |

The custom `TraversabilityLayer` subscribes to `/traversability_gridmap`, reads
the `traversability` layer, follows the `rgbd_camera` rectangle of interest,
clears the robot footprint, and merges data into Nav2 using `max`, `ema`, or
`overwrite` persistence modes.

## Mission and Cover Vision

Mission-level navigation is handled by `mission_master` and action servers from
`action.launch.py`.

| Component | Purpose |
| --- | --- |
| `mission_master` | Consumes mission lists/control messages and publishes mission state. |
| `gnss_only_server` | Executes WGS84 goal missions through Nav2. |
| `cover_vision_server` | Generates spiral coverage paths around a target area and navigates until a target object is detected. |
| `cover_vision_yolo_adapter` | Converts class-specific YOLO poses into the mission-level YOLO detection topic. |
| `cover_vision_aruco_adapter` | Converts `aruco_opencv` detections into the mission-level ArUco detection topic. |
| `map_cropper` | Provides cropped map support for mission/debug workflows. |

Mission topics:

| Topic | Type | Purpose |
| --- | --- | --- |
| `/mission_list` | `mr2_action_interface/msg/MissionList` | Ordered mission queue. |
| `/mission_control` | `mr2_action_interface/msg/MissionControl` | Pause, resume, abort, and clear-costmap commands. |
| `/mission_status` | `mr2_action_interface/msg/MissionStatus` | Mission state and progress. |
| `/cover_vision/object_pose/aruco` | `geometry_msgs/PoseStamped` | ArUco detection selected for cover vision. |
| `/cover_vision/object_pose/yolo` | `geometry_msgs/PoseStamped` | YOLO detection selected for cover vision. |
| `/cover_vision/coverage_path` | `nav_msgs/Path` | Coverage path used for debug and dashboard display. |

## Dashboard Path Rendering

`path_to_geopath.launch.py` reduces dashboard ROS traffic by converting full
map-frame paths to geographic paths on the robot/base side:

| Input | Output |
| --- | --- |
| `/plan_smoothed` | `/plan_smoothed/geo` |
| `/cover_vision/coverage_path` | `/cover_vision/coverage_path/geo` |

These outputs let the dashboard draw Nav2 plans and cover-vision coverage paths
without calling `/toLL` for every path point.

## Debug Commands

```bash
ros2 topic echo /mission_status
ros2 topic echo /cover_vision/coverage_path
ros2 topic echo /traversability_gridmap
ros2 service list | rg 'fromLL|toLL|datum'
ros2 service call /fromLL robot_localization/srv/FromLL \
  "{ll_point: {latitude: 38.5, longitude: -110.8, altitude: 0.0}}"
```
