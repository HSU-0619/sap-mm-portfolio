PROCESS BEFORE OUTPUT.
  MODULE status_0200.
  MODULE modify_popup.
  MODULE set_f4_help.

PROCESS AFTER INPUT.
  FIELD gs_item-menge MODULE calc_total ON REQUEST.
  MODULE exit_200 AT EXIT-COMMAND.
  MODULE user_command_0200.

PROCESS ON VALUE-REQUEST.
  FIELD gs_item-matnr MODULE f4_help.
