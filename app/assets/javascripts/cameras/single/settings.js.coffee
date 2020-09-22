onCameraDeleteError = (jqXHR, status, error) ->
  Notification.error "An error occurred removing your camera. Please try again and, if the problem persists, contact support."

onCameraDeleteSuccess = (data, status, jqXHR) ->
  if data.success
    Notification.info "Camera #{this} successfully."
    window.location = '/'
  else
    Notification.info data.message

handleCameraDelete = ->
  $("#delete-camera").on "click", (event) ->
    event.preventDefault()
    if $("#camera_specified_id") && $("#camera_specified_id").val() is ''
      Notification.error "Please enter camera id to confirm delete camera."
      return

    data =
      share: $("#share").val()
      camera_specified_id: $("#camera_specified_id").val()

    settings =
      cache: false
      data: data
      error: onCameraDeleteError
      success: onCameraDeleteSuccess
      context: 'deleted'
      url: "/cameras/#{Evercam.Camera.id}"
      type: 'DELETE'
    $.ajax(settings)

  $("#remove-camera").on "click", (event) ->
    event.preventDefault()
    data =
      share: $("#share").val()
      share_id: $("#share_id").val()

    settings =
      cache: false
      data: data
      error: onCameraDeleteError
      success: onCameraDeleteSuccess
      context: 'removed'
      url: "/cameras/#{Evercam.Camera.id}"
      type: 'DELETE'
    $.ajax(settings)

window.initializeSettingsTab = ->
  handleCameraDelete()
