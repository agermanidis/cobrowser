servePage = ->
  console.log "SERVING PAGE", !!browserWindow
  return unless browserWindow

  doc = browserWindow.document

  html = doc.getElementsByTagName('html')[0]
  serializedHTMLAttributes = {}
  for {nodeName, nodeValue} in html.attributes
    serializedHTMLAttributes[nodeName] = nodeValue

  serializedHeadAttributes = {}
  for {nodeName, nodeValue} in doc.head.attributes
    serializedHeadAttributes[nodeName] = nodeValue

  serializedBodyAttributes = {}
  for {nodeName, nodeValue} in doc.body.attributes
    serializedBodyAttributes[nodeName] = nodeValue

  try

    serializedHeadList = []
    for node in doc.head.childNodes
      continue unless node.nodeType in [1,3]
      continue if node.nodeName in ['SCRIPT', 'NOSCRIPT']
      if node.nodeName == 'META' and node.getAttribute('http-equiv') == 'refresh'
        executeHttpEquivRefresh node.getAttribute('content')
        continue
      try
        serialized = serializeCompact node, browserWindow.location.href
      catch e
        throw e
      serializedHeadList.push serialized


    serializedBodyList = []
    for node in doc.body.childNodes
      continue unless node.nodeType in [1,3]
      continue if node.nodeName in ['SCRIPT', 'NOSCRIPT']
      try
        serialized = serializeCompact node, browserWindow.location.href
      catch e
        throw e
      serializedBodyList.push serialized

  catch e
    console.log "EEEE", e

  currentPageId = uuid()
  currentPage = JSON.stringify {serializedBodyList, serializedHeadList, serializedHTMLAttributes, serializedHeadAttributes, serializedBodyAttributes}

  console.log "serving page", currentPageId

  # fs.open "./public/jsons/#{currentPageId}", 'w', (err, fd) ->
  #   fs.write fd, JSON.stringify(currentPage)

  browserEvents.emit 'page-served', currentPageId

servePageHTML = ->
  return unless browserWindow

  doc = browserWindow.document

  currentPageId = uuid()
  #currentPageHTML = browserWindow.document.outerHTMLIgnoringScript

  currentPageHTML = doc.head.innerHTMLIgnoringScript
  currentPageHTML += "\x00"
  currentPageHTML += doc.body.innerHTMLIgnoringScript

  return unless currentPageHTML?

  # fs.open "./public/htmls/#{currentPageId}.html", 'w', (err, fd) ->
  #   fs.write fd, currentPageHTML

  browserEvents.emit 'page-served-html', currentPageId


injectListeners = (window) ->
  nodeAddedListener = ({target}) ->
    return if target.nodeName in ''

    if target == target.parentNode?.lastChild
      insert = no
    else
      insert = yes
      referenceAddress = getNodeAddress target.nextSibling

    serializedNode = serializeGivenUrl target, window.location.href
    parentAddress = getNodeAddress target.parentNode

    browserEvents.emit 'node-added', serializedNode, insert, parentAddress, referenceAddress

  nodeRemovedListener = ({ target }) ->
    console.log "node removed", target
    browserEvents.emit 'node-removed', getNodeAddress( target )

  nodeAttrChangeListener = ( {target, newValue, attrName} ) ->
    browserEvents.emit 'node-attr-changed', getNodeAddress( target ), attrName, newValue

  windowLocationListener =  ({ newURL }) ->
    browserEvents.emit 'url-changed', newURL

  window.addEventListener 'DOMNodeInserted', nodeAddedListener
  window.addEventListener 'DOMNodeRemoved', nodeRemovedListener
  window.addEventListener 'DOMAttrModified', nodeAttrChangeListener
  window.addEventListener 'WindowLocationChanged', windowLocationChanged

  {nodeAddedListener, nodeRemovedListener, nodeAttrChangeListener, windowLocationListener}

lock =->

  locked = false
  lockQueue = []

  lockListeners = ->
    locked = true

  unlockListeners = ->
    locked = false
    fn args... for [fn, args] in lockQueue

  lockAware = (fn) ->
    (args...) ->
      if locked
        lockQueue.push [fn, args]
      else
        fn args...


  browserEvents.on 'title-changed', ({title}) ->
    socket.emit 'title-changed', title

  browserEvents.on 'location-changed', (url) ->
    socket.emit 'location--changed', url

  browserEvents.on 'status-changed', (status) ->
    socket.emit 'status-changed', status

  browserEvents.on 'log', (message) ->
    socket.emit 'log', message

  socket.on 'set-url', (url) ->
    clientEvents.emit 'set-url', url


# jsdom.env "http://google.com", [], (errors, window) ->
#   listenRepl window

#   browser?.addEventListener 'ActiveDocumentChanged', (evt) ->
#     {window, document, canGoBackward, canGoForward} = evt
#     setupWindow window

#   browser?.addEventListener 'TabOpened', (tabId) ->

#   browser?.addEventListener 'TabRemoved', ->

#   clientEvents.on 'CreateTab', (requestId) ->

#   window.addEventListener 'DOMNodeInserted', ({target}) ->
#     console.log 'DOMNodeInsertedIntoDocument'
#     nodeInserted target, window

#   window.addEventListener 'DOMNodeRemoved', ({ target }) ->
#     address = getNodeAddress( target )
#     console.log "node removed", address
#     browserEvents.emit 'node-removed', address if address

#   window.addEventListener 'DOMAttrModified', ( {target, newValue, attrName} ) ->
#     console.log 'attr modified', target.address, attrName, newValue
#     browserEvents.emit 'node-attr-changed', getNodeAddress( target ), attrName, newValue

#   # window.addEventListener 'DOMPropertyModified', ({ target, newValue, attrName }) ->
#   #   console.log 'prop changed changed'
#   #   browserEvents.emit 'node-prop-changed', getNodeAddress( target ), attrName, newValue

#   window.addEventListener 'input', ({ target, newValue, changeId }) ->
#     console.log "INPUT CHANGED", changeId
#     browserEvents.emit 'input-changed', getNodeAddress( target ), newValue, changeId

#   window.addEventListener 'DOMCharacterDataModified', ({ target, newValue }) ->
#     console.log 'ch changed'
#     browserEvents.emit 'text-changed', getNodeAddress( target ), newValue


#   window.addEventListener 'WindowLocationChanged', ({ newURL }) ->
#     browserEvents.emit 'location-changed', newURL

#   window.addEventListener 'FormExpectingFiles', ({ address }) ->
#     browserEvents.emit 'receive-files', address

#   window.addEventListener 'load', =>
#     console.log 'new page loaded'
#     browserWindow = window
#     lastId = 0
#     servePageCompact()
#     #servePageHTML()

#   clientEvents.on 'set-url', (url) ->
#     console.log 'setting url'
#     window.location = url

#   clientEvents.on 'event', (event) ->
#     handleEvent event, window

#   clientEvents.on 'text-input-event', (target, newValue, changeId) ->
#     handleTextInputEvent target, newValue, changeId, window


listenRepl = (window) ->
  server = net.createServer (conn) ->
    conn.on 'data', (data) ->
      try
        reply = window.run data.toString()
      catch e
        reply = e.toString()
      conn.write util.format( reply ) + '\r\n'

  server.listen 8595, ->
    console.log 'listening to 8595'



  fetchResource: ({location, method, referer, formData, contentType}, cb) ->
    @cookies.getCookies location, (err, cookies) =>
      requestOptions =
        url: location
        method: method or "GET"
        jar: false
        headers:
          'user-agent': @userAgent
          cookie: cookies.join "; "

      requestOptions.headers.referer = referer if referer
      requestOptions.headers['content-type'] = contentType if contentType

      request requestOptions, (err, resp, body) =>
        return cb(@blank) if err

        addCookie = (cookieString) =>
          @cookies.setCookie cookieString, location, {}, ->

        setCookieHeader = resp.headers['set-cookie']

        if setCookieHeader?
          if Array.isArray setCookieHeader
             setCookieHeader.forEach addCookie
          else
             addCookie setCookieHeader

        cb body


  fetchDocument: ({location, method, referer, formData, contentType}, cb) ->
    @cookies.getCookies location, (err, cookies) =>
      requestOptions =
        url: location
        method: method or "GET"
        jar: false
        headers:
          'user-agent': @userAgent
          cookie: cookies.join "; "

      requestOptions.headers.referer = referer if referer
      requestOptions.headers['content-type'] = contentType if contentType

      console.log "PERFORMING REQUEST"

      try
        request requestOptions, (err, resp, body) =>
          doc = new HTMLDocument url: location
          doc.parentWindow = @createWindow doc

          if err
            message = "The server at #{URL.parse(location).host} could not be found."
            doc.write "<html><body>#{message}</body></html>"

          else
            addCookie = (cookieString) =>
              @cookies.setCookie cookieString, location, {}, ->

            setCookieHeader = resp.headers['set-cookie']

            if setCookieHeader?
              if Array.isArray setCookieHeader
                 setCookieHeader.forEach addCookie
              else
                 addCookie setCookieHeader

            respType = resp.headers['content-type']

            if respType == "text/html" or /\<html\>/.test "<html>"
              doc.write body
            else
              doc.write "<html><body>#{body}</body></html>"

          doc.close()

          cb null, doc

      catch e
        message = "Invalid protocol."
        doc = new HTMLDocument
        doc.parentWindow = @createWindow doc
        doc.write "<html><body>#{message}</body></html>"
        doc.close()
        cb null, doc

  @shadowWithSetter ['abort', 'blur', 'cancel', 'canplay', 'canplaythrough', 'change', 'click', 'close', 'contextmenu', 'cuechange', 'dblclick', 'drag', 'dragend', 'dragenter', 'dragleave', 'dragover', 'dragstart', 'drop', 'durationchange', 'emptied', 'ended', 'error', 'focus', 'input', 'invalid', 'keydown', 'keypress', 'keyup', 'load', 'loadeddata', 'loadedmetadata', 'loadstart', 'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup', 'mousewheel', 'pause', 'play', 'playing', 'progress', 'ratechange', 'reset', 'scroll', 'seeked', 'seeking', 'select', 'show', 'stalled', 'submit', 'suspend', 'timeupdate', 'volumechange', 'waiting'].map (name) -> "on#{name}"


  hidden =
    _processIframe: (src) ->
      context.createChildContext src
    _submitForm: (form, submitter = null) ->
      console.log "delegating to context"
      context.submitForm form, submitter
    _fetch: (src, cb) ->
      context.resourceManager.fetch url: src, cb
    _enqueue: (f) ->
      context.resourceManager.enqueue f
    _onResourceManagerDrain: (cb) ->
      context.resourceManager.on 'drain', cb
    _setCookie: (c) ->


executeHttpEquivRefresh = (content) ->
  [timeout, url] = content.split(';')
  timeout = parseInt timeout
  if url == ''
    setTimeout timeout, ->
      browserWindow.location.reload()
  else
    url = url.split('=')[1]
    setTimeout timeout, ->
      browserWindow.location = url
