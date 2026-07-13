@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '고객별 월별 판매오더 수정현황 집계'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCDS_C1_SD_0019
  as select from ztc1sd0008 as H
    inner join      ztc1sd0001 as SO
      on SO.vbeln = cast( substring( H.objectid, 1, 10 ) as vbeln_va )
    left outer join ztc1sd0024 as Link
      on Link.kunnr = SO.kunnr
    left outer join ztc1sd0014 as BP
      on BP.partner = Link.partner
{
  key SO.kunnr                    as CustomerNo,
  key H.udate                     as ChangeDate,    // 변경일 (전체 날짜)
      max( BP.name_org1 )         as CustomerName,
      count( distinct H.changer ) as ChangeCount
}
where H.objectclas = 'SD_SO'
group by
  SO.kunnr,
  H.udate
