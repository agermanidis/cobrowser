require './meta'

refresh = (coll, interface) ->
  interface.collection = coll
  for member, index in coll
    interface[index] = member
  index = coll.length
  while interface[index]
    delete interface[index++]

class ClientRectList
  @get length: -> @collection.length
  item: (index) -> @collection[index]
  constructor: (coll = []) ->
    refresh coll, @

class ClientRect
  @readonly ['top', 'right', 'bottom', 'left', 'width', 'height']
  constructor: (@_top, @_right, @_bottom, @_left, @_width, @_height) ->

