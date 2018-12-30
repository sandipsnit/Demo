#!/bin/sh
#
# OVD_SSL_Server_Config.sh   version: 11.1.1.6.0
#
# Copyright (c) 2008, 2012, Oracle and/or its affiliates. All rights reserved. 
#
# Configuration Scripts Disclaimer:
# You configure the server and client systems by running the shell 
# scripts provided with this product. These scripts have been tested 
# and found to work correctly on all supported operating systems.  
# Do not modify the scripts, as inconsistent behavior might result.
#
#echo ""
#echo "OVD Server SSL Automation Script: Release 11.1.1.6.0 - Production"
#echo "Copyright (c) 2010 Oracle.  All rights reserved."
#echo ""
#echo " "

# a. Create a java key store JKS for OVD 



export WLST_PATH=$ORACLE_HOME/common/bin
if [ "$OS" = "Windows_NT" ]
then
export HOSTNAME=`hostname`
export WLSTCMD="${WLST_PATH}/wlst.cmd"
else
export HOSTNAME=`hostname -f`
export WLSTCMD="${WLST_PATH}/wlst.sh"
fi
export DOMAIN=dc=your_company,dc=com
export DNNAME=cn=$HOSTNAME,ou=ovd,$DOMAIN
export ALIAS='serverselfsigned'
export CA_ROOT=$ORACLE_HOME/rootCA
export KSTORES=$CA_ROOT/keystores
export OVD_INSTANCE_NAME=ovd1
export INSTANCE_TYPE=ovd
export SSL_END_POINT='LDAP SSL Endpoint'
export COMPONENT_NAME='ovd1'
export OVDKSDIR=$KSTORES/ovd
export timeStamp=`date +%Y%m%d%H%M%S`


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
dir=$1
if [ -e $dir ]
then
    rm -f $dir/* > /dev/null 
else
    mkdir -p $dir
fi
}
##--------------------------------------------------------------------
errors()
{
 errortype=$1
 logfile=$2
 wltn=$3
 error=`grep -i $errortype $logfile`
 if [ "X$error" != "X" ]
 then 
  if [ "$errortype" = "invalid" ]
  then
   printf "Invalid Credential\n"
  fi
  if [ "$errortype" = "cannot" ]
  then
   printf "Failed to connect to the LDAP server\n"
  fi
  if [ "$errortype" = "no" ]
  then
   printf "No such an object in the LDAP server\n"
  fi
    if [ "$errortype" = "MBeanException" ]
  then
    printf ">>>Failed configure OID $wltname\n"
    printf ">>>The wallet name $wltn may currently used. You may use a different wallet name\n"
  fi
  if [ "$errortype" = "exception" ]
  then
    printf ">>>Exception - Unable to configure the SSL wallet!\n"
  fi
  if [ "$errortype" = "failed" ]
  then
    printf ">>>Exception - Bind failed!\n"
  fi
  if [ "$errortype" = "ORACLE_INSTANCE" ]
  then
    printf ">>>ORACLE_INSTANCE is not set correctly!\n"
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

while [ "X$1" != "X" ]
do
getParams $1 $2
shift; shift;
done

printf ">>>Enter your OVD instance name [ovd1] "
read ovdinst

if [ "X$ovdinst" = "X" ]
then
export ovdinst="ovd1"
fi

printf ">>>Enter your Oracle instance [asinst_1]: " 
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

printf ">>>Enter weblogic admin host: [$HOSTNAME] "
read webadminhost

if [ "X$webadminhost" = "X" ]
then
  webadminhost="$HOSTNAME"
fi

printf ">>>Enter weblogic admin port: [7001] "
read webadminport

if [ "X$webadminport" = "X" ]
then
  webadminport="7001"
fi
printf ">>>Enter weblogic admin user: [weblogic] "
read webadmin

if [ "X$webadmin" = "X" ]
then
  webadmin="weblogic"
fi

stty -echo
while [ 1 ]
do
  printf ">>>Enter password for $webadmin: "
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

printf ">>>Enter your keystore name [ovdks1.jks]: "
read ksname
if [ "X$ksname" = "X" ]
then
export ksname="ovdks1.jks"
fi

cleanCache OVDKSDIR
cp ${OVDKSDIR}/identity.jks $OVDKSDIR/$ksname
#capasswd="$1"
#kpasswd="$2"

LogFile=${OVDKSDIR}/OVD_SSL_Server_Config_${timeStamp}.log
##--------------------------------------------------------------------
## ovdssl-check.py
##--------------------------------------------------------------------
echo "
from org.python.modules.time import Time

connect('$webadmin','$webpass','t3://"$webadminhost":$webadminport')
custom()
cd('oracle.as.management.mbeans.register')
cd('oracle.as.management.mbeans.register:type=component,name=$ovdinst,instance=$instance')
invoke('load',jarray.array([],java.lang.Object),jarray.array([],java.lang.String)) 
cd('../..')
# Navigate to the SSL config of the ovd instance $ovdinst
start_time = Time.time()
while true:
   try:
      cd('oracle.as.ovd') 
      cd('oracle.as.ovd:type=component.listenersconfig.sslconfig,name=LDAP SSL Endpoint,instance=$instance,component=$ovdinst')
      break
   except WLSTException:
      elapsed_time = Time.time() - start_time
      # Retry no more than 5 minutes (300 sec)
      if elapsed_time > 300:
         print \"Exception raised: unable to navigate through the OVD MBean configuration\"
         exit(exitcode=1)
      else:
         print \"Retry...\"
         Time.sleep(10)
listKeyStores('$instance','$ovdinst','ovd')
exit()" > $OVDKSDIR/ovdssl-check.py
##--------------------------------------------------------------------
## ovdssl-sa.py
##--------------------------------------------------------------------
echo "connect('$webadmin','$webpass','t3://"$webadminhost":$webadminport')
custom()
cd('oracle.as.management.mbeans.register')
cd('oracle.as.management.mbeans.register:type=component,name=$ovdinst,instance=$instance')
invoke('load',jarray.array([],java.lang.Object),jarray.array([],java.lang.String)) 
cd('../..')
cd('oracle.as.ovd') 
cd('oracle.as.ovd:type=component.listenersconfig.sslconfig,name=LDAP SSL Endpoint,instance=$instance,component=$ovdinst')
set('Threads', 20)
importKeyStore('$instance', '$ovdinst', 'ovd', '$ksname', '$kpasswd', '$OVDKSDIR/$ksname')
set('KeyStorePassword',java.lang.String('$kpasswd').toCharArray())
set('TrustStorePassword',java.lang.String('$kpasswd').toCharArray())
set('KeyStore','$ksname')
set('TrustStore','$ksname')
cd('../..')
cd('oracle.as.management.mbeans.register')
cd('oracle.as.management.mbeans.register:type=component,name=$ovdinst,instance=$instance')
invoke('save',jarray.array([],java.lang.Object),jarray.array([],java.lang.String))
invoke('load',jarray.array([],java.lang.Object),jarray.array([],java.lang.String)) 
cd('../..')
cd('oracle.as.ovd') 
cd('oracle.as.ovd:type=component.listenersconfig.sslconfig,name=LDAP SSL Endpoint,instance=$instance,component=$ovdinst')
configureSSL('$instance', '$ovdinst', '$INSTANCE_TYPE', '$SSL_END_POINT', '$OVDKSDIR/ovdssl-sa.prop')
set('IncludeAnonCiphers',Boolean(true))
exit()" > $OVDKSDIR/ovdssl-sa.py
##--------------------------------------------------------------------
## ovdssl-sa-del.py
##--------------------------------------------------------------------
echo "connect('$webadmin','$webpass','t3://"$webadminhost":$webadminport')
custom()
cd('oracle.as.management.mbeans.register')
cd('oracle.as.management.mbeans.register:type=component,name=$ovdinst,instance=$instance')
invoke('load',jarray.array([],java.lang.Object),jarray.array([],java.lang.String)) 
cd('../..')
cd('oracle.as.ovd') 
cd('oracle.as.ovd:type=component.listenersconfig.sslconfig,name=LDAP SSL Endpoint,instance=$instance,component=$ovdinst')
deleteKeyStore('$instance','$ovdinst', 'ovd', '$ksname')
importKeyStore('$instance', '$ovdinst', 'ovd', '$ksname', '$kpasswd', '$OVDKSDIR/$ksname')
set('KeyStorePassword',java.lang.String('$kpasswd').toCharArray())
set('TrustStorePassword',java.lang.String('$kpasswd').toCharArray())
set('KeyStore','$ksname')
set('TrustStore','$ksname')
cd('../..')
cd('oracle.as.management.mbeans.register')
cd('oracle.as.management.mbeans.register:type=component,name=$ovdinst,instance=$instance')
invoke('save',jarray.array([],java.lang.Object),jarray.array([],java.lang.String))
invoke('load',jarray.array([],java.lang.Object),jarray.array([],java.lang.String)) 
cd('../..')
cd('oracle.as.ovd') 
cd('oracle.as.ovd:type=component.listenersconfig.sslconfig,name=LDAP SSL Endpoint,instance=$instance,component=$ovdinst')
configureSSL('$instance', '$ovdinst', '$INSTANCE_TYPE', '$SSL_END_POINT', '$OVDKSDIR/ovdssl-sa.prop')
exit()" > $OVDKSDIR/ovdssl-sa-del.py
##--------------------------------------------------------------------
## ovdssl-sa.prop
##--------------------------------------------------------------------
echo "SSLEnabled=true
AuthenticationType=Server
SSLVersions=SSLv3,TLSv1,SSLv2Hello
Ciphers="SSL_RSA_WITH_RC4_128_MD5,SSL_RSA_WITH_RC4_128_SHA,TLS_RSA_WITH_AES_128_CBC_SHA"
KeyStore=$ksname
TrustStore=$ksname" > $OVDKSDIR/ovdssl-sa.prop
##--------------------------------------------------------------------
echo " " 
printf "Checking the existence of $ksname in the OVD...\n"
$WLSTCMD $OVDKSDIR/ovdssl-check.py > $OVDKSDIR/ks_check.log 2>&1
errors Exception $OVDKSDIR/ks_check.log
printf "Configuring $ksname for $ovdinst listener...\n"
export existKS=`cat $OVDKSDIR/ks_check.log|grep -i $ksname`
if [ "X$existKS" = "X" ]
then
$WLSTCMD $OVDKSDIR/ovdssl-sa.py > $OVDKSDIR/ovdssl-sa.log 2 > $OVDKSDIR/ovdssl-sa.log 2>&1
errors MBeanException $OVDKSDIR/ovdssl-sa.log
else
$WLSTCMD $OVDKSDIR/ovdssl-sa-del.py > $OVDKSDIR/ovdssl-sa-del.log 2>&1
errors MBeanException $OVDKSDIR/ovdssl-sa-del.log 
fi
##--------------------------------------------------------------------
printf "Do you want to restart your OVD instance?[y/n]"
read ansr

if [ "X$ansr" = "Xy" ]
then 
"$ORACLE_HOME"/opmn/bin/opmnctl stopproc ias-component="$ovdinst" >> $LogFile 2>&1
"$ORACLE_HOME"/opmn/bin/opmnctl startproc ias-component="$ovdinst" >> $LogFile 2>&1
errortype="ORACLE_INSTANCE"
errors $errortype $LogFile
errors unable $LogFile

echo " "
printf "Do you want to test your OVD SSL set up?[y/n]"
read ans
if [ "X$ans" = "Xy" ]
 then 
  printf "Please enter your OVD ssl port:[3131] "
  read sslport
  if [ "X$sslport" = "X" ]
  then 
   export sslport="3131"
  fi
  if [ "X$lpasswd" = "X" ]
  then
   printf ">>>Please enter cn=orcladmin password: "
   stty -echo
   read lpasswd
   echo " "
  fi
  stty echo
  echo "Please enter the OVD hostname [$HOSTNAME]"
  read host
  if [ "X$host" = "X" ]
   then 
     host=$HOSTNAME
  fi
  echo "$ORACLE_HOME/bin/ldapbind -h $host -p $sslport -U 2 -D $cn=orcladmin ..."
  $ORACLE_HOME/bin/ldapbind -h $host -p $sslport -U 2 -D "cn=orcladmin" -w $lpasswd -W file:$CA_ROOT -P $capasswd >> $LogFile 2>&1
  errors invalid $LogFile
  errors cannot $LogFile
  errors failed $LogFile
  printf "Bind successfully to OVD SSL port $sslport\n" 
fi
fi
##--------------------------------------------------------------------

if [ "$verbose" = "true" ]
then
 printf "Your keystore content: \n"
 "$JAVA_HOME"/bin/keytool -list -v -keystore $OVDKSDIR/$ksname -storepass $kpasswd -keypass $kpasswd
fi
cleanCache "$OVDKSDIR"
printf "Your $OID_INSTANCE_NAME SSL server has been set up successfully\n"
##--------------------------------------------------------------------

