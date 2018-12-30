--
--
-- upgmds.db2
--
-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--    NAME
--      upgmds.db2 - SQL script to upgrade MDS repository.
--
--    DESCRIPTION
--    This file upgrades the schema for the MDS shredded repository.
--    It contains RCU preprocessor variable definitions and usages.
--    This file only alters tables and creates sequences. Other objects
--    (procedures, functions, types, variables, triggers, indexes, etc.) are
--    dropped and recreated using the same scripts as schema creation.
--
--    NOTES
--    This requires the IN_TABLESPACE preprocessor variable to be defined.
--    It should be set to either an empty string (to use the default tablespace)
--    or  "IN <tablespacename>" to use the given tablespace.
--
--    MODIFIED   (MM/DD/YY)
--    jhsi        10/17/11 - #(13100986) fixed syntax error for creating
--                           MDS_METADATA_DOCS table
--    jhsi        10/11/11 - Added MDS_METADATA_DOCS table and
--                           PATH_CONTENT_TYPE column
--    erwang      08/26/11 - Add PATH_DOC_MOTYPE_NSURI and PATH_DOC_MOTYPE_NAME
--                           columns
--    pwhaley     04/19/10 - #(9585915) XbranchMerge pwhaley_upgmds_db2 from main
--    pwhaley     04/14/10 - #(9584856) created from ../oracle/upgmds.sql.
--

-- Max. length for username
define username=240
@

-- Max length of application and deploy module(MAR) name
define deplName=400
@

-- Max length for motype_nsuri
define moTypeNSURI=800
@

-- Max length for motype_name
define moTypeName=127
@

-- Apply changes done for support of deployment management.
CREATE PROCEDURE upgradeMDS()
LANGUAGE SQL
BEGIN ATOMIC
    DECLARE cnt             integer;
    DECLARE upgradeForDepl  boolean;
    DECLARE partitionID     decimal(31,0);
    DECLARE createSeqStmt   varchar(256);
    DECLARE SQLSTATE        char(5);

    DECLARE c CURSOR FOR select partition_id from mds_partitions for read only;

    SET cnt = 0;
    SELECT count(*) into cnt from syscat.tables
            where type = 'T' and ownertype = 'U'
            and tabschema = current_schema
            and tabname = 'MDS_DEPL_LINEAGES'
            for read only;
    IF ( cnt = 0 ) then
        SET upgradeForDepl = true;
        -- CALL dbms_output.put_line('Applying deployment support changes.');
        EXECUTE immediate
            'CREATE table MDS_DEPL_LINEAGES (' ||
                'DL_PARTITION_ID             DECIMAL(31,0) NOT NULL,' ||
                'DL_LINEAGE_ID               DECIMAL(31,0) NOT NULL,' ||
                'DL_APPNAME                  VARCHAR($deplName) NOT NULL,' ||
                'DL_DEPL_MODULE_NAME         VARCHAR($deplName),' ||
                -- TODO: Reduce length of this to 1
                'DL_IS_SEEDED                DECIMAL(31,0)' ||
                ') $IN_TABLESPACE';
    END IF;

    SET cnt = 0;
    SELECT count(*) into cnt from syscat.tables
            where type = 'T' and ownertype = 'U'
            and tabschema = current_schema
            and tabname = 'MDS_METADATA_DOCS'
            for read only;
    IF ( cnt = 0 ) then
        EXECUTE immediate
            'CREATE table MDS_METADATA_DOCS (' ||
                'MD_PARTITION_ID             DECIMAL(31,0) NOT NULL,' ||
                'MD_CONTENTID                DECIMAL(31,0) NOT NULL,' ||
                'MD_CONTENTS                 CLOB(1G) NOT NULL' ||
                ') $IN_TABLESPACE';
    END IF;

    -- Check and create the new columns as a separate steps to handle
    -- corner case of mds_depl_lineage left out from a PS2 schema when
    -- PS1 schema is installed on top of PS2.
    SET cnt = 0;
    SELECT count(*) into cnt from syscat.columns
            where tabschema = current_schema
            and tabname = 'MDS_PATHS' and colname = 'PATH_LINEAGE_ID';
    IF ( cnt = 0 ) then
        SET upgradeForDepl = true;
        EXECUTE immediate
            'ALTER table MDS_PATHS ADD COLUMN PATH_CONT_CHECKSUM DECIMAL(31,0)';
        EXECUTE immediate
            'ALTER table MDS_PATHS ADD COLUMN PATH_LINEAGE_ID DECIMAL(31,0)';
    END IF;

    IF ( upgradeForDepl = true ) then
        -- Create lineage id sequence for all the existing partitions.
        OPEN c;
        createSequences:
        WHILE ( 1 = 1 ) do
            FETCH from c into partitionID;
            IF ( SQLSTATE <> '00000' ) then
                CLOSE c;
                LEAVE createSequences;
            END IF;
            SET createSeqStmt = 'CREATE SEQUENCE mds_lineage_id_' ||
                                    partitionID ||
                                    '_s start with 1 increment by 1';
            EXECUTE immediate createSeqStmt;
            -- For completeness, handle case where sequence already exists.
            IF ( SQLSTATE = '42710' ) THEN
                -- CALL dbms_output.put_line('Sequence mds_lineage_id_' ||
                --                         partitionID ||
                --                         ' already exists, not recreated.');
            END IF;
        END WHILE createSequences;
    END IF;

    -- Added the path_doc_motype_nsuri and path_doc_motype_name colums
    SET cnt = 0;
    SELECT count(*) into cnt from syscat.columns
            where tabschema = current_schema
            and tabname = 'MDS_PATHS' and colname = 'PATH_DOC_MOTYPE_NAME';
    IF ( cnt = 0 ) then
        EXECUTE immediate 'ALTER TABLE MDS_PATHS ADD PATH_DOC_MOTYPE_NSURI VARCHAR($moTypeNSURI)';
        EXECUTE immediate 'ALTER TABLE MDS_PATHS ADD PATH_DOC_MOTYPE_NAME VARCHAR($moTypeName)';
    END IF;

    -- Added the path_content_type column
    SET cnt = 0;
    SELECT count(*) into cnt from syscat.columns
            where tabschema = current_schema
            and tabname = 'MDS_PATHS' and colname = 'PATH_CONTENT_TYPE';
    IF ( cnt = 0 ) then
        EXECUTE immediate 'ALTER TABLE MDS_PATHS ADD PATH_CONTENT_TYPE DECIMAL(31,0)';
    END IF;

    -- Added the sb_created_by, sb_created_on and label_time colums to support
    -- sandbox metadata and purging of labels.
    SET cnt = 0;
    SELECT count(*) into cnt from syscat.columns
            where tabschema = current_schema
            and tabname = 'MDS_SANDBOXES' and colname = 'SB_CREATED_BY';
    IF ( cnt = 0 ) then
        EXECUTE immediate 'ALTER TABLE MDS_SANDBOXES ADD SB_CREATED_BY VARCHAR($username)';
    END IF;
    SET cnt = 0;
    SELECT count(*) into cnt from syscat.columns
            where tabschema = current_schema
            and tabname = 'MDS_SANDBOXES' and colname = 'SB_CREATED_ON';
    IF ( cnt = 0 ) then
        EXECUTE immediate 'ALTER TABLE MDS_SANDBOXES ADD SB_CREATED_ON TIMESTAMP';
    END IF;
    SET cnt = 0;
    SELECT count(*) into cnt from syscat.columns
            where tabschema = current_schema
            and tabname = 'MDS_LABELS' and colname = 'LABEL_TIME';
    IF ( cnt = 0 ) then
        EXECUTE immediate 'ALTER TABLE MDS_LABELS ADD LABEL_TIME TIMESTAMP';
    END IF;


END
@

call upgradeMDS()
@

drop procedure upgradeMDS()
@




