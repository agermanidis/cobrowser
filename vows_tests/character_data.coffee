{Element} = require '../dom/element'
{Document} = require '../dom/document'
{CharacterData, Text} = require '../dom/character_data'
vows = require 'vows'
assert = require 'assert'
{printException, assertEventDispatched} = require '../test_helpers'

CharacterDataTests = vows.describe('Character Data').addBatch
  'simple text node':
    topic: ->
      text = new Text ""
      text

    'text.nodeName => #text': (text) ->
      assert.equal text.nodeName, '#text'

    'text.data.length => 0': (text) ->
      assert.equal text.data.length, 0

    'text.length => 0': (text) ->
      assert.equal text.length, 0

    'text.data => 12345678 after settting': (text) ->
      text.data = "abc"
      assert.equal text.data, "abc"
      assert.equal text.nodeValue, text.data
      assert.equal text.textContent, text.data
      text.nodeValue = "defg"
      assert.equal text.data, "defg"
      text.textContent = "12345678"
      assert.equal text.data, "12345678"

    'text.substringData(0, 4) => 1234': (text) ->
      assert.equal text.substringData(0, 4), "1234"
      assert.equal text.substringData(0, 123231), text.data

    "text.replaceData(0, 4, '4321') => 43215678": (text) ->
      assert.isUndefined text.replaceData(0, 4, '4321')
      assert.equal text.data, '43215678'

    "text.insertData(4, '1234'); text.data => 432112345678abc": (text) ->
      assert.isUndefined text.insertData(4, '1234')
      assert.equal text.data, '432112345678'

    "text.deleteData(0, 4); text.data => 12345678": (text) ->
      assert.isUndefined text.deleteData(0, 4)
      assert.equal text.data, '12345678'

    "text.appendData('abc'); text.data => 12345678abc": (text) ->
      assert.isUndefined text.appendData 'abc'
      assert.equal text.data, '12345678abc'

    "text.splitText(8) => text(12345678) and text(abc)": (text) ->
      other = text.splitText 8
      assert.equal text.data, '12345678'
      assert.equal other.data, 'abc'
      assert.equal other.parentNode, text.parentNode



  'contiguous text nodes':
    topic: ->
      parent = new Element "tag"
      text1 = new Text "a"
      text2 = new Text "b"
      text3 = new Text "c"
      text4 = new Text "d"

      parent.appendChild text1
      parent.appendChild text2
      parent.appendChild text3
      parent.appendChild text4

      {parent, text1, text2, text3, text4}

    'parentNode of text nodes is parent': ({parent, text1, text2, text3, text4}) ->
      assert.equal text1.parentNode, parent
      assert.equal text2.parentNode, parent
      assert.equal text3.parentNode, parent
      assert.equal text4.parentNode, parent

    'text*.wholeText => abcd': ({parent, text1, text2, text3, text4}) ->
      assert.equal text1.wholeText, 'abcd'
      assert.equal text2.wholeText, 'abcd'
      assert.equal text3.wholeText, 'abcd'
      assert.equal text4.wholeText, 'abcd'

    "parent.textContent => abcd": ({parent}) ->
      assert.equal parent.textContent, 'abcd'

    'parent.normalize() results in one node w/ data abcd': ({parent, text1, text2, text3, text4}) ->
      parent.normalize()
      assert.lengthOf parent._childNodes, 1
      assert.isTrue parent.contains text1
      assert.isFalse parent.contains text2
      assert.isFalse parent.contains text3
      assert.isFalse parent.contains text4
      assert.equal text1.data, 'abcd'

  'document-tied text node':
    topic: ->
      document = new Document
      document.write "<!doctype html><html><head></head><body></body></html>"
      text = document.createTextNode 'abc'
      document.body.appendChild text
      text

    'DOMCharacterDataModified is triggered when splitText is invoked': (text) ->
      assertEventDispatched text, "DOMCharacterDataModified", false, ->
        text.splitText 2

    'DOMCharacterDataModified is triggered when data is set': (text) ->
      assertEventDispatched text, "DOMCharacterDataModified", false, ->
        text.data = 'asdads'


CharacterDataTests.export module
