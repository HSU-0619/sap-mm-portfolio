@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'QR 발행대상(배치 그룹핑)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCDS_C1_MM_0004
  as select from ztc1mm0005 as gr
    left outer join ztc1mm0001 as mat on gr.matnr = mat.matnr
    left outer join ztc1mm0012 as ven on gr.lifnr = ven.lifnr
    left outer join ZCDS_C1_MM_0009_2 as qr on  gr.charg_sid = qr.Charg
                                            and gr.matnr     = qr.Matnr
{
  key gr.matnr                              as Matnr,
  key gr.charg_sid                          as Charg,
  key gr.werks                              as Werks,
      max( mat.maktx )                      as Maktx,
      max( gr.lgort_sid )                   as Lgort,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      sum( gr.menge )                       as Menge,      // 총수량(누적)
      gr.meins                              as Meins,
 
      max( gr.ebeln )                       as Ebeln,
      max( gr.lifnr )                       as Lifnr,
      max( ven.name1 )                      as VenName,
      max( gr.budat )                       as Budat,      // 최신 입고일
      max( gr.bldat )                       as Bldat,

      max( gr.mblnr )                       as Mblnr,      // 대표 입고문서(발행용)
      max( gr.mjahr )                       as Mjahr,
      max( gr.zeile )                       as Zeile,

      max( qr.QrNo )                        as QrNo,
      max( qr.QrStatus )                    as QrStatus,
      case when max( qr.QrNo ) is not null
           then 'X' else '' end             as QrIssued
}
where gr.bwart = '101' or gr.bwart = '131'
group by gr.matnr, gr.charg_sid, gr.werks, gr.meins
