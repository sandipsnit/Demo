Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/OIF.sql /st_entsec_11.1.1.7.0/1 2012/10/16 18:41:13 rkoul Exp $
Rem
Rem OIF.sql
Rem
Rem Copyright (c) 2008, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      OIF.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       10/16/12 - grant select to append user
Rem    sregmi      10/29/08 - Created
Rem

-- SQL Script for OIF
-- &&1 - Audit Admin Role
-- &&2 - Audit Append Role
-- &&3 - Audit Viewer Role

CREATE TABLE OIF (
	IAU_ID NUMBER , 
	IAU_TstzOriginating TIMESTAMP , 
	IAU_EventType VARCHAR(255) , 
	IAU_EventCategory VARCHAR(255) , 
	IAU_RemoteProviderID VARCHAR(255) , 
	IAU_ProtocolVersion VARCHAR(255) , 
	IAU_NameIDQualifier VARCHAR(255) , 
	IAU_NameIDValue VARCHAR(255) , 
	IAU_NameIDFormat VARCHAR(255) , 
	IAU_SessionID VARCHAR(255) , 
	IAU_FederationID VARCHAR(255) , 
	IAU_UserID VARCHAR(255) , 
	IAU_FederationType VARCHAR(255) , 
	IAU_AuthenticationMechanism VARCHAR(255) , 
	IAU_AuthenticationEngineID VARCHAR(255) , 
	IAU_OldNameIDQualifier VARCHAR(255) , 
	IAU_OldNameIDValue VARCHAR(255) , 
	IAU_Binding VARCHAR(255) , 
	IAU_Role VARCHAR(255) , 
	IAU_MessageType VARCHAR(255) , 
	IAU_AssertionVersion VARCHAR(255) , 
	IAU_IssueInstant VARCHAR(255) , 
	IAU_Issuer VARCHAR(255) , 
	IAU_AssertionID VARCHAR(255) , 
	IAU_IncomingMessageString VARCHAR(3999) , 
	IAU_IncomingMessageStringCLOB CLOB , 
	IAU_OutgoingMessageString VARCHAR(3999) , 
	IAU_OutgoingMessageStringCLOB CLOB , 
	IAU_Type VARCHAR(255) , 
	IAU_PropertyName VARCHAR(255) , 
	IAU_PropertyType VARCHAR(255) , 
	IAU_PeerProviderID VARCHAR(255) , 
	IAU_PropertyContext VARCHAR(255) , 
	IAU_Description VARCHAR(255) , 
	IAU_OldValue VARCHAR(255) , 
	IAU_NewValue VARCHAR(255) , 
	IAU_ProviderType VARCHAR(255) , 
	IAU_COTBefore CLOB , 
	IAU_COTAfter CLOB , 
	IAU_ServerConfigBefore CLOB , 
	IAU_ServerConfigAfter CLOB , 
	IAU_DataStoreBefore CLOB , 
	IAU_DataStoreAfter CLOB , 
	IAU_Metadata VARCHAR(255) , 
	IAU_NewDataStoreType VARCHAR(255) , 
	IAU_DataStoreName VARCHAR(255) 
);

-- INDEX 
CREATE INDEX OIF_Index
ON OIF(IAU_TSTZORIGINATING);

-- PERMISSIONS 
GRANT ALL on OIF to &&1;
GRANT INSERT on OIF to &&2;
GRANT SELECT on OIF to &&2;
GRANT SELECT on OIF to &&3;

-- SYNONYMS 
CREATE OR REPLACE SYNONYM &&3..OIF FOR &&1..OIF;
CREATE OR REPLACE SYNONYM &&2..OIF FOR &&1..OIF;
