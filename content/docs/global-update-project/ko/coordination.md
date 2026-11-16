---
title: "Project와 파일 관리"
weight: 40
draft: false
translation_source: "en/coordination.md"
translation_source_sha256: "f0dd98bc26c535bae4b117580c7be3713bc2ab84094ea6d939b22114e4b85ffe"
translation_status: "review-needed"
---

# Project와 파일 관리 {#작업과-근거를-함께-볼-수-있게-합니다}

[프로젝트 개요]({{< ref "docs/global-update-project/ko/_index.md" >}}) · [English]({{< ref "docs/global-update-project/en/coordination.md" >}})

[공유 GitHub Project](https://github.com/orgs/URC-kaist/projects/2)에서 기존 운용 코드, 마이그레이션, 문서, 공동 시험 작업을 연결합니다. [마이그레이션 fork](https://github.com/URC-kaist/mr2-stack-jazzy)를 만들고 영문 착수 이슈 13개를 Project에 연결·분류했습니다. 이슈를 등록할 때는 담당자와 날짜를 지정하지 않았습니다.

Project는 조직 내 비공개이며 SW 팀장에게 관리자 권한이 있습니다. 공개로 바꾸려면 조직 소유자가 설정해야 합니다.

[Project 구성 초안]({{< project-resource "projects/global-update-project/project.json" >}})과 [한국어 착수 이슈 초안]({{< project-resource "projects/global-update-project/issues.ko.json" >}})도 내려받을 수 있습니다. 내용을 검토하기 위한 파일이며 GitHub API에 그대로 가져오는 형식은 아닙니다.

## Project에서 관리할 항목 {#작은-project에서-시작합니다}

| 필드 | 적을 내용 |
| --- | --- |
| Status | Backlog, Ready, In progress, In review, Blocked, Done 중 현재 상태 |
| Workstream | Platform, Navigation/Simulation, Communication/UI, Control/CAN, Perception/Video, System verification 중 작업 분야 |
| Priority | P0 prerequisite, P1 migration, P2 capability investigation 중 우선순위 |
| Required environment | 개발자 PC, Nano, NX, 로버·필드 시험 등 필요한 환경. 여러 개를 적을 수 있습니다. |
| Assignees | SW 팀장이 이슈에서 지정하는 담당자 |

선행 작업, 명령, 예상 작업량의 범위, 시험 결과, 아직 남은 검증은 연결된 이슈나 PR에 적습니다. 투입 가능한 시간과 URC 2027 준비 일정이 정해지면 날짜·iteration을 추가합니다. 진행 보드, 장비 사용 대기 목록, 통합 일정 보기로 나누어 살펴보면 편리합니다.

PR을 병합하면 코드 수정은 끝날 수 있습니다. 하지만 별도 NX·시스템 시험 이슈까지 자동으로 완료되는 것은 아닙니다. 시험을 통과할 때마다 소스 버전, 환경, 설정을 남기고, 코드가 바뀌면 이전 시험 결과를 계속 적용할 수 있는지 확인하세요. [GitHub Projects 안내](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects)

## 저장소를 함께 관리하는 방법 {#저장소-정책}

기존 이력을 이어받은 fork에서 작은 브랜치와 PR로 작업하는 방향입니다. 기존 운용 코드와 Jazzy 코드를 구분하고, 원본 저장소의 수정 사항을 가져오는 절차를 정합니다. API가 다르다는 이유만으로 fork가 필수인 것은 아니지만, 협업과 배포 대상을 명확히 구분하는 데 도움이 됩니다.

저장소 관리 책임, 이슈를 모을 위치, 검증한 코드를 최종 반영할 위치는 팀이 함께 정합니다. [GitHub fork 모델](https://docs.github.com/en/pull-requests/reference/forks)

처음부터 다시 작성하려면 별도의 기술 검토가 필요합니다. 기존 구현의 구체적인 한계, 대체 설계, 대표 프로토타입, 유지해야 할 기능, 전환 계획을 제시해야 합니다. 마이그레이션 저장소를 만들었다고 전면 재작성을 결정한 것은 아닙니다.

## Project에는 파일 위치와 시험 결과 연결하기 {#project는-색인이고-파일은-저장소가-보관합니다}

실제 파일은 크기와 보존 목적에 맞는 곳에 보관하고, 이슈에서 찾을 수 있도록 연결합니다.

| 파일 종류 | 보관 위치 제안 |
| --- | --- |
| 설치·설정 절차, 작은 산출물 목록, 시험 요약 | 버전 관리하는 저장소 파일 |
| 일상적인 CI 로그와 빌드 결과 | 보존 기간을 정한 Actions artifacts |
| 릴리스용 파일 묶음 | 크기와 접근 조건이 맞으면 Release assets |
| 대형 복구 이미지, bag, 영상, 데이터셋 | 팀이 관리하는 장기 보관 공간 |

이슈에는 산출물 목록(manifest)을 연결하세요. 파일의 목적과 위치, 소스 SHA, 하드웨어·BSP·설정, 체크섬, 접근 방법, 보존 기간을 적습니다.

Actions artifacts는 기간이 지나거나 해당 실행 기록을 삭제하면 사라질 수 있습니다. 채택한 릴리스 파일과 복구 자료는 따로 보존해야 합니다. [Actions 파일 보존 안내](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/remove-workflow-artifacts), [대용량 파일과 배포](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)

보관 위치는 팀이 선택하고 다른 팀원도 접근할 수 있는지 확인합니다. 인증 정보는 시험 결과 파일에 넣지 말고 별도의 접근 관리 수단으로 다룹니다.

## 짧게 정기적으로 확인할 내용 {#협의-주기}

현재 운용 코드의 수정 사항, Jazzy 빌드 상태, 공통 인터페이스 변경, 장비 사용 일정, 다음에 확인할 결과를 함께 살펴봅니다. 주간 검토를 출발점으로 삼되 실제 가용 시간에 맞춰 조정하세요.

NX 시험 일정이 겹치면 SW 팀장, HW 담당자, 릴리스 승인 담당자가 조율합니다. 그동안 독립적으로 할 수 있는 작업은 계속 진행합니다.

문서에는 오래 참고할 설명을, 이슈·PR에는 진행 상태를, 시험 기록에는 실행 결과를 남깁니다. 서로 연결해 두면 개인 대화를 다시 찾아보지 않아도 작업과 결정의 이유를 파악할 수 있습니다.
