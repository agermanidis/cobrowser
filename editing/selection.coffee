{Range, bpCompare, AFTER, BEFORE} = require '../dom/range'
{rootOf} = require '../dom/tree_operations'
{DOMException, INVALID_STATE_ERR} = require '../dom/exceptions'

BACKWARDS = -1
FORWARDS = 1

class Selection
  @get
    anchorNode: -> @_anchorNode or null
    anchorOffset: -> @_anchorOffset or 0
    focusNode: -> @_focusNode or null
    focusOffset: -> @_focusOffset or 0

    isCollapsed: ->
      @_anchorNode == @_focusNode and @_anchorOffset == @_focusOffset

  collapse: (node, offset) ->
    @_range = @_document.createRange node, offset, node, offset

  collapseToStart: ->
    unless @_range
      throw new DOMException INVALID_STATE_ERR

    @_range = @_document.createRange @_range.startContainer, @_range.startOffset, @_range.startContainer, @_range.startOffset

  collapseToEnd: ->
    unless @_range
      throw new DOMException INVALID_STATE_ERR

    @_range = @_document.createRange @_range.endContainer, @_range.endOffset, @_range.endContainer, @_range.endOffset

  extend: (node, offset) ->
    unless @_range
      throw new DOMException INVALID_STATE_ERR

    if rootOf(node) == rootOf(@_range.startContainer)
      startContainer = node
      startOffset = offset

    else if bpCompare(@_anchorNode, @_anchorOffset, node, offset) != AFTER
      startContainer = @_anchorNode
      startOffset = @_anchorOffset
      endContainer = node
      endOffset = offset

    else
      startContainer = node
      startOffset = offset
      endContainer = @_anchorNode
      endOffset = @_anchorOffset

    @_range = @_document.createRange startContainer, startOffset, endContainer, endOffset

    if bpCompare(node, offset, @_anchorNode, @_anchorOffset) == BEFORE
      @_direction = BACKWARDS
    else
      @_direction = FORWARDS

  selectAllChildren: (node) ->
    @_range = @_document.createRange node, 0, node, node.length
    @_direction = FORWARDS

  deleteFromDocument: ->
    @_range?.deleteContents()


  constructor: (@_document) ->
    @_range = null
    @_direction = FORWARDS

