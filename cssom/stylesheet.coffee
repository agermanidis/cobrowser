require '../dom/meta'

{parse} = require 'cssom'

class Stylesheet
  @readonly ['type', 'href', 'ownerNode', 'parentStyleSheet', 'title', 'media']

  constuctor: (@_type, @_href, @_ownerNode, @_parentStylesheet, @_title, @_media) ->
    @disabled = false

class CSSStyleSheet extends Stylesheet
  @readonly ['ownerRule', 'cssRules']

  constructor: (args..., @_ownerRule) ->
    super args...
    @_cssRules = []

  insertRule: (text, index) ->
    newRule = parse text
    if index < 0 then throw DOMException INDEX_SIZE_ERR
    n = @_cssRules.length
    if index >= n then throw DOMException INDEX_SIZE_ERR
    newRule.parentStylesheet = @
    @_cssRules.splice index, 0, newRule
    index

  deleteRule: (index) ->
    if index < 0 then throw DOMException INDEX_SIZE_ERR
    n = @_cssRules.length
    if index >= n then throw DOMException INDEX_SIZE_ERR
    oldRule = @_cssRules[index]
    oldRule.parentStylesheet = null
    @_cssRules.splice index, 1
    return

  toString: ->
    ret = ''
    for rule in @_cssRules
      ret += rule.cssText + '\n'
    ret

module.export = {CSSStyleSheet}
