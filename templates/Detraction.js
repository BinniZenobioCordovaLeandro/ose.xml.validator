'use strict'

var catalogPayMethod = require('../catalogs/catalogPayMethod.json')

class Detraction {
  constructor () {
    this._warning = []

    this._indicator = null
    this._percent = null
    this._mount = null
    this._mountCurrencyId = null
    this._ctaBanco = null
    this._codMedioPago = null
    this._codMedioPagoListName = null
    this._codMedioPagoListAgencyName = null
    this._codMedioPagoListUri = null
    this._codBienDetraccion = null
    this._codBienDetraccionSchemeName = null
    this._codBienDetraccionSchemeAgencyName = null
    this._codBienDetraccionSchemeUri = null
    this._valueRef = null
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

  get percent () {
    return this._percent
  }

  set percent (value) {
    this._percent = value
  }

  get mount () {
    return this._mount
  }

  get mountCurrencyId () {
    return this._mountCurrencyId
  }

  set mountCurrencyId (value) {
    this._mountCurrencyId = value
  }

  set mount (value) {
    if (value && (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(value) || !(Number(value) > 0))) throw new Error('3037')
    this._mount = value
  }

  get ctaBanco () {
    return this._ctaBanco
  }

  set ctaBanco (value) {
    this._ctaBanco = value
  }

  get codMedioPago () {
    return this._codMedioPago
  }

  set codMedioPago (value) {
    if (value && !catalogPayMethod[value]) throw new Error('3174')
    this._codMedioPago = value
  }

  get codMedioPagoListName () {
    return this._codMedioPagoListName
  }

  set codMedioPagoListName (value) {
    if (value && value !== 'Medio de pago') this.warning.push('4252')
    this._codMedioPagoListName = value
  }

  get codMedioPagoListAgencyName () {
    return this._codMedioPagoListAgencyName
  }

  set codMedioPagoListAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4251')
    this._codMedioPagoListAgencyName = value
  }

  get codMedioPagoListUri () {
    return this._codMedioPagoListUri
  }

  set codMedioPagoListUri (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo59') this.warning.push('4253')
    this._codMedioPagoListUri = value
  }

  get codBienDetraccion () {
    return this._codBienDetraccion
  }

  set codBienDetraccion (value) {
    this._codBienDetraccion = value
  }

  get codBienDetraccionSchemeName () {
    return this._codBienDetraccionSchemeName
  }

  set codBienDetraccionSchemeName (value) {
    if (value && value !== 'Codigo de detraccion') this.warning.push('4255')
    this._codBienDetraccionSchemeName = value
  }

  get codBienDetraccionSchemeAgencyName () {
    return this._codBienDetraccionSchemeAgencyName
  }

  set codBienDetraccionSchemeAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4256')
    this._codBienDetraccionSchemeAgencyName = value
  }

  get codBienDetraccionSchemeUri () {
    return this._codBienDetraccionSchemeUri
  }

  set codBienDetraccionSchemeUri (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo54') this.warning.push('4257')
    this._codBienDetraccionSchemeUri = value
  }

  get valueRef () {
    return this._valueRef
  }

  set valueRef (value) {
    this._valueRef = value
  }
}

module.exports = Detraction
