
var $buoop = { vs: { i: 9, f: 35, o: -8, s: 7, c: 40}, reminder: 1,
  reminderClosed: 2 };
function $buo_f() {
  var e = document.createElement("script");
  e.src = "https://browser-update.org/update.min.js";
  document.body.appendChild(e);
}
try { document.addEventListener("DOMContentLoaded", $buo_f, false) }
catch(e) { window.attachEvent("onload", $buo_f) }
