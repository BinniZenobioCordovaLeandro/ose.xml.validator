"use strict";

var DetailAttribute = require('./DetailAttribute');

class SaleDetail {
    constructor() {
        this._unidad = null;
        this._cantidad = null;
        this._codProducto = null;
        this._codProdSunat = null;
        this._codProdGS1 = null;
        this._descripcion = null;
        this._mtoValorUnitario = null;
        this._cargos = null;
        this._descuentos = null;
        this._descuento = null;
        this._mtoBaseIgv = null;
        this._porcentajeIgv = null;
        this._igv = null;
        this._tipAfeIgv = null;
        this._mtoBaseIsc = null;
        this._porcentajeIsc = null;
        this._isc = null;
        this._tipSisIsc = null;
        this._mtoBaseOth = null;
        this._porcentajeOth = null;
        this._otroTributo = null;
        this._totalImpuestos = null;
        this._mtoPrecioUnitario = null;
        this._mtoValorVenta = null;
        this._mtoValorGratuito = null;

        this._atributos = [new DetailAttribute()];
    }
}

module.exports = SaleDetail;