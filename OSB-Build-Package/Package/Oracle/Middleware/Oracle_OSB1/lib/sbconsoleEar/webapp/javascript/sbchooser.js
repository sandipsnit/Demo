
//
// This function moves items from one chooser
// to the other, back and forth and the users
// request.
//

function swapItems(fromChooser,toChooser){

 if (fromChooser.selectedIndex == -1) return;

    var items = fromChooser.options.length;

    // Need to loop through all options to see if
    // selected, to enable multi-select
    for (i=0;i<items;i++){

      var fromItem = fromChooser.options[i]; // was 'i'

      if (fromItem.selected){
        var option = new Option(fromItem.text,fromItem.value,false,false);
        if (!checkForDuplicates(toChooser,option)){
            toChooser.options[toChooser.options.length] = option;
            //fromChooser.options[fromChooser.selectedIndex]=null;
            fromChooser.options[i]=null;
            // sortAndReplace(toChooser);
            items--;i--;
        }else{
            alert('Duplicate Exists');
        }
      }
      // if not selected do nothing
     }
 }

// utility method to move from Chosen to Available
function removeItem(fromChooser, toChooser, requiredColumns, message)
{
    if (fromChooser.selectedIndex == -1) return;
    var selectedCol = fromChooser.options[fromChooser.selectedIndex].value;
    if ( requiredColumns.indexOf(selectedCol) != -1 ) {
        alert(message);

    } else {
        swapItems( fromChooser, toChooser);
    }
}

function sortAndReplace(chooser){;
   var tempArray = new Array(chooser.options.length);
   for (var j=0;j<chooser.options.length;j++)
       tempArray[j] = chooser.options[j];
   tempArray.sort(compareOptions);
   for (var i=0;i<tempArray.length;i++){
        chooser.options[i] = new Option(tempArray[i].text,tempArray[i].value,false,false);
   }
}
function compareOptions(opt1,opt2){
  if (opt1.text < opt2.text) return -1;
  else if (opt1.text > opt2.text) return 1;
  else return 0;
}
function checkForDuplicates(targetChooser,option){
 var options = targetChooser.options;
 for (var i=0;i<options.length;i++){
     var anOption = options[i];
     if (anOption.text == option.text && anOption.value == option.value) return true;
 }
 return false;
}
function trackChanges(chooser,field){
  var newValue = '';
  for (var i=0;i<chooser.options.length;i++){
      newValue+=chooser.options[i].value+'\t';
  }
  field.value = newValue;
}

function moveUp(chooser){

  var sIndex = chooser.selectedIndex;

  if (sIndex == -1 || sIndex == 0) return;

  var tempOption = chooser.options[sIndex];
  var aboveOption = chooser.options[sIndex-1];

  //alert ("Need to swap " + tempOption.value + " with " + aboveOption.value);

  chooser.options[sIndex] = new Option(aboveOption.text,aboveOption.value,false,false);
  chooser.options[sIndex-1] = new Option(tempOption.text,tempOption.value,false,true);

}

function moveDown(chooser){

  var sIndex = chooser.selectedIndex;

  if (sIndex == -1 || sIndex == chooser.options.length -1 ) return;

  var tempOption = chooser.options[sIndex];
  var aboveOption = chooser.options[sIndex+1];

  //alert ("Need to swap " + tempOption.value + " with " + aboveOption.value);

  chooser.options[sIndex] = new Option(aboveOption.text,aboveOption.value,false,false);
  chooser.options[sIndex+1] = new Option(tempOption.text,tempOption.value,false,true);
}

function actionOverrideAndSubmit(formName, uri, newAction){
    var theform = document.forms[formName];
    var myregexp = new RegExp("actionOverride=[a-zA-Z/.]*");
    var newuri = uri.replace(myregexp, newAction);
    if(uri.indexOf("actionOverride") == -1){
      newuri += newAction;
     }
    if (theform != null) {
        theform.action = newuri;
        theform.submit();
    }
}

function actionOverrideAndSubmit(formName, uri, name, value){
    var theform = document.forms[formName];
    var myregexp = new RegExp(name +"=[a-zA-Z/.]*");
    var newuri = uri.replace(myregexp, value);
    if(uri.indexOf(name) == -1){
      submitFormWithParam(formName,name,value);
     }else{
      alert(newuri);
      if (theform != null) {
          theform.action = newuri;
          theform.submit();
      }
    }
}


function setFormActionAndSubmit(formName, newAction){
    var theform = document.forms[formName];
    if (theform != null) {
        theform.action = newAction;
    }
}

