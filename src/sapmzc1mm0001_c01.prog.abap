*&---------------------------------------------------------------------*
*& Include          SAPMZC1MM0001_C01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Class LCL_EVENT_HANDLER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS : add_toolbar   FOR EVENT toolbar       OF cl_gui_alv_grid
                                  IMPORTING e_object,
                    user_command  FOR EVENT user_command  OF cl_gui_alv_grid
                                  IMPORTING e_ucomm,
                    hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
                                  IMPORTING e_row_id e_column_id,
                    memo_toolbar_click FOR EVENT function_selected OF cl_gui_toolbar
                                       IMPORTING fcode.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Class (Implementation) LCL_EVENT_HANDLER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

  METHOD add_toolbar.
    PERFORM handle_add_toolbar USING e_object.
  ENDMETHOD.

  METHOD user_command.
    PERFORM handle_user_command USING e_ucomm.
  ENDMETHOD.

  METHOD hotspot_click.
    PERFORM handle_hotspot USING e_row_id e_column_id.
  ENDMETHOD.

  METHOD memo_toolbar_click.
    CASE fcode.
      WHEN 'SMEMO'.
        PERFORM save_memo.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
