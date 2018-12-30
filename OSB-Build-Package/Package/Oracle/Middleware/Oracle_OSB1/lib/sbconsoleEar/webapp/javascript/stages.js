

/**
 * Global variable within the page which contains the id of a visible
 * window. This will help prevent multiple windows showing up later.
 * Hide and ShowMenu methods coordinate setting and unsetting this.
 */
var xbusMenuVisible = null;


/**
 * Simple method which toggles the show/hide details icon on window popups.
 */
function tsd(id)
{
    var node = document.getElementById(id);
    var e = document.getElementById(id + "E");

    if (e != null)
        e.style.display="none";

    if (node != null)
    {
        if (node.style.display == "none" || node.style.display == "")
        {
            node.style.display="block";
            document["stageMaximize" + id].src = "/sbconsole/images/sb/minimize.gif";
        }
        else
        {
            node.style.display="none";
            document["stageMaximize" + id].src = "/sbconsole/images/sb/maximize.gif";
        }
    }
}


/**
 * Displays a JavaScript window at the current location. Typically
 * used for displaying a popup menu on the page.
 */
function showMenu(id)
{
    if (xbusMenuVisible != null)
        hideMenu(xbusMenuVisible);

    var node = document.getElementById(id);
    if (node != null)
    {
        node.style.posTop=event.clientY;
        node.style.posLeft=event.clientX;
        node.style.visibility="visible";

        xbusMenuVisible = id;
    }
}


/**
 * Hides the popup window with the specified id.
 */
function hideMenu(id)
{
    var node = document.getElementById(id);
    if (node != null)
        node.style.visibility="hidden";

    xbusMenuVisible = null;
}


/**
 * Sets the cursor for the element with the specified id.
 * id: the id of the element for which the cursor is to be set
 * cType: a string representing the cursor style, "pointer", "default" etc.
 */
function setCursor(id, cType)
{
    var node = document.getElementById(id);
    if (node != null)
        node.style.cursor = cType;
}

/*
   This function sets X and Y position for Menu
   Example :   setMenuPosition('menu_id', event)
*/
function setMenuPosition(menuElement, e) {
    // get window location
    var winLocation = getWindowLocation();
    var x = e.pageX? e.pageX: e.clientX + winLocation[2];    // scrollX
    var y = e.pageY? e.pageY: e.clientY + winLocation[3];    // scrollY

    if ( x + menuElement.offsetWidth > winLocation[0] + winLocation[2] ){
        x = x - menuElement.offsetWidth ;
    } else {
        x = x + X_OFFSET;
    }

    if ( y + menuElement.offsetHeight > winLocation[1] + winLocation[3] ) {
        y = ( y - menuElement.offsetHeight > winLocation[3] )? y - menuElement.offsetHeight : winLocation[1] + winLocation[3] - menuElement.offsetHeight;
    } else {
        y = y + Y_OFFSET;
    }
    // Set x and y position
    menuElement.style.left = x + "px";
    menuElement.style.top = y + "px";
}

/*
This function determines windows location
*/
function getWindowLocation(){

    var width   = 0;  // Array index 0 - Window width
    var height  = 0;  // Array index 1 - Window height
    var scrollX = 0;  // Array index 2 - Scroll X
    var scrollY = 0;  // Array index 3 - Scroll Y

    // To determine the window width
    if (window.innerWidth) {
        //Non-IE
        width = window.innerWidth - 18;
    } else if (document.documentElement && document.documentElement.clientWidth){
        //IE 6+ in 'standards compliant mode'
  		width = document.documentElement.clientWidth;
    } else if (document.body && document.body.clientWidth){
        //IE 4 compatible
  		width = document.body.clientWidth;
    }

    // To determine the window height
    if (window.innerHeight) {
        height = window.innerHeight - 18;
  	} else if (document.documentElement && document.documentElement.clientHeight){
  		height = document.documentElement.clientHeight;
  	} else if (document.body && document.body.clientHeight){
  		height = document.body.clientHeight;
    }

    // To determine  how far the window has been scrolled in X direction
  	if (typeof window.pageXOffset == "number") {
        //Netscape compliant
  	    scrollX = window.pageXOffset;
  	} else if (document.documentElement && document.documentElement.scrollLeft){
  	    //IE6 standards compliant mode
  		scrollX = document.documentElement.scrollLeft;
  	} else if (document.body && document.body.scrollLeft){
  	    //DOM compliant
  		scrollX = document.body.scrollLeft;
  	} else if (window.scrollX) {
  	    scrollX = window.scrollX;
  	}

    // To determine  how far the window has been scrolled in Y direction
    if (typeof window.pageYOffset == "number") {
        scrollY = window.pageYOffset;
    } else if (document.documentElement && document.documentElement.scrollTop){
  		scrollY = document.documentElement.scrollTop;
  	} else if (document.body && document.body.scrollTop){
  		scrollY = document.body.scrollTop;
  	} else if (window.scrollY) {
  	    scrollY = window.scrollY;
    }

    return [width, height, scrollX, scrollY];
}




