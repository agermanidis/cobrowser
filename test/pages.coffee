{Browser} = require '../browser'
PageServer = require '../pageserver'
{Node} = require '../dom/node'
{Document} = require '../dom/document'
{Window} = require '../dom/window'
vows = require 'vows'
assert = require 'assert'
{printException, visitTestPage, visitPage} = require '../test_helpers'
{once} = require '../dom/helpers'
{findFirst} = require '../dom/tree_operations'

PORT = 1859
PageServer.start PORT

# switching to mocha as test framework b/c vows is too awkward for async

testPageDescribe = (path, cb) ->
  describe "testing browser on test page #{path}", ->
    browser = new Browser
    tab = browser.createTab()
    before (done) ->
      cb = once done
      tab.navigate "http://localhost:#{PORT}#{path}"
      #tab.on 'load', cb
      setTimeout cb, 1000
    cb tab

pageDescribe = (url, cb) ->
  describe "testing browser on web page @ #{url}", ->
    browser = new Browser
    tab = browser.createTab()
    before (done) ->
      cb = once done
      tab.navigate url
      #tab.on 'load', cb
      setTimeout cb, 3000
    cb tab

fillInForm = (form, kvs) ->
  for k, v of kvs
    if node = form.elements[k]
      node.value = v

clickFormSubmit = (form) ->
  submitButton = findFirst form, (node) -> node.type == 'submit'
  submitButton.click()

testPageDescribe '/simple.html', (tab) ->
  it 'has a document', ->
    assert.isNotNull tab.document
    tab.document.should.be.an.instanceOf Document

    content = tab.document.getElementById('content')

    describe 'document of tab', ->
      it 'extracts the title correctly', ->
        tab.document.title.should.equal 'Hello World'

      it 'finds #content by id', ->
        assert.isNotNull content
        content.should.be.an.instanceOf Node

        describe '#content', ->
          it 'should should have a text content equal to Hi!', ->
            content.textContent.should.equal 'Hi!'

  it 'has a window', ->
    assert.isNotNull tab.window
    tab.window.should.be.an.instanceOf Window

testPageDescribe '/window_variable.html', (tab) ->
  it 'sets window.a = 2', ->
    tab.window.should.have.property 'a', 2

testPageDescribe '/counter.html', (tab) ->
  it.skip 'should update #counter correctly', (done) ->
    counter = tab.document.getElementById 'counter'
    counter.should.be.an.instanceOf Node

    count = 0
    previousContent = counter.textContent

    check = ->
      currentContent = counter.textContent
      currentContent.should.not.equal previousContent
      parseInt(currentContent).should.be.greaterThan parseInt(previousContent)

      previousContent = currentContent

      if count < 3
        count++
        setTimeout check, 1000
      else done()

    setTimeout check, 1000

testPageDescribe '/hashchange.html', (tab) ->
  lastMessage = (document) ->
    messages = document.getElementById 'messages'
    messages.lastChild?.textContent or null

  it 'responds to hashchange after location is set', ->
    tab.window.location = "#abc"

    msg = lastMessage(tab.document)
    assert.isNotNull msg
    msg.should.equal "#abc"

  it 'responds to hashchange after location.hash is set', ->
    tab.window.location.hash = "def"

    msg = lastMessage(tab.document)
    assert.isNotNull msg
    msg.should.equal "#def"

testPageDescribe '/text_script.html', (tab) ->
  it 'sets the textContent of the body to abc': (err, tab) ->
    assert.isFunction tab.window.onload
    tab.document.body.textContent.should.equal 'abc'

testPageDescribe '/src_script.html', (tab) ->
  it 'sets the textContent of the body to doodoo': (err, tab) ->
    assert.isFunction tab.window.onload
    tab.document.body.textContent.should.equal 'doodoo'

testPageDescribe '/jquery.html', (tab) ->
  it.only 'has loaded jquery on window', ->
    tab.window.should.have.property '$'

  it 'executes the jquery code thereby setting document.body to Hello World', ->
    tab.document.body.textContent.should.match /Hello world/

testPageDescribe '/a.html', (tab) ->
  it 'navigates to b.html after location is set', (done) ->
    tab.window.location = 'b.html'

    tab.on 'session-changed', ->
      tab.document.body.textContent.should.equal 'B'
      done()

testPageDescribe '/ajax.html', (tab) ->
  it 'fetches json from server and updates document.body', ->
    tab.document.body.textContent.should.equal 'success'

testPageDescribe '/iframe_src.html', (tab) ->
  it 'creates a window for the frame', ->
    tab.childContexts.should.not.be.empty

  it 'has an simple.html open on the iframe element w/ textContent Hi!', ->
    iframe = tab.document.getElementsByTagName('iframe')[0]
    assert.isObject iframe.contentDocument
    iframe.contentDocument.body.textContent.should.match /Hi!/

testPageDescribe '/iframe_srcdoc.html', (tab) ->
  it 'loads the srcdoc and displays body textContent Hi!', ->
    iframe = tab.document.getElementsByTagName('iframe')[0]
    assert.isObject iframe.contentDocument
    iframe.contentDocument.body.textContent.should.match /Hi!/

pageDescribe 'http://google.com', (tab) ->
  it 'loads successfully', ->
    assert.isObject tab.document

pageDescribe 'http://amazon.com', (tab) ->
  it 'loads successfully', ->
    assert.isObject tab.document

pageDescribe 'http://news.ycombinator.com/login', (tab) ->
  it.only 'loads successfully', ->
    assert.isObject tab.document
