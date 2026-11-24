---
title: "Mission Master와 비전"
weight: 2
draft: false
bookCollapseSection: true
translation_source: "content/docs/2026_mr2/navigation/mission_master_and_vision.md"
translation_source_sha256: "1b9af81352cfd381908a6f7401d51566a63bf08f182b69d475c00563e9b4bde5"
translation_status: "review-needed"
---

# Mission Master와 비전

*원문: Jaeuk Kim, 2026년 3월*

[English]({{< ref "docs/2026_mr2/navigation/mission_master_and_vision.md" >}})

> 이 설명은 Jaeuk Kim이 팀을 떠나기 전인 2026년 3월경에 작성했습니다. 당시의 설계를 설명하므로 이후 구현 변경 사항은 반영되어 있지 않을 수 있습니다. 이번 공개에서는 일부 사실 및 기초 개념 오류만 수정했으며, 현재 구현에 맞춰 문서 전체를 갱신하지는 않았습니다.

*일부 오류 수정: 2026년 11월 25일.*

Translation: used [pianojay/mr2-translation-ko](https://github.com/pianojay/mr2-translation-ko), November 25, 2026.

## 행동 트리와 액션: 자율 주행 파이프라인을 지휘하기

거창한 제목이지만 근거 없는 말은 아닙니다. Navigation은 *자율* 주행을 구성하는 하위 모듈일 뿐입니다.
우리는 자율 주행 스택에 명령을 내리고, 필요할 때 멈추고 다시 시작하는 일을 *자동화*하려는 것입니다.
생각은 단순하지만 구현은 간단해 보이지 않습니다.
다행히 Nav2와 ROS2에는 이를 확장할 도구가 있습니다.

### Nav2의 행동 트리

먼저 Nav2의 행동 트리(BT) 튜토리얼과 BehaviorTree.cpp 문서를 읽어 개념을 익히기를 권합니다.
좀 더 욕심이 난다면 Probabilistic Robotics를 참고해도 좋습니다.

BT 튜토리얼을 읽다 보면 유행에 맞춰 유한 상태 머신(FSM)을 전부 BT로 바꾸고 싶어질 수 있습니다. 이론적으로는 가능하지만, 개발과 유지보수는 악몽이 될 것입니다.
조금 짓궂게 말하면, **BT는 계층적인 예외 처리에 적합하지 않습니다.** 더 편하게 말하자면 논리 제어에는 영 좋지 않습니다. 단순한 진행 상태 이상의 논리가 있다면, FSM을 사용해 일반 코드로 작성해야 합니다.

BT는 구조가 정해져 있고 예측 가능하며 주기적으로 반복되는 파이프라인에 좋습니다. 자율 주행 파이프라인이 그렇고, Nav2가 바로 이렇게 구현되어 있습니다.
먼저 Nav2 구성 요소를 모두 실행해 사용할 준비를 합니다. 그다음 BT를 실행하는 액션이 주행을 시작합니다.
여기서 계획기는 경로를 만들고 컨트롤러는 속도 명령을 생성하며, 이 과정이 틱마다 이어집니다.

BT는 XML 파일로 정의하고, 외부에서 실행 요청을 받아 그 설명대로 동작합니다.
기본적으로 Nav2는 NavigateToPose와 NavigateThroughPoses라는 두 BT 실행 인터페이스를 제공합니다.
기본 구성을 복사한 뒤 임무에 맞게 수정할 수 있습니다.

### ROS2의 액션 서버

*ROS2*에는 토픽, 서비스, 그리고 액션이 있습니다.
애초에 왜 구분했을까요?

토픽은 단순합니다. 한쪽이 발행하고 다른 쪽이 구독합니다. 다른 노드가 처리할 정보를 널리 전달하는 방식입니다.

서비스는 함수 호출과 비슷합니다. 클라이언트가 요청을 보내면 서비스 서버가 처리하고 응답을 돌려줍니다. 응답 필드는 비어 있을 수도 있습니다. 클라이언트는 응답을 비동기로 처리할 수 있습니다.
LED용 CAN 인터페이스나 navsat_transform 노드의 `toLL`, `fromLL` 좌표 변환 서비스에서 이런 구현을 볼 수 있습니다.
서비스는 간헐적이고 즉시 처리하는 작업에 사용하며, 메시지 구조는 `.srv` 파일로 정의합니다.

액션은 한 단계 더 확장된 방식입니다.
함수 호출과 비슷하지만, 오래 걸리면서 중간 상태를 확인하거나 개입해야 하는 작업에 더 적합합니다.
액션 서버가 제공하는 작업을 액션 클라이언트가 호출하고, 상태를 확인하고, 실행에 개입할 수 있습니다.
메시지 구조는 `.action` 파일로 정의합니다.

Nav2는 경로 계획과 경로 추종 같은 작업을 액션 서버로 제공하며, 다른 구성 요소는 서비스와 토픽도 사용합니다. 자율 주행 액션은 개발 시 사용할 수 있는 BT 노드로 이미 노출되어 있습니다. 한편, 우리는 상위 지휘와 규칙 기반 처리를 담당하는 모듈을 액션 서버로 구현합니다.

## 행동 트리 구성

Nav2는 기본적으로 NavigateToPose와 NavigateThroughPoses라는 두 행동 트리 실행 인터페이스를 제공합니다.

### NavigateToPose

NavigateToPose는 목표 하나를 받고, 로버가 그 목표에 도달하면 SUCCESS로 판단합니다. “A에서 B로 가기”에 유용합니다. 자세한 내용은 `my_navigate_to_pose.xml` 구현을 참고하세요.

### NavigateThroughPoses

NavigateThroughPoses는 목표 배열을 받고, 배열에 남은 목표가 없으면 SUCCESS로 판단합니다. 기본 BT는 목표에 도착하면 해당 목표를 제거합니다. 우리는 RemovePassedGoals 노드로 이를 보완했습니다. 자세한 내용은 `my_navigate_through_poses.xml` 구현을 참고하세요.

## 액션 서버 구성

이제 올바른 BT를 호출하고 목표 하나 또는 목표 배열을 전달할 주체가 필요합니다.
여기서 드디어 자율 주행 임무를 기준으로 프로그램을 작성할 수 있습니다.

임무는 “GNSS-only”와 “Coverage and Vision” 두 종류로 나눕니다.
전자는 단순히 “A에서 B로 가기”이고, 후자는 추가 단계와 계획이 필요합니다.

### GnssOnly 액션 서버

GnssOnly는 목표 좌표를 받아 NavigateToPose를 호출합니다.
액션 인터페이스인 `GnssOnly.action`은 다음과 같습니다.

```text
# GnssOnly.action definitions
# Goal - GPS coordinate to navigate to
float64 target_latitude
float64 target_longitude
---
# Result - Final outcome
int32 navigation_result    # 1 = SUCCESS, 0 = NOT SUCCESS
---
# Feedback - BT execution status
int32 bt_status           # 1 = RUNNING, 0 = NOT RUNNING
```

자세한 내용은 GnssOnly 액션 노드의 전체 구현을 참고하세요.

### CoverVision 액션 서버

CoverVision은 목표 좌표, 탐색 방법, 탐색 반지름, 물체 종류를 받습니다.
먼저 NavigateToPose를 호출하고, 나선 형태의 목표들을 만든 뒤 NavigateThroughPoses를 호출합니다.
나선 탐색 중 *비전 어댑터*에서 물체 자세를 받으면 NavigateThroughPoses를 멈추고, NavigateToPose를 호출해 로버가 물체를 바라보도록 합니다.
액션 인터페이스인 `CoverVision.action`은 다음과 같습니다.

```text
# CoverVision.action definitions
# Goal - GPS coordinate, radius, detection method
uint8 detection_method  # 0 = NONE, 1 = ARUCO, 2 = YOLO
float64 target_latitude
float64 target_longitude
float64 target_radius       # in meters
int32 object_type          # optional semantic class or tag id
---
# Result - Final outcome with waypoint completion info
int32 mission_result        # 1 = SUCCESS, 0 = FAILURE
int32 waypoints_completed    # How many waypoints were successfully visited
---
# Feedback - Coverage mission progress
int32 bt_status             # 1 = RUNNING, 0 = NOT_RUNNING
int32 total_waypoints       # Total waypoints generated
int32 current_waypoint_index # Current waypoint being navigated to
```

자세한 내용은 CoverVision 액션 노드의 전체 구현을 참고하세요.

### MissionMaster 노드

MissionMaster는 액션 클라이언트로서 GnssOnly와 CoverVision 액션 서버를 지휘합니다.
베이스 스테이션과 MissionMaster 사이의 인터페이스를 살펴보겠습니다.
효과적인 제어와 명령 전달을 위해 MissionList, MissionControl, MissionStatus라는 사용자 정의 메시지를 만들었습니다.

MissionList는 각 자율 주행 임무를 나타내는 MissionSpec의 배열입니다.

```text
# Mission specification for Mission Master
# mission_type: 0=UNKNOWN, 1=GNSS_ONLY, 2=COVER_VISION
# detection_method: 0=NONE, 1=ARUCO, 2=YOLO
# object_type (used by YOLO): 0=MALLET, 1=PICK, 2=BOTTLE
uint32 mission_id
uint8 mission_type
uint8 detection_method
int32 object_type

# WGS84 target (required for GNSS_ONLY and COVER_VISION)
float64 target_latitude
float64 target_longitude

# Coverage parameters (used by COVER_VISION)
float64 target_radius
uint32 waypoint_count
```

MissionControl은 명령 인터페이스입니다. 상태는 MissionStatus로 확인하므로 서비스 대신 토픽으로 구현했습니다.
MissionControl 토픽은 가장 신뢰성 높은 명령·제어 전달을 위해 SiK bridge를 사용합니다.

```text
# Command channel for Mission Master
# command: 0=NOOP, 1=PAUSE, 2=RESUME, 3=ABORT
uint8 command

# Optional: clear costmaps when pausing or aborting
bool clear_costmap

# Optional: target mission id (0 = current mission)
uint32 mission_id
```

MissionStatus는 임무 진행 상황과 상태를 주기적으로 보고합니다.

- mr2_led 패키지의 `mission_status_led_node`는 이 토픽을 구독하고 LED 서비스를 호출합니다. LED 노드가 처리하는 전체 규약은 `mr2_led/README.md`를 참고하세요.
- `twist_to_commands_controller`도 이 토픽을 구독해 `/cmd_vel` 입력을 선택합니다. 상태가 RUNNING이 아니면 수동 조작을 위해 `/base/cmd_vel`을 구독합니다.

```text
# Mission Master status report
# state: 0=IDLE, 1=RUNNING, 2=PAUSED, 3=COMPLETED, 4=FAILED
builtin_interfaces/Time stamp
MissionSpec active_mission
uint8 state
bool arrival

# Coverage progress (optional)
uint32 current_waypoint_index
uint32 total_waypoints

# Nav2 feedback (meters). Use negative if unknown.
float32 distance_remaining

# Optional human-readable detail or error
string detail
```

Mission Master는 MissionList를 순서대로 처리하면서 GnssOnly 또는 CoverVision을 실행하고 각 액션 서버에 임무 정보를 전달합니다. 일시 정지와 재개, 비용 지도 초기화 같은 추가 명령도 보낼 수 있습니다.
임무를 마치면 10초 동안 `arrival == true`를 보고하고, 임무 목록이 소진되면 COMPLETED를 보고합니다.
PAUSED는 수동 조작을 위한 상태입니다. ABORT 명령을 보내거나 자율 주행 스택이 실패하면 FAILED가 됩니다.

## 비전으로 물체 위치 추정하기

이 절에서는 센서에서 CoverVision까지 비전 파이프라인이 어떻게 동작하는지 살펴보겠습니다.
비전 파이프라인은 계층상 Nav2와 같은 수준에 있지만, 구조가 더 단순하므로 여기서 설명합니다.

처리 구조는 다음과 같습니다.

1. 센서 좌표계에서 물체 위치를 추정합니다.
2. 위치 정보를 map 좌표계로 변환합니다.
3. 위치 추정값을 필터링합니다.

### ArUco Tracker

ArUco 입력은 `front_uvc_camera.launch.py`로 `v4l2_camera_node`를 실행해 `front_camera`에 연결합니다.
입력 토픽은 `/image_raw`입니다.

OpenCV ArUco Tracker 라이브러리로 ArUco 태그의 자세를 추정합니다.
태그 크기를 미리 알기 때문에 깊이 정보는 필요하지 않습니다.
ArUco Tracker 노드는 [`aruco_opencv_msgs/msg/arucodetection`](https://docs.ros.org/en/kilted/p/aruco_opencv_msgs/msg/ArucoDetection.html) 형식의 토픽을 발행하므로, 필요한 정보를 꺼내 처리해야 합니다. 이 일은 `cover_vision_aruco_adapter` 노드가 담당합니다.

### YOLO와 깊이 지도

YOLO와 깊이 정보, IMU에는 `realsense_rgbd.launch.py`를 사용합니다. 이 launch는 `realsense2_camera_node`를 실행하고 `rgbd_camera`에 연결합니다.
바운딩 박스 추론에는 `/color/image_raw`를, 깊이 지도에는 `/aligned_depth_to_color/image_raw`를 입력으로 받습니다.

2차원 물체 검출에는 미세 조정한 YOLO11을 사용합니다.
하지만 이것만으로는 카메라에 투영된 바운딩 박스만 얻으므로 깊이 지도도 함께 사용합니다. 바운딩 박스의 중심 픽셀을 읽어 물체 깊이를 추정합니다. 이는 읽은 깊이가 물체 표면의 값이라는 가정입니다. 중심이 배경이나 지면에 걸리면 잘못된 물체 거리를 얻을 수 있습니다.

전체 위치 추정을 사용할 수 있으면 센서 좌표계의 물체 위치를 발행합니다. 물체가 세 종류이므로 종류별로 세 가지 토픽을 발행합니다.
`cover_vision_yolo_adapter` 노드가 이 입력을 선별하고 처리합니다.

### CoverVision 연결: 어댑터 노드

각 어댑터 노드는 입력 토픽에서 정보를 꺼내고, 조건에 따라 선별하고, 필터링합니다. 최종적으로 CoverVision이 사용할 수 있는 `map` 좌표계의 물체 자세를 만듭니다.
두 어댑터는 독립적으로 설정할 수 있으며 다음을 지원합니다.

1. 거리 게이팅: 물체가 너무 멀면 잡음일 가능성이 높다고 보고 입력을 무시합니다.
2. 점프 게이팅: 새로 평활화한 물체 위치가 직전에 발행한 위치에서 임계값보다 멀리 떨어져 있으면 새 값을 발행하지 않습니다. 직전에 발행한 위치를 비교 기준으로 유지합니다. 오검출을 줄이기 위한 불완전한 휴리스틱입니다.
3. 평활화: 일정한 크기의 창에 모은 위치들을 사용해 값을 부드럽게 만듭니다.

## 정리

이제 베이스 스테이션에서 자율 주행 스택과 비전 모듈까지 전체를 계층적으로 살펴보겠습니다.

1. 베이스 스테이션은 MissionMaster와 직접 통신해 임무 목록과 명령을 보냅니다. MissionMaster는 임무 상태를 발행합니다.
2. MissionMaster는 임무 목록을 순서대로 처리하고, 임무 종류에 따라 GnssOnly 또는 CoverVision을 호출하며 인자를 전달합니다.
3. GnssOnly는 NavigateToPose로 목표 좌표까지 이동합니다. 도달하면 SUCCESS를 보고합니다.
4. CoverVision은 NavigateToPose로 탐색 장소까지 이동하고, 나선 형태의 목표들을 만든 뒤 NavigateThroughPoses를 호출합니다. 비전 어댑터가 필터링된 물체 위치를 보고하면 주행을 중단하고 NavigateToPose로 물체를 바라보게 합니다. 로버가 물체를 바라보거나 나선 경로를 완주하면 SUCCESS를 보고합니다.
5. MissionMaster는 임무가 SUCCESS일 때마다 `arrival==true`를 보고하고, 전체 목록이 소진되면 자신도 SUCCESS를 보고합니다.
