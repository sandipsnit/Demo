#!/usr/local/bin/perl
# 
# $Header: has/install/crsconfig/crsconfig_lib.pm /main/233 2009/11/03 22:07:00 samjo Exp $
#
# crsconfig_lib.pm
# 
# Copyright (c) 2008, 2009, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      crsconfig_lib.pm - Library module for root scripts
#
#    DESCRIPTION
#      crsconfig_lib.pm - Library module containing functions for Oracle
#                         Clusterware and SI-HAS configurations
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    samjo       11/03/09 - Disable CRF
#    ksviswan    10/28/09 - Patching Support
#    diguma      10/15/09 - 8770139: check_service grep
#    mimili      10/11/09 - enable evmd in SIHA to replace eonsd 
#                                -add dependencies for cluster mode
#    ahabbas     10/07/09 - only enable ACFS for those tests that use it
#    ksviswan    10/01/09 - CheckPoint Implementation for fresh  Clusterware install
#    jachang     09/24/09 - Omit setting permissions on voting files
#    ysharoni    09/15/09 - bug 8739811 - gpnp config manifest owner
#    sujkumar    09/22/09 - Add IPD/OS related changes
#    dpham       09/22/09 - XbranchMerge dpham_bug-8889417 from
#                           st_has_11.2.0.1.0
#    ysharoni    09/15/09 - bug 8739811 - gpnp config manifest owner  
#    dpham       09/15/09 - Change OCR file owner to root in an upgrade (8889417)
#    dpham       09/14/09 - XbranchMerge dpham_bug-8761196 from
#    dpham       09/14/09 - XbranchMerge dpham_bug-8484319 from
#                           st_has_11.2.0.1.0
#    dpham       09/02/09 - add add_ITDIR_to_dirs() function (bug 8484319)
#    ysharoni    09/01/09 - remove sticky bit from wallets (bug 8821492)
#    dpham       08/18/09 - Add double-quotes for NT
#    jleys       07/29/09 - XbranchMerge jleys_bug-8667932_11.2.0.1.0_pl from
#    jleys       07/23/09 - Fix for bug 8667932; check CSSD can run realtime
#    ksviswan    07/21/09 - add unlock for Oracle Restart Home
#    dpham       08/21/09 - XbranchMerge dpham_bug-8776078 from
#                           st_has_11.2.0.1.0
#    dpham       08/17/09 - ACFS driver should start as "NT AUTHORITY\\SYSTEM" on NT
#    dpham       08/02/09 - Fix bug 8761196
#    ksviswan    07/30/09 - XbranchMerge ksviswan_bug-8693624 from
#    dpham       07/29/09 - XbranchMerge dpham_bug-8727340 from
#                           st_has_11.2.0.1.0
#    dpham       07/28/09 - Fix split function to work for other languages
#    rwessman    07/27/09 - Bug 8705125
#    ksviswan    07/21/09 - add unlock for Oracle Restart Home
#    dpham       07/20/09 - XbranchMerge dpham_bug8655947 from
#    dpham       07/15/09 - XbranchMerge dpham_bug-8416640_2 from
#                           st_has_11.2.0.1.0
#    dpham       07/15/09 - XbranchMerge dpham_bug-8664938 from main
#    dpham       07/12/09 - fix bug 8416640
#    dpham       07/12/09 - Set owner of ohasd.bin and crsd.bin to root and set its
#                           permissions to '0741'
#    dpham       07/08/09 - Add isPathonASM
#			  - Fix getHostVIP() function (bug 8664269,8659066)
#    sunsridh    07/07/09 - bug 8658959 Let ora.diskmon get pulled up always
#    dpham       07/03/09 - 8656033
#    ksviswan    06/24/09 - Fix Bug 8627151
#    dpham       06/24/09 - Fix logic error in isLastNodeToStart() function
#    dpham       06/17/09 - Always call ASMCA during deconfigure_ASM
#			  - Fix get OCR key in get_OldVipInfoFromOCRDump()
#			  - Fix isCRSAlreadyConfigured
#    dpham       06/10/09 - Set perm '0600' on olr location for SIHA
#			  - Use single-quotes on diskgroup if it contains '$'
#			  - Pass nodes_to_start list for DHCP
#			  - Check proper return code in wait_for_stack_start()
#    dpham       06/05/09 - Allow asm diskgroup contains '$'
#    ysharoni    05/31/09 - bug 8557547 - no empty asm disco str
#    dpham       05/31/09 - Check for "10.1" in getUpgradeConfig
#			  - Add isNodeappsExists()  
#    dpham       05/29/09 - Call get_oifcfg_iflist() from new crshome if unable
#			    to get from old crshome 
#			  - Fix configNode & start_Nodeapps for DHCP (8556760)
#    jleys       05/27/09 - Clarify call to prep voting files
#    dpham       05/25/09 - Fix configNewNode for DHCP (bug 8541115)
#    jleys       05/19/09 - Prepare voting files in upgrade
#    dpham       05/20/09 - Add s_copyOCRLoc
#			  - Export PARAM_FILE_NAME for asmca
#			  - Export PARAM_FILE_NAME for asmca
#    dpham       05/12/09 - Add getUpgradeConfig, configNode, configFirstNode, 
#			    validateNetmask, backupOLR
#    hchau       05/12/09 - Start ctssd resource with env var CTSS_REBOOT=TRUE
#                           when starting the stack
#    dpham       05/11/09 - Add get_OldVipInfoFromOCRDump and export stop_resource
#    vmanivel    05/08/09 - Bug 8258489, removing language references
#    garnaiz     05/05/09 - add new shutdown dependency to cssd
#    dpham       05/05/09 - Convert hostname to lowercase (8489146)
#    dpham       05/04/09 - Fix automerge issue on $$upgrade_ref
#    ksviswan    05/04/09 - Implement downgrade
#    garnaiz     05/01/09 - add subroutine to stop diskmon and capture output
#                           and use it in perform_initial_config
#    samjo       04/30/09 - Bug 8447184. Tolerate ora.asm in INTERMEDIATE state
#                           for ora.crsd
#    dpham       04/29/09 - Add double-quotes on -attr for windows (bug 8339645)
#                         - Separate add/start resources (bug 8462980)
#    ysharoni    05/01/09 - removing incorrect , in optional prf_cif gpnptool
#                           par
#    ysharoni    04/29/09 - bug8466476 fix - no implicit same-mask interconn
#    ysharoni    04/28/09 - replacing get_clusterguid to use std crs ver
#    dpham       04/27/09 - Export s_houseCleaning
#    ksviswan    04/25/09 - Add Patching support
#    hchau       04/22/09 - Bug 8265795. Make crsd, evmd, and asm depends on
#                           ctss
#    dpham       04/22/09 - Add get_OldVipInfoFromOCRDump & isLastNodeToUpgrade
#    dpham       04/21/09 - XbranchMerge dpham_bug-8249129 from
#                           st_has_11.2beta2
#    sbasu       04/20/09 - #8447374:disable OC4J resource
#    dpham       04/20/09 - Remove single quote from LANGUAGE_ID
#    garnaiz     04/16/09 - bug 8438116: explicitly stop diskmon when going
#                           from exclusive to clustered
#    dpham       04/15/09 - Call s_createLocalOnlyOCR for OS-specific
#    ksviswan    04/15/09 - XbranchMerge ksviswan_rootmisc_fixes from
#                           st_has_11.2beta2
#    ksviswan    04/13/09 - Exit if active version change fails during upgrade.
#    ksviswan    04/09/09 - XbranchMerge ksviswan_bug-8408487 from
#                           st_has_11.2beta2
#    garnaiz     04/09/09 - XbranchMerge garnaiz_bug-8413328 from
#                           st_has_11.2beta2
#    agusev      04/09/09 - XbranchMerge agusev_bug-8323709 from main
#    dpham       04/08/09 - XbranchMerge dpham_bug-8412144 from main
#    agusev      04/07/09 - Fix for 8323709
#    ksviswan    04/07/09 - Fix bug 8408487. check if VOTING_DISKS defined prior to use
#    dpham       04/07/09 - Add isASMExists to check if ASM exists during upgrade
#			  - Move checkServiceDown function from crsdelete.pm module
#    dpham       04/02/09 - get OldVipInfo for 10.1
#    samjo       04/01/09 - Bug 7394469. Update ora.crsd dep
#    jleys       04/01/09 - Create lastgasp directory
#    dpham       03/31/09 - ACFS is not supported in SIHA in 11gR2
#    dpham       03/30/09 - Obsolete GetLocalNode. Use $CFG->HOST instead
#    spavan      03/27/09 - install cvuqdisk rpm as part of root
#    dpham       03/27/09 - Ensure ASM_DISKSTRING is defined
#    ksviswan    03/26/09 - get ONS port info for upgrade - Bug 8373077
#    ksviswan    03/24/09 - Add special start nodepps for upgrade 
#    dpham       03/20/09 - Remove OCFS_CONFIG var. It's used only for NT
#    dpham       03/17/09 - Add createLocalOnlyOCR (bug 8353813)
#    seviswan    03/18/09 - Add -oratabLocation switch to configure_ASM
#    dpham       03/17/09 - Remove 'ora.daemon.type' from log directory
#                         - Fix invalid return code check from CSS_start_exclusive
#    agusev      03/12/09 - Fix for 7605771 (cssd perms in SIHA)
#    samjo       03/04/09 - Bug 8218839. Add pullup dep bet CRSD and ASM
#    agraves     03/12/09 - Move usm_root to acfsroot.
#    dpham       03/11/09 - Remove srvctl trace in get_OldVipInfo
#    ksviswan    03/11/09 - Fix configNodeapps for upgrade - Bug 8329144
#    dpham       03/10/09 - Export OCFS_CONFIG variable
#                         - olrlocation permission should be "0600".
#                         - Set OCRCONFIG & OLRCONFIG to null in 
#                           add_olr_ocr_vdisk_locs on Windows
#    ksviswan    03/10/09 - Fix migrate local ocr logic - Bug 8322300
#    dpham       03/09/09 - Set traces in get_oldconfig_info
#    agraves     03/06/09 - Add option for ASMADMIN group name to clscfg
#                           install and upgrade.
#    ysharoni    03/06/09 - temp fix for bug 8258942
#    dpham       03/06/09 - Add ora.registry.acfs resource for non-ASM OCR/VD
#    dpham       03/05/09 - Remove "clscfg -local -l $LANGUAGE_ID" for SIHA.
#     			  - Change ASM_DISCOVER_STRING to ASM_DISKSTRING in deconfigure_ASM
#    jleys       02/06/09 - Remove expansion of VF discovery string
#    ysharoni    03/02/09 - Add get_crs_version,get_ocr_privatenames_info
#    dpham       03/02/09 - Set ora.registry.acfs owner to root
#     			  - Start ora.asm resource during deconfigure ASM
#    jleys       02/06/09 - Remove expansion of VF discovery string
#    ksviswan    03/01/09 - Fix Old VIP info logic for multinode - Bug 8287142
#    sravindh    03/01/09 - Fix logic in validating interface list
#    sunsridh    02/26/09 - Disable ora.diskmon on Win32
#    dpham       02/26/09 - usm_root and ora.drivers.acfs get installed on all nodes
#     			          - ora.registry.acfs resource gets added and started 
#                           on the last node
#    dpham       02/24/09 - Add isInterfaceValid
#    dpham       02/23/09 - Add $OPROCDDIR
#    ksviswan    02/23/09 - Restore ocr.loc and local.ocr - Bug 8280425
#    dpham       02/22/09 - Add isCRSAlreadyConfigured
#    diguma      02/21/09 - Support more post clscfg commands during config
#    ysharoni    02/23/09 - adding prdr wallet
#    dpham       02/20/09 - Set SRVM_TRACE after getHostVIP
#             			  - Fix getHostVIP to check for 'VIP exist' 
#    samjo       02/16/09 - Change 'crsctl changeav' to 'crsctl set crs
#                           activeversion'
#    dpham       02/16/09 - Set ownership of OLRCONFIG to $SUPERUSER
#    dpham       02/14/09 - Rollback ASM_DISKS & ASM_DISCOVER_STRING
#    jleys       02/08/09 - Do not show exclusive failure in msgs
#    sravindh    02/16/09 - Review comments
#    dpham       02/11/09 - Call usm_root on every node
#    dpham       02/11/09 - Validate usm_root to ensure it exists
#    sravindh    02/10/09 - Fix bug 7714358
#    dpham       02/09/09 - Add deconfigure_ASM
#    priagraw    02/06/09 - reorder startup of gipcd
#    dpham       02/05/09 - Fix ORA_CRS_HOME error 
#    dpham       01/29/09 - ocrconfig_loc is not populate properly in 
#                           local_only_config_exists
#    dpham       02/05/09 - Revert setting 'root' ownership on crshome and OCR
#    hchau       02/04/09 - Add RC_START RC_KILL to global vars
#    dpham       02/04/09 - Add isRAC_appropriate to check for rac_on/rac_off
#    ysharoni    02/03/09 - Change cluutil output handling.
#    dpham       01/29/09 - ocrconfig_loc is not populate properly in i
#                           local_only_config_exists
#    dpham       01/29/09 - Export s_set_ownergroup & s_set_perms
#    dpham       01/27/09 - Add unlockCRSHOME
#    dpham       01/22/09 - Skip validate VOTING_DISKS for SIHA
#    dpham       01/21/09 - Add "start ora.registry.acfs"
#                         - Set owner group/permission on cfgtoollogs/crsconfig
#                         - Set owner group/permission on srvmcfg*.log
#    diguma      01/16/09 - move cssdmonitor dependencies to type file
#    ysharoni    01/16/09 - Add nodelst to push gpnp conf in upgrade
#    rsreekum    01/16/09 - export configNewNode
#    jleys       01/08/09 - Use null string for ASM discover string
#    diguma      01/08/09 - changing the auto_start for css in cluster mode
#    sbasu       12/31/08 - fix srvctl tracing for oc4j srvctl commands
#    dpham       01/13/08 - Fix "FAILED TO START NODEAPPS" (7563279
#                         - "add nodeapps" should be called only on 1st node, 
#                           "add vip" should be called on other nodes (7449794
#    dpham       01/13/08 - Change file test to "-e $ocrfile" in validate_SICSS
#    dpham       01/09/08 - Set owner/group of OCR path to root/dba
#    ysharoni    12/25/08 - add netinfo to profile for upgrade
#    dpham       01/07/08 - Fix "FAILED TO FIND EARLIER VERSION DBHOME" 
#    dpham       12/29/08 - Fix CRS_NODEVIP double quotes issue
#    ysharoni    12/25/08 - add netinfo to profile for upgrade
#    ksviswan    12/23/08 - Fix Bug 7561694
#    agraves     12/22/08 - Change usmfs to registry.acfs
#                           Change usm to drivers.acfs.
#    dpham       12/22/08 - Remove double quotes from $nodevip 
#                           when add nodeapps
#    jleys       12/19/08 - Add INIT to list of global variables
#    jleys       12/18/08 - Fix typo in get_oldconfig_info
#    garnaiz     12/16/08 - set diskmon user env variable
#    dpham       01/07/08 - Fix "FAILED TO FIND EARLIER VERSION DBHOME" 
#    jleys       12/10/08 - Remove commented out code and some trace statements
#    jleys       12/10/08 - Use system_cmd for olr_initial_config
#    jleys       12/01/08 - Fix ASM_DISKS quotes problem
#    jleys       11/29/08 - Set delete flag in $CFG
#    jleys       11/26/08 - VAlidate Oracle Home as part of config init
#    jleys       11/25/08 - Fix SIHA validation
#    jleys       11/14/08 - Packagize perl scripts
#    dpham       12/11/08 - Fix ocfs, permissions, start services issues
#    rwessman    12/02/08 - Bug 7587535.
#    rwessman    12/02/08 - Bug 7609364.
#    dpham       12/02/08 - Remove ORA_DBA_GROUP validation
#    sravindh    11/25/08 - Fix from siyarlag for bug 7597160
#    sravindh    11/25/08 - Bugfix 7597160
#    dpham       11/21/08 - Add single quote on ASM_DISCOVERY_STRING
#    dpham       11/20/08 - Return FALSE if unable to exit exclusive mode
#    ksviswan    11/20/08 - fix ExtractVotedisk
#    dpham       11/13/08 - Add createConfigEnvFile for Time Zone  
#    jleys       11/12/08 - Use error instead of trace to write to both stdout
#                           and log
#    dpham       11/10/08 - Create ASM diskgroup as install user
#                         - Start diskgroup on all nodes
#    dpham       11/07/08 - Change usmca to asmca.
#    yizhang     11/07/08 - Fix bug 7539974
#    sbasu       11/05/08 - Add configOC4JContainer() to config/start OC4J containter
#    dpham       11/05/08 - Check for ASM disk group in validate_SICSS
#    jleys       10/31/08 - Remove setting of ORA_CRS_HOME in
#                           olr_initial_config
#    dpham       10/30/08 - Create CRS resource for OCR/Voting disk group.
#    jleys       10/30/08 - Add diagnostic output
#    jleys       10/28/08 - Use system_cmd for start_resource
#    jleys       10/26/08 - Cleanup compile warnings
#    diguma      10/17/08 - 7492916: wrong attributes for SIHA
#    dphami      10/16/08 - On windows, OCR and voting disks should be files not dirs.
#    yizhang     10/27/08 - Fix bug 7509687
#    rwessman    10/27/08 - Bug 7512890.
#    dpham       10/27/08 - configure_ASM should returns $success not $sucess
#                         - remove "!start_resource("ora.asm", "-init")"
#    dpham       10/22/08 - Add call to s_start_ocfs_driver
#    lmortime    10/20/08 - Bug 7279735 - Making "cluster" primary and
#                           "clusterware" an alias
#    ysharoni    10/20/08 - fail in case if wallet creation failed.
#    dpham       10/20/08 - Remove quotes from -diskGroupName and -redundancy of usmca.
#    diguma      10/17/08 - 7492916: wrong attributes for SIHA
#    dpham       10/16/08 - R:\ocr or /ocr should be file not dir.
#    dpham       10/14/08 - Add ExtractVotedisk function
#    rwessman    10/15/08 - Bug 7482219.
#    sunsridh    10/03/08 - Adding diskmon agent
#    jleys       08/19/08 - Convert all use of s_run_as_user to run_as_user
#    jleys       09/24/08 - Do not complete initial config if VF add not
#                           successful
#    dpham       09/30/08 - Add CRS resources for OCR/Voting disk group (bug 6665952).
#                         - Fix 'Resource ora.asm is already running' issue (bug 7423931).
#    jleys       09/29/08 - Remove the CSSD monitor from the SIHA install
#    ppallapo    09/26/08 - Add ocrid, cluster_guid to gpnp profile
#    dpham       09/25/08 - Add new code for DHCP
#    rwessman    09/25/08 - Bug 7428250.
#    dpham       09/22/08 - Set OLR file permission to ORACLE_OWNER/ORA_DBA_GROUP (bug 7411347). 
#    diguma      09/20/08 - 
#    akhaladk    09/17/08 - 
#    rsreekum    09/16/08 - Fix issue with check_service 
#    rwessman    09/16/08 - Bug 7392881.
#    ppallapo    09/15/08 - Change ORACLE_DBA_GROUP to ORA_DB_GROUP
#    dpham       09/09/08 - Always delete olr file if it exists. 
#    akhaladk    09/04/08 - Fix acls
#    yizhang     09/01/08 - 
#    lmortime    08/29/08 - Bug 7279735 - Making "cluster" primary and
#                           "clusterware" an alias
#    ysharoni    08/26/08 - remove Public attr in profile net defn
#    dpham       08/26/08 - add is_dev_env check before calling setParentDir2Root 
#    rxkumar     08/21/08 - fix bug7309465
#    hkanchar    08/14/08 - 
#    dpham       08/13/08 - Set owner/group of ORA_CRS_HOME and its parent dir to root/dba
#    khsingh     08/07/08 - ,
#    dpham       08/07/08 - Add trim function.
#                         - Check for valid ASM_DISCOVERY_STRING 
#    khsingh     08/06/08 - add crs_init_scripts
#    khsingh     08/04/08 - add File::Find
#    hkanchar    07/30/08 - Updage clscfg usage to include language id for OLR
#    dpham       07/28/08 - '-configureLocalASM' for usmca should be used only on the 1st node.
#    dpham       07/23/08 - Fix "NO_VAL" of OCR/VF when ASM is used. 
#    rwessman    07/22/08 - Incorporated review comments from jcreight.
#    ysharoni    07/17/08 - networks list became comma-delimited
#    dpham       07/16/08 - 
#    agusev      07/11/08 - Changed the way crsd being running is determined
#                           for exclusive start
#    jleys       07/11/08 - Put fix fo bug 7159411 back in
#    dpham       07/10/08 - Fix listener on a new node (bug 7169845
#                         - Fix netmask/if for new node
#    rwessman    07/01/08 - Added support for GNS.
#    dpham       06/30/08 - add usmfs resource
#    ysharoni    06/30/08 - fix gpnp global/local home recognition pbm
#    hqian       06/20/08 - Files: change owner before changing permissions
#    jleys       06/13/08 - Add hosts to clscfg for Sameer
#    jleys       04/21/08 - Correct merge errors
#    jleys       04/19/08 - Merge updates
#    jleys       04/15/08 - Add new sub for olr in SIHA
#    jleys       04/06/08 - Add diagnostics
#    ysharoni    03/05/08 - fixes for undefined gpnp packg vars
#    jleys       03/01/08 - Add initial config function
#    dpham       06/20/08 - create ocr and olr parent directory
#    gdbhat      06/20/08 - Bug 6054661
#    dpham       06/17/08 - fix date issue (bug 7010382)
#    dpham       06/16/08 - add new node logic
#    jgrout      05/19/08 - realign crsctl commands, fix check_service
#    srisanka    05/12/08 - validate SIHA params
#    ysharoni    05/06/08 - Network info format change
#    srisanka    04/30/08 - Bug 7010382: fix month representation
#    dpham       04/28/08 - Add new subroutines for root deconfig  
#    jleys       04/25/08 - Review comments
#    ysharoni    04/22/08 - internal subroutines converted to normal
#    jleys       04/21/08 - Add comments
#    jleys       04/21/08 - Add function to determine if this is the last node
#    ysharoni    03/31/08 - bug 6895319
#    srisanka    03/19/08 - use trace for all verbose messages
#    ysharoni    03/05/08 - fixes for underfined gpnp packg vars
#    srisanka    02/11/08 - new APIs and fixes for output redirection
#    jgrout      02/12/08 - Fix bug 6607370
#    skakarla    02/07/08 - quoting discovery 
#    srisanka    01/09/08 - separate generic and OSD code
#    ysharoni    12/27/07 - root wallet created by orapki, not mkwallet
#    jgrout      12/20/07 - Fix copy_to_initdir, copy_to_rcdirs
#                            for bug 6678133
#    ysharoni    12/09/07 - add gpnp code
#    srisanka    08/01/07 - Creation
# 

package crsconfig_lib;

use strict;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

$VERSION = '1';

use English;
use Exporter;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Spec::Functions;
use Sys::Hostname;
use POSIX qw(tmpnam);
use Carp;
use Socket;

use constant ERROR                     => "-1";
use constant FAILED                    =>  "0";
use constant SUCCESS                   =>  "1";
use constant TRUE                      =>  "1";
use constant FALSE                     =>  "0";
use constant GPNP_SETUP_BAD            => "-1"; # invalid/error
use constant GPNP_SETUP_NONE           =>  '0';  # none
use constant GPNP_SETUP_LOCAL          =>  '1';  # good local setup
use constant GPNP_SETUP_GOTCLUSTERWIDE =>  '2';  # good clusterwide; that just made local
use constant GPNP_SETUP_CLUSTERWIDE    =>  '3';  # good local same as clusterwide
use constant CKPTSUC                   =>  'SUCCESS';
use constant CKPTFAIL                  =>  'FAIL';
use constant CKPTSTART                 =>  'START';
use constant CMDSUC                    =>  '0';
use constant CMDFAIL                   =>  '1';

# How much of the stack do we want to start?
# YYY: If IPD/OS should not be dependent on anybody else and first one to start
use constant START_STACK_NONE          => 0;
use constant START_STACK_CRF           => 1; # Start IPD/OS
use constant START_STACK_MDNSD         => 2; # Start MDNSD
use constant START_STACK_GIPCD         => 3; # Start GIPCD
use constant START_STACK_GPNPD         => 4; # Start GPNPD
use constant START_STACK_CTSSD         => 5; # Start CTSSD
use constant START_STACK_CSSD          => 6; # Start CSSD
use constant START_STACK_ASM           => 7; # Start ASM
# Start the rest, EVMD & CRSD cannot be started independtly
use constant START_STACK_ALL           => 8;

# --- gpnp string constants:
use constant GPNP_DIRNAME              => 'gpnp';

use constant GPNP_W_DIRNAME            => 'wallets';
use constant GPNP_W_ROOT_DIRNAME       => 'root';
use constant GPNP_W_PRDR_DIRNAME       => 'prdr';
use constant GPNP_W_PEER_DIRNAME       => 'peer';
use constant GPNP_W_PA_DIRNAME         => 'pa';

use constant GPNP_P_DIRNAME            => 'profiles';
use constant GPNP_P_PEER_DIRNAME       => 'peer';

use constant GPNP_PROFILE_NAME         => 'profile.xml';
use constant GPNP_PROFSAV_NAME         => 'profile_orig.xml';

use constant GPNP_WRL_FILE_PFX         => 'file:';
use constant GPNP_WALLET_NAME          => 'ewallet.p12';
use constant GPNP_SSOWAL_NAME          => 'cwallet.sso';

use constant GPNP_CERT_NAME            => 'cert.txt';
use constant GPNP_CERTRQ_NAME          => 'certreq.txt';
use constant GPNP_RTCERT_NAME          => 'b64certificate.txt';
use constant GPNP_PDUMMY               => 'gpnp_wallet1';

use constant GPNP_W_ROOT_DN            => '"CN=GPnP_root"';
use constant GPNP_W_PA_DN              => '"CN=GPnP_pa"';
use constant GPNP_W_PEER_DN            => '"CN=GPnP_peer"';
use constant GPNP_W_KEYSZ              => '1024';
use constant GPNP_W_EXPDT              => '"01/01/2099"';
use constant GPNP_W_CVALID             => '9999';

our @exp_vars;
our $CFG;

# Becase oracss.pm uses the constants defined here, export in a BEGIN
# block so that they will not cause a compilation failure
BEGIN {
  @ISA = qw(Exporter);

  my @exp_const = qw(TRUE FALSE ERROR FAILED SUCCESS CKPTSUC CKPTFAIL CKPTSTART
                     GPNP_SETUP_BAD GPNP_SETUP_NONE GPNP_SETUP_LOCAL
                     GPNP_SETUP_GOTCLUSTERWIDE GPNP_SETUP_CLUSTERWIDE

                     START_STACK_NONE START_STACK_MDNSD
                     START_STACK_GIPCD START_STACK_GPNPD
                     START_STACK_CTSSD START_STACK_CSSD
                     START_STACK_ALL START_STACK_ASM
                     START_STACK_CRF
                    );

  # temporarely export $g_force, $g_delete, $g_lastnode, $g_downgrade, and $g_version
  # to OSD modules until they are packaged
  our @exp_vars = qw ($ACFS_supported
		      $CRSCTL
                      $CRS_NODEVIPS
                      $CRS_STORAGE_OPTION
                      $DEBUG
                      $FAILED
                      $g_force
                      $g_delete
                      $g_lastnode
                      $g_downgrade
                      $g_version
                      $GNS_ADDR_LIST
                      $GNS_CONF
                      $GNS_DOMAIN_LIST
                      $HAS_GROUP
                      $HAS_USER
                      $HOST
                      $ID
                      $INIT
                      $IT
                      $LANGUAGE_ID
                      $NETWORKS
                      $NODE_NAME_LIST
                      $OCRCONFIG
                      $OCRCONFIGDIR
                      $OCRLOC
                      $OCR_LOCATIONS
                      $OLRCONFIG
                      $OLRCONFIGDIR
                      $OLRLOC
                      $OLR_LOCATION
		      $OPROCDDIR
                      $ORACLE_HOME
                      $ORACLE_OWNER
                      $ORA_CRS_HOME
                      $ORA_DBA_GROUP
                      $RCALLDIR
                      $RCKDIR
                      $RCSDIR
                      $RC_START
                      $RC_KILL
                      $SCAN_NAME
                      $SCAN_PORT
                      $SCRBASE
                      $SRVCONFIG
                      $SRVCTL
                      $SUCCESS
                      $SUPERUSER
                      $UPGRADE
                      $DOWNGRADE
                      $oldcrshome
                      $oldcrsver
                      $VOTING_DISKS
                     );

  my @exp_osd  = qw(s_redirect_souterr      s_osd_setup s_init_scr
                    s_restore_souterr       s_get_config_key
                    s_check_SuperUser       s_get_platform_family
                    s_ResetOCR              s_CleanTempFiles 
                    s_reset_crshome         s_ResetVotedisks
                    s_set_ownergroup        s_set_perms
		    s_get_olr_file          s_removeCvuRpm
		    s_houseCleaning         s_ResetOLR
		    s_is92ConfigExists	    s_removeGPnPprofile
		    s_copyOCRLoc            s_RemoveInitResources
                    s_crf_check_bdbloc      s_crf_remove_itab
                    );

  my @exp_func = qw(check_CRSConfig validate_olrconfig validateOCR
                    is_dev_env
                    validate_ocrconfig olr_initial_config
                    copy_file check_SuperUser configLastNode
                    initial_cluster_validation
                    upgrade_OCR
                    ValidateOwnerGroup ValidateCommand
                    start_resource push_clusterwide_gpnp_setup
                    ExtractVotedisks
                    get_ocrdisk get_ocrmirrordisk get_ocrloc3disk
                    get_ocrloc4disk get_ocrloc5disk get_ocrlocaldisk
                    initialize_local_gpnp configure_hasd
                    create_dir create_dirs crs_exec_path
                    perform_initial_config perform_upgrade_config
                    instlststr_to_gpnptoolargs
                    oifcfgiflst_to_instlststr
                    register_service start_service check_service
                    tolower_host export_vars
                    setup_param_vars instantiate_scripts
                    copy_wrapper_scripts set_file_perms
                    trace error backtrace dietrap
                    get_oldconfig_info get_OldVipInfo get_OldVipInfoFromOCRDump
                    stop_OldCrsStack
                    run_env_setup_modules first_node_tasks
                    wait_for_stack_start isAddNode
                    isLastNodeToStart isLastNodeToUpgrade
                    local_only_config_exists migrate_dbhome_to_SIHA
                    local_only_stack_active stop_local_only_stack
                    start_clusterware run_crs_cmd system_cmd
                    system_cmd_capture
                    configNewNode
                    configureAllRemoteNodes
                    check_OldCrsStack
                    unlockCRSHome
                    unlockHAHome
                    isRAC_appropriate deconfigure_ASM isACFSSupported
                    start_acfs_registry isCRSAlreadyConfigured isInterfaceValid
                    get_crs_version createLocalOnlyOCR
                    configureCvuRpm checkServiceDown update_ons_config
		    getUpgradeConfig configNode backupOLR
		    getCurrentNodenameList isNodeappsExists quoteDiskGroup
                    isPathonASM stop_resource getCkptStatus writeCkpt isCkptexist
                    perform_start_cluster perform_initialize_local_gpnp perform_register_service
                    perform_start_service perform_init_config perform_olr_initial_config
                    perform_configure_hasd perform_configNode remove_checkpoints RemoveScan
                    RemoveNodeApps crf_config_generate crf_delete_bdb isCRFSupported
                    crf_do_delete run_as_user run_as_user2
                   );

  my @exp_arrays = qw(@crs_init_resources @ns_files @ns_files);

  @EXPORT  = qw($CFG);
  push @EXPORT, @exp_const, @exp_func, @exp_osd, @exp_vars, @exp_arrays;
}

use oracss;

# FIXME: These should be moved to crsdelete.pm, which is the place
# they are referenced
our @crs_init_resources = ("ora.evmd","ora.crsd","ora.cssd",
                           "ora.cssdmonitor","ora.gpnpd","ora.gipcd","ora.mdnsd");
our @ns_files = ("CSS","CRS","EVM","PROC","css","crs","evm","proc");

# This is used by an OSD subroutine, but that subroutine is used
# only by crsdelete.pm
our @crs_init_scripts = ("init.evmd","init.crsd","init.cssd",
                         "init.crs","init.ohasd");
our @crs_nodevip_list_old;
our $srvctl_trc_dir;
our $srvctl_trc_suff = 0;

my %stack_start_levels =
  (START_STACK_CRF      => 'Oracle clusterware daemons up to IPD/OS',
   START_STACK_MDNSD    => 'Oracle clusterware daemons up to MDNSD',
   START_STACK_GIPCD    => 'Oracle clusterware daemons up to GIPCD',
   START_STACK_GPNPD    => 'Oracle clusterware daemons up to GPNPD',
   START_STACK_CTSSD    => 'Oracle clusterware daemons up to CTSSD',
   START_STACK_CSSD     => 'Oracle clusterware daemons up to CSSD',
   START_STACK_ASM      => 'Oracle clusterware daemons up to ASM',
   START_STACK_ALL      => 'the Oracle clusterware stack'
   );

# The exported varables are required until the osd layer can adopt
# a package approach

our ($ACFS_supported,
     $CRSCTL,
     $CRS_NODEVIPS,
     $CRS_STORAGE_OPTION,
     $DEBUG,
     $GNS_ADDR_LIST,
     $GNS_CONF,
     $GNS_DOMAIN_LIST,
     $GPNP_ORIGIN_FILE,
     $HAS_GROUP,
     $HAS_USER,
     $HOST,
     $HOSTNAME,
     $ID,
     $INIT,
     $IT,
     $LANGUAGE_ID,
     $NETWORKS,
     $NODE_NAME_LIST,
     $OCRCONFIG,
     $OCRCONFIGDIR,
     $OCRLOC,
     $OCR_LOCATIONS,
     $OLRCONFIG,
     $OLRCONFIGDIR,
     $OLRLOC,
     $OLR_LOCATION,
     $OPROCDDIR,
     $ORACLE_HOME,
     $ORACLE_OWNER,
     $ORA_CRS_HOME,
     $ORA_DBA_GROUP,
     $RCALLDIR,
     $RCKDIR,
     $RCSDIR,
     $RC_START,
     $RC_KILL,
     $SCAN_NAME,
     $SCAN_PORT,
     $SCRBASE,
     $SRVCONFIG,
     $SRVCTL,
     $SUPERUSER,
     $UPGRADE,
     $DOWNGRADE,
     $oldcrshome,
     $oldcrsver,
     $VOTING_DISKS
    );

my %elements = ( 'SUPERUSER'           => 'SCALAR',
                 'IS_SIHA'             => 'SCALAR',
                 'UPGRADE'             => 'SCALAR',                 
                 'paramfile'           => 'SCALAR',
                 'osdfile'             => 'SCALAR',
                 'addfile'             => 'SCALAR',
                 'crscfg_trace_file'   => 'SCALAR',
                 'crscfg_trace'        => 'SCALAR',
                 'unlock_crshome'      => 'SCALAR',
                 'hahome'              => 'SCALAR',
                 'oldcrshome'          => 'SCALAR',
                 'oldcrsver'           => 'SCALAR',
                 'CLSCFG_EXTRA_PARMS'  => 'ARRAY',
                 'oldconfig'           => 'HASH',
                 'params'              => 'HASH',
                 'hosts'               => 'ARRAY',
                 'srvctl_trc_suff'     => 'COUNTER',
                 'DOWNGRADE'           => 'SCALAR'
               );

our $TRUE = TRUE;
our $FALSE = FALSE;
our $ERROR = FAILED;
our $SUCCESS = SUCCESS;
our $FAILED = FAILED;

our $wrapdir_crs; # this var will be used across multiple functions

# OSD API definitions
use s_crsconfig_lib;

# Currently the OSDs are not packaged, so no version will show up
# Once they are packaged, the version can be queried to allow osds
# to be updated on different platforms in separate txns and behavior
# adjusted according to capabilities of the version
our $OSD_VERSION = $s_crsconfig_lib::VERSION;

sub export_vars {
  for my $var (@exp_vars) {
    $var =~ s/^\$//;

    # CRSCTL is for OSDs & delete functions
    if ($var eq "CRSCTL") {
      $CRSCTL = crs_exec_path('crsctl');
    }
    elsif ($var eq "SRVCTL") {
      $SRVCTL = crs_exec_path('srvctl');
    }
    elsif ($CFG->defined_param($var)) {
      my $val = $CFG->params($var);
      $val =~ s!\\!\\\\!g; # for Windows
      $val =~ s!\"!\\\"!g; # for Windows
      eval("\$$var = \"$val\"");
    }
    elsif ($CFG->config_value($var)) {
      my $val = $CFG->config_value($var);
      $val =~ s!\\!\\\\!g; # for Windows
      $val =~ s!\"!\\\"!g; # for Windows
      eval("\$$var = \"$val\"");
    }
  }
}

sub run_crs_cmd {
  my $exec = shift;
  my @cmd = (crs_exec_path($exec), @_);

  return system_cmd(@cmd);
}

sub crs_exec_path {
  my ($cfg, $name);
  $cfg = $name = shift;
  if (@_ > 0) { $name = shift; } # called as a method
  else { $cfg = $CFG; }
  return catfile($cfg->ORA_CRS_HOME, 'bin', $name);
}

# If an element is defined as a counter, return incremented value
# Basically, this is the equivalent of ++counter
sub increment_counter {
  my $cfg  = shift;
  my $name = shift;
  my $incr = 1;
  my $ret;
  if (@_) { 
    $incr = shift;
    if (@_) { croak "Too many args to increment_counter $name"; }
  }
  else {
    $ret = $cfg->{$name} + $incr;
    $cfg->{$name} = $ret;
  }

  return $ret;
}

sub start_clusterware {
  my $level = $_[0];
  my $status = SUCCESS;

  trace ("Starting", $stack_start_levels{$level});
  if (($level < START_STACK_MDNSD ||
            start_resource("ora.mdnsd", "-init"))  &&
      ($level < START_STACK_GIPCD ||
       start_resource("ora.gipcd", "-init"))  &&
      ($level < START_STACK_GPNPD ||
       start_resource("ora.gpnpd", "-init"))  &&
      ($level < START_STACK_CRF ||
            ! isCRFSupported()   ||
            start_resource("ora.crf", "-init"))  &&
      ($level < START_STACK_CSSD || CSS_start_clustered()) &&
      ($level < START_STACK_CTSSD ||
       start_resource("ora.ctssd", "-init", 
                      "-env", "USR_ORA_ENV=CTSS_REBOOT=TRUE"))  &&
      ($level < START_STACK_ASM ||
       !$CFG->ASM_STORAGE_USED  || # if ASM used, start it
       start_resource("ora.asm", "-init"))  &&
      ($level < START_STACK_ALL ||
       (start_resource("ora.crsd", "-init")   &&
        start_resource("ora.evmd", "-init")))) {
    trace ("Successfully started requested Oracle stack daemons");
  } else {
    error ("Failed to start Oracle Clusterware stack");
    $status = FAILED;
  }

  return $status;
}

sub perform_start_cluster
{
  my $ckptstrtstack;
  my $ckpt = "ROOTCRS_STRTSTACK";
  if (isCkptexist($ckpt))
  {
    $ckptstrtstack = getCkptStatus($ckpt);
    trace("$ckpt state is $ckptstrtstack");
    if ($ckptstrtstack eq CKPTFAIL) {
       clean_start_cluster();
       start_cluster();
    } elsif ($ckptstrtstack eq CKPTSTART) {
       start_cluster();
    } elsif ($ckptstrtstack eq CKPTSUC) {
       trace("Cluster stack already started");
       return $SUCCESS;
    }
  } else {
      start_cluster();
  }
}

sub start_cluster
{
    my $ckpt = "ROOTCRS_STRTSTACK";
    writeCkpt($ckpt, CKPTSTART);
    # Start gpnpd
    if ( ! start_clusterware(START_STACK_GPNPD) )
    {
      error ("Failed to start GPnP");
      error ("Failed to start Oracle Clusterware stack");
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }

    # Upgrade the CSS voting disks.
    if ( ($UPGRADE) && (!CSS_upgrade($CFG)) )
    {
      error ("Failed to upgrade the CSS voting disks ");
      error ("Failed to start Oracle Clusterware stack");
      exit 1;
    }

    # Start CSS in clustered mode
    if ( ! CSS_start_clustered() )
    {
      error ("Failed to start CSS in clustered mode");
      error ("Failed to start Oracle Clusterware stack");
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }

    # Start CTSS with reboot option to signal step sync
    # Note: Before migrating stack startup to 'crsctl start crs',
    #       'CTSS_REBOOT=TRUE' is a workaround to signal step sync.
    if ( ! start_resource("ora.ctssd", "-init",
                          "-env", "USR_ORA_ENV=CTSS_REBOOT=TRUE") )
    {
      error ("Failed to start CTSS");
      error ("Failed to start Oracle Clusterware stack");
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }

    # Start ASM if needed
    if ( ($CRS_STORAGE_OPTION == 1) &&
         (! start_resource("ora.asm", "-init")) )
    {
      error ("Failed to start ASM");
      error ("Failed to start Oracle Clusterware stack");
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }

    # Start CRS
    if ( ! start_resource("ora.crsd", "-init") )
    {
      error ("Failed to start CRS");
      error ("Failed to start Oracle Clusterware stack");
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }

    # Start EVM
    if ( ! start_resource("ora.evmd", "-init") )
    {
      error ("Failed to start EVM");
      error ("Failed to start Oracle Clusterware stack");
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }

    trace ("Successfully started Oracle clusterware stack");

  if (!wait_for_stack_start(24)) { 
     writeCkpt($ckpt, CKPTFAIL);
     exit 1; 
  }
  writeCkpt($ckpt, CKPTSUC);

}

###---------------------------------------------------------
#### Function for tracing logging messages for root scripts
# ARGS : 0
sub trace
{
    my ($sec, $min, $hour, $day, $month, $year) =
        (localtime) [0, 1, 2, 3, 4, 5];
    $month = $month + 1;
    $year = $year + 1900;

    if ($CFG && $CFG->crscfg_trace) {
      my $CRSCFG_TRACE_FILE = $CFG->crscfg_trace_file;
      if ($CRSCFG_TRACE_FILE) {
        open (TRCFILE, ">>$CRSCFG_TRACE_FILE")
          or die "trace(): Can't open $CRSCFG_TRACE_FILE for append: $!";
      }
      printf TRCFILE  "%04d-%02d-%02d %02d:%02d:%02d: @_\n",
        $year, $month, $day, $hour, $min, $sec;
      close (TRCFILE);
    } else {
      printf "%04d-%02d-%02d %02d:%02d:%02d: @_\n",
        $year, $month, $day, $hour, $min, $sec;
    }
}

####---------------------------------------------------------
#### Function for dumping errors on STDOUT
# ARGS : 0 
sub error
{
    print "@_\n";

    if ($CFG && $CFG->crscfg_trace && $CFG->crscfg_trace_file) {
        trace (@_);
    }
    if ($DEBUG) {
      trace("###### Begin Error Stack Trace ######");
      backtrace();
      trace("####### End Error Stack Trace #######\n");
    }
}

sub backtrace {
  my $levels = $_[0];
  my $done = FALSE;

  trace(sprintf("    %-15s %-20s %-4s %-10s", "Package", "File",
                "Line", "Calling"));
  trace(sprintf("    %-15s %-20s %-4s %-10s", "-" x 15, "-" x 20,
                "-" x 4, "-" x 10));
  for (my $bt = 1; ((!$levels && !$done) || $bt <= $levels); $bt++) {
    my @caller = caller($bt);
    if (scalar(@caller) == 0) { $done = TRUE; }
    else {
      my $pkg = $caller[0];
      my $file = basename($caller[1]);
      my $line = $caller[2];
      my $sub  = $caller[3];
      trace(sprintf("%2d: %-15s %-20s %4d %s", $bt, $pkg, $file,
                    $line, $sub));
    }
  }
}

sub dietrap {
  trace("###### Begin DIE Stack Trace ######");
  backtrace(0);
  trace("####### End DIE Stack Trace #######\n");
  die @_;
};

sub print_config
{
  my $cfg = shift;

  my @cfgfiles = ($cfg->paramfile);

  if ($cfg->osdfile && -e $cfg->osdfile) { push @cfgfiles, $cfg->osdfile; }
  if ($cfg->addfile && -e $cfg->addfile) { push @cfgfiles, $cfg->addfile; }

  trace ("### Printing the configuration values from files:");
  for my $file (@cfgfiles) { trace("   $file"); }

  # validates if any value is assigned to the script variables
  for my $key (sort(keys %{$cfg->params})) {
    my $val = $cfg->params($key);
    trace("$key=$val");
  }

  trace ("### Printing other configuration values ###");
  my %cfgh = %{($cfg)};
  for my $key (sort(keys %cfgh)) {
    my $ref = ref($cfg->$key);
    my $val = $cfgh{$key};

    if (!$ref) { trace("$key=$val"); } # scalar
    elsif ($ref eq "ARRAY") { trace("$key=" . join(' ', @{($val)})); }
    elsif ($ref eq "HASH" && $key ne "params" &&
           scalar(keys(%{($val)}))) {
      trace("Printing values from hash $key");
      my %subh = %{($val)};
      for my $hkey (sort(keys(%subh))) {
        trace("  $key key $hkey=$subh{$hkey}");
      }
    }
  }

  trace ("### Printing of configuration values complete ###");

  return;
}

####---------------------------------------------------------
#### Function for checking and returning Super User name
# ARGS : 0
sub check_SuperUser
{
    my $superuser = s_check_SuperUser ()
        or trace("Not running as authorized user");
    return $superuser;
}

####---------------------------------------------------------
#### Function for getting this host name in lower case with no domain name
# ARGS : 0
sub tolower_host
{
    trace ("Parsing the host name");

    my $host = hostname () or return "";

    # If the hostname is an IP address, let hostname remain as IP address
    # Else, strip off domain name in case /bin/hostname returns FQDN
    # hostname
    my $shorthost;
    if ($host =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
        $shorthost = $host;
    } else {
        ($shorthost,) = split (/\./, $host);
    }

    # convert to lower case
    $shorthost =~ tr/A-Z/a-z/;

    return $shorthost;
}

sub trim
################################################################################
# Function: Remove leading and trailing blanks.
#
# Arg     : string
#
# Return  : trimmed string
################################################################################
{
   my $str = $_;
   $str = shift;
   $str =~ s/^\s+//;
   $str =~ s/\s+$//;
   return $str ;
}

####---------------------------------------------------------
#### Function for validating SIHA installer variables list
# ARGS: 1
# ARG1: Filename in which these parameters are set
sub validateSIHAVarList
{
    my $all_found = SUCCESS;
    my $cfg = shift;
    my $paramfile = $cfg->paramfile;

    # list of params that MUST be specified in the param file
    my @required = ("ORACLE_HOME", "ORACLE_OWNER", "ASM_UPGRADE");

    if ($CFG->platform_family eq 'unix') {
      push @required, "ORA_DBA_GROUP";
    }

    for my $param (@required) {
      if (!$cfg->params($param) || $cfg->params($param) =~ /^%/) {
        error("Required parameter $param not found in $paramfile");
        $all_found = FAILED;
      }
    }

    return $all_found;
}

####---------------------------------------------------------
#### Function for validating installer variables list
# ARGS: 0
#
# This validates parameters by checking to see that all have had proper
# substituion.
# There is probably a list of required parameters that should be
# verified to be specified and reasonable
sub validateCRSVarList
{
  my %params = %{($CFG->params)};
  my $all_set = SUCCESS;
  my @keys   = keys(%params);

  trace ("Checking parameters from paramfile " . $CFG->paramfile .
         " to validate installer variables");

  # validates if any value is assigned to the script variables
  for my $key (sort(@keys)) {
    my $val = $CFG->params($key);
    if ($val =~ /^%/) {
      error ("No value set for the parameter $key. ",
             "Use parameter file ", $CFG->paramfile, " to set values");
      $all_set = FAILED;
    }
  }

  return $all_set;
}

####-----------------------------------------------------------------------
#### Function for performing one-time clusterwide setup
# ARGS: 0
sub first_node_tasks
{
    # if in ADE env, skip these steps and return success
    if (is_dev_env()) {
        return SUCCESS;
    }

    return s_first_node_tasks ();
}

####---------------------------------------------------------
#### Validating OCR locations based on existing ocr settings
# ARGS: 3
# ARG1 : Path for Oracle CRS home
# ARG2 : Cluster name
# ARG3 : Comma separated OCR locations
sub validateOCR
{
    my $crshome = $_[0];
    my $clustername = $_[1];
    my $ocrlocations = $_[2];

    my $status = SUCCESS;

    if (!$crshome) {
        error ("Null value passed as Oracle CRS home");
        return FAILED;
    }

    if (!(-d $crshome)) {
        error ("The file \"$crshome\" does not exist");
        return FAILED;
    }

    trace ("Oracle CRS home = $crshome");

    if (!($clustername)) {
        error ("Null value passed as Oracle Clusterware name");
        return FAILED;
    }

    trace ("Oracle cluster name = $clustername");

    if (isAddNode($HOST, $CFG->params('NODE_NAME_LIST'))) {
       if (! s_copyOCRLoc()) {
          error ("Unable to copy OCR locations");
          return FAILED;
       }
    } elsif (! $ocrlocations) {
       error ("Null value passed as OCR locations");
       return FAILED;
    }

    trace ("OCR locations = $ocrlocations");
    trace ("Validating OCR");

    # call OSD API
    return s_validateOCR ($crshome, $clustername, $ocrlocations);
}

####---------------------------------------------------------
#### Function for 'TOUCH'ing local.olr file if it does not exist
#    It also validates/sets up OLR config if does not exist
# ARGS: 2
# ARG1 : Complete path of OLR location
# ARG2 : CRS Home
sub validate_olrconfig
{
    my $olrlocation = $_[0];
    my $crshome     = $_[1];
    my $IS_SIHA     = $CFG->IS_SIHA;
    my $ORACLE_OWNER = $CFG->params('ORACLE_OWNER');
    my $ORA_DBA_GROUP = $CFG->params('ORA_DBA_GROUP');

    if (!$olrlocation) {
        error ("Null value passed for olr location");
        return FAILED;
    }

    if (-e $olrlocation)
    {
       # delete olr file if exists
       if ($DEBUG) { trace ("unlink ($olrlocation)");}
       unlink ($olrlocation) or error ("Can't delete $olrlocation: $!");
    }

    if (!(-f $olrlocation)) 
    {
       # create an empty file and reset permission
       if ($DEBUG) { trace ("create $olrlocation");}
       open (FILEHDL, ">$olrlocation") or return FAILED;
       close (FILEHDL);

       if ($IS_SIHA) {
          s_set_ownergroup ($ORACLE_OWNER, $ORA_DBA_GROUP, $olrlocation)
               or die "Can't change ownership on $olrlocation: $!";
          s_set_perms ("0600", $olrlocation) 
               or die "Can't set permissions on $$olrlocation: $!";
       } else {
          s_set_ownergroup ($CFG->SUPERUSER, $ORA_DBA_GROUP, $olrlocation)
               or die "Can't change ownership on $olrlocation: $!";
          s_set_perms ("0600", $olrlocation) 
               or die "Can't set permissions on $$olrlocation: $!";

       }
    }
    trace ("OLR location = " . $olrlocation);

    if (!$crshome) {
        error ("Null value passed for CRS Home");
        return FAILED;
    }

    if (!(-d $crshome)) {
        error ("The Oracle CRS home path \"$crshome\" does not exist");
    }
    trace ("Oracle CRS Home = " . $crshome);

    # OSD to validate OLR config
    my $rc = s_validate_olrconfig ($olrlocation, $crshome);

    return $rc;
}

####---------------------------------------------------------
#### Function for returning OLR location
# ARGS: 0
sub get_olrdisk
{
    trace ("Retrieving OLR file location");
    return s_get_olrdisk ();
}

####---------------------------------------------------------
#### Function for validating OCR config
# ARGS: 2
# ARG1 : ocrlocations
# ARG2 : isHas
sub validate_ocrconfig
{
    my $ocrlocations = $_[0];
    my $isHas        = $_[1];

    if (!$ocrlocations) {
        error ("Null value passed for olr locations");
        return FAILED;
    }

    trace ("OCR locations = " . $ocrlocations);

    # OSD to validate OCR config
    s_validate_ocrconfig ($ocrlocations, $isHas) or return FAILED;

    return SUCCESS;
}

####---------------------------------------------------------
#### Function for returning OCR location
# ARGS: 0
sub get_ocrdisk
{
    trace ("Retrieving OCR main disk location");
    return s_get_ocrdisk ();
}

####---------------------------------------------------------
#### Function for returning OCR mirror location
# ARGS: 0
sub get_ocrmirrordisk
{
    trace ("Retrieving OCR mirror disk location");
    return s_get_ocrmirrordisk ();
}

####---------------------------------------------------------
#### Function for returning OCR loc3 location
# ARGS: 0
sub get_ocrloc3disk
{
    trace ("Retrieving OCR loc3 disk location");

    my $OCRCONFIG = $CFG->params('OCRCONFIG');
    my $ret;

    if (!(-r $OCRCONFIG)) {
        error ("Either " . $OCRCONFIG . " does not exist or is not readable");
        error ("Make sure the file exists and it has read and execute access");
        return $ret;
    }

    $ret = s_get_config_key ("ocr", "ocrconfig_loc3");

    return $ret;
}

####---------------------------------------------------------
#### Function for returning OCR loc4 location
# ARGS: 0
sub get_ocrloc4disk
{
    trace ("Retrieving OCR loc4 disk location");

    my $OCRCONFIG = $CFG->params('OCRCONFIG');
    my $ret;

    if (!(-r $OCRCONFIG)) {
        error ("Either " . $OCRCONFIG . " does not exist or is not readable");
        error ("Make sure the file exists and it has read and execute access");
        return $ret;
    }

    $ret = s_get_config_key ("ocr", "ocrconfig_loc4");

    return $ret;
}

####---------------------------------------------------------
#### Function for returning OCR loc5 location
# ARGS: 0
sub get_ocrloc5disk
{
    trace ("Retrieving OCR loc5 disk location");

    my $OCRCONFIG = $CFG->params('OCRCONFIG');
    my $ret;

    if (!(-r $OCRCONFIG)) {
        error ("Either " . $OCRCONFIG . " does not exist or is not readable");
        error ("Make sure the file exists and it has read and execute access");
        return $ret;
    }

    $ret = s_get_config_key ("ocr", "ocrconfig_loc5");

    return $ret;
}

####---------------------------------------------------------
#### Function for returning OCR local_only location from ocr.loc
# ARGS: 0
sub get_ocrlocaldisk
{
    my $OCRCONFIG = $CFG->params('OCRCONFIG');
    my $ret = "";

    if (!(-r $OCRCONFIG)) {
        error ("Either " . $OCRCONFIG . " does not exist or is not readable");
        error ("Make sure the file exists and it has read and execute access");
        return $ret;
    }

    $ret = s_get_config_key ("ocr", "local_only");

    return $ret;
}

####---------------------------------------------------------
#### Function for retrieving SRV location from ocr.loc
# ARGS: 0
sub get_srvdisk
{
    my $SRVCONFIG = $CFG->params('SRVCONFIG');
    my $ret = "";

    if (!(-r $SRVCONFIG)) {
        error ("Either " . $SRVCONFIG . " does not exist or is not readable");
        error ("Make sure the file exists and it has read and execute access");
        return $ret;
    }

    $ret = s_get_config_key ("srv", "srvconfig_loc");

    return $ret;
}

####---------------------------------------------------------
#### Check if this is a SI CSS configuration
sub validate_SICSS
{
    trace ("Validating for SI-CSS configuration");

    my $ocrfile = get_ocrdisk();

    if (!$ocrfile) {
        trace ("Unable to retrieve ocr disk info");
        return SUCCESS;
    }

    if ($ocrfile =~ /\+/) {
       # return if ocrfile is ASM disk group
       return SUCCESS;
    }
    else {
       if (! (-e $ocrfile)) {
          error ("The file " . $ocrfile . " does not exist");
          return SUCCESS;
       }
    }

    # OCR location already specified. Check if it is used for
    # single instance CSS/ASM
    my $local_flag = s_get_config_key("ocr", "local_only");
    if (!$local_flag) {
        return FAILED;
    }

    # convert to upper-case
    $local_flag =~ tr/a-z/A-Z/;

    trace ("LOCAL_FLAG = " . $local_flag);

    # Previous installation of 10g single instance
    if ($local_flag eq "TRUE") {
        error ("CSS is configured for single instance Oracle databases.");
        error ("Delete this configuration using the command " .
               "'localconfig delete' before proceeding with RAC " .
               "configuration.");
        return FAILED;
    }

    return SUCCESS;
}

####---------------------------------------------------------
#### Check if this is a SI HAS configuration
sub validate_SIHAS
{
    trace ("Validing for SI-HAS configuration");

    my $olrfile = get_olrdisk();

    if (!$olrfile) {
        trace ("olr.loc file does not exist");
        return FALSE;
    }

    if (!(-f $olrfile)) {
        error ("The file " . $olrfile . " does not exist");
        return FALSE;
    }

    # ocr.loc already has a location specified. Check if it is used for
    # single instance CSS/ASM

    my $local_flag = s_get_config_key ("ocr", "local_only");
    if (!$local_flag) {
        return FALSE;
    }

    # convert to upper-case
    $local_flag =~ tr/a-z/A-Z/;

    # Previous installation of 10g single instance
    if ($local_flag eq "TRUE") {
        return TRUE;
    } else {
        return FALSE;
    }
}

####---------------------------------------------------------
#### Function to check if OCR is on ASM
sub isOCRonASM
{
    trace ("Checking if OCR is on ASM");

    my $ocrfile   = get_ocrdisk();
    my $ocrmirror = get_ocrmirrordisk();
    my $ocrloc3   = get_ocrloc3disk();
    my $ocrloc4   = get_ocrloc4disk();
    my $ocrloc5   = get_ocrloc5disk();


    if (!$ocrfile) {
        trace ("OCR config does not exist");
        return FALSE;
    }

    if (($ocrfile =~ /\+/) || ($ocrmirror =~ /\+/) || ($ocrloc3 =~ /\+/) || ($ocrloc4 =~ /\+/) || ($ocrloc5 =~ /\+/)) {
        return TRUE;
    } else {
        return FALSE;
    }
}

####---------------------------------------------------------
#### Function to check if OCR is on ASM
sub isPathonASM
{
   trace ("Checking if given path is on ASM");

   my $diskpath = $_[0];

   if (!$diskpath) {
      trace ("Device path is not specified");
      return FALSE;
   }

   if ($diskpath =~ /\+/) {
      return TRUE;
   } 
   else {
      return FALSE;
   }
}

####---------------------------------------------------------
#### Function for checking if CRS is already configured
# ARGS : 1
# ARG1 : CRS home
# ARG2 : Host name
# ARG3 : CRS user
# ARG4 : isCrsConfigured? (OUT var)
sub check_CRSConfig
{
    my $crshome   = $_[0];
    my $hostname  = $_[1];
    my $crsuser   = $_[2];
    my $dbagroup  = $_[3];
    my $gpnpghome = $_[4];
    my $gpnplhome = $_[5];

    my $crsconfigok = FALSE;
    my $gpnp_setup_type = GPNP_SETUP_BAD;

    # init outers
    $_[6] = $crsconfigok; 
    $_[7] = $gpnp_setup_type; 

    trace ("Oracle CRS home = " . $crshome);

    if (!$hostname) {
        error ("Null value passed for host name");
        return FAILED;
    }

    trace ("Host name = " . $hostname);

    if (!$crsuser) {
        error ("Null value passed for Oracle crs user");
        return FAILED;
    }

    trace ("CRS user = " . $crsuser);

    ## Define gpnp globals and validate gpnp directories.
    # Note: This step must be performed unconditionally,
    #       because successfull script use gpnp globals.
    #
    if (! verify_gpnp_dirs( $crshome, $gpnpghome, $gpnplhome,
                            $hostname, $crsuser, $dbagroup ) ) {
        trace("GPnP cluster-wide dir: $gpnpghome, local dir: $gpnplhome.");
        error ("Bad GPnP setup. Check log; GPnP directories must exist.");
        return FAILED;
    }

    ##Checking if CRS has already been configured
    trace ("Checking to see if Oracle CRS stack is already configured");

    # call OSD API
    if (s_check_CRSConfig ($hostname, $crsuser)) {
        $crsconfigok = TRUE;
    }

    ## GPnP validate existing setup, if any
    #  If a cluster-wide setup found, it will be promoted to local 
    $gpnp_setup_type = check_gpnp_setup( $crshome, 
                                         $gpnpghome, $gpnplhome, $hostname,
                                         $crsuser, $dbagroup ); 

    if ($gpnp_setup_type != GPNP_SETUP_GOTCLUSTERWIDE &&
        $gpnp_setup_type != GPNP_SETUP_CLUSTERWIDE)
    {
      trace ("GPNP configuration required");
      $crsconfigok = FALSE;  # gpnp setup is not ok or not finalized
    }
    $CFG->gpnp_setup_type($gpnp_setup_type);

    # reinit outers
    $_[6] = $crsconfigok; 
    $_[7] = $gpnp_setup_type; 
   return SUCCESS;
}

sub validate_9iGSD
#---------------------------------------------------------------------
# Function: Validating if 9iGSD is up
#
# Args    : none
#---------------------------------------------------------------------
{
   trace ("Checking to see if any 9i GSD is up");

   my $exists = s_checkOracleCM ();

   if (! $exists) {
      return $SUCCESS;
   }

   my $lsdb = catfile($ORA_CRS_HOME, 'bin', 'lsdb');

    open (LSDB, "$lsdb -g|")
        or error ("Can't execute \"" . $lsdb . " -g\" and read output: " . $!);
    my @GSDNODE = <LSDB>;
    close (LSDB);

    my $GSDCHK_STATUS = $?;
    # if GSD running, lsdb will print GSD's node name

    if (($GSDCHK_STATUS != 0) && (@GSDNODE)) {
        error ("9i GSD is running on node " . @GSDNODE);
        error ("Stop the GSD and rerun root.sh");
        return FAILED;
    }

    return SUCCESS;
}

####---------------------------------------------------------
#### Function for setting permissions on CRS home files and directories
#
# ::::::::::TBD:::::::::
# How do we incorporate this function under the new scheme?
# ::::::::::TBD:::::::::
#
# ARGS : 3
# ARG1 : crs home path
# ARG2 : The Oracle owner
# ARG3 : The Oracle DBA group
#
#sub setperm_crshome

####---------------------------------------------------------
# 
sub strrchr { substr($_[0], rindex($_[0], $_[1]) + 1) }

####------ [ GPNP

####---------------------------------------------------------

=head2 get_oifcfg_iflist

  Gets "oifcfg iflist" networks interface info, e.g.
  ("eth0  10.0.0.0  PRIVATE 255.255.252.0", 
   "eth1  140.87.4.0  UNKNOWN 255.255.252.0") 
  Note that adapter name (e.g. eth1) can be quoted and contain spaces
  on some platforms, and ip net addr can be ipv6. 

=head3 Parameters

  string with oifcfg home location. If undef, then current home is used.

=head3 Returns

  =head4 returns a list of strings-net intf defs
  =head4 result code (0 for success) as a first member of array.

=cut

sub get_oifcfg_iflist
{
   return get_oifcfg_info(($_[0], 'iflist','-p','-n'));
}

=head2 get_oifcfg_getif

  Gets "oifcfg getif" networks interface info, e.g.
  ("eth0  10.0.0.0  global  public", 
   "eth1  140.87.4.0  global  cluster_interconnect") 
  Note that adapter name (e.g. eth1) can be quoted and contain spaces
  on some platforms, and ip net addr can be ipv6. 

=head3 Parameters

  string with oifcfg home location. If undef, then current home is used.

=head3 Returns

  =head4 returns a list of strings-net intf defs
  =head4 result code (0 for success) as a first member of array.

=cut

sub get_oifcfg_getif
{
   return get_oifcfg_info(($_[0], 'getif'));
}

=head2 get_oifcfg_info

  Gets oifcfg networks interface info for specified command line params.

=head3 Parameters

  =head4 string with oifcfg home location. If undef, then current home is used.
  =head4 Rest of arguments passed to oifcfg cmdline. 

=head3 Returns

  =head4 returns a list of strings-net intf defs; Warning messages, if any, 
         are filtered out.
  =head4 result code (0 for success) as a first member of array.

=cut

sub get_oifcfg_info
{
   my @intfs = ();

   my ($home, @args) = @_;
   my $cmd;
   if (! defined $home) {
     $cmd = crs_exec_path('oifcfg');
   } else {
     $cmd = catfile( $home, 'bin', 'oifcfg' );
   }
   # run oifcfg asking for intf, net, type and mask
   my @out = system_cmd_capture(($cmd, @args));
   my $rc  = shift @out;

   # read-in interface list 
   if (0 == $rc) {
      trace "---Got oifcfg out ($cmd ".join(' ',@args)."):";
      foreach (0..$#out) {
         my $intf = $out[$_];
         trace $intf ;
         # total failure should return rc, else filter out non-fatal
         # error messages, if any, e.g. "PRIF-nn: error....."
         if ($intf !~ /^PR[A-Z]+-[0-9]+: /) {
           push @intfs, $intf ;
         } else {
           error( $intf );
         }
      }
   } else {
      push @intfs, "$cmd ".join(' ',@args)." failed."; 
   }
   return ($rc, @intfs);
}

=head2 get_olsnodes_info

  Gets olsnodes output for given command line params. 

=head3 Parameters

  string with olsnodes home location. If undef, then current home is used.

=head3 Returns

  =head4 returns a list of strings with node names. Warning messages, if any,
         are filtered out.
  =head4 result code (0 for success) as a first member of array.

=cut

sub get_olsnodes_info
{
   my @nodes = ();

   my ($home, @args) = @_;
   my $cmd;
   if (! defined $home) {
     $cmd = crs_exec_path('olsnodes');
   } else {
     $cmd = catfile( $home, 'bin', 'olsnodes' );
   }

   # run olsnodes w/given pars
   my @out = system_cmd_capture(($cmd, @args));
   my $rc  = shift @out;

   # read-in interface list 
   if (0 == $rc) {
      trace "---Got olsnodes out ($cmd ".join(' ',@args)."):";
      foreach (0..$#out) {
         my $node = $out[$_];
         trace $node ;
         # total failure should return rc, else filter out non-fatal
         # error messages, if any, e.g. "PRCO-nn: error....."
         if ($node !~ /^PR[A-Z]+-[0-9]+: /) {
           push @nodes, $node ;
         } else {
           error( $node );
         }
      }
   } else { 
      push @nodes, "$cmd ".join(' ',@args)." failed.";
   }
   return ($rc, @nodes);
}

=head2 get_ocr_privatenames_info

  Gets OCR information about configured private nodenames in form 
  indentical to "olsnodes -p" output (nodename private_names...).

  This is used to replace olsnodes-p where not available, e.g. on 10.1.
  OCR access performed with ORA_CRS_HOME ocrdump utility by dumping
  SYSTEM.crs keys.
  If all fails, will try "olsnodes" (node names only) in old home as 
  a last resort.

=head3 Parameters

  string with olsnodes home location. If undef, then current home is used.

=head3 Returns

  =head4 returns a list of strings with node names.
  =head4 result code (0 for success) as a first member of array.

=cut

sub get_ocr_privatenames_info
{
   my @nodes = ();

   my $home = $_[0];
   my $cmd;
   if (! defined $home) {
     $cmd = crs_exec_path('ocrdump');
   } else {
     $cmd = catfile( $home, 'bin', 'ocrdump' );
   }

   # run "ocrdump -stdout -keyname SYSTEM.css"
   my @args = ($cmd, '-stdout', '-keyname', 'SYSTEM.css');
   my @out = system_cmd_capture(@args);
   my $rc  = shift @out;

   if ($DEBUG) {
     trace "---SYSTEM.css OCR dump:\n".
           join(' ',@args)."\nout: \n".join("\n",@out)."\n";
   }
   # read-in dumped css keys 
   if (0 == $rc) {
      my @nodnames = grep(/^\[SYSTEM\.css\.node_names\.[^\]\.]+\]$/,   @out);
      my @pvtnames = grep(/^\[SYSTEM\.css\.privatenames\.[^\]\.]+\]$/, @out);

      if (!(defined @nodnames) || !(defined @pvtnames)) {
         trace "Warning: OCR has no css public or private node names. ";
      }
      if ($DEBUG) {
         trace "---OCR node_names: ".  join(' ',@nodnames).
              "\n---OCR pvt_names: ".  join(' ',@pvtnames);
      }
      # to keep it simple, we do not do any matching by nodenum between 
      # node_names and privatenames, since they are not used together anyways;
      # assuming same order, same number.
 
      foreach (0..$#nodnames) {
         my $curidx = $_;
         my $nodname = $nodnames[$_];
         if (defined $nodname) {
           $nodname =~ m/^.+\.([^\]\.]+)\]$/; # take last key - nodename
           $nodname = $1;
         }
         # normally both arrays will be paired
         my $pvtname = $pvtnames[$_];
         if (defined $pvtname) {
           $pvtname =~ m/^.+\.([^\]\.]+)\]$/; # take last key - nodename
           $pvtname = $1;
         }
         if (defined $nodname) {
            push @nodes, "$nodname $pvtname";
         }
         trace ("ocr node parsed: -$nodname-$pvtname-="); 
      }
      if (scalar(@nodes) == 0) {
         error "Failed to get a list of CSS nodes from OCR. ".
               "Setup way not work properly."; 

         # return at least a list of nodes (no -p), so setup can propagate
         # properly - run in old home.
         return get_olsnodes_info($CFG->OLD_CRS_HOME);
      }
   } else { 
      push @nodes, "".join(' ', @args)." failed.";
   }
   return ($rc, @nodes);
}


=head2 get_upgrade_netinfo

  This is a top-level call to get a string with network information for 
  upgrade config.
  (This is an analog of NETOWORKS installer interview parameter.)
  Note: OLD_CRS_HOME must be set to use this function.

=head3 Parameters

  None.

=head3 Returns

  returns a string - a comma-separated list of net intf defs, installer-style

=cut

sub get_upgrade_netinfo
{
   my @iflist_out;    # oifcfg iflist results
   my @getif_out;     # oifcfg getif results
   my @olsnodes_out;  # olsnodes -p results
   my @iflist_info;   # parsed oifcfg iflist results
   my @getif_info;    # parsed oifcfg getif results
   my @ols_info;      # parsed olsnodes results
   my @olsif_info;    # parsed olsnodes results matched against oifcfg iflist
   my @net_info;      # consolidated parsed interfaces to use in prf net cfg
   my $rc;
   my $generrmsg = "Cannot get node network interfaces";

   my $OLD_CRS_HOME = $CFG->OLD_CRS_HOME;
   check_dir( $OLD_CRS_HOME ) or die "Old CRS Home directory is invalid.";

   my @OLD_CRS_VERSION = @{$CFG->oldconfig('ORA_CRS_VERSION')};
   if (! defined @OLD_CRS_VERSION) {
     @OLD_CRS_VERSION = get_crs_version($CFG->ORA_CRS_HOME);
   }

   # oifcfg iflist
   ($rc,@iflist_out) = get_oifcfg_iflist($CFG->ORA_CRS_HOME);
   die "$generrmsg (".join(' ',@iflist_out).")" if ($rc!=0);

   # check if crs is up, if so, do oifcfg getif 
   my $crs_is_up = check_service ("cluster", 2);
   if ($crs_is_up) {
      # getif must be invoked from old crshome
      ($rc,@getif_out) = get_oifcfg_getif($OLD_CRS_HOME);
      die "$generrmsg (".join(' ',@getif_out).")" if ($rc!=0);
   }

   # olsnodes private addrs
   if ($OLD_CRS_VERSION[0] >= 10 && $OLD_CRS_VERSION[1] >= 2) {
   
      ($rc,@olsnodes_out) = get_olsnodes_info($OLD_CRS_HOME, '-p');
      die "$generrmsg (".join(' ',@olsnodes_out).")" if ($rc!=0); 
   
   } else {
      # CRS <10.2 does not support olsnodes -p
      trace( "\"olsnodes -p\" unavailable in ".
             join('.', @OLD_CRS_VERSION). 
             " -- will try OCR interconnects instead ");

      ($rc,@olsnodes_out) = get_ocr_privatenames_info($ORA_CRS_HOME);
      die "$generrmsg (".join(' ',@olsnodes_out).")" if ($rc!=0); 
   } 

   @iflist_info = parse_netinfo( \@iflist_out ); 
   $rc = shift @iflist_info; 
   die "$generrmsg (failed to parse oifcfg iflist output)" if ($rc!=0); 

   @getif_info = parse_netinfo( \@getif_out ); 
   $rc = shift @getif_info; 
   die "$generrmsg (failed to parse oifcfg getif output)" if ($rc!=0); 

   @ols_info = parse_olsnodesp_netinfo( \@olsnodes_out ); 
   $rc = shift @ols_info; 
   die "$generrmsg (failed to parse olsnodes -p output)" if ($rc!=0); 

   # validate olsnodes info against getif/iflist data
   # first, match to node interfaces 
   @olsif_info = match_node_netintfs( \@ols_info, \@iflist_info );
   $rc = shift @olsif_info; 
   die "$generrmsg (failed to get olsnodes networks)" if ($rc!=0); 

   # then, consolidate oifcfg-getif and olsnodes-p results
   @net_info = match_getif_netintfs( \@getif_info, \@olsif_info );
   $rc = shift @net_info; 
   die "$generrmsg (failed to consolidate network info)" if ($rc!=0); 

   my $s_instiflist = '';
   foreach (0..$#net_info) {
      my $intfref = $net_info[$_];
      $s_instiflist = oifcfg_intf_to_instlststr( $intfref, $s_instiflist );
   }
   trace ("upgrade netlst: \"".$s_instiflist."\""); 

   # convert netinfo into cmdline pars 
   if ($DEBUG) {
     my @netprogram =  instlststr_to_gpnptoolargs( $s_instiflist );
     trace ("upgrade netcmd: \"".join(' ',@netprogram)."\""); 
   }

   # get a comma-separated list of cluster nodes to push cluster-wide
   # gpnp setup to
   my $s_cluster_nodes = get_upgrade_node_list( \@ols_info );
   trace ("upgrade node list: \"".$s_cluster_nodes."\""); 

   return ($s_instiflist, $s_cluster_nodes);
}

=head2 get_upgrade_node_list

  Create a comma-seaparated list of cluster nodes based on parsed oldnodes 
  info. 

=head3 Parameters

  =head4 an array reference of parsed olsnodes-p info (refs to parsed lines).

=head3 Returns

  =head4 returns a comma-separated list of cluster nodes.

=cut

sub get_upgrade_node_list
{
   my $olsref = $_[0];    #ref
   my @olshs = @{$olsref};     # array of parsed olsnodes host/pvthost arrays
   my $s_nodes_list = "";

   foreach (0..$#olshs) {
      my $olsintfref = $olshs[$_];
      my ($node, $pvtnode) = @{$olsintfref};

      if (defined $node) {
         if (! ($s_nodes_list eq "")) {
            $s_nodes_list .= ",";
         }
         $s_nodes_list .= $node;
      }
   }
   if ($DEBUG) {
      trace "Cluster node list, per olsnodes: \"$s_nodes_list\"";
   }
   return $s_nodes_list;
}

=head2 match_node_netintfs

  Create a table of oifcfg-style cluster-interconnect interfaces based on 
  oldnodes -p private node names, resolved and matched against available 
  node interfaces. 

=head3 Parameters

  =head4 an array reference of parsed olsnodes-p info (refs to parsed lines).
  =head4 an array reference of parsed oifcfg-iflist info (refs to parsed lines)

=head3 Returns

  =head4 returns an array of parsed oifcfg-iflist style info (array of refs) 
         for cluster-interconnect interfaces inferred from olsnodes-p output.
  =head4 result code (0 for success) as a first member of array.

=cut

sub match_node_netintfs
{
   my $olsref = $_[0];    #ref
   my $oiflstref = $_[1]; #ref
   my @olshs = @{$olsref};     # array of parsed olsnodes host/pvthost arrays
   my @intfs = @{$oiflstref};  # array of parsed oifcfg iflist arrays
   my @netinfo = ();
   my $rc = 0;

   trace "Processing ".scalar(@olshs)." olsnodes:";
   foreach (0..$#olshs) {
      my $olsintfref = $olshs[$_];
      my $node;
      my $pvtnode;
      my $iaddr;
      my $saddr;
      ($node, $pvtnode) = @{$olsintfref};
      trace "   node $_ pub:$node pvt:$pvtnode=";

      # [ resolve private node into addr 
      if (defined $pvtnode) {
         my $name;
         my $aliases;
         my $addrtype;
         my $length;
         my @addrs;
         ($name, $aliases, $addrtype, $length, @addrs) = 
              gethostbyname $pvtnode
              or die "Can't gethostbyname on $pvtnode: $!";

         (($addrtype == AF_INET) && (scalar(@addrs) > 0)) or next;
         ($length == 4) or error "IPv6 is currently not supported"; # 16

         trace "     $pvtnode addrs: ";
         for my $iiaddr (@addrs) {
            $saddr = undef;
            $iaddr = undef;
            if (defined $iiaddr) {
               $saddr = inet_ntoa( $iiaddr );
               trace "       $saddr ";

               # toberevised: +ipv6 - inet_pton
               $iaddr = ipv4_atol($saddr); 
            }
            if (defined $saddr) {
               # Now loop through the iflist interfaces and see if 
               # node private addr matched for known adapter
               foreach (0..$#intfs) {
                  my $intfref = $intfs[$_];
                  my $ada; 
                  my $net;
                  my $nod;
                  my $typ;
                  my $msk;
                  ($ada, $net, $nod, $typ, $msk ) = @{$intfref};
                  if ((defined $msk) && (defined $net) && (defined $ada)) {

                     # toberevised: +ipv6 - inet_pton
                     my $imask = ipv4_atol($msk); 
                     my $inet  = ipv4_atol($net); 

                     my $match = FALSE;
                     $match = TRUE if (($imask & $iaddr) == $inet);
                     my $unique = TRUE;
                     if ($match) {
                        foreach (0..$#netinfo) {
                           my  $intfref1 = $netinfo[$_];
                           my  $ada1 = @{$intfref1}[0];
                           if ($ada1 eq $ada) {
                              $unique = FALSE; 
                              last;
                           }
                        }
                        if ($unique) { 
                           # make a new cluster_interconnect intf
                           my @intf = ($ada, $net, 'global', 
                                       'cluster_interconnect', $msk );
                           push @netinfo, \@intf; 
                        }
                     }
                     trace("        matching olsnodes/iflist ".
                           "(net $net == $saddr & $msk) match=$match ".
                           "unique=$unique");
                  }
               }
            }
         }
      }
      # ] 
   }
   return ($rc, @netinfo);
}


=head2 match_getif_netintfs

  Create a consolidated table of all used oifcfg-style interfaces based on 
  oifcfg getif info, ammended with resolved oldnodes -p info, if any.
  Resulting netinfo will be used as a NETWORKS info in the gpnp profile.

=head3 Parameters

  =head4 an array reference of parsed oifcfg-getif info (refs to parsed lines).
  =head4 an array reference of parsed oifcfg-olsnodes info from 
         match_node_netintfs (refs to parsed lines)

=head3 Returns

  =head4 returns a merged array of parsed oifcfg-getif style info (array of 
         refs) for available network interfaces.
  =head4 result code (0 for success) as a first member of array.

=cut

sub match_getif_netintfs
{
   my $getifref = $_[0]; #ref
   my $olsifref = $_[1]; #ref
   my @getifs = @{$getifref};  # array of parsed oifcfg getifs arrays
   my @olsifs = @{$olsifref};  # array of parsed olsnodes matched to iflist 
   my @netinfo = ();
   my $rc = 0;

   my $ada; 
   my $net;
   my $nod;
   my $typ;
   my $msk;
   my $getif_pvt_ifs = 0;
   my $getif_pub_ifs = 0;

   # copy getif array into resulting netinfo as base, to be ammended with 
   # olsnodes info
   foreach (0..$#getifs) {
      my $gifref = $getifs[$_];
      ($ada, $net, $nod, $typ, $msk ) = @{$gifref};
      if (defined $ada) {
         my @netif = ($ada, $net, $nod, $typ, $msk );
         push @netinfo, \@netif;  # add unconditionally
 
         # count if types
         if ($typ =~ m/cluster_interconnect/i) {
           $getif_pvt_ifs++;
         }
         if ($typ =~ m/public/i) {
           $getif_pub_ifs++;
         }
      }
   }
   # If getif has no interconnects, try to derive them from 
   # olsnodes/ocr-private-name info:
   # loop through olsnodes interfaces and see if there is something not
   # yet present in results
   #
   # Note: ALL olsifs are cluster_interconnects
   #
   if ( $getif_pvt_ifs == 0 ) {
     foreach (0..$#olsifs) {
        my $olsifref = $olsifs[$_];
        ($ada, $net, $nod, $typ, $msk ) = @{$olsifref};

        my $match = FALSE;
        my $typealt = FALSE;
        if (defined $ada) {

          foreach (0..$#netinfo) {
            my $netifref = $netinfo[$_];
            my $ada_if; 
            my $net_if;
            my $nod_if;
            my $typ_if;
            my $msk_if;
            ($ada_if, $net_if, $nod_if, $typ_if, $msk_if ) = @{$netifref};
            #   0        1         2        3       4
            
            # if a different interface with the same subnet found in results
            # do not add it, just update the type. 
            # (Loose match on subnet, not adapter name if ($ada eq $ada_if))
            #
            if ($net eq $net_if) {
               $match = TRUE;

               # make sure olsnodes type is included in the results type
               # - If there are multiple public types defined, override 
               #   matching interfaces to be cluster_interconnects
               # - If there is only single public, make it dual-purpose
               #
               if ($typ_if !~ m/$typ/i) { 
                 $typealt = TRUE;
                 if ($getif_pub_ifs > 1) {
                   $getif_pub_ifs--;
                   ${$netifref}[3] = $typ; # replace
                 } else {
                   ${$netifref}[3] = $typ_if .= ",$typ"; # append
                 }
               }
               last;
            }
         }
         # if olsnodes interface is not int the results yet, add a copy 
         if (! $match) {
            my @olsif = @{$olsifref};
            push @netinfo, \@olsif;
         }
         trace(" matching olsnodes/getif $ada-$net match=$match ".
               "typealt=$typealt ");
       }
     } # for olsifs
   }
   trace "---resulting upgrade iflist:";
   foreach (0..$#netinfo) {
      my $netifref = $netinfo[$_];
      ($ada, $net, $nod, $typ, $msk ) = @{$netifref};
      trace ("intf $_: -$ada-$net-$nod-$typ-$msk-");  
   }
   trace "---";
   return ($rc, @netinfo);
}

=head2 parse_netinfo

  Parse oifcfg-style netinfo (iflist/getif) into array of refs to array
  for each interface, containing interface definition elements.
  See oifcfg_intf_parse.

=head3 Parameters

  An array reference of strings with oifcfg output.

=head3 Returns

  =head4 returns a resulting array of parsed interfaces, each represented as
         an array containing string components of interface definition 
         (interface name (unquoted), masked addr, 
         scope (global/node), type (public,cluter_interconnect), mask).
  =head4 result code (0 for success) as a first member of array.

=cut

sub parse_netinfo
{
   my $netoutref = $_[0]; #ref
   my @intfs = @{$netoutref};
   my @netinfo = ();
   my $rc = 0;

   foreach (0..$#intfs) {
      my $idef = $intfs[$_];
      my $ada; 
      my $net;
      my $nod;
      my $typ;
      my $msk;
      my @net = oifcfg_intf_parse( $idef );
      ($ada, $net, $nod, $typ, $msk ) = @net;
      if ((defined $typ) && (defined $net) && (defined $ada)) {
        push @netinfo, \@net;
      }
   }
   return ($rc, @netinfo);
}

=head2 parse_olsnodesp_netinfo

  Parse olsnodes-style netinfo into array of refs to array
  for each node info. Each array contains public and private node name.

=head3 Parameters

  An array reference of strings with olsnodes output.

=head3 Returns

  =head4 returns an array of parsed olsnodes node info arrays (public/private
         node name).
  =head4 result code (0 for success) as a first member of array.

=cut

sub parse_olsnodesp_netinfo
{
   my $netoutref = $_[0]; #ref
   my @intfs = @{$netoutref};
   my @netinfo = ();
   my $rc = 0;

   foreach (0..$#intfs) {
      my $idef = $intfs[$_];
      my $n;
      my $host;
      my $pvthost;

      if ($DEBUG)
        { trace ("intf: $idef"); }

      # olsnodes -p will give output in form "<hostname> <privatehonm>" lines.
      $idef =~ s/^\s+|\s+$//g;
      $idef =~ s/\s+/ /g;
      $n    = rindex( $idef, ' ' );
      $host = substr( $idef, 0, $n );

      $pvthost = substr( $idef, $n+1 );

      my @net = ($host, $pvthost);
      if (defined $host) {
        push @netinfo, \@net;
      }
      if ($DEBUG)
        { trace ("node parsed: -$host-$pvthost-="); }
   }
   return ($rc, @netinfo);
}

####---------------------------------------------------------

=head2 ipv4_atol
  Convert a string with decimal dotted ipv4 to network-ordered long
  Note: this is quite similar to inet_aton(); however, it does not tries
  to resolve hostnames as inet_aton does.

=head3 Parameters

  String containing decimal-dotted ipv4 address value.

=head3 Returns

 @returns a network-ordered long ipv4 address value.

=cut

sub ipv4_atol
{
  return unpack('N',pack('C4',split(/\./,shift)));
}

=head2 ipv4_ltoa
  Convert a network-ordered long ipv4 address value to a 
  string decimal dotted ipv4 notation.

=head3 Parameters

  Long containing network-ordered ipv4 address value.

=head3 Returns

 @returns a string dotted-decimal ipv4 address value.

=cut

sub ipv4_ltoa
{
  return inet_ntoa(pack('N',shift));
}

=head2 oifcfg_intf_parse

  Parse a single net interface description produced by oifcfg cmd.
  For example:
  a) oifcfg iflist output:
   "eth0  10.0.0.0  PRIVATE  255.255.252.0", 
   "eth1  140.87.4.0  UNKNOWN  255.255.252.0",
   "Local Area Connection 3  140.87.128.0  PRIVATE"
  b) oifcfg getif output:
   "Local Area Connection 4  140.87.136.0  global  cluster_interconnect,public"

=head3 Parameters

  A string containing oifcfg interface definition, see examples above. 
  (Other strings, such as warnings, etc., must be filtered out.)

=head3 Returns

 @returns an array of interface parameters:
   ($adapter_name, $network, $node_name, $type_list, $mask)
   Where:
   adapter_name is the name of net adapter, unquoted;
   network is a network bits of adapter address;
   node_name is 'global' for cluster-wide config, or node name if node-specific;
   type_list is a comma-separated list of network types (valid values are
             unknown|local|public|private|cluster_interconnect);
   mask is a mask bits;
   If any of the parameters was not defined, undef returned in its place.

=cut

sub oifcfg_intf_parse 
{
   my $idef = $_[0]; 
   my $valid_types = "(local|public|private|unknown|cluster_interconnect)([,](local|public|private|unkown|cluster_interconnect))*";
   my $an_; 
   my $ada; 
   my $net;
   my $nod;
   my $typ;
   my $msk;
   my $iaddr; 
   my $n; 
   if ($DEBUG) 
      { trace ("intf: $idef"); } 
   $idef =~ s/^\s+|\s+$//g; 
   $n   = rindex( $idef, ' ' );
   $an_ = substr( $idef, 0, $n );
   $an_ =~ s/\s+$//; 
 
   $typ = substr( $idef, $n+1 );
   if ($typ !~ m/$valid_types/i) { # if cannot be type, check if mask
      $msk = $typ;
      $typ = undef;

      # validate mask
      $iaddr = ipv4_atol($msk); # toberevised: +ipv6 - inet_pton
      if (! defined $iaddr) {
         $msk = undef;
      } else {
         $msk = ipv4_ltoa($iaddr); # toberevised: +ipv6 - inet_ntop
      }
      $iaddr = undef;
      if (defined $msk)
      {
         $n   = rindex( $an_, ' ' );
         $typ = substr( $an_, $n+1 );
         $an_ = substr( $an_, 0, $n );
         $an_ =~ s/\s+$//; 
      }
   }
   if ($typ !~ m/$valid_types/i) {
      $typ = undef;
   }
   if (defined $typ) {
      $n = rindex( $an_, ' ' );
      if (1 <= $n) {
         $ada = substr( $an_, 0, $n );
         $ada =~ s/\s+$//;
         $net = substr( $an_, ($n+1) );

         # validate address, if not addr, must be scope (nodename/global) 
         $iaddr = ipv4_atol($net); # toberevised: +ipv6 - inet_pton
         if ((! defined $iaddr) || ($iaddr == 0)) {
           $nod = $net;
           $net = undef;
           $n = rindex( $ada, ' ' );
           if (1 <= $n) {
             $net = substr( $ada, ($n+1) );
             $ada = substr( $ada, 0, $n );
             $ada =~ s/\s+$//;
           }
           # validate address
           $iaddr = ipv4_atol($net); #toberevised: +ipv6 -inet_pton
         }
         if ((! defined $iaddr) || ($iaddr == 0)) {
           $net = undef;
         } else {
           $net = ipv4_ltoa($iaddr); # toberevised: +ipv6 - inet_ntop
         }
         $iaddr = undef;
      }
   }
   if ($DEBUG) 
      { trace ("intf parsed: -$ada-$net-$nod-$typ-$msk-="); } 
   return ($ada, $net, $nod, lc($typ), $msk );
}

=head2 oifcfgiflst_to_instlststr

 Create GPnP networks list based on oifcfg info
 Example of output:
 "Local Area Connection 3"/140.87.128.0:public,"Local Area Connection 4"/140.87.136.0:cluster_interconnect|public
 or 
 eth0/10.0.100.0:cluster_interconnect,eth1/140.87.4.0.0:public
 Adaptor name can be quoted. /\<>|"*? are not legal for in adapter name (note,
 spaces or commas can appear). List is space-separated.
 For the sake of "oifcfg iflist" compatibility, UNKNOWN/PRIVATE/LOCAL types
 recognized (UNKNOWN mapped to public, PRIVATE mapped to cluster_interconnect,
 and LOCAL skipped. oifcfg types can be combined (comma-separated) - inst
 list uses | separator, though installer never produces interfaces with
 multiple types.

=head3 Parameters

  Reference to array of oifcfg-style output, e.g.
   ("eth0  10.0.0.0  PRIVATE", "eth1  140.87.4.0  UNKNOWN") 
   ("Local Area Connection 3 140.87.128.0 PUBLIC", i
    "Local Area Connection 4 140.87.136.0 CLUSTER_INTERCONNECT,PUBLIC" )
   
=head3 Returns 

  returns a string with installer-style net info.

=cut

sub oifcfgiflst_to_instlststr
{
   my $intfsref  = $_[0]; # ref
   my @intfs     = @{$intfsref};
   my $s_instiflist = '';
   foreach (0..$#intfs) {
      my $idef = $intfs[$_];
      my @intf = oifcfg_intf_parse( $idef );

      $s_instiflist = oifcfg_intf_to_instlststr( \@intf, $s_instiflist );
   }
   trace ("inst netlst:\"".$s_instiflist."\""); 
   return $s_instiflist;
}

=head2 oifcfgiflst_to_instlststr

 Create GPnP network string based oifcfgi-style info for a single net intf.
 Used by oifcfgiflst_to_instlststr

=head3 Parameters

  =head4 Reference to array of parsed oifcfg-style interface, see 
         oifcfg_intf_parse.
  =head4 A ref to a string containing resulting net info string to append.
   
=head3 Returns 

  returns a string with installer-style net info

=cut

sub oifcfg_intf_to_instlststr
{
   my $idefref  = $_[0]; # ref # ref to parsed interface definition
   my $s_instiflist = $_[1];   # list of NETWORKS, installer-style

   my $ada; 
   my $net;
   my $nod;
   my $typ;
   my $msk;
   ($ada, $net, $nod, $typ, $msk ) = @{$idefref};
   $s_instiflist = '' if (! defined $s_instiflist);

   if ((! defined $typ) || (! defined $net) || (! defined $ada)) {
      return; # bad intf definition
   }
   # For the sake of "oifcfg iflist" compatibility, UNKNOWN/PRIVATE/LOCAL types
   # recognized (UNKNOWN mapped to public, 
   # PRIVATE mapped to cluster_interconnect,
   # and LOCAL skipped. oifcfg types can be combined (comma-separated) - inst
   # list uses | separator, though installer never produces interfaces with
   # multiple types.
   #
   if ($typ =~ m/LOCAL/i) {
      return; # skip "do_not_use" itf
   }
   $typ =~ s/(UNKNOWN|unknown)/public/g; 
   $typ =~ s/(PRIVATE|private)/cluster_interconnect/g; 
   $typ =~ s/,/|/g;  # replace separator

   # tabs, \/|"'*:<>? are normally illegal in adapter names
   if ($ada =~ /[ ,:<>\t\^\(\)\\\/\*\?\|\[\]\+]/) { 
      $ada = '"'.$ada.'"';
   }
   if (!($s_instiflist eq '')) {
      $s_instiflist .= ',';
   }
   $s_instiflist .= $ada.'/'.$net.':'.lc($typ);
   if ($DEBUG) 
      { trace ("inst netlst:\"".$s_instiflist."\""); }
   return $s_instiflist;
}

=head2 instlststr_to_gpnptoolargs
   
 Get list of gpnptool net info params based on current list of
 networks in installer-style network list, see oifcfgiflst_to_instlststr.

=head3 Parameters

  =head4 A string with installer-style networks list.
   
=head3 Returns 

  returns a string with gpnptool profile create/edit net generating params.

=cut

sub instlststr_to_gpnptoolargs
{
   my $networks = $_[0];

   my @intfs = ();
   my @program = ( '-hnet=gen', '-gen:hnet_nm="*"' );

   if ($DEBUG) 
      { trace ("iflist: '".$networks."'"); }

   #$networks =~ s/^{|}$//g;
   push(@intfs, $+) while $networks =~ m{
       ("[^\"\\]*(?:\\.[^\"\\]*)*"[^,]+)[,]?  # groups def inside quotes
           | ([^,]+)[,]?
           | [,\s]
         }gx;
   push(@intfs, undef) if substr($networks,-1,1) eq '\s';
   if ($DEBUG)
      { trace ("iflist: ".join("\n", @intfs)); }

   my $i=0;
   foreach (0..$#intfs) {
      my $idef = $intfs[$_];
      my $an_;
      my $ada;
      my $net;
      my $typ;
      my $styp;
      my $n;
      if ($DEBUG) 
         { trace ($idef); }
      if ($idef !~ m/(^.+)[:]((public|cluster_interconnect)([|](public|cluster_interconnect))?)$/) {
         error ("Ivalid network type in \"$idef\" - skipped; ".
                "only \"public\" and \"cluster_interconnect\" are allowed.");
         next;
      } else {
         $an_ = $1;
         $typ = $2;
         $typ =~ s/[|]/,/g; # make std list
         $styp = $typ;
         $n = rindex( $an_, '/' );
         if (1 <= $n)
         {
            $ada = substr( $an_, 0, $n );
            $net = substr( $an_, ($n+1) );
         }
         if ($idef =~ m/"([^\"]+)"/) {
            $ada = $1;
         }
         $i++;
         if ($DEBUG) 
            { trace ("$i => '".$ada."','".$net."','".$styp."'"); }
         push( @program, '-gen:net=net'.$i );
         push( @program, '-net'.$i.':net_ip="'.  $net           .'"' );
         push( @program, '-net'.$i.':net_ada="'. $ada           .'"' );
         push( @program, '-net'.$i.':net_use="'. lc($styp)      .'"' );
      }
   }
   if ($DEBUG)
      { trace ("gpnptool pars: ".join(' ', @program)); }
   return @program;
}

####---------------------------------------------------------
#### Package-wide GPnP constants. 
#
# --- constant result codes:
# gpnp setup result

# gpnp global pars
  our $GPNP_CRSHOME_DIR         ;
  our $GPNP_HOST                ;
  our $GPNP_ORAUSER             ;     
  our $GPNP_ORAGROUP            ;

# gpnp directories
  our $GPNP_GPNPHOME_DIR        ;

  our $GPNP_WALLETS_DIR         ;
  our $GPNP_W_ROOT_DIR          ;
  our $GPNP_W_PRDR_DIR        ;
  our $GPNP_W_PEER_DIR          ;
  our $GPNP_W_PA_DIR            ;

  our $GPNP_PROFILES_DIR        ;
  our $GPNP_P_PEER_DIR          ;

  our $GPNP_GPNPLOCALHOME_DIR   ;

  our $GPNP_L_WALLETS_DIR       ;
  our $GPNP_L_W_ROOT_DIR        ;
  our $GPNP_L_W_PRDR_DIR      ;
  our $GPNP_L_W_PEER_DIR        ;
  our $GPNP_L_W_PA_DIR          ;

  our $GPNP_L_PROFILES_DIR      ;
  our $GPNP_L_P_PEER_DIR        ;

# gpnp files
  our $GPNP_W_ROOT_FILE   ;
  our $GPNP_WS_PA_FILE    ;
  our $GPNP_WS_PEER_FILE  ;
  our $GPNP_WS_PRDR_FILE  ;

  our $GPNP_C_ROOT_FILE   ;
  our $GPNP_C_PA_FILE     ;
  our $GPNP_C_PEER_FILE   ;

  our $GPNP_P_PEER_FILE   ;
  our $GPNP_P_SAVE_FILE   ;

  our $GPNP_L_W_ROOT_FILE   ;
  our $GPNP_L_W_PA_FILE     ;
  our $GPNP_L_WS_PA_FILE    ;
  our $GPNP_L_W_PEER_FILE   ;
  our $GPNP_L_WS_PEER_FILE  ;
  our $GPNP_L_WS_PRDR_FILE  ;

  our $GPNP_L_CRQ_PA_FILE   ;
  our $GPNP_L_CRQ_PEER_FILE ;

  our $GPNP_L_C_ROOT_FILE   ;
  our $GPNP_L_C_PA_FILE     ;
  our $GPNP_L_C_PEER_FILE   ;

  our $GPNP_L_P_PEER_FILE   ;
  our $GPNP_L_P_SAVE_FILE   ;

# gpnp peer wrls
  our $GPNP_W_PEER_WRL      ;
  our $GPNP_L_W_PEER_WRL    ;

# gpnp prdr wrls
  our $GPNP_W_PRDR_WRL    ;
  our $GPNP_L_W_PRDR_WRL  ;

# package tools
  our $GPNP_E_GPNPTOOL      ;
  our $GPNP_E_GPNPSETUP     ;

####---------------------------------------------------------
#### Define package-wide GPnP constants. Values validated separately. 
#### This sub MUST be called before any gpnp setup handling takes place.
# ARGS: 6
# ARG1 : Path for Oracle CRS home
# ARG2 : Path for directory containing gpnp dir with a cluster-wide setup
# ARG3 : Path for directory containing gpnp dir with a local setup
# ARG4 : Current Hostname
# ARG5 : OracleOwner user
# ARG6 : OracleDBA group
# @returns SUCCESS or $FAILURE
#
#static
sub define_gpnp_consts
{
    my $crshome    = $_[0];
    my $gpnpdir    = $_[1];
    my $gpnplocdir = $_[2];
    my $host       = $_[3];
    my $orauser    = $_[4];
    my $oragroup   = $_[5];

    # gpnp directories:
    $GPNP_CRSHOME_DIR     = $crshome;
    $GPNP_HOST            = $host;
    $GPNP_ORAUSER         = $orauser;
    $GPNP_ORAGROUP        = $oragroup;

    # -- cluster-wide
    $GPNP_GPNPHOME_DIR    = catdir( $gpnpdir, GPNP_DIRNAME );
    $GPNP_WALLETS_DIR     = catdir( $GPNP_GPNPHOME_DIR, 
                                    GPNP_W_DIRNAME );
    $GPNP_W_ROOT_DIR      = catdir( $GPNP_WALLETS_DIR, 
                                    GPNP_W_ROOT_DIRNAME );
    $GPNP_W_PRDR_DIR    = catdir( $GPNP_WALLETS_DIR, 
                                    GPNP_W_PRDR_DIRNAME );
    $GPNP_W_PEER_DIR      = catdir( $GPNP_WALLETS_DIR, 
                                    GPNP_W_PEER_DIRNAME );
    $GPNP_W_PA_DIR        = catdir( $GPNP_WALLETS_DIR, 
                                    GPNP_W_PA_DIRNAME );
    $GPNP_PROFILES_DIR    = catdir( $GPNP_GPNPHOME_DIR, 
                                    GPNP_P_DIRNAME );
    $GPNP_P_PEER_DIR      = catdir( $GPNP_PROFILES_DIR, 
                                    GPNP_P_PEER_DIRNAME );
    # -- local
    $GPNP_GPNPLOCALHOME_DIR  = catdir( $gpnplocdir, GPNP_DIRNAME, $host );
    $GPNP_L_WALLETS_DIR   = catdir( $GPNP_GPNPLOCALHOME_DIR, 
                                    GPNP_W_DIRNAME );
    $GPNP_L_W_ROOT_DIR    = catdir( $GPNP_L_WALLETS_DIR, 
                                    GPNP_W_ROOT_DIRNAME );
    $GPNP_L_W_PRDR_DIR    = catdir( $GPNP_L_WALLETS_DIR, 
                                    GPNP_W_PRDR_DIRNAME );
    $GPNP_L_W_PEER_DIR    = catdir( $GPNP_L_WALLETS_DIR, 
                                    GPNP_W_PEER_DIRNAME );
    $GPNP_L_W_PA_DIR      = catdir( $GPNP_L_WALLETS_DIR, 
                                    GPNP_W_PA_DIRNAME );
    $GPNP_L_PROFILES_DIR  = catdir( $GPNP_GPNPLOCALHOME_DIR, 
                                    GPNP_P_DIRNAME );
    $GPNP_L_P_PEER_DIR    = catdir( $GPNP_L_PROFILES_DIR, 
                                    GPNP_P_PEER_DIRNAME );
    # gpnp files:

    # -- cluster-wide
    $GPNP_ORIGIN_FILE     = catfile( $GPNP_GPNPHOME_DIR, 'manifest.txt' );
    $GPNP_W_ROOT_FILE     = catfile( $GPNP_W_ROOT_DIR, GPNP_WALLET_NAME );
    $GPNP_WS_PA_FILE      = catfile( $GPNP_W_PA_DIR,   GPNP_SSOWAL_NAME );
    $GPNP_WS_PEER_FILE    = catfile( $GPNP_W_PEER_DIR, GPNP_SSOWAL_NAME );
    $GPNP_WS_PRDR_FILE    = catfile( $GPNP_W_PRDR_DIR, GPNP_SSOWAL_NAME );
    $GPNP_C_ROOT_FILE     = catfile( $GPNP_W_ROOT_DIR, GPNP_RTCERT_NAME );
    $GPNP_C_PA_FILE       = catfile( $GPNP_W_PA_DIR,   GPNP_CERT_NAME );
    $GPNP_C_PEER_FILE     = catfile( $GPNP_W_PEER_DIR, GPNP_CERT_NAME );
    $GPNP_P_PEER_FILE     = catfile( $GPNP_P_PEER_DIR, GPNP_PROFILE_NAME );
    $GPNP_P_SAVE_FILE     = catfile( $GPNP_P_PEER_DIR, GPNP_PROFSAV_NAME );

    # -- local
    $GPNP_L_W_ROOT_FILE   = catfile( $GPNP_L_W_ROOT_DIR, GPNP_WALLET_NAME );
    $GPNP_L_W_PA_FILE     = catfile( $GPNP_L_W_PA_DIR,   GPNP_WALLET_NAME );
    $GPNP_L_WS_PA_FILE    = catfile( $GPNP_L_W_PA_DIR,   GPNP_SSOWAL_NAME );
    $GPNP_L_W_PEER_FILE   = catfile( $GPNP_L_W_PEER_DIR, GPNP_WALLET_NAME );
    $GPNP_L_WS_PEER_FILE  = catfile( $GPNP_L_W_PEER_DIR, GPNP_SSOWAL_NAME );
    $GPNP_L_WS_PRDR_FILE  = catfile( $GPNP_L_W_PRDR_DIR, GPNP_SSOWAL_NAME );
    $GPNP_L_CRQ_PA_FILE   = catfile( $GPNP_L_W_PA_DIR,   GPNP_CERTRQ_NAME );
    $GPNP_L_CRQ_PEER_FILE = catfile( $GPNP_L_W_PEER_DIR, GPNP_CERTRQ_NAME );
    $GPNP_L_C_ROOT_FILE   = catfile( $GPNP_L_W_ROOT_DIR, GPNP_RTCERT_NAME );
    $GPNP_L_C_PA_FILE     = catfile( $GPNP_L_W_PA_DIR,   GPNP_CERT_NAME );
    $GPNP_L_C_PEER_FILE   = catfile( $GPNP_L_W_PEER_DIR, GPNP_CERT_NAME );
    $GPNP_L_P_PEER_FILE   = catfile( $GPNP_L_P_PEER_DIR, GPNP_PROFILE_NAME );
    $GPNP_L_P_SAVE_FILE   = catfile( $GPNP_L_P_PEER_DIR, GPNP_PROFSAV_NAME );

    # gpnp peer wrls
    $GPNP_W_PEER_WRL      =  "".GPNP_WRL_FILE_PFX.$GPNP_W_PEER_DIR;
    $GPNP_L_W_PEER_WRL    =  "".GPNP_WRL_FILE_PFX.$GPNP_L_W_PEER_DIR;

    # gpnp prdr wrls
    $GPNP_W_PRDR_WRL      =  "".GPNP_WRL_FILE_PFX.$GPNP_W_PRDR_DIR;
    $GPNP_L_W_PRDR_WRL    =  "".GPNP_WRL_FILE_PFX.$GPNP_L_W_PRDR_DIR;

    # package tools
    $GPNP_E_GPNPTOOL      = catfile( $crshome, 'bin', 'gpnptool' );
    $GPNP_E_GPNPSETUP     = catfile( $crshome, 'bin', 'cluutil' );

    return SUCCESS;
}

####---------------------------------------------------------
#### Verify directory exists
# ARGS: 1
# ARG1 : Path to check
# @returns SUCCESS or $FAILURE
# static
sub check_dir { 
  my $chkdirnm  = $_[0];
  if (!(defined($chkdirnm ))) {
    error ("Null dirname in setup $chkdirnm");
    return FAILED;
  } 
  if (!(-d $chkdirnm)) {
    error ("The setup directory \"$chkdirnm\" does not exist");
    return FAILED;
  }
  # not checking perms, since they may not be valid for root
  return SUCCESS;
}

####---------------------------------------------------------
#### Verify file exists
# ARGS: 1
# ARG1 : Path to check
# @returns SUCCESS or $FAILURE
# static
sub check_file { 
  my $chkfilenm  = $_[0];
  if (!(defined($chkfilenm))) {
    error ("Null filename in setup");
    return FAILED;
  } 
  if (!(-f $chkfilenm)) {
    trace ("The setup file \"$chkfilenm\" does not exist");
    return FAILED;
  }
  # not checking perms, since they may not be valid for root
  return SUCCESS;
}

####---------------------------------------------------------
#### Copy file from one local location to another
#
# Copies file from one local location to another
# if user/group given, will chown copied file as it
# ARGS: 4
# ARG1 : Source file path
# ARG2 : Destination file path
# ARG3 : User owner to set (or undef)
# ARG4 : Group owner to set (or undef)
# @returns SUCCESS or $FAILURE
#
sub copy_file { 
  my $src = $_[0]; 
  my $dst = $_[1]; 
  my $usr = $_[2]; 
  my $grp = $_[3]; 

  if (! (-f $src)) {
     trace("  $src ? -f failed" );
     return FAILED;
  }
  trace("  copy \"$src\" => \"$dst\"" );
  if (! copy( $src, $dst ))
  {
    error( "Failed to copy \"$src\" to \"$dst\": $!" ); 
    return FAILED;
  }
  # chown to specific user if requested
  if (defined( $usr ) && defined( $grp )) 
  {
    trace("  set ownership on \"$dst\" => ($usr,$grp)" );
    if (FAILED == s_set_ownergroup ($usr, $grp, $dst)) 
    { 
      error( "Failed to set ownership on $dst: $!" ); 
      return FAILED;
    }
  }
  return SUCCESS;
}

####---------------------------------------------------------
#### Check gpnp setup in given home is complete and valid
# Note: osd-type failure (perms, etc.) will cause invalid
#       setup and attempt to recreate local setup later
# static
sub check_gpnp_home_setup { 
  my $islocal = $_[0]; # boolean (TRUE  - local home (node-specific), 
                       #          FALSE - global home (seed)
  my $gpnphome;
  my $gpnp_p_peer;  
  my $gpnp_w_peer;  
  my $gpnp_w_prdr;  
  my $gpnp_wrl_peer;  
  my $gpnp_wrl_prdr;  
  my $orauser = $GPNP_ORAUSER;

  # assign appropriate gpnp home
  if ($islocal) {
    $gpnphome = $GPNP_GPNPLOCALHOME_DIR; # validated
    $gpnp_p_peer = $GPNP_L_P_PEER_FILE;  
    $gpnp_w_peer = $GPNP_L_WS_PEER_FILE;
    $gpnp_wrl_peer = $GPNP_L_W_PEER_WRL;  
    $gpnp_w_prdr = $GPNP_L_WS_PRDR_FILE;
    $gpnp_wrl_prdr = $GPNP_L_W_PRDR_WRL;  
  } else {
    $gpnphome = $GPNP_GPNPHOME_DIR; # validated
    $gpnp_p_peer = $GPNP_P_PEER_FILE;
    $gpnp_w_peer = $GPNP_WS_PEER_FILE;
    $gpnp_wrl_peer = $GPNP_W_PEER_WRL;  
    $gpnp_w_prdr = $GPNP_WS_PRDR_FILE;
    $gpnp_wrl_prdr = $GPNP_W_PRDR_WRL;  
  }

  # check for mandatory peer profile and wallet, 
  my $profile_ok = check_file( $gpnp_p_peer );
  my $wallet_ok  = check_file( $gpnp_w_peer );
  my $rwallet_ok = check_file( $gpnp_w_prdr );

  trace( "chk gpnphome $gpnphome: profile_ok $profile_ok ".
         "wallet_ok $wallet_ok r/o_wallet_ok $rwallet_ok" );

  if (! $profile_ok || ! $wallet_ok ) {
     trace("chk gpnphome $gpnphome: INVALID (bad profile/wallet)");
     return FAILED;
  }
  # now check profile sig against wallet (wallet owner or peer)
  my $rc = run_gpnptool_verifysig( $gpnp_p_peer, $gpnp_wrl_peer, $orauser );
  if ($rc <= 0) {
     trace("chk gpnphome $gpnphome: INVALID (bad profile signature)");
     return FAILED;
  }
  # now check profile sig against r/o wallet
  if (! $rwallet_ok ) {
     error("chk gpnphome $gpnphome: INCOMPLETE (base gpnp config is ok, but ".
           "gpnp config reader wallet is missing)");
     # keep going
  } else {
     # Note: prdr wallet does not have an owner, must be validated against peer
     my $rc = run_gpnptool_verifysig( $gpnp_p_peer, $gpnp_wrl_prdr, 
                                      $orauser );
     if ($rc <= 0) {
        $rwallet_ok = FAILED;
        error("chk gpnphome $gpnphome: INVALID (base gpnp config is ok, but ".
              "gpnp config reader wallet is invalid - ".
              "does not verify peer profile signature)");
        # keep going
     }
  }
  if ( $rwallet_ok ) { # if no errors noticed on r/o wallet 
    trace("chk gpnphome $gpnphome: OK");
  }
  # make sure profile permissions are correct, ignore res
  gpnp_wallets_set_ownerperm($islocal);  # error(s) logged 

  return SUCCESS;
}

####---------------------------------------------------------
#### Define and verify GPnP local/cluster-wide gpnp directories 
#### This sub MUST be called before any gpnp setup handling takes place.
# ARGS: 6
# ARG1 : Path for Oracle CRS home
# ARG2 : Path for directory containing gpnp dir with a cluster-wide setup
# ARG3 : Path for directory containing gpnp dir with a local setup
# ARG4 : Hostname, must be given
# ARG5 : OracleOwner user
# ARG6 : OracleDBA group
# @returns SUCCESS or $FAILURE
#
#static
sub verify_gpnp_dirs
{
    my $crshome    = $_[0];
    my $gpnpdir    = $_[1];
    my $gpnplocdir = $_[2];
    my $host       = $_[3];
    my $orauser    = $_[4];
    my $oragroup   = $_[5];

    #-------------
    # Check pars

    if (!$crshome) {
        error ("Empty path specified for Oracle CRS home");
        return FAILED;
    }
    if (!(-d $crshome)) {
        error ("The Oracle CRS home path \"" . $crshome . "\" does not exist");
        return FAILED;
    }
    trace ("Oracle CRS home = " . $crshome);
    if (!$host) {
        error ("Hostname is required for GPnP setup");
        return FAILED;
    }
    trace ("GPnP host = " . $host);

    check_dir( $gpnpdir ) or return FAILED;
    check_dir( $gpnplocdir ) or return FAILED;

    # define package-wide dir names on validated params
    define_gpnp_consts( $crshome, $gpnpdir, $gpnplocdir, $host,
                        $orauser, $oragroup ) 
      or return FAILED;

    trace ("Oracle GPnP home = $GPNP_GPNPHOME_DIR");
    trace ("Oracle GPnP local home = $GPNP_GPNPLOCALHOME_DIR");

    # Check defined const dirs:
    # 1) mandatory
    check_dir( $GPNP_GPNPHOME_DIR ) or return FAILED;
    check_dir( $GPNP_W_PEER_DIR ) or return FAILED;
    check_dir( $GPNP_P_PEER_DIR ) or return FAILED;

    check_dir( $GPNP_GPNPLOCALHOME_DIR ) or return FAILED;
    check_dir( $GPNP_L_W_PEER_DIR ) or return FAILED;
    check_dir( $GPNP_L_P_PEER_DIR ) or return FAILED;

    # 2) optional
    check_dir( $GPNP_W_ROOT_DIR );
    check_dir( $GPNP_W_PA_DIR );
    check_dir( $GPNP_L_W_ROOT_DIR );
    check_dir( $GPNP_L_W_PA_DIR );

    trace("GPnP directories verified. ");
    return SUCCESS;
}

####---------------------------------------------------------
#### Verify GPnP local/cluster-wide file setup (wallet(s)/profiles)
#### Note: verify_gpnp_dirs must be called prior calling this function
# All parameters validated elsewhere
# ARGS: 6
# ARG1 : Path for Oracle CRS home
# ARG2 : Path for directory containing gpnp dir with a cluster-wide setup
# ARG3 : Path for directory containing gpnp dir with a local setup
# ARG4 : Current Hostname
# ARG5 : OracleOwner user
# ARG6 : OracleDBA group
# @returns 
#  GPNP_SETUP_BAD   - if local setup is bad/inconsistent, or error of some
#                      kind occured - local setup must be created
#  GPNP_SETUP_NONE  - if local setup must be created
#  GPNP_SETUP_LOCAL - if local setup already valid, but not cluster-wide
#                      (i.e. there is no cluster-wide setup found;
#                      -x, if succeeded, must push the setup)
#  GPNP_SETUP_GOTCLUSTERWIDE
#                      if local setup is valid, and was just promoted
#                      from a valid cluster-wide setup
#  GPNP_SETUP_CLUSTERWIDE
#                      if local setup is valid, and matches cluster-wide
# 
sub check_gpnp_setup
{
    my $crshome    = $GPNP_CRSHOME_DIR; # validated
    my $gpnpdir    = $GPNP_GPNPHOME_DIR; # validated
    my $gpnplocdir = $GPNP_GPNPLOCALHOME_DIR; # validated
    my $host       = $GPNP_HOST;
    my $orauser    = $GPNP_ORAUSER;
    my $oragroup   = $GPNP_ORAGROUP;

    my $rc      = 0;
    my @program ;

    # 1) Make sure global (seed) and local (node-specific) gpnp dirs
    #    are distinct
    if ($GPNP_GPNPLOCALHOME_DIR eq $GPNP_GPNPHOME_DIR)
    {
      error( "Invalid GPnP home locations: "
            ."cluster-wide \"$GPNP_GPNPHOME_DIR\", "
            ."node-specific \"$GPNP_GPNPLOCALHOME_DIR\". "
            ."Must be different." );
    }
    # 2) check local setup exists and valid
    trace( "---Checking local gpnp setup...");
    my $gpnploc_valid = check_gpnp_home_setup( TRUE );

    # 3) check cluster-wide setup exists and valid
    trace( "---Checking cluster-wide gpnp setup...");
    my $gpnp_valid = check_gpnp_home_setup( FALSE );

    trace( "gpnp setup checked: local valid? $gpnploc_valid ".
           "cluster-wide valid? $gpnp_valid" );

    # 4) see if we can assume cluster-wide setup, return current 
    #    type of gpnpsetup accordingly
    #
    if ( $gpnp_valid && $gpnploc_valid) {

      # if both setups valid, check local setup verifies against
      # cluster-wide wallet (wallet owner or peer)
      $rc = run_gpnptool_verifysig( $GPNP_L_P_PEER_FILE, 
                                    $GPNP_W_PEER_WRL, $orauser );
      if ($rc <= 0) {
        trace("Failed to veirfy a local peer profile \"$GPNP_L_P_PEER_FILE\" ".
              "against cluster-wide wallet \"$GPNP_W_PEER_WRL\" ".
              "rc=$rc (0==invalid,<0==error).\n".
              "Will try to take a cluster-wide setup." );

        # promote cluster-wide setup 
        if (take_clusterwide_gpnp_setup())
        {
          trace( "gpnp setup: GOTCLUSTERWIDE" );
          return GPNP_SETUP_GOTCLUSTERWIDE;
        } 
        else # copy was not successfull - stick with local setup
        { 
          trace( "Failed to copy cluster-wide setup.\n".
                 "gpnp setup: LOCAL" );
          return GPNP_SETUP_LOCAL;
        }
      } else {
          trace( "Local and Cluster-wide setups signed with same wallet.\n".
                 "gpnp setup: CLUSTERWIDE" );
        return GPNP_SETUP_CLUSTERWIDE; # identical setups
      }
    } elsif ( $gpnp_valid ) { # cluster-wide setup only, just try to take that
      if (take_clusterwide_gpnp_setup())
      {
        trace( "gpnp setup: GOTCLUSTERWIDE" );
        return GPNP_SETUP_GOTCLUSTERWIDE;
      } 
      else # copy was not successfull - no good setup or no setup
      { 
        trace( "Failed to copy cluster-wide setup.\n".
               "gpnp setup: BAD" );
        return GPNP_SETUP_BAD;
      }
    } elsif ( $gpnploc_valid ) { # local setup only
      trace( "gpnp setup: LOCAL" );
      return GPNP_SETUP_LOCAL;
    } else {
      trace( "gpnp setup: NONE" );
      return GPNP_SETUP_NONE;
    }  
    return GPNP_SETUP_BAD; # neverreached
}


####---------------------------------------------------------
#### Copy cluster-wide GPnP file setup to be node-local
#### (Copy local wallet(s)/profiles from global stage area on current node)
#
# NOTE:  for use by check_gpnp_setup() 
#
# @returns SUCCESS or $FAILURE
#
#static
sub take_clusterwide_gpnp_setup
{
    my $crshome    = $GPNP_CRSHOME_DIR; # validated
    my $gpnpdir    = $GPNP_GPNPHOME_DIR; # validated
    my $gpnplocdir = $GPNP_GPNPLOCALHOME_DIR; # validated
    my $usr        = $GPNP_ORAUSER;
    my $grp        = $GPNP_ORAGROUP;

    # copy cluster-wide setup files
    trace("Taking cluster-wide setup as local");

    # mandatory
    my $status = 
    copy_file( $GPNP_P_PEER_FILE,  # peer profile
               $GPNP_L_P_PEER_FILE, 
               $usr, $grp );
    if ($status == SUCCESS) { $status = 
    copy_file( $GPNP_WS_PEER_FILE, # peer wallet
               $GPNP_L_WS_PEER_FILE, 
               $usr, $grp ); }

    # optional
    if ($status == SUCCESS) { 
      copy_file( $GPNP_WS_PRDR_FILE, # prdr wallet
                 $GPNP_L_WS_PRDR_FILE, 
                 $usr, $grp ); 

      copy_file( $GPNP_P_SAVE_FILE,  # saved profile
                 $GPNP_L_P_SAVE_FILE, 
                 $usr, $grp ); 

      copy_file( $GPNP_W_ROOT_FILE,  # root wallet
                 $GPNP_L_W_ROOT_FILE, 
                 $usr, $grp );
      copy_file( $GPNP_WS_PA_FILE,   # pa wallet
                 $GPNP_L_WS_PA_FILE, 
                 $usr, $grp );

      copy_file( $GPNP_C_ROOT_FILE,  # root cert
                 $GPNP_L_C_ROOT_FILE, 
                 $usr, $grp );
      copy_file( $GPNP_C_PEER_FILE,  # peer cert
                 $GPNP_L_C_PEER_FILE, 
                 $usr, $grp );
      copy_file( $GPNP_C_PA_FILE,    # pa cert
                 $GPNP_L_C_PA_FILE, 
                 $usr, $grp );

      # Make sure copied local wallet permissions changed, ignore res
      my $islocal = TRUE;
      gpnp_wallets_set_ownerperm( $islocal );  # error(s) logged 

    }    
    unless ($status == SUCCESS) { 
      error( "Failed to take cluster-wide GPnP setup as local" );
    }
    return $status;
}

####---------------------------------------------------------
#### Copy file from local path to remote path for given list of nodes
#### if user given, will run copy as it
#### This routine is gpnp-setup specific.
# ARGS: 4
# ARG1 : Source file name
# ARG2 : Destination remote path
# ARG3 : User-owner
# ARG4 : List of nodes to copy
# @returns SUCCESS or $FAILURE
#
# static
sub copy_gpnpsetup_to_nodes  {
  my $src  = $_[0]; 
  my $dst  = $_[1]; 
  my $user = $_[2]; 
  my $nodelist = $_[3];  # comma-separated scalar list

  my $rc      = 0;
  my @capout  = ();

  if (! (-f $src)) {
     trace("  $src ? -f failed" );
     return FAILED;
  }
  trace("  $src =>  $dst" );
  my @program = ($GPNP_E_GPNPSETUP,
                 '-sourcefile', $src, 
                 '-destfile',   $dst, 
                 '-nodelist',   $nodelist ); 

  # run as specific user, if requested
  trace( '     rmtcpy: '.join(' ', @program) );
  $rc = run_as_user2($user, \@capout, @program);

  # cluutil return 0 err code and errors, if any, on stdout
  if (scalar(@capout) > 0)
  {
    trace( "---rmtcopy { $nodelist } output---\n".join('', @capout));
    trace( "---rmtcopy---." );
  }
  if (0 != $rc) 
  {
     error("Failed to rmtcopy \"$src\" to \"$dst\" ".
           "for nodes {$nodelist}, rc=$rc" ); 
     return FAILED;
  }
  return SUCCESS;
}

####---------------------------------------------------------
#### Push GPnP local file setup to be cluster-wide 
#### (Copy local wallet(s)/profiles to global stage area on current node as well
#### as list of cluster nodes)
#
# NOTE:  check_gpnp_setup() MUST be called prior calling this sub
#
# ARGS: 1
# ARG1 : List of comma-separated cluster node names to push gpnp file setup to
#        (inclusion of current node is ok)
# @returns SUCCESS or $FAILURE
#
sub push_clusterwide_gpnp_setup
{
    my $nodelist   = $_[0];
    my $crshome    = $GPNP_CRSHOME_DIR; # validated
    my $gpnpdir    = $GPNP_GPNPHOME_DIR; # validated
    my $gpnplocdir = $GPNP_GPNPLOCALHOME_DIR; # validated
    my $host       = $GPNP_HOST;
    my $orauser    = $GPNP_ORAUSER;
    my $oragroup   = $GPNP_ORAGROUP;

    # TOBEREVISED - normally, current node is a part of a node list
    #               and cluster-wide setup pushed through localhost rmtcopy
    #               Perhaps current node can be treated specially (order,local)

    $nodelist =~ s/ //g;
    trace("Pushing local gpnpsetup to cluster nodes: {$nodelist}");

    # opt manifest 1st
    my $origout = tmpnam(); # concurrency not an issue here
    open( MFT, ">$origout" ) or # non-fatal
       error "Can't open \"$origout\": $!";

    print MFT "---GPnP cluster-wide configuration---\n";
    print MFT "origin: $host\n";
    print MFT "push_list: {$nodelist}\n";
    print MFT "owner: $GPNP_ORAUSER,".
                         "$GPNP_ORAGROUP\n";
    print MFT "TS: ".gmtime()." UTC (".localtime()." local)\n";
    close( MFT );

    # set MFT owner to orauser, to make sure rmt copy succeeds
    s_set_ownergroup ($orauser, $oragroup, $origout) or # non-fatal
      error( "Can't change ownership on $origout: $!" );

    s_set_perms ("0640", $origout) or # non-fatal
      error( "Can't set permissions on $origout: $!" );

    copy_gpnpsetup_to_nodes( $origout,             # push config manifest
                      $GPNP_ORIGIN_FILE, 
                      $orauser, $nodelist ); 
    unlink($origout);

    # mandatory
    my $status = 
    copy_gpnpsetup_to_nodes( $GPNP_L_P_PEER_FILE,  # peer profile
                      $GPNP_P_PEER_FILE, 
                      $orauser, $nodelist );
    if ($status == SUCCESS) { $status = 
    copy_gpnpsetup_to_nodes( $GPNP_L_WS_PEER_FILE, # peer wallet
                      $GPNP_WS_PEER_FILE, 
                      $orauser, $nodelist ); }

    # optional
    if ($status == SUCCESS) { 
    copy_gpnpsetup_to_nodes( $GPNP_L_P_SAVE_FILE,  # saved profile
                      $GPNP_P_SAVE_FILE, 
                      $orauser, $nodelist ); 

    copy_gpnpsetup_to_nodes( $GPNP_L_W_ROOT_FILE,  # root wallet
                      $GPNP_W_ROOT_FILE, 
                      $orauser, $nodelist );
    copy_gpnpsetup_to_nodes( $GPNP_L_WS_PRDR_FILE, # prdr (r/o) wallet
                      $GPNP_WS_PRDR_FILE, 
                      $orauser, $nodelist ); 
    copy_gpnpsetup_to_nodes( $GPNP_L_WS_PA_FILE,   # pa wallet
                      $GPNP_WS_PA_FILE, 
                      $orauser, $nodelist );

    copy_gpnpsetup_to_nodes( $GPNP_L_C_ROOT_FILE,  # root cert
                      $GPNP_C_ROOT_FILE, 
                      $orauser, $nodelist );
    copy_gpnpsetup_to_nodes( $GPNP_L_C_PEER_FILE,  # peer cert
                      $GPNP_C_PEER_FILE, 
                      $orauser, $nodelist );
    copy_gpnpsetup_to_nodes( $GPNP_L_C_PA_FILE,    # pa cert
                      $GPNP_C_PA_FILE, 
                      $orauser, $nodelist );
    }
    unless ($status == SUCCESS) { 
       print STDERR "rmtcopy aborted\n";
    }
    return $status;
}

####---------------------------------------------------------
#### Create GPnP wallet(s)
# ARGS: 6
# ARG1 : Parameter hash
# ARG2 : Hostname, can be null for non-host specific setup
# ARG3 : Force wallet creation (if FALSE, wallet won't be created if exists)
# @returns SUCCESS or $FAILURE
#
sub create_gpnp_wallets
{
    my $host     = $_[0];
    my $force    = $_[1];

    my $crshome  = $CFG->ORA_CRS_HOME; # validated
    my $gpnpdir  = $CFG->params('GPNPCONFIGDIR'); # validated
    my $orauser  = $CFG->params('ORACLE_OWNER');
    my $oragroup = $CFG->params('ORA_DBA_GROUP');
    my $islocal  = FALSE;

    my $status  = SUCCESS;
    my $rc      = 0;
    my @program ;

    #-------------
    # Check existing setup, if any

    my $GPNPHOME_DIR = catdir( $gpnpdir, 'gpnp' );
    my $WALLETS_DIR =  catdir( $GPNPHOME_DIR, 'wallets' );
    if ($host) {
        $WALLETS_DIR = catdir( $GPNPHOME_DIR, $host, 'wallets' );
        $islocal = TRUE;
    }
    trace ("Oracle CRS home = " . $crshome);
    trace ("Oracle GPnP wallets home = $WALLETS_DIR");

    my $W_ROOT_DIR  = catdir( $WALLETS_DIR, 'root' );
    my $W_PA_DIR    = catdir( $WALLETS_DIR, 'pa' );
    my $W_PEER_DIR  = catdir( $WALLETS_DIR, 'peer' );
    my $W_PRDR_DIR  = catdir( $WALLETS_DIR, 'prdr' );

    my $WALLET_NAME = 'ewallet.p12';
    my $SSOWAL_NAME = 'cwallet.sso';

    my $W_ROOT_FILE = catfile( $W_ROOT_DIR, $WALLET_NAME );
    my $W_PEER_FILE = catfile( $W_PEER_DIR, $SSOWAL_NAME );
    my $W_PRDR_FILE = catfile( $W_PRDR_DIR, $SSOWAL_NAME );
    my $W_PA_FILE   = catfile( $W_PA_DIR,   $SSOWAL_NAME );

    trace ("Checking if GPnP setup exists");
    if (!(-d $W_ROOT_DIR)) {
        error ("The directory \"$W_ROOT_DIR\" does not exist");
        return FAILED;
    }
    if (!(-d $W_PEER_DIR)) {
        error ("The directory \"$W_PEER_DIR\" does not exist");
        return FAILED;
    }
    if (!(-d $W_PRDR_DIR)) {
        error ("The directory \"$W_PRDR_DIR\" does not exist");
        return FAILED;
    }
    if (!(-d $W_PA_DIR)) {
        error ("The directory \"$W_PA_DIR\" does not exist");
        return FAILED;
    }
    if (-f $W_PEER_FILE) {
        trace ("$W_PEER_FILE wallet exists");
        if (! $force)
        {
           trace ("$W_PEER_FILE exists and force is not requested. Done.");
           return SUCCESS;
        }
    }
    trace ("$W_PEER_FILE wallet must be created");

    if (-f $W_PRDR_FILE) {
        trace ("Warning: existing $W_PRDR_FILE wallet will be deleted.");
    }
    if (-f $W_PA_FILE) {
        trace ("Warning: existing $W_PA_FILE wallet will be deleted.");
    }


    #-------------
    # Create wallet(s)

    my $E_ORAPKI    = catfile( $crshome, 'bin', 'orapki' );

    my $CERT_NAME   = 'cert.txt';
    my $CERTRQ_NAME = 'certreq.txt';
    my $RTCERT_NAME = 'b64certificate.txt';
    my $PDUMMY      = 'gpnp_wallet1';

    my $W_ROOT_DN   = '"CN=GPnP_root"';
    my $W_PA_DN     = '"CN=GPnP_pa"';
    my $W_PEER_DN   = '"CN=GPnP_peer"';
    my $W_KEYSZ     = '1024';
    my $W_EXPDT     = '"01/01/2099"';
    my $W_CVALID    = '9999';

    my $CRQ_PA_FILE = catfile( $W_PA_DIR, $CERTRQ_NAME );
    my $CRQ_PEER_FILE = catfile( $W_PEER_DIR, $CERTRQ_NAME );
    my $C_ROOT_FILE = catfile( $W_ROOT_DIR, $RTCERT_NAME );
    my $C_PA_FILE   = catfile( $W_PA_DIR, $CERT_NAME );
    my $C_PEER_FILE = catfile( $W_PEER_DIR, $CERT_NAME );

    trace ("Removing old wallets/certificates, if any");
    unlink ($W_ROOT_FILE, $W_PA_FILE, $W_PEER_FILE, $W_PRDR_FILE,
            $CRQ_PA_FILE, $CRQ_PEER_FILE, 
            $C_ROOT_FILE, $C_PA_FILE, $C_PEER_FILE); 

    #-------------
    # 1.a Create root wallet 
    if (SUCCESS == $status) 
    {
        print( "  root wallet\n" ); #FIXME output from lib breaks conv
        trace( "Creating GPnP Root Wallet..." );
        @program = ( $E_ORAPKI, 'wallet', 'create', 
                     '-wallet', "\"$W_ROOT_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-nologo' ); 
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to create a root wallet for Oracle Cluster GPnP. ".
                 "orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # 1.b Create self-signed root wallet certificate 
    if (SUCCESS == $status) 
    {
        print( "  root wallet cert\n" ); #FIXME output from lib breaks conv
        trace( "Creating GPnP Root Certificate..." );
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_ROOT_DIR\"", 
                     '-pwd', $PDUMMY,
                     '-self_signed',
                     '-dn', $W_ROOT_DN,
                     '-keysize', $W_KEYSZ,
                     '-validity', $W_CVALID, 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to create a root certificate for Oracle Cluster GPnP.".
                 " orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # 1.c Export root wallet certificate 
    if (SUCCESS == $status) 
    {
        print( "  root cert export\n" ); #FIXME output from lib breaks conv
        trace( "Exporting GPnP Root Certificate..." );
        @program = ( $E_ORAPKI, 'wallet', 'export', 
                     '-wallet', "\"$W_ROOT_DIR\"", 
                     '-pwd', $PDUMMY,
                     '-dn', $W_ROOT_DN,
                     '-cert', "\"$C_ROOT_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to export root certificate for Oracle Cluster GPnP. ".
                 "orapki rc=$rc" );
           $status = FAILED;
        }
    }
    #-------------
    # 2. Create empty wallets for peer, prdr & pa (cwallet.sso  ewallet.p12)
    # a) peer
    if (SUCCESS == $status) 
    {
        print( "  peer wallet\n" ); #FIXME output from lib breaks conv
        trace( "Creating GPnP Peer Wallet..." );
        @program = ( $E_ORAPKI, 'wallet', 'create', 
                     '-wallet', "\"$W_PEER_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-auto_login', 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to create a peer wallet for Oracle Cluster GPnP. ".
                 "orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # b) prdr
    if (SUCCESS == $status) 
    {
        print( "  profile reader wallet\n" ); #FIXME output from lib breaks conv
        trace( "Creating GPnP Profile Reader Wallet..." );
        @program = ( $E_ORAPKI, 'wallet', 'create', 
                     '-wallet', "\"$W_PRDR_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-auto_login', 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to create a profile reader wallet for ".
                 "Oracle Cluster GPnP. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # c) pa
    if (SUCCESS == $status) 
    {
        print( "  pa wallet\n" ); #FIXME output from lib breaks conv
        trace( "Creating GPnP PA Wallet..." );
        @program = ( $E_ORAPKI, 'wallet', 'create', 
                     '-wallet', "\"$W_PA_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-auto_login', 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to create a PA wallet for Oracle Cluster GPnP. ".
                 "orapki rc=$rc" );
           $status = FAILED;
        }
    }
    #-------------
    # 3. Add private key to a wallet
    # a) peer
    if (SUCCESS == $status) 
    {
        print( "  peer wallet keys\n" ); #FIXME output from lib breaks conv
        trace("Adding private key to GPnP Peer Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_PEER_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-dn', $W_PEER_DN,
                     '-keysize', $W_KEYSZ, 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a peer wallet for Oracle Cluster GPnP. ".
                 "Cannot add private key to a wallet. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # b) pa
    if (SUCCESS == $status) 
    {
        print( "  pa wallet keys\n" ); #FIXME output from lib breaks conv
        trace("Adding private key to GPnP PA Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_PA_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-dn', $W_PA_DN,
                     '-keysize', $W_KEYSZ, 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a PA wallet for Oracle Cluster GPnP. ".
                 "Cannot add private key to a wallet. orapki rc=$rc" );
           $status = FAILED;
        }
    }

    #-------------
    # 4. Create cert request (B64) for each (certreq.txt)
    # a) peer
    if (SUCCESS == $status) 
    {
        print( "  peer cert request\n" ); #FIXME output from lib breaks conv
        trace("Creating certificate request for GPnP Peer Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'export', 
                     '-wallet', "\"$W_PEER_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-dn', $W_PEER_DN,
                     '-request', "\"$CRQ_PEER_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a peer wallet for Oracle Cluster GPnP. ".
                 "Cannot export a certificate request from a wallet. ".
                 "orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # b) pa
    if (SUCCESS == $status) 
    {
        print( "  pa cert request\n" ); #FIXME output from lib breaks conv
        trace("Creating certificate request for GPnP PA Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'export', 
                     '-wallet', "\"$W_PA_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-dn', $W_PA_DN,
                     '-request', "\"$CRQ_PA_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a PA wallet for Oracle Cluster GPnP. ".
                 "Cannot export a certificate request from a wallet. ".
                 "orapki rc=$rc" );
           $status = FAILED;
        }
    }
    #-------------
    # 5. Create certificate files (B64) for each 
    #    (cert.txt signed with same root wallet (valid 27yrs))
    # a) peer
    if (SUCCESS == $status) 
    {
        print( "  peer cert\n" ); #FIXME output from lib breaks conv
        trace("Creating certificate for GPnP Peer Wallet...");
        @program = ( $E_ORAPKI, 'cert', 'create', 
                     '-wallet', "\"$W_ROOT_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-request', "\"$CRQ_PEER_FILE\"",
                     '-cert', "\"$C_PEER_FILE\"",
                     '-validity', $W_CVALID, 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a peer wallet for Oracle Cluster GPnP. ".
                 "Cannot create a peer certificate. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # b) pa
    if (SUCCESS == $status) 
    {
        print( "  pa cert\n" ); #FIXME output from lib breaks conv
        trace("Creating certificate for GPnP PA Wallet...");
        @program = ( $E_ORAPKI, 'cert', 'create', 
                     '-wallet', "\"$W_ROOT_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-request', "\"$CRQ_PA_FILE\"",
                     '-cert', "\"$C_PA_FILE\"",
                     '-validity', $W_CVALID, 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a PA wallet for Oracle Cluster GPnP. ".
                 "Cannot create a PA certificate. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    #-------------
    # 6. Add root certificate as trusted cert to all user wallets 
    #    (to allow import certificates not only as self-signed)
    # a) peer
    if (SUCCESS == $status) 
    {
        print( "  peer root cert TP\n" ); #FIXME output from lib breaks conv
        trace("Adding Root Certificate TP to GPnP Peer Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_PEER_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-trusted_cert', '-cert', "\"$C_ROOT_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a peer wallet for Oracle Cluster GPnP. ".
                 "Cannot add a root TP certificate. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # b) prdr
    if (SUCCESS == $status) 
    {
        print( "  profile reader root cert TP\n" ); #FIXME output from lib 
        trace("Adding Root Certificate TP to GPnP Profile Reader Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_PRDR_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-trusted_cert', '-cert', "\"$C_ROOT_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a Profile Reader Wallet ".
                 "for Oracle Cluster GPnP. ".
                 "Cannot add a root TP certificate. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # c) pa
    if (SUCCESS == $status) 
    {
        print( "  pa root cert TP\n" ); #FIXME output from lib breaks conv
        trace("Adding Root Certificate TP to GPnP PA Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_PA_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-trusted_cert', '-cert', "\"$C_ROOT_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a PA wallet for Oracle Cluster GPnP. ".
                 "Cannot add a root TP certificate. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    #-------------
    # 7. Add cross certificates as trust points
    # a) peer - add pa
    if (SUCCESS == $status) 
    {
        print( "  peer pa cert TP\n" ); #FIXME output from lib breaks conv
        trace("Adding PA Certificate as a TP into a GPnP Peer Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_PEER_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-trusted_cert', '-cert', "\"$C_PA_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a peer wallet for Oracle Cluster GPnP. ".
                 "Cannot add a PA TP certificate. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # b) pa - add peer
    if (SUCCESS == $status) 
    {
        print( "  pa peer cert TP\n" ); #FIXME output from lib breaks conv
        trace("Adding peer Certificate as a TP into a GPnP PA Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_PA_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-trusted_cert', '-cert', "\"$C_PEER_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a PA wallet for Oracle Cluster GPnP. ".
                 "Cannot add a peer TP certificate. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # c) prdr - add peer
    if (SUCCESS == $status) 
    {
        print( "  profile reader pa cert TP\n" ); #FIXME output from lib 
        trace("Adding PA Certificate as a TP into a GPnP ".
              "Profile Reader Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_PRDR_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-trusted_cert', '-cert', "\"$C_PA_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a Profile Reader Wallet ".
                 "for Oracle Cluster GPnP. ".
                 "Cannot add a PA TP certificate. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # c) prdr - add pa
    if (SUCCESS == $status) 
    {
        print( "  profile reader peer cert TP\n" ); #FIXME output from lib
        trace("Adding peer Certificate as a TP into a GPnP ".
              "Profile Reader Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_PRDR_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-trusted_cert', '-cert', "\"$C_PEER_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a Profile Reader Wallet ".
                 "for Oracle Cluster GPnP. ".
                 "Cannot add a peer TP certificate. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    #-------------
    # 8. Finally, add user certificate to user wallets (to add public key cert)
    # a) peer
    if (SUCCESS == $status) 
    {
        print( "  peer user cert\n" ); #FIXME output from lib breaks conv
        trace("Adding PA Certificate as a TP into a GPnP Peer Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_PEER_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-user_cert', '-cert', "\"$C_PEER_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a peer wallet for Oracle Cluster GPnP. ".
                 "Cannot add a PA TP certificate. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    # b) pa
    if (SUCCESS == $status) 
    {
        print( "  pa user cert\n" ); #FIXME output from lib breaks conv
        trace("Adding peer Certificate as a TP into a GPnP PA Wallet...");
        @program = ( $E_ORAPKI, 'wallet', 'add', 
                     '-wallet', "\"$W_PA_DIR\"", 
                     '-pwd', $PDUMMY, 
                     '-user_cert', '-cert', "\"$C_PA_FILE\"", 
                     '-nologo' );
        trace( join(' ', @program) );
        $rc = system( "@program" );
        if (0 != $rc) {
           error("Failed to make a PA wallet for Oracle Cluster GPnP. ".
                 "Cannot add a peer TP certificate. orapki rc=$rc" );
           $status = FAILED;
        }
    }
    if (SUCCESS == $status) {

        # Delete intermediate files and non-sso wallets
        unlink( $CRQ_PEER_FILE, $CRQ_PA_FILE,
            catfile( $W_PEER_DIR, $WALLET_NAME ),
            catfile( $W_PRDR_DIR, $WALLET_NAME ),
            catfile( $W_PA_DIR, $WALLET_NAME ) );

        # Change file ownership to non-root
        $status = gpnp_wallets_set_ownerperm( $islocal );  # error(s) logged 

    }
    if (SUCCESS == $status) {
        trace ("GPnP Wallets successfully created.");    
    }
    return $status;
}

# set gpnp wallet/certs ownership and permissions
sub gpnp_wallets_set_ownerperm()
{
    my $islocal = $_[0]; # boolean (TRUE  - local home (node-specific), 
                         #          FALSE - global home (seed)
    my $status  = SUCCESS;
    my $haderr  = FALSE;

    my $orauser  = $CFG->params('ORACLE_OWNER');
    my $oragroup = $CFG->params('ORA_DBA_GROUP');

    # file paths are validated
    my $gpnp_c_root;
    my $gpnp_w_root;  
    my $gpnp_c_peer;
    my $gpnp_w_peer;  
    my $gpnp_c_pa;
    my $gpnp_w_pa;  
    my $gpnp_w_prdr;  

    # assign appropriate gpnp home
    if ($islocal) {
       $gpnp_c_root = $GPNP_L_C_ROOT_FILE;
       $gpnp_w_root = $GPNP_L_W_ROOT_FILE;
       $gpnp_c_peer = $GPNP_L_C_PEER_FILE;
       $gpnp_w_peer = $GPNP_L_WS_PEER_FILE;
       $gpnp_c_pa   = $GPNP_L_C_PA_FILE;
       $gpnp_w_pa   = $GPNP_L_WS_PA_FILE;
       $gpnp_w_prdr = $GPNP_L_WS_PRDR_FILE;
    } else {
       $gpnp_c_root = $GPNP_C_ROOT_FILE;
       $gpnp_w_root = $GPNP_W_ROOT_FILE;
       $gpnp_c_peer = $GPNP_C_PEER_FILE;
       $gpnp_w_peer = $GPNP_WS_PEER_FILE;
       $gpnp_c_pa   = $GPNP_C_PA_FILE;
       $gpnp_w_pa   = $GPNP_WS_PA_FILE;
       $gpnp_w_prdr = $GPNP_WS_PRDR_FILE;
    }

    # Change file ownership to non-root
    my @resfiles = ( $gpnp_c_root, $gpnp_w_root, 
                     $gpnp_c_peer, $gpnp_w_peer, $gpnp_w_prdr,
                     $gpnp_c_pa,   $gpnp_w_pa   );
    trace("resfiles are @resfiles");

    foreach (@resfiles) {
       if ($CFG->platform_family eq "windows") {
          my $nt_authority = "NT AUTHORITY\\SYSTEM";
          my $admin = "Administrators";
          if ($DEBUG) {
             trace ("s_set_ownergroup_win ($nt_authority, $admin, $_)");
          }
          if (($status = s_set_ownergroup_win ($nt_authority,
                                               $admin, $_))  != $SUCCESS) {
             error ("Can't set ownership on $_: $!");
             $haderr = TRUE;
          }
       } else {
          # set permissions/owner on wallets/certs
          if (($status = s_set_perms ("700", $_)) != $SUCCESS) {
             error "Can't set permissions on $_: $!";
             $haderr = TRUE;
          }
          if (($status = s_set_ownergroup ($orauser,
                                           $oragroup, $_)) != $SUCCESS) {
             error ("Can't set ownership on $_: $!");
             $haderr = TRUE;
          }
       }
    }
    if ($CFG->platform_family eq "windows") {
    } else {
       # ease permissions/owner on config reader wallet
       if (($status = s_set_perms ("750", $gpnp_w_prdr)) != $SUCCESS) {
          error "Can't set permissions on $gpnp_w_prdr: $!";
          $haderr = TRUE;
       }
    }
    # head out
    if ( $haderr ) {
        error ("Error(s) occurred while setting GPnP Wallets ".
               "ownership/permissions.");    
    } else {
        trace ("GPnP Wallets ownership/permissions successfully set.");    
    }
    return $status;
}

####---------------------------------------------------------
#### Function for returning OCRID 
# ARGS: 1
# ARG1: ORA_CRS_HOME
# @returns ID fetched from  ocrcheck or -1 in case of error
sub get_ocrid
{

   my $crshome = $_[0];
   my $ocrcheck = catfile($crshome, 'bin', 'ocrcheck');
   my $id = -1;

   if ( -x $ocrcheck ) {

     trace("Executing ocrcheck to get ocrid");
     open(OCRCHECK, "$ocrcheck |" );
     my @output = <OCRCHECK>;
     close(OCRCHECK);
     my @txt = grep (/ ID /, @output);
     foreach my $line (@txt) {
       my ($IDSTRING, $oid)  = split(/:/, $line);
       $id = trim($oid);
     }

     $CFG->OCR_ID($id);
   }
   else {
         trace("Error !! Could not execute $ocrcheck ");
   }

   if ($id == -1) {
      trace("get_ocrid : Failed to get ocrid ");
   }
   return $id;

}

####---------------------------------------------------------
#### Function for returning CLUSTER_GUID. 
# 1) First , checks for clusterware active version 
#    NOTE: CFG->oldconfig('ORA_CRS_VERSION') must be set.
# 2) If, version < 11.1.0.7 , returns -1.
# 3) Else, get the clusterguid from "crsctl get css clusterguid".
# ARGS: 1
# ARG1: ORA_CRS_HOME
# @returns ID fetched from  crsctl or -1 in case of error

sub get_clusterguid
{
   my $home = $_[0];
   my $id = -1;

   ## If here , must be 11.1.0.7 and higher
   my @OLD_CRS_VERSION = @{$CFG->oldconfig('ORA_CRS_VERSION')};
   if (($OLD_CRS_VERSION[0]   < 11) ||
       (($OLD_CRS_VERSION[0] == 11) && ($OLD_CRS_VERSION[1] == 1) &&
        ($OLD_CRS_VERSION[2] ==  0) && ($OLD_CRS_VERSION[3]  < 7)))
   {
      trace("Skipping clusterguid fetch for ".join('.',@OLD_CRS_VERSION));
      return -1;
   }
   trace("Fetching clusterguid from ".join('.',@OLD_CRS_VERSION));

   my $cmd;
   if (! defined $home) {
     $cmd = crs_exec_path('crsctl');
   } else {
     $cmd = catfile( $home, 'bin', 'crsctl' );
   }

   # run "crsctl get css clusterguid"
   my @out = system_cmd_capture(($cmd, "get", "css", "clusterguid"));
   my $rc  = shift @out;

   # if succeeded, get the guid, output must be a single line
   if ($rc == 0) {
      my $outid = $out[0];
      $id = trim($outid);
      trace( "Got CSS GUID: $id (".join(' ',@out).")" );
   }
   else
   {
      error ("Retrieval of CSS GUID failed (rc=$rc), ".
             "with the message:\n".join("\n", @out)."\n");
   }

   if ($id == -1) {
      trace("get_clusterguid : Failed to get clusterguid");
   }
   return $id;
}



####---------------------------------------------------------
#### Run gpnptool with options
# ARGS: 3
# ARG1 : ref to array of gpnptool arguments (verb + switches)
# ARG2 : user to run gpnptool as (or undef if don't care)
# ARG3 : if reference to an array var passed, return captured output 
#        (stderr in case of gpnptool) value (strings are "as is", not chomped);
#        if undefined, no capture takes place.
# @returns numeric exit code from gpnptool (0 on success)
#
sub run_gpnptool
{
    my $argsref   = $_[0]; #ref
    my $user      = $_[1];
    my $capoutref = $_[2]; #ref

    my $rc = -1;

    my @program = ($GPNP_E_GPNPTOOL, @{$argsref});

    # run as specific user, if requested
    trace ('gpnptool: run '.join(' ', @program));
    $rc = run_as_user2($user, $capoutref, @program);
    trace ("gpnptool: rc=$rc");
    if (defined($capoutref))
    {
      trace ("gpnptool output:\n".  join('', @{$capoutref}) );
    }
    return $rc;
}

####---------------------------------------------------------
#### Run gpnptool verify for given profile and wallet loc (WRL)
# ARGS: 3
# ARG1 : profile filepath (verified)
# ARG2 : WRL (gpnptool-recognized wallet locator string, e.g. 
#        'file:/mypath/') 
# ARG2 : user to run gpnptool as (or undef if don't care)
# @returns numeric result:
#          <0   error occured
#          ==0  profile signature does not matches against given wallet
#          ==1  profile signature matches against given wallet
#
sub run_gpnptool_verifysig
{
    my $gpnp_p   = $_[0]; # validated
    my $gpnp_wrl = $_[1]; # validated
    my $orauser  = $_[2];

    my @gpnptool_args = ( 'verify', 
                          "-p=\"$gpnp_p\"", 
                          "-w=\"$gpnp_wrl\"",  
                          '-wu=peer'
                        );
    my @gpnptool_out  = ();

    # run gpnptool verify as orauser, capturing stdout/err
    my $rc = run_gpnptool( \@gpnptool_args, $orauser, \@gpnptool_out );
    if (0 != $rc) {
        trace("Failed to verify a \"$gpnp_p\" profile against ".
              "cluster-wide wallet \"$gpnp_wrl\" gpnptool rc=$rc" );
        return -1;
    }
    # TOBEREVISED - gpnptool error code - now suc on invalid sig 
    my $gpnptool_res = join('', @gpnptool_out );
    if ($gpnptool_res =~ m/signature is valid/i) {
        trace("Profile \"$gpnp_p\" signature is VALID ".
              "for wallet \"$gpnp_wrl\"" );
        return 1;
    }
    elsif ($gpnptool_res =~ m/signature is not valid/i) {
        trace("Profile \"$gpnp_p\" signature is INVALID".
              " for wallet \"$gpnp_wrl\"" );
        return 0;
    }
    else {
        error("Profile \"$gpnp_p\" signature verified, ".
              "but no signature status string ".
              "found in \"\n$gpnptool_res\n\"");
        return -2;
    }
    return -1;
}

sub perform_initialize_local_gpnp
{
  my $hostname =   $_[0];
  my $gpnp_setup_type = $_[1];
  my $ckptgpnp;
  my $ckpt = "ROOTCRS_GPNPSETUP";
  if (isCkptexist($ckpt))
  {
    $ckptgpnp = getCkptStatus($ckpt);
    trace("$ckpt state is $ckptgpnp");
    if ($ckptgpnp eq CKPTFAIL) {
       clean_initialize_local_gpnp();
       initialize_local_gpnp($hostname, $gpnp_setup_type);
    } elsif ($ckptgpnp eq CKPTSTART) {
       initialize_local_gpnp($hostname, $gpnp_setup_type);
    } elsif ($ckptgpnp eq CKPTSUC) {
       trace("Local GPNP already initialized");
       return $SUCCESS;
    }
  } else {
      initialize_local_gpnp($hostname, $gpnp_setup_type);
  }
}

sub initialize_local_gpnp
{
  my $hostname =   $_[0];
  my $gpnp_setup_type = $_[1];
  
  my $gpnp_descr = "unknown";
  my $status;
  my $ckpt = "ROOTCRS_GPNPSETUP";
  writeCkpt($ckpt, CKPTSTART);

 SWITCH: {
    $gpnp_setup_type == GPNP_SETUP_BAD  and 
      $gpnp_descr = "dirty", last;
    $gpnp_setup_type == GPNP_SETUP_NONE and
      $gpnp_descr = "none", last;
    $gpnp_setup_type == GPNP_SETUP_LOCAL and 
      $gpnp_descr = "local", last;
    $gpnp_setup_type == GPNP_SETUP_GOTCLUSTERWIDE and 
      $gpnp_descr = "new-cluster-wide", last;
    $gpnp_setup_type == GPNP_SETUP_CLUSTERWIDE and 
      $gpnp_descr = "cluster-wide", last;
    $gpnp_descr = "unknown";        # default case
  }

  trace ("GPnP setup state: $gpnp_descr");
  if ($gpnp_setup_type == GPNP_SETUP_BAD) {
    trace("Forcing re-creation of gpnp setup.");
    $gpnp_setup_type = GPNP_SETUP_NONE;
  }
  # unless GPnP configuration we running is cluster-wide, or on good local 
  # gpnp profile/wallet config, create local setup
  if ($gpnp_setup_type == GPNP_SETUP_GOTCLUSTERWIDE ||
      $gpnp_setup_type == GPNP_SETUP_CLUSTERWIDE) {
    trace("GPnP cluster configuration already performed");
  }
  elsif ($gpnp_setup_type == GPNP_SETUP_LOCAL) {
    trace("GPnP cluster configuration not required for non-clustered ",
          "config");
  }
  elsif ($gpnp_setup_type == GPNP_SETUP_NONE) {
    trace ("Creating local GPnP setup for clustered node...");

   $status =  create_gpnp_wallets($hostname, TRUE );
   if ($status != SUCCESS) {
      error ("Creation of Oracle GPnP peer profile failed for $hostname");
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
   }

    trace ("<--- GPnP wallets successfully created");

    # gpnp: Create gpnp peer profile for host (force) with given pars
    trace ("Creating GPnP peer profile --->");

    $status = create_gpnp_peer_profile($hostname,
                             TRUE, # force (create, not edit)
                             TRUE  # sign with peer wallet
                            );
    if ($status != SUCCESS) {
      error ("Creation of Oracle GPnP peer profile failed for $hostname");
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }
    trace ("<--- GPnP peer profile successfully created");

    trace ("GPnP local setup successfully created\n");
  }
  writeCkpt($ckpt, CKPTSUC);
  return;
}
  ####---------------------------------------------------------
#### Create GPnP peer profile
# ARG1 : Parameter hash
# ARG1 : Hostname, can be null for non-host specific setup
# ARG2 : Force profile creation (if FALSE, won't be created if exists)
# ARG3 : If 1, attempt to sign a profile with a peer wallet
# @returns SUCCESS or $FAILURE
#
sub create_gpnp_peer_profile
{
    my $host     = $_[0];
    my $force    = $_[1];
    my $sign     = $_[2];

    my $status   = SUCCESS;
    my $rc       = 0;
    my @gpnptool_args;
    my @gpnptool_out ;
    my $edit     = FALSE;
    my $verb     = 'create'; 

    my $crshome  = $CFG->ORA_CRS_HOME; # validated
    my $gpnpdir  = $CFG->params('GPNPCONFIGDIR'); # validated
    my $orauser  = $CFG->params('ORACLE_OWNER');
    my $oragroup = $CFG->params('ORA_DBA_GROUP');
    my $p_paloc  = $CFG->params('GPNP_PA');
    my $p_cname  = $CFG->params('CLUSTER_NAME');
    my $p_cssdis = $CFG->VF_DISCOVERY_STRING;
    my $p_cssld  = $CFG->params('CSS_LEASEDURATION');
    my $p_asmdis = $CFG->params('ASM_DISCOVERY_STRING');
    my $p_asmspf = $CFG->params('ASM_SPFILE');
    my $p_ocrid  = $CFG->oldconfig('OCRID');
    my $p_nets   = $CFG->params('NETWORKS');
    my $p_clstid = $CFG->oldconfig('CLUSTER_GUID');

    # if old set of networks defined, use them instead
    my $p_oldnets = $CFG->oldconfig('NETWORKS');
    if ((defined $p_oldnets) && !($p_nets eq $p_oldnets)) {
       $p_nets = $p_oldnets;
    }

    #-------------
    # Check existing setup, if any

    my $GPNPHOME_DIR = catdir( $gpnpdir, 'gpnp' );
    my $PROFILES_DIR;
    if ($host) {
        $PROFILES_DIR = catdir( $GPNPHOME_DIR, $host, 'profiles' );
    } else {
        $PROFILES_DIR = catdir( $GPNPHOME_DIR, 'profiles' );
    }
    trace ("Oracle CRS home = " . $crshome);
    trace ("Oracle GPnP profiles home = $PROFILES_DIR");
    trace ("Oracle GPnP profiles parameters: ");
    trace ("   paloc=$p_paloc=");
    trace ("   cname=$p_cname=");
    trace ("   cssdisco=$p_cssdis=");
    trace ("   cssld=$p_cssld=");
    trace ("   asmdisco=$p_asmdis=");
    trace ("   asmspf=$p_asmspf=");
    trace ("   netlst=$p_nets=");
    trace ("   ocrid=$p_ocrid=");
    trace ("   clusterguid=$p_clstid=");

    my $P_PEER_DIR  = catdir( $PROFILES_DIR, 'peer' );
    my $P_PEER_FILE = catfile( $P_PEER_DIR, 'profile.xml' );
    my $P_SAVE_FILE = catfile( $P_PEER_DIR, 'profile_orig.xml' );

    my $SSOWAL_NAME ;
    my $WALLETS_DIR ;
    my $W_PEER_DIR  ;
    my $W_PEER_FILE ;
    my $W_PEER_WRL  ;

    if (0 != $sign) {
        if ($host) {
           $WALLETS_DIR = catdir( $GPNPHOME_DIR, $host, 'wallets' );
        } else {
           $WALLETS_DIR = catdir( $GPNPHOME_DIR, 'wallets' );
        }
        $SSOWAL_NAME = 'cwallet.sso';
        $W_PEER_DIR  = catdir( $WALLETS_DIR, 'peer' );
        $W_PEER_FILE = catfile( $W_PEER_DIR, $SSOWAL_NAME );
        $W_PEER_WRL  = 'file:'.$W_PEER_DIR;
    }
    trace ("Checking if GPnP setup exists");
    if (0 != $sign) {
        if (!(-d $W_PEER_DIR)) {
           error ("The directory \"$W_PEER_DIR\" does not exist");
           return FAILED;
        }
        if (!(-r $W_PEER_FILE)) {
           error ("The GPnP peer wallet file \"" . $W_PEER_FILE .
               "\" does not exist or is not readable");
           return FAILED;
        }
    }
    if (!(-d $P_PEER_DIR)) {
        error ("The directory \"$P_PEER_DIR\" does not exist");
        return FAILED;
    }
    if (-f $P_PEER_FILE) {
        trace ("$P_PEER_FILE wallet exists");
        if (! $edit) {
           if (! $force)
           {
              trace ("GPnP peer profile \"".$P_PEER_FILE.
                     "\" exists and force is not requested. Done.");
              return SUCCESS;
           }
           unlink ($P_PEER_FILE, $P_SAVE_FILE); 
        }
    } else {
        $edit = FALSE;    
        trace ("$P_PEER_FILE profile must be created");
    }

    #-------------
    # Create/edit profile(s)
    {
      # make sure asmdis is not empty (replace empty value with 
      # a predefined value (see bug 8557547)
      if (!$p_asmdis || $p_asmdis eq "") {
         $p_asmdis = 
            "++no-value-at-profile-creation--never-updated-through-ASM++";
      }

      # convert netinfo into cmdline pars
      my @netprogram =  instlststr_to_gpnptoolargs( $p_nets );

      my @ocridparam;
      if (!$p_ocrid || $p_ocrid == -1) {
         trace("OCRID is not available, hence not set in GPnP Profile");
      }
      else {
         @ocridparam = ('-ocr=ocr', "-ocr:ocr_oid=\"$p_ocrid\"" );
      }
      my @clstidparam;
      if (!$p_clstid || $p_clstid == -1) {
         trace("ClusterGUID is not available, hence not set in GPnP Profile");
      }
      else {
         @clstidparam = ("-prf_cid=\"$p_clstid\"");
      } 
      # cmdline
      $verb = 'edit' if $edit;
      @gpnptool_args = ( $verb, 
                 "-o=\"$P_PEER_FILE\"", '-ovr', 
                 '-prf', 
                      "-prf_sq=1", "-prf_cn=$p_cname", "-prf_pa=\"$p_paloc\"",
                 @netprogram,
                 '-css=css', 
                      "-css:css_dis=\"$p_cssdis\"", "-css:css_ld=$p_cssld",
                 '-asm=asm', 
                      "-asm:asm_dis=\"$p_asmdis\"", "-asm:asm_spf=\"$p_asmspf\""
                ); 

      if ($edit) {
         push(@gpnptool_args, "-p=\"$P_PEER_FILE\"");
      }

      if (@ocridparam) {
         push(@gpnptool_args, @ocridparam);
      }

      if (@clstidparam) {
         push(@gpnptool_args, @clstidparam);
      }

      @gpnptool_out  = () ;

      $rc = run_gpnptool( \@gpnptool_args, $orauser, \@gpnptool_out);
      if (0 != $rc) {
        error("Failed to $verb a peer profile for Oracle Cluster GPnP. ".
              "gpnptool rc=$rc" );
        $status = FAILED;
      } 
    }
    # sign profile if req 
    if ((SUCCESS == $status) && (0 != $sign))
    {
      @gpnptool_args = ( 'sign',
                 "-p=\"$P_PEER_FILE\"", 
                 "-o=\"$P_PEER_FILE\"", '-ovr', 
                 "-w=\"$W_PEER_WRL\"",          
                 '-rmws' # compact; or format, e.g. '-fmt=0,2'
                 );
      @gpnptool_out  = () ;
      $rc = run_gpnptool( \@gpnptool_args, $orauser, \@gpnptool_out);
      if (0 != $rc) {
        error("Failed to sign a peer profile for Oracle Cluster GPnP. ".
              "gpnptool rc=$rc" );
        $status = FAILED;
      } 
    } 
    # save created profile on success
    if (SUCCESS == $status) 
    {
        copy( $P_PEER_FILE, $P_SAVE_FILE ) or # non-fatal
          error("Failed to copy \"$P_PEER_FILE\" to \"$P_SAVE_FILE\": $!");
    }
    # change file ownership to non-root
    if ( -f $P_PEER_FILE )
    {
      if ($DEBUG) 
        { trace ("  s_set_ownergroup($orauser, $oragroup, $P_PEER_FILE)");}
      if (FAILED ==
          ($status = s_set_ownergroup ($orauser, $oragroup, $P_PEER_FILE))) {
          error( "Can't change ownership on $P_PEER_FILE: $!" ); 
      }
    }
    if ( -f $P_SAVE_FILE )
    {
      if ($DEBUG) 
        { trace ("  s_set_ownergroup($orauser, $oragroup, $P_SAVE_FILE)");}

      s_set_ownergroup ($orauser, $oragroup, $P_SAVE_FILE) or # non-fatal
        error( "Can't change ownership on $P_SAVE_FILE: $!" ); 
    }
    # for extra check, verify created peer profile against wallet 
    # after chown
    if ($DEBUG)
    {
      $rc = run_gpnptool_verifysig( $P_PEER_FILE, 
                                    $W_PEER_WRL, $orauser );
      if ($rc <= 0) {
        error("Failed to verify a peer profile \"$P_PEER_FILE\"".
              " with WRL=$W_PEER_WRL. rc=$rc");
        $status = FAILED;
      } 
    }

    if (SUCCESS == $status) {
        trace("GPnP peer profile $verb successfully completed.");        
    }
    return $status;
}
####------ ] GPNP

####---------------------------------------------------------
#### Function for copying onc.config to Oracle 10g home
# ARGS : 1
# ARG1 : Oracle CRS home
sub copyONSConfig
{
    my $crshome = $_[0];

    if (!$crshome) {
        error ("Empty path specified for Oracle CRS home");
        return FAILED;
    }

    if (!(-d $crshome)) {
        error ("The Oracle CRS home path \"" . $crshome . "\" does not exist");
        return FAILED;
    }

    trace ("Oracle CRS home = " . $crshome);
    trace ("Copying ONS config file to 10.2 CRS home");

    my $OLSNODESBIN = catfile ($crshome, "bin", "olsnodes");
    if (-x $OLSNODESBIN) {
        open (OLSNODES, "$OLSNODESBIN -l|");
        my $NODE_NAME = <OLSNODES>;
        close (OLSNODES);
        my $OCRDUMPBIN = catfile ($crshome, "bin", "ocrdump");
        if (-x $OCRDUMPBIN) {
            open (OCRDUMP, "$OCRDUMPBIN -stdout -keyname
                'CRS.CUR.ora!$NODE_NAME!ons.ACTION_SCRIPT'|");
            my @output = <OCRDUMP>;
            close (OCRDUMP);
            my $txt = grep (/ORATEXT/, @output);
            my ($key, $ONS_OH) = split (/:/, $txt);
            $ONS_OH =~ s!/bin/racgwrap!!g;
            $ONS_OH =~ s/^ //g;
            ## checking if ONS resource is configured
            if ($ONS_OH) { 
                ##ONS resource is configured
                my $ONSCONFIG = catfile($ONS_OH, "opmn", "conf", "ons.config");
                my $ONSCONFIG_CH =
                    catfile($ONS_OH, "opmn", "conf", "ons.config");
                if (-f $ONSCONFIG) {
                    ##The ons.config file exists at source location
                    copy ($ONSCONFIG_CH, "$ONSCONFIG_CH.orig");
                    copy ($ONSCONFIG, $ONSCONFIG_CH); 
                    trace ("$ONSCONFIG was copied successfully to " .
                           $ONSCONFIG_CH);
                }
            }
        }
    }

    return SUCCESS;
}

####---------------------------------------------------------
#### Function for creating a directory
# ARGS:
# arg 0 -- directory path to be created
#
# Returns: list of directories -- including intermediate directories -- created
sub create_dir
{
    my $dir_path = $_[0];

    # convert '\' to '/' (for NT)
    $dir_path =~ s!\\!/!g;

    # If dir_path doesn't already exist, create it.
    #
    # If dir_path exists as a symlink, then if the target of the symlink
    # doesn't exist, create the target path.  This is applicable especially
    # to ADE environments where we might already have a symlink pointing to
    # some directory in the has_work/ tree.
    my $link_path;
    if ($link_path = s_isLink ($dir_path)) {
        if ($CFG->DEBUG) {
            trace ("  $dir_path is a SYMLINK to $link_path; changing cwd to " .
                   dirname ($dir_path) . " and resetting DIR_PATH");
        }
        chdir (dirname ($dir_path));
        $dir_path = $link_path;
    }

    my @dirs;

    if (!(-e $dir_path)) {
        if ($CFG->DEBUG) { trace ("  mkpath ($dir_path)");}
        @dirs = mkpath ($dir_path)
                  or die "Can't create $dir_path: $!";
    }

    return @dirs;
}

sub perform_register_service
{
  my $srv = $_[0];
  my $ckptregser;
  my $ckpt = "ROOTCRS_REGOHASD";
  if (isCkptexist($ckpt))
  {
    $ckptregser = getCkptStatus($ckpt);
    trace("$ckpt state is $ckptregser");
    if ($ckptregser eq CKPTFAIL) {
       clean_register_service();
       register_service($srv);
    }  elsif ($ckptregser eq CKPTSTART) {
       register_service($srv);
    } elsif ($ckptregser eq CKPTSUC) {
       trace("$srv already registered");
       return $SUCCESS;
    }
  } else {
      register_service($srv);
  }
}

####---------------------------------------------------------
#### Function for registering daemon/service with init
# ARGS: 1
# ARG1: daemon to be registered
sub register_service
{
    my $srv = $_[0];
    my $status;
    my $ckpt = "ROOTCRS_REGOHASD";
    # call OSD API
    writeCkpt($ckpt,CKPTSTART);
    $status = s_register_service ($srv);
    if ($status == SUCCESS) {
       writeCkpt($ckpt,CKPTSUC);
    } else {
       writeCkpt($ckpt,CKPTFAIL);
    }
    return $status;
}

####---------------------------------------------------------
#### Function for unregistering daemon/service
# ARGS: 1
# ARG1: daemon to be registered
sub unregister_service
{
    my $srv = $_[0];

    # call OSD API
    return s_unregister_service ($srv);
}


sub perform_start_service
{
  my $srv = $_[0];
  my $ckptstrtser;
  my $ckpt = "ROOTCRS_STARTOHASD";
  if (isCkptexist($ckpt))
  {
    $ckptstrtser = getCkptStatus($ckpt);
    trace("$ckpt state is $ckptstrtser");
    if ($ckptstrtser eq CKPTFAIL) {
       clean_start_service();
       start_service($srv);
    }  elsif ($ckptstrtser eq CKPTSTART) {
       start_service($srv);
    } elsif ($ckptstrtser eq CKPTSUC) {
       trace("$srv is already started");
       return $SUCCESS;
    }
  } else {
       start_service($srv);
  }
}

####---------------------------------------------------------
#### Function for starting daemon/service
# ARGS: 2
# ARG1: daemon to be started
# ARG2: user as whom daemon/service needs to be started
sub start_service
{
    my $srv  = $_[0];
    my $user = $_[1];
    my $status;
    my $ckpt = "ROOTCRS_STARTOHASD";
    # call OSD API
    writeCkpt($ckpt,CKPTSTART);
    $status = s_start_service ($srv);
    if ($status == SUCCESS) {
       writeCkpt($ckpt,CKPTSUC);
    } else {
       writeCkpt($ckpt,CKPTFAIL);
    }
    return $status;
}

####---------------------------------------------------------
#### Function for stopping daemon/service
# ARGS: 2
# ARG1: daemon to be stopped
# ARG2: user as whom daemon/service needs to be stopped
sub stop_service
{
    my $srv = $_[0];
    my $user = $_[1];

    return s_stop_service ($srv, $user);
}

####---------------------------------------------------------
#### Function for checking daemon/service
# ARGS: 2
# ARG1: daemon to be checked
# ARG2: num retries
sub check_service
{
    my $srv = $_[0];
    my $retries = $_[1];

    my $srv_running = FALSE;
    my $CRSCTL = crs_exec_path("crsctl");
    my $cmd = "$CRSCTL check $srv";
    my $grep_val;
    my @chk;
    my @cmdout;

    # for OHASD, we need to grep for CRS-4638
    # cannot use grep on Windows, customers are unlikely to have grep
    # on their systems

    # for CRS, we need to grep for CRS-4537
    if ($srv eq "ohasd") {
      $grep_val = "4638";
      $cmd = "$CRSCTL check has";
    } 
    elsif ($srv eq "cluster") {
      my $node  = $CFG->HOST;
      $cmd      = "$CRSCTL check $srv -n $node";
      $grep_val = "4537";
      trace("$cmd");
    }
    elsif ($srv eq "css") {
      $grep_val = "4529";
    } 

    # Wait for srv to start up
    while ($retries && ! $srv_running) {
      @chk = system_cmd_capture($cmd);
      # Return code of command is set on close, so capture now
      my $rc = shift @chk;

      if ($grep_val) { @cmdout = grep(/$grep_val/, @chk); } # for OHASD

      # if scalar(@cmdout) > 0, we found the msg we were looking for
      if (($grep_val && scalar(@cmdout) > 0) ||
          (!$grep_val && $rc == 0)) {
        $srv_running = TRUE;
      }
      else {
        trace ("Checking the status of $srv");
        sleep (5);
        $retries--;
      }
    }

    # perform OSD actions
    s_check_service ($srv, $srv_running);

    return $srv_running;
}

sub start_resource
{
  my $ORA_CRS_HOME = $CFG->ORA_CRS_HOME;
  my $CRSCTL = catfile ($ORA_CRS_HOME, "bin", "crsctl");
  my @cmd = ($CRSCTL, 'start', 'resource', (@_));
  my $success = TRUE;

  my $status = system_cmd(@cmd);
  if ($status != 0) {
    error("Start of resource \"@_\" failed");
    $success = FALSE;
  }
 else {
  trace("Start of resource \"@_\" Succeeded");
  }
  return $success;
}

sub stop_resource
{
  my $ORA_CRS_HOME = $CFG->ORA_CRS_HOME;
  my $CRSCTL = catfile ($ORA_CRS_HOME, "bin", "crsctl");
  my @cmd = ($CRSCTL, 'stop', 'resource', (@_));
  my $success = TRUE;

  my $status = system_cmd(@cmd);
  if ($status != 0) {
    error("Stop of resource \"@_\" failed");
    $success = FALSE;
  }

  return $success;
}

sub stop_diskmon
{
  my $ORA_CRS_HOME = $CFG->ORA_CRS_HOME;
  my $CRSCTL = catfile ($ORA_CRS_HOME, "bin", "crsctl");
  my $success = TRUE;

  # no diskmon in windows
  if ($CFG->platform_family eq "windows")
  {
      return TRUE;
  }

  my @output = system_cmd_capture($CRSCTL,
                                  "stop",
                                  "resource",
                                  "ora.diskmon",
                                  "-init");
  my $status = shift @output;

  if ($status != 0 && !scalar(grep(/CRS\-2500/, @output)))
  {
      error("Stop of resource \"ora.diskmon\" failed\n".join("\n", @output));
      $success = FALSE;
  }

  return $success;
}

sub local_only_config_exists {
  my $found      = FALSE;
  my $local_only = s_get_config_key("ocr", "local_only");
  my $ocrcfg_loc = s_get_config_key("ocr", "ocrconfig_loc");
  my $db_home    = "";

  if ($local_only =~ m/true/i) {
     $CFG->oldconfig('OCRCONFIG', $ocrcfg_loc);

     # get older version DBHOME path
    if ($ocrcfg_loc =~ m/(.+).cdata.localhost.local.ocr/) {
       $db_home = $1;
       if ($db_home) {
          $CFG->oldconfig('DB_HOME', $db_home);
          $found = TRUE;
          trace ("local_only config exists");
       }
       else {
          error ("Failed to find earlier version DBHOME");
       }
    }
    else {
       error ("OCR location file /etc/oracle/ocr.loc is corrupted.\n" .
              "If this is a fresh install, ensure that /etc/oracle is empty");
    }
  }

  return $found;
}

####---------------------------------------------------------
#### Function name : migrate_dbhome_to_SIHA
# ARGS 0:
# This routine does the operations in the following sequence.
# 1) Take a backup copy of older ocr file.
# 2) Update the location of ocr.loc
# 3) touch and change file permissions.
# 4) Create necessary configuration with 'crsctl pin css' command.

sub migrate_dbhome_to_SIHA {
  my $db_home;
  my $ret = FAILED;
  my $status;
  my $OCRCONFIGBIN = crs_exec_path("ocrconfig");
  my $CRSCTLBIN = crs_exec_path("crsctl");
  my $HOST = tolower_host ();
  my $ORACLE_OWNER = $CFG->params('ORACLE_OWNER');
  my $ORA_DBA_GROUP = $CFG->params('ORA_DBA_GROUP');
  $ENV{'NLS_LANG'} = $CFG->params('LANGUAGE_ID');

  my $ocrcfg_loc = $CFG->oldconfig('OCRCONFIG');
  my $copy_lococr = "$ORACLE_HOME/cdata/localhost/localsiasm.ocr";
  my $new_lococr = "$ORACLE_HOME/cdata/localhost/local.ocr";

  # copy over older local-only OCR to SIHA home
  if (defined $ocrcfg_loc) {
     if (copy_file ($ocrcfg_loc, $copy_lococr) != SUCCESS) {
        error ("Copy of older local-only OCR failed");
     }
  }

  # Now touch, set owner and perm
  if (!(-e $new_lococr)) {
    if ($CFG->DEBUG) { trace ("Creating empty file $new_lococr");}
    # create an empty file
    open (FILEHDL, ">$new_lococr") or die "Can't create $new_lococr: $!";
    close (FILEHDL);
  }
  # Set ownership/group
  if ($CFG->DEBUG) {
    trace ("s_set_ownergroup ($ORACLE_OWNER, $ORA_DBA_GROUP, $new_lococr)");
  }
  s_set_ownergroup ($ORACLE_OWNER, $ORA_DBA_GROUP, $new_lococr)
    or die "Can't set ownership on $new_lococr: $!";

  # Set permissions, if specified
  s_set_perms ("0640", $new_lococr)
    or die "Can't set permissions on $new_lococr: $!";

  # update ocr.loc
  if (defined $ocrcfg_loc) {
     if (0 !=  system_cmd($OCRCONFIGBIN, '-repair',
                                         '-replace', $ocrcfg_loc,
                                         '-replacement', $new_lococr)) {
        error("Replace of older local-only OCR failed");
     }
  }

  # Now create necessary configuration with 'crsctl pin css ...'
  # This will create the same configuration as 'clscfg -local -install
  $status = system_cmd("$CRSCTLBIN pin css -n $HOST");
  if (0 != $status) {
    error("Error creating local-only OCR ");
  }
  else { $ret = SUCCESS; }

  return $ret;

}

sub local_only_stack_active {
  my $restart_css = FALSE;
    # check if older version SI CSS is running
  my $OLD_CRSCTL = catfile ($CFG->oldconfig('DB_HOME'), "bin", "crsctl");
  my $status = system ("$OLD_CRSCTL check css");

  if (0 == $status) {
    # set flag to restart SIHA CSS before we're done
    $restart_css = TRUE;
  }

  return $restart_css;
}

sub stop_local_only_stack {
  my $stack_stopped = SUCCESS;
  my $status;
  my $OLD_SIHOME = $CFG->oldconfig('DB_HOME');

  #Bug 8280425. Take a backup of ocr.loc and local.ocr
  #before invoking localconfig -delete
  my $newocr_loc     = catfile ($OCRCONFIGDIR, 'ocr.loc');
  my $savenewocr_loc = catfile ($OCRCONFIGDIR, 'ocr.loc.save');
  my $newlococr      = catfile ($OLD_SIHOME, 'cdata', 'localhost', 'local.ocr');
  my $savenewlococr  = catfile ($OLD_SIHOME, 'cdata', 'localhost', 'local.ocr.save');

  trace("backing up  $newocr_loc");
  if (copy_file ($newocr_loc, $savenewocr_loc) != SUCCESS) {
    error ("backup of $newocr_loc failed");
  }
  trace("backing up $newlococr");
  if (copy_file ($newlococr, $savenewlococr) != SUCCESS) {
    error ("backup of $newlococr failed");
  }

  trace ("Stopping older version SI CSS");
  # stop old SI CSS
  my $OLD_LOCALCONFIGBIN = catfile ($CFG->oldconfig('DB_HOME'),
                                    "bin", "localconfig");
  $status = system ("$OLD_LOCALCONFIGBIN delete");
  if ($status == 0) {
    trace ("Older version SI CSS successfully stopped/deconfigured");
  }
  else {
    $stack_stopped = FAILED;
    error ("Failed to stop/deconfigure older version SI CSS");
  }

  #Bug 8280425
  #localconfig -delete removes the ocr.loc and local.ocr
  #restore the same.
  trace("Restoring $newocr_loc");
  if (copy_file ($savenewocr_loc, $newocr_loc) != SUCCESS) {
    error ("Restore of older $newocr_loc failed");
  }

  trace("Restoring $newlococr");
  if (copy_file ($savenewlococr, $newlococr ) != SUCCESS) {
    error ("Restore of $newlococr failed");
  }
   s_set_ownergroup ($ORACLE_OWNER, $ORA_DBA_GROUP, $newocr_loc)
               or die "Can't change ownership on $newocr_loc: $!";

   s_set_ownergroup ($ORACLE_OWNER, $ORA_DBA_GROUP, $newlococr)
               or die "Can't change ownership on $newlococr: $!";

  return $stack_stopped;
}

#
## The following APIs have been pulled in from crsconfig_util.pm
#

sub source_file
{
    my $file = $_[0];

    open (SRCFILE, $file) or die "Couldn't open $file: $!";
    my $contents = join "", <SRCFILE>;
    close SRCFILE;

    eval $contents;
    die "Couldn't eval $file: $@\n" if $@;
}

sub read_file
{
    my $file = $_[0];
    open (FILE, "<$file") or die "Can't open $file: $!";
    my @contents = (<FILE>);
    close (FILE);

    return @contents;
}

# ARGS
# ARG 0: paramfile
sub setup_param_vars
{
    my $paramfile = $_[0];

    # To support the use of 'strict', it is necessary to create a small
    # program to be executed via 'eval'
    # Because 'strict' requires all variables to be declared, the scope
    # of 'my' variables is the program, and variables that are defined
    # by the parameter file are used in the definition of subsequent
    # parameter file entries, e.g. DIRPREFIX, to get the scoping right
    # it is necessary to create a program that will allow previously
    # defined values
    my @epgm;
    open(PARAMFILE, $paramfile) or die "Cannot open $paramfile: $!";

    while (<PARAMFILE>) {
        if ($_ !~ /^#|^\s*$/) {
            # The magic below takes params of the form KEY=VAL and sets them as
            # variables in the perl context
            chomp;
            $_ = trim ($_);
            my ($key, $val) = split ('=');

            # store this in a hash that is returned
            if ((0 > index($val,'"')) && $key ne 'ASM_DISK_GROUP') {
              # escape \ (for NT)
              $val =~ s!\\!\\\\!g;
              push @epgm, "my \$$key=\"$val\";";
            } else { # won't allow perl var subst
              push @epgm, "my \$$key='$val';";
            }
            push @epgm, '$CFG->params(', "'$key',\$$key);";
        }
    }
    close (PARAMFILE);
    eval("@epgm");

    # if there was an error log it
    if ($@) { trace($@); }

    return;
}

# ARGS
# none
sub instantiate_config_params
{
    # If it contains a pattern of the form '%foo%' AND a mapping exists
    # for 'foo', replace '%foo%' with the corresponding value.
    my $rexp="[a-zA-Z_]+";
    foreach (@_) {
      my @matchlist = $_ =~ /%(${rexp})%/g;
      foreach my $match (@matchlist) {
        if (defined($CFG->config_value($match))) {
          my $sub = $CFG->config_value($match);
          $_ =~ s/%(${match})%/$sub/g;
        }
        elsif ($CFG->defined_param($match)) {
          my $sub = $CFG->params($match);
          $_ =~ s/%(${match})%/$sub/g;
        }
      }
      @matchlist = $_ =~ /\$(${rexp})/g;
      foreach my $match (@matchlist) {
        if ($CFG->config_value($match)) {
          my $sub = $CFG->config_value($match);
          $_ =~ s/\$(${match})/$sub/g;
        }
        elsif ($CFG->defined_param($match)) {
          my $sub = $CFG->params($match);
          $_ =~ s/\$(${match})/$sub/g;
        }
      }
    }
}

# ARGS
# none
sub instantiate_scripts
{
    #
    # Script instantiation module
    #
    # Instantiate all files in $CH/crs/sbs/ directory -- replace %FOO%
    # with value for FOO (obtained from crsconfig_params) -- and place
    # this in $CH/crs/utl/ directory
    my $ORA_CRS_HOME = $CFG->ORA_CRS_HOME;
    my $sbsdir   = catfile ($ORA_CRS_HOME, "crs", "sbs");
    my @sbsfiles = glob (catfile ($sbsdir, "*.sbs"));

    $wrapdir_crs = catfile ($ORA_CRS_HOME, "crs", "utl");

    # create $wrapdir_crs if it doesn't exist already
    create_dir ($wrapdir_crs);

    foreach my $srcfile (@sbsfiles) {
        my @sbsfile = read_file ($srcfile);

        # strip off .sbs suffix
        (my $dstfile = basename ($srcfile)) =~ s/\.sbs//g;
        my $dstpath = catfile ($wrapdir_crs, $dstfile);
        if ($DEBUG) { trace ("SRC FILE: $srcfile; DST PATH: $dstpath");}

        open (DSTPATH, ">${dstpath}")
            or die "Can't open $dstpath: $!";

        foreach my $line (@sbsfile) {
            # skip blanks and comments
            if ($line !~ /^#|^\s*$/) {
                instantiate_config_params ($line);
            }
            print DSTPATH "$line";
        }

        close (DSTPATH);
    }
}

# ARGS
# none
sub create_dirs
{
    #
    # Directories Creation module
    #
    # Create directories with ownership/permissions as specified in
    # crs/utl/crsconfig_dirs
    #

    my @dcfile = read_file (catfile ($wrapdir_crs, "crsconfig_dirs"));
    foreach my $line (@dcfile) {
        chomp ($line);
        next if ($line =~ /^#|^\s*$/);  # skip blanks and comments
        # replace variables in input line
        my @matches = $line =~ /(\$\w+)/g;
        for my $match (@matches) {
          if (defined($CFG->config_value($match))) {
            my $sub = $CFG->config_value($match);
            $line =~ s/${match}/$sub/g;
          } elsif ($CFG->defined_param($match)) {
            my $sub = $CFG->params($match);
            $line =~ s/${match}/$sub/g;
          }
        }

        if ($DEBUG) { trace ("crsconfig_dirs: LINE is $line");}
        my ($platform, $dir_path, $owner, $grp, $perms) = split (/ /, $line);

        my $myplatformfamily = s_get_platform_family ();
        $myplatformfamily =~ tr/A-Z/a-z/;

        if (($platform eq "all") || ($platform =~ m/$myplatformfamily/)) {

            my @dirs_created = create_dir ($dir_path);

            # if no dir was created, add dir_path to list to set ownership/perms
            # below
            if (!@dirs_created)
            {
                if ($DEBUG) {
                    trace ("  no dir created; adding $dir_path to list");
                }
                push (@dirs_created, $dir_path);
            }

            # Setting same ownership/permissions for all intermediate dirs
            # as well
            if (@dirs_created) {
                foreach my $dir (@dirs_created) {
                    if ($DEBUG) {
                        trace ("  s_set_ownergroup ($owner, $grp, $dir)");
                    }
                    s_set_ownergroup ($owner, $grp, $dir)
                        or die "Can't change ownership on $dir: $!";
                    if ($perms) {
                        if ($DEBUG) {trace ("  s_set_perms ($perms, $dir)");}
                        s_set_perms ($perms, $dir)
                            or die "Can't set permissions on $dir: $!";
                    }
                }
            }

        }
    }
}

# ARGS
# none
sub copy_wrapper_scripts
{
    #
    # Wrapper copy module
    #
    # Copy files from SOURCE to DEST as specified in
    # crs/utl/crsconfig_files
    #
    my @wcfile = read_file (catfile ($wrapdir_crs, "crsconfig_files"));
    foreach my $line (@wcfile) {
        chomp ($line);
        next if ($line =~ /^#|^\s*$/);  # skip blanks and comments
        my ($platform, $src, $dst) = split (/ /, $line);

        my $myplatformfamily = s_get_platform_family ();
        $myplatformfamily =~ tr/A-Z/a-z/;

        if (($platform eq "all") || ($platform =~ m/$myplatformfamily/)) {
            # If the dest file already exists, first remove it
            if (-e $dst) {
                if ($DEBUG) { trace ("unlink ($dst)");}
                unlink ($dst) or error ("Can't delete $dst: $!");
            }
            if ($DEBUG) { trace ("copy ($src, $dst)");}
            copy($src, $dst) or error ("Can't copy $src to $dst: $!");
        }
    }
}

# ARGS
# arg 0 -- param hash
sub set_file_perms
{
  my $SUPERUSER = $CFG->SUPERUSER;
    #
    # File permissions module
    #
    # Set ownership/permissions as specified in
    # crs/utl/crsconfig_fileperms (after touching the file, if
    # required)
    #
    my $myplatformfamily = s_get_platform_family ();
    $myplatformfamily =~ tr/A-Z/a-z/;

    my @fpfile = read_file (catfile ($wrapdir_crs, "crsconfig_fileperms"));
    my ($file_name, $bin_file);

    foreach my $line (@fpfile) {
        chomp ($line);
        next if ($line =~ /^#|^\s*$/);  # skip blanks and comments

        # replace variables in input line
        $line =~ s/(\$\w+)/$1/eeg;
        if ($DEBUG) { trace ("crsconfig_fileperms: LINE is $line");}

        my ($platform, $file_path, $owner, $grp, $perms) = split (/ /, $line);
        if (($platform eq "all") || ($platform =~ m/$myplatformfamily/)) {
            if (!(-e $file_path)) {
                if ($CFG->DEBUG) { trace ("Creating empty file $file_path");}
                # create an empty file
                open (FILEHDL, ">$file_path") or die "Can't create $file_path: $!";
                close (FILEHDL);
            }

            # Set ownership/group
            if ($CFG->DEBUG) {
              trace ("s_set_ownergroup ($owner, $grp, $file_path)");
            }

            $file_name = basename($file_path);

            if (($file_name =~ /.bin/) && ($owner eq $CFG->HAS_USER)) {
               $bin_file = TRUE;
            }
            else {
               $bin_file = FALSE;
            }

            if ($bin_file && is_dev_env()) {
               trace("Development env... Not setting permissions on $file_name");
            }
            else {
               # Set ownership/group
               s_set_ownergroup ($owner, $grp, $file_path)
                    or die "Can't set ownership on $file_path: $!";

               # Set permissions, if specified
               if ($perms) {
                  if ($CFG->DEBUG) { trace ("s_set_perms ($perms, $file_path)");}
                  s_set_perms ($perms, $file_path)
                        or die "Can't set permissions on $file_path: $!";
               }
            }
        }
    }

   if (! is_dev_env() && (! $CFG->IS_SIHA)) {
      if ($myplatformfamily eq "unix") {
         # Set owner/group of ORA_CRS_HOME and its parent dir to root/dba
         s_setParentDirOwner ($SUPERUSER, $ORA_CRS_HOME);

         if (! $CFG->ASM_STORAGE_USED) {
	    # in an upgrade, OCR_LOCATIONS would be empty.  
	    if ($CFG->UPGRADE) {
	       my $ocrconfig_loc = s_get_config_key('ocr', 'ocrconfig_loc');
	       my $ocrmirror_loc = s_get_config_key('ocr', 'ocrmirrorconfig_loc');
	       trace ("ocrconfig_loc=$ocrconfig_loc");
	       trace ("ocrmirror_loc=$ocrmirror_loc");
	       if ($ocrconfig_loc) {
	          # check if it's a symbolic link
	          if (-l $ocrconfig_loc) {
		     my $ocr_loc = readlink($ocrconfig_loc);
		     s_setParentDirOwner ($SUPERUSER, $ocr_loc);
		  }
		  else {
		     s_setParentDirOwner ($SUPERUSER, $ocrconfig_loc);
	          }
	       }

	       if ($ocrmirror_loc) {
	          if (-l $ocrmirror_loc) {
		     my $mirror_loc = readlink($ocrmirror_loc);
		     s_setParentDirOwner ($SUPERUSER, $mirror_loc);
		  }
		  else {
		     s_setParentDirOwner ($SUPERUSER, $ocrmirror_loc);
	          }
	       }
	    }
	    else {
	       my @ocr_locs = split (/\s*,\s*/, $CFG->params('OCR_LOCATIONS'));
               foreach my $loc (@ocr_locs) {
		  # Set owner/group of OCR path to root/dba
		  trace ("set owner/group of OCR path");
		  s_setParentDirOwner ($SUPERUSER, $loc);
               }
            }
         }
      }
   }
}


# ARGS
# none
sub add_RCALLDIR_to_dirs
{
  my $SUPERUSER = $CFG->SUPERUSER;
    my $dirsfile = catfile ($wrapdir_crs, "crsconfig_dirs");
    open (DIRSFILE, ">>$dirsfile")
        or die "Can't open $dirsfile for append: $!";

    my $myplatformfamily = s_get_platform_family ();
    $myplatformfamily =~ tr/A-Z/a-z/;

    # add RCALLDIR locations to crsconfig_dirs
    my @RCALLDIRLIST = split (/ /, $RCALLDIR);
    foreach my $rc (@RCALLDIRLIST) {
        print DIRSFILE "$myplatformfamily $rc $SUPERUSER $SUPERUSER 0755\n";
    }

    close (DIRSFILE);
}

sub add_ITDIR_to_dirs
#---------------------------------------------------------------------
# Function: add IT_DIR directory to crsconfig_dirs
# Args    : none
#---------------------------------------------------------------------
{
   if ($CFG->defined_param('IT_DIR')) {
      if (is_dev_env()) {
	 my $itdir     = $CFG->params('IT_DIR');
         my $SUPERUSER = $CFG->SUPERUSER;
         my $dirsfile  = catfile ($wrapdir_crs, 'crsconfig_dirs');
         my $platform  = s_get_platform_family();

         open (DIRSFILE, ">>$dirsfile")
              or die "Can't open $dirsfile for append: $!";
         print DIRSFILE "$platform $itdir $SUPERUSER $SUPERUSER 0755\n";
         close (DIRSFILE);
      }
   }
}

sub add_olr_ocr_vdisk_locs
#---------------------------------------------------------------------
# Function: add OCR & OLR to crsconfig_dirs and crsconfig_fileperms
#           files
#
# Args    : none
#---------------------------------------------------------------------
{
   my $IS_SIHA       = $CFG->IS_SIHA;
   my $SUPERUSER     = $CFG->SUPERUSER;
   my $ORACLE_OWNER  = $CFG->params('ORACLE_OWNER');
   my $ORA_DBA_GROUP = $CFG->params('ORA_DBA_GROUP');
   my $OCRCONFIG;
   my $OLRCONFIG;

   my $myplatformfamily = s_get_platform_family ();

   if ($myplatformfamily eq "unix") {
      $OCRCONFIG = $CFG->params('OCRCONFIG');
      $OLRCONFIG = $CFG->params('OLRCONFIG');
   }

   # open crsconfig_fileperms
   my $permsfile = catfile ($wrapdir_crs, "crsconfig_fileperms");
   open (FPFILE, ">>$permsfile")
        or die "Can't open $permsfile for append: $!";

   # open crsconfig_dirs
   my $dirsfile = catfile ($wrapdir_crs, "crsconfig_dirs");
   open (DIRSFILE, ">>$dirsfile")
        or die "Can't open $dirsfile for append: $!";

   # add OLRCONFIG and OLR_LOCATION
   if ($OLRCONFIG) {
      if (is_dev_env()) {
         print FPFILE "$myplatformfamily $OLRCONFIG " . 
		      "$ORACLE_OWNER $ORA_DBA_GROUP 0644\n";
      } else {
         print FPFILE "$myplatformfamily $OLRCONFIG " .
		      "$SUPERUSER $ORA_DBA_GROUP 0644\n";
      }
   }

   print FPFILE
         "$myplatformfamily $OLR_LOCATION $ORACLE_OWNER $ORA_DBA_GROUP 0600\n";

   # add OCRCONFIG, OCR_LOCATION and OCR_MIRROR_LOCATION
   if (! $IS_SIHA)
   {
      if ($OCRCONFIG)
      {
         print FPFILE
               "$myplatformfamily $OCRCONFIG $SUPERUSER " .
                "$ORA_DBA_GROUP 0644\n";
      }
      # OCR permissions need to change to 0600 when CSSD dependency on OCR
      # goes away. Bypass if ASM is used.

      if (!$CFG->ASM_STORAGE_USED)
      {
         my @ocr_locs = split (/\s*,\s*/, $OCR_LOCATIONS);
         foreach my $loc (@ocr_locs)
         {
           print FPFILE "$myplatformfamily $loc $SUPERUSER $ORA_DBA_GROUP 0640\n";
           # set owner and permission of OCR directory by adding to 
           # crsconfig_dirs
           my @dirs;
           if ($myplatformfamily eq "windows") {
             @dirs = split (/\\/, $loc);
           } else {
             # other platforms
             @dirs = split (/\//, $loc);
           }

           my $nbr_of_levels = scalar (@dirs);
           # $nbr_of_levels = 2 means it's at the root directory (exp: R:\ocr).
           # Therefore, no need to add to crsconfig_dirs 
           if ($nbr_of_levels > 2 ) {
             my ($dir) = split ($dirs[$nbr_of_levels-1], $loc);
             print DIRSFILE "$myplatformfamily $dir $ORACLE_OWNER $ORA_DBA_GROUP 0755\n";
           }
         }
      }
   }

   # add all voting disks.  Bypass if ASM is used.
   # XXX: is this step required? Existing shell scripts don't seem to be
   # using validate_VDisks() function
   if (!$CFG->ASM_STORAGE_USED)
   {
      my @votingdisks = split (/\s*,\s*/, $VOTING_DISKS);
      foreach my $vdisk (@votingdisks)
      {
         # voting disk should not be precreated since the startup script may
         # be run as a different user than crs user. Precreating/touching
         # a voting disk prematurely will cause later I/Os to fail, such as
         # voting file upgrade/create

         # set owner and permission of votind disks directory by adding to
         # crsconfig_dirs
         my @dirs;
         if ($myplatformfamily eq "windows") {
            @dirs = split (/\\/, $vdisk);
         }
         else {
            # other platforms
            @dirs = split (/\//, $vdisk);
         }

         my $nbr_of_levels = scalar (@dirs);
         # $nbr_of_levels = 2 means it's at the root directory (exp: R:\vdisk).
         # Therefore, no need to add to crsconfig_dirs 
         if ($nbr_of_levels > 2 ) {
            my ($dir) = split ($dirs[$nbr_of_levels-1], $vdisk);
            print DIRSFILE
                  "$myplatformfamily $dir $ORACLE_OWNER $ORA_DBA_GROUP 0755\n";
         }
      }
   }

   # add OCRCONFIGDIR and OLRCONFIGDIR to crsconfig_dirs
   my $owner;
   if (is_dev_env()) {
      $owner = $ORACLE_OWNER;
   } else {
      $owner = $SUPERUSER;
   }

   if ($OCRCONFIGDIR) {
      print DIRSFILE "$myplatformfamily $OCRCONFIGDIR " .
                     "$owner $ORA_DBA_GROUP 0755\n";
   }

   if (($OLRCONFIGDIR) && ($OLRCONFIGDIR ne $OCRCONFIGDIR)) {
      print DIRSFILE "$myplatformfamily $OLRCONFIGDIR " .
                     "$owner $ORA_DBA_GROUP 0755\n";
   }

   # close files
   close (FPFILE);
   close (DIRSFILE);
}

sub isFirstNodeToStart 
######################################################################
# Returns:
#   FALSE   if node is not first to start
#   TRUE    if node is     first to start
######################################################################
{
   my $isFirst = FALSE;

   # Get the list of nodes that have started
   my $olsnodes = catfile($ENV{'ORA_CRS_HOME'}, 'bin', 'olsnodes');
   open ON, "$olsnodes |";
   my @olsnodes = (<ON>);
   close ON;

   chomp @olsnodes;

   if (scalar(@olsnodes) == 1)
   {
      $isFirst = TRUE;
   }

   return $isFirst;
}

# Arguments:
#   0. Name of host to check
#   1. List of nodes in config
#
# Returns:
#   FALSE   if node is not last to start
#   TRUE    if node is     last to start
sub isLastNodeToStart {
  my $nodelst   = $_[1];
  my $hostname  = $_[0];
  my $isLast = FALSE;
  my $lastnode = 0;
  my %nodes;

  my @nodelist = split(',', $nodelst);

  # Get the list of nodes that have started
  my $olsnodes = catfile($ENV{'ORA_CRS_HOME'}, 'bin', 'olsnodes');
  open ON, "$olsnodes -n|";
  my @olsnodes = (<ON>);
  close ON;

  chomp @olsnodes;

  # If all of the nodes in the configuration are up, find out if
  # we are the last node in the list
  #
  # There are 2 'special' cases to consider.
  #  Node numbers starting from 0 (numbers hould start from 1 soon
  #  Leases are not sequential (some lease slots not taken)
  # For these cases, we want to identify the highest node number
  # in use and select that node as the last node to start
  if (scalar(@nodelist) == scalar(@olsnodes)) {
    my ($nodename, $nodenum);

    # Create a hash with key of node number, value of hostname
    %nodes = map { ($nodename, $nodenum) = (split(' ', $_));
                   if ($nodenum > $lastnode) {
                     $lastnode = $nodenum;
                   }
                   # Get the highest node number of nodes started
                   $nodenum => $nodename;
                 } @olsnodes;
    if ($hostname =~ /$nodes{$lastnode}/i) {
       $isLast = TRUE;
       trace "Host $hostname is the last node to start";
    }
  }

  return $isLast;
}

sub isLastNodeToUpgrade
{
   trace ("isLastNodeToUpgrade...");

   my $lastnode_to_upgrade = TRUE;
   my $crsctl = catfile ($CFG->params('ORACLE_HOME'), "bin", "crsctl");

   # get current releaseversion
   open (QUERYCRS, "$crsctl query crs releaseversion |");
   my $output = <QUERYCRS>;
   close (QUERYCRS);

   my $release_version = getVerInfo($output);

   trace ("release_version=$release_version");

   # get current softwareversion
   my @nodes = split (/,/, $CFG->params('NODE_NAME_LIST'));
   my $software_version;

   foreach my $nodename (@nodes) {
      open (QUERYCRS, "$crsctl query crs softwareversion $nodename |");
      $output = <QUERYCRS>;
      close (QUERYCRS);

      $software_version = getVerInfo($output);

      trace ("software_version on $nodename=$software_version");

      # compare version
      if ($software_version ne $release_version) {
         $lastnode_to_upgrade = FALSE;
      }
   }

   return $lastnode_to_upgrade;
}

# ARGS
# none
sub run_env_setup_modules
{
    instantiate_scripts ();

    #
    # Before Directories Creation module is invoked, we need to add entries
    # for RCALLDIR locations to crsconfig_dirs
    # Note: this is done only on platforms where RCALLDIR is defined.
    #
    if ($RCALLDIR) {
        add_RCALLDIR_to_dirs ();
    }

    add_ITDIR_to_dirs();

    # Before File Permissions module is invoked, we need to add entries for
    # OCR and Voting Disk locations to crsconfig_fileperms. This is not
    # required to be done for upgrade scenarios. Bug 8236090.

    if (! $CFG->UPGRADE)
    {
     add_olr_ocr_vdisk_locs ();
    }

    # Before create dirs and set file permissions, we need to start
    # ocfs driver.
    if (SUCCESS != s_start_ocfs_driver ()) {
      error ("Unable to start OCFS driver");
      exit 1;
    }

    create_dirs ();

    copy_wrapper_scripts ();

    set_file_perms ();

    # create s_crsconfig_$HOST_env.txt file
    s_createConfigEnvFile ();
}

sub perform_init_config
{
  my $ckptinitcfg;
  my $ckpt = "ROOTCRS_PFMINITCFG";
  if (isCkptexist($ckpt))
  {
    $ckptinitcfg = getCkptStatus($ckpt);
    trace("$ckpt state is $ckptinitcfg");
    if ($ckptinitcfg eq CKPTFAIL) {
       clean_perform_initial_config();
       perform_initial_config();
    } elsif ($ckptinitcfg eq CKPTSTART) {
       perform_initial_config();
    } elsif ($ckptinitcfg eq CKPTSUC) {
       trace("Node initail configuration already completed");
       return $SUCCESS;
    }
  }
  else {
    perform_initial_config();
  }
}

=head2 perform_initial_config

   Checks for existing CSS configuration and creates initial
   configuration if no configuration found

=head3 Parameters

   The parameter hash

=head3 Returns

  TRUE  - A  CSS configuration was found or created
  FALSE - No CSS configuration was found and none created

=cut

sub perform_initial_config {
  my $rc;
  my $success = TRUE;
  my $ASM_DISK_GROUP = $CFG->params('ASM_DISK_GROUP');
  my $ckpt = "ROOTCRS_PFMINITCFG";

  ## Enter exclusive mode to setup the environment
  trace ("Checking if initial configuration has been performed");

  writeCkpt($ckpt, CKPTSTART);

  my $excl_ret = CSS_start_exclusive();
  if ($excl_ret != CSS_EXCL_SUCCESS) {
    # These resources may have been started as part of CSS
    # startup, so stop them now
    stop_resource("ora.gpnpd", "-init");
    stop_resource("ora.gipcd", "-init");
    stop_resource("ora.mdnsd", "-init");
    stop_diskmon();

    if ($excl_ret == CSS_EXCL_FAIL_CLUSTER_ACTIVE) {
      error("An active cluster was found during exclusive startup,",
            "restarting to join the cluster");
    }
    else {
      error("The exlusive mode cluster start failed, see alert log",
            "for more information");
      $success = FALSE;
    }
  }
  # in business
  # Need to find out whether we should be doing something as
  # exclusive node or not. Use CSS voting files as a way of
  # checking cluster initialization status
  elsif (CSS_is_configured()) {
    trace("Existing configuration setup found");
  }
  else {
    trace("Performing initial configuration for cluster");

    if (!start_resource("ora.ctssd", "-init")) {
      error("Clusterware exclusive mode start of resource ora.ctssd",
            "failed");
      $success = FALSE;
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }
    # If ASM diskgroup is defined, need to configure and start ASM
    # ASM is started as part of the config

    elsif ($CFG->ASM_STORAGE_USED && !configure_ASM()) {
      error("Did not succssfully configure and start ASM");
      $success = FALSE;
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }
    # ocrconfig - Create OCR keys
    elsif (! configure_OCR()) {
      $success = FALSE;
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }
    elsif (!start_resource("ora.crsd", "-init")) {
      error("Clusterware exclusive mode start of resource ora.crsd",
            "failed");
      $success = FALSE;
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    } else {
      trace ("Creating voting files");

      # Depending on whether using ASM or not, create
      # accordingly
      if ($CFG->ASM_STORAGE_USED) {
        $success = CSS_add_vfs("+$ASM_DISK_GROUP");
        if ($success != TRUE) {
           writeCkpt($ckpt, CKPTFAIL);
           exit 1;
        }
      } else {
        $success = CSS_add_vfs(split(',', $CFG->params('VOTING_DISKS')));
        if ($success != TRUE) {
           writeCkpt($ckpt, CKPTFAIL);
           exit 1;
        }
      }
      my $ORA_CRS_HOME = $CFG->ORA_CRS_HOME;
      my $CRSCTL = catfile ($ORA_CRS_HOME, "bin", "crsctl");
      system("$CRSCTL query css votedisk");
    }

    if ($success) {
      # Push local gpnp setup to be cluster-wide.
      # This will copy local gpnp file profile/wallet setup to a
      # list of cluster nodes, including current node.
      # This promotes a node-local gpnp setup to be
      # "cluster-wide"
      trace ("Promoting local gpnp setup to cluster-wide. " .
             "Nodes {$NODE_NAME_LIST}");

      if (! push_clusterwide_gpnp_setup( $CFG->params('NODE_NAME_LIST') )) {
         error ("Failed to promote local gpnp setup to other " .
                "cluster nodes");
         $success = FALSE;
         writeCkpt($ckpt, CKPTFAIL);
         exit 1;
      }
    }

    # Allow additional commands to be executed if set
    if ($success && $CFG->CRSCFG_POST_CMD) {
      my @cmdl = @{$CFG->CRSCFG_POST_CMD};
      for my $cmd (@cmdl) { my @cmd = @{$cmd}; system_cmd(@cmd); }
    }
  }

  if ($excl_ret == CSS_EXCL_SUCCESS) {
    trace ("Exiting exclusive mode");
    if (! stop_resource("ora.crsd", "-init")) {
       error("Failed to stop CRSD");
       $success = FALSE;
       writeCkpt($ckpt, CKPTFAIL);
       exit 1;
    }

    if ($CFG->ASM_STORAGE_USED &&
        !stop_resource('ora.asm', '-init')) {
      error("Failed to stop ASM");
      $success = FALSE;
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }

    if (! stop_resource("ora.ctssd", "-init")) {
       error("Failed to stop OCTSSD");
       $success = FALSE;
       writeCkpt($ckpt, CKPTFAIL);
       exit 1;
    }

    if (!CSS_stop() ||
        !stop_resource("ora.gpnpd", "-init") ||
        !stop_resource("ora.gipcd", "-init") ||
        !stop_resource("ora.mdnsd", "-init") ||
        !stop_diskmon())
    {
      error("Failed to exit exclusive mode");
      $success = FALSE;
      writeCkpt($ckpt, CKPTFAIL);
      exit 1;
    }
  }

  if ($success != TRUE) {
     writeCkpt($ckpt, CKPTFAIL);
  } else {
     writeCkpt($ckpt, CKPTSUC);
  }
  return $success;
}

=head2 perform_upgrade_config

   Upgrades configuration and pushes cluster-wide gpnp setup 

=head3 Parameters

   The parameter hash

=head3 Returns

  TRUE  - A  configuration was found and upgraded
  FALSE - No configuration was found or upgraded

=cut

sub perform_upgrade_config {
  my $rc;
  my $success = TRUE;
  my $gpnp_setup_type = $_[0];

  # upgrade OCR
  if ($DEBUG) { trace("Upgrading OCR..."); }
  if (! upgrade_OCR()) { 
    trace("OCR upgrade failed");
    $success = FALSE;
  }
  else {

    if ($DEBUG) { trace("OCR upgraded; gpnp setup type: $gpnp_setup_type"); }
    if (($gpnp_setup_type != GPNP_SETUP_GOTCLUSTERWIDE) &&
        ($gpnp_setup_type != GPNP_SETUP_CLUSTERWIDE)) {

      # Push local gpnp setup to be cluster-wide.
      # This will copy local gpnp file profile/wallet setup to a
      # list of cluster nodes, including current node.
      # This promotes a node-local gpnp setup to be
      # "cluster-wide"
      trace ("Promoting local gpnp setup to cluster-wide. " .
             "Nodes {$NODE_NAME_LIST}");

      if (! push_clusterwide_gpnp_setup( $CFG->params('NODE_NAME_LIST') )) {
         error ("Failed to promote local gpnp setup to other " .
                "cluster nodes");
         $success = FALSE;
      }
    } else {
      trace ("Skipping push gpnp configuration cluster-wide");
    }
  }
  return $success;
}


=head2 olr_initial_config

   Creates or updates OLR

=head3 Parameters

   parameters hash

=head3 Returns

  TRUE  - OLR configuration was     created or updated
  FALSE - OLR configuration was not created or updated

=cut


sub perform_olr_initial_config
{
  my $ckptolr;
  my $ckpt = "ROOTCRS_OLR";
  if (isCkptexist($ckpt))
  {
    $ckptolr = getCkptStatus($ckpt);
    trace("$ckpt state is $ckptolr");
    if ($ckptolr eq CKPTFAIL) 
    {
       clean_olr_initial_config();
       if (! $CFG->IS_SIHA) {
          initial_cluster_validation();
       }
       olr_initial_config();
    } elsif ($ckptolr eq CKPTSTART) {
       olr_initial_config();
    } elsif ($ckptolr eq CKPTSUC) {
       trace("OLR is already initialized");
       return $SUCCESS;
    }
  }
  else {
    trace("Initializing OLR now..");
    if (! $CFG->IS_SIHA) {
       initial_cluster_validation();
    }
    olr_initial_config();
  }
}

sub olr_initial_config {
  my $status;
  my $rc = FALSE;
  my @cmd;
  my $ckpt = "ROOTCRS_OLR";

  my $ORA_CRS_HOME = $CFG->ORA_CRS_HOME;
  my $OCRCONFIGBIN = catfile ($ORA_CRS_HOME, "bin", "ocrconfig");
  my $CLSCFGBIN = catfile ($ORA_CRS_HOME, "bin", "clscfg");
  my $ORACLE_OWNER = $CFG->params('ORACLE_OWNER');
  my $ORACLE_DBA_GROUP = $CFG->params('ORA_DBA_GROUP');
  my $asmgrp       = $CFG->params('ORA_ASM_GROUP');

  writeCkpt($ckpt, CKPTSTART); 

  trace ("Creating or upgrading Oracle Local Registry (OLR)");
  if ($CFG->IS_SIHA) {
    $status = run_as_user($ORACLE_OWNER,
                          "$OCRCONFIGBIN -local -upgrade");
  }
  else {
    @cmd = ($OCRCONFIGBIN, '-local', '-upgrade', $ORACLE_OWNER, 
            $ORACLE_DBA_GROUP);
    $status = system_cmd(@cmd);
  }

  if (0 == $status) {
    trace ("OLR successfully created or upgraded");
  } else {
    trace("$OCRCONFIGBIN -local -upgrade failed with error: $status");
    error ("Failed to create or upgrade OLR");
    writeCkpt($ckpt, CKPTFAIL);
    exit 1;
  }

  ## create keys in OLR
  my $lang_id = $CFG->params('LANGUAGE_ID');
  $lang_id =~ s/'//g; # remove single quotes
  trace ("$CLSCFGBIN -localadd");

  if ($CFG->IS_SIHA) {
    $status = run_as_user($ORACLE_OWNER,
                         "$CLSCFGBIN -localadd");
  }
  else {
    system ("$CLSCFGBIN -localadd");
    $status = $CHILD_ERROR >> 8;
  }

  if (0 == $status) {
    trace ("Keys created in the OLR successfully");
    $rc = TRUE;
    writeCkpt($ckpt, CKPTSUC);
  } else {
    error ("Failed to create keys in the OLR, rc = $status, $CHILD_ERROR");
    writeCkpt($ckpt, CKPTFAIL);
    exit 1;
  }

  return $rc;
}

sub is_dev_env
{
    my $isDevEnv = uc($ENV{'_SCLS_DEVELOPMENT'});
    if ($isDevEnv eq "TRUE") {
        return TRUE;
    } else {
        return FALSE;
    }
}

# Thin wrapper of OSD function to run a command as a specified user
# Parameters:
#   1. user to run command as
#   remaining arguments are the command to run
sub run_as_user
{
  my $user = shift;
  trace("Running as user $user: @_");
  return $CFG->s_run_as_usere($user, @_);
}

# Thin wrapper of OSD function to run a command as a specified user
# Parameters:
#   1. user to run command as
#   2. array reference for output capture
#   remaining arguments are the command to run
sub run_as_user2
{
  my $user = shift;
  my $aref = shift;
  trace("Running as user $user: @_");
  return $CFG->s_run_as_user2e($user, $aref, @_);
}

sub perform_configure_hasd
{
  my $mode     = $_[0];
  my $hostname = $_[1];
  my $owner    = $_[2]; # the owner of the software bits aka CRS USER
  my $pusr     = $_[3]; # the privileged user 
  my $grp      = $_[4];
  my $ckptcfgohasd;
  my $ckpt = "ROOTCRS_OHASDRES";
  if (isCkptexist($ckpt))
  {
    $ckptcfgohasd = getCkptStatus($ckpt);
    trace("$ckpt state is $ckptcfgohasd");
    if ($ckptcfgohasd eq CKPTFAIL) {
       trace("Removing OHASD resources and types");
       configure_hasd('crs', $hostname, $owner, $pusr, $grp, "delete");
       configure_hasd('crs', $hostname, $owner, $pusr, $grp);
    } elsif ($ckptcfgohasd eq CKPTSTART) {
       configure_hasd('crs', $hostname, $owner, $pusr, $grp);
    } elsif ($ckptcfgohasd eq CKPTSUC) {
       trace("OHASD Resources are already added");
       return $SUCCESS;
    }
  }
  else {
    configure_hasd('crs', $hostname, $owner, $pusr, $grp);
  }
}

sub configure_hasd {
  my $mode     = $_[0];
  my $hostname = $_[1];
  my $owner    = $_[2]; # the owner of the software bits aka CRS USER
  my $pusr     = $_[3]; # the privileged user 
  my $grp      = $_[4];
  my $action   = $_[5];
  my @out      = ();

  my $dquotes;
  my $status;
  my $ckpt = "ROOTCRS_OHASDRES";

  
  writeCkpt($ckpt,CKPTSTART);
  # Register these resources for SIHA only
  my @registerTypesHAS = ("cssd", "crs", "evm", "ctss");
  # Register these resources for clusterware only
  my @registerTypesCRS = ("mdns", "gpnp", "gipc", "cssd", "cssdmonitor",
                          "crs", "evm", "ctss", "crf", "asm", "drivers.acfs");
 
  if ($CFG->platform_family eq "windows") {
     $dquotes = '"';
  } else {
     push(@registerTypesHAS, "diskmon");
     push(@registerTypesCRS, "diskmon");
  }
      
  my $ORACLE_HOME = $ENV{'ORACLE_HOME'};

  # 
  # Make sure CRS_HOME is set
  # 
  if ( ! $ORACLE_HOME ) {
    writeCkpt($ckpt,CKPTFAIL);
    die "ERROR: ORACLE_HOME is not set in the environment,";
  }

  # Set Homes
  my $CRS_HOME_BIN      = catdir($ORACLE_HOME,"bin");
  my $CRS_HOME_SCRIPT   = catdir($ORACLE_HOME,"crs","profile");
  my $CRS_HOME_TEMPLATE = catdir($ORACLE_HOME,"crs","template");

  my $crsctl = catfile( $CRS_HOME_BIN, "crsctl");

  ## set the owners : user IDs to spawn agents as
  my $MDNSOWNER = $owner;
  my $GPNPOWNER = $owner;
  my $GIPCOWNER = $owner;
  my $CSSOWNER = $pusr;
  my $EVMOWNER = $owner;
  my $CRSOWNER = $pusr;

  # set the users : explit execution rules (may or may not be equal to
  # owner)
  my $MDNSUSER = $owner;
  my $GPNPUSER = $owner;
  my $GIPCUSER = $owner;
  my $CSSUSER = $owner;
  my $EVMUSER = $owner;
  my $CRSDUSER = $owner;

  my @types;
  if ($mode eq "has") {
    @types = @registerTypesHAS;
  } elsif ($mode eq "crs") {
    @types = @registerTypesCRS;
  }

  my $baseType = 'ora.daemon.type';
  my $file     = 'daemon.type';
  my $infile = catfile($CRS_HOME_TEMPLATE, $file);
  my $logdir = catdir($ORA_CRS_HOME, "log", $hostname);
  my $ohasdlog = catdir($logdir, "ohasd");
  my $outfile = catfile($ohasdlog, $baseType);
  my $name;

  #set default action to add
  if (! $action) {
     $action = "add";
  }

  trace("Registering type $baseType");
  instantiateTemplate($infile, $outfile);
  if ($action eq "add") {
     system_cmd($crsctl, "add","type", $baseType, "-basetype", "cluster_resource",
              "-file", "$outfile", "-init");
     if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
     }
  }
  unlink($outfile);

  # register the infrastructure resources
  foreach my $type (@types)
  {
    $file = $type . '.type';
    $name = 'ora.' . $type . '.type';
    $infile = catfile($CRS_HOME_TEMPLATE, $file);
    $logdir = catdir($ORA_CRS_HOME, "log", $hostname);
    $ohasdlog = catdir($logdir, "ohasd");
    $outfile = catfile($ohasdlog, $file);

    trace("Registering type $name");
    instantiateTemplate($infile, $outfile);
    if ($action eq "add") {
       $status =  system_cmd($crsctl, "add","type", $name, "-basetype",
                  $baseType, "-file", "$outfile", "-init");
       trace("status for registering $baseType is $status");
       if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
       }
    }
       
    # remove outfile, not fatal if it fails
    unlink($outfile);
  }

  my @evm_attr = ("ACL='owner:$EVMOWNER:rw-,pgrp:$grp:rw-," .
                       "other::r--,user:$EVMUSER:rwx'"); 
  my @asm_attr    = ("ACL='owner:$CSSUSER:rw-,pgrp:$grp:rw-," .
                     "other::r--,user:$CSSUSER:rwx'");
  my @css_attr    = ("CSS_USER=$CSSUSER");
  my @crsd_attr   = ("ACL='owner:$CRSOWNER:rw-,pgrp:$grp:rw-," .
                     "other::r--,user:$CRSDUSER:r-x'");
  my @css_attrmon = ("CSS_USER=$CSSUSER",
                     "ACL='owner:$CSSOWNER:rw-,pgrp:$grp:rw-," .
                     "other::r--,user:$CSSUSER:r-x'");
  my @diskmon_attr = ("USR_ORA_ENV=ORACLE_USER=$CSSUSER");

  if ($ENV{'CSSDAGENT_ATTR'}) { push @css_attr, $ENV{'CSSDAGENT_ATTR'}; }
  if ($ENV{'CSSDAGENT_ATTR'}) { push @css_attrmon, $ENV{'CSSDAGENT_ATTR'}; }

  if ($mode eq "crs")
  {
    push @css_attr, "ACL='owner:$CSSOWNER:rw-,pgrp:$grp:rw-," .
                    "other::r--,user:$CSSUSER:r-x'"; 
    push @css_attr, "AUTO_START=always";

    if ($CFG->platform_family eq "windows")
    {
      push @css_attr, "START_DEPENDENCIES=weak(ora.gpnpd)" .
                      "hard(ora.cssdmonitor)";
      push @css_attr, "STOP_DEPENDENCIES='hard(intermediate:ora.gipcd,intermediate:ora.cssdmonitor)'";
    }
    else
    {
      push @css_attr, "START_DEPENDENCIES='weak(ora.gpnpd,concurrent:ora.diskmon)" .
                      "hard(ora.cssdmonitor)'";
      push @css_attr, "STOP_DEPENDENCIES='hard(intermediate:ora.gipcd,shutdown:ora.diskmon,intermediate:ora.cssdmonitor)'";
      push @diskmon_attr, "START_DEPENDENCIES='weak(concurrent:ora.cssd)" .
                          "pullup:always(ora.cssd)'";
    }
    push @diskmon_attr, "ACL='owner:$CSSOWNER:rw-,pgrp:$grp:rw-," .
                        "other::r--,user:$CSSUSER:r-x'";
   if ($action eq "add") {
      $status = system_cmd($crsctl, "add", "resource", "ora.mdnsd", "-attr", $dquotes . "ACL='owner:$MDNSOWNER:rw-,pgrp:$grp:rw-,other::r--,user:$MDNSUSER:rwx'" . $dquotes, '-type', 'ora.mdns.type', '-init');
      if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
      }
   } else {
      @out = system_cmd_capture($crsctl, "delete", "resource", "ora.mdnsd", "-f", "-init");
   }
   if ($action eq "add") {
      $status = system_cmd($crsctl, "add", "resource", "ora.gipcd", "-attr", $dquotes . "ACL='owner:$GIPCOWNER:rw-,pgrp:$grp:rw-,other::r--,user:$GIPCUSER:rwx'" . $dquotes, "-type", "ora.gipc.type", "-init");
      if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
      }
    } else {
      @out = system_cmd_capture($crsctl, "delete", "resource", "ora.gipcd", "-f", "-init");
   }
   if ($action eq "add") {
      $status = system_cmd($crsctl, "add", "resource", "ora.gpnpd", "-attr", $dquotes . "ACL='owner:$GPNPOWNER:rw-,pgrp:$grp:rw-,other::r--,user:$GPNPUSER:rwx',START_DEPENDENCIES='weak(ora.mdnsd,ora.gipcd)',STOP_DEPENDENCIES=hard(intermediate:ora.gipcd)" . $dquotes, "-type", "ora.gpnp.type", "-init");
      if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
      }
    } else {
      @out = system_cmd_capture($crsctl, "delete", "resource", "ora.gpnpd", "-f", "-init");
   }

    if ($CFG->platform_family ne "windows") {
       if ($action eq "add") {
       $status = system_cmd($crsctl, "add", "resource", "ora.diskmon",
                  "-attr", $dquotes . join(',', @diskmon_attr) . $dquotes,
                  "-type", "ora.diskmon.type", "-init");
         if ($status != CMDSUC) {
         writeCkpt($ckpt,CKPTFAIL);
         exit 1;
         }
       } else {
         @out = system_cmd_capture($crsctl, "delete", "resource", "ora.diskmon", "-f", "-init");
       }
    }
    
   if ($action eq "add") {
      $status =  system_cmd($crsctl, "add", "resource", "ora.cssdmonitor",
               "-attr", $dquotes . join(',', @css_attrmon) . $dquotes,
               "-type", "ora.cssdmonitor.type", "-init", "-f");
      if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
      }
   } else {
      @out = system_cmd_capture($crsctl, "delete", "resource", "ora.cssdmonitor", "-f", "-init");
   }
   
   if ($action eq "add") {
      $status =  system_cmd($crsctl, "add", "resource", "ora.cssd",
               "-attr", $dquotes . join(',', @css_attr) . $dquotes,
               "-type", "ora.cssd.type", "-init");
      if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
      }
   } else {
      @out = system_cmd_capture($crsctl, "delete", "resource", "ora.cssd", "-f", "-init");
   }

   if ($action eq "add") {
      $status =  system_cmd($crsctl, "add", "resource", "ora.ctssd", "-attr", "ACL='owner:$CRSOWNER:rw-,pgrp:$grp:rw-,other::r--,user:$CRSDUSER:r-x'", "-type", "ora.ctss.type", "-init");
      if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
      }
   } else {
      @out = system_cmd_capture($crsctl, "delete", "resource", "ora.ctssd", "-f", "-init");
   }
   
   # add startup and stop dependencies for evmd in cluster mode; those dependencies not used in SIHA
   push @evm_attr, "START_DEPENDENCIES='hard(ora.cssd,ora.ctssd)" .
	                                "pullup(ora.cssd,ora.ctssd)'";

   push @evm_attr, "STOP_DEPENDENCIES='hard(intermediate:ora.cssd)'";
   
   if ($action eq "add") {
       $status = system_cmd($crsctl, "add", "resource", "ora.evmd", "-attr", join(',', @evm_attr), "-type", "ora.evm.type", "-init");
      if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
      }
   } else {
      @out = system_cmd_capture($crsctl, "delete", "resource", "ora.evmd", "-f", "-init");
   }
    if (isCRFSupported())
    {
      if ($action eq "add") {
      $status =  system_cmd($crsctl, "add", "resource", "ora.crf", "-attr", "ACL='owner:$CRSOWNER:rw-,pgrp:$grp:rw-,other::r--,user:$CRSDUSER:r-x'", "-type", "ora.crf.type", "-init");
      if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
      }
      } else {
      @out = system_cmd_capture($crsctl, "delete", "resource", "ora.crf", "-f", "-init");
      }
   
    }

    # ora.ctssd dependency only needed for cluster and not for siha
    push @asm_attr, "START_DEPENDENCIES='hard(ora.cssd,ora.ctssd)" .
                                        "pullup(ora.cssd,ora.ctssd)" .
                                        "weak(ora.drivers.acfs)'";

    # When OCR is on ASM, add ora.asm as a HARD and PULLUP start dependency
    # These need to be consistent with :
    # has/crs/template/crs.type
    # prou.c
    if ($CFG->ASM_STORAGE_USED) {
       push @crsd_attr, "START_DEPENDENCIES='hard(intermediate:ora.asm,ora.cssd,ora.ctssd)" .
	                                    "pullup(ora.asm,ora.cssd,ora.ctssd)'";
       push @crsd_attr, "STOP_DEPENDENCIES='hard(shutdown:ora.asm,intermediate:ora.cssd)'";
    }

   if ($action eq "add") {
      $status =  system_cmd($crsctl, "add", "resource", "ora.asm",
                "-attr", $dquotes . join(',', @asm_attr) . $dquotes,
                "-type", "ora.asm.type", "-init");
      if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
      }
   } else {
      @out = system_cmd_capture($crsctl, "delete", "resource", "ora.asm", "-f", "-init");
   }

   if ($action eq "add") {
      $status =  system_cmd($crsctl, "add", "resource", "ora.crsd",
                "-attr", $dquotes . join(',', @crsd_attr) . $dquotes,
                "-type", "ora.crs.type", "-init");
      if ($status != CMDSUC) {
       writeCkpt($ckpt,CKPTFAIL);
       exit 1;
      }
   } else {
      @out = system_cmd_capture($crsctl, "delete", "resource", "ora.crsd", "-f", "-init");
   }

    if (isACFSSupported()) {
       my $owner;
       my $asmgrp = $CFG->params('ORA_ASM_GROUP');
       if ($CFG->platform_family eq "windows") {
          $owner  = "NT AUTHORITY\\SYSTEM";
       }
       else {
          $owner  = $CFG->SUPERUSER;
       }
       if ($action eq "add") {
          $status = system_cmd($crsctl, "add", "resource", "ora.drivers.acfs", "-attr", $dquotes . "ACL='owner:$owner:rwx,pgrp:$asmgrp:r-x,other::r--,user:$CRSDUSER:r-x'" . $dquotes, "-type", "ora.drivers.acfs.type","-init");
          if ($status != CMDSUC) {
          writeCkpt($ckpt,CKPTFAIL);
          exit 1;
         }
       } else {
          @out = system_cmd_capture($crsctl, "delete", "resource", "ora.drivers.acfs", "-f", "-init");
       }
    }

    if ($action eq "delete")
    {
     trace("Deleting base types");
     foreach my $type (@types)
     {
       $file = $type . '.type';
       $name = 'ora.' . $type . '.type';
       $logdir = catdir($ORA_CRS_HOME, "log", $hostname);
       $ohasdlog = catdir($logdir, "ohasd");
       @out =  system_cmd_capture($crsctl, "delete","type", $name, "-init");
     }
     @out = system_cmd_capture($crsctl, "delete","type", $baseType, "-init"); 
    }
  } elsif ($mode eq "has") {
    # SI-HA cssd does not depend on mdnsd/gpnpd
    push @css_attr, "ACL='owner:$CSSOWNER:rwx,pgrp:$grp:rwx,other::r--'"; 
    push @css_attr, "RESTART_ATTEMPTS=5";
    push @diskmon_attr, "ACL='owner:$CSSOWNER:rwx,pgrp:$grp:rwx,other::r--'";

    if ($CFG->platform_family ne "windows")
    {
      push @css_attr, "START_DEPENDENCIES='weak(concurrent:ora.diskmon)'";
      push @css_attr, "STOP_DEPENDENCIES='hard(shutdown:ora.diskmon)'";
      push @diskmon_attr, "START_DEPENDENCIES='weak(concurrent:ora.cssd)" .
                          "pullup:always(ora.cssd)'";

      if ($action eq "add") {
         $status = system_cmd($crsctl, "add", "resource", "ora.diskmon",
                 "-attr", $dquotes . join(',', @diskmon_attr) . $dquotes,
                 "-type", "ora.diskmon.type", "-init");
         if ($status != CMDSUC) {
          writeCkpt($ckpt,CKPTFAIL);
          exit 1;
         }
       } else {
          @out = system_cmd_capture($crsctl, "delete", "resource", "ora.diskmon", "-f", "-init");
       }
    }

    if ($action eq "add") {
       $status = system_cmd($crsctl, "add", "resource", "ora.cssd",
               "-attr", $dquotes . join(',', @css_attr) . $dquotes,
               "-type", "ora.cssd.type", "-init");
       if ($status != CMDSUC) {
         writeCkpt($ckpt,CKPTFAIL);
         exit 1;
       }
    } else {
          @out = system_cmd_capture($crsctl, "delete", "resource", "ora.cssd", "-f", "-init");
    }
     
    if ($action eq "add") {
       $status = system_cmd($crsctl, "add", "resource", "ora.evmd",
               "-attr", $dquotes . join(',', @evm_attr) . $dquotes,
               "-type", "ora.evm.type", "-init");
       if ($status != CMDSUC) {
         writeCkpt($ckpt,CKPTFAIL);
         exit 1;
       }
    } else {
          @out = system_cmd_capture($crsctl, "delete", "resource", "ora.evmd", "-f", "-init");
    }

  } 
  writeCkpt($ckpt,CKPTSUC);
  return TRUE;
}

#----------------------( instantiateTemplate )--------------------------#
#                                                                       #
#                                                                       #
#  FUNCTION: instantiateTemplate                                        #
#                                                                       #
#  PURPOSE: Instantiates the cap file with the CRS HOME location        #
#                                                                       #
#-----------------------------------------------------------------------#
sub instantiateTemplate
{
  my $ORACLE_HOME = $CFG->params('ORACLE_HOME');

  my ($inFile, $outFile) = @_;

  #TODO Define this based on platforms
  my $FSEP = '/';

  # If I can read the template or cap, instantiate the file replacing any 
  # special values
  if ( -r $inFile) 
  {
    open (INF, "<", "$inFile") or
        fatal("Unable to open $inFile, $!, ");

    # Make sure to open output file safely
    if ( -r $outFile ) 
    {
      trace("Removing pre existing $outFile from a previous run.");
      unlink($outFile) or 
          die("ERROR: Unable to remove $outFile,  $!,");
    }
    open (OUTF, ">", "$outFile") or
        die("ERROR: Unable to open file for writing $outFile,  $!,");

    # 
    # Filter Transformations
    #
    while (<INF>) 
    {
      # Modify CRS Home
      s/%ORA_CRS_HOME%/$ORACLE_HOME/;

      # Modify File Separators for NT
      s/\/\//$FSEP/g;
      print OUTF $_;
    }
    close(INF) or
        die("ERROR: Unable to close $inFile, $!");

    close(OUTF) or
        die("ERROR: Unable to close $outFile, $!");

  } 
  else 
  {
    error("$inFile is not readable.",
          "Verify the value of ORACLE_HOME, ");
    die("ERROR: Failed to register $inFile with the OHASD,");
  }

}

sub ValidateCommand
#---------------------------------------------------------------------
# Function: Validate system command to ensure command exists and
#           exececutable.
# Args    : 1
#---------------------------------------------------------------------
{
   my $cmd = $_[0];

   trace("Validating $cmd");
   if (-x $cmd) {
      return (TRUE);
   } else {
      return (FALSE);
   }
}

sub ValidateOwnerGroup
#---------------------------------------------------------------------
# Function: Validate Owner Group
# Args    :
#---------------------------------------------------------------------
{
   my $ORACLE_OWNER = $CFG->params('ORACLE_OWNER');
   my $ORACLE_DBA_GROUP = $CFG->params('ORA_DBA_GROUP');
   # validate owner
   my $valid_owner = TRUE;
   my $opt_force;

   if (($opt_force) and ($ORACLE_OWNER =~ "%")) {
      $valid_owner = FALSE;
   }

   # validate group
   my $valid_group = TRUE;
   if (($opt_force) and ($ORA_DBA_GROUP =~ "%")) {
      $valid_group = FALSE;
   }
} #endsub

sub getHostVIP
#---------------------------------------------------------------------
# Function: Get Host's VIP from CLUSTER_NEW_VIPS
#
# Args    : [0] Hostname
#
# Returns : Host's VIP
#---------------------------------------------------------------------
{
   my $hostname     = $_[0];
   my @new_hosts    = split (/,/, $CFG->params('CLUSTER_NEW_HOST_NAMES'));
   my @new_vips     = split (/,/, $CFG->params('CLUSTER_NEW_VIPS'));
   my $nbr_of_hosts = scalar(@new_hosts);
   my $nbr_of_vips  = scalar(@new_vips);

   if (($CFG->params('CRS_DHCP_ENABLED') ne 'true') &&
       ($nbr_of_hosts != $nbr_of_vips)) {
      print "ERROR: the number of hosts and the number of vips are not equal\n";
      die;
   }

   # get netmask/if
   my $srvctlbin = catfile ($CFG->ORA_CRS_HOME, "bin", "srvctl");

   open OUTPUT, "$srvctlbin config nodeapps -a|";
   my @VIPList = (<OUTPUT>);
   chomp @VIPList;
   trace ("VIPList=$VIPList[1]");
   close OUTPUT;

   if ($VIPList[1] =~ /:/) {
      # get new VIP
      my @VIPs = split (/\//, $VIPList[1]);
      my $ix   = 0;
      foreach my $host (@new_hosts) {
         chomp $host;
         if ($hostname =~ /$host/i) {
	    last;
         }

         $ix++;
      }

      # append netmask/if to new vip
      if ($VIPs[3] eq "" || $VIPs[4] eq "") {
         return "";
      }
      else {
         return $new_vips[$ix] . "/" . $VIPs[3] . "/" . $VIPs[4];
      }
   }
   else {
      return "";
   }
}

sub isAddNode
#---------------------------------------------------------------------
# Function: Check if hostname is a new node.
#
# Args    : [0] Name of host to check
#           [1] List of nodes in config
#
# Returns : TRUE  if     new node
#           FALSE if not new node
#---------------------------------------------------------------------
{
   my $hostname = $_[0];
   my $nodelist = $_[1];

   if ($CFG->defined_param('CRS_ADDNODE') &&
       $CFG->params('CRS_ADDNODE') eq "true")
   {
      return TRUE;
   } elsif ($nodelist !~ /\b$hostname\b/i) {
      return TRUE;
   }

   return FALSE;
}

sub srvctl
#---------------------------------------------------------------------
# Function: Run srvctl with the given arguments.
#
# Args    : [0] - TRUE  if run as ORACLE_OWNER
#               - FALSE if run as root
#           [1] - srvctl arguments
#
# Returns : TRUE  if successful
#           FALSE if failed
#---------------------------------------------------------------------
{
   my $run_as_oracle_owner = $_[0];
   my $srvctl_args         = $_[1];
   my $ORA_CRS_HOME        = $CFG->ORA_CRS_HOME;
   my $ORACLE_OWNER        = $CFG->params('ORACLE_OWNER');
   my $ORA_DBA_GROUP       = $CFG->params('ORA_DBA_GROUP');
   my $srvctlbin           = catfile ($ORA_CRS_HOME, "bin", "srvctl");
   $srvctl_trc_dir         = catdir ($ORA_CRS_HOME, "cfgtoollogs", "crsconfig");
  
   # set trace file 
   my $srvctl_trc_file = catfile ($srvctl_trc_dir,
                                  "srvmcfg" . $srvctl_trc_suff++ . ".log");
   $ENV{SRVM_TRACE}       = "TRUE";
   $ENV{SRVCTL_TRACEFILE} = $srvctl_trc_file;

   my $status;
   my $cmd = "${srvctlbin} $srvctl_args";
   trace ("Invoking \"${cmd}\"");
   trace ("trace file=$srvctl_trc_file");

   if ($run_as_oracle_owner) {
      $status = run_as_user ($ORACLE_OWNER, ${cmd});
   }
   else {
      $status = system (${cmd});
   }

   # set owner & permission of trace file
   s_set_ownergroup ($ORACLE_OWNER, $ORA_DBA_GROUP, $srvctl_trc_file);
   s_set_perms ("0775", $srvctl_trc_file);

   if (0 == $status) {
      return TRUE;
   } else {
      trace ("  \"${cmd}\" failed with status ${status}.");
      return FALSE;
   }
}
sub getSubnet
#---------------------------------------------------------------------
# Function: Get subnet from $NETWORKS
#
# Args    : [0] $NETWORKS
#
# Returns : subnet
#---------------------------------------------------------------------
{
   my $networks = $_[0];
   my $subnet;

   if ($networks =~ /\bpublic\b/) {
      my @network_ifs = split (/,/, $networks);

      foreach my $network_if (@network_ifs) {
         if ($network_if =~ /\bpublic\b/) {
            # strip out "eth*" and ":public"
            my ($eth, $txt) = split (/\//, $network_if);
            ($subnet, $txt) = split (/:public/, $txt);
            last;
         }
      }
   }

   return $subnet;
}

sub add_Nodeapps
#-------------------------------------------------------------------------------
# Function: Add nodeapps for static IP & DHCP
# Args    : [0] upgrade_opt
#           [1] nodevip
#           [2] DHCP_flag
#           [3] nodes_to_add
#           [4] nodes_to_start
# Returns : TRUE  if success
#           FALSE if failed
#           nodes_to_start - list of nodes to start
#-------------------------------------------------------------------------------
{
   my $upgrade_opt        = shift;
   my $nodevip_ref        = shift;
   my $isDHCP             = shift;
   my $nodes_to_add_ref   = shift;
   my $nodes_to_start_ref = shift;

   trace ("adding nodeapps...");
   trace ("upgrade_opt=$upgrade_opt");
   trace ("nodevip=@$nodevip_ref");
   trace ("DHCP_flag=$isDHCP");
   trace ("nodes_to_add=@$nodes_to_add_ref");

   my $srvctlbin        = catfile ($CFG->ORA_CRS_HOME, "bin", "srvctl");
   my $config_nodeapps  = catfile ($CFG->ORA_CRS_HOME, "bin",
                                   "srvctl config nodeapps");
   my $vip_exists       = FALSE;
   my $success          = TRUE;
   my $run_as_owner     = FALSE;
   my @output;

   if ($isDHCP) {
      trace ("add nodeapps for DHCP");
      my $node    = $$nodes_to_add_ref[0];
      push @$nodes_to_start_ref, $node;

      # Currently we don't support multiple public subnets. The installer should
      # be smart enough not to allow user to select more than 1 public subnet.
      my $subnet  = getSubnet ($CFG->params('NETWORKS'));
      my $nodevip = shift (@$nodevip_ref);
      $nodevip    =~ s/AUTO/$subnet/;  # substitute AUTO w/ subnet

      my $status = srvctl($run_as_owner,
                          "add nodeapps -S \"$nodevip\" $upgrade_opt");
      if (${status}) {
         trace ("add nodeapps -S $nodevip on node=$node ... passed");
      } else {
         error ("add nodeapps -S $nodevip on node=$node ... failed");
         $success = FALSE;
      }

      return $success;
   }

   # add nodeapps for STATIC IP
   trace("add nodeapps for static IP");

   # The following  check is only valid in case of an addnode scenario
   if (! $CFG->UPGRADE) {
      trace("Running srvctl config nodeapps to detect if VIP exists");
      open OPUT, "$config_nodeapps |";
      @output = grep(/(^PRKO-2312|^PRKO-2331|^PRKO-2339)/, <OPUT>);
      close OPUT;
      if (scalar(@output) == 0) {
         trace ("vip exists");
         $vip_exists = TRUE;
      } else {
         trace ("output=@output");
      }
   }

   foreach my $node (@$nodes_to_add_ref) {
      $node =~ tr/A-Z/a-z/; #convert to lowercase
      my $nodevip = shift (@$nodevip_ref)
                       or die "ERROR: No more elements in crs_nodevip_list";
      my $status;
      my $cmd;
      my @txt = grep (/$node/, @output);

      if (scalar(@txt) == 0) {   # nodeapps is not yet added on this node
         if ($vip_exists) {
            $cmd = "add vip -n $node -k 1 -A $nodevip";
            $status = srvctl($run_as_owner,
                             "add vip -n $node -k 1 -A \"$nodevip\" " .
                             "$upgrade_opt");
         } else {
            $vip_exists = TRUE;
            if ($CFG->UPGRADE){
               my($onslocport, $onsremport) = get_ons_port($node);
               $cmd = "add nodeapps -n $node -l $onslocport " .
                      "-r $onsremport -A $nodevip";
               $status = srvctl($run_as_owner,
                         "add nodeapps -n $node -l $onslocport -r $onsremport " .
                         "-A \"$nodevip\" $upgrade_opt");
            } else {
               $cmd = "add nodeapps -n $node -A $nodevip";
               $status = srvctl($run_as_owner,
                                "add nodeapps -n $node -A \"$nodevip\" " .
                                "$upgrade_opt");
            }
         }

         if (${status}) {
            push @$nodes_to_start_ref, $node;
            trace ("$cmd on node=$node ... passed");
         } else {
            error ("$cmd on node=$node ... failed");
            $success = FALSE;
         }
      }
   }

   trace ("nodes_to_start=@$nodes_to_start_ref");
   return $success;
}

sub start_Nodeapps
#-------------------------------------------------------------------------------
# Function: Start nodeapps for static IP & DHCP
# Args    : [0] - DHCP_flag - TRUE if it's DHCP
#           [1] - nodes_to_start - list of nodes to be started
# Returns : TRUE  if success
#           FALSE if failed
#-------------------------------------------------------------------------------
{
   my $isDHCP             = shift;
   my $nodes_to_start_ref = shift;
   trace ("starting nodeapps...");
   trace ("DHCP_flag=$isDHCP");
   trace ("nodes_to_start=@$nodes_to_start_ref");

   my $srvctl  = catfile ($CFG->ORA_CRS_HOME, 'bin', 'srvctl');
   my $success = TRUE;
   my $exit_value;
   my @output;
   my $cmd;
   my $rc;
   my $status;

   foreach my $node (@$nodes_to_start_ref) {
      if (($isDHCP) && (! isFirstNodeToStart())) {
         $cmd = "$srvctl start vip -i $node";
      } else {
         $cmd = "$srvctl start nodeapps -n $node";
      }

      $rc = `$cmd`;
      $exit_value=$?>>8;

      trace("exit value of start nodeapps/vip is $exit_value");
      if ( $exit_value != 0) {
         my @lines = split("\n",$rc);
         trace("output for start nodeapps is  @lines");
         @output=grep(!/(^PRKO-2419|^PRKO-242[0-3])/,@lines);
         trace("output of startnodeapp after removing already started mesgs is @output");

         if (scalar(@output) >= 1) {
            error ("$cmd ... failed");
            $success = FALSE;
         } else {
            trace ("$cmd ... passed");
         }
      }
   }

   return $success;

}

sub add_GNS
#---------------------------------------------------------------------
# Function: Add GNS
# Args    : [0] list of addresses on which GNS is to listen
#           [1] domain(s) which GNS is to service.
# Returns : TRUE  if success
#           FALSE if failed
#---------------------------------------------------------------------
{
   if ($CFG->params('GNS_CONF') ne "true") {
      trace ("GNS is not to be configured - skipping");
      return TRUE;
   }

   my ($address_list, $domain_list) = @_;
   my $run_as_owner                 = FALSE;
   my $status = srvctl($run_as_owner,
                       "add gns -i ${address_list} -d ${domain_list}");

   if (TRUE == ${status}) {
      trace ("add gns -i $address_list -d $domain_list ... passed");
   } else {
      error ("add gns -i $address_list -d $domain_list ... failed");
      return FALSE;
   }

   return TRUE;
}

sub start_GNS
#---------------------------------------------------------------------
# Function: Start GNS
# Args    : nonde
# Returns : TRUE  if success
#           FALSE if failed
#---------------------------------------------------------------------
{
   if ($CFG->params('GNS_CONF') ne "true") {
      trace ("GNS is not to be configured - skipping");
      return TRUE;
   }

   # start gns
   my $run_as_owner = FALSE;
   my $status       = srvctl($run_as_owner, "start gns");

   if (${status}) {
      trace ("start gns ... passed");
   } else {
      error ("start gns ... failed");
      return FALSE;
   }

   return TRUE;
}

sub enable_GSD
{
   # enable GSD
   my $success 	    = TRUE;
   my $run_as_owner = TRUE;
   my $status       = srvctl($run_as_owner, "enable nodeapps -g");

   if (${status}) {
      trace ("enable nodeapps -g ... passed");
   } else {
      error ("enable nodeapps -g ... failed");
      $success = FALSE;
   }

   if ($success) {
      # start nodeapps
      $run_as_owner = FALSE;
      my $status = srvctl($run_as_owner, "start nodeapps");

      if (${status}) {
         trace ("start nodeapps ... passed");
      } else {
         # At this point Network resource is already started.
         # Therefore it's OK to ignore return code from "start nodeapps".
         trace ("start nodeapps ... failed. It's OK!!!");
      }
   }

   return $success;
}

sub configNewNode
#---------------------------------------------------------------------
# Function: Configure nodeapps for new node
# Args    : [0] new node
#           [1] DHCP tag to indicate if DHCP is used
# Returns : TRUE  if success
#           FALSE if failed
#---------------------------------------------------------------------
{
   my $newnode             = $_[0];
   my $run_as_oracle_owner = FALSE;
   my $status;

   trace ("Configure Nodeapps for new node=$newnode");

   if ($CFG->params('CRS_DHCP_ENABLED') eq 'false') {
      # get VIP
      my $hostvip = getHostVIP($newnode);
      if (! $hostvip) {
         print "Unable to get VIP info for new node\n";
         trace ("Unable to get VIP info for new node");
         exit;
      }

      # add nodeapps
      $status = srvctl($run_as_oracle_owner,
                       "add nodeapps -n $newnode -A \"$hostvip\" ");

      if (${status}) {
         trace ("add nodeapps on node=$newnode ... success");
      } else {
         error ("add nodeapps on node=$newnode ... failed");
         return FALSE;
      }
   }

   # start vip
   $status = srvctl($run_as_oracle_owner, "start vip -i $newnode");

   if (${status}) {
      trace ("start vip on node:$newnode ... success");
   } else {
      error ("start vip on node:$newnode ... failed");
      return FALSE;
   }

   # start listener
   $status = srvctl($run_as_oracle_owner,
                    "start listener -n  $newnode");

   if (${status}) {
      trace ("start listener on node=$newnode ... success");
   } else {
      error ("start listener on node=$newnode ... failed");
      return FALSE;
   }

   return TRUE;
}

sub createDiskgroupRes
#---------------------------------------------------------------------
# Function: Create and start ASM diskgroup resource on all nodes
# Args    : none
# Returns : TRUE  if success
#           FALSE if failed
#---------------------------------------------------------------------
{
   my $ORA_CRS_HOME     = $CFG->ORA_CRS_HOME;
   my $ORACLE_OWNER     = $CFG->params('ORACLE_OWNER');
   my $ORACLE_DBA_GROUP = $CFG->params('ORA_DBA_GROUP');
   my $success          = TRUE;
   my $cmd;

   trace ("Adding ASM diskgroup resource");

   # convert ASM_DISK_GROUP to upper-case
   my $crsctl	      = catfile($ORA_CRS_HOME, 'bin', 'crsctl');
   my $ASM_DISK_GROUP = uc($CFG->params('ASM_DISK_GROUP'));
   if ($ASM_DISK_GROUP =~ /\$/) {
      # if diskgroup contains '$', put single-quotes around it
      quoteDiskGroup($ASM_DISK_GROUP);
      $cmd = "$crsctl create diskgroup '$ASM_DISK_GROUP'";
   }
   else {
      $cmd = "$crsctl create diskgroup $ASM_DISK_GROUP";
   }

   my $status = run_as_user ($ORACLE_OWNER, $cmd);

   if ($status == 0) {
      trace ("create diskgroup $ASM_DISK_GROUP ... success");
   } else {
      error ("create diskgroup $ASM_DISK_GROUP ... failed");
      return FALSE;
   }

   trace ("Successfully created disk group resource");

   # since diskgroup rescource is successfully added on the lastnode
   # we need to start diskgroup rescource on other nodes
   # get the local node
   my $olsnodes = catfile($ORA_CRS_HOME, 'bin', 'olsnodes -l');
   open (OLSNODES, "$olsnodes |") or die "olsnodes failed: $!";
   my @output = (<OLSNODES>);
   close OLSNODES;
   chomp @output;
   my $local_node = $output[0];

   # get the list of all nodes
   $olsnodes = catfile($ORA_CRS_HOME, 'bin', 'olsnodes');
   open (OLSNODES, "$olsnodes |") or die "olsnodes failed: $!";
   my @nodes = (<OLSNODES>);
   close OLSNODES;

   # build node_list from olsnodes, except for local node
   my $node_list = "";
   foreach my $node (@nodes) {
      chomp $node;
      if ($node ne $local_node) {
         if ($node_list ne "") {
            $node_list = $node_list . ",";
         }

         $node_list = $node_list . $node;
      }
   }

   # node_list eq "" means 1-node install
   if ($node_list ne "") {
      # start diskgroup on all nodes
      my $run_as_oracle_owner = FALSE;
      $status = srvctl($run_as_oracle_owner,
                       "start diskgroup -g $ASM_DISK_GROUP -n \"$node_list\" ");

      if (${status}) {
         trace ("start diskgroup resource ... success");
      } else {
         error ("start diskgroup resource ... failed");
         return FALSE;
      }
   }

   return $success;
}


sub perform_configNode
{
  my $ckptcfg;
  my $ckpt= "ROOTCRS_CFGNODE";
  if (isCkptexist($ckpt))
  {
    $ckptcfg = getCkptStatus($ckpt);
    trace("$ckpt state is $ckptcfg");
    if ($ckptcfg eq CKPTFAIL) {
       clean_configNode();
       configNode();
    } elsif ($ckptcfg eq CKPTSTART) {
       configNode();
    } elsif ($ckptcfg eq CKPTSUC) {
       trace("CRS Resources are already configured");
       return $SUCCESS;
    }
  }
  else {
    configNode();
  }
}

sub configNode
#---------------------------------------------------------------------
# Function: Configure node
# Args    : none
# Returns : TRUE  if success
#           FALSE if failed
#---------------------------------------------------------------------
{
   trace ("Configuring node");
   my $DHCP_flag = FALSE;
   my $success   = TRUE;
   my $ckpt = "ROOTCRS_CFGNODE";

   writeCkpt($ckpt, CKPTSTART);

   # set DHCP_flag to TRUE if it's DHCP
   my $crs_nodevips = $CFG->params('CRS_NODEVIPS');
   $crs_nodevips    =~ s/'//g; # ' in comment to avoid confusion of editors.
   $crs_nodevips    =~ s/"//g; # remove " on Windows
   my @crs_nodevip_list = split (/\s*,\s*/, $crs_nodevips);

   if ($crs_nodevip_list[0] =~ /\bAUTO/) {
      $DHCP_flag = TRUE;
   }

   # configure new node
   if (isAddNode($HOST, $CFG->params('NODE_NAME_LIST'))) {
      $success = configNewNode($HOST);
      return $success;
   }

   # configure upgrade node 
   if ($CFG->UPGRADE) {
      if (isLastNodeToUpgrade ($HOST, $CFG->params('NODE_NAME_LIST'))) {
	 $success = configLastNode(@crs_nodevip_list_old);
      }

      # clean-up from upgrade
      if ($CFG->platform_family eq 'unix') {
         s_houseCleaning();
      }

      return $success;
   }

   # configure fresh install node
   my $upgrade_option;
   my @nodevip;
   my @nodes_to_add;
   my @nodes_to_start;

   # add nodeapps
   my @node_list = split (',', $CFG->params('NODE_NAME_LIST'));
   my $ix        = 0;
   foreach my $node (@node_list) {
      if ($CFG->HOST =~ /$node/i) {
         push @nodevip, $crs_nodevip_list[$ix];
         push @nodes_to_add, $node;
         last; # done for this node
      } else {
         $ix++;
      }
   }

   if (isFirstNodeToStart()) {
      $success = add_Nodeapps($upgrade_option, \@nodevip, $DHCP_flag, 
			      \@nodes_to_add, \@nodes_to_start);
      if ($success != TRUE) {
         writeCkpt($ckpt, CKPTFAIL);
         exit 1;
      }

      $success = configFirstNode($DHCP_flag, \@nodes_to_start);
      if ($success != SUCCESS) { 
         writeCkpt($ckpt, CKPTFAIL);
         exit 1; 
      }      
   } else {
      if ($DHCP_flag) {
         push @nodes_to_start, $nodes_to_add[0];
      }
      else {
         $success = add_Nodeapps($upgrade_option, \@nodevip, $DHCP_flag, 
				 \@nodes_to_add, \@nodes_to_start);
      }

      if ($success) {
         $success = start_Nodeapps($DHCP_flag, \@nodes_to_start);
      }
   }

   writeCkpt($ckpt, CKPTSUC);
   return $success;
}

sub configFirstNode
#---------------------------------------------------------------------
# Function: Configure first node
# Args    : [0] DHCP_flag
#           [1] nodes_to_start
# Returns : TRUE  if success
#           FALSE if failed
#---------------------------------------------------------------------
{
   my $DHCP_flag          = shift;
   my $nodes_to_start_ref = shift;

   trace ("Configuring first node");
   trace ("DHCP_flag=$DHCP_flag");
   trace ("nodes_to_start=@$nodes_to_start_ref");

   my $success = SUCCESS;

   if (($CFG->params('ASM_UPGRADE') =~ m/false/i) && (! isASMExists())) {
      trace("Prior version ASM does not exist , Invoking add asm");
      add_ASM();  # add ora.asm
      if ($CFG->ASM_STORAGE_USED) {
         createDiskgroupRes();  # add disk group resource, if necessary
      }
    }

   add_acfs_registry();


   if ($success &&
       add_GNS($CFG->params('GNS_ADDR_LIST'),
               $CFG->params('GNS_DOMAIN_LIST')) &&
       add_scan() &&
       add_scan_listener() &&
       add_J2EEContainer()) {
       $success = SUCCESS;
   } else {
       $success = FAILED;
   }

   if ($success &&
       start_Nodeapps($DHCP_flag, \@$nodes_to_start_ref) &&
       start_GNS() &&
       start_scan() &&
       start_scan_listener() &&
       start_J2EEContainer()) {
       $success = SUCCESS;
       if (($CFG->params('ASM_UPGRADE') =~ m/false/i) && (isASMExists())) {
          $success = start_acfs_registry(\@$nodes_to_start_ref);
       }

       if ($CFG->platform_family eq 'unix') {
          if (s_is92ConfigExists()) {
             $success = enable_GSD();
          }
       }
   } else {
       $success = FAILED;
   }

   return $success;
}

sub configLastNode
#---------------------------------------------------------------------
# Function: Configure last node (for upgrade only)
# Args    : [0] crs_nodevip_list - contains viplist
# Returns : TRUE  if success
#           FALSE if failed
#---------------------------------------------------------------------
{
   my @crs_nodevip_list = @_;
   trace ("Configuring last node");
   trace("Old nodeapps list is  @crs_nodevip_list");
   my $success        = TRUE;
   my $crsctlbin      = catfile ($CFG->ORA_CRS_HOME, "bin", "crsctl");
   my $srvctlbin      = catfile ($CFG->ORA_CRS_HOME, "bin", "srvctl");
   my $DHCP_flag      = FALSE;
   my $upgrade_option = "-u";
   my $status;
   my @nodes_to_start;

   # set DHCP_flag to TRUE if it's DHCP
   if ($crs_nodevip_list[0] =~ /\bAUTO/) {
      $DHCP_flag = TRUE;
   }

   # for upgrade VIP information would be read from existing OCR.
   upgrade_config();

   # add nodeapps
   my @nodes_to_add = split (',', $CFG->params('NODE_NAME_LIST'));
   $success = add_Nodeapps($upgrade_option, \@crs_nodevip_list,
                           $DHCP_flag, \@nodes_to_add, \@nodes_to_start);

   # Trigger the active version change.
   if ($success && (! setActiveversion())) {
      $success = FAILED;
   }

   if ($success &&
      ($CFG->params('ASM_UPGRADE') =~ m/false/i) &&
      (! isASMExists())) {
      trace("Prior version ASM does not exist , Invoking add asm");
      add_ASM();  # add ora.asm
      if ($CFG->ASM_STORAGE_USED) {
         createDiskgroupRes();  # add disk group resource, if necessary
      }

   }

   add_acfs_registry();

   if ($success &&
       add_GNS($CFG->params('GNS_ADDR_LIST'),
               $CFG->params('GNS_DOMAIN_LIST')) &&
       add_scan() &&
       add_scan_listener() &&
       add_J2EEContainer()) {
       $success = SUCCESS;
   } else {
       $success = FAILED;
   }

   if ($success &&
       start_Nodeapps($DHCP_flag, \@nodes_to_start) &&
       start_GNS() &&
       start_scan() &&
       start_scan_listener() &&
       start_J2EEContainer())
   {
       $success = SUCCESS;
       if (($CFG->params('ASM_UPGRADE') =~ m/false/i) && (isASMExists())) {
          $success = start_acfs_registry(\@nodes_to_start);
       }

       if ($CFG->platform_family eq 'unix') {
          # FIXME: need to have the same function on windows
          if (s_is92ConfigExists()) {
             $success = enable_GSD();
          }
       }
   } else {
       $success = FAILED;
   }

   return $success;
}

# Get CRS active version major number (i.e. 10, 11, etc.) Stack must be up.
sub getCRSMajorVersion {
  my $crsctlbin = catfile ($CFG->ORA_CRS_HOME, 'bin', 'crsctl');
  my $ver 	= 0;
  my @cmd 	= ($crsctlbin, 'query', 'crs', 'activeversion');
  my @out 	= system_cmd_capture(@cmd);
  my $rc  	= shift @out;

  if ($rc == 0) {
     my $verinfo    = getVerInfo($out[0]);
     my @versionarr = split(/\./, $verinfo);
     $ver	    = $versionarr[0];
     trace("crs major version=$ver");
  }
  else {
     error ("@cmd ... failed rc=$rc with message:\n @out \n");
  }

  return $ver;
}

=head2 get_crs_version

  Gets parsed version numbers of active CRS version.
  Version is a result of "crsctl query crs activeversion" command.
  Stack (CRS) must be up for this to succeed.

=head3 Parameters

  string with crsctl home location. If undef, then current home is used.
   
=head3 Returns

=head4 returns an array of version numbers major to minor. 
       If error occurred, all numbers will be 0. Error will be printed.       

=cut

sub get_crs_version 
{
   my $home = $_[0];
   my @ver  = (0, 0, 0, 0, 0);
   my ($crsctl);

   if (! defined $home) {
      $crsctl = crs_exec_path('crsctl');
   } else {
      $crsctl = catfile($home, 'bin', 'crsctl' );
   }

   # run "crsctl query crs activeversion" -- stack must be up
   # Example output:
   # Oracle Clusterware active version on the cluster is [11.2.0.0.2]
   my @cmd = ($crsctl, 'query', 'crs', 'activeversion');
   my @out = system_cmd_capture(@cmd);
   my $rc  = shift @out;

   # if succeeded, parse to ver numbers, output must be a single line,
   # version is 5 numbers, major to minor (see above) 
   if ($rc == 0) { 
      my $verstring = getVerInfo($out[0]);
      @ver          = split(/\./, $verstring);
      trace( "Got CRS active version: ".join('.', @ver) );
   }
   else {
      error ("@cmd ... failed rc=$rc with message:\n @out \n");
   }
   return @ver;
}

sub upgrade_config {
  # On the last node create a OCR backup.
  my $ORA_CRS_HOME    = $CFG->ORA_CRS_HOME;
  my $crsctlbin       = catfile ($ORA_CRS_HOME, "bin", "crsctl");
  my $ocrconfigbin = catfile ($ORA_CRS_HOME, "bin", "ocrconfig");
  my $success = FAILED;
  my $status;
  my $cmd;

  if (getCRSMajorVersion() > 10)
  {
    $cmd = "$ocrconfigbin -manualbackup";
    trace ("Invoking \"$cmd\"");
    my $status = system_cmd("$cmd");
    if (0 == $status) {
      trace ("OCR backup completed  successfully");
    } else {
      error ("OCR backup failed!");
    }
  }

  # Should we proceed with the upgrade if the OCR backup fails?

  # Tell crs subsystem to copy the old resource profiles to new
  # engine. Which does not copy the nodeapps.
  $cmd = "$crsctlbin startupgrade";
  trace ("Invoking \"$cmd\"");
  $status = system_cmd ("$cmd");

  if ($status == 0) { $success = SUCCESS; }

  return $success;
}

sub add_scan 
{
   my $run_as_oracle_owner = FALSE;
   my $status = srvctl($run_as_oracle_owner, "add scan -n $SCAN_NAME");

   if (${status}) {
      trace ("add scan=$SCAN_NAME ... success");
   } else {
      error ("add scan=$SCAN_NAME ... failed");
      return FALSE;
   }

   return TRUE;
}

sub start_scan 
{
   my $run_as_oracle_owner = FALSE;
   my $status = srvctl($run_as_oracle_owner, "start scan");

   if (${status}) {
      trace ("start scan ... success");
   } else {
      error ("start scan ... failed");
      return FALSE;
   }

   return TRUE;
}

sub add_scan_listener 
{
   my $run_as_oracle_owner = TRUE;
   my $status = srvctl($run_as_oracle_owner, "add scan_listener -p $SCAN_PORT");

   if (${status}) {
      trace ("add scan listener ... success");
   } else {
      error ("add scan listener ... failed");
      return FALSE;
  }

  return TRUE;
}

sub start_scan_listener 
{
   my $run_as_oracle_owner = TRUE;
   my $status = srvctl($run_as_oracle_owner, "start scan_listener");

   if (${status}) {
      trace ("start scan listener ... success");
   } else {
      error ("start scan listener ... failed");
      return FALSE;
   }

   return TRUE;
}

sub isACFSSupported
{
  $ACFS_supported      = FALSE;
  my $acfsroot         = catfile ($CFG->ORA_CRS_HOME, "bin", "acfsroot");
  my $acfsroot_bat     = catfile ($CFG->ORA_CRS_HOME, "bin", "acfsroot.bat");
  my $myplatformfamily = s_get_platform_family ();
     $myplatformfamily =~ tr/A-Z/a-z/;

  # if we are running in development mode, then limit support to only when
  # the appropriate env variables are set
  if( is_dev_env() )
  {
    my $acfsInstall = uc($ENV{'USM_ENABLE_ACFS_INSTALL'});
    
    # if this ENV is not set then we give up early
    if ( $acfsInstall ne "TRUE" )
    {
      trace("ADVM/ACFS disabled because of ENV in test mode");
      return FALSE;
    }
  }

  if ($myplatformfamily eq "windows") {
     if (! (-e $acfsroot_bat)) {
        trace ("ADVM/ACFS is not configured");
        return FALSE;
     }
  } else {
     if (! (-e $acfsroot)) {
        trace ("ADVM/ACFS is not configured");
        return FALSE;
     }
  }

  # Output (error messages) from acfsroot gets trapped so that it can
  # be sent to the CRS log via error().
  open (ACFS, "$acfsroot install -s |");
  my $acfsroot_output = <ACFS>;

  # no output (error messages) means success
  if (defined($acfsroot_output)) {
    do {
      error($acfsroot_output);
    }  while ($acfsroot_output = <ACFS>);

    $ACFS_supported = FALSE;
    trace ("ADVM/ACFS is not configured");
  } else {
    $ACFS_supported = TRUE;
    trace ("ADVM/ACFS is configured\n");
  }

  close(ACFS);
  return $ACFS_supported;
}

sub add_ASM 
{
   my $run_as_oracle_owner = TRUE;
   my $status = srvctl($run_as_oracle_owner, "add asm");

   if (${status}) {
      trace ("add asm ... success");
   } else {
      error ("add asm ... failed");
      return FALSE;
   }

   return TRUE;
}

sub add_acfs_registry
{
   if (! $ACFS_supported) {
      return TRUE;
   }

   my $ORA_CRS_HOME = $CFG->ORA_CRS_HOME;
   my $owner        = $CFG->SUPERUSER;
   my $asmgrp       = $CFG->params('ORA_ASM_GROUP');
   my $crsctlbin    = catfile ($ORA_CRS_HOME, "bin", "crsctl");
   my $rc           = TRUE;

   # add type ora.registry.acfs.type
   my @cmd = ($crsctlbin, 'add', 'type', 'ora.registry.acfs.type',
              '-basetype', 'ora.local_resource.type',
              '-file', "$ORA_CRS_HOME/crs/template/registry.acfs.type");
   trace ("Invoking: @cmd");
   my $status = system_cmd(@cmd);

   if (0 == $status) {
      trace ("add ora.registry.acfs.type ... success");
   }
   else {
      error ("add ora.registry.acfs.type ... failed");
      return FALSE;
   }

   # add resource ora.registry.acfs
   @cmd = ($crsctlbin, "add", "resource", "ora.registry.acfs", "-attr", 
	     	"ACL='owner:$owner:rwx,pgrp:$asmgrp:r-x,other::r--'", 
		"-type", "ora.registry.acfs.type", "-f");

   trace ("Invoking: @cmd");
   $status = system_cmd (@cmd);

   if (0 == $status) {
      trace ("add resource ora.registry.acfs ... success");
   }
   else {
      error ("add resource ora.registry.acfs ... failed");
      return FALSE;
   }

  return $rc;
}

sub start_acfs_registry
#-------------------------------------------------------------------------------
# Function: Start acfs registry
# Args	  : [0] - nodes_to_start - list of nodes to start
# Returns : TRUE  if success
#           FALSE if failed
#-------------------------------------------------------------------------------
{
   if ((! $ACFS_supported) || (! $CFG->ASM_STORAGE_USED)) {
      return TRUE;
   }

   my $nodes_to_start_ref = shift;
   trace ("starting acfs_registry...");
   trace ("nodes_to_start=@$nodes_to_start_ref");

   my $crsctl = catfile ($CFG->ORA_CRS_HOME, "bin", "crsctl");
   my $rc     = TRUE;

   # start resource ora.acfs
   foreach my $node (@$nodes_to_start_ref) {
      my @cmd = ($crsctl, 'start', 'res', 'ora.registry.acfs', '-n', $node);
      my $status = system_cmd(@cmd);

      if (0 == $status) {
         trace ("@cmd ... success");
      }
      else {
         trace ("@cmd ... failed");
         $rc = FALSE;
         last;
      }
   }

   return $rc;
}

=head2 configure_ASM

   Creates or updates ASM

=head3 Parameters

   None

=head3 Returns

  TRUE  - ASM configuration was     created or updated
  FALSE - ASM configuration was not created or updated

=head3 Notes

  This will start ASM as part of the configuration if it is successful

=cut

sub configure_ASM {
  my $ORA_CRS_HOME = $CFG->ORA_CRS_HOME;
  my $success = TRUE;
  my $status;
  my $ASMDISKS = $CFG->params('ASM_DISKS');
  my $ASM_DISCOVERY_STRING = $CFG->params('ASM_DISCOVERY_STRING');

  trace ("Configuring ASM via ASMCA");

  # Do not change the order of these parameters as asmca requires the
  # parameters to be in a specific order or it will fail
  my @runasmca = (catfile ($ORA_CRS_HOME, "bin", "asmca"), '-silent');
  if ($CFG->params('ASM_DISK_GROUP') ){
     my $diskgroup = $CFG->params('ASM_DISK_GROUP');
     if ($diskgroup =~ /\$/) {
        # if diskgroup contains '$', put single-quotes around it
        quoteDiskGroup($diskgroup);
        push @runasmca, '-diskGroupName', "'$diskgroup'";
     }
     else {
        push @runasmca, '-diskGroupName', $diskgroup;
     }
  }

  # When this is run as superuser
  if ($CFG->params('ASM_DISKS')) {
    push @runasmca, '-diskList', $ASMDISKS;
  }

  if ($CFG->params('ASM_REDUNDANCY')) {
    push @runasmca, '-redundancy', $CFG->params('ASM_REDUNDANCY');
  }

  if ($CFG->params('ASM_DISCOVERY_STRING')) {
    push @runasmca, '-diskString', "'$ASM_DISCOVERY_STRING'";
  }

  if (isFirstNodeToStart()) {
    push (@runasmca, ('-configureLocalASM'));
  }

  if ($CFG->defined_param('ORATAB_LOC')) {
      push (@runasmca, ('-oratabLocation'), $CFG->params('ORATAB_LOC'));
  }

  trace ("Executing as " . $CFG->params('ORACLE_OWNER') . ": @runasmca");
  $status = run_as_user($CFG->params('ORACLE_OWNER'), @runasmca);

  if ($status != 0) {
    $success = FALSE;
    error("Configuration of ASM failed, see logs for details");
  }

  return $success;
}

=head2 configure_OCR

   Creates or updates OCR

=head3 Parameters

   None

=head3 Returns

  TRUE  - OCR configuration was     created or updated
  FALSE - OCR configuration was not created or updated

=cut

sub configure_OCR {
  my $ORA_CRS_HOME = $CFG->ORA_CRS_HOME;
  my $success = TRUE;
  my $OCRCONFIGBIN = catfile ($ORA_CRS_HOME, "bin", "ocrconfig");
  my $status;
  my $lang_id = $CFG->params('LANGUAGE_ID');
  my $asmgrp       = $CFG->params('ORA_ASM_GROUP');

  my @runocrconfig = ("$OCRCONFIGBIN", "-upgrade",
                      $CFG->params('ORACLE_OWNER'),
                      $CFG->params('ORA_DBA_GROUP'));

  my $CLSCFGBIN = catfile ($ORA_CRS_HOME, "bin", "clscfg");
  my @runclscfg = ("$CLSCFGBIN", "-install",
                   "-h", $CFG->params('HOST_NAME_LIST'),
                   '-o', $ORA_CRS_HOME, 
                   '-g', $asmgrp);

  if ($CFG->CLSCFG_EXTRA_PARMS) {
    push @runclscfg, @{$CFG->CLSCFG_EXTRA_PARMS};
  }

  trace ("Creating or upgrading OCR keys");
  $status = system_cmd("@runocrconfig");
  if (0 != $status) {
    error ("Failed to create Oracle Cluster Registry configuration,",
           "rc $status");
    $success = FALSE;
  }
  else {
    trace ("OCR keys are successfully populated");

    if (!s_reset_srvconfig()) {
      error("Reset of OCR location in srvconfig failed");
      $success = FALSE;
    }
    else {
      #
      # clscfg - Initialize the Oracle Cluster Registry for the
      #          cluster. Should be done once per cluster install.
      #          Overwriting a configuration while any CRS daemon is
      #          running can cause serious issues.
      #
      trace("Executing clscfg");
      $status = system_cmd("@runclscfg");

      # Get true return value of clscfg (i.e. rc for spawned
      # process)
      if (0 != $status) {
        error("Failed to initialize Oracle Cluster Registry for cluster,",
              "rc $status");
        $success = FALSE;
      }
      else {
        trace ("Oracle Cluster Registry initialization completed");

        if ($CFG->CLSCFG_POST_CMD) {
          my @cmd = @{$CFG->CLSCFG_POST_CMD};
          system_cmd(@cmd);
        }
      }
    }
  }

  return $success;
}

# Execute a system command and analyze the return codes
sub system_cmd {
  my $rc = 0;

  if ($DEBUG) { trace("Executing cmd: @_"); }

  system(@_);

  my $prc = $CHILD_ERROR >> 8; # get program return code
  if ($prc != 0) {
    # program returned error code
    error("Command return code of $prc ($CHILD_ERROR) from command: @_");
    $rc = $prc;
  }
  elsif (($rc = $CHILD_ERROR) < 0) {
    error("Failure to execute: $! for command @_");
  }
  elsif ($rc & 127) {
    # program returned error code
    my $sig = $rc & 127;
    error("Failure with signal $sig from command: @_");
  }
  elsif ($rc) { trace("Failure with return code $rc from command @_"); }

  return $rc;
}

=head2 system_cmd_capture

  Capture the output from a system command and analyze the return codes

=head3 Parameters

   Command to be executed

=head3 Returns

  Array containing both the return code and the captured output 
  The command output is chomped

=head3 Usage

  To capture the data of command foo:
    my @out = system_cmd_capture('foo')
    my $rc = shift @out;

  The @out now contains only the output of the command 'foo'

=cut

sub system_cmd_capture {
  my $rc  = 0;
  my $prc = 0;
  my @output;

  if ($DEBUG) { trace("Executing cmd: @_"); }

  if (!open(CMD, "@_ 2>&1 |")) { $rc = -1; }
  else {
    @output = (<CMD>);
    close CMD;
    # the code return must be after the close
    $prc = $CHILD_ERROR >> 8; # get program return code right away
    chomp(@output);
  }

  if ($DEBUG) { trace(join("\n", ("Command output:", @output))); }

  if ($prc != 0) {
    # program returned error code
    # error("Command return code of $prc from command: @_");
    $rc = $prc;
  }
  elsif ($rc < 0 || ($rc = $CHILD_ERROR) < 0) {
    error("Failure to execute: $! for command @_");
  }
  elsif ($rc & 127) {
    # program returned error code
    my $sig = $rc & 127;
    error("Failure with signal $sig from command: @_");
  }
  elsif ($rc) { trace("Failure with return code $rc from command @_"); }

  return ($rc, @output);
 
}

sub ExtractVotedisks
#---------------------------------------------------------------------
# Function: Extract Voting disks
#
# Args    : none
#---------------------------------------------------------------------
{
   # Check if CRS is up
   my $crsctl    = catfile ($ORA_CRS_HOME, "bin", "crsctl");
   my $cluster_is_up = check_service ("cluster", 2);
   my $crs_is_up = check_service ("ohasd", 2);
   my $start_exclusive = FALSE;
   my @votedisk_list;

   if (!$crs_is_up) {
     trace("OHASD is not up. So starting CRS exclusive");
     start_service("crsexcl"); 
     $crs_is_up = TRUE;
   }
   else {
     trace("OHASD is already up.");

     if (!$cluster_is_up) {
       trace("Starting CSS exclusive");
       $start_exclusive = TRUE;
       my $css_rc = CSS_start_exclusive();
       if ($css_rc != CSS_EXCL_SUCCESS) {
         $start_exclusive = FALSE;
         trace ("CSS failed to enter exclusive mode to extract votedisk");
       }
     }
   }

   if (($crs_is_up) || ($start_exclusive)) {
      trace("Querying CSS vote disks");
      open (QUERY_VOTEDISK, "$crsctl query css votedisk|");
      my @css_votedisk = (<QUERY_VOTEDISK>);
      chomp @css_votedisk;
      close QUERY_VOTEDISK;

      if ($start_exclusive) {
         CSS_stop();
      }

      foreach my $votedisk (@css_votedisk) {
         trace("Voting disk is : $votedisk");
         # get line contains ' (/'
         if ($votedisk =~ / \(/) {
            # $votedisk contains '1.  2 282bf2a833f54f02bf4befd002fa90d6
            # (/dev/raw/raw1) [OCRDG]'
            # parse $votedisk to get '/dev/raw/raw1'
            my $vdisk;
            my ($dummy, $text) = split (/\(/, $votedisk);
            ($vdisk, $dummy) = split (/\)/, $text);
            push (@votedisk_list, $vdisk);
         }
      }
   }

   trace ("Vote disks found: @votedisk_list");
   return @votedisk_list;
}

sub add_J2EEContainer
#---------------------------------------------------------------------
# Function: Add the OC4J Container
# Args    : none
#---------------------------------------------------------------------
{
   my $oc4j_owner  = $CFG->params('ORACLE_OWNER');
   my $srvctlbin   = catfile ($CFG->ORA_CRS_HOME, "bin", "srvctl");
   my $srvctl_add  = "$srvctlbin add oc4j";
   my $oc4j_status = FAILED;

   #setup SRVCTL tracing
   $srvctl_trc_dir  = catdir ($CFG->ORA_CRS_HOME, "cfgtoollogs", "crsconfig");
   my $srvctl_trc_file = catfile ($srvctl_trc_dir,
                         "srvmcfg" . $srvctl_trc_suff++ . ".log");
   $ENV{SRVCTL_TRACEFILE} = $srvctl_trc_file;

   # Add the OC4J resource
   my $oc4j_cmd_retval = run_as_user($oc4j_owner, $srvctl_add);

   if (0 != $oc4j_cmd_retval) {
      trace ("J2EE (OC4J) Container Resource Add ... failed ...");
   } else {
      $oc4j_status = SUCCESS;
      trace ("J2EE (OC4J) Container Resource Add ... passed ...");
   }

   return $oc4j_status;
}

sub start_J2EEContainer
#---------------------------------------------------------------------
# Function: Start the OC4J Container
# Args    : none
#---------------------------------------------------------------------
{
   my $oc4j_owner = $CFG->params('ORACLE_OWNER');
   my $srvctlbin           = catfile ($CFG->ORA_CRS_HOME, "bin", "srvctl");
   my $srvctl_start        = "$srvctlbin start oc4j";
   my $srvctl_disable      = "$srvctlbin disable oc4j";
   my $oc4j_status         = FAILED;
   my $oc4j_enable_start   = FALSE;
   my $oc4j_cmd_retval;

   #setup SRVCTL tracing
   $srvctl_trc_dir  = catdir ($CFG->ORA_CRS_HOME, "cfgtoollogs", "crsconfig");
   my $srvctl_trc_file = catfile ($srvctl_trc_dir,
                         "srvmcfg" . $srvctl_trc_suff++ . ".log");
   $ENV{SRVCTL_TRACEFILE} = $srvctl_trc_file;

   # Start the OC4J resource if not disabled
   if (!$oc4j_enable_start) {
      # Disable the OC4J resource (oc4j_enable_start = FALSE)
      $oc4j_cmd_retval = run_as_user($oc4j_owner, $srvctl_disable);

      if (0 != $oc4j_cmd_retval) {
         trace ("J2EE (OC4J) Container Resource Disable ... failed ...");
      } else {
         $oc4j_status = SUCCESS;
         trace ("J2EE (OC4J) Container Resource Disable ... passed ...");
      }
   } else {
      # Start OC4J Resource (oc4j_enable_start = TRUE)
      $oc4j_cmd_retval = run_as_user($oc4j_owner, $srvctl_start);

      if (0 != $oc4j_cmd_retval) {
         trace ("J2EE (OC4J) Container Resource Start ... failed ...");
      } else {
         $oc4j_status = SUCCESS;
         trace ("J2EE (OC4J) Container Resource Start ... passed ...");
      }
   }

   return $oc4j_status;
}

sub configureAllRemoteNodes
#---------------------------------------------------------------------
# Function: Configure all remote nodes for Windows
#
# Args    : none
#---------------------------------------------------------------------
{
   my $host = $_[0];
   my $platform_family = s_get_platform_family ();

   if (($platform_family eq "windows")
   && (! isLastNodeToStart($host, $NODE_NAME_LIST))) {
      s_configureAllRemoteNodes();

   }
}

#For 10.1, get the oracle home location where the VIP
#resources are configured.
sub get101viphome
{
  my $host    = $CFG->HOST;
  my $ocrdump = catfile ($ORACLE_HOME, 'bin', 'ocrdump');

  # get ons.ACTION_SCRIPT keyname
  open (OCRDUMP, "$ocrdump -stdout -keyname " .
        "'CRS.CUR.ora!$host!ons.ACTION_SCRIPT'|");
  my @output = <OCRDUMP>;
  close (OCRDUMP);

  # get vip home
  my @txt = grep (/ORATEXT/, @output);
  my ($key, $vip_home) = split (/: /, $txt[0]);
  $vip_home =~ s!/bin/racgwrap!!g;
  $vip_home =~ s/^ //g;
  chomp($vip_home);
  return $vip_home;
}

# gets the VIp information from the OCR. CRS stack needs to be up
# before calling this sub routine.
sub get_OldVipInfo
{
  my @CRS_NODEVIP_LIST;
  my $vip_index     = 0;
  my $OLD_CRS_HOME  = $CFG->OLD_CRS_HOME;
  my @SNODES        = split (/,/, $NODE_NAME_LIST);
  my $ORACLE_OWNER  = $CFG->params('ORACLE_OWNER');
  my $ORA_DBA_GROUP = $CFG->params('ORA_DBA_GROUP');
  my $srvctlbin;

  # if version is 10.1, use dbhome. Otherwise, use OLD_CRS_HOME.
  my @old_version = @{$CFG->oldconfig('ORA_CRS_VERSION')};
  if ($old_version[0] eq "10" &&
      $old_version[1] eq "1") {

     my $ons_home = get101viphome();
     $srvctlbin = catfile ($ons_home, 'bin', 'srvctl');
     $ENV{'ORACLE_HOME'}  = $ons_home;
  } else {
     $srvctlbin = catfile ($OLD_CRS_HOME, 'bin', 'srvctl');
  }

  foreach my $nodename (@SNODES) {
    my $SRVCTL_CMD = "$srvctlbin config nodeapps -n $nodename -a";
    open(SRVCMDF, "$SRVCTL_CMD |") 
      || die "Could not get existing VIP information\n";
    my @buffer = <SRVCMDF>;
    close SRVCMDF;

    my $VipValue = $buffer[0];
    chomp($VipValue);
    trace("VIpValue =  $VipValue");
    my ($Name, $Value) 	= split(/:/, $VipValue);
    my ($val1, $vip_name, $ip, $old_netmask, $intif) 
			= split(/\//, $Value);
    my ($new_netmask, $vip);
    chomp $vip_name;
    chomp $ip;
    chomp $old_netmask;
    chomp $intif;
    trace("vip_name = $vip_name");
    trace("ip = $ip");
    trace("old_netmask = $old_netmask");
    trace("intif =$intif");

    # use vip_name if it exists, otherwise use ip
    if (! $vip_name) {
       $vip = $ip;
    }
    else {
       $vip = $vip_name;
    }

    if (validateNetmask($old_netmask, $intif, \$new_netmask)) {
       $CRS_NODEVIP_LIST[$vip_index] = "$vip/$old_netmask";
    } else {
       $CRS_NODEVIP_LIST[$vip_index] = "$vip/$new_netmask";
    }

    trace ("vip on $nodename = $CRS_NODEVIP_LIST[$vip_index]");
    $vip_index++;
  }

  $ENV{'ORACLE_HOME'} = $ORACLE_HOME;
  return @CRS_NODEVIP_LIST;
}

sub get_OldVipInfoFromOCRDump
#-------------------------------------------------------------------------------
# Function:  Get old VIP info from ocrdump
# Args    :  none
# Returns :  @vip_list
#-------------------------------------------------------------------------------
{
   trace("get old VIP info from ocrdump");
   my $ocrdump  = catfile ($CFG->params('ORACLE_HOME'), 'bin', 'ocrdump');
   my @nodes    = split (/,/, $CFG->params('NODE_NAME_LIST'));
   my $ix       = 0;
   my @vip_list;

   foreach my $nodename (@nodes) {
      # get IP from DATABASE.NODEAPPS.$nodename.VIP.IP
      open (OCRDUMP, "$ocrdump -stdout -keyname " .
                     "'DATABASE.NODEAPPS.$nodename.VIP.IP'|");
      my @output = <OCRDUMP>;
      close (OCRDUMP);

      my @txt = grep (/ORATEXT/, @output);
      my ($key, $ip) = split (/: /, $txt[0]);
      chomp($ip);

      # get NETMASK from DATABASE.NODEAPPS.$nodename.VIP.NETMASK
      open (OCRDUMP, "$ocrdump -stdout -keyname " .
                     "'DATABASE.NODEAPPS.$nodename.VIP.NETMASK'|");
      my @output = <OCRDUMP>;
      close (OCRDUMP);

      my @txt = grep (/ORATEXT/, @output);
      my ($key, $old_netmask) = split (/: /, $txt[0]);
      chomp($old_netmask);

      # get network interface name
      open (OCRDUMP, "$ocrdump -stdout -keyname " .
                     "'CRS.CUR.ora!$nodename!vip.USR_ORA_IF'|");
      my @output = <OCRDUMP>;
      close (OCRDUMP);

      my @txt = grep (/ORATEXT/, @output);
      my ($key, $intif) = split (/: /, $txt[0]);
      my $new_netmask;
      chomp($intif);

      if ($ip ne "" && $old_netmask ne "") {
         if (validateNetmask($old_netmask, $intif, \$new_netmask)) {
            $vip_list[$ix] = "$ip/$old_netmask";
         } else {
            $vip_list[$ix] = "$ip/$new_netmask";
         }

         $ix++;
      }
   }

   return @vip_list;
}

#Gets the OLD clusterware ONS port information
sub get_ons_port
{
#---------------------------------------------------------------------
# Function: Get the ONS port used by the old version crs
#---------------------------------------------------------------------
   my $node = $_[0];
   my $home;
   my $ONSCONFFILE;
   my $ORA_CRS_HOME = $CFG->ORA_CRS_HOME;
   my @buf2;
   my $Name;
   my $portnum;
   my $useocr;
   my $localport;
   my $remoteport;
   my $locport;
   my $remport;
   my $cmd;
   my $ocrkey;
   my $line;
   my $idx = 0;
 
   # if version is 10.1, use dbhome where ons is configured. Otherwise, use OLD_CRS_HOME.
   my @old_version = @{$CFG->oldconfig('ORA_CRS_VERSION')};
   if ($old_version[0] eq "10" &&
      $old_version[1] eq "1") {
      $home = get101viphome();
   }
   else
   {
      $home = $CFG->OLD_CRS_HOME;
   }
 
   $ONSCONFFILE = catfile( $home, 'opmn' , 'conf', 'ons.config');
   trace("ons conf file is $ONSCONFFILE");
   open(FONS, $ONSCONFFILE) or
        trace("Could not  open \"$ONSCONFFILE\": $!");

   while(<FONS>) {
     if(/^useocr\=on\b/i) { $useocr=$_;  }
     if(/^remoteport\b/i) { $remoteport=$_;  }
     if(/^localport\b/i)  { $localport=$_;  }
   }

   close (FONS);
   #get the remote port
   if (defined($useocr))
   {
      trace("useocr is on . get the remote port from OCR");
      $cmd = catfile( $ORA_CRS_HOME, 'bin', 'ocrdump' );
      $ocrkey = "DATABASE.ONS_HOSTS";
      trace("key to search is $ocrkey");
      my @args = ($cmd, '-stdout', '-keyname', $ocrkey);
      my @out = system_cmd_capture(@args);
      my $rc  = shift @out;
      foreach $line (@out)
      {
       if($line =~ m/DATABASE\.ONS_HOSTS\.$node.*\.PORT\]/i)
       {
          @buf2 = @out[$idx+1];
          last;
       }
       $idx++;
      }
      trace("buf2 is @buf2");
      if (scalar(@buf2) != 0) {
        ($Name, $portnum) = split(/:/, $buf2[0]);
      }
         $remport = trim($portnum);
   }
   else 
   {
    if (defined($remoteport)) {
        ($Name, $portnum) = split(/=/, $remoteport);
        $remport = trim($portnum);
    }
   }
  
   #always get the localport from ons.config if present
   if (defined($localport)) {
     ($Name, $portnum) = split(/=/, $localport);
     $locport = trim($portnum);
   }

   #set 11.2 default values for ons port
   if (! $locport) {
       trace("setting default port  for ons localport");
       $locport = "6100";
   }
   if (! $remport) {
       trace("setting default port  for ons remoteport");
       $remport = "6200";
   }
   return ($locport, $remport);
}


#update ons.config - Bug 8424681

sub update_ons_config
{
   my @nodelist = split(/\,/, $CFG->params('NODE_NAME_LIST'));
   my $node;
   my $host = $CFG->HOST;
   my $str = "nodes="; 
   my $ONSCONFFILE = catfile( $ORACLE_HOME, 'opmn' , 'conf', 'ons.config');
   foreach $node (@nodelist)
   {
    my($onslocport, $onsremport) = get_ons_port($node);
    trace ("ons remoteport for $node is $onsremport");
    if ($node ne $nodelist[-1])
    {
       $str = $str . "$node:$onsremport" . ",";
    }
    else
    {
       $str = $str . "$node:$onsremport";
    }
   }
   trace("ons nodes string is $str");
   my($onslocport, $onsremport) = get_ons_port($host);
   trace("ons conf file is $ONSCONFFILE");
   open(FONS, ">>$ONSCONFFILE") or
        error ("Could not  open \"$ONSCONFFILE\": $!");
   print FONS "remoteport=$onsremport\n";
   print FONS "$str\n";
   close FONS;
}

# Stops the old running crs stack.
sub stop_OldCrsStack
{
  my $OLD_CRS_HOME = $CFG->OLD_CRS_HOME;
  my $status = s_stop_OldCrsStack($OLD_CRS_HOME);
  if (0 == $status) {
      trace ("Old CRS stack stopped successfully");
  } else {
      trace ("Unable to stop Old CRS stack");
      die;
  }
  sleep(60);
}

# Checks if Pre 11.2 crs stack is running.
sub check_OldCrsStack
{
  my $OLD_CRS_HOME = $CFG->OLD_CRS_HOME;
  my $status       = s_check_OldCrsStack($OLD_CRS_HOME);

  if ($status == SUCCESS) {
      trace ("Earlier version Oracle Clusterware is running");
  } else {
      trace ("Earlier version Oracle Clusterware is not running");
      return FAILED;
  }

  return SUCCESS;
}

sub get_oldconfig_info {
  trace ("Get old config info...");

  # Get old CRS home
  my $oldCrsHome = s_getOldCrsHome();
  $CFG->oldconfig('ORA_CRS_HOME', $oldCrsHome);
  $CFG->OLD_CRS_HOME($oldCrsHome);

  # Get old CRS version, use new stack binaries
  my @oldCrsVer = get_crs_version($CFG->ORA_CRS_HOME);
  $CFG->oldconfig('ORA_CRS_VERSION', \@oldCrsVer);

  # Get cluster GUID/OCRID, use new stack binaries
  my $oldClusterID = get_clusterguid($CFG->ORA_CRS_HOME);
  my $oldOCRID     = get_ocrid($CFG->ORA_CRS_HOME);
  $CFG->oldconfig('CLUSTER_GUID', $oldClusterID);
  $CFG->oldconfig('OCRID', $oldOCRID);

  # populate $NETWORK/NODE_NAME_LIST info for upgrade
  my ($networks, $nodes) = get_upgrade_netinfo();
  $CFG->oldconfig('NETWORKS', $networks);
  $CFG->params('NETWORKS', $networks);

  $CFG->oldconfig('NODE_NAME_LIST', $nodes);
  $CFG->params('NODE_NAME_LIST', $nodes);
  
  trace ("  old CrsHome  =$oldCrsHome");
  trace ("  old CrsVer   =@oldCrsVer");
  trace ("  old ClusterID=$oldClusterID");
  trace ("  old OCRID    =$oldOCRID");
  trace ("  old networks =$networks");
  trace ("  old nodes    =$nodes");

  return;
}

=head2 initial_cluster_validation

  Perform validations for the cluster installation as well as
  initializes some component files

=head3 Parameters

  None

=head3 Returns

  None, errors result in termination of the script

=cut

sub initial_cluster_validation {
  my $OLR_LOCATION = $CFG->OLR_LOCATION;
  my $ORA_CRS_HOME = $CFG->ORA_CRS_HOME;
  my $CLUSTER_NAME = $CFG->params('CLUSTER_NAME');
  my $OCR;

  validate_SICSS () or die "validate_SICSS failed";
  validate_9iGSD () or die "validate_9iGSD failed";
  validate_olrconfig ($OLR_LOCATION, $ORA_CRS_HOME)
    or die "Error in validate_olrconfig: $!";

  if ($CFG->ASM_STORAGE_USED) {
     my $diskgroup = $CFG->params('ASM_DISK_GROUP');
     $OCR = "+" . $diskgroup;
  }
  else { $OCR = $CFG->params('OCR_LOCATIONS'); }

  if (! $CFG->UPGRADE)
  {
   validateOCR ($ORA_CRS_HOME, $CLUSTER_NAME, $OCR)
    or die "validateOCR failed for $OCR";
  }

  if (!CSS_CanRunRealtime($CFG)) {
    die("CSS cannot be run in realtime mode");
  }

  if (isAddNode($HOST, $CFG->params('NODE_NAME_LIST'))) {
     if ((isOCRonASM()) && ($CFG->params('CRS_STORAGE_OPTION') != 1))
     {
        $CFG->params('CRS_STORAGE_OPTION', 1);
     }
     elsif ((! isOCRonASM()) && ($CFG->params('CRS_STORAGE_OPTION') == 1))
     {
        $CFG->params('CRS_STORAGE_OPTION', 2);
     }
  }

  return;
}

=head2 wait_for_stack_start

  Wait for the stack to start up

=head3 Parameters

  Number of chcks to see if the stack is up, made every 5 seconds

=head3 Returns

  SUCCESS  Stack is up
  FAILED   Stack is not up

=head3 Usage


=cut

sub wait_for_stack_start {
  # Wait until the daemons actually start up
  my $is_up = FALSE;
  my $retries = shift;
  my $crsctl = crs_exec_path('crsctl');
  my @output;
  my $rc;

  # Complete success. This is the last node of the install.
  # Wait for CRSD and EVMD to start up
  while ($retries) {
    @output = system_cmd_capture($crsctl, 'stat', 'resource');
    $rc	    = shift @output;

    if ($rc == 0) {
      $is_up = TRUE;
      last;
    }

    trace ("Waiting for Oracle CRSD and EVMD to start");
    sleep (5);
    $retries--;
  }

  if ($is_up) {
    trace ("Oracle CRS stack installed and running");
  } else {
    error ("Timed out waiting for the CRS stack to start.");
    exit 1;
  }

  return $is_up;
}

sub upgrade_OCR {
  my $ret = TRUE;

  my @runocrconfig = ("ocrconfig", "-upgrade",
                      $CFG->params('ORACLE_OWNER'),
                      $CFG->params("ORA_DBA_GROUP"));

  # ocrconfig - Create OCR keys
  trace ("Creating or upgrading OCR keys");
  my $status = run_crs_cmd(@runocrconfig);
  if ($status == 0) {
    trace ("OCR keys are successfully populated");
    s_reset_srvconfig () or die "reset srvconfig failed";
  } else {
    error ("Failed to create Oracle Cluster Registry configuration");
    $ret = FALSE;
  }

  return $ret;
}

=head2 new

  This is the class constructor method for this class

=head3 Parameters

  A hash containing values for any key that is listed in the accessor
  methods section

=head3 Returns

  A blessed class

=head3 Usage

  my $cfg = crsconfig_lib->new(
                paramfile           => $PARAM_FILE_PATH,
                osdfile             => $defsfile,
                crscfg_trace        => TRUE,
                HOST                => $HOST
                )

  This creates an object with parameters built from $PARAM_FILE_PATH
  and $defsfile, for HOST $HOST with tracing turned on.  The values
  specified may be retrieved via the standard access methods, e.g.
    my $host = $cfg->HOST;
  will set $host to the $HOST value set in the hash passed to 'new'.

  While it is possible to pass any key/value pair to 'new', even ones
  for which there are no access methods, the values cannot be easily
  used without an access method.  For the list of access methods, see
  the 'Access Methods Section' below

=cut

# Class constructor and methods
sub new {
  my ($class, %init) = @_;
  $CFG = {};
  for my $element (keys %init) {
    $CFG->{$element} = undef;
    if (defined($init{$element})) {
      my $type = $elements{$element};
      $CFG->{$element} = $init{$element};
      if (($type eq 'ARRAY' || $type eq 'HASH') &&
             ref($init{$element}) ne $type) {
        croak "Initializer for $element must be $type reference";
      }
    }
  }

  # Initialize stuff not in the initializer
  for my $element (keys %elements) {
    if (!defined($CFG->{$element})) {
      my $type = $elements{$element};
      if ($type eq 'ARRAY') { $CFG->{$element} = []; }
      elsif ($type eq 'HASH') { $CFG->{$element} = {}; }
      elsif ($type eq 'COUNTER') { $CFG->{$element} = 0; }
    }
  }

  bless $CFG, $class;

  if (! $CFG->paramfile) {
    die("No configuration parameter file was specified");
  }

  if (! -e $CFG->paramfile) {
    die("Configuration parameter file", $CFG->paramfile,
        "cannot be found");
  }

  print ("Using configuration parameter file: ", $CFG->paramfile, "\n");

  # Set up the parameters
  setup_param_vars($CFG->paramfile);

  # Now set various defaults/values based on various input
  my $OH = $CFG->params('ORACLE_HOME'); # for convenience

  if ($OH) { trace("Using Oracle CRS home $OH"); }
  else {
    die("The Oracle CRS home path not found in the configuration",
        "parameters");
  }

  if (!(-d $OH)) {
    die("The Oracle CRS home path \"$OH\" does not exist");
  }

  my $default_trc_dir = catfile($OH, 'cfgtoollogs', 'crsconfig');
  my $default_olr_dir = catfile($OH, 'cdata');

  if ($CFG->IS_SIHA) { # Define stuff for SIHA
    $CFG->parameters_valid($CFG->validateSIHAVarList);


    # trace file
    if (!$CFG->crscfg_trace_file) {
       my $file = "roothas.log";
       if ($CFG->CRSDelete) { $file = "hadelete.log"; }
       if ($CFG->HAPatch)   { $file = "hapatch.log"; }

       $CFG->crscfg_trace_file(catfile($default_trc_dir, $file));
    }

    if (!$CFG->OLR_DIRECTORY) {
      $CFG->OLR_DIRECTORY(catfile($default_olr_dir, 'localhost'));
    }
  }
  else { # Define stuff for clustered mode
    $CFG->parameters_valid(validateCRSVarList());
    if (!$CFG->crscfg_trace_file) {
      my $host = $CFG->HOST;
      my $file = "rootcrs_$host.log";
      if ($CFG->CRSDelete) { $file = "crsdelete_$host.log"; }
      if ($CFG->CRSPatch)  { $file = "crspatch_$host.log"; }
      if ($CFG->DOWNGRADE) { $file = "crsdowngrade_$host.log"; }

      $CFG->crscfg_trace_file(catfile($default_trc_dir, $file));
    }

    if (!$CFG->OLR_DIRECTORY) {
      $CFG->OLR_DIRECTORY($default_olr_dir);
    }
  }

  # We really should destroy $CFG here; this will be impelmented later
  if ($CFG->parameters_valid) {
    trace("The configuration parameter file", $CFG->paramfile,
          "is valid");
  }
  else {
    die("The configuration parameter file", $CFG->paramfile,
        "is not valid");
  }

  if ($CFG->osdfile && -e $CFG->osdfile) {
    setup_param_vars($CFG->osdfile);
  }

  if ($CFG->addfile && -e $CFG->addfile) {
    setup_param_vars($CFG->addfile);
  }

  $CFG->SUPERUSER(check_SuperUser());

  if ($CFG->SUPERUSER) { $CFG->user_is_superuser(TRUE); }
  else {
    # If we are not SUPERUSER, indicate this and set SUPERUSER to
    # ORACLE_OWNER
    $CFG->user_is_superuser(FALSE);
    $CFG->SUPERUSER($CFG->params('ORACLE_OWNER'));
  }

  # Set some default values, if necessary
  if (!$CFG->ORA_CRS_HOME) {
    $CFG->ORA_CRS_HOME($CFG->params('ORACLE_HOME'));
  }

  if (!$CFG->HOST) { $CFG->HOST(tolower_host()); }

  $CFG->OLR_LOCATION(catfile($CFG->OLR_DIRECTORY, $CFG->HOST . '.olr'));

  if ($CFG->SUPERUSER &&
      $CFG->defined_param('OLASTGASPDIR') &&
      ! -e $CFG->params('OLASTGASPDIR')) {
    mkpath($CFG->params('OLASTGASPDIR'));
  }

  if (!$CFG->HAS_USER) {
    $CFG->HAS_USER($CFG->params('ORACLE_OWNER'));
  }

  if (!$CFG->HAS_GROUP) {
    $CFG->HAS_GROUP($CFG->params('ORA_DBA_GROUP'));
  }

  if (!$CFG->s_run_as_user2p) {
    $CFG->s_run_as_user2p(\&crsconfig_lib::s_run_as_user2);
  }

  if (!$CFG->s_run_as_userp) {
    $CFG->s_run_as_userp(\&crsconfig_lib::s_run_as_user);
  }

  # If the versions of the 'run_as user' commands with parm order
  # reversed exist, as inidicated in the sybol table, set them now
  if (!$CFG->s_run_as_user2_v2p &&
      defined($s_crsconfig_lib::{'s_run_as_user2_v2'})) {
    $CFG->s_run_as_user2p_v2(\&crsconfig_lib::s_run_as_user2_v2);
  }

  if (!$CFG->s_run_as_user_v2p && 
      defined($s_crsconfig_lib::{'s_run_as_user_v2'})) {
    $CFG->s_run_as_userp_v2(\&crsconfig_lib::s_run_as_user_v2);
  }

  if (! $CFG->UPGRADE) {
    if ($CFG->ASM_STORAGE_USED) {
      # Put a null string in for VF discover string so that the change
      # will not be rejected (bug 7694835)
      $CFG->VF_DISCOVERY_STRING('');
    }
    else {
      if (! $CFG->IS_SIHA) {
        if ($CFG->defined_param('VOTING_DISKS'))
        {
           $CFG->VF_DISCOVERY_STRING($CFG->params('VOTING_DISKS'));
        }
        else
        {
           $CFG->VF_DISCOVERY_STRING('');
        }
      }
    }
  }

  $CFG->platform_family(lc(s_get_platform_family()));

  # To allow s_crsconfig_lib functions to work until they have been
  # properly packaged, put some variables into the global domain
  export_vars();

  $CFG->print_config;

  # set owner & permission of trace file
  s_set_ownergroup ($CFG->params('ORACLE_OWNER'),
                    $CFG->params('ORA_DBA_GROUP'),
                    $CFG->crscfg_trace_file);
  s_set_perms ("0775", $CFG->crscfg_trace_file);

  return $CFG;
}

# Access Methods Section
#   This section contains the accessor method used in this class
#
# Adding a new accessor method:
#   Unless the accessor method must do something special, use the
#   standard access methods:
#     access_array  - get/set a value from/in an array
#     access_hash   - get/set a value from/in an hash
#     access_scalar - get/set a scalar value
#
# Examples:
#   (scalar FOOS)
#     (method definition) sub FOOS {return access_scalar(@_);}
#     (value set)   $CFG->FOOS('BARS'); (sets $CFG->FOOS to 'BARS')
#     (value get)   my $foos = $CFG->FOOS;
#
#   (array FOOA)
#     (method definition) sub FOOA {return access_array(@_);}
#     (value set)   $CFG->FOOA(0, 'BARA'); (sets FOOA[0])
#     (value set)   $CFG->FOOA(\@BARA); (sets FOOA array to @BARA)
#     (value get)   my $fooa0 = $CFG->FOOA(0); (gets FOOA[0])
#     (value get)   my @fooa = @{$CFG->FOOA}; (gets @FOOA)
#
#   (hash FOOH)
#     (method definition) sub FOOH {return access_hash(@_);}
#     (value set)   $CFG->FOOH('BARk', 'BARv'); (sets FOOH key BARk to BARv)
#     (value set)   $CFG->FOOH(\%BARH); (sets $CFG->FOOH to %BARH)
#     (value get)   my $barv = $CFG->FOOH('BARk'); (gets FOOH{'BARk'})
#     (value get)   my %fooh = %{$CFG->FOOH}; (gets %FOOH)
#
#   (counter FOOC) initial value preset to 0
#     (method definitions)
#        sub FOOC {return access_counter(@_);}
#        sub pp_FOOC {return access_counter(@_);}
#        sub FOOC_pp {return access_counter(@_);}
#     (value get - assuming a current value of 3)
#        (no value change)
#          my $cval = $CFG->FOOC; (returns 3, current value still 3)
#        (increment before returning ++FOOC)
#          my $cval = $CFG->pp_FOOC; (returns 4, current value now 4)
#        (increment after returning FOOC++)
#          my $cval = $CFG->FOOC_pp; (returns 3, current value now 4)


# Accessor methods for class elements
sub CLSCFG_EXTRA_PARMS  { return access_array(@_); }
sub CLSCFG_POST_CMD     { return access_array(@_); }
sub CRSCFG_POST_CMD     { return access_array(@_); }
sub CRSDelete           { return access_scalar(@_); }
sub DEBUG               { return access_scalar(@_); $DEBUG = $CFG->DEBUG; }
sub HAS_GROUP           { return access_scalar(@_); }
sub HAS_USER            { return access_scalar(@_); }
sub HOST                { return access_scalar(@_); }
sub IS_SIHA             { return access_scalar(@_); }
sub OCR_ID              { return access_scalar(@_); }
sub ORA_CRS_HOME        { return access_scalar(@_); }
sub SUPERUSER           { return access_scalar(@_); }
sub VF_DISCOVERY_STRING { return access_scalar(@_); }
sub OLR_DIRECTORY       { return access_scalar(@_); }
sub OLR_LOCATION        { return access_scalar(@_); }
sub UPGRADE             { return access_scalar(@_); }
sub DOWNGRADE           { return access_scalar(@_); }
sub OLD_CRS_HOME        { return access_scalar(@_); }
sub NETWORKS            { return access_scalar(@_); }
sub addfile             { return access_scalar(@_); }
sub gpnp_setup_type     { return access_scalar(@_); }
sub hosts               { return access_array(@_); }
sub osdfile             { return access_scalar(@_); }
sub paramfile           { return access_scalar(@_); }
sub parameters_valid    { return access_scalar(@_); }
sub platform_family     { return access_scalar(@_); }
sub user_is_superuser   { return access_scalar(@_); }
sub oldconfig           { return access_hash(@_); }
sub s_run_as_user2p     { return access_scalar(@_); }
sub s_run_as_user2_v2p  { return access_scalar(@_); }
sub s_run_as_userp      { return access_scalar(@_); }
sub s_run_as_user_v2p   { return access_scalar(@_); }
sub unlock_crshome      { return access_scalar(@_); }
sub hahome              { return access_scalar(@_); }
sub CRSPatch            { return access_scalar(@_); }
sub HAPatch             { return access_scalar(@_); }
sub oldcrshome          { return access_scalar(@_); }
sub oldcrsver           { return access_scalar(@_); }
sub force               { return access_scalar(@_); }
sub lastnode            { return access_scalar(@_); }

# Counters
# pp_ for increment before, eg pp_foo same as ++foo
# _pp for increment after, eg foo_pp same as foo++
# both take an argument for increment amount (default increment is 1)
sub srvctl_trc_suff     { return access_counter(@_); }
sub pp_srvctl_trc_suff  { return access_counter(@_); } # ++srvctl_trc_suff
sub srvctl_trc_suff_pp  { return access_counter(@_); } # srvctl_trc_suff++

sub GPNP_GPNPHOME_DIR   { return access_scalar(@_); }
sub GPNP_WALLETS_DIR    { return access_scalar(@_); }
sub GPNP_W_ROOT_DIR     { return access_scalar(@_); }
sub GPNP_W_PEER_DIR     { return access_scalar(@_); }
sub GPNP_W_PRDR_DIR     { return access_scalar(@_); }
sub GPNP_W_PA_DIR       { return access_scalar(@_); }
sub GPNP_PROFILES_DIR   { return access_scalar(@_); }
sub GPNP_P_PEER_DIR     { return access_scalar(@_); }

# -- local
sub GPNP_GPNPLOCALHOME_DIR { return access_scalar(@_); }
sub GPNP_L_WALLETS_DIR  { return access_scalar(@_); }
sub GPNP_L_W_ROOT_DIR   { return access_scalar(@_); }
sub GPNP_L_W_PEER_DIR   { return access_scalar(@_); }
sub GPNP_L_W_PRDR_DIR   { return access_scalar(@_); }
sub GPNP_L_W_PA_DIR     { return access_scalar(@_); }
sub GPNP_L_PROFILES_DIR { return access_scalar(@_); }
sub GPNP_L_P_PEER_DIR   { return access_scalar(@_); }

# gpnp files:

# -- cluster-wide
sub GPNP_ORIGIN_FILE   { return access_scalar(@_); }
sub GPNP_W_ROOT_FILE   { return access_scalar(@_); }
sub GPNP_WS_PA_FILE    { return access_scalar(@_); }
sub GPNP_WS_PEER_FILE  { return access_scalar(@_); }
sub GPNP_WS_PRDR_FILE  { return access_scalar(@_); }
sub GPNP_C_ROOT_FILE   { return access_scalar(@_); }
sub GPNP_C_PA_FILE     { return access_scalar(@_); }
sub GPNP_C_PEER_FILE   { return access_scalar(@_); }
sub GPNP_P_PEER_FILE   { return access_scalar(@_); }
sub GPNP_P_SAVE_FILE   { return access_scalar(@_); }

# -- local
sub GPNP_L_W_ROOT_FILE { return access_scalar(@_); }
sub GPNP_L_W_PA_FILE   { return access_scalar(@_); }
sub GPNP_L_WS_PA_FILE  { return access_scalar(@_); }
sub GPNP_L_W_PEER_FILE { return access_scalar(@_); }
sub GPNP_L_WS_PEER_FILE { return access_scalar(@_); }
sub GPNP_L_WS_PRDR_FILE { return access_scalar(@_); }
sub GPNP_L_CRQ_PA_FILE { return access_scalar(@_); }
sub GPNP_L_CRQ_PEER_FILE { return access_scalar(@_); }
sub GPNP_L_C_ROOT_FILE { return access_scalar(@_); }
sub GPNP_L_C_PA_FILE   { return access_scalar(@_); }
sub GPNP_L_C_PEER_FILE { return access_scalar(@_); }
sub GPNP_L_P_PEER_FILE { return access_scalar(@_); }
sub GPNP_L_P_SAVE_FILE { return access_scalar(@_); }

# gpnp peer wrls
sub GPNP_W_PEER_WRL { return access_scalar(@_); }
sub GPNP_L_W_PEER_WRL { return access_scalar(@_); }
sub GPNP_W_PRDR_WRL { return access_scalar(@_); }
sub GPNP_L_W_PRDR_WRL { return access_scalar(@_); }

# package tools
sub GPNP_E_GPNPTOOL { return access_scalar(@_); }
sub GPNP_E_GPNPSETUP { return access_scalar(@_); }

sub config_value { return $_[0]->{$_[1]}; }

sub params {
  my $cfg = shift;

  # If the parameter has not been defined, error.  This prevents
  # typos from going unnoticed
  if (scalar(@_) == 1 && !defined($cfg->{'params'}->{$_[0]})) {
    die ("Parameter $_[0] not defined");
  }
  else { return access_hash($cfg, @_); }
}

sub defined_param {
  my $cfg = shift;
  my $defd = FALSE;
  if (scalar(@_) > 1) { croak "Only 1 parameter allowed: @_"; }
  else { $defd = defined($cfg->{'params'}->{$_[0]}); }

  return $defd;
}

sub defined_value {
  my $cfg = shift;
  my $defd = FALSE;
  if (scalar(@_) > 1) { croak "Only 1 parameter allowed: @_"; }
  else { $defd = defined($cfg->{$_[0]}); }

  return $defd;
}

sub ASM_STORAGE_USED {
  my $cfg = shift;
  my $val;
  my $ret;
  if (@_) { # Setting the value, so keep params in sync
    $ret = shift;
    if ($ret) { $cfg->params('CRS_STORAGE_OPTION', 1); }
    else { $cfg->params('CRS_STORAGE_OPTION', 2); }
  }
  elsif ($cfg->params('CRS_STORAGE_OPTION') == 1) { $ret = TRUE; }
  else { $ret = FALSE; }

  return $ret;
}

# If tracing is turned on after initialization, make sure directory is
# created
sub crscfg_trace {
  my $ret = access_scalar(@_);
  # if the call was to turn tracing on, make sure trace dir created
  if ($ret && scalar(@_) > 1) { setup_trace_dir(); }
  return $ret;
}

sub crscfg_trace_file {
  my $ret = access_scalar(@_);
  # if the call was set the file name, make sure trace dir created
  if (scalar(@_) > 1) { setup_trace_dir(); }
  return $ret;
}

###### End Access Methods Section #######

# Set up the trace directory
sub setup_trace_dir {
  if ($CFG->crscfg_trace &&
      $CFG->crscfg_trace_file &&
      ! -e $CFG->crscfg_trace_file) {
    my $trace_dir = dirname($CFG->crscfg_trace_file);
    if (! -e $trace_dir) {
      my $tracing = $CFG->crscfg_trace;

      print "Creating trace directory\n";
      # temporarily turn off tracing to avoid recursing in create_dir
      $CFG->crscfg_trace(0);
      create_dir($trace_dir);
      $CFG->crscfg_trace($tracing);
    }
  }
}

# Execute a command as a user (do not invoke directly, use run_as_user)
sub s_run_as_usere {
  my $cfg = shift;
  my $user = shift;
  my $pgm = $cfg->s_run_as_userp;
  my @args = ("@_", $user);
  if ($cfg->s_run_as_user_v2p) {
    $pgm = $cfg->s_run_as_user_v2p;
    @args = ($user, @_);
  }
  return &$pgm(@args);
}

# Execute a command as a user, returning the output
# (do not invoke directly, use run_as_user2)
sub s_run_as_user2e {
  my $cfg = shift;
  my $user = shift;
  my $aref = shift;
  my $rc;
  my @args = (\@_, $user, $aref);
  if (!$cfg->s_run_as_user2_v2p) {
    my $pgm  = $cfg->s_run_as_user2p;;
    $rc = &$pgm(\@_, $user, $aref);
  }
  else {
    my $pgm = $cfg->s_run_as_user2_v2p;
    my @out = &$pgm($user, @_);
    $rc = shift @out;
    @{$aref} = @out;
  }
  return $rc;
}

# Low level access methods
sub access_scalar {
  my $class  = shift;

  # find where we were called from so that we know what element
  # Get callers name
  my @caller = caller(1);

  my $name = $caller[3];
  # strip class name to get element name
  my $class_name = ref($class);
  $name =~ s/$class_name\:\://;

  my $ret;
  if (@_ > 1) { croak "Too many args to $name"; }
  if (@_) {$ret = shift; $class->{$name} = $ret; }
  else { $ret = $class->{$name}; }

  return $ret;
}

sub access_array {
  my $class  = shift;

  # find where we were called from so that we know what element
  # Get callers name
  my @caller = caller(1);

  my $name = $caller[3];
  # strip class name to get element name
  my $class_name = ref($class);
  $name =~ s/$class_name\:\://;

  my $init;
  my $ret;

  if (! @_) { $ret = $class->{$name}; }
  else {
    $init = shift;
    if (ref($init) eq 'ARRAY' && !@_) {
      $class->{$name} = $init;
      $ret = $class->{$name};
    }
    elsif (@_ > 1) { croak "Too many args to $name"; }
    elsif (@_) { $class->{$name}->[$init] = $ret = shift; }
    else { $ret = $class->{$name}->[$init]; }
  }

  return $ret;
}

sub access_hash {
  my $class  = shift;

  # find where we were called from so that we know what element
  # Get callers name
  my @caller = caller(1);

  my $name = $caller[3];
  # strip class name to get element name
  my $class_name = ref($class);
  $name =~ s/$class_name\:\://;

  my $init;
  my $ret;
  if (! @_) { $ret = $class->{$name}; }
  else {
    $init = shift;
    if (ref($init) eq 'HASH' && !@_) {
      $class->{$name} = $init;
      $ret = $class;
    }
    elsif (@_ > 1) { croak "Too many args to $name"; }
    elsif (@_) { $class->{$name}->{$init} = $ret = shift; }
    else { $ret = $class->{$name}->{$init}; }
  }

  return $ret;
}

sub access_counter {
  my $class  = shift;

  # find where we were called from so that we know what element
  # Get callers name
  my @caller = caller(1);

  my $name = $caller[3];
  # strip class name to get element name
  my $class_name = ref($class);
  $name =~ s/$class_name\:\://;

  my $elt_name = $name;
  my $pre  = $elt_name =~ s/^pp_//;
  my $post = $elt_name =~ s/_pp$//;

  my $ret = $class->{$elt_name};
  my $incr = 1;
  if (@_ > 1) { croak "Too many args to $name: @_"; }

  if (@_) { $incr = shift; }
  if ($pre) { $class->$elt_name(($ret += $incr)); }
  elsif ($post) { $class->$elt_name($ret + $incr); }

  return $ret;
}

sub StopCRS
#-------------------------------------------------------------------------------
# Function: Stop CRS
# Args    : 0
# Returns : TRUE  if success
#           FALSE if failed
#-------------------------------------------------------------------------------
{
   my $crsctl = crs_exec_path("crsctl");
   my $success = TRUE;

   if (! -x $crsctl) {
      error ("$crsctl does not exist to proceed with -unlock option");
      return FALSE;
   }

   trace ("Stop Oracle Clusterware...");

   # stop cluster
   trace ("stop crs...");
   system ("$crsctl stop crs -f");

   if (! checkServiceDown("cluster")) {
      print "You must kill crs processes or reboot the system to properly \n";
      print "cleanup the processes started by Oracle clusterware\n";
      return FALSE;
   }

   # check if ohasd & crs are still up
   if (! checkServiceDown("ohasd")) {
      error "Unable to stop CRS\n";
      $success = FALSE;
   }

   return $success;
}

sub unlockHAHome
{
   trace ("Unlock Oracle Restart home...");
   my $unlock_hahome;

   #Try to get the home path from olr.loc
   $unlock_hahome = s_get_olr_file ("crs_home");
   trace ("Home location in olr.loc is $unlock_hahome");

   if (! $unlock_hahome)
   {
      $unlock_hahome = $CFG->hahome;
   }

   # validate if crshome exists
   if (! -e $unlock_hahome) {
      error  "Oracle Restart home: $unlock_hahome not found\n";
      return FALSE;
   }

   my $CRSCTL = catfile ($unlock_hahome, "bin", "crsctl");
   
   # stop ohasd
   trace ("Stopping Oracle Restart");

   trace ("$CRSCTL stop has -f");
   system ("$CRSCTL stop has -f");

   # Allow HA daemons to shutdown in 10sec
   sleep 10;

   # check the status of HA stack
   if (checkServiceDown("ohasd")) {
      s_reset_crshome($ORACLE_OWNER, $ORA_DBA_GROUP, 755, $unlock_hahome);
      print "Successfully unlock $unlock_hahome\n";
   }
   else { 
      print "The Oracle Restart stack failed to stop.\n";
      print "You should stop the stack with 'crsctl stop has' and rerun the command\n";
   }
}

sub unlockCRSHome
{
   trace ("Unlock crshome...");

   my $unlock_crshome;

   #Try to get the home path from olr.loc
   $unlock_crshome = s_get_olr_file ("crs_home");
   trace ("Home location in olr.loc is $unlock_crshome");

   if (! $unlock_crshome)
   {
      $unlock_crshome = $CFG->unlock_crshome;
   }

   # validate if crshome exists
   if (! -e $unlock_crshome) {
      error  "crshome: $unlock_crshome not found\n";
      return FALSE;
   }

   if (StopCRS()) {
      s_reset_crshome($ORACLE_OWNER, $ORA_DBA_GROUP, 755, $unlock_crshome);
      print "Successfully unlock $unlock_crshome\n";
   } else {
      print "The Oracle Clusterware stack failed to stop.\n";
      print "You should stop the stack with 'crsctl stop crs' and rerun the command\n";
   }
}

sub isRAC_appropriate
#-------------------------------------------------------------------------------
# Function:  Check if rac_on/rac_off on Unix
# Args    :  none
# Returns :  TRUE  if rac_on/rac_off     needs to be set
#            FALSE if rac_on/rac_off not needs to be set
#-------------------------------------------------------------------------------
{
   my $myplatformfamily = s_get_platform_family ();
   $myplatformfamily =~ tr/A-Z/a-z/;

   if ($myplatformfamily eq "unix") {
      return s_isRAC_appropriate ();
   } 
   else {
      return TRUE
   }
}

sub deconfigure_ASM {
   trace ("De-configuring ASM...");

   my $crsctl	       = catfile ($CFG->ORA_CRS_HOME, 'bin', 'crsctl');
   my $owner 	       = $CFG->params('ORACLE_OWNER');
   my $start_exclusive = FALSE;
   my $rc              = FALSE;
   my $status;

   # Check if CRS is up
   my $crs_is_up  = check_service ("ohasd", 2);
   my $cluster_is_up = check_service ("cluster", 2);

   if (!$crs_is_up) {
     trace("OHASD is not up. So starting clusterware exclusive");
     start_service("crsexcl"); 
     $crs_is_up = TRUE;
   }
   else {
     trace("OHASD is already up");

     if (!$cluster_is_up){
       trace("Starting CSS exclusive");
       $start_exclusive = TRUE;
       my $css_rc = CSS_start_exclusive();
       if ($css_rc != CSS_EXCL_SUCCESS) {
         $start_exclusive = FALSE;
         trace ("CSS failed to enter exclusive mode to de-configure ASM");
       }
     }
   }

   if (($crs_is_up) || ($start_exclusive)) {
      # delete voting disks on ASM
      if (! CSS_delete_vfs ()) {
 	 trace ("Unable to delete voting files in exclusive mode");
         return FALSE;
      }

      # start ora.asm resource
      if (! start_resource("ora.asm", "-init")) {
         trace ("Unable to start ora.asm resource to deconfigure ASM");
         return FALSE;
      }
   }
    
   # call asmca -deleteLocalASM to delete diskgroup
   # Do not change the order of these parameters as asmca requires the
   # parameters to be in a specific order or it will fail
   my @runasmca = (catfile ($CFG->ORA_CRS_HOME, "bin", "asmca"),
                   '-silent', '-deleteLocalASM');

   if ($CFG->params('ASM_DISK_GROUP') ){
      my $diskgroup = $CFG->params('ASM_DISK_GROUP');
      if ($diskgroup =~ /\$/) {
         # if diskgroup contains '$', put single-quotes around it
         quoteDiskGroup($diskgroup);
         push @runasmca, '-diskGroups', "'$diskgroup'";
      }
      else {
         push @runasmca, '-diskGroups', $diskgroup;
      }
   }

   if (($CFG->defined_param('ASM_DISKSTRING')) && ($CFG->params('ASM_DISKSTRING'))) {
      my $disktring = $CFG->params('ASM_DISKSTRING');
      push @runasmca, '-diskString', "'$disktring'";
   }

   if ($CFG->params('NODE_NAME_LIST')) {
      push @runasmca, '-nodeList', $CFG->params('NODE_NAME_LIST');
   }

   $ENV{'PARAM_FILE_NAME'} = $CFG->paramfile;
   $status = run_as_user($owner, @runasmca);

   if ($status == 0) {
      trace ("de-configuration ASM ... success, see logs for details");
      $rc = TRUE;
   }
   else {
      error ("de-configuration ASM ... failed, see logs for details");
   }

   return $rc;
}

sub isCRSAlreadyConfigured
#-------------------------------------------------------------------------------
# Function: Check if CRS is already configured on this node
# Args    : none
# Return  : TRUE  if CRS is     already configured
# 	    FALSE if CRS is not already configured
#-------------------------------------------------------------------------------
{
   my $value;
   my $olr_exists = FALSE;
   my $localOCR_exists = FALSE;
   my $crs_exists = s_check_CRSConfig($CFG->HOST, 
				      $CFG->params('ORACLE_OWNER'));

   if (-e $OLRCONFIG) {
      $value = s_get_olr_file ("crs_home");
      if ($value) {
         $olr_exists = TRUE;
      }
   }

   if (-e $OCRCONFIG) {
      $value = local_only_config_exists();
      if ($value) {
         $localOCR_exists = TRUE;
      }
   }

   if ($olr_exists && $crs_exists) {
      print "CRS is already configured on this node for crshome=$value\n";
      print "Cannot configure two CRS instances on the same cluster.\n";
      print "Please deconfigure before proceeding with the " .
            "configuration of new home. \n";
      trace ("CRS is already configured on this node for crshome=$value");
      trace ("Cannot configure two CRS instances on the same cluster.");
      trace ("Please deconfigure before proceeding with the " .
             "configuration of new home. ");
      return TRUE;
   }
   elsif ((! $olr_exists) && (! $crs_exists)) {
      trace ("CRS is not yet configured. Hence, will proceed to configure CRS");
      return FALSE;
   }
   elsif ($CFG->UPGRADE && (! $olr_exists)) {
      return FALSE;
   }
   elsif (!$CFG->UPGRADE && (! $olr_exists) && ($localOCR_exists)) {
      return FALSE;
   }
   else {
      print "Improper Oracle Clusterware configuration found on this host\n";
      print "Deconfigure the existing cluster configuration before starting\n";
      print "to configure a new Clusterware \n";
      print "run \'$ORACLE_HOME/crs/install/rootcrs.pl -deconfig\' \n";
      print "to configure existing failed configuration and then rerun root.sh\n";
      trace ("Improper Oracle Clusterware configuration found on this host");
      trace ("Deconfigure the existing cluster configuration before starting");
      trace ("to configure a new Clusterware");
      trace ("run \'$ORACLE_HOME/crs/install/rootcrs.pl -deconfig\' ");
      trace ("to deconfigure existing failed configuration and then rerun root.sh");
      return TRUE;
   }
}

sub isInterfaceValid
#-------------------------------------------------------------------------------
# Function:  Check if interface is valid
# Args    :  none
#-------------------------------------------------------------------------------
{
   my $networks       = $CFG->params('NETWORKS');
   my $rc             = FALSE;
   my @interface_list = split (/,/, $networks);

   my $pi_count = 0;
   foreach my $interface (@interface_list) {
      if ($interface =~ /\bcluster_interconnect\b/) {
         $pi_count++;
      }
   }

   # if more than 1 interface, at least 1 private interface
   # otherwise, it's invalid
   if (scalar(@interface_list) == 1 ||
      (scalar(@interface_list) > 1 && $pi_count >= 1)) {
      $rc = TRUE;
   } else {
      print  "Invalid interface. There are more than one interface,\n";
      print  "but there is no private interface specified\n";
      trace ("Invalid interface. There are more than one interface,");
      trace ("but there is no private interface specified");
   }

   return $rc;
}

sub configureCvuRpm
#------------------------------------------------------------------------------
# Function:  Install cvuqdisk rpm on Linux 
# Args    :  none
#-------------------------------------------------------------------------------
{
   my $platform_family = s_get_platform_family ();

   if ($platform_family eq "unix")
   {
      s_configureCvuRpm();
   }
}

sub createLocalOnlyOCR
#-------------------------------------------------------------------------------
# Function:  Create local-only OCR
# Args    :  none
#-------------------------------------------------------------------------------
{
   trace ("create Local Only OCR...");

   my $IS_SIHA    = $CFG->IS_SIHA;
   my $owner      = $CFG->params('ORACLE_OWNER');
   my $dba_group  = $CFG->params('ORA_DBA_GROUP');
   my $local_ocr  = catfile ($ORACLE_HOME, "cdata", "localhost", "local.ocr");

   s_createLocalOnlyOCR();
   
   # create local.ocr and set ownergroup
   open (FILEHDL, ">$local_ocr") or die "Unable to open $local_ocr: $!";
   close (FILEHDL);
   s_set_ownergroup ($owner, $dba_group, $local_ocr)
                or die "Can't change ownership on $local_ocr: $!";
   s_set_perms ("0640", $local_ocr)
                or die "Can't set permissions on $local_ocr: $!";


   # validate local.ocr and update ocr.loc
   validate_ocrconfig ($local_ocr, $IS_SIHA)
                or die "Error in validate_ocrconfig: $!";

}
sub checkServiceDown
#---------------------------------------------------------------------
# Function: Check if service is down
# Args    : 1 - service
# Returns : TRUE  if service is down
#           FALSE if service is up
#---------------------------------------------------------------------
{
   my $srv      = $_[0];
   my $crsctl   = catfile ($ORACLE_HOME, "bin", "crsctl");
   my $srv_down = FALSE;
   my $grep_val;
   my $cmd;
   my $node;
   my @cmdout;

   # for OHASD, we need to grep for CRS-4639
   if ($srv eq "ohasd") {
      $grep_val = "4639";
      $cmd      = "$crsctl check has";
   } elsif ($srv eq "cluster") {
      $grep_val = "4639";
      $cmd      = "$crsctl check cluster -n $HOST";
   } elsif ($srv eq "css") {
      $grep_val = "4639";
      $cmd      = "$crsctl check css";
   }

   my @chk = system_cmd_capture($cmd);
   my $rc  = shift @chk;

   if ($grep_val) {
      @cmdout = grep(/$grep_val/, @chk);
   }

   # if scalar(@cmdout) > 0, we found the msg we were looking for
   if (($grep_val && scalar(@cmdout) > 0) ||
       (!$grep_val && $rc == 0)) {
      $srv_down = TRUE;
   }

   return $srv_down;
}

sub isASMExists
#-------------------------------------------------------------------------------
# Function:  Check if ASM exists
# Args    :  none
# Returns :  TRUE  if     exists
#            FALSE if not exists
#-------------------------------------------------------------------------------
{
   my $crs_home = $CFG->ORA_CRS_HOME;
   my $host     = $CFG->HOST;
   my $crs_stat = catfile ($crs_home, 'bin', 'crs_stat');

   open (CRSSTAT, "$crs_stat |");

   # temporarely using crs_stat to find pre 11.2 ASM
   # grep "ora.$host*asm"
   my @txt = grep /ora.$host.*asm/, <CRSSTAT>;

   close (CRSSTAT);

   if (scalar(@txt) == 0) {
      trace ("check ASM exists done and ASM does not exist");
      return FALSE;
   }

   return TRUE;
}
      
sub setActiveversion
{
   my $crsctl  = catfile ($CFG->ORA_CRS_HOME, 'bin', 'crsctl');
   my @cmd     = ($crsctl, 'set', 'crs', 'activeversion');
   my $status  = system (@cmd);

   if (0 == $status) {
      trace ("@cmd ... passed");
      sleep(60);  # Wait until CRS changes to new engine
   } else {
      error ("@cmd ... failed");
      return FAILED;
   }

   return SUCCESS;
}

sub getUpgradeConfig
{
   get_oldconfig_info();

   my @crs_version = @{$CFG->oldconfig('ORA_CRS_VERSION')};
   trace ("crs version=@crs_version");

   #Check if Old Clusterware is running
   my $old_crs_running = check_OldCrsStack();

   if (($crs_version[0] eq '10' && $crs_version[1] eq '1') &&
       (! isNodeappsExists())) {
      my $crs_nodevips = $CFG->params('CRS_NODEVIPS');
      if ($crs_nodevips eq "") {
         error ("Set CRS_NODEVIPS in crsconfig_params and rerun rootupgrade.sh");
	 error ("The format as follows: ");
	 error ("     CRS_NODEVIPS='node1-vip/node1-netmask/node1-interface," .
	 	"		    node2-vip/node2-netmask/node2-interface'");
         exit 1;
      } else {
         $crs_nodevips    =~ s/'//g; # ' in comment to avoid confusion of editors.
         $crs_nodevips    =~ s/"//g; # remove " on Windows
         @crs_nodevip_list_old = split (/\s*,\s*/, $crs_nodevips);
      }
   } 
   else {
      if ($old_crs_running) {  #stack is running
         # Retrieve VIP config info from old stack
         @crs_nodevip_list_old = get_OldVipInfo();
      } 
      else {
         @crs_nodevip_list_old = get_OldVipInfoFromOCRDump();
      }
   }

   if ($old_crs_running) {
     # stop the stack if it is already running.
     stop_OldCrsStack();
   }

   trace("crs_nodevip_list_old=@crs_nodevip_list_old");

   # update ons.config file
   update_ons_config();

   my $vfds = CSS_get_old_VF_string();
   $CFG->VF_DISCOVERY_STRING($vfds);
   if (! $CFG->VF_DISCOVERY_STRING) {
      die("Cannot complete the upgrade without the voting file list");
   }

   trace ("Voting file discovery string:", $CFG->VF_DISCOVERY_STRING);

   # Prepare the voting files for upgrade; if there is an error here
   # it should not be considered fatal, since this is only an attempt
   # to correct a case where a voting file's skgfr block 0 was
   # overwritten, which is not likely to have happened
   $CFG->CSS_prep_old_VFs();
}

sub validateNetmask
#-------------------------------------------------------------------------------
# Function: Validate netmask 
# Args    : [0] - old netmask
#	    [1] - network interface 
#	    [1] - new netmask
# Returns : TRUE  if success
#	    FALSE if failed
#	    new netmask
#-------------------------------------------------------------------------------
{
   my $old_netmask 	= $_[0];
   my $netif		= $_[1];
   my $new_netmask_ref 	= $_[2];
   my $oifcfg	   	= catfile($CFG->params('ORACLE_HOME'), 'bin', 'oifcfg');
   my $success		= TRUE;
   $$new_netmask_ref 	= "";

   open OPUT, "$oifcfg iflist -p -n |";

   if ($netif) { #not null
      my @output = grep { /\b$netif\b/i } (<OPUT>);

      if (scalar(@output) == 0) { #not found
	 error("Unable to find netmask for network interface=$netif");
   	 $success = FALSE;
      } else { 
	 my ($val1, $val2, $val3);
	 ($val1, $val2, $val3, $$new_netmask_ref) = split (/ +/, $output[0]);
	 chomp $$new_netmask_ref;

	 if ($old_netmask ne $$new_netmask_ref) {
	    trace("old_netmask=$old_netmask does NOT match " .
		  "new_netmask=$$new_netmask_ref");
   	    $success = FALSE;
	 }
      }
   } else {
      my @output = grep { /\b$old_netmask\b/i } (<OPUT>);
      if (scalar(@output) == 0) { #not found
	 trace("Unable to find netmask=$old_netmask");
   	 $success = FALSE;
      }
   }

   close OPUT;
   return $success;
}

sub backupOLR
#-------------------------------------------------------------------------------
# Function: Backup OLR 
# Args    : none
# Returns : SUCCESS or FAILED
#-------------------------------------------------------------------------------
{
   my $ocrconfig = catfile($CFG->params('ORACLE_HOME'), 'bin', 'ocrconfig');
   my $rc = system ("$ocrconfig -local -manualbackup");

   if ($rc == 0) {
      trace ("$ocrconfig -local -manualbackup ... passed");
   } else {
      trace ("$ocrconfig -local -manualbackup ... failed");
      return FAILED;
   }

   return SUCCESS;
}

sub getCurrentNodenameList
#-------------------------------------------------------------------------------
# Function: Get current NODE_NAME_LIST
# Args    : none
# Returns : @node_list - list of nodes
#-------------------------------------------------------------------------------
{
   my @node_list = split (/,/, $CFG->params('NODE_NAME_LIST'));

   return @node_list;
}

sub isNodeappsExists
#-------------------------------------------------------------------------------
# Function: Check if nodeapps exists 
# Args    : none
# Returns : TRUE  if     exists
#	    FALSE if not exists
#-------------------------------------------------------------------------------
{
   @crs_nodevip_list_old = get_OldVipInfoFromOCRDump();
   if (scalar(@crs_nodevip_list_old) == 0) {
      return FALSE;
   }

   return TRUE;
}

sub quoteDiskGroup
#-------------------------------------------------------------------------------
# Function: Check if asm disk group contains '$'
# Args    : diskgroup
# Returns : diskgroup w/ '\' character
#-------------------------------------------------------------------------------
{
   if ($_[0]) {
      $_[0] =~ s/\$/\\\$/g;
   }
}

sub getVerInfo
#-------------------------------------------------------------------------------
# Function: Get the the Version from the String Passed
# Args    : VerString
# Returns : VerInfo 
#-------------------------------------------------------------------------------
{
   my $verstring = $_[0];
   my @verarray = (0, 0, 0, 0, 0);
   my $verinfo;
   trace("Version String passed is: $verstring");
   if ($verstring)
   {
      $verstring =~ m/\[(\d*)\.(\d*)\.(\d*)\.(\d*)\.(\d*)\].*$/;
      @verarray = ($1, $2, $3, $4, $5);
      $verinfo = join('.',@verarray);
      trace("Version Info returned is : $verinfo");
   }
   else
   {
      trace("Null Version String is Passed to getVerInfo");
   }

   return $verinfo;
}

sub getCkptStatus
{
   my $ckptName = $_[0];
   my $crshome  = $CFG->ORA_CRS_HOME;
   my @capout = ();
   my $rc;
   my $user = $CFG->HAS_USER;
   my $ORACLE_BASE = $CFG->params('ORACLE_BASE');
   my $CKPTTOOL = catfile( $crshome, 'bin', 'cluutil');
   my @program = ($CKPTTOOL, '-ckpt', '-oraclebase', $ORACLE_BASE, '-chkckpt', '-name', $ckptName, '-status');
   # run as specific user, if requested
   $rc = run_as_user2($user, \@capout, @program);
   # cluutil return 0 err code and errors, if any, on stdout
   if (scalar(grep(/START/, @capout)) > 0)
   {

     return CKPTSTART;
   }
   elsif (scalar(grep(/SUCCESS/, @capout)) > 0)
   {
     return CKPTSUC;
   }
   elsif (scalar(grep(/FAIL/, @capout)) > 0)
   {
     return CKPTFAIL;
   }
}

sub crf_config_generate
{
  my $mynameEntry = $_[0];
  my $hlist = "";
  my $nodelist = "";
  my $master = "";
  my $replica = "";
  my $masterpub = "";
  my $bdbloc = $_[1]; 
  my $usernm = $_[2];
  my $clustnm = $CFG->params('CLUSTER_NAME');
  my $crfhome = $ORA_CRS_HOME;
  my $configfile = tmpnam();

  $hlist=$_[3];
  $hlist =~ s/ //g;
  $nodelist=$_[3];
  chomp($nodelist);
  my @hosts = split(/[,]+/, $nodelist);
  $master = $hosts[0];

  if ($CFG->platform_family eq "windows")
  {
    $usernm = "";
  }
  
  # no replica if less than 2 nodes
  if (scalar(@hosts) >= 2) { $replica = $hosts[1]; }

  if ($mynameEntry eq $master)
  {
    $masterpub=$HOST;
  }
  open CONFIG_FILE,'>',$configfile;
  print CONFIG_FILE  "HOSTS=$hlist\n" ;
  print CONFIG_FILE  "MASTER=$master\n" ;
  print CONFIG_FILE  "REPLICA=$replica\n" ;
  print CONFIG_FILE  "MYNAME=$mynameEntry\n" ;
  print CONFIG_FILE  "MASTERPUB=$masterpub\n" ;
  print CONFIG_FILE  "CLUSTERNAME=$clustnm\n" ;
  print CONFIG_FILE  "USERNAME=$usernm\n";
  print CONFIG_FILE  "BDBLOC=$bdbloc\n" ;
  print CONFIG_FILE  "CRFHOME=$crfhome\n" ;
  close CONFIG_FILE ;

  return $configfile;
}

sub isCkptexist
#-------------------------------------------------------------------------------
# Function: Verify if checkpoint exist
# Args    : Check point Name
# Returns : boolean
#-------------------------------------------------------------------------------
{
   my $ckptName = $_[0];
   my $crshome  = $CFG->ORA_CRS_HOME;
   my @capout = ();
   my $rc;
   my $user = $CFG->HAS_USER;
   my $ORACLE_BASE = $CFG->params('ORACLE_BASE');
   my $CKPTTOOL = catfile( $crshome, 'bin', 'cluutil');
   my @program = ($CKPTTOOL, '-ckpt', '-oraclebase', $ORACLE_BASE, '-chkckpt', '-name', $ckptName);
   # run as specific user, if requested
   trace( '     ckpt: '.join(' ', @program) );
   $rc = run_as_user2($user, \@capout, @program);
   # cluutil return 0 err code and errors, if any, on stdout
   if (scalar(grep(/TRUE/, @capout)) > 0)
   {
     
     return SUCCESS;
   }
   if ((0 != $rc) || (scalar(grep(/FALSE/, @capout))) > 0)
   {
     trace("checkpoint $ckptName does not exist");
     return FAILED;
   }
}


sub writeCkpt
{
   my $ckptName =  $_[0];
   my $ckptState = $_[1];
   my $crshome  = $CFG->ORA_CRS_HOME;
   my @capout = ();
   my $rc;
   my $user = $CFG->HAS_USER;
   my $ORACLE_BASE = $CFG->params('ORACLE_BASE');
   my $CKPTTOOL = catfile( $crshome, 'bin', 'cluutil');
   my @program = ($CKPTTOOL, '-ckpt', '-oraclebase', $ORACLE_BASE, '-writeckpt', '-name', $ckptName, '-state', $ckptState);
   # run as specific user, if requested
   $rc = run_as_user2($user, \@capout, @program);
   # cluutil return 0 err code and errors, if any, on stdout
   if (scalar(@capout) > 0)
   {
     return SUCCESS;
   }
   if (0 != $rc)
   {
     error("Failed to check if checkpoint exist");
     return FAILED;
   }
   else
   {
     return SUCCESS;
   }
}

sub clean_start_cluster
{
  my $ckpt = "ROOTCRS_STRTSTACK";
  trace("Cleaning clusterware stack startup failure");
  StopCRS();
  writeCkpt($ckpt, CKPTSTART);
}

sub clean_olr_initial_config
{
   my $ckpt = "ROOTCRS_OLR";
   trace("Deleting the failed configuration of OLR");
   #olr_initial_config is idempotent. No cleanup needed
   #s_ResetOLR();
   writeCkpt($ckpt, CKPTSTART);
}

sub clean_initialize_local_gpnp
{
   my $ckpt = "ROOTCRS_GPNPSETUP";
   trace("Deleting the failed GPNP configuration");
   #Need to verify if the following call will do the necessary cleanup
   #initialize_local_gpnp is idempotent. No cleanup needed
   #s_removeGPnPprofile();
   writeCkpt($ckpt, CKPTSTART);
}

sub clean_register_service
{
   my $ckpt = "ROOTCRS_REGOHASD";
   trace("Deleting the failed OHASD Register");
   unregister_service("ohasd");
   writeCkpt($ckpt, CKPTSTART);
}

sub clean_start_service
{
   my $ckpt = "ROOTCRS_STARTOHASD";
   trace("Cleaning  the failed OHASD start");
   my $crsctl = catfile ($CFG->params('ORACLE_HOME'), "bin", "crsctl");
   system ("$crsctl stop has -f");
   writeCkpt($ckpt, CKPTSTART);
}

sub clean_perform_initial_config
{
   my $ckpt = "ROOTCRS_PFMINITCFG";
   my $ASM_DISK_GROUP = $CFG->params('ASM_DISK_GROUP');
   my $crsctl = catfile ($CFG->params('ORACLE_HOME'), "bin", "crsctl");
   my @out = ();

   trace("Cleaning up the failed initial configuration");
   if ($CFG->ASM_STORAGE_USED) {
      deconfigure_ASM();
   } else {
      CSS_delete_vfs(split(',', $CFG->params('VOTING_DISKS')));
   }
   @out = system_cmd_capture($crsctl, "stop", "cluster", "-f");
   #TBD -  what if push_clusterwide_gpnp_setup fails ?
   writeCkpt($ckpt, CKPTSTART);
}

sub clean_configure_hasd
{
   my $ckpt = "ROOTCRS_OHASDRES";
   trace("Deleting the failed OHASD configuration");
   #Need to have an api to remove the added resources
   #Currently the logic is implemented in configure_hasd
   writeCkpt($ckpt, CKPTSTART);  

}

sub clean_configNode
{
   my $ckpt = "ROOTCRS_CFGNODE";
   trace("Deleting the failed Node configuration");
   #Need to resue Remove Resources in crsdelete.pm ?
   RemoveOC4J();
   RemoveScan();
   #Need to remove asm/asm diskgroup.
   RemoveASM();
   RemoveNodeApps();
   writeCkpt($ckpt, CKPTSTART);
}

sub remove_checkpoints
{
   my $file = catdir ($CFG->params('ORACLE_BASE'), 'Clusterware', 'ckptGridHA.xml');
   trace("removing checkpoints");
   if (-f $file) {
      unlink($file);
   }
}

sub RemoveNodeApps
#---------------------------------------------------------------------
# Function: Remove nodeapps
# Args    : 0
#---------------------------------------------------------------------
{
   trace ("Removing nodeapps...");

   # check if nodeapps is configured
   my $srvctl = catfile ($CFG->ORA_CRS_HOME, "bin", "srvctl");
   system ("$srvctl config nodeapps");

   if ($CHILD_ERROR != 0) {
      return $SUCCESS;
   }

   my $cmd;
   my $status;
   my $node  = $CFG->HOST;
   my $force = '';

   if ($CFG->force) {
      $force = '-f';
   }

   # stop nodeapps
   $cmd = "$srvctl stop nodeapps -n $node $force";
   $status = system ($cmd);

   if ($status == 0) {
      trace ("$cmd ... success");
   } else {
      trace ("$cmd ... failed");
   }

   # remove nodeapps if lastnode, otherwise remove VIP
   if ($CFG->lastnode) {
      $cmd    = "$srvctl remove nodeapps -y $force";
      $status = system ($cmd);

      if ($status == 0) {
         trace ("$cmd ... success");
      } else {
         trace ("$cmd ... failed");
      }
   }
   else {
      $cmd    = "$srvctl remove vip -i $node -y $force";
      $status = system ($cmd);

      if ($status == 0) {
         trace ("$cmd ... success");
      } else {
         trace ("$cmd ... failed");
      }
   }
}

sub RemoveScan
#---------------------------------------------------------------------
# Function: Remove Scan
# Args    : 0
#---------------------------------------------------------------------
{
   trace ("Remove scans listeners");
   my $cmd_su = "/bin/su";

   if ($CFG->force)
   {
     trace("Stopping and removing scan listener with force");
     system ("$cmd_su $ORACLE_OWNER -c \"$SRVCTL stop scan_listener -f\"");
     system ("$cmd_su $ORACLE_OWNER -c \"$SRVCTL remove scan_listener -f\"");
   }
   else {
     trace("Stopping and removing scan listener gracefully");
     system ("$cmd_su $ORACLE_OWNER -c \"$SRVCTL stop scan_listener \"");
     system ("$cmd_su $ORACLE_OWNER -c \"$SRVCTL remove scan_listener -y\"");
   }

   if ($CFG->force)
   {
     trace("Stopping and removing scan vip with force");
     system ("$SRVCTL stop scan -f");
     system ("$SRVCTL remove scan -y -f");
   }
   else
   {
     trace("Stopping and removing scan vip gracefully");
     system ("$SRVCTL stop scan");
     system ("$SRVCTL remove scan -y");
   }
} #endsub

sub RemoveASM
{
    my $crsctl = catfile ($CFG->params('ORACLE_HOME'), "bin", "crsctl");
    my $srvctl = catfile ($CFG->ORA_CRS_HOME, "bin", "srvctl");
    my @out = ();

   @out = system_cmd_capture($crsctl, "delete", "resource", "ora.asm", "-f");
}

sub RemoveOC4J
{
   my $crsctl = catfile ($CFG->params('ORACLE_HOME'), "bin", "crsctl");
   my @out = ();

   @out = system_cmd_capture($crsctl, "delete", "resource", "ora.oc4j", "-f");
}

sub crf_kill_for_sure
{
  kill(15, $_[0]);

  # if that didn't work, use force
  if (kill(0, $_[0]))
  {
    kill(9, $_[0]);
  }
}

# delete the bdb files in bdbloc.
sub crf_delete_bdb
{
  my $bdbloc = $_[0];

  if ($bdbloc ne "")
  {
    # remove files which we created.
    chdir $bdbloc or die "ERROR:Cannot chdir to $bdbloc, invalid BDB path.";
    opendir(DIR, "$bdbloc") || die "Error in opening dir $bdbloc\n";
    trace("Removing contents of BDB Directory $bdbloc\n");
    my $crfbdbfile;
    my @ldbfiles = grep(/\.ldb$/,readdir(DIR));
    foreach $crfbdbfile (@ldbfiles)
    {
      unlink ($crfbdbfile);
    }

    # database files
    rewinddir (DIR);
    my @bdbfiles = grep(/\.bdb$/,readdir(DIR));
    foreach $crfbdbfile (@bdbfiles)
    {
      unlink ($crfbdbfile);
    }

    # env files
    rewinddir (DIR);
    my @dbfiles = grep(/__db.*$/,readdir(DIR));
    foreach $crfbdbfile (@dbfiles)
    {
      unlink ($crfbdbfile);
    }

    # archive log
    rewinddir (DIR);
    my @bdblogfiles = grep(/log.*$/,readdir(DIR));
    foreach $crfbdbfile (@bdblogfiles)
    {
      unlink ($crfbdbfile);
    }
    closedir (DIR);
  }
}

sub isCRFSupported
{
  my $osysmond         = catfile ($CFG->ORA_CRS_HOME, "bin", "osysmond");
  my $osysmond_exe     = catfile ($CFG->ORA_CRS_HOME, "bin", "osysmond.exe");

  trace ("IPD/OS not supported on this platform");
  return FALSE;
}

# delete a node from the CRF install
sub crf_do_delete
{
  # shutdown the sysmond, ologgerd, oproxyd if they are running

  my $cmd;
  my $instdir;
  my $defpath;
  my $rootpath;
  my $configfile;
  my $line;
  my $bdbloc;

  trace("Check and delete older IPD/OS installation");

  if ($CFG->platform_family eq "windows")
  {
    $instdir = "C:\\Program Files\\oracrf";
    $defpath = "$ENV{SYSTEMROOT}"."\\system32\\";
    $rootpath = "$ENV{SYSTEMROOT}";
  }
  else
  {
    $instdir = "/usr/lib/oracrf";
    $defpath = "/usr/bin";
    $rootpath = "/";
  }

  my $instfile = catfile("$instdir","install","installed");
  if (! -f $instfile)
  {
    trace("INFO: The OS Tool is not installed at $instdir.");
  }
  else
  {
    trace("Older IPD/OS installation detected ... Stopping and removing it ... ");
    $cmd = catfile("oclumon", "stop", "all");
    $configfile = catfile("$instdir", "admin", "crf${HOST}.ora");

    system("$cmd");
    sleep(5);

    # read config file to find older BDB loc
    my @filecontent = read_file ($configfile);
    foreach my $line (@filecontent)
    {
      # skip blanks and comments
      if ($line !~ /^#|^\s*$/)
      {
        if ($line =~ /BDBLOC=(.*)/) { $bdbloc = $1; last;}
      }
    }

    my $crfhome = $instdir;

    # osysmond first
    my $runpth=catfile("$crfhome","admin","run");
    my $pidf=catfile("$runpth","crfmond","s${HOST}.pid");
    if (-f $pidf)
    {
      open(PID_FILE, $pidf);
      while (<PID_FILE>)
      {
        crf_kill_for_sure($_);
      }
      close(PID_FILE);
      unlink($pidf);
    }
    my $dir;
    $dir = catfile("$runpth", "crfmond");
    rmdir("$dir");

    # ologgerd now
    my $pidf=catfile("$runpth","crflogd","l${HOST}.pid");
    if (-f $pidf)
    {
      open(PID_FILE, $pidf);
      while (<PID_FILE>)
      {
        crf_kill_for_sure($_);
      }
      close(PID_FILE);
      unlink($pidf);
    }
    $dir = catfile("$runpth", "crflogd");
    rmdir("$dir");

    # proxy next
    my $pidf=catfile("$runpth","crfproxy","p${HOST}.pid");
    if (-f $pidf)
    {
      open(PID_FILE, $pidf);
      while (<PID_FILE>)
      {
        crf_kill_for_sure($_);

        # give some time to oproxy to react.
        sleep 2;
      }
      close(PID_FILE);
      unlink($pidf);
    }
    $dir = catfile("$runpth", "crfproxy");
    rmdir("$dir");

    # ask crfcheck to shutdown cleanly
    my $pidf=catfile("$crfhome","log","${HOST}","crfcheck/crfcheck.lck");
    if (-f $pidf)
    {
      open(PID_FILE, $pidf);
      while (<PID_FILE>)
      {
        kill 15, $_;
      }
      close(PID_FILE);
    }

    my $rootpath;
    s_crf_remove_itab();

    # remove the tree
    trace("Removing install dirs from $instdir ...\n");
    my $filed;
    my $file;
    foreach $filed ('bin', 'lib', 'admin', 'jlib', 'mesg', 'log',
                     'install', 'jdk', 'db')
    {
      $file = catfile("$instdir", "$filed"); 
      rmtree("$file", 0, 0);
    }

    # delete old bdb files.
    trace("Deleting older IPD/OS BDB files at: ", $bdbloc);
    crf_delete_bdb($bdbloc);

    unlink("$defpath"."crfgui");
    unlink("$defpath"."oclumon");
    unlink("$defpath"."crfcheck");

    # change dir to a safer place
    chdir $rootpath;
    trace("Removing CRFHOME path $instdir...\n");
    rmdir $instdir;
    trace("Old IPD/OS install removal operation completed.\n");
  }
}

1;
__END__

=head2 <sub-name>


=head3 Parameters


=head3 Returns


=head3 Usage


=cut


