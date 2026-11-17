---
title: "Introduction"
weight: 2
draft: false
bookCollapseSection: true
---

# Introduction

*Written by Jaeuk Kim in 2026. 03*

> **Revision context:** The substantial explanation was last revised in March
> 2026 (private documentation snapshot: 2 March). Targeted factual corrections
> were added with Codex on 18 November 2026; the full narrative has not yet been
> jointly human-reviewed. Later implementation changes are recorded separately
> in [Implementation Notes]({{< ref "docs/2026_mr2/navigation/implementation_notes.md" >}}).
> Read this as the design explanation from that period, rather than a complete
> description of the latest running configuration.

The **Autonomous Navigation** stack -- often dismissively dubbed "navigation" --
is one of the complex components with heavy design consideratios of
logic and decision, control frequency, dependence, consistency, and fine-tuning.

A good autonomy will not need supervision; But to build so, you will be considerate in every level designing its machinations.
In Navigation section, I will go through the major and peripheral system implementations and their wirings.
This could be either in software-level, sensor-level, or conceptual level.

Whenever I omit an implemnetation, it means either of following:
1. I was lazy.
2. I am planning to create a separate page dedicated to that topic.

## What is to Autonomously Navigate?

If you ask "What is Autonomous Navigation", you are actually looking at multiple layers working at once.
But the most prominent description would be "to go from A to B". Or even more simply, "to go from 'where I am' to B".
We can further dissect the process as the following:

1. You must know where you are in the first place. (Localization)
2. You need to create a path (list of intermediate points) connecting two points. (Planning)
3. You command the platform to move in such velocity to follow the path. (Controlling)

This is the brief summary of core pipeline; The position turns into a path, and the path turns into a velocity command.

## Localization

(Implementation-wise, localization stack is preliminarily launched by the main `rover_*` launch outside of `navigation` launch.)

### GNSS and Frames

**To localize is to fix your coordinate in some frame.**
For instance, with GNSS data, you can localize your 3D position with (1) latitude, (2) longitude, and (3) height (from epllipsoid);
These are geodetic coordinates referenced to **WGS84**. Null Island denotes latitude 0, longitude 0; it is not the origin of the Earth-centered coordinate system.

However, WGS84 is not suitable in a local sense; We would prefer cartesian system with intuitive units like meters.
So to measure deviation from the known origin with convenience (ex: deploying position), we use **`map`** frame.

`map` is a cartesian frame with meter as its unit. The frame's origin -- or *datum* -- is defined geographically, and the intended orientation is (X, Y, Z) = (East, North, Up), a.k.a ENU convention. The exact projection and alignment depend on the configured coordinate conversion; see [Maps]({{< ref "docs/2026_mr2/navigation/maps.md" >}}).

(There is also a projected coordinate frame called **`utm`**, using a zone-based easting/northing convention. UTM is not itself a local tangent plane, and a zone does not specify the geodetic datum. We also use this frame for path visualization on dashboard's MapLibre. Refer to "path_to_geopath" launch in the source code to track the usage.)

By informing the GNSS with real-time kinematics (RTK), we can estimate the rover's position with centimeter-level accuracy.
And by using dual-antenna setup, we can compute the absolute orientation (yaw) of the rover with simple geometry.
From now on, every global information for navigation is in `map` frame.

### Odometry Sensor Fusion (robot_localizaiton)

While GNSS can give us absolute position and absolute yaw, we can also estimate our position with other, differential sensors.
This is strictly necessary considering that typical GNSS data only ticks in 1 Hz frequency.

Luckily, we have wheel encoder odometry for local velocity, and IMU for acceleration and angular velocity.
These sensors can provide updates more frequently than GNSS. Their input rates and the EKF output frequency can be configured separately; changing the latter does not itself change the sensor rates.
By fusing these differential data, we can estimate the rover's position between GNSS updates. The fusion masks determine which available quantities are actually used; the audited real configuration does not fuse IMU linear acceleration.

The whole procedure is done by **dual-EKF** setup with the help of `robot_localization` and `imu_filter_madgwick` node.
I omit the implementation detail for now.
It is highly advised to understand dual-EKF setup for the relation between `map`, `odom`, and `base_link` frames.

## Planner (Nav2)

Now that we know where we are, (and assuming we have a costmap,) we can plan a path to the goal.
We want this path to be safe, reflective to the obstacles, and efficient.
If you have tried studying computer science, you might have heard of a search algorithm called **A\***, a variation of uniform cost search but with informed heuristcic -- such as Eucledian distance. In our implementation, we go one step further and use **Lazy Theta\*** for taut path; Basically, we want the rover to travel in straight lines, following line-of-sight logic, and not constrained to grid formation.
This is a considerate choice since 1. Utah desert is believed to be mostly empty 2. Empirically, it is more temporally stable than other grid-based planners.

The generated path goes through a **smoother**, so that it is less jagged.
I chose to use Savitzky-Golay smoother since it is robust, stable, predictable, and quick.
This smoother nudges the windowed segments (size=7) to be piecewise-polynomial (degree=3). It works well with Theta* planner.

## Controller (Nav2)

Now the rover should follow the path;
The role of controller is to command linear velocity and angular velocity to the rover to dictate its trajectory.
These values are derived *geometrically*, so the rover MUST obey to follow these values, or it will certainly deviate from the path and fail to progress properly.
There are many options to choose, but I stripped them down to regulated pure pursuit (**RPP**) and model predictive path integral (**MPPI**).

RPP is attractive for its faithfulness; When a path is given, it surely follows the path, always.
However, this means the rover will be only aware of the global path generation, and less robust to local obstacles.
So this is only good when the rover can fully trust the path planner, which may not always be the case when you should counter unforceen obstacles.

MPPI is more self-govenring but costly.
With numerous cost functions, it samples hundreads of trajectories to find the optimum in a stochastic manner.
The cost function includes these metrics:
 - pose deviation from the path
 - obstacle cost
 - goal orientation deviation
 - going backwards
 - ...

It works well, and and it does not require shim rotation guards (in-place rotation for edge cases where other controller fails).
It was proven to be more responsive than RPP setup, and Jetson Orin was able to process the sampling in time.

## Costmaps (Nav2)

Now that we know how the core components work, I will intruoduce another substrate that is required for the planner and controller: Costmaps.

The costmap is attached to a frame to store cost information. The planner uses global costmap, attached to `map` frame, storing global obstacle data, such as terrains. The controller uses local costmap, attached to `odom` frame. (However, local costmap rolls around `base_link` due to "rolling window" option. This is visually confusing since the local costmap seems to be centered at `base_link`, but the data is written in `odom`.)

The global costmap subscribes to a map server for a static map information that is the global slope map, the preprocessed DEM data.
Aside that fact, global and local costmap works equivalently; They both subscribe to traversability (local occupancy) data, and updates itself with new occupancy information. Both costmaps finish the layer composition with inflation.

The property can be summarized as the following:

- Global Costmap:
    - Attached to `map`
    - Resolution: 0.4 m/px
    - Size: Very Large (contain entire path)
    - For Theta* planner
    - Layers: [static, traversability, inflation]

- Local Costmap:
    - Attached to `odom` but rolls along `base_link`
    - Resolution: 0.1 m/px
    - Size: Small (few meter proximity)
    - For MPPI controller
    - Layers: [traversability, inflation]

### Inflation

Inflation is to smoothly bloat the obstacle from its original occupancy. Inflating an obstacle has two purpose:
1. Guide the planner to avoid proximity from the obstacles, but more importantly and primarily:
2. Add a patch of rover radius so the rover can be considered as a dot for the planner.

The second property is the most important aspect when you try to tune the inflation of the costmap.
*Planner does not, and cannot consider rover geometry on its own.*
In our implementation, the rover is considered as a circle enclosing a 1.2 m by 1.2 m square footprint: its diameter is 1.2 × √2 ≈ 1.697 m, corresponding to the configured collision radius of 0.8485 m. This is distinct from the inflation radius and wheel radius. The URC 2026 1.2 m box restriction applies at weigh-in; it is not a guarantee of the deployed footprint.

### Static Map

The static map for the global slope cost is hosted by a map server.
The original startup map is a 2500 x 2500 (1km x 1km) grayscale png. Mission preparation can replace it with a terrain crop; the later implementation can also load a blank free-space map outside the source coverage.
The regenerated terrain and dashboard imagery products, their frames and projections, and the remaining runtime-consumer adaptation are described in [Maps]({{< ref "docs/2026_mr2/navigation/maps.md" >}}).

### Traversability

Traversability is computed and processed by the traversability layer of each costmap.
**This new layer is a custom implemnetation to take data in GridMap format.**
Here I will omit the detail on the process on the traversability pipeline for now.
The gist is that it transforms depth camera pointclouds to heightmap and then traversability map.

## Miscellaneous but other useful modules (Nav2)

- Goal detection: Check if we arrived with correct pose. If true, end navigation with SUCCESS.
- Velocity smoother: Filter the velocity command output to prevent kinetically impossible outputs.

Now that we know how to go from A to B, we must learn how to guide the navigation itself.
Please go to "Mission Master and Vision" documentation to understand the setup.
