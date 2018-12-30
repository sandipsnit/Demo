#!/bin/sh
#
# setWlstEnvExtns.sh
#
# Copyright (c) 2008, 2013, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      setWlstEnvExtns.sh - Calls out to WLST environment-setting scripts
#
#    DESCRIPTION
#      Calls out to classpath-setting scripts that configure the
#	classpath for WLST commands.
#
#    NOTES
#      This script is called by wlst.sh to in turn call out to 
#	scripts that set up the classpath for the WLST commands
# 	that belong to various components and products.
#
CURRENT_COMMON_COMPONENTS_HOME="${COMMON_COMPONENTS_HOME}"
export CURRENT_COMMON_COMPONENTS_HOME

if [ "${COMMON_COMPONENTS_HOME}" = "" ] || [ ! -d "${COMMON_COMPONENTS_HOME}" ]; then
	COMMON_COMPONENTS_HOME="${ORACLE_HOME}"
	export COMMON_COMPONENTS_HOME
fi

if [ "${CURRENT_HOME}" = "${COMMON_COMPONENTS_HOME}" ] ; then
	# JRF WLST Environment setting
	if [ -f "${COMMON_COMPONENTS_HOME}"/common/bin/setWlstEnv.sh ] ; then
		. "${COMMON_COMPONENTS_HOME}"/common/bin/setWlstEnv.sh
	fi
fi

if [ "${CURRENT_HOME}" = "${ORACLE_HOME}" ] ; then
	# SOA WLST Environment Setting
	if [ -f "${ORACLE_HOME}"/common/bin/setSOAWlstEnv.sh ] ; then
		. "${ORACLE_HOME}"/common/bin/setSOAWlstEnv.sh
	fi

	# WebCenter WLST Environment Setting
	if [ -f "${ORACLE_HOME}"/common/bin/setWebCenterWlstEnv.sh ] ; then
		. "${ORACLE_HOME}"/common/bin/setWebCenterWlstEnv.sh
	fi

	# OWLCS WLST Environment Setting
	if [ -f "${ORACLE_HOME}"/common/bin/setOWLCSWlstEnv.sh ] ; then
		. "${ORACLE_HOME}"/common/bin/setOWLCSWlstEnv.sh
	fi

fi
COMMON_COMPONENTS_HOME="${CURRENT_COMMON_COMPONENTS_HOME}"
export COMMON_COMPONENTS_HOME
