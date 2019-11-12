'use stritct'

class Signature {
  constructor () {
    this._id = null
    this._canonicalizationAlgorithm = null
    this._signatureAlgorithm = null
    this._referenceUri = null
    this._transformAlgorithm = null
    this._digestAlgorithm = null
    this._digestValue = null
    this._signatureValue = null
    this._x509Certificate = null
    this._signature = null
    this._signatureId = null
    this._partyIdentificationId = null
    this._partyName = null
    this._externalReferenceUri = null
  }

  get id () {
    return this._id
  }

  set id (value) {
    if (!value) throw new Error('2085')
    if (!/^[\wÀ-ÿ #$-/:-?{-~!"^_`+=]{1,3000}$/.test(value)) throw new Error('2084')
    this._id = value
  }

  get canonicalizationAlgorithm () {
    return this._canonicalizationAlgorithm
  }

  set canonicalizationAlgorithm (value) {
    if (!value) throw new Error('2087')
    if (!/^[\wÀ-ÿ #$-/:-?{-~!"^_`+=]{1,3000}$/.test(value)) throw new Error('2086')
    this._canonicalizationAlgorithm = value
  }

  get signatureAlgorithm () {
    return this._signatureAlgorithm
  }

  set signatureAlgorithm (value) {
    if (!value) throw new Error('2089')
    if (!/^[\wÀ-ÿ #$-/:-?{-~!"^_`+=]{1,3000}$/.test(value)) throw new Error('2088')
    this._signatureAlgorithm = value
  }

  get referenceUri () {
    return this._referenceUri
  }

  set referenceUri (value) {
    if (!value) throw new Error('2091')
    if (value.length <= 0 || value === '') throw new Error('2090')
    this._referenceUri = value
  }

  get transformAlgorithm () {
    return this._transformAlgorithm
  }

  set transformAlgorithm (value) {
    if (!value) throw new Error('2093')
    if (!/^[\wÀ-ÿ #$-/:-?{-~!"^_`+=]{1,3000}$/.test(value)) throw new Error('2092')
    this._transformAlgorithm = value
  }

  get digestAlgorithm () {
    return this._digestAlgorithm
  }

  set digestAlgorithm (value) {
    if (!value) throw new Error('2095')
    if (!/^[\wÀ-ÿ #$-/:-?{-~!"^_`+=]{1,3000}$/.test(value)) throw new Error('2094')
    this._digestAlgorithm = value
  }

  get digestValue () {
    return this._digestValue
  }

  set digestValue (value) {
    if (!value) throw new Error('2097')
    this._digestValue = value
  }

  get signatureValue () {
    return this._signatureValue
  }

  set signatureValue (value) {
    if (!value) throw new Error('2099')
    if (!/^[\wÀ-ÿ #$-/:-?{-~!"^_`+=]{2,}$/.test(value)) throw new Error('2098')
    this._signatureValue = value
  }

  get x509Certificate () {
    return this._x509Certificate
  }

  set x509Certificate (value) {
    if (!value) throw new Error('2101')
    if (!/^[\wÀ-ÿ #$-/:-?{-~!"^_`+=]{2,}$/.test(value)) throw new Error('2100')
    this._x509Certificate = value
  }

  get signature () {
    return this._signature
  }

  set signature (value) {
    this._signature = value
  }

  get signatureId () {
    return this._signatureId
  }

  set signatureId (value) {
    if (!value) throw new Error('2076')
    if (!/^[\wÀ-ÿ #$-/:-?{-~!"^_`+=]{1,3000}$/.test(value)) throw new Error('2077')
    this._signatureId = value
  }

  get partyIdentificationId () {
    return this._partyIdentificationId
  }

  set partyIdentificationId (value) {
    if (!value) throw new Error('2079')
    this._partyIdentificationId = value
  }

  get partyName () {
    return this._partyName
  }

  set partyName (value) {
    if (!value) throw new Error('2081')
    if (!/^[\wÀ-ÿ #$-/:-?{-~!"^_`+=]{1,3000}$/.test(value)) throw new Error('2080')
    this._partyName = value
  }

  get externalReferenceUri () {
    return this._externalReferenceUri
  }

  set externalReferenceUri (value) {
    if (!value) throw new Error('2083')
    if (!/^[\wÀ-ÿ #$-/:-?{-~!"^_`+=]{1,3000}$/.test(value)) throw new Error('2082')
    this._externalReferenceUri = value
  }

  toJSON () {
    return {
      id: this.id,
      canonicalizationAlgorithm: this.canonicalizationAlgorithm,
      signatureAlgorithm: this.signatureAlgorithm,
      referenceUri: this.referenceUri,
      transformAlgorithm: this.transformAlgorithm,
      digestAlgorithm: this.digestAlgorithm,
      digestValue: this.digestValue,
      signatureValue: this.signatureValue,
      x509Certificate: this.x509Certificate,
      signature: this.signature,
      signatureId: this.signatureId,
      partyIdentificationId: this.partyIdentificationId,
      partyName: this.partyName,
      externalReferenceUri: this.externalReferenceUri
    }
  }
}

module.exports = Signature
