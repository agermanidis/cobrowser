{HTMLElement} = require './element'
{findFirstChild, findLastChild} = require '../dom/tree_operations'
{DOMException, HIERARCHY_REQUEST_ERR, INDEX_SIZE_ERR} = require '../dom/exceptions'
{DOMSettableTokenList} = require '../dom/collections'

class HTMLTableElement extends HTMLElement
  @reflect ['align', 'frame', 'rules', 'summary', 'width']
  @reflect treatNullAs: '', ['bgColor', 'cellPadding', 'cellSpacing']

  createCaption: ->
    existing = findFirstChild @, (node) -> node.tagName == 'CAPTION'
    return existing if existing
    caption = @ownerDocument.createElement 'caption'
    @appendChild caption

  deleteCaption: ->
    existing = findFirstChild @, (node) -> node.tagName == 'CAPTION'
    @removeChild existing if existing
    return

  @define
    tHead:
      get: ->
        findFirstChild @, (node) -> node.tagName == 'THEAD'
      set: (el) ->

  createTHead: ->


  deleteTHead: ->
    existing = findFirstChild @, (node) -> node.tagName == 'THEAD'
    @removeChild existing if existing
    return

  @define
    tFoot:
      get: ->
        findFirstChild @, (node) -> node.tagName == 'TFOOT'

      set: (el) ->

  @get rows: ->

  # createTBody:
  #   existing = findLastChild @, (node) -> node.tagName == 'TBODY'
  #   tbody = @ownerDocument.createElement 'TBODY'
  #   if existing
  #     @insertBefore tbody, existing
  #   else
  #     @appendChild tbody

class HTMLTableCaptionElement extends HTMLElement
  @reflect ['align']

class HTMLTableColElement extends HTMLElement
  @reflect ['align', 'ch', 'chOff', 'vAlign', 'width']

class HTMLTableRowElement extends HTMLElement
  @reflect ['align', 'ch', 'chOff', 'vAlign']
  @reflect treatNullAs: '', ['bgColor']

  @get rowIndex: ->

  insertCell: (index) ->

  deleteCell: (index) ->


class HTMLTableCellElement extends HTMLElement
  @reflect ['abbr', 'align', 'axis', 'height', 'width', 'ch', 'chOff', 'vAlign']
  @reflect bool: true, ['noWrap']
  @reflect treatNullAs: '', ['bgColor']

class HTMLTableDataCellElement extends HTMLTableCellElement
  @reflect camelized: true, ['colSpan', 'rowSpan']

  @get
    headers: ->
      new DOMSettableTokenList @getAttribute('headers'), (s) =>
        @setAttribute 'headers', s

    cellIndex: ->
      @parentNode.cells.collection.indexOf @

class HTMLTableSectionElement extends HTMLElement
  @reflect ['align', 'ch', 'chOff', 'vAlign']

  @get rows: ->
    new HTMLCollection @_children.filter (node) -> node.tagName == 'TR'

  insertRow: (index) ->
    if index < -1 or index > @rows.length
      throw new DOMException INDEX_SIZE_ERR

    newRow = @ownerDocument.createElement 'TR'

    if !index? or index == -1
      @appendChild newRow

    else
      @insertBefore newRow, @rows[index]

  deleteRow: (index) ->
    unless 0 <= index < @rows.length
      throw new DOMException INDEX_SIZE_ERR

    @removeChild @rows[index]
    return

class HTMLTableHeaderCellElement extends HTMLElement


module.exports = {HTMLTableElement, HTMLTableCaptionElement, HTMLTableColElement, HTMLTableRowElement, HTMLTableDataCellElement, HTMLTableSectionElement, HTMLTableHeaderCellElement}
