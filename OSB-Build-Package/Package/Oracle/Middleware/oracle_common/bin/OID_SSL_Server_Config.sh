#!/bin/sh
#
# OID_SSL_Server_Config.sh   version: 11.1.1.6.0
#
# Copyright (c) 2008, 2011, Oracle and/or its affiliates. All rights reserved. 
#
# Configuration Scripts Disclaimer:
# You configure the server and client systems by running the shell 
# scripts provided with this product. These scripts have been tested 
# and found to work correctly on all supported operating systems.  
# Do not modify the scripts, as inconsistent behavior might result.
#


export DOMAIN="dc=your_company,dc=com"
export DN=cn=$HOSTNAME,ou=oid,$DOMAIN
export CA_ROOT=$ORACLE_HOME/rootCA
export KSTORE=$CA_ROOT/oid/wallet
export COMPONENT_TYPE=oid
export WLST_PATH=$ORACLE_HOME/common/bin
export TIMESTAMP=`date +%Y%m%d%H%M%S`
export SSL_PORT_NAME=sslport1
if [ "$OS" = "Windows_NT" ]
then
export OraPKI=$ORACLE_HOME/../oracle_common/bin/orapki.bat
export HOSTNAME=`hostname`
export wlstcmd="${WLST_PATH}"/wlst.cmd
else
export OraPKI=$ORACLE_HOME/../oracle_common/bin/orapki
export HOSTNAME=`hostname -f`
export wlstcmd="${WLST_PATH}"/wlst.sh
fi

##--------------------------------------------------------------------
errors()
{
 errortype=$1
 logfile=$2
 wltn=$3
 error=`cat $logfile | grep -i $errortype`
 if [ "X$error" != "X" ]
 then 
  if [ "$errortype" = "invalid" ]
  then
    printf ">>>Invalid Credential\n"
  fi
  if [ "$errortype" = "SecurityException" ]
  then
    printf ">>>Invalid Credential\n"
  fi

  if [ "$errortype" = "cannot" ]
  then
    printf ">>>Failed to connect to the LDAP server\n"
  fi
  if [ "$errortype" = "MBeanException" ]
  then
    printf ">>>Failed configure OID $wltname\n"
    printf ">>>The wallet name $wltn may currently used. You may use a different wallet name\n"
    exit 1
  fi
  if [ "$errortype" = "exception" ]
  then
    printf ">>>Exception - Unable to configure the SSL wallet!\n"
  fi
  if [ "$errortype" = "ORACLE_INSTANCE" ]
  then
    printf ">>>ORACLE_INSTANCE is not set!\n"
    printf ">>>Failed to restart your $oidinst.\n"
    printf ">>>Please check $logfile for more information\n"
    exit 1
  fi
  printf ">>>Failed to configure your SSL server wallet\n"
  printf ">>>Please check $logfile for more information\n"

  if [ "X$wltn" = "X" ]
  then
    exit 1
  fi
 fi

}
##--------------------------------------------------------------------
getParams()
{
PARAM=$1 
VAL=$2 
case $PARAM in
     -capwd)    capasswd=$VAL ;;
     -keypwd)   kpasswd=$VAL ;; 
     -ldappwd)  lpasswd=$VAL ;;
     -verbose)  verbose=$VAL ;;
     -v)        verbose=$VAL ;;
      *)        printf "Unknown Param $1\n"
                exit 1 
      ;;
esac
}

##--------------------------------------------------------------------
cleanCache()
{
targetDir=$1
if [ -e $targetDir ]
then
    rm -f $targetDir/* > /dev/null 
else
    mkdir -p $targetDir
fi

}
##--------------------------------------------------------------------
while [ "X$1" != "X" ]
do
getParams $1 $2
shift; shift;
done

stty echo
printf ">>>Enter your OID component name: [oid1] "
read oidinst

if [ "X$oidinst" = "X" ]
then
  export oidinst="oid1"
fi

printf ">>>Enter the weblogic admin server host [$HOSTNAME] "
read webadminhost

if [ "X$webadminhost" = "X" ]
then
export webadminhost=$HOSTNAME
fi

printf ">>>Enter the weblogic admin port: [7001] "
read webadminport

if [ "X$webadminport" = "X" ]
then
  export webadminport="7001"
fi
printf ">>>Enter the weblogic admin user: [weblogic] "
read webadmin

if [ "X$webadmin" = "X" ]
then
  webadmin="weblogic"
fi

stty -echo
  while [ 1 ]
  do
  printf ">>>Enter $webadmin password: "
  read webpass
  if [ "X$webpass" = "X" ]
  then
    echo ""
    continue
  fi
  break
  done
  stty echo
  echo " "

printf ">>>Enter your AS instance name:[asinst_1] "
read instance
if [ "X$instance" = "X" ]
then
 export instance="asinst_1"
fi

if [ "X$ORACLE_INSTANCE" = "X" ]
then 
 ORACLE_INSTANCE="$ORACLE_HOME/../$instance"
 if [ ! -e "$ORACLE_INSTANCE" ]
  then
  printf "Please set up your ORACLE_INSTANCE\n"
  exit 1
 fi
fi

printf ">>>Enter an SSL wallet name for OID component [oid_wallet1] "
read wltname
if [ "X$wltname" = "X" ]
then
 wltname="oid_wallet1"
fi
KSTORE=$CA_ROOT/wallets/oid
LogFile=$KSTORE/OID_SSL_Server_Config.log

##--------------------------------------------------------------------
## To configure using wlst
#$ oidssl-check.py
##--------------------------------------------------------------------
echo "connect('$webadmin','$webpass','t3://"$webadminhost":$webadminport')
listKeyStores('$instance','$oidinst','$COMPONENT_TYPE')
exit()" > $KSTORE/oidssl-check.py

##--------------------------------------------------------------------
## oidssl-sa.py
##--------------------------------------------------------------------
echo "connect('$webadmin','$webpass','t3://"$webadminhost":$webadminport')
importWallet('$instance', '$oidinst', '$COMPONENT_TYPE', '$wltname', '', '$KSTORE/cwallet.sso')
configureSSL('$instance', '$oidinst', '$COMPONENT_TYPE', '$SSL_PORT_NAME', '$KSTORE/oidssl-sa.prop')
exit()" > $KSTORE/oidssl-sa.py

##--------------------------------------------------------------------
## oidssl-sa-del.py
##--------------------------------------------------------------------
echo "connect('$webadmin','$webpass','t3://"$webadminhost":$webadminport')
deleteKeyStore('$instance','$oidinst', '$COMPONENT_TYPE', '$wltname')
importWallet('$instance', '$oidinst', '$COMPONENT_TYPE', '$wltname', '', '$KSTORE/cwallet.sso')
configureSSL('$instance', '$oidinst', '$COMPONENT_TYPE', '$SSL_PORT_NAME', '$KSTORE/oidssl-sa.prop')
exit()" > $KSTORE/oidssl-sa-del.py

##--------------------------------------------------------------------
## oidssl-sa.prop
##--------------------------------------------------------------------
echo "SSLEnabled=true
AuthenticationType=Server
SSLVersions=nzos_Version_3_0
Ciphers=
KeyStore=$wltname" > $KSTORE/oidssl-sa.prop 2>&1

##--------------------------------------------------------------------
printf "Checking the existence of $wltname in the OID server...\n"

"$wlstcmd" $KSTORE/oidssl-check.py > $KSTORE/oidssl_check.log 2>&1 
errors SecrityException $KSTORE/oidssl_check.log $wltname
errors MBeanException $KSTORE/oidssl_check.log $wltname
errors exception $KSTORE/oidssl_check.log

printf "Configuring the newly generated Oracle Wallet with your OID component...\n"

existWLT=`grep ${wltname} ${KSTORE}/oidssl_check.log`

if [ "X$existWLT" = "X" ]
then
 "$wlstcmd" $KSTORE/oidssl-sa.py > $KSTORE/oidssl-sa.log 2>&1
 errors error $KSTORE/oidssl-sa.log
else
 "$wlstcmd" $KSTORE/oidssl-sa-del.py > $KSTORE/oidssl-sa-del.log 2>&1
 errors MBeanException $KSTORE/oidssl-sa-del.log $wltname
 errors exception $KSTORE/oidssl-sa-del.log
fi
##--------------------------------------------------------------------
# Test your set up
##--------------------------------------------------------------------
printf "Do you want to restart your OID component?[y/n]"
read ansr

if [ "X$ansr" = "Xy" ]
then 
 $ORACLE_HOME/opmn/bin/opmnctl restartproc ias-component="$oidinst" > $LogFile 2>&1
 errortype="ORACLE_INSTANCE"
 errors "$errortype" $LogFile
 echo " "
 printf "Do you want to test your SSL set up?[y/n]"
 read ansr
 if [ "X$ansr" = "Xy" ]
  then 
   printf ">>>Please enter your OID ssl port:[3131] "
   read sslport
   if [ "X$sslport" = "X" ]
   then 
    sslport="3131"
   fi

   if [ "X$lpasswd" = "X" ]
   then
    printf ">>>Please enter $admuser password: "
    stty -echo
    read lpasswd
    echo " "
   fi
   stty echo
   echo "Please enter the OID hostname:[$HOSTNAME]"
   read host
   if [ "X$host" = "X" ]
   then
     host=$HOSTNAME
   fi
   echo ">>>Invoking $ORACLE_HOME/bin/ldapbind -h $host -p $sslport -U 2 -D cn=orcladmin ..."
   $ORACLE_HOME/bin/ldapbind -h $host -p $sslport -U 2 -D cn=orcladmin -w $lpasswd -W file:$CA_ROOT -P $capasswd >> $LogFile 2>&1
   errors invalid $LogFile
   errors handshake $LogFile
   errors usage $LogFile
   printf "Bind successful\n"
   echo " "
 fi
fi
##--------------------------------------------------------------------
printf "Your $oidinst SSL server has been set up successfully\n"
if [ "X$verbose" = "false" ] 
then
rm -rf $KSTORE
fi
##--------------------------------------------------------------------
