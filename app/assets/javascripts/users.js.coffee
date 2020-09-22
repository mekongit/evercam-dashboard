showError = (message) ->
  Notification.show(message)
  true

showFeedback = (message) ->
  Notification.show(message)
  true

handleScrollToEvents = ->
  # Javascript to enable link to tab
url = document.location.toString()
if url.match("#")
  $(".nav-tabs a[href=#" + url.split("#")[1] + "]").tab "show"
  setTimeout (->
    scrollTo 0, 0
    return
  ), 2

# Change hash for page-reload
$(".nav-tabs a").on "shown.bs.tab", (e) ->
  window.location.hash = e.target.hash
  scrollTo 0, 0

initialize = ->
  Notification.init(".bb-alert")
  true

if !window.Evercam
  window.Evercam = {}

window.Evercam.Users =
  initialize: initialize

jQuery ->
$('div').tooltip();

