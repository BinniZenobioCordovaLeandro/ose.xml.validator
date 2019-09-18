"use strict"

var moment = require('moment');

const BaseSale = require('../templates/BaseSale');
var DomDocumentHelper = require('../helpers/DomDocumentHelper');

var path = require('./ocpp/Factura2_0.json');

var catalog_documentTypeCode = require('../catalogs/catalog_documentTypeCode.json'),
    list_padronContribuyente = require('../catalogs/list_padronContribuyente.json'),
    list_autorizacionComprobanteContingencia = require('../catalogs/list_autorizacionComprobanteContingencia.json'),
    list_autorizacionComprobanteFisico = require('../catalogs/list_autorizacionComprobanteFisico.json'),
    list_comprobantePagoElectronico = require('../catalogs/list_comprobantePagoElectronico.json'),
    parameter_maximunSendTerm = require('../catalogs/parameter_maximunSendTerm.json');

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
            var matches = /^([A-Z0-9]{1,4})-([0-9]{1,8})$/.exec(this.id);
            if (matches[1] != this.fileInfo.serieComprobante) throw new Error('1035');
            this.serie = matches[1];
            if (matches[2] != this.fileInfo.correlativoComprobante) throw new Error('1036');
            this.correlativo = matches[2];
            var rucTipoSerie = this.fileInfo.rucEmisor + '-' + this.fileInfo.tipoComprobante + '-' + this.serie;
            if (!/^[0-9]{1}/.test(this.serie) && (
                    list_comprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)] &&
                    list_comprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe == 1
                )) throw new Error('1033');
            if (/^[0-9]{1}/.test(this.serie) && (
                    list_comprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe &&
                    list_comprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe == 2
                )) throw new Error('1032');
            if (
                !/^[0-9]{1}/.test(this.serie) &&
                (
                    list_comprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)] && (
                        list_comprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe == 0 ||
                        list_comprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe == 2
                    )
                )
            ) throw new Error('1032');
            if (/^[0-9]{1}/.test(this.serie)) {
                if (!(list_autorizacionComprobanteContingencia[rucTipoSerie] && (
                        this.correlativo >= list_autorizacionComprobanteContingencia[rucTipoSerie].num_ini_cpe &&
                        this.correlativo <= list_autorizacionComprobanteContingencia[rucTipoSerie].num_fin_cpe
                    ))) throw new Error('3207');
                if (!(list_autorizacionComprobanteFisico[rucTipoSerie] && (
                        this.correlativo >= list_autorizacionComprobanteFisico[rucTipoSerie].num_ini_cpe &&
                        this.correlativo <= list_autorizacionComprobanteFisico[rucTipoSerie].num_fin_cpe
                    ))) throw new Error('3207');
            }

            this.fechaEmision = domDocumentHelper.select(path.fechaEmision);
            if (!/^[0-9]{1}/.test(this.serie)) {
                if (
                    moment().diff(moment(this.fechaEmision), 'days') > parameter_maximunSendTerm[this.fileInfo.tipoComprobante].day &&
                    !domDocumentHelper.select(path.fechaVencimiento) &&
                    moment().diff(moment(this.fechaEmision), 'days') >= 0
                ) throw new Error('2108');
            }
            this.horaEmision = domDocumentHelper.select(path.horaEmision);
            this.tipoDoc = domDocumentHelper.select(path.tipoDoc);
            if (this.tipoDoc != this.fileInfo.tipoComprobante && catalog_documentTypeCode[this.tipoDoc]) throw new Error('1003');
            this.tipoDoc_listID = domDocumentHelper.select(path.tipoDoc_listID);
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

            this.company.ruc = domDocumentHelper.select(path.company.ruc);
            if (this.company.ruc != this.fileInfo.rucEmisor) throw new Error('1034');
            if (
                this.tipoDoc_listID == '0201' &&
                list_padronContribuyente[this.company.ruc].ind_padron != '05'
            ) throw new Error('3097');
            this.company.ruc_schemeId = domDocumentHelper.select(path.company.ruc_schemeId);
            this.company.ruc_schemeName = domDocumentHelper.select(path.company.ruc_schemeName);
            this.company.ruc_schemeAgencyName = domDocumentHelper.select(path.company.ruc_schemeAgencyName);
            this.company.ruc_schemeUri = domDocumentHelper.select(path.company.ruc_schemeUri);
            this.company.nombreComercial = domDocumentHelper.select(path.company.nombreComercial);
            this.company.razonSocial = domDocumentHelper.select(path.company.razonSocial);

            this.company.address.direccion = domDocumentHelper.select(path.company.address.direccion);
            this.company.address.urbanizacion = domDocumentHelper.select(path.company.address.urbanizacion);
            this.company.address.provincia = domDocumentHelper.select(path.company.address.provincia);
            this.company.address.ubigueo = domDocumentHelper.select(path.company.address.ubigueo);
            this.company.address.ubigueo_schemeAgencyName = domDocumentHelper.select(path.company.address.ubigueo_schemeAgencyName);
            this.company.address.ubigueo_schemeName = domDocumentHelper.select(path.company.address.ubigueo_schemeName);
            this.company.address.departamento = domDocumentHelper.select(path.company.address.departamento);
            this.company.address.distrito = domDocumentHelper.select(path.company.address.distrito);
            this.company.address.codigoPais = domDocumentHelper.select(path.company.address.codigoPais);
            this.company.address.codigoPais_listId = domDocumentHelper.select(path.company.address.codigoPais_listId);
            this.company.address.codigoPais_listAgencyName = domDocumentHelper.select(path.company.address.codigoPais_listAgencyName);
            this.company.address.codigoPais_listName = domDocumentHelper.select(path.company.address.codigoPais_listName);

            this.company.address.codLocal = domDocumentHelper.select(path.company.address.codLocal);
            this.company.address.codLocal_listAgencyName = domDocumentHelper.select(path.company.address.codLocal_listAgencyName);
            this.company.address.codLocal_listName = domDocumentHelper.select(path.company.address.codLocal_listName);

            resolve(
                this.warning.concat(this.company.warning, this.company.address.warning) ?
                this.warning.concat(this.company.warning, this.company.address.warning) :
                null);
        });
    }
}

module.exports = Factura2_0Loader;