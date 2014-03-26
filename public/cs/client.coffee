socket = io.connect '/client'

guid = ->
  S4 = ->
    (((1+Math.random())*0x10000)|0).toString(16).substring(1)
  S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4()

userId = guid()

tabSelected = null
tabElementSelected = null

setUrl = (url) ->
  socket.emit 'navigate', tabSelected, url

socket.on 'session-changed', (tab_id, context) ->
  console.log 'session changed', tab_id, context
  tabStore[tab_id] = context
  getTabNavigator(tab_id).textContent = context.title

  if tabSelected == tab_id
    updateContext context

socket.on 'status-changed', (tab_id, msg) ->
  return unless tabSelected == tab_id
  $("#status").html msg or ""

existsTab = (id) ->
  !!getTabIframe(id)

socket.on 'tab-created', (id, forceNavigate) ->
  unless existsTab id
    createTabIframe id
    createNavigatorElement id, "about:blank"
    #selectTab id if forceNavigate

socket.on 'tab-destroyed', ->

updateContext = ({url, title, hasNextEntries, hasPreviousEntries}) ->
  console.log "updating context"
  $("#addressBar").val url

  if hasPreviousEntries
    $("#back").removeAttr "disabled"
  else
    $("#back").attr "disabled", "disabled"

  if hasNextEntries
    $("#forward").removeAttr "disabled"
  else
    $("#forward").attr "disabled", "disabled"

logMessage = (message) ->
  logDiv = document.getElementById("log")
  messageElement = document.createElement('p')
  messageElement.innerText = message
  logDiv.appendChild messageElement

socket.on 'log', (message) ->
  logMessage message

getTabIframe = (id) ->
  document.getElementById("tab-#{id}")

getTabNavigator = (id) ->
  document.getElementById("navigator-#{id}")

selectTab = (id) ->
  tab = getTabIframe id
  $(".tab-navigator").removeClass "selected"
  $(".tab").hide()
  $(tab).show()
  tabSelected = id
  tabElementSelected = tab
  navigator = $("#navigator-#{id}")[0]
  navigator.classList.add("selected")
  navigator.textContent = tabStore[id].title or "about:blank"

  $("#tab-id").html id

  updateContext tabStore[id]

createTabIframe = (id) ->
  iframe = document.createElement("iframe")
  iframe.src = "/tab?id=#{id}&userId=#{userId}"
  iframe.id = "tab-#{id}"
  iframe.className = "tab"
  tabContainer = document.getElementById("tab-container")
  tabContainer.appendChild(iframe)

createNavigatorElement = (id, title) ->
  #console.log 'creating navigator element', {id, title}
  navigatorElement = document.createElement "li"
  #navigatorElement.textContent = title
  navigatorElement.id = "navigator-#{id}"
  navigatorElement.className = "tab-navigator"
  $(navigatorElement).click ->
    selectTab id
  $("#tab-navigator").append navigatorElement

addressBar = null

navigateToRandomTab = ->
  for k, v of tabStore
    selectTab k
    return

createTab = (url = "http://news.ycombinator.com") ->
  #$.getJSON "/create_tab", {url}, ({id, tab}) ->
  $.getJSON "/create_tab", {url, userId}, ({id}) ->
    #tabStore[id] = tab
    createTabIframe id
    createNavigatorElement id#, tab.title
    selectTab id

window.onload = ->
  hasTabs = false

  for id, {address, title} of tabStore
    hasTabs = true
    createTabIframe id
    createNavigatorElement id, title
    selectTab id unless tabSelected

  unless hasTabs
    createTab()

  $("#addressBar").keypress ({which}) ->
    if which == 13
      setUrl @value

  $("#create-tab").click (evt) ->
    createTab()

  $("#destroy-tab").click (evt) ->
    if tabSelected
      $.get "/destroy_tab", id: tabSelected, ->
        tabElementSelected.parentNode.removeChild tabElementSelected
        navigator = getTabNavigator tabSelected
        navigator.parentNode.removeChild navigator
        delete tabStore[tabSelected]
        tabSelected = null
        tabElementSelected = null
        navigateToRandomTab()

  $("#back").click (evt) ->
    socket.emit 'back', tabSelected

  $("#forward").click (evt) ->
    socket.emit 'forward', tabSelected

  $("#reload").click (evt) ->
    socket.emit 'reload', tabSelected

  $("#open-tab").click (evt) ->
    window.open("/tab?id=#{tabSelected}")
