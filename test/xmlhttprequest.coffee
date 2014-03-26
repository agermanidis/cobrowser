{XMLHttpRequest, FormData} = require '../dom/xmlhttprequest'
{createTestServer} = require '../test_helpers'
qs = require 'querystring'

performIn = (ms, f) ->
  setTimeout f, ms

describe 'XMLHttpRequest', (done) ->
  server = null

  describe 'body-less GET request and server that gives empty reply', ->
    before (done) ->
      createTestServer 2985, (newServer) =>
        server = newServer
        done()

    request = new XMLHttpRequest
    request.origin = "http://localhost:2985"

    it 'is opened correctly', ->
      request.open 'GET', '/abc'
      request._method.should.equal 'GET'
      request._url.should.equal "http://localhost:2985/abc"
      request._synchronous.should.equal false
      request._readyState.should.equal XMLHttpRequest.OPENED

    it 'sends request correctly', (done) ->
      request.send()

      performIn 1000, ->
        server.hasReceivedRequest method: 'GET', path: '/abc'

        request._statusCode.should.equal 200
        request.response.should.be.empty
        request._readyState.should.equal XMLHttpRequest.DONE

        done()

    after -> server.destroy()

  describe 'body-less GET request on server that takes too long to reply', ->
    before (done) ->
      routes =
        'get /abc': (req, res) ->
          performIn 2000, ->
            res.send 200

      createTestServer 2985, routes, (newServer) =>
        server = newServer
        done()

    request = new XMLHttpRequest
    request.origin = "http://localhost:2985"
    request.open 'GET', '/abc'
    request.timeout = 500

    it 'throws timeout error', (done) ->
      request.send()

      performIn 1000, ->
        request._error.should.be.true
        done()

    after -> server.destroy()

  describe 'body-less GET request on server that gives string reply', ->
    before (done) ->
      routes =
        'get /abc': (req, res) ->
          res.send "hello"

      createTestServer 2985, routes, (newServer) =>
        server = newServer
        done()

    request = new XMLHttpRequest
    request.origin = "http://localhost:2985"
    request.open 'GET', '/abc'
    request.timeout = 500

    it 'gets response correctly', (done) ->
      request.send()

      performIn 1000, ->
        request.response.should.equal "hello"
        done()

    after -> server.destroy()

  describe 'body-less GET request on server that gives json reply', ->
    before (done) ->
      routes =
        'get /abc': (req, res) ->
          res.json {a:2}

      createTestServer 2985, routes, (newServer) =>
        server = newServer
        done()

    request = new XMLHttpRequest
    request.origin = "http://localhost:2985"
    request.open 'GET', '/abc'
    request.responseType = 'json'

    it 'gets response correctly', (done) ->
      request.send()

      performIn 1000, ->
        request.response.should.be.a 'object'
        request.response.a.should.equal 2
        done()

    after -> server.destroy()

  describe 'POST request w/ string body', ->
    before (done) ->
      createTestServer 2985, (newServer) =>
        server = newServer
        done()

    request = new XMLHttpRequest
    request.origin = "http://localhost:2985"
    request.open 'POST', '/abc'
    request.setRequestHeader 'content-type', "application/x-www-form-urlencoded"

    it 'gets response correctly', (done) ->
      request.send qs.stringify a: 2, b: 3

      performIn 1000, ->
        console.log server.requestStack
        server.hasReceivedRequest method: "POST", path: "/abc", body: {a:'2', b:'3'}
        done()

    after -> server.destroy()

  describe 'POST request w/ form data', ->
    before (done) ->
      createTestServer 2985, (newServer) =>

        server = newServer
        done()

    request = new XMLHttpRequest
    request.origin = "http://localhost:2985"
    request.open 'POST', '/abc'

    fd = new FormData
    fd.append "a", "hello world"

    it 'gets response correctly', (done) ->
      request.send fd

      performIn 2000, ->
        console.log server.requestStack
        server.hasReceivedRequest method: "POST", path: "/abc", body: {a: 'hello world'}
        done()

    after -> server.destroy()



