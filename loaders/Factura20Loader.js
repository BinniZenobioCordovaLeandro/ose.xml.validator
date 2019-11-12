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
var Term = require('../templates/Term')

var DomDocumentHelper = require('../helpers/DomDocumentHelper')

var path = require('./ocpp/Factura20.json')

var catalogDocumentTypeCode = require('../catalogs/catalogDocumentTypeCode.json')
var catalogTaxRelatedDocumentCode = require('../catalogs/catalogTaxRelatedDocumentCode.json')
var catalogIgvAffectationTypeCode = require('../catalogs/catalogIgvAffectationTypeCode.json')
var catalogTaxTypeCode = require('../catalogs/catalogTaxTypeCode.json')
var catalogIscCalculationSystemTypeCode = require('../catalogs/catalogIscCalculationSystemTypeCode.json')
var catalogChargeCode = require('../catalogs/catalogChargeCode.json')
var catalogGeograficLocationCode = require('../catalogs/catalogGeograficLocationCode.json')
var catalogCountryCode = require('../catalogs/catalogCountryCode.json')
var catalogIdentityDocumentTypeCode = require('../catalogs/catalogIdentityDocumentTypeCode.json')
var catalogServiceCodeSubjectDetraction = require('../catalogs/catalogServiceCodeSubjectDetraction.json')
var catalogLoanType = require('../catalogs/catalogLoanType.json')
var catalogIndicatorFirstHome = require('../catalogs/catalogIndicatorFirstHome.json')
var listContribuyente = require('../catalogs/listContribuyente.json')
var listPadronContribuyente = require('../catalogs/listPadronContribuyente.json')
var listAutorizacionComprobanteContingencia = require('../catalogs/listAutorizacionComprobanteContingencia.json')
var listAutorizacionComprobanteFisico = require('../catalogs/listAutorizacionComprobanteFisico.json')
var listComprobantePagoElectronico = require('../catalogs/listComprobantePagoElectronico.json')
var parameterMaximunSendTerm = require('../catalogs/parameterMaximunSendTerm.json')
var parameterIgvTax = require('../catalogs/parameterIgvTax.json')
var parameterIvapTax = require('../catalogs/parameterIvapTax.json')
var parameterIcbperTax = require('../catalogs/parameterIcbperTax.json')

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
      this.customization = domDocumentHelper.select(path.customization)
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
      if (!/^[0-9]{1}/.test(this.serie) && (
        listComprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)] && (
          listComprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe === 0 ||
        listComprobantePagoElectronico[(rucTipoSerie + '-' + this.correlativo)].ind_estado_cpe === 2)
      )) throw new Error('1032')
      if (/^[0-9]{1}/.test(this.serie) && !(listAutorizacionComprobanteContingencia[rucTipoSerie] && (
        this.correlativo >= listAutorizacionComprobanteContingencia[rucTipoSerie].num_ini_cpe &&
            this.correlativo <= listAutorizacionComprobanteContingencia[rucTipoSerie].num_fin_cpe
      ))) throw new Error('3207')
      if (/^[0-9]{1}/.test(this.serie) && !(listAutorizacionComprobanteFisico[rucTipoSerie] && (
        this.correlativo >= listAutorizacionComprobanteFisico[rucTipoSerie].num_ini_cpe &&
            this.correlativo <= listAutorizacionComprobanteFisico[rucTipoSerie].num_fin_cpe
      ))) throw new Error('3207')

      this.fechaEmision = domDocumentHelper.select(path.fechaEmision)
      if (!/^[0-9]{1}/.test(this.serie) &&
          moment().diff(moment(this.fechaEmision), 'days') > parameterMaximunSendTerm[this.fileInfo.tipoComprobante].day &&
          !domDocumentHelper.select(path.fechaVencimiento) &&
          moment().diff(moment(this.fechaEmision), 'days') >= 0
      ) throw new Error('2108')
      this.horaEmision = domDocumentHelper.select(path.horaEmision)

      this.tipoDoc = domDocumentHelper.select(path.tipoDoc)
      if (this.tipoDoc !== this.fileInfo.tipoComprobante && catalogDocumentTypeCode[this.tipoDoc]) throw new Error('1003')
      this.tipoDocListAgencyName = domDocumentHelper.select(path.tipoDocListAgencyName)
      this.tipoDocListName = domDocumentHelper.select(path.tipoDocListName)
      this.tipoDocListURI = domDocumentHelper.select(path.tipoDocListURI)
      this.tipoOperacion = domDocumentHelper.select(path.tipoOperacion)
      this.tipoOperacionName = domDocumentHelper.select(path.tipoOperacionName)
      this.tipoOperacionListSchemeUri = domDocumentHelper.select(path.tipoOperacionListSchemeUri)
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
      if (this.tipoOperacion === '0201' && listPadronContribuyente[this.company.ruc].ind_padron !== '05') throw new Error('3097')
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

      this.company.agent.ruc = domDocumentHelper.select(path.company.agent.ruc)
      if (this.tipoOperacion === '0302' && !this.company.agent.ruc) throw new Error('3156')
      this.company.agent.rucSchemeId = domDocumentHelper.select(path.company.agent.rucSchemeId)
      this.company.agent.rucSchemeName = domDocumentHelper.select(path.company.agent.rucSchemeName)
      this.company.agent.rucSchemeAgencyName = domDocumentHelper.select(path.company.agent.rucSchemeAgencyName)
      this.company.agent.rucSchemeUri = domDocumentHelper.select(path.company.agent.rucSchemeUri)

      this.client.numDoc = domDocumentHelper.select(path.client.numDoc)
      this.client.tipoDoc = domDocumentHelper.select(path.client.tipoDoc)
      if (
        (this.tipoOperacion === '0200' ||
        this.tipoOperacion === '0201' ||
        this.tipoOperacion === '0204' ||
        this.tipoOperacion === '0208') &&
      this.client.tipoDoc === '6') throw new Error('2800')
      if ((this.tipoOperacion === '0202' ||
          this.tipoOperacion === '0203' ||
          this.tipoOperacion === '0205' ||
          this.tipoOperacion === '0206' ||
          this.tipoOperacion === '0207' ||
          this.tipoOperacion === '0401') && !catalogIdentityDocumentTypeCode[this.client.tipoDoc] && this.client.tipoDoc !== '-') throw new Error('2800')
      if (this.tipoOperacion === '0112' && this.client.tipoDoc !== '1' && this.client.tipoDoc !== '6') throw new Error('2800')
      if (this.client.tipoDoc !== '6') throw new Error('2800')

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
        if (!(document.tipoDoc === '02' || document.tipoDoc === '03') && document.payIdentifier !== document.nroDoc) throw new Error('3213')
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
      if (this.tipoOperacion === '1001' && !legendsCode['2006']) this.warning.push('4265')
      if (this.tipoOperacion === '1002' && !legendsCode['2006']) this.warning.push('4265')
      if (this.tipoOperacion === '1003' && !legendsCode['2006']) this.warning.push('4265')
      if (this.tipoOperacion === '1004' && !legendsCode['2006']) this.warning.push('4265')

      if (domDocumentHelper.select(path.mtoDescuentos)) this.mtoDescuentos = domDocumentHelper.select(path.mtoDescuentos)
      this.mtoDescuentosCurrencyId = domDocumentHelper.select(path.mtoDescuentosCurrencyId)
      if (this.mtoDescuentosCurrencyId && this.mtoDescuentosCurrencyId !== this.tipoMoneda) throw new Error('2071')
      if (domDocumentHelper.select(path.sumOtrosCargos)) this.sumOtrosCargos = domDocumentHelper.select(path.sumOtrosCargos)
      this.sumOtrosCargosCurrencyId = domDocumentHelper.select(path.sumOtrosCargosCurrencyId)
      if (this.sumOtrosCargosCurrencyId && this.sumOtrosCargosCurrencyId !== this.tipoMoneda) throw new Error('2071')
      this.mtoImpVenta = domDocumentHelper.select(path.mtoImpVenta)
      this.mtoImpVentaCurrencyId = domDocumentHelper.select(path.mtoImpVentaCurrencyId)
      if (this.mtoImpVentaCurrencyId && this.mtoImpVentaCurrencyId !== this.tipoMoneda) this.warning.push('2071')
      this.valorVenta = domDocumentHelper.select(path.valorVenta)
      this.valorVentaCurrencyId = domDocumentHelper.select(path.valorVentaCurrencyId)
      if (this.valorVentaCurrencyId && this.valorVentaCurrencyId !== this.tipoMoneda) throw new Error('2071')
      this.precioVenta = domDocumentHelper.select(path.precioVenta)
      this.precioVentaCurrencyId = domDocumentHelper.select(path.precioVentaCurrencyId)
      if (this.precioVentaCurrencyId && this.precioVentaCurrencyId !== this.tipoMoneda) throw new Error('2071')
      this.mtoRndImpVenta = domDocumentHelper.select(path.mtoRndImpVenta)
      this.mtoRndImpVentaCurrencyId = domDocumentHelper.select(path.mtoRndImpVentaCurrencyId)
      if (this.mtoRndImpVentaCurrencyId && this.mtoRndImpVentaCurrencyId !== this.tipoMoneda) throw new Error('2071')

      var detailsLength = domDocumentHelper.select(path.details['.']) ? domDocumentHelper.select(path.details['.']).length : 0
      var detailsId = {}
      var detailsCodProducto = {}
      var detailsMtoType = {}
      var detailsTotalTaxTaxDetailsCodeCumulative = {}
      var detailsTotalTaxTaxDetailsCodeAboveZeroCumulative = {}
      var detailsCargosCodTipoCumulative = {}
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
        totalTax: {
          taxDetails: {}
        },
        mtoValorVenta: domDocumentHelper.select(path.details.mtoValorVenta),
        mtoValorVentaCurrencyId: domDocumentHelper.select(path.details.mtoValorVentaCurrencyId),
        cargos: {},
        envio: {
          partida: {},
          llegada: {},
          terminos: {}
        }
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
          quantity: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.quantity}`),
          quantityUnitCode: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.quantityUnitCode}`),
          codeListName: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.codeListName}`),
          codeListAgencyName: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.codeListAgencyName}`),
          codeListURI: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.codeListURI}`),
          value: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.value}`),
          fecInicio: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.fecInicio}`),
          horInicio: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.horInicio}`),
          fecFin: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.fecFin}`),
          duracion: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.duracion}`),
          duracionUnitCode: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.atributos.duracionUnitCode}`)
        }
        for (let index = 0; index < details.atributosLength; index++) {
          var detailAttribute = new DetailAttribute()
          detailAttribute.name = details.atributos.name[index] ? details.atributos.name[index].textContent : null
          detailAttribute.code = details.atributos.code[index] ? details.atributos.code[index].textContent : null
          detailAttribute.codeListName = details.atributos.codeListName[index] ? details.atributos.codeListName[index].textContent : null
          detailAttribute.codeListAgencyName = details.atributos.codeListAgencyName[index] ? details.atributos.codeListAgencyName[index].textContent : null
          detailAttribute.codeListURI = details.atributos.codeListURI[index] ? details.atributos.codeListURI[index].textContent : null
          detailAttribute.quantity = details.atributos.quantity[index] ? details.atributos.quantity[index] : null
          if (detailAttribute.code === '3006' && !detailAttribute.quantity) throw new Error('3135')
          if (detailAttribute.code === '3006' && (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(detailAttribute.quantity) || !(Number(detailAttribute.quantity) > 0))) detailAttribute.warning.push('4281')
          detailAttribute.quantityUnitCode = details.atributos.quantityUnitCode[index] ? details.atributos.quantityUnitCode[index].textContent : null
          detailAttribute.value = details.atributos.value[index] ? details.atributos.value[index].textContent : null
          if ((detailAttribute.code === '3001' || detailAttribute.code === '3002' || detailAttribute.code === '3003' || detailAttribute.code === '3004') && (!detailAttribute.value || detailAttribute.value === '')) throw new Error('3064')
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
          if (detailAttribute.code === '7000' && !detailAttribute.value) throw new Error('3064')
          if (
            (detailAttribute.code === '4000' ||
            detailAttribute.code === '4001' ||
            detailAttribute.code === '4007' ||
            detailAttribute.code === '4008' ||
            detailAttribute.code === '4009') &&
            (!detailAttribute.value || detailAttribute.value === '')
          ) throw new Error('3064')

          if (detailAttribute.code === '4008' && !catalogIdentityDocumentTypeCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4000' && !catalogCountryCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4001' && !catalogCountryCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4007' && !/[\w ]{3,200}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4009' && !/[\w ]{3,20}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')

          if (
            (detailAttribute.code === '4000' ||
            detailAttribute.code === '4007' ||
            detailAttribute.code === '4008' ||
            detailAttribute.code === '4009') &&
            (!detailAttribute.value || detailAttribute.value === '')
          ) throw new Error('3064')
          if (
            (detailAttribute.code === '5000' ||
            detailAttribute.code === '5001' ||
            detailAttribute.code === '5002' ||
            detailAttribute.code === '5003') &&
            (!detailAttribute.value || detailAttribute.value === '')
          ) throw new Error('3064')

          if (detailAttribute.code === '5000' && !/[\w ]{1,20}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '5001' && !/[\w ]{1,10}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '5002' && !/[\w ]{1,30}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '5003' && !/[\w ]{1,30}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')

          if (
            (detailAttribute.code === '4001' ||
            detailAttribute.code === '4002' ||
            detailAttribute.code === '4003' ||
            detailAttribute.code === '4004' ||
            detailAttribute.code === '4005' ||
            detailAttribute.code === '4006' ||
            detailAttribute.code === '4007' ||
            detailAttribute.code === '4008' ||
            detailAttribute.code === '4009' ||
            detailAttribute.code === '4010' ||
            detailAttribute.code === '4011') &&
            (!detailAttribute.value || detailAttribute.value === '')
          ) throw new Error('3064')

          if (detailAttribute.code === '7001' && !catalogLoanType[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '7002' && !catalogIndicatorFirstHome[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '7003' && !/[\w ]{3, 50}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '7004' && !/[\w ]{3, 50}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '7005' && !/^([12]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]))$/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '7006' && !catalogGeograficLocationCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '7007' && !/[\w ]{3, 200}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')

          if ((detailAttribute.code === '4030' || detailAttribute.code === '4031' || detailAttribute.code === '4032' || detailAttribute.code === '4033') && (!detailAttribute.value || detailAttribute.value === '')) throw new Error('3064')

          if (detailAttribute.code === '4030' && !catalogGeograficLocationCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4032' && !catalogGeograficLocationCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4031' && !/[\w ]{3, 200}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4033' && !/[\w ]{3, 200}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if ((detailAttribute.code === '4040' || detailAttribute.code === '4041' || detailAttribute.code === '4042' || detailAttribute.code === '4043' || detailAttribute.code === '4044' || detailAttribute.code === '4045' || detailAttribute.code === '4046' || detailAttribute.code === '4049') && (!detailAttribute.value || detailAttribute.value === '')) throw new Error('3064')
          if (detailAttribute.code === '4040' && !/[\w ]{3, 200}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4041' && !catalogIdentityDocumentTypeCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4042' && !catalogGeograficLocationCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4043' && !/[\w ]{3, 200}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4044' && !catalogGeograficLocationCode[detailAttribute.value]) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4045' && !/[\w ]{3, 200}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4046' && !/[\w ]{3, 100}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '4049' && !/[\w ]{3, 20}/.test(detailAttribute.value)) detailAttribute.warning.push('4280')
          if (detailAttribute.code === '7021' && !/^[0-9]{4}-[0-9]{2}-[0-9]{3}-[0-9]{6}$/.test(detailAttribute.value)) detailAttribute.warning.push('4202')
          detailAttribute.fecInicio = details.atributos.fecInicio[index] ? details.atributos.fecInicio[index].textContent : null
          if (detailAttribute.code === '3059' && !detailAttribute.fecInicio) detailAttribute.warning.push('3065')
          if (detailAttribute.code === '4002' && !detailAttribute.fecInicio) throw new Error('3065')
          if (detailAttribute.code === '4003' && !detailAttribute.fecInicio) throw new Error('3065')
          if (detailAttribute.code === '4004' && !detailAttribute.fecInicio) throw new Error('3065')
          if (detailAttribute.code === '4006' && !detailAttribute.fecInicio) throw new Error('3065')
          if (detailAttribute.code === '3005' && !detailAttribute.fecInicio) throw new Error('3065')
          if (detailAttribute.code === '4006' && !detailAttribute.fecInicio) throw new Error('3065')
          if (detailAttribute.code === '4048' && !detailAttribute.fecInicio) throw new Error('3065')

          detailAttribute.horInicio = details.atributos.horInicio[index] ? details.atributos.horInicio[index].textContent : null
          if (detailAttribute.code === '3060' && !detailAttribute.horInicio) throw new Error('3172')
          if (detailAttribute.code === '4047' && !detailAttribute.horInicio) throw new Error('3172')

          detailAttribute.fecFin = details.atributos.fecFin[index] ? details.atributos.fecFin[index].textContent : null
          detailAttribute.duracion = details.atributos.duracion[index] ? details.atributos.duracion[index].textContent : null
          if (detailAttribute.code === '3135' && !detailAttribute.duracion) throw new Error('3135')
          detailAttribute.duracionUnitCode = details.atributos.duracionUnitCode[index] ? details.atributos.duracionUnitCode[index].textContent : null
          details.atributosCode[detailAttribute.code] = detailAttribute
          saleDetail.atributos.push(detailAttribute)
          saleDetail.warning = saleDetail.warning.concat(detailAttribute.warning)
        }
        if (this.tipoOperacion === '1002' && !details.atributosCode['3001']) throw new Error('3063')
        if (this.tipoOperacion === '1002' && !details.atributosCode['3002']) throw new Error('3130')
        if (this.tipoOperacion === '1002' && !details.atributosCode['3003']) throw new Error('3131')
        if (this.tipoOperacion === '1002' && !details.atributosCode['3004']) throw new Error('3132')
        if (this.tipoOperacion === '1002' && !details.atributosCode['3005']) throw new Error('3134')
        if (this.tipoOperacion === '1002' && !details.atributosCode['3006']) throw new Error('3133')
        if (this.tipoOperacion === '0202' && !details.atributosCode['4000']) throw new Error('3138')
        if (this.tipoOperacion === '0202' && !details.atributosCode['4001']) throw new Error('3140')
        if (this.tipoOperacion === '0202' && !details.atributosCode['4002']) throw new Error('3141')
        if (this.tipoOperacion === '0202' && !details.atributosCode['4003']) throw new Error('3142')
        if (this.tipoOperacion === '0202' && !details.atributosCode['4004']) throw new Error('3143')
        if (this.tipoOperacion === '0202' && !details.atributosCode['4005']) throw new Error('3145')
        if (this.tipoOperacion === '0202' && !details.atributosCode['4006']) throw new Error('3144')
        if (this.tipoOperacion === '0202' && !details.atributosCode['4007']) throw new Error('3139')
        if (this.tipoOperacion === '0202' && !details.atributosCode['4008']) throw new Error('3137')
        if (this.tipoOperacion === '0202' && !details.atributosCode['4009']) throw new Error('3136')
        if (this.tipoOperacion === '0205' && !details.atributosCode['4000']) throw new Error('3138')
        if (this.tipoOperacion === '0205' && !details.atributosCode['4007']) throw new Error('3139')
        if (this.tipoOperacion === '0205' && !details.atributosCode['4008']) throw new Error('3137')
        if (this.tipoOperacion === '0205' && !details.atributosCode['4009']) throw new Error('3136')
        if (this.tipoOperacion === '0301' && !details.atributosCode['4030']) throw new Error('3168')
        if (this.tipoOperacion === '0301' && !details.atributosCode['4031']) throw new Error('3169')
        if (this.tipoOperacion === '0301' && !details.atributosCode['4032']) throw new Error('3170')
        if (this.tipoOperacion === '0301' && !details.atributosCode['4033']) throw new Error('3171')
        if (this.tipoOperacion === '0302' && !details.atributosCode['4040']) throw new Error('3159')
        if (this.tipoOperacion === '0302' && !details.atributosCode['4041']) throw new Error('3160')
        if (this.tipoOperacion === '0302' && !details.atributosCode['4049']) throw new Error('3204')
        if (this.tipoOperacion === '0302' && !details.atributosCode['4042']) throw new Error('3161')
        if (this.tipoOperacion === '0302' && !details.atributosCode['4043']) throw new Error('3162')
        if (this.tipoOperacion === '0302' && !details.atributosCode['4044']) throw new Error('3163')
        if (this.tipoOperacion === '0302' && !details.atributosCode['4045']) throw new Error('3164')
        if (this.tipoOperacion === '0302' && !details.atributosCode['4046']) throw new Error('3165')
        if (this.tipoOperacion === '0302' && !details.atributosCode['4047']) throw new Error('3166')
        if (this.tipoOperacion === '0302' && !details.atributosCode['4048']) throw new Error('3167')

        if (details.atributosCode['4004'] && details.atributosCode['4003'] &&
            (moment(details.atributosCode['4004'].fecInicio) < moment(details.atributosCode['4003'].fecInicio))
        ) detailAttribute.warning.push('4282')

        if ((details.atributosCode['5001'] ||
            details.atributosCode['5002'] ||
            details.atributosCode['5003']) &&
          !details.atributosCode['5000']) throw new Error('3146')
        if ((details.atributosCode['5001'] ||
            details.atributosCode['5002'] ||
            details.atributosCode['5003']) &&
          !details.atributosCode['5001']) throw new Error('3147')
        if ((details.atributosCode['5001'] ||
            details.atributosCode['5002'] ||
            details.atributosCode['5003']) &&
          !details.atributosCode['5002']) throw new Error('3148')
        if ((details.atributosCode['5001'] ||
            details.atributosCode['5002'] ||
            details.atributosCode['5003']) &&
          !details.atributosCode['5003']) throw new Error('3149')

        if (saleDetail.codProducto === '84121901' && !details.atributosCode['7001']) throw new Error('3150')
        if (saleDetail.codProducto === '84121901' &&
            (details.atributosCode['7002'] && details.atributosCode['7002'].value === 3) &&
          !details.atributosCode['7003']) throw new Error('3151')
        if (saleDetail.codProducto === '84121901' && !details.atributosCode['7004']) throw new Error('3152')
        if (saleDetail.codProducto === '84121901' && !details.atributosCode['7005']) throw new Error('3153')
        if (saleDetail.codProducto === '84121901' &&
            (details.atributosCode['7002'] && details.atributosCode['7002'].value === 3) &&
          !details.atributosCode['7006']) throw new Error('3154')
        if (saleDetail.codProducto === '84121901' &&
            (details.atributosCode['7002'] && details.atributosCode['7002'].value === 3) &&
          !details.atributosCode['7007']) throw new Error('3155')

        saleDetail.descripcion = details.descripcion[index] ? details.descripcion[index].textContent : null
        saleDetail.mtoValorUnitario = details.mtoValorUnitario[index] ? details.mtoValorUnitario[index].textContent : null
        saleDetail.mtoValorUnitarioCurrencyId = details.mtoValorUnitarioCurrencyId[index] ? details.mtoValorUnitarioCurrencyId[index].textContent : null
        if (saleDetail.mtoValorUnitarioCurrencyId && saleDetail.mtoValorUnitarioCurrencyId !== this.tipoMoneda) throw new Error('2071')
        if (Number(details.mtoPrecioUnitario[index].length) > 0) throw new Error(2409)
        saleDetail.mtoType = details.mtoType[index] ? details.mtoType[index].textContent : null
        saleDetail.mtoTypeListName = details.mtoTypeListName[index] ? details.mtoTypeListName[index].textContent : null
        saleDetail.mtoTypeListAgencyName = details.mtoTypeListAgencyName[index] ? details.mtoTypeListAgencyName[index].textContent : null
        saleDetail.mtoTypeListUri = details.mtoTypeListUri[index] ? details.mtoTypeListUri[index].textContent : null

        saleDetail.mtoPrecioUnitario = details.mtoPrecioUnitario[index] ? details.mtoPrecioUnitario[index].textContent : null
        saleDetail.mtoPrecioUnitarioCurrencyId = details.mtoPrecioUnitarioCurrencyId[index] ? details.mtoPrecioUnitarioCurrencyId[index].textContent : null
        if (saleDetail.mtoPrecioUnitarioCurrencyId !== this.tipoMoneda) throw new Error('2071')

        saleDetail.mtoValorVenta = details.mtoValorVenta[index] ? details.mtoValorVenta[index].textContent : null
        saleDetail.mtoValorVentaCurrencyId = details.mtoValorVentaCurrencyId[index] ? details.mtoValorVentaCurrencyId[index].textContent : null
        if (saleDetail.mtoValorVentaCurrencyId && saleDetail.mtoValorVentaCurrencyId !== this.tipoMoneda) throw new Error('2071')

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
        details.totalTax.taxDetailsCodeTaxableAmountAboveZero = {}
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
          if (!details.totalTax.taxDetailsCodeTaxableAmountAboveZero['2000'] && Number(taxDetail.taxableAmount) !== Number(saleDetail.mtoValorVenta)) taxDetail.warning.push('4294')
          taxDetail.taxableAmountCurrencyId = details.totalTax.taxDetails.taxableAmountCurrencyId[index] ? details.totalTax.taxDetails.taxableAmountCurrencyId[index].textContent : null
          if (taxDetail.taxableAmountCurrencyId && taxDetail.taxableAmountCurrencyId !== this.tipoMoneda) throw new Error('2071')
          taxDetail.taxAmount = details.totalTax.taxDetails.taxAmount[index] ? details.totalTax.taxDetails.taxAmount[index].textContent : null
          if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(taxDetail.taxAmount) && /^[+-0.]{1,}$/.test(taxDetail.taxAmount)) throw new Error('2033')
          if (details.totalTax.taxDetailsCode['2000'] && Number(details.totalTax.taxDetailsCode['2000'].taxableAmount) > 0 &&
            (Number(taxDetail.taxableAmount) !== (Number(saleDetail.mtoValorVenta) + Number(taxDetail.taxAmount)) ||
              (Number(taxDetail.taxableAmount) <= (Number(saleDetail.mtoValorVenta) + Number(taxDetail.taxAmount)) + 1 &&
                Number(taxDetail.taxableAmount) >= (Number(saleDetail.mtoValorVenta) + Number(taxDetail.taxAmount)) - 1)
            )) taxDetail.warning.push('4294')
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
          if (taxDetail.taxExemptionReasonCode === '17' && Number(taxDetail.taxableAmount) > 0 && !legendsCode['2007']) this.warning.push('4264')
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
          if ((taxDetail.code === '9995' || taxDetail.co7e === '9997' ||
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
          if (taxDetail.code === '9996' && Number(taxDetail.taxableAmount) > 0 && (
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
          if ((taxDetail.code === '1000' || taxDetail.code === '1016') && Number(taxDetail.taxableAmount) > 0.06 && /^[+-0.]{1,}$/.test(taxDetail.taxAmount)) throw new Error('3111')
          if ((taxDetail.code !== '2000' || taxDetail.code !== '9999') && Number(taxDetail.taxableAmount) > 0 && !taxDetail.taxExemptionReasonCode) throw new Error('2371')
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
          if (taxDetail.code === '9996' && Number(taxDetail.taxableAmount) > 0 && (taxDetail.taxExemptionReasonCode === '11' || taxDetail.taxExemptionReasonCode === '12' || taxDetail.taxExemptionReasonCode === '13' || taxDetail.taxExemptionReasonCode === '14' || taxDetail.taxExemptionReasonCode === '15' || taxDetail.taxExemptionReasonCode === '16' || taxDetail.taxExemptionReasonCode === '17') && /^[+-0.]{1,}$/.test(taxDetail.percent)) throw new Error('2993')
          if ((taxDetail.code === '1000' || taxDetail.code === '1016') && taxDetail.taxableAmount > 0 && /^[+-0.]{1,}$/.test(taxDetail.percent)) throw new Error('2993')
          if (taxDetail.code === '7152' && Number(taxDetail.baseUnitMeasure) > 0 && Number(Number(taxDetail.taxAmount).toFixed(2)) !== Number((Number(taxDetail.perUnitAmount) * Number(taxDetail.baseUnitMeasure)).toFixed(2))) throw new Error('4318')
          if (taxDetail.code === '7152' && !taxDetail.baseUnitMeasure) throw new Error('3237')
          if (taxDetail.code === '7152' && Number(taxDetail.baseUnitMeasure) > 0 && /^[+-0.]{1,}$/.test(taxDetail.perUnitAmount)) throw new Error('3238')
          if (taxDetail.code === '7152' && Number(taxDetail.baseUnitMeasure) > 0 && taxDetail.tipoMoneda === 'PEN' && Number(taxDetail.perUnitAmount) !== Number(parameterIcbperTax[this.fechaEmision.replace(/-/g, '')])) this.warning.push('4237')
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

          if (Number(taxDetail.taxableAmount) > 0) details.totalTax.taxDetailsCodeTaxableAmountAboveZero[taxDetail.code] = taxDetail

          if (detailsTotalTaxTaxDetailsCodeCumulative[taxDetail.code]) {
            detailsTotalTaxTaxDetailsCodeCumulative[taxDetail.code].taxableAmount += Number(taxDetail.taxableAmount)
            detailsTotalTaxTaxDetailsCodeCumulative[taxDetail.code].taxAmount += Number(taxDetail.taxAmount)
            detailsTotalTaxTaxDetailsCodeCumulative[taxDetail.code].mtoValorVenta += Number(saleDetail.mtoValorVenta)
          } else {
            detailsTotalTaxTaxDetailsCodeCumulative[taxDetail.code] = {}
            detailsTotalTaxTaxDetailsCodeCumulative[taxDetail.code].taxableAmount = Number(taxDetail.taxableAmount)
            detailsTotalTaxTaxDetailsCodeCumulative[taxDetail.code].taxAmount = Number(taxDetail.taxAmount)
            detailsTotalTaxTaxDetailsCodeCumulative[taxDetail.code].mtoValorVenta = Number(saleDetail.mtoValorVenta)
          }
          if (detailsTotalTaxTaxDetailsCodeAboveZeroCumulative[taxDetail.code]) {
            if (Number(taxDetail.taxableAmount) > 0) detailsTotalTaxTaxDetailsCodeAboveZeroCumulative[taxDetail.code].mtoValorVenta += Number(saleDetail.mtoValorVenta)
            if (Number(taxDetail.taxAmount) > 0) detailsTotalTaxTaxDetailsCodeAboveZeroCumulative[taxDetail.code].taxAmount += Number(saleDetail.taxAmount)
          } else {
            detailsTotalTaxTaxDetailsCodeAboveZeroCumulative[taxDetail.code] = {}
            detailsTotalTaxTaxDetailsCodeAboveZeroCumulative[taxDetail.code].mtoValorVenta = (Number(taxDetail.taxableAmount) > 0) ? Number(saleDetail.mtoValorVenta) : Number(0)
            detailsTotalTaxTaxDetailsCodeAboveZeroCumulative[taxDetail.code].taxAmount = (Number(taxDetail.taxAmount) > 0) ? Number(saleDetail.taxAmount) : Number(0)
          }

          saleDetail.totalTax.taxDetails.push(taxDetail) // re-check this
          saleDetail.totalTax.warning = saleDetail.totalTax.warning.concat(taxDetail.warning) // re-check this
        }
        if (!(
          (details.totalTax.taxDetailsCode['1000'] && Number(details.totalTax.taxDetailsCode['1000'].taxableAmount) > 0) ||
          (details.totalTax.taxDetailsCode['1016'] && Number(details.totalTax.taxDetailsCode['1016'].taxableAmount) > 0) ||
          (details.totalTax.taxDetailsCode['9996'] && Number(details.totalTax.taxDetailsCode['9996'].taxableAmount) > 0) ||
          (details.totalTax.taxDetailsCode['9997'] && Number(details.totalTax.taxDetailsCode['9997'].taxableAmount) > 0) ||
          // Si el 'Código de tributo' es '9997', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones exoneradas con 'Código de tributo de línea' igual a '9997' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos exonerados (Código '05'), con una tolerancia + - 1
          (details.totalTax.taxDetailsCode['9997'] && Number(details.totalTax.taxDetailsCode['9997'].taxableAmount) > 0) ||
          // Si el 'Código de tributo' es '9998', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones inafectas con 'Código de tributo de línea' igual a '9998' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos inafectos (Código '06'), con una tolerancia + - 1
          (details.totalTax.taxDetailsCode['9998'] && Number(details.totalTax.taxDetailsCode['9998'].taxableAmount) > 0)
        )) throw new Error('3105')
        if (Object.keys(details.totalTax.taxDetailsCodeTaxableAmountAboveZero).length > 0 &&
          ((Object.keys(details.totalTax.taxDetailsCodeTaxableAmountAboveZero).length === 2 &&
            !((details.totalTax.taxDetailsCodeTaxableAmountAboveZero['1000'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['2000']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['1016'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9999']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9995'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9999']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9996'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['2000']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9997'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['2000']) ||
              // Si el 'Código de tributo' es '9997', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones exoneradas con 'Código de tributo de línea' igual a '9997' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos exonerados (Código '05'), con una tolerancia + - 1
              (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9997'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['2000']) ||
              // Si el 'Código de tributo' es '9998', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones inafectas con 'Código de tributo de línea' igual a '9998' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos inafectos (Código '06'), con una tolerancia + - 1
              (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9998'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['2000'])
            )) || (Object.keys(details.totalTax.taxDetailsCodeTaxableAmountAboveZero).length === 3 &&
            !((details.totalTax.taxDetailsCodeTaxableAmountAboveZero['1000'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['2000'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9999']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9996'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['2000'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9999']) ||
              (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9997'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['2000'] && details.totalTax.taxDetailsCodeTaxableAmountAbove7ero['9999']) ||
              // Si el 'Código de tributo' es '9997', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones exoneradas con 'Código de tributo de línea' igual a '9997' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos exonerados (Código '05'), con una tolerancia + - 1
              (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9997'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['2000'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9999']) ||
              // Si el 'Código de tributo' es '9998', el valor del Tag UBL es diferente a la sumatoria de 'Valor de venta por ítem' (cbc:LineExtensionAmount) que correspondan a ítems de operaciones inafectas con 'Código de tributo de línea' igual a '9998' y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), menos los 'Montos de Descuentos globales' por anticipos inafectos (Código '06'), con una tolerancia + - 1
              (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9998'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['2000'] && details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9999']))
          ) || Object.keys(details.totalTax.taxDetailsCodeTaxableAmountAboveZero).length > 3)) throw new Error('3223')

        if (!details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9996'] && saleDetail.mtoType === '02' && Number(saleDetail.mtoPrecioUnitario)) throw new Error('3224')
        if (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9996'] && saleDetail.mtoType !== '02') throw new Error('3234')

        details.cargosLength = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos['.']}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.cargos['.']}`).length : 0
        details.cargosCodTipo = {}
        details.cargosCodTipoCumulative = {}
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
          if (!(charge.codTipo === '00' || charge.codTipo === '01' || charge.codTipo === '47' || charge.codTipo === '48'))charge.warning.push('4268')
          charge.indicator = details.cargos.indicator[index] ? details.cargos.indicator[index].textContent : null
          if (String(charge.indicator) !== 'true' && (charge.codTipo === '47' || charge.codTipo === '48')) throw new Error('3114')
          if (String(charge.indicator) !== 'false' && (charge.codTipo === '00' || charge.codTipo === '01')) throw new Error('3114')
          charge.codTipoListAgencyName = details.cargos.codTipoListAgencyName[index] ? details.cargos.codTipoListAgencyName[index].textContent : null
          charge.codTipoListName = details.cargos.codTipoListName[index] ? details.cargos.codTipoListName[index].textContent : null
          charge.codTipoListUri = details.cargos.codTipoListUri[index] ? details.cargos.codTipoListUri[index].textContent : null
          charge.factor = details.cargos.factor[index] ? details.cargos.factor[index].textContent : null
          if (charge.factor && (!/^[+]?[0-9]{1,3}\.[0-9]{1,5}$/.test(charge.factor) || !/^[+-0.]{1,}$/.test(charge.factor))) throw new Error('3052')
          charge.montoBase = details.cargos.montoBase[index] ? details.cargos.montoBase[index].textContent : null
          if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(charge.montoBase) || /^[+-0.]{1,}$/.test(charge.montoBase)) throw new Error('3053')
          charge.montoBaseCurrencyId = details.cargos.montoBaseCurrencyId[index] ? details.cargos.montoBaseCurrencyId[index].textContent : null
          if (charge.montoBaseCurrencyId && charge.montoBaseCurrencyId !== this.tipoMoneda) throw new Error('2071')
          charge.monto = details.cargos.monto[index] ? details.cargos.monto[index].textContent : null
          if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(charge.monto) || !/^[+-0.]{1,}$/.test(charge.monto)) throw new Error('2955')
          if (charge.codTipo && (charge.factor && !(Number(charge.factor) > 0)) && !(Number(charge.monto) === (Number(charge.montoBase) * Number(charge.factor)) || (Number(charge.monto) <= (Number((Number(charge.montoBase) * Number(charge.factor)).toFixed(2)) + 1) && Number(charge.monto) >= (Number((Number(charge.montoBase) * Number(charge.factor)).toFixed(2)) - 1)))) charge.warning.push('4322')
          charge.montoCurrencyId = details.cargos.montoCurrencyId[index] ? details.cargos.montoCurrencyId[index].textContent : null
          if (charge.montoCurrencyId && charge.montoCurrencyId !== this.tipoMoneda) throw new Error('2071')

          details.cargosCodTipo[charge.codTipo] = charge

          if (details.cargosCodTipoCumulative[charge.codTipo]) {
            details.cargosCodTipoCumulative[charge.codTipo].monto += Number(charge.monto)
          } else {
            details.cargosCodTipoCumulative[charge.codTipo] = {}
            details.cargosCodTipoCumulative[charge.codTipo].monto = Number(charge.monto)
          }

          if (detailsCargosCodTipoCumulative[charge.codTipo]) {
            detailsCargosCodTipoCumulative[charge.codTipo].monto += Number(charge.monto)
          } else {
            detailsCargosCodTipoCumulative[charge.codTipo] = {}
            detailsCargosCodTipoCumulative[charge.codTipo].monto = Number(charge.monto)
          }

          saleDetail.cargos.push(charge)
          saleDetail.warning = saleDetail.warning.concat(charge.warning)
        }

        if (!details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9996'] && !(
          Number(saleDetail.mtoPrecioUnitario) === (Number(saleDetail.mtoValorVenta) + Number(saleDetail.totalTax.taxAmount) - Number(details.cargosCodTipoCumulative['01'] ? details.cargosCodTipoCumulative['01'].monto : 0) +
          Number(details.cargosCodTipoCumulative['48'] ? details.cargosCodTipoCumulative['48'].monto : 0)) / Number(saleDetail.cantidad) ||
          (
            Number(saleDetail.mtoPrecioUnitario) <= ((Number(saleDetail.mtoValorVenta) + Number(saleDetail.totalTax.taxAmount) - Number(details.cargosCodTipoCumulative['01'] ? details.cargosCodTipoCumulative['01'].monto : 0) +
             Number(details.cargosCodTipoCumulative['48'] ? details.cargosCodTipoCumulative['48'].monto : 0)) / Number(saleDetail.cantidad)) + 1 &&
            Number(saleDetail.mtoPrecioUnitario) >= ((Number(saleDetail.mtoValorVenta) + Number(saleDetail.totalTax.taxAmount) - Number(details.cargosCodTipoCumulative['01'] ? details.cargosCodTipoCumulative['01'].monto : 0) +
             Number(details.cargosCodTipoCumulative['48'] ? details.cargosCodTipoCumulative['48'].monto : 0)) / Number(saleDetail.cantidad)) - 1))
        ) this.warning.push('4287')

        if (details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9996'] && !(
          Number(saleDetail.mtoValorVenta) === Number(saleDetail.mtoPrecioUnitario) * Number(saleDetail.cantidad) - Number(details.cargosCodTipoCumulative['00'] ? details.cargosCodTipoCumulative['00'].monto : 0) +
          Number(details.cargosCodTipoCumulative['47'] ? details.cargosCodTipoCumulative['47'].monto : 0) ||
          (
            Number(saleDetail.mtoValorVenta) <= Number(saleDetail.mtoPrecioUnitario) * Number(saleDetail.cantidad) - Number(details.cargosCodTipoCumulative['00'] ? details.cargosCodTipoCumulative['00'].monto : 0) +
            Number(details.cargosCodTipoCumulative['47'] ? details.cargosCodTipoCumulative['47'].monto : 0) + 1 &&
            Number(saleDetail.mtoValorVenta) >= Number(saleDetail.mtoPrecioUnitario) * Number(saleDetail.cantidad) - Number(details.cargosCodTipoCumulative['00'] ? details.cargosCodTipoCumulative['00'].monto : 0) +
            Number(details.cargosCodTipoCumulative['47'] ? details.cargosCodTipoCumulative['47'].monto : 0) - 1
          ))) this.warning.push('4288') // check this again please
        if (!details.totalTax.taxDetailsCodeTaxableAmountAboveZero['9996'] && !(
          Number(saleDetail.mtoValorVenta) === Number(saleDetail.mtoValorUnitario) * Number(saleDetail.cantidad) - Number(details.cargosCodTipoCumulative['00'] ? details.cargosCodTipoCumulative['00'].monto : 0) +
          Number(details.cargosCodTipoCumulative['47'] ? details.cargosCodTipoCumulative['47'].monto : 0) ||
          (
            Number(saleDetail.mtoValorVenta) <= Number(saleDetail.mtoValorUnitario) * Number(saleDetail.cantidad) - Number(details.cargosCodTipoCumulative['00'] ? details.cargosCodTipoCumulative['00'].monto : 0) +
             Number(details.cargosCodTipoCumulative['47'] ? details.cargosCodTipoCumulative['47'].monto : 0) + 1 &&
            Number(saleDetail.mtoValorVenta) >= Number(saleDetail.mtoValorUnitario) * Number(saleDetail.cantidad) - Number(details.cargosCodTipoCumulative['00'] ? details.cargosCodTipoCumulative['00'].monto : 0) +
             Number(details.cargosCodTipoCumulative['47'] ? details.cargosCodTipoCumulative['47'].monto : 0) - 1
          ))) this.warning.push('4288') // check this again please

        if (this.tipoOperacion === '1004') { // CHECK THIS
          saleDetail.envio.partida.ubigueo = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.partida.ubigueo}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.partida.ubigueo}`).textContent : null
          if (this.tipoOperacion === '1004' && (!saleDetail.envio.partida.ubigueo || saleDetail.envio.partida.ubigueo === '')) throw new Error('3116')
          if (saleDetail.envio.partida.ubigueo && !catalogGeograficLocationCode[saleDetail.envio.partida.ubigueo]) saleDetail.envio.partida.warning.push('4200')
          saleDetail.envio.partida.ubigueoSchemeAgencyName = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.partida.ubigueoSchemeAgencyName}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.partida.ubigueoSchemeAgencyName}`).textContent : null
          saleDetail.envio.partida.ubigueoSchemeName = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.partida.ubigueoSchemeName}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.partida.ubigueoSchemeName}`).textContent : null
          saleDetail.envio.partida.direccion = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.partida.direccion}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.partida.direccion}`).textContent : null
          if (this.tipoOperacion === '1004' && (!saleDetail.envio.partida.direccion || saleDetail.envio.partida.direccion === '')) throw new Error('3117')
          if (!/[\w ]{3,200}/.test(saleDetail.envio.partida.direccion)) saleDetail.envio.partida.warning.push('4236')

          saleDetail.envio.llegada.ubigueo = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.llegada.ubigueo}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.llegada.ubigueo}`).textContent : null
          if (this.tipoOperacion === '1004' && (!saleDetail.envio.llegada.ubigueo || saleDetail.envio.llegada.ubigueo === '')) throw new Error('3118')
          if (saleDetail.envio.llegada.ubigueo && !catalogGeograficLocationCode[saleDetail.envio.llegada.ubigueo]) saleDetail.envio.llegada.warning.push('4200')
          saleDetail.envio.llegada.ubigueoSchemeAgencyName = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.llegada.ubigueoSchemeAgencyName}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.llegada.ubigueoSchemeAgencyName}`).textContent : null
          saleDetail.envio.llegada.ubigueoSchemeName = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.llegada.ubigueoSchemeName}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.llegada.ubigueoSchemeName}`).textContent : null
          saleDetail.envio.llegada.direccion = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.llegada.direccion}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.llegada.direccion}`).textContent : null
          if (this.tipoOperacion === '1004' && (!saleDetail.envio.llegada.direccion || saleDetail.envio.llegada.direccion === '')) throw new Error('3119')
          if (saleDetail.envio.llegada.direccion && !legendsCode['2005']) this.warning.push('4266')
          if (!/[\w ]{3,200}/.test(saleDetail.envio.llegada.direccion)) saleDetail.envio.llegada.warning.push('4236')

          saleDetail.envio.desTraslado = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.desTraslado}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.desTraslado}`).textContent : null
          if (this.tipoOperacion === '1004' && (!saleDetail.envio.desTraslado || saleDetail.envio.desTraslado === '')) throw new Error('3120')

          details.envio.terminosLength = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.terminos['.']}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.terminos['.']}`).length : 0
          details.envio.terminosType = {}
          details.envio.terminos = {
            type: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.terminos.type}`),
            value: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.terminos.value}`),
            valueCurrencyId: domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.envio.terminos.valueCurrencyId}`)
          }
          for (let index = 0; index < details.envio.terminosLength; index++) {
            var term = new Term()
            term.type = details.envio.terminos.type[index] ? details.envio.terminos.type[index].textContent : null
            term.value = details.envio.terminos.value[index] ? details.envio.terminos.value[index].textContent : null
            if (this.tipoOperacion === '1004' && !term.value) throw new Error('3122')
            if (this.tipoOperacion === '1004' && (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(term.value) || !(Number(term.value) > 0))) throw new Error('3123')
            term.valueCurrencyId = details.envio.terminos.valueCurrencyId[index] ? details.envio.terminos.valueCurrencyId[index].textContent : null
            if (term.valueCurrencyId !== 'PEN') throw new Error('3208')
            if (this.tipoOperacion === '1004' && term.type === '01' && details.envio.terminosType[term.type]) throw new Error('3124')
            if (this.tipoOperacion === '1004' && term.type === '02' && details.envio.terminosType[term.type]) throw new Error('3124')
            if (this.tipoOperacion === '1004' && term.type === '03' && details.envio.terminosType[term.type]) throw new Error('3124')

            details.envio.terminosType[term.type] = term
          }
          if (this.tipoOperacion === '1004' && !details.envio.terminosType['01']) throw new Error('3124')
          if (this.tipoOperacion === '1004' && !details.envio.terminosType['02']) throw new Error('3125')
          if (this.tipoOperacion === '1004' && !details.envio.terminosType['03']) throw new Error('3126')

          saleDetail.vehiculo.tramo.partida.ubigueo = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.partida.ubigueo}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.partida.ubigueo}`).textContent : null
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.tramo.partida.ubigueo && !catalogGeograficLocationCode[saleDetail.vehiculo.tramo.partida.ubigueo]) saleDetail.vehiculo.tramo.partida.warning.push('4200')
          saleDetail.vehiculo.tramo.partida.ubigueoSchemeAgencyName = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.partida.ubigueoSchemeAgencyName}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.partida.ubigueoSchemeAgencyName}`).textContent : null
          saleDetail.vehiculo.tramo.partida.ubigueoSchemeName = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.partida.ubigueoSchemeName}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.partida.ubigueoSchemeName}`).textContent : null
          saleDetail.vehiculo.tramo.partida.id = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.partida.id}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.partida.id}`).textContent : null
          saleDetail.vehiculo.tramo.llegada.ubigueo = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.llegada.ubigueo}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.llegada.ubigueo}`).textContent : null
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.tramo.llegada.ubigueo && !catalogGeograficLocationCode[saleDetail.vehiculo.tramo.llegada.ubigueo]) saleDetail.vehiculo.tramo.llegada.warning.push('4200')
          saleDetail.vehiculo.tramo.llegada.ubigueoSchemeAgencyName = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.llegada.ubigueoSchemeAgencyName}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.llegada.ubigueoSchemeAgencyName}`).textContent : null
          saleDetail.vehiculo.tramo.llegada.ubigueoSchemeName = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.llegada.ubigueoSchemeName}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.llegada.ubigueoSchemeName}`).textContent : null
          saleDetail.vehiculo.tramo.description = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.description}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.description}`).textContent : null
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.tramo.description && !/[\w ]{3, 100}/.test(saleDetail.vehiculo.tramo.description)) saleDetail.vehiculo.tramo.warning.push('4271')
          saleDetail.vehiculo.tramo.id = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.id}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.id}`).textContent : null
          saleDetail.vehiculo.tramo.value = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.value}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.value}`).textContent : null
          if (this.tipoOperacion === '1004' && (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(saleDetail.vehiculo.tramo.value) || !(Number(saleDetail.vehiculo.tramo.value) > 0))) saleDetail.vehiculo.tramo.warning.push('4272')
          saleDetail.vehiculo.tramo.valueCurrencyId = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.valueCurrencyId}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.tramo.valueCurrencyId}`).textContent : null
          if (saleDetail.vehiculo.tramo.valueCurrencyId !== 'PEN') throw new Error('3208')
          saleDetail.vehiculo.config = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.config}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.config}`).textContent : null
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.config && !/[\w ]{1,15}/.test(saleDetail.vehiculo.config)) saleDetail.vehiculo.warning.push('4273')
          saleDetail.vehiculo.configListAgencyName = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.configListAgencyName}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.configListAgencyName}`).textContent : null
          saleDetail.vehiculo.configListName = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.configListName}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.configListName}`).textContent : null
          saleDetail.vehiculo.usefulLoadType = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.usefulLoadType}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.usefulLoadType}`).textContent : null
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.usefulLoadType && !(saleDetail.vehiculo.usefulLoadType === '01' || saleDetail.vehiculo.usefulLoadType === '02')) saleDetail.vehiculo.warning.push('4274')
          saleDetail.vehiculo.usefulLoadTm = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.usefulLoadTm}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.usefulLoadTm}`).textContent : null
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.usefulLoadType && !saleDetail.vehiculo.usefulLoadTm) saleDetail.vehiculo.warning.push('4275')
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.usefulLoadType && (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(saleDetail.vehiculo.usefulLoadType) || !(Number(saleDetail.vehiculo.usefulLoadType) > 0))) saleDetail.vehiculo.warning.push('4276')
          saleDetail.vehiculo.usefulLoadTmUnitCode = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.usefulLoadTmUnitCode}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.usefulLoadTmUnitCode}`).textContent : null
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.usefulLoadTmUnitCode && saleDetail.vehiculo.usefulLoadTmUnitCode !== 'TNE') saleDetail.vehiculo.warning.push('4277')
          saleDetail.vehiculo.effectiveLoadType = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.effectiveLoadType}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.effectiveLoadType}`).textContent : null
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.effectiveLoadType && !(saleDetail.vehiculo.effectiveLoadType === '01' || saleDetail.vehiculo.effectiveLoadType === '02')) saleDetail.vehiculo.warning.push('4277')
          saleDetail.vehiculo.effectiveLoadTm = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.effectiveLoadTm}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.effectiveLoadTm}`).textContent : null
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.effectiveLoadType && !saleDetail.vehiculo.effectiveLoadTm) saleDetail.vehiculo.warning.push('4275')
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.effectiveLoadTm && (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(saleDetail.vehiculo.effectiveLoadTm) || !(Number(saleDetail.vehiculo.effectiveLoadTm) > 0))) saleDetail.vehiculo.warning.push('4276')
          saleDetail.vehiculo.effectiveLoadUnitCode = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.effectiveLoadUnitCode}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.effectiveLoadUnitCode}`).textContent : null
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.effectiveLoadUnitCode && saleDetail.vehiculo.effectiveLoadUnitCode !== 'TNE') saleDetail.vehiculo.warning.push('4277')
          saleDetail.vehiculo.refValue = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.refValue}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.refValue}`).textContent : null
          saleDetail.vehiculo.refValueCurrencyId = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.refValueCurrencyId}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.refValueCurrencyId}`).textContent : null
          saleDetail.vehiculo.nominalLoad = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.nominalLoad}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.nominalLoad}`).textContent : null
          if (this.tipoOperacion === '1004' && saleDetail.vehiculo.nominalLoad && (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(saleDetail.vehiculo.nominalLoad) || !(Number(saleDetail.vehiculo.nominalLoad) > 0))) saleDetail.vehiculo.warning.push('4278')
          saleDetail.vehiculo.nominalLoadCurrencyId = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.nominalLoadCurrencyId}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.nominalLoadCurrencyId}`).textContent : null
          saleDetail.vehiculo.returnFactor = domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.returnFactor}`) ? domDocumentHelper.select(`${path.details['.']}[${index + 1}]${path.details.vehiculo.returnFactor}`).textContent : null
        }

        if (listPadronContribuyente[this.company.ruc].ind_padron === 12 && !saleDetail.codProdSunat && !saleDetail.codProdGs1) saleDetail.warning.push('4331')
        if (detailsId[saleDetail.id]) throw new Error('2752')
        detailsId[saleDetail.id] = saleDetail
        detailsCodProducto[saleDetail.codProdSunat] = saleDetail.codProdSunat
        detailsMtoType[saleDetail.mtoType] = saleDetail
        this.details.push(saleDetail)
        this.warning = this.warning.concat(saleDetail.warning)
      }
      if (this.tipoOperacion === '0112' && !(detailsCodProducto['84121901'] || detailsCodProducto['80131501'])) throw new Error('3181')

      var totalTaxLength = domDocumentHelper.select(path.totalTax['.']) ? domDocumentHelper.select(path.totalTax['.']).length : 0
      if (!Number(totalTaxLength)) throw new Error('2956')
      if (Number(totalTaxLength) > 1) throw new Error('3024')
      this.totalTax.taxAmount = domDocumentHelper.select(path.totalTax.taxAmount)
      if (this.totalTax.taxAmount && (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(this.totalTax.taxAmount) || /^[+-0.]{1,}$/.test(this.totalTax.taxAmount))) throw new Error('3020')
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
        if ((this.tipoOperacion === '0200' || this.tipoOperacion === '0201' || this.tipoOperacion === '0202' || this.tipoOperacion === '0203' || this.tipoOperacion === '0204' || this.tipoOperacion === '0205' || this.tipoOperacion === '0206' || this.tipoOperacion === '0207' || this.tipoOperacion === '0208') && (taxDetailsCode === '1000' || taxDetailsCode === '1016')) taxDetail.warning.push('3107')
        if ((this.tipoOperacion === '0200' || this.tipoOperacion === '0201' || this.tipoOperacion === '0202' || this.tipoOperacion === '0203' || this.tipoOperacion === '0204' || this.tipoOperacion === '0205' || this.tipoOperacion === '0206' || this.tipoOperacion === '0207' || this.tipoOperacion === '0208') && (taxDetailsCode === '2000' || taxDetailsCode === '9999')) taxDetail.warning.push('3107')
        if (taxDetail.code !== '7152' && !taxDetails.taxableAmount[index]) throw new Error('3003')
        taxDetail.taxableAmount = taxDetails.taxableAmount[index] ? taxDetails.taxableAmount[index].textContent : null
        if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(taxDetail.taxableAmount)) throw new Error('2999')
        if (taxDetail.code === '2000' && Number(taxDetail.taxableAmount) > 0) throw new Error('2650')
        if (taxDetail.code === '9996' && (detailsMtoType['02'] && Number(detailsMtoType['02'].mtoPrecioUnitario) > 0) && Number(taxDetail.taxableAmount) === 0) taxDetail.warning.push('2641')
        if (taxDetail.code === '9996' && legendsCode['1002'] && Number(taxDetail.taxableAmount) === 0) taxDetail.warning.push('2416')
        if (taxDetail.code === '9997' && legendsCode['2001'] && Number(taxDetail.taxableAmount) === 0) taxDetail.warning.push('4022')
        if (taxDetail.code === '9997' && legendsCode['2002'] && Number(taxDetail.taxableAmount) === 0) taxDetail.warning.push('4023')
        if (taxDetail.code === '9997' && legendsCode['2003'] && Number(taxDetail.taxableAmount) === 0) taxDetail.warning.push('4024')
        if (taxDetail.code === '9997' && legendsCode['2008'] && Number(taxDetail.taxableAmount) === 0) taxDetail.warning.push('4244')
        taxDetail.taxableAmountCurrencyId = taxDetails.taxableAmountCurrencyId[index] ? taxDetails.taxableAmountCurrencyId[index].textContent : null
        if (taxDetail.taxableAmountCurrencyId && taxDetail.taxableAmountCurrencyId !== this.tipoMoneda) throw new Error('2071')
        taxDetail.taxAmount = taxDetails.taxAmount[index] ? taxDetails.taxAmount[index].textContent : null
        if (taxDetail.code === '7152' && moment(this.fechaEmision) < moment('2019-08-01') && Number(taxDetail.taxAmount) > 0) throw new Error('2949')
        if (taxDetail.taxAmount && !/^[+-0.]{1,}$/.test(taxDetail.taxAmount) &&
          (taxDetail.code === '9995' ||
            taxDetail.code === '9997' ||
            taxDetail.code === '9998')) throw new Error('3000')
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
        if (taxDetail.code === '9996' && Number(taxDetail.taxableAmount) > 0) {
          var objectKeysDetails = Object.keys(detailsId)
          for (let index = 0; index < objectKeysDetails.length; index++) {
            if (Number(detailsId[objectKeysDetails[index]].mtoValorUnitario) > 0) throw new Error('2640')
          }
        }

        this.totalTax.taxDetails.push(taxDetail)
        this.warning = this.warning.concat(taxDetail.warning)
      }

      if ((this.tipoOperacion === '0200' || this.tipoOperacion === '0201' || this.tipoOperacion === '0202' || this.tipoOperacion === '0203' || this.tipoOperacion === '0204' || this.tipoOperacion === '0205' || this.tipoOperacion === '0206' || this.tipoOperacion === '0207' || this.tipoOperacion === '0208') && (taxDetailsCode['9997'] || taxDetailsCode['9998'])) throw new Error('3107')

      var totalTaxDetailsSum = Number((Number(taxDetailsCode['1000'] ? taxDetailsCode['1000'] : 0) + Number(taxDetailsCode['1016'] ? taxDetailsCode['1016'] : 0) + Number(taxDetailsCode['2000'] ? taxDetailsCode['2000'] : 0) + Number(taxDetailsCode['7152'] ? taxDetailsCode['7152'] : 0) + Number(taxDetailsCode['9999'] ? taxDetailsCode['9999'] : 0)).toFixed(2))
      if (!(Number(totalTaxDetailsSum) === Number(Number(this.totalTax.taxAmount).toFixed(2)) || (Number(totalTaxDetailsSum) >= Number((Number(this.totalTax.taxAmount)).toFixed(2)) + 1 && Number(totalTaxDetailsSum) <= Number((Number(this.totalTax.taxAmount)).toFixed(2)) - 1))) this.totalTax.warning.push('4301')

      var cargosLength = domDocumentHelper.select(path.cargos['.']).length ? domDocumentHelper.select(path.cargos['.']).length : 0
      var cargosCodTipo = {}
      var cargosCodTipoCumulative = {}
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

        cargosCodTipo[charge.codTipo] = charge

        if (cargosCodTipoCumulative[charge.codTipo]) {
          cargosCodTipoCumulative[charge.codTipo].monto += Number(charge.monto)
        } else {
          cargosCodTipoCumulative[charge.codTipo] = {}
          cargosCodTipoCumulative[charge.codTipo].monto = Number(charge.monto)
        }

        this.cargos.push(charge)
        this.warning = this.warning.concat(charge.warning)
      }

      if (this.tipoOperacion === '2001' && !(cargosCodTipo['51'] || cargosCodTipo['52'] || cargosCodTipo['53'])) throw new Error('3093')
      if (taxDetail.code === '2000' && Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['2000'].taxAmount) > 0 && Number(taxDetail.taxAmount) === 0) taxDetail.warning.push('4020')
      if (taxDetail.code === '1000' && !(
        (
          Number(taxDetail.taxAmount) === (Number(detailsTotalTaxTaxDetailsCodeCumulative['1000'].taxableAmount) -
            Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) -
            Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) +
            Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0)) *
            (Number(parameterIgvTax[this.fechaEmision.replace(/-/g, '')]) / 100)
        ) ||
        (
          Number(taxDetail.taxAmount) >= ((Number(detailsTotalTaxTaxDetailsCodeCumulative['1000'].taxableAmount) -
            Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) -
            Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) +
            Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0)) *
            (Number(parameterIgvTax[this.fechaEmision.replace(/-/g, '')]) / 100)) - 1 &&
            Number(taxDetail.taxAmount) <= ((Number(detailsTotalTaxTaxDetailsCodeCumulative['1000'].taxableAmount) -
            Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) -
            Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) +
            Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0)) *
            (Number(parameterIgvTax[this.fechaEmision.replace(/-/g, '')]) / 100)) + 1
        )
      )) taxDetail.warning.push('4290')
      if (taxDetail.code === '9995' && !(Number(taxDetail.taxableAmount) === Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9995'].mtoValorVenta) || (taxDetail.taxableAmount >= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9995'].mtoValorVenta) - 1 && taxDetail.taxableAmount <= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9995'].mtoValorVenta) + 1))) throw new Error('4295')
      if (taxDetail.code === '9998' && !(Number(taxDetail.taxableAmount) === Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9998'].mtoValorVenta) - Number(cargosCodTipoCumulative['06'] ? cargosCodTipoCumulative['06'].monto : 0) || (Number(taxDetail.taxableAmount) >= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9998'].mtoValorVenta) - Number(cargosCodTipoCumulative['06'] ? cargosCodTipoCumulative['06'].monto : 0) - 1 && Number(taxDetail.taxableAmount) <= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9998'].mtoValorVenta) - Number(cargosCodTipoCumulative['06'] ? cargosCodTipoCumulative['06'].monto : 0) + 1))) throw new Error('4296')
      if (taxDetail.code === '9997' && !(Number(taxDetail.taxableAmount) === Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9997'].mtoValorVenta) - Number(cargosCodTipoCumulative['05'] ? cargosCodTipoCumulative['05'].monto : 0) || (Number(taxDetail.taxableAmount) >= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9997'].mtoValorVenta) - Number(cargosCodTipoCumulative['05'] ? cargosCodTipoCumulative['05'].monto : 0) - 1 && Number(taxDetail.taxableAmount) <= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9997'].mtoValorVenta) - Number(cargosCodTipoCumulative['05'] ? cargosCodTipoCumulative['05'].monto : 0) + 1))) throw new Error('4297')
      if (taxDetail.code === '9996' && !(Number(taxDetail.taxableAmount) === Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9996'].mtoValorVenta) || (Number(taxDetail.taxableAmount) >= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9996'].mtoValorVenta) - 1 && Number(taxDetail.taxableAmount) <= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9996'].mtoValorVenta) + 1))) taxDetail.warning.push('4298')
      if (taxDetail.code === '1000' && taxDetail.taxableAmount &&
          !(
            Number(taxDetail.taxableAmount) === Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1000'].mtoValorVenta) - Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) -
            Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0) ||
            (
              Number(taxDetail.taxableAmount) >= (Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1000'].mtoValorVenta) - Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) -
              Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0)) - 1 &&
              Number(taxDetail.taxableAmount) <= (Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1000'].mtoValorVenta) - Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) -
              Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0)) + 1
            )
          )
      ) taxDetail.warning.push('4299')

      if (taxDetail.code === '1016' && taxDetail.taxableAmount &&
          !(
            Number(taxDetail.taxableAmount) === Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1016'].mtoValorVenta) - Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) -
            Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0) ||
            (
              Number(taxDetail.taxableAmount) >= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1016'].mtoValorVenta) - Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) -
              Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0) - 1 &&
              Number(taxDetail.taxableAmount) <= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1016'].mtoValorVenta) - Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) -
              Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0) + 1
            )
          )) taxDetail.warning.push('4300')
      if (taxDetail.code === '1016' && !(
        Number(taxDetail.taxAmount) === (Number(detailsTotalTaxTaxDetailsCodeCumulative['1016'].taxableAmount) - Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) -
        Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0)) * (Number(parameterIvapTax[this.fechaEmision.replace(/-/g, '')]) / 100) ||
        (
          Number(taxDetail.taxAmount) >= ((Number(detailsTotalTaxTaxDetailsCodeCumulative['1016'].taxableAmount) - Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) - Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0)) * (Number(parameterIvapTax[this.fechaEmision.replace(/-/g, '')]) / 100)) - 1 &&
          Number(taxDetail.taxAmount) <= ((Number(detailsTotalTaxTaxDetailsCodeCumulative['1016'].taxableAmount) - Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) - Number(cargosCodTipoCumulative['04'] ? cargosCodTipoCumulative['04'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0)) * (Number(parameterIvapTax[this.fechaEmision.replace(/-/g, '')]) / 100)) + 1
        )
      )) taxDetail.warning.push('4302')
      if (taxDetail.code === '2000' && taxDetail.taxableAmount && !(Number(taxDetail.taxableAmount) === Number(detailsTotalTaxTaxDetailsCodeCumulative['2000'].taxableAmount) || (Number(taxDetail.taxableAmount) >= Number(detailsTotalTaxTaxDetailsCodeCumulative['2000'].taxableAmount) - 1 && Number(taxDetail.taxableAmount) <= Number(detailsTotalTaxTaxDetailsCodeCumulative['2000'].taxableAmount) + 1))) taxDetail.warning.push('4303')
      if (taxDetail.code === '9999' && taxDetail.taxableAmount && Number(taxDetail.taxableAmount) !== Number(detailsTotalTaxTaxDetailsCodeCumulative['9999'].taxableAmount)) taxDetail.warning.push('4304')
      if (taxDetail.code === '2000' && !(Number(taxDetail.taxAmount) === Number(detailsTotalTaxTaxDetailsCodeCumulative['2000'].taxAmount) || (Number(taxDetail.taxAmount) >= Number(detailsTotalTaxTaxDetailsCodeCumulative['2000'].taxAmount) - 1 && Number(taxDetail.taxAmount) <= Number(detailsTotalTaxTaxDetailsCodeCumulative['2000'].taxAmount) + 1))) taxDetail.warning.push('4305')
      if (taxDetail.code === '9999' && !(Number(taxDetail.taxAmount) === Number(detailsTotalTaxTaxDetailsCodeCumulative['9999'].taxAmount) || (Number(taxDetail.taxAmount) >= Number(detailsTotalTaxTaxDetailsCodeCumulative['9999'].taxAmount) - 1 && Number(taxDetail.taxAmount) <= Number(detailsTotalTaxTaxDetailsCodeCumulative['9999'].taxAmount) + 1))) taxDetail.warning.push('4306')

      if (this.mtoDescuentos && Number(this.mtoDescuentos) !== Number(detailsCargosCodTipoCumulative['01'] ? detailsCargosCodTipoCumulative['01'].monto : 0) + Number(cargosCodTipoCumulative['03'] ? cargosCodTipoCumulative['03'].monto : 0) || !(
        Number(this.mtoDescuentos) >= (Number(detailsCargosCodTipoCumulative['01'] ? detailsCargosCodTipoCumulative['01'].monto : 0) + Number(cargosCodTipoCumulative['03'] ? cargosCodTipoCumulative['03'].monto : 0)) - 1 &&
        Number(this.mtoDescuentos) <= (Number(detailsCargosCodTipoCumulative['01'] ? detailsCargosCodTipoCumulative['01'].monto : 0) + Number(cargosCodTipoCumulative['03'] ? cargosCodTipoCumulative['03'].monto : 0)) + 1
      )) this.warning.push('4307')
      if (this.sumOtrosCargos && Number(this.sumOtrosCargos) !== (Number(detailsCargosCodTipoCumulative['48'] ? detailsCargosCodTipoCumulative['48'].monto : 0) +
        Number(cargosCodTipoCumulative['45'] ? cargosCodTipoCumulative['45'].monto : 0) * Number(cargosCodTipoCumulative['46'] ? cargosCodTipoCumulative['46'].monto : 0) +
        Number(cargosCodTipoCumulative['50'] ? cargosCodTipoCumulative['50'].monto : 0)) || !(
        Number(this.sumOtrosCargos) >= (Number(detailsCargosCodTipoCumulative['48'] ? detailsCargosCodTipoCumulative['48'].monto : 0) +
        Number(cargosCodTipoCumulative['45'] ? cargosCodTipoCumulative['45'].monto : 0) * Number(cargosCodTipoCumulative['46'] ? cargosCodTipoCumulative['46'].monto : 0) +
        Number(cargosCodTipoCumulative['50'] ? cargosCodTipoCumulative['50'].monto : 0)) - 1 &&
          Number(this.sumOtrosCargos) <= (Number(detailsCargosCodTipoCumulative['48'] ? detailsCargosCodTipoCumulative['48'].monto : 0) +
        Number(cargosCodTipoCumulative['45'] ? cargosCodTipoCumulative['45'].monto : 0) * Number(cargosCodTipoCumulative['46'] ? cargosCodTipoCumulative['46'].monto : 0) +
        Number(cargosCodTipoCumulative['50'] ? cargosCodTipoCumulative['50'].monto : 0)) + 1
      )) this.warning.push('4308')
      if (Number(this.valorVenta) !== (
        Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1000'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1000'].mtoValorVenta : 0) +
        Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1016'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1016'].mtoValorVenta : 0) +
        Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9995'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9995'].mtoValorVenta : 0) +
        Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9997'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9997'].mtoValorVenta : 0) +
        Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9998'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9998'].mtoValorVenta : 0)) -
        Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0) ||
        (
          Number(this.valorVenta) >= ((
            Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1000'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1000'].mtoValorVenta : 0) +
          Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1016'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1016'].mtoValorVenta : 0) +
          Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9995'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9995'].mtoValorVenta : 0) +
          Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9997'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9997'].mtoValorVenta : 0) +
          Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9998'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9998'].mtoValorVenta : 0)) -
          Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0)) - 1 &&
          Number(this.valorVenta) >= ((
            Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1000'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1000'].mtoValorVenta : 0) +
          Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1016'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['1016'].mtoValorVenta : 0) +
          Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9995'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9995'].mtoValorVenta : 0) +
          Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9997'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9997'].mtoValorVenta : 0) +
          Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9998'] ? detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9998'].mtoValorVenta : 0)) -
          Number(cargosCodTipoCumulative['02'] ? cargosCodTipoCumulative['02'].monto : 0) + Number(cargosCodTipoCumulative['49'] ? cargosCodTipoCumulative['49'].monto : 0)) + 1
        )) this.warning.push('4309')
      if (this.precioVenta

      ) this.warning.push('4310') // PENDIENTE
      // "Si existe el Tag UBL, y no existe 'Total Importe IVAP' con monto mayor a cero, y el valor es diferente de la
      // sumatoria de 'Total valor de venta' más 'Sumatoria ISC' más 'Sumatoria Otros Tributos' más 'Sumatoria ICBPER' más el resultado de:
      // Multiplicar la sumatoria de los 'Monto base' de las líneas (cbc:TaxableAmount) con 'Código de tributo por línea' igual a '1000',
      // menos 'Monto de descuentos' globales que afectan la base (Código '02'), más los 'Montos de cargos' globales que afectan la base (Código '49') por la tasa vigente del IGV a la fecha de emisión, con una tolerancia + - 1"
      if (this.precioVenta) this.warning.push('4310') // PENDIENTE
      // "Si existe el Tag UBL, y existe 'Total Importe IVAP' con monto mayor a cero, y el valor es diferente de la sumatoria de 'Total valor de venta' más 'Sumatoria Otros Tributos' más 'Sumatoria ICBPER' más el resultado de:
      // Multiplicar la sumatoria de los 'Monto base' de las líneas (cbc:TaxableAmount) con 'Código de tributo por línea' igual a '1016',
      // menos 'Monto de descuentos' globales que afectan la base (Código '02'), más los 'Montos de cargos' globales que afectan la base (Código '49') por la tasa vigente del IVAP a la fecha de emisión, con una tolerancia + - 1"
      if (this.precioVenta) this.warning.push('4310') // PENDIENTE
      // Si existe el Tag UBL, y no existe 'Total Importe IGV' con monto mayor a cero,
      // y no existe 'Total Importe IVAP' con monto mayor a cero, y el valor es diferente de la sumatoria de 'Total valor de venta' más 'Sumatoria ISC' más 'Sumatoria Otros Tributos' más 'Sumatoria ICBPER'
      if (taxDetail.code === '9996' && (Number(taxDetail.taxAmount) !== Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9996'].taxAmount) || !(
        Number(taxDetail.taxAmount) >= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9996'].taxAmount) - 1 &&
        Number(taxDetail.taxAmount) <= Number(detailsTotalTaxTaxDetailsCodeAboveZeroCumulative['9996'].taxAmount) + 1
      ))) throw new Error('4311') // PENDIENTE
      // Si 'Código de tributo' es '9996', el valor del Tag UBL es diferente de la
      // sumatoria de 'Monto de IGV' (cbc:TaxAmount) que correspondan a ítems de operaciones gratuitas con 'Código de tributo por línea' igual a '9996'
      // y cuyo 'Monto base' es mayor a cero (cbc:TaxableAmount>0), con una tolerancia + - 1

      if (Number(this.mtoImpVenta) !== Number(this.precioVenta) + Number(this.sumOtrosCargos) - Number(this.mtoDescuentos) - Number(this.totalAnticipos) + Number(this.mtoRndImpVenta) || !(
        Number(this.mtoImpVenta) >= (Number(this.precioVenta) + Number(this.sumOtrosCargos) - Number(this.mtoDescuentos) - Number(this.totalAnticipos) + Number(this.mtoRndImpVenta)) - 1 &&
          Number(this.mtoImpVenta) <= (Number(this.precioVenta) + Number(this.sumOtrosCargos) - Number(this.mtoDescuentos) - Number(this.totalAnticipos) + Number(this.mtoRndImpVenta)) + 1
      )) this.warning.push('4312') // PENDIENTE
      // Si el valor del tag difiere de la sumatoria del 'Total precio de venta' más
      // 'Sumatoria otros cargos (que no afectan la base imponible del IGV)'
      // menos 'Sumatoria otros descuentos (que no afectan la base imponible del IGV)'
      // menos 'Total anticipos' de corresponder y
      // más 'Monto de redondeo del importe total', con una tolerancia +- 1.

      if (taxDetail.code === '7152' && Number(this.mtoImpVenta) !== Number(detailsTotalTaxTaxDetailsCodeCumulative['7152'].taxAmount)) taxDetail.warning.push('4321')
      this.perception.indicator = domDocumentHelper.select(path.perception.indicator)
      this.perception.mtoTotal = domDocumentHelper.select(path.perception.mtoTotal)
      this.perception.mtoTotalCurrencyID = domDocumentHelper.select(path.perception.mtoTotalCurrencyID)
      if (this.perception.mtoTotalCurrencyID && this.perception.indicator === 'Percepcion' && this.perception.mtoTotalCurrencyID !== 'PEN') throw new Error('2788')
      if ((this.tipoOperacion === '1001' || this.tipoOperacion === '1002' || this.tipoOperacion === '1003' || this.tipoOperacion === '1004') && this.perception.indicator !== 'Percepcion') throw new Error('3127')
      if (!(this.tipoOperacion === '1001' || this.tipoOperacion === '1002' || this.tipoOperacion === '1003' || this.tipoOperacion === '1004') && this.perception.indicator === 'Detraccion') throw new Error('3128')
      this.detraccion.codBienDetraccion = domDocumentHelper.select(path.detraccion.codBienDetraccion)
      if (this.perception.indicator === 'Detraccion' && (!this.detraccion.codBienDetraccion || this.detraccion.codBienDetraccion === '')) throw new Error('3127')
      if (this.perception.indicator === 'Detraccion' && this.detraccion.codBienDetraccion && !catalogServiceCodeSubjectDetraction[this.detraccion.codBienDetraccion]) throw new Error('3033')
      if (this.perception.indicator === 'Detraccion' && this.tipoOperacion === '1002' && this.detraccion.codBienDetraccion === '004') throw new Error('3129')
      if (this.perception.indicator === 'Detraccion' && this.tipoOperacion === '1003' && this.detraccion.codBienDetraccion === '028') throw new Error('3129')
      if (this.perception.indicator === 'Detraccion' && this.tipoOperacion === '1004' && this.detraccion.codBienDetraccion === '027') throw new Error('3129')
      this.detraccion.codBienDetraccionSchemeName = domDocumentHelper.select(path.detraccion.codBienDetraccionSchemeName)
      this.detraccion.codBienDetraccionSchemeAgencyName = domDocumentHelper.select(path.detraccion.codBienDetraccionSchemeAgencyName)
      this.detraccion.codBienDetraccionSchemeUri = domDocumentHelper.select(path.detraccion.codBienDetraccionSchemeUri)
      this.detraccion.indicator = domDocumentHelper.select(path.detraccion.indicator)
      if ((this.tipoOperacion === '1001' || this.tipoOperacion === '1002' || this.tipoOperacion === '1003' || this.tipoOperacion === '1004') && this.detraccion.indicator !== 'Detraccion') throw new Error('3034')
      this.detraccion.authorization = domDocumentHelper.select(path.detraccion.authorization)
      if (this.tipoOperacion === '0302' && !this.detraccion.authorization) throw new Error('3175')
      this.detraccion.ctaBanco = domDocumentHelper.select(path.detraccion.ctaBanco)
      if (this.detraccion.indicator === 'Detraccion' && (!this.detraccion.ctaBanco || this.detraccion.ctaBanco === '')) throw new Error('3034')
      this.detraccion.codMedioPago = domDocumentHelper.select(path.detraccion.codMedioPago)
      if (this.tipoOperacion === '0302' && !this.detraccion.codMedioPago) throw new Error('3173')
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
        prepayment.idSchemeName = anticipos.idSchemeName[index] ? anticipos.idSchemeName[index].textContent : null
        prepayment.idSchemeAgencyName = anticipos.idSchemeAgencyName[index] ? anticipos.idSchemeAgencyName[index].textContent : null
        prepayment.total = anticipos.total[index] ? anticipos.total[index].textContent : null
        if (prepayment.total && !prepayment.id) throw new Error('3211')
        if (prepayment.total && (Number(prepayment.total) < 0 && /^[+-0.]{1,}$/.test(prepayment.total))) throw new Error('2503')
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
      if (Number(anticiposSum) > 0 && !(Number(this.totalAnticipos) > 0)) throw new Error('3220')
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
      if ((this.envio.transportista.choferTipoDoc === '4' || this.envio.transportista.choferTipoDoc === '7') && /[\w]{1,12}/.test(this.envio.transportista.choferDoc)) this.envio.transportista.warning.push('4174')
      this.envio.transportista.choferDocSchemeName = domDocumentHelper.select(path.envio.transportista.choferDocSchemeName)
      this.envio.transportista.choferDocSchemeAgencyName = domDocumentHelper.select(path.envio.transportista.choferDocSchemeAgencyName)
      this.envio.transportista.choferDocSchemeURI = domDocumentHelper.select(path.envio.transportista.choferDocSchemeURI)
      this.envio.transportista.numDoc = domDocumentHelper.select(path.envio.transportista.numDoc)
      if (this.envio.id && this.envio.modTraslado === '01' && !this.envio.transportista.numDoc) this.envio.transportista.warning.push('4286')
      if (this.envio.id && this.envio.modTraslado === '02' && this.envio.transportista.numDoc) this.envio.transportista.warning.push('4159')
      if (this.envio.id && !this.envio.modTraslado && !this.envio.transportista.numDoc) this.envio.transportista.warning.push('4160')
      this.envio.transportista.tipoDoc = domDocumentHelper.select(path.envio.transportista.tipoDoc)
      if (this.envio.transportista.tipoDoc === '6' && !/^[0-9]{11}$/.test(this.envio.transportista.numDoc)) this.envio.transportista.warning.push('4163')
      if (this.envio.transportista.numDoc && !this.envio.transportista.tipoDoc) this.envio.transportista.warning.push('4161')
      this.envio.transportista.numDocSchemeName = domDocumentHelper.select(path.envio.transportista.numDocSchemeName)
      this.envio.transportista.numDocSchemeAgencyName = domDocumentHelper.select(path.envio.transportista.numDocSchemeAgencyName)
      this.envio.transportista.numDocSchemeUri = domDocumentHelper.select(path.envio.transportista.numDocSchemeUri)
      this.envio.transportista.rznSocial = domDocumentHelper.select(path.envio.transportista.rznSocial)
      if (this.envio.transportista.numDoc && !this.envio.transportista.rznSocial) this.envio.transportista.warning.push('4164')
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
        this.company.agent.warning,
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

  toJSON () {
    var json = {
      warning: this.warning,
      ublVersion: this.ublVersion,
      id: this.id,
      customization: this.customization,
      customizationSchemeAgencyName: this.customizationSchemeAgencyName,
      tipoDoc: this.tipoDoc,
      tipoDocListName: this.tipoDocListName,
      tipoDocListURI: this.tipoDocListURI,
      tipoOperacion: this.tipoOperacion,
      tipoOperacionName: this.tipoOperacionName,
      tipoOperacionListSchemeUri: this.tipoOperacionListSchemeUri,
      fecVencimiento: this.fecVencimiento,
      mtoOperGratuitas: this.mtoOperGratuitas,
      sumDsctoGlobal: this.sumDsctoGlobal,
      mtoDescuentos: this.mtoDescuentos,
      mtoDescuentosCurrencyId: this.mtoDescuentosCurrencyId,
      tipoDocListAgencyName: this.tipoDocListAgencyName,
      descuentos: this.descuentos,
      cargos: [],
      mtoCargos: this.mtoCargos,
      totalAnticipos: this.totalAnticipos,
      totalAnticiposCurrencyId: this.totalAnticiposCurrencyId,
      perception: this.perception.toJSON(),
      guiaEmbebida: this.guiaEmbebida,
      anticipos: [],
      detraccion: this.detraccion.toJSON(),
      seller: this.seller,
      valorVenta: this.valorVenta,
      valorVentaCurrencyId: this.valorVentaCurrencyId,
      precioVenta: this.precioVenta,
      precioVentaCurrencyId: this.precioVentaCurrencyId,
      mtoRndImpVenta: this.mtoRndImpVenta,
      mtoRndImpVentaCurrencyId: this.mtoRndImpVentaCurrencyId,
      envio: this.envio.toJSON(),
      serie: this.serie,
      correlativo: this.correlativo,
      fechaEmision: this.fechaEmision,
      horaEmision: this.horaEmision,
      tipoMoneda: this.tipoMoneda,
      tipoMonedaListID: this.tipoMonedaListID,
      tipoMonedaListName: this.tipoMonedaListName,
      tipoMonedaListAgencyName: this.tipoMonedaListAgencyName,
      fechaVencimiento: this.fechaVencimiento,
      signature: this.signature.toJSON(),
      company: this.company.toJSON(),
      client: this.client.toJSON(),
      totalTax: this.totalTax.toJSON(),
      sumOtrosCargos: this.sumOtrosCargos,
      sumOtrosCargosCurrencyId: this.sumOtrosCargosCurrencyId,
      mtoOperGravadas: this.mtoOperGravadas,
      mtoOperInafectas: this.mtoOperInafectas,
      mtoOperExoneradas: this.mtoOperExoneradas,
      mtoOperExportacion: this.mtoOperExportacion,
      mtoIGV: this.mtoIGV,
      mtoBaseIsc: this.mtoBaseIsc,
      mtoISC: this.mtoISC,
      mtoBaseOth: this.mtoBaseOth,
      mtoOtrosTributos: this.mtoOtrosTributos,
      totalImpuestos: this.totalImpuestos,
      mtoImpVenta: this.mtoImpVenta,
      mtoImpVentaCurrencyId: this.mtoImpVentaCurrencyId,
      details: [],
      legends: [],
      guias: [],
      relDocs: [],
      compra: this.compra
    }
    for (let index = 0; index < this.cargos.length; index++) json.cargos.push(this.cargos[index].toJSON())
    for (let index = 0; index < this.anticipos.length; index++) json.anticipos.push(this.anticipos[index].toJSON())
    for (let index = 0; index < this.details.length; index++) json.details.push(this.details[index].toJSON())
    for (let index = 0; index < this.legends.length; index++) json.legends.push(this.legends[index].toJSON())
    for (let index = 0; index < this.guias.length; index++) json.guias.push(this.guias[index].toJSON())
    for (let index = 0; index < this.relDocs.length; index++) json.relDocs.push(this.relDocs[index].toJSON())
    return json
  }
}

module.exports = Factura20Loader
