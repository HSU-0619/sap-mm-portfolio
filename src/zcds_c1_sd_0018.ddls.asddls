@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '자재별 생산 입고예정'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCDS_C1_SD_0018
  as select from ztc1pp0010 as D
    inner join   ztc1pp0009 as H
      on D.aufnr = H.aufnr
{
      // 생산오더 주차별 입고예정 (남은 미입고분만)
  key D.aufnr          as Aufnr,
  key D.order_item_no  as OrderItemNo,
      H.matnr          as Matnr,          // 어느 자재 생산인지 (헤더)
      H.werks          as Werks,
      D.gltrp          as ReceiptDate,    // 입고 예정일 (주차별 완료예정일)
      // 남은 입고수량 = 생산수량 - 입고완료수량
      @Semantics.quantity.unitOfMeasure: 'Meins'
      cast( D.gamng - D.wemng as abap.quan(13,3) ) as OpenQty,
      D.meins          as Meins,
      H.pro_status     as ProStatus
}
where  D.gamng - D.wemng  > 0       // 아직 안 들어온 분만
  and H.pro_status <> 'TEC'           // 기술적 완료 제외 (이미 재고 반영)
  and H.pro_status <> 'CLD'           // 마감 제외
  and D.gltrp >= $session.system_date
