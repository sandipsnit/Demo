Rem
Rem
Rem cremds.sql
Rem
Rem Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      cremds.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem    This file creates the database schema for the repository.
Rem
Rem    NOTES
Rem    The database user must have grant to create sequence in order to
Rem    successfully use the MDS Repository.
Rem    The user must have execute privilege on dbms_rls in order to
Rem    run cremdsvpd.sql to add VPD policies on the schema.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jhsi       02/27/12 - #(12751112) Added configurestats.sql for setting
Rem                          dbms_stats preferences
Rem    jhsi       05/27/11 - VPD - multitenancy support
Rem    jhsi       07/27/09 - Using plb files
Rem    rupandey   01/27/09 - #(8202149) Added call to new mds_internal_utils scripts.
Rem    gnagaraj   10/22/07 - #(6508932) Remove unused pl/sql packages
Rem    abhatt     07/12/07 - #(6135856) Update comments, remove dbms_lock notes
Rem    rupandey   05/10/07 - Disabled scripts to create XDB tables and 
Rem                          procedures as part of MDS repository.  	
Rem    rupandey   12/15/06 - Removed call to execute procedure for registering 
Rem			     stylesheet.	  	
REM    rupandey   11/09/06 - Disabling populating the MDS_XDB_TRANSFORMS table. We
REM                          do not depend on the XSLT for transforming MDS
REM                          documents that are read. Also refer to bug# 5647734
REM    rupandey   08/22/06 - Added call to PL/SQL to load data in
REM			      MDS_XDB_TRANSFORMS table.
Rem    rnanda     08/14/06 - Created
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

Rem Creating the tables and views
@@cremdcmtbs
@@cremdsrtbs

Rem Creating the indexes
@@cremdsinds

Rem Creating the types
@@cremdstyps


Rem Creating the package specs
@@MDSINCS.pls
@@MDSINSRS.pls
@@MDSUTINS.pls

Rem Creating the package bodies
@@MDSINCB.plb
@@MDSINSRB.plb
@@MDSUTINB.plb

Rem Setting dbms_stats preferences 
@@configurestats

Rem If there were any compilations problems this will spit out the 
Rem the errors. uncomment to get errors.
Rem show errors

Rem Creating the VPD policy
@@cremdsvpd

EXIT;
