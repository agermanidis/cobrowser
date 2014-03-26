require '../dom/meta'

{parse} = require 'cssom'
{MediaList} = require './medialist'

serializeRule = (rule) ->
  #switch rule.type

class CSSRule
  STYLE_RULE: 1
  CHARSET_RULE: 2
  IMPORT_RULE: 3
  MEDIA_RULE: 4
  FONT_FACE_RULE: 5
  PAGE_RULE: 6
  NAMESPACE_RULE: 10

  @get
    parentRule: ->
    cssText: ->

  @set
    cssText: (val) ->


class CSSStyleRule extends CSSRule
  type: CSSRule.STYLE_RULE

class CSSCharsetRule extends CSSRule
  type: CSSRule.CHARSET_RULE

class CSSImportRule extends CSSRule
  type: CSSRule.IMPORT_RULE
  @readonly ['href', 'styleSheet']
  @get media: -> @_styleSheet.media
  @constructor: (@_href, @_styleSheet) ->

class CSSMediaRule extends CSSRule
  type: CSSRule.MEDIA_RULE

class CSSFontFaceRule extends CSSRule
  type: CSSRule.FONT_FACE_RULE

class CSSPageRule extends CSSRule
  type: CSSRule.PAGE_RULE

class CSSNamespaceRule extends CSSRule
  type: CSSRule.NAMESPACE_RULE
  @readonly ['namespaceURI', 'prefix']
  @constructor: (@_namespaceURI, @_prefix = '') ->

styleInterfaces =
  1: CSSStyleRule
  2: CSSCharsetRule
  3: CSSImportRule
  4: CSSMediaRule
  5: CSSFontFaceRule
  6: CSSPageRule
  10: CSSNamespaceRule

module.exports = {CSSRule, CSSStyleRule, CSSCharsetRule, CSSImportRule, CSSMediaRule, CSSFontFaceRule, CSSPageRule, CSSNamespaceRule}
