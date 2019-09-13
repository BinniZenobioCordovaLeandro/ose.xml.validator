"use stritct";

class Signature {
    constructor() {
        this._id = null;
        this._canonicalization_algorithm = null;
        this._signature_algorithm = null;
        this._reference_uri = null;
        this._transform_algorithm = null;
        this._digest_algorithm = null;
        this._digestValue = null;
        this._signatureValue = null;
        this._x509Certificate = null;
        this._signature = null;
        this._signature_id = null;
        this._partyIdentificationId = null;
        this._partyName = null;
        this._externalReferenceUri = null;
    }
    get id() {
        return this._id;
    }
    set id(value) {
        if (!value) throw new Error('2085');
        if (!/^[A-Za-z0-9]{1,3000}$/.test(value)) throw new Error('2084');
        this._id = value;
    }
    get canonicalization_algorithm() {
        return this._canonicalization_algorithm;
    }
    set canonicalization_algorithm(value) {
        if (!value) throw new Error('2087');
        if (!/^[A-Za-z0-9:/.#-]{1,3000}$/.test(value)) throw new Error('2086');
        this._canonicalization_algorithm = value;
    }
    get signature_algorithm() {
        return this._signature_algorithm;
    }
    set signature_algorithm(value) {
        if (!value) throw new Error('2089');
        if (!/^[A-Za-z0-9:/.#-]{1,3000}$/.test(value)) throw new Error('2088');
        this._signature_algorithm = value;
    }
    get reference_uri() {
        return this._reference_uri;
    }
    set reference_uri(value) {
        if (value.length <= 0) throw new Error('2090');
        if (!value) throw new Error('2091');
        this._reference_uri = value;
    }
    get transform_algorithm() {
        return this._transform_algorithm;
    }
    set transform_algorithm(value) {
        if (!value) throw new Error('2093');
        if (!/^[A-Za-z0-9:/.#-]{1,3000}$/.test(value)) throw new Error('2092');
        this._transform_algorithm = value;
    }
    get digest_algorithm() {
        return this._digest_algorithm;
    }
    set digest_algorithm(value) {
        if (!value) throw new Error('2095');
        if (!/^[A-Za-z0-9:/.#-]{1,3000}$/.test(value)) throw new Error('2094');
        this._digest_algorithm = value;
    }
    get digestValue() {
        return this._digestValue;
    }
    set digestValue(value) {
        if (!value) throw new Error('2097');
        this._digestValue = value;
    }
    get signatureValue() {
        return this._signatureValue;
    }
    set signatureValue(value) {
        if (!value) throw new Error('2099');
        if (!/^[A-Za-z0-9+=/]{2,}$/.test(value)) throw new Error('2098');
        this._signatureValue = value;
    }
    get x509Certificate() {
        return this._x509Certificate;
    }
    set x509Certificate(value) {
        if (!value) throw new Error('2101');
        if (!/^[A-Za-z0-9+=\n/ ]{2,}$/.test(value)) throw new Error('2100');
        this._x509Certificate = value;
    }
    get signature() {
        return this._signature;
    }
    set signature(value) {
        this._signature = value;
    }
    get signature_id() {
        return this._signature_id;
    }
    set signature_id(value) {
        if (!value) throw new Error('2076');
        if (!/^[A-Za-z0-9]{1,3000}$/.test(value)) throw new Error('2077');
        this._signature_id = value;
    }
    get partyIdentificationId() {
        return this._partyIdentificationId;
    }
    set partyIdentificationId(value) {
        if (!value) throw new Error('2076');
        this._partyIdentificationId = value;
    }
    get partyName() {
        return this._partyName;
    }
    set partyName(value) {
        if (!value) throw new Error('2081');
        if (!/^[A-Za-z0-9. ]{1,3000}$/.test(value)) throw new Error('2080');
        this._partyName = value;
    }
    get externalReferenceUri() {
        return this._externalReferenceUri;
    }
    set externalReferenceUri(value) {
        if (!value) throw new Error('2083');
        if (!/^[A-Za-z0-9]{1,3000}$/.test(value)) throw new Error('2082');
        this._externalReferenceUri = value;
    }
}

module.exports = Signature;