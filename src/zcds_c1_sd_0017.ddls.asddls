@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '자재별 가용재고'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCDS_C1_SD_0017
  as select from ztc1mm0020 as St
{
      // 자재 + 플랜트별 가용재고 합계 (clabs = 가용/비제한 재고)
  key St.matnr        as Matnr,
  key St.werks        as Werks,
      cast( sum( St.clabs ) as abap.dec(15,3) ) as AvailQty
}
group by
  St.matnr,
  St.werks
