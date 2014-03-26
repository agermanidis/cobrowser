require '../dom/meta'
URL = require 'url'

{HTMLElement} = require './element'
{fireSimpleEvent} = require '../dom/dom_helpers'
{preorder, findAncestor} = require '../dom/tree_operations'
{NodeList, refreshCollection} = require '../dom/collections'
{HTMLFormControlsCollection, HTMLOptionsCollection, refreshOptionsCollection} = require './collections'

sufferingFromBeingMissing = (node) ->
  # TODO: implement for radio groups
  # or, in the case of an element in a radio button group, any of the other elements in the group has a required attribute.
# http://www.whatwg.org/specs/web-apps/current-work/multipage/association-of-controls-and-forms.html#barred-from-constraint-validation
  return isRequired = node.getAttribute('required') and !node.value

sufferingFromTypeMismatch = (node) ->
  # TODO: check for tel, url, email, datetime, date, month, week
  return false

sufferingFromPatternMismatch = (node) ->
  # TODO: check for multiple
  pattern = node.getAttribute('pattern') and !pattern.test(node.value)

sufferingFromBeingTooLong = (node) ->
  # browser prevents this anyway
  maxlength = node.getAttribute('maxlength') and node.length > maxlength

sufferingFromUnderflow = (node) ->
  min = node.getAttribute('min') and node.value < parseFloat(min)

sufferingFromOverflow = (node) ->
  min = node.getAttribute('max') and node.value > parseFloat(max)

sufferingFromCustomError = (node) ->
  !node._customValidityErrorMessage.length

isMutable = (el) ->
  !el.getAttribute('disabled')

satisfiesNone = (item, check) ->
  for filter in filters
    return false if check item
  true

satisfiesConstraints = (node) ->
  satisfiesNone node, [
    sufferingFromBeingMissing
    sufferingFromTypeMismatch
    sufferingFromPatternMismatch
    sufferingFromBeingTooLong
    sufferingFromUnderflow
    sufferingFromStepMismatch
    sufferingFromCustomError
  ]

isCandidateForConstraintValidation = (el) -> true

staticallyValidateForm = (form) ->
  controls = form.elements
  invalidControls = []

  for field in controls
    unless satisfiesConstraints field
      invalidControls.push field

  return true if invalidControls.length == 0

  unhandledInvalidControls = []

  for field in invalidControls
    ev = document.createEvent "HTMLEvents"
    ev.initEvent "invalid", false, true
    unhandledInvalidControls.push field if field.dispatchEvent ev

  unhandledInvalidControls

interactivelyValidateForm = (form) ->
  result = staticallyValidateForm form
  return true if result == true

  if Array.isArray result and result.length > 0
    first = result[0]
    first.focus()

  false

constructFormDataset = (form) ->
  controls = form.elements

  data = []

  for field in controls
    {name, type, nodeName, checked, disabled, value} = field

    continue if field.getAttribute('datalist') or field.getAttribute('disabled')
    continue if nodeName == 'BUTTON' and field != submitter
    continue if nodeName == 'INPUT' and type in ['checkbox', 'radio'] and !checked
    continue if type != 'image' and !name
    #continue if field.nodeName != 'INPUT'

    data.push {name, type, value}

  data

multipartEncodeFormData = (data) ->
  mime = "UTF-8"
  for entry, index in data
    {name, value, type} = entry
    if name == '_charset_' and type == 'hidden'
      entry.value = mime
    entry.name = encodeURIComponent name
    entry.value = encodeURIComponent value
  parts = []
  #ret = ''
  boundary = "PomoBoundary65a640b2d7d44d32a6bea6db8c71f114"
  for {name, value} in data
    preamble = "--#{boundary}\r\n"
    preamble += "content-disposition: form-data; name=\"#{name}\"\r\n"
    # type = "text/plain"
    preamble += '\r\n'
    parts.push new Buffer preamble
    parts.push new Buffer value
    parts.push new Buffer "\r\n"
    # ret += preamble
    # ret += '\r\n'
    # ret += value
    # ret += '\r\n'
  parts.push new Buffer "--#{boundary}--\r\n"
  #ret += "--#{boundary}--"
  {encodedData: parts, boundary}
  #{encodedData: ret, boundary}

urlEncodeFormData = (data) ->
  ret = ''
  for {name, value, type}, index in data
    ret += "#{encodeURIComponent(name)}=#{encodeURIComponent(value)}"
    ret += "&" unless index == data.length - 1
  ret

submitForm = (form, submitter) ->
  context = form.ownerDocument?.defaultView?._context
  return unless context

  return if context.formIsBeingSubmitted

  context.formIsBeingSubmitted = true

  {history, document} = context

  if submitter
    action = submitter.getAttribute 'formaction'
    method = submitter.getAttribute 'formmethod'
    novalidate = submitter.getAttribute 'formnovalidate'
    enctype = submitter.getAttribute 'formenctype'

  action = action or form.getAttribute('action') or window.location
  method = method or form.getAttribute('method') or "GET"
  novalidate = novalidate or form.getAttribute('novalidate') or false
  enctype = enctype or form.getAttribute('enctype') or "application/x-www-form-urlencoded"

  method = method.toUpperCase()

  url = URL.resolve form.ownerDocument.URL, action
  data = constructFormDataset form

  console.log 'constructing data set', data

  switch enctype
    when "application/x-www-form-urlencoded"
      encodedData = urlEncodeFormData data
    when "multipart/form-data"
      {encodedData, boundary} = multipartEncodeFormData data

  console.log "SUBMITTING FORM", {method, url, encodedData, enctype}

  history.submitForm method, url, encodedData, enctype, boundary

  context.formIsBeingSubmitted = false

resetElement = (el) ->


resetForm = (form) ->
  if fireSimpleEvent form, 'reset', false, true
    for el in form.elements
      resetElement el

transformIntoNodeListAndAdd = (item, el) ->
  unless item instanceof NodeList
    #console.log 1
    new NodeList [item, el]
  else
    #console.log 2
    coll = item.collection
    coll.push el
    #console.log 'new coll', coll.length
    refreshCollection coll, item
    item

refreshForm = (form) ->
  delete form._elements

  index = 0
  while form[index]
    delete form[index++]

  for name, _ of form._names
    delete form[name]

  form._names = {}
  form._elements = els = preorder(form).filter (node) => node.form == form and node.type != 'image'
  len = els.length

  for el, index in els
    form[index] = el

    if name = el.name
      #console.log 'considering name', {name}
      if existing = form[name]
        #console.log 'existing', existing instanceof NodeList
        form[name] = transformIntoNodeListAndAdd existing, el
        #console.log 'existing', form[name].length
      else
        form[name] = el

      form._names[name] = true

    if id = el.id
      if existing = form[id]
        form[id] = transformIntoNodeListAndAdd existing, el
      else
        form[id] = el

      form._names[id] = true

class HTMLFieldSetElement extends HTMLElement


class HTMLFormElement extends HTMLElement
  @reflect [{attr: 'color', treatNullAs: ''}, 'face', 'size', {prop: 'acceptCharset', attr: 'accept-charset'}, 'autocomplete', 'enctype', 'encoding', 'method', 'name', 'target']
  @reflect bool: true, ['noValidate'] #'formnovalidate']

  @define
    action:
      get: ->
        attrValue = @getAttribute 'action'
        if !attrValue?.length then @ownerDocument.URL else attrValue

      set: (val) ->
        @setAttribute 'action', val

  @get
    length: -> @elements.length
    elements: -> return new HTMLFormControlsCollection @_elements

  submit: ->
    submitForm @

  reset: ->
    return unless @_lockedForReset
    @_lockedForReset = true
    resetForm @
    @_lockedForReset = false

  constructor: (args...) ->
    super args...

    @_names = {}

    @addEventListener 'DOMNodeInserted', =>
      refreshForm @
    @addEventListener 'DOMNodeRemoved', =>
      refreshForm @
    @addEventListener 'DOMAttrModified', =>
      refreshForm @


    # formAction: ->
    #   attrValue = @getAttribute 'formaction'
    #   if !attrValue?.length then @ownerDocument.URL else attrValue


class HTMLLabelElement extends HTMLElement
  @reflect [{prop: 'htmlFor', attr: 'for'}]

class ValidityState
  constructor: (states) ->
    {@valueMissing, @typeMismatch, @patternMismatch, @tooLong, @rangeUnderflow, @rangeOverflow, @stepMismatch, @customError, @valid} = states

class HTMLInputElement extends HTMLElement
  @reflect ['accept', 'alt', 'autocomplete', 'dirName', 'formAction', 'formEnctype', 'formMethod', 'formTarget', 'max', 'min', 'name', 'pattern', 'placeholder', 'size', 'src', 'step', 'type', {prop: 'defaultValue', attr: 'value', treatNullAs: ''}, {treatNullAs: '', attr: 'value'}, 'align', 'useMap']

  @reflect bool: true, ['autofocus', {prop: 'defaultChecked', attr: 'checked'}, 'checked', 'disabled', 'formNoValidate', 'indeterminate', 'multiple', 'readOnly', 'required']

  @get
    valueAsDate: -> new Date @value
    valueAsNumber: -> parseFloat @value

    form: -> findAncestor @, (node) -> node.tagName == 'FORM'

    height: ->
    width: ->
    size: ->

    validityState: ->
      new ValidityState
        sufferingFromBeingMissing: sufferingFromBeingMissing @
        sufferingFromTypeMismatch: sufferingFromTypeMismatch @
        sufferingFromPatternMismatch: sufferingFromPatternMismatch @
        sufferingFromBeingTooLong: sufferingFromBeingTooLong @
        sufferingFromUnderflow: sufferingFromUnderflow @
        sufferingFromStepMismatch: sufferingFromStepMismatch @
        sufferingFromCustomError: sufferingFromCustomError @

    willValidate: ->
      isCandidateForConstraintValidation @

    labels: ->
      labelElements = @ownerDocument.getElementsByTagName 'label'
      new NodeList labelElements.filter (label) -> label.getAttribute('for') == @id

  checkvalidity: ->
    satisfiesConstraints @

  setValidity: (msg) ->
    @_customValidityErrorMessage = msg

  stepUp: (n) ->

  stepDown: (n) ->

  click: ->
    if @type == 'submit' and isMutable @
      submitForm @form, @

  constructor: (args...) ->
    @_customValidityErrorMessage = ''
    super args...

class HTMLKeygenElement extends HTMLElement
  @reflect ['challenge', 'keytype', 'name', 'type']
  @reflect bool: true, ['autofocus', 'disabled']

class HTMLMeterElement extends HTMLElement
  @reflect ['value', 'min', 'max', 'low', 'high', 'optimum']
  #todo
#

class HTMLOptGroupElement extends HTMLElement
  @reflect type: 'bool', ['disabled']

class HTMLOptionElement extends HTMLElement
  @reflect type: 'bool', ['disabled']
  @reflect [{attr: 'selected', prop: 'defaultSelected'}, 'selected']
  @get label: -> @getAttribute 'label' or @text
  @set label: (val) -> @setAttribute 'label', val

  @define
    text:
      get: -> stripLeadingAndTrailingWhitespace(@textContent).replace '\s+', ' '
      set: (val) -> @textContent = val

class HTMLOutputElement extends HTMLElement

getListOfOptions = (select) ->
  ret = select._childNodes.filter (node) -> node.tagName == 'OPTION'
  optGroups = select._childNodes.filter (node) -> node.tagName == 'OPTGROUP'
  for group in optGroups
    ret = ret.concat group._childNodes.filter (node) -> node.tagName == 'OPTION'
  ret

class HTMLSelectElement extends HTMLElement
  @reflect type: 'long', ['size']
  @reflect type: 'bool', ['autofocus', 'disabled', 'multiple', 'required']
  @get type: -> if @multiple then "select-multiple" else "select-one"

  @get length: ->
    @_options.length

  add: (args...) ->
    @options.add args...

  remove: (args...) ->
    @options.remove args...

  @get selectedIndex: ->
    for option, index in @options
      return index if option.selected
    -1

  @get value: ->
    for option in @options
      return option.value if option.selected
    ''

  @get selectedOptions: ->
    selected = []
    for option in @options
      selected.push options if option.selected
    new HTMLCollection selected

  @get labels: ->
    labels = @_childNodes.filter (node) -> node.tagName == 'LABEL'
    new NodeList labels

  constructor: (args...) ->
    super args...

    @options = new HTMLOptionsCollection @, getListOfOptions(@)

    @addEventListener 'DOMNodeInserted', =>
      refreshOptionsCollection getListOfOptions(@), @options

    @addEventListener 'DOMNodeRemoved', =>
      refreshOptionsCollection getListOfOptions(@), @options

    @addEventListener 'DOMAttrModified', =>
      refreshOptionsCollection getListOfOptions(@), @options

class HTMLTextAreaElement extends HTMLElement
  @reflect ['dirName', 'name', 'placeholder', 'wrap', {prop: 'defaultValue', attr: 'value'}, 'value']
  @reflect type: 'bool', ['autofocus', 'disabled', 'readOnly', 'required']
  @reflect type: 'long', ['cols', 'maxLength', 'rows']

  @get
    type: -> 'textarea'
    textLength: -> #??

module.exports = {HTMLFieldSetElement, HTMLFormElement, HTMLLabelElement, HTMLInputElement, HTMLKeygenElement, HTMLOptGroupElement, HTMLOptionElement, HTMLSelectElement}
