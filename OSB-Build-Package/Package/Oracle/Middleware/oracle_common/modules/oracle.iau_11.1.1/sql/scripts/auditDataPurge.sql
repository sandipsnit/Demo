Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/auditDataPurge.sql /st_entsec_11.1.1.7.0/2 2012/10/02 13:04:12 rkoul Exp $
Rem
Rem auditDataPurge.sql
Rem
Rem Copyright (c) 2010, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      auditDataPurge.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem     Usage: arg1=schema  arg2=number_of_days_prior_to_which_everything_should_be_purged
Rem           : e.g sql>@auditDataPurge.sql DEV_IAU 100
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       09/28/12 - bugfix 14471957
Rem    dozhou      07/10/12 - add table iau_custom
Rem    skalyana    05/25/10 - Created
Rem

-- delete rows
@@auditDeleteData.sql &&1 &&2

--shrink space
@@auditReclaimSpace.sql &&1

