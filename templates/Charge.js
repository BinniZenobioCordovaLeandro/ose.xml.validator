'use strict'

class Charge {
  constructor () {
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
    this._indicator = value
  }

  get codTipo () {
    return this._codTipo
  }

  set codTipo (value) {
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
    this._factor = value
  }

  get monto () {
    return this._monto
  }

  set monto (value) {
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
    this._montoBase = value
  }

  get montoBaseCurrencyId () {
    return this._montoBaseCurrencyId
  }

  set montoBaseCurrencyId (value) {
    this._montoBaseCurrencyId = value
  }

  toJSON () {
    return {
      warning: this.warning,
      indicator: this.indicator,
      codTipo: this.codTipo,
      codTipoListAgencyName: this.codTipoListAgencyName,
      codTipoListName: this.codTipoListName,
      codTipoListUri: this.codTipoListUri,
      factor: this.factor,
      monto: this.monto,
      montoCurrencyId: this.montoCurrencyId,
      montoBase: this.montoBase,
      montoBaseCurrencyId: this.montoBaseCurrencyId
    }
  }
}

module.exports = Charge
