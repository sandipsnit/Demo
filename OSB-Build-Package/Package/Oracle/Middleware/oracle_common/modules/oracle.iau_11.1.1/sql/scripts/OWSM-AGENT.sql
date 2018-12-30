Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/OWSM-AGENT.sql /st_entsec_11.1.1.7.0/1 2012/10/16 18:41:13 rkoul Exp $
Rem
Rem OWSM_AGENT.sql
Rem
Rem Copyright (c) 2007, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      OWSM_AGENT.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       10/16/12 - grant select to append user
Rem    sregmi      07/12/07 - Created
Rem

-- SQL Script for OWSM_AGENT
-- &&1 - Audit Admin Role
-- &&2 - Audit Append Role
-- &&3 - Audit Viewer Role

CREATE TABLE OWSM_AGENT (
	IAU_ID NUMBER , 
	IAU_TstzOriginating TIMESTAMP , 
	IAU_EventType VARCHAR(255) , 
	IAU_EventCategory VARCHAR(255) , 
	IAU_AppName VARCHAR(255) , 
	IAU_AssertionName VARCHAR(255) , 
	IAU_CompositeName VARCHAR(255) , 
	IAU_Endpoint VARCHAR(4000) , 
	IAU_AgentMode VARCHAR(255) , 
	IAU_ModelObjectName VARCHAR(255) , 
	IAU_Operation VARCHAR(255) , 
	IAU_ProcessingStage VARCHAR(255) , 
	IAU_Version NUMBER , 
	IAU_Protocol VARCHAR(255) 
);

-- INDEX 
CREATE INDEX OWSM_AGENT_Index
ON OWSM_AGENT(IAU_TSTZORIGINATING);

-- PERMISSIONS 
GRANT ALL on OWSM_AGENT to &&1;
GRANT INSERT on OWSM_AGENT to &&2;
GRANT SELECT on OWSM_AGENT to &&2;
GRANT SELECT on OWSM_AGENT to &&3;

-- SYNONYMS
CREATE OR REPLACE SYNONYM &&3..OWSM_AGENT FOR &&1..OWSM_AGENT;
CREATE OR REPLACE SYNONYM &&2..OWSM_AGENT FOR &&1..OWSM_AGENT;
