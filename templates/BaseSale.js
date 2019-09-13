"use strict";

var moment = require('moment');

var Parameter = require('../catalogs/Parameter.json');
const Catalog02 = require('../catalogs/Catalog02.json');

var Company = require('./Company');
var Client = require('./Client');
var Document = require('./Document');
var SaleDetail = require('./SaleDetail');
var Signature = require('./Signature');

class BaseSale {
    constructor() {
        this._warning = [];
        this._ublVersion = null;
        this._customization = null;
        this._id = null;

        this._customization_schemeAgencyName = null;

        this._tipoDoc = null;
        this._tipoDoc_listAgencyName = null;
        this._tipoDoc_listName = null;
        this._tipoDoc_listURI = null;

        this._serie = null;
        this._correlativo = null;

        this._fechaEmision = null;
        this._horaEmision = null;

        this._company = new Company();
        this._client = new Client();

        this._tipoMoneda = null;
        this._tipoMoneda_listID = null;
        this._tipoMoneda_listName = null;
        this._tipoMoneda_listAgencyName = null;

        this._fechaVencimiento = null;

        this._signature = new Signature();

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
    get customization_schemeAgencyName() {
        return this._customization_schemeAgencyName;
    }
    set customization_schemeAgencyName(value) {
        if (value) {
            if (!/^PE:SUNAT$/.test(value)) this.warning.push('4256');
            this._customization_schemeAgencyName = value;
        }
    }
    get id() {
        return this._id;
    }
    set id(value) {
        var matches = /^([A-Z0-9]{1,4})-([0-9]{1,8})$/.exec(value);
        // if (matches[1] != global.value.serie) throw new Error('1035');
        // if (matches[2] != global.value.correlativo) throw new Error('1036');
        if (!(/^[F][A-Z0-9]{3}-[0-9]{1,8}$/.test(value) || /^[0-9]{1,4}-[0-9]{1,8}$/.test(value))) throw new Error('1001');
        // if (!/^[0-9]{1}/.test(value) && vouchers.id(value).indicador == 1) throw new Error('1033');
        // if (/^[0-9]{1}/.test(value) && vouchers.id(value).indicador == 2) throw new Error('1032');
        // if (!/^[0-9]{1}/.test(value) && (vouchers.id(value).indicador == 0 || vouchers.id(value).indicador == 2)) throw new Error('1032');
        // if (/^[0-9]{1}/.test(value) && vouchersAuthorityContingency.id(value)) throw new Error('3207');
        // if (/^[0-9]{1}/.test(value) && !vouchersAuthorityPhysical.id(value)) throw new Error('3207');
        this._id = value;
    }
    get tipoDoc() {
        return this._tipoDoc;
    }
    set tipoDoc(value) {
        if (!value) throw new Error('1004');
        // if (value != file.tipoDoc) throw new Error('1004');
        this._tipoDoc = value;
    }
    get tipoDoc_listAgencyName() {
        return this._tipoDoc_listAgencyName;
    }
    set tipoDoc_listAgencyName(value) {
        if (value) {
            if (!/^PE:SUNAT$/.test(value)) this.warning.push('4251');
            this._tipoDoc_listAgencyName = value;
        }
    }
    get tipoDoc_listName() {
        return this._tipoDoc_listName;
    }
    set tipoDoc_listName(value) {
        if (value) {
            if (value != 'Tipo de Documento') this.warning.push('4252');
            this._tipoDoc_listName = value;
        }
    }
    get tipoDoc_listURI() {
        return this._tipoDoc_listURI;
    }
    set tipoDoc_listURI(value) {
        if (value) {
            if (value != 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01') this.warning.push('4253');
            this._tipoDoc_listURI = value;
        }
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
        if (moment().diff(moment(value), 'days') > 2) throw new Error('2329');
        // check 2108
        // console.log(Parameter["004"]);
        this._fechaEmision = value;
    }
    get horaEmision() {
        return this._horaEmision;
    }
    set horaEmision(value) {
        this._horaEmision = value;
    }
    get company() {
        return this._company;
    }
    set company(value) {
        this._company = value;
    }
    get client() {
        return this._client;
    }
    set client(value) {
        this._client = value;
    }
    get tipoMoneda() {
        return this._tipoMoneda;
    }
    set tipoMoneda(value) {
        if (!value) throw new Error('2070');
        if (!Catalog02[value]) throw new Error('3088');
        this._tipoMoneda = value;
    }
    get tipoMoneda_listID() {
        return this._tipoMoneda_listID;
    }
    set tipoMoneda_listID(value) {
        if (value) {
            if (value != 'ISO 4217 Alpha') this.warning.push('4254');
            this._tipoMoneda_listID = value;
        }
    }
    get tipoMoneda_listName() {
        return this._tipoMoneda_listName;
    }
    set tipoMoneda_listName(value) {
        if (value) {
            if (value != 'Currency') this.warning.push('4252');
            this._tipoMoneda_listName = value;
        }
    }
    get tipoMoneda_listAgencyName() {
        return this._tipoMoneda_listAgencyName;
    }
    set tipoMoneda_listAgencyName(value) {
        if (value) {
            if (value != 'United Nations Economic Commission for Europe') this.warning.push('4251');
            this._tipoMoneda_listAgencyName = value;
        }
    }
    get fechaVencimiento() {
        return this._fechaVencimiento;
    }
    set fechaVencimiento(value) {
        this._fechaVencimiento = value;
    }
    get signature() {
        return this._signature;
    }
    set signature(value) {
        this._signature = value;
    }
}

module.exports = BaseSale;