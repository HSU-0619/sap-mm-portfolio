@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Child view for PO approval'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity zc1_29_mm_cv_01_cds as select from ztc1mm0008
association to parent zc1_29_mm_rv_01_cds as _Header
    on $projection.Ebeln = _Header.Ebeln
{
    key ebeln as Ebeln,
    key ebelp as Ebelp,
    matnr as Matnr,
    @Semantics.quantity.unitOfMeasure: 'Meins'
    menge as Menge,
    meins as Meins,
    werks as Werks,
    pstyp as Pstyp,
    lgort as Lgort,
    reswk as Reswk,
    @Semantics.amount.currencyCode: 'Waers'
    netpr as Netpr,
    waers as Waers,
    peinh as Peinh,
    banfn as Banfn,
    bnfpo as Bnfpo,
    wepos as Wepos,
    repos as Repos,
    webre as Webre,
    elikz as Elikz,
    erekz as Erekz,
    loekz as Loekz,
    paedt as Paedt,
    statu as Statu,
    _Header
}
