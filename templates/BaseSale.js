'use strict'

var moment = require('moment')

const catalogCoinTypeCode = require('../catalogs/catalogCoinTypeCode.json')

var Company = require('./Company')
var Client = require('./Client')
var Document = require('./Document')
var SaleDetail = require('./SaleDetail')
var Signature = require('./Signature')
var TotalTax = require('./TotalTax')

class BaseSale {
  constructor () {
    this._warning = []

    this._ublVersion = null
    this._id = null

    this._customization = null
    this._customizationSchemeAgencyName = null

    this._tipoDoc = null
    this._tipoOperacion = null
    this._tipoDocListAgencyName = null
    this._tipoDocListName = null
    this._tipoDocListURI = null

    this._serie = null
    this._correlativo = null

    this._fechaEmision = null
    this._horaEmision = null

    this._tipoMoneda = null
    this._tipoMonedaListID = null
    this._tipoMonedaListName = null
    this._tipoMonedaListAgencyName = null

    this._fechaVencimiento = null

    this._signature = new Signature()

    this._company = new Company()
    this._client = new Client()
    this._totalTax = new TotalTax()

    this._sumOtrosCargos = null
    this._mtoOperGravadas = null
    this._mtoOperInafectas = null
    this._mtoOperExoneradas = null
    this._mtoOperExportacion = null
    this._mtoIGV = null
    this._mtoBaseIsc = null
    this._mtoISC = null
    this._mtoBaseOth = null
    this._mtoOtrosTributos = null
    this._totalImpuestos = null
    this._mtoImpVenta = null

    this._details = [new SaleDetail()]

    this._legends = null

    this._guias = [new Document()]
    this._relDocs = [new Document()]

    this._compra = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get ublVersion () {
    return this._ublVersion
  }

  set ublVersion (value) {
    if (!value) throw new Error('2075')
    if (!/^([1-9.]){3}$/.test(value)) throw new Error('2074')
    this._ublVersion = value
  }

  get customization () {
    return this._customization
  }

  set customization (value) {
    if (!value) throw new Error('2073')
    if (!/^([0-9.]){3}$/.test(value)) throw new Error('2072')
    this._customization = value
  }

  get customizationSchemeAgencyName () {
    return this._customizationSchemeAgencyName
  }

  set customizationSchemeAgencyName (value) {
    if (value) {
      if (!/^PE:SUNAT$/.test(value)) this.warning.push('4256')
      this._customizationSchemeAgencyName = value
    }
  }

  get id () {
    return this._id
  }

  set id (value) {
    if (!(/^[F][A-Z0-9]{3}-[0-9]{1,8}$/.test(value) || /^[0-9]{1,4}-[0-9]{1,8}$/.test(value))) throw new Error('1001')
    this._id = value
  }

  get tipoDoc () {
    return this._tipoDoc
  }

  set tipoDoc (value) {
    if (!value) throw new Error('1004')
    this._tipoDoc = value
  }

  get tipoOperacion () {
    return this._tipoOperacion
  }

  set tipoOperacion (value) {
    this._tipoOperacion = value
  }

  get tipoDocListAgencyName () {
    return this._tipoDocListAgencyName
  }

  set tipoDocListAgencyName (value) {
    if (value) {
      if (!/^PE:SUNAT$/.test(value)) this.warning.push('4251')
      this._tipoDocListAgencyName = value
    }
  }

  get tipoDocListName () {
    return this._tipoDocListName
  }

  set tipoDocListName (value) {
    if (value) {
      if (value !== 'Tipo de Documento') this.warning.push('4252')
      this._tipoDocListName = value
    }
  }

  get tipoDocListURI () {
    return this._tipoDocListURI
  }

  set tipoDocListURI (value) {
    if (value) {
      if (value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01') this.warning.push('4253')
      this._tipoDocListURI = value
    }
  }

  get serie () {
    return this._serie
  }

  set serie (value) {
    this._serie = value
  }

  get correlativo () {
    return this._correlativo
  }

  set correlativo (value) {
    this._correlativo = value
  }

  get fechaEmision () {
    return this._fechaEmision
  }

  set fechaEmision (value) {
    if (moment().diff(moment(value), 'days') > 2) throw new Error('2329')
    this._fechaEmision = value
  }

  get horaEmision () {
    return this._horaEmision
  }

  set horaEmision (value) {
    this._horaEmision = value
  }

  get tipoMoneda () {
    return this._tipoMoneda
  }

  set tipoMoneda (value) {
    if (!value) throw new Error('2070')
    if (!catalogCoinTypeCode[value]) throw new Error('3088')
    this._tipoMoneda = value
  }

  get tipoMonedaListID () {
    return this._tipoMonedaListID
  }

  set tipoMonedaListID (value) {
    if (value) {
      if (value !== 'ISO 4217 Alpha') this.warning.push('4254')
      this._tipoMonedaListID = value
    }
  }

  get tipoMonedaListName () {
    return this._tipoMonedaListName
  }

  set tipoMonedaListName (value) {
    if (value) {
      if (value !== 'Currency') this.warning.push('4252')
      this._tipoMonedaListName = value
    }
  }

  get tipoMonedaListAgencyName () {
    return this._tipoMonedaListAgencyName
  }

  set tipoMonedaListAgencyName (value) {
    if (value) {
      if (value !== 'United Nations Economic Commission for Europe') this.warning.push('4251')
      this._tipoMonedaListAgencyName = value
    }
  }

  get fechaVencimiento () {
    return this._fechaVencimiento
  }

  set fechaVencimiento (value) {
    this._fechaVencimiento = value
  }

  get signature () {
    return this._signature
  }

  set signature (value) {
    this._signature = value
  }

  get company () {
    return this._company
  }

  set company (value) {
    this._company = value
  }

  get client () {
    return this._client
  }

  set client (value) {
    this._client = value
  }

  get totalTax () {
    return this._totalTax
  }

  set totalTax (value) {
    this._totalTax = value
  }

  get mtoBaseIsc () {
    return this._mtoBaseIsc
  }

  set mtoBaseIsc (value) {
    if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(value) && !/^[+-][0.]{1,}$/.test(value)) throw new Error('2999')
    this._mtoBaseIsc = value
  }

  get mtoOtrosTributos () {
    return this._mtoOtrosTributos
  }

  set mtoOtrosTributos (value) {
    this._mtoOtrosTributos = value
  }

  get totalImpuestos () {
    return this._totalImpuestos
  }

  set totalImpuestos (value) {
    if (value && !/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(value) && !/^[+-][0.]{1,}$/.test(value)) throw new Error('3020')
    this._totalImpuestos = value
  }

  get details () {
    return this._details
  }

  set details (value) {
    this._details = value
  }

  get guias () {
    return this._guias
  }

  set guias (value) {
    this._guias = value
  }

  get relDocs () {
    return this._relDocs
  }

  set relDocs (value) {
    this._relDocs = value
  }
}

module.exports = BaseSale
