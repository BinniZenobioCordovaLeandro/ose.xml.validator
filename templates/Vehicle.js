'use strict'

var Stretch = require('./Stretch')

class Vehicle {
  constructor () {
    this._warning = []
    this._tramo = new Stretch()
    this._config = null
    this._configListAgencyName = null
    this._configListName = null
    this._usefulLoadType = null
    this._usefulLoadTm = null
    this._usefulLoadTmUnitCode = null
    this._effectiveLoadType = null
    this._effectiveLoadTm = null
    this._effectiveLoadUnitCode = null
    this._refValue = null
    this._refValueCurrencyId = null
    this._nominalLoad = null
    this._nominalLoadCurrencyId = null
    this._returnFactor = null
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get tramo () {
    return this._tramo
  }

  set tramo (value) {
    this._tramo = value
  }

  get config () {
    return this._config
  }

  set config (value) {
    this._config = value
  }

  get configListAgencyName () {
    return this._configListAgencyName
  }

  set configListAgencyName (value) {
    if (value && value !== 'PE:MTC') this.warning.push('4251')
    this._configListAgencyName = value
  }

  get configListName () {
    return this._configListName
  }

  set configListName (value) {
    if (value && value !== '4252') this.warning.push('4252')
    this._configListName = value
  }

  get usefulLoadType () {
    return this._usefulLoadType
  }

  set usefulLoadType (value) {
    this._usefulLoadType = value
  }

  get usefulLoadTm () {
    return this._usefulLoadTm
  }

  set usefulLoadTm (value) {
    this._usefulLoadTm = value
  }

  get usefulLoadTmUnitCode () {
    return this._usefulLoadTmUnitCode
  }

  set usefulLoadTmUnitCode (value) {
    this._usefulLoadTmUnitCode = value
  }

  get effectiveLoadType () {
    return this._effectiveLoadType
  }

  set effectiveLoadType (value) {
    this._effectiveLoadType = value
  }

  get effectiveLoadTm () {
    return this._effectiveLoadTm
  }

  set effectiveLoadTm (value) {
    this._effectiveLoadTm = value
  }

  get effectiveLoadUnitCode () {
    return this._effectiveLoadUnitCode
  }

  set effectiveLoadUnitCode (value) {
    this._effectiveLoadUnitCode = value
  }

  get refValue () {
    return this._refValue
  }

  set refValue (value) {
    this._refValue = value
  }

  get refValueCurrencyId () {
    return this._refValueCurrencyId
  }

  set refValueCurrencyId (value) {
    if (value !== 'PEN') throw new Error('3208')
    this._refValueCurrencyId = value
  }

  get nominalLoad () {
    return this._nominalLoad
  }

  set nominalLoad (value) {
    this._nominalLoad = value
  }

  get nominalLoadCurrencyId () {
    return this._nominalLoadCurrencyId
  }

  set nominalLoadCurrencyId (value) {
    this._nominalLoadCurrencyId = value
  }

  get returnFactor () {
    return this._returnFactor
  }

  set returnFactor (value) {
    this._returnFactor = value
  }

  toJSON () {
    return {
      warning: this.warning,
      tramo: this.tramo.toJSON(),
      config: this.config,
      configListAgencyName: this.configListAgencyName,
      configListName: this.configListName,
      usefulLoadType: this.usefulLoadType,
      usefulLoadTm: this.usefulLoadTm,
      usefulLoadTmUnitCode: this.usefulLoadTmUnitCode,
      effectiveLoadType: this.effectiveLoadType,
      effectiveLoadTm: this.effectiveLoadTm,
      effectiveLoadUnitCode: this.effectiveLoadUnitCode,
      refValue: this.refValue,
      refValueCurrencyId: this.refValueCurrencyId,
      nominalLoad: this.nominalLoad,
      nominalLoadCurrencyId: this.nominalLoadCurrencyId,
      returnFactor: this.returnFactor
    }
  }
}

module.exports = Vehicle
