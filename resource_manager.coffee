URL = require 'url'
{Queue} = require './queue'
http = require 'http'
https = require 'https'

class ResourceManager extends Queue
  constructor: (@context) ->
    {@cookieJar} = context
    @visited = []
    super

  userAgent: "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17"

  setCookies: (url, setCookieHeader) ->
    console.log "SETTING COOKIES"

    return unless setCookieHeader

    addCookie = (cookieString) =>
      console.log "add cookie w/ url #{url} & string #{cookieString}"
      @cookieJar.addCookie url, cookieString

      # @cookies.setCookie cookieString, url, {}, (err, cookie) =>
      #   @getCookieString url, (err, s) =>
      #     @context.cookieString = s

    if Array.isArray setCookieHeader
      setCookieHeader.forEach addCookie
    else
      addCookie setCookieHeader

  request: ({url, method, referrer, body, contentType}, cb) ->
    @cookieJar.getCookieString url, (err, cookieString) =>
      return cb?(err) if err

      {protocol, hostname, port, path} = URL.parse url

      if protocol == 'http:'
        requester = http
      else if protocol == 'https:'
        requester = https
      else
        return cb? "Protocol not supported"

      console.log "cookiestring for #{url} is #{cookieString}"

      headers =
        Cookie: cookieString
        'User-Agent': @userAgent

      if referrer
        headers['Referer'] = referrer
      if contentType
        headers['Content-Type'] = contentType

      if body
        if Array.isArray body
          length = 0
          for entry in body
            length += entry.length
        else
          length = body.length

        headers['Content-Length'] = length

      options = {protocol, hostname, port, path, headers, method}

      req = requester.request options, (res) =>
        console.log res.statusCode, 'res headers', res.headers

        if setCookieHeader = res.headers['set-cookie']
          @setCookies url, setCookieHeader

        if 300 <= res.statusCode < 400 and location = res.headers.location
          url = URL.resolve url, location
          return @request {url, method: 'GET', referrer, cookieString}, cb

        data = []
        res.on 'data', (chunk) ->
          data.push chunk
        res.on 'end', ->
          cb? null, res, data.join('')

      req.on 'error', (err) ->
        cb? err

      if body
        console.log 'writing body', body
        if Array.isArray body
          for entry in body
            req.write entry
        else
          req.write body

      req.end()

  fetchResource: (opts, cb) ->
    @enqueue (done, task) =>
      #task.on 'abort', done
      @fetch opts, (ret...) =>
        done()
        cb? ret...

  fetch: ({url, method, referrer, formData, contentType}, cb) ->
    {host} = URL.parse(url)
    @context.emit 'status-changed', "Waiting for #{host}..."

    method ?= "GET"

    if formData
      switch method
        when "GET"
          if contentType == "application/x-www-form-urlencoded"
            url = URL.resolve url, "?#{formData}"
        when "POST"
          unless Array.isArray formData
            body = new Buffer formData
          else
            body = formData

    console.log "making a #{method} request", formData, url

    @request {url, method, referrer, body, contentType}, (err, res, body) =>
      return cb(err) if err

      @context.emit 'status-changed', "Transferring data from #{host}..."
      contentType = res.headers['content-type']
      lastModified = res.headers['last-modified']
      statusCode = res.statusCode

      cb? err, {body, contentType, lastModified, statusCode}
      @context.emit 'status-changed', ""

module.exports = {ResourceManager}
