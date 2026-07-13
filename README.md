# SAP MM 포트폴리오 — 홍승욱

S/4HANA 환경에서 MM(자재관리) 모듈의 조달 프로세스 전 구간을 Full-Custom CBO로 설계·개발한 프로젝트입니다.

**포트폴리오 페이지** → https://HSU-0619.github.io/sap-mm-portfolio/

## 담당 프로그램

| 구분 | T-Code / App | 프로그램명 | 핵심 |
|---|---|---|---|
| ABAP | ZC1MM0001 | 자재마스터 관리 | LVORM 비활성화 시 진행 PR/PO 검증 |
| ABAP | ZRC1MM0004 | 구매요청(PR) 관리 | D-Day 납기 시각화, 확정 시점 단가 고정 |
| ABAP | ZRC1MM0005 | 구매오더(PO) 관리·결재 | 벤더별 PO 분리 생성, 금액 기준 결재 분기 |
| ABAP | ZC1MM0006 | 구매정보레코드(PIR) | 계약 단가 이력, 연간계약 PO 자동 생성 |
| ABAP | ZRC1MM0010 | 송장검증(IV) | 3-Way Match, FI AP 전표 생성, LUW 제어 |
| Fiori | po-approval | 구매오더 결재 승인 | RAP 액션, 직급 권한 제어, 결재 PDF |
| Fiori | qr-inventory | QR 자재 추적 | QR 발행/스캔, 3D 창고 대시보드 |
| Fiori | sd-change-history | [SD] 판매오더 변경이력 | RAP + OData V4, ATP 납기영향 분석 |

## 기술 스택

- **ABAP**: Module Pool, ALV Grid/Tree, Search Help, Function Module, SNRO
- **최신 ABAP**: Eclipse ADT, CDS View, RAP, OData V2/V4
- **Frontend**: SAPUI5 (Freestyle)
- **자격**: SAP Certified Associate — Backend Developer ABAP Cloud (C_ABAPD_2601), Fiori Application Developer (C_FIORD), SQLD

## 폴더 구조

```
├── index.html        # 포트폴리오 웹페이지 (GitHub Pages)
├── abap/             # ABAP 소스 (프로그램별 폴더, 인클루드 단위 .abap)
├── fiori/            # UI5 프로젝트 (node_modules 제외)
└── docs/             # 프로그램 스펙서 PDF
```

> 본 저장소의 코드는 교육 프로젝트(태산자전거 가상 기업) 산출물이며, 실기업 데이터를 포함하지 않습니다.
