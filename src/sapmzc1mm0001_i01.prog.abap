*&---------------------------------------------------------------------*
*& Include          SAPMZC1MM0001_I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.

  CALL METHOD : go_picture->free,
                go_list_alv->free,
                go_pic_cont->free,
                go_list_cont->free,
                go_container->free.

  FREE : go_picture, go_list_alv, go_pic_cont, go_list_cont, go_container.

  LEAVE TO SCREEN 0.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE gv_okcode.
    WHEN 'SEARCH'.
      PERFORM search_matdata.
    WHEN 'CLEAR'.
      PERFORM clear_condition.
    WHEN 'SAVE'.
      PERFORM save_data.
  ENDCASE.

ENDMODULE.
