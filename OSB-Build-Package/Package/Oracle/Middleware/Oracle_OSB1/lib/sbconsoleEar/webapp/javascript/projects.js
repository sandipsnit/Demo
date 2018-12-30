/*
This function loads the page for the given url
*/
function loadResourcePage(obj){
    var url = obj.value;
    if(url == '0') return;   
    document.location.href = url;
}

function setProjectDesc(source, destination){
    var src = document.getElementById(source);
    var dest = document.getElementById(destination);
    if(!src && !dest) return;
    dest.innerHTML = src.innerHTML;
}

/*
  This function opens node in tree view and view the Project or Folder
*/
function ocAndViewProjectOrFolder(nodeId, nodeName, url){
    // CR331587, CR349690
    // This function is always invoked via a link <A href="javascript:ocAndViewProjectOrFolder(...)">
    // IE triggers a "beforeunload" event when this link is clicked (handler is utils.js unloadWarning() function), and
    // before the corresponding javascript is executed. Firefox does NOT trigger the "beforeunload" for the javascript.
    // If we get here in IE then the user has already responded OK to proceed and the href javascript continues here.
    // If the beforeunload warning is cancelled then the href link is not loaded and this function is not called.
    // For Firefox the "beforeunload" event is not triggered until after the javascript attempts to load the URL.
    if (navigator.appName == IE) {
        unloadWarning.submitOk = true;
    }

    url = addUrlParameter(url, "action", "expandNode");
    url = addUrlParameter(url, "nodeId", nodeId);
    url = addUrlParameter(url, "treePageContext", "project");
    if(window.addScrollPositionsToUrl){
        url = addScrollPositionsToUrl(url);
    }
    FireUrlHrefEvent(url);
}
