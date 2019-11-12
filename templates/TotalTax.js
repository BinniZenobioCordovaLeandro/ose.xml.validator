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

  toJSON () {
    var json = {
      warning: this.warning,
      taxAmount: this.taxAmount,
      taxAmountCurrencyid: this.taxAmountCurrencyid,
      taxDetails: []
    }
    for (let index = 0; index < this.taxDetails.length; index++) {
      json.taxDetails.push(this.taxDetails[index].toJSON())
    }
    return json
  }
}

module.exports = TotalTax
