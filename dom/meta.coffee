{camelize, decamelize} = require './helpers'

Function::add = (obj) ->
  for k, v in obj
    @::[k] = v

Function::constants = (obj) ->
  for k, v in obj
    @[k] = v

Function::get = (obj) ->
  for k, v of obj
    Object.__defineGetter__.call @::, k, v

Function::set = (obj) ->
  for k, v of obj
    Object.__defineSetter__.call @::, k, v

Function::define = (obj) ->
  for k, v of obj
    Object.defineProperty @::, k, v

Function::reflect = (args...) ->
  if args.length > 1
    [{treatNullAs, bool, type}, attributes] = args
    treatNullAsGlobal = treatNullAs
    boolGlobal = bool
    typeGlobal = type

  else
    [attributes] = args

  attributes.forEach (attr) =>
    {treatNullAs, prop, type, bool} = {}

    if typeof attr == 'object'
      {treatNullAs, attr, prop, type, bool} = attr

    treatNullAs ?= treatNullAsGlobal
    treatNullAs ?= ''
    bool ?= boolGlobal
    type ?= typeGlobal

    prop ?= attr

    bool = type == 'bool'
    long = type == 'long'
    attr = decamelize(attr).toLowerCase()

    Object.defineProperty @::, prop,
      get: ->
        val = @getAttribute attr
        return !!val if bool
        if val
          if long then parseFloat(val) else val
        else
          return treatNullAs

      set: (value) ->
        if bool
          if !!value
            @setAttribute attr, ''
          else
            @removeAttribute attr
        else
          @setAttribute attr, value

      configurable: false
      enumerable: true

Function::massDefine = ({properties, get, set, camelized}) ->
  properties.forEach (prop) =>
    Object.defineProperty @::, camelize(prop),
      get: ->
        get.call @, prop
      set: (v) ->
        set.call @, prop, v

Function::decompose = ({properties, get, set, camelized}) ->
  for prop in properties
    Object.defineProperty @::, camelize(prop),
      get: ->
        obj = get.call @
        obj[prop] or null
      set: (v) ->
        set.call @, prop, v

Function::readonly = (names) ->
  names.forEach (name) =>
    Object.defineProperty @::, name,
      get: -> @["_#{name}"]
      set: ->
      configurable: false
      enumerable: true

Function::events = (names) ->
  names.forEach (name) =>
    Object.defineProperty @::, "on"+name,
      get: ->
        @["_on#{name}"] or null
      set: (listener) ->
        @["_on#{name}"] = listener
      configurable: false
      enumerable: true

