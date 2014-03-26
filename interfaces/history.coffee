createHistoryInterface = (history) ->
  historyInterface =
    pushState: history.pushState
    popState: history.popState
    back: history.back
    forward: history.forward

  historyInterface.__defineGetter__ 'length', ->
    history.length

  historyInterface.__defineGetter__ 'state', ->
    history.state

  historyInterface

module.exports = {createHistoryInterface}
