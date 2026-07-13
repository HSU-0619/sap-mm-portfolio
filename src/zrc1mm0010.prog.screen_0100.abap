PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  MODULE init_process_control.
  MODULE set_screen_number.

  MODULE display_html_header_0100.

  CALL SUBSCREEN sub_area INCLUDING sy-repid gv_dynnr.

PROCESS AFTER INPUT.
  MODULE save_okcode.
  CALL SUBSCREEN sub_area.
  MODULE exit AT EXIT-COMMAND.
  MODULE user_command_0100.
