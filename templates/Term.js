'use strict'

class Term {
  constructor () {
    this._warning = []
    this._type = null
    this._value = null
    this._valueCurrencyId = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get type () {
    return this._type
  }

  set type (value) {
    this._type = value
  }

  get value () {
    return this._value
  }

  set value (value) {
    this._value = value
  }

  get valueCurrencyId () {
    return this._valueCurrencyId
  }

  set valueCurrencyId (value) {
    this._valueCurrencyId = value
  }

  toJSON () {
    return {
      warning: this.warning,
      type: this.type,
      value: this.value,
      valueCurrencyId: this.valueCurrencyId
    }
  }
}

module.exports = Term
