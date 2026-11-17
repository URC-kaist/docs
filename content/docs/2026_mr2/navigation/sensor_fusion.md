---
title: "Sensor Fusion"
weight: 2
draft: false
bookCollapseSection: true
---

# Sensor Fusion

*Written by Jaeuk Kim in 2026. 03*

> **Revision context:** This is the March 2026 explanation, with targeted
> factual corrections added with Codex on 18 November 2026. The full narrative
> has not yet been jointly human-reviewed. See
> [Implementation Notes]({{< ref "docs/2026_mr2/navigation/implementation_notes.md" >}})
> for the audited real/simulation settings and the unresolved tilt dependency.

In this page, I will talk about sensor fusion for localization.

Even with centimeter-level localization with the help of RTK-informed dual-GNSS, since GNSS data only arrives every second, the rover pose will be jumpy discontinuous. In that, we need to fuse differential sensors for intermediate times.

As an overview, we can summarize the setup as the following:

1. RTK-GNSS: Global orientation (yaw) and position (WGS84), low frequency
2. Wheel encoder odometry: Local velocity, high frequency
3. IMU accelerometer and gyroscope: Orientation estimation (roll, pitch), angular velocity, and linear acceleration, high frequency; the EKF configuration selects which quantities to fuse

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

The Kalman Filter is a recurrent computation that converges to the 'best' estimate of the state vector, given noisy inputs (and with known covariance).

To Extend the Kalman Filter is to linearize non-linear prediction and measurement models around the current estimate via Jacobian matrices. In `robot_localization`, orientation-dependent motion is one source of nonlinearity; geographic conversion is handled separately by `navsat_transform`. This is a local approximation, rather than a guarantee of an optimal estimate for every nonlinear problem.

It is very hard to explain the concepts without a blackboard and a chalk, so I am sorry.

The gist is, Kalman Filter updates the state estimate and its uncertainty (P), based on measurement uncertainty (R) and process uncertainty (Q). R describes uncertainty in the measurements, supplied through the incoming message covariances. Q describes uncertainty in the prediction model, including motion the model does not capture; it is not another sensor covariance. In `robot_localization`, `process_noise_covariance` configures Q, while `initial_estimate_covariance` sets the starting P.

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

Navsat Transform converts the WGS84 coordinate into the configured world frame, using the datum, the current odometry estimate, and an earth-referenced heading. The generic setup can use an IMU for heading; our configuration sets `use_odometry_yaw: true` instead. A GNSS fix supplies position, not an independently observed full orientation.

The problem is, IMU is not very reliable for global yaw. Some may contain magnetometers, but it is very easy to disturb them.
So instead, we inject dual-antenna heading, hijacking the result of navsat transform; We overwrite the yaw value for the orientation with the geometrically computed global yaw, so the EKF Global can consume it with no discrepancy.

This procedure is done by `gps_heading_gps_node`.

More on "geometrical computation":

When we have two GNSS recievers, we get two coordinates, in WGS84 system.
By sending these coordinates in *ECEF* frame, we can represent them as a 3D vector, for their difference vector.
By [reprojecting the difference back to the ENU frame](https://gssc.esa.int/navipedia/index.php/Transformations_between_ECEF_and_ENU_coordinates), we can calculate the baseline yaw with `atan2(north, east)`, measured counterclockwise from East, then apply the antenna mounting offset to obtain the rover's yaw.
