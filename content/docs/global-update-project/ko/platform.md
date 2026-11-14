---
title: "플랫폼과 핵심 원칙"
weight: 10
draft: false
translation_source: "en/platform.md"
translation_revision: "8e4d9a6"
---

# 무엇을 업데이트하나요?

[프로젝트 개요]({{< ref "docs/global-update-project/ko/_index.md" >}}) · [English]({{< ref "docs/global-update-project/en/platform.md" >}})

마이그레이션의 실질적인 단위는 동작하는 로봇 배포 환경입니다. OS 변경은 ROS 노드, 네이티브 라이브러리, 장치 드라이버, GPU 추론, 멀티미디어, 서비스의 기반을 바꿉니다. 다음 조합 전체를 검증 대상으로 봅니다.

**모듈 + 캐리어 보드 → JetPack/BSP → Ubuntu → ROS 및 네이티브 의존성 → 애플리케이션 동작**

## 후보 플랫폼

| 계층 | 기존 저장소의 기준 | 마이그레이션 후보 |
| --- | --- | --- |
| Ubuntu | 22.04 **Jammy** | 24.04 **Noble** |
| ROS 2 | Humble | **Jazzy** |
| Gazebo 조합 | Fortress | Harmonic |
| 실제 운용 컴퓨터 | Orin NX; 설치 환경은 목록화 필요 | 캐리어 보드에 맞는 후보 이미지를 적용한 Orin NX |
| 네이티브 개발 장비 | — | 사용 가능함이 확인된 재설정 가능한 Orin Nano |

Jammy는 Ubuntu의 코드명이며 ROS 목표 버전이 아닙니다. NVIDIA는 **JetPack 7.2.1 / Jetson Linux 39.2.1**에서 Orin과 Ubuntu 24.04 기반 환경을 지원한다고 명시합니다. 실제 Nano/NX의 캐리어와 주변장치 요구사항을 확인하며 이 이미지를 후보로 조사합니다. [NVIDIA 릴리스](https://developer.nvidia.com/embedded/jetpack/downloads/archive-7.2.1), [모듈 지원 범위](https://developer.nvidia.com/embedded/jetpack-archive)

조사일인 2026-11-14 기준으로 Ubuntu 22.04 표준 유지보수와 ROS Humble 지원은 2027년 5월까지입니다. Ubuntu 24.04와 Jazzy는 2029년 5월까지입니다. 이는 계획적인 지원 기반 전환이며, Orin NX 하드웨어 자체가 즉시 OS 교체를 요구하는 것은 아닙니다. [Ubuntu 수명 주기](https://ubuntu.com/about/release-cycle), [ROS 플랫폼 정책](https://raw.githubusercontent.com/ros-infrastructure/rep/master/rep-2000.rst)

현재 Gazebo 표는 Fortress의 지원 종료를 2027년 5월, Harmonic을 2029년 5월로 명시합니다. 공식 지원 조합인 Jazzy/Harmonic을 초기 목표로 삼습니다. [Gazebo 릴리스](https://gazebosim.org/docs/harmonic/releases/), [ROS 조합](https://gazebosim.org/docs/harmonic/ros_installation/)

## 동작 규약을 보존하고 결과를 검증합니다

명령의 단위·부호, 관절 순서·제한, 좌표계 규약, 프로토콜 인코딩, 모드 전환, 오래된 명령의 처리 방식을 명시합니다. API가 바뀌면 운용자가 기대하는 같은 동작을 유지하기 위해 구현도 바뀔 수 있습니다. 수치적으로 동일한 궤적이 아니더라도 합의한 임무 허용오차를 만족하면 수용할 수 있습니다.

후보 환경은 **식별된 실제 운용 기준**과 비교합니다. 여기에는 배포된 소스/빌드, 프로파일, 의존성, 보정값, 모델, 관측한 기능이 포함됩니다. 기본 브랜치 조사는 소스에 관한 근거이며, NX에 실제 설치된 구성의 증명은 아닙니다.

## Nano와 NX는 관련된 서로 다른 시험 환경입니다

Nano에서는 네이티브 설치, arm64 빌드, NVIDIA 스택, 연결된 장치의 결과를 확인할 수 있습니다. 다른 캐리어, 전체 NX 부하, NX 하드웨어 인코더까지 인증할 수는 없습니다. Orin Nano에는 NVENC가 없으므로 전송·브라우저 동작을 시험할 때는 명시적으로 축소한 소프트웨어 인코딩 프로파일을 사용합니다. [NVIDIA 인코딩 안내](https://docs.nvidia.com/jetson/archives/r36.4.4/DeveloperGuide/SD/Multimedia/SoftwareEncodeInOrinNano.html)

원본 모델과 빌드 절차는 공유하되, Nano에서 생성한 TensorRT 엔진이 NX의 승인된 산출물이라고 가정하지 않고 배포 대상에 맞춰 생성·검증합니다.

## 새 기능은 목적을 정해 평가합니다

[이슈 #55](https://github.com/URC-kaist/mr2-stack/issues/55#issuecomment-3891126618)는 더 새로운 Nav2 기능의 필요성을 제기합니다. 조사에서는 Jazzy 릴리스 메타데이터와 소스 태그 `1.3.14`에 `nav2_route`가 있음을 확인했습니다. 같은 태그에서는 `RemoveInCollisionGoals` 관련 경로와 Planner Server의 `allow_partial_planning` 매개변수를 찾지 못했습니다. 기능 채택 전에 실제 설치 패키지의 동작을 확인합니다. [릴리스 소스](https://github.com/ros-navigation/navigation2/tree/1.3.14), [Jazzy 메타데이터](https://raw.githubusercontent.com/ros/rosdistro/master/jazzy/distribution.yaml)

각 실험은 해결할 임무 문제와 기대 결과에서 출발합니다. 막힌 경유점을 건너뛰는 것, 목표를 옮기는 것, 부분 경로를 반환하는 것은 서로 다른 동작입니다. 지형 충돌 효율 벤치마크도 기본 시뮬레이터 호환성 검증과 분리합니다.
