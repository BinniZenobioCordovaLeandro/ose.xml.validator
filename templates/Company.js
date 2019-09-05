"use strict";
var Address = require('./Address');

class Company {
    constructor() {
        this._ruc = null;
        this._razonSocial = null;
        this._nombreComercial = null;
        this._address = new Address();
        this._email = null;
        this._telephone = null;
    }
}

module.exports = Company;