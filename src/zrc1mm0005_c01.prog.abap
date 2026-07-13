*&---------------------------------------------------------------------*
*& Include          ZRC1MM0005_C01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Class LCL_EVENT_HANDLER
*&---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS : on_double_click  FOR EVENT double_click OF cl_gui_alv_grid
                                     IMPORTING e_row e_column sender,
                    on_toolbar       FOR EVENT toolbar      OF cl_gui_alv_grid
                                     IMPORTING e_object sender,
                    on_user_command  FOR EVENT user_command OF cl_gui_alv_grid
                                     IMPORTING e_ucomm,
                    on_tree_command  FOR EVENT function_selected OF cl_gui_toolbar
                                     IMPORTING fcode,
                    on_link_click    FOR EVENT link_click   OF cl_gui_alv_tree
                                     IMPORTING node_key fieldname,
                    on_sapevent      FOR EVENT sapevent     OF cl_gui_html_viewer
                                     IMPORTING action,
                    on_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
                                     IMPORTING e_row_id e_column_id sender.

ENDCLASS.

*&---------------------------------------------------------------------*
*& Class (Implementation) LCL_EVENT_HANDLER
*&---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

  METHOD on_double_click.
    CASE sender.
      WHEN go_left_alv.
        PERFORM handle_double_click USING e_row e_column.
      WHEN go_po_alv.
        PERFORM handle_double_click_po USING e_row.
    ENDCASE.
  ENDMETHOD.

  METHOD on_toolbar.
    CASE sender.
      WHEN go_left_alv.
        PERFORM handle_toolbar_left USING e_object.
      WHEN go_right_alv.
        PERFORM handle_toolbar_right USING e_object.
      WHEN go_po_alv.
        PERFORM handle_toolbar_po USING e_object.
    ENDCASE.
  ENDMETHOD.

  METHOD on_user_command.
    PERFORM handle_user_command USING e_ucomm.
  ENDMETHOD.

  METHOD on_tree_command.
    PERFORM handle_tree_command USING fcode.
  ENDMETHOD.

  METHOD on_link_click.
    PERFORM handle_tree_link_click USING node_key fieldname.
  ENDMETHOD.

  METHOD on_sapevent.
    PERFORM handle_card_click USING action.
  ENDMETHOD.

  METHOD on_hotspot_click.
    CASE sender.
      WHEN go_po_alv.
        PERFORM handle_bigo_click USING e_row_id e_column_id.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
