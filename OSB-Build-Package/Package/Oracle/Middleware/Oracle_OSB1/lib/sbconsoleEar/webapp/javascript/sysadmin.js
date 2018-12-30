
/**
 * If a project is selected or unselected on import/export page, all of its
 * items will be selected or unselected as well. The sub item format is
 * type:fullname, and the first part of the fullname is its project name
 */
function selectProjectItems(cb, f, projName) {
    var delim = ":"; //format is type:fullname
    for(var i=0;i<f.elements.length;i++) {
        if (f.elements[i].type=="checkbox") {
            var str = f.elements[i].value;

            //take out type
            var myarray = str.split(delim);
            if (myarray.length > 1) {
                var itemName = myarray[1]; //item's full name
                //itemName starts with default name
                myarray = itemName.split("/");
                if (myarray[0] == projName) {
                    f.elements[i].checked=cb.checked;
                }
            }
        }
    }
}

function updateProjectFlag(cb, f, projName) {
    var projValue = "Project:" + projName;
    var delim = ":"; //format is type:fullname
    var checkedFlag = true;

    //if the current item is unchecked, then its project should be unchecked;
    //no need to find out other items.
    //otherwise, find out if all of the project items are checked, if yes, then
    //project item should be checked.
    if (cb.checked == false) {
        checkedFlag = false;
    } else {
        // find other items in the project
        for(var i=0;i<f.elements.length;i++) {
            if (f.elements[i].type=="checkbox" && f.elements[i].value != projValue) {
                var str = f.elements[i].value;

                //take out type
                var myarray = str.split(delim);
                if (myarray.length > 1) {
                    var itemName = myarray[1]; //item's full name
                    //itemName starts with default name
                    myarray = itemName.split("/");
                    if (myarray[0] == projName) {
                        if (f.elements[i].checked == false) {
                            checkedFlag = false;
                            break;
                        }
                    }
                }
            }
        }
    }

    //find out project element and update its flag
    for(var i=0;i<f.elements.length;i++) {
        if (f.elements[i].type=="checkbox" && f.elements[i].value == projValue) {
            f.elements[i].checked = checkedFlag;
            break;
        }
    }
}

function updateImportExportAllFlag(cb, f, allcb, envvars, opvalues, secsettings, credentials, acls, includeDep) {
    var checkedFlag = true;
    //if the current item is unchecked, then the allBox should be unchecked;
    //no need to find out other items.
    //otherwise, find out if all other items are checked, if yes, then
    //allcb checkbox should be checked.
    if (cb.checked == false) {
        checkedFlag = false;
    } else {
        // find all items in all projects exclude includeDep and envars checkboxes
        for(var i=0;i<f.elements.length;i++) {
            var e = f.elements[i];
            if (e.type=="checkbox" && e.name != allcb &&
                    e.name != envvars &&
                    e.name != opvalues &&
                    e.name != secsettings &&
                    e.name != credentials &&
                    e.name != acls &&
                    e.name != includeDep &&
                    e.checked == false) {
                checkedFlag = false;
                break;
            }
        }
    }

    //update select all checkbox
    f.elements[allcb].checked = checkedFlag;
}

/**
 * Update all items flage except preserve env vars, operation values and include dependences
*/
function updateAllItems(cb, f, envvars, opvalues, secvalues, credvalues, aclvalues, includeDep) {
    for(var i=0;i<f.elements.length;i++) {
        if (f.elements[i].type=="checkbox") {
			if( !f.elements[i].disabled && f.elements[i].name != envvars &&
                f.elements[i].name != opvalues &&
                f.elements[i].name != secvalues &&
                f.elements[i].name != credvalues &&
                f.elements[i].name != aclvalues &&
                f.elements[i].name != includeDep) {
				f.elements[i].checked=cb.checked;
			}
        }
    }
}
