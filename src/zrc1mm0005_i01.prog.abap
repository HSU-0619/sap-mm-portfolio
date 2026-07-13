*&---------------------------------------------------------------------*
*& Include          ZRC1MM0005_I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.

  CALL METHOD : go_detail_i_alv->free,
                go_detail_h_html->free,
                go_detail_split->free,
                go_po_alv->free,
                go_po_splitter->free,
                go_card_html->free,
                go_po_main_cont->free,
                go_card_cont->free,
                go_bottom_tree->free,
                go_right_alv->free,
                go_left_alv->free,
                go_bottom_cont->free,
                go_right_cont->free,
                go_left_cont->free.

  FREE : go_detail_i_alv, go_detail_h_html, go_detail_split,
         go_po_alv, go_po_splitter, go_card_html,
         go_po_main_cont, go_card_cont,
         go_bottom_tree, go_right_alv, go_left_alv,
         go_bottom_cont, go_right_cont, go_left_cont.

  LEAVE TO SCREEN 0.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  IF gv_okcode(3) = 'TAB'.
    tab_strip-activetab = gv_okcode.
  ENDIF.

*  CASE gv_okcode.
*    WHEN 'SEARCH'.
*      PERFORM search_prdata.
*  ENDCASE.

  CLEAR gv_okcode.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0110  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0110 INPUT.

  CASE gv_okcode.
    WHEN 'SEARCH'.
      PERFORM search_prdata.
    WHEN 'REFRESH'.
      PERFORM refresh_pr.
    WHEN 'PO_ADD'.
      PERFORM add_conv_list.
    WHEN 'SEL_ALL'.
      PERFORM select_all_right.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0120  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0120 INPUT.

  CASE gv_okcode.
    WHEN 'SEARCH'.
      PERFORM search_podata.
    WHEN 'REFRESH'.
      PERFORM refresh_po.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  CASE ok_code_0200.
    WHEN 'SAVE'.
      PERFORM save_modify USING abap_false.

    WHEN 'RESUBMIT'.
      PERFORM save_modify USING abap_true.

    WHEN 'CANCEL' OR 'EXIT' OR 'BACK'.
*-- 다음 진입 시 새 데이터로 재초기화하기 위해 컨테이너 해제
      IF go_modi_cont IS BOUND.
        CALL METHOD go_modi_cont->free.
        CLEAR : go_modi_cont, go_modi_alv.
      ENDIF.

      IF go_bigo_cont IS BOUND.
        CALL METHOD go_bigo_cont->free.
        CLEAR : go_bigo_cont, go_bigo_text.
      ENDIF.

      LEAVE TO SCREEN 0.
  ENDCASE.

  CLEAR ok_code_0200.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  EXIT_200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_300 INPUT.

  CALL METHOD : go_bigo_pop_html->free,
                go_bigo_pop_cont->free.

  FREE : go_bigo_pop_html, go_bigo_pop_cont.

  LEAVE TO SCREEN 0.

ENDMODULE.
