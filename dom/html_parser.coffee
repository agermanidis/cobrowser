htmlparser = require 'htmlparser'
{HTMLDecode} = require 'jsdom'

{ELEMENT_NODE, TEXT_NODE} = require './node'
{DOMException} = require './exceptions'
{preInsert} = require './dom_operations'

#todo: set parser
appendDOM = (dom, parent, document, inBody, reference = null, ignoreLock = false) ->
  console.log 'appendDOM', parent?

  for child in dom
    document._scriptParsingLock.whenUnlocked ->
      childNode = switch child.type
        when 'tag', 'script', 'style'
          if child.name.toLowerCase() == 'body'
            inBody = true
          document.createElement child.name
        when 'directive'
          if child.name == '!doctype'
            document.implementation.createDocumentType child.data.split(' ')[1] or ''
          else null
        when 'text'
          #data = child.data.replace '\n', ''
          if parent.nodeType == ELEMENT_NODE
            if inBody or child.data.replace(/(\n|\r|\s)/g, '').length
              #console.log 'text!', child.data, child.data.length
              if parent.tagName == 'SCRIPT'
                document.createTextNode child.data
              else
                document.createTextNode HTMLDecode child.data

        when 'comment'
          console.log "COMMENT FOUND", parent._address, child.data
          if parent.nodeType == ELEMENT_NODE and parent.tagName == 'SCRIPT'
            console.log "HAHAHA!"
            document.createTextNode child.data
          else
            document.createComment child.data
        else null

      return unless childNode

      if attrs = child.attribs
        for name, value of attrs
          #console.log {name, value}
          childNode.setAttribute name, HTMLDecode(value).toString()

      if ignoreLock
        preInsert childNode, parent, reference

        if children = child.children
          appendDOM children, childNode, document, inBody

      else
        document._scriptParsingLock.whenUnlocked ->
          preInsert childNode, parent, reference

          if children = child.children
            appendDOM children, childNode, document, inBody

createDOM = (dom, document, cb) ->
  console.log 'createdom'

  fragment = document.createDocumentFragment()

  for child in dom

    childNode = switch child.type
      when 'tag', 'script', 'style'
        document.createElement child.name
      when 'directive'
        if child.name == '!doctype'
          document.implementation.createDocumentType child.data.split(' ')[1] or ''
        else null
      when 'comment'
        document.createComment child.data
      else null

    continue unless childNode

    if attrs = child.attribs
      for name, value of attrs
        childNode.setAttribute name, HTMLDecode(value)

    fragment.appendChild childNode

    if children = child.children
      appendDOM children, childNode, document

    #childNodes.push childNode

  cb? null, fragment

createDocumentParser = (document) ->
  done = (err, dom) ->
    if err then throw new DOMException
    else appendDOM dom, document, document

  doneForEl = (el, reference, ignoreLock) ->
    (err, dom) ->
      if err then throw new DOMException
      else appendDOM dom, el, document, reference, ignoreLock

  parseDone = (cb) ->
    (err, dom) ->
      if err then cb err
      else createDOM dom, document, cb

  handler = new htmlparser.DefaultHandler done, verbose: false
  parser = new htmlparser.Parser handler

  parserObj =
    active: false
    block: ->
    resume: ->

  parserObj.appendTo = (el, html, cb) ->
    return if @active
    @active = true

    elHandler = new htmlparser.DefaultHandler doneForEl(el).bind(@), verbose: false
    elParser = new htmlparser.Parser elHandler
    elParser.parseComplete html

    @active = false

    cb?()

  parserObj.insertBefore = (parentEl, referenceEl, html, cb) ->
    return if @active
    @active = true

    elHandler = new htmlparser.DefaultHandler doneForEl(parentEl, referenceEl, true).bind(@), verbose: false
    elParser = new htmlparser.Parser elHandler
    elParser.parseComplete html

    @active = false

    cb?()

  parserObj.parse = (html, cb) ->
    return if @active
    @active = true

    handler = new htmlparser.DefaultHandler parseDone(cb), verbose: false
    parser = new htmlparser.Parser handler
    parser.parseComplete html

    @active = false

  parserObj

appendHTML = (html, node, document) ->
  done = (err, dom) ->
    if err then throw new DOMException
    else appendDOM dom, node, document

  handler = new htmlparser.DefaultHandler done, verbose: false
  parser = new htmlparser.Parser handler
  parser.parseComplete html


module.exports = {appendHTML, createDocumentParser}
