*&---------------------------------------------------------------------*
*& Include ZRC1MM0010_TOP                           - Report ZRC1MM0010
*&---------------------------------------------------------------------*
REPORT zrc1mm0010 MESSAGE-ID zmcl301.

**********************************************************************
* TAB Strip
**********************************************************************
CONTROLS : tab_strip TYPE TABSTRIP.
DATA : gv_dynnr TYPE sy-dynnr.

**********************************************************************
* TABLES
**********************************************************************
TABLES : ztc1mm0001,  " 자재 마스터
         ztc1mm0007,  " PO 헤더
         ztc1mm0008,  " PO 아이템
         ztc1mm0011,  " EKBE 구매이력
         ztc1mm0012,  " 공급업체
         ztc1mm0017,  " IV 헤더
         ztc1mm0018.  " IV 아이템

**********************************************************************
* Class instance
**********************************************************************
*-- 단건 송장검증 탭
DATA : go_single_cont TYPE REF TO cl_gui_custom_container,
       go_single_alv  TYPE REF TO cl_gui_alv_grid.

*-- 대량 송장검증 탭
DATA : go_mass_cont TYPE REF TO cl_gui_custom_container,
       go_mass_alv  TYPE REF TO cl_gui_alv_grid.

**********************************************************************
* Internal tabble and Work area
**********************************************************************
*-- 단건 : 송장 품목 (편집 ALV)
DATA : BEGIN OF gs_single,
         icon     TYPE icon_d,             " 결과 아이콘
         buzei    TYPE ztc1mm0018-buzei,   " 항번
         ebeln    TYPE ztc1mm0008-ebeln,   " PO 번호
         ebelp    TYPE ztc1mm0008-ebelp,   " PO 아이템
         matnr    TYPE ztc1mm0008-matnr,   " 자재번호
         maktx    TYPE ztc1mm0001-maktx,   " 자재명
         werks    TYPE ztc1mm0008-werks,   " 플랜트
         po_menge TYPE ztc1mm0008-menge,   " PO 수량
         gr_menge TYPE ztc1mm0008-menge,   " GR 누적
         iv_acc   TYPE ztc1mm0008-menge,   " 기청구누적
         open_qty TYPE ztc1mm0008-menge,   " 청구가능 잔량
         iv_menge TYPE ztc1mm0018-menge,   " 송장수량 (편집)
         meins    TYPE ztc1mm0018-meins,   " 단위
         po_netpr TYPE ztc1mm0008-netpr,   " PO 단가
         iv_netpr TYPE ztc1mm0018-netpr,   " 송장단가 (편집)
         peinh    TYPE ztc1mm0018-peinh,   " 가격단위
         po_amt   TYPE ztc1mm0018-wrbtr,   " PO 금액
         wrbtr    TYPE ztc1mm0018-wrbtr,   " 송장금액
         waers    TYPE ztc1mm0018-waers,   " 통화
         diff_amt TYPE ztc1mm0018-wrbtr,   " 차액
         msg(40)  TYPE c,                  " 검증 메시지
         celltab  TYPE lvc_t_styl,         " 셀 편집
       END OF gs_single,
       gt_single LIKE TABLE OF gs_single.

*-- 대량 : 엑셀
DATA : BEGIN OF gs_excel,
         xblnr TYPE ztc1mm0017-xblnr,
         lifnr TYPE ztc1mm0012-lifnr,
         bldat TYPE ztc1mm0017-bldat,
         budat TYPE ztc1mm0017-budat,
         ebeln TYPE ztc1mm0018-ebeln,
         ebelp TYPE ztc1mm0018-ebelp,
         matnr TYPE ztc1mm0018-matnr,
         menge TYPE ztc1mm0018-menge,
         meins TYPE ztc1mm0018-meins,
         netpr TYPE ztc1mm0018-netpr,
         peinh TYPE ztc1mm0018-peinh,
         wrbtr TYPE ztc1mm0018-wrbtr,
         waers TYPE ztc1mm0017-waers,
       END OF gs_excel,
       gt_excel LIKE TABLE OF gs_excel.

*-- 대량 : 매칭 결과
DATA : BEGIN OF gs_mass,
         icon       TYPE icon_d,
         xblnr      TYPE ztc1mm0017-xblnr,
         lifnr      TYPE ztc1mm0012-lifnr,
         name1      TYPE ztc1mm0012-name1,
         bldat      TYPE ztc1mm0017-bldat,
         budat      TYPE ztc1mm0017-budat,
         ebeln      TYPE ztc1mm0008-ebeln,
         ebelp      TYPE ztc1mm0008-ebelp,
         matnr      TYPE ztc1mm0008-matnr,
         maktx      TYPE ztc1mm0001-maktx,        " 자재명
         werks      TYPE ztc1mm0008-werks,
         iv_menge   TYPE ztc1mm0018-menge,
         po_menge   TYPE ztc1mm0008-menge,
         gr_menge   TYPE ztc1mm0008-menge,
         iv_acc     TYPE ztc1mm0008-menge,
         open_qty   TYPE ztc1mm0008-menge,
         meins      TYPE ztc1mm0018-meins,
         iv_netpr   TYPE ztc1mm0008-netpr,
         po_netpr   TYPE ztc1mm0008-netpr,
         peinh      TYPE ztc1mm0018-peinh,
         po_amt     TYPE ztc1mm0018-wrbtr,        " PO 예상금액
         wrbtr      TYPE ztc1mm0018-wrbtr,        " 송장 청구금액 (벤더 청구액)
         waers      TYPE ztc1mm0018-waers,
         diff_amt   TYPE ztc1mm0018-wrbtr,        " 차액
         post_amt   TYPE ztc1mm0018-wrbtr,        " 전기예정금액 (합계 대상)
         status(10) TYPE c,
         msg(40)    TYPE c,
         block      TYPE c,                       " 송장 전체 보류 ('X')
       END OF gs_mass,
       gt_mass LIKE TABLE OF gs_mass.

TYPES: tt_invitem TYPE STANDARD TABLE OF ztc1mm0018 WITH DEFAULT KEY. " 포스팅용


*-- ALV 설정
DATA : gt_fcat_single   TYPE lvc_t_fcat,
       gt_fcat_mass     TYPE lvc_t_fcat,
       gs_fcat          TYPE lvc_s_fcat,
       gs_layout        TYPE lvc_s_layo,
       gs_layout_single TYPE lvc_s_layo,
       gs_layout_mass   TYPE lvc_s_layo,
       gt_sort_mass     TYPE lvc_t_sort,           " 대량 ALV 서브토탈 정렬
       gs_variant       TYPE disvariant.

*-- EBELN Search help용
DATA : BEGIN OF gs_sh_ebeln,
         ebeln TYPE ztc1mm0007-ebeln,
         lifnr TYPE ztc1mm0007-lifnr,
         name1 TYPE ztc1mm0012-name1,
         bedat TYPE ztc1mm0007-bedat,
       END OF gs_sh_ebeln,
       gt_sh_ebeln LIKE TABLE OF gs_sh_ebeln.

**********************************************************************
* Common variable
**********************************************************************
DATA : gv_okcode  TYPE sy-ucomm,
       gv_save_ok TYPE sy-ucomm.

*-- 단건 검증 완료 플래그 ('X' = 검증 거친 최신 상태 / '' = 미검증·재검증필요)
DATA gv_s_verified TYPE c.

*-- 단건 송장검증 탭 변수
DATA : gv_s_ebeln       TYPE ztc1mm0008-ebeln,    " 조회 PO번호
       gv_s_xblnr       TYPE ztc1mm0017-xblnr,    " 외부송장번호
       gv_s_lifnr       TYPE ztc1mm0012-lifnr,    " 벤더
       gv_s_name1       TYPE ztc1mm0012-name1,    " 벤더명
       gv_s_bldat       TYPE ztc1mm0017-bldat,    " 송장일자
       gv_s_budat       TYPE ztc1mm0017-budat,    " 전기일자
       gv_s_waers       TYPE ztc1mm0017-waers,    " 통화
       gv_s_input_total TYPE ztc1mm0017-rmwwr,    " 송장총액 (사용자 입력)
       gv_s_total       TYPE ztc1mm0017-rmwwr,    " 송장총액 (자동계산)
       gv_s_diff        TYPE ztc1mm0017-rmwwr,    " 차이금액
       gv_s_icon_bal    TYPE icon_d,              " Balance 일치 아이콘
       gv_s_bal_txt(10) TYPE c,                   " Balance 텍스트
       gv_s_icon        TYPE icon_d,              " 전체 상태 아이콘
       gv_s_state(20)   TYPE c.                   " 상태 텍스트

*-- 대량 송장검증 탭 변수
DATA : gv_m_files_cnt TYPE i,
       gv_m_total     TYPE i,                     " 전체 건수
       gv_m_pass      TYPE i,                     " 통과 건수
       gv_m_fail      TYPE i,                     " 실패 건수
       gv_m_skip      TYPE i.                     " 기처리(중복) 건수


**********************************************************************
* Constants
**********************************************************************
CONSTANTS : gc_state_cr  TYPE ztc1mm0017-zstate VALUE 'CR', " 생성
            gc_state_bl  TYPE ztc1mm0017-zstate VALUE 'BL', " 블로킹
            gc_state_ps  TYPE ztc1mm0017-zstate VALUE 'PS', " 전기완료
            gc_block_q   TYPE ztc1mm0017-zblock VALUE 'Q',  " 수량차이
            gc_block_p   TYPE ztc1mm0017-zblock VALUE 'P',  " 단가차이
            gc_vgabe_gr  TYPE ztc1mm0011-vgabe  VALUE '1',  " GR
            gc_vgabe_ir  TYPE ztc1mm0011-vgabe  VALUE '2',  " IR
            gc_tolerance TYPE p DECIMALS 4 VALUE '0.05'.    " 허용 오차율 5%

*--------------------------------------------------------------------*
* 상단 ERP 헤더
DATA: go_html_dock   TYPE REF TO cl_gui_docking_container,
      go_html_header TYPE REF TO zcl_c1_co_html.

*--------------------------------------------------------------------*
