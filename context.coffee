{CookieJar} = require './cookie'
Contextify = require 'contextify'
uuid = require 'node-uuid'
URL = require 'url'
net = require 'net'
request = require 'request'
util = require 'util'
{EventEmitter} = require 'events'
{effectiveMediaVolume, setTime, HTMLMediaElement} = require './html/media'

cloneCookies = (cookies) ->

isTextInput = (node) ->
  node.nodeName == 'INPUT' and /(text|search|tel|email|password)/i.test node.type

descendantContexts = (context) ->
  list = []
  for child in context.childContexts
    list.push child
    Array::push.apply list, descendantContexts child
  list

class BrowserContext extends EventEmitter
  constructor: (opts = {}) ->
    console.log 'creating new context w/ opts', {opts}
    {@cookieJar, history, @opener, @parent, @frameElement, @name, @browser, @id, @debugScript, url} = opts

    @creator = @parent or @opener

    #@cookies ?= new CookieJar
    @cookieJar ?= new CookieJar
    #@cookieString = ''

    console.log 1

    if @parent
      length = @parent.childContexts.push @
      refreshWindowIndices @window if @window
      @index = length - 1

    console.log 2
    @resourceManager = new ResourceManager @

    console.log 3
    @id ?= uuid()
    console.log 4

    #@blank = @blankDocument()
    #@invalidProtocol = @invalidProtocolDocument()
    @sockets = []
    @window = null

    @promptReplies = {}

    @childContexts = []

    @formIsBeingSubmitted = false

    @on 'console-message', (type, args...) ->
      ret = ''
      for arg in args
        ret += ' '
        if typeof arg == 'object'
          ret += util.inspect arg
        else ret += arg
      console.log "[#{type.toUpperCase()}]#{ret}"

    @on 'status-changed', (newStatus) ->
      @status = newStatus

    @attachedSockets = {}

    if history
      {entries, index} = history
      @history = new History @, entries, index
      if document = @history.currentDocument()
        @loadDocument @history.currentDocument()
      else
        @history.assign url if url

    else
      console.log 'creating new history'
      @history = new History @
      @history.assign url if url

    @historyInterface = createHistoryInterface @history
    @locationInterface = createLocationInterface @history
    @consoleInterface = createConsoleInterface @

    if @browser
      @browser.addContext @

  resize: (width, height) ->
    @window.screen = {width, height}

  navigate: (url, cb) ->
    return unless url

    if url.indexOf("javascript:") == 0
      @window.run url.substring(11)

    else
      @history.assign url, yes

  send: (args...) ->
    console.log "SENDING", args...
    for id, socket of @attachedSockets
      console.log 'sending to', id
      socket.emit args...

  sendTo: (id, args...) ->
    @attachedSockets[id]?.emit args...

  serializeSession: (direction) ->
    return null if @history.isEmpty()
    id = @history.currentEntryId()
    hasPreviousEntries = @history.hasPreviousEntries()
    hasNextEntries = @history.hasNextEntries()
    url = @url()
    title = @title()
    {id, url, title, hasPreviousEntries, hasNextEntries, direction}

  sessionChanged: ->
    console.log 'SESSION CHANGED', @serializeSession()
    @document?.URL = @url()
    @emit 'session-changed', @serializeSession()
    @servePage()

  url: ->
    @history.currentURL()

  title: ->
    @history.currentTitle()

  retrieveNodeFromAddress: (address, document = @document) ->
    return unless @document
    # return document if address == document.address
    # results = document.getElementsByAddress(address)
    # return results[0] if results.length > 0
    document._addressCache[address]

  receiveFile: (id, buffer) ->
    @emit 'file-received', id, buffer

  handleEvent: (event, originalSender) ->
    #console.log "handling event", originalSender, event.type, event.eventClass, event.target

    return unless @document

    {eventClass, type, bubbles, cancelable} = event
    address = event.target

    ev = @document.createEvent (eventClass or "Event")
    ev.initEvent type, bubbles, cancelable

    if address == 'window'
      target = @window
    else
      target = @retrieveNodeFromAddress address, @document

    return unless target?

    switch eventClass
      when "MouseEvents"
        {screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button} = event

        for k, v of {screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button}
          ev['_' + k] = v

        #ev.initMouseEvent type, bubbles, cancelable, @window, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, null

        if target.dispatchEvent ev
          if event.type == 'click'
            target.click?()
            @send 'user-click', originalSender, address

          #if event.type == 'mousemove'
            #console.log 'mousemove', {screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button}
            #@send 'user-mousemove', originalSender, address, clientX, clientY

      when "KeyboardEvents"
        {keyIdentifier, keyLocation, keyCode, ctrlKey, shiftKey, altKey, metaKey, altGraphKey} = event
        #ev.initKeyboardEvent type, bubbles, cancelable, @window, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey, altGraphKey
        #ev.keyCode = keyCode

        for k, v of {keyIdentifier, keyLocation, keyCode, ctrlKey, shiftKey, altKey, metaKey, altGraphKey}
          ev['_' + k] = v

        canContinue = target.dispatchEvent ev
        return unless canContinue

        if event.type == 'keypress' and isTextInput(target) and event.keyCode == 13
          target.form?.submit()

      else
        #ev.initEvent type, bubbles, cancelable

        if type == 'resize'
          @window.innerWidth = event.innerWidth
          @window.innerHeight = event.innerHeight

        #else if type == 'scroll' and @target == 'window'

        target.dispatchEvent ev

  inputChanged: (target, newValue, changeId) ->
    @send 'input-changed', target._address, newValue, changeId

  handleInput: (targetAddress, newValue, changeId) ->
    target = @retrieveNodeFromAddress targetAddress, @document
    if target
      console.log "HANDLING TEXT INPUT w/ target ", target?, target.value
      if target
        target.value = newValue
        @inputChanged target, newValue, changeId
    #target._interact newValue, changeId

  collect: ({msg, matchArgs, except}, cb) ->
    received = {}
    done = false

    refresh = ->
      for id, socket of @attachedSockets
        return unless received[id]

      done = true
      cb()

    for id, socket of @attachedSockets
      unless socket in except
        socket.on msg, (args...) ->
          return if done

          for matchArg, index in (matchArgs or [])
            return if matchArg != args[index]
          received[id] = true
          refresh()

  installSocket: (userId, socket) ->
    socket.on 'back', =>
      @back()

    socket.on 'forward', =>
      @forward()

    socket.on 'event', (event) =>
      @handleEvent event, userId

    socket.on 'input-event', (target, newValue, changeId) =>
      @handleInput target, newValue, changeId

    socket.on 'submit-form', (addr) =>
      target = @retrieveNodeFromAddress addr, @document
      target?.submit?()

    # socket.on 'prompt-reply', (id, reply) =>
    #   @send 'prompt-replied', id, reply
    #   @promptReplies[id] = reply

    socket.on 'media', (address, command, args...) ->
      el = @retrieveNodeFromAddress address, @document

      switch command
        when 'time-update'
          [time] = args
          #el._time = time
          setTime el, time

        when 'set-volume'
          [vol] = args
          el.volume = vol

        when 'set-duration'
          [duration] = args
          setDuration el, duration

        when 'set-rate'
          [rate] = args
          setRate el, duration

        when 'loadedmetadata'
          changeReadyState el, HTMLMediaElement.HAVE_METADATA

        when 'loadeddata'
          changeReadyState el, HTMLMediaElement.HAVE_CURRENT_DATA

        when 'canplay'
          changeReadyState el, HTMLMediaElement.HAVE_FUTURE_DATA

        when 'canplaythrough'
          changeReadyState el, HTMLMediaElement.HAVE_ENOUGH_DATA

        when 'play'
          el.play()

        when 'pause'
          el.pause()

        when 'seek'
          [time] = args
          seekId = uuid()
          @collect msg: 'media', args: [address, 'seeked', seekId], ->
            el.currentTime = time
          @send 'media', address, 'seek', time, seekId

        when 'set-playback-rate'
          [rate] = args
          #el.playbackRate

        when 'ended'
          endedElement el

    socket.on 'disconnect', =>
      delete @attachedSockets[userId]

  attachSocket: (userId, socket) ->
    console.log 'attach socket', userId, socket?
    @attachedSockets[userId] = socket
    @installSocket userId, socket

  userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.57 Safari/537.1"

  back: ->
    @history.back()

  forward: ->
    @history.forward()

  getOrGenerateSerializedDocument: ->
    return unless @document?
    return @serializedDocument if @serializedDocument
    console.log "CREATING SERIALIZED DOCUMENT", @document.documentElement._childNodes.length
    @serializedDocument = new DOMToObject @document

  documentOptions: ->
    visited: @history.visited()

  abortDocument: (doc) ->
    # Cancel any instances of the fetch algorithm in the context of this Document,
    # discarding any tasks queued for them, and discarding any further data
    # received from the network for them.

    # http://www.whatwg.org/specs/web-apps/current-work/multipage/history.html#abort-a-document

  servePage: ->
    #@getOrGenerateSerializedDocument()
    @send 'document-changed', @documentOptions()

  blankDocument: ->
    doc = new Document
    doc.write "<html><head><title>about:blank</title></head><body>about:blank</body></html>"
    doc

  invalidProtocolDocument: ->
    doc = new Document
    doc.write "<html><head><title>Invalid Protocol</title></head><body>Invalid Protocol</body></html>"
    doc

  close: ->
    @emit 'about-to-destroy'
    @parent?.childContexts.slice @index, 1
    @closeAllContexts()

  closeAllContexts: ->
    for context in @childContexts
      context.close()

  unloadDocument: (document = @document) ->
    window = document._defaultView
    document._defaultView = null
    document._active = false

    if @document == document
      @serializedDocument = null
      @document = null
      @window?.destroy()
      @window = null
      @closeAllContexts()

  loadDocument: (document) ->
    @document = document
    document._active = true
    document._timesLoaded++
    @window = document._defaultView ?= @createWindow document

    # @window.addEventListener 'AllScriptsLoadedSuccessfully', =>
    #   console.log 'context loaded'
    #   @emit 'load'

    windowLoaded = =>
      console.log "before status change", @window._listeners
      @emit 'status-changed', null
      @servePage()
      @installEventListeners()

    if document.readyState == 'complete'
      windowLoaded()

    else
      #document.addEventListener 'DOMContentLoaded', (ev) ->
      document.addEventListener 'readystatechange', (ev) ->
        if document.readyState == 'interactive' or document.readyState == 'complete'
          windowLoaded()

  nodeInserted: (node) =>
    sd = @getOrGenerateSerializedDocument()
    serialized = sd.serializeCompact node, @document.URL
    return unless serialized
    parentAddress = node.parentNode._address
    referenceAddress = node.nextSibling?._address
    @send 'node-added', serialized, parentAddress, ( referenceAddress or null )
    sd.add node

  nodeRemoved: (node, parent) =>
    console.log "NODE REMOVED", node._address
    @send 'node-removed', node._address
    sd = @getOrGenerateSerializedDocument node.ownerDocument
    sd.remove node, parent

  nodeAttrModified: (node, attrName, attrValue) =>
    console.log "NODE ATTR MODIFIED", {attrName, attrValue}
    @send 'node-attr-modified', node._address, attrName, attrValue
    sd = @getOrGenerateSerializedDocument node.ownerDocument
    sd.changeAttribute node, attrName, attrValue

  textInputOcurred: (target, value, changeId) =>
    @send 'input-changed', target._address, value, changeId
    sd = @getOrGenerateSerializedDocument node.ownerDocument
    sd.changeIDLAttribute target, 'value', value

  installEventListeners: ->
    window = @window

    # window.addEventListener 'DOMNodeInserted', (evt) =>
    #   @nodeInserted evt.target

    window.addEventListener 'DOMNodeInserted', (evt) =>
      console.log 'node inserted'
      @nodeInserted evt.target

    window.addEventListener 'DOMNodeRemoved', (evt) =>
      @nodeRemoved evt.target, evt.relatedNode

    window.addEventListener 'DOMAttrModified', (evt) =>
      console.log "DOM ATTR MODIFIED"
      @nodeAttrModified evt.target, evt.attrName, evt.newValue

    window.addEventListener 'input', (evt) =>
      @textInputOcurred evt.target, evt.newValue, evt.changeId

  createWindow: (doc) ->
    window = createWindow @, doc

    #console.log "BEFORE CONTEXTIFY", window._listeners
    Contextify window
    #console.log "AFTER CONTEXTIFY", window._listeners

    window.window = window.self = window.frames = window.getGlobal()

    window

  createDocument: ({err, referrer, url, body, contentType, lastModified}, cb) ->
    @emit 'status-changed', "Loading #{URL.parse(url).host}..."

    console.log "CREATING DOCUMENT", {referrer}
    doc = new Document {url, referrer, lastModified, contentType}
    console.log "CREATED DOCUMENT"
    doc._defaultView = window = @createWindow doc
    #@installEventListeners window

    console.log "CREATING DOCUMENT W/ RESPTYPE", contentType

    if err
      message = "The server at #{URL.parse(url).host} could not be found."
      doc.write "<html><body>#{message}</body></html>"
    else
      if contentType == "text/html" or /\<html/.test body
        doc.write body
      else if /image/.test contentType
        doc.write "<html><body><img src=\"#{url}\"></img></html>"
      else
        doc.write "<html><body>#{body}</body></html>"
    doc.close()
    cb? null, doc

  serialize: (cb) ->
    id: @id
    parent: @parent?.id or ''
    opener: @opener?.id or ''
    history: @history.serialize()

  @deserialize: ({id, parent, opener, history}, browser) ->
    history = History.deserialize history
    opener = browser.tabs[opener] if opener
    parent = browser.tabs[parent] if parent
    {cookieJar} = browser
    new BrowserContext {id, history, opener, parent, cookieJar, browser}

  clone: ->
    new BrowserContext
      history: @history.serialize()
      cookies: cloneCookies @cookies
      parent: @parent
      opener: @opener

  download: (href, userId) ->
    @sendTo userId, 'download', href

  reload: ->
    @history.reload()

  prompt: (type, args...) ->
    id = uuid()
    @send 'prompt', id, type, args...
    id

  print: ->
    @send 'print'

  discardDocument: (document) ->
    @history.discardDocument document

  createBrowsingContext: ->
    #new BrowserContext opener: @, cookies: @cookies
    @browser.createTab opener: @, cookies: @cookies

  canvasCommand: (node, cmd, args...) ->
    @send 'canvas', node._address, cmd, args...

  mediaCommand: (node, cmd, args...) ->
    @send 'media', node._address, cmd, args...

  registerMediaElement: (el) ->
    el.addEventListener 'volumechange', =>
      @mediaCommand el, 'set-volume', effectiveMediaVolume(el)

module.exports = {BrowserContext, descendantContexts}

{Document} = require './dom/document'
{History} = require './history'
{ResourceManager} = require './resource_manager'
{createWindow, refreshWindowIndices} = require './dom/window'
{handleEvent, handleTextInputEvent} = './events'
{DOMToObject} = require './domtoobject'
{createConsoleInterface, createLocationInterface, createHistoryInterface} = require './interfaces'
