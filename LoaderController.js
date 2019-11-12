'use strict'

var Factura20Loader = require('./loaders/Factura20Loader')
var Boleta20Loader = require('./loaders/Boleta20Loader')

var catalogDocumentTypeCode = require('./catalogs/catalogDocumentTypeCode.json')

var MyObjectLiteral = {
  Factura20Loader: Factura20Loader,
  Boleta20Loader: Boleta20Loader
}

class LoaderController {
  constructor (DocumentType, ublVersion, xmlString, fileInfo = null, domDocument = null) {
    this._DocumentType = DocumentType
    this._ublVersion = ublVersion
    return new (MyObjectLiteral[catalogDocumentTypeCode[DocumentType].loader])(xmlString, fileInfo, domDocument)
  }
}

module.exports = LoaderController
