*&---------------------------------------------------------------------*
*& Include          ZRC1MM0004_C01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Class LCL_EVENT_HANDLER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS : on_double_click    FOR EVENT double_click OF cl_gui_alv_grid
                                       IMPORTING e_row e_column,
                    on_toolbar         FOR EVENT toolbar OF cl_gui_alv_grid
                                       IMPORTING e_object sender,
                    on_user_command    FOR EVENT user_command OF cl_gui_alv_grid
                                       IMPORTING e_ucomm,
                    on_alv_checkbox    FOR EVENT data_changed OF cl_gui_alv_grid
                                       IMPORTING er_data_changed,
                    modify_value       FOR EVENT data_changed_finished OF cl_gui_alv_grid
                                       IMPORTING e_modified et_good_cells,
                    handle_search_help FOR EVENT onf4 OF cl_gui_alv_grid
                                       IMPORTING e_fieldname
                                                 e_fieldvalue
                                                 es_row_no
                                                 er_event_data
                                                 et_bad_cells
                                                 e_display.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Class (Implementation) LCL_EVENT_HANDLER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

  METHOD on_double_click.
    PERFORM handle_double_click USING e_row e_column.
  ENDMETHOD.

  METHOD on_toolbar.
    CASE sender.
      WHEN go_left_alv.
        PERFORM handle_toolbar USING e_object.
      WHEN go_right_mid_alv.
        PERFORM handle_toolbar_detail_mid USING e_object.
      WHEN go_right_bot_alv.
        PERFORM handle_toolbar_detail_bot USING e_object.
      WHEN go_create_alv.
        PERFORM handle_toolbar_create USING e_object.
    ENDCASE.
  ENDMETHOD.

  METHOD on_user_command.
    PERFORM handle_user_command USING e_ucomm.
  ENDMETHOD.

  METHOD on_alv_checkbox.
    PERFORM handle_alv_checkbox USING er_data_changed.     " 삭제 체크박스
  ENDMETHOD.

  METHOD modify_value.
    PERFORM handle_modify_value USING e_modified et_good_cells.    " 수동생성 자동세팅
  ENDMETHOD.

  METHOD handle_search_help.
    PERFORM onf4 USING e_fieldname        " Search help
                       e_fieldvalue
                       es_row_no
                       er_event_data
                       et_bad_cells
                       e_display.
  ENDMETHOD.

ENDCLASS.
