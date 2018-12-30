#!/bin/sh
#
#
#    NAME
#    agentdeployroot.sh - root.sh script for agentpush  install

STATEDIR_R_OH=$1
CUT=/usr/bin/cut
#check if user is root or not
ID=`id|$CUT -f2 -d"("|$CUT -f1 -d")"`
if [ "$ID" != "root" ]
then
        echo "Please login as root and then execute the script" 
	exit 1;
fi

homeDir=$HOME
if [ -f  $STATEDIR_R_OH/oraInst.loc ]
then
	echo "${STATEDIR_R_OH}/oraInst.loc exists"
	ORAINVENTORY=`grep '^inventory_loc' $STATEDIR_R_OH/oraInst.loc | $CUT -c15-`
	ORAINSTROOT=$ORAINVENTORY/orainstRoot.sh 
else
	echo "${STATEDIR_R_OH}/oraInst.loc does not exist"
fi

ORAINSTLOC=/etc/oraInst.loc


calculateOS()
{
    platform=`uname -s`

    case "$platform"
    in
       "SunOS")  ORAINSTLOC="/var/opt/oracle/oraInst.loc"
                 os=solaris;;
       "Linux")  os=linux;;
       "HP-UX")  os=hpux;;
         "AIX")  os=aix;;
             *)  echo "Sorry, $platform is not currently supported." | tee -a $LogFile
                 echo "Sorry, $platform is not currently supported. \n"
                 exit 1;;
    esac

    echo "Platform: $platform" | tee -a $LogFile
    echo "Platform: $platform \n"


}

calculateOS

 if test -f "$ORAINSTLOC"
 then 
    echo ""
 else     
    if  test -f  "$ORAINSTROOT" ;
     then
      echo "executing orainstRoot.sh"
      chmod +x  $ORAINSTROOT
      $ORAINSTROOT 
      if [ $? -eq 0 ]
       then
           echo "homeDir/oraInventory/orainstRoot.sh executed  sucessfuly"
         else
           echo "homeDir/oraInventory/orainstRoot.sh is not executed properly"
        fi
       
     fi  
 fi 

if  test -f  "$STATEDIR_R_OH/root.sh" ;
   then
        echo "$STATEDIR_R_OH/root.sh"
        chmod +x $STATEDIR_R_OH/root.sh
     	$STATEDIR_R_OH/root.sh $STATEDIR_R_OH
        if [ $? -eq 0 ]
           then
                echo "$STATEDIR_R_OH/root.sh  executed  sucessfuly"
           else
                exit 1;
        fi
fi


