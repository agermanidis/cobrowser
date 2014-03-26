require './meta'

{extend, caseInsensitiveEqual, endsWith} = require './helpers'

endDispatch = (event) ->
  event._dispatched = false
  event._eventPhase = null
  event._currentTarget = null
  not event.defaultPrevented

getListeners = (node, type, capture = false) ->
  listeners = node._listeners?[type]?[capture] or []
  if !capture and contentListener = node["on#{type}"]
    listeners.push contentListener
  #console.log {listeners}
  listeners

invoke = (node, event) ->
  event._currentTarget = node

  switch event._eventPhase
    when Event.CAPTURING_PHASE
      listeners = getListeners node, event._type, true

    when Event.AT_TARGET
      listeners = getListeners(node, event._type, true).concat getListeners(node, event._type)

    when Event.BUBBLING_PHASE
      listeners = getListeners node, event._type

  return unless listeners

  event._listenersTriggered = true if listeners.length

  for listener in listeners
    return if event._stopImmediatePropagation

    try
      listener.call node, event
    catch e
      continue

class EventTarget
  addEventListener: (type, listener, capture = false) ->
    return unless listener
    @_listeners ?= {}
    @_listeners[type] ?= {}
    @_listeners[type][capture] ?= []
    @_listeners[type][capture].push listener
    return

  removeEventListener: (type, listener, capture = false) ->
    return unless listener and listeners = @_listeners[type]?[capture]
    index = listeners.indexOf listener
    listeners.splice index, 1 if index != -1
    return

  dispatchEvent: (event) ->
    throw new DOMException INVALID_STATE_ERR, "Event has already been dispatched" if event._dispatched
    throw new DOMException INVALID_STATE_ERR, "Event has not been initialized" if !event._initialized

    event._isTrusted = false
    event._dispatched = true
    event._target = @
    event._eventPhase = Event.CAPTURING_PHASE
    event._listenersTriggered = false

    window = @ownerDocument?.defaultView

    window.event = event if window

    path = ancestors @
    path.push window if window

    path.reverse()

    for node in path
      invoke node, event
      return endDispatch event if event._stopPropagation

    event._eventPhase = Event.AT_TARGET

    invoke @, event

    return endDispatch event if event._stopPropagation

    if event._bubbles
      path.reverse()
      event._eventPhase = Event.BUBBLING_PHASE

      for node in path
        invoke node, event
        return endDispatch event if event._stopPropagation

    endDispatch event

class Event
  @CAPTURING_PHASE: 1
  @AT_TARGET: 2
  @BUBBLING_PHASE: 3

  @readonly ['type', 'bubbles', 'cancelable', 'target', 'currentTarget', 'eventPhase', 'isTrusted', 'defaultPrevented']

  constructor: ->
    @timestamp = new Date
    @_stopPropagation = false
    @_stopImmediatePropagation = false

  stopPropagation: ->
    @_stopPropagation = true

  stopImmediatePropagation: ->
    @_stopPropagation = true
    @_stopImmediatePropagation = true

  preventDefault: ->
    @_defaultPrevented = true if @_cancelable

  initEvent: (@_type = "", @_bubbles = false, @_cancelable = false) ->
    @_initialized = true

class CustomEvent extends Event
  @readonly ['detail']
  constructor: (type, bubbles, cancelable, @_detail = null) ->
    super type, bubbles, cancelable

class UIEvent extends Event
  @readonly ['view', 'detail']
  initUIEvent: (type, bubbles, cancelable, @_view, @_detail) ->
    @initEvent type, bubbles, cancelable

class MouseEvent extends UIEvent
  @readonly ['screenX', 'screenY', 'clientX', 'clientY', 'ctrlKey', 'shiftKey', 'altKey', 'metaKey', 'button', 'relatedTarget']
  initMouseEvent: (type, bubbles, cancelable, view, detail, @_screenX, @_screenY, @_clientX, @_clientY, @_ctrlKey, @_shiftKey, @_altKey, @_metaKey, @_button, @_relatedTarget) ->
    @initUIEvent type, bubbles, cancelable, view, detail

class KeyboardEvent extends UIEvent
  @readonly ['altKey', 'char', 'charCode', 'ctrlKey', 'key', 'keyCode', 'locale', 'location', 'metaKey', 'repeat', 'shiftKey']
  initKeyboardEvent: (type, bubbles, cancelable, view, @_char, @_key, @_location) ->

class HashChangeEvent extends Event
  @readonly ['oldURL', 'newURL']

class BeforeLoadEvent extends Event
  @readonly ['url']

class BeforeUnloadEvent extends Event
  @readonly ['returnValue']

class PageTransitionEvent extends Event
  @readonly ['persisted']

class PopStateEvent extends Event
  @readonly ['state']

class ProgressEvent extends Event
  @readonly ['lengthComputable', 'loaded', 'total']
  constructor: (@_type, opts) ->
    {lengthComputable, loaded, total} = opts
    @_bubbles = @_cancelable = false
    @_lengthComputable = lengthComputable or false
    @_loaded = loaded or 0
    @_total = total or 0
    @_initialized = true

class MessageEvent extends Event
  @readonly ['data', 'origin', 'lastEventId', 'source', 'ports']
  constructor: (@_type, opts) ->
    {data, origin, lastEventId, source, ports} = opts
    @_data = data
    @_origin = origin
    @_lastEventId = lastEventId
    @_source = source
    @_ports = ports
    @_bubbles = false
    @_cancelable = false
    @_initialized = true

class MutationEvent extends Event
  @MODIFICATION: 1
  @ADDITION: 2
  @REMOVAL: 3

  @readonly ['relatedNode', 'prevValue', 'newValue', 'attrName', 'attrChange']
  initMutationEvent: (@_type, @_bubbles, @_cancelable, @_relatedNode, @_prevValue, @_newValue, @_attrName, @_attrChange) ->
    @_initialized = true

class CloseEvent extends Event
  @readonly ['wasClean', 'code', 'reason']
  constructor: (@_type, opts) ->
    {wasClean, code, reason} = opts
    @_wasClean = wasClean
    @_code = code
    @_reason = reason
    @_bubbles = false
    @_cancelable = false
    @_initialized = true

class StorageEvent extends Event
  @readonly ['key', 'oldValue', 'newValue', 'url', 'storageArea']
  constructor: (@_type, opts) ->
    {key, oldValue, newValue, url, storageArea} = opts
    @_key = key or null
    @_oldValue = oldValue or null
    @_newValue = newValue or null
    @_url = url or ''
    @_storageArea = storageArea or null
    @_bubbles = false
    @_cancelable = false
    @_initialized = true

class DragEvent extends MouseEvent
  @readonly ['dataTransfer']
  constructor: (@_type, opts) ->
    {view, detail, screenX, screenY, clientX, clientY, ctrlKey, shiftKey, altKey, metaKey, button, buttons, relatedTarget, dataTransfer} = opts
    @_view = view or null
    @_detail = detail or 0
    @_screenX = screenX or 0
    @_screenY = screenY or 0
    @_clientX = clientX or 0
    @_clientX = clientY or 0
    @_ctrlKey = ctrlKey or false
    @_shiftKey = shiftKey or false
    @_altKey = altKey or false
    @_metaKey = metaKey or false
    @_button = button or 0
    @_buttons = buttons or 0
    @_relatedTarget = relatedTarget or null
    @_initialized = true

class TrackEvent extends Event
  @readonly ['track']
  constructor: (@_type, opts) ->
    @_track = opts?.track or null
    @_bubbles = false
    @_cancelable = false
    @_initialized = true

eventInterfaces = {Event, CustomEvent, UIEvent, MouseEvent, HashChangeEvent, BeforeLoadEvent, BeforeUnloadEvent, PageTransitionEvent, ProgressEvent, MutationEvent, KeyboardEvent, CloseEvent, MessageEvent, StorageEvent, TrackEvent}

getEventInterface = (eventInterface) ->
  if endsWith eventInterface, 's'
    eventInterface = eventInterface.substring 0, eventInterface.length - 1

  for name, eventClass of eventInterfaces
    return eventClass if caseInsensitiveEqual name, eventInterface

  return Event if eventInterface.toLowerCase() == 'htmlevents'

  null

module.exports = eventInterfaces
extend module.exports, {EventTarget, getEventInterface}

{ancestors} = require './tree_operations'
{INVALID_STATE_ERR, DOMException} = require './exceptions'
