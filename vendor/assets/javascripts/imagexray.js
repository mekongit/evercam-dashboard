function imageComp(imgID, img2Path) {
  var img, img2, lens, result, cx, cy, clicked = 0,resizeFlag=1;
  img = document.getElementById(imgID);
  //result = document.getElementById(resultID);
  /*create lens:*/
  lens = document.createElement("DIV");
  lens.setAttribute("class", "img-comp-lens");
  span_main_div = document.createElement("div");
  span_child_div = document.createElement("span");
  span_main_div.setAttribute("class", "span-main-div");
  span_main_div.setAttribute("id", "xray-calendar");
  span_child_div.setAttribute("class", "date-value");
  icon_div = document.createElement("i");
  icon_div.setAttribute("class", "fas fa-chevron-right xray-inner-icon");
  icon_div2 = document.createElement("i");
  icon_div2.setAttribute("class", "fas fa-calendar-alt xray-inner-icon2");
  lens.appendChild(span_main_div);
  lens.appendChild(icon_div);
  span_main_div.appendChild(icon_div2);
  span_main_div.appendChild(span_child_div);
  /*insert lens:*/
  img.parentElement.insertBefore(lens, img);

  cx = 1;//result.offsetWidth / lens.offsetWidth;
  cy = 1;//result.offsetHeight / lens.offsetHeight;

  lens.style.backgroundImage = "url('" + img2Path + "')";
  lens.style.backgroundSize = (img.width * cx) + "px " + (img.height * cy) + "px";
  var z = img.getBoundingClientRect();
  var lense = lens.getBoundingClientRect();
  var left = (z.width - lense.width)/2;
  var top = (z.height - lense.height)/2;


  lens.style.left = left + "px";
  lens.style.top = top + "px";
  lens.style.backgroundPosition = "-" + (left * cx) + "px -" + (top * cy) + "px";


  function touchDown() {
    //debugger;
    clicked = 1;
  }
  function touchUp() {
    // debugger;
    clicked = 0;
  }

  function mouseDown() {
    // debugger;
    clicked = 1;
  }
  function mouseUp() {
    clicked = 0;
  }
  $( ".img-comp-lens" ).on( "resizestart", function( event, ui ) {
    // debugger;
    resizeFlag = 0;
  } );
  $( ".img-comp-lens" ).on( "resizestop", function( event, ui ) {
    // debugger;
    resizeFlag = 1;
  } );

  lens.addEventListener("mousemove", moveLens);
  img.addEventListener("mousemove", moveLens);

  lens.addEventListener("touchmove", moveLens);
  img.addEventListener("touchmove", moveLens);

  lens.addEventListener("mousedown", mouseDown);
  img.addEventListener("mousedown", mouseDown);

  lens.addEventListener("mouseup", mouseUp);
  img.addEventListener("mouseup", mouseUp);

  lens.addEventListener("touchstart", touchDown);
  img.addEventListener("touchstart", touchDown);

  lens.addEventListener("touchend", touchUp);
  img.addEventListener("touchend", touchUp);

  lens.addEventListener("touchmove", moveLens);
  img.addEventListener("touchmove", moveLens);
	

  function moveLens(e) {  
    var pos, x, y;

    e.preventDefault();

    pos = getCursorPos(e);

    //var l = lens.getBoundingClientRect();

    x = pos.x - (lens.offsetWidth / 2);
    y = pos.y - (lens.offsetHeight / 2);

    if (x > img.width - lens.offsetWidth) { x = img.width - lens.offsetWidth; }
    if (x < 0) { x = 0; }
    if (y > img.height - lens.offsetHeight) { y = img.height - lens.offsetHeight; }
    if (y < 0) { y = 0; }

    var l = lens.getBoundingClientRect();
    
    var mouseBmax = parseInt(pos.mouseBottom) + 50;
    var mouseBmin = parseInt(pos.mouseBottom) - 50;
    var mouseRmax = parseInt(pos.mouseRight) + 50;
    var mouseRmin = parseInt(pos.mouseRight) - 50;
    if (parseInt(pos.lensBottom) <= mouseBmax && parseInt(pos.lensBottom) >= mouseBmin) {
      return false;
    } else if (parseInt(pos.lensRight) <= mouseRmax && parseInt(pos.lensRight) >= mouseRmin) {
      return false;
    }
    else if (parseInt(l.top) <= mouseBmax && parseInt(l.top) >= mouseBmin) {
      lens.style.backgroundPosition = "-" + (pos.lensLeft) + "px -" + (pos.lensTop) + "px";
      return false;
    } else if (parseInt(l.left) <= mouseRmax && parseInt(l.left) >= mouseRmin) {
      lens.style.backgroundPosition = "-" + (pos.lensLeft) + "px -" + (pos.lensTop) + "px";
      return false;
    }
    if(clicked==1){
    if(resizeFlag==1){
    lens.style.left = x + "px";
    lens.style.top = y + "px";
    lens.style.backgroundPosition = "-" + (x * cx) + "px -" + (y * cy) + "px";}}
  }
  function getCursorPos(e) {
    var a, b, x = 0, y = 0;
    var lensRight, lensBottom,lensLeft, lensTop, mouseRight, mouseBottom,
      e = e || window.event;

    a = img.getBoundingClientRect();
    b = lens.getBoundingClientRect();
    lensRight = b.right;
    lensBottom = b.bottom;
    lensLeft = b.left - a.left;
    lensTop = b.top - a.top;

    if (e.touches != null) {
      x = e.touches[0].pageX;
      y = e.touches[0].pageY;
      mouseRight = e.touches[0].clientX;
      mouseBottom = e.touches[0].clientY;
    } else {
      x = e.pageX - a.left;
      y = e.pageY - a.top;

      mouseRight = e.clientX;
      mouseBottom = e.clientY;
    }

    x = x - window.pageXOffset;
    y = y - window.pageYOffset;
    return { x: x, y: y, lensRight: lensRight, lensBottom: lensBottom, mouseRight: mouseRight, mouseBottom: mouseBottom,lensLeft:lensLeft,lensTop:lensTop };
  }
}