vows = require 'vows'
assert = require 'assert'
{assertEventDispatched} = require '../test_helpers'

ScriptTests = vows.describe('Script').addBatch
  'error is reported when script content is not valid JS':
    topic: ->
      doc = new Document
      doc.write "<!doctype html><html><head><title>ABC</title></head><body><script>var i =0;</script></body></html>"
      doc





ScriptTests.export module


