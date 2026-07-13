*&---------------------------------------------------------------------*
*& Include ZRC1MM0004_TOP                           - Report ZRC1MM0004
*&---------------------------------------------------------------------*
REPORT zrc1mm0004 MESSAGE-ID zmcl301.

**********************************************************************
* TAB Strip
**********************************************************************
CONTROLS : tab_strip TYPE TABSTRIP.
DATA : gv_dynnr  TYPE sy-dynnr.

**********************************************************************
* TABLES
**********************************************************************
TABLES : ztc1mm0025, " PR 헤더 테이블
         ztc1mm0026. " PR 아이템 테이블

**********************************************************************
* Class instance
**********************************************************************
*-- PR 조회 탭
DATA : go_list_cont      TYPE REF TO cl_gui_custom_container,
       go_split_cont     TYPE REF TO cl_gui_splitter_container,
       go_left_cont      TYPE REF TO cl_gui_container,           " PR 리스트 조회
       go_left_alv       TYPE REF TO cl_gui_alv_grid,            " PR 리스트

       go_right_cont     TYPE REF TO cl_gui_container,           " PR 상세조회
       go_right_split    TYPE REF TO cl_gui_splitter_container,  " 3중 분할 (공통정보, 미전환, 전환완료)
       go_right_top_cont TYPE REF TO cl_gui_container,           " 공통정보
       go_right_mid_cont TYPE REF TO cl_gui_container,           " PO 미전환
       go_right_bot_cont TYPE REF TO cl_gui_container,           " PO 전환완료
       go_html_viewer    TYPE REF TO cl_gui_html_viewer,         " 공통정보 HTML
       go_right_mid_alv  TYPE REF TO cl_gui_alv_grid,            " 미전환 ALV
       go_right_bot_alv  TYPE REF TO cl_gui_alv_grid.            " 전환 ALV

*-- PR 수정 팝업창
DATA : go_modi_pop TYPE REF TO cl_gui_custom_container,
       go_modi_alv TYPE REF TO cl_gui_alv_grid.

*-- PR 수동생성 탭
DATA : go_head_cont    TYPE REF TO cl_gui_custom_container,      " PR 헤더 HTML
       go_head_html    TYPE REF TO cl_gui_html_viewer,

       go_create_cont  TYPE REF TO cl_gui_custom_container,      " PR 수동생성 ALV
       go_create_alv   TYPE REF TO cl_gui_alv_grid,

       go_summary_cont TYPE REF TO cl_gui_custom_container,      " PR 수동생성 요약 HTML
       go_summary_html TYPE REF TO cl_gui_html_viewer.

**********************************************************************
* Internal table and Work area
**********************************************************************

*-- PR 조회 리스트 (Header)
DATA : BEGIN OF gs_header,
         icon        TYPE icon_d,                  " 상태 아이콘
         banfn       TYPE ztc1mm0025-banfn,        " 구매요청 번호
         item_cnt    TYPE i,                       " 품목 개수
         badat       TYPE ztc1mm0025-badat,        " PR 요청일자
         lfdat       TYPE ztc1mm0026-lfdat,        " 가장 빠른 납기일
         estkz       TYPE ztc1mm0025-estkz,        " 생성구분
         estkz_t     TYPE dd07v-ddtext,            " 생성구분 텍스트 (수동/MRP)
         statu       TYPE ztc1mm0025-statu,        " 처리상태 (ICON 세팅 <CR/PC/FC>)
         afnam       TYPE ztc1mm0025-afnam,        " 구매요청 생성자
         dday        TYPE i,                       " 납기잔여일수
         dday_txt(6),                              " D-day 텍스트 (D-2, D-6)
         total_amt   TYPE p LENGTH 13 DECIMALS 2,  " 총 예상금액
         waers       TYPE ztc1mm0026-waers,        " 통화키
         del_icon    TYPE icon_d,                  " 삭제 아이콘
         cellcolor   TYPE lvc_t_scol,              " 셀 편집
         sort_group  TYPE i,                       " 1=미확정/일부확정, 2=확정완료
         sort_stat   TYPE i,                       " CR=1, PC=2, FC=3
       END OF gs_header,
       gt_header LIKE TABLE OF gs_header.

*-- PR 상세정보 (Item)
DATA : BEGIN OF gs_item,
         icon          TYPE icon_d,
         banfn         TYPE ztc1mm0026-banfn,          " 구매요청번호
         bnfpo         TYPE ztc1mm0026-bnfpo,          " 품목 번호
         matnr         TYPE ztc1mm0026-matnr,          " 자재 번호
         maktx         TYPE ztc1mm0026-maktx,          " 자재 내역
         menge         TYPE ztc1mm0026-menge,          " 수량
         meins         TYPE ztc1mm0026-meins,          " 단위
         price         TYPE ztc1mm0026-price,          " 자재 단가
         total_mat_amt TYPE p LENGTH 13 DECIMALS 2,    " 자재당 총 금액(수량*자재 단가)
         waers         TYPE ztc1mm0026-waers,          " 통화키
         werks         TYPE ztc1mm0026-werks,          " 플랜트
         lgort         TYPE ztc1mm0026-lgort,          " 저장위치
         lgort_txt     TYPE dd07v-ddtext,              " 저장위치명
         lfdat         TYPE ztc1mm0026-lfdat,          " 납품 예정일
         statu         TYPE ztc1mm0026-statu,          " 품목 상태 ( 전환완료 / 미전환 / 삭제 : 분리 )
         ebeln         TYPE ztc1mm0026-ebeln,          " PO전환 시 업데이트되는 PO번호 (추적성 위해)
         loekz         TYPE ztc1mm0026-loekz,          " 삭제 플래그
       END OF gs_item,
       gt_item    LIKE TABLE OF gs_item,
       gt_item_no LIKE TABLE OF gs_item,    " PO 미전환
       gt_item_ok LIKE TABLE OF gs_item.    " PO 전환완료

*-- PR 생성 ALV
DATA : BEGIN OF gs_create,
         bnfpo         TYPE ztc1mm0026-bnfpo,                  " 품목 번호
         matnr         TYPE ztc1mm0026-matnr,                  " 자재 번호
         maktx         TYPE ztc1mm0026-maktx,                  " 자재 내역
         menge         TYPE ztc1mm0026-menge,                  " 수량
         meins         TYPE ztc1mm0026-meins,                  " 단위
         werks         TYPE ztc1mm0026-werks,                  " 플랜트
         lgort         TYPE ztc1mm0026-lgort,                  " 저장위치
         lgort_txt     TYPE dd07v-ddtext,                      " 저장위치명
         lfdat         TYPE ztc1mm0026-lfdat,                  " 납품 예정일
         price         TYPE ztc1mm0026-price,                  " 자재 단가
         waers         TYPE ztc1mm0026-waers,                  " 통화키
         total_mat_amt TYPE p LENGTH 13 DECIMALS 2,            " 자재당 총 금액(수량*자재 단가)
         purrsn        TYPE ztc1mm0026-purrsn,                 " 구매사유
         celltab       TYPE lvc_t_styl,                        " 셀 편집
       END OF gs_create,
       gt_create LIKE TABLE OF gs_create.

*-- ALV 설정
DATA : gt_fcat_header   TYPE lvc_t_fcat,           " PR 리스트
       gt_fcat_item     TYPE lvc_t_fcat,           " PR 상세(전환/미전환)
       gt_fcat_create   TYPE lvc_t_fcat,           " PR 수동생성
       gs_fcat          TYPE lvc_s_fcat,
       gs_layout_list   TYPE lvc_s_layo,
       gs_layout_mid    TYPE lvc_s_layo,
       gs_layout_bot    TYPE lvc_s_layo,
       gs_layout_create TYPE lvc_s_layo,
       gs_variant       TYPE disvariant.

*-- MAKTX 세팅용
DATA : gt_maktx TYPE TABLE OF ztc1mm0001,
       gs_maktx TYPE ztc1mm0001.

*-- PRICE 세팅용
DATA : BEGIN OF gs_price,
         matnr      TYPE ztc1mm0026-matnr,
         price      TYPE ztc1mm0026-price,
         waers      TYPE ztc1mm0026-waers,
         valid_from TYPE ztc1mm0022-valid_from,
       END OF gs_price,
       gt_price LIKE TABLE OF gs_price.

*-- MATNR Search help용
DATA : BEGIN OF gs_sh_matnr,
         matnr TYPE ztc1mm0001-matnr,
         maktx TYPE ztc1mm0001-maktx,
       END OF gs_sh_matnr,
       gt_sh_matnr LIKE TABLE OF gs_sh_matnr.

*-- BANFN Search help용
DATA : BEGIN OF gs_sh_banfn,
         banfn   TYPE ztc1mm0025-banfn,
         badat   TYPE ztc1mm0025-badat,
         afnam   TYPE ztc1mm0025-afnam,    " 사번ID 아닌 이름이 들어감
         statu   TYPE ztc1mm0025-statu,
         statu_t TYPE char10,              " 상태 텍스트 (미확정/일부확정/확정완료)
       END OF gs_sh_banfn,
       gt_sh_banfn LIKE TABLE OF gs_sh_banfn.

**********************************************************************
* Common variable
**********************************************************************
DATA : gv_okcode        TYPE sy-ucomm,
       gv_save_ok       TYPE sy-ucomm,
       gs_button        TYPE stb_button,       " ALV Toolbar 버튼
       gv_preview_banfn TYPE ztc1mm0025-banfn. " 수동생성 창에서 구매요청번호 미리보기용

*-- 저장위치명 세팅용
DATA : gt_lgort TYPE TABLE OF dd07v,
       gs_lgort TYPE dd07v.

*-- PR 상태 카운터 (Header 기준)
DATA : gv_cnt_all TYPE i,  " 전체 PR
       gv_cnt_cr  TYPE i,  " 확정대기 (하나도 전환 X)
       gv_cnt_pc  TYPE i,  " 일부확정 (상세 품목에서 일부)
       gv_cnt_fc  TYPE i.  " 확정완료 (상세 품목까지)

**********************************************************************
* Screen Painter variable
**********************************************************************
DATA : gv_badat_to TYPE ztc1mm0025-badat.  " PR 조회 날짜 범위

*--------------------------------------------------------------------*
* 상단 ERP 헤더
DATA: go_html_dock   TYPE REF TO cl_gui_docking_container,
      go_html_header TYPE REF TO zcl_c1_co_html.

*--------------------------------------------------------------------*
