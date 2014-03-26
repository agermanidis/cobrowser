{EventTarget} = require '../dom/event'

class ApplicationCache extends EventTarget
  @UNCACHED: 0
  @IDLE: 1
  @CHECKING: 2
  @DOWNLOADING: 3
  @UPDATEREADY: 4
  @OBSOLETE: 5

  @get status: ->

  @events ['checking', 'error', 'noupdate',
           'downloading', 'progress', 'updateready',
           'cached', 'obsolete']

  update: ->
  abort: ->
  swapCache: ->

  constructor: (@_window) ->


