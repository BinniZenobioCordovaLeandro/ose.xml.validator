var dom = require('xmldom').DOMParser;
var xpathModule = require('xpath');

class DomDocumentHelper {
    constructor(xmlString, mimeType = "application/xml") {
        this._xml = xmlString;
        this._dom = new dom().parseFromString(xmlString, mimeType);
        this._nameSpaces = [];
        this._xpath = null;
    }
    get xml() {
        return this._xml;
    }
    set xml(xml) {
        this._xml = xml;
    }
    get dom() {
        return this._dom;
    }
    set dom(dom) {
        this._dom = dom;
    }
    get nameSpaces() {
        return this.nameSpaces;
    }
    set nameSpaces(nameSpaces) {
        this._nameSpaces = nameSpaces;
    }
    get xpath() {
        return this._xpath;
    }
    set xpath(xpath) {
        this._xpath = xpath;
    }
    mappingNameSpaces(xml = this.xml, xpath = this.xpath) {
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
        this.namespaces = namespaces;
        this.xpath = xpathModule.useNamespaces(namespaces);
    }
    select(xpathExpression, dom = this.dom, xpath = this.xpath) {
        if (/^[string]{1,6}/.test(xpathExpression)) {
            var xpathExpressionExist = xpathExpression.replace('string', 'boolean');
            var exist = xpath(xpathExpressionExist, dom);
            // console.log(xpathExpressionExist, exist);
            if (!exist) return false;

            var xpathExpressionCount = xpathExpression.replace('string', 'count');
            var count = xpath(xpathExpressionCount, dom);
            // console.log(xpathExpressionCount, count);
            if (count != 1) return false;
        }
        // console.log(xpathExpressionExist);
        // console.log(xpath(xpathExpressionExist, dom));
        return xpath(xpathExpression, dom);
    }
}
module.exports = DomDocumentHelper;