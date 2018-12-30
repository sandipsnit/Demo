Rem
Rem $Header: jtmds/src/dbschema/oracleebr/cremds-rcu.sql /st_jdevadf_patchset_ias/3 2012/02/28 10:55:17 jhsi Exp $
Rem
Rem cremds-rcu.sql
Rem
Rem Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      cremds-rcu.sql - RCU SQL script to create EBR-enabled schema for
Rem                       MDS repository. 
Rem
Rem    DESCRIPTION
Rem    This file creates the EBR-enabled database schema for MDS repository.
Rem    To be used only by RCU.
Rem
Rem    NOTES
Rem    The first parameter is the schema user, the second parameter is 
Rem    the edition name.
Rem    The user should have grant to create sequence in order to
Rem    successfully use the MDS Repository.
Rem    The user must have execute privilege on dbms_rls in order to
Rem    run cremdsvpd.sql to add VPD policies on the schema.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jhsi        02/27/12 - #(12751112) Added configurestats.sql for setting
Rem                           dbms_stats preferences
Rem    jhsi        05/27/11 - VPD - multitenancy support
Rem    jhsi        04/19/11 - Created using cremds_ebr.sql
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

ALTER SESSION SET CURRENT_SCHEMA=&&1;
ALTER SESSION SET EDITION=&&2;

Rem Create MDS Repository

Rem Creating the tables and views for EBR-enabled schema
Rem NOTE: Minimum Database version required - Oracle 11.2
@@cremdcmtbs
@@cremdsrtbs

Rem Creating the indexes
@@cremdsinds

Rem Creating the types
@@../sql/cremdstyps.sql

Rem Creating the package specs
@@../sql/MDSINCS.pls
@@../sql/MDSINSRS.pls
@@../sql/MDSUTINS.pls

Rem Creating the package bodies
@@../sql/MDSINCB.plb
@@../sql/MDSINSRB.plb
@@../sql/MDSUTINB.plb

Rem Setting dbms_stats preferences 
@@configurestats

Rem If there were any compilations problems this will spit out the 
Rem the errors. uncomment to get errors.
Rem show errors

Rem Creating the VPD policy
@@../sql/cremdsvpd.sql

EXIT;
