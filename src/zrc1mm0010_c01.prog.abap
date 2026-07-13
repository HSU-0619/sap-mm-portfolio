*&---------------------------------------------------------------------*
*& Include          ZRC1MM0010_C01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Class lcl_event_handler
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION FINAL.

  PUBLIC SECTION.

    CLASS-METHODS : on_data_changed_finished  FOR EVENT data_changed_finished OF cl_gui_alv_grid
                                              IMPORTING e_modified sender,
                    on_toolbar                FOR EVENT toolbar OF cl_gui_alv_grid
                                              IMPORTING e_object.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Class (Implementation) lcl_event_handler
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

  METHOD on_data_changed_finished.
*-- 단건 탭에서만, 실제 변경이 있을 때만 재계산/검증
    IF sender = go_single_alv AND e_modified = 'X'.
      PERFORM handle_single_changed.
    ENDIF.
  ENDMETHOD.

  METHOD on_toolbar.
    PERFORM handle_toolbar USING e_object.
  ENDMETHOD.

ENDCLASS.
