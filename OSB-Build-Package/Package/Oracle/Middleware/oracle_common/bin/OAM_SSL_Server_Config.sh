#!/bin/sh
#
# $Header: entsec_network/jsrc/oracle/security/pki/OAM_SSL_Server_Config.sh /entsec_11.1.1.4.0_dwg/3 2011/09/28 21:49:48 qdinh Exp $
#
# OAM_SSL_Server_Config.sh
#
# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      OAM_SSL_Server_Config.sh - SSL server config script for OAM10
#
#    DESCRIPTION
#      You configure the server and client systems by running the shell 
#      scripts provided with this product. These scripts have been tested 
#      and found to work correctly on all supported operating systems.  
#      Do not modify the scripts, as inconsistent behavior might result.
#
#    NOTES
#      version: 11.1.1.6.0
#
#    MODIFIED   (MM/DD/YY)
#    qdinh       09/28/11 - bug 13032184
#    qdinh       08/16/11 - fix version
#    qdinh       06/29/11 - add SSL scripts
#    wxie        10/28/10 - additional fixes during testing
#    wxie        10/27/10 - Add exec permission, windows fix and temporary
#                           cacert conversion from DER to PEM
#    wxie        10/24/10 - review comments
#    wxie        10/22/10 - SSL server config script for OAM10
#    wxie        10/22/10 - Creation
#

# Turn off echoing variables
set +x
echo ""

export CA_ROOT="$ORACLE_HOME"/rootCA
export KSTORE="$CA_ROOT"/OAM
export LogFile="$KSTORE"/OAM_SSL_Server_Config.log
if [ "$OS" = "Windows_NT" ]
then
  export OraPKI="$ORACLE_HOME/../oracle_common/bin/orapki.bat"
else
  export OraPKI=$ORACLE_HOME/../oracle_common/bin/orapki
fi

clean()
{
  targetDir="$1"
  if [ -e "$targetDir" ]
  then
    rm -f "$targetDir"/* > /dev/null 
  else
    mkdir -p "$targetDir"
  fi
}

# Cleanup the temporary dir holding certificates
clean "$KSTORE"

# Pre-requisite:
# Check if root CA certificate and CA wallet exist at $OH/rootCA
if [ ! -e "$CA_ROOT"/cacert.der -o ! -e "$CA_ROOT"/ewallet.p12 ]
then
  printf "Either "$CA_ROOT"/cacert.der or "$CA_ROOT"/ewallet.p12 does not exist, please have both ready before running this script\n"
  exit
fi

printf ">>>Enter your OAM10 Access Server install location: [e.g. /scratch/aime/OAM10/access] "
read oamDir
echo ""

if [ ! -e "$oamDir"/oblix ]
then
  printf "$oamDir is invalid OAM10 Access Server install directory\n"
  exit
fi

"$oamDir"/oblix/tools/openssl/openssl x509 -in "$CA_ROOT"/cacert.der -inform DER -out "$KSTORE"/cacert.txt -outform PEM > "$LogFile" 2>&1
echo "****************************************************************"
echo "*** CA root cert has been converted from DER to PEM format.  ***"
echo "****************************************************************"
echo ""

# Cleanup aaa_req.pem aaa_key.pem in OAM config area before running
# configureAAAServer tool
rm -rf "$oamDir"/oblix/config/aaa_req.pem
rm -rf "$oamDir"/oblix/config/aaa_key.pem

# Reconfig AAA server in cert mode and request certificate
echo "****************************************************************"
echo "*** This script will first invoke configureAAAServer tool to ***"
echo "*** reconfig AAA server in cert mode, and then generate a    ***"
echo "*** certificate request. Please select 3(Cert), 1(request a  ***"
echo "*** certificate), and enter pass phrase for the first 3      ***"
echo "*** prompts. Otherwise, this script is not guaranteed to     ***"
echo "*** work properly.                                           ***"
echo "****************************************************************"
cfgAAAPath="$oamDir"/oblix/tools/configureAAAServer
cd "$cfgAAAPath"
./configureAAAServer reconfig "$oamDir"
echo ""

if [ ! -e "$oamDir"/oblix/config/aaa_req.pem -o ! -e "$oamDir"/oblix/config/aaa_key.pem ]
then
  echo "****************************************************************"
  printf "configureAAAServer is not run properly to generate a certificate request. Most likely you selected wrong options. Please read the notes at beginning and rerun the script.\n"
  exit
fi

echo "****************************************************************"
echo "*** Now we will sign the certificate request using CA cert.  ***"
echo "****************************************************************"
echo ""
stty -echo
while [ 1 ]
do
  printf ">>>Enter the CA wallet password: "
  read wltpasswd
  if [ "X$wltpasswd" = "X" ]
  then
    echo ""
    continue
  fi
  break
done
stty echo
echo ""

# Convert the certificate request (aaa_req.pem) in an orapki acceptable format
sed "s/CERTIFICATE REQUEST/NEW CERTIFICATE REQUEST/g" "$oamDir"/oblix/config/aaa_req.pem > "$KSTORE"/aaa_req.pem
echo ""
printf "Certificate request (aaa_req.pem) has been converted to orapki acceptable format in "$KSTORE"\n"
echo ""

# Sign the $KSTORE certificate request with the generated root CA at $OH/rootCA
# using 'orapki'
export TIMESTAMP=`date +%Y%m%d%H%M%S`
"$OraPKI" cert create -wallet "$CA_ROOT" -request "$KSTORE"/aaa_req.pem -cert "$KSTORE"/aaa_cert.pem -serial_num $TIMESTAMP -validity 365 -summary -pwd $wltpasswd >> "$LogFile" 2>&1

if [ ! -e "$KSTORE"/aaa_cert.pem ]
then
  printf "The certificate failed to be generated, please check the error and rerun the script\n"
  exit
else
  printf "The certificate has been signed by the root CA\n"
  echo ""
fi

# Install certificate into AAA server location
cp "$KSTORE"/aaa_cert.pem "$oamDir"/oblix/config/aaa_cert.pem
cp "$KSTORE"/cacert.txt "$oamDir"/oblix/config/aaa_chain.pem
# There's no need to copy aaa_key.pem since it's already in place after
# running configureAAAServer earier
echo "****************************************************************"
echo "*** OAM server certificate have been installed into Access   ***"
echo "*** Server config directory.                                 ***"
echo "****************************************************************"
echo ""

# Restart AAA Server
echo "****************************************************************"
echo "*** Restarting AAA Server ...                                ***"
echo "****************************************************************"
echo ""

if [ "$OS" = "Windows_NT" ]
then
  printf ">>> On windows NT, please restart your Access Server manually\n"
else
  printf "Do you want to restart your Access Server? [y/n] "
  read ansr
  echo ""
  
  if [ "X$ansr" = "Xy" -o "X$ansr" = "XY" ]
  then
    "$oamDir"/oblix/apps/common/bin/restart_access_server >> "$LogFile" 2>&1
  
    # Give some extra time for AAA server to startup
    sleep 20
  
    if [ "`grep "Access Server Exception" "$LogFile"`" != "" -o \
         "`grep "Access Server Watchdog cannot run" "$LogFile"`" != "" ]
    then
      printf "Access Server failed to be started, please check "$LogFile" for details\n"
      exit
    else
      printf "Access Server has been started/restarted\n"
    fi
  else
    printf ">>> Please restart Access Server manually later\n"
  fi
fi

echo ""
echo "****************************************************************"
echo "*** Your OAM10 Access Server has been setup successfully in  ***"
echo "*** cert mode.                                               ***"
echo "****************************************************************"
