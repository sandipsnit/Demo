-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- MDSINSRB.sql - MDS INternal Shredded Repository Body
--
--
-- MODIFIED  (MM/DD/YY)
-- jhsi       10/11/11 - Update repos version to 11.1.1.61.63 for unshredded
--                       xml
-- erwang     09/30/11 - bump up repository version to 11.1.1.61.56
-- erwang     08/29/11 - Bump up reposition version# to 11.1.1.61.34
-- erwang     06/22/11 - #(12600604) adjust column sizes
-- erwang     03/22/11 - Change delimiter to /
-- erwang     01/10/11 - Creation.
--

-- This is used to verify that the repository API and MDS java code are
-- compatible.  REPOS_VERSION should be updated every time repository schema/ 
-- stored procedures are modified to current version of MDS.
--
-- In addition, if MDS java code is not compatible with older repository,
-- MysqlDB.MIN_SHREDDED_REPOS_VERSION should be changed to this value.

define REPOS_VERSION          = "11.1.1.61.63";


-- This is used to verify that the repository API and MDS java code are
-- compatible.  This is the earliest MDS midtier version which is compatible
-- with the repository.
define MIN_MDS_VERSION        = "11.1.1.61.34";

-- Maximum size for Max and Min Version
define MDS_VERSION            = 32;

-- System Defined Error ID.  Definition can be found at sys.messages table.
define LOCK_REQUEST_TIMEOUT   = 1222;

define DUP_VAL_ON_CONSTRAINT  = 2601;

define DUP_VAL_ON_INDEX       = 2627;

-- User-defined exceptions.
-- Must keep these error codes in sync with mdsinc.sql and other scripts.

-- External Error Codes to Java layer
define ERROR_DOCUMENT_NAME_CONFLICT = 50100;

define ERROR_PACKAGE_NAME_CONFLICT  = 50101;

define ERROR_CORRUPT_SEQUENCE       = 50102;

define ERROR_CONFLICTING_CHANGE     = 50103;

define ERROR_RESOURCE_BUSY          = 50104;

define ERROR_GUID_CONFLICT          = 50105;

define ERROR_RESOURCE_NOT_EXIST     = 50106;

define ERROR_LINEAGE_ALREADY_EXIST  = 50107;

define ERROR_NO_DATA_FOUND          = 50108;


-- Internal Error Codes
define ERROR_CHUNK_SIZE_EXCEEDED    = 50200;

define ERROR_ARRAY_OUT_OF_BOUNDARY  = 50201;


define NRI                          = 4000;

define PARTITION_NAME               = 200;

-- Gets the minimun version of MDS with which the repository is
-- compatible.  That is, the actual MDS version must be >= to the
-- minimum version of MDS in order for the repositroy and java code to
-- be compatible.
--
-- Returns:
--   Returns the mimumum version of MDS
--

drop function if exists mds_getMinMDSVersion
/


CREATE  FUNCTION mds_getMinMDSVersion()
RETURNS VARCHAR(15)
LANGUAGE SQL

BEGIN

    RETURN '$MIN_MDS_VERSION';
END
/



--
-- Gets the version of the repository API.  This API version must >= to the
-- java constant CompatibleVersions.MIN_REPOS_VERSION.
--
-- Returns:
--   Returns the version of the repository
--

drop function if exists mds_getRepositoryVersion
/

CREATE FUNCTION mds_getRepositoryVersion()
RETURNS VARCHAR(15)
LANGUAGE SQL

BEGIN

    RETURN '$REPOS_VERSION';
END
/


--
-- Gets the version and encoding of the repository API.
--
-- Returns:
--   Returns the version and encoding of the repository.
--

drop procedure if exists mds_getReposVersionAndEncoding
/

CREATE PROCEDURE mds_getReposVersionAndEncoding ( OUT reposVersion VARCHAR(15), 
                                                  OUT dbEncoding   VARCHAR(25))
LANGUAGE SQL

BEGIN
   
    SET reposVersion = '$REPOS_VERSION';
    
    -- get the encoding from the database, it returns 'utf8' for unicode.
    select default_character_set_name into dbEncoding 
             from information_schema.schemata 
             where schema_name = schema();   
END
/


--
-- Deletes the given partition. If there are any documents in the given
-- partition, this method will delete all those documents.  This procedure
-- will be committed in its own transaction upon success.
--
-- Parameters:
--   partitionName - Name of the partition.
--
drop procedure if exists mds_deletePartition
/


CREATE PROCEDURE mds_deletePartition (partitionName VARCHAR($PARTITION_NAME))
LANGUAGE SQL

BEGIN
    DECLARE partitionID    INT;

    DECLARE EXIT HANDLER FOR NOT FOUND
    BEGIN
        -- Mimic Oracle's behavior to throw an exception.
        RESIGNAL SQLSTATE '$ERROR_NO_DATA_FOUND'
             SET MESSAGE_TEXT = 'ERROR_NO_DATA_FOUND';
    END;
    
    SELECT partition_id INTO partitionID 
          FROM MDS_PARTITIONS
          WHERE partition_name = partitionName;
    
    DELETE FROM MDS_COMPONENTS WHERE comp_partition_id = partitionID;
    DELETE FROM MDS_ATTRIBUTES WHERE att_partition_id = partitionID;
    DELETE FROM MDS_NAMESPACES WHERE ns_partition_id = partitionID;

    CALL mds_internal_deletePartition(partitionID);
END
/

--
-- Retrieves the namespace id for the specified uri.  If the namespace
-- does not already exist, it will be created.  No validation occurs on the
-- uri.
--
-- Parameters:
--   namespaceID   - Returns the ID for the uri
--   partitionID   - Partition Id
--   uri           - uri
--

drop procedure if exists mds_getnamespaceID
/

CREATE PROCEDURE mds_getNamespaceID (OUT namespaceID INT, 
                                         partitionID INT, 
                                         uri         VARCHAR($NRI))
LANGUAGE SQL

BEGIN
    DECLARE EXIT HANDLER FOR NOT FOUND
    BEGIN
        -- Release the lock upon SQLException.
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SELECT RELEASE_LOCK('MDS_NAMESPACES');
            RESIGNAL;
        END;

        DECLARE EXIT HANDLER FOR NOT FOUND
        BEGIN
            INSERT INTO MDS_NAMESPACES(ns_partition_id, ns_uri)
                   VALUES (partitionID, uri);

            SELECT LAST_INSERT_ID() into namespaceID;

            SELECT RELEASE_LOCK('MDS_NAMESPACES');
        END;
           
        -- Get the application lock, wait for very long time.
        SELECT GET_LOCK('MDS_NAMESPACES', 9999999999) INTO @lock; 

        -- Read again to make sure it is not just added.
        -- Since no unique index on ns_uri and partition_id, we
        -- will have a share lock on the row while reading it.
        SELECT ns_id INTO namespaceID 
           FROM MDS_NAMESPACES 
             WHERE ns_uri = uri and
                   ns_partition_id = partitionID
             LOCK IN SHARE MODE;
                
        -- Someone just added it.
        SELECT RELEASE_LOCK('MDS_NAMESPACES');
    END;            
        
    SELECT ns_id INTO namespaceID 
           FROM MDS_NAMESPACES 
             WHERE ns_uri = uri and
                   ns_partition_id = partitionID;
END
/

--
-- Purges document versions from the shredded content tables.
-- See mds_internal_common.purgeMetadata() for more details of the purge
-- algorithm.
--
-- Parameters  
--  numVersionsPurged - Out parameter indicating number of versions purged
--  partitionID       - PartitionID for the repository partition
--  purgeCompareTime  - Creation time prior to which versions can be purged
--  secondsToLive     - Versions older than this time to be purged
--  isAutoPurge       - 0 if manual purge and 1 if auto-purge
--  commitNumber      - Commit number used for purging path and content tables  
--

drop procedure if exists mds_purgeMetadata
/

CREATE PROCEDURE mds_purgeMetadata ( OUT numVersionsPurged INT, 
                                         partitionID       INT, 
                                         purgeCompareTime  TIMESTAMP, 
                                         secondsToLive     INT, 
                                         isAutoPurge       SMALLINT, 
                                     OUT commitNumber      BIGINT)
LANGUAGE SQL

purgeMetadata:BEGIN
    DECLARE lockTimeout      INT DEFAULT -1;
    DECLARE P_LOCK_TIMEOUT   INT DEFAULT -1;
    DECLARE TMP_TABLE_EXISTS SMALLINT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Restore lock timeout.
        IF (P_LOCK_TIMEOUT <> -1) THEN
            SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;
        END IF;

        IF TMP_TABLE_EXISTS = 1 THEN
            DELETE FROM MDS_PURGE_PATHS;
        END IF;
    END;

    -- Save curent lock timeout
    SET P_LOCK_TIMEOUT = @@INNODB_LOCK_WAIT_TIMEOUT; 

    -- Set lock timeout to 5 times longer than timeout setting.
    IF (P_LOCK_TIMEOUT <> -1) THEN
    BEGIN
        SET lockTimeout = P_LOCK_TIMEOUT * 5;
        SET @@INNODB_LOCK_WAIT_TIMEOUT = lockTimeout;
    END;
    END IF;

    -- Set the purgeCompareTime from secondsToLive value
    -- SET purgeCompareTime = TIMESTAMPADD(SECOND, -1*secondsToLive, UTC_TIMESTAMP());

    SET commitNumber = -1;

    -- First, find the CN that is closest to the purge time (so that we
    -- don't have to do a full table scan of mds_tranasctions in a subquery)
    IF secondsToLive = 0 THEN
        SELECT IFNULL(MAX(txn_cn),-1)
            INTO commitNumber
            FROM MDS_TRANSACTIONS
            WHERE txn_partition_id = partitionID;
    ELSE
        -- We have to do inclusive since MySQL's TIMESTAMP doesn't save a fraction of a second.
        SELECT IFNULL(MAX(txn_cn),-1)
            INTO commitNumber
            FROM MDS_TRANSACTIONS
            WHERE txn_partition_id = partitionID
                  AND txn_time <= purgeCompareTime;
    END IF;

    -- No row found.
    IF ( commitNumber = -1 ) THEN
        LEAVE purgeMetadata;
    END IF;

    -- Create Temporary table MDS_PURGE_PATHS
    CREATE TEMPORARY TABLE IF NOT EXISTS MDS_PURGE_PATHS
        (PPATH_CONTENTID     BIGINT,
         PPATH_LOW_CN        BIGINT,
         PPATH_HIGH_CN       BIGINT,
         PPATH_PARTITION_ID  INT,
       INDEX MDS_PURGE_PATHS1(PPATH_LOW_CN, PPATH_PARTITION_ID, PPATH_HIGH_CN),
       INDEX MDS_PURGE_PATHS2(PPATH_CONTENTID, PPATH_PARTITION_ID)) ENGINE=INNODB;

    SET TMP_TABLE_EXISTS = 1;

    DELETE FROM MDS_PURGE_PATHS;


    SET numVersionsPurged = 0;

    -- This will populate mds_purge_data table with the data for paths
    -- that can be purged
    CALL mds_internal_purgeMetadata(numVersionsPurged,
                                    partitionID, 
                                    purgeCompareTime,
                                    secondsToLive,
                                    isAutoPurge,    
                                    commitNumber );

    IF (P_LOCK_TIMEOUT <> -1) THEN
        SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;
    END IF;

END
/


-- Used in the queryapi. The attr_value column contains both strings and
-- number values in a varchar2. In the query api we need to be able to
-- complete number and string comparisions against the values in the column.
-- However if we use to_number() on the column the string values are going to
-- fall over in a big heap and give the  ORACLE 01722 error: invalid number 
-- exception. This function allows us to handle this scenario more gracefully.
-- ie   to_number('29') works
-- to_number('sugar') -- SQLSTATE 22018. in this case return null.
--

drop function if exists mds_toNumber
/

CREATE FUNCTION mds_toNumber(attribute_value VARCHAR(100)) 
RETURNS DECIMAL 

LANGUAGE SQL
CONTAINS SQL

BEGIN 
    DECLARE rtnVal DECIMAL default 0;

    -- Handle for invalid numeric format.
    DECLARE CONTINUE HANDLER FOR 1366
    BEGIN
        SET rtnVal = NULL;
    END;

    IF (attribute_value IS NULL) THEN
        return NULL;
    END IF;
        
    SET rtnVal = CAST(attribute_value as decimal);

    RETURN rtnVal;
END
/


drop function if exists mds_trimWhite 
/

CREATE FUNCTION mds_trimWhite(parm VARCHAR(16380))
RETURNS VARCHAR(16380)
LANGUAGE SQL
BEGIN 
    DECLARE ch CHAR(1);
    DECLARE val VARCHAR(16380);
    SET val = parm;
    IF ( val IS NULL ) THEN
        RETURN NULL;
    END IF;
  leftTrim:
    WHILE CHAR_LENGTH(val) > 0 DO
        SET ch = LEFT(val,1);
        IF  ch = ' ' OR ch = char(10) OR ch = char(13) THEN
            SET val = SUBSTRING(val, 2);
        ELSE
            LEAVE leftTrim;
        END IF;
    END WHILE leftTrim;
  rightTrim:
    WHILE CHAR_LENGTH(val) > 0 DO
        SET ch = RIGHT(val, 1);
        IF  ch = ' ' OR ch = char(10) OR ch = char(13) THEN
            SET @len = CHAR_LENGTH(val) - 1;
            SET val = LEFT(val, @len);
        ELSE
            LEAVE rightTrim;
        END IF;
    END WHILE rightTrim;
    RETURN val;
END
/
