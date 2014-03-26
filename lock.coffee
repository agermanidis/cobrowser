class Lock
  constructor: ->
    @locked = false
    @callbacks = []

  lock: ->
    @locked = true

  unlock: ->
    @locked = false
    thereWereCallbacks = !!@callbacks.length
    for callback in @callbacks
      callback()
    @callbacks = []
    thereWereCallbacks

  whenUnlocked: (f) ->
    if @locked
      @callbacks.push f
    else
      f()

module.exports = {Lock}
