Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/SOA-HCFP.sql /st_entsec_11.1.1.7.0/1 2012/10/16 18:41:13 rkoul Exp $
Rem
Rem SOA_HCFP.sql
Rem
Rem Copyright (c) 2011, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      SOA_HCFP.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       10/16/12 - grant select to append user
Rem    skalyana    06/21/11 - Created
Rem

CREATE TABLE SOA_HCFP (
        IAU_ID NUMBER ,
        IAU_TstzOriginating TIMESTAMP ,
        IAU_EventType VARCHAR(255) ,
        IAU_EventCategory VARCHAR(255) ,
        IAU_Reason VARCHAR(255)
);

-- INDEX 
CREATE INDEX SOA_HCFP_Index
ON SOA_HCFP(IAU_TSTZORIGINATING);

-- PERMISSIONS 
GRANT ALL on SOA_HCFP to &&1;
GRANT INSERT on SOA_HCFP to &&2;
GRANT SELECT on SOA_HCFP to &&2;
GRANT SELECT on SOA_HCFP to &&3;

-- SYNONYMS 
CREATE OR REPLACE SYNONYM &&3..SOA_HCFP FOR &&1..SOA_HCFP;
CREATE OR REPLACE SYNONYM &&2..SOA_HCFP FOR &&1..SOA_HCFP;
