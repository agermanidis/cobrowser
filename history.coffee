URL_ = require 'url'
uuid = require 'node-uuid'

{Document} = require './dom/document'

sameURL = (one, two) ->
  one = URL_.parse one
  two = URL_.parse two
  one.protocol == two.protocol and one.host == two.host and one.path == two.path and one.hash == two.hash

# deep clone
cloneObj = (obj) ->
  encountered = []

  clone = (o) ->
    copy = {}
    for k, v of o
      if typeof v == 'object'
        if v in encountered
          throw new Error
        copy[k] = clone v
        encountered.push v
      else
        copy[k] = v
    copy

  clone obj

class History
  constructor: (@context, @entries = [], @index = -1) ->

  isEmpty: ->
    !@entries.length

  visited: ->
    urls = []
    for {url} in @entries
      urls.push url
    urls

  length: ->
    @entries.length

  hasPreviousEntries: ->
    @index != 0

  hasNextEntries: ->
    @index != @length() - 1

  state: ->
    @entries[@index].data or null

  setEntry: (entry) ->
    entry.id = uuid()
    @entries[@index] = entry
    @context.sessionChanged()

  changeLocation: (url, replacement = no, absolute = no, cb) ->
    if @currentURL() and sameURL url, @currentURL()
      return @reload()

    if @length() == 0
      resolved = URL_.parse url
      current = URL_.parse ""

    else
      if absolute
        resolved = URL_.parse url
      else
        resolved = URL_.resolveObject @currentURL(), url

      current = @currentURLObj()

    url = URL_.format(resolved)

    if resolved.protocol != current.protocol or resolved.host != current.host or resolved.path != current.path
      referrer = @currentURL()
      @navigate {url, referrer}, (document) =>
        title = document.title or resolved.host + (resolved.path or "") + (resolved.hash or "")
        @index++ unless replacement
        @setEntry
          data: null
          title: title
          url: url
          document: document
          pop: false
        cb?()

    else
      title = @currentTitle()
      document = @currentDocument()
      @index++ unless replacement
      @setEntry
        data: null
        title: title
        url: url
        document: document
        pop: false

      if resolved.hash != current.hash
        @hashChangeEvent current.url, resolved.url

      cb?()

  submitForm: (method, url, formData, enctype, boundary) ->
    if /multipart/.test enctype
      contentType = "#{enctype}; boundary=#{boundary}"
    else
      contentType = enctype

    #console.log "SUBMITTING DATA: ", formData.map (x) -> x.toString()
    #console.log "data:", contentType, formData

    @navigate {method, url, formData, contentType, referrer: @currentDocument().URL}, (document) =>
      title = document.title
      @index++
      @setEntry
        data: null
        title: title
        url: url
        document: document
        pop: false

  navigate: ({url, referrer, formData, contentType, method}, cb) ->
    return unless @promptToUnload()

    context = @context
    resourceManager = context.resourceManager
    currentDocument = @currentDocument()

    context.emit 'status-changed', "Navigating to #{URL_.parse(url).host}..."

    context.abortDocument currentDocument if currentDocument
    context.unloadDocument currentDocument if currentDocument

    console.log 'navigate', {url, referrer, formData, contentType, method}
    resourceManager.fetchResource {url, referrer, formData, contentType, method}, (err, resp) ->

      if resp
        {contentType, lastModified, body} = resp

      console.log 'ERR FFFF', err
      context.createDocument {err, referrer, body, url, contentType, lastModified},  (err, document) ->
        context.loadDocument document
        cb? document

  assign: (url, absolute = no, cb = ->) ->
    @changeLocation url, no, absolute, cb

  replace: (url) ->
    @changeLocation url, yes

  reload: ->
    url = @currentURL()
    @navigate {url}, (document) =>
      title = document.title or url
      @setEntry
        data: null
        title: title
        url: url
        document: document
        pop: false

  promptToUnload: ->
    window = @context.window
    return true unless window

    ev = window.document.createEvent "BeforeUnloadEvent"
    ev.initEvent "beforeunload", false, true
    ev._returnValue = ""
    success = window.dispatchEvent ev
    {returnValue} = ev

    if (not success) or returnValue != ""
      if typeof returnValue == "string" and returnValue != ""
        promptReply = window.prompt returnValue
      else
        promptReply = window.prompt "Are you sure you want to navigate away from the page?"

      return false unless promptReply

    true

  go: (delta) ->
    if delta == 0 or (not delta)
      return @reload()

    index = @index + delta

    hashChanged = false
    stateChanged = false

    return if index < 0 or index >= @length()

    currentEntry = @entries[@index]
    entry = @entries[index]

    if currentEntry.document != entry.document
      return unless @promptToUnload()
      @context.unloadDocument @currentDocument()

    @index = index

    unless @loadedDocument()
      unless entry.document
        @navigate url: entry.url
      @context.loadDocument entry.document

    unless entry.pop
      entry.title = entry.document.title

    currentEntryHash = URL_.parse(currentEntry.url).hash
    entryHash = URL_.parse(entry.url).hash

    if currentEntry.document == entry.document and currentEntryHash != entryHash
      @hashChangeEvent currentEntry.url, entry.url

    direction = if delta > 0 then 'forward' else 'backward'
    @context.sessionChanged direction

  hashChangeEvent: (oldURL, newURL) ->
    window = @context.window
    return unless window
    ev = window.document.createEvent "HashChangeEvent"
    ev.initEvent "hashchange", true, false
    ev._oldURL = oldURL
    ev._newURL = newURL
    window.dispatchEvent ev

  back: ->
    @go -1

  forward: ->
    @go 1

  popState: ->
    current = @currentEntry()
    if current.pop
      return unless @popStateEvent()
      @index--
      for index in [@index + 1..@length() - 1]
        delete @entries[index]
      current.data
    else
      throw "DOM Exception 18"

  pushState: (data = null, title = @currentTitle()) =>
    @index++
    @setEntry pop: true, data, title, url: @currentURL(), document: @currentDocument()

  pushNavigationEntry: ({document, title, url}) =>
    @index++
    @setEntry {url, document, pop: false, data: null, title: document.title}

  replaceState: (data = null, title = @currentTitle()) =>
    @setEntry pop: true, data, title, url: @currentURL(), document: @currentDocument()

  clone: (context) ->
    clonedEntries = []

    for {data, title, url, document, pop} in @entries
      clonedEntry =
        data: cloneObj data
        title: title
        url: url
        document: document.cloneNode()
        pop: pop
      clonedEntries.push clonedEntry

    new History context, clonedEntries, @index

  currentEntry: ->
    @entries[@index]

  currentURL: ->
    #console.log @entries, @index
    console.log 'receiving current url', @entries[@index]?.url
    @entries[@index]?.url

  currentURLObj: ->
    try
      URL_.parse @entries[@index]?.url
    catch e
      null

  currentEntryId: ->
    @entries[@index].id

  currentURLHash: ->
    @currentURLObj()?.hash

  currentTitle: ->
    @entries[@index]?.title

  currentDocument: ->
    @entries[@index]?.document

  loadedDocument: ->
    @context.document

  serialize: ->
    serializedEntries = @entries.map ({data, title, url, document, pop}) ->
      {data, title, url, document: document.serialize(), pop}
    JSON.stringify {entries: serializedEntries, @index}

  @deserialize: (serializedHistory) ->
    if typeof serializedHistory == 'string'
      {entries, index} = JSON.parse serializedHistory
    else
      {entries, index} = serializedHistory

    deserializedEntries = entries.map (entry) ->
      {data, title, url, pop, document} = entry
      {url, contentType, referrer, lastModified, body} = entry.document

      document = new Document {url, contentType, referrer, lastModified}
      document.write body

      {data, title, url, document, pop}

    {index, entries: deserializedEntries}

module.exports = {History}
