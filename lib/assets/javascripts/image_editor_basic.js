/**
 * basic.js
 * @author NHN Ent. FE Development Team <dl_javascript@nhnent.com>
 * @fileoverview
 */
'use strict';

function copyUrl(){
  var url = document.createElement('p');
	url.innerHTML = "https://project1-evercam.herokuapp.com/image-editor/img/img.html";

	var div1 = document.createElement('div');
	div1.contentEditable = true;
	div1.appendChild(url);
	document.body.appendChild(div1);

	SelectText(div1);
	try {
		var successful = document.execCommand('copy');
		var msg = successful ? 'successful' : 'unsuccessful';
	} catch (err) {
		console.log('Oops, unable to copy');
	}
	document.body.removeChild(div1);
}

function copyImg(){
  var img = document.createElement('img');
	img.src = imageEditor.toDataURL('image/jpeg', 0.1);

	var div1 = document.createElement('div');
	div1.contentEditable = true;
	div1.appendChild(img);
	document.body.appendChild(div1);

	SelectText(div1);
	try {
		var successful = document.execCommand('copy');
		var msg = successful ? 'successful' : 'unsuccessful';
	} catch (err) {
		console.log('Oops, unable to copy');
	}
	document.body.removeChild(div1);
}

function SelectText(element) {
	var doc = document;
	if (doc.body.createTextRange) {
		var range = document.body.createTextRange();
		range.moveToElementText(element);
		range.select();
	} else if (window.getSelection) {
		var selection = window.getSelection();
		var range = document.createRange();
		range.selectNodeContents(element);
		selection.removeAllRanges();
		selection.addRange(range);
	}
}

var supportingFileAPI = !!(window.File && window.FileList && window.FileReader);
var rImageType = /data:(image\/.+);base64,/;
var selected_color = '#ff0000';
var method = "POST";
var archive_id, archive_title, archive_timestamp;
var shapeOptions = {};
var saving_image = false;
var shapeType, activeObjectId, imageEditor, instanceBrush, instanceText, instanceShape, instanceArrow;

// Buttons
var $btns, $btnsActivatable, $inputImage, $btnDownload, $btnUndo, $btnRedo, $btnClearObjects, $btnDrawLinefree, $btnDrawLinestraight, $btnDrawRect;
var $btnDrawCircle, $btnSelection, $btnText, $btnAddIcon, $btnRegisterIcon, $btnClose, $btnApplyCrop, $btnCancelCrop;

// Input etc.
var $inputBrushWidthRange, $inputFontSizeRange, $inputStrokeWidthRange, $inputCheckTransparent, $inputCheckGrayscale;

// Sub menus
var $displayingSubMenu, $drawLineSubMenu, $imageFilterSubMenu, $cropSubMenu;

// Select line type
var $selectLine, $selectShapeType, $drawRectangle, $selectColorType, $selectBlendType, $selectedTool;

function set_variables() {
  //buttons
  $btns = $('.menu-item');
  $btnsActivatable = $btns.filter('.activatable');
  $inputImage = $('#input-image-file');
  $btnDownload = $('#btn-download');
  $btnUndo = $('#btn-undo');
  $btnRedo = $('#btn-redo');
  $btnClearObjects = $('#btn-clear-objects');
  $btnDrawLinefree = $('#btn-draw-line-free');
  $btnDrawLinestraight = $('#btn-draw-line-straight');
  $btnDrawRect = $('#btn-draw-rect');
  $btnDrawCircle = $('#btn-draw-circle');
  $btnSelection = $('#selection');
  $btnText = $('#btn-text');
  $btnAddIcon = $('#btn-add-icon');
  $btnRegisterIcon = $('#btn-register-icon');
  $btnClose = $('.close');
  $btnApplyCrop = $('#btn-apply-crop');
  $btnCancelCrop = $('#btn-cancel-crop');

  //input
  $inputBrushWidthRange = $('#input-brush-width-range');
  $inputFontSizeRange = $('#input-font-size-range');
  $inputStrokeWidthRange = $('#input-stroke-width-range');
  $inputCheckTransparent = $('#input-check-transparent');
  $inputCheckGrayscale = $('#input-check-grayscale');

  // Sub menus
  $displayingSubMenu = $();
  $drawLineSubMenu = $('#draw-line-sub-menu');

  $imageFilterSubMenu = $('#image-filter-sub-menu');
  $cropSubMenu = $('#crop-sub-menu');

  // Select line type
  $selectLine = $('[name="select-line-type"]');

  // Select shape type
  $selectShapeType = $('[name="select-shape-type"]');
  $drawRectangle = $('#type-rectangle');

  // Select color of shape type
  $selectColorType = $('[name="select-color-type"]');

  //Select blend type
  $selectBlendType = $('[name="select-blend-type"]');
}

function initImageEditor() {
  imageEditor = new tui.ImageEditor(document.querySelector('#tui-image-editor'), {
      cssMaxWidth: "100%",
      cssMaxHeight: "100%",
      usageStatistics: false,
      selectionStyle: {
        cornerSize: 20,
        rotatingPointOffset: 70
      }
  });
  resizeEditor();
}

function resizeEditor() {
  var view_height = Metronic.getViewPort().height;
  var controls_height = $(".tui-image-editor-controls").height();
  var nav_tab = $("#ul-nav-tab").height();
  var container_height = $(".container-info").height();
  var top_height = controls_height + nav_tab + container_height + 20;
  view_height = view_height - top_height;
  var top = view_height / 2;

  $("#tui-image-editor").height("100%");
  $(".tui-image-editor-canvas-container").css("padding-top", "56.2%");

  var max_width = $("#tui-image-editor").width();
  if (max_width === 0) {
    set_loading_resolution();
    max_width = 350;
  }

  // imageEditor.resizeCanvasDimension({width: max_width, height: view_height})
  $(".tui-image-editor-canvas-container").css("max-width", max_width + "px");
  $(".tui-image-editor-canvas-container").css("max-height", "100%");

  $(".lower-canvas").css("max-width", max_width + "px");
  $(".lower-canvas").css("max-height", "100%");

  $(".upper-canvas").css("max-width", max_width + "px");
  $(".upper-canvas").css("max-height", "100%");

  $(".div-save-edit-image").height("100%")
  $(".div-save-edit-image").width(max_width)
  $(".saving-light-box").height(view_height + 85)
  $(".saving-light-box").width(max_width)
}

function set_loading_resolution() {
  $(".tui-image-editor-canvas-container").width(350);
  $(".tui-image-editor-canvas-container").height(351);

  $(".lower-canvas").width(350);
  $(".lower-canvas").height(351);

  $(".upper-canvas").width(350);
  $(".upper-canvas").height(351);
}

function reset_canvas_size() {
  $(".tui-image-editor-canvas-container").css("width", "100%");
  $(".tui-image-editor-canvas-container").css("height", "100%");

  $(".lower-canvas").css("width", "100%");
  $(".lower-canvas").css("height", "100%");

  $(".upper-canvas").css("width", "100%");
  $(".upper-canvas").css("height", "100%");
}

function initColorPicker() {
  instanceBrush = tui.colorPicker.create({
  	container: $('#tui-brush-color-picker')[0],
    color: selected_color
  });

  $("input[title='#FF0000']").addClass("tui-colorpicker-selected")
}

// Common global functions
// HEX to RGBA
function hexToRGBa(hex, alpha) {
    var r = parseInt(hex.slice(1, 3), 16);
    var g = parseInt(hex.slice(3, 5), 16);
    var b = parseInt(hex.slice(5, 7), 16);
    var a = alpha || 1;

    return 'rgba(' + r + ', ' + g + ', ' + b + ', ' + a + ')';
}

function setShapeToolbar(obj) {
    var strokeColor, fillColor, isTransparent;
    var colorType = $selectColorType.val();

    if (colorType === 'stroke') {
        strokeColor = obj.stroke;
        isTransparent = (strokeColor === 'transparent');

        if (!isTransparent) {
            shapeColorpicker.setColor(strokeColor);
        }
    } else if (colorType === 'fill') {
        fillColor = obj.fill;
        isTransparent = (fillColor === 'transparent');

        if (!isTransparent) {
            shapeColorpicker.setColor(fillColor);
        }
    }

    $inputCheckTransparent.prop('checked', isTransparent);
    $inputStrokeWidthRange.val(obj.strokeWidth);
}

function getBrushSettings() {
  var brushWidth = 10;
  selected_color = instanceBrush.getColor();

  return {
    width: brushWidth,
    color: hexToRGBa(selected_color, 1.0)
  };
}

function activateShapeMode() {
  if (imageEditor.getDrawingMode() !== 'SHAPE') {
    imageEditor.stopDrawingMode();
    imageEditor.startDrawingMode('SHAPE');
  }
}

function activateSelectionMode() {
  imageEditor.stopDrawingMode();
  $("#image-editor li.active").removeClass("active");
}

function activateIconMode() {
  imageEditor.stopDrawingMode();
}

function activateTextMode() {
  if (imageEditor.getDrawingMode() !== 'TEXT') {
    imageEditor.stopDrawingMode();
    imageEditor.startDrawingMode('TEXT');
  }
}

function setTextToolbar(obj) {
  var fontSize = obj.fontSize;
  var fontColor = obj.fill;

  $inputFontSizeRange.val(fontSize);
  instanceBrush.setColor(fontColor);
}

function setIconToolbar(obj) {
  var iconColor = obj.fill;

  instanceBrush.setColor(iconColor);
}

function applyOrRemoveFilter(applying, type, options) {
    if (applying) {
      imageEditor.applyFilter(type, options).then(function (result) { });
    } else {
      imageEditor.removeFilter(type);
    }
}

function activate_free_line_mode() {
  imageEditor.stopDrawingMode();

  var settings = getBrushSettings();
  imageEditor.stopDrawingMode();
  imageEditor.startDrawingMode('FREE_DRAWING', settings);
  $("#image-editor li.active").removeClass("active");
  $btnDrawLinefree.addClass("active");
  $selectedTool = $btnDrawLinefree;
}

function image_editor_fn(){
  imageEditor.on({
    objectAdded: function(objectProps) {

    },
    undoStackChanged: function(length) {
      if (length) {
        $btnUndo.removeClass('disabled');
      } else {
        $btnUndo.addClass('disabled');
      }
      resizeEditor();
    },
    redoStackChanged: function(length) {
      if (length) {
        $btnRedo.removeClass('disabled');
      } else {
        $btnRedo.addClass('disabled');
      }
      resizeEditor();
    },
    objectScaled: function(obj) {
      if (obj.type === 'text') {
        $inputFontSizeRange.val(obj.fontSize);
      }
    },
    addText: function(pos) {
      imageEditor.addText('Double Click', {
        position: pos.originPosition,
        styles: {
          fontSize: '150',
          fill: selected_color
         }
      }).then(function (objectProps) {

      });
    },
    objectActivated: function(obj) {
      activeObjectId = obj.id;
      if (obj.type === 'rect' || obj.type === 'circle') {
        setShapeToolbar(obj);
        activateShapeMode();
      } else if (obj.type === 'icon') {
        setIconToolbar(obj);
        activateIconMode();
      } else if (obj.type === 'text') {
        setTextToolbar(obj);
        activateTextMode();
      }
    },
    textEditing: function() {
      var position = imageEditor.getObjectPosition(activeObjectId, 'left', 'top');

    },
    mousedown: function(event, originPointer) {
      if ($imageFilterSubMenu.is(':visible') && imageEditor.hasFilter('colorFilter')) {
        imageEditor.applyFilter('colorFilter', {
          x: parseInt(originPointer.x, 10),
          y: parseInt(originPointer.y, 10)
        });
      }
    }
  });
}

function selector_fn() {
  instanceBrush.on('selectColor', function(event) {
    selected_color = event.color;
    imageEditor.setBrush({
      color: hexToRGBa(selected_color, 1.0)
    });
    setTimeout(function(){
      $selectedTool.addClass("active");
    }, 200);
  });

  // IE9 Unselectable
  $('.menu').on('selectstart', function() {
      return false;
  });
}

function button_events() {
  $("#back-to-archives").on('click', function(){
    if (window.location.href.indexOf("live") > -1) {
      $(".nav-tab-live").tab('show');
      handleLiveViewMenuWidth()
    }
    else if (window.location.href.indexOf("recordings") > -1)
    {
      $(".nav-tab-recordings").tab('show');
    }
    else if (window.location.href.indexOf("archives") > -1) {
      $(".nav-tab-archives").tab('show');
    }
    else {
      $(".nav-tab-live").tab('show');
      handleLiveViewMenuWidth();
    }
  });

  $btnSelection.on('click', function(){
    activateSelectionMode();
    $selectedTool = $btnSelection;
  });

  // Attach button click event listeners
  $btns.on('click', function() {
    if (!$(this).hasClass("blur-item")) {
      $btnsActivatable.removeClass('active');
    }
  });

  $btnsActivatable.on('click', function() {
    $(this).addClass('active');
  });

  $("#crop-image").on("click", function(){
    imageEditor.startDrawingMode('CROPPER');
    $cropSubMenu.show();
    $selectedTool = $("#crop-image");
  });

  $btnApplyCrop.on('click', function() {
    imageEditor.crop(imageEditor.getCropzoneRect()).then(function () {
      imageEditor.stopDrawingMode();
      $cropSubMenu.hide();
    });
  });

  $btnCancelCrop.on('click', function() {
    imageEditor.stopDrawingMode();
    $cropSubMenu.hide();
  })

  $btnUndo.on('click', function() {
    if (!$(this).hasClass('disabled')) {
      imageEditor.undo();
    }
  });

  $btnRedo.on('click', function() {
    if (!$(this).hasClass('disabled')) {
        imageEditor.redo();
    }
  });

  $btnClearObjects.on('click', function() {
    imageEditor.clearObjects();
    // $("#tab_image_editor").removeClass("hide")
    if(method === "PATCH") {
      delete_edited_image();
    } else {
      $(".nav-tab-archives").tab('show');
    }

  });

  $btnClose.on('click', function() {
    imageEditor.stopDrawingMode();
  });

  $inputBrushWidthRange.on('change', function() {
    imageEditor.setBrush({width: 8});//parseInt(this.value, 10)}
  });

  $inputImage.on('change', function(event) {
    var file;

    if (!supportingFileAPI) {
        alert('This browser does not support file-api');
    }

    file = event.target.files[0];
    imageEditor.loadImageFromFile(file).then(function (result) {

        imageEditor.clearUndoStack();
    });
  });

  $btnDownload.on('click', function() {
    archive_title = archive_timestamp.format("YYYY-MM-DDTHH:mm:ss.SSS") + "Z";
    var imageName = Evercam.Camera.id + "-" + archive_title;
    var dataURL = imageEditor.toDataURL();
    var blob, type, w;
    reset_canvas_size();
    if (Intercom_script) {
      Intercom('trackEvent', 'download-edit-image');
    }
    if (supportingFileAPI) {
        blob = base64ToBlob(dataURL);
        type = blob.type.split('/')[1];
        imageName += '.' + type;

        // Library: FileSaver - saveAs
        saveAs(blob, imageName);
    } else {
        alert('This browser needs a file-server');
        w = window.open();
        w.document.body.innerHTML = '<img src=' + dataURL + '>';
    }
  });

  // control draw line mode
  $btnDrawLinestraight.on('click', function() {
    imageEditor.stopDrawingMode();

    var settings = getBrushSettings();
    imageEditor.stopDrawingMode();
    imageEditor.startDrawingMode('LINE_DRAWING', settings);
    $selectedTool = $btnDrawLinestraight;
  });

  $btnDrawLinefree.on('click', function() {
    activate_free_line_mode();
  });

  // control draw shape mode
  $btnDrawRect.on('click', function() {
    shapeOptions.stroke = selected_color;
    shapeOptions.fill = 'transparent';

    shapeOptions.strokeWidth = 10;//Number($inputStrokeWidthRange.val())
    imageEditor.setDrawingShape('rect', shapeOptions);
    activateShapeMode();
    $selectedTool = $btnDrawRect;
  });

  $btnDrawCircle.on('click', function() {
    shapeOptions.stroke = selected_color;
    shapeOptions.fill = 'transparent';
    shapeOptions.strokeWidth = 10;
    imageEditor.setDrawingShape('circle', shapeOptions);
    activateShapeMode();
    $selectedTool = $btnDrawCircle;
  });

  // control text mode
  $btnText.on('click', function() {
    activateTextMode();
    $selectedTool = $btnText;
  });

  $inputFontSizeRange.on('change', function() {
    imageEditor.changeTextStyle(activeObjectId, {
      fontSize: parseInt(this.value, 10)
    });
  });

  $btnAddIcon.on('click', function() {
    activateIconMode();
    //var element = event.target || event.srcElement;
    imageEditor.once('mousedown', function(e, originPointer) {
      imageEditor.addIcon('arrow', {
        left: originPointer.x,
        top: originPointer.y,
        fill: selected_color
      }).then(function (objectProps) {  });
    });
    $selectedTool = $btnAddIcon;
  });

}

function save_file() {
  $("#btn-save-edited-file").on("click", function() {
    if(saving_image) {
      return;
    }
    saving_image = true;
    var data, from, onError, onSuccess, settings;
    var imageData = imageEditor.toDataURL();
    reset_canvas_size();
    $(".bb-alert").removeClass("alert-danger").addClass("alert-info");
    NProgress.start();
    // $(".div-save-edit-image").show();

    data = {
      title: archive_title,
      type: "edit",
      content: imageData,
      file_extension: "png",
      requested_by: Evercam.User.username,
      api_id: Evercam.User.api_id,
      api_key: Evercam.User.api_key
    };

    if (method === "POST") {
      archive_title = archive_timestamp.format("YYYY-MM-DDTHH:mm:ss.SSS") + "Z";
      data.from_date = toISOString(archive_timestamp);
      data.to_date = toISOString(archive_timestamp);
    }

    onError = function(jqXHR, status, error) {
      saving_image = false;
      if (jqXHR.status === 500) {
        Notification.show("Internal Server Error. Please contact to admin.");
      } else {
        Notification.show(jqXHR.responseJSON.message);
      }
      $(".bb-alert").removeClass("alert-info").addClass("alert-danger");
      $(".div-save-edit-image").hide();
      NProgress.done();
    };

    onSuccess = function(result, status, jqXHR) {
      saving_image = false;
      archive_id = result.archives[0].id;
      archive_title = result.archives[0].title;
      var newTime = moment.tz(result.archives[0].created_at, Evercam.Camera.timezone);
      $(".image-edit-date").show();
      $(".image-edit-date").text("Created at " + newTime.format('MMMM Do YYYY, HH:mm:ss'));
      $(".bb-alert").removeClass("alert-danger").addClass("alert-info");
      Notification.show("Image saved and you can check in archives.");
      $(".div-save-edit-image").hide();
      method = "PATCH";
      NProgress.done();
      resizeEditor();
    };

    var query_string = "";
    if(method === "PATCH") {
      query_string = "/" + archive_id;
    }

    settings = {
      cache: false,
      data: data,
      dataType: 'json',
      error: onError,
      success: onSuccess,
      type: method,
      url: Evercam.API_URL + "cameras/" + Evercam.Camera.id + "/archives" + query_string
    };

    $.ajax(settings);
    setTimeout(function(){
      $(".div-save-edit-image").hide();
      NProgress.done();
    }, 1000);
  });
}

function delete_edited_image() {
  NProgress.start();

  var onError = function(jqXHR, status, error) {
    Notification.show(jqXHR.responseJSON.message);
    $(".bb-alert").removeClass("alert-info").addClass("alert-danger");
    NProgress.done();
  }

  var onSuccess = function(data, status, jqXHR) {
    NProgress.done();
    $(".nav-tab-archives").tab('show');
    Notification.show("Archive deleted successfully.");
  }

  var settings = {
    cache: false,
    data: {},
    dataType: 'json',
    error: onError,
    success: onSuccess,
    type: 'DELETE',
    url: Evercam.API_URL + "cameras/" + Evercam.Camera.id + "/archives/" + archive_id + "?api_id=" + Evercam.User.api_id + "&api_key=" + Evercam.User.api_key
  }
  $.ajax(settings);
}

function load_editor_image() {
  $("#edit-recording-image").on("click", function() {
    loading_image($("#imgPlayback"));
    track_intercom_edit_image_event()
  });

  $(".edit-live-image").on("click", function() {
    remove_classes_from_live();
    track_intercom_edit_image_event()
    loading_image($("#live-player-image"));
  });

  $(".edit-offline-image").on("click", function() {
    remove_classes_from_live();
    track_intercom_edit_image_event()
    loading_image($("#imgPlayback"));
  });
}

function track_intercom_edit_image_event () {
  if (Intercom_script) {
    Intercom('trackEvent', 'edit-image');
  }
}

function remove_classes_from_live() {
  $('.center-tabs').width('100%');
  $('#ul-nav-tab').removeClass('nav-menu-text');
  $('.center-tabs').removeClass('center-tabs-live');
  $('#read-only-sharing-tab').removeClass('read-only-sharing-tab');
  $('.delete-share-icon').removeClass('colour-white');
}

var handleLiveViewMenuWidth = function() {
  var content_width, live_view_menu_width, side_bar_width;
  if ($(window).width() >= 992) {
    content_width = Metronic.getViewPort().width;
    side_bar_width = $(".page-sidebar").width();
    live_view_menu_width = content_width - side_bar_width;
    $('.center-tabs').addClass('center-tabs-live');
    $('#ul-nav-tab').addClass('nav-menu-text');
    $('#read-only-sharing-tab').addClass('read-only-sharing-tab');
    $('.delete-share-icon').addClass('colour-white');
    return $('.center-tabs').width(live_view_menu_width);
  } else {
    $('.center-tabs').width('100%');
    $('.center-tabs').removeClass('center-tabs-live');
    $('#read-only-sharing-tab').removeClass('read-only-sharing-tab');
    $('.delete-share-icon').removeClass('colour-white');
    return $('#ul-nav-tab').removeClass('nav-menu-text');
  }
};

function loading_image($control) {
  $(".image-edit-autor").html("Requested by: " + Evercam.User.fullname + "</br>");
  method = "POST";
  var image_timestamp = $control.attr("data-timestamp");
  var image_data = $control.attr("src");
  archive_timestamp = moment.tz(image_timestamp, Evercam.Camera.timezone);
  archive_title = archive_timestamp.format("YYYY-MM-DDTHH:mm:ss.SSS") + "Z";
  $(".image-edit-cr-date").html("Cloud Recording: " + archive_timestamp.format("MM/DD/YYYY HH:mm:ss") + "</br>");
  $(".image-edit-date").hide();
  $("#edit-image-title").text(archive_title);
  imageEditor.loadImageFromURL(image_data, archive_title).then(function (sizeValue) {
    imageEditor.clearUndoStack();
  });
  $("#tab_image_editor").removeClass("hide");
  $(".nav-tab-image-editor").tab('show');
}

function model_events() {
  $('.nav-tab-image-editor').on('shown.bs.tab', function(){
    activate_free_line_mode();
  });

  $('.nav-tab-image-editor').on('hide.bs.tab', function(){
    archive_id = "";
    archive_title = "";
  });
}

function reset_control(type) {
  switch (type) {
    case 'CROPPER':
      break;
    case 'TEXT':
      break;
    case 'FREE_DRAWING':
      setTimeout(activateSelectionMode, 500);
      break;
    default:
      activateSelectionMode();
  }
}

function resize_event() {
  $(window).resize(function() {
    resizeEditor();
  });
}

function edit_image() {
  $("#archives-table").on("click", ".archive-image-edit", function() {
    archive_id = $(this).attr("data-id");
    archive_title = $(this).attr("data-title");
    archive_timestamp = moment.utc($(this).attr('data-from'), "MM/DD/YYYY, HH:mm:ss")
    $("#edit-image-title").text(archive_title);
    var media_time = $(this).attr('data-time');
    var newTime = moment.tz(media_time, Evercam.Camera.timezone);

    $(".image-edit-autor").html("Requested by: " + $(this).attr('data-autor') + "</br>");
    $(".image-edit-cr-date").html("Cloud Recording: " + $(this).attr('data-from') + "</br>");
    $(".image-edit-date").text("Created at " + moment(newTime).format('MMMM Do YYYY, HH:mm:ss'));
    var url = $(this).attr("data-url");
    method = "PATCH";
    show_canvas(false);

    imageEditor.loadImageFromURL(url, archive_title).then(function (sizeValue) {
      imageEditor.clearUndoStack();
      show_canvas(true);
    });
    $("#tab_image_editor").removeClass("hide");
    $(".nav-tab-image-editor").tab('show');
    resizeEditor();
    track_intercom_edit_image_event()
  });
}

function show_canvas(mode) {
  if(mode) {
    $(".lower-canvas").show();
    $(".upper-canvas").show();
  } else {
    $(".lower-canvas").hide();
    $(".upper-canvas").hide();
  }
}

function update_image_title() {
  $("#change-archive-title").on("click", function(){
    var title = $("#edit-image-title").text();
    $("#edit-image-title").replaceWith('<input name="test" id="edit-image-title" type="text" value="'+title+'">');
    $("#editor-update-title").show();
    $("#editor-cancel-title").show();
    $("#change-archive-title").hide();
    $("#edit-image-title").css("width", "50%");
    $("#edit-image-title").css("font-size", "22px");
    $("#editor-update-title i").css("font-size", "17px");
    $("#editor-cancel-title i").css("font-size", "17px");
  });

  $("#editor-update-title").on("click", function(){
    var title = $("#edit-image-title").val();
    archive_title = title;
    $("#edit-image-title").replaceWith('<strong id="edit-image-title">'+title+'</strong>');
    $("#editor-update-title").hide();
    $("#editor-cancel-title").hide();
    $("#change-archive-title").show();
    $("#change-archive-title i").css("font-size", "17px");
  });

  $("#editor-cancel-title").on("click", function(){
    var title = $("#edit-image-title").val();
    $("#edit-image-title").replaceWith('<strong id="edit-image-title">'+archive_title+'</strong>');
    $("#editor-update-title").hide();
    $("#editor-cancel-title").hide();
    $("#change-archive-title").show();
    $("#change-archive-title i").css("font-size", "17px");
  });
}

function initPopupDelete() {
  $("#popup-delete-edit-view").popbox({
    open: "#open-delete-edit-view",
    box: "#box-delete-edit-view",
    arrow: "#arrow-delete-edit-view",
    arrow_border: "#arrow-border-delete-edit-view",
    close: "#closepopup-delete-edit-view",
  });
}

function initEditorTool(){
  set_variables();
  initImageEditor();
  initColorPicker();
  image_editor_fn();
  selector_fn();
  $drawLineSubMenu.show();
  button_events();
  model_events();
  save_file();
  resize_event();
  edit_image();
  load_editor_image();
  update_image_title();
  initPopupDelete();
}
