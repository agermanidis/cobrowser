{preorder, findFirst, rootOf, isDescendantOf, isInclusiveDescendantOf, descendants, descendantsInclusive, isAncestorOf, isInclusiveAncestorOf, ancestors, ancestorsInclusive, findAncestor, isSiblingOf, firstChild, lastChild, indexOf, nextSibling, previousSibling, precedes, follows, precedingNode, followingNode, precedingNodes, followingNodes} = require '../dom/tree_operations'
{makeTree} = require '../test_helpers'
vows = require 'vows'
assert = require 'assert'

TreeOperationsTests = vows.describe('Tree Operations').addBatch
  all:
    topic: ->
      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]
      names = ['one', 'two', 'three', 'four', 'five', 'six']
      {tree, names}

    preorder: ({tree, names}) ->
      allNodes = preorder tree
      assert.deepEqual names, allNodes.map (node) -> node.name

    findFirst: ({tree}) ->
      match = findFirst tree, (node) -> node.name == 'four'
      assert.equal match.name, 'four'
      match = findFirst tree, (node) -> node.name == 'seven'
      assert.isNull match

    rootOf: ({tree}) ->
      child = tree.childNodes[1].childNodes[0]
      assert.equal rootOf(child).name, 'one'

    isDescendantOf: ({tree}) ->
      three = findFirst tree, (node) -> node.name == 'three'
      four = findFirst tree, (node) -> node.name == 'four'
      assert.isTrue isDescendantOf four, three
      assert.isFalse isDescendantOf three, four
      assert.isFalse isDescendantOf three, three

    isInclusiveDescendantOf: ({tree}) ->
      three = findFirst tree, (node) -> node.name == 'three'
      four = findFirst tree, (node) -> node.name == 'four'
      assert.isTrue isInclusiveDescendantOf four, three
      assert.isFalse isInclusiveDescendantOf three, four
      assert.isTrue isInclusiveDescendantOf three, three

    descendants: ({tree}) ->
      three = findFirst tree, (node) -> node.name == 'three'
      nodes = descendants three
      names = ['four', 'five', 'six']
      assert.deepEqual names, nodes.map (node) -> node.name

    descendantsInclusive: ({tree}) ->
      three = findFirst tree, (node) -> node.name == 'three'
      nodes = descendantsInclusive three
      names = ['three', 'four', 'five', 'six']
      assert.deepEqual names, nodes.map (node) -> node.name

    isAncestorOf: ({tree}) ->
      three = findFirst tree, (node) -> node.name == 'three'
      four = findFirst tree, (node) -> node.name == 'four'
      assert.isFalse isAncestorOf four, three
      assert.isTrue isAncestorOf three, four
      assert.isFalse isAncestorOf three, three

    isInclusiveAncestorOf: ({tree}) ->
      three = findFirst tree, (node) -> node.name == 'three'
      four = findFirst tree, (node) -> node.name == 'four'
      assert.equal isInclusiveAncestorOf(four, three), false
      assert.equal isInclusiveAncestorOf(three, four), true
      assert.equal isInclusiveAncestorOf(three, three), true

    ancestors: ({tree}) ->
      five = findFirst tree, (node) -> node.name == 'five'
      nodes = ancestors five
      names = ['four', 'three', 'one']
      assert.deepEqual names, nodes.map (node) -> node.name

    ancestorsInclusive: ({tree}) ->
      five = findFirst tree, (node) -> node.name == 'five'
      nodes = ancestorsInclusive five
      names = ['five', 'four', 'three', 'one']
      assert.deepEqual names, nodes.map (node) -> node.name

    findAncestor: ({tree}) ->
      five = findFirst tree, (node) -> node.name == 'five'
      three = findFirst tree, (node) -> node.name == 'three'
      assert.equal three, findAncestor five, (node) -> node.name == 'three'
      assert.isNull findAncestor three, (node) -> node.name == 'five'

    isSiblingOf: ({tree}) ->
      five = findFirst tree, (node) -> node.name == 'five'
      six = findFirst tree, (node) -> node.name == 'six'
      four = findFirst tree, (node) -> node.name == 'four'
      assert.equal isSiblingOf(five, six), true
      assert.equal isSiblingOf(four, six), false

    firstChild: ({tree}) ->
      four = findFirst tree, (node) -> node.name == 'four'
      five = findFirst tree, (node) -> node.name == 'five'
      assert.equal firstChild(four), five

    lastChild: ({tree}) ->
      four = findFirst tree, (node) -> node.name == 'four'
      six = findFirst tree, (node) -> node.name == 'six'
      assert.equal lastChild(four), six

    indexOf: ({tree}) ->
      five = findFirst tree, (node) -> node.name == 'five'
      six = findFirst tree, (node) -> node.name == 'six'
      assert.equal indexOf(five), 0
      assert.equal indexOf(six), 1

    nextSibling: ({tree}) ->
      one = findFirst tree, (node) -> node.name == 'one'
      five = findFirst tree, (node) -> node.name == 'five'
      six = findFirst tree, (node) -> node.name == 'six'

      assert.isNull nextSibling(one)
      assert.equal nextSibling(five), six
      assert.isNull nextSibling(six)

    previousSibling: ({tree}) ->
      one = findFirst tree, (node) -> node.name == 'one'
      five = findFirst tree, (node) -> node.name == 'five'
      six = findFirst tree, (node) -> node.name == 'six'

      assert.isNull previousSibling(one)
      assert.isNull previousSibling(five)
      assert.equal previousSibling(six), five

    precedes: ({tree}) ->
      one = findFirst tree, (node) -> node.name == 'one'
      five = findFirst tree, (node) -> node.name == 'five'
      six = findFirst tree, (node) -> node.name == 'six'
      assert.isTrue precedes one, five
      assert.isTrue precedes five, six
      assert.isFalse precedes six, five

    follows: ({tree}) ->
      one = findFirst tree, (node) -> node.name == 'one'
      five = findFirst tree, (node) -> node.name == 'five'
      six = findFirst tree, (node) -> node.name == 'six'
      assert.isTrue follows six, five
      assert.isTrue follows six, one
      assert.isFalse follows five, six

    precedingNode: ({tree}) ->
      one = findFirst tree, (node) -> node.name == 'one'
      four = findFirst tree, (node) -> node.name == 'four'
      five = findFirst tree, (node) -> node.name == 'five'
      six = findFirst tree, (node) -> node.name == 'six'

      assert.isNull precedingNode one
      assert.equal precedingNode(five), four
      assert.equal precedingNode(six), five

    followingNode: ({tree}) ->
      one = findFirst tree, (node) -> node.name == 'one'
      two = findFirst tree, (node) -> node.name == 'two'
      three = findFirst tree, (node) -> node.name == 'three'
      four = findFirst tree, (node) -> node.name == 'four'
      five = findFirst tree, (node) -> node.name == 'five'
      six = findFirst tree, (node) -> node.name == 'six'

      assert.equal followingNode(one), two
      assert.equal followingNode(two), three
      assert.equal followingNode(five), six
      assert.isNull followingNode six

    'followingNodes and precedingNodes': ({tree}) ->
      three = findFirst tree, (node) -> node.name == 'three'
      four = findFirst tree, (node) -> node.name == 'four'
      five = findFirst tree, (node) -> node.name == 'five'
      six = findFirst tree, (node) -> node.name == 'six'

      following = followingNodes three
      assert.deepEqual ['four', 'five', 'six'], following.map (node) -> node.name

      preceding = precedingNodes three
      assert.deepEqual ['two', 'one'], preceding.map (node) -> node.name

TreeOperationsTests.export module

