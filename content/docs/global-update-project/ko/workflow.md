---
title: "개발 절차"
weight: 20
draft: false
translation_source: "en/workflow.md"
translation_revision: "8e4d9a6"
---

# 운용 로버를 유지하며 개발하기

[프로젝트 개요]({{< ref "docs/global-update-project/ko/_index.md" >}}) · [English]({{< ref "docs/global-update-project/en/workflow.md" >}})

**일상적인 개발 중에는 NX 로버의 기존 운용 환경을 유지합니다.** 후보 이미지 구성, 재플래시, 서비스 실험, 네이티브 통합은 Nano에서 수행합니다. 시뮬레이션과 병렬 코딩은 워크스테이션에서 진행합니다.

{{< mermaid >}}
flowchart LR
    W[워크스테이션] --> C[검토된 후보 환경]
    N[Nano 시험 장비] --> C
    C --> Q[예정된 NX 검증]
    Q --> F[공동 시스템 및 필드 인수 시험]
    F --> R[합의된 전환]
{{< /mermaid >}}

## 두 개발 계열을 유지합니다

Humble 운용 계열을 유지하면서, 격리된 저장소/작업 공간에서 Jazzy를 개발합니다. 팀이 접근할 수 있는 마이그레이션 fork를 우선 검토하되, GitHub 생성 위치와 최종 기준 저장소 정책은 팀이 정합니다. 이력을 보존한 로컬 저장소는 `~/mr2-stack-jazzy`에 준비되어 있습니다. 브랜치는 `migration/jazzy`이며, `upstream`은 `URC-kaist/mr2-stack`을 가리키고 게시용 remote는 없습니다.

시작점은 조사한 커밋 `74422f36c55140519f111cf6709f1725711b536a`이며, 로컬 태그 `audit/2026-11-14`로도 표시합니다. 이는 잠정적인 통합 시작점입니다. 각 분야의 포팅을 합치기 전에 rover-direct 작업과 실제 운용 환경의 차이를 기준에 어떻게 반영할지 결정합니다.

선택한 저장소 안에서는 작은 브랜치와 검토된 PR을 사용합니다. 운용 환경에도 필요한 수정은 적절한 경우 Humble 계열에 먼저 반영한 뒤, 합의한 merge/cherry-pick 절차로 Jazzy에 반영합니다. 목표 환경 전용 변경은 후보 계열에서 관리합니다. 별도 저장소는 협업을 분리하는 수단이며, 전면 재작성을 요구하거나 뜻하지 않습니다.

## 환경을 분리하고 공통 규약을 맞춥니다

클린 22.04/Humble과 24.04/Jazzy 환경, 독립된 셸, 분리된 `build`, `install`, `log` 디렉터리를 사용합니다. 한 셸에서 두 ROS 설치를 함께 source하거나 바이너리 overlay를 재사용하지 않습니다. 컨테이너는 사용자 공간 재현에 도움이 되지만 BSP/장치의 네이티브 시험을 대신하지는 않습니다.

개발 ROS 그래프와 명령·네트워크 엔드포인트는 운용 로버와 격리합니다. 공통 메시지, TF, launch, 프로토콜, 운용 프로파일 변경은 통합 담당자를 통해 합의합니다. 시험에는 mock뿐 아니라 실제 네이티브 ROS 경계도 포함합니다.

## 첫 재현성 실습

빌드 담당자가 환경 구성 절차와 대표 시나리오를 준비하고, 다른 팀원이 클린 환경에서 재현합니다. 소스/서브모듈 고정 버전, 의존성 출처, 런타임 버전, 정확한 명령, 결과, 남은 장치 시험을 기록합니다.

아래는 **후보 환경 구성이 끝난 뒤의 점검 순서**입니다. 완전한 설치 절차나 현재 소스의 통과를 보장하는 명령은 아닙니다.

```bash
# 로버 NX가 아닌, 폐기·재구성 가능한 Noble/Jazzy 개발 환경에서 실행합니다.
source /opt/ros/jazzy/setup.bash
cd ~/mr2-stack-jazzy/rover/ros2_ws
rosdep install --from-paths src --ignore-src --rosdistro jazzy -y
colcon build --symlink-install --event-handlers console_direct+
source install/setup.bash
colcon test --event-handlers console_direct+
colcon test-result --verbose
```

의존성 실패를 검토하며 광범위한 skip 목록으로 숨기지 않습니다. 유용한 smoke 시나리오 하나에서 시작해 이를 막는 기존 결함을 해결하고, 구현에 따라 점검 범위를 넓힙니다.

## 공유 Nano 사용 규칙

소스 버전, 이미지, 주변장치, 예상 시간, 재부팅·재플래시 계획을 적어 장비를 예약합니다. 해당 시간에 공유 OS/BSP와 전역 의존성을 변경할 담당자를 정합니다. 종료 후에는 기준 환경을 복구하거나 명시적으로 인계합니다. 로버에 필요한 장비를 분리하는 대신 전용 시험 장치, 재생 데이터, mock을 사용합니다.

## 준비된 NX 검증 시간

운용을 중단하지 않는 범위에서 NX 전용 지원 조건과 설정을 일찍 조사합니다. 실제 NX가 필요한 시험은 검토된 후보 묶음, 해당 Nano 근거, 한정된 목표, 중단 조건, 부트 펌웨어를 고려한 복구 계획을 갖추어 예정된 정비 시간에 수행합니다.

복원 시간을 확보하고, 별도로 전환을 합의하지 않았다면 시험 후 기존 운용 환경으로 복구합니다. Nano에서의 연습이 NX 복구를 입증하지는 않습니다. 시간을 확보할 수 없다면 NX 전용 관문은 대기 상태로 두고 독립적인 개발을 계속합니다. 한 대뿐인 NX의 배포 환경을 최종 교체하는 동안까지 무중단을 보장할 수는 없습니다.
