'use strict'

var DetailAttribute = require('./DetailAttribute')

const catalogCommercialMeasureUnitTypeCode = require('../catalogs/catalogCommercialMeasureUnitTypeCode.json')
const catalogSunatProductCode = require('../catalogs/catalogSunatProductCode.json')

class SaleDetail {
  constructor () {
    this._warning = []

    this._id = null
    this._unidad = null
    this._unidadUnitCodeListId = null
    this._unidadUnitCodeListAgencyName = null
    this._cantidad = null
    this._codProducto = null
    this._codProdSunat = null
    this._codProdSunatListID = null
    this._codProdSunatListAgencyName = null
    this._codProdSunatListName = null
    this._codProdGS1 = null
    this._codProdGS1SchemeId = null
    this._descripcion = null
    this._mtoValorUnitario = null
    this._cargos = null
    this._descuentos = null
    this._descuento = null
    this._mtoBaseIgv = null
    this._porcentajeIgv = null
    this._igv = null
    this._tipAfeIgv = null
    this._mtoBaseIsc = null
    this._porcentajeIsc = null
    this._isc = null
    this._tipSisIsc = null
    this._mtoBaseOth = null
    this._porcentajeOth = null
    this._otroTributo = null
    this._totalImpuestos = null
    this._mtoPrecioUnitario = null
    this._mtoValorVenta = null
    this._mtoValorGratuito = null

    this._atributos = [new DetailAttribute()]
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
    if (value && (!/[0-9]{1,5}/.test(value) || /^[0]{1,5}$/.test(value))) throw new Error('2023')
    this._id = value
  }

  get unidad () {
    return this._unidad
  }

  set unidad (value) {
    if (!value) throw new Error('2883')
    if (value && !catalogCommercialMeasureUnitTypeCode[value]) throw new Error('2936')
    this._unidad = value
  }

  get unidadUnitCodeListId () {
    return this._unidadUnitCodeListId
  }

  set unidadUnitCodeListId (value) {
    if (value && value !== 'UN/ECE rec 20') this.warning.push('4258')
    this._unidadUnitCodeListId = value
  }

  get unidadUnitCodeListAgencyName () {
    return this._unidadUnitCodeListAgencyName
  }

  set unidadUnitCodeListAgencyName (value) {
    if (value && value !== 'United Nations Economic Commission for Europe') this.warning.push('4259')
    this._unidadUnitCodeListAgencyName = value
  }

  get cantidad () {
    return this._cantidad
  }

  set cantidad (value) {
    if (!value || /^[0.]{1,}$/.test(value)) throw new Error('2024')
    if (!/^[+]?[0-9]{1,12}\.[0-9]{1,10}$/.test(value)) throw new Error('2025')
    this._cantidad = value
  }

  get codProducto () {
    return this._codProducto
  }

  set codProducto (value) {
    if (value && !/^[A-Za-z0-9!$%^&*()_+|~=`{}[\]:";'<>?,./]{1,30}$/.test(value)) throw new Error('4269')
    this._codProducto = value
  }

  get codProdSunat () {
    return this._codProdSunat
  }

  set codProdSunat (value) {
    if (value && !catalogSunatProductCode[value]) this.warning.push('4332')
    if (value &&
            /^[\w]{8}$/.test(value) && (
      /[0]{6}$/.test(value) ||
                /[0]{4}$/.test(value)
    )) this.warning.push('4337')
    this._codProdSunat = value
  }

  get codProdSunatListID () {
    return this._codProdSunatListID
  }

  set codProdSunatListID (value) {
    if (value && value !== 'UNSPSC') this.warning.push('4254')
    this._codProdSunatListID = value
  }

  get codProdSunatListAgencyName () {
    return this._codProdSunatListAgencyName
  }

  set codProdSunatListAgencyName (value) {
    if (value && value !== 'GS1 US') this.warning.push('4251')
    this._codProdSunatListAgencyName = value
  }

  get codProdSunatListName () {
    return this._codProdSunatListName
  }

  set codProdSunatListName (value) {
    if (value && value !== 'Item Classification') this.warning.push('4252')
    this._codProdSunatListName = value
  }

  get codProdGS1 () {
    return this._codProdGS1
  }

  set codProdGS1 (value) {
    if (this.codProdGS1SchemeId === 'GTIN-8' && value.length) { this._codProdGS1 = value }
  }

  get codProdGS1SchemeId () {
    return this._codProdGS1SchemeId
  }

  set codProdGS1SchemeId (value) {
    this._codProdGS1SchemeId = value
  }
}

module.exports = SaleDetail
