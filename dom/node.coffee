require './meta'

{extend, mapcat, equalProperties} = require './helpers'

ELEMENT_NODE = 1
ATTRIBUTE_NODE = 2
TEXT_NODE = 3
CDATA_SECTION_NODE = 4
ENTITY_REFERENCE_NODE = 5
ENTITY_NODE = 6
PROCESSING_INSTRUCTION_NODE = 7
COMMENT_NODE = 8
DOCUMENT_NODE = 9
DOCUMENT_TYPE_NODE = 10
DOCUMENT_FRAGMENT_NODE = 11
NOTATION_NODE = 12

DOCUMENT_POSITION_DISCONNECTED = 0x01
DOCUMENT_POSITION_PRECEDING = 0x02
DOCUMENT_POSITION_FOLLOWING = 0x04
DOCUMENT_POSITION_CONTAINS = 0x08
DOCUMENT_POSITION_CONTAINED_BY = 0x10
DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20

extend module.exports, {ELEMENT_NODE, ATTRIBUTE_NODE, TEXT_NODE, CDATA_SECTION_NODE, ENTITY_REFERENCE_NODE, ENTITY_NODE, PROCESSING_INSTRUCTION_NODE, COMMENT_NODE, DOCUMENT_NODE, DOCUMENT_TYPE_NODE, DOCUMENT_FRAGMENT_NODE, NOTATION_NODE, DOCUMENT_POSITION_DISCONNECTED, DOCUMENT_POSITION_PRECEDING, DOCUMENT_POSITION_FOLLOWING, DOCUMENT_POSITION_CONTAINS, DOCUMENT_POSITION_CONTAINED_BY, DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC}

{DOMException, HIERARCHY_REQUEST_ERR, NOT_FOUND_ERR} = require './exceptions'
{ancestor, descendants, firstChild, lastChild, nextSibling, previousSibling, rootOf, indexOf, isAncestorOf, isDescendantOf, isInclusiveDescendantOf, isInclusiveAncestorOf, followingNode, follows, precedes, preorder} = require './tree_operations'
{NodeList} = require './collections'
{EventTarget} = require './event'
{locateNamespace, locateNamespacePrefix, contiguousTextNodes, isFollowedByNodeWithType, isPrecededByNodeWithType, childrenWithType, hasChildWithNodeType} = require './dom_helpers'
{remove, adopt, preInsert, insert, append, preRemove, replaceAll, replace, clone} = require './dom_operations'

class Node extends EventTarget
  @readonly ['baseURI', 'ownerDocument', 'parentNode']

  constructor: ->
    @_childNodes = []
    @_parentNode = null
    @_ownerDocument = null
    @_observers = []
    #@_baseURI = @_ownerDocument.baseURI

  @get
    length: -> @_childNodes.length
    firstChild: -> firstChild @
    lastChild: -> lastChild @
    previousSibling: -> previousSibling @
    nextSibling: -> nextSibling @
    childNodes: -> new NodeList @_childNodes
    parentElement: ->
      if @_parentNode?.nodeType == @ELEMENT_NODE then @_parentNode else null
    nodeName: ->
      switch @nodeType
        when Node.ELEMENT_NODE
          @tagName
        when Node.TEXT_NODE
          "#text"
        when Node.PROCESSING_INSTRUCTION_NODE
          @target
        when Node.COMMENT_NODE
          "#comment"
        when Node.DOCUMENT_TYPE_NODE
          @name
        when Node.DOCUMENT_TYPE_NODE
          "#document"
        when Node.DOCUMENT_FRAGMENT_NODE
          "#document-fragment"
    ownerDocument: ->
      return null if @nodeType == @DOCUMENT_NODE
      @_ownerDocument
    nodeValue: ->
      switch @nodeType
        when Node.TEXT_NODE, Node.COMMENT_NODE, Node.PROCESSING_INSTRUCTION_NODE
          @data
        else
          null
    textContent: ->
      switch @nodeType
        when Node.ELEMENT_NODE, Node.DOCUMENT_FRAGMENT_NODE
          textNodes = preorder(@).filter (node) -> node.nodeType == Node.TEXT_NODE
          ret = ''
          for textNode in textNodes
            ret += textNode.data
          ret
        when Node.TEXT_NODE, Node.COMMENT_NODE, Node.PROCESSING_INSTRUCTION_NODE
          @data
        else
          null
    innerText: -> @textContent

  @set
    nodeValue: (v) ->
      switch @nodeType
        when Node.TEXT_NODE, Node.COMMENT_NODE, Node.PROCESSING_INSTRUCTION_NODE
          @replaceData 0, @length, v
        else
          null

    textContent: (s) ->
      s = '' unless s
      s = s.toString()
      switch @nodeType
        when Node.ELEMENT_NODE, Node.DOCUMENT_FRAGMENT_NODE
          node = null
          if s.length > 0
            node = new Text s
          replaceAll node, @
        when Node.TEXT_NODE, Node.PROCESSING_INSTRUCTION_NODE, Node.COMMENT_NODE
          @replaceData 0, @length, s

  compareDocumentPosition: (other) ->
    reference = @

    if other == reference
      return 0
    if rootOf(other) != rootOf(reference)
      return DOCUMENT_POSITION_DISCONNECTED
    if isAncestorOf other, reference
      return DOCUMENT_POSITION_CONTAINS | DOCUMENT_POSITION_PRECEDING
    if isDescendantOf other, reference
      return DOCUMENT_POSITION_CONTAINED_BY | DOCUMENT_POSITION_FOLLOWING
    if precedes other, reference
      return DOCUMENT_POSITION_PRECEDING

    DOCUMENT_POSITION_FOLLOWING

  contains: (other) ->
    isInclusiveDescendantOf other, @

  hasChildNodes: -> !!@_childNodes.length

  insertBefore: (node, child) ->
    preInsert node, @, child

  appendChild: (node) ->
    append node, @

  replaceChild: (node, child) ->
    replace child, node, @

  removeChild: (node) ->
    remove node, @

  cloneNode: (cloneChildren = true) ->
    clone @, @_ownerDocument, cloneChildren

  isEqualNode: (node) ->
    return false unless node
    return false if @nodeType != node.nodeType

    switch node.nodeType
      when Node.DOCUMENT_TYPE_NODE
        return false unless equalProperties @, node, 'name', 'publicID', 'systemID'
      when Node.ELEMENT_NODE
        return false unless equalProperties @, node, 'namespaceURI', 'prefix', 'localName'
        attrList = @_attributes
        return false unless attrList.length == node._attributes.length
        for attr, index in attrList
          return false unless equalProperties node._attributes[index], attr, 'namespaceURI', 'localName', 'value'
      when Node.PROCESSING_INSTRUCTION_NODE
        return false unless equalProperties @, node, 'target', 'data'
      when Node.TEXT_NODE, Node.COMMENT_NODE
        return false unless equalProperties @data == node.data

    children = node._childNodes
    return false unless children.length == @_childNodes.length
    for child, index in @_childNodes
      return false unless child.isEqualNode children[index]
    true

  normalize: ->
    ret = ''
    length = 0

    for node in preorder(@).filter( (node) -> node.nodeType == Node.TEXT_NODE )
      length = node.length

      data = mapcat contiguousTextNodes(node), (textNode) -> textNode.data

      node.replaceData 0, length, data

      sibling = nextSibling node
      if doc = @ownerDocument
        while sibling = nextSibling sibling and sibling.nodeType == Node.TEXT_NODE
          for range in doc._ranges
            if range.startContainer == sibling
              range._startOffset += length
              range._startContainer = node
            if range.endContainer == sibling
              range._endOffset += length
              range._endContainer = node

          length += sibling.length

      for textNode in contiguousTextNodes(node) when textNode != node
        remove textNode, textNode.parentNode

  lookupPrefix: (namespace) ->
    return null if !namespace or namespace.length == 0

    switch @nodeType
      when Node.ELEMENT_NODE
        locateNamespacePrefix @, namespace

      when Node.DOCUMENT_NODE
        unless documentElement = @documentElement
          return null

        locateNamespacePrefix documentElement, namespace

      when Node.DOCUMENT_TYPE_NODE, Node.DOCUMENT_FRAGMENT_NODE
        return null

      else
        unless parentElement = @parentElement
          return null

        locateNamespacePrefix parentElement, namespace

  lookupNamespaceURI: (prefix) ->
    prefix = null if prefix == ''
    locateNamespace @, prefix

  isDefaultNamespace: (namespace) ->
    namespace = null if namespace == ''
    namespace == locateNamespace @, null

extend Node, {ELEMENT_NODE, ATTRIBUTE_NODE, TEXT_NODE, CDATA_SECTION_NODE, ENTITY_REFERENCE_NODE, ENTITY_NODE, PROCESSING_INSTRUCTION_NODE, COMMENT_NODE, DOCUMENT_NODE, DOCUMENT_TYPE_NODE, DOCUMENT_FRAGMENT_NODE, NOTATION_NODE, DOCUMENT_POSITION_DISCONNECTED, DOCUMENT_POSITION_PRECEDING, DOCUMENT_POSITION_FOLLOWING, DOCUMENT_POSITION_CONTAINS, DOCUMENT_POSITION_CONTAINED_BY, DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC}

class DocumentFragment extends Node
  nodeType: Node.DOCUMENT_FRAGMENT_NODE

extend module.exports, {Node, DocumentFragment}

{Text} = require './character_data'

