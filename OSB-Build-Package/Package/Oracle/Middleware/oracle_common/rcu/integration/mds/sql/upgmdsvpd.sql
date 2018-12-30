Rem
Rem
Rem upgmdsvpd.sql
Rem
Rem Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 
Rem
Rem    NAME
Rem      upgmdsvpd.sql - SQL script to upgrade MDS repository VPD policy.
Rem
Rem    DESCRIPTION
Rem    This file drops and adds VPD policies on MDS repository schema.
Rem
Rem    NOTES
Rem    The user must have execute privilege on dbms_rls in order to
Rem    run cremdsvpd.sql to add VPD policies on the schema.
Rem    The schema owner should be passed in as a paramter to this script.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jhsi        07/28/11 - Created
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

ALTER SESSION SET CURRENT_SCHEMA=&&1;

Rem create VPD policy for multitenancy support
@@cremdsvpd

EXIT;
