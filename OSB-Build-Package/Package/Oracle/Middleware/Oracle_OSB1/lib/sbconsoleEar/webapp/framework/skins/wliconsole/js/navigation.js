
/**
 * These functions are used to maintain the selected modules and sub-modules
 * in the navigation pane of the sbconsole.
 */


 /**
 * Function to pass the selected module/sub-module to server for refreshing navigation pane.
 */
function loadPortlet( mod_id, submod_id, url ) {

	url = url + '&selmodule=' + mod_id + '&selsubmodule=' + submod_id;
    try {
        document.location.href = url;
    } catch(err) {
        // Do nothing - could be user cancellation of unload confirmation dialog
    }

    
}

/**
 * Function to toggle the modules div.
 */
function toggleModules() {
	var modulesObj = document.getElementById("modules_div");

	if ( modulesObj.style.visibility == 'visible' ) {
		modulesObj.style.visibility = 'hidden';
		document.all.submodules_div.style.height = "547px";
		document.all.modules_div.style.height = "1px";
		document.all.nav_toggle.src = '/sbconsole/images/sb/nav_open.jpg';
		document.all.nav_toggle.title = 'Click to show navigation buttons';
		moduleToggle = 0;
	} else {
		modulesObj.style.visibility = 'visible';
		document.all.submodules_div.style.height = "380px";
		document.all.modules_div.style.height = "167px";
		document.all.nav_toggle.src = '/sbconsole/images/sb/nav_close.jpg';
		document.all.nav_toggle.title = 'Click to hide navigation buttons';
		moduleToggle = 1;
	}
	
}
