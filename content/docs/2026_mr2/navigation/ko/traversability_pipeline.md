---
title: "지형 주행 가능성 파이프라인"
weight: 2
draft: false
bookCollapseSection: true
translation_source: "content/docs/2026_mr2/navigation/traversability_pipeline.md"
translation_source_sha256: "99a5a1a65d32d0316ec03d2728797d90e10bebd6e3ec957f30615a65d0845314"
translation_status: "review-needed"
---

# 지형 주행 가능성 파이프라인

*원문: Jaeuk Kim, 2026년 3월*

[English]({{< ref "docs/2026_mr2/navigation/traversability_pipeline.md" >}})

> 이 설명은 Jaeuk Kim이 팀을 떠나기 전인 2026년 3월경에 작성했습니다. 당시의 설계를 설명하므로 이후 구현 변경 사항은 반영되어 있지 않을 수 있습니다. 이번 공개에서는 일부 사실 및 기초 개념 오류만 수정했으며, 현재 구현에 맞춰 문서 전체를 갱신하지는 않았습니다.

Translation: used [pianojay/mr2-translation-ko](https://github.com/pianojay/mr2-translation-ko), November 25, 2026.

Traversability(지형 주행 가능성)는 어떤 영역을 안전하게 통과할 수 있는지 수치로 나타낸 값입니다.
“장애물 비용”을 조금 더 멋지게 표현한 말처럼 볼 수도 있지만, 플랫폼에 따라 달라진다는 점에서 의미가 더 섬세합니다. 예를 들어 우리의 4WS4WD 플랫폼은 사람이 지켜보지 않아도 최대 0.5 rad의 경사와 높이 0.1 m의 거친 장애물을 통과할 수 있습니다.

따라서 파이프라인은 다음을 처리해야 합니다.

1. 기울어지지 않은 좌표계를 기준으로 주변 지형 정보를 얻습니다. (`pc2_to_heightmap_node`)
2. 플랫폼에 맞게 데이터를 필터링해 주행 가능성을 구합니다. (`traversability_filter_node`)
3. 결과를 Nav2 비용 지도에 반영합니다. (`mr2_nav2_plugins::TraversabilityLayer`)

## `pc2_to_heightmap_node`

첫 번째 할 일은 `base_link` 좌표계에서 지형의 3차원 정보, 즉 높이 지도를 얻는 것입니다.
우리는 D435i를 사용하므로 ROS2 realsense wrapper에서 포인트 클라우드 스트림을 받을 수 있습니다.
직접 만든 `pc2_to_heightmap_node`는 관심 영역(ROI)을 0.1 m 해상도로 나누고 높이를 읽습니다.
ROI는 센서를 신뢰할 수 있는 거리인 0.3~3.0 m 범위에 고정하며, 크기는 3 m × 4 m입니다. 따라서 격자는 1200개 셀로 이루어집니다.
센서가 보는 영역은 원뿔 모양이므로, 좌우 일부 셀에는 점이 들어오지 않습니다.

포인트 클라우드의 점들을 순회합니다.
먼저 점들을 `base_link` 좌표계로 변환한 뒤 각 셀에 나눠 담습니다.
이제 셀마다 대표 높이를 정해야 합니다.
견고하면서도 명확한 처리를 위해, 저는 `std:nth_element`로 다섯 번째 순위의 값을 골랐습니다. 시간 복잡도는 O(N)입니다.
왜 다섯 번째일까요? 큰 값은 이상치여서 실제보다 과도한 높이를 나타낼 수 있기 때문입니다.
다만 이 선택은 충분히 시험하지 않았습니다. 최댓값을 써도 괜찮았을 수 있습니다.
저는 잠재적인 잡음을 걸러내려는 의도로 조금 더 보수적으로 선택했습니다.
반면 대표 높이로 중앙값이나 평균을 쓰면 지형 정보가 사라지므로 적절하지 않다는 점은 시험으로 확인했습니다.

결과는 `base_link` 좌표계의 GridMap 형식으로 발행합니다.

## `traversability_filter_node`

이 노드는 `grid_map_filters`를 사용해 필터 수식을 설정 파일로 전달할 수 있게 합니다.
이것이 애초에 `grid_map` 패키지를 사용하는 이유입니다.
Traversability 파이프라인을 디버깅하고 설계를 빠르게 반복하기가 쉬워집니다.

전체 구현은 `trav_pipeline.yaml`에서 볼 수 있습니다.

핵심 계산은 다음과 같습니다.

1. Inpainting: 주변 셀을 참고해 nan 값, 즉 점이 없는 셀을 채웁니다. 따라서 꽤 위험한 처리입니다.
2. 지오이드 기준 경사도: 이 노드가 필터링된 자세 추정값을 구독하는 것을 볼 수 있습니다. 중력 방향을 얻기 위한 것입니다. 높이 지도를 *지오이드* 좌표계로 변환해 절대 경사도를 구합니다. 이것이 위치 추정 파이프라인에서 3차원 자세 추정이 필요한 이유 중 하나입니다.
3. Roughness(거칠기): 주변 영역의 평균에서 얼마나 벗어나는지를 양수로 나타낸 값입니다. 값이 높으면 지면이 울퉁불퉁하다는 뜻입니다.

경사도와 거칠기로부터 최종 traversability를 부드러운 계단 함수로 계산합니다.
얕은 요철에서 나타나는 급한 경사는 무시하되, 절대 경사도와 큰 장애물에는 민감하게 반응하도록 한 것입니다.

시그모이드 함수가 다음과 같을 때:
{{< katex display=true >}}
    \sigma_k(x) = \frac{1}{1 + e^{-k x}}
{{< /katex >}}

부드러운 게이팅 함수는 다음과 같습니다.
{{< katex display=true >}}
    f(s,r) =
    \max\left(
    2\,\sigma_{50}(s-0.5)\,\sigma_{200}(r-0.1),
    \;
    2\,\sigma_{50}(r-0.1)
    \right)
{{< /katex >}}

그 뒤 결과를 0과 1 사이로 제한합니다.
0.5와 0.1은 플랫폼의 통과 능력을 기준으로 정했습니다.
50과 200은 함수가 얼마나 부드럽게 변하는지 결정합니다.

사실 이것은 주행 가능성이 아니라 *통행을 방해하는 정도*라는 것을 알아차렸을 것입니다.
지나갈 수 없을수록 값이 커집니다.
맞습니다. Nav2 비용 지도에 반영할 때 더 직관적이도록 방향을 뒤집었습니다.

## `TraversabilityLayer`: GridMap을 위한 사용자 정의 Nav2 Costmap2D 플러그인

GridMap 데이터를 반영하기 위해 [공식 튜토리얼](https://docs.nav2.org/plugin_tutorials/docs/writing_new_costmap2d_plugin.html)을 참고했습니다.

Nav2의 ObstacleLayer는 `scan`, `pointcloud2` 같은 원시 센서 데이터를 받는 옵션을 제공합니다.
하지만 GridMap 형식으로 계산된 데이터를 직접 받지는 못합니다.
Traversability를 다시 포인트 클라우드로 바꿔 넣는 식으로 ObstacleLayer에 맞추려는 시도도 많았습니다.
그러나 결국 직접 레이어를 만드는 쪽이 원하는 대로 조정하기 훨씬 쉬웠습니다.

TraversabilityLayer는 `nav2_costmap_2d::CostmapLayer`를 상속합니다. CostmapLayer는 공개된 “master” 비용 지도와 자체 비공개 비용 지도를 갖습니다.
Master 비용 지도는 각 Nav2 비용 지도 서버의 레이어 사이에서 전달되는 지도입니다. 이름이 혼동된다는 점은 저도 압니다.
먼저 자체 비용 지도에 traversability를 기록한 뒤 master 비용 지도와 합칩니다.
자체 비용 지도를 매번 처음부터 그리지 않으므로, 주변을 지도에 기록하고 그 정보를 유지할 수 있습니다.

GridMap을 자체 비용 지도에 반영하는 방법과 자체 지도를 공개 지도에 합치는 방법은 파라미터로 조절할 수 있습니다.
현재는 정보를 유지하는 방식으로 “maximum”을 사용합니다. 따라서 TraversabilityLayer는 기록한 것을 영역 밖으로 밀려날 때까지 잊지 않습니다.

자세한 내용은 소스 구현을 참고하세요.

## 개선할 여지

- Traversability 파이프라인은 전체 Nav2 다음으로 계산량이 많은 파이프라인 중 하나입니다.
  포인트 클라우드 스트림 주기를 제한해 부담을 줄였고, 그 덕분에 적어도 시스템을 운용할 수는 있었습니다.
  더 강력한 컴퓨터 없이도 파이프라인을 더 최적화할 수 있다고 생각합니다.
- 이를 위해 `pc2_to_heightmap_node`의 셀 분류 방식을 개선할 수 있습니다.
- Voxel 해상도를 0.05에서 0.01로 높여 볼 수도 있습니다. 0.05는 각도 계산에 너무 거친 것 같습니다.
