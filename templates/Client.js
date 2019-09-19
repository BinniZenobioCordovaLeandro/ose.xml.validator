"use strict";

var Address = require('./Address');

var list_contribuyente = require('../catalogs/list_contribuyente.json')

class Client {
    constructor() {
        this._warning = [];

        this._tipoDoc = null;
        this._tipoDoc_schemeName = null;
        this._tipoDoc_schemeAgencyName = null;
        this._tipoDoc_schemeURI = null;
        this._numDoc = null;
        this._rznSocial = null;
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
    get tipoDoc() {
        return this._tipoDoc;
    }
    set tipoDoc(value) {
        if (!value) throw new Error('2015');
        if (value != '6') throw new Error('2800');

        this._tipoDoc = value;
    }
    get tipoDoc_schemeName() {
        return this._tipoDoc_schemeName;
    }
    set tipoDoc_schemeName(value) {
        if(value && value != 'Documento de Identidad')this.warning('4255');

        this._tipoDoc_schemeName = value;
    }
    get tipoDoc_schemeAgencyName() {
        return this._tipoDoc_schemeAgencyName;
    }
    set tipoDoc_schemeAgencyName(value) {
        if(value && value != 'PE:SUNAT')this.warning('4256');

        this._tipoDoc_schemeAgencyName = value;
    }
    get tipoDoc_schemeURI() {
        return this._tipoDoc_schemeURI;
    }
    set tipoDoc_schemeURI(value) {
        if(value && value != 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06')this.warning('4257');
        this._tipoDoc_schemeURI = value;
    }
    get numDoc() {
        return this._numDoc;
    }
    set numDoc(value) {
        if (!value) throw new Error('3090');
        if (!value) throw new Error('2014');
        if (this.tipoDoc == '6' && !/^[0-9]{11}$/.test(value)) throw new Error('2017');
        if (this.tipoDoc == '6' && !list_contribuyente[value]) throw new Error('3202');
        if (this.tipoDoc == '6' && list_contribuyente[value].ind_estado != '00') this.warning('4013');
        if (this.tipoDoc == '6' && list_contribuyente[value].ind_condicion == '12') this.warning('4014');
        if ((this.tipoDoc == "4" || this.tipoDoc == "7" || this.tipoDoc == "0" || this.tipoDoc == "A" 
        || this.tipoDoc == "B" || this.tipoDoc == "C" || this.tipoDoc == "D" || this.tipoDoc == "E") && 
        !/^[A-Za-z0-9]{15}$/.test(value)) throw new Error('2802');
        if (this.tipoDoc == "1" && !/^[0-9]{8}$/.test(value)) throw new Error('2801');
           
        this._numDoc = value;

    }
    get rznSocial() {
        return this._rznSocial;
    }
    set rznSocial(value) {
        if(!value) throw new Error('2021');
        if(/^[A-Za-z0-9]{3,1500}$/.test(value)) throw new Error('2022');

        this._rznSocial = value;
    }
    get address() {
        return this._address;
    }
    set address(value) {
        this._address = value;
    }
}

module.exports = Client;