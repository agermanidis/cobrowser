{HTMLElement} = require './element'
{DOMTokenList} = require '../dom/collections'
{originFromURL} = require '../dom/helpers'
{getBrowsingContext} = require './html_helpers'

URL = require 'url'

allowedToNavigate = (A, B) ->
  originA = A.document.origin
  originB = B.document.origin

  return true if originA == originB

  # ...TODO
  return true

selectBrowsingContext = (target, window) ->
  current = window._context

  switch target
    when null, '', '_self'
      return current
    when '_parent'
      return window.parent._context
    when '_top'
      return window.top._context
    else
      if target != '_blank' and match = current.getContextByName(target) and allowedToNavigate current, match
        match
      else
        current.createBrowsingContext()

followHyperlink = (el) ->
  document = el.ownerDocument
  window = document?.defaultView
  return unless window

  href = el.getAttribute 'href'
  target = el.getAttribute 'target'

  try
    url = URL.resolve document.URL, href
  catch e
    url = href

  context = selectBrowsingContext target, window

  if context
    context.navigate url

downloadHyperlink = (el, userId) ->
  context = getBrowsingContext el
  href = el.getAttribute 'href'
  if href
    context.download href, userId

postActivationBehavior = (el, userId) ->
  download = el.getAttribute 'download'

  if download
    downloadHyperlink el, userId
  else
    followHyperlink el

class HTMLAnchorElement extends HTMLElement
  @reflect ['href', 'target', 'rel', 'media', 'hreflang', 'type', 'coords', 'charset', 'name', 'rev', 'shape']

  @get
    text: -> @textContent
    relList: -> new DOMTokenList @rel, (newRel) -> @rel = newRel

  @get
    protocol: -> URL.parse(@href).protocol
    host: -> URL.parse(@href).host
    hostname: -> URL.parse(@href).hostname
    port: -> URL.parse(@href).port
    pathname: -> URL.parse(@href).pathname
    search: -> URL.parse(@href).search
    hash: -> URL.parse(@href).hash

  @set
    protocol: (p) ->
      urlObj = URL.parse(@href)
      urlObj.protocol = p
      URL.format urlObj
    host: (h) ->
      urlObj = URL.parse(@href)
      urlObj.host = h
      URL.format urlObj
    hostname: (h) ->
      urlObj = URL.parse(@href)
      urlObj.hostname = h
      URL.format urlObj
    port: (p) ->
      urlObj = URL.parse(@href)
      urlObj.port = p
      URL.format urlObj
    pathname: (p) ->
      urlObj = URL.parse(@href)
      urlObj.pathname = p
      URL.format urlObj
    search: (s) ->
      urlObj = URL.parse(@href)
      urlObj.search = p
      URL.format urlObj
    hash: (h) ->
      urlObj = URL.parse(@href)
      urlObj.hash = h
      URL.format urlObj

  click: (userId = null) ->
    postActivationBehavior @, userId

module.exports = {HTMLAnchorElement}
