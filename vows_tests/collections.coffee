{NodeList, HTMLCollection, DOMStringList, DOMTokenList, DOMSettableTokenList} = require '../dom/collections'
{preorder} = require '../dom/tree_operations'
{makeTree} = require '../test_helpers'
vows = require 'vows'
assert = require 'assert'

DOMTokenListTests = vows.describe('DOMTokenList').addBatch
  'empty list':
    topic: -> new DOMTokenList ""

    'correctly finds length': (topic) ->
      assert.equal topic.length, 0

    'correctly finds length after addition': (topic) ->
      topic.add "one"
      assert.equal topic.length, 1

  'non-empty list':
    topic: -> new DOMTokenList 'one two three'

    'correctly checks for elements': (topic) ->
      assert.isTrue topic.contains 'one'
      assert.isTrue topic.contains 'two'
      assert.isTrue topic.contains 'three'

    'correctly behaves after removal': (topic) ->
      topic.remove 'two'
      assert.equal topic.length, 2
      assert.isFalse topic.contains 'two'

    'correctly behaves after removal of non-member': (topic) ->
      topic.remove 'blah'
      assert.equal topic.length, 2

    'correctly behaves after addition': (topic) ->
      topic.add 'four'
      assert.equal topic.length, 3
      assert.isTrue topic.contains 'four'

    'correctly behaves after toggle of member': (topic) ->
      topic.toggle 'four'
      assert.equal topic.length, 2
      assert.isFalse topic.contains 'four'

    'correctly behaves after toggle of non-member': (topic) ->
      topic.toggle 'five'
      assert.equal topic.length, 3
      assert.isTrue topic.contains 'five'


NodeListTests = vows.describe('Node List').addBatch
  'empty list':
    topic: ->
      new NodeList

    'has length == 0': (topic) ->
      assert.isZero topic.length

    'topic.item(0) returns null': (topic) ->
      assert.isNull topic.item(0)

    'topic[0] returns undefined': (topic) ->
      assert.isUndefined topic[0]

  'list w/ one element':
    topic: ->
      new NodeList [1]

    'has length == 1': (topic) ->
      assert.equal topic.length, 1

    'topic.item(0) returns 1': (topic) ->
      assert.equal topic.item(0), 1

    'topic[0] returns 1': (topic) ->
      assert.equal topic[0], 1

  'attached to node':
    topic: ->
      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]
      [one] = preorder tree
      nodeList = new NodeList one._childNodes
      {tree, one, nodeList}

    test: ({tree, one, nodeList}) ->
      assert.equal nodeList.length, 2


NodeListTests.export module
DOMTokenListTests.export module
