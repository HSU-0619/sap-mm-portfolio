*&---------------------------------------------------------------------*
*& Include ZRC1MM0005_TOP                           - Report ZRC1MM0005
*&---------------------------------------------------------------------*
REPORT zrc1mm0005 MESSAGE-ID zmcl301.

**********************************************************************
* ALV Tree 관련 CLASS
**********************************************************************
CLASS: cl_gui_column_tree DEFINITION LOAD,
       cl_gui_cfw         DEFINITION LOAD.

**********************************************************************
* TAB Strip
**********************************************************************
CONTROLS : tab_strip TYPE TABSTRIP.
DATA : gv_dynnr TYPE sy-dynnr.

**********************************************************************
* TABLES
**********************************************************************
TABLES : ztc1mm0012, " 공급업체 테이블
         ztc1mm0021, " 구매정보레코드 헤더 테이블
         ztc1mm0025, " PR 헤더 테이블
         ztc1mm0026, " PR 아이템 테이블
         ztc1mm0007, " PO 헤더 테이블
         ztc1mm0008, " PO 아이템 테이블
         ztc1hr0001, " HR 인사 마스터 테이블
         ztc1mm0027. " PO 결재이력

**********************************************************************
* Class instance
**********************************************************************
*-- PO 생성 탭
DATA : go_left_cont   TYPE REF TO cl_gui_custom_container,
       go_right_cont  TYPE REF TO cl_gui_custom_container,
       go_bottom_cont TYPE REF TO cl_gui_custom_container,
       go_left_alv    TYPE REF TO cl_gui_alv_grid,
       go_right_alv   TYPE REF TO cl_gui_alv_grid,
       go_bottom_tree TYPE REF TO cl_gui_alv_tree.

*-- 자재별 벤더 조회 팝업창
DATA : go_vender_pop TYPE REF TO cl_gui_custom_container,
       go_vender_alv TYPE REF TO cl_gui_alv_grid.

*-- HTML 구분선/화살표
DATA : go_div_cont   TYPE REF TO cl_gui_custom_container,
       go_div_html   TYPE REF TO cl_gui_html_viewer,
       go_arrow_cont TYPE REF TO cl_gui_custom_container,
       go_arrow_html TYPE REF TO cl_gui_html_viewer.

*-- PO 결재 탭 (Approval) 리스트/상세
DATA : go_po_main_cont TYPE REF TO cl_gui_custom_container,
       go_po_splitter  TYPE REF TO cl_gui_splitter_container, " 헤더/아이템 분리
       go_list_cont    TYPE REF TO cl_gui_container,          " 구매오더 리스트(결재대기,결재중,승인,반려)
       go_detail_cont  TYPE REF TO cl_gui_container,          " 상세정보
       go_po_alv       TYPE REF TO cl_gui_alv_grid.

*-- 상세 영역 splitter (헤더 HTML / 아이템 ALV)
DATA : go_detail_split  TYPE REF TO cl_gui_splitter_container,
       go_detail_h_cont TYPE REF TO cl_gui_container,
       go_detail_i_cont TYPE REF TO cl_gui_container,
       go_detail_h_html TYPE REF TO cl_gui_html_viewer,
       go_detail_i_alv  TYPE REF TO cl_gui_alv_grid.

*-- PO 결재 카운트 및 ALV버튼 HTML CARD
DATA : go_card_cont TYPE REF TO cl_gui_custom_container,
       go_card_html TYPE REF TO cl_gui_html_viewer.

*-- PO 수정 팝업창
DATA : go_modi_cont TYPE REF TO cl_gui_custom_container,
       go_modi_alv  TYPE REF TO cl_gui_alv_grid.

*-- 반려 사유 텍스트 박스
DATA : go_bigo_cont TYPE REF TO cl_gui_custom_container,
       go_bigo_text TYPE REF TO cl_gui_textedit.

*-- 반려 사유 HTML 팝업 (Screen 0300)
DATA : go_bigo_pop_cont TYPE REF TO cl_gui_custom_container,
       go_bigo_pop_html TYPE REF TO cl_gui_html_viewer.

*-- 반려 사유 관련? -> 재상신 -> 결재 중으로 바로 이동(Fiori)

**********************************************************************
* Internal table and Work area
**********************************************************************
*-- Left : 확정 PR 헤더 목록
DATA : BEGIN OF gs_left,
         icon     TYPE icon_d,
         banfn    TYPE ztc1mm0025-banfn,
         item_cnt TYPE i,
         sel_cnt  TYPE i,
         badat    TYPE ztc1mm0025-badat,
         statu    TYPE ztc1mm0025-statu,
         ernam    TYPE ztc1mm0025-ernam,
       END OF gs_left,
       gt_left LIKE TABLE OF gs_left.

*-- Right : 선택한 PR의 품목 상세
DATA : BEGIN OF gs_right,
         banfn     TYPE ztc1mm0026-banfn,
         check     TYPE c,
         bnfpo     TYPE ztc1mm0026-bnfpo,
         matnr     TYPE ztc1mm0026-matnr,
         maktx     TYPE ztc1mm0026-maktx,
         menge     TYPE ztc1mm0026-menge,
         meins     TYPE ztc1mm0026-meins,
         price     TYPE ztc1mm0026-price,
         waers     TYPE ztc1mm0026-waers,
         lfdat     TYPE ztc1mm0026-lfdat,
         lifnr     TYPE ztc1mm0021-lifnr,
         name1     TYPE ztc1mm0012-name1,
         minbm     TYPE ztc1mm0022-minbm,    " 최소주문수량
         norbm     TYPE ztc1mm0022-norbm,    " 발주 묶음 단위
         bsart     TYPE ztc1mm0025-bsart,
         purrsn    TYPE ztc1mm0026-purrsn,
         sent      TYPE c LENGTH 1,          " Tree로 이동 완료 플래그
         linecolor TYPE char4,
         celltab   TYPE lvc_t_styl,
       END OF gs_right,
       gt_right LIKE TABLE OF gs_right.

*-- Bottom : PO 생성 대상 (Tree 소스)
DATA : BEGIN OF gs_bottom,
         lifnr     TYPE ztc1mm0021-lifnr,
         name1     TYPE ztc1mm0012-name1,
         banfn     TYPE ztc1mm0026-banfn,
         bnfpo     TYPE ztc1mm0026-bnfpo,
         matnr     TYPE ztc1mm0026-matnr,
         maktx     TYPE ztc1mm0026-maktx,
         menge     TYPE ztc1mm0026-menge,
         req_menge TYPE ztc1mm0026-menge,    " 기존 PR 요청수량 (보정 전)
         meins     TYPE ztc1mm0026-meins,
         price     TYPE ztc1mm0026-price,
         waers     TYPE ztc1mm0026-waers,
         lfdat     TYPE ztc1mm0026-lfdat,
         bsart     TYPE ztc1mm0025-bsart,
         purrsn    TYPE ztc1mm0026-purrsn,
         total_amt TYPE p LENGTH 13 DECIMALS 2,
         del_icon  TYPE icon_d,
       END OF gs_bottom,
       gt_bottom LIKE TABLE OF gs_bottom.

*-- PO 리스트 (헤더) -> 결재 대기, 결재중, 승인, 반려
DATA : BEGIN OF gs_appr,
         ebeln         TYPE ztc1mm0007-ebeln,
         lifnr         TYPE ztc1mm0007-lifnr,
         name1         TYPE ztc1mm0012-name1,                " 벤더명
         item_cnt      TYPE i,                               " 품목수
         total_amt     TYPE p LENGTH 13 DECIMALS 2,          " 총금액
         waers         TYPE ztc1mm0007-waers,
         bedat         TYPE ztc1mm0007-bedat,
         statu         TYPE ztc1mm0007-statu,
         appr_type_txt TYPE char12,                      " 결재유형
         bigo          TYPE ztc1mm0007-bigo,                 " 구매사유 요약 / PO 비고
         rej_reason    TYPE ztc1mm0027-appr_comment,         " 결재이력의 최신 반려사유
         rej_icon     TYPE icon_d,                          " 반려 사유 아이콘 표시용
         linecolor     TYPE char4,
       END OF gs_appr,
       gt_appr LIKE TABLE OF gs_appr.

DATA : gt_wait    LIKE TABLE OF gs_appr,
       gt_ing     LIKE TABLE OF gs_appr,
       gt_done    LIKE TABLE OF gs_appr,
       gt_rej     LIKE TABLE OF gs_appr,
       gt_po_list LIKE TABLE OF gs_appr.

*-- 반려 사유 팝업에 표시할 선택 PO 행
DATA : gs_bigo_sel LIKE gs_appr.

*-- 상세정보 아이템
DATA : BEGIN OF gs_detail_item,
         ebelp TYPE ztc1mm0008-ebelp,
         matnr TYPE ztc1mm0008-matnr,
         maktx TYPE ztc1mm0026-maktx,
         menge TYPE ztc1mm0008-menge,
         meins TYPE ztc1mm0008-meins,
         netpr TYPE ztc1mm0008-netpr,
         total TYPE p LENGTH 13 DECIMALS 2,
         waers TYPE ztc1mm0007-waers,
         lfdat TYPE ztc1mm0026-lfdat,
       END OF gs_detail_item,
       gt_detail_item LIKE TABLE OF gs_detail_item.

*-- PO 수정 팝업용 품목 복사본 -> 결제 대기, 반려
DATA : BEGIN OF gs_modi_item,
         ebelp   TYPE ztc1mm0008-ebelp,
         matnr   TYPE ztc1mm0008-matnr,
         maktx   TYPE ztc1mm0026-maktx,
         menge   TYPE ztc1mm0008-menge,
         meins   TYPE ztc1mm0008-meins,
         netpr   TYPE ztc1mm0008-netpr,
         total   TYPE p LENGTH 13 DECIMALS 2,
         waers   TYPE ztc1mm0007-waers,
         lfdat   TYPE ztc1mm0008-lfdat,
         celltab TYPE lvc_t_styl,
       END OF gs_modi_item,
       gt_modi_item LIKE TABLE OF gs_modi_item.

*-- ALV 설정
DATA : gt_fcat_left     TYPE lvc_t_fcat,
       gt_fcat_right    TYPE lvc_t_fcat,
       gt_fcat_bottom   TYPE lvc_t_fcat,
       gt_fcat_po       TYPE lvc_t_fcat,
       gt_fcat_detail   TYPE lvc_t_fcat,
       gs_fcat          TYPE lvc_s_fcat,
       gs_layout_left   TYPE lvc_s_layo,
       gs_layout_right  TYPE lvc_s_layo,
       gs_layout_po     TYPE lvc_s_layo,
       gs_layout_detail TYPE lvc_s_layo,
       gs_variant       TYPE disvariant.

*-- PO 수정 팝업 ALV 설정
DATA : gt_fcat_modi   TYPE lvc_t_fcat,
       gs_layout_modi TYPE lvc_s_layo.

*-- Tree 관련
DATA : g_tree_toolbar TYPE REF TO cl_gui_toolbar,
       gs_tree_header TYPE treev_hhdr.

**********************************************************************
* Common variable
**********************************************************************
DATA : gv_okcode    TYPE sy-ucomm,
       gs_button    TYPE stb_button,
       gv_title     TYPE char50,
       gv_sel_banfn TYPE ztc1mm0025-banfn.

*-- 결재요청 버튼 표시 권한 (직급 기준)
DATA : gv_my_grade TYPE ztc1hr0001-zgrade,
       gv_can_appr TYPE abap_bool.

*-- HTML용 PO 카운트
DATA : gv_cnt_all  TYPE i,
       gv_cnt_wait TYPE i,
       gv_cnt_ing  TYPE i,
       gv_cnt_done TYPE i,
       gv_cnt_rej  TYPE i.

*-- 결재 탭 화면 상태
DATA : gv_curr_stat   TYPE c LENGTH 4 VALUE 'ALL',  " ALL/WAIT/ING/DONE/REJ
       gv_detail_open TYPE abap_bool,
       gv_card_init   TYPE abap_bool,
       gv_dtl_init    TYPE abap_bool.

*-- 수정 팝업 상태 / 헤더 정보 (Dynpro 필드용)
DATA : gv_modi_ebeln TYPE ztc1mm0007-ebeln,
       gv_modi_lifnr TYPE ztc1mm0007-lifnr,
       gv_modi_name1 TYPE ztc1mm0012-name1,
       gv_modi_bedat TYPE ztc1mm0007-bedat,
       gv_modi_waers TYPE ztc1mm0007-waers,
       gv_modi_statu TYPE ztc1mm0007-statu,
       gv_modi_stxt  TYPE char20,
       gv_modi_bigo  TYPE ztc1mm0007-bigo,
       ok_code_0200  TYPE sy-ucomm.

**********************************************************************
* Screen Painter variable
**********************************************************************
DATA : gv_badat_to TYPE ztc1mm0025-badat,  " 구매요청일 to
       gv_bedat_to TYPE ztc1mm0007-bedat.  " 구매오더 생성일 to

CONSTANTS gc_small_appr_limit TYPE p LENGTH 13 DECIMALS 2 VALUE '100000.00'.

*--------------------------------------------------------------------*
* 상단 ERP 헤더
DATA: go_html_dock   TYPE REF TO cl_gui_docking_container,
      go_html_header TYPE REF TO zcl_c1_co_html.
