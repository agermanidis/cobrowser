{ELEMENT_NODE, PROCESSING_INSTRUCTION_NODE, DOCUMENT_TYPE_NODE, TEXT_NODE, DOCUMENT_NODE, DOCUMENT_FRAGMENT_NODE, COMMENT_NODE} = require './node'
{DOMException, WRONG_DOCUMENT_ERR, NOT_FOUND_ERR, NOT_SUPPORTED_ERR, INVALID_STATE_ERR, INVALID_NODE_TYPE_ERR, INDEX_SIZE_ERR} = require './exceptions'
{descendants, isAncestorOf, firstChild, follows, precedes, indexOf, rootOf, isInclusiveAncestorOf, ancestorsInclusive, followingNode, findFirst, findLast} = require './tree_operations'
{preInsert, clone, remove} = require './dom_operations'

BEFORE = -1
EQUAL = 0
AFTER = 1

bpCompare = (nodeA, offsetA, nodeB, offsetB) ->
  if nodeA == nodeB
    if offsetA > offsetB
      return AFTER
    else if offsetA == offsetB
      return EQUAL
    else return BEFORE

  if follows nodeA, nodeB
    result = bpCompare nodeB, offsetB, nodeA, offsetA
    if result == AFTER
      return BEFORE
    if result == BEFORE
      return AFTER

  if isAncestorOf nodeA, nodeB
    child = nodeB
    until child in nodeA.childNodes
      child = child.parentNode
    if indexOf(child) < offsetA
      return AFTER

  BEFORE

rootOfRange = (range) ->
  return null if range._detached
  rootOf range.startContainer

isContained = (node, range) ->
  rootOf(node) == rootOfRange(range) and bpCompare(node, 0, range.startContainer, range.startOffset) == AFTER and bpCompare(node, node.length, range.endContainer, range.endOffset) == BEFORE

xor = (a, b) -> !a and b or a and !b

isPartiallyContained = (node, range) ->
  xor isInclusiveAncestorOf(node, range.startContainer), isInclusiveAncestorOf(node, range.endContainer)

collapseRange = (range, toStart = false) ->
  if range._detached
    throw new DOMException INVALID_STATE_ERR, "Range is detached"

  if toStart
    range._endContainer = range._startContainer
    range._endOffset = range._startOffset
  else
    range._startContainer = range._endContainer
    range._startOffset = range._endOffset

class Range
  START_TO_START: 0
  START_TO_END: 1
  END_TO_END: 2
  END_TO_START: 3

  @readonly ['startContainer', 'startOffset', 'endContainer', 'endOffset', 'collapse']

  constructor: (@_startContainer, @_startOffset, @_endContainer, @_endOffset) ->

  @get
    startContainer: ->
      if @_detached
        throw new DOMException INVALID_STATE_ERR, "Range is detached"
      @_startContainer

    startOffset: ->
      if @_detached
        throw new DOMException INVALID_STATE_ERR, "Range is detached"
      @_startOffset

    endContainer: ->
      if @_detached
        throw new DOMException INVALID_STATE_ERR, "Range is detached"
      @_endContainer

    endOffset: ->
      if @_detached
        throw new DOMException INVALID_STATE_ERR, "Range is detached"
      @_endOffset

    collapsed: ->
      if @_detached
        throw new DOMException INVALID_STATE_ERR, "Range is detached"

      @_startContainer == @_endContainer and @_startOffset == @_endOffset

    commonAncestorContainer: ->
      if @_detached
        throw new DOMException INVALID_STATE_ERR, "Range is detached"

      container = @_startContainer
      endContainer = @_endContainer
      endContainerAncestors = ancestorsInclusive endContainer

      until container in endContainerAncestors
        container = container.parentNode

      container

  setStart: (node, offset) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    if node.nodeType == DOCUMENT_TYPE_NODE
      throw new DOMException INVALID_STATE_ERR, "Cannot set the start of the range on a document type node"

    if offset > node.length
      throw new DOMException INDEX_SIZE_ERR, "Offset specified is greater than the length of the node"

    if bpCompare(node, offset, @_endContainer, @_endOffset) == AFTER or rootOfRange(@) != rootOf(node)
      @_endContainer = node
      @_endOffset = offset

    @_startContainer = node
    @_startOffset = offset

  setEnd: (node, offset) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    if node.nodeType == DOCUMENT_TYPE_NODE
      throw new DOMException INVALID_STATE_ERR, "Cannot set the start of the range on a document type node"

    if offset > node.length
      throw new DOMException INDEX_SIZE_ERR, "Offset specified is greater than the length of the node"

    if bpCompare(node, offset, @_startContainer, @_startOffset) == BEFORE or rootOfRange(@) != rootOf(node)
      @_startContainer = node
      @_startOffset = offset


    @_endContainer = node
    @_endOffset = offset

  setStartBefore: (node) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    parent = node.parentNode

    unless parent
      throw new DOMException INVALID_NODE_TYPE_ERR

    @_startContainer = parent
    @_startOffset = indexOf node

  setStartAfter: (node) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    parent = node.parentNode

    unless parent
      throw new DOMException INVALID_NODE_TYPE_ERR

    @_startContainer = parent
    @_startOffset = 1 + indexOf node

  setEndBefore: (node) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    parent = node.parentNode

    unless parent
      throw new DOMException INVALID_NODE_TYPE_ERR

    @_endContainer = parent
    @_endOffset = indexOf node

  setEndAfter: (node) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    parent = node.parentNode

    unless parent
      throw new DOMException INVALID_NODE_TYPE_ERR

    @_endContainer = parent
    @_endOffset = 1 + indexOf node

  selectNode: (refNode) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    parent = refNode.parentNode
    unless parent
      throw new DOMException INVALID_NODE_TYPE_ERR, "Reference node has no parent"

    index = indexOf refNode
    @setStart parent, index
    @setEnd parent, index + 1

  selectNodeContents: (refNode) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    if refNode.nodeType == DOCUMENT_TYPE_NODE
      throw new DOMException INVALID_NODE_TYPE_ERR, "Reference node cannot be a document type"

    {length} = refNode
    @setStart refNode, 0
    @setEnd refNode, length

  compareBoundaryPoints: (how, sourceRange) ->
    if @_detached or sourceRange.detached
      throw new DOMException INVALID_STATE_ERR, "At least one of the ranges is detached"

    if rootOfRange(@) != rootOfRange(sourceRange)
      throw new DOMException WRONG_DOCUMENT_ERR, "Both ranges must have the same document"

    switch how
      when Range.START_TO_START
        container = @_startContainer
        offset = @_startOffset
        otherContainer = sourceRange.startContainer
        otherOffset = sourceRange.startOffset
      when Range.START_TO_END
        container = @_startContainer
        offset = @_startOffset
        otherContainer = sourceRange.endContainer
        otherOffset = sourceRange.endOffset
      when Range.END_TO_END
        container = @_endContainer
        offset = @_endOffset
        otherContainer = sourceRange.endContainer
        otherOffset = sourceRange.endOffset
      when Range.END_TO_START
        container = @_endContainer
        offset = @_endOffset
        otherContainer = sourceRange.startContainer
        otherOffset = sourceRange.startOffset
      else
        throw new DOMException NOT_SUPPORTED_ERR

    bpCompare container, offset, otherContainer, otherOffset

  deleteContents: ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is already detached"

    return if @_startContainer == @_endContainer and @_startOffset == @_endOffset

    if @_startContainer == @_endContainer and (@_startContainer.nodeType == TEXT_NODE or @_startContainer.nodeType == COMMENT_NODE)
      @_startContainer.replaceData @_startOffset, @_endOffset - @_startOffset, ''
      return

    nodesToRemove = []
    node = @_startContainer
    while node = followingNode(node)
      break if node == @_endContainer
      unless isContained node.parentNode, @
        nodesToRemove.push node

    if isInclusiveAncestorOf @_startContainer, @_endContainer
      newNode = @_startContainer
      newOffset = @_startOffset
    else
      reference = @_startContainer
      while reference.parentNode and !isInclusiveAncestorOf(reference, @_endContainer)
        reference = reference.parentNode
      newNode = reference.parentNode
      newOffset = 1 + indexOf reference

    if @_startContainer.nodeType == TEXT_NODE or @_startContainer.nodeType == COMMENT_NODE
      @_startContainer.replaceData @_startOffset, @_startContainer.length - @_startOffset, ''

    for node in nodesToRemove
      remove node, node.parentNode

    if @_endContainer.nodeType == TEXT_NODE or @_endContainer.nodeType == COMMENT_NODE
      @_endContainer.replaceData @_endOffset, @_endContainer.length - @_endOffset, ''

    @_startContainer = @_endContainer = newNode
    @_startOffset = @_endOffset = newOffset
    return

  extractContents: ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is already detached"

    frag = @_startContainer.ownerDocument.createDocumentFragment()
    return frag if @_startContainer == @_endContainer and @_startOffset == @_endOffset

    if @_startContainer == @_endContainer and (@_startContainer.nodeType == TEXT_NODE or @_startContainer.nodeType == COMMENT_NODE)
      copy = clone @_startContainer
      copy.data = @_startContainer.substringData @_startOffset, @_endOffset - @_startOffset
      @_startContainer.replaceData @_startOffset, @_startContainer.length - @_startOffset, ''
      frag.appendChild copy
      collapseRange @, true
      console.log @_startOffset, @_endOffset, @_startContainer.data
      return frag

    commonAncestor = @_startContainer
    while commonAncestor and !isInclusiveAncestorOf(commonAncestor, @_endContainer)
      commonAncestor = commonAncestor.parentNode

    if isInclusiveAncestorOf @_startContainer, @_endContainer
      firstPartiallyContainedChild = null
    else
      firstPartiallyContainedChild = findFirst @_startContainer, (node) ->
        isPartiallyContained node, @

    if isInclusiveAncestorOf @_endContainer, @_startContainer
      lastPartiallyContainedChild = null
    else
      lastPartiallyContainedChild = findLast @_startContainer, (node) ->
        isPartiallyContained node, @

    containedChildren = preorder(commonAncestor).filter (node) =>
      if isContained node, @
        if node.nodeType == DOCUMENT_TYPE_NODE
          throw new DOMException HIERARCHY_REQUEST_ERR
        return true
      false

    if firstPartiallyContainedChild.nodeType == TEXT_NODE or firstPartiallyContainedChild.nodeType == COMMENT_NODE
      copy = clone @_startContainer
      copy.data = @_startContainer.substringData @_startOffset, @_startContainer.length - @_startOffset
      firstPartiallyContainedChild.replaceData @_startOffset, @_startContainer.length - @_startOffset, ''
      frag.appendChild copy

    else if firstPartiallyContainedChild
      copy = clone @_startContainer
      frag.appendChild copy
      subrange = new Range @_startContainer, @_startOffset, firstPartiallyContainedChild, firstPartiallyContainedChild.length
      subfrag = subrange.cloneContents()
      for child in subfrag.childNodes
        append child, copy

    for child in containedChildren
      copy = clone child
      append clone, frag

    if lastPartiallyContainedChild.nodeType == TEXT_NODE or lastPartiallyContainedChild.nodeType == COMMENT_NODE
      copy = clone @_endContainer
      copy.data = @_endContainer.substringData @_endOffset, @_endContainer.length - @_endOffset
      lastPartiallyContainedChild.replaceData @_endContainer.substringData @_endOffset, @_endContainer.length - @_endOffset, ''
      frag.appendChild copy

    else if lastPartiallyContainedChild
      copy = clone @_endContainer
      frag.appendChild copy
      subrange = new Range @_endContainer, @_endOffset, lastPartiallyContainedChild, lastPartiallyContainedChild.length
      subfrag = subrange.cloneContents()
      for child in subfrag.childNodes
        append child, copy

    @_startContainer = @_endContainer = newNode
    @_startOffset = @_endOffset = newOffset
    frag

  cloneContents: -> @extractContents()

  insertNode: (node) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is already detached"

    if @_startContainer.nodeType == COMMENT_NODE or (@_startContainer.nodeType == TEXT_NODE and !@_startContainer.parentNode)
      throw new DOMException HIERARCHY_REQUEST_ERR

    if @_startContainer.nodeType == TEXT_NODE
      referenceNode = @_startContainer.splitText @_startOffset
    else
      referenceNode = @_startContainer.childNodes[@_startOffset] or null

    if referenceNode
      parent = referenceNode.parentNode
      newOffset = indexOf referenceNode
    else
      parent = @_startContainer
      newOffset = parent.length

    if node.nodeType == DOCUMENT_FRAGMENT_NODE
      newOffset += node.length
    else
      newOffset += 1

    preInsert node, parent, referenceNode

    if @_startContainer == @_endContainer and @_startOffset == @_endOffset
      @setEnd parent, newOffset

  surroundContents: (newParent) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is already detached"

    for descendant in descendants(@commonAncestorContainer) when descendant.nodeType != TEXT_NODE
      if isPartiallyContained descendant, @
        throw new DOMException INVALID_STATE_ERR

    if newParent.nodeType in [DOCUMENT_NODE, DOCUMENT_FRAGMENT_NODE, DOCUMENT_TYPE_NODE]
      throw new DOMException INVALID_NODE_TYPE_ERR

    fragment = @extractContents()

    while !!newParent.childNodes?.length
      remove firstChild(newParent), newParent

    @insertNode newParent
    console.log 'append'
    newParent.appendChild fragment
    console.log 'select'
    @selectNode newParent

  cloneRange: ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is already detached"

    new Range @_startContainer, @_startOffset, @_endContainer, @_endOffset

  detach: ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is already detached"

    @_detached = true

    doc = @_startContainer.ownerDocument
    if doc
      ranges = doc._ranges
      ranges.splice ranges.indexOf(@), 1

    return

  isPointInRange: (node, offset) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    if rootOfRange(@) != rootOf(node)
      throw new DOMException WRONG_DOCUMENT_ERR

    if node.nodeType == DOCUMENT_TYPE_NODE
      throw new DOMException INVALID_NODE_TYPE_ERR, "Node cannot be a document type"

    if offset > node.length
      throw new DOMException INDEX_SIZE_ERR

    beforeStart = bpCompare(node, offset, @_startContainer, @_startOffset) == BEFORE
    afterEnd = bpCompare(node, offset, @_endContainer, @_endOffset) == AFTER

    not (beforeStart or afterEnd)

  comparePoint: (node, offset) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    if rootOfRange(@) != rootOf(node)
      throw new DOMException WRONG_DOCUMENT_ERR

    if node.nodeType == DOCUMENT_TYPE_NODE
      throw new DOMException INVALID_NODE_TYPE_ERR, "Node cannot be a document type"

    if offset > node.length
      throw new DOMException INDEX_SIZE_ERR

    if bpCompare(node, offset, @_startContainer, @_startOffset) == BEFORE
      return -1

    if bpCompare(node, offset, @_endContainer, @_endOffset) == AFTER
      return 1

    0

  intersectsNode: (node) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    return false if rootOfRange(@) != rootOf(node)

    parent = node.parentNode
    unless parent
      throw new DOMException NOT_FOUND_ERR

    offset = indexOf node

    afterStart = bpCompare(parent, offset, @_startContainer, @_startOffset) == AFTER
    beforeEnd = bpCompare(parent, offset, @_endContainer, @_endOffset) == BEFORE
    afterStart and beforeEnd

  toString: ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    if @_startContainer == @_endContainer and @_startContainer.nodeType == TEXT_NODE
      return @_startContainer.substringData @_startOffset, @_endOffset

    s = ''

    if @_startContainer.nodeType == TEXT_NODE
      s += @_startContainer.substringData @_startOffset, @_startContainer.length - @_startOffset

    node = @_startContainer
    while (node = followingNode node) and node != @_endContainer
      if node.nodeType == TEXT_NODE and isContained node, @
        s += node.data

    if @_endContainer.nodeType == TEXT_NODE
      s += @_endContainer.substringData 0, @_endOffset

    s

  createContextualFragment: (fragment) ->
    if @_detached
      throw new DOMException INVALID_STATE_ERR, "Range is detached"

    element = switch @_startContainer.nodeType
      when DOCUMENT_NODE, DOCUMENT_FRAGMENT_NODE
        null
      when ELEMENT_NODE
        @_startContainer
      when TEXT_NODE, COMMENT_NODE
        @_startContainer.parentElement

    if !element or element.ownerDocument.localName == 'html'
      element = @_startContainer.ownerDocument.createElement 'body'

    # todo

  collapse: (toStart) ->
    collapseRange @, toStart


module.exports = {Range, bpCompare, BEFORE, EQUAL, AFTER}
