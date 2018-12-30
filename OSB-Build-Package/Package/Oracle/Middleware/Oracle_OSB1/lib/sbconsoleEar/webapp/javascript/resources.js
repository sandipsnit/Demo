/********************************************************************************
 *
 *      This files contains java script for the XQuery transform and
 *      Schema resources.
 *
 *      this file needs the following javascript:
 *          -   utils.js
 *          -   functions.js
 *
 *******************************************************************************/


/********************************************************************************
 *          Common code
 *******************************************************************************/

/**
 * Fire an event to get the resource details.
 */
function getResourceDetails(resname, resvalue, url) {
    if (resvalue == null || resvalue == "") {
        return;
    }
    url = addUrlParameter(url, resname, resvalue);
    fireEvent(url);
}

/**
 * Fire an event to get the resource details.
 */
function submitAndGetResourceDetails(resname, resvalue, url){
    if (resvalue == null || resvalue == "") {
        return;
    }
    url = addUrlParameter(url, resname, resvalue);
    fireEvent(url);
}


/**
 * Display the description.
 */
function setResourceDescription(descr, nodeId) {

    // get new description
    descr = descr.split("\n");

    // get parent node
    var node = null
    if ( nodeId == null )
       node = document.getElementById('com.bea.wli.sb.resources.description');
    else
       node = document.getElementById(nodeId);
    DOM_removeChildren(node);
    for(var i = 0; i < descr.length; ++i) {
        DOM_addText(node, descr[i]);
        DOM_addChild(node, DOM_createElement('br'));
    }
}


/********************************************************************************
 *          Schema Resources
 *******************************************************************************/

/**
 * display the target namespace
 */
function setSchemaTargetNamespace(tns) {
    var node = document.getElementById('com.bea.wli.sb.resources.schema.targetNamespace');
    DOM_removeChildren(node);
    DOM_addText(node, tns);
    DOM_addChild(node, DOM_createElement('br'));
}


/**
 * display the list of types
 */
function setSchemaDefinitions(elts, types) {
    var node;

    // clean all options
    node = document.getElementById('com.bea.wli.sb.resources.schema.definitions');
    if ( node != null ) {
        while(node.options.length > 0) {
            node.options[node.options.length - 1] = null;
        }
    }

    // build new "element" options
    node = document.getElementById('com.bea.wli.sb.resources.schema.definitions.elements');
    if ( node != null ) {
        for(var i = 0; i < elts.length; ++i) {
            var option = buildSchemaOption(elts[i], 'element::');
            DOM_addChild(node, option);
        }
    }

    // build new "type" options
    node = document.getElementById('com.bea.wli.sb.resources.schema.definitions.types');
    if ( node != null ) {
        for(var i = 0; i < types.length; ++i) {
            var option = buildSchemaOption(types[i], 'type::');
            DOM_addChild(node, option);
        }
    }
}

function buildSchemaOption(name, scope) {
    var option = DOM_createElement('option');
    DOM_addText(option, name);
    DOM_addAttribute(option, 'value', scope + name);
    return option;
}


/********************************************************************************
 *          Wsdl Resources
 *******************************************************************************/

/**
 * display the target namespace
 */
function setWsdlTargetNamespace(tns) {
    var node = document.getElementById('com.bea.wli.sb.resources.wsdl.targetNamespace');
    DOM_removeChildren(node);
    DOM_addText(node, tns);
    DOM_addChild(node, DOM_createElement('br'));
}


/**
 * display the list of types
 */
function setWsdlDefinitions(portTypes, bindings, ports, elts, types) {
    var node;

    // clean all options
    node = document.getElementById('com.bea.wli.sb.resources.wsdl.definitions');
    while(node.options.length > 0) {
        node.options[node.options.length - 1] = null;
    }

    // build new "porttype" options
    node = document.getElementById('com.bea.wli.sb.resources.wsdl.definitions.porttypes');
    if (node != null) {
        for(var i = 0; i < portTypes.length; ++i) {
            var option = buildWsdlOption(portTypes[i], 'portType::' + portTypes[i]);
            DOM_addChild(node, option);
        }
    }

    // build new "bindings" options
    node = document.getElementById('com.bea.wli.sb.resources.wsdl.definitions.bindings');
    if (node != null) {
        for(var i = 0; i < bindings.length; ++i) {
            var option = buildWsdlOption(bindings[i], 'binding::' + bindings[i]);
            DOM_addChild(node, option);
        }
    }

    // build new "ports" options
    node = document.getElementById('com.bea.wli.sb.resources.wsdl.definitions.ports');
    if (node != null) {
        for(var i = 0; i < ports.length; ++i) {
            var option = buildWsdlOption(ports[i], 'port::' + ports[i]);
            DOM_addChild(node, option);
        }
    }

    // build new "element" options
    node = document.getElementById('com.bea.wli.sb.resources.wsdl.definitions.elements');
    if (node != null) {
        for(var i = 0; i < elts.length; ++i) {
            var option = buildWsdlOption(elts[i][0], 'element::' + elts[i][0] + ":" + elts[i][1]);
            DOM_addChild(node, option);
        }
    }

    // build new "type" options
    node = document.getElementById('com.bea.wli.sb.resources.wsdl.definitions.types');
    if (node != null) {
        for(var i = 0; i < types.length; ++i) {
            var option = buildWsdlOption(types[i][0], 'type::' + types[i][0] + ":" + types[i][1]);
            DOM_addChild(node, option);
        }
    }
}

function buildWsdlOption(name, value) {
    var option = DOM_createElement('option');
    DOM_addText(option, name);
    DOM_addAttribute(option, 'value', value);
    return option;
}
