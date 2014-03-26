require './meta'

refreshCollection = (coll, obj) ->
  obj.collection = coll
  for member, index in coll
    obj[index] = member
  index = coll.length
  while obj[index]
    delete obj[index++]


class StyleSheetList
  item: (index) ->
    @collection[index] or null

  @get length: -> @collection.length

  constructor: (coll = []) ->
    refreshCollection coll, @

class NodeList
  item: (index) ->
    @collection[index] or null

  @get length: -> @collection.length

  constructor: (coll = []) ->
    #console.log 'constructing nodelist w/ ', coll.length
    refreshCollection coll, @

class DOMStringList
  @get length: -> @collection.length

  item: (index) ->
    @collection[index] or null

  contains: (string) ->
    string in @collection

  constructor: (coll = []) ->
    # coll.on 'changed', =>
    #   refreshCollection coll, @

    refreshCollection coll, @

class HTMLCollection
  @namedElementRE: /a|applet|area|embed|form|frame|frameset|iframe|img|object/

  @get length: -> @collection.length

  item: (index) ->
    @collection[index] or null

  namedItem: (name) ->
    for el in @collection
      if (@namedElementRE.test(el.name) and el.name == name) or (el.id == name)
        return el
    null

  constructor: (coll = []) ->
    # coll.on 'changed', =>
    #   refreshCollection coll, @

    refreshCollection coll, @

class DOMTokenList
  constructor: (@string, @setter = ->) ->
    if !@string then @string = ''

  @get
    value: -> @string.replace(/^\s+/, '').replace(/\s+$/, '').replace(/\s+/, ' ')
    length: -> if @value.length == 0 then 0 else @value.split(/\s+/).length

  item: (index) ->
    @value.split(/\s+/)[index] or null

  contains: (token) ->
    token in @value.split /\s+/

  add: (token) ->
    unless @contains token
      if @length > 0
        @string += " "
      @string += token
    @setter @value

  remove: (token) ->
    @string = @string.replace token, ''
    @setter @value

  toggle: (token) ->
    if @contains token
      @remove token
      false
    else
      @add token
      true

  toString: ->
    @string

class DOMSettableTokenList extends DOMTokenList
  @set value: (s) ->
    @string = s
    @setter @value

class NamedNodeMap
  @get length: -> @collection.length

  item: (index) ->
    @collection[index] or null

  getNamedItem: (nameToMatch) ->
    for {name}, index in @collection
      return @collection[index] if name == nameToMatch
    null

  getNamedItemNS: (nameToMatch) ->
    for {name, namespaceURI}, index in @collection
      if name == nameToMatch and namespaceURI == namespaceToMatch
        return @collection[index]
    null

  setNamedItem: (item) ->
    # TODO

  setNamedItemNS: (item) ->
    # TODO

  removeNamedItem: (nameToMatch) ->
    for {name}, index in @collection
      if name == nameToMatch
        return @collection.splice index, 1

  removeNamedItemNS: (nameToMatch, namespaceToMatch) ->
    for {name, namespaceURI}, index in @collection
      if name == nameToMatch and namespaceURI == namespaceToMatch
        return @collection.splice index, 1

  constructor: (coll = [], @el) ->
    refreshCollection coll, @

    for {_name, value} in coll
      @[_name] = value

module.exports = {NodeList, HTMLCollection, DOMStringList, DOMTokenList, DOMSettableTokenList, StyleSheetList, NamedNodeMap, refreshCollection}
