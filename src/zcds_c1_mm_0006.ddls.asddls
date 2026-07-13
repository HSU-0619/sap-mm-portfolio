@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '배치별 현재고 집계 CDS View'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCDS_C1_MM_0006
  as select from ztc1mm0020
{
  key matnr                               as Matnr,
  key werks                               as Werks,
  key lgort                               as Lgort,
  key charg                               as Charg,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      clabs                               as Clabs,      -- 가용재고
      @Semantics.quantity.unitOfMeasure: 'Meins'
      cinsm                               as Cinsm,      -- 품질검사중
      @Semantics.quantity.unitOfMeasure: 'Meins'
      cspem                               as Cspem,      -- 보류재고
      @Semantics.quantity.unitOfMeasure: 'Meins'
      umlme                               as Umlme,      -- 이동중

      meins                               as Meins
}
