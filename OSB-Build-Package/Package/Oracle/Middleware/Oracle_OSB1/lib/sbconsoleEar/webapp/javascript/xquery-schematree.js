
/**
 * table of prefixes
 */
var prefixes = new Array();

/**
 * the list of tree node definitions
 * (parentId, prefixId, localName)
 */
var treenodes = new Array();

/*
 * id of the last variable selected
 */
var lastSelVarId = null;

/**
 * build the XPath for the given node.
 */
function getXPath(nodeId) {
    var parentId, prefixId;
    var name, prefix, attr="";

    // get data
    parentId = treenodes[nodeId][0];
    prefixId = treenodes[nodeId][1];
    name = treenodes[nodeId][2];
    if (treenodes[nodeId][3]) {
        attr = treenodes[nodeId][3];
    }

    // get local name
    if (prefixId != -1) {
        name = attr + prefixes[prefixId] + ":" + name;
    } else {
        name = attr + name;
    }

    // get full path
    if (parentId == -1) {
        return name;
    } else if (name == "") {
        return getXPath(parentId);
    } else {
        return getXPath(parentId) + "/" + name;
    }
}


/**
 * sets the XPath in the dataTransfer for drag&drop (IE only).
 */
function startDragXPath(id) {
    var text = getXPath(id);
    text = textForXpath( text );
    event.dataTransfer.setData("Text", text);
}


/**
 * call to display the selected path.
 * users need to implement the "showXPath0(text)" method
 */
function showXPath(id) {
    var elm = null;
    if ( id != null) {

        // change the background color of the last selection
        if ( lastSelVarId != null) {
            elm = document.getElementById(lastSelVarId);
            elm.bgColor="#FFFFFF"
        }

        // change the background color of the current selection
        elm  = document.getElementById(id);
        elm.bgColor = "#E0E0E0";

        // save the last selection
        lastSelVarId = id;

        var text = getXPath(id);
        text = textForXpath( text );
        showXPath0(text);
    }
}


function textForXpath( text ) {
    // FROM_XPATH_BUILDER is defined as global in utils.js and set in XPathBuilder.jsp
    // So, it is necessary to qualify the name with "parent."
    if ( parent.FROM_XPATH_BUILDER ) {
    	var index = text.indexOf('/');
    	if ( index == -1 )
    		text = ".";
    	else
    		text = '.' + text.substring(index);
    }
    return text;
}


/**
 * toggle a tree node
 */
function toggleTreeNode(imgId, blockId, toSubmit) {
    var image = document.getElementById(imgId);
    var block = document.getElementById(blockId);
	if (image.src.lastIndexOf("plus.gif") != -1) {
        block.style.display = "block";
        image.src = "/sbconsole/images/sb/icon_minus.gif";
        insertTreeNodeId(imgId, toSubmit);
    } else {
        block.style.display = "none";
        image.src = "/sbconsole/images/sb/icon_plus.gif";
        removeTreeNodeId(imgId);
    }
}

/**
 *  Insert the tree node id in the variable nodesToExpand
 *  the imageId passed will be in the following format:
 *       com.bea.wli.sb.xquery.schemma.tree.navimg.27
 *  We will retrieve last item in the above string which is the id. Here it is 27
 */
function insertTreeNodeId(imageId, toSubmit) {
    var index = imageId.lastIndexOf(".");
    var tempId = -1;
    if ( index != -1 ) {
        var id = imageId.substr(index + 1);
        tempId = id;
        if (parent.nodesToExpand != null && parent.nodesToExpand.length > 0 ) {
            id = "," + id;
            parent.nodesToExpand = parent.nodesToExpand + id;
        } else {
            parent.nodesToExpand = id;
        }
		if(toSubmit){
            var schemaTreeScrollX = 0;
            var schemaTreeScrollY = 0;
            var winLocation = getWindowLocation();
            if(winLocation){
                schemaTreeScrollX = winLocation[2];
                schemaTreeScrollY = winLocation[3];
            }
            var schemaTreeScrollXYPos = schemaTreeScrollX + ":" + schemaTreeScrollY;
            parent.onSubmitExpandCurrentMCVNode(tempId, schemaTreeScrollXYPos);
		}
    }
}

/**
 *  Remove the tree node id from the variable nodesToExpand
 *  the imageId passed will be in the following format:
 *       com.bea.wli.sb.xquery.schemma.tree.navimg.27
 *  We will retrieve last part in the above string which is the id. Here it is 27
 *
 */
function removeTreeNodeId(imageId) {
    if ( parent.nodesToExpand != null && parent.nodesToExpand.length > 0 ) {
        var index = imageId.lastIndexOf(".");
        if ( index != -1 ) {
            var id = imageId.substr(index + 1);

            // create an array of ids from nodesToExpand
            var idArray = parent.nodesToExpand.split(",");

            // create a new array by excluding the id to be removed from nodesToExpand
            var newArray = new Array();
            var j = 0;
            for ( var i = 0; i < idArray.length; i++ ){
                if ( idArray[i] != id ) {
                    newArray[j++] = idArray[i];
                }
            }

            // replace the nodesToExpand
            if ( newArray.length > 0 )
                parent.nodesToExpand = newArray.join(",");
            else
                parent.nodesToExpand = "";
        }
    }
}

function expandTreeNodes() {
    var theImage = null;
    var theBlock = null;
    var imagePrefix = "com.bea.wli.sb.xquery.schemma.tree.navimg.";
    var blockPrefix = "com.bea.wli.sb.xquery.schemma.tree.block.";
    if ( parent.nodesToExpand == null || parent.nodesToExpand.length == 0 ) {
        parent.nodesToExpand = "-1";
    }
    // create an array of ids from nodesToExpand
    var idArray = parent.nodesToExpand.split(",");
    for ( var i = 0 ; i < idArray.length; i++) {
        var id = idArray[i];
        if(id == -1)continue;
        theImage = document.getElementById(imagePrefix+id);
        theBlock = document.getElementById(blockPrefix+id);
        if (theImage.src.lastIndexOf("plus.gif") != -1) {
            theBlock.style.display = "block";
            theImage.src = "/sbconsole/images/sb/icon_minus.gif";
        }
    }

    if(parent.mcvTreeWindowPos != null && parent.mcvTreeWindowPos.length != 0 ){
        var xy = parent.mcvTreeWindowPos.split(":");
        if( window.scrollTo ){
            setTimeout('window.scrollTo('+xy[0] +','+ xy[1] +')', 1);
	    }
    }
}

/*
@todo : use getWindowLocation function from utils.js
It is too risky to refactor this code, We have to fix it in next release - saba 08/09/07
*/
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