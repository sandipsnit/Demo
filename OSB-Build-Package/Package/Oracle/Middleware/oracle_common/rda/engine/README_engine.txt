                 Oracle Remote Diagnostic Agent Compiled Engine


PURPOSE
=======
Even when Perl is not available, it is still possible to execute the Oracle
Remote Diagnostic Agent (RDA) for most common platforms, by using the
corresponding compiled engine.

Compiled engines are currently available for the following platforms:
-- IBM AIX
-- Intel Linux (Enterprise Linux, RedHat, and SuSE)
-- HP-UX
-- HP Tru64
-- MicroSoft Windows
-- Mac OS X
-- Oracle Solaris (SPARC)

INSTALLATION INSTRUCTIONS
=========================
To use a compiled engine, you have to install a full RDA distribution. Check
the installation instructions in the README file for your platform type for
further information.

The next step is to download the compiled engine for your platform. Knowledge
article 330363.1 shows where you can download a compiled engine for your 
platform.
https://support.oracle.com/rs?type=doc&id=330363.1

It is important that the compiled engine and the RDA distribution are of the
same version.

After the download of the compiled engine package, unzip it, and move the
compiled engine files to the engine directory present inside the RDA
installation directory.

The rda.cfg in the standard distribution of RDA, RDA, contains the following
entries:
RDA_ENG=""
RDA_EXE="rda.exe"
D_RDA=".."

Using the same compiled engine systematically for an RDA installation
---------------------------------------------------------------------
When you want to use a compiled engine through usual RDA commands (rda.cmd or
rda.sh), you must edit the rda.cfg file contained in the engine directory. Its
initial content is:
RDA_ENG=""
RDA_EXE="rda.exe"
D_RDA=".."

After making the file writable, specify the compiled engine name in the RDA_ENG
value. For Windows, you will have:
RDA_ENG="rda_win.exe"
RDA_EXE="rda.exe"
D_RDA=".."

For Windows, the first invocation of rda.cmd will take a copy of the compiled
engine in the RDA installation directory. On subsequent executions, the start
script is checking if a new version of the specified compiled engine is
available. When available, the start script will copy that new version to
rda.exe in the installation directory.

For UNIX, you must use rda.sh to obtain the same result.

Using a compiled engine in a shared or in a read-only installation
------------------------------------------------------------------
When the RDA installation is shared between different systems or different
users, the same compiled engine is not necessarily applicable to everybody or
the installation directory is not necessarily writable for everybody.

In this case, RDA uses the work directory to store the copy of the specified
compiled engine. Create in the working directory an rda.cfg file with the
following content:
RDA_ENG="<name of the compiled engine>"
RDA_EXE="rda.exe"
D_RDA="<full path of the RDA installation directory>"

For instance,
RDA_ENG="rda_win.exe"
RDA_EXE="rda.exe"
D_RDA="D:\MyOracleHome\rda"

After that, you can use the usual start scripts.
For UNIX,
  <RDA installation directory>/rda.sh

For Windows,
  <RDA installation directory>\rda.cmd

On the first invocation of the start script, it will take a copy of the
compiled engine in the RDA installation directory. On subsequent executions,
the start script will check if a new version of the specified compiled engine
is available. When available, the start script will copy that new version to
rda.exe in the installation directory.

The copy mechanism preserves the possibility to upgrade only the shared
installation when a new RDA version is available. Each user will get their
compiled engine copy automatically updated at next run.

COPYRIGHT NOTICE
================
Copyright 2002, 2012, Oracle. All rights reserved.

TRADEMARK NOTICE
================
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

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
