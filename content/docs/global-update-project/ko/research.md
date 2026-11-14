---
title: "기술 조사"
weight: 60
draft: false
translation_source: "en/research.md"
translation_revision: "8e4d9a6"
---

# 조사 근거와 마이그레이션 경계

[프로젝트 개요]({{< ref "docs/global-update-project/ko/_index.md" >}}) · [English]({{< ref "docs/global-update-project/en/research.md" >}})

조사일: **2026-11-14**. [URC-kaist/mr2-stack](https://github.com/URC-kaist/mr2-stack)의 기본 브랜치는 `main`이 아닌 `2026`입니다. 조사한 소스는 [`74422f36c55140519f111cf6709f1725711b536a`](https://github.com/URC-kaist/mr2-stack/tree/74422f36c55140519f111cf6709f1725711b536a)이며, 자체 ROS 패키지 22개와 고정된 두 서브모듈의 패키지 7개를 포함합니다. 이는 조사 스냅샷을 식별하며, 실제 NX 배포 환경을 목록화한 결과는 아닙니다.

## 영향이 큰 경계

| 경계 | 판단과 작업 |
| --- | --- |
| Jetson 플랫폼 | 캐리어 BSP, CAN, 카메라, 멀티미디어, 추론의 조합을 네이티브에서 검증합니다. 정확한 보드·이미지를 기록합니다. |
| ros2_control / Servo | manager/spawner 매개변수 전달, 하드웨어 인터페이스, 수명 주기를 검토합니다. 기존 Servo 시작·상태 호출부는 목표 API에 맞춰야 합니다. |
| Nav2 | plugin 식별자, progress checker 설정, BT.CPP/XML, 자체 주행 가능성 처리 동작을 정확한 목표 버전에 맞춥니다. |
| Gazebo | 이미 현대적인 `ros_gz_sim`/`gz_ros2_control`을 사용합니다. 혼재한 Ignition/Gazebo 설정과 sensor/clock/QoS 동작을 검증합니다. |
| 인지/영상 | 고정하지 않은 Python 의존성과 외부 엔진 출처를 재현 가능한 절차로 정리하고, 필요한 카메라·인코더·추론 동시 부하를 검증합니다. |
| 웹/네이티브 relay | 클린 dashboard type check에서 중복 선언을 재현했습니다. mock gateway 시험은 실제 `rclnodejs` 통합을 입증하지 않습니다. |
| 재현성 | 기존 lockfile/gitlink는 유용하지만 클린 ROS 빌드와 완전한 네이티브 의존성 구성은 아직 수행할 작업입니다. |

Upstream 참고: [ros2_control 마이그레이션](https://control.ros.org/jazzy/doc/ros2_control/doc/migration.html), [Jazzy Servo 소스](https://raw.githubusercontent.com/moveit/moveit2/jazzy/moveit_ros/moveit_servo/src/servo_node.cpp), [Nav2 Humble→Iron](https://docs.nav2.org/rolling/configuration_and_development/migration_guides/Humble/), [Nav2 Iron→Jazzy](https://docs.nav2.org/rolling/configuration_and_development/migration_guides/iron/Iron/), [Gazebo 마이그레이션](https://gazebosim.org/docs/harmonic/migration_from_ignition/). 구현 전에 선택한 릴리스 패키지를 확인합니다. 바뀔 수 있는 upstream 브랜치는 참고 자료이며 배포 고정 버전이 아닙니다.

## 실제로 확인한 내용

Ubuntu 22.04.5 amd64 / Humble에서 설치된 의존성과 mock 네이티브 경계를 사용해 **gateway 시험 49개가 통과**했습니다. 클린 dashboard 의존성 설치는 성공했지만 type check에서 science type alias 9개의 중복을 재현했습니다. Python 68개, Bash 21개, XML/Xacro/SDF 43개 파일의 구문 검사가 통과했습니다. 이 결과는 한정된 검사이며 런타임·의미 검증이 아닙니다.

클린 ROS 컴파일, Jazzy 빌드, 시뮬레이터 실행, Jetson 네이티브 시험, GPU 시험, 필드 인수는 수행하지 않았습니다. Noble arm64 패키지 색인 직접 요청은 TLS 검증에서 실패했으며, 이를 패키지 부재로 해석하지 않고 기록했습니다. ROS 릴리스 메타데이터는 관측한 릴리스 정보를 뜻하며 바이너리 설치·동작의 증명은 아닙니다.

근거 다운로드: [소스 목록]({{< project-resource "projects/global-update-project/evidence/repository-snapshot.json" >}}), [패키지 의존성]({{< project-resource "projects/global-update-project/evidence/package-dependencies.tsv" >}}), [gateway 시험]({{< project-resource "projects/global-update-project/evidence/gateway-tests.json" >}}), [클린 dashboard 검사]({{< project-resource "projects/global-update-project/evidence/clean-dashboard-check.json" >}}), [릴리스 메타데이터]({{< project-resource "projects/global-update-project/evidence/target-release-availability.json" >}}), [근거 manifest]({{< project-resource "projects/global-update-project/evidence/manifest.json" >}}).

## 관련 병행 개발

[PR #81](https://github.com/URC-kaist/mr2-stack/pull/81) / [이슈 #80](https://github.com/URC-kaist/mr2-stack/issues/80)는 rover-direct 배포를 다룹니다. 과거의 Nano 표기는 확인된 실제 운용 대상인 NX를 바꾸지 않으며, 해당 브랜치의 검증 주장은 기본 브랜치의 결과가 아닙니다. 이 작업을 통합 기준에 어떻게 포함할지 결정합니다. [이슈 #68](https://github.com/URC-kaist/mr2-stack/issues/68)은 기존 CI 요구를, [#83](https://github.com/URC-kaist/mr2-stack/issues/83)은 가벼운 상태 기록을 다룹니다.

지형 world는 큰 mesh 충돌 자산을 사용합니다. Harmonic 호환성과 지형 효율 벤치마크는 별도 작업입니다. 동등한 자산·설정을 비교하고 실제 physics backend를 기록한 뒤 속도 향상을 시뮬레이터의 효과로 판단합니다.
