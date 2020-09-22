/**
 * Created by azhar on 10/05/17.
 */
var jQuery;
var $;
(function(window) {

  "use strict";
  // Localize jQuery variable

  var camera_id, before, after, mode;

  /******** Our main function ********/
  function main() {
    jQuery(document).ready(function ($) {
      addVideojsReffrences();
      var bucket_url = "https://s3-eu-west-1.amazonaws.com/evercam-camera-assets/";
      var params = document.body.getElementsByTagName('script');
      var query = params[0].classList;
      camera_id = query[0];
      before = query[1];
      after = query[2];

      if (query.length == 5) {
        mode = query[4];
        var compare_exid = query[3];
      } else {
        mode = query[3];
      }

      if (mode == undefined || mode == "") {
        mode = "drag";
      }

      var html = '<div id="image-compare" class="js-img-compare embed">';
      html += '     <div style="display: none;">';
      html += '       <span id="calendar-before" class="images-compare-label"><i class="fas fa-calendar-alt compare-calendar"></i> Before</span>';
      html += '       <img id="compare_before" src="" alt="Before"/>';
      html += '     </div>';
      html += '     <div>';
      html += '       <span id="calendar-after" class="images-compare-label"><i class="fas fa-calendar-alt compare-calendar"></i> After</span>';
      html += '       <img id="compare_after" src="" alt="After"/>';
      html += '     </div>';
      html += '     <div class="evercam-brand">';
      html += '       <img src="https://dash.evercam.io/assets/evercam-logo-white.png" class="svg-logo" alt="Evercam.io" />';
      html += '     </div>';
      html += '   </div>';

      document.getElementById("evercam-compare").innerHTML = html;
      if (query.length == 5) {
        $("#compare_after").attr("src", bucket_url+camera_id+"/compares/"+compare_exid+"/end-"+after+".jpg");
        $("#compare_before").attr("src", bucket_url+camera_id+"/compares/"+compare_exid+"/start-"+before+".jpg");
      } else {
        $("#compare_after").attr("src", bucket_url+camera_id+"/snapshots/"+after+".jpg");
        $("#compare_before").attr("src", bucket_url+camera_id+"/snapshots/"+before+".jpg");
      }
      setTimeout(function() { initCompare(mode) }, 2000);
    });
  }

  function initCompare (mode) {
    var imagesCompareElement = $('.js-img-compare').imagesCompare({interactionMode: mode});
    var imagesCompare = imagesCompareElement.data('imagesCompare');
  }

  function getFirstLastImages(image_id, query_string, reload) {
    var data, onError, onSuccess, settings;
    /*data = {
      api_id: Evercam.User.api_id,
      api_key: Evercam.User.api_key
    };*/
    onError = function(jqXHR, status, error) {
      return false;
    };
    onSuccess = function(response, status, jqXHR) {
      var snapshot = response
      if (query_string.indexOf("nearest") > 0 && response.snapshots.length > 0) {
        snapshot = response.snapshots[0]
      }
      if (snapshot.data !== undefined)
      {
        $("#" + image_id).attr("src", snapshot.data);
        if (reload) {
          return initCompare("drag");
        }
      }
    };
    settings = {
      cache: false,
      data: {},
      dataType: 'json',
      error: onError,
      success: onSuccess,
      type: 'GET',
      url: "https://media.evercam.io/v2/cameras/" + camera_id + "/recordings/snapshots" + query_string
    };
    return $.ajax(settings);
  };

  /******** Add videojs *****************/
  function addVideojsReffrences() {
    var videojs_tag = document.createElement('script');
    videojs_tag.setAttribute("type","text/javascript");
    videojs_tag.setAttribute("src", "https://dash.evercam.io/assets/hammer.min.js");
    (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(videojs_tag);

    var videojs_hls_tag = document.createElement('script');
    videojs_hls_tag.setAttribute("type","text/javascript");
    videojs_hls_tag.setAttribute("src", "https://dash.evercam.io/assets/jquery.images-compare.js");
    (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(videojs_hls_tag);

    var style = "<style>";
    style += ".images-compare-container { display: inline-block;position: relative;overflow: hidden;} .images-compare-before { will-change: clip;position: absolute;top: 0;left: 0;z-index: 2;pointer-events: none;overflow: hidden; }";
    style += ".images-compare-after { pointer-events: none; } .images-compare-before img, .images-compare-after img { max-width: 100%;height: auto;display: block; } .images-compare-separator { position: absolute;background: white;height: 100%;width: 1px;z-index: 4;left: 0;top: 0;}";
    style += ".images-compare-handle { height: 38px;width: 38px;position: absolute;left: 50%;top: 50%;margin-left: -22px;margin-top: -22px;border: 3px solid white; -webkit-border-radius: 1000px; -moz-border-radius: 1000px;border-radius: 1000px;z-index: 6;cursor: pointer; }";
    style += ".images-compare-left-arrow, .images-compare-right-arrow { width: 0;height: 0;border: 6px inset transparent;position: absolute;top: 50%;margin-top: -6px; }";
    style += ".images-compare-left-arrow { border-right: 6px solid white;left: 50%;margin-left: -17px; } .images-compare-right-arrow { border-left: 6px solid white;right: 50%;margin-right: -17px; }";
    style += ".images-compare-label { font-family: sans-serif;text-transform: uppercase;font-weight: bold;position: absolute;top: 10px;left: 10px;z-index: 1;color: rgb(0, 0, 0);color: rgba(0, 0, 0, 0.4);background: rgb(255, 255, 255);background: rgba(255, 255, 255, 0.7);padding: 10px;border-radius: 5px;pointer-events: auto;cursor: pointer;display: none; }";
    style += ".images-compare-container .images-compare-label { display: inherit; } .images-compare-before .images-compare-label { left: 10px; } .images-compare-after .images-compare-label { left: auto;right: 10px; }";
    style += ".evercam-brand { bottom: 5px;display: table;height: 14px;line-height: 14px;padding: 1px 4px 1px 5px;position: absolute;text-decoration: none;z-index: 10; right: 0; text-align: right; } .evercam-brand img.svg-logo { height: auto; width: 65%; margin-left: 3px; }"
    style += "</style>";
    jQuery('head').append(style);
  }

  /******** Called once jQuery has loaded ******/
  function scriptLoadHandler() {
    // Restore $ and window.jQuery to their previous values and store the
    // new jQuery in our local jQuery variable
    jQuery = window.jQuery.noConflict(true);
    $ = jQuery;
    // Call our main function
    main();
  }

  /******** Load jQuery if not present *********/
  if (window.jQuery === undefined || window.jQuery.fn.jquery !== '2.1.3') {
    var script_tag = document.createElement('script');
    script_tag.setAttribute("type","text/javascript");
    script_tag.setAttribute("src",
      "https://code.jquery.com/jquery-2.1.3.min.js");
    if (script_tag.readyState) {
      script_tag.onreadystatechange = function () { // For old versions of IE
        if (this.readyState === 'complete' || this.readyState === 'loaded') {
          scriptLoadHandler();
        }
      };
    } else {
      script_tag.onload = scriptLoadHandler;
    }
    // Try to find the head, otherwise default to the documentElement
    (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(script_tag);
  } else {
    // The jQuery version on the window is the one we want to use
    jQuery = window.jQuery;
    $ = jQuery;
    main();
  }

}(window));
