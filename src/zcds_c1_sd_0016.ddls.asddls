@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SD 판매오더 변경이력 아이템'
@Metadata.allowExtensions: true
define view entity ZCDS_C1_SD_0016
  as select from ztc1sd0009 as Pos

  /// [ATP] 변경된 SO 품목 조인 (자재/플랜트/현재수량)
    left outer join ztc1sd0002 as SoItem
      on  SoItem.vbeln = cast( substring( Pos.tabkey,  1, 10 ) as vbeln_va )
      and SoItem.posnr = cast( substring( Pos.tabkey, 11,  6 ) as posnr_va )
    // [ATP] SO 헤더 조인 (요청 납기일)
    left outer join ztc1sd0001 as SoHdr
      on  SoHdr.vbeln = cast( substring( Pos.tabkey, 1, 10 ) as vbeln_va )
    left outer join ztc1hr0001 as HrUser
      on  HrUser.uname = Pos.ernam
  // 부모(변경 헤더 CDHDR)로 association
  association [1..1] to ZCDS_C1_SD_0015 as _Header
    on  _Header.ObjectClass = $projection.ObjectClass
    and _Header.ObjectId    = $projection.ObjectId
    and _Header.ChangeNr    = $projection.ChangeNr
{
  key Pos.changer        as ChangeNr,
  key Pos.tabname        as TabName,
  key Pos.tabkey         as TabKey,
  key Pos.fname          as FieldName,
  key Pos.chngind        as ChangeInd,
      Pos.objectclas     as ObjectClass,
      Pos.objectid       as ObjectId,
      cast( substring( Pos.tabkey,  1, 10 ) as vbeln_va )  as SalesOrder,
      cast( substring( Pos.tabkey, 11,  6 ) as posnr_va )  as SalesOrderItem,
      Pos.value_old      as ValueOld,
      Pos.value_new      as ValueNew,
      Pos.unit_old       as UnitOld,
      Pos.unit_new       as UnitNew,
      Pos.cuky_old       as CukyOld,
      Pos.cuky_new       as CukyNew,
      Pos.text_case      as TextCase,
      case Pos.chngind
        when 'I' then '생성'
        when 'U' then '수정'
        when 'D' then '삭제'
        else Pos.chngind
      end                as ChangeIndText,
      case Pos.tabname
        when 'ZTC1SD0001' then '헤더'
        when 'ZTC1SD0002' then '아이템'
        else Pos.tabname
      end                as ChangeLevelText,
      case Pos.fname
        when 'KWMENG' then '주문수량'
        when 'NETWR'  then '금액'
        when 'EDATU'  then '납기일'
        when 'NETPR'  then '단가'
        when 'WERKS'  then '플랜트'
        when 'KUNNR'  then '고객'
        when 'KWERT'  then '금액'
        else Pos.fname
      end                as FieldLabel,
      SoItem.matnr       as Matnr,
      SoItem.werks       as PlantTo,
      @Semantics.quantity.unitOfMeasure: 'Uom'
      SoItem.kwmeng      as CurrentQty,
      SoItem.vrkme       as Uom,
      SoHdr.vdatu        as RequestedDate,
      HrUser.ename       as ChangeUserName,   
      HrUser.zgrade      as ChangeUserGrade,  
      HrUser.dept        as ChangeUserDept,   
      Pos.erdat          as ErDat,
      Pos.erzet          as ErZet,
      Pos.ernam          as ErNam,
      _Header
}
