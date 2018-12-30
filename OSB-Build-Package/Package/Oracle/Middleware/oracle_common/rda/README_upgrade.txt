                     Remote Diagnostic Agent (RDA) Upgrade
     
    
PURPOSE
=======
When Oracle Configuration Manager (OCM) and RDA are installed in the same
directory, OCM can upgrade the RDA installation.

When OCM is configured in connected mode, the OCM component upgrade can take
place not only during a scheduled run, but also when RDA is triggering OCM. In
the last case, RDA is already running when the upgrade is performed. Therefore,
RDA supports hot upgrades. To minimize the number of old files involved in its
execution, RDA will execute an OCM "getupdates" request at the very beginning
of its execution. It will take care to not execute "getupdates" requests 
repetitively. By default, it will wait at least 10 hours before making another
attempt.

When OCM is configured in disconnected mode, RDA upgrades OCM by using the OCM
distribution kits shipped inside the RDA distribution kits. In such a context,
it is less probable that RDA has an OCM kit containing a more recent RDA
version than the version already in use.

The RDA upgrade is automatically disabled when any of the following conditions
are fulfilled:

1) The rda directory is not writable for the OCM component upgrade process.

2) The rda/rda.cfg contains any directory group specification.

3) The rda/engine/rda.cfg specifies any other directory than its parent
   directory as RDA software home.

4) The RDA build is more recent than the build contained in the corresponding
   OCM component.

The upgrade process can replace any RDA software files or directories,
including the compiled engines. Other files or directories contained in the rda
directory are preserved.

CONTROLLING THE UPGRADE MECHANISM
=================================
You can control the upgrade mechanism by adding lines in the rda/rda.cfg file.

1) You can block any RDA upgrade with:

   NO_UPGRADE="<any value>"

2) You can disable the "getupdates" requests with:

   NO_GETUPDATES="<any value>"

   RDA automatically adds the above line when OCM is configured in disconnected
   mode.

3) You can specify the minimum time (in seconds) between two successive
   "getupdates" requests:

   NO_RETEST="<duration in seconds>"

OBSOLETE FILE CLEANUP
=====================
Starting from RDA 4.22, RDA has a mechanism to declare obsolete some files or
directories from previous releases. Those old objects are ignored. You can
eliminate them by using:

  <rda> -XUpgrade files

This command can be executed by the upgrade process also.

PLATFORMS SUPPORTED
===================
At this time, the RDA upgrade through OCM is supported on the following
platforms:

-- IBM AIX
-- IBM Linux on POWER
-- IBM zSeries Based Linux
-- Intel Linux (Enterprise Linux, RedHat and SuSE)
-- HP-UX Itanium
-- HP-UX PA-Risc
-- Microsoft Windows
-- Oracle Solaris SPARC
-- Oracle Solaris x86

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
organizations that Oracle does not own or control. Oracle neither evaluates nor
makes any representations regarding the accessibility of these Web sites.
