#!/bin/sh
#
# SSLClientConfig.sh   version: 11.1.1.6.0
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
echo "SSL Automation Script: Release 11.1.1.6.0 - Production"
echo "Copyright (c) 2010 Oracle.  All rights reserved."
echo ""
echo "Downloading the CA certificate from a central LDAP location"
echo "Creating a common trust store in JKS and Oracle Wallet formats ..." 
echo "Configuring SSL clients with the common trust store..." 
echo "Make sure that your LDAP server is currently up and running."
echo " "

caRoot=$ORACLE_HOME/rootCA
export caRoot
OraComBin=$ORACLE_HOME/../oracle_common/bin
export OraComBin
trustStoreDir=$caRoot/keystores
export trustStoreDir
trustStoreName="trust.jks"
export trustStoreName
timeStamp=`date +%Y%m%d%H%M%S`
export timeStamp

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


Alias=${hostName}_demoCA
export Alias

Usage()
{
   this="$0"
   printf "Usage: $this -component [wls|ohs|webcache|webgate|oim -sub [oam|soa]] [-v [true/false] \n" 
   exit
}

Usage_silent()
{
   this="$0"
   printf "Usage: $this -h <ldap_hostname> [-p <ldap_port>] [-u <ldap_user>] [-pwd <ldap_password>] [-verbose [true/false]] -component \n"
   printf "        wls| ohs| webcache| oim -sub [oam| soa]] \n"
   printf "                [-domain <ssldomain>] -keystore [keystore_name] -keypwd [keypass] \n"
   printf "                [-domaindir <wls_domain_directory>] [-servername <wls_server_name>] [-wlsadmin <wls_admin_user>] \n"
   printf "                [-wlsadminport <wls_admin_port>] \n"
   printf "        webgate [-silent [y/n]] [-webgatedir <webgate_dir>] [-webgateid <webgate_id>] [-webgatepwd <webgate_password>] \n"
   printf "                [-oamserverhost <access_server_host>] [-oamserverport <access_server_port>] [-oamserverid <access_server_id>] \n" 
   printf "                [-webgatepassphrase <pass_phrase>] [-capwd <ca_wallet_password>] [-restart [y/n]] [-isohs [y/n]] \n"
   printf "                [-ohsOH <OHS_ORACLE_HOME>] [-ohsIH <OHS_INSTANCE_HOME>] [-ohsid <ohs_id>] -oamssldomain <oam_ssl_domain> \n"
   printf "        cacert \n"
   exit 0
}

##
## Read commandline arguments
##
getParams()
{
PARAM=$1 
VAL=$2 
case $PARAM in
     -component)    component=$VAL ;;
     -sub)          subcomp=$VAL ;;
     -h)            host=$VAL ;;
     -p)            PORT=$VAL ;;
     -u)            user=$VAL ;;
     -pwd)          lpasswd=$VAL ;;
     -domain)       domain=$VAL ;;
     -keystore)     kname=$VAL ;;
     -keypwd)       keypass=$VAL ;;
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
     -capwd)             capwd=$VAL
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
#---------------------------------------------------------------------------------------
errors()
{
 errortype=$1
 logfile=$2
 error=`cat $logfile| grep -i $errortype`
 if [ "X$error" != "X" ]
 then
  if [ "$errortype" = "file" ]
  then
   printf "Missing ldap command line tools\n"
  fi 
  if [ "$errortype" = "invalid" ]
  then
   printf "Invalid Credential\n"
  fi
  if [ "$errortype" = "cannot" ]
  then
   printf "Failed to connect to the LDAP server\n"
  fi
  if [ "$errortype" = "exception" ]
  then
   printf "Exception - Please check $logfile\n"
  fi
  if [ "$errortype" = "no" ]
  then
   printf "No such an object in the LDAP server\n"
  fi

  exit 1
 fi

}
validatePath()
{
bindir=$1
script=$2
 if [ ! -f "${bindir}/${script}" ]
 then 
   printf "Please set up SSL_BIN_DIR to the directory where $script located\n"
   exit 1
 fi

}
checkFile()
{
 infile=$1
 if [ ! -f $infile ]
 then
   printf "Error: $infile does not exist\n"
   exit 1
 fi
}
#---------------------------------------------------------------------------------------
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
checkFile "$ORACLE_HOME"/bin/ldapsearch
checkFile "$OraPKI"
printf ">>>Searching the LDAP for the CA ${object} ...\n"
"$ORACLE_HOME"/bin/ldapsearch -h $host -p $port -D "$admuser" -w $lpasswd -b  cn=demoCA,${sslDomain} -t -s base "(objectclass=*)" $object >> $logfile 2>&1
grep $object $logfile > $caRoot/${object}2_1.out 2>&1
sed "s/${object}=//g" $caRoot/${object}2_1.out > $caRoot/${object}2_2.out 2>&1
errors invalid $logfile
errors no $logfile

if [ "$object" = "userpkcs12" ]
then
 mv `cat $caRoot/${object}2_2.out`  $cadir/ewallet.p12
 ${OraPKI} wallet display -wallet $cadir -pwd $capasswd >> $logfile 2>&1
else
 mv  `cat $caRoot/${object}2_2.out`  $cadir/cacert.der
 wlsTrustDir=${trustStoreDir}/tmp
 alias="test"
 tpwd="fdaflkcae"
 cleanCache $wlsTrustDir
 genTrustStoreJKS $keyTool $wlsTrustDir "cn=test" $OraPKI $caRoot $alias $logfile $tpwd
 cleanCache $wlsTrustDir
fi


}
#---------------------------------------------------------------------------------------
getInput()
{
input=$1
prompt=$2
stty -echo
while [ 1 ]
do
  printf "$prompt"
  read $input
  if [ "X$input" = "X" ]
  then
    echo ""
    continue
  fi
  break
done
stty echo
echo " "
}
#---------------------------------------------------------------------------------------
getDN() 
{
  orgUnit=$1
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
  printf "Your certificate subject DN is $dnName\n"
}
#---------------------------------------------------------------------------------------
genOracleWallet()
{
opki=$1
cadir=$2
logfile=$3
component=$4
wltdir=$cadir/wallets/${component}
cleanCache $wltdir
echo " "
printf "Creating an Oracle SSL Client Wallet for $component...\n"
prompt=">>>Enter a password to protect your wallet: "
prompt2=">>>Enter confirmed password for your wallet: "

while [ 1 ]
do
  getInput wpwd "$prompt"
  getInput wpwd2 "$prompt2"
  if [ "X$wpass" != "X$wpass2" ]
  then
    continue
  fi
  break
done
stty echo
echo " "

$opki wallet create -wallet $wltdir -pwd $wpwd >> $logfile 2>&1
#To import the $wltdir certificate into the OID $wltdir wallet using  'orapki'  tool
$opki wallet add -wallet $wltdir -trusted_cert -cert $cadir/cacert.der -pwd $wpwd >> $logfile 2>&1
$opki wallet create -wallet $wltdir -auto_login -pwd $wpwd >> $logfile 2>&1
}
#---------------------------------------------------------------------------------------
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

#d.Import the CA certificate located at $OH/rootCA as a trusted certificate into the keystore 
printf "Import the existing CA at $cadir/cacert.der into keystore... "
$ktool -import -trustcacerts -alias rootca -file $cadir/cacert.der  -keystore  $kstore -storepass $kpasswd -noprompt >> $logfile 2>&1

#d.Import the CA certificate located at $OH/rootCA as a trusted certificate into the keystore 
printf "Import the server certificate at $ksdir into keystore... "
$ktool -importcert -noprompt -v  -alias $alias -file $ksdir/cert.txt  -keystore  $kstore -storepass $kpasswd -noprompt >> $logfile 2>&1
errors exception $logfile
}
#---------------------------------------------------------------------------------------
getPassword()
{

 if [ "$component" != "webgate" ]
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
    break
  done
  stty echo
  echo " " 
  stty -echo
  while [ 1 ]
  do
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

  if [ "$component" != "webgate" ]
  then
   printf ">>>Enter your keystore name: [clientkey.jks] "
   read kname
   if [ "X$kname" = "X" ]
   then
     ksName="clientkey.jks"
   else
    ksName=$kname
   fi
  fi
    
}
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

if [ "X$tmppwd" = "X" ]
then
 if [ "X$keypass" = "X" ]
 then
  prompt=">>>Enter a password to protect your truststore: "
  prompt2=">>>Enter confirmed password for your truststore: "

  while [ 1 ]
  do
    getInput trustStorePass "$prompt"
    getInput trustStorePass2 "$prompt2"
    if [ "X$trustStorePass" != "X$trustStorePass2" ]
    then
      continue
    fi
    break
  done
  stty echo
  echo " "
  else 
   trustStorePass=$keypass
  fi
else
 trustStorePass=$tmppwd
fi

if [ ! -e $ksdir ] 
then
printf "Create directory $ksdir"
mkdir -p $ksdir
printf "\n"
fi
# Generate keystore or ewallet
if [ ! -f $kstore ]
then
$ktool  -genkey -alias testkey -keystore $kstore -storepass $trustStorePass -keyalg rsa -dname $dname -keypass $trustStorePass > $logfile 2>&1
$opki wallet create -wallet $ksdir -pwd $trustStorePass >> $logfile 2>&1
else
 printf "Updating the existing $kstore...\n"
fi

#b. Import CA certificate located at $OH/rootCA into the CTS 
if [ -f $cadir/cacert.der ]
then
 printf "Importing the CA certifcate into trust stores...\n"
 $ktool -importcert -noprompt -trustcacerts -alias $alias -file $caRoot/cacert.der -keystore  $kstore -storepass $trustStorePass >> $logfile 2>&1

 printf ">>>The common trust store in JKS format is located at $kstore\n" 
 # Import CA certifcate into ewallet.p12

 $OraPKI wallet add -wallet $ksdir -trusted_cert -cert $caRoot/cacert.der -pwd $trustStorePass >> $logfile 2>&1
 printf ">>>The common trust store in Oracle wallet format is located at $ksdir/ewallet.p12\n"

 # export the ca cert to pem format back to cacert_tmp.txt
$keyTool -exportcert -rfc -alias $alias -file $cadir/cacert_tmp.txt -keystore $kstore -storepass $trustStorePass >> $logfile 2>&1 
 if [ -f $cadir/cacert.txt ]
 then
   echo " " >> $cadir/cacert.txt
   cat $cadir/cacert_tmp.txt >> $cadir/cacert.txt
 else
   cat $cadir/cacert_tmp.txt > $cadir/cacert.txt
   echo " " >> $cadir/cacert.txt
 fi

fi

if [ "$verbose" = "true" ]
then 
 $ktool -list -v -keystore $kstore -storepass $trustStorePass 
 $opki wallet display -wallet $ksdir -pwd $trustStorePass
 cat $cadir/cacert_tmp.txt
fi
 rm -f $cadir/cacert_tmp.txt
}
#---------------------------------------------------------------------------------------
testConnection()
{
host=$1
port=$2
user=$3
lpwd=$4
logf=$5
checkFile "${ORACLE_HOME}"/bin/ldapbind
${ORACLE_HOME}/bin/ldapbind -h $host -p $port -D "$user" -w $lpwd > $logf 2>&1 
errors file $logf
errors invalid $logf
errors cannot  $logf

}
#---------------------------------------------------------------------------------------
setSSLBinDir()
{
    if [ "X$SSL_BIN_DIR" = "X" ]
    then 
       sslBinDir="$OraComBin"
    else
       sslBinDir="$SSL_BIN_DIR"
    fi
}
#---------------------------------------------------------------------------------------
checkEnv()
{
envVar=$1
 if [ "X$envVar" = "X" ]
 then 
  printf "Please set your $envVar\n"
 exit
fi

}
#---------------------------------------------------------------------------------------
cleanCache()
{
targetDir=$1
if [ -e $targetDir ]
then
    rm -f $targetDir/* > /dev/null 2>&1 
else
    mkdir -p $targetDir
fi

}
#---------------------------------------------------------------------------------------
# Read setenv  input

if [ "X$1" = "X" ]
then
   Usage $0
else  
   if [ "X$2" = "X" ] 
   then
     Usage $0
   fi
fi

checkEnv ORACLE_HOME
if [ "X$JAVA_HOME" = "X" ]
then 
  JAVA_HOME=$ORACLE_HOME/../jdk160_21
  keyTool=$JAVA_HOME/bin/keytool
  if [ ! -e $keyTool ] 
  then
    printf "$keyTool does not exist\n"
    printf "Please set your JAVA_HOME\n"
  fi 
fi
getSSLDomain()
{ 
CA="$1"
defval="$2"
 printf ">>>Enter the sslDomain for the $CA [$defval]: " 
 read domain
 if [ "X$domain" = "X" ]
 then
   domain="$defval"
 fi
 sslDomain="cn=$domain,cn=sslDomains"
 isDownloadCA="y"
 if [ "X$domain" = "X$domain1" ]
 then
  isDownloadCA="n"
 fi
}
keyTool=$JAVA_HOME/bin/keytool
cleanCache $caRoot
#---------------------------------------------------------------------------------------
# Get input parameters
printf "Downloading the CA certificate from the LDAP server...\n"

if [ "X$1" = "X" ]
then
  Usage $0
  exit 1
fi
while [ "X$1" != "X" ]
do
getParams $1 $2
shift; shift;
done

if [ "X$host" = "X" ]
then
 printf ">>>Enter the LDAP hostname [$hostName]: "
 read host
 if [ "X$host" = "X" ]
 then 
   host=`hostname`
   export host
 fi
fi

if [ "X$PORT" = "X" ]
then 
 printf ">>>Enter the LDAP port: [3060]? "
 read port
 if [ "X$port" = "X" ]
 then 
   port=3060
   export port
 fi
else 
   port=$PORT
fi

if [ "X$user" = "X" ]
then
 printf ">>>Enter your LDAP user [cn=orcladmin]: " 
 read user
 if [ "X$user" = "X" ]
 then 
   user="cn=orcladmin"
   export user
 fi
fi

if [ "X$lpasswd" = "X" ]
then
 stty -echo
 while [ 1 ]
 do
   printf ">>>Enter password for $user: "
   read lpasswd
   if [ "X$lpasswd" = "X" ]
   then
     echo " "
     continue
   fi
   break
 done
 stty echo
 echo " "
fi

getSSLDomain "CA" "idm"
##if [ "X$domain" = "X" ]
##then
## printf ">>>Enter the sslDomain for the CA [idm]: " 
## read domain
## if [ "X$domain" = "X" ]
## then
##   domain="idm"
## fi
##fi
##
LogFile=${trustStoreDir}/SSLClientConfig_${timeStamp}
#sslDomain="cn=$domain,cn=sslDomains"
certobj="usercertificate"
testConnection $host $port "$user" $lpasswd $LogFile
downloadCA $host $port "$user" $lpasswd $sslDomain $caRoot $certobj $LogFile
#---------------------------------------------------------------------------------------
#
# Configure WLS client truststore by invoking related component scripts
#---------------------------------------------------------------------------------------
setSSLBinDir
dnName="cn=demo,cn=testentry"

if [ "$component" = "cacert" ]
then
   printf "Generate trust store for the CA cert at $sslDomain\n"
    trustDir=${trustStoreDir}/common
   genTrustStoreJKS $keyTool $trustDir $dnName $OraPKI $caRoot "${Alias}_${domain}" $LogFile
fi

if [ "$component" = "wls" ]
then
    printf "Invoking Weblogic SSL Client Configuration Script...\n"
    wlsTrustDir=${trustStoreDir}/wls
    genTrustStoreJKS $keyTool $wlsTrustDir $dnName $OraPKI $caRoot "${Alias}_${domain}" $LogFile
    validatePath "$sslBinDir" WLS_SSL_Client_Config.sh
    "${sslBinDir}/WLS_SSL_Client_Config.sh" -trustfile $trustStoreName -pwd $trustStorePass  $domainDirArg $serverNameArg $wlsAdminArg $wlsAdminPassArg $wlsAdminPortArg $verboseArg
fi
#------------------------------------------------
# Configure oim client keystores and trust stores
#------------------------------------------------
if [ "$component" = "oim" ]
then
    printf "Invoking OIM SSL Client Configuration Scripts...\n" 
    if [ "$subcomponent" = "oam" ]
    then 
     # Need to download the CA wallet for signing OIM certificate to talk to OAM
      wltobj="userpkcs12"
      downloadCA $host $port "$user" $lpasswd $sslDomain $caRoot $wltobj $LogFile
      getPassword
      getDN
      oim_alias=${hostName}_"oimoam"
      genKeyStoreJKS $keyTool $caRoot $dnName $oim_alias $ksName $swpasswd $capasswd $component $LogFile
      validatePath "$sslBinDir" OIMOAM_SSL_Client_Config.sh
      "${sslBinDir}/OIMOAM_SSL_Client_Config.sh"  -file $kstore -pwd $swpasswd $oim_alias $verbose
    fi

    if [ "$subcomponent" = "soa" ]
    then
      oim_alias=${hostName}_"demoCA"
      wlsTrustDir=${trustStoreDir}/oim
      genTrustStoreJKS $keyTool $wlsTrustDir $dnName $OraPKI $caRoot $oim_alias $LogFile
      validatePath "$sslBinDir" OIMSOA_SSL_Client_Config.sh
      "${sslBinDir}/OIMSOA_SSL_Client_Config.sh"  -file $trustStoreName -pwd $trustStorePass $verbose
    fi
fi 

#------------------------------------------------
# Configure OAM Webgate keystore
#------------------------------------------------

if [ "$component" = "webgate" ]
then
    wlsTrustDir=${trustStoreDir}/webgate
    printf "Invoking Webgate SSL Client Configuration Script...\n"
    wltobj="userpkcs12"
    # webgate needs to have a client cert and trust therefore need to download
    # a full CA wallet to sign webgate client certificate
    getPassword
    downloadCA $host $port "$user" $lpasswd $sslDomain $caRoot $wltobj $LogFile
    if [ "X$oamssldomain" = "X" ]
    then
       getSSLDomain "OAM server"  "oam"
    else
       sslDomain="cn=$domain,cn=sslDomains"
    fi
    downloadCA $host $port "$user" $lpasswd $sslDomain $caRoot $certobj $LogFile
    validatePath "$sslBinDir" OAMWG_SSL_Client_Config.sh
    "${sslBinDir}/OAMWG_SSL_Client_Config.sh" $silentArg $webgateDirArg $webgateIdArg $webgatePwdArg $oamHostArg $oamPortArg $oamIdArg $webgatePPArg $caPwdArg $restartArg $isohsArg $ohsOHArg $ohsIHArg $ohsIdArg
fi

#------------------------------------------------
# Configure Webcache Oracle wallet
#------------------------------------------------
if [ "$component" = "webcache" ]
then
    printf "Invoking Webcache SSL Client Configuration Script...\n"
    genOracleWallet $OraPKI $caRoot $LogFile $component
    validatePath "$sslBinDir" OAMWC_SSL_Client_Config.sh
    "${sslBinDir}/OAMWC_SSL_Client_Config.sh" -trustfile $trustStoreName -pwd $trustStorePass $verbose
fi

#------------------------------------------------
# Configure OHS client wallet
#------------------------------------------------
if [ "$component" = "ohs" ]
then
    printf "Invoking Webcache SSL Client Configuration Script...\n"   
    genOracleWallet $OraPKI $caRoot $LogFile $component
    validatePath "$sslBinDir" OHS_SSL_Client_Config.sh
    "${sslBinDir}/OHS_SSL_Client_Config.sh" -trustfile $trustStoreName -pwd $trustStorePass $verbose
fi
if [ "$component" != "ohs" -a "$component" != "webcache" -a "$component" != "webgate" -a  "$component" != "wls" -a "$component" != "oim"  -a "$component" != "cacert" ]
then 
   printf "Product $component is not supported yet...\n"
fi
#------------------------------------------------
if [ "$verbose" != "true" ] 
then
 cleanCache $caRoot
fi
