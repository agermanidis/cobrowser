{ATTRIBUTE_NODE, DOCUMENT_NODE, DOCUMENT_FRAGMENT_NODE, ELEMENT_NODE, DOCUMENT_TYPE_NODE, PROCESSING_INSTRUCTION_NODE, COMMENT_NODE, TEXT_NODE, CDATA_SECTION_NODE} = require './node'
{DOMException, HIERARCHY_REQUEST_ERR, NOT_FOUND_ERR} = require './exceptions'
{nextSibling, indexOf, isDescendantOf, isInclusiveAncestorOf, descendants, descendantsInclusive} = require './tree_operations'
{hasChildWithNodeType, childrenWithType, isFollowedByNodeWithType, isPrecededByNodeWithType, isPartOfDocument, assignAddress} = require './dom_helpers'
{copyArray, runAsync} = require './helpers'
{MutationEvent} = require './event'

subtreeModified = (node) ->
  if doc = node.ownerDocument
    evt = doc.createEvent 'MutationEvent'
    evt.initMutationEvent 'DOMSubtreeModified', true, false, node.parentNode, '', '', '', 0
    node.dispatchEvent evt

nodeRemoved = (node) ->
  if doc = node.ownerDocument
    evt = doc.createEvent 'MutationEvent'
    evt.initMutationEvent 'DOMNodeRemoved', true, false, node.parentNode, '', '', '', 0
    node.dispatchEvent evt

  subtreeModified node

nodeInsertedIntoDocument = (node) ->
  if doc = node.ownerDocument
    assignAddress node, doc
    evt = doc.createEvent 'MutationEvent'
    evt.initMutationEvent 'DOMNodeInsertedIntoDocument', false, false, node.parentNode, '', '', '', 0
    node.dispatchEvent evt

nodeInserted = (node) ->
  if doc = node.ownerDocument
    evt = doc.createEvent 'MutationEvent'
    evt.initMutationEvent 'DOMNodeInserted', true, false, node.parentNode, '', '', '', 0
    node.dispatchEvent evt

  subtreeModified node

remove = (node, parent, suppressObservers) ->
  index = indexOf node

  # ranges

  # mutation records

  #for ancestor in ancestors node
#
  doc = parent.ownerDocument or null
  if doc
    for range in doc._ranges
      if isDescendantOf range.startContainer, node
        range.setStart parent, index
      if isDescendantOf range.endContainer, node
        range.setEnd parent, index
      if range.startContainer == parent and range.startOffset > index
        range._startOffset -= 1
      if range.endContainer == parent and range.endOffset > index
        range._startOffset -= 1

  parent._childNodes.splice index, 1
  node._parentNode = null

  nodeRemoved node

  node

adopt = (node, ownerDocument) ->
  # If node is an element, it is affected by a base URL change.
  if node.parentNode
    remove node, node.parentNode

  if ownerDocument
    for descendant in descendantsInclusive node
      #console.log 'making descendant', descendant.nodeName, ownerDocument?

      descendant._ownerDocument = ownerDocument
      if id = descendant.id
        ownerDocument._idCache[id] = descendant

      nodeInsertedIntoDocument descendant

preInsert = (node, parent, child = null) ->
  #console.log 'inserting', node.nodeName, 'to', parent.nodeName, 'is parent document', parent.nodeType == DOCUMENT_NODE

  #console.log 1
  unless parent.nodeType in [DOCUMENT_NODE, DOCUMENT_FRAGMENT_NODE, ELEMENT_NODE]
    throw new DOMException HIERARCHY_REQUEST_ERR

  #console.log 2
  if isInclusiveAncestorOf node, parent
    throw new DOMException HIERARCHY_REQUEST_ERR

  #console.log 3
  if child and child.parentNode != parent
    throw new DOMException NOT_FOUND_ERR

  #console.log 4
  if parent.nodeType == DOCUMENT_NODE
    #console.log 4.1, node.nodeValue
    unless node.nodeType in [DOCUMENT_FRAGMENT_NODE, DOCUMENT_TYPE_NODE, ELEMENT_NODE, PROCESSING_INSTRUCTION_NODE, COMMENT_NODE]
      throw new DOMException HIERARCHY_REQUEST_ERR

    #console.log 4.2
    if node.nodeType == DOCUMENT_FRAGMENT_NODE
      if childrenWithType(ELEMENT_NODE, node) > 1 or hasChildWithNodeType(TEXT_NODE, node)
        throw new DOMException HIERARCHY_REQUEST_ERR

      if childrenWithType(ELEMENT_NODE, node) == 1 and (hasChildWithNodeType(ELEMENT_NODE, parent) or (child and isFollowedByNodeWithType child, DOCUMENT_TYPE_NODE))
        throw new DOMException HIERARCHY_REQUEST_ERR

    #console.log 4.3
    # if node.nodeType == ELEMENT_NODE and (hasChildWithNodeType(ELEMENT_NODE, parent) and not (child in parent._childNodes) or (child and isFollowedBy child, DOCUMENT_TYPE_NODE))
    #   throw new DOMException HIERARCHY_REQUEST_ERR

    #console.log 4.4
    if node.nodeType == DOCUMENT_TYPE_NODE and (hasChildWithNodeType(DOCUMENT_TYPE_NODE, parent) and not (child in parent._childNodes) or (child and isPrecededByNodeWithType child, ELEMENT_NODE))
      throw new DOMException HIERARCHY_REQUEST_ERR

  else if parent.nodeType in [DOCUMENT_FRAGMENT_NODE, ELEMENT_NODE] and not (node.nodeType in [DOCUMENT_FRAGMENT_NODE, ELEMENT_NODE, TEXT_NODE, PROCESSING_INSTRUCTION_NODE, COMMENT_NODE])
    throw new DOMException HIERARCHY_REQUEST_ERR

  #console.log 5

  reference = child
  if reference == node
    child = nextSibling node

  if isPartOfDocument parent
    if parent.nodeType == DOCUMENT_NODE
      adopt node, parent
    else
      adopt node, parent.ownerDocument

  insert node, parent, reference

  node

insert = (node, parent, child, suppressObservers = false) ->
  if node.nodeType == DOCUMENT_FRAGMENT_NODE
    nodes = copyArray node._childNodes
  else
    nodes = [node]

  count = nodes.length

  if child then index = indexOf(child) else index = null
  doc = parent.ownerDocument or null
  if doc? and index?
    for range in doc._ranges
      if range.startContainer == parent and range.startOffset > index
        range._startOffset += count
      else if range.endContainer == parent and range.endOffset > index
        range._endOffset += count

  if node.nodeType == DOCUMENT_FRAGMENT_NODE
    while !!node._childNodes.length
      remove node.firstChild, node, true

  #unless suppressObservers
    #If suppress observers flag is unset, queue a "childList" record with target parent, addedNodes nodes, removedNodes null, nextSibling child, and previousSibling child's previous sibling or parent's last child if child is null.

  for toBeInserted in nodes
    toBeInserted._parentNode = parent

  if child
    parent._childNodes.splice index, 0, nodes...
  else
    parent._childNodes.push nodes...

  nodeInserted node

append = (node, parent) ->
  preInsert node, parent, null

preRemove = (child, parent) ->
  if child.parentNode != parent then throw new DOMException NOT_FOUND_ERR
  remove child, parent
  child

replaceAll = (node, parent) ->
  if node
    adopt node, parent.ownerDocument
  while parent._childNodes.length
    parent.removeChild parent.firstChild
  if node
    insert node, parent

replace = (child, node, parent) ->
  if child.parentNode != parent
    throw new DOMException NOT_FOUND_ERR

  if isInclusiveAncestorOf node, parent
    throw new DOMException HIERARCHY_REQUEST_ERR

  if parent.nodeType == DOCUMENT_NODE
    unless node.nodeType in [DOCUMENT_FRAGMENT_NODE, DOCUMENT_TYPE_NODE, ELEMENT_NODE, PROCESSING_INSTRUCTION_NODE, COMMENT_NODE]
      throw new DOMException HIERARCHY_REQUEST_ERR

    if node.nodeType == DOCUMENT_FRAGMENT_NODE
      if childrenWithType(ELEMENT_NODE, node).length > 1 or hasChildWithNodeType(TEXT_NODE, node)
        throw new DOMException HIERARCHY_REQUEST_ERR

      if childrenWithType(ELEMENT_NODE, node).length == 1 and (hasChildWithNodeType(ELEMENT_NODE, parent, [child]) or isFollowedByNodeWithType(node, DOCUMENT_TYPE_NODE))
        throw new DOMException HIERARCHY_REQUEST_ERR

    if node.nodeType == ELEMENT_NODE and (hasChildWithNodeType(ELEMENT_NODE, parent, [child]) or isFollowedByNodeWithType(node, DOCUMENT_TYPE_NODE))
        throw new DOMException HIERARCHY_REQUEST_ERR

    if node.nodeType == DOCUMENT_TYPE_NODE and (hasChildWithNodeType(DOCUMENT_TYPE_NODE, parent, [child]) or isPrecededByNodeWithType(node, ELEMENT_NODE))
        throw new DOMException HIERARCHY_REQUEST_ERR

  else if parent.nodeType in [DOCUMENT_FRAGMENT_NODE, ELEMENT_NODE] and not (node.nodeType in [DOCUMENT_FRAGMENT_NODE, ELEMENT_NODE, TEXT_NODE, PROCESSING_INSTRUCTION_NODE, COMMENT_NODE])
    throw new DOMException HIERARCHY_REQUEST_ERR

  reference = nextSibling child
  if reference == node
    reference = nextSibling node

  adopt node, parent.ownerDocument
  remove child, parent
  insert node, parent, reference

  if node.nodeType == DOCUMENT_FRAGMENT_NODE
    nodes = node._childNodes
  else
    nodes = [node]

  #queue a "childList" record with target parent, addedNodes nodes, removedNodes a list solely containing child, nextSibling reference child, and previousSibling child's previous sibling.e

  #At this point nodes are removed and nodes are inserted.

  child

module.exports = {remove, adopt, preInsert, insert, append, preRemove, replaceAll, replace, clone}

clone = module.exports.clone = (node, ownerDocument, cloneChildren = true) ->
  {Document, DocumentType} = require './document'
  {Element, Attr} = require './element'
  {Text, ProcessingInstruction, Comment} = require './character_data'
  {DocumentFragment} = require './node'

  switch node.nodeType
    when ELEMENT_NODE
      {localName, namespaceURI, prefix, _attributes} = node
      copy = ownerDocument.createElement localName
      copy._namespaceURI = namespaceURI
      copy._prefix = prefix
      for {name, namespaceURI, prefix, localName, value} in _attributes
        copy._attributes.push new Attr name, namespaceURI, prefix, localName, value
    when ATTRIBUTE_NODE
      copy = new Attr
    when TEXT_NODE
      {data} = node
      copy = ownerDocument.createTextNode data
    when CDATA_SECTION_NODE
      {data} = node
      copy = new CharacterData data
    when PROCESSING_INSTRUCTION_NODE
      {target, data} = node
      copy = ownerDocument.createProcessingInstruction target, data
    when COMMENT_NODE
      {data} = node
      copy = ownerDocument.createComment data
    when DOCUMENT_NODE
      copy = new Document
    when DOCUMENT_TYPE_NODE
      {name, publicID, systemID} = node
      copy = ownerDocument.implementation.createDocumentType name, publicID, systemID
    when DOCUMENT_FRAGMENT_NODE
      copy = ownerDocument.createDocumentFragment()
    when NOTATION_NODE
      copy = new Notation

  if cloneChildren
    for child in node._childNodes
      clonedChild = clone child, ownerDocument, cloneChildren
      append clonedChild, copy

  copy
