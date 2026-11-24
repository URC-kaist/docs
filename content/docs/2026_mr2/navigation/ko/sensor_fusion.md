---
title: "센서 융합"
weight: 2
draft: false
bookCollapseSection: true
translation_source: "content/docs/2026_mr2/navigation/sensor_fusion.md"
translation_source_sha256: "b57738f2ff5181308843c1a20ed90ee3e3bd8f306ada4b0368889448f1168ca0"
translation_status: "review-needed"
---

# 센서 융합

*원문: Jaeuk Kim, 2026년 3월*

[English]({{< ref "docs/2026_mr2/navigation/sensor_fusion.md" >}})

> 이 설명은 Jaeuk Kim이 팀을 떠나기 전인 2026년 3월경에 작성했습니다. 당시의 설계를 설명하므로 이후 구현 변경 사항은 반영되어 있지 않을 수 있습니다. 이번 공개에서는 일부 사실 및 기초 개념 오류만 수정했으며, 현재 구현에 맞춰 문서 전체를 갱신하지는 않았습니다.

*일부 오류 수정: 2026년 11월 25일.*

Translation: used [pianojay/mr2-translation-ko](https://github.com/pianojay/mr2-translation-ko), November 25, 2026.

이 문서에서는 위치 추정을 위한 센서 융합을 이야기하겠습니다.

RTK 정보를 받은 이중 GNSS로 센티미터 수준의 위치를 얻더라도, GNSS 데이터는 1초마다 들어오므로 로버의 추정 자세가 불연속적으로 튈 수 있습니다. 따라서 그 사이의 시점은 상대적인 센서 정보를 융합해 추정해야 합니다.

구성을 요약하면 다음과 같습니다.

1. RTK-GNSS: 전역 방향(yaw)과 위치(WGS84), 낮은 주기
2. 바퀴 엔코더 오도메트리: 국소 속도, 높은 주기
3. IMU 가속도계와 자이로스코프: 국소 방향(roll, pitch)과 속도, 높은 주기

## 불확실성: 잡음과 외란

아무것도 그대로 믿을 수는 없습니다.
센서 데이터에는 저마다 오차가 있고, 작은 충격이나 흔들림에도 측정값이 변합니다.
그렇다고 모든 것이 무작위이고 예측 불가능하다는 뜻은 아닙니다. 불확실성이 있다는 뜻입니다.

여기서 잡음(Noise)과 외란(Disturbance)을 구분합니다. 잡음은 센서 자체에 내재하며, 외란은 주변 환경에서 오는 변화입니다.

- 잡음:
  - IMU와 바퀴 엔코더의 잡음 및 바이어스: 정지해 있어도 열 잡음 등으로 측정값이 변합니다.
  - GNSS 위치의 튐: 수렴 상태가 좋지 않거나 RTK가 끊기면 GNSS 위치가 갑자기 10여 미터씩 튈 수 있습니다.
- 외란:
  - 울퉁불퉁한 지면이나 강한 바람이 로버의 운동에 영향을 줄 수 있습니다.

따라서 입력은 값만으로 표현하지 않고, 이러한 잡음을 가우스 분포로 나타내는 공분산과 함께 다룹니다.

## 칼만 필터란 무엇이며, 무엇을 확장할까요?

칼만 필터는 잡음이 있는 측정값과 그 공분산을 사용해 상태 추정의 예측과 보정을 반복합니다. 최적성은 모델과 잡음에 대한 가정에 달려 있습니다. 참 상태로의 수렴을 무조건 보장하는 것은 아닙니다.

확장 칼만 필터(EKF)는 비선형 운동 모델과 측정 모델을 야코비안 행렬로 국소 선형화합니다. robot_localization에서는 3차원 방향과 운동의 기구학 관계에 비선형성이 나타나며, 지리 좌표 변환은 별도로 처리합니다. 이 관계들은 선형이 아니지만, 현재 추정값 주변에서 국소적으로 근사합니다.

칠판과 분필 없이 이 개념을 설명하기는 어렵네요. 양해 부탁드립니다.

요지는 칼만 필터가 측정 불확실성(R)과 예측 모델의 과정 불확실성(Q)을 사용해 상태와 그 불확실성(P)을 추정한다는 것입니다. robot_localization에서 Q는 과정 잡음 공분산으로 설정하며, 별도로 설정하는 또 하나의 센서 잡음 공분산이 아닙니다. R은 측정 공분산에서 오고, P는 상태 추정의 불확실성을 나타냅니다.

이 과정을 거치면 EKF가 센서 융합 장치로 동작해 연속적인 위치 추정을 제공합니다.

## Dual-EKF 구성과 이중 안테나 헤딩

[공식 튜토리얼](https://docs.ros.org/en/noetic/api/robot_localization/html/integrating_gps.html)을 읽어 보세요.
엔지니어와 개발자로서 `map`, `odom`, `base_link` 좌표계의 관계를 이해하려면 [REP-105](https://www.ros.org/reps/rep-0105.html)도 도움이 됩니다. 중간의 `odom` 좌표계는 GNSS를 사용하는 오도메트리와 사용하지 않는 오도메트리의 차이를 다루는 데 중요합니다.

1. EKF Local: `odom` -> `base_link`

   GNSS 정보 없이 위치를 추정하므로 IMU와 바퀴 오도메트리만 받습니다.

2. EKF Global: `map` -> `base_link` (따라서 `map` -> `odom`)

   GNSS 정보를 포함한 위치 추정입니다.
   tf: `odom` -> `base_link`와 tf: `map` -> `base_link`가 완전히 일치한다면, tf: `map` -> `odom`은 항등 변환에 가까워집니다.
   물론 항상 그렇지는 않습니다. 그래서 GNSS를 사용하는 센서 융합과 사용하지 않는 센서 융합에 별도의 좌표계가 필요합니다.

`odom` 좌표계는 완충 역할을 해 연속적인 위치 추정을 유지합니다. GNSS가 주기적으로 갱신되어도 로버의 오도메트리가 튀지 않게 하는 것입니다.
즉, `map` -> `base_link`는 튈 수 있지만 `odom` -> `base_link`는 연속적입니다. 경험상 `map` -> `base_link`의 튐은 무시할 만했습니다.

## 이중 안테나: 헤딩 주입

Navsat Transform은 WGS84 위치를 world 좌표계, 여기서는 `map`으로 변환합니다. Datum은 초기화 과정이나 서비스 호출로 정합니다.
GNSS 위치, 방향 정보, 오도메트리로 좌표 변환을 정합니다. 출력은 GNSS 위치를 해당 world 좌표계로 표현한 것이며, /gps/fix만으로 완전한 방향 측정값을 얻는 것은 아닙니다.

문제는 IMU의 전역 yaw를 그다지 신뢰하기 어렵다는 것입니다. 자력계가 있는 IMU도 있지만, 자력계는 쉽게 교란됩니다.
그래서 navsat transform의 결과에 이중 안테나로 구한 헤딩을 주입합니다. 방향의 yaw 값을 기하학적으로 계산한 전역 yaw로 덮어써서 EKF Global이 일관된 정보를 받도록 합니다.

이 과정은 `gps_heading_gps_node`가 처리합니다.

“기하학적 계산”을 조금 더 설명하겠습니다.

GNSS 수신기 두 개가 있으면 WGS84 좌표 두 개를 얻습니다.
이 좌표들을 *ECEF* 좌표계로 변환하면 두 점 사이의 차이를 3차원 벡터로 나타낼 수 있습니다.
그 [차이 벡터를 ENU 좌표계로 다시 투영](https://gssc.esa.int/navipedia/index.php/Transformations_between_ECEF_and_ENU_coordinates)하면 동쪽을 0으로 하고 반시계 방향으로 증가하는 ROS 전역 yaw를 계산할 수 있습니다. 여기에 안테나 장착 방향의 오프셋을 적용하면 로버의 yaw를 얻습니다.
