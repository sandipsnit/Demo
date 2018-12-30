Oracle Service Bus 11gR1 PS6 (11.1.1.7.0)
____________________________________________________________
November 2012


After you install the Oracle Service Bus 11gR1 PS6 (11.1.1.7.0), use
these scripts to upgrade Oracle Service Bus 11gR1 pre 11.1.1.4.0 domains as described in the
Oracle Service Bus Upgrade Guide at
http://download.oracle.com/docs/cd/E17904_01/doc.1111/e15032/toc.htm


The steps are also documented below for your convenience:


Perform the following steps for each domain to be upgraded:

1. Make sure you have backed up and shut down all domains to be upgraded.

2. Under each Oracle Service Bus 11gR1 domain to be upgraded,
   open a command window and run the DOMAIN/bin/setDomainEnv.cmd/sh command.

3. In the command window, switch to the directory in which the upgrade scripts
   resides:
   OSB_ORACLE_HOME/common/lib/upgrade

4. On the command line, run the appropriate script for your operating system:

   Linux/Solaris: java weblogic.WLST ./domainUpgrade.py

   Windows: java weblogic.WLST domainUpgrade.py
