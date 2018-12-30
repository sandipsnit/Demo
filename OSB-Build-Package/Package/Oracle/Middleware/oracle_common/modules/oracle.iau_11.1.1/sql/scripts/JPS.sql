Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/JPS.sql /st_entsec_11.1.1.7.0/1 2012/10/16 18:41:13 rkoul Exp $
Rem
Rem JPS.sql
Rem
Rem Copyright (c) 2007, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      JPS.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       10/16/12 - grant select to append user
Rem    skalyana    04/23/11 - Update for OES changes
Rem    shiahuan    09/03/09 - XbranchMerge shiahuan_bug-8847408 from
Rem                           st_entsec_11.1.1.2.0
Rem    sregmi      05/12/08 - Adding new Attributes
Rem    sregmi      07/12/07 - Created
Rem


-- SQL Script for JPS
-- &&1 - Audit Admin Role
-- &&2 - Audit Append Role
-- &&3 - Audit Viewer Role

CREATE TABLE JPS (
	IAU_ID NUMBER , 
	IAU_TstzOriginating TIMESTAMP , 
	IAU_EventType VARCHAR(255) , 
	IAU_EventCategory VARCHAR(255) , 
	IAU_CodeSource VARCHAR(1024) , 
	IAU_Principals VARCHAR(1024) , 
	IAU_InitiatorGUID VARCHAR(1024) , 
	IAU_Subject VARCHAR(1024) , 
	IAU_PermissionAction VARCHAR(1024) , 
	IAU_PermissionTarget VARCHAR(1024) , 
	IAU_PermissionClass VARCHAR(1024) , 
	IAU_mapName VARCHAR(1024) , 
	IAU_key VARCHAR(1024) , 
	IAU_PermissionScope VARCHAR(1024) , 
	IAU_ApplicationRole VARCHAR(1024) , 
	IAU_EnterpriseRoles VARCHAR(1024) , 
	IAU_InitiatorDN VARCHAR(1024) , 
	IAU_GUID VARCHAR(1024) , 
	IAU_Permission VARCHAR(1024) , 
	IAU_ModifiedAttributeName VARCHAR(1024) , 
	IAU_ModifiedAttributeValue VARCHAR(2048) , 
	IAU_PermissionSetName VARCHAR(1024) , 
	IAU_ResourceActions VARCHAR(1024) , 
	IAU_ResourceType VARCHAR(1024) ,
        IAU_stripeName VARCHAR(1024) ,
        IAU_keystoreName VARCHAR(1024) ,
        IAU_alias VARCHAR(1024) ,
        IAU_operation VARCHAR(1024),
        IAU_PermissionCheckResult VARCHAR(50),
        IAU_RuntimeResource VARCHAR(2048),
        IAU_RuntimeAction VARCHAR(1024),
        IAU_AppContext VARCHAR(2048),
        IAU_Direction VARCHAR(50),
        IAU_AccessResult VARCHAR(1024),
        IAU_ManagedApplication VARCHAR(1024),
        IAU_PolicyName VARCHAR(1024),
        IAU_PolicyDomainName VARCHAR(1024),
        IAU_PolicyCodeSource VARCHAR(1024),
        IAU_PolicyRules VARCHAR(2048),
        IAU_PermSets VARCHAR(2048),
        IAU_Obligations VARCHAR(1024),
        IAU_PolicySemantic VARCHAR(1024),
        IAU_PolicyPrincipalsOld VARCHAR(2048),
        IAU_PolicyCodeSourceOld VARCHAR(1024),
        IAU_PolicyRulesOld VARCHAR(2048),
        IAU_PermSetsOld VARCHAR(2048),
        IAU_ResourceActionsOld VARCHAR(2048),
        IAU_ObligationsOld VARCHAR(1024),
        IAU_Cascade VARCHAR(50),
        IAU_ResName VARCHAR(1024),
        IAU_ResTypeName VARCHAR(1024),
        IAU_ResourceAttributes VARCHAR(1024),
        IAU_ModifiedAttributeValueNew VARCHAR(2048),
        IAU_ModifiedAttributeValueOld VARCHAR(2048),
        IAU_ResourceAttributesOld VARCHAR(1024),
        IAU_RoleMembers VARCHAR(2048),
        IAU_ResourceNames VARCHAR(2048),
        IAU_PolicyPrincipals VARCHAR(2048),
        IAU_AdminRoleName VARCHAR(1024),
        IAU_PolicyAppRolePrincipals VARCHAR(2048),
        IAU_ResourceNameExpressions VARCHAR(2048),
        IAU_PolicyAppRolePrincipalsOld VARCHAR(2048),
        IAU_RoleMembersOld VARCHAR(2048),
        IAU_ResourceNamesOld VARCHAR(2048),
        IAU_ResourceNameExpressionsOld VARCHAR(2048),
        IAU_Flush VARCHAR(1024),
        IAU_PdpAddress VARCHAR(1024),
        IAU_PurgeTime VARCHAR(1024),
        IAU_ConfigurationId VARCHAR(1024)
);

-- INDEX 
CREATE INDEX JPS_Index
ON JPS(IAU_TSTZORIGINATING);

-- PERMISSIONS 
GRANT ALL on JPS to &&1;
GRANT INSERT on JPS to &&2;
GRANT SELECT on JPS to &&2;
GRANT SELECT on JPS to &&3;

-- SYNONYMS 
CREATE OR REPLACE SYNONYM &&3..JPS FOR &&1..JPS;
CREATE OR REPLACE SYNONYM &&2..JPS FOR &&1..JPS;
