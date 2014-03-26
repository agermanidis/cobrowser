require './meta'

{CDATA_SECTION_NODE, TEXT_NODE, COMMENT_NODE, PROCESSING_INSTRUCTION_NODE, Node} = require './node'
{DOMException, INDEX_SIZE_ERR, NO_MODIFICATION_ALLOWED_ERR} = require './exceptions'
{runAsync} = require './helpers'

characterDataModified = (node, prevValue, newValue) ->
  if doc = node.ownerDocument
    evt = doc.createEvent 'MutationEvent'
    evt.initMutationEvent 'DOMCharacterDataModified', true, false, node.parentNode, '', '', '', 0
    node.dispatchEvent evt

class CharacterData extends Node
  nodeType: CDATA_SECTION_NODE

  @get length: -> @_data.length

  @define
    data:
      get: ->
        @_data
      set: (newValue) ->
        prevValue = @_data
        @_data = newValue
        characterDataModified @, prevValue, newValue

  constructor: (@_data = '') ->
    super

  substringData: (offset, count = 0) ->
    data = @_data
    length = data.length

    throw new DOMException INDEX_SIZE_ERR if offset > length

    if offset + count > length
      data.substring offset
    else
      data.substring offset, offset + count

  appendData: (data) ->
    @replaceData @length, 0, data

  insertData: (offset, data) ->
    @replaceData offset, 0, data

  deleteData: (offset, count) ->
    @replaceData offset, count, ''

  replaceData: (offset, count, data) ->
    currentData = @_data
    length = currentData.length

    throw new DOMException NO_MODIFICATION_ALLOWED_ERR if @_readonly
    throw new DOMException INDEX_SIZE_ERR if offset > length

    if offset + count > length
      count = length - offset

    # Queue a "characterData" record with target node and oldValue node's data.

    start = currentData.substring 0, offset
    newData = start + data
    deleteOffset = offset
    end = currentData.substring deleteOffset + count

    @data = newData + end

    if doc = @ownerDocument
      for range in doc._ranges
        if range.startContainer == @ and offset < range.startOffset <= offset + count
          range._startOffset = offset
        if range.endContainer == @ and offset < range.endOffset <= offset + count
          range._endOffset = offset
        if range.startContainer == @ and range.startOffset >= offset + count
          range._startOffset += data.length

    return

class Text extends CharacterData
  nodeType: TEXT_NODE

  splitText: (offset) ->
    length = @length

    unless 0 <= offset < length
      throw new DOMException INDEX_SIZE_ERR

    count = length - offset

    data = @substringData offset, count

    node = new Text data

    #node._ownerDocument = @_ownerDocument
    parent = @_parentNode

    if parent
      parent.insertBefore node, @nextSibling

      if doc = parent.ownerDocument
        for range in doc._ranges
          if range.startContainer == node and range.startOffset > offset
            range._startContainer = node
            range._startOffset -= offset
          if range.endContainer == node and range.endOffset > offset
            range._endContainer = node
            range._endOffset -= offset

    @replaceData offset, count, ''

    if parent and doc = parent.ownerDocument
      for range in doc._ranges
        if range.startContainer == node and range.startOffset > offset
          range._startContainer = node
          range._startOffset = offset
        if range.endContainer == node and range.endOffset > offset
          range._endContainer = node
          range._endOffset = offset

    node

  @get
    wholeText: ->
      wholeText = ''

      node = @previousSibling
      while node and node.nodeType == Node.TEXT_NODE
        wholeText = node.data + wholeText
        node = node.previousSibling

      node = @
      while node and node.nodeType == Node.TEXT_NODE
        wholeText += node.data
        node = node.nextSibling

      wholeText

class Comment extends Text
  nodeType: COMMENT_NODE

  constructor: (text) ->
    super text
    @_nodeName = "#comment"
    @_tagName = "#comment"

class ProcessingInstruction extends CharacterData
  nodeType: PROCESSING_INSTRUCTION_NODE
  @readonly ['target']
  constructor: (@_target, data) ->
    super data

module.exports = {CharacterData, Text, Comment, ProcessingInstruction}
