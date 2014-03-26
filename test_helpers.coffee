{Browser} = require './browser'
{EventTarget} = require './dom/event'
{NodeList} = require './dom/collections'
{DOMException} = require './dom/exceptions'
{nextSibling, previousSibling} = require './dom/tree_operations'
{once} = require './dom/helpers'
assert = require 'assert'
express = require 'express'
util = require 'util'
qs = require 'querystring'

{DocumentFragment} = require './dom/node'
{Element, Attr} = require './dom/element'
{CharacterData, Text, ProcessingInstruction, Comment} = require './dom/character_data'
{DocumentType, Document} = require './dom/document'

class TestNode extends EventTarget
  constructor: (@name, @parentNode) ->
    @_childNodes = []

  addChild: (c) ->
    @_childNodes.push c
    c.parentNode = @

  @get
    nextSibling: -> nextSibling @
    previousSibling: -> previousSibling @
    firstChild: -> firstChild @
    lastChild: -> lastChild @
    childNodes: -> new NodeList @_childNodes

makeTree = ([rootName, children...]) ->
  root = new TestNode rootName, null
  for child in children
    root.addChild makeTree(child)
  root

throwsDOMException = (code, block) ->
  try
    block()
  catch e
    assert.equal e.constructor, DOMException
    assert.equal e.code, code

printException = (block) ->
  try
    block()
  catch e
    console.log e

assertEventDispatched = (node, type, capture, opts..., block) ->
  [opts] = opts
  opts ?= {}
  caught = false
  listener = (evt) ->
    caught = true
    for k, v of opts
      assert.equal evt[k], v
    node.removeEventListener type, listener
  node.addEventListener type, listener, capture
  block()
  assert.isTrue caught

visitTestPage = (port, path, cb) ->
  wrappedCallback = once cb
  browser = new Browser
  browser.createTab (tab) ->
    tab.navigate "http://localhost:#{port}#{path}"
    tab.on 'session-changed', ->
      wrappedCallback null, tab
  return

visitPage = (url, callback) ->
  wrappedCallback = once callback
  browser = new Browser
  browser.createTab (tab) ->
    tab.navigate url
    tab.on 'session-changed', ->
      wrappedCallback null, tab
  return

createTestServer = (port, handlers = {}, cb) ->
  if typeof handlers == 'function'
    cb = handlers
    handlers = {}

  server = express()
  server.use express.bodyParser()

  server.requestStack = []

  for route, handler of handlers
    [method, path] = route.split ' '
    if method in ['get', 'post', 'delete', 'head']
      server[method] path, (req, res) ->
        {query, body, method, headers} = req
        server.requestStack.push {path, method, query, body, headers}
        handler req, res

  server.all "/:any", (req, res) ->
    {path, query, body, method, headers} = req
    server.requestStack.push {path, method, query, body, headers}
    res.end()

  server.hasReceivedRequest = (opts, block) ->
    expectedMethod = opts.method?.toUpperCase() or 'GET'
    expectedPath = opts.path?.toLowerCase() or '/'
    expectedQuery = opts.query or {}
    expectedBody = opts.body or {}
    expectedHeaders = opts.headers or {}

    for {method, path, query, body, headers} in server.requestStack
      if method == expectedMethod and path == expectedPath
        mismatch = false

        for k, v of expectedQuery
          if query[k] != v
            mismatch = true

        for k, v of expectedBody
          if body[k] != v
            mismatch = true

        for k, v of expectedHeaders
          if headers[k] != v
            mismatch = true

        break if mismatch
        server.requestStack = []

        return true

    server.requestStack = []
    throw new assert.AssertionError
      message: "Server did not receive the expected request"
      expected: "Expected Request: #{util.inspect(opts)}"

  httpServer = server.listen port, ->
    cb? server

  server.destroy = ->
    httpServer.close()


module.exports = {makeTree, throwsDOMException, printException, assertEventDispatched, visitTestPage, visitPage, createTestServer}
