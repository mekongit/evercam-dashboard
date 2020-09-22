resizeWin = ->
  $(window).resize ->
    $('#evercam-video-section').css height: $(window).innerHeight()
    centerSignIn()
    centerNotLoggedInNotification()
    return

centerSignIn = ->
  offset = ($(window).height() - $('.section-position').height()) / 2
  if $(window).height() > $('.section-position').height()
    # Center vertically in window
    $('.section-position').css "margin-top", offset

  widthset = ($(window).width() - $('.center-div').width()) / 2
  if $(window).width() > $('.center-div').width()
    # Center vertically in window
    $('.center-div').css "margin-left", widthset

validateUsernameEmail = (input_String, input_name) ->
  data = {}

  onError = (jqXHR, status, error) ->
    $("##{input_name}-error-block").css 'display', 'none'
    $("#signup-#{input_name} .#{input_name}-loading-icon").hide()
    $("##{input_name}-available").removeClass('hide')
    $("##{input_name}-not-available").addClass('hide')

  onSuccess = (response, status, jqXHR) ->
    $("##{input_name}-error-block").css 'display', 'block'
    $("#signup-#{input_name} .#{input_name}-loading-icon").hide()
    $("##{input_name}-not-available").removeClass('hide')
    $("##{input_name}-available").addClass('hide')

  settings =
    cache: false
    dataType: 'json'
    error: onError
    success: onSuccess
    type: 'POST'
    url: "#{Evercam.API_URL}users/exist/#{input_String}"
  $.ajax(settings)

getInputValue = ->
  $('#user_firstname').focusout ->
    input_value = $('#user_firstname').val()
    if !validateName(input_value)
      $('#invalid-userfirst-name').css 'display', 'block'
    else
      $('#invalid-userfirst-name').css 'display', 'none'

  $('#user_lastname').focusout ->
    input_value = $('#user_lastname').val()
    if !validateName(input_value)
      $('#invalid-userlast-name').css 'display', 'block'
    else
      $('#invalid-userlast-name').css 'display', 'none'
  
  $('#user_email').focusout ->
    input_value = $('#user_email').val()
    user_email = 'email'
    if !validateEmail(input_value)
      $('#signup-email').addClass('has-error')
      $('#incorrect-email-block').css 'display', 'block'
      validateExistingEmailValue(input_value, user_email)
    else
      $('#signup-email').removeClass('has-error')
      $('#incorrect-email-block').css 'display', 'none'
      validateExistingEmailValue(input_value, user_email)

  $('#user_password').focusout ->
    input_value = $('#user_password').val()
    if !validatePassword(input_value)
      $('#invalid-password').css 'display', 'block'
    else
      $('#invalid-password').css 'display', 'none'

validateExistingEmailValue = (input_value, user_email) ->
  setTimeout (->
    if $('#signup-email').hasClass('has-error')
      hideEmailValidationIcons()
      $('#email-error-block').css 'display', 'none'
    else
      hideEmailValidationIcons()
      $('#signup-email .email-loading-icon').show()
      validateUsernameEmail(input_value, user_email)
  ), 100

validateEmail = (email) ->
  re = /^(?!.*\.{2})[a-zA-Z0-9!.#$%&'*+"/=?^_`{|}~-]+@[a-zA-Z\d\-]+(\.[a-zA-Z]+)*\.[a-zA-Z]+\z*$/
  addresstrimed = email.replace(RegExp(' ', 'gi'), '')
  if re.test(addresstrimed) == false
    false
  else
    true

validateName = (first_last_name) ->
  re = /^[A-Za-z\/\s\']*$/
  addresstrimed = first_last_name.replace(RegExp(' ', 'gi'), '')
  if re.test(addresstrimed) == false
    false
  else
    true

validatePassword = (password) ->
  re = /^.{6,}$/
  addresstrimed = password.replace(RegExp(' ', 'gi'), '')
  if re.test(addresstrimed) == false
    false
  else
    true

hideUsernameValidationIcons = ->
  $('#username-not-available').addClass('hide')
  $('#username-available').addClass('hide')

hideEmailValidationIcons = ->
  $('#email-not-available').addClass('hide')
  $('#email-available').addClass('hide')

showNotLoggedInUserNotification = ->
  requested_url_value = $("#request_url_value").val()
  if requested_url_value
    if requested_url_value.indexOf('cameras/') > -1
      $('#signout-user-message').show()
      setTimeout (->
        $('#signout-user-message').fadeOut('slow')
        return
      ), 15000
    else
      $('#signout-user-message').hide()

centerNotLoggedInNotification = ->
  widthset = ($(window).width() - $('#signout-user-message').width()) / 2
  if $(window).width() > $('#signout-user-message').width()
    $('#signout-user-message').css "left", widthset
    $('#signout-user-message').css "margin-left", "-14px"

window.initializeVideoBackground = ->
  centerSignIn()
  resizeWin()
  getInputValue()
  showNotLoggedInUserNotification()
  centerNotLoggedInNotification()
