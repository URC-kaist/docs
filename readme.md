# URC KAIST Documentation / Website

Hugo 도구를 이용하여 문서를 관리하고 웹사이트를 구축합니다.

## 1. 레포지토리 복제
```bash
git clone --recursive https://github.com/URC-kaist/urc-kaist.github.io.git
```

## 2. Hugo 설치
공식 설치 안내를 참조하시기 바랍니다: https://gohugo.io/installation/  
- **macOS:**  
  ```bash
  brew install hugo
  ```  
- **Ubuntu (WSL 포함):**  
  ```bash
  sudo apt update
  sudo apt install hugo
  ```  
- **Windows:**  
  Windows 환경에서는 Chocolatey 혹은 Scoop 등의 패키지 관리자를 이용하시기 바랍니다.

## 3. 문서 작성 및 배치
1. `./content/` 디렉터리 아래에 원하는 위치에 `.md` 파일을 생성하십시오.  
2. 디렉터리 구조가 곧 사이트의 URL 경로가 되므로, 필요한 만큼 하위 폴더를 구성할 수 있습니다.  
3. 각 폴더의 요약 페이지를 작성하려면 해당 폴더에 `_index.md` 파일을 생성하십시오.

### 문서 파일의 Front Matter
모든 Markdown 파일 상단에 아래와 같은 메타데이터를 추가해야 합니다:
```yaml
---
title: "문서 제목 (한글 또는 영어)"
weight: 1           # 메뉴 내 정렬 순서 (작을수록 상단에 표시)
draft: false        # true로 설정 시 사이트 빌드 시 제외
bookCollapseSection: true  # _index.md에서 해당 섹션 접기 여부
---
```

궁금하신 점이 있으시면 언제든지 문의해 주십시오.  
