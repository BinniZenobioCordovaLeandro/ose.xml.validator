'use strict'

var moment = require('moment')

var Invoice = require('../templates/Invoice')
var Document = require('../templates/Document')
var SaleDetail = require('../templates/SaleDetail')
var DetailAttribute = require('../templates/DetailAttribute')
var TaxDetail = require('../templates/TaxDetail')
var Charge = require('../templates/Charge')
var Legend = require('../templates/Legend')
var Prepayment = require('../templates/Prepayment')

var DomDocumentHelper = require('../helpers/DomDocumentHelper')

var path = require('./ocpp/Factura2_0.json')

var catalogDocumentTypeCode = require('../catalogs/catalogDocumentTypeCode.json')
var catalogTaxRelatedDocumentCode = require('../catalogs/catalogTaxRelatedDocumentCode.json')
var listContribuyente = require('../catalogs/listContribuyente.json')
var listPadronContribuyente = require('../catalogs/listPadronContribuyente.json')
var listAutorizacionComprobanteContingencia = require('../catalogs/listAutorizacionComprobanteContingencia.json')
var listAutorizacionComprobanteFisico = require('../catalogs/listAutorizacionComprobanteFisico.json')
var listComprobantePagoElectronico = require('../catalogs/listComprobantePagoElectronico.json')
var parameterMaximunSendTerm = require('../catalogs/parameterMaximunSendTerm.json')
var catalogIgvAffectationTypeCode = require('../catalogs/catalogIgvAffectationTypeCode.json')
var catalogTaxTypeCode = require('../catalogs/catalogTaxTypeCode.json')
var catalogIscCalculationSystemTypeCode = require('../catalogs/catalogIscCalculationSystemTypeCode.json')
var catalogChargeCode = require('../catalogs/catalogChargeCode.json')
var catalogGeograficLocationCode = require('../catalogs/catalogGeograficLocationCode.json')
var catalogIdentityDocumentTypeCode = require('../catalogs/catalogIdentityDocumentTypeCode.json')
var catalogServiceCodeSubjectDetraction = require('../catalogs/catalogServiceCodeSubjectDetraction.json')

class Factura20Loader extends Invoice {
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
      this.customizationSchemeAgencyName = domDocumentHelper.select(path.customizationSchemeAgencyName)

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
      this.tipoOperacionName = domDocumentHelper.select(path.tipoOperacionName)
      this.tipoOperacionListSchemeUri = domDocumentHelper.select(path.tipoOperacionListSchemeUri)
      this.tipoDocListAgencyName = domDocumentHelper.select(path.tipoDocListAgencyName)
      this.tipoDocListName = domDocumentHelper.select(path.tipoDocListName)
      this.tipoDocListURI = domDocumentHelper.select(path.tipoDocListURI)
      this.tipoMoneda = domDocumentHelper.select(path.tipoMoneda)
      this.tipoMonedaListID = domDocumentHelper.select(path.tipoMonedaListID)
      this.tipoMonedaListName = domDocumentHelper.select(path.tipoMonedaListName)
      this.tipoMonedaListAgencyName = domDocumentHelper.select(path.tipoMonedaListAgencyName)
      this.compra = domDocumentHelper.select(path.compra)
      this.fechaVencimiento = domDocumentHelper.select(path.fechaVencimiento)
      this.signature.id = domDocumentHelper.select(path.signature.id)
      this.signature.canonicalizationAlgorithm = domDocumentHelper.select(path.signature.canonicalizationAlgorithm)
      this.signature.signatureAlgorithm = domDocumentHelper.select(path.signature.signatureAlgorithm)
      this.signature.reference_uri = domDocumentHelper.select(path.signature.reference_uri)
      this.signature.transformAlgorithm = domDocumentHelper.select(path.signature.transformAlgorithm)
      this.signature.digestAlgorithm = domDocumentHelper.select(path.signature.digestAlgorithm)
      this.signature.digestValue = domDocumentHelper.select(path.signature.digestValue)
      this.signature.signatureValue = domDocumentHelper.select(path.signature.signatureValue)
      this.signature.x509Certificate = domDocumentHelper.select(path.signature.x509Certificate)
      this.signature.signature = domDocumentHelper.select(path.signature.signature)
      this.signature.signatureId = domDocumentHelper.select(path.signature.signatureId)
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
      this.company.rucSchemeId = domDocumentHelper.select(path.company.rucSchemeId)
      this.company.rucSchemeName = domDocumentHelper.select(path.company.rucSchemeName)
      this.company.rucSchemeAgencyName = domDocumentHelper.select(path.company.rucSchemeAgencyName)
      this.company.rucSchemeUri = domDocumentHelper.select(path.company.rucSchemeUri)
      this.company.nombreComercial = domDocumentHelper.select(path.company.nombreComercial)
      this.company.razonSocial = domDocumentHelper.select(path.company.razonSocial)

      this.company.address.direccion = domDocumentHelper.select(path.company.address.direccion)
      this.company.address.urbanizacion = domDocumentHelper.select(path.company.address.urbanizacion)
      this.company.address.provincia = domDocumentHelper.select(path.company.address.provincia)
      this.company.address.ubigueo = domDocumentHelper.select(path.company.address.ubigueo)
      this.company.address.ubigueoSchemeAgencyName = domDocumentHelper.select(path.company.address.ubigueoSchemeAgencyName)
      this.company.address.ubigueoSchemeName = domDocumentHelper.select(path.company.address.ubigueoSchemeName)
      this.company.address.departamento = domDocumentHelper.select(path.company.address.departamento)
      this.company.address.distrito = domDocumentHelper.select(path.company.address.distrito)
      this.company.address.codigoPais = domDocumentHelper.select(path.company.address.codigoPais)
      this.company.address.codigoPaisListId = domDocumentHelper.select(path.company.address.codigoPaisListId)
      this.company.address.codigoPaisListAgencyName = domDocumentHelper.select(path.company.address.codigoPaisListAgencyName)
      this.company.address.codigoPaisListName = domDocumentHelper.select(path.company.address.codigoPaisListName)

      this.company.address.codLocal = domDocumentHelper.select(path.company.address.codLocal)
      this.company.address.codLocalListAgencyName = domDocumentHelper.select(path.company.address.codLocalListAgencyName)
      this.company.address.codLocalListName = domDocumentHelper.select(path.company.address.codLocalListName)

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
      // COMPLETO (ERROR : 2800)
      if (
        this.tipoOperacion === '0112 Venta Interna - Sustenta Gastos Deducibles Persona Natural' &&
        this.client.tipoDoc !== '1' && this.client.tipoDoc !== '6'
      ) throw new Error('2800')
      this.client.tipoDocSchemeName = domDocumentHelper.select(path.client.tipoDocSchemeName)
      this.client.tipoDocSchemeAgencyName = domDocumentHelper.select(path.client.tipoDocSchemeAgencyName)
      this.client.tipoDocSchemeURI = domDocumentHelper.select(path.client.tipoDocSchemeURI)
      this.client.rznSocial = domDocumentHelper.select(path.client.rznSocial)
      this.client.address.direccion = domDocumentHelper.select(path.client.address.direccion)

      var guiasLength = domDocumentHelper.select(path.guias['.']).length ? domDocumentHelper.select(path.guias['.']).length : 0
      var guiasId = {}
      var guias = {
        nroDoc: domDocumentHelper.select(path.guias.nroDoc),
        tipoDoc: domDocumentHelper.select(path.guias.tipoDoc),
        tipoDocListAgencyName: domDocumentHelper.select(path.guias.tipoDocListAgencyName),
        tipoDocListName: domDocumentHelper.select(path.guias.tipoDocListName),
        tipoDocListURI: domDocumentHelper.select(path.guias.tipoDocListURI)
      }
      for (let index = 0, document; index < guiasLength; index++) {
        document = new Document()
        document.nroDoc = guias.nroDoc[index] ? guias.nroDoc[index].textContent : null
        if (document.nroDoc &&
          !(
            /^[T][0-9]{3}-[0-9]{1,8}-[0-9]{4}-[0-9]{1,8}$/.test(document.nroDoc) ||
            /^[0-9]{4}-[0-9]{1,8}$/.test(document.nroDoc) ||
            /^[EG][0-9]{2}-[0-9]{1,8}$/.test(document.nroDoc) ||
            /^[G][0-9]{3}-[0-9]{1,8}$/.test(document.nroDoc)
          )
        ) document.warning.push('4006')
        document.tipoDoc = guias.tipoDoc[index] ? guias.tipoDoc[index].textContent : null
        if (document.tipoDoc && !catalogDocumentTypeCode[document.tipoDoc] &&
          !(
            document.tipoDoc === '09' || document.tipoDoc === '31'
          )) document.warning.push('4005')
        document.tipoDocListAgencyName = guias.tipoDocListAgencyName[index] ? guias.tipoDocListAgencyName[index].textContent : null
        document.tipoDocListName = guias.tipoDocListName[index] ? guias.tipoDocListName[index].textContent : null
        document.tipoDocListURI = guias.tipoDocListURI[index] ? guias.tipoDocListURI[index].textContent : null
        if (document.tipoDocListURI && document.tipoDocListURI !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01') document.warning.push('4253')
        if (guiasId[document.nroDoc]) throw new Error('2364')
        guiasId[document.nroDoc] = document
        this.guias.push(document)
        this.warning = this.warning.concat(document.warning)
      }

      var relDocsLength = domDocumentHelper.select(path.relDocs['.']).length ? domDocumentHelper.select(path.relDocs['.']).length : 0
      var relDocsId = {}
      var relDocsPayIdentifier = {}
      var relDocs = {
        nroDoc: domDocumentHelper.select(path.relDocs.nroDoc),
        tipoDoc: domDocumentHelper.select(path.relDocs.tipoDoc),
        tipoDocListAgencyName: domDocumentHelper.select(path.relDocs.tipoDocListAgencyName),
        tipoDocListName: domDocumentHelper.select(path.relDocs.tipoDocListName),
        tipoDocListURI: domDocumentHelper.select(path.relDocs.tipoDocListURI),
        payIdentifier: domDocumentHelper.select(path.relDocs.payIdentifier),
        payIdentifierListName: domDocumentHelper.select(path.relDocs.payIdentifierListName),
        payIdentifierListAgencyName: domDocumentHelper.select(path.relDocs.payIdentifierListAgencyName),
        docEmisor: domDocumentHelper.select(path.relDocs.docEmisor),
        docEmisorSchemeName: domDocumentHelper.select(path.relDocs.docEmisorSchemeName),
        docEmisorSchemeAgencyName: domDocumentHelper.select(path.relDocs.docEmisorSchemeAgencyName),
        docEmisorSchemeURI: domDocumentHelper.select(path.relDocs.docEmisorSchemeURI),
        tipoDocEmisor: domDocumentHelper.select(path.relDocs.tipoDocEmisor)
      }
      for (let index = 0, document; index < relDocsLength; index++) {
        document = new Document()
        document.nroDoc = relDocs.nroDoc[index] ? relDocs.nroDoc[index].textContent : null
        if (document.nroDoc && !/^[A-Za-z0-9]{1,30}$/.test(document.nroDoc)) document.warning.push('4010')
        document.tipoDoc = relDocs.tipoDoc[index] ? relDocs.tipoDoc[index].textContent : null
        if (document.tipoDoc && !catalogTaxRelatedDocumentCode[document.tipoDoc] && !(
          document.tipoDoc === '04' ||
              document.tipoDoc === '05' ||
              document.tipoDoc === '06' ||
              document.tipoDoc === '07' ||
              document.tipoDoc === '99' ||
              document.tipoDoc === '01'
        )) document.warning.push('4009')
        document.tipoDocListAgencyName = relDocs.tipoDocListAgencyName[index] ? relDocs.tipoDocListAgencyName[index].textContent : null
        document.tipoDocListName = relDocs.tipoDocListName[index] ? relDocs.tipoDocListName[index].textContent : null
        document.tipoDocListURI = relDocs.tipoDocListURI[index] ? relDocs.tipoDocListURI[index].textContent : null
        if (document.tipoDocListURI && document.tipoDocListURI !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo12') this.warning.push('4253')
        document.payIdentifier = relDocs.payIdentifier[index] ? relDocs.payIdentifier[index].textContent : null
        if ((document.tipoDoc === '02' || document.tipoDoc === '03')) throw new Error('3214') // PEDIENTE
        // Si 'Tipo de comprobante que se realizó el anticipo' es '02' o '03', y no existe un 'Importe del anticipo' con 'Identificador de pago' igual al valor del tag UBL
        if ((document.tipoDoc === '02' || document.tipoDoc === '03') && relDocsPayIdentifier[document.payIdentifier]) throw new Error('3215')
        if ((document.tipoDoc === '02' || document.tipoDoc === '03') && !document.payIdentifier) throw new Error('3216')
        if (document.payIdentifier && !(document.tipoDoc === '02' || document.tipoDoc === '03')) throw new Error('2505')
        document.payIdentifierListName = relDocs.payIdentifierListName[index] ? relDocs.payIdentifierListName[index].textContent : null
        document.payIdentifierListAgencyName = relDocs.payIdentifierListAgencyName[index] ? relDocs.payIdentifierListAgencyName[index].textContent : null
        document.docEmisor = relDocs.docEmisor[index] ? relDocs.docEmisor[index] : null
        if (document.payIdentifier && !document.docEmisor) throw new Error('3217')
        if (document.payIdentifier && !listContribuyente[document.docEmisor]) throw new Error('2529')
        if (document.payIdentifier && (
          /^[B]{1}/.test(document.nroDoc) ||
            /^[F]{1}/.test(document.nroDoc) ||
            /^[E]{1}/.test(document.nroDoc)
        ) && document.docEmisor === this.fileInfo.rucEmisor &&
          (
            listComprobantePagoElectronico[document.tipoDoc] &&
            listComprobantePagoElectronico[document.tipoDoc].num_ruc &&
            listComprobantePagoElectronico[document.tipoDoc].ind_estado_cpe === '1'
          )
        ) throw new Error('3218') // REVIEW
        // Si existe identificador de pago (cbc:DocumentStatusCode) y 'Serie del comprobante que realizó el anticipo' empieza con B o F o E, y RUC del emisor del anticipo es igual al RUC emisor de la factura, la 'Serie y número del comprobante que realizó el anticipo' no existe con estado aceptado en el listado para el RUC consignado en el emisor del anticipo
        if (document.payIdentifier && /^[0-9]{1}/.test(document.nroDoc) &&
          document.docEmisor === this.fileInfo.rucEmisor &&
          (
            listAutorizacionComprobanteFisico[document.tipoDoc] &&
            listAutorizacionComprobanteFisico[document.tipoDoc].num_ruc &&
            listAutorizacionComprobanteFisico[document.tipoDoc].ind_estado_cpe === '1'
          )
        ) document.warning.push('3219') // REVIEW
        // Si existe identificador de pago (cbc:DocumentStatusCode) y 'Serie del comprobante que realizó el anticipo' empieza con número, y RUC del emisor del anticipo es igual al RUC emisor de la factura, la 'Serie y número del comprobante que realizó el anticipo' no existe en el listado para el RUC consignado en el emisor del anticipo
        document.docEmisorSchemeName = relDocs.docEmisorSchemeName[index] ? relDocs.docEmisorSchemeName[index].textContent : null
        document.docEmisorSchemeAgencyName = relDocs.docEmisorSchemeAgencyName[index] ? relDocs.docEmisorSchemeAgencyName[index].textContent : null
        document.docEmisorSchemeURI = relDocs.docEmisorSchemeURI[index] ? relDocs.docEmisorSchemeURI[index].textContent : null

        document.tipoDocEmisor = relDocs.tipoDocEmisor[index] ? relDocs.tipoDocEmisor[index] : null
        if (document.tipoDocEmisor && document.tipoDoc === '02' && !(
          /^[F][A-Z0-9]{3}-[0-9]{1,8}$/.test(document.nroDoc) ||
          /^(E001)-[0-9]{1,8}$/.test(document.nroDoc) ||
          /^[0-9]{1,4}-[0-9]{1,8}$/.test(document.nroDoc)
        )) throw new Error('2521')
        if (document.tipoDocEmisor && document.tipoDoc === '03' && !(
          /^[B][A-Z0-9]{3}-[0-9]{1,8}$/.test(document.nroDoc) ||
          /^(EB01)-[0-9]{1,8}$/.test(document.nroDoc) ||
          /^[0-9]{1,4}-[0-9]{1,8}$/.test(document.nroDoc)
        )) throw new Error('2521')
        if (relDocsId[document.nroDoc]) throw new Error('2365')
        relDocsId[document.nroDoc] = document
        relDocsPayIdentifier[document.payIdentifier] = document
        this.relDocs.push(document)
        this.warning = this.warning.concat(document.warning)
      }

      var detailsLength = domDocumentHelper.select(path.details['.']) ? domDocumentHelper.select(path.details['.']).length : 0
      var detailsId = {}
      var detailsCodProducto = {}
      var details = {
        id: domDocumentHelper.select(path.details.id),
        unidad: domDocumentHelper.select(path.details.unidad),
        unidadUnitCodeListId: domDocumentHelper.select(path.details.unidadUnitCodeListId),
        unidadUnitCodeListAgencyName: domDocumentHelper.select(path.details.unidadUnitCodeListAgencyName),
        cantidad: domDocumentHelper.select(path.details.cantidad),
        codProducto: domDocumentHelper.select(path.details.codProducto),
        codProdSunat: domDocumentHelper.select(path.details.codProdSunat),
        codProdSunatListId: domDocumentHelper.select(path.details.codProdSunatListId),
        codProdSunatListAgencyName: domDocumentHelper.select(path.details.codProdSunatListAgencyName),
        codProdSunatListName: domDocumentHelper.select(path.details.codProdSunatListName),
        codProdGs1SchemeId: domDocumentHelper.select(path.details.codProdGs1SchemeId),
        codProdGs1: domDocumentHelper.select(path.details.codProdGs1),
        atributos: {},
        descripcion: domDocumentHelper.select(path.details.descripcion),
        mtoValorUnitario: domDocumentHelper.select(path.details.mtoValorUnitario),
        mtoValorUnitarioCurrencyId: domDocumentHelper.select(path.details.mtoValorUnitarioCurrencyId),
        mtoType: domDocumentHelper.select(path.details.mtoType),
        mtoTypeListName: domDocumentHelper.select(path.details.mtoTypeListName),
        mtoTypeListAgencyName: domDocumentHelper.select(path.details.mtoTypeListAgencyName),
        mtoTypeListUri: domDocumentHelper.select(path.details.mtoTypeListUri),
        mtoPrecioUnitario: domDocumentHelper.select(path.details.mtoPrecioUnitario),
        mtoPrecioUnitarioCurrencyId: domDocumentHelper.select(path.details.mtoPrecioUnitarioCurrencyId),
        mtoValorGratuito: domDocumentHelper.select(path.details.mtoValorGratuito),
        mtoValorGratuitoCurrencyId: domDocumentHelper.select(path.details.mtoValorGratuitoCurrencyId),
        totalTax: {
          taxDetails: {}
        },
        mtoValorVenta: domDocumentHelper.select(path.details.mtoValorVenta),
        mtoValorVentaCurrencyId: domDocumentHelper.select(path.details.mtoValorVentaCurrencyId),
        cargos: {}
      }
      for (let index = 0; index < detailsLength; index++) {
        var saleDetail = new SaleDetail()
        saleDetail.id = details.id[index] ? details.id[index].textContent : null
        saleDetail.unidad = details.unidad[index] ? details.unidad[index].textContent : null
        saleDetail.unidadUnitCodeListId = details.unidadUnitCodeListId[index] ? details.unidadUnitCodeListId[index].textContent : null
        saleDetail.unidadUnitCodeListAgencyName = details.unidadUnitCodeListAgencyName[index] ? details.unidadUnitCodeListAgencyName[index].textContent : null
        saleDetail.cantidad = details.cantidad[index] ? details.cantidad[index].textContent : null
        saleDetail.codProducto = details.codProducto[index] ? details.codProducto[index].textContent : null
        saleDetail.codProdSunat = details.codProdSunat[index] ? details.codProdSunat[index].textContent : null
        saleDetail.codProdSunatListId = details.codProdSunatListId[index] ? details.codProdSunatListId[index].textContent : null
        saleDetail.codProdSunatListAgencyName = details.codProdSunatListAgencyName[index] ? details.codProdSunatListAgencyName[index].textContent : null
        saleDetail.codProdSunatListName = details.codProdSunatListName[index] ? details.codProdSunatListName[index].textContent : null
        saleDetail.codProdGS1SchemeId = details.codProdGs1SchemeId[index] ? details.codProdGs1SchemeId[index].textContent : null
        saleDetail.codProdGs1 = details.codProdGs1[index] ? details.codProdGs1[index].textContent : null

        details.atributosLength = domDocumentHelper.select(path.details.atributos['.']) ? domDocumentHelper.select(path.details.atributos['.']).length : 0
        details.atributosCode = {}
        details.atributos = {
          name: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.name}`),
          code: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.code}`),
          codeListName: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.codeListName}`),
          codeListAgencyName: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.codeListAgencyName}`),
          codeListURI: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.codeListURI}`),
          value: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.value}`),
          fecInicio: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.fecInicio}`),
          horInicio: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.horInicio}`),
          fecFin: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.fecFin}`),
          duracion: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.duracion}`)
        }
        for (let index = 0; index < details.atributosLength; index++) {
          var detailAttribute = new DetailAttribute()
          detailAttribute.name = details.atributos.name[index] ? details.atributos.name[index].textContent : null
          detailAttribute.code = details.atributos.code[index] ? details.atributos.code[index].textContent : null
          detailAttribute.codeListName = details.atributos.codeListName[index] ? details.atributos.codeListName[index].textContent : null
          detailAttribute.codeListAgencyName = details.atributos.codeListAgencyName[index] ? details.atributos.codeListAgencyName[index].textContent : null
          detailAttribute.codeListURI = details.atributos.codeListURI[index] ? details.atributos.codeListURI[index].textContent : null
          detailAttribute.value = details.atributos.value[index] ? details.atributos.value[index].textContent : null
          if ((detailAttribute.code === '3001' ||
              detailAttribute.code === '3002' ||
              detailAttribute.code === '3003' ||
              detailAttribute.code === '3004') &&
            (!detailAttribute.value || detailAttribute.value === '')
          ) throw new Error('3064')
          if (detailAttribute.code === '3001' && /[\w ]{1,15}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '3002' && /[\w ]{1,100}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '3003' && /[\w ]{1,150}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '3004' && /[\w ]{1,100}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')

          if ((
            detailAttribute.code === '3050' ||
            detailAttribute.code === '3051' ||
            detailAttribute.code === '3052' ||
            detailAttribute.code === '3053' ||
            detailAttribute.code === '3054' ||
            detailAttribute.code === '3055' ||
            detailAttribute.code === '3056' ||
            detailAttribute.code === '3057' ||
            detailAttribute.code === '3058') &&
            (!detailAttribute.value || detailAttribute.value === '')
          ) detailAttribute.warning.push('3064')
          if (detailAttribute.code === '3050' && !/[\w]{1,20}/.test(detailAttribute.value)) detailAttribute.warning.push('3064')
          if (detailAttribute.code === '3051' && !/[\w]{3,20}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '3052' && !/[\w]{3,15}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '3053' && !catalogIdentityDocumentTypeCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '3054' && !/[\w]{3,200}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '3055' && !catalogGeograficLocationCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '3056' && !/[\w]{3,200}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '3057' && !catalogGeograficLocationCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '3058' && !/[\w]{3,200}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '7000' && !detailAttribute.value) throw new Error('3064') // PENDIENTE // De existir 'Código del concepto' igual a '7000' y no existe el tag.
          detailAttribute.fecInicio = details.atributos.fecInicio[index] ? details.atributos.fecInicio[index].textContent : null
          if (detailAttribute.code === '3059' && !detailAttribute.fecInicio) detailAttribute.warning.push('3065')
          detailAttribute.horInicio = details.atributos.horInicio[index] ? details.atributos.horInicio[index].textContent : null
          if (detailAttribute.code === '3060' && !detailAttribute.horInicio) throw new Error('3172')
          detailAttribute.fecFin = details.atributos.fecFin[index] ? details.atributos.fecFin[index].textContent : null
          detailAttribute.duracion = details.atributos.duracion[index] ? details.atributos.duracion[index].textContent : null

          details.atributosCode[detailAttribute.code] = detailAttribute
          saleDetail.warning = saleDetail.warning.concat(detailAttribute.warning)
        }
        if (this.tipoOperacion === '1002' && !details.atributosCode['3001']) throw new Error('3063')
        if (this.tipoOperacion === '1002' && !details.atributosCode['3002']) throw new Error('3130')
        if (this.tipoOperacion === '1002' && !details.atributosCode['3003']) throw new Error('3131')
        if (this.tipoOperacion === '1002' && !details.atributosCode['3004']) throw new Error('3132')

        saleDetail.descripcion = details.descripcion[index] ? details.descripcion[index].textContent : null
        saleDetail.mtoValorUnitario = details.mtoValorUnitario[index] ? details.mtoValorUnitario[index].textContent : null
        saleDetail.mtoValorUnitarioCurrencyId = details.mtoValorUnitarioCurrencyId[index] ? details.mtoValorUnitarioCurrencyId[index].textContent : null
        if (saleDetail.mtoValorUnitarioCurrencyId && saleDetail.mtoValorUnitarioCurrencyId !== this.tipoMoneda) throw new Error('2071')
        if (Number(details.mtoValorGratuito[index].length) > 0) throw new Error(2409)
        saleDetail.mtoType = details.mtoType[index] ? details.mtoType[index].textContent : null
        saleDetail.mtoTypeListName = details.mtoTypeListName[index] ? details.mtoTypeListName[index].textContent : null
        saleDetail.mtoTypeListAgencyName = details.mtoTypeListAgencyName[index] ? details.mtoTypeListAgencyName[index].textContent : null
        saleDetail.mtoTypeListUri = details.mtoTypeListUri[index] ? details.mtoTypeListUri[index].textContent : null
        if (saleDetail.mtoType === '02') {
          saleDetail.mtoPrecioUnitario = details.mtoPrecioUnitario[index] ? details.mtoPrecioUnitario[index].textContent : null
          saleDetail.mtoPrecioUnitarioCurrencyId = details.mtoPrecioUnitarioCurrencyId[index] ? details.mtoPrecioUnitarioCurrencyId[index] : null
          if (saleDetail.mtoPrecioUnitarioCurrencyId !== this.tipoMoneda) throw new Error('2071')
        } else if (saleDetail.mtoType === '01') {
          saleDetail.mtoValorGratuito = details.mtoValorGratuito[index] ? details.mtoValorGratuito[index].textContent : null
          saleDetail.mtoValorGratuitoCurrencyId = details.mtoValorGratuitoCurrencyId[index] ? details.mtoValorGratuitoCurrencyId[index].textContent : null
        }
        saleDetail.mtoValorVenta = details.mtoValorVenta[index] ? details.mtoValorVenta[index].textContent : null

        details.totalTaxLength = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax['.']}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax['.']}`).length : 0
        if (Number(details.totalTaxLength) > 1) throw new Error('3026')
        if (!Number(details.totalTaxLength)) throw new Error('3195')
        details.totalTax.taxAmount = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxAmount}`)
        details.totalTax.taxAmountCurrencyId = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxAmountCurrencyId}`)
        saleDetail.totalTax.taxAmount = (details.totalTax.taxAmount && details.totalTax.taxAmount.length === 1) ? details.totalTax.taxAmount[0].textContent : null
        saleDetail.totalTax.taxAmountCurrencyId = details.totalTax.taxAmountCurrencyId[index] ? details.totalTax.taxAmountCurrencyId[index].textContent : null

        details.totalTax.taxDetailsLength = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails['.']}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails['.']}`).length : null
        details.totalTax.ivap = false
        details.totalTax.taxDetailsCode = {}
        details.totalTax.taxDetailsCodeTaxableAmountAboveCero = {}
        details.totalTax.taxDetails = {
          taxableAmount: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.taxableAmount}`),
          taxableAmountCurrencyId: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.taxableAmountCurrencyId}`),
          taxAmount: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.taxAmount}`),
          taxAmountCurrencyId: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.taxAmountCurrencyId}`),
          baseUnitMeasure: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.baseUnitMeasure}`),
          baseUnitMeasureUnitCode: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.baseUnitMeasureUnitCode}`),
          perUnitAmount: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.perUnitAmount}`),
          percent: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.percent}`),
          tierRange: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.tierRange}`),
          taxExemptionReasonCode: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.taxExemptionReasonCode}`),
          taxExemptionReasonCodeListAgencyName: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.taxExemptionReasonCodeListAgencyName}`),
          taxExemptionReasonCodeListName: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.taxExemptionReasonCodeListName}`),
          taxExemptionReasonCodeListURI: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.taxExemptionReasonCodeListURI}`),
          code: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.code}`),
          codeSchemeName: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.codeSchemeName}`),
          codeSchemeAgencyName: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.codeSchemeAgencyName}`),
          codeSchemeUri: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.codeSchemeUri}`),
          name: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.name}`),
          typeCode: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.totalTax.taxDetails.typeCode}`)
        }
        for (let index = 0; index < details.totalTax.taxDetailsLength; index++) {
          var taxDetail = new TaxDetail()
          taxDetail.taxableAmount = details.totalTax.taxDetails.taxableAmount[index] ? details.totalTax.taxDetails.taxableAmount[index].textContent : null
          if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(taxDetail.taxableAmount)) throw new Error('3031')
          if (details.totalTax.taxDetailsCode['2000'] &&
            Number(details.totalTax.taxDetailsCode['2000'].taxableAmount) > 0 &&
            taxDetail.taxableAmount !== saleDetail.mtoValorVenta
          ) taxDetail.warning.push('4294') // Pendiente
          // Si existe en la misma línea un cac:TaxSubtotal con 'Código de tributo por línea' igual a '2000' cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount > 0), el valor del tag es diferente de la suma del 'Valor de Venta por ítem' más el 'Monto del tributo de la línea del ISC', con una tolerancia + - 1
          if (!details.totalTax.taxDetailsCodeTaxableAmountAboveCero['2000'] && Number(taxDetail.taxableAmount) !== Number(saleDetail.mtoValorVenta)) taxDetail.warning.push('4294')
          taxDetail.taxableAmountCurrencyId = details.totalTax.taxDetails.taxableAmountCurrencyId[index] ? details.totalTax.taxDetails.taxableAmountCurrencyId[index].textContent : null
          if (taxDetail.taxableAmountCurrencyId && taxDetail.taxableAmountCurrencyId !== this.tipoMoneda) throw new Error('2071')
          taxDetail.taxAmount = details.totalTax.taxDetails.taxAmount[index] ? details.totalTax.taxDetails.taxAmount[index].textContent : null
          if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(taxDetail.taxAmount) && /^[+-0.]{1,}$/.test(taxDetail.taxAmount)) throw new Error('2033')
          taxDetail.taxAmountCurrencyId = details.totalTax.taxDetails.taxAmountCurrencyId[index] ? details.totalTax.taxDetails.taxAmountCurrencyId[index].textContent : null
          if (taxDetail.taxAmountCurrencyId && taxDetail.taxAmountCurrencyId !== this.tipoMoneda) throw new Error('2071')
          taxDetail.baseUnitMeasure = details.totalTax.taxDetails.baseUnitMeasure[index] ? details.totalTax.taxDetails.baseUnitMeasure[index].textContent : null
          if (taxDetail.baseUnitMeasure && taxDetail.baseUnitMeasure > 0 && taxDetail.baseUnitMeasure !== saleDetail.cantidad) throw new Error('3236')
          taxDetail.baseUnitMeasureUnitCode = details.totalTax.taxDetails.baseUnitMeasureUnitCode[index] ? details.totalTax.taxDetails.baseUnitMeasureUnitCode[index].textContent : null
          taxDetail.perUnitAmount = details.totalTax.taxDetails.perUnitAmount[index] ? details.totalTax.taxDetails.perUnitAmount[index].textContent : null
          taxDetail.percent = details.totalTax.taxDetails.percent[index] ? details.totalTax.taxDetails.percent[index].textContent : null
          if (taxDetail.percent && !/^[+]?[0-9]{1,3}\.[0-9]{1,5}$/.test(taxDetail.percent) && /^[+-0.]{1,}$/.test(taxDetail.percent)) throw new Error('3102')
          taxDetail.tierRange = details.totalTax.taxDetails.tierRange[index] ? details.totalTax.taxDetails.tierRange[index].textContent : null
          taxDetail.taxExemptionReasonCode = details.totalTax.taxDetails.taxExemptionReasonCode[index] ? details.totalTax.taxDetails.taxExemptionReasonCode[index].textContent : null
          if ((this.tipoOperacion === '0200' ||
          this.tipoOperacion === '0201' ||
          this.tipoOperacion === '0202' ||
          this.tipoOperacion === '0203' ||
          this.tipoOperacion === '0204' ||
          this.tipoOperacion === '0205' ||
          this.tipoOperacion === '0206' ||
          this.tipoOperacion === '0207' ||
          this.tipoOperacion === '0208'
          ) && taxDetail.taxExemptionReasonCode !== '40'
          ) throw new Error('2642')
          if (taxDetail.taxExemptionReasonCode === '17' && Number(taxDetail.taxableAmount) > 0) details.totalTax.ivap = true
          if ((taxDetail.taxExemptionReasonCode !== '17' && Number(taxDetail.taxableAmount) > 0) && details.totalTax.ivap) throw new Error('2644')
          taxDetail.taxExemptionReasonCodeListAgencyName = details.totalTax.taxDetails.taxExemptionReasonCodeListAgencyName[index] ? details.totalTax.taxDetails.taxExemptionReasonCodeListAgencyName[index].textContent : null
          taxDetail.taxExemptionReasonCodeListName = details.totalTax.taxDetails.taxExemptionReasonCodeListName[index] ? details.totalTax.taxDetails.taxExemptionReasonCodeListName[index].textContent : null
          taxDetail.taxExemptionReasonCodeListURI = details.totalTax.taxDetails.taxExemptionReasonCodeListURI[index] ? details.totalTax.taxDetails.taxExemptionReasonCodeListURI[index].textContent : null
          taxDetail.code = details.totalTax.taxDetails.code[index] ? details.totalTax.taxDetails.code[index].textContent : null
          if (!taxDetail.code) throw new Error('2037')
          if (!catalogTaxTypeCode[taxDetail.code]) throw new Error('2036')
          if (taxDetail.code !== '7152' && !taxDetail.percent) throw new Error('2992')
          if (taxDetail.code === '2000' && Number(taxDetail.taxableAmount) > 0 &&
          (
            Number(taxDetail.taxAmount) !== Number((
              (Number(taxDetail.percent) / 100) * Number(taxDetail.taxableAmount)
            ).toFixed(2)) ||
            !(
              Number(taxDetail.taxAmount) <= Number(((Number(taxDetail.percent) / 100) * Number(taxDetail.taxableAmount)).toFixed(2)) + 1 &&
              Number(taxDetail.taxAmount) >= Number(((Number(taxDetail.percent) / 100) * Number(taxDetail.taxableAmount)).toFixed(2)) - 1
            )
          )
          ) throw new Error('3108')
          if (taxDetail.code === '2000' && Number(taxDetail.taxableAmount) > 0 && /^[+-0.]{1,}$/.test(taxDetail.percent)) throw new Error('3104')
          if (taxDetail.code === '2000' && Number(taxDetail.taxableAmount) > 0 && !taxDetail.tierRange) throw new Error('2373')
          if (taxDetail.code !== '2000' && taxDetail.tierRange) throw new Error('3210')
          if (taxDetail.code === '2000' && Number(taxDetail.taxableAmount) > 0 && !catalogIscCalculationSystemTypeCode[taxDetail.tierRange]) throw new Error('2041')
          if (taxDetail.code === '9999' && Number(taxDetail.taxableAmount) > 0 &&
          (
            Number(taxDetail.taxAmount) !== Number(((Number(taxDetail.percent) / 100) * Number(taxDetail.taxableAmount)).toFixed(2)) ||
            !(
              Number(taxDetail.taxAmount) <= Number(((Number(taxDetail.percent) / 100) * Number(taxDetail.taxableAmount)).toFixed(2)) + 1 &&
              Number(taxDetail.taxAmount) >= Number(((Number(taxDetail.percent) / 100) * Number(taxDetail.taxableAmount)).toFixed(2)) - 1
            )
          )
          ) throw new Error('3109')
          if (
            (taxDetail.code === '9995' ||
            taxDetail.co7e === '9997' ||
            // Si el 'Código de tributo' es '9997', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones exoneradas con 'Código de tributo de línea' igual a '9997' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos exonerados (Código '05'), con una tolerancia + - 1
            taxDetail.co6e === '9997' ||
            // Si el 'Código de tributo' es '9998', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones inafectas con 'Código de tributo de línea' igual a '9998' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos inafectos (Código '06'), con una tolerancia + - 1
            taxDetail.code === '9998') && !/^[+-0.]{1,}$/.test(taxDetail.taxAmount)
          ) throw new Error('3110')
          if (taxDetail.code === '9996' && Number(taxDetail.taxableAmount) > 0.06 &&
          (
            taxDetail.taxExemptionReasonCode === '11' ||
            taxDetail.taxExemptionReasonCode === '12' ||
            taxDetail.taxExemptionReasonCode === '13' ||
            taxDetail.taxExemptionReasonCode === '14' ||
            taxDetail.taxExemptionReasonCode === '15' ||
            taxDetail.taxExemptionReasonCode === '16' ||
            taxDetail.taxExemptionReasonCode === '17'
          ) && /^[+-0.]{1,}$/.test(taxDetail.taxAmount)
          ) throw new Error('3111')
          if (taxDetail.code === '9996' && Number(taxDetail.taxableAmount) > 0 &&
            (
              taxDetail.taxExemptionReasonCode === '21' ||
              taxDetail.taxExemptionReasonCode === '31' ||
              taxDetail.taxExemptionReasonCode === '32' ||
              taxDetail.taxExemptionReasonCode === '33' ||
              taxDetail.taxExemptionReasonCode === '34' ||
              taxDetail.taxExemptionReasonCode === '35' ||
              taxDetail.taxExemptionReasonCode === '36' ||
              taxDetail.taxExemptionReasonCode === '37' ||
              taxDetail.taxExemptionReasonCode === '40'
            ) && !/^[+-0.]{1,}$/.test(taxDetail.taxAmount)
          ) throw new Error('3110')
          if (
            (taxDetail.code === '1000' ||
            taxDetail.code === '1016') &&
            Number(taxDetail.taxableAmount) > 0.06 &&
            /^[+-0.]{1,}$/.test(taxDetail.taxAmount)
          ) throw new Error('3111')
          if ((taxDetail.code !== '2000' || taxDetail.code !== '9999') &&
            Number(taxDetail.taxableAmount) > 0 && !taxDetail.taxExemptionReasonCode
          ) throw new Error('2371')
          if ((taxDetail.code === '2000' || taxDetail.code === '9999') && taxDetail.taxExemptionReasonCode) throw new Error('3050')
          if ((taxDetail.code !== '2000' || taxDetail.code !== '9999') && Number(taxDetail.taxAmount) > 0 && !catalogIgvAffectationTypeCode[taxDetail.taxExemptionReasonCode]) throw new Error('2040')
          if (
            (taxDetail.taxExemptionReasonCode === '10' ||
            taxDetail.taxExemptionReasonCode === '11' ||
            taxDetail.taxExemptionReasonCode === '12' ||
            taxDetail.taxExemptionReasonCode === '13' ||
            taxDetail.taxExemptionReasonCode === '14' ||
            taxDetail.taxExemptionReasonCode === '15' ||
            taxDetail.taxExemptionReasonCode === '16' ||
            taxDetail.taxExemptionReasonCode === '17'
            ) &&
            (
              Number(taxDetail.taxAmount) !== Number((
                (Number(taxDetail.percent) / 100) * Number(taxDetail.taxableAmount)
              ).toFixed(2)) ||
              !(
                Number(taxDetail.taxAmount) <= Number(((Number(taxDetail.percent) / 100) * Number(taxDetail.taxableAmount)).toFixed(2)) + 1 &&
                Number(taxDetail.taxAmount) >= Number(((Number(taxDetail.percent) / 100) * Number(taxDetail.taxableAmount)).toFixed(2)) - 1
              )
            )
          ) throw new Error('3103')
          if (taxDetail.code === '9996' && Number(taxDetail.taxableAmount) > 0 &&
            (taxDetail.taxExemptionReasonCode === '11' ||
            taxDetail.taxExemptionReasonCode === '12' ||
            taxDetail.taxExemptionReasonCode === '13' ||
            taxDetail.taxExemptionReasonCode === '14' ||
            taxDetail.taxExemptionReasonCode === '15' ||
            taxDetail.taxExemptionReasonCode === '16' ||
            taxDetail.taxExemptionReasonCode === '17') &&
            /^[+-0.]{1,}$/.test(taxDetail.percent)
          ) throw new Error('2993')
          if ((
            taxDetail.code === '1000' ||
            taxDetail.code === '1016'
          ) && taxDetail.taxableAmount > 0 &&
          /^[+-0.]{1,}$/.test(taxDetail.percent)
          ) throw new Error('2993')
          if (taxDetail.code === '7152' && Number(taxDetail.baseUnitMeasure) > 0 &&
            Number(Number(taxDetail.taxAmount).toFixed(2)) !== Number((Number(taxDetail.perUnitAmount) * Number(taxDetail.baseUnitMeasure)).toFixed(2))
          ) throw new Error('4318')
          if (taxDetail.code === '7152' && !taxDetail.baseUnitMeasure) throw new Error('3237')
          if (taxDetail.code === '7152' && Number(taxDetail.baseUnitMeasure) > 0 && /^[+-0.]{1,}$/.test(taxDetail.perUnitAmount)) throw new Error('3238')
          if (taxDetail.code === '7152' && Number(taxDetail.baseUnitMeasure) > 0 &&
            taxDetail.tipoMoneda === 'PEN'
            // && ICBPER // PENDIENTE
          ) this.warning.push('4237')
          taxDetail.codeSchemeName = details.totalTax.taxDetails.codeSchemeName[index] ? details.totalTax.taxDetails.codeSchemeName[index].textContent : null
          taxDetail.codeSchemeAgencyName = details.totalTax.taxDetails.codeSchemeAgencyName[index] ? details.totalTax.taxDetails.codeSchemeAgencyName[index].textContent : null
          taxDetail.codeSchemeUri = details.totalTax.taxDetails.codeSchemeUri[index] ? details.totalTax.taxDetails.codeSchemeUri[index].textContent : null
          taxDetail.name = details.totalTax.taxDetails.name[index] ? details.totalTax.taxDetails.name[index].textContent : null
          if (!taxDetail.name) throw new Error('2996')
          if (catalogTaxTypeCode[taxDetail.code].name !== taxDetail.name) throw new Error('3051')
          taxDetail.typeCode = details.totalTax.taxDetails.typeCode[index] ? details.totalTax.taxDetails.typeCode[index].textContent : null
          if (catalogTaxTypeCode[taxDetail.code].international !== taxDetail.typeCode) throw new Error('2377')

          if (details.totalTax.taxDetailsCode[taxDetail.code]) throw new Error('3067')
          details.totalTax.taxDetailsCode[taxDetail.code] = taxDetail
          if (Number(taxDetail.taxableAmount) > 0) details.totalTax.taxDetailsCodeTaxableAmountAboveCero[taxDetail.code] = taxDetail
        }
        if (!(
          (details.totalTax.taxDetailsCode['1000'] && Number(details.totalTax.taxDetailsCode['1000'].taxableAmount) > 0) ||
          (details.totalTax.taxDetailsCode['1016'] && Number(details.totalTax.taxDetailsCode['1016'].taxableAmount) > 0) ||
          (details.totalTax.taxDetailsCode['9996'] && Number(details.totalTax.taxDetailsCode['9996'].taxableAmount) > 0) ||
          (details.totalTax.taxDetailsCode['9997'] && Number(details.totalTax.taxDetailsCode['9997'].taxabl7Amount) > 0) ||
          // Si el 'Código de tributo' es '9997', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones exoneradas con 'Código de tributo de línea' igual a '9997' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos exonerados (Código '05'), con una tolerancia + - 1
          (details.totalTax.taxDetailsCode['9997'] && Number(details.totalTax.taxDetailsCode['9997'].taxabl6Amount) > 0) ||
          // Si el 'Código de tributo' es '9998', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones inafectas con 'Código de tributo de línea' igual a '9998' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos inafectos (Código '06'), con una tolerancia + - 1
          (details.totalTax.taxDetailsCode['9998'] && Number(details.totalTax.taxDetailsCode['9998'].taxableAmount) > 0)
        )) throw new Error('3105')
        if (Object.keys(details.totalTax.taxDetailsCodeTaxableAmountAboveCero).length > 0 &&
        (
          (
            Object.keys(details.totalTax.taxDetailsCodeTaxableAmountAboveCero).length === 2 &&
            !(
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['1000'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['2000']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['1016'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9999']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9995'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9999']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9996'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['2000']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9997'] && details.totalTax.taxDetailsCodeTaxableAmountAbove7ero['2000']) ||
              // Si el 'Código de tributo' es '9997', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones exoneradas con 'Código de tributo de línea' igual a '9997' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos exonerados (Código '05'), con una tolerancia + - 1
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9997'] && details.totalTax.taxDetailsCodeTaxableAmountAbove6ero['2000']) ||
              // Si el 'Código de tributo' es '9998', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones inafectas con 'Código de tributo de línea' igual a '9998' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos inafectos (Código '06'), con una tolerancia + - 1
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9998'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['2000'])
            )
          ) ||
          (
            Object.keys(details.totalTax.taxDetailsCodeTaxableAmountAboveCero).length === 3 &&
            !(
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['1000'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['2000'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9999']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9996'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['2000'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9999']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9997'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['2000'] && details.totalTax.taxDetailsCodeTaxableAmountAbove7ero['9999']) ||
              // Si el 'Código de tributo' es '9997', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones exoneradas con 'Código de tributo de línea' igual a '9997' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos exonerados (Código '05'), con una tolerancia + - 1
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9997'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['2000'] && details.totalTax.taxDetailsCodeTaxableAmountAbove6ero['9999']) ||
              // Si el 'Código de tributo' es '9998', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones inafectas con 'Código de tributo de línea' igual a '9998' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos inafectos (Código '06'), con una tolerancia + - 1
              (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9998'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['2000'] && details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9999'])
            )
          ) ||
          Object.keys(details.totalTax.taxDetailsCodeTaxableAmountAboveCero).length > 3
        )
        ) throw new Error('3223')

        if (details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9996']) this.warning.push('4288') // PENDIENTE
        if (!details.totalTax.taxDetailsCodeTaxableAmountAboveCero['9996']) this.warning.push('4288') // PENDIENTE
        saleDetail.mtoValorVentaCurrencyId = details.mtoValorVentaCurrencyId[index] ? details.mtoValorVentaCurrencyId[index].textContent : null
        if (saleDetail.mtoValorVentaCurrencyId && saleDetail.mtoValorVentaCurrencyId !== this.tipoMoneda) throw new Error('2071')

        details.cargosLength = domDocumentHelper.select(path.details.cargos['.']) ? domDocumentHelper.select(path.details.cargos['.']).length : 0
        details.cargosCode = {}
        details.cargos = {
          indicator: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos.indicator}`),
          codTipo: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos.codTipo}`),
          codTipoListAgencyName: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos.codTipoListAgencyName}`),
          codTipoListName: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos.codTipoListName}`),
          codTipoListUri: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos.codTipoListUri}`),
          factor: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos.factor}`),
          monto: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos.monto}`),
          montoCurrencyId: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos.montoCurrencyId}`),
          montoBase: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos.montoBase}`),
          montoBaseCurrencyId: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos.montoBaseCurrencyId}`)
        }
        for (let index = 0; index < details.cargosLength; index++) {
          var charge = new Charge()
          charge.codTipo = details.cargos.codTipo[index] ? details.cargos.codTipo[index] : null
          if (!charge.codTipo) throw new Error('3073')
          if (!catalogChargeCode[charge.codTipo]) throw new Error('2954')
          if (
            !(
              charge.codTipo === '00' ||
              charge.codTipo === '01' ||
              charge.codTipo === '47' ||
              charge.codTipo === '48'
            )
          )charge.warning.push('4268')
          charge.indicator = details.cargos.indicator[index] ? details.cargos.indicator[index].textContent : null
          if (String(charge.indicator) !== 'true' && (charge.codTipo === '47' || charge.codTipo === '48')) throw new Error('3114')
          if (String(charge.indicator) !== 'false' && (charge.codTipo === '00' || charge.codTipo === '01')) throw new Error('3114')
          charge.codTipoListAgencyName = details.cargos.codTipoListAgencyName[index] ? details.cargos.codTipoListAgencyName[index].textContent : null
          charge.codTipoListName = details.cargos.codTipoListName[index] ? details.cargos.codTipoListName[index].textContent : null
          charge.codTipoListUri = details.cargos.codTipoListUri[index] ? details.cargos.codTipoListUri[index].textContent : null
          charge.factor = details.cargos.factor[index] ? details.cargos.factor[index].textContent : null
          if (charge.factor &&
            (!/^[+]?[0-9]{1,3}\.[0-9]{1,5}$/.test(charge.factor) || !/^[+-0.]{1,}$/.test(charge.factor))
          ) throw new Error('3052')
          charge.montoBase = details.cargos.montoBase[index] ? details.cargos.montoBase[index].textContent : null
          if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(charge.montoBase) ||
            /^[+-0.]{1,}$/.test(charge.montoBase)) throw new Error('3053')
          charge.montoBaseCurrencyId = details.cargos.montoBaseCurrencyId[index] ? details.cargos.montoBaseCurrencyId[index].textContent : null
          if (charge.montoBaseCurrencyId && charge.montoBaseCurrencyId !== this.tipoMoneda) throw new Error('2071')
          charge.monto = details.cargos.monto[index] ? details.cargos.monto[index].textContent : null
          if (
            !/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(charge.monto) || !/^[+-0.]{1,}$/.test(charge.monto)
          ) throw new Error('2955')
          if (charge.codTipo &&
            (charge.factor && !(Number(charge.factor) > 0)) &&
            !(
              Number(charge.monto) === (Number(charge.montoBase) * Number(charge.factor)) ||
              (
                Number(charge.monto) <= (Number((Number(charge.montoBase) * Number(charge.factor)).toFixed(2)) + 1) &&
                Number(charge.monto) >= (Number((Number(charge.montoBase) * Number(charge.factor)).toFixed(2)) - 1)
              )
            )
          ) charge.warning.push('4322')
          charge.montoCurrencyId = details.cargos.montoCurrencyId[index] ? details.cargos.montoCurrencyId[index].textContent : null
          if (charge.montoCurrencyId && charge.montoCurrencyId !== this.tipoMoneda) throw new Error('2071')
        }

        if (listPadronContribuyente[this.company.ruc].ind_padron === 12 && !saleDetail.codProdSunat && !saleDetail.codProdGs1) saleDetail.warning.push('4331')
        if (detailsId[saleDetail.id]) throw new Error('2752')
        detailsId[saleDetail.id] = saleDetail
        detailsCodProducto[saleDetail.codProdSunat] = saleDetail.codProdSunat
        this.details.push(saleDetail)
        this.warning = this.warning.concat(saleDetail.warning)
      }
      if (this.tipoOperacion === '0112' && !(detailsCodProducto['84121901'] || detailsCodProducto['80131501'])) throw new Error('3181')

      var totalTaxLength = domDocumentHelper.select(path.totalTax['.']) ? domDocumentHelper.select(path.totalTax['.']).length : 0
      if (!Number(totalTaxLength)) throw new Error('2956')
      if (Number(totalTaxLength) > 1) throw new Error('3024')
      this.totalTax.taxAmount = domDocumentHelper.select(path.totalTax.taxAmount)
      if (this.totalTax.taxAmount &&
        (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(this.totalTax.taxAmount) || /^[+-0.]{1,}$/.test(this.totalTax.taxAmount))
      ) throw new Error('3020')
      this.totalImpuestos = this.totalTax.taxAmount
      this.totalTax.taxAmountCurrencyId = domDocumentHelper.select(path.totalTax.taxAmountCurrencyId)

      var taxDetailsLength = domDocumentHelper.select(path.totalTax.taxDetails['.']) ? domDocumentHelper.select(path.totalTax.taxDetails['.']).length : 0
      var taxDetailsCode = {}
      var taxDetails = {
        taxableAmount: domDocumentHelper.select(path.totalTax.taxDetails.taxableAmount),
        taxableAmountCurrencyId: domDocumentHelper.select(path.totalTax.taxDetails.taxableAmountCurrencyId),
        taxAmount: domDocumentHelper.select(path.totalTax.taxDetails.taxAmount),
        taxAmountCurrencyId: domDocumentHelper.select(path.totalTax.taxDetails.taxAmountCurrencyId),
        code: domDocumentHelper.select(path.totalTax.taxDetails.code),
        codeSchemeName: domDocumentHelper.select(path.totalTax.taxDetails.codeSchemeName),
        codeSchemeAgencyName: domDocumentHelper.select(path.totalTax.taxDetails.codeSchemeAgencyName),
        codeSchemeUri: domDocumentHelper.select(path.totalTax.taxDetails.codeSchemeUri),
        name: domDocumentHelper.select(path.totalTax.taxDetails.name),
        typeCode: domDocumentHelper.select(path.totalTax.taxDetails.typeCode)
      }
      for (let index = 0; index < taxDetailsLength; index++) {
        taxDetail = new TaxDetail()
        taxDetail.code = taxDetails.code[index] ? taxDetails.code[index].textContent : null
        if (!taxDetail.code) throw new Error('3059')
        if (!catalogTaxTypeCode[taxDetail.code]) throw new Error('3007')
        if ((this.tipoOperacion === '0200' ||
          this.tipoOperacion === '0201' ||
          this.tipoOperacion === '0202' ||
          this.tipoOperacion === '0203' ||
          this.tipoOperacion === '0204' ||
          this.tipoOperacion === '0205' ||
          this.tipoOperacion === '0206' ||
          this.tipoOperacion === '0207' ||
          this.tipoOperacion === '0208') &&
          (taxDetailsCode === '1000' ||
            taxDetailsCode === '1016')) taxDetail.warning.push('3107')
        if ((this.tipoOperacion === '0200' ||
            this.tipoOperacion === '0201' ||
            this.tipoOperacion === '0202' ||
            this.tipoOperacion === '0203' ||
            this.tipoOperacion === '0204' ||
            this.tipoOperacion === '0205' ||
            this.tipoOperacion === '0206' ||
            this.tipoOperacion === '0207' ||
            this.tipoOperacion === '0208') &&
          (taxDetailsCode === '2000' ||
            taxDetailsCode === '9999')) taxDetail.warning.push('3107')
        if (taxDetail.code !== '7152' && !taxDetails.taxableAmount[index]) throw new Error('3003')
        taxDetail.taxableAmount = taxDetails.taxableAmount[index] ? taxDetails.taxableAmount[index].textContent : null
        if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(taxDetail.taxableAmount)) throw new Error('2999')
        if (taxDetail.code === '1000' && taxDetail.taxableAmount) taxDetail.warning.push('4299') // PENDIENTE
        // Si 'Código de tributo' es '1000' y  el Tag UBL existe, el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por item' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones gravadas con el IGV con 'Código de tributo por línea' igual a '1000' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount > 0), menos los 'Monto de descuento global' que afectan la base imponible ('Código de motivo de descuento' igual a '02' y '04') más 'Montos de cargo global' que afectan la base imponible ('Código de motivo de cargo' igual a  '49'), con una tolerancia + - 1
        if (taxDetail.code === '1016' && taxDetail.taxableAmount) taxDetail.warning.push('4300') // PENDIENTE
        // Si 'Código de tributo' es '1016' y  el Tag UBL existe, el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por item' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones gravadas con el IVAP con 'Código de tributo por línea' igual a '1016' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount > 0), menos los 'Monto de descuento global' que afectan la base imponible ('Código de motivo de descuento' igual a '02' y '04'), más los 'Monto de cargo global' que afectan la base ('Código de motivo de cargo' igual a '49'), con una tolerancia + - 1
        if (taxDetail.code === '2000' && taxDetail.taxableAmount > 0) throw new Error('2650')
        if (taxDetail.code === '2000' && taxDetail.taxableAmount) taxDetail.warning.push('4303') // PENDIENTE
        // Si 'Código de tributo' es '2000', si el Tag UBL existe y el valor del Tag UBL es diferente a la sumatoria de los 'Monto base' (cbc:TaxableAmount) de los ítems con 'Código de tributo por línea' igual a '2000' (con una tolerancia + - 1)
        if (taxDetail.code === '9995') throw new Error('4295') // PENDIENTE
        // Si el 'Código de tributo' es '9995', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones de exportación con 'Código de tributo de línea' igual a '9995' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount > 0), con una tolerancia + - 1
        if (taxDetail.code === '9996') taxDetail.warning.push('4298') // PENDIENTE
        // Si 'Código de tributo' es '9996', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por item' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones gratuitas con 'Código de tributo por línea' igual a '9996' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount > 0), con una tolerancia + - 1
        if (taxDetail.code === '9996') taxDetail.warning.push('2641') // PENDIENTE
        // Si 'Código de tributo' es '9996' (Gratuita) y existe una línea con 'Valor referencial unitario por ítem en operaciones gratuitas (no onerosas)' ('Código de precio' igual a '02') con monto mayor a cero, el valor del Tag UBL es igual a 0 (cero)
        if (taxDetail.code === '9996') taxDetail.warning.push('2416') // PENDIENTE
        // Si 'Código de tributo' es '9996' (Gratuita) y 'Código de leyenda' es '1002', el valor del Tag UBL es igual a 0 (cero)
        if (taxDetail.code === '9997') throw new Error('4297') // PENDIENTE
        // Si el 'Código de tributo' es '9997', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones exoneradas con 'Código de tributo de línea' igual a '9997' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos exonerados (Código '05'), con una tolerancia + - 1
        if (taxDetail.code === '9998') throw new Error('4296') // PENDIENTE
        // Si el 'Código de tributo' es '9998', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones inafectas con 'Código de tributo de línea' igual a '9998' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos inafectos (Código '06'), con una tolerancia + - 1
        if (taxDetail.code === '9997' && /^[+-0.]{1,}$/.test(taxDetail.taxableAmount)) taxDetail.warning.push('4022') // PENDIENTE
        // Si 'Código de tributo' igual a '9997' (Exonerada)  y existe 'Código de leyenda' igual a '2001', el valor del Tag UBL es igual a 0 (cero)
        if (taxDetail.code === '9997' && /^[+-0.]{1,}$/.test(taxDetail.taxableAmount)) taxDetail.warning.push('4023') // PENDIENTE
        // Si 'Código de tributo' igual a '9997' (Exonerada) y existe 'Código de leyenda' igual a '2002', el valor del Tag UBL es igual a 0 (cero)
        if (taxDetail.code === '9997' && /^[+-0.]{1,}$/.test(taxDetail.taxableAmount)) taxDetail.warning.push('4024') // PENDIENTE
        // Si 'Código de tributo' igual a '9997' (Exonerada) y existe 'Código de leyenda' igual a '2003', el valor del Tag UBL es igual a 0 (cero)
        if (taxDetail.code === '9997' && /^[+-0.]{1,}$/.test(taxDetail.taxableAmount)) taxDetail.warning.push('4244') // PENDIENTE
        // Si 'Código de tributo' igual a '9997' (Exonerada) y 'Código de leyenda' es '2008', el valor del Tab UBL es igual a 0 (cero)
        if (taxDetail.code === '9999' && taxDetail.taxableAmount) taxDetail.warning.push('4304') // PENDIENTE
        // Si existe el Tag y el 'Código de tributo' es '9999', el valor del Tag UBL es diferente a la sumatoria de los 'Montos base' (cbc:TaxableAmount) de los ítems con 'Código de tributo por línea' igual a '9999'
        taxDetail.taxableAmountCurrencyId = taxDetails.taxableAmountCurrencyId[index] ? taxDetails.taxableAmountCurrencyId[index].textContent : null
        if (taxDetail.taxableAmountCurrencyId && taxDetail.taxableAmountCurrencyId !== this.tipoMoneda) throw new Error('2071')
        taxDetail.taxAmount = taxDetails.taxAmount[index] ? taxDetails.taxAmount[index].textContent : null
        if (taxDetail.code === '1000') taxDetail.warning.push('4290') // PENDIENTE
        // Si  'Código de tributo' es '1000', el valor del Tag Ubl es diferente al resultado de multiplicar la sumatoria de los 'Monto base' (cbc:TaxableAmount) de los ítems con 'Código de tributo por línea' igual a '1000', menos 'Monto de descuentos' globales que afectan la base (Código '02' y '04'), más los 'Montos de cargos' globales que afectan la base (Código 49) por la tasa vigente al IGV a la fecha de emisión, con una tolerancia + - 1
        if (taxDetail.code === '1016') taxDetail.warning.push('4302') // PENDIENTE
        // Si  'Código de tributo' es '1016', el valor del Tag UBL es diferente al resultado de multiplicar la sumatoria de los 'Monto base' (cbc:TaxableAmount) de los ítems con 'Código de tributo por línea' igual a '1016', menos los 'Monto de descuentos' globales que afectan la base ('Código de motivo de descuento' igual a '02' y '04'), más los 'Monto de cargos' globales que afectan la base ('Código de motivo de cargo' igual a '49') por la tasa vigente del IVAP, con una tolerancia + - 1
        if (taxDetail.code === '2000') taxDetail.warning.push('4305') // PENDIENTE
        // Si  'Código de tributo' es '2000', el valor del Tag Ubl es diferente de la sumatoria de los 'Monto de tributo de la línea' (cbc:TaxAmount) de los ítems con 'Código de tributo por línea' igual a '2000', (con una tolerancia + - 1)
        if (taxDetail.code === '7152') taxDetail.warning.push('4321') // PENDIENTE
        // Si  'Código de tributo' es '7152', el valor del Tag Ubl es diferente de la sumatoria de los 'Monto del tributo de la línea'  (cbc:TaxAmount) de los ítems con 'Código de tributo por línea' igual a '7152'
        if (taxDetail.code === '7152' && moment(this.fechaEmision) < moment('2019-08-01') && Number(taxDetail.taxAmount) > 0) throw new Error('2949')
        if (taxDetail.taxAmount && !/^[+-0.]{1,}$/.test(taxDetail.taxAmount) &&
          (taxDetail.code === '9995' ||
            taxDetail.code === '9997' ||
            taxDetail.code === '9998')) throw new Error('3000')
        if (taxDetail.code === '9996') throw new Error('4311') // PENDIENTE
        // Si  'Código de tributo' es '9996', el valor del Tag UBL es diferente de la sumatoria de 'Monto de IGV' (cbc:TaxAmount) que correspondan a ítems de operaciones gratuitas con 'Código de tributo por línea' igual a '9996' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), con una tolerancia + - 1
        if (taxDetail.code === '9999') taxDetail.warning.push('4306') // PENDIENTE
        // Si  'Código de tributo' es '9999', el valor del Tag Ubl es diferente de la sumatoria de los 'Monto del tributo de la línea' (cbc:TaxAmount) de los ítems con 'Código de tributo por línea' igual a '9999', con una tolerancia + - 1
        if (taxDetail.code === '2000') taxDetail.warning.push('4020') // PENDIENTE
        // Si 'Código de tributo' es '2000' (ISC), y existe al menos un ítem con 'Código de tributo por línea' igual a '2000' y 'Monto ISC por línea' (cbc:TaxAmount) mayor a cero, el valor del Tag UBL es igual a 0 (cero)
        taxDetail.taxAmountCurrencyId = taxDetails.taxAmountCurrencyId[index] ? taxDetails.taxAmountCurrencyId[index].textContent : null
        if (taxDetail.taxAmountCurrencyId && taxDetail.taxAmountCurrencyId !== this.tipoMoneda) throw new Error('2071')
        taxDetail.codeSchemeName = taxDetails.codeSchemeName[index] ? taxDetails.codeSchemeName[index].textContent : null
        taxDetail.codeSchemeAgencyName = taxDetails.codeSchemeAgencyName[index] ? taxDetails.codeSchemeAgencyName[index].textContent : null
        taxDetail.codeSchemeUri = taxDetails.codeSchemeUri[index] ? taxDetails.codeSchemeUri[index].textContent : null
        taxDetail.name = taxDetails.name[index] ? taxDetails.name[index].textContent : null
        if (!taxDetail.name) throw new Error('2054')
        if (catalogTaxTypeCode[taxDetail.code].name !== taxDetail.name) throw new Error('2964')
        taxDetail.typeCode = taxDetails.typeCode[index] ? taxDetails.typeCode[index].textContent : null
        if (!taxDetail.typeCode) throw new Error('2052')
        if (catalogTaxTypeCode[taxDetail.code].international !== taxDetail.typeCode) throw new Error('2961')

        if (taxDetailsCode[taxDetail.code]) throw new Error('3068')
        taxDetailsCode[taxDetail.code] = taxDetail.taxAmount
        // if() // PENDIENTE
        // Si 'Tipo de operación' es de exportación '0200' o '0201' o '0202' o '0203' o '0204' o '0205' o '0206' o '0207' o '0208' y existe un ID '9997' o '9998' a nivel global
        if (taxDetail.code === '9996' && Number(taxDetail.taxableAmount) > 0) {
          var objectKeysDetails = Object.keys(detailsId)
          for (let index = 0; index < objectKeysDetails.length; index++) {
            if (Number(detailsId[objectKeysDetails[index]].mtoValorUnitario) > 0) throw new Error('2640')
          }
        }

        this.totalTax.taxDetails.push(taxDetail)
        this.warning = this.warning.concat(taxDetail.warning)
      }

      var totalTaxDetailsSum = Number(
        (
          Number(taxDetailsCode['1000'] ? taxDetailsCode['1000'] : 0) +
          Number(taxDetailsCode['1016'] ? taxDetailsCode['1016'] : 0) +
          Number(taxDetailsCode['2000'] ? taxDetailsCode['2000'] : 0) +
          Number(taxDetailsCode['7152'] ? taxDetailsCode['7152'] : 0) +
          Number(taxDetailsCode['9999'] ? taxDetailsCode['9999'] : 0)
        ).toFixed(2))
      if (!(
        Number(totalTaxDetailsSum) === Number(Number(this.totalTax.taxAmount).toFixed(2)) ||
        (
          Number(totalTaxDetailsSum) >= Number((Number(this.totalTax.taxAmount)).toFixed(2)) + 1 &&
          Number(totalTaxDetailsSum) <= Number((Number(this.totalTax.taxAmount)).toFixed(2)) - 1
        )
      )) this.totalTax.warning.push('4301')

      var cargosLength = domDocumentHelper.select(path.cargos['.']).length ? domDocumentHelper.select(path.cargos['.']).length : 0
      var cargosCode = {}
      var cargos = {
        indicator: domDocumentHelper.select(path.cargos.indicator),
        codTipo: domDocumentHelper.select(path.cargos.codTipo),
        codTipoListAgencyName: domDocumentHelper.select(path.cargos.codTipoListAgencyName),
        codTipoListName: domDocumentHelper.select(path.cargos.codTipoListName),
        codTipoListUri: domDocumentHelper.select(path.cargos.codTipoListUri),
        factor: domDocumentHelper.select(path.cargos.factor),
        monto: domDocumentHelper.select(path.cargos.monto),
        montoCurrencyId: domDocumentHelper.select(path.cargos.montoCurrencyId),
        montoBase: domDocumentHelper.select(path.cargos.montoBase),
        montoBaseCurrencyId: domDocumentHelper.select(path.cargos.montoBaseCurrencyId)
      }
      for (let index = 0; index < cargosLength; index++) {
        charge = new Charge()
        if ((cargos.indicator[index]) && !(cargos.codTipo[index])) throw new Error('3072')
        charge.codTipo = cargos.codTipo[index] ? cargos.codTipo[index].textContent : null
        if (!catalogChargeCode[charge.codTipo]) throw new Error('3071')
        charge.indicator = cargos.indicator[index] ? cargos.indicator[index].textContent : null
        if (String(charge.indicator) !== 'true' && charge.codTipo === '45') throw new Error('3114')
        if (String(charge.indicator) !== 'true' && (
          charge.codTipo === '51' ||
            charge.codTipo === '52' ||
            charge.codTipo === '53'
        )) throw new Error('3114')
        if (
          (
            charge.codTipo === '45' ||
              charge.codTipo === '46' ||
              charge.codTipo === '49' ||
              charge.codTipo === '50' ||
              charge.codTipo === '51' ||
              charge.codTipo === '52' ||
              charge.codTipo === '53'
          ) && String(charge.indicator) !== 'true'
        ) throw new Error('3114')
        if (
          (
            charge.codTipo === '02' ||
              charge.codTipo === '03' ||
              charge.codTipo === '04' ||
              charge.codTipo === '05' ||
              charge.codTipo === '06'
          ) && String(charge.indicator) !== 'false'
        ) throw new Error('3114')
        if (
          charge.codTipo === '00' ||
            charge.codTipo === '01' ||
            charge.codTipo === '47' ||
            charge.codTipo === '48'
        ) charge.warning.push('4291')
        charge.codTipoListAgencyName = cargos.codTipoListAgencyName[index] ? cargos.codTipoListAgencyName[index].textContent : null
        charge.codTipoListName = cargos.codTipoListName[index] ? cargos.codTipoListName[index].textContent : null
        charge.codTipoListUri = cargos.codTipoListUri[index] ? cargos.codTipoListUri[index].textContent : null
        charge.factor = cargos.factor[index] ? cargos.factor[index].textContent : null
        if (charge.factor &&
          (!/^[+]?[0-9]{1,3}\.[0-9]{1,5}$/.test(charge.factor) || !/^[+-0.]{1,}$/.test(charge.factor))
        ) throw new Error('3025')
        charge.montoBase = cargos.montoBase[index] ? cargos.montoBase[index].textContent : null
        if (charge.montoBase && !/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(charge.montoBase) &&
          !/^[+-0.]{1,}$/.test(charge.montoBase)) throw new Error('3016')
        if ((/^[+-0.]{1,}$/.test(charge.montoBase) || !charge.montoBase) &&
          charge.codTipo === '45') throw new Error('3092')
        if (
          (
            charge.codTipo === '51' ||
            charge.codTipo === '52' ||
            charge.codTipo === '53'
          ) &&
          this.tipoMoneda === 'PEN' && Number(charge.montoBase) > Number(this.mtoImpVenta)) throw new Error('2797')
        if ((!charge.montoBase || /^[+-0.]{1,}$/.test(charge.montoBase)) && (
          charge.codTipo === '51' ||
          charge.codTipo === '52' ||
          charge.codTipo === '53'
        )) throw new Error('3233')
        charge.montoBaseCurrencyId = cargos.montoBaseCurrencyId[index] ? cargos.montoBaseCurrencyId[index].textContent : null
        if ((charge.codTipo === '51' ||
              charge.codTipo === '52' ||
              charge.codTipo === '53') &&
          charge.montoBaseCurrencyId !== 'PEN') throw new Error('2788')
        if (charge.montoBaseCurrencyId && charge.montoBaseCurrencyId !== this.tipoMoneda) throw new Error('2071')
        charge.monto = cargos.monto[index] ? cargos.monto[index].textContent : null
        if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(charge.monto) || !/^[+-0.]{1,}$/.test(charge.monto)
        ) throw new Error('2968')
        if (charge.monto && /^[+-0.]{1,}$/.test(charge.monto) && charge.codTipo === '45') throw new Error('3074')
        if ((
          charge.codTipo === '51' ||
          charge.codTipo === '52' ||
          charge.codTipo === '53'
        ) && (
          Number(charge.monto) !== Number((Number(charge.montoBase) * Number(charge.factor)).toFixed(2)) || (
            Number(charge.monto) <= Number((Number(charge.montoBase) * Number(charge.factor)).toFixed(2)) + 1 &&
            Number(charge.monto) >= Number((Number(charge.montoBase) * Number(charge.factor)).toFixed(2)) - 1
          ))) throw new Error('2798')
        if (charge.codTipo && (charge.factor && !(Number(charge.factor) > 0)) &&
            !(Number(charge.monto) === (Number(charge.montoBase) * Number(charge.factor)) || (
              Number(charge.monto) <= (Number((Number(charge.montoBase) * Number(charge.factor)).toFixed(2)) + 1) &&
              Number(charge.monto) >= (Number((Number(charge.montoBase) * Number(charge.factor)).toFixed(2)) - 1)))
        ) charge.warning.push('4322')
        charge.montoCurrencyId = cargos.montoCurrencyId[index] ? cargos.montoCurrencyId[index].textContent : null
        if ((charge.codTipo === '51' ||
            charge.codTipo === '52' ||
            charge.codTipo === '53') &&
          charge.montoCurrencyId !== 'PEN') throw new Error('2792')
        if (charge.montoCurrencyId && charge.montoCurrencyId !== this.tipoMoneda) throw new Error('2071')
        cargosCode[charge.codTipo] = charge
        this.cargos.push(charge)
        this.warning = this.warning.concat(charge.warning)
      }
      if (this.tipoOperacion === '2001' && !(
        cargosCode['51'] ||
        cargosCode['52'] ||
        cargosCode['53']
      )) throw new Error('3093')

      if (domDocumentHelper.select(path.mtoDescuentos)) {
        this.mtoDescuentos = domDocumentHelper.select(path.mtoDescuentos)
        if (this.mtoDescuentos) this.warning.push('4307') // PENDIENTE
        // El valor del tag es diferente a la sumatoria de los 'Montos de descuentos' de línea que no afectan la base (con 'Código de motivo de descuento' igual a '01') y los 'Montos de descuentos' globales que no afectan la base (con 'Código de motivo de descuento' igual a'03'), con una tolerancia de + - 1
        this.mtoDescuentosCurrencyId = domDocumentHelper.select(path.mtoDescuentosCurrencyId)
        if (this.mtoDescuentosCurrencyId && this.mtoDescuentosCurrencyId !== this.tipoMoneda) throw new Error('2071')
      }
      if (domDocumentHelper.select(path.sumOtrosCargos)) {
        this.sumOtrosCargos = domDocumentHelper.select(path.sumOtrosCargos)
        if (this.sumOtrosCargos) this.warning.push('4308') // PENDIENTE
        // El valor del tag es diferente a la sumatoria de los 'Montos de cargos' de línea que no afectan la base (con 'Código de motivo de cargo' igual a '48') y los 'Montos de cargos' globales que no afectan la base (con 'Código de motivo de cargo' igual a '45, '46' y '50'), con una tolerancia de + - 1
        this.sumOtrosCargosCurrencyId = domDocumentHelper.select(path.sumOtrosCargosCurrencyId)
        if (this.sumOtrosCargosCurrencyId && this.sumOtrosCargosCurrencyId !== this.tipoMoneda) throw new Error('2071')
      }
      this.mtoImpVenta = domDocumentHelper.select(path.mtoImpVenta)
      if (this.mtoImpVenta) this.warning.push('4312') // PENDIENTE
      // Si el valor del tag difiere de la sumatoria del 'Total precio de venta' más 'Sumatoria otros cargos (que no afectan la base imponible del IGV)' menos 'Sumatoria otros descuentos (que no afectan la base imponible del IGV)' menos 'Total anticipos' de corresponder y más 'Monto de redondeo del importe total',  con una tolerancia + - 1.
      this.mtoImpVentaCurrencyId = domDocumentHelper.select(path.mtoImpVentaCurrencyId)
      if (this.mtoImpVentaCurrencyId && this.mtoImpVentaCurrencyId !== this.tipoMoneda) this.warning.push('2071')
      this.valorVenta = domDocumentHelper.select(path.valorVenta)
      if (this.valorVenta) this.warning.push('4309') // PENDIENTE
      // El valor del tag es diferente de la sumatoria del 'Valor de venta por ítem' (cbc:LineExtensionAmount) de los ítems con 'Código de tributo por línea' igual a  '1000', '1016', '9995', '9997' y '9998'  y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount > 0), menos 'Montos de descuentos globales' que afectan la base ('Código de motivo de descuento' igual a '02') más 'Montos de cargos globales' que afectan la base ('Código de motivo de cargo' igual a '49'), con una tolerancia de + - 1
      this.valorVentaCurrencyId = domDocumentHelper.select(path.valorVentaCurrencyId)
      if (this.valorVentaCurrencyId && this.valorVentaCurrencyId !== this.tipoMoneda) throw new Error('2071')
      this.precioVenta = domDocumentHelper.select(path.precioVenta)
      if (!this.precioVenta) this.warning.push('4317')
      if (this.precioVenta) this.warning.push('4310') // PENDIENTE
      // "Si existe el Tag UBL, y existe 'Total Importe IGV' con monto mayor a cero, y el valor es diferente de la sumatoria de 'Total valor de venta' más 'Sumatoria ISC' más 'Sumatoria Otros Tributos' más 'Sumatoria ICBPER' más el resultado de:
      // Multiplicar la sumatoria de los 'Monto base' de las líneas (cbc:TaxableAmount) con 'Código de tributo por línea' igual a '1000', menos 'Monto de descuentos' globales que afectan la base (Código '02'), más los 'Montos de cargos' globales que afectan la base (Código '49') por la tasa vigente del IGV a la fecha de emisión, con una tolerancia + - 1"
      if (this.precioVenta) this.warning.push('4310') // PENDIENTE
      // "Si existe el Tag UBL, y existe 'Total Importe IVAP' con monto mayor a cero, y el valor es diferente de la sumatoria de 'Total valor de venta' más 'Sumatoria Otros Tributos' más 'Sumatoria ICBPER' más el resultado de:
      // Multiplicar la sumatoria de los 'Monto base' de las líneas (cbc:TaxableAmount) con 'Código de tributo por línea' igual a '1016', menos 'Monto de descuentos' globales que afectan la base (Código '02'), más los 'Montos de cargos' globales que afectan la base (Código '49') por la tasa vigente del IVAP a la fecha de emisión, con una tolerancia + - 1"
      if (this.precioVenta) this.warning.push('4310') // PENDIENTE
      // Si existe el Tag UBL, y no existe 'Total Importe IGV' con monto mayor a cero, y no existe 'Total Importe IVAP' con monto mayor a cero, y el valor es diferente de la sumatoria de 'Total valor de venta' más 'Sumatoria ISC' más 'Sumatoria Otros Tributos' más 'Sumatoria ICBPER'
      this.precioVentaCurrencyId = domDocumentHelper.select(path.precioVentaCurrencyId)
      if (this.precioVentaCurrencyId && this.precioVentaCurrencyId !== this.tipoMoneda) throw new Error('2071')
      this.mtoRndImpVenta = domDocumentHelper.select(path.mtoRndImpVenta)
      if (this.mtoRndImpVenta && Number(Number(this.mtoRndImpVenta).toFixed(0)) > 1) this.warning.push('4314')
      this.mtoRndImpVentaCurrencyId = domDocumentHelper.select(path.mtoRndImpVentaCurrencyId)
      if (this.mtoRndImpVentaCurrencyId && this.mtoRndImpVentaCurrencyId !== this.tipoMoneda) throw new Error('2071')

      var legendsLength = domDocumentHelper.select(path.legends['.']) ? domDocumentHelper.select(path.legends['.']).length : 0
      var legendsCode = {}
      var legends = {
        code: domDocumentHelper.select(path.legends.code),
        value: domDocumentHelper.select(path.legends.value)
      }
      for (let index = 0; index < legendsLength; index++) {
        var legend = new Legend()
        legend.code = legends.code[index] ? legends.code[index].textContent : null
        legend.value = legends.value[index] ? legends.value[index].textContent : null
        if (legendsCode[legend.code]) throw new Error('3014')
      }
      if (!legendsCode['2005']) this.warning.push('4266') // PENDIENTE
      // Si existe Dirección del lugar en el que se entrega el bien (tag Dirección completa y detallada) y no existe código de leyenda igual a '2005'
      if (this.tipoOperacion === '1001' && !legendsCode['2006']) this.warning.push('4265')
      if (this.tipoOperacion === '1002' && !legendsCode['2006']) this.warning.push('4265')
      if (this.tipoOperacion === '1003' && !legendsCode['2006']) this.warning.push('4265')
      if (this.tipoOperacion === '1004' && !legendsCode['2006']) this.warning.push('4265')
      if (!legendsCode['2007']) this.warning.push('4264') // PENDIENTE
      // Si existe una línea con código de 'Afectación al IGV o IVAP' con valor '17' (IVAP) cuyo 'Mont base' es mayor a cero (cbc:TaxableAmount > 0), y no existe código de leyenda igual a '2007'

      this.perception.indicator = domDocumentHelper.select(path.perception.indicator)
      this.perception.mtoTotal = domDocumentHelper.select(path.perception.mtoTotal)
      this.perception.mtoTotalCurrencyID = domDocumentHelper.select(path.perception.mtoTotalCurrencyID)
      if (this.perception.mtoTotalCurrencyID && this.perception.indicator === 'Percepcion' && this.perception.mtoTotalCurrencyID !== 'PEN') throw new Error('2788')
      if ((this.tipoOperacion === '1001' ||
          this.tipoOperacion === '1002' ||
          this.tipoOperacion === '1003' ||
          this.tipoOperacion === '1004'
      ) && this.perception.indicator !== 'Percepcion') throw new Error('3127')
      if (!(this.tipoOperacion === '1001' ||
        this.tipoOperacion === '1002' ||
        this.tipoOperacion === '1003' ||
        this.tipoOperacion === '1004'
      ) && this.perception.indicator === 'Detraccion') throw new Error('3128')

      this.detraccion.codBienDetraccion = domDocumentHelper.select(path.detraccion.codBienDetraccion)
      if (this.perception.indicator === 'Detraccion' &&
          (!this.detraccion.codBienDetraccion || this.detraccion.codBienDetraccion === '')
      ) throw new Error('3127')
      if (this.perception.indicator === 'Detraccion' &&
          this.detraccion.codBienDetraccion &&
          !catalogServiceCodeSubjectDetraction[this.detraccion.codBienDetraccion]
      ) throw new Error('3033')
      if (this.perception.indicator === 'Detraccion' &&
          this.tipoOperacion === '1002' &&
          this.detraccion.codBienDetraccion === '004'
      ) throw new Error('3129')
      if (this.perception.indicator === 'Detraccion' &&
          this.tipoOperacion === '1003' &&
          this.detraccion.codBienDetraccion === '028'
      ) throw new Error('3129')
      if (this.perception.indicator === 'Detraccion' &&
          this.tipoOperacion === '1004' &&
          this.detraccion.codBienDetraccion === '027'
      ) throw new Error('3129')
      this.detraccion.codBienDetraccionSchemeName = domDocumentHelper.select(path.detraccion.codBienDetraccionSchemeName)
      this.detraccion.codBienDetraccionSchemeAgencyName = domDocumentHelper.select(path.detraccion.codBienDetraccionSchemeAgencyName)
      this.detraccion.codBienDetraccionSchemeUri = domDocumentHelper.select(path.detraccion.codBienDetraccionSchemeUri)
      this.detraccion.indicator = domDocumentHelper.select(path.detraccion.indicator)
      if ((this.tipoOperacion === '1001' ||
        this.tipoOperacion === '1002' ||
        this.tipoOperacion === '1003' ||
        this.tipoOperacion === '1004'
      ) && this.detraccion.indicator !== 'Detraccion') throw new Error('3034')
      this.detraccion.ctaBanco = domDocumentHelper.select(path.detraccion.ctaBanco)
      if (this.detraccion.indicator === 'Detraccion' && (!this.detraccion.ctaBanco || this.detraccion.ctaBanco === '')) throw new Error('3034')
      this.detraccion.codMedioPago = domDocumentHelper.select(path.detraccion.codMedioPago)
      this.detraccion.codMedioPagoListName = domDocumentHelper.select(path.detraccion.codMedioPagoListName)
      this.detraccion.codMedioPagoListAgencyName = domDocumentHelper.select(path.detraccion.codMedioPagoListAgencyName)
      this.detraccion.codMedioPagoListUri = domDocumentHelper.select(path.detraccion.codMedioPagoListUri)
      this.detraccion.mount = domDocumentHelper.select(path.detraccion.mount)
      if (this.perception.indicator === 'Detraccion' && !this.detraccion.mount) throw new Error('3035')
      this.detraccion.mountCurrencyId = domDocumentHelper.select(path.detraccion.mountCurrencyId)
      if (this.perception.indicator === 'Detraccion' && this.detraccion.mountCurrencyId !== 'PEN') throw new Error('3208')
      this.detraccion.percent = domDocumentHelper.select(path.detraccion.percent)

      var anticiposLength = domDocumentHelper.select(path.anticipos['.']) ? domDocumentHelper.select(path.anticipos['.']).length : 0
      var anticiposId = {}
      var anticiposSum = 0
      var anticipos = {
        id: domDocumentHelper.select(path.anticipos.id),
        idSchemeName: domDocumentHelper.select(path.anticipos.idSchemeName),
        idSchemeAgencyName: domDocumentHelper.select(path.anticipos.idSchemeAgencyName),
        total: domDocumentHelper.select(path.anticipos.total),
        totalCurrencyId: domDocumentHelper.select(path.anticipos.totalCurrencyId),
        payDate: domDocumentHelper.select(path.anticipos.payDate)
      }
      for (let index = 0; index < anticiposLength; index++) {
        var prepayment = new Prepayment()
        prepayment.id = anticipos.id[index] ? anticipos.id[index].textContent : null
        if (Number('1') === 1) throw new Error('3212') // PENDIENTE
        // Si no existe documento con 'Tipo de comprobante que se realizó el anticipo' '02' o '03' con el mismo 'Identificador de pago' (cbc:DocumentStatusCode) que el valor del Tag UBL
        prepayment.idSchemeName = anticipos.idSchemeName[index] ? anticipos.idSchemeName[index].textContent : null
        prepayment.idSchemeAgencyName = anticipos.idSchemeAgencyName[index] ? anticipos.idSchemeAgencyName[index].textContent : null
        prepayment.total = anticipos.total[index] ? anticipos.total[index].textContent : null
        if (prepayment.total && !prepayment.id) throw new Error('3211')
        if (prepayment.total && (Number(prepayment.total) < 0 && /^[+-0.]{1,}$/.test(prepayment.total))) throw new Error('2503')
        if (prepayment.total && Number(prepayment.total) > 0) throw new Error('3220') // PENDIENTE
        // Si existe Tag UBL con valor mayor a cero, y no existe 'Total Anticipos' con monto mayor a cero
        prepayment.totalCurrencyId = anticipos.totalCurrencyId[index] ? anticipos.totalCurrencyId[index].textContent : null
        if (prepayment.totalCurrencyId && prepayment.totalCurrencyId !== this.tipoMoneda) throw new Error('2071')
        prepayment.payDate = anticipos.payDate[index] ? anticipos.payDate[index].textContent : null

        if (anticiposId[prepayment.id]) throw new Error('3212')
        anticiposId[prepayment.id] = prepayment
        anticiposSum = Number(anticiposSum) + Number(prepayment.total)
        this.anticipos.push(prepayment)
      }

      this.totalAnticipos = domDocumentHelper.select(path.totalAnticipos)
      if (Number(this.totalAnticipos) > 0 && Number(this.totalAnticipos) !== anticiposSum) throw new Error('2509')
      this.totalAnticiposCurrencyId = domDocumentHelper.select(path.totalAnticiposCurrencyId)

      if (this.totalAnticiposCurrencyId && this.totalAnticiposCurrencyId !== this.tipoMoneda) throw new Error('2071')

      this.envio.id = domDocumentHelper.select(path.envio.id)
      this.envio.idSchemeName = domDocumentHelper.select(path.envio.idSchemeName)
      this.envio.idSchemeAgencyName = domDocumentHelper.select(path.envio.idSchemeAgencyName)
      this.envio.idSchemeUri = domDocumentHelper.select(path.envio.idSchemeUri)

      this.envio.modTraslado = domDocumentHelper.select(path.envio.modTraslado)
      this.envio.modTrasladoListName = domDocumentHelper.select(path.envio.modTrasladoListName)
      this.envio.modTrasladoListAgencyName = domDocumentHelper.select(path.envio.modTrasladoListAgencyName)
      this.envio.modTrasladoListUri = domDocumentHelper.select(path.envio.modTrasladoListUri)

      this.envio.llegada.ubigueo = domDocumentHelper.select(path.envio.llegada.ubigueo)
      if (this.envio.llegada.ubigueo && !catalogGeograficLocationCode[this.envio.llegada.ubigueo]) this.warning.push('4176')
      if (this.envio.id && this.envio.modTraslado && !this.envio.llegada.ubigueo) this.envio.llegada.warning.push('4127')
      if (this.envio.id && !this.envio.modTraslado && this.envio.llegada.ubigueo) this.envio.llegada.warning.push('4135')
      this.envio.llegada.ubigueoSchemeAgencyName = domDocumentHelper.select(path.envio.llegada.ubigueoSchemeAgencyName)
      this.envio.llegada.ubigueoSchemeName = domDocumentHelper.select(path.envio.llegada.ubigueoSchemeName)
      this.envio.llegada.direccion = domDocumentHelper.select(path.envio.llegada.direccion)
      if (this.envio.llegada.direccion && !/^[\w ]{1,100}$/.test(this.envio.llegada.direccion)) this.warning.push('4179')
      if (this.envio.id && this.envio.modTraslado && !this.envio.llegada.direccion) this.envio.llegada.warning.push('4127')
      if (this.envio.id && !this.envio.modTraslado && this.envio.llegada.direccion) this.envio.llegada.warning.push('4135')

      this.envio.partida.ubigueo = domDocumentHelper.select(path.envio.partida.ubigueo)
      if (this.envio.partida.ubigueo && !catalogGeograficLocationCode[this.envio.partida.ubigueo]) this.warning.push('4176')
      if (this.envio.id && this.envio.modTraslado && !this.envio.partida.ubigueo) this.envio.partida.warning.push('4128')
      if (this.envio.id && !this.envio.modTraslado && this.envio.partida.ubigueo) this.envio.partida.warning.push('4136')
      this.envio.partida.ubigueoSchemeAgencyName = domDocumentHelper.select(path.envio.partida.ubigueoSchemeAgencyName)
      this.envio.partida.ubigueoSchemeName = domDocumentHelper.select(path.envio.partida.ubigueoSchemeName)
      this.envio.partida.direccion = domDocumentHelper.select(path.envio.partida.direccion)
      if (this.envio.partida.direccion && !/^[\w ]{1,100}$/.test(this.envio.partida.direccion)) this.warning.push('4184')
      if (this.envio.id && this.envio.modTraslado && !this.envio.partida.direccion) this.envio.partida.warning.push('4128')
      if (this.envio.id && !this.envio.modTraslado && this.envio.partida.direccion) this.envio.partida.warning.push('4136')

      this.envio.transportista.placa = domDocumentHelper.select(path.envio.transportista.placa)
      // if (this.envio.id && this.envio.modTraslado === '01' && !this.envio.partida.ubigueo) this.envio.partida.warning.push('4158')
      if (this.envio.id && this.envio.modTraslado === '02' && !this.envio.transportista.placa) this.envio.transportista.warning.push('4158')
      if (this.envio.id && !this.envio.modTraslado && !this.envio.transportista.placa) this.envio.transportista.warning.push('4158')
      this.envio.transportista.choferDoc = domDocumentHelper.select(path.envio.transportista.choferDoc)
      this.envio.transportista.choferTipoDoc = domDocumentHelper.select(path.envio.transportista.choferTipoDoc)
      if (this.envio.transportista.choferDoc && !this.envio.transportista.choferTipoDoc) this.envio.transportista.warning.push('4172')
      if (this.envio.modTraslado === '01' && this.envio.transportista.placa && !this.envio.transportista.choferDoc) this.envio.transportista.warning.push('4157')
      if (this.envio.modTraslado === '02' && !this.envio.transportista.choferDoc) this.envio.transportista.warning.push('4157')
      if (this.envio.id && !this.envio.modTraslado && !this.envio.transportista.choferDoc) this.envio.transportista.warning.push('4157')
      if (this.envio.transportista.choferTipoDoc === 'A' && /[\w]{1,15}/.test(this.envio.transportista.choferDoc)) this.envio.transportista.warning.push('4174')
      if (this.envio.transportista.choferTipoDoc === '1' && /[0-9]{8}/.test(this.envio.transportista.choferDoc)) this.envio.transportista.warning.push('4174')
      if ((this.envio.transportista.choferTipoDoc === '4' ||
      this.envio.transportista.choferTipoDoc === '7') && /[\w]{1,12}/.test(this.envio.transportista.choferDoc)) this.envio.transportista.warning.push('4174')
      this.envio.transportista.choferDocSchemeName = domDocumentHelper.select(path.envio.transportista.choferDocSchemeName)
      this.envio.transportista.choferDocSchemeAgencyName = domDocumentHelper.select(path.envio.transportista.choferDocSchemeAgencyName)
      this.envio.transportista.choferDocSchemeURI = domDocumentHelper.select(path.envio.transportista.choferDocSchemeURI)
      this.envio.transportista.numDoc = domDocumentHelper.select(path.envio.transportista.numDoc)
      if (this.envio.id && this.envio.modTraslado === '01' && !this.envio.transportista.numDoc) this.envio.transportista.warning.push('4286')
      if (this.envio.id && this.envio.modTraslado === '02' && this.envio.transportista.numDoc) this.envio.transportista.warning.push('4159')
      if (this.envio.id && !this.envio.modTraslado && !this.envio.transportista.numDoc) this.envio.transportista.warning.push('4160')
      if (this.envio.transportista.numDoc) this.envio.transportista.warning.push('4163') // PENDIENTE
      // Si "Datos del Transportista (FG Remitente) o Transportista contratante (FG Transportista) - Tipo de documento de identidad" es 6, el formato del Tag UBL es diferente de numérico de 11 dígitos
      this.envio.transportista.tipoDoc = domDocumentHelper.select(path.envio.transportista.tipoDoc)
      if (this.envio.transportista.numDoc && !this.envio.transportista.tipoDoc) this.envio.transportista.warning.push('4161')
      this.envio.transportista.numDocSchemeName = domDocumentHelper.select(path.envio.transportista.numDocSchemeName)
      this.envio.transportista.numDocSchemeAgencyName = domDocumentHelper.select(path.envio.transportista.numDocSchemeAgencyName)
      this.envio.transportista.numDocSchemeUri = domDocumentHelper.select(path.envio.transportista.numDocSchemeUri)
      this.envio.transportista.rznSocial = domDocumentHelper.select(path.envio.transportista.rznSocial)
      if (this.envio.transportista.rznSocial) this.envio.transportista.warning.push('4164') // PENDIENTE
      // Si "Datos del Transportista (FG Remitente) o Transportista contratante (FG Transportista) - Número de documento de identidad" existe, no existe el Tag UBL
      this.envio.transportista.regMtc = domDocumentHelper.select(path.envio.transportista.regMtc)
      this.envio.transportista.numConstancia = domDocumentHelper.select(path.envio.transportista.numConstancia)

      this.envio.numContenedor = domDocumentHelper.select(path.envio.numContenedor)
      this.envio.pesoTotal = domDocumentHelper.select(path.envio.pesoTotal)
      this.envio.undPesoTotal = domDocumentHelper.select(path.envio.undPesoTotal)

      this.envio.fecTraslado = domDocumentHelper.select(path.envio.fecTraslado)
      if (this.envio.id && this.envio.modTraslado && !this.envio.fecTraslado) this.envio.warning.push('4126')
      if (this.envio.id && !this.envio.modTraslado && !this.envio.fecTraslado) this.envio.warning.push('4126')
      this.envio.subContract = domDocumentHelper.select(path.envio.subContract)
      if (this.envio.id && this.envio.modTraslado && !this.envio.subContract) this.envio.warning.push('4129')

      this.warning = this.warning.concat(this.company.warning,
        this.company.address.warning,
        this.client.warning,
        this.client.address.warning,
        this.totalTax.warning,
        this.envio.warning,
        this.envio.llegada.warning,
        this.envio.partida.warning,
        this.envio.transportista.warning
      )
      resolve(this.warning)
    })
  }
}

module.exports = Factura20Loader
