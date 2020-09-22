window.showOfflineButton = ->
  if $.cookie("hide-offline-cameras")
    $("#offline-btn").prop("checked", true)
    $('.sub-menu, .dropdown-menu.scroll-menu, #camera-index').addClass('cam-active')
  $('#offline-btn').on 'click', (event) ->
    hide_cameras = $(this).prop("checked")
    if hide_cameras
      $.cookie("hide-offline-cameras", $(this).prop("checked"), { expires: 365, path: "/" })
      $('.sub-menu, .dropdown-menu.scroll-menu, #camera-index').toggleClass('cam-active')
    else
      $.removeCookie("hide-offline-cameras", { path: "/" })
      $('.sub-menu, .dropdown-menu.scroll-menu, #camera-index').toggleClass('cam-active')

nProgressCall = ->
  $('#hello > a').on 'click', ->
    NProgress.start()
  $('.cameralist-height > ul > li > a').on 'click', ->
    NProgress.start()
  $('.nprogCall').on 'click', ->
    NProgress.start()

slideToggleList = ->
  if $('.cameralist-height:visible').length == 0
    $('#hello .fa-caret-up').hide()
    $('#hello .fa-caret-down').show()
  else
    $('#hello .fa-caret-up').show()
    $('#hello .fa-caret-down').hide()

slideToggle = ->
  $('.camera-fadrop').click ->
    $('.cameralist-height').slideToggle 'slow', ->
      slideToggleList()

removeDropdown = ->
  $("#Intercom").on "click", ->
    $('#live_support').removeClass('open')

initSocket = ->
  Evercam.socket = new (Phoenix.Socket)(Evercam.websockets_url, {params: {api_id: Evercam.User.api_id, api_key: Evercam.User.api_key, ip: Evercam.request.ip, source: "dashboard"}})
  Evercam.socket.connect()
  if Evercam.User.username
    Evercam.user_channel = Evercam.socket.channel("users:#{Evercam.User.username}")
    Evercam.user_channel.join()
    Evercam.user_channel.on 'camera-status-changed', (payload) ->
      updateCameraStatus(payload.camera_id, payload.status)

    Evercam.user_channel.on 'camera-share', (payload) ->
      update_cameras(payload)

update_cameras = (camera) ->
  offline_class = ""
  if camera.status is false
    offline_class = "sidebar-offline"

  cr_html = ""

  if camera.cr_storage_duration
    if camera.cr_storage_duration is -1
      recording_duration = '∞'
    else
      recording_duration = camera.cr_storage_duration

    if camera.cr_status isnt 'off' && camera.cr_status isnt 'paused'
      cr_html = "<div id='green-dot-div' class='green-dot-div' title='#{recording_duration}'>
        <i class='fas fa-circle green-dot'></i>
      </div>"

  list_element =
    "<li class='sub-menu-item camera-#{camera.camera_id} #{offline_class}'>
      #{cr_html}
      <a data-camera-id='#{camera.camera_id}' href='/v2/cameras/#{camera.camera_id}'>#{camera.name}</a>
      <i class='red header-sidebar fa fa-unlink'></i>
    </li>"

  $.each $(".sidebar-cameras-list li"), (i, list) ->
    if $(list).find("a").text().toLowerCase() > camera.name.toLowerCase()
      $(".sidebar-cameras-list li:eq(#{i})").before(list)
      return false

updateCameraStatus = (camera_id, status) ->
  if status == "online"
    $(".sidebar-cameras-list .camera-#{camera_id}").removeClass("sidebar-offline")
    $(".page-header.camera-#{camera_id} .camera-switch").removeClass("camera-offline")
    $(".page-content .camera-index.camera-#{camera_id}").removeClass("camera-offline")
    $(".page-content.camera-#{camera_id} #camera-details-panel .status").parent().html('<div class="status green">Online</div>')
  else
    $(".sidebar-cameras-list .camera-#{camera_id}").addClass("sidebar-offline")
    $(".page-header.camera-#{camera_id} .camera-switch").addClass("camera-offline")
    $(".page-content .camera-index.camera-#{camera_id}").addClass("camera-offline")
    $(".page-content.camera-#{camera_id} #camera-details-panel .status").parent().html('<div class="status red">Offline</div>')

handleCameraListHeight = ->
  menu_count = $(".page-sidebar-menu > li").length
  max_height = menu_count * 34
  $('.cameralist-height').css 'max-height', $('.page-sidebar-menu').height() - max_height

delay = do ->
  timer = 0
  (callback, ms) ->
    clearTimeout timer
    timer = setTimeout(callback, ms)
    return

sidebarScrollPosition = ->
  $(document).ready ->
    prev_scroll_position = $.cookie('prev_scroll_position')
    $('.cameralist-height').scrollTop prev_scroll_position

  $('.page-sidebar-menu .cameralist-height').scroll (event) ->
    scroll_positon = $('.cameralist-height').scrollTop()
    $.cookie 'prev_scroll_position', scroll_positon,
      expires: 7
      path: '/'

highlightActiveCamera = ->
  hrefs = $('.cameralist-height a')
  hrefs.each ->
    if $(this).data('camera-id') == Evercam.Camera.id
      $(this).parent().addClass('active-color')
    else
      $(this).parent().removeClass('active-color')

$ ->
  initSocket()
  showOfflineButton()
  $('[data-toggle="tooltip"]').tooltip()

$(window).ready ->
  nProgressCall()
  slideToggle()
  removeDropdown()
  handleCameraListHeight()
  sidebarScrollPosition()
  highlightActiveCamera()
  slideToggleList()
  $(window).resize ->
    delay (->
      handleCameraListHeight()
      return
    ), 500
    return
