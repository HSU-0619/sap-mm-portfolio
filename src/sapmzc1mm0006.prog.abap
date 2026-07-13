*&---------------------------------------------------------------------*
*& Module Pool      SAPMZC1MM0006
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Program ID    : SAPMZC1MM0006 (구매정보 레코드 관리)
*& Program Name  : 구매정보 레코드 관리 프로그램
*& Module        : MM
*& T-Code        :
*& Created By    : 홍승욱 (NCODE-C-29)
*& Created On    : 2026.05.12
*& Description   : 구매정보 레코드 관리 프로그램
*&---------------------------------------------------------------------*
*& [ Modification History ]
*& Date        Developer     Description
*&---------------------------------------------------------------------*
*& 2026.05.12  홍승욱        화면설계
*&---------------------------------------------------------------------*
*INCLUDE sapmzc1mm0006_top                       .    " Global Data
*
*INCLUDE sapmzc1mm0006_c01                       .  " ALV Events
*INCLUDE sapmzc1mm0006_o01                       .  " PBO-Modules
*INCLUDE sapmzc1mm0006_i01                       .  " PAI-Modules
*INCLUDE sapmzc1mm0006_f01                       .  " FORM-Routines

INCLUDE sapmzc1mm0096_top                       .    " Global Data

INCLUDE sapmzc1mm0096_c01                       .  " ALV Events
INCLUDE sapmzc1mm0096_o01                       .  " PBO-Modules
INCLUDE sapmzc1mm0096_i01                       .  " PAI-Modules
INCLUDE sapmzc1mm0096_f01                       .  " FORM-Routines

**********************************************************************
* START-OF-SELECTION
**********************************************************************
START-OF-SELECTION.
  CALL SCREEN 100.
