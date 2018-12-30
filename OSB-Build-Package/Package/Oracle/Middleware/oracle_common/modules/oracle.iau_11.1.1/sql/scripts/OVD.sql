Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/OVD.sql /st_entsec_11.1.1.7.0/1 2012/10/16 18:41:13 rkoul Exp $
Rem
Rem OVD.sql
Rem
Rem Copyright (c) 2007, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      OVD.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       10/16/12 - grant select to append user
Rem    gsandeep    04/09/08 - 
Rem    sregmi      07/12/07 - Created
Rem

-- SQL Script for OVDComponent
-- &&1 - Audit Admin Role
-- &&2 - Audit Append Role
-- &&3 - Audit Viewer Role

CREATE TABLE OVDComponent (
	IAU_ID NUMBER , 
	IAU_TstzOriginating TIMESTAMP , 
	IAU_EventType VARCHAR(255) , 
	IAU_EventCategory VARCHAR(255) , 
	IAU_ServiceOperation VARCHAR(255) 
);

CREATE OR REPLACE SYNONYM OVD FOR OVDComponent;

-- INDEX 
CREATE INDEX OVDComponent_Index
ON OVDComponent(IAU_TSTZORIGINATING);

-- PERMISSIONS 
GRANT ALL on OVDComponent to &&1;
GRANT INSERT on OVDComponent to &&2;
GRANT SELECT on OVDComponent to &&2;
GRANT SELECT on OVDComponent to &&3;

-- SYNONYMS
CREATE OR REPLACE SYNONYM &&3..OVDComponent FOR &&1..OVDComponent;
CREATE OR REPLACE SYNONYM &&2..OVDComponent FOR &&1..OVDComponent;
