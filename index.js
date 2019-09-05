"use strict";

const ReturnCode = require('./catalogs/ReturnCode.json');
const Catalog01 = require('./catalogs/Catalog01.json');
var LoaderController = require('./LoaderController');

const chalk = require('chalk'),
    path = require('path'),
    fs = require('fs'),
    dom = require('xmldom').DOMParser,
    xpathModule = require('xpath');

console.log(chalk.cyan('- Hi!, i\'m ose.xml.validator, and well be, i running now.'));

var xmlpath = path.resolve('./xmls/EJEMPLO XML FACTURA 1 GRAVADA.xml');

var xml = fs.readFileSync(xmlpath, 'utf8');

var doc = new dom().parseFromString(xml, "application/xml");
var namespaces = (xml) => {
    var regexSimple = /xmlns+=+['"](.*?)['"]/g,
        regexComplex = /xmlns+:(.*?)=+['"](.*?)['"]/g,
        namespaces = {},
        matchesSimple = null,
        matchesComplex = null,
        countId = 0;
    while (matchesSimple = regexSimple.exec(xml)) {
        namespaces.xmlns = matchesSimple[1];
    }
    while (matchesComplex = regexComplex.exec(xml)) {
        namespaces[matchesComplex[1]] = matchesComplex[2];
    }
    return namespaces;
}

var select = xpathModule.useNamespaces(namespaces(xml));

var ublVersion = select("string(//*[local-name(.)='UBLVersionID' and namespace-uri(.)='urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2'])", doc);
var documentType = select("string(//*[local-name(.)='InvoiceTypeCode' and namespace-uri(.)='urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2'])", doc);

var pathString = "string(//xmlns:Invoice/cbc:UBLVersionID)";
console.log(chalk.cyan('pathString'), ':', select(pathString, doc));

console.log(chalk.white('xmlInfo'), {
    'ublVersion': ublVersion,
    'documentType': Catalog01[documentType]
});

console.log(chalk.white(`- now, i will create a Loader class to `), chalk.yellow(`${Catalog01[documentType]} ${ublVersion}`));

var loader = new LoaderController(ublVersion, Catalog01[documentType], xml);

console.log('The loader will be loading \n');

loader.load().then((result) => {
    if (result.length) {
        var warnings = {};
        result.forEach(warning => {
            warnings[warning] = ReturnCode[warning];
        });
        console.log(chalk.yellow(':/ ', 'All was loaded, but well... found warnings.'));
        console.log(chalk.yellow(JSON.stringify(warnings)));
    } else {
        console.log(chalk.blue(':) ', 'All was loaded good. '));
    }
}).catch((err) => {
    console.error(chalk.red(':( ', 'I found an exception. '));
    console.error(chalk.red(err.name), chalk.red(':'), chalk.red(err.message));
    console.error(chalk.red('Detail'), chalk.red(':'), chalk.red(`${ReturnCode[err.message]}`));
});