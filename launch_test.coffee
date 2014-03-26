{Browser} = require './browser'
BrowserShell = require './browser_shell'
PageServer = require './pageserver'

PageServer.start 1859

PORT = 8594

browser = new Browser
browser.startBrowserContextREPL PORT
tab = browser.createTab()
#repl.context.tab = tab

[path] = process.argv.slice(-1)

tab.navigate "http://localhost:1859/#{path or ''}"

BrowserShell.start PORT

