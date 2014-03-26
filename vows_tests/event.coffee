{Document} = require '../dom/document'
{Element} = require '../dom/element'
{EventTarget, Event, getEventInterface, MouseEvent} = require '../dom/event'
{findFirst, preorder} = require '../dom/tree_operations'
{INVALID_STATE_ERR} = require '../dom/exceptions'
{makeTree, throwsDOMException, printException} = require '../test_helpers'
vows = require 'vows'
assert = require 'assert'

stackMessage = (stack, name, capture = false) ->
  (event) ->
    stack.push
      name: name
      capture: capture
      phase: event._eventPhase
      currentTarget: event._currentTarget.name
      isTrusted: event._isTrusted
      dispatched: event._dispatched
      defaultPrevented: event._defaultPrevented

assertObjArrayMatch = (arr, expect) ->
  assert.equal arr.length, expect.length
  for item, index in arr
    for k, v of expect[index]
      assert.equal item[k], v

EventTests = vows.describe('Events').addBatch
  'event interfaces':
    'getEventInterface(MouseEvent) => MouseEvent': ->
      assert.equal getEventInterface('MouseEvent'), MouseEvent

    'getEventInterface(MouseEvents) => MouseEvent': ->
      assert.equal getEventInterface('MouseEvents'), MouseEvent

    'getEventInterface(TestEvent) => null': ->
      assert.isNull getEventInterface('TestEvent')

  'simple event':
    topic: ->
      stack = []

      event = new Event
      event.initEvent 'test', false, false


      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]
      [one, two, three, four, five] = preorder tree

      one.addEventListener 'test', stackMessage(stack, 'one', true), true
      two.addEventListener 'test', stackMessage(stack, 'two', true), true
      three.addEventListener 'test', stackMessage(stack, 'three', true), true
      four.addEventListener 'test', stackMessage(stack, 'four', true), true
      five.addEventListener 'test', stackMessage(stack, 'five', true), true

      one.addEventListener 'test', stackMessage(stack, 'one')
      two.addEventListener 'test', stackMessage(stack, 'two')
      three.addEventListener 'test', stackMessage(stack, 'three')
      four.addEventListener 'test', stackMessage(stack, 'four')
      five.addEventListener 'test', stackMessage(stack, 'five')



      {event, tree, stack, target: four}

    'dispatch returns true': ({event, target}) ->
      assert.isTrue target.dispatchEvent event

    'the right listeners were called': ({event, target, stack}) ->
      assertObjArrayMatch stack, [
        {name: 'one', capture: yes, phase: Event.CAPTURING_PHASE, currentTarget: 'one'},
        {name: 'three', capture: yes, phase: Event.CAPTURING_PHASE, currentTarget: 'three'},
        {name: 'four', capture: yes, phase: Event.AT_TARGET, currentTarget: 'four'},
        {name: 'four', capture: no, phase: Event.AT_TARGET, currentTarget: 'four'}
      ]

  'bubbling event':
    topic: ->
      stack = []

      event = new Event
      event.initEvent 'test', true, false

      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]
      [one, two, three, four, five] = preorder tree

      one.addEventListener 'test', stackMessage(stack, 'one', true), true
      two.addEventListener 'test', stackMessage(stack, 'two', true), true
      three.addEventListener 'test', stackMessage(stack, 'three', true), true
      four.addEventListener 'test', stackMessage(stack, 'four', true), true
      five.addEventListener 'test', stackMessage(stack, 'five', true), true

      one.addEventListener 'test', stackMessage(stack, 'one')
      two.addEventListener 'test', stackMessage(stack, 'two')
      three.addEventListener 'test', stackMessage(stack, 'three')
      four.addEventListener 'test', stackMessage(stack, 'four')
      five.addEventListener 'test', stackMessage(stack, 'five')

      {event, tree, stack, target: three}

    'dispatch returns true': ({event, target}) ->
      assert.isTrue target.dispatchEvent event

    'the right listeners were called': ({event, target, stack}) ->
      assertObjArrayMatch stack, [
        {name: 'one', capture: yes, phase: Event.CAPTURING_PHASE},
        {name: 'three', capture: yes, phase: Event.AT_TARGET},
        {name: 'three', capture: no, phase: Event.AT_TARGET}
        {name: 'one', capture: no, phase: Event.BUBBLING_PHASE}
      ]

  'trying to dispatch event while in dispatch state':
    topic: ->
      stack = []

      event = new Event
      event.initEvent 'test', true, false

      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]

      one = findFirst tree, (node) -> node.name == 'one'

      one.addEventListener 'test', (evt) ->
        one.dispatchEvent evt

      {event, tree, stack, target: one}

    'dispatch should throw invalid state error': ({event, target}) ->
      throwsDOMException INVALID_STATE_ERR, -> target.dispatchEvent(event)

  'stop propagation, capturing phase':
    topic: ->
      stack = []

      event = new Event
      event.initEvent 'test', true, false

      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]
      [one, two, three, four, five] = preorder tree

      one.addEventListener 'test', stackMessage(stack, 'one', true), true
      three.addEventListener 'test', stackMessage(stack, 'three', true), true
      four.addEventListener 'test', ( (evt) -> evt.stopPropagation() ), true
      five.addEventListener 'test', stackMessage(stack, 'five', true), true

      one.addEventListener 'test', stackMessage(stack, 'one')
      three.addEventListener 'test', stackMessage(stack, 'three')
      four.addEventListener 'test', stackMessage(stack, 'four')
      five.addEventListener 'test', stackMessage(stack, 'five')

      {event, tree, stack, target: five}

    'dispatch returns true': ({event, target}) ->
      assert.isTrue target.dispatchEvent event

    'the right listeners were called': ({event, target, stack}) ->
      assertObjArrayMatch stack, [
        {name: 'one', capture: yes, phase: Event.CAPTURING_PHASE},
        {name: 'three', capture: yes, phase: Event.CAPTURING_PHASE}
      ]

  'stop propagation, at target phase':
    topic: ->
      stack = []

      event = new Event
      event.initEvent 'test', true, false

      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]
      [one, two, three, four, five] = preorder tree

      one.addEventListener 'test', stackMessage(stack, 'one', true), true
      three.addEventListener 'test', stackMessage(stack, 'three', true), true
      four.addEventListener 'test', stackMessage(stack, 'four', true), true
      five.addEventListener 'test', stackMessage(stack, 'five', true), true

      one.addEventListener 'test', stackMessage(stack, 'one')
      three.addEventListener 'test', stackMessage(stack, 'three')
      four.addEventListener 'test', stackMessage(stack, 'four')
      five.addEventListener 'test', ( (evt) -> evt.stopPropagation() )

      {event, tree, stack, target: five}

    'the right listeners were called': ({event, target, stack}) ->
      target.dispatchEvent event

      assertObjArrayMatch stack, [
        {name: 'one', capture: yes, phase: Event.CAPTURING_PHASE},
        {name: 'three', capture: yes, phase: Event.CAPTURING_PHASE}
        {name: 'four', capture: yes, phase: Event.CAPTURING_PHASE}
        {name: 'five', capture: yes, phase: Event.AT_TARGET}
      ]

  'stop propagation, at bubbling phase':
    topic: ->
      stack = []

      event = new Event
      event.initEvent 'test', true, false

      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]
      [one, two, three, four, five] = preorder tree

      one.addEventListener 'test', stackMessage(stack, 'one', true), true
      three.addEventListener 'test', stackMessage(stack, 'three', true), true
      four.addEventListener 'test', stackMessage(stack, 'four', true), true
      five.addEventListener 'test', stackMessage(stack, 'five', true), true

      one.addEventListener 'test', stackMessage(stack, 'one')
      three.addEventListener 'test', ( (evt) -> evt.stopPropagation() )
      four.addEventListener 'test', stackMessage(stack, 'four')
      five.addEventListener 'test', stackMessage(stack, 'five')

      {event, tree, stack, target: five}

    'the right listeners were called': ({event, target, stack}) ->
      target.dispatchEvent event

      assertObjArrayMatch stack, [
        {name: 'one', capture: yes, phase: Event.CAPTURING_PHASE},
        {name: 'three', capture: yes, phase: Event.CAPTURING_PHASE}
        {name: 'four', capture: yes, phase: Event.CAPTURING_PHASE}
        {name: 'five', capture: yes, phase: Event.AT_TARGET}
        {name: 'five', capture: no, phase: Event.AT_TARGET}
        {name: 'four', capture: no, phase: Event.BUBBLING_PHASE}
      ]

  'stop propagation, same node':
    topic: ->
      stack = []

      event = new Event
      event.initEvent 'test', true, false

      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]

      one = findFirst tree, (node) -> node.name == 'one'

      one.addEventListener 'test', ( (evt) -> evt.stopPropagation() )
      one.addEventListener 'test', stackMessage(stack, 'one')

      {event, tree, stack, target: one}

    'the right listeners were called': ({event, target, stack}) ->
      target.dispatchEvent event

      assertObjArrayMatch stack, [
        {name: 'one', capture: no, phase: Event.AT_TARGET},
      ]

  'stop immediate propagation':
    topic: ->
      stack = []

      event = new Event
      event.initEvent 'test', true, false

      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]

      one = findFirst tree, (node) -> node.name == 'one'

      one.addEventListener 'test', ( (evt) -> evt.stopImmediatePropagation() )
      one.addEventListener 'test', stackMessage(stack, 'one')

      {event, tree, stack, target: one}

    'the right listeners were called': ({event, target, stack}) ->
      target.dispatchEvent event

      assert.isEmpty stack

  'cancelable, prevent default':
    topic: ->
      stack = []

      event = new Event
      event.initEvent 'test', false, true

      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]

      one = findFirst tree, (node) -> node.name == 'one'

      one.addEventListener 'test', ( (evt) -> evt.preventDefault() )

      {event, tree, stack, target: one}

    'the right listeners were called': ({event, target, stack}) ->
      assert.isFalse target.dispatchEvent event

  'not cancelable, prevent default':
    topic: ->
      stack = []

      event = new Event
      event.initEvent 'test', false, false

      tree = makeTree ['one', ['two'], ['three', ['four', ['five'], ['six']]]]

      one = findFirst tree, (node) -> node.name == 'one'

      one.addEventListener 'test', ( (evt) -> evt.preventDefault() )

      {event, tree, stack, target: one}

    'preventDefault has no effect - dispatch returns true': ({event, target, stack}) ->
      assert.isTrue target.dispatchEvent event

  'event content attributes':
    topic: ->
      stack = []

      event = new Event
      event.initEvent 'ended', false, false

      document = new Document
      document.onended = stackMessage(stack, 'ended', false)

      {document, event, stack}

    'onended is triggered': ({document, event, stack}) ->
      console.log stack
      document.dispatchEvent event
      assert.equal stack[0].name, 'ended'





EventTests.export(module)
