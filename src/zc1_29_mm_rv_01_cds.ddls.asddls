@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Root view for PO approval'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity zc1_29_mm_rv_01_cds as 
    select from ztc1mm0007
    composition [0..*] of zc1_29_mm_cv_01_cds as _Item
{
    key ebeln as Ebeln,
        bsart as Bsart,
        bukrs as Bukrs,
        bstyp as Bstyp,
        lifnr as Lifnr,
        werks as Werks,
        bedat as Bedat,
        waers as Waers,
        frgkz as Frgkz,
        loekz as Loekz,
        statu as Statu,
        bigo  as Bigo,
        _Item 
}
