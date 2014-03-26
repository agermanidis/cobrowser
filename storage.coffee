require './dom/meta'

class Storage
  @get length: ->
    Object.keys(@_storage).length

  getItem: (key) ->
    @_storage[key]

  setItem: (key, value) ->
    @_storage[key] = value

  remoteItem: (key) ->
    delete @_storage[key]

  clear: ->
    @_storage = {}

  constructor: ->
    @clear()

module.exports = {Storage}

