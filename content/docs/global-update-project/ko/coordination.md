---
title: "협업과 산출물"
weight: 40
draft: false
translation_source: "en/coordination.md"
translation_revision: "8e4d9a6"
---

# 작업과 근거를 함께 볼 수 있게 합니다

[프로젝트 개요]({{< ref "docs/global-update-project/ko/_index.md" >}}) · [English]({{< ref "docs/global-update-project/en/coordination.md" >}})

공유 GitHub Project로 운용 코드, 마이그레이션, 문서, 공동 검증을 연결합니다. [조직 Project](https://github.com/orgs/URC-kaist/projects/2)와 [마이그레이션 fork](https://github.com/URC-kaist/mr2-stack-jazzy)를 생성했습니다. 영문 착수 이슈 13개를 연결·분류했으며 담당자와 날짜는 미지정입니다. Project는 조직 정책에 따라 비공개이며 SW 팀장에게 관리자 권한을 부여했습니다. 공개 전환은 조직 소유자가 해야 합니다.

[Project 구성 초안]({{< project-resource "projects/global-update-project/project.json" >}})과 [한국어 착수 이슈]({{< project-resource "projects/global-update-project/issues.ko.json" >}})를 내려받을 수 있습니다. 검토용 자료이며 GitHub API에 바로 가져오는 형식은 아닙니다.

## 작은 Project에서 시작합니다

| 필드 | 용도 |
| --- | --- |
| Status | Backlog, Ready, In progress, In review, Blocked, Done |
| Workstream | Platform, Navigation/Simulation, Communication/UI, Control/CAN, Perception/Video, System verification |
| Priority | P0 prerequisite, P1 migration, P2 capability investigation |
| Required environment | Workstation, Nano, NX, 공동 로버/필드 시험; 여러 환경을 기재 가능 |
| Assignees | SW 팀장이 이슈에서 지정 |

의존성, 명령, 작업량 범위, 근거, 남은 검증은 연결된 이슈/PR에 둡니다. 투입 여력과 URC 2027 일정이 합의된 뒤 날짜·iteration을 추가합니다. 실행 보드, 하드웨어 대기열, 통합 로드맵이 유용한 보기입니다.

PR 병합은 구현 작업을 닫을 수 있지만 별도 NX/시스템 검증 이슈까지 완료하지는 않습니다. 통과 결과마다 소스, 환경, 설정을 식별합니다. 새 변경이 있으면 이전 근거의 유효성을 확인합니다. [GitHub Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects)

## 저장소 정책

우선 검토하는 방향은 이력을 보존하는 마이그레이션 fork, 작은 브랜치/PR, upstream 수정 반영 절차, 명시적인 운용/후보 환경입니다. API 변경 때문에 기술적으로 fork가 반드시 필요한 것은 아닙니다. 협업과 배포 계열을 명확히 구분하는 것이 목적입니다. 팀 소유권, 기준 이슈 위치, 인수된 코드의 최종 반영 위치를 함께 정합니다. [GitHub fork 모델](https://docs.github.com/en/pull-requests/reference/forks)

처음부터 다시 작성하려면 구체적 한계, 대체 설계, 대표 프로토타입, 기능 동등성 요구, 전환 계획이라는 별도 기술 근거가 필요합니다. 마이그레이션 저장소 생성이 전면 재작성을 뜻하지는 않습니다.

## Project는 색인이고 파일은 저장소가 보관합니다

| 산출물 | 제안 위치 |
| --- | --- |
| 환경 구성 절차, 작은 manifest, 시험 요약 | 버전 관리되는 저장소 파일 |
| 일반 CI 로그·빌드 결과 | 보존 기간을 지정한 Actions artifacts |
| 선택한 릴리스 묶음 | 크기·접근 조건에 맞는 Release assets |
| 대형 복구 이미지, bag, 영상, 데이터셋 | 팀이 관리하는 지속적인 저장 공간 |

이슈에 산출물 manifest를 연결합니다. 목적, 위치, 소스 SHA, 하드웨어/BSP/설정, 체크섬, 접근, 보존 정책을 담습니다. Actions artifacts는 만료되거나 실행 삭제와 함께 사라질 수 있으므로 인수된 릴리스와 복구 자료는 별도로 보존합니다. [산출물 수명 주기](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/remove-workflow-artifacts), [바이너리 배포](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)

팀이 저장 위치를 선택하고 공동 접근을 확인합니다. 인증 정보는 일반 근거 묶음에 넣지 않고 적절한 접근 관리 수단으로 다룹니다.

## 협의 주기

짧은 정기 검토에서 운용 수정 사항, 후보 빌드 상태, 공통 인터페이스 변경, 장비 대기열, 다음에 입증할 결과를 확인합니다. 주간 검토를 출발점으로 제안하되 실제 가용 시간에 맞춥니다. NX 정비 시간 충돌은 SW 팀장, HW 통합, 지정된 릴리스 권한자와 조정하고 다른 작업은 계속합니다.

문서는 안정적인 설명, 이슈/PR은 진행 상태, 시험 기록은 결과를 담습니다. 서로 연결하여 개인 대화를 재구성하지 않고도 판단할 수 있게 합니다.
