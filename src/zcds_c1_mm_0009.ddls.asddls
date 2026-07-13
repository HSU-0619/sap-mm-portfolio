@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'QR 이동이력'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCDS_C1_MM_0009
  as select from ztc1mm0005 as mv
    left outer join ztc1mm0001 as mat on mv.matnr = mat.matnr
    left outer join ztc1mm0012 as ven on mv.lifnr = ven.lifnr
{
  key mv.mblnr        as Mblnr,
  key mv.mjahr        as Mjahr,
  key mv.zeile        as Zeile,
      mv.bwart        as Bwart,
      mv.shkzg        as Shkzg,
      mv.matnr        as Matnr,
      mat.maktx       as Maktx,
      mv.werks        as Werks,
      mv.lgort_sid    as Lgort,
      mv.umlgo        as Umlgo,
      mv.charg_sid    as Charg,
      @Semantics.quantity.unitOfMeasure: 'Meins'
      mv.menge        as Menge,
      mv.meins        as Meins,
      mv.budat        as Budat,
      mv.bldat        as Bldat,
      mv.ebeln        as Ebeln,
      mv.ebelp        as Ebelp,
      mv.lifnr        as Lifnr,
      ven.name1       as VenName,
      mv.aufnr        as Aufnr
}
