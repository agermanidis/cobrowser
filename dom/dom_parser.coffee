require './meta'

{Document, XMLDocument} = require './document'
{Element} = require './element'


class DOMParser
  parseFromString: (str, type) ->
    if type == 'text/html'
      document = 0#parse
    else

      doc = new XMLDocument contentType: type
      root = new Element 'parsererror', 'http://www.mozilla.org/newlayout/xml/parsererror.xml'
      doc.appendChild root
      doc

module.exports = {DOMParser}
