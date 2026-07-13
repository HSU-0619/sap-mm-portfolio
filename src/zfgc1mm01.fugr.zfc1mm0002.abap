FUNCTION ZFC1MM0002.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXCEPTIONS
*"     NO_DATA
*"----------------------------------------------------------------------
  DATA: lt_ver  TYPE TABLE OF ztc1mm0001,
        lt_fcat TYPE slis_t_fieldcat_alv,
        ls_fcat TYPE slis_fieldcat_alv,
        lt_sort TYPE slis_t_sortinfo_alv,
        ls_sort TYPE slis_sortinfo_alv.

  REFRESH: lt_ver, lt_fcat, lt_sort.

*  -- 버전그룹 지정된 전체 자재 조회
  SELECT vrsgr matnr maktx vrsnr
    INTO CORRESPONDING FIELDS OF TABLE lt_ver
    FROM ztc1mm0001
   WHERE vrsgr <> space.

  IF lt_ver IS INITIAL.
    RAISE no_data.
  ENDIF.

*  -- 정렬 (그룹 → 불출순위)
  SORT lt_ver BY vrsgr ASCENDING vrsnr ASCENDING.

*  -- 필드카탈로그
  CLEAR ls_fcat.
  ls_fcat-fieldname = 'VRSGR'. ls_fcat-seltext_m = '그룹'.
  ls_fcat-outputlen = 10.      APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'MATNR'. ls_fcat-seltext_m = '자재코드'.
  ls_fcat-outputlen = 12.      APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'MAKTX'. ls_fcat-seltext_m = '자재명'.
  ls_fcat-outputlen = 30.      APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'VRSNR'. ls_fcat-seltext_m = '불출순위'.
  ls_fcat-outputlen = 8.       ls_fcat-just = 'R'.
  APPEND ls_fcat TO lt_fcat.

*  -- 정렬/그룹화 (VRSGR 같은 값은 첫 행만 표시)
  CLEAR ls_sort.
  ls_sort-spos      = 1.
  ls_sort-fieldname = 'VRSGR'.
  ls_sort-up        = 'X'.
  ls_sort-group     = '*'.
  APPEND ls_sort TO lt_sort.

  CLEAR ls_sort.
  ls_sort-spos      = 2.
  ls_sort-fieldname = 'VRSNR'.
  ls_sort-up        = 'X'.
  APPEND ls_sort TO lt_sort.

*  -- ALV 출력 (팝업)
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      it_fieldcat           = lt_fcat
      it_sort               = lt_sort
      i_screen_start_column = 25
      i_screen_start_line   = 3
      i_screen_end_column   = 107
      i_screen_end_line     = 20
    TABLES
      t_outtab              = lt_ver
    EXCEPTIONS
      OTHERS                = 1.

ENDFUNCTION.
