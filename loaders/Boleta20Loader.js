'use strict'
const BaseSale = require('../templates/BaseSale')
class Boleta20Loader extends BaseSale {
  constructor (xml) {
    super()
    this._xml = xml
  }

  get xml () {
    return this._xml
  }

  set xml (value) {
    this._xml = value
  }

  load (xml = this.xml) {
    console.log('loading sentences to Boleta20Loader')
  }
}

module.exports = Boleta20Loader
