addPropertyEventListeners = (obj, events) ->
  for event in events
    listenerName = "__on#{event}"
    obj.__defineGetter__ "on#{event}", ->
      @[listenerName] or null
    obj.__defineSetter__  "on#{event}", (listener) ->
      @[listenerName] = listener
      @addEventListener eventType, listener, true

module.exports = {addPropertyEventListeners}

