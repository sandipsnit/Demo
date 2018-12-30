Rem
Rem $Header: jazn/jps/schema/oracle/opss_upgrade_11116_11117.sql /st_entsec_11.1.1.7.0/1 2012/10/24 22:33:57 jianz Exp $
Rem
Rem opss_upgrade_11116_11117.sql
Rem
Rem Copyright (c) 2011, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      opss_upgrade_11116_11117.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jianz       09/02/12 - Created,PS6 upgrade from PS5
Rem

ALTER SESSION SET CURRENT_SCHEMA=&&1;

--opss_attrs upgrade

UPDATE JPS_ATTRS SET ATTRVAL='11.1.1.7.0' WHERE ATTRNAME='orclProductVersion' AND (ATTRVAL='11.1.1.6.0');

COMMIT;
