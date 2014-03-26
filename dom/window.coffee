require './meta'

{EventTarget} = require './event'
{extend} = require './helpers'
{fireSimpleEvent} = require './dom_helpers'
dom = require './index'
{XMLHttpRequest} = require './xmlhttprequest'
{DOMException, NETWORK_ERR} = require './exceptions'
{WebSocket} = require '../websocket'

startTimer = (window, startFn, stopFn, callback, ms) ->
  res = startFn callback, ms
  window._timers.push [res, stopFn]
  res

stopTimer = (window, id) ->
  return unless id?

  timers = window._timers
  for [timerId, fn], index in timers
    if id == timerId
      fn.call window, id
      timers.splice index, 1
      break

stopAllTimers = (window) ->
  window._timers.forEach ([res, stopFn]) ->
    stopFn.call window, res
  window._timers = []

class Window extends EventTarget
  @readonly ['history', 'console', 'document', 'length']

  name: "Pomo"

  @get
    XMLHttpRequest: ->
      self = @

      (args...) ->
        req = new XMLHttpRequest
        req.origin = self.document.origin
        req

    WebSocket: ->
      self = @

      (args...) ->
        new WebSocket self.document.origin, args...

  external:
    AddSearchProvider: (engineURL) ->
    IsSearchProviderInstalled: (engineURL) -> 0
    AddFavorite: (url, title) ->


  navigator:
    userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.57 Safari/537.1"
    appName: "Netscape"
    platform: process.platform
    appVersion: process.version
    plugins: {}
    language: "en-US"
    onLine: true
    javaEnabled: -> true

  constructor: (@_location, @_history, @_console, @_document) ->
    @_timers = []
    @_length = 0
    @_loadingScripts = []
    @_focused = true

    @addEventListener 'DOMNodeInsertedIntoDocument', ({target}) =>
      if target.nodeName == 'SCRIPT'
        target.addEventListener 'load', =>
          index = @_loadingScripts.indexOf target
          if index != -1
            @_loadingScripts.splice index, 1
          unless @_loadingScripts.length
            fireSimpleEvent @, 'AllScriptsLoadedSuccessfully'

        @_loadingScripts.push target

    @addEventListener 'load', =>
      unless @_loadingScripts.length
        fireSimpleEvent @, 'AllScriptsLoadedSuccessfully'


  getComputedStyle: (node) ->
    node?.style or null

  focus: ->
    @_focused = true
    fireSimpleEvent @, 'focus', false, false

  blur: ->
    @_focused = false
    fireSimpleEvent @, 'blur', false, false

  @events ['abort', 'afterprint', 'beforeprint', 'beforeload', 'beforeunload',
   'blur', 'cancel', 'canplay', 'canplaythrough', 'change', 'click',
   'close', 'contextmenu', 'cuechange', 'dblclick', 'drag', 'dragend',
   'dragenter', 'dragleave', 'dragover', 'dragstart', 'drop', 'durationchange',
   'emptied', 'ended', 'error', 'focus', 'hashchange', 'input', 'invalid', 'keydown',
   'keypress', 'keyup', 'load', 'loadeddata', 'loadedmetadata', 'loadstart',
   'message', 'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup',
   'offline', 'online', 'pause', 'play', 'playing', 'pagehide', 'pageshow',
   'popstate', 'progress', 'ratechange', 'reset', 'resize', 'scroll', 'seeked',
   'seeking', 'select', 'show', 'stalled', 'storage', 'submit', 'suspend',
   'timeupdate', 'unload', 'volumechange', 'waiting']

  @get
    location: -> @_location
    parent: -> @_context.parent?.window or @window
    top: -> if @parent != @window then @parent.top else @window
    length: -> @_context.childContexts.length
    frameElement: -> @_context.frameElement or null

  @define
    name:
      get: -> @_context.name or ''
      set: (name) -> @_context.name = name

  @set location: (url) ->
    @location.assign url

  setTimeout: (fn, ms) ->
    if typeof fn == 'string'
      code = fn
      fn = =>
        try
          @run code
        catch e
    else
      fn = =>
        try
          fn.bind(@)()
        catch e

    startTimer @, setTimeout, clearTimeout, fn, ms

  setInterval: (fn, ms) ->
    if typeof fn == 'string'
      code = fn
      fn = =>
        try
          @run code
        catch e
    else
      fn = =>
        try
          fn()
        catch e
    startTimer @, setInterval, clearInterval, fn, ms

  clearTimeout: (id) ->
    stopTimer @, id

  clearInterval: (id) ->
    stopTimer @, id

  screen:
    width: 0
    height: 0

  Image: (width, height) =>
    el = @document.createElement 'img'
    el.width = width if width?
    el.height = height if height?
    el

  Option: (text, value, defaultSelected, selected) ->
    el = @document.createElement 'option'
    el.text = text
    el.value = value
    if selected
      el.selected = defaultSelected
    el

  Audio: (src = '') =>
    el = @document.createElement 'audio'
    el.src = src
    el

  innerWidth: 0
  innerHeight: 0

  outerWidth: 0
  outerHeight: 0

  pageXOffset: 0
  pageYOffset: 0

  screenX: 0
  screenY: 0
  screenLeft: 0
  screenTop: 0

  scrollX: 0
  scrollY: 0

  scrollTop: 0

  scrollLeft: 0

  resizeBy: ->

  resizeTo: ->

  scroll: ->

  scrollBy: ->

  scrollTo: ->

  btoa: (s) ->
    (new Buffer s).toString 'base64'

  atob: (b) ->
    (new Buffer b, 'base64').toString()

  destroy: ->
    stopAllTimers @

  _fetch: (url, cb) ->
    @_context.resourceManager.fetchResource {url}, (err, resp) ->
      body = resp?.body or null
      if resp? and resp.statusCode >= 400
        err = new DOMException NETWORK_ERR, "Failed to load resource"
      cb? err, body

  _setCookie: (c) ->
    @_context.resourceManager.setCookies @document.URL, c

  alert: (args...) ->
    # id = @_context.prompt 'alert', args...
    # continue until @_context.promptReplies[id]?
    # @_context.promptReplies[id]


  prompt: (args...) ->
    # id = @_context.prompt 'prompt', args...
    # continue until @_context.promptReplies[id]?
    # @_context.promptReplies[id]

  confirm: ->
    # id = @_context.prompt 'open', args...
    # continue until @_context.promptReplies[id]?
    # @_context.promptReplies[id]

  showModalDialog: (args...) ->
    # @_context.prompt 'showModalDialog', args...
    # continue until @_context.promptReplies[id]?
    # @_context.promptReplies[id]

  print: ->
    @_context.print()

  close: ->
    @destroy()
    @_context.close()

module.exports = {Window}




extend Window::, dom

for k in {Object, Function, Array, String, Boolean, Number, Math, Date, RegExp, JSON, Error, EvalError, RangeError, ReferenceError, SyntaxError, TypeError, URIError, ArrayBuffer, Int8Array, Uint8Array, Uint8ClampedArray, Int16Array, Uint16Array, Int32Array, Uint32Array, Float32Array, Float64Array, DataView, encodeURI, encodeURIComponent, escape, unescape}
  Window::__defineGetter__ k, -> global[k]

createWindow = (context, document) ->
  window = new Window context.locationInterface, context.historyInterface, context.consoleInterface, document

  Object.defineProperty window, '_context',
    get: -> context
    enumerable: false

  refreshWindowIndices window
  window

refreshWindowIndices = (window) ->
  index = 0
  while window[index]
    delete window[index++]

  children = window._context.childContexts
  for child, index in children
    window[index] = child.window

module.exports = {createWindow, refreshWindowIndices}


