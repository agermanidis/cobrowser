require '../dom/meta'

URL = require 'url'

{HTMLElement} = require './element'

isBlockingScripts = (el) ->
  el._parser == el.ownerDocument?._parser and !el._stylesheetReady

obtainResource = (el) ->
  return unless el.href

  document = el.ownerDocument
  return unless document

  try
    url = URL.resolve document.URL, el.href
  catch e
    return

  document.defaultView._fetch url, (err, body) ->
    el._body = body if body

class HTMLLinkElement extends HTMLElement
  @reflect ['charset', 'rev', 'target', {bool: true, attr: 'disabled'}, 'href', 'rel', 'media', 'hreflang', 'type']
  @get relList: -> new DOMTokenList @rel, (newRel) -> @rel = newRel

class HTMLStyleElement extends HTMLElement
  @reflect [{attr: 'media', treatNullAs: 'all'}, 'type']
  @reflect bool: true, ['disabled', 'scoped']

class LinkStyle
  @get sheet: ->

#HTMLStyleElement extends LinkStyle
#HTMLLinkElement extends LinkStyle

module.exports = {HTMLStyleElement, HTMLLinkElement}
