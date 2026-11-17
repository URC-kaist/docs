---
title: "컨트롤러 포팅 예제"
weight: 25
draft: false
translation_source: "en/controller-example.md"
translation_source_sha256: "e7c5b4df883d232b46541e1b0ba9d273ff708d0148b8450dfad9bba7bdd8883a"
translation_status: "review-needed"
---

# 예제: 컨트롤러에 파라미터 전달하기 {#예제-컨트롤러에-매개변수-전달하기}

[개발 시작하기]({{< ref "docs/global-update-project/ko/start.md" >}}) · [English]({{< ref "docs/global-update-project/en/controller-example.md" >}})

**GU-05**의 일부로 제안하는 작업입니다. 코드 조사와 수정은 어떻게 진행하고, 어떤 결과를 실제 실행이나 장치 시험으로 확인해야 하는지 보여 줍니다. 아래 패치와 시험은 아직 수행하지 않았습니다.

## 1. 현재 코드가 파라미터를 어디로 보내는지 확인하기 {#1-기존-동작-규약을-파악합니다}

조사한 commit `74422f36…`의 [`launch_common.py`](https://github.com/URC-kaist/mr2-stack/blob/74422f36c55140519f111cf6709f1725711b536a/rover/ros2_ws/src/mr2_rover_description/mr2_rover_description/launch_common.py)는 설정 파일을 `ros2_control_node`에 전달합니다.

spawner는 컨트롤러를 불러와 설정된 상태로 시작시키는 프로그램입니다. `controller_spawners()`는 각 spawner 명령에 컨트롤러 이름을 넣고, 필요한 경우 `--inactive`를 추가합니다. 파라미터 파일은 전달하지 않습니다. 개별 launch 파일에도 이 helper를 거치지 않고 spawner를 만드는 코드가 있습니다.

[`rover_controllers.yaml`](https://github.com/URC-kaist/mr2-stack/blob/74422f36c55140519f111cf6709f1725711b536a/rover/ros2_ws/src/mr2_rover_description/config/controllers/rover_controllers.yaml)에는 controller manager의 설정과 `rover_controller`의 파라미터가 나뉘어 있습니다. 컨트롤러에는 joint(관절) 목록, 차체와 바퀴의 치수, `twist_timeout`이 전달되어야 합니다. 이번 작업에서는 기존에 선택한 값을 유지합니다. 값을 새로 튜닝하는 작업은 아닙니다.

## 2. Jazzy에서 달라진 부분과 연결하기 {#2-소스를-upstream-변경과-연결합니다}

[공식 Humble→Jazzy 안내](https://control.ros.org/jazzy/doc/ros2_control/doc/migration.html)에 따르면, YAML을 manager에만 전달하는 방식으로는 이전처럼 컨트롤러 파라미터가 전달되지 않습니다. spawner 명령에 `--param-file`을 지정해야 합니다.

따라서 현재 코드에서 파라미터 파일을 전달하는 경로를 바꿔야 하는지 검토할 수 있습니다. 이는 소스와 공식 변경 안내를 대조한 판단이며, 우리 Jazzy 환경에서 실패를 재현한 결과는 아닙니다.

## 3. 수정 범위를 정하고 모든 spawner 찾기 {#3-작은-변경을-제안합니다}

설정 파일 경로를 나타내는 `controller_config`를 공통 helper와 직접 생성하는 spawner에 전달하도록 수정합니다. 이 값은 launch substitution이며, 실행할 때 설정 파일 경로로 평가됩니다. 아래는 spawner 인수를 구성하는 부분의 예시입니다.

```python
# spawner 인수 구성의 예시입니다. 완전한 launch 파일 패치는 아닙니다.
args = [name, "--param-file", controller_config]
if name in inactive_controllers:
    args.append("--inactive")
```

실제 수정에서는 helper의 파라미터와 호출부를 함께 바꿔야 합니다. launch 조건, 사용할 controller manager, namespace, 비활성 상태로 시작하는 동작은 유지하세요.

공통 helper만 고치면 직접 생성하는 spawner를 놓칠 수 있습니다. 다음 검색으로 **모든** 생성 위치를 확인합니다.

```bash
# 개발 저장소에서 관련 코드를 찾습니다. 파일이나 장치는 변경하지 않습니다.
rg -n 'controller_spawners\(|executable="spawner"' \
  ~/mr2-stack-jazzy/rover/ros2_ws/src/mr2_rover_description
```

robot-description topic 연결, 컨트롤러 API 호환성, 하드웨어 인터페이스도 시작 과정에 영향을 줍니다. 각각 별도 확인 항목으로 남기세요. 이 flag 하나를 추가했다고 제어 부분의 마이그레이션이 끝나는 것은 아닙니다.

## 4. 실제 CAN 장치와 분리한 환경에서 확인하기 {#4-구성된-격리-환경에서-확인합니다}

설치·설정을 마친 시험 환경에서 관련 패키지를 빌드하고, 생성된 spawner 명령의 인수를 확인합니다. 이어 검토된 mock hardware 또는 시뮬레이션 절차로 컨트롤러를 load/configure합니다. mock hardware는 실제 장치 대신 장치 동작을 모사하는 시험 환경입니다. 이 단계에서는 실제 CAN에 접근하지 않으며, 확인을 위해 하드웨어용 launch를 바로 실행하지 않습니다.

격리된 ROS 그래프가 실행 중이면 다음 명령으로 상태와 파라미터를 조회할 수 있습니다.

```bash
# 시험 절차에서 정한 manager/controller 경로를 사용합니다.
ros2 control list_controllers -c /controller_manager
ros2 control list_hardware_interfaces -c /controller_manager
ros2 param dump /rover_controller
```

실제 joint 목록, 차체와 바퀴의 치수, timeout이 선택한 YAML과 일치하는지 비교하세요. lifecycle 상태와 컨트롤러가 사용권을 가진(claim한) 인터페이스도 확인합니다. lifecycle은 컨트롤러의 설정·활성화 등 상태 전환을 뜻합니다.

빌드 성공이나 “loaded” 로그만으로는 파라미터 전달을 확인할 수 없습니다. 출력값이 우연히 기본값과 같을 수도 있습니다. mock 시험 절차에서 허용한다면 영향이 없는 파라미터 값을 명시적으로 덮어쓰고, 그 값이 컨트롤러에 도달하는지도 확인하세요. 다른 시작 조건 때문에 실패했다면 원인을 구분해 기록합니다.

## 5. 결과를 인계하고 실제 장치 시험 남기기 {#5-결과를-인계하고-물리-관문을-남깁니다}

diff, 소스·환경·설정 버전, 실행한 launch 절차를 남깁니다. spawner에 전달된 인수, 파라미터 dump, lifecycle과 인터페이스 조회 결과도 함께 전달하세요. 실행하지 않은 시험은 구분해서 적습니다.

Codex는 코드 수정과 이런 소프트웨어 시험 결과를 준비할 수 있습니다. 사람 검토자는 유지해야 할 인터페이스와 시작·모드 전환 정책에 맞는지 확인합니다.

실제 구동·조향·팔의 방향과 제한, 유효 시간이 지난 명령에 대한 반응, 제어권 전환, 복구는 합의한 NX 시험 시간에 HW 담당자·운용자와 확인해야 합니다. mock에서 활성화에 성공해도 실제 장치 동작까지 확인한 것은 아닙니다. 소프트웨어 결과와 장치 시험을 이렇게 나누면 범위가 명확한 작업을 위임할 수 있습니다.
