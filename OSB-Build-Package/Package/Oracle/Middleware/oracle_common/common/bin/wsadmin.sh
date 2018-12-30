#!/bin/sh
#
# wsadmin.sh
#
# Copyright (c) 2009, 2011, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      wsadmin.sh - Wrapper script for wsadmin
#
#    DESCRIPTION
#      Set up FMW extensions for wsadmin

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

if [ -d "${WAS_HOME}" ]
then
  WAS_HOME=`cd "${WAS_HOME}"; pwd`
else
  echo "WAS_HOME not found:  '${WAS_HOME}'"
  exit 1
fi

if [ ! -f "${WAS_HOME}/lib/startup.jar" ]
then
  echo "WAS_HOME is not a valid WebSphere directory:  '${WAS_HOME}'"
  exit 1
fi

MODULES="${COMMON_COMPONENTS_HOME}"/modules
CIE_MODULES=${CIE_MODULES:-${MODULES}}
CIE_L10N_MODULES=${CIE_L10N_MODULES:-${CIE_MODULES}}

CIE_TMPDIR="${TMPDIR:-/tmp}"/fmwconfig.$$

if [ -n "${CIE_LOG}" ]
then
  LOG_PROP="oracle.cie.log=${CIE_LOG}"
fi
if [ -n "${CIE_LOG_PRIORITY}" ]
then
  LOG_PRIORITY_PROP="oracle.cie.log.priority=${CIE_LOG_PRIORITY}"
fi

CIE_CLASSPATH=${CIE_MODULES}/com.oracle.cie.config-was-patch_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.de_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.es_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.fr_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.it_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.ja_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.ko_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.pt.BR_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.zh.CN_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config-was.zh.TW_7.2.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.config-was_7.2.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.config-was-schema_7.0.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.de_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.es_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.fr_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.it_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.ja_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.ko_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.pt.BR_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.zh.CN_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.config.zh.TW_7.2.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.config_7.2.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.de_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.es_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.fr_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.it_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.ja_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.ko_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.pt.BR_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.zh.CN_6.1.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.wizard.zh.TW_6.1.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.wizard_6.1.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.oui_1.3.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.xmldh_2.5.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.de_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.es_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.fr_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.it_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.ja_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.ko_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.pt.BR_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.zh.CN_6.4.0.0.jar${CLASSPATHSEP}${CIE_L10N_MODULES}/com.oracle.cie.comdev.zh.TW_6.4.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.oracle.cie.comdev_6.4.0.0.jar${CLASSPATHSEP}${MODULES}/com.oracle.cie.security_1.0.0.0/com.oracle.cie.encryption_1.0.0.0.jar${CLASSPATHSEP}${CIE_MODULES}/com.bea.core.xml.xmlbeans_2.1.0.0_2-5-1.jar${CLASSPATHSEP}${CIE_MODULES}/javax.xml.stream_1.1.1.0.jar

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

if [ -r "${SCRIPTPATH}"/setWsadminEnv.sh ]
then
  . "${SCRIPTPATH}"/setWsadminEnv.sh
fi

if [ -n "${WSADMIN_CLASSPATH}" ]
then
  CIE_CLASSPATH="${CIE_CLASSPATH}${CLASSPATHSEP}${WSADMIN_CLASSPATH}"
fi

TMP_PROPFILE="${CIE_TMPDIR}"/omwconfig.properties
cat >"${TMP_PROPFILE}" <<EOF
# CIE Config Properties.
# wsadmin properties.
com.ibm.ws.scripting.defaultLang=jython
com.ibm.ws.scripting.connectionType=NONE
com.ibm.ws.scripting.classpath=${CIE_CLASSPATH}
wsadmin.script.libraries=${CIE_LIBS};${WSADMIN_SCRIPT_LIBRARIES}
# CIE properties.
com.oracle.cie.libs=${CIE_LIBS}
WAS_HOME=${WAS_HOME}
MW_HOME=${MW_HOME}
COMMON_COMPONENTS_HOME=${COMMON_COMPONENTS_HOME}
CIE_TMPDIR=${CIE_TMPDIR}
${LOG_PROP}
${LOG_PRIORITY_PROP}
EOF

"${WAS_HOME}"/bin/wsadmin.sh -profile ${CIE_LIBS}/OracleMWConfigLoader.py -p "${TMP_PROPFILE}" "$@"

