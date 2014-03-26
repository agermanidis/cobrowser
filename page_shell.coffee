readline = require 'readline'
net = require 'net'

client = net.createConnection 8595, ->
  tabId = process.argv.slice(-1)[0]
  options = id: tabId

  if "--coffee" in process.argv
    options.language = 'coffeescript'
    console.log "Using Coffee-Script"

  client.write JSON.stringify options
  console.log "Connected to JSDOM server"
  replStart()

client.on 'data', (data) ->
  console.log data.toString().replace('\n','')
  repl.prompt()

repl = readline.createInterface process.stdin, process.stdout

replStart = ->
  repl.setPrompt 'POMO> '
  repl.prompt()

  repl.on 'line', (line) ->
    client.write line


