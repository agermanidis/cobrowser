{Node} = require '../dom/node'
{Element} = require '../dom/element'
{printException} = require '../test_helpers'
vows = require 'vows'
assert = require 'assert'

NodeTests = vows.describe('Node').addBatch
  'node without parent or children test':
    topic: ->
      node = new Element "tag"
      node

    'node type is ELEMENT_NODE': (node) ->
      assert.equal node.nodeType, Node.ELEMENT_NODE

    'has no parent': (node) ->
      assert.isNull node.parentNode
      assert.isNull node.parentElement

    'has no siblings': (node) ->
      assert.isNull node.nextSibling
      assert.isNull node.previousSibling

    'has no children': (node) ->
      assert.equal node.childNodes.length, 0
      assert.isFalse node.hasChildNodes()
      assert.isNull node.firstChild
      assert.isNull node.lastChild

    'has no node document': (node) ->
      assert.isNull node.ownerDocument

  'appending child':
    topic: ->
      node = new Element "tag"
      child1 = new Element "tag"
      {node, child1}

    'appending child returns child': ({node, child1}) ->
      assert.equal node.appendChild(child1), child1

    'length of childNodes is 1': ({node}) ->
      assert.equal node.childNodes.length, 1

    'hasChildNodes returns true': ({node}) ->
      assert.isTrue node.hasChildNodes()

    'parent of child1 is node': ({node, child1}) ->
      assert.equal child1.parentNode, node

    'node contains child1': ({node, child1}) ->
      assert.isTrue node.contains child1

    'node.compareDocumentPosition(child1) => DOCUMENT_POSITION_CONTAINS': ({node, child1}) ->
      assert.isNotZero node.compareDocumentPosition(child1) & Node.DOCUMENT_POSITION_CONTAINED_BY
      assert.isZero node.compareDocumentPosition(child1) & Node.DOCUMENT_POSITION_CONTAINS

    'child1.compareDocumentPosition(node) => DOCUMENT_POSITION_CONTAINED_BY': ({node, child1}) ->
      assert.isNotZero child1.compareDocumentPosition(node) & Node.DOCUMENT_POSITION_CONTAINS

  'appending two children':
      topic: ->
        node = new Element "node"
        child1 = new Element "child1"
        child2 = new Element "child2"

        node.appendChild child2
        node.insertBefore child1, child2

        {node, child1, child2}

      'length of childNodes is 2': ({node, child1, child2}) ->
        assert.equal node.childNodes.length, 2

      'children are in the right order: [child1, child2]': ({node, child1, child2}) ->
        assert.deepEqual node._childNodes, [child1, child2]
        assert.isNotZero child1.compareDocumentPosition(child2) & Node.DOCUMENT_POSITION_FOLLOWING
        assert.isNotZero child2.compareDocumentPosition(child1) & Node.DOCUMENT_POSITION_PRECEDING

      'parent contains children': ({node, child1, child2}) ->
        assert.isTrue node.contains child1
        assert.isTrue node.contains child2

        assert.equal node.firstChild, child1
        assert.equal node.lastChild, child2

        assert.equal child1.nextSibling, child2
        assert.equal child2.previousSibling, child1

  'removing a child':
    topic: ->
      node = new Element "node"
      child = new Element "child1"

      node.appendChild child
      node.removeChild child

      {node, child}

    'length of childNodes is 0': ({node, child}) ->
      assert.equal node.childNodes.length, 0

    'node does not contain child': ({node, child}) ->
      assert.isFalse node.contains child

  'replacing a child':
    topic: ->
      node = new Element "node"
      child1 = new Element "child1"
      child2 = new Element "child2"

      node.appendChild child1
      node.replaceChild child2, child1

      {node, child1, child2}

    'length of childNodes is 1': ({node}) ->
      assert.equal node.childNodes.length, 1

    "node's child is child2": ({node, child1, child2}) ->
      assert.isTrue node.contains child2
      assert.isFalse node.contains child1







NodeTests.export module
