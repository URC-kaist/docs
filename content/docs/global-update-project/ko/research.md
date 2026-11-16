---
title: "기술 조사 결과"
weight: 60
draft: false
translation_source: "en/research.md"
translation_source_sha256: "70d050f1095ee9c07931f6925af6520f26bad18e4a3eac3c1db87f05d9c6b625"
translation_status: "review-needed"
---

# 기술 조사 결과와 남은 작업 {#조사-근거와-마이그레이션-경계}

[프로젝트 개요]({{< ref "docs/global-update-project/ko/_index.md" >}}) · [English]({{< ref "docs/global-update-project/en/research.md" >}})

조사일은 **2026-11-14**입니다. [URC-kaist/mr2-stack](https://github.com/URC-kaist/mr2-stack)의 기본 브랜치는 `main`이 아닌 `2026`입니다. 조사한 commit은 [`74422f36c55140519f111cf6709f1725711b536a`](https://github.com/URC-kaist/mr2-stack/tree/74422f36c55140519f111cf6709f1725711b536a)입니다. 자체 ROS 패키지 22개와 버전을 고정한 서브모듈 두 개의 패키지 7개를 확인했습니다. 이 소스 목록과 실제 NX에 설치된 코드는 별도로 확인해야 합니다.

## 먼저 살펴볼 변경 지점 {#영향이-큰-경계}

| 분야 | 확인할 내용 |
| --- | --- |
| Jetson 플랫폼 | 캐리어 보드의 BSP, CAN, 카메라, 영상 처리, 추론을 실제 장비에서 함께 검증해야 합니다. 정확한 보드와 이미지를 기록합니다. |
| ros2_control / Servo | manager/spawner의 파라미터 전달, 하드웨어 인터페이스, lifecycle 상태 전환을 확인합니다. Servo의 시작·상태 조회 호출부도 목표 API에 맞춰 수정해야 합니다. |
| Nav2 | plugin 식별자, progress checker 설정, BT.CPP/XML, 자체 traversability(지형 주행 가능성) 처리를 설치할 버전에 맞춥니다. |
| Gazebo | 이미 `ros_gz_sim`/`gz_ros2_control`을 사용합니다. 혼재한 Ignition/Gazebo 설정을 정리하고 센서·clock·QoS 동작을 확인합니다. |
| Perception과 영상 | 버전이 고정되지 않은 Python 의존성과 외부에서 받은 추론 엔진의 출처·생성 절차를 정리합니다. 필요한 카메라·인코더·추론을 동시에 실행해 봐야 합니다. |
| 웹과 실제 ROS relay | 기존 설치 결과가 없는 환경에서도 dashboard 타입 검사에서 중복 선언이 발생했습니다. mock gateway 시험만으로 실제 `rclnodejs` 연동을 확인할 수는 없습니다. |
| 환경 재현 | lockfile과 서브모듈 버전 기록은 있지만, 클린 ROS 빌드와 네이티브 의존성의 전체 설치 절차는 아직 준비·확인해야 합니다. |

패키지별 공식 참고 자료는 [ros2_control 마이그레이션](https://control.ros.org/jazzy/doc/ros2_control/doc/migration.html), [Jazzy Servo 소스](https://raw.githubusercontent.com/moveit/moveit2/jazzy/moveit_ros/moveit_servo/src/servo_node.cpp), [Nav2 Humble→Iron](https://docs.nav2.org/rolling/configuration_and_development/migration_guides/Humble/), [Nav2 Iron→Jazzy](https://docs.nav2.org/rolling/configuration_and_development/migration_guides/iron/Iron/), [Gazebo 마이그레이션](https://gazebosim.org/docs/harmonic/migration_from_ignition/)입니다.

구현 전에 실제로 설치할 릴리스 패키지 버전을 확인하세요. 계속 바뀌는 upstream 브랜치는 참고 자료이며, 그 자체가 배포 버전을 고정해 주지는 않습니다.

## 조사에서 실행한 검사 {#실제로-확인한-내용}

Ubuntu 22.04.5 amd64 / Humble에서 다음을 확인했습니다.

- **gateway 시험 49개 통과:** 기존 설치 의존성을 사용했고, 네이티브 연동 부분은 mock으로 대체했습니다.
- **dashboard 의존성의 새 설치 성공:** 타입 검사에서는 science 타입 별칭 9개의 중복 선언 오류를 재현했습니다.
- **구문 검사 통과:** Python 68개, Bash 21개, XML/Xacro/SDF 43개 파일을 검사했습니다.

이 검사는 실행 중의 전체 동작이나 로직의 정확성까지 확인한 결과는 아닙니다. 클린 ROS 컴파일, Jazzy 빌드, 시뮬레이터 실행, 실제 Jetson 시험, GPU 시험, 필드 검증은 수행하지 않았습니다.

Noble arm64 패키지 색인을 직접 가져오려던 요청은 TLS 검증에서 실패했습니다. 이를 패키지가 없다는 뜻으로 해석하지 않고 실패로 기록했습니다. ROS 릴리스 메타데이터에서 패키지를 확인한 것도 설치나 실행 성공과는 구분해야 합니다.

원본 기록은 다음에서 내려받을 수 있습니다. [소스 목록]({{< project-resource "projects/global-update-project/evidence/repository-snapshot.json" >}}), [패키지 의존성]({{< project-resource "projects/global-update-project/evidence/package-dependencies.tsv" >}}), [gateway 시험]({{< project-resource "projects/global-update-project/evidence/gateway-tests.json" >}}), [dashboard 검사]({{< project-resource "projects/global-update-project/evidence/clean-dashboard-check.json" >}}), [릴리스 메타데이터]({{< project-resource "projects/global-update-project/evidence/target-release-availability.json" >}}), [검증 파일 목록]({{< project-resource "projects/global-update-project/evidence/manifest.json" >}}).

## 기존에 진행 중인 작업과 연결하기 {#관련-병행-개발}

[PR #81](https://github.com/URC-kaist/mr2-stack/pull/81)과 [이슈 #80](https://github.com/URC-kaist/mr2-stack/issues/80)은 rover-direct 배포를 다룹니다. 그 문서에 과거 Nano 사용이 적혀 있어도 현재 로버의 목표 장비는 확인된 Orin NX입니다. 해당 브랜치의 검증 결과를 기본 브랜치의 결과로 취급해서도 안 됩니다. 어떤 변경을 통합 기준에 넣을지 결정해야 합니다.

[이슈 #68](https://github.com/URC-kaist/mr2-stack/issues/68)은 CI를, [#83](https://github.com/URC-kaist/mr2-stack/issues/83)은 가벼운 상태 관측 기능을 다룹니다.

지형 world에는 충돌 판정에 쓰는 대형 mesh 모델이 있습니다. Harmonic에서 동작하게 만드는 작업과 지형 충돌 처리의 성능 측정은 별도입니다. 같은 모델·설정으로 비교하고 실제 physics backend를 기록해야 속도 변화의 원인을 판단할 수 있습니다.
