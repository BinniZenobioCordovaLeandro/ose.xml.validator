'use strict'

var catalogLegendCode = require('../catalogs/catalogLegendCode.json')

class Legend {
  constructor () {
    this._code = null
    this._value = null
  }

  get code () {
    return this._code
  }

  set code (value) {
    if (value && !catalogLegendCode[value]) throw new Error('3027')
    this._code = value
  }

  get value () {
    return this._value
  }

  set value (value) {
    if (!/^[\w $-/:-?{-~!"^_`[\]]{1,200}$/.test(value)) throw new Error('3006')
    this._value = value
  }

  toJSON () {
    return {
      code: this.code,
      value: this.value
    }
  }
}

module.exports = Legend
