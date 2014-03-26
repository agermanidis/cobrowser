require './meta'

{DOMException, NOT_SUPPORTED_ERR, INVALID_STATE_ERR} = require './exceptions'
{firstChild, lastChild, nextSibling, previousSibling, followingNode, precedingNode, hasChildren, follows, precedes, isInclusiveDescendantOf, isAncestorOf} = require './tree_operations'

NodeFilter =
  FILTER_ACCEPT: 1
  FILTER_REJECT: 2
  FILTER_SKIP: 3

  SHOW_ALL: 0xFFFFFFFF
  SHOW_ELEMENT: 0x1
  SHOW_ATTRIBUTE: 0x2
  SHOW_TEXT: 0x4
  SHOW_CDATA_SECTION: 0x8
  SHOW_ENTITY_REFERENCE: 0x10
  SHOW_ENTITY: 0x20
  SHOW_PROCESSING_INSTRUCTION: 0x40
  SHOW_COMMENT: 0x80
  SHOW_DOCUMENT: 0x100
  SHOW_DOCUMENT_TYPE: 0x200
  SHOW_DOCUMENT_FRAGMENT: 0x400
  SHOW_NOTATION: 0x800

nthBit = (num, n) ->
  (num >> n-1) & 1

filter = (iterator, node) ->
  if iterator._active then throw new DOMException INVALID_STATE_ERR, "Filter is already active"

  n = node.nodeType - 1

  return NodeFilter.FILTER_SKIP if !nthBit(iterator._whatToShow, n)
  return NodeFilter.FILTER_ACCEPT unless iteratorFilter = iterator._filter

  iterator._active = true
  result = iteratorFilter node
  iterator._active = false

  #If an exception was thrown, re-throw the exception, terminate these steps, and terminate the steps of the algorithm that invoked this algorithm.

  result

class NodeIterator
  @readonly ['root', 'referenceNode', 'pointerBeforeReferenceNode', 'whatToShow', 'filter']

  constructor: (@_root, @_whatToShow = NodeFilter.SHOW_ALL, @_filter = null) ->
    throw new DOMException NOT_SUPPORTED_ERR unless @_root
    @_detached = false
    @_pointerBeforeReferenceNode = true
    @_active = false
    @_referenceNode = @_root

  nextNode: ->
    throw new DOMException INVALID_STATE_ERR, "Iterator is detached" if @_detached

    node = @_referenceNode
    beforeNode = @_pointerBeforeReferenceNode
    result = null

    until result == NodeFilter.FILTER_ACCEPT
      if beforeNode
        beforeNode = false
      else
        node = followingNode node, @_root
        #node = @_all[++@_index]
        return null unless node

      result = filter @, node
      throw new DOMException INVALID_STATE_ERR, "Iterator is detached" if @_detached

    @_referenceNode = node
    @_pointerBeforeReferenceNode = beforeNode

    node

  previousNode: ->
    throw new DOMException INVALID_STATE_ERR, "Iterator is detached" if @_detached

    node = @_referenceNode
    beforeNode = @_pointerBeforeReferenceNode
    result = null

    until result == NodeFilter.FILTER_ACCEPT
      if beforeNode
        node = precedingNode node, @_root
        #node = @_all[--@_index]
        return null unless node
      else
        beforeNode = true

      result = filter @, node
      throw new DOMException INVALID_STATE_ERR, "Iterator is detached" if @_detached

    @_referenceNode = node
    @_pointerBeforeReferenceNode = beforeNode

    node

  detach: ->
    @_detached = true
    @_referenceNode = null

class TreeWalker
  @readonly ['root', 'whatToShow', 'filter', 'currentNode']

  constructor: (@_root, @_whatToShow = NodeFilter.SHOW_ALL, @_filter = null) ->
    throw new DOMException NOT_SUPPORTED_ERR unless @_root
    @_currentNode = @_root

  parentNode: ->
    node = @_currentNode
    root = @_root
    while node and node != root
      node = node.parentNode
      if node and filter(@, node) == NodeFilter.FILTER_ACCEPT
        return @_currentNode = node
    null

  firstChild: ->
    node = @_currentNode

    while node
      node = firstChild node
      return null unless node

      result = filter @, node

      if result == NodeFilter.FILTER_ACCEPT
        return @_currentNode = node

      else if result == NodeFilter.FILTER_SKIP and child = firstChild node
        node = child
        continue

      while node
        sibling = nextSibling node

        if sibling
          node = sibling
          break

        if parent = node.parentNode and parent != @_root and parent != current
          node = parent
        else
          return null

    node

  lastChild: ->
    node = @_currentNode

    while node
      node = lastChild node
      return null unless node

      result = filter @, node

      if result == NodeFilter.FILTER_ACCEPT
        return @_currentNode = node

      else if result == NodeFilter.FILTER_SKIP and child = lastChild node
        node = child
        continue

      while node
        sibling = previousSibling node

        if sibling
          node = sibling
          break

        if parent = node.parentNode and parent != @_root and parent != current
          node = parent
        else
          return null

    node

  previousSibling: ->
    node = @_currentNode
    return null if node == @_root

    loop
      sibling = previousSibling node
      return null unless sibling

      while sibling
        node = sibling
        result = filter @, node

        if result == NodeFilter.FILTER_ACCEPT
          return @_currentNode = node

        sibling = lastChild node

        if !sibling or result == NodeFilter.FILTER_REJECT
          sibling = previousSibling node

        node = node.parentNode

        return null if !node or node == @_root
        return null if filter(@, node) == NodeFilter.FILTER_ACCEPT

  nextSibling: ->
    node = @_currentNode
    return null if node == @_root

    loop
      sibling = nextSibling node
      return null unless sibling

      while sibling
        node = sibling
        result = filter @, node

        if result == NodeFilter.FILTER_ACCEPT
          return @_currentNode = node

        sibling = firstChild node

        if !sibling or result == NodeFilter.FILTER_REJECT
          sibling = nextSibling node

        node = node.parentNode

        return null if !node or node == @_root
        return null if filter(@, node) == NodeFilter.FILTER_ACCEPT

  previousNode: ->
    # node = @_currentNode
    # root = @_root

    # while node != root
    #   sibling = previousSibling node

    #   while sibling
    #     node = sibling
    #     result = filter @, node

    #     while result != NodeFilter.FILTER_REJECT and !!node.childNodes.length
    #       node = lastChild node
    #       result = filter @, node

    #     return @_currentNode = node if result == NodeFilter.FILTER_ACCEPT
    #     return null if node == root or !node.parentNode

    #     node = node.parentNode
    #     return @_currentNode = node if filter(@, node) == NodeFilter.FILTER_ACCEPT

    node = @_currentNode

    loop
      node = precedingNode node
      break if !node or !isInclusiveDescendantOf(node, @_root)
      result = filter @, node
      return @_currentNode = node if filter(@, node) == NodeFilter.FILTER_ACCEPT

    node


  nextNode: ->
    node = @_currentNode
    # result = NodeFilter.FILTER_ACCEPT

    # while true
    #   while result != NodeFilter.FILTER_ACCEPT and child = firstChild node
    #     node = child
    #     result = filter @, node
    #     return @_currentNode = node if result == NodeFilter.FILTER_ACCEPT

    #   if follower = followingNode node
    #     node = follower
    #   else
    #     continue

    #   return @_currentNode = node if filter(@, node) == NodeFilter.FILTER_ACCEPT

    loop
      node = followingNode node
      break if !node or !isInclusiveDescendantOf(node, @_root)
      result = filter @, node
      return @_currentNode = node if filter(@, node) == NodeFilter.FILTER_ACCEPT

    node


module.exports = {NodeFilter, NodeIterator, TreeWalker}
