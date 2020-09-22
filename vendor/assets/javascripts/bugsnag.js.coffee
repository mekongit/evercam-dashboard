initializeBugsnag = ->
  bugsnag
    apiKey: '914a9c62307b9fccfdf29c7c381fa5d3'
    appVersion: '4.10.0'

window.initializeBugSnag = ->
  initializeBugsnag()
