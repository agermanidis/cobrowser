require './meta'

{Node, ELEMENT_NODE} = require './node'

createAttribute = (name, namespace, prefix, localName, value) ->
  return new Attr name, namespace, prefix, localName, value

attrChanged = (node, attrChange, attrNode, attrName, prevValue, newValue) ->
  if attrName == 'id' and doc = node._ownerDocument
    delete doc._idCache[prevValue] if prevValue
    doc._idCache[newValue] = node

  if attrName == 'name' and doc = node._ownerDocument
    if prevValue
      existing = doc[prevValue]

      if existing instanceof HTMLCollection
        coll = existing.collection
        index = coll.indexOf node
        if index != -1
          coll.splice index, 1
        refreshCollection coll, existing

      else if (existing instanceof Node) or existing?.window?
        delete doc[prevValue] if prevValue

    existing = doc[newValue]
    referenced = if node.tagName == 'IFRAME' then node.contentWindow else node

    if existing instanceof HTMLCollection
      coll = existing.collection
      coll.push referenced
      refreshCollection coll, existing

    else if (existing instanceof Node) or existing?.window?
      doc[newValue] = new HTMLCollection [existing, referenced]

    else unless typeof existing == 'function'
      doc[newValue] = referenced

  # if /(name|id)/.test(attrName) and form = node.form
  #   if prevValue
  #     existing = form[prevValue]

  #     if existing instanceof RadioNodeList
  #       coll = existing.collection
  #       index = coll.indexOf node
  #       if index != -1
  #         coll.splice index, 1
  #       refreshCollectionWithNames coll, existing

  #     else if (existing instanceof Node) or existing?.window?
  #       delete form[prevValue] if prevValue

  #   existing = form[newValue]
  #   referenced = node

  #   if existing instanceof RadioNodeList
  #     coll = existing.collection
  #     coll.push referenced
  #     refreshCollectionWithNames coll, existing

  #   else if (existing instanceof Node) or existing?.window?
  #     form[newValue] = new RadioNodeList [existing, referenced]

  #   else if typeof existing != 'function'
  #     form[newValue] = referenced

  if doc = node.ownerDocument
    evt = doc.createEvent 'MutationEvent'
    evt.initMutationEvent 'DOMAttrModified', true, false, attrNode, prevValue, newValue, attrName, attrChange
    node.dispatchEvent evt

class Element extends Node
  nodeType: ELEMENT_NODE

  @readonly ['localName', 'namespaceURI', 'prefix']

  @set
    className: (newValue) -> @setAttributeNS null, "class", newValue
    id: (newValue) -> @setAttributeNS null, "id", newValue

  @get
    tagName: ->
      qualifiedName = if @_prefix then "#{@_prefix}:#{@_localName}" else @_localName
      qualifiedName.toUpperCase()

    nodeName: -> @tagName
    id: -> @getAttributeNS(null, 'id') or ''
    className: -> @getAttributeNS(null, 'class') or ''
    classList: -> new DOMTokenList @className, (newValue) => @className = newValue
    attributes: -> new NamedNodeMap @_attributes

    children: ->
      new HTMLCollection filterWhere @_childNodes, 'nodeType', ELEMENT_NODE

    childElementCount: ->
      @children.length

    firstElementChild: ->
      @children[0] or null

    lastElementChild: ->
      children = @children
      children[children.length - 1] or null

    previousElementChild: ->
      sibling = @
      while sibling = sibling.previousSibling
        if sibling.nodeType == Node.ELEMENT_NODE
          return sibling
      sibling

    nextElementChild: ->
      sibling = @
      while sibling = sibling.nextSibling
        if sibling.nodeType == Node.ELEMENT_NODE
          return sibling
      sibling

  constructor: (@_localName, @_namespaceURI = null, @_prefix = null) ->
    @_attributes = []
    super

  getAttribute: (attrName) ->
    attrName = attrName.toLowerCase()
    for {name, value} in @_attributes
      return value if attrName == name
    null

  getAttributeNS: (attrNamespace, attrLocalName) ->
    attrNamespace = null if typeof attrNamespace == 'string' and attrNamespace.length == 0
    for {namespaceURI, localName, value} in @_attributes
      if namespaceURI == attrNamespace and localName == attrLocalName
        return value
    null

  getAttributeNode: (attrName) ->
    attrName = attrName.toLowerCase()
    for attr in @_attributes
      return attr if attr.name == attrName
    null

  setAttributeNode: ({name, value}) ->
    @setAttribute name, value

  removeAttributeNode: (attr) ->
    index = @_attributes.indexOf attr
    if index != -1
      @_attributes.splice index, 1
    attr

  setAttribute: (attrName, attrValue) ->
    #console.log 'setting attr', {attrName, attrValue}, @_attributes, @nodeName
    console.log 'setting attr', {attrName, attrValue}

    #console.log attrValue
    #if typeof attrValue != 'string' then throw new Error

    match = null
    for attr in @_attributes
      if attr.name == attrName
        match = attr
        break

    prev = null

    unless match
      newAttr = createAttribute attrName, null, null, null, attrValue
      attrChanged @, MutationEvent.ADDITION, newAttr, attrName, null, attrValue
      @_attributes.push newAttr
    else
      prev = match.value
      attrChanged @, MutationEvent.MODIFICATION, match, attrName, prev, attrValue
      match.value = attrValue

    if attrName.indexOf('on') == 0 and @[attrName] != undefined
      if attrName == 'onerror'
        body = "(function(event, source, lineno, column) { #{attrValue} })()"
      else
        body = "(function(event) { #{attrValue} })()"

      @[attrName] = ->
        try
          @ownerDocument.defaultView?.run body
        catch e
          return

  setAttributeNS: (attrNamespace, attrName, attrValue) ->
    if typeof attrNamespace == 'string' and attrNamespace.length == 0
      attrNamespace = null

    if attrName.indexOf(":") != -1
      [attrPrefix, attrLocalName] = attrName.split ':'
    else
      attrPrefix = null
      attrLocalName = attrName

    if attrPrefix and !attrNamespace
      throw new DOMException NAMESPACE_ERR

    match = null

    for attr in @_attributes
      {namespaceURI, localName} = attr
      if namespaceURI == attrNamespace and localName == attrLocalName
        match = attr
        break

    unless match
      newAttr = createAttribute attrName, attrNamespace, attrPrefix, attrLocalName, attrValue
      attrChanged @, MutationEvent.ADDITION, newAttr, attrName, null, attrValue
      @_attributes.push newAttr
      return

    #Queue an "attributes" record with target context object, name name, namespace namespace, and oldValue attribute's value.

    attrChanged @, MutationEvent.MODIFICATION, match, attrName, match.value, attrValue

    match.value = attrValue

  removeAttribute: (attrName) ->
    attrName = attrName.toLowerCase()
    for attr, index in @_attributes
      if attrName == attr.name
        @_attributes.splice index, 1
        attrChanged @, MutationEvent.REMOVAL, attr, attrName, attr.value, null

  removeAttributeNS: (attrNamespace, attrLocalName) ->
    if typeof attrNamespace == 'string' and attrNamespace.length == 0
      attrNamespace = null
    for attr, index in @_attributes
      {namespaceURI, localName} = attr
      if attrNamespace == namespaceURI and attrLocalName == localName
        @_attributes.splice index, 1
        attrChanged @, MutationEvent.REMOVAL, attr, attrName, attr.value, null

  hasAttribute: (attrName) ->
    for {name} in @_attributes
      return true if name == attrName
    false

  hasAttributeNS: (attrNamespace, attrLocalName) ->
    attrNamespace = null if typeof attrNamespace == 'string' and attrNamespace.length == 0
    for {namespaceURI, localName} in @_attributes
      return true if attrNamespace == namespaceURI and attrLocalName == localName
    false

  getElementsByTagName: (localName) ->
    listElements localName, @

  getElementsByTagNameNS: (namespace, localName) ->
    listElementsNS namespace, localName, @

  getElementsByClassName: (classNames) ->
    listElementsByClass classNames, @

  querySelector: (sel) ->
    @_ownerDocument._nwmatcher.first sel, @

  querySelectorAll: (sel) ->
    new HTMLCollection @_ownerDocument._nwmatcher.select sel, @

  matchesSelector: (sel) ->
    @_ownerDocument._nwmatcher.match @, sel

class Attr
  @readonly ['name', 'namespaceURI', 'prefix', 'localName']
  constructor: (@_name, @_namespaceURI, @_prefix, @_localName, @value) ->
  @get
    nodeName: -> @_name
    nodeValue: -> @value

module.exports = {Element, Attr}

{DOMException, NAMESPACE_ERR} = require './exceptions'
{MutationEvent} = require './event'
{DOMTokenList, HTMLCollection, NamedNodeMap, refreshCollection} = require './collections'
{RadioNodeList, refreshCollectionWithNames} = require '../html/collections'
{listElements, listElementsNS, listElementsByClass} = require './dom_helpers'
{filterWhere} = require './helpers'
{Window} = require './window'
