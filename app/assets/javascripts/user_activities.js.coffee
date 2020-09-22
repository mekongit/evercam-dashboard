parser = undefined
format_time = null
table = undefined

initializeDataTable = ->
  table = $('#user-activity').DataTable({
    ajax: {
      url: "#{Evercam.API_URL}users/session/activities?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}&limit=10000#{get_search_query()}",
      dataSrc: (d) ->
        d.user_logs
      error: (xhr, error, thrown) ->
        if xhr.responseJSON
          Notification.show(xhr.responseJSON.message)
        else
          Notification.show("Something went wrong, Please try again.")
        NProgress.done()
    },
    columns: [
      {data: (row, type, set, meta) ->
        if row.extra && row.extra.agent
          if row.extra.agent.indexOf("iPhone") isnt -1
            return "<i class='fab fa-apple'></i> iOS APP"
          else if row.extra.agent.indexOf("java") isnt -1
            return "<i class='fab fa-android'></i> Andriod APP"
          else
            agent = parse_agent_string(row.extra.agent)
            if agent.browser.name
              return "<i class='fab fa-#{agent.browser.name.toLowerCase()}'></i> #{agent.browser.name} on #{agent.os.name}"
            else
              ""
        else
          ""
      , orderable: false},
      {data: (row, type, set, meta) ->
        if row.extra && row.extra.ip
          return row.extra.ip
        else
          ""
      , orderable: false},
      {data: (row, type, set, meta) ->
        if row.extra && row.extra.country && row.extra.country_code
          return "<img src='https://www.countryflags.io/#{row.extra.country_code}/shiny/16.png'> #{row.extra.country}"
        else
          ""
      , orderable: false},
      {data: ( row, type, set, meta ) ->
        time = moment(row.done_at)
        return "<span>#{moment(time).format('MMMM Do YYYY, HH:mm:ss')}</span>"
      , sType: 'uk_datetime', orderable: false },
      {data: ( row, type, set, meta ) ->
        if row.extra && row.extra.name
          action_title = "<b>#{row.extra.name}</b>"
        else
          action_title = ""

        if row.action is 'shared' or row.action is 'stopped sharing' or row.action is "updated share"
          desc = ""
          if row.action is "updated share"
            desc = "rights "
          if row.extra && row.extra.with
            return ("Camera <b>#{row.camera_exid}</b> #{row.action} #{desc}with #{row.extra.with}")
          else
            return row.action
        else if row.action is 'cloud recordings updated' or row.action is 'cloud recordings created'
          return "#{row.action} for <b>#{row.camera_exid}</b>"
        else if row.action is 'created' or row.action is 'camera created'
          return "Camera <b>#{row.camera_exid}</b> created"
        else if row.action is 'edited' or row.action is 'camera edited'
          return "Camera <b>#{row.camera_exid}</b> updated"
        else if row.action is 'camera deleted'
          return "Camera <b>#{row.camera_exid}</b> deleted"
        else if row.action is 'archive deleted'
          return "Archive #{action_title} deleted from camera <b>#{row.camera_exid}</b>"
        else if row.action is 'archive created'
          return "Archive #{action_title} created for camera <b>#{row.camera_exid}</b>"
        else if row.action is 'file uploaded'
          return "File #{action_title} uploaded in camera <b>#{row.camera_exid}</b>"
        else if row.action is 'saved media URL'
          return "Saved media URL #{action_title} in camera <b>#{row.camera_exid}</b>"
        else if row.action is "archive edited"
          return "Archive #{action_title} updated in camera <b>#{row.camera_exid}</b>"
        else if row.action is "compare created"
          return "Compare #{action_title.replace("Compare: ", "")} created for camera <b>#{row.camera_exid}</b>"
        else if row.action is "compare deleted"
          return "Compare #{action_title.replace("Compare: ", "")} deleted from camera <b>#{row.camera_exid}</b>"
        else if row.action is "user edited"
          return "User settings updated"
        else if row.action is "login using api_id / api_key"
          return "Login using API_ID and API_KEY"
        else if row.action is "login"
          return "Login"
        else if row.action is "logout"
          return "Logout"
        else
            return row.action
      , orderable: false}
    ],
    autoWidth: false,
    info: false,
    bPaginate: false,
    pageLength: 50
    "language": {
      "emptyTable": "No data available"
    },
    order: [],
    drawCallback: ->
      NProgress.done()
    initComplete: (settings, json) ->
      $("#user-activity_length").hide()
      $("#user-activity_filter").hide()
      $("#user-activity_wrapper div.col-sm-12").removeClass("col-sm-12")
  })
  $("#user-activity_filter").hide()
  $("#user-activity_wrapper div.col-sm-12").removeClass("col-sm-12")

parse_agent_string = (agent_string) ->
  parser.setUA(agent_string)
  result = parser.getResult()
  data =
    browser: result.browser
    device: result.device
    os: result.os
    os_version: result.os.version
    engine_name: result.engine.name
    cpu_architecture: result.cpu.architecture

initDatepicker = ->
  $(".datetimepicker").datetimepicker
    timepicker: false
    closeOnDateSelect: 0
    format: 'd/m/Y H:i'

getDate = (type) ->
  DateFromTime = new Date(moment.utc().format('MM/DD/YYYY, HH:mm:ss'))
  if type is "from"
    DateFromTime.setMonth(DateFromTime.getMonth() - 5)
    DateFromTime.setHours(0)
    DateFromTime.setMinutes(0)
  if type is "to"
    DateFromTime.setHours(23)
    DateFromTime.setMinutes(59)
  Dateformated =  format_time.formatDate(DateFromTime, 'd/m/Y H:i')
  return Dateformated

get_search_query = ->
  from_date = moment($('#datetimepicker_from').val(), "DD-MM-YYYY H:mm")
  to_date = moment($('#datetimepicker_to').val(), "DD-MM-YYYY H:mm")
  from = from_date.toISOString()
  to = to_date.toISOString()

  fromto_seg = ''
  fromto_seg += '&from=' + from if from
  fromto_seg += '&to=' + to if isNaN(to)
  return fromto_seg

searchLogs = ->
  $("#search-logs").on "click", ->
    NProgress.start()
    url = "#{Evercam.API_URL}users/session/activities?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}&limit=10000#{get_search_query()}"
    table.ajax.url(url).load() if table?

window.initializeUserActivity = ->
  format_time = new DateFormatter()
  $("#datetimepicker_from").val(getDate("from"))
  $("#datetimepicker_to").val(getDate("to"))
  initDatepicker()
  initializeDataTable()
  parser = new UAParser()
  searchLogs()
