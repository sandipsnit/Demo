#!/bin/sh
#
# SSLServerConfig.sh   version: 11.1.1.6.0
#
# Copyright (c) 2008, 2012, Oracle and/or its affiliates. All rights reserved. 
#
# Configuration Scripts Disclaimer:
# You configure the server and client systems by running the shell 
# scripts provided with this product. These scripts have been tested 
# and found to work correctly on all supported operating systems.  
# Do not modify the scripts, as inconsistent behavior might result.
#
echo ""
echo "Server SSL Automation Script: Release 11.1.1.6.0 - Production"
echo "Copyright (c) 2010 Oracle.  All rights reserved."
echo " "


OraComBin=$ORACLE_HOME/../oracle_common/bin
export OraComBin
OraBin=$ORACLE_HOME/bin
export OraBin
caRoot=$ORACLE_HOME/rootCA
export caRoot
logDir=$caRoot/log
export logDir
timeStamp=`date +%Y%m%d%H%M%S`
export timeStamp
wltDir=$caRoot/wallet
export wltDir
jksDir=$caRoot/keystores
export jksDir

OS=`uname`

DOMAIN=`domainname`

if [ "$OS" = "Windows_NT" ]
then
OraPKI=$OraComBin/orapki.bat
export OraPKI
hostName=`hostname`
export hostName
elif [ "$OS" = "Linux" ]
then
OraPKI=$OraComBin/orapki
export OraPKI
hostName=`hostname -f`
export hostName
elif [ "$OS" = "AIX" ]
then
OraPKI=$OraComBin/orapki
export OraPKI
hostName=`hostname`
export hostName
elif [ "$OS" = "SunOS" ] || [ "$OS" = "HP-UX" ]
then
OraPKI=$OraComBin/orapki
export OraPKI
hostName=`hostname`
hostName="${hostName}.$DOMAIN"
export hostName
else
hostName=`hostname`
export hostName
fi


component="$2"
export component
## -----------------------------------------------------------
Usage()
{
   this="$0"
   printf "Usage: $this -component [oid|ovd|oam|oim|wls|ohs|db] [-v [true/false]] \n" 
   exit
}
#-------------------------------------------------------------
##
## Read commandline arguments
##
getParams()
{
PARAM=$1 
VAL=$2 
case $PARAM in
     -component)    component=$VAL ;;
     -h)            host=$VAL ;;
     -p)            port=$VAL ;;
     -u)            admuser=$VAL ;;
     -pwd)          lpasswd=$VAL ;;
     -ssldomain)    domain=$VAL ;;
     -keystore)     kname=$VAL ;;
     -keypwd)       swpasswd=$VAL ;;
     -domaindir)    domainDir=$VAL
                    domainDirArg="-domaindir $VAL" ;;
     -servername)   serverName=$VAL 
                    serverNameArg="-servername $VAL" ;;
     -wlsadmin)     wlsadmin=$VAL 
                    wlsAdminArg="-wlsadmin $VAL" ;;
     -wlsadminpass) wlsadminpass=$VAL 
                    wlsAdminPassArg="-wlsadminpass $VAL" ;;
     -wlsadminport) wlsadminport=$VAL
                    wlsAdminPortArg="-wlsadminport $VAL" ;;
     -silent)            silentArg="-silent $VAL" ;;
     -webgatedir)        webgateDirArg="-webgatedir $VAL" ;;
     -webgateid)         webgateIdArg="-webgateid $VAL" ;;
     -webgatepwd)        if [ "X$VAL" = "X" ] 
                         then 
                          VAL="null"
                         fi
                         webgatePwdArg="-webgatepwd $VAL" ;;
     -oamserverhost)     oamhost=$VAL
                         oamHostArg="-oamserverhost $VAL" ;;
     -oamserverport)     oamport=$VAL
                         oamPortArg="-oamserverport $VAL" ;;
     -oamserverid)       oamid=$VAL
                         oamIdArg="-oamserverid $VAL" ;;
     -oamssldomain)      oamssldomain=$VAL ;;
     -webgatepassphrase) webgatepassphrase=$VAL
                         webgatePPArg="-webgatepassphrase $VAL" ;;
     -capwd)             capasswd=$VAL
                         caPwdArg="-capwd $VAL" ;;
     -ohsOH)             ohsoh=$VAL
                         ohsOHArg="-oshOH $VAL" ;;
     -ohsIH)             ohsih=$VAL
                         ohsIHArg="-oshIH $VAL" ;;
     -isohs)             isohs=$VAL
                         isohsArg="-isohs $VAL" ;;
     -ohsid)             oshid=$VAL
                         oshIdArg="-ohsid $VAL" ;; 
     -v)                 verbose=$VAL
                         verboseArg="-v $VAL" ;;
      *)                 printf "Unknown Param $1\n"
                         Usage $0
                         exit 1 
      ;;
esac
}
#-------------------------------------------------------------
setSSLBinDir()
{
    if [ "X${SSL_BIN_DIR}" = "X" ]
    then 
       sslBinDir="${OraComBin}"
    else
       sslBinDir="${SSL_BIN_DIR}"
    fi
}
#-------------------------------------------------------------
cleanCache()
{
dir=$1
if [ -e $dir ]
then
    rm -f ${dir}/* > /dev/null 2>&1
else
    mkdir -p $dir
fi
}
#-------------------------------------------------------------
errors()
{
 errortype=$1
 logfile=$2
 error=`cat $logfile | grep -i $errortype`
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
  if [ "$errortype" = "unable" ]
  then
   printf "Unable to open the CA wallet - check your password\n"
   exit 1
  fi
  exit
 fi
}
#-------------------------------------------------------------
genOracleWallet()
{
cadir=$1
wpwd=$2
capwd=$3
dname=$4
tstamp=$5
opki=$6
logfile=$7
component=$8
wltdir=$cadir/wallets/${component}
cleanCache $wltdir
echo " "
printf "Creating an Oracle SSL Wallet for ${component} instance...\n"
$opki wallet create -wallet $wltdir -pwd $wpwd >> $logfile 2>&1
$opki wallet add -wallet $wltdir -dn $dname -keysize 1024 -pwd $wpwd >> $logfile 2>&1
$opki wallet export -wallet $wltdir -dn $dname -request $wltdir/creq.txt -pwd $wpwd >> $logfile 2>&1

#To sign the $wltdir certificate with the generate root CA at $OH/rootCA using 'orapki'
$opki cert create -wallet $cadir  -request $wltdir/creq.txt -cert $wltdir/srvcert.txt -serial_num $tstamp -validity 365 -summary -pwd $capwd >> $logfile 2>&1
errors "unable" $logfile
#To import the $wltdir certificate into the OID $wltdir wallet using  'orapki'  tool
$opki wallet add -wallet $wltdir -trusted_cert -cert $cadir/cacert.der -pwd $wpwd >> $logfile 2>&1
$opki wallet add -wallet $wltdir -user_cert -cert $wltdir/srvcert.txt -pwd $wpwd >> $logfile 2>&1
$opki wallet create -wallet $wltdir -auto_login -pwd $wpwd >> $logfile 2>&1
errors error $logfile
}
#-------------------------------------------------------------
genKeyStoreJKS()
{
ktool=$1
cadir=$2
dname=$3
alias=$4
ksname=$5
kpasswd=$6
capwd=$7
compo=$8
logfile=$9
ksdir=${cadir}/keystores/${compo}
kstore=${ksdir}/${ksname}
cleanCache $ksdir
#a. Create a new keystore
$ktool  -genkey -alias $alias -keystore $kstore -storepass $kpasswd -keyalg  rsa -dname $dname -keypass $kpasswd >> $logfile 2>&1
 
#b.Create a certificate request from the newly generated key pair
$ktool -certreq -alias $alias -keystore $kstore -file $ksdir/csr.txt -storepass $kpasswd >> $logfile 2>&1

#c.Create the server certificate signed by the central CA using 'orapki'.
$OraPKI cert create -wallet $cadir -request $ksdir/csr.txt -cert $ksdir/cert.txt -serial_num $timeStamp -validity 365  -pwd $capwd >> $logfile 2>&1
errors "unable" $logfile

#d.Import the CA certificate located at $OH/rootCA as a trusted certificate into the keystore 
printf ">>>Import the existing CA at ${cadir}/cacert.der into keystore...\n"
$ktool -import -trustcacerts -alias rootca -file ${cadir}/cacert.der  -keystore  $kstore -storepass $kpasswd -noprompt >> $logfile 2>&1
errors "unable" $logfile

#d.Import the CA certificate located at $OH/rootCA as a trusted certificate into the keystore 
printf ">>>Import the server certificate at $ksdir/cert.txt into kstore... \n"
$ktool -importcert -noprompt -v  -alias $alias -file $ksdir/cert.txt  -keystore  $kstore -storepass $kpasswd -noprompt >> $logfile 2>&1

}
#-------------------------------------------------------------
getDN() 
{
orgUnit=$1
stty echo 
  printf "Enter attribute values for your certificate DN\n"
  printf ">>>Country Name 2 letter code [US]:"
  read country
  if [ "X$country" = "X" ]
  then
    country="US"
  fi
  printf ">>>State or Province Name [California]:"
  read state
  if [ "X$state" = "X" ]
  then
    state="California"
  fi
  printf ">>>Locality Name(eg, city) []:"
  read locality
  printf ">>>Organization Name (eg, company) [mycompany]:"
  read organization
  printf ">>>Organizational Unit Name (eg, section) [$orgUnit]:"
  read organizationUnit
  printf ">>>Common Name (eg, hostName.domainName.com) [$hostName]:"
  read commonName
  if [ "X$commonName" = "X" ]
  then
    commonName="$hostName"
  fi
  if [ "X$organizationUnit" != "X" ]
  then
    OU="ou=$organizationUnit,"
  else
    OU="ou=$orgUnit,"
  fi
  if [ "X$organization" != "X" ]
  then
    O="O=$organization,"
  fi

  if [ "X$locality" != "X" ]
  then
    L="l=$locality,"
  fi 
  dnName="cn=$commonName,${OU}${O}${L}st=$state,c=$country" 
  printf "The subject DN is $dnName\n"

}
#-------------------------------------------------------------
testConnection()
{
host=$1
port=$2
user=$3
lpwd=$4
logf=$5
$ORACLE_HOME/bin/ldapbind -h $host -p $port -D "$user" -w $lpwd >> $logf 2>&1 
errors invalid $logf
errors cannot  $logf

}
#-------------------------------------------------------------
#---------------------------------------------------------------------------------------
genTrustStoreJKS()
{
ktool=$1
ksdir=$2
dname=$3
opki=$4
cadir=$5
alias=$6
logfile=$7
tmppwd=$8
kstore=$ksdir/trust.jks

trustStorePass=$tmppwd

cleanCache $ksdir

# Generate keystore or ewallet
if [ ! -f $kstore ]
then
$ktool  -genkey -alias testkey -keystore $kstore -storepass $trustStorePass -keyalg rsa -dname $dname -keypass $trustStorePass > $logfile 2>&1
fi

#b. Import CA certificate located at $OH/rootCA into the CTS 
if [ -f $cadir/cacert.der ]
then
 printf "Importing the CA certifcate into trust stores...\n"
 $ktool -importcert -noprompt -trustcacerts -alias $alias -file $cadir/cacert.der -keystore  $kstore -storepass $trustStorePass >> $logfile 2>&1  
 # export the ca cert to pem format back to cacert_tmp.txt
 $keyTool -exportcert -rfc -alias $alias -file $cadir/cacert_tmp.txt -keystore  $wlsTrustDir/trust.jks -storepass $tpwd >> $logfile 2>&1
 if [ -f $caRoot/cacert.txt ]
 then
   echo " " >> $caRoot/cacert.txt
   cat $cadir/cacert_tmp.txt >> $caRoot/cacert.txt
 else
   cat $cadir/cacert_tmp.txt > $caRoot/cacert.txt
   echo " " >> $cadir/cacert.txt
 fi
 rm -f $cadir/cacert_tmp.txt
else
 printf "Missing $cadir/cacert.der\n"
 exit 1
fi

if [ "$verbose" = "true" ]
then 
 if [ -f $kstore ]
 then 
   $ktool -list -v -keystore $kstore -storepass $tpwd
 fi
 if [ -f $ksdir/ewallet.p12 ] 
 then
   $opki wallet display -wallet $ksdir -pwd $tpwd
 fi
fi

}
#-------------------------------------------------------------

downloadCA() 
{
host=$1
port=$2
admuser=$3
lpasswd=$4
sslDomain=$5
cadir=$6
object=$7
logfile=$8

printf ">>>Searching the LDAP for the CA ${object} ...\n"
if [ ! -f $ORACLE_HOME/bin/ldapsearch ]
then
 printf "Missing $ORACLE_HOME/bin/ldapsearch...\n"
 exit
fi
$ORACLE_HOME/bin/ldapsearch -h $host -p $port -D "$admuser" -w $lpasswd -b  \
cn=demoCA,${sslDomain} -t -s base "(objectclass=*)" $object >> ${logfile} 2>&1
grep $object ${logfile} > $logDir/${object}2_1.out 2>&1
sed "s/${object}=//g" $logDir/${object}2_1.out > $logDir/${object}2_2.out 2>&1
errors invalid $logfile
errors no $logfile

if [ "$object" = "userpkcs12" ]
then
 mv `cat $logDir/${object}2_2.out`  $cadir/ewallet.p12
else
 mv  `cat $logDir/${object}2_2.out`  $cadir/cacert.der
 wlsTrustDir=${cadir}/tmp
 alias="test"
 tpwd="xyzadb1462edf"
 cleanCache $wlsTrustDir
 genTrustStoreJKS $keyTool $wlsTrustDir "cn=test" $OraPKI $cadir $alias $logfile $tpwd
 cleanCache $wlsTrustDir
fi
}

#-------------------------------------------------------------
getSSLDomain()
{ 
CA="$1"
defval="$2"
domain1="$3"
 if [ "X$domain" = "X" ]
 then
  printf ">>>Enter the sslDomain for the $CA [$defval]: " 
  read domain
  if [ "X$domain" = "X" ]
  then
    domain="$defval"
  fi
 fi
 sslDomain="cn=$domain,cn=sslDomains"
 isDownloadCA="y"
 if [ "X$domain" = "X$domain1" ]
 then
   isDownloadCA="n"
 fi
}
#-------------------------------------------------------------
getPassword()
{
  
if [ "$component" != "oam" ]
then
  if [ "X$swpasswd" = "X" ]
  then
   stty -echo
   while [ 1 ]
   do
   printf ">>>Enter a password to protect your SSL wallet/keystore: "
   read swpasswd
   if [ "X$swpasswd" = "X" ]
   then
     echo ""
     continue
   fi
#swpass=$swpasswd
#   break
#   done
    stty echo
    echo " "
    stty -echo
#   while [ 1 ]
#   do
    printf ">>>Enter confirmed password for your SSL wallet/keystore: "
    read swpasswd2
    echo " "
    if [ "$swpasswd2" != "$swpasswd" ] 
    then
      printf ">>>The password and the confirmed password are mismatched.\n"
      continue
    fi
    break
    done
    stty echo
 fi
fi

if [ "X$capasswd" = "X" ]
then
 stty -echo
   while [ 1 ]
   do
   printf ">>>Enter password for the CA wallet: "
   read capasswd
   if [ "X$capasswd" = "X" ]
   then
     echo ""
     continue
   fi
   capass=$capasswd
   break
   done
   stty echo
   echo " "
fi
}
validatePath()
{
bindir=$1
script=$2
 if [ ! -f ${bindir}/${script} ]
 then 
   printf "Please set up SSL_BIN_DIR to the directory where $script located\n"
   exit 1
 fi
}
#-------------------------------------------------------------
# Check Usage
if [ "X$1" = "X" ]
then
   Usage $0
else  
   if [ "X$2" = "X" ] 
   then
     Usage $0
   fi
fi

if [ "X$ORACLE_HOME" = "X" ]
then 
 printf "Please set your ORACLE_HOME\n"
 exit
fi

if [ "X$ORACLE_INSTANCE" = "X" ]
then 
 printf "Please set your ORACLE_INSTANCE\n"
 exit
fi

if [ "X$JAVA_HOME" = "X" ]
then 
 JAVA_HOME=$ORACLE_HOME/../jdk160_21
 export JAVA_HOME
 if [ ! -e  $JAVA_HOME ]
 then 
  printf "Please set your JAVA_HOME\n"
  exit
 fi
fi

keyTool=$JAVA_HOME/bin/keytool

# Clean up existing cache
cleanCache $caRoot
cleanCache $logDir

while [ "X$1" != "X" ]
do
getParams $1 $2
shift; shift;
done


printf "Downloading the CA wallet from the central LDAP location...\n"
if [ "X$host" = "X" ]
then
 printf ">>>Enter the LDAP Hostname [$hostName]: "
 read host
 if [ "X$host" = "X" ]
 then
  host=$hostName
  export host
 fi
fi

if [ "X$port" = "X" ]
then
 printf ">>>Enter the LDAP port [3060]: "
 read port
 if [ "X${port}" = "X" ]
 then
  port="3060"
  export port
 fi
fi

if [ "X$admuser" = "X" ]
then
 printf ">>>Enter an admin user DN [cn=orcladmin] "
 read admuser
 if [ "X$admuser" = "X" ]
 then 
  admuser="cn=orcladmin"
  export admuser
 fi
fi

stty -echo
  
if [ "X$lpasswd" = "X" ]
then
 while [ 1 ]
 do
   printf ">>>Enter password for $admuser: "
   read lpasswd
   if [ "X$lpasswd" = "X" ]
   then
     echo ""
     continue
   fi
   break
   done
 stty echo
 echo " "
fi

if [ "$component" != "oam" ]
then
 getSSLDomain "CA" "idm"
fi

#
LogFile=$logDir/SSLServerConfig_${timeStamp}.log
certobj="usercertificate"
wltobj="userpkcs12"
Alias=$hostName
ksName="identity.jks"
cleanCache $wltDir
cleanCache $jksDir
cleanCache $logDir
testConnection $host $port "$admuser" $lpasswd $LogFile
if [ "$component"  != "oam" ]
then
getPassword
fi
if [ "$component" != "oam" ]
then
downloadCA $host $port "$user" $lpasswd $sslDomain $caRoot $certobj $LogFile
downloadCA $host $port "$user" $lpasswd $sslDomain $caRoot $wltobj $LogFile
fi

## -----------------------------------------------------------------------------------------
## 2. Now you can call component script for particular component specific
## - OVD_SSL_Server_Config.sh for '-component ovd'
## - OID_SSL_Server_Config.sh for '-component oid'
## - DB_SSL_Server_Config.sh for '-component db'
## - WLS_SSL_Server_Config.sh for '-component wls' (for all J2EE applications)
## - OAM_SSL_Server_Config.sh for '-component oam 10g'
## -----------------------------------------------------------------------------------------
echo " "
setSSLBinDir
## -----------------------------------------------------------------------------------------
if [ "$component" = "oid" ]
then 
 printf "Invoking OID SSL Server Configuration Script...\n"
 getDN "oid-$timeStamp"
 genOracleWallet $caRoot $swpasswd $capasswd $dnName $timeStamp $OraPKI $LogFile $component
 echo ${sslBinDir}
 "${sslBinDir}"/OID_SSL_Server_Config.sh -ldappwd $lpasswd -keypwd $swpasswd -capwd $capasswd $verboseArg 
 exitcode=$?
fi
## -----------------------------------------------------------------------------------------
if [ "$component" = "ovd" ]
then 
 printf "Invoking OVD SSL Server Configuration Script...\n"
 getDN "ovd-$timeStamp"
 genKeyStoreJKS $keyTool $caRoot $dnName $Alias $ksName $swpasswd $capasswd $component $LogFile 
 "$sslBinDir"/OVD_SSL_Server_Config.sh -ldappwd $lpasswd -capwd $capasswd -keypwd $swpasswd "$verboseArg"
 exitcode=$?
fi
## -----------------------------------------------------------------------------------------
if [ "$component" = "oim" ]
then
 printf "Invoking OIM SSL Server Configuration Script...\n"
 getDN "oim-$timeStamp"
 genKeyStoreJKS $keyTool $caRoot $dnName $Alias $ksName $swpasswd $capasswd $component $LogFile
 "$sslBinDir"/WLS_SSL_Server_Config.sh $Alias -keypwd $swpasswd "$verboseArg"
 exitcode=$?
fi
## -----------------------------------------------------------------------------------------
if [ "$component" = "oam" ]
then 
 printf "Invoking OAM SSL Server Configuration Script...\n"
 getSSLDomain "CA" "oam"
 downloadCA $host $port "$user" $lpasswd $sslDomain $caRoot $certobj $LogFile
 downloadCA $host $port "$user" $lpasswd $sslDomain $caRoot $wltobj $LogFile
 getSSLDomain "Webgate" "wg" $domain
 if [ "$isDownloadCA" = "y" ]
 then
  downloadCA $host $port "$user" $lpasswd $sslDomain $caRoot/$domain $certobj $LogFile
 fi
 validatePath  "$sslBinDir" OAM_SSL_Server_Config.sh
 "$sslBinDir"/OAM_SSL_Server_Config.sh -pwd $capasswd
 exitcode=$?
fi
## -----------------------------------------------------------------------------------------
if [ "$component" = "ohs" ]
then
 getDN "ohs-$timeStamp"
 genOracleWallet $caRoot $swpasswd $capasswd $dnName $timeStamp $OraPKI $LogFile $component
 printf "Invoking OHS SSL Server Configuration Script...\n"
 validatePath  "$sslBinDir" OHS_SSL_Server_Config.sh
 "$sslBinDir"/OHS_SSL_Server_Config.sh
 exitcode=$?
fi
## -----------------------------------------------------------------------------------------
if [ "$component" = "wls" ]
then
 printf "Invoking Weblogic SSL Server Configuration Script...\n"
 getDN "wls-$timeStamp"
 genKeyStoreJKS $keyTool $caRoot $dnName $Alias $ksName $swpasswd $capasswd $component $LogFile 
 "$sslBinDir"/WLS_SSL_Server_Config.sh -keyalias $Alias -keypwd $swpasswd "$verboseArg"
 exitcode=$?
fi
## -----------------------------------------------------------------------------------------
# Cleaning up cache
if [ "$verbose" != "true" ]
then 
cleanCache $caRoot
fi
## -----------------------------------------------------------------------------------------
# Return the appropriate exit code
exit $exitcode
