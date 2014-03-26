WebSocketClient = require 'websocket'
{addPropertyEventListeners} = require './helpers'

proto =
  CONNECTING: 0
  OPEN: 1
  CLOSING: 2
  CLOSED: 3

addPropertyEventListeners proto, ['close', 'error', 'message', 'open']

createWebsocketInterface = ->
  client = new WebSocketClient

  WebSocket = ->

  WebSocket.prototype = proto
  WebSocket.prototype.send = ->
  WebSocket.prototype.close = client.close

module.exports = {createWebsocketInterface}
