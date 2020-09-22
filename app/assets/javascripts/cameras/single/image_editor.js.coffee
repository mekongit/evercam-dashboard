#= require fabric.min.js
#= require tui-code-snippet.min.js
#= require tui-color-picker.min.js
#= require tui-image-editor.min.js
#= require image_editor_basic.js
#= require js.cookie.min.js

save_edited_file = ->
  $(".btn-save-edited-file").on "click", ->
    console.log "asda"

handle_tab_events = ->
  $('.nav-tab-image-editor').on 'hide.bs.tab', ->
    $("#tab_image_editor").addClass("hide")

window.initializeImageEditorTab = ->
  handle_tab_events()
  initEditorTool()
