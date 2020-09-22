submitForm = ->
  $("#submit-button").on "click", ->
    if $("#email").val() is "" || $("#amount").val() is "" || $("#card-number").val() is "" || $("#name").val() is "" || $("#card-cvc").val() is ""
      Notification.show(" Please add required fields: Email, Amount and card details.")
      return false
    else
      return ValidateCardData()

ValidateCardData = ->
  if $('#name').val() isnt '' and $('#card-number').val() isnt ''
    if $('#name').val() is $('#card-number').val()
      Notification.show ' Card number cannot be name of Card holder.'
      return false

  if $('#name').val() is ''
    Notification.show 'Cardholder name must not be empty.'
    return false

  cardNumber = $('#card-number').val()
  if cardNumber is ''
    Notification.show ' Please enter Card Number.'
    return false
  else if !isCreditCard(cardNumber)
    Notification.show ' Please enter valid Card Number.'
    return false

  result = ExpiryDate($('#expiry-month').val(), $('#expiry-year').val())
  if result isnt undefined
    Notification.show result
    return false
  true

isCreditCard = (creditCardNo) ->
  if creditCardNo.length < 10 or creditCardNo.length > 19
    return false
  sum = 0
  mul = 1
  l = creditCardNo.length
  i = 0
  while i < l
    digit = creditCardNo.substring(l - i - 1, l - i)
    tproduct = parseInt(digit, 10) * mul
    if tproduct >= 10
      sum += tproduct % 10 + 1
    else
      sum += tproduct
    if mul == 1
      mul++
    else
      mul--
    i++
  if sum % 10 == 0
    true
  else
    false

ExpiryDate = (sMonth, sYear) ->
  d = new Date
  currentMonth = d.getMonth()
  currentMonth = currentMonth + 1
  iMonth = parseInt(sMonth)
  iYear = parseInt(sYear)
  currentYear = d.getFullYear()
  if parseInt(sMonth) < currentMonth and iYear <= currentYear
    return 'Card expiry should be a future date.'
  if !(iMonth >= 1 and iMonth <= 12)
    return 'Card expiry month must be between 01 and 12 inclusive.'
  if iYear < currentYear - 1
    return 'Card expiry year is too far into the past.'
  if iYear > currentYear + 20
    return 'Card expiry year is too far into the future.'

CheckCardNumber = ->
  $("#card-number").on "keyup", ->
    if !validateInt($(this).val())
      value = $(this).val()
      $(this).val value.substring(0, value.length - 1)
      return false
    # $('#errMessage').html ''
    # CheckCard(this)

validateInt = (address) ->
  reg = /^(0|[0-9][1-9]|[1-9][0-9]*)$/
  if reg.test(address) == false
    false
  else
    true

CheckCard = (control) ->
  $('ul.cards li').each ->
    $(this).find('span').removeClass 'cdisabled'
    return
  cardTypeSelectedText = creditCardTypeFromNumber($(control).val())
  $('ul.cards li').each ->
    curSpan = $(this).find('span').html()
    if curSpan != cardTypeSelectedText
      $(this).find('span').addClass 'cdisabled'
    #else
    #    $("#<=ddlCardType.ClientID %>").val(type);

creditCardTypeFromNumber = (num) ->
# first, sanitize the number by removing all non-digit characters.
  num = num.replace(/[^\d]/g, '')
  # now test the number against some regexes to figure out the card type.
  if num.match(/^5[1-5]/)
    return 'MC'
  else if num.match(/^4\d{15}/) or num.match(/^4\d{12}/)
    return 'VISA'
  else if num.match(/^3[47]/)
    return 'AMEX'
  else if num.match(/^(36|30|38)/)
    return 'DINERS'
  else if num.match(/^(6304|670[69]|6771)/)
    return 'LASER'
  ''

autoDecimal = ->
  $("#amount").on "blur", ->
    value = $(this).val()
    if value
      $(this).val(parseFloat(value).toFixed(2))

window.initializePay = ->
  CheckCardNumber()
  submitForm()
  autoDecimal()