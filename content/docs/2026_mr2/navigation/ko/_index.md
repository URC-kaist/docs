---
title: "한국어 설명"
weight: 3
draft: false
bookCollapseSection: true
---

# 자율 주행 상세 설명

[English]({{< ref "docs/2026_mr2/navigation/_index.md" >}})

아래 네 문서는 Jaeuk Kim이 팀을 떠나기 전인 2026년 3월경에 작성했습니다. 당시의 설계를 설명하므로 이후 구현 변경 사항은 반영되어 있지 않을 수 있습니다. 이번 공개에서는 원래 설명을 유지하면서 일부 사실 및 기초 개념 오류만 수정했습니다.

| 문서 | 내용 |
| --- | --- |
| [소개]({{< ref "docs/2026_mr2/navigation/ko/introduction.md" >}}) | 위치 추정, 경로 계획, 제어, 비용 지도 |
| [센서 융합]({{< ref "docs/2026_mr2/navigation/ko/sensor_fusion.md" >}}) | EKF와 이중 GNSS 안테나를 이용한 위치 및 자세 추정 |
| [지형 주행 가능성 파이프라인]({{< ref "docs/2026_mr2/navigation/ko/traversability_pipeline.md" >}}) | 깊이 카메라에서 비용 지도까지의 처리 과정 |
| [Mission Master와 비전]({{< ref "docs/2026_mr2/navigation/ko/mission_master_and_vision.md" >}}) | 임무 실행과 물체 위치 추정 |

## 지도 생성

[지도]({{< ref "docs/2026_mr2/navigation/ko/maps.md" >}})는 2026년 11월에 문서화한 별도의 map-pipeline 작업을 설명합니다. 지형 지도, 대시보드 타일, 실행 중인 로버와 연결할 때 확인할 사항을 다룹니다.

Translation: used [pianojay/mr2-translation-ko](https://github.com/pianojay/mr2-translation-ko), November 25, 2026.
