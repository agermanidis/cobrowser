URL = require 'url'

URIResolve = (base, url) ->
  if url.match /^\/\//
    if baseUrl
      return baseUrl.match(/^(\w+:)\/\//)[1] + href
    else return null

  else if !href.match(/^\/[^\/]/)
    url = url.replace /^\//, ""

  URL.resolve base, url

module.exports = {URIResolve}

