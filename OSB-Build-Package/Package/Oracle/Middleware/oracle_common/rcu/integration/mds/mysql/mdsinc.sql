-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- MDSINC.SQL - MDS metadata services INternal Common Body
--
-- Notes:
--   For database portablity reason, please don't introduce any new public
--   functions.  
--
-- MODIFIED    (MM/DD/YYYY)
--  jhsi        10/11/11 - Added param contentType to prepareDocForInsert
--  erwang      09/29/11 - Added retry in insertPath
--  erwang      08/29/11 - Added moTypeNSURI and moTypeName to
--                         preparpeDocForInsert()
--  erwang      06/22/11 - #(12600604) adjust column sizes
--  erwang      03/22/11 - Change delimiter to /
--  erwang      01/21/11 - Added a trigger to prevent from inserting two same
--                          rows with NULL GUID
--  erwang      01/11/2011  - Created.
--

-- ---------------------------------------------------------------------------
-- -------------------------- PRIVATE VARIABLES ------------------------------
-- ---------------------------------------------------------------------------

-- User-defined exceptions.
-- The error code will be encoded in text message of error 90000.  "'" must be 
-- used in define error code.  
-- The error codes should be kept in sync with mdsinsr.sql and all other scripts 
-- They must also be in sync with errorcode definitions in Java class Db2DB.

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
 
define ERROR_NAME_CONFLICT_NONTIP   = 50109;
 

-- Internal Error Codes
define ERROR_CHUNK_SIZE_EXCEEDED    = 50200;
 
define ERROR_ARRAY_OUT_OF_BOUNDARY  = 50201;
 

  
-- PATH_DOCID of "/" is assumed to be 0
define ROOT_DOCID                   = 0;
 
  
-- Enumeration values for PATH_OPERATION values indicating the operation
-- performed on a path (version).
define DELETE_OP                   = 0;
 
define CREATE_OP                   = 1;
 
define UPDATE_OP                   = 2;
 
define RENAME_OP                   = 3;
 

-- Enumeration values for PATH_TYPE indicating the type of resource
define TYPE_DOCUMENT              = "DOCUMENT";
 
define TYPE_PACKAGE               = "PACKAGE";
 

-- Value used for PATH_HIGH_CN, PATH_LOW_CN when the changes are not yet
-- commited (i.e, in-transaction value). Since no other transaction would
-- see this value (as it is yet uncommited) it is not a problem for all
-- transactions to use this same number as the Commit Number for all CN
-- columns prior to commiting the changes.
-- When the changes are commited, processCommit() replaces this CN value
-- with the commit number generated for that transaction.
define INTXN_CN                   = -1;
 

-- Integer constants to denote a true or a false value
define INT_TRUE                  =  1;
 
define INT_FALSE                 = -1;
 

-- constant variables defines the size 
define CREATOR                    = 64; 
 
define ELEM_NSURI                 = 800;
 
define ELEM_NAME                  = 127;
 
define FULLNAME                   = 480;
 
define GUID                       = 36;
 
define LABEL_NAME                 = 512;
 
define PARTITION_NAME             = 200;
 
define PATH_NAME                  = 256;
 
define PATH_TYPE                  = 30;
 
define VER_COMMENTS               = 800;
 
define XML_VERSION                = 10;
 
define XML_ENCODING               = 60;

define SEQ_NAME                   = 256;
 
define DEPL_NAME                  = 350;

define lcktimeout                 = 1;
 
define retries                    = 5;

-- Trigger to prevent inserting two same rows with NULL GUID.
drop trigger if exists mds_path_trigger_insert
/

create trigger mds_path_trigger_insert before insert on MDS_PATHS 
   FOR EACH ROW BEGIN
       DECLARE existsRow INT DEFAULT 0;
       IF (NEW.PATH_GUID IS NULL ) THEN
           -- We will have to enforce MDS_PATHS_U2 here.
  
           SELECT  1 INTO existsRow FROM MDS_PATHS WHERE
                 PATH_OWNER_DOCID= NEW.PATH_OWNER_DOCID AND
                 PATH_NAME = NEW.PATH_NAME AND
                 PATH_VERSION = NEW.PATH_VERSION AND
                 PATH_PARTITION_ID = NEW.PATH_PARTITION_ID AND
                 PATH_GUID IS NULL LIMIT 1 
              LOCK IN SHARE MODE;
           IF existsRow = 1 THEN
               SIGNAL SQLSTATE '23000' 
                    SET MYSQL_ERRNO=1062, CONSTRAINT_NAME = 'MDS_PATHS_U2';
           END IF;
       END IF;
   END
/

drop function if exists mds_internal_INSTR
/

--
-- Return the index of the last occurrence of the first string in the second.
-- This function is like Oracle's INSTR with a negative third operand.
--
-- Parameters:
--   str1      - String to be found.
--   str2      - String to search in.
-- Returns:
--   the (one-origin) index of the last occurrence of str1 in str2, or zero
--   if str1 isn't a substring of str2.

create FUNCTION mds_internal_INSTR(str1  VARCHAR(1024),
                                   str2  VARCHAR(4000))
RETURNS SMALLINT

LANGUAGE SQL
DETERMINISTIC
CONTAINS SQL

BEGIN 
  DECLARE pos      SMALLINT;
  DECLARE prevPos  SMALLINT;
 
  -- Handling special cases
  IF NULLIF(str1,'') IS NULL OR 
       NULLIF(str2,'') IS NULL THEN
     RETURN 0;
  END IF; 

  SET prevPos = 0;
  SET pos = LOCATE(str1, str2, 1);

  WHILE pos <> 0 DO
    SET prevPos = pos;
    SET pos = LOCATE(str1, str2, prevPos + 1);
  END WHILE;

  RETURN prevPos;
END
/


drop procedure if exists mds_lockDocument
/
--
-- Locks the tip version of the document, given a valid docID.
-- If the document is already locked, a "RESOURCE_BUSY" exception will 
-- be raised.
--
-- Parameters:
--   partitionID   - the partition where the document exists
--   docID         - ID of the document to lock
--   useVersionNum - if true, the versionNum of the locked document will be returned. 
--   versionNum    - OUT parameter, version of the document that was locked.
--
CREATE PROCEDURE mds_lockDocument (IN  partitionID    INT, 
                                   IN  docID          BIGINT, 
                                   IN  useVersionNum  SMALLINT, 
                                   OUT versionNum     INT )
LANGUAGE SQL

BEGIN
    DECLARE tmpdocID BIGINT;

    DECLARE P_LOCK_TIMEOUT  INT DEFAULT -1;

    DECLARE COUNT    SMALLINT DEFAULT 1;

    DECLARE RETRY_NEEDED SMALLINT DEFAULT 0;


    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;

        RESIGNAL;
    END;


    -- Save curent lock timeout
    SET P_LOCK_TIMEOUT = @@INNODB_LOCK_WAIT_TIMEOUT;

    SET @@INNODB_LOCK_WAIT_TIMEOUT = $lcktimeout;

    LOCK_RETRIES:
    REPEAT
    BEGIN
      DECLARE CONTINUE HANDLER FOR NOT FOUND
      BEGIN
        DECLARE DOC_EXISTS SMALLINT DEFAULT 0;

        SET COUNT = COUNT + 1;
        SET RETRY_NEEDED = 1;

        -- We found that we couldn't find the row in some cases
        -- while multiple threads creating new version at same time.
        -- We will do retry if the query can find the row.
        SELECT 1 INTO DOC_EXISTS FROM DUAL WHERE
             EXISTS(SELECT PATH_DOCID FROM MDS_PATHS WHERE
                 PATH_PARTITION_ID = partitionID AND
                 PATH_DOCID = docID AND PATH_HIGH_CN IS NULL);

        IF DOC_EXISTS = 0 OR
             COUNT > $retries THEN
        BEGIN
           SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;

           IF DOC_EXISTS > 0 THEN
               -- We rather throw an exception here.
               RESIGNAL SQLSTATE '$ERROR_RESOURCE_BUSY'
                   SET MESSAGE_TEXT = '$ERROR_RESOURCE_BUSY';
           ELSE
           BEGIN
               -- Maybe it was deleted.
               IF useVersionNum = 1 THEN
                   -- we canot return a NULL versionNum
                   RESIGNAL SQLSTATE '$ERROR_RESOURCE_NOT_EXIST'
                       SET MESSAGE_TEXT = '$ERROR_RESOURCE_NOT_EXIST';
               ELSE
                   SET RETRY_NEEDED = 0;
               END IF;
           END;
           END IF;
        END;
        END IF;
      END;

      -- Continue handler for lock timeout and deadlock;
      DECLARE CONTINUE HANDLER FOR 1205,1213
      BEGIN
          SET COUNT = COUNT + 1;

          SET RETRY_NEEDED = 1;

          IF (COUNT >= $retries) THEN
              SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;

              RESIGNAL SQLSTATE '$ERROR_RESOURCE_BUSY'
                   SET MESSAGE_TEXT = 'ERROR_RESOURCE_BUSY';
          END IF;
      END;

      -- Continue handler for all other exceptions;
      SET RETRY_NEEDED = 0;

      IF (useVersionNum) = 1 THEN
          SELECT path_docid, path_version
            INTO tmpdocID, versionNum
            FROM MDS_PATHS
            WHERE path_docid = docID
              AND path_high_cn IS NULL
              AND path_partition_id = partitionID
              AND path_version = (SELECT path_version FROM MDS_PATHS 
                                      WHERE path_docid = docID AND
                                            path_high_cn IS NULL AND
                                            path_partition_id = partitionID)
             FOR UPDATE;
      ELSE
          SELECT path_docid INTO tmpdocID
              FROM MDS_PATHS
              WHERE path_docid = docID
                AND path_high_cn IS NULL
                AND path_partition_id = partitionID
              FOR UPDATE;

      END IF;
    END;

      UNTIL RETRY_NEEDED = 0
    END REPEAT LOCK_RETRIES;

    -- Restore lock timeout.
    SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;
END
/



drop procedure if exists mds_acquireWriteLock
/

--
--
-- Locks the tip version for the specified document, so that it can not be
-- modified/deleted/renamed untill this transaction is commited.
--
-- If the document is already locked, it will not retry to obtain the lock 
-- and a "RESOURCEBUSY" exception will be raised.
--
-- If the document to be locked does not exist 'ERROR_RESOURCE_NOT_EXIST'
-- exception will be raised.  
--
-- Parameters:
--   partitionID  - the partition where the document exists.
--   fullPathName - Fully qualified name of the document
--   mdsGuid      - GUID for the document, if non-null, GUID will be used
--                  to locate the documen
--
CREATE PROCEDURE mds_acquireWriteLock (partitionID   INT, 
                                       fullPathName  VARCHAR($FULLNAME), 
                                       mdsGuid       VARCHAR($GUID))
LANGUAGE SQL

BEGIN
    DECLARE tmpDocID      BIGINT;
    DECLARE tmpVersionNum INT;

    DECLARE P_LOCK_TIMEOUT  INT DEFAULT -1;

    DECLARE COUNT    SMALLINT DEFAULT 0;

    DECLARE LOCKTIMEOUT_HAPPENED SMALLINT DEFAULT 0;


    -- Continue handler for all other exceptions;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;

        RESIGNAL;
    END;


    -- Save curent lock timeout
    SET P_LOCK_TIMEOUT = @@INNODB_LOCK_WAIT_TIMEOUT;

    SET @@INNODB_LOCK_WAIT_TIMEOUT = $lcktimeout;


    LOCK_RETRIES:
    REPEAT
    BEGIN
      DECLARE EXIT HANDLER FOR NOT FOUND
      BEGIN
          SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;

          RESIGNAL SQLSTATE '$ERROR_RESOURCE_NOT_EXIST'
                   SET MESSAGE_TEXT = 'ERROR_RESOURCE_NOT_EXIST';
      END;

      -- Continue handler for lock timeout and deadlock;
      DECLARE CONTINUE HANDLER FOR 1205,1213
      BEGIN
          SET COUNT = COUNT + 1;

          SET LOCKTIMEOUT_HAPPENED = 1;

          IF (COUNT >= $retries) THEN
          BEGIN
              SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;

              RESIGNAL SQLSTATE '$ERROR_RESOURCE_BUSY'
                 SET MESSAGE_TEXT = 'ERROR_RESOURCE_BUSY';
          END;
          END IF;
      END;

      SET LOCKTIMEOUT_HAPPENED = 0;

      IF (mdsGuid IS NOT NULL) THEN 
        SELECT path_docid INTO tmpDocID
          FROM MDS_PATHS
          WHERE path_guid = mdsGuid
                AND path_high_cn IS NULL 
                AND path_partition_id = partitionID
                AND path_type = '$TYPE_DOCUMENT'
          FOR UPDATE;
      ELSE
        SELECT path_docid INTO tmpDocID
            FROM MDS_PATHS
            WHERE path_fullname = fullPathName
                  AND path_high_cn IS NULL
                  AND path_partition_id = partitionID
                  AND path_type = '$TYPE_DOCUMENT'
            FOR UPDATE;
      END IF;
    END;

      UNTIL LOCKTIMEOUT_HAPPENED = 0
    END REPEAT LOCK_RETRIES;

    -- Restore lock timeout.
    SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;
END
/


--
-- Insert the sequence into MDS_SEQUENCES table.  If the row is there,
-- update its value with new seed number.
--
-- Parameters:
--   seqName  -  Sequence Name.
--   seed     -  seed number.
--
drop procedure if exists mds_createSequence
/

create PROCEDURE mds_createSequence(seqName       VARCHAR($SEQ_NAME),
                                    seed          BIGINT)
LANGUAGE SQL

BEGIN  

  -- Replace possible ";" with "_" to avoid SQL injection.
  SET seqName = REPLACE(seqName, ';', '_');

  SET @sql = CONCAT('CREATE TABLE IF NOT EXISTS ', seqName, 
                    '(ID BIGINT NOT NULL AUTO_INCREMENT UNIQUE) engine=innodb');

  PREPARE stmt FROM @sql;

  EXECUTE stmt;

  DEALLOCATE PREPARE stmt;

  -- Auto increment value has to be set seperately for MySQL.
  SET @seedStr = CAST(seed as CHAR);

  SET @sql = CONCAT('ALTER TABLE ', seqName, ' AUTO_INCREMENT=', @seedStr); 

  PREPARE stmt FROM @sql; 

  EXECUTE stmt;

  DEALLOCATE PREPARE stmt;
  
END
/

--
-- Get the next sequence number.  
--
-- Parameters:
--   setNumber OUTPUT - Sequence Number.
--   seqName          -  Sequence Name.
--

drop procedure if exists mds_getNextSequence
/

create PROCEDURE mds_getNextSequence(OUT seqNumber    BIGINT,
                                         seqName      VARCHAR($SEQ_NAME))
LANGUAGE SQL

getNextSeq:BEGIN  
  DECLARE seqNo   BIGINT;
  DECLARE locked  SMALLINT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
      IF locked = 1 THEN
          SELECT RELEASE_LOCK(seqName);
      END IF;

      RESIGNAL;
  END;

  -- Replace possible ";" with "_" to avoid possible sql injection.
  SET seqName = REPLACE(seqName, ';', '_');

  SELECT count(*) INTO @cnt 
      FROM information_schema.tables
      WHERE table_schema = schema() AND table_name = seqName; 

  IF @cnt = 0 THEN
  BEGIN
      -- Acquire application lock
      SELECT GET_LOCK(seqName, 9999999999) INTO @lock;

      SET locked = 1;

      -- Query again to make sure no one added it.
      SELECT count(*) INTO @cnt 
          FROM information_schema.tables
          WHERE table_schema = schema() AND table_name = seqName; 

      IF @cnt = 0 THEN
          SET @sql = CONCAT('CREATE TABLE IF NOT EXISTS ',
                    seqName, '(ID BIGINT UNIQUE NOT NULL AUTO_INCREMENT)');

          PREPARE stmt FROM @sql;

          EXECUTE stmt; 

          DEALLOCATE PREPARE stmt;
      END IF;

      SELECT RELEASE_LOCK(seqName);
      SET locked = 0;
  END;
  END IF;

  SET @sql = CONCAT('INSERT INTO ', seqName, ' VALUES(NULL)');

  PREPARE stmt FROM @sql;

  EXECUTE stmt; 

  DEALLOCATE PREPARE stmt;

  -- Get the last identity that is used to insert into the table.
  SET seqNumber = LAST_INSERT_ID();

  -- We don't want the table piled up with a lot of records.  
  -- We need to leave some rows in the table, so the auto ID won't
  -- be re-seed if database is restarted.  We also shold avoid trying to 
  -- delete rows that are just added by others in their uncommited txn 
  -- to avoid lock waiting.
  SET @purgeSeqNo = seqNumber - 100000;

  -- Check to see if there is a need to prone old table values.
  IF ( MOD(seqNumber,1000) <> 0 OR
        @purgeSeqNo < 1 ) THEN
     LEAVE getNextSeq;
  END IF;


  SET @sql = CONCAT('DELETE FROM ', seqName, ' WHERE ID < ?');

  PREPARE stmt FROM @sql;

  EXECUTE stmt USING @purgeSeqNo; 

  DEALLOCATE PREPARE stmt;

END
/


--
-- Get the doc sequence name.  
--
-- Parameters:
--   partitionID        - Partition Number.
-- Returns:
--   the name of sequence. 

drop function if exists mds_getDocSequenceName
/

create FUNCTION mds_getDocSequenceName(partitionID  INT) 
      RETURNS VARCHAR($SEQ_NAME)
LANGUAGE SQL
DETERMINISTIC
CONTAINS SQL
BEGIN  
  DECLARE strID      VARCHAR(50);
  DECLARE sqlName    VARCHAR($SEQ_NAME);

  SET strID = CASE 
                 WHEN partitionID IS NULL THEN '' 
                 WHEN partitionID < 0 THEN CONCAT('n', CAST(ABS(partitionID) as CHAR))
                 ELSE CAST(partitionID as CHAR) 
              END;
  SET sqlName = CONCAT('MDS_SEQUENCE_DOC_ID_', strID);

  RETURN sqlName;
END
/


--
-- Get the content sequence name.  
--
-- Parameters:
--   partitionID        - Partition Number.
-- Returns:
--   the name of sequence. 

drop function if exists mds_getContentSequenceName
/

create FUNCTION mds_getContentSequenceName(partitionID INT) 
      RETURNS VARCHAR($SEQ_NAME)
LANGUAGE SQL
DETERMINISTIC
CONTAINS SQL
BEGIN  
  DECLARE strID      VARCHAR(50);
  DECLARE sqlName    VARCHAR($SEQ_NAME);

  SET strID = CASE 
                 WHEN partitionID IS NULL THEN '' 
                 WHEN partitionID < 0 THEN CONCAT('n', CAST(ABS(partitionID) as CHAR))
                 ELSE CAST(partitionID as CHAR) 
              END;

  SET sqlName = CONCAT('MDS_SEQUENCE_CONTENT_ID_', strID);

  RETURN sqlName;
END
/


--
-- Get the Lineage sequence name.  
--
-- Parameters:
--   partitionID        - Partition Number.
-- Returns:
--   the name of sequence. 

drop function if exists mds_getLineageSequenceName
/

create FUNCTION mds_getLineageSequenceName(partitionID INT)
      RETURNS VARCHAR($SEQ_NAME)
LANGUAGE SQL
DETERMINISTIC
CONTAINS SQL
BEGIN
  DECLARE strID      VARCHAR(50);
  DECLARE sqlName    VARCHAR($SEQ_NAME);

  SET strID = CASE
                 WHEN partitionID IS NULL THEN ''
                 WHEN partitionID < 0 THEN CONCAT('n', CAST(ABS(partitionID) as CHAR))
                 ELSE CAST(partitionID as CHAR)
              END;

  SET sqlName = CONCAT('MDS_SEQUENCE_LINEAGE_ID_', strID);

  RETURN sqlName;
END
/


--
-- Drop Sequence from sequence table.
--
-- Parameters:
--   seqName     - Sequence Name
--
drop procedure if exists mds_dropSequence
/

create PROCEDURE mds_dropSequence(seqName  VARCHAR($SEQ_NAME))
LANGUAGE SQL
BEGIN

  SET @sql = CONCAT('drop table if exists ', seqName);

  PREPARE stmt1 FROM @sql; 

  EXECUTE stmt1;

  DEALLOCATE PREPARE stmt1;
END
/


--
-- Recreates Document and Content ID sequences with the minimum documentID
-- and contentID set to the values provided as input parameters.
--
-- Parameters:
--   partitionID  -  Partition ID.
--   minDocId     -  Minimum Document ID
--   minContentId -  Minimum Content ID
--
drop procedure if exists mds_recreateSequences
/

create PROCEDURE mds_recreateSequences(partitionID    INT,
                                       minDocId       BIGINT,
                                       minContentId   BIGINT,
                                       minLineageId   BIGINT)
BEGIN
  DECLARE seqName VARCHAR($SEQ_NAME);

  SET seqName = mds_getDocSequenceName(partitionID);
  CALL mds_dropSequence(seqName);
  CALL mds_createSequence(seqName, minDocId);

  SET seqName = mds_getContentSequenceName(partitionID);
  CALL mds_dropSequence(seqName);
  CALL mds_createSequence(seqName,minContentId);

  SET seqName = mds_getLineageSequenceName(partitionID); 
  CALL mds_dropSequence(seqName);
  CALL mds_createSequence(seqName, minLineageId);
        
END
/


--
-- Drops the Document and Content ID sequences for the given
-- partitionID
--
-- Parameters:
--   partitionID  -  Partition ID.
--

drop procedure if exists mds_dropSequences
/

create PROCEDURE mds_dropSequences(partitionID   INT)
LANGUAGE SQL
BEGIN
  DECLARE seqName VARCHAR($SEQ_NAME);

  SET seqName = mds_getDocSequenceName(partitionID);
  CALL mds_dropSequence(seqName);

  SET seqName = mds_getContentSequenceName(partitionID);
  CALL mds_dropSequence(seqName);

  SET seqName = mds_getLineageSequenceName(partitionID); 
  CALL mds_dropSequence(seqName);
END
/

-- Checks if the specified doucment has been concurrently
-- updated/deleted/renamed after the transaction represented by lowCN,
-- raises ERROR_CONFLICTING_CHANGE if so.
--
-- Parameters:
--   docID        -  PATH_DOCID of the document to be verified
--   fullPathName -  Fully qualified MDS name of the document
--   lowCN        -  PATH_LOW_CN beyond which the updates are to be checked
--                   This is the commit number with which the document was
--                   being saved was obtained.
--   version      -  Version of the document being saved/deleted. 
--   partitionID  -  Parition ID in which the document exists.

drop procedure if exists mds_doConcurrencyCheck
/


create procedure mds_doConcurrencyCheck (docID          BIGINT, 
                                         fullPathName   VARCHAR($FULLNAME), 
                                         lowCN          BIGINT, 
                                         curVersion     INT, 
                                         partitionID    INT)
LANGUAGE SQL

BEGIN
    
    DECLARE pDocID BIGINT;
    
    DECLARE verToCheck INT;

    DECLARE P_LOCK_TIMEOUT   INT DEFAULT -1;

    DECLARE COUNT    SMALLINT DEFAULT 0;

    DECLARE LOCKTIMEOUT_HAPPENED SMALLINT DEFAULT 0;

    -- Continue handler for all other exceptions;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;

        RESIGNAL;
    END;

    -- Save curent lock timeout
    SET P_LOCK_TIMEOUT = @@INNODB_LOCK_WAIT_TIMEOUT;

    SET @@INNODB_LOCK_WAIT_TIMEOUT = $lcktimeout;

    -- Check if no row exists which has a highCN set for the MDS_PATHS
    -- row with PATH_LOW_CN value of what was grabbed when getDocument was done.
    -- If there is such a row, that means a concurrent operation is being
    -- attempted.
    -- We have to find the high_cn of row having matching low cn and
    -- VERSION = current Version (not with just any row that matches the
    -- low_cn) because of the  following scenario.
    -- path_fullname path_low_cn   path_high_cn path_version path_op
    -- /foo          1             1            1            Create
    -- /foo1         10            10           2            Rename
    -- /foo1         10                         3            Save
    -- As this case shows, we should not take the high_cn as 10 but null.
    -- This is a workaround till the versions with the same low_cn and high_cn
    -- are avoided (by not creating a new version if one already exists with
    -- low_cn=-1) and should be removed once this problem is fixed
    -- TODO: Remove this IF block when repos upgrade is feasible

    LOCK_RETRIES:
    REPEAT
    BEGIN
      DECLARE EXIT HANDLER FOR NOT FOUND 
      BEGIN
          RESIGNAL SQLSTATE '$ERROR_CONFLICTING_CHANGE' 
                   SET MESSAGE_TEXT = 'ERROR_CONFLICTING_CHANGE';
      END;

      -- Continue handler for lock timeout and deadlock;
      DECLARE CONTINUE HANDLER FOR 1205,1213
      BEGIN
          SET COUNT = COUNT + 1;

          SET LOCKTIMEOUT_HAPPENED = 1;

          IF (COUNT >= $retries) THEN
          BEGIN
              RESIGNAL SQLSTATE '$ERROR_RESOURCE_BUSY'
                   SET MESSAGE_TEXT = 'ERROR_RESOURCE_BUSY';
          END;
          END IF;
      END;

      SET LOCKTIMEOUT_HAPPENED = 0;

      IF (curVersion = -1) THEN 
        SELECT MAX(path_version) INTO verToCheck FROM MDS_PATHS
            WHERE path_docid = docID AND path_low_cn=lowCN
                  AND path_partition_id = partitionID;

        SELECT path_docid INTO pDocID FROM MDS_PATHS
            WHERE path_docid = docID AND path_high_cn IS NULL  
                  AND path_partition_id = partitionID
                  AND NOT EXISTS (
          SELECT path_docid FROM MDS_PATHS
              WHERE (path_docid = docID OR path_fullname =fullPathName)
              -- Checking highCN is sufficient as it will be populated both when
              -- a new version is created (due to save/rename) or when current version
              -- is deleted. path_high_cn with value -1 are ignored since they were
              -- changes in the same transaction
              AND ( path_low_cn = lowCN
              AND ( path_high_cn IS NOT NULL AND path_high_cn <> $INTXN_CN ))
              -- This condition on maxVer used for the workaround described above
              -- should be removed once the temporary versions are avoided
              AND (path_version = verToCheck)
              AND path_partition_id = partitionID)
         FOR UPDATE;
      ELSE
      BEGIN

          -- Attempting to lock the current version conditional to NULL highCN
          -- is sufficient as it will be populated both when a newer version 
          -- is created (due to save/rename) or when current version
          -- is deleted. A no data found exception indicates concurrency
          SELECT path_docid INTO pDocID FROM MDS_PATHS
            WHERE path_docid = docID AND 
                path_version = curVersion AND 
                path_partition_id = partitionID AND 
                path_high_cn IS NULL 
            FOR UPDATE;
      END;
      END IF;
    END;

      UNTIL LOCKTIMEOUT_HAPPENED = 0
    END REPEAT LOCK_RETRIES;

    SET @@INNODB_LOCK_WAIT_TIMEOUT = P_LOCK_TIMEOUT;
END
/



--
-- Generates a unique(within the repository partition) commit number(CN) for
-- the transaction
-- Parameters
--     commitNumber Generated Commit Number.
--     partitionID PartitionID for the repository partition
-- 
drop procedure if exists mds_internal_generateCommitNumber
/

CREATE PROCEDURE mds_internal_generateCommitNumber ( OUT commitNumber   BIGINT, 
                                                         partitionID    INT)
LANGUAGE SQL

BEGIN
    -- Return the next commit number after locking the commit number row so
    -- so that no another transaction can commit parallelly
    INSERT INTO MDS_TXN_LOCKS (LOCK_PARTITION_ID, LOCK_TXN_CN)
        VALUES (partitionID, 1)
        ON DUPLICATE KEY UPDATE LOCK_TXN_CN = LOCK_TXN_CN + 1;

    -- The row is already locked by previous statement.
    SELECT LOCK_TXN_CN INTO commitNumber FROM MDS_TXN_LOCKS 
        WHERE LOCK_PARTITION_ID = partitionID;
END
/



-- Return a list of Path elements that match the given set of patterns.
-- Notes: No more than 400 patterns should be passed in.  Otherwise, 
-- only the first 400 results will be returned. 
--
-- Parameters:
--	results		- A comma seperated list of flags (FOUND/NOT_FOUND).
--	partitionID	- The partition ID where the documents exist.
--	patterns	- List of patterns which will be used to filter the
-- 			  results.The patterns are ordered such that the most 
--			  general pattern is followed my more specific patterns.
--			  This pattern ordering is very important to how documents
--			  are looked up.
--
drop procedure if exists mds_checkDocumentExistence
/

create PROCEDURE mds_checkDocumentExistence(OUT results     VARCHAR(4000),
         	                                partitionID INT,
		                                patterns    VARCHAR(4000)) 
LANGUAGE SQL

checkDocument:BEGIN
  DECLARE found         VARCHAR(10);

  DECLARE startPOS      SMALLINT;
  DECLARE sepPOS        SMALLINT;
  DECLARE len           SMALLINT;
  DECLARE count         SMALLINT;
  DECLARE total_len     SMALLINT;
  DECLARE pattern       VARCHAR(4000);
  DECLARE prev          VARCHAR(10);

  SET patterns = TRIM(COALESCE(patterns,''));

  -- If it is an empty string, return here.
  IF (patterns = '') THEN
      SET results = '';

      LEAVE checkDocument;
  END IF;

  SET startPOS = 1;
  SET sepPOS   = -1;  -- Initialize with non 0 value.
  SET results  = '';
  SET prev     = 'NOT_FOUND';
  SET count    =  0;

  SET total_len = CHAR_LENGTH(patterns);
    
  WHILE (sepPOS <> 0) DO
    SET sepPOS = LOCATE(',', patterns, startPOS);
    
    IF (sepPOS = 0) THEN
      SET len = total_len - startPOS + 1;
    ELSE
      SET len = sepPOS - startPOS;
    END IF;

    SET pattern = SUBSTRING(patterns, startPOS, len);

    -- trim space from both sides
    SET pattern = TRIM(pattern);

    -- #(6416307) This optimization was done to prevent executing queries for
    -- patterns for which no documents would ever be found. The query is executed
    -- for the first pattern in patterns, and subsequent patterns are evaluated for
    -- document matches only if the more general pattern before it resulted
    -- in a successful hit on the database. The ordering in the patterns is very important
    -- since if a more general pattern is not found then there is no need to fire a 
    -- database query. This optimization resulted in significant performance improvement
    -- in PSR tests with a small size PDCache.
    SET found = 'NOT_FOUND';

    BEGIN
        DECLARE CONTINUE HANDLER FOR NOT FOUND
        BEGIN
            SET found = 'NOT_FOUND';
        END;

        IF ( count = 0 OR prev = 'FOUND' ) THEN
            SELECT 'FOUND' INTO found FROM MDS_PATHS
                 WHERE PATH_PARTITION_ID = partitionID
                     AND PATH_TYPE= 'DOCUMENT'
	             AND PATH_FULLNAME like pattern
                     LIMIT 1;
        END IF;
    END;

    -- Append an comma if results already contains values.
    IF (count > 0) THEN
        SET results = CONCAT(results,',');
    END IF;

    SET results = CONCAT(results, found);

    SET prev = found;

    SET count = count + 1;

    -- Try to not overflow the results. (LEN("NOT_FOUND") + 1) * 400 = 4000 characters.
    IF (count >= 400) THEN
        LEAVE checkDocument;
    END IF;

    IF (sepPOS <> 0) THEN   
      -- Shift the position to the right of sepPOS.
      SET startPOS = sepPOS + 1;

      -- If the last character is ",", we will append one "NOT_FOUND" and set setPOS to 0.
      IF (startPOS > total_len) THEN
        -- Add "," and "NOT_FOUND".  We know there is value in results.
        SET results = CONCAT(results, ',', 'NOT_FOUND'); 

        -- To exit in next loop.
        SET sepPOS = 0;   
      END IF;
    END IF;
  END WHILE;
END
/



-- Creates a transaction
--
-- Generates an unique commit number and inserts a new transaction
-- entry into mds_transactions
-- Parameters
--     commitNumber Commit Number.
--     partitionID  PartitionID for the repository partition
--     userName     User whose changes are being commited, can be null.
--
drop procedure if exists mds_createNewTransaction
/

CREATE PROCEDURE mds_createNewTransaction(OUT commitNumber BIGINT, 
                                              partitionID INT, 
                                              username VARCHAR($CREATOR))
LANGUAGE SQL
BEGIN
    -- Call generateCommitNumber()
    CALL mds_internal_generateCommitNumber(commitNumber,partitionID);
    
    -- Record the creator and time information for this transaction
    -- #(5570793) Store the transaction time as UTC so that it can be compared
    -- with mid-tier time correctly when mid-tier and repository are on 
    -- different timezones    
    INSERT INTO MDS_TRANSACTIONS(txn_partition_id, txn_cn, txn_creator, txn_time)
         VALUES (partitionID,commitNumber,username, utc_timestamp());
END 
/


-- Emulate Oracle's NUMTODSINTERVAL function.
-- Parameters
--   n      Value to be converted.
--   unit   Unit for the value
drop function if exists mds_internal_numtodsinterval
/

CREATE FUNCTION mds_internal_numtodsinterval(n    BIGINT, 
                                             unit VARCHAR(60))
RETURNS BIGINT 

LANGUAGE SQL

DETERMINISTIC
CONTAINS SQL

  RETURN n*
    CASE UPPER(unit)
      WHEN 'DAY' THEN 24*3600
      WHEN 'HOUR' THEN 3600
      WHEN 'MINUTE' THEN 60
      ELSE 1
END
/


-- Checks if the purge interval has elapsed since the last_purge_time.
-- If so, returns the current DB time (which will cause a purge to be
-- invoked from java). 
-- It also updates the last_purge_time for the partition if purge interval
-- has elapsed as an optimization to avoid parallel purges.
-- Parameters
--  partitionID       PartitionID for the repository partition
--  autoPurgeInterval Minimum time interval to wait before invoking the next 
--                    autopurge
--  purgeRequired     OUT parameter 1 if purge is required.
--  dbSystimeTime     OUT parameter. DB system time when the last purge occured
--
drop procedure if exists mds_isPurgeRequired
/

CREATE PROCEDURE mds_isPurgeRequired (     partitionID       INT, 
                                           autoPurgeInterval INT, 
                                       OUT purgeRequired     SMALLINT, 
                                       OUT dbSystemTime      TIMESTAMP )
LANGUAGE SQL

BEGIN
    DECLARE systemTime TIMESTAMP;
    DECLARE v_rows     INT DEFAULT 0;
    
    -- Store the system time in a local variable
    -- to remove any inaccuracies in using it in the query below
    -- #(5570793) - Store timestamps always as UTC
    SET systemTime = UTC_TIMESTAMP();
    
    -- #(6351111) As an optimization, the check will also update the
    -- the last_purge_time on the partition
    UPDATE MDS_PARTITIONS 
        SET partition_last_purge_time = systemTime
           WHERE partition_id = partitionID
                AND  (systemTime - partition_last_purge_time) > 
                     (mds_internal_numtodsinterval(autoPurgeInterval, 'SECOND'));

    -- Check if any row changed.  ROW_COUNT() is a system function.
    SELECT ROW_COUNT() into v_rows;

    IF ( v_rows > 0 ) THEN
        SET purgeRequired = 1;
    ELSE
        SET purgeRequired = 0;
    END IF;

    SET dbSystemTime = systemTime;
END
/


--
-- Delete the pacakge.
--
-- Parameters:
--   execResult   - -1 if the package was not deleted because it contained
--                  documents or sub packages, 0 if the package is
--                  successfully deleted.
--   partitionID  - the partition where the package exists.
--   pathID       - ID of the package to delete
--
drop procedure if exists mds_deletePackage
/

CREATE PROCEDURE mds_deletePackage (OUT result      SMALLINT, 
                                        partitionID INT, 
                                        pathID      BIGINT)
LANGUAGE SQL

BEGIN
    
    DECLARE childCount INT;
    
    SET result = 0;
    
    -- Check if the package is empty, otherwise it should not be deleted
    SELECT COUNT(*) INTO childCount FROM MDS_PATHS 
        WHERE path_owner_docid = pathID AND path_high_cn IS NULL
              AND path_partition_id = partitionID;

    IF (childCount = 0) THEN 
         UPDATE MDS_PATHS SET path_high_cn=$INTXN_CN, 
                              path_operation=$DELETE_OP
             WHERE path_docid = pathId
                   AND path_type = '$TYPE_PACKAGE'
                   AND path_high_cn IS NULL
                   AND path_partition_id = partitionID ;

    ELSE
        SET result = -1;
    END IF;
END
/

--
-- Purges document versions from the base tables, i.e, mds_paths,
-- mds_dependencies, mds_streamed_docs.
-- Only those document versions which are in sessions.mds_purge_paths,
-- which are not labeled and are not the tip versions are  purged.
--
-- Parameters
--  partitionID       - PartitionID for the repository partition
--

drop procedure if exists mds_internal_purgeMetadata2
/


CREATE PROCEDURE mds_internal_purgeMetadata2 ( partitionID   INT)
LANGUAGE SQL

BEGIN
    DECLARE docID      BIGINT;

    DECLARE version    INT;

    DECLARE C_STMTSTR VARCHAR(512) DEFAULT '';

    DECLARE SQLCODE INTEGER DEFAULT 0;

    DECLARE C_FOUND INTEGER DEFAULT 0;

    -- Delete paths
    DECLARE c CURSOR FOR SELECT PATH_DOCID, PATH_VERSION FROM MDS_PATHS 
                     WHERE PATH_PARTITION_ID=partitionID AND 
                     EXISTS (SELECT 1 FROM MDS_PURGE_PATHS 
                     WHERE path_low_cn = ppath_low_cn AND 
                     path_high_cn = ppath_high_cn AND 
                     path_partition_id = ppath_partition_id);
    
    -- Handler exception for no data deleted with DELETE command.
    DECLARE CONTINUE HANDLER FOR NOT FOUND 
    BEGIN 
    END;

    OPEN c;

    BEGIN
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET C_FOUND = 0;

        SET C_FOUND = 1;
        FETCH FROM c INTO docID, version;

        WHILE C_FOUND = 1 DO
          DELETE FROM MDS_PATHS 
              WHERE PATH_PARTITION_ID = partitionID AND
                    PATH_DOCID = docID AND
                    PATH_VERSION = version;

          SET C_FOUND = 1;
          FETCH FROM c INTO docID, version;
        END WHILE;
    END;

    CLOSE c;

    -- To avoid purging shared content, remove any purge row still whose content
    -- is still referenced by MDS_PATHS
    DELETE FROM MDS_PURGE_PATHS WHERE ppath_partition_id = partitionID AND
      ppath_contentid IN 
        (SELECT path_contentid FROM MDS_PATHS WHERE
           path_partition_id = partitionID);
    
    -- Delete streamed contents if any
    DELETE  FROM MDS_STREAMED_DOCS WHERE sd_partition_id = partitionID
      AND sd_contentid IN
      (SELECT ppath_contentid FROM MDS_PURGE_PATHS
         WHERE ppath_partition_id = partitionID);
    
    -- Delete dependencies if any
    DELETE FROM MDS_DEPENDENCIES WHERE dep_low_cn IN
      (SELECT ppath_low_cn FROM MDS_PURGE_PATHS
         WHERE ppath_partition_id = partitionID);    
      
    -- Delete the components first, since reading contents
    -- does an outer join from components to attributes. We
    -- want to acquire our locks in the same order.

    -- Delete components of the purged versions.
    DELETE FROM MDS_COMPONENTS
          WHERE comp_partition_id = partitionID
                AND comp_contentid IN
                (SELECT ppath_contentid
                      FROM MDS_PURGE_PATHS 
                         WHERE ppath_partition_id = partitionID);

    -- Delete attributes of the purged versions.
    DELETE  FROM MDS_ATTRIBUTES 
         WHERE att_partition_id = partitionid
                AND att_contentid IN
                 (SELECT ppath_contentid
                      FROM MDS_PURGE_PATHS 
                         WHERE ppath_partition_id = partitionID);

END
/


--
-- Purges document versions from the base tables, i.e, mds_paths, 
-- mds_dependencies, mds_streamed_docs. 
-- Only those document versions which were created older than secondsToLive, 
-- which are not labeled and are not the tip versions are  purged.
--
-- Parameters  
--  numVersionsPurged - Out parameter indicating number of versions purged
--  partitionID       - PartitionID for the repository partition
--  purgeCompareTime  - Creation time prior to which versions can be purged
--  secondsToLive     - Versions older than this time to be purged  
--  isAutoPurge       - 0 if manual purge and 1 if auto-purge
--  commitNumber      - Commit number used for purging path and content tables
--

drop procedure if exists mds_internal_purgeMetadata
/

CREATE PROCEDURE mds_internal_purgeMetadata (OUT numVersionsPurged INT, 
                                                 partitionID       BIGINT, 
                                                 purgeCompareTime  TIMESTAMP, 
                                                 secondsToLive     INT, 
                                                 isAutoPurge       SMALLINT, 
                                                 commitNumber      BIGINT )

LANGUAGE SQL

purgeMetadata:BEGIN
    DECLARE content_id      BIGINT;

    DECLARE lowCN           BIGINT;

    DECLARE highCN          BIGINT;

    DECLARE p_lowCN         BIGINT;

    DECLARE numVersionsPurgeThisTime INT;

    DECLARE C_FOUND         SMALLINT DEFAULT 0;

    DECLARE c CURSOR FOR SELECT path_contentid, path_low_cn, path_high_cn FROM MDS_PATHS
                    WHERE path_low_cn <= commitNumber 
                    AND path_low_cn > 0     
                    AND NOT EXISTS               
                    (SELECT label_cn from MDS_LABELS
                        WHERE path_low_cn <= label_cn 
                        AND (path_high_cn > label_cn OR path_high_cn IS NULL) 
                        AND label_partition_id = path_partition_id) 
                    AND path_high_cn IS NOT NULL 
                    -- #(11709515) Sandbox apply needs older versions and since sandbox
                    -- destroy deletes all sandbox content, no need to purge sandbox documents
                    AND path_fullname NOT LIKE '/mdssys/sandbox/%' -- Exclude Sandboxes
                    AND path_partition_id = partitionID ORDER BY path_low_cn;


    -- Handler exception for no data deleted with DELETE command.
    DECLARE CONTINUE HANDLER FOR NOT FOUND 
    BEGIN
    END;

    SET numVersionsPurged = 0;

    SET p_lowCN = 0;

    OPEN c;

    SET numVersionsPurgeThisTime = 0;

    SET C_FOUND = 1;

    FETCH FROM c INTO content_id, lowCN, highCN;

    WHILE C_FOUND = 1 DO
    BEGIN
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET C_FOUND = 0;
        -- We only do purge if there are more than 300 file to be purged and
        -- all fileis with same locCN are included.
        IF (numVersionsPurgeThisTime >= 300 AND
            p_lowCN <> lowCN ) THEN

            SET numVersionsPurged = numVersionsPurged + numVersionsPurgeThisTime;
        
            CALL mds_internal_purgeMetadata2(partitionID);

            -- clean up session.mds_purge_paths for next time.
            DELETE FROM MDS_PURGE_PATHS;

            -- Commit the change for each loop.   
            COMMIT;

            -- Reset numVersionsPurgeThisTime
            SET numVersionsPurgeThisTime = 0;
        END IF;

        -- #(6838583) Populate the mds_purge_data with details of versions that
        -- qualify for purge
        INSERT INTO MDS_PURGE_PATHS
            (ppath_contentid, ppath_low_cn, ppath_high_cn, ppath_partition_id)
         VALUES(content_id, lowCN, highCN, partitionID);

        SET numVersionsPurgeThisTime = numVersionsPurgeThisTime + 1;

        SET p_lowCN      = lowCN;

        SET C_FOUND = 1;

        FETCH FROM c INTO content_id, lowCN, highCN;
    END;
    END WHILE;

    CLOSE c;

    -- Check to see if any thing left needs to be purged.
    IF (numVersionsPurgeThisTime > 0) THEN 
        
       SET numVersionsPurged = numVersionsPurged + numVersionsPurgeThisTime;

       CALL mds_internal_purgeMetadata2(partitionID);

       -- clean up session.mds_purge_paths for next time.
       DELETE FROM MDS_PURGE_PATHS;

       -- Commit the change.   
       COMMIT;
    END IF;

    -- #(7038905) Delete any unused transaction rows
    DELETE FROM MDS_TRANSACTIONS WHERE txn_partition_id=partitionID
      AND NOT EXISTS (SELECT 'x' FROM MDS_PATHS
                      WHERE path_partition_id = partitionID
                      AND path_low_cn=txn_cn)
      AND NOT EXISTS (SELECT 'x' FROM MDS_PATHS
                      WHERE path_partition_id = partitionID
                      AND path_high_cn IS NOT NULL AND path_high_cn = txn_cn)
      -- #(8637322) Don't purge mds_txn rows used by labels
      AND NOT EXISTS (SELECT 'x' FROM MDS_LABELS
                      WHERE label_partition_id = partitionID
                      AND label_cn = txn_cn);

    -- Content tables are purged in mds_internal_shredded.purgeMetadata()
    -- or mds_internal_xdb.purgeMetadata() from which this procedure is called
    -- Update the purgeTime if it manual purge, for auto-purge it is updated
    -- in processCommit() itself.
    IF (isAutoPurge = 0) THEN

        UPDATE MDS_PARTITIONS SET partition_last_purge_time = UTC_TIMESTAMP 
              WHERE partition_id = partitionID;
    END IF;
   
    COMMIT;

END
/




--
-- Retrieves the document id for the specified fully qualified path name.
-- The pathname must begin with a '/' and should look something like:
--   /mypkg/mysubpkg/mydocument
--
-- Parameters:
--   docID         - OUTPUT.The ID of the path or -1 if no such path exists
--   partitionID   - the partition where the document exists
--   fullPathName  - the fully qualified name of the document
--   pathType      - the type of the document, either 'DOCUMENT' or 'PACKAGE'
--                   if no type is specified, and there happens to be a path
--                   of both 'DOCUMENT' and 'PACKAGE' (which is unlikely),
--                   then the id of the DOCUMENT will be returned
--

drop function if exists mds_getDocumentID
/

CREATE FUNCTION mds_getDocumentID( partitionID     INT, 
                                   fullPathName    VARCHAR($FULLNAME), 
                                   pathType        VARCHAR($PATH_TYPE))                                  
RETURNS BIGINT
LANGUAGE SQL

BEGIN
    DECLARE fullPath VARCHAR($FULLNAME);
    DECLARE docID    BIGINT;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND 
    BEGIN
        SET docID = -1;
    END;

    SET docID = -1;
    SET fullPath = fullPathName;
    
    -- #(3234805) If the document does not start with a forward slash,
    -- then it's an invalid document name
    IF (LOCATE('/', fullPathName, 1) <> 1) THEN 
        RETURN docID;
    END IF;
        
    IF ((fullPathName) = '/')
          AND ((pathType IS NULL)
             OR (pathType = '$TYPE_PACKAGE')) THEN 

        SET docID = $ROOT_DOCID;

        RETURN docID;
    END IF;
        
    IF (LOCATE('/', fullPath, CHAR_LENGTH(fullPath)) > 0) THEN 
        SET fullPath = SUBSTRING(fullPath, 1, CHAR_LENGTH(fullPath) - 1);
    END IF;
        
    IF (pathType IS NULL ) THEN
        SELECT path_docid INTO docID
            FROM MDS_PATHS
            WHERE path_fullname = fullPath
                  AND path_partition_id = partitionID
                  AND path_high_cn IS NULL;
    ELSE
        SELECT path_docid INTO docID
            FROM MDS_PATHS 
            WHERE path_fullname = fullPath
                  AND path_type = pathType
                  AND path_high_cn IS NULL
                  AND path_partition_id = partitionID;
    END IF;    

    RETURN docID;
END
/

--
-- Retrieves the document id for the specified fully qualified path name
-- and GUID. The pathname must begin with a '/' and should look something like
--   /mypkg/mysubpkg/mydocument
--
-- Parameters:
--   docID         - OUTPUT.The ID of the path or -1 if no such path exists
--   partitionID   - the partition where the document exists
--   fullPathName  - the fully qualified name of the document
--   mdsGuid	     - the GUID of the document
--   pathType      - the type of the document, either 'DOCUMENT' or 'PACKAGE'
--                   if no type is specified, and there happens to be a path
--                   of both 'DOCUMENT' and 'PACKAGE' (which is unlikely),
--                   then the id of the DOCUMENT will be returned
--

drop function if exists mds_getDocumentIDByGUID
/

CREATE FUNCTION mds_getDocumentIDByGUID (partitionID  INT, 
                                          fullPathName VARCHAR($FULLNAME), 
                                          mdsGuid      VARCHAR($GUID), 
                                          pathType     VARCHAR($PATH_TYPE)) 
RETURNS BIGINT 
LANGUAGE SQL

BEGIN
    DECLARE fullPath VARCHAR($FULLNAME);
    DECLARE bindVar  SMALLINT;
    DECLARE docID    BIGINT;

    DECLARE CONTINUE HANDLER FOR NOT FOUND 
    BEGIN
        SET docID = -1;
    END;

    SET docID    = -1;
    SET bindVar  = 2;
    SET fullPath = fullPathName;
        
    -- fullpath and/or mdsGuid must be non-null
    IF mdsGuid IS NULL THEN
        RETURN docID;
    END IF;
        
    -- #(3234805) If the document does not start with a forward slash,
    -- then it's an invalid document name
    IF (fullPathName IS NOT NULL
            AND LOCATE('/', fullPathName, 1) <> 1) THEN 
        RETURN docID;
    END IF;
        
    IF ((fullPathName IS NOT NULL AND fullPathName = '/')
         AND ((pathType IS NULL) OR (pathType = '$TYPE_PACKAGE'))) THEN
        SET docID = $ROOT_DOCID;

        RETURN docID;
    END IF;
        
    -- #(3403125) Remove the trailing forward slash
    IF (fullPath IS NOT NULL
            AND LOCATE('/', fullPath, CHAR_LENGTH(fullPath)) > 0) THEN 
        SET fullPath = SUBSTRING(fullPath, 1, CHAR_LENGTH(fullPath) - 1);
    END IF;
        
    IF (fullPath IS NOT NULL
            AND CHAR_LENGTH(fullPath) > 0) THEN 
        SET bindVar = bindVar + 1;
    END IF;
        
    IF (pathType IS NOT NULL
            AND CHAR_LENGTH(pathType) > 0) THEN 
        SET bindVar = bindVar + 1;
    END IF;
        
    IF (bindVar = 2) THEN    
        SELECT IFNULL(path_docid,-1) INTO docID FROM MDS_PATHS WHERE path_guid = mdsGuid 
                   AND path_partition_id = partitionID AND path_high_cn IS NULL;
    ELSEIF (bindVar = 3 AND fullPath IS NOT NULL) THEN
        SELECT IFNULL(path_docid,-1) INTO docID FROM MDS_PATHS WHERE path_guid = mdsGuid 
                   AND path_partition_id = partitionID AND path_high_cn IS NULL AND path_fullname = fullPath;
    ELSEIF (bindVar = 3 AND pathType IS NOT NULL) THEN
        SELECT IFNULL(path_docid,-1) INTO docID FROM MDS_PATHS WHERE path_guid = mdsGuid 
                   AND path_partition_id = partitionID AND path_high_cn IS NULL AND path_type = pathType;
        
    ELSEIF (bindVar =4) THEN
        SELECT IFNULL(path_docid,-1) INTO docID FROM MDS_PATHS WHERE path_guid = mdsGuid 
                   AND path_partition_id = partitionID AND path_high_cn IS NULL 
                   AND path_fullname = fullPath AND path_type = pathType;
    END IF;

    RETURN docID;
END
/

--
-- Retrieves the document id for the specified attributes.  This is
-- typically used when attempting to find the id of a path which is
-- owned by a package document.
--
-- Note that this will return the docID which matches the specified
-- name, ownerID and docType.
--
-- Parameters:
--   docID         - OUTPUT.The ID of the path or -1 if no such path exists
--   partitionID   - the partition where the document exists
--   name          - the name of the document (not fully qualified)
--   ownerID       - the ID of the owning package
--   docType       - either 'DOCUMENT' or 'PACKAGE'
--

drop function if exists mds_internal_getDocumentIDByOwnerID
/

CREATE FUNCTION mds_internal_getDocumentIDByOwnerID ( partitionID INT, 
                                                      name        VARCHAR($PATH_NAME), 
                                                      ownerID     BIGINT, 
                                                      docType     VARCHAR($PATH_TYPE)) 
RETURNS BIGINT 
LANGUAGE SQL

BEGIN
    DECLARE docID    BIGINT;

    DECLARE EXIT HANDLER FOR NOT FOUND 
    BEGIN
        SET docID = -1;
    END;

    -- Find the docid for the specified attributes
    SELECT  path_docid INTO docid
        FROM MDS_PATHS 
        WHERE path_name = name AND
               path_owner_docid = ownerID AND
               path_type = docType AND
               path_high_cn IS NULL AND
               path_partition_id = partitionID;

    RETURN docID;
END
/

--
-- For each document name, retrieve the corresponding document ID.
-- The document ID for docs[i] is in docIDs[i].  If no documentID
-- exists for a docs[i], then docIDs[i] = -1.
--

drop procedure if exists mds_getDocumentIDs
/

create PROCEDURE mds_getDocumentIDs(    partitionID     INT,
                                        docs            VARCHAR(4000),
                                    OUT docIDs          VARCHAR(4000))
LANGUAGE SQL

BEGIN
  DECLARE startPOS     SMALLINT;
  DECLARE sepPOS       SMALLINT;
  DECLARE len          SMALLINT;
  DECLARE docID        BIGINT;
  DECLARE fullName     VARCHAR($FULLNAME);

  SET startPOS = 1;
  SET sepPOS   = -1;  -- Initialize with non 0 value.
  SET docIDs   = '';
    
  WHILE(sepPOS <> 0) DO
    SET sepPOS = LOCATE(',', docs, startPOS);
    
    IF (sepPOS = 0) THEN
      SET len = CHAR_LENGTH(docs) - startPOS + 1;
    ELSE
      SET len = sepPOS - startPOS;
    END IF;

    SET fullName = SUBSTRING(docs, startPOS, len);

    SET docID = mds_getDocumentID(partitionID, fullName, '$TYPE_DOCUMENT');

    -- Add the ID to docIDs.
    IF (startPOS > 1) THEN
      SET docIDs = concat(docIDs, ',');
    END IF;

    SET docIDs = CONCAT(docIDs, CAST(docID AS SIGNED));
      
    -- Shift the position to the right of @sepPOS.
    IF (sepPOS <> 0) THEN
      SET startPOS = sepPOS + 1;
    END IF;
  END WHILE;
END
/

-- Given the document id, find the fully qualified document name
--
-- Parameters:
--   partitionID   - the partition where the document exists
--   docID         - the ID of the document
--
-- Returns:
--   the fully qualified document name
--

drop function if exists mds_getDocumentName
/

CREATE FUNCTION mds_getDocumentName (partitionID INT, 
                                     docid       BIGINT )
RETURNS VARCHAR($PATH_NAME)
LANGUAGE SQL
DETERMINISTIC
READS SQL DATA

BEGIN
    
    DECLARE name VARCHAR($FULLNAME) DEFAULT NULL;
    
    SELECT path_fullname INTO name
          FROM MDS_PATHS 
          WHERE path_docid = docid
                AND path_partition_id = partitionID
                AND path_high_cn IS NULL LIMIT 1;
    
    RETURN name;
END
/

--
-- Helper procedure for Shredded DB/XDB specific deletePartition procedures. 
-- NOTE : This package procedure contains code common to both Shredded DB
-- and XDB, and it should NOT be directly called from Java code. Instead, it  
-- is internally consumed by the deletePartition procedures specifically
-- implemented for Shredded DB and XDB. This procedure have to be made public
-- as Shredded DB/XDB specific deletePartition procedures should invoke this
-- procedure internally
--
-- Parameters:
--   partitionID - Partition Id.

drop procedure if exists mds_internal_deletePartition
/

create PROCEDURE mds_internal_deletePartition(partitionID  INT)
LANGUAGE SQL
BEGIN
  DECLARE nameSeq         VARCHAR($SEQ_NAME);

  DELETE FROM MDS_PARTITIONS where PARTITION_ID = partitionID;
  DELETE FROM MDS_PATHS where PATH_PARTITION_ID = partitionID;
  DELETE FROM MDS_DEPENDENCIES where DEP_PARTITION_ID = partitionID;
  DELETE FROM MDS_STREAMED_DOCS where SD_PARTITION_ID = partitionID;

  DELETE FROM MDS_TRANSACTIONS where TXN_PARTITION_ID = partitionID;
  DELETE FROM MDS_TXN_LOCKS where LOCK_PARTITION_ID = partitionID;
  DELETE FROM MDS_SANDBOXES where SB_PARTITION_ID = partitionID;
  DELETE FROM MDS_LABELS where LABEL_PARTITION_ID = partitionID;  
  DELETE FROM MDS_DEPL_LINEAGES WHERE DL_PARTITION_ID = partitionID;

  CALL mds_dropSequences(partitionID);

END
/


--
-- Create the partition.  If the partition is created
-- successfully, it cannot be rolled back by the parent transaction. The user has
-- to use deletePartition procedure to delete the partition.
--
-- Parameters:
--   partitionID       - OUT param, partition ID of the created partition
--   partitionExists   - OUT param, value to indicate if the partition already 
--                       existed.
--   partitionName     - Name of the Repository partition.
--
drop procedure if exists mds_internal_createPartition
/

CREATE PROCEDURE mds_internal_createPartition( OUT partitionID     INT, 
                                               OUT partitionExists INT, 
                                                   partitionName   VARCHAR($PARTITION_NAME))
LANGUAGE SQL

BEGIN
    
    DECLARE createSeqStmt VARCHAR(256);
    DECLARE dropSeqStmt VARCHAR(256);

    -- Unique Key violation exception.
    DECLARE EXIT HANDLER FOR 1062 
    BEGIN
        -- #(7442627) Partition exists already (possibly because of
        -- a request from another thread), delete the sequences
        -- created and let the caller know it already exists
        CALL mds_dropSequences(partitionID);
        
        -- #(9233460) Get correct partitionID of the newly created partition.
        SELECT partition_id INTO partitionID FROM MDS_PARTITIONS 
           WHERE partition_name = partitionName;

        SET partitionExists = $INT_TRUE;
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING, NOT FOUND
    BEGIN
      -- If exception happened, we will try to delete created
      -- sequences since the transaction will not be committed.

      CALL mds_dropSequences(partitionID);
            
      RESIGNAL;
    END;

    CALL mds_getNextSequence(partitionID, 'MDS_PARTITION_ID_S');
   
    SET @seqName = mds_getDocSequenceName(partitionID); 
    
    CALL mds_createSequence(@seqName, 1);

    SET @seqName = mds_getContentSequenceName(partitionID); 
    
    CALL mds_createSequence(@seqName, 1);

    SET @seqName = mds_getLineageSequenceName(partitionID); 
    
    CALL mds_createSequence(@seqName, 1);

    -- Now create the entry in the partition-table, 
    -- store the partition_last_purge_time as current time to avoid an 
    -- immediate autopurge when the partition is populated.
      
    INSERT INTO MDS_PARTITIONS(PARTITION_ID, 
                               PARTITION_NAME,
                               PARTITION_LAST_PURGE_TIME)
        VALUES (partitionID,
                partitionName,
                UTC_TIMESTAMP());
    
    -- #(5891638) Return value to indicate a new partition create.
    SET partitionExists = $INT_FALSE;    
END
/

-- Does all the processing for commiting metadata changes made in a
-- transaction. Calling this method will ensure that the commit is always done
-- using a critical section. 
--
-- Parameters
--  commitNumber      Commit Number.
--  partitionID       PartitionID for the repository partition
--  userName          User whose changes are being commited, can be null.
--

drop procedure if exists mds_internal_processCommitCS
/

CREATE PROCEDURE mds_internal_processCommitCS ( OUT commitNumber      BIGINT, 
                                                    partitionID       INT, 
                                                    username          VARCHAR($CREATOR)) 
LANGUAGE SQL

BEGIN
    
    DECLARE docID      BIGINT;

    DECLARE version    BIGINT;

    DECLARE depID      BIGINT;

    DECLARE labelName  VARCHAR($LABEL_NAME);

    DECLARE DONE INTEGER DEFAULT 0;
    
    -- Documents, packages that were created,deleted or superceded by new version
    DECLARE cpath1 CURSOR FOR SELECT PATH_DOCID, PATH_VERSION FROM MDS_PATHS 
                     WHERE PATH_PARTITION_ID=partitionID AND  
                     PATH_LOW_CN=$INTXN_CN; 

    DECLARE cpath2 CURSOR FOR SELECT PATH_DOCID, PATH_VERSION FROM MDS_PATHS 
                     WHERE PATH_PARTITION_ID=partitionID AND  
                     PATH_HIGH_CN=$INTXN_CN; 

    -- Dependencies that were created, deleted or superceded by new version
    DECLARE cdep1 CURSOR FOR SELECT DEP_ID FROM MDS_DEPENDENCIES 
                     WHERE DEP_PARTITION_ID=partitionID AND 
                     DEP_LOW_CN=$INTXN_CN;  

    DECLARE cdep2 CURSOR FOR SELECT DEP_ID FROM MDS_DEPENDENCIES 
                     WHERE DEP_PARTITION_ID=partitionID AND 
                     DEP_HIGH_CN=$INTXN_CN;  

    -- Labels created in this transaction
    DECLARE clabel CURSOR FOR SELECT LABEL_NAME FROM MDS_LABELS 
                     WHERE LABEL_PARTITION_ID=partitionID AND 
                     LABEL_CN=$INTXN_CN;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET DONE = 1;
    
    -- NOTE: Do any processing before invoking createNewTransaction(),
    --       so that we dont lock the rows in createNewTransaction()
    --       for longer time.
    -- Generates an unique commit number and inserts a new transaction
    -- entry into mds_transactions
    CALL mds_createNewTransaction(commitNumber,partitionID,username);

    -- #(9152916) Switch to use a cusor to read all committed row and update
    -- one by one.  For DB2, if a new row is added or an existing is 
    -- updated with PATH_LOW_CN = -1 by another transaction, even if the change
    -- is not committed, UPDATE MDS_PAHTS SET ... WHERE PATH_LOW_CN = -1 AND ...
    -- will be blocked by the newly added or changed row done by other txn.
    -- If two txn add or update documents, even they are not updating the same 
    -- document, it may still introduce deadlock.  Updating through the cursor will
    -- only update the rows that are committed and will reduce the chance to get 
    -- deadlock.  Following changes are based on the same reason.

    
    OPEN cpath1;

    SET DONE = 0;
    FETCH FROM cpath1 INTO docID, version;

    WHILE DONE = 0 DO    
      UPDATE MDS_PATHS
          SET PATH_LOW_CN = commitNumber
          WHERE PATH_PARTITION_ID = partitionID AND
                PATH_DOCID = docID AND
                PATH_VERSION = version;            

      SET DONE = 0;
      FETCH FROM cpath1 INTO docID, version;
    END WHILE;

    CLOSE cpath1;

    OPEN cpath2;

    SET @cnt = 0;
    SET DONE = 0;
    FETCH FROM cpath2 INTO docID, version;

    WHILE DONE = 0 DO    
      UPDATE MDS_PATHS
          SET PATH_HIGH_CN = commitNumber
          WHERE PATH_PARTITION_ID = partitionID AND
                PATH_DOCID = docID AND
                PATH_VERSION = version; 
      SET @cnt = @cnt + 1;

      SET DONE = 0;
      FETCH FROM cpath2 INTO docID, version;
    END WHILE;

    CLOSE cpath2;

    OPEN cdep1;

    SET DONE = 0;
    FETCH FROM cdep1 INTO depID;

    WHILE DONE = 0 DO    
        UPDATE MDS_DEPENDENCIES
          SET DEP_LOW_CN = commitNumber
          WHERE DEP_ID = depID;            

      SET DONE = 0;
      FETCH FROM cdep1 INTO depID;
    END WHILE;

    CLOSE cdep1;

    OPEN cdep2;

    SET DONE = 0;
    FETCH FROM cdep2 INTO depID;

    WHILE DONE = 0 DO    
        UPDATE MDS_DEPENDENCIES
          SET DEP_HIGH_CN = commitNumber
          WHERE DEP_ID = depID;            

      SET DONE = 0;
      FETCH FROM cdep2 INTO depID;
    END WHILE;

    CLOSE cdep2;

    
    OPEN clabel;

    SET DONE = 0;
    FETCH FROM clabel INTO labelName;

    WHILE DONE = 0 DO    
        UPDATE MDS_LABELS
          SET LABEL_CN = commitNumber
          WHERE LABEL_PARTITION_ID = partitionID AND
                LABEL_NAME = labelName;            

      SET DONE = 0;
      FETCH FROM clabel INTO labelName;
    END WHILE;

    CLOSE clabel;
END
/


-- Does all the processing for commiting changes made in a MDS
-- label. 
--
-- Sets the LABEL_CN to the latest commit number or a new commit number that 
-- is generated.
--
-- Parameters
--  commitNumber      Commit Number.
--  partitionID       PartitionID for the repository partition
--  userName          User whose changes are being commited, can be null.
--  commitDBTime      Transaction commit time.
--  isCSCommit        OUT parameter. Calling procedure can request whether
--                    to commit the transaction with critical section ( by 
--                    specifying value 1) or not (value as -1) using 
--                    this parameter. Even if the request is for commit
--                    without critical section, we may internally commit
--                    the transaction with critical section if required. The
--                    out value will always reflect whether the actual commit
--                    was done with CS (value 1) or not (value -1).

drop procedure if exists mds_internal_processCommitNoCS
/

CREATE PROCEDURE mds_internal_processCommitNoCS ( OUT   commitNumber      BIGINT, 
                                                        partitionID       INT, 
                                                        username          VARCHAR($CREATOR),
                                                        commitDBTime      TIMESTAMP,
                                                  OUT   isCSCommit        SMALLINT)
LANGUAGE SQL

BEGIN

    DECLARE labelName  VARCHAR($LABEL_NAME);

    DECLARE DONE       SMALLINT DEFAULT 0;

    -- Labels created in this transaction
    DECLARE clabel CURSOR FOR SELECT LABEL_NAME FROM MDS_LABELS 
                     WHERE LABEL_PARTITION_ID=partitionID AND 
                     LABEL_CN=$INTXN_CN;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET DONE = 1;
    
    SET isCSCommit = $INT_FALSE;

    BEGIN
        DECLARE CONTINUE HANDLER FOR NOT FOUND 
        BEGIN
            -- It means that no commit number is available for this
            -- partition. Go through critical section to create a new CN.
            CALL mds_createNewTransaction(commitNumber,partitionID,username);

            -- Mark the flag that we commit the transaction with critical
            -- section.
            SET isCSCommit = $INT_TRUE;

        END;

        SELECT LOCK_TXN_CN INTO commitNumber 
            FROM MDS_TXN_LOCKS 
            WHERE LOCK_PARTITION_ID = partitionID;
    END;

    OPEN clabel;

    SET DONE = 0;
    FETCH FROM clabel INTO labelName;

    WHILE DONE = 0 DO    
        
        -- If it is a critical section commit, the txn_time itself will
        -- represent the label creation time. Hence no need to set the label
        -- creation time explicitly in labels table.
        -- If it is a commit without critical section, we need to set the
        -- label creation time explicitly.
        IF ( isCSCommit = $INT_TRUE ) THEN
            UPDATE MDS_LABELS
              SET LABEL_CN = commitNumber
              WHERE LABEL_PARTITION_ID = partitionID AND
                    LABEL_NAME = labelName;
        ELSE
            -- it is a commit without critical section, we need to set the
            -- label creation time explicitly.

            -- Since Mysql TIMESTAMP has precision of 1 second, we will bump
            -- the label_time to 1 second if we find a label with same cn and
            -- LABEL_TIME.
            SELECT MAX(LABEL_TIME)
                 INTO @lbl_time FROM MDS_LABELS
                 WHERE LABEL_PARTITION_ID = partitionID AND
                       LABEL_CN = commitNumber;
            IF ( @lbl_time IS NULL ) THEN
                SELECT MAX(TXN_TIME) into @lbl_time FROM MDS_TRANSACTIONS
                       WHERE TXN_PARTITION_ID = partitionID AND
                             TXN_CN = commitNumber; 
            END IF;

            IF ( @lbl_time IS NULL ) THEN
                SET @lbl_time = commitDBTime;
            ELSE
                IF ( @lbl_time >= commitDBTime ) THEN
                    SET @lbl_time = TIMESTAMPADD(SECOND, 1, @lbl_time);
                ELSE
                    SET @lbl_time = commitDBTime;
                END IF;
            END IF;

            UPDATE MDS_LABELS
              SET LABEL_CN = commitNumber, LABEL_TIME = @lbl_time 
              WHERE LABEL_PARTITION_ID = partitionID AND
                    LABEL_NAME = labelName;
        END IF;  

      SET DONE = 0;
      FETCH FROM clabel INTO labelName;
    END WHILE;

    CLOSE clabel;
END
/


-- Does all the processing for commiting metadata changes made in a
-- transaction as described below.
--
-- (i) It generates a unique(within the repository partition)
--     commit number(CN)for the transaction
--
-- (ii) For any documents, packages or dependencies that were deleted or
-- superseeded by newer version in the transaction, sets PATH_HIGH_CN or
-- DEP_HIGH_CN to  this commit number. These will be seen as unavailable
-- for anybody using  a higher  commit number but could be retrieved by
-- anybody using a the  same or lower CN (referred to as logical deletion)
--
-- (iii) Initalizes the PATH_LOW_CN or DEP_LOW_CN for any for the documents,
-- packages and dependencies created to mark them as being available from
-- this CN and later
--
-- (iv) Sets the LABEL_CN to commit number that is generated, the label
-- can be used to read any content that existed at this CN (including
-- changes in this transaction) or before.
--
-- (v) If required, checks if the auto purge needs to be invoked and if found
-- so populates the currentDBTime with the current system time.
--
-- Parameters
--  commitNumber      Commit Number.
--  partitionID       PartitionID for the repository partition
--  userName          User whose changes are being commited, can be null.
--  autoPurgeInterval Minimum time interval to wait before invoking the next
--                    autopurge
--  doPurgeCheck      Value to indicate whether to do a purge check or not
--  purgeRequired     OUT parameter integer to determine purge required.
--  commitDBTime      OUT parameter transaction commit time.
--  isCSCommit        IN OUT parameter. Calling procedure can request whether
--                    to commit the transaction with critical section ( by 
--                    specifying value 1) or not (value as -1) using 
--                    this parameter. Even if the request is for commit
--                    without critical section, we may internally commit
--                    the transaction with critical section if required. The
--                    out value will always reflect whether the actual commit
--                    was done with CS (value 1) or not (value -1).
--

drop procedure if exists mds_processCommitNew
/

CREATE PROCEDURE mds_processCommitNew ( OUT   commitNumber      BIGINT, 
                                              partitionID       INT, 
                                              username          VARCHAR($CREATOR), 
                                              autoPurgeInterval INT, 
                                              doPurgeCheck      SMALLINT, 
                                        OUT   purgeRequired     SMALLINT, 
                                        OUT   commitDBTime      TIMESTAMP,
                                        INOUT isCSCommit        SMALLINT)
LANGUAGE SQL

BEGIN
    DECLARE systemTime TIMESTAMP;

    -- Store the system time in a local variable
    -- to remove any inaccuracies in using it in the query below
    -- #(5570793) - Store timestamps always as UTC
    SET systemTime = UTC_TIMESTAMP();
    
    SET purgeRequired = -1;
    
    SET commitDBTime = systemTime;

    IF ( isCSCommit = $INT_TRUE ) THEN
        CALL mds_internal_processCommitCS(commitNumber, partitionID, username);
    ELSE
        CALL mds_internal_processCommitNoCS(commitNumber,
                                            partitionID,
                                            username,
                                            commitDBTime,
                                            isCSCommit);
    END IF;
END
/


    
-- Does all the processing for commiting metadata changes made in a
-- transaction. Calling this method will ensure that the commit is always done
-- using a critical section. This method is maintained for backward
-- compatibility reasons. This method can be removed when backward 
-- compatibility is no longer an issue.
--
-- Parameters
--  commitNumber      Commit Number.
--  partitionID       PartitionID for the repository partition
--  userName          User whose changes are being commited, can be null.
--  autoPurgeInterval Minimum time interval to wait before invoking the next
--                    autopurge
--  doPurgeCheck      Value to indicate whether to do a purge check or not
--  purgeRequired     OUT parameter integer to determine purge required.
--  commitDBTime      OUT parameter transaction commit time.
--
drop procedure if exists mds_processCommit
/


CREATE PROCEDURE mds_processCommit ( OUT commitNumber      BIGINT, 
                                         partitionID       INT, 
                                         username          VARCHAR($CREATOR), 
                                         autoPurgeInterval INT, 
                                         doPurgeCheck      SMALLINT, 
                                     OUT purgeRequired     SMALLINT, 
                                     OUT commitDBTime      TIMESTAMP )
LANGUAGE SQL

BEGIN
    DECLARE isCSCommit INT;
   
    SET isCSCommit = 1;

    CALL mds_processCommitNew(commitNumber, 
                              partitionID, 
                              username,
                              autoPurgeInterval,
                              doPurgeCheck,
                              purgeRequired,
                              commitDBTime,
                              isCSCommit);
END
/


--
-- Delete the document logically by marking the document version as
-- not being valid after this transaction
--
-- Parameters:
--   partitionID  - the partition where the document to be created
--   docID        - ID of the document to delete
--   lowCN        - PATH_LOW_CN of the document being deleted, used for
--                  checking concurrent updates on the document
--   version      - Version of the document to be deleted.
--   docName      - Name of the document, used for concurrent update in the
--                  case it was recreated
--   forceIt      - Specify 0 if concurrent update check should not be done
--

drop procedure if exists mds_deleteDocument
/



CREATE PROCEDURE mds_deleteDocument (partitionID INT, 
                                     docID       BIGINT, 
                                     lowCN       BIGINT, 
                                     version     INT, 
                                     docName     VARCHAR($FULLNAME), 
                                     forceIt     INT)
LANGUAGE SQL

BEGIN
    -- placeholder for call to lockDocument
    DECLARE tmpVersNum INT;
    
    IF (forceIt = 0) THEN 
        -- Check for any Concurrent operations first. If no Concrrency issues are
        -- detected then go ahead and grab the lock, create a new version of the
        -- document.

        CALL mds_doConcurrencyCheck(docID,docName,lowCN,version,partitionID);
    ELSE
        -- Lock the path before updating it as deleted
        -- deleteDocument would fail with resource_busy exception if somebody
        -- is modifying it or has locked it.

        CALL mds_lockDocument(partitionID,docID,0,tmpVersNum);

    END IF;
    
    -- NOTE: Tables updated here should be kept in sync with
    -- prepareDocumentForInsert() obsoleting the previous version
    -- Logically delete the document by marking the HIGH_CN as -1
    -- This will be replaced with the correct commit number in
    -- processCommit()
    UPDATE MDS_PATHS SET path_high_cn=$INTXN_CN, 
                         path_operation=$DELETE_OP
        WHERE path_docid = docid
              AND path_type = '$TYPE_DOCUMENT' AND path_high_cn IS NULL
              AND path_partition_id = partitionID;
    
    -- Delete the dependencies originating from this docuent
    UPDATE MDS_DEPENDENCIES SET dep_high_cn=$INTXN_CN
        WHERE dep_child_docid = docid AND dep_high_cn IS NULL
              AND dep_partition_id = partitionID;
END
/


--
-- Gives the partitionID for the given partitionName. If the entry not found,
-- it will create new entry in MDS_PARTIITONS table and returns the new
-- partitionID.  If this function is called within a transaction and it succeeds, 
-- roll back the transaction won't undo the changes which have been made.  
-- Users can call deletePartition function to do cleanup.
-- 
--
-- Parameters:
--   partitionID(OUT)  - Returns the ID for the given partition.
--   partitionExists   - OUT param, value to indicate if the partition already 
--                       exists.
--   partitionName     - Name of the Repository partition.
--

drop procedure if exists mds_getOrCreatePartitionID
/


CREATE PROCEDURE mds_getOrCreatePartitionID (OUT partitionID     INT, 
                                             OUT partitionExists SMALLINT, 
                                                 partitionName   VARCHAR($PARTITION_NAME))
LANGUAGE SQL

BEGIN
    
    DECLARE EXIT HANDLER FOR NOT FOUND
    BEGIN
        -- Create sequences in a seperate transaction.
        CALL mds_internal_createPartition(partitionID, partitionExists, partitionName);
    END;
    
    SELECT partition_id INTO partitionID
        FROM MDS_PARTITIONS 
        WHERE partition_name = partitionName;     

    -- #(5891638) Return value to indicate the partition exists.
    SET partitionExists = $INT_TRUE;
END
/


--
-- Creates an entry in the MDS_PATHS document.
--
-- Parameters:
--   docID        - the document ID for the inserted path.
--   partitionID  - the partition where the document to be created
--   documentID   - Document ID of the document being saved.
--   pathname     - the name of the document/package (not fully qualified)
--   fullPath     - Fullname for the path to be created
--   ownerID      - the ID of the owning package
--   docType      - either 'DOCUMENT', 'TRANSLATION' or 'PACKAGE'
--   docElemName  - Local name of the document element, null for Non-XML docs
--   docElemNSURI - NS URI of document element, null for Non-XML docs
--   versionNum   - Version number, applicable only for DOCUMENTs
--   xmlversion   - xml version, which can be null for "child" documents
--   xmlencoding  - xml encoding, which can be null for "child" documents
--   checksum     - checksum for the document content.
--   lineageID    - lineageID for the document if seeded.
--   moTypeNSURI  - Element namespace of the base document for a customization
--                  document.  Null value for a base document or a package.
--   moTypeName   - Element name of the base document for a customization
--                  document.  Null value for a base document or a package.
--   contentType  - Document content stored as: 0 - Shredded XML
--                                              1 - BLOB
--                                              2 - Unshredded XML
--
--

drop procedure if exists mds_internal_insertPath
/


CREATE PROCEDURE mds_internal_insertPath ( OUT docID         BIGINT, 
                                               partitionID   INT, 
                                               documentID    BIGINT, 
                                               pathname      VARCHAR($PATH_NAME), 
                                               fullPath      VARCHAR($FULLNAME), 
                                               ownerID       BIGINT, 
                                               docType       VARCHAR($PATH_TYPE), 
                                               docElemNSURI  VARCHAR($ELEM_NSURI), 
                                               docElemName   VARCHAR($ELEM_NAME), 
                                               versionNum    INT, 
                                               verComment    VARCHAR($VER_COMMENTS), 
                                               xmlversion    VARCHAR($XML_VERSION), 
                                               xmlencoding   VARCHAR($XML_ENCODING), 
                                               mdsGuid       VARCHAR($GUID),
                                               checksum      BIGINT,
                                               lineageID     BIGINT,
                                               moTypeNSURI   VARCHAR($ELEM_NSURI), 
                                               moTypeName    VARCHAR($ELEM_NAME),
                                               contentType   SMALLINT) 
LANGUAGE SQL

BEGIN
    DECLARE contentID BIGINT;
        
    DECLARE changeType BIGINT;
        
    -- An exception can be caused by one of the following situations:
    -- (1) If the sequence MDS_DOCUMENT_ID_S is corrupt (i.e. the current value
    --     of the sequence is less than the maximum document ID)
    -- (2) We are trying to insert a document whose name matches an existing
    --     package or vice versa.  For example, suppose we have a document
    --     called:
    --       /demo/test/mydoc.xml
    --     and we try to create a document called:
    --       /demo/test
    --     This will fail due to the unique index on (path_owner_docid,
    --     path_name).
    --  (3) Two users are attempting to insert the same document at the same
    --      time
 
    -- 
    DECLARE EXIT HANDLER FOR 1062 
    BEGIN
                
        DECLARE cnt INT;
        DECLARE pathTypeToCheck VARCHAR($PATH_TYPE);
                    
        -- Since no data was found, we know this was caused by either (1) or
        -- or (2).  If the following query returns no rows, then this can only
        -- be explained by a corrupt sequence; otherwise, we are dealing with
        -- a name conflict.
        DECLARE EXIT HANDLER FOR NOT FOUND 
        BEGIN 
          SELECT count(*) INTO cnt
            FROM MDS_PATHS 
            WHERE  path_name = pathname AND
                   path_owner_docid = ownerID AND
                   path_high_cn IS NULL AND
                   path_partition_id = partitionID;
            
            IF (cnt = 0) THEN
            -- #(9649970) Check if the conflict could be due to a deleted 
            -- resource of other type
              IF (docType = '$TYPE_DOCUMENT') THEN
                set pathTypeToCheck = '$TYPE_PACKAGE';
              ELSE
                set pathTypeToCheck = '$TYPE_DOCUMENT';
              END IF;

              SELECT count(*) INTO cnt
                FROM MDS_PATHS 
                WHERE
                   path_name = pathname AND
                   path_owner_docid = ownerID AND
                   path_high_cn IS NOT NULL AND
                   path_partition_id = partitionID AND
                   path_type=pathTypeToCheck;
              IF (cnt = 0) THEN
                RESIGNAL SQLSTATE '$ERROR_CORRUPT_SEQUENCE'
                 SET MESSAGE_TEXT = 'ERROR_CORRUPT_SEQUENCE';
              ELSE
                RESIGNAL SQLSTATE '$ERROR_NAME_CONFLICT_NONTIP'
                 SET MESSAGE_TEXT = 'ERROR_NAME_CONFLICT_NONTIP';
              END IF;
            ELSE
                RESIGNAL SQLSTATE '$ERROR_DOCUMENT_NAME_CONFLICT'
                 SET MESSAGE_TEXT = 'ERROR_DOCUMENT_NAME_CONFLICT 1';
            END IF;
        END;

        SELECT path_docid INTO docID
            FROM MDS_PATHS 
            WHERE path_name = pathname AND
                  path_owner_docid = ownerID AND
                  path_type = docType AND
                  path_high_cn IS NULL AND
                  path_partition_id = partitionID;

        -- Conflict change happened.
        RESIGNAL SQLSTATE '$ERROR_DOCUMENT_NAME_CONFLICT'
            SET MESSAGE_TEXT = 'ERROR_DOCUMENT_NAME_CONFLICT 2';
    END;
        
    SET contentID = NULL;
        
    IF (docType = '$TYPE_DOCUMENT') THEN
        -- Get the next content ID in the given partition.

        SET @seqName = mds_getContentSequenceName(partitionID); 

        CALL mds_getNextSequence(contentID, @seqName);
            
        -- Newer versions of the document should use the same document ID
        IF (documentID = -1) THEN

            SET changeType = $CREATE_OP;

            SET @seqName = mds_getDocSequenceName(partitionID); 

            CALL mds_getNextSequence(docID, @seqName);
                
        ELSE

            SET changeType = $UPDATE_OP;
            SET docID = documentID;
        END IF;
    ELSE
        -- Get the next document ID for the package in the given partition.
        SET @seqName = mds_getDocSequenceName(partitionID); 

        CALL mds_getNextSequence(docID, @seqName);
    END IF;
        
    -- New documents are created with low_cn set to -1, it is
    -- replaced with actual commit number corresponding to the transaction
    -- by BaseDBMSConnection.commit()
    INSERT INTO MDS_PATHS 
      (PATH_PARTITION_ID, PATH_NAME, PATH_DOCID, 
       PATH_OWNER_DOCID, PATH_TYPE,
       PATH_DOC_ELEM_NSURI, PATH_DOC_ELEM_NAME,
       PATH_FULLNAME, PATH_GUID,
       PATH_LOW_CN, PATH_HIGH_CN, PATH_OPERATION, PATH_CONTENTID,
       PATH_VERSION, PATH_VER_COMMENT,
       PATH_XML_VERSION, PATH_XML_ENCODING, PATH_CONT_CHECKSUM, 
       PATH_LINEAGE_ID, PATH_DOC_MOTYPE_NSURI, PATH_DOC_MOTYPE_NAME,
       PATH_CONTENT_TYPE)
    VALUES
      (partitionID, pathname, docID, ownerID, docType,
       docElemNSURI, docElemName,
       fullPath, mdsGuid,
       $INTXN_CN, null, changeType, contentID,
       versionNum, verComment,
       xmlversion, xmlencoding, checksum, lineageID,
       moTypeNSURI, moTypeName, contentType);
END
/


--
-- Creates an entry in the MDS_PATHS document with retry if encounting
-- ERROR_CORRUPT_SEQUNCE exception. 
--
-- Parameters:
--   docID        - the document ID for the inserted path.
--   partitionID  - the partition where the document to be created
--   documentID   - Document ID of the document being saved.
--   pathname     - the name of the document/package (not fully qualified)
--   fullPath     - Fullname for the path to be created
--   ownerID      - the ID of the owning package
--   docType      - either 'DOCUMENT', 'TRANSLATION' or 'PACKAGE'
--   docElemName  - Local name of the document element, null for Non-XML docs
--   docElemNSURI - NS URI of document element, null for Non-XML docs
--   versionNum   - Version number, applicable only for DOCUMENTs
--   xmlversion   - xml version, which can be null for "child" documents
--   xmlencoding  - xml encoding, which can be null for "child" documents
--   checksum     - checksum for the document content.
--   lineageID    - lineageID for the document if seeded.
--   moTypeNSURI  - Element namespace of the base document for a customization
--                  document.  Null value for a base document or a package.
--   moTypeName   - Element name of the base document for a customization
--                  document.  Null value for a base document or a package.
--   contentType  - Document content stored as: 0 - Shredded XML
--                                              1 - BLOB
--                                              2 - Unshredded XML
--
--

drop procedure if exists mds_internal_insertPathWithRetry
/

CREATE PROCEDURE mds_internal_insertPathWithRetry ( OUT docID         BIGINT, 
                                                        partitionID   INT, 
                                                        documentID    BIGINT, 
                                                        pathname      VARCHAR($PATH_NAME), 
                                                        fullPath      VARCHAR($FULLNAME), 
                                                        ownerID       BIGINT, 
                                                        docType       VARCHAR($PATH_TYPE), 
                                                        docElemNSURI  VARCHAR($ELEM_NSURI), 
                                                        docElemName   VARCHAR($ELEM_NAME), 
                                                        versionNum    INT, 
                                                        verComment    VARCHAR($VER_COMMENTS), 
                                                        xmlversion    VARCHAR($XML_VERSION), 
                                                        xmlencoding   VARCHAR($XML_ENCODING), 
                                                        mdsGuid       VARCHAR($GUID),
                                                        checksum      BIGINT,
                                                        lineageID     BIGINT,
                                                        moTypeNSURI   VARCHAR($ELEM_NSURI), 
                                                        moTypeName    VARCHAR($ELEM_NAME),
                                                        contentType   SMALLINT)
LANGUAGE SQL

BEGIN
    DECLARE finish      SMALLINT DEFAULT 0;
    DECLARE num_tried   SMALLINT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR SQLSTATE '$ERROR_CORRUPT_SEQUENCE'
    BEGIN
        -- If we ever retried upon corrupted exception, we will end here.
        IF ( num_tried > 1 ) THEN
            RESIGNAL;
        END IF;

        -- Reset the flag to try one more time.
        SET finish = 0;
    END;

    WHILE  ( finish = 0 )  DO
        SET num_tried = num_tried + 1;
        SET finish = 1;

        CALL mds_internal_insertPath(docID,           -- Returns DOCID for the inserted pkg path.
                                     partitionID,
                                     documentID,      -- existing docID : treat as create
                                     pathname,        -- Path Name
                                     fullPath,
                                     ownerID,
                                     docType,
                                     docElemNSURI,    -- DocElemNSURI
                                     docElemName,     -- docElemName
                                     versionNum,
                                     verComment,      -- verComment
                                     xmlversion,      -- xmlversion
                                     xmlencoding,     -- xmlencoding
                                     mdsGuid,         -- GUID
                                     checksum,        -- checksum
                                     lineageID,       -- LineageID
                                     moTypeNSURI,     -- moTypeNSURI
                                     moTypeName,      -- moTypeName 
                                     contentType);    -- contentType
    END WHILE;
END
/

--
-- Creates the specified package, commiting it immediately to avoid
-- concurrency issues.
--
-- Parameters:
--   partitionID  - the partition where the document to be created
--   fullPathName - the complete path name of the package
--   pkgLocalName - Local name of the package  
--   pkgDocID     - PATH_DOCID of the parent package
--   verNum       - Version number for the package
--
-- Returns:
--   PATH_DOCID of the created package
--

drop procedure if exists mds_internal_createPkgImmediate
/

CREATE PROCEDURE mds_internal_createPkgImmediate (OUT docID         BIGINT,
                                                      partitionID   INT, 
                                                      fullPathName  VARCHAR($FULLNAME), 
                                                      pkgLocalName  VARCHAR($FULLNAME), 
                                                      pkgDocID      BIGINT, 
                                                      verNum        BIGINT) 
LANGUAGE SQL

BEGIN    
    SET docID = 0;
    
    CALL mds_internal_insertPathWithRetry(
                                 docID,           -- Returns DOCID for the inserted pkg path.
                                 partitionID,
                                 -1,              -- existing docID : treat as create
                                 pkgLocalName,    -- Path Name
                                 fullPathName,
                                 pkgDocID,
                                 '$TYPE_PACKAGE',
                                 null,            -- DocElemNSURI
                                 null,            -- docElemName
                                 verNum,
                                 null,            -- verComment
                                 null,            -- xmlversion
                                 null,            -- xmlencoding
                                 null,            -- GUID
                                 null,            -- checksum
                                 null,            -- LineageID
                                 null,            -- moTypeNSURI
                                 null,            -- moTypeName
                                 null);           -- contentType 
END
/


--
-- Checks if the package path parts already exist and if not
-- recursively creates the non-existing parent packages.
--
-- Parameters:
--   partitionID  - the partition where the document to be created
--   fullPathName   - the complete path name of the document
--
-- Returns:
--   the ID of the created path
--

drop procedure if exists mds_internal_createPackageRecursive
/


CREATE PROCEDURE mds_internal_createPackageRecursive (OUT pkgDocID     BIGINT,
                                                          partitionID  INT, 
                                                          fullPathName VARCHAR($FULLNAME)) 
LANGUAGE SQL

createPackageRecursive:BEGIN
    DECLARE parentPkgName   VARCHAR($FULLNAME);
    
    DECLARE newVersionNum   INT DEFAULT 1;

    DECLARE strSQL          VARCHAR(256) DEFAULT '';
    
    -- Declared with size of path_fullname to allow long pathname to 
    -- fail with COLWIDTH_EXCEED_ERROR exception
    DECLARE pkgLocalName    VARCHAR($FULLNAME);
    
    DECLARE lastSlashpos    SMALLINT DEFAULT 1.0;
    
    DECLARE CFOUND INTEGER DEFAULT NULL;
    
    DECLARE c CURSOR FOR SELECT path_docid FROM MDS_PATHS 
                            WHERE path_fullname = fullPathName AND path_type = '$TYPE_PACKAGE' 
                                  AND path_partition_id = partitionID AND path_high_cn IS NULL;
    
    SET pkgDocID = 0;

    IF( fullPathName = '/' ) THEN
        SET pkgDocID = $ROOT_DOCID;
   
        LEAVE createPackageRecursive;
    END IF;
        
    -- Does this package already exist
    OPEN c;
        
    BEGIN
       DECLARE CONTINUE HANDLER FOR NOT FOUND SET CFOUND = 0;

       SET CFOUND = 1;
       FETCH FROM c INTO pkgDocID;
    END;
        
    -- Insert the package if it does not already exist
    IF CFOUND = 1 THEN 
        CLOSE c;
        LEAVE createPackageRecursive;
    END IF;
            
    -- #(5508200) - If this is a recreate then continue the version number 
    -- of the logically deleted resource instead of 1 
    SELECT COALESCE(MAX(path_version)+1, 1) INTO newVersionNum
        FROM MDS_PATHS 
         WHERE path_fullname = fullPathName AND 
               path_partition_id = partitionID AND
               path_high_cn IS NOT NULL AND 
               path_type = '$TYPE_PACKAGE';

    IF newVersionNum < 1 THEN
        SET newVersionNum = 1;
    END IF;

    IF newVersionNum < 1 THEN
        SET newVersionNum = 1;
    END IF;

    -- Search for the last slash to compute the package and document name

    SET lastSlashpos = mds_internal_INSTR('/', fullPathName);
            
    SET pkgLocalName = SUBSTRING(fullPathName, lastSlashpos + 1);

    IF (lastSlashpos > 1) THEN 
                
        SET parentPkgName = SUBSTRING(fullPathName, 1, lastSlashpos - 1);
    ELSE

        -- For example: for /mypkg, pkg is '/' and pkgLocalName is 'mypkg'
        SET parentPkgName = '/';
    END IF;
            
    -- #(6011472) Recursively check existence of parent packages starting
    -- from immediate parent package. This is more efficient than doing
    -- a topdown check as it avoids query for all higher parent packages
    -- once an existing parent is found.
    
    CALL mds_internal_createPackageRecursive(pkgDocID,
                                             partitionID, 
                                             parentPkgName); 
  
    CALL mds_internal_createPkgImmediate(pkgDocID, 
                                         partitionID,
                                         fullPathName,
                                         pkgLocalName,
                                         pkgDocID,
                                         newVersionNum);
        
    CLOSE c;      
END
/


--
-- Creates an entry in the MDS_PATHS table for the MDS document.
-- The full name of the document must be specified.  Any packages
-- which do not already exist will be created as well.
--
-- Note that absPathName cannot be over 4000 bytes long, otherwise,
-- an "ORACLE 06502: PL/SQL: numeric or value error: character string 
-- buffer too small" exception will be thrown from the procedure.
-- Parameters:
--   partitionID  - the partition where the document to be created
--   absPathName  - the complete path name of the document.  
--   docType      - either 'PACKAGE' or 'DOCUMENT' OR 'TRANSLATION'
--   docElemName  - Local name of the document element, null for Non-XML docs
--   docElemNSURI - NS URI of document element, null for Non-XML docs
--   versionNum   - Version number for the document
--   xmlversion   - xml version
--   xmlencoding  - xml encoding
--   mdsGuid      - GUID for the document
--   checksum     - checksum for the document content.
--   lineageID    - lineageID for the document if seeded.
--   moTypeNSURI  - Element namespace of the base document for a customization
--                  document.  Null value for a base document or a package.
--   moTypeName   - Element name of the base document for a customization
--                  document.  Null value for a base document or a package.
--   contentType  - Document content stored as: 0 - Shredded XML
--                                              1 - BLOB
--                                              2 - Unshredded XML
--
-- Returns:
--   the ID of the created path
--
drop procedure if exists mds_internal_createPath
/

CREATE PROCEDURE mds_internal_createPath (OUT  docID         BIGINT,
                                               partitionID   INT, 
                                               documentID    BIGINT, 
                                               absPathName   VARCHAR($FULLNAME), 
                                               docType       VARCHAR($PATH_TYPE), 
                                               docElemNSURI  VARCHAR($ELEM_NSURI), 
                                               docElemName   VARCHAR($ELEM_NAME), 
                                               versionNum    INT, 
                                               verComment    VARCHAR($VER_COMMENTS), 
                                               xmlversion    VARCHAR($XML_VERSION), 
                                               xmlencoding   VARCHAR($XML_ENCODING), 
                                               mdsGuid       VARCHAR($GUID),
                                               checksum      BIGINT,
                                               lineageID     BIGINT, 
                                               moTypeNSURI   VARCHAR($ELEM_NSURI), 
                                               moTypeName    VARCHAR($ELEM_NAME),
                                               contentType   SMALLINT)
LANGUAGE SQL

createPath:BEGIN
    
    DECLARE ownerDocID    BIGINT DEFAULT 0;
    
    DECLARE fullPathName  VARCHAR(4000);
    
    DECLARE packageName   VARCHAR($FULLNAME);
    
    -- Declared with size of path_fullname to allow long pathname to 
    -- fail with COLWIDTH_EXCEED_ERROR exception
    DECLARE docName       VARCHAR($FULLNAME);
    
    DECLARE lastSlashpos  INTEGER;

    SET docID = 0;
        
    SET fullPathName = absPathName;
    
    -- Ensure that the pathName starts with a slash
    IF (LOCATE('/', fullPathName) <> 1) THEN
        
        SET docID = -1;
        LEAVE createPath;
    END IF;
    
    
    -- #(3403125) Remove the trailing forward slash if any
    IF (LOCATE('/', fullPathName, CHAR_LENGTH(fullPathName)) > 0)  THEN

        SET fullPathName = SUBSTRING(fullPathName, 1, CHAR_LENGTH(fullPathName) - 1);
    
    END IF;
    
    SET lastSlashpos = mds_internal_INSTR('/', fullPathName);
    
    SET docName = SUBSTRING(fullPathName, lastSlashpos + 1);
    
    IF (lastSlashpos > 1) THEN 
        
        SET packageName = SUBSTRING(fullPathName, 1, lastSlashpos - 1);
    ELSE

        -- Root level resource Example: /page1.xml or /mypkg
        SET packageName = '/';
    END IF;
    
    -- Create MDS_PATHS entry for the package
    CALL mds_internal_createPackageRecursive(ownerDocID, partitionID, packageName);
    
    -- Now create the MDS_PATHS entry for the document
    CALL mds_internal_insertPathWithRetry(
                                 docId,         -- returns new id for the inserted path.
                                 partitionID,
                                 documentID,
                                 docName,
                                 fullPathName,
                                 ownerDocID,
                                 docType,
                                 docElemNSURI,
                                 docElemName,
                                 versionNum,
                                 verComment,
                                 xmlversion,
                                 xmlencoding,
                                 mdsGuid,
                                 checksum,
                                 lineageID,
                                 moTypeNSURI,
                                 moTypeName,
                                 contentType);

END
/


--
-- Renames the document with given document id to the new name passed in.
-- The document with new name will continue to have the docId of the old
-- document.
--
-- Parameters:
--   partitionID    - the partition where the document exists
--   p_oldDocId     - document id for doc with old name. Used in step 3.
--   p_oldName      - the original name of the component/document
--   p_newName      - the new name of the component/document
--   p_newDocName   - document name component of the new name
--   p_vercomment   - Version comment for the renamed document
--   p_xmlversion   - xml version of the document
--   p_xmlencoding  - xml encoding of the document
--   p_pkgChange    - true if package has changed between oldName and new
--			Name. false otherwise.

drop procedure if exists mds_renameDocument
/


CREATE PROCEDURE mds_renameDocument (partitionID    INT, 
                                     p_oldDocId     BIGINT, 
                                     p_fullpath     VARCHAR($FULLNAME), 
                                     p_newName      VARCHAR($FULLNAME), 
                                     p_newDocName   VARCHAR($PATH_NAME), 
                                     p_vercomment   VARCHAR($VER_COMMENTS), 
                                     p_xmlversion   VARCHAR($XML_VERSION), 
                                     p_xmlencoding  VARCHAR($XML_ENCODING), 
                                     p_pkgChange    BIGINT )
LANGUAGE SQL

BEGIN
    
    -- If packageName is changed
    -- 1) Create a new path for newDocName
    -- 2) Delete the document portion of the path created in 1
    -- 3) Update the document portion of old path to refer to the parent path created
    --    in 1.
    -- else
    -- 1) Update oldname with newnames for given oldDocId.
    -- end
    -- all declarations

    DECLARE docID            BIGINT;
    DECLARE parentDocID      BIGINT;
    DECLARE oldPartnID       BIGINT;
    DECLARE oldGuid          VARCHAR($GUID);
    DECLARE oldDocElemName   VARCHAR($ELEM_NAME);
    DECLARE oldDocElemNS     VARCHAR($ELEM_NSURI);
    DECLARE oldContID        BIGINT;
    DECLARE oldVerNum        BIGINT;
    DECLARE oldXmlVer        VARCHAR($XML_VERSION);
    DECLARE oldXmlEnc        VARCHAR($XML_ENCODING);
    DECLARE tmpVersionNum    BIGINT;
    DECLARE oldChkSum        BIGINT;
    DECLARE oldMoTypeName    VARCHAR($ELEM_NAME);
    DECLARE oldMoTypeNS      VARCHAR($ELEM_NSURI);
    DECLARE oldContentType   SMALLINT;

    DECLARE fullPathName     VARCHAR(4000);    
    DECLARE packageName      VARCHAR($FULLNAME);
    DECLARE docName          VARCHAR($FULLNAME);
    DECLARE lastSlashpos     INTEGER;

    -- #(2669626) If the sequence, MDS_DOCUMENT_ID_S, is corrupt (which can
    -- happen if it gets reset), then createPath will raise a NO_DATA_FOUND
    -- exception.
    DECLARE EXIT HANDLER FOR SQLSTATE '$ERROR_CORRUPT_SEQUENCE'
    BEGIN
        RESIGNAL; 
    END;

    DECLARE EXIT HANDLER FOR SQLSTATE '$ERROR_NAME_CONFLICT_NONTIP'
    BEGIN
        RESIGNAL;
    END;

    -- #(2456503) If we were unable to create the path, it is likely due
    -- to an already existing document or package
    DECLARE EXIT HANDLER FOR SQLSTATE '$ERROR_DOCUMENT_NAME_CONFLICT'
    BEGIN
        RESIGNAL; 
    END;            

    SET fullPathName = p_newName;

    
    -- Lock the old document path before renaming so that it fails with
    -- resource_busy exception if somebody is modifying it or has locked it.
    CALL mds_lockDocument(partitionID,p_oldDocId,0,tmpVersionNum);
    
    -- Save the values from the tip document that need to be used for the
    -- renamed document
    SELECT PATH_PARTITION_ID, PATH_GUID, PATH_CONTENTID, PATH_OWNER_DOCID,
           PATH_DOC_ELEM_NAME, PATH_DOC_ELEM_NSURI,
           PATH_VERSION, PATH_XML_VERSION, PATH_XML_ENCODING,
           PATH_CONT_CHECKSUM, PATH_DOC_MOTYPE_NAME, PATH_DOC_MOTYPE_NSURI,
           PATH_CONTENT_TYPE
        INTO oldPartnID, oldGuid, oldContID, parentDocID,
           oldDocElemName, oldDocElemNS,
           oldVerNum, oldXmlVer, oldXmlEnc,
           oldChkSum, oldMoTypeName, oldMoTypeNS, oldContentType
        FROM MDS_PATHS WHERE path_docid=p_oldDocId
           AND path_partition_id=partitionID
           AND path_high_cn IS NULL;

    IF p_pkgChange = 1 THEN 
        -- #(8306901) create recursive package
        IF (LOCATE('/', fullPathName, CHAR_LENGTH(fullPathName)) > 0)  THEN

            SET fullPathName = SUBSTRING(fullPathName, 1, 
                                         CHAR_LENGTH(fullPathName) - 1);
        END IF;
            
        SET lastSlashpos = mds_internal_INSTR('/', fullPathName);
    
        IF ( lastSlashpos > 1 ) THEN

            SET packageName = SUBSTRING(fullPathName, 1, lastSlashpos - 1);
        ELSE
            -- Root level resource Example: /page1.xml or /mypkg
            SET packageName = '/';
            
        END IF;
            
        -- create the parent package if it does not exist
        CALL mds_internal_createPackageRecursive(parentDocID, partitionID,packageName);
    END IF;
    
    -- Mark the current version as old version by setting PATH_HIGH_CN
    -- deleteDocument() is not used for this purpose since the typed
    -- dependencies originating from this document are still valid
    UPDATE MDS_PATHS SET path_high_cn=$INTXN_CN
        WHERE path_docid = p_oldDocId
              AND path_type = '$TYPE_DOCUMENT' 
              AND path_partition_id=partitionID
              AND path_high_cn IS NULL;

    -- Select the highest version number for the document identified by the new
    -- name. This is because if there already a document exists which has the
    -- same fullPathName as the newName, get its latest version number and
    -- assign it to the new version being saved.[ofcourse after incrementing it
    -- by 1] bug # 5508200
    SELECT COALESCE(MAX(path_version), oldVerNum) INTO oldVerNum
        FROM MDS_PATHS
        WHERE ( path_fullname = p_newName OR 
                path_guid = oldGuid OR
                  path_docid = p_oldDocId) AND 
                  path_partition_id = partitionID and
                  path_type='$TYPE_DOCUMENT';

    -- #(6446544) deleteAllVersions() would leave behind the tip after 
    -- changing it's path_version to -ve of path_low_cn. If we find this as 
    -- the existing version, we should ignore it and create this version 
    -- with version=1
    IF (1 > oldVerNum) THEN 
        
        SET oldVerNum = 1;
    END IF;
    
    -- Create the renamed document as a new version with the same ContentID
    INSERT INTO MDS_PATHS
         (path_partition_id, path_name, path_fullname, path_guid,
          path_docid, path_owner_docid,  path_type,
          path_doc_elem_nsuri, path_doc_elem_name,
          path_low_cn, path_high_cn, path_contentid,
          path_version, path_ver_comment, path_operation,
          path_xml_version,path_xml_encoding, path_cont_checksum,
          path_doc_motype_nsuri, path_doc_motype_name, path_content_type)
       VALUES (oldPartnID, p_newDocName, p_newName, oldGuid,
               p_oldDocId, parentDocID, '$TYPE_DOCUMENT',
               oldDocElemNS, oldDocElemName,
               $INTXN_CN, null, oldContID,
               oldVerNum + 1, null, $RENAME_OP,
               oldXmlVer, oldXmlEnc, oldChkSum,
               oldMoTypeNS, oldMoTypeName, oldContentType);
END
/


--
-- Performs all steps that are necessary before a top-level document is
-- saved/updated which includes:
-- (1) If the document already exists, updates the "who" columns in
--     MDS_PATHS and deletes the contents of the document
-- (2) If the document does not exist yet, creates a new entry in the
--     MDS_PATHS table
--
-- Parameters:
--   newDocID     - the ID of the document or -1 if an error occurred
--   docVersion  - Document version, IN OUT parameter
--   fullPathName - fully qualified name of the document/package file
--   pathType     - 'DOCUMENT' for single document or 'PACKAGE' for package
--   docElemName  - Local name of the document element, null for Non-XML docs
--   docElemNSURI - NS URI of document element, null for Non-XML docs
--   xmlversion   - xml version
--   xmlencoding  - xml encoding
--   mdsGuid      - the GUID of the document
--   lowCN        - Low Cn value for the document.
--   documentID   - The document ID.
--   forceIt      - Force operation or not ?
--   checksum     - checksum for the document content.
--   lineageID    - lineageID for the document if seeded.
--   moTypeNSURI  - Element namespace of the base document for a customization
--                  document.  Null value for a base document or a package.
--   moTypeName   - Element name of the base document for a customization
--                  document.  Null value for a base document or a package.
--   contentType  - Document content stored as: 0 - Shredded XML
--                                              1 - BLOB
--                                              2 - Unshredded XML
--

drop procedure if exists  mds_prepareDocumentForInsert
/


CREATE PROCEDURE mds_prepareDocumentForInsert ( OUT   newDocID     BIGINT, 
                                                INOUT docVersion   INT, 
                                                OUT   contID       BIGINT, 
                                                      partitionID  INT, 
                                                      fullPathName VARCHAR($FULLNAME), 
                                                      pathType     VARCHAR($PATH_TYPE), 
                                                      docElemNSURI VARCHAR($ELEM_NSURI), 
                                                      docElemName  VARCHAR($ELEM_NAME), 
                                                      verComment   VARCHAR($VER_COMMENTS), 
                                                      xmlversion   VARCHAR($XML_VERSION), 
                                                      xmlencoding  VARCHAR($XML_ENCODING), 
                                                      mdsGuid      VARCHAR($GUID), 
                                                      lowCN        BIGINT, 
                                                      documentID   BIGINT, 
                                                      forceIt      INT,
                                                      checksum     BIGINT,
                                                      lineageID    BIGINT,
                                                      moTypeNSURI  VARCHAR($ELEM_NSURI), 
                                                      moTypeName   VARCHAR($ELEM_NAME),
                                                      contentType  SMALLINT) 
LANGUAGE SQL

BEGIN
    
    DECLARE versionNum INT;
    DECLARE prevVerLowCN BIGINT;
    DECLARE createReq INTEGER;
    DECLARE namePattern VARCHAR($FULLNAME);
    DECLARE patternLength INTEGER;

    SET createReq = documentID;

    IF createReq = -1 THEN 
    BEGIN
        DECLARE cnt INT;
            
        -- #(2669626) If the sequence, MDS_DOCUMENT_ID_S, is corrupt (which can
        -- happen if it gets reset), then createPath will raise a NO_DATA_FOUND
        -- exception.
        DECLARE EXIT HANDLER FOR SQLSTATE '$ERROR_CORRUPT_SEQUENCE'
        BEGIN
            RESIGNAL;
        END;
            
        DECLARE EXIT HANDLER FOR SQLSTATE '$ERROR_NAME_CONFLICT_NONTIP'
        BEGIN
            RESIGNAL;
        END;

        -- #(2456503) If we were unable to create the path, it is likely due
        -- to an already existing document or package
        DECLARE EXIT HANDLER FOR SQLSTATE '$ERROR_DOCUMENT_NAME_CONFLICT'
        BEGIN
            IF (pathType = '$TYPE_DOCUMENT') THEN
                RESIGNAL;
            ELSE
                RESIGNAL SQLSTATE '$ERROR_PACKAGE_NAME_CONFLICT'
                 SET MESSAGE_TEXT = 'ERROR_PACKAAGE_NAME_CONFLICT';
            END IF;
        END;

        -- Check if the document by this GUID already exists. Note: Document name
        -- check happens during createPath() leveraging a unique index
        IF ( mdsGuid IS NOT NULL AND LENGTH(mdsGuid) > 0) THEN
          IF ( LOCATE('/mdssys/sandbox/', fullPathName) > 0 ) THEN
              SET patternLength = LOCATE('/', fullPathName, CHAR_LENGTH('/mdssys/sandbox/')) + 1;
              SET namePattern = CONCAT(SUBSTR(fullPathName, 1, patternLength), '%');

              SELECT  count(*)  INTO cnt  FROM MDS_PATHS
              WHERE path_guid = mdsGuid
                    AND path_high_cn IS NULL
                    AND path_partition_id = partitionID 
                    AND path_type = pathType
                    AND path_fullname like namePattern;
          ELSE
              SELECT  count(*)  INTO cnt  FROM MDS_PATHS
                WHERE path_guid = mdsGuid
                  AND path_high_cn IS NULL
                  AND path_partition_id = partitionID 
                  AND path_type = pathType
                  AND path_fullname not like '/mdssys/sandbox/%';
          END IF;
          IF ( cnt <> 0 ) THEN
            SIGNAL SQLSTATE '$ERROR_GUID_CONFLICT'
                 SET MESSAGE_TEXT = 'ERROR_GUID_CONFLICT';
          END IF;
        END IF;
            
        SET versionNum = 1;
        
        -- #(5508200) - Ensure a document has unique version number after recreate
        -- Check if an older version already exists, get its version number.
        -- We want the creation to fail(leveraging the unique index) if the 
        -- document already exists hence get the version only deleted documents
        -- (i.e, having path_high_cn as non-null)
        IF (mdsGuid IS NOT NULL AND LENGTH(mdsGuid) > 0) THEN
          IF ( LOCATE('/mdssys/sandbox/', fullPathName) > 0 ) THEN
              SET patternLength = LOCATE('/', fullPathName, CHAR_LENGTH('/mdssys/sandbox/')) + 1;
              SET namePattern = CONCAT(SUBSTR(fullPathName, 1, patternLength), '%');

              SELECT COALESCE(MAX(path_version)+1, versionNum) INTO versionNum 
                FROM MDS_PATHS
                WHERE path_guid = mdsGuid AND 
                      path_high_cn IS NOT NULL AND 
                      path_partition_id = partitionID AND 
                      path_type = pathType AND
                      path_fullname like namePattern;
          ELSE
              SELECT COALESCE(MAX(path_version)+1, versionNum) INTO versionNum 
                FROM MDS_PATHS
                WHERE path_guid = mdsGuid AND 
                      path_high_cn IS NOT NULL AND 
                      path_partition_id = partitionID AND 
                      path_type = pathType AND
	              path_fullname not like '/mdssys/sandbox/%';
          END IF;
        ELSE
            SELECT COALESCE(MAX(path_version)+1, versionNum) INTO versionNum 
                FROM MDS_PATHS
                WHERE path_fullname = fullPathName AND 
                      path_high_cn IS NOT NULL AND 
                      path_partition_id = partitionID AND 
                      path_type = pathType;
        END IF;
            
        -- #(6446544) deleteAllVersions() would leave behind the tip after 
        -- changing it's path_version to -ve of path_low_cn. If we find this as 
        -- the existing version, we should ignore it and create this version 
        -- with version=1
        IF ( 1 > versionNum ) THEN

            SET versionNum = 1;
        END IF;

        -- Document does not exist yet, so create it now
        CALL mds_internal_createPath(newDocID,
                                     partitionID,
                                     documentID,
                                     fullPathName,
                                     pathType,
                                     docElemNSURI,
                                     docElemName,
                                     versionNum,
                                     verComment,
                                     xmlversion,
                                     xmlencoding,
                                     mdsGuid,
                                     checksum,
                                     lineageID,
                                     moTypeNSURI,
                                     moTypeName,
                                     contentType);
    END;
    ELSE
        IF (forceIt = 0) THEN 
            
            -- Check for any Concurrent operations first. If no Concrrency issues
            -- are detected then go ahead and grab the lock, create a new version
            -- of the document. If a concurrency issue is detected then an
            -- Exception will be raised in doConcurrencyCheck.
            CALL mds_doConcurrencyCheck(documentID,    -- DocID of the document.
                                        fullPathName,  -- Full Path of the document.
                                        lowCN,         -- LowCN of the grabbed document
                                        docVersion,  -- Version of the doc being saved
                                        partitionID);   -- partitionID

            -- Since the concurrency check has passed, there can't be
            -- any other changes after the current version, so compute the
            -- new version number as the next to current version.
            SET versionNum = docVersion + 1;       
        ELSE
            -- forceIt=TRUE, so no concurrency check will be performed.
            -- Other versions may have got created after the current version.
            --
            -- Lock the document with an single query that computes the current
            -- tip version and uses that to lock the document to make use
            -- of the unique index to improve performance (See #(7330932)
            --
            -- If somebody is modifyingit or locked it, lockDocument would fail
            -- and the newer version would not be created
            CALL mds_lockDocument(partitionID, 
                                  documentID,
		                  1,            -- use versionNum to lock.
		                  versionNum);  -- OUT parameter, version of the locked tip.

	    -- Since the concurrency check+lock / lock has been done, there can't be
   	    -- any other changes after the current version, so compute the
            -- new version number as the next to current version.

            SET versionNum = versionNum + 1;
        END IF;
        
        BEGIN
            -- #(2669626) If the sequence, MDS_DOCUMENT_ID_S, is corrupt 
            -- (which can happen if it gets reset), then createPath will 
            -- raise a NO_DATA_FOUND exception.
            DECLARE EXIT HANDLER FOR SQLSTATE '$ERROR_CORRUPT_SEQUENCE'
            BEGIN
                RESIGNAL;
            END;
    
            DECLARE EXIT HANDLER FOR SQLSTATE '$ERROR_NAME_CONFLICT_NONTIP'
            BEGIN
                RESIGNAL;
            END;

            -- #(2456503) If we were unable to create the path, it is likely due
            -- to an already existing document or package
            DECLARE EXIT HANDLER FOR SQLSTATE '$ERROR_DOCUMENT_NAME_CONFLICT'
            BEGIN
                IF (pathType = '$TYPE_DOCUMENT') THEN
                    RESIGNAL;
                ELSE
                    RESIGNAL SQLSTATE '$ERROR_PACKAGE_NAME_CONFLICT'
                         SET MESSAGE_TEXT = 'ERROR_PACKAGE_NAME_CONFLICT';
                END IF;
            END;
            
            CALL mds_internal_createPath(newDOCID,
                                         partitionID,
                                         documentID,
                                         fullPathName,
                                         pathType,
                                         docElemNSURI,
                                         docElemName,
                                         versionNum,
                                         verComment,
                                         xmlversion,
                                         xmlencoding,
                                         mdsGuid,
                                         checksum,
                                         lineageID,
                                         moTypeNSURI,
                                         moTypeName,
                                         contentType);

            -- Set the high_cn for the previous version to -1, it would be replaced

            -- by the actual commit number for the transaction by
            -- BaseDBMSConnection.commit()
            -- NOTE: List of tables updated done here should be kept in sync with
            -- those in deleteDocument()
            UPDATE MDS_PATHS SET path_high_cn = $INTXN_CN
                WHERE path_docid = newDocID AND 
                      path_version=(versionNum-1) AND
                      path_partition_id = partitionID;

            -- When multiple changes are done in a transaction, the depdnecies
            -- for all versions will have the same low_cn.
            --
            -- We delete all dependencies that are available instead of restricting
            -- to delete dependencies with dep_low_cn=<path_low_cn of prev version>
            -- This is because when a document is renamed the path_low_cn for the
            -- renamed document changes where as the dependencies are retained
            -- If this renamed document is not updated, we can not find the
            -- dependencies matching the low_cn of the renamed document version
            UPDATE MDS_DEPENDENCIES SET dep_high_cn=$INTXN_CN
                WHERE dep_child_docid = newDocID
                      AND dep_high_cn IS NULL
                      AND dep_partition_id = partitionID;
        END;
    END IF;
    
    -- Set the out variables (version and contentID) so that
    -- the content can be populated from the java code
    SELECT path_contentid INTO contID from MDS_PATHS
        WHERE path_docid = newDocID AND path_version = versionNum
              AND path_partition_id = partitionID;

    SET docVersion = versionNum;
END
/


--
 -- Check if a lineage entry exists for the given application and module in the
 -- partition. If it exists throw ERROR_LINEAGE_ALREADY_EXIST exception.
 -- otheriwse a lineage is created and returned.
 -- paritionID  - parition id
 -- application - application for which the lineage is required.
 -- module      - module which is part of the application.
 -- isSeeded    - 1 if it represents seeded documents entry, 0 otherwise.
 -- return lineageID
 --

drop procedure if exists mds_createLineageID
/

CREATE PROCEDURE mds_createLineageID(  partitionID  INT, 
                                       application  VARCHAR($DEPL_NAME), 
                                       module       VARCHAR($DEPL_NAME),
                                       isSeeded     SMALLINT,
                                    OUT lineageID   BIGINT)
LANGUAGE SQL

BEGIN    
    DECLARE cnt       BIGINT; 

    
    DECLARE EXIT HANDLER FOR 1062 
    BEGIN
       -- The exception has occured because of duplicate entries. Raise the 
       -- ERROR_LINEAGE_ALREADY_EXIST exception for the same.
       SIGNAL SQLSTATE '$ERROR_LINEAGE_ALREADY_EXIST'
             SET MESSAGE_TEXT = 'ERROR_LINEAGE_ALREADY_EXIST';
    END;
    

    SET @seqName = mds_getLineageSequenceName(partitionID);

    CALL mds_getNextSequence(lineageID, @seqName);
    
    INSERT INTO MDS_DEPL_LINEAGES
      (DL_PARTITION_ID, DL_LINEAGE_ID, DL_APPNAME,
       DL_DEPL_MODULE_NAME, DL_IS_SEEDED)
     VALUES
      (partitionID,
       lineageID,
       application,
       module,
       isSeeded);
END
/

