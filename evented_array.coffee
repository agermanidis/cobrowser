{EventEmitter} = require 'events'
{inherits} = require 'util'

EventedArray = ->
  EventEmitter.call @
  @arr = []
  @

inherits EventedArray, EventEmitter

refresh = (ea) ->
  index = 0
  while ea[index]
    delete ea[index++]

  for item, index in ea.arr
    ea[index] = item

EventedArray::__defineGetter__ 'length', -> @arr.length

EventedArray::concat = (args...) ->
  @arr.concat args...

EventedArray::indexOf = (args...) ->
  @arr.concat args...

EventedArray::join = (args...) ->
  @arr.join args...

EventedArray::lastIndexOf = (args...) ->
  @arr.lastIndexOf args...

EventedArray::pop = (args...) ->
  ret = @arr.pop args...
  refresh @
  @emit 'changed', @arr
  ret

EventedArray::push = (args...) ->
  ret = @arr.push args...
  refresh @
  @emit 'changed', @arr
  ret

EventedArray::reverse = (args...) ->
  ret = @arr.reverse args...
  refresh @
  @emit 'changed', @arr
  ret

EventedArray::shift = (args...) ->
  ret = @arr.shift args...
  refresh @
  @emit 'changed', @arr
  ret

EventedArray::slice = (args...) ->
  @arr.slice args...

EventedArray::sort = (args...) ->
  ret = @arr.sort args...
  refresh @
  @emit 'changed', @arr
  ret

EventedArray::splice = (args...) ->
  ret = @arr.splice args...
  refresh @
  @emit 'changed', @arr
  ret

EventedArray::toString = (args...) ->
  @arr.toString args...

EventedArray::unshift = (args...) ->
  ret = @arr.unshift args...
  refresh @
  @emit 'changed', @arr
  ret

EventedArray::valueOf = (args...) ->
  @arr.valueOf args...

module.exports = {EventedArray}

