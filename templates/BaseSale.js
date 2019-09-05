"use strict";
var Company = require('./Company');
var Client = require('./Client');
var Document = require('./Document');
var SaleDetail = require('./SaleDetail');

class BaseSale {
    constructor() {
        this._warning = [];
        this._ublVersion = null;
        this._customization = null;
        this._customization_SchemeAgencyName = null;
        this._tipoDoc = null;
        this._serie = null;
        this._correlativo = null;
        this._fechaEmision = null;

        this._company = new Company();
        this._client = new Client();

        this._tipoMoneda = null;
        this._sumOtrosCargos = null;
        this._mtoOperGravadas = null;
        this._mtoOperInafectas = null;
        this._mtoOperExoneradas = null;
        this._mtoOperExportacion = null;
        this._mtoIGV = null;
        this._mtoBaseIsc = null;
        this._mtoISC = null;
        this._mtoBaseOth = null;
        this._mtoOtrosTributos = null;
        this._totalImpuestos = null;
        this._mtoImpVenta = null;

        this._details = [new SaleDetail()];

        this._legends = null;

        this._guias = [new Document()];
        this._relDocs = [new Document()];

        this._compra = null;
    }
    get warning() {
        return this._warning;
    }
    set warning(value) {
        this._warning = value;
    }
    get ublVersion() {
        return this._ublVersion;
    }
    set ublVersion(value) {
        if (!value) throw new Error('2075');
        if (!/^([1-9.]){3}$/.test(value)) throw new Error('2074');
        this._ublVersion = value;
    }
    get customization() {
        return this._customization;
    }
    set customization(value) {
        if (!value) throw new Error('2073');
        if (!/^([0-9.]){3}$/.test(value)) throw new Error('2072');
        this._customization = value;
    }
    get customization_SchemeAgencyName() {
        return this._customization_SchemeAgencyName;
    }
    set customization_SchemeAgencyName(value) {
        if (value) {
            if (!/^PE:SUNAT$/.test(value)) this.warning.push('4256');
            this._customization_SchemeAgencyName = value;
        }
    }
    get tipoDoc() {
        return this._tipoDoc;
    }
    set tipoDoc(value) {
        this._tipoDoc = value;
    }
    get serie() {
        return this._serie;
    }
    set serie(value) {
        this._serie = value;
    }
    get correlativo() {
        return this._correlativo;
    }
    set correlativo(value) {
        this._correlativo = value;
    }
    get fechaEmision() {
        return this._fechaEmision;
    }
    set fechaEmision(value) {
        this._fechaEmision = value;
    }
}

module.exports = BaseSale;