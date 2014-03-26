{ELEMENT_NODE, DOCUMENT_NODE} = require './node'

rquickExpr = /^(?:#([\w\-]+)|(\w+)|\.([\w\-]+))$/

select = (el, selector) ->
  {nodeType} = el

  if nodeType != ELEMENT_NODE or nodeType != DOCUMENT_NODE
    return false

  quickMatch = rquickExpr.exec selector

  if match = quickMatch[1]
    if nodeType == DOCUMENT_NODE







