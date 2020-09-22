HideBrokenSnap = ->
  $('#message.snapshot-proxy').on 'error', ->
    @src = '/assets/offline.png'
    @removeclassName = 'snapshot-proxy snapshot-refresh'
    @className = 'no-thumbnail'
    true

RemoveDropdown = ->
  $("#Intercom").on "click", ->
    $('#live_support').removeClass('open')

window.initializeHeader = ->
  HideBrokenSnap()
  RemoveDropdown()
