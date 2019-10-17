'use strict'

class Prepayment {
  constructor () {
    this._warning = []

    this._id = null
    this._idSchemeName = null
    this._idSchemeAgencyName = null
    this._tipoDocRel = null
    this._nroDocRel = null
    this._total = null
    this._totalCurrencyId = null
    this._payDate = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get id () {
    return this._id
  }

  set id (value) {
    this._id = value
  }

  get idSchemeName () {
    return this._idSchemeName
  }

  set idSchemeName (value) {
    if (value && value !== 'Anticipo') this.warning.push('4255')
    this._idSchemeName = value
  }

  get idSchemeAgencyName () {
    return this._idSchemeAgencyName
  }

  set idSchemeAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4256')
    this._idSchemeAgencyName = value
  }

  get tipoDocRel () {
    return this._tipoDocRel
  }

  set tipoDocRel (value) {
    this._tipoDocRel = value
  }

  get nroDocRel () {
    return this._nroDocRel
  }

  set nroDocRel (value) {
    this._nroDocRel = value
  }

  get total () {
    return this._total
  }

  set total (value) {
    this._total = value
  }

  get totalCurrencyId () {
    return this._totalCurrencyId
  }

  set totalCurrencyId (value) {
    this._totalCurrencyId = value
  }

  get payDate () {
    return this._payDate
  }

  set payDate (value) {
    this._payDate = value
  }
}

module.exports = Prepayment
