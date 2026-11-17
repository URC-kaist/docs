---
title: "업데이트 범위와 원칙"
weight: 10
draft: false
translation_source: "en/platform.md"
translation_source_sha256: "1763cc9b265711b05a8edc9a15d373d82289661fa2879738c76ecedc95b3e994"
translation_status: "review-needed"
---

# 업데이트 범위와 원칙 {#무엇을-업데이트하나요}

[프로젝트 개요]({{< ref "docs/global-update-project/ko/_index.md" >}}) · [English]({{< ref "docs/global-update-project/en/platform.md" >}})

OS만 새로 설치해서 끝나는 작업은 아닙니다. OS가 바뀌면 ROS 노드가 사용하는 라이브러리, 장치 드라이버, GPU 추론, 영상 처리, 서비스의 실행 환경도 달라집니다. 다음 조합에서 로버가 필요한 동작을 하는지 함께 확인해야 합니다.

**모듈과 캐리어 보드 → JetPack/BSP → Ubuntu → ROS와 네이티브 라이브러리 → 애플리케이션 동작**

## 목표로 검토하는 조합 {#후보-플랫폼}

| 항목 | 기존 저장소가 전제로 삼은 환경 | 마이그레이션 목표 |
| --- | --- | --- |
| Ubuntu | 22.04 **Jammy** | 24.04 **Noble** |
| ROS 2 | Humble | **Jazzy** |
| Gazebo | Fortress | Harmonic |
| 로버 컴퓨터 | Orin NX. 실제 설치 환경은 확인이 필요합니다. | 캐리어 보드에 맞는 이미지로 구성한 Orin NX |
| Jetson 개발 장비 | — | 자유롭게 재설정할 수 있는 여분의 Orin Nano |

Jammy는 Ubuntu의 코드명입니다. ROS 2의 목표 버전은 Jazzy입니다.

NVIDIA는 **JetPack 7.2.1 / Jetson Linux 39.2.1**에서 Orin과 Ubuntu 24.04 기반 환경을 지원한다고 안내합니다. 이를 설치 이미지 후보로 삼되, 실제 Nano·NX의 캐리어 보드와 주변장치가 지원되는지 확인해야 합니다. [NVIDIA 릴리스](https://developer.nvidia.com/embedded/jetpack/downloads/archive-7.2.1), [모듈 지원 범위](https://developer.nvidia.com/embedded/jetpack-archive)

조사일인 2026-11-14 기준으로 Ubuntu 22.04의 표준 유지보수와 ROS Humble의 지원은 2027년 5월까지, Ubuntu 24.04와 Jazzy는 2029년 5월까지입니다. 지원 기간을 고려해 전환을 준비하는 것이며, Orin NX를 쓰고 있다는 이유만으로 당장 OS를 바꿔야 한다는 뜻은 아닙니다. [Ubuntu 지원 주기](https://ubuntu.com/about/release-cycle), [ROS 플랫폼 정책](https://raw.githubusercontent.com/ros-infrastructure/rep/master/rep-2000.rst)

조사에서 확인한 Gazebo 지원 기간은 Fortress가 2027년 5월까지, Harmonic이 2029년 5월까지입니다. 초기 목표는 공식 지원 조합인 Jazzy/Harmonic으로 잡습니다. [Gazebo 릴리스](https://gazebosim.org/docs/harmonic/releases/), [ROS 조합](https://gazebosim.org/docs/harmonic/ros_installation/)

## 유지해야 할 동작부터 정하기 {#동작-규약을-보존하고-결과를-검증합니다}

명령의 단위와 부호, joint(관절)의 순서와 제한값, 좌표계, 프로토콜 인코딩, 모드 전환을 명시하세요. 유효 시간이 지난 명령을 어떻게 처리할지도 포함합니다. API가 바뀌면 코드도 바꿔야 하지만, 운용자가 기대하는 동작은 유지해야 합니다. 궤적의 수치가 완전히 같지 않더라도 팀이 정한 임무 허용오차를 만족하면 받아들일 수 있습니다.

비교 기준은 **현재 NX에서 실제로 쓰는 코드와 설정**입니다. 소스와 빌드 버전, 운용 구성, 의존성, 보정값, 모델, 확인된 기능을 기록하세요. 기본 브랜치를 조사한 결과만으로 NX에 무엇이 설치되어 있는지까지 알 수는 없습니다.

## Nano에서 확인할 일과 NX에서 확인할 일 {#nano와-nx는-관련된-서로-다른-시험-환경입니다}

Nano에서는 실제 Jetson의 설치 과정, arm64 빌드, NVIDIA 소프트웨어, 연결된 장치를 시험할 수 있습니다. 다른 캐리어 보드나 NX의 전체 부하, NX 하드웨어 인코더는 NX에서 따로 확인해야 합니다.

Orin Nano에는 NVENC가 없습니다. Nano에서 영상 전송과 브라우저 동작을 시험할 때는 부하를 줄인 소프트웨어 인코딩 설정을 정하고 기록하세요. [NVIDIA 인코딩 안내](https://docs.nvidia.com/jetson/archives/r36.4.4/DeveloperGuide/SD/Multimedia/SoftwareEncodeInOrinNano.html)

원본 모델과 빌드 절차는 공유할 수 있습니다. 다만 Nano에서 만든 TensorRT 엔진을 그대로 NX용 검증 완료 파일로 취급하면 안 됩니다. 실제 배포할 장비에 맞춰 생성하고 검증하세요.

## 새 기능을 평가하는 방법 {#새-기능은-목적을-정해-평가합니다}

[이슈 #55](https://github.com/URC-kaist/mr2-stack/issues/55#issuecomment-3891126618)에서는 더 새로운 Nav2 기능이 필요하다는 의견이 나왔습니다. 조사에서는 Jazzy 릴리스 메타데이터와 소스 태그 `1.3.14`에서 `nav2_route`를 확인했습니다. 같은 태그에서 `RemoveInCollisionGoals` 관련 경로와 Planner Server의 `allow_partial_planning` 파라미터는 찾지 못했습니다. 도입을 결정하기 전에 실제 설치할 패키지 버전과 동작을 확인하세요. [릴리스 소스](https://github.com/ros-navigation/navigation2/tree/1.3.14), [Jazzy 메타데이터](https://raw.githubusercontent.com/ros/rosdistro/master/jazzy/distribution.yaml)

실험마다 해결할 임무 문제와 기대 결과를 먼저 정합니다. 막힌 경유점을 건너뛰기, 목표 위치 바꾸기, 부분 경로 반환하기는 서로 다른 기능입니다. 지형 충돌 처리의 성능 측정도 시뮬레이터가 기본적으로 동작하는지 확인하는 작업과 나누어 진행합니다.
