deserializeCompact = (serialized) ->
  [type, rest...] = serialized
  switch type

    when 1
      [nodeName, address, properties, children] = rest
      node = document.createElement nodeName
      node.address = address
      for property, value of properties
        node.setAttribute property, value
      for child in children
        node.appendChild deserializeCompact(child)

    when 3
      [nodeValue, address] = rest
      node = document.createTextNode nodeValue
      node.address = address
  node

deserializeNode = (address, doc, listensToEvents = yes) ->
  try
    [type, rest...] = doc[address]
  catch e
    console.log "could not find #{address}"
    return
  try
    switch type
      when 1
        [nodeName, attributes, children] = rest
        node = document.createElement nodeName
        node.address = address
        if addressBook?
          addressBook[address] = node
        for attribute, value of attributes
          #console.log {attribute, value}
          node.setAttribute attribute, value
        for childAddress in children
          child = deserializeNode(childAddress, doc)
          node.appendChild child if child
      when 3
        [nodeValue] = rest
        node = document.createTextNode nodeValue
        node.address = address

    installEventListeners node if listensToEvents

    node
  catch e
    console.error "EXCEPTION:", e
    return

deserializeDocument = ({root, nodes}) ->
  deserializeNode root, nodes


deserialize = (serialized) ->
  if serialized.type == 'element'
    {nodeName, address, properties, children, style} = serialized
    node = document.createElement nodeName
    node.address = address
    for property, value of properties
      node.setAttribute property, value

    node.style.cssText = style if style

    for child in children
      node.appendChild deserialize(child)

  else if serialized.type == 'text'
    {data, address} = serialized
    node = document.createTextNode data
    node.address = address

  else if serialized.type == 'comment'
    {data, address} = serialized
    node = document.createComment data
    node.address = address

  node

