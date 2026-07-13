*  &---------------------------------------------------------------------*
*  & Include          SAPMZC1MM0001_F01
*  &---------------------------------------------------------------------*
*  &---------------------------------------------------------------------*
*  & Form set_matdata
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM set_matdata .

    DATA: lv_maktx TYPE ztc1mm0001-maktx.

    IF rb_all IS INITIAL AND rb_use IS INITIAL AND rb_nuse IS INITIAL.
      rb_all = 'X'.
    ENDIF.

    CLEAR: gs_matdata, gt_matdata.

*  -- 자재내역 LIKE 조회를 위한 % % 추가
    IF ztc1mm0001-maktx IS NOT INITIAL.
      lv_maktx = '%' && ztc1mm0001-maktx && '%'.
    ENDIF.

*  -- 자재마스터 조회 (조회조건 + 라디오버튼)
    SELECT matnr, maktx, mtart, matkl,
           ntgew, gewei, normt, meins, bismt, vrsgr, vrsnr, lvorm, bigo
      FROM ztc1mm0001
      WHERE ( @ztc1mm0001-matnr IS INITIAL OR matnr =    @ztc1mm0001-matnr )
        AND ( @lv_maktx         IS INITIAL OR maktx LIKE @lv_maktx )
        AND ( @ztc1mm0001-mtart IS INITIAL OR mtart =    @ztc1mm0001-mtart )
        AND ( @ztc1mm0001-matkl IS INITIAL OR matkl =    @ztc1mm0001-matkl )
        AND ( @rb_all  = 'X'
         OR ( @rb_use  = 'X' AND lvorm = ' ' )
         OR ( @rb_nuse = 'X' AND lvorm = 'X' ) )
      INTO CORRESPONDING FIELDS OF TABLE @gt_matdata.

*  -- 자재유형/자재그룹 한글 텍스트로 전환
    PERFORM convert_text.

*  -- 정렬 기준: 사용 → 미사용, 자재유형 → 자재그룹 → 자재번호
    SORT gt_matdata BY lvorm ASCENDING
                       mtart ASCENDING
                       matkl ASCENDING
                       matnr ASCENDING.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form display_screen
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM display_screen .

*  -- 자재 데이터 조회 및 셀 스타일 설정
    PERFORM set_matdata.
    PERFORM set_celltab.

    IF go_container IS NOT BOUND.

*  -- 컨테이너 생성
      PERFORM create_object.

*  -- 필드 카탈로그 설정 ('L' = 자재마스터 ALV)
      CLEAR : gs_fcat, gt_fcat_list.
      PERFORM set_field_catalog USING : 'L' 'X' 'MATNR'      'ZTC1MM0001' ' ' ' ',
                                        'L' ' ' 'MAKTX'      'ZTC1MM0001' ' ' 'X',
                                        'L' ' ' 'MTART_TEXT' ''           ' ' ' ',
                                        'L' ' ' 'MATKL_TEXT' ''           ' ' ' ',
                                        'L' ' ' 'NTGEW'      'ZTC1MM0001' ' ' ' ',
                                        'L' ' ' 'GEWEI'      'ZTC1MM0001' 'C' ' ',
                                        'L' ' ' 'NORMT'      'ZTC1MM0001' ' ' ' ',
                                        'L' ' ' 'MEINS'      'ZTC1MM0001' 'C' ' ',
                                        'L' ' ' 'VRSGR'      'ZTC1MM0001' 'C' ' ',
                                        'L' ' ' 'VRSNR'      'ZTC1MM0001' 'C' ' ',
                                        'L' ' ' 'LVORM'      'ZTC1MM0001' ' ' ' '.

*  -- 레이아웃 설정
      PERFORM set_layout.

*  -- 툴바 제거
      PERFORM toolbar_exclude.

*  -- 이벤트 핸들러
      SET HANDLER : lcl_event_handler=>add_toolbar    FOR go_list_alv,
                    lcl_event_handler=>user_command   FOR go_list_alv,
                    lcl_event_handler=>hotspot_click  FOR go_list_alv.

*  -- ALV 출력
      PERFORM create_display.

    ENDIF.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form create_object
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM create_object .

    CREATE OBJECT go_container
      EXPORTING
        container_name = 'MAIN_CONT'.

*  -- 좌/우 분할
    CREATE OBJECT go_split_cont
      EXPORTING
        parent  = go_container
        rows    = 1
        columns = 2.

*  -- 좌측 컨테이너
    CALL METHOD go_split_cont->get_container
      EXPORTING
        row       = 1
        column    = 1
      RECEIVING
        container = go_list_cont.

*  -- 우측 컨테이너
    CALL METHOD go_split_cont->get_container
      EXPORTING
        row       = 1
        column    = 2
      RECEIVING
        container = go_right_cont.

*  -- 좌/우 비율 (좌 59% : 우 41%)
    CALL METHOD go_split_cont->set_column_width
      EXPORTING
        id    = 1
        width = 59.

*  -- 우측 상/중/하 3분할 (이미지 / 재고 / 메모)
    CREATE OBJECT go_split2_cont
      EXPORTING
        parent  = go_right_cont
        rows    = 3
        columns = 1.

*  -- 1행 이미지
    CALL METHOD go_split2_cont->get_container
      EXPORTING
        row       = 1
        column    = 1
      RECEIVING
        container = go_pic_cont.

*  -- 2행 재고
    CALL METHOD go_split2_cont->get_container
      EXPORTING
        row       = 2
        column    = 1
      RECEIVING
        container = go_stock_cont.

*  -- 3행 메모
    CALL METHOD go_split2_cont->get_container
      EXPORTING
        row       = 3
        column    = 1
      RECEIVING
        container = go_memo_cont.

*  -- 비율 (이미지 40 : 재고 35 : 메모 25)
    CALL METHOD go_split2_cont->set_row_height
      EXPORTING
        id     = 1
        height = 40.

    CALL METHOD go_split2_cont->set_row_height
      EXPORTING
        id     = 2
        height = 35.

*  -- 좌측 ALV
    CREATE OBJECT go_list_alv
      EXPORTING
        i_parent = go_list_cont.

*  -- 우측 상단 Picture
    CREATE OBJECT go_picture
      EXPORTING
        parent = go_pic_cont.

*  -- 우측 하단 재고 ALV
    CREATE OBJECT go_stock_alv
      EXPORTING
        i_parent = go_stock_cont.

*  -- 메모 영역을 상(버튼)/하(에디터)로 분할
    CREATE OBJECT go_memo_split
      EXPORTING
        parent  = go_memo_cont
        rows    = 2
        columns = 1.

*  -- 상단 버튼 컨테이너
    CALL METHOD go_memo_split->get_container
      EXPORTING
        row       = 1
        column    = 1
      RECEIVING
        container = go_memo_btn_cont.

*  -- 하단 에디터 컨테이너
    CALL METHOD go_memo_split->get_container
      EXPORTING
        row       = 2
        column    = 1
      RECEIVING
        container = go_memo_edit_cont.

*  -- 버튼 영역 높이 고정 (작게)
    CALL METHOD go_memo_split->set_row_height
      EXPORTING
        id     = 1
        height = 20.

*  -- 메모 툴바 생성
    CREATE OBJECT go_memo_toolbar
      EXPORTING
        parent = go_memo_btn_cont.

*  -- 저장 버튼 추가
    CALL METHOD go_memo_toolbar->add_button
      EXPORTING
        fcode     = 'SMEMO'
        icon      = '@2L@'                "* 저장 아이콘
        butn_type = cntb_btype_button
        text      = '메모 저장'
        quickinfo = '비고 저장'.

    DATA : lt_events TYPE cntl_simple_events,
           ls_event  TYPE cntl_simple_event.

    CLEAR lt_events.
    ls_event-eventid    = cl_gui_toolbar=>m_id_function_selected.
    ls_event-appl_event = abap_true.
    APPEND ls_event TO lt_events.

    CALL METHOD go_memo_toolbar->set_registered_events
      EXPORTING
        events = lt_events.

*  -- 툴바 이벤트 핸들러 등록
    SET HANDLER lcl_event_handler=>memo_toolbar_click FOR go_memo_toolbar.

*  -- 메모 텍스트에디터 (에디터 컨테이너에 생성)
    CREATE OBJECT go_memo_editor
      EXPORTING
        parent = go_memo_edit_cont.

*  -- 줄바꿈 안 함 / 상태바 표시
    CALL METHOD go_memo_editor->set_toolbar_mode
      EXPORTING
        toolbar_mode = 0.

    CALL METHOD go_memo_editor->set_statusbar_mode
      EXPORTING
        statusbar_mode = 0.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form set_field_catalog
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  &      --> P_GUB    ALV 구분 (L=자재마스터 / S=재고현황)
*  &      --> P_KEY
*  &      --> P_FIELD
*  &      --> P_TABLE
*  &      --> P_JUST
*  &      --> P_EMPH
*  &---------------------------------------------------------------------*
  FORM set_field_catalog  USING pv_gub pv_key pv_field pv_table pv_just pv_emph.

    gs_fcat = VALUE #( key       = pv_key
                       fieldname = pv_field
                       ref_table = pv_table
                       just      = pv_just
                       emphasize = pv_emph ).

    PERFORM get_korean_text USING    pv_table
                                     pv_field
                            CHANGING gs_fcat-coltext.

    CASE pv_gub.

*  -- L : 자재마스터 ALV (좌측)
      WHEN 'L'.
        gs_fcat-edit = 'X'.
        CASE pv_field.
          WHEN 'MAKTX'.
            gs_fcat-coltext = '자재명'.
          WHEN 'MTART_TEXT'.
            gs_fcat-coltext   = '자재유형'.
            gs_fcat-outputlen = 10.
          WHEN 'MATKL_TEXT'.
            gs_fcat-coltext   = '자재그룹'.
            gs_fcat-outputlen = 12.
          WHEN 'MATNR'.
            gs_fcat-hotspot = 'X'.
          WHEN 'LVORM'.
            gs_fcat-checkbox = 'X'.
            gs_fcat-coltext  = '미사용'.
        ENDCASE.

*  -- S : 재고현황 ALV (우측 하단)
      WHEN 'S'.
        CASE pv_field.
          WHEN 'WERKS'.
            gs_fcat-coltext   = '플랜트'.
            gs_fcat-outputlen = 6.
          WHEN 'LGORT'.
            gs_fcat-coltext   = '저장위치'.
            gs_fcat-outputlen = 6.
          WHEN 'LGORT_TXT'.
            gs_fcat-coltext   = '저장위치명'.
            gs_fcat-outputlen = 14.
          WHEN 'CHARG'.
            gs_fcat-coltext   = '배치번호'.
            gs_fcat-outputlen = 10.
          WHEN 'MEINS'.
            gs_fcat-coltext   = '단위'.
            gs_fcat-outputlen = 3.
          WHEN 'CLABS'.
            gs_fcat-coltext    = '가용재고'.
            gs_fcat-qfieldname = 'MEINS'.
            gs_fcat-outputlen  = 10.
          WHEN 'CINSM'.
            gs_fcat-coltext    = '품질검사재고'.
            gs_fcat-qfieldname = 'MEINS'.
            gs_fcat-outputlen  = 10.
          WHEN 'CSPEM'.
            gs_fcat-coltext    = '보류재고'.
            gs_fcat-qfieldname = 'MEINS'.
            gs_fcat-outputlen  = 9.
        ENDCASE.

    ENDCASE.

    CASE pv_gub.
      WHEN 'L'.
        APPEND gs_fcat TO gt_fcat_list.
      WHEN 'S'.
        APPEND gs_fcat TO gt_fcat_stock.
    ENDCASE.

    CLEAR gs_fcat.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form set_layout
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM set_layout .

    gs_layout = VALUE #( zebra      = abap_true
                         cwidth_opt = 'A'
                         sel_mode   = 'D'
                         stylefname = 'CELLTAB'
                         info_fname = 'LINECOLOR' ).

    gs_variant = VALUE #( report = sy-repid
                          handle = 'ALV1' ).

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form create_display
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM create_display .

    CALL METHOD go_list_alv->set_table_for_first_display
      EXPORTING
        is_variant           = gs_variant
        i_save               = 'A'
        i_default            = 'X'
        is_layout            = gs_layout
        it_toolbar_excluding = gt_toolbar
      CHANGING
        it_outtab            = gt_matdata
        it_fieldcatalog      = gt_fcat_list.

*  -- 초기 조회모드 설정
    CALL METHOD go_list_alv->set_ready_for_input
      EXPORTING
        i_ready_for_input = 0.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form search_matdata
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM search_matdata .

    DATA : lv_total TYPE i,
           lv_nuse  TYPE i,
           lv_text  TYPE string.

    PERFORM set_matdata.
    PERFORM set_celltab.
    PERFORM refresh_table.

*  -- 조회 건수 메시지
    lv_total = lines( gt_matdata ).

    IF lv_total = 0.
      MESSAGE s000 WITH '조회 결과가 없습니다.' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    LOOP AT gt_matdata TRANSPORTING NO FIELDS WHERE lvorm = 'X'.
      lv_nuse = lv_nuse + 1.
    ENDLOOP.

    lv_text = |총 { lv_total }건 조회됨 (사용 { lv_total - lv_nuse } / 미사용 { lv_nuse })|.
    MESSAGE s000 WITH lv_text.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form convert_text
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM convert_text .

    DATA : lt_mtart TYPE TABLE OF dd07v,
           ls_mtart TYPE dd07v,
           lt_matkl TYPE TABLE OF dd07v,
           ls_matkl TYPE dd07v.

    CHECK gt_matdata IS NOT INITIAL.

*  -- 자재유형 도메인 Fixed Value
    CALL FUNCTION 'GET_DOMAIN_VALUES'
      EXPORTING
        domname         = 'ZDC1_MM_MTART'
        text            = 'X'
      TABLES
        values_tab      = lt_mtart
      EXCEPTIONS
        no_values_found = 1
        OTHERS          = 2.

*  -- 자재그룹 도메인 Fixed Value
    CALL FUNCTION 'GET_DOMAIN_VALUES'
      EXPORTING
        domname         = 'ZDC1_MM_MATKL'
        text            = 'X'
      TABLES
        values_tab      = lt_matkl
      EXCEPTIONS
        no_values_found = 1
        OTHERS          = 2.

    LOOP AT gt_matdata INTO gs_matdata.

*  -- 자재유형 텍스트
      READ TABLE lt_mtart INTO ls_mtart
        WITH KEY domvalue_l = gs_matdata-mtart.
      IF sy-subrc = 0.
        gs_matdata-mtart_text = ls_mtart-ddtext.
      ENDIF.

*  -- 자재그룹 텍스트
      READ TABLE lt_matkl INTO ls_matkl
        WITH KEY domvalue_l = gs_matdata-matkl.
      IF sy-subrc = 0.
        gs_matdata-matkl_text = ls_matkl-ddtext.
      ENDIF.

      MODIFY gt_matdata FROM gs_matdata
        TRANSPORTING mtart_text matkl_text.

    ENDLOOP.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form refresh_table
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM refresh_table .

    DATA : ls_stable TYPE lvc_s_stbl.

    CHECK go_list_alv IS BOUND.

    CLEAR ls_stable.

    ls_stable-col = 'X'.
    ls_stable-row = 'X'.

    CALL METHOD go_list_alv->refresh_table_display
      EXPORTING
        is_stable = ls_stable
      EXCEPTIONS
        finished  = 1
        OTHERS    = 2.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form handle_add_toolbar
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  &      --> E_OBJECT
*  &---------------------------------------------------------------------*
  FORM handle_add_toolbar  USING po_object TYPE REF TO cl_alv_event_toolbar_set.

    CLEAR gs_button.
    gs_button-butn_type = 3.  " 구분선
    APPEND gs_button TO po_object->mt_toolbar.

*   토글 버튼
    CLEAR gs_button.
    gs_button-function  = 'TOGL'.
    gs_button-icon      = icon_toggle_display_change.
    IF gv_mode = 'D'.
      gs_button-quickinfo = '수정모드 전환'.
    ELSE.
      gs_button-quickinfo = '조회모드 전환'.
    ENDIF.
    APPEND gs_button TO po_object->mt_toolbar.

    CLEAR gs_button.
    gs_button-butn_type = 3.  " 구분선
    APPEND gs_button TO po_object->mt_toolbar.

*   행 추가
    CLEAR gs_button.
    gs_button-function  = 'ADD'.
    gs_button-icon      = icon_insert_row.
    gs_button-quickinfo = '행 추가'.
    IF gv_mode = 'D'.
      gs_button-disabled = abap_true.
    ENDIF.
    APPEND gs_button TO po_object->mt_toolbar.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form handle_user_command
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  &      --> E_UCOMM
*  &---------------------------------------------------------------------*
  FORM handle_user_command  USING pv_ucomm.

    CASE pv_ucomm.
      WHEN 'TOGL'.
        PERFORM toggle_mode.
      WHEN 'ADD'.
        PERFORM add_row.
      WHEN 'SAVE'.
        PERFORM save_data.
    ENDCASE.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form toggle_mode
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM toggle_mode .

    DATA : ls_fcat TYPE lvc_s_fcat.

    IF gv_mode = 'D'.
      gv_mode = 'E'.
*  -- 수정모드: MATNR 핫스팟 제거
      LOOP AT gt_fcat_list INTO ls_fcat WHERE fieldname = 'MATNR'.
        ls_fcat-hotspot = ' '.
        MODIFY gt_fcat_list FROM ls_fcat.
      ENDLOOP.
    ELSE.
      CALL METHOD go_list_alv->check_changed_data.
      gv_mode = 'D'.

*  -- 저장 안 한 빈 행 제거
      DELETE gt_matdata WHERE matnr IS INITIAL.

*  -- 조회모드: MATNR 핫스팟 복원
      LOOP AT gt_fcat_list INTO ls_fcat WHERE fieldname = 'MATNR'.
        ls_fcat-hotspot = 'X'.
        MODIFY gt_fcat_list FROM ls_fcat.
      ENDLOOP.
    ENDIF.

*  -- fcat 변경사항 ALV에 반영
    CALL METHOD go_list_alv->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fcat_list.

    PERFORM set_alv_mode.
    CALL METHOD go_list_alv->set_toolbar_interactive.
    PERFORM refresh_table.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form set_alv_mode
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM set_alv_mode .

    CHECK go_list_alv IS BOUND.

    IF gv_mode = 'E'.
      CALL METHOD go_list_alv->set_ready_for_input
        EXPORTING
          i_ready_for_input = 1.
    ELSE.
      CALL METHOD go_list_alv->set_ready_for_input
        EXPORTING
          i_ready_for_input = 0.
    ENDIF.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form add_row
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM add_row .

    CLEAR gs_matdata.

*  -- 신규 행: celltab 비워두면 전체 편집 가능
    APPEND gs_matdata TO gt_matdata.

    CALL METHOD go_list_alv->set_toolbar_interactive.
    PERFORM refresh_table.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form delete_row
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM delete_row .

    DATA : lt_rows TYPE lvc_t_row,
           ls_row  TYPE lvc_s_row.

    CALL METHOD go_list_alv->check_changed_data.

*  -- 선택 행 가져오기
    CALL METHOD go_list_alv->get_selected_rows
      IMPORTING
        et_index_rows = lt_rows.

    IF lt_rows IS INITIAL.
      MESSAGE s000 WITH '행을 선택하세요.' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    LOOP AT lt_rows INTO ls_row.

      READ TABLE gt_matdata INTO gs_matdata INDEX ls_row-index.
      CHECK sy-subrc = 0.

*  -- 삭제플래그 토글 ('X' <-> ' ')
      IF gs_matdata-lvorm = 'X'.
        gs_matdata-lvorm = space.
      ELSE.
        gs_matdata-lvorm = 'X'.
      ENDIF.

      MODIFY gt_matdata FROM gs_matdata INDEX ls_row-index
        TRANSPORTING lvorm.

    ENDLOOP.

    PERFORM set_celltab.
    PERFORM refresh_table.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form save_data
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM save_data .

    DATA : ls_save   TYPE ztc1mm0001,
           lv_answer TYPE c LENGTH 1,
           lv_cnt    TYPE i,
           lv_pr_cnt TYPE i,
           lv_po_cnt TYPE i,
           ls_fcat   TYPE lvc_s_fcat.

    CALL METHOD go_list_alv->check_changed_data.

*  -- 빈 행(자재번호 미입력) 검증
    LOOP AT gt_matdata INTO gs_matdata.
      IF gs_matdata-matnr IS INITIAL.
        MESSAGE s000 WITH '자재번호가 입력되지 않은 행이 있습니다.'
                         DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
    ENDLOOP.

*  -- 미사용 전환 검증 (PR/PO 진행중 체크)
    LOOP AT gt_matdata INTO gs_matdata.
      CHECK gs_matdata-lvorm = 'X'.

      CLEAR : lv_pr_cnt, lv_po_cnt.

      PERFORM check_matnr_in_use
        USING    gs_matdata-matnr
        CHANGING lv_pr_cnt
                 lv_po_cnt.

      IF lv_pr_cnt > 0 OR lv_po_cnt > 0.

*  -- ★ gt_matdata에서 lvorm 강제 원복
        gs_matdata-lvorm = ' '.
        gs_matdata-linecolor = ' '.
        MODIFY gt_matdata FROM gs_matdata
          TRANSPORTING lvorm linecolor.

        MESSAGE s000 WITH |{ gs_matdata-matnr }은(는) 진행중인 PR { lv_pr_cnt }건 / PO { lv_po_cnt }건 존재 → 저장 불가.|
          DISPLAY LIKE 'E'.

        PERFORM set_celltab.
        PERFORM refresh_table.

        RETURN.
      ENDIF.

    ENDLOOP.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = '[Taesan] 저장'
        text_question         = '변경된 내용을 저장하시겠습니까?'
        text_button_1         = '예'
        icon_button_1         = 'ICON_OKAY'
        text_button_2         = '아니오'
        icon_button_2         = 'ICON_CANCEL'
        default_button        = '2'
        display_cancel_button = ' '
      IMPORTING
        answer                = lv_answer.

    IF lv_answer <> '1'.
      RETURN.
    ENDIF.

*  -- 저장 처리
    DATA : ls_db TYPE ztc1mm0001.

    LOOP AT gt_matdata INTO gs_matdata.

*  --   DB 원본 읽기
      CLEAR ls_db.
      SELECT SINGLE * FROM ztc1mm0001
        INTO ls_db
       WHERE matnr = gs_matdata-matnr.

      IF sy-subrc = 0.
*  --     기존 행: DB원본을 베이스로 깔고 화면 관리필드만 덮어쓰기
        ls_save = ls_db.
        MOVE-CORRESPONDING gs_matdata TO ls_save.

*  --     변경 없으면 스킵
        IF ls_save = ls_db.
          CONTINUE.
        ENDIF.
      ELSE.
*  --     신규 행
        CLEAR ls_save.
        MOVE-CORRESPONDING gs_matdata TO ls_save.
      ENDIF.

*  --   신규 행이거나 변경된 행만 저장
      MODIFY ztc1mm0001 FROM ls_save.
      IF sy-subrc = 0.
        lv_cnt = lv_cnt + 1.
      ENDIF.

    ENDLOOP.

*  -- 변경 건 없으면 안내
    IF lv_cnt = 0.
      MESSAGE s000 WITH '변경된 내용이 없습니다.'.
      RETURN.
    ENDIF.

    COMMIT WORK AND WAIT.
    MESSAGE s000 WITH |총 { lv_cnt }건이 저장되었습니다.|.

*  -- 조회모드 복원 + 핫스팟 복원
    gv_mode = 'D'.
    LOOP AT gt_fcat_list INTO ls_fcat WHERE fieldname = 'MATNR'.
      ls_fcat-hotspot = 'X'.
      MODIFY gt_fcat_list FROM ls_fcat.
    ENDLOOP.

    CALL METHOD go_list_alv->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fcat_list.

*  -- 화면 갱신
    PERFORM set_matdata.
    PERFORM set_celltab.
    PERFORM set_alv_mode.
    PERFORM refresh_table.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form toolbar_exclude
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM toolbar_exclude .

    CLEAR gt_toolbar.

    APPEND : cl_gui_alv_grid=>mc_fc_loc_insert_row TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_delete_row TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_append_row TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_copy_row   TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_cut        TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_copy       TO gt_toolbar,
             cl_gui_alv_grid=>mc_mb_paste          TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_check          TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_refresh        TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_undo       TO gt_toolbar.

*  -- 행 위치변경/붙여넣기 계열 직접 차단
    APPEND '&LOCAL&MOVE_ROW'      TO gt_toolbar.
    APPEND '&LOCAL&PASTE'         TO gt_toolbar.
    APPEND '&LOCAL&PASTE_NEW_ROW' TO gt_toolbar.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form set_celltab
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM set_celltab .

    DATA : ls_style TYPE lvc_s_styl,
           ls_color TYPE lvc_s_scol,
           lv_tabix TYPE sy-tabix.

    LOOP AT gt_matdata INTO gs_matdata.

      lv_tabix = sy-tabix.
      CLEAR gs_matdata-celltab.

*     기존 행만 MATNR 잠금 (신규 행은 MATNR 비어있음)
      IF gs_matdata-matnr IS NOT INITIAL.
        CLEAR ls_style.
        ls_style-fieldname = 'MATNR'.
        ls_style-style     = cl_gui_alv_grid=>mc_style_disabled.
        INSERT ls_style INTO TABLE gs_matdata-celltab.
      ENDIF.

*  -- 미사용 자재 행 색상
      IF gs_matdata-lvorm = 'X'.
        gs_matdata-linecolor = 'C400'.
      ENDIF.

      MODIFY gt_matdata FROM gs_matdata INDEX lv_tabix TRANSPORTING celltab linecolor.

    ENDLOOP.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form handle_hotspot
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  &      --> E_ROW_ID
*  &      --> E_COLUMN_ID
*  &---------------------------------------------------------------------*
  FORM handle_hotspot  USING ps_row    TYPE lvc_s_row
                             ps_column TYPE lvc_s_col.

*  -- MATNR 클릭 시
    CHECK ps_column-fieldname = 'MATNR'.

    READ TABLE gt_matdata INTO gs_matdata INDEX ps_row-index.
    CHECK sy-subrc = 0.

*  -- 신규 행 핫스팟 X
    CHECK gs_matdata-matnr IS NOT INITIAL.

*  -- 미사용 자재는 이미지/재고 조회 X
    IF gs_matdata-lvorm = 'X'.
      MESSAGE s414 WITH gs_matdata-matnr gs_matdata-maktx DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    gv_selected_matnr = gs_matdata-matnr.

    PERFORM display_image.
    PERFORM get_stock_data.
    PERFORM display_stock.
    PERFORM display_memo.

*  -- 선택 행 하이라이팅
    PERFORM highlight_row USING ps_row-index.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form get_stock_data
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM get_stock_data .

    DATA : lt_lgort TYPE TABLE OF dd07v,
           ls_lgort TYPE dd07v.

*  -- 선택 자재 저장위치별 재고현황 조회
    SELECT matnr werks lgort charg clabs cinsm cspem meins
      INTO CORRESPONDING FIELDS OF TABLE gt_stock
      FROM ztc1mm0020
     WHERE matnr = gs_matdata-matnr.

*  -- 저장위치명 세팅 (도메인 ZDC1_MM_LGORT Fixed Value)
    CALL FUNCTION 'GET_DOMAIN_VALUES'
      EXPORTING
        domname         = 'ZDC1_MM_LGORT'
        text            = 'X'
      TABLES
        values_tab      = lt_lgort
      EXCEPTIONS
        no_values_found = 1
        OTHERS          = 2.

    LOOP AT gt_stock INTO gs_stock.

      READ TABLE lt_lgort INTO ls_lgort
        WITH KEY domvalue_l = gs_stock-lgort.
      IF sy-subrc = 0.
        gs_stock-lgort_txt = ls_lgort-ddtext.
      ENDIF.

      MODIFY gt_stock FROM gs_stock TRANSPORTING lgort_txt.

    ENDLOOP.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form display_image
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM display_image .

    DATA: lv_url         TYPE c LENGTH 255,
          lv_objid       TYPE w3objid,
          lv_img_matnr   TYPE ztc1mm0001-matnr,
          query_string   LIKE w3query OCCURS 1 WITH HEADER LINE,
          html           LIKE w3html OCCURS 1,
          mime           LIKE w3mime OCCURS 0,
          return_code    LIKE w3param-ret_code,
          content_type   LIKE w3param-cont_type,
          content_length LIKE w3param-cont_len,
          size           TYPE i.

*  -- 이전 이미지 클리어
    CALL METHOD go_picture->clear_picture.

*  --------------------------------------------------------------------*
*   1차: 현재 MATNR 기준 이미지 조회
*  --------------------------------------------------------------------*
    CLEAR lv_objid.
    CONCATENATE 'ZMAT_' gs_matdata-matnr INTO lv_objid.
    CONDENSE lv_objid NO-GAPS.

    CLEAR: query_string, html, mime.
    REFRESH: query_string, html, mime.

    query_string-name  = '_OBJECT_ID'.
    query_string-value = lv_objid.
    APPEND query_string.

    CALL FUNCTION 'WWW_GET_MIME_OBJECT'
      TABLES
        query_string        = query_string
        html                = html
        mime                = mime
      CHANGING
        return_code         = return_code
        content_type        = content_type
        content_length      = content_length
      EXCEPTIONS
        object_not_found    = 1
        parameter_not_found = 2
        OTHERS              = 3.

*  --------------------------------------------------------------------*
*   2차: 현재 MATNR 이미지가 없으면 BISMT 기준 이미지 조회
*  --------------------------------------------------------------------*
    IF sy-subrc <> 0 AND gs_matdata-bismt IS NOT INITIAL.

      CLEAR lv_objid.
      CONCATENATE 'ZMAT_' gs_matdata-bismt INTO lv_objid.
      CONDENSE lv_objid NO-GAPS.

      CLEAR: query_string, html, mime.
      REFRESH: query_string, html, mime.

      query_string-name  = '_OBJECT_ID'.
      query_string-value = lv_objid.
      APPEND query_string.

      CALL FUNCTION 'WWW_GET_MIME_OBJECT'
        TABLES
          query_string        = query_string
          html                = html
          mime                = mime
        CHANGING
          return_code         = return_code
          content_type        = content_type
          content_length      = content_length
        EXCEPTIONS
          object_not_found    = 1
          parameter_not_found = 2
          OTHERS              = 3.

    ENDIF.

*  --------------------------------------------------------------------*
*   3차: MATNR/BISMT 둘 다 없으면 기본 이미지
*  --------------------------------------------------------------------*
    IF sy-subrc <> 0.

      lv_objid = 'ZMAT_DEFAULT'.

      CLEAR: query_string, html, mime.
      REFRESH: query_string, html, mime.

      query_string-name  = '_OBJECT_ID'.
      query_string-value = lv_objid.
      APPEND query_string.

      CALL FUNCTION 'WWW_GET_MIME_OBJECT'
        TABLES
          query_string     = query_string
          html             = html
          mime             = mime
        CHANGING
          return_code      = return_code
          content_type     = content_type
          content_length   = content_length
        EXCEPTIONS
          object_not_found = 1
          OTHERS           = 99.

      CHECK sy-subrc = 0.

    ENDIF.

*  -- URL 생성
    size = content_length.

    CALL FUNCTION 'DP_CREATE_URL'
      EXPORTING
        type     = 'image'
        subtype  = cndp_sap_tab_unknown
        size     = size
        lifetime = cndp_lifetime_transaction
      TABLES
        data     = mime
      CHANGING
        url      = lv_url
      EXCEPTIONS
        OTHERS   = 1.

    CHECK lv_url IS NOT INITIAL.

*  -- 이미지 표시
    CALL METHOD go_picture->load_picture_from_url
      EXPORTING
        url = lv_url.

    CALL METHOD go_picture->set_display_mode
      EXPORTING
        display_mode = cl_gui_picture=>display_mode_fit_center.

  ENDFORM.

*  &---------------------------------------------------------------------*
*  & Form display_stock
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM display_stock .

    DATA: ls_layout TYPE lvc_s_layo.

*  -- grid_title을 선택자재로 갱신
    ls_layout-zebra      = abap_true.
    ls_layout-no_toolbar = abap_true.
    ls_layout-grid_title = |{ gs_matdata-maktx } 재고현황|.
    ls_layout-smalltitle = abap_true.

    IF gv_stock_init = abap_false.

*  -- 재고 ALV 필드카탈로그 ('S' = 재고현황 ALV)
      CLEAR : gs_fcat, gt_fcat_stock.
      PERFORM set_field_catalog USING : 'S' 'X' 'WERKS'     'ZTC1MM0020' 'C' '',
                                        'S' 'X' 'LGORT'     'ZTC1MM0020' 'C' '',
                                        'S' ' ' 'LGORT_TXT' ''           ' ' 'X',
                                        'S' ' ' 'CHARG'     'ZTC1MM0020' ' ' ' ',
                                        'S' ' ' 'CLABS'     'ZTC1MM0020' ' ' ' ',
                                        'S' ' ' 'CINSM'     'ZTC1MM0020' ' ' ' ',
                                        'S' ' ' 'CSPEM'     'ZTC1MM0020' ' ' ' ',
                                        'S' ' ' 'MEINS'     'ZTC1MM0020' 'C' ' '.

      CALL METHOD go_stock_alv->set_table_for_first_display
        EXPORTING
          is_layout       = ls_layout
        CHANGING
          it_outtab       = gt_stock
          it_fieldcatalog = gt_fcat_stock.

      gv_stock_init = abap_true.

    ELSE.

*  -- grid_title 적용 (선택 자재 변경시마다)
      CALL METHOD go_stock_alv->set_frontend_layout
        EXPORTING
          is_layout = ls_layout.

      CALL METHOD go_stock_alv->refresh_table_display.

    ENDIF.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form get_korean_text
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  &      --> PV_TABLE
*  &      --> PV_FIELD
*  &      <-- GS_FCAT_COLTEXT
*  &---------------------------------------------------------------------*
  FORM get_korean_text USING    VALUE(pv_table)
                                VALUE(pv_field)
                       CHANGING cv_coltext.

    DATA: lv_rollname TYPE rollname,
          lv_text     TYPE scrtext_m.

*  -- 참조테이블 없는 컬럼은 한글텍스트 조회 불필요
    CHECK pv_table IS NOT INITIAL.

*  -- DD03L에서 롤네임 조회
    SELECT SINGLE rollname
      FROM dd03l
      INTO lv_rollname
      WHERE tabname   = pv_table
        AND fieldname = pv_field.

    CHECK lv_rollname IS NOT INITIAL.

*  -- DD04T에서 한글 중간 텍스트 조회
    SELECT SINGLE scrtext_m
      FROM dd04t
      INTO lv_text
      WHERE rollname   = lv_rollname
        AND ddlanguage = '3'.

    IF lv_text IS NOT INITIAL.
      cv_coltext = lv_text.
    ENDIF.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form highlight_row
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  &      --> PS_ROW_INDEX
*  &---------------------------------------------------------------------*
  FORM highlight_row USING pv_index TYPE lvc_index.

    DATA : lv_tabix TYPE sy-tabix.

    LOOP AT gt_matdata INTO gs_matdata.

      lv_tabix = sy-tabix.

*  -- 삭제플래그 행은 색 유지
      IF gs_matdata-lvorm = 'X'.
        gs_matdata-linecolor = 'C400'.    " 빨강 (미사용)
      ELSEIF lv_tabix = pv_index.
        gs_matdata-linecolor = 'C300'.    " 노랑 (선택 행)
      ELSE.
        CLEAR gs_matdata-linecolor.       " 일반 행
      ENDIF.

      MODIFY gt_matdata FROM gs_matdata INDEX lv_tabix TRANSPORTING linecolor.

    ENDLOOP.

    PERFORM refresh_table.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form clear_condition
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  & -->  p1        text
*  & <--  p2        text
*  &---------------------------------------------------------------------*
  FORM clear_condition .

    DATA : ls_stock_layout TYPE lvc_s_layo.

*  -- 조회조건 초기화
    CLEAR : ztc1mm0001-matnr,
            ztc1mm0001-maktx,
            ztc1mm0001-mtart,
            ztc1mm0001-matkl.

*  -- 라디오버튼 초기화
    rb_all  = 'X'.
    rb_use  = ' '.
    rb_nuse = ' '.

*  -- 이미지 초기화 (NULL 체크)
    IF go_picture IS BOUND.
      CALL METHOD go_picture->clear_picture.
    ENDIF.

*  -- 재고 ALV 초기화 (grid title 포함)
    CLEAR gt_stock.
    IF gv_stock_init = abap_true AND go_stock_alv IS BOUND.
*  --   grid title 제거를 위해 layout 재적용
      ls_stock_layout-zebra      = abap_true.
      ls_stock_layout-no_toolbar = abap_true.
      ls_stock_layout-grid_title = space.
      CALL METHOD go_stock_alv->set_frontend_layout
        EXPORTING
          is_layout = ls_stock_layout.
      CALL METHOD go_stock_alv->refresh_table_display.
    ENDIF.

*  -- 메모 에디터 초기화
    IF go_memo_editor IS BOUND.
      DATA : lt_clear TYPE TABLE OF char255.
      REFRESH lt_clear.
      APPEND space TO lt_clear.
      CALL METHOD go_memo_editor->set_text_as_r3table
        EXPORTING
          table = lt_clear.
    ENDIF.

    CLEAR gv_selected_matnr.

    PERFORM search_matdata.

    MESSAGE s000 WITH '조회조건이 초기화되었습니다.'.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form check_matnr_in_use
*  &---------------------------------------------------------------------*
*  & text
*  &---------------------------------------------------------------------*
*  &      --> GS_MATDATA_MATNR
*  &      <-- LV_PR_CNT
*  &      <-- LV_PO_CNT
*  &---------------------------------------------------------------------*
  FORM check_matnr_in_use  USING    pv_matnr  TYPE ztc1mm0001-matnr
                           CHANGING cv_pr_cnt TYPE i
                                    cv_po_cnt TYPE i.

    CLEAR : cv_pr_cnt, cv_po_cnt.

*  -- PR: 취소 안 된 품목 중 미확정/일부확정 상태
    SELECT COUNT(*)
      FROM ztc1mm0026
     WHERE matnr = @pv_matnr
       AND loekz = ''
       AND statu = 'CR'
      INTO @cv_pr_cnt.

*  -- PO: 미입고/진행중 (AP 미완료) 품목
    SELECT COUNT(*)
      FROM ztc1mm0008
     WHERE matnr = @pv_matnr
       AND ( loekz IS INITIAL OR loekz = '' )
      INTO @cv_po_cnt.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form display_memo
*  &---------------------------------------------------------------------*
*  & 선택 자재의 비고(BIGO)를 메모 에디터에 표시
*  &---------------------------------------------------------------------*
  FORM display_memo .

    DATA : lt_text TYPE TABLE OF char255,
           lv_bigo TYPE ztc1mm0001-bigo.

    CHECK go_memo_editor IS BOUND.

*  -- 선택 자재의 비고 읽기
    CLEAR lv_bigo.
    SELECT SINGLE bigo
      INTO lv_bigo
      FROM ztc1mm0001
     WHERE matnr = gs_matdata-matnr.

*  -- 에디터에 표시 (텍스트 테이블로 변환)
    REFRESH lt_text.
    APPEND lv_bigo TO lt_text.

    CALL METHOD go_memo_editor->set_text_as_r3table
      EXPORTING
        table = lt_text.

  ENDFORM.
*  &---------------------------------------------------------------------*
*  & Form save_memo
*  &---------------------------------------------------------------------*
*  & 메모 에디터 내용을 선택 자재의 비고(BIGO)로 DB 저장
*  & (메모 전용 저장버튼 SMEMO에서 호출 / ALV 저장과 분리)
*  &---------------------------------------------------------------------*
  FORM save_memo .

    DATA : lt_memo TYPE TABLE OF char255,
           ls_memo TYPE char255,
           lv_bigo TYPE ztc1mm0001-bigo.

    CHECK go_memo_editor IS BOUND.

*  -- 선택 자재 없으면 막기
    IF gv_selected_matnr IS INITIAL.
      MESSAGE s000 WITH '자재를 먼저 선택하세요.' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

*  -- 에디터 내용 읽기
    REFRESH lt_memo.
    CALL METHOD go_memo_editor->get_text_as_r3table
      IMPORTING
        table  = lt_memo
      EXCEPTIONS
        OTHERS = 1.

*  -- 첫 줄만 사용 (CHAR 255 단일행)
    CLEAR lv_bigo.
    READ TABLE lt_memo INTO ls_memo INDEX 1.
    IF sy-subrc = 0.
      lv_bigo = ls_memo.
    ENDIF.

*  -- DB 저장
    UPDATE ztc1mm0001
       SET bigo = lv_bigo
     WHERE matnr = gv_selected_matnr.

    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.

*  --   내부테이블도 갱신 (재조회 없이 동기화)
      LOOP AT gt_matdata INTO gs_matdata
        WHERE matnr = gv_selected_matnr.
        gs_matdata-bigo = lv_bigo.
        MODIFY gt_matdata FROM gs_matdata INDEX sy-tabix
          TRANSPORTING bigo.
      ENDLOOP.

      MESSAGE s000 WITH '비고가 저장되었습니다.'.
    ELSE.
      ROLLBACK WORK.
      MESSAGE s000 WITH '비고 저장 중 오류가 발생했습니다.' DISPLAY LIKE 'E'.
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
*
*    IF go_html_dock IS NOT BOUND.
*
*      CREATE OBJECT go_html_dock
*        EXPORTING
*          side      = cl_gui_docking_container=>dock_at_top
*          extension = 35.
*
*    ENDIF.
*
*    IF go_html_header IS NOT BOUND.
*
*      CREATE OBJECT go_html_header
*        EXPORTING
*          io_parent = go_html_dock.
*
*    ENDIF.
*
*    go_html_header->display(
*     EXPORTING
*       iv_module_tag   = |MM|
*       iv_module_full  = |MM - Materials Management|
*       iv_program_name = |자재마스터 관리 프로그램|
*       iv_program_desc = |자재 조회, 변경, 상태 확인을 통합 관리하는 프로그램입니다|
*       iv_program_id   = |{ sy-repid }|
*       iv_system_info  = |{ sy-sysid } / { sy-mandt }|
*       iv_user_id      = |{ sy-uname }|
*       iv_user_name    = |{ sy-uname }|
*   ).

  ENDFORM.
