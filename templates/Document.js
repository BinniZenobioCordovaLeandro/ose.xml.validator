'use strict'

class Document {
  constructor () {
    this._warning = []
    this._nroDoc = null
    this._tipoDoc = null
    this._tipoDocListAgencyName = null
    this._tipoDocListName = null
    this._tipoDocListURI = null
    this._payIdentifier = null
    this._payIdentifierListName = null
    this._payIdentifierListAgencyName = null
    this._docEmisor = null
    this._docEmisorSchemeName = null
    this._docEmisorSchemeAgencyName = null
    this._docEmisorSchemeURI = null
    this._tipoDocEmisor = null
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
    if (value && !(
      value === 'Tipo de Documento' ||
      value === 'Documento Relacionado')) this.warning.push('4252')
    this._tipoDocListName = value
  }

  get tipoDocListURI () {
    return this._tipoDocListURI
  }

  set tipoDocListURI (value) {
    this._tipoDocListURI = value
  }

  get payIdentifier () {
    return this._payIdentifier
  }

  set payIdentifier (value) {
    this._payIdentifier = value
  }

  get payIdentifierListName () {
    return this._payIdentifierListName
  }

  set payIdentifierListName (value) {
    if (value && value !== 'Anticipo') this.warning.push('4252')
    this._payIdentifierListName = value
  }

  get payIdentifierListAgencyName () {
    return this._payIdentifierListAgencyName
  }

  set payIdentifierListAgencyName (value) {
    if (value && value !== 'PE:SUNAT') throw new Error('4251')
    this._payIdentifierListAgencyName = value
  }

  get docEmisor () {
    return this._docEmisor
  }

  set docEmisor (value) {
    this._docEmisor = value
  }

  get docEmisorSchemeName () {
    return this._docEmisorSchemeName
  }

  set docEmisorSchemeName (value) {
    if (value && value !== 'Documento de Identidad') this.warning.push('4255')
    this._docEmisorSchemeName = value
  }

  get docEmisorSchemeAgencyName () {
    return this._docEmisorSchemeAgencyName
  }

  set docEmisorSchemeAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4256')
    this._docEmisorSchemeAgencyName = value
  }

  get docEmisorSchemeURI () {
    return this._docEmisorSchemeURI
  }

  set docEmisorSchemeURI (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06') this.warning.push('4257')
    this._docEmisorSchemeURI = value
  }

  get tipoDocEmisor () {
    return this._tipoDocEmisor
  }

  set tipoDocEmisor (value) {
    if (!value || value !== '6') throw new Error('2520')
    this._tipoDocEmisor = value
  }

  toJSON () {
    return {
      warning: this.warning,
      nroDoc: this.nroDoc,
      tipoDoc: this.tipoDoc,
      tipoDocListAgencyName: this.tipoDocListAgencyName,
      tipoDocListName: this.tipoDocListName,
      tipoDocListURI: this.tipoDocListURI,
      payIdentifier: this.payIdentifier,
      payIdentifierListName: this.payIdentifierListName,
      payIdentifierListAgencyName: this.payIdentifierListAgencyName,
      docEmisor: this.docEmisor,
      docEmisorSchemeName: this.docEmisorSchemeName,
      docEmisorSchemeAgencyName: this.docEmisorSchemeAgencyName,
      docEmisorSchemeURI: this.docEmisorSchemeURI,
      tipoDocEmisor: this.tipoDocEmisor
    }
  }
}

module.exports = Document
