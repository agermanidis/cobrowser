// Generated by CoffeeScript 1.3.3
var deserialize, deserializeCompact, deserializeDocument, deserializeNode,
  __slice = [].slice;

deserializeCompact = function(serialized) {
  var address, child, children, node, nodeName, nodeValue, properties, property, rest, type, value, _i, _len;
  type = serialized[0], rest = 2 <= serialized.length ? __slice.call(serialized, 1) : [];
  switch (type) {
    case 1:
      nodeName = rest[0], address = rest[1], properties = rest[2], children = rest[3];
      node = document.createElement(nodeName);
      node.address = address;
      for (property in properties) {
        value = properties[property];
        node.setAttribute(property, value);
      }
      for (_i = 0, _len = children.length; _i < _len; _i++) {
        child = children[_i];
        node.appendChild(deserializeCompact(child));
      }
      break;
    case 3:
      nodeValue = rest[0], address = rest[1];
      node = document.createTextNode(nodeValue);
      node.address = address;
  }
  return node;
};

deserializeNode = function(address, doc, listensToEvents) {
  var attribute, attributes, child, childAddress, children, node, nodeName, nodeValue, rest, type, value, _i, _len, _ref;
  if (listensToEvents == null) {
    listensToEvents = true;
  }
  try {
    _ref = doc[address], type = _ref[0], rest = 2 <= _ref.length ? __slice.call(_ref, 1) : [];
  } catch (e) {
    console.log("could not find " + address);
    return;
  }
  try {
    switch (type) {
      case 1:
        nodeName = rest[0], attributes = rest[1], children = rest[2];
        node = document.createElement(nodeName);
        node.address = address;
        if (typeof addressBook !== "undefined" && addressBook !== null) {
          addressBook[address] = node;
        }
        for (attribute in attributes) {
          value = attributes[attribute];
          node.setAttribute(attribute, value);
        }
        for (_i = 0, _len = children.length; _i < _len; _i++) {
          childAddress = children[_i];
          child = deserializeNode(childAddress, doc);
          if (child) {
            node.appendChild(child);
          }
        }
        break;
      case 3:
        nodeValue = rest[0];
        node = document.createTextNode(nodeValue);
        node.address = address;
    }
    if (listensToEvents) {
      installEventListeners(node);
    }
    return node;
  } catch (e) {
    console.error("EXCEPTION:", e);
  }
};

deserializeDocument = function(_arg) {
  var nodes, root;
  root = _arg.root, nodes = _arg.nodes;
  return deserializeNode(root, nodes);
};

deserialize = function(serialized) {
  var address, child, children, data, node, nodeName, properties, property, style, value, _i, _len;
  if (serialized.type === 'element') {
    nodeName = serialized.nodeName, address = serialized.address, properties = serialized.properties, children = serialized.children, style = serialized.style;
    node = document.createElement(nodeName);
    node.address = address;
    for (property in properties) {
      value = properties[property];
      node.setAttribute(property, value);
    }
    if (style) {
      node.style.cssText = style;
    }
    for (_i = 0, _len = children.length; _i < _len; _i++) {
      child = children[_i];
      node.appendChild(deserialize(child));
    }
  } else if (serialized.type === 'text') {
    data = serialized.data, address = serialized.address;
    node = document.createTextNode(data);
    node.address = address;
  } else if (serialized.type === 'comment') {
    data = serialized.data, address = serialized.address;
    node = document.createComment(data);
    node.address = address;
  }
  return node;
};
