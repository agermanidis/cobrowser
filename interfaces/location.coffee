URL = require 'url'

createLocationInterface = (history) ->
  loc =
    assign: (args...) ->
      history.assign args...
    replace: (args...) ->
      history.replace args...
    reload: (args...) ->
      history.reload args...

  loc.__defineGetter__ 'href', ->
    history.currentURL()

  loc.__defineSetter__ 'href', (href) ->
    history.assign href

  loc.__defineGetter__ 'protocol', ->
    history.currentURLObj()?.protocol or ""

  loc.__defineGetter__ 'host', ->
    history.currentURLObj()?.host or ""

  loc.__defineGetter__ 'hostname', ->
    history.currentURLObj()?.hostname or ""

  loc.__defineGetter__ 'port', ->
    history.currentURLObj()?.port or ""

  loc.__defineGetter__ 'pathname', ->
    history.currentURLObj()?.pathname or ""

  loc.__defineGetter__ 'search', ->
    history.currentURLObj()?.search or ""

  loc.__defineGetter__ 'hash', ->
    history.currentURLObj()?.hash or ""

  loc.__defineSetter__ 'protocol', (protocol) ->
    current = history.currentURL()
    newURL = URL.parse current
    newURL.protocol = protocol
    @assign URL.format(newURL)

  loc.__defineSetter__ 'host', (host) ->
    current = history.currentURL()
    newURL = URL.parse current
    newURL.host = host
    @assign URL.format(newURL)

  loc.__defineSetter__ 'hostname', (hostname) ->
    current = history.currentURL()
    newURL = URL.parse current
    newURL.hostname = hostname
    @assign URL.format(newURL)

  loc.__defineSetter__ 'port', (port) ->
    current = history.currentURL()
    newURL = URL.parse current
    newURL.port = port
    @assign URL.format(newURL)

  loc.__defineSetter__ 'pathname', (pathname) ->
    current = history.currentURL()
    newURL = URL.parse current
    newURL.pathname = pathname
    @assign URL.format(newURL)

  loc.__defineSetter__ 'search', (search) ->
    current = history.currentURL()
    newURL = URL.parse current
    newURL.search = search
    @assign URL.format(newURL)

  loc.__defineSetter__ 'hash', (hash) ->
    current = history.currentURL()
    newURL = URL.parse current
    newURL.hash = hash
    @assign URL.format(newURL)

  loc

module.exports = {createLocationInterface}
