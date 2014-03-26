express = require 'express'
util = require 'util'
app = express()
fs = require 'fs'
#request = require 'request'
http = require 'http'
URL = require 'url'
WebSocketServer = require('websocket').server

app.configure ->
  app.use express.static __dirname + '/pages'
  app.use express.bodyParser()
  app.use express.cookieParser("SECRET")

# app.use (req, res, next) ->
#   data = ''
#   req.setEncoding 'utf-8'
#   req.on 'data', (chunk) ->
#     data += chunk
#   req.on 'end', ->
#     req.data = data
#     next()

app.get '/testpost', (req, res) ->
  console.log "response", res
  console.log "params", req.params
  console.log "query", req.query
  console.log "body", req.body
  res.send util.format(req.query) + '\n' + util.format(req.headers)

app.get '/download', (req, res) ->
  {url} = req.query
  options = URL.parse(url)
  options.method = "GET"
  filename = options.path.split('/').slice(-1)[0]
  res.set "Content-Disposition", "attachment; filename=\"#{filename}\""
  dreq = http.request options, (dres) ->
    res.set "Content-Type", dres.headers['Content-Type']
    dres.pipe res
  dreq.end()

app.post '/testpost', (req, res) ->
  console.log "request", req
  console.log "params", req.params
  console.log "query", req.query
  console.log "body", req.body
  console.log "cookie", req.cookies.test
  res.cookie "test", "val"

  res.send util.format(req.body) + '\n' + util.format(req.headers)

app.get '/testget', (req, res) ->
  console.log 'got request'
  res.json a: 2

startWebSocketServer = (server) ->
  server = new WebSocketServer httpServer: server
  server.on 'request', (request) ->
    console.log 'request made'
    connection = request.accept()
    console.log 'connection made'
    connection.send "CONNECTED!"
    connection.on 'message', (msg) ->
      connection.send "RECEIVED!"

module.exports =
  start: (port = 1859, cb) ->
    unless @server
      @server = app.listen port, ->
        console.log "listening at http://localhost:#{port}"
        cb?()
      startWebSocketServer @server

  kill: ->
    @server.close()

if require.main == module
  module.exports.start()
