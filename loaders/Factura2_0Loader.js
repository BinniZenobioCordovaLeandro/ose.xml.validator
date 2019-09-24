"use strict"

var moment = require('moment');

const BaseSale = require('../templates/BaseSale');
var DomDocumentHelper = require('../helpers/DomDocumentHelper');

var path = require('./ocpp/Factura2_0.json');

var catalog_documentTypeCode = require('../catalogs/catalog_documentTypeCode.json'),
    catalog_taxRelatedDocumentCode = require('../catalogs/catalog_taxRelatedDocumentCode.json'),
    list_padronContribuyente = require('../catalogs/list_padronContribuyente.json'),
    list_autorizacionComprobanteContingencia = require('../catalogs/list_autorizacionComprobanteContingencia.json'),
    list_autorizacionComprobanteFisico = require('../catalogs/list_autorizacionComprobanteFisico.json'),
    list_comprobantePagoElectronico = require('../catalogs/list_comprobantePagoElectronico.json'),
    parameter_maximunSendTerm = require('../catalogs/parameter_maximunSendTerm.json');

var Document = require('../templates/Document');

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

            this.client.numDoc = domDocumentHelper.select(path.client.numDoc);
            this.client.tipoDoc = domDocumentHelper.select(path.client.tipoDoc);
            if ((
                    this.tipoDoc_listID == '0200' ||
                    this.tipoDoc_listID == '0201' ||
                    this.tipoDoc_listID == '0204' ||
                    this.tipoDoc_listID == '0208'
                ) && this.client.tipoDoc == '6') throw new Error('2800');
            if (

                this.tipoDoc_listID == '0202' ||
                this.tipoDoc_listID == '0203' ||
                this.tipoDoc_listID == '0205' ||
                this.tipoDoc_listID == '0206' ||
                this.tipoDoc_listID == '0207' ||
                this.tipoDoc_listID == '0401'
            ) throw new Error('2800');
            //ICOMPLETO (ERROR : 2800)
            if (
                this.tipoDoc_listID == '0112 Venta Interna - Sustenta Gastos Deducibles Persona Natural' &&
                this.client.tipoDoc != '1' && this.client.tipoDoc != '6'
            ) throw new Error('2800');
            this.client.tipoDoc_schemeName = domDocumentHelper.select(path.client.tipoDoc_schemeName);
            this.client.tipoDoc_schemeAgencyName = domDocumentHelper.select(path.client.tipoDoc_schemeAgencyName);
            this.client.tipoDoc_schemeURI = domDocumentHelper.select(path.client.tipoDoc_schemeURI);
            this.client.rznSocial = domDocumentHelper.select(path.client.rznSocial);
            this.client.address.direccion = domDocumentHelper.select(path.client.address.direccion);
            this.client.address.urbanizacion = domDocumentHelper.select(path.client.address.urbanizacion);
            this.client.address.provincia = domDocumentHelper.select(path.client.address.provincia);
            this.client.address.ubigueo = domDocumentHelper.select(path.client.address.ubigueo);
            this.client.address.adress_schemeAgencyName = domDocumentHelper.select(path.client.address.adress_schemeAgencyName);
            this.client.address.address_schemeName = domDocumentHelper.select(path.client.address.address_schemeName);
            this.client.address.departamento = domDocumentHelper.select(path.client.address.departamento);
            this.client.address.distrito = domDocumentHelper.select(path.client.address.distrito);
            this.client.address.codigoPais = domDocumentHelper.select(path.client.address.codigoPais);
            this.client.address.address_listID = domDocumentHelper.select(path.client.address.address_listID);
            this.client.address.address_listAgencyName = domDocumentHelper.select(path.client.address.address_listAgencyName);
            this.client.address.address_listName = domDocumentHelper.select(path.client.address.address_listName);
            
            var guias = domDocumentHelper.select(path.guias['.']);
            var guiasLength = guias.length ? guias.length : 0;
            var guiasId = {};
            for (let index = 0; index < guiasLength; index++) {
                var document = new Document();
                const guia = guias[index];
                if (domDocumentHelper.select(path.guias.nroDoc)[index]) {
                    document.nroDoc = domDocumentHelper.select(path.guias.nroDoc)[index].textContent;
                    if (document.nroDoc &&
                        !(
                            /^[T][0-9]{3}-[0-9]{1,8}-[0-9]{4}-[0-9]{1,8}$/.test(document.nroDoc) ||
                            /^[0-9]{4}-[0-9]{1,8}$/.test(document.nroDoc) ||
                            /^[EG][0-9]{2}-[0-9]{1,8}$/.test(document.nroDoc) ||
                            /^[G][0-9]{3}-[0-9]{1,8}$/.test(document.nroDoc)
                        )
                    ) document.warning.push('4006');
                }
                if (domDocumentHelper.select(path.guias.tipoDoc)[index]) {
                    document.tipoDoc = domDocumentHelper.select(path.guias.tipoDoc)[index].textContent;
                    if (document.tipoDoc && !catalog_documentTypeCode[document.tipoDoc] &&
                        !(
                            document.tipoDoc == '09' || document.tipoDoc == '31'
                        )) document.warning.push('4005');
                }
                if (domDocumentHelper.select(path.guias.tipoDoc_listAgencyName)[index])
                    document.tipoDoc_listAgencyName = domDocumentHelper.select(path.guias.tipoDoc_listAgencyName)[index].textContent;
                if (domDocumentHelper.select(path.guias.tipoDoc_listName)[index])
                    document.tipoDoc_listName = domDocumentHelper.select(path.guias.tipoDoc_listName)[index].textContent;
                if (domDocumentHelper.select(path.guias.tipoDoc_listURI)[index]) {
                    document.tipoDoc_listURI = domDocumentHelper.select(path.guias.tipoDoc_listURI)[index].textContent;
                    if (document.tipoDoc_listURI && document.tipoDoc_listURI != 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01') document.warning.push('4253');
                }
                if (guiasId[document.nroDoc]) throw new Error('2364');
                guiasId[document.nroDoc] = document;
                this.guias.push(document);
                this.warning = this.warning.concat(document.warning);
            }

            var relDocs = domDocumentHelper.select(path.relDocs['.']);
            var relDocsLength = relDocs.length ? relDocs.length : 0;
            var relDocsId = [];
            for (let index = 0; index < relDocsLength; index++) {
                var document = new Document();
                const rel = relDocs[index];
                if (domDocumentHelper.select(path.relDocs.nroDoc)[index]) {
                    document.nroDoc = domDocumentHelper.select(path.relDocs.nroDoc)[index].textContent;
                    if (document.nroDoc && catalog_taxRelatedDocumentCode[document.nroDoc] &&
                        !/^[A-Za-z0-9]{1,30}$/.test(document.nroDoc)
                    ) document.warning.push('4010');
                }
                if (domDocumentHelper.select(path.relDocs.tipoDoc)[index]) {
                    document.tipoDoc = domDocumentHelper.select(path.relDocs.tipoDoc)[index].textContent;
                    if (document.tipoDoc && !catalog_taxRelatedDocumentCode[document.tipoDoc] && !(
                            document.tipoDoc == '04' ||
                            document.tipoDoc == '05' ||
                            document.tipoDoc == '06' ||
                            document.tipoDoc == '07' ||
                            document.tipoDoc == '99' ||
                            document.tipoDoc == '01'
                        )) document.warning.push('4009');
                }
                if (domDocumentHelper.select(path.relDocs.tipoDoc_listAgencyName)[index])
                    document.tipoDoc_listAgencyName = domDocumentHelper.select(path.relDocs.tipoDoc_listAgencyName)[index].textContent;
                if (domDocumentHelper.select(path.relDocs.tipoDoc_listName)[index])
                    document.tipoDoc_listName = domDocumentHelper.select(path.relDocs.tipoDoc_listName)[index].textContent;
                if (domDocumentHelper.select(path.relDocs.tipoDoc_listURI)[index]) {
                    document.tipoDoc_listURI = domDocumentHelper.select(path.relDocs.tipoDoc_listURI)[index].textContent;
                    if (document.tipoDoc_listURI && document.tipoDoc_listURI != 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo12') document.warning.push('4253');
                }
                if (relDocsId[document.nroDoc]) throw new Error('2365');
                relDocsId[document.nroDoc] = document;
                this.relDocs.push(document);
                this.warning = this.warning.concat(document.warning);
            }

            this.warning = this.warning.concat(this.company.warning, this.company.address.warning, this.client.warning, this.client.address.warning);
            resolve(this.warning);
        });
    }
}

module.exports = Factura2_0Loader;