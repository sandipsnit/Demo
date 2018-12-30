' $Header: emll/lib/emocmutl.vbs /main/7 2010/12/21 13:18:03 fmorshed Exp $
'
' Copyright Oracle 2006, 2010. All Rights Reserved
'
'    NAME
'      ocmutl.vbs - utility commands
'
'    DESCRIPTION
'      This script is used to invoke named utility functions that
'      return information or state to a wrapping shell script.
'
'    EXIT VALUES
'      0 - Success
'      1 - Prerequisite failure
'      2 - Invalid argument specified
'
'    MODIFIED
'      fmorshed 12/15/10 - getNLevelJavaHome now takes a verbose parameter
'      jsutton  07/22/10 - fix up cacls arguments
'      qding    04/07/10 - add set_permissions command option
'      jsutton  03/19/10 - Add WSH version check
'      ndutko   11/16/08 - Add interface to return the hostname
'      ndutko   05/08/08 - XbranchMerge ndutko_bug-7028658 from st_emll_10.3.0
'      ndutko   05/08/08 - Support of getting JAVA_HOME in the great
'                          grandparent if the grandparent doesn't contain a
'                          jdk. Note, this is in support of opatch deployment.
'      ndutko   03/17/08 - initial
'
Option Explicit

Dim WshShell,WshEnv

Dim oExec,oStdErr,oStdOut

Dim FSO
Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8
Const TempFolder = 2

' Constants to be used in exit codes.
Const SUCCESS = 0
Const ERR_PREREQ_FAILURE = 1
Const ERR_INVALID_ARG = 2

' Function constants
Const ORACLE_HOME_PARENT_LEVEL = 2

Dim JavaHome

' Set banner info
Const VersionInfo = "Oracle Configuration Manager - Release: %version-num%.%build.number% - %version-release%"
Const CopyrightInfo = "%copyright-info%"

' WSH prerequisite check
Dim vbVersion,vbVerArray
vbVersion = WScript.Version
vbVerArray = split(vbVersion,".",-1)
If (StrComp(vbVerArray(0),"5") < 0) or (StrComp(vbVerArray(1),"6") < 0) Then
    WScript.Echo "WSH 5.6 or later required; current version is " & vbVersion
    WScript.Quit (ERR_PREREQ_FAILURE)
End If

' Processing begins here
Set WshShell = WScript.CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
Set WshEnv = WshShell.Environment("PROCESS")

' Include core utility
IncludeCoreUtils

' Get the path variable settings given the script execution
Dim CCR_HOME, CCR_BIN, ORACLE_HOME, CCR_LIB, CCR_TEMP, CCR_CONFIG_HOME
Call GetPaths(CCR_HOME, CCR_BIN, ORACLE_HOME, CCR_CONFIG_HOME)

Dim args, argVal
Set args = WScript.Arguments

If args.Count <= 0 Then
    WScript.Echo "Command options are: check_java_prereqs | get_env"
    WScript.Quit (ERR_INVALID_ARG)
End If

For Each argVal In args
  Select Case argVal
      Case "get_env"
          Call get_env

      Case "check_java_prereqs"
          WScript.Quit(check_java_prereqs())

      Case "get_hostname"
          WScript.Echo getNonDHCPHostname

      Case "set_walletPermissions"
          WScript.Quit(setWalletPermissions())

      Case Else
          WScript.Echo "Unknown Command argument"
          WScript.Quit(ERR_INVALID_ARG)
  End Select
Next

' Wallet file created by OracleWallet API has permissions only for
' the logon user, we need to set the permissions so that the OCM
' nmz service which is launched as a local system user can access the file
' Code is essentially copied from the setPermissions function from 
' install/core/postinstall.vbs
Function setWalletPermissions()
  setWalletPermissions = 0
  Dim walletFile
  walletFile = FSO.BuildPath( CCR_CONFIG_HOME, "config\diagcheck_wallet\ewallet.p12")

  If (Not FSO.FileExists(walletFile)) Then
    Exit Function
  End If

  Dim drv : Set drv = FSO.GetDrive(FSO.GetDriveName(walletFile))
  If drv.FileSystem = "NTFS" Then
    'Allow full access to SYSTEM account and members of Administrators group
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
    ' set permissions

    setWalletPermissions = runProc(" echo y| cacls """ & walletFile & """ /T /G SYSTEM:F " & adminGroupName & ":F """ & creatorName & """:F", "")
  End If
End Function

' Determine if we meet the minimum for java requirements.
'
Function check_java_prereqs()
  check_java_prereqs=SUCCESS
  Dim JavaHome

  ' Search for the java home to the great grandparent directory. OPatch install
  ' scenario.
  If (NOT getNLevelJavaHome(JavaHome, ORACLE_HOME_PARENT_LEVEL, True)) Then
    check_java_prereqs=ERR_PREREQ_FAILURE
  End If
End Function

' Return the ORACLE_HOME, OCM_HOME, CCR_CONFIG_HOME, and JAVA_HOME
Sub get_env()
  Dim javaHome

  ' Search for the java home to the great grandparent directory. OPatch install
  ' scenario
  Call getNLevelJavaHome(javaHome, ORACLE_HOME_PARENT_LEVEL, True)
  printDebug "* emocmutl JavaHome = " & javaHome
  WScript.Echo ORACLE_HOME & "," & CCR_HOME & "," & CCR_CONFIG_HOME & "," & javaHome
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
