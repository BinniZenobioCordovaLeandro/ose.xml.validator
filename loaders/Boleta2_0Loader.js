"use strict"
const BaseSale = require('../templates/BaseSale');
var DomDocumentHelper = require('../helpers/DomDocumentHelper');
class Boleta2_0Loader extends BaseSale {
    constructor(xml) {
        this._xml = xml;
    }
    get xml() {
        return this._xml;
    }
    set xml(value) {
        this._xml = value;
    }
    load(xml = this.xml) {
        console.log('loading sentences to Boleta2_0Loader');
    }
}

module.exports = Boleta2_0Loader;