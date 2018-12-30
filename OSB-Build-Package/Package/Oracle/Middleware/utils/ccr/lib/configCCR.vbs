' $Header: emll/lib/configCCR.vbs /main/177 2010/12/21 13:18:03 fmorshed Exp $
'
' Copyright Oracle 2006, 2010. All Rights Reserved
'
'    NAME
'      configCCR.vbs - setup script for initial CCR install
'
'    DESCRIPTION
'      This script is used to install and set up CCR on first install
'      Note, this module was initially setupCCR.vbs. It was renamed in
'      the 10.2.4 release due to bug 5581924.
'
'    EXIT VALUES
'      0 - Success
'      1 - Prerequisite failure
'      2 - Invalid argument specified
'      3 - Invalid Usage
'      11 - Unexpected Installation failure
'      12 - License Agreement declined
'
'    MODIFIED
'      fmorshed  05/05/11 - XbranchMerge fmorshed_fix_12376821 from main
'      fmorshed  05/03/11 - If we are deploying the core, then get yourself in install code path.
'                           This is done on Linux side and hence by definition it should be done
'                           on Windows as well.  Otherwise, updates are not gotten, and certain
'                           messages are not output.
'      fmorshed  03/25/11 - deriveCCR now defines an environment variable 
'                           DERIVECCR_IN_PROGRESS to tell who it invokes that
'                           there is a deriveCCR in progress.
'      davili    03/21/11 - Update out of place upgrade, continue ocm install
'                           on empty input config file
'      fmorshed  03/19/11 - Since deriveCCR now only removes ccr.properties and
'                           collector.properties from the config directory, only
'                           look for cc.properties to detect an already
'                           establishedconfig home in compatibility mode.
'      fmorshed  01/13/11 - Fix bug 11065118: CONFIGCCR -A IS SUCCESSFUL EVEN
'                           THOUGH HOME IS ALREADY CONFIGURED
'      davili    01/07/11 - Update out of place upgrade setup
'      fmorshed  01/05/11 - Change the check for deploy packages to presence of
'                           core.jar.
'      fmorshed  12/19/10 - Before refusing to re-configure check that the
'                           confighome is even setup.
'      davili    12/09/10 - Update for out of place upgrade
'      fmorshed  10/13/10 - Move some useful declarations to coreutil.vbs.  
'                           For robustness, change the prompt recognition arguments to 
'                           interactive_runProc to an array of prompts that are matched
'                           exactly (not partially) against the output.
'                           For readability, make a function from some free standing code.
'                           Change how an unconfigured installation is recognized to accomodate
'                           deriveCCR (which calls here).
'      asunar    09/21/10 - Replacing the # with ' added in the base
'                           transaction for the comment
'      asunar    09/17/10 - Adding code to remove the diag_check directories
'      asunar    07/23/10 - Moving the processDisconn up in the if statement
'                           and adding emocmrsp -export for disconnected case
'                           too
'      jsutton   07/22/10 - fix up cacls arguments
'      asunar    07/15/10 - Rolling back the txn asunar_bg_8840500
'      asunar    06/28/10 - collect and upload should happen before going to
'                           disconnected mode
'      asunar    06/21/10 - Handling the return code 3 from content server
'      qding     03/23/10 - fix scriptName in checkArgs
'      qding     03/23/10 - fix nt setup break
'      jsutton   03/19/10 - Add WSH version check
'      qding     03/16/10 - bug 9478872, remove undocumented qualifiers
'      jsutton   03/16/10 - bug 9391311
'      qding     03/14/10 - bug 9455199
'      asunar    03/02/10 - export the JAVA_HOME value to the env to be used
'                           later
'      ckalivar  02/15/10 - Bug 9057054: Deprecated Country code
'      ckalivar  12/17/09 - Bug 8934667: emCCR getupdates returncode handled
'      qding     01/31/10 - project 30108, OCheck
'      asunar    09/29/09 - Changing the text for -C argument to be similar to
'                           -repeater option of emocmrsp
'      aghanti   07/30/09 - Modifyig err message to report exclusion of -C with
'                           resp file
'      ndutko    07/27/09 - Save and restore the emocmclnt.jar
'      aghanti   07/24/09 - Rolling back txn aghanti_bug-8666409
'      aghanti   07/22/09 - Bug 8702196 - Replacing all external references to
'                           'OCM Repeater' with 'Oracle Support Hub'
'      aghanti   07/15/09 - Minor changes to make install flow similar to unix
'      aghanti   06/30/09 - Incorporating Repeater in standard install flow
'      ndutko    04/14/09 - Variables can not have '_' chars
'      ndutko    04/01/09 - Save the JARs consumed by emocmutl.jar in the case
'                           of a failure and rollback.
'      ndutko    03/10/09 - Save the emocmcommon.jar
'      jsutton   01/12/09 - backup, restore, cleanup new files
'      ndutko    12/30/08 - Don't display the visitation banner, redirecting to
'                           metalink if adding a config in disconnected mode.
'      ndutko    12/18/08 - Stop the Scheduler if the collector is placed into
'                           disconnected mode via response file.
'      pparida   12/16/08 - 7649762: Do not run status collection if -a or -r
'                           option present.
'      ckalivar  12/17/08 - Bug-7606689: Fix to remove extra line printing when
'                           configCCR fails
'      asunar    12/16/08 - BUG 7599023-Switching OCM to disconnected mode
'                           using a response file doesnot stop the scheduler
'      ckalivar  11/12/08 - Bug:7482056- corrected the check for Invalid number
'                           of arguments
'      ckalivar  11/12/08 - Bug:7265292- added an empty line in output of -R
'                           without responsefile
'      pparida   10/23/08 - pparida_ocm_status_metric: Upload oracle_livelink
'                           before switching from connected to disconnected
'                           mode.
'      ndutko    10/30/08 - Change usage string
'      ndutko    10/14/08 - Name change from MetaLink to My Oracle Support
'      ndutko    09/06/08 - XbranchMerge ndutko_tsp_changes from st_emll_10.3.0
'      ndutko    09/06/08 - XbranchMerge ndutko_bug-7358958 from st_emll_10.3.0
'      ndutko    09/05/08 - XbranchMerge ndutko_bug-7330620 from st_emll_10.3.0
'      ndutko    08/27/08 - Remove references to Software Configuration Manager
'      ndutko    08/20/08 - No longer refer to license.txt
'      ndutko    08/16/08 - Prompt for review of TSP not accpetance.
'      jsutton   07/22/08 - 7185914: create CCR_HOME/state directory
'      pparida   05/14/08 - 7038930: Conditionalize stop_abort call in
'                           deconfigInstance().
'      pparida   05/13/08 - 7022623: Add message to deconfigInstance() before
'                           calling stop_abort
'      ndutko    05/09/08 - Change of license text when the license was
'                           declined
'      ndutko    05/06/08 - Do not work on the software version software
'                           provider into collector.properties unless the
'                           properties are specified.
'      ndutko    05/06/08 - XbranchMerge ndutko_bug-7019750 from st_emll_10.3.0
'      ndutko    05/06/08 - XbranchMerge ndutko_bug-7019786 from st_emll_10.3.0
'      ndutko    05/06/08 - Typo in the license declined wrapup
'      ndutko    04/29/08 - XbranchMerge ndutko_bug-6976713 from main
'      ndutko    04/29/08 - Capture condition of a response file that does not
'                           exist is passed in and the license check fails.
'      ndutko    04/28/08 - Support for -c validation
'      ndutko    04/25/08 - Add support from setupCCR.exe to invoke with -H
'      ndutko    04/18/08 - -R and -r are mutually exclusive
'      ndutko    04/18/08 - Fix for bug 6980550
'      ndutko    04/15/08 - Move the configuration completion messages after
'                           the config is completed.
'      ndutko    04/15/08 - Removal of references to the proxy qualifier
'      ndutko    04/09/08 - Cutover to not prompt for proxies, etc.
'      ndutko    04/02/08 - 
'      jsutton   03/21/08 - Guard winmgmts use (NT issues, bug 6903664)
'      ndutko    03/18/08 - Protect the jsse_license.html
'      ndutko    03/18/08 - GetRegistrationProperties now requires additional
'                           arguments
'      ndutko    03/17/08 - Changes in support of use of response file
'      jsutton   02/05/08 - Deal with non-English Administrators group
'      pparida   12/17/07 - Fix bug 6698695: Remove space after echo y in cacls
'                           command.
'      jsutton   12/13/07 - Make sure file permissions are defaulted properly
'      jsutton   11/06/07 - Strip quotes from ORACLE_CONFIG_HOME env var
'      ndutko    10/25/07 - XbranchMerge ndutko_bug-6528510 from st_emll_10.2.7
'      ndutko    10/24/07 - XbranchMerge ndutko_bug-6524910 from st_emll_10.2.7
'      ndutko    10/24/07 - Do not allow configCCR -a to be invoked where
'                           ORACLE_CONFIG_HOME == ORACLE_HOME.
'      jsutton   10/23/07 - Escape special chars in properties
'      ndutko    10/23/07 - Remove bad Unix comment char and invalid escaped
'                           chars
'      ndutko    10/22/07 - Check to make certain the configuration to
'                           disconnected mode or visa versa, or removal of this
'                           OCH matches the bin home
'      pparida   10/19/07 - Fix bug 6512459: Do not allow -a or -r for new
'                           install.
'      ndutko    10/19/07 - XbranchMerge ndutko_bug-6467643 from st_emll_10.2.7
'      ndutko    10/19/07 - XbranchMerge ndutko_bug-6512958 from st_emll_10.2.7
'      ndutko    10/19/07 - Provide more information if the OH or OCH is not
'                           completely configured when a request is made.
'      ndutko    10/18/07 - In sharedHome mode, store the CCR_HOME directory in
'                           the collector.properties as ccr.binHome. Verify
'                           this against running command paths.
'      jsutton   10/16/07 - XbranchMerge jsutton_bug-6486342 from
'                           st_emll_10.2.7
'      jsutton   10/15/07 - XbranchMerge jsutton_bug-6475562 from
'                           st_emll_10.2.7
'      ndutko    10/13/07 - XbranchMerge ndutko_bug-6495476 from st_emll_10.2.7
'      jsutton   10/12/07 - XbranchMerge jsutton_bug-6496084 from
'      jsutton   10/12/07 - XbranchMerge jsutton_bug-6486401 from
'                           st_emll_10.2.7
'      ndutko    10/12/07 - XbranchMerge ndutko_bug-6497483 from st_emll_10.2.7
'      ndutko    10/15/07 - Typo - wrong function name
'      jsutton   10/15/07 - Create the mini-inventory file
'      ndutko    10/12/07 - Insure -a and -r are not specified at the same
'                           time.
'      jsutton   10/12/07 - Use stop_abort when stopping scheduler in deconfig
'      ndutko    10/12/07 - Bring config/deconfig in line with Linux
'                           implementation.
'      ndutko    10/11/07 - XbranchMerge ndutko_bug-6495218 from st_emll_10.2.7
'      ndutko    10/11/07 - Do not permit a deconfig where ORACLE_CONFIG_HOME =
'                           CCR_HOME
'      ndutko    10/09/07 - XbranchMerge ndutko_bug-6488100 from st_emll_10.2.7
'      ndutko    10/09/07 - Determine whether this version of install supports
'                           shared installs and use constants vs checking for a
'                           directory.
'      jsutton   10/08/07 - Fix name redefinition
'      jsutton   10/05/07 - Fix issues found during QA
'      jsutton   10/04/07 - Sync vbs with shell
'      jsutton   10/03/07 - Service name depends on ORACLE_CONFIG_HOME
'      jsutton   10/01/07 - Fix syntax issue
'      jsutton   09/25/07 - Clients track deployed content
'      jsutton   09/14/07 - Instantiate sched.properties per instance in shared
'                           homes
'      jsutton   09/12/07 - Set CCR_CONFIG_HOME correctly during setup
'      jsutton   09/09/07 - Put uplinkreg.bin back in config/default
'      jsutton   08/23/07 - Windows fixups for shared home work
'      jsutton   08/06/07 - Windows support for shared OH
'      jsutton   02/27/07 - Remove logjam on launched process output
'      jsutton   02/06/07 - XbranchMerge jsutton_bug-5851694 from
'                           st_emll_10.2.5
'      ndutko    01/27/07 - Movement of Exit codes to coreutils.vbs
'      ndutko    01/27/07 - XbranchMerge ndutko_bug-5846940 from st_emll_10.2.5
'      jsutton   01/19/07 - Prevent updateComponents from stepping on other
'                           operations
'      ndutko    01/11/07 - Support for distributing configCCR in base
'                           distribution
'      pparida   01/11/07 - Install/Uninstall service while switching between
'                           connected and disconnected modes.
'      jsutton   01/08/07 - Save/restore license.txt for rollback case
'      ndutko    12/19/06 - remove the emCCRenv if in install and rolling back
'      ndutko    12/12/06 - Do not return to caller if called with -h
'      ndutko    12/12/06 - Don't prompt for info after a usage failure.
'      ndutko    12/12/06 - Allow for parameter validation before prerequisite
'                           checks
'      ndutko    12/12/06 - Pull in the emCCRenv if it is present
'      ndutko    12/06/06 - Movement of exit codes to co-incide with
'                           pre-reorganization
'      ndutko    12/04/06 - Incomplete If clause
'      ndutko    11/30/06 - Adjust the location of the license.txt
'      ndutko    11/30/06 - Standardize on exit code(s) for when the License
'                           agreement is not accepted.
'      kgupta    11/13/06 - Use -noCollect to start scheduler if
'                           CCR_INSTALL_DEFER_COLLECT is defined
'      ndutko    11/02/06 - Rename of license.install to license.txt
'      pparida   10/18/06 - Fix bug 5610543: Check for existence of the
'                           PREVIOUS dir before calling GetFolder
'      pparida   10/12/06 - Check for file existence before deleting files in state/previous dir 
'      ndutko    10/05/06 - XbranchMerge ndutko_nt_regtest_fixes from
'                           st_emll_10.2.4
'      ndutko    10/05/06 - Remove extraneous CRLF
'      ndutko    10/04/06 - Rename of module to configCCR
'      ndutko    10/04/06 - XbranchMerge ndutko_bug-5581924 from st_emll_10.2.4
'      ndutko    10/03/06 - XbranchMerge ndutko_bug-5577019 from st_emll_10.2.4
'      ndutko    10/03/06 - Remove the temporary files if license is declined
'      ndutko    10/03/06 - XbranchMerge ndutko_bug-5576989 from st_emll_10.2.4
'      ndutko    10/02/06 - If not in an INSTALL codepath, then only get
'                           updates but do not deploy any changes.
'      ndutko    10/02/06 - Mask out the proxyPwd seed if proxy is changed
'      ndutko    09/25/06 - Remove setupCCR on successful installation
'      ndutko    09/24/06 - Compare against failures for status before
'                           determining the collecor is started.
'      ndutko    09/23/06 - Remove uplinkreg.bin on rollback of core
'      ndutko    09/15/06 - Changes to handle reconfig and disconnected
'      jsutton   08/31/06 - Fix usege output issues for regressions
'      jsutton   08/24/06 - Finish up multi-arch work
'      jsutton   08/21/06 - Fix usage message ordering
'      jsutton   08/03/06 - Save OsInfo class file on core rollback
'      jsutton   07/19/06 - Handle file input differently 
'      kgupta    06/21/06 - Exit with non-zero return code in case of an error
'      jsutton   06/21/06 - Disallow install on inappropriate disk types 
'      jsutton   06/07/06 - Fix check for invalid switches 
'      jsutton   06/06/06 - Use -h for usage flag, align with Linux syntax 
'      jsutton   06/01/06 - Safeguard absolute necessity files for setup in 
'                           case of core rollback 
'      kgupta    05/25/06 - XbranchMerge kgupta_fix_5214665 from main 
'      nemalhot  05/22/06 - Fixing Null value checks 
'      nemalhot  05/25/06 - XbranchMerge nemalhot_bug-5237038 from main 
'      ndutko    05/18/06 - Remove all CCRHome references 
'      jsutton   05/18/06 - No rollbackCore once we get past registration 
'      ndutko    05/18/06 - Address issue with 'more' on Windows NT 
'      ndutko    05/18/06 - Use the common GetEnvironmentalValue() interface 
'                           from coreutil 
'      ndutko    05/16/06 - Use the full validating JDK function when 
'                           detecting the JAVA_HOME validity 
'      kgupta    05/17/06 - Remove proxy info if any during rollback 
'      kgupta    05/17/06 - Shift proxy password prompt code to nmzsp 
'      ndutko    05/15/06 - Precede the more command with 
'                           C:\WINDOWS\system32\cmd.exe /c 
'      jsutton   05/15/06 - Fix tkdiff-induced problems 
'      jsutton   05/12/06 - Alternate approach to getting output from 
'                           subprocesses 
'      ndutko    05/12/06 - Support the specification of JAVA_HOME that 
'                           contains a space (Bug 5223000) 
'      jsutton   05/11/06 - Clean up 
'      ndutko    05/11/06 - Capture the failure of missing emSnapshotENV 
'      nemalhot  05/11/06 - Fix Bug 5217151 
'      ndutko    05/10/06 - Add white space to conform to Unix implementation 
'      jsutton   05/10/06 - Handle input command line issues w/proxy, etc. 
'      nemalhot  05/08/06 - convert directory paths to lowercase 
'      jsutton   05/03/06 - Further script cleanup 
'      jsutton   03/16/06 - Use CCR_INSTALL_DEBUG where applicable 
'      jsutton   03/13/06 - Fix problem w/syntax 
'      jsutton   02/20/06 - Fix up perl_bin 
'      jsutton   02/09/06 - ccr.properties.template is in CRLF format 
'      jsutton   01/19/06 - initial
'
Option Explicit

Dim ExecCommand
Dim oExec,oStdErr,oStdOut
Dim WshShell,WshEnv

Dim FSO
Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8

' Constants to be used in exit codes...
Const SUCCESS = 0
Const ERR_PREREQ_FAILURE = 1
Const ERR_INVALID_ARG = 2
Const ERR_INVALID_USAGE = 3
Const ERR_LICENSE_DECLINED = 12

'This is declared in coreutil.vbs
'Const ERR_LOCK_FAILURE=4
'Const ERR_CORRUPT_INSTALL=5
'Const ERR_UNEXPECTED_FAILURE=11

Dim CCR_HOME, CCR_BIN, ORACLE_HOME, JAVA_HOME, CCR_CONFIG_HOME
Dim USER_CCR_BACKUP, USERDEF_CCR_BACKUP, USER_COLLECTOR_BACKUP, USERDEF_COLLECTOR_BACKUP
Dim CCR_PROXY_PARAM
Dim RESPONSE_FILE
Dim REPEATER_URL
Dim SOFTWARE_INSTALLER, SOFTWARE_INSTALLER_VERSION
Dim G_Verify_Syntax : G_Verify_Syntax = False

Dim pendingFldr,pendingFiles,pendingFile

Dim CCRSig,CCRDisconnected,CCRRegInfo(3)
Const regCSI = 0
Const regMLID = 1
Const regCC = 2

Dim retStatus,i

Dim CCR_INSTALL_CODEPATH : CCR_INSTALL_CODEPATH = False
Dim G_NewInstall : G_NewInstall = False
Dim a_option : a_option = False
Dim r_option : r_option = False

Dim isDiagchecksCmd : isDiagchecksCmd = False
Dim isVerifyDiagProps : isVerifyDiagProps = False
Dim diagcheckTargetType,diagcheckTargetName,diagcheckPropertyName

' G_ConfigurationRequest is used to indicate whether a configuration, or removal
' of configuration is requested. Valid values are "", "config" or "deconfig".
Dim G_ConfigurationRequest

' G_configurationCompleted is used to denote that a configuration request was
' explicitly requested or implicitly made thru a new installation and the
' setup of writeable trees was completed. Values are 0 for false and 1 for true.
Dim G_ConfigurationCompleted : G_ConfigurationCompleted = False

' G_OCMConfigured indicates that the OCM Home/OCM Configuration Home contains
' configuration information. The valid values are 'undefined' prior to calls
' to isOCMConfigured, and TRUE or FALSE otherwise
Dim G_OCMConfigured

' G_INIT_DISCONN_STATE defines a string that identifies the initial disconnect
' state of the collector when a configuration or reconfiguration is being
' performed
Dim G_INIT_DISCONN_STATE : G_INIT_DISCONN_STATE = False

Dim dayName(7)
dayName(0) = ""
dayName(1) = "Su"
dayName(2) = "M"
dayName(3) = "T"
dayName(4) = "W"
dayName(5) = "TH"
dayName(6) = "F"
dayName(7) = "S"

Dim dictProps, dictResults
Dim CCR_SCHEDULER_SVCNAME

'**************************
' Main entry point
'**************************

' WSH prerequisite check
Dim checkRetStatus : checkRetStatus = WSHPrerequisiteChecks()
If (retStatus <> SUCCESS) then
    Quit(ERR_PREREQ_FAILURE)
End If

Set WshShell = WScript.CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
Set WshEnv = WshShell.Environment("PROCESS")

' Include core utility
IncludeCoreUtils

'
' Get the paths that are required hereafter. 
'
Call GetPaths(CCR_HOME, CCR_BIN, ORACLE_HOME, CCR_CONFIG_HOME)
'
' Check to see if this is the install codepath
'
If (isInSetupMode(CCR_HOME)) Then
  '
  ' Set flag - we're in the install codepath
  '
  WshEnv("CCR_INSTALL_CODEPATH") = "1"
  CCR_INSTALL_CODEPATH = True
  G_NewInstall = True
  G_ConfigurationRequest = "config"

  '
  ' during an install (vs. upgrade) we create the hosts tree
  ' for support of shared Oracle Homes
  '
  If (Not FSO.FolderExists(CCR_HOME & "\hosts")) Then
    FSO.CreateFolder(CCR_HOME & "\hosts")
  End If
  '
  ' per bug 7185914, we also create the state directory
  '
  If (Not FSO.FolderExists(CCR_HOME & "\state")) Then
    FSO.CreateFolder(CCR_HOME & "\state")
  End If
  '
  ' Just to be sure, recheck the CCR_CONFIG_HOME value and
  ' ensure the expected/required subtrees are beneath it
  '

  Call GetCCRConfigHome(CCR_HOME, CCR_CONFIG_HOME)

  CreateConfigTree(CCR_CONFIG_HOME)
  setPermissions()
End If

WshEnv("CCR_CONFIG_HOME") = CCR_CONFIG_HOME

' Get the starting state for connectivity.
G_INIT_DISCONN_STATE = IsDisconnected()

'
' Make sure we're installing on a Fixed, non-SUBSTed drive
'
If FSO.GetDrive(FSO.GetDriveName(CCR_HOME)).DriveType <> 2 Then
  WScript.Echo "Oracle Configuration Manager must be installed on a local, non-removable, writeable drive"
  Quit(ERR_PREREQ_FAILURE)
End If

Call runProc("subst","")
Dim substInfo : substInfo = oStdOut
Dim substArray : substArray = Split(substInfo, vbCr, -1)
Dim substData
For Each substData in substArray
  If (Left(LCase(substData), 2) = LCase(FSO.GetDriveName(CCR_HOME))) Then
    WScript.Echo "Oracle Configuration Manager may not be installed on a SUBSTed drive."
    Quit(ERR_PREREQ_FAILURE)
  End If
Next

' Pull in the emCCRenv if present.
instantiateSavedEnv(CCR_CONFIG_HOME)

'
' validate arguments
'
retStatus = checkArgs()
If (Not retStatus = SUCCESS Or G_Verify_Syntax = True) Then
  Quit(retStatus)
End If

'
' check for Installation prerequisites.
'
retStatus = checkPrerequisites()
If (Not retStatus = SUCCESS) Then
  Quit(retStatus)
End If

'
' Out of place upgrade
' If the environment variable $OUT_OF_PLACE_UPGRADE_INFO is set,
' then we are doing an out of place upgrade, otherwise it is just
' a regular install.   If we are doing an out of place upgrade,
' then we check the file at $OUT_OF_PLACE_UPGRADE_INFO to see that
' it exists and is not empty.
'
Dim strOUT_OF_PLACE_UPGRADE_INFO : strOUT_OF_PLACE_UPGRADE_INFO = GetEnvironmentalValue("OUT_OF_PLACE_UPGRADE_INFO")
If (strOUT_OF_PLACE_UPGRADE_INFO <> "") Then
  Dim FileOK : FileOK = 0
  On Error Resume Next
  If (FSO.FileExists(strOUT_OF_PLACE_UPGRADE_INFO) And FSO.GetFile(strOUT_OF_PLACE_UPGRADE_INFO).Size > 0) Then
    On Error Goto 0
    If Err.Number = 0 Then
      FileOK = 1
      Dim strOCMLibDir : strOCMLibDir = ORACLE_HOME & "\ccr\lib" 
      Dim strclasspath : strclasspath = " " & strOCMLibDir & "\emocmclnt.jar;" & strOCMLibDir & "\regexp.jar;" & strOCMLibDir & "\log4j-core.jar;" & strOCMLibDir & "\xmlparserv2.jar "
      Dim strCCR_CONFIG_HOME : strCCR_CONFIG_HOME = " -DCCR_CONFIG_HOME=" & CCR_CONFIG_HOME & " "
      Dim strUpgradeInfo : strUpgradeInfo = " -DOUT_OF_PLACE_UPGRADE_INFO=" & strOUT_OF_PLACE_UPGRADE_INFO & " "

      Dim ExitValue
      ExitValue = runProc(JAVA_HOME & "\bin\java.exe", " " & strUpgradeInfo & strCCR_CONFIG_HOME & " -classpath " & strclasspath & " oracle.sysman.ccr.collector.util.OutOfPlaceUpgradeClient")
      If (ExitValue <> SUCCESS) Then
          errorExit(ExitValue)
      End If
    End If
  End If
  If FileOK = 0 Then
    WScript.Echo "Out of place upgrade error.  File at " & strOUT_OF_PLACE_UPGRADE_INFO & " could not be found or is empty.  Continuing with regular OCM install.  Note: duplicate targets could be generated on CCR server with this setup."
  End If
End If

'
' Are we doing a config or deconfig operation?
'
If G_ConfigurationRequest = "config" Then
  Call configAnInstance()
Else
  Dim matchingCCRHome

  If (Not IsOCMConfigured(True)) Then
    WScript.Echo "OCM is not configured for this host or ORACLE_CONFIG_HOME. Please configure OCM first."
    WScript.Quit(ERR_PREREQ_FAILURE)
  End If

  ' Check to make certain the CCR_HOME and OCH->ccr.binHome values match up.  
  If (isUninitialized(GetEnvironmentalValue("DERIVECCR_IN_PROGRESS"))) Then
    If (Not configMatchesHome(CCR_HOME, matchingCCRHome)) Then
        WScript.Echo "Error: This OCM configuration location corresponds to the installation in "
        WScript.Echo "the directory: """ & matchingCCRHome & """."
        WScript.Quit(ERR_PREREQ_FAILURE)
    End If
  End If

  If G_ConfigurationRequest = "deconfig" Then
    Call deconfigInstance()
    WScript.Quit(SUCCESS)
  End If
End If

' Save the configuration state
Call backupConfigFiles()

'
' verify properties file gets set up if not already
'
If (Not CCRDisconnected) Then
  If (Not isUninitialized(RESPONSE_FILE)) Then
      printDebug "* configCCR Response file specifed with name: "& RESPONSE_FILE

      ' Disable CCR_DEBUG for the part where emocmrsp is used to query for response
      ' file values.
      Dim CCR_DEBUG : CCR_DEBUG = GetEnvironmentalValue("CCR_DEBUG")
      WshEnv("CCR_DEBUG") = ""

      Dim EMOCMRSP_BIN, ExitCode

      EMOCMRSP_BIN=FSO.BuildPath(CCR_HOME, FSO.BuildPath("bin", "emocmrsp.bat"))       

      ExitCode = runProc(EMOCMRSP_BIN,"-no_banner -response_file """ & RESPONSE_FILE & """ -query license.accepted")
      If (ExitCode <> SUCCESS) Then
          WScript.StdOut.write (oStdOut)
          Call rollbackCore(CCR_INSTALL_CODEPATH, True) 
          errorExit(ExitCode)
      End If

      CCRSig = oStdOut

      ' Check to see if the response file indicates a declined license 
      If ( isUninitialized(CCRSig) ) Then
        printDebug "* configCCR key ocm.license.accepted is not present in the response file"

        WScript.echo "Oracle Configuration Manager has been installed but not configured. OCM enables"
        WScript.echo "Oracle to provide superior, proactive support for our customers. Oracle"
        WScript.echo "strongly recommends customers configure OCM. To complete the configuration of"
        WScript.echo "OCM, refer to the OCM Installation and Administration Guide"
        WScript.echo "(http://www.oracle.com/technology/documentation/ocm.html)."

        Call rollbackCore(CCR_INSTALL_CODEPATH, True)
        errorExit(ERR_LICENSE_DECLINED)
      Else 
        printDebug "* configCCR license.accepted = "& CCRSig
        If ( Left(LCase(CCRSig),4) <> "true" ) Then
          WScript.echo "Oracle Configuration Manager has been installed but not configured. OCM enables"
          WScript.echo "Oracle to provide superior, proactive support for our customers. Oracle"
          WScript.echo "strongly recommends customers configure OCM. To complete the configuration of"
          WScript.echo "OCM, refer to the OCM Installation and Administration Guide"
          WScript.echo "(http://www.oracle.com/technology/documentation/ocm.html)."

          Call rollbackCore(CCR_INSTALL_CODEPATH, True)
          errorExit(ERR_LICENSE_DECLINED)
        End If
      End If
    
      ' Get the state of the disconnected/connected mode from the 
      ' response file.
      Call runProc(EMOCMRSP_BIN,"-no_banner -response_file """ & RESPONSE_FILE & """ -query network_config.disconnected")
      Dim strDisconnected : strDisconnected = oStdOut
      If (Not isUninitialized(strDisconnected)) Then
        If (Left(LCase(strDisconnected),4) <> "true") Then
          CCRDisconnected = false
        Else
          CCRDisconnected = true
        End If
      End If

      ' Re-enable debug if it was set before.
      If (Not IsUninitialized(CCR_DEBUG)) Then
          WshEnv("CCR_DEBUG") = CCR_DEBUG
      End If

      ' Stop the scheduler if needed
      Call stopSchedulerOnReconfig(CCRDisconnected)

      If (CCRDisconnected) Then
        ' When we are moving to disconnected mode from being configured against
        ' a repeater earlier (where the repeater was pointing to a different
        ' endpoint than the one originally in ccr.endpoint), stripping out the
        ' registration values causes the upload in processDisconn() to fail.
        ' So in this case, we run the 'emocmrsp -export' after processDisconn()
        Call processDisconn(CCRDisconnected)
        ' Strip out the previous contents of the ccr.properties file containing
        ' registration information.
        Call runProc(EMOCMRSP_BIN,"-no_banner -export """ & RESPONSE_FILE & """")
      Else
        ' If we are moving to connected mode, running 'emocmrsp -export' after
        ' 'processDisconn()' also strips out the ccr.disconnected property which
        ' we add in processDisconn(). Hence, we run processDisconn() first only
        ' when moving to disconnected mode
        Call runProc(EMOCMRSP_BIN,"-no_banner -export """ & RESPONSE_FILE & """")
        Call processDisconn(CCRDisconnected)
      End If

      retStatus = checkLicenseSig()
      If (Not retStatus = SUCCESS) Then
        printDebug "* configCCR - failed license check after instantiation of env"
        Call restoreConfigFiles()
        Quit(retStatus)
      End If

  Else
      ' Should not get here. The response generator can not be
      ' called by VBS due to the prompting that it does.
      WScript.Echo("UNEXPECTED ERROR - Interactive usage of response generator attempted.")
      Call restoreConfigFiles()
      Quit(ERR_UNEXPECTED_FAILURE)
  End If
Else
  retStatus = checkLicenseSig()
  If (Not retStatus = SUCCESS) Then
     printDebug "* configCCR license failed for disconnected install"
     Call restoreConfigFiles()
     Quit(retStatus)
  End If

  Call stopSchedulerOnReconfig(CCRDisconnected)
  ' process the disconnected setting
  Call processDisconn(CCRDisconnected)
End If

If (Not FSO.FileExists(CCR_HOME & "\inventory\core.jar")) Then
  ' 
  ' Addition of the software inventory and version to the collector.properties
  ' file in the CCR_HOME/config directory.
  Dim softwareProps : Set softwareProps = CreateObject("Scripting.Dictionary")
  If (Not IsUninitialized(SOFTWARE_INSTALLER)) Then
      Call softwareProps.Add("ocm.install_source",SOFTWARE_INSTALLER)
  End If
  If (Not isUninitialized(SOFTWARE_INSTALLER_VERSION)) Then
      Call softwareProps.Add("ocm.install_source.version", SOFTWARE_INSTALLER_VERSION)
  End If

  ' Only manipulate the collector.properties if the property was set.
  If (softwareProps.Count > 0) Then
          Call replaceProperties(FSO.BuildPath(CCR_HOME, _
                           FSO.BuildPath("config", "collector.properties")), softwareProps)
  End If
  
  ' Snapshot interesting environment vars
  '
  retStatus = interactive_runProc("cscript //nologo " & CCR_HOME & "\lib\emSnapshotEnv.vbs","", null)
  'dumpExecInfo
  If (Not retStatus = 0) Then
    Call restoreConfigFiles()
    Quit(ERR_UNEXPECTED_FAILURE)
  End If

  '
  ' Persist the computed value of ORACLE_HOME as an environmental variable
  WshEnv("ORACLE_HOME") = LCase(ORACLE_HOME)

  '
  ' deploy core
  '
  Call backupSetupFiles()

  printDebug "deploying Core"
  WScript.Echo ""
  WScript.Echo "** Installing base package **"

  WshEnv("CCR_INSTALL_CODEPATH") = "1"
  CCR_INSTALL_CODEPATH = True

  ExecCommand = "cscript //nologo "& CCR_HOME & "\lib\deployPackages.vbs " & _
                "-i " & CCR_HOME & "\inventory\pending\core.jar"
  Call interactive_runProc(ExecCommand,"", null)
  'dumpExecInfo

  If (Not oExec.ExitCode = 0 Or InStr(lcase(oStdErr),"error") Or InStr(lcase(oStdOut),"error")) Then
    WScript.Echo "Core package could not be deployed."
    Call rollbackCore(CCR_INSTALL_CODEPATH, False)
    errorExit(oExec.ExitCode)
  End If

  '
  '  Fix up perlBin setting
  '
  Dim fileLoc,collPropBakFile,collPropFile,collProp
  fileLoc = findFile("perl.exe", CCR_HOME)
  fileLoc = Replace(fileLoc, "\", "/")

  Dim dictPerlProp : Set dictPerlProp = CreateObject("Scripting.Dictionary")
  Call dictPerlProp.Add("perlBin", fileLoc)
  Call replaceProperties(CCR_HOME & "\config\default\collector.properties", _
                         dictPerlProp)
End If

' Toggle service only during switching i.e.
' if it is not an install codepath
If (Not CCR_INSTALL_CODEPATH) Then
  Dim retValService
  WshEnv("ORACLE_HOME") = LCase(ORACLE_HOME)
  ' Put service name in the environment
  CCR_SCHEDULER_SVCNAME = getOCMServiceName()
  WshEnv("CCR_SCHEDULER_SVCNAME") = CCR_SCHEDULER_SVCNAME

  If (Not CCRDisconnected) Then
    retValService = installService()
  Else
    retValService = uninstallService()
  End If

End If

' Check to see if a registration should be performed
If (Not isInSetupMode(CCR_HOME)) Then
    If (Not CCRDisconnected) Then
      printDebug "registering"

      If (CCR_INSTALL_CODEPATH) Then
        WScript.Echo ""
        WScript.Echo "** Registering installation with Oracle Configuration Manager server(s) **"
      Else
        WScript.Echo ""
        WScript.Echo "** Validating configuration changes with Oracle Configuration Manager server(s) **"
      End If

      '
      ' register with auth server -- set NO UPDATES flag
      '
      WshEnv("CCR_NOUPDATE") = "1"

      ExecCommand = "cscript //nologo "& CCR_HOME & "\lib\emCCRCollector.vbs -silent register"
      Call interactive_runProc(ExecCommand,"", null)
      'dumpExecInfo

      If (Not oExec.ExitCode = 0 Or InStr(lcase(oStdErr),"error") Or InStr(lcase(oStdOut),"error")) Then
        Call rollbackCore(CCR_INSTALL_CODEPATH, False)
        errorExit(ERR_UNEXPECTED_FAILURE)
      End If

      WshEnv.Remove("CCR_NOUPDATE")
    End If

End If
'
' it is now safe to remove the setup backups
Call cleanupBackupSetupFiles()

' Remove setup.exe if possible
' DelFile(CCR_HOME & "\bin\setupCCR.exe")

'
' remove backed up config files
'
Call removeBackupConfigFiles()

If (CCR_INSTALL_CODEPATH) Then
  ExecCommand = "cscript //nologo "& CCR_HOME & "\lib\deployPackages.vbs"
  Call interactive_runProc(ExecCommand,"", null)
  'dumpExecInfo
Else
  ' Remove any and all JARs in the pending directory as a service restart 
  ' may cause a catagrophic and failing upgrade.
  Set pendingFldr = FSO.GetFolder(CCR_HOME & "\inventory\pending")
  Set pendingFiles = pendingFldr.Files

  For Each pendingFile in pendingFiles
    If (LCase(FSO.GetExtensionName(pendingFile.name)) = "jar") Then
      Call FSO.DeleteFile(pendingFile.ShortPath)
    End If
  Next

End If

' Indicate whether the end of install should display the termination
' cleanliness messages.
'
Dim DISPLAY_INSTALL_MSGS
If (CCR_INSTALL_CODEPATH) Then
    DISPLAY_INSTALL_MSGS=True
Else
    DISPLAY_INSTALL_MSGS=False
End If

' If not in disconnected mode, get the updates
' Note this code block is now disabled due to issues uncovered in bug
' 5577165. That the configCCR.exe can not be replaced when it is open
' and causes deployment failures.
If (CCR_INSTALL_CODEPATH And Not CCRDisconnected) Then
  printDebug "getUpdates"
  WScript.Echo ""
  WScript.Echo "** Getting package updates from ContentServer **"

  ExecCommand = "cscript //nologo "& CCR_HOME & "\lib\emCCRCollector.vbs -silent getupdates"
  Call interactive_runProc(ExecCommand,"", null)
  'dumpExecInfo

 ' Excpect exitcode 6 if non mandtory downloads are available and download failed
  If (oExec.ExitCode <> 0 And oExec.ExitCode <> 5 And oExec.ExitCode <> 6 And oExec.ExitCode <> 3 ) Then
    errorExit(ERR_UNEXPECTED_FAILURE)
  End If
  If ( oExec.ExitCode = 3 ) Then
     WScript.Echo ""
     WScript.Echo "Unable to determine whether updates to OCM are present."
     WScript.Echo "The service is unreachable. Continuing with the installation."
  End If 
  '
  ' done with install codepath, proceed normally in the rest
  '
  If (CCR_INSTALL_CODEPATH) Then
    WshEnv.Remove("CCR_INSTALL_CODEPATH")
    CCR_INSTALL_CODEPATH=False
  End If
  '
  ' deploy pending packages
  '
  printDebug "deploy pending packages"

  Set pendingFldr = FSO.GetFolder(CCR_HOME & "\inventory\pending")
  Set pendingFiles = pendingFldr.Files
  printDebug pendingFldr & " contains " & pendingFiles.Count & " files "

  For Each pendingFile in pendingFiles
    printDebug pendingFile
    If (lcase(FSO.GetExtensionName(pendingFile.name)) = "jar") Then

      printDebug "deploy pending pkgs"

      ExecCommand = "cscript //nologo "& CCR_HOME & "\lib\deployPackages.vbs"
      Call interactive_runProc(ExecCommand,"", null)
      'dumpExecInfo

      Exit For
    End If
  Next
End If

'
' Take a list of what is in CCR_HOME/inventory
'
Dim invFile : invFile = CCR_CONFIG_HOME & "\config\default\collector_config.inventory"
Dim invFileStream : Set invFileStream = FSO.OpenTextFile(invFile, ForWriting, True)
ExecCommand = "cscript //nologo "& CCR_HOME & "\lib\deployPackages.vbs -l"
Call runProc2(ExecCommand,"", FALSE)
Dim deployedPkg, deployedTxt, deployedInfo : deployedInfo = Split(oStdOut,vbCrLf,-1)
For Each deployedTxt in deployedInfo
  If (Instr(deployedTxt,"pending deployment")) Then
    Exit For
  ElseIf (Instr(deployedTxt,"Package ") > 0) Then
    deployedPkg = Split(deployedTxt," ",-1)
    ' Need to get this into the mini-inventory file
    invFileStream.WriteLine(Replace(deployedPkg(1),",","=") & deployedPkg(3))
  End If
Next
invFileStream.Close

printDebug "cleanup"

' Check to see whether the scheduler is started.
Dim schedulerStarted
ExecCommand = "" & CCR_HOME & "\bin\emCCR.bat status"
schedulerStarted = runProc2(ExecCommand, "", False)

Dim CCRDev: CCRDev = GetEnvironmentalValue("ORACLE_CCR_DEV")
If (isUninitialized(CCRDev) And Not _
    schedulerStarted = 0 And Not schedulerStarted = 55 And Not _
    CCRDisconnected) Then
  WScript.echo vbcrlf & "** Starting the Oracle Configuration Manager Scheduler **"

  Dim options: options = ""
  Dim installDeferCollect

  installDeferCollect =  GetEnvironmentalValue("CCR_INSTALL_DEFER_COLLECT")
  If (Not isUninitialized(installDeferCollect)) Then
    options = "-noCollect"
  End If

  ExecCommand = "" & CCR_HOME & "\bin\emCCR.bat start" & " " & options 
  Call interactive_runProc(ExecCommand,"", null)
  'dumpExecInfo
End If

' Display the messages in cases of types of installation.
if (DISPLAY_INSTALL_MSGS) Then
    If (CCRDisconnected) Then
        WScript.Echo _
          vbCrLf & _
          "Oracle Configuration Manager has been configured in disconnected mode. If the" & vbCrLf & _
          "target ORACLE_HOME is running a database, please refer to the" & vbCrLf & _
          """Post-installation Database Configuration"" section of the OCM Installation" & vbCrLf & _
          "and Administration Guide" & vbCrLf & _
          "(http://www.oracle.com/technology/documentation/ocm.html) to complete the" & vbCrLf & _
          "installation." & vbCrLf & _
          vbCrLf & _
          "View configuration data reports and access valuable configuration best" & vbCrLf & _
          "practices by going to My Oracle Support." 
    else
        WScript.Echo _
          vbCrLf & _
          "Oracle Configuration Manager has been configured in connected mode. If the" & vbCrLf & _
          "target ORACLE_HOME is running a database, please refer to the" & vbCrLf & _
          """Post-installation Database Configuration"" section of the OCM Installation" & vbCrLf & _
          "and Administration Guide" & vbCrLf & _
          "(http://www.oracle.com/technology/documentation/ocm.html) to complete the" & vbCrLf & _
          "installation."

        Dim propFile : propFile = FSO.BuildPath(CCR_CONFIG_HOME,"config\ccr.properties")
        Dim registrationMethod
        If (FSO.FileExists(propFile)) Then 
            Set dictProps = CreateObject("Scripting.Dictionary")
            Call dictProps.Add("ccr.registration_mode","")
            Set dictResults = getPropertyValues(propFile, dictProps)
            registrationMethod = dictResults.Item("ccr.registration_mode")
        End If
 
        If ( Not isUninitialized(registrationMethod) ) Then
            If ( registrationMethod <> "anon" ) Then
                WScript.Echo vbCrLf & _
                  "View configuration data reports and access valuable configuration best" & vbCrLf & _
                  "practices by going to My Oracle Support."
            End If
        End If
    End If
End If

'*************************
' End MAIN
'*************************

' This function makes a backup of all modified configuration files. Constants
' are declared to be used to refer to the backups. The backup variables follow
' the form [USER|SYSTEM]_<basename-prop-file>_BACKUP
'
' For example, the file $CCR_HOME/config/ccr.properties would have its backup
' named: USER_CCR_BACKUP
'
' Note, previous backups are replaced.
Private Sub backupConfigFiles()
    Dim parentDir

    If (FSO.FileExists(CCR_CONFIG_HOME & "\config\ccr.properties")) Then
	    printDebug "* configCCR backupConfigFiles() - "& CCR_CONFIG_HOME&"\config\default\ccr.properties exists"
        parentDir = FSO.GetParentFolderName( _
                              CCR_CONFIG_HOME & "\config\ccr.properties")
        USER_CCR_BACKUP = FSO.BuildPath(parentDir, FSO.getTempName())
        DelFile(USER_CCR_BACKUP)
        Call FSO.CopyFile(CCR_CONFIG_HOME & "\config\ccr.properties", _
                          USER_CCR_BACKUP)
    End If

    If (FSO.FileExists(CCR_CONFIG_HOME & "\config\default\ccr.properties")) Then
	    printDebug "* configCCR backupConfigFiles() - "& CCR_CONFIG_HOME&"\config\ccr.properties exists"
        parentDir = FSO.GetParentFolderName( _
                              CCR_CONFIG_HOME & "\config\default\ccr.properties")
        USERDEF_CCR_BACKUP = FSO.BuildPath(parentDir, FSO.getTempName())
        DelFile(USERDEF_CCR_BACKUP)
        Call FSO.CopyFile(CCR_CONFIG_HOME & "\config\default\ccr.properties", _
                          USERDEF_CCR_BACKUP)
    End If

    If (FSO.FileExists(CCR_CONFIG_HOME & "\config\collector.properties")) Then
	    printDebug "* configCCR backupConfigFiles() - "& CCR_CONFIG_HOME&"\config\collector.properties exists"
        parentDir = FSO.GetParentFolderName( _
                              CCR_CONFIG_HOME & "\config\collector.properties")
        USER_COLLECTOR_BACKUP = FSO.BuildPath(parentDir, FSO.getTempName())
        DelFile(USER_COLLECTOR_BACKUP)
        Call FSO.CopyFile(CCR_CONFIG_HOME & "\config\collector.properties", _
                          USER_COLLECTOR_BACKUP)
    End If

    If (FSO.FileExists(CCR_CONFIG_HOME & "\config\default\collector.properties")) Then
	    printDebug "* configCCR backupConfigFiles() - "& CCR_CONFIG_HOME&"\config\default\collector.properties exists"
        parentDir = FSO.GetParentFolderName( _
                              CCR_CONFIG_HOME & "\config\default\collector.properties")
        USERDEF_COLLECTOR_BACKUP = FSO.BuildPath(parentDir, FSO.getTempName())
        DelFile(USERDEF_COLLECTOR_BACKUP)
        Call FSO.CopyFile(CCR_CONFIG_HOME & "\config\default\collector.properties", _
                          USERDEF_COLLECTOR_BACKUP)
    End If

End Sub

' Restore the previously saved configuration files. The restoration or state
' relies on the list of saved config files specified in backupConfigFiles()
'
' Note, if the config file did not exist before, it may have been created. 
' the end result is to remove the newly created file too.
Private Sub restoreConfigFiles()
	printDebug "* configCCR restoreConfigFiles() - restoring files"

    If (Not isUninitialized(USER_CCR_BACKUP)) Then
        DelFile(CCR_CONFIG_HOME & "\config\ccr.properties")
        printDebug "* configCCR restoreConfigFiles() - restoring "&CCR_CONFIG_HOME & "\config\ccr.properties"
        Call FSO.MoveFile(USER_CCR_BACKUP, CCR_CONFIG_HOME & "\config\ccr.properties")
    Else
        DelFile(CCR_CONFIG_HOME & "\config\ccr.properties")
    End If

    If (Not isUninitialized(USERDEF_CCR_BACKUP)) Then
        DelFile(CCR_CONFIG_HOME & "\config\default\ccr.properties")
        printDebug "* configCCR restoreConfigFiles() - restoring "&CCR_CONFIG_HOME & "\config\default\ccr.properties"
        Call FSO.MoveFile(USERDEF_CCR_BACKUP, CCR_CONFIG_HOME & "\config\default\ccr.properties")
    Else
        DelFile(CCR_CONFIG_HOME & "\config\default\ccr.properties")
    End If

    If (Not isUninitialized(USER_COLLECTOR_BACKUP)) Then
        DelFile(CCR_CONFIG_HOME & "\config\collector.properties")
        printDebug "* configCCR restoreConfigFiles() - restoring "&CCR_CONFIG_HOME & "\config\collector.properties"
        Call FSO.MoveFile(USER_COLLECTOR_BACKUP, CCR_CONFIG_HOME & "\config\collector.properties")
    Else
        DelFile(CCR_CONFIG_HOME & "\config\collector.properties")
    End If

    If (Not isUninitialized(USERDEF_COLLECTOR_BACKUP)) Then
        DelFile(CCR_CONFIG_HOME & "\config\default\collector.properties")
        printDebug "* configCCR restoreConfigFiles() - restoring "&CCR_CONFIG_HOME & "\config\default\collector.properties"
        Call FSO.MoveFile(USERDEF_COLLECTOR_BACKUP, CCR_CONFIG_HOME & "\config\default\collector.properties")
    Else
        DelFile(CCR_CONFIG_HOME & "\config\default\collector.properties")
    End If

End Sub

' Removes all the backup configuration files created by backupConfigFiles().
' Called at a point where the installation or reconfiguration has successed.
Private Sub removeBackupConfigFiles()
    If (Not isUninitialized(USER_CCR_BACKUP)) Then
        DelFile(USER_CCR_BACKUP)
    End If
    If (Not isUninitialized(USERDEF_CCR_BACKUP)) Then
        DelFile(USERDEF_CCR_BACKUP)
    End If
    If (Not isUninitialized(USER_COLLECTOR_BACKUP)) Then
        DelFile(USER_COLLECTOR_BACKUP)
    End If
    If (Not isUninitialized(USERDEF_COLLECTOR_BACKUP)) Then
        DelFile(USERDEF_COLLECTOR_BACKUP)
    End If

End Sub

'-------------------------
' usage info
'-------------------------
Sub usage()

    Dim usageMsg,scriptName

    If (isInSetupMode(CCR_HOME)) Then
      scriptName = "setupCCR"
    Else
      scriptName = "configCCR"
    End If

   If ( scriptName = "configCCR" ) Then
    usageMsg = "Usage: " &  scriptName & " [ -s ] [ -d | -C <OracleSupportHubUrl> ] [ -a | -r ] [<csi-number> [<MyOracleSupportId>]]" & vbCRLf _
     & "       " & scriptName & " [ -R <response-file> ]"
    WScript.Echo usageMsg
    Else
    usageMsg = "Usage: " &  scriptName & " [ -s ] [ -d | -C <OracleSupportHubUrl> ] [<csi-number> [<MyOracleSupportId>]]" & vbCRLf _
     & "       " & scriptName & " [ -R <response-file> ]"
    WScript.Echo usageMsg
    End If

    If ( scriptName = "configCCR" ) Then
      usageMsg = "       " & scriptName & " -D [ -v ] [ -T <target type> [ -N <target name> [ -P <property name> ]]]"
      WScript.Echo usageMsg
    End If

    usageMsg = "" & vbCrLf _
     & "where:" & vbCrLf _
     & "" & vbCrLf _
     & "      <csi-number>        Oracle Customer Support Identifier (CSI)" & vbCrLf _
     & "      <MyOracleSupportId> My Oracle Support user name registered for the CSI" & vbCrLf _
     & "      <response-file>     Response file generated by emocmrsp" & vbCrLf _
     & "" & vbCrLf _
     & "      -d                  Indicates that the installation will be done in the" & vbCrLf _
     & "                          disconnected mode. All other qualifiers and arguments" & vbCrLf _
     & "                          are ignored." & vbCrLf _
     & "" & vbCrLf _
     & "      -s                  Indicates acceptance of the license agreement found in" & vbCrLf _
     & "                          http://www.oracle.com/support/policies.html." & vbCrLf _
     & "" & vbCrLf _
     & "      -R                  Configures OCM using a specified response file." & vbCrLf _
     & "" & vbCrLf _
     & "      -C                  url for Oracle Support Hub used to connect to" & vbCrLf _
     & "                          Oracle. If NONE is specified, no Oracle Support" & vbCrLf _
     & "                          Hub is to be used to communicate with Oracle" & vbCrLf
    WScript.Echo usageMsg

    If ( scriptName = "configCCR" ) Then
     usageMsg = "      -D                  Configure missing diagcheck properties." & vbCrLf _
     & "" & vbCrLf _
     & "      -v                  Used with configuring diagnostic checks (-D qualifier)." & vbCrLf _
     & "                          Verifies target properties are sufficiently configured." & vbCrLf _
     & "" & vbCrLf _
     & "      -a                  Configures OCM for the current host or ORACLE_CONFIG_HOME." & vbCrLf _
     & "" & vbCrLf _
     & "      -r                  Removes OCM configuration for the current host or ORACLE_CONFIG_HOME." & vbCrLf _
     & "" & vbCrLf _
     & "      -T                  Target type for the target property to be configured" & vbCrLf _
     & "                          or verified. This is used strictly with Diagnostic Checks" & vbCrLf _
     & "                          (-D qualifier)." & vbCrLf _
     & "" & vbCrLf _
     & "      -N                  Target name for the target property to be configured" & vbCrLf _
     & "                          or verified. Target type (-T qualifier) must be specified." & vbCrLf _
     & "                          This is used strictly with Diagnostic Checks (-D qualifier)." & vbCrLf _
     & "" & vbCrLf _
     & "      -P                  Name of the target property to be configured or" & vbCrLf _
     & "                          verified. Value for the property will be prompted." & vbCrLf _
     & "                          Target type (-T) and target name (-N) must be specified." & vbCrLf _
     & "                          This is used strictly with Diagnostic Checks (-D qualifier)." & vbCrLf
    WScript.Echo usageMsg
    End If

End Sub

'-------------------------
' check Arguments
'
' Returns
'   SUCCESS
'   ERR_INVALID_ARG
'   ERR_INVALID_USAGE
'-------------------------
Function checkArgs()

printDebug "checkArgs"

  ' Default return code
  checkArgs = SUCCESS

  Dim allArgs,argIndex,regIndex
  Dim Response_option : Response_option = False
  Set allArgs = WScript.Arguments
  regIndex = 0

  ' set the default mode for disconnected to be false
  CCRDisconnected = False

  For argIndex = 0 to allArgs.count - 1
    If (allArgs(argIndex) = "-h") Then
      If (G_Verify_Syntax <> True) Then
          usage()
          Quit(SUCCESS)
          Exit Function
      End If
    ElseIf (allArgs(argIndex) = "-H") Then
      usage()
      checkArgs = ERR_INVALID_USAGE
      Exit Function
    ElseIf (allArgs(argIndex) = "-c") Then
      Quit(SUCCESS)
      Exit Function
    ElseIf (allArgs(argIndex) = "-s") Then
      CCRSig = "true"
    ElseIf (allArgs(argIndex) = "-d") Then
      CCRDisconnected = True
    ElseIf (allArgs(argIndex) = "-a") Then
      If (G_NewInstall) Then
          Wscript.Echo "Specification of -a on a new installation is not permitted."
          checkArgs = ERR_INVALID_USAGE
          Exit Function
      End If
      a_option = True
      G_ConfigurationRequest = "config"
    ElseIf (allArgs(argIndex) = "-r") Then
      If (G_NewInstall) Then
          Wscript.Echo "Specification of -r during a new installation is not permitted."
          checkArgs = ERR_INVALID_USAGE
          Exit Function
      End If
      r_option = True
      G_ConfigurationRequest = "deconfig"
    ElseIf (allArgs(argIndex) = "-D") Then
      isDiagchecksCmd = True
    ElseIf (allArgs(argIndex) = "-v") Then
      isVerifyDiagProps = True
    ElseIf (allArgs(argIndex) = "-R") Then
      if (argIndex+1 >= allArgs.count) Then
          WScript.Echo "Required value for option ""-R"" is missing."
          WScript.Echo ""
          usage()
          checkArgs = ERR_INVALID_USAGE 
          Exit Function
      Else
          RESPONSE_FILE = allArgs(argIndex+1)
          argIndex = argIndex+1
      End If
    ElseIf (allArgs(argIndex) = "-C") Then
      if (argIndex+1 >= allArgs.count) Then
          WScript.Echo "Required value for option ""-C"" is missing."
          WScript.Echo ""
          usage()
          checkArgs = ERR_INVALID_USAGE 
          Exit Function
      Else
          REPEATER_URL = allArgs(argIndex+1)
          argIndex = argIndex+1
      End If
    ElseIf (allArgs(argIndex) = "-S") Then
      if (argIndex+1 >= allArgs.count) Then
          WScript.Echo "Required value for option ""-S"" is missing."
          WScript.Echo ""
          usage()
          checkArgs = ERR_INVALID_USAGE 
          Exit Function
      Else
          SOFTWARE_INSTALLER = allArgs(argIndex+1)
          argIndex = argIndex+1
      End If
    ElseIf (allArgs(argIndex) = "-V") Then
      if (argIndex+1 >= allArgs.count) Then
          WScript.Echo "Required value for option ""-V"" is missing."
          WScript.Echo ""
          usage()
          checkArgs = ERR_INVALID_USAGE 
          Exit Function
      Else
          SOFTWARE_INSTALLER_VERSION = allArgs(argIndex+1)
          argIndex = argIndex+1
      End If
    ElseIf (allArgs(argIndex) = "-T") Then
      if ( Not isUninitialized(diagcheckTargetType) ) Then
          WScript.Echo "only one -T qualifier is allowed"
          usage()
          checkArgs = ERR_INVALID_USAGE 
          Exit Function
      End If
      if (argIndex+1 >= allArgs.count) Then
          WScript.Echo "Required value for option ""-T"" is missing."
          WScript.Echo ""
          usage()
          checkArgs = ERR_INVALID_USAGE 
          Exit Function
      Else
          diagcheckTargetType = allArgs(argIndex+1)
          argIndex = argIndex+1
      End If
    ElseIf (allArgs(argIndex) = "-N") Then
      if ( Not isUninitialized(diagcheckTargetName) ) Then
          WScript.Echo "only one -N qualifier is allowed"
          usage()
          checkArgs = ERR_INVALID_USAGE 
          Exit Function
      End If
      if (argIndex+1 >= allArgs.count) Then
          WScript.Echo "Required value for option ""-N"" is missing."
          WScript.Echo ""
          usage()
          checkArgs = ERR_INVALID_USAGE 
          Exit Function
      Else
          diagcheckTargetName = allArgs(argIndex+1)
          argIndex = argIndex+1
      End If
    ElseIf (allArgs(argIndex) = "-P") Then
      if ( Not isUninitialized(diagcheckPropertyName) ) Then
          WScript.Echo "only one -P qualifier is allowed"
          usage()
          checkArgs = ERR_INVALID_USAGE 
          Exit Function
      End If
      if (argIndex+1 >= allArgs.count) Then
          WScript.Echo "Required value for option ""-P"" is missing."
          WScript.Echo ""
          usage()
          checkArgs = ERR_INVALID_USAGE 
          Exit Function
      Else
          diagcheckPropertyName = allArgs(argIndex+1)
          argIndex = argIndex+1
      End If
    ElseIf (allArgs(argIndex) = "-VERIFY_SYNTAX") Then
          G_Verify_Syntax = True

    ElseIf (Left(allArgs(argIndex),1) = "-") Then
      WScript.Echo "Invalid command qualifier specified: " & allArgs(argIndex)
      WScript.Echo ""
      usage()
      checkArgs = ERR_INVALID_USAGE
      Exit Function
    Else
      If (regIndex > 2) Then
        ' We should only get up to 3 registration args
        WScript.Echo "Invalid number of arguments"
        WScript.Echo ""
        usage()
        checkArgs = ERR_INVALID_ARG
        Exit Function
      End If

      CCRRegInfo(regIndex) = allArgs(argIndex)
      regIndex = regIndex + 1
    End If
  Next

  ' Check to make certain -a and -r were not specified at the
  ' same time.
  If ( a_option = True And r_option = True ) Then
      WScript.Echo "Options -a and -r are mutually exclusive."
      checkArgs = ERR_INVALID_USAGE
      Exit Function
  End If

  Dim scriptName
  If (isInSetupMode(CCR_HOME)) Then
    scriptName = "setupCCR"
  Else
    scriptName = "configCCR"
  End If

  ' bug 9478596, diagcheck options are not allowed for setupCCR command
  If ( scriptName = "setupCCR" ) Then
      If ( isDiagchecksCmd = True Or _
          isVerifyDiagProps = True Or _
          Not isUninitialized(diagcheckTargetType) Or _
          Not isUninitialized(diagcheckTargetName) Or _
          Not isUninitialized(diagcheckPropertyName)) Then
              WScript.Echo "Diagchecks options -D, -v, -T, -N and -P are invalid for setupCCR command."
              checkArgs = ERR_INVALID_USAGE
              Exit Function
      End If 
  End If

  If ( isDiagchecksCmd = True ) Then
    If ( a_option = True Or r_option = True Or _
         CCRDisconnected = True Or _
         Left(LCase(CCRSig),4) = "true" Or _
         Not isUninitialized(RESPONSE_FILE) Or _
         Not isUninitialized(REPEATER_URL) Or _
         Not isUninitialized(SOFTWARE_INSTALLER) Or _
         Not isUninitialized(SOFTWARE_INSTALLER_VERSION) ) Then
      WScript.Echo "Option -D is for diagcheck only and cannot be combined with other actions such as -a, -r, -d, -s, -R or -C"
      checkArgs = ERR_INVALID_USAGE
      Exit Function
    End If
  End If

  ' -v, -T, -N, -P options are only valid for diagchecks commands
  If ( isVerifyDiagProps = True Or _
       Not isUninitialized(diagcheckTargetType) Or _
       Not isUninitialized(diagcheckTargetName) Or _
       Not isUninitialized(diagcheckPropertyName)) Then
         If ( isDiagchecksCmd <> True ) Then
           WScript.Echo "options -v, -T -N -P are only valid when -D option is used"
           checkArgs = ERR_INVALID_USAGE
           Exit Function
         End If
  End If

  If ( Not isUninitialized(diagcheckTargetName) And _
       isUninitialized(diagcheckTargetType) ) Then
    WScript.Echo "Cannot use -N without specifying -T."
    checkArgs = ERR_INVALID_USAGE
    Exit Function
  End If

  If ( Not isUninitialized(diagcheckPropertyName) ) Then
    If ( isUninitialized(diagcheckTargetType) Or _
         isUninitialized(diagcheckTargetName) ) Then
      WScript.Echo "Cannot use -P without specifying both -T and -N."
      checkArgs = ERR_INVALID_USAGE
      Exit Function
    End If
  End If

  ' Check to make certain -R wasn't specified with any of the other
  ' qualifiers that are invalid.
  If ( Not isUninitialized(RESPONSE_FILE) ) Then
      If ( Not isUninitialized(CCR_PROXY_PARAM) Or _
           Not isUninitialized(CCRSig) Or _
           r_option = True Or _
           CCRDisconnected Or _
           regIndex > 0 ) Then
             WScript.Echo "A response file can not be specified with -s, -d, -C, -r or command line arguments."
             checkArgs = ERR_INVALID_USAGE
             Exit Function
      End If
  End If
        
  ' Check to make certain -C wasn't specified with any of the other
  ' qualifiers that are invalid.
  If ( Not isUninitialized(REPEATER_URL) ) Then
      If ( Not isUninitialized(RESPONSE_FILE) Or _
           r_option = True Or _
           CCRDisconnected ) Then
             WScript.Echo "The Oracle Support Hub URL can not be specified with -R, -d or -r options."
             checkArgs = ERR_INVALID_USAGE
             Exit Function
      End If
  End If
        
  ' When config home is setup then configCCR -a in compatibility mode is not allowed.  
  If (isUninitialized(GetEnvironmentalValue("DERIVECCR_IN_PROGRESS"))) Then
    Dim OCH : OCH = GetEnvironmentalValue("ORACLE_CONFIG_HOME")
    If ( a_option = True And Not isUninitialized(OCH)) Then
        OCH = UnquoteString(OCH)
        If ( compareDirSpec(OCH, ORACLE_HOME) ) Then
            WScript.Echo "ORACLE_CONFIG_HOME can not be the same value as the ORACLE_HOME when adding"
            WScript.Echo "another OCM configuration."
            checkArgs = ERR_INVALID_USAGE
            Exit Function
        End If
    End If
  End If

End Function

'-------------------------
' Check license sig
'
' returns SUCCESS or ERR_LICENSE_DECLINED
'-------------------------
Function checkLicenseSig()

  printDebug "checkLicenseSig"

  Dim btnVal,moreRet
  Dim licenseFile,licenseText
  Dim userIn

  ' Get the default value for the signature
  Dim propFile : propFile = FSO.BuildPath(CCR_CONFIG_HOME,"config\collector.properties")
  Dim defaultSignature
  If (FSO.FileExists(propFile)) Then
    Set dictProps = CreateObject("Scripting.Dictionary")
    Call dictProps.Add("ccr.agreement_signer","")
    Set dictResults = getPropertyValues(propFile, dictProps)
    defaultSignature = dictResults.Item("ccr.agreement_signer")

    If (NOT IsUninitialized(defaultSignature)) Then
      CCRSig = defaultSignature
    End If
  End If

  If (isUninitialized(CCRSig)) Then
  ' prompt user for input
    Wscript.Echo "Visit http://www.oracle.com/support/policies.html for Oracle Technical Support policies."

    CCRSig = "true"
    If (Len(CCRSig) > 0) Then
      checkLicenseSig = SUCCESS
    Else
      checkLicenseSig = ERR_LICENSE_DECLINED
    End If
  Else
    checkLicenseSig = SUCCESS
  End If

  If (checkLicenseSig = SUCCESS) Then
    Set dictProps = CreateObject("Scripting.Dictionary")
    Call dictProps.Add("ccr.agreement_signer", "true")
    Call replaceProperties(propFile, dictProps)
  End If        

End Function

'-----------------------
' Interrogate config - ensure properties file OK
'
' Returns
'   SUCCESS
'   ERR_INVALID_ARG
'-----------------------
Function interrogateConfig()

  printDebug "interrogateConfig"

  ' Get the default values for the CSI, Metalink account and country if
  ' present from the configuration files.
  Dim defaultCSI, defaultMetalinkID, defaultCountryCode
  Dim registration_method, metalink_email_addr, metalink_email_pwd

  Dim propFileName : propFileName = CCR_CONFIG_HOME & "\config\ccr.properties"
  Call GetRegistrationProperties( _
                        propFileName, defaultCSI, defaultMetalinkID, _
                        registration_method, _
                        metalink_email_addr, metalink_email_pwd)

  '
  ' check alternate properties files in case any items left uninitialized
  '
  propFileName = CCR_CONFIG_HOME & "\config\default\ccr.properties"
  Call GetRegistrationProperties( _
                        propFileName, defaultCSI, defaultMetalinkID, _
                        registration_method, _
                        metalink_email_addr, metalink_email_pwd)

  propFileName = CCR_HOME & "\config\ccr.properties"
  Call GetRegistrationProperties( _
                        propFileName, defaultCSI, defaultMetalinkID, _
                        registration_method, _
                        metalink_email_addr, metalink_email_pwd)

  propFileName = CCR_HOME & "\config\default\ccr.properties"
  Call GetRegistrationProperties( _
                        propFileName, defaultCSI, defaultMetalinkID, _
                        registration_method, _
                        metalink_email_addr, metalink_email_pwd)

  If (Len(CCRRegInfo(regCSI)) = 0 Or Len(CCRRegInfo(regMLID)) = 0 Or Len(CCRRegInfo(regCC)) = 0) Then
    Wscript.Echo "The installation requires the following piece(s) of information."
  End If
  ' get CSI, Metalink ID, CountryCode; assume properties file not yet instantiated
  If (isUninitialized(CCRRegInfo(regCSI))) Then
    Wscript.StdOut.Write CSIPrompt ' prompt user for input
    If (Not isUninitialized(defaultCSI)) Then
        Wscript.StdOut.Write "[" & defaultCSI & "] "
    End If
    CCRRegInfo(regCSI) = Wscript.StdIn.ReadLine             ' get CSI
    If (isUninitialized(CCRRegInfo(regCSI)) And isUninitialized(defaultCSI)) Then
      WScript.StdOut.Write("A CSI is required to configure Oracle Configuration Manager.")
      interrogateConfig = ERR_INVALID_ARG
      Exit Function
    Else
      If (isUninitialized(CCRRegInfo(regCSI))) Then
        CCRRegInfo(regCSI) = defaultCSI
      End If
    End If
  End If

  If (isUninitialized(CCRRegInfo(regMLID))) Then
    Wscript.StdOut.Write MOSUsernamePrompt ' prompt user for input
    If (Not isUninitialized(defaultMetalinkID)) Then
        Wscript.StdOut.Write "[" & defaultMetalinkID & "] "
    End If
    CCRRegInfo(regMLID) = Wscript.StdIn.ReadLine     ' get MetaLink ID
    If (isUninitialized(CCRRegInfo(regMLID)) And isUninitialized(defaultMetalinkID)) Then
      WScript.StdOut.Write("A My Oracle Support user name is required to configure Oracle Configuration Manager.")
      interrogateConfig = ERR_INVALID_ARG
      Exit Function
    Else
      If (isUninitialized(CCRRegInfo(regMLID))) Then
        CCRRegInfo(RegMLID) = defaultMetalinkID
      End If
    End If
  End If

  If (isUninitialized(CCRRegInfo(regCC))) Then
    Wscript.StdOut.Write CountryCodePrompt ' prompt user for input
    If (Not isUninitialized(defaultCSI)) Then
        Wscript.StdOut.Write "[" & defaultCountryCode & "] "
    End If
    CCRRegInfo(regCC) = Wscript.StdIn.ReadLine      ' get CC
    If (isUninitialized(CCRRegInfo(regCC)) and isUninitialized(defaultCountryCode)) Then
      WScript.StdOut.Write("The country code is required to configure Oracle Configuration Manager.")
      interrogateConfig = ERR_INVALID_ARG
      Exit Function
    Else
      If (isUninitialized(CCRRegInfo(regCC))) Then
        CCRRegInfo(regCC) = defaultCountryCode
      End If
    End If
  End If

  ' Update the ccr.properties file with the newly retrieved information.
  Dim ccrProps : Set ccrProps = CreateObject("Scripting.Dictionary")
  Call ccrProps.Add("ccr.support_id", CCRRegInfo(regCSI))
  Call ccrProps.Add("ccr.metalink_id", CCRRegInfo(regMLID))
  Call ccrProps.Add("ccr.country_code", CCRRegInfo(regCC))

  propFileName = CCR_CONFIG_HOME & "\config\ccr.properties"
  Call replaceProperties(propFileName, ccrProps)

  interrogateConfig = SUCCESS

End Function

' 
' Stop the scheduler on reconfiguration. This is done based upon a final
' requested state. It should not be called except in specific cases.
Private Sub stopSchedulerOnReconfig(ByVal disconnectedSchedState)

    ' If this is a disconnected case, attempt the stop of the scheduler.
    ' This is done before the state changes to make certain that the command
    ' is still available before switching from connected to disconnected.
    If ( disconnectedSchedState And _
         a_option = False And r_option = False) Then
            If (FSO.FileExists(CCR_HOME & "\bin\emCCR.bat") And _
                G_INIT_DISCONN_STATE = False) Then
                Call runProc(CCR_HOME & "\bin\emCCR.bat stop", "")
            End If
    End If
End Sub

' ----------------------------------------------
' processes the value for the disconnected state
' ----------------------------------------------
' 
Sub processDisconn(ByVal bDisconnectState)
  Dim strDisconnectState

  Dim collectorLock, lockStatus, objCollectorLock, waitMsg
  collectorLock = CCR_CONFIG_HOME & "\state\collector.lock"

  If (bDisconnectState) Then
    strDisconnectState = "true"
  Else
    strDisconnectState = "false"
  End If
 ' Remove the previous state of the disconnection from the config.
  Dim propFile : propFile = FSO.BuildPath(CCR_CONFIG_HOME, "config\collector.properties")
  Set dictProps = CreateObject("Scripting.Dictionary")
  Call dictProps.Add("ccr.disconnected", strDisconnectState)
  Call replaceProperties(propFile, dictProps)


  ' Remove all previous *.ser files if this is a disconnect to switch
  If (bDisconnectState) Then
    If (G_NewInstall = False And G_INIT_DISCONN_STATE = False And _
        a_option = False And r_option = False) Then
        ' Do a collection so that oracle_livelink target's status is uploaded
        lockStatus = lockfile( objCollectorLock, 5, 60, collectorLock, waitMsg )
        If (lockStatus) Then
            Call interactive_runProc("cscript //nologo "& CCR_HOME & "\lib\emCCRCollector.vbs -silent -connect discover collect upload ""-collection=Oracle Configuration Manager,oracle_livelink""","", null)
            Call releaseLockfile(objCollectorLock, collectorLock)
        End If
    End If

    ' DeleteFile throws error if file is not found. So we have to check for
    ' existence thru a loop since FSO.FileExists does not support wildcards
    Dim serFilesExist, prevFile
    serFilesExist = False
    ' First check that the PREVIOUS folder exists or else GetFolder will
    ' return an error if the folder does not exist (eg during initial install)
    If (FSO.FolderExists(CCR_CONFIG_HOME & "\state\previous")) Then
      Dim prevDir : Set prevDir = FSO.GetFolder(CCR_CONFIG_HOME & "\state\previous")
      For Each prevFile in prevDir.Files
        If (LCase(FSO.GetExtensionName(prevFile))="ser") Then
          serFilesExist = True
          Exit For
        End If
      Next
    End If

    If (serFilesExist) Then
      Call FSO.DeleteFile(CCR_CONFIG_HOME & "\state\previous\*.ser", True)
    End if
  End If          

End Sub

'--------------------------
' Rollback core
'
' Arguments:
'    installFlag - type of installation path this was - either a INSTALL or 
'                  RECONFIG step that resulted in the rollback.
'    bSilent     - indicates whether any feedback should be returned.
'--------------------------
Sub rollbackCore(ByVal installCodepath, ByVal bSilent)

  printDebug "rollbackCore"

  If (installCodepath) Then

      ' Delete the emCCRenv if in install codepath - it should not exist.
      Call DelFile(CCR_CONFIG_HOME & "\config\emCCRenv")

      If (FSO.FileExists(CCR_HOME & "\inventory\core.jar")) Then
          ExecCommand = "cscript //nologo "& CCR_HOME & "\lib\deployPackages.vbs " & _
                        "-d " & CCR_HOME & "\inventory\core.jar"
          Call interactive_runProc(ExecCommand,"", null)
          'dumpExecInfo
      End If

      ' Remove the uplinkreg.bin on a failed installation
      Call DelFile(CCR_CONFIG_HOME & "\config\default\uplinkreg.bin")

      ' Restore the backed up setup files.
      Call restoreSetupFiles()

      'put core.jar back into pending inventory
      If FSO.FileExists(CCR_HOME & "\inventory\core.jar") Then
          DelFile(CCR_HOME & "\inventory\pending\core.jar")
          Call FSO.MoveFile(CCR_HOME & "\inventory\core.jar", CCR_HOME & "\inventory\pending\")
      End If
      ' Removing the diagcheck directories if installation fails
      If FSO.FolderExists(CCR_CONFIG_HOME & "\config\diagchecks_exclude") Then
        Call FSO.DeleteFolder(CCR_CONFIG_HOME & "\config\diagchecks_exclude", True)
      End If
      If FSO.FolderExists(CCR_CONFIG_HOME & "\config\diagcheck_wallet") Then
         Call FSO.DeleteFolder(CCR_CONFIG_HOME & "\config\diagcheck_wallet", True)
      End If

  Else
      If (bSilent <> True) Then
         WScript.Echo ""
         WScript.Echo "** Configuration changes restored to previous values... **"
      End If
  End If

  Call restoreConfigFiles()
  Call removeBackupConfigFiles()

End Sub

' Backup all files needed to be saved in the case of a failed deployment.
'
Sub backupSetupFiles()

  Call FSO.CopyFile(CCR_HOME & "\lib\coreutil.vbs", CCR_HOME & "\bin\coreutil.vbs.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\deployPackages.vbs", CCR_HOME & "\bin\deployPackages.vbs.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\emSnapshotEnv.vbs", CCR_HOME & "\bin\emSnapshotEnv.vbs.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\configCCR.vbs", CCR_HOME & "\bin\configCCR.vbs.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\OsInfo.class", CCR_HOME & "\bin\OsInfo.class.save")
  Call FSO.CopyFile(CCR_HOME & "\doc\jsse_license.html", CCR_HOME & "\bin\jsse_license.html.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\emocmutl.vbs", CCR_HOME & "\bin\emocmutl.vbs.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\emocmclnt.jar", CCR_HOME & "\bin\emocmclnt.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\emocmclnt-14.jar", CCR_HOME & "\bin\emocmclnt-14.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\emocmcommon.jar", CCR_HOME & "\bin\emocmcommon.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\osdt_core3.jar", CCR_HOME & "\bin\osdt_core3.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\osdt_jce.jar", CCR_HOME & "\bin\osdt_jce.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\http_client.jar", CCR_HOME & "\bin\http_client.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\jcert.jar", CCR_HOME & "\bin\jcert.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\jnet.jar", CCR_HOME & "\bin\jnet.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\jsse.jar", CCR_HOME & "\bin\jsse.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\log4j-core.jar", CCR_HOME & "\bin\log4j-core.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\regexp.jar", CCR_HOME & "\bin\regexp.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\lib\xmlparserv2.jar", CCR_HOME & "\bin\xmlparserv2.jar.save")
  Call FSO.CopyFile(CCR_HOME & "\bin\emocmrsp.bat", CCR_HOME & "\bin\emocmrsp.bat.save")

End Sub  

' Restores a file to the destination directory
'
Sub restoreFile(ByVal srcdir, ByVal file, ByVal destdir)
  If (IsUninitialized(destdir)) Then
      destdir=srcdir
  End If
  If (FSO.FileExists(FSO.BuildPath(CCR_HOME & "\" & srcdir, file & ".save"))) Then
      Call FSO.MoveFile( FSO.BuildPath(CCR_HOME & "\" & srcdir, file & ".save"), _
                         FSO.BuildPath(CCR_HOME & "\" & destdir, file ))
  End If 
End Sub

' Restore the files backed up prior to setup.
'
Sub restoreSetupFiles()

  If Not FSO.FolderExists(CCR_HOME & "\lib") Then
    Call FSO.CreateFolder(CCR_HOME & "\lib")
  End If

  Call restoreFile("bin", "deployPackages.vbs", "lib")
  Call restoreFile("bin", "coreutil.vbs", "lib")
  Call restoreFile("bin", "configCCR.vbs", "lib")
  Call restoreFile("bin", "emSnapshotEnv.vbs", "lib")
  Call restoreFile("bin", "OsInfo.class", "lib")
  Call restoreFile("bin", "jsse_license.html", "doc")
  Call restoreFile("bin", "emocmrsp.bat", "")
  Call restoreFile("bin", "emocmclnt.jar", "lib")
  Call restoreFile("bin", "emocmclnt-14.jar", "lib")
  Call restoreFile("bin", "emocmcommon.jar", "lib")
  Call restoreFile("bin", "osdt_core3.jar", "lib")
  Call restoreFile("bin", "osdt_jce.jar", "lib")
  Call restoreFile("bin", "http_client.jar", "lib")
  Call restoreFile("bin", "jcert.jar", "lib")
  Call restoreFile("bin", "jnet.jar", "lib")
  Call restoreFile("bin", "jsse.jar", "lib")
  Call restoreFile("bin", "log4j-core.jar", "lib")
  Call restoreFile("bin", "regexp.jar", "lib")
  Call restoreFile("bin", "xmlparserv2.jar", "lib")
  Call restoreFile("bin", "emocmutl.vbs", "lib")
End Sub

' Clean up the backup store (files saved for backup)
'
Sub cleanupBackupSetupFiles()
  Call delFile(CCR_HOME & "\bin\deployPackages.vbs.save")
  Call delFile(CCR_HOME & "\bin\coreutil.vbs.save")
  Call delFile(CCR_HOME & "\bin\configCCR.vbs.save")
  Call delFile(CCR_HOME & "\bin\emSnapshotEnv.vbs.save")
  Call delFile(CCR_HOME & "\bin\OsInfo.class.save")
  Call delFile(CCR_HOME & "\bin\jsse_license.html.save")
  Call delFile(CCR_HOME & "\bin\emocmutl.vbs.save")
  Call delFile(CCR_HOME & "\bin\emocmclnt.jar.save")
  Call delFile(CCR_HOME & "\bin\emocmclnt-14.jar.save")
  Call delFile(CCR_HOME & "\bin\emocmcommon.jar.save")
  Call delFile(CCR_HOME & "\bin\osdt_core3.jar.save")
  Call delFile(CCR_HOME & "\bin\osdt_jce.jar.save")
  Call delFile(CCR_HOME & "\bin\http_client.jar.save")
  Call delFile(CCR_HOME & "\bin\jcert.jar.save")
  Call delFile(CCR_HOME & "\bin\jnet.jar.save")
  Call delFile(CCR_HOME & "\bin\jsse.jar.save")
  Call delFile(CCR_HOME & "\bin\log4j-core.jar.save")
  Call delFile(CCR_HOME & "\bin\regexp.jar.save")
  Call delFile(CCR_HOME & "\bin\xmlparserv2.jar.save")
  Call delFile(CCR_HOME & "\bin\emocmrsp.bat.save")
End Sub

Sub configAnInstance()
  If (SupportsSharedHomes(CCR_HOME)) Then
    If (Not IsOCMConfigured(False)) Then
      Call GetCCRConfigHome(CCR_HOME, CCR_CONFIG_HOME)
      CreateConfigTree(CCR_CONFIG_HOME)
      setPermissions()
      If ( CompareDirSpec(CCR_HOME, CCR_CONFIG_HOME) <> True ) Then
          If (FSO.FileExists(CCR_HOME & "\config\collector.properties")) Then
              Call FSO.CopyFile(CCR_HOME & "\config\collector.properties", _
                  CCR_CONFIG_HOME & "\config\collector.properties")
          End If
      End If
      Call PersistCcrBinHomeConfig(CCR_HOME)
      If Not (CCR_INSTALL_CODEPATH = True) Then
        retStatus = interactive_runProc("cscript //nologo " & CCR_HOME & "\lib\emSnapshotEnv.vbs","", null)
        Call configureScheduler()  
      End If
    Else
      WScript.Echo "This installation is already configured for OCM. Please remove existing configuration first."
      WScript.Quit(ERR_PREREQ_FAILURE)
    End If
  Else
    WScript.Echo "This OCM install can only support one instance."
    WScript.Quit(ERR_PREREQ_FAILURE)
  End If
  G_ConfigurationCompleted = True
End Sub

'
' Store the ocm binary home directory tree based upon information
' stored in the sharedHome and persisted as part of configuration.
Sub PersistCcrBinHomeConfig(ByVal ccrBinHome)
  If SupportsSharedHomes(ccrBinHome) Then
    Dim ccrConfigHome
    Call GetCCRConfigHome(ccrBinHome, ccrConfigHome)

    Dim collectorPropFile 
    collectorPropFile = FSO.BuildPath( _
              FSO.BuildPath(ccrConfigHome, "config"), _
              "collector.properties")

    Dim dictProps : Set dictProps = CreateObject("Scripting.Dictionary")
    ' escape special characters for Java compatibility
    Call escapeSpecialChars(ccrBinHome)
    Call dictProps.Add("ccr.binHome",ccrBinHome)

    Call ReplaceProperties(collectorPropFile, dictProps)
  End If
End Sub

Sub deconfigInstance()
  If SupportsSharedHomes(CCR_HOME) Then
    Call GetCCRConfigHome(CCR_HOME, CCR_CONFIG_HOME)
    If (G_ConfigurationRequest = "deconfig" And _
        FSO.FolderExists(CCR_CONFIG_HOME) And _
        compareDirSpec(CCR_HOME, CCR_CONFIG_HOME)) Then
      WScript.Echo "Removing the configuration where %ORACLE_CONFIG_HOME% is the same as "
      WScript.Echo "the parent directory of the ccr directory ("+ CCR_HOME + ") is not permitted."
      WScript.Quit(ERR_PREREQ_FAILURE)
    End If
    ' Remove CCR_CONFIG_HOME tree
    ' need to stop and uninstall the service first though
    WshEnv("ORACLE_HOME") = LCase(ORACLE_HOME)
    CCR_SCHEDULER_SVCNAME = getOCMServiceName()
    WshEnv("CCR_SCHEDULER_SVCNAME") = CCR_SCHEDULER_SVCNAME

    If (G_ConfigurationCompleted Or G_ConfigurationRequest = "deconfig") Then
      If (FSO.FileExists(CCR_HOME & "\bin\emCCR.bat")) Then
        If (Not IsDisconnected()) Then
          WScript.Echo "Stopping Oracle Configuration Manager"
          Call interactive_runProc(CCR_HOME & "\bin\emCCR.bat stop_abort","", null)
        End If
      End If
    End If

    printdebug " Remove service " & CCR_SCHEDULER_SVCNAME
    Dim rvs : rvs = uninstallService()
    If FSO.FolderExists(CCR_CONFIG_HOME) And Not compareDirSpec(CCR_CONFIG_HOME, CCR_HOME) Then
      If (G_ConfigurationRequest = "deconfig") Then
          WScript.Echo "Removing writeable/state directories under " & CCR_CONFIG_HOME
      End If
      
      If (G_ConfigurationRequest = "deconfig" Or _
          G_ConfigurationCompleted) Then
          removeDirectory(FSO.BuildPath(CCR_CONFIG_HOME, "config"))
          removeDirectory(FSO.BuildPath(CCR_CONFIG_HOME, "state"))
      End If
  
      If (G_ConfigurationRequest = "deconfig") Then
          removeDirectory(FSO.BuildPath(CCR_CONFIG_HOME, "log"))
      End If
    End If
  Else
    If (G_ConfigurationRequest = "deconfig") Then
        WScript.Echo "This OCM install can support only one host."
        WScript.Quit(ERR_PREREQ_FAILURE)
    End If
  End If
End Sub

' 
' Remove a directory, flag any error and contine
'
Sub removeDirectory(ByVal directory)
    On Error Resume Next
    Call FSO.DeleteFolder(directory, True)
    If (Err.Number <> 0) Then
        WScript.Echo "Error removing " & directory & ": " & Err.Description
    End If
    On Error Goto 0
End Sub

'
' This function looks at the scheduler properties and sets the scheduler 
' collection entry if the entry is not present already.
'
Sub configureScheduler()
  If Not FSO.FileExists(CCR_CONFIG_HOME & "\config\default\sched.properties") Then
    Dim nowTime,frequency,schedHour,schedMinute,schedDow
    nowTime = Now
    ' run daily
    frequency = "DAILY"
    schedHour = Hour(nowTime)
    schedMinute = Minute(nowTime)
    schedDow = dayName(Weekday(nowTime))

    Dim schedFileTmpl,schedFile,schedEntry,schedArray,schedPiece,schedOut

    Set schedFileTmpl = FSO.OpenTextFile(CCR_HOME & "\config\default\sched.properties.template", ForReading)
    Set schedFile = FSO.OpenTextFile(CCR_CONFIG_HOME & "\config\default\sched.properties", ForWriting, True)

    Do Until (schedFileTmpl.AtEndOfStream)
      schedEntry = schedFileTmpl.ReadLine
      If(Instr(schedEntry,"%") > 0) Then
        schedArray = Split(schedEntry,"%",-1)
        Dim arrayIndex
        arrayIndex = 0
        For Each schedPiece In schedArray
          Select Case schedPiece
            Case "FREQUENCY"
              schedOut = schedOut & frequency
            Case "HOUR"
              schedOut = schedOut & schedHour
            Case "MINUTE"
              schedOut = schedOut & schedMinute
            Case "DAY_OF_WEEK"
              schedOut = schedOut & schedDow
            Case Else
              If ((arrayIndex Mod 2) = 0) Then
                schedOut = schedOut & schedPiece
              Else
                schedOut = schedOut & "%" & schedPiece & "%"
              End If
          End Select
        arrayIndex = arrayIndex + 1
        Next
        schedFile.WriteLine(schedOut)
      Else
        schedFile.WriteLine(schedEntry)
      End If
    Loop

    schedFileTmpl.Close
    schedFile.Close

  End If
End Sub

Sub delFile(fileSpec)
  If FSO.FileExists(fileSpec) Then
    printDebug "Removing " & fileSpec
    Call FSO.DeleteFile(fileSpec, True)
  End If
End Sub

Function findFile(byval fileName, startFolder)
  Dim FSO,currFolder,Folder
  Set FSO = CreateObject("Scripting.FileSystemObject")
  fileName = Replace("\" & fileName,"\\","\")
  If Not FSO.FolderExists(startFolder) Then
    WScript.Stderr.WriteLine(startFolder & " does not exist on this system.")
    Exit Function
  End If
  Set currFolder = FSO.GetFolder(startFolder)
  If FSO.FileExists(currFolder & fileName) Then
    findFile = currFolder
    Exit Function
  End If
  For Each Folder in currFolder.SubFolders
    findFile = findFile(fileName,Folder)
    If Len(findFile) > 0 Then
      Exit Function
    End If    
  Next
End Function

'--------------------------
' Installs the OCM Service
'--------------------------
Function installService
  'Install the service
  call runProc(CCR_HOME & "\bin\nmzctl.exe", " install")
  dumpExecInfoErrOnly
  installService = oExec.ExitCode
End Function

'-------------------------------------------------------------
' Removes the service from Service Control Manager's database
'-------------------------------------------------------------
Function uninstallService  
  If FSO.FileExists(CCR_HOME & "\bin\nmzctl.exe") Then
    'uninstall the service
    uninstallService = runProc(CCR_HOME & "\bin\nmzctl.exe", " uninstall")
    dumpExecInfoErrOnly
  Else
    'Nothing to do
    uninstallService = 0
  End If  
End Function

'
'Assign file access permissions for CCR_CONFIG_HOME subdirs
' ONLY on NTFS filesystems
'
Private Function setPermissions()
  setPermissions = 0
  Dim drv : Set drv = FSO.GetDrive(FSO.GetDriveName(CCR_CONFIG_HOME))
  If drv.FileSystem = "NTFS" Then
    'Allow full access to SYSTEM account and Administrators group
    '
    'We get the Administrators group name using a well-known SID in our query
    '
    Dim WshNetwork : Set WshNetwork = WScript.CreateObject("WScript.Network")
    Dim hostName : hostName = LCase(WshNetwork.ComputerName)
    Dim objWMIService,colAccounts,objAccount,adminGroupName,creatorName
    ' default
    adminGroupName = "Administrators"
    creatorName = "Creator Owner"
    ' Wrap in a resume block
    On Error Resume Next
    Set objWMIService = GetObject("winmgmts:\\" & hostName & "\root\cimv2")
    If objWMIService Is Not Nothing Then
      Dim objLocator,objService,objSID
      Set objLocator = CreateObject("WbemScripting.SWbemLocator")
      Set objService = objLocator.ConnectServer ("", "root/cimv2")
      objService.Security_.impersonationlevel = 3
      objService.Security_.Privileges.AddAsString "SeSecurityPrivilege", TRUE

      ' get administrators group name
      Set objSID = objService.Get("Win32_SID.SID=""S-1-5-32-544""")
      adminGroupName = objSID.AccountName

      ' get creator owner name
      Set objSID = objService.Get("Win32_SID.SID=""S-1-3-0""")
      creatorName = objSID.AccountName

    End If
    On Error Goto 0
    '
    'Note: " echo y| cacls" and NOT " echo y | cacls". Should NOT be any space between y and |
    '
    setPermissions = runProc(" echo y| cacls " & CCR_CONFIG_HOME & "\config /T /G SYSTEM:F " & adminGroupName & ":F """ & creatorName & """:F", "")
    setPermissions = runProc(" echo y| cacls " & CCR_CONFIG_HOME & "\state /T /G SYSTEM:F " & adminGroupName & ":F  """ & creatorName & """:F", "")
    setPermissions = runProc(" echo y| cacls " & CCR_CONFIG_HOME & "\log /T /G SYSTEM:F " & adminGroupName & ":F  """ & creatorName & """:F", "")
  End If
End Function

' Includes the core utility file.
Private Sub IncludeCoreUtils
    Dim CoreUtils, tmpCCRRootObj
    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")

    ' Derive the location of the temporary CCR_HOME from the script
    ' name. Its the parent directory of the parent directory.
    Set tmpCCRRootObj = FSO.GetFolder( _
                            FSO.GetParentFolderName( _
                                FSO.GetParentFolderName(WScript.ScriptFullName)))

    CoreUtils = FSO.BuildPath( _
                    FSO.BuildPath( tmpCCRRootObj.ShortPath, "lib" ), _
                    "coreutil.vbs" )

    IncludeFileAbs CoreUtils
End Sub

' Includes a file in the global namespace of the current script.
' The file can contain any VBScript source code.
' The path of the file name must be specified absolute (or
' relative to the current directory).
Private Sub IncludeFileAbs (ByVal FileName)
   Dim f: set f = FSO.OpenTextFile(FileName,ForReading)
   Dim s: s = f.ReadAll()
   ExecuteGlobal s
End Sub

'---------------------------------------------------------------------
' errorExit(errCode)
'
'   Must only accept the error codes that are specified in the 
'   module definition - otherwise, it returns a ERR_UNEXPECTED_FAILURE
'---------------------------------------------------------------------
Sub errorExit(errCode)
    If (errCode <> SUCCESS And G_ConfigurationCompleted) Then
        Dim confFile
        confFile = FSO.BuildPath(_
                      FSO.BuildPath(CCR_CONFIG_HOME,"config"),"collector.properties")
        If (FSO.FileExists(confFile)) Then
            FSO.DeleteFile(confFile)
        End If
    End If

    If (errCode < SUCCESS or errCode > ERR_LICENSE_DECLINED) Then
       Quit(ERR_UNEXPECTED_FAILURE)  
    Else
       Quit(errCode)
    End If
End Sub

' Exit routine to do clean up and exit
Function Quit(retCode)
  ' now *really* quit
  WScript.Quit(retCode)
End Function

' WSH prerequisite checks
Private Function WSHPrerequisiteChecks()
    Dim vbVersion : vbVersion = WScript.Version
    Dim vbVerArray : vbVerArray = split(vbVersion,".",-1)
    WSHPrerequisiteChecks = SUCCESS
    If (StrComp(vbVerArray(0),"5") < 0) or (StrComp(vbVerArray(1),"6") < 0) Then
        WScript.Echo "WSH 5.6 or later required; current version is " & vbVersion
        WSHPrerequisiteChecks = ERR_PREREQ_FAILURE
    End If
End Function

