*&---------------------------------------------------------------------*
*& Include          SAPMZC1MM0096_TOP
*&---------------------------------------------------------------------*
PROGRAM sapmzc1mm0096 MESSAGE-ID zmc1301.

**********************************************************************
* Class instance
**********************************************************************
*-- 메인 컨테이너
DATA : go_main_cont    TYPE REF TO cl_gui_custom_container.

*-- 스플리터 (좌:PIR목록 / 우:상세영역) + 우측 상/하 스플리터
DATA : go_splitter     TYPE REF TO cl_gui_splitter_container,
       go_detail_split TYPE REF TO cl_gui_splitter_container.

*-- 스플리터 분할 영역 컨테이너
DATA : go_list_cont   TYPE REF TO cl_gui_container,   " 좌  : PIR 목록
       go_detail_cont TYPE REF TO cl_gui_container,   " 우  : 상세 영역
       go_price_cont  TYPE REF TO cl_gui_container,   " 우상: 단가/조건
       go_po_cont     TYPE REF TO cl_gui_container.   " 우하: NB PO 이력

*-- ALV 그리드
DATA : go_list_alv  TYPE REF TO cl_gui_alv_grid,
       go_price_alv TYPE REF TO cl_gui_alv_grid,
       go_po_alv    TYPE REF TO cl_gui_alv_grid.

**********************************************************************
* Internal table / Work area
**********************************************************************
*-- PIR 목록
DATA : BEGIN OF gs_list.
         INCLUDE STRUCTURE ztc1mm0021.
DATA :   ebeln       TYPE ztc1mm0007-ebeln,
         bsart       TYPE ztc1mm0007-bsart,
         maktx       TYPE ztc1mm0001-maktx,
         name1       TYPE ztc1mm0012-name1,
         kdatb       TYPE ztc1mm0012-kdatb,
         kdate       TYPE ztc1mm0012-kdate,
         vkdatb      TYPE ztc1mm0012-kdatb,    "*-- 벤더 계약시작일 (판정용)
         vkdate      TYPE ztc1mm0012-kdate,    "*-- 벤더 계약종료일 (판정용)
         netpr       TYPE ztc1mm0022-netpr,
         waers       TYPE ztc1mm0022-waers,
         has_price   TYPE c LENGTH 1,
         status_icon TYPE icon_d,
         linecolor   TYPE char4,
       END OF gs_list,
       gt_list LIKE TABLE OF gs_list.

*-- 헤더 밴드 : 조회조건 전용
DATA : BEGIN OF gs_head,
         infnr TYPE ztc1mm0021-infnr,
         matnr TYPE ztc1mm0021-matnr,
         maktx TYPE ztc1mm0001-maktx,
         lifnr TYPE ztc1mm0021-lifnr,
         name1 TYPE ztc1mm0012-name1,
       END OF gs_head.

*-- 단가 입력/이력 (우상단) : VALID_FROM/VALID_TO 기간 방식
*-- 키: INFNR + VALID_FROM (복합키 → DB 레벨 중복 방지)
DATA : BEGIN OF gs_price.
         INCLUDE STRUCTURE ztc1mm0022.
DATA :   celltab TYPE lvc_t_styl,
         flag    TYPE c,           " 'N' = 신규 입력행
       END OF gs_price,
       gt_price LIKE TABLE OF gs_price.

*-- 신규 PIR 생성 팝업 (화면 0200)
*-- plan_year : 등록연도 입력 → valid_from/valid_to 자동계산 (화면 숨김)
*-- plan_menge: 연간계획수량 → ZTC1MM0008-MENGE 에 저장
DATA : BEGIN OF gs_pop,
         matnr      TYPE ztc1mm0021-matnr,
         maktx      TYPE ztc1mm0001-maktx,
         lifnr      TYPE ztc1mm0021-lifnr,
         name1      TYPE ztc1mm0012-name1,
         kdatb      TYPE ztc1mm0012-kdatb,        " 벤더 계약시작일 (readonly)
         kdate      TYPE ztc1mm0012-kdate,        " 벤더 계약종료일 (readonly)
         ekorg      TYPE ztc1mm0022-ekorg,
         werks      TYPE ztc1mm0022-werks,
         plan_year  TYPE n LENGTH 4,              " 등록연도 (입력) → valid_from/to 자동계산
         valid_from TYPE ztc1mm0022-valid_from,   " 자동계산 (화면 숨김)
         valid_to   TYPE ztc1mm0022-valid_to,     " 자동계산 (화면 숨김)
         netpr      TYPE ztc1mm0022-netpr,
         peinh      TYPE ztc1mm0022-peinh,
         waers      TYPE ztc1mm0022-waers,
         minbm      TYPE ztc1mm0022-minbm,
         norbm      TYPE ztc1mm0022-norbm,
         plan_menge TYPE ztc1mm0008-menge,        " 연간계획수량 -> ZTC1MM0008-MENGE
         meins      TYPE ztc1mm0022-meins,
         aplfz      TYPE ztc1mm0022-aplfz,
         webre      TYPE ztc1mm0022-webre,
       END OF gs_pop.

*-- PO 이력 (우하단) : NB 일반발주만 표시 (ZAPC 연간계약 제외)
DATA : BEGIN OF gs_po,
         ebeln      TYPE ztc1mm0008-ebeln,
         ebelp      TYPE ztc1mm0008-ebelp,
         bsart      TYPE ztc1mm0007-bsart,
         infnr      TYPE ztc1mm0008-infnr,
         lifnr      TYPE ztc1mm0007-lifnr,
         matnr      TYPE ztc1mm0008-matnr,
         maktx      TYPE ztc1mm0001-maktx,
         menge      TYPE ztc1mm0008-menge,
         meins      TYPE ztc1mm0008-meins,
         netpr      TYPE ztc1mm0008-netpr,
         peinh      TYPE ztc1mm0008-peinh,
         waers      TYPE ztc1mm0007-waers,
         werks      TYPE ztc1mm0008-werks,
         lgort      TYPE ztc1mm0008-lgort,
         bedat      TYPE ztc1mm0007-bedat,
         statu      TYPE ztc1mm0008-statu,
         statu_text TYPE char20,
       END OF gs_po,
       gt_po LIKE TABLE OF gs_po.

*-- ALV 공통
DATA : gt_fcat_list  TYPE lvc_t_fcat,
       gt_fcat_price TYPE lvc_t_fcat,
       gt_fcat_po    TYPE lvc_t_fcat,
       gs_fcat       TYPE lvc_s_fcat,
       gs_layo_list  TYPE lvc_s_layo,
       gs_layo_price TYPE lvc_s_layo,
       gs_layo_po    TYPE lvc_s_layo,
       gs_variant    TYPE disvariant.

*-- Search Help 용
DATA : BEGIN OF gs_sh_matnr,
         matnr TYPE ztc1mm0001-matnr,
         maktx TYPE ztc1mm0001-maktx,
       END OF gs_sh_matnr,
       gt_sh_matnr LIKE TABLE OF gs_sh_matnr.

DATA : BEGIN OF gs_sh_lifnr,
         lifnr TYPE ztc1mm0012-lifnr,
         name1 TYPE ztc1mm0012-name1,
         kdatb TYPE ztc1mm0012-kdatb,
         kdate TYPE ztc1mm0012-kdate,
       END OF gs_sh_lifnr,
       gt_sh_lifnr LIKE TABLE OF gs_sh_lifnr.

*-- Toolbar 제거
DATA : gt_toolbar TYPE ui_functions.

**********************************************************************
* Common variable
**********************************************************************
DATA : gv_okcode      TYPE sy-ucomm,
       gs_button      TYPE stb_button,
       gv_sel_infnr   TYPE ztc1mm0021-infnr,
       gv_detail_open TYPE abap_bool.
*--------------------------------------------------------------------*
* 상단 ERP 헤더
DATA: go_html_dock   TYPE REF TO cl_gui_docking_container,
      go_html_header TYPE REF TO zcl_c1_co_html.

*--------------------------------------------------------------------*
