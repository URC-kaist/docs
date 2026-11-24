---
title: "Sensor Fusion"
weight: 2
draft: false
bookCollapseSection: true
---

# Sensor Fusion

*Written by Jaeuk Kim in 2026. 03*

[한국어]({{< ref "docs/2026_mr2/navigation/ko/sensor_fusion.md" >}})

> These explanations were written by Jaeuk Kim around March 2026, before he left the team. They describe the design at that time and may not reflect later implementation changes. Only minor factual and conceptual corrections have been made for this publication; these chapters have not been updated to match the current implementation.

*Minor corrections: November 25, 2026.*

In this page, I will talk about sensor fusion for localization.

Even with centimeter-level localization with the help of RTK-informed dual-GNSS, since GNSS data only arrives every second, the rover pose will be jumpy discontinuous. In that, we need to fuse differential sensors for intermediate times.

As an overview, we can summarize the setup as the following:

1. RTK-GNSS: Global orientation (yaw) and position (WGS84), low frequency
2. Wheel encoder odometry: Local velocity, high frequency
3. IMU accelerometer and gyroscope: Local orientation (roll, pitch) and velocity, high frequency

## Uncertainties: Noise and Disturbance

You cannot trust anything.
Every sensor data is tainted on its own, and every small jolts and bumps cause the sensor readings to fluctuate.
But that does not mean everything is random and unpredictable, it is just uncertain.

So there is Noise and Disturbance. The former is inherent to the sensor itself, and Disturbance is local pertubation from the environment.

- Noise:
  - IMU and wheel encoder noise and bias: even stationary, the sensor value fluctuates due to thermal noise.
  - Jumpy GNSS: Due to ill-conditioned convergence or missing RTK, the GNSS can sometimes jump around ten meters or so, unexpectedly.

- Disturbance:
  - Bumpy terrain and strong winds can interfere to the rover kinetics.

In that, every input is not described as their pure value, but with covariance to describe these noise as Gaussian distribution.

## What is Kalman Filter and What does it mean to Extend It?

The Kalman Filter repeatedly predicts and corrects a state estimate using noisy measurements and their covariance. Its optimality depends on the model and noise assumptions; it is not an unconditional guarantee of convergence to the true state.

To Extend the Kalman Filter is to locally linearize nonlinear motion and measurement models via Jacobian matrices. In robot_localization, 3D orientation and motion kinematics introduce nonlinear relationships; geographic coordinate conversion is handled separately. Although these relationships are not linear, we approximate them locally around the current estimate.

It is very hard to explain the concepts without a blackboard and a chalk, so I am sorry.

The gist is, Kalman Filter estimates the state and its uncertainty (P), using measurement uncertainty (R) and process uncertainty in the prediction model (Q). In robot_localization, Q is configured as the process-noise covariance; it is not another configured sensor-noise covariance. R comes from the measurement covariance, and P describes uncertainty in the state estimate.

After everything, EKF will work as a sensor fusion setup, giving us continuous localization.

## Dual-EKF setup (but with Dual-Antenna Heading)

Reading the [official tutorial](https://docs.ros.org/en/noetic/api/robot_localization/html/integrating_gps.html).
Further understanding [REP-105](https://www.ros.org/reps/rep-0105.html) will help you understand the relation between `map`, `odom`, and `base_link`as an engineer and developer. The intermediate `odom` frame is important to compensate discrepancy between GNSS and non-GNSS odometry.

1. EKF Local: `odom` -> `base_link`
This is a localization without any GNSS information, so it only takes IMU and wheel odometry.

2. EKF Global: `map` -> `base_link` (therefore, `map` -> `odom`)
This is a localization with GNSS information.
If tf: `odom` -> `base_link` and tf: `map` -> `base_link` matches perfectly, then tf: `map` -> `odom` will be close to identity.
Of course, this is not always the case. That is why we need a separate frame for GNSS-informed, and sans-GNSS-informed sensor fusion.

This `odom` frame acts as a buffer, ensuring continuous localization, so that the rover localization is not jumpy for periodic GNSS updates.
That is, `map` -> `base_link` can be jumpy, but `odom` -> `base_link` will not. Empirically, the jumpiness of `map` -> `base_link` was negligible.


## Dual-Antenna: Heading Injection

Navsat Transform converts the WGS84 position into the world frame (`map` here), using a datum that is either initialized or set by service call.
It uses GNSS position, heading information, and odometry to establish the coordinate transform. Its output expresses the GNSS position in that world frame; /gps/fix alone does not supply a full orientation measurement.

The problem is, IMU is not very reliable for global yaw. Some may contain magnetometers, but it is very easy to disturb them.
So instead, we inject dual-antenna heading, hijacking the result of navsat transform; We overwrite the yaw value for the orientation with the geometrically computed global yaw, so the EKF Global can consume it with no discrepancy.

This procedure is done by `gps_heading_gps_node`.

More on "geometrical computation":

When we have two GNSS recievers, we get two coordinates, in WGS84 system.
By sending these coordinates in *ECEF* frame, we can represent them as a 3D vector, for their difference vector.
By [reprojecting the difference back to the ENU frame](https://gssc.esa.int/navipedia/index.php/Transformations_between_ECEF_and_ENU_coordinates), we can calculate ROS global yaw counterclockwise from East, then apply the antenna mounting offset to obtain the rover's yaw.
