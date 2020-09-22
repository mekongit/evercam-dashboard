evercam_logs = undefined

startReport = (logs) ->
  evercam_logs = logs
  chart = visavailChart()
  chart.width $('#visavail_container').width() - 200
  $('#draw_report').text ''
  d3.select('#draw_report').datum(logs).call chart
  return

onResize = ->
  $(window).resize ->
    startReport(evercam_logs)
    centerLoadingAnimation()

selectHistoryDays = ->
  $('#select-history-days, #type-all').on 'change', ->
    onChangeStatusReportDays($("#select-history-days").val(), $("input[name='offline_only']:checked").val())
    $('#visavail_container').addClass 'opacity'
    $('#status-report .loading-image-div').removeClass 'hide'
    $('#select-history-days ').attr 'disabled', 'disabled'

toggleLoadingImage = ->
  $('#visavail_container').removeClass 'opacity'
  $('#status-report .loading-image-div').addClass 'hide'
  $('#status-dropdown').removeClass 'hide'
  $('#select-history-days ').removeAttr 'disabled'

onChangeStatusReportDays = (days, offline_only) ->
  data = {}
  data.history_days = days
  data.offline_only = offline_only

  onError = (jqXHR, status, error) ->
    $(".bb-alert").removeClass("alert-info").addClass("alert-danger")
    Notification.show(error)
    toggleLoadingImage()

  onSuccess = (response, success, jqXHR) ->
    if response.length is 0
      toggleLoadingImage()
      $('#draw_report').hide()
    else
      startReport(response)
      toggleLoadingImage()
      $('#draw_report').show()

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    type: 'GET'
    url: "/status_report"

  sendAJAXRequest(settings)

centerLoadingAnimation = ->
  offset = ($(window).height() - 100) / 2
  $("#loading-image-div").css "margin-top", offset

window.initializeOnlineOfflineReport = ->
  onResize()
  Notification.init(".bb-alert")
  selectHistoryDays()
  onChangeStatusReportDays()
  centerLoadingAnimation()
