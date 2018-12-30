/*
  Copyright (c) 2000-2004 BEA Systems, Inc.
  All rights reserved

  THIS IS UNPUBLISHED PROPRIETARY
  SOURCE CODE OF BEA Systems, Inc.
  The copyright notice above does not
  evidence any actual or intended
  publication of such source code.
*/

/* $Id: //depot/dev/src_xbus/wli/xbus/common/oam/console/webapp/javascript/services.js#1 $ */

/**
 *  This finds the first checkbox that is checked in the collection of elements.
 *  It returns the name and value as a URL parameter (?name=value).
 *  If nothing is checked then it defaults to the first checkbox.
 */
function getFirstChecked( collection ) {
    var param = "";
    for(var i=0; i<collection.length; i++) {
        var checkbox = collection[i];
        // default to first checkbox
        if (i==0) {
            param = checkbox.name + "=" + checkbox.value;
        }
        if (checkbox.checked) {
            param = checkbox.name + "=" + checkbox.value;
            break;
        }
    }
    return param;
}

/**
 * Modifies the given anchor by appending a URL parameter retrieved from an
 * input checkbox. This is used to create a link associated with a table that
 * has multiple checkboxes with the same name. The first one in the table that
 * is checked is used for the link. If none are checked then the first one is
 * used.
 */
function linkFirstChecked( anchor, cbName ) {
    var collection = document.getElementsByName(cbName);
    if (collection.length == 0) {
        anchor.removeAttribute("href");
    } else {
        anchor.href += "?" + getFirstChecked(collection);
    }
}