getElementInterface = (tag) ->
  elementInterfaces[tag.toLowerCase()] or HTMLUnknownElement

module.exports = {getElementInterface}

{ELEMENT_NODE, TEXT_NODE, DOCUMENT_NODE, DOCUMENT_FRAGMENT_NODE} = require '../dom/node'
{DOMException, NO_MODIFICATION_ALLOWED_ERR} = require '../dom/exceptions'
{mapcat} = require '../dom/helpers'
{Element} = require '../dom/element'
{NodeList, HTMLCollection} = require '../dom/collections'
{ancestors, findAncestor} = require '../dom/tree_operations'
{insert, append, replaceAll, replace, remove} = require '../dom/dom_operations'
{CSSStyleDeclaration, updateDeclaration} = require '../cssom/styledeclaration'
{ClientRect} = require '../cssom/clientrect'
{serializeNode} = require '../dom/dom_serialize'
{HTML_NAMESPACE} = require '../dom/namespaces'
{fireSimpleEvent} = require '../dom/dom_helpers'

class HTMLElement extends Element
  @reflect bool: true, ['hidden']

  constructor: (@_parser, args...) ->
    @addEventListener 'DOMAttrModified', ({attrName, newValue}) =>
      if attrName == 'style'
        #console.log 'updating style', {attrName, newValue}
        updateDeclaration @style, newValue

    super args...

  focus: ->
    fireSimpleEvent @, 'focus', false, false
    fireSimpleEvent @, 'focusin', true, false
    if document = @ownerDocument
      document._activeElement = @

  blur: ->
    fireSimpleEvent @, 'blur', false, false
    fireSimpleEvent @, 'focusout', true, false

  @define
    innerHTML:
      get: ->
        ret = ''
        for child in @_childNodes
          ret += serializeNode child
        ret

      set: (text) ->
        @_parser.parse text, (err, fragment) =>
          throw new err if err
          replaceAll fragment, @
        text

    outerHTML:
      get: ->
        serializeNode @

      set: (text) ->
        parent = @parentNode
        document = @ownerDocument

        if parent
          if parent.nodeType == DOCUMENT_NODE
            throw new DOMException NO_MODIFICATION_ALLOWED_ERR
          if parent.nodeType == DOCUMENT_FRAGMENT_NODE
            parent = document.createElement 'body'
            parent._ownerDocument = document

        @_parser.parse text, (err, fragment) =>
          throw err if err
          replace @, fragment, parent

        text

  insertAdjacentHTML: (position, text) ->
    switch position
      when 'beforebegin', 'afterend'
        context = @parentNode
        if !context or context.nodeType == DOCUMENT_NODE
          throw new DOMException NO_MODIFICATION_ALLOWED_ERR
      when 'afterbegin', 'beforeend'
        context = @

    return unless context

    document = context.ownerDocument

    if context.nodeType != ELEMENT_NODE or document.isHTMLDocument and context.localName == 'html' and context.namespaceURI == HTML_NAMESPACE
      context = document.createElement 'body'
      context._namespaceURI = HTML_NAMESPACE

    @_parser.parse text, (err, fragment) ->
      throw err if err

      switch position
        when 'beforebegin'
          insert fragment, context.parentNode, context
        when 'afterbegin'
          insert fragment, context, context.firstChild
        when 'beforend'
          append fragment, context
        when 'afterend'
          insert fragment, context.parentNode, context.nextSibling

    return

  @get
    offsetParent: ->
    style: ->
      #console.log 'TRYINA GET STYLE', @_address, @_style
      unless @_style
        @_style = new CSSStyleDeclaration @getAttribute('style'), (newValue) =>
          @setAttribute 'style', newValue
      @_style

  click: ->
    @parentNode.click()

  getBoundingClientRect: ->
    new ClientRect 0, 0, 0, 0

  @get isContentEditable: ->
    current = @
    while current
      if current.nodeType == DOCUMENT_NODE
        return true if current.designMode == 'on'
        return false if current.designMode == 'off'

      return true if @_contentEditable == 'true'
      return false if @_contentEditable == 'false'

      current = current.parentNode

  @define
    contentEditable:
      get: ->
        @_contentEditable or "inherit"
      set: (v) ->
        return unless /(true|false|inherit)/.test v
        @_contentEditable = v

  @events ['abort', 'blur', 'cancel', 'canplay', 'canplaythrough', 'change', 'click', 'close', 'contextmenu', 'cuechange', 'dblclick', 'drag', 'dragend', 'dragenter', 'dragleave', 'dragover', 'dragstart', 'drop', 'durationchange', 'emptied', 'ended', 'error', 'focus', 'input', 'invalid', 'keydown', 'keypress', 'keyup', 'load', 'loadeddata', 'loadedmetadata', 'loadstart', 'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup', 'mousewheel', 'pause', 'play', 'playing', 'progress', 'ratechange', 'reset', 'scroll', 'seeked', 'seeking', 'select', 'show', 'stalled', 'submit', 'suspend', 'timeupdate', 'volumechange', 'waiting']

module.exports = {HTMLElement}

class HTMLAppletElement extends HTMLElement
  @reflect ['align', 'alt', 'archive', 'code', 'codeBase', 'height', 'hspace', 'name', 'object', 'vspace', 'and', 'width']

class HTMLBaseElement extends HTMLElement
  @reflect ['href', 'target']

class HTMLBodyElement extends HTMLElement
  @events ['afterprint', 'beforeprint', 'beforeunload', 'blur', 'error', 'focus', 'hashchange', 'load', 'message', 'offline', 'online', 'popstate', 'pagehide', 'pageshow', 'resize', 'scroll', 'storage', 'unload']
  @reflect ['background']
  @reflect treatNullAs: '', ['text', 'link', 'vLink', 'aLink', 'bgColor']

  click: ->

class HTMLBRElement extends HTMLElement
  @reflect ['clear']

class HTMLButtonElement extends HTMLElement

class HTMLDivElement extends HTMLElement
  @reflect ['align']

class HTMLDListElement extends HTMLElement
  @reflect ['compact']

class HTMLEmbedElement extends HTMLElement
  @reflect ['align', 'name']

class HTMLFontElement
  @reflect [{treatNullAs: '', attr: 'color'}, 'face', 'size']

class HTMLHtmlElement extends HTMLElement
  @reflect ['version']

class HTMLPreElement extends HTMLElement
  @reflect ['width']

class HTMLQuoteElement extends HTMLElement
  @reflect ['cite']

class HTMLOListElement extends HTMLElement
  @reflect ['reversed', 'start', 'type', {bool: true, attr: 'compact'}]

class HTMLSpanElement extends HTMLElement

class HTMLLegendElement extends HTMLElement
  @reflect ['align']
  @get form: ->
    fieldset = findAncestor (node) -> node.tagName == 'fieldset'
    fieldset?.form or null

class HTMLLIElement extends HTMLElement
  @reflect ['type', 'value']

class HTMLMenuElement extends HTMLElement
  @reflect ['type', 'label', {bool: true, attr: 'compact'}]

class HTMLMetaElement extends HTMLElement
  @reflect ['name', {prop: 'httpEquiv', attr: 'http-equiv'}, 'content', 'scheme']

  constructor: (args...) ->
    @addEventListener 'DOMNodeInsertedIntoDocument', (event) ->
      switch @httpEquiv
        when 'content-language'
          return if !@content or !@content.length or @content?.indexOf(',') != -1
          input = @content
          #todo

    super args...

class HTMLTitleElement extends HTMLElement
  @define
    text:
      get: ->
        textNodes = @_childNodes.filter (node) -> node.nodeType == TEXT_NODE
        mapcat textNodes, (textNode) -> textNode.data
      set: (t) ->
        @textContent = t

class HTMLHeadElement extends HTMLElement

class HTMLHeadingElement extends HTMLElement
  @reflect ['align']

class HTMLCommandElement extends HTMLElement
  @reflect ['label', 'icon', 'radiogroup']
  @reflect bool: true, ['disabled', 'checked']

class HTMLDataListElement extends HTMLElement
  @get options: -> new HTMLCollection @getElementsByTagName 'script'

class HTMLDListElement extends HTMLElement
  @reflect bool: true, ['compact']

class HTMLModElement extends HTMLElement
  @reflect ['cite', 'dateTime']

class HTMLDetailsElement extends HTMLElement
  @reflect bool: true, ['open']

class HTMLDialogElement extends HTMLElement
  @reflect [{bool: true, attr: 'open'}, 'returnValue']

class HTMLHRElement extends HTMLElement
  @reflect [{bool: true, attr: 'noShade'}, 'align', 'color', 'size', 'width']

class HTMLMapElement extends HTMLElement
  @reflect ['name']
  @get
    areas: -> @getElementsByTagName 'area'
    images: -> @getElementsByTagName 'image'

class HTMLObjectElement extends HTMLElement
  @reflect ['align', 'archive', 'code', 'hspace', 'vspace']
  @reflect bool: true, ['declare']
  @reflect treatAsNull: '', ['border']

class HTMLParagraphElement extends HTMLElement
  @reflect ['align']

class HTMLParamElement extends HTMLElement
  @reflect ['type', 'valueType']

class HTMLProgressElement extends HTMLElement
  @reflect ['value', 'max']
  @get
    position: -> @value / @max
    labels: ->
      ret = []
      for descendant in preorder @ownerDocument
        if descendant.tagName == 'label'
          if isAncestorOf(descendant, @) or descendant.getAttribute('for') == @id
            ret.push descendant
      new NodeList ret

class HTMLTimeElement extends HTMLElement
  @reflect ['datetime']

class HTMLUListElement extends HTMLElement
  @reflect [{bool: true, attr: 'compact'}, 'type']

class HTMLUnknownElement extends HTMLElement

{HTMLAnchorElement} = require './anchor'
{HTMLAudioElement, HTMLVideoElement, HTMLTrackElement, HTMLSourceElement} = require './media'
{HTMLAreaElement} = require './area'
{HTMLCanvasElement} = require './canvas'
{HTMLTableElement, HTMLTableCaptionElement, HTMLTableColElement, HTMLTableRowElement, HTMLTableDataCellElement, HTMLTableSectionElement, HTMLTableHeaderCellElement} = require './table'
{HTMLFieldSetElement, HTMLFormElement, HTMLLabelElement, HTMLInputElement, HTMLKeygenElement, HTMLMeterElement, HTMLOptGroupElement, HTMLOptionElement, HTMLOutputElement, HTMLSelectElement, HTMLTextAreaElement} = require './form'
{HTMLFrameElement, HTMLIFrameElement, HTMLFrameSetElement} = require './frame'
{HTMLScriptElement} = require './script'
{HTMLImageElement} = require './image'
{HTMLStyleElement, HTMLLinkElement} = require './style'

elementInterfaces =
  a: HTMLAnchorElement
  abbr: HTMLElement
  address: HTMLElement
  area:	HTMLAreaElement
  article: HTMLElement
  aside: HTMLElement
  audio: HTMLAudioElement
  b: HTMLElement
  base: HTMLBaseElement
  bdi: HTMLElement
  bdo: HTMLElement
  blockquote:	HTMLQuoteElement
  body:	HTMLBodyElement
  br:	HTMLBRElement
  button:	HTMLButtonElement
  canvas:	HTMLCanvasElement
  caption: HTMLTableCaptionElement
  cite: HTMLElement
  code:	HTMLElement
  col: HTMLTableColElement
  colgroup: HTMLTableColElement
  command: HTMLCommandElement
  datalist: HTMLDataListElement
  dd: HTMLElement
  del: HTMLModElement
  details: HTMLDetailsElement
  dfn: HTMLElement
  dialog: HTMLDialogElement
  div: HTMLDivElement
  dl: HTMLDListElement
  dt: HTMLElement
  em: HTMLElement
  embed: HTMLEmbedElement
  fieldset: HTMLFieldSetElement
  figcaption: HTMLElement
  figure: HTMLElement
  footer: HTMLElement
  form: HTMLFormElement
  h1: HTMLHeadingElement
  h2: HTMLHeadingElement
  h3: HTMLHeadingElement
  h4: HTMLHeadingElement
  h5: HTMLHeadingElement
  h6: HTMLHeadingElement
  head: HTMLHeadElement
  header: HTMLElement
  hgroup: HTMLElement
  hr: HTMLHRElement
  html: HTMLHtmlElement
  i: HTMLElement
  iframe: HTMLIFrameElement
  img: HTMLImageElement
  input: HTMLInputElement
  ins: HTMLModElement
  kbd: HTMLElement
  keygen: HTMLKeygenElement
  label: HTMLLabelElement
  legend: HTMLLegendElement
  li: HTMLLIElement
  link: HTMLLinkElement
  map: HTMLMapElement
  mark: HTMLElement
  menu: HTMLMenuElement
  meta: HTMLMetaElement
  meter: HTMLMeterElement
  nav: HTMLElement
  noscript: HTMLElement
  object: HTMLObjectElement
  ol: HTMLOListElement
  optgroup: HTMLOptGroupElement
  option: HTMLOptionElement
  output: HTMLOutputElement
  p: HTMLParagraphElement
  param: HTMLParamElement
  pre: HTMLPreElement
  progress: HTMLProgressElement
  q: HTMLQuoteElement
  rp: HTMLElement
  rt: HTMLElement
  ruby: HTMLElement
  s: HTMLElement
  samp: HTMLElement
  script: HTMLScriptElement
  section: HTMLElement
  select: HTMLSelectElement
  small: HTMLElement
  source: HTMLSourceElement
  span: HTMLSpanElement
  strong: HTMLElement
  style: HTMLStyleElement
  sub: HTMLElement
  summary: HTMLElement
  sup: HTMLElement
  table: HTMLTableElement
  tbody: HTMLTableSectionElement
  td: HTMLTableDataCellElement
  textarea: HTMLTextAreaElement
  tfoot: HTMLTableSectionElement
  th: HTMLTableHeaderCellElement
  thead: HTMLTableSectionElement
  time: HTMLTimeElement
  title: HTMLTitleElement
  tr: HTMLTableRowElement
  track: HTMLTrackElement
  u: HTMLElement
  ul: HTMLUListElement
  var: 	HTMLElement
  video: HTMLVideoElement
  wbr: HTMLElement

module.exports.HTMLElement = HTMLElement
