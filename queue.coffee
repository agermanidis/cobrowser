{EventEmitter} = require 'events'

taskDone = (q) ->
  ->
    q.load--
    refresh q

execute = (task, q) ->
  q.load++
  task ( -> setTimeout taskDone(q), 0 ), task

refresh = (q) ->
  #console.log q

  return if q.paused
  return if q.load >= q.capacity

  for dependency in q.dependencies
    return if dependency.load

  queue = q.queue

  if queue.length <= 0
    q.emit 'drain'
  else
    next = queue.shift()
    execute next, q

class Queue extends EventEmitter
  constructor: (@capacity = 1, args...) ->
    @queue = []
    @load = 0
    @dependencies = []
    @paused = false
    super args...

  pause: =>
    console.log 'pausing'
    @paused = true

  unpause: ->
    @paused = false
    refresh @

  enqueue: (task) =>
    console.log 'is paused', @paused
    @queue.push task
    refresh @

  drain: ->
    @queue = []
    refresh @

  addDependency: (queue) ->
    @dependencies.push queue
    queue.on 'drain', =>
      refresh @

Queue::__defineGetter__ 'length', -> @queue.length

module.exports = {Queue}

