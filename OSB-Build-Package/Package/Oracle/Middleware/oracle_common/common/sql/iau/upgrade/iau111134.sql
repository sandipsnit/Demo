Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/iau111134.sql /st_entsec_11.1.1.7.0/2 2012/12/25 11:15:30 rkoul Exp $
Rem
Rem iau11113.sql
Rem
Rem Copyright (c) 2010, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      iau11113.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       12/20/12 - add user tenantid to iau_base for ps6 upgrade
Rem    miqi        08/16/12 - fix bug 14504888
Rem    skalyana    10/16/11 - More changes for OAM
Rem    skalyana    01/25/11 - XbranchMerge skalyana_bug-10378722 from main
Rem    skalyana    12/04/10 - Fix bug and include changes for OAAM
Rem    skalyana    02/24/11 - Fix for bug # 11780316
Rem    skalyana    11/08/10 - bug # 10268948
Rem    skalyana    05/10/10 - Created
Rem

ALTER SESSION SET CURRENT_SCHEMA=&&1;

ALTER TABLE OAAM
MODIFY IAU_CaseActionEnum VARCHAR(4000);
ALTER TABLE OAAM
MODIFY IAU_CaseChallengeResult NUMBER;
ALTER TABLE OAAM
MODIFY IAU_CaseDisposition VARCHAR(4000);
ALTER TABLE OAAM
MODIFY IAU_CaseSeverity VARCHAR(4000);
ALTER TABLE OAAM
MODIFY IAU_CaseStatus VARCHAR(4000);
ALTER TABLE OAAM
RENAME COLUMN IAU_PolicyName TO IAU_PolicyName_OLD;
ALTER TABLE OAAM
ADD IAU_PolicyName VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_CaseType INTEGER;
ALTER TABLE OAAM
ADD IAU_SessionIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_JobId NUMBER;
ALTER TABLE OAAM
ADD IAU_JobInstanceIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_JobIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_JobName VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_JobType INTEGER;
ALTER TABLE OAAM
ADD IAU_ScheduleType INTEGER;
ALTER TABLE OAAM
ADD IAU_Result NUMBER;
ALTER TABLE OAAM
ADD IAU_CustomJobType VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_CustomJobTypeId NUMBER;
ALTER TABLE OAAM
ADD IAU_PatternDetails VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_PatternIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_PatternStatus VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_PatternId NUMBER;
ALTER TABLE OAAM
ADD IAU_PatternParam VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_PatternParamIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_TransactionDef VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_TransactionDefIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_TransactionDefStatus INTEGER;
ALTER TABLE OAAM
ADD IAU_TransactionEntityDefMap VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_TransactionEntityDefMapIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_TransactionDefId NUMBER;
ALTER TABLE OAAM
ADD IAU_DataElementDefArray VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_DataElementDefIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_TransactionDataMapping VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_TransactionDataMappingIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_TransactionEntityMapId NUMBER;
ALTER TABLE OAAM
ADD IAU_SnapshotData VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_SnapshotDiffTree VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_IsDeleteSnapshotItems NUMBER;
ALTER TABLE OAAM
ADD IAU_SnapshotIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_ImpExpPropertiesArgs VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_DynamicAction VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_DynamicActionIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_DynamicActionInstance VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_DynamicActionInstanceIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_DynamicActionInstStatus INTEGER;
ALTER TABLE OAAM
ADD IAU_PolicySet VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_PolicySetId NUMBER;
ALTER TABLE OAAM
ADD IAU_ScoreActions VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_ActionOverrides VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_ScoreActionIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_ActionOverrideBlockIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_PropertyName VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_PropertyValue VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_PropertyNames VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_EntityDef VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_EntityDefIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_EntityDefStatus INTEGER;
ALTER TABLE OAAM
ADD IAU_EntityDefId NUMBER;
ALTER TABLE OAAM
ADD IAU_IdSchemeElemDefIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_KeyGenScheme INTEGER;
ALTER TABLE OAAM
ADD IAU_DisplayElemDefIds VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_EntityDefsMap VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_RecentLoginsSearchQuery VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_RequestId VARCHAR(4000);
ALTER TABLE OAAM
ADD IAU_TrxLogId NUMBER;
ALTER TABLE OAAM
ADD IAU_RuntimeType INTEGER;
ALTER TABLE OAAM
ADD IAU_PolicySetLogId NUMBER;
ALTER TABLE OAAM
ADD IAU_EntityDefsMapIds VARCHAR(4000);


ALTER TABLE JPS
ADD IAU_stripeName VARCHAR(1024);
ALTER TABLE JPS
ADD IAU_keystoreName VARCHAR(1024);
ALTER TABLE JPS
ADD IAU_alias VARCHAR(1024);
ALTER TABLE JPS
ADD IAU_operation VARCHAR(1024);

ALTER TABLE IAU_BASE
ADD IAU_ComponentData CLOB;
ALTER TABLE IAU_BASE
ADD IAU_AuditUser VARCHAR(255);
ALTER TABLE IAU_BASE
ADD IAU_TenantId VARCHAR(255);
ALTER TABLE IAU_BASE
ADD IAU_UserTenantId VARCHAR(255);

@@STS.sql  &&1 &&2 &&3

ALTER TABLE OAM
ADD IAU_Impersonator VARCHAR(255);
ALTER TABLE OAM
ADD IAU_OldSettings CLOB;
ALTER TABLE OAM
ADD IAU_NewSettings CLOB;
ALTER TABLE OAM
ADD IAU_ResourceType VARCHAR(255);
ALTER TABLE OAM
RENAME COLUMN IAU_AdditionalInfo TO IAU_AdditionalInfo_OLD;
ALTER TABLE OAM
ADD IAU_AdditionalInfo CLOB;

@@auditschema.pls &&1 &&2 &&3
@@auditreports.pls &&1 &&2 &&3

-- create base tables for dynamic metadata model
@@auditGenericTabs.sql &&1 &&2 &&3

@@SOA-B2B.sql &&1 &&2 &&3
@@SOA-HCFP.sql &&1 &&2 &&3
@@XMLPSERVER.sql &&1 &&2 &&3

ALTER TABLE OAM
ADD IAU_PolicyObjectID VARCHAR(255);
ALTER TABLE OAM
ADD IAU_ReadOnly VARCHAR(255);
ALTER TABLE OAM
ADD IAU_PolicyAdminContext CLOB;
ALTER TABLE OAM
ADD IAU_PolicyType VARCHAR(255);
ALTER TABLE OAM
ADD IAU_ProtectionLevel VARCHAR(255);
ALTER TABLE OAM
ADD IAU_ServiceURI VARCHAR(1024);
ALTER TABLE OAM
ADD IAU_ServiceIdentifier VARCHAR(255);
ALTER TABLE OAM
ADD IAU_ServiceOperation VARCHAR(255);
ALTER TABLE OAM
ADD IAU_AdminRoleName VARCHAR(255);
ALTER TABLE OAM
ADD IAU_ClientIPAddress VARCHAR(255);
ALTER TABLE OAM
ADD IAU_SessionCreationTime VARCHAR(255);
ALTER TABLE OAM
ADD IAU_SessionExpirationTime VARCHAR(255);
ALTER TABLE OAM
ADD IAU_SessionLastUpdateTime VARCHAR(255);
ALTER TABLE OAM
ADD IAU_SessionLastAccessTime VARCHAR(255);
ALTER TABLE OAM
ADD IAU_IdentityDomain VARCHAR(255);
ALTER TABLE OAM
ADD IAU_GenericAttribute1 VARCHAR(255);
ALTER TABLE OAM
ADD IAU_GenericAttribute2 VARCHAR(255);
ALTER TABLE OAM
ADD IAU_GenericAttribute3 VARCHAR(255);
ALTER TABLE OAM
ADD IAU_GenericAttribute4 VARCHAR(255);
ALTER TABLE OAM
ADD IAU_GenericAttribute5 VARCHAR(255);
ALTER TABLE OAM
ADD IAU_ResourceOperations VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_ApplicationDomainName VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_AuthenticationSchemeID VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_AgentID VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_SSOSessionID VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_AuthorizationScheme VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_ResourceID VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_AuthorizationPolicyID VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_UserID VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_PolicyName VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_SchemeName VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_ResourceHostName VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_OldAttributes VARCHAR(4000);
ALTER TABLE OAM
MODIFY IAU_NewAttributes VARCHAR(4000);
ALTER TABLE OAM
MODIFY IAU_ResponseType VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_AgentType VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_ConstraintType VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_InstanceName VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_DataSourceName VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_DataSourceType VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_HostIdentifierName VARCHAR(255);
ALTER TABLE OAM
MODIFY IAU_ResourceURI VARCHAR(1024);
ALTER TABLE OAM
MODIFY IAU_ResourceTemplateName VARCHAR(255);
