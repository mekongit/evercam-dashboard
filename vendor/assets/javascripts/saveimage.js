/**
 * Created by evercam on 4/6/15.
 */
var SaveImage = (function() {
  "use strict";

  var that = {};

  that.init = function() {

  };


  function isNativeApp(){
      return /io.evercam.androidapp\/[0-9\.]+$/.test(navigator.userAgent);
  }

  that.save = function (fileURL, fileName) {
    // for non-IE
    if (!window.ActiveXObject) {
        var save = document.createElement('a');
        save.href = fileURL;
        save.target = '_blank';
        if (!isNativeApp()) {
            save.download = fileName || 'unknown';
        }
        var event = document.createEvent("MouseEvents");
        event.initMouseEvent("click", true, false, window, 0, 0, 0, 0, 0,
          false, false, false, false, 0, null);
        save.dispatchEvent(event);
    }
    // for IE
    else if (!!window.ActiveXObject && document.execCommand) {
        var _window = window.open(fileURL, '_blank');
        _window.document.close();
        _window.document.execCommand('SaveAs', true, fileName || fileURL);
        _window.close();
    }
};
return that;
}());