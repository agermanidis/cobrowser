socket = io.connect '/page'

scrollMemory = {}

isTextInput = (node) ->
  node.nodeName == 'INPUT' and /(text|search|tel|email|password)/.test node.type.toLowerCase()

guid = ->
  S4 = ->
    (((1+Math.random())*0x10000)|0).toString(16).substring(1)
  S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4()

#userId = guid()

loadedInitialStuff = false
queue = []
addressBook = {}

addToQueue = (args...) ->
  queue.push args

changesCommitted = {}

drainQueue = ->
  for [command, rest...] in queue
    console.log command, rest
    switch command
      when "node-added"
        addNode rest...
      when "node-remove"
        removeNode rest...
      when "node-attr-modified"
        changeNode rest...

socket.on 'location-changed', (url) ->
  console.log 'location changed', url
  loadedInitialStuff = false

socket.on 'print', ->
  window.print()

performPath = (ctx, path) ->
  ctx.beginPath()
  for [cmd, args...] in path
    ctx[cmd] args...

socket.on 'canvas', (address, cmd, args...) ->
  canvas = retrieveNodeFromAddress address
  ctx = canvas.getContext '2d'

  switch cmd
    when 'clearRect'
      [x, y, w, h, m] = args
      ctx.transform m...
      ctx.clearRect args...

    when 'fillRect'
      [x, y, w, h, fillStyle, m] = args
      ctx.transform m...
      ctx.fillStyle = fillStyle
      ctx.fillRect x, y, w, h

    when 'strokeRect'
      [x, y, w, h, strokeStyle, lineWidth, lineJoin, miterLimit, m] = args
      ctx.transform m...
      ctx.strokeStyle = strokeStyle
      ctx.lineWidth = lineWidth
      ctx.lineJoin = lineJoin
      ctx.miterLimit = miterLimit
      ctx.strokeRect x, y, w, h

    when 'fillText'
      [text, x, y, maxWidth, fillStyle, m] = args
      ctx.transform m...
      ctx.fillStyle = fillStyle
      #ctx.fillText = text, x, y, maxWidth

    when 'fill'
      [path, fillStyle, m] = args
      performPath ctx, path
      ctx.transform m...
      ctx.fillStyle = fillStyle
      ctx.fill()

    when 'stroke'
      [path, strokeStyle, lineWidth, lineCap, lineJoin, miterLimit, m] = args
      performPath ctx, path
      ctx.transform m...
      ctx.strokeStyle = strokeStyle
      ctx.lineWidth = lineWidth
      ctx.lineJoin = lineJoin
      ctx.miterLimit = miterLimit
      ctx.stroke()

# socket.on 'page-served-html', (id) ->
#   console.log 'id', id
#   loadedInitialStuff = false
#   $.get "/htmls/#{id}.html", (data) ->
#     [head, body] = data.split '\x00'
#     document.head.innerHTML = head
#     document.body.innerHTML = body
#     loadedInitialStuff = true

socket.on 'page-served-html', (id) ->
  loadedInitialStuff = false
  $.get "/current_page", (data) ->
    [head, body] = data.split '\x00'
    document.head.innerHTML = head
    document.body.innerHTML = body
    loadedInitialStuff = true

fixCSSURL = ->
  currentURL = "http://google.com"
  currentURLObj = URI currentURL

  for stylesheet in document.styleSheets
    for rule in stylesheet.rules
      if /url/.test rule.cssText
        backgroundImage = rule.style.backgroundImage
        if /url/.test backgroundImage
          url = backgroundImage.substring 4, backgroundImage.length - 1
          urlObj = URI url
          if urlObj.hostname() == "localhost"
            #console.log "here"
            path = urlObj.path()
            fixedURL = URI(path).absoluteTo(currentURL).toString()
            rule.style.backgroundImage = "url(\"#{fixedURL}\")"


fixStylesheets = ->
  realHost = 'http://google.com'

  $("style").each (index, el) ->
    css = el.textContent
    matches = css.match /url\([^)]*\)/g
    return unless matches
    for match in matches
      [_, url] = match.match /url\(([^)]*)\)/
      uri = URI url
      if uri.host() == ''
        css = css.replace url, uri.absoluteTo(realHost).toString()
    el.textContent = css

  $("[style]").each (index, el) ->
    css = el.style.cssText
    matches = css.match /url\([^)]*\)/g
    return unless matches
    for match in matches
      [_, url] = match.match /url\(([^)]*)\)/
      uri = URI url
      if uri.hostname() in ['','localhost']
        css = css.replace url, URI(uri.path()).absoluteTo(realHost).toString()
    el.style.cssText = css


  $("link[rel='stylesheet']").each (index, el) ->

loadDocument = (id, sd, options = {}) ->
  console.log 'loading doc', id
  currentDocumentID = id
  console.log 'scroll mem', scrollMemory
  addressBook = {}
  doc = window.document
  doc.removeChild doc.documentElement
  doc.appendChild deserializeDocument(sd)
  loadedInitialStuff = true
  #fixStylesheets()
  drainQueue()
  markVisited options.visited or documentOptions.visited or []
  if scrollValues = scrollMemory[currentDocumentID]
    setTimeout (=>
      document.body.scrollTop = scrollValues.scrollTop
      document.body.scrollLeft = scrollValues.scrollLeft
    ), 200
  else
    setTimeout (=>
      document.body.scrollTop = 0
      document.body.scrollLeft = 0
    ), 200

markVisited = (locations) ->
  $("a").each (index, anchor) ->
    if anchor.href in locations
      $(anchor).addClass 'visited'

socket.on 'page-served', (id) ->
  loadedInitialStuff = false

  $.getJSON "/document", id: tabId, ({serializedDocument, documentId}) ->
    console.log 'received doc', {documentId, serializedDocument}
    loadDocument documentId, serializedDocument

socket.on 'document-changed', (options) ->
  loadedInitialStuff = false

  $.getJSON "/document", id: tabId, ({serializedDocument, documentId}) ->
    console.log 'received doc', {documentId, serializedDocument}
    loadDocument documentId, serializedDocument

page = null

appearanceCallbacks = {}

modifyAllElements = (callback) ->
  acceptNode = (node) -> NodeFilter.FILTER_ACCEPT
  walker = document.createTreeWalker page, NodeFilter.SHOW_ELEMENT, {acceptNode}, false
  while child = walker.nextNode()
    callback child

getNodeAddress = (node) ->
  node?.dataset?.address or node?.address

descendants = (node) ->
  results = []
  for child in node.childNodes
    if child.hasChildNodes()
      Array::push.apply results, descendants(child)
    results.push child
  results


whenAppears = (address, cb) ->
  if node = retrieveNodeFromAddress address
    cb node
  else
    appearanceCallbacks[ address ] ?= []
    appearanceCallbacks[ address ].push cb

appeared = (node) ->
  address = getNodeAddress node
  for cb in ( appearanceCallbacks[ address ] or [ ] )
    cb node

existsNode = (address) ->
  retrieveNodeFromAddress(address)?

addNode = (serializedNode, parentAddress, referenceAddress) ->
  #console.log serializedNode, parentAddress, referenceAddress

  node = deserializeCompact serializedNode
  #addressBook[address] = node

  #console.log "parent exists", existsNode parentAddress

  whenAppears parentAddress, ->
    #console.log "appeared", parentAddress

    parent = retrieveNodeFromAddress parentAddress

    if referenceAddress
      whenAppears referenceAddress, ->
        reference = retrieveNodeFromAddress referenceAddress
        parent.insertBefore node, reference
    else
      console.log "appending child"
      parent.appendChild node

    appeared node

retrieveNodeFromAddress = (address, doc = document) ->
  console.log 'addressbook', address, addressBook
  return addressBook[address] if addressBook[address]?

  return doc if getNodeAddress(doc) == address
  possibleElement = doc.querySelector "[data-address='#{address}']"
  return possibleElement if possibleElement
  for descendant in descendants(doc)
    return descendant if getNodeAddress( descendant ) == address
    #return descendant if getNodeAddress(descendant) == address
  console.log 'failed to retrieve', address

removeNode = (address) ->
  node = retrieveNodeFromAddress address
  console.log 'removing', node
  node.parentNode.removeChild node

changeNode = (address, attrName, attrValue) ->
  node = retrieveNodeFromAddress address
  node.setAttribute attrName, attrValue

changeNodeProperty = (address, propName, propValue) ->
  node = retrieveNodeFromAddress address
  node[propName] = propValue

metaWithProperty = (prop) ->
  document.querySelector "meta[property='#{prop}']"

setUrl = (url) ->
  socket.emit 'set-url', url

back = ->
  socket.emit 'back'

forward = ->
  socket.emit 'forward'


getRange = ->
  try
    sel = window.getSelection()
    range = sel.getRangeAt()
  catch e
    return
  range

keysEqual = (obj, kvs) ->
  for k, v of kvs
    return false unless obj[k] == v
  true

isContentEditable = (node) ->
  while parent = node.parentNode
    if node.contentEditable in ['' or 'true']
      return true
    if node.contentEditable == 'false'
      return false
    node = parent
  return false

isEditingText = ->
  range = getRange()
  return false unless range

  {commonAncestorContainer} = range

  return true if isContentEditable( commonAncestorContainer )
  return true if keysEqual commonAncestorContainer, nodeName: 'INPUT', type: 'text'
  return true if commonAncestorContainer.nodeName == 'TEXTAREA'

  false


installEventListeners = (node) ->
  if node.nodeName == 'INPUT' and node.type.toLowerCase() == 'submit' and node.value == ''
    node.value = "Submit"

  else if node.nodeName == 'INPUT' and node.type.toLowerCase() == 'reset' and node.value == ''
    node.value = "Reset"

  node.addEventListener 'mouseenter', ->
    console.log "MOUSE ENTER!"

  #console.log 'installed event listeners'



socket.on 'node-added', (serializedNode, parentAddress, referenceAddress) ->
  console.log 'node-added', serializedNode, parentAddress, referenceAddress

  if loadedInitialStuff
    console.log 'loadedInitialStuff'
    addNode serializedNode, parentAddress, referenceAddress

  else
    console.log 'not loadedInitialStuff'
    addToQueue 'node-added', serializedNode, parentAddress, referenceAddress

socket.on 'node-removed', (address) ->
  console.log 'node-removed', address

  if loadedInitialStuff
    removeNode address
  else
    addToQueue 'node-removed', address


socket.on 'node-attr-modified', (address, attrName, attrValue) ->
  if loadedInitialStuff
    changeNode address, attrName, attrValue
  else
    addToQueue 'node-attr-modified', address, attrName, attrValue

  console.log 'node-attr-modified', address, attrName, attrValue

socket.on 'node-prop-changed', (address, propName, propValue) ->

  if loadedInitialStuff
    changeNodeProperty address, propName, propValue
  else
    addToQueue 'node-prop-changed', address, propName, propValue

  console.log 'node-prop-changed', address, propName, propValue



socket.on 'input-changed', (address, newValue, changeId) ->
  console.log 'input-changed', address, newValue, changeId

  return if changesCommitted[changeId]

  if loadedInitialStuff
    changeNodeProperty address, "value", newValue
  else
    addToQueue 'input-changed', address, "value", newValue


socket.on 'text-changed', (address, text) ->
  textNode = retrieveNodeFromAddress addres
  throw "Tried to change text on non-text node" if textNode.nodeType != 3




socket.on 'reset', ({ serializedBodyList, serializedHeadList, serializedHTMLAttributes }) ->
  console.log 'reset'
  # for serializedNode in serializedHeadList
  #   node = deserialize serializedNode
  #   if serializedNode.nodeName == 'TITLE'
  #     document.querySelector('title').innerText = node.innerText
  #     continue
  #   else if serializedNode.nodeName == 'META'
  #     if existing = metaWithProperty( serializedNode.attributes.property )
  #       existing.parentNode.removeChild existing

  #   document.head.appendChild node

  # for serializedNode in serializedBodyList
#
  document.head.innerHTML = ''
  document.body.innerHTML = ''

  html = document.querySelector("html")

  for k, v of serializedHTMLAttributes
    html.setAttribute k, v

  for serializedNode in serializedHeadList
    node = deserialize serializedNode
    document.head.appendChild node

  for serializedNode in serializedBodyList
    #console.log serializedNode
    node = deserialize serializedNode
    document.body.appendChild node


  # will have to deal with ranges on this one

  # sel = window.getSelection()

  # try
  #   range = window.getSelection().getRangeAt()
  #   {startOffset, endOffset, startContainer, endContainer, commonAncestorContainer} = range

  # catch e
  #   range = null

  textNode.data = text

socket.on 'canvas-command', (address, command, args...) ->
  canvasElement = retrieveNodeFromAddress address
  throw "Tried to execute canvas command on non-canvas element" if canvasElement.nodeName != "CANVAS"
  context = canvasElement.getContext '2d'
  context[ command ]( args... ) # probably will have to deserialize the arguments

lastUrl = null
lastLocationId = null

socket.on 'url-changed', (url, location_id) ->
  lastUrl = url
  lastLocationId = location_id

uploadFiles = (fileList, cb) ->
  xhr = new XMLHttpRequest
  formData = new FormData
  xhr.open 'post', '/upload', true
  xhr.upload.addEventListener 'progress', (e) ->
  xhr.onreadystatechange = ->
    if xhr.readyState == 4 and xhr.status == 200
      cb?()
  for file, index in fileList
    formData.append index, file
  xhr.send formData

socket.on 'receive-files', (formAddress) ->
  el = retrieveNodeFromAddress formAddress

wrapInSpanRange = (textNode, start, end) ->
  data = textNode.data
  start ?= 0
  end ?= data.length

  if start == 0 and end == data.length and isOnlyChild(textNode)
    console.log 'doing this'
    return textNode.parentNode

  beforeText = data.substring(0, start)
  rangeText = data.substring(start, end)
  afterText = data.substring(end)

  spanWrapper = document.createElement 'span'
  spanWrapper.innerText = rangeText
  textNode.parentNode.insertBefore spanWrapper, textNode

  if beforeText != ''
    beforeTextNode = document.createTextNode data.substring(0, start)
    textNode.parentNode.insertBefore beforeTextNode, spanWrapper

  if afterText == ''
    textNode.parentNode?.removeChild textNode
  else
    textNode.data = afterText

  spanWrapper

markWhole = (el, color) ->

# socket.on 'reset', (data) ->
#   createNode(datum) for datum in data
#   fixAddresses lastUrl

eventMessage = (evt) ->
  socket.emit 'event', evt

copyKeys = (src, dest, keys) ->
  for k in keys
    dest[k] = src[k]

serializeEvent = (event) ->
  proto = event.__proto__
  serialized = {}
  copyKeys event, serialized, ['cancelable', 'bubbles', 'type', 'innerHeight', 'innerWidth']

  if event.target == window
    serialized.target = 'window'
  else
    serialized.target = getNodeAddress event.target

  if event instanceof MouseEvent
    copyKeys event, serialized, ['screenX', 'screenY', 'clientX', 'clientY', 'ctrlKey', 'shiftKey', 'altKey', 'metaKey', 'button', 'detail'] # view not included to prevent circularity
    serialized.eventClass = 'MouseEvents'

  else if event instanceof KeyboardEvent
    copyKeys event, serialized, ['keyIdentifier', 'keyLocation', 'keyCode', 'ctrlKey', 'shiftKey', 'altKey', 'metaKey', 'altGraphKey']
    serialized.eventClass = "KeyboardEvents"

  else if event instanceof MutationEvent
    copyKeys event, serialized, ['prevValue', 'newValue', 'attrName', 'attrChange'] # do i really need the previous value?
    serialized.eventClass = 'MutationEvents'

  else if event instanceof UIEvent
    copyKeys event, serialized, ['detail'] # view not included to prevent circularity
    serialized.eventClass = 'UIEvents'

  serialized

inputChanged = (target, newValue, changeId) ->
  socket.emit 'input-event', target, newValue, changeId

isFileInput = (node) ->
  node.nodeName == 'INPUT' and node.type == 'file'

hasUndesirableClickBehavior = (node) ->
  if node.nodeType == 1
    switch node.nodeName
      when "INPUT"
        return true if node.getAttribute('type') == 'submit'
      when "A"
        console.log "true"
        return true
  return false

inputChange = (node) ->
  newValue = node.value
  changeId = guid()
  changesCommitted[changeId] = true
  inputChange node.address, newValue, changeId

serializeRange = ({startContainer, endContainer, commonAncestorContainer, startOffset, endOffset}) ->
  startContainerAddress = getNodeAddress startContainer
  endContainerAddress = getNodeAddress endContainer
  commonAncestorContainerAddress = getNodeAddress commonAncestorContainer
  {startOffset, startContainerAddress, endOffset, endContainerAddress, commonAncestorContainerAddress}


selectRange = (serializedRange, color) ->

captureEvents = (node, eventTypes, handler) ->
  for type in eventTypes
    node.addEventListener type, handler, true

KeyMap =
  ENTER: 13
  SHIFT: 91
  TAB: 9
  BACKSPACE: 8
  LEFT: 37
  RIGHT: 39
  UP: 38
  DOWN: 40

submitForm = (form) ->
  socket.emit 'submit-form', form.address

window.onload = ->
  #window.location = null

  window.addEventListener 'keydown', (evt) ->
    if evt.keyCode == KeyMap.BACKSPACE
      socket.emit 'back', tabSelected

  loadDocument currentDocumentID, serializedDocument if serializedDocument

  socket.on 'connect', ->
    console.log "CONNECTED"
    socket.emit 'subscribe', tabId, userId

  # window.addEventListener 'click', (evt) ->
  #   console.log 'click', evt.target
  #   evt.preventDefault()
  #   if hasUndesirableClickBehavior(evt.target)
  #     console.log "has undesirable click"
  #   #inputChange evt.target if evt.target.nodeName == 'INPUT'
  #   eventMessage serializeEvent( evt )

  captureEvents window, ['click', 'dblclick', 'mouseover', 'mousedown', 'mousemove', 'focus', 'blur', 'focusin', 'focusout', 'mousenter', 'mouseleave', 'mouseout', 'mouseup', 'resize', 'scroll', 'keydown', 'keypress', 'keyup'], (evt) ->

    switch evt.type
      when 'keypress'
        if evt.target.nodeName == 'INPUT' and evt.keyCode == 13
          event.preventDefault()
          if form = evt.target.form
            submitForm form

      when 'click'
        evt.preventDefault()

      when 'resize'
        evt.innerHeight = window.innerHeight
        evt.innerWidth = window.innerWidth

      when 'scroll'
        console.log 'test', currentDocumentID, document.body.scrollTop
        scrollMemory[currentDocumentID] =
          scrollTop: document.body.scrollTop
          scrollLeft: document.body.scrollLeft

    eventMessage serializeEvent evt

  window.addEventListener 'change', (evt) ->
    console.log 'input', evt
    newValue = evt.target.value
    changeId = guid()
    changesCommitted[changeId] = true
    inputChanged evt.target.address, newValue, changeId

  window.addEventListener 'input', (evt) ->
    console.log 'input', evt
    newValue = evt.target.value
    changeId = guid()
    changesCommitted[changeId] = true
    inputChanged evt.target.address, newValue, changeId

  window.addEventListener 'selectionchange', ->

