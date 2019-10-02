'use strict'

var Factura20Loader = require('./loaders/Factura20Loader')
var Boleta20Loader = require('./loaders/Boleta20Loader')

var MyObjectLiteral = {
  '012.1': Factura20Loader,
  '032.1': Boleta20Loader
}

class LoaderController {
  constructor (DocumentType, ublVersion, xmlString, fileInfo = null, domDocument = null) {
    this._DocumentType = DocumentType
    this._ublVersion = ublVersion
    return new (MyObjectLiteral[DocumentType + ublVersion])(xmlString, fileInfo, domDocument)
  }
}

module.exports = LoaderController
