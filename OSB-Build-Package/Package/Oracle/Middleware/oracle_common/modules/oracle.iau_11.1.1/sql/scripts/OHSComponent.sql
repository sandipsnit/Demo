Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/OHSComponent.sql /st_entsec_11.1.1.7.0/1 2012/10/16 18:41:13 rkoul Exp $
Rem
Rem OHS.sql
Rem
Rem Copyright (c) 2007, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      OHS.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       10/16/12 - grant select to append user
Rem    sregmi      07/29/07 - Created
Rem

-- SQL Script for OHSComponent
-- &&1 - Audit Admin Role
-- &&2 - Audit Append Role
-- &&3 - Audit Viewer Role

CREATE TABLE OHSComponent (
	IAU_ID NUMBER , 
	IAU_TstzOriginating TIMESTAMP , 
	IAU_EventType VARCHAR(255) , 
	IAU_EventCategory VARCHAR(255) , 
	IAU_Reason CLOB , 
	IAU_SSLConnection VARCHAR(255) , 
	IAU_AuthorizationType VARCHAR(255) 
);

CREATE OR REPLACE SYNONYM OHS FOR OHSComponent;

-- INDEX 
CREATE INDEX OHSComponent_Index
ON OHSComponent(IAU_TSTZORIGINATING);

-- PERMISSIONS 
GRANT ALL on OHSComponent to &&1;
GRANT INSERT on OHSComponent to &&2;
GRANT SELECT on OHSComponent to &&2;
GRANT SELECT on OHSComponent to &&3;

-- SYNONYMS
CREATE OR REPLACE SYNONYM &&3..OHSComponent FOR &&1..OHSComponent;
CREATE OR REPLACE SYNONYM &&2..OHSComponent FOR &&1..OHSComponent;
