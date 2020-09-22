#= require amcharts.js
#= require serial.js

chart = null
amChart = null
chartData = []
start_index = 0
errors = []
success = []
sum = 0
total_success = 0
total_errors = 0
start_date = moment()

calculate_failed_percentage = ->
  curr_date_time = moment()
  minutes = curr_date_time.diff(start_date, 'minutes')
  failed_perc = (total_errors / (Evercam.Camera.cloud_recording.frequency * minutes)) * 100
  if total_errors is 0
    $("#spn_failed_persent").text("0%")
  else
    $("#spn_failed_persent").text("#{parseFloat(failed_perc).toFixed(2)}%")

arrange_datasets = (data) ->
  start_date = moment(data[0])
  data.splice(0, 1)
  textarea = $("#txt-response-live-tail")

  while(start_index < data.length)
    val = data[start_index + 1]
    date_time = moment(data[start_index]*1000)
    row = "<div class='float-left'>[#{date_time.format('MM/DD/YYYY HH:mm:ss')}]</div> <div class='float-left'>#{val}</div>"
    if val.indexOf("[Error]") >= 0
      textarea.append("<div class='col-sm-12 tail-padding-left5' style='color: red;'>#{row}</div>")
      errors.push val
      success.push 0
      total_errors += 1
      chartData.push
        date: new Date(date_time)
        error: parseFloat(val.split(" ")[1].replace("[", "").replace("]", ""))
    else
      textarea.append("<div class='col-sm-12 tail-padding-left5'>#{row}</div>")
      success.push val
      response_time = parseFloat(val.split(" ")[1].replace("[", "").replace("]", ""))
      sum += response_time
      total_success += 1
      errors.push 0
      chartData.push
        date: new Date(date_time)
        snapshot: response_time

    start_index += 2

  calculate_failed_percentage()
  if sum is 0
    $("#spn_success_average").text("0.00")
  else
    $("#spn_success_average").text(parseFloat(sum/total_success).toFixed(4))
  draw_amcharts()

draw_amcharts = ->
  chartData = chartData.slice(chartData.length - 2000)

  amChart = AmCharts.makeChart('chartdiv',
    type: 'serial'
    dataProvider: chartData
    categoryField: 'date'
    path: "/assets/"
    pathToImages: "/assets/"
    categoryAxis:
      parseDates: true
      gridAlpha: 0.15
      minorGridEnabled: true
      axisColor: '#DADADA'
    valueAxes: [ {
      axisAlpha: 0.2
      id: 'v1'
    } ]
    graphs: [
      {
        type: 'column'
        title: 'Snapshot'
        id: 'g1'
        valueField: 'snapshot'
        lineAlpha: 0
        fillAlphas: 0.8
        fillAlphas: 1
        lineColor: "#2ecc71"
        balloonText: '[[title]] in [[category]]: <b>[[value]]</b>'
      }
      {
        type: 'column'
        title: 'Error'
        id: 'g2'
        valueField: 'error'
        lineThickness: 2
        lineAlpha: 0
        fillAlphas: 0.8
        fillAlphas: 1
        lineColor: "#DC4C3F"
        fillColorsField: '#DC4C3F'
        balloonText: '[[title]] in [[category]]: <b>[[value]]</b>'
      }
    ]
    chartCursor:
      categoryBalloonDateFormat: "MMM DD JJ:NN:SS",
      cursorPosition: "mouse",
      fullWidth: true
      cursorAlpha: 0.1
    categoryAxis:
      minPeriod: 'ss'
      parseDates: true
    chartScrollbar:
      scrollbarHeight: 30
      color: '#FFFFFF'
      dragIconHeight: 22
      dragIconWidth: 22
      graph: 'g1'
    mouseWheelZoomEnabled: true)

  amChart.addListener 'dataUpdated', zoomChart
  $("#chartdiv").removeClass("hide")

zoomChart = ->
  # different zoom methods can be used - zoomToIndexes, zoomToDates, zoomToCategoryValues
  try
    amChart.zoomToIndexes chartData.length - 40, chartData.length - 1
  catch e
    error = e

get_responses = (is_update) ->
  data =
    api_id: Evercam.User.api_id
    api_key: Evercam.User.api_key

  onError = (data) ->
    false

  onSuccess = (data) ->
    if data isnt null
      if is_update
        arrange_datasets(data)
        chart.config.data.datasets[0].data = success
        chart.config.data.datasets[1].data = errors
        chart.update()
        setTimeout (-> arrange_datasets(data)), 60000
      else
        arrange_datasets(data)

  settings =
    error: onError
    success: onSuccess
    data: data
    dataType: 'json'
    contentType: "application/json charset=utf-8"
    type: "GET"
    url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/response-time"

  $.ajax(settings)

get_error = (str) ->
  switch str
    when "Error: 0" then ["unhandled", 80]
    when "Error: 0.5" then ["system_limit", 95]
    when "Error: 1" then ["emfile", 57]
    when "Error: 1.5" then ["case_clause", 95]
    when "Error: 2" then ["bad_request", 95]
    when "Error: 2.5" then ["closed", 59]
    when "Error: 3" then ["nxdomain", 75]
    when "Error: 3.5" then ["ehostunreach", 96]
    when "Error: 4" then ["enetunreach", 94]
    when "Error: 4.5" then ["req_timedout", 96]
    when "Error: 5" then ["timeout", 65]
    when "Error: 5.5" then ["connect_timeout", 112]
    when "Error: 6" then ["econnrefused", 103]
    when "Error: 6.5" then ["not_found", 80]
    when "Error: 7" then ["forbidden", 80]
    when "Error: 7.5" then ["unauthorized", 95]
    when "Error: 8" then ["device_error", 95]
    when "Error: 8.5" then ["device_busy", 95]
    when "Error: 9" then ["invalid_operation", 120]
    when "Error: 9.5" then ["moved", 60]
    when "Error: 10" then ["not_a_jpeg", 90]
    else ["else", 0]

get_error_text = (str) ->
  switch str
    when 0 then "unhandled"
    when 0.5 then "system_limit"
    when 1 then "emfile"
    when 1.5 then "case_clause"
    when 2 then "bad_request"
    when 2.5 then "closed"
    when 3 then "nxdomain"
    when 3.5 then "ehostunreach"
    when 4 then "enetunreach"
    when 4.5 then "req_timedout"
    when 5 then "timeout"
    when 5.5 then "connect_timeout"
    when 6 then "econnrefused"
    when 6.5 then "not_found"
    when 7 then "forbidden"
    when 7.5 then "unauthorized"
    when 8 then "device_error"
    when 8.5 then "device_busy"
    when 9 then "invalid_operation"
    when 9.5 then "moved"
    when 10 then "not_a_jpeg"
    else "Unhandled"

scroll_to_end = ->
  textarea = $("#txt-response-live-tail")
  if textarea.length
    scroll_diff = textarea[0].scrollHeight - textarea.scrollTop()
    if scroll_diff <= 400
      textarea.scrollTop(textarea[0].scrollHeight - textarea.height())

initial_scroll_to_end = ->
  textarea = $("#txt-response-live-tail")
  if textarea.length
    textarea.scrollTop(textarea[0].scrollHeight - textarea.height())

start_live_tail = ->
  Evercam.livetail_channel = Evercam.socket.channel("livetail:#{Evercam.Camera.id}")
  Evercam.livetail_channel.join()
  Evercam.livetail_channel.on 'camera-response', (payload) ->
    textarea = $("#txt-response-live-tail")
    timestamp = "<div class='float-left'>[#{moment(payload.timestamp*1000).format('MM/DD/YYYY HH:mm:ss')}:]</div>"
    response_time = "<div class='float-left'>[#{payload.response_time}]</div>"
    description = "<div class='float-left'>[#{payload.description}]</div>"
    if payload.response_type is "ok"
      sum += payload.response_time
      total_success += 1
      textarea.append("<div class='col-sm-12 tail-padding-left5'>#{timestamp} <div class='float-left'>[Snapshot]</div>#{response_time} #{description}</div>")
    else
      total_errors += 1
      textarea.append("<div class='col-sm-12 tail-padding-left5' style='color: red;'>#{timestamp} <div class='float-left'>[Error]</div>#{response_time} <div class='float-left'>[#{payload.response_type}]</div> #{description}</div>")

    calculate_failed_percentage()
    if sum is 0
      $("#spn_success_average").text("0.00")
    else
      $("#spn_success_average").text(parseFloat(sum/total_success).toFixed(4))
    scroll_to_end()

stop_live_tail = ->
  Evercam.livetail_channel.leave() if Evercam.livetail_channel

handleTabOpen = ->
  $('.nav-tab-logs').on 'show.bs.tab', ->
    setTimeout initial_scroll_to_end, 500
    start_live_tail()

  $('.nav-tab-logs').on 'hide.bs.tab', ->
    stop_live_tail()

window.initJqueryPlotResponseTime = ->
  get_responses()
  handleTabOpen()
