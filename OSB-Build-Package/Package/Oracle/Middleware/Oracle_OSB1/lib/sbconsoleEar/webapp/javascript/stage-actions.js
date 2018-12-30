
/********************************************************************************
 *          xquery condition/expression Handling
 *******************************************************************************/

/**
 * few constants as references to the HTML
 */
var CST_CONDITION_FORM  = "com.bea.wli.sb.stages.actions.condition.form";
var CST_EXPR_FORM       = "com.bea.wli.sb.stages.actions.expr.form";
var CST_WSCALLOUT_FORM  = "com.bea.wli.sb.stages.actions.wscallout.form";
var CST_ERROR_FORM      = "com.bea.wli.sb.stages.actions.error.form";
var CST_FORM_CANCEL     = ".cancel";
var CST_FORM_SUBMIT     = ".submit";
var CST_FORM_CFG        = ".cfg";


/**
 * used to sets the configuration data of the condition to edit.
 */
function editXqueryCondition(id) {
    var nodeFrom, nodeTo;

    nodeFrom = document.getElementById(id + CST_FORM_CANCEL);
    nodeTo = document.getElementById(CST_CONDITION_FORM + CST_FORM_CANCEL);
    nodeTo.value = nodeFrom.value;

    nodeFrom = document.getElementById(id + CST_FORM_SUBMIT);
    nodeTo = document.getElementById(CST_CONDITION_FORM + CST_FORM_SUBMIT);
    nodeTo.value = nodeFrom.value;

    nodeFrom = document.getElementById(id + CST_FORM_CFG);
    nodeTo = document.getElementById(CST_CONDITION_FORM + CST_FORM_CFG);
    nodeTo.value = nodeFrom.value;

    submitForm(CST_CONDITION_FORM);
}

function buildXqueryCondition(id, cmd) {
    editXqueryCondition(id);

    var cmdIdNode = document.getElementById("com.bea.wli.sb.stages.routing.cmdid");
    cmdIdNode.value = cmd;

    var form = document.forms[0];
    form.submit();
}


/**
 * used to sets the configuration data of the expression to edit.
 */
function editXqueryExpr(id) {
    var nodeFrom, nodeTo;

    nodeFrom = document.getElementById(id + CST_FORM_CANCEL);
    nodeTo = document.getElementById(CST_EXPR_FORM + CST_FORM_CANCEL);
    nodeTo.value = nodeFrom.value;

    nodeFrom = document.getElementById(id + CST_FORM_SUBMIT);
    nodeTo = document.getElementById(CST_EXPR_FORM + CST_FORM_SUBMIT);
    nodeTo.value = nodeFrom.value;

    nodeFrom = document.getElementById(id + CST_FORM_CFG);
    nodeTo = document.getElementById(CST_EXPR_FORM + CST_FORM_CFG);
    nodeTo.value = nodeFrom.value;

    submitForm(CST_EXPR_FORM);
}
/**
 * used to sets the configuration data of the WS-Callout to edit.
 */
function editWsCalloutAndSubmitForm(id, url) {
    var nodeFrom, nodeTo;

    var CST_FORM_WS_ACTION_ID = ".wsactionid";

    nodeFrom = document.getElementById(id + CST_FORM_CANCEL);
    nodeTo = document.getElementById(CST_WSCALLOUT_FORM + CST_FORM_CANCEL);
    nodeTo.value = nodeFrom.value;

    nodeFrom = document.getElementById(id + CST_FORM_SUBMIT);
    nodeTo = document.getElementById(CST_WSCALLOUT_FORM + CST_FORM_SUBMIT);
    nodeTo.value = nodeFrom.value;

    nodeFrom = document.getElementById(id + CST_FORM_CFG);
    nodeTo = document.getElementById(CST_WSCALLOUT_FORM + CST_FORM_CFG);
    nodeTo.value = nodeFrom.value;

    nodeFrom = document.getElementById(id + CST_FORM_WS_ACTION_ID);
    nodeTo = document.getElementById(CST_WSCALLOUT_FORM + CST_FORM_WS_ACTION_ID);
    nodeTo.value = nodeFrom.value;

    var theform = document.getElementById(CST_WSCALLOUT_FORM);
    theform.action = url;
    submitForm(CST_WSCALLOUT_FORM);
}
/**
 * used to sets the configuration data of the Error to edit.
 */
function editErrorAndSubmitForm(id, url) {
    var nodeFrom, nodeTo;
    var CST_FORM_ERROR_ACTION_ID = ".erroractionid";

    nodeFrom = document.getElementById(id + CST_FORM_CANCEL);
    nodeTo = document.getElementById(CST_ERROR_FORM + CST_FORM_CANCEL);
    nodeTo.value = nodeFrom.value;

    nodeFrom = document.getElementById(id + CST_FORM_SUBMIT);
    nodeTo = document.getElementById(CST_ERROR_FORM + CST_FORM_SUBMIT);
    nodeTo.value = nodeFrom.value;

    nodeFrom = document.getElementById(id + CST_FORM_CFG);
    nodeTo = document.getElementById(CST_ERROR_FORM + CST_FORM_CFG);
    nodeTo.value = nodeFrom.value;

    nodeFrom = document.getElementById(id + CST_FORM_ERROR_ACTION_ID);
    nodeTo = document.getElementById(CST_ERROR_FORM + CST_FORM_ERROR_ACTION_ID);
    nodeTo.value = nodeFrom.value;

    var theform = document.getElementById(CST_ERROR_FORM);
    theform.action = url;
    submitForm(CST_ERROR_FORM);
}


/**
 * submit the given form
 */
function submitForm(formId) {
    var theform = document.getElementById(formId);
    if (theform != null) {
        theform.submit();
    }
}


/********************************************************************************
 *          drag & drop  handling
 *******************************************************************************/

/**
 * few constants as references to the HTML
 */
var CST_SEPARATOR_ICON          = "/sbconsole/images/sb/stageactions_target.gif";
var CST_SEPARATOR_ICON_OVER     = "/sbconsole/images/sb/stageactions_target_over.gif";
var CST_RECYCLEBIN_ICON         = "/sbconsole/images/sb/trash.gif";
var CST_RECYCLEBIN_ICON_OVER    = "/sbconsole/images/sb/trash.gif";

var CST_SUFFIX_HIDDEN           = ".hidden";
var CST_PARAM_SRC               = "dragSrc";
var CST_PARAM_TARGET            = "dragTarget";
var CST_PARAM_COPY              = "dragCopy";


/**
 * variables used for the dragging algorithm
 */
var _dragapproved = false
var _dragObject = null;
var _orgOnmousemove = null;
var _dragOffX, _dragOffY, _dragX, _dragY;


/**
 * the list of targets, and drop url.
 * those values must be set by the enclsing HTML
 */
var _targets = new Array();
var _recyclebin = null;
var _dropUrl;

/**
 * the selected drop target
 */
var _selectedTarget = null;


/**
 *
 */
function startDrag()
{
    // check a DND is valid
    if (event.srcElement.className != "draggable") {
        return;
    }

    // set drag object visible
    _dragObject = document.getElementById(event.srcElement.id + ".hidden");
    _dragObject.style.visibility = "visible";
    _dragObject.style.display="block";

    // get its original offset to the mouse pointer
    _dragObject.style.posLeft = event.srcElement.offsetLeft;
    _dragObject.style.posTop = event.srcElement.offsetTop;

    _dragOffX = _dragObject.style.posLeft;
    _dragOffY = _dragObject.style.posTop;
    _dragX = event.clientX;
    _dragY = event.clientY;

    // turn on all drop target
    show_targets();

    // remember document function
    _orgOnmousemove = document.onmousemove;
    document.onmousemove = doDrag;

    // let's DND
    _dragapproved = true;
}


/**
 *
 */
function doDrag()
{
    var X1, Y1, W1, H1;
    var X3, Y3, X4, Y4;

    // make sure we are DNDing
    if (!_dragapproved) {
        return;
    }

    // move target to current position
    _dragObject.style.posLeft = _dragOffX + event.clientX - _dragX;
    _dragObject.style.posTop = _dragOffY + event.clientY - _dragY;

    // drag object bounding box
    X1 = _dragObject.style.posLeft;
    Y1 = _dragObject.style.posTop;
    W1 = _dragObject.offsetWidth;
    H1 = _dragObject.offsetHeight;

    // get selected drop target
    _selectedTarget = null;
    for(var i = 0; i < _targets.length; ++i) {
        var node = _targets[i];

        // drop target bounding box
        X2 = node.offsetLeft;
        Y2 = node.offsetTop;
        W2 = node.offsetWidth;
        H2 = node.offsetHeight;

        // handle based on intersection with source
        if (intersects(X1, Y1, W1, H1, X2, Y2, W2, H2)) {
            targetOn(node);
            _selectedTarget = node;
        } else {
            targetOff(node);
        }
    }

    // check recycle bin
    X2 = _recyclebin.offsetLeft;
    Y2 = _recyclebin.offsetTop;
    W2 = _recyclebin.offsetWidth;
    H2 = _recyclebin.offsetHeight;
    if (intersects(X1, Y1, W1, H1, X2, Y2, W2, H2)) {
        targetOn(_recyclebin);
        _selectedTarget = _recyclebin;
    } else {
        targetOff(_recyclebin);
    }


    // prevent default behaviour
    return false;
}

function intersects(X1, Y1, W1, H1, X2, Y2, W2, H2) {
    if (X2 > X1 + W1 || X2 + W2 < X1 || Y2 > Y1 + H1 || Y2 + H2 < Y1) {
        return false;
    } else {
        return true;
    }
}


/**
 *
 */
function endDrag() {
    var dragSrc, dragTarget;

    // make sure we were DNDing
    if (_dragapproved == false) {
        return;
    }
    _dragapproved = false;

    // keep drag info before reset
    dragSrc = _dragObject;
    dragTarget = _selectedTarget;

    // reset document function
    document.onmousemove = _orgOnmousemove;

    // reset drag source
    _dragObject.style.visibility = "hidden";
    _dragObject.style.display    = "none";
    _dragObject = null;

    // reset _targets
    hide_targets();
    if (_selectedTarget != null) {
        targetOff(_selectedTarget);
        _selectedTarget = null;
    }

    // now execute the drop action
    if (dragTarget != null ) {
        var url = _dropUrl;
        var src = dragSrc.id;
        var target = dragTarget.id;
        var isCopy = event.ctrlKey == true;

        url += "&" + CST_PARAM_SRC + "=" + src.substring(0, src.length - CST_SUFFIX_HIDDEN.length);
        url += "&" + CST_PARAM_TARGET + "=" + target;
        if (isCopy) {
            url += "&" + CST_PARAM_COPY + "=true";
        }
        window.location.href = url;
    }
}


/**
 * show all _targets
 */
function show_targets() {
    for (var i = 0; i < _targets.length; i++) {
        if (_targets[i].className == "dragTargetHidden") {
            _targets[i].style.display = "block";
            _targets[i].src = CST_SEPARATOR_ICON;
        }
    }
}

/**
 * hide all _targets
 */
function hide_targets() {
    for (var i = 0; i < _targets.length; i++) {
        if (_targets[i].className == "dragTargetHidden") {
            _targets[i].style.display = "none";
        }
    }
}

/**
 * turn on target
 */
function targetOn(node) {
    if (node == _recyclebin) {
        _recyclebin.src = CST_RECYCLEBIN_ICON_OVER;
    } else {
        node.src = CST_SEPARATOR_ICON_OVER;
    }
}

/**
 * turn off target
 */
function targetOff(node) {
    if (node == _recyclebin) {
        _recyclebin.src = CST_RECYCLEBIN_ICON;
    } else {
        node.src = CST_SEPARATOR_ICON;
    }
}
