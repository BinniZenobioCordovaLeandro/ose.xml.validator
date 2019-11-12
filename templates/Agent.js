'use strict'

class Agent {
  constructor () {
    this._warning = []
    this._ruc = null
    this._rucSchemeId = null
    this._rucSchemeName = null
    this._rucSchemeAgencyName = null
    this._rucSchemeUri = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get ruc () {
    return this._ruc
  }

  set ruc (value) {
    this._ruc = value
  }

  get rucSchemeId () {
    return this._rucSchemeId
  }

  set rucSchemeId (value) {
    if (this.ruc && !value) throw new Error('3157')
    if (this.ruc && value && value !== '6') throw new Error('3158')
    this._rucSchemeId = value
  }

  get rucSchemeName () {
    return this._rucSchemeName
  }

  set rucSchemeName (value) {
    if (value && value !== 'Documento de Identidad') this.warning.push('4255')
    this._rucSchemeName = value
  }

  get rucSchemeAgencyName () {
    return this._rucSchemeAgencyName
  }

  set rucSchemeAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push()
    this._rucSchemeAgencyName = value
  }

  get rucSchemeUri () {
    return this._rucSchemeUri
  }

  set rucSchemeUri (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06') this.warning.push('4257')
    this._rucSchemeUri = value
  }

  toJSON () {
    return {
      warning: this.warning,
      ruc: this.ruc,
      rucSchemeId: this.rucSchemeId,
      rucSchemeName: this.rucSchemeName,
      rucSchemeAgencyName: this.rucSchemeAgencyName,
      rucSchemeUri: this.rucSchemeUri
    }
  }
}

module.exports = Agent
