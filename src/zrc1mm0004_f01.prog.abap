*&---------------------------------------------------------------------*
*& Include          ZRC1MM0004_F01
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

  IF go_list_cont IS NOT BOUND.

*-- Search help 설정
    PERFORM set_f4_matnr.

*-- 구매요청번호 미리보기 설정
    PERFORM get_preview_banfn.

*-- 데이터 조회
    PERFORM set_prdata.

*-- 컨테이너 생성
    PERFORM create_tab1.
    PERFORM create_tab2.

*-- 필드 카탈로그 설정
    CLEAR : gt_fcat_header, gt_fcat_item, gt_fcat_create, gs_fcat.
    PERFORM set_field_catalog USING :
                                      " H : PR리스트
                                      'H' 'X' 'ICON'      ''           'C' '',
                                      'H' 'X' 'BANFN'     'ZTC1MM0025' ' ' '',
                                      'H' ' ' 'ESTKZ_T'   ''           ' ' '',
                                      'H' ' ' 'AFNAM'     'ZTC1MM0025' ' ' '',
                                      'H' ' ' 'BADAT'     'ZTC1MM0025' 'C' '',
                                      'H' ' ' 'LFDAT'     'ZTC1MM0026' 'C' '',
                                      'H' ' ' 'DDAY_TXT'  ''           'C' '',
                                      'H' ' ' 'ITEM_CNT'  ''           ' ' '',
                                      'H' ' ' 'TOTAL_AMT' ''           ' ' '',
                                      'H' ' ' 'WAERS'     'ZTC1MM0026' 'C' '',
                                      'H' ' ' 'DEL_ICON'  ''           'C' '',

                                      " I : PR 미확정/확정
                                      'I' 'X' 'ICON'          ''           'C' ' ',
                                      'I' 'X' 'BNFPO'         'ZTC1MM0026' ' ' ' ',
                                      'I' ' ' 'MATNR'         'ZTC1MM0026' ' ' ' ',
                                      'I' ' ' 'MAKTX'         'ZTC1MM0026' ' ' 'X',
                                      'I' ' ' 'WERKS'         'ZTC1MM0026' 'C' ' ',
                                      'I' ' ' 'LGORT'         'ZTC1MM0026' 'C' ' ',
                                      'I' ' ' 'LGORT_TXT'     ''           ' ' 'X',
                                      'I' ' ' 'MENGE'         'ZTC1MM0026' ' ' ' ',
                                      'I' ' ' 'MEINS'         'ZTC1MM0026' 'C' ' ',
                                      'I' ' ' 'PRICE'         'ZTC1MM0026' ' ' ' ',
                                      'I' ' ' 'TOTAL_MAT_AMT' ''           ' ' ' ',
                                      'I' ' ' 'WAERS'         'ZTC1MM0026' 'C' ' ',
                                      'I' ' ' 'LFDAT'         'ZTC1MM0026' 'C' ' ',
                                      'I' ' ' 'EBELN'         'ZTC1MM0026' ' ' ' ',
                                      'I' ' ' 'LOEKZ'         'ZTC1MM0026' ' ' ' ',

                                      " C : PR 수동생성
                                      'C' 'X' 'BNFPO'         'ZTC1MM0026' ' ' '',
                                      'C' ' ' 'MATNR'         'ZTC1MM0026' ' ' '',
                                      'C' ' ' 'MAKTX'         'ZTC1MM0026' ' ' '',
                                      'C' ' ' 'MENGE'         'ZTC1MM0026' ' ' '',
                                      'C' ' ' 'MEINS'         'ZTC1MM0026' 'C' '',
                                      'C' ' ' 'WERKS'         'ZTC1MM0026' 'C' '',
                                      'C' ' ' 'LGORT'         'ZTC1MM0026' 'C' '',
                                      'C' ' ' 'LGORT_TXT'     ''           ' ' '',
                                      'C' ' ' 'LFDAT'         'ZTC1MM0026' 'C' '',
                                      'C' ' ' 'PRICE'         'ZTC1MM0026' ' ' '',
                                      'C' ' ' 'TOTAL_MAT_AMT' ''           ' ' '',
                                      'C' ' ' 'WAERS'         'ZTC1MM0026' 'C' '',
                                      'C' ' ' 'PURRSN'        'ZTC1MM0026' ' ' ''.

*-- 레이아웃 설정
    PERFORM set_layout.

*-- 이벤트 핸들러
    SET HANDLER : lcl_event_handler=>on_double_click       FOR go_left_alv,
                  lcl_event_handler=>on_toolbar            FOR go_left_alv,
                  lcl_event_handler=>on_toolbar            FOR go_right_mid_alv,
                  lcl_event_handler=>on_toolbar            FOR go_right_bot_alv,
                  lcl_event_handler=>on_toolbar            FOR go_create_alv,
                  lcl_event_handler=>on_user_command       FOR ALL INSTANCES,
                  lcl_event_handler=>on_alv_checkbox       FOR go_right_mid_alv,
                  lcl_event_handler=>modify_value          FOR go_create_alv,
                  lcl_event_handler=>handle_search_help    FOR go_create_alv.

*-- 편집 이벤트 발생
    PERFORM set_edit_event.

*-- html 초기값 설정
    PERFORM set_header_html_init.

*-- 구매사유 설정
    PERFORM set_purrsn_dropdown.

*-- ALV 출력
    PERFORM create_display.

    PERFORM set_create_header_html.
    PERFORM set_summary_html.

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

*-- PR 조회 탭 서브스크린
  CREATE OBJECT go_list_cont
    EXPORTING
      container_name = 'LIST_CONT'.

*-- 좌/우 분할 split 컨테이너
  CREATE OBJECT go_split_cont
    EXPORTING
      parent  = go_list_cont
      rows    = 1
      columns = 2.

  CALL METHOD go_split_cont->set_column_width
    EXPORTING
      id    = 1
      width = 51.  " 좌측 51%, 우측 49%

*-- 좌측 컨테이너
  CALL METHOD go_split_cont->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_left_cont.

*-- 우측 컨테이너
  CALL METHOD go_split_cont->get_container
    EXPORTING
      row       = 1
      column    = 2
    RECEIVING
      container = go_right_cont.

*-- 좌측 ALV
  CREATE OBJECT go_left_alv
    EXPORTING
      i_parent = go_left_cont.

*-- 우측 3분할 컨테이너
  CREATE OBJECT go_right_split
    EXPORTING
      parent  = go_right_cont
      rows    = 3
      columns = 1.

  CALL METHOD go_right_split->set_row_height
    EXPORTING
      id     = 1
      height = 24.

*-- 상단 컨테이너 (공통정보)
  CALL METHOD go_right_split->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_right_top_cont.

*-- 중간 컨테이너 (PR 미확정)
  CALL METHOD go_right_split->get_container
    EXPORTING
      row       = 2
      column    = 1
    RECEIVING
      container = go_right_mid_cont.

*-- 하단 컨테이너 (PR 확정)
  CALL METHOD go_right_split->get_container
    EXPORTING
      row       = 3
      column    = 1
    RECEIVING
      container = go_right_bot_cont.

*-- 상단 (공통정보 HTML)
  CREATE OBJECT go_html_viewer
    EXPORTING
      parent = go_right_top_cont.

*-- 중간 ALV
  CREATE OBJECT go_right_mid_alv
    EXPORTING
      i_parent = go_right_mid_cont.

*-- 하단 ALV
  CREATE OBJECT go_right_bot_alv
    EXPORTING
      i_parent = go_right_bot_cont.

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

*-- PR 수동생성 헤더 HTML 컨테이너
  CREATE OBJECT go_head_cont
    EXPORTING
      container_name = 'HEADER_CONT'.

*-- PR 수동생성 컨테이너
  CREATE OBJECT go_create_cont
    EXPORTING
      container_name = 'CREATE_CONT'.

*-- PR 수동생성 요약 HTML 컨테이너
  CREATE OBJECT go_summary_cont
    EXPORTING
      container_name = 'SUMMARY_CONT'.

*-- 헤더 HTML
  CREATE OBJECT go_head_html
    EXPORTING
      parent = go_head_cont.

*-- PR 수동생성 ALV
  CREATE OBJECT go_create_alv
    EXPORTING
      i_parent = go_create_cont.

*-- 요약 HTML
  CREATE OBJECT go_summary_html
    EXPORTING
      parent = go_summary_cont.

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

  PERFORM get_korean_text USING    pv_table
                                   pv_field
                          CHANGING gs_fcat-coltext.


*-- 공통 속성 (ALV 무관)
  CASE pv_field.
    WHEN 'MENGE'.
      gs_fcat-qfieldname = 'MEINS'.
    WHEN 'ICON'.
      gs_fcat-coltext = '상태'.
    WHEN 'LFDAT'.
      gs_fcat-coltext = '납기요청일'.
  ENDCASE.

*-- I, C 공통 속성 (PR 아이템 관련)
  IF pv_flag = 'I' OR pv_flag = 'C'.
    CASE pv_field.
      WHEN 'BNFPO'.
        gs_fcat-coltext = '품목번호'.
      WHEN 'MAKTX'.
        gs_fcat-coltext = '자재명'.
      WHEN 'TOTAL_MAT_AMT'.
        gs_fcat-coltext  = '총 금액'.
        gs_fcat-cfieldname = 'WAERS'.
      WHEN 'PRICE'.
        gs_fcat-cfieldname = 'WAERS'.
        gs_fcat-coltext = '단가'.
    ENDCASE.
  ENDIF.

*-- ALV별 개별 속성
  CASE pv_flag.
    WHEN 'H'.  " 좌측 PR 목록
      CASE pv_field.
        WHEN 'BADAT'.
          gs_fcat-coltext = '구매요청일'.
        WHEN 'DEL_ICON'.
          gs_fcat-coltext = '취소품목 여부'.
        WHEN 'ITEM_CNT'.
          gs_fcat-coltext = '품목 개수'.
        WHEN 'ESTKZ_T'.
          gs_fcat-coltext = '생성구분'.
        WHEN 'DDAY_TXT'.
          gs_fcat-coltext = '납기잔여일수'.
        WHEN 'TOTAL_AMT'.
          gs_fcat-coltext = '총 예상금액'.
          gs_fcat-cfieldname = 'WAERS'.
      ENDCASE.
    WHEN 'I'.  " PR 미확정 아이템
      CASE pv_field.
        WHEN 'LGORT_TXT'.
          gs_fcat-coltext   = '저장위치명'.
          gs_fcat-outputlen = 14.
        WHEN 'LOEKZ'.
          gs_fcat-checkbox = 'X'.
          gs_fcat-edit = 'X'.
          gs_fcat-coltext = '취소처리'.
        WHEN 'EBELN'.
          gs_fcat-coltext = '구매오더 번호'.
      ENDCASE.
    WHEN 'C'.
      CASE pv_field.
        WHEN 'BNFPO'.
          gs_fcat-outputlen = 6.
        WHEN 'MATNR'.
          gs_fcat-outputlen = 16.
          gs_fcat-f4availabl = 'X'.
        WHEN 'MAKTX'.
          gs_fcat-outputlen = 24.
        WHEN 'MENGE'.
          gs_fcat-outputlen = 10.
        WHEN 'MEINS'.
          gs_fcat-outputlen = 4.
        WHEN 'WERKS'.
          gs_fcat-outputlen = 6.
        WHEN 'LGORT'.
          gs_fcat-outputlen = 6.
        WHEN 'LGORT_TXT'.
          gs_fcat-outputlen = 10.
          gs_fcat-coltext   = '저장위치명'.
        WHEN 'LFDAT'.
          gs_fcat-outputlen = 12.
        WHEN 'PRICE'.
          gs_fcat-outputlen = 12.
        WHEN 'WAERS'.
          gs_fcat-outputlen = 6.
        WHEN 'TOTAL_MAT_AMT'.
          gs_fcat-outputlen = 15.
        WHEN 'PURRSN'.
          gs_fcat-outputlen = 12.
          gs_fcat-coltext   = '구매사유'.
          gs_fcat-edit      = 'X'.
          gs_fcat-drdn_hndl = '01'.
      ENDCASE.
  ENDCASE.

  CASE pv_flag.
    WHEN 'H'.
      APPEND gs_fcat TO gt_fcat_header.
    WHEN 'I'.
      APPEND gs_fcat TO gt_fcat_item.
    WHEN 'C'.
      APPEND gs_fcat TO gt_fcat_create.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_korean_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PV_TABLE
*&      --> PV_FIELD
*&      <-- GS_FCAT_COLTEXT
*&---------------------------------------------------------------------*
FORM get_korean_text USING   VALUE(pv_table)
                             VALUE(pv_field)
                     CHANGING cv_coltext.
*-- 필드명 한글 설정
  DATA: lv_rollname TYPE rollname,
        lv_text     TYPE coltext.

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
*& Form set_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_layout .

  gs_layout_list = VALUE #( zebra      = abap_true
                            cwidth_opt = 'A'
                            sel_mode   = 'D'
                            grid_title = '구매요청 목록'
                            ctab_fname = 'CELLCOLOR' ).

  gs_layout_mid = VALUE #( zebra      = abap_true
                           cwidth_opt = 'A'
                           sel_mode   = 'A'
                           grid_title = '구매요청 미확정 품목'
                           stylefname = 'CELLTAB' ).

  gs_layout_bot = VALUE #( zebra      = abap_true
                           cwidth_opt = 'A'
                           sel_mode   = 'A'
                           grid_title = '구매요청 확정 품목' ).

  gs_layout_create = VALUE #( zebra      = abap_true
                              sel_mode   = 'D'
                              edit       = 'X'
                              stylefname = 'CELLTAB').


  gs_variant = VALUE #( report = sy-repid
                        handle = 'PR' ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_edit_event
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_edit_event .

  DATA: ls_f4 TYPE lvc_s_f4,
        lt_f4 TYPE lvc_t_f4.

  CALL METHOD go_right_mid_alv->register_edit_event
    EXPORTING
      i_event_id = cl_gui_alv_grid=>mc_evt_modified.

  CALL METHOD go_create_alv->register_edit_event
    EXPORTING
      i_event_id = cl_gui_alv_grid=>mc_evt_modified.

  ls_f4-fieldname  = 'MATNR'.
  ls_f4-register   = 'X'.
  ls_f4-getbefore  = ''.
  ls_f4-chngeafter = 'X'.
  APPEND ls_f4 TO lt_f4.

  CALL METHOD go_create_alv->register_f4_for_fields
    EXPORTING
      it_f4 = lt_f4.


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

*-- PR 리스트 (좌측)
  CALL METHOD go_left_alv->set_table_for_first_display
    EXPORTING
      is_variant      = gs_variant
      i_save          = 'A'
      i_default       = 'X'
      is_layout       = gs_layout_list
    CHANGING
      it_outtab       = gt_header
      it_fieldcatalog = gt_fcat_header.

  CLEAR gs_fcat.
  READ TABLE gt_fcat_item INTO gs_fcat WITH KEY fieldname = 'EBELN'.
  IF sy-subrc EQ 0.
    gs_fcat-no_out = 'X'.
    MODIFY gt_fcat_item FROM gs_fcat INDEX sy-tabix TRANSPORTING no_out.
  ENDIF.

*-- PR 미확정 (우측)
  CALL METHOD go_right_mid_alv->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layout_mid
    CHANGING
      it_outtab       = gt_item_no
      it_fieldcatalog = gt_fcat_item.

  CLEAR gs_fcat.
  READ TABLE gt_fcat_item INTO gs_fcat WITH KEY fieldname = 'EBELN'.
  IF sy-subrc EQ 0.
    gs_fcat-no_out = ' '.
    MODIFY gt_fcat_item FROM gs_fcat INDEX sy-tabix TRANSPORTING no_out.
  ENDIF.

*-- READ TABLE로 필드 속성을 변경
  CLEAR gs_fcat.
  READ TABLE gt_fcat_item INTO gs_fcat WITH KEY fieldname = 'LOEKZ'.
  IF sy-subrc EQ 0.
    gs_fcat-no_out = 'X'.
    MODIFY gt_fcat_item FROM gs_fcat INDEX sy-tabix TRANSPORTING no_out.
  ENDIF.

*-- PR 확정 (우측)
  CALL METHOD go_right_bot_alv->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layout_bot
    CHANGING
      it_outtab       = gt_item_ok
      it_fieldcatalog = gt_fcat_item.

*-- PR 생성 (편집 ALV)
  CALL METHOD go_create_alv->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layout_create
    CHANGING
      it_outtab       = gt_create
      it_fieldcatalog = gt_fcat_create.

  CALL METHOD go_create_alv->set_ready_for_input
    EXPORTING
      i_ready_for_input = 1.

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
*& Form handle_toolbar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM handle_toolbar  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

*-- 표준 버튼 제거
  CLEAR po_object->mt_toolbar.

*-- 처리상태 필터 버튼
  CLEAR gs_button.
  gs_button-function  = 'FILTER_ALL'.
  gs_button-text      = |   전체 : { gv_cnt_all } 건|.
  APPEND gs_button TO po_object->mt_toolbar.

  CLEAR gs_button.
  gs_button-function  = 'FILTER_WAIT'.
  gs_button-icon      = icon_led_red.
  gs_button-text      = |   확정대기 : { gv_cnt_cr } 건|.
  APPEND gs_button TO po_object->mt_toolbar.

  CLEAR gs_button.
  gs_button-function  = 'FILTER_PART'.
  gs_button-icon      = icon_led_yellow.
  gs_button-text      = |   일부확정 : { gv_cnt_pc } 건|.
  APPEND gs_button TO po_object->mt_toolbar.

  CLEAR gs_button.
  gs_button-function  = 'FILTER_DONE'.
  gs_button-icon      = icon_led_green.
  gs_button-text      = |   확정완료 : { gv_cnt_fc } 건|.
  APPEND gs_button TO po_object->mt_toolbar.


*-- 구분선
  CLEAR gs_button.
  gs_button-butn_type = 3.
  APPEND gs_button TO po_object->mt_toolbar.

*-- 구매요청 확정 버튼
  CLEAR gs_button.
  gs_button-function  = 'PR_REQ_H'.
  gs_button-icon      = icon_next_object.
  gs_button-text      = '   구매요청 확정  '.
  APPEND gs_button TO po_object->mt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_toolbar_detail_mid
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM handle_toolbar_detail_mid  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

*-- 표준 버튼 제거
  CLEAR po_object->mt_toolbar.

*-- 구매요청 확정 버튼
  CLEAR gs_button.
  gs_button-function  = 'PR_REQ_I'.
  gs_button-icon      = icon_next_object.
  gs_button-text      = '   구매요청 확정  '.
  APPEND gs_button TO po_object->mt_toolbar.

*-- 수정 버튼
  CLEAR gs_button.
  gs_button-function  = 'PR_MODIFY'.
  gs_button-icon      = icon_annotation.
  gs_button-text      = '   구매요청 수정  '.
  APPEND gs_button TO po_object->mt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_toolbar_detail_bot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM handle_toolbar_detail_bot  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

*-- 표준 버튼 제거
  CLEAR po_object->mt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_user_command
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_UCOMM
*&---------------------------------------------------------------------*
FORM handle_user_command  USING    pv_ucomm.

  CASE pv_ucomm.
*-- TAB1 버튼
    WHEN 'FILTER_ALL'.
      PERFORM filter_table USING ''.
    WHEN 'FILTER_WAIT'.
      PERFORM filter_table USING 'CR'.
    WHEN 'FILTER_PART'.
      PERFORM filter_table USING 'PC'.
    WHEN 'FILTER_DONE'.
      PERFORM filter_table USING 'FC'.
    WHEN 'PR_REQ_H'.
      PERFORM pr_request_h. " 헤더 기준 구매요청 확정 (한꺼번에)

    WHEN 'PR_REQ_I'.
      PERFORM pr_request_i. " 아이템 기준 구매요청 확정 (한 개씩)
    WHEN 'PR_MODIFY'.
      PERFORM pr_modify.

*-- TAB2 버튼
    WHEN 'NEW'.
      PERFORM create_new.
    WHEN 'ADD'.
      PERFORM add_row.
    WHEN 'DEL'.
      PERFORM del_row.
    WHEN 'SAVE'.
      PERFORM save_pr.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form filter_table
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&---------------------------------------------------------------------*
FORM filter_table  USING pv_statu TYPE char2.

*-- PR 헤더 : 처리상태별 필터검색 기능
  DATA : lt_filter TYPE lvc_t_filt,
         ls_filter TYPE lvc_s_filt.

  CLEAR lt_filter.

  IF pv_statu IS NOT INITIAL.
    ls_filter-fieldname = 'STATU'.
    ls_filter-sign      = 'I'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       = pv_statu.
    APPEND ls_filter TO lt_filter.
  ENDIF.

*-- ALV 객체에 필터 세팅
  CALL METHOD go_left_alv->set_filter_criteria
    EXPORTING
      it_filter = lt_filter.

*-- 필터를 반영해서 TABLE Refresh
  PERFORM refresh_table USING go_left_alv.

  PERFORM clear_right_side.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_table
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GO_LEFT_ALV
*&---------------------------------------------------------------------*
FORM refresh_table  USING po_alv TYPE REF TO cl_gui_alv_grid.

  DATA : ls_stable TYPE lvc_s_stbl.

  CLEAR ls_stable.

  ls_stable-col = 'X'.
  ls_stable-row = 'X'.

  CALL METHOD po_alv->refresh_table_display
    EXPORTING
      is_stable = ls_stable.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_header_html_init
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_header_html_init.

*-- 초기 html 세팅
  DATA : lt_html TYPE TABLE OF char255,
         lv_url  TYPE char255.

  APPEND '<html><body style="font-family:Arial; font-size:11px; margin:4px; background:#D5DFE8;">' TO lt_html.
  APPEND '<div style="border:1px solid #1F3A52; background:linear-gradient(135deg,#E3ECF4,#F0F5FA); padding:8px; border-radius:3px;">' TO lt_html.
  APPEND '<div style="display:flex; align-items:center; margin-bottom:2px; padding-left:8px;">' TO lt_html.
  APPEND '<span style="width:14px; height:14px; margin-right:6px; border:1px solid #5B829D; background:#EAF3F9; color:#1E5C89; font-size:10px; font-weight:900; line-height:12px; text-align:center; display:inline-block;">i</span>' TO lt_html.
  APPEND '<b style="font-size:12px; color:#1F3A52;">구매요청 상세 정보</b>' TO lt_html.
  APPEND '</div>' TO lt_html.
  APPEND '<hr style="border:0; border-top:1px solid #7A9BB8; margin:4px 8px;">' TO lt_html.
  APPEND '<span style="color:#555; padding-left:8px;">좌측 리스트에서 구매요청을 더블클릭하세요.</span>' TO lt_html.
  APPEND '</div></body></html>' TO lt_html.

*-- ABAP 내부 HTML 데이터를 SAP GUI HTML Viewer에 업로드
  CALL METHOD go_html_viewer->load_data
    EXPORTING
      type                 = 'text'
      subtype              = 'html'
    IMPORTING
      assigned_url         = lv_url   " 내가 사용할 수 있는 url 생성
    CHANGING
      data_table           = lt_html  " html코드 들어있는 Internal table
    EXCEPTIONS
      dp_error_general     = 1
      dp_invalid_parameter = 2
      OTHERS               = 3.

*-- url 화면에 띄움
  CALL METHOD go_html_viewer->show_url
    EXPORTING
      url                    = lv_url " url 등록
    EXCEPTIONS
      cntl_error             = 1
      cnht_error_not_allowed = 2
      cnht_error_parameter   = 3
      dp_error_general       = 4
      OTHERS                 = 5.

  CALL METHOD cl_gui_cfw=>flush.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_prdata
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_prdata .
  DATA : lt_domval    TYPE TABLE OF dd07v,
         ls_domval    TYPE dd07v,
         ls_cellcolor TYPE lvc_s_scol.

  DATA : lt_not_fc LIKE TABLE OF gs_header,
         lt_fc     LIKE TABLE OF gs_header.

  CLEAR : gs_header, gt_header.

*-- PR 헤더 조회
*-- 품목이 모두 취소되어도 좌측 ALV에는 헤더가 남아야 하므로
*-- 아이템 테이블과 INNER JOIN 하지 않음
  SELECT banfn, badat, estkz, statu, afnam
    FROM ztc1mm0025
   WHERE ( @ztc1mm0025-banfn IS INITIAL OR banfn = @ztc1mm0025-banfn )
     AND ( @ztc1mm0025-badat IS INITIAL OR badat >= @ztc1mm0025-badat )
     AND ( @gv_badat_to IS INITIAL OR badat <= @gv_badat_to )
    INTO TABLE @DATA(lt_temp).

*-- 취소처리 안 된 품목 기준 집계
*-- 품목 개수 / 최소 납기요청일
  SELECT banfn,
         COUNT(*) AS item_cnt,
         MIN( lfdat ) AS min_lfdat
    FROM ztc1mm0026
   WHERE loekz = ''
   GROUP BY banfn
    INTO TABLE @DATA(lt_item_sum).

  SORT lt_item_sum BY banfn.

*-- 도메인 value값 가져오기
  CALL FUNCTION 'DD_DOMVALUES_GET'
    EXPORTING
      domname        = 'ZDC1_MM_ESTKZ'
      text           = 'X'
      langu          = sy-langu
    TABLES
      dd07v_tab      = lt_domval
    EXCEPTIONS
      wrong_textflag = 1
      OTHERS         = 2.

*-- 총 예상금액을 위한 아이템 테이블 조회
*-- 취소처리 안 된 품목만 금액 계산
  SELECT c~banfn,
         SUM( c~menge * d~netpr ) AS total_amt,
         d~waers
    FROM ztc1mm0026 AS c
   INNER JOIN ztc1mm0021 AS a ON a~matnr = c~matnr
   INNER JOIN ztc1mm0022 AS d ON d~infnr = a~infnr
     AND d~valid_from <= @sy-datum
     AND d~valid_to   >= @sy-datum
   WHERE c~loekz = ''
   GROUP BY c~banfn, d~waers
    INTO TABLE @DATA(lt_amt).

  SORT lt_amt BY banfn.

*-- 아이템 테이블에서 삭제한 행에 대한 정보
  SELECT banfn, COUNT(*) AS del_cnt
    FROM ztc1mm0026
   WHERE loekz = 'X'
   GROUP BY banfn
    INTO TABLE @DATA(lt_del).

  SORT lt_del BY banfn.

*-- 필드 데이터 설정
  LOOP AT lt_temp INTO DATA(ls_temp).

    CLEAR gs_header.
    MOVE-CORRESPONDING ls_temp TO gs_header.

*-- ESTKZ 도메인 텍스트 변환
    READ TABLE lt_domval INTO ls_domval
      WITH KEY domvalue_l = ls_temp-estkz.

    IF sy-subrc = 0.
      gs_header-estkz_t = ls_domval-ddtext.
    ELSE.
      gs_header-estkz_t = ls_temp-estkz.
    ENDIF.

*-- 취소처리 안 된 품목 기준 품목 개수 / 최소 납기요청일 설정
    READ TABLE lt_item_sum INTO DATA(ls_item_sum)
      WITH KEY banfn = ls_temp-banfn
      BINARY SEARCH.

    IF sy-subrc = 0.
      gs_header-item_cnt = ls_item_sum-item_cnt.
      gs_header-lfdat    = ls_item_sum-min_lfdat.
    ELSE.
*-- 모든 품목이 취소처리된 경우
      gs_header-item_cnt = 0.
      CLEAR gs_header-lfdat.
    ENDIF.

*-- 총 예상금액 설정
    READ TABLE lt_amt INTO DATA(ls_amt)
      WITH KEY banfn = ls_temp-banfn
      BINARY SEARCH.

    IF sy-subrc = 0.
      gs_header-total_amt = ls_amt-total_amt.
      gs_header-waers     = ls_amt-waers.
    ELSE.
      CLEAR : gs_header-total_amt,
              gs_header-waers.
    ENDIF.

*-- 상태 아이콘 설정
    CASE ls_temp-statu.
      WHEN 'CR'.
        gs_header-icon = icon_led_red.    " 확정대기 : 빨강
        gs_header-sort_group = 1.
        gs_header-sort_stat  = 1.
      WHEN 'PC'.
        gs_header-icon = icon_led_yellow. " 일부확정 : 노랑
        gs_header-sort_group = 1.
        gs_header-sort_stat  = 2.
      WHEN 'FC'.
        gs_header-icon = icon_led_green.  " 확정완료 : 초록
        gs_header-sort_group = 2.
        gs_header-sort_stat  = 3.
      WHEN OTHERS.
        CLEAR gs_header-icon.
    ENDCASE.

*-- 아이템 테이블에서 삭제한 행이 있으면 아이콘 설정
    READ TABLE lt_del INTO DATA(ls_del)
      WITH KEY banfn = ls_temp-banfn
      BINARY SEARCH.

    IF sy-subrc = 0.
      gs_header-del_icon = icon_checked.
    ELSE.
      CLEAR gs_header-del_icon.
    ENDIF.

*-- 납기잔여일수 계산
*-- 취소처리 안 된 품목 중 가장 빠른 납기요청일 기준
    CLEAR : gs_header-dday,
            gs_header-dday_txt,
            gs_header-cellcolor.

    IF gs_header-lfdat IS NOT INITIAL.
      DATA(lv_days) = gs_header-lfdat - sy-datum. " 납기요청일 - 오늘날짜

      gs_header-dday = lv_days.

*-- D-day 텍스트 설정 (상태 : FC면 빈 칸)
      IF ls_temp-statu = 'FC'.
        gs_header-dday_txt = '확정'.
      ELSEIF lv_days > 0.
        gs_header-dday_txt = |D-{ lv_days }|.
      ELSEIF lv_days = 0.
        gs_header-dday_txt = 'D-Day'.
      ELSE.
        gs_header-dday_txt = |D+{ lv_days * -1 }|.
      ENDIF.

*-- D+ 셀 빨강 표시 (미확정/일부확정만)
      IF lv_days < 0 AND ls_temp-statu <> 'FC'.
        CLEAR ls_cellcolor.
        ls_cellcolor-fname     = 'DDAY_TXT'.  " 색칠할 필드명
        ls_cellcolor-color-col = 6.           " 빨강
        ls_cellcolor-color-int = 1.           " 강조
        ls_cellcolor-color-inv = 0.

        APPEND ls_cellcolor TO gs_header-cellcolor.
      ENDIF.
    ENDIF.

    APPEND gs_header TO gt_header.

  ENDLOOP.

  CLEAR : lt_not_fc, lt_fc.

*-- 확정완료와 미확정/일부확정을 분리
  LOOP AT gt_header INTO gs_header.

    IF gs_header-statu = 'FC'.
      APPEND gs_header TO lt_fc.
    ELSE.
      APPEND gs_header TO lt_not_fc.
    ENDIF.

  ENDLOOP.

*-- 미확정/일부확정 : 납기잔여일수 우선
*-- D+초과 → D-Day → D-1 → D-2 순
  SORT lt_not_fc BY dday      ASCENDING
                    sort_stat ASCENDING
                    badat     ASCENDING
                    banfn     ASCENDING.

*-- 확정완료 : 구매요청번호 최신순
*-- 방금 확정된 PR이 확정완료 영역 맨 위에 보이게 함
  SORT lt_fc BY banfn DESCENDING.

*-- 합치기
  CLEAR gt_header.
  APPEND LINES OF lt_not_fc TO gt_header.
  APPEND LINES OF lt_fc     TO gt_header.

*-- PR 헤더 상태별 개수 카운트(버튼 표시)
  PERFORM set_status_counter.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_status_counter
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_status_counter .

  CLEAR : gv_cnt_all, gv_cnt_cr, gv_cnt_pc, gv_cnt_fc.

*-- PR 헤더 기준 개수
  gv_cnt_all = lines( gt_header ). " 전체 구매요청 개수

  LOOP AT gt_header INTO gs_header.
    CASE gs_header-statu.
      WHEN 'CR'. gv_cnt_cr = gv_cnt_cr + 1. " 확정대기 개수
      WHEN 'PC'. gv_cnt_pc = gv_cnt_pc + 1. " 일부확정 개수
      WHEN 'FC'. gv_cnt_fc = gv_cnt_fc + 1. " 확정완료 개수
    ENDCASE.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form search_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM search_pr .

*-- 날짜 범위 유효성 체크
  IF ztc1mm0025-badat IS NOT INITIAL
     AND gv_badat_to IS NOT INITIAL
     AND ztc1mm0025-badat > gv_badat_to.
    MESSAGE s420 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 조회버튼 클릭 시
  PERFORM set_prdata.
  PERFORM refresh_table USING go_left_alv.

*-- 우측 ALV 클리어
  PERFORM clear_right_side.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_double_click
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_ROW
*&      --> E_COLUMN
*&---------------------------------------------------------------------*
FORM handle_double_click  USING ps_row    TYPE lvc_s_row
                                ps_column TYPE lvc_s_col.

  READ TABLE gt_header INTO gs_header INDEX ps_row-index.
  CHECK sy-subrc = 0.

  PERFORM get_pr_detail USING gs_header-banfn.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_pr_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_HEADER_BANFN
*&---------------------------------------------------------------------*
FORM get_pr_detail  USING pv_banfn TYPE ztc1mm0025-banfn.

  CLEAR : gs_item, gt_item, gt_item_no, gt_item_ok.

*-- 공통정보 HTML 헤더 정보 갱신
  PERFORM set_header_html USING pv_banfn.

*-- 상세정보 조회
  SELECT banfn, bnfpo, matnr, maktx, price, waers, menge, meins,
         werks, lgort, lfdat, statu, ebeln, loekz
    FROM ztc1mm0026
   WHERE banfn = @pv_banfn
    INTO CORRESPONDING FIELDS OF TABLE @gt_item.

  PERFORM get_detail_maktx.
  PERFORM get_detail_price.
  PERFORM get_detail_lgort.

  SORT gt_item BY bnfpo.

*-- 확정/미확정 분리 및 상태 아이콘 설정
  LOOP AT gt_item INTO gs_item.

*-- 상세정보 MAKTX 설정 -> READ TABLE로 ZTC1MM0001에서 가져오기
    PERFORM set_detail_maktx.
    PERFORM set_detail_price.
    PERFORM set_detail_lgort.

    gs_item-total_mat_amt = gs_item-menge * gs_item-price.

    CASE gs_item-statu.
      WHEN 'CR'.
        IF gs_item-loekz = 'X'.
          gs_item-icon = icon_delete.
        ELSE.
          gs_item-icon = icon_led_red.
        ENDIF.
        APPEND gs_item TO gt_item_no.
      WHEN 'FC'.
        gs_item-icon = icon_led_green.
        APPEND gs_item TO gt_item_ok.
    ENDCASE.

    MODIFY gt_item FROM gs_item TRANSPORTING total_mat_amt.

  ENDLOOP.

*-- 확정/미확정 테이블 refresh
  PERFORM refresh_table USING go_right_mid_alv.
  PERFORM refresh_table USING go_right_bot_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_detail_maktx
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_detail_maktx .

  IF gt_item IS NOT INITIAL.

    SELECT mandt, matnr, maktx
      FROM ztc1mm0001
      FOR ALL ENTRIES IN @gt_item
     WHERE matnr = @gt_item-matnr
      INTO TABLE @gt_maktx.

    SORT gt_maktx BY matnr.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_detail_price
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_detail_price .

  IF gt_item IS NOT INITIAL.

    SELECT a~matnr,
           b~netpr AS price,
           b~waers,
           b~valid_from
      FROM ztc1mm0021 AS a
     INNER JOIN ztc1mm0022 AS b
        ON a~infnr = b~infnr
      FOR ALL ENTRIES IN @gt_item
     WHERE a~matnr      = @gt_item-matnr
       AND a~loekz      = ''
       AND b~loekz      = ''
       AND b~valid_from <= @sy-datum
       AND b~valid_to   >= @sy-datum
      INTO CORRESPONDING FIELDS OF TABLE @gt_price.

    SORT gt_price BY matnr ASCENDING
                    valid_from DESCENDING.

    DELETE ADJACENT DUPLICATES FROM gt_price COMPARING matnr.

  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_detail_maktx
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_detail_maktx .

  IF gs_item-maktx IS INITIAL.
    READ TABLE gt_maktx INTO gs_maktx
      WITH KEY matnr = gs_item-matnr
      BINARY SEARCH.
    IF sy-subrc = 0.
      gs_item-maktx = gs_maktx-maktx.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_detail_price
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_detail_price .

  READ TABLE gt_price INTO gs_price
    WITH KEY matnr = gs_item-matnr
    BINARY SEARCH.
  IF sy-subrc = 0.
    gs_item-price = gs_price-price.
    gs_item-waers = gs_price-waers.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_header_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PV_BANFN
*&---------------------------------------------------------------------*
FORM  set_header_html  USING pv_banfn TYPE ztc1mm0025-banfn.

*-- PR 더블클릭 시 동적으로 HTML 헤더 세팅
  DATA : lt_html  TYPE TABLE OF char255,  " html코드 담긴 Internal table
         lv_url   TYPE char255,           " html viewer 임시 url
         ls_head  TYPE ztc1mm0025,        " 더블클릭한 행의 pr 헤더 데이터를 담는 구조
         lv_statu TYPE char10,            " 텍스트 값
         lv_estkz TYPE char10,            " 텍스트 값
         lv_color TYPE char7,             " 색 지정
         lv_afnam TYPE ztc1mm0025-afnam,
         lv_dept  TYPE zec1_hr_dept,      " 요청자 부서
         lv_reqr  TYPE char40,            " 부서/이름 표시값
         lv_badat(10).

  SELECT SINGLE *
    FROM ztc1mm0025
   WHERE banfn = @pv_banfn
    INTO @ls_head.

*-- 요청자명 세팅
  lv_afnam = ls_head-afnam.

  IF lv_afnam IS INITIAL.
    PERFORM get_user_name USING    ls_head-ernam
                          CHANGING lv_afnam.
  ENDIF.

*-- 요청자 부서 조회
  CLEAR lv_dept.
  SELECT SINGLE dept
    FROM ztc1hr0001
   WHERE uname = @ls_head-ernam
    INTO @lv_dept.

*-- 부서/이름 형태로 조합
  IF lv_dept IS NOT INITIAL.
    lv_reqr = |{ lv_dept } / { lv_afnam }|.
  ELSE.
    lv_reqr = lv_afnam.
  ENDIF.

*-- 요청일 YYYY.MM.DD 형태로 변환
  CLEAR lv_badat.
  IF ls_head-badat IS NOT INITIAL.
    lv_badat = |{ ls_head-badat+0(4) }.{ ls_head-badat+4(2) }.{ ls_head-badat+6(2) }|.
  ENDIF.

  CASE ls_head-statu.
    WHEN 'CR'.
      lv_statu = '미확정'.
      lv_color = '#D32F2F'.
    WHEN 'PC'.
      lv_statu = '일부확정'.
      lv_color = '#F9A825'.
    WHEN 'FC'.
      lv_statu = '확정완료'.
      lv_color = '#2E7D32'.
    WHEN 'DL'.
      lv_statu = '삭제'.
      lv_color = '#757575'.
    WHEN OTHERS.
      lv_statu = ls_head-statu.
      lv_color = '#555'.
  ENDCASE.

  CASE ls_head-estkz.
    WHEN 'R'.
      lv_estkz = '수동'.
    WHEN 'B'.
      lv_estkz = 'MRP'.
    WHEN OTHERS.
      lv_estkz = ls_head-estkz.
  ENDCASE.

*-- html 코드 lt_html에 적재
  APPEND '<html><body style="font-family:Arial; font-size:11px; margin:2px 4px; background:#D5DFE8; overflow:hidden;">' TO lt_html.
  APPEND '<div style="border:1px solid #1F3A52; background:linear-gradient(135deg,#E3ECF4,#F0F5FA); padding:6px 8px; border-radius:3px;">' TO lt_html.

*-- 타이틀
  APPEND '<div style="display:flex; align-items:center; margin-bottom:2px; padding-left:8px;">' TO lt_html.
  APPEND '<span style="width:14px; height:14px; margin-right:6px; border:1px solid #5B829D; background:#EAF3F9; color:#1E5C89; font-size:10px; font-weight:900; line-height:12px; text-align:center; display:inline-block;">i</span>' TO lt_html.
  APPEND '<b style="font-size:12px; color:#1F3A52;">구매요청 상세 정보</b>' TO lt_html.
  APPEND '</div>' TO lt_html.
  APPEND '<hr style="border:0; border-top:1px solid #7A9BB8; margin:4px 8px;">' TO lt_html.

*-- 데이터 테이블
  APPEND '<table style="font-size:11px; width:100%; border-collapse:collapse; table-layout:fixed;">' TO lt_html.

*-- 1행
  APPEND '<tr>' TO lt_html.
  APPEND |<td style="color:#555; padding:3px 8px; width:10%; white-space:nowrap;">구매요청 번호</td>| TO lt_html.
  APPEND |<td style="font-weight:bold; padding:3px 8px; width:27%; color:#0D2538;">{ ls_head-banfn }</td>| TO lt_html.
  APPEND |<td style="color:#555; padding:3px 8px; width:10%; white-space:nowrap;">요청일</td>| TO lt_html.
  APPEND |<td style="padding:3px 8px; width:27%;">{ lv_badat }</td>| TO lt_html.
  APPEND |<td style="color:#555; padding:3px 8px; width:10%; white-space:nowrap;">상태</td>| TO lt_html.
  APPEND |<td style="padding:3px 8px; width:16%;"><span style="| TO lt_html.
  APPEND |background:{ lv_color }; color:#fff; padding:1px 8px; border-radius:3px; font-weight:bold;| TO lt_html.
  APPEND |">{ lv_statu }</span></td>| TO lt_html.
  APPEND '</tr>' TO lt_html.

*-- 2행
  APPEND '<tr>' TO lt_html.
  APPEND |<td style="color:#555; padding:3px 8px; width:10%; white-space:nowrap;">구매조직</td>| TO lt_html.
  APPEND |<td style="padding:3px 8px; width:27%;">{ ls_head-ekorg }</td>| TO lt_html.
  APPEND |<td style="color:#555; padding:3px 8px; width:10%; white-space:nowrap;">요청자</td>| TO lt_html.
  APPEND |<td style="padding:3px 8px; width:27%;">{ lv_reqr }</td>| TO lt_html.
  APPEND |<td style="color:#555; padding:3px 8px; width:10%; white-space:nowrap;">생성구분</td>| TO lt_html.
  APPEND |<td style="padding:3px 8px; width:16%;">{ lv_estkz }</td>| TO lt_html.
  APPEND '</tr>' TO lt_html.

  APPEND '</table></div></body></html>' TO lt_html.

*-- ABAP 내부 HTML 데이터를 SAP GUI HTML Viewer에 업로드
  CALL METHOD go_html_viewer->load_data
    EXPORTING
      type                 = 'text'
      subtype              = 'html'
    IMPORTING
      assigned_url         = lv_url   " 내가 사용할 수 있는 url 생성
    CHANGING
      data_table           = lt_html  " html코드 들어있는 Internal table
    EXCEPTIONS
      dp_error_general     = 1
      dp_invalid_parameter = 2
      OTHERS               = 3.

*-- url 화면에 띄움
  CALL METHOD go_html_viewer->show_url
    EXPORTING
      url                    = lv_url " url 등록
    EXCEPTIONS
      cntl_error             = 1
      cnht_error_not_allowed = 2
      cnht_error_parameter   = 3
      dp_error_general       = 4
      OTHERS                 = 5.

  CALL METHOD cl_gui_cfw=>flush.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form pr_request_h
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM pr_request_h .

*-- PR 헤더 기준 PR확정
  DATA : lt_rows     TYPE lvc_t_row,
         ls_rows     TYPE lvc_s_row,
         lv_answer,
         lv_cr       TYPE i,       " 선택한 행의 개수
         lv_question TYPE char100. " 구매요청 확정 버튼 클릭 시 메세지 팝업

*-- 선택한 행의 index를 가져오는 코드
  CALL METHOD go_left_alv->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

*-- 행 개수에 따른 로직 구현
  CASE lines( lt_rows ).
    WHEN 0.
*-- 행 선택 X시 메세지 출력
      MESSAGE s400 DISPLAY LIKE 'E'.
    WHEN 1.
      READ TABLE lt_rows INTO ls_rows INDEX 1.
      READ TABLE gt_header INTO gs_header INDEX ls_rows-index.
      CHECK sy-subrc = 0.

*-- 이미 확정완료된 구매요청은 확정 불가능 메세지 출력
      IF gs_header-statu = 'FC'.
        MESSAGE s402 WITH gs_header-banfn DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

*--   미확정(CR) 품목 수 계산
      SELECT COUNT(*)
        FROM ztc1mm0026
       WHERE banfn = @gs_header-banfn
         AND statu = 'CR'
         AND loekz = ''
        INTO @lv_cr.

      MESSAGE i406 WITH lv_cr INTO lv_question.


      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = '[Taesan] 구매요청 확정'
          text_question         = lv_question
          text_button_1         = '예'
          icon_button_1         = 'ICON_OKAY'
          text_button_2         = '아니오'
          icon_button_2         = 'ICON_CANCEL'
          display_cancel_button = ' '
          start_column          = 65
          start_row             = 10
        IMPORTING
          answer                = lv_answer.

      IF lv_answer NE '1'.
        EXIT.
      ENDIF.

*-- '네' 누를 경우 그 행의 품목별 구매요청을 모두 확정지음
      UPDATE ztc1mm0026 SET statu = 'FC'
       WHERE banfn = gs_header-banfn
         AND statu = 'CR'
         AND loekz = ''.

      PERFORM save_confirm_data USING gs_header-banfn. " 구매요청 아이템 테이블에 데이터 저장

*-- PR 헤더의 상태 아이콘 변경
      PERFORM update_header_status USING gs_header-banfn.

      COMMIT WORK AND WAIT.
      MESSAGE s403.

*-- 좌측 PR 목록만 갱신
      PERFORM refresh_left_only.

*-- 우측 ALV초기화
      PERFORM clear_right_side.

    WHEN OTHERS.
*-- 행 2개 이상 선택시 메세지 출력
      MESSAGE s401 DISPLAY LIKE 'E'.
  ENDCASE.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form pr_request_i
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM pr_request_i .

*-- PR 아이템 기준 PR확정
  DATA : lt_rows     TYPE lvc_t_row,
         ls_rows     TYPE lvc_s_row,
         lt_item_no  LIKE TABLE OF gs_item,
         lv_answer,
         lv_cr       TYPE i,        " 상세정보의 미확정 개수
         lv_del      TYPE i,        " 삭제 행 개수
         lv_question TYPE char100.  " 구매요청 확정 버튼 클릭 시 메세지 팝업

*-- 선택한 행의 index를 가져오는 코드
  CALL METHOD go_right_mid_alv->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  IF lt_rows IS INITIAL.
    MESSAGE s400 DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  LOOP AT lt_rows INTO ls_rows.

    READ TABLE gt_item_no INTO gs_item INDEX ls_rows-index.
    CHECK sy-subrc = 0.

    IF gs_item-loekz = 'X'.
      lv_del += 1.
      CONTINUE.
    ENDIF.

    lv_cr += 1.

    APPEND gs_item TO lt_item_no.

  ENDLOOP.

*-- 구매요청 확정 버튼 눌렀을 시 메세지 출력
  IF lv_del > 0 AND lv_cr = 0.
    MESSAGE s404 DISPLAY LIKE 'E'.
    RETURN.
  ELSEIF lv_del > 0.
    MESSAGE i405 WITH lv_cr lv_del INTO lv_question.
  ELSE.
    MESSAGE i406 WITH lv_cr INTO lv_question.
  ENDIF.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '[Taesan] 구매요청 확정'
      text_question         = lv_question
      text_button_1         = '예'
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = '아니오'
      icon_button_2         = 'ICON_CANCEL'
      display_cancel_button = ' '
      start_column          = 65
      start_row             = 10
    IMPORTING
      answer                = lv_answer.

  IF lv_answer NE '1'.
    EXIT.
  ENDIF.

*-- '네' 누를 경우 그 행의 품목별 구매요청을 모두 확정지음
  LOOP AT lt_item_no INTO DATA(ls_item_no).

    UPDATE ztc1mm0026 SET statu = 'FC'
    WHERE bnfpo = @ls_item_no-bnfpo
      AND banfn = @ls_item_no-banfn
      AND statu = 'CR'.

    PERFORM save_confirm_data USING gs_header-banfn. " 구매요청 아이템 테이블에 데이터 저장

  ENDLOOP.

*-- PR 헤더의 상태 아이콘 변경
  PERFORM update_header_status USING ls_item_no-banfn.

  COMMIT WORK AND WAIT.
  MESSAGE s403.

*-- 좌측 PR 목록만 갱신
  PERFORM refresh_left_only.

*-- 상세 새로고침 (미확정 → 확정 이동)
  PERFORM get_pr_detail USING ls_item_no-banfn.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_confirm_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_HEADER_BANFN
*&---------------------------------------------------------------------*
FORM save_confirm_data  USING pv_banfn TYPE ztc1mm0025-banfn..

  DATA: lv_maktx TYPE ztc1mm0026-maktx,
        lv_meins TYPE ztc1mm0026-meins,
        lv_price TYPE ztc1mm0026-price,
        lv_waers TYPE ztc1mm0026-waers.

  SELECT banfn, bnfpo, matnr
    FROM ztc1mm0026
   WHERE banfn = @pv_banfn
     AND statu = 'FC'
     AND loekz = ''
    INTO TABLE @DATA(lt_items).

  LOOP AT lt_items INTO DATA(ls_item).

    PERFORM get_matnr_info USING    ls_item-matnr
                           CHANGING lv_maktx
                                    lv_meins
                                    lv_price
                                    lv_waers.

    UPDATE ztc1mm0026 SET maktx = lv_maktx
                          price = lv_price
                          waers = lv_waers
     WHERE banfn = ls_item-banfn
       AND bnfpo = ls_item-bnfpo.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form update_header_status
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_HEADER_BANFN
*&---------------------------------------------------------------------*
FORM update_header_status  USING pv_banfn TYPE ztc1mm0025-banfn.

  DATA : lv_total TYPE i,     " 전체 개수 (삭제안된 것)
         lv_fc    TYPE i.     " 상세정보의 확정완료 개수


*-- 총 품목개수(삭제 제외)
  SELECT COUNT(*)
    FROM ztc1mm0026
   WHERE banfn = @pv_banfn
     AND loekz = ''
    INTO @lv_total.

*-- 확정완료 개수(삭제 제외)
  SELECT COUNT(*)
    FROM ztc1mm0026
   WHERE banfn = @pv_banfn
     AND statu = 'FC'
     AND loekz = ''
    INTO @lv_fc.

*-- 확정완료에 따라 PR 헤더 리스트의 상태 업데이트
  IF lv_fc = lv_total.
    UPDATE ztc1mm0025 SET statu = 'FC' WHERE banfn = pv_banfn.
  ELSEIF lv_fc = 0.
    UPDATE ztc1mm0025 SET statu = 'CR' WHERE banfn = pv_banfn.
  ELSE.
    UPDATE ztc1mm0025 SET statu = 'PC' WHERE banfn = pv_banfn.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_alv_checkbox
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ER_DATA_CHANGED
*&---------------------------------------------------------------------*
FORM handle_alv_checkbox  USING pr_data_changed TYPE REF TO cl_alv_changed_data_protocol.

  DATA : ls_modi  TYPE lvc_s_modi, " 변경 값, 행 번호 등
         lv_banfn TYPE ztc1mm0025-banfn.

*-- 변경된 셀 정보 읽기 (체크박스 1개)
  READ TABLE pr_data_changed->mt_mod_cells INTO ls_modi INDEX 1.

  IF sy-subrc = 0 AND ls_modi-fieldname = 'LOEKZ'.
*-- 변경된 행 읽기
    READ TABLE gt_item_no INTO gs_item INDEX ls_modi-row_id.
    CHECK sy-subrc = 0.

    lv_banfn = gs_item-banfn.

*-- DB 즉시 UPDATE (체크='X' / 해제='')
    UPDATE ztc1mm0026 SET loekz = ls_modi-value
     WHERE banfn = gs_item-banfn
       AND bnfpo = gs_item-bnfpo.

    COMMIT WORK AND WAIT.

*-- PR 헤더의 상태 아이콘 변경
    PERFORM update_header_status USING lv_banfn.

*-- 좌측 PR 목록만 갱신
    PERFORM refresh_left_only.

*-- 현재 선택 PR 상세 다시 조회
    PERFORM get_pr_detail USING lv_banfn.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form pr_modify
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM pr_modify .

*-- 선택한 PR 수정팝업
  DATA : lt_rows TYPE lvc_t_row,
         ls_rows TYPE lvc_s_row,
         ls_head TYPE ztc1mm0025.

*-- 선택한 행의 index를 가져오는 코드
  CALL METHOD go_right_mid_alv->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

*-- 행 개수에 따른 로직 구현
  CASE lines( lt_rows ).
    WHEN 0.
*-- 행 선택 X시 메세지 출력
      MESSAGE s407 DISPLAY LIKE 'E'.
    WHEN 1.
      READ TABLE lt_rows INTO ls_rows INDEX 1.
      READ TABLE gt_item_no INTO gs_item INDEX ls_rows-index.
      CHECK sy-subrc = 0.

*-- MRP로 생성된 PR은 수정경고 메세지
      SELECT SINGLE banfn estkz
        INTO CORRESPONDING FIELDS OF ls_head
        FROM ztc1mm0025
       WHERE banfn = gs_item-banfn.

      IF sy-subrc = 0 AND ls_head-estkz = 'B'.
        MESSAGE i412 DISPLAY LIKE 'E'.  " MRP 생성건 수정경고
      ENDIF.

*-- 이미 삭제처리된 구매요청은 수정 불가능
      IF gs_item-loekz = 'X'.
        MESSAGE s408 DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      CALL SCREEN 200 STARTING AT 95 4 ENDING AT 163 13.
    WHEN OTHERS.
*-- 행 2개 이상 선택시 메세지 출력
      MESSAGE s401 DISPLAY LIKE 'E'.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_modify
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_modify .

  IF go_modi_pop IS NOT BOUND.

    CREATE OBJECT go_modi_pop
      EXPORTING
        container_name = 'MODIFY_CONT'.

    CREATE OBJECT go_modi_alv
      EXPORTING
        i_parent = go_modi_pop.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_modify_screen
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_modify_screen .

*-- 수정팝업 필드 편집 가능 여부 설정
  LOOP AT SCREEN.

    CASE screen-name.
*-- 편집 허용
      WHEN 'GS_ITEM-MATNR'
        OR 'GS_ITEM-MENGE'
        OR 'GS_ITEM-WERKS'
        OR 'GS_ITEM-LGORT'
        OR 'GS_ITEM-LFDAT'.
        screen-input = 1.

*-- 나머지는 readonly
      WHEN OTHERS.
        IF screen-name CP 'GS_ITEM-*'.
          screen-input = 0.
        ENDIF.
    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_f4_matnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_f4_matnr .

*-- MATNR Search help 생성
  SELECT matnr, maktx
    FROM ztc1mm0001
   WHERE mtart = 'ROH'
     AND lvorm <> 'X'
    INTO TABLE @gt_sh_matnr.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_f4_help
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_f4_help .

  DATA : lt_return LIKE TABLE OF ddshretval WITH HEADER LINE.

  PERFORM set_f4_matnr.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'MATNR'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'GS_ITEM-MATNR'
      window_title    = '[Taesan] 자재 번호'
      value_org       = 'S'
    TABLES
      value_tab       = gt_sh_matnr
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

*-- 선택한 자재의 내역을 세팅
  IF lt_return[] IS NOT INITIAL.

    lt_return = VALUE #( lt_return[ 1 ] OPTIONAL ).
    gs_sh_matnr = VALUE #( gt_sh_matnr[ matnr = lt_return-fieldval ] OPTIONAL ).

    gs_item-matnr = lt_return-fieldval.

*-- 자재명/단위/단가/통화 조회 (공통 FORM 활용)
    PERFORM get_matnr_info USING    gs_item-matnr
                           CHANGING gs_item-maktx
                                    gs_item-meins
                                    gs_item-price
                                    gs_item-waers.

    CLEAR gs_item-menge.
    gs_item-total_mat_amt = gs_item-menge * gs_item-price.

    PERFORM update_screen_field.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form update_screen_field
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM update_screen_field.

  DATA : lt_read      TYPE TABLE OF dynpread WITH HEADER LINE,
         lv_total(20),
         lv_price(20),
         lv_menge(20).

*-- Conversion amount
  WRITE : gs_item-price         CURRENCY gs_item-waers TO lv_price,
          gs_item-total_mat_amt CURRENCY gs_item-waers TO lv_total.

*-- Set value to screen field
  lt_read[] = VALUE #(
                       ( fieldname  = 'GS_ITEM-MATNR'
                         fieldvalue = gs_item-matnr )

                       ( fieldname  = 'GS_ITEM-MAKTX'
                         fieldvalue = gs_item-maktx )

                       ( fieldname  = 'GS_ITEM-TOTAL_MAT_AMT'
                         fieldvalue = lv_total )

                       ( fieldname  = 'GS_ITEM-PRICE'
                         fieldvalue = lv_price )

                       ( fieldname  = 'GS_ITEM-MENGE')
                      ).


*-- 공백제거
  CONDENSE lt_read-fieldvalue NO-GAPS.
  APPEND lt_read.

*-- Update screen field value
  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_read.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_mat_total
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM calc_mat_total .

  gs_item-total_mat_amt = gs_item-menge * gs_item-price.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form modify_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM modify_pr .

  DATA : ls_update         TYPE ztc1mm0026,
         lv_selected_banfn TYPE ztc1mm0025-banfn, " 내가 선택한 행을 저장하는 변수 -> 수정팝업창 이후 초기화 방지
         lv_valid          TYPE flag.             " 유효성 체크 결과 플래그

*-- 자재번호 유효성 체크
  PERFORM check_matnr_valid USING    gs_item-matnr
                            CHANGING lv_valid.
  CHECK lv_valid = 'X'.

  SELECT SINGLE *
    FROM ztc1mm0026
    INTO ls_update
   WHERE banfn = gs_item-banfn
     AND bnfpo = gs_item-bnfpo.

  IF sy-subrc = 0.
    MOVE-CORRESPONDING gs_item TO ls_update.
  ENDIF.

  UPDATE ztc1mm0026 FROM ls_update.
  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE '저장되었습니다.' TYPE 'S'.

*-- 현재 선택된 BANFN 저장
    lv_selected_banfn = gs_item-banfn.

*-- 좌측 PR 목록만 갱신
    PERFORM refresh_left_only.

*-- 상세정보 갱신
    PERFORM get_pr_detail USING lv_selected_banfn.
    LEAVE TO SCREEN 0.
  ELSE.
    ROLLBACK WORK.
    MESSAGE '저장 실패.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_toolbar_create
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM handle_toolbar_create  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

*-- 표준 버튼 제거
  CLEAR po_object->mt_toolbar.

*-- 처리상태 필터 버튼
  CLEAR gs_button.
  gs_button-function  = 'NEW'.
  gs_button-icon      = icon_system_undo.
  gs_button-text      = '  초기화  '.
  APPEND gs_button TO po_object->mt_toolbar.

  CLEAR gs_button.
  gs_button-function  = 'ADD'.
  gs_button-icon      = icon_positive.
  gs_button-text      = '  품목 추가  '.
  APPEND gs_button TO po_object->mt_toolbar.

  CLEAR gs_button.
  gs_button-function  = 'DEL'.
  gs_button-icon      = icon_negative.
  gs_button-text      = '  품목 삭제  '.
  APPEND gs_button TO po_object->mt_toolbar.

*-- 구분선
  CLEAR gs_button.
  gs_button-butn_type = 3.
  APPEND gs_button TO po_object->mt_toolbar.

  CLEAR gs_button.
  gs_button-function  = 'SAVE'.
  gs_button-icon      = icon_create.
  gs_button-text      = '  생성  '.
  APPEND gs_button TO po_object->mt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form init_create_row
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM init_create_row .

  CLEAR : gs_create, gt_create.

  gs_create-bnfpo = 10.
  gs_create-werks = 'TS00'.
  gs_create-lgort = 'SL10'.

  PERFORM set_create_lgort_txt.

  PERFORM set_screen_change .

  APPEND gs_create TO gt_create.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_new
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_new .

  PERFORM init_create_row.

  PERFORM refresh_table USING go_create_alv.
  PERFORM set_summary_html.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form add_row
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM add_row .

  DATA lv_bnfpo TYPE ztc1mm0026-bnfpo.

  lv_bnfpo = 10.

*-- 10부터 시작해서 비어있는 번호 찾기 : 무한루프
  WHILE abap_true = abap_true.

    READ TABLE gt_create TRANSPORTING NO FIELDS
         WITH KEY bnfpo = lv_bnfpo.                " gt_create 안에 lv_bnfpo와 같은 bnfpo가 있는지 확인

    IF sy-subrc <> 0.
      EXIT.            " 없는 번호 발견 -> 종료 후 +10
    ENDIF.

    lv_bnfpo = lv_bnfpo + 10.

  ENDWHILE.

*-- 새 행 생성
  CLEAR gs_create.
  gs_create-bnfpo = lv_bnfpo.
  gs_create-werks = 'TS00'.
  gs_create-lgort = 'SL10'.

*-- 저장위치명 세팅
  PERFORM set_create_lgort_txt.

*-- 스타일 세팅
  PERFORM set_screen_change.

  APPEND gs_create TO gt_create.

  SORT gt_create BY bnfpo ASCENDING.

  PERFORM refresh_table USING go_create_alv.
  PERFORM set_summary_html.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form del_row
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM del_row .

  DATA : lt_roid TYPE lvc_t_roid, " 선택된 행의 인덱스 정보를 담는 테이블
         ls_roid TYPE lvc_s_roid.

*-- Get selected row index at ALV
  CALL METHOD go_create_alv->get_selected_rows
    IMPORTING
      et_row_no = lt_roid. " 사용자가 체크박스나 클릭으로 선택한 행들의 인덱스를 lt_roid에 저장

*-- 선택한 행이 있는지 확인
  IF lt_roid IS INITIAL.
    MESSAGE s504 DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

*-- 선택된 행을 Internal table에서 삭제 - 역순으로 삭제 -> Index가 바뀌기 때문에
  SORT lt_roid BY row_id DESCENDING.
  LOOP AT lt_roid INTO ls_roid.

    CLEAR gs_create.

*-- 선택 행 삭제
    DELETE gt_create INDEX ls_roid-row_id.

  ENDLOOP.

*-- ALV 새로고침
  PERFORM refresh_table USING go_create_alv.
  PERFORM set_summary_html.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM save_pr .

  DATA : lv_banfn    TYPE ztc1mm0026-banfn,
         ls_head     TYPE ztc1mm0025,
         ls_item     TYPE ztc1mm0026,
         lv_answer,
         lv_question TYPE char100,
         lv_check    TYPE string.

  CALL METHOD go_create_alv->check_changed_data.

*-- 유효성 체크
  LOOP AT gt_create INTO gs_create.

    CLEAR lv_check.

    IF gs_create-matnr IS INITIAL.
      lv_check = '자재번호'.
    ELSEIF gs_create-menge IS INITIAL OR gs_create-menge = 0.
      lv_check = '수량'.
    ELSEIF gs_create-werks IS INITIAL.
      lv_check = '플랜트'.
    ELSEIF gs_create-lgort IS INITIAL.
      lv_check = '저장위치'.
    ELSEIF gs_create-lfdat IS INITIAL.
      lv_check = '납기요청일'.
    ENDIF.

    IF lv_check IS NOT INITIAL.
      MESSAGE s411 WITH lv_check DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

  ENDLOOP.

  MESSAGE i410 INTO lv_question.

*-- 생성 확인 팝업
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '[Taesan] 생성'
      text_question         = lv_question
      text_button_1         = '예'
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = '아니오'
      icon_button_2         = 'ICON_CANCEL'
      display_cancel_button = ' '
      start_column          = 65
      start_row             = 5
    IMPORTING
      answer                = lv_answer.

  IF lv_answer NE '1'.
    EXIT.
  ENDIF.

*-- BANFN(구매요청번호) 자동채번
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = 'PR'          " 번호범위
      object                  = 'ZNRC1MM01'   " SNRO 오브젝트
    IMPORTING
      number                  = lv_banfn
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.


*-- 헤더 INSERT (ZTC1MM0025)
  CLEAR ls_head.
  ls_head-banfn = lv_banfn.
  ls_head-badat = sy-datum.
  ls_head-ekorg = 'P100'.
  ls_head-ernam = sy-uname.
  ls_head-statu = 'CR'.
  ls_head-estkz = 'R'.

*-- hr테이블 사용해서 요청자 이름
  ls_head-ernam = sy-uname.
  PERFORM get_user_name USING    sy-uname
                        CHANGING ls_head-afnam.

  READ TABLE gt_create TRANSPORTING NO FIELDS WITH KEY purrsn = 'URGENT'.
  IF sy-subrc = 0.
    ls_head-bsart = 'ZEMG'.   " 긴급구매
  ELSE.
    ls_head-bsart = 'NB'.     " 일반구매
  ENDIF.

  INSERT ztc1mm0025 FROM ls_head.

*-- 품목 INSERT (ZTC1MM0026)
  LOOP AT gt_create INTO gs_create.

    CLEAR ls_item.
    MOVE-CORRESPONDING gs_create TO ls_item.

*-- 공통 필드 세팅
    ls_item-banfn = lv_banfn.
    ls_item-statu = 'CR'.
    ls_item-loekz = ''.

    IF ls_item-purrsn IS INITIAL.
      ls_item-purrsn = 'ETC'.   "*-- 선택 안 했을 때 기본값
    ENDIF.

    INSERT ztc1mm0026 FROM ls_item.

  ENDLOOP.

  COMMIT WORK AND WAIT.

  MESSAGE s409 WITH lv_banfn.

*-- 화면 초기화
  PERFORM init_create_row.

  PERFORM get_preview_banfn.
  PERFORM set_create_header_html.

  PERFORM refresh_table USING go_create_alv.
  PERFORM set_summary_html.

*-- 좌측 PR 조회 리스트 갱신
  PERFORM search_pr.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_screen_change
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_screen_change .

  CLEAR gs_create-celltab.

*-- 자동세팅 필드 읽기전용 설정
  gs_create-celltab = VALUE #(
                               style = cl_gui_alv_grid=>mc_style_disabled
                               ( fieldname = 'BNFPO'         )
                               ( fieldname = 'MAKTX'         )
                               ( fieldname = 'MEINS'         )
                               ( fieldname = 'WERKS'         )
                               ( fieldname = 'LGORT'         )
                               ( fieldname = 'LGORT_TXT'     )
                               ( fieldname = 'PRICE'         )
                               ( fieldname = 'WAERS'         )
                               ( fieldname = 'TOTAL_MAT_AMT' )
                              ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_matnr_info
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LS_MODI_VALUE
*&      <-- LV_MAKTX
*&      <-- LV_MEINS
*&      <-- LV_PRICE
*&      <-- LV_WAERS
*&---------------------------------------------------------------------*
FORM get_matnr_info USING    pv_matnr TYPE ztc1mm0026-matnr
                    CHANGING cv_maktx TYPE ztc1mm0026-maktx
                             cv_meins TYPE ztc1mm0026-meins
                             cv_price TYPE ztc1mm0026-price
                             cv_waers TYPE ztc1mm0026-waers.

  CLEAR: cv_maktx, cv_meins, cv_price, cv_waers.

*-- 자재명 / 단위
  SELECT SINGLE maktx, meins
    INTO (@cv_maktx, @cv_meins)
    FROM ztc1mm0001
   WHERE matnr = @pv_matnr.

*-- 단가 / 통화 (sy-datum 기준 유효한 행만)
  SELECT SINGLE b~netpr, b~waers
    INTO (@cv_price, @cv_waers)
    FROM ztc1mm0021 AS a
    INNER JOIN ztc1mm0022 AS b
      ON a~infnr = b~infnr
   WHERE a~matnr      = @pv_matnr
     AND a~loekz      = ''
     AND b~loekz      = ''
     AND b~valid_from <= @sy-datum
     AND b~valid_to   >= @sy-datum.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_modify_value
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_MODIFIED
*&      --> ET_GOOD_CELLS
*&---------------------------------------------------------------------*
FORM handle_modify_value  USING    pv_modified
                                   pt_good_cells TYPE lvc_t_modi.

  DATA: ls_modi  TYPE lvc_s_modi,
        lv_maktx TYPE ztc1mm0026-maktx,
        lv_meins TYPE ztc1mm0026-meins,
        lv_price TYPE ztc1mm0026-price,
        lv_waers TYPE ztc1mm0026-waers,
        lv_matnr TYPE ztc1mm0026-matnr,
        lv_lfdat TYPE ztc1mm0026-lfdat,
        lv_valid TYPE flag.

  CHECK pv_modified IS NOT INITIAL.

  LOOP AT pt_good_cells INTO ls_modi.

    READ TABLE gt_create INTO gs_create INDEX ls_modi-row_id.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    CASE ls_modi-fieldname.

      WHEN 'MATNR'.
        lv_matnr = ls_modi-value.

*-- 자재번호 유효성 체크
        PERFORM check_matnr_valid USING    lv_matnr
                                  CHANGING lv_valid.

*-- 유효성 체크 불합격 -> 값 초기화
        IF lv_valid <> 'X'.
          CLEAR: gs_create-matnr, gs_create-maktx, gs_create-meins,
                 gs_create-price, gs_create-waers, gs_create-total_mat_amt.
          MODIFY gt_create FROM gs_create INDEX ls_modi-row_id
            TRANSPORTING matnr maktx meins price waers total_mat_amt.
          CONTINUE.
        ENDIF.

*-- 유효성 체크 통과 -> 값 자동세팅
        PERFORM get_matnr_info USING    lv_matnr
                               CHANGING lv_maktx
                                        lv_meins
                                        lv_price
                                        lv_waers.

        gs_create-matnr = lv_matnr.
        gs_create-maktx = lv_maktx.
        gs_create-meins = lv_meins.
        gs_create-price = lv_price.
        gs_create-waers = lv_waers.

        IF gs_create-menge IS INITIAL.
          CLEAR gs_create-total_mat_amt.
        ELSE.
          gs_create-total_mat_amt = gs_create-menge * gs_create-price.
        ENDIF.

        MODIFY gt_create FROM gs_create INDEX ls_modi-row_id
          TRANSPORTING matnr maktx meins price waers total_mat_amt.

      WHEN 'MENGE'. " 수량 변경 시 총 금액 재계산
        gs_create-menge = ls_modi-value.
        gs_create-total_mat_amt = gs_create-menge * gs_create-price.

        MODIFY gt_create FROM gs_create INDEX ls_modi-row_id
          TRANSPORTING menge total_mat_amt.

      WHEN 'LFDAT'. " 납기요청일 과거 체크
        lv_lfdat = ls_modi-value.

        IF lv_lfdat < sy-datum.
          MESSAGE s419 DISPLAY LIKE 'E'.   " '납기요청일은 오늘 이후여야 합니다.'
          CLEAR gs_create-lfdat.
        ELSE.
          gs_create-lfdat = lv_lfdat.
        ENDIF.

        MODIFY gt_create FROM gs_create INDEX ls_modi-row_id
          TRANSPORTING lfdat.

    ENDCASE.

  ENDLOOP.

  PERFORM refresh_table USING go_create_alv.
  PERFORM set_summary_html.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_summary_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_summary_html .

  DATA: lt_html     TYPE TABLE OF char255,
        lv_url      TYPE char255,
        lv_cnt      TYPE i,
        lv_qty      TYPE menge_d,
        lv_amt      TYPE p LENGTH 13 DECIMALS 2,
        lv_qty_disp TYPE char20,
        lv_amt_disp TYPE char20.

*-- 집계 계산
  lv_cnt = lines( gt_create ).

  LOOP AT gt_create INTO gs_create.
    lv_qty = lv_qty + gs_create-menge.
    lv_amt = lv_amt + ( gs_create-menge * gs_create-price ).
  ENDLOOP.

*-- 수량: 소수점 제거 + 천단위 콤마
  WRITE lv_qty TO lv_qty_disp DECIMALS 0.
  CONDENSE lv_qty_disp.

*-- 금액: 소수점 제거 + 천단위 콤마 (KRW는 정수 통화)
  WRITE lv_amt TO lv_amt_disp CURRENCY 'KRW'.
  CONDENSE lv_amt_disp.

**-- html 코드 적재
*  APPEND '<html><body style="font-family:Arial; font-size:11px; margin:0; padding:8px; background:#D5DFE8;">' TO lt_html.
*  APPEND '<div style="border:1px solid #1F3A52; background:linear-gradient(135deg,#E3ECF4,#F0F5FA); padding:10px; border-radius:3px;">' TO lt_html.
*
*  APPEND '<table style="width:100%; border-collapse:collapse;">' TO lt_html.
*  APPEND '<tr>' TO lt_html.
*
**-- 총 품목수
*  APPEND '<td style="width:33%; padding:6px 12px; vertical-align:middle; border-right:1px solid #7A9BB8;">' TO lt_html.
*  APPEND '<table style="width:100%;"><tr>' TO lt_html.
*  APPEND '<td style="width:40px; font-size:20px; color:#1F3A52; text-align:center;">&#128230;</td>' TO lt_html.
*  APPEND '<td>' TO lt_html.
*  APPEND '<div style="color:#555; font-size:10px; margin-bottom:2px;">총 품목수</div>' TO lt_html.
*  APPEND |<div style="color:#0D2538; font-size:13px;"><span style="font-weight:bold; font-size:16px; color:#1F3A52;">{ lv_cnt }</span> 건</div>| TO lt_html.
*  APPEND '</td></tr></table></td>' TO lt_html.
*
**-- 총 요청 수량
*  APPEND '<td style="width:33%; padding:6px 12px; vertical-align:middle; border-right:1px solid #7A9BB8;">' TO lt_html.
*  APPEND '<table style="width:100%;"><tr>' TO lt_html.
*  APPEND '<td style="width:40px; font-size:20px; color:#1F3A52; text-align:center;">&#128203;</td>' TO lt_html.
*  APPEND '<td>' TO lt_html.
*  APPEND '<div style="color:#555; font-size:10px; margin-bottom:2px;">총 요청 수량</div>' TO lt_html.
*  APPEND |<div style="color:#0D2538; font-size:13px;"><span style="font-weight:bold; font-size:16px; color:#1F3A52;">{ lv_qty_disp }</span> EA </div>| TO lt_html.
*  APPEND '</td></tr></table></td>' TO lt_html.
*
**-- 총 예상 금액
*  APPEND '<td style="width:33%; padding:6px 12px; vertical-align:middle;">' TO lt_html.
*  APPEND '<table style="width:100%;"><tr>' TO lt_html.
*  APPEND '<td style="width:40px; font-size:20px; color:#1F3A52; text-align:center;">&#8361;</td>' TO lt_html.
*  APPEND '<td>' TO lt_html.
*  APPEND '<div style="color:#555; font-size:10px; margin-bottom:2px;">총 예상 금액</div>' TO lt_html.
*  APPEND |<div style="color:#0D2538; font-size:13px;"><span style="font-weight:bold; font-size:16px; color:#1F3A52;">{ lv_amt_disp }</span> KRW</div>| TO lt_html.
*  APPEND '</td></tr></table></td>' TO lt_html.
*
*  APPEND '</tr></table>' TO lt_html.
*  APPEND '</div></body></html>' TO lt_html.
  APPEND '<html><body style="font-family:Arial, ''Malgun Gothic'', sans-serif; font-size:11px; margin:0; padding:3px 1px 2px 1px; background:#DFEAF2;">' TO lt_html.
  APPEND '<div style="width:100%; border:1px solid #9EB8CA; background:#F7FBFE; padding:14px 0; box-sizing:border-box;">' TO lt_html.
  APPEND '<table style="width:100%; border-collapse:collapse;">' TO lt_html.
  APPEND '<tr>' TO lt_html.

*-- 총 품목수
  APPEND '<td style="width:33%; padding:6px 12px; vertical-align:middle; border-right:1px solid #9EB8CA;">' TO lt_html.
  APPEND '<table style="width:100%;"><tr>' TO lt_html.
  APPEND '<td style="width:40px; font-size:20px; color:#1E5C89; text-align:center;">&#128230;</td>' TO lt_html.
  APPEND '<td>' TO lt_html.
  APPEND '<div style="color:#465F72; font-weight:900; font-size:10px; margin-bottom:2px;">총 품목수</div>' TO lt_html.
  APPEND |<div style="color:#263B4B; font-size:13px;"><span style="font-weight:bold; font-size:16px; color:#1F3446;">{ lv_cnt }</span> 건</div>| TO lt_html.
  APPEND '</td></tr></table></td>' TO lt_html.

*-- 총 요청 수량
  APPEND '<td style="width:33%; padding:6px 12px; vertical-align:middle; border-right:1px solid #9EB8CA;">' TO lt_html.
  APPEND '<table style="width:100%;"><tr>' TO lt_html.
  APPEND '<td style="width:40px; font-size:20px; color:#1E5C89; text-align:center;">&#128203;</td>' TO lt_html.
  APPEND '<td>' TO lt_html.
  APPEND '<div style="color:#465F72; font-weight:900; font-size:10px; margin-bottom:2px;">총 요청 수량</div>' TO lt_html.
  APPEND |<div style="color:#263B4B; font-size:13px;"><span style="font-weight:bold; font-size:16px; color:#1F3446;">{ lv_qty_disp }</span> EA </div>| TO lt_html.
  APPEND '</td></tr></table></td>' TO lt_html.

*-- 총 예상 금액
  APPEND '<td style="width:33%; padding:6px 12px; vertical-align:middle;">' TO lt_html.
  APPEND '<table style="width:100%;"><tr>' TO lt_html.
  APPEND '<td style="width:40px; font-size:20px; color:#1E5C89; text-align:center;">&#8361;</td>' TO lt_html.
  APPEND '<td>' TO lt_html.
  APPEND '<div style="color:#465F72; font-weight:900; font-size:10px; margin-bottom:2px;">총 예상 금액</div>' TO lt_html.
  APPEND |<div style="color:#263B4B; font-size:13px;"><span style="font-weight:bold; font-size:16px; color:#1F3446;">{ lv_amt_disp }</span> KRW</div>| TO lt_html.
  APPEND '</td></tr></table></td>' TO lt_html.

  APPEND '</tr></table>' TO lt_html.
  APPEND '</div></body></html>' TO lt_html.

*-- HTML Viewer에 로드
  CALL METHOD go_summary_html->load_data
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

  CALL METHOD go_summary_html->show_url
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
*& Form set_create_header_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_create_header_html .

  DATA : lt_html     TYPE TABLE OF char255,
         lv_url      TYPE char255,
         lv_date(10),
         lv_uname    TYPE ztc1mm0025-afnam.

  WRITE sy-datum TO lv_date.

  PERFORM get_user_name USING    sy-uname
                        CHANGING lv_uname.

**-- HTML 시작
*  APPEND '<html><body style="font-family:Arial, sans-serif; font-size:12px; margin:0; padding:8px 16px 16px 16px; background:#F5F6F8; color:#333; overflow:hidden">' TO lt_html.
*
***********************************************************************
** 1. 헤더 정보 블록
***********************************************************************
**-- 섹션 타이틀
*  APPEND '<div style="font-size:14px; font-weight:bold; color:#1A3A6E; margin-bottom:6px;">' TO lt_html.
*  APPEND '구매요청 헤더 정보' TO lt_html.
*  APPEND '</div>' TO lt_html.
*
**-- 구분선
*  APPEND '<hr style="border:0; border-top:2px solid #1A3A6E; margin:0 0 16px 0;">' TO lt_html.
*
**-- 필드 리스트
*  APPEND '<div style="margin-bottom:14px;">' TO lt_html.
*  APPEND '<div style="font-size:11px; font-weight:bold; color:#222; margin-bottom:4px;">구매요청번호</div>' TO lt_html.
*  APPEND |<div style="background:#fff; border:1px solid #B8C4D9; border-radius:3px; padding:6px 10px; color:#1A3A6E; font-weight:bold;">{ gv_preview_banfn } <span style="color:#999; font-weight:normal; font-size:10px;">(예정)</span></div>| TO lt_html.
*  APPEND '</div>' TO lt_html.
*
*  APPEND '<div style="margin-bottom:14px;">' TO lt_html.
*  APPEND '<div style="font-size:11px; font-weight:bold; color:#222; margin-bottom:4px;">요청일</div>' TO lt_html.
*  APPEND |<div style="background:#fff; border:1px solid #B8C4D9; border-radius:3px; padding:6px 10px; color:#222;">{ lv_date }</div>| TO lt_html.
*  APPEND '</div>' TO lt_html.
*
*  APPEND '<div style="margin-bottom:14px;">' TO lt_html.
*  APPEND '<div style="font-size:11px; font-weight:bold; color:#222; margin-bottom:4px;">요청자</div>' TO lt_html.
*  APPEND |<div style="background:#fff; border:1px solid #B8C4D9; border-radius:3px; padding:6px 10px; color:#222;">{ lv_uname }</div>| TO lt_html.
*  APPEND '</div>' TO lt_html.
*
*  APPEND '<div style="margin-bottom:14px;">' TO lt_html.
*  APPEND '<div style="font-size:11px; font-weight:bold; color:#222; margin-bottom:4px;">생성구분</div>' TO lt_html.
*  APPEND '<div style="background:#fff; border:1px solid #B8C4D9; border-radius:3px; padding:6px 10px; color:#1A3A6E; font-weight:bold;">수동생성</div>' TO lt_html.
*  APPEND '</div>' TO lt_html.
*
*  APPEND '<div style="margin-bottom:8px;">' TO lt_html.
*  APPEND '<div style="font-size:11px; font-weight:bold; color:#222; margin-bottom:4px;">구매조직</div>' TO lt_html.
*  APPEND '<div style="background:#fff; border:1px solid #B8C4D9; border-radius:3px; padding:6px 10px; color:#222;">P100</div>' TO lt_html.
*  APPEND '</div>' TO lt_html.
*
*  APPEND '<div style="height:4px;"></div>' TO lt_html.
***********************************************************************
** 2. 안내 섹션
***********************************************************************
**-- 섹션 타이틀
*  APPEND '<div style="font-size:14px; font-weight:bold; color:#1A3A6E; margin-bottom:6px;">' TO lt_html.
*  APPEND '안내' TO lt_html.
*  APPEND '</div>' TO lt_html.
*
**-- 구분선
*  APPEND '<hr style="border:0; border-top:2px solid #1A3A6E; margin:0 0 10px 0;">' TO lt_html.
*
**-- 안내 내용
*  APPEND '<div style="color:#555; font-size:11px; line-height:1.6;">' TO lt_html.
*  APPEND '아이템 정보를 입력한 후<br>' TO lt_html.
*  APPEND '저장 버튼을 클릭하면<br>' TO lt_html.
*  APPEND '구매요청이 생성되고<br>' TO lt_html.
*  APPEND '구매요청번호가 부여됩니다.' TO lt_html.
*  APPEND '</div>' TO lt_html.
*
*  APPEND '</body></html>' TO lt_html.

*-- HTML 시작
  APPEND '<html><body style="font-family:Arial, ''Malgun Gothic'', sans-serif; font-size:12px; margin:0; padding:8px 16px 16px 16px; background:#DFEAF2; color:#263B4B; overflow:hidden">' TO lt_html.

**********************************************************************
* 1. 헤더 정보 블록
**********************************************************************
  APPEND '<div style="font-size:14px; font-weight:900; color:#1F3446; margin-bottom:6px;">' TO lt_html.
  APPEND '구매요청 헤더 정보' TO lt_html.
  APPEND '</div>' TO lt_html.

  APPEND '<hr style="border:0; border-top:2px solid #9EB8CA; margin:0 0 16px 0;">' TO lt_html.

  APPEND '<div style="margin-bottom:14px;">' TO lt_html.
  APPEND '<div style="font-size:11px; font-weight:900; color:#465F72; margin-bottom:4px;">구매요청번호</div>' TO lt_html.
  APPEND |<div style="background:#fff; border:1px solid #A7BDCC; border-radius:2px; padding:6px 10px; color:#1F3446; font-weight:bold;">{ gv_preview_banfn } <span style="color:#8A9AA6; font-weight:normal; font-size:10px;">(예정)</span></div>| TO lt_html.
  APPEND '</div>' TO lt_html.

  APPEND '<div style="margin-bottom:14px;">' TO lt_html.
  APPEND '<div style="font-size:11px; font-weight:900; color:#465F72; margin-bottom:4px;">요청일</div>' TO lt_html.
  APPEND |<div style="background:#fff; border:1px solid #A7BDCC; border-radius:2px; padding:6px 10px; color:#263B4B;">{ lv_date }</div>| TO lt_html.
  APPEND '</div>' TO lt_html.

  APPEND '<div style="margin-bottom:14px;">' TO lt_html.
  APPEND '<div style="font-size:11px; font-weight:900; color:#465F72; margin-bottom:4px;">요청자</div>' TO lt_html.
  APPEND |<div style="background:#fff; border:1px solid #A7BDCC; border-radius:2px; padding:6px 10px; color:#263B4B;">{ lv_uname }</div>| TO lt_html.
  APPEND '</div>' TO lt_html.

  APPEND '<div style="margin-bottom:14px;">' TO lt_html.
  APPEND '<div style="font-size:11px; font-weight:900; color:#465F72; margin-bottom:4px;">생성구분</div>' TO lt_html.
  APPEND '<div style="background:#fff; border:1px solid #A7BDCC; border-radius:2px; padding:6px 10px; color:#1F3446; font-weight:bold;">수동생성</div>' TO lt_html.
  APPEND '</div>' TO lt_html.

  APPEND '<div style="margin-bottom:8px;">' TO lt_html.
  APPEND '<div style="font-size:11px; font-weight:900; color:#465F72; margin-bottom:4px;">구매조직</div>' TO lt_html.
  APPEND '<div style="background:#fff; border:1px solid #A7BDCC; border-radius:2px; padding:6px 10px; color:#263B4B;">P100</div>' TO lt_html.
  APPEND '</div>' TO lt_html.

  APPEND '<div style="height:4px;"></div>' TO lt_html.

**********************************************************************
* 2. 안내 섹션
**********************************************************************
  APPEND '<div style="font-size:14px; font-weight:900; color:#1F3446; margin-bottom:6px;">' TO lt_html.
  APPEND '안내' TO lt_html.
  APPEND '</div>' TO lt_html.

  APPEND '<hr style="border:0; border-top:2px solid #9EB8CA; margin:0 0 10px 0;">' TO lt_html.

  APPEND '<div style="color:#314B5F; font-size:11px; line-height:1.6; font-weight:800;">' TO lt_html.
  APPEND '아이템 정보를 입력한 후<br>' TO lt_html.
  APPEND '저장 버튼을 클릭하면<br>' TO lt_html.
  APPEND '구매요청이 생성되고<br>' TO lt_html.
  APPEND '구매요청번호가 부여됩니다.' TO lt_html.
  APPEND '</div>' TO lt_html.

  APPEND '</body></html>' TO lt_html.

**********************************************************************
* HTML Viewer 로드
**********************************************************************
  CALL METHOD go_head_html->load_data
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

  CALL METHOD go_head_html->show_url
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
*& Form check_matnr_valid
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_ITEM_MATNR
*&      <-- LV_VALID
*&---------------------------------------------------------------------*
FORM check_matnr_valid  USING    pv_matnr TYPE ztc1mm0026-matnr
                        CHANGING cv_valid TYPE flag.

  DATA : ls_mat TYPE ztc1mm0001.

  CLEAR cv_valid.

*-- 필수값 체크
  IF pv_matnr IS INITIAL.
    MESSAGE s416 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- F4 목록(gt_sh_matnr) 존재 여부
  READ TABLE gt_sh_matnr TRANSPORTING NO FIELDS WITH KEY matnr = pv_matnr.
  IF sy-subrc <> 0.
    MESSAGE s415 WITH pv_matnr DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 미사용 자재 차단 (직접입력 우회 방지)
  SELECT SINGLE matnr, lvorm
    FROM ztc1mm0001
   WHERE matnr = @pv_matnr
    INTO CORRESPONDING FIELDS OF @ls_mat.

  IF sy-subrc = 0 AND ls_mat-lvorm = 'X'.
    MESSAGE s000 WITH |{ pv_matnr }은(는) 미사용 처리된 자재입니다.|
      DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  cv_valid = 'X'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_preview_banfn
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_preview_banfn .

  DATA: lv_max_banfn TYPE ztc1mm0025-banfn,
        lv_num       TYPE n LENGTH 10.

*-- 현재 DB의 가장 큰 BANFN 조회
  SELECT MAX( banfn )
    FROM ztc1mm0025
    INTO @lv_max_banfn.

  IF lv_max_banfn IS INITIAL.
    lv_num = '2000000001'.
  ELSE.
    lv_num = lv_max_banfn + 1.
  ENDIF.

  gv_preview_banfn = lv_num.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form onf4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_FIELDNAME
*&      --> E_FIELDVALUE
*&      --> ES_ROW_NO
*&      --> ER_EVENT_DATA
*&      --> ET_BAD_CELLS
*&      --> E_DISPLAY
*&---------------------------------------------------------------------*
FORM onf4  USING p_fieldname   TYPE  lvc_fname
                 p_fieldvalue  TYPE  lvc_value
                 ps_row_no     TYPE  lvc_s_roid
                 pi_event_data TYPE REF TO cl_alv_event_data
                 pt_bad_cells  TYPE  lvc_t_modi
                 p_display     TYPE  char01.

  FIELD-SYMBOLS <fs_modi> TYPE lvc_t_modi.

  DATA: lt_return LIKE TABLE OF ddshretval WITH HEADER LINE,
        ls_modi   TYPE lvc_s_modi.

  CHECK p_fieldname = 'MATNR'.

  PERFORM set_f4_matnr.

*-- F4 팝업 호출
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'MATNR'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'GS_CREATE-MATNR'
      window_title    = '[Taesan] 자재 번호'
      value_org       = 'S'
    TABLES
      value_tab       = gt_sh_matnr
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

*-- F4 처리 완료 표시
  pi_event_data->m_event_handled = 'X'.

*-- 선택값을 ALV 셀에 반영
  ASSIGN pi_event_data->m_data->* TO <fs_modi>.

  READ TABLE lt_return INDEX 1.
  IF sy-subrc = 0.
    ls_modi-row_id    = ps_row_no-row_id.
    ls_modi-fieldname = p_fieldname.
    ls_modi-value     = lt_return-fieldval.
    APPEND ls_modi TO <fs_modi>.
  ENDIF.

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
*-- 좌측 재조회 시 우측 패널 초기화
  CLEAR : gt_item, gt_item_no, gt_item_ok.

  PERFORM refresh_table USING go_right_mid_alv.
  PERFORM refresh_table USING go_right_bot_alv.

*-- HTML 초기 안내문구로 되돌림
  PERFORM set_header_html_init.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_user_name
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> SY_UNAME
*&      <-- LS_HEAD_AFNAM
*&---------------------------------------------------------------------*
FORM get_user_name USING    pv_uname TYPE sy-uname
                   CHANGING cv_name  TYPE ztc1mm0025-afnam.

  CLEAR cv_name.

  SELECT SINGLE ename
    FROM ztc1hr0001
   WHERE uname = @pv_uname
    INTO @cv_name.

  IF cv_name IS INITIAL.
    cv_name = pv_uname.   " 매핑 실패 시 ID 그대로
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_f4_banfn
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_f4_banfn .

  CLEAR gt_sh_banfn.
*-- PR 헤더 + HR 테이블 JOIN
  SELECT a~banfn,
         a~badat,
         b~ename AS afnam,
         a~statu
    FROM ztc1mm0025 AS a
    LEFT JOIN ztc1hr0001 AS b ON a~ernam = b~uname
    INTO CORRESPONDING FIELDS OF TABLE @gt_sh_banfn.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_banfn_help
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_banfn_help .

  TYPES: BEGIN OF ty_f4_banfn,
           banfn   TYPE c LENGTH 10,
           badat   TYPE c LENGTH 10,
           afnam   TYPE c LENGTH 20,
           statu_t TYPE c LENGTH 10,
         END OF ty_f4_banfn.

  DATA : lt_value     TYPE TABLE OF ty_f4_banfn,
         ls_value     TYPE ty_f4_banfn,
         lt_return    LIKE TABLE OF ddshretval WITH HEADER LINE,
         lt_field_tab TYPE TABLE OF dfies,
         ls_field_tab TYPE dfies.

  CLEAR : lt_value, lt_return, lt_field_tab.

*--------------------------------------------------------------------*
* F4 표시용 데이터 구성
*--------------------------------------------------------------------*
  LOOP AT gt_sh_banfn INTO gs_sh_banfn.

    CLEAR ls_value.

    ls_value-banfn = gs_sh_banfn-banfn.
    ls_value-afnam = gs_sh_banfn-afnam.

    IF gs_sh_banfn-badat IS NOT INITIAL.
      WRITE gs_sh_banfn-badat TO ls_value-badat.
    ENDIF.

    IF gs_sh_banfn-statu_t IS NOT INITIAL.
      ls_value-statu_t = gs_sh_banfn-statu_t.
    ELSE.
      CASE gs_sh_banfn-statu.
        WHEN 'CR'.
          ls_value-statu_t = '미확정'.
        WHEN 'PC'.
          ls_value-statu_t = '일부확정'.
        WHEN 'FC'.
          ls_value-statu_t = '확정완료'.
        WHEN OTHERS.
          ls_value-statu_t = gs_sh_banfn-statu.
      ENDCASE.
    ENDIF.

    APPEND ls_value TO lt_value.

  ENDLOOP.

  CLEAR ls_field_tab.
  ls_field_tab-fieldname = 'BANFN'.
  ls_field_tab-position  = 1.
  ls_field_tab-offset    = 0.
  ls_field_tab-inttype   = 'C'.
  ls_field_tab-datatype  = 'CHAR'.
  ls_field_tab-leng      = 10.
  ls_field_tab-intlen    = 20.
  ls_field_tab-outputlen = 12.
  ls_field_tab-scrtext_l = '구매요청번호'.
  ls_field_tab-scrtext_m = '구매요청번호'.
  ls_field_tab-scrtext_s = '요청번호'.
  ls_field_tab-fieldtext = '구매요청번호'.
  ls_field_tab-reptext   = '구매요청번호'.
  APPEND ls_field_tab TO lt_field_tab.

  CLEAR ls_field_tab.
  ls_field_tab-fieldname = 'BADAT'.
  ls_field_tab-position  = 2.
  ls_field_tab-offset    = 20.
  ls_field_tab-inttype   = 'C'.
  ls_field_tab-datatype  = 'CHAR'.
  ls_field_tab-leng      = 10.
  ls_field_tab-intlen    = 20.
  ls_field_tab-outputlen = 12.
  ls_field_tab-scrtext_l = '구매요청일'.
  ls_field_tab-scrtext_m = '구매요청일'.
  ls_field_tab-scrtext_s = '요청일'.
  ls_field_tab-fieldtext = '구매요청일'.
  ls_field_tab-reptext   = '구매요청일'.
  APPEND ls_field_tab TO lt_field_tab.

  CLEAR ls_field_tab.
  ls_field_tab-fieldname = 'AFNAM'.
  ls_field_tab-position  = 3.
  ls_field_tab-offset    = 40.
  ls_field_tab-inttype   = 'C'.
  ls_field_tab-datatype  = 'CHAR'.
  ls_field_tab-leng      = 20.
  ls_field_tab-intlen    = 40.
  ls_field_tab-outputlen = 12.
  ls_field_tab-scrtext_l = '요청자'.
  ls_field_tab-scrtext_m = '요청자'.
  ls_field_tab-scrtext_s = '요청자'.
  ls_field_tab-fieldtext = '요청자'.
  ls_field_tab-reptext   = '요청자'.
  APPEND ls_field_tab TO lt_field_tab.

  CLEAR ls_field_tab.
  ls_field_tab-fieldname = 'STATU_T'.
  ls_field_tab-position  = 4.
  ls_field_tab-offset    = 80.
  ls_field_tab-inttype   = 'C'.
  ls_field_tab-datatype  = 'CHAR'.
  ls_field_tab-leng      = 10.
  ls_field_tab-intlen    = 20.
  ls_field_tab-outputlen = 12.
  ls_field_tab-scrtext_l = '처리상태'.
  ls_field_tab-scrtext_m = '처리상태'.
  ls_field_tab-scrtext_s = '상태'.
  ls_field_tab-fieldtext = '처리상태'.
  ls_field_tab-reptext   = '처리상태'.
  APPEND ls_field_tab TO lt_field_tab.


*-- F4 팝업 호출
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'BANFN'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'ZTC1MM0025-BANFN'
      window_title    = '[Taesan] 구매요청 번호'
      value_org       = 'S'
    TABLES
      field_tab       = lt_field_tab
      value_tab       = lt_value
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  IF lt_return[] IS NOT INITIAL.
    READ TABLE lt_return INDEX 1.
    ztc1mm0025-banfn = lt_return-fieldval.
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

*-- 조회조건 입력값 클리어
  CLEAR : ztc1mm0025-banfn,
          ztc1mm0025-badat,
          gv_badat_to.

*-- 전체 데이터 재조회
  PERFORM set_prdata.
  PERFORM refresh_table USING go_left_alv.

*-- 필터 해제
  PERFORM filter_table USING ''.

*-- 우측 클리어
  PERFORM clear_right_side.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_left_only
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_left_only .

  PERFORM set_prdata.
  PERFORM refresh_table USING go_left_alv.

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
*      iv_program_name = |구매요청 관리 프로그램|
*      iv_program_desc = |MRP 결과 기반의 PR 생성과 수정 및 최종 확정 업무를 수행하는 프로그램입니다|
*      iv_program_id   = |{ sy-repid }|
*      iv_system_info  = |{ sy-sysid } / { sy-mandt }|
*      iv_user_id      = |{ sy-uname }|
*      iv_user_name    = |{ sy-uname }|
*  ).
*
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_purrsn_dropdown
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_purrsn_dropdown .

  DATA : lt_drop   TYPE lvc_t_drop,
         ls_drop   TYPE lvc_s_drop,
         lt_domval TYPE TABLE OF dd07v,
         ls_domval TYPE dd07v.

  CALL FUNCTION 'DD_DOMVALUES_GET'
    EXPORTING
      domname        = 'ZDC1_MM_PURRSN'
      text           = 'X'
      langu          = sy-langu
    TABLES
      dd07v_tab      = lt_domval
    EXCEPTIONS
      wrong_textflag = 1
      OTHERS         = 2.

  LOOP AT lt_domval INTO ls_domval.
    ls_drop-handle = '01'.
    ls_drop-value  = ls_domval-domvalue_l.
    APPEND ls_drop TO lt_drop.
    CLEAR ls_drop.
  ENDLOOP.

  CALL METHOD go_create_alv->set_drop_down_table
    EXPORTING
      it_drop_down = lt_drop.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_detail_lgort
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_detail_lgort .

  CLEAR gt_lgort.

  CALL FUNCTION 'DD_DOMVALUES_GET'
    EXPORTING
      domname        = 'ZDC1_MM_LGORT'
      text           = 'X'
      langu          = sy-langu
    TABLES
      dd07v_tab      = gt_lgort
    EXCEPTIONS
      wrong_textflag = 1
      OTHERS         = 2.

  SORT gt_lgort BY domvalue_l.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_detail_lgort
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_detail_lgort .

  READ TABLE gt_lgort INTO gs_lgort
    WITH KEY domvalue_l = gs_item-lgort
    BINARY SEARCH.
  IF sy-subrc = 0.
    gs_item-lgort_txt = gs_lgort-ddtext.
  ELSE.
    CLEAR gs_item-lgort_txt.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_create_lgort_txt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_create_lgort_txt .

  IF gt_lgort IS INITIAL.
    PERFORM get_detail_lgort.
  ENDIF.

  CLEAR gs_lgort.
  READ TABLE gt_lgort INTO gs_lgort
    WITH KEY domvalue_l = gs_create-lgort
    BINARY SEARCH.
  IF sy-subrc = 0.
    gs_create-lgort_txt = gs_lgort-ddtext.
  ELSE.
    CLEAR gs_create-lgort_txt.
  ENDIF.

ENDFORM.
