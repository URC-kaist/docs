---
title: "한국어"
weight: 2
draft: false
bookCollapseSection: true
translation_source: "en/_index.md"
translation_revision: "developer-guidance-2026-11-14"
---

# MR2 글로벌 업데이트: 개발팀 안내

[English]({{< ref "docs/global-update-project/en/_index.md" >}})

**기존 로버의 운용을 유지하면서, Ubuntu 24.04 / ROS 2 Jazzy 기반의 재현 가능하고 유지보수하기 쉬운 Orin NX 배포 환경을 준비합니다.** 자유롭게 재설정할 수 있는 Orin Nano에서 Jetson 네이티브 개발을 수행하고, NX의 운용 중단이 필요한 검증은 준비된 정비 시간에 진행합니다.

이 프로젝트는 개발자 온보딩, 반복 가능한 개발 환경, 패키지 지원 기반 개선, 시스템 통합 검증을 통해 URC 2027 준비를 뒷받침합니다. 새 패키지의 유용한 기능도 평가하되, 기존 동작의 호환성 확보와 신규 기능 실험은 서로 다른 인수 기준으로 관리합니다.

## 개발자로서 궁금한 점

| 질문 | 읽을 곳 |
| --- | --- |
| 24.04/Jazzy 업데이트는 실제로 무엇을 뜻하나요? | [플랫폼과 핵심 원칙]({{< ref "docs/global-update-project/ko/platform.md" >}}): 필요한 동작을 보존하며 플랫폼을 바꿉니다. |
| 어디서 시작하며 Humble과 Jazzy는 어떻게 공존하나요? | [개발 시작 카드]({{< ref "docs/global-update-project/ko/start.md" >}}), 이어서 [개발 절차]({{< ref "docs/global-update-project/ko/workflow.md" >}}). |
| 개발자들이 분야별로 병렬 작업할 수 있나요? | [업무 분담]({{< ref "docs/global-update-project/ko/work-packages.md" >}}): 분야, 의존성, 인력 배정에 필요한 정보입니다. |
| Codex가 절차적으로 할 일과 사람이 개입할 일은 무엇인가요? | [컨트롤러 로딩 예제]({{< ref "docs/global-update-project/ko/controller-example.md" >}}): 조사, 제안, 검증, 인계 과정을 따릅니다. |
| 워크스테이션과 Nano 시험이 한 대뿐인 NX에 관해 무엇을 입증하나요? | [공동 검증]({{< ref "docs/global-update-project/ko/acceptance.md" >}}): 환경별 근거와 준비된 NX 검증 시간입니다. |
| 새 기능도 배우고 통합할 수 있나요? | [기능 조사]({{< ref "docs/global-update-project/ko/platform.md" >}}): 호환성 작업과 함께 정확한 버전의 기능을 평가합니다. |

## 운용 모델

| 환경 | 역할 |
| --- | --- |
| 개발자 워크스테이션 | 병렬 개발, 클린 빌드, 시뮬레이션, 신규 기능 조사 |
| 재설정 가능한 Orin Nano | arm64/NVIDIA 스택 네이티브 통합, 환경 구성·복구 실험 |
| 운용 중인 Orin NX 로버 | 예정된 정비 시간의 실제 배포 환경 검증 및 필드 인수 시험 |

후보 환경을 개발하는 동안 Humble 운용 계열을 유지합니다. 마이그레이션용 fork를 팀의 검토 방향으로 제안하며, 준비된 로컬 저장소는 기존 이력을 보존합니다. [개발 절차]({{< ref "docs/global-update-project/ko/workflow.md" >}})

## 협업과 착수 회의

현 SW 팀장 **`@yongwhan-chung`**이 담당자와 투입 여력을 정합니다. 공유 GitHub Project와 양언어 착수 이슈를 작성했으며, GitHub Project·저장소 생성은 보류 중입니다. [협업과 산출물]({{< ref "docs/global-update-project/ko/coordination.md" >}})

통합 기준 커밋과 필수 운용 모드를 합의하고, Nano 인수·접근을 준비하며, 초기 재현성 작업과 HW/운용 담당자의 참여를 정합니다. 이후 실제 결과를 바탕으로 병렬 포팅과 URC 2027 통합 리허설을 계획합니다. [착수 회의 안건]({{< ref "docs/global-update-project/ko/agenda.md" >}})

조사를 통해 주요 포팅 경계를 확인했지만, 후보 환경을 두 Jetson에서 빌드하거나 검증한 상태는 아닙니다. [기술 조사]({{< ref "docs/global-update-project/ko/research.md" >}}) · [공동 검증]({{< ref "docs/global-update-project/ko/acceptance.md" >}})
