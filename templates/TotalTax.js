'use strict'

var TaxDetail = require('./TaxDetail')

class TotalTax {
  constructor () {
    this._warning = []

    this._taxAmount = null
    this._taxAmountCurrencyid = null
    this._taxDetails = [new TaxDetail()]
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get taxAmount () {
    return this._taxAmount
  }

  set taxAmount (value) {
    this._taxAmount = value
  }

  get taxAmountCurrencyid () {
    return this._taxAmountCurrencyid
  }

  set taxAmountCurrencyid (value) {
    this._taxAmountCurrencyid = value
  }

  get taxDetails () {
    return this._taxDetails
  }

  set taxDetails (value) {
    this._taxDetails = value
  }
}

module.exports = TotalTax
