http = require 'http'
{detect} = require 'jschardet'

options =
  host: 'www.google.gr'
  port: 80
  path: '/'

http.get options, (res) ->
  res.setEncoding 'utf8'
  data = ''
  res.on 'data', (chunk) ->
    data += chunk.toString('utf8')
  res.on 'end', ->
    console.log 'end', escape( data )

