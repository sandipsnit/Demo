Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/OAM.sql /st_entsec_11.1.1.7.0/1 2012/10/16 18:41:13 rkoul Exp $
Rem
Rem OAM.sql
Rem
Rem Copyright (c) 2009, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      OAM.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       10/16/12 - grant select to append user
Rem    skalyana    10/16/11 - More changes for OAM
Rem    skalyana    10/09/11 - Fix for bug # 13042179
Rem    skalyana    11/08/10 - Bug # 10268948
Rem    skalyana    10/10/10 - schema changes for OAM
Rem    shiahuan    09/09/09 - Created
Rem

-- SQL Script for OAM
-- &&1 - Audit Admin Role
-- &&2 - Audit Append Role
-- &&3 - Audit Viewer Role

CREATE TABLE OAM (
	IAU_ID NUMBER , 
	IAU_TstzOriginating TIMESTAMP , 
	IAU_EventType VARCHAR(255) , 
	IAU_EventCategory VARCHAR(255) , 
	IAU_ApplicationDomainName VARCHAR(255) , 
	IAU_AuthenticationSchemeID VARCHAR(255) , 
	IAU_AgentID VARCHAR(255) , 
	IAU_SSOSessionID VARCHAR(255) , 
	IAU_AdditionalInfo CLOB, 
	IAU_AuthorizationScheme VARCHAR(255) , 
	IAU_UserDN VARCHAR(255) , 
	IAU_ResourceID VARCHAR(255) , 
	IAU_AuthorizationPolicyID VARCHAR(255) , 
	IAU_AuthenticationPolicyID VARCHAR(255) , 
	IAU_UserID VARCHAR(255) , 
	IAU_ResourceHost VARCHAR(255) , 
	IAU_RequestID VARCHAR(255) , 
	IAU_PolicyName VARCHAR(255) , 
	IAU_SchemeName VARCHAR(255) , 
	IAU_ResourceHostName VARCHAR(255) , 
	IAU_OldAttributes VARCHAR(4000) , 
	IAU_NewAttributes VARCHAR(4000) , 
        IAU_SchmeType VARCHAR(40) ,
	IAU_ResponseType VARCHAR(255) , 
	IAU_AgentType VARCHAR(255) , 
	IAU_ConstraintType VARCHAR(255) , 
	IAU_InstanceName VARCHAR(255) , 
	IAU_DataSourceName VARCHAR(255) , 
	IAU_DataSourceType VARCHAR(255) , 
	IAU_HostIdentifierName VARCHAR(255) , 
	IAU_ResourceURI VARCHAR(1024) , 
        IAU_ResourceTemplateName VARCHAR(255),
	IAU_Impersonator VARCHAR(255),
	IAU_OldSettings CLOB,
	IAU_NewSettings CLOB,
	IAU_ResourceType VARCHAR(255),
	IAU_PolicyObjectID VARCHAR(255),
	IAU_ReadOnly VARCHAR(255),
	IAU_PolicyAdminContext CLOB,
	IAU_PolicyType VARCHAR(255),
	IAU_ProtectionLevel VARCHAR(255),
	IAU_ServiceURI VARCHAR(1024),
	IAU_ServiceIdentifier VARCHAR(255),
	IAU_ServiceOperation VARCHAR(255),
	IAU_AdminRoleName VARCHAR(255),
	IAU_ClientIPAddress VARCHAR(255),
	IAU_SessionCreationTime VARCHAR(255),
	IAU_SessionExpirationTime VARCHAR(255),
	IAU_SessionLastUpdateTime VARCHAR(255),
	IAU_SessionLastAccessTime VARCHAR(255),
	IAU_IdentityDomain VARCHAR(255),
	IAU_GenericAttribute1 VARCHAR(255),
	IAU_GenericAttribute2 VARCHAR(255),
	IAU_GenericAttribute3 VARCHAR(255),
	IAU_GenericAttribute4 VARCHAR(255),
	IAU_GenericAttribute5 VARCHAR(255),
	IAU_ResourceOperations VARCHAR(255)
);

-- INDEX 
CREATE INDEX OAM_Index
ON OAM(IAU_TSTZORIGINATING);

-- PERMISSIONS 
GRANT ALL on OAM to &&1;
GRANT INSERT on OAM to &&2;
GRANT SELECT on OAM to &&2;
GRANT SELECT on OAM to &&3;

-- SYNONYMS 
CREATE OR REPLACE SYNONYM &&3..OAM FOR &&1..OAM;
CREATE OR REPLACE SYNONYM &&2..OAM FOR &&1..OAM;
