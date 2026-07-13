*&---------------------------------------------------------------------*
*& Include          ZRC1MM0010_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form display_screen
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_screen .

  IF go_single_cont IS NOT BOUND.

*-- 컨테이너 생성
    PERFORM create_tab1.
    PERFORM create_tab2.

*-- 필드 카탈로그 설정
    CLEAR : gt_fcat_single, gt_fcat_mass, gs_fcat.
    PERFORM set_field_catalog USING :
                                      " S : 단건 송장검증
                                      'S' 'X' 'ICON'     ''           'C' '',
                                      'S' 'X' 'MSG'      ''           ''  '',
                                      'S' 'X' 'BUZEI'    'ZTC1MM0018' 'C' '',
                                      'S' ' ' 'EBELN'    'ZTC1MM0008' ''  '',
                                      'S' ' ' 'EBELP'    'ZTC1MM0008' 'C' '',
                                      'S' ' ' 'MATNR'    'ZTC1MM0008' ''  '',
                                      'S' ' ' 'MAKTX'    'ZTC1MM0001' ''  'X',
                                      'S' ' ' 'WERKS'    'ZTC1MM0008' 'C' '',
                                      'S' ' ' 'PO_MENGE' ''           ''  '',
                                      'S' ' ' 'GR_MENGE' ''           ''  '',
                                      'S' ' ' 'IV_ACC'   ''           ''  '',
                                      'S' ' ' 'OPEN_QTY' ''           ''  '',
                                      'S' ' ' 'IV_MENGE' ''           ''  '',
                                      'S' ' ' 'MEINS'    'ZTC1MM0018' 'C' '',
                                      'S' ' ' 'PO_NETPR' ''           ''  '',
                                      'S' ' ' 'IV_NETPR' ''           ''  '',
                                      'S' ' ' 'PEINH'    'ZTC1MM0018' ''  '',
                                      'S' ' ' 'PO_AMT'   ''           ''  '',
                                      'S' ' ' 'WRBTR'    'ZTC1MM0018' ''  '',
                                      'S' ' ' 'DIFF_AMT' ''           ''  '',
                                      'S' ' ' 'WAERS'    'ZTC1MM0018' 'C' '',

                                      " M : 대량 송장검증
                                      'M' 'X' 'ICON'     ''           'C' '',
                                      'M' 'X' 'MSG'      ''           ''  '',
                                      'M' ' ' 'XBLNR'    'ZTC1MM0017' ''  '',
                                      'M' ' ' 'LIFNR'    'ZTC1MM0012' 'C' '',
                                      'M' ' ' 'NAME1'    'ZTC1MM0012' ''  '',
                                      'M' ' ' 'EBELN'    'ZTC1MM0008' ''  '',
                                      'M' ' ' 'EBELP'    'ZTC1MM0008' 'C' '',
                                      'M' ' ' 'MATNR'    'ZTC1MM0008' ''  '',
                                      'M' ' ' 'MAKTX'    'ZTC1MM0001' ''  'X',
                                      'M' ' ' 'WERKS'    'ZTC1MM0008' 'C' '',
                                      'M' ' ' 'PO_MENGE' ''           ''  '',
                                      'M' ' ' 'GR_MENGE' ''           ''  '',
                                      'M' ' ' 'IV_ACC'   ''           ''  '',
                                      'M' ' ' 'OPEN_QTY' ''           ''  '',
                                      'M' ' ' 'IV_MENGE' ''           ''  '',
                                      'M' ' ' 'MEINS'    'ZTC1MM0018' 'C' '',
                                      'M' ' ' 'PO_NETPR' ''           ''  '',
                                      'M' ' ' 'PEINH'    'ZTC1MM0018' ''  '',
                                      'M' ' ' 'PO_AMT'   ''           ''  '',
                                      'M' ' ' 'WRBTR'    'ZTC1MM0018' ''  '',
                                      'M' ' ' 'DIFF_AMT' ''           ''  '',
                                      'M' ' ' 'POST_AMT' ''           ''  '',
                                      'M' ' ' 'WAERS'    'ZTC1MM0018' 'C' ''.

*-- 레이아웃 설정
    PERFORM set_layout.

*-- 이벤트 핸들러
    SET HANDLER : lcl_event_handler=>on_data_changed_finished  FOR go_single_alv,
                  lcl_event_handler=>on_toolbar FOR go_single_alv.

*-- ALV 출력
    PERFORM create_display.

*-- 단건 편집 이벤트 등록
    CALL METHOD go_single_alv->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_tab1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_tab1 .

*-- 단건 송장검증
  CREATE OBJECT go_single_cont
    EXPORTING
      container_name = 'SINGLE_CONT'.

  CREATE OBJECT go_single_alv
    EXPORTING
      i_parent = go_single_cont.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_tab2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_tab2 .

*-- 대량 송장검증
  CREATE OBJECT go_mass_cont
    EXPORTING
      container_name = 'MASS_CONT'.

  CREATE OBJECT go_mass_alv
    EXPORTING
      i_parent = go_mass_cont.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> P_
*&---------------------------------------------------------------------*
FORM set_field_catalog  USING pv_flag pv_key pv_field pv_table pv_just pv_emph.

  gs_fcat = VALUE #( key       = pv_key
                     fieldname = pv_field
                     ref_table = pv_table
                     just      = pv_just
                     emphasize = pv_emph ).

*-- 공통 속성 (아이콘, 수량단위, 통화 연결)
  CASE pv_field.
    WHEN 'ICON'.
      gs_fcat-icon = 'X'.

    WHEN 'PO_MENGE' OR 'GR_MENGE' OR 'IV_ACC' OR 'OPEN_QTY'.
      gs_fcat-ref_table  = 'ZTC1MM0008'.
      gs_fcat-ref_field  = 'MENGE'.
      gs_fcat-qfieldname = 'MEINS'.

    WHEN 'IV_MENGE'.
      gs_fcat-ref_table  = 'ZTC1MM0018'.
      gs_fcat-ref_field  = 'MENGE'.
      gs_fcat-qfieldname = 'MEINS'.

    WHEN 'PO_NETPR'.
      gs_fcat-ref_table  = 'ZTC1MM0008'.
      gs_fcat-ref_field  = 'NETPR'.
      gs_fcat-cfieldname = 'WAERS'.

    WHEN 'IV_NETPR'.
      gs_fcat-ref_table  = 'ZTC1MM0018'.
      gs_fcat-ref_field  = 'NETPR'.
      gs_fcat-cfieldname = 'WAERS'.

    WHEN 'PO_AMT' OR 'DIFF_AMT' OR 'POST_AMT'.
      gs_fcat-ref_table  = 'ZTC1MM0018'.
      gs_fcat-ref_field  = 'WRBTR'.
      gs_fcat-cfieldname = 'WAERS'.

    WHEN 'WRBTR'.
      gs_fcat-ref_table  = 'ZTC1MM0018'.
      gs_fcat-ref_field  = 'WRBTR'.
      gs_fcat-cfieldname = 'WAERS'.
  ENDCASE.

*-- 컬럼 텍스트
  CASE pv_field.
    WHEN 'ICON'.
      gs_fcat-coltext = '상태'.
      gs_fcat-outputlen = 4.
    WHEN 'BUZEI'.
      gs_fcat-coltext = '항번'.
      gs_fcat-outputlen = 4.
    WHEN 'XBLNR'.
      gs_fcat-coltext = '외부송장번호'.
      gs_fcat-outputlen = 10.
    WHEN 'LIFNR'.
      gs_fcat-coltext = '벤더번호'.
      gs_fcat-outputlen = 5.
    WHEN 'NAME1'.
      gs_fcat-coltext = '벤더명'.
      gs_fcat-outputlen = 15.
    WHEN 'EBELN'.
      gs_fcat-coltext = '구매오더번호'.
      gs_fcat-outputlen = 10.
    WHEN 'EBELP'.
      gs_fcat-coltext = '품목'.
      gs_fcat-outputlen = 3.
    WHEN 'MATNR'.
      gs_fcat-coltext = '자재번호'.
      gs_fcat-outputlen = 10.
    WHEN 'MAKTX'.
      gs_fcat-coltext = '자재명'.
      gs_fcat-outputlen = 15.
    WHEN 'WERKS'.
      gs_fcat-coltext = '플랜트'.
      gs_fcat-outputlen = 6.
    WHEN 'PO_MENGE'.
      gs_fcat-coltext = '구매오더수량'.
      gs_fcat-outputlen = 8.
    WHEN 'GR_MENGE'.
      gs_fcat-coltext = '입고누적'.
      gs_fcat-outputlen = 7.
    WHEN 'IV_ACC'.
      gs_fcat-coltext = '기청구'.
      gs_fcat-outputlen = 7.
    WHEN 'OPEN_QTY'.
      gs_fcat-coltext = '청구가능'.
      gs_fcat-outputlen = 8.
    WHEN 'IV_MENGE'.
*--   단건은 직접 입력(편집) 컬럼이라 연필 표시, 대량은 엑셀값이라 미표시
      IF pv_flag = 'S'.
        gs_fcat-coltext = '송장수량 ✎'.
      ELSE.
        gs_fcat-coltext = '송장수량'.
      ENDIF.
      gs_fcat-outputlen = 8.
    WHEN 'MEINS'.
      gs_fcat-coltext = '단위'.
      gs_fcat-outputlen = 4.
    WHEN 'PO_NETPR'.
      gs_fcat-coltext = '구매오더단가'.
      gs_fcat-outputlen = 8.
    WHEN 'IV_NETPR'.
*--   단건만 직접 입력(편집) 컬럼이라 연필 표시
      IF pv_flag = 'S'.
        gs_fcat-coltext = '송장단가 ✎'.
      ELSE.
        gs_fcat-coltext = '송장단가'.
      ENDIF.
      gs_fcat-outputlen = 8.
    WHEN 'PEINH'.
      gs_fcat-coltext = '단위'.
      gs_fcat-outputlen = 5.
    WHEN 'PO_AMT'.
      gs_fcat-coltext = '예상금액'.
      gs_fcat-outputlen = 10.
    WHEN 'WRBTR'.
      gs_fcat-coltext = '송장금액'.
      gs_fcat-outputlen = 10.
    WHEN 'WAERS'.
      gs_fcat-coltext = '통화'.
      gs_fcat-outputlen = 4.
    WHEN 'DIFF_AMT'.
      gs_fcat-coltext = '차액'.
      gs_fcat-outputlen = 8.
    WHEN 'POST_AMT'.
      gs_fcat-coltext = '전기예정금액'.
      gs_fcat-outputlen = 12.
    WHEN 'MSG'.
      gs_fcat-coltext = '검증메시지'.
      gs_fcat-outputlen = 10.
  ENDCASE.

  CASE pv_field.
    WHEN 'OPEN_QTY' OR 'IV_MENGE'.
      gs_fcat-emphasize = 'C300'.   " 수량 짝
    WHEN 'PO_AMT' OR 'WRBTR'.
      gs_fcat-emphasize = 'C100'.   " 금액 짝
    WHEN 'POST_AMT'.
      gs_fcat-emphasize = 'C500'.   " 전기 대상 금액 (초록)
  ENDCASE.

*-- 단건 ALV 편집 셀 (송장수량 / 송장단가)
  IF pv_flag = 'S'.
    CASE pv_field.
      WHEN 'IV_MENGE' OR 'IV_NETPR'.
        gs_fcat-edit = 'X'.
    ENDCASE.
  ENDIF.

*-- 대량 ALV 합계 대상 : 전기예정금액만 (실제 전기될 금액과 일치)
  IF pv_flag = 'M'.
    CASE pv_field.
      WHEN 'POST_AMT'.
        gs_fcat-do_sum = 'X'.
    ENDCASE.
  ENDIF.

  CASE pv_flag.
    WHEN 'S'.
      APPEND gs_fcat TO gt_fcat_single.
    WHEN 'M'.
      APPEND gs_fcat TO gt_fcat_mass.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_layout .

  gs_layout_single = VALUE #( zebra      = abap_true
                              sel_mode   = 'A'
                              stylefname = 'CELLTAB'
                              grid_title = '단건 송장 품목' ).

  gs_layout_mass  = VALUE #( zebra      = abap_true
                             cwidth_opt = 'A'
                             sel_mode   = 'A'
                             grid_title = '대량 송장검증 결과' ).

  gs_variant = VALUE #( report = sy-repid
                        handle = 'IV' ).

*-- 대량: 송장(LIFNR + XBLNR) 단위 금액 서브토탈
  CLEAR gt_sort_mass.
  gt_sort_mass = VALUE #( ( spos = 1 fieldname = 'LIFNR' up = 'X' )
                          ( spos = 2 fieldname = 'XBLNR' up = 'X' subtot = 'X' )
                          ( spos = 3 fieldname = 'EBELN' up = 'X' )
                          ( spos = 4 fieldname = 'EBELP' up = 'X' ) ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_display
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_display .

*-- 단건 송장검증
  CALL METHOD go_single_alv->set_table_for_first_display
    EXPORTING
      is_variant      = gs_variant
      i_save          = 'A'
      i_default       = 'X'
      is_layout       = gs_layout_single
    CHANGING
      it_outtab       = gt_single
      it_fieldcatalog = gt_fcat_single.

*-- 대량 송장검증
  CALL METHOD go_mass_alv->set_table_for_first_display
    EXPORTING
      is_variant      = gs_variant
      i_save          = 'A'
      i_default       = 'X'
      is_layout       = gs_layout_mass
    CHANGING
      it_outtab       = gt_mass
      it_sort         = gt_sort_mass
      it_fieldcatalog = gt_fcat_mass.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_subscreen_number
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_subscreen_number .

  CASE tab_strip-activetab.
    WHEN 'TAB1'.
      gv_dynnr = '0110'.
      SET PF-STATUS 'SINGLE'.
    WHEN 'TAB2'.
      gv_dynnr = '0120'.
      SET PF-STATUS 'MASS'.
    WHEN OTHERS.
      gv_dynnr = '0110'.
      tab_strip-activetab = 'TAB1'.
      SET PF-STATUS 'SINGLE'.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_table
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PO_ALV
*&---------------------------------------------------------------------*
FORM refresh_table USING po_alv TYPE REF TO cl_gui_alv_grid.

  DATA : ls_stable TYPE lvc_s_stbl.

  ls_stable-col = 'X'.
  ls_stable-row = 'X'.

  CALL METHOD po_alv->refresh_table_display
    EXPORTING
      is_stable = ls_stable.

ENDFORM.
**********************************************************************
* 공통 데이터 조회
**********************************************************************
*&---------------------------------------------------------------------*
*& Form get_gr_qty
*&---------------------------------------------------------------------*
*& GR 누적 = EKBE WHERE VGABE='1' (SHKZG 부호 처리)
*&---------------------------------------------------------------------*
*&      --> PV_EBELN
*&      --> PV_EBELP
*&      <-- CV_GR
*&---------------------------------------------------------------------*
FORM get_gr_qty USING    pv_ebeln TYPE ztc1mm0008-ebeln
                         pv_ebelp TYPE ztc1mm0008-ebelp
                CHANGING cv_gr    TYPE ztc1mm0008-menge.

  DATA : lt_ekbe TYPE TABLE OF ztc1mm0011,
         ls_ekbe TYPE ztc1mm0011.

  CLEAR cv_gr.

  SELECT * FROM ztc1mm0011
    INTO TABLE lt_ekbe
   WHERE ebeln = pv_ebeln
     AND ebelp = pv_ebelp
     AND vgabe = gc_vgabe_gr.

  LOOP AT lt_ekbe INTO ls_ekbe.
    IF ls_ekbe-shkzg = 'S'.
      cv_gr = cv_gr + ls_ekbe-menge.
    ELSE.
      cv_gr = cv_gr - ls_ekbe-menge.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_iv_qty
*&---------------------------------------------------------------------*
*& 기청구 누적 = EKBE WHERE VGABE='2'
*&---------------------------------------------------------------------*
*&      --> PV_EBELN
*&      --> PV_EBELP
*&      <-- CV_IV
*&---------------------------------------------------------------------*
FORM get_iv_qty USING    pv_ebeln TYPE ztc1mm0008-ebeln
                         pv_ebelp TYPE ztc1mm0008-ebelp
                CHANGING cv_iv    TYPE ztc1mm0008-menge.

  CLEAR cv_iv.

  SELECT SUM( menge ) INTO cv_iv
    FROM ztc1mm0011
   WHERE ebeln = pv_ebeln
     AND ebelp = pv_ebelp
     AND vgabe = gc_vgabe_ir.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_open_qty
*&---------------------------------------------------------------------*
*& 청구가능잔량 = MIN(GR누적, PO수량) - 기청구누적
*&---------------------------------------------------------------------*
FORM calc_open_qty USING    pv_po_qty TYPE ztc1mm0008-menge
                            pv_gr     TYPE ztc1mm0008-menge
                            pv_iv     TYPE ztc1mm0008-menge
                   CHANGING cv_open   TYPE ztc1mm0008-menge.

  IF pv_gr > pv_po_qty.
    cv_open = pv_po_qty - pv_iv.
  ELSE.
    cv_open = pv_gr - pv_iv.
  ENDIF.

  IF cv_open < 0.
    cv_open = 0.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form convert_date_string
*&---------------------------------------------------------------------*
*& 문자열 일자 -> DATS
*&---------------------------------------------------------------------*
FORM convert_date_string USING    pv_in  TYPE c
                         CHANGING pv_out TYPE d.

  DATA : lv_clean(10) TYPE c.

  lv_clean = pv_in.
  REPLACE ALL OCCURRENCES OF '-' IN lv_clean WITH ''.
  REPLACE ALL OCCURRENCES OF '.' IN lv_clean WITH ''.
  REPLACE ALL OCCURRENCES OF '/' IN lv_clean WITH ''.

  pv_out = lv_clean.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form number_get_belnr
*&---------------------------------------------------------------------*
*& IV 송장번호 채번
*&---------------------------------------------------------------------*
FORM number_get_belnr CHANGING pv_belnr TYPE ztc1mm0017-belnr.

  CLEAR pv_belnr.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = 'IV'
      object                  = 'ZNRC1MM01'
    IMPORTING
      number                  = pv_belnr
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0.
    CLEAR pv_belnr.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_xblnr_dup
*&---------------------------------------------------------------------*
*& 외부송장번호 중복 체크 (LIFNR + XBLNR 조합)
*&---------------------------------------------------------------------*
*&      --> PV_LIFNR
*&      --> PV_XBLNR
*&      <-- CV_DUP   ('X' 중복 / '' OK)
*&      <-- CV_BELNR (기존 송장번호)
*&---------------------------------------------------------------------*
FORM check_xblnr_dup USING    pv_lifnr TYPE ztc1mm0012-lifnr
                              pv_xblnr TYPE ztc1mm0017-xblnr
                     CHANGING cv_dup   TYPE c
                              cv_belnr TYPE ztc1mm0017-belnr.

  CLEAR : cv_dup, cv_belnr.

  CHECK pv_xblnr IS NOT INITIAL.

  SELECT SINGLE belnr INTO cv_belnr
    FROM ztc1mm0017
   WHERE lifnr = pv_lifnr
     AND xblnr = pv_xblnr.

  IF sy-subrc = 0.
    cv_dup = 'X'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form determine_iv_state
*&---------------------------------------------------------------------*
*& 송장 상태 (ZSTATE) / 블로킹 사유 (ZBLOCK) 결정
*&  - 빨강 존재 → 호출 안 함 (전기 차단)
*&  - 노랑 존재 → BL + ZBLOCK
*&  - 전부 OK   → PS
*&---------------------------------------------------------------------*
FORM determine_iv_state USING    pv_yellow_cnt TYPE i
                                 pv_qty_diff   TYPE c
                                 pv_price_diff TYPE c
                        CHANGING cv_state      TYPE ztc1mm0017-zstate
                                 cv_block      TYPE ztc1mm0017-zblock.

  CLEAR : cv_state, cv_block.

  IF pv_yellow_cnt > 0.
    cv_state = gc_state_bl.
*-- 단가차이 우선
    IF pv_price_diff = 'X'.
      cv_block = gc_block_p.
    ELSEIF pv_qty_diff = 'X'.
      cv_block = gc_block_q.
    ENDIF.
  ELSE.
    cv_state = gc_state_ps.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form call_ap_voucher
*&---------------------------------------------------------------------*
*&      --> PS_HDR
*&      --> PT_ITM
*&      <-- CV_RC
*&      <-- CV_MSG
*&      <-- CV_FI_BELNR
*&---------------------------------------------------------------------*
*& IV 송장 1건에 대한 FI AP 전표 생성
*& - FI 전표는 송장 헤더 총액 기준으로 생성
*& - 역추적은 FI 헤더 AWTYP/AWKEY = MM 송장번호+연도 기준
*& - IS_INVITEM은 기존 FI 펑션 필수값이라 대표 품목 1건만 전달
*& - COMMIT은 호출자(post_single / post_mass)가 처리
*&---------------------------------------------------------------------*
FORM call_ap_voucher USING    ps_hdr TYPE ztc1mm0017
                              pt_itm TYPE tt_invitem
                     CHANGING cv_rc       TYPE sy-subrc
                              cv_msg      TYPE char100
                              cv_fi_belnr TYPE ztc1fi0006-belnr.

  DATA : ls_itm      TYPE ztc1mm0018,
         lv_belnr    TYPE ztc1fi0006-belnr,
         lv_fi_belnr TYPE ztc1fi0006-belnr,
         lv_gjahr    TYPE ztc1fi0006-gjahr,
         lv_msg      TYPE char100.

  CLEAR : cv_rc, cv_msg, cv_fi_belnr, lv_belnr, lv_fi_belnr, lv_msg.

*--------------------------------------------------------------------*
* 1. 입력 검증
*--------------------------------------------------------------------*
  IF ps_hdr IS INITIAL.
    cv_rc  = 4.
    cv_msg = 'FI 전표 생성 실패: 송장 헤더가 없습니다.'.
    RETURN.
  ENDIF.

  IF pt_itm IS INITIAL.
    cv_rc  = 4.
    cv_msg = 'FI 전표 생성 실패: 송장 품목이 없습니다.'.
    RETURN.
  ENDIF.

  IF ps_hdr-budat IS INITIAL.
    cv_rc  = 4.
    cv_msg = 'FI 전표 생성 실패: 전기일자가 없습니다.'.
    RETURN.
  ENDIF.

  IF ps_hdr-rmwwr IS INITIAL OR ps_hdr-rmwwr <= 0.
    cv_rc  = 4.
    cv_msg = 'FI 전표 생성 실패: 송장 총액이 0입니다.'.
    RETURN.
  ENDIF.

*--------------------------------------------------------------------*
* 2. 기존 FI 펑션 필수값용 대표 품목 1건 선정
*    FI 포스팅 금액은 PS_HDR-RMWWR 총액 기준이므로
*    품목 상세는 MM 송장품목 ZTC1MM0018에서 추적
*--------------------------------------------------------------------*
  READ TABLE pt_itm INTO ls_itm INDEX 1.

  IF sy-subrc <> 0 OR ls_itm-matnr IS INITIAL.
    cv_rc  = 4.
    cv_msg = 'FI 전표 생성 실패: 대표 송장 품목을 찾을 수 없습니다.'.
    RETURN.
  ENDIF.

*--------------------------------------------------------------------*
* 3. FI 회계연도 결정
*--------------------------------------------------------------------*
  lv_gjahr = ps_hdr-budat(4).

*--------------------------------------------------------------------*
* 4. FI 전표번호 채번
*--------------------------------------------------------------------*
  CALL FUNCTION 'ZFC1FI0001'
    EXPORTING
      iv_bukrs       = '1000'
      iv_blart       = 'RE'
      iv_gjahr       = lv_gjahr
    IMPORTING
      ev_belnr       = lv_belnr
    EXCEPTIONS
      not_found      = 1
      nr_range_error = 2
      OTHERS         = 3.

  IF sy-subrc <> 0 OR lv_belnr IS INITIAL.
    cv_rc  = sy-subrc.
    cv_msg = 'FI 전표번호 채번 실패'.
    RETURN.
  ENDIF.

*--------------------------------------------------------------------*
* 5. 기존 FI 펑션 호출
*--------------------------------------------------------------------*
  CALL FUNCTION 'ZFC1FI0006'
    EXPORTING
      iv_belnr          = lv_belnr
      iv_mm_event       = 'IV'
      is_invdoc         = ps_hdr
      is_invitem        = ls_itm
      iv_budat          = ps_hdr-budat
      iv_bldat          = ps_hdr-bldat
    IMPORTING
      ev_belnr          = lv_fi_belnr
      ev_msg            = lv_msg
    TABLES
      it_invitem        = pt_itm
    EXCEPTIONS
      mapping_not_found = 1
      posting_error     = 2
      OTHERS            = 3.

  IF sy-subrc <> 0.
    cv_rc = sy-subrc.

    IF lv_msg IS NOT INITIAL.
      cv_msg = lv_msg.
    ELSE.
      cv_msg = |FI AP 전표 생성 실패: FI전표번호={ lv_belnr }|.
    ENDIF.

    RETURN.
  ENDIF.

*--------------------------------------------------------------------*
* 6. 정상 종료
*--------------------------------------------------------------------*
  cv_rc = 0.

  IF lv_fi_belnr IS NOT INITIAL.
    cv_fi_belnr = lv_fi_belnr.
  ELSE.
    cv_fi_belnr = lv_belnr.
  ENDIF.

  IF lv_msg IS NOT INITIAL.
    cv_msg = lv_msg.
  ELSE.
    cv_msg = |FI AP 전표 생성 완료: { cv_fi_belnr }|.
  ENDIF.

ENDFORM.
**********************************************************************
* === 탭1 단건 송장검증 ===
**********************************************************************
*&---------------------------------------------------------------------*
*& Form search_single_po
*&---------------------------------------------------------------------*
*& PO번호로 송장 품목 조회 + 편집 ALV 표시
*&---------------------------------------------------------------------*
FORM search_single_po .

  DATA : lt_po    TYPE TABLE OF ztc1mm0008,
         ls_po    TYPE ztc1mm0008,
         ls_head  TYPE ztc1mm0007,
         lv_gr    TYPE ztc1mm0008-menge,
         lv_iv    TYPE ztc1mm0008-menge,
         lv_open  TYPE ztc1mm0008-menge,
         lv_buzei TYPE n LENGTH 3.

  IF gv_s_ebeln IS INITIAL.
    MESSAGE 'PO 번호를 입력하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- PO 헤더
  SELECT SINGLE * FROM ztc1mm0007
    INTO ls_head
   WHERE ebeln = gv_s_ebeln
     AND loekz = ''.

  IF sy-subrc <> 0.
    MESSAGE 'PO를 찾을 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 승인완료 PO만 송장검증 가능
  IF ls_head-statu <> 'AP'.
    MESSAGE '승인 완료된 PO만 송장검증 가능합니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  gv_s_lifnr = ls_head-lifnr.
  gv_s_waers = ls_head-waers.

*-- 송장일자 / 전기일자 기본값
  IF gv_s_bldat IS INITIAL.
    gv_s_bldat = sy-datum.
  ENDIF.

  IF gv_s_budat IS INITIAL.
    gv_s_budat = sy-datum.
  ENDIF.

*-- 벤더명
  SELECT SINGLE name1 INTO gv_s_name1
    FROM ztc1mm0012
   WHERE lifnr = gv_s_lifnr.

*-- PO 아이템 (IV 대상)
  SELECT * FROM ztc1mm0008
    INTO TABLE lt_po
   WHERE ebeln = gv_s_ebeln
     AND loekz = ''
     AND repos = 'X'.

  IF lt_po IS INITIAL.
    MESSAGE 'IV 대상 PO 품목이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 송장 품목 ALV 구성
  CLEAR : gs_single, gt_single, lv_buzei.

  LOOP AT lt_po INTO ls_po.

    lv_buzei = lv_buzei + 1.

    CLEAR gs_single.
    gs_single-buzei    = lv_buzei.
    gs_single-ebeln    = ls_po-ebeln.
    gs_single-ebelp    = ls_po-ebelp.
    gs_single-matnr    = ls_po-matnr.
    gs_single-werks    = ls_po-werks.
    gs_single-po_menge = ls_po-menge.
    gs_single-meins    = ls_po-meins.
    gs_single-po_netpr = ls_po-netpr.
    gs_single-iv_netpr = ls_po-netpr.
    gs_single-peinh    = ls_po-peinh.
    gs_single-waers    = ls_head-waers.

*-- 자재명
    SELECT SINGLE maktx INTO gs_single-maktx
      FROM ztc1mm0001
     WHERE matnr = ls_po-matnr.

*-- GR / IR 누적
    PERFORM get_gr_qty USING    ls_po-ebeln ls_po-ebelp CHANGING lv_gr.
    PERFORM get_iv_qty USING    ls_po-ebeln ls_po-ebelp CHANGING lv_iv.

    gs_single-gr_menge = lv_gr.
    gs_single-iv_acc   = lv_iv.

*-- 청구가능
    PERFORM calc_open_qty USING    ls_po-menge lv_gr lv_iv CHANGING lv_open.
    gs_single-open_qty = lv_open.

*-- 기본값
    gs_single-iv_menge = 0.

    IF gs_single-peinh > 0.
      gs_single-po_amt = gs_single-iv_menge * gs_single-po_netpr / gs_single-peinh.
    ELSE.
      gs_single-po_amt = gs_single-iv_menge * gs_single-po_netpr.
    ENDIF.

    gs_single-wrbtr    = gs_single-po_amt.
    gs_single-diff_amt = 0.

*-- 편집 가능 셀 표시 (입고+청구가능 잔량 있을 때만 입력 허용)
    CLEAR gs_single-celltab.

    IF gs_single-gr_menge > 0 AND gs_single-open_qty > 0.
      gs_single-celltab = VALUE #(
        style = cl_gui_alv_grid=>mc_style_enabled
        ( fieldname = 'IV_MENGE' )
        ( fieldname = 'IV_NETPR' )
      ).
    ELSE.
*--   입고 없음 / 청구가능 0 → 입력 잠금 (회색)
      gs_single-celltab = VALUE #(
        style = cl_gui_alv_grid=>mc_style_disabled
        ( fieldname = 'IV_MENGE' )
        ( fieldname = 'IV_NETPR' )
      ).
    ENDIF.

*-- 초기 상태 (입고/청구가능 없으면 조회 시점부터 LOCKED 표시)
    IF gs_single-gr_menge <= 0.
      gs_single-icon = icon_locked.
      gs_single-msg  = '입고 대기'.
    ELSEIF gs_single-open_qty <= 0.
      gs_single-icon = icon_locked.
      gs_single-msg  = '청구 완료'.
    ELSE.
      gs_single-icon = icon_led_inactive.
      gs_single-msg  = '검증 전'.
    ENDIF.

    APPEND gs_single TO gt_single.
  ENDLOOP.

*-- 신규 조회 → 검증상태 초기화
  CLEAR gv_s_verified.

*-- 송장총액 / 헤더 갱신
  PERFORM recalc_single_total.

  gv_s_icon  = icon_led_inactive.
  gv_s_state = '검증 전'.

*-- ALV 갱신
  PERFORM refresh_table USING go_single_alv.

  MESSAGE |PO { gv_s_ebeln } / { lines( gt_single ) }건 품목 조회 완료| TYPE 'S'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_single_changed
*&---------------------------------------------------------------------*
*& 송장수량 / 단가 셀 편집 시 실시간 호출
*&---------------------------------------------------------------------*
FORM handle_single_changed.

  LOOP AT gt_single INTO gs_single.

*-- 금액만 재계산 (검증/상태는 [검증] 버튼에서만 변경)
    PERFORM calc_single_row CHANGING gs_single.

*-- 편집 발생 → 검증상태 초기화 (회색=대상아님 행은 유지)
    IF gs_single-icon <> icon_locked.
      gs_single-icon = icon_led_inactive.
      gs_single-msg  = '검증 전'.
    ENDIF.

    MODIFY gt_single FROM gs_single.

  ENDLOOP.

*-- 검증상태 무효화 → 전기 전 재검증 강제
  CLEAR gv_s_verified.

*-- 송장총액 / Balance 갱신
  PERFORM recalc_single_amount.

*-- 헤더 상태 표시
  gv_s_icon  = icon_led_inactive.
  gv_s_state = '재검증 필요'.

*-- ALV 즉시 refresh
  PERFORM refresh_table USING go_single_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_single_row
*&---------------------------------------------------------------------*
*& 한 행 금액만 재계산 (검증/상태 변경 없음)
*&---------------------------------------------------------------------*
FORM calc_single_row CHANGING ps_row STRUCTURE gs_single.

*-- PO금액 / 송장금액
  IF ps_row-peinh > 0.
    ps_row-po_amt = ps_row-iv_menge * ps_row-po_netpr / ps_row-peinh.
    ps_row-wrbtr  = ps_row-iv_menge * ps_row-iv_netpr / ps_row-peinh.
  ELSE.
    ps_row-po_amt = ps_row-iv_menge * ps_row-po_netpr.
    ps_row-wrbtr  = ps_row-iv_menge * ps_row-iv_netpr.
  ENDIF.

*-- 차액
  ps_row-diff_amt = ps_row-wrbtr - ps_row-po_amt.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form verify_one_row
*&---------------------------------------------------------------------*
*& 한 행 검증 (수량 + 단가 오차율)
*&---------------------------------------------------------------------*
FORM verify_one_row CHANGING ps_row STRUCTURE gs_single.

  DATA : lv_diff_pct TYPE p DECIMALS 4,
         lv_open_txt TYPE char20.

  CLEAR : ps_row-icon, ps_row-msg.

*-- PO금액 / 송장금액 / 차액 재계산
  PERFORM calc_single_row CHANGING ps_row.

*-- 입고 이력이 없으면 이번 송장 대상 아님 (회색)
  IF ps_row-gr_menge <= 0.
    ps_row-icon = icon_locked.
    ps_row-msg  = '입고 대기'.
    RETURN.
  ENDIF.

*-- 청구가능 잔량이 없으면 이번 송장 대상 아님 (회색)
  IF ps_row-open_qty <= 0.
    ps_row-icon = icon_locked.
    ps_row-msg  = '청구 완료'.
    RETURN.
  ENDIF.

*-- 송장수량 0이면 검증대상 아님
  IF ps_row-iv_menge <= 0.
    ps_row-icon = icon_led_red.
    ps_row-msg  = '송장수량 입력 필요'.
    RETURN.
  ENDIF.

*-- (1) 수량 검증
  IF ps_row-iv_menge < 0.
    ps_row-icon = icon_led_red.
    ps_row-msg  = '수량 음수.'.
    RETURN.
  ENDIF.

  IF ps_row-iv_menge > ps_row-open_qty.
    CLEAR lv_open_txt.
    WRITE ps_row-open_qty TO lv_open_txt DECIMALS 0.
    CONDENSE lv_open_txt.

    ps_row-icon = icon_led_red.
    ps_row-msg  = |청구가능({ lv_open_txt } { ps_row-meins }) 초과|.
    RETURN.
  ENDIF.

*-- (2) 금액 검증 (오차율)
  IF ps_row-po_amt <> 0.
    lv_diff_pct = abs( ps_row-diff_amt ) / ps_row-po_amt.
  ENDIF.

  IF lv_diff_pct > gc_tolerance.
    ps_row-icon = icon_led_yellow.
    ps_row-msg  = |단가차이 { lv_diff_pct * 100 }% (보류)|.
    RETURN.
  ENDIF.

*-- (3) 정상
  ps_row-icon = icon_led_green.
  ps_row-msg  = 'OK'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form recalc_single_total
*&---------------------------------------------------------------------*
*& 자동 계산 총액 + Balance 체크
*&---------------------------------------------------------------------*
FORM recalc_single_total .

*-- 금액(총액/Balance) + 전체 검증상태 동시 갱신
  PERFORM recalc_single_amount.
  PERFORM recalc_single_status.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form recalc_single_amount
*&---------------------------------------------------------------------*
*& 송장총액 + Balance 만 재계산 (검증 상태는 변경하지 않음)
*&---------------------------------------------------------------------*
FORM recalc_single_amount .

  DATA : lv_total TYPE ztc1mm0017-rmwwr.

  CLEAR : gv_s_total, gv_s_diff, gv_s_icon_bal, gv_s_bal_txt.

*-- 송장총액 (회색=이번 대상 아님 행 제외)
  LOOP AT gt_single INTO gs_single
    WHERE icon <> icon_locked.
    lv_total = lv_total + gs_single-wrbtr.
  ENDLOOP.

  gv_s_total = lv_total.

*-- Balance 체크 (사용자 입력총액 vs 계산총액)
  IF gv_s_input_total IS NOT INITIAL.
    gv_s_diff = gv_s_input_total - gv_s_total.
    IF abs( gv_s_diff ) < 1.
      gv_s_icon_bal = icon_led_green.
      gv_s_bal_txt  = '일치'.
    ELSE.
      gv_s_icon_bal = icon_led_red.
      gv_s_bal_txt  = '불일치'.
    ENDIF.
  ELSE.
    gv_s_icon_bal = icon_led_inactive.
    gv_s_bal_txt  = '-'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form recalc_single_status
*&---------------------------------------------------------------------*
*& 전체 검증상태(아이콘/텍스트) 재산정 ([검증] 버튼 경로에서만 호출)
*&---------------------------------------------------------------------*
FORM recalc_single_status .

  DATA : lv_red TYPE i,
         lv_yel TYPE i,
         lv_grn TYPE i.

  CLEAR : gv_s_icon, gv_s_state.

  LOOP AT gt_single INTO gs_single
    WHERE icon <> icon_locked.
    CASE gs_single-icon.
      WHEN icon_led_red.    lv_red = lv_red + 1.
      WHEN icon_led_yellow. lv_yel = lv_yel + 1.
      WHEN icon_led_green.  lv_grn = lv_grn + 1.
    ENDCASE.
  ENDLOOP.

*-- 전체 상태
  IF lv_red > 0.
    gv_s_icon  = icon_red_light.
    IF lv_yel > 0.
      gv_s_state = |실패 { lv_red }건 / 보류 { lv_yel }건|.
    ELSE.
      gv_s_state = |실패 { lv_red }건|.
    ENDIF.
  ELSEIF lv_yel > 0.
    gv_s_icon  = icon_yellow_light.
    gv_s_state = |보류 { lv_yel }건|.
  ELSEIF lv_grn > 0.
    gv_s_icon  = icon_green_light.
    gv_s_state = '검증 완료'.
  ELSE.
    gv_s_icon  = icon_led_inactive.
    gv_s_state = '대기'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form verify_single
*&---------------------------------------------------------------------*
FORM verify_single .

  IF gt_single IS INITIAL.
    MESSAGE '조회된 송장 품목이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT gt_single INTO gs_single.
    PERFORM verify_one_row CHANGING gs_single.
    MODIFY gt_single FROM gs_single.
  ENDLOOP.

  PERFORM recalc_single_total.
  PERFORM refresh_table USING go_single_alv.

*-- 검증을 거친 최신 상태임을 표시 (전기 가능 여부는 post_single이 판정)
  gv_s_verified = 'X'.

  MESSAGE '검증 완료' TYPE 'S'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form post_single
*&---------------------------------------------------------------------*
*& 단건 전기 (실패 차단 / 보류 BL / 정상 PS / AP 전표 호출)
*&---------------------------------------------------------------------*
FORM post_single .

  DATA : ls_hdr    TYPE ztc1mm0017,
         ls_itm    TYPE ztc1mm0018,
         ls_ekbe   TYPE ztc1mm0011,
         lt_itm    TYPE TABLE OF ztc1mm0018,
         lt_ekbe   TYPE TABLE OF ztc1mm0011,
         lv_belnr  TYPE ztc1mm0017-belnr,
         lv_gjahr  TYPE ztc1mm0017-gjahr,
         lv_red    TYPE i,
         lv_yel    TYPE i,
         lv_state  TYPE ztc1mm0017-zstate,
         lv_block  TYPE ztc1mm0017-zblock,
         lv_dup    TYPE c,
         lv_dup_be TYPE ztc1mm0017-belnr,
         lv_qty_d  TYPE c,
         lv_prc_d  TYPE c,
         lv_diff   TYPE ztc1mm0017-rmwwr,
         lv_rc       TYPE sy-subrc,
         lv_msg      TYPE char100,
         lv_fi_belnr TYPE ztc1fi0006-belnr,
         lv_answer   TYPE c.

  IF gt_single IS INITIAL.
    MESSAGE '전기할 송장 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 검증 미실행 / 검증 후 수정됨 → 재검증 강제
  IF gv_s_verified IS INITIAL.
    MESSAGE '검증을 먼저 실행하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 재검증 안 된 미검증 행이 남아있으면 차단 (노랑=블로킹 처리 대상)
  LOOP AT gt_single TRANSPORTING NO FIELDS
    WHERE icon = icon_led_inactive.
    MESSAGE '재검증되지 않은 품목이 있습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDLOOP.

*-- 필수 입력
  IF gv_s_xblnr IS INITIAL OR gv_s_bldat IS INITIAL OR gv_s_budat IS INITIAL.
    MESSAGE '외부송장번호 / 송장일자 / 전기일자를 입력하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 실패 / 보류 카운트 (회색=이번 대상 아님 → 제외)
  LOOP AT gt_single INTO gs_single.

    CASE gs_single-icon.
      WHEN icon_led_red.
        lv_red = lv_red + 1.
      WHEN icon_led_yellow.
        lv_yel = lv_yel + 1.
        IF gs_single-iv_menge > gs_single-open_qty.
          lv_qty_d = 'X'.
        ELSE.
          lv_prc_d = 'X'.
        ENDIF.
    ENDCASE.

  ENDLOOP.

*-- 초록/보류 한 건도 없으면 처리 대상 없음
  IF lv_red = 0 AND lv_yel = 0.
*--   모두 회색이면 처리할 게 없음
    READ TABLE gt_single TRANSPORTING NO FIELDS
         WITH KEY icon = icon_led_green.
    IF sy-subrc <> 0.
      MESSAGE '전기처리 대상 품목이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
  ENDIF.

  IF lv_red > 0.
    MESSAGE |검증 실패 { lv_red }건. 전기 불가| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- XBLNR 중복 체크
  PERFORM   check_xblnr_dup USING    gv_s_lifnr gv_s_xblnr
                          CHANGING lv_dup lv_dup_be.
  IF lv_dup = 'X'.
    MESSAGE |이미 처리된 송장: { lv_dup_be }| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- Balance 체크 (입력총액 있을 때만)
  IF gv_s_input_total IS NOT INITIAL.
    lv_diff = gv_s_input_total - gv_s_total.
    IF abs( lv_diff ) >= 1.
      MESSAGE |Balance 불일치. 입력총액 vs 계산총액 차이 { lv_diff }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
  ENDIF.

*-- 전기 확인 (보류 여부 따라 메시지 분기)
  IF lv_yel > 0.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = '[Taesan] 송장 블로킹 처리'
        text_question         = |보류 { lv_yel }건 포함. 블로킹 처리하시겠습니까?|
        text_button_1         = '예'
        icon_button_1         = 'ICON_OKAY'
        text_button_2         = '아니오'
        icon_button_2         = 'ICON_CANCEL'
        default_button        = '2'
        display_cancel_button = ' '
      IMPORTING
        answer                = lv_answer.
  ELSE.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = '[Taesan] 송장 전기'
        text_question         = '송장을 전기하시겠습니까?'
        text_button_1         = '예'
        icon_button_1         = 'ICON_OKAY'
        text_button_2         = '아니오'
        icon_button_2         = 'ICON_CANCEL'
        default_button        = '1'
        display_cancel_button = ' '
      IMPORTING
        answer                = lv_answer.
  ENDIF.

  IF lv_answer <> '1'.
    RETURN.
  ENDIF.

*-- ZSTATE / ZBLOCK 결정
  PERFORM determine_iv_state USING    lv_yel lv_qty_d lv_prc_d
                             CHANGING lv_state lv_block.

*-- BELNR 채번
  PERFORM number_get_belnr CHANGING lv_belnr.
  IF lv_belnr IS INITIAL.
    MESSAGE 'IV 송장번호 채번 실패' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gv_s_budat IS INITIAL.
    lv_gjahr = sy-datum(4).
  ELSE.
    lv_gjahr = gv_s_budat(4).
  ENDIF.

*-- 헤더
  CLEAR ls_hdr.
  ls_hdr-mandt  = sy-mandt.
  ls_hdr-belnr  = lv_belnr.
  ls_hdr-gjahr  = lv_gjahr.
  ls_hdr-bukrs  = '1000'. " 추후 바뀔거같음
  ls_hdr-blart  = 'RE'.
  ls_hdr-lifnr  = gv_s_lifnr.
  ls_hdr-xblnr  = gv_s_xblnr.
  ls_hdr-bldat  = gv_s_bldat.
  ls_hdr-budat  = gv_s_budat.
  ls_hdr-waers  = gv_s_waers.
  ls_hdr-rmwwr  = gv_s_total.
  ls_hdr-zblock = lv_block.
  ls_hdr-zstate = lv_state.
  ls_hdr-erdat  = sy-datum.
  ls_hdr-erzet  = sy-uzeit.
  ls_hdr-ernam  = sy-uname.

*-- 아이템 + EKBE
  LOOP AT gt_single INTO gs_single
    WHERE icon = icon_led_green
       OR icon = icon_led_yellow.

    CLEAR ls_itm.
    ls_itm-mandt = sy-mandt.
    ls_itm-belnr = lv_belnr.
    ls_itm-gjahr = lv_gjahr.
    ls_itm-buzei = gs_single-buzei.
    ls_itm-ebeln = gs_single-ebeln.
    ls_itm-ebelp = gs_single-ebelp.
    ls_itm-matnr = gs_single-matnr.
    ls_itm-werks = gs_single-werks.
    ls_itm-menge = gs_single-iv_menge.
    ls_itm-meins = gs_single-meins.
    ls_itm-netpr = gs_single-iv_netpr.
    ls_itm-peinh = gs_single-peinh.
    ls_itm-wrbtr = gs_single-wrbtr.
    ls_itm-dmbtr = gs_single-wrbtr.
    ls_itm-waers = gs_single-waers.
    ls_itm-erdat = sy-datum.
    ls_itm-erzet = sy-uzeit.
    ls_itm-ernam = sy-uname.
    APPEND ls_itm TO lt_itm.

*-- EKBE (VGABE=2 IR 이력)
    CLEAR ls_ekbe.
    ls_ekbe-mandt = sy-mandt.
    ls_ekbe-ebeln = gs_single-ebeln.
    ls_ekbe-ebelp = gs_single-ebelp.
    ls_ekbe-zekkn = '01'.
    ls_ekbe-vgabe = gc_vgabe_ir.
    ls_ekbe-belnr = lv_belnr.
    ls_ekbe-gjahr = lv_gjahr.
    ls_ekbe-buzei = gs_single-buzei.
    ls_ekbe-budat = gv_s_budat.
    ls_ekbe-cpudt = sy-datum.
    ls_ekbe-cputm = sy-uzeit.
    ls_ekbe-menge = gs_single-iv_menge.
    ls_ekbe-dmbtr = gs_single-wrbtr.
    ls_ekbe-waers = gv_s_waers.
    ls_ekbe-shkzg = 'H'.
    ls_ekbe-werks = gs_single-werks.
    ls_ekbe-xblnr = gv_s_xblnr.
    ls_ekbe-statu = 'IV'.
    ls_ekbe-aedat = sy-datum.
    APPEND ls_ekbe TO lt_ekbe.

  ENDLOOP.

*-- IV 문서 생성
  INSERT ztc1mm0017 FROM ls_hdr.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'IV 헤더 생성 실패' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  INSERT ztc1mm0018 FROM TABLE lt_itm.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'IV 아이템 생성 실패' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  INSERT ztc1mm0011 FROM TABLE lt_ekbe.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'IV 구매이력 생성 실패' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- AP 전표 함수 호출은 정상 송장(PS)만. 보류(BL) 송장은 FI 전표 미생성
*-- 보류 송장은 IV 문서로 생성되나, 단가/수량 확인 후 별도 릴리스 필요
  IF lv_state = gc_state_ps.

    CLEAR lv_fi_belnr.

    PERFORM call_ap_voucher USING    ls_hdr lt_itm
                            CHANGING lv_rc lv_msg lv_fi_belnr.
    IF lv_rc <> 0.
      ROLLBACK WORK.
      MESSAGE |FI AP 전표 생성 실패: { lv_msg }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

  ENDIF.

  COMMIT WORK AND WAIT.

  IF lv_state = gc_state_bl.
    MESSAGE |송장 { lv_belnr } 블로킹 처리 완료. 단가/수량 확인 필요.| TYPE 'S' DISPLAY LIKE 'W'.
  ELSE.
    MESSAGE |FI 전표 { lv_fi_belnr } 전기 완료 (송장 { lv_belnr })| TYPE 'S'.
  ENDIF.

  PERFORM clear_single.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form clear_single
*&---------------------------------------------------------------------*
FORM clear_single .

  CLEAR : gs_single, gt_single,
          gv_s_ebeln, gv_s_xblnr, gv_s_lifnr, gv_s_name1,
          gv_s_bldat, gv_s_budat, gv_s_waers,
          gv_s_input_total, gv_s_total,
          gv_s_icon, gv_s_state,
          gv_s_icon_bal, gv_s_bal_txt,
          gv_s_verified.

  IF go_single_alv IS BOUND.
    PERFORM refresh_table USING go_single_alv.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form download_template
*&---------------------------------------------------------------------*
*& SMW0 등록 엑셀 양식 다운로드 (Z_IV_TEMPLATE)
*&---------------------------------------------------------------------*
FORM download_template .

  DATA : ls_wwwdata  TYPE wwwdatatab,
         lv_objid    TYPE wwwdatatab-objid,
         lv_filename TYPE string,
         lv_path     TYPE string,
         lv_fullpath TYPE string,
         lv_action   TYPE i,
         lv_destin   TYPE rlgrap-filename.

*-- SMW0 등록 여부 확인 (키 필드만 조회)
  SELECT SINGLE objid INTO lv_objid
    FROM wwwdata
   WHERE relid = 'MI'
     AND objid = 'Z_IV_TEMPLATE'.

  IF sy-subrc <> 0.
    MESSAGE 'SMW0에 Z_IV_TEMPLATE이 등록되지 않았습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- KEY 파라미터 구성
  ls_wwwdata-relid = 'MI'.
  ls_wwwdata-objid = 'Z_IV_TEMPLATE'.

*-- 저장 위치 선택
  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      default_file_name = 'IV_Upload_Template.xlsx'
      default_extension = 'xlsx'
    CHANGING
      filename          = lv_filename
      path              = lv_path
      fullpath          = lv_fullpath
      user_action       = lv_action.

  IF lv_action <> cl_gui_frontend_services=>action_ok.
    RETURN.
  ENDIF.

  lv_destin = lv_fullpath.

*-- SMW0 → 로컬 파일로 직접 다운로드
  CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
    EXPORTING
      key         = ls_wwwdata
      destination = lv_destin.

  IF sy-subrc = 0.
    MESSAGE '엑셀 양식 다운로드 완료' TYPE 'S'.
  ELSE.
    MESSAGE '엑셀 양식 다운로드 실패' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form upload_mass_excel
*&---------------------------------------------------------------------*
*& 다중 엑셀 파일 업로드 + 자동 매칭/검증
*&---------------------------------------------------------------------*
FORM upload_mass_excel .

  DATA : lt_files  TYPE filetable,
         ls_file   TYPE file_table,
         lv_rc     TYPE i,
         lv_action TYPE i,
         lt_raw    TYPE TABLE OF alsmex_tabline.

  DATA : lv_filename TYPE rlgrap-filename.

*-- 다중 파일 선택
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title   = '송장 엑셀 파일 선택 (다중 가능)'
      file_filter    = '*.xlsx;*.xls'
      multiselection = 'X'
    CHANGING
      file_table     = lt_files
      rc             = lv_rc
      user_action    = lv_action.

  IF lv_action <> cl_gui_frontend_services=>action_ok.
    RETURN.
  ENDIF.

  gv_m_files_cnt = lines( lt_files ).

  CLEAR : gs_excel, gt_excel.

*-- 파일별 반복
  LOOP AT lt_files INTO ls_file.

    CLEAR : lt_raw, lv_filename.

    lv_filename = ls_file-filename.

    CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
      EXPORTING
        filename                = lv_filename
        i_begin_col             = 1
        i_begin_row             = 2
        i_end_col               = 8
        i_end_row               = 9999
      TABLES
        intern                  = lt_raw
      EXCEPTIONS
        inconsistent_parameters = 1
        upload_ole              = 2
        OTHERS                  = 3.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    PERFORM convert_excel_to_internal USING lt_raw.

  ENDLOOP.

  IF gt_excel IS INITIAL.
    MESSAGE '엑셀에 유효한 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 업로드만 수행. 검증은 [검증] 버튼에서 수행
  CLEAR : gs_mass, gt_mass,
          gv_m_pass, gv_m_fail, gv_m_skip, gv_m_total.

  LOOP AT gt_excel INTO gs_excel.
    CLEAR gs_mass.

    gs_mass-xblnr    = gs_excel-xblnr.
    gs_mass-lifnr    = gs_excel-lifnr.
    gs_mass-bldat    = gs_excel-bldat.
    gs_mass-budat    = gs_excel-budat.
    gs_mass-ebeln    = gs_excel-ebeln.
    gs_mass-ebelp    = gs_excel-ebelp.
    gs_mass-iv_menge = gs_excel-menge.
    gs_mass-wrbtr    = gs_excel-wrbtr.
    gs_mass-waers    = 'KRW'.
    gs_mass-icon     = icon_led_inactive.
    gs_mass-status   = 'READY'.
    gs_mass-msg      = '검증 전'.

    APPEND gs_mass TO gt_mass.
  ENDLOOP.

  gv_m_total = lines( gt_mass ).

  IF go_mass_alv IS BOUND.
    PERFORM refresh_table USING go_mass_alv.
  ENDIF.

  MESSAGE |{ gv_m_files_cnt }개 파일 / { gv_m_total }건 업로드 완료. 검증 버튼을 누르세요.| TYPE 'S'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form convert_excel_to_internal
*&---------------------------------------------------------------------*
FORM convert_excel_to_internal USING pt_raw TYPE STANDARD TABLE.

  DATA : ls_raw      TYPE alsmex_tabline,
         lv_prev_row TYPE i VALUE 0,
         ls_excel    LIKE gs_excel.

  LOOP AT pt_raw INTO ls_raw.

    IF lv_prev_row <> 0 AND lv_prev_row <> ls_raw-row.

      IF ls_excel-xblnr IS NOT INITIAL
     AND ls_excel-lifnr IS NOT INITIAL
     AND ls_excel-ebeln IS NOT INITIAL
     AND ls_excel-ebelp IS NOT INITIAL.
        APPEND ls_excel TO gt_excel.
      ENDIF.

      CLEAR ls_excel.
    ENDIF.

    lv_prev_row = ls_raw-row.

    CASE ls_raw-col.
      WHEN 1.
        ls_excel-xblnr = ls_raw-value.
      WHEN 2.
        ls_excel-lifnr = ls_raw-value.
      WHEN 3.
        PERFORM convert_date_string USING ls_raw-value CHANGING ls_excel-bldat.
      WHEN 4.
        PERFORM convert_date_string USING ls_raw-value CHANGING ls_excel-budat.
      WHEN 5.
        ls_excel-ebeln = ls_raw-value.
      WHEN 6.
        ls_excel-ebelp = ls_raw-value.
      WHEN 7.
        IF ls_raw-value CO '0123456789., '.
          REPLACE ALL OCCURRENCES OF ',' IN ls_raw-value WITH ''.
          CONDENSE ls_raw-value NO-GAPS.
          ls_excel-menge = ls_raw-value.
        ENDIF.
      WHEN 8.
        IF ls_raw-value CO '0123456789., '.
          REPLACE ALL OCCURRENCES OF ',' IN ls_raw-value WITH ''.
          CONDENSE ls_raw-value NO-GAPS.

          CALL FUNCTION 'CURRENCY_AMOUNT_IDOC_TO_SAP'
            EXPORTING
              currency    = 'KRW'
              idoc_amount = ls_raw-value
            IMPORTING
              sap_amount  = ls_excel-wrbtr.
        ENDIF.
    ENDCASE.

  ENDLOOP.

  IF ls_excel-xblnr IS NOT INITIAL
 AND ls_excel-lifnr IS NOT INITIAL
 AND ls_excel-ebeln IS NOT INITIAL
 AND ls_excel-ebelp IS NOT INITIAL.
    APPEND ls_excel TO gt_excel.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form verify_mass
*&---------------------------------------------------------------------*
*& 대량 자동 매칭 + 검증 (PO/벤더/수량/금액/중복)
*&---------------------------------------------------------------------*
FORM verify_mass .

  DATA : ls_po       TYPE ztc1mm0008,
         ls_head     TYPE ztc1mm0007,
         lv_gr       TYPE ztc1mm0008-menge,
         lv_iv       TYPE ztc1mm0008-menge,
         lv_open     TYPE ztc1mm0008-menge,
         lv_open_txt TYPE char20,
         lv_diff_pct TYPE p DECIMALS 4,
         lv_dup      TYPE c,
         lv_dup_be   TYPE ztc1mm0017-belnr.

  IF gt_excel IS INITIAL.
    MESSAGE '엑셀을 먼저 업로드하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CLEAR : gs_mass, gt_mass.
  CLEAR : gv_m_pass, gv_m_fail, gv_m_skip, gv_m_total.

  LOOP AT gt_excel INTO gs_excel.

    CLEAR : gs_mass, ls_po, ls_head,
            lv_gr, lv_iv, lv_open, lv_diff_pct,
            lv_dup, lv_dup_be.

*-- 엑셀 원본값 세팅
    gs_mass-xblnr    = gs_excel-xblnr.
    gs_mass-lifnr    = gs_excel-lifnr.
    gs_mass-bldat    = gs_excel-bldat.
    gs_mass-budat    = gs_excel-budat.
    gs_mass-ebeln    = gs_excel-ebeln.
    gs_mass-ebelp    = gs_excel-ebelp.
    gs_mass-matnr    = gs_excel-matnr.
    gs_mass-iv_menge = gs_excel-menge.
    gs_mass-meins    = gs_excel-meins.
    gs_mass-iv_netpr = gs_excel-netpr.
    gs_mass-peinh    = gs_excel-peinh.
    gs_mass-wrbtr    = gs_excel-wrbtr.
    gs_mass-waers    = 'KRW'.

*-- 필수값 체크 (외부송장번호 / 벤더 / 일자 / PO / 청구금액)
    IF gs_excel-xblnr IS INITIAL OR
       gs_excel-lifnr IS INITIAL OR
       gs_excel-bldat IS INITIAL OR
       gs_excel-budat IS INITIAL OR
       gs_excel-ebeln IS INITIAL OR
       gs_excel-ebelp IS INITIAL OR
       gs_excel-wrbtr IS INITIAL.

      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'MISS'.
      gs_mass-msg    = '필수값 누락'.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

*-- 송장일자 유효성 체크
    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gs_excel-bldat
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.

    IF sy-subrc <> 0.
      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'DATE'.
      gs_mass-msg    = '송장일자 오류'.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

*-- 전기일자 유효성 체크
    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gs_excel-budat
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.

    IF sy-subrc <> 0.
      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'DATE'.
      gs_mass-msg    = '전기일자 오류'.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

*-- 엑셀 파일 내 중복 품목 체크 (DB 반영 전 이중청구 방지)
    READ TABLE gt_mass TRANSPORTING NO FIELDS
      WITH KEY lifnr = gs_excel-lifnr
               xblnr = gs_excel-xblnr
               ebeln = gs_excel-ebeln
               ebelp = gs_excel-ebelp.

    IF sy-subrc = 0.
      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'DUPFILE'.
      gs_mass-msg    = '엑셀 내 중복 품목'.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

*-- 벤더명
    SELECT SINGLE name1
      INTO gs_mass-name1
      FROM ztc1mm0012
     WHERE lifnr = gs_excel-lifnr.

*-- 외부송장번호 + PO품목 단위 중복 체크
    PERFORM check_iv_item_dup USING    gs_excel-lifnr
                                       gs_excel-xblnr
                                       gs_excel-ebeln
                                       gs_excel-ebelp
                              CHANGING lv_dup
                                       lv_dup_be.

    IF lv_dup = 'X'.
      gs_mass-icon   = icon_locked.
      gs_mass-status = 'DUP'.
      gs_mass-msg    = |이미 처리된 송장 품목: { lv_dup_be }|.
      gv_m_skip = gv_m_skip + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

*-- PO 품목 조회
    SELECT SINGLE *
      INTO ls_po
      FROM ztc1mm0008
     WHERE ebeln = gs_excel-ebeln
       AND ebelp = gs_excel-ebelp
       AND loekz = ''
       AND repos = 'X'.

    IF sy-subrc <> 0.
      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'PO'.
      gs_mass-msg    = 'IV 대상 PO 품목 없음'.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

    gs_mass-matnr    = ls_po-matnr.
    gs_mass-werks    = ls_po-werks.
    gs_mass-po_menge = ls_po-menge.
    gs_mass-po_netpr = ls_po-netpr.
    gs_mass-meins    = ls_po-meins.
    gs_mass-peinh    = ls_po-peinh.

*-- 자재명 (PO 품목에서 확정된 자재번호 기준 조회)
    SELECT SINGLE maktx
      INTO gs_mass-maktx
      FROM ztc1mm0001
     WHERE matnr = ls_po-matnr.

*-- PO 헤더 조회
    SELECT SINGLE *
      INTO ls_head
      FROM ztc1mm0007
     WHERE ebeln = gs_excel-ebeln
       AND loekz = ''.

    IF sy-subrc <> 0.
      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'PO'.
      gs_mass-msg    = 'PO 헤더 없음'.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

    gs_mass-waers = ls_head-waers.

*-- PO 승인상태 체크
    IF ls_head-statu <> 'AP'.
      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'AP'.
      gs_mass-msg    = '승인 완료 PO가 아님'.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

*-- 벤더 일치 체크
    IF ls_head-lifnr <> gs_excel-lifnr.
      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'REF'.
      gs_mass-msg    = '벤더가 PO와 일치하지 않음'.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

*-- GR / IR 누적
    PERFORM get_gr_qty USING    gs_excel-ebeln
                                gs_excel-ebelp
                       CHANGING lv_gr.

    PERFORM get_iv_qty USING    gs_excel-ebeln
                                gs_excel-ebelp
                       CHANGING lv_iv.

    gs_mass-gr_menge = lv_gr.
    gs_mass-iv_acc   = lv_iv.

*-- GR 없음
    IF lv_gr <= 0.
      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'NOGR'.
      gs_mass-msg    = '입고 이력 없음'.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

*-- 청구가능 계산
    PERFORM calc_open_qty USING    ls_po-menge
                                   lv_gr
                                   lv_iv
                          CHANGING lv_open.

    gs_mass-open_qty = lv_open.

    IF lv_open <= 0.
      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'CLOSED'.
      gs_mass-msg    = '청구가능 수량 없음'.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

*-- 수량 검증
    IF gs_excel-menge <= 0.
      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'QTY'.
      gs_mass-msg    = '송장수량 입력 오류'.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

    IF gs_excel-menge > lv_open.
      CLEAR lv_open_txt.
      WRITE lv_open TO lv_open_txt DECIMALS 0.
      CONDENSE lv_open_txt.

      gs_mass-icon   = icon_led_red.
      gs_mass-status = 'QTY'.
      gs_mass-msg    = |청구가능({ lv_open_txt } { gs_mass-meins }) 초과|.
      gv_m_fail = gv_m_fail + 1.
      APPEND gs_mass TO gt_mass.
      CONTINUE.
    ENDIF.

*-- PO 기준금액
    IF ls_po-peinh > 0.
      gs_mass-po_amt = gs_excel-menge * ls_po-netpr / ls_po-peinh.
    ELSE.
      gs_mass-po_amt = gs_excel-menge * ls_po-netpr.
    ENDIF.

    gs_mass-diff_amt = gs_excel-wrbtr - gs_mass-po_amt.

*-- 송장단가 역산 (엑셀에 단가 칸이 없으므로 청구금액 / 수량으로 산출)
*-- 수량 검증을 통과한 시점이라 gs_excel-menge > 0 보장됨
    IF ls_po-peinh > 0.
      gs_mass-iv_netpr = gs_excel-wrbtr * ls_po-peinh / gs_excel-menge.
    ELSE.
      gs_mass-iv_netpr = gs_excel-wrbtr / gs_excel-menge.
    ENDIF.

*-- 금액 검증
    IF gs_mass-po_amt <> 0.
      lv_diff_pct = abs( gs_mass-diff_amt ) / gs_mass-po_amt.
    ENDIF.

    IF lv_diff_pct > gc_tolerance.
      gs_mass-icon   = icon_led_yellow.
      gs_mass-status = 'PRICE'.
      gs_mass-msg = |단가 차이 { lv_diff_pct * 100 }% - 전기 제외|.
      gv_m_fail = gv_m_fail + 1.
    ELSE.
      gs_mass-icon   = icon_led_green.
      gs_mass-status = 'OK'.
      gs_mass-msg    = 'OK'.
      gv_m_pass = gv_m_pass + 1.
    ENDIF.

    APPEND gs_mass TO gt_mass.

  ENDLOOP.

  gv_m_total = lines( gt_mass ).

*-- 송장(LIFNR + XBLNR) 단위 통합 검증 (오류/전기 제외 품목 포함 송장 전체 전기 제외)
  PERFORM rollup_mass_invoice.

*-- 전기예정금액 산정 (ALV 합계가 실제 전기금액과 일치하도록)
  PERFORM set_post_amount.

  IF go_mass_alv IS BOUND.
    PERFORM refresh_table USING go_mass_alv.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form rollup_mass_invoice
*&---------------------------------------------------------------------*
*& 송장(LIFNR + XBLNR) 단위 통합 검증
*&  - 송장 내 품목이 전부 OK  → 전기 가능
*&  - 한 품목이라도 오류/전기 제외 → 송장 전체 전기 제외 (BLOCK = 'X')
*&---------------------------------------------------------------------*
FORM rollup_mass_invoice .

  DATA : lv_ng    TYPE c,
         lv_index TYPE i.

  LOOP AT gt_mass INTO gs_mass.

    lv_index = sy-tabix.

*-- 동일 송장(LIFNR + XBLNR) 그룹에 오류/전기 제외 품목이 있는지 확인
    CLEAR lv_ng.
    LOOP AT gt_mass TRANSPORTING NO FIELDS
         WHERE lifnr  = gs_mass-lifnr
           AND xblnr  = gs_mass-xblnr
           AND status <> 'OK'.
      lv_ng = 'X'.
      EXIT.
    ENDLOOP.

*-- 전기 제외 송장이면 현재 행에 BLOCK 표시
    IF lv_ng = 'X'.
      gs_mass-block = 'X'.

*--   품목 자체는 정상이지만 동일 송장 내 오류로 전기 불가
      IF gs_mass-status = 'OK'.
       gs_mass-msg = '송장 내 오류 품목 존재 - 전기 제외'.
      ENDIF.

      MODIFY gt_mass FROM gs_mass INDEX lv_index.
    ENDIF.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_post_amount
*&---------------------------------------------------------------------*
*& 전기예정금액(POST_AMT) 산정
*&  - 실제 전기 대상(검증 OK + 송장 전기 제외 아님) 행만 청구금액 반영
*&  - 실패 / 중복 / 전기 제외 행은 0  → ALV 합계 = 실제 전기될 금액
*&  - 송장청구금액(WRBTR)은 모든 행에 원본 유지 (화면 표시용)
*&---------------------------------------------------------------------*
FORM set_post_amount .

  LOOP AT gt_mass INTO gs_mass.

    IF gs_mass-status = 'OK' AND gs_mass-block = ''.
      gs_mass-post_amt = gs_mass-wrbtr.
    ELSE.
      CLEAR gs_mass-post_amt.
    ENDIF.

    MODIFY gt_mass FROM gs_mass.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form post_mass
*&---------------------------------------------------------------------*
*& 대량 전기 (송장 LIFNR+XBLNR 단위, 송장 전체가 OK인 건만)
*&---------------------------------------------------------------------*
FORM post_mass .

  DATA : ls_hdr      TYPE ztc1mm0017,
         ls_itm      TYPE ztc1mm0018,
         ls_ekbe     TYPE ztc1mm0011,
         lt_itm      TYPE TABLE OF ztc1mm0018,
         lt_ekbe     TYPE TABLE OF ztc1mm0011,
         lv_belnr    TYPE ztc1mm0017-belnr,
         lv_gjahr    TYPE ztc1mm0017-gjahr,
         lv_buzei    TYPE n LENGTH 3,
         lv_total    TYPE ztc1mm0017-rmwwr,
         lv_save_cnt TYPE i,
         lv_rc       TYPE sy-subrc,
         lv_msg      TYPE char100,
         lv_fi_belnr TYPE ztc1fi0006-belnr,
         lv_answer   TYPE c.

  DATA : lv_cur_lifnr TYPE ztc1mm0017-lifnr,
         lv_cur_xblnr TYPE ztc1mm0017-xblnr.

*-- 전기 가능 송장 카운트용
  DATA : lv_ok_inv  TYPE i,
         lv_prv_lif TYPE ztc1mm0017-lifnr,
         lv_prv_xbl TYPE ztc1mm0017-xblnr.

  IF gt_mass IS INITIAL.
    MESSAGE '전기할 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 송장(LIFNR + XBLNR) 단위로 묶기 위해 정렬
  SORT gt_mass BY lifnr xblnr ebeln ebelp.

*-- 전기 가능 송장 수 = 품목 전체 OK + 전기 제외 아님 그룹의 송장 개수
  CLEAR : lv_ok_inv, lv_prv_lif, lv_prv_xbl.

  LOOP AT gt_mass INTO gs_mass WHERE status = 'OK'
                                 AND block  = ''.
    IF gs_mass-lifnr <> lv_prv_lif OR gs_mass-xblnr <> lv_prv_xbl.
      lv_ok_inv  = lv_ok_inv + 1.
      lv_prv_lif = gs_mass-lifnr.
      lv_prv_xbl = gs_mass-xblnr.
    ENDIF.
  ENDLOOP.

  IF lv_ok_inv = 0.
    MESSAGE '전기 가능한 송장이 없습니다. (검증을 먼저 실행하세요)'
            TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 전기 확인
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '[Taesan] 대량 송장 전기'
      text_question         = |전기 가능 송장 { lv_ok_inv }건을 전기하시겠습니까?|
      text_button_1         = '예'
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = '아니오'
      icon_button_2         = 'ICON_CANCEL'
      default_button        = '1'
      display_cancel_button = ' '
    IMPORTING
      answer                = lv_answer.

  IF lv_answer <> '1'.
    RETURN.
  ENDIF.

  CLEAR : lv_cur_lifnr, lv_cur_xblnr.

*-- 송장 전체가 OK인(전기 제외 아닌) 품목만 LIFNR + XBLNR 단위로 전기 처리
  LOOP AT gt_mass INTO gs_mass WHERE status = 'OK'
                                 AND block  = ''.

*-- 새 송장 시작 조건 (LIFNR 또는 XBLNR 변경)
    IF gs_mass-lifnr <> lv_cur_lifnr OR gs_mass-xblnr <> lv_cur_xblnr.

*--   직전 송장 IV/FI 전기 처리
      IF lv_cur_xblnr IS NOT INITIAL.

        ls_hdr-rmwwr = lv_total.
        INSERT ztc1mm0017 FROM ls_hdr.
        IF sy-subrc <> 0.
          ROLLBACK WORK.
          MESSAGE 'IV 헤더 생성 실패' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        INSERT ztc1mm0018 FROM TABLE lt_itm.
        IF sy-subrc <> 0.
          ROLLBACK WORK.
          MESSAGE 'IV 아이템 생성 실패' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        INSERT ztc1mm0011 FROM TABLE lt_ekbe.
        IF sy-subrc <> 0.
          ROLLBACK WORK.
          MESSAGE 'IV 구매이력 생성 실패' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

*--     AP 전표 호출
        CLEAR lv_fi_belnr.

        PERFORM call_ap_voucher USING    ls_hdr lt_itm
                                CHANGING lv_rc lv_msg lv_fi_belnr.
        IF lv_rc <> 0.
          ROLLBACK WORK.
          MESSAGE |FI AP 전표 생성 실패: { lv_msg }| TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        lv_save_cnt = lv_save_cnt + 1.
        CLEAR : ls_hdr, lt_itm, lt_ekbe, lv_total, lv_buzei.
      ENDIF.

*--   신규 송장 헤더
      PERFORM number_get_belnr CHANGING lv_belnr.

      IF gs_mass-budat IS INITIAL.
        lv_gjahr = sy-datum(4).
      ELSE.
        lv_gjahr = gs_mass-budat(4).
      ENDIF.

      CLEAR ls_hdr.
      ls_hdr-mandt  = sy-mandt.
      ls_hdr-belnr  = lv_belnr.
      ls_hdr-gjahr  = lv_gjahr.
      ls_hdr-bukrs  = '1000'.
      ls_hdr-blart  = 'RE'.
      ls_hdr-lifnr  = gs_mass-lifnr.
      ls_hdr-xblnr  = gs_mass-xblnr.
      ls_hdr-bldat  = gs_mass-bldat.
      ls_hdr-budat  = gs_mass-budat.
      ls_hdr-waers  = gs_mass-waers.
      ls_hdr-zblock = ''.
      ls_hdr-zstate = gc_state_ps.
      ls_hdr-erdat  = sy-datum.
      ls_hdr-erzet  = sy-uzeit.
      ls_hdr-ernam  = sy-uname.

      lv_cur_lifnr = gs_mass-lifnr.
      lv_cur_xblnr = gs_mass-xblnr.
    ENDIF.

*-- 송장 아이템
    lv_buzei = lv_buzei + 1.

    CLEAR ls_itm.
    ls_itm-mandt = sy-mandt.
    ls_itm-belnr = ls_hdr-belnr.
    ls_itm-gjahr = ls_hdr-gjahr.
    ls_itm-buzei = lv_buzei.
    ls_itm-ebeln = gs_mass-ebeln.
    ls_itm-ebelp = gs_mass-ebelp.
    ls_itm-matnr = gs_mass-matnr.
    ls_itm-werks = gs_mass-werks.
    ls_itm-menge = gs_mass-iv_menge.
    ls_itm-meins = gs_mass-meins.
    ls_itm-netpr = gs_mass-iv_netpr.
    ls_itm-peinh = gs_mass-peinh.
    ls_itm-wrbtr = gs_mass-wrbtr.
    ls_itm-dmbtr = gs_mass-wrbtr.
    ls_itm-waers = gs_mass-waers.
    ls_itm-erdat = sy-datum.
    ls_itm-erzet = sy-uzeit.
    ls_itm-ernam = sy-uname.
    APPEND ls_itm TO lt_itm.

*-- EKBE
    CLEAR ls_ekbe.
    ls_ekbe-mandt = sy-mandt.
    ls_ekbe-ebeln = gs_mass-ebeln.
    ls_ekbe-ebelp = gs_mass-ebelp.
    ls_ekbe-zekkn = '01'.
    ls_ekbe-vgabe = gc_vgabe_ir.
    ls_ekbe-belnr = ls_hdr-belnr.
    ls_ekbe-gjahr = ls_hdr-gjahr.
    ls_ekbe-buzei = lv_buzei.
    ls_ekbe-budat = ls_hdr-budat.
    ls_ekbe-cpudt = sy-datum.
    ls_ekbe-cputm = sy-uzeit.
    ls_ekbe-menge = gs_mass-iv_menge.
    ls_ekbe-dmbtr = gs_mass-wrbtr.
    ls_ekbe-waers = gs_mass-waers.
    ls_ekbe-shkzg = 'H'.
    ls_ekbe-werks = gs_mass-werks.
    ls_ekbe-xblnr = gs_mass-xblnr.
*    ls_ekbe-lifnr = gs_mass-lifnr.
    ls_ekbe-statu = 'IV'.
    ls_ekbe-aedat = sy-datum.
    APPEND ls_ekbe TO lt_ekbe.

    lv_total = lv_total + gs_mass-wrbtr.

  ENDLOOP.

*-- 마지막 송장 IV/FI 전기 처리
  IF lv_cur_xblnr IS NOT INITIAL.

    ls_hdr-rmwwr = lv_total.
    INSERT ztc1mm0017 FROM ls_hdr.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE 'IV 헤더 생성 실패' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    INSERT ztc1mm0018 FROM TABLE lt_itm.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE 'IV 아이템 생성 실패' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    INSERT ztc1mm0011 FROM TABLE lt_ekbe.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE 'IV 구매이력 생성 실패' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CLEAR lv_fi_belnr.

    PERFORM call_ap_voucher USING    ls_hdr lt_itm
                            CHANGING lv_rc lv_msg lv_fi_belnr.
    IF lv_rc <> 0.
      ROLLBACK WORK.
      MESSAGE |FI AP 전표 생성 실패: { lv_msg }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    lv_save_cnt = lv_save_cnt + 1.
  ENDIF.

  COMMIT WORK AND WAIT.

  MESSAGE |FI AP 전표 { lv_save_cnt }건 전기 완료| TYPE 'S'.

  PERFORM clear_mass.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form clear_mass
*&---------------------------------------------------------------------*
FORM clear_mass .

  CLEAR : gs_excel, gt_excel, gs_mass, gt_mass,
          gv_m_files_cnt, gv_m_pass, gv_m_fail, gv_m_skip, gv_m_total.

  IF go_mass_alv IS BOUND.
    PERFORM refresh_table USING go_mass_alv.
  ENDIF.

  CLEAR gv_okcode.
  CLEAR gv_save_ok.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_bldat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_bldat .

  CALL FUNCTION 'F4_DATE'
    IMPORTING
      select_date = gv_s_bldat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_budat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_budat .

  CALL FUNCTION 'F4_DATE'
    IMPORTING
      select_date = gv_s_budat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_iv_item_dup
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_EXCEL_LIFNR
*&      --> GS_EXCEL_XBLNR
*&      --> GS_EXCEL_EBELN
*&      --> GS_EXCEL_EBELP
*&      <-- LV_DUP
*&      <-- LV_DUP_BE
*&---------------------------------------------------------------------*
FORM check_iv_item_dup USING    pv_lifnr TYPE ztc1mm0012-lifnr
                                pv_xblnr TYPE ztc1mm0017-xblnr
                                pv_ebeln TYPE ztc1mm0008-ebeln
                                pv_ebelp TYPE ztc1mm0008-ebelp
                       CHANGING cv_dup   TYPE c
                                cv_belnr TYPE ztc1mm0017-belnr.

  CLEAR : cv_dup, cv_belnr.

  CHECK pv_lifnr IS NOT INITIAL
    AND pv_xblnr IS NOT INITIAL
    AND pv_ebeln IS NOT INITIAL
    AND pv_ebelp IS NOT INITIAL.

  SELECT SINGLE h~belnr
    INTO cv_belnr
    FROM ztc1mm0017 AS h
   INNER JOIN ztc1mm0018 AS i
      ON h~belnr = i~belnr
     AND h~gjahr = i~gjahr
   WHERE h~lifnr = pv_lifnr
     AND h~xblnr = pv_xblnr
     AND i~ebeln = pv_ebeln
     AND i~ebelp = pv_ebelp.

  IF sy-subrc = 0.
    cv_dup = 'X'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_toolbar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM handle_toolbar  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

*-- 표준 버튼 제거
  CLEAR po_object->mt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_help_ebeln
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f4_help_ebeln .

  DATA : lt_head   TYPE TABLE OF ztc1mm0007,
         ls_head   TYPE ztc1mm0007,
         lt_item   TYPE TABLE OF ztc1mm0008,
         ls_item   TYPE ztc1mm0008,
         lv_gr     TYPE ztc1mm0008-menge,
         lv_iv     TYPE ztc1mm0008-menge,
         lv_open   TYPE ztc1mm0008-menge,
         lt_return LIKE TABLE OF ddshretval WITH HEADER LINE.

*-- Search help 목록 초기화
  CLEAR : gs_sh_ebeln, gt_sh_ebeln.

*-- Search help PO 헤더 조회
  SELECT * FROM ztc1mm0007
    INTO TABLE lt_head
   WHERE loekz = ''
     AND statu <> 'DL'
     AND bsart <> 'ZAPC'.

  IF lt_head IS INITIAL.
    MESSAGE s000 WITH TEXT-e01 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- PO 별 송장검증 가능 여부 판정
  LOOP AT lt_head INTO ls_head.

*-- IV 대상 품목 (삭제X / 송장검증대상) 조회
    SELECT * FROM ztc1mm0008
      INTO TABLE lt_item
     WHERE ebeln = ls_head-ebeln
       AND loekz = ''
       AND repos = 'X'.

    LOOP AT lt_item INTO ls_item.

*-- GR/IR 누적 및 청구가능수량 계산
      PERFORM get_gr_qty    USING    ls_item-ebeln ls_item-ebelp
                            CHANGING lv_gr.
      PERFORM get_iv_qty    USING    ls_item-ebeln ls_item-ebelp
                            CHANGING lv_iv.
      PERFORM calc_open_qty USING    ls_item-menge lv_gr lv_iv
                            CHANGING lv_open.

*-- 입고 이력 + 청구가능수량 모두 존재하는 PO만 Search help목록에 추가
      IF lv_gr > 0 AND lv_open > 0.

        CLEAR gs_sh_ebeln.
        gs_sh_ebeln-ebeln = ls_head-ebeln.
        gs_sh_ebeln-lifnr = ls_head-lifnr.
        gs_sh_ebeln-bedat = ls_head-bedat.

*-- Search help 표시용 벤더명 조회
        SELECT SINGLE name1 INTO gs_sh_ebeln-name1
          FROM ztc1mm0012
         WHERE lifnr = ls_head-lifnr.

        APPEND gs_sh_ebeln TO gt_sh_ebeln.
        EXIT.
      ENDIF.

    ENDLOOP.

  ENDLOOP.

  IF gt_sh_ebeln IS INITIAL.
    MESSAGE s000 WITH TEXT-e02 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SORT gt_sh_ebeln BY ebeln.

*-- Search help 팝업 호출
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'EBELN'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'GV_S_EBELN'
      window_title    = '[Taesan] IV 대상 구매오더 번호'
      value_org       = 'S'
    TABLES
      value_tab       = gt_sh_ebeln
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

*-- 선택한 PO 내역 세팅
  IF lt_return[] IS NOT INITIAL.
    READ TABLE lt_return INDEX 1.
    IF sy-subrc = 0.
      gv_s_ebeln = lt_return-fieldval.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_html_header
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_html_header .

  IF go_html_dock IS NOT BOUND.

    CREATE OBJECT go_html_dock
      EXPORTING
        side      = cl_gui_docking_container=>dock_at_top
        extension = 35.

  ENDIF.

  IF go_html_header IS NOT BOUND.

    CREATE OBJECT go_html_header
      EXPORTING
        io_parent = go_html_dock.

  ENDIF.

  go_html_header->display(
     EXPORTING
       iv_module_tag   = |MM|
       iv_module_full  = |MM - Materials Management|
       iv_program_name = |송장검증 프로그램|
       iv_program_desc = |3-Way Matching 기반으로 구매오더·입고·송장을 검증하고 AP 전표 생성을 수행하는 프로그램입니다|
       iv_program_id   = |{ sy-repid }|
       iv_system_info  = |{ sy-sysid } / { sy-mandt }|
       iv_user_id      = |{ sy-uname }|
       iv_user_name    = |{ sy-uname }|
   ).

ENDFORM.
