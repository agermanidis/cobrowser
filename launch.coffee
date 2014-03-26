{Browser} = require './browser'
BrowserShell = require './browser_shell'
PageServer = require './pageserver'

PageServer.start 1859

PORT = 8594

browser = new Browser
repl = browser.startBrowserREPL PORT
tab = browser.createTab()
repl.context.tab = tab

[url] = process.argv.slice(-1)
tab.navigate url if url

BrowserShell.start PORT

