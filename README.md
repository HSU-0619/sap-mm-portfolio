# SAP MM · ABAP/Fiori Portfolio

> SAP S/4HANA 기반 자전거 제조기업 통합 ERP 교육 프로젝트에서  
> **MM 조달 프로세스의 설계부터 ABAP·RAP·Fiori 구현까지 수행한 포트폴리오**입니다.

## Portfolio Links

| 구분 | 링크 |
|---|---|
| 포트폴리오 웹사이트 | [GitHub Pages에서 보기](https://HSU-0619.github.io/sap-mm-portfolio/) |
| 프로그램 스펙서 | [PDF로 바로 보기](./docs/program-spec.pdf) |
| ABAP·RAP·Fiori 소스 | [소스 디렉터리 보기](./src/) |
| 스펙서 원본 | [PPTX 다운로드](./docs/program-spec-source.pptx) |

---

## Project Overview

가상의 자전거 제조기업 **태산자전거**를 대상으로 수행한 SAP S/4HANA 기반 통합 ERP 구축 프로젝트입니다.

표준 업무 흐름을 바탕으로 자재마스터, 구매요청, 구매오더, 구매정보레코드, 송장검증으로 이어지는 MM 조달 프로세스를 CBO 기반으로 설계하고, 생산·재고·재무 데이터가 연결되도록 타 모듈 인터페이스를 구현했습니다.

### 담당 영역

- MM 프로세스 및 CBO 데이터 구조 설계
- ABAP Report·Module Pool·ALV 프로그램 개발
- CDS View·RAP·OData 서비스 구현
- SAPUI5 기반 Fiori 앱 개발
- PP·FI·SD 모듈 데이터 및 전표 연계
- 프로그램 스펙서와 테스트 산출물 작성

---

## Key Programs

### Classic ABAP

| T-Code | 프로그램 | 주요 구현 내용 |
|---|---|---|
| `ZC1MM0001` | 자재마스터 관리 | 조회·수정·신규 등록, 재고·이미지·메모 통합 조회, 미사용 전환 시 진행 중 PR·PO 검증 |
| `ZRC1MM0004` | 구매요청 관리 | PR 조회·생성·확정·수정, D-Day 기반 납기 시각화, 확정 시점 단가 고정 |
| `ZRC1MM0005` | 구매오더 관리·결재 | 확정 PR의 벤더별 PO 생성, 최소주문수량 보정, 금액 기준 결재유형 분기 |
| `ZC1MM0006` | 구매정보레코드 관리 | 계약단가 이력 관리, 발주이력 비교, 신규 PIR 생성 시 연간계약 PO 연계 |
| `ZRC1MM0010` | 송장검증 | 3-Way Match, 송장 단위 Roll-up 검증, FI AP 전표 생성 및 LUW 제어 |

### Fiori / RAP

| App | 기능 | 주요 구현 내용 |
|---|---|---|
| PO Approval | 구매오더 결재 승인 | 상태별 KPI, 다중 승인, 직급 권한 제어, 결재이력 및 PDF 출력 |
| QR Inventory | QR 자재 추적 | QR 발행·재발행·스캔, 배치 이동이력, 모바일 재고 조회 |
| SD Change History | 판매오더 변경이력 분석 | 변경 전후 비교, ATP 기반 납기 영향 분석, 고객·위험도 분석 |

---

## Technical Highlights

### 데이터 정합성 중심의 저장 설계

- 화면에 노출되지 않은 필드가 초기값으로 덮어써지지 않도록 DB 원본 우선 적재 방식 적용
- 변경된 행만 선별하여 저장
- 구매 문서 간 번호와 상태값을 연결해 PR → PO → GR → IV 역추적 구현

### 모듈 간 트랜잭션 제어

송장 대량 전기 과정에서 MM 이력과 FI 전표가 분리 반영되는 문제를 분석하고, 호출부에서 `COMMIT WORK`와 `ROLLBACK WORK`를 통제하도록 개선했습니다.

이를 통해 오류 발생 시 관련 데이터가 함께 취소되고, 정상 처리 시에만 최종 반영되도록 데이터 정합성을 확보했습니다.

### 현업 사용성을 고려한 UI

- 납기 임박 건 우선 정렬 및 상태별 색상 표시
- ALV Grid·Tree·HTML Viewer를 결합한 복합 화면 구성
- 직급과 문서 상태에 따른 버튼 및 편집 권한 제어
- 모바일 환경을 고려한 Fiori 화면 구현

---

## Tech Stack

| 영역 | 기술 |
|---|---|
| Backend | ABAP, Open SQL, Module Pool, ALV Grid/Tree, Function Module |
| Cloud ABAP | Eclipse ADT, CDS View, RAP, Behavior Definition |
| Integration | OData V2/V4, Module Interface, LUW Control |
| Frontend | SAPUI5 Freestyle, Fiori Elements |
| Data Modeling | CBO Table, Domain, Data Element, Search Help |
| Tools | SAP GUI, Eclipse ADT, VS Code, abapGit, GitHub Pages |

---

## Repository Structure

```text
sap-mm-portfolio/
├── index.html
│   └── GitHub Pages 포트폴리오 웹페이지
│
├── src/
│   └── abapGit으로 추출한 ABAP·CDS·RAP·Fiori 관련 객체
│
├── docs/
│   ├── program-spec.pdf
│   ├── program-spec-source.pptx
│   └── previews/
│       └── 포트폴리오 프로그램 미리보기 이미지
│
├── .abapgit.xml
│   └── abapGit 저장소 설정
│
└── README.md
