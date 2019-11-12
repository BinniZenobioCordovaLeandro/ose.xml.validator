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

var path = require('./ocpp/Boleta20.json')

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
var catalogCountryCode = require('../catalogs/catalogCountryCode.json')
var catalogIdentityDocumentTypeCode = require('../catalogs/catalogIdentityDocumentTypeCode.json')
var catalogServiceCodeSubjectDetraction = require('../catalogs/catalogServiceCodeSubjectDetraction.json')
var catalogLoanType = require('../catalogs/catalogLoanType.json')
var catalogIndicatorFirstHome = require('../catalogs/catalogIndicatorFirstHome.json')

class Boleta20Loader extends Invoice {
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
      ) throw new Error('1079')
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

      resolve(domDocumentHelper, xml)
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

module.exports = Boleta20Loader
