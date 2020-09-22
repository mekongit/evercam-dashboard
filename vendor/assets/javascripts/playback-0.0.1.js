/*!
 * Playback JavaScript v0.0.1
 * https://www.evercam.io/
 *
 * Copyright 2014 Evercam.io
 * Released
 *
 * Date: 2014-08-04
 */
(function (window) {

    Playback = {
        options: {
            playbackUrl: 'https://playback.azurewebsites.net/Recording.html',
            cameraId: "",
            token: "",
            api_id: "",
            api_key: ""
        },

        Load: function () {
            var jQuery;
            var params = this.options;

            var scriptLoadHandler = function () {
                // Restore $ and window.jQuery to their previous values and store the
                // new jQuery in our local jQuery variable
                jQuery = window.jQuery.noConflict(true);
                // Call our main function
                initPlayback();
            }

            var initPlayback = function () {
                iframe =
                jQuery("<iframe />")
                .css({ "overflow-y": "hidden", "overflow-x": "scroll", "width": "100%", "height": "715px" })
                .attr({ "src": params.playbackUrl + '?id=' + params.cameraId + '&token=' + params.token + '&api_id=' + params.api_id + '&api_key=' + params.api_key, "frameborder": "0" })
                .appendTo("div[evercam='playback']");
            };

            if (window.jQuery === undefined) {
                var script_tag = document.createElement('script');
                script_tag.setAttribute("type", "text/javascript");
                script_tag.setAttribute("src",
                  "https://code.jquery.com/jquery-2.1.1.min.js");

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
                initPlayback();
            }

        }
    };

}(window));
