FUNCTION ZFC1MM0001.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCT
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     REFERENCE(SHLP) TYPE  SHLP_DESCR
*"     REFERENCE(CALLCONTROL) TYPE  DDSHF4CTRL
*"----------------------------------------------------------------------

*-- 중복 값 제거
SORT RECORD_TAB BY STRING.
DELETE ADJACENT DUPLICATES FROM RECORD_TAB COMPARING STRING.

ENDFUNCTION.
