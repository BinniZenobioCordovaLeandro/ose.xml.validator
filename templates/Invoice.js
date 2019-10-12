'use strict'

var BaseSale = require('./BaseSale')
var Charge = require('./Charge')
var Detraction = require('./Detraction')

class Invoice extends BaseSale {
  constructor () {
    super()
    this._tipoOperacion = null
    this._fecVencimiento = null
    this._mtoOperGratuitas = null
    this._sumDsctoGlobal = null
    this._mtoDescuentos = null
    this._mtoDescuentosCurrencyId = null
    this._descuentos = null
    this._cargos = [new Charge()]
    this._mtoCargos = null
    this._totalAnticipos = null
    this._perception = null
    this._guiaEmbebida = null
    this._anticipos = null
    this._detraccion = new Detraction()
    this._seller = null
    this._valorVenta = null
    this._valorVentaCurrencyId = null
    this._precioVenta = null
    this._precioVentaCurrencyId = null
    this._mtoRndImpVenta = null
    this._mtoRndImpVentaCurrencyId = null
  }

  get tipoOperacion () {
    return this._tipoOperacion
  }

  set tipoOperacion (value) {
    this._tipoOperacion = value
  }

  get fecVencimiento () {
    return this._fecVencimiento
  }

  set fecVencimiento (value) {
    this._fecVencimiento = value
  }

  get mtoOperGratuitas () {
    return this._mtoOperGratuitas
  }

  set mtoOperGratuitas (value) {
    this._mtoOperGratuitas = value
  }

  get sumDsctoGlobal () {
    return this._sumDsctoGlobal
  }

  set sumDsctoGlobal (value) {
    this._sumDsctoGlobal = value
  }

  get mtoDescuentos () {
    return this._mtoDescuentos
  }

  set mtoDescuentos (value) {
    if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(value) ||
      !/^[+-0.]{1,}$/.test(value)) throw new Error('2065')
    this._mtoDescuentos = value
  }

  get mtoDescuentosCurrencyId () {
    return this._mtoDescuentosCurrencyId
  }

  set mtoDescuentosCurrencyId (value) {
    this._mtoDescuentosCurrencyId = value
  }

  get descuentos () {
    return this._descuentos
  }

  set descuentos (value) {
    this._descuentos = value
  }

  get cargos () {
    return this._cargos
  }

  set cargos (value) {
    this._cargos = value
  }

  get mtoCargos () {
    return this._mtoCargos
  }

  set mtoCargos (value) {
    this._mtoCargos = value
  }

  get totalAnticipos () {
    return this._totalAnticipos
  }

  set totalAnticipos (value) {
    this._totalAnticipos = value
  }

  get perception () {
    return this._perception
  }

  set perception (value) {
    this._perception = value
  }

  get guiaEmbebida () {
    return this._guiaEmbebida
  }

  set guiaEmbebida (value) {
    this._guiaEmbebida = value
  }

  get anticipos () {
    return this._anticipos
  }

  set anticipos (value) {
    this._anticipos = value
  }

  get detraccion () {
    return this._detraccion
  }

  set detraccion (value) {
    this._detraccion = value
  }

  get seller () {
    return this._seller
  }

  set seller (value) {
    this._seller = value
  }

  get valorVenta () {
    return this._valorVenta
  }

  set valorVenta (value) {
    if (value &&
      !/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(value) &&
      !/^[+-0.]{1,}$/.test(value)) throw new Error('2062')
    this._valorVenta = value
  }

  get valorVentaCurrencyId () {
    return this._valorVentaCurrencyId
  }

  set valorVentaCurrencyId (value) {
    this._valorVentaCurrencyId = value
  }

  get precioVenta () {
    return this._precioVenta
  }

  set precioVenta (value) {
    if (value &&
      !/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(value) &&
      !/^[+-0.]{1,}$/.test(value)) throw new Error('3019')
    this._precioVenta = value
  }

  get precioVentaCurrencyId () {
    return this._precioVentaCurrencyId
  }

  set precioVentaCurrencyId (value) {
    this._precioVentaCurrencyId = value
  }

  get mtoRndImpVenta () {
    return this._mtoRndImpVenta
  }

  set mtoRndImpVenta (value) {
    this._mtoRndImpVenta = value
  }

  get mtoRndImpVentaCurrencyId () {
    return this._mtoRndImpVentaCurrencyId
  }

  set mtoRndImpVentaCurrencyId (value) {
    this._mtoRndImpVentaCurrencyId = value
  }
}

module.exports = Invoice
