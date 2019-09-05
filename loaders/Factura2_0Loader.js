"use strict"
const BaseSale = require('../templates/BaseSale');

var DomDocumentHelper = require('../helpers/DomDocumentHelper');

class Factura2_0Loader extends BaseSale {
    constructor(xml) {
        super();
        this._xml = xml;
        this._domDocumentHelper = new DomDocumentHelper(xml);
    }
    get xml() {
        return this._xml;
    }
    set xml(value) {
        this._xml = value;
    }
    get domDocumentHelper() {
        return this._domDocumentHelper;
    }
    set domDocumentHelper(value) {
        this._domDocumentHelper = value;
    }
    load(xml = this.xml, domDocumentHelper = this.domDocumentHelper) {
        return new Promise((resolve, reject) => {
            domDocumentHelper.mappingNameSpaces();
            this.ublVersion = domDocumentHelper.select("string(/xmlns:Invoice/cbc:UBLVersionID)");
            this.customization = domDocumentHelper.select("string(/xmlns:Invoice/cbc:CustomizationID)");
            this.customization_SchemeAgencyName = domDocumentHelper.select("string(/xmlns:Invoice/cbc:CustomizationID/@schemeAgencyName)");
            resolve(this.warning ? this.warning : null);
        });
    }
}

module.exports = Factura2_0Loader;