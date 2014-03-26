{INVALID_STATE_ERR} = require '../dom/exceptions'
{NodeFilter, NodeIterator, TreeWalker} = require '../dom/treewalker'
{findFirst, preorder} = require '../dom/tree_operations'
{makeTree, throwsDOMException} = require '../test_helpers'
vows = require 'vows'
assert = require 'assert'

NodeIteratorTests = vows.describe('Node Iterator').addBatch
  'show all, accept all':
    topic: ->
      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]
      three = findFirst tree, (node) -> node.name == 'three'
      iterator = new NodeIterator three, NodeFilter.SHOW_ALL, -> NodeFilter.FILTER_ACCEPT
      {iterator, tree}

    'has the right nodes in the right order': ({iterator}) ->
      assert.equal iterator.previousNode(), null

      names = ['three', 'four', 'five', 'six']

      for name in names
        next = iterator.nextNode()
        assert.equal next.name, name

      assert.equal iterator.nextNode(), null

      names.reverse()

      for name in names
        prev = iterator.previousNode()
        assert.equal prev.name, name

    'throws exception after detachment': ({iterator}) ->
      iterator.detach()
      throwsDOMException INVALID_STATE_ERR, -> iterator.nextNode()
      throwsDOMException INVALID_STATE_ERR, -> iterator.previousNode()

  'show all, accept some':
    topic: ->
      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]
      three = findFirst tree, (node) -> node.name == 'three'

      iterator = new NodeIterator three, NodeFilter.SHOW_ALL, (node) ->
        if node.name in ['four', 'five']
          NodeFilter.FILTER_ACCEPT
        else
          NodeFilter.FILTER_REJECT

      {iterator, tree}

    'has the right nodes in the right order': ({iterator}) ->
      assert.equal iterator.previousNode(), null

      names = ['four', 'five']

      for name in names
        next = iterator.nextNode()
        assert.equal next.name, name

      assert.equal iterator.nextNode(), null

      names.reverse()

      for name in names
        prev = iterator.previousNode()
        assert.equal prev.name, name


TreeWalkerTests = vows.describe('Tree Walker').addBatch
  'show all, accept all':
    topic: ->
      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]
      [one, two, three, four, five, six] = preorder tree

      walker = new TreeWalker one, NodeFilter.SHOW_ALL, -> NodeFilter.FILTER_ACCEPT
      {walker, tree, one, two, three, four, five, six}

    'parentNode returns null when root': ({walker}) ->
      assert.equal walker.parentNode(), null

    'traversing children of one w/ firstChild() and nextSibling()': ({walker, two, three}) ->
      assert.equal walker.firstChild(), two
      assert.equal walker.nextSibling(), three

    'traversing children of three w/ nextNode()': ({walker, three, four, five, six}) ->
      assert.equal walker.nextNode(), four
      assert.equal walker.nextNode(), five
      assert.equal walker.nextNode(), six

    'nextNode(), firstChild(), lastChild(), nextSibling() return false': ({walker}) ->
      assert.equal walker.nextNode(), null
      assert.equal walker.firstChild(), null
      assert.equal walker.lastChild(), null
      assert.equal walker.nextSibling(), null

    'navigating back': ({walker, five, four, three}) ->
      assert.equal walker.previousSibling(), five
      assert.equal walker.previousNode(), four
      assert.equal walker.parentNode(), three

NodeIteratorTests.export module
TreeWalkerTests.export module
