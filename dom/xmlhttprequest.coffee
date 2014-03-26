require './meta'

URL = require 'url'
http = require 'http'
https = require 'https'

{ProgressEvent, EventTarget} = require './event'
{hasListeners, fireSimpleEvent, haveSameOrigin} = require './dom_helpers'
{startsWith, makeSet, arrayBufferToBuffer, isArrayBufferView} = require './helpers'
{DOMException, TIMEOUT_ERR, NETWORK_ERR, INVALID_STATE_ERR, INVALID_ACCESS_ERR} = require './exceptions'
{Document} = require './document'
{Blob, File} = require './file'

requestError = (xhr, exception, event) ->
  xhr._error = true
  changeState xhr, XMLHttpRequest.DONE

  if xhr._synchronous
    throw new DOMException exception

  fireSimpleEvent xhr, 'readystatechange'

  unless xhr._uploadComplete
    xhr._uploadComplete = true
    fireProgressEvent xhr._upload, event, xhr
    fireProgressEvent xhr._upload, 'loadend', xhr

  fireProgressEvent xhr, event, xhr
  fireProgressEvent xhr, 'loadend', xhr

changeState = (xhr, state) ->
  switch state
    when XMLHttpRequest.HEADERS_RECEIVED, XMLHttpRequest.LOADING
      xhr._readyState = state
      fireSimpleEvent xhr, 'readystatechange'
    when XMLHttpRequest.DONE
      xhr._synchronous = false
      xhr._readyState = state
      fireSimpleEvent xhr, 'readystatechange'
      fireProgressEvent xhr, 'load', xhr
      fireProgressEvent xhr, 'loadend', xhr
    else
      xhr._readyState = state
      fireSimpleEvent xhr, 'readystatechange'

multipartEncodeFormData = (data) ->
  mime = "UTF-8"
  for entry, index in data
    {name, value, type} = entry
    if name == '_charset_' and type == 'hidden'
      entry.value = mime
    #entry.name = encodeURIComponent name
    #entry.value = encodeURIComponent value
    entry.name = name
    entry.value = value
  parts = []
  #ret = ''
  boundary = "PomoBoundary65a640b2d7d44d32a6bea6db8c71f114"
  for {name, value} in data
    preamble = "--#{boundary}\r\n"
    preamble += "content-disposition: form-data; name=\"#{name}\"\r\n"
    # type = "text/plain"
    preamble += '\r\n'
    parts.push new Buffer preamble
    parts.push new Buffer value
    parts.push new Buffer "\r\n"
    # ret += preamble
    # ret += '\r\n'
    # ret += value
    # ret += '\r\n'
  parts.push new Buffer "--#{boundary}--\r\n"
  #ret += "--#{boundary}--"
  {entityBody: parts, boundary}
  #{encodedData: ret, boundary}

# async = (f) ->
#   (args...) ->
#     self = @
#     setTimeout (-> f.call self, args...), 0

fireProgressEvent = (target, type, xhr) ->
  ev = new ProgressEvent type,
    total: xhr._totalLength or 0
    lengthComputable: xhr._lengthComputable or false
    loaded: xhr._loaded or 0

  target.dispatchEvent ev

forbiddenMethodRE = /(CONNECT|TRACE|TRACK)/i
setCookieRE = /set-cookie2?/i

forbiddenHeaders = makeSet [
  "accept-charset"
  "accept-encoding"
  "access-control-request-headers"
  "access-control-request-method"
  "connection"
  "content-length"
  "content-transfer-encoding"
  "cookie"
  "cookie2"
  "date"
  "expect"
  "host"
  "keep-alive"
  "origin"
  "referer"
  "te"
  "trailer"
  "transfer-encoding"
  "upgrade"
  "via"
]

class FormData
  @readonly ['data']

  constructor: ->
    @_data = []

  append: (name, value, filenameArg) ->
    if value instanceof Blob
      filename = 'blob'
      if value instanceof File and value.name != ''
        filename = value.name
      if filenameArg?
        filename = filenameArg

      @_data.push {name, value, type: 'file', filename}

    else
      value = value.toString()
      @_data.push {name, value, type: 'text'}

class XMLHttpRequestEventTarget extends EventTarget
  @events ['loadstart', 'progress', 'abort', 'error', 'load', 'timeout', 'loadend']

class XMLHttpRequestUpload extends XMLHttpRequestEventTarget

class XMLHttpRequest extends XMLHttpRequestEventTarget
  @events ['readystatechange']

  @UNSENT: 0
  @OPENED: 1
  @HEADERS_RECEIVED: 2
  @LOADING: 3
  @DONE: 4

  @readonly ['readyState', 'upload']

  @define
    responseType:
      get: ->
        @_responseType
      set: (type) ->
        if @_readyState == XMLHttpRequest.LOADING or @_readyState == XMLHttpRequest.DONE or @_document or @_synchronous
          throw new INVALID_ACCESS_ERR
        @_responseType = type

    timeout:
      get: -> @_timeout
      set: (val) ->
        if @_document and @_synchronous
          throw new INVALID_ACCESS_ERR
        @_timeout = val

    withCredentials:
      get: -> @_withCredentials
      set: (val) ->
        if @_readyState == XMLHttpRequest.UNSENT or @_readyState == XMLHttpRequest.OPENED or @_anonymous or @_send or @_synchronous or @_document
          throw new INVALID_ACCESS_ERR

        @_withCredentials = val

  @get
    status: ->
      if @_readyState == XMLHttpRequest.UNSENT or @_readyState == XMLHttpRequest.OPENED or @_error
        return 0

      @_statusCode

    statusText: ->
      if @_readyState == XMLHttpRequest.UNSENT or @_readyState == XMLHttpRequest.OPENED or @_error
        return ''

      http.STATUS_CODES[@_statusCode]

    responseText: ->
      unless @_responseType == '' or @_responseType == 'text'
        throw new INVALID_ACCESS_ERR

      unless @_readyState == XMLHttpRequest.LOADING or @_readyState == XMLHttpRequest.DONE
        return ''

      if @_error
        return ''

      console.log 'response data', @_responseData

      @_responseData?.join('') or ''

    responseXML: ->
      unless @_responseType == '' or @_responseType == 'document'
        throw new INVALID_ACCESS_ERR

      unless @_readyState == XMLHttpRequest.LOADING or @_readyState == XMLHttpRequest.DONE
        return null

      if @_error
        return null

      # ...

    response: ->
      if @responseType == '' or @responseType == 'text'
        unless @_readyState == XMLHttpRequest.LOADING or @_readyState == XMLHttpRequest.DONE
          return ''
        if @_error
          return ''
        @_responseData?.join('') or ''

      else
        unless @_readyState == XMLHttpRequest.DONE
          return ''
        if @_error
          return ''

        switch @responseType
          when 'arraybuffer'

            unless @_responseData
              return new ArrayBuffer

            length = 0
            for chunk in @_responseData
              length += @_responseData.length

            ab = new ArrayBuffer length

            accum = 0
            for chunk in @_responseData
              for byte in chunk
                ab[accum + index] = byte
              accum += chunk.length

            return ab

          when "blob"
            unless @_responseData
              return new Blob

          # ...

          when "document"
            unless @_responseData and @_responseContentType.toLowerCase() in ['text/html', 'text/xml', 'application/xml']
              return null

            # ...

          when "json"
            jsonText = @_responseData?.join('') or ''
            return JSON.parse jsonText

  open: (method, url, async = true, user = null, password = null) ->
    #if @_document

    if (user or password) and !haveSameOrigin(@_origin, url)
      throw new DOMException INVALID_ACCESS_ERR

    @_method = method
    @_url = URL.resolve @origin, url
    @_synchronous = not async
    @_user = user
    @_password = password

    @_send = false
    @_requestHeaders = {}
    @_responseEntityBody = null
    @_loaded = 0
    @_total = 0
    @_lengthComputable = false
    @_responseData = null

    changeState @, XMLHttpRequest.OPENED
    fireSimpleEvent @, 'readystatechange'

  setRequestHeader: (header, value) ->
    unless @_readyState == XMLHttpRequest.OPENED or @_send
      throw new DOMException INVALID_STATE_ERR

    header = header.toLowerCase()

    if forbiddenHeaders[header] or startsWith(header, "proxy-") or startsWith(header, "sec-")
      return

    @_requestHeaders[header] = value

  getResponseHeader: (header) ->
    if @_readyState == XMLHttpRequest.UNSENT or @_readyState == XMLHttpRequest.OPENED or @_error
      return null

    header = header.toLowerCase()
    @_responseHeaders[header]

  getAllResponseHeaders: ->
    if @_readyState == XMLHttpRequest.UNSENT or @_readyState == XMLHttpRequest.OPENED or @_error
      return ''

    headerStrings = []

    for k, v of @_responseHeaders when !setCookieRE.test(k)
      headerStrings.push "#{k}: #{v}"

    headerStrings.join '\r\n'

  overrideMimeType: (mime) ->
    if @_readyState == XMLHttpRequest.LOADING or XMLHttpRequest._readyState == XMLHttpRequest.DONE
      throw new DOMException INVALID_STATE_ERR
    @setRequestHeader 'content-type', mime

  send: (data) ->
    return unless data

    @_send = true

    entityBody = null

    if isArrayBufferView data
      entityBody = arrayBufferToBuffer data

    else if data instanceof Blob
      {type} = data
      if type != ''
        mime = type
      entityBody = data.data #?!

    else if typeof data == 'string'
      encoding = 'UTF-8'
      mime = 'text/plain;charset=UTF-8'
      entityBody = data

    else if data instanceof FormData
      {entityBody, boundary} = multipartEncodeFormData data.data
      mime = "multipart/form-data; boundary=#{boundary}"

    else if data instanceof Document
      {encoding} = data
      entityBody = data.innerHTML

      if data.isHTMLDocument
        mime = 'text/html'
      else
        mime = 'application/xml'

      mime += ";charset=#{encoding}"

    if @_requestHeaders['content-type']?
      [contentType] = @_requestHeaders['content-type'].split ';'
      @setRequestHeader 'content-type', "#{contentType}; charset=#{encoding}"

    else if mime
      @setRequestHeader 'content-type', mime

    if !@_synchronous and hasListeners @
      @_uploadEvents = false

    @_error = false

    unless entityBody
      @_uploadComplete = true

    unless @_synchronous
      fireSimpleEvent @, 'readystatechange'
      fireProgressEvent @, 'loadstart', @

    {protocol, hostname, port, path} = URL.parse @_url

    if protocol == 'https:'
      isHTTPS = true
      requester = https
    else if protocol == 'http:'
      isHTTPS = false
      requester = http

    unless port
      port = if isHTTPS then 443 else 80

    headers = @_requestHeaders

    if @_user
      @_password ?= ""
      authBuf = new Buffer "#{@_user}:#{@_password}"
      headers["authorization"] = "Basic #{authBuf.toString('base64')}"

    @_lengthComputable = false

    if entityBody
      if Array.isArray entityBody
        length = 0
        for entry in entityBody
          length += entry.length
        @_lengthComputable = true

      else if entityBody instanceof Buffer or typeof entityBody == 'string'
        length = entityBody.length
        @_lengthComputable = true

      @_totalLength = headers['Content-Length'] = length

    options = {protocol, hostname, path, port, headers, method: @_method}

    gotResponse = false

    @_activeRequest = req = requester.request options

    if @_timeout != 0
      onTimeout = =>
        unless gotResponse
          requestError @, TIMEOUT_ERR, 'timeout'
          req.destroy()

      setTimeout onTimeout, @_timeout

    req.on 'response', (res) =>
      console.log 'got response'
      gotResponse = true

      @_activeRequest = null
      @_activeResponse = res

      @_statusCode = res.statusCode
      @_responseHeaders = res.headers
      @_responseContentType = res.headers['content-type'] or ''

      lock = false

      progressUpdate = =>
        unless lock
          fireProgressEvent @, 'progress', @

      progressIntervalId = setInterval progressUpdate, 50

      if res.statusCode in [301, 302, 303, 307]
        @_url = res.header.location
        @_method = 'GET'
        @send()

        # If the XMLHttpRequest origin and the origin of request URL are same origin transparently follow the redirect while observing the same-origin request event rules.
        # Otherwise, follow the cross-origin request steps and terminate the steps for this algorithm.

      else
        changeState @, XMLHttpRequest.HEADERS_RECEIVED

      firstByteReceived = false
      data = []

      res.on 'data', (chunk) =>
        unless firstByteReceived
          changeState @, XMLHttpRequest.LOADING
        progressUpdate()
        data.push chunk

      res.on 'end', =>
        clearInterval progressIntervalId
        if data.length
          @_responseData = data
        changeState @, XMLHttpRequest.DONE
        @_activeResponse = null

    req.on 'error', (err) =>
      requestError @, NETWORK_ERR, 'error'

    if entityBody
      if Array.isArray entityBody
        for entry in entityBody
          req.write entry
          @_loaded += entry.length
      else
        req.write entityBody
        @_loaded += entityBody.length

    req.end()

  abort: ->
    @_aborted = true
    @_error = true
    @_synchronous = false

    @_activeRequest?.destroy()
    @_activeResponse?.destroy()

    if (@_readyState == XMLHttpRequest.UNSENT) or (@_readyState == XMLHttpRequest.OPENED and @_send) or (@_readyState == XMLHttpRequest.DONE)
      return @_readyState = XMLHttpRequest.UNSENT

    changeState @, XMLHttpRequest.DONE
    @_send = false
    fireSimpleEvent @, 'readystatechange'
    fireProgressEvent @, 'abort', @
    fireProgressEvent @, 'loadend', @

    unless @_uploadComplete
      @_uploadComplete = true
      fireProgressEvent @_upload, 'abort', @
      fireProgressEvent @_upload, 'loadend', @

  constructor: ->
    console.log 'creating new request'
    @_requestHeaders = {}
    @_anonymous = false
    @_timeout = 0
    @_withCredentials = false
    @_responseType = ''
    @_upload = new XMLHttpRequestUpload

class AnonymousXMLHttpRequest extends XMLHttpRequest
  constructor: (args...) ->
    @_anonymous = true
    super args...



module.exports = {XMLHttpRequest, XMLHttpRequestUpload, FormData}
