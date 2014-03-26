express = require 'express'

module.exports =
  createTestServer: (paths) ->
    server = express()

    for route, handler of paths
      [method, path] = route.split ' '
      method = method.toLowerCase()
      if method in ['get', 'post', 'delete', 'head']
        server[method] path, handler

    server



