
getBrowsingContext = (el) ->
  el.ownerDocument.defaultView?._context or null

module.exports = {getBrowsingContext}
