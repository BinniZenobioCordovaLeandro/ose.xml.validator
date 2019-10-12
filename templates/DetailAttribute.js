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
    this._fecInicio = null
    this._fecFin = null
    this._duracion = null
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
    if (catalogTaxConceptIdentificationCode[value]) console.warn('DetailAttribute', `${value} not exist into the catalog catalogTaxConceptIdentificationCode`)
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

  get fecInicio () {
    return this._fecInicio
  }

  set fecInicio (value) {
    this._fecInicio = value
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
    this._duracion = value
  }
}

module.exports = DetailAttribute
