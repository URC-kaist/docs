---
title: "한국어"
weight: 2
draft: false
bookCollapseSection: true
translation_source: "en/_index.md"
translation_source_sha256: "af394a6ff25ba45fdcef8481417ed1cf4c4427256947116df25fa65da91f5771"
translation_status: "review-needed"
---

# MR2 글로벌 업데이트 개발 안내 {#mr2-글로벌-업데이트-개발팀-안내}

[English]({{< ref "docs/global-update-project/en/_index.md" >}})

**로버 소프트웨어가 Ubuntu 24.04와 ROS 2 Jazzy에서 동작하도록 옮기는 프로젝트입니다. 개발하는 동안 기존 Orin NX 로버는 계속 사용할 수 있도록 유지합니다.** 새 환경의 설치와 Jetson에서의 시험은 여분의 Orin Nano에서 진행합니다. NX의 운용을 중단해야 하는 시험은 미리 준비하고 일정을 잡아 진행합니다.

URC 2027을 준비하면서 새 팀원도 개발 환경을 쉽게 구성하고, 같은 절차로 빌드와 시험을 반복할 수 있게 만드는 것이 목표입니다. 앞으로도 유지보수할 수 있는 패키지 조합을 갖추고, 로버 전체가 함께 동작하는지도 확인합니다. 새 버전의 유용한 기능도 살펴보되, 기존 기능을 옮기는 작업과 새 기능 실험은 통과 기준을 따로 정합니다.

## 개발자로서 궁금한 점 {#개발자로서-궁금한-점}

| 질문 | 읽을 문서 |
| --- | --- |
| 24.04/Jazzy로 옮긴다는 것은 무엇을 바꾸는 일인가요? | [업데이트 범위와 원칙]({{< ref "docs/global-update-project/ko/platform.md" >}}) |
| 어디서 시작하나요? Humble 코드도 계속 고쳐야 하나요? | [개발 시작하기]({{< ref "docs/global-update-project/ko/start.md" >}}), [개발 절차]({{< ref "docs/global-update-project/ko/workflow.md" >}}) |
| 분야별로 나누어 동시에 작업할 수 있나요? | [분야별 작업과 협업]({{< ref "docs/global-update-project/ko/work-packages.md" >}}) |
| Codex에 맡길 일과 사람이 확인할 일은 어떻게 나누나요? | [컨트롤러 포팅 예제]({{< ref "docs/global-update-project/ko/controller-example.md" >}}) |
| 개발자 PC나 Nano에서 통과하면 NX에서도 쓸 수 있나요? | [장비별 시험과 로버 검증]({{< ref "docs/global-update-project/ko/acceptance.md" >}}) |
| 새 패키지의 기능도 도입할 수 있나요? | [새 기능 평가 원칙]({{< ref "docs/global-update-project/ko/platform.md" >}}) |

## 어느 장비에서 작업하나요? {#운용-모델}

| 장비 | 할 일 |
| --- | --- |
| 개발자 PC | 코드 수정, 클린 빌드, 시뮬레이션, 새 기능 조사를 병렬로 진행합니다. |
| 재설정 가능한 Orin Nano | 실제 arm64/NVIDIA 환경에서 설치, 장치 연동, 복구 절차를 시험합니다. |
| 운용 중인 Orin NX 로버 | 합의한 시간에 NX 전용 기능과 실제 로버 동작을 검증합니다. |

Jazzy를 개발하는 동안 현재 로버가 쓰는 Humble 코드도 유지보수합니다. 기존 commit 이력을 이어받은 마이그레이션용 fork를 준비했으며, 두 저장소 사이에서 수정 사항을 반영하는 방법은 [개발 절차]({{< ref "docs/global-update-project/ko/workflow.md" >}})에서 설명합니다.

## 작업 배정과 첫 회의 {#협업과-착수-회의}

담당자와 투입 가능한 시간은 현 SW 팀장 `@yongwhan-chung`이 조정합니다. [공유 Project](https://github.com/orgs/URC-kaist/projects/2)와 [마이그레이션 fork](https://github.com/URC-kaist/mr2-stack-jazzy)를 만들고, 담당자 미배정 상태의 착수 이슈 13개를 등록했습니다. Project는 조직 내 비공개이며 SW 팀장에게 관리자 권한이 있습니다. 자세한 사용 방법은 [Project와 파일 관리]({{< ref "docs/global-update-project/ko/coordination.md" >}})를 참고하세요.

먼저 기준 commit과 첫 릴리스에서 지원할 운용 모드를 정합니다. Nano를 가져와 사용할 수 있도록 준비하고, 초기 빌드·재현 작업을 배정하며, HW 담당자와 로버 운용자가 참여할 시험을 계획합니다. 첫 결과를 본 뒤 분야별 포팅과 URC 2027 통합 시험 일정을 구체화합니다. [첫 회의에서 정할 일]({{< ref "docs/global-update-project/ko/agenda.md" >}})

기존 조사에서는 주요 변경 지점을 확인했습니다. 아직 두 Jetson에서 Jazzy 환경을 빌드하거나 검증한 것은 아닙니다. [기술 조사 결과]({{< ref "docs/global-update-project/ko/research.md" >}}) · [장비별 시험과 로버 검증]({{< ref "docs/global-update-project/ko/acceptance.md" >}})
