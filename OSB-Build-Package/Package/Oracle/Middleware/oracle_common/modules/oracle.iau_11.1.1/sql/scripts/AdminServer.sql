Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/AdminServer.sql /st_entsec_11.1.1.7.0/1 2012/10/16 18:41:13 rkoul Exp $
Rem
Rem AdminServer.sql
Rem
Rem Copyright (c) 2007, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      AdminServer.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       10/16/12 - grant select to append user
Rem    sregmi      12/24/07 - 
Rem    gsandeep    12/16/07 - Created
Rem

-- SQL Script for AdminServer
-- &&1 - Audit Admin Role
-- &&2 - Audit Append Role
-- &&3 - Audit Viewer Role
CREATE TABLE AdminServer (
	IAU_ID NUMBER,
	IAU_TstzOriginating TIMESTAMP, 
	IAU_EventType VARCHAR(255), 
	IAU_EventCategory VARCHAR(255), 
	IAU_DeploymentOperation VARCHAR(255),
	IAU_DeploymentStatus VARCHAR(255),
	IAU_DeploymentApplicationId VARCHAR(255),
	IAU_DeploymentTarget VARCHAR(255)
);

-- INDEX
CREATE INDEX AdminServer_Index
ON AdminServer(IAU_TSTZORIGINATING);

GRANT ALL on AdminServer to &&1;
GRANT INSERT on AdminServer to &&2;
GRANT SELECT on AdminServer to &&2;
GRANT SELECT on AdminServer to &&3;

-- SYNONYMS
CREATE or replace SYNONYM &&3..AdminServer FOR &&1..AdminServer;
CREATE or replace SYNONYM &&2..AdminServer FOR &&1..AdminServer;
