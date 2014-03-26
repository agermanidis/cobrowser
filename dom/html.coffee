
wrapInArray = (x) ->
  if Array.isArray x then x else [x]

getClass = (c) ->

extend = (obj, others) ->
  for other in others
    for k, v of other
      obj[k] = v


define = (name, {private, tags, init, inherits, methods, attributes, properties, getters, setters, modify}) ->
  tags = wrapInArray tag
  tags = tags.map (tag) -> tag.toUpperCase()

  inherits = wrapInArray inherits
  inherits = inherits.map (c) ->
    if typeof c == 'string'
      @[c]
    else c

  eClass = core[name] = (document, name) ->


  proto = eClass::

  extend proto, inherits

  for method, fn of methods
    proto[method] = fn

  for prop, fn of getters
    proto.__defineGetter__ prop, fn

  for prop, fn of setters
    proto.__defineSetter__ prop, fn

  for prop, obj of properties
    Object.defineProperty proto, prop, obj

  # for attribute in attributes
  #   switch typeof attribute
  #     when 'string'

  modify.call proto

define 'HTMLElement',
  inherits: core.Element
  methods: {}
  getters:
    elements: ->
    length: ->
    rowIndex: ->
  modify: ->

define 'HTMLAnchorElement',
  tags: 'a'

define 'HTMLHtmlElement', tag: 'html', attributes: ['version']
define 'HTMLHeadElement', tag: 'head', attributes: ['profile']

define 'HTMLTitleElement',
  tag: 'title'
  text:
    get: -> @innerHTML
    set: (s) -> @innerHTML = s

define 'HTMLBaseElement',
  tag: 'base'
  attributes: ['href', 'target']



define 'HTMLMetaElement',
  tag: 'meta'
  attributes: ['content']


define 'HTMLFormElement',
  tag: 'form'
  methods:
