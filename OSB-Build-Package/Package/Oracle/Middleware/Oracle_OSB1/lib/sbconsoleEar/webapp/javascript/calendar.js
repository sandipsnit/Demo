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
    function closeToggle(className) {
          var theTags       = document.getElementsByTagName('p');
                for (var i=0; i<theTags.length; i++){
                      if (theTags[i].className == className){
                            theTags[i].style.display = 'none';
                      }
                }
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
