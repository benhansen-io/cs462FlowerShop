http = require('http')
url = require('url')
querystring = require('querystring')

post = (postOptions, postData, callback) ->

  postReq = http.request postOptions, (res) ->
    output = ''
    res.setEncoding 'utf8'

    res.on 'data', (chunk) ->
      output += chunk

    res.on 'end', () ->
      if callback?
        callback null, output

  postReq.on 'error', (e) ->
    console.log "error posting to esl" + JSON.stringify e
    if callback?
      callback e

  postReq.write postData
  postReq.end()

module.exports.sendEvent = (esl, eventObject, callback) ->
  urlObject = url.parse esl
  postData = querystring.stringify eventObject

  postOptions =
    host: urlObject.hostname
    port: urlObject.port
    path: urlObject.path
    method: 'POST'
    headers:
      'Content-Type': 'application/x-www-form-urlencoded'
      'Content-Length': postData.length

  post postOptions, postData, callback
