'use strict'

class SalePerception {
  constructor () {
    this._warning = []

    this._indicator = null
    this._codReg = null
    this._porcentaje = null
    this._mtoBase = null
    this._mto = null
    this._mtoTotal = null
    this._mtoTotalCurrencyID = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get indicator () {
    return this._indicator
  }

  set indicator (value) {
    this._indicator = value
  }

  get codReg () {
    return this._codReg
  }

  set codReg (value) {
    this._codReg = value
  }

  get porcentaje () {
    return this._porcentaje
  }

  set porcentaje (value) {
    this._porcentaje = value
  }

  get mtoBase () {
    return this._mtoBase
  }

  set mtoBase (value) {
    this._mtoBase = value
  }

  get mto () {
    return this._mto
  }

  set mto (value) {
    this._mto = value
  }

  get mtoTotal () {
    return this._mtoTotal
  }

  set mtoTotal (value) {
    this._mtoTotal = value
  }

  get mtoTotalCurrencyID () {
    return this._mtoTotalCurrencyID
  }

  set mtoTotalCurrencyID (value) {
    this._mtoTotalCurrencyID = value
  }
}

module.exports = SalePerception
