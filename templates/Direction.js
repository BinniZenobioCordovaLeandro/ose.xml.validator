'use strict'

class Direction {
  constructor () {
    this._warning = []

    this._ubigueo = null
    this._ubigueoSchemeAgencyName = null
    this._ubigueoSchemeName = null

    this._direccion = null
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

  get direccion () {
    return this._direccion
  }

  set direccion (value) {
    this._direccion = value
  }
}

module.exports = Direction
