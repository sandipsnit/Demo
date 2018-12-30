#!/bin/sh
#
# WLS_SSL_Server_Config.sh   version: 11.1.1.6.0
#
# Copyright (c) 2008, 2011, Oracle and/or its affiliates. All rights reserved. 
#
# Configuration Scripts Disclaimer:
# You configure the WLS servers and clients by running the shell 
# scripts provided with this product. These scripts have been tested 
# and found to work correctly on all supported operating systems.  
# Do not modify the scripts, as inconsistent behavior might result.
#
#echo ""
#echo "WLS Server SSL Automation Script: Release 11.1.1.6.0 - Production"
#echo "Copyright (c) 2010 Oracle.  All rights reserved."
#echo ""
#echo " "

# a. Create a java key store JKS for OVD 

export WLST_PATH=$ORACLE_HOME/common/bin
export Domain=dc=your_company,dc=com
export CaRoot=$ORACLE_HOME/rootCA
export ksDir=$CaRoot/keystores
export wlsKSDir=$ksDir/wls
export TimeStamp=`date +%Y%m%d%H%M%S`
if [ "$OS" = "Windows_NT" ]
then
export hostName=`hostname`
export wlstcmd="${WLST_PATH}"/wlst.cmd
else
export hostName=`hostname -f`
export wlstcmd="${WLST_PATH}"/wlst.sh
fi
##----------------------------------------------------------------

##--------------------------------------------------------------------
getParams()
{
PARAM=$1 
VAL=$2 
case $PARAM in
     -keyalias) keyAlias=$VAL ;;
     -keypwd)   keyPassword=$VAL ;; 
     -verbose)  verbose=$VAL ;;
     -v)        verbose=$VAL ;;
      *)        printf "Unknown Param $1\n"
                exit 1 
      ;;
esac
}

##----------------------------------------------------------------
cleanCache()
{
dir=$1
if [ -f $dir ]
then
    rm -f dir/* > /dev/null 
else
    mkdir -p $dir
fi
}
errors()
{
 errortype=$1
 logfile=$2
 wltn=$3
 error=`grep -i $errortype $logfile`
 if [ "X$error" != "X" ]
 then 
  if [ "$errortype" = "SecurityException" ]
  then
   printf "Invalid Credential\n"
  fi
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
  printf ">>>Failed to configure your SSL server wallet\n"
  printf ">>>Please check $logfile for more information\n"
  if [ "X$wltn" = "X" ]
  then
    exit 1
  fi
 fi

}

while [ "X$1" != "X" ]
do
getParams $1 $2
shift; shift;
done

printf "Configuring SSL for your WLS server instance...\n"

printf ">>>Enter your WLS domain home directory: "
read domainDir

if [ ! -e $domainDir/servers ]
then
printf "$domainDir is invalid WLS domain home\n"
exit
fi

printf ">>>Enter your WLS server instance name [AdminServer] "
read serverName

if [ "X$serverName" = "X" ]
then
export serverName="AdminServer"
fi

if  [ ! -e $domainDir/servers/$serverName ]
then 
printf ">>>$serverName does not exist in $domainDir\n"
exit
fi

printf "Enter SSL Listen Port: [7002] "
read sslPort

if [ "X$sslPort" = "X" ]
then 
sslPort="7002"
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

printf ">>>Enter your keystore name [identity.jks]: "
read kStoreName

if [ "X$kStoreName" = "X" ]
then
export kStoreName="identity.jks"
fi


identityKeyStoreDir=${domainDir}/keystores
cleanCache $identityKeyStoreDir
identityKeyStore=$identityKeyStoreDir/$kStoreName
echo $wlsKSDir
cp ${wlsKSDir}/identity.jks $identityKeyStore



echo $identityKeyStore

echo " " 
#
# Generate a jython code for the wls server
#

echo "

def cfgWLSIdentity(domainDir, serverName, identityKeystore, keystorePassword, keyAlias, keyPassword, sslPort):
    print 'Configuring identity for server: ' + serverName + ' ...'
    edit()
    startEdit()
    cd ('\Servers')
    cd (serverName)

    try:
        try:
            # Set the keystore file for CustomIdentityAndCustomTrust
            print '*** Setting KeyStores to CustomIdentityAndCustomTrust'
            cmo.setKeyStores('CustomIdentityAndCustomTrust')

            print '*** Setting CustomIdentityKeyStoreFileName to ' + identityKeystore
            cmo.setCustomIdentityKeyStoreFileName(identityKeystore)
            cmo.setCustomIdentityKeyStorePassPhrase(keystorePassword)
            cmo.setCustomIdentityKeyStoreType('JKS')
            # Set the server-private-key-alias and the pass phrase
            cd('SSL')
            cd(serverName)
            cmo.setServerPrivateKeyAlias(keyAlias)
            cmo.setServerPrivateKeyPassPhrase(keyPassword)
            cmo.setEnabled(true)
            cmo.setListenPort(sslPort)
        finally:
            save()
            print '*** Activating the changes for: ' + serverName
            activate()
            print 'Exit editing session..'
            print '*** SSL configuration  successfully for: ' + serverName
    except:
        print 'Error: Unable to configure identity store'
        print ''.join(traceback.format_exception(*sys.exc_info())[-2:]).strip().replace('\n',': ')
        exit(exitcode=1)

# Begin of main program
connect('$webadmin','$webpass', 't3://$hostName:$webadminport')
cfgWLSIdentity('$domainDir', '$serverName', '$identityKeyStore', '$keyPassword', '$keyAlias', '$keyPassword', $sslPort)
disconnect()
" > $wlsKSDir/wlssvr.py
printf "Configuring WLS $serverName ...\n"
printf "Running "$wlstcmd" $wlsKSDir/wlssvr.py..."
LogFile=${wlsKSDir}/wlssvr.log
if [ "$3" = "-v" ]
then
 "$wlstcmd" $wlsKSDir/wlssvr.py > $LogFile
 errors SecurityException $LogFile
 errors exception $LogFile
 errors error $LogFile
else
 "$wlstcmd" $wlsKSDir/wlssvr.py > $wlsKSDir/wlssvr.log 2>&1
 errors SecurityException $LogFile
 errors exception $LogFile
 errors error $LogFile
fi


echo " "

if [ "$3" = "-v" ]
then
printf "Your keystore content: \n"
$JAVA_HOME/bin/keytool -list -v -keystore $identityKeyStore -storepass $keyPassword -keypass $keyPassword
fi
printf "Your WLS server has been set up successfully\n"


