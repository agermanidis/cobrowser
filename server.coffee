express = require 'express'
app = express()
{EventEmitter} = require 'events'
{Browser} = require './browser'
{argv} = require 'optimist'

browser = new Browser debugScript: argv.debug

browserEvents = new EventEmitter
clientEvents = new EventEmitter

filesStored = {}

app.configure ->
  app.use express.static __dirname + '/public'
  app.set 'view engine', 'jade'
  app.set 'view options', layout: no
  app.use express.bodyParser()

browser.startBrowserREPL 8594
browser.startBrowserContextREPL 8595

app.get '/', (req, res) ->
  res.render 'client', tabs: JSON.stringify browser.serializeTabSessions()

app.get '/create_tab', (req, res) ->
  {url, userId} = req.query
  browser.createTab {url}, (tab) ->
    #res.json id: tab.id, tab: tab.serializeSession()
    res.json id: tab.id

app.get '/tab', (req, res) ->
  {id, userId} = req.query
  tab = browser.getTab id
  if tab
    document = tab.getOrGenerateSerializedDocument?()

    if document
      res.render 'tab',
        tabId: id
        userId: userId
        documentId: tab.document._id
        serializedDocument: JSON.stringify document
        documentOptions: JSON.stringify tab.documentOptions()
    else
      res.render 'tab',
        tabId: id
        userId: userId
        documentId: ''
        serializedDocument: 'null'
        documentOptions: JSON.stringify tab.documentOptions()

  else
    res.send 404

app.get '/document', (req, res) ->
  {id} = req.query
  tab = browser.getTab id
  if tab
    serializedDocument = tab.getOrGenerateSerializedDocument()
    documentId = tab.document._id
    res.json {serializedDocument, documentId}
  else
    res.send 404

app.get '/destroy_tab', (req, res) ->
  {id} = req.query
  if id
    browser.destroyTab id
  res.send 200

app.post '/upload', (req, res) ->
  for file in req.files
    filesStored[file.id] = true

server = app.listen 9705, ->
  console.log "listening at http://localhost:9705"

io = require('socket.io').listen(server)

clientSocket = io.of '/client'
pageSocket = io.of '/page'

pageSocket.on 'connection', (socket) ->
  socket.on 'subscribe', (tabId, userId) ->
    console.log "SUBSCRIBE REQUEST", tabId
    if tab = browser.getTab tabId
      tab.attachSocket userId, socket

clientSocket.on 'connection', (socket) ->
  browser.attachSocket socket


