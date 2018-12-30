#!/bin/sh
# Copyright (c) 2009, 2011, Oracle and/or its affiliates. All rights reserved. 

cleanup()
{
  [ -d "${CIE_TMPDIR}" ] && rm -rf "${CIE_TMPDIR}"
}

mypwd="`pwd`"

# Determine the location of this script...
# Note: this will not work if the script is sourced (. ./config.sh)
SCRIPTNAME=$0
case "${SCRIPTNAME}" in
 /*)  SCRIPTPATH=`dirname "${SCRIPTNAME}"` ;;
  *)  SCRIPTPATH=`dirname "${mypwd}/${SCRIPTNAME}"` ;;
esac

CLASSPATHSEP=:

case "${OS}" in
Windows_NT*)
  CLASSPATHSEP=\;
;;
CYGWIN*)
  CLASSPATHSEP=\;
;;
esac
export CLASSPATHSEP

MW_HOME="${MW_HOME:-${SCRIPTPATH}/../../..}"
if [ -d "${MW_HOME}" ]
then
  MW_HOME=`cd "${MW_HOME}"; pwd`
fi

COMMON_COMPONENTS_HOME="${COMMON_COMPONENTS_HOME:-${SCRIPTPATH}/../..}"
if [ -d "${COMMON_COMPONENTS_HOME}" ]
then
  COMMON_COMPONENTS_HOME=`cd "${COMMON_COMPONENTS_HOME}"; pwd`
fi

SETHOME=${COMMON_COMPONENTS_HOME}/common/bin/setWasHome.sh

if [ -z "${WAS_HOME}" -a -r "${SETHOME}" ]
then
  . ${SETHOME}
fi

if [ -f "${WAS_HOME}/lib/startup.jar" ]
then
  WAS_HOME=`cd "${WAS_HOME}"; pwd`
else
  echo "WAS_HOME not valid:  '${WAS_HOME}'"
  exit 1
fi

JAVA_HOME="${WAS_HOME}"/java

MODULES="${COMMON_COMPONENTS_HOME}"/modules
CIE_MODULES=${CIE_MODULES:-${MODULES}}
CIE_L10N_MODULES=${CIE_L10N_MODULES:-${CIE_MODULES}}

CIE_TMPDIR="${TMPDIR:-/tmp}"/fmwconfig.$$

JDBC_DRIVER_CLASSPATH="${MODULES}/oracle.jdbc_11.1.1/ojdbc6dms.jar:${MODULES}/oracle.odl_11.1.1/ojdl.jar:${MODULES}/oracle.dms_11.1.1/dms.jar:${DB_DRIVER_CLASSPATH}"

CIE_CLASSPATH=${CIE_MODULES}/com.oracle.cie.config-was-patch_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.de_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.es_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.fr_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.it_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.ja_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.ko_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.pt.BR_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.zh.CN_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.zh.TW_7.2.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.config-was_7.2.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.config-was-schema_7.0.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.de_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.es_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.fr_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.it_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.ja_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.ko_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.pt.BR_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.zh.CN_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.zh.TW_7.2.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.config_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.de_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.es_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.fr_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.it_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.ja_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.ko_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.pt.BR_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.zh.CN_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.zh.TW_6.1.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.wizard_6.1.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.oui_1.3.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.xmldh_2.5.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.de_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.es_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.fr_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.it_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.ja_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.ko_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.pt.BR_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.zh.CN_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.zh.TW_6.4.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.comdev_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wlw-plaf.de_5.3.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wlw-plaf.es_5.3.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wlw-plaf.fr_5.3.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wlw-plaf.it_5.3.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wlw-plaf.ja_5.3.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wlw-plaf.ko_5.3.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wlw-plaf.pt.BR_5.3.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wlw-plaf.zh.CN_5.3.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wlw-plaf.zh.TW_5.3.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wlw-plaf_5.3.0.0.jar${CLASSPATHSEP}${MODULES}/com.oracle.cie.security_1.0.0.0/com.oracle.cie.encryption_1.0.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.bea.core.xml.xmlbeans_2.1.0.0_2-5-1.jar${CLASSPATHSEP}${CIE_MODULES}/javax.xml.stream_1.1.1.0.jar${CLASSPATHSEP}${JDBC_DRIVER_CLASSPATH}

CIE_LIBS="${COMMON_COMPONENTS_HOME}"/common/wsadmin

trap 'cleanup' HUP INT QUIT TERM EXIT

umask 077
mkdir "${CIE_TMPDIR}"
if [ ! $? ]
then
  echo "Unable to create tmp directory"
  trap - EXIT
  exit 1
fi
umask 027

if [ -r "${SCRIPTPATH}"/setWasConfigEnv.sh ]
then
  . "${SCRIPTPATH}"/setWasConfigEnv.sh
fi

if [ -n "${WASCONFIG_CLASSPATH}" ]
then
  CLASSPATH="${CIE_CLASSPATH}${CLASSPATHSEP}${WASCONFIG_CLASSPATH}"
else
  CLASSPATH="${CIE_CLASSPATH}"
fi
export CLASSPATH

"${JAVA_HOME}"/bin/java ${CONFIG_JVM_ARGS} -DMW_HOME="${MW_HOME}" -DWAS_HOME="${WAS_HOME}" -DCOMMON_COMPONENTS_HOME="${COMMON_COMPONENTS_HOME}" -Dcom.oracle.cie.libs="${CIE_LIBS}" -DCIE_TMPDIR="${CIE_TMPDIR}" com.oracle.cie.wizard.WizardController "$@"

