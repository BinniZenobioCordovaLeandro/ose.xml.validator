"use strict"

const BaseSale = require('../templates/BaseSale');
var DomDocumentHelper = require('../helpers/DomDocumentHelper');

var path = require('./ocpp/Factura2_0.json');

class Factura2_0Loader extends BaseSale {
    constructor(xml, fileInfo = null, domDocumentHelper = null) {
        super();
        this._xml = xml;
        this._fileInfo = fileInfo ? fileInfo : {
            rucEmisor: null,
            tipoComprobante: null,
            serieComprobante: null,
            correlativoComprobante: null
        };
        this._domDocumentHelper = domDocumentHelper ? domDocumentHelper : new DomDocumentHelper(xml);
    }
    get xml() {
        return this._xml;
    }
    set xml(value) {
        this._xml = value;
    }
    get fileInfo() {
        return this._fileInfo;
    }
    set fileInfo(value) {
        this._fileInfo = value;
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

            this.ublVersion = domDocumentHelper.select(path.ublVersion);
            if (this.ublVersion != "2.1") throw new Error('2074');
            this.customization = domDocumentHelper.select(path.customization);
            if (this.customization != "2.0") throw new Error('2072');
            this.customization_schemeAgencyName = domDocumentHelper.select(path.customization_schemeAgencyName);
            this.id = domDocumentHelper.select(path.id);
            this.fechaEmision = domDocumentHelper.select(path.fechaEmision);
            this.horaEmision = domDocumentHelper.select(path.horaEmision);
            this.tipoDoc = domDocumentHelper.select(path.tipoDoc);
            this.tipoDoc_listAgencyName = domDocumentHelper.select(path.tipoDoc_listAgencyName);
            this.tipoDoc_listName = domDocumentHelper.select(path.tipoDoc_listName);
            this.tipoDoc_listURI = domDocumentHelper.select(path.tipoDoc_listURI);
            this.tipoMoneda = domDocumentHelper.select(path.tipoMoneda);
            this.tipoMoneda_listID = domDocumentHelper.select(path.tipoMoneda_listID);
            this.tipoMoneda_listName = domDocumentHelper.select(path.tipoMoneda_listName);
            this.tipoMoneda_listAgencyName = domDocumentHelper.select(path.tipoMoneda_listAgencyName);
            this.fechaVencimiento = domDocumentHelper.select(path.fechaVencimiento);

            this.signature.id = domDocumentHelper.select(path.signature.id);
            this.signature.canonicalization_algorithm = domDocumentHelper.select(path.signature.canonicalization_algorithm);
            this.signature.signature_algorithm = domDocumentHelper.select(path.signature.signature_algorithm);
            this.signature.reference_uri = domDocumentHelper.select(path.signature.reference_uri);
            this.signature.transform_algorithm = domDocumentHelper.select(path.signature.transform_algorithm);
            this.signature.digest_algorithm = domDocumentHelper.select(path.signature.digest_algorithm);
            this.signature.digestValue = domDocumentHelper.select(path.signature.digestValue);
            this.signature.signatureValue = domDocumentHelper.select(path.signature.signatureValue);
            this.signature.x509Certificate = domDocumentHelper.select(path.signature.x509Certificate);
            this.signature.signature = domDocumentHelper.select(path.signature.signature);
            this.signature.signature_id = domDocumentHelper.select(path.signature.signature_id);
            this.signature.partyIdentificationId = domDocumentHelper.select(path.signature.partyIdentificationId);
            if (this.signature.partyIdentificationId != this.fileInfo.rucEmisor) throw new Error('2078');
            this.signature.partyName = domDocumentHelper.select(path.signature.partyName);
            this.signature.externalReferenceUri = domDocumentHelper.select(path.signature.externalReferenceUri);

            resolve(this.warning ? this.warning : null);
        });
    }
}

module.exports = Factura2_0Loader;