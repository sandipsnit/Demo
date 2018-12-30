#"""
# Copyright (c) 2010, 2012, Oracle and/or its affiliates. All rights reserved. 
#-------------------------------------------------------------------------------
#Caution: This file is part of the WLST implementation. Do not edit or move
#this file because this may cause WLST commands and scripts to fail. Do not
#try to reuse the logic in this file or keep copies of this file because this
#could cause your WLST scripts to fail when you upgrade to a different version
#of WLST. 
#-------------------------------------------------------------------------------
#MODIFIED (MM/DD/YY)
#
#trdsouza 05/17/12 - Created. Shell commands to get Jars Version(Manifest) from shiphome.
#-------------------------------------------------------------------------------
#"""

#!/bin/bash

./wlst.sh $MW_HOME/oracle_common/common/wlst/PrintJarsVersion.py "printJarsVersion"
