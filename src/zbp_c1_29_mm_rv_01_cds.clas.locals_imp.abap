CLASS lhc_header DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR header RESULT result.

    METHODS approve FOR MODIFY
      IMPORTING keys FOR ACTION header~approve RESULT result.

    METHODS reject FOR MODIFY
      IMPORTING keys FOR ACTION header~reject RESULT result.

ENDCLASS.

CLASS lhc_header IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD approve.
    MODIFY ENTITIES OF zc1_29_mm_rv_01_cds IN LOCAL MODE
      ENTITY Header
        UPDATE FIELDS ( Statu )
        WITH VALUE #( FOR k IN keys
                      ( %tky  = k-%tky
                        Statu = 'AP' ) ).

    READ ENTITIES OF zc1_29_mm_rv_01_cds IN LOCAL MODE
      ENTITY Header
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls IN lt_result
                      ( %tky   = ls-%tky
                        %param = ls ) ).
  ENDMETHOD.

  METHOD reject.
    MODIFY ENTITIES OF zc1_29_mm_rv_01_cds IN LOCAL MODE
      ENTITY Header
        UPDATE FIELDS ( Statu Bigo )
        WITH VALUE #( FOR k IN keys
                      ( %tky  = k-%tky
                        Statu = 'RJ'
                        Bigo  = k-%param-bigo ) ).

    READ ENTITIES OF zc1_29_mm_rv_01_cds IN LOCAL MODE
      ENTITY Header
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls IN lt_result
                      ( %tky   = ls-%tky
                        %param = ls ) ).

  ENDMETHOD.

ENDCLASS.
