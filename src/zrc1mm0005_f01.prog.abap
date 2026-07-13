*&---------------------------------------------------------------------*
*& Include          ZRC1MM0005_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form display_screen
*&---------------------------------------------------------------------*
FORM display_screen .

  IF go_left_cont IS NOT BOUND.

*-- 확정 구매요청 리스트 조회
    PERFORM set_prdata.

*-- 구매오더 (결재대기) 리스트 조회
    PERFORM set_podata.

*-- 화면 구성요소 생성
    PERFORM create_tab1.
    PERFORM create_div_html.
    PERFORM create_arrow_html.
    PERFORM create_tab2.

*-- 필드카탈로그 설정
    CLEAR : gt_fcat_left, gt_fcat_right, gt_fcat_bottom, gt_fcat_po, gt_fcat_detail, gt_fcat_modi, gs_fcat.

    PERFORM set_field_catalog USING :
                                      " L : Left(확정 PR)
                                      'L' 'X' 'ICON'     ''            'C' '',
                                      'L' ' ' 'BANFN'    'ZTC1MM0025'  'C' '',
                                      'L' ' ' 'ITEM_CNT' ''            ' ' '',
                                      'L' ' ' 'BADAT'    'ZTC1MM0025'  'C' '',
                                      'L' ' ' 'ERNAM'    'ZTC1MM0025'  'C' '',

                                      " R : Right(선택 PR 상세)
                                      'R' '' 'CHECK' ''           ' ' '',
                                      'R' '' 'BNFPO' 'ZTC1MM0026' ' ' '',
                                      'R' '' 'MATNR' 'ZTC1MM0026' ' ' '',
                                      'R' '' 'MAKTX' 'ZTC1MM0026' ' ' '',
                                      'R' '' 'MENGE' 'ZTC1MM0026' ' ' '',
                                      'R' '' 'MEINS' 'ZTC1MM0026' 'C' '',
                                      'R' '' 'PRICE' 'ZTC1MM0026' ' ' '',
                                      'R' '' 'WAERS' 'ZTC1MM0026' 'C' '',
                                      'R' '' 'LIFNR' 'ZTC1MM0021' 'C' '',
                                      'R' '' 'NAME1' 'ZTC1MM0012' ' ' '',

                                      " A : 구매오더 결재 리스트(통합)
                                      'A' 'X' 'EBELN'         'ZTC1MM0007' 'C' '',
                                      'A' ' ' 'NAME1'         'ZTC1MM0012' ' ' 'X',
                                      'A' ' ' 'APPR_TYPE_TXT' ''           'C' '',
                                      'A' ' ' 'ITEM_CNT'      ''           ' ' '',
                                      'A' ' ' 'TOTAL_AMT'     ''           ' ' '',
                                      'A' ' ' 'WAERS'         'ZTC1MM0007' 'C' '',
                                      'A' ' ' 'BEDAT'         'ZTC1MM0007' 'C' '',
                                      'A' ' ' 'REJ_ICON'      ''           'C' '',

                                       " D : 구매오더 상세 품목
                                      'D' ' ' 'EBELP' 'ZTC1MM0008' 'C' '',
                                      'D' ' ' 'MATNR' 'ZTC1MM0008' ' ' '',
                                      'D' ' ' 'MAKTX' 'ZTC1MM0001' ' ' '',
                                      'D' ' ' 'MENGE' 'ZTC1MM0008' 'R' '',
                                      'D' ' ' 'MEINS' 'ZTC1MM0008' 'C' '',
                                      'D' ' ' 'NETPR' 'ZTC1MM0008' 'R' '',
                                      'D' ' ' 'TOTAL' ''           'R' '',
                                      'D' ' ' 'WAERS' 'ZTC1MM0007' 'C' '',
                                      'D' ' ' 'LFDAT' 'ZTC1MM0026' 'C' '',

                                       " M : PO 수정 팝업 품목
                                      'M' ' ' 'EBELP' 'ZTC1MM0008' 'C' '',
                                      'M' ' ' 'MATNR' 'ZTC1MM0008' ' ' '',
                                      'M' ' ' 'MAKTX' 'ZTC1MM0001' ' ' '',
                                      'M' ' ' 'MENGE' 'ZTC1MM0008' 'R' '',
                                      'M' ' ' 'MEINS' 'ZTC1MM0008' 'C' '',
                                      'M' ' ' 'NETPR' 'ZTC1MM0008' 'R' '',
                                      'M' ' ' 'TOTAL' ''           'R' '',
                                      'M' ' ' 'WAERS' 'ZTC1MM0008' 'C' '',
                                      'M' ' ' 'LFDAT' 'ZTC1MM0008' 'C' ''.

*-- Tree 필드카탈로그
    PERFORM set_tree_field_catalog USING : 'LIFNR'     '벤더'      'X',
                                           'NAME1'     '벤더명'    'X',
                                           'BANFN'     'PR번호'    'X',
                                           'BNFPO'     '품목'      'X',
                                           'MATNR'     '자재번호'  ' ',
                                           'MAKTX'     '자재명'    ' ',
                                           'REQ_MENGE' '요청수량'  ' ',
                                           'MENGE'     '발주수량'  ' ',
                                           'MEINS'     '단위'      ' ',
                                           'PRICE'     '단가'      ' ',
                                           'TOTAL_AMT' '총 금액'   ' ',
                                           'WAERS'     '통화'      ' ',
                                           'LFDAT'     '납기일'    ' ',
                                           'DEL_ICON'  '삭제'      ' '.

    PERFORM set_layout.

*-- 이벤트 핸들러 등록
    SET HANDLER : lcl_event_handler=>on_double_click  FOR ALL INSTANCES,
                  lcl_event_handler=>on_toolbar       FOR ALL INSTANCES,
                  lcl_event_handler=>on_user_command  FOR ALL INSTANCES,
                  lcl_event_handler=>on_link_click    FOR go_bottom_tree,
                  lcl_event_handler=>on_hotspot_click FOR ALL INSTANCES.

*-- Tree에 link_click 이벤트를 애플리케이션 이벤트로 등록
    PERFORM register_tree_events.

*-- Right ALV modified 이벤트 등록
    CALL METHOD go_right_alv->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified.

    PERFORM create_display.

    PERFORM set_card_html.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_prdata
*&---------------------------------------------------------------------*
FORM set_prdata .

  SELECT a~banfn, a~badat, a~statu, a~ernam,
         COUNT(*) AS item_cnt
    FROM ztc1mm0025 AS a
    INNER JOIN ztc1mm0026 AS b ON a~banfn = b~banfn
   WHERE ( @ztc1mm0025-banfn IS INITIAL OR a~banfn = @ztc1mm0025-banfn )
     AND ( @ztc1mm0025-badat IS INITIAL OR a~badat >= @ztc1mm0025-badat )
     AND ( @gv_badat_to IS INITIAL OR a~badat <= @gv_badat_to )
     AND b~statu = 'FC'
     AND b~ebeln IS INITIAL
   GROUP BY a~banfn, a~badat, a~statu, a~ernam
    INTO CORRESPONDING FIELDS OF TABLE @gt_left.

  SORT gt_left BY badat DESCENDING
                  banfn ASCENDING.

  LOOP AT gt_left ASSIGNING FIELD-SYMBOL(<fs_left>).
    <fs_left>-sel_cnt = 0.
    <fs_left>-icon    = icon_red_light.
    PERFORM convert_uname_to_name CHANGING <fs_left>-ernam.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_tab1
*&---------------------------------------------------------------------*
FORM create_tab1 .

  CREATE OBJECT go_left_cont
    EXPORTING
      container_name = 'LIST_CONT'.

  CREATE OBJECT go_right_cont
    EXPORTING
      container_name = 'DETAIL_CONT'.

  CREATE OBJECT go_bottom_cont
    EXPORTING
      container_name = 'PO_CONT'.

  CREATE OBJECT go_left_alv
    EXPORTING
      i_parent = go_left_cont.

  CREATE OBJECT go_right_alv
    EXPORTING
      i_parent = go_right_cont.

  CREATE OBJECT go_bottom_tree
    EXPORTING
      parent              = go_bottom_cont
      node_selection_mode = cl_gui_column_tree=>node_sel_mode_single
      item_selection      = abap_true
      no_html_header      = abap_true.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_tab2
*&---------------------------------------------------------------------*
FORM create_tab2 .
*-- HTML CARD
  CREATE OBJECT go_card_cont
    EXPORTING
      container_name = 'CARD_CONT'.

*-- 리스트/상세 메인 컨테이너
  CREATE OBJECT go_po_main_cont
    EXPORTING
      container_name = 'PO_MAIN_CONT'.

*-- 좌/우 분할 split 컨테이너
  CREATE OBJECT go_po_splitter
    EXPORTING
      parent  = go_po_main_cont
      rows    = 1
      columns = 2.

*-- 초기 좌측 100%, 우측 0% (상세 숨김)
  CALL METHOD go_po_splitter->set_column_width
    EXPORTING
      id    = 1
      width = 100.

*-- 좌측 컨테이너 (리스트)
  CALL METHOD go_po_splitter->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_list_cont.

*-- 우측 컨테이너 (상세정보)
  CALL METHOD go_po_splitter->get_container
    EXPORTING
      row       = 1
      column    = 2
    RECEIVING
      container = go_detail_cont.

*-- 우측 상세 splitter (헤더 / 아이템)
  CREATE OBJECT go_detail_split
    EXPORTING
      parent  = go_detail_cont
      rows    = 2
      columns = 1.

*-- 상단 컨테이너 (리스트)
  CALL METHOD go_detail_split->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_detail_h_cont.

*-- 하단 컨테이너 (상세정보)
  CALL METHOD go_detail_split->get_container
    EXPORTING
      row       = 2
      column    = 1
    RECEIVING
      container = go_detail_i_cont.

*-- 헤더 55%, 아이템 45%
  CALL METHOD go_detail_split->set_row_height
    EXPORTING
      id     = 1
      height = 40.

*-- HTML
  CREATE OBJECT go_card_html
    EXPORTING
      parent = go_card_cont.

*-- 좌측 통합 ALV
  CREATE OBJECT go_po_alv
    EXPORTING
      i_parent = go_list_cont.

*-- 상단 ALV
  CREATE OBJECT go_detail_h_html
    EXPORTING
      parent = go_detail_h_cont.

*-- 하단 ALV
  CREATE OBJECT go_detail_i_alv
    EXPORTING
      i_parent = go_detail_i_cont.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog
*&---------------------------------------------------------------------*
FORM set_field_catalog  USING pv_flag pv_key pv_field pv_table pv_just pv_emph.

  gs_fcat = VALUE #( key       = pv_key
                     fieldname = pv_field
                     ref_table = pv_table
                     just      = pv_just
                     emphasize = pv_emph ).

  PERFORM get_korean_text USING    pv_table
                                   pv_field
                          CHANGING gs_fcat-coltext.


  IF pv_flag = 'R'.
    CASE pv_field.
      WHEN 'MAKTX'.
        gs_fcat-coltext    = '자재명'.
      WHEN 'CHECK'.
        gs_fcat-coltext    = '선택'.
      WHEN 'MENGE'.
        gs_fcat-qfieldname = 'MEINS'.
      WHEN 'PRICE'.
        gs_fcat-cfieldname = 'WAERS'.
        gs_fcat-coltext    = '단가'.
    ENDCASE.
  ENDIF.

  CASE pv_flag.
    WHEN 'L'.
      CASE pv_field.
        WHEN 'ICON'.
          gs_fcat-coltext = '상태'.
          gs_fcat-outputlen = 5.
        WHEN 'BANFN'.
          gs_fcat-outputlen = 12.
        WHEN 'ITEM_CNT'.
          gs_fcat-coltext = '품목 개수'.
      ENDCASE.
    WHEN 'R'.
      CASE pv_field.
        WHEN 'CHECK'.
          gs_fcat-checkbox  = 'X'.
          gs_fcat-edit      = 'X'.
          gs_fcat-outputlen = 5.
        WHEN 'BNFPO'.
          gs_fcat-outputlen = 6.
        WHEN 'MATNR'.
          gs_fcat-outputlen = 12.
        WHEN 'MAKTX'.
          gs_fcat-outputlen = 20.
        WHEN 'MENGE'.
          gs_fcat-outputlen = 8.
          gs_fcat-just      = 'R'.
        WHEN 'MEINS'.
          gs_fcat-outputlen = 5.
        WHEN 'PRICE'.
          gs_fcat-outputlen = 10.
          gs_fcat-just      = 'R'.
        WHEN 'WAERS'.
          gs_fcat-outputlen = 5.
        WHEN 'LIFNR'.
          gs_fcat-outputlen = 10.
        WHEN 'NAME1'.
          gs_fcat-outputlen = 20.
      ENDCASE.
    WHEN 'A'.
      CASE pv_field.
        WHEN 'EBELN'.
          gs_fcat-coltext   = '구매오더 번호'.
          gs_fcat-outputlen = 14.
        WHEN 'NAME1'.
          gs_fcat-outputlen = 19.
        WHEN 'APPR_TYPE_TXT'.
          gs_fcat-coltext   = '결재유형'.
          gs_fcat-outputlen = 12.
          gs_fcat-no_out    = 'X'.
        WHEN 'ITEM_CNT'.
          gs_fcat-coltext   = '품목'.
          gs_fcat-outputlen = 3.
        WHEN 'TOTAL_AMT'.
          gs_fcat-cfieldname = 'WAERS'.
          gs_fcat-coltext    = '총 금액'.
          gs_fcat-outputlen  = 13.
        WHEN 'WAERS'.
          gs_fcat-outputlen = 5.
        WHEN 'BEDAT'.
          gs_fcat-coltext   = '구매오더 생성일'.
          gs_fcat-outputlen = 10.
        WHEN 'REJ_ICON'.
*-- 반려사유 아이콘: hotspot 클릭 가능, 기본은 숨김 (반려 카드일 때만 표시)
          gs_fcat-coltext   = '사유'.
          gs_fcat-icon      = 'X'.
          gs_fcat-hotspot   = 'X'.
          gs_fcat-no_out    = 'X'.
          gs_fcat-outputlen = 5.
      ENDCASE.
    WHEN 'D'.
      CASE pv_field.
        WHEN 'EBELP'.
          gs_fcat-coltext = '품목 번호'.
          gs_fcat-outputlen = 7.
        WHEN 'MATNR'.
          gs_fcat-outputlen = 12.
        WHEN 'MAKTX'.
          gs_fcat-coltext   = '자재명'.
          gs_fcat-outputlen = 20.
        WHEN 'MENGE'.
          gs_fcat-qfieldname = 'MEINS'.
          gs_fcat-coltext = '수량'.
          gs_fcat-outputlen = 6.
        WHEN 'MEINS'.
          gs_fcat-coltext = '단위'.
        WHEN 'NETPR'.
          gs_fcat-outputlen = 10.
          gs_fcat-cfieldname = 'WAERS'.
        WHEN 'TOTAL'.
          gs_fcat-coltext = '총 금액'.
          gs_fcat-cfieldname = 'WAERS'.
      ENDCASE.
    WHEN 'M'.
      CASE pv_field.
        WHEN 'EBELP'.
          gs_fcat-coltext   = '품목 번호'.
          gs_fcat-outputlen = 7.
        WHEN 'MATNR'.
          gs_fcat-coltext   = '자재 번호'.
          gs_fcat-outputlen = 12.
        WHEN 'MAKTX'.
          gs_fcat-coltext   = '자재명'.
          gs_fcat-outputlen = 20.
        WHEN 'MENGE'.
          gs_fcat-qfieldname = 'MEINS'.
          gs_fcat-coltext    = '수량'.
          gs_fcat-outputlen  = 8.
          gs_fcat-edit       = 'X'.
        WHEN 'MEINS'.
          gs_fcat-coltext   = '단위'.
          gs_fcat-outputlen = 5.
        WHEN 'NETPR'.
          gs_fcat-coltext    = '단가'.
          gs_fcat-outputlen  = 10.
          gs_fcat-cfieldname = 'WAERS'.
          gs_fcat-edit       = 'X'.
        WHEN 'TOTAL'.
          gs_fcat-coltext    = '총 금액'.
          gs_fcat-outputlen  = 13.
          gs_fcat-cfieldname = 'WAERS'.
          gs_fcat-datatype   = 'CURR'.
          gs_fcat-inttype    = 'P'.
          gs_fcat-intlen     = 13.
          gs_fcat-decimals   = 2.
        WHEN 'WAERS'.
          gs_fcat-coltext   = '통화'.
          gs_fcat-outputlen = 5.
        WHEN 'LFDAT'.
          gs_fcat-coltext   = '납기일'.
          gs_fcat-outputlen = 10.
          gs_fcat-edit      = 'X'.
      ENDCASE.
  ENDCASE.

  CASE pv_flag.
    WHEN 'L'.
      APPEND gs_fcat TO gt_fcat_left.
    WHEN 'R'.
      APPEND gs_fcat TO gt_fcat_right.
    WHEN 'A'.
      APPEND gs_fcat TO gt_fcat_po.
    WHEN 'D'.
      APPEND gs_fcat TO gt_fcat_detail.
    WHEN 'M'.
      APPEND gs_fcat TO gt_fcat_modi.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_tree_field_catalog
*&---------------------------------------------------------------------*
FORM set_tree_field_catalog  USING pv_field pv_text pv_no_out.

  CASE pv_field.
    WHEN 'MENGE' OR 'REQ_MENGE'.
      gt_fcat_bottom = VALUE #( BASE gt_fcat_bottom
                                ( fieldname  = pv_field
                                  coltext    = pv_text
                                  no_out     = pv_no_out
                                  qfieldname = 'MEINS'
                                  outputlen  = 12
                                  just       = 'R' ) ).

    WHEN 'TOTAL_AMT'.
      gt_fcat_bottom = VALUE #( BASE gt_fcat_bottom
                                ( fieldname  = pv_field
                                  coltext    = pv_text
                                  no_out     = pv_no_out
                                  cfieldname = 'WAERS'
                                  outputlen  = 20
                                  just       = 'R' ) ).

    WHEN 'PRICE'.
      gt_fcat_bottom = VALUE #( BASE gt_fcat_bottom
                                ( fieldname  = pv_field
                                  coltext    = pv_text
                                  no_out     = pv_no_out
                                  cfieldname = 'WAERS'
                                  outputlen  = 10
                                  just       = 'R' ) ).

    WHEN 'LFDAT'.
      gt_fcat_bottom = VALUE #( BASE gt_fcat_bottom
                                ( fieldname = pv_field
                                  coltext   = pv_text
                                  no_out    = pv_no_out
                                  outputlen = 15
                                  just      = 'C' ) ).


    WHEN 'DEL_ICON'.
*-- 삭제 아이콘: hotspot으로 클릭 가능하게
      gt_fcat_bottom = VALUE #( BASE gt_fcat_bottom
                                ( fieldname = pv_field
                                  coltext   = pv_text
                                  no_out    = pv_no_out
                                  icon      = 'X'
                                  hotspot   = 'X'
                                  outputlen = 8
                                  just      = 'C' ) ).

    WHEN 'MEINS'.
      gt_fcat_bottom = VALUE #( BASE gt_fcat_bottom
                                  ( fieldname = pv_field
                                    coltext   = pv_text
                                    no_out    = pv_no_out
                                    outputlen = 10 ) ).

    WHEN 'WAERS'.
      gt_fcat_bottom = VALUE #( BASE gt_fcat_bottom
                                  ( fieldname = pv_field
                                    coltext   = pv_text
                                    no_out    = pv_no_out
                                    outputlen = 10 ) ).

    WHEN 'MAKTX'.
      gt_fcat_bottom = VALUE #( BASE gt_fcat_bottom
                                ( fieldname = pv_field
                                  coltext   = pv_text
                                  no_out    = pv_no_out
                                  outputlen = 20 ) ).

    WHEN 'MATNR'.
      gt_fcat_bottom = VALUE #( BASE gt_fcat_bottom
                                ( fieldname = pv_field
                                  coltext   = pv_text
                                  no_out    = pv_no_out
                                  outputlen = 13 ) ).

    WHEN OTHERS.
      gt_fcat_bottom = VALUE #( BASE gt_fcat_bottom
                                ( fieldname = pv_field
                                  coltext   = pv_text
                                  no_out    = pv_no_out
                                  outputlen = 20
                                  just      = 'C') ).
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout
*&---------------------------------------------------------------------*
FORM set_layout .

  gs_layout_left = VALUE #( zebra      = abap_true
                            sel_mode   = 'D'
                            grid_title = '구매요청 확정 목록' ).

  gs_layout_right = VALUE #( zebra      = abap_true
                             sel_mode   = 'A'
                             no_headers = 'X'
                             info_fname = 'LINECOLOR'
                             stylefname = 'CELLTAB' ).

*-- 통합 PO 리스트
  gs_layout_po = VALUE #( zebra      = abap_true
                          sel_mode   = 'D'
                          info_fname = 'LINECOLOR'
                          grid_title = '구매오더 결재 리스트' ).

*-- 상세 아이템
  gs_layout_detail = VALUE #( zebra      = abap_true
                              sel_mode   = 'D'
                              no_toolbar = 'X'
                              grid_title = '품목 상세'
                              smalltitle = 'X').

*-- 수정 팝업
  gs_layout_modi = VALUE #( zebra      = abap_true
                            sel_mode   = 'D'
                            edit       = 'X'
                            stylefname = 'CELLTAB'
                            no_toolbar = 'X'
                            cwidth_opt = 'A'
                            grid_title = '구매오더 품목 수정' ).

  gs_variant = VALUE #( report = sy-repid
                        handle = 'PO' ).



ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_subscreen_number
*&---------------------------------------------------------------------*
FORM set_subscreen_number .

  CASE tab_strip-activetab.
    WHEN 'TAB1'.
      gv_dynnr = '0110'.
      SET PF-STATUS 'TAB1'.
    WHEN 'TAB2'.
      gv_dynnr = '0120'.
      SET PF-STATUS 'TAB2'.
    WHEN OTHERS.
      gv_dynnr = '0110'.
      tab_strip-activetab = 'TAB1'.
      SET PF-STATUS 'TAB1'.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form register_tree_events
*&---------------------------------------------------------------------*
FORM register_tree_events .

  DATA : lt_events TYPE cntl_simple_events,
         ls_event  TYPE cntl_simple_event.

  ls_event-eventid    = cl_gui_column_tree=>eventid_link_click.
  ls_event-appl_event = 'X'.
  APPEND ls_event TO lt_events.

  CALL METHOD go_bottom_tree->set_registered_events
    EXPORTING
      events = lt_events.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_display
*&---------------------------------------------------------------------*
FORM create_display .

**********************************************************************
* 구매오더 생성 탭
**********************************************************************

*-- 구매요청 확정 목록 (Left)
  CALL METHOD go_left_alv->set_table_for_first_display
    EXPORTING
      is_variant      = gs_variant
      i_save          = 'A'
      i_default       = 'X'
      is_layout       = gs_layout_left
    CHANGING
      it_outtab       = gt_left
      it_fieldcatalog = gt_fcat_left.

*-- 구매요청 상세정보 (Right)
  CALL METHOD go_right_alv->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layout_right
    CHANGING
      it_outtab       = gt_right
      it_fieldcatalog = gt_fcat_right.

*-- Bottom Tree 생성
  PERFORM create_bottom_tree.
  PERFORM build_bottom_tree.
  PERFORM set_tree_toolbar.

**********************************************************************
* 구매오더 결재 탭
**********************************************************************
*-- 초기 상태: ALL (전체)
  gv_curr_stat = 'ALL'.
  gt_po_list   = gt_appr.

  PERFORM set_po_grid_title.

  CALL METHOD go_po_alv->set_table_for_first_display
    EXPORTING
      is_variant      = gs_variant
      i_save          = 'A'
      i_default       = 'X'
      is_layout       = gs_layout_po
    CHANGING
      it_outtab       = gt_po_list
      it_fieldcatalog = gt_fcat_po.

*-- 상세 아이템 ALV (초기 빈 데이터)
  CALL METHOD go_detail_i_alv->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layout_detail
    CHANGING
      it_outtab       = gt_detail_item
      it_fieldcatalog = gt_fcat_detail.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_korean_text
*&---------------------------------------------------------------------*
FORM get_korean_text  USING  VALUE(pv_table)
                             VALUE(pv_field)
                      CHANGING cv_coltext.

  DATA: lv_rollname TYPE rollname,
        lv_text     TYPE scrtext_m.

  SELECT SINGLE rollname
    FROM dd03l
    INTO lv_rollname
    WHERE tabname   = pv_table
      AND fieldname = pv_field.

  CHECK lv_rollname IS NOT INITIAL.

  SELECT SINGLE scrtext_m
    FROM dd04t
    INTO lv_text
    WHERE rollname   = lv_rollname
      AND ddlanguage = '3'.

  IF lv_text IS NOT INITIAL.
    cv_coltext = lv_text.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_div_html
*&---------------------------------------------------------------------*
FORM create_div_html .


  CREATE OBJECT go_div_cont
    EXPORTING
      container_name = 'LINE_DIV'.

  CREATE OBJECT go_div_html
    EXPORTING
      parent = go_div_cont.

  DATA: lt_html TYPE TABLE OF char255,
        lv_url  TYPE char255.

  APPEND '<html><body style="margin:0;padding:0;background:#DFEBF5;' TO lt_html.
  APPEND 'width:100%;height:100%;overflow:hidden;">'                 TO lt_html.

  APPEND '<div style="position:relative;width:100%;height:100%;">'   TO lt_html.

  APPEND '<div style="position:absolute;top:50%;left:0;'             TO lt_html.
  APPEND 'width:65%;height:1px;'                                     TO lt_html.
  APPEND 'background:linear-gradient(to right,transparent,#7a9aba);"></div>' TO lt_html.

  APPEND '<div style="position:absolute;top:50%;right:0;'            TO lt_html.
  APPEND 'width:35%;height:1px;'                                     TO lt_html.
  APPEND 'background:linear-gradient(to left,transparent,#7a9aba);"></div>' TO lt_html.

  APPEND '<div style="position:absolute;top:50%;left:50%;'           TO lt_html.
  APPEND 'transform:translateX(-50%) translateY(-50%);'              TO lt_html.
  APPEND 'background:#1a4068;border-radius:10px;'                    TO lt_html.
  APPEND 'padding:3px 12px;white-space:nowrap;">'                    TO lt_html.
  APPEND '<span style="color:#fff;font-size:11px;">&#9660;</span>'   TO lt_html.
  APPEND '&nbsp;<span style="font-size:11px;color:#a8c8e8;'          TO lt_html.
  APPEND 'font-family:Malgun Gothic;">'                              TO lt_html.
  APPEND '체크 후 [구매오더 대상 추가] 클릭</span>'                  TO lt_html.
  APPEND '</div>'                                                    TO lt_html.

  APPEND '</div>'                                                    TO lt_html.
  APPEND '</body></html>'                                            TO lt_html.

  CALL METHOD go_div_html->load_data
    IMPORTING
      assigned_url = lv_url
    CHANGING
      data_table   = lt_html.

  CALL METHOD go_div_html->show_url
    EXPORTING
      url = lv_url.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_arrow_html
*&---------------------------------------------------------------------*
FORM create_arrow_html .

  CREATE OBJECT go_arrow_cont
    EXPORTING
      container_name = 'ARROW_DIV'.

  CREATE OBJECT go_arrow_html
    EXPORTING
      parent = go_arrow_cont.

  DATA: lt_html TYPE TABLE OF char255,
        lv_url  TYPE char255.

  APPEND '<html><body style="margin:0;padding:0;background:#DFEBF5;' TO lt_html.
  APPEND 'width:100%;height:100%;overflow:hidden;">'                 TO lt_html.

  APPEND '<table width="100%" height="100%" border="0"'              TO lt_html.
  APPEND ' cellpadding="0" cellspacing="0">'                         TO lt_html.
  APPEND '<tr><td align="center" valign="middle">'                   TO lt_html.

  APPEND '<span style="font-size:20px;color:#1a4068;">&#9658;</span>' TO lt_html.

  APPEND '</td></tr></table>'                                        TO lt_html.
  APPEND '</body></html>'                                            TO lt_html.

  CALL METHOD go_arrow_html->load_data
    IMPORTING
      assigned_url = lv_url
    CHANGING
      data_table   = lt_html.

  CALL METHOD go_arrow_html->show_url
    EXPORTING
      url = lv_url.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_double_click
*&---------------------------------------------------------------------*
FORM handle_double_click  USING ps_row    TYPE lvc_s_row
                                ps_column TYPE lvc_s_col.

  READ TABLE gt_left INTO gs_left INDEX ps_row-index.
  CHECK sy-subrc = 0.

  PERFORM get_pr_detail USING gs_left-banfn.

  CALL METHOD cl_gui_cfw=>set_new_ok_code
    EXPORTING
      new_code = 'ENTER'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form search_prdata
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM search_prdata .

*-- 조건 재조회
  PERFORM set_prdata.
  PERFORM update_left_status.
  PERFORM refresh_table USING go_left_alv.

*-- Right ALV / Tree 초기화
  CLEAR : gt_right.
  PERFORM refresh_table USING go_right_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_pr_detail
*&---------------------------------------------------------------------*
FORM get_pr_detail  USING pv_banfn TYPE ztc1mm0025-banfn.

  DATA : lt_right_work LIKE gt_right.

  gv_sel_banfn = pv_banfn.

*-- 상세정보 조회 (계약 벤더만)
  SELECT a~banfn, a~bnfpo, a~matnr, a~maktx, a~menge, a~meins,
         c~netpr AS price, c~waers, a~lfdat, b~lifnr, d~name1,
         c~minbm, c~norbm, h~bsart, a~purrsn
  FROM ztc1mm0026 AS a
  INNER JOIN ztc1mm0021 AS b ON a~matnr = b~matnr
  INNER JOIN ztc1mm0022 AS c ON b~infnr = c~infnr
  INNER JOIN ztc1mm0012 AS d ON b~lifnr = d~lifnr
  INNER JOIN ztc1mm0025 AS h ON a~banfn = h~banfn
 WHERE a~banfn        = @pv_banfn
   AND c~contract_flg = 'X'
   AND a~statu        = 'FC'
   AND a~ebeln IS INITIAL
   AND a~loekz        = ''
   AND b~loekz        = ''
   AND c~loekz        = ''
   AND c~valid_from <= @sy-datum
   AND c~valid_to   >= @sy-datum
  INTO CORRESPONDING FIELDS OF TABLE @lt_right_work.

  SORT lt_right_work BY bnfpo.

*-- 이미 Tree로 이동된 항목은 sent/check/linecolor/celltab 복원
  LOOP AT lt_right_work ASSIGNING FIELD-SYMBOL(<fs_right>).
    READ TABLE gt_bottom TRANSPORTING NO FIELDS
         WITH KEY banfn = <fs_right>-banfn
                  bnfpo = <fs_right>-bnfpo
                  lifnr = <fs_right>-lifnr
                  matnr = <fs_right>-matnr.
    IF sy-subrc = 0.
      <fs_right>-sent      = 'X'.
      <fs_right>-check     = 'X'.
      <fs_right>-linecolor = 'C500'.
      PERFORM set_cell_readonly USING <fs_right>-celltab 'CHECK'.
    ENDIF.
  ENDLOOP.

  gt_right = lt_right_work.

  gs_layout_right-no_headers = space.

  CALL METHOD go_right_alv->set_frontend_layout
    EXPORTING
      is_layout = gs_layout_right.

  PERFORM refresh_table USING go_right_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_cell_readonly
*&   특정 셀 필드를 읽기전용(잠금)으로 설정
*&---------------------------------------------------------------------*
FORM set_cell_readonly  USING pt_celltab TYPE lvc_t_styl
                              pv_field   TYPE lvc_fname.

  DATA : ls_celltab TYPE lvc_s_styl.

  FIELD-SYMBOLS : <fs_celltab> TYPE lvc_t_styl.

  ASSIGN pt_celltab TO <fs_celltab>.

*-- 기존 항목 제거 (중복 방지)
  DELETE <fs_celltab> WHERE fieldname = pv_field.

  ls_celltab-fieldname = pv_field.
  ls_celltab-style     = cl_gui_alv_grid=>mc_style_disabled.
  INSERT ls_celltab INTO TABLE <fs_celltab>.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form clear_cell_readonly
*&   특정 셀 잠금 해제
*&---------------------------------------------------------------------*
FORM clear_cell_readonly  USING pt_celltab TYPE lvc_t_styl
                                pv_field   TYPE lvc_fname.

  FIELD-SYMBOLS : <fs_celltab> TYPE lvc_t_styl.

  ASSIGN pt_celltab TO <fs_celltab>.

  DELETE <fs_celltab> WHERE fieldname = pv_field.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_table
*&---------------------------------------------------------------------*
FORM refresh_table  USING po_alv TYPE REF TO cl_gui_alv_grid.

  DATA : ls_stable TYPE lvc_s_stbl.

  ls_stable-col = 'X'.
  ls_stable-row = 'X'.

  CALL METHOD po_alv->refresh_table_display
    EXPORTING
      is_stable = ls_stable.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_toolbar_left
*&---------------------------------------------------------------------*
FORM handle_toolbar_left  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

  CLEAR po_object->mt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_toolbar_right
*&---------------------------------------------------------------------*
FORM handle_toolbar_right  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

  CLEAR po_object->mt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form add_conv_list
*&   체크된 행을 Tree(gt_bottom)로 이동
*&---------------------------------------------------------------------*
FORM add_conv_list .

  DATA lv_tabix TYPE sy-tabix.

  CALL METHOD go_right_alv->check_changed_data.

  LOOP AT gt_right INTO gs_right WHERE check = 'X'.
    lv_tabix = sy-tabix.

*-- 이미 이동 처리된 건 스킵
    IF gs_right-sent = 'X'.
      CONTINUE.
    ENDIF.

*-- 이중 방어: gt_bottom 중복 체크
    READ TABLE gt_bottom TRANSPORTING NO FIELDS
         WITH KEY banfn = gs_right-banfn
                  bnfpo = gs_right-bnfpo
                  lifnr = gs_right-lifnr
                  matnr = gs_right-matnr.
    IF sy-subrc = 0.
      gs_right-sent = 'X'.
      CONTINUE.
    ENDIF.

*-- gt_bottom 추가
    CLEAR gs_bottom.
    MOVE-CORRESPONDING gs_right TO gs_bottom.

*-- 발주 묶음/최소주문수량 반영하여 발주수량 산정
    PERFORM calc_order_qty USING    gs_right-menge
                                    gs_right-minbm
                                    gs_right-norbm
                           CHANGING gs_bottom-menge.

    gs_bottom-req_menge = gs_right-menge.
    gs_bottom-total_amt = gs_bottom-menge * gs_right-price.
    gs_bottom-del_icon  = icon_incomplete.
    APPEND gs_bottom TO gt_bottom.

*-- 현재 행 상태 업데이트 (이동완료 플래그 + 초록색 + CHECK 잠금)
    gs_right-sent      = 'X'.
    gs_right-linecolor = 'C500'.
    PERFORM set_cell_readonly USING gs_right-celltab 'CHECK'.

    MODIFY gt_right FROM gs_right
      INDEX lv_tabix
      TRANSPORTING sent linecolor celltab.

  ENDLOOP.

  PERFORM refresh_table USING go_right_alv.
  PERFORM build_bottom_tree.

  PERFORM update_left_status.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_tree_link_click
*&   Tree의 DEL_ICON(hotspot) 클릭 이벤트
*&---------------------------------------------------------------------*
FORM handle_tree_link_click  USING pv_node_key  TYPE lvc_nkey
                                   pv_fieldname TYPE lvc_fname.

*-- 삭제 아이콘 컬럼이 아니면 무시
  CHECK pv_fieldname = 'DEL_ICON'.

  PERFORM remove_from_bottom USING pv_node_key.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form remove_from_bottom
*&   Tree에서 하위노드 제거 + gt_bottom에서 삭제 + gt_right 복원
*&   마지막 하위노드 제거 시 상위노드도 자동 제거
*&---------------------------------------------------------------------*
FORM remove_from_bottom  USING pv_node_key TYPE lvc_nkey.

  DATA : ls_outtab_line LIKE gs_bottom,
         lv_outtab_idx  TYPE sy-tabix,
         lv_vendor_cnt  TYPE i.

*-- 1. 노드 데이터 조회
  CALL METHOD go_bottom_tree->get_outtab_line
    EXPORTING
      i_node_key    = pv_node_key
    IMPORTING
      e_outtab_line = ls_outtab_line.

*-- 하위노드가 아니면 무시 (상위노드는 banfn/bnfpo 비어있음)
  CHECK ls_outtab_line-banfn IS NOT INITIAL.

*-- 2. gt_bottom에서 정확히 1건만 삭제
  READ TABLE gt_bottom TRANSPORTING NO FIELDS
    WITH KEY banfn = ls_outtab_line-banfn
             bnfpo = ls_outtab_line-bnfpo
             lifnr = ls_outtab_line-lifnr
             matnr = ls_outtab_line-matnr.

  IF sy-subrc = 0.
    lv_outtab_idx = sy-tabix.
    DELETE gt_bottom INDEX lv_outtab_idx.
  ENDIF.

*-- 3. gt_right 복원 (sent/check/linecolor/celltab) - 1건만
  LOOP AT gt_right ASSIGNING FIELD-SYMBOL(<fs_right>)
                   WHERE banfn = ls_outtab_line-banfn
                     AND bnfpo = ls_outtab_line-bnfpo
                     AND lifnr = ls_outtab_line-lifnr
                     AND matnr = ls_outtab_line-matnr
                     AND sent  = 'X'.

    <fs_right>-sent      = ''.
    <fs_right>-check     = ''.
    <fs_right>-linecolor = ''.
    PERFORM clear_cell_readonly USING <fs_right>-celltab 'CHECK'.
    EXIT.

  ENDLOOP.

*-- 4. 해당 벤더의 gt_bottom 남은 건수 확인
  lv_vendor_cnt = 0.
  LOOP AT gt_bottom TRANSPORTING NO FIELDS
       WHERE lifnr = ls_outtab_line-lifnr
         AND banfn IS NOT INITIAL.
    lv_vendor_cnt = lv_vendor_cnt + 1.
  ENDLOOP.

*-- 5. Tree 재빌드 (전체 다시 그리기)
  PERFORM build_bottom_tree.

*-- 6. 오른쪽 ALV 반드시 갱신 (어느 경로든 여기 도달)
  PERFORM refresh_table USING go_right_alv.

  PERFORM update_left_status.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_bottom_tree
*&---------------------------------------------------------------------*
FORM create_bottom_tree .

  CLEAR gs_tree_header.
  gs_tree_header-heading   = '공급업체 / 자재'.
  gs_tree_header-tooltip   = '구매오더 생성 대상 Tree'.
  gs_tree_header-width     = 40.
  gs_tree_header-width_pix = space.

  CALL METHOD go_bottom_tree->set_table_for_first_display
    EXPORTING
      is_variant          = gs_variant
      i_save              = 'A'
      i_default           = 'X'
      is_hierarchy_header = gs_tree_header
    CHANGING
      it_outtab           = gt_bottom
      it_fieldcatalog     = gt_fcat_bottom.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form build_bottom_tree
*&---------------------------------------------------------------------*
FORM build_bottom_tree .

  DATA : lt_bottom      LIKE TABLE OF gs_bottom,
         lt_vendor      TYPE SORTED TABLE OF ztc1mm0021-lifnr
                          WITH UNIQUE KEY table_line,
         lt_vendor_keys TYPE lvc_t_nkey,
         ls_src         LIKE gs_bottom,
         ls_bottom      LIKE gs_bottom,
         ls_vendor_sum  LIKE gs_bottom,
         ls_layout      TYPE lvc_s_layn,
         lv_node_text   TYPE lvc_value,
         lv_vendor_key  TYPE lvc_nkey,
         lv_meins_diff  TYPE abap_bool,
         lv_waers_diff  TYPE abap_bool.

  FIELD-SYMBOLS: <lv_lifnr> TYPE ztc1mm0021-lifnr.

*-- 1. 정상 상세행만 추출
  LOOP AT gt_bottom INTO ls_src.
    CHECK ls_src-banfn IS NOT INITIAL.
    CHECK ls_src-bnfpo IS NOT INITIAL.
    CHECK ls_src-matnr IS NOT INITIAL.
    APPEND ls_src TO lt_bottom.
  ENDLOOP.

  SORT lt_bottom BY lifnr name1 banfn bnfpo matnr.

  CALL METHOD go_bottom_tree->delete_all_nodes.

*-- 2. 벤더 목록 추출
  LOOP AT lt_bottom INTO ls_bottom.
    INSERT ls_bottom-lifnr INTO TABLE lt_vendor.
  ENDLOOP.

*-- 3. 벤더별 상위/하위 노드 생성
  LOOP AT lt_vendor ASSIGNING <lv_lifnr>.

    CLEAR : ls_vendor_sum,
            lv_meins_diff,
            lv_waers_diff.

*--- 벤더 소계 계산
    LOOP AT lt_bottom INTO ls_bottom WHERE lifnr = <lv_lifnr>.

      IF ls_vendor_sum-lifnr IS INITIAL.
        ls_vendor_sum-lifnr = ls_bottom-lifnr.
        ls_vendor_sum-name1 = ls_bottom-name1.
        ls_vendor_sum-meins = ls_bottom-meins.
        ls_vendor_sum-waers = ls_bottom-waers.
        ls_vendor_sum-lfdat = ls_bottom-lfdat.
      ELSE.
*-- 최소 납기일자로 변경
        IF ls_vendor_sum-lfdat IS INITIAL OR
          ls_bottom-lfdat < ls_vendor_sum-lfdat.
          ls_vendor_sum-lfdat = ls_bottom-lfdat.
        ENDIF.
      ENDIF.

      ls_vendor_sum-menge     = ls_vendor_sum-menge + ls_bottom-menge.
      ls_vendor_sum-req_menge = ls_vendor_sum-req_menge + ls_bottom-req_menge.
      ls_vendor_sum-total_amt = ls_vendor_sum-total_amt + ls_bottom-total_amt.

      IF ls_vendor_sum-meins IS NOT INITIAL
         AND ls_bottom-meins IS NOT INITIAL
         AND ls_vendor_sum-meins <> ls_bottom-meins.
        lv_meins_diff = abap_true.
      ENDIF.

      IF ls_vendor_sum-waers IS NOT INITIAL
         AND ls_bottom-waers IS NOT INITIAL
         AND ls_vendor_sum-waers <> ls_bottom-waers.
        lv_waers_diff = abap_true.
      ENDIF.

    ENDLOOP.

    IF lv_meins_diff = abap_true.
      CLEAR ls_vendor_sum-meins.
    ENDIF.

    IF lv_waers_diff = abap_true.
      CLEAR ls_vendor_sum-waers.
    ENDIF.

*--- 상위노드는 상세필드/삭제아이콘 비움
    CLEAR : ls_vendor_sum-banfn,
            ls_vendor_sum-bnfpo,
            ls_vendor_sum-matnr,
            ls_vendor_sum-maktx,
            ls_vendor_sum-price,
            ls_vendor_sum-del_icon.

*--- 상위노드 레이아웃 (폴더)
    CLEAR : ls_layout.
    ls_layout-isfolder  = abap_true.
    ls_layout-n_image   = icon_plant.
    ls_layout-exp_image = icon_plant.

    lv_node_text = |{ ls_vendor_sum-name1 }|.

    CALL METHOD go_bottom_tree->add_node
      EXPORTING
        i_relat_node_key = ''
        i_relationship   = cl_gui_column_tree=>relat_last_child
        i_node_text      = lv_node_text
        is_node_layout   = ls_layout
        is_outtab_line   = ls_vendor_sum
      IMPORTING
        e_new_node_key   = lv_vendor_key.

*--- 상위노드 키 수집 (펼치기용)
    APPEND lv_vendor_key TO lt_vendor_keys.

*--- 하위노드 추가 (leaf)
    LOOP AT lt_bottom INTO ls_bottom WHERE lifnr = <lv_lifnr>.

      ls_bottom-del_icon = icon_incomplete.

*--- 하위노드 레이아웃 (leaf - folder 아님)
      CLEAR ls_layout.
      ls_layout-isfolder = abap_false.
      ls_layout-n_image  = '@KJ@'.

      lv_node_text = |{ ls_bottom-banfn } / { ls_bottom-bnfpo }|.

      CALL METHOD go_bottom_tree->add_node
        EXPORTING
          i_relat_node_key = lv_vendor_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = lv_node_text
          is_node_layout   = ls_layout
          is_outtab_line   = ls_bottom.

    ENDLOOP.

  ENDLOOP.

*-- 4. 모든 상위노드 펼치기
  IF lt_vendor_keys IS NOT INITIAL.
    CALL METHOD go_bottom_tree->expand_nodes
      EXPORTING
        it_node_key = lt_vendor_keys.
  ENDIF.

  CALL METHOD go_bottom_tree->frontend_update.
  CALL METHOD cl_gui_cfw=>flush.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_tree_toolbar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_tree_toolbar .

  DATA: lt_fcode TYPE TABLE OF ui_func,
        lv_fcode TYPE ui_func.

*-- 툴바읽기
  CALL METHOD go_bottom_tree->get_toolbar_object
    IMPORTING
      er_toolbar = g_tree_toolbar.

  CHECK NOT g_tree_toolbar IS INITIAL.

*-- 툴바에서 필요없는 버튼 제거
  APPEND '&CALC'       TO lt_fcode.
  APPEND '&FIND'       TO lt_fcode.
  APPEND '&PRINT_BACK' TO lt_fcode.
  APPEND '&LOAD'       TO lt_fcode.

  LOOP AT lt_fcode INTO lv_fcode.

    CALL METHOD g_tree_toolbar->delete_button
      EXPORTING
        fcode            = lv_fcode
      EXCEPTIONS
        cntl_error       = 1
        cntb_error_fcode = 2
        OTHERS           = 3.

  ENDLOOP.

*-- 구매오더 생성 버튼 추가
  CALL METHOD g_tree_toolbar->add_button
    EXPORTING
      fcode     = 'CREATE'
      icon      = icon_shoppingcart
      butn_type = cntb_btype_button
      text      = '구매오더 생성'
      quickinfo = 'PO 생성'.

  SET HANDLER lcl_event_handler=>on_tree_command FOR g_tree_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form update_left_status
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM update_left_status .

  DATA: lv_sent_cnt TYPE i.

  LOOP AT gt_left ASSIGNING FIELD-SYMBOL(<fs_left>).

    CLEAR lv_sent_cnt.

*-- 해당 PR의 Tree로 이동된 건수 카운트
    LOOP AT gt_bottom TRANSPORTING NO FIELDS
         WHERE banfn = <fs_left>-banfn
           AND banfn IS NOT INITIAL.
      lv_sent_cnt = lv_sent_cnt + 1.
    ENDLOOP.

    <fs_left>-sel_cnt = lv_sent_cnt.

*-- 상태 아이콘 결정
    IF lv_sent_cnt = 0.
      <fs_left>-icon = icon_red_light.            " 빨강
    ELSEIF lv_sent_cnt < <fs_left>-item_cnt.
      <fs_left>-icon = icon_yellow_light.         " 노랑
    ELSE.
      <fs_left>-icon = icon_green_light.          " 초록
    ENDIF.

  ENDLOOP.

  PERFORM refresh_table USING go_left_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_tree_command
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> FCODE
*&---------------------------------------------------------------------*
FORM handle_tree_command  USING pv_fcode TYPE ui_func.

  CASE pv_fcode.
    WHEN 'CREATE'.
      PERFORM create_po.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_po
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_po .

  DATA : lt_vendor    TYPE TABLE OF ztc1mm0021-lifnr,
         lt_po_header TYPE TABLE OF ztc1mm0007,
         lt_po_item   TYPE TABLE OF ztc1mm0008,
         lt_purrsn    TYPE SORTED TABLE OF ztc1mm0026-purrsn WITH UNIQUE KEY table_line,
         lv_purrsn    TYPE ztc1mm0026-purrsn,
         lv_pur_cnt   TYPE i,
         ls_reason    LIKE gs_bottom,
         ls_po_header TYPE ztc1mm0007,
         ls_po_item   TYPE ztc1mm0008,
         lv_lifnr     TYPE ztc1mm0021-lifnr,
         lv_ebeln     TYPE ztc1mm0007-ebeln,
         lv_ebelp     TYPE ztc1mm0008-ebelp,
         lv_bsart     TYPE ztc1mm0025-bsart,
         lv_po_cnt    TYPE i,
         lv_answer(1).

  IF gt_bottom IS INITIAL.
    MESSAGE s413 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '[Taesan] 구매오더 생성'
      text_question         = '구매오더를 생성하시겠습니까?'
      text_button_1         = '예'
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = '아니오'
      icon_button_2         = 'ICON_CANCEL'
      display_cancel_button = ' '
    IMPORTING
      answer                = lv_answer.

  IF lv_answer NE '1'.
    EXIT.
  ENDIF.

  LOOP AT gt_bottom INTO gs_bottom WHERE banfn IS NOT INITIAL.
    APPEND gs_bottom-lifnr TO lt_vendor.
  ENDLOOP.

  SORT lt_vendor.
  DELETE ADJACENT DUPLICATES FROM lt_vendor.

*-- 벤더별 PO 생성
  LOOP AT lt_vendor INTO lv_lifnr.

*-- 해당 벤더 품목 중 ZEMG 있으면 ZEMG, 아니면 NB
    READ TABLE gt_bottom TRANSPORTING NO FIELDS
      WITH KEY lifnr = lv_lifnr bsart = 'ZEMG'.
    IF sy-subrc = 0.
      lv_bsart = 'ZEMG'.
    ELSE.
      lv_bsart = 'NB'.
    ENDIF.

*-- 해당 벤더 품목의 구매사유 종류 수집
    CLEAR : lt_purrsn, lv_purrsn, lv_pur_cnt.

    LOOP AT gt_bottom INTO ls_reason
      WHERE lifnr = lv_lifnr
        AND banfn IS NOT INITIAL.

      IF ls_reason-purrsn IS NOT INITIAL.
        INSERT ls_reason-purrsn INTO TABLE lt_purrsn.
      ENDIF.

    ENDLOOP.

    DESCRIBE TABLE lt_purrsn LINES lv_pur_cnt.

*-- EBELN(구매오더번호) 자동채번
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr             = 'PO'
        object                  = 'ZNRC1MM01'
      IMPORTING
        number                  = lv_ebeln
      EXCEPTIONS
        interval_not_found      = 1
        number_range_not_intern = 2
        object_not_found        = 3
        quantity_is_0           = 4
        quantity_is_not_1       = 5
        interval_overflow       = 6
        buffer_overflow         = 7
        OTHERS                  = 8.

*--- PO 헤더
    CLEAR ls_po_header.
    ls_po_header-ebeln = lv_ebeln.
    ls_po_header-bsart = lv_bsart.   "*-- ZEMG or NB
    ls_po_header-bukrs = '1000'.
    ls_po_header-bstyp = 'F'.
    ls_po_header-lifnr = lv_lifnr.
    ls_po_header-werks = 'TS00'.
    ls_po_header-bedat = sy-datum.
    ls_po_header-waers = 'KRW'.
    ls_po_header-statu = 'SV'.

*-- PO 헤더 비고(BIGO)에 구매사유 요약 저장
    IF lv_pur_cnt = 1.

      READ TABLE lt_purrsn INTO lv_purrsn INDEX 1.

      CASE lv_purrsn.
        WHEN 'MRP'.     ls_po_header-bigo = 'MRP 부족분 보충'.
        WHEN 'URGENT'.  ls_po_header-bigo = '긴급 구매 요청'.
        WHEN 'STOCK'.   ls_po_header-bigo = '안전재고/재주문점 보충'.
        WHEN 'NEWITEM'. ls_po_header-bigo = '신규 품목 도입'.
        WHEN 'REPLACE'. ls_po_header-bigo = '노후/불량 자재 교체'.
        WHEN 'ETC'.     ls_po_header-bigo = '기타구매'.
        WHEN OTHERS.    ls_po_header-bigo = lv_purrsn.
      ENDCASE.

    ELSEIF lv_pur_cnt > 1.

      ls_po_header-bigo = '복수 구매사유 포함'.

    ELSE.

      CLEAR ls_po_header-bigo.

    ENDIF.

    APPEND ls_po_header TO lt_po_header.

*--- PO 품목
    CLEAR lv_ebelp.

    LOOP AT gt_bottom INTO gs_bottom WHERE lifnr = lv_lifnr
                                       AND banfn IS NOT INITIAL.

      lv_ebelp = lv_ebelp + 10.

      CLEAR ls_po_item.
      ls_po_item-mandt = sy-mandt.
      ls_po_item-ebeln = lv_ebeln.
      ls_po_item-ebelp = lv_ebelp.
      ls_po_item-matnr = gs_bottom-matnr.
      ls_po_item-menge = gs_bottom-menge.
      ls_po_item-meins = gs_bottom-meins.
      ls_po_item-werks = 'TS00'.
      ls_po_item-lgort = 'SL10'.
      ls_po_item-pstyp = '0'.
      ls_po_item-netpr = gs_bottom-price.
      ls_po_item-waers = gs_bottom-waers.
      ls_po_item-peinh = 1.
      ls_po_item-banfn = gs_bottom-banfn.
      ls_po_item-bnfpo = gs_bottom-bnfpo.
      ls_po_item-wepos = 'X'.
      ls_po_item-repos = 'X'.
      ls_po_item-statu = 'SV'.
      ls_po_item-lfdat = gs_bottom-lfdat.

*--   INFNR 조회 : 자재+벤더 기준 오늘 유효한 계약 PIR
      CLEAR ls_po_item-infnr.
      SELECT SINGLE a~infnr
        FROM ztc1mm0021 AS a
        INNER JOIN ztc1mm0022 AS b ON b~infnr = a~infnr
       WHERE a~matnr        = @gs_bottom-matnr
         AND a~lifnr        = @lv_lifnr
         AND a~loekz        = @space
         AND b~loekz        = @space
         AND b~contract_flg = 'X'
         AND b~valid_from  <= @sy-datum
         AND b~valid_to    >= @sy-datum
        INTO @ls_po_item-infnr.

      APPEND ls_po_item TO lt_po_item.

*--- 원본 PR에 EBELN 업데이트 (역추적)
      UPDATE ztc1mm0026 SET ebeln = lv_ebeln
       WHERE banfn = gs_bottom-banfn
         AND bnfpo = gs_bottom-bnfpo.

    ENDLOOP.

    lv_po_cnt = lv_po_cnt + 1.

  ENDLOOP.

*-- DB INSERT
  INSERT ztc1mm0007 FROM TABLE lt_po_header.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'PO 헤더 저장 실패' TYPE 'E'.
    RETURN.
  ENDIF.

  INSERT ztc1mm0008 FROM TABLE lt_po_item.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'PO 품목 저장 실패' TYPE 'E'.
    RETURN.
  ENDIF.

  COMMIT WORK.

*-- 화면 초기화
  CLEAR : gt_bottom, gt_right.

  PERFORM build_bottom_tree.
  PERFORM refresh_table USING go_right_alv.

  PERFORM set_prdata.
  PERFORM refresh_table USING go_left_alv.

  PERFORM set_podata.
  PERFORM apply_curr_stat.
  PERFORM refresh_table USING go_po_alv.
  PERFORM set_card_html.

  MESSAGE |구매오더 { lv_po_cnt }건 생성 완료| TYPE 'S'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_toolbar_ing
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM handle_toolbar_ing  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

  CLEAR po_object->mt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_toolbar_appr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM handle_toolbar_appr  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

  CLEAR po_object->mt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_toolbar_rej
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM handle_toolbar_rej  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

  CLEAR po_object->mt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_podata
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_podata .

  DATA : lv_max_seqnr TYPE ztc1mm0027-seqnr.

  CLEAR : gt_appr, gt_wait, gt_ing, gt_done, gt_rej.

*-- 모든 PO 가져오기 (statu, bigo 포함)
  SELECT a~ebeln, a~lifnr, b~name1, a~waers, a~bedat, a~statu, a~bigo,
         COUNT( c~ebelp ) AS item_cnt,
         SUM( c~netpr * c~menge ) AS total_amt
    FROM ztc1mm0007 AS a
   INNER JOIN ztc1mm0012 AS b ON a~lifnr = b~lifnr
   INNER JOIN ztc1mm0008 AS c ON a~ebeln = c~ebeln
   WHERE ( @ztc1mm0007-ebeln IS INITIAL OR a~ebeln = @ztc1mm0007-ebeln )
     AND ( @ztc1mm0007-bsart IS INITIAL OR a~bsart = @ztc1mm0007-bsart )
     AND ( @ztc1mm0007-bedat IS INITIAL OR a~bedat >= @ztc1mm0007-bedat )
     AND ( @gv_bedat_to IS INITIAL OR a~bedat <= @gv_bedat_to )
     AND ( @ztc1mm0007-werks IS INITIAL OR a~werks = @ztc1mm0007-werks )
     AND ( @ztc1mm0007-lifnr IS INITIAL OR a~lifnr = @ztc1mm0007-lifnr )
     AND a~bsart <> 'ZAPC'
   GROUP BY a~ebeln, a~lifnr, b~name1, a~waers, a~bedat, a~statu, a~bigo
    INTO CORRESPONDING FIELDS OF TABLE @gt_appr.

*-- 결재유형 + 반려사유 아이콘 매핑
  LOOP AT gt_appr ASSIGNING FIELD-SYMBOL(<fs_appr>).
    CASE <fs_appr>-statu.
      WHEN 'FT'. <fs_appr>-appr_type_txt = '전결'.
      WHEN 'PD'. <fs_appr>-appr_type_txt = '일반결재'.
      WHEN OTHERS. CLEAR <fs_appr>-appr_type_txt.
    ENDCASE.

*-- 반려건이면 결재이력에서 최신 반려사유 조회
    IF <fs_appr>-statu = 'RJ'.

      CLEAR : <fs_appr>-rej_reason,
              <fs_appr>-rej_icon.

      CLEAR lv_max_seqnr.

      SELECT MAX( seqnr )
        FROM ztc1mm0027
       WHERE ebeln  = @<fs_appr>-ebeln
         AND action = 'RJ'
        INTO @lv_max_seqnr.

      IF lv_max_seqnr IS NOT INITIAL.
        SELECT SINGLE appr_comment
          FROM ztc1mm0027
         WHERE ebeln  = @<fs_appr>-ebeln
           AND seqnr  = @lv_max_seqnr
           AND action = 'RJ'
          INTO @<fs_appr>-rej_reason.
      ENDIF.

      IF <fs_appr>-rej_reason IS NOT INITIAL.
        <fs_appr>-rej_icon = icon_display_text.
      ENDIF.

    ENDIF.
  ENDLOOP.

*-- 상태별로 분리
  LOOP AT gt_appr INTO gs_appr.

    CASE gs_appr-statu.
      WHEN 'SV'.
        APPEND gs_appr TO gt_wait.
      WHEN 'PD' OR 'FT'.
        APPEND gs_appr TO gt_ing.
      WHEN 'AP'.
        APPEND gs_appr TO gt_done.
      WHEN 'RJ'.
        APPEND gs_appr TO gt_rej.
    ENDCASE.

  ENDLOOP.

*-- 정렬
*-- 전체     : 생성일 최신순 -> 오더번호
  SORT gt_appr BY bedat DESCENDING ebeln ASCENDING.

*-- 결재대기 : 오래된 건 -> 금액 큰 순
  SORT gt_wait BY bedat ASCENDING total_amt DESCENDING.

*-- 결재중   : 생성일 최신순
  SORT gt_ing  BY bedat DESCENDING ebeln ASCENDING.

*-- 승인완료 : 생성일 최신순
  SORT gt_done BY bedat DESCENDING ebeln ASCENDING.

*-- 반려     : 생성일 최신순
  SORT gt_rej  BY bedat DESCENDING ebeln ASCENDING.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_card_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_card_html .

  DATA : lt_html TYPE TABLE OF char255,
         lv_url  TYPE char255.

  DATA : lt_events TYPE cntl_simple_events,
         ls_event  TYPE cntl_simple_event.

*-- 카운트 갱신
  PERFORM count_po_status.

*-- 첫 호출 시 sapevent 핸들러 등록
  IF gv_card_init IS INITIAL AND go_card_html IS BOUND.

    CLEAR : lt_events, ls_event.

    ls_event-eventid    = cl_gui_html_viewer=>m_id_sapevent.
    ls_event-appl_event = abap_true.
    APPEND ls_event TO lt_events.

    CALL METHOD go_card_html->set_registered_events
      EXPORTING
        events = lt_events.

    SET HANDLER lcl_event_handler=>on_sapevent FOR go_card_html.

    gv_card_init = abap_true.

  ENDIF.

*-- HTML 빌드
  PERFORM build_card_html CHANGING lt_html.

  CALL METHOD go_card_html->load_data
    EXPORTING
      type                 = 'text'
      subtype              = 'html'
    IMPORTING
      assigned_url         = lv_url
    CHANGING
      data_table           = lt_html
    EXCEPTIONS
      dp_error_general     = 1
      dp_invalid_parameter = 2
      OTHERS               = 3.

  CALL METHOD go_card_html->show_url
    EXPORTING
      url                    = lv_url
    EXCEPTIONS
      cntl_error             = 1
      cnht_error_not_allowed = 2
      cnht_error_parameter   = 3
      dp_error_general       = 4
      OTHERS                 = 5.

  CALL METHOD cl_gui_cfw=>flush.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form count_po_status
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM count_po_status .

  CLEAR : gv_cnt_all, gv_cnt_wait, gv_cnt_ing, gv_cnt_done, gv_cnt_rej.

  gv_cnt_wait = lines( gt_wait ).
  gv_cnt_ing  = lines( gt_ing ).
  gv_cnt_done = lines( gt_done ).
  gv_cnt_rej  = lines( gt_rej ).

  gv_cnt_all = gv_cnt_wait + gv_cnt_ing + gv_cnt_done + gv_cnt_rej.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_user_command
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_UCOMM
*&---------------------------------------------------------------------*
FORM handle_user_command  USING pv_ucomm.

  CASE pv_ucomm.
    WHEN 'APPR_PO'.
      PERFORM po_approval.
    WHEN 'GO_APPR'.
      PERFORM go_approval.
    WHEN 'RE_PO'.
      PERFORM po_resubmit.
    WHEN 'MOD_PO'.
      PERFORM modify_po.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form po_approval
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM po_approval .

  DATA : lt_rows   TYPE lvc_t_row,
         ls_row    TYPE lvc_s_row,
         lv_ebeln  TYPE ztc1mm0007-ebeln,
         lv_total  TYPE p LENGTH 13 DECIMALS 2,
         lv_stat   TYPE ztc1mm0007-statu,
         lv_action TYPE ztc1mm0027-action,
         lv_cmt    TYPE ztc1mm0027-appr_comment,
         lv_amt    TYPE c LENGTH 30,
         lv_cnt    TYPE i,
         lv_ft     TYPE i,
         lv_pd     TYPE i.

  IF gv_can_appr = abap_false.
    MESSAGE '결재 상신 권한이 없습니다' TYPE 'I'.
    RETURN.
  ENDIF.

  CALL METHOD go_po_alv->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  IF lt_rows IS INITIAL.
    MESSAGE s417 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT lt_rows INTO ls_row.
    READ TABLE gt_po_list INTO gs_appr INDEX ls_row-index.
    CHECK sy-subrc = 0.
    lv_ebeln = gs_appr-ebeln.

*-- 금액 계산 → FT/PD 분기
    PERFORM calc_po_total    USING    lv_ebeln
                             CHANGING lv_total.
    PERFORM decide_appr_type USING    lv_total
                             CHANGING lv_stat.

*-- STATU 변경
    UPDATE ztc1mm0007 SET statu = @lv_stat
     WHERE ebeln = @lv_ebeln.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    UPDATE ztc1mm0008 SET statu = @lv_stat
     WHERE ebeln = @lv_ebeln.

*-- 통화 자릿수 반영한 금액 문자열 (KRW=정수표기)
    CLEAR lv_amt.
    WRITE lv_total TO lv_amt CURRENCY gs_appr-waers.
    CONDENSE lv_amt.

    lv_action = 'SB'.
    lv_cmt    = COND #( WHEN lv_stat = 'FT'
                        THEN |전결 상신 (총 { lv_amt } { gs_appr-waers })|
                        ELSE |일반결재 상신 (총 { lv_amt } { gs_appr-waers })| ).

    PERFORM insert_approval_log
      USING lv_ebeln 'REQ' lv_action lv_cmt.

    IF lv_stat = 'FT'.
      lv_ft = lv_ft + 1.
    ELSE.
      lv_pd = lv_pd + 1.
    ENDIF.
    lv_cnt = lv_cnt + 1.
  ENDLOOP.

  COMMIT WORK.

*-- 화면 갱신
  PERFORM set_podata.
  PERFORM apply_curr_stat.
  PERFORM set_po_grid_title.
  CALL METHOD go_po_alv->set_frontend_layout EXPORTING is_layout = gs_layout_po.
  PERFORM refresh_table USING go_po_alv.
  PERFORM set_card_html.

  MESSAGE |결재요청 { lv_cnt }건 완료 (FT { lv_ft } / PD { lv_pd })| TYPE 'S'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form lock
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM lock .

*-- HR 마스터에서 로그인 사용자 직급 조회
  SELECT SINGLE zgrade
    FROM ztc1hr0001
   WHERE uname = @sy-uname
    INTO @gv_my_grade.

*-- HR 마스터에 등록되지 않은 사용자는 진입 차단
  IF sy-subrc <> 0.
    LEAVE TO TRANSACTION 'SESSION_MANAGER'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_appr_auth
*&   직급별 결재요청(상신) 권한 판정
*&---------------------------------------------------------------------*
FORM set_appr_auth .

  CLEAR gv_can_appr.

*-- 결재요청(상신) 가능 직급 : 사원/대리/차장/책임/부장
*-- 고문은 상신 불가
  CASE gv_my_grade.
    WHEN '사원' OR '대리' OR '차장' OR '책임' OR '부장'.
      gv_can_appr = abap_true.
    WHEN OTHERS.
      gv_can_appr = abap_false.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_card_click
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ACTION
*&---------------------------------------------------------------------*
FORM handle_card_click  USING p_action.

*-- 반려 사유 팝업 닫기
  IF p_action = 'CLOSE_BIGO'.
    CALL METHOD cl_gui_cfw=>set_new_ok_code
      EXPORTING
        new_code = 'BIGO_CLOSE'.
    RETURN.
  ENDIF.

*-- 상세 닫기 버튼
  IF p_action = 'CLOSE_DETAIL'.
    PERFORM close_po_detail.
    RETURN.
  ENDIF.

*-- 카드 전환
  CASE p_action.
    WHEN 'CARD_ALL'.
      gv_curr_stat = 'ALL'.
      gt_po_list   = gt_appr.
    WHEN 'CARD_WAIT'.
      gv_curr_stat = 'WAIT'.
      gt_po_list   = gt_wait.
    WHEN 'CARD_ING'.
      gv_curr_stat = 'ING'.
      gt_po_list   = gt_ing.
    WHEN 'CARD_DONE'.
      gv_curr_stat = 'DONE'.
      gt_po_list   = gt_done.
    WHEN 'CARD_REJ'.
      gv_curr_stat = 'REJ'.
      gt_po_list   = gt_rej.
    WHEN OTHERS.
      RETURN.
  ENDCASE.

*-- 제목 변경
  PERFORM set_po_grid_title.

*-- 상세 닫기
  PERFORM close_po_detail.

*-- 반려 카드일 때만 REJ_ICON 컬럼 표시
  PERFORM toggle_bigo_column.

*-- ALV 레이아웃 반영
  CALL METHOD go_po_alv->set_frontend_layout
    EXPORTING
      is_layout = gs_layout_po.

  PERFORM refresh_table USING go_po_alv.

  CALL METHOD go_po_alv->set_toolbar_interactive.

  PERFORM set_card_html.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form apply_curr_stat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM apply_curr_stat .

  CASE gv_curr_stat.
    WHEN 'ALL'.  gt_po_list = gt_appr.
    WHEN 'WAIT'. gt_po_list = gt_wait.
    WHEN 'ING'.  gt_po_list = gt_ing.
    WHEN 'DONE'. gt_po_list = gt_done.
    WHEN 'REJ'.  gt_po_list = gt_rej.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form close_po_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM close_po_detail .

  IF gv_detail_open IS NOT INITIAL.

    CALL METHOD go_po_splitter->set_column_width
      EXPORTING
        id    = 1
        width = 100.

    gv_detail_open = abap_false.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form render_detail_header
*&---------------------------------------------------------------------*
FORM render_detail_header USING ps_hdr TYPE ztc1mm0007.

  DATA : lt_html   TYPE TABLE OF char255,
         lv_url    TYPE char255,
         lv_name   TYPE ztc1mm0012-name1,
         lv_stxt   TYPE char20,
         lv_bg     TYPE char20,
         lv_fg     TYPE char20,
         lv_total  TYPE p LENGTH 13 DECIMALS 2,
         lv_itmcnt TYPE i,
         lv_totstr TYPE string,
         lv_char   TYPE c LENGTH 30.

*-- 벤더명
  SELECT SINGLE name1
    FROM ztc1mm0012
   WHERE lifnr = @ps_hdr-lifnr
    INTO @lv_name.

*-- 품목수/총금액
  SELECT COUNT(*) AS cnt,
         SUM( netpr * menge ) AS amt
    FROM ztc1mm0008
   WHERE ebeln = @ps_hdr-ebeln
    INTO ( @lv_itmcnt, @lv_total ).

*-- 통화 자릿수 정확히
  WRITE lv_total TO lv_char CURRENCY ps_hdr-waers.
  CONDENSE lv_char.
  lv_totstr = lv_char.

*-- 상태
  CASE ps_hdr-statu.
    WHEN 'SV'.
      lv_stxt = '결재 대기'.
      lv_bg = '#FFF6D9'.
      lv_fg = '#B58A00'.
    WHEN 'PD' OR 'FT'.
      lv_stxt = '결재 진행 중'.
      lv_bg = '#E3EEFB'.
      lv_fg = '#2A5A8A'.
    WHEN 'AP'.
      lv_stxt = '승인 완료'.
      lv_bg = '#E8F3DB'.
      lv_fg = '#5A7A2A'.
    WHEN 'RJ'.
      lv_stxt = '반려'.
      lv_bg = '#FBE6E6'.
      lv_fg = '#A03A3A'.
    WHEN OTHERS.
      lv_stxt = ps_hdr-statu.
      lv_bg = '#EEE'.
      lv_fg = '#555'.
  ENDCASE.

  APPEND '<html><head><style>html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;box-sizing:border-box;}*{box-sizing:border-box;}</style></head>' TO lt_html.
  APPEND '<body scroll="no" style="font-family:Malgun Gothic,Arial;font-size:11px;margin:0;padding:0;background:#DFEBF5;overflow:hidden;">' TO lt_html.

  APPEND '<div style="width:100%;height:100%;background:#FFFFFF;border:1px solid #CFD8E3;border-radius:4px;overflow:hidden;">' TO lt_html.

*-- 타이틀 바
  APPEND '<div style="height:22px;padding:3px 10px;background:#E8EEF5;border-bottom:1px solid #D5DEEA;display:flex;justify-content:space-between;align-items:center;">' TO lt_html.
  APPEND '<div style="color:#3D4A5A;font-size:10px;font-weight:600;letter-spacing:0.2px;">구매오더 상세 정보</div>' TO lt_html.
  APPEND '<a href="sapevent:CLOSE_DETAIL" style="color:#7A8896;text-decoration:none;font-size:11px;">✕</a>' TO lt_html.
  APPEND '</div>' TO lt_html.

*-- PO NUMBER 영역
  APPEND '<div style="height:52px;padding:5px 14px;background:linear-gradient(180deg,#EAF4FF,#F8FBFF);border-bottom:1px solid #DCE5EF;display:flex;justify-content:space-between;align-items:center;">' TO lt_html.
  APPEND |<div><div style="font-size:9px;color:#5E7FA6;letter-spacing:1px;font-weight:700;">구매오더 NUMBER</div>| TO lt_html.
  APPEND |<div style="font-size:22px;font-weight:800;color:#0B63CE;margin-top:1px;letter-spacing:0.3px;line-height:24px;">{ ps_hdr-ebeln }</div></div>| TO lt_html.
  APPEND |<span style="display:inline-block;padding:4px 13px;border-radius:12px;background:{ lv_bg };color:{ lv_fg };font-weight:700;font-size:10px;">{ lv_stxt }</span>| TO lt_html.
  APPEND '</div>' TO lt_html.

*-- 정보 그리드
  APPEND '<table style="width:100%;border-collapse:collapse;table-layout:fixed;">' TO lt_html.

  APPEND '<tr style="height:25px;">' TO lt_html.
  APPEND |<td style="width:18%;padding:1px 9px;background:#EEF3F8;color:#607083;border-right:1px solid #E0E6EE;border-bottom:1px solid #E0E6EE;font-weight:700;font-size:10px;letter-spacing:0.3px;">공급업체</td>| TO lt_html.
  APPEND |<td style="width:32%;padding:1px 9px;border-right:1px solid #E0E6EE;border-bottom:1px solid #E0E6EE;color:#18344F;font-size:12px;font-weight:600;">{ ps_hdr-lifnr } / { lv_name }</td>| TO lt_html.
  APPEND |<td style="width:18%;padding:1px 9px;background:#EEF3F8;color:#607083;border-right:1px solid #E0E6EE;border-bottom:1px solid #E0E6EE;font-weight:700;font-size:10px;letter-spacing:0.3px;">구매오더 생성일</td>| TO lt_html.
  APPEND |<td style="width:32%;padding:1px 9px;border-bottom:1px solid #E0E6EE;color:#18344F;font-size:12px;font-weight:600;">{ ps_hdr-bedat+0(4) }-{ ps_hdr-bedat+4(2) }-{ ps_hdr-bedat+6(2) }</td>| TO lt_html.
  APPEND '</tr>' TO lt_html.

  APPEND '<tr style="height:25px;">' TO lt_html.
  APPEND |<td style="padding:1px 9px;background:#EEF3F8;color:#607083;border-right:1px solid #E0E6EE;border-bottom:1px solid #E0E6EE;font-weight:700;font-size:10px;letter-spacing:0.3px;">품목 수</td>| TO lt_html.
  APPEND |<td style="padding:1px 9px;border-right:1px solid #E0E6EE;border-bottom:1px solid #E0E6EE;color:#18344F;font-size:12px;font-weight:600;">{ lv_itmcnt } 건</td>| TO lt_html.
  APPEND |<td style="padding:1px 9px;background:#EEF3F8;color:#607083;border-right:1px solid #E0E6EE;border-bottom:1px solid #E0E6EE;font-weight:700;font-size:10px;letter-spacing:0.3px;">통화</td>| TO lt_html.
  APPEND |<td style="padding:1px 9px;border-bottom:1px solid #E0E6EE;color:#18344F;font-size:12px;font-weight:600;">{ ps_hdr-waers }</td>| TO lt_html.
  APPEND '</tr>' TO lt_html.

*-- 총 발주 금액: 한 줄 통일
  APPEND '<tr style="height:30px;">' TO lt_html.
  APPEND |<td colspan="4" style="padding:4px 12px;background:linear-gradient(135deg,#EAF5FF,#DCEEFF);color:#0B4F8A;font-weight:800;font-size:14px;border-top:1px solid #C8DDF2;white-space:nowrap;">| TO lt_html.
  APPEND |<span style="float:left;">총 발주 금액</span>| TO lt_html.
  APPEND |<span style="float:right;font-size:17px;font-weight:800;color:#0B4F8A;">{ lv_totstr } { ps_hdr-waers }</span>| TO lt_html.
  APPEND '</td>' TO lt_html.
  APPEND '</tr>' TO lt_html.

  APPEND '</table>' TO lt_html.
  APPEND '</div></body></html>' TO lt_html.

  CALL METHOD go_detail_h_html->load_data
    IMPORTING
      assigned_url = lv_url
    CHANGING
      data_table   = lt_html.

  CALL METHOD go_detail_h_html->show_url
    EXPORTING
      url = lv_url.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form build_card_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LT_HTML
*&---------------------------------------------------------------------*
*FORM build_card_html  CHANGING pt_html TYPE STANDARD TABLE..
*  DATA : lv_act_all  TYPE char80,
*         lv_act_wait TYPE char80,
*         lv_act_ing  TYPE char80,
*         lv_act_done TYPE char80,
*         lv_act_rej  TYPE char80.
*
**-- 현재 선택 카드 강조
*  CASE gv_curr_stat.
*    WHEN 'ALL'.  lv_act_all  = 'border:2px solid #4A6FA5;box-shadow:0 2px 8px rgba(74,111,165,0.20);'.
*    WHEN 'WAIT'. lv_act_wait = 'border:2px solid #D4A017;box-shadow:0 2px 8px rgba(212,160,23,0.20);'.
*    WHEN 'ING'.  lv_act_ing  = 'border:2px solid #4A6FA5;box-shadow:0 2px 8px rgba(74,111,165,0.20);'.
*    WHEN 'DONE'. lv_act_done = 'border:2px solid #6B9A3A;box-shadow:0 2px 8px rgba(107,154,58,0.20);'.
*    WHEN 'REJ'.  lv_act_rej  = 'border:2px solid #B53A3A;box-shadow:0 2px 8px rgba(181,58,58,0.20);'.
*  ENDCASE.
*
*  REFRESH pt_html.
*
*  APPEND '<html><head><style>' TO pt_html.
*  APPEND 'html,body{margin:0;padding:0;background:#DFEBF5;overflow:hidden;}' TO pt_html.
*  APPEND '.card{display:block;padding:10px 12px;border-radius:8px;text-decoration:none;background:#FFFFFF;border:1px solid #D5DEEA;transition:all .15s;cursor:pointer;}' TO pt_html.
*  APPEND '.card:hover{box-shadow:0 2px 6px rgba(0,0,0,0.12);transform:translateY(-1px);}' TO pt_html.
*  APPEND '.row{display:flex;align-items:center;gap:10px;}' TO pt_html.
*  APPEND '.ico{width:36px;height:36px;border-radius:8px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}' TO pt_html.
*  APPEND '.lbl{font-size:11px;color:#6A7585;line-height:1.1;font-weight:500;}' TO pt_html.
*  APPEND '.cnt{font-size:16px;font-weight:700;line-height:1.2;margin-top:3px;}' TO pt_html.
*  APPEND '.unit{font-size:11px;font-weight:600;margin-left:3px;opacity:0.75;}' TO pt_html.
*  APPEND '</style></head>' TO pt_html.
*
*  APPEND '<body scroll="no" style="font-family:Malgun Gothic,Arial;padding:6px;">' TO pt_html.
*  APPEND '<table style="width:100%;border-collapse:separate;border-spacing:8px;table-layout:fixed;"><tr>' TO pt_html.
*
**-- 전체
*  APPEND |<td><a href="sapevent:CARD_ALL" class="card" style="{ lv_act_all }">| TO pt_html.
*  APPEND '<div class="row">' TO pt_html.
*  APPEND '<div class="ico" style="background:#EAF1FA;color:#4A6FA5;">' TO pt_html.
*  APPEND '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2">' TO pt_html.
*  APPEND '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>' TO pt_html.
*  APPEND '<polyline points="14 2 14 8 20 8"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="16" y2="17"/></svg></div>' TO pt_html.
*  APPEND |<div><div class="lbl">전체</div><div class="cnt" style="color:#1F3A52;">{ gv_cnt_all }<span class="unit">건</span></div></div>| TO pt_html.
*  APPEND '</div></a></td>' TO pt_html.
*
**-- 결재 대기
*  APPEND |<td><a href="sapevent:CARD_WAIT" class="card" style="{ lv_act_wait }">| TO pt_html.
*  APPEND '<div class="row">' TO pt_html.
*  APPEND '<div class="ico" style="background:#FFF6D9;color:#B58A00;">' TO pt_html.
*  APPEND '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2">' TO pt_html.
*  APPEND '<circle cx="12" cy="12" r="9"/><polyline points="12 7 12 12 15 14"/></svg></div>' TO pt_html.
*  APPEND |<div><div class="lbl">결재 대기</div><div class="cnt" style="color:#6A5200;">{ gv_cnt_wait }<span class="unit">건</span></div></div>| TO pt_html.
*  APPEND '</div></a></td>' TO pt_html.
*
**-- 결재 진행 중
*  APPEND |<td><a href="sapevent:CARD_ING" class="card" style="{ lv_act_ing }">| TO pt_html.
*  APPEND '<div class="row">' TO pt_html.
*  APPEND '<div class="ico" style="background:#E3EEFB;color:#2A5A8A;">' TO pt_html.
*  APPEND '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2">' TO pt_html.
*  APPEND '<path d="M6 2h12M6 22h12M6 2v4l6 6 6-6V2M6 22v-4l6-6 6 6v4"/></svg></div>' TO pt_html.
*  APPEND |<div><div class="lbl">결재 진행 중</div><div class="cnt" style="color:#1A3A5A;">{ gv_cnt_ing }<span class="unit">건</span></div></div>| TO pt_html.
*  APPEND '</div></a></td>' TO pt_html.
*
**-- 승인 완료
*  APPEND |<td><a href="sapevent:CARD_DONE" class="card" style="{ lv_act_done }">| TO pt_html.
*  APPEND '<div class="row">' TO pt_html.
*  APPEND '<div class="ico" style="background:#E8F3DB;color:#5A7A2A;">' TO pt_html.
*  APPEND '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2">' TO pt_html.
*  APPEND '<circle cx="12" cy="12" r="9"/><polyline points="8 12 11 15 16 9"/></svg></div>' TO pt_html.
*  APPEND |<div><div class="lbl">승인 완료</div><div class="cnt" style="color:#3A5A1A;">{ gv_cnt_done }<span class="unit">건</span></div></div>| TO pt_html.
*  APPEND '</div></a></td>' TO pt_html.
*
**-- 반려
*  APPEND |<td><a href="sapevent:CARD_REJ" class="card" style="{ lv_act_rej }">| TO pt_html.
*  APPEND '<div class="row">' TO pt_html.
*  APPEND '<div class="ico" style="background:#FBE6E6;color:#A03A3A;">' TO pt_html.
*  APPEND '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2">' TO pt_html.
*  APPEND '<circle cx="12" cy="12" r="9"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg></div>' TO pt_html.
*  APPEND |<div><div class="lbl">반려</div><div class="cnt" style="color:#7A2020;">{ gv_cnt_rej }<span class="unit">건</span></div></div>| TO pt_html.
*  APPEND '</div></a></td>' TO pt_html.
*
*  APPEND '</tr></table></body></html>' TO pt_html.
*
*ENDFORM.
  FORM build_card_html  CHANGING pt_html TYPE STANDARD TABLE..

  DATA : lv_cnt_all_s  TYPE string,
         lv_cnt_wait_s TYPE string,
         lv_cnt_ing_s  TYPE string,
         lv_cnt_done_s TYPE string,
         lv_cnt_rej_s  TYPE string.

*-- 현재 선택 카드별 active 클래스
  DATA : lv_act_all  TYPE string,
         lv_act_wait TYPE string,
         lv_act_ing  TYPE string,
         lv_act_done TYPE string,
         lv_act_rej  TYPE string.

*-- 숫자 → 문자열
  lv_cnt_all_s  = gv_cnt_all.  CONDENSE lv_cnt_all_s.
  lv_cnt_wait_s = gv_cnt_wait. CONDENSE lv_cnt_wait_s.
  lv_cnt_ing_s  = gv_cnt_ing.  CONDENSE lv_cnt_ing_s.
  lv_cnt_done_s = gv_cnt_done. CONDENSE lv_cnt_done_s.
  lv_cnt_rej_s  = gv_cnt_rej.  CONDENSE lv_cnt_rej_s.

*-- 현재 선택 카드 강조 (active 클래스 부여)
  CASE gv_curr_stat.
    WHEN 'ALL'.  lv_act_all  = ' sel-all'.
    WHEN 'WAIT'. lv_act_wait = ' sel-wait'.
    WHEN 'ING'.  lv_act_ing  = ' sel-ing'.
    WHEN 'DONE'. lv_act_done = ' sel-done'.
    WHEN 'REJ'.  lv_act_rej  = ' sel-rej'.
  ENDCASE.

  REFRESH pt_html.

**********************************************************************
* HTML HEAD / STYLE (CO02 톤 + 슬림 가로 5카드)
* - 카드 띠를 얇게(한 줄 컴팩트)
* - 아이콘 / 라벨+건수를 한 줄에 가로 배치
* - 클릭/강조 동작은 기존 그대로 (sapevent:CARD_xxx)
**********************************************************************
  APPEND '<html><head><meta charset="UTF-8"><style>' TO pt_html.

  APPEND 'html,body{font-family:Arial,"Malgun Gothic",sans-serif;font-size:11px;background:#DFEAF2;margin:0;padding:0;color:#243746;width:100%;height:100%;overflow:hidden;}' TO pt_html.

  APPEND '.wrap{height:100%;box-sizing:border-box;padding:3px 5px;overflow:hidden;}' TO pt_html.

*-- 카드 가로 배열 (슬림)
  APPEND '.cards{display:flex;gap:5px;align-items:stretch;height:100%;overflow:hidden;}' TO pt_html.

*-- 카드 공통 (CO02 section 톤)
  APPEND '.card{flex:1;min-width:100px;display:block;text-decoration:none;border:1px solid #9EB8CA;background:#F8FBFD;box-sizing:border-box;overflow:hidden;cursor:pointer;}' TO pt_html.
  APPEND '.card:hover{filter:brightness(.985);box-shadow:0 1px 3px rgba(0,0,0,.10);}' TO pt_html.

*-- 카드 한 줄 레이아웃 (작은 아이콘 / 라벨 / 건수)
  APPEND '.card-row{display:flex;align-items:center;gap:7px;padding:4px 9px;box-sizing:border-box;height:100%;}' TO pt_html.
  APPEND '.ico{width:22px;height:22px;border-radius:5px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}' TO pt_html.
  APPEND '.txt{flex:1;min-width:0;display:flex;align-items:baseline;gap:6px;}' TO pt_html.
  APPEND '.lbl{font-size:10px;color:#465F72;font-weight:900;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}' TO pt_html.
  APPEND '.cnt{font-size:14px;font-weight:900;white-space:nowrap;}' TO pt_html.
  APPEND '.unit{font-size:9px;font-weight:700;margin-left:2px;opacity:.75;}' TO pt_html.

*-- 선택 강조 (테두리 + 옅은 배경)
  APPEND '.sel-all{border:2px solid #4A6FA5;background:#F2F7FC;}' TO pt_html.
  APPEND '.sel-wait{border:2px solid #D4A017;background:#FFFCF2;}' TO pt_html.
  APPEND '.sel-ing{border:2px solid #4A6FA5;background:#F2F7FC;}' TO pt_html.
  APPEND '.sel-done{border:2px solid #6B9A3A;background:#F6FBF0;}' TO pt_html.
  APPEND '.sel-rej{border:2px solid #B53A3A;background:#FDF4F4;}' TO pt_html.

  APPEND '</style></head>' TO pt_html.

**********************************************************************
* BODY
**********************************************************************
  APPEND '<body scroll="no">' TO pt_html.
  APPEND '<div class="wrap"><div class="cards">' TO pt_html.

*-- 전체
  APPEND |<a href="sapevent:CARD_ALL" class="card{ lv_act_all }">| TO pt_html.
  APPEND '<div class="card-row">' TO pt_html.
  APPEND '<div class="ico" style="background:#EAF1FA;color:#4A6FA5;">' TO pt_html.
  APPEND '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2">' TO pt_html.
  APPEND '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>' TO pt_html.
  APPEND '<polyline points="14 2 14 8 20 8"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="16" y2="17"/></svg></div>' TO pt_html.
  APPEND '<div class="txt"><span class="lbl">전체</span>' TO pt_html.
  APPEND |<span class="cnt" style="color:#1F3A52;">{ lv_cnt_all_s }<span class="unit">건</span></span></div>| TO pt_html.
  APPEND '</div></a>' TO pt_html.

*-- 결재 대기
  APPEND |<a href="sapevent:CARD_WAIT" class="card{ lv_act_wait }">| TO pt_html.
  APPEND '<div class="card-row">' TO pt_html.
  APPEND '<div class="ico" style="background:#FFF6D9;color:#B58A00;">' TO pt_html.
  APPEND '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2">' TO pt_html.
  APPEND '<circle cx="12" cy="12" r="9"/><polyline points="12 7 12 12 15 14"/></svg></div>' TO pt_html.
  APPEND '<div class="txt"><span class="lbl">결재 대기</span>' TO pt_html.
  APPEND |<span class="cnt" style="color:#6A5200;">{ lv_cnt_wait_s }<span class="unit">건</span></span></div>| TO pt_html.
  APPEND '</div></a>' TO pt_html.

*-- 결재 진행 중
  APPEND |<a href="sapevent:CARD_ING" class="card{ lv_act_ing }">| TO pt_html.
  APPEND '<div class="card-row">' TO pt_html.
  APPEND '<div class="ico" style="background:#E3EEFB;color:#2A5A8A;">' TO pt_html.
  APPEND '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2">' TO pt_html.
  APPEND '<path d="M6 2h12M6 22h12M6 2v4l6 6 6-6V2M6 22v-4l6-6 6 6v4"/></svg></div>' TO pt_html.
  APPEND '<div class="txt"><span class="lbl">결재 진행 중</span>' TO pt_html.
  APPEND |<span class="cnt" style="color:#1A3A5A;">{ lv_cnt_ing_s }<span class="unit">건</span></span></div>| TO pt_html.
  APPEND '</div></a>' TO pt_html.

*-- 승인 완료
  APPEND |<a href="sapevent:CARD_DONE" class="card{ lv_act_done }">| TO pt_html.
  APPEND '<div class="card-row">' TO pt_html.
  APPEND '<div class="ico" style="background:#E8F3DB;color:#5A7A2A;">' TO pt_html.
  APPEND '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2">' TO pt_html.
  APPEND '<circle cx="12" cy="12" r="9"/><polyline points="8 12 11 15 16 9"/></svg></div>' TO pt_html.
  APPEND '<div class="txt"><span class="lbl">승인 완료</span>' TO pt_html.
  APPEND |<span class="cnt" style="color:#3A5A1A;">{ lv_cnt_done_s }<span class="unit">건</span></span></div>| TO pt_html.
  APPEND '</div></a>' TO pt_html.

*-- 반려
  APPEND |<a href="sapevent:CARD_REJ" class="card{ lv_act_rej }">| TO pt_html.
  APPEND '<div class="card-row">' TO pt_html.
  APPEND '<div class="ico" style="background:#FBE6E6;color:#A03A3A;">' TO pt_html.
  APPEND '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2">' TO pt_html.
  APPEND '<circle cx="12" cy="12" r="9"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg></div>' TO pt_html.
  APPEND '<div class="txt"><span class="lbl">반려</span>' TO pt_html.
  APPEND |<span class="cnt" style="color:#7A2020;">{ lv_cnt_rej_s }<span class="unit">건</span></span></div>| TO pt_html.
  APPEND '</div></a>' TO pt_html.

  APPEND '</div></div></body></html>' TO pt_html.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_double_click_po
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_ROW
*&---------------------------------------------------------------------*
FORM handle_double_click_po  USING ps_row TYPE lvc_s_row.

  FIELD-SYMBOLS : <fs_po> LIKE LINE OF gt_po_list.

*-- 기존 색 초기화
  LOOP AT gt_po_list ASSIGNING <fs_po>.
    CLEAR <fs_po>-linecolor.
  ENDLOOP.

*-- 선택행 색칠
  READ TABLE gt_po_list ASSIGNING <fs_po> INDEX ps_row-index.
  CHECK sy-subrc = 0.

  <fs_po>-linecolor = 'C300'.
  gs_appr = <fs_po>.

  PERFORM refresh_table USING go_po_alv.
  PERFORM show_po_detail USING gs_appr-ebeln.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_po_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_APPR_EBELN
*&---------------------------------------------------------------------*
FORM show_po_detail  USING pv_ebeln TYPE ztc1mm0007-ebeln.

  DATA : ls_hdr    TYPE ztc1mm0007,
         lt_events TYPE cntl_simple_events,
         ls_event  TYPE cntl_simple_event.

*-- PO 헤더 조회
  SELECT SINGLE *
    FROM ztc1mm0007
   WHERE ebeln = @pv_ebeln
    INTO @ls_hdr.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

*-- 헤더 HTML Viewer 첫 호출 시 SAPEVENT 등록
  IF gv_dtl_init IS INITIAL AND go_detail_h_html IS BOUND.

    CLEAR : lt_events, ls_event.

    ls_event-eventid    = cl_gui_html_viewer=>m_id_sapevent.
    ls_event-appl_event = abap_true.
    APPEND ls_event TO lt_events.

    CALL METHOD go_detail_h_html->set_registered_events
      EXPORTING
        events = lt_events.

    SET HANDLER lcl_event_handler=>on_sapevent FOR go_detail_h_html.

    gv_dtl_init = abap_true.

  ENDIF.

*-- 헤더 HTML 출력
  PERFORM render_detail_header USING ls_hdr.

*-- PO 아이템 조회
  CLEAR gt_detail_item.

  SELECT a~ebelp,
         a~matnr,
         b~maktx,
         a~menge,
         a~meins,
         a~netpr,
         a~lfdat
    FROM ztc1mm0008 AS a
    LEFT JOIN ztc1mm0026 AS b ON  a~banfn = b~banfn
                              AND a~bnfpo = b~bnfpo
   WHERE a~ebeln = @pv_ebeln
    INTO CORRESPONDING FIELDS OF TABLE @gt_detail_item.

*-- 금액/통화 계산
  LOOP AT gt_detail_item ASSIGNING FIELD-SYMBOL(<fs_dtl>).
    <fs_dtl>-total = <fs_dtl>-menge * <fs_dtl>-netpr.
    <fs_dtl>-waers = ls_hdr-waers.
  ENDLOOP.

*-- 상세 품목 ALV 갱신
  PERFORM refresh_table USING go_detail_i_alv.

*-- splitter 펼치기: 좌 40%, 우 60%
  IF gv_detail_open IS INITIAL.

    CALL METHOD go_po_splitter->set_column_width
      EXPORTING
        id    = 1
        width = 40.

    gv_detail_open = abap_true.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_toolbar_po
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM handle_toolbar_po  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

  CLEAR po_object->mt_toolbar.

  CASE gv_curr_stat.
*-- 선택한 PO결재상신 (행 선택 후 클릭 -> 피오리 이동)
    WHEN 'WAIT'.
*-- 결재요청 권한 직급만 버튼 노출
      IF gv_can_appr = abap_true.
        CLEAR gs_button.
        gs_button-function  = 'APPR_PO'.
        gs_button-icon      = icon_export.
        gs_button-text      = ' 결재요청 '.
        gs_button-quickinfo = '선택한 PO 결재 상신'.
        APPEND gs_button TO po_object->mt_toolbar.
      ENDIF.

*-- 결재 중 (피오리 이동)
    WHEN 'ING'.
      CLEAR gs_button.
      gs_button-function  = 'GO_APPR'.
      gs_button-icon      = icon_system_paste.
      gs_button-text      = ' 결재현황 '.
      gs_button-quickinfo = '결재 페이지 이동'.
      APPEND gs_button TO po_object->mt_toolbar.

*-- 재상신
    WHEN 'REJ'.
      CLEAR gs_button.
      gs_button-function  = 'RE_PO'.
      gs_button-icon      = icon_intensify.
      gs_button-text      = ' 재상신 '.
      gs_button-quickinfo = '반려 PO 재상신'.
      APPEND gs_button TO po_object->mt_toolbar.

      CLEAR gs_button.
      gs_button-function  = 'MOD_PO'.
      gs_button-icon      = icon_change.
      gs_button-text      = ' 수정 '.
      gs_button-quickinfo = '반려 PO 수정'.
      APPEND gs_button TO po_object->mt_toolbar.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form po_resubmit
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM po_resubmit .

  DATA : lt_rows   TYPE lvc_t_row,
         ls_row    TYPE lvc_s_row,
         lv_ebeln  TYPE ztc1mm0007-ebeln,
         lv_total  TYPE p LENGTH 13 DECIMALS 2,
         lv_stat   TYPE ztc1mm0007-statu,
         lv_cmt    TYPE ztc1mm0027-appr_comment,
         lv_amt    TYPE c LENGTH 30,
         lv_ans(1).

  CALL METHOD go_po_alv->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  CASE lines( lt_rows ).
    WHEN 0.
      MESSAGE s417 DISPLAY LIKE 'E'. RETURN.
    WHEN 1.
      READ TABLE lt_rows INTO ls_row INDEX 1.
      READ TABLE gt_po_list INTO gs_appr INDEX ls_row-index.
      CHECK sy-subrc = 0.
      lv_ebeln = gs_appr-ebeln.
    WHEN OTHERS.
      MESSAGE '한 건씩 재상신 가능합니다' TYPE 'I'. RETURN.
  ENDCASE.

*-- 금액 재계산 → FT/PD 재분기
  PERFORM calc_po_total    USING lv_ebeln CHANGING lv_total.
  PERFORM decide_appr_type USING lv_total CHANGING lv_stat.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '[Taesan] 재상신'
      text_question         = |PO { lv_ebeln } 를 { COND #( WHEN lv_stat = 'FT' THEN '전결' ELSE '일반결재' ) }로 재상신하시겠습니까?|
      text_button_1         = '예'
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = '아니오'
      icon_button_2         = 'ICON_CANCEL'
      display_cancel_button = ' '
    IMPORTING
      answer                = lv_ans.
  CHECK lv_ans = '1'.

  UPDATE ztc1mm0007 SET statu = @lv_stat
   WHERE ebeln = @lv_ebeln.
  IF sy-subrc <> 0.
    MESSAGE 'PO 상태 변경 실패' TYPE 'E'. RETURN.
  ENDIF.

  UPDATE ztc1mm0008 SET statu = @lv_stat
   WHERE ebeln = @lv_ebeln.

*-- 통화 자릿수 반영한 금액 문자열
  CLEAR lv_amt.
  WRITE lv_total TO lv_amt CURRENCY gs_appr-waers.
  CONDENSE lv_amt.

  lv_cmt = |재상신 - { COND string( WHEN lv_stat = 'FT' THEN '전결' ELSE '일반결재' ) } (총 { lv_amt } { gs_appr-waers })|.

  PERFORM insert_approval_log
    USING lv_ebeln 'REQ' 'RS' lv_cmt.

  COMMIT WORK.

  PERFORM set_podata.
  PERFORM apply_curr_stat.
  PERFORM refresh_table USING go_po_alv.
  PERFORM set_card_html.

  MESSAGE |PO { lv_ebeln } 재상신 완료| TYPE 'S'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_po_grid_title
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_po_grid_title .

  CASE gv_curr_stat.
    WHEN 'ALL'.
      gs_layout_po-grid_title = '전체'.
    WHEN 'WAIT'.
      gs_layout_po-grid_title = '결재 대기'.
    WHEN 'ING'.
      gs_layout_po-grid_title = '결재중'.
    WHEN 'DONE'.
      gs_layout_po-grid_title = '승인'.
    WHEN 'REJ'.
      gs_layout_po-grid_title = '반려'.
    WHEN OTHERS.
      gs_layout_po-grid_title = '구매오더 결재 리스트'.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form go_approval
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM go_approval .

  DATA : lt_rows  TYPE lvc_t_row,
         ls_row   TYPE lvc_s_row,
         lv_ebeln TYPE ztc1mm0007-ebeln,
         lv_url   TYPE char255.

  CALL METHOD go_po_alv->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  CASE lines( lt_rows ).
    WHEN 0.
*-- 전체 결재 목록으로
      lv_url = |https://bgissap1.bgissap.co.kr:44300/sap/bc/ui2/flp?sap-client=100&sap-language=EN#zc1mmpoappr-display|.
    WHEN 1.
      READ TABLE lt_rows INTO ls_row INDEX 1.
      READ TABLE gt_po_list INTO gs_appr INDEX ls_row-index.
      CHECK sy-subrc = 0.
      lv_ebeln = gs_appr-ebeln.
*-- 해당 PO 상세 자동 표시
      lv_url = |https://bgissap1.bgissap.co.kr:44300/sap/bc/ui2/flp?sap-client=100&sap-language=EN#zc1mmpoappr-display?ebeln={ lv_ebeln }|.
    WHEN OTHERS.
      MESSAGE '결재현황 이동은 한 건만 선택해주세요' TYPE 'I'.
      RETURN.
  ENDCASE.

  CALL FUNCTION 'CALL_BROWSER'
    EXPORTING
      url    = lv_url
    EXCEPTIONS
      OTHERS = 1.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form toggle_bigo_column
*&   반려 카드일 때만 REJ_ICON 컬럼 표시
*&---------------------------------------------------------------------*
FORM toggle_bigo_column .

  DATA : lt_fcat TYPE lvc_t_fcat.

  CALL METHOD go_po_alv->get_frontend_fieldcatalog
    IMPORTING
      et_fieldcatalog = lt_fcat.

  LOOP AT lt_fcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).

    CASE <fs_fcat>-fieldname.

*-- 반려 카드일 때만 반려사유 아이콘 표시
      WHEN 'REJ_ICON'.
        IF gv_curr_stat = 'REJ'.
          <fs_fcat>-no_out = ''.
        ELSE.
          <fs_fcat>-no_out = 'X'.
        ENDIF.

*-- 결재 진행 중 카드일 때만 결재유형 표시
      WHEN 'APPR_TYPE_TXT'.
        IF gv_curr_stat = 'ING'.
          <fs_fcat>-no_out = ''.
        ELSE.
          <fs_fcat>-no_out = 'X'.
        ENDIF.

    ENDCASE.

  ENDLOOP.

  CALL METHOD go_po_alv->set_frontend_fieldcatalog
    EXPORTING
      it_fieldcatalog = lt_fcat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_bigo_click
*&   반려사유(REJ_ICON) 아이콘 클릭 -> 반려 사유 팝업
*&---------------------------------------------------------------------*
FORM handle_bigo_click  USING ps_row TYPE lvc_s_row
                              ps_col TYPE lvc_s_col.

*-- REJ_ICON 컬럼이 아니면 무시
  CHECK ps_col-fieldname = 'REJ_ICON'.

  READ TABLE gt_po_list INTO gs_bigo_sel INDEX ps_row-index.
  CHECK sy-subrc = 0.
  CHECK gs_bigo_sel-rej_reason IS NOT INITIAL.

*-- 반려 사유 HTML 팝업 호출
  CALL SCREEN 0300 STARTING AT 60 6 ENDING AT 100 17.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_bigo_popup
*&   반려 사유 HTML 팝업 컨테이너/뷰어 생성 + sapevent 등록
*&---------------------------------------------------------------------*
FORM create_bigo_popup .

  DATA : lt_events TYPE cntl_simple_events,
         ls_event  TYPE cntl_simple_event.

  IF go_bigo_pop_cont IS NOT BOUND.

    CREATE OBJECT go_bigo_pop_cont
      EXPORTING
        container_name = 'BIGO_CONT'.

    CREATE OBJECT go_bigo_pop_html
      EXPORTING
        parent = go_bigo_pop_cont.

*-- 닫기(sapevent) 이벤트 등록
    ls_event-eventid    = cl_gui_html_viewer=>m_id_sapevent.
    ls_event-appl_event = abap_true.
    APPEND ls_event TO lt_events.

    CALL METHOD go_bigo_pop_html->set_registered_events
      EXPORTING
        events = lt_events.

    SET HANDLER lcl_event_handler=>on_sapevent FOR go_bigo_pop_html.

  ENDIF.

  PERFORM show_bigo_html.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_bigo_html
*&   반려 사유 HTML 빌드 및 출력
*&---------------------------------------------------------------------*
FORM show_bigo_html .

  DATA : lt_html TYPE TABLE OF char255,
         lv_url  TYPE char255,
         lv_date TYPE char10.

  lv_date = |{ gs_bigo_sel-bedat+0(4) }-{ gs_bigo_sel-bedat+4(2) }-{ gs_bigo_sel-bedat+6(2) }|.

  APPEND '<html><head><style>html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;box-sizing:border-box;}*{box-sizing:border-box;}</style></head>' TO lt_html.
  APPEND '<body scroll="no" style="font-family:Malgun Gothic,Arial;font-size:11px;margin:0;padding:0;background:#DFEBF5;overflow:hidden;">' TO lt_html.

  APPEND '<div style="width:100%;height:100%;background:#FFFFFF;border:1px solid #CFD8E3;border-radius:4px;overflow:hidden;">' TO lt_html.

*-- 타이틀 바
  APPEND '<div style="height:22px;padding:3px 10px;background:#E8EEF5;border-bottom:1px solid #D5DEEA;display:flex;align-items:center;">' TO lt_html.
  APPEND '<div style="color:#3D4A5A;font-size:10px;font-weight:600;letter-spacing:0.2px;">반려 사유</div>' TO lt_html.
  APPEND '</div>' TO lt_html.

*-- PO NUMBER + 발주일
  APPEND '<div style="padding:6px 12px;background:#F8FAFC;border-bottom:1px solid #E5EBF1;display:flex;justify-content:space-between;align-items:center;">' TO lt_html.
  APPEND |<div><div style="font-size:9px;color:#7A8896;letter-spacing:1px;font-weight:600;">구매오더 번호</div>| TO lt_html.
  APPEND |<div style="font-size:14px;font-weight:700;color:#1A4068;margin-top:1px;line-height:18px;">{ gs_bigo_sel-ebeln }</div></div>| TO lt_html.
  APPEND |<div style="text-align:right;"><div style="font-size:9px;color:#7A8896;">발주일</div><div style="font-size:11px;color:#3D4A5A;font-weight:500;">{ lv_date }</div></div>| TO lt_html.
  APPEND '</div>' TO lt_html.

*-- 공급업체
  APPEND '<table style="width:100%;border-collapse:collapse;table-layout:fixed;">' TO lt_html.
  APPEND '<tr style="height:24px;">' TO lt_html.
  APPEND |<td style="width:22%;padding:1px 9px;background:#EEF3F8;color:#607083;border-bottom:1px solid #E0E6EE;font-weight:600;font-size:10px;letter-spacing:0.2px;">공급업체</td>| TO lt_html.
  APPEND |<td style="padding:1px 9px;border-bottom:1px solid #E0E6EE;color:#2A3A4A;font-size:11px;font-weight:500;">{ gs_bigo_sel-lifnr } / { gs_bigo_sel-name1 }</td>| TO lt_html.
  APPEND '</tr></table>' TO lt_html.

*-- 사유 본문 박스
  APPEND '<div style="padding:8px 12px;">' TO lt_html.
  APPEND '<div style="font-size:9px;color:#7A6E7A;letter-spacing:0.5px;font-weight:600;margin-bottom:3px;">REJECT REASON</div>' TO lt_html.
  APPEND '<div style="min-height:38px;padding:8px 10px;background:#F6F3F5;border:1px solid #E1DCE0;border-left:3px solid #8A6E7A;border-radius:2px;color:#3D3540;font-size:11px;line-height:1.5;white-space:pre-wrap;word-break:break-all;">' TO lt_html.
  APPEND |{ gs_bigo_sel-rej_reason }| TO lt_html.
  APPEND '</div></div>' TO lt_html.

  APPEND '</div></body></html>' TO lt_html.

  CALL METHOD go_bigo_pop_html->load_data
    IMPORTING
      assigned_url = lv_url
    CHANGING
      data_table   = lt_html.

  CALL METHOD go_bigo_pop_html->show_url
    EXPORTING
      url = lv_url.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_bigo_popup
*&   반려 사유 팝업 컨테이너 해제
*&---------------------------------------------------------------------*
FORM free_bigo_popup .

  IF go_bigo_pop_cont IS BOUND.
    CALL METHOD go_bigo_pop_cont->free.
    CLEAR : go_bigo_pop_cont, go_bigo_pop_html.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form modify_po
*&   수정 진입 -> PO 데이터 로드 -> 화면 0200 호출
*&---------------------------------------------------------------------*
FORM modify_po .

  DATA : lt_rows  TYPE lvc_t_row,
         ls_row   TYPE lvc_s_row,
         lv_ebeln TYPE ztc1mm0007-ebeln,
         ls_hdr   TYPE ztc1mm0007.

  CALL METHOD go_po_alv->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  CASE lines( lt_rows ).
    WHEN 0.
      MESSAGE '수정할 구매오더를 선택하세요' TYPE 'I'.
      RETURN.
    WHEN 1.
      READ TABLE lt_rows INTO ls_row INDEX 1.
      READ TABLE gt_po_list INTO gs_appr INDEX ls_row-index.
      CHECK sy-subrc = 0.
      lv_ebeln = gs_appr-ebeln.
    WHEN OTHERS.
      MESSAGE '한 건씩 수정 가능합니다' TYPE 'I'.
      RETURN.
  ENDCASE.

*-- 헤더 정보 조회
  SELECT SINGLE * FROM ztc1mm0007 WHERE ebeln = @lv_ebeln INTO @ls_hdr.
  IF sy-subrc <> 0.
    MESSAGE '구매오더를 찾을 수 없습니다' TYPE 'E'.
    RETURN.
  ENDIF.

  SELECT SINGLE name1 FROM ztc1mm0012
   WHERE lifnr = @ls_hdr-lifnr INTO @gv_modi_name1.

  gv_modi_ebeln = ls_hdr-ebeln.
  gv_modi_lifnr = ls_hdr-lifnr.
  gv_modi_bedat = ls_hdr-bedat.
  gv_modi_waers = ls_hdr-waers.
  gv_modi_statu = ls_hdr-statu.
  gv_modi_bigo  = ls_hdr-bigo.

  CASE ls_hdr-statu.
    WHEN 'SV'. gv_modi_stxt = '결재 대기'.
    WHEN 'RJ'. gv_modi_stxt = '반려'.
    WHEN OTHERS. gv_modi_stxt = ls_hdr-statu.
  ENDCASE.

*-- 품목 조회
  CLEAR gt_modi_item.

  SELECT a~ebelp, a~matnr, b~maktx, a~menge, a~meins, a~netpr,
         a~waers, a~lfdat
    FROM ztc1mm0008 AS a
    LEFT JOIN ztc1mm0026 AS b ON  a~banfn = b~banfn
                              AND a~bnfpo = b~bnfpo
   WHERE a~ebeln = @lv_ebeln
    INTO CORRESPONDING FIELDS OF TABLE @gt_modi_item.

*-- 잠금 컬럼 처리 (EBELP/MATNR/MAKTX/MEINS/TOTAL/WAERS = 잠금)
  LOOP AT gt_modi_item ASSIGNING FIELD-SYMBOL(<fs_modi>).
    <fs_modi>-total = <fs_modi>-menge * <fs_modi>-netpr.
    PERFORM set_cell_readonly USING <fs_modi>-celltab 'EBELP'.
    PERFORM set_cell_readonly USING <fs_modi>-celltab 'MATNR'.
    PERFORM set_cell_readonly USING <fs_modi>-celltab 'MAKTX'.
    PERFORM set_cell_readonly USING <fs_modi>-celltab 'MEINS'.
    PERFORM set_cell_readonly USING <fs_modi>-celltab 'TOTAL'.
    PERFORM set_cell_readonly USING <fs_modi>-celltab 'WAERS'.
  ENDLOOP.

*-- 화면 0200 호출
  CALL SCREEN 0200 STARTING AT 70 5 ENDING AT 138 28.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_modify
*&   수정 팝업 저장 (DB UPDATE)
*&   pv_resubmit = 'X' 이면 수정된 금액 기준으로 FT/PD 재분기
*&---------------------------------------------------------------------*
FORM save_modify USING pv_resubmit TYPE abap_bool.

  DATA : lv_ans   TYPE c LENGTH 1,
         lv_total TYPE p LENGTH 13 DECIMALS 2,
         lv_stat  TYPE ztc1mm0007-statu,
         lv_cmt   TYPE ztc1mm0027-appr_comment,
         lv_amt   TYPE c LENGTH 30.

*-- ALV의 미확정 변경 강제 commit
  CALL METHOD go_modi_alv->check_changed_data.

*-- 검증
  LOOP AT gt_modi_item INTO gs_modi_item.

    IF gs_modi_item-menge <= 0.
      MESSAGE |품목 { gs_modi_item-ebelp }: 수량은 0보다 커야 합니다| TYPE 'E'.
      RETURN.
    ENDIF.

    IF gs_modi_item-netpr <= 0.
      MESSAGE |품목 { gs_modi_item-ebelp }: 단가는 0보다 커야 합니다| TYPE 'E'.
      RETURN.
    ENDIF.

    IF gs_modi_item-lfdat IS INITIAL.
      MESSAGE |품목 { gs_modi_item-ebelp }: 납기일을 입력하세요| TYPE 'E'.
      RETURN.
    ENDIF.

  ENDLOOP.

*-- 확인 팝업
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '[Taesan] 저장'
      text_question         = COND #( WHEN pv_resubmit = abap_true
                                       THEN '수정 후 재상신하시겠습니까?'
                                       ELSE '수정 사항을 저장하시겠습니까?' )
      text_button_1         = '예'
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = '아니오'
      icon_button_2         = 'ICON_CANCEL'
      display_cancel_button = ' '
    IMPORTING
      answer                = lv_ans.

  CHECK lv_ans = '1'.

*-- 품목 UPDATE
  LOOP AT gt_modi_item INTO gs_modi_item.

    UPDATE ztc1mm0008
       SET menge = @gs_modi_item-menge,
           netpr = @gs_modi_item-netpr,
           lfdat = @gs_modi_item-lfdat
     WHERE ebeln = @gv_modi_ebeln
       AND ebelp = @gs_modi_item-ebelp.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE |품목 { gs_modi_item-ebelp } 수정 실패| TYPE 'E'.
      RETURN.
    ENDIF.

  ENDLOOP.

*-- 재상신이면 수정된 금액 기준으로 FT/PD 재분기
  IF pv_resubmit = abap_true.

    PERFORM calc_po_total    USING    gv_modi_ebeln
                             CHANGING lv_total.
    PERFORM decide_appr_type USING    lv_total
                             CHANGING lv_stat.

    UPDATE ztc1mm0007
       SET statu = @lv_stat
     WHERE ebeln = @gv_modi_ebeln.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE '구매오더 재상신 상태 변경 실패' TYPE 'E'.
      RETURN.
    ENDIF.

    UPDATE ztc1mm0008 SET statu = @lv_stat
     WHERE ebeln = @gv_modi_ebeln.

*--- 통화 자릿수 반영한 금액 문자열
    CLEAR lv_amt.
    WRITE lv_total TO lv_amt CURRENCY gv_modi_waers.
    CONDENSE lv_amt.

    lv_cmt = |수정 후 재상신 - { COND string( WHEN lv_stat = 'FT' THEN '전결' ELSE '일반결재' ) } (총 { lv_amt } { gv_modi_waers })|.

    PERFORM insert_approval_log
      USING gv_modi_ebeln 'REQ' 'RS' lv_cmt.

  ENDIF.

  COMMIT WORK.

*-- 화면 갱신
  PERFORM set_podata.
  PERFORM apply_curr_stat.
  PERFORM refresh_table USING go_po_alv.
  PERFORM set_card_html.

  IF gv_detail_open = abap_true.
    PERFORM show_po_detail USING gv_modi_ebeln.
  ENDIF.

  MESSAGE |PO { gv_modi_ebeln } { COND string( WHEN pv_resubmit = abap_true
                                                THEN '수정 및 재상신 완료'
                                                ELSE '저장 완료' ) }| TYPE 'S'.

  IF go_modi_cont IS BOUND.
    CALL METHOD go_modi_cont->free.
    CLEAR : go_modi_cont, go_modi_alv.
  ENDIF.

  IF go_bigo_cont IS BOUND.
    CALL METHOD go_bigo_cont->free.
    CLEAR : go_bigo_cont, go_bigo_text.
  ENDIF.

  LEAVE TO SCREEN 0.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_order_qty
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_RIGHT_MENGE
*&      --> GS_RIGHT_MINBM
*&      --> GS_RIGHT_NORBM
*&      <-- GS_BOTTOM_MENGE
*&---------------------------------------------------------------------*
FORM calc_order_qty  USING    pv_req   TYPE ztc1mm0026-menge
                              pv_minbm TYPE ztc1mm0022-minbm
                              pv_norbm TYPE ztc1mm0022-norbm
                     CHANGING cv_qty   TYPE ztc1mm0026-menge.

  DATA : lv_lot TYPE i.

*-- 기본값 : 요청수량 그대로
  cv_qty = pv_req.

*-- 발주 묶음(NORBM) 배수로 올림
  IF pv_norbm > 0.
    lv_lot = ceil( pv_req / pv_norbm ).
    cv_qty = lv_lot * pv_norbm.
  ENDIF.

*-- 최소주문수량(MINBM) 하한 보정
  IF pv_minbm > 0 AND cv_qty < pv_minbm.
    cv_qty = pv_minbm.
*-- 보정 후에도 묶음 배수 유지
    IF pv_norbm > 0.
      lv_lot = ceil( cv_qty / pv_norbm ).
      cv_qty = lv_lot * pv_norbm.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_pr .

  CLEAR : ztc1mm0025-banfn,
          ztc1mm0025-badat,
          gv_badat_to.

  PERFORM set_prdata.
  PERFORM update_left_status.
  PERFORM refresh_table USING go_left_alv.

  PERFORM clear_right_side.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form search_podata
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM search_podata .

*-- 조건 재조회
  PERFORM set_podata.

*-- 현재 선택된 카드 상태 기준으로 ALV 출력 데이터 재세팅
  PERFORM apply_curr_stat.

*-- 제목 유지/갱신
  PERFORM set_po_grid_title.

*-- ALV 갱신
  PERFORM refresh_table USING go_po_alv.

*-- 카드 카운트 갱신
  PERFORM set_card_html.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_po
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_po .

  CLEAR : ztc1mm0007-ebeln, ztc1mm0007-bsart, ztc1mm0007-bedat,
          gv_bedat_to, ztc1mm0007-werks, ztc1mm0007-lifnr.

*-- PO 데이터 전체 재조회
  PERFORM set_podata.

  PERFORM apply_curr_stat.

*-- ALV 제목 갱신
  PERFORM set_po_grid_title.

*-- PO 리스트 ALV 갱신
  PERFORM refresh_table USING go_po_alv.

*-- 카드 카운트 갱신
  PERFORM set_card_html.

*-- 상세 영역 열려 있으면 닫기
  PERFORM close_po_detail.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form clear_right_side
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM clear_right_side .

  CLEAR : gt_right.
  PERFORM refresh_table USING go_right_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_po_total
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_EBELN
*&      <-- LV_TOTAL
*&---------------------------------------------------------------------*
FORM calc_po_total  USING    pv_ebeln TYPE ztc1mm0007-ebeln
                    CHANGING cv_total TYPE p.

  SELECT SUM( menge * netpr )
    FROM ztc1mm0008
   WHERE ebeln = @pv_ebeln
     AND ( loekz IS INITIAL OR loekz = '' )
    INTO @cv_total.

  IF sy-subrc <> 0.
    CLEAR cv_total.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form decide_appr_type
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_TOTAL
*&      <-- LV_STAT
*&---------------------------------------------------------------------*
FORM decide_appr_type  USING    pv_total TYPE p
                       CHANGING cv_stat  TYPE ztc1mm0007-statu.

  IF pv_total <= gc_small_appr_limit.
    cv_stat = 'FT'.    " 전결
  ELSE.
    cv_stat = 'PD'.    " 일반결재
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form insert_approval_log
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_EBELN
*&      --> P_
*&      --> LV_ACTION
*&      --> LV_CMT
*&---------------------------------------------------------------------*
FORM insert_approval_log  USING pv_ebeln  TYPE ztc1mm0007-ebeln
                              pv_astep  TYPE ztc1mm0027-astep
                              pv_action TYPE ztc1mm0027-action
                              pv_cmt    TYPE ztc1mm0027-appr_comment.

  DATA : ls_log TYPE ztc1mm0027,
         lv_max TYPE ztc1mm0027-seqnr,
         ls_hr  TYPE ztc1hr0001.

*-- 현재 로그인 사용자 HR 정보
  SELECT SINGLE * FROM ztc1hr0001
   WHERE uname = @sy-uname INTO @ls_hr.

*-- 다음 SEQNR
  SELECT MAX( seqnr )
    FROM ztc1mm0027
   WHERE ebeln = @pv_ebeln
    INTO @lv_max.

  IF lv_max IS INITIAL.
    ls_log-seqnr = 10.
  ELSE.
    ls_log-seqnr = lv_max + 10.
  ENDIF.

  ls_log-mandt   = sy-mandt.
  ls_log-ebeln   = pv_ebeln.
  ls_log-astep   = pv_astep.
  ls_log-pernr   = ls_hr-pernr.
  ls_log-uname   = sy-uname.
  ls_log-ename   = ls_hr-ename.
  ls_log-zgrade  = ls_hr-zgrade.
  ls_log-action  = pv_action.
  GET TIME STAMP FIELD ls_log-actdt.
  ls_log-appr_comment = pv_cmt.

  INSERT ztc1mm0027 FROM ls_log.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_html_header
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
*FORM display_html_header .
*
*  IF go_html_dock IS NOT BOUND.
*
*    CREATE OBJECT go_html_dock
*      EXPORTING
*        side      = cl_gui_docking_container=>dock_at_top
*        extension = 35.
*
*  ENDIF.
*
*  IF go_html_header IS NOT BOUND.
*
*    CREATE OBJECT go_html_header
*      EXPORTING
*        io_parent = go_html_dock.
*
*  ENDIF.
*
*  go_html_header->display(
*    EXPORTING
*      iv_module_tag   = |MM|
*      iv_module_full  = |MM - Material Management|
*      iv_program_name = |구매오더 관리 프로그램|
*      iv_program_desc = |확정된 구매요청의 구매오더 발주와 구매 승인 프로세스 통합 관리 프로그램입니다|
*      iv_program_id   = |{ sy-repid }|
*      iv_system_info  = |{ sy-sysid } / { sy-mandt }|
*      iv_user_id      = |{ sy-uname }|
*      iv_user_name    = |{ sy-uname }|
*  ).
*
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form select_all_right
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM select_all_right .

  CALL METHOD go_right_alv->check_changed_data.

  IF gt_right IS INITIAL.
    MESSAGE '선택할 품목이 없습니다' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT gt_right ASSIGNING FIELD-SYMBOL(<fs_right>).
*-- 이미 Tree로 이동된 행은 건너뜀 (CHECK 잠금 유지)
    IF <fs_right>-sent = 'X'.
      CONTINUE.
    ENDIF.
    <fs_right>-check = 'X'.
  ENDLOOP.

  PERFORM refresh_table USING go_right_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form convert_uname_to_name
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- <FS_LEFT>_ERNAM
*&---------------------------------------------------------------------*
FORM convert_uname_to_name CHANGING cv_ernam TYPE ztc1mm0025-ernam.

  DATA : lv_ename TYPE ztc1hr0001-ename.

  CHECK cv_ernam IS NOT INITIAL.

  SELECT SINGLE ename
    FROM ztc1hr0001
    WHERE uname = @cv_ernam
    INTO @lv_ename.

*-- HR 마스터 미등록 사용자는 UNAME 그대로 표시
  IF sy-subrc = 0 AND lv_ename IS NOT INITIAL.
    cv_ernam = lv_ename.
  ENDIF.

ENDFORM.
