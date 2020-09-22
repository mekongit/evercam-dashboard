stream_paused = false
img_real_width = 0
img_real_height = 0
live_view_timestamp = 0
image_placeholder = null
camera_host = null
tries = 0
clear_timeout_videojs = null
is_logged_intercom = false
timoutWarning = 120000
warningTimer = undefined
timeoutTimer = undefined
zoom_level = 0

controlButtonEvents = ->
  $(".play-pause").on "click", ->
    if stream_paused
      $(this).children().removeClass "fa-play"
      $(this).children().addClass "fa-pause"
      $(this).children().attr "title", "Pause"
      playJpegStream()
    else
      $(this).children().removeClass "fa-pause"
      $(this).children().addClass "fa-play"
      $(this).children().attr "title", "Play"
      stopJpegStream()
    stream_paused = !stream_paused

  $('#refresh-offline-camera').on "click", ->
    $('.fa-still').css 'display', 'none'
    $('.fa-spin').css 'display', 'block'
    refreshCameraStatus()

hidegif = ->
  $('.fa-spin').css 'display', 'none'
  $('.fa-still').css 'display', 'block'

refreshCameraStatus = ->
  NProgress.start()
  data = {}

  onError = (jqXHR, status, error) ->
    message = jqXHR.responseJSON.message
    Notification.error message
    hidegif()
    NProgress.done()

  onSuccess = (data, status, jqXHR) ->
    NProgress.done()
    hidegif()
    location.reload()


  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/x-www-form-urlencoded"
    type: 'POST'
    url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/recordings/snapshots?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"

  sendAJAXRequest(settings)

fullscreenImage = ->
  $("#toggle").click ->
    screenfull.toggle $("#live-player-image")[0]
  $("#live-player-image").dblclick ->
    screenfull.toggle $(this)[0]

  if screenfull.enabled
    document.addEventListener screenfull.raw.fullscreenchange, ->
      $("#live-player-image").css({"height": "100%"})
      $("#live-player-image").css({"width": "auto"})
  else
    getImageRealRatio()

openPopout = ->
  $("#link-popout").on "click", ->
    $("<img/>").attr("src", image_placeholder.src).load( ->
      window.open("/live/#{Evercam.Camera.id}", "_blank", "width=#{@width}, height=#{@height}, scrollbars=0")
    ).error ->
      window.open("/live/#{Evercam.Camera.id}", "_blank", "width=640, height=600, scrollbars=0")

initializePlayer = ->
  if /Edge/.test(navigator.userAgent)
    $("#select-stream-type").val("jpeg").trigger("change")
    $('#select-stream-table').hide()
    setInterval (->
      load_jpeg()
    ), 10
  else
    $('#select-stream-table').show()
    window.vjs_player = videojs 'camera-video-player', {
      techOrder: ["flash", "html5"]
    }, ->
      @on 'error', ->
        if !window.is_rtsp_open
          msg = "Port #{$("#ext-rtsp-port").val()} is closed on #{$("#camera-url").val()}."
          Notification.error(msg)
          $(".vjs-error-display div").text(msg)
        setInterval (->
          $("#select-stream-type").val("jpeg").trigger("change")
          load_jpeg()
        ), 1000
    $("#camera-video-player").append($("#ptz-control"))

    tries = 0
    clear_timeout_videojs = setTimeout switch_to_jpeg, 5000
    setInterval (->
      if $('#camera-video-player').hasClass 'vjs-user-active'
        $('#live-view-placeholder .pull-right table').css 'marginTop', '-65px'
        $('#live-view-placeholder .pull-right table').stop().animate()
      else
        $('#live-view-placeholder .pull-right table').animate { 'marginTop': '-39px' }, 500
    ), 10

switch_to_jpeg = ->
  if tries < 11 && window.vjs_player && (window.vjs_player.readyState() == undefined || window.vjs_player.readyState() <= 0)
    tries = tries + 1
    clear_timeout_videojs = setTimeout switch_to_jpeg, 5000
  else if tries >= 11 && window.vjs_player && (window.vjs_player.readyState() == undefined || window.vjs_player.readyState() <= 0)
    snap_height = $("#camera-video-stream").height()
    span_width = $("#camera-video-stream").width()

    $("#camera-video-player .vjs-error-display").removeClass("vjs-hidden")
    $("#camera-video-player .vjs-error-display div").html("<span style='top: #{(snap_height / 2) - 30}px; left: #{(span_width / 2) - 250}px;'
      class='spn-message'>Stream inactive for more than 60 seconds. To continue <a href='#' id='lnk_no_stream'>click here.</a></span>")

  $("#camera-video-stream").on "click", "#lnk_no_stream", ->
    $("#select-stream-type").val("jpeg").trigger("change")
    load_jpeg()

destroyPlayer = ->
  unless $('#camera-video-stream').html() == ''
    $("#jpg-portion").append($("#ptz-control"))
    setTimeout (->
      if window.vjs_player
        if window.vjs_player.isReady_ is true
          window.vjs_player.dispose()
          remove_user_from_feed()
        return
    ), 0
    $("#camera-video-stream").html('')

remove_user_from_feed = ->
  stream_url = $("#hls_stream_url").val()
  if stream_url isnt "" || stream_url isnt null
    api_url = stream_url.replace("/index.m3u8", "")

    onComplete = (result) ->
      true

    settings =
      cache: false
      data: {}
      dataType: 'json'
      error: onComplete
      success: onComplete
      contentType: "application/json; charset=utf-8"
      type: 'DELETE'
      url: api_url
    sendAJAXRequest(settings)

load_jpeg = ->
  destroyPlayer()
  $('.flash-error-message').hide()
  $("#streams").removeClass("active").addClass "inactive"
  $("#fullscreen").removeClass("inactive").addClass "active"
  playJpegStream()
  $('#live-view-placeholder .pull-right table').css 'margin-top', '-39px'
  $('.tabbable-custom > .tab-content').css 'padding-bottom', '0px'
  $("#camera-video-stream").hide()
  $("#camera-video-stream .video-js").css 'height', '0px'
  $(".wrap").css 'padding-top', '0px'
  getImageRealRatio()
  clearTimeout(clear_timeout_videojs)

handleChangeStream = ->
  $("#select-stream-type").on "change", ->
    switch $(this).val()
      when 'jpeg'
        load_jpeg()
      when 'video'
        $('#select-stream-table').show()
        $("#camera-video-stream").html(video_player_html)
        initializePlayer()
        turnOffZoomEffect()
        # flashDetection()
        $("#fullscreen").removeClass("active").addClass "inactive"
        $("#streams").removeClass("inactive").addClass "active"
        stopJpegStream()
        $('#live-view-placeholder .pull-right table').css 'background-color', 'transparent'
        $("#camera-video-stream").show()
        imgHeight = $("#camera-video-stream").height()
        $("#camera-video-stream .video-js").css 'height', "#{imgHeight}px"

handleTabOpen = ->
  $('.nav-tab-live').on 'show.bs.tab', ->
    StartTimers()
    playJpegStream()
    logCameraViewed() unless is_logged_intercom
    if $('#select-stream-type').length
      $("#select-stream-type").trigger "change"

  $('.nav-tab-live').on 'hide.bs.tab', ->
    clearTimeout(clear_timeout_videojs)
    clearTimeout(warningTimer)
    stopJpegStream()
    if $('#select-stream-type').length
      destroyPlayer()

  if $(".nav-tabs li.active a").attr("data-target") is "#live"
    logCameraViewed() unless is_logged_intercom
    if $('#select-stream-type').length
      $("#select-stream-type").trigger "change"
    else
      $(".nav-tabs li.active a").trigger("show.bs.tab")

handleSaveSnapshot = ->
  $('#save-live-snapshot').on 'click', ->
    blob = base64ToBlob($("#live-player-image").attr('src'))
    saveAs(blob, "#{Evercam.Camera.id}-#{moment().toISOString()}.jpg")

  $('#save-offline-snapshot').on 'click', ->
    NProgress.start()
    blob = $("#live .camera-thumbnail").attr('src')
    toDataURL blob, (dataUrl) ->
      console.log 'RESULT:', dataUrl
      blob = base64ToBlob(dataUrl)
      saveAs(blob, "#{Evercam.Camera.id}.png")
      NProgress.done()

toDataURL = (src, callback, outputFormat) ->
  img = new Image
  img.crossOrigin = 'Anonymous'

  img.onload = ->
    canvas = document.createElement('CANVAS')
    ctx = canvas.getContext('2d')
    dataURL = undefined
    canvas.height = @naturalHeight
    canvas.width = @naturalWidth
    ctx.drawImage this, 0, 0
    dataURL = canvas.toDataURL(outputFormat)
    callback dataURL
    return

  img.src = src
  if img.complete or img.complete == undefined
    img.src = 'data:image/png;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=='
    img.src = src
  return

getImageRealRatio = ->
  $('<img/>').attr('src', $("#live-player-image").attr('src')).load ->
    img_real_width = @width
    img_real_height = @height
    offline_img_width = $(".camera-thumbnail").width()
    offline_img_height = $(".camera-thumbnail").height()
    offline_wrap_width = $(".offline-camera-placeholder .wrap").width()
    offline_wrap_height = $(".offline-camera-placeholder .wrap").height()
    offline_height = $(".offline-camera-placeholder .offline-image").height()
    fullscreen_height = $("#fullscreen").height()
    fullscreen_width = $("#fullscreen").width()
    jpeg_img_height = $("#live-player-image").height()
    jpeg_img_width = $("#live-player-image").width()
    play_options_width = $("#jpg-portion .play-options").width()
    play_options_position = $("#fullscreen").height() / 2
    play_options_left_position = ($("#fullscreen").width() - play_options_width) / 2
    $('#jpg-portion .play-options').css({"top": "#{play_options_position}px"})
    if $('.camera-preview-online').hasClass 'hide'
      if offline_img_height > offline_wrap_height ||
      offline_img_width < offline_wrap_width
        $(".offline-image .camera-thumbnail").css({
          "height": "#{offline_wrap_height}px"
        })
        $(".offline-image .camera-thumbnail").css({"width": "auto"})
        $(".offline-image .camera-thumbnail").css({"margin-top": "0px"})
      else
        $(".offline-image .camera-thumbnail").css({"width": "100%"})
        $(".offline-image .camera-thumbnail").css({"height": "auto"})
        if offline_wrap_height == offline_img_height
          setTimeout (-> getImageRealRatio()), 100
        else
          offline_img_align = (offline_wrap_height - offline_img_height) / 2
          $(".offline-image .camera-thumbnail").css({
            "margin-top": "#{offline_img_align}px"
          })
      if offline_img_width is 0
        setTimeout (-> getImageRealRatio()), 100
    else
      if $(window).width() >= 992
        if jpeg_img_height > fullscreen_height ||
        jpeg_img_width < fullscreen_width
          $("#live-player-image").css({"height": "#{fullscreen_height}px"})
          $("#live-player-image").css({"width": "auto"})
          $("#live-player-image").css({"margin-top": "0px"})
        else
          if navigator.appName == 'Microsoft Internet Explorer' or ! !(navigator.userAgent.match(/Trident/) or navigator.userAgent.match(/rv:11/)) or typeof $.browser != 'undefined' and $.browser.msie == 1
            $("#live-player-image").css({"margin-top": "0px"})
          $("#live-player-image").css({"width": "100%"})
          $("#live-player-image").css({"height": "auto"})
          if fullscreen_height == jpeg_img_height
            setTimeout (-> getImageRealRatio()), 100
          else
            jpeg_align = (fullscreen_height - jpeg_img_height) / 2
            $("#live-player-image").css({"margin-top": "#{jpeg_align}px"})
      if img_real_width is 0 && img_real_height is 0
        setTimeout (-> getImageRealRatio()), 100
      if jpeg_img_height is 0
        setTimeout (-> getImageRealRatio()), 100

calculateHeight = ->
  content_width = Metronic.getViewPort().width
  side_bar_width = $(".page-sidebar").width()
  image_height = Metronic.getViewPort().height
  if $(".page-sidebar").css('display') is "none"
    content_width = content_width - side_bar_width

  $("#console-log").text("Real-Width: #{img_real_width}, content-width: #{content_width}")
  if $(".page-sidebar").css('display') is "none" && img_real_width > content_width
    image_height = img_real_height / img_real_width * content_width
  $("#fullscreen").css({"height": "#{image_height}px","max-height": "100%"})
  if $(window).width() >= 992
    $("#camera-video-stream").css({
      "height": "#{image_height}px",
      "max-height": "100%"
    })
    $(".offline-camera-placeholder .offline-image").css({
      "height": "#{image_height}px",
      "width": "100%"
    })
    $("#camera-video-stream .video-js").css({"height": "#{image_height}px"})
  else
    $(".offline-camera-placeholder .offline-image").css({
      "height": "auto",
      "max-height": "100%"
      "width": "100%"
    })
    $("#camera-video-stream").css({"width": "100%"})
    $("#camera-video-stream").css({"height": "auto"})
    $("#camera-video-stream .video-js").css({"width": "100%"})
    $("#camera-video-stream .video-js").css({"height": "auto"})

  snap_height = $("#camera-video-stream").height()
  span_width = $("#camera-video-stream").width()
  $(".spn-message").css({"top": "#{(snap_height / 2) - 30}px", "left": "#{(span_width / 2) - 250}px"})

  if $(window).width() <= 992
    $("#fullscreen").css({"width": "100%"})
    $("#fullscreen").css({"height": "auto"})
    $("#live-player-image").css({"margin-top": "-7px"})
    $(".camera-thumbnail").css({"margin-top": "0px"})
    $(".camera-thumbnail").css({"width": "100%"})
    $(".camera-thumbnail").css({"height": "auto"})

handleResize = ->
  calculateHeight()
  getImageRealRatio()
  centerDiv()
  $(window).resize ->
    calculateHeight()
    getImageRealRatio()
    turnOffZoomEffect()
    centerDiv()

handlePtzCommands = ->
  $(".ptz-controls").on 'click', 'i', ->
    headingText = $('#ptz-control table thead tr th').text()
    $('#ptz-control table thead tr th').html 'Waiting <div class="loader"></div>'
    ptz_command = $(this).attr("data-val")
    if !ptz_command
      return
    api_url = "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/ptz/relative?#{ptz_command}&api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
    if ptz_command is "home"
      api_url = "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/ptz/#{ptz_command}?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
    data = {}

    onComplete = (result) ->
      $('#ptz-control table thead tr th').html headingText

    settings =
      cache: false
      data: data
      dataType: 'json'
      error: onComplete
      success: onComplete
      contentType: "application/json; charset=utf-8"
      type: 'POST'
      url: api_url
    sendAJAXRequest(settings)

getPtzPresets = ->
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onSuccess = (result) ->
    for preset in result.Presets
      if preset.token < 33
        whole_div = $('<div>', {class: "whole-row"})
        divPresets =$('<div>', {class: "row-preset"})
        edit_icon = $('<i>', {class: "fa fa-pencil edit-ptz-ctrl"})
        delete_icon = $('<i>', {class: "fas fa-trash-alt delete-ptz-ctrl"})
        edit_icon.attr("data-dismiss", "modal")
        edit_icon.attr("data-target", "#edit-preset")
        edit_icon.attr("data-toggle", "modal")
        edit_icon.attr("title", "Edit!")
        delete_icon.attr("data-dismiss", "modal")
        delete_icon.attr("data-target", "#delete-preset")
        delete_icon.attr("data-toggle", "modal")
        delete_icon.attr("title", "Delete")
        divPresets.append($(document.createTextNode(preset.Name)))
        divPresets.attr("token_val", preset.token)
        whole_div.append(divPresets)
        whole_div.append(delete_icon)
        whole_div.append(edit_icon)
        $("#presets-table").append(whole_div)
    NProgress.done()

  settings =
    cache: false
    data: data
    dataType: 'json'
    success: onSuccess
    contentType: "application/json; charset=utf-8"
    type: 'GET'
    url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/ptz/presets"
  sendAJAXRequest(settings)

onEditPtz = ->
  $("#camera-presets").on "click", ".edit-ptz-ctrl", ->
    token_value = $(this).closest('div').find('.row-preset').attr("token_val")
    token_name = $(this).closest('div').find(".row-preset").text()
    $("#edit-preset .preset-edit").attr("token_val", token_value)
    $("#edit-preset input").val(token_name)
    callDeletePtz(token_value)

onDeletePtz = ->
  $("#camera-presets").on "click", ".delete-ptz-ctrl", ->
    token_value = $(this).prev(".row-preset").attr("token_val")
    token_name = $(this).prev(".row-preset").text()
    $("#delete-preset .preset-delete").attr("token_val", token_value)
    $("#delete-preset input").val(token_name)
    callDeletePtz(token_value)

callDeletePtz = (token_value) ->
  $("#edit-preset").off('click').on 'click', ".preset-edit", ->
    deletePtzPreset(token_value,1)
  $("#delete-preset").off('click').on 'click', ".preset-delete", ->
    deletePtzPreset(token_value,2)

deletePtzPreset = (token_value,type) ->
  NProgress.start()
  token = token_value
  data = {}

  onError = (jqXHR, status, error) ->
    Notification.error("Something went wrong, Please try again.")

  onSuccess = (data, status, jqXHR) ->
    if type is 1
      token_name = $("#edit-preset input").val()
      createPtzPresets(token_name)
    else
      Notification.info("Preset Deleted Successfully.")
      refreshPresetList()

  settings =
    data: data
    dataType: 'json'
    contentType: "application/x-www-form-urlencoded"
    success: onSuccess
    error: onError
    type: 'GET'
    url: "#{Evercam.MEDIA_API_URL}onvif/v20/PTZ/RemovePreset?id=#{Evercam.Camera.id}&ProfileToken=Profile_1&PresetToken=#{token}&api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
  jQuery.ajax(settings)

changePtzPresets = ->
  $("#camera-presets").off('click').on 'click', '.row-preset', ->
    NProgress.start()
    data = {}

    onSuccess = (data,status,jqXhr)  ->
      NProgress.done()

    settings =
      cache: false
      data: data
      dataType: 'json'
      success: onSuccess
      contentType: "application/json; charset=utf-8"
      type: 'POST'
      url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/ptz/presets/go/#{$(this).attr("token_val")}?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
    sendAJAXRequest(settings)
    $('#camera-presets').modal('hide')

ptzCreation = ->
  $('#create-preset').on 'click', '.add-preset', ->
    preset_name = $('.preset-value').val()
    createPtzPresets(preset_name)

createPtzPresets = (preset_name) ->
  NProgress.start()
  data = {}
  data.preset_name = preset_name

  onError = (jqXHR, status, error) ->
    message = jqXHR.responseJSON.message
    Notification.error message
    NProgress.done()

  onSuccess = (data, status, jqXHR) ->
    Notification.info "Preset Added Successfully"
    refreshPresetList()

  settings =
    cache: false
    data: data
    dataType: 'json'
    success: onSuccess
    error: onError
    type: 'POST'
    contentType: 'application/x-www-form-urlencoded'
    url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/ptz/presets/create?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
  sendAJAXRequest(settings)

refreshPresetList = ->
  $('#presets-table').empty()
  getPtzPresets()

handleModelEvents = ->
  $("#camera-presets").on "show.bs.modal", ->
    $("#ptz-control").addClass("hide")

  $("#camera-presets").on "hidden.bs.modal", ->
    $("#ptz-control").removeClass("hide")
    $('#ptz-control table thead tr th').html 'PTZ'

playJpegStream = ->
  if !Evercam.camera_channel || Evercam.camera_channel.state is "closed"
    Evercam.camera_channel = Evercam.socket.channel("cameras:#{Evercam.Camera.id}")
    Evercam.camera_channel.join()
    Evercam.camera_channel.on 'snapshot-taken', (payload) ->
      $(".btn-live-player").removeClass "hide"
      if !stream_paused
        live_view_timestamp = payload.iso_timestamp
        $('#live-player-image').attr('src', 'data:image/jpeg;base64,' + payload.image)
        $("#live-player-image").attr("data-timestamp", payload.iso_timestamp)
        if $("#live-snapshot-magnifier").hasClass 'enabled'
          $('.zoomWindowContainer').hide()
          $('.zoomContainer div').css 'background-image', 'url(' + 'data:image/jpeg;base64,' + payload.image + ')'

stopJpegStream = ->
  if Evercam.camera_channel
    Evercam.camera_channel.leave()
    Evercam.camera_channel = undefined

checkPTZExist = ->
  if $(".ptz-controls").length > 0
    $('.live-options').css('top','124px').css('right','32px')

$(window).load HideMessage = ->
  if !$(".wrap img#message").hasClass("no-thumbnail")
    $("#offline_message").show()

flashDetection = ->
  hasFlash = false
  try
    flash = new ActiveXObject('ShockwaveFlash.ShockwaveFlash')
    if flash
      hasFlash = true
  catch e
    if navigator.mimeTypes and navigator.mimeTypes['application/x-shockwave-flash'] != undefined and navigator.mimeTypes['application/x-shockwave-flash'].enabledPlugin
      hasFlash = true

  if hasFlash is false and Evercam.Camera.status == "online" and $('#select-stream-type').val() is "video"
    $('.vjs-error-display').hide()
    $('.flash-error-message').show()

logCameraViewed = ->
  is_logged_intercom = true
  data = {}
  data.view = true

  onError = (jqXHR, status, error) ->
    if Evercam.User.username
      message = jqXHR.responseJSON.message

  onSuccess = (data, status, jqXHR) ->
    true

  settings =
    data: data
    dataType: 'json'
    success: onSuccess
    error: onError
    type: 'POST'
    contentType: 'application/x-www-form-urlencoded'
    url: "/log_intercom"
  sendAJAXRequest(settings)

initSelectStream = ->
  camera_select = $('#select-stream-type').select2
    minimumResultsForSearch: Infinity
    templateSelection: format,
    templateResult: format
    escapeMarkup: (m) ->
      m

format = (state) ->
  is_offline = ""
  if !state.id
    return state.text
  if state.id == '0'
    return state.text
  return $("<span>#{state.text}</span>")

inactiveWindow = ->
  document.onmousemove = ->
    if $(".nav-tabs li.active a").attr("data-target") is "#live"
      clearTimeout warningTimer
      StartTimers()

  $("#live-view-placeholder").on "click", ".click_to_start_stream", ->
    ResetTimers()

StartTimers = ->
  warningTimer = setTimeout((->
    IdleWarning()
    ), timoutWarning)

ResetTimers = ->
  if $(".nav-tabs li.active a").attr("data-target") is "#live"
    clearTimeout warningTimer
    StartTimers()
    stream_type = $("#select-stream-type").val()
    switch stream_type
      when 'jpeg', undefined
        playJpegStream()
        $("#fullscreen .inactive-jpeg-error-display").addClass("hide")
        if $("#live-snapshot-magnifier").hasClass 'enabled'
          hideIcons()
        else
          showIcons()
        if $("#offline-snapshot-magnifier").hasClass 'enabled'
          hideOfflineIcons()
        else
          showOfflineIcons()
      when 'video'
        playInActiveVideoStream()
        turnOffZoomEffect()

IdleWarning = ->
  if $(".nav-tabs li.active a").attr("data-target") is "#live"
    showInactiveMessage()

showInactiveMessage = ->
  snap_height = $("#camera-video-stream").height()
  snap_width = $("#camera-video-stream").width()
  jpeg_snap_height = $("#fullscreen").height()
  jpeg_snap_width = $("#fullscreen").width()
  stream_type = $("#select-stream-type").val()
  html = "Stream is paused, User is inactive for more than 2 minutes. <a href='#' class='click_to_start_stream'>Click To Play</a>"

  switch stream_type
    when 'jpeg', undefined
      stopJpegStream()
      turnOffZoomEffect()
      $(".play-options .hide-icon").hide()
      $(".play-options .ui-snapshot-magnifier").hide()
      $("#fullscreen .inactive-jpeg-error-display").removeClass("hide")
      $("#fullscreen .inactive-jpeg-error-display div").html("<span style='top: #{(jpeg_snap_height / 2) - 30}px; left: #{(jpeg_snap_width / 2) - 250}px;'
        class='spn-message'>#{html}</span>")
    when 'video'
      vjs_player.pause()
      $("#camera-video-player .vjs-error-display").addClass("vjs-hidden")
      $("#camera-video-stream .inactive-error-display").removeClass("hide")
      $(".vjs-control-bar .vjs-play-control").removeClass("vjs-playing").addClass("vjs-paused")
      $("#camera-video-stream .inactive-error-display div").html("<span style='top: #{(snap_height / 2) - 30}px; left: #{(snap_width / 2) - 250}px;'
        class='spn-message'>#{html}</span>")

playInActiveVideoStream = ->
  vjs_player.play()
  $("#camera-video-stream .inactive-error-display").addClass("hide")
  $(".vjs-control-bar .vjs-play-control").addClass("vjs-playing").removeClass("vjs-paused")

initZoom = ->
  $("#camera-video-stream").on "mousewheel", (e) ->
    if e.deltaY < 0
      zoom_level = zoom_level - 0.1
    else
      zoom_level = zoom_level + 0.1
    console.log(zoom_level, e.deltaY)
    if zoom_level > -1 && zoom_level <= 1
      window.vjs_player.zoomrotate({zoom: zoom_level, rotate: 0});

onClickLiveSnapshotMagnifier = ->
  $('#live-snapshot-magnifier').on 'click', ->
    $('.zoomContainer').remove()
    if $('#live-snapshot-magnifier.enabled').length == 0
      initElevateZoom()
      $(this).toggleClass 'enabled'
    else
      $(this).toggleClass 'enabled'
      $('.zoomContainer').hide()
      showIcons()
  
  $('#offline-snapshot-magnifier').on 'click', ->
    $('.zoomContainer').remove()
    if $('#offline-snapshot-magnifier.enabled').length == 0
      initOfflineElevateZoom()
      $(this).toggleClass 'enabled'
    else
      $(this).toggleClass 'enabled'
      $('.zoomContainer').hide()
      showOfflineIcons()

turnOffZoomEffect = ->
  $('#live-snapshot-magnifier').removeClass 'enabled'
  $('.zoomContainer').hide()
  showIcons()

turnOfflineZoomEffect = ->
  $('#offline-snapshot-magnifier').removeClass 'enabled'
  $('.zoomContainer').hide()
  showIcons()

hideIcons = ->
  $(".play-options .hide-icon").hide()
  $(".play-options .ui-snapshot-magnifier").show()


hideOfflineIcons = ->
  $(".offline-play-icons .hide-icon").hide()
  $(".offline-play-icons .ui-snapshot-magnifier").show()

showIcons = ->
  $(".play-options .hide-icon").show()
  $(".play-options .ui-snapshot-magnifier").show()

showOfflineIcons = ->
  $(".offline-play-icons  .hide-icon").show()
  $(".offline-play-icons  .ui-snapshot-magnifier").show()

centerTabClick = ->
  $(document).click (e) ->
    if $(e.target).is('#ul-nav-tab li a,#ul-nav-tab li a span')
      turnOffZoomEffect()
      turnOfflineZoomEffect()

centerDiv = ->
  messagebox_width = $("#offline_message").width()
  screen_width = $(".offline-camera-placeholder").width()
  offset = (screen_width - messagebox_width) / 2
  $("#offline_message").css "right", offset

hoverMouseOnFullscreen = ->
  $('#live-view-placeholder #fullscreen').hover (->
    $("#jpg-portion .play-options").css('opacity', '1')
  ), ->
    if $("#live-snapshot-magnifier").hasClass 'enabled'
      $("#jpg-portion .play-options").css('opacity', '1')
    else
      $("#jpg-portion .play-options").css('opacity', '0')
  
  $('#live .offline-camera-placeholder').hover (->
    $(".offline-image .offline-play-icons").css('opacity', '1')
  ), ->
    if $("#offline-snapshot-magnifier").hasClass 'enabled'
      $(".offline-image .offline-play-icons").css('opacity', '1')
    else
      $(".offline-image .offline-play-icons").css('opacity', '0')

initElevateZoom = ->
  hideIcons()
  $('#live-player-image').elevateZoom
    zoomType: 'lens',
    responsive: 'true',
    scrollZoom: true,
    lensShape: 'round',
    lensSize: 230

initOfflineElevateZoom = ->
  hideOfflineIcons()
  $('.offline-image .camera-thumbnail').elevateZoom
    zoomType: 'lens',
    responsive: 'true',
    scrollZoom: true,
    lensShape: 'round',
    lensSize: 230

removeMagnifierOnEsc = ->
  $(document).on 'keyup', (evt) ->
    if evt.keyCode = 27
      turnOffZoomEffect()
      turnOfflineZoomEffect()

check_dunkettle_camera = ->
  cameras = ["dunke-wqnzu", "dunke-ibcwt", "dunke-bnivp", "dunke-gqiwe", "camer-runah", "camer-sraxw", "camer-xeojc"]
  if cameras.indexOf("#{Evercam.Camera.id}") is -1
    return false

  token = Base64.encode("#{Evercam.Camera.id}|#{Evercam.Camera.name}")
  onSuccess = (response) ->
    $("#select-stream-type").val("video").trigger("change")
    true

  onError = (jqXHR, status, error) ->
    false

  settings =
    cache: false
    data: {}
    dataType: 'text'
    error: onError
    success: onSuccess
    type: 'GET'
    url: "https://media.evercam.io/hls/#{token}/index.m3u8?nvr=true"

  $.ajax(settings)

window.initializeLiveTab = ->
  window.video_player_html = $('#camera-video-stream').html()
  window.vjs_player = {}
  image_placeholder = document.getElementById("live-player-image")
  camera_host = $('.hidden-input').val()
  controlButtonEvents()
  fullscreenImage()
  openPopout()
  handleResize()
  handleChangeStream()
  handleTabOpen()
  handleSaveSnapshot()
  handlePtzCommands()
  changePtzPresets()
  handleModelEvents()
  checkPTZExist()
  # flashDetection()
  onEditPtz()
  onDeletePtz()
  ptzCreation()
  NProgress.done()
  initSelectStream()
  StartTimers()
  onClickLiveSnapshotMagnifier()
  inactiveWindow()
  removeMagnifierOnEsc()
  centerTabClick()
  hoverMouseOnFullscreen()
  check_dunkettle_camera()
  hidegif()

->
  calculateHeight()
