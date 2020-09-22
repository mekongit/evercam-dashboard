format_time = null

initializeCamerasDataTable = ->
  camera_table = $('#cameras-log-table').DataTable({
    ajax: {
      url: $("#base-url").val(),
      dataSrc: 'cameras',
      error: (xhr, error, thrown) ->
        if xhr.responseJSON
          Notification.show(xhr.responseJSON.message)
        else
          Notification.show("Something went wrong, Please try again.")
    },
    columns: [
      {data: (row, type, set, meta ) ->
        if row.status == "online"
          return "
          <a href='/v2/cameras/#{row.id}' target='_blank'>#{row.name}</a>"
        else
          return "
          <a href='/v2/cameras/#{row.id}' target='_blank'>#{row.name}</a>
          <i class='red main-sidebar fa fa-unlink font-12'></i>"
      },
      {data: userCameraRights},
      {data: (row, type, set, meta ) ->
        if row.vendor_name
          return "#{row.vendor_name} (#{row.model_name})"
        else
          ""
      },
      {data: (row, type, set, meta ) ->
        if row.timezone
          return row.timezone
        else
          return ""
      },
      {data: (row, type, set, meta ) ->
        if row.is_public
          return "<span style='color: green'>Yes</span>"
        else
          return "<span style='color: red'>No</span>"
      },
      {data: (row, type, set, meta ) ->
        if row.cloud_recordings
          cr = row.cloud_recordings
          getCloudStatus(cr.status, cr.storage_duration, cr.frequency)
        else if row.rights.indexOf("edit") == -1
          return "<span>Not Available</span>"
        else
          return "<span style='color: red'>Off (No Recordings)</span>"
      },
    ],
    order: [[ 3, "desc" ]],
    bPaginate: false,
    bSort: true,
    bFilter: false,
    autoWidth: false,
  })

getCloudStatus = (status, duration, frequency) ->
  if frequency is 60
    text_frequency = ", 1 per second"
  else
    text_frequency = ", 1 every #{60/frequency} seconds"
  storage = "#{duration} Days"
  if duration is 1
    storage = "24 Hours"
  else if duration is -1
    storage = "Inifinity"
  switch status
    when "on"
      return "
      <span style='color: green'>#{storage} (Continuous)</span>
      #{text_frequency}"
    when "on-scheduled"
      return "
      <span style='color: green'>#{storage} (On Schedule)</span>
      #{text_frequency}"
    when "off"
      return "<span style='color: red'>Off (No Recordings)</span>"
    when "paused"
      return "
      <span style='color: black'>Paused (#{storage})</span>
      #{text_frequency}"

userCameraRights = (row) ->
  str = row.rights
  arr = str.split(",")
  if row.owned == true
    return "Owner"
  else if arr.indexOf("edit") != -1
    return "Full"
  else
    return "Read only"

window.initializeCamerasTable = ->
  format_time = new DateFormatter()
  initializeCamerasDataTable()
