'use strict'

var catalogTaxConceptIdentificationCode = require('../catalogs/catalogTaxConceptIdentificationCode.json')

class DetailAttribute {
  constructor () {
    this._warning = []
    this._code = null
    this._codeListName = null
    this._codeListAgencyName = null
    this._codeListURI = null
    this._name = null
    this._value = null
    this._quantity = null
    this._quantityUnitCode = null
    this._fecInicio = null
    this._horInicio = null
    this._fecFin = null
    this._duracion = null
    this._duracionUnitCode = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get code () {
    return this._code
  }

  set code (value) {
    if (!catalogTaxConceptIdentificationCode[value]) console.warn('DetailAttribute', `${value} not exist into the catalog catalogTaxConceptIdentificationCode`)
    this._code = value
  }

  get codeListName () {
    return this._codelistName
  }

  set codeListName (value) {
    if (value && value !== 'Propiedad del item') this.warning.push('4252')
    this._codelistName = value
  }

  get codeListAgencyName () {
    return this._codelistAgencyName
  }

  set codeListAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4251')
    this._codelistAgencyName = value
  }

  get codeListURI () {
    return this._codelistURI
  }

  set codeListURI (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo55') this.warning.push('4253')
    this._codelistURI = value
  }

  get name () {
    return this._name
  }

  set name (value) {
    if (value && value === '') this.warning.push('4235')
    this._name = value
  }

  get value () {
    return this._value
  }

  set value (value) {
    this._value = value
  }

  get quantity () {
    return this._quantity
  }

  set quantity (value) {
    this._quantity = value
  }

  get quantityUnitCode () {
    return this._quantityUnitCode
  }

  set quantityUnitCode (value) {
    if (value && value !== 'TNE') throw new Error('3115')
    this._quantityUnitCode = value
  }

  get fecInicio () {
    return this._fecInicio
  }

  set fecInicio (value) {
    this._fecInicio = value
  }

  get horInicio () {
    return this._horInicio
  }

  set horInicio (value) {
    this._horInicio = value
  }

  get fecFin () {
    return this._fecFin
  }

  set fecFin (value) {
    this._fecFin = value
  }

  get duracion () {
    return this._duracion
  }

  set duracion (value) {
    if (value && !/[0-9]{1,4}/.test(value)) this.warning.push('4281')
    this._duracion = value
  }

  get duracionUnitCode () {
    return this._duracionUnitCode
  }

  set duracionUnitCode (value) {
    if (value && value !== 'DAY') this.warning.push('4313')
    this._duracionUnitCode = value
  }

  toJSON () {
    return {
      warning: this.warning,
      code: this.code,
      codeListName: this.codeListName,
      codeListAgencyName: this.codeListAgencyName,
      codeListURI: this.codeListURI,
      name: this.name,
      value: this.value,
      quantity: this.quantity,
      quantityUnitCode: this.quantityUnitCode,
      fecInicio: this.fecInicio,
      horInicio: this.horInicio,
      fecFin: this.fecFin,
      duracion: this.duracion,
      duracionUnitCode: this.duracionUnitCode
    }
  }
}

module.exports = DetailAttribute
