Rem
Rem
Rem upgmds.sql
Rem
Rem Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      upgmds.sql - SQL script to upgrade MDS repository.
Rem
Rem    DESCRIPTION
Rem    This file upgrades indexes and stored procedures for the MDS
Rem    shredded repository.
Rem
Rem    NOTES
Rem    It is required to run upgmdsvpd.sql after running this script
Rem    if any schema table has been modified for adding multitenancy
Rem    support.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jhsi        02/27/12 - #(12751112) Call configurestats.sql for setting
Rem                           dbms_stats preferences
Rem    jhsi        09/16/11 - Added MDS_METADATA_DOCS table and
Rem                           PATH_CONTENT_TYPE column
Rem    erwang      08/24/11 - Added PATH_DOC_MOTYPE_NAME and
Rem                           PATH_DOC_MOTYPE_NSURI if not exists
Rem    jhsi        08/16/11 - Added PARTITION_MT_STATE column
Rem    jhsi        07/28/11 - Move VPD policy upgrade to upgmdsvpd.sql
Rem    jhsi        07/06/11 - VPD - multitenancy support
Rem    gnagaraj    12/21/09 - Upgrade for deploy support
Rem    gnagaraj    10/08/09 - XbranchMerge gnagaraj_colsize_changes_bug8859749
Rem                           from main
Rem    vyerrama    03/23/10 - #(9320961) Added sandbox and label table columns
Rem    gnagaraj    10/08/09 - #(8859749) Include column size changes
Rem    gnagaraj    08/17/09 - Created
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

Rem Recreating the types
@@cremdstyps


Rem Apply changes done for support deployment management
DECLARE
    cnt              NUMBER;
    upgradeForDepl  BOOLEAN := FALSE;
    partitionID      MDS_PARTITIONS.PARTITION_ID%TYPE;
    createSeqStmt    VARCHAR2(256);
    SEQUENCE_EXISTS  EXCEPTION;
    PRAGMA EXCEPTION_INIT (SEQUENCE_EXISTS, -00955);
CURSOR c IS
      SELECT partition_id
      FROM mds_partitions;
BEGIN

  cnt := 0;
  SELECT COUNT(*) INTO cnt FROM USER_TABLES WHERE TABLE_NAME = 'MDS_DEPL_LINEAGES';
  IF (cnt = 0) THEN
    upgradeForDepl := TRUE;
    dbms_output.put_line('Applying deployment support changes');
    EXECUTE IMMEDIATE 
        'CREATE TABLE MDS_DEPL_LINEAGES (
         DL_PARTITION_ID             NUMBER NOT NULL,
         DL_LINEAGE_ID               NUMBER NOT NULL,
         DL_APPNAME                  VARCHAR2(400) NOT NULL,
         DL_DEPL_MODULE_NAME         VARCHAR2(400),
         DL_IS_SEEDED                NUMBER
         )';
  END IF;

  -- Check and create the new columns as a separate steps to handle
  -- corner case of mds_depl_lineage left out from a PS2 schema when
  -- PS1 schema is installed on top of PS2.
  cnt := 0;
  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_PATHS'
  AND column_name='PATH_LINEAGE_ID';
  IF (cnt = 0) THEN
    upgradeForDepl := TRUE;
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_PATHS ADD PATH_CONT_CHECKSUM NUMBER';
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_PATHS ADD PATH_LINEAGE_ID NUMBER';
  END IF;

  
  IF ( upgradeForDepl = TRUE ) THEN
    -- Create lineage id sequence for all the existing partitions
    OPEN c;
    LOOP
      FETCH c INTO partitionID;
      IF (c%NOTFOUND) THEN
        CLOSE c;
        EXIT;
      END IF;
      BEGIN
        createSeqStmt := 'CREATE SEQUENCE mds_lineage_id_' ||
                          partitionID ||
                          '_s  START WITH 1 INCREMENT BY 1';
        EXECUTE IMMEDIATE createSeqStmt;
        EXCEPTION
          -- For completeness, handle case where sequence already exists
          WHEN SEQUENCE_EXISTS THEN
          BEGIN
            dbms_output.put_line('Sequence mds_lineage_id_' ||
                                 partitionID 
                                 || ' already exists, not recreated');
          END;
      END;
    END LOOP;
  END IF;


  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_SANDBOXES'
  AND column_name='SB_CREATED_BY';

-- Added the sb_created_by, sb_created_on and label_time colums to support sandbox metadata 
-- and purging of labels.
  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_SANDBOXES ADD SB_CREATED_BY VARCHAR2(200)';
  END IF;

  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_SANDBOXES'
  AND column_name='SB_CREATED_ON';

  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_SANDBOXES ADD SB_CREATED_ON TIMESTAMP';
  END IF;

  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_LABELS'
  AND column_name='LABEL_TIME';

  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_LABELS ADD LABEL_TIME TIMESTAMP';
  END IF;


  -- Add PATH_DOC_MOTYPE_NAME and PATH_DOC_MOTYPE_NSURI if they are not in the
  -- table.
  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_PATHS'
  AND column_name='PATH_DOC_MOTYPE_NAME';
  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_PATHS ADD (PATH_DOC_MOTYPE_NSURI VARCHAR2(800),' ||
                                                 'PATH_DOC_MOTYPE_NAME VARCHAR2(127))';
  END IF;

  -- Add PATH_CONTENT_TYPE if they are not in the table.
  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_PATHS'
  AND column_name='PATH_CONTENT_TYPE';
  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_PATHS ADD PATH_CONTENT_TYPE NUMBER';
  END IF;

  -- Add enterprise_id column for VPD - multitenancy support
  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_PATHS'
    AND column_name='ENTERPRISE_ID'; 
  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_PATHS ADD ENTERPRISE_ID NUMBER(18) 
      DEFAULT NVL(SYS_CONTEXT(''CLIENTCONTEXT'', ''MDS_MT_TENANT_ID''), 0)';
  END IF;

   
  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_DEPL_LINEAGES'
    AND column_name='ENTERPRISE_ID';

  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_DEPL_LINEAGES ADD ENTERPRISE_ID NUMBER(18) 
      DEFAULT NVL(SYS_CONTEXT(''CLIENTCONTEXT'', ''MDS_MT_TENANT_ID''), 0)';
  END IF;

  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_LABELS'
    AND column_name='ENTERPRISE_ID';

  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_LABELS ADD ENTERPRISE_ID NUMBER(18) 
      DEFAULT NVL(SYS_CONTEXT(''CLIENTCONTEXT'', ''MDS_MT_TENANT_ID''), 0)';
  END IF;
   
  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_STREAMED_DOCS'
    AND column_name='ENTERPRISE_ID';

  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_STREAMED_DOCS ADD ENTERPRISE_ID NUMBER(18) 
      DEFAULT NVL(SYS_CONTEXT(''CLIENTCONTEXT'', ''MDS_MT_TENANT_ID''), 0)';
  END IF;
   
  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_DEPENDENCIES'
    AND column_name='ENTERPRISE_ID';

  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_DEPENDENCIES ADD ENTERPRISE_ID NUMBER(18) 
      DEFAULT NVL(SYS_CONTEXT(''CLIENTCONTEXT'', ''MDS_MT_TENANT_ID''), 0)';
  END IF;

  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_SANDBOXES'
    AND column_name='ENTERPRISE_ID';

  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_SANDBOXES ADD ENTERPRISE_ID NUMBER(18) 
      DEFAULT NVL(SYS_CONTEXT(''CLIENTCONTEXT'', ''MDS_MT_TENANT_ID''), 0)';
  END IF;

  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_COMPONENTS'
    AND column_name='ENTERPRISE_ID';

  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_COMPONENTS ADD ENTERPRISE_ID NUMBER(18) 
      DEFAULT NVL(SYS_CONTEXT(''CLIENTCONTEXT'', ''MDS_MT_TENANT_ID''), 0)';
  END IF;

  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_ATTRIBUTES'
    AND column_name='ENTERPRISE_ID';

  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_ATTRIBUTES ADD ENTERPRISE_ID NUMBER(18) 
      DEFAULT NVL(SYS_CONTEXT(''CLIENTCONTEXT'', ''MDS_MT_TENANT_ID''), 0)';
  END IF;

  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_LARGE_ATTRIBUTES'
    AND column_name='ENTERPRISE_ID';

  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_LARGE_ATTRIBUTES ADD ENTERPRISE_ID NUMBER(18) 
      DEFAULT NVL(SYS_CONTEXT(''CLIENTCONTEXT'', ''MDS_MT_TENANT_ID''), 0)';
  END IF;

  -- Add partiton_mt_state column for multitenancy support
  SELECT COUNT(*) INTO cnt FROM user_tab_columns WHERE table_name='MDS_PARTITIONS'
    AND column_name='PARTITION_MT_STATE';

  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE MDS_PARTITIONS ADD PARTITION_MT_STATE NUMBER';
  END IF;

  -- Add MDS_METADATA_DOCS table for unshreaded document content support
  cnt := 0;
  SELECT COUNT(*) INTO cnt FROM USER_TABLES WHERE TABLE_NAME = 'MDS_METADATA_DOCS';
  IF (cnt = 0) THEN
    EXECUTE IMMEDIATE 
        'create table MDS_METADATA_DOCS (
         MD_PARTITION_ID  NUMBER NOT NULL,
         MD_CONTENTID     NUMBER NOT NULL,
         MD_CONTENTS      CLOB NOT NULL,
         ENTERPRISE_ID    NUMBER(18) DEFAULT NVL(SYS_CONTEXT(''CLIENTCONTEXT'', ''MDS_MT_TENANT_ID''), 0)
         )';
  END IF;

END;
/

Rem Recreating the indexes
@@dropmdsinds
@@cremdsinds

Rem Recreating the package specs
@@MDSINCS.pls
@@MDSINSRS.pls
@@MDSUTINS.pls

Rem Recreating the package bodies
@@MDSINCB.plb
@@MDSINSRB.plb
@@MDSUTINB.plb

Rem Setting dbms_stats preferences
@@configurestats

Rem If there were any compilations problems this will spit out the 
Rem the errors. uncomment to get errors.
Rem show errors

EXIT;
