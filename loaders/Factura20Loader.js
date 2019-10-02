'use strict'

var moment = require('moment')

var BaseSale = require('../templates/BaseSale')
var SaleDetail = require('../templates/SaleDetail')

var DomDocumentHelper = require('../helpers/DomDocumentHelper')

var path = require('./ocpp/Factura2_0.json')

var catalogDocumentTypeCode = require('../catalogs/catalogDocumentTypeCode.json')
var catalogTaxRelatedDocumentCode = require('../catalogs/catalogTaxRelatedDocumentCode.json')
var listPadronContribuyente = require('../catalogs/listPadronContribuyente.json')
var listAutorizacionComprobanteContingencia = require('../catalogs/listAutorizacionComprobanteContingencia.json')
var listAutorizacionComprobanteFisico = require('../catalogs/listAutorizacionComprobanteFisico.json')
var listComprobantePagoElectronico = require('../catalogs/listComprobantePagoElectronico.json')
var parameterMaximunSendTerm = require('../catalogs/parameterMaximunSendTerm.json')

var Document = require('../templates/Document')

class Factura20Loader extends BaseSale {
  constructor (xml, fileInfo = null, domDocumentHelper = null) {
    super()
    this._xml = xml
    this._fileInfo = fileInfo || {
      rucEmisor: null,
      tipoComprobante: null,
      serieComprobante: null,
      correlativoComprobante: null
    }
    this._domDocumentHelper = domDocumentHelper || new DomDocumentHelper(xml)
  }

  get xml () {
    return this._xml
  }

  set xml (value) {
    this._xml = value
  }

  get fileInfo () {
    return this._fileInfo
  }

  set fileInfo (value) {
    this._fileInfo = value
  }

  get domDocumentHelper () {
    return this._domDocumentHelper
  }

  set domDocumentHelper (value) {
    this._domDocumentHelper = value
  }

  load (xml = this.xml, domDocumentHelper = this.domDocumentHelper) {
    return new Promise((resolve, reject) => {
      domDocumentHelper.mappingNameSpaces()

      this.ublVersion = domDocumentHelper.select(path.ublVersion)
      if (this.ublVersion !== '2.1') throw new Error('2074')
      this.customization = domDocumentHelper.select(path.customization)
      if (this.customization !== '2.0') throw new Error('2072')
      this.customization_schemeAgencyName = domDocumentHelper.select(path.customization_schemeAgencyName)

      this.id = domDocumentHelper.select(path.id)
      var matches = /^([A-Z0-9]{1,4})-([0-9]{1,8})$/.exec(this.id)
      if (matches[1] !== this.fileInfo.serieComprobante) throw new Error('1035')
      this.serie = matches[1]
      if (matches[2] !== this.fileInfo.correlativoComprobante) throw new Error('1036')
      this.correlativo = matches[2]
      var rucTipoSerie = this.fileInfo.rucEmisor + '-' + this.fileInfo.tipoComprobante + '-' + this.serie
      if (!/^[0-9]{1}/.test(this.serie) && (
        listComprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)] &&
          listComprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe === 1
      )) throw new Error('1033')
      if (/^[0-9]{1}/.test(this.serie) && (
        listComprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe &&
          listComprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe === 2
      )) throw new Error('1032')
      if (
        !/^[0-9]{1}/.test(this.serie) &&
        (
          listComprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)] && (
            listComprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe === 0 ||
            listComprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe === 2
          )
        )
      ) throw new Error('1032')
      if (/^[0-9]{1}/.test(this.serie)) {
        if (!(listAutorizacionComprobanteContingencia[rucTipoSerie] && (
          this.correlativo >= listAutorizacionComprobanteContingencia[rucTipoSerie].num_ini_cpe &&
            this.correlativo <= listAutorizacionComprobanteContingencia[rucTipoSerie].num_fin_cpe
        ))) throw new Error('3207')
        if (!(listAutorizacionComprobanteFisico[rucTipoSerie] && (
          this.correlativo >= listAutorizacionComprobanteFisico[rucTipoSerie].num_ini_cpe &&
            this.correlativo <= listAutorizacionComprobanteFisico[rucTipoSerie].num_fin_cpe
        ))) throw new Error('3207')
      }

      this.fechaEmision = domDocumentHelper.select(path.fechaEmision)
      if (!/^[0-9]{1}/.test(this.serie)) {
        if (
          moment().diff(moment(this.fechaEmision), 'days') > parameterMaximunSendTerm[this.fileInfo.tipoComprobante].day &&
          !domDocumentHelper.select(path.fechaVencimiento) &&
          moment().diff(moment(this.fechaEmision), 'days') >= 0
        ) throw new Error('2108')
      }
      this.horaEmision = domDocumentHelper.select(path.horaEmision)
      this.tipoDoc = domDocumentHelper.select(path.tipoDoc)
      if (this.tipoDoc !== this.fileInfo.tipoComprobante && catalogDocumentTypeCode[this.tipoDoc]) throw new Error('1003')
      this.tipoOperacion = domDocumentHelper.select(path.tipoOperacion)
      this.tipoDoc_listAgencyName = domDocumentHelper.select(path.tipoDoc_listAgencyName)
      this.tipoDoc_listName = domDocumentHelper.select(path.tipoDoc_listName)
      this.tipoDoc_listURI = domDocumentHelper.select(path.tipoDoc_listURI)
      this.tipoMoneda = domDocumentHelper.select(path.tipoMoneda)
      this.tipoMoneda_listID = domDocumentHelper.select(path.tipoMoneda_listID)
      this.tipoMoneda_listName = domDocumentHelper.select(path.tipoMoneda_listName)
      this.tipoMoneda_listAgencyName = domDocumentHelper.select(path.tipoMoneda_listAgencyName)
      this.fechaVencimiento = domDocumentHelper.select(path.fechaVencimiento)

      this.signature.id = domDocumentHelper.select(path.signature.id)
      this.signature.canonicalization_algorithm = domDocumentHelper.select(path.signature.canonicalization_algorithm)
      this.signature.signature_algorithm = domDocumentHelper.select(path.signature.signature_algorithm)
      this.signature.reference_uri = domDocumentHelper.select(path.signature.reference_uri)
      this.signature.transform_algorithm = domDocumentHelper.select(path.signature.transform_algorithm)
      this.signature.digest_algorithm = domDocumentHelper.select(path.signature.digest_algorithm)
      this.signature.digestValue = domDocumentHelper.select(path.signature.digestValue)
      this.signature.signatureValue = domDocumentHelper.select(path.signature.signatureValue)
      this.signature.x509Certificate = domDocumentHelper.select(path.signature.x509Certificate)
      this.signature.signature = domDocumentHelper.select(path.signature.signature)
      this.signature.signature_id = domDocumentHelper.select(path.signature.signature_id)
      this.signature.partyIdentificationId = domDocumentHelper.select(path.signature.partyIdentificationId)
      if (this.signature.partyIdentificationId !== this.fileInfo.rucEmisor) throw new Error('2078')
      this.signature.partyName = domDocumentHelper.select(path.signature.partyName)
      this.signature.externalReferenceUri = domDocumentHelper.select(path.signature.externalReferenceUri)

      this.company.ruc = domDocumentHelper.select(path.company.ruc)
      if (this.company.ruc !== this.fileInfo.rucEmisor) throw new Error('1034')
      if (
        this.tipoOperacion === '0201' &&
        listPadronContribuyente[this.company.ruc].ind_padron !== '05'
      ) throw new Error('3097')
      this.company.ruc_schemeId = domDocumentHelper.select(path.company.ruc_schemeId)
      this.company.ruc_schemeName = domDocumentHelper.select(path.company.ruc_schemeName)
      this.company.ruc_schemeAgencyName = domDocumentHelper.select(path.company.ruc_schemeAgencyName)
      this.company.ruc_schemeUri = domDocumentHelper.select(path.company.ruc_schemeUri)
      this.company.nombreComercial = domDocumentHelper.select(path.company.nombreComercial)
      this.company.razonSocial = domDocumentHelper.select(path.company.razonSocial)

      this.company.address.direccion = domDocumentHelper.select(path.company.address.direccion)
      this.company.address.urbanizacion = domDocumentHelper.select(path.company.address.urbanizacion)
      this.company.address.provincia = domDocumentHelper.select(path.company.address.provincia)
      this.company.address.ubigueo = domDocumentHelper.select(path.company.address.ubigueo)
      this.company.address.ubigueo_schemeAgencyName = domDocumentHelper.select(path.company.address.ubigueo_schemeAgencyName)
      this.company.address.ubigueo_schemeName = domDocumentHelper.select(path.company.address.ubigueo_schemeName)
      this.company.address.departamento = domDocumentHelper.select(path.company.address.departamento)
      this.company.address.distrito = domDocumentHelper.select(path.company.address.distrito)
      this.company.address.codigoPais = domDocumentHelper.select(path.company.address.codigoPais)
      this.company.address.codigoPais_listId = domDocumentHelper.select(path.company.address.codigoPais_listId)
      this.company.address.codigoPais_listAgencyName = domDocumentHelper.select(path.company.address.codigoPais_listAgencyName)
      this.company.address.codigoPais_listName = domDocumentHelper.select(path.company.address.codigoPais_listName)

      this.company.address.codLocal = domDocumentHelper.select(path.company.address.codLocal)
      this.company.address.codLocal_listAgencyName = domDocumentHelper.select(path.company.address.codLocal_listAgencyName)
      this.company.address.codLocal_listName = domDocumentHelper.select(path.company.address.codLocal_listName)

      this.client.numDoc = domDocumentHelper.select(path.client.numDoc)
      this.client.tipoDoc = domDocumentHelper.select(path.client.tipoDoc)
      if ((
        this.tipoOperacion === '0200' ||
          this.tipoOperacion === '0201' ||
          this.tipoOperacion === '0204' ||
          this.tipoOperacion === '0208'
      ) && this.client.tipoDoc === '6') throw new Error('2800')
      if (

        this.tipoOperacion === '0202' ||
        this.tipoOperacion === '0203' ||
        this.tipoOperacion === '0205' ||
        this.tipoOperacion === '0206' ||
        this.tipoOperacion === '0207' ||
        this.tipoOperacion === '0401'
      ) throw new Error('2800')
      // ICOMPLETO (ERROR : 2800)
      if (
        this.tipoOperacion === '0112 Venta Interna - Sustenta Gastos Deducibles Persona Natural' &&
        this.client.tipoDoc !== '1' && this.client.tipoDoc !== '6'
      ) throw new Error('2800')
      this.client.tipoDoc_schemeName = domDocumentHelper.select(path.client.tipoDoc_schemeName)
      this.client.tipoDoc_schemeAgencyName = domDocumentHelper.select(path.client.tipoDoc_schemeAgencyName)
      this.client.tipoDoc_schemeURI = domDocumentHelper.select(path.client.tipoDoc_schemeURI)
      this.client.rznSocial = domDocumentHelper.select(path.client.rznSocial)
      this.client.address.direccion = domDocumentHelper.select(path.client.address.direccion)

      var guiasLength = domDocumentHelper.select(path.guias['.']).length ? domDocumentHelper.select(path.guias['.']).length : 0
      var guiasId = {}
      var guias = {
        nroDoc: domDocumentHelper.select(path.guias.nroDoc),
        tipoDoc: domDocumentHelper.select(path.guias.tipoDoc),
        tipoDoc_listAgencyName: domDocumentHelper.select(path.guias.tipoDoc_listAgencyName),
        tipoDoc_listName: domDocumentHelper.select(path.guias.tipoDoc_listName),
        tipoDoc_listURI: domDocumentHelper.select(path.guias.tipoDoc_listURI)
      }
      for (let index = 0, document; index < guiasLength; index++) {
        document = new Document()
        if (guias.nroDoc[index]) {
          document.nroDoc = guias.nroDoc[index].textContent
          if (document.nroDoc &&
            !(
              /^[T][0-9]{3}-[0-9]{1,8}-[0-9]{4}-[0-9]{1,8}$/.test(document.nroDoc) ||
              /^[0-9]{4}-[0-9]{1,8}$/.test(document.nroDoc) ||
              /^[EG][0-9]{2}-[0-9]{1,8}$/.test(document.nroDoc) ||
              /^[G][0-9]{3}-[0-9]{1,8}$/.test(document.nroDoc)
            )
          ) document.warning.push('4006')
        }
        if (guias.tipoDoc[index]) {
          document.tipoDoc = guias.tipoDoc[index].textContent
          if (document.tipoDoc && !catalogDocumentTypeCode[document.tipoDoc] &&
            !(
              document.tipoDoc === '09' || document.tipoDoc === '31'
            )) document.warning.push('4005')
        }
        if (guias.tipoDoc_listAgencyName[index]) {
          document.tipoDoc_listAgencyName = guias.tipoDoc_listAgencyName[index].textContent
        }
        if (guias.tipoDoc_listName[index]) {
          document.tipoDoc_listName = guias.tipoDoc_listName[index].textContent
        }
        if (guias.tipoDoc_listURI[index]) {
          document.tipoDoc_listURI = guias.tipoDoc_listURI[index].textContent
          if (document.tipoDoc_listURI && document.tipoDoc_listURI !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01') document.warning.push('4253')
        }
        if (guiasId[document.nroDoc]) throw new Error('2364')
        guiasId[document.nroDoc] = document
        this.guias.push(document)
        this.warning = this.warning.concat(document.warning)
      }

      var relDocsLength = domDocumentHelper.select(path.relDocs['.']).length ? domDocumentHelper.select(path.relDocs['.']).length : 0
      var relDocsId = {}
      var relDocs = {
        nroDoc: domDocumentHelper.select(path.relDocs.nroDoc),
        tipoDoc: domDocumentHelper.select(path.relDocs.tipoDoc),
        tipoDoc_listAgencyName: domDocumentHelper.select(path.relDocs.tipoDoc_listAgencyName),
        tipoDoc_listName: domDocumentHelper.select(path.relDocs.tipoDoc_listName),
        tipoDoc_listURI: domDocumentHelper.select(path.relDocs.tipoDoc_listURI)
      }
      for (let index = 0, document; index < relDocsLength; index++) {
        document = new Document()
        if (relDocs.nroDoc[index]) {
          document.nroDoc = relDocs.nroDoc[index].textContent
          if (document.nroDoc && catalogTaxRelatedDocumentCode[document.nroDoc] &&
            !/^[A-Za-z0-9]{1,30}$/.test(document.nroDoc)
          ) document.warning.push('4010')
        }
        if (relDocs.tipoDoc[index]) {
          document.tipoDoc = relDocs.tipoDoc[index].textContent
          if (document.tipoDoc && !catalogTaxRelatedDocumentCode[document.tipoDoc] && !(
            document.tipoDoc === '04' ||
              document.tipoDoc === '05' ||
              document.tipoDoc === '06' ||
              document.tipoDoc === '07' ||
              document.tipoDoc === '99' ||
              document.tipoDoc === '01'
          )) document.warning.push('4009')
        }
        if (relDocs.tipoDoc_listAgencyName[index]) {
          document.tipoDoc_listAgencyName = relDocs.tipoDoc_listAgencyName[index].textContent
        }
        if (relDocs.tipoDoc_listName[index]) {
          document.tipoDoc_listName = relDocs.tipoDoc_listName[index].textContent
        }
        if (relDocs.tipoDoc_listURI[index]) {
          document.tipoDoc_listURI = relDocs.tipoDoc_listURI[index].textContent
          if (document.tipoDoc_listURI && document.tipoDoc_listURI !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo12') document.warning.push('4253')
        }
        if (relDocsId[document.nroDoc]) throw new Error('2365')
        relDocsId[document.nroDoc] = document
        this.relDocs.push(document)
        this.warning = this.warning.concat(document.warning)
      }

      var detailsLength = domDocumentHelper.select(path.details['.']) ? domDocumentHelper.select(path.details['.']).length : 0
      var detailsId = {}
      var detailsCodProducto = {}
      var details = {
        id: domDocumentHelper.select(path.details.id),
        unidad: domDocumentHelper.select(path.details.unidad),
        unidad_unitCodeListId: domDocumentHelper.select(path.details.unidad_unitCodeListId),
        unidad_unitCodeListAgencyName: domDocumentHelper.select(path.details.unidad_unitCodeListAgencyName),
        cantidad: domDocumentHelper.select(path.details.cantidad),
        codProducto: domDocumentHelper.select(path.details.codProducto),
        codProdSunat: domDocumentHelper.select(path.details.codProdSunat),
        codProdSunat_listID: domDocumentHelper.select(path.details.codProdSunat_listID),
        codProdSunat_listAgencyName: domDocumentHelper.select(path.details.codProdSunat_listAgencyName),
        codProdSunat_listName: domDocumentHelper.select(path.details.codProdSunat_listName),
        codProdGS1_schemeId: domDocumentHelper.select(path.details.codProdGS1_schemeId),
        codProdGS1: domDocumentHelper.select(path.details.codProdGS1),
        descripcion: domDocumentHelper.select(path.details.descripcion),
        mtoValorUnitario: domDocumentHelper.select(path.details.mtoValorUnitario)

      }
      for (let index = 0; index < detailsLength; index++) {
        var saleDetail = new SaleDetail()
        saleDetail.id = details.id[index] ? details.id[index].textContent : null
        saleDetail.unidad = details.unidad[index] ? details.unidad[index].textContent : null
        saleDetail.unidad_unitCodeListId = details.unidad_unitCodeListId[index] ? details.unidad_unitCodeListId[index].textContent : null
        saleDetail.unidad_unitCodeListAgencyName = details.unidad_unitCodeListAgencyName[index] ? details.unidad_unitCodeListAgencyName[index].textContent : null
        saleDetail.cantidad = details.cantidad[index] ? details.cantidad[index].textContent : null
        saleDetail.codProducto = details.codProducto[index] ? details.codProducto[index].textContent : null
        saleDetail.codProdSunat = details.codProdSunat[index] ? details.codProdSunat[index].textContent : null
        saleDetail.codProdSunat_listID = details.codProdSunat_listID[index] ? details.codProdSunat_listID[index].textContent : null
        saleDetail.codProdSunat_listAgencyName = details.codProdSunat_listAgencyName[index] ? details.codProdSunat_listAgencyName[index].textContent : null
        saleDetail.codProdSunat_listName = details.codProdSunat_listName[index] ? details.codProdSunat_listName[index].textContent : null
        saleDetail.codProdGS1_schemeId = details.codProdGS1_schemeId[index] ? details.codProdGS1_schemeId[index].textContent : null
        saleDetail.codProdGS1 = details.codProdGS1[index] ? details.codProdGS1[index].textContent : null
        saleDetail.descripcion = details.descripcion[index] ? details.descripcion[index].textContent : null
        saleDetail.mtoValorUnitario = details.mtoValorUnitario[index] ? details.mtoValorUnitario[index].textContent : null

        if (listPadronContribuyente[this.company.ruc].ind_padron === 12 && !saleDetail.codProdSunat && !saleDetail.codProdGS1) saleDetail.warning.push('4331')

        if (detailsId[saleDetail.id]) throw new Error('2752')
        detailsId[saleDetail.id] = saleDetail
        detailsCodProducto[saleDetail.codProdSunat] = saleDetail.codProdSunat
        this.details.push(saleDetail)
        this.warning = this.warning.concat(saleDetail.warning)
      }
      if (this.tipoOperacion === '0112' && !(detailsCodProducto['84121901'] || detailsCodProducto['80131501'])) throw new Error('3181')

      this.warning = this.warning.concat(this.company.warning, this.company.address.warning, this.client.warning, this.client.address.warning)
      resolve(this.warning)
    })
  }
}

module.exports = Factura20Loader
