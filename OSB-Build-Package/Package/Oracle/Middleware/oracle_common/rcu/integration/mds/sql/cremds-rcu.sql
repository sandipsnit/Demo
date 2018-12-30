Rem
Rem $Header: cremds-rcu.sql 22-oct-2007.15:57:27 gnagaraj Exp $
Rem
Rem cremds-rcu.sql
Rem
Rem Copyright (c) 2006, Oracle. All rights reserved.  
Rem
Rem    NAME
Rem      cremds-rcu.sql - RCU SQL script to create MDS repository schema. 
Rem
Rem    DESCRIPTION
Rem    This file creates the database schema for MDS repository. To
Rem    be used only by RCU.
Rem
Rem    NOTES
Rem    The user should have grant to create sequence in order to
Rem    successfully use the MDS Repository.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rupandey   09/26/06 - Renamed script. Identical to cremds.sql, 
Rem                          except here we alter the session else RCU
Rem			     ends up creating MDS Repos in dba namespace.
Rem			     Invokes cremds.sql.	
Rem    rupandey   08/22/06 - Added call to PL/SQL to load data in 
Rem			     MDS_XDB_TRANSFORMS table.
Rem    rnanda     08/14/06 - Created
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

ALTER SESSION SET CURRENT_SCHEMA=&&1;

Rem Create MDS Repository
@@cremds.sql

EXIT;
