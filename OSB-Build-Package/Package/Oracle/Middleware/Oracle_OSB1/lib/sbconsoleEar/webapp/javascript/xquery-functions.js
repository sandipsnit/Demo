
/**
 * list of all the xquery function code.
 */
var xfnCodeTemplates;
var idPrefix = "com.bea.wli.sb.xquery.functions.block.";
var lastSelFnId = null;


/**
 * display the xquery function code in the view area.
 */
function showXfnCode(id) {
    var elm = null;
    if ( id != null) {

        // change the background color of the last selection
        if ( lastSelFnId != null) {
            elm = document.getElementById(lastSelFnId);
            elm.bgColor="#FFFFFF"
        }

        // change the background color of the current selection
        var curSelId = idPrefix+id;
        elm  = document.getElementById(curSelId);
        elm.bgColor = "#E0E0E0";

        // save the last selection
        lastSelFnId = curSelId;

        // display the contents in the property inspector
        var text = xfnCodeTemplates[id];
        parent.showXfnCode(text);
    }
}


/**
 * toggle the function category or sub-category
 */
function toggleXfnCategory(imgId, blockId) {
    var image = document.getElementById(imgId);
    var block = document.getElementById(blockId);
    if (image.src.lastIndexOf("plus.gif") != -1) {
        block.style.display = "block";
        image.src = "/sbconsole/images/sb/icon_minus.gif";
    } else {
        block.style.display = "none";
        image.src = "/sbconsole/images/sb/icon_plus.gif";
    }
}


/**
 * sets the function xquery code in the dataTransfer for drag&drop (IE only).
 */
function xfnStartDrag(id) {
    var text = xfnCodeTemplates[id];
    event.dataTransfer.setData("Text", text);
}
