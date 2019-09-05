var xpath = require('xpath'),
    dom = require('xmldom').DOMParser,
    fs = require('fs'),
    path = require('path'),
    chalk = require('chalk');

var namespaces = (xml) => {
    var regex = /xmlns+:(.*?)=+['"](.*?)['"]/g,
        namespaces = {},
        matches = null;
    while (matches = regex.exec(xml)) {
        namespaces[matches[1]] = matches[2];
    }
    console.log(namespaces);
    return namespaces;
}

var xml = fs.readFileSync(path.resolve('./tests/xmlCreated.xml'), 'utf8');
// var select = xpath.useNamespaces({
//     "bookml": "http://example.com/book"
// });
var select = xpath.useNamespaces(namespaces(xml));

var doc = new dom().parseFromString(xml)

// TIME TO TEST
// console.log(chalk.red('----------------------------------------------------------------------------------'));
// console.log(select('/book/cac:title', doc));
// console.log(select("string(/book/cac:title)", doc));

console.log(chalk.red('----------------------------------------------------------------------------------'));
console.log(select('//cbc:UBLVersionID/text()', doc)[0].nodeValue);
console.log(select("string(//cbc:UBLVersionID)", doc));

console.log(chalk.red('----------------------------------------------------------------------------------'));
console.log(select('//cbc:CustomizationID/text()', doc)[0].nodeValue);
console.log(select("string(//cbc:CustomizationID)", doc));

// other logic
console.log(chalk.red('----------------------------------------------------------------------------------'));
var listID = select('//cbc:InvoiceTypeCode/@listID', doc);
console.log(listID[0].value);
var gen = xpath.select('//Invoice/cac:InvoiceLine/cac:Item/cac:CommodityClassification', doc);
console.dir(gen);

// console.log(select("string(//cbc:InvoiceTypeCode@listID)", doc));

// console.log(chalk.red('----------------------------------------------------------------------------------'));
// // console.log(select('/Invoice/cbc:UBLVersionID/text()', doc)[0].nodeValue);
// console.log(select("string(/Invoice/cbc:UBLVersionID)", doc));

// console.log(chalk.red('----------------------------------------------------------------------------------'));
// // console.log(select('//Invoice/cbc:CustomizationID/text()', doc)[0].nodeValue);
// console.log(select("string(//Invoice/cbc:CustomizationID)", doc));