function initSkin()
{
    // We have disabled the Portal menus in the wliconsole skin. 
    // So need to comment out the initialization of dynamic menus.
    // initDynamicMenus();
    
    initRolloverMenus();
    initPortletDeleteButtons();
    // See the comments in float.js about this function...
    //initPortletFloatButtons();

    // set scrollbar position tree view after the page load
    setTreeViewScrollPosition();

    // set window position
    setWindowScrollPosition();

    // general onload processing
    if (typeof bodyOnLoad == "function") {
        bodyOnLoad();
    }
}
