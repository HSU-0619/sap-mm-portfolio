*&---------------------------------------------------------------------*
*& Include          SAPMZC1MM0096_I01
*&---------------------------------------------------------------------*
*& PROCESS AFTER INPUT Modules
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module EXIT_0100 INPUT
*&---------------------------------------------------------------------*
MODULE exit INPUT.

  CALL METHOD : go_list_alv->free,
                go_price_alv->free,
                go_po_alv->free,
                go_price_cont->free,
                go_po_cont->free,
                go_detail_split->free,
                go_list_cont->free,
                go_detail_cont->free,
                go_splitter->free,
                go_main_cont->free.

  FREE : go_list_alv, go_price_alv, go_po_alv, go_price_cont,
         go_po_cont, go_detail_split, go_list_cont, go_detail_cont,
         go_splitter, go_main_cont.

  LEAVE TO SCREEN 0.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module USER_COMMAND_0100 INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  DATA lv_ok_100 TYPE sy-ucomm.

  lv_ok_100 = gv_okcode.
  CLEAR gv_okcode.

  CASE lv_ok_100.
    WHEN 'SEARCH'.
      PERFORM search_data.   " 조회
    WHEN 'NEWPIR'.
      PERFORM new_pir.       " 신규 (팝업)
    WHEN 'CLEAR'.
      PERFORM clear_search.  " 초기화
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module EXIT_0200 INPUT
*&---------------------------------------------------------------------*
MODULE exit_0200 INPUT.

  CASE gv_okcode.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      CLEAR gv_okcode.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module USER_COMMAND_0200 INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  DATA lv_ok_200 TYPE sy-ucomm.

  lv_ok_200 = gv_okcode.
  CLEAR gv_okcode.

  PERFORM calc_valid_period.

  CASE lv_ok_200.
    WHEN 'SAVE'.
      PERFORM save_new_pir.   " 저장
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module F4_POP_MATNR INPUT
*&---------------------------------------------------------------------*
*-- 화면 0200 팝업 자재번호 Search Help
*&---------------------------------------------------------------------*
MODULE f4_pop_matnr INPUT.

  PERFORM f4_pop_matnr.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module F4_POP_LIFNR INPUT
*&---------------------------------------------------------------------*
*-- 화면 0200 팝업 공급업체 Search Help
*&---------------------------------------------------------------------*
MODULE f4_pop_lifnr INPUT.

  PERFORM f4_pop_lifnr.

ENDMODULE.
