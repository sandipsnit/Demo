Rem
Rem $Header: jazn/jps/schema/oracle/opss_drop_privileg.sql /st_entsec_11.1.1.7.0/1 2012/10/24 22:33:57 jianz Exp $
Rem
Rem opss_drop_privileg.sql
Rem
Rem Copyright (c) 2012, Oracle and/or its affiliates. All rights reserved. 
Rem
Rem    NAME
Rem      opss_drop_privileg.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jianz       09/03/12 - Created
Rem

REVOKE CREATE ANY INDEX FROM &&1 ;
REVOKE RESOURCE FROM &&1 ;
REVOKE CONNECT FROM &&1 ;
REVOKE UNLIMITED TABLESPACE FROM &&1 ;
ALTER USER &&1 QUOTA UNLIMITED ON &&2 ;
 
GRANT CREATE CLUSTER TO &&1 ;
GRANT CREATE INDEXTYPE TO &&1 ;
GRANT CREATE OPERATOR TO &&1 ;
GRANT CREATE PROCEDURE TO &&1 ;
GRANT CREATE SEQUENCE TO &&1 ;
GRANT CREATE SESSION TO &&1 ;
GRANT CREATE TABLE TO &&1 ;
GRANT CREATE TRIGGER TO &&1 ;
GRANT CREATE TYPE TO &&1 ;
GRANT CREATE VIEW TO &&1 ;
COMMIT;
