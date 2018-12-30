Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/creComponentTabs_oes.sql /entsec_11.1.1.4.0_dwg/1 2011/01/07 14:04:34 skalyana Exp $
Rem
Rem creComponentTabs_oes.sql
Rem
Rem Copyright (c) 2010, Oracle and/or its affiliates. All rights reserved. 
Rem
Rem    NAME
Rem      creComponentTabs_oes.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    skalyana    12/10/10 - Created
Rem

-- &&1 - Audit Admin Role
-- &&2 - Audit Append Role
-- &&3 - Audit Viewer Role

-- Call all of the supplied sql files that contains
-- code to create all the event specific tables and
-- indexes

@@JPS.sql &&1 &&2 &&3
