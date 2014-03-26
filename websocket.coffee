require './dom/meta'

URL = require 'url'

WebSocketClient = require('websocket').client

{EventTarget, CloseEvent, MessageEvent} = require './dom/event'
{SYNTAX_ERR, INVALID_ACCESS_ERR, DOMException} = require './dom/exceptions'
{fireSimpleEvent} = require './dom/dom_helpers'
{bufferToArrayBuffer, arrayBufferToBuffer, isArrayBufferView} = require './dom/helpers'
{Blob} = require './dom/file'

buildRequestURL = (secure, host, port, resourceName) ->
  protocol = if secure then "wss:" else "ws:"
  "#{protocol}//#{host}:#{port}#{resourceName}"

parseWebsocketURL = (url) ->
  urlObj = URL.parse url

  return unless urlObj.host?
  return unless /^wss?:$/.test urlObj.protocol
  return if urlObj.hash?

  secure = urlObj.protocol == "wss:"
  host = urlObj.host.toLowerCase()
  port = urlObj.port or (if secure then 443 else 80)
  resourceName = urlObj.path or '/'
  resourceName += urlObj.search or ''

  {host, port, resourceName, secure}

establishConnection = (ws, host, port, resourceName, secure, protocols, origin) ->
  client = new WebSocketClient()
  client.on 'connect', (connection) ->
    ws._connection = connection
    connectionEstablished ws
  client.connect buildRequestURL(secure, host, port, resourceName), protocols, origin

connectionEstablished = (ws) ->
  connection = ws._connection

  ws._readyState = WebSocket.OPEN
  ws._protocol = connection.protocol
  ws._extensions = connection.extensions

  connection.on 'message', (message) ->
    messageReceived ws, message

  connection.on 'close', ->
    connectionClosed ws

  fireSimpleEvent ws, 'open'

messageReceived = (ws, message) ->
  return unless ws._readyState == WebSocket.OPEN

  if message.type == 'utf8'
    data = message.utf8Data

  else if message.type == 'binary'
    switch ws.binaryType
      when 'blob'
        data = new Blob message.binaryData
      when 'arraybuffer'
        data = bufferToArrayBuffer message.binaryData

  return unless data

  event = new MessageEvent 'message', {data, origin: ws._origin}
  ws.dispatchEvent event

connectionClosed = (ws) ->
  connection = ws._connection

  ws._readyState = WebSocket.CLOSED

  code = connection.closeReasonCode
  reason = connection.closeDescription
  wasClean = code == 1000

  unless wasClean
    fireSimpleEvent ws, 'error'

  closeEvent = new CloseEvent 'close', {wasClean, code, reason}
  ws.dispatchEvent closeEvent

  delete ws._connection

class WebSocket extends EventTarget
  @readonly ['url', 'readyState', 'bufferedAmount', 'extensions', 'protocol']
  @events ['open', 'error', 'close', 'message']

  @CONNECTING: 0
  @OPEN: 1
  @CLOSING: 2
  @CLOSED: 3

  binaryType: 'blob'

  close: (code, reason) ->
    if code and code != 1000 and (code < 3000 or code > 4999)
      throw new DOMException INVALID_ACCESS_ERR

    if reason and reason.length > 123
      throw new DOMException SYNTAX_ERR

    return if @_readyState >= WebSocket.CLOSING
    return unless @_connection

    @_connection.close()
    @_readyState = WebSocket.CLOSING

  send: (data) ->
    if @_readyState == WebSocket.CONNECTING or !@_connection
      throw new DOMException INVALID_STATE_ERR

    if data instanceof Blob
      data = data.data

    else if data instanceof ArrayBuffer or isArrayBufferView data
      data = arrayBufferToBuffer data

    @_connection.send data

  constructor: (@_origin, @_url, protocols) ->
    unless @_url
      throw new DOMException SYNTAX_ERR, "Not enough arguments"

    @_readyState = WebSocket.CONNECTING
    @_bufferedAmount = 0

    unless {host, port, resourceName, secure} = parseWebsocketURL @_url
      throw new DOMException SYNTAX_ERR, "URL is not valid"

    {protocol} = URL.parse @_origin

    if !secure and protocol == 'https'
      throw new DOMException SYNTAX_ERR

    if typeof protocols == 'string'
      protocols = [protocols]

    process.nextTick => establishConnection @, host, port, resourceName, secure, protocols, @_origin

module.exports = {WebSocket}
