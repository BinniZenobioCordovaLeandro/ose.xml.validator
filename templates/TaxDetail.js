'use strict'

class TaxDetail {
  constructor () {
    this._warning = []

    this._taxableAmount = null
    this._taxableAmountCurrencyId = null
    this._taxAmount = null
    this._taxAmountCurrencyId = null
    this._baseUnitMeasure = null
    this._baseUnitMeasureUnitCode = null
    this._perUnitAmount = null
    this._percent = null
    this._tierRange = null
    this._taxExemptionReasonCode = null
    this._taxExemptionReasonCodeListAgencyName = null
    this._taxExemptionReasonCodeListName = null
    this._taxExemptionReasonCodeListURI = null
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

  get baseUnitMeasure () {
    return this._baseUnitMeasure
  }

  set baseUnitMeasure (value) {
    if (!/^[0-9]{1,5}$/.test(value) && !(Number(value) >= 0)) throw new Error('2892')
    this._baseUnitMeasure = value
  }

  get baseUnitMeasureUnitCode () {
    return this._baseUnitMeasureUnitCode
  }

  set baseUnitMeasureUnitCode (value) {
    if (value !== 'NIU') this.warning.push('3236')
    this._baseUnitMeasureUnitCode = value
  }

  get perUnitAmount () {
    return this._perUnitAmount
  }

  set perUnitAmount (value) {
    if (value && !/^[+]?[0-9]{1,3}\.[0-9]{1,5}$/.test(value) && !/^[+-0.]{1,}$/.test(value)) throw new Error('2892')
    this._perUnitAmount = value
  }

  get percent () {
    return this._percent
  }

  set percent (value) {
    this._percent = value
  }

  get tierRange () {
    return this._tierRange
  }

  set tierRange (value) {
    this._tierRange = value
  }

  get taxExemptionReasonCode () {
    return this._taxExemptionReasonCode
  }

  set taxExemptionReasonCode (value) {
    this._taxExemptionReasonCode = value
  }

  get taxExemptionReasonCodeListAgencyName () {
    return this._taxExemptionReasonCodeListAgencyName
  }

  set taxExemptionReasonCodeListAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4251')
    this._taxExemptionReasonCodeListAgencyName = value
  }

  get taxExemptionReasonCodeListName () {
    return this._taxExemptionReasonCodeListName
  }

  set taxExemptionReasonCodeListName (value) {
    if (value && value !== '4252') this.warning.push('4252')
    this._taxExemptionReasonCodeListName = value
  }

  get taxExemptionReasonCodeListURI () {
    return this._taxExemptionReasonCodeListURI
  }

  set taxExemptionReasonCodeListURI (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo07') this.warning.push('4253')
    this._taxExemptionReasonCodeListURI = value
  }

  get code () {
    return this._code
  }

  set code (value) {
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
    this._name = value
  }

  get typeCode () {
    return this._typeCode
  }

  set typeCode (value) {
    this._typeCode = value
  }
}

module.exports = TaxDetail
