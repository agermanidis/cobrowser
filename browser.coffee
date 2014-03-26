{EventEmitter} = require 'events'
net = require 'net'
util = require 'util'
vm = require 'vm'
uuid = require 'node-uuid'

Coffeescript = require 'coffee-script'

{CookieJar} = require './cookie'
{BrowserContext} = require './context'
{parseAddress} = require './address_bar'

class Browser extends EventEmitter
  constructor: (opts = {}) ->
    @id = opts.id or uuid()
    {@cookieJar, @debugScript} = opts
    @cookieJar ?= new CookieJar
    @tabs = {}
    @contexts = {}
    @attachedSockets = {}
    @documents = {}

  installTabListeners: (tab) ->
    id = tab.id

    tab.on 'status-changed', (msg) =>
      @send 'status-changed', id, msg

    tab.on 'session-changed', (session) =>
      @send 'session-changed', id, session
      @updateModel()

    tab.on 'about-to-destroy', =>
      @destroyTab id

  updateModel: ->
    @model.updateBrowser(@) if @model

  createTab: (opts, cb) ->
    if typeof opts == 'function'
      cb = opts
      opts = {}

    opts ?= {}
    opts.browser = @
    opts.debugScript = @debugScript

    tab = new BrowserContext opts
    @send 'tab-created', tab.id

    @addTab tab

    cb? tab
    tab

  destroyTab: (id) ->
    @destroyContext id
    @send 'tab-destroyed', id

  destroyContext: (id) ->
    delete @contexts[id]
    delete @tabs[id]

  getTab: (id) ->
    @tabs[id] or null

  attachToModel: (@model) ->
    @on 'tab-added', (ctx) =>
      #@model.addTab ctx
      @updateModel()

    @on 'tab-changed', (ctx) ->

  installSocket: (socket, id) ->
    socket.on 'back', (tab_id) =>
      tab = @getTab(tab_id)
      tab.back() if tab

    socket.on 'forward', (tab_id) =>
      tab = @getTab(tab_id)
      tab.forward() if tab

    socket.on 'reload', (tab_id) =>
      tab = @getTab(tab_id)
      tab.reload() if tab

    socket.on 'navigate', (tab_id, address) =>
      tab = @getTab(tab_id)
      tab.navigate parseAddress(address) if tab

    socket.on 'create-tab', (url) =>
      tab = @createTab {url}
      #tab.navigate url
      #socket.emit 'tab-created', tab.id

    socket.on 'disconnect', =>
      delete @attachedSockets[id]

    @on 'tab-added', (ctx) ->
      @send 'tab-added', ctx.id

  attachSocket: (socket) ->
    id = uuid()
    @attachedSockets[id] = socket
    #@attachedSockets.push socket
    @installSocket socket, id

  clientMessage: (id, command, args...) ->
    @send command, id, args...

  send: (args...) ->
    for id, socket of @attachedSockets
      socket.emit args...

  sendTo: (id, args...) ->
    @attachedSockets[id].emit args...

  firstTab: ->
    @tabs[ Object.keys(@tabs)[0] ]

  serializeTabs: ->
    tabs = []
    for id, tab of @tabs
      tabs.push tab.serialize()
    tabs

  serializeTabSessions: ->
    sessions = {}
    for id, tab of @tabs
      sessions[id] = tab.serializeSession()
    sessions

  serialize: ->
    {@id, tabs: @serializeTabs(), cookieJar: @cookieJar.toObject()}

  unload: ->
    for id, tab of @tabs
      tab.unloadDocument()

  addContext: (ctx) ->
    return if ctx.id in @contexts
    @contexts[ctx.id] = ctx

  addTab: (tab) ->
    id = tab.id
    return if id in @tabs
    @tabs[id] = @contexts[id] = tab
    @installTabListeners tab
    @emit 'tab-added', tab

  @deserialize: (serialized) ->
    @fromObject JSON.parse serialized

  @fromObject: ({id, tabs, cookieJar}) ->
    cookieJar = CookieJar.fromObject cookieJar
    browser = new Browser id, {cookieJar}
    for tab in tabs
      browser.addTab BrowserContext.deserialize tab, browser
    browser

  startBrowserREPL: (port) =>
    settings = null

    context = vm.createContext()
    context.browser = @

    preprocess = (data) -> data

    run = (data) ->
      vm.runInContext preprocess(data), context

    server = net.createServer (conn) =>
      isCommand = (data) ->
        data.indexOf("#") == 0

      conn.on 'data', (data) =>
        data = data.toString()

        unless settings
          settings = JSON.parse data

          if settings.language == 'coffeescript'
            preprocess = (data) -> Coffeescript.compile data, bare: true
          return

        else
          try
            reply = run data
          catch e
            reply = e

          conn.write util.inspect(reply, false, 0, true) + "\r\n"

    server.listen port, ->
      console.log "browser server listening to #{port}"

    {server, context}

  startBrowserContextREPL: (port) ->
    server = net.createServer (conn) =>
      context = null

      evalFn = (data) ->
        context.window.run data.toString()

      conn.on 'data', (data) =>
        unless context
          {id, language} = JSON.parse data

          console.log "establishing repl connection with options: ", util.format({id, language})

          unless @tabs[id]?
            context = @tabs[ Object.keys(@tabs)[0] ]
          else
            context = @tabs[ id ]

          if language == 'coffeescript'
            evalFn = (data) ->
              context.window.run Coffeescript.compile(data, bare: true)

          if context
            context.on 'console-message', (type, args...) ->
              conn.write "[#{type.toUpperCase()}] #{args.join(' ')}"

          return

        try
          if context.window
            #reply = context.window.run data.toString()
            reply = evalFn data
          else
            reply = "NOT CONNECTED TO WINDOW"
        catch e
          reply = e

        #conn.write util.format( reply ) + '\r\n'
        conn.write util.inspect(reply, false, 0, true) + '\r\n'

    server.listen port, ->
      console.log "listening to #{port}"

module.exports = {Browser}
