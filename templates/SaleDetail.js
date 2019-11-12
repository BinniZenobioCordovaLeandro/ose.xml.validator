'use strict'

var DetailAttribute = require('./DetailAttribute')
var TotalTax = require('./TotalTax')
var Shipment = require('./Shipment')
var Vehicle = require('./Vehicle')
var Charge = require('./Charge')

const catalogCommercialMeasureUnitTypeCode = require('../catalogs/catalogCommercialMeasureUnitTypeCode.json')
const catalogSunatProductCode = require('../catalogs/catalogSunatProductCode.json')
const catalogUnitSalePriceTypeCode = require('../catalogs/catalogUnitSalePriceTypeCode.json')

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
    this._codProdGs1SchemeId = null
    this._descripcion = null
    this._mtoValorUnitario = null
    this._mtoValorUnitarioCurrencyId = null
    this._cargos = [new Charge()]
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
    this._mtoType = null
    this._mtoTypeListName = null
    this._mtoTypeListAgencyName = null
    this._mtoTypeListUri = null
    this._mtoPrecioUnitario = null
    this._mtoPrecioUnitarioCurrencyId = null
    this._mtoValorVenta = null
    this._mtoValorVentaCurrencyId = null
    this._totalTax = new TotalTax()
    this._atributos = [new DetailAttribute()]
    this._envio = new Shipment()
    this._vehiculo = new Vehicle()
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
      /^[0]{6}$/.test(value) ||
        /^[0]{4}$/.test(value)
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
    if (this.codProdGS1_schemeId === 'GTIN-8' && !/^[A-Za-z0-9]{8}$/.test(value)) this.warning.push('4334')
    if (this.codProdGS1_schemeId === 'GTIN-12' && !/^[A-Za-z0-9]{12}$/.test(value)) this.warning.push('4334')
    if (this.codProdGS1_schemeId === 'GTIN-13' && !/^[A-Za-z0-9]{13}$/.test(value)) this.warning.push('4334')
    if (this.codProdGS1_schemeId === 'GTIN-14' && !/^[A-Za-z0-9]{14}$/.test(value)) this.warning.push('4334')
    if (value && !this.codProdGS1_schemeId) this.warning.push('4333')
    this._codProdGS1 = value
  }

  get codProdGs1SchemeId () {
    return this._codProdGs1SchemeId
  }

  set codProdGs1SchemeId (value) {
    if (value && value !== 'GTIN-8' && value !== 'GTIN-12' && value !== 'GTIN-13' && value !== 'GTIN-14') this.warning.push('4335')
    this._codProdGs1SchemeId = value
  }

  get descripcion () {
    return this._descripcion
  }

  set descripcion (value) {
    if (!value) throw new Error('2026')
    if (!/^[\w\W]{1,500}$/.test(value)) throw new Error('2027')
    this._descripcion = value
  }

  get mtoValorUnitario () {
    return this._mtoValorUnitario
  }

  set mtoValorUnitario (value) {
    if (!value) throw new Error('2068')
    if (!/^[+]?[0-9]{1,12}\.[0-9]{1,10}$/.test(value)) throw new Error('2369')
    this._mtoValorUnitario = value
  }

  get mtoValorUnitarioCurrencyId () {
    return this._mtoValorUnitarioCurrencyId
  }

  set mtoValorUnitarioCurrencyId (value) {
    this._mtoValorUnitarioCurrencyId = value
  }

  get mtoType () {
    return this._mtoType
  }

  set mtoType (value) {
    if (!catalogUnitSalePriceTypeCode[value]) throw new Error('2410')
    this._mtoType = value
  }

  get mtoTypeListName () {
    return this._mtoTypeListName
  }

  set mtoTypeListName (value) {
    if (value && value !== 'Tipo de Precio') this.warning.push('4252')
    this._mtoTypeListName = value
  }

  get mtoTypeListAgencyName () {
    return this._mtoTypeListAgencyName
  }

  set mtoTypeListAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4251')
    this._mtoTypeListAgencyName = value
  }

  get mtoTypeListUri () {
    return this._mtoTypeListUri
  }

  set mtoTypeListUri (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo16') this.warning.push('4253')
    this._mtoTypeListUri = value
  }

  get mtoPrecioUnitario () {
    return this._mtoPrecioUnitario
  }

  set mtoPrecioUnitario (value) {
    if (!value) throw new Error('2028')
    if (!/^[+]?[0-9]{1,12}\.[0-9]{1,10}$/.test(value) && Number(value) !== 0) throw new Error('2367')
    // throw new Error('3234') // PENDIENTE
    // Si existe en la misma línea un cac:TaxSubtotal con 'Código de tributo por línea' igual a '9996' cuyo 'Monto base'
    // es mayor a cero (cbc:TaxableAmount > 0) (Operaciones gratuitas), y 'Código de precio' es diferente de '02' (Valor referencial
    //  en operaciones no onerosa).
    this._mtoPrecioUnitario = value
  }

  get mtoPrecioUnitarioCurrencyId () {
    return this._mtoPrecioUnitarioCurrencyId
  }

  set mtoPrecioUnitarioCurrencyId (value) {
    this._mtoPrecioUnitarioCurrencyId = value
  }

  get mtoValorVenta () {
    return this._mtoValorVenta
  }

  set mtoValorVenta (value) {
    if (!/^[+]?[0-9]{1,12}\.[0-9]{1,2}$/.test(value) && Number(value) !== 0) throw new Error('2370')
    this._mtoValorVenta = value
  }

  get mtoValorVentaCurrencyId () {
    return this._mtoValorVentaCurrencyId
  }

  set mtoValorVentaCurrencyId (value) {
    this._mtoValorVentaCurrencyId = value
  }

  get totalTax () {
    return this._totalTax
  }

  set totalTax (value) {
    this._totalTax = value
  }

  get atributos () {
    return this._atributos
  }

  set atributos (value) {
    this._atributos = value
  }

  get envio () {
    return this._envio
  }

  set envio (value) {
    this._envio = value
  }

  get vehiculo () {
    return this._vehiculo
  }

  set vehiculo (value) {
    this._vehiculo = value
  }

  toJSON () {
    var json = {
      warning: this.warning,
      id: this.id,
      unidad: this.unidad,
      unidadUnitCodeListId: this.unidadUnitCodeListId,
      unidadUnitCodeListAgencyName: this.unidadUnitCodeListAgencyName,
      cantidad: this.cantidad,
      codProducto: this.codProducto,
      codProdSunat: this.codProdSunat,
      codProdSunatListID: this.codProdSunatListID,
      codProdSunatListAgencyName: this.codProdSunatListAgencyName,
      codProdSunatListName: this.codProdSunatListName,
      codProdGS1: this.codProdGS1,
      codProdGs1SchemeId: this.codProdGs1SchemeId,
      descripcion: this.descripcion,
      mtoValorUnitario: this.mtoValorUnitario,
      mtoValorUnitarioCurrencyId: this.mtoValorUnitarioCurrencyId,
      cargos: [],
      descuentos: this.descuentos,
      descuento: this.descuento,
      mtoBaseIgv: this.mtoBaseIgv,
      porcentajeIgv: this.porcentajeIgv,
      igv: this.igv,
      tipAfeIgv: this.tipAfeIgv,
      mtoBaseIsc: this.mtoBaseIsc,
      porcentajeIsc: this.porcentajeIsc,
      isc: this.isc,
      tipSisIsc: this.tipSisIsc,
      mtoBaseOth: this.mtoBaseOth,
      porcentajeOth: this.porcentajeOth,
      otroTributo: this.otroTributo,
      totalImpuestos: this.totalImpuestos,
      mtoType: this.mtoType,
      mtoTypeListName: this.mtoTypeListName,
      mtoTypeListAgencyName: this.mtoTypeListAgencyName,
      mtoTypeListUri: this.mtoTypeListUri,
      mtoPrecioUnitario: this.mtoPrecioUnitario,
      mtoPrecioUnitarioCurrencyId: this.mtoPrecioUnitarioCurrencyId,
      mtoValorVenta: this.mtoValorVenta,
      mtoValorVentaCurrencyId: this.mtoValorVentaCurrencyId,
      totalTax: this.totalTax.toJSON(),
      atributos: [],
      envio: this.envio.toJSON(),
      vehiculo: this.vehiculo.toJSON()
    }
    for (let index = 0; index < this.atributos.length; index++) json.atributos.push(this.atributos[index].toJSON())
    for (let index = 0; index < this.cargos.length; index++) json.cargos.push(this.cargos[index].toJSON())
    return json
  }
}

module.exports = SaleDetail
