ip = null
port = null
rtsp_port = null
xhrRequestPortCheck = null
flag = true

initNotification = ->
  Notification.init(".bb-alert");
  if notifyMessage
    Notification.show notifyMessage

loadVendorModels = (vendor_id, stroke_key_up) ->
  NProgress.start()
  $("#camera-model option").remove()
  $("#camera-model").append('<option value="">Loading...</option>');
  if vendor_id is ""
    $("#camera-model option").remove()
    $("#camera-model").append('<option value="">Select Camera Model</option>');
    $("#snapshot").val("")
    $("#snapshot-readonly").val("")
    $("#rtsp").val("")
    $("#rtsp-readonly").val("")
    $("#snapshot").removeClass("hide")
    $("#snapshot-readonly").addClass("hide")
    $("#rtsp").removeClass("hide")
    $("#rtsp-readonly").addClass("hide")
    NProgress.done()
    return

  data = {}
  data.vendor_id = vendor_id
  data.limit = 400
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (jqXHR, status, error) ->
    NProgress.done()
    false

  onSuccess = (result, status, jqXHR) ->
    $("#camera-model option").remove()
    if result.models.length == 0
      $("#camera-model").append('<option value="">No Model Found</option>');
      return

    models = sortByKey(result.models, "name")
    for model in models
      selected = if model.id is $("#last-selected-model").val() then 'selected="selected"' else ''
      jpg_url = if model.defaults.snapshots then model.defaults.snapshots.jpg else ''
      if jpg_url is "unknown"
        jpg_url = ""
      if selected is '' && model.name.toLowerCase().indexOf('default') isnt -1
        $("#camera-model").prepend("
          <option jpg-val='#{jpg_url}'
          rtsp-val='#{model.h264_url}'
          value='#{model.id}' selected='selected'>#{model.name}
          </option>"
        )
      else if model.name.toLowerCase().indexOf('other') isnt -1
        $("#camera-model").prepend("
          <option jpg-val='#{jpg_url}'
          rtsp-val='#{model.h264_url}'
          value='#{model.id}' selected='selected'>#{model.name} - Custom URL
          </option>"
        )
      else
        $("#camera-model").append("
          <option jpg-val='#{jpg_url}'
          rtsp-val='#{model.h264_url}'
          value='#{model.id}' #{selected}>#{model.name}
          </option>"
        )
    if $("#last-selected-model").val() is ''
      if model.id isnt "other_default"
        $("#snapshot").val(cleanAndSetJpegUrl($("#camera-model").find(":selected").attr("jpg-val")))
        $("#snapshot-readonly").val(cleanAndSetJpegUrl($("#camera-model").find(":selected").attr("jpg-val")))
        $("#snapshot").addClass("hide")
        $("#snapshot-readonly").removeClass("hide")
        $("#rtsp").addClass("hide")
        $("#rtsp-readonly").removeClass("hide")
      else
        $("#snapshot").val("") if !stroke_key_up
        $("#snapshot-readonly").val("")
        $("#rtsp").val("") if !stroke_key_up
        $("#rtsp-readonly").val("")
        $("#snapshot").removeClass("hide")
        $("#snapshot-readonly").addClass("hide")
        $("#rtsp").removeClass("hide")
        $("#rtsp-readonly").addClass("hide")
    $("#last-selected-model").val('')
    NProgress.done()

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/json; charset=utf-8"
    type: 'GET'
    url: "#{Evercam.API_URL}models"

  sendAJAXRequest(settings)

sortByKey = (array, key) ->
  array.sort (a, b) ->
    x = a[key]
    y = b[key]
    (if (x < y) then -1 else ((if (x > y) then 1 else 0)))

loadVendors = ->
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (jqXHR, status, error) ->
    false

  onSuccess = (result, status, jqXHR) ->
    vendors = sortByKey(result.vendors, "name")

    for vendor in vendors
      selected = ''
      if vendor.id is $("#last-selected-vendor").val()
        selected = 'selected="selected"'
        loadVendorModels(vendor.id)
        $("#last-selected-vendor").val('')
      if vendor.id is "other"
        $("#camera-vendor").prepend("<option value='#{vendor.id}' #{selected}>#{vendor.name} - Custom URL</option>")
      else
        $("#camera-vendor").append("<option value='#{vendor.id}' #{selected}>#{vendor.name}</option>")

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/json; charset=utf-8"
    type: 'GET'
    url: "#{Evercam.API_URL}vendors"

  sendAJAXRequest(settings)

validate_hostname = (str) ->
  ValidIpAddressRegex = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
  ValidHostnameRegex = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/
  ValidIpAddressRegex.test(str) or ValidHostnameRegex.test(str)

handleVendorModelEvents = ->
  $("#camera-vendor").on "change", ->
    loadVendorModels($(this).val())

  $(".camera-model").on "change", ->
    $("#snapshot").val(cleanAndSetJpegUrl($(this).find(":selected").attr("jpg-val")))
    $("#snapshot-readonly").val(cleanAndSetJpegUrl($(this).find(":selected").attr("jpg-val")))
    $("#snapshot").addClass("hide")
    $("#snapshot-readonly").removeClass("hide")

cleanAndSetJpegUrl = (jpeg_url) ->
  if jpeg_url.indexOf('/') == 0
    jpeg_url = jpeg_url.substr(1)
  return jpeg_url

onLoadPage = ->
  if $("#last-selected-model").val() isnt ''
    if $("#last-selected-model").val() is "other_default"
      $("#snapshot").removeClass("hide")
      $("#snapshot-readonly").addClass("hide")
      $("#rtsp").removeClass("hide")
      $("#rtsp-readonly").addClass("hide")
    else
      $("#snapshot").addClass("hide")
      $("#snapshot-readonly").removeClass("hide")
      $("#rtsp").addClass("hide")
      $("#rtsp-readonly").removeClass("hide")
    $("#snapshot").val(cleanAndSetJpegUrl($("#snapshot").val()))
    $("#snapshot-readonly").val(cleanAndSetJpegUrl($("#snapshot-readonly").val()))
  $(".settings").hide()
  appendCopyFromDropdown()
  #toggle the componenet with class msg_body
  $(".additional").click ->
    slideToggleList()
    $(this).toggleClass('active')
    $(this).toggleClass('sidebar-checked')
    $(".settings").slideToggle 500

  $("#hide").click ->
    $("p").fadeOut()

  $("#reveal").click ->
    $(".this").fadeIn()

  $("#unreveal").click ->
    $(".this").fadeOut()

  $("#clone-camera-list .cameras-dropdown-toggle").click ->
    slideToggleCameraList()

  if window.location.href.indexOf('clone') > -1
    $('#copy-from .chk-span').addClass 'checked active'
    $('.copy-from-camera').show()
  else
    $('#copy-from .chk-span').removeClass 'checked active'
    $('.copy-from-camera').hide()

  $('#copy-from-text').on 'click', (event) ->
    toggleCopyFromDropdown()

  $('#copy-from input[type="checkbox"]').on 'click', (event) ->
    toggleCopyFromDropdown()

toggleCopyFromDropdown = ->
  $('#copy-from .sidebar-chk-span').toggleClass('active')
  $('#copy-from .sidebar-chk-span').toggleClass('sidebar-checked')
  $(".copy-from-camera").slideToggle 500
  appendCopyFromDropdown()

slideToggleCameraList = ->
  if $('#clone-camera-list').hasClass 'open'
    $('#clone-camera-list .fa-chevron-down').show()
    $('#clone-camera-list .fa-chevron-up').hide()
  else
    $('#clone-camera-list .fa-chevron-down').hide()
    $('#clone-camera-list .fa-chevron-up').show()

slideToggleList = ->
  if ($('.settings')).css('display') == 'none'
    $('.additional .fa-chevron-up').show()
    $('.additional .fa-chevron-down').hide()
  else
    $('.additional .fa-chevron-up').hide()
    $('.additional .fa-chevron-down').show()

appendCopyFromDropdown = ->
  if $(window).width() < 768
    $('#camera-friendly-name').addClass 'camera-friendly-name'
    $('#camera-friendly-name').removeClass 'margin-top-20'
  else
    $('#camera-friendly-name').removeClass 'camera-friendly-name'
    $('#camera-friendly-name').addClass 'margin-top-20'

onAddCamera = ->
  $("#add-button").on 'click', ->
    if $("#camera-name").val().trim() is ""
      Notification.error "Please enter required fields: Camera Name."
      return false
    if $("#camera-name").val().trim() is "" && $("#camera-id").val().trim() is "" && $("#camera-url").val().trim() is "" && $("#snapshot").val().trim() is ""
      Notification.error "Please enter required camera fields: Camera Name, Camera-Id, Camera URL and Snapshot Url."
      return false
    if $("#camera-url").val().trim() is ""
      Notification.error "Please enter required fields: Camera URL."
      return false
    if $("#snapshot").val().trim() is ""
      Notification.error "Please enter required fields: Snapshot Url."
      return false
    regularExpression = /^(^127\.0\.0\.1)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)$/
    if regularExpression.test($("#camera-url").val())
      Notification.error "Its your local IP, please provide camera public IP."
      $("#camera-url").css("border-color", "red")
      return false

onCustomizedUrl = ->
  $("#snapshot").on "keyup", ->
    if $("#camera-vendor").val() isnt "other"
      $("#camera-vendor").val("other")
      loadVendorModels($("#camera-vendor").val(), true)

port_check = (external_port,type) ->
  ex_ip = $('#camera-url').val()
  ex_port = external_port
  if !ex_port
    $(".#{type}port-status").empty()
    return
  if !ex_ip
    $(".#{type}port-status").empty()
    return
  $(".#{type}port-status").empty()
  $(".#{type}refresh-gif").show()
  data = {}

  onError = (jqXHR, textStatus, ex) ->
    $(".#{type}refresh-gif").hide()
    $(".#{type}port-status").removeClass('green')
    $(".#{type}port-status").addClass('red')
    $(".#{type}port-status").html('
      <i class="fa fa-times icon-font icon-position"></i>
        <span>Port is closed</span>'
    )

  onSuccess = (result, status, jqXHR) ->
    if result.open is true
      $(".#{type}refresh-gif").hide()
      $(".#{type}port-status").removeClass('red')
      $(".#{type}port-status").addClass('green')
      $(".#{type}port-status").html('
        <i class="fa fa-check icon-font icon-position"></i>
        <span>Port is open</span>'
      )
    else
      if flag is true
        port_check(ex_port, '')
        flag = false
      else
        $(".#{type}refresh-gif").hide()
        $(".#{type}port-status").removeClass('green')
        $(".#{type}port-status").addClass('red')
        $(".#{type}port-status").html(
          '<i class="fa fa-times icon-font icon-position"></i>
          <span>Port is closed</span>'
        )

  settings =
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/x-www-form-urlencoded"
    type: 'GET'
    url: "#{Evercam.MEDIA_API_URL}cameras/port-check?address=#{ex_ip}&port=#{ex_port}"

  xhrRequestPortCheck = jQuery.ajax(settings)

check_port = ->
  regexp = /^[0-9]{2,5}$/
  $('#port').on 'keyup', (e) ->
    flag = true
    @value = @value.replace(/[^\d]/, '')
    if xhrRequestPortCheck
      xhrRequestPortCheck.abort()
    port = $('#port').val()
    if port and !port.match regexp
      $('.external-port').css('borderColor',"#b94a48")
      $(".port-status").empty()
    else
      $('.external-port').css('borderColor',"#aaaaaa")
      port_check(port,'')

  $('#camera-url').on 'keyup', ->
    if xhrRequestPortCheck
      xhrRequestPortCheck.abort()
    port_check(port,'') unless !port.match regexp

cursor_visible = ->
  $('.external-port').on 'click', ->
    $('#port').focus()
  $('#change').on 'click', ->
    $('#ext-rtsp-port').focus()

onFocusOut = ->
  $('#camera-name').focusout ->
    camera_value = $("#camera-name").val()
    if camera_value
      $('#camera-name').attr('data-validation-error-msg', 'Containing letters, spaces and hyphens.')
    else
      $('#camera-name').attr('data-validation-error-msg', ' ')

  $('#camera-url').focusout ->
    camera_value = $("#camera-url").val()
    if camera_value
      $('#camera-url').attr('data-validation-error-msg', 'This should be in the form of <strong>149.5.43.10</strong> or <strong>portlarochelle.com</strong>.')
    else
      $('#camera-url').attr('data-validation-error-msg', ' ')

  $('#snapshot').focusout ->
    camera_value = $("#snapshot").val()
    if camera_value
      $('#snapshot').attr('data-validation-error-msg', 'The input value can only contain alphanumeric characters  and -_/.&?=')
    else
      $('#snapshot').attr('data-validation-error-msg', ' ')

window.initializeAddCamera = ->
  ip = $('#camera-url').val()
  port = $('#port').val()
  Metronic.init()
  Layout.init()
  QuickSidebar.init()
  onLoadPage()
  $.validate(validateOnEvent: true)
  handleVendorModelEvents()
  initNotification()
  loadVendors()
  onAddCamera()
  onFocusOut()
  onCustomizedUrl()
  cursor_visible()
  check_port()
  port_check(port,'')
  NProgress.done()
  $(window).resize ->
    appendCopyFromDropdown()
