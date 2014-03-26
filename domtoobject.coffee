URL = require 'url'

{makeSet} = require './dom/helpers'

isEventHandlerProperty = (prop) ->
  prop.indexOf("on") == 0

tagsToConceal = makeSet [
  'SCRIPT'
  'NOSCRIPT'
  'OBJECT'
]

class DOMToObject
  constructor: (document) ->
    # console.log 'constructing domtoobject', document.URL
    # throw new Error

    @url = document.URL
    @nodes = {}
    @root = @add document.documentElement

  add: (node) ->
    #console.log "adding child", node.nodeName
    return unless node
    return if node._address and @nodes[node._address]

    nodeType = node.nodeType

    if nodeType == 1
      tag = node.tagName

      return if tagsToConceal[tag]

      address = node._address

      attributes = {}
      for {name, value} in node.attributes when !isEventHandlerProperty(name)
        continue if tag == 'IFRAME' and /src/.test name

        if /(src|href)/.test name
          attributes[name] = URL.resolve @url, value
        else
          attributes[name] = value

      @nodes[address] = [ 1, tag, attributes, [] ]

    else if nodeType == 3
      address = node._address
      @nodes[address] = [ 3, node.nodeValue ]

    parentAddress = node.parentNode?._address
    referenceAddress = node.nextSibling?._address
    parentChildren = @nodes[parentAddress]?[3]

    if parentAddress? and parentChildren?
      if referenceAddress and ( referenceIndex = parentChildren.indexOf(referenceAddress) ) != -1
        parentChildren.splice referenceIndex, 0, address
      else
        parentChildren.push address

    if children = node._childNodes
      for child in children
        #console.log "ADDING A CHILD", node.nodeName, child.nodeName
        @add child

    address

  remove: (node, parent) ->
    return if tagsToConceal[node.tagName]
    address = node._address
    parentAddress = parent?._address
    delete @nodes[address]
    if parentAddress
      parentChildren = @nodes[parentAddress][3]
      if index = parentChildren.indexOf address
        parentChildren.splice index, 1

  changeAttribute: (node, attrName, attrValue) ->
    return if tagsToConceal[node.tagName]
    address = node._address
    serializedNode = @nodes[address]
    try
      serializedNode[2][attrName] = attrValue
    catch e
      return

  serializeCompact: (node) ->
    nodeType = node.nodeType
    if nodeType == 1
      tag = node.tagName
      return if tagsToConceal[tag]

      address = node._address

      children = []
      for child in node._childNodes
        serialized = @serializeCompact child, @url
        children.push serialized if serialized

      attributes = {}
      for {name, value} in node.attributes when !isEventHandlerProperty(name)
        if tag == 'IFRAME' and /src/.test name
          #attributes.src =
          null

        else if /(src|href)/.test name
          attributes[name] = URL.resolve @url, value
        else
          attributes[name] = value

      [1, tag, address, attributes, children]

    else if nodeType == 3
      address = node.address
      [3, node.nodeValue, address]

module.exports = {DOMToObject}
