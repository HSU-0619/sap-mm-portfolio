@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO 품목 Root view'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZCDS_C1_MM_0002_RV
  as select from ztc1mm0008 as I
    left outer join ztc1mm0026 as PR
      on  I.banfn = PR.banfn
      and I.bnfpo = PR.bnfpo
{
  key I.ebeln  as Ebeln,
  key I.ebelp  as Ebelp,
      I.matnr  as Matnr,
      PR.maktx as Maktx,
      PR.purrsn as Purrsn,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      I.menge  as Menge,
      I.meins  as Meins,

      @Semantics.amount.currencyCode: 'Waers'
      I.netpr  as Netpr,

      I.peinh  as Peinh,
      I.waers  as Waers,
      I.werks  as Werks,
      I.lgort  as Lgort,
      I.lfdat  as Lfdat,
      I.banfn  as Banfn,
      I.bnfpo  as Bnfpo,
      I.loekz  as Loekz,
      I.statu  as ItemStatu
}
