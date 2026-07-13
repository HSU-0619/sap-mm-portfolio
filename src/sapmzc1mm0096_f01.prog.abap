*&---------------------------------------------------------------------*
*& Include          SAPMZC1MM0096_F01
*&---------------------------------------------------------------------*
*& FORM Routines
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form display_screen
*&---------------------------------------------------------------------*
*-- ALV 컨테이너/그리드 최초 1회 생성 + 초기 목록 출력
*&---------------------------------------------------------------------*
FORM display_screen .

  IF go_main_cont IS NOT BOUND.

    PERFORM create_object.
    PERFORM set_layout.

*-- 초기 목록 조회
    PERFORM get_data.

    PERFORM toolbar_exclude.

*-- 필드 카탈로그
    CLEAR : gt_fcat_list, gt_fcat_price, gt_fcat_po, gs_fcat.

    PERFORM set_field_catalog USING :
                                      " L : PIR 목록
                                      'L' 'STATUS_ICON' 'C' 4,
                                      'L' 'INFNR'       'C' 12,
                                      'L' 'MATNR'       'L' 12,
                                      'L' 'MAKTX'       'L' 16,
                                      'L' 'LIFNR'       'C' 6,
                                      'L' 'NAME1'       'L' 16,
                                      'L' 'KDATB'       'C' 10,
                                      'L' 'KDATE'       'C' 10,
                                      'L' 'NETPR'       'R' 8,
                                      'L' 'WAERS'       'C' 5,
                                      'L' 'LOEKZ'       'C' 6,

                                      " P : 단가 입력/이력
                                      'P' 'VALID_FROM'  'C' 10,
                                      'P' 'VALID_TO'    'C' 10,
                                      'P' 'EKORG'       'C' 6,
                                      'P' 'WERKS'       'C' 6,
                                      'P' 'NETPR'       'R' 8,
                                      'P' 'PEINH'       'R' 6,
                                      'P' 'WAERS'       'C' 5,
                                      'P' 'MINBM'       'R' 8,
                                      'P' 'NORBM'       'R' 8,
                                      'P' 'MEINS'       'C' 6,
                                      'P' 'APLFZ'       'R' 8,
                                      'P' 'LOEKZ'       'C' 6,

                                      " O : NB PO 이력 (ZAPC 제외)
                                      'O' 'EBELN'      'C' 10,
                                      'O' 'EBELP'      'C' 6,
                                      'O' 'MATNR'      'L' 12,
                                      'O' 'MAKTX'      'L' 16,
                                      'O' 'MENGE'      'R' 10,
                                      'O' 'MEINS'      'C' 6,
                                      'O' 'NETPR'      'R' 8,
                                      'O' 'PEINH'      'R' 6,
                                      'O' 'WAERS'      'C' 5,
                                      'O' 'WERKS'      'C' 6,
                                      'O' 'LGORT'      'C' 6,
                                      'O' 'BEDAT'      'C' 10,
                                      'O' 'STATU_TEXT' 'C' 10.

*-- 이벤트 등록
    SET HANDLER : lcl_event_handler=>on_hotspot_click         FOR go_list_alv,
                  lcl_event_handler=>on_data_changed_finished FOR go_list_alv,
                  lcl_event_handler=>on_toolbar               FOR go_price_alv,
                  lcl_event_handler=>on_user_command          FOR go_price_alv.

    PERFORM create_display.

*-- 목록 ALV : LOEKZ 체크박스 즉시 이벤트
    CALL METHOD go_list_alv->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_object
*&---------------------------------------------------------------------*
*-- 단일 메인 컨테이너 → 스플리터로 좌(PIR목록)/우(상세영역) 분할
*-- 우측은 다시 상(단가)/하(NB PO이력)로 분할. 초기 우측 폭 = 0 (숨김)
*&---------------------------------------------------------------------*
FORM create_object .

*-- 메인 커스텀 컨테이너 (SE51 화면 0100 'MAIN_CONT')
  CREATE OBJECT go_main_cont
    EXPORTING
      container_name = 'MAIN_CONT'.

*-- 좌/우 스플리터
  CREATE OBJECT go_splitter
    EXPORTING
      parent  = go_main_cont
      rows    = 1
      columns = 2.

  CALL METHOD go_splitter->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_list_cont.

  CALL METHOD go_splitter->get_container
    EXPORTING
      row       = 1
      column    = 2
    RECEIVING
      container = go_detail_cont.

*-- 초기 좌측 100% / 우측 0% (상세 숨김 → INFNR 클릭 시 펼침)
  CALL METHOD go_splitter->set_column_width
    EXPORTING
      id    = 1
      width = 100.

*-- 우측 상/하 스플리터 (상:단가이력 / 하:NB PO이력)
  CREATE OBJECT go_detail_split
    EXPORTING
      parent  = go_detail_cont
      rows    = 2
      columns = 1.

  CALL METHOD go_detail_split->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_price_cont.

  CALL METHOD go_detail_split->get_container
    EXPORTING
      row       = 2
      column    = 1
    RECEIVING
      container = go_po_cont.

*-- 단가 50% / PO 이력 50%
  CALL METHOD go_detail_split->set_row_height
    EXPORTING
      id     = 1
      height = 50.

*-- ALV 그리드 생성
  CREATE OBJECT go_list_alv
    EXPORTING
      i_parent = go_list_cont.

  CREATE OBJECT go_price_alv
    EXPORTING
      i_parent = go_price_cont.

  CREATE OBJECT go_po_alv
    EXPORTING
      i_parent = go_po_cont.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout
*&---------------------------------------------------------------------*
*-- cwidth_opt 미사용 → fcat 의 outputlen 으로 칸 폭 직접 제어
*&---------------------------------------------------------------------*
FORM set_layout .

  gs_layo_list  = VALUE #( zebra      = 'X'
                           sel_mode   = 'A'
                           info_fname = 'LINECOLOR' ).

*-- 단가 ALV : celltab 으로 신규행만 편집
  gs_layo_price = VALUE #( zebra      = 'X'
                           sel_mode   = 'A'
                           stylefname = 'CELLTAB' ).

  gs_layo_po    = VALUE #( zebra      = 'X'
                           sel_mode   = 'A' ).

  gs_variant    = VALUE #( report = sy-repid
                           handle = 'PIR' ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog
*&---------------------------------------------------------------------*
*&      --> PV_FLAG    L=목록 / P=단가 / O=PO
*&      --> PV_FIELD   필드명
*&      --> PV_JUST    정렬 (L/C/R)
*&      --> PV_LEN     컬럼 폭
*&---------------------------------------------------------------------*
FORM set_field_catalog USING pv_flag  TYPE c
                             pv_field TYPE lvc_fname
                             pv_just  TYPE lvc_just
                             pv_len   TYPE lvc_outlen.

  CLEAR gs_fcat.
  gs_fcat-fieldname = pv_field.
  gs_fcat-just      = pv_just.
  gs_fcat-outputlen = pv_len.

*-- 공통 컬럼 속성
  CASE pv_field.
    WHEN 'STATUS_ICON'.
      gs_fcat-coltext = '상태'.
      gs_fcat-icon    = 'X'.
    WHEN 'INFNR'.
      gs_fcat-coltext = '정보레코드'.
    WHEN 'MATNR'.
      gs_fcat-coltext = '자재번호'.
    WHEN 'MAKTX'.
      gs_fcat-coltext = '자재명'.
    WHEN 'LIFNR'.
      gs_fcat-coltext = '벤더'.
    WHEN 'NAME1'.
      gs_fcat-coltext = '벤더명'.
    WHEN 'KDATB'.
      gs_fcat-coltext = '계약시작일'.
    WHEN 'KDATE'.
      gs_fcat-coltext = '계약종료일'.
    WHEN 'VALID_FROM'.
      gs_fcat-coltext = '단가시작일'.
    WHEN 'VALID_TO'.
      gs_fcat-coltext = '단가종료일'.
    WHEN 'EKORG'.
      gs_fcat-coltext = '구매조직'.
    WHEN 'WERKS'.
      gs_fcat-coltext = '플랜트'.
    WHEN 'LGORT'.
      gs_fcat-coltext = '저장위치'.
    WHEN 'NETPR'.
      gs_fcat-coltext    = '단가'.
      gs_fcat-cfieldname = 'WAERS'.
    WHEN 'PEINH'.
      gs_fcat-coltext = '가격단위'.
    WHEN 'WAERS'.
      gs_fcat-coltext = '통화'.
    WHEN 'MINBM'.
      gs_fcat-coltext    = '최소주문수량'.
      gs_fcat-qfieldname = 'MEINS'.
    WHEN 'NORBM'.
      gs_fcat-coltext    = '표준발주수량'.
      gs_fcat-qfieldname = 'MEINS'.
    WHEN 'MENGE'.
      gs_fcat-coltext    = '발주수량'.
      gs_fcat-qfieldname = 'MEINS'.
    WHEN 'MEINS'.
      gs_fcat-coltext = '단위'.
    WHEN 'APLFZ'.
      gs_fcat-coltext = '리드타임'.
    WHEN 'WEBRE'.
      gs_fcat-coltext  = 'GR기준IV'.
      gs_fcat-checkbox = 'X'.
    WHEN 'LOEKZ'.
      gs_fcat-coltext  = '미사용'.
      gs_fcat-checkbox = 'X'.
    WHEN 'EBELN'.
      gs_fcat-coltext = '구매오더'.
    WHEN 'EBELP'.
      gs_fcat-coltext = '품목번호'.
    WHEN 'BEDAT'.
      gs_fcat-coltext = '발주일'.
    WHEN 'STATU_TEXT'.
      gs_fcat-coltext = '구매오더 상태'.
  ENDCASE.

*-- ALV 별 개별 속성
  CASE pv_flag.

    WHEN 'L'.   " PIR 목록
      IF pv_field = 'INFNR'.
        gs_fcat-hotspot = 'X'.   "*-- 핫스팟 → 클릭 시 단가/PO 이력 표시
      ENDIF.
      IF pv_field = 'LOEKZ'.
        gs_fcat-edit = 'X'.      "*-- 체크박스 직접 클릭 → 미사용 토글
      ENDIF.
      APPEND gs_fcat TO gt_fcat_list.

    WHEN 'P'.   " 단가 입력/이력
*--   편집 후보 컬럼 (실제 편집 허용은 celltab 으로 행별 제어)
      CASE pv_field.
        WHEN 'VALID_FROM' OR 'VALID_TO'
          OR 'EKORG' OR 'WERKS'
          OR 'NETPR' OR 'PEINH' OR 'WAERS'
          OR 'MINBM' OR 'NORBM' OR 'MEINS'
          OR 'APLFZ'.
          gs_fcat-edit = 'X'.
      ENDCASE.
      APPEND gs_fcat TO gt_fcat_price.

    WHEN 'O'.   " NB PO 이력
      APPEND gs_fcat TO gt_fcat_po.

  ENDCASE.

  CLEAR gs_fcat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_display
*&---------------------------------------------------------------------*
FORM create_display .

*-- PIR 목록 (좌측)
  CALL METHOD go_list_alv->set_table_for_first_display
    EXPORTING
      is_variant           = gs_variant
      i_save               = 'A'
      is_layout            = gs_layo_list
      it_toolbar_excluding = gt_toolbar
    CHANGING
      it_outtab            = gt_list
      it_fieldcatalog      = gt_fcat_list.

*-- NB PO 이력 (우하단)
  CALL METHOD go_po_alv->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layo_po
    CHANGING
      it_outtab       = gt_po
      it_fieldcatalog = gt_fcat_po.

*-- 단가 입력/이력 (우상단)
  CALL METHOD go_price_alv->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layo_price
    CHANGING
      it_outtab       = gt_price
      it_fieldcatalog = gt_fcat_price.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*-- PIR 목록 조회 (헤더 + 자재명 + 벤더명/계약일 + 현재 유효 단가)
*-- 유효 단가 판정: VALID_FROM <= sy-datum AND VALID_TO >= sy-datum
*&---------------------------------------------------------------------*
FORM get_data .

  DATA lv_maktx TYPE ztc1mm0001-maktx.

  CLEAR gt_list.

  IF gs_head-maktx IS NOT INITIAL.
    lv_maktx = |%{ gs_head-maktx }%|.
  ENDIF.

*-- 1) PIR 헤더 + 자재명 + 벤더명
  SELECT a~infnr, a~matnr, a~lifnr, a~loekz,
         a~ernam, a~erdat, a~aenam, a~aedat,
         c~maktx,
         d~name1,
         d~kdatb AS vkdatb,
         d~kdate AS vkdate
    FROM ztc1mm0021 AS a
    LEFT JOIN ztc1mm0001 AS c ON c~matnr = a~matnr
    LEFT JOIN ztc1mm0012 AS d ON d~lifnr = a~lifnr
   WHERE ( @gs_head-infnr IS INITIAL OR a~infnr =    @gs_head-infnr )
     AND ( @gs_head-matnr IS INITIAL OR a~matnr =    @gs_head-matnr )
     AND ( @gs_head-lifnr IS INITIAL OR a~lifnr =    @gs_head-lifnr )
     AND ( @gs_head-maktx IS INITIAL OR c~maktx LIKE @lv_maktx     )
    INTO CORRESPONDING FIELDS OF TABLE @gt_list.

  CHECK gt_list IS NOT INITIAL.

  SORT gt_list BY matnr lifnr.

*-- 2) 현재 유효 단가(미삭제): VALID_FROM <= 오늘 AND VALID_TO >= 오늘
*--    복수 유효 단가 존재 시 VALID_FROM 최신 우선
  SELECT infnr, valid_from, valid_to, netpr, waers
    FROM ztc1mm0022
    FOR ALL ENTRIES IN @gt_list
   WHERE infnr      =  @gt_list-infnr
     AND loekz      =  @space
     AND valid_from <= @sy-datum
     AND valid_to   >= @sy-datum
    INTO TABLE @DATA(lt_price).

  SORT lt_price BY infnr valid_from DESCENDING.

*-- 3) 단가 보강 + 상태 판정
*--    계약시작일/종료일 = PIR 단가 유효기간(VALID_FROM/TO) 기준
  LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<l>).

    READ TABLE lt_price INTO DATA(ls_p) WITH KEY infnr = <l>-infnr.
    IF sy-subrc = 0.
      <l>-has_price = 'X'.
      <l>-netpr     = ls_p-netpr.
      <l>-waers     = ls_p-waers.
      <l>-vkdatb    = ls_p-valid_from.   "*-- PIR 단가 시작일 → 계약시작일
      <l>-vkdate    = ls_p-valid_to.     "*-- PIR 단가 종료일 → 계약종료일
    ELSE.
      CLEAR <l>-has_price.
    ENDIF.

    PERFORM apply_list_status CHANGING <l>.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form apply_list_status
*&---------------------------------------------------------------------*
*-- PIR 목록 행의 상태 LED / 행색 / 계약일 표시 결정
*--   판정 기준 : 유효 단가(has_price) + 벤더 계약기간(vkdatb~vkdate)
*--   ※ 단가 없는 자재는 벤더 계약이 살아있어도 '미계약' 으로 처리
*--   계약시작/종료일은 '계약중' 인 행에만 표시 (그 외는 공란)
*&---------------------------------------------------------------------*
FORM apply_list_status CHANGING cs_list LIKE gs_list.

  CLEAR : cs_list-status_icon, cs_list-linecolor,
          cs_list-kdatb, cs_list-kdate.

*-- 미사용
  IF cs_list-loekz = 'X'.
    cs_list-status_icon = icon_led_inactive.
    RETURN.
  ENDIF.

*-- 현재 유효 단가 없음 → 미계약
  IF cs_list-has_price IS INITIAL.
    cs_list-status_icon = icon_led_inactive.
    RETURN.
  ENDIF.

*-- 벤더 계약기간 정보 없음 → 미계약
  IF cs_list-vkdatb IS INITIAL OR cs_list-vkdate IS INITIAL.
    cs_list-status_icon = icon_led_inactive.
    RETURN.
  ENDIF.

*-- 계약기간 판정
  IF cs_list-vkdatb <= sy-datum AND cs_list-vkdate >= sy-datum.

*--   계약중 → 계약일 표시 + 행색 부여
    cs_list-kdatb = cs_list-vkdatb.
    cs_list-kdate = cs_list-vkdate.

    IF ( cs_list-vkdate - sy-datum ) <= 30.
      cs_list-status_icon = icon_led_yellow.   "*-- 만료임박
      cs_list-linecolor   = 'C300'.
    ELSE.
      cs_list-status_icon = icon_led_green.    "*-- 계약중
      cs_list-linecolor   = 'C500'.
    ENDIF.

  ELSEIF sy-datum < cs_list-vkdatb.
    cs_list-status_icon = icon_led_inactive.   "*-- 계약예정 (아직 미계약)

  ELSE.
    cs_list-status_icon = icon_led_red.        "*-- 만료
    cs_list-linecolor   = 'C600'.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_data_changed
*&---------------------------------------------------------------------*
*-- 목록 ALV LOEKZ 체크박스 변경 → 즉시 DB 반영
*&---------------------------------------------------------------------*
FORM handle_data_changed USING pt_good TYPE lvc_t_modi.

  DATA : ls_mod   TYPE lvc_s_modi,
         lv_loekz TYPE ztc1mm0021-loekz,
         lv_chg   TYPE abap_bool.

  LOOP AT pt_good INTO ls_mod WHERE fieldname = 'LOEKZ'.

    READ TABLE gt_list ASSIGNING FIELD-SYMBOL(<l>) INDEX ls_mod-row_id.
    CHECK sy-subrc = 0.

*--   data_changed_finished 시점 : 내부테이블에 이미 반영됨
    lv_loekz = <l>-loekz.

    UPDATE ztc1mm0021
       SET loekz = @lv_loekz,
           aenam = @sy-uname,
           aedat = @sy-datum,
           aezet = @sy-uzeit
     WHERE infnr = @<l>-infnr.

    UPDATE ztc1mm0022
       SET loekz = @lv_loekz
     WHERE infnr = @<l>-infnr.

*--   상태 LED / 행색 재계산
    PERFORM apply_list_status CHANGING <l>.

    lv_chg = abap_true.

  ENDLOOP.

  IF lv_chg = abap_true.
    COMMIT WORK.
    PERFORM refresh_table USING go_list_alv.
    MESSAGE '미사용 상태가 변경되었습니다' TYPE 'S'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_hotspot_click
*&---------------------------------------------------------------------*
*-- INFNR 클릭 → 단가 이력 + NB PO 이력 + 상세영역 펼치기
*&---------------------------------------------------------------------*
FORM handle_hotspot_click USING ps_row TYPE lvc_s_row
                                ps_col TYPE lvc_s_col.

  DATA ls_list LIKE gs_list.

  CHECK ps_col-fieldname = 'INFNR'.

  READ TABLE gt_list INTO ls_list INDEX ps_row-index.
  CHECK sy-subrc = 0.

  gv_sel_infnr = ls_list-infnr.

  PERFORM expand_detail.
  PERFORM set_detail_title   USING ls_list.
  PERFORM get_detail.
  PERFORM get_po_list.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_detail_title
*&---------------------------------------------------------------------*
*-- 우측 단가/PO ALV grid title 에 선택 PIR 정보 표시
*&---------------------------------------------------------------------*
FORM set_detail_title USING ps_list LIKE gs_list.

  gs_layo_price-grid_title = |[ { ps_list-infnr } ] { ps_list-maktx } 단가 이력|.
  gs_layo_po-grid_title    = |[ { ps_list-infnr } ] { ps_list-maktx } 구매오더 이력 (일반발주)|.
  gs_layo_price-smalltitle = abap_true.
  gs_layo_po-smalltitle    = abap_true.

  CALL METHOD go_price_alv->set_frontend_layout
    EXPORTING
      is_layout = gs_layo_price.

  CALL METHOD go_po_alv->set_frontend_layout
    EXPORTING
      is_layout = gs_layo_po.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form clear_detail_title
*&---------------------------------------------------------------------*
*-- 우측 단가/PO ALV grid title 제거 (초기화 / 재검색 시)
*&---------------------------------------------------------------------*
FORM clear_detail_title .

  CLEAR : gs_layo_price-grid_title,
          gs_layo_po-grid_title.

  CALL METHOD go_price_alv->set_frontend_layout
    EXPORTING
      is_layout = gs_layo_price.

  CALL METHOD go_po_alv->set_frontend_layout
    EXPORTING
      is_layout = gs_layo_po.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form expand_detail
*&---------------------------------------------------------------------*
*-- 우측 상세영역 펼치기 (좌 45 / 우 55)
*&---------------------------------------------------------------------*
FORM expand_detail .

  CHECK gv_detail_open IS INITIAL.

  CALL METHOD go_splitter->set_column_width
    EXPORTING
      id    = 1
      width = 45.

  gv_detail_open = abap_true.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form collapse_detail
*&---------------------------------------------------------------------*
*-- 우측 상세영역 접기 (좌 100 / 우 0)
*&---------------------------------------------------------------------*
FORM collapse_detail .

  IF gv_detail_open IS NOT INITIAL.
    CALL METHOD go_splitter->set_column_width
      EXPORTING
        id    = 1
        width = 100.
    gv_detail_open = abap_false.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_detail
*&---------------------------------------------------------------------*
*-- 선택 PIR 의 단가 이력 조회 (우상단 ALV)
*-- VALID_FROM 내림차순 정렬 (최신 기간 단가가 상단 표시)
*&---------------------------------------------------------------------*
FORM get_detail .

  CLEAR gt_price.
  CHECK gv_sel_infnr IS NOT INITIAL.

*-- 단가 전체 이력 (폐기 포함, VALID_FROM 최신 순)
  SELECT *
    FROM ztc1mm0022
   WHERE infnr = @gv_sel_infnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_price.

  SORT gt_price BY valid_from DESCENDING.

*-- 기존 이력행 편집 불가
  LOOP AT gt_price ASSIGNING FIELD-SYMBOL(<p>).
    CLEAR <p>-flag.
    PERFORM build_celltab USING abap_false CHANGING <p>-celltab.
  ENDLOOP.

  PERFORM refresh_table USING go_price_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_po_list
*&---------------------------------------------------------------------*
*-- 선택 PIR(INFNR)로 생성된 NB PO 이력 조회 (우하단 ALV)
*-- ZAPC(연간계약) 제외 → bsart = 'NB' 일반발주만 표시
*&---------------------------------------------------------------------*
FORM get_po_list .

  CLEAR gt_po.
  CHECK gv_sel_infnr IS NOT INITIAL.

  SELECT b~ebeln, b~ebelp, b~infnr,
         a~lifnr, b~matnr,
         b~menge, b~meins,
         b~netpr, b~peinh, a~waers,
         b~werks, b~lgort,
         a~bedat, a~statu
    FROM ztc1mm0008 AS b
    INNER JOIN ztc1mm0007 AS a ON a~ebeln = b~ebeln
   WHERE b~infnr = @gv_sel_infnr
     AND b~loekz = @space
     AND a~loekz = @space
     AND a~bsart = 'NB'    "*-- ZAPC 제외, 일반발주(NB)만 조회
    INTO CORRESPONDING FIELDS OF TABLE @gt_po.

  SORT gt_po BY ebeln DESCENDING ebelp ASCENDING.

*-- 자재명 보강 + PO상태 한글변환
  IF gt_po IS NOT INITIAL.
    SELECT matnr, maktx
      FROM ztc1mm0001
      FOR ALL ENTRIES IN @gt_po
     WHERE matnr = @gt_po-matnr
      INTO TABLE @DATA(lt_makt).

    LOOP AT gt_po ASSIGNING FIELD-SYMBOL(<o>).
      READ TABLE lt_makt INTO DATA(ls_m) WITH KEY matnr = <o>-matnr.
      IF sy-subrc = 0.
        <o>-maktx = ls_m-maktx.
      ENDIF.
*--   PO 상태 한글 텍스트
      PERFORM conv_po_status USING    <o>-statu
                             CHANGING <o>-statu_text.
    ENDLOOP.
  ENDIF.

  PERFORM refresh_table USING go_po_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form conv_po_status
*&---------------------------------------------------------------------*
*-- PO 상태코드 → 한글 텍스트 (결재 워크플로 매핑)
*&---------------------------------------------------------------------*
FORM conv_po_status USING    pv_statu TYPE ztc1mm0008-statu
                    CHANGING cv_text  TYPE char20.

  CASE pv_statu.
    WHEN 'SV'. cv_text = '결재 대기'.
    WHEN 'PD' OR 'FT'. cv_text = '결재 진행 중'.
    WHEN 'AP'. cv_text = '승인 완료'.
    WHEN 'RJ'. cv_text = '반려'.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form build_celltab
*&---------------------------------------------------------------------*
*-- 단가행 편집 가능 여부 celltab 생성
*&---------------------------------------------------------------------*
FORM build_celltab USING    pv_editable TYPE abap_bool
                   CHANGING ct_celltab  TYPE lvc_t_styl.

  DATA : ls_styl TYPE lvc_s_styl,
         lv_mode TYPE lvc_style.

  CLEAR ct_celltab.

  IF pv_editable = abap_true.
    lv_mode = cl_gui_alv_grid=>mc_style_enabled.
  ELSE.
    lv_mode = cl_gui_alv_grid=>mc_style_disabled.
  ENDIF.

  LOOP AT gt_fcat_price INTO DATA(ls_fc) WHERE edit = 'X'.
    CLEAR ls_styl.
    ls_styl-fieldname = ls_fc-fieldname.
    ls_styl-style     = lv_mode.
    INSERT ls_styl INTO TABLE ct_celltab.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_toolbar_price
*&---------------------------------------------------------------------*
*-- 단가 ALV 툴바 : 단가추가 / 저장 / 초기화
*&---------------------------------------------------------------------*
FORM handle_toolbar_price USING po_object TYPE REF TO cl_alv_event_toolbar_set.

  CLEAR po_object->mt_toolbar.

  CLEAR gs_button.
  gs_button-butn_type = 3.
  APPEND gs_button TO po_object->mt_toolbar.

*-- 상세영역 접기/펼치기 토글
  CLEAR gs_button.
  gs_button-function  = 'FOLD'.
  gs_button-icon      = icon_column_right.
  gs_button-text      = ' 접기 '.
  gs_button-quickinfo = '상세영역 닫기'.
  APPEND gs_button TO po_object->mt_toolbar.

  CLEAR gs_button.
  gs_button-butn_type = 3.
  APPEND gs_button TO po_object->mt_toolbar.

  CLEAR gs_button.
  gs_button-function = 'ADDP'.
  gs_button-icon     = icon_insert_row.
  gs_button-text     = ' 단가추가 '.
  APPEND gs_button TO po_object->mt_toolbar.

  CLEAR gs_button.
  gs_button-function = 'SAVE'.
  gs_button-icon     = icon_system_save.
  gs_button-text     = ' 저장 '.
  APPEND gs_button TO po_object->mt_toolbar.

  CLEAR gs_button.
  gs_button-function = 'RESET'.
  gs_button-icon     = icon_refresh.
  gs_button-text     = ' 초기화 '.
  APPEND gs_button TO po_object->mt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form handle_user_command
*&---------------------------------------------------------------------*
*-- 단가 ALV 툴바 버튼 디스패치
*&---------------------------------------------------------------------*
FORM handle_user_command USING pv_ucomm TYPE sy-ucomm.

  CASE pv_ucomm.
    WHEN 'ADDP'.    PERFORM add_price.     "*-- 기존 PIR 에 단가행 추가
    WHEN 'SAVE'.    PERFORM save_pir.      "*-- 추가 단가행 저장
    WHEN 'RESET'.   PERFORM reset_price.   "*-- 추가행 취소
    WHEN 'FOLD'.    PERFORM collapse_detail.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_table
*&---------------------------------------------------------------------*
FORM refresh_table USING po_alv TYPE REF TO cl_gui_alv_grid.

  DATA ls_stable TYPE lvc_s_stbl.

  CHECK po_alv IS BOUND.

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.

  CALL METHOD po_alv->refresh_table_display
    EXPORTING
      is_stable = ls_stable.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form add_price
*&---------------------------------------------------------------------*
*-- 기존 PIR 에 단가행 1줄 추가 (편집 가능 행)
*-- 신규행 기본값: VALID_FROM = 오늘, VALID_TO = 9999.12.31
*&---------------------------------------------------------------------*
FORM add_price .

  DATA ls_price LIKE gs_price.

  IF gv_sel_infnr IS INITIAL.
    MESSAGE '먼저 구매정보레코드를 선택하세요' TYPE 'I'.
    RETURN.
  ENDIF.

  CALL METHOD go_price_alv->check_changed_data.

  CLEAR ls_price.
  ls_price-mandt      = sy-mandt.
  ls_price-infnr      = gv_sel_infnr.
  ls_price-ekorg      = 'P100'.
  ls_price-werks      = 'TS00'.
  ls_price-valid_from = sy-datum.          "*-- 오늘부터
  ls_price-valid_to   = '99991231'.        "*-- 기본 무기한
  ls_price-waers      = 'KRW'.
  ls_price-meins      = 'EA'.
  ls_price-peinh      = 1.
  ls_price-aplfz      = 7.
  ls_price-webre      = 'X'.
  ls_price-flag       = 'N'.

  PERFORM build_celltab USING abap_true CHANGING ls_price-celltab.

  INSERT ls_price INTO gt_price INDEX 1.

  PERFORM refresh_table USING go_price_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_pir
*&---------------------------------------------------------------------*
*-- 선택 PIR 에 추가한 단가행 저장
*-- 키: INFNR + VALID_FROM → 동일 기간 중복 시 INSERT 에러로 차단
*&---------------------------------------------------------------------*
FORM save_pir .

  DATA : ls_item TYPE ztc1mm0022,
         lt_ins  TYPE TABLE OF ztc1mm0022,
         lt_new  LIKE gt_price.

  IF gv_sel_infnr IS INITIAL.
    MESSAGE '먼저 구매정보레코드를 선택하세요' TYPE 'I'.
    RETURN.
  ENDIF.

  CALL METHOD go_price_alv->check_changed_data.

*-- 신규 입력행만 추출
  LOOP AT gt_price INTO gs_price WHERE flag = 'N'.
    APPEND gs_price TO lt_new.
  ENDLOOP.

  IF lt_new IS INITIAL.
    MESSAGE '저장할 단가 행이 없습니다' TYPE 'I'.
    RETURN.
  ENDIF.

*-- 필수값 검증
  LOOP AT lt_new INTO gs_price.

    IF gs_price-ekorg IS INITIAL OR gs_price-werks IS INITIAL.
      MESSAGE '구매조직/플랜트는 필수입니다' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF gs_price-valid_from IS INITIAL.
      MESSAGE '단가 시작일(VALID_FROM)은 필수입니다' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF gs_price-valid_to IS INITIAL.
      MESSAGE '단가 종료일(VALID_TO)은 필수입니다' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

*--   시작일 > 종료일 방지
    IF gs_price-valid_from > gs_price-valid_to.
      MESSAGE '단가 시작일이 종료일보다 늦습니다' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF gs_price-netpr <= 0 OR gs_price-waers IS INITIAL.
      MESSAGE '단가와 통화는 필수입니다' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

  ENDLOOP.

*-- 단가행 INSERT (INFNR+VALID_FROM 중복 시 DB 레벨 에러)
  LOOP AT lt_new INTO gs_price.
    CLEAR ls_item.
    MOVE-CORRESPONDING gs_price TO ls_item.
    ls_item-mandt = sy-mandt.
    ls_item-infnr = gv_sel_infnr.
    ls_item-webre = 'X'.
    ls_item-loekz = space.
    ls_item-ernam = sy-uname.
    ls_item-erdat = sy-datum.
    ls_item-erzet = sy-uzeit.
    APPEND ls_item TO lt_ins.
  ENDLOOP.

  INSERT ztc1mm0022 FROM TABLE lt_ins.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE '단가 저장 실패 (동일 시작일 단가 중복 확인)' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  UPDATE ztc1mm0021
     SET aenam = @sy-uname,
         aedat = @sy-datum,
         aezet = @sy-uzeit
   WHERE infnr = @gv_sel_infnr.

  COMMIT WORK.

  PERFORM get_data.
  PERFORM refresh_table USING go_list_alv.
  PERFORM get_detail.

  MESSAGE '단가가 저장되었습니다' TYPE 'S'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form reset_price
*&---------------------------------------------------------------------*
*-- 단가 추가행 취소 (신규행만 제거)
*&---------------------------------------------------------------------*
FORM reset_price .

  DELETE gt_price WHERE flag = 'N'.

  PERFORM refresh_table USING go_price_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form search_data
*&---------------------------------------------------------------------*
*-- 조회 : 헤더 조회조건으로 PIR 목록 조회 + 상세영역 접기
*&---------------------------------------------------------------------*
FORM search_data .

  CLEAR : gt_price, gt_po, gv_sel_infnr.

  PERFORM get_data.

*-- 우측 상세영역 접기 + grid title 제거
  PERFORM collapse_detail.
  PERFORM clear_detail_title.

  PERFORM refresh_table USING go_list_alv.
  PERFORM refresh_table USING go_price_alv.
  PERFORM refresh_table USING go_po_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form clear_search
*&---------------------------------------------------------------------*
*-- 초기화 : 조회조건 + 우측 영역 비우고 전체 재조회 + 상세영역 접기
*&---------------------------------------------------------------------*
FORM clear_search .

  CLEAR : gs_head, gt_price, gt_po, gv_sel_infnr.

  PERFORM get_data.

*-- 우측 상세영역 접기 + grid title 제거
  PERFORM collapse_detail.
  PERFORM clear_detail_title.

  PERFORM refresh_table USING go_list_alv.
  PERFORM refresh_table USING go_price_alv.
  PERFORM refresh_table USING go_po_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form new_pir
*&---------------------------------------------------------------------*
*-- 신규 PIR 생성 팝업(화면 0200) 호출
*&---------------------------------------------------------------------*
FORM new_pir .

*-- 팝업 초기값
  CLEAR gs_pop.
  gs_pop-ekorg     = 'P100'.
  gs_pop-werks     = 'TS00'.
  gs_pop-plan_year = sy-datum(4).   "*-- 올해 연도 기본값
  gs_pop-waers     = 'KRW'.
  gs_pop-meins     = 'EA'.
  gs_pop-peinh     = 1.
  gs_pop-aplfz     = 7.
  gs_pop-webre     = 'X'.

  CALL SCREEN 0200 STARTING AT 35 4 ENDING AT 90 22.

*-- 팝업 닫힌 후 목록 갱신
  PERFORM get_data.
  PERFORM refresh_table USING go_list_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_new_pir
*&---------------------------------------------------------------------*
*-- 팝업 : 신규 PIR 생성 + 단가 등록 + ZAPC PO 자동 생성
*--
*-- 저장 흐름:
*--  1) 등록연도 기준 VALID_FROM/TO 자동 계산 (벤더 계약기간 교차 보정)
*--     예) 2026 입력, 계약 2025.01.01~2027.04.30
*--         → valid_from = 2026.01.01 / valid_to = 2026.12.31
*--  2) 중복체크 : 자재 + 벤더 + 기간 기준 (연도별 복수 생성 가능)
*--  3) ZTC1MM0021 PIR 헤더 INSERT
*--  4) ZTC1MM0022 단가 INSERT
*--  5) ZTC1MM0007 ZAPC PO 헤더 INSERT (연간계약 대표 헤더)
*--  6) ZTC1MM0008 ZAPC PO 품목 INSERT (연간계획수량 + PIR 연결)
*&---------------------------------------------------------------------*
FORM save_new_pir .

  DATA : ls_head   TYPE ztc1mm0021,
         ls_item   TYPE ztc1mm0022,
         ls_po_hdr TYPE ztc1mm0007,
         ls_po_itm TYPE ztc1mm0008,
         lv_infnr  TYPE ztc1mm0021-infnr,
         lv_ebeln  TYPE ztc1mm0007-ebeln,
         lv_chk    TYPE ztc1mm0021-infnr,
         lv_year   TYPE c LENGTH 4.

*-- 필수값 검증
  IF gs_pop-matnr IS INITIAL OR gs_pop-lifnr IS INITIAL.
    MESSAGE '자재번호와 벤더는 필수입니다' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_pop-kdatb IS INITIAL OR gs_pop-kdate IS INITIAL.
    MESSAGE '선택한 벤더에 계약기간이 없습니다. 벤더마스터를 확인하세요' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_pop-plan_year IS INITIAL.
    MESSAGE '등록연도를 입력하세요' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_pop-ekorg IS INITIAL OR gs_pop-werks IS INITIAL.
    MESSAGE '구매조직/플랜트는 필수입니다' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_pop-netpr <= 0 OR gs_pop-waers IS INITIAL
    OR gs_pop-peinh <= 0 OR gs_pop-meins IS INITIAL.
    MESSAGE '단가/통화/가격단위/단위는 필수입니다' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_pop-plan_menge <= 0 OR gs_pop-norbm <= 0
    OR gs_pop-minbm <= 0 OR gs_pop-aplfz <= 0.
    MESSAGE '수량/리드타임은 0보다 커야 합니다' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 등록연도 기준 VALID_FROM / VALID_TO 자동 계산 (공용 FORM)
  PERFORM calc_valid_period.

*-- 계약기간 밖 → 기간 미계산 → 차단
  IF gs_pop-valid_from IS INITIAL OR gs_pop-valid_to IS INITIAL.
    MESSAGE |적용연도 { gs_pop-plan_year }이 벤더 계약기간({ gs_pop-kdatb+0(4) }.{ gs_pop-kdatb+4(2) }.|
         && |{ gs_pop-kdatb+6(2) } ~ { gs_pop-kdate+0(4) }.{ gs_pop-kdate+4(2) }.{ gs_pop-kdate+6(2) }) 밖입니다| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- 중복체크 : 자재 + 벤더 + 기간 기준
*-- 같은 자재/벤더라도 연도가 다르면 별도 PIR 생성 가능
  SELECT SINGLE a~infnr
    FROM ztc1mm0021 AS a
    INNER JOIN ztc1mm0022 AS b ON b~infnr = a~infnr
   WHERE a~matnr      = @gs_pop-matnr
     AND a~lifnr      = @gs_pop-lifnr
     AND a~loekz      = @space
     AND b~loekz      = @space
     AND b~valid_from = @gs_pop-valid_from
     AND b~valid_to   = @gs_pop-valid_to
    INTO @lv_chk.

  IF sy-subrc = 0.
    MESSAGE |{ gs_pop-plan_year }년도 해당 자재+벤더 PIR이 이미 존재합니다 ({ lv_chk })| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- PIR 채번
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = 'PI'
      object                  = 'ZNRC1MM01'
    IMPORTING
      number                  = lv_infnr
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0 OR lv_infnr IS INITIAL.
    MESSAGE 'PIR 번호 채번 실패' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- ZTC1MM0021 PIR 헤더 INSERT
  CLEAR ls_head.
  ls_head-mandt = sy-mandt.
  ls_head-infnr = lv_infnr.
  ls_head-matnr = gs_pop-matnr.
  ls_head-lifnr = gs_pop-lifnr.
  ls_head-loekz = space.
  ls_head-ernam = sy-uname.
  ls_head-erdat = sy-datum.
  ls_head-erzet = sy-uzeit.

  INSERT ztc1mm0021 FROM ls_head.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'PIR 헤더 저장 실패' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- ZTC1MM0022 단가 INSERT
  CLEAR ls_item.
  MOVE-CORRESPONDING gs_pop TO ls_item.
  ls_item-mandt        = sy-mandt.
  ls_item-infnr        = lv_infnr.
  ls_item-valid_from   = gs_pop-valid_from.
  ls_item-valid_to     = gs_pop-valid_to.
  ls_item-contract_flg = 'X'.          "*-- 계약 단가
  ls_item-webre        = 'X'.
  ls_item-loekz        = space.
  ls_item-ernam        = sy-uname.
  ls_item-erdat        = sy-datum.
  ls_item-erzet        = sy-uzeit.

  INSERT ztc1mm0022 FROM ls_item.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'PIR 단가 저장 실패' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- ZAPC PO 채번
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = 'ZP'
      object                  = 'ZNRC1MM01'
    IMPORTING
      number                  = lv_ebeln
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0 OR lv_ebeln IS INITIAL.
    ROLLBACK WORK.
    MESSAGE 'ZAPC PO 번호 채번 실패' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- ZTC1MM0007 ZAPC PO 헤더 INSERT
*-- 연간계약 대표 헤더. KDATB/KDATE = 해당연도 기간
  CLEAR ls_po_hdr.
  ls_po_hdr-mandt = sy-mandt.
  ls_po_hdr-ebeln = lv_ebeln.
  ls_po_hdr-bsart = 'ZAPC'.
  ls_po_hdr-bukrs = '1000'.
  ls_po_hdr-bstyp = 'K'.                    "*-- 계약 유형
  ls_po_hdr-lifnr = gs_pop-lifnr.
  ls_po_hdr-werks = gs_pop-werks.
  ls_po_hdr-bedat = sy-datum.
  ls_po_hdr-kdatb = gs_pop-valid_from.      "*-- 해당연도 시작일
  ls_po_hdr-kdate = gs_pop-valid_to.        "*-- 해당연도 종료일
  ls_po_hdr-waers = gs_pop-waers.
  ls_po_hdr-wkurs = 1.
  ls_po_hdr-statu = 'AP'.                   "*-- 연간계약은 바로 승인
  ls_po_hdr-frgkz = 'X'.                    "*-- 릴리스
  ls_po_hdr-bigo  = |{ gs_pop-plan_year }년 { gs_pop-maktx } 연간 계약|.

  INSERT ztc1mm0007 FROM ls_po_hdr.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'ZAPC PO 헤더 저장 실패' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*-- ZTC1MM0008 ZAPC PO 품목 INSERT
*-- 연간계획수량(plan_menge) + PIR(INFNR) 연결
  CLEAR ls_po_itm.
  ls_po_itm-mandt = sy-mandt.
  ls_po_itm-ebeln = lv_ebeln.
  ls_po_itm-ebelp = '00010'.
  ls_po_itm-matnr = gs_pop-matnr.
  ls_po_itm-menge = gs_pop-plan_menge.      "*-- 연간계획수량
  ls_po_itm-meins = gs_pop-meins.
  ls_po_itm-werks = gs_pop-werks.
  ls_po_itm-lgort = 'SL10'.
  ls_po_itm-pstyp = '0'.
  ls_po_itm-netpr = gs_pop-netpr.
  ls_po_itm-waers = gs_pop-waers.
  ls_po_itm-peinh = gs_pop-peinh.
  ls_po_itm-infnr = lv_infnr.              "*-- PIR 연결
  ls_po_itm-statu = 'AP'.
  ls_po_itm-loekz = space.

  INSERT ztc1mm0008 FROM ls_po_itm.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'ZAPC PO 품목 저장 실패' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  COMMIT WORK AND WAIT.

  MESSAGE |PIR { lv_infnr } / ZAPC PO { lv_ebeln } 생성 완료 ({ gs_pop-plan_year }년 { gs_pop-maktx })| TYPE 'S'.

  LEAVE TO SCREEN 0.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_pop_matnr
*&---------------------------------------------------------------------*
*-- 팝업 자재 F4 : ROH(원자재) 기준 조회
*&---------------------------------------------------------------------*
FORM f4_pop_matnr .

  DATA : lt_return TYPE TABLE OF ddshretval,
         ls_return TYPE ddshretval,
         lt_read   TYPE TABLE OF dynpread,
         ls_read   TYPE dynpread.

  SELECT matnr, maktx
    FROM ztc1mm0001
   WHERE mtart = 'ROH'
    INTO TABLE @gt_sh_matnr.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'MATNR'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'GS_POP-MATNR'
      window_title    = '자재 선택'
      value_org       = 'S'
    TABLES
      value_tab       = gt_sh_matnr
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  CHECK sy-subrc = 0.

  READ TABLE lt_return INTO ls_return INDEX 1.
  CHECK sy-subrc = 0.

  gs_pop-matnr = ls_return-fieldval.

  SELECT SINGLE maktx
    FROM ztc1mm0001
   WHERE matnr = @gs_pop-matnr
    INTO @gs_pop-maktx.

  ls_read-fieldname  = 'GS_POP-MATNR'.
  ls_read-fieldvalue = gs_pop-matnr.
  APPEND ls_read TO lt_read.

  CLEAR ls_read.
  ls_read-fieldname  = 'GS_POP-MAKTX'.
  ls_read-fieldvalue = gs_pop-maktx.
  APPEND ls_read TO lt_read.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_read.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_pop_lifnr
*&---------------------------------------------------------------------*
*-- 팝업 벤더 F4 : 선택 시 계약시작/종료일을 벤더마스터에서 자동 세팅
*&---------------------------------------------------------------------*
FORM f4_pop_lifnr .

  DATA : lt_return TYPE TABLE OF ddshretval,
         ls_return TYPE ddshretval,
         lt_read   TYPE TABLE OF dynpread,
         ls_read   TYPE dynpread.

  SELECT lifnr, name1, kdatb, kdate
    FROM ztc1mm0012
    INTO TABLE @gt_sh_lifnr.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'LIFNR'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'GS_POP-LIFNR'
      window_title    = '벤더 선택'
      value_org       = 'S'
    TABLES
      value_tab       = gt_sh_lifnr
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  CHECK sy-subrc = 0.

  READ TABLE lt_return INTO ls_return INDEX 1.
  CHECK sy-subrc = 0.

  gs_pop-lifnr = ls_return-fieldval.

*-- 벤더 계약기간 자동 세팅 (벤더마스터 kdatb/kdate)
  CLEAR : gs_pop-name1, gs_pop-kdatb, gs_pop-kdate.

  SELECT SINGLE name1, kdatb, kdate
    FROM ztc1mm0012
   WHERE lifnr = @gs_pop-lifnr
    INTO ( @gs_pop-name1, @gs_pop-kdatb, @gs_pop-kdate ).

  ls_read-fieldname  = 'GS_POP-LIFNR'.
  ls_read-fieldvalue = gs_pop-lifnr.
  APPEND ls_read TO lt_read.

  CLEAR ls_read.
  ls_read-fieldname  = 'GS_POP-NAME1'.
  ls_read-fieldvalue = gs_pop-name1.
  APPEND ls_read TO lt_read.

  CLEAR ls_read.
  ls_read-fieldname  = 'GS_POP-KDATB'.
  ls_read-fieldvalue = gs_pop-kdatb.
  APPEND ls_read TO lt_read.

  CLEAR ls_read.
  ls_read-fieldname  = 'GS_POP-KDATE'.
  ls_read-fieldvalue = gs_pop-kdate.
  APPEND ls_read TO lt_read.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_read.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form toolbar_exclude
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM toolbar_exclude .

  CLEAR : gt_toolbar.

  APPEND :   cl_gui_alv_grid=>mc_fc_loc_insert_row TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_delete_row TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_append_row TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_copy_row   TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_cut        TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_copy       TO gt_toolbar,
             cl_gui_alv_grid=>mc_mb_paste          TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_check          TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_refresh        TO gt_toolbar,
             cl_gui_alv_grid=>mc_fc_loc_undo       TO gt_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_valid_period
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM calc_valid_period .

  DATA : lv_year TYPE c LENGTH 4,
         lv_from TYPE ztc1mm0022-valid_from,
         lv_to   TYPE ztc1mm0022-valid_to.

  CLEAR : gs_pop-valid_from, gs_pop-valid_to.

*-- 적용연도 또는 벤더 계약기간 미입력 시 계산 안 함
  IF gs_pop-plan_year IS INITIAL.
    RETURN.
  ENDIF.
  IF gs_pop-kdatb IS INITIAL OR gs_pop-kdate IS INITIAL.
    RETURN.
  ENDIF.

*-- 과거연도 차단 : 현재연도보다 이전이면 기간 비움
  IF gs_pop-plan_year < sy-datum(4).
    CLEAR : gs_pop-valid_from, gs_pop-valid_to.
    RETURN.
  ENDIF.

  lv_year = gs_pop-plan_year.

*-- 해당 연도 전체기간 (1/1 ~ 12/31)
  lv_from = lv_year && '0101'.
  lv_to   = lv_year && '1231'.

*-- 해당 연도가 벤더 계약기간을 벗어나면 차단 (기간 비움)
  IF lv_from < gs_pop-kdatb OR lv_to > gs_pop-kdate.
    CLEAR : gs_pop-valid_from, gs_pop-valid_to.
    RETURN.
  ENDIF.

*-- 계약기간 내 → 그대로 세팅
  gs_pop-valid_from = lv_from.
  gs_pop-valid_to   = lv_to.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_html_header
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_html_header .

  IF go_html_dock IS NOT BOUND.

    CREATE OBJECT go_html_dock
      EXPORTING
        side      = cl_gui_docking_container=>dock_at_top
        extension = 35.

  ENDIF.

  IF go_html_header IS NOT BOUND.

    CREATE OBJECT go_html_header
      EXPORTING
        io_parent = go_html_dock.

  ENDIF.

  go_html_header->display(
     EXPORTING
       iv_module_tag   = |MM|
       iv_module_full  = |MM - Materials Management|
       iv_program_name = |구매정보레코드 관리 프로그램!|
       iv_program_desc = |구매정보레코드 등록과 단가·발주 이력을 통합 관리하는 프로그램입니다|
       iv_program_id   = |{ sy-repid }|
       iv_system_info  = |{ sy-sysid } / { sy-mandt }|
       iv_user_id      = |{ sy-uname }|
       iv_user_name    = |{ sy-uname }|
   ).

ENDFORM.
