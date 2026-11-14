---
title: "Worked Migration Example"
weight: 25
draft: false
---

# Example: Make Controller Parameters Reach Their Controller

[Starting card]({{< ref "docs/global-update-project/en/start.md" >}}) · [한국어]({{< ref "docs/global-update-project/ko/controller-example.md" >}})

This proposed subtask of **GU-05** illustrates what a developer or Codex can do procedurally and which conclusions need runtime or physical evidence. No application patch or test described here has been executed by this documentation amendment.

## 1. Identify the existing contract

At audited commit `74422f36…`, [`launch_common.py`](https://github.com/URC-kaist/mr2-stack/blob/74422f36c55140519f111cf6709f1725711b536a/rover/ros2_ws/src/mr2_rover_description/mr2_rover_description/launch_common.py) passes the configuration file to `ros2_control_node`; `controller_spawners()` supplies controller names and optional `--inactive`, without a parameter file. Individual launch files also create spawners outside that helper.

[`rover_controllers.yaml`](https://github.com/URC-kaist/mr2-stack/blob/74422f36c55140519f111cf6709f1725711b536a/rover/ros2_ws/src/mr2_rover_description/config/controllers/rover_controllers.yaml) separates controller-manager declarations from `rover_controller` parameters. The intended contract is that joint lists, geometry and `twist_timeout` reach the actual controller. Preserve their selected values during this port; they are not new tuning recommendations.

## 2. Connect the source to an upstream change

The [official Humble-to-Jazzy guide](https://control.ros.org/jazzy/doc/ros2_control/doc/migration.html) explains that loading the YAML only into the manager no longer supplies controller parameters as before; spawners should receive `--param-file`. This maps a concrete source pattern to a migration requirement. It is not a reproduced failure in our target environment.

## 3. Propose a small change

Pass the selected `controller_config` substitution into the shared helper and all relevant direct spawners. An illustrative argument fragment is:

```python
# Illustration inside a spawner builder, not a complete launch-file patch.
args = [name, "--param-file", controller_config]
if name in inactive_controllers:
    args.append("--inactive")
```

A real patch must update the helper signature/callers and preserve launch conditions, controller-manager selection, namespaces and inactive startup behavior. Search for **all** spawners rather than changing only the first helper:

```bash
# Read-only inventory in the candidate workspace.
rg -n 'controller_spawners\(|executable="spawner"' \
  ~/mr2-stack-jazzy/rover/ros2_ws/src/mr2_rover_description
```

Robot-description topic wiring, controller API compatibility and hardware interfaces are related startup prerequisites. Track them explicitly; adding this flag does not complete the whole control migration.

## 4. Verify in a provisioned isolated environment

Build the affected packages and inspect the generated spawner arguments. Then use a reviewed mock-hardware or simulation recipe to load/configure the controller without physical CAN access. Do not launch the hardware entry point merely to test this change.

With that isolated graph running, read-only observations can include:

```bash
# Use the manager/controller paths selected by that test recipe.
ros2 control list_controllers -c /controller_manager
ros2 control list_hardware_interfaces -c /controller_manager
ros2 param dump /rover_controller
```

Compare the actual joint lists, geometry and timeout with the selected YAML; confirm expected lifecycle state and claimed interfaces. A build, a log saying “loaded,” or equality with an accidental default is insufficient evidence of parameter delivery. Where the mock recipe permits, test a harmless parameter override and observe its arrival. Record failures in other startup prerequisites separately.

## 5. Hand over the result and retain the physical gate

Return the diff, source/environment/configuration versions, launch recipe, argument observations, parameter dump and lifecycle/interface results. State which checks were not run. Codex can prepare this software evidence; a human reviewer confirms contract intent and startup/mode policy.

Joint HW/operator testing still checks real drive/steering/arm directions, limits, stale-command response, handover and recovery in the scheduled NX session. Mock activation does not certify those physical behaviors. This division makes a bounded API migration delegable without overstating its result.
