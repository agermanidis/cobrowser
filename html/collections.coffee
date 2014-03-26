{HTMLCollection, NodeList, refreshCollection} = require '../dom/collections'
{preorder, isAncestorOf} = require '../dom/tree_operations'
{DOMException, HIERARCHY_REQUEST_ERR, NOT_FOUND_ERR} = require '../dom/exceptions'
{Node} = require '../dom/node'
{remove} = require '../dom/dom_operations'

refreshCollectionWithNames = (coll, obj) ->
  refreshCollection coll, obj

  prevNames = obj.names
  for name in prevNames
    delete obj[name]

  obj.names = {}

  for el in coll
    if name = el.name
      obj.__defineGetter__ 'name', ->
        obj.namedItem(name)

      obj.names[name] = true

    if id = el.id
      obj.__defineGetter__ 'id', ->
        obj.namedItem(id)

      obj.names[id] = true

class HTMLAllCollection extends HTMLCollection
  tags: (tagName) ->
    tagName = tagName.toUpperCase()
    ret = []
    @collection.filter (node) -> node.tagName == tagName

class HTMLFormControlsCollection extends HTMLCollection
  namedItem: (name) ->
    for el in @collection
      return el if el.name == name
    null

  constructor: (coll) ->
    refreshCollection coll, @

refreshOptionsCollection = (coll, obj) ->
  refreshCollection coll, obj

  for name, _ of obj.names
    delete obj[name]

  obj.names = {}

  for el in coll
    if name = el.name
      do (name) ->
        obj.__defineGetter__ name, ->
          obj.namedItem(name)

      obj.names[name] = true

    if id = el.id
      do (id) ->
        obj.__defineGetter__ id, ->
          obj.namedItem(id)

      obj.names[id] = true

class HTMLOptionsCollection extends HTMLCollection
  @define
    length:
      get: -> @collection.length
      set: (len) ->
        refreshOptionsCollection @collection[..len - 1], @

  namedItem: (name) ->
    els = @collection.filter (node) -> node.name == name or node.id == name
    switch els.length
      when 0 then null
      when 1 then els[0]
      else new NodeList els

  add: (element, before) ->
    if isAncestorOf element, @root
      throw new DOMException HIERARCHY_REQUEST_ERR

    if before and !isDescendantOf(element, @root)
      throw new DOMException NOT_FOUND_ERR

    return if element == before

    if before instanceof Node
      reference = before
    else if typeof before == 'number'
      reference = @collection[before]

    if reference
      parent = reference.parentNode
    else
      parent = @root

    parent.insertBefore element, reference
    refreshOptionsCollection @root._childNodes, @

  remove: (index) ->
    return if @length == 0
    return unless 0 <= index <= @length

    element = @collection[index]
    remove element, parent
    refreshOptionsCollection @root._childNodes, @

  @get selectedIndex: -> @root.selectedIndex

  constructor: (@root, coll) ->
    refreshOptionsCollection coll, @


class RadioNodeList extends NodeList
  @define
    value:
      get: ->
        for el in @collection
          if el.checked and value = el.value
            return value
        return ''

      set: (val) ->
        for el in @collection
          if el.value == val
            return el.checked = true

  namedItem: (name) ->
    elements = @collection.filter (node) -> node.name == name or node.id == name
    return null unless elements.length
    return elements[0] if elements.length == 1
    new RadioNodeList elements

  constructor: (coll) ->
    @names = {}
    refreshCollectionWithNames coll, @


module.exports = {HTMLFormControlsCollection, HTMLAllCollection, HTMLOptionsCollection, RadioNodeList, refreshOptionsCollection}
