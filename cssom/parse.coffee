{CSSStyleRule, CSSCharsetRule, CSSImportRule, CSSMediaRule, CSSFontFaceRule, CSSPageRule, CSSNamespaceRule} = require './rule'
{CSSStyleSheet} = require './stylesheet'

isRegexp = (r) -> r instanceof RegExp
isString = (s) -> typeof s == 'string'

class ParseBuffer
  constructor: (@contents) ->
    @index = 0

  current: -> @contents[@index]
  following: -> @contents[@index..]

  eat: (s) ->
    if isString s
      if @contents.indexOf(string) == @index
        @index += string.length
      else
        null

    else if Array.isArray s
      for c in s
        break if @eat c

    # else if isRegexp s
    #   match = @following().match s
    #   return null unless match
    #   matchString = match[0]
    #   {index} = match
    #   @index += (@index - index) + matchString.length

  eatWhile: (s, accum = '') ->
    if accum += @eat s
      return @eatWhile s, accum
    accum

  eatUntil: (s, accum = '') ->
    unless accum += @eat s
      return @eatUntil s, accum
    accum

  peek: (string) ->
    @contents.indexOf(string) == @index

BEFORE_SELECTOR = 0
AT_SELECTOR = 1
AT_RULE = 2
AT_BLOCK = 3
BEFORE_NAME = 4
BEFORE_VALUE = 5
AT_VALUE = 6
IMPORT_BEGIN = 7
AT_IMPORT = 8

WHITESPACE = /[ \t\r\n\f]+/
AT_KEYFRAMES = /@(-(?:\w+-)+)?keyframes/g
NONASCII = /^\0-\237/
ESCAPE = [UNICODE, /\\[^\n\r\f0-9a-f]/]
NMSTART = [/[_a-z]/, NONASCII, ESCAPE]
CDO = '<!--'
CDC = '-->'

parseValue = (buf) ->

parseString = (buf) ->
  if sep = buf.eat "'", '"'
    value = buf.eat STRING
    buf.eat sep
    return value

parseRuleBlock = (buf) ->

identifier = (buf) ->
  buf.eat '-'
  buf.eat NMSTART

value = (buf) ->

maybe = (args..., f) ->
  try
    f args...
  catch e
    null

zeroOrMore = (args..., f) ->
  ret = []
  while true
    try
      if result = f args...
        ret.push result
    catch e
      break
  ret

oneOrMore = (args..., f) ->
  ret = []
  ret.push f args...
  while true
    try
      if result = f args...
        ret.push result
    catch e
      break
  ret

anyOf = (args..., fs) ->
  for f in fs
    try
      f args...
      break
    catch e
      continue

block = (buf) ->
  buf.eat '{'
  buf.eatWhile WHITESPACE
  anyOf buf, [any, block, atKeyword]

atKeyword = (buf) ->
  buf.eat '@'
  identifier buf

value = (buf) ->
  ret = zeroOrMore buf, ->
    anyOf buf, [any, block, atKeyword]
  ret.join ''

ruleset = (buf) ->
  sel = maybe buf, selector, buf
  buf.eat '{'
  buf.eatWhile WHITESPACE
  firstRule = maybe buf, declaration
  otherrules = zeroOrMore buf, ->
    buf.eat ';'
    buf.eatWhile WHITESPACE
    maybe buf, declaration
  buf.eat '}'
  buf.eatWhile WHITESPACE

declaration = (buf) ->
  property = identifier buf
  buf.eatWhile WHITESPACE
  buf.eat ':'
  buf.eatWhile WHITESPACE
  value = value buf
  [property, value]

parseRule = (buf) ->
  if buf.eat '@'
    type = buf.eatUntil WHITESPACE
    switch type
      when "media"
        rule = new CSSMediaRule
      when "import"
        rule = new CSSImportRule
      when "font-face"
        rule = new CSSFontFaceRule
      else
        rule = new CSSKeyFrameRule
  else
    if selector = buf.eatUntil '{'
      rule = new CSSStyleRule
      rule._selectorText = selector
      return if buf.eat '{' and propertiesObj = parseRuleBlock buf

parseStylesheet = (string) ->
  stylesheet = new CSSStyleSheet

  while true
    buf.eat [CDO, CDC, WHITESPACE]
    rule = parseRule buf
    return stylesheet unless rule
    stylesheet.insertRule rule

