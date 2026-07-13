@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO 결재이력 조회 view'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCDS_C1_MM_0003_PV
  as select from ZCDS_C1_MM_0003_RV
{
  key Ebeln,
  key Seqnr,
      Astep,
      Pernr,
      Uname,
      Ename,
      Zgrade,
      Action,
      Actdt,
      ApprComment
}
