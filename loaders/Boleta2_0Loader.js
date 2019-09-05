"use strict"

class Boleta2_0Loader {
    constructor(xml) {
        this._xml = xml;
    }
    get xml() {
        return this._xml;
    }
    set xml(value) {
        this._xml = value;
    }
    load(xml = this.xml) {
        console.log('loading sentences to Boleta2_0Loader');
    }
}

module.exports = Boleta2_0Loader;