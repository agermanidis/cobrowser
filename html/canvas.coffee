{HTMLElement} = require './element'

{DOMException, NOT_SUPPORTED_ERR} = require '../dom/exceptions'

class HTMLCanvasElement extends HTMLElement

# events:
# clearRect(x, y, w, h)
# fillRect(x, y, w, h, fillStyle)
# strokeRect(x, y, w, h, strokeStyle, lineWidth, lineJoin, miterLimit)

contextCommand = (ctx, args...) ->
  address = ctx.canvas._address
  context = browsingContextOf ctx
  context.canvasCommand address, args...
  return

serializeImageData = (imagedata) ->

browsingContextOf = (ctx) ->
  ctx.canvas.ownerDocument?.defaultView?._context

copyDrawingState = (ds) ->
  JSON.parse JSON.stringify ds

identityMatrix = -> [1, 0, 0, 1, 0, 0]

getTransformMatrix = (ctx) ->
  ctx._stack[0].transform

createDrawingState = ->
  globalAlpha: 1
  globalCompositeOperation: 'source-over'
  strokeStyle: 'black'
  fillStyle: 'black'
  shadowOffsetX: 0
  shadowOffsetY: 0
  shadowBlur: 0
  shadowColor: 'black'
  lineWidth: 1
  lineCap: 'butt'
  lineJoin: 'miter'
  miterLimit: 10
  font: '10px sans-serif'
  textAlign: 'start'
  textBaseline: 'alphabetic'
  transform: identityMatrix()
  clippingRegion: []

class CanvasRenderingContext2D
  @readonly ['canvas']

  save: ->
    @_stack.push copyDrawingState @_stack[0]
    return

  restore: ->
    @_stack.pop()
    return

  @decompose
    properties: [
      'globalAlpha', 'globalCompositeOperation', 'strokeStyle',
      'fillStyle', 'shadowOffsetX', 'shadowOffsetY',
      'shadowBlur', 'shadowColor', 'lineWidth',
      'lineCap', 'lineJoin', 'miterLimit',
      'font', 'textAlign', 'textBaseline'
    ]

    get: (k) ->
      @_stack[0][k]

    set: (k, v) ->
      @_stack[0][k] = v

  createLinearGradient: (x0, y0, x1, y1) ->

  createRadialGradient: (x0, y0, x1, y1, r1) ->

  createPattern: (image, repetition = 'repeat') ->

  clearRect: (x, y, w, h) ->
    contextCommand @, 'clearRect', x, y, w, h, getTransformMatrix(@)

  fillRect: (x, y, w, h) ->
    contextCommand @, 'fillRect', x, y, w, h, @fillStyle, getTransformMatrix(@)

  strokeRect: (x, y, w, h) ->
    contextCommand @, 'strokeRect', x, y, w, h, @strokeStyle, @lineWidth, @lineJoin, @miterLimit, getTransformMatrix(@)

  fillText: (text, x, y, maxWidth) ->
    contextCommand @, 'fillText', text, x, y, maxWidth, @fillStyle, getTransformMatrix(@)

  strokeText: (text, x, y, maxWidth) ->
    contextCommand @, 'strokeText', text, x, y, maxWidth, @strokeStyle, @lineWidth, @lineJoin, @miterLimit, getTransformMatrix(@)

  measureText: ->

  beginPath: ->
    @_currentPath = []

  fill: ->
    contextCommand @, 'fill', @_currentPath, @fillStyle, getTransformMatrix(@)

  stroke: ->
    contextCommand @, 'stroke', @_currentPath, @strokeStyle, @lineWidth, @lineCap, @lineJoin, @miterLimit, getTransformMatrix(@)

  moveTo: (x, y) ->
    @_currentPath.push ['moveTo', x, y]

  lineTo: (x, y) ->
    @_currentPath.push ['lineTo', x, y]

  quadraticCurveTo: (cpx, cpy, x, y) ->
    @_currentPath.push ['quadraticCurveTo', cpx, cpy, x, y]

  bezierCurveTo: (cp1x, cp1y, cp2x, cp2y, x, y) ->
    @_currentPath.push ['bezierCurveTo', cp1x, cp1y, cp2x, cp2y, x, y]

  arcTo: (x1, y1, x2, y2) ->
    @_currentPath.push ['arcTo', x1, y1, x2, y2]

  arc: (x, y, radius, startAngle, endAngle, anticlockwise) ->
    @_currentPath.push ['arc', x, y, radius, startAngle, endAngle, anticlockwise]

  rect: (x, y, w, h) ->
    @_currentPath.push ['rect', x, y, w, h]

  closePath: ->
    @_currentPath.push []

  drawSystemFocusRing: (element) ->
  drawCustomFocusRing: (element) ->

  scrollPathIntoView: ->

  clip: ->

  isPointInPath: (x, y) -> false

  scale: (x, y) ->
    m = getTransformMatrix @

    m[0] *= x
    m[1] *= x
    m[2] *= y
    m[3] *= y

  rotate: (angle) ->
    m = getTransformMatrix @

    cos = Math.cos angle
    sin = Math.sin angle

    m[0] = m[0] * cos + m[2] * sin
    m[1] = m[1] * cos + m[3] * sin
    m[2] = m[0] * (-sin) + m[2] * cos
    m[3] = m[1] * (-sin) + m[3] * cos

  translate: (x, y) ->
    m = getTransformMatrix @

    m[4] += m[0] * x + m[2] * y
    m[5] += m[1] * x + m[3] * y

  transform: (a, b, c, d, e, f) ->
    m = getTransformMatrix @

    m[0] = a
    m[1] = b
    m[2] = c
    m[3] = d
    m[4] = e
    m[5] = f

  setTransform: (a, b, c, d, e, f) ->
    ds = @_stack[0]
    ds.transform = identityMatrix()
    @transform a, b, c, d, e, f

  createImageData: (args...) ->
    if args.length == 1
      [imagedata] = args
    else
      [sx, sy] = args

  getImageData: (sx, sy, sw, sh) ->

  putImageData: (imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) ->

  constructor: (@_canvas) ->
    initialDrawingState = createDrawingState()
    @_stack = [initialDrawingState]
    @_currentPath = []

class CanvasGradient
  addColorStop: (offset, color) ->


class TextMetrics
  @readonly ['width']
  constructor: (@_width) ->

class ImageData
  @readonly ['width', 'height', 'data']
  constructor: (@_width, @_height, @_data) ->



module.exports = {HTMLCanvasElement}
