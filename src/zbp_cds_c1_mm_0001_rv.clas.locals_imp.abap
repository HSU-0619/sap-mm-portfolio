CLASS lhc_poapproval DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR PoApproval
      RESULT result.

    METHODS approve FOR MODIFY
      IMPORTING keys FOR ACTION poapproval~approve RESULT result.

    METHODS reject FOR MODIFY
      IMPORTING keys FOR ACTION poapproval~reject RESULT result.

    METHODS insert_log
      IMPORTING iv_ebeln  TYPE ztc1mm0007-ebeln
                iv_action TYPE ztc1mm0027-action
                iv_cmt    TYPE ztc1mm0027-appr_comment.

    METHODS check_grade
      IMPORTING iv_statu        TYPE ztc1mm0007-statu
      RETURNING VALUE(rv_allow) TYPE abap_bool.

ENDCLASS.


CLASS lhc_poapproval IMPLEMENTATION.

  METHOD get_global_authorizations.

    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = if_abap_behv=>auth-allowed.
    ENDIF.

    IF requested_authorizations-%action-approve = if_abap_behv=>mk-on.
      result-%action-approve = if_abap_behv=>auth-allowed.
    ENDIF.

    IF requested_authorizations-%action-reject = if_abap_behv=>mk-on.
      result-%action-reject = if_abap_behv=>auth-allowed.
    ENDIF.

  ENDMETHOD.

  METHOD approve.

    LOOP AT keys INTO DATA(ls_key).

      SELECT SINGLE statu
        FROM ztc1mm0007
       WHERE ebeln = @ls_key-ebeln
        INTO @DATA(lv_stat).

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |PO { ls_key-ebeln }를 찾을 수 없습니다| ) )
          TO reported-poapproval.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-poapproval.
        CONTINUE.
      ENDIF.

      IF lv_stat <> 'FT' AND lv_stat <> 'PD'.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |{ lv_stat } 상태는 승인할 수 없습니다| ) )
          TO reported-poapproval.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-poapproval.
        CONTINUE.
      ENDIF.

      IF check_grade( lv_stat ) = abap_false.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |{ lv_stat } 승인 권한이 없습니다| ) )
          TO reported-poapproval.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-poapproval.
        CONTINUE.
      ENDIF.

      MODIFY ENTITIES OF zcds_c1_mm_0001_rv IN LOCAL MODE
        ENTITY PoApproval
          UPDATE FIELDS ( Statu Aedat )
          WITH VALUE #(
            ( %tky  = ls_key-%tky
              Statu = 'AP'
              Aedat = sy-datum )
          )
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).

      IF lt_failed-poapproval IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-poapproval.
        CONTINUE.
      ENDIF.

*--- 품목(8번) 상태 동기화 : 승인
      UPDATE ztc1mm0008 SET statu = 'AP'
       WHERE ebeln = @ls_key-ebeln.

      insert_log(
        iv_ebeln  = ls_key-ebeln
        iv_action = 'AP'
        iv_cmt    = |{ lv_stat } 승인|
      ).

    ENDLOOP.

    READ ENTITIES OF zcds_c1_mm_0001_rv IN LOCAL MODE
      ENTITY PoApproval
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls_result IN lt_result
      ( %tky   = ls_result-%tky
        %param = ls_result )
    ).

  ENDMETHOD.


  METHOD reject.

    LOOP AT keys INTO DATA(ls_key).

      DATA(lv_bigo) = ls_key-%param-bigo.

      IF lv_bigo IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |반려 사유를 입력하세요| ) )
          TO reported-poapproval.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-poapproval.
        CONTINUE.
      ENDIF.

      SELECT SINGLE statu
        FROM ztc1mm0007
       WHERE ebeln = @ls_key-ebeln
        INTO @DATA(lv_stat).

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |PO { ls_key-ebeln }를 찾을 수 없습니다| ) )
          TO reported-poapproval.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-poapproval.
        CONTINUE.
      ENDIF.

      IF lv_stat <> 'FT' AND lv_stat <> 'PD'.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |{ lv_stat } 상태는 반려할 수 없습니다| ) )
          TO reported-poapproval.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-poapproval.
        CONTINUE.
      ENDIF.

      IF check_grade( lv_stat ) = abap_false.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |{ lv_stat } 반려 권한이 없습니다| ) )
          TO reported-poapproval.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-poapproval.
        CONTINUE.
      ENDIF.

*--- 반려: 헤더 상태만 변경 (BIGO는 구매사유 요약이므로 건드리지 않음)
      MODIFY ENTITIES OF zcds_c1_mm_0001_rv IN LOCAL MODE
        ENTITY PoApproval
          UPDATE FIELDS ( Statu Aedat )
          WITH VALUE #(
            ( %tky  = ls_key-%tky
              Statu = 'RJ'
              Aedat = sy-datum )
          )
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).

      IF lt_failed-poapproval IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-poapproval.
        CONTINUE.
      ENDIF.

*--- 품목(8번) 상태 동기화 : 반려
      UPDATE ztc1mm0008 SET statu = 'RJ'
       WHERE ebeln = @ls_key-ebeln.

*--- 반려사유는 결재이력(APPR_COMMENT)에만 저장
      insert_log(
        iv_ebeln  = ls_key-ebeln
        iv_action = 'RJ'
        iv_cmt    = lv_bigo
      ).

    ENDLOOP.

    READ ENTITIES OF zcds_c1_mm_0001_rv IN LOCAL MODE
      ENTITY PoApproval
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls_result IN lt_result
      ( %tky   = ls_result-%tky
        %param = ls_result )
    ).

  ENDMETHOD.


  METHOD insert_log.

    DATA: ls_log TYPE ztc1mm0027,
          lv_max TYPE ztc1mm0027-seqnr,
          ls_hr  TYPE ztc1hr0001.

    SELECT SINGLE *
      FROM ztc1hr0001
     WHERE uname = @sy-uname
      INTO @ls_hr.

    SELECT MAX( seqnr )
      FROM ztc1mm0027
     WHERE ebeln = @iv_ebeln
      INTO @lv_max.

    ls_log-mandt        = sy-mandt.
    ls_log-ebeln        = iv_ebeln.
    ls_log-seqnr        = COND #( WHEN lv_max IS INITIAL THEN 10 ELSE lv_max + 10 ).
    ls_log-astep        = 'APP'.
    ls_log-pernr        = ls_hr-pernr.
    ls_log-uname        = sy-uname.
    ls_log-ename        = ls_hr-ename.
    ls_log-zgrade       = ls_hr-zgrade.
    ls_log-action       = iv_action.
    GET TIME STAMP FIELD ls_log-actdt.
    ls_log-appr_comment = iv_cmt.

    INSERT ztc1mm0027 FROM ls_log.

  ENDMETHOD.


  METHOD check_grade.

    DATA lv_grade TYPE ztc1hr0001-zgrade.

    CLEAR rv_allow.

    SELECT SINGLE zgrade
      FROM ztc1hr0001
     WHERE uname = @sy-uname
      INTO @lv_grade.

    IF sy-subrc <> 0.
      rv_allow = abap_false.
      RETURN.
    ENDIF.

    CASE iv_statu.

      WHEN 'FT'. " 전결
        IF lv_grade = '차장'
        OR lv_grade = '책임'
        OR lv_grade = '부장'.
          rv_allow = abap_true.
        ENDIF.

      WHEN 'PD'. " 일반결재
        IF lv_grade = '부장'.
          rv_allow = abap_true.
        ENDIF.

      WHEN OTHERS.
        rv_allow = abap_false.

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
