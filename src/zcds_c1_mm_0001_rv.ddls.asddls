@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO 결재 헤더 Root view'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZCDS_C1_MM_0001_RV
  as select from ztc1mm0007 as PO
    left outer join ztc1mm0012 as V
      on PO.lifnr = V.lifnr
    left outer join ztc1hr0001 as ME 
      on ME.uname = $session.user
{
  key PO.ebeln as Ebeln,
      PO.bsart as Bsart,
      PO.bukrs as Bukrs,
      PO.bstyp as Bstyp,
      PO.lifnr as Lifnr,
      V.name1  as Name1,
      ME.zgrade as MyGrade,
      PO.werks as Werks,
      PO.bedat as Bedat,
      PO.waers as Waers,
      PO.zterm as Zterm,
      PO.frgkz as Frgkz,
      PO.statu as Statu,
      PO.bigo  as Bigo,
      PO.ernam as Ernam,
      PO.aedat as Aedat,
      PO.loekz as Loekz
}
