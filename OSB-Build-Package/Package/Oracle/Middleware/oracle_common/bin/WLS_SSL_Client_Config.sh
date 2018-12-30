#!/bin/sh
#
# WLS_SSL_Client_Config.sh   version: 11.1.1.6.0
#
# Copyright (c) 2008, 2011, Oracle and/or its affiliates. All rights reserved. 
#
# Configuration Scripts Disclaimer:
# You configure the WLS clients by setting customized trust store by 
# running the shell scripts provided with this product. 
# These scripts have been tested  and found to work correctly on 
# all supported operating systems.  
# Do not modify the scripts, as inconsistent behavior might result.
#
#echo ""
#echo "WLS Client SSL Automation Script: Release 11.1.1.6.0 - Production"
#echo "Copyright (c) 2010 Oracle.  All rights reserved."
#echo ""
#echo " "

export WLST_PATH=$ORACLE_HOME/common/bin
export caRoot=$ORACLE_HOME/rootCA
export wlsTrustDir=$caRoot/keystores/wls
export timeStamp=`date +%Y%m%d%H%M%S`
if [ "$OS" = "Windows_NT" ]
then
export hostName=`hostname`
export wlstcmd="${WLST_PATH}"/wlst.cmd
else
export hostName=`hostname -f`
export wlstcmd="${WLST_PATH}"/wlst.sh
fi
getParams()
{
PARAM=$1 
VAL=$2 
case $PARAM in
     -trustfile)    trustStoreName=$VAL ;;
     -pwd)          trustStorePassword=$VAL ;;
     -keystore)     kname=$VAL ;;
     -domaindir)    domainDir=$VAL ;;
     -servername)   serverName=$VAL ;;
     -wlsadmin)     webadmin=$VAL ;;
     -wlsadminpass) webpass=$VAL ;;
     -wlsadminport) webadminport=$VAL ;; 
     -v)            verbose=$VAL ;;
      *)            printf "Unknown Parameter $1\n"
                    exit 1 
      ;;
esac
}

errors()
{
 errortype=$1
 logfile=$2
 error=`cat $LogFile | grep -i $errortype`
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
  exit
 fi

}
cleanCache()
{
dir=$1
if [ -e $dir ]
then
    rm -f ${dir}/*.*  
else
    mkdir -p $dir
fi
}
printf "Configuring SSL Trust for your WLS server instance...\n"

while [ "X$1" != "X" ]
do
getParams $1 $2
shift; shift;
done

printf ">>>Enter your trust store name: [$trustStoreName]"
read tsName
if [ "X$tsName" = "X" ]
then
  tsName=$trustStoreName
fi

if [ "X$domainDir" = "X" ]
then
 printf ">>>Enter your WLS domain home directory: "
 read domainDir
fi

if [ ! -e $domainDir/servers ]
then 
printf ">>>$domainDir is invalid\n"
exit 1
fi

if [ "X$serverName" = "X" ]
then 
 printf ">>>Enter your WLS server instance name [AdminServer] "
 read serverName
fi

if [ "X$serverName" = "X" ]
then
export serverName="AdminServer"
fi
export keyStoreDir="servers/${serverName}/keystores"

if [ "X$webadminport" = "X" ]
then
 printf ">>>Enter weblogic admin port: [7001] "
 read webadminport
fi

if [ "X$webadminport" = "X" ]
then
  webadminport="7001"
fi

if [ "X$webadmin" = "X" ]
then
 printf ">>>Enter weblogic admin user: [weblogic] "
 read webadmin
fi

if [ "X$webadmin" = "X" ]
then
  webadmin="weblogic"
fi

if [ "X$webpass" = "X" ]
then
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
fi

srcTrustStore=${wlsTrustDir}/${trustStoreName}
trustStoreDir=${domainDir}/${keyStoreDir}
cleanCache ${trustStoreDir}
destTrustStore=${trustStoreDir}/${tsName}
printf ">>>Copy $srcTrustStore to $destTrustStore...\n"
cp $srcTrustStore $destTrustStore

#
# Generate a jython code for the wls server to set up truststore
#

echo "

def cfgWLSTrust(domainDir, serverName, trustKeystore, truststorePassword):
    print 'Configuring trust key store for server: ' + serverName + ' ...'
    edit()
    startEdit()
    cd ('\Servers')
    cd (serverName)

    try:
        try:
            # Set the keystore file for CustomIdentityAndCustomTrust
            print '*** Setting Trust Store to CustomIdentityAndCustomTrust'
            cmo.setKeyStores('CustomIdentityAndCustomTrust')
            print '*** Setting CustomTrustKeyStoreFileName to ' + trustKeystore
            cmo.setCustomTrustKeyStoreFileName(trustKeystore)
            # Set the custom trust key store pass-phrase-encrypted
            cmo.setCustomTrustKeyStoreType('JKS')
            cmo.setCustomTrustKeyStorePassPhrase(truststorePassword)
            # Set the server-private-key-alias and the pass phrase
            cd('SSL')
            cd(serverName)
            cmo.setEnabled(true)
        finally:
            save()
            print '*** Activating the changes for: ' + serverName
            activate()
            print 'Exit editing session..'
            print '*** SSL configuration  successfully for: ' + serverName
    except:
        print 'Error: Unable to configure trust store'
        print ''.join(traceback.format_exception(*sys.exc_info())[-2:]).strip().replace('\n',': ')
        exit(exitcode=1)

# Begin of main program
connect('$webadmin','$webpass', 't3://$hostName:$webadminport')
cfgWLSTrust('$domainDir', '$serverName', '$destTrustStore', '$trustStorePassword')
disconnect()
" > ${wlsTrustDir}/wlscln.py
printf "Configuring WLS $serverName ...\n"
printf "Running "$wlstcmd" $wlsTrustDir/wlscln.py...\n"
LogFile="${wlsTrustDir}/wlscln.log"
if [ "$verbose" = "true" ]
then
 "$wlstcmd" ${wlsTrustDir}/wlscln.py > $LogFile 
else
 "$wlstcmd" ${wlsTrustDir}/wlscln.py > $LogFile 2>&1
 errors exception $LogFile
 errors failed $LogFile
 errors invalid $LogFile
 printf "Your WLS server has been set up successfully\n"
fi

echo " "

if [ "$verbose" = "-v" ]
then
printf "Your keystore content: \n"
$JAVA_HOME/bin/keytool -list -v -keystore $trustStoreName -storepass $trustStorePassword -keypass $trustStorePassword
fi
