require '../dom/meta'

{HTMLElement} = require './element'

BROKEN = -1
UNAVAILABLE = 0
PARTIALLY_AVAILABLE = 1
COMPLETELY_AVAILABLE = 2

isAvailable = (img) ->
  img._state == PARTIALLY_AVAILABLE or img._state == COMPLETELY_AVAILABLE

updateImageData = (img) ->
  img._state = UNAVAILABLE

class HTMLImageElement extends HTMLElement
  @reflect ['alt', 'src', 'crossOrigin', 'width', 'height', 'name', 'align', 'useMap', 'isMap', 'hspace', 'vspace', 'longDesc', {treatNullAs: '', attr: 'border'}]
  constructor: ->
    @_state = UNAVAILABLE
    super
  @get
    complete: ->
      !@src or @src == ''
    naturalWidth: ->
    naturalHeight: ->
    #src: ->
      #@getAttribute('src')

module.exports = {HTMLImageElement}
