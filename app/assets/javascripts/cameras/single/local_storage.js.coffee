window.localwidgetLoaded = false
playbackUrl = 'https://playback.azurewebsites.net/home/doc/page/main.aspx'

initLocalStorage = ->
  window.localwidgetLoaded = true
  iframe = jQuery('<iframe />').css(
    'overflow-y': 'hidden'
    'overflow-x': 'scroll'
    'width': '100%'
    'height': '640px').attr(
    'src': playbackUrl + "?camera=#{Evercam.Camera.id}&api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
    'frameborder': '0').appendTo('div[evercam=\'localstorage\']')

handleTabOpen = ->
  $('.nav-tab-local-storage').on 'show.bs.tab', ->
    unless window.localwidgetLoaded
      initLocalStorage()

window.initializeLocalStorageTab = ->
  handleTabOpen()
