@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO 결재 헤더 Projection view'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZCDS_C1_MM_0001_PV
  provider contract transactional_query
  as projection on ZCDS_C1_MM_0001_RV
{
  key Ebeln,
      Bsart,
      Bukrs,
      Bstyp,
      Lifnr,
      Name1,
      MyGrade,
      Werks,
      Bedat,
      Waers,
      Zterm,
      Frgkz,
      Statu,
      Bigo,
      Ernam,
      Aedat,
      Loekz
}
