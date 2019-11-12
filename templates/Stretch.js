'use strict'

var Direction = require('./Direction')

class Stretch {
  constructor () {
    this._warning = []
    this._id = null
    this._partida = new Direction()
    this._llegada = new Direction()
    this._description = null
    this._value = null
    this._valueCurrencyId = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get id () {
    return this._id
  }

  set id (value) {
    this._id = value
  }

  get partida () {
    return this._partida
  }

  set partida (value) {
    this._partida = value
  }

  get llegada () {
    return this._llegada
  }

  set llegada (value) {
    this._llegada = value
  }

  get description () {
    return this._description
  }

  set description (value) {
    this._description = value
  }

  get value () {
    return this._value
  }

  set value (value) {
    this._value = value
  }

  get valueCurrencyId () {
    return this._valueCurrencyId
  }

  set valueCurrencyId (value) {
    this._valueCurrencyId = value
  }

  toJSON () {
    return {
      warning: this.warning,
      id: this.id,
      partida: this.partida.toJSON(),
      llegada: this.llegada.toJSON(),
      description: this.description,
      value: this.value,
      valueCurrencyId: this.valueCurrencyId
    }
  }
}

module.exports = Stretch
