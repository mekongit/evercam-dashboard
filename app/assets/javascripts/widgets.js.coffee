updateCode = () ->
  camera = $('#widget-camera').val()
  refresh = $('#widget-refresh-rate').val()
  width = $('#widget-camera-width').val()
  option_width = $('#width-option').val()
  pre_auth = $('#widget-authenticate').val()

  url = window.location.origin
  camera_name = $('#widget-camera option:selected').text()
  offline = camera_name.indexOf('(Offline)') != -1
  priv = if camera_name.indexOf('(Private)') == -1 then 'false' else 'true'
  api_credentials = if pre_auth == 'true' then "&api_id=#{window.api_credentials.api_id}&api_key=#{window.api_credentials.api_key}" else ''

  baseText = "<div id='ec-container-#{camera}' style='width:
    #{width}#{option_width};position:relative;padding-top:56.2%;'></div>
    <script src='#{url}/live.view.widget.js?refresh=#{refresh}&camera=#{camera}&private=#{priv}#{api_credentials}' async></script>"
  $('#code').val(baseText)
  document.removeEventListener("visibilitychange", window.ec_vis_handler, false);
  clearTimeout(window.ec_watcher) if window.ec_watcher?
  $('.preview').html(baseText) unless offline

updatePartialValues = ->
  camera = $('#widget-camera').val()
  refresh = $('#widget-refresh-rate').val()
  width = $('#widget-camera-width').val()
  option_width = $('#width-option').val()
  pre_auth = $('#widget-authenticate').val()

  url = window.location.origin
  camera_name = $('#widget-camera option:selected').text()
  offline = camera_name.indexOf('(Offline)') != -1
  priv = if camera_name.indexOf('(Private)') == -1 then 'false' else 'true'
  api_credentials = if pre_auth == 'true' then "&api_id=#{window.api_credentials.api_id}&api_key=#{window.api_credentials.api_key}" else ''

  baseText = "<div id='ec-container-#{camera}' style='width:
    #{width}#{option_width};position:relative;padding-top:56.2%;'><div>
    <script src='#{url}/live.view.widget.js?refresh=#{refresh}&camera=#{camera}&private=#{priv}#{api_credentials}' async></script>"
  $('#code').val(baseText)
  $("#ec-container-#{camera}").width("#{width}#{option_width}")

initCameraSelect = ->
  camera_select = $('#widget-camera').select2
    templateSelection: format,
    templateResult: format
    escapeMarkup: (m) ->
      m
  $('.widget-input .select2-container--default').width '100%'

format = (state) ->
  is_offline = ""
  if !state.id
    return state.text
  if state.id == '0'
    return state.text
  return $("<span><img style='height:30px;margin-bottom:1px;margin-top:1px;width:35px;' src='#{Evercam.MEDIA_API_URL}cameras/#{state.id}/thumbnail?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}' class='img-flag' />&nbsp;#{state.text}</span>")

handle_tab_open = ->
  $('.nav-tab-live').on 'shown.bs.tab', ->
    updateCode()

  $('.nav-tab-live').on 'hide.bs.tab', ->
    $('.preview').html("")

$ ->
  initCameraSelect()
  handle_tab_open()
  $('#widget-camera-width').change(updatePartialValues)
  $('#width-option').change(updatePartialValues)
  $('#widget-refresh-rate').change(updateCode)
  $('#widget-camera').change(updateCode)
  $('#widget-authenticate').change(updatePartialValues)
  $('#code').on 'click', ->
    @select()
    return
