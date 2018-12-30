
 /**
  * If a service is selected or unselected on import/publish page, all of its
  * items will be selected or unselected as well.
  */
 function selectServiceItems(cb, f, serviceKey) {
     var delim = ":@#"; //format is template key:parent key
     for(var i = 0; i < f.elements.length; i++){
         if(f.elements[i].type=="checkbox"){
             var str = f.elements[i].value;
             var myarray = str.split(delim);
             if(myarray.length>1){
                 if(myarray[1] == serviceKey){
                     f.elements[i].checked=cb.checked;
                 }
             }
         }
     }

 }

 function updateServiceFlag(cb, f, serviceKey) {
     var delim = ":@#"; //format is type:fullname
     var checkedFlag = true;

     //if the current item is unchecked, then its service should be unchecked;
     //no need to find out other items.
     //otherwise, find out if all of the service items are checked, if yes, then
     //service item should be checked.
     if (cb.checked == false) {
         checkedFlag = false;
     } else {
         for(var i = 0; i < f.elements.length; i++){
             if(f.elements[i].type=="checkbox"){
                 var str = f.elements[i].value;
                 var myarray = str.split(delim);
                 if(myarray.length>1){
                     if(myarray[1] == serviceKey){
                         if (f.elements[i].checked == false) {
                             checkedFlag = false;
                             break;
                         }
                     }
                 }
             }
         }
     }

     //find out service element and update its flag
     for(var i=0;i<f.elements.length;i++) {
         if (f.elements[i].type=="checkbox" && f.elements[i].value == serviceKey) {
             f.elements[i].checked = checkedFlag;
             break;
         }
     }
 }