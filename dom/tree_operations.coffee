preorder = (root) ->
  nodes = [root]
  for child in root._childNodes
    Array::push.apply nodes, preorder(child)
  nodes

findFirstChild = (root, f) ->
  for child in root._childNodes
    return child if f child
  null

findLastChild = (root, f) ->
  lc = null
  for child in root._childNodes
    lc = child if f child
  lc

findFirst = (root, f) ->
  return root if f root
  for child in root._childNodes
    if match = findFirst child, f
      return match
  null

findLast = (root, f) ->
  if f root
    last = root
  else
    last = null
  for child in root._childNodes
    if match = findLast child, f
      last = match
  null

rootOf = (node) ->
  while node.parentNode
    node = node.parentNode
  node

isDescendantOf = (A, B) ->
  !!A.parentNode and ( A.parentNode == B or isDescendantOf A.parentNode, B )

isInclusiveDescendantOf = (A, B) ->
  A == B or isDescendantOf A, B

descendants = (A) ->
  descendantsInclusive(A).slice(1)

descendantsInclusive = (A) ->
  preorder A

isAncestorOf = (A, B) ->
  isDescendantOf B, A

isInclusiveAncestorOf = (A, B) ->
  isInclusiveDescendantOf B, A

ancestors = (A) ->
  ret = []
  while A = A.parentNode
    ret.push A
  ret

ancestorsInclusive = (A) ->
  [A].concat ancestors(A)

findAncestor = (A, filter) ->
  while A = A.parentNode
    return A if filter A
  null

isSiblingOf = (A, B) ->
  A.parentNode == B.parentNode

firstChild = (A) ->
  A._childNodes[0] or null

lastChild = (A) ->
  children = A._childNodes
  children[children.length - 1] or null

indexOf = (A) ->
  A.parentNode?._childNodes.indexOf A

nextSibling = (A) ->
  index = indexOf A
  A.parentNode?._childNodes[index + 1] or null

previousSibling = (A) ->
  index = indexOf A
  A.parentNode?._childNodes[index - 1] or null

precedes = (A, B) ->
  root = rootOf A
  inTreeOrder = preorder root
  inTreeOrder.indexOf(A) < inTreeOrder.indexOf(B)

follows = (A, B) ->
  root = rootOf A
  inTreeOrder = preorder root
  inTreeOrder.indexOf(A) > inTreeOrder.indexOf(B)

precedingNode = (A, root) ->
  # if previous = previousSibling A
  #   return previous
  # A.parentNode
  inTreeOrder = preorder (root or rootOf A)
  inTreeOrder[inTreeOrder.indexOf(A) - 1] or null

followingNode = (A, root) ->
  # if child = A.childNodes[0]
  #   return child

  # if next = nextSibling A
  #   return next

  # followingNode A.parentNode

  inTreeOrder = preorder (root or rootOf A)
  inTreeOrder[inTreeOrder.indexOf(A) + 1] or null

followingNodes = (node, root) ->
  node = followingNode node, root
  ret = []
  while node
    ret.push node
    node = followingNode node, root
  ret

precedingNodes = (node, root) ->
  node = precedingNode node, root
  ret = []
  while node
    ret.push node
    node = precedingNode node, root
  ret

hasChildren = (A) ->
  !!A._childNodes.length

module.exports = {preorder, findFirstChild, findLastChild, findFirst, findLast, rootOf, isDescendantOf, isInclusiveDescendantOf, descendants, descendantsInclusive, isAncestorOf, isInclusiveAncestorOf, ancestors, ancestorsInclusive, findAncestor, isSiblingOf, firstChild, lastChild, indexOf, nextSibling, previousSibling, precedes, follows, precedingNode, followingNode, precedingNodes, followingNodes, hasChildren}
