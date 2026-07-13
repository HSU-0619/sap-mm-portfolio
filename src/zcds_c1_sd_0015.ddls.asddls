@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SD 판매오더 변경이력 헤더'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.usageType:{
  serviceQuality: #A,
  sizeCategory: #M,
  dataClass: #TRANSACTIONAL
}
define view entity ZCDS_C1_SD_0015
  as select from ztc1sd0008 as Hdr

  // 자식(변경 아이템 CDPOS) association.
  // [개선 ④] CHANGENR 단독이 아니라 OBJECTCLAS+OBJECTID+CHANGENR 3개로 조인 → 인덱스 사용
  association [0..*] to ZCDS_C1_SD_0016 as _Item
    on  $projection.ObjectClass = _Item.ObjectClass
    and $projection.ObjectId    = _Item.ObjectId
    and $projection.ChangeNr    = _Item.ChangeNr

{
      // 변경문서 키
  key Hdr.changer        as ChangeNr,        // 변경번호 (CDCHANGENR)

      Hdr.objectclas     as ObjectClass,     // 오브젝트 클래스
      Hdr.objectid       as ObjectId,        // 오브젝트 값 (판매오더 등)

      // 판매오더 번호: OBJECTID 앞 10자리에서 추출 (적재 규칙에 맞춰 조정)
      @Search.defaultSearchElement: true
      cast( substring( Hdr.objectid, 1, 10 ) as vbeln_va ) as SalesOrder,

      // 누가/언제/무엇으로 변경했는지
      Hdr.username       as ChangeUser,      // 변경자
      Hdr.udate          as ChangeDate,      // 변경일자
      Hdr.utime          as ChangeTime,      // 변경시각
      Hdr.tcode          as TCode,           // 트랜잭션코드

      // 관리 필드 (INCLUDE ZSC1SD0001 타임스탬프)
      Hdr.erdat          as ErDat,
      Hdr.erzet          as ErZet,
      Hdr.ernam          as ErNam,

      // association 공개
      _Item
}
