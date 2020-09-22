flashDetection = ->
  hasFlash = false
  try
    flash = new ActiveXObject('ShockwaveFlash.ShockwaveFlash')
    if flash
      hasFlash = true
  catch e
    if navigator.mimeTypes and navigator.mimeTypes['application/x-shockwave-flash'] != undefined and navigator.mimeTypes['application/x-shockwave-flash'].enabledPlugin
      hasFlash = true

  if hasFlash is true
    $('.flash-section .yes-flash').removeClass('hide')
    $('.flash-section .no-flash').addClass('hide')
  else
    $('.flash-section .no-flash').removeClass('hide')
    $('.flash-section .yes-flash').addClass('hide')

osAndBrowserDetection = ->
  userAgent = navigator.userAgent.toLowerCase()
  $('.os-section .os-info').html '<i class="no-icon fa fa-check green icon-font"></i> Running OS is: <span><b>' + navigator.platform + '</b></span>'
  $('.browser-section .browser-info').html '<i class="no-icon fa fa-check green icon-font"></i> Running browser is: <span><b>' + bowser.name + ' ' + bowser.version + '</b></span>'
  $('.javascipt-section .yes-javascript').removeClass('hide')

detectMediaUrlRequest = ->
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (jqXHR, status, error) ->
    $('#yes-blocked').removeClass('hide')
    $('#no-blocked').addClass('hide')

  onSuccess = (response) ->
    $('#no-blocked').removeClass('hide')
    $('#yes-blocked').addClass('hide')

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/json charset=utf-8"
    type: 'GET'
    url: "#{Evercam.MEDIA_API_URL}cameras?api_id#{Evercam.User.api_id}&api_key#{Evercam.User.api_key}"

  sendAJAXRequest(settings)

window.initializeBrowserCompatiblity = ->
  flashDetection()
  osAndBrowserDetection()
  detectMediaUrlRequest()
