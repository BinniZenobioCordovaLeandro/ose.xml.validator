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
            var ublVersion = domDocumentHelper.select("string(/xmlns:Invoice/cbc:UBLVersionID)");
            if (ublVersion != "2.1") {
                throw new Error('2074');
            } else {
                this.ublVersion = ublVersion;
            }
            var customization = domDocumentHelper.select("string(/xmlns:Invoice/cbc:CustomizationID)");
            if (customization != "2.0") {
                throw new Error('2072');
            } else {
                this.customization = customization;
            }
            this.customization_SchemeAgencyName = domDocumentHelper.select("string(/xmlns:Invoice/cbc:CustomizationID/@schemeAgencyName)");
            this.id = domDocumentHelper.select('string(/xmlns:Invoice/cbc:ID)');
            this.fechaEmision = domDocumentHelper.select('string(/xmlns:Invoice/cbc:IssueDate)');
            this.horaEmision = domDocumentHelper.select('string(/xmlns:Invoice/cbc:IssueTime)');
            this.tipoDoc = domDocumentHelper.select('string(/xmlns:Invoice/cbc:InvoiceTypeCode)');
            this.tipoDoc_listAgencyName = domDocumentHelper.select('string(/xmlns:Invoice/cbc:InvoiceTypeCode/@listAgencyName)');
            this.tipoDoc_listName = domDocumentHelper.select('string(/xmlns:Invoice/cbc:InvoiceTypeCode/@listName)');
            this.tipoDoc_listURI = domDocumentHelper.select('string(/xmlns:Invoice/cbc:InvoiceTypeCode/@listURI)');

            this.tipoMoneda = domDocumentHelper.select('string(/xmlns:Invoice/cbc:DocumentCurrencyCode)');
            this.tipoMoneda_listID = domDocumentHelper.select('string(/xmlns:Invoice/cbc:DocumentCurrencyCode/@listID)');
            this.tipoMoneda_listName = domDocumentHelper.select('string(/xmlns:Invoice/cbc:DocumentCurrencyCode/@listName)');
            this.tipoMoneda_listAgencyName = domDocumentHelper.select('string(/xmlns:Invoice/cbc:DocumentCurrencyCode/@listAgencyName)');

            this.fechaVencimiento = domDocumentHelper.select('string(/xmlns:Invoice/cbc:DueDate)');

            resolve(this.warning ? this.warning : null);
        });
    }
}

module.exports = Factura2_0Loader;