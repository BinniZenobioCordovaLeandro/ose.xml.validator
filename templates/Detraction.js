'use strict'

class Detraction {
  constructor () {
    this._percent = null
    this._mount = null
    this._ctaBanco = null
    this._codMedioPago = null
    this._codBienDetraccion = null
    this._valueRef = null
  }

  get percent () {
    return this._percent
  }

  set percent (value) {
    this._percent = value
  }

  get mount () {
    return this._mount
  }

  set mount (value) {
    this._mount = value
  }

  get ctaBanco () {
    return this._ctaBanco
  }

  set ctaBanco (value) {
    this._ctaBanco = value
  }

  get codMedioPago () {
    return this._codMedioPago
  }

  set codMedioPago (value) {
    this._codMedioPago = value
  }

  get codBienDetraccion () {
    return this._codBienDetraccion
  }

  set codBienDetraccion (value) {
    this._codBienDetraccion = value
  }

  get valueRef () {
    return this._valueRef
  }

  set valueRef (value) {
    this._valueRef = value
  }
}

module.exports = Detraction
