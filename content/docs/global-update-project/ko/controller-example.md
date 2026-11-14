---
title: "마이그레이션 예제"
weight: 25
draft: false
translation_source: "en/controller-example.md"
translation_revision: "developer-guidance-2026-11-14"
---

# 예제: 컨트롤러에 매개변수 전달하기

[개발 시작 카드]({{< ref "docs/global-update-project/ko/start.md" >}}) · [English]({{< ref "docs/global-update-project/en/controller-example.md" >}})

**GU-05**의 하위 작업으로 제안하는 예제입니다. 개발자나 Codex가 절차적으로 할 일과 런타임·물리 근거가 필요한 판단을 구분합니다. 이번 문서 보완에서는 아래 애플리케이션 패치나 시험을 실행하지 않았습니다.

## 1. 기존 동작 규약을 파악합니다

조사 커밋 `74422f36…`의 [`launch_common.py`](https://github.com/URC-kaist/mr2-stack/blob/74422f36c55140519f111cf6709f1725711b536a/rover/ros2_ws/src/mr2_rover_description/mr2_rover_description/launch_common.py)는 설정 파일을 `ros2_control_node`에 전달합니다. `controller_spawners()`에는 컨트롤러 이름과 선택적인 `--inactive`만 전달하며 매개변수 파일을 주지 않습니다. 개별 launch 파일에도 이 helper를 사용하지 않는 spawner가 있습니다.

[`rover_controllers.yaml`](https://github.com/URC-kaist/mr2-stack/blob/74422f36c55140519f111cf6709f1725711b536a/rover/ros2_ws/src/mr2_rover_description/config/controllers/rover_controllers.yaml)은 controller manager 선언과 `rover_controller` 매개변수를 구분합니다. 관절 목록, 기하 정보, `twist_timeout`이 실제 컨트롤러에 전달되어야 합니다. 이번 포팅에서는 선택한 값을 보존하며 새 튜닝 권장값으로 취급하지 않습니다.

## 2. 소스를 upstream 변경과 연결합니다

[공식 Humble→Jazzy 안내](https://control.ros.org/jazzy/doc/ros2_control/doc/migration.html)는 YAML을 manager에만 전달하는 기존 방식으로는 컨트롤러 매개변수가 전달되지 않으므로 spawner의 `--param-file`을 사용하도록 설명합니다. 구체적인 소스 형태를 마이그레이션 요구와 연결한 것이며, 우리 목표 환경에서 실패를 재현한 결과는 아닙니다.

## 3. 작은 변경을 제안합니다

선택한 `controller_config` substitution을 공통 helper와 관련된 직접 생성 spawner 모두에 전달합니다. 아래는 인수 구성의 예시입니다.

```python
# spawner builder 내부의 예시이며 완전한 launch 파일 패치가 아닙니다.
args = [name, "--param-file", controller_config]
if name in inactive_controllers:
    args.append("--inactive")
```

실제 패치에서는 helper 인자와 호출부를 수정하고 launch 조건, controller manager 선택, namespace, inactive 시작 동작을 보존해야 합니다. 첫 helper만 바꾸지 말고 **모든** spawner를 찾습니다.

```bash
# 후보 작업 공간의 읽기 전용 목록화.
rg -n 'controller_spawners\(|executable="spawner"' \
  ~/mr2-stack-jazzy/rover/ros2_ws/src/mr2_rover_description
```

robot-description topic 연결, controller API 호환성, 하드웨어 인터페이스도 관련 시작 조건입니다. 명시적으로 추적하며 이 flag 하나를 추가했다고 전체 제어 포팅이 끝났다고 보지 않습니다.

## 4. 구성된 격리 환경에서 확인합니다

관련 패키지를 빌드하고 생성된 spawner 인수를 확인합니다. 이어 검토된 mock hardware 또는 시뮬레이션 절차로 물리 CAN에 접근하지 않고 컨트롤러를 load/configure합니다. 이 변경을 확인하기 위해 실제 하드웨어 진입점을 바로 실행하지 않습니다.

격리된 그래프를 실행한 상태에서는 다음과 같이 읽기 전용으로 관측할 수 있습니다.

```bash
# 시험 절차에서 선택한 manager/controller 경로를 사용합니다.
ros2 control list_controllers -c /controller_manager
ros2 control list_hardware_interfaces -c /controller_manager
ros2 param dump /rover_controller
```

실제 관절 목록, 기하 정보, timeout을 선택한 YAML과 비교하고 기대한 수명 주기 상태와 확보한 인터페이스를 확인합니다. 빌드 성공, “loaded” 로그, 우연히 같은 기본값만으로 전달을 입증할 수는 없습니다. mock 절차에서 허용하면 영향이 없는 매개변수 override가 도착하는지도 확인합니다. 다른 시작 조건의 실패는 구분해 기록합니다.

## 5. 결과를 인계하고 물리 관문을 남깁니다

diff, 소스·환경·설정 버전, launch 절차, 인수 관측, 매개변수 dump, 수명 주기·인터페이스 결과를 돌려줍니다. 실행하지 않은 점검도 명시합니다. Codex는 소프트웨어 근거를 준비할 수 있고 사람 검토자는 규약의 의도와 시작·모드 정책을 확인합니다.

실제 구동·조향·팔의 방향, 제한, 오래된 명령 반응, 제어권 전환, 복구는 예정된 NX 시간에 HW/운용 담당자와 공동 시험합니다. mock 활성화가 이 물리 동작을 인증하지는 않습니다. 이 구분을 통해 결과를 과장하지 않으면서 범위가 명확한 API 마이그레이션을 위임할 수 있습니다.
