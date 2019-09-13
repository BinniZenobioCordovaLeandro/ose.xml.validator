"use strict";

const ReturnCode = require('./catalogs/ReturnCode.json'),
    Catalog01 = require('./catalogs/Catalog01.json');

var DomDocumentHelper = require('./helpers/DomDocumentHelper'),
    LoaderController = require('./LoaderController');

const chalk = require('chalk'),
    path = require('path'),
    fs = require('fs'),
    dom = require('xmldom').DOMParser,
    xpathModule = require('xpath');

console.log(chalk.cyan('- Hi!, i\'m ose.xml.validator, and well be, i running now.'))

var xmlpath = path.resolve('./xmls/EJEMPLO XML FACTURA 1 GRAVADA.xml');
var xml = fs.readFileSync(xmlpath, 'utf8');

var domDocumentHelper = new DomDocumentHelper(xml);
domDocumentHelper.mappingNameSpaces();

var ublVersion = domDocumentHelper.select("string(//xmlns:Invoice/cbc:UBLVersionID)");
var documentType = domDocumentHelper.select("string(//xmlns:Invoice/cbc:InvoiceTypeCode)");
console.log(chalk.white('xmlInfo'), {
    'ublVersion': ublVersion,
    'documentType': Catalog01[documentType]
});

console.log(chalk.white(`- now, i will create a Loader class to `), chalk.yellow(`${Catalog01[documentType]} ${ublVersion}`));

var fileInfo = {
    rucEmisor: '20600695771',
    tipoComprobante: '01',
    serieComprobante: 'FFF1',
    correlativoComprobante: '1',
}

var loader = new LoaderController(documentType, ublVersion, xml, fileInfo, domDocumentHelper);
console.log('The loader will be loading');
loader.load().then((result) => {
    if (result.length) {
        var warnings = {};
        result.forEach(warning => {
            warnings[warning] = ReturnCode[warning];
        });
        console.log(chalk.yellow(':/ ', 'All was loaded, but well... found warnings.'));
        console.log(chalk.yellow(JSON.stringify(warnings)), '\n');
    } else {
        console.log(chalk.blue(':) ', 'All was loaded good. '), '\n');
    }
}).catch((err) => {
    console.error(chalk.red(':( ', 'I found an exception. '));
    console.error(chalk.red(err.name), chalk.red(':'), chalk.red(err.message));
    console.error(chalk.red('Detail'), chalk.red(':'), chalk.red(`${ReturnCode[err.message]}`), '\n');
});