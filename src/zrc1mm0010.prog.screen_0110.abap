PROCESS BEFORE OUTPUT.
* MODULE STATUS_0110.
*
PROCESS AFTER INPUT.
  MODULE user_command_0110.

PROCESS ON VALUE-REQUEST.
  FIELD gv_s_ebeln MODULE f4_ebeln.
  FIELD gv_s_bldat MODULE f4_date_bldat.
  FIELD gv_s_budat MODULE f4_date_budat.
