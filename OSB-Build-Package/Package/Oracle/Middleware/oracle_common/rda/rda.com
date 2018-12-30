$!
$!###########################################################################
$! Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.
$! Shell Script Wrapper for perl and zip
$!
$! $Id: rda.com,v 2.6 2012/01/02 14:11:56 mschenke Exp $
$! ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/bin/rda.com,v 2.6 2012/01/02 14:11:56 mschenke Exp $
$!
$!###########################################################################
$ save_file_sharing = "UNKNOWN"
$ save_perl_env     = "UNKNOWN"
$ save_rda_edit     = "UNKNOWN"
$ rda_perl_sym      = "UNKNOWN"
$ my_delete         = "delete"
$!
$ on ERROR then goto the_end
$ on CONTROL_Y then goto the_end
$!
$ this_script      = f$environment ("PROCEDURE")
$ this_script_dev  = f$parse (this_script,,,"DEVICE")
$ this_script_dir  = f$parse (this_script,,,"DIRECTORY")
$ len_script_dir   = f$length(this_script_dir)
$ if f$locate("<", this_script_dir) .lt. len_script_dir .or. -
     f$locate(">", this_script_dir) .lt. len_script_dir
$ then
$   echo ""
$   echo "RDA.COM ERROR:"
$   echo ""
$   echo "This command procedure - ''this_script'"
$   echo "contains < > instead of [ ] for the directory specification."
$   echo ""
$   echo "Use of < > in directory specifications is not supported by Oracle Corporation."
$   echo ""
$   echo ""
$   exit %X184CA     ! %RMS-E-DIR, error in directory name
$ endif
$!
$! Check for the Perl symbol
$!
$ pipe show symbol PERL | search/output=nl:/nohead/nowarn/nolog sys$input "="
$ if $STATUS .eqs. "%X18D78053"
$ then
$    if f$trnlnm("PERL_ROOT") .nes. "" 
$    then
$       PERL :== "$PERL_ROOT:[000000]PERL.EXE"
$       rda_perl_sym = "set"
$    else
$       TYPE/PAGE SYS$INPUT

  WARNING: Unable to detect a PERL symbol, or find the logical PERL_ROOT

           Please check the state of PERL on this system.

           PERL can be downloaded from
             http://h71000.www7.hp.com/opensource/opensource.html

$       goto the_end
$    endif
$ endif
$!
$! Test if we can execute Perl
$!
$ SET MESSAGE /NOFACILITY /NOIDENTIFICATION /NOSEVERITY /NOTEXT
$ SET NOON
$ PIPE PERL -v > nl:
$ cur_sev = $SEVERITY
$ SET MESSAGE /FACILITY /IDENTIFICATION /SEVERITY /TEXT
$ SET ON
$!
$ if cur_sev .ne. 1
$ then
$    TYPE/PAGE SYS$INPUT

  WARNING: Unable to execute Perl

           Please check the state of PERL on this system.

           PERL can be downloaded from
             http://h71000.www7.hp.com/opensource/opensource.html

$    goto the_end
$ endif
$!
$!  Check for Perl version 5.6 if so, prevent autoflush
$!
$ PIPE PERL -v | -
  search/output=nl:/nohead/nowarn/nolog sys$input "V5.6" > nl:
$ if $status .eqs. "%X10000001"
$ then
$    save_rda_edit = f$trnlnm("RDA_EDIT")
$    define/nolog rda_edit "RDA_FLUSH=0"
$ endif
$!
$! Check for the zip symbol
$!
$ zip_flg = "TRUE"
$ pipe show symbol ZIP | search/output=nl:/nohead/nowarn/nolog sys$input "="
$ if $STATUS .eqs. "%X18D78053"
$ then
$    if f$search("SYS$SYSTEM:ZIP.EXE") .nes. ""
$    then
$       ZIP := "$SYS$SYSTEM:ZIP.EXE"
$    else
$       zip_flg = "FALSE"
$       TYPE/PAGE SYS$INPUT

  WARNING: Unable to detect a ZIP symbol, or find file SYS$SYSTEM:ZIP.EXE.

           Please add the symbol if you already have ZIP on your system.

           ZIP utilities can be downloaded from
             http://h71000.www7.hp.com/opensource/opensource.html

           This is not a fatal error, but will prevent the production
           of the RDA results ZIP file. You can still send the resulting
           output files to Oracle Support (using VMS BACKUP or similar).

$       INQUIRE /NOPUNCTUATION answer$$ "Press [RETURN] to continue:  "
$    endif
$ endif
$!
$! Test if we can execute ZIP
$!
$ if zip_flg
$ then
$    SET MESSAGE /NOFACILITY /NOIDENTIFICATION /NOSEVERITY /NOTEXT
$    SET NOON
$    DEFINE/USER_MODE SYS$OUTPUT NL:
$    ZIP -h
$    cur_sev = $SEVERITY
$    SET MESSAGE /FACILITY /IDENTIFICATION /SEVERITY /TEXT
$    SET ON
$    if cur_sev .ne. 1
$    then
$       zip_flg = "FALSE"
$       TYPE/PAGE SYS$INPUT

  WARNING: Unable to execute ZIP.

           Please check the status of ZIP.

           ZIP utilities can be downloaded from
             http://h71000.www7.hp.com/opensource/opensource.html

           This is not a fatal error, but will prevent the production
           of the RDA results ZIP file. You can still send the resulting
           output files to Oracle Support (using VMS BACKUP or similar).

$       INQUIRE /NOPUNCTUATION answer$$ "Press [RETURN] to continue:  "
$    endif
$ endif
$!
$! Save the current settings (if present) and establish the RDA
$! environment.
$!
$ save_perl_env = f$trnlnm("PERL_ENV_TABLES","LNM$PROCESS")
$ if save_perl_env .nes. ""
$ then
$    elm = 1
$ind_loop:
$    if f$trnlnm("PERL_ENV_TABLES","LNM$PROCESS",elm) .nes. ""
$    then
$       save_perl_env = save_perl_env + -
              "," + f$trnlnm("PERL_ENV_TABLES","LNM$PROCESS",elm)
$       elm = elm + 1
$       goto ind_loop
$    endif
$    DEASSIGN PERL_ENV_TABLES
$ endif
$!
$!  Build the list of the current search structure in LNM$FILE_DEV
$!
$ dflt = ""
$!
$!  Have we got one at PROCESS level (if not use SYSTEM)
$!
$ lnmdir = "LNM$PROCESS_DIRECTORY"
$ lnm_file_dev = f$trnlnm("LNM$FILE_DEV",lnmdir)
$ if lnm_file_dev .eqs. "" then lnmdir = "LNM$SYSTEM_DIRECTORY"
$!
$!  Get the number of entries
$!
$ max_idx = f$trnlnm("LNM$FILE_DEV",lnmdir,,,,"MAX_INDEX")
$ idx = 0
$!
$!  build the list we need for Perl
$!
$LNM_LOOP:
$  lnm = f$trnlnm("LNM$FILE_DEV",lnmdir,idx)
$! 
$  if dflt .nes. "" then dflt = dflt+","
$  dflt = dflt+lnm
$!
$! Increment our current index and get the next element in the array
$!
$  idx = idx + 1
$  if idx .le. max_idx then goto lnm_loop
$!
$!  Job done, set PERL_ENV_TABLES to the results
$!
$ DEFINE/NOLOG PERL_ENV_TABLES CRTL_ENV,'dflt'
$!
$! Allow to open files multiple times
$!
$ save_file_sharing = f$trnlnm("DECC$FILE_SHARING")
$ if save_file_sharing .nes. "" then DEASSIGN DECC$FILE_SHARING
$ DEFINE/NOLOG DECC$FILE_SHARING "ENABLE"
$!
$! Execute RDA
$!
$ write sys$output " "
$ write sys$output " RDA Environment established. Executing..."
$ write sys$output " "
$!
$!  Build the perl command
$!
$!  Capture all passed parameters.
$!  Note that in order to preserve lowercase parameters,
$!  they must be passed in wrapped in quotes.
$!
$!  e.g  $ @RDA "-vdCRP"
$!
$ rda_params = ""
$ cnt = 1
$!
$!  Loop through the parameters passed to us and build the string
$!
$param_loop:
$ str = p'cnt'
$ if str .nes. "" 
$ then
$    if cnt .eq. 1
$    then
$       rda_params =  str
$    else
$       rda_params = rda_params + """ """ + str
$    endif
$    cnt = cnt + 1
$    if cnt .le. 8 then goto param_loop
$ endif
$!
$ if rda_params .eqs. ""
$ then 
$    perl_command = "perl rda.pl"
$ else
$    perl_command = "perl rda.pl """ + rda_params + """
$ endif
$!
$!  Execute the command
$!  Redirect SYS$INPUT to get input from the terminal
$!
$ DEFINE/USER_MODE SYS$INPUT SYS$COMMAND
$ 'perl_command
$!
$THE_END:
$!
$! Cleanup up the logicals/symbols we have created or overwritten
$! for the RDA envrionment.
$!
$ if save_perl_env .nes. "UNKNOWN"
$ then
$    if save_perl_env .nes. ""
$    then
$       define/nolog PERL_ENV_TABLES 'save_perl_env
$    else
$       deassign PERL_ENV_TABLES
$    endif
$ endif
$!
$ if save_file_sharing .nes. "UNKNOWN"
$ then
$    if save_file_sharing .nes. ""
$    then
$       define/nolog DECC$FILE_SHARING 'save_file_sharing
$    else
$       deassign DECC$FILE_SHARING
$    endif
$ endif
$!
$ if save_rda_edit .nes. "UNKNOWN"
$ then
$    if save_rda_edit .nes. ""
$    then
$       define/nolog RDA_EDIT "''save_rda_edit'"
$    else
$       deassign RDA_EDIT
$    endif
$ endif
$!
$ if rda_perl_sym .nes. "UNKNOWN" -
         then my_delete/symbol/global perl
$!
$ EXIT
