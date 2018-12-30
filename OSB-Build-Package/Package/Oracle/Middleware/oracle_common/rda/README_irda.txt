     Remote Diagnostic Agent Interface for Incident Packaging System (IRDA)

PURPOSE
=======
Starting with Oracle Database 11.2.0.2, the Incident Package System (IPS) can
trigger a Remote Diagnostic Agent (RDA) collection when finalizing an incident
package. IPS expects to find an irda.pl interface script in the rda
subdirectory of the Oracle home. That does not prevent you from putting the RDA
software somewhere else, for example, on a shared drive. In that case, the
subdirectory contains the interface script and its configuration file(s) only.

RDA derives the collection requirements from the incident using rules. It
suppresses all interactive dialogs during the setup and the data collection.

INSTALLATION INSTRUCTIONS
=========================
The IRDA interface is contained in all RDA distributions starting from RDA 4.22
and does not require any configuration when RDA is installed in the rda
subdirectory of the Oracle home. Otherwise, you can use the irda.pl script to
install a bootstrap in relevant Oracle homes.

For more information on IRDA, see its man pages:
  <rda> -M irda

Currently this utility is written in the English language only, including the
built in documentation.

PLATFORMS SUPPORTED
===================
At this time, the interface is supported on all platforms supported by RDA and
products using the Automated Diagnostic Repository (ADR) releases used in
Oracle Database 11.2.0.2 or later.

PRODUCT SUPPORTED
=================
Rules currently support the Oracle Database and the Oracle Fusion Middleware
products.

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
