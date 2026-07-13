@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '구매오더별 누적 입고수량 집계'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCDS_C1_MM_0007
  as select from ztc1mm0005
{
  key ebeln,
  key ebelp,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      sum( menge ) as GrQty,

      meins        as Meins
}
where bwart = '101'
group by ebeln, ebelp, meins
