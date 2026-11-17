---
title: "Implementation Notes"
weight: 4
draft: false
bookCollapseSection: true
---

# Implementation Notes

*Source comparison and editorial notes prepared with Codex on 18 November 2026.*

The four detailed chapters preserve Jaeuk Kim's March 2026 design explanation.
Their private source snapshot is dated 2 March; the last direct navigation
implementation contribution used in this comparison is 16 March (`fdfeb7aa`).
Targeted corrections address factual mistakes without rewriting the narrative
around later tuning. The full chapter text has not yet been jointly
human-reviewed.

The observations below refer to
[`mr2-stack/2026` at `74422f3`](https://github.com/URC-kaist/mr2-stack/tree/74422f36c55140519f111cf6709f1725711b536a),
verified against the remote on 18 November. They describe committed settings,
rather than measurements from a running rover. The newer
[Maps chapter]({{< ref "docs/2026_mr2/navigation/maps.md" >}}) documents the
separately regenerated map pipeline and its remaining consumer-integration work.

## CoverVision and the competition requirement

The March implementation attempted to face a detected object using FollowPath.
The [18 May change](https://github.com/URC-kaist/mr2-stack/commit/3ec436daa8516ff6cea18016e940d93be0d3343e)
removes that turn and accepts fresh detections during the approach as well as
coverage. Accepted detections cancel navigation and complete the action;
finishing coverage without a detection also returns success.

URC 2026 rule 1.f.v requires autonomous object identification on the C2 display
while the rover is stopped. Rule 1.f.vii separately calls for arrival indications
on the rover and operator display. The official
[2026 rules archive](https://urc.marssociety.org/home/about-urc/history/urc2026/urc2026-requirements-guidelines)
and [Autonomy Q7](https://urc.marssociety.org/home/about-urc/history/urc2026/urc2026-qa)
allow a suitably sized bounding box to identify the object. A final rover-facing
turn is not stated as a requirement. It can be an implementation choice for
keeping the target visible, but neither a turn nor action success alone proves
that the required display evidence was produced. Why the turn was removed, and
what field verification supported that choice, remain unrecorded in the inspected
change.

## Localization rates, planarity, and gravity

| Setting | March real configuration | Audited real configuration | Audited simulation |
| --- | --- | --- | --- |
| Local EKF output | 30 Hz, 3D | 15 Hz, 2D | 30 Hz, 3D |
| Global EKF output | 30 Hz, 2D | 15 Hz, 2D | 30 Hz, 3D |
| Navsat processing frequency | 30 Hz | 15 Hz | 30 Hz |
| EKF sensor timeout | 0.1 s | 0.2 s | 2.0 s |

Input sensor rates are separate from filter output and navsat processing rates.
The [real configuration](https://github.com/URC-kaist/mr2-stack/blob/74422f36c55140519f111cf6709f1725711b536a/rover/ros2_ws/src/mr2_rover_auto/config/dual_ekf_navsat_real.yaml)
does not fuse IMU linear acceleration. The
[May change](https://github.com/URC-kaist/mr2-stack/commit/fe7f37bc9b4ea326443efe22c8a379a89024e8c2)
does not establish why the rates or local planarity were chosen; an empirical
benefit needs measurements or the author's explanation.

`two_d_mode` constrains height, roll, pitch, and related out-of-plane motion to
zero. It can be appropriate for planar navigation. It does more than ignore an
unreliable GNSS altitude: declining one measurement component and constraining
the entire filter to a plane are different decisions. See the upstream
[parameter reference](https://github.com/cra-ros-pkg/robot_localization/blob/b1e373177cc8190f2a424243a73a1023c882140f/doc/state_estimation_nodes.rst).

This matters for traversability. The configured
[`gravity_source: tf`](https://github.com/URC-kaist/mr2-stack/blob/74422f36c55140519f111cf6709f1725711b536a/rover/ros2_ws/src/mr2_rover_auto/config/trav_pipeline.yaml)
expresses map-up in `base_link`; it needs rover tilt relative to an upright
reference. The node also supports an IMU input, but that path is not selected by
this configuration. The real Madgwick filter publishes an orientation topic,
with its own TF publication disabled.

There is a further dependency even in the March configuration. The global EKF
publishes `map -> odom` by removing the local `odom -> base_link` estimate from
its global `map -> base_link` estimate. Thus the composed map-to-base transform
follows the global estimate. A 3D local filter alone does not preserve physical
tilt in that composed transform when the global filter is planar. This follows
from the upstream
[transform construction](https://github.com/cra-ros-pkg/robot_localization/blob/b1e373177cc8190f2a424243a73a1023c882140f/src/ros_filter.cpp#L2280-L2327).

**Unresolved integration question:** Which deployed source supplied the physical
gravity direction? The committed defaults expose a mismatch with the intended
slope calculation. This source-level finding does not establish the actual
field configuration or a measured failure. Restoring local 3D mode alone should
not be presented as a verified solution; inspect the full frame chain or an
independent gravity source first.

## Steering still uses inverse kinematics

The interface remains body velocity (`cmd_vel`) to wheel joint commands through
ros2_control, followed by the hardware/CAN interface. The peer removed the
separate mission smoothing solver, rather than all 4WS4WD inverse kinematics.
The remaining
[controller](https://github.com/URC-kaist/mr2-stack/blob/74422f36c55140519f111cf6709f1725711b536a/rover/ros2_ws/src/mr2_rover_control/src/twist_to_commands_controller.cpp#L346-L494)
computes each wheel's contact velocity as `vx_i = vx - wz*y_i`,
`vy_i = vy + wz*x_i`, then steering with `atan2` and wheel angular speed from
contact speed divided by wheel radius. It chooses between equivalent
steering/reverse-drive solutions and applies limits and steering-error speed
scaling. MissionStatus still selects manual versus autonomous command input.

In [PR #79](https://github.com/URC-kaist/mr2-stack/pull/79), “nominal steering
conversion” means using the path previously used for ordinary manual driving
in mission mode too. “Left-right hunting” describes alternating steering/yaw
corrections. The PR says reducing MPPI yaw-rate sampling spread was intended to
reduce this; it does not provide a measured tracking comparison. Sampling spread
is the dispersion of candidate yaw rates, rather than the maximum yaw rate.
The later [unification commit](https://github.com/URC-kaist/mr2-stack/commit/5495a2d05102d67f0b175782e79caebf97a41750)
deletes the separate mission solver. The field tradeoff behind removing that
smoothing remains a question for its author.

## Maps, hardware, and smaller implementation details

- The cropper is implemented. PR #79 adds a bounded blank free-space fallback
  when the terrain source does not cover the rover/goal request. This addresses
  the off-map task; it does not provide terrain knowledge outside the source.
  The rebuilt map-generation pipeline and the old runtime cropper still have
  different data contracts, described in Maps.
- Wheel radius changes from 0.125 to 0.17 m. The radius affects both angular
  wheel commands and encoder-derived linear velocity. At the same wheel angular
  speed a larger wheel travels faster; at the same requested body speed the
  corresponding angular command is smaller. This is distinct from changing
  Nav2's commanded speed limits.
- The later transport is XBee, replacing SiK. The mission message definitions
  remain the same; no comparative radio-reliability claim is made here.
- The configured voxel size is already 0.01 m. The old TODO to change 0.05 to
  0.01 m needs no new issue unless a distinct performance problem is identified.
- Max persistence retains the intended contrast with EMA forgetting; explicit
  clearing and rolling-window eviction still apply.
- YOLO depth uses a clipped 5×5 median of valid samples. Adapter jump gating
  suppresses a new smoothed publication that is too far from the previous
  published pose. It is a false-positive heuristic, not proof of target identity.
  ArUco's configured `force_enable: true` also differs from the mission-gated
  YOLO adapter. These details do not require replacing the chapter's teaching
  narrative with every available parameter.

These notes keep observed behavior usable while leaving undocumented historical
motivations open for follow-up. They do not certify field performance or replace
the competition's own success criteria.
