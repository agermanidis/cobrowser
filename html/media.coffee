require '../dom/meta'

URL = require 'url'

{HTMLElement} = require './element'
{EventTarget} = require '../dom/event'
{DOMException, INDEX_SIZE_ERR} = require '../dom/exceptions'
{fireSimpleEvent} = require '../dom/dom_helpers'
{mapmin} = require '../dom/helpers'
{findFirstChild} = require '../dom/tree_operations'

# events to listen to on the client
# - volume?
# - seeking: then seek on server
# - when all seeked: throw seeked on server
# - ended: end all
# propagate durationchange, error, timeupdate

# interface:
# - seek( el, time )
# - play( el )
# - pause( el )
# - setVolume( el, vol )
# - setPlaybackRate( el, rate )

setVolume = (el, vol, userId) ->
  #context = el._ownerDocument._defaultView._context
  #context.mediaCommand el, 'volume', vol
  el.volume = vol

setTime = (el, time) ->
  el._currentPlaybackPosition = time
  fireSimpleEvent el, 'timeupdate'

setRate = (el, rate) ->
  el._playbackRate = rate
  fireSimpleEvent el, 'ratechange'


setDuration = (el, duration) ->
  el._duration = duration

endedElement = (el) ->
  el._currentPlaybackPosition = el._duration
  fireSimpleEvent el, 'ended'
  el._ownerDocument._defaultView._context.mediaCommand el, 'ended'

togglePlay = (el) ->
  if el.paused
    el.play()
  else
    el.pause()

handleDurationChange = (el, newDuration) ->

effectiveMediaVolume = (el) ->
  return 0 if el.muted or el.controller?._muteOverride
  el.volume * (el.controller?._volumeMultiplier or 1)

populateListOfPendingTracks = (el) ->

resourceSelection = (el) ->
  el._networkState = HTMLMediaElement.NETWORK_NO_SOURCE
  #continue unless el._blockedOnParser

  if !el._blockedOnParser
    populateListOfPendingTracks el

  firstSource = findFirstChild el, (node) -> node.tagName == 'SOURCE'

  if el.src
    mode = 'attribute'
  else if firstSource
    mode = 'children'
  else
    return el._networkState = HTMLMediaElement.NETWORK_EMPTY

  fireSimpleEvent el, 'loadstart'

  failed = ->
    unless el._selectionAborted
      el._error = new MediaError MediaError.MEDIA_ERR_NOT_SUPPORTED
      forgetMediaResourceSpecificTracks el
      el._networkState = HTMLMediaElement.NETWORK_NO_SOURCE

  if mode == 'attribute'
    unless el.src
      return failed()
    absoluteURL = URL.resolve el.ownerDocument.URL, el.src
    el._currentSrc = absoluteURL
    resourceFetch el, absoluteURL
    unless el._selectionAborted
      el._selectionAborted = false
      failed()
      fireSimpleEvent el, 'error'

  else
    sources =  el._childNodes.filter (node) -> node.tagName == 'SOURCE'
    pointer = 0

resourceFetch = (el, url) ->
  el._resource = url


forgetMediaResourceSpecificTracks = (el) ->

exposeMediaSpecificTextTrack = (resource) ->

changeNetworkState = (el, state) ->
  eventName =
    switch state
      when HTMLMediaElement.NETWORK_LOADING then "loadstart"
      when HTMLMediaElement.NETWORK_IDLE then "suspend"
      when HTMLMediaElement.NETWORK_EMPTY then "emptied"
      when HTMLMediaElement.NETWORK_STALLED then "loading"

  fireSimpleEvent el, eventName

changereadystate = (el, state) ->
  current = el._readyState
  if current == HTMLMediaElement.HAVE_NOTHING and state == HTMLMediaElement.HAVE_METADATA
    fireSimpleEvent el, 'loadedmetadata'

  else if current == HTMLMediaElement.HAVE_METADATA and state == HTMLMediaElement.HAVE_CURRENT_DATA
    fireSimpleEvent el, 'loadeddata'

  else if state == HTMLMediaElement.HAVE_ENOUGH_DATA
    if current == HTMLMediaElement.HAVE_CURRENT_DATA
      fireSimpleEvent el, 'canplay'
    unless el.paused
      fireSimpleEvent el, 'playing'

mediaElementLoad = (el) ->
  if el.networkState == HTMLMediaElement.NETWORK_LOADING
    fireSimpleEvent el, 'abort'
  else if el.networkState == HTMLMediaElement.NETWORK_EMPTY
    fireSimpleEvent el, 'emptied'
    el._networkState = HTMLMediaElement.NETWORK_EMPTY
    forgetMediaResourceSpecificTracks el
    if el._readyState != HTMLMediaElement.HAVE_NOTHING
      changeReadyState el, HTMLMediaElement.HAVE_NOTHING
    el._paused = true
    el._seeking = false
    el._currentPlaybackPosition = 0
    if el._officialPlaybackPosition != 0
      el._officialPlaybackPosition = 0
      fireSimpleEvent el, 'timeupdate'
    el._initialPlaybackStartPosition = 0
    # ...

hasEndedPlayback = (el) ->
  return false unless el._readyState >= HTMLMediaElement.HAVE_METADATA
  #return true if el._currentPlaybackPosition
  #return true if
  false

stateToEventName =
  0: 'emptied'
  1: 'loadedmetadata'
  2: 'loadeddata'
  3: 'canplay'
  4: 'canplaythrough'

reportControllerState = (controller) ->
  if !controller._slaveMediaElements.length
    readinessState = 0
  else
    readinessState = mapmin controller._slaveMediaElements, (el) -> el.readyState

  nextState = controller._mostRecentlyReportedState
  if nextState < readinessState
    while nextState < readinessState
      nextState++
      controller._readyState = nextState
      fireSimpleEvent controller, stateToEventName[nextState]
  else
    fireSimpleEvent controller, stateToEventName[readinessState]

  controller._mostRecentlyReportedState = readinessState

  if !controller._slaveMediaElements.length
    newPlaybackState = 'waited'

mediaElementsOf = (doc) ->
  preorder(doc).filter (node) -> node.tagName.test /(VIDEO|AUDIO)/

bringMediaElementUpToSpeedWithNewController = (el) ->

mediaGroupUpdate = (m) ->
  oldController = m._controller
  newController = null

  m._controller = null

  mediagroup = m.mediagroup

  if mediagroup
    mediaElements = mediaElementsOf m.ownerDocument
    for other in mediaElements when other != m
      if other.mediagroup == mediagroup
        newController = other._controller
        break

    unless controller
      newController = new MediaController

    m._controller = newController

  return if oldController == newController

  if oldController and oldController._slaveMediaElements.length
    reportControllerState oldController

  if newController
    reportControllerState newController

populateListOfPendingTextTracks = (el) ->
  tracks = []
  for child in el.children
    if child.tagName == 'TRACK' and not child.disabled
      tracks.push child

class MediaError
  @MEDIA_ERR_ABORTED: 1
  @MEDIA_ERR_NETWORK: 2
  @MEDIA_ERR_DECODE: 3
  @MEDIA_ERR_NOT_SUPPORTED: 4
  constructor: (@code) ->

class TextTrackList
  @get length: ->
  @events ['addtrack', 'removetrack']
  constructor: (el) ->

class TextTrackCue extends EventTarget
  @events ['enter', 'exit']
  getCueAsHTML: -> @text
  constructor: (@startTime, @endTime, @text) ->
    @id = ''
    @pauseOnExit = false
    @vertical = ''
    @snapToLines = true
    @line = "auto"
    @position = 50
    @size = 100
    @align = "middle"

class TextTrackCueList

TEXT_TRACK_DISABLED = 0
TEXT_TRACK_HIDDEN = 1
TEXT_TRACK_SHOWING = 2

class TextTrack extends EventTarget
  @readonly ['kind', 'label', 'language', 'inBandMetadataTrackDispatchType', 'cues', 'activeCues']
  @events ['cuechange']

  addCue: (cue) ->
    @_textTrackCues.push cue
    return

  removeCue: (cue) ->
    index = @_textTrackCues.indexOf cue
    @_textTrackCues.splice index, 1
    return

  constructor: (@_kind, @_label, @_language, @_inBandMetadataTrackDispatchType) ->
    @_textTrackCues = []

class TimeRanges
  @get length: -> @ranges.length

  start: (index) ->
    unless 0 <= index < @length
      throw new DOMException INDEX_SIZE_ERR

    @ranges[index][0]

  end: (index) ->
    unless 0 <= index < @length
      throw new DOMException INDEX_SIZE_ERR

    @ranges[index][1]

  constructor: (@ranges) ->

class MediaController extends EventTarget
  @readonly ['readyState', 'buffered', 'seekable', 'duration', 'paused', 'playbackState', 'played']
  @events ['emptied', 'loadedmetadata', 'loadeddata', 'canplay', 'canplaythrough', 'playing', 'ended', 'waiting', 'durationchange', 'timeupdate', 'play', 'pause', 'ratechange', 'volumechange']

  pause: ->
  play: ->

  @define
    volume:
      get: ->
        @_volumeMultiplier
      set: (v) ->
        unless 0 <= v <= 1
          throw new DOMException INDEX_SIZE_ERR

        @_volumeMultiplier = v
        fireSimpleEvent @, 'volumechange'

    playbackRate:
      get: ->
        @_playbackRate
      set: (v) ->
        unless 0 <= v <= 1
          throw new DOMException INDEX_SIZE_ERR

        @_playbackRate = v
        fireSimpleEvent @, 'ratechange'

    defaultPlaybackRate:
      get: ->
        @_defaultPlaybackRate

      set: (v) ->
        unless 0 <= v <= 1
          throw new DOMException INDEX_SIZE_ERR

        @_defaultPlaybackRate = v
        fireSimpleEvent @, 'ratechange'

  constructor: ->
    @_readyState = HTMLMediaElement.HAVE_NOTHING
    @_slaveMediaElements = []
    @_volumeMultiplier = 1
    @_muteOverride = false
    @_playbackRate = 1
    @_defaultPlaybackRate = 1

effectiveMediaVolume = (el) ->
  return 0 if el.getAttribute('muted') or el._controller?._muteOverride
  el.volume * (el._controller?._volumeMultiplier or 1)

class HTMLMediaElement extends HTMLElement
  @NETWORK_EMPTY: 0
  @NETWORK_IDLE: 1
  @NETWORK_LOADING: 2
  @NETWORK_NO_SOURCE: 3

  @HAVE_NOTHING: 0
  @HAVE_METADATA: 1
  @HAVE_CURRENT_DATA: 2
  @HAVE_FUTURE_DATA: 3
  @HAVE_ENOUGH_DATA: 4

  @readonly ['networkState', 'buffered', 'currentSrc', 'error', 'seeking']
  @reflect ['src', 'crossOrigin', 'preload', 'mediaGroup']
  @reflect type: 'bool', ['controls', {attr: 'muted', prop: 'defaultMuted'}]

  @get
    duration: -> @_duration

    audioTracks: ->

    videoTracks: ->

    textTracks: ->

    played: ->
      new TimeRanges []

  @define
    currentTime:
      get: -> @_currentPlaybackPosition

      set: (v) ->
        return if @_networkState == HTMLMediaElement.HAVE_NOTHING

        @_seeking = true
        fireSimpleEvent @, 'seeking'

        @_seeking = false
        fireSimpleEvent @, 'timeupdate'
        fireSimpleEvent @, 'seeked'

    volume:
      get: ->
        @_volume

      set: (vol) ->
        unless 0 <= v <= 1
          throw new DOMException INDEX_SIZE_ERR

        @_volume = v
        fireSimpleEvent @, 'volumechange'

  addTextTrack: (kind, label, language) ->

  paused: true
  @set paused: (v) ->
    return if v == @paused
    if v then @play() else @pause()

  play: ->
    if @_networkState == HTMLMediaElement.NETWORK_EMPTY
      resourceSelection @

  pause: ->
    if @_networkState == HTMLMediaElement.NETWORK_EMPTY
      resourceSelection @

    @_autoplaying = false

    unless @paused
      @paused = true
      fireSimpleEvent @, 'timeupdate'
      fireSimpleEvent @, 'pause'
      @_officialPlaybackPosition = @_currentPlaybackPosition

    reportControllerState @_controller if @_controller

  load: ->

  @define
    controller:
      get: -> @_controller
      set: (newController) ->
        oldController = @_controller

  constructor: (args...) ->
    super args...

    @_currentPlaybackPosition = 0
    @_officialPlaybackPosition = 0
    @_defaultPlaybackStartPosition = 0
    @_initialPlaybackStartPosition = 0
    @_pendingTracks = []
    @_textTracks = []
    @_controller = null
    @_autoplaying = true
    @_resource = null
    @_volume = 1

    if @mediagroup
      mediaGroupUpdate @

    @addEventListener 'DOMAttrModified', ({attrName}) ->
      mediaGroupUpdate @ if attrName == 'mediagroup'

class HTMLAudioElement extends HTMLMediaElement

class AudioTrackList extends EventTarget
  @events ['change', 'addtrack', 'removetrack']
  getTrackById: (index) ->

class AudioTrack
  @readonly ['id', 'kind', 'label', 'language']
  @define
    enabled:
      get: ->
      set: (b) ->

class HTMLTrackElement extends HTMLMediaElement
  @reflect ['kind', 'srclang', 'label']
  @reflect type: 'bool', ['default']

  @NONE: 0
  @LOADING: 1
  @LOADED: 2
  @ERROR: 3

  @readonly ['readyState', 'track']

class HTMLVideoElement extends HTMLMediaElement


class VideoTrackList extends EventTarget
  @events ['change', 'addtrack', 'removetrack']
  getTrackById: (index) ->

class VideoTrack
  @readonly ['id', 'kind', 'label', 'language']
  @define
    enabled:
      get: ->
      set: (b) ->

class HTMLSourceElement extends HTMLMediaElement
  @reflect treatNullAs: '', ['src', 'type', 'media']

module.exports = {MediaError, TimeRanges, HTMLAudioElement, HTMLVideoElement, HTMLTrackElement, HTMLSourceElement, effectiveMediaVolume, setTime, setDuration}
