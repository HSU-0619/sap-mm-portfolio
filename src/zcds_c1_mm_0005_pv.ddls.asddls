@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'QR 발행이력 Projection view'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZCDS_C1_MM_0005_PV
  provider contract transactional_query
  as projection on ZCDS_C1_MM_0005_RV
{
  key QrNo,
      Mblnr,
      Mjahr,
      Zeile,
      Charg,
      Matnr,
      Maktx,
      Werks,
      Lgort,
      Ebeln,
      Ebelp,
      Lifnr,
      VenName,
      @Semantics.quantity.unitOfMeasure: 'Meins'
      GrQty,
      Meins,
      GrDate,
      Bldat,
      QrData,
      QrStatus,
      Erdat,
      Ernam,
      ErnamName
}
