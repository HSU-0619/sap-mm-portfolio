@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'QR 발행이력 Root view'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZCDS_C1_MM_0005_RV
  as select from ztc1mm0028 as qr

    left outer join ztc1mm0001 as mat
      on qr.matnr = mat.matnr

    left outer join ztc1mm0012 as ven
      on qr.lifnr = ven.lifnr
      
    left outer join ztc1mm0005 as gr          
      on  qr.mblnr = gr.mblnr
      and qr.mjahr = gr.mjahr
      and qr.zeile = gr.zeile
      
    left outer join ztc1hr0001 as hr
      on hr.uname = qr.ernam
{
  key qr.qr_no                            as QrNo,
      qr.mblnr                            as Mblnr,
      qr.mjahr                            as Mjahr,
      qr.zeile                            as Zeile,
      qr.charg                            as Charg,
      qr.matnr                            as Matnr,
      mat.maktx                           as Maktx,
      qr.werks                            as Werks,
      qr.lgort                            as Lgort,
      qr.ebeln                            as Ebeln,
      qr.ebelp                            as Ebelp,
      qr.lifnr                            as Lifnr,
      ven.name1                           as VenName,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      qr.gr_qty                           as GrQty,
      qr.meins                            as Meins,

      qr.gr_date                          as GrDate,
      gr.bldat                            as Bldat,
      qr.qr_data                          as QrData,
      qr.qr_status                        as QrStatus,
      qr.erdat                            as Erdat,
      qr.ernam                            as Ernam,
      hr.ename                            as ErnamName
}
