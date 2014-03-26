require '../dom/meta'

URL = require 'url'
fs = require 'fs'

{HTMLElement} = require './element'
{TEXT_NODE} = require '../dom/node'
{stripLeadingAndTrailingWhitespace, mapcat} = require '../dom/helpers'
{fireSimpleEvent, isPartOfDocument} = require '../dom/dom_helpers'

finishScriptPreparation = (script, err, body, type, externalFile = true) ->
  return unless body
  console.log 'finishScriptPreparation', body[0..50]

  src = script.getAttribute 'src'
  defer = script.getAttribute 'defer'
  async = script.getAttribute 'async'
  document = script.ownerDocument

  console.log "CHOOSING"

  if src and defer and !async # and script._parserInserted
    document._scriptsToExecuteAfterParsing.enqueue (done) ->
      executeScriptBlock script, err, body, type, externalFile
      done()

  else if src and !async #and script._parserInserted
    # The element is the pending parsing-blocking script of the Document of the parser that created the element. (There can only be one such script per Document at a time.)

    # document._parser.block()
    # executeScriptBlock()
    # document._parser.unblock()

    document._scriptParsingLock.lock()
    executeScriptBlock script, err, body, type, externalFile
    document._scriptParsingLock.unlock()

    # document._scriptsToExecuteAfterParsing.enqueue (done) ->
    #   executeScriptBlock script, err, body, type, externalFile
    #   done()

  else if !src and script._parserInserted and document._blockingStylesheet
    # document._parser.block()
    # executeScriptBlock()
    # document._parser.unblock()

    document._scriptsToExecuteAfterParsing.enqueue (done) ->
      executeScriptBlock script, err, body, type, externalFile
      done()

  else if src and !async and script._forceAsync
    document._scriptsToExecuteASAP.enqueue (done) =>
      executeScriptBlock script, err, body, type, externalFile
      done()

  else if src
    document._scriptsToExecuteASAP.enqueue (done) =>
      executeScriptBlock script, err, body, type, externalFile
      done()

  else
    # document._scriptsToExecuteASAP.enqueue (done) ->
    #   executeScriptBlock script, err, body, externalFile
    #   done()
    executeScriptBlock script, err, body, type, externalFile

prepareScript = (script) ->
  console.log 'trying to prepare script', script._address

  return if script._alreadyStarted or !script.ownerDocument.defaultView

  console.log 'preparing script', script._address, script.src, script.text

  if script._parserInserted
    wasParserInserted = true
    script._parserInserted = false

  if wasParserInserted and !script.getAttribute('async')
    script._forceAsync = true

  src = script.src
  text = script.text

  return unless src.length or text.replace(/(\n|\r)/g, '').length
  return unless document = script.ownerDocument

  type = script.getAttribute('type')
  lang = script.getAttribute('language')

  if type and type == '' or !type and lang == '' or !type and !lang
    scriptBlockType = 'text/javascript'
  else if type
    scriptBlockType = type.trim()
  else
    scriptBlockType = "text/#{lang}"

  if wasParserInserted
    script._parserInserted = true
    script._forceAsync = false

  script._alreadyStarted = true
  return if script._parserInserted and document != script._parser.document

  eventAttr = script.getAttribute 'event'
  forAttr = script.getAttribute 'for'

  if eventAttr and forAttr
    eventAttr = eventAttr.trim().toLowerCase()
    forAttr = forAttr.trim().toLowerCase()

    return unless forAttr == 'window'
    return unless /^onload(\(\))?$/.test eventAttr

  if charset = script.getAttribute 'charset'
    script._characterEncoding = charset
  else
    script._fallbackCharacterEncoding = script.ownerDocument.encoding

  src = script.getAttribute 'src'

  #return unless document._active

  if src and src != ''
    src = URL.resolve document.URL, src
    document._scriptPreparationQueue.enqueue (done) ->
      return unless document.defaultView
      document.defaultView._fetch src, (err, body) ->
        done()
        finishScriptPreparation script, err, body, scriptBlockType, true

  else if src == ''
    return fireSimpleEvent script, 'error'

  else
    document._scriptPreparationQueue.enqueue (done) ->
      done()
      finishScriptPreparation script, null, script.text, scriptBlockType, false

logScriptError = (body, e, cb) ->
  data = e.toString() + '\n\n' + body
  fs.writeFile 'script_error.log', data.toString('utf8'), (err) ->
    cb err

isDebugEnabled = (script) ->
  context = script.ownerDocument.defaultView._context
  context?.debugScript or no

handleError = (err, script) ->
  unless isDebugEnabled
    throw e
    fireSimpleEvent script, 'error'

executeScriptBlock = (script, err, body, type, externalFile = false) ->
  document = script.ownerDocument

  return if script._parserInserted and document.ownerDocument != script._parser.document

  if err
    return fireSimpleEvent script, 'error'

  canContinue = fireSimpleEvent script, 'beforescriptexecute', true, true
  return unless canContinue

  if externalFile
    document._ignoreDestructiveWritesCounter++

  #return unless script._ownerDocument._active

  if type == 'text/javascript' and body
    document.currentScript = script
    try
      console.log 'running', body[0..50]
      #console.log 'running', body
      document.defaultView?.run body
    catch e
      console.log 'e to string', e.toString()
      # try to decomment
      trimmed = body.trim()
      if trimmed.indexOf("<!--") == 0 and trimmed.lastIndexOf("-->") == trimmed.length - 3
        try
          document.defaultView?.run trimmed[4..-4]
        catch e
          logScriptError body, e, (err) ->
            handleError err, script
      else
        logScriptError body, e, (err) ->
          handleError err, script

    document.currentScript = null

  if externalFile
    document._ignoreDestructiveWritesCounter--

  fireSimpleEvent script, 'afterscriptexecute', true
  fireSimpleEvent script, 'load'

class HTMLScriptElement extends HTMLElement
  @reflect treatNullAs: '', ['src', 'type', 'charset', 'event', 'htmlFor']
  @reflect bool: true, ['async', 'defer']

  @define
    text:
      get: ->
        textNodes = @_childNodes.filter (node) -> node.nodeType == TEXT_NODE
        mapcat textNodes, (textNode) -> textNode.data
      set: (t) ->
        @textContent = t

  constructor: (args...) ->
    @addEventListener 'DOMNodeInsertedIntoDocument', =>
      prepareScript @

    @addEventListener 'DOMSubtreeModified', =>
      return unless isPartOfDocument @
      prepareScript @

    @addEventListener 'DOMAttrModified', ({attrName, prevValue}) =>
      return unless isPartOfDocument @
      if attrName == 'src' and !prevValue?.length
        console.log 'attr modified'
        prepareScript @

    super args...

module.exports = {HTMLScriptElement}
