'use strict'

var catalogGeograficLocationCode = require('../catalogs/catalogGeograficLocationCode.json')
var catalogCountryCode = require('../catalogs/catalogCountryCode.json')

class Address {
  constructor () {
    this._warning = []

    this._ubigueo = null
    this._ubigueoSchemeAgencyName = null
    this._ubigueoSchemeName = null

    this._codigoPais = null
    this._codigoPaisListId = null
    this._codigoPaisListAgencyName = null
    this._codigoPaisListName = null

    this._departamento = null
    this._provincia = null
    this._distrito = null
    this._urbanizacion = null
    this._direccion = null
    this._codLocal = null
    this._codLocalListAgencyName = null
    this._codLocalListName = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get ubigueo () {
    return this._ubigueo
  }

  set ubigueo (value) {
    if (value && !catalogGeograficLocationCode[value]) this.warning.push('4093')
    this._ubigueo = value
  }

  get ubigueoSchemeAgencyName () {
    return this._ubigueoSchemeAgencyName
  }

  set ubigueoSchemeAgencyName (value) {
    if (value && value !== 'PE:INEI') this.warning.push('4256')
    this._ubigueoSchemeAgencyName = value
  }

  get ubigueoSchemeName () {
    return this._ubigueoSchemeName
  }

  set ubigueoSchemeName (value) {
    if (value && value !== 'Ubigeos') this.warning.push('4255')
    this._ubigueoSchemeName = value
  }

  get codigoPais () {
    return this._codigoPais
  }

  set codigoPais (value) {
    if (value && catalogCountryCode[value] && catalogCountryCode[value].a2 !== 'PE') this.warning.push('4041')
    this._codigoPais = value
  }

  get codigoPaisListId () {
    return this._codigoPaisListId
  }

  set codigoPaisListId (value) {
    if (value && value !== 'ISO 3166-1') this.warning.push('4254')
    this._codigoPaisListId = value
  }

  get codigoPaisListAgencyName () {
    return this._codigoPaisListAgencyName
  }

  set codigoPaisListAgencyName (value) {
    if (value && value !== 'United Nations Economic Commission for Europe') this.warning.push('4251')
    this._codigoPaisListAgencyName = value
  }

  get codigoPaisListName () {
    return this._codigoPaisListName
  }

  set codigoPaisListName (value) {
    if (value && value !== 'Country') this.warning.push('4252')
    this._codigoPaisListName = value
  }

  get departamento () {
    return this._departamento
  }

  set departamento (value) {
    if (value) {
      if (
        /^([ ]{1})/.test(value) ||
                /([ ]{1})$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !/^.{1,30}$/.test(value)
      ) this.warning.push('4097')
    }
    this._departamento = value
  }

  get provincia () {
    return this._provincia
  }

  set provincia (value) {
    if (value) {
      if (
        /^([ ]{1})/.test(value) ||
                /([ ]{1})$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !/^.{1,30}$/.test(value)
      ) this.warning.push('4096')
    }
    this._provincia = value
  }

  get distrito () {
    return this._distrito
  }

  set distrito (value) {
    if (value) {
      if (
        /^([ ]{1})/.test(value) ||
                /([ ]{1})$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !/^.{1,30}$/.test(value)
      ) this.warning.push('4098')
    }
    this._distrito = value
  }

  get urbanizacion () {
    return this._urbanizacion
  }

  set urbanizacion (value) {
    if (value) {
      if (
        /^([ ]{1})?/.test(value) ||
                /([ ]{1})?$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !/^.{1,25}$/.test(value)
      ) this.warning.push('4095')
    }
    this._urbanizacion = value
  }

  get direccion () {
    return this._direccion
  }

  set direccion (value) {
    if (value) {
      if (
        /^([ ]{1})/.test(value) ||
                /([ ]{1})$/.test(value) ||
                /[\t\n\r]{1,}/.test(value) ||
                !/^.{1,200}$/.test(value)
      ) this.warning.push('4094')
    }
    this._direccion = value
  }

  get codLocal () {
    return this._codLocal
  }

  set codLocal (value) {
    if (!value) this.warning.push('3030')
    if (value && !/^[0-9]{4}$/.test(value)) this.warning.push('4242')
    this._codLocal = value
  }

  get codLocalListAgencyName () {
    return this._codLocalListAgencyName
  }

  set codLocalListAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4251')
    this._codLocalListAgencyName = value
  }

  get codLocalListName () {
    return this._codLocalListName
  }

  set codLocalListName (value) {
    if (value && value !== 'Establecimientos anexos') this.warning.push('4252')
    this._codLocalListName = value
  }
}

module.exports = Address
