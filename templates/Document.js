'use strict'

class Document {
  constructor () {
    this._warning = []

    this._nroDoc = null
    this._tipoDoc = null
    this._tipoDocListAgencyName = null
    this._tipoDocListName = null
    this._tipoDocListURI = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get nroDoc () {
    return this._nroDoc
  }

  set nroDoc (value) {
    this._nroDoc = value
  }

  get tipoDoc () {
    return this._tipoDoc
  }

  set tipoDoc (value) {
    this._tipoDoc = value
  }

  get tipoDocListAgencyName () {
    return this._tipoDocListAgencyName
  }

  set tipoDocListAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4251')
    this._tipoDocListAgencyName = value
  }

  get tipoDocListName () {
    return this._tipoDocListName
  }

  set tipoDocListName (value) {
    if (value && value !== 'Tipo de Documento') this.warning.push('4252')
    this._tipoDocListName = value
  }

  get tipoDocListURI () {
    return this._tipoDocListURI
  }

  set tipoDocListURI (value) {
    this._tipoDocListURI = value
  }
}

module.exports = Document
