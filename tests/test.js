var xpath = require('xpath'),
    dom = require('xmldom').DOMParser,
    fs = require('fs'),
    path = require('path'),
    chalk = require('chalk');

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
    console.log(namespaces);
    return namespaces;
}

var xml = fs.readFileSync(path.resolve('./tests/xmlTest.xml'), 'utf8');
var doc = new dom().parseFromString(xml);
var select = xpath.useNamespaces(namespaces(xml));

// Like, chalk.
console.log(select('/xmlns:Invoice/cbc:InvoiceTypeCode/text()', doc)[0].nodeValue);
console.log(select('/xmlns:Invoice/cbc:InvoiceTypeCode/@listAgencyName', doc)[0].value);

var ArrayElements = '/xmlns:Invoice/cac:AccountingSupplierParty';

select(ArrayElements, doc).forEach((element, index) => {
    console.log('\n');
    console.log(select('string(/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/udt:vocal)', doc));
    console.log(select('string(/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/udt:vocal/@prop)', doc));
    console.log(select('number(/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/udt:vocal/@num)', doc));
    console.log(select('/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID/text()', doc)[index].nodeValue);
    console.log(select('/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeName', doc)[index].value);
});