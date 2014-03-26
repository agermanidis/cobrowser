{EventEmitter} = require 'events'


stripLeadingAndTrailingWhitespace = (s) ->
  #s.replace(/^\s+/, '').replace(/\s+$/, '')
  s.trim()

once = (f) ->
  hasBeenInvoked = false
  (args...) ->
    return if hasBeenInvoked
    hasBeenInvoked = true
    f args...

getter = (prop) ->
  (obj) -> obj[prop]

pluck = (arr, prop) ->
  arr.map (obj) -> obj[prop]

filterWhere = (arr, name, value) ->
  arr.filter (obj) -> obj[name] == value

extend = (obj, others...) ->
  for other in others
    for k, v of other
      obj[k] = v

nonEmpty = (arr) ->
  Array.isArray(arr) and !!arr.length

anyTrue = (arr) ->
  for item in arr
    return true if !!item
  false

mapcat = (arr, f) ->
  ret = ''
  for result in arr.map f
    ret += result
  ret

mapmin = (arr, f) ->
  Math.min.apply null, arr.map f

mapmax = (arr, f) ->
  Math.max.apply null, arr.map f

equalProperties = (obj, other, attrs...) ->
  for attr in attrs
    return false if obj[attr] != other[attr]
  true

caseInsensitiveEqual = (a, b) ->
  a.toLowerCase() == b.toLowerCase()

startsWith = (s, sb) ->
  s.indexOf(sb) == 0

endsWith = (s, sb) ->
  s.lastIndexOf(sb) + sb.length == s.length

copyArray = (arr) ->
  newArr = []
  for item in arr
    newArr.push item
  newArr

runAsync = (f) ->
  setTimeout f, 0

memoize = (f) ->
  memoized = (args...) ->
    if ret = memoized.results[args]
      return ret
    result = f args...
    memoized.results[args] = result
    result

  memoized.invalidate = (key) ->
    if key
      delete memoized.results[key]
    else
      memoized.results = {}

  memoized.invalidate()

  memoized

makeSet = (keys) ->
  obj = {}
  for key in keys
    obj[key] = true
  obj

originFromURL = (url) ->
  {protocol, host} = URL.parse url
  "#{protocol}//#{host}"

arrayBufferToBuffer = (ab) ->
  buf = new Buffer
  for index in [0..ab.byteLength-1]
    buf[index] = ab[index]
  buf

bufferToArrayBuffer = (b) ->
  ab = new ArrayBuffer b.length
  for index in [0..b.length - 1]
    ab[index] = b[index]
  ab

isArrayBufferView = (ab) ->
  ab?.constructor in [Int8Array, Uint8Array, Uint8ClampedArray, Int16Array, Uint16Array, Int32Array, Uint32Array, Float32Array, Float64Array]

camelize = (s) ->
  r = s[0] or ''
  nextIsUpperCase = false
  for c in s.substring(1)
    if c == '-'
      nextIsUpperCase = true
    else if nextIsUpperCase
      r += c.toUpperCase()
      nextIsUpperCase = false
    else
      r += c
  r

decamelize = (s) ->
  r = s[0] or ''
  for c in s[1..]
    if /[A-Z]/.test c
      r += "-#{c.toLowerCase()}"
    else r += c
  r

zipmap = (keys, values) ->
  ret = {}
  for key, index in keys
    ret[key] = values[index]
  ret

ignoringEvent = (el, type, f) ->
  preventDefault = (evt) -> evt.preventDefault()
  el.addEventListener type, preventDefault, true
  f -> el.removeEventListener type,  preventDefault, true

module.exports = {once, runAsync, copyArray, extend, mapcat, mapmin, mapmax, equalProperties, caseInsensitiveEqual, endsWith, anyTrue, nonEmpty, stripLeadingAndTrailingWhitespace, memoize, filterWhere, makeSet, originFromURL, startsWith, arrayBufferToBuffer, bufferToArrayBuffer, isArrayBufferView, camelize, decamelize, zipmap}
