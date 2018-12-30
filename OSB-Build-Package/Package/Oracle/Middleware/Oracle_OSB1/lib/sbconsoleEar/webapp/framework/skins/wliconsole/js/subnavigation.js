
/**
 * These functions are used to maintain the selected modules and sub-modules
 * in the navigation pane of the sbconsole.
 */


/**
 * Function to pass the selected module/sub-module to server for refreshing navigation pane.
 */
function loadPortlet( mod_id, submod_id, url ) {

	url = url + '&selmodule=' + mod_id + '&selsubmodule=' + submod_id;
	document.location.href = url;
    
}