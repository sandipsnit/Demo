/**
 * true if IE
 */
function isIE() {
    return navigator.appName == "Microsoft Internet Explorer";
}

/********************************************************************************
 *          XQuery Function Handling
 *******************************************************************************/

/**
 * display the xquery function code in the view area.
 */
function showXfnCode(text) {
    var input = document.getElementById("xquery.editor.property.inspector");
    if ( input != null )
        input.value = text;
}

/********************************************************************************
 *          Variable Type Handling
 *******************************************************************************/

/**
 *  callback call to set the variable xpath
 */
function setVariableXPath(xpath) {
    var input = document.getElementById("xquery.editor.property.inspector");
    if ( input != null )
        input.value = xpath;
}

/**
 * variable to hold the condition expression selected for editing/deleting
 */
var condSelectedExpr = null;

/**
 * select the cond expression
 */
function selectCondExpr(id, canUpdate) {
    var node = document.getElementById("com.bea.wli.sb.xquery.view.cond.expr." + id);
    if (condSelectedExpr != null) {
        condSelectedExpr.bgColor = 'white';
        condSelectedExpr = null;
    }

    condSelectedExpr = node;
    condSelectedExpr.bgColor = '#FFC993';

    var input = document.getElementById('com.bea.wli.sb.xquery.view.cond.expr.selected');
    input.value = id;

    if (canUpdate) {
		var divElem = document.getElementById("plain.image.div");
		divElem.style.display="none";
		divElem = document.getElementById("anchor.image.div")
		divElem.style.display="block";

    } else {
		var divElem = document.getElementById("anchor.image.div");
		divElem.style.display="none";
		divElem = document.getElementById("plain.image.div")
		divElem.style.display="block";
    }
}

/**
 * Functions for new xquery expression builder
 */

function PrefixNamespacePair( prefix, namespace )
{
    this.prefix = prefix;
    this.namespace = namespace;

    this.getPrefix = getPrefix;
    this.getNamespace = getNamespace;
}

function getPrefix()
{
    return this.prefix;
}

function getNamespace()
{
    return this.namespace;
}

function prefixExists( pairArray, prefix )
{
    for ( var i = 0; i < pairArray.length; i++ )
    {
        if ( pairArray[i].getPrefix() == prefix )
        {
            return true;
        }
    }
    return false;
}

function namespaceAlreadyDefined( pairArray, namespace )
{
    for ( var i = 0; i < pairArray.length; i++ )
    {
        if ( pairArray[i].getNamespace() == namespace )
        {
            return true;
        }
    }
    return false;
}

function getMappedPrefixes( pairArray, namespace )
{
    var prefixes = "";
    for ( var i = 0; i < pairArray.length; i++ )
    {
        if ( pairArray[i].getNamespace() == namespace )
        {
            if ( prefixes.length > 0 )
                prefixes = prefixes + ", " + pairArray[i].getPrefix();
            else
                prefixes = pairArray[i].getPrefix();
        }
    }
    return prefixes;
}


