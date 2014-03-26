{Browser} = require './browser'
PageServer = require './pageserver'

PORT = 1859
PageServer.start PORT

browser = new Browser
browser.createTab (tab) ->
  tab.navigate "http://localhost:#{PORT}/simple.html"
  tab.on 'session-changed', ->
    console.log 'session did change'

