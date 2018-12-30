Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/auditUser.sql /entsec_11.1.1.4.0_dwg/1 2011/09/22 10:30:34 skalyana Exp $
Rem
Rem auditUser.sql
Rem
Rem Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      auditUser.sql 
Rem
Rem    DESCRIPTION
Rem      Creates Users needed for the IAU Schema
Rem
Rem    NOTES
Rem      
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    skalyana    09/21/11 - Fix bug # 12664543
Rem    sregmi      08/08/06 - Creation
Rem

-- &&1 - Audit Admin Role
-- &&2 - Audit Admin Password
-- &&3 - Default TableSpace
-- &&4 - Temporary Table Splace

-- &&5 - Audit Append Role
-- &&6 - Audit Append Password

-- &&7 - Audit Viewer Role
-- &&8 - Audit Viewer Password

CREATE USER &&1 
    IDENTIFIED BY &&2 
    DEFAULT TABLESPACE &&3 
    TEMPORARY TABLESPACE &&4;
GRANT RESOURCE TO &&1;
GRANT UNLIMITED TABLESPACE to &&1;
GRANT CONNECT TO &&1;


-- Create and Manage Roles: Two more Users.
-- Viewer and Append Roles
CREATE USER &&5
IDENTIFIED BY &&6
DEFAULT TABLESPACE &&3
TEMPORARY TABLESPACE &&4;
GRANT CONNECT to &&5;


CREATE USER &&7
IDENTIFIED BY &&8
DEFAULT TABLESPACE &&3
TEMPORARY TABLESPACE &&4;
GRANT CONNECT to &&7;



