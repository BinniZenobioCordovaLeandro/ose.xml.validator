"use strict";

class Document {
    constructor() {
        this._warning = [];

        this._nroDoc = null;
        this._tipoDoc = null;
        this._tipoDoc_listAgencyName = null;
        this._tipoDoc_listName = null;
        this._tipoDoc_listURI = null;
    }
    get warning() {
        return this._warning;
    }
    set warning(value) {
        this._warning = value;
    }
    get nroDoc() {
        return this._nroDoc;
    }
    set nroDoc(value) {
        this._nroDoc = value;
    }
    get tipoDoc() {
        return this._tipoDoc;
    }
    set tipoDoc(value) {
        this._tipoDoc = value;
    }
    get tipoDoc_listAgencyName() {
        return this._tipoDoc_listAgencyName;
    }
    set tipoDoc_listAgencyName(value) {
        if (value && value != 'PE:SUNAT') this.warning.push('4251');
        this._tipoDoc_listAgencyName = value;
    }
    get tipoDoc_listName() {
        return this._tipoDoc_listName;
    }
    set tipoDoc_listName(value) {
        if (value && value != 'Tipo de Documento') this.warning.push('4252');
        this._tipoDoc_listName = value;
    }
    get tipoDoc_listURI() {
        return this._tipoDoc_listURI;
    }
    set tipoDoc_listURI(value) {
        this._tipoDoc_listURI = value;
    }
}

module.exports = Document;