copyKeys = (src, dest, keys) ->
  for k in keys
    dest[k] = src[k]


serialize = (event) ->
  proto = event.__proto__
  serialized = {}

  switch proto
    when MouseEvent
      copyKeys event, serialized, ['screenX', 'screenY', 'clientX', 'clientY', 'ctrlKey', 'shiftKey', 'altKey', 'metaKey', 'button']


