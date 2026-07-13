@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO 결재이력 Root view'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCDS_C1_MM_0003_RV
  as select from ztc1mm0027 as H
{
  key H.ebeln        as Ebeln,
  key H.seqnr        as Seqnr,

      H.astep        as Astep,
      H.pernr        as Pernr,
      H.uname        as Uname,
      H.ename        as Ename,
      H.zgrade       as Zgrade,
      H.action       as Action,
      H.actdt        as Actdt,
      H.appr_comment as ApprComment
}
