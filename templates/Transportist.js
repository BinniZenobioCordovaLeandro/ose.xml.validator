'use strict'

var catalogIdentityDocumentTypeCode = require('../catalogs/catalogIdentityDocumentTypeCode.json')

class Transportist {
  constructor () {
    this._warning = []

    this._tipoDoc = null
    this._numDoc = null
    this._numDocSchemeName = null
    this._numDocSchemeAgencyName = null
    this._numDocSchemeUri = null
    this._rznSocial = null
    this._placa = null
    this._choferTipoDoc = null
    this._choferDoc = null
    this._choferDocSchemeName = null
    this._choferDocSchemeAgencyName = null
    this._choferDocSchemeURI = null
    this._regMtc = null
    this._numConstancia = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get tipoDoc () {
    return this._tipoDoc
  }

  set tipoDoc (value) {
    if (value && value !== '6') this.warning.push('4162')
    this._tipoDoc = value
  }

  get numDoc () {
    return this._numDoc
  }

  set numDoc (value) {
    this._numDoc = value
  }

  get numDocSchemeName () {
    return this._numDocSchemeName
  }

  set numDocSchemeName (value) {
    if (value && value !== 'Documento de Identidad') this.warning.push('4255')
    this._numDocSchemeName = value
  }

  get numDocSchemeAgencyName () {
    return this._numDocSchemeAgencyName
  }

  set numDocSchemeAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4256')
    this._numDocSchemeAgencyName = value
  }

  get numDocSchemeUri () {
    return this._numDocSchemeUri
  }

  set numDocSchemeUri (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06') this.warning.push('4257')
    this._numDocSchemeUri = value
  }

  get rznSocial () {
    return this._rznSocial
  }

  set rznSocial (value) {
    if (value && /[\w]{3,100}/.test(value)) this.warning.push('4165')
    this._rznSocial = value
  }

  get placa () {
    return this._placa
  }

  set placa (value) {
    if (value && !/^[\w -]{6,8}$/.test(value)) this.warning.push('4167')
    this._placa = value
  }

  get choferTipoDoc () {
    return this._choferTipoDoc
  }

  set choferTipoDoc (value) {
    if (value && !(
      value === '1' ||
      value === '4' ||
      value === '7' ||
      value === 'A'
    )) this.warning.push('4173')
    if (value && !catalogIdentityDocumentTypeCode[value]) this.warning.push('4173')
    this._choferTipoDoc = value
  }

  get choferDoc () {
    return this._choferDoc
  }

  set choferDoc (value) {
    this._choferDoc = value
  }

  get choferDocSchemeName () {
    return this._choferDocSchemeName
  }

  set choferDocSchemeName (value) {
    if (value && value !== 'Documento de Identidad') this.warning.push('4255')
    this._choferDocSchemeName = value
  }

  get choferDocSchemeAgencyName () {
    return this._choferDocSchemeAgencyName
  }

  set choferDocSchemeAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('PE:SUNAT')
    this._choferDocSchemeAgencyName = value
  }

  get choferDocSchemeURI () {
    return this._choferDocSchemeURI
  }

  set choferDocSchemeURI (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06') this.warning.push('4257')
    this._choferDocSchemeURI = value
  }

  get regMtc () {
    return this._regMtc
  }

  set regMtc (value) {
    this._regMtc = value
  }

  get numConstancia () {
    return this._numConstancia
  }

  set numConstancia (value) {
    this._numConstancia = value
  }
}

module.exports = Transportist
