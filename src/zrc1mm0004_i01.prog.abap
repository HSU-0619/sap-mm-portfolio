*&---------------------------------------------------------------------*
*& Include          ZRC1MM0004_I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.

  CALL METHOD : go_create_alv->free,
                go_left_alv->free,
                go_html_viewer->free,
                go_right_mid_alv->free,
                go_right_bot_alv->free,
                go_right_top_cont->free,
                go_right_mid_cont->free,
                go_right_bot_cont->free,
                go_right_split->free,
                go_left_cont->free,
                go_right_cont->free,
                go_split_cont->free,
                go_create_cont->free,
                go_list_cont->free.

  FREE : go_create_alv , go_left_alv, go_html_viewer, go_right_mid_alv, go_right_bot_alv,
         go_right_split, go_left_cont, go_right_cont, go_split_cont, go_create_cont, go_list_cont.

  LEAVE TO SCREEN 0.

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
*&      Module  EXIT_200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_200 INPUT.

  CALL METHOD : go_modi_alv->free,
                go_modi_pop->free.

  FREE : go_modi_alv, go_modi_pop.

  LEAVE TO SCREEN 0.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  F4_HELP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help INPUT.

  PERFORM set_f4_help.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  CALC_TOTAL  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE calc_total INPUT.

  PERFORM calc_mat_total.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  DATA: lv_ucomm TYPE sy-ucomm.
  lv_ucomm = gv_okcode.
  CLEAR gv_okcode.

  CASE lv_ucomm.
    WHEN 'SAVE'.
      PERFORM modify_pr.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  F4_BANFN_HELP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_banfn_help INPUT.

  PERFORM set_banfn_help.

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
*&      Module  USER_COMMAND_0110  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0110 INPUT.

  CASE gv_save_ok.
    WHEN 'SEARCH'.
      PERFORM search_pr.
    WHEN 'REFRESH'.
      PERFORM refresh_pr.
    WHEN 'PO_SCREEN'.
      CALL TRANSACTION 'ZRC1MM0005'.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0120  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0120 INPUT.

  CASE gv_save_ok.
    WHEN 'PO_SCREEN'.
      CALL TRANSACTION 'ZRC1MM0005'.
  ENDCASE.

ENDMODULE.
