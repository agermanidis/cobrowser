require './meta'

URL = require 'url'
uuid = require 'node-uuid'
nwmatcher = require 'nwmatcher'

{Node} = require './node'

{DocumentFragment, ELEMENT_NODE, DOCUMENT_TYPE_NODE, DOCUMENT_NODE} = require './node'
{Element} = require './element'
{Text, ProcessingInstruction, Comment} = require './character_data'
{DOMException, NAMESPACE_ERR, NOT_SUPPORTED_ERR, INVALID_CHARACTER_ERR, INVALID_STATE_ERR} = require './exceptions'
{findFirst, preorder, descendantsInclusive} = require './tree_operations'
{HTMLCollection, StyleSheetList} = require './collections'
{Range} = require './range'
{NodeFilter, NodeIterator, TreeWalker} = require './treewalker'
{fireSimpleEvent, runAsync, findFirstWithTag, listElements, listElementsNS, listElementsByClass} = require './dom_helpers'
{stripLeadingAndTrailingWhitespace} = require './helpers'
{adopt, clone} = require './dom_operations'
{appendHTML, createDocumentParser} = require './html_parser'
{HTML_NAMESPACE, XMLNS_NAMESPACE} = require './namespaces'
{getEventInterface, BeforeUnloadEvent} = require './event'
{descendantContexts} = require '../context'
{getElementInterface} = require '../html/element'

{Queue} = require '../queue'
{Lock} = require '../lock'

parsingStopped = (document) ->
  console.log "PARSING STOPPED", document._scriptsToExecuteAfterParsing.length

  changeReadyState document, "interactive"

  {_openElements, _scriptsToExecuteAfterParsing, _scriptPreparationQueue} = document

  while !!_openElements.length
    _openElements.shift()

  #Spin the event loop until the first script in the list of scripts that will execute when the document has finished parsing has its "ready to be parser-executed" flag set and the parser's Document has no style sheet that is blocking scripts.

  _scriptPreparationQueue.on 'drain', ->
    _scriptsToExecuteAfterParsing.on 'drain', ->
      #throw new Error
      fireSimpleEvent document, 'DOMContentLoaded', true
      changeReadyState document, "complete"

      if window = document.defaultView
        console.log 'window listeners', window._listeners
        fireSimpleEvent window, 'load'

        pageShowEvent = document.createEvent 'PageTransitionEvent'
        pageShowEvent.initEvent false, false
        pageShowEvent.persisted = false
        window.dispatchEvent pageShowEvent

      document._readyForPostLoadTasks = true

    _scriptsToExecuteAfterParsing.unpause()

promptToUnloadDocument = (document, duringPromptToUnload = false) ->
  document._ignoreOpensDuringUnload++

  refused = false
  window = document.defaultView

  beforeUnload = document.createEvent 'BeforeUnloadEvent'
  beforeUnload.initEvent 'beforeunload', false, true
  eventSuccessful = window.dispatchEvent beforeUnload

  if beforeUnload.returnValue != '' or not eventSuccessful
    if typeof returnValue == "string" and returnValue != ""
      promptReply = window.prompt returnValue
    else
      promptReply = window.prompt "Are you sure you want to navigate away from the page?"

    refused = !promptReply

  unless duringPromptToUnload
    contexts = descendantContexts window._context
    for b in contexts
      unless promptToUnloadDocument b.document, true
        refused = true
        break
      unless b.document._salvageable
        document._salvageable = false

  document._ignoreOpensDuringUnload--

  not refused

unloadingDocumentCleanup = (document) ->
  # ...

discardDocument = (document) ->
  document._salvageable = false
  unloadingDocumentCleanup document
  window = document.defaultView
  if window
    window._context.discardDocument document
  # ...

unloadDocument = (document, recycle) ->
  refused = false

  document._ignoreOpensDuringUnload++
  window = document.defaultView
  event = fireSimpleEvent window, 'pagehide'

  if event._listenersTriggered
    document._salvageable = false

  unless duringPromptToUnload
    contexts = descendantContexts window._context
    for b in contexts
      unloadDocument b.document, false
      unless b.document._salvageable
        document._salvageable = false

    if !document._salvageable and !document._recycle
      discardDocument document

  document._ignoreOpensDuringUnload--

abortParser = (document) ->

abortDocument = (document) ->
  contexts = descendantContexts window._context
  for b in contexts
    abortDocument b.document

  document._scriptsToExecuteAfterParsing.drain()
  document._scriptsToExecuteASAP.drain()
  document._scriptPreparationQueue.drain()

  abortParser document
  document._salvageable = false

changeReadyState = (document, state) ->
  document._readyState = state
  fireSimpleEvent document, 'readystatechange'

class DocumentType extends Node
  nodeType: DOCUMENT_TYPE_NODE
  @readonly ['name', 'publicId', 'systemId']
  @get length: -> 0
  constructor: (@_name, @_publicId = '', @_systemId = '') ->
    super

class Document extends Node
  constructor: (opts = {}) ->
    console.log 'constructng doc', opts

    @_id = uuid()

    @_URL = opts.url or ''
    @_referrer = opts.referrer or ''
    @_lastModified = opts.lastModified or new Date
    @_contentType = opts.contentType or 'text/html'
    @_encoding = opts.encoding or 'UTF-8'
    @_readyState = 'loading'

    @_gid = 0
    @_parser = createDocumentParser @
    @_idCache = {}
    @_addressCache = {}
    @_ranges = []
    @_salvageable = true
    @_ignoreDestructiveWritesCounter = 0
    @_ignoreOpensDuringUnload = 0
    @_preferredStyleSheetSet = ''
    @_styleSheets = []

    @_scriptsToExecuteASAP = new Queue
    @_scriptsToExecuteAfterParsing = new Queue
    #@_scriptsToExecuteAfterParsing.addDependency @_scriptsToExecuteASAP

    @_scriptParsingLock = new Lock

    @_scriptPreparationQueue = new Queue
    @_openElements = []
    @_readyForPostLoadTasks = false
    @_active = true
    @_isParsing = false

    @_activeElement = null
    @_timesLoaded = 0

    @currentScript = null

    super

  @get _nwmatcher: ->
    if matcher = @__nwmatcher
      return matcher

    @__nwmatcher = new nwmatcher document: @

  nodeType: DOCUMENT_NODE
  compatMode: 'CSS1Compat'

  @readonly [
    'URL', 'compatMode', 'characterSet', 'contentType',
    'referrer', 'lastModified', 'reloadOverride', 'readyState',
    'preferredStyleSheetSet', 'defaultView'
  ]

  fgColor: ''
  linkColor: ''
  vlinkColor: ''
  alinkColor: ''
  bgColor: ''

  @define
    location:
      get: ->
        console.log 'defaultView', @
        @_defaultView.location
      set: (url) ->
        if window = @defaultView
          return window.location = url
        null

  @get
    activeElement: -> @_activeElement or @body

    origin: ->
      {protocol, host} = URL.parse @_URL
      "#{protocol}//#{host}"

    baseURI: -> @_URL

    styleSheets: -> new StyleSheetList @_styleSheets

    referrer: ->
      @_referrer or ''

    doctype: ->
      match = findFirst @, (node) -> node.nodeType == DOCUMENT_TYPE_NODE
      match or null

    documentURI: -> @_URL

    documentElement: ->
      for child in @_childNodes
        return child if child.nodeType == ELEMENT_NODE
      null

    implementation: ->
      new DOMImplementation @

    head: ->
      findFirstWithTag 'head', @

    body: ->
      findFirstWithTag 'body', @

    title: ->
      title = findFirstWithTag 'title', @
      return null unless title
      title.text.trim().replace /\s+/, ' '

    anchors: ->
      new HTMLCollection @getElementsByTagName 'a'

    applets: ->
      new HTMLCollection @getElementsByTagName 'applet'

    images: ->
      new HTMLCollection @getElementsByTagName 'images'

    embeds: ->
      new HTMLCollection @getElementsByTagName 'embed'

    plugins: ->
      @embeds

    links: ->
      new HTMLCollection preorder(@).filter (node) ->
        /a(rea)?$/.test(node.tagName) and node.getAttribute 'href'

    forms: ->
      new HTMLCollection @getElementsByTagName 'form'

    scripts: ->
      new HTMLCollection @getElementsByTagName 'script'

    domain: ->
      URL.parse(@URL).host or null

    all: ->
      new HTMLCollection preorder @

    cookie: ->
      @_defaultView?._context.cookieJar.getCookieStringSync(@_URL) or ''

  @set
    cookie: (c) ->
      @_defaultView._setCookie c

    title: (t) ->
      return unless typeof t == 'string'
      head = @head
      return null unless head
      title = findFirstWithTag 'title', @
      unless title
        title = @createElement 'title'
        head.appendChild title
      title.text = t

  write: (text) ->
    #console.log 'starting parsing', text
    @_scriptsToExecuteAfterParsing.pause()
    @_isParsing = true
    if scriptEl = @currentScript
      @_parser.appendTo scriptEl._parentNode, text, =>
        @_isParsing = false
        console.log 'parsing stopped'
        parsingStopped @
    else
      @_parser.appendTo @, text, =>
        @_isParsing = false
        console.log 'parsing stopped'
        parsingStopped @

  writeln: (text) ->
    @write text + '\n'

  createElement: (localName) ->
    localName = localName.toLowerCase()
    unless getElementInterface?
      {getElementInterface} = require '../html/element'
    elementInterface = getElementInterface localName
    console.log 'element interface exists', elementInterface?
    el = new elementInterface @_parser, localName, HTML_NAMESPACE
    el._ownerDocument = @
    el

  createElementNS: (namespace, qualifiedName) ->
    [prefix, localName] = qualifiedName.split ' '
    if prefix and !namespace
      throw new DOMException NAMESPACE_ERR
    if prefix == 'xml' and namespace != XML_NAMESPACE
      throw new DOMException NAMESPACE_ERR
    if (qualifiedName == 'xmlns' or prefix == 'xmlns') and namespace != XMLNS_NAMESPACE
      throw new DOMException NAMESPACE_ERR
    if namespace == XMLNS_NAMESPACE and qualifiedName != 'xmlns' and prefix != 'xmlns'
      throw new DOMException NAMESPACE_ERR
    unless Element?
      {Element} = require './element'
    el = new Element localName, namespace, prefix
    el._ownerDocument = @
    el

  createDocumentFragment: ->
    fragment = new DocumentFragment
    fragment._ownerDocument = @
    fragment

  createTextNode: (data) ->
    textNode = new Text data
    textNode._ownerDocument = @
    textNode

  createComment: (data) ->
    comment = new Comment data
    comment._ownerDocument = @
    comment

  createProcessingInstruction: (target, data) ->
    if data.indexOf '?>'
      throw new DOMException INVALID_CHARACTER_ERR, "Data cannot contain '?>'"
    instruction = new ProcessingInstruction target, data
    instruction._ownerDocument = @
    instruction

  importNode: (node, deep = true) ->
    if node.nodeType == DOCUMENT_NODE
      throw new DOMException NOT_SUPPORTED_ERR, "Cannot import a document"

    clone node, @, deep

  adoptNode: (node) ->
    if node.nodeType == DOCUMENT_NODE
      throw new DOMException NOT_SUPPORTED_ERR, "Cannot adopt a document"

    adopt node, @

  createEvent: (eventInterfaceName) ->
    if eventInterface = getEventInterface eventInterfaceName
      return new eventInterface
    throw new DOMException NOT_SUPPORTED_ERR, "Event interface #{eventInterfaceName} is not supported"

  createRange: ->
    range = new Range @, 0, @, 0
    @_ranges.push range
    range

  createNodeIterator: (root, whatToShow, filter) ->
    new NodeIterator root, whatToShow, filter

  createTreeWalker: (root, whatToShow, filter) ->
    new TreeWalker root, whatToShow, filter

  getElementById: (elementId) ->
    @_idCache[elementId] or null

  getElementsByTagName: (localName) ->
    listElements localName.toLowerCase(), @

  getElementsByTagNameNS: (namespace, localName) ->
    listElementsNS namespace, localName.toLowerCase(), @

  getElementsByClassName: (classNames) ->
    listElementsByClass classNames, @

  getElementsByName: (name) ->
    new HTMLCollection preorder(@).filter (node) -> node.getAttribute and node.getAttribute('name') == name

  open: (args...) ->
    if args.length <= 2
      unless @isHTMLDocument
        throw new DOMException INVALID_STATE_ERR

      [type, replace] = args

      type ?= 'text/html'
      replace ?= ''

      replace = replace.toLowerCase() == 'replace'

      for node in descendantsInclusive @
        node._listeners = {}

      @_encoding = 'UTF-8'

      @_reloadOverride = true
      @_reloadOverrideBuffer = ''
      @_salvageable = true

      return @ if @_isParsing

      @defaultView._context.unloadDocument @

    #If the document has an active parser that isn't a script-created parser, and the insertion point associated with that parser's input stream is not undefined (that is, it does point to somewhere in the input stream), then the method does nothing. Abort these steps and return the Document object on which the method was invoked.

    #Prompt to unload the Document object. If the user refused to allow the document to be unloaded, then these steps must be aborted.

    else
      @defaultView.open args...

  clear: ->

  close: ->
    unless @isHTMLDocument
      throw new DOMException INVALID_STATE_ERR

  isHTMLDocument: yes
  isIFrameSrcDocument: no

  hasFocus: ->
    @defaultView?._focused or false

  getSelection: ->
    @defaultView?.getSelection() or null

  querySelector: (sel) ->
    @_nwmatcher.first sel, @

  querySelectorAll: (sel) ->
    new HTMLCollection @_nwmatcher.select sel, @

  click: ->

  serialize: ->
    {url: @URL, @contentType, @referrer, @lastModified, body: @documentElement.outerHTML}

  @events ['abort', 'blur', 'cancel', 'canplay', 'canplaythrough', 'change', 'click', 'close', 'contextmenu', 'cuechange', 'dblclick', 'drag', 'dragend', 'dragenter', 'dragleave', 'dragover', 'dragstart', 'drop', 'durationchange', 'emptied', 'ended', 'error', 'focus', 'input', 'invalid', 'keydown', 'keypress', 'keyup', 'load', 'loadeddata', 'loadedmetadata', 'loadstart', 'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup', 'mousewheel', 'pause', 'play', 'playing', 'progress', 'ratechange', 'reset', 'scroll', 'seeked', 'seeking', 'select', 'show', 'stalled', 'submit', 'suspend', 'timeupdate', 'volumechange', 'waiting', 'readystatechange']

class XMLDocument extends Document
  isHTMLDocument: no
  load: (url) ->
    changeReadyState @, 'loading'
    process.nextTick =>
      result = new Document
      success = false
      # Fetch url from the origin of document, with the synchronous flag set and the force same-origin flag set.

      changeReadyState @, 'complete'
      frag = @createDocumentFragment()
      frag._childNodes = result
      replaceAll frag, @
      fireSimpleEvent @, 'load'
    true

class DOMImplementation
  constructor: (@parent) ->

  createDocumentType: (qualifiedName, publicId, systemId) ->
    doctype = new DocumentType qualifiedName, publicId, systemId
    adopt doctype, @parent
    doctype

  createDocument: (namespace, qualifiedName, doctype) ->
    doc = new XMLDocument
    doc._createdByScript = true

    element = null

    if qualifiedName?.length > 0
      element = doc.createElementNS namespace, qualifiedName

    if doctype
      doc.appendChild doctype
    if element
      doc.appendChild element

    doc

  createHTMLDocument: (t) ->
    doc = new Document
    doc._createdByScript = true
    doc._contentType = "text/html"
    doctype = new DocumentType "html"
    doc.appendChild doctype
    html = doc.createElement "html"
    doc.appendChild html
    head = doc.createElement "head"
    html.appendChild head
    title = doc.createElement "title"
    title.textContent = t
    head.appendChild title
    body = doc.createElement "body"
    html.appendChild body
    doc

  hasFeature: -> yes

module.exports = {DocumentType, Document, DOMImplementation}
