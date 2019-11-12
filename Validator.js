'use strict'

const chalk = require('chalk')

const ReturnCode = require('./catalogs/ReturnCode.json')
const catalogDocumentTypeCode = require('./catalogs/catalogDocumentTypeCode.json')

var DomDocumentHelper = require('./helpers/DomDocumentHelper')
var LoaderController = require('./LoaderController')

class Validator {
  constructor (xmlString, fileInfo) {
    this._xmlString = xmlString || null
    this._fileInfo = fileInfo || { rucEmisor: null, tipoComprobante: null, serieComprobante: null, correlativoComprobante: null }
  }

  get xmlString () {
    return this._xmlString
  }

  set xmlString (value) {
    this._xmlString = value
  }

  get fileInfo () {
    return this._fileInfo
  }

  set fileInfo (value) {
    this._fileInfo = value
  }

  validate (xmlString = this.xmlString, fileInfo = this.fileInfo) {
    return new Promise((resolve, reject) => {
      if (!xmlString) throw new Error('xmlString parameter can\'t be empty !')

      console.log(chalk.cyan('- Hi!, i\'m ose.xml.validator.'), chalk.cyan('And well be, i running now to validate the xml structure, second SUNAT.'))

      var domDocumentHelper = new DomDocumentHelper(xmlString)
      domDocumentHelper.mappingNameSpaces()

      var ublVersion = domDocumentHelper.select("string(//*[local-name(.)='UBLVersionID' and namespace-uri(.)='urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2'])")
      var documentType = fileInfo.tipoComprobante

      console.log(chalk.white('\t Good! the ublVersion is'), ublVersion)
      console.log(chalk.white('\t Great! , the documentType is'), documentType)

      console.log(chalk.white('- Well !,  now, i will create a Loader class to'), chalk.yellow(`document type ${documentType} by the ubl ${ublVersion}`))

      var loader = new LoaderController(documentType, ublVersion, xmlString, fileInfo, domDocumentHelper)
      console.log(' - The loader was created!')
      loader.load().then((result) => {
        if (result.length) {
          var warnings = {}
          for (let index = 0; index < result.length; index++) {
            const warning = result[index]
            warnings[warning] = ReturnCode[warning]
          }
          resolve(warnings)
        }
        resolve(null)
      }).catch((err) => {
        console.log(chalk.bgRed(err), chalk.red(ReturnCode[err.message]))
        throw err
      })
    })
  }
}

module.exports = Validator
