/**
 * Global Javascript variable to detect if the Variable palette is being accessed from XPATH or XQUERY
 */
var FROM_XPATH_BUILDER = false;
var IE = "Microsoft Internet Explorer";
var SAFARI = "";
var EVEN_ROW_BG_COLOR ="#FFFFFF";
var ODD_ROW_BG_COLOR = "#EAEAEA";
var ROW_SELECTED_HILITE_COLOR = "#FFFFA6";
var ROW_MOUSE_OVER_COLOR = "#FFFFCC";//"#FFC1FF";

var MODIFIED_ROW_CHECK_BOX_ARRAY = new Array();
/********************************************************************************
 *          Url handling
 *******************************************************************************/
function addUrlParameter(url, name, value) {
    if (url.indexOf("?") != -1) {
        url += "&";
    } else {
        url += "?";
    }
    return url + name + "=" + encodeURI(value);
}


/********************************************************************************
 *          DOM manipulation
 *******************************************************************************/

function DOM_createElement(name) {
    return document.createElement(name);
}

function DOM_addAttribute(node, name, value) {
    node.setAttribute(name, value);
}

function DOM_addText(node, text) {
    node.appendChild( document.createTextNode(text) );
}

function DOM_addChild(parent, child) {
    parent.appendChild(child);
}

function DOM_removeChildren(node) {
    while(node.hasChildNodes()) {
        node.removeChild(node.childNodes.item(0));
    }
}

function DOM_insertSiblingAfter(node, elem) {
    node.insertAdjacentElement("afterEnd", elem);
}

function DOM_clone(node) {
    return node.cloneNode();
}


/********************************************************************************
 *          Event Handling
 *******************************************************************************/
function fireEvent(url) {
    var frame = document.getElementById('eventTarget');
    frame.src = url;
}


/********************************************************************************
 *          Browser Utils
 *******************************************************************************/

/**
 * open a chooser
 */

function onOpenChooser(idName, id, url, formName, serverValue, paramSelectedValue, resName, resValue)
{
    var formObj = document.forms[formName];
    if(formObj){
        var ipElement = formObj.elements[id];
        if(!ipElement){
		    ipElement = document.getElementById(id);
	    }
        if(ipElement){
            var selectedValue = ipElement.value;
            if(selectedValue && trimSpaces(selectedValue) != "" ) {
                url = addUrlParameter(url, paramSelectedValue, selectedValue);
            } else if(serverValue != 'null' && trimSpaces(serverValue) != "" ){
                url = addUrlParameter(url, paramSelectedValue, serverValue);
            }
        }

        if (resName !== null && resValue != null) {
            url = addUrlParameter(url, resName, resValue);
        }
    }
    onOpenBrowser(idName, id, url);
}

/*--------------------------------------------------------------------------------------------------------------------
* These are the current input parameters (some are overloaded or ignored depending on other parameters):
*
* idName        -   will be passed on to the browser as a URL query parameter name along with a value from id
                    (browserUrl&idName=id...)
* id            -   identifies the input element on the parent form (HTML name or id), AND also used as the browser
*                   window name. If this input element has a value it is also used as the initial selected value for
*                   the popup.
* url           -   Initial URL to use for opening the browser pop-up window. Additional parameters are appended to this
*                   before actually opening the browser.
* serverValue   -   Another way to pass an initial selected value.  This is only used if the above "id" parameter
*                   value content is null or empty.
* formName      -   Name of the parent form containing the selection input text field (id field).
*
* The following parameters are URL query parameter names used by the chooser.  The client of this function and the
* chooser must use the same HTML parameter names to pass the pre-selected values by name in the URL&parameterName=value...
*
* paramSelectedValue   - pre-selected resource name (URL&paramSelectedValue=resource_name...)
* paramDefinition      - pre-selected definition type (value is Port, Binding, ...) URL&paramDefinition=defnType...
* paramDefinitionValue - pre-selected definition name (URL&paramDefinitionValue=value...
*
* SYNTAX OF THE SELECTED VALUE:
* The values for the above 3 parameters come from the preselected value, which has a special syntax of the form:
* resourceName#defType::defName
*
* For example:   project/folder/MyWsdlResource#port::myPort
--------------------------------------------------------------------------------------------------------------------*/
function onOpenChooserWithDefinitions(idName, id, url, formName, serverValue,
                                      paramSelectedValue, paramDefinition, paramDefinitionValue)
{
    var formObj = document.forms[formName];
    if(formObj){
        var ipElement = formObj.elements[id];
        if(!ipElement){
		    ipElement = document.getElementById(id);
	    }
        if(ipElement){
            var selectedValue = ipElement.value;
            var defTypes;
            if(selectedValue && trimSpaces(selectedValue) != "" ) {
                defTypes = getResourceDefinitionNameAndValues(selectedValue);
            } else if(serverValue != 'null' && trimSpaces(serverValue) != "" ){
                defTypes = getResourceDefinitionNameAndValues(serverValue);
            }

            if(defTypes && defTypes.length == 3){

                if(trimSpaces(defTypes[0]) != ""){
                    url = addUrlParameter(url, paramSelectedValue, defTypes[0]);
                }
                if(trimSpaces(defTypes[1]) != ""){
                    url = addUrlParameter(url, paramDefinition, defTypes[1]);
                }
                if(trimSpaces(defTypes[2]) != ""){
                    url = addUrlParameter(url, paramDefinitionValue, defTypes[2]);
                }
            }
        }
    }
    onOpenBrowser(idName, id, url);
}

function onOpenChooserWithArchiveDetails(idName, id, url, formName, serverValue, paramSelectedValue, paramClassMethod)
{
    var formObj = document.forms[formName];
    if(formObj){
        var ipElement = formObj.elements[id];
        if(!ipElement){
		    ipElement = document.getElementById(id);
	    }
        if(ipElement){
            var selectedValue = ipElement.value;
            var resWithDetails;
            if(selectedValue && trimSpaces(selectedValue) != "" ) {
                resWithDetails = getArchiveDefinitionNameAndValues(selectedValue);
            } else if(serverValue != 'null' && trimSpaces(serverValue) != "" ){
                resWithDetails = getArchiveDefinitionNameAndValues(serverValue);
            }
            if(resWithDetails && resWithDetails.length == 2){
                if(trimSpaces(resWithDetails[0]) != ""){
                    url = addUrlParameter(url, paramSelectedValue, resWithDetails[0]);
                }
                if(trimSpaces(resWithDetails[1]) != ""){
                    url = addUrlParameter(url, paramClassMethod, resWithDetails[1]);
                }
            }
        }
    }
    onOpenBrowser(idName, id, url);
}

/**
 * open a browser
 */
function onOpenBrowser(idName, id, url)
{
    // build the full url

    url = addUrlParameter(url, idName, id);

    // get window position
    var winPos = getWindowCenterPos(900, 700);
    // open the window
    var win = window.open(url, "ALSB_"+id, "menubar=no,resizable=yes,scrollbars=yes,width=900,height=700,left=" + winPos[0] +", top=" +  winPos[1]);
    win.focus();
}

/**
 *  open the certficate popup
 */
function openCertificatePopup(url, id)
{
    if (id == null) id = "popup";
    // get window position
    var winPos = getWindowCenterPos(820, 700);
    // open the window
    var win = window.open(url, "ALSB_"+id, "menubar=no,resizable=yes,scrollbars=yes,width=820,height=700,left=" + winPos[0] +", top=" +  winPos[1]);
    win.focus();
}

function openResourceUtilityWindow(url, id, _width, _height, _scrollbars) {
    // get window position
    var width = 600;
    var height = 400;
    var scrollbars= "yes";
    if (typeof(_width) != "undefined") width = _width;
    if (typeof(_height) != "undefined") height = _height;
    if (typeof(_scrollbars) != "undefined") scrollbars = _scrollbars;
    var winPos = getWindowCenterPos(width, height);
    var win = window.open(url, "ALSB_"+id, "menubar=no, resizable=yes, scrollbars=" + scrollbars +
                            ", width=" + width + ", height=" + height + ", left=" + winPos[0] +", top=" +  winPos[1]);
    win.focus();
}

function getWindowCenterPos(winWidth, winHeight){
	var leftPos = 0;
	var topPos = 0;
	if (screen) {
        leftPos = (screen.width - winWidth)/2;
        topPos = (screen.height - winHeight)/2;
    }

	return  [leftPos, topPos];
}

/*
    This function is fired when onLoad event occurs in body
    It provides a mechanism to conditionally call a function if it is defined.
*/
function bodyOnLoad() {
    if (typeof pageStartOnLoad == "function") {
        pageStartOnLoad();
    }
}

/*
    This function is fired when onClick event occurs in body
*/
function bodyOnClick(){
    hideOptionsMenu();
    setWindowPositionsCookie();
}

/*
    This function is fired when key is pressed on body of the html page.
    Implement this function to do specific function based on which key is pressed on each jsp, if needed
*/

function bodyOnKeyPress(evt){
}

var X_OFFSET = 0;   // horizontal offset
var Y_OFFSET = 0;   // vertical offset
var ACTIVE_OPTIONS_MENU_ID = null;
var OPTIONS_MENU_CLICKED = false;
var ANNOTATION_INFOTIP_ID = null;
var ANNOTATION_INFOTIP_OPENED = true;
/*
  This function pops-up the option menu
*/
function showOptionsMenu(id, e) {
    hideOptionsMenu();
    var menuElement = document.getElementById? document.getElementById(id): null;
    if (!menuElement) {
        return;
    }
    ACTIVE_OPTIONS_MENU_ID = id;
    OPTIONS_MENU_CLICKED = true;
    setMenuPosition(menuElement,e);
    menuElement.style.visibility="visible";
}

/*
  This function hides the option menu
*/
function hideOptionsMenu(){
    if(ACTIVE_OPTIONS_MENU_ID != null && !OPTIONS_MENU_CLICKED){
        var menuElement = document.getElementById? document.getElementById(ACTIVE_OPTIONS_MENU_ID): null;
        if(menuElement != null){
            menuElement.style.visibility="hidden";
            ACTIVE_OPTIONS_MENU_ID = null;
        }
    }
	OPTIONS_MENU_CLICKED = false;
	hideCascadeOptionsMenus();
    hideInfotip();
}

/*
  This function loads the page for the given url
*/
function FireOptionsMenuUrl(optionUrl){
    OPTIONS_MENU_CLICKED = true;
    document.location.href = optionUrl;
}

var ACTIVE_MAIN_MENU_ID_1;
var ACTIVE_MAIN_MENU_ID_1_CLICKED=false;
var ACTIVE_MAIN_MENU_ID_2;
var ACTIVE_MAIN_MENU_ID_2_CLICKED=false;
var ACTIVE_MAIN_MENU_ID_3;
var ACTIVE_MAIN_MENU_ID_3_CLICKED=false;
//MENU1_TOP and MENU1_LEFT are used for menu2 iframe
var MENU1_TOP = "0px";
var MENU1_LEFT = "0px";
var MENU2_TOP = "0px";
var MENU2_LEFT = "0px";
function showMenu1(id, event){
    hideCascadeOptionsMenus();
    var menuElement = document.getElementById? document.getElementById(id): null;
    if (!menuElement) return;
    ACTIVE_MAIN_MENU_ID_1 = id;
	ACTIVE_MAIN_MENU_ID_1_CLICKED = true;
    setMenuPosition(menuElement,event);
    menuElement.style.zIndex = 2;

    //add for IE select Z-index problem
    if (navigator.appName == IE) {
        if (document.getElementById('MENU1_IFRAME')) {
            var mIFrame1 = document.getElementById('MENU1_IFRAME');
            mIFrame1.style.width = menuElement.offsetWidth;
            mIFrame1.style.height = menuElement.offsetHeight;
            mIFrame1.style.top  = menuElement.style.top;
            mIFrame1.style.left = menuElement.style.left;
            mIFrame1.style.zIndex = menuElement.style.zIndex - 1;

            //save the menu1 start position for menu 2 use
	        MENU1_TOP = menuElement.style.top;
	        MENU1_LEFT = menuElement.style.left;

            mIFrame1.style.display="inline";
       }
    }

    menuElement.style.visibility="visible";
}

function showMenu2(id, event, hOffset, index){
    if(ACTIVE_MAIN_MENU_ID_2){
       var oldMenuElement = document.getElementById? document.getElementById(ACTIVE_MAIN_MENU_ID_2): null;
       if (oldMenuElement) hideMenuId(oldMenuElement);
	   var oldMIFrame2 = document.getElementById('MENU2_IFRAME');
	   if(oldMIFrame2) oldMIFrame2.style.display = "none";

    }

    var menuElement = document.getElementById? document.getElementById(id): null;
    if (!menuElement) return;
    ACTIVE_MAIN_MENU_ID_2 = id;
    menuElement.style.left = hOffset + "px";
    menuElement.style.top = (20 * index) + "px";
    menuElement.style.zIndex = 2;

    //add for IE select Z-index problem
    if (navigator.appName == IE) {
        if (document.getElementById('MENU2_IFRAME')) {
            var mIFrame2 = document.getElementById('MENU2_IFRAME');

            mIFrame2.style.width = menuElement.offsetWidth;
            mIFrame2.style.height = menuElement.offsetHeight;

	        var m1top = MENU1_TOP.substring(0, (MENU1_TOP.indexOf('px')));
            mIFrame2.style.top =(parseInt(m1top) + parseInt((20 * index))) + "px";

	        var m1left = MENU1_LEFT.substring(0, (MENU1_LEFT.indexOf('px')));
            mIFrame2.style.left = (parseInt(m1left) + parseInt(hOffset) )+ "px";

            mIFrame2.style.zIndex = menuElement.style.zIndex - 1;
            mIFrame2.style.display = "inline";

            //save the menu2 start position for menu 3 use
	        MENU2_TOP = mIFrame2.style.top;
	        MENU2_LEFT = mIFrame2.style.left;

        }
    }

    menuElement.style.visibility="visible";
    ACTIVE_MAIN_MENU_ID_2_CLICKED = true;
}

function showMenu3(id, event, hOffset, index){

    if(ACTIVE_MAIN_MENU_ID_3){
       var oldMenuElement = document.getElementById? document.getElementById(ACTIVE_MAIN_MENU_ID_3): null;
       if (oldMenuElement) hideMenuId(oldMenuElement);
	   var oldMIFrame3 = document.getElementById('MENU3_IFRAME');
	   if(oldMIFrame3) oldMIFrame3.style.display = "none";

    }

    var menuElement = document.getElementById? document.getElementById(id): null;
    if (!menuElement) return;
    ACTIVE_MAIN_MENU_ID_3 = id;
    menuElement.style.left = hOffset + "px";     // menu width is set as 150px in CSS
    menuElement.style.top = (20 * index) + "px";
    menuElement.style.zIndex = 2;

    //add for IE select Z-index problem
    if (navigator.appName == IE) {
        if (document.getElementById('MENU3_IFRAME')) {
            var mIFrame3 = document.getElementById('MENU3_IFRAME');

            mIFrame3.style.width = menuElement.offsetWidth;
            mIFrame3.style.height = menuElement.offsetHeight;

	        var m2top = MENU2_TOP.substring(0, (MENU2_TOP.indexOf('px')));
            mIFrame3.style.top =(parseInt(m2top) + parseInt((20 * index))) + "px";

	        var m2left = MENU2_LEFT.substring(0, (MENU2_LEFT.indexOf('px')));
            mIFrame3.style.left = (parseInt(m2left) + parseInt(hOffset) )+ "px";

            mIFrame3.style.zIndex = menuElement.style.zIndex - 1;
            mIFrame3.style.display = "inline";
        }
    }

    menuElement.style.visibility="visible";
    ACTIVE_MAIN_MENU_ID_3_CLICKED = true;
}

function hideCascadeOptionsMenus(){
    if(ACTIVE_MAIN_MENU_ID_3 && ACTIVE_MAIN_MENU_ID_3_CLICKED){
       var menuElement = document.getElementById? document.getElementById(ACTIVE_MAIN_MENU_ID_3): null;
       if (menuElement) hideMenuId(menuElement);
	   var mIFrame3 = document.getElementById('MENU3_IFRAME');
	   if(mIFrame3) mIFrame3.style.display = "none";
    }
	ACTIVE_MAIN_MENU_ID_3_CLICKED = false;

    if(ACTIVE_MAIN_MENU_ID_2 && ACTIVE_MAIN_MENU_ID_2_CLICKED){
       var menuElement = document.getElementById? document.getElementById(ACTIVE_MAIN_MENU_ID_2): null;
       if (menuElement) hideMenuId(menuElement);
	   var mIFrame2 = document.getElementById('MENU2_IFRAME');
	   if(mIFrame2) mIFrame2.style.display = "none";

    }
	ACTIVE_MAIN_MENU_ID_2_CLICKED = false;

    if(ACTIVE_MAIN_MENU_ID_1 && !ACTIVE_MAIN_MENU_ID_1_CLICKED){
       var menuElement = document.getElementById? document.getElementById(ACTIVE_MAIN_MENU_ID_1): null;
       if (menuElement) hideMenuId(menuElement);
	   var mIFrame1 = document.getElementById('MENU1_IFRAME');
       if(mIFrame1) mIFrame1.style.display = "none";
    }
	ACTIVE_MAIN_MENU_ID_1_CLICKED = false;
}

function hideMenuId(menuElement){
    menuElement.style.visibility="hidden";
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
    var rowOffset = 5;  // This is for tooltip, we want it displays without overwriting the text

    if ( x + menuElement.offsetWidth > winLocation[0] + winLocation[2] ){
        x = x - menuElement.offsetWidth ;
    } else {
        x = x + X_OFFSET;
    }

    if ( y + menuElement.offsetHeight > winLocation[1] + winLocation[3] ) {
        y = ( y - menuElement.offsetHeight > winLocation[3] )? y - menuElement.offsetHeight - rowOffset : winLocation[1] + winLocation[3] - menuElement.offsetHeight - rowOffset;
    } else {
        y = y + Y_OFFSET + rowOffset;
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
        width = window.innerWidth;
    } else if (document.documentElement && document.documentElement.clientWidth){
        //IE 6+ in 'standards compliant mode'
  		width = document.documentElement.clientWidth;
    } else if (document.body && document.body.clientWidth){
        //IE 4 compatible
  		width = document.body.clientWidth;
    }

    // To determine the window height
    if (window.innerHeight) {
        height = window.innerHeight;
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

function expandContent(src, dest){
	collapseAndExpand(src, dest);
}

function collapseContent(src, dest){
	collapseAndExpand(src, dest);
}

function collapseAndExpand(src, dest){
	var srcElement = document.getElementById? document.getElementById(src): null;
	var destElement = document.getElementById? document.getElementById(dest): null;
    if(!srcElement && !destElement ){
        return;
    }
    destElement.innerHTML = srcElement.innerHTML;
}


/*
  This function loads the page for the given url
*/
function FireUrlHrefEvent(url){
    try {
        document.location.href = url;
    } catch ( error ) {
        // Just ignore the error
        // Fix for CR372943 - Javascript error "Unspecified Error" occurs
    }
}

/*
  This function does nothing; may be used for no-op in href
*/
function emptyJsFunction(){

}

/*
  Used to set focus on the given formElement
  Eg : documents.forms[0].inputElement
*/
function setFocus(formElement){
    if(formElement){
        formElement.focus();
    }
}

var waitWin;

function closeWaitWindow()
{
    if (waitWin && waitWin.open && !waitWin.closed) {
        waitWin.close();
    }
}

function openWaitWindow(url) {
    leftPos = 0;
    topPos = 0;
    if (screen) {
        leftPos = (screen.width / 2) - 150;
        topPos = (screen.height / 2) - 100;
    } else {
        leftPos = 400;
    }   topPos = 500;

    var opts = "height=200,width=300, top=" + topPos+ ",left=" + leftPos + ", toolbar=no, location=no, directories=no, status=no, menubar=no, scrollbars=no, resizable=no";
    waitWin = window.open(url, "waitWin", opts);
    waitWin.focus();
}

/**
 *  This function returns selected radio button value.
 *  argument: rdoElement = document.formName.rdoInputName
 */
function getRdoValue(rdoElement) {
    if(!rdoElement) return;
    if(rdoElement.checked) return rdoElement.value; // if only one radio button; it may happen only in Chooser
    var i;
    for (i=0; i < rdoElement.length; i++){
        if(rdoElement[i].checked == true) {
            return rdoElement[i].value;
        }
    }
}
/**
 *  This function returns selected radio button value.
 *  argument: checkBoxElement = document.formName.rdoInputName
 */
function getCheckedValues(checkBoxElement) {
    var checkedValues = "";
    if(!checkBoxElement) return;
    if(checkBoxElement.checked) return checkBoxElement.value; // if only one radio button; it may happen only in Chooser
    var i;
    for (i=0; i < checkBoxElement.length; i++){
        if(checkBoxElement[i].checked == true) {
            checkedValues = checkedValues + ":" + checkBoxElement[i].value;
        }
    }
    return checkedValues;
}


var CanSetWindowPositionsCookie = true;
var WINDOW_X_POS = "WINDOW_X_POS";
var WINDOW_Y_POS = "WINDOW_Y_POS";
var WINDOW_JSP_ID = "WINDOW_JSP_ID";
function setWindowPositionsCookie(){
    var scrollX = 0;  var scrollY = 0;
    if( CanSetWindowPositionsCookie ){
        var winLocation = getWindowLocation();
        if(winLocation){
            scrollX = winLocation[2];
            scrollY = winLocation[3];
        }
        var expires_mins = 25;
        if((typeof(jspId) != "undefined")){
            createCookie(WINDOW_JSP_ID, jspId, expires_mins);
            createCookie(WINDOW_X_POS, scrollX, expires_mins);
            createCookie(WINDOW_Y_POS, scrollY, expires_mins);
        }

    }
}

/*
 * This function is used to create cookie for the given name and value
 */
function createCookie(name, value, mins) {
	var expires = "";
	if (mins){
		var date = new Date();
		date.setTime(date.getTime()+(mins*60*1000));
		var expires = "; expires="+ date.toGMTString();
	}
	document.cookie = name+ "=" + value + expires + "; path=/";
}

/*
 * This function is used to read cookie for the given name if exists
 */
function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0; i < ca.length;i++){
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

/**
  * This function does a delete
  */
 function confirmDelete (formName,confirmMessage,noSelectMessage) {

	var formObject = document.forms[formName];
	if ( formObject)  {
		for(var i=0; i< formObject.elements.length; i++ ) {
			elementType = formObject.elements[i].type;
			if ( elementType == 'checkbox') {
				if  (formObject.elements[i].name.indexOf ('alertSummaryDetaildeleteAlertId') !=-1) {
		 			if( formObject.elements[i].checked) {
						return confirm (confirmMessage);
					}
				}
			}
  		}
        }
        alert(noSelectMessage);
        return false;
 }

/*
 * This function is used to determine if input values are changed from default on client side
 */
function areDefaultValuesChanged(formName) {
    var formObj = document.forms[formName];
    if(formObj) {
        for(var i = 0, j = formObj.elements.length; i < j; i++) {
            elementType = formObj.elements[i].type;

            if (elementType == 'text' || elementType == 'textarea' || elementType == 'password') {
                if (formObj.elements[i].value != formObj.elements[i].defaultValue) {
                    return true;
                }
            }

            if (elementType == 'checkbox' || elementType == 'radio') {
                if (formObj.elements[i].checked != formObj.elements[i].defaultChecked) {
                    return true;
                }
            }

            if (elementType == 'select-one' || elementType == 'select-multiple') {
                for (var k = 0, l = formObj.elements[i].options.length; k < l; k++) {
                    if (formObj.elements[i].options[k].selected != formObj.elements[i].options[k].defaultSelected) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

function ConfirmCancelAllMessageFlow(confirmMsg, url){
    if(confirm(confirmMsg)){
        FireUrlHrefEvent(url);
    }
}

function confirmAction(msg, url){
    if(confirm(msg)){
        FireUrlHrefEvent(url);
    }
}

/*
 * Returns key code for the key pressed
 */
function getKeyCode(evt){
    var code = (window.event) ?  event.keyCode : evt.which;
    return code;
}

/*
 * Returns true, if enter key is pressed
 */
function isEnterKeyPressed(code){
    var isEnter = false;
    if (code == 13){
        isEnter = true;
    }
    return isEnter;
}

/*
 * hilites the selected row
 */
function hiliteCurrentTableRow(formName, ipName, tableRowIdFormat){
    var ipElement = (document.forms[formName]).elements[ipName];
    // if no input return immediately
    if(!ipElement) return;
    MODIFIED_ROW_CHECK_BOX_ARRAY = new Array();
    // for one row
    if(ipElement.checked) {
        var tableRowId = tableRowIdFormat + 0;
        var tableRowElement = document.getElementById(tableRowId);
        if(!tableRowElement) return;
        if(ipElement.checked == true ) {
            MODIFIED_ROW_CHECK_BOX_ARRAY[MODIFIED_ROW_CHECK_BOX_ARRAY.length] = tableRowId;
            tableRowElement.className = "table_row_data_hilite";
            return;
        }
    }
    // for multiple rows
    for (var i = 0; i < ipElement.length; i++){
        var tableRowId = tableRowIdFormat + i;
        var tableRowElement = document.getElementById(tableRowId);
        if(!tableRowElement){
            break;
        }
        if(ipElement[i].checked == true) {
            MODIFIED_ROW_CHECK_BOX_ARRAY[MODIFIED_ROW_CHECK_BOX_ARRAY.length] = tableRowId;
            tableRowElement.className = "table_row_data_hilite";
        } else {
            if(i % 2 == 0){
                tableRowElement.style.background = EVEN_ROW_BG_COLOR;
            } else {
                tableRowElement.style.background = ODD_ROW_BG_COLOR;
            }
        }
    }
}


/* updates entire rows based on 'cb' input state */
function updateTableRowsBgColor(cb, f, childIpName, tableId, rowCount){
    if(!cb.checked){
        MODIFIED_ROW_CHECK_BOX_ARRAY = new Array();
        for (i = 0; i < rowCount; i++){
            var tableRowId = getTableRowIdFormat(tableId, i);
            var tableRowElement = document.getElementById(tableRowId);
            if(!tableRowElement){
                continue;
            }
            if(i % 2 == 0){
                tableRowElement.style.background = EVEN_ROW_BG_COLOR;
            } else {
                tableRowElement.style.background = ODD_ROW_BG_COLOR;
            }
        }
    } else {

        var ipElement = f.elements[childIpName]
        // if no input return immediately
        if(!ipElement) return;
        var cbIndex = 0;
        for (var i = 0; i < rowCount; i++){
            var tableRowId = getTableRowIdFormat(tableId, i);
            var tableRowElement = document.getElementById(tableRowId);
            if(!tableRowElement){
                continue;
            }
            // TODO : hardcoded column index, please use better mechanism for 3.0   - Saba
            var columObj = document.getElementById(getTableColumnIdFormat(tableRowId, 0));
            if(!columObj){
                continue;
            }
            var htmlvalue = columObj.innerHTML;
            if(htmlvalue && htmlvalue.indexOf('checkbox') != -1 && htmlvalue.indexOf('disabled') != -1){
                continue;
            }
            var ipObj = ipElement[cbIndex];
            if(!ipObj){
                ipObj = ipElement;
            }
            if(!isHighliteRow(tableRowId)){
                MODIFIED_ROW_CHECK_BOX_ARRAY[MODIFIED_ROW_CHECK_BOX_ARRAY.length] = tableRowId;
                tableRowElement.style.background = ROW_SELECTED_HILITE_COLOR;
            }
            cbIndex++;
        }
    }
}

/**
  * Updates current row bgcolor based on input state
  */
function updateTableRowBgColor(cbObj, childIpName, tableId, rowIndex){
    var tableRowId = getTableRowIdFormat(tableId, rowIndex);
    var tableRowElement = document.getElementById(tableRowId);
    if(!tableRowElement) return;
    if(cbObj.checked && !isHighliteRow(tableRowId)) {
        tableRowElement.style.background = ROW_SELECTED_HILITE_COLOR;
        MODIFIED_ROW_CHECK_BOX_ARRAY[MODIFIED_ROW_CHECK_BOX_ARRAY.length] = tableRowId;
    } else {
        // changed back to default state
        var removeIndex = -1;
         for(var i = 0; i < MODIFIED_ROW_CHECK_BOX_ARRAY.length; i++){
            if(MODIFIED_ROW_CHECK_BOX_ARRAY[i] == tableRowId){
                removeIndex = i;
                break;
            }
        }
        if(removeIndex != -1){
            if(rowIndex % 2 == 0){
                tableRowElement.style.background = EVEN_ROW_BG_COLOR;
            } else {
                tableRowElement.style.background = ODD_ROW_BG_COLOR;
            }
            MODIFIED_ROW_CHECK_BOX_ARRAY.splice(removeIndex, 1);
        }
    }
}

function updateTableRowsBgColorOnPageLoad(headerCheckBoxName, childIpName, formName, tableId, rowCount){
    var theform = document.forms[formName];
    var ipElement = theform.elements[headerCheckBoxName];
    if(!ipElement) return;
    /*if(!ipElement.checked){
        for(var i = 0; i < rowCount; i++) {
             if (theform.elements[i].type == "checkbox" &&
                 theform.elements[i].name == childIpName &&
                 theform.elements[i].name != headerCheckBoxName &&
                 theform.elements[i].checked) {
                 updateTableRowBgColor(theform.elements[i], childIpName, tableId, i);
                 break;
             }
        }
    }    */
    updateTableRowsBgColor(ipElement, theform, childIpName, tableId, rowCount);
}

function hiliteSelectedTableRow(formName, ipName, tableRowIdFormat){
    var ipElement = (document.forms[formName]).elements[ipName];
    // if no input return immediately
    if(!ipElement) return;
    MODIFIED_ROW_CHECK_BOX_ARRAY = new Array();
    // for one row
    if(ipElement.checked) {
        var tableRowId = tableRowIdFormat + 0;
        var tableRowElement = document.getElementById(tableRowId);
        if(!tableRowElement) return;
        if(ipElement.checked == true) {
            MODIFIED_ROW_CHECK_BOX_ARRAY[MODIFIED_ROW_CHECK_BOX_ARRAY.length] = tableRowId;
            tableRowElement.className = "table_row_data_hilite";
            return;
        }
    }
    // for multiple rows
    for (i = 0; i < ipElement.length; i++){
        var tableRowId = tableRowIdFormat + i;
        var tableRowElement = document.getElementById(tableRowId);
        if(!tableRowElement){
            break;
        }
        if(ipElement[i].checked == true) {
            MODIFIED_ROW_CHECK_BOX_ARRAY[MODIFIED_ROW_CHECK_BOX_ARRAY.length] = tableRowId;
            tableRowElement.className = "table_row_data_hilite";
            break;
        }
    }
}

function trimSpaces( str )
{
  str = str.replace( /^\s+/g, "" ); // strip leading
  return str.replace( /\s+$/g, "" ); // strip trailing
}

/*
 * The definition types and separator strings used here need to match those in WsdlObject.java
 */
function getResourceDefinitionNameAndValues(nameAndDefinitions)
{
    var resName = "";
    var type = "";
    var typeValue = "";
    var index;
    if(nameAndDefinitions && trimSpaces(nameAndDefinitions) != "") {
        index = nameAndDefinitions.indexOf("#")
        if(index != -1){
            resName =  nameAndDefinitions.substring(0, index);
            typeValue = nameAndDefinitions.substring(index+1);
        }

        if(nameAndDefinitions.indexOf("#element::") != -1){
            type =  'element'
        } else if(nameAndDefinitions.indexOf("#type::") != -1){
            type =  'type'
        } else if(nameAndDefinitions.indexOf("#binding::") != -1){
            type =  'binding'
        } else if(nameAndDefinitions.indexOf("#port::") != -1){
            type =  'port'
        }

        index = nameAndDefinitions.indexOf("::")
        if(index != -1){
            typeValue =  nameAndDefinitions.substring(index+2);
        }
    }
    return [resName, type, typeValue];
}

function getArchiveDefinitionNameAndValues(nameAndDetails)
{
    var resName = "";
    var classAndMethod = "";
    var index;
    if(nameAndDetails && trimSpaces(nameAndDetails) != "") {
        index = nameAndDetails.lastIndexOf("#")
        if(index != -1){
            resName =  nameAndDetails.substring(0, index);
            classAndMethod = nameAndDetails.substring(index+1);
        }
    }
    return [resName, classAndMethod];
}

/**
 * functions for modal popup
 */
function MM_reloadPage(init) {  //reloads the window if Nav4 resized
  if (init==true) with (navigator) {if ((appName=="Netscape")&&(parseInt(appVersion)==4)) {
    document.MM_pgW=innerWidth; document.MM_pgH=innerHeight; onresize=MM_reloadPage; }}
  else if (innerWidth!=document.MM_pgW || innerHeight!=document.MM_pgH) {
    location.reload();
  }
}
MM_reloadPage(true);

function MM_findObj(n, d) { //v4.01
  var p,i,x;
  if(!d) { d=document; }
  if((p=n.indexOf("?"))>0&&parent.frames.length) {
    d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);
    d=document;
  }
  if(!(x=d[n])&&d.all) {
    x=d.all[n];
  }
  for (i=0;!x&&i<d.forms.length;i++)
    x=d.forms[i][n];
  for(i=0;!x&&d.layers&&i<d.layers.length;i++)
    x=MM_findObj(n,d.layers[i].document);
  if(!x && d.getElementById)
    x=d.getElementById(n);

  return x;
}

function MM_showHideLayers() { //v6.0
  var i,p,v,obj,args=MM_showHideLayers.arguments;
  for (i=0; i<(args.length-2); i+=3)
    if ((obj=MM_findObj(args[i]))!=null) {
        v=args[i+2];
        if (obj.style) {
            obj=obj.style; v=(v=='show')?'inline':(v=='hide')?'none':v;
        }
        obj.display=v;
    }
}

function setPopupPosition() {
    if (isPopupOpened == true) {
        var windowLocation = getWindowLocation();

        var maskElement = document.getElementById('mask');
        if (maskElement != null) {
            maskElement.style.height = windowLocation[1] + "px";
            maskElement.style.width = windowLocation[0] + "px";
            maskElement.style.top = windowLocation[3] + "px";
            maskElement.style.left = windowLocation[2] + "px";
        }

        var popupElement = document.getElementById('pop_up');
        if (popupElement != null) {
            var leftPos = windowLocation[2] + (windowLocation[0] / 2) - 150;
            var topPos = windowLocation[3] + (windowLocation[1] / 2) - 100;
            popupElement.style.top  = topPos + "px";
            popupElement.style.left = leftPos + "px";

            //add for IE select Z-index problem
            if (navigator.appName == IE) {
                var popupIFrameElement = document.getElementById('POP_UP_IFRAME');
                if (popupIFrameElement != null) {
                    popupIFrameElement.style.top  = popupElement.style.top;
                    popupIFrameElement.style.left = popupElement.style.left;
               }
            }
        }
    }
}

var isPopupOpened = false;
var disableSelectBox = false;
function openPopup(toOpenPopupWin, callbackUrl, disable){
    var userAgent = navigator.userAgent.toLowerCase();
    if ( callbackUrl && userAgent.indexOf( "safari" ) != -1 ) {
        //It doesn't work as expected on Safari if we do ajax and form submit at the same time, so
        //we don't make callback on Safari
        return;
    }

    isPopupOpened = true;

    setPopupPosition();

    //show mask
    MM_showHideLayers('mask','','show');

    //Need to handle IE issues
    if (navigator.appName == IE) {
        if (disable == 'true') {
            disableSelectBox = disable;
            disableSelectBoxes();
        }
        disableTabIndexes();
    }

    if (toOpenPopupWin == 'true') {
        //show progress meter, and make sure the callback can be called only after show progess meter
        if (callbackUrl) {
            setTimeout('showPopup(\"' + callbackUrl + '\")', 1);
            //showPopup(callbackUrl);
        } else {
            setTimeout('showPopup()', 1);
            //showPopup();
        }
    } else {
        if (callbackUrl) {
            makeCallbackRequest(callbackUrl);
        }
    }

}

function showPopup(callbackUrl) {
    if (navigator.appName == IE) {
        var popupIFrameElement = document.getElementById('POP_UP_IFRAME');
        if (popupIFrameElement != null) {
            var popupElement = document.getElementById('pop_up');
            if (popupElement != null) {
                //show iframe
                MM_showHideLayers('POP_UP_IFRAME','','show');
            }
        }
    }
    MM_showHideLayers('pop_up','','show');

    //reset timer
    hours = 0, mins = 0, secs = 0;
    showTimer('pop_up_timer');
    if (callbackUrl) {
        makeCallbackRequest(callbackUrl);
    }
}

var hours = 0;
var mins = 0;
var secs = 0;
function showTimer(timerId) {

    var e = document.getElementById(timerId);
    if (isPopupOpened && e) {

        var secsStr = secs<=9 ? "0"+secs : secs;
        var minsStr = mins<=9 ? "0"+mins : mins;

        var hoursStr = "";
        //don't display hour if it is < 0
        if (hours > 0) {
            hoursStr = hours<=9 ? "0"+hours + ":" : hours + ":";
        }

        e.innerHTML = hoursStr + minsStr + ":" + secsStr;

        secs++;
        if (secs == 60) {
            secs = 0;
            mins++;
            if (mins == 60) {
                mins = 0;
                hours++;
            }
        }

        setTimeout("showTimer('" + timerId + "')",1000);
    }
}


function closePopup(){
    MM_showHideLayers('pop_up','','hide');
    MM_showHideLayers('mask','','hide');

    //Need to handle IE issues
    if (navigator.appName == IE) {
        MM_showHideLayers('POP_UP_IFRAME','','hide');

        if (disableSelectBox == 'true') {
            enableSelectBoxes();
        }
        enableTabIndexes();
    }

    isPopupOpened = false;
}
window.onscroll = setPopupPosition;
addEvent(window, "resize", setPopupPosition);

function addEvent(obj, evType, fn){
 if (obj.addEventListener){
    obj.addEventListener(evType, fn, true);
    return true;
 } else if (obj.attachEvent){
    var r = obj.attachEvent("on"+evType, fn);
    return r;
 } else {
    return false;
 }
}
function removeEvent(obj, evType, fn, useCapture){
  if (obj.removeEventListener){
    obj.removeEventListener(evType, fn, useCapture);
    return true;
  } else if (obj.detachEvent){
    var r = obj.detachEvent("on"+evType, fn);
    return r;
  }
}


function newXMLHttpRequest() {
    var xml_request;
    if (window.XMLHttpRequest) { // Mozilla, Safari,...
        xml_request = new XMLHttpRequest();
        if (xml_request.overrideMimeType) {
            xml_request.overrideMimeType('text/xml');
            // See note below about this line
        }
    } else if (window.ActiveXObject) { // IE
        try {
            xml_request = new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e) {
            try {
                xml_request = new ActiveXObject("Microsoft.XMLHTTP");
            } catch (e) {}
        }
    }
    return xml_request;
}

/**
 * AJax to check if the server has done the task
 */
function makeCallbackRequest(url) {
    var http_request = newXMLHttpRequest();
    
    if (http_request) {
        http_request.onreadystatechange = function() { alertContents(http_request); };
        http_request.open('GET', url, true);
        http_request.send(null);
    }
}

function alertContents(http_request) {
        if (http_request.readyState == 4) {
            try {
                if (http_request.status == 200) {
                    //if (http_request.responseText == "yes") {
                        closePopup();
                    //}
                } else {
                    //alert('There was a problem with the request.');
                    closePopup(); //close it anyway
                }
            } catch (e) {
                //close popup if there is any error;
                closePopup();
            }          
        }
        reInitializeSessionTimeoutTimer();
}

// If using Mozilla or Firefox, use Tab-key trap.
if (!document.all) {
	document.onkeypress = keyDownHandler;
}
// Tab key trap. iff popup is shown and key was [TAB], suppress it.
// @argument e - event - keyboard event that caused this function to be called.
function keyDownHandler(e) {
    if (isPopupOpened && e.keyCode == 9)  return false;
}

// Pre-defined list of tags we want to disable/enable tabbing into
var gTabbableTags = new Array("A","BUTTON","TEXTAREA","INPUT","IFRAME");
var gTabIndexes = new Array();

// For IE.  Go through predefined tags and disable tabbing into them.
function disableTabIndexes() {
	if (document.all) {
		var i = 0;
		for (var j = 0; j < gTabbableTags.length; j++) {
			var tagElements = document.getElementsByTagName(gTabbableTags[j]);
			for (var k = 0 ; k < tagElements.length; k++) {
				gTabIndexes[i] = tagElements[k].tabIndex;
				tagElements[k].tabIndex="-1";
				i++;
			}
		}
	}
}

// For IE. Restore tab-indexes.
function enableTabIndexes() {
	if (document.all) {
		var i = 0;
		for (var j = 0; j < gTabbableTags.length; j++) {
			var tagElements = document.getElementsByTagName(gTabbableTags[j]);
			for (var k = 0 ; k < tagElements.length; k++) {
				tagElements[k].tabIndex = gTabIndexes[i];
				tagElements[k].tabEnabled = true;
				i++;
			}
		}
	}
}


/**
* Disable all drop down form select boxes, this is get around IE's problem of having
* select form tags to always be the topmost z-index or layer
*/
//orginalDisabledSelect is used to save the drop down form selects which are orginally
//disabled, and we will not enable them in enableSelectBoxes()
var orginalDisabledSelect = new Array();
function disableSelectBoxes() {
    var idx = 0;
	for(var i = 0; i < document.forms.length; i++) {
		for(var j = 0; j < document.forms[i].length; j++){
		    var element = document.forms[i].elements[j];
			if(element.tagName == "SELECT") {
			    if (element.disabled) {
			        //save this element to orginalDisabledSelect, since the form may not
			        //have a name, so we remember its index in document
			        orginalDisabledSelect[idx++] = [i, element.name];
			    } else {
				    element.disabled = true;
				}
			}
		}
	}
}

/**
* Enable the drop down form select boxes which was disabled in disableSelectBoxes(), this
* is get around IE's problem of having select form tags to always be the topmost z-index
* or layer
*/
function enableSelectBoxes() {
	for(var i = 0; i < document.forms.length; i++) {
		for(var j = 0; j < document.forms[i].length; j++){
		    var element = document.forms[i].elements[j];
			if(element.tagName == "SELECT") {
			    //check if orginalDisabledSelect contains it, if yes, don't enable it
			    var matched = false;
			    for(var k =0; k<orginalDisabledSelect.length; k++) {
			        if (orginalDisabledSelect[k][0] == i &&
			            orginalDisabledSelect[k][1] == element.name) {
			            matched = true;
			            break;
			        }
			    }
			    if (!matched) {
			        //enable this select
			        element.disabled = false;
			    }
			}
		}
	}
}

/**
 * Update selall checkbox if any checkbox flag changes
 */
function updateAllFlag(cb, f, allcb) {
     var checkedFlag = true;

     //if the current item is unchecked, then the allBox should be unchecked;
     //no need to find out other items.
     //otherwise, find out if all other items are checked, if yes, then
     //allcb checkbox should be checked.
     if (cb.checked == false) {
         checkedFlag = false;
     } else {
         // find other items in the project
         for(var i=0;i<f.elements.length;i++) {
             if (f.elements[i].type=="checkbox" &&
                     f.elements[i].name != allcb &&
                     f.elements[i].checked == false) {
                 checkedFlag = false;
                 break;
             }
         }
     }

     //update select all checkbox
     f.elements[allcb].checked = checkedFlag;
 }

//Pre-load common images
var commonImageSources = new Array(
"/sbconsole/images/sb/processing.png",
"/sbconsole/images/sb/change_center_bg_no_corners.jpg"
);

var commonImages = new Array();
function preloadCommonImages(){
    for (var i=0; i<commonImageSources.length; i++){
        commonImages[i] = new Image();
        commonImages.src = commonImageSources[i];
    }
}
preloadCommonImages();

var canSetResourceName = false;
function setResourceNameFromFileName(srcValue, destField, formName){
    var formObject = document.forms[formName];
	// if no form  return immediately
	if(!formObject) return;
	var ipElement = formObject.elements[destField];
	// if no input element  return immediately
	if(!ipElement) return;

	if( trimSpaces(ipElement.value) == "" && !canSetResourceName){
		canSetResourceName = true;
	}
	// If user entered something in destField, dont set the file name to destField and return immediately
	if(!canSetResourceName) return;
	// if no file path return immediately
	if(trimSpaces(srcValue) == "") return;
    // Extract file name alone
	var slashIndex = srcValue.lastIndexOf("\\");
	if(slashIndex == -1){  // for unix system
	    slashIndex = srcValue.lastIndexOf("/");
	}

    var fileName;
    if(slashIndex != -1){
	    fileName = srcValue.substring(slashIndex+1);
    } else {
        //no file seperator  fix bug9010029
        fileName = srcValue;
    }

    var periodIndex = fileName.lastIndexOf(".");
	if(periodIndex != -1){
	    fileName = fileName.substring(0, periodIndex);
	}

    // set the file name to destFiled
	ipElement.value = fileName;
}

function replaceAll(text, oldStr, newStr){
    while ( text.indexOf(oldStr) != -1){
        text = text.replace(oldStr, newStr);
    }
    return text;
}

function replaceBreakWithNewLine(text){
    return replaceAll(text, '<br/>', '\n');
}

/********************************************************************************
 *          Warning for unsaved changes when unloading a page
 *******************************************************************************/
/* The following global variables control the unloadWarning */
unloadWarning.text = "{UNDEFINED_I8N_MSG}";
unloadWarning.hasChanges = false;
unloadWarning.submitOk = false;
unloadWarning.formname = null;
unloadWarning.shown = false;

function unloadWarning() {
    if (unloadWarning.shown || unloadWarning.submitOk) {
        return;
    }
    // check server object
    if (unloadWarning.hasChanges) {
        // CR331587 - unload warning can occur mulitple time for changes
        // unloadWarning.shown = true;
        return unloadWarning.text;
    // check client browser form inputs
    } else if (areDefaultValuesChanged(unloadWarning.formname)){
        // CR331587 - unload warning can occur mulitple time for changes
        // unloadWarning.shown = true;
        return unloadWarning.text;
    }
}
/* Forms should call this to suppress the unload warning on submit */
function onSubmitNoWarning() {
    unloadWarning.submitOk = true;
    return true;
}

/* On mouse over the row, hilite row  */
function onMouseOverChangeTableRowBgColor(rowObj){
    var row = document.getElementById(rowObj.id);
    if(row && !isHighliteRow(rowObj.id)){
        row.style.background = ROW_MOUSE_OVER_COLOR;
    }
}

/*On mouse out the row, chage back to original bg color and hilite the modified row */
function onMouseOutChangeTableRowBgColor(rowObj){
	var row = document.getElementById(rowObj.id);
    if(row){
        if(isHighliteRow(rowObj.id)){   //Highlite row
            row.style.background= ROW_SELECTED_HILITE_COLOR;
        } else if(rowObj.className == 'table_row_data_even_row'){  //even row
            row.style.background= EVEN_ROW_BG_COLOR;
        } else {  //odd row
            row.style.background= ODD_ROW_BG_COLOR;
        }
    }
}

/* On mouse over the row, hilite columns one by one */
function onMouseOverChangeTableCellBgColor(rowObj, numColumns){
    for(var i = 0; i < numColumns; i++){
        var columObj = document.getElementById(getTableColumnIdFormat(rowObj.id, i));
        if(columObj && !isHighliteColumn(columObj.id)){
            columObj.style.background=ROW_MOUSE_OVER_COLOR;
        }
    }
}

/* Array Holds currently modified check boxes*/
var MODIFIED_CHECK_BOX_ARRAY = new Array();

/*On mouse out the row, chage back to original bg color and hilite the modified check box cell*/
function onMouseOutChangeTableCellBgColor(rowObj, numColumns){
	for(var i = 0; i < numColumns; i++){
		var columObj = document.getElementById(getTableColumnIdFormat(rowObj.id, i));
		if(columObj){
			if(isHighliteColumn(columObj.id)){   //Highlite row
				columObj.style.background=ROW_SELECTED_HILITE_COLOR;
			} else if(rowObj.className == 'table_row_data_even_row'){  //even row
				columObj.style.background=EVEN_ROW_BG_COLOR;
			} else {  //odd row
				columObj.style.background=ODD_ROW_BG_COLOR;
			}
		}
    }
}

/* returns true if the given row id exists in modified row check boxe array*/
function isHighliteRow(rowId){
	var bRtnValue = false;
    for(var i = 0; i < MODIFIED_ROW_CHECK_BOX_ARRAY.length; i++){
        if(MODIFIED_ROW_CHECK_BOX_ARRAY[i] == rowId){
			bRtnValue = true;
            break;
        }
    }
    return bRtnValue;
}

/* returns true if the given column id exists in modified check boxes array*/
function isHighliteColumn(columnId){
	var bRtnValue = false;
    for(var i = 0; i < MODIFIED_CHECK_BOX_ARRAY.length; i++){
        if(MODIFIED_CHECK_BOX_ARRAY[i] == columnId){
			bRtnValue = true;
            break;
        }
    }
    return bRtnValue;
}

/* updates Modidifed check box array*/
function updateModifiedCBItems(cbObj, columnId, rowIndex){
    var columObj = document.getElementById(columnId);
    if(!columObj)return;
    if(cbObj.checked != cbObj.defaultChecked){
        if(!isHighliteColumn(columnId)){
            columObj.style.background=ROW_SELECTED_HILITE_COLOR;
            MODIFIED_CHECK_BOX_ARRAY[MODIFIED_CHECK_BOX_ARRAY.length] = columnId;
        }
    } else {
        // changed back to default state
        var removeIndex = -1;
         for(var i = 0; i < MODIFIED_CHECK_BOX_ARRAY.length; i++){
            if(MODIFIED_CHECK_BOX_ARRAY[i] == columnId){
                removeIndex = i;
                break;
            }
        }
        if(removeIndex != -1) {
            if(rowIndex % 2 == 0){
                columObj.style.background=EVEN_ROW_BG_COLOR;  // even row
            } else {
                columObj.style.background=ODD_ROW_BG_COLOR;   // odd row
            }
            MODIFIED_CHECK_BOX_ARRAY.splice(removeIndex, 1);
        }
    }
}

/* Formats column id for Table*/
function getTableColumnIdFormat(rowId, columnIndex){
    return rowId.concat("_colId_"+columnIndex);
}

/* format and returns table row id*/
function getTableRowIdFormat(tableId, rowIndex){
	var rtnId;
	if(tableId){
        rtnId = "tableId_"+ tableId + "_";
    }
    rtnId = (rtnId.concat("rowId_")) + rowIndex;
    return rtnId;
}

/* format and returns table cell id*/
function getTableRowColumnIdFormat(tableId, rowIndex, columnIndex){
	var rtnId;
	if(tableId){
        rtnId = "tableId_"+ tableId + "_";
    }
    rtnId = (rtnId.concat("rowId_")) + rowIndex;
    return getTableColumnIdFormat(rtnId, columnIndex);
}

/* Updates entire column bgcolor based on header check box*/
function updateEntireColumnBgColor(cb, f, childIpName, tableId, rowCount, columnIndex){
    var childCBObj = f.elements[childIpName];
    var cbIndex = 0;
    for(var i=0; i < rowCount; i++) {
        var columnId = getTableRowColumnIdFormat(tableId, i, columnIndex);
        var columObj = document.getElementById(columnId);
        if(columObj && (columObj.innerHTML).indexOf('checkbox') == -1){
            continue;
        }
        var cbb = childCBObj[cbIndex];
        if(!cbb){
            cbb = childCBObj;
        }
        updateOneColumnBgColor(cbb, childIpName, tableId, i, columnIndex );
        cbIndex++;
    }

}

/* update one cell check box bgcolor */
function updateOneColumnBgColor(childCBObj, childIpName, tableId, rowIndex, columnIndex ){
	if( childCBObj && childCBObj.type == 'checkbox' && !childCBObj.disabled && childCBObj.name == childIpName){
		var columnId = getTableRowColumnIdFormat(tableId, rowIndex, columnIndex);
        updateModifiedCBItems(childCBObj, columnId, rowIndex);
	}
}
    function showInfotip(id, event, info){
        hideCascadeOptionsMenus();
        var divId = id + "_div"
        var menuElement = document.getElementById? document.getElementById(divId): null;
        if (!menuElement) return;
        var textareaId = id + "_textarea";
        var textareaElement = document.getElementById ? document.getElementById(textareaId) : null;
        if (!textareaElement) return;
        textareaElement.value = info;
        ANNOTATION_INFOTIP_ID = divId;
        ANNOTATION_INFOTIP_OPENED = true;
        setMenuPosition(menuElement,event);
        menuElement.style.zIndex = 2;

        //add for IE select Z-index problem
        if (navigator.appName == IE) {
            if (document.getElementById('ANNOTATION_INFOTIP_IFRAME')) {
                var mIFrame1 = document.getElementById('ANNOTATION_INFOTIP_IFRAME');
                mIFrame1.style.width = menuElement.offsetWidth;
                mIFrame1.style.height = menuElement.offsetHeight;
                mIFrame1.style.top  = menuElement.style.top;
                mIFrame1.style.left = menuElement.style.left;
                mIFrame1.style.zIndex = menuElement.style.zIndex - 1;

                mIFrame1.style.display="inline";
           }
        }

        menuElement.style.visibility="visible";
    }

	/*
	  This function hides the infotip
	*/
	function hideInfotip(){
	    if(ANNOTATION_INFOTIP_ID != null && !ANNOTATION_INFOTIP_OPENED ){
	        var menuElement = document.getElementById? document.getElementById(ANNOTATION_INFOTIP_ID): null;
	        if(menuElement != null){
	            menuElement.style.visibility="hidden";
	            ANNOTATION_INFOTIP_ID = null;
	            var infoTipIFrame = document.getElementById('ANNOTATION_INFOTIP_IFRAME');
	            if(infoTipIFrame) infoTipIFrame.style.display = "none";
	        }
	    }
	    ANNOTATION_INFOTIP_OPENED = false;
	}

function clearDateFiledHint(thisobj, format){
    if(trimSpaces(thisobj.value) == format) {
        thisobj.value = "";
    }
}

function resetDateFieldHint(thisobj, format){
    if(trimSpaces(thisobj.value) == "") {
        thisobj.value = format;
    }
}

function makeRequestToUpdateToggle(url){
    var http_request = newXMLHttpRequest();
    if (http_request) {
        http_request.onreadystatechange = function() { updateToggleResponse(http_request); };
        http_request.open('GET', url, true);
        http_request.send(null);
    }
}


    function updateToggleResponse(http_request) {
        if (http_request.readyState == 4) {
            try {
                if (http_request.status == 200) {
                   //alert("response from ajax = " + http_request.responseText);
                } else {
                }
            } catch (e) {
            }
        }
        reInitializeSessionTimeoutTimer();
    }

function appendStatusMessage(divId, tableId, additionalMessages)
{
    var statusDiv = document.getElementById(divId);
    var messageTable = document.getElementById(tableId);
    if ( messageTable == null ) {
        messageTable = insertStatusMessageTable(statusDiv, tableId);
    }
    var lastRow = messageTable.rows.length;
    for ( var index = 0; index < additionalMessages.length; index++) {
        var row = messageTable.insertRow(lastRow++);
        var newCell = row.insertCell(0);
        newCell.innerHTML = additionalMessages[index];
    }
    statusDiv.style.display="block";
}

function insertStatusMessageTable(statusDiv, tableId)
{
    // createa a table to contain the MessageTable

    var containerTable = document.createElement("table");
    containerTable.width="100%";
    containerTable.style.align="center"
    containerTable.border="0";
    containerTable.className="messagebg";
    containerTable.cellSpacing="0";
    containerTable.cellPadding="0";

    // create a new row and column
    var row = containerTable.insertRow(0); // insert row at the top
    var cell = row.insertCell(0);

    // create a new table
    var messageTable = makeStatusMessageTable(tableId);

    // add it to the cell in the container table    
    cell.appendChild(messageTable);

    // append the container table to the div
    statusDiv.appendChild(containerTable);

    return messageTable;
}

function makeStatusMessageTable(tableId)
{
    // create a table to contain the status messages
    var messageTable = document.createElement("table");
    messageTable.width="100%";
    messageTable.border="0";
    messageTable.id = tableId;
    messageTable.cellSpacing="0";
    messageTable.cellPadding="0";
    return messageTable;
}

function makeRequestToUpdateTable(url, tableId){
    var http_request = newXMLHttpRequest();
    if (http_request) {
        http_request.onreadystatechange = function() { updateTableResponse(http_request, tableId); };
        http_request.open('GET', url, true);
        http_request.send(null);
    }
}


    function updateTableResponse(http_request, tableDivId) {
        if (http_request.readyState == 4) {
            try {
                if (http_request.status == 200) {
                   document.getElementById(tableDivId).innerHTML=http_request.responseText;
                } else {
                }
            } catch (e) {
            }
        }
        reInitializeSessionTimeoutTimer();
    }

//TableTag: get the page number input in text field and set it to param in url
function gotoPage(url, fieldId, param){
    var num = document.getElementById(fieldId);
    url = addUrlParameter(url, param, num.value);
    document.location.href = url;
}


function showAbout() {
    var windowLocation = getWindowLocation();

    var maskElement = document.getElementById('mask');
    if (maskElement != null) {
        maskElement.style.height = windowLocation[1] + "px";
        maskElement.style.width = windowLocation[0] + "px";
        maskElement.style.top = windowLocation[3] + "px";
        maskElement.style.left = windowLocation[2] + "px";
    }

    var popupIFrameElement = document.getElementById('ABOUTLINK_POP_UP_IFRAME');
    var popupElement = document.getElementById('aboutlink_pop_up');
    if (popupElement != null) {
        var leftPos = windowLocation[2] + (windowLocation[0] / 2) - 200;
        var topPos = windowLocation[3] + (windowLocation[1] / 2) - 200;
        popupElement.style.top  = topPos + "px";
        popupElement.style.left = leftPos + "px";

        //add for IE select Z-index problem
        if (navigator.appName == IE) {
            if (popupIFrameElement != null) {
                popupIFrameElement.style.top  = popupElement.style.top;
                popupIFrameElement.style.left = popupElement.style.left;
           }
        }
    }

    //show mask
    MM_showHideLayers('mask','','show');

    //Need to handle IE issues
    if (navigator.appName == IE) {
        disableSelectBoxes();
        disableTabIndexes();

        if (popupIFrameElement != null && popupElement != null) {
            //show iframe
            MM_showHideLayers('ABOUTLINK_POP_UP_IFRAME','','show');
        }
    }

    MM_showHideLayers('aboutlink_pop_up','','show');
}

function hideAbout(){
    MM_showHideLayers('aboutlink_pop_up','','hide');
    MM_showHideLayers('mask','','hide');

    //Need to handle IE issues
    if (navigator.appName == IE) {
        MM_showHideLayers('ABOUTLINK_POP_UP_IFRAME','','hide');

        enableSelectBoxes();
        enableTabIndexes();
    }
}

function reInitializeSessionTimeoutTimer(){
    if( window.cancelAutoRedirectToLoginPage ){
        window.cancelAutoRedirectToLoginPage();
    }
    if( window.initializeAutoRedirectToLoginPage ){
        window.initializeAutoRedirectToLoginPage();
	}
}

function selectRadio(form, radioName, radioValue)
{
    var nodes = form.elements[radioName];
    for(var i = 0; i < nodes.length; ++i)
    {
        if (nodes[i].value == radioValue)
        {
            nodes[i].checked = true;
            break;
        }
    }
}
