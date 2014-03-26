require './dom/meta'

{EventTarget} = require './dom/event'

applicationCacheDownloadProcess = (cache) ->

class ApplicationCache extends EventTarget
  @UNCACHED: 0
  @IDLE: 1
  @CHECKING: 2
  @DOWNLOADING: 3
  @UPDATEREADY: 4

  @readonly ['status']

  @events [
    'checking', 'error', 'noupdate', 'downloading',
    'progress', 'updateready', 'cached', 'obsolete'
  ]

  update: ->
  abort: ->
  swapCache: ->


