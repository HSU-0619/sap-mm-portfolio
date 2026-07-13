*&---------------------------------------------------------------------*
*& Include          SAPMZC1MM0096_C01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Class LCL_EVENT_HANDLER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS : on_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
                                     IMPORTING e_row_id e_column_id,
                    on_data_changed_finished FOR EVENT data_changed_finished OF cl_gui_alv_grid
                                             IMPORTING e_modified et_good_cells,
                    on_toolbar       FOR EVENT toolbar OF cl_gui_alv_grid
                                     IMPORTING e_object sender,
                    on_user_command  FOR EVENT user_command OF cl_gui_alv_grid
                                     IMPORTING e_ucomm.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Class (Implementation) LCL_EVENT_HANDLER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

*-- INFNR 핫스팟 클릭 → 상세 + PO 이력 조회
  METHOD on_hotspot_click.
    PERFORM handle_hotspot_click USING e_row_id e_column_id.
  ENDMETHOD.

  METHOD on_data_changed_finished.
    CHECK e_modified = 'X'.
    PERFORM handle_data_changed USING et_good_cells.
  ENDMETHOD.

*-- 툴바 : sender 로 어느 ALV 인지 구분
  METHOD on_toolbar.
    PERFORM handle_toolbar_price USING e_object.
  ENDMETHOD.

*-- 툴바 버튼 클릭
  METHOD on_user_command.
    PERFORM handle_user_command USING e_ucomm.
  ENDMETHOD.

ENDCLASS.
