{Document, DocumentType} = require '../dom/document'
{Element} = require '../dom/element'
{Text} = require '../dom/character_data'
{preorder} = require '../dom/tree_operations'
{Range, bpCompare, BEFORE, EQUAL, AFTER} = require '../dom/range'
vows = require 'vows'
assert = require 'assert'
{makeTree} = require '../test_helpers'

RangeTests = vows.describe('Range').addBatch
  'testing bpCompare':
    topic: ->
      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]
      [one, two, three, four, five, six] = preorder tree
      {tree, one, two, three, four, five, six}

    'same node, different offset': ({one}) ->
      assert.equal bpCompare(one, 1, one, 2), BEFORE
      assert.equal bpCompare(one, 1, one, 1), EQUAL
      assert.equal bpCompare(one, 2, one, 1), AFTER

    'comparing one w/ two': ({one, two}) ->
      assert.equal bpCompare(one, 0, two, 1), BEFORE
      assert.equal bpCompare(one, 1, two, 0), AFTER

    'comparing five w/ six': ({five, six}) ->
      assert.equal bpCompare(five, 3, six, 5), BEFORE
      assert.equal bpCompare(six, 3, five, 5), AFTER

  'testing Range':
    topic: ->
      doc = new Document
      doctype = doc.appendChild new DocumentType 'html'
      html = doc.appendChild new Element 'html'
      head = html.appendChild new Element 'head'
      title = head.appendChild new Element 'title'
      title.textContent = "myTitle"
      body = html.appendChild new Element 'body'
      container = body.appendChild new Element 'div'
      container.textContent = "Link: "
      link = container.appendChild new Element 'a'
      link.textContent = "here"
      linkTextNode = link.childNodes[0]
      range = doc.createRange()
      {doc, body, container, link, range, linkTextNode}

    'setStartBefore(link), setEnd(link, 2), start = [container, 1]': ({container, linkTextNode, link, range}) ->
      range.setStartBefore link
      assert.equal range.startContainer, container
      assert.equal range.startOffset, 1

    'setStartBefore(link), setEnd(link, 2), end = [linkTextNode, 2]': ({container, linkTextNode, link, range}) ->
      range.setEnd linkTextNode, 2
      assert.equal range.endContainer, linkTextNode
      assert.equal range.endOffset, 2

    'setStartBefore(link), setEnd(link, 2), commonAncestor = container': ({container, linkTextNode, link, range}) ->
     assert.equal range.commonAncestorContainer, container

    'setStartBefore(link), setEnd(link, 2), textContent = he': ({container, linkTextNode, link, range}) ->
      assert.equal range.toString(), 'he'

    'setStart(link, 2), setEndAfter(link), textContent = re': ({container, linkTextNode, link, range}) ->
      range.setStart linkTextNode, 2
      range.setEndAfter link

      assert.equal range.startContainer, linkTextNode
      assert.equal range.startOffset, 2

      assert.equal range.endContainer, container
      assert.equal range.endOffset, 2

      assert.equal range.commonAncestorContainer, container

      assert.equal range.toString(), 're'

    'selectNode(link), textContent = here': ({range, container, link}) ->
      range.selectNode link
      assert.equal range.startContainer, container
      assert.equal range.toString(), 'here'

    'selectNodeContents(link), textContent = here': ({range, link}) ->
      range.selectNodeContents link
      assert.equal range.startContainer, link
      assert.equal range.endContainer, link
      assert.equal range.startOffset, 0
      assert.equal range.endOffset, 1
      assert.equal range.toString(), 'here'

    'insertNode(abc), textContent = abchere': ({link, range}) ->
      range.insertNode new Text "abc"
      assert.equal link.childNodes[0].data, 'abc'
      assert.equal range.startContainer, link
      assert.equal range.startOffset, 0
      assert.equal range.endOffset, 2
      assert.equal range.toString(), 'abchere'

    'testing intersectsNode': ({link, range, container}) ->
      range.selectNodeContents container
      assert.isTrue range.intersectsNode link
      range.setStartAfter link
      assert.isFalse range.intersectsNode link

    'testing isPointInRange': ({link, linkTextNode, range, container}) ->
      range.setStart linkTextNode, 1
      range.setEnd linkTextNode, 3
      assert.isTrue range.isPointInRange linkTextNode, 1
      assert.isTrue range.isPointInRange linkTextNode, 2
      assert.isTrue range.isPointInRange linkTextNode, 3
      assert.isFalse range.isPointInRange linkTextNode, 4
      assert.isFalse range.isPointInRange link, 0
      assert.isFalse range.isPointInRange link, 1

    'surrounding contents': ({range, doc, link, linkTextNode}) ->
      link.removeChild link.childNodes[0]
      assert.equal link.textContent, 'here'
      range.setStart linkTextNode, 1
      range.setEnd linkTextNode, 3
      wrapper = link.appendChild doc.createElement 'span'
      wrapper.appendChild doc.createTextNode 'boo'
      range.surroundContents wrapper
      assert.equal wrapper.childNodes.length, 1
      assert.equal wrapper.textContent, 'er'
      assert.equal link.textContent, 'here'

    'deleting contents': ({container, link, range}) ->
      range.selectNode link
      range.deleteContents()
      assert.equal container.textContent, "Link: "
      assert.equal range.toString(), ''

    'collapsing': ({range, doc, link, linkTextNode}) ->
      range.setStart linkTextNode, 1
      range.setEnd linkTextNode, 3
      range.collapse true
      assert.equal range.startOffset, 1

      range.setStart linkTextNode, 1
      range.setEnd linkTextNode, 3
      range.collapse()
      assert.equal range.startOffset, 3

    'detaching': ({doc, range}) ->
      assert.isTrue range in doc._ranges
      range.detach()
      assert.isFalse range in doc._ranges


RangeTests.export module

