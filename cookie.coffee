require './dom/meta'

net = require 'net'
punycode = require 'punycode'
URL = require 'url'

{zipmap} = require './dom/helpers'

DATE_DELIM = /[\x09\x20-\x2F\x3B-\x40\x5B-\x60\x7B-\x7E]/
TOKEN = /[\x21\x23-\x26\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/
COOKIE_OCTET  = /[\x21\x23-\x2B\x2D-\x3A\x3C-\x5B\x5D-\x7E]/
COOKIE_OCTETS = /^[\x21\x23-\x2B\x2D-\x3A\x3C-\x5B\x5D-\x7E]+$/
COOKIE_PAIR_STRICT = new RegExp '^('+TOKEN.source+'+)=("?)('+COOKIE_OCTET.source+'*)\\2'
COOKIE_PAIR = /^([^=\s]+)\s*=\s*(\"?)\s*(.*)\s*\2/
NON_CTL_SEMICOLON = /[\x20-\x3A\x3C-\x7E]+/
EXTENSION_AV = NON_CTL_SEMICOLON
PATH_VALUE = NON_CTL_SEMICOLON

TRAILING_SEMICOLON = /;+$/

DAY_OF_MONTH = /^(0?[1-9]|[12][0-9]|3[01])$/
TIME = /(0?[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])/
MONTH = /^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)$/i

MONTHS = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
YEAR = /^([1-9][0-9]{1,3})$/

MAX_TIME = 2147483647000
MAX_DATE = new Date MAX_TIME
MIN_TIME = 0
MIN_DATE = new Date MIN_TIME

MONTH_TO_NUM = zipmap MONTHS, [0..11]

processPath = (path) ->
  return '/' if !path or path.indexOf('/') != 0 or path == '/'
  path[0..path.lastIndexOf('/')]

cookieCompare = (a, b) ->
  deltaLen = (b.path?.length or 0) - (a.path?.length or 0)
  return deltaLen unless deltaLen == 0
  b.creationTime.getTime() - a.creationTime.getTime()

domainMatch = (str, domainStr) ->
  return true if str == domainStr
  index = str.indexOf domainStr
  return false if index == -1
  return false if index + domainStr.length != str.length
  return false if str[index - 1] != '.'
  return false unless net.isIP str

pathMatch = (str, path) ->
  return true if str == path
  if str.indexOf(path) == 0
    return true if path.slice(-1) == '/'
    return true if str.substr[path.length] == '/'
  false

parseDate = (s) ->
  return unless s

  foundTime = false
  foundDOM = false
  foundMonth = false
  foundYear = false

  tokens = s.split DATE_DELIM

  date = new Date
  date.setMilliseconds 0

  for token in tokens
    token = token.trim()
    continue unless token.length

    unless foundTime
      result = TIME.exec token
      if result
        foundTime = true
        [_, hours, minutes, seconds] = result
        date.setUTCHours hours
        date.setUTCMinutes minutes
        date.setUTCSeconds seconds
        continue

    unless foundDOM
      result = DAY_OF_MONTH.exec token
      console.log 'dom', result
      if result
        foundDOM = true
        date.setUTCDate result[1]
        continue

    unless foundMonth
      result = MONTH.exec token
      console.log 'month', result
      if result
        foundMonth = true
        date.setUTCMonth MONTH_TO_NUM[result[1].toLowerCase()]

    unless foundYear
      result = YEAR.exec token
      if result
        [year] = result

        if 70 <= year <= 99
          year += 1900

        else if year <= 69
          year += 2000

        if year < 1601
          return

        foundYear = true
        date.setUTCFullYear year
        continue

  return unless foundTime or foundDOM or foundMonth or foundYear
  date

canonicalDomain = (str) ->
  return null if str == null

  str = str.trim().replace /^\./, ''

  if /[^\u0001-\u007f]/.test str
    str = punycode.toASCII(str)

  str.toLowerCase()

class CookieJar
  constructor: (opts = {}) ->
    @rejectPublicSuffixes = opts.rejectPublicSuffixes or false
    @cookies = []

  addCookie: (url, cookieString) ->
    console.log 'adding cookie', {url, cookieString}

    cookie = Cookie.parse cookieString
    #if @rejectPublicSuffixes

    urlObj = URL.parse url
    hostname = canonicalDomain urlObj.hostname

    if cookie.domain
      return unless domainMatch hostname, cookie.canonicalDomain()

      if cookie.hostOnly
        cookie.hostOnly = false

    else
      cookie.hostOnly = true
      cookie.domain = hostname

    cookie.path = processPath (cookie.path or urlObj.pathname)

    @cookies.push cookie

  getCookies: (url, cb) ->
    console.log 'getCookies', url

    urlObj = URL.parse url
    host = canonicalDomain urlObj.hostname
    path = urlObj.pathname or '/'

    isSecure = /^(wss:|https:)$/.test urlObj.protocol

    matches = @cookies.filter (cookie) ->
      return false unless domainMatch host, cookie.domain
      return false unless pathMatch path, cookie.path
      return false if cookie.secure and not isSecure
      return false if cookie.hasExpired()
      true

    matches.sort cookieCompare

    uniqueMatches = []
    seen = {}
    for match in matches
      unless seen[match.key]
        uniqueMatches.push match
        seen[match.key] = true

    now = new Date
    uniqueMatches.forEach (cookie) -> cookie.lastAccessed = now

    cb null, uniqueMatches

  getCookiesSync: (url) ->
    urlObj = URL.parse url
    host = canonicalDomain urlObj.hostname
    path = urlObj.pathname or '/'

    isSecure = /^(wss:|https:)$/.test urlObj.protocol

    matches = @cookies.filter (cookie) ->
      return false unless domainMatch host, cookie.domain
      return false unless pathMatch path, cookie.path
      return false if cookie.secure and not isSecure
      return false if cookie.hasExpired()
      true

    matches.sort cookieCompare

    uniqueMatches = []
    seen = {}
    for match in matches
      unless seen[match.key]
        uniqueMatches.push match
        seen[match.key] = true

    now = new Date
    uniqueMatches.forEach (cookie) -> cookie.lastAccessed = now

    uniqueMatches

  getCookieStringSync: (url) ->
    @getCookiesSync(url).map( (cookie) -> cookie.toString() ).join '; '

  getCookieString: (url, cb) ->
    @getCookies url, (err, cookies) ->
      return cb err if err
      cb null, cookies.map( (cookie) -> cookie.toString() ).join '; '

  serialize: ->
    JSON.stringify @cookies.map (cookie) -> cookie.toObject()

  toObject: ->
    @cookies.map (cookie) -> cookie.toObject()

  clone: ->
    clone = new CookieJar
    clone.cookies = @cookies.map (cookie) -> cookie.clone()
    clone

  @deserialize: (cookies) ->
    @fromObject JSON.parse cookies

  @fromObject: (serializedCookies) ->
    cookies = serializedCookies.map (cookie) -> Cookie.fromObject cookie

    cj = new CookieJar
    cj.cookies = cookies
    cj

class Cookie
  constructor: ({@key, @value, @secure, @expires, @httpOnly, @maxAge, @domain, @path, @creationTime, @extensions, @lastAccessed}) ->
    @secure ?= false
    @httpOnly ?= false
    @maxAge ?= null
    @expires ?= null
    @domain ?= null
    @path ?= null
    @extensions ?= []
    @creationTime ?= new Date
    @lastAccessed ?= new Date

  hasExpired: ->
    now = new Date

    if @maxAge
      expirationTime = new Date @creationTime
      expirationTime.setTime expirationTime.getTime() + @maxAge * 1000
      now > expirationTime

    else if @expires
      now > @expires

    else
      false

  isPersistent: ->
    @maxAge or @expires != Infinity

  validate: ->
    @expires == Infinity

  canonicalDomain: ->
    canonicalDomain @domain

  toObject: ->
    expires = @expires?.toString() or null
    creationTime = @creationTime.toString()
    {expires, creationTime, @key, @value, @secure, @httpOnly, @maxAge, @domain, @path, @extensions}

  serialize: ->
    JSON.stringify @toObject()

  clone: ->
    JSON.deserialize @serialize()

  toString: ->
    if !@value or COOKIE_OCTETS.test @value
      "#{@key}=#{@value}"
    else
      "#{@key}=\"#{@value}\""

  @deserialize: (serialized) ->
    {expires, creationTime} = serialized
    expires = new Date expires
    creationTime = new Date creationTime
    new Cookie {expires, creationTime, @key, @value, @secure, @httpOnly, @maxAge, @domain, @path}

  @parse: (cookieString) ->
    cookieString = cookieString.replace /;+$/, ''
    firstSemicolon = cookieString.indexOf ';'

    if firstSemicolon != -1
      result = COOKIE_PAIR.exec cookieString.slice 0, firstSemicolon
    else
      result = COOKIE_PAIR.exec cookieString

    return unless result
    [_, key, _, value] = result

    if firstSemicolon != -1
      unparsed = cookieString[firstSemicolon + 1..].replace(/^\s*;\s*/,'').trim()
      cookieAVs = unparsed.split /\s*;\s*/

      extensions = []

      for cookieAV in cookieAVs
        equalsIndex = cookieAV.indexOf '='
        if equalsIndex == -1
          AVKey = cookieAV
          AVValue = null
        else
          [AVKey, AVValue] = cookieAV.split '='

        AVKey = AVKey.trim().toLowerCase()
        AVValue = AVValue.trim() if AVValue

        switch AVKey
          when 'expires'
            break unless AVValue
            expires = new Date AVValue

          when 'max-age'
            break unless AVValue
            delta = parseInt AVValue
            break if delta <= 0
            maxAge = delta

          when 'domain'
            break unless AVValue
            domain = AVValue.trim().replace /^\./, ''

          when 'path'
            break unless AVValue
            path = AVValue

          when 'secure'
            secure = true

          when 'httponly'
            httpOnly = true

          else
            extensions.push [AVKey, AVValue]

    new Cookie {key, value, expires, secure, httpOnly, path, maxAge, domain, extensions}

module.exports = {CookieJar, Cookie}
