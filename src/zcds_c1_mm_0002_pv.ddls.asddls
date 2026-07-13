@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO 품목 Projection view'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZCDS_C1_MM_0002_PV
  provider contract transactional_query
  as projection on ZCDS_C1_MM_0002_RV
{
  key Ebeln,
  key Ebelp,
      Matnr,
      Maktx,
      Purrsn,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      Menge,
      Meins,

      @Semantics.amount.currencyCode: 'Waers'
      Netpr,

      Peinh,
      Waers,
      Werks,
      Lgort,
      Lfdat,
      Banfn,
      Bnfpo,
      Loekz,
      ItemStatu
}
