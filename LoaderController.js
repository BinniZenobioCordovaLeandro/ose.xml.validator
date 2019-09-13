"use strict";

var Factura2_0Loader = require('./loaders/Factura2_0Loader'),
    Boleta2_0Loader = require('./loaders/Boleta2_0Loader');


var MyObjectLiteral = {
    "012.1": Factura2_0Loader,
    "032.1": Boleta2_0Loader
}

class LoaderController {
    constructor(DocumentType, ublVersion, xmlString, fileInfo = null, domDocument = null) {
        this._DocumentType = DocumentType;
        this._ublVersion = ublVersion;
        return new(MyObjectLiteral[DocumentType + ublVersion])(xmlString, fileInfo, domDocument);
    }
}

module.exports = LoaderController;