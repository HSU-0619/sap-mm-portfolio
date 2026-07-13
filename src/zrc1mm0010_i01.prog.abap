*&---------------------------------------------------------------------*
*& Include          ZRC1MM0010_I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.

  CALL METHOD : go_mass_alv->free,
                go_single_alv->free,
                go_mass_cont->free,
                go_single_cont->free.

  FREE : go_mass_alv, go_single_alv, go_mass_cont, go_single_cont.

  LEAVE TO SCREEN 0.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  SAVE_OKCODE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE save_okcode INPUT.

  gv_save_ok = gv_okcode.
  CLEAR gv_okcode.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  IF gv_save_ok(3) = 'TAB'.
    tab_strip-activetab = gv_save_ok.
  ENDIF.

  CLEAR gv_save_ok.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0110  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0110 INPUT.

  CASE gv_save_ok.
    WHEN 'SEARCH'.
      PERFORM search_single_po.
    WHEN 'VERIFY'.
      PERFORM verify_single.
    WHEN 'POST'.
      PERFORM post_single.
    WHEN 'RESET'.
      PERFORM clear_single.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0120  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0120 INPUT.

  CASE gv_save_ok.
    WHEN 'UPLOAD'.
      PERFORM upload_mass_excel.
    WHEN 'VERIFY'.
      PERFORM verify_mass.
    WHEN 'POST'.
      PERFORM post_mass.
    WHEN 'RESET'.
      PERFORM clear_mass.
    WHEN 'DOWN'.
      PERFORM download_template.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  F4_DATE_BLDAT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_date_bldat INPUT.

  PERFORM set_field_bldat.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  F4_DATE_BUDAT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_date_budat INPUT.

  PERFORM set_field_budat.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  F4_EBELN  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_ebeln INPUT.

  PERFORM f4_help_ebeln.

ENDMODULE.
