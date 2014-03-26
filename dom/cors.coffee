isSimpleMethod = (method) ->
  method.toLowerCase() in ['get', 'head', 'post']

isSimpleResponseHeader = (header) ->
  /(Accept|Accept-Language|Content-Language)/i.test header

simpleCrossOriginRequest = ->


preflightRequest = ->
