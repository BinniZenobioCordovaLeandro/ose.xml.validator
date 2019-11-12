'use strict'
var Address = require('./Address')
var Agent = require('./Agent')

var listContribuyente = require('../catalogs/listContribuyente.json')

class Company {
  constructor () {
    this._warning = []

    this._ruc = null
    this._rucSchemeId = null
    this._rucSchemeName = null
    this._rucSchemeAgencyName = null
    this._rucSchemeUri = null

    this._razonSocial = null

    this._nombreComercial = null

    this._address = new Address()
    this._email = null
    this._telephone = null

    this._agent = new Agent()
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
    if (!value) throw new Error('3089')
    if (!listContribuyente[value] || listContribuyente[value].ind_estado !== '00') throw new Error('2010')
    if (listContribuyente[value].ind_condicion === '12') throw new Error('2011')
    this._ruc = value
  }

  get rucSchemeId () {
    return this._rucSchemeId
  }

  set rucSchemeId (value) {
    if (!value) throw new Error('1008')
    if (Number(value) !== 6) throw new Error('1007')
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
    if (value && value !== 'PE:SUNAT') this.warning.push('4256')
    this._rucSchemeAgencyName = value
  }

  get rucSchemeUri () {
    return this._rucSchemeUri
  }

  set rucSchemeUri (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06') this.warning.push('4257')
    this._rucSchemeUri = value
  }

  get razonSocial () {
    return this._razonSocial
  }

  set razonSocial (value) {
    if (!value) throw new Error('1037')
    if (
      /^([ ]{1})/.test(value) ||
            /([ ]{1})$/.test(value) ||
            /[\t\n\r]{1,}/.test(value) ||
            !/^.{1,1500}$/.test(value)
    ) this.warning.push('4338')
    this._razonSocial = value
  }

  get nombreComercial () {
    return this._nombreComercial
  }

  set nombreComercial (value) {
    if (value) {
      if (
        /^([ ]{1})/.test(value) ||
                /([ ]{1})$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !(/^.{1,1500}$/.test(value))
      ) this.warning.push('4092')
    }
    this._nombreComercial = value
  }

  get address () {
    return this._address
  }

  set address (value) {
    this._address = value
  }

  get agent () {
    return this._agent
  }

  set agent (value) {
    this._agent = value
  }

  toJSON () {
    return {
      warning: this.warning,
      ruc: this.ruc,
      rucSchemeId: this.rucSchemeId,
      rucSchemeName: this.rucSchemeName,
      rucSchemeAgencyName: this.rucSchemeAgencyName,
      rucSchemeUri: this.rucSchemeUri,
      razonSocial: this.razonSocial,
      nombreComercial: this.nombreComercial,
      address: this.address.toJSON(),
      email: this.email,
      telephone: this.telephone,
      agent: this.agent.toJSON()
    }
  }
}

module.exports = Company
