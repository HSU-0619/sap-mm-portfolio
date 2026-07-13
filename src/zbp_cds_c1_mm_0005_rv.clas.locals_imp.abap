CLASS lhc_qrhist DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR QrHist
      RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE QrHist.

    METHODS setAdminData FOR DETERMINE ON SAVE
      IMPORTING keys FOR QrHist~setAdminData.

ENDCLASS.

CLASS lhc_qrhist IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA : lv_qrno   TYPE ztc1mm0028-qr_no.
    DATA : ls_entity LIKE LINE OF entities.

    LOOP AT entities INTO ls_entity.

*-- QR번호 채번 (ZNRC1MM02)
      CLEAR lv_qrno.

      CALL FUNCTION 'NUMBER_GET_NEXT'
        EXPORTING
          nr_range_nr             = 'QR'
          object                  = 'ZNRC1MM01'
        IMPORTING
          number                  = lv_qrno
        EXCEPTIONS
          interval_not_found      = 1
          number_range_not_intern = 2
          object_not_found        = 3
          quantity_is_0           = 4
          quantity_is_not_1       = 5
          interval_overflow       = 6
          buffer_overflow         = 7
          OTHERS                  = 8.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

*-- QR 인코딩 문자열 = QR번호만 저장 (URL 미사용)
      APPEND VALUE #( %cid      = ls_entity-%cid
                      QrNo      = lv_qrno )
             TO mapped-qrhist.

    ENDLOOP.

  ENDMETHOD.

  METHOD setAdminData.

    MODIFY ENTITIES OF zcds_c1_mm_0005_rv IN LOCAL MODE
      ENTITY QrHist
        UPDATE FIELDS ( Erdat Ernam QrData )
        WITH VALUE #( FOR ls_key IN keys
                      ( %tky   = ls_key-%tky
                        Erdat  = cl_abap_context_info=>get_system_date( )
                        Ernam  = cl_abap_context_info=>get_user_technical_name( )
                        QrData = |https://61.97.134.34:44300/sap/bc/ui5_ui5/sap/zc1mmqr/index.html#/scan/{ ls_key-QrNo }| ) )
      REPORTED DATA(lt_reported).

  ENDMETHOD.

ENDCLASS.
