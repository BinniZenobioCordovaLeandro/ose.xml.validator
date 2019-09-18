"use strict";
var Address = require('./Address');

var list_contribuyente = require('../catalogs/list_contribuyente.json');

class Company {
    constructor() {
        this._warning = [];

        this._ruc = null;
        this._ruc_schemeId = null;
        this._ruc_schemeName = null;
        this._ruc_schemeAgencyName = null;
        this._ruc_schemeUri = null;

        this._razonSocial = null;

        this._nombreComercial = null;

        this._address = new Address();
        this._email = null;
        this._telephone = null;
    }
    get warning() {
        return this._warning;
    }
    set warning(value) {
        this._warning = value;
    }
    get ruc() {
        return this._ruc;
    }
    set ruc(value) {
        if (!value) throw new Error('3089');
        if (list_contribuyente[value].ind_estado != '00') throw new Error('2010');
        if (list_contribuyente[value].ind_condicion == '12') throw new Error('2011');
        this._ruc = value;
    }
    get ruc_schemeId() {
        return this._ruc_schemeId;
    }
    set ruc_schemeId(value) {
        if (!value) throw new Error('1008');
        if (value != 6) throw new Error('1007');
        this._ruc_schemeId = value;
    }
    get ruc_schemeName() {
        return this._ruc_schemeName;
    }
    set ruc_schemeName(value) {
        if (value && value != 'Documento de Identidad') this.warning.push('4255');
        this._ruc_schemeName = value;
    }
    get ruc_schemeAgencyName() {
        return this._ruc_schemeAgencyName;
    }
    set ruc_schemeAgencyName(value) {
        if (value && value != 'PE:SUNAT') this.warning.push('4256');
        this._ruc_schemeAgencyName = value;
    }
    get ruc_schemeUri() {
        return this._ruc_schemeUri;
    }
    set ruc_schemeUri(value) {
        if (value && value != 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06') this.warning.push('4257');
        this._ruc_schemeUri = value;
    }
    get razonSocial() {
        return this._razonSocial;
    }
    set razonSocial(value) {
        if (!value) throw new Error('1037');
        if (
            /^([ ]{1})/.test(value) ||
            /([ ]{1})$/.test(value) ||
            /[\t\n\r]{1,}/.test(value) ||
            !/^.{1,1500}$/.test(value)
        ) this.warning.push('4338');
        this._razonSocial = value;
    }
    get nombreComercial() {
        return this._nombreComercial;
    }
    set nombreComercial(value) {
        if (value) {
            if (
                /^([ ]{1})/.test(value) ||
                /([ ]{1})$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !(/^.{1,1500}$/.test(value))
            ) this.warning.push('4092');
        }
        this._nombreComercial = value;
    }
    get address() {
        return this._address;
    }
    set address(value) {
        this._address = value;
    }
}

module.exports = Company;