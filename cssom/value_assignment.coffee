{propertyNames} = require './properties'
{decamelize, camelize} = require '../dom/helpers'
{preorder} = require '../dom/tree_operations'
{ELEMENT_NODE} = require '../dom/node'

nonascii = "[^\0-\237]"
unicode = "\\[0-9a-f]{1,6}(\r\n|[ \n\r\t\f])?"
escape = "#{unicode}|\\[^\n\r\f0-9a-f]"
nmstart = "([_a-z]|#{nonascii}|#{escape})"
nmchar = "([_a-z0-9-]|#{nonascii}|#{escape})"
name = "(#{nmchar})+"
ident = "[-]?#{nmstart}(#{nmchar})*"
func = "#{ident}\("
dashmatch = "|="
includes = "~="
nl = "\n|\r\n|\r|\f"
string1 = '\"([^\n\r\f\\"]|\\' + nl + '|' + escape + ')*\\?'
string2 = "\'([^\n\r\f\\']|\\" + nl + '|' + escape + ')*\\?'
string = "(#{string1}|#{string2})"

classR = RegExp "[.](#{ident})"
elementNameR = RegExp "(#{ident}|[*])"
attributeR = RegExp "\[\s*#{ident}\s*(=|#{includes}|#{dashmatch})\s*(#{ident}|#{string})\s*)\]"
pseudoR = RegExp ":(#{ident}|#{func})"

initialValues =
  azimuth: 'center'
  backgroundAttachment: 'scroll'
  backgroundColor: 'transparent'
  backgroundImage: 'none'
  backgroundPosition: '0% 0%'
  backgroundRepeat: 'repeat'
  borderCollapse: 'separate'
  borderSpacing: '0'
  borderTopStyle: 'none'
  borderRightStyle: 'none'
  borderBottomStyle: 'none'
  borderLeftStyle: 'none'
  borderTopWidth: 'medium'
  borderRightWidth: 'medium'
  borderBottomWidth: 'medium'
  borderLeftWidth: 'medium'
  bottom: 'auto'
  captionSide: 'top'
  clear: 'none'
  clip: 'auto'
  color: 'black'
  content: 'normal'
  counterIncrement: 'none'
  counterReset: 'none'
  cueAfter: 'none'
  cueBefore: 'none'
  direction: 'ltr'
  display: 'inline'
  elevation: 'level'
  emptyCells: 'show'
  float: 'none'
  fontFamily: 'Times New Roman'
  fontSize: 'medium'
  fontStyle: 'normal'
  fontVariant: 'normal'
  fontWeight: 'normal'
  height: 'auto'
  left: 'auto'
  letterSpacing: 'normal'
  lineHeight: 'normal'
  listStyleImage: 'none'
  listStylePosition: 'outside'
  listStyleType: 'disc'
  marginRight: '0'
  marginLeft: '0'
  marginTop: '0'
  marginBottom: '0'
  maxHeight: 'none'
  maxWidth: 'none'
  minHeight: '0'
  minWidth: '0'
  orphans: '2'
  outlineColor: 'invert'
  outlineStyle: 'none'
  outlineWidth: 'medium'
  overflow: 'visible'
  paddingTop: '0'
  paddingRight: '0'
  paddingBottom: '0'
  paddingLeft: '0'
  pageBreakAfter: '0'
  pageBreakBefore: '0'
  pageBreakInside: '0'
  pitchRange: '50'
  pitch: 'medium'
  playDuring: 'auto'
  position: 'static'
  quotes: ''
  richness: '50'
  right: 'auto'
  speakHeader: 'once'
  speakNumeral: 'continuous'
  speakPunctuation: 'none'
  speak: 'normal'
  speechRate: 'medium'
  stress: '50'
  tableLayout: 'auto'
  textAlign: -> if @direction == 'ltr' then 'left' else 'right'
  textDecoration: 'none'
  textIndent: 'none'
  textTransform: 'none'
  top: 'auto'
  unicodeBidi: 'normal'
  verticalAlign: 'baseline'
  visibility: 'visible'
  voiceFamily: ''
  volume: 'medium'
  whiteSpace: 'normal'
  windows: '2'
  width: 'auto'
  wordSpacing: 'normal'
  zIndex: 'auto'

fromBase = (arr, base) ->
  ret = 0
  for val, power in arr.reverse()
    ret += val * Math.pow base, power
  ret

parseSelector = (sel) ->

calculateSpecificity = (sel) ->


findElementsBySelector = (selector, document) ->


cascade = (declaration, element) ->


assignPropertyValues = (rules, document) ->
  for rule in rules
    rule.specificity = calculateSpecificity rule.selectorText

  preorder document.body, (node) ->
    return unless node.nodeType == ELEMENT_NODE

module.exports = {assignPropertyValues}
