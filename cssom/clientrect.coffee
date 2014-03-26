require '../dom/meta'

class ClientRect
  @readonly ['top', 'right', 'bottom', 'left']
  constructor: (@_top, @_right, @_bottom, @_left) ->
  @get
    width: -> @right - @left
    height: -> @bottom - @top

module.exports = {ClientRect}
