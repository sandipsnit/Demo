                   RDA - Oracle Remote Diagnostic Agent (RDA)


PURPOSE
=======
RDA is a set of command line diagnostic scripts that are executed by an engine
written in the Perl programming language. RDA is used to gather detailed
information about an Oracle environment; the data gathered is in turn used to
aid in problem diagnosis. The output is also useful for seeing the overall
system configuration.

Oracle Support encourages the use of RDA because it provides a comprehensive
picture of the customer's environment. This can greatly reduce service request
resolution time by minimizing the number of requests from Oracle Customer
Support for more information. RDA is designed to be as unobtrusive as possible;
it does not modify systems in any way, it only collects useful data for Oracle
Customer Support.

INSTALLATION INSTRUCTIONS
=========================
To install RDA, extract the tar or tar.gz archive contents into a new
directory, preserving the directory structure of the archive. Do not extract
into a directory that contains an older RDA version.

Example:
  tar xvf rda.tar
or
  gunzip rda.tar.gz
  tar xvf rda.tar

Important: Do not extract the contents of the RDA archive (rda.tar and
rda.tar.gz) on a Windows client first. If you do, you will have to remove the
^M characters from the end of each line in all of the shell scripts in order
for them to run.

You can verify the RDA installation using the following command:

  perl rda.pl -cv
or
  rda.sh -cv

RUNNING RDA
===========
Before you begin: Log on as the UNIX user that owns the Oracle installation.
On some operating systems, this user will not have the necessary permissions
to run all of the commands and utilities called by RDA (for example, sar, top,
vmstat). When you are running RDA to assist in resolving a Service Request, the
analyst will most likely need the information pertaining to the Oracle owner.
In this case, Oracle support recommends that you run RDA as the UNIX user who
owns the Oracle software. An exception to this rule is when RDA is used to
assist in a performance related issue.

Note: If you use su to connect to root or a privileged user, do not use "su -"
as the minus resets the environment.

1) Choose the RDA command that you will be using depending on your environment:
   -- rda.pl  Use the following command to verify Perl is installed and
              available in the path:

              perl -V

              Inspect the command output, checking that '.' (i.e. the current
              directory) is present in @INC section.

   -- rda.sh  Use this command if Perl is not available.

   NOTE: The RDA command you selected above is represented as <rda> in the
   rest of this procedure. Therefore substitute ./rda.sh, ./rda.pl, or
   perl rda.pl in place of <rda>. Including the dot ensures that RDA is
   executed from the local directory.

2) Make sure the RDA command is executable. To verify, enter the following
   command:

   chmod +x rda.sh rda.pl

3) The data collection requires an initial setup to determine which information
   should be collected. Enter the following command to initiate the set up:

   <rda> -S

   After setup completes, review the setup file setup.cfg.

   You can also choose to collect only specific data. For more details, view
   the command usage help by specifying the -h option, or complete manual page
   with the -M option.

4) At this point, you can collect diagnostic information. Ensure that sqlplus
   is able to connect to the database with the userid that you specified during
   the setup. Start the data collection using the following command:

   <rda> [-v]

   The -v option is optional. It allows you to view the collection progression.

5) The output is a set of HTML files that are located in the RDA output
   directory which you specified at setup. You can review the data collected,
   starting with:

   <output_directory>/<report_group>__start.htm

   Please note: Do not submit any health, payment card or other sensitive
   production data that requires protections greater than those specified in
   the Oracle GCS Security Practices (http://www.oracle.com/us/support/library/
   customer-support-security-practices-069170.pdf). Information on how to
   remove data from your submission is available at
   https://support.oracle.com/rs?type=doc&id=1227943.1


6) The output is also packaged in an archive. If the data collection was
   generated to assist in resolving a Service Request, send the report archive
   to Oracle Support by uploading the file via My Oracle Support. If ftp'ing
   the file, please be sure to ftp in BINARY format. Do not rename the file, as
   the file name helps Oracle Support quickly identify that RDA output is
   attached to the service request.

It is impossible to tell how long RDA will take to execute, as it depends on
many variables, such as system activity, the options chosen, network settings,
etc. On an average system, RDA takes just a few minutes to run. Most scripts
are designed to stop if for some reason they cannot complete within 30 seconds,
(for example, the a lsnrctl status command will stop if the listener is hung.)
It is not unusual for RDA to take 15 minutes or more on a very busy server,
especially if there are many Oracle listener processes active.

If you must run data collection for specific modules again, for example the
OS and DBA modules, then you can run the following command:

  <rda> -vCRP OS DBA

RDA maintains the list of modules that are already collected. If you want RDA
to collect all data again using the same setup, then you can execute the
following command:

  <rda> -vCRPf or <rda> -vf

You can force RDA to define another collection using system defaults instead of
the previous collection settings in two ways:

  Deleting or renaming the "setup.cfg" file before running:
    <rda> -S
or
  Running the following RDA command:
    <rda> -Sfn

Currently this utility is written in the English language only, including the
built in documentation.

PLATFORMS SUPPORTED
===================
At this time, the scripts are supported on the following UNIX platforms:

-- Apple Mac OS X/Darwin
-- IBM AIX
-- IBM Dynix/Ptx
-- IBM Linux on POWER
-- IBM zSeries Based Linux
-- Intel Linux (Enterprise Linux, RedHat, and SuSE)
-- HP-UX Itanium
-- HP-UX PA-Risc (10.* and 11.*)
-- HP Tru64 Unix
-- Oracle Solaris SPARC (2.5 - 2.10)
-- Oracle Solaris x86

The scripts can also be run on other platforms, however, Oracle Support
recommends testing them on a non-production server first, as their performance
is unpredictable. For example, you will receive errors when RDA attempts to run
utilities and commands that are not supported on those platforms.

PRODUCTS SUPPORTED
==================
RDA collects information that is useful for troubleshooting issues in the
following areas:

-- Installation/configuration issues
-- Performance issues
-- ORA-600, ORA-7445, ORA-3113, and ORA-4031 errors
-- Upgrade, migration, and linking issues
-- Developer issues
-- Oracle Database issues
-- Oracle Application Server/Fusion Middleware issues
-- Oracle Enterprise Manager issues
-- Oracle Collaboration products (Oracle Collaboration Suite and Oracle
   Beehive) issues
-- Oracle Application issues
-- Acquired company product issues
-- Other corrective issues

SPECIAL NOTES ON USERIDS AND PASSWORDS
======================================
As a means of providing higher security when using RDA, passwords are no longer
stored in plain text in the setup.txt file. As result, RDA prompts for the
required passwords when collecting the data.

If the Perl implementation installed on your operating system supports it, RDA
will suppress the character echo during password requests. When the character
echo is suppressed, the password is requested twice for verification. If both
entered passwords do not match after three attempts, the request is cancelled.

RDA can perform OS authentication, which eliminates having to enter a password
for database information gathering. It also accepts "/" as a username to
avoid entering a password when RDA is gathering database information.

For executing RDA at regularly scheduled intervals via cron, passwords can be
encoded inside the setup file. For instance, to encode the system password,
use the following command:

  <rda> -A system

The password will be requested interactively.

SPECIAL NOTES ON OUTPUT DIRECTORY
=================================
To limit security vulnerabilities, the permissions of the RDA output directory
should be set as restrictive as possible. The output directory could contain
sensitive configuration information and, when no other mechanism is available,
temporary data collection files.

TROUBLESHOOTING STEPS
=====================
If you receive a "Command not found" error, ensure that the .sh or .pl files
have execute privileges.

If RDA is unable to connect to the database, and the user is declared as a
SYSDBA user when running the setup, ensure that connections are possible with
that user using AS SYSDBA. For example, if SYSTEM is specified as the username,
make sure that you can connect using the following command in sqlplus:

  connect system AS SYSDBA

If you cannot connect, run the setup again and answer N to that question, or
edit the setup file and set SYSDBA_USER=0. You can also use the 'TSTdb' test
module to obtain more elements on the connection problem.

If you use TWO_TASK to connect to the database, unset TWO_TASK and run RDA on
the server local to the database. This is necessary because RDA depends on a
local connection to the database, and automatically unsets TWO_TASK before
performing any function.

If you run RDA for an issue that involves multiple tiers (for example,
Application Server, Database Server, OLAP/Express Drive, OID, etc.) and the
tiers are on separate servers, then you must run RDA on each server associated
with the issue that you are troubleshooting. Data for these tiers will not be
collected unless RDA is run on the server that the product resides on.

If you are running RDA for an issue that involves products under different
ORACLE_HOME directories but the same server, you must run RDA multiple times,
once for each ORACLE_HOME that is involved in the issue that you are
troubleshooting. It is possible to have multiple setup files (cf. option -s).

RDA has RDA_TIMEOUT and SQL_TIMEOUT settings, which allows to limit the
execution time of operating system commands and SQL scripts respectively. This
is done to avoid situations in which RDA could hang because the execution of a
query would never complete. However, this feature depends on the operating
system capability to interrupt any tasks and should not always be operational.
If RDA was not able to execute a specific script, it might be a timeout issue.
You can try to increase these parameters in the setup file.

There could be situations in which some queries would take longer than 30
seconds to complete execution. In these cases, do the following to increase
the
RDA_TIMEOUT or SQL_TIMEOUT parameter:

1) Change directory to the directory where RDA is installed (or the directory
   containing the setup file if an alternate setup is specified with an '-s'
   option).

2) Use an editor such as 'vi' to edit the setup file (setup.cfg by default).

3) Change the value of RDA_TIMEOUT or SQL_TIMEOUT to a value greater than 30.

4) Re-run RDA (possibly limited to impacted modules).

5) It may be necessary to increase this value several times in order for the
   query to complete in the allotted time.

The setting can also be changed at execution time by using an '-e' option.

Under certain circumstances, RDA generates an error in a RDA-nnnnn format. You
can discover the meaning and possible solution to the error by using the '-E'
option. For example,
    <rda> -E RDA-00014

HOW TO REPORT PROBLEMS
======================
If problems running RDA cannot be fixed with the troubleshooting steps
described above, you can file a Service Request in My Oracle Support by
selecting "OSS Support Tools" from the product list of values on the
"Create a SR" screen. Click on "Expand the Product List" button to see the full
set of products. Select the "Remote Diagnostic Agent (RDA) Issue" type and
complete the Service Request. Please include:

-- The description of the error, including the error number and messages.

-- The output of:
     <rda> -c
     <rda> -V
     uname -a
     id
     ulimit -a
     env | sort
     alias | sort

When possible, re-run the RDA program with debug and trace mode enabled and
upload the output in the Service Request. For instance:

     <rda> -vdt            (for whole data collection)
     <rda> -vd T:<module>  (for a single module)

For database connection problems, include the output of
     <rda> -T T:TSTdb

COPYRIGHT NOTICE
================
Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

TRADEMARK NOTICE
================
Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

LEGAL NOTICES AND TERMS OF USE
==============================
https://support.oracle.com/rs?type=doc&id=225559.1

DOCUMENTATION ACCESSIBILITY
===========================
Our goal is to make Oracle products, services, and supporting documentation
accessible, with good usability, to the disabled community. To that end, our
documentation includes features that make information available to users of
assistive technology. This documentation is available in HTML format, and
contains markup to facilitate access by the disabled community. Standards will
continue to evolve over time, and Oracle is actively engaged with other market-
leading technology vendors to address technical obstacles so that our
documentation can be accessible to all of our customers. For additional
information, visit the Oracle Accessibility Program Web site at

http://www.oracle.com/accessibility/

Accessibility of Code Examples in Documentation JAWS, a Windows screen reader,
may not always correctly read the code examples in this document. The
conventions for writing code require that closing braces should appear on an
otherwise empty line; however, JAWS may not always read a line of text that
consists solely of a bracket or brace.

Accessibility of Links to External Web Sites in Documentation. This
documentation may contain links to Web sites of other companies or
organizations that Oracle does not own or control. Oracle neither evaluates
nor makes any representations regarding the accessibility of these Web sites.
