{HTMLElement} = require './element'

class HTMLAreaElement extends HTMLElement
  @reflect ['alt', 'coords', 'shape', 'href',
            'target', 'rel', 'media', 'hreflang',
            'type', 'noHref']

  @get
    relList: -> new DOMTokenList @rel, (newRel) -> @rel = newRel

  @decompose
    properties: ['protocol', 'host', 'hostname', 'port', 'pathname', 'search', 'hash']
    get: ->
      URL.parse @href
    set: (key, value) ->
      urlObj[key] = value
      @href = URL.format urlObj

module.exports = {HTMLAreaElement}
