URL = require 'url'

{HTMLCollection} = require './collections'
{TEXT_NODE, ELEMENT_NODE, DOCUMENT_NODE, DOCUMENT_TYPE_NODE, DOCUMENT_FRAGMENT_NODE} = require './node'
{preorder, findFirst, previousSibling, nextSibling, followingNode, precedingNode} = require './tree_operations'
{Event, getEventInterface} = require './event'

locateNamespacePrefix = (element, namespace) ->
  if element.namespaceURI == namespace
    return element.prefix

  attr = node.getAttributeNS "xmlns", prefix
  attr ?= node.getAttributeNS null, "xmlns"

  return attr.localName if attr

  unless parentElement = element.parentElement
    return null

  locateNamespacePrefix parentElement, namespace

locateNamespace = (node, prefix) ->
  switch node.nodeType
    when ELEMENT_NODE
      if node.namespace and node.prefix == prefix
        return namespace

      attr = node.getAttributeNS "xmlns", prefix
      attr ?= node.getAttributeNS null, "xmlns"

      if attr
        value = attr.value
        return value

      unless parentElement = node.parentElement
        return null

      locateNamespace parentElement, prefix

    when DOCUMENT_NODE
      unless documentElement = node.documentElement
        return null

      locateNamespace documentElement, prefix

    when DOCUMENT_TYPE_NODE, DOCUMENT_FRAGMENT_NODE
      return null

    else
      unless parentElement = node.parentElement
        return null

      locateNamespace parentElement, prefix

listElements = (localName, root) ->
  if localName == '*'
    return new HTMLCollection preorder(root).filter (node) -> node.nodeType == ELEMENT_NODE

  new HTMLCollection preorder(root).filter (node) -> node.localName == localName

listElementsNS = (namespace, localName, root) ->
  namespace = null if typeof namespace == 'string' and nnamespace.length == 0

  if namespace == '*' and localName == '*'
    return new HTMLCollection preorder(root).filter (node) -> node.nodeType == ELEMENT_NODE

  if namespace == '*'
    return new HTMLCollection preorder(root).filter(node) -> node.localName == localName

  if localName == '*'
    return new HTMLCollection preorder(root).filter (node) -> node.namespaceURI == namespace

  new HTMLCollection preorder(root).filter (node) -> node.localName == localName and node.namespaceURI == namespace

listElementsByClass = (classNames, root) ->
  classes = classNames.split ' '

  if classes.length == 0
    return new HTMLCollection []

  new HTMLCollection preorder(root).filter (node) ->
    return false if node.nodeType != ELEMENT_NODE
    for className in classes
      return false unless node.classList.contains className
    true

contiguousTextNodes = (node) ->
  ret = []

  sibling = node
  while sibling = previousSibling(sibling) and sibling.nodeType == TEXT_NODE
    ret.unshift sibling

  ret.push node

  sibling = node
  while (sibling = nextSibling sibling) and sibling.nodeType == TEXT_NODE
    ret.push sibling

  ret

isFollowedByNodeWithType = (node, nodeType) ->
  while node = followingNode node
    return true if node.nodeType == nodeType
  false

isPrecededByNodeWithType = (node, nodeType) ->
  while node = precedingNode node
    return true if node.nodeType == nodeType
  false

childrenWithType = (nodeType, node) ->
  ret = []
  for child in node._childNodes
    ret.push child if child.nodeType == nodeType
  ret

hasChildWithNodeType = (nodeType, node, except = []) ->
  children = childrenWithType(nodeType, node).filter (child) -> not (child in except)
  !!children.length

findFirstWithTag = (tag, root) ->
  tag = tag.toUpperCase()
  findFirst root, (node) -> node.tagName == tag

fireSimpleEvent = (node, type, bubbles = false, cancelable = false, opts = {}) ->
  doc = node.ownerDocument or node.document

  if doc
    event = doc.createEvent "Event"
  else
    event = new Event

  event.initEvent type, bubbles, cancelable
  for k, v of opts
    event["_#{k}"] = v

  node.dispatchEvent event

  event



createEvent = (interfaceName, opts) ->
  eventInterface = getEventInterface interfaceName
  evt = new eventInterface
  for k, v of opts
    evt['_' + k] = v

haveSameOrigin = (A, B) ->
  return true if A == B

  if typeof A == 'string'
    A = URL.parse A
  if typeof B == 'string'
    B = URL.parse B

  A.protocol == B.protocol and A.host == B.host

hasListeners = (obj) ->
  for type, listeners of obj._listeners
    return true if listeners[true]?.length or listeners[false]?.length
  false

isPartOfDocument = (node) ->
  while node
    return true if node.nodeType == DOCUMENT_NODE
    node = node.parentNode
  false

assignAddress = (node, document) ->
  id = node._address = document._gid++
  document._addressCache[id] = node

getNodeByAddress = (address, document) ->
  document._addressCache[address] or null

getNodeAddress = (node) ->
  node._address

module.exports = {locateNamespace, locateNamespacePrefix, listElements, listElementsNS, listElementsByClass, contiguousTextNodes, isFollowedByNodeWithType, isPrecededByNodeWithType, childrenWithType, hasChildWithNodeType, findFirstWithTag, fireSimpleEvent, createEvent, haveSameOrigin, hasListeners, isPartOfDocument, assignAddress, getNodeAddress, getNodeByAddress}
