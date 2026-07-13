@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '자재별 구매오더 입고예정(리드타임 기반)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCDS_C1_MM_0008
  as select from ztc1mm0008 as po
    inner join ztc1mm0007 as hd
      on hd.ebeln = po.ebeln

    left outer join ZCDS_C1_MM_0007 as gr
      on  gr.ebeln = po.ebeln
      and gr.ebelp = po.ebelp

    left outer join ztc1mm0022 as ir
      on  ir.infnr      = po.infnr
      and ir.werks      = 'TS00'
      and ir.valid_from <= $session.system_date
      and ir.valid_to   >= $session.system_date
{
  key po.ebeln as Ebeln,
  key po.ebelp as Ebelp,

      po.matnr as Matnr,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      cast(
        cast( po.menge as abap.quan( 13, 3 ) )
        -
        cast(
          coalesce(
            gr.GrQty,
            cast( 0 as abap.quan( 13, 3 ) )
          )
          as abap.quan( 13, 3 )
        )
        as abap.quan( 13, 3 )
      ) as OpenQty,

 
      po.meins as Meins,

      cast( coalesce( ir.aplfz, 3 ) as abap.int4 ) as LeadDays,

      dats_add_days(
        hd.bedat,
        cast( coalesce( ir.aplfz, 3 ) as abap.int4 ),
        'NULL'
      ) as EtaDate
}
where hd.statu = 'AP'
  and po.elikz = ''
  and po.ebeln like '3%'
  and cast( po.menge as abap.quan( 13, 3 ) )
      >
      cast(
        coalesce(
          gr.GrQty,
          cast( 0 as abap.quan( 13, 3 ) )
        )
        as abap.quan( 13, 3 )
      )
