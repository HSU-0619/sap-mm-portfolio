@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'QR 발행여부(배치당 1행)'
define view entity ZCDS_C1_MM_0009_2
  as select from ztc1mm0028
{
  key charg            as Charg,
  key matnr            as Matnr,
      max( qr_no )     as QrNo,
      max( qr_status ) as QrStatus
}
group by charg, matnr
