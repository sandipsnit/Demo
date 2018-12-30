Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/WS-PolicyAttachment.sql /st_entsec_11.1.1.7.0/1 2012/10/16 18:41:13 rkoul Exp $
Rem
Rem WS-PolicyAttachment.sql
Rem
Rem Copyright (c) 2008, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      WS-PolicyAttachment.sql - <one-line expansion of the name>
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

-- SQL Script for WS_PolicyAttachment
-- &&1 - Audit Admin Role
-- &&2 - Audit Append Role
-- &&3 - Audit Viewer Role

CREATE TABLE WS_PolicyAttachment (
        IAU_ID NUMBER ,
        IAU_TstzOriginating TIMESTAMP ,
        IAU_EventType VARCHAR(255) ,
        IAU_EventCategory VARCHAR(255) ,
        IAU_PolicyChangeType VARCHAR(255) ,
        IAU_PolicyURI VARCHAR(4000) ,
        IAU_PolicyCategory VARCHAR(255) ,
        IAU_PolicyStatus VARCHAR(255) ,
        IAU_ServiceEndPoint VARCHAR(4000) ,
        IAU_PolicySubjRescPattern VARCHAR(4000)
);


-- INDEX 
CREATE INDEX WS_PolicyAttachment_Index
ON WS_PolicyAttachment(IAU_TSTZORIGINATING);

-- PERMISSIONS 
GRANT ALL on WS_PolicyAttachment to &&1;
GRANT INSERT on WS_PolicyAttachment to &&2;
GRANT SELECT on WS_PolicyAttachment to &&2;
GRANT SELECT on WS_PolicyAttachment to &&3;

-- SYNONYMS 
CREATE OR REPLACE SYNONYM &&3..WS_PolicyAttachment FOR &&1..WS_PolicyAttachment;
CREATE OR REPLACE SYNONYM &&2..WS_PolicyAttachment FOR &&1..WS_PolicyAttachment;
