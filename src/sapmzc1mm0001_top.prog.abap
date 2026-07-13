*&---------------------------------------------------------------------*
*& Include          SAPMZC1MM0001_TOP
*&---------------------------------------------------------------------*
PROGRAM sapmzc1mm0001 MESSAGE-ID zmcl301.

**********************************************************************
* TABLES
**********************************************************************
TABLES : ztc1mm0001.

**********************************************************************
* Class instance
**********************************************************************
DATA : go_container   TYPE REF TO cl_gui_custom_container,
       go_split_cont  TYPE REF TO cl_gui_splitter_container, " 좌/우 분리
       go_list_cont   TYPE REF TO cl_gui_container,          " 자재 조회(좌측 전체)
       go_right_cont  TYPE REF TO cl_gui_container,          " 우측 전체
       go_split2_cont TYPE REF TO cl_gui_splitter_container, " 상/하 분리
       go_pic_cont    TYPE REF TO cl_gui_container,          " 자재 이미지
       go_stock_cont  TYPE REF TO cl_gui_container,          " 자재 Stock ALV
       go_list_alv    TYPE REF TO cl_gui_alv_grid,
       go_picture     TYPE REF TO cl_gui_picture,
       go_stock_alv   TYPE REF TO cl_gui_alv_grid.

*-- 메모 툴바
DATA : go_memo_split     TYPE REF TO cl_gui_splitter_container,
       go_memo_btn_cont  TYPE REF TO cl_gui_container,
       go_memo_edit_cont TYPE REF TO cl_gui_container,
       go_memo_toolbar   TYPE REF TO cl_gui_toolbar.

*-- 비고 메모
DATA : go_memo_cont   TYPE REF TO cl_gui_container,        "* 메모 컨테이너
       go_memo_editor TYPE REF TO cl_gui_textedit.         "* 메모 에디터

**********************************************************************
* Internal table / Work area
**********************************************************************
*-- ALV 출력
DATA : BEGIN OF gs_matdata,
         matnr      TYPE ztc1mm0001-matnr,
         maktx      TYPE maktx,
         mtart      TYPE ztc1mm0001-mtart,
         mtart_text TYPE dd07t-ddtext,         " 자재유형 한글
         matkl      TYPE ztc1mm0001-matkl,
         matkl_text TYPE dd07t-ddtext,         " 자재그룹 한글
         ntgew      TYPE ntgew,
         gewei      TYPE gewei,
         normt      TYPE normt,
         meins      TYPE meins,
         bismt      TYPE ztc1mm0001-bismt,
         vrsgr      TYPE ztc1mm0001-vrsgr,
         vrsnr      TYPE ztc1mm0001-vrsnr,
         lvorm      TYPE ztc1mm0001-lvorm,
         bigo       TYPE ztc1mm0001-bigo,
         linecolor  TYPE char4,                " 행 색상
         celltab    TYPE lvc_t_styl,           " 셀 편집 제어용
       END OF gs_matdata,
       gt_matdata LIKE TABLE OF gs_matdata.

*-- 플랜트 -> Storage location별 재고 현황
DATA : BEGIN OF gs_stock,
         matnr     TYPE ztc1mm0020-matnr,
         werks     TYPE ztc1mm0020-werks,
         lgort     TYPE ztc1mm0020-lgort,
         lgort_txt TYPE dd07t-ddtext,      " 저장위치명
         charg     TYPE ztc1mm0020-charg,
         clabs     TYPE labst,             " 가용재고
         cinsm     TYPE insme,             " 품질검사재고
         cspem     TYPE speme,             " 보류재고
         meins     TYPE meins,
       END OF gs_stock,
       gt_stock LIKE TABLE OF gs_stock.

*-- 삭제 버퍼
DATA : gt_delete LIKE TABLE OF gs_matdata.


*-- ALV 설정
DATA : gt_fcat_list  TYPE lvc_t_fcat,
       gt_fcat_stock TYPE lvc_t_fcat,
       gs_fcat       TYPE lvc_s_fcat,
       gs_layout     TYPE lvc_s_layo,
       gs_variant    TYPE disvariant.

*-- ALV Toolbar
DATA : gt_toolbar TYPE ui_functions,
       gs_button  TYPE stb_button.

**********************************************************************
* Common variable
**********************************************************************
DATA : gv_okcode TYPE sy-ucomm,
       gv_mode   VALUE 'D'.               " D=조회, E=수정

*-- 조회조건 : 라디오버튼
DATA : rb_all  TYPE c,  " 전체
       rb_use  TYPE c,  " 사용자재
       rb_nuse TYPE c.  " 미사용자재

DATA : gv_stock_init     TYPE abap_bool, " 재고ALV 최초 생성여부
       gv_selected_matnr TYPE matnr.     " 현재 선택된 자재번호

*--------------------------------------------------------------------*
* 상단 ERP 헤더
DATA: go_html_dock   TYPE REF TO cl_gui_docking_container,
      go_html_header TYPE REF TO zcl_c1_co_html.

*--------------------------------------------------------------------*
