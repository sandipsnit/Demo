Rem
Rem
Rem Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 
Rem
Rem    NAME
Rem      mds_user.sql - Create user for EBR-enabled MDS Repository
Rem
Rem    DESCRIPTION
Rem      The file is used to create EBR-enabled schema user for MDS
Rem      Repository.  To be used only by RCU.
Rem
Rem    NOTES
Rem      The first 4 parameters are passed to the general mds_user.sql for 
Rem      creating the user on Oracle database. The fifth parameter is the 
Rem      edition name which must already exist in the database.
Rem      Enables the edition after creating the schema user. 
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jhsi        10/20/11 - #(13240968) Grant create view privilege to user
Rem    jhsi        04/19/11 - Created using mds_user.sql
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

@@../sql/mds_user.sql &&1 &&2 &&3 &&4

ALTER USER &&1 ENABLE EDITIONS;
GRANT USE ON EDITION &&5 TO &&1;
GRANT CREATE VIEW TO &&1;

EXIT;
