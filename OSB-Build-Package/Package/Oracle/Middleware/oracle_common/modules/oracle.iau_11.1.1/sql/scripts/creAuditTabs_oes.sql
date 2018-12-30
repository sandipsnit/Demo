Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/creAuditTabs_oes.sql /entsec_11.1.1.4.0_dwg/1 2011/01/07 14:04:34 skalyana Exp $
Rem
Rem creComponentTabs_oes.sql
Rem
Rem Copyright (c) 2010, 2011, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      creAuditTabs_oes.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    skalyana    12/10/10 - Created
Rem

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
        IAU_ComponentData           CLOB
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
GRANT INSERT ON IAU_BASE TO &&5;		
GRANT ALL    ON IAU_BASE TO &&1;		
GRANT SELECT ON IAU_BASE TO &&7;
GRANT SELECT ON ID_SEQ TO &&5;

-- SYNONYMS
CREATE or replace SYNONYM &&7..IAU_BASE FOR &&1..IAU_BASE;
CREATE or replace SYNONYM &&5..IAU_BASE FOR &&1..IAU_BASE;

-- START SCRIPTS TO CREATE ALL THE COMPONENT SPECIFIC TABS AND INDEXES
@@creComponentTabs_oes.sql &&1 &&5 &&7

-- PL/SQL stored procedures/functions
@@auditschema.pls &&1 &&5 &&7
@@auditreports.pls &&1 &&5 &&7

-- START SCRIPTS TO CREATE BI TRANSLATION RELATED TABLES 
@@creDispNames.sql &&1 &&5 &&7

-- START SCRIPT TO POPULATE DISPLAY NAME TABLE
@@disp_names_oes.sql

-- create base tables for dynamic metadat model
-- @@auditGenericTabs.sql &&1 &&5 &&7

exit
