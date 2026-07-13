*&---------------------------------------------------------------------*
*& Include          ZRC1MM0005_O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'M100'.
  SET TITLEBAR 'T100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_PROCESS_CONTROL OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_process_control OUTPUT.

  PERFORM display_screen.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_SCREEN_NUMBER OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_screen_number OUTPUT.

  PERFORM set_subscreen_number.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0110 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0110 OUTPUT.

  IF gv_sel_banfn IS INITIAL.
    gv_title = ''.
  ELSE.
    gv_title = |구매요청 { gv_sel_banfn } · 품목 목록|.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.

  DATA : lt_excl TYPE TABLE OF sy-ucomm.

*-- 반려가 아니면 재상신 버튼 숨김
  IF gv_modi_statu <> 'RJ'.
    APPEND 'RESUBMIT' TO lt_excl.
  ENDIF.

  SET PF-STATUS 'M200' EXCLUDING lt_excl.
  SET TITLEBAR  'T200' WITH gv_modi_ebeln.

*-- 반려건만 BIGO 영역 표시
  LOOP AT SCREEN.
    IF screen-group1 = 'BIG'.
      IF gv_modi_statu = 'RJ' AND gv_modi_bigo IS NOT INITIAL.
        screen-invisible = 0.
        screen-active    = 1.
      ELSE.
        screen-invisible = 1.
        screen-active    = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

*-- 컨테이너/ALV 최초 1회 생성
  IF go_modi_cont IS NOT BOUND.

    CREATE OBJECT go_modi_cont
      EXPORTING
        container_name = 'MODI_CONT'.

    CREATE OBJECT go_modi_alv
      EXPORTING
        i_parent = go_modi_cont.

    CALL METHOD go_modi_alv->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layout_modi
      CHANGING
        it_outtab       = gt_modi_item
        it_fieldcatalog = gt_fcat_modi.

    CALL METHOD go_modi_alv->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified.

  ELSE.
    PERFORM refresh_table USING go_modi_alv.
  ENDIF.

*-- 반려 사유 텍스트 박스 (반려건만)
  IF gv_modi_statu = 'RJ' AND gv_modi_bigo IS NOT INITIAL.

    IF go_bigo_cont IS NOT BOUND.

      CREATE OBJECT go_bigo_cont
        EXPORTING
          container_name = 'BIGO_CONT'.

      CREATE OBJECT go_bigo_text
        EXPORTING
          parent = go_bigo_cont.

*-- 읽기 전용 + 멀티라인
      CALL METHOD go_bigo_text->set_readonly_mode
        EXPORTING
          readonly_mode = cl_gui_textedit=>true.

      CALL METHOD go_bigo_text->set_toolbar_mode
        EXPORTING
          toolbar_mode = cl_gui_textedit=>false.

      CALL METHOD go_bigo_text->set_statusbar_mode
        EXPORTING
          statusbar_mode = cl_gui_textedit=>false.

    ENDIF.

*-- 텍스트 설정
    DATA : lt_bigo_text TYPE TABLE OF char255.
    CLEAR lt_bigo_text.
    APPEND gv_modi_bigo TO lt_bigo_text.

    CALL METHOD go_bigo_text->set_text_as_stream
      EXPORTING
        text = lt_bigo_text.

  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  SET PF-STATUS 'M300'.
  SET TITLEBAR 'T300'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module CREATE_POPUP OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE create_popup OUTPUT.

  PERFORM create_bigo_popup.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module DISPLAY_HTML_HEADER_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
*MODULE display_html_header_0100 OUTPUT.
*
*  PERFORM display_html_header.
*
*ENDMODULE.
