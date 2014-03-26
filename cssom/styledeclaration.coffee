require '../dom/meta'

{parse} = require 'cssom'

{DOMException, NO_MODIFICATION_ALLOWED_ERR} = require '../dom/exceptions'
{propertyNames} = require './properties'

serializeBlock = (d) ->
  s = ''

  return s if d.length == 0

  for i in [0..d.length - 1]
    n = d.item i
    v = d.getPropertyValue n

    continue if v == ''

    if s.length > 0
      s += ' '

    s += "#{n}: #{v}"

    p = d.getPropertyPriority n
    if p != ''
      s += ' !'
      s += p

    s += ';'

  s

refreshIndices = (declaration) ->
  for property, index in declaration._properties
    declaration[index] = property

  declaration.length = declaration._properties.length

refresh = (declaration, styleObj) ->
  properties = []
  propertiesObj = {}

  index = 0
  while declaration[index]
    delete declaration[index++]

  if styleObj.length > 0
    for index in [0..styleObj.length - 1]
      property = properties[index] = styleObj[index].toLowerCase()
      value = styleObj[property]
      priority = styleObj._importants[property]
      propertiesObj[property] = {value, priority}

  declaration._properties = properties
  declaration._propertiesObj = propertiesObj

  refreshIndices declaration

updateDeclaration = (declaration, text) ->
  dummyBlock = "dummy { #{text} }"
  styleObj = parse(dummyBlock).cssRules[0]?.style
  if styleObj
    refresh declaration, styleObj

class CSSStyleDeclaration
  @get
    length: -> @_properties.length
    parentRule: -> null

  @define
    cssText:
      get: ->
        serializeBlock @

      set: (text) ->
        updateDeclaration @, text
        if @_firstTime
          @_firstTime = false
        else
          @setter @cssText

  item: (index) ->
    @_properties[index] or null

  getPropertyValue: (property) ->
    #console.log "ACCESSING", property
    @_propertiesObj[property.toLowerCase()]?.value or ''

  getPropertyPriority: (property) ->
    @_propertiesObj[property.toLowerCase()]?.priority or ''

  setProperty: (property, value, priority = '') ->
    #console.log 'setting', {property, value}

    if @_readonly
      throw new DOMException NO_MODIFICATION_ALLOWED_ERR

    property = property.toLowerCase()

    if value == ''
      return @removeProperty property

    @_propertiesObj[property] = {value, priority}

    index = @_properties.indexOf property

    if index == -1
      @_properties.push property

    refreshIndices @
    @setter @cssText

    value

  removeProperty: (property) ->
    if @_readonly
      throw new DOMException NO_MODIFICATION_ALLOWED_ERR

    property = property.toLowerCase()

    index = @_properties.indexOf property

    if index != -1
      @_properties.splice index, 1
      delete @_propertiesObj[property]

      refreshIndices @

      @setter @cssText

  @massDefine
    properties: propertyNames
    camelized: true
    get: (prop) -> @getPropertyValue prop
    set: (prop, value) -> @setProperty prop, value

  constructor: (value, @setter = ->) ->
    @_properties = []
    @_propertiesObj = {}
    @_firstTime = true
    @cssText = value or ''

module.exports = {CSSStyleDeclaration, updateDeclaration}

