"use strict"
var Factura2_0 = require('./loaders/Factura2_0Loader'),
    Boleta2_0 = require('./loaders/Boleta2_0Loader');


var MyObjectLiteral = {
    "Factura2.1": Factura2_0,
    "Boleta de venta2.1": Boleta2_0
}

class LoaderController {
    constructor(ublVersion, DocumentType, xmlString) {
        this._ublVersion = ublVersion;
        this._DocumentType = DocumentType;
        return new(MyObjectLiteral[DocumentType + ublVersion])(xmlString);
    }
}

module.exports = LoaderController;