#!/bin/sh
##
## SSLGenCA.sh version: 11.1.1.6.0
## 
## This script uses OraPKI tool to generate a Demo Signing CA wallet
## It will upload the wallet to an central LDAP directory
## Its access is restricted by appropriate contaiment
## - SSL Admin group
## - associated ACIs
## It will upload the CA certificate for public access
## - The demo CA wallet password will be persisted in the $OH
## ,where it is invoked, in an obfuscated file (or a smart card)
## - If there is an exiting CA in the LDAP, the script should
## fail and advice the admin to take some actions
##   + by deleting the entries before proceeding.
## This script should be run once in an IDM & FA deployment, unless
## you need to replace the existing CA.
## 
## Copyright (c) 2008, 2010, Oracle and/or its affiliates. All rights reserved. 
##
## Configuration Scripts Disclaimer:
## You configure the server and client systems by running the shell 
## scripts provided with this product. These scripts have been tested 
## and found to work correctly on all supported operating systems.  
## Do not modify the scripts, as inconsistent behavior might result.
## 
## This script can be located in $OH/common/bin
## Creation: 09/23/2010
## By Quan Dinh
##
##
echo ""
echo "SSL Certificate Authority Generation Script: Release 11.1.1.6.0 - Production"
echo "Copyright (c) 2010 Oracle.  All rights reserved."
echo " "
CA_ROOT=$ORACLE_HOME/rootCA
export CA_ROOT
CA_CRED=$ORACLE_HOME/credCA
export CA_CRED
TIMESTAMP=`date +%Y%m%d%H%M%S`
export TIMESTAMP
CN=CN=$TIMESTAMP-Demo-CA
export CN
DN=$CN',O=myCompany,C=US'
export DN

OS=`uname`

DOMAIN=`domainname`

if [ "$OS" = "Windows_NT" ]
then
OraPKI="$ORACLE_HOME"/../oracle_common/bin/orapki.bat
export OraPKI
HostName=`hostname`
export HostName
elif [ "$OS" = "Linux" ]
then
OraPKI="$ORACLE_HOME"/../oracle_common/bin/orapki
export OraPKI
HostName=`hostname -f`
export HostName
elif [ "$OS" = "AIX" ]
then
OraPKI="$ORACLE_HOME"/../oracle_common/bin/orapki
export OraPKI
HostName=`hostname`
export HostName
elif [ "$OS" = "SunOS" ] || [ "$OS" = "HP-UX" ]
then
OraPKI="$ORACLE_HOME"/../oracle_common/bin/orapki
export OraPKI
HostName=`hostname`
HostName="${HostName}.$DOMAIN"
export HostName
else
HostName=`hostname`
export HostName
fi


####### Enter a password for the common trust store
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
  if [ "$errortype" = "violation" ]
  then
   printf ">>>ldapmodify violation\n"
  fi
  printf ">>>Failed to generate CA certificate\n"
  printf ">>>Check $logfile for more information\n"
  exit 1
 fi

}
cleanCache()
{
dir=$1
if [ -e $dir ]
then
    rm -f dir/* > /dev/null 
else
    mkdir -p $dir
fi
}
cleanCache $CA_ROOT
cleanCache $CA_CRED

printf "************************************************************************\n"
printf "*********** This tool will generate a self-signed CA wallet ************\n"
printf "*********** and store it in a central LDAP directory        ************\n"
printf "*********** for IDM and FA SSL set up and provisioning       ************\n"
printf "************************************************************************\n"

if [ "X${ORACLE_HOME}" = "X" ]
then 
 printf "Please set your ORACLE_HOME\n"
 exit
fi

if [ "X$JAVA_HOME" = "X" ]
then 
 JAVA_HOME=${ORACLE_HOME}/../jdk160_21
 if [ ! -f ${JAVA_HOME}/bin/keytool ]
 then 
 printf ">>>Please set your JAVA_HOME correctly\n"
 exit
 fi 
fi

if [ -f $CA_ROOT/ewallet.p12 ]
then
  printf ">>>Do you want to remove the existing CA wallet?[y/n] "
  read ans
  if [ "X$ans" = "Xn" ]
  then
    exit
  else 
   rm -fr $CA_ROOT/*
  fi 
fi

####### Create an entry for the CA in LDAP using ldapadd 
printf ">>>Enter the LDAP hostname [$HostName]: " 
read host
if [ "X$host" = "X" ]
then
host=$HostName
export host
fi

printf ">>>Enter the LDAP port [3060]: "
read port
if [ "X$port" = "X" ]
then
port="3060"
export port
fi 

printf ">>>Enter the admin user [cn=orcladmin] "
read admuser
if [ "X$admuser" = "X" ] 
then
   admuser="cn=orcladmin"
   export admuser
fi

stty -echo
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

printf ">>>Enter the LDAP sslDomain where your CA will be stored [idm]: "
read ldapSSLdomain

if [ "X$ldapSSLdomain" = "X" ] 
then
   sslDomain="cn=idm,cn=sslDomains"
   export sslDomain
else
   sslDomain="cn=$ldapSSLdomain,cn=sslDomains"
   export sslDomain
fi

####### Check the existing of the LDAP entry
LogFile=$CA_ROOT/genca.log
if [ ! -f $ORACLE_HOME/bin/ldapsearch ]
then
 printf "Missing $ORACLE_HOME/bin/ldapsearch...\n"
 exit
fi

${ORACLE_HOME}/bin/ldapsearch -h $host -p $port -D "$admuser" -w $lpasswd -s base -b cn=demoCA,${sslDomain} "objectclass=*" dn > $LogFile 2>&1

errors cannot $LogFile
errors invalid $LogFile

 # If there is an existing entry then warn the admin to remove it manually.
existCA=`cat $LogFile|grep -i ca`
export existCA
if [ "X$existCA" != "X" ]
then
 printf "*********************************WARNING *********************************************\n"
 printf "*********** There exists a Certificate Authority wallet in the LDAP server ***********\n"
 printf "*********** Remove the CA can affect your current SSL deployment environment *********\n"
 printf "*********************************WARNING *********************************************\n"
 echo " " 
 printf ">>>Do you want to remove your CA at cn=demoCA,${sslDomain}? [y/n] "
 read isremove
if [ ! -f $ORACLE_HOME/bin/ldapdelete ]
then
 printf "Missing $ORACLE_HOME/bin/ldapdelete...\n"
 exit
fi
 if [ "X$isremove" = "Xy" ]
 then
  ${ORACLE_HOME}/bin/ldapdelete -h $host -p $port -D "$admuser" -w $lpasswd cn=sslAdmins,cn=demoCA,${sslDomain} cn=demoCA,${sslDomain} >> $LogFile 2>&1
 else   
   rm -rf $CA_ROOT
   exit
 fi  
fi 
stty -echo
while [ 1 ]
do
  printf ">>>Enter a password to protect your CA wallet: "
  read wpasswd
  if [ "X$wpasswd" = "X" ]
  then
    echo ""
    continue
  fi
  stty echo
  echo " "
  stty -echo
  printf ">>>Enter confirmed password for your CA wallet: "
  read wpasswd2
  echo " " 
  if [ "$wpasswd2" != "$wpasswd" ] 
  then
    printf ">>>The password and the confirmed password are mismatched.\n"
    continue
  fi
  break
  done
  stty echo
  echo " "


printf "Generate a new CA Wallet...\n"
"$OraPKI" wallet create -wallet $CA_ROOT -pwd $wpasswd >> $LogFile 2>&1
"$OraPKI" wallet add -wallet $CA_ROOT -dn $DN -keysize 2048 -self_signed -validity 3650 -pwd $wpasswd >> $LogFile 2>&1
"$OraPKI" wallet display -wallet $CA_ROOT -pwd $wpasswd > /dev/null 2>&1
"$OraPKI" wallet export -wallet $CA_ROOT -dn $DN -cert $CA_ROOT/cacert.txt -pwd $wpasswd >> $LogFile 2>&1
"$OraPKI" wallet pkcs12_to_jks -wallet $CA_ROOT -pwd $wpasswd -jksKeyStoreLoc $CA_ROOT/ca.jks -jksKeyStorepwd $wpasswd >> $LogFile 2>&1
"$JAVA_HOME"/bin/keytool -exportcert -alias orakey -keystore $CA_ROOT/ca.jks -file $CA_ROOT/cacert.der -storepass $wpasswd >> $LogFile 2>&1
 
####### Create container for SSLDomain and certifcate authority
echo "dn:cn=sslDomains
cn: sslDomains
objectclass: top
objectclass: orclContainer

dn: $sslDomain
objectclass: top
objectclass: orclContainer
cn: $sslDomain

dn: cn=groups,$sslDomain
objectclass: top
objectclass: orclContainer
cn: groups

dn: cn=users,$sslDomain
objectclass: top
objectclass: orclContainer
cn: users" > $CA_ROOT/ssldomain.ldif 2>&1

####### Create an entry for the CA wallet storage using ldapadd

echo "dn:cn=demoCA,${sslDomain}
objectclass:inetOrgPerson
cn: demoCA
sn: $TIMESTAMP-Demo-CA
userpassword: $wpasswd" > ${CA_ROOT}/caentry.ldif
      
# Create an SSL Admin entry
echo "dn: cn=sslAdmins,cn=groups,${sslDomain}
uniquemember: cn=orcladmin
description: SSL Wallet Administrators Group for $sslDomain
objectclass: orclprivilegegroup
objectclass: groupOfUniqueNames
objectclass: orclacpgroup" > $CA_ROOT/ssladm.ldif 2>&1

printf "Create SSL Domains Container for $sslDomain...\n"
${ORACLE_HOME}/bin/ldapadd -h $host -p $port -c -D "$admuser" -w $lpasswd -f ${CA_ROOT}/ssldomain.ldif >> $LogFile 2>&1
errors cannot $LogFile

printf "Storing the newly generated CA to the LDAP...\n"


####### Create an entry for the CA 
${ORACLE_HOME}/bin/ldapadd -h $host -p $port -D "$admuser" -w $lpasswd -f ${CA_ROOT}/caentry.ldif >> $LogFile 2>&1
errors cannot $LogFile

####### create and ssl admin entry
${ORACLE_HOME}/bin/ldapadd -h $host -p $port -D "$admuser" -w $lpasswd -f ${CA_ROOT}/ssladm.ldif >> $LogFile 2>&1
errors cannot $LogFile

####### upload the wallet binary into the CA entry
echo "dn:cn=demoCA,${sslDomain}
changetype:modify
add: userPKCS12
userPKCS12:$CA_ROOT/ewallet.p12
-
userCertificate:$CA_ROOT/cacert.der" > $CA_ROOT/cawallet.ldif 2>&1
${ORACLE_HOME}/bin/ldapmodify -h $host -p $port -D "$admuser" -w $lpasswd -b -v -f $CA_ROOT/cawallet.ldif >> $LogFile 2>&1
errors cannot $LogFile

######## set up an ACL for SSL admin and wallet protection
echo "dn:cn=demoCA,${sslDomain}
changetype:modify
add:orclaci
orclaci: access to entry by group=\"cn=sslAdmins, cn=demoCA,${sslDomain}\" (browse,add,delete) by * (browse)
-
add:orclaci
orclaci: access to attr!=(userPKCS12,orclaci,uniquemember) by group=\"cn=sslAdmins, cn=demoCA,${sslDomain}\" (read,search,write,compare) by * (read,search,compare)
-
add:orclaci
orclaci: access to attr=(userPKCS12,orclaci,uniquemember) by group=\"cn=sslAdmins, cn=demoCA,${sslDomain}\" (read,search,write,compare) by * (none)" > $CA_ROOT/sslaci.ldif  2>&1

printf "Set up ACL to protect the CA wallet...\n"
${ORACLE_HOME}/bin/ldapmodify -h $host -p $port -D "$admuser" -w $lpasswd -b -v -f $CA_ROOT/sslaci.ldif >> $LogFile 2>&1
errors violation $LogFile

######## Store wallet password to an CSF file using mkstore 
# a. To create an auto login wallet you do the following:
${ORACLE_HOME}/bin/mkstore -wrl $CA_CRED/castore -createALO  >> $LogFile 2>&1

# b. To add a secret into it you do the following:
${ORACLE_HOME}/bin/mkstore -wrl $CA_CRED/castore -createEntry capassword $wpasswd >> $LogFile 2>&1

# c. Finally to extract the secret, you'd do the following and you'd get the output described:
if [ "$1" = "-v" ]
then 
mkstore -wrl $CA_CRED/castore -viewEntry capassword >> $LogFile 2>&1
fi

######## Testing by downloading the CA wallet and the server certificate

if [ "$1" = "-v" ]
then
ldapsearch -h $host -p $port -D "$admuser" -w $lpasswd -b  cn=demoCA,${sslDomain} -t -s base "(objectclass=*)" userpkcs12 >> $LogFile 2>&1
ldapsearch -h $host -p $port -D "$admuser" -w $lpasswd -b cn=demoCA,${sslDomain}  -t -s base "(objectclass=*)" usercertificate >> $LogFile 2>&1
errors cannot $LogFile
errors invalid $LogFile
fi

printf ">>>The newly generated CA is stored in LDAP entry cn=demoCA,$sslDomain successfully.\n"
#rm -fr $CA_ROOT

