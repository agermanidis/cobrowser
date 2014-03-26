{ELEMENT_NODE, DOCUMENT_NODE, DOCUMENT_FRAGMENT_NODE, TEXT_NODE, COMMENT_NODE, DOCUMENT_TYPE_NODE} = require './node'

singleTagRE = /(area|base|basefront|br|col|frame|hr|img|input|isindex|link|meta|param|embed)/

serializeText = (textNode) ->
  textNode.data

serializeComment = (comment) ->
    "<!--#{comment.data}-->"

serializeDocument = (document) ->
  xml = ''
  for child in document._childNodes
    xml += serializeNode child
  xml

serializeDocumentFragment = (fragment) ->
  xml = ''
  for child in fragment._childNodes
    xml += serializeNode child
  xml

serializeDocumentType = (doctype) ->
  xml = "<!DOCTYPE "


  xml += ">"

serializeElement = (el) ->
  tag = el.tagName.toLowerCase()

  xml = "<#{tag}"
  for {name, value} in el._attributes
    xml += " #{name}=\"#{value}\""

  if singleTagRE.test tag
    return xml += "/>"

  xml += ">"
  for child in el._childNodes
    xml += serializeNode child

  xml += "</#{tag}>"

serializeElementForClient = (el) ->
  tag = el.tagName.toLowerCase()

  xml = "<#{tag}"
  for {name, value} in el._attributes
    continue if name.indexOf('on') == 0

    xml += " #{name}=\"#{value}\""

  if singleTagRE.test tag
    return xml += "/>"

  xml += ">"
  for child in el._childNodes
    xml += serializeNode child

  xml += "</#{tag}>"

serializeNodeForClient = (node) ->
  switch node.nodeType
    when ELEMENT_NODE
      serializeElementForClient node
    when DOCUMENT_NODE
      serializeDocument node
    when DOCUMENT_TYPE_NODE
      serializeDocumentType node
    when DOCUMENT_FRAGMENT_NODE
      serializeDocumentFragment node
    when TEXT_NODE
      serializeText node
    when COMMENT_NODE
      serializeComment node

serializeNode = (node) ->
  switch node.nodeType
    when ELEMENT_NODE
      serializeElement node
    when DOCUMENT_NODE
      serializeDocument node
    when DOCUMENT_TYPE_NODE
      serializeDocumentType node
    when DOCUMENT_FRAGMENT_NODE
      serializeDocumentFragment node
    when TEXT_NODE
      serializeText node
    when COMMENT_NODE
      serializeComment node

module.exports = {serializeNode, serializeNodeForClient}

