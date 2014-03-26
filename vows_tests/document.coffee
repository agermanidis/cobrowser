{Document, DocumentType} = require '../dom/document'
{Element} = require '../dom/element'
{HIERARCHY_REQUEST_ERR, NOT_SUPPORTED_ERR} = require '../dom/exceptions'
vows = require 'vows'
assert = require 'assert'
{throwsDOMException, printException, assertEventDispatched} = require '../test_helpers'

DocumentTests = vows.describe('Document').addBatch
  'empty document':
    topic: ->
      doc = new Document

    'event content attributes return null': (doc) ->
      assert.isNull doc.onloadeddata

    'has no doctype or documentElement': (doc) ->
      assert.isNull doc.doctype
      assert.isNull doc.documentElement

  'simple document':
    topic: ->
      doc = new Document
      doctype = doc.appendChild new DocumentType 'html'
      console.log 1, doc.createElement
      try
        html = doc.appendChild doc.createElement 'html'
      catch e
        console.log 'eee', e
      console.log 2
      head = html.appendChild doc.createElement 'head'
      console.log 3
      title = head.appendChild doc.createElement 'title'
      console.log 4
      title.textContent = "myTitle"
      body = html.appendChild doc.createElement 'body'
      console.log 'exist2?', doc?, doctype?
      {doc, doctype, html, head, title, body}

    'ownerDocument correctly set up': ({doc, doctype, html, head, title, body}) ->
      console.log 'exist?', doc?, doctype?
      assert.equal doctype.ownerDocument, doc
      assert.equal html.ownerDocument, doc
      assert.equal head.ownerDocument, doc
      assert.equal body.ownerDocument, doc

    'correctly accesses doctype, html, head, title, body': ({doc, doctype, html, head, title, body}) ->
      assert.equal doc.doctype, doctype
      assert.equal doc.documentElement, html
      assert.equal doc.head, head
      assert.equal doc.body, body
      assert.equal doc.title, 'myTitle'
      assert.equal doc.getElementsByTagName('title')[0], title

    'setting title': ({doc, title}) ->
      title.textContent = 'stuff'
      assert.equal doc.title, 'stuff'

    'cannot add a child to a doctype': ({doc, doctype}) ->
      throwsDOMException HIERARCHY_REQUEST_ERR, -> doctype.appendChild doc.createElement 'test'

    'cannot add a second doctype': ({doc}) ->
      throwsDOMException HIERARCHY_REQUEST_ERR, -> doc.appendChild new DocumentType 'html'

    'cannot add another element to document': ({doc}) ->
      throwsDOMException HIERARCHY_REQUEST_ERR, -> doc.appendChild doc.createElement 'test'

    'createElement works': ({doc, body}) ->
      el = doc.createElement 'test'
      assert.equal el.ownerDocument, doc
      body.appendChild(el)
      assert.equal doc.getElementsByTagName('test')[0], el

    'getElementById': ({doc, body}) ->
      el = doc.createElement 'test'
      el.id = 'myId'
      body.appendChild el
      assert.equal doc.getElementById('myId'), el

    'adopt an element of another document': ({doc}) ->
      otherDoc = new Document
      throwsDOMException NOT_SUPPORTED_ERR, -> doc.adoptNode otherDoc
      el = otherDoc.createElement 'test'
      assert.equal el.ownerDocument, otherDoc
      doc.adoptNode el
      assert.equal el.ownerDocument, doc

    'createRange': ({doc}) ->
      range = doc.createRange()
      assert.equal range.startContainer, doc
      assert.equal range.startOffset, 0

    'createNodeIterator': ({doc, doctype, html, head, title, body}) ->
      iterator = doc.createNodeIterator doc
      titleTextNode = title.childNodes[0]
      nodes = [doc, doctype, html, head, title, titleTextNode, body]

      for node in nodes
        next = iterator.nextNode()
        assert.equal next, node

  'mutation events are fired':
    topic: ->
      document = new Document
      parent = new Element 'parent'
      child = new Element 'child'
      {document, parent, child}

    'nodeInsertedIntoDocument is triggered when parent is adopted by document': ({document, parent}) ->
      assertEventDispatched parent, "DOMNodeInsertedIntoDocument", false, ->
        document.appendChild parent

    'nodeInserted is triggered when child is inserted into parent': ({parent, child}) ->
      assertEventDispatched child, "DOMNodeInserted", false, ->
        parent.appendChild child

  'parsing html':
    topic: ->
      doc = new Document
      doc.write "<!doctype html><html><head><title>ABC</title></head><body><script async>var i =0;</script></body></html>"
      doc

    'contains doctype': (doc) ->
      assert.equal doc.doctype.name, 'html'
      assert.equal doc.title, 'ABC'
      script = doc.getElementsByTagName('script')[0]
      assert.isObject script
      assert.equal script.text, 'var i =0;'
      assert.isTrue script.async

DocumentTests.export module
