{Element, Attr} = require '../dom/element'
{preorder} = require '../dom/tree_operations'
{Document} = require '../dom/document'
{HTMLElement} = require '../html/element'
{MutationEvent} = require '../dom/event'
{CSSStyleDeclaration} = require '../cssom/styledeclaration'
vows = require 'vows'
assert = require 'assert'
{assertEventDispatched, printException} = require '../test_helpers'

ElementTests = vows.describe('Element').addBatch
  'simple element':
    topic: ->
      element = new Element "a"
      element

    'node.isEqualNode(node) => true': (element) ->
      assert.isTrue element.isEqualNode element

    'nodeName returns tagName': (element) ->
      assert.equal element.nodeName, 'A'

    'playing around with class': (element) ->
      assert.isFalse element.hasAttribute 'class'
      assert.equal element.classList.length, 0
      assert.equal element.className, ''

      element.className = "a b c"

      assert.isTrue element.hasAttribute 'class'

      assert.equal element.className, "a b c"
      assert.equal element.getAttribute('class'), "a b c"
      assert.equal element.getAttributeNS(null, 'class'), "a b c"

      assert.isTrue element.classList.contains "a"
      assert.isTrue element.classList.contains "b"
      assert.isTrue element.classList.contains "c"
      assert.equal element.classList.length, 3

      element.classList.remove 'c'

      assert.equal element.classList.length, 2
      assert.isFalse element.classList.contains "c"

      element.classList.toggle 'c'
      assert.equal element.classList.length, 3
      assert.isTrue element.classList.contains "c"

      element.classList.add 'd'
      assert.equal element.classList.length, 4
      assert.isTrue element.classList.contains "d"

      element.removeAttribute 'class'
      assert.isFalse element.hasAttribute 'class'

    'getting & setting id': (element) ->
      assert.isEmpty element.id
      assert.isFalse element.hasAttribute('id')
      element.id = "myId"
      assert.isTrue element.hasAttribute('id')
      assert.equal element.id, "myId"

    'setting textContent': (element) ->
      element.textContent = "abcd"
      assert.lengthOf element._childNodes, 1
      assert.equal element._childNodes[0].data, 'abcd'


  'testing htmlelement style':
    topic: ->
      el = new HTMLElement {}, 'test'

    'el.style is instance of CSSStyleDeclaration': (el) ->
      assert.instanceOf el.style, CSSStyleDeclaration

    'setting style attribute is reflected in the declaration object': (el) ->
      retrievedStyle = el.style
      el.setAttribute 'style', 'background-color: red;'
      console.log 'el attrs', el.attributes, el.style
      assert.equal el.style.cssText, 'background-color: red;'
      assert.equal el.style.backgroundColor, 'red'
      assert.equal retrievedStyle.backgroundColor, 'red'

    'setting style in the declaration is reflected in the attribute': (el) ->
      el.style.backgroundColor = ''
      el.style.width = '500px'
      assert.equal el.getAttribute('style'), 'width: 500px;'

    'setting cssText': (el) ->
      el.style.cssText = 'background-color: red; width: 10px;'
      assert.equal el.style.backgroundColor, 'red'
      assert.equal el.style.width, '10px'
      assert.equal el.style[0], 'background-color'
      assert.equal el.style[1], 'width'
      assert.equal el.style.getPropertyValue('background-color'), 'red'
      assert.equal el.style.getPropertyValue('width'), '10px'

  'element w/ children':
    topic: ->
      element = new Element "a"
      child1 = new Element "b"
      child1.className = "match"
      child2 = new Element "c"
      child3 = new Element "d"
      child3.className = "match"
      element.appendChild child1
      element.appendChild child2
      child1.appendChild child3
      {element, child1, child2, child3}

    'element.children => [child1, child2]': ({element, child1, child2} ) ->
      assert.equal element.children.length, 2
      assert.equal element.children[0], child1
      assert.equal element.firstElementChild, child1
      assert.equal element.children[1], child2
      assert.equal element.lastElementChild, child2
      assert.equal element.childElementCount, 2
      assert.equal child1.nextElementChild, child2
      assert.equal child2.previousElementChild, child1

    'element.getElementsByTagName(c) => [child2]': ({element, child2}) ->
      matches = element.getElementsByTagName 'c'
      assert.equal matches.length, 1
      assert.equal matches[0], child2

    'element.getElementsByTagName(d) => [child3]': ({element, child3}) ->
      matches = element.getElementsByTagName 'd'
      assert.equal matches.length, 1
      assert.equal matches[0], child3

    'element.getElementsByClassName(match) => [child1, child3]': ({element, child1, child3}) ->
      matches = element.getElementsByClassName 'match'
      assert.equal matches.length, 2
      assert.equal matches[0], child1
      assert.equal matches[1], child3

  # 'document-tied element':
  #   topic: ->
  #     document = new Document
  #     document.write "<!doctype html><html><head></head><body></body></html>"
  #     element = document.createElement 'p'
  #     document.body.appendChild element
  #     console.log 'el', element
  #     element

  #   'DOMAttrModified is triggered when new attr is set': (element) ->
  #     assertEventDispatched element, "DOMAttrModified", false, attrChange: MutationEvent.ADDITION, prevValue: null, newValue: 1, ->
  #       element.setAttribute 'stuff', 1

  #   'DOMAttrModified is triggered when existing attr is set': (element) ->
  #     assertEventDispatched element, "DOMAttrModified", false, attrChange: MutationEvent.MODIFICATION, prevValue: 1, newValue: 2, ->
  #       element.setAttribute 'stuff', 2

  #   'DOMAttrModified is triggered when attr is removed': (element) ->
  #     assertEventDispatched element, "DOMAttrModified", false, attrChange: MutationEvent.REMOVAL, prevValue: 2, newValue: null, ->
  #       element.removeAttribute 'stuff'

  'attr reflection works alright':
    topic: ->
      document = new Document
      document.createElement 'script'

    'setting .src sets the attribute src': (script) ->
      script.src = "abc"
      assert.equal script.getAttribute('src'), 'abc'

    'setting src attribute sets .src': (script) ->
      script.setAttribute 'src', 'def'
      assert.equal script.src, 'def'

    'setting bool attr async sets .async to true': (script) ->
      script.setAttribute 'async', 'async'
      assert.isTrue script.async
      script.async = false
      assert.isFalse script.hasAttribute 'async'
      assert.isFalse script.async
      script.async = true
      assert.isTrue script.hasAttribute 'async'
      assert.equal script.getAttribute('async'), ''

  'innerHTML and outerHTML work':
    topic: ->
      document = new Document
      console.log 'asdasd'
      document.createElement 'p'

    'innerHTML should be empty initially': (el) ->
      assert.equal el.innerHTML, ''

    'outerHTML should be just the element initially': (el) ->
      assert.equal el.outerHTML, '<p></p>'

    # 'setting innerHTML to just text': (el) ->
    #   el.innerHTML = 'hello'
    #   assert.lengthOf el._childNodes, 1
    #   assert.equal el.innerHTML, "hello"
    #   assert.equal el.outerHTML, "<p>hello</p>"
    #   assert.equal el.textContent, "hello"

    # 'setting innerHTML to <span>a</span><a>b</b>': (el) ->
    #   el.innerHTML = "<span>a</span><a>b</a>"
    #   assert.lengthOf el._childNodes, 2
    #   assert.equal el.innerHTML, "<span>a</span><a>b</a>"

  'appending to HTML elements':
    topic: ->
      document = new Document
      document.write "<html><body><p></p><form></form></body></html>"
      form = document.body.getElementsByTagName('form')[0]
      {document, form}

    'can add an element to it': ({document, form}) ->
      form.appendChild document.createElement 'input'

  'form element':
    topic: ->
      document = new Document
      document.write "<html><body><form><input></input></form></body></html>"
      form = document.body.getElementsByTagName('form')[0]
      input = document.body.getElementsByTagName('input')[0]
      {document, form, input}

    'can retrieve .form of input': ({form, input}) ->
      assert.equal input.form, form

    'can retrieve input from form.elements': ({form, input}) ->
      assert.include form.elements.collection, input

ElementTests.export module
