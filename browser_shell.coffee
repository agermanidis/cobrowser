readline = require 'readline'
net = require 'net'

PORT = 8594

BrowserShell = module.exports =
  start: (port = PORT, coffee = yes) ->
    client = @client = net.createConnection port, ->
      tabId = process.argv.slice(-1)[0]
      options = {}

      if "--coffee" in process.argv or coffee
        options.language = 'coffeescript'
        console.log "Using Coffee-Script"

      client.write JSON.stringify options
      console.log "Connected to browser"
      replStart()

    client.on 'data', (data) ->
      console.log data.toString().replace('\n','')
      repl.prompt()

    repl = @repl = readline.createInterface process.stdin, process.stdout

    replStart = ->
      repl.setPrompt 'POMO> '
      repl.prompt()

      repl.on 'line', (line) ->
        client.write line

  close: ->
    @client.close()
    @repl.close()

if require.main == module
  console.log 'starting browser shell'
  BrowserShell.start()

