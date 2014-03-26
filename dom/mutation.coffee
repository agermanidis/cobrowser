require './meta'

{ancestors} = require './tree_operations'
{DOMException, SYNTAX_ERR} = require './exceptions'
{anyTrue, nonEmpty} = require './helpers'

queueAttributesRecord = (target, name, namespace, oldValue) ->
  record = new MutationRecord 'attributes', target, null, null, null, null, name, namespace
  recordWithOldValue = new MutationRecord 'attributes', target, null, null, null, null, name, namespace, oldValue

  for observer in target._observers
    {attributes, attributeFilter, attributeOldValue} = observer.options
    continue unless attributes
    continue if nonEmpty(attributeFilter) and (not name in attributeFilter)
    if attributeOldValue then observer._queue.push recordWithOldValue
    else observer._queue.push record

  for ancestor in ancestors target
    for observer in ancestor._observers
      {subtree, attributes, attributeFilter, attributeOldValue} = observer.options
      continue unless subtree
      continue unless attributes
      continue if nonEmpty(attributeFilter) and (not name in attributeFilter)
      if attributeOldValue then observer._queue.push recordWithOldValue
      else observer._queue.push record

queueCharacterDataRecord = (target, oldValue) ->
  record = new MutationRecord 'characterData', target,
  recordWithOldValue = new MutationRecord 'characterData', target, null, null, null, null, null, null, oldValue

  for observer in target._observers
    {characterData, characterDataOldValue} = observer.options
    continue unless characterData
    if characterDataOldValue then observer._queue.push recordWithOldValue
    else observer._queue.push record

  for ancestor in ancestors target
    for observer in ancestor._observers
      {subtree, characterData, characterDataOldValue} = observer.options
      continue unless subtree
      continue unless characterData
      if characterDataOldValue then observer._queue.push recordWithOldValue
      else observer._queue.push record

queueChildListRecord = (target, addedNodes, removedNodes, previousSibling, nextSibling) ->
  record = new MutationRecord 'childList', target, addedNodes, removedNodes, previousSibling, nextSibling

  for observer in target._observers
    {childList} = observer.options
    continue unless childList
    observer._queue.push record

  for ancestor in ancestors target
    for obsever in target._observers
      {subtree, childList} = observer.options
      continue unless subtree
      continue unless childList
      observer._queue.push record

observersIndex = (target, observer) ->
  for [targetObserver], index in target._observers
    return index if targetObserver == observer
  null

class MutationObserver
  constructor: (@_callback) ->
    @_queue = []
    @_nodes = []

  observe: (target, options) ->
    {childList, attributes, characterData, attributeOldValue, attributeFilter, characterDataOldValue} = options
    throw new DOMException SYNTAX_ERR unless any [childList, attributes, characterData]
    throw new DOMException SYNTAX_ERR if !attributes and attributeOldValue
    throw new DOMException SYNTAX_ERR if !attributes and nonEmpty attributeFilter
    throw new DOMException SYNTAX_ERR if !characterData and characterDataOldValue

    if index = observersIndex target, @
      target._observers[index][1] = options
    else
      target._observers.push [@, options]
      @_nodes.push target

  disconnect: ->
    for target in @_nodes
      if index = observersIndex target, @
        target._observers.splice index, 1

class MutationRecord
  @readonly ['type', 'target', 'addedNodes', 'removedNodes', 'previousSibling', 'nextSibling', 'attributeName', 'attributeNamespace', 'oldValue']
  constructor: (@_type, @_target, @_addedNodes = null, @_removedNodes = null, @_previousSibling = null, @_nextSibling = null, @_attributeName = null, @_attributeNamespace = null, @_oldValue = null) ->

module.exports = {MutationObserver, MutationRecord, queueAttributesRecord, queueCharacterDataRecord, queueChildListRecord}
