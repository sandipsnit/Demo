var params="toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,";
var win,hwin;

function imgOn(image) {
    document[image].src = image + "_over.gif";
}

function imgOff(image) {
    document[image].src = image + ".gif";
}

function imgIdOn(id, image) {
    document[id].src = image + "_over.gif";
}

function imgIdOff(id, image) {
    document[id].src = image + ".gif";
}

function popup2(url,w,h,name) {
  if (w==null) w=500;
  if (h==null) h=350;
  if (name==null) name="popup";
  win = window.open(url,"name",params + "width=" + w+",height="+h);
  win.focus();
}

function openWindow(url, name) {
  if (name==null) name="popup";
  win=window.open(url,name);
  win.focus();
}

function popup(url,w,h,x,y,name) {
  if (w==null) w=500;
  if (h==null) h=350;
  if (name==null) name="popup";
  if (win==null || typeof(win != "object"))
    win=window.open(url,name,params + "width=" + w+",height="+h+",top="+y+",left="+x);
  else
    win.location.href=url;
  win.focus();
}

function loadInParent(url, closeSelf) {
  opener.location = url;
  if (closeSelf) {
    self.close();
    opener.focus();
  }
}

function cancel() {
  if (opener!=null) {
    self.close();
    opener.focus();
  }
}

function refreshmainwindow() {
// this will close the pop up window
alert("submitted");
window.close();
alert("closed");
// this will reload the parent window...
if (!window.opener.closed) {
alert("reloading");
window.opener.location.reload();
alert("focusing");
window.opener.focus();
}
}

function checkYear(e) {
  value=e.value;
  window.alert(value);
}

function submitForm(formId) {
    var theform = document.getElementById(formId);
    if (theform != null) {
        theform.submit();
    }
}
// This variable is used to avoid multiple submissions(multiple clicks on button) on page
var SUBMIT_FLAG = true;
function submitFormWithParam(formName, name, value) {
    var theform = document.forms[formName];
    if (theform != null && SUBMIT_FLAG) {
        if (unloadWarning.formname == formName) {
            onSubmitNoWarning();
        }
        theform.action = addUrlParameter(theform.action, name, value);
        theform.submit();
		// Reset submit_flag button
		SUBMIT_FLAG = false;
    }
}

function setActionAndSubmitForm(formName, url) {
    var theform = document.forms[formName];
    if (theform != null && SUBMIT_FLAG) {
        theform.action = url;
        theform.submit();
		// Reset submit_flag button
		SUBMIT_FLAG = false;
    }
}


function submitAndClose(url) {
  self.close();
  if (opener!=null){
    opener.location.href=url;
    opener.focus();
  }
}

/**
 * This is used by simple-table tag to pass the sortLinkUrl before submitting
 * the form.
 */
function submitWithUrl(formName, name, url, fieldId, param) {
    // CR355410
    // This function is always invoked via a link <A href="javascript:submitWithUr(...)">
    // IE triggers a "beforeunload" event TWICE when this link is clicked and executed. This is a known IE anomaly.
    // The first event is triggered in IE when the href is assigned the javascript URL (before it executes).
    // In contrast, Firefox does NOT trigger the "beforeunload" for an HREF with a javascript: URL.
    // Both browsers fire the "beforeunload" event when the javascript execution causes a real page unload.
    // If we get here in IE then the user has already seen the warning and responded OK to proceed with the HREF
    // otherwise this method was cancelled and we never get here.
    // For Firefox the "beforeunload" event is not triggered until after the javascript attempts to load the new URL.
    // The event handler is normally utils.js - unloadWarning() and will execute on f.submit().
    if (navigator.appName == IE) {
        unloadWarning.submitOk = true;
    }

    //this is used for goto page, user may click "Go" button to a page, we need to change the page num in the url
    if (fieldId && param) {
        var num = document.getElementById(fieldId);
        url = addUrlParameter(url, param, num.value);
    }
    
    var f = document.forms[formName];
    f.elements[name].value = url;
    f.submit();
}

function execNavLink(form) {
  window.location.href=form.navlinks.value;
}

function execTaskLink(baseurl, message, form) {
  if(message.length > 0) {
    if(verifySelection(form.tasklistid, message)) {
      //window.location.href=baseurl+"?"+form.tasklistid.value;
      return true;
    }
  }
  return false;
}

function submitURL (id, selectId) {
  var element = document.getElementById(id);
  var subElement = document.getElementById (selectId);
  subElement.value="true";
  element.submit();
}

function setLocation(url) {
  window.location.href=url;
}

function closeWin() {
  if(opener!=null) {
   opener.focus();
   self.close();
  } else {
    self.close();
  }
}

function help(url) {
  if(url==null)
    url="/sbconsole/html/adminhelp/index.htm";
  if (hwin==null || typeof(hwin != "object"))
    hwin=window.open(url,"helpwin",params+"700,height=500,top=25,left=25");
  else
    hwin.location.href=url;
  hwin.focus();
}

function verify(obj, msg) {
    var conf = confirm(msg);
    if (conf) {
       document.location.href = obj.href;
    }
}

function verify2(obj, msg, msg2) {
    var conf = confirm(msg);
    var param = obj.href;
    if (conf) {
        var conf2 = confirm(msg2);
        if(conf2){
            obj.document.cert.trmks.value = "true";
            param = param + "&trmks=true";
        }
        else{
            obj.document.cert.trmks.value = "false";
            param = param + "&trmks=false";
        }
       document.location.href = param;
    }
}


function selectAll(cb, f) {
    for(var i=0;i<f.elements.length;i++) {
        if (f.elements[i].type=="checkbox") {
			if( !f.elements[i].disabled) {
				f.elements[i].checked=cb.checked;
			}
        }
    }
}

function selectChildCheckBoxes(cb, f, childIpName) {
    for(var i=0;i<f.elements.length;i++) {
        if (f.elements[i].type=="checkbox") {
			if( !f.elements[i].disabled && f.elements[i].name == childIpName) {
				f.elements[i].checked=cb.checked;
			}
        }
    }
}

function checkIfBoxSelected (formname) {
    var bchk = false;
    var f = document.forms[formname];
    for(var i=0;i<f.elements.length;i++) {
        if (f.elements[i].type=="checkbox") {
            if( !f.elements[i].disabled) {
                if (f.elements[i].checked == true) {
                    bchk = true;
                    break;
                }
            }
        }
    }
    return bchk;
}

function selectAllBox(count) {
    if(count>0)
        document.write("<input type=\"checkbox\" name=\"selallcb\" onClick=\"selectAll(this,this.form);\">");
    else
        document.write("&nbsp;");
}

function selectAllCheckBox(count, allChkBoxName, enableFlag, title, childCheckBoxName) {
    if( count > 0 ) {
        if(!enableFlag){
            document.write("<input type=\"checkbox\" name=\""+allChkBoxName+"\"  title=\""+ title + "\" disabled='true' >");
        } else {
            document.write("<input type=\"checkbox\" name=\""+allChkBoxName+"\" title=\""+ title + "\" onClick=\"selectChildCheckBoxes(this, this.form, '"+childCheckBoxName+"' );\">");
        }
    } else {
        document.write("&nbsp;");
    }
}

/* updates entire column bgcolor based on header check box state */
function selectAllCheckBoxWithColsBgColorParams(count, allChkBoxName, enableFlag, title, childCheckBoxName, tableId, rowCount, colIndex) {
    if( count > 0 ) {
        if(!enableFlag){
            document.write("<input type=\"checkbox\" name=\""+allChkBoxName+"\"  title=\""+ title + "\" disabled='true' >");
        } else {
            document.write("<input type=\"checkbox\" name=\""+allChkBoxName+"\" title=\""+ title + "\" onClick=\"selectChildCheckBoxes(this, this.form, '"+childCheckBoxName+"' ); updateEntireColumnBgColor(this, this.form, '"+childCheckBoxName+"', '"+tableId+"', "+rowCount+", "+colIndex+");\">");
        }
    } else {
        document.write("&nbsp;");
    }
}

/* updates entire row bgcolor based on header check box state */
function selectAllCheckBoxWithRowsBgColorParams(rowCount, allChkBoxName, enableFlag, title, childCheckBoxName, tableId) {
    if( rowCount > 0 ) {
        if(!enableFlag){
            document.write("<input type=\"checkbox\" name=\""+allChkBoxName+"\"  title=\""+ title + "\" disabled='true' >");
        } else {
            document.write("<input type=\"checkbox\" name=\""+allChkBoxName+"\" title=\""+ title + "\" onClick=\"selectChildCheckBoxes(this, this.form, '"+childCheckBoxName+"' ); updateTableRowsBgColor(this, this.form, '"+childCheckBoxName+"', '"+tableId+"', "+rowCount+");\">");
        }
    } else {
        document.write("&nbsp;");
    }
}

/**
 * If any of the item is unchecked, then the allBox should be unchecked;
 * If all items are checked, then allcb checkbox should be checked.
 */
function updateAllBox(f, allcb) {

    if (f.elements[allcb] == null)
        return;

    var checkedFlag = true;
    var count = 0;
    for(var i=0;i<f.elements.length;i++) {
        if (f.elements[i].type=="checkbox" &&
                f.elements[i].name != allcb) {
            if ( f.elements[i].checked == false ) {
                checkedFlag = false;
                break;
            } else {
                count++;
            }
        }
    }
    if (count == 0) {
        //no checkbox found
        checkedFalg = false;
    }
    
    //update select all checkbox
    f.elements[allcb].checked = checkedFlag;
}

/**
 * If any of the item is unchecked, then the allBox should be unchecked;
 * If all items are checked, then allcb checkbox should be checked.
 */
function updateAllCheckBox(cb, f, allcb) {
    var checkedFlag = true;
    if(f.elements[allcb] == null) return false;
    if(cb.checked == false) {
        checkedFlag = false;
    } else {
         for(var i=0;i<f.elements.length;i++) {
             if (f.elements[i].type=="checkbox" &&
                 f.elements[i].name==cb.name &&
                 f.elements[i].name != allcb &&
                 f.elements[i].checked == false) {
                 checkedFlag = false;
                 break;
             }
         }
     }
     //update select all checkbox
     f.elements[allcb].checked = checkedFlag;
     return checkedFlag;
}


function updateSelectAllHeaderCheckBoxOnPageLoad(ipName, formName, allcb) {
    var childCb = document.getElementsByName(ipName)[0];
    if(!childCb) return;
    var theform = document.forms[formName];
    updateAllCheckBox(childCb, theform, allcb);
}


function verifySelection(f, message) {
    for(var i=0;i<f.form.elements.length;i++) {
        if (f.form.elements[i].type=="checkbox" && f.form.elements[i].name!="selallcb") {
            if (f.form.elements[i].checked==true)
                return true;
        }
    }
    window.alert(message);
    return false;
}

function verifySingleSelection(f, message) {
    var count = 0;
    for(var i=0;i<f.form.elements.length;i++) {
        if (f.form.elements[i].type=="checkbox" && f.form.elements[i].name!="selallcb") {
            if (f.form.elements[i].checked)
                count++;
        }
    }
    if (count == 0 || count > 1) {
        window.alert(message);
        return false;
    } else {
        return true;
    }
}

function verifyDelete(f, message, delmsg) {
    if (verifySelection(f, message))
        return confirm(delmsg);
    else
        return false;
}


// functions related to the chooser element
function cloneOption(option) {
  var out = new Option(option.text,option.value);
  out.selected = option.selected;
  out.defaultSelected = option.defaultSelected;
  return out;
}

function removeSelected(from) {
  for(i=from.options.length - 1; i >= 0; i--) {
    if (from.options[i].selected) {
       from.options[i] = null;
    }
  }
}



function shiftSelected(chosen,howFar) {
  var opts = chosen.options;
  var newopts = new Array(opts.length);
  var start; var end; var incr;
  if (howFar > 0) {
    start = 0; end = newopts.length; incr = 1;
  } else {
    start = newopts.length - 1; end = -1; incr = -1;
  }


  for(var sel=start; sel != end; sel+=incr) {
    if (opts[sel].selected) {
      setAtFirstAvailable(newopts,cloneOption(opts[sel]),sel+howFar,-incr);
    }
  }


  for(var uns=start; uns != end; uns+=incr) {
    if (!opts[uns].selected) {
      setAtFirstAvailable(newopts,cloneOption(opts[uns]),start,incr);
    }
  }


   opts.length = 0;
  for(i=0; i<newopts.length; i++) {
    opts[opts.length] = newopts[i];
  }
}

function setAtFirstAvailable(array,obj,startIndex,incr) {
  if (startIndex < 0) startIndex = 0;
  if (startIndex >= array.length) startIndex = array.length -1;
  for(var xxx=startIndex; xxx>= 0 && xxx<array.length; xxx += incr) {
    if (array[xxx] == null) {
      array[xxx] = obj;
      return;
    }
  }
}

function moveSelected(from,to) {

  newTo = new Array();
  for(i=from.options.length - 1; i >= 0; i--) {
    if (from.options[i].selected) {
      newTo[newTo.length] = cloneOption(from.options[i]);
      if (from.name.indexOf("noremove") == -1) {
          // we can remove this item from the "from" list
          from.options[i] = null;
      }
    }
  }


  for(i=to.options.length - 1; i >= 0; i--) {
    newTo[newTo.length] = cloneOption(to.options[i]);

    newTo[newTo.length-1].selected = false;
  }

  to.options.length = 0;

  for(i=newTo.length - 1; i >=0 ; i--) {
    to.options[to.options.length] = newTo[i];
  }
  selectionChanged(to,from);


  //var sorted = 'both';
  if (to.name.indexOf("sorted") >= 0)
  {
    sortOptions(to,"up");
  }
}

function presort(l) {
  if (l.name.indexOf("sorted") >= 0)  {
      sortOptions(l, "up");
      }
}


function updateHiddenChooserField(chosen,hidden) {
  hidden.value='';
  var opts = chosen.options;
  for(var i=0; i<opts.length; i++) {
    hidden.value = hidden.value + opts[i].value;
    if (i<opts.length-1) hidden.value = hidden.value + "\n";
  }
}



function selectionChanged(selectedElement,unselectedElement) {
  for(i=0; i<unselectedElement.options.length; i++) {
    unselectedElement.options[i].selected=false;
  }
  enableButton("movefrom_"+selectedElement.name,
               (selectedElement.selectedIndex != -1));
  enableButton("movefrom_"+unselectedElement.name,
               (unselectedElement.selectedIndex != -1));
  enableButton("moveup_" + selectedElement.name,
               (selectedElement.selectedIndex != -1));
  enableButton("movedown_" + selectedElement.name,
               (selectedElement.selectedIndex != -1));
  enableButton("moveup_"+unselectedElement.name,
               (unselectedElement.selectedIndex != -1));
  enableButton("movedown_"+unselectedElement.name,
               (unselectedElement.selectedIndex != -1));

}


function enableButton(buttonName,enable) {
  var img = document.images[buttonName];
  if (img == null) return;
  var src = img.src;
  var und = src.lastIndexOf("_disabled.gif");

  if (und != -1) {
    if (enable) img.src = src.substring(0,und)+".gif";
  } else {
    if (!enable) {
      var gif = src.lastIndexOf("_clicked.gif");
      if (gif == -1) gif = src.lastIndexOf(".gif");
      img.src = src.substring(0,gif)+"_disabled.gif";
    }
  }
}

function pushButton(buttonName,push) {
  var img = document.images[buttonName];
  if (img == null) return;
  var src = img.src;
  var und = src.lastIndexOf("_disabled.gif");
  if (und != -1) return false;
  und = src.lastIndexOf("_clicked.gif");

  if (und == -1) {
    var gif = src.lastIndexOf(".gif");
    if (push) img.src = src.substring(0,gif)+"_clicked.gif";
  } else {
      if (!push) img.src = src.substring(0,und)+".gif";
  }
}



function deleteOption(object,index) {
    object.options[index] = null;
}

function addOption(object,text,value) {
    var defaultSelected = false;
    var selected = false;
    var optionName = new Option(text, value, defaultSelected, selected)
    object.options[object.length] = optionName;
    object.options[object.length-1].selected = false;

}

function sortOptions(what,direction) {

	//disable the left button, cuz it would get really confused:
	//enableButton("movefrom_chosen_wl_control_weblogic.management.configuration.WebAppComponentMBean.Targets-Server",false);

    var copyOption = new Array();
    for (var i=0;i<what.options.length;i++)
    {
        copyOption[i] = new Array(what.options[i].value,what.options[i].text);
    }

	if (direction == "up")
	{
    	copyOption.sort(sortingFunctionUp);
    }
    else
    {
    	copyOption.sort(sortingFunctionDown);
    }

    for (var i=what.options.length-1;i>-1;i--)
        deleteOption(what,i);

    for (var i=0;i<copyOption.length;i++)
        addOption(what,copyOption[i][1],copyOption[i][0]);
}

function sortingFunctionUp(a,b)
{
	if (a[1] < b[1]) return -1;
	else if (a[1] > b[1]) return 1;
	else return 0;


}

function sortingFunctionDown(a,b)
{
	if (a[1] > b[1]) return -1;
	else if (a[1] < b[1]) return 1;
	else return 0;


}



function openInWindow( frm, instid, url ) {
   variableWindow = window.open( url, "new_id", 'toolbar=1,scrollbars=1,location=0,statusbar=0,menubar=0,resizable=1,width=750,height=550,left = 50,top = 50');
   return false;
}

// Move calendar rules and role condition rule up or down
// For calendar rules, ignoreFirstSelectionField must be false and
// for role condition rule, ignoreFirstSelectionField must be true.
function moveRules(formName, myLocation, direction, ignoreFirstSelectionField) {
  if (myLocation == 0 && direction == 0) return;

  if (myLocation == -1) return;

  var thisForm = document.forms[formName];
  var rows = 0; //caculate how many rules we have
  for (i=0; i < thisForm.elements.length; i++) {
      var e = thisForm.elements[i];
      if (e.name.search("rules_") == 0){
          rows++;
      }
  }

  var toLocation = (direction == 0) ? myLocation - 1 : myLocation + 1;

  if (toLocation < 0 || toLocation >= rows) return;

  //switch text
  var toTexField = thisForm.elements['rules_'+toLocation];
  var fromTexFiled = thisForm.elements['rules_'+myLocation]
  var tmpTextValue = toTexField.value;
  toTexField.value = fromTexFiled.value;
  fromTexFiled.value = tmpTextValue;

  //switch busy/free for calendar rule and and/or for role condition rule
  // For role condition rule, in condition, the command for the 1st element
  // in the condition does not mean anything.
  // When swich occurs between the 1st and 2nd items, the command of the 2nd item
  // should always preserved as the command of the 2nd item.  So do NOT switch
  if (!((ignoreFirstSelectionField) &&
      (((toLocation == 0) && (myLocation == 1)) || ((toLocation == 1) && (myLocation == 0))))) {
      var toSelectedField = thisForm.elements['list_' + toLocation];
      var fromSelectedField = thisForm.elements['list_' + myLocation];
      var tmpSelectValue = toSelectedField.value;
      toSelectedField.value = fromSelectedField.value;
      fromSelectedField.value = tmpSelectValue;
  }

  //switch hidden
  var toHiddenField = thisForm.elements['hidden_' + toLocation];
  var fromHiddenField = thisForm.elements['hidden_' + myLocation];
  var tmpHiddenValue = toHiddenField.value;
  toHiddenField.value = fromHiddenField.value;
  fromHiddenField.value = tmpHiddenValue;
}

function moveUpList(thisform, name) {
	var listField = thisform.elements[name];
	var myarray  = name.split('_');
	var hiddenfieldname = myarray[1];
	var hidden = thisform.elements[hiddenfieldname];
   if ( listField.length == -1) {  // If the list is empty
   } else {
      var selected = listField.selectedIndex;
      if (selected == -1) {
      } else {  // Something is selected
         if ( listField.length == 0 ) {  // If there's only one in the list
         } else {  // There's more than one in the list, rearrange the list order
            if ( selected == 0 ) {
            } else {
               // Get the text/value of the one directly above the hightlighted entry as
               // well as the highlighted entry; then flip them
               var moveText1 = listField[selected-1].text;
               var moveText2 = listField[selected].text;
               var moveValue1 = listField[selected-1].value;
               var moveValue2 = listField[selected].value;
               listField[selected].text = moveText1;
               listField[selected].value = moveValue1;
               listField[selected-1].text = moveText2;
               listField[selected-1].value = moveValue2;
               listField.selectedIndex = selected-1; // Select the one that was selected before
            }  // Ends the check for selecting one which can be moved
         }  // Ends the check for there only being one in the list to begin with
      }  // Ends the check for there being something selected
   }  // Ends the check for there being none in the list
   updateHiddenChooserField(listField, hidden);
}

function moveDownList(thisform, name) {
	var listField = thisform.elements[name];

	var myarray  = name.split('_');
	var hiddenfieldname = myarray[1];
	var hidden = thisform.elements[hiddenfieldname];

   if ( listField.length == -1) {  // If the list is empty
   } else {
      var selected = listField.selectedIndex;
      if (selected == -1) {
      } else {  // Something is selected
         if ( listField.length == 0 ) {  // If there's only one in the list
         } else {  // There's more than one in the list, rearrange the list order
            if ( selected == listField.length-1 ) {
            } else {
               // Get the text/value of the one directly below the hightlighted entry as
               // well as the highlighted entry; then flip them
               var moveText1 = listField[selected+1].text;
               var moveText2 = listField[selected].text;
               var moveValue1 = listField[selected+1].value;
               var moveValue2 = listField[selected].value;
               listField[selected].text = moveText1;
               listField[selected].value = moveValue1;
               listField[selected+1].text = moveText2;
               listField[selected+1].value = moveValue2;
               listField.selectedIndex = selected+1; // Select the one that was selected before
            }  // Ends the check for selecting one which can be moved
         }  // Ends the check for there only being one in the list to begin with
      }  // Ends the check for there being something selected
   }  // Ends the check for there being none in the list
   updateHiddenChooserField(listField, hidden);
}

function reloadPage(thisForm) {
    thisForm.submit();
}

//Used by editwfversioning.jsp to show date for the selection of service URI
function showDate(theForm, name, year, month,dayofMonth, hour, minute, second){
   var delim = "###";
   var str = theForm.elements[name].value;
   var mstr = str.split(delim);
   theForm.elements[year].value = mstr[0];
   theForm.elements[month].value = mstr[1];
   theForm.elements[dayofMonth].value = mstr[2];
   theForm.elements[hour].value = mstr[3];
   theForm.elements[minute].value = mstr[4];
   theForm.elements[second].value = mstr[5];
}


function enableDisable(form, enable, disable, enableStyle, disableStyle) {
    var enableArray = null;
    var disableArray = null;
    var i;
    if (enable != null && enable != "") {
      enableArray = enable.split(",");
      for (i = 0; i < enableArray.length; i++) {
          changeInputElement(form, enableArray[i], true, enableStyle);
      }
    }
    if (disable != null && disable != "") {
      disableArray = disable.split(",");
      for (i = 0; i < disableArray.length; i++) {
          changeInputElement(form, disableArray[i], false, disableStyle);
      }
    }
    return true;
}


function enableWhenChecked(checkboxelement, enable, enableStyle, disableStyle) {
    if (checkboxelement.checked == true) {
        // enable the input boxes if this checkbox is checked
        enableDisable(checkboxelement.form, enable, null, enableStyle, disableStyle);
    } else {
        // otherwise disable them
        enableDisable(checkboxelement.form, null, enable, enableStyle, disableStyle);
    }
}


function changeInputElement(form, paramName, enabled, style) {
  for (var i = 0; i < form.elements.length; i++) {
    var target = form.elements[i];
    if (target.name == paramName || target.name.indexOf(paramName + "_xsfx_") != -1) {
        if (enabled == false) {
            target.disabled = true;
        } else {
            target.disabled = false;
        }
        // target.className=style;
    }
  }
}

/**
 * Simple method which toggles the show/hide the specified element.
 */
function details(id)
{
    var node = document.getElementById(id);

    if (node != null)
    {
        if (node.style.display == "none" || node.style.display == "")
        {
            node.style.display = "block";
            node.style.visibility = "visible";
        }
        else
        {
            node.style.display = "none";
            node.style.visibility = "hidden";
        }
    }
}


/**
 * Used in a UI where changing a menu selection changes the follow up
 * input fields to be filled out by the user. For example, user selects
 * option A from a drop down which requires fields X, Y, Z. Option B
 * from the menu requires fields N, M. Depending on the menu selection
 * we will hide/display X, Y, Z and N, M. A collection of X, Y, Z fields
 * are referred to as a pane and are created by the <i:input-pane> tag.
 */
function togglePanes(menu, paneIds)
{
    // turn off all panes
    for (i = 0; i < paneIds.length; i++)
    {
        nodes = document.getElementsByName("input-pane-" + paneIds[i]);

        for (j = 0; j < nodes.length; j++)
        {
            nodes[j].style.display = "none";
            nodes[j].style.visibility = "hidden";
        }
    }

    // turn on selected pane
    nodes = document.getElementsByName("input-pane-" + menu.value);
    for (j = 0; j < nodes.length; j++)
    {
        nodes[j].style.display = "block";
        nodes[j].style.visibility = "visible";
    }
}


/**
 * turns on/off a pipeline display
 */
function pipelineDisplay(e, id)
{
    if (e != null)
    {
        p = document.getElementById(id);

        if (e.checked == true)
        {
            p.style.display = "block";
            p.style.visibility = "visible";
        }
        else
        {
            p.style.display = "none";
            p.style.visibility = "hidden";
        }
    }
}

function setFormParamById(formName, id, theValue) {
    var idNode = document.getElementById(id);
    idNode.value = theValue;

    var theform = document.forms[formName];
    theform.submit();
}

//This function doesnot submit the form
function setFormParam(formName, id, theValue) {
    var idNode = document.getElementById(id);
    idNode.value = theValue;
}

function updateselallcbOnLoad(formName){
     var checkedFlag = true;

	 // find whether all check boxes are selected
	 var theform = document.forms[formName];
     for(var i=0;i<theform.elements.length;i++) {
         if (theform.elements[i].type=="checkbox" &&
                 theform.elements[i].name != 'selallcb' &&
                 theform.elements[i].checked == false) {
             checkedFlag = false;
             break;
         }
     }

     //update select all checkbox
     theform.elements['selallcb'].checked = checkedFlag;

}


function toggleDiv (divId, linkId, visibleText, hiddenText, visiblegif, hiddenGif) {
  var obj = document.getElementById (divId);
  if (obj.style.visibility == 'visible') {
    obj.style.visibility = 'hidden';
    toggleText (linkId, hiddenText, hiddenGif);
  } else {
    obj.style.visibility = 'visible';
    toggleText (linkId, visibleText, visiblegif);
  }

}

function toggleText(linkId, toText, gifId, toGif) {
  var obj = document.getElementById (linkId);
  obj.innerText = toText;
}

function toggleText2(linkId, toText, gifId, toGif) {
  document.getElementById(linkId).innerHTML=toText;
}


// TODO: Need to rename as this function gets overwritten by the function with the same name with 5 arguments
function toggle( targetId ){
 if (document.getElementById){
            target = document.getElementById( targetId );
                  if (target.style.display == "none"){
                        target.style.display = "";
                  } else {
                        target.style.display = "none";
                  }
      }
}

function toggleTableCustomizer( targetId, showText, hideText, ajaxUrl ){
    if (document.getElementById){
        target = document.getElementById( targetId );
        var targetImage = document.getElementById(targetId + ".image");
        if (target.style.display == "none"){
            target.style.display = "";
            targetImage.title = hideText;
        } else {
            target.style.display = "none";
            targetImage.title = showText;
        }
        makeRequestToUpdateToggle(ajaxUrl);
    }
}

function toggleAddParamAndSubmit( formname, targetId ){
 if (document.getElementById){
            target = document.getElementById( targetId );
                  if (target.style.display == "none"){
                        target.style.display = "";
                        var actionurl = document.getElementById ('pageurl');
                        domainlog = document.getElementById ('domainlog');
                        domainlog.value= 'true';
                        setActionAndSubmitForm(formname,actionurl);
                  } else {
                        target.style.display = "none";
                  }
      }
}

function toggle( targetId, linkId, normalText, closeText, imageId ){
 if (document.getElementById){
            target = document.getElementById( targetId );
                  if (target.style.display == "none"){
                        target.style.display = "";
                        toggleText2(linkId, closeText, '', '');
                        toggleImage(imageId, false);
                  } else {
                        target.style.display = "none";
                        toggleText2(linkId, normalText, '', '');
                        toggleImage(imageId, true);
                  }
      }
}

function openLogSummary( show, targetId, linkId, closeText, imageId ){
alert(show);
 if (document.getElementById){
            target = document.getElementById( targetId );
                  if (show){
                  alert("Changing");
                        target.style.display = "";
                        toggleText(linkId, closeText, '', '');
                        toggleImage(imageId, false);
                  }else {
                        target.style.display = "none";
                  }
      }
}


function toggleAddParamAndSubmit( formname, targetId, linkId, normalText, closeText, imageId ){
 if (document.getElementById){
            target = document.getElementById( targetId );
                  if (target.style.display == "none"){
                        actionurl = document.forms[formname].WLIServerMonitoringpageurl;
                        domainlog = document.forms[formname].WLIServerMonitoringdomainlog;
                        domainlog.value= "true";
                        setActionAndSubmitForm(formname,actionurl.value);
                  } else {
                        target.style.display = "none";
                        actionurl = document.forms[formname].WLIServerMonitoringpageurl;
                        domainlog = document.forms[formname].WLIServerMonitoringdomainlog;
                        domainlog.value= "false";
                        setActionAndSubmitForm(formname,actionurl.value);
                  }
      }
}

function toggleImage(imageId, closed ){
    var image = document.getElementById (imageId);
    if(closed == true )
      image.src="images/arrow_next.gif";
    else
      image.src="images/arrow_down.gif";
}


function closeToggle(targetId) {
 if (document.getElementById){
            target = document.getElementById( targetId );
                        target.style.display = "none";
      }
}


function updateFlag(formName, deleteId){
      var fo = document.forms[formName];
      var d = fo.elements[deleteId];
      d.value ="false";
}

function updateAndConfirm( deleteId, message){
      alert("finding delete");
      var deleteFlag = document.getElementById (deleteId);
      alert(deleteFlag.value);
      deleteFlag.value= "true";
      return  confirm(message);
}

function validateDate(day, month, year, errorMsg)
{
      var leap = false;
      if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0))
        leap = true;

      if (leap == false && month == 1 && day > 28){
        alert(errorMsg);
        return false;
      }
      else if(leap == true && month == 1 && day > 29) {
        alert(errorMsg);
        return false;
      }
      else if ((month == 3 || month == 5 || month == 8 || month == 10) && day == 31) {
        alert(errorMsg);
        return false;
      }

      return true;
}

var TREE_SCROLL_X_POS;
var TREE_SCROLL_Y_POS;
var TREE_SCROLL_TO_ELEMENT_FLAG = false;
function setTreeViewScrollPosition(){
    var divElement = document.getElementById("submodules_div");
    if(divElement){
        if(TREE_SCROLL_TO_ELEMENT_FLAG){
            scrollToElement();
        }
        var xRef = divElement.scrollLeft;
		var yRef = divElement.scrollTop;
        if(TREE_SCROLL_X_POS && xRef < TREE_SCROLL_X_POS){
			divElement.scrollLeft = TREE_SCROLL_X_POS;
        }
        if(TREE_SCROLL_Y_POS && yRef < TREE_SCROLL_Y_POS){
            divElement.scrollTop = TREE_SCROLL_Y_POS;
        }
    }
}

var WIN_SCROLL_X_POS;
var WIN_SCROLL_Y_POS;
var CanSetWindowPositionsCookie = false;
function setWindowScrollPosition(){
	if(window.scrollTo && WIN_SCROLL_X_POS >= 0 && WIN_SCROLL_Y_POS >= 0){
		window.scrollTo(WIN_SCROLL_X_POS, WIN_SCROLL_Y_POS);
		return;
	}
	if(CanSetWindowPositionsCookie){
        setWindowScrollPositionFromCookie();
	}
}

/*
 * This funstions sets window position from cookie
 */
function setWindowScrollPositionFromCookie(){
	var x = readCookie('WINDOW_X_POS');
	var y = readCookie('WINDOW_Y_POS');
	var jspName = readCookie("WINDOW_JSP_ID");
	if(window.scrollTo){
        if(jspName && (typeof(jspId) != "undefined") && jspName == jspId && x != null && y != null){
            window.scrollTo(x, y);
        }
	}
}

/*
 * The following functions work with the expandable-table tag to expand/collapse the
 * individual rows in the table.
 */
 function openExpandableRow(id)
 {
     var img = document.getElementById(id + '.img');
     var content = document.getElementById(id + '.content');
     var stateParam = document.getElementById(id + '.state');
     img.src = '/sbconsole/images/sb/minus_box.gif';
     /* IE and Firefox don't have common display property - set to '' (remove none) to show */
     content.style.display = '';
     stateParam.value = 'expanded';
 }

 function closeExpandableRow(id)
 {
     var img = document.getElementById(id + '.img');
     var content = document.getElementById(id + '.content');
     var stateParam = document.getElementById(id + '.state');
     img.src = '/sbconsole/images/sb/plus_box.gif';
     content.style.display = 'none';
     stateParam.value = 'collapsed';
 }

 function toggleExpandableRow(id)
 {
     var content = document.getElementById(id + '.content');
     if (content.style.display == 'none') {
         openExpandableRow(id);
     } else {
         closeExpandableRow(id);
     }
 }

/*
 * This function is used to disable header check box and action button, if no child check box is available to check
 */
function updateHeaderCheckBoxAndButtonState(formName, childIpName, headerCheckBoxName, actionButtonName){
    var fo = document.forms[formName];
    var bDisabled = true;
    for(var i=0; i < fo.elements.length; i++) {
        if (fo.elements[i].type == "checkbox" && !fo.elements[i].disabled && fo.elements[i].name == childIpName) {
            bDisabled = false;
            break;
        }
    }
    if(bDisabled){
        var ipElement;
        ipElement = fo.elements[headerCheckBoxName];
        if(ipElement) ipElement.disabled = bDisabled;

        ipElement = fo.elements[actionButtonName];
        if(ipElement) ipElement.disabled = bDisabled;
    }
}

    function scrollToElementPosition(id) {
        var element = document.getElementById(id);
        if (element != null) {

            var curleft = curtop = 0;
            if (element.offsetParent) {
                curleft = element.offsetLeft;
                curtop = element.offsetTop;
                while (element = element.offsetParent) {
                    curleft += element.offsetLeft;
                    curtop += element.offsetTop;
                }
            }

            if (curleft >= 0 && curtop >= 0) {
                WIN_SCROLL_X_POS = curleft;
                WIN_SCROLL_Y_POS = curtop;
                setWindowScrollPosition();
            }
            return [curleft,curtop];
        } else {
            return [-1,-1];
        }
    }

var hasDependencyResList = new Array();
var resCount = 0;
function updateDependentResourceList(gName, fName) {
    hasDependencyResList[resCount++] = [gName, fName];
}

function submitWithConfirmDependentResource(fo, checkboxName, buttonName, msg) {
    var toSubmit = true;
    var hasDependentResources = false;
    if (hasDependencyResList.length > 0) {
        for(var i=0; i < fo.elements.length; i++) {
            var elm = fo.elements[i];
            if (elm.type == "checkbox" && !elm.disabled && elm.name == checkboxName && elm.checked) {
                for (var j=0; j<hasDependencyResList.length; j++) {
                    if (hasDependencyResList[j][0] == elm.value) {
                        hasDependentResources = true;
                        msg = msg + "\n" + hasDependencyResList[j][1];
                    }
                }
            }
        }
    }

    if (hasDependentResources) {
        toSubmit = confirm(msg);
    }

    if (toSubmit){
        fo.action = addUrlParameter(fo.action, buttonName, "true");
        fo.submit();
    }
}

function validateInteger(id, msg, min, max) {
    var intPattern = /^\d+$/;
    var node = document.getElementById(id);
    var val = node.value;
    if (isNaN(val) || !intPattern.test(val) || (min != null && parseInt(val) < parseInt(min)) || (max != null && parseInt(val) > parseInt(max))) {
        alert("'" + val + "' " + msg);
        node.focus();
        return false;
    } else {
        node.value = val;
        return true;
    }
}
