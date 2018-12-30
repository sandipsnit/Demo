#!/bin/sh
#
# $Header: entsec_network/jsrc/oracle/security/pki/OAMWG_SSL_Client_Config.sh /entsec_11.1.1.4.0_dwg/3 2011/09/28 21:49:48 qdinh Exp $
#
# OAMWG_SSL_Client_Config.sh
#
# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      OAMWG_SSL_Client_Config.sh - SSL client config script for 10g webgate
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
#    wxie        10/27/10 - Add exec permission, windows fix, temporary
#                           cacert conversion from DER to PEM, and OHS restart
#                           fix
#    wxie        10/24/10 - review comments
#    wxie        10/22/10 - SSL client config script for 10g webgate
#    wxie        10/22/10 - Creation
#

# Turn off echoing variables
set +x
echo ""

export CA_ROOT="$ORACLE_HOME"/rootCA
export KSTORE="$CA_ROOT"/WEBGATE
export LogFile="$KSTORE"/OAMWG_SSL_Client_Config.log
if [ "$OS" = "Windows_NT" ]
then
  export OraPKI="$ORACLE_HOME/../oracle_common/bin/orapki.bat"
  export HOSTNAME=`hostname`
else
  export OraPKI=$ORACLE_HOME/../oracle_common/bin/orapki
  export HOSTNAME=`hostname -f`
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

printf ">>>Enter your 10g WebGate install location: [e.g. /scratch/aime/wg10/access] "
read wgDir
echo ""

if [ ! -e "$wgDir"/oblix ]
then
  printf "$wgDir is invalid 10g WebGate install directory\n"
  exit
fi

"$wgDir"/oblix/tools/openssl/openssl x509 -in "$CA_ROOT"/cacert.der -inform DER -out "$KSTORE"/cacert.txt -outform PEM > "$LogFile" 2>&1
echo "****************************************************************"
echo "*** CA root cert has been converted from DER to PEM format.  ***"
echo "****************************************************************"
echo ""

while [ 1 ]
do
  printf ">>>Enter WebGate ID: "
  read wgid
  if [ "X$wgid" = "X" ]
  then
    echo ""
    continue
  fi
  break
done
echo ""

# WebGate password can be empty
stty -echo
printf ">>>Enter WebGate Password: "
read wgpasswd
stty echo
echo ""
echo ""

printf ">>>Enter the Access Server Host Name [$HOSTNAME]: "
read host
echo ""

if [ "X$host" = "X" ]
then
  export host=$HOSTNAME
fi

printf ">>>Enter the Access Server Port [6021]: "
read port
echo ""

if [ "X$port" = "X" ]
then
   export port=6021
fi

while [ 1 ]
do
  printf ">>>Enter Access Server ID: "
  read aaaid
  if [ "X$aaaid" = "X" ]
  then
    echo ""
    continue
  fi
  break
done
echo ""

stty -echo
while [ 1 ]
do
  printf ">>>Enter WebGate Pass Phrase: "
  read wgpassphr
  if [ "X$wgpassphr" = "X" ]
  then
    echo ""
    continue
  fi
  break
done
stty echo
echo ""
echo ""

# Cleanup aaa_req.pem aaa_key.pem in webgate config area before running
# configureAAAServer tool
rm -rf "$wgDir"/oblix/config/aaa_req.pem
rm -rf "$wgDir"/oblix/config/aaa_key.pem

# Reconfig webgate in cert mode and request certificate
echo "****************************************************************"
echo "*** This script will first invoke configureWebGate tool to   ***"
echo "*** reconfig webgate in cert mode, and then generate a       ***"
echo "*** certificate request.                                     ***"
echo "****************************************************************"
cfgWG="$wgDir"/oblix/tools/configureWebGate/configureWebGate
"$cfgWG" -i "$wgDir" -t WebGate -w $wgid -m cert -c request -h $host -p $port -a $aaaid -r $wgpassphr -P "$wgpasswd"
echo ""

if [ ! -e "$wgDir"/oblix/config/aaa_req.pem -o ! -e "$wgDir"/oblix/config/aaa_key.pem ]
then
  echo "****************************************************************"
  printf "configureWebGate is not run properly to generate a certificate request. Most likely you provided wrong parameters. Please rerun the script and make sure you enter right parameter values when prompted.\n"
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
sed "s/CERTIFICATE REQUEST/NEW CERTIFICATE REQUEST/g" "$wgDir"/oblix/config/aaa_req.pem > "$KSTORE"/aaa_req.pem
echo ""
printf "Certificate request (aaa_req.pem) has been converted to orapki acceptable format in "$KSTORE"\n"
echo ""

# Sign the "$KSTORE" certificate request with the generated root CA at
# $OH/rootCA using orapki
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

# Install certificate into webgate location
cp "$KSTORE"/aaa_cert.pem "$wgDir"/oblix/config/aaa_cert.pem
cp "$KSTORE"/cacert.txt "$wgDir"/oblix/config/aaa_chain.pem
# There's no need to copy aaa_key.pem since it's already in place after
# running configureWebGate earier
echo "****************************************************************"
echo "*** WebGate certificate have been installed into WebGate     ***"
echo "*** config directory.                                        ***"
echo "****************************************************************"
echo ""

# Test connection
echo "****************************************************************"
echo "*** Testing connection to AAA Server ...                     ***"
echo "*** (Make sure AAA Server is up and running.)                ***"
echo "****************************************************************"
"$cfgWG" -i "$wgDir" -t WebGate -w $wgid -m cert -c install -h $host -p $port -a $aaaid -r $wgpassphr -P "$wgpasswd" -S
echo ""

# Restart Webserver
echo "****************************************************************"
echo "*** Restarting Webserver ...                                 ***"
echo "****************************************************************"
echo ""

if [ "$OS" = "Windows_NT" ]
then
  printf ">>> On windows NT, please restart your webserver manually\n"
else
  printf "Do you want to restart your webserver? [y/n] "
  read ansr
  echo ""

  if [ "X$ansr" = "Xy" -o "X$ansr" = "XY" ]
  then
    printf "Is your webserver OHS? [y/n] "
    read isohs
    echo ""
  
    if [ "X$isohs" = "Xy" -o "X$isohs" = "XY" ]
    then
      printf ">>>Enter ORACLE_HOME for your OHS webtier install [e.g. /scratch/aime/WT/Oracle_WT1]: "
      read ohsOH
      echo ""
    
      if [ ! -e "$ohsOH"/opmn/bin/opmnctl ]
      then
        printf ">>> $ohsOH is invalid webtier Oracle Home\n"
        printf ">>> Please restart OHS manually later\n"
        exit
      fi
    
      printf ">>>Enter ORACLE_INSTANCE for your OHS webtier instance [e.g. /scratch/aime/WT/Oracle_WT1/instances/instance1]: "
      read ohsIH
      echo ""
    
      if [ ! -e "$ohsIH"/OHS ]
      then
        printf ">>> $ohsIH is invalid Instance Home\n"
        printf ">>> Please restart OHS manually later\n"
        exit
      fi
    
      printf ">>>Enter OHS component id [ohs1]: "
      read ohsinst
      echo ""
    
      if [ "X$ohsinst" = "X" ]
      then
        export ohsinst="ohs1"
      fi
    
      export ORACLE_HOME="$ohsOH"
      export ORACLE_INSTANCE="$ohsIH"
    
      # Get OHS instance status
      "$ORACLE_HOME"/opmn/bin/opmnctl status > "$KSTORE"/status.out 2>&1
    
      # Start opmn if not already started
      if [ "`grep "opmn is not running" "$KSTORE"/status.out`" != "" ]
      then
        "$ORACLE_HOME"/opmn/bin/opmnctl start
      fi
      
      # Depending on OHS instance status, start or restart
      if [ "`grep $ohsinst "$KSTORE"/status.out|grep Alive`" != "" ]
      then
        "$ORACLE_HOME"/opmn/bin/opmnctl restartproc ias-component="$ohsinst" >> "$LogFile" 2>&1
      else
        "$ORACLE_HOME"/opmn/bin/opmnctl startproc ias-component="$ohsinst" >> "$LogFile" 2>&1
      fi
    
      # Remove temp file
      rm -rf "$KSTORE"/status.out

      printf "OHS instance has been started/restarted\n"

    else  # not OHS
      printf ">>> For webserver other than OHS, please restart manually later\n"
    fi
  else  # ansr is no
    printf ">>> Please restart your webserver manually later\n"
  fi
fi

echo ""
echo "****************************************************************"
echo "*** Your 10g WebGate has been setup successfully in cert     ***"
echo "*** mode.                                                    ***"
echo "****************************************************************"
