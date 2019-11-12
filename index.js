'use strict'

const fs = require('fs')
const path = require('path')
const iconv = require('iconv-lite')
const chalk = require('chalk')
const argv = require('yargs').argv
const moment = require('moment')

const Validator = require('./Validator')

if (!argv.xmlpath) throw new Error('I need an xml Path to execute all script logic')

var startTime = moment()

const xmlpath = path.resolve(argv.xmlpath)
fs.readFile(xmlpath, (err, data) => {
  if (err) throw err
  var encoding = /encoding="([\w-]{1,})"/mg.exec(data.toString('utf8'))[1]
  const xmlString = iconv.decode(data, encoding)
  const fileInfo = {}
  if (/([0-9]{11})-([0-9]{2})-([0-9a-zA-Z]{4})-([0-9]{1,8})\.([a-zA-Z]{3})$/.test(argv.xmlpath)) {
    const match = /([0-9]{11})-([0-9]{2})-([0-9a-zA-Z]{4})-([0-9]{1,8})\.([a-zA-Z]{3})$/.exec(argv.xmlpath)
    fileInfo.rucEmisor = match[1]
    fileInfo.tipoComprobante = match[2]
    fileInfo.serieComprobante = match[3]
    fileInfo.correlativoComprobante = match[4]
  } else if (argv.fileinfo) {
    if (/([0-9]{11})-([0-9]{2})-([0-9a-zA-Z]{4})-([0-9]{1,8})/.test(argv.fileinfo)) {
      const match = /([0-9]{11})-([0-9]{2})-([0-9a-zA-Z]{4})-([0-9]{1,8})$/.exec(argv.fileinfo)
      fileInfo.rucEmisor = match[1]
      fileInfo.tipoComprobante = match[2]
      fileInfo.serieComprobante = match[3]
      fileInfo.correlativoComprobante = match[4]
    } else {
      console.error(chalk.bgRed('The fileinfo argument value structure need be ([0-9]{11})-([0-9]{2})-([0-9a-zA-Z]{4})-([0-9]{1,8})$'))
      throw new Error('The fileinfo argument value structure need be ([0-9]{11})-([0-9]{2})-([0-9a-zA-Z]{4})-([0-9]{1,8})$')
    }
  } else {
    console.error(chalk.bgRed('The xml file name structure need be ([0-9]{11})-([0-9]{2})-([0-9a-zA-Z]{4})-([0-9]{1,8}).([a-zA-Z]{3})$'))
    throw new Error('The xml file name structure need be ([0-9]{11})-([0-9]{2})-([0-9a-zA-Z]{4})-([0-9]{1,8}).([a-zA-Z]{3})$')
  }
  new Validator(xmlString, fileInfo).validate().then((result) => {
    const milliseconds = moment().diff(startTime, 'milliseconds')
    console.log(chalk.white(`The xml ${fileInfo.rucEmisor}-${fileInfo.tipoComprobante}-${fileInfo.serieComprobante}-${fileInfo.correlativoComprobante}, validated results :`))
    if (result) console.warn(chalk.yellow('xml warnings'), result)
    if (Number(milliseconds) < 300) console.log(chalk.bgGreen(':D'), chalk.green(`processed on ${milliseconds} milliseconds`))
    if (Number(milliseconds) >= 300 && Number(milliseconds) < 500) console.log(chalk.bgYellow(':/'), chalk.yellow(`processed on ${milliseconds} milliseconds`))
    if (Number(milliseconds) >= 500) console.log(chalk.bgRed(':('), chalk.red(`processed on ${milliseconds} milliseconds`))

    console.log()
  }).catch((err) => {
    throw err
  })
})
