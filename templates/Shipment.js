'use strict'

var Direction = require('./Direction')
var Transportist = require('./Transportist')
var Term = require('./Term')

var catalogTransportModalityCode = require('../catalogs/catalogTransportModalityCode.json')
var catalogTransportReasonCode = require('../catalogs/catalogTransportReasonCode.json')
var catalogCommercialMeasureUnitTypeCode = require('../catalogs/catalogCommercialMeasureUnitTypeCode.json')

class Shipment {
  constructor () {
    this._warning = []
    this._id = null
    this._idSchemeName = null
    this._idSchemeAgencyName = null
    this._idSchemeUri = null
    this._codTraslado = null
    this._desTraslado = null
    this._indTransbordo = null
    this._pesoTotal = null
    this._undPesoTotal = null
    this._numBultos = null
    this._modTraslado = null
    this._modTrasladoListName = null
    this._modTrasladoListAgencyName = null
    this._modTrasladoListUri = null
    this._fecTraslado = null
    this._subContract = null
    this._numContenedor = null
    this._codPuerto = null
    this._transportista = new Transportist()
    this._llegada = new Direction()
    this._partida = new Direction()
    this._terms = [new Term()]
  }

  get warning () {
    return this._warning
  }

  set warning (value) {
    this._warning = value
  }

  get id () {
    return this._id
  }

  set id (value) {
    if (value && !catalogTransportReasonCode[value]) this.warning.push('4249')
    this._id = value
  }

  get idSchemeName () {
    return this._idSchemeName
  }

  set idSchemeName (value) {
    if (value && value !== 'Motivo de Traslado') this.warning.push('4255')
    this._idSchemeName = value
  }

  get idSchemeAgencyName () {
    return this._idSchemeAgencyName
  }

  set idSchemeAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4256')
    this._idSchemeAgencyName = value
  }

  get idSchemeUri () {
    return this._idSchemeUri
  }

  set idSchemeUri (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo20') this.warning.push('4257')
    this._idSchemeUri = value
  }

  get desTraslado () {
    return this._desTraslado
  }

  set desTraslado (value) {
    this._desTraslado = value
  }

  get pesoTotal () {
    return this._pesoTotal
  }

  set pesoTotal (value) {
    if (value && /^[+-]?[0-9]{12}\.[0-9]{2}/.test(value)) this.warning.push('4155')
    this._pesoTotal = value
  }

  get undPesoTotal () {
    return this._undPesoTotal
  }

  set undPesoTotal (value) {
    if (value && value !== 'KGM') this.warning.push('4154')
    if (value && !catalogCommercialMeasureUnitTypeCode[value]) this.warning.push('4154')
    this._undPesoTotal = value
  }

  get modTraslado () {
    return this._modTraslado
  }

  set modTraslado (value) {
    if (value && !catalogTransportModalityCode[value]) this.warning.push('4043')
    this._modTraslado = value
  }

  get modTrasladoListName () {
    return this._modTrasladoListName
  }

  set modTrasladoListName (value) {
    if (value && value !== 'Modalidad de Transporte') this.warning.push('4252')
    this._modTrasladoListName = value
  }

  get modTrasladoListAgencyName () {
    return this._modTrasladoListAgencyName
  }

  set modTrasladoListAgencyName (value) {
    if (value && value !== 'PE:SUNAT') this.warning.push('4251')
    this._modTrasladoListAgencyName = value
  }

  get modTrasladoListUri () {
    return this._modTrasladoListUri
  }

  set modTrasladoListUri (value) {
    if (value && value !== 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo18') this.warning.push('4253')
    this._modTrasladoListUri = value
  }

  get fecTraslado () {
    return this._fecTraslado
  }

  set fecTraslado (value) {
    this._fecTraslado = value
  }

  get subContract () {
    return this._subContract
  }

  set subContract (value) {
    this._subContract = value
  }

  get numContenedor () {
    return this._numContenedor
  }

  set numContenedor (value) {
    if (value && !/[\w -]{6,8}/.test(value)) this.warning.push('4170')
    this._numContenedor = value
  }

  get transportista () {
    return this._transportista
  }

  set transportista (value) {
    this._transportista = value
  }

  get llegada () {
    return this._llegada
  }

  set llegada (value) {
    this._llegada = value
  }

  get partida () {
    return this._partida
  }

  set partida (value) {
    this._partida = value
  }

  get terms () {
    return this._terms
  }

  set terms (value) {
    this._terms = value
  }

  toJSON () {
    var json = {
      warning: this.warning,
      id: this.id,
      idSchemeName: this.idSchemeName,
      idSchemeAgencyName: this.idSchemeAgencyName,
      idSchemeUri: this.idSchemeUri,
      codTraslado: this.codTraslado,
      desTraslado: this.desTraslado,
      indTransbordo: this.indTransbordo,
      pesoTotal: this.pesoTotal,
      undPesoTotal: this.undPesoTotal,
      numBultos: this.numBultos,
      modTraslado: this.modTraslado,
      modTrasladoListName: this.modTrasladoListName,
      modTrasladoListAgencyName: this.modTrasladoListAgencyName,
      modTrasladoListUri: this.modTrasladoListUri,
      fecTraslado: this.fecTraslado,
      subContract: this.subContract,
      numContenedor: this.numContenedor,
      codPuerto: this.codPuerto,
      transportista: this.transportista.toJSON(),
      llegada: this.llegada.toJSON(),
      partida: this.partida.toJSON(),
      terms: []
    }
    for (let index = 0; index < this.terms.length; index++) {
      json.terms.push(this.terms[index].toJSON())
    }
    return json
  }
}

module.exports = Shipment
