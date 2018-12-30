Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/creAuditTabs.sql /st_entsec_11.1.1.7.0/4 2012/12/25 11:15:30 rkoul Exp $
Rem
Rem creAuditTabs.sql
Rem
Rem Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      creAuditTabs.sql 
Rem
Rem    DESCRIPTION
Rem      Creates Tables and indexes for the IAU Schema
Rem
Rem    NOTES
Rem      
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       12/20/12 - add user tenandID
Rem    rkoul       10/16/12 - create synonym for seq_id
Rem    dozhou      06/12/12 - XbranchMerge dozhou_bug-14155350 from main
Rem    dozhou      06/09/12 - add tenant id
Rem    dozhou      05/16/12 - XbranchMerge dozhou_audit_misc from main
Rem    dozhou      05/15/12 - add AuditUser
Rem    miqi        06/29/11 - XbranchMerge dozhou_audit_runtime from main
Rem    dozhou      11/09/10 - comment out auditGenericScript
Rem    shiahuan    11/04/09 - IAU_COMPONENTDATA
Rem    shiahuan    08/20/09 - Domain Name
Rem    pdatta      12/18/08 - split up disp_names.sql into two
Rem    gsandeep    03/26/08 - 
Rem    gsandeep    03/30/08 - 
Rem    srkannan    03/27/08 - add bi trans tables
Rem    sregmi      03/17/08 - Fix 6894368
Rem    gsandeep    02/26/08 - fix 6819233
Rem    gsandeep    02/22/08 - Add EventSourceType
Rem    sregmi      10/12/06 - Removing dbms_ias registration
Rem    sregmi      08/08/06 - Creation
Rem
Rem TODO Remove ComponentID and make ComponentType NOT NULL

-- &&1 - Audit Admin Role
-- &&2 - Audit Admin Password
-- &&3 - Default TableSpace
-- &&4 - Temporary Table Splace

-- &&5 - Audit Append Role
-- &&6 - Audit Append Password

-- &&7 - Audit Viewer Role
-- &&8 - Audit Viewer Password

@@auditUser.sql &&1 &&2 &&3 &&4 &&5 &&6 &&7 &&8

ALTER SESSION SET CURRENT_SCHEMA=&&1;

CREATE TABLE IAU_BASE (  
        IAU_ID                      NUMBER , 
        IAU_OrgId                   VARCHAR(255) ,
        IAU_ComponentId             VARCHAR(255) , 
        IAU_ComponentType	    VARCHAR(255) ,
	IAU_InstanceId              VARCHAR(255) , 
        IAU_HostingClientId         VARCHAR(255) , 
        IAU_HostId                  VARCHAR(255) , 
        IAU_HostNwaddr              VARCHAR(255) , 
        IAU_ModuleId                VARCHAR(255) , 
        IAU_ProcessId               VARCHAR(255) , 
        IAU_OracleHome              VARCHAR(255) , 
        IAU_HomeInstance            VARCHAR(255) , 
        IAU_UpstreamComponentId     VARCHAR(255) , 
        IAU_DownstreamComponentId   VARCHAR(255) , 
        IAU_ECID                    VARCHAR(255) , 
	IAU_RID			    VARCHAR(255) ,
	IAU_ContextFields	    VARCHAR(2000) ,
        IAU_SessionId               VARCHAR(255) , 
        IAU_SecondarySessionId      VARCHAR(255) , 
        IAU_ApplicationName         VARCHAR(255) , 
	IAU_TargetComponentType     VARCHAR(255) ,
        IAU_EventType               VARCHAR(255) , 
        IAU_EventCategory           VARCHAR(255) , 
        IAU_EventStatus             NUMBER       , 
        IAU_TstzOriginating         TIMESTAMP    , 
        IAU_ThreadId                VARCHAR(255) , 
        IAU_ComponentName           VARCHAR(255) , 
        IAU_Initiator               VARCHAR(255) , 
        IAU_MessageText             VARCHAR(2000) , 
        IAU_FailureCode             VARCHAR(255) , 
        IAU_RemoteIP                VARCHAR(255) , 
        IAU_Target                  VARCHAR(255) , 
        IAU_Resource                VARCHAR(255) , 
        IAU_Roles                   VARCHAR(255) , 
        IAU_AuthenticationMethod    VARCHAR(255) ,
        IAU_TransactionId	    VARCHAR(255) ,
        IAU_DomainName              VARCHAR(255) ,
        IAU_ComponentData           CLOB ,
        IAU_AuditUser               VARCHAR(255) ,
        IAU_TenantId                VARCHAR(255) ,
        IAU_UserTenantId            VARCHAR(255)
);

-- INDEXES
CREATE INDEX EVENT_TIME_INDEX
ON IAU_BASE(IAU_TSTZORIGINATING);   

-- SEQUENCE FOR AN ID FOR THE BASE TABLE
CREATE SEQUENCE ID_SEQ
START WITH 1
INCREMENT BY 30
NOMAXVALUE;

-- PERMISSIONS 
GRANT ALL    ON IAU_BASE TO &&1;		
GRANT INSERT ON IAU_BASE TO &&5;		
GRANT SELECT ON IAU_BASE TO &&5;
GRANT SELECT ON IAU_BASE TO &&7;
GRANT SELECT ON ID_SEQ TO &&5;

-- SYNONYMS
CREATE or replace SYNONYM &&7..IAU_BASE FOR &&1..IAU_BASE;
CREATE or replace SYNONYM &&5..IAU_BASE FOR &&1..IAU_BASE;

CREATE or replace SYNONYM &&5..ID_SEQ FOR &&1..ID_SEQ;

-- START SCRIPTS TO CREATE ALL THE COMPONENT SPECIFIC TABS AND INDEXES
@@creComponentTabs.sql &&1 &&5 &&7

-- PL/SQL stored procedures/functions
@@auditschema.pls &&1 &&5 &&7
@@auditreports.pls &&1 &&5 &&7

-- START SCRIPTS TO CREATE BI TRANSLATION RELATED TABLES 
@@creDispNames.sql &&1 &&5 &&7

-- START SCRIPT TO POPULATE DISPLAY NAME TABLE
@@disp_names.sql

-- create base tables for dynamic metadat model
@@auditGenericTabs.sql &&1 &&5 &&7

exit

