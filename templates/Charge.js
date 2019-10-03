'use strict'

var catalogChargeCode = require('../catalogs/catalogChargeCode.json')

class Charge {
  constructor (params) {
    this._warning = []

    this._indicator = null
    this._codTipo = null
    this._codTipoListAgencyName = null
    this._codTipoListName = null
    this._codTipoListUri = null
    this._factor = null
    this._monto = null
    this._montoCurrencyId = null
    this._montoBase = null
    this._montoBaseCurrencyId = null
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
    if (
      (
        this.codTipo === '45' ||
        this.codTipo === '46' ||
        this.codTipo === '49' ||
        this.codTipo === '50' ||
        this.codTipo === '51' ||
        this.codTipo === '52' ||
        this.codTipo === '53'
      ) && String(value) !== 'true'
    ) throw new Error('3114')
    if (
      (
        this.codTipo === '02' ||
        this.codTipo === '03' ||
        this.codTipo === '04' ||
        this.codTipo === '05' ||
        this.codTipo === '06'
      ) && String(value) !== 'false'
    ) throw new Error('3114')
    this._indicator = value
  }

  get codTipo () {
    return this._codTipo
  }

  set codTipo (value) {
    if (
      value === '00' ||
      value === '01' ||
      value === '47' ||
      value === '48'
    ) this.warning.push('4291')
    if (!catalogChargeCode[value]) throw new Error('3071')
    this._codTipo = value
  }

  get codTipoListAgencyName () {
    return this._codTipoListAgencyName
  }

  set codTipoListAgencyName (value) {
    if (value !== 'PE:SUNAT') this.warning.push('4251')
    this._codTipoListAgencyName = value
  }

  get codTipoListName () {
    return this._codTipoListName
  }

  set codTipoListName (value) {
    if (value !== 'Cargo/descuento') this.warning.push('4252')
    this._codTipoListName = value
  }

  get codTipoListUri () {
    return this._codTipoListUri
  }

  set codTipoListUri (value) {
    if (value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo53') this.warning.push('4253')
    this._codTipoListUri = value
  }

  get factor () {
    return this._factor
  }

  set factor (value) {
    if (value &&
      (!/^[+]?[0-9]{1,3}\.[0-9]{1,5}$/.test(value) || /^[+-0.]{1,}$/.test(value))
    ) throw new Error('3025')
    this._factor = value
  }

  get monto () {
    return this._monto
  }

  set monto (value) {
    if (
      !/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(value) || /^[+-0.]{1,}$/.test(value)
    ) throw new Error('2968')
    if (this.codTipo &&
      (this.factor && !(Number(this.factor) > 0)) &&
      !(
        Number(value) === (Number(this.montoBase) * Number(this.factor)) ||
        Number(value) === ((Number(this.montoBase) * Number(this.factor)) + 1) ||
        Number(value) === ((Number(this.montoBase) * Number(this.factor)) - 1)
      )
    ) this.warning.push('4322')
    this._monto = value
  }

  get montoCurrencyId () {
    return this._montoCurrencyId
  }

  set montoCurrencyId (value) {
    this._montoCurrencyId = value
  }

  get montoBase () {
    return this._montoBase
  }

  set montoBase (value) {
    if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(value) ||
    /^[+-0.]{1,}$/.test(value)) throw new Error('3016')
    this._montoBase = value
  }

  get montoBaseCurrencyId () {
    return this._montoBaseCurrencyId
  }

  set montoBaseCurrencyId (value) {
    this._montoBaseCurrencyId = value
  }
}

module.exports = Charge
