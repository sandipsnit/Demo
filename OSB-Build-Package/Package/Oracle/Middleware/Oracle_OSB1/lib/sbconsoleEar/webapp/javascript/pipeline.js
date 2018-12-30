
/**
 * The scripts here are intended to provide some form of drag and drop
 * of stage images within a pipeline. The basic idea is that all objects
 * within the page have a bounding rectangle of some sort, the dimensions
 * of which can be determined at runtime. It also assumes that a set of valid
 * targets (specified by the targets array variable) have been declared in
 * the hosting HTML page. These targets for the pipeline will be the arrow
 * images with the little circle. Since we are overwriting the default behaviour
 * of the onmousemove event we have to replicate it somehow. So as a source
 * image is dragged over the screen we repeatedly have to determine if this image
 * is intersecting the bounding rectangle of one of our targets. If so then we
 * take some action.
 *
 * I have not noticed any performance issues with this yet. However even with huge
 * pipelines with dozens of stages (arguably unlikely) I think we will still be ok.
 */

var dragObject, x, y;

var dragapproved = false
var selected = -1;

/**
 * Both of these values need to be set by the enclosing HTML.
 */
var targets = new Array();
var dropUrl = null;


/**
 * Determines if we are using NetScape
 */
function usingExplorer()
{
    return navigator.appName == "Microsoft Internet Explorer";
}


/**
 * Trivial function which determines if two rectangles overlap
 * each other. The two rectangles are specified by
 *  R1 = [(X1, Y1), (X2, Y2)] and
 *  R2 = [(X3, Y3), (X4, Y4)].
 * In this case R1 represents the boundary of a possible target object
 * in the page and R2 represents the boundary of the dragged object.
 */
function intersects(X1, Y1, X2, Y2, X3, Y3, X4, Y4)
{
    if ( (X1 <= X3 && X2 >= X3 || X1 <= X4 && X2 >= X4 || X1 >= X3 && X2 <= X4 || X1 <= X3 && X2 >= X4) &&
         (Y1 <= Y3 && Y2 >= Y3 || Y1 <= Y4 && Y2 >= Y4 || Y1 >= Y3 && Y2 <= Y4 || Y1 <= Y3 && Y2 >= Y4) )
    {
        return true;
    }
    else
        return false;
}


/**
 * Where the work is done. Important to keep this as simple as possible
 * otherwise performance will grind to a halt as the user will be able to
 * drag an image faster than the method can keep up.
 *
 * Basically what is happening here is that we iterate through a list of
 * possible target objects specified by the "targets" array. For each object
 * we calculate the bounding rectangle of the object and see if this rectangle
 * intersects with the bounding rectangle of the image being dragged. If so
 * then we effectively have a mouse over event and we can highlight the image
 * or record state. Works for both IE 6.0 and NetScape 7.1
 *
 * could probably refine this but for the moment there is no performance problems.
 */
function doDrag(evt)
{
    if (dragapproved)
    {
        for (i = 0; i < targets.length; i++)
        {
            var X1, Y1,
                X2, Y2,
                X3, Y3,
                X4, Y4;

            var node = targets[i];
            if (node != null)
            {
                X1 = node.offsetLeft;
                Y1 = node.offsetTop;

                if (document.all)
                {
                    dragObject.style.posLeft = temp1 + event.clientX - x;
                    dragObject.style.posTop = temp2 + event.clientY - y;

                    X2 = X1 + node.offsetWidth;
                    Y2 = Y1 + node.offsetHeight;

                    X3 = dragObject.style.posLeft;
                    Y3 = dragObject.style.posTop;

                    X4 = X3 + dragObject.offsetWidth;
                    Y4 = Y3 + dragObject.offsetHeight;
                }
                else
                {
                    dragObject.style.left = temp1 + (evt.clientX - x) + 'px';
                    dragObject.style.top =  temp2 + (evt.clientY - y) + 'px';

                    X2 = X1 + node.width;
                    Y2 = Y1 + node.height;

                    X3 = parseInt(dragObject.style.left);
                    Y3 = parseInt(dragObject.style.top);

                    X4 = X3 + dragObject.width;
                    Y4 = Y3 + dragObject.height;
                }

                if (intersects(X1, Y1, X2, Y2, X3, Y3, X4, Y4))
                {
                    imgIdOn(node.name, '/sbconsole/images/sb/stageSeparator');
                    selected = i;
                    return false;
                }
                else
                {
                    imgIdOff(node.name, '/sbconsole/images/sb/stageSeparator');
                    selected = -1;
                }
            }
        }

        return false;
    }
}


/**
 * The start Drag method. IE uses the global variable "event".
 * This method does some initial setup including setting the variable
 * dragObject which is actually an image representing the stage but which is hidden
 * underneath the user visible one.
 * It then sets the global onmousemove event handler to be doDrag().
 */
function startDrag(evt)
{
    if (document.all && event.srcElement.className == "draggable")
    {
        selected = -1;

        dragObject = document.getElementById(event.srcElement.id + "_hidden");
        dragObject.style.visibility = "visible";
        dragObject.style.display="block";

        dragObject.style.posLeft = event.srcElement.offsetLeft;
        dragObject.style.posTop = event.srcElement.offsetTop;

        temp1 = dragObject.style.posLeft;
        temp2 = dragObject.style.posTop;
        x = event.clientX;
        y = event.clientY;

        dragapproved = true;
        document.onmousemove = doDrag;
    }
}


/**
 * The start Drag method. It takes an event object which is
 * relevant only for NetScape and is automatically passed to it by
 * NetScape. IE uses the global variable "event". This method is
 * the same as above.
 */
function NSstartDrag(evt)
{
    if (evt.target.className == "draggable")
    {
        selected = -1;

        dragObject = document.getElementById(evt.target.id + "_hidden");
        dragObject.style.visibility = "visible";
        dragObject.style.display="block";

        dragObject.style.left = evt.target.offsetLeft + 'px';
        dragObject.style.top = evt.target.offsetTop + 'px';

        temp1 = evt.target.offsetLeft;
        temp2 = evt.target.offsetTop;
        x = evt.clientX;
        y = evt.clientY;

        dragapproved = true;
        document.onmousemove = doDrag;
    }
}


/**
 * Dragging has ended. So turn off any images that might have been
 * highligted and execute whatever action was requried. Hides the
 * object which had been dragged.
 */
function endDrag()
{
    dragapproved = false;

    for (i = 0; i < targets.length; i++)
    {
        if (targets[i] != null)
            imgIdOff(targets[i].name, '/sbconsole/images/sb/stageSeparator');
    }

    if (dragObject != null)
    {
        dragObject.style.visibility = "hidden";
        dragObject.style.display    = "none";

        if (selected > -1)
        {
            // the length of "_hidden" is 7 - hack, hmmm....
            i = dragObject.id;
            url = dropUrl + "&type=" + i.substring(0,  i.length - 7) + "&insertId=" + selected;

            // alert(url);
            window.location.href = url;
        }
    }
}

/**
 * Given the id of the hidden form for a particular stage this executes
 * the submit() method for the form.
 */
function editStage(id)
{
    var n = document.getElementById(id);
    if (n != null)
        n.submit();
}

/**
 * For Netscape.
 */
if (usingExplorer() == false)
    document.onmousedown = NSstartDrag;

// For mulitlevel menus

var X_OFFSET = 0;   // horizontal offset
var Y_OFFSET = 0;   // vertical offset
var ACTIVE_MAIN_MENU_ID;
var ACTIVE_SUB_MENU_ID;
var MAIN_MENU_CLICKED = false;
var SUB_MENU_CLICKED = false;

function showMainMenu(id, e) {
    hideMainMenu();
    var menuElement = document.getElementById? document.getElementById(id): null;
    if (!menuElement) return;
    ACTIVE_MAIN_MENU_ID = id;
    setMenuPosition(menuElement,e);
    menuElement.style.visibility="visible";
    MAIN_MENU_CLICKED = true;
}

function showSubMenu(id, e, index) {
    hideSubMenu();
    var menuElement = document.getElementById? document.getElementById(id): null;
    if (!menuElement) return;
    ACTIVE_SUB_MENU_ID = id;
    menuElement.style.left = 149+ "px";     // menu width is set as 150px in CSS
    menuElement.style.top = (20 * index) + "px";
    menuElement.style.visibility="visible";
    SUB_MENU_CLICKED = true;
}

function hideMainMenu(){
    if(ACTIVE_MAIN_MENU_ID){
       var menuElement = document.getElementById? document.getElementById(ACTIVE_MAIN_MENU_ID): null;
       hideMenu(menuElement);
    }
    hideSubMenu();
}

function hideAnySubMenu(hide){
    if(hide == 'true'){
        hideSubMenu();
    }
}

function hideSubMenu(){
    if(ACTIVE_SUB_MENU_ID){
       var menuElement = document.getElementById? document.getElementById(ACTIVE_SUB_MENU_ID): null;
       hideMenu(menuElement);
    }
}


function hideCascadeMenus(){
    if(ACTIVE_MAIN_MENU_ID && !MAIN_MENU_CLICKED){
       var menuElement = document.getElementById? document.getElementById(ACTIVE_MAIN_MENU_ID): null;
       hideMenu(menuElement);
    }
    hideSubMenu();
    MAIN_MENU_CLICKED = false;
}

function hideMenu(menuElement){
    menuElement.style.visibility="hidden";
}

