"use strict";

var catalog_geograficLocationCode = require('../catalogs/catalog_geograficLocationCode.json'),
    catalog_countryCode = require('../catalogs/catalog_countryCode.json');

class Address {
    constructor() {
        this._warning = [];

        this._ubigueo = null;
        this._ubigueo_schemeAgencyName = null;
        this._ubigueo_schemeName = null;

        this._codigoPais = null;
        this._codigoPais_listId = null;
        this._codigoPais_listAgencyName = null;
        this._codigoPais_listName = null;

        this._departamento = null;
        this._provincia = null;
        this._distrito = null;
        this._urbanizacion = null;
        this._direccion = null;
        this._codLocal = null;
        this._codLocal_listAgencyName = null;
        this._codLocal_listName = null;

    }
    get warning() {
        return this._warning;
    }
    set warning(value) {
        this._warning = value;
    }
    get ubigueo() {
        return this._ubigueo;
    }
    set ubigueo(value) {
        if (value && !catalog_geograficLocationCode[value]) this.warning.push('4093');
        this._ubigueo = value;
    }
    get ubigueo_schemeAgencyName() {
        return this._ubigueo_schemeAgencyName;
    }
    set ubigueo_schemeAgencyName(value) {
        if (value && value != 'PE:INEI') this.warning.push('4256');
        this._ubigueo_schemeAgencyName = value;
    }
    get ubigueo_schemeName() {
        return this._ubigueo_schemeName;
    }
    set ubigueo_schemeName(value) {
        if (value && value != 'Ubigeos') this.warning.push('4255');
        this._ubigueo_schemeName = value;
    }
    get codigoPais() {
        return this._codigoPais;
    }
    set codigoPais(value) {
        if (value && catalog_countryCode[value] && catalog_countryCode[value].a2 != 'PE') this.warning.push('4041');
        this._codigoPais = value;
    }
    get codigoPais_listId() {
        return this._codigoPais_listId;
    }
    set codigoPais_listId(value) {
        if (value && value != 'ISO 3166-1') this.warning.push('4254');
        this._codigoPais_listId = value;
    }
    get codigoPais_listAgencyName() {
        return this._codigoPais_listAgencyName;
    }
    set codigoPais_listAgencyName(value) {
        if (value && value != 'United Nations Economic Commission for Europe') this.warning.push('4251');
        this._codigoPais_listAgencyName = value;
    }
    get codigoPais_listName() {
        return this._codigoPais_listName;
    }
    set codigoPais_listName(value) {
        if (value && value != 'Country') this.warning.push('4252');
        this._codigoPais_listName = value;
    }
    get departamento() {
        return this._departamento;
    }
    set departamento(value) {
        if (value) {
            if (
                /^([ ]{1})/.test(value) ||
                /([ ]{1})$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !/^.{1,30}$/.test(value)
            ) this.warning.push('4097');
        }
        this._departamento = value;
    }
    get provincia() {
        return this._provincia;
    }
    set provincia(value) {
        if (value) {
            if (
                /^([ ]{1})/.test(value) ||
                /([ ]{1})$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !/^.{1,30}$/.test(value)
            ) this.warning.push('4096');
        }
        this._provincia = value;
    }
    get distrito() {
        return this._distrito;
    }
    set distrito(value) {
        if (value) {
            if (
                /^([ ]{1})/.test(value) ||
                /([ ]{1})$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !/^.{1,30}$/.test(value)
            ) this.warning.push('4098');
        }
        this._distrito = value;
    }
    get urbanizacion() {
        return this._urbanizacion;
    }
    set urbanizacion(value) {
        if (value) {
            if (
                /^([ ]{1})/.test(value) ||
                /([ ]{1})$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !/^.{1,25}$/.test(value)
            ) this.warning.push('4095');
        }
        this._urbanizacion = value;
    }
    get direccion() {
        return this._direccion;
    }
    set direccion(value) {
        if (value) {
            if (
                /^([ ]{1})/.test(value) ||
                /([ ]{1})$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !/^.{1,200}$/.test(value)
            ) this.warning.push('4094');
        }
        this._direccion = value;
    }
    get codLocal() {
        return this._codLocal;
    }
    set codLocal(value) {
        if (!value) this.warning.push('3030');
        if (value && !/^[0-9]{4}$/.test(value)) this.warning.push('4242');
        this._codLocal = value;
    }
    get codLocal_listAgencyName() {
        return this._codLocal_listAgencyName;
    }
    set codLocal_listAgencyName(value) {
        if (value && value != 'PE:SUNAT') this.warning.push('4251');
        this._codLocal_listAgencyName = value;
    }
    get codLocal_listName() {
        return this._codLocal_listName;
    }
    set codLocal_listName(value) {
        if (value && value != 'Establecimientos anexos') this.warning.push('4252');
        this._codLocal_listName = value;
    }
    
}

module.exports = Address;