'use strict'

var catalogTaxTypeCode = require('../catalogs/catalogTaxTypeCode.json')

class TaxDetail {
  constructor () {
    this._warning = []

    this._taxableAmount = null
    this._taxableAmountCurrencyId = null
    this._taxAmount = null
    this._taxAmountCurrencyId = null
    this._code = null
    this._codeSchemeName = null
    this._codeSchemeAgencyName = null
    this._codeSchemeUri = null
    this._name = null
    this._typeCode = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get taxableAmount () {
    return this._taxableAmount
  }

  set taxableAmount (value) {
    if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(value)) throw new Error('2999')
    this._taxableAmount = value
  }

  get taxableAmountCurrencyId () {
    return this._taxableAmountCurrencyId
  }

  set taxableAmountCurrencyId (value) {
    this._taxableAmountCurrencyId = value
  }

  get taxAmount () {
    return this._taxAmount
  }

  set taxAmount (value) {
    if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(value)) throw new Error('2048')
    this._taxAmount = value
  }

  get taxAmountCurrencyId () {
    return this._taxAmountCurrencyId
  }

  set taxAmountCurrencyId (value) {
    this._taxAmountCurrencyId = value
  }

  get code () {
    return this._code
  }

  set code (value) {
    if (!value) throw new Error('3059')
    if (!catalogTaxTypeCode[value]) throw new Error('3007')
    this._code = value
  }

  get codeSchemeName () {
    return this._codeSchemeName
  }

  set codeSchemeName (value) {
    if (value && value !== 'Codigo de tributos') this.warning.push('4255')
    this._codeSchemeName = value
  }

  get codeSchemeAgencyName () {
    return this._codeSchemeAgencyName
  }

  set codeSchemeAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4256')
    this._codeSchemeAgencyName = value
  }

  get codeSchemeUri () {
    return this._codeSchemeUri
  }

  set codeSchemeUri (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05') this.warning.push('4257')
    this._codeSchemeUri = value
  }

  get name () {
    return this._name
  }

  set name (value) {
    if (!value) throw new Error('2054')
    if (catalogTaxTypeCode[this.code].name !== value) throw new Error('2964')
    this._name = value
  }

  get typeCode () {
    return this._typeCode
  }

  set typeCode (value) {
    if (!value) throw new Error('2052')
    if (catalogTaxTypeCode[this.code].international !== value) throw new Error('2961')
    this._typeCode = value
  }
}

module.exports = TaxDetail
