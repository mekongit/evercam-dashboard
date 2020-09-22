imagesCompare = undefined
clearTimeOut = null
xhrChangeMonth = null
removeCalendarHighlightflag = false

initCompare = ->
  imagesCompareElement = $('.js-img-compare').imagesCompare()
  imagesCompare = imagesCompareElement.data('imagesCompare')
  events = imagesCompare.events()

  imagesCompare.on events.changed, (event) ->
    true

getFirstLastImages = (image_id, query_string, reload, setDate) ->
  data =
    api_id: Evercam.User.api_id
    api_key: Evercam.User.api_key

  if query_string is "/latest"
    data.is_save = true

  onError = (jqXHR, status, error) ->
    false

  onSuccess = (response, status, jqXHR) ->
    snapshot = response
    if query_string.indexOf("nearest") > 0 && response.snapshots.length > 0
      snapshot = response.snapshots[0]
    if snapshot.data isnt undefined
      $("##{image_id}").attr("src", snapshot.data)
      $("##{image_id}").attr("timestamp", snapshot.created_at)
      if setDate is true && query_string.indexOf("nearest") < 0
        d = moment(snapshot.created_at)
        string_date = d.format("M/D/YYYY")
        camera_created_date = moment(Evercam.Camera.created_at)
        camera_created_year = camera_created_date.format('YYYY')
        camera_created_at = camera_created_date.format("YYYY/M/D")
        $('#calendar-before').datetimepicker({value: d._d, minDate: camera_created_at, yearStart: camera_created_year})
        $('#calendar-after').datetimepicker({minDate: camera_created_at, yearStart: camera_created_year})
      if setDate is false && query_string.indexOf("nearest") < 0
        date_after = moment(snapshot.created_at)
        after_year = date_after.format('YYYY')
        string_after_date = date_after.format("YYYY/M/D")
        $('#calendar-after').datetimepicker({value: date_after, maxDate: string_after_date, yearEnd: after_year})
      initCompare() if reload
    else
      Notification.error("No image found")

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    type: 'GET'
    url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/recordings/snapshots#{query_string}"
  sendAJAXRequest(settings)

handleTabOpen = ->
  $('.nav-tab-compare').on 'shown.bs.tab', ->
    initCompare()
    updateURL()

updateURL = ->
  url = "#{Evercam.request.rootpath}/compare"
  query_string = ""
  if $("#txtbefore").val() isnt ""
    query_string = "?before=#{toISOString(moment.tz($("#txtbefore").val(), "MM/DD/YYYY hh:mm", Evercam.Camera.timezone))}"
  if $("#txtafter").val() isnt ""
    after_date = toISOString(moment.tz($("#txtafter").val(), "MM/DD/YYYY hh:mm", Evercam.Camera.timezone))
    if query_string is ""
      query_string = "?after=#{after_date}"
    else
      query_string = "#{query_string}&after=#{after_date}"

  url = "#{url}#{query_string}"
  if history.replaceState
    window.history.replaceState({}, '', url)

getQueryStringByName = (name) ->
  name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]')
  regex = new RegExp('[\\?&]' + name + '=([^&#]*)')
  results = regex.exec(location.search)
  if results == null
    null
  else
    decodeURIComponent(results[1].replace(/\+/g, ' '))

HighlightDaysInMonth = (query_string, year, month) ->
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (response, status, error) ->
    false

  onSuccess = (response, status, jqXHR) ->
    if removeCalendarHighlightflag is true
      removeCurrentDateHighlight(query_string)
      removeCurrentHourHighlight(query_string)
    hideBeforeAfterLoadingAnimation(query_string)
    for day in response.days
      HighlightBeforeAfterDay(query_string, year, month, day)

  settings =
    cache: true
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/json charset=utf-8"
    type: 'GET'
    url: "#{Evercam.MEDIA_API_URL}cameras/#{Evercam.Camera.id}/recordings/snapshots/#{year}/#{month}/days"

  xhrChangeMonth = sendAJAXRequest(settings)

HighlightBeforeAfterDay = (query_string, before_year, before_month, before_day) ->
  beforeDays = $("##{query_string} .xdsoft_datepicker table td[class*='xdsoft_date'] div")
  beforeDays.each ->
    beforeDay = $(this)
    if !beforeDay.parent().hasClass('xdsoft_other_month')
      iDay = parseInt(beforeDay.text())
      if before_day == iDay
        beforeDay.parent().addClass 'active-class-css'

HighlightSnapshotHour = (query_string, year, month, date) ->
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (jqXHR, status, error) ->
    false

  onSuccess = (response, status, jqXHR) ->
    if removeCalendarHighlightflag is true
      removeCurrentHourHighlight(query_string)
    hideBeforeAfterLoadingAnimation(query_string)
    for hour in response.hours
      HighlightBeforeAfterHour(query_string, year, month, date, hour)

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/json charset=utf-8"
    type: 'GET'
    timeout: 15000
    url: "#{Evercam.MEDIA_API_URL}cameras/#{Evercam.Camera.id}/recordings/snapshots/#{year}/#{(month)}/#{date}/hours"

  xhrChangeMonth = sendAJAXRequest(settings)

HighlightBeforeAfterHour = (query_string, before_year, before_month, before_day, before_hour) ->
  beforeHours = $("##{query_string} .xdsoft_timepicker [class*='xdsoft_time']")
  beforeHours.each ->
    beforeHour = $(this)
    iHour = parseInt(beforeHour.text())
    if before_hour == iHour
      beforeHour.addClass 'active-class-css'

removeCurrentHourHighlight = (query_string) ->
  beforeHours = $("##{query_string} .xdsoft_timepicker div[class*='xdsoft_time']")
  beforeHours.removeClass 'xdsoft_current'

removeCurrentDateHighlight = (query_string) ->
  beforeDays = $("##{query_string} .xdsoft_calendar table td[class*='xdsoft_date']")
  beforeDays.removeClass 'xdsoft_current'

showBeforeAfterLoadingAnimation = (query_string) ->
  $("##{query_string} .xdsoft_datepicker").addClass 'opacitypoint5'
  $("##{query_string} .xdsoft_timepicker").addClass 'opacitypoint5'

hideBeforeAfterLoadingAnimation = (query_string) ->
  $("##{query_string} .xdsoft_datepicker").removeClass 'opacitypoint5'
  $("##{query_string} .xdsoft_timepicker").removeClass 'opacitypoint5'

setCompareEmbedCodeTitle = ->
  $("#div-embed-code").on "click", (e)->
    after_image_time = $("#compare_after").attr("timestamp")
    before_image_time = $("#compare_before").attr("timestamp")
    if after_image_time && before_image_time isnt undefined
      day_before = moment(before_image_time).format("Do")
      day_after = moment(after_image_time).format("Do")
      month_before = moment(before_image_time).format("MMM")
      month_after = moment(after_image_time).format("MMM")
      $("#export-compare-title").val("#{day_before} #{month_before} to #{day_after} #{month_after}")
      e.stopPropagation()
      $('#export-compare-modal').modal 'show'
    else
      e.stopPropagation()
      $(".bb-alert").css "width", "410px"
      Notification.warning("Unable to export compare, before/after image is not available.")

export_compare = ->
  $("#export_compare_button").on "click", ->
    $("#spn-success-export").removeClass("alert-info").addClass("alert-danger")
    name = $("#export-compare-title").val()
    if name is ""
      $("#spn-success-export").text("Please enter export name.").removeClass("hide")
      return false

    button = $(this)
    button.prop("disabled", true)
    $("#row-animation").removeClass("hide")
    namePart = name.replace(/[^A-Z0-9]/ig, "")
    exid = "#{namePart.slice(0, 5)}-#{makeRandString()}".toLowerCase()
    after = "#{convert_timestamp_to_path($("#compare_after").attr("timestamp"))}"
    before = "#{convert_timestamp_to_path($("#compare_before").attr("timestamp"))}"
    embed_code = "<div id='evercam-compare'></div><script src='#{window.location.origin}/assets/evercam_compare.js' class='#{Evercam.Camera.id} #{before} #{after} #{exid} autoplay'></script>"
    $("#txtEmbedCode").val(embed_code)

    data =
      api_id: Evercam.User.api_id
      api_key: Evercam.User.api_key
      name: name
      before_date: $("#compare_before").attr("timestamp")
      # before_image: $("#compare_before").attr("src")
      after_date: $("#compare_after").attr("timestamp")
      # after_image: $("#compare_after").attr("src")
      embed: embed_code
      exid: exid
      create_animation: true

    onError = (jqXHR, status, error) ->
      $("#spn-success-export").text("Failed to export compare.").removeClass("hide")
      $("#row-animation").addClass("hide")
      button.prop("disabled", false)

    onSuccess = (response, status, jqXHR) ->
      button.hide()
      $("#row-animation").addClass("hide")
      $("#row-textarea").removeClass("hide")
      $("#row-message").removeClass("hide")
      $("#spn-success-export").addClass("alert-info").removeClass("alert-danger").addClass("hide")
      $("#gif_url").val("#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/compares/#{response.compares[0].id}.gif".replace("media.evercam.io", "api.evercam.io"))
      $("#mp4_url").val("#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/compares/#{response.compares[0].id}.mp4".replace("media.evercam.io", "api.evercam.io"))
      clearTimeOut = setTimeout( ->
        auto_check_compare_status(response.compares[0].id, 0)
      , 10000)

    settings =
      cache: false
      data: data
      dataType: 'json'
      error: onError
      success: onSuccess
      type: 'POST'
      url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/compares"
    sendAJAXRequest(settings)

convert_timestamp_to_path = (timestamp) ->
  moment.tz(timestamp, Evercam.Camera.timezone).utc().format('YYYY-MM-DD-HH_mm_ss')

cancelForm = ->
  $('#export-compare-modal').on 'hide.bs.modal', ->
    clean_form()

  $('#export-compare-modal').on 'show.bs.modal', ->
    clean_form()

clean_form = ->
  $("#txtEmbedCode").val("")
  $("#row-textarea").addClass("hide")
  $("#spn-success-export").addClass("hide")
  $("#export_compare_button").prop("disabled", false)
  $("#export_compare_button").show()
  $("#row-gif-url").addClass("hide")
  $("#row-mp4-url").addClass("hide")
  $("#row-message").addClass("hide")
  clearTimeout(clearTimeOut)

download_animation = ->
  $(".download-animation").on "click", ->
    src_id = $(this).attr("data-download-target")
    file_name= $("#export-compare-title").val()
    NProgress.start()
    download_compare($("#{src_id}").val(), file_name)

download_compare = (url, file_name) ->
  xhr = new XMLHttpRequest()
  xhr.open('GET', url)
  xhr.responseType = 'blob'
  xhr.onload = ->
    type = xhr.response.type.split('/')[1]
    saveAs(xhr.response, "#{file_name}.#{type}")
    NProgress.done()
  xhr.onerror = ->
    console.error('could not download file')
  xhr.send()

switch_to_archive_tab = ->
  $("#switch_archive").on "click", ->
    $('#export-compare-modal').modal('hide')
    $(".nav-tab-archives").tab('show')

auto_check_compare_status = (compare_id, tries) ->
  onError = (jqXHR, status, error) ->
    false

  onSuccess = (response, status, jqXHR) ->
    if response.compares[0].status is "Completed"
      $("#row-gif-url").removeClass("hide")
      $("#row-mp4-url").removeClass("hide")
      $("#row-message").addClass("hide")
    else if response.compares[0].status is "Processing" && tries < 10
      clearTimeOut = setTimeout( ->
        auto_check_compare_status(response.compares[0].id, tries++)
      , 10000)

  settings =
      cache: false
      data: {}
      dataType: 'json'
      error: onError
      success: onSuccess
      type: 'GET'
      url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/compares/#{compare_id}?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
    sendAJAXRequest(settings)

makeRandString = ->
  text = ''
  possible = 'abcdefghijklmnopqrstuvwxyz'
  i = 0
  while i < 7
    text += possible.charAt(Math.floor(Math.random() * possible.length))
    i++
  text

window.initializeCompareTab = ->
  getFirstLastImages("compare_before", "/oldest", false, true)
  getFirstLastImages("compare_after", "/latest", false, false)
  handleTabOpen()
  export_compare()
  cancelForm()
  copyToClipboard(".copy-url-icon")
  download_animation()
  switch_to_archive_tab()
  setCompareEmbedCodeTitle()

  $('#calendar-before').datetimepicker
    format: 'm/d/Y H:m'
    id: 'before-calendar'
    onSelectTime: (dp, $input) ->
      $("#txtbefore").val($input.val())
      val = getQueryStringByName("after")
      iso_datetime = toISOString(moment.tz($input.val(), "MM/DD/YYYY hh:mm", Evercam.Camera.timezone))
      url = "#{Evercam.request.rootpath}/compare?before=#{iso_datetime}"
      if val isnt null
        url = "#{url}&after=#{val}"
      if history.replaceState
        window.history.replaceState({}, '', url)
      getFirstLastImages("compare_before", "/#{iso_datetime}/nearest", true, false)
    onChangeMonth: (dp, $input) ->
      xhrChangeMonth.abort()
      month = dp.getMonth() + 1
      year = dp.getFullYear()
      removeCalendarHighlightflag = true
      HighlightDaysInMonth("before-calendar", year, month)
      showBeforeAfterLoadingAnimation("before-calendar")
    onSelectDate: (ct, $i) ->
      month = ct.getMonth() + 1
      year = ct.getFullYear()
      date = ct.getDate()
      removeCalendarHighlightflag = true
      HighlightSnapshotHour("before-calendar", year, month, date)
      HighlightDaysInMonth("before-calendar", year, month)
      showBeforeAfterLoadingAnimation("before-calendar")
    onShow: (current_time, $input) ->
      month = current_time.getMonth() + 1
      year = current_time.getFullYear()
      date = current_time.getDate()
      removeCalendarHighlightflag = false
      HighlightDaysInMonth("before-calendar", year, month)
      HighlightSnapshotHour("before-calendar", year, month, date)
      showBeforeAfterLoadingAnimation("before-calendar")

  $('#calendar-after').datetimepicker
    format: 'm/d/Y H:m'
    id: 'after-calendar'
    onSelectTime: (dp, $input) ->
      $("#txtafter").val($input.val())
      val = getQueryStringByName("before")
      url = "#{Evercam.request.rootpath}/compare"
      iso_datetime = toISOString(moment.tz($input.val(), "MM/DD/YYYY hh:mm", Evercam.Camera.timezone))
      if val isnt null
        url = "#{url}?before=#{val}&after=#{iso_datetime}"
      else
        url = "#{url}?after=#{iso_datetime}"
      if history.replaceState
        window.history.replaceState({}, '', url)
      getFirstLastImages("compare_after", "/#{iso_datetime}/nearest", true, false)
    onChangeMonth: (dp, $input) ->
      xhrChangeMonth.abort()
      month = dp.getMonth() + 1
      year = dp.getFullYear()
      removeCalendarHighlightflag = true
      HighlightDaysInMonth("after-calendar", year, month)
      showBeforeAfterLoadingAnimation("after-calendar")
    onSelectDate: (ct, $i) ->
      month = ct.getMonth() + 1
      year = ct.getFullYear()
      date = ct.getDate()
      removeCalendarHighlightflag = true
      HighlightSnapshotHour("after-calendar", year, month, date)
      HighlightDaysInMonth("after-calendar", year, month)
      showBeforeAfterLoadingAnimation("after-calendar")
    onShow: (current_time, $input) ->
      month = current_time.getMonth() + 1
      year = current_time.getFullYear()
      date = current_time.getDate()
      removeCalendarHighlightflag = false
      HighlightDaysInMonth("after-calendar", year, month)
      HighlightSnapshotHour("after-calendar", year, month, date)
      showBeforeAfterLoadingAnimation("after-calendar")
