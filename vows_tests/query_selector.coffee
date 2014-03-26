vows = require 'vows'
assert = require 'assert'

QuerySelectorTests = vows.describe('Query Selector').addBatch
  'id selector':
    topic: ->
      doc = new Document
      doc.write "<!doctype html><html><body><div id='test'></div></body></html>"
      doc

    'query-selecting #test returns an element': (doc) ->
      res = doc.querySelector "#test"
      assert.isNotNull res

    'query-selecting #test2 returns null': (doc) ->
      assert.isNull doc.querySelector "#test2"

  'class selector':
    topic: ->
      doc = new Document
      doc.write "<!doctype html><html><body><div class='test'></div><div class='test2'></div><div class='test2'></div><div class='test3'></div></body></html>"
      doc

    'query-selecting .test returns an element': (doc) ->
      res = doc.querySelector ".test"
      assert.isNotNull res

    'query-selecting-all .test2 returns 2 elements': (doc) ->
      res = doc.querySelectorAll ".test2"
      assert.isNotNull res

    'query-selecting .test3 returns null': (doc) ->
      assert.isNull doc.querySelector "#test2"

QuerySelectorTests.export module
