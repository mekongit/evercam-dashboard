/**
 * util.js
 * @author Azhar Malik. Evercam Development Team <support@evercam.io>
 * @everc
 */
'use strict';

function sendAJAXRequest(settings) {
  var headers, token;
  token = $('meta[name="csrf-token"]');
  if (token.size() > 0) {
    headers = {
      "X-CSRF-Token": token.attr("content")
    };
    settings.headers = headers;
  }
  return $.ajax(settings);
}

function base64ToBlob(data) {
  var mimeString = '';
  var raw, uInt8Array, i, rawLength;

  raw = data.replace(rImageType, function(header, imageType) {
    mimeString = imageType;

    return '';
  });

  raw = atob(raw);
  rawLength = raw.length;
  uInt8Array = new Uint8Array(rawLength);

  for (i = 0; i < rawLength; i += 1) {
    uInt8Array[i] = raw.charCodeAt(i);
  }

  return new Blob([uInt8Array], {type: mimeString});
}

function copyToClipboard(element) {
  var clipboard = new ClipboardJS(element);
  return clipboard.on('success', function(e) {
    Notification.info('Copied!');
  });
}

function toISOString(datetime) {
  return datetime.format("YYYY-MM-DDTHH:mm:ss.SSSZ"); // "2014-09-08T08:02:17-05:00"
}
