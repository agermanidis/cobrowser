require '../dom/meta'

URL = require 'url'

{HTMLElement} = require './element'
{Document} = require '../dom/document'
{fireSimpleEvent} = require '../dom/dom_helpers'
{BrowserContext} = require '../context'

processIframeAttributes = (iframe) ->
  src = iframe.getAttribute 'src'
  srcdoc = iframe.getAttribute 'srcdoc'

  if srcdoc
    document = new Document url: 'about:srcdoc', contentType: 'text/html'
    document.write srcdoc
    url = title = 'about:srcdoc'
    iframe._context.loadDocument document
    iframe._context.history.pushNavigationEntry {document, url, title}

  else if !iframe._attributesProcessed or !src
    fireSimpleEvent iframe, 'load'

  else
    if src == '' or !iframe._attributesProcessed
      url = 'about:blank'
    else
      try
        url = URL.resolve iframe.ownerDocument.URL, src
      catch e
        url = 'about:blank'

    iframe._context.navigate url

  iframe._attributesProcessed = true

createNestedBrowsingContext = (iframe) ->
  new BrowserContext frameElement: iframe, parent: iframe.ownerDocument.defaultView._context

discardNestedBrowsingContext = (iframe) ->
  iframe._context?.close()

class HTMLFrameSetElement extends HTMLElement
  @reflect ['cols', 'rows']
  @events ['afterprint', 'beforeprint', 'beforeunload', 'blur', 'error', 'focus', 'hashchange', 'load', 'message', 'offline', 'online', 'pagehide', 'pageshow', 'popstate', 'resize', 'scroll', 'storage', 'unload']

class HTMLFrameElement extends HTMLElement
  @reflect ['name', 'scrolling', 'src', 'frameBorder', 'longDesc']
  @reflect bool: true, ['noResize']
  # todo

class HTMLIFrameElement extends HTMLElement
  @reflect ['src', 'srcdoc', 'name', 'seamless', 'width', 'height', 'align', 'scrolling', 'frameBorder', 'longDesc']
  @reflect treatNullAs: '', ['marginHeight', 'marginWidth']

  @get
    sandbox: -> new DOMTokenList @getAttribute('sandbox'), (newValue) => @setAttribute 'sandbox', newValue

    contentWindow: ->
      console.log 'retrieving content window', @_context?
      @_context?.window or null

    contentDocument: ->
      @contentWindow?.document or null

  constructor: (args...) ->
    super args...

    #console.log 'has document', @document?
    #throw new Error "creating frame"

    @addEventListener 'DOMNodeInsertedIntoDocument', (evt) =>
      throw new Error "inserted into document"
      @_context = createNestedBrowsingContext @
      processIframeAttributes @

    @addEventListener 'DOMNodeRemovedFromDocument', (evt) =>
      discardNestedBrowsingContext @

    @addEventListener 'DOMAttrModified', (evt) =>
      return unless @_context

      switch evt.attrName
        when 'name'
          @_context.name = evt.newValue

        when 'srcdoc', 'src'
          processIframeAttributes @


module.exports = {HTMLFrameElement, HTMLIFrameElement, HTMLFrameSetElement}
