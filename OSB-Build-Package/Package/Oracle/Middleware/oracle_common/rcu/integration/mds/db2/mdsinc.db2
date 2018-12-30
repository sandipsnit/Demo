-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- MDSINCB.DB2 - MDS metadata services INternal Common Body
--
-- Notes:
--   For database portablity reason, please don't introduce any new public
--   functions.  There are a few limitations on db2 SQL PL functions.  Please
--   use procedure if proper.
--
-- MODIFIED    (MM/DD/YY)
-- jhsi         10/11/11 - Added param contentType to prepareDocForInsert
-- erwang       08/26/11 - Added moTypeNS and moTypeName to
--                         prepareDocForInsert()
-- vyerrama     02/22/11 - #(11817738) Excluded sandbox docs from purge.
-- erwang       09/21/10 - XbranchMerge erwang_bug-10056819 from main
-- erwang       09/20/10 - #(10056819) workaround issue we ran into in get
--                         nextval
-- vyerrama     07/01/10 - XbranchMerge vyerrama_sandbox_guid from main
-- gnagaraj     06/15/10 - #(9649970) Handle name conflict with deleted res
-- erwang       06/07/10 - XbranchMerge erwang_bug-9498962 from main
-- erwang       06/01/10 - #(9498962) Added retry upon unique key violation
-- erwang       04/27/10 - #(9625576) Added ERROR_NO_DATA_FOUND
-- erwang       04/02/10 - #(9555084) Added processCommitNew.
-- vyerrama     12/10/09 - Added createLineageID
-- erwang       03/08/10 - Improve locking timeout issue caused by Auto Purge.
-- erwang       12/30/09 - XbranchMerge erwang_bug-9152916 from main
-- erwang       02/17/10 - XbranchMerge erwang_bug-9377465 from main
-- erwang       02/11/10 - SQL Security and boundary situation handling
-- akrajend     01/19/10 - #(9233460) Get correct partition Id if the
--                         createPartition fails in cluster env.
-- akrajend     01/05/10 - Modify recreateSequence to recreate lineageID
--                         sequence with new lineage value.
-- erwang       01/19/10 - Added retries in locking document
-- erwang       12/10/09 - Remove ERROR_LOCK_TIMEOUT
-- erwang       12/02/09 - #(9152916) fix deadlock issue under db2 9.7
-- erwang       01/19/10 - XbranchMerge fix_psr_lock_timeout_issue from main
-- akrajend     01/19/10 - #(9233460) Get correct partition Id if the
--                         createPartition fails in cluster env.
-- erwang       08/27/09 - Use $ for defined variable
-- erwang       08/24/09 - Change variable substitution syntax
-- pwhaley      08/20/09 - Make temp purge table keep rows across commits.
-- erwang       08/17/09 - Increase the size of creator and fullname
-- erwang       08/06/09  - Fix deadlock issue in creating or updating docs by 
--                          multiple connections.
-- pwhaley      08/05/09  - Fix for sandbox deletion changes: ensure new
--                          package version is >= 1.
-- erwang       07/15/09  - Create.
--

-----------------------------------------------------------------------------
---------------------------- PRIVATE VARIABLES ------------------------------
-----------------------------------------------------------------------------

-- User-defined exceptions.
-- The error code will be encoded in text message of error 90000.  "'" must be 
-- used in define error code.  
-- The error codes should be kept in sync with mdsinsr.sql and all other scripts 
-- They must also be in sync with errorcode definitions in Java class Db2DB.

-- External Error Codes to Java layer
define ERROR_DOCUMENT_NAME_CONFLICT = 90100
@
define ERROR_PACKAGE_NAME_CONFLICT  = 90101
@
define ERROR_CORRUPT_SEQUENCE       = 90102
@
define ERROR_CONFLICTING_CHANGE     = 90103 
@
define ERROR_RESOURCE_BUSY          = 90104
@
define ERROR_GUID_CONFLICT          = 90105
@
define ERROR_RESOURCE_NOT_EXIST     = 90106
@
define ERROR_LINEAGE_ALREADY_EXIST  = 90107
@

-- Internal Error Codes
define ERROR_CHUNK_SIZE_EXCEEDED    = 90200
@
define ERROR_ARRAY_OUT_OF_BOUNDARY  = 90201
@

  
-- PATH_DOCID of "/" is assumed to be 0
define ROOT_DOCID                   = 0
@
  
-- Enumeration values for PATH_OPERATION values indicating the operation
-- performed on a path (version).
define DELETE_OP                   = 0
@
define CREATE_OP                   = 1
@
define UPDATE_OP                   = 2
@
define RENAME_OP                   = 3
@

-- Enumeration values for PATH_TYPE indicating the type of resource
define TYPE_DOCUMENT              = "DOCUMENT"
@
define TYPE_PACKAGE               = "PACKAGE"
@

-- Value used for PATH_HIGH_CN, PATH_LOW_CN when the changes are not yet
-- commited (i.e, in-transaction value). Since no other transaction would
-- see this value (as it is yet uncommited) it is not a problem for all
-- transactions to use this same number as the Commit Number for all CN
-- columns prior to commiting the changes.
-- When the changes are commited, processCommit() replaces this CN value
-- with the commit number generated for that transaction.
define INTXN_CN                   = -1
@

-- Integer constants to denote a true or a false value
define INT_TRUE                  =  1
@
define INT_FALSE                 = -1
@

-- constant variables defines the size 
define CREATOR                    = 240 
@
define ELEM_NSURI                 = 800
@
define ELEM_NAME                  = 127
@
define FULLNAME                   = 1800
@
define GUID                       = 36
@
define LABEL_NAME                 = 1000
@
define PARTITION_NAME             = 200
@
define PATH_NAME                  = 512 
@
define PATH_TYPE                  = 30
@
define VER_COMMENTS               = 800
@
define XML_VERSION                = 10
@
define XML_ENCODING               = 60
@

define SEQ_NAME                   = 256
@
define DEPL_NAME                  = 400
@

-- constant variable used for locktime out and retry time
define lcktimeout                 = 2
@

define retries                    = 3
@


CREATE VARIABLE mTempTablesDefined  SMALLINT DEFAULT 0
@

-- Initial global temp table
--
create PROCEDURE mds_internal_initialTempTables()

LANGUAGE SQL
BEGIN
    DECLARE GLOBAL TEMPORARY TABLE 
        session.mds_purge_paths(PPATH_CONTENTID    DECIMAL(31,0),
                        PPATH_LOW_CN       DECIMAL(31,0) NOT NULL,
                        PPATH_HIGH_CN      DECIMAL(31,0) NOT NULL,
                        PPATH_PARTITION_ID DECIMAL(31,0) NOT NULL)
        ON COMMIT PRESERVE ROWS
        NOT LOGGED;

    SET mTempTablesDefined = 1;
END
@

-- Has to be called to so procedures that access the temp table can be created. 
CALL mds_internal_initialTempTables()
@


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
SPECIFIC mds_internal_INSTR
DETERMINISTIC
NO EXTERNAL ACTION
CONTAINS SQL

BEGIN ATOMIC
  DECLARE pos      SMALLINT;
  DECLARE prevPos  SMALLINT;
 
  -- Handling special cases
  IF NULLIF(str1,'') IS NULL OR 
       NULLIF(str2,'') IS NULL THEN
     RETURN 0;
  END IF; 

  SET prevPos = 0;
  SET pos = LOCATE(str1, str2, 1, CODEUNITS32);

  WHILE pos <> 0 DO
    SET prevPos = pos;
    SET pos = LOCATE(str1, str2, prevPos + 1, CODEUNITS32);
  END WHILE;

  RETURN prevPos;
END
@


--
-- Delete sequence by name. 
--
-- Parameters:
--   seqName    -   Sequence Name. It should not exceed 30 characters long.
--
CREATE PROCEDURE mds_internal_deleteSequence (seqName VARCHAR(30) )
LANGUAGE SQL
SPECIFIC mds_internal_deleteSequence

BEGIN
    DECLARE dropSeqSql VARCHAR(256);
    
    DECLARE SEQUENCE_NOT_EXIST CONDITION FOR SQLSTATE '42704';

    DECLARE EXIT HANDLER FOR SEQUENCE_NOT_EXIST 
    BEGIN
    END;
    
    -- No need to drop a sequence without a name.
    IF TRIM(COALESCE(seqName,'')) = '' THEN
        RETURN;
    END IF; 
           
    SET dropSeqSql = 'DROP SEQUENCE ' || seqName;

    EXECUTE IMMEDIATE dropSeqSql;

END
@


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
CREATE PROCEDURE mds_lockDocument (IN  partitionID    DECIMAL(31,0), 
                                   IN  docID          DECIMAL(31,0), 
                                   IN  useVersionNum  SMALLINT, 
                                   OUT versionNum     DECIMAL(31,0) )
LANGUAGE SQL
SPECIFIC mds_lockDocument

BEGIN
    DECLARE tmpdocID DECIMAL(31,0);

    DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

    DECLARE P_SQLSTATE CHAR(5);

    DECLARE P_LOCK_TIMEOUT  INT DEFAULT -1;

    DECLARE COUNT    SMALLINT DEFAULT 1;

    DECLARE LOCKTIMEOUT_HAPPENED SMALLINT DEFAULT 0;

    DECLARE EXIT HANDLER FOR NOT FOUND
    BEGIN
        -- Restore lock timeout.
        SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;
    END;

    -- Continue handler for lock timeout and deadlock;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT SQLSTATE
            INTO P_SQLSTATE
         FROM sysibm.sysdummy1;

        SET COUNT = COUNT + 1;
        SET LOCKTIMEOUT_HAPPENED = 1;

        IF P_SQLSTATE = '40001' OR
               P_SQLSTATE = '57033' THEN
        BEGIN
            IF COUNT > $retries THEN
            BEGIN
                SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;

                RESIGNAL SQLSTATE '$ERROR_RESOURCE_BUSY';
            END;
            END IF;
        END;
        ELSE
        BEGIN
            SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;

            RESIGNAL;
        END;
        END IF;
    END;

    -- Save curent lock timeout
    SELECT CURRENT LOCK TIMEOUT INTO P_LOCK_TIMEOUT FROM SYSIBM.SYSDUMMY1;

    SET CURRENT LOCK TIMEOUT WAIT $lcktimeout;

    LOCK_RETRIES:
    REPEAT
      SET LOCKTIMEOUT_HAPPENED = 0;

      IF (useVersionNum) = 1 THEN
          SELECT path_docid, path_version
            INTO tmpdocID, versionNum
            FROM mds_paths
            WHERE path_docid = docID
              AND path_high_cn IS NULL
              AND path_partition_id = partitionID
            WITH RS USE AND KEEP UPDATE LOCKS;
      ELSE
          SELECT path_docid INTO tmpdocID
              FROM mds_paths
              WHERE path_docid = docID
                AND path_high_cn IS NULL
                AND path_partition_id = partitionID
              WITH RS USE AND KEEP UPDATE LOCKS;

      END IF;

      UNTIL LOCKTIMEOUT_HAPPENED = 0
    END REPEAT LOCK_RETRIES;

    -- Restore lock timeout.
    SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;
END
@


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
CREATE PROCEDURE mds_acquireWriteLock (partitionID   DECIMAL(31,0), 
                                       fullPathName  VARCHAR($FULLNAME), 
                                       mdsGuid       VARCHAR($GUID))
LANGUAGE SQL
SPECIFIC mds_acquireWriteLock1

BEGIN
    DECLARE tmpDocID      DECIMAL(31,0);
    DECLARE tmpVersionNum DECIMAL(31,0);

    DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

    DECLARE P_SQLSTATE CHAR(5);

    DECLARE P_LOCK_TIMEOUT  INT DEFAULT -1;

    DECLARE COUNT    SMALLINT DEFAULT 0;

    DECLARE LOCKTIMEOUT_HAPPENED SMALLINT DEFAULT 0;

    DECLARE EXIT HANDLER FOR NOT FOUND
    BEGIN
        -- Restore lock timeout.
        SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;

        RESIGNAL SQLSTATE '$ERROR_RESOURCE_NOT_EXIST';
    END;

    -- Exit handler for lock timeout and deadlock;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT SQLSTATE
            INTO P_SQLSTATE
         FROM sysibm.sysdummy1;

        SET LOCKTIMEOUT_HAPPENED = 1;

        SET COUNT = COUNT + 1;

        IF P_SQLSTATE = '40001' OR
               P_SQLSTATE = '57033' THEN
        BEGIN
            IF (COUNT >= $retries) THEN
            BEGIN
                SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;

                RESIGNAL SQLSTATE '$ERROR_RESOURCE_BUSY';
            END;
            END IF;
        END;
        ELSE
        BEGIN
            SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;

            RESIGNAL;
        END;
        END IF;
    END; 
        
    -- Save curent lock timeout
    SELECT CURRENT LOCK TIMEOUT INTO P_LOCK_TIMEOUT FROM SYSIBM.SYSDUMMY1;

    SET CURRENT LOCK TIMEOUT WAIT $lcktimeout;

    LOCK_RETRIES:
    REPEAT
      SET LOCKTIMEOUT_HAPPENED = 0;

      IF (mdsGuid IS NOT NULL) THEN 
        SELECT path_docid INTO tmpDocID
          FROM mds_paths
          WHERE path_guid = mdsGuid
                AND path_high_cn IS NULL 
                AND path_partition_id = partitionID
                AND path_type = '$TYPE_DOCUMENT'
          WITH RS USE AND KEEP UPDATE LOCKS;
      ELSE
        SELECT path_docid INTO tmpDocID
            FROM mds_paths
            WHERE path_fullname = fullPathName
                  AND path_high_cn IS NULL
                  AND path_partition_id = partitionID
                  AND path_type = '$TYPE_DOCUMENT'
            WITH RS USE AND KEEP UPDATE LOCKS;
      END IF;

      UNTIL LOCKTIMEOUT_HAPPENED = 0
    END REPEAT LOCK_RETRIES;

    -- Restore lock timeout.
    SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;
END
@

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
--
CREATE PROCEDURE mds_acquireWriteLock (partitionID   DECIMAL(31,0), 
                                       fullPathName  VARCHAR($FULLNAME)) 
LANGUAGE SQL
SPECIFIC mds_acquireWriteLock2

BEGIN

    CALL mds_acquireWriteLock(partitionID, fullPathName, NULL);

END
@

--
-- Generates a unique(within the repository partition) commit number(CN) for
-- the transaction
-- Parameters
--     commitNumber Generated Commit Number.
--     partitionID PartitionID for the repository partition
-- 
CREATE PROCEDURE mds_internal_generateCommitNumber ( OUT commitNumber   DECIMAL(31,0), 
                                                         partitionID    DECIMAL(31,0))
LANGUAGE SQL
SPECIFIC mds_internal_generateCommitNumber

BEGIN
    DECLARE count  SMALLINT;

    SET count = 0;

    WHILE count < 3 DO
      BEGIN
        DECLARE EXIT HANDLER FOR NOT FOUND
        BEGIN
            DECLARE UNIQUE_KEY_VIOLATION CONDITION FOR SQLSTATE '23505';

            DECLARE EXIT HANDLER FOR UNIQUE_KEY_VIOLATION 
            BEGIN
                -- No more than 3 tries.
                IF count >= 3 THEN
                    RESIGNAL;
                END IF;
            END;

            -- No txn has occured in this partition, intialize the transaction number
            -- for this partition and lock the row so that no another transaction
            -- can start committing parallely
            INSERT INTO MDS_TXN_LOCKS VALUES (partitionID,commitNumber);
                
            SELECT LOCK_TXN_CN INTO commitNumber
              FROM MDS_TXN_LOCKS
              WHERE LOCK_PARTITION_ID = partitionID
              WITH RS USE AND KEEP UPDATE LOCKS;

            RETURN;
        END;
        
        SET count = count + 1;

        -- Default value if no txn has occured in this partition
        SET commitNumber = 1;
        
        -- Return the next commit number after locking the commit number row so
        -- so that no another transaction can commit parallelly
        -- #(5460992) - Use an infinite wait. Using a NOWAIT in a loop
        -- is inefficient and does not help when large number of
        -- transactions are involved.
        SELECT LOCK_TXN_CN INTO commitNumber
          FROM MDS_TXN_LOCKS
          WHERE LOCK_PARTITION_ID = partitionID
          WITH RS USE AND KEEP UPDATE LOCKS;
        
        SELECT LOCK_TXN_CN INTO commitNumber FROM
            NEW TABLE(UPDATE MDS_TXN_LOCKS 
                         SET LOCK_TXN_CN = LOCK_TXN_CN + 1
                       WHERE LOCK_PARTITION_ID = partitionID);
        RETURN;
      END;
    END WHILE;
END
@

--
-- Convert a numeric value to its string format to be used as part of a 
-- object name.  Since schema object name cannot contain '-', '-' character
-- will be replaced by 'n' for a negative value.
--
-- Parameters:
--   value     - the numeric value to be converted to string format.
--
-- Returns:
--   The numeric value in string format.
--
CREATE FUNCTION mds_internal_toCharNamePart(value DECIMAL(31,0))
       RETURNS VARCHAR(50)
LANGUAGE SQL
SPECIFIC mds_internal_toCharNamePart
DETERMINISTIC
NO EXTERNAL ACTION

BEGIN ATOMIC
    IF (value IS NULL) THEN 
      RETURN '';
    END IF;
    
    IF (value < 0) THEN 
        RETURN 'n' || TRIM(B ' ' FROM CHAR(CAST(ABS(value) AS INTEGER)));
    ELSE
        RETURN TRIM(B ' ' FROM CHAR(CAST(value AS INTEGER)));
    END IF;
END
@


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
create PROCEDURE mds_checkDocumentExistence(OUT results     VARCHAR(4000),
         	                                partitionID DECIMAL(31,0),
		                                patterns    VARCHAR(4000)) 
LANGUAGE SQL
SPECIFIC mds_checkDocumentExistence

BEGIN
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

      RETURN;
  END IF;

  SET startPOS = 1;
  SET sepPOS   = -1;  -- Initialize with non 0 value.
  SET results  = '';
  SET prev     = 'NOT_FOUND';
  SET count    =  0;

  SET total_len = CHAR_LENGTH(patterns, CODEUNITS32);
    
  WHILE (sepPOS <> 0) DO
    SET sepPOS = LOCATE(',', patterns, startPOS, CODEUNITS32);
    
    IF (sepPOS = 0) THEN
      SET len = total_len - startPOS + 1;
    ELSE
      SET len = sepPOS - startPOS;
    END IF;

    SET pattern = SUBSTRING(patterns, startPOS, len, CODEUNITS32);

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
            SELECT 'FOUND' INTO found FROM SYSIBM.SYSDUMMY1
               WHERE EXISTS
                 (SELECT PATH_FULLNAME FROM MDS_PATHS
                   WHERE PATH_PARTITION_ID = partitionID
                   AND PATH_TYPE= 'DOCUMENT'
	               AND PATH_FULLNAME like pattern);
        END IF;
    END;

    -- Append ',' if results already contains values.
    IF (count > 0) THEN
        SET results = results || ',';
    END IF;

    SET results = results || found;
    SET prev = found;

    SET count = count + 1;

    -- Try to not overflow the results. (LEN('NOT_FOUND') + 1) * 400 = 4000 characters.
    IF (count >= 400) THEN
      RETURN;
    END IF;
      
    IF (sepPOS <> 0) THEN   
      -- Shift the position to the right of sepPOS.
      SET startPOS = sepPOS + 1;

      -- If the last character is ',', we will append one 'NOT_FOUND' and set setPOS to 0.
      IF (startPOS > total_len) THEN
        -- Add ',' and 'NOT_FOUND'.  We know there is value in results.
        SET results = results || ',' || 'NOT_FOUND'; 

        SET sepPOS = 0;   -- To exit in next loop.
      END IF;
    END IF;
  END WHILE;
END
@

-- Creates a transaction
--
-- Generates an unique commit number and inserts a new transaction
-- entry into mds_transactions
-- Parameters
--     commitNumber Commit Number.
--     partitionID  PartitionID for the repository partition
--     userName     User whose changes are being commited, can be null.
--

CREATE PROCEDURE mds_createNewTransaction(OUT commitNumber DECIMAL(31,0), 
                                              partitionID DECIMAL(31,0), 
                                              username VARCHAR($CREATOR))
LANGUAGE SQL
SPECIFIC mds_createNewTransaction

BEGIN
    -- Call generateCommitNumber()
    CALL mds_internal_generateCommitNumber(commitNumber,partitionID);
    
    -- Record the creator and time information for this transaction
    -- #(5570793) Store the transaction time as UTC so that it can be compared
    -- with mid-tier time correctly when mid-tier and repository are on 
    -- different timezones    
    INSERT INTO mds_transactions(txn_partition_id, txn_cn, txn_creator, txn_time)
         VALUES (partitionID,commitNumber,username,CURRENT TIMESTAMP - CURRENT TIMEZONE);

    RETURN;
END
@


-- Emulate Oracle's NUMTODSINTERVAL function.
-- Parameters
--   n      Value to be converted.
--   unit   Unit for the value
CREATE FUNCTION mds_internal_numtodsinterval(n    DECIMAL(31,0), 
                                             unit VARCHAR(60))
RETURNS DECIMAL(31,0)

LANGUAGE SQL
SPECIFIC mds_internal_numtodsinterval

DETERMINISTIC
NO EXTERNAL ACTION
CONTAINS SQL

  RETURN n*
    CASE UPPER(unit)
      WHEN 'DAY' THEN 24*3600
      WHEN 'HOUR' THEN 3600
      WHEN 'MINUTE' THEN 60
      ELSE 1
END
@

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

CREATE PROCEDURE mds_isPurgeRequired (     partitionID       DECIMAL(31,0), 
                                           autoPurgeInterval DECIMAL(31,0), 
                                       OUT purgeRequired     DECIMAL(31,0), 
                                       OUT dbSystemTime      TIMESTAMP )
LANGUAGE SQL
SPECIFIC mds_isPurgeRequired 

BEGIN
    DECLARE systemTime TIMESTAMP;
    DECLARE v_rows     INT DEFAULT 0;
    
    -- Store the system time in a local variable
    -- to remove any inaccuracies in using it in the query below
    -- #(5570793) - Store timestamps always as UTC
    SET systemTime = CURRENT TIMESTAMP - CURRENT TIMEZONE;
    
    -- #(6351111) As an optimization, the check will also update the
    -- the last_purge_time on the partition
    UPDATE mds_partitions
        SET partition_last_purge_time = systemTime
           WHERE partition_id = partitionID
                AND EXISTS(SELECT partition_last_purge_time
                               FROM mds_partitions
                               WHERE (systemTime - partition_last_purge_time) > 
                                   (mds_internal_numtodsinterval(autoPurgeInterval, 'SECOND'))
                                 AND partition_id = partitionID);
    -- Check if any row changed.
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF ( v_rows > 0 ) THEN
        SET purgeRequired = 1;
    ELSE
        SET purgeRequired = 0;
    END IF;

    SET dbSystemTime = systemTime;
END
@

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
CREATE PROCEDURE mds_internal_purgeMetadata (OUT numVersionsPurged DECIMAL(31,0), 
                                                 partitionID       DECIMAL(31,0), 
                                                 purgeCompareTime  TIMESTAMP, 
                                                 secondsToLive     DECIMAL(31,0), 
                                                 isAutoPurge       DECIMAL(31,0), 
                                             OUT commitNumber      DECIMAL(31,0) )
LANGUAGE SQL
SPECIFIC mds_internal_purgeMetadata

BEGIN
    
    DECLARE SQL_ROWCOUNT INTEGER;

    -- First, find the CN that is closest to the purge time (so that we
    -- don't have to do a full table scan of mds_tranasctions in a subquery)
    SELECT MAX(txn_cn)
        INTO commitNumber
        FROM mds_transactions
        WHERE txn_partition_id = partitionID
              AND txn_time < purgeCompareTime;
    
    -- #(6838583) Populate the mds_purge_data with details of versions that 
    -- qualify for purge
    INSERT INTO session.mds_purge_paths 
      (ppath_contentid, ppath_low_cn, ppath_high_cn, ppath_partition_id)
      (SELECT path_contentid, path_low_cn, path_high_cn, path_partition_id
         FROM mds_paths path
         WHERE path_low_cn <= commitNumber
           AND path_low_cn > 0          -- Don't purge non-committed (-1) 
           AND NOT EXISTS               -- Not covered by any label or non-tip
             (SELECT label_cn from mds_labels
                WHERE path.path_low_cn <= label_cn
                AND (path.path_high_cn > label_cn OR path.path_high_cn IS NULL)
                AND label_partition_id = path.path_partition_id)
         -- This check is required in the outer query again for not deleting the 
         -- tip when two versions of the document are created in the same
         -- transaction and hence have the same low_cn for the deleted and the
         -- tip version
         AND path_high_cn IS NOT NULL
         -- #(11817738) Sandbox apply needs older versions and since sandbox
         -- destroy deletes all sandbox content, no need to purge sandbox documents
         AND path_fullname NOT LIKE '/mdssys/sandbox/%'
         AND path_partition_id = partitionID);

    
    GET DIAGNOSTICS SQL_ROWCOUNT = ROW_COUNT;

    SET numVersionsPurged = SQL_ROWCOUNT;
    
    IF (numVersionsPurged = 0) THEN 
        
      -- Nothing to do if no qualifying paths were found
        RETURN;    
    END IF;
    
    -- Delete paths
    DELETE FROM mds_paths WHERE path_partition_id = partitionID AND
      EXISTS 
        (SELECT 'x' FROM session.mds_purge_paths
           WHERE path_low_cn = ppath_low_cn 
             AND path_high_cn = ppath_high_cn
             AND path_partition_id = ppath_partition_id);
    
    -- To avoid purging shared content, remove any purge row still whose content
    -- is still referenced by MDS_PATHS
    DELETE FROM session.mds_purge_paths WHERE ppath_partition_id = partitionID AND
      ppath_contentid IN 
        (SELECT path_contentid FROM mds_paths WHERE
           path_partition_id = partitionID);
    
    -- Delete streamed contents if any
    DELETE  FROM mds_streamed_docs WHERE sd_partition_id = partitionID
      AND sd_contentid IN
      (SELECT ppath_contentid FROM session.mds_purge_paths
         WHERE ppath_partition_id = partitionID);
    
    -- Delete dependencies if any
    DELETE FROM mds_dependencies WHERE dep_low_cn IN
      (SELECT ppath_low_cn FROM session.mds_purge_paths
         WHERE ppath_partition_id = partitionID);    
      
    -- #(7038905) Delete any unused transaction rows
    DELETE FROM mds_transactions WHERE txn_partition_id=partitionID 
      AND NOT EXISTS (SELECT 'x' FROM mds_paths 
                      WHERE path_partition_id = partitionID 
                      AND path_low_cn=txn_cn)
      AND NOT EXISTS (SELECT 'x' FROM mds_paths 
                      WHERE path_partition_id = partitionID
                      AND path_high_cn IS NOT NULL AND path_high_cn = txn_cn)
      -- #(8637322) Don't purge mds_txn rows used by labels
      AND NOT EXISTS (SELECT 'x' FROM mds_labels
                      WHERE label_partition_id = partitionID
                      AND label_cn = txn_cn);

    -- TODO Purge unused lineage rows
    -- Deferred from PS2 since the lineage could be in use. 
    -- See deployment optimization spec. for details. Need to revisit later.
    -- DELETE FROM mds_depl_lineages WHERE dl_partition_id=partitionID 
    --  AND NOT EXISTS (SELECT 'x' FROM mds_paths 
    --                  WHERE path_partition_id = partitionID 
    --                  AND path_lineage_id=dl_lineage_id);
    
    -- Content tables are purged in mds_internal_shredded.purgeMetadata()
    -- or mds_internal_xdb.purgeMetadata() from which this procedure is called
    -- Update the purgeTime if it manual purge, for auto-purge it is updated
    -- in processCommit() itself.
    IF (isAutoPurge = 0) THEN 
        
        UPDATE mds_partitions
              SET partition_last_purge_time = CURRENT TIMESTAMP - CURRENT TIMEZONE
              WHERE partition_id = partitionID;    
    END IF;

END
@


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
CREATE PROCEDURE mds_deletePackage (OUT result      DECIMAL(31,0), 
                                                 partitionID DECIMAL(31,0), 
                                                 pathID      DECIMAL(31,0))
LANGUAGE SQL
SPECIFIC mds_deletePackage 

BEGIN
    
    DECLARE childCount DECIMAL(31,0);
    
    SET result = 0;
    
    -- Check if the package is empty, otherwise it should not be deleted
    SELECT COUNT(*) INTO childCount FROM mds_paths
        WHERE path_owner_docid = pathID AND path_high_cn IS NULL
              AND path_partition_id = partitionID;

    IF (childCount = 0) THEN 
         UPDATE mds_paths SET path_high_cn=$INTXN_CN, 
                              path_operation=$DELETE_OP
             WHERE path_docid = pathId
                   AND path_type = '$TYPE_PACKAGE'
                   AND path_high_cn IS NULL
                   AND path_partition_id = partitionID ;

    ELSE
        SET result = -1;
    END IF;
    
    RETURN;
END
@


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

CREATE PROCEDURE mds_getDocumentID(OUT docID       DECIMAL(31,0),
                                       partitionID     DECIMAL(31,0), 
                                       fullPathName    VARCHAR($FULLNAME), 
                                       pathType        VARCHAR($PATH_TYPE))                                  
LANGUAGE SQL

SPECIFIC mds_getDocumentID

BEGIN
    DECLARE fullPath VARCHAR($FULLNAME);
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND 
    BEGIN
        SET docID = -1;
    END;

    SET docID = -1;
    SET fullPath = fullPathName;
    
    -- #(3234805) If the document does not start with a forward slash,
    -- then it's an invalid document name
    IF (LOCATE('/', fullPathName, 1, CODEUNITS32) <> 1) THEN 
        RETURN;
    END IF;
        
    IF ((fullPathName) = '/')
          AND ((pathType IS NULL)
             OR (pathType = '$TYPE_PACKAGE')) THEN 

        SET docID = $ROOT_DOCID;

        RETURN;
    END IF;
        
    IF (LOCATE('/', fullPath, CHAR_LENGTH(fullPath, CODEUNITS32)) > 0) THEN 
        SET fullPath = SUBSTRING(fullPath, 1, CHAR_LENGTH(fullPath, CODEUNITS32) - 1, CODEUNITS32);
    END IF;
        
    IF (pathType IS NULL ) THEN
        SELECT path_docid INTO docID
            FROM mds_paths
            WHERE path_fullname = fullPath
                  AND path_partition_id = partitionID
                  AND path_high_cn IS NULL;
    ELSE
        SELECT path_docid INTO docID
            FROM mds_paths
            WHERE path_fullname = fullPath
                  AND path_type = pathType
                  AND path_high_cn IS NULL
                  AND path_partition_id = partitionID;
    END IF;    
END
@


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

CREATE PROCEDURE mds_getDocumentIDByGUID (OUT docID        DECIMAL(31,0),
                                              partitionID  DECIMAL(31,0), 
                                              fullPathName VARCHAR($FULLNAME), 
                                              mdsGuid      VARCHAR($GUID), 
                                              pathType     VARCHAR($PATH_TYPE)) 
LANGUAGE SQL

SPECIFIC mds_getDocumentIDByGUID 

BEGIN
    DECLARE sqlStmt  VARCHAR(256);
    DECLARE fullPath VARCHAR($FULLNAME);
    DECLARE bindVar  SMALLINT;
    DECLARE c CURSOR FOR sqlPrep;

    DECLARE CONTINUE HANDLER FOR NOT FOUND 
    BEGIN
        SET docID = -1;
    END;

    SET docID    = -1;
    SET bindVar  = 2;
    SET fullPath = fullPathName;
        
    -- fullpath and/or mdsGuid must be non-null
    IF mdsGuid IS NULL THEN
        RETURN;
    END IF;
        
    -- #(3234805) If the document does not start with a forward slash,
    -- then it's an invalid document name
    IF (fullPathName IS NOT NULL
            AND LOCATE('/', fullPathName, 1, CODEUNITS32) <> 1) THEN 
        RETURN;
    END IF;
        
    IF ((fullPathName IS NOT NULL AND fullPathName = '/')
         AND ((pathType IS NULL) OR (pathType = '$TYPE_PACKAGE'))) THEN
        SET docID = $ROOT_DOCID;
        RETURN;
    END IF;
        
    -- #(3403125) Remove the trailing forward slash
    IF (fullPath IS NOT NULL
            AND LOCATE('/', fullPath, CHAR_LENGTH(fullPath, CODEUNITS32)) > 0) THEN 
        SET fullPath = SUBSTRING(fullPath, 1, CHAR_LENGTH(fullPath, CODEUNITS32) - 1, CODEUNITS32);
    END IF;
        
    SET sqlStmt = 'SELECT nvl(path_docid,-1) FROM mds_paths WHERE path_guid = ?' || 
                  ' AND path_partition_id = ? AND path_high_cn IS NULL';

    IF (fullPath IS NOT NULL
            AND CHAR_LENGTH(fullPath, CODEUNITS32) > 0) THEN 
        SET bindVar = bindVar + 1;
        SET sqlStmt = sqlStmt || ' AND path_fullname=?'; 
    END IF;
        
    IF (pathType IS NOT NULL
            AND CHAR_LENGTH(pathType, CODEUNITS32) > 0) THEN 
        SET bindVar = bindVar + 1;
        SET sqlStmt = COALESCE(sqlStmt, '') || ' AND path_type=?'; 
    END IF;
        
    PREPARE sqlPrep FROM sqlStmt;

    IF (bindVar = 2) THEN    
        OPEN c USING mdsGuid, partitionID;
    ELSEIF (bindVar = 3 AND fullPath IS NOT NULL) THEN
        OPEN c USING mdsGuid, partitionID, fullPath;
    ELSEIF (bindVar = 3 AND pathType IS NOT NULL) THEN
        OPEN c USING mdsGuid, partitionID, pathType;
    ELSEIF (bindVar =4) THEN
        OPEN c USING mdsGuid, partitionID,
                     fullpath, pathType;
    END IF;

    FETCH FROM c INTO docID;

    CLOSE c;
        
    RETURN;
END
@

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

CREATE PROCEDURE mds_internal_getDocumentIDByOwnerID (OUT docID       DECIMAL(31,0),
                                                          partitionID DECIMAL(31,0), 
                                                          name        VARCHAR($PATH_NAME), 
                                                          ownerID     DECIMAL(31,0), 
                                                          docType     VARCHAR($PATH_TYPE)) 
LANGUAGE SQL

SPECIFIC mds_internal_getDocumentIDByOwnerID

BEGIN
    DECLARE EXIT HANDLER FOR NOT FOUND 
    BEGIN
        SET docID = -1;
    END;

    -- Find the docid for the specified attributes
    SELECT  path_docid INTO docid
        FROM mds_paths
        WHERE path_name = name AND
               path_owner_docid = ownerID AND
               path_type = docType AND
               path_high_cn IS NULL AND
               path_partition_id = partitionID;

    RETURN;
END
@


--
-- For each document name, retrieve the corresponding document ID.
-- The document ID for docs[i] is in docIDs[i].  If no documentID
-- exists for a docs[i], then docIDs[i] = -1.
--
create PROCEDURE mds_getDocumentIDs(    partitionID     DECIMAL(31,0),
                                        docs            VARCHAR(4000),
                                    OUT docIDs          VARCHAR(4000))
LANGUAGE SQL
SPECIFIC mds_getDocumentIDs

BEGIN
  DECLARE startPOS     SMALLINT;
  DECLARE sepPOS       SMALLINT;
  DECLARE len          SMALLINT;
  DECLARE docID        DECIMAL(31,0);
  DECLARE fullName     VARCHAR($FULLNAME);

  SET startPOS = 1;
  SET sepPOS   = -1;  -- Initialize with non 0 value.
  SET docIDs   = '';
    
  WHILE(sepPOS <> 0) DO
    SET sepPOS = LOCATE(',', docs, startPOS, CODEUNITS32);
    
    IF (sepPOS = 0) THEN
      SET len = CHAR_LENGTH(docs, CODEUNITS32) - startPOS + 1;
    ELSE
      SET len = sepPOS - startPOS;
    END IF;

    SET fullName = SUBSTRING(docs, startPOS, len, CODEUNITS32);

    CALL mds_getDocumentID(docID, partitionID, fullName, '$TYPE_DOCUMENT');

    -- Add the ID to docIDs.
    IF (startPOS > 1) THEN
      SET docIDs = docIDs || ',';
    END IF;

    SET docIDs = docIDs || TRIM(B ' ' FROM CHAR(CAST(docID AS INTEGER)));
      
    -- Shift the position to the right of @sepPOS.
    IF (sepPOS <> 0) THEN
      SET startPOS = sepPOS + 1;
    END IF;
  END WHILE;
END
@



-- Given the document id, find the fully qualified document name
--
-- Parameters:
--   partitionID   - the partition where the document exists
--   docID         - the ID of the document
--
-- Returns:
--   the fully qualified document name
--

CREATE FUNCTION mds_getDocumentName (partitionID DECIMAL(31,0), 
                                     docid       DECIMAL(31,0) )
RETURNS VARCHAR($PATH_NAME)
LANGUAGE SQL
SPECIFIC mds_getDocumentName 
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA

BEGIN ATOMIC
    
    DECLARE name VARCHAR($FULLNAME) DEFAULT NULL;
    
    SET (name)
       = (SELECT path_fullname
          FROM mds_paths
          WHERE path_docid = docid
                AND path_partition_id = partitionID
                AND path_high_cn IS NULL);
    
    RETURN (name);
END
@

--
-- Recreates Document, Content and Lineage ID sequences with the minimum
-- documentID, contentID and lineageID set to the values provided as input
-- parameters.
--
-- Parameters:
--   partitionID  -  Partition ID.
--   minDocId     -  Minimum Document ID
--   minContentId -  Minimum Content ID
--   minLineageId -  Minimum Lineage ID
--

CREATE PROCEDURE mds_recreateSequences (partitionID  DECIMAL(31,0), 
                                        minDocId     DECIMAL(31,0), 
                                        minContentId DECIMAL(31,0),
                                        minLineageId DECIMAL(31,0) DEFAULT NULL)
LANGUAGE SQL
SPECIFIC recreateSequences 

BEGIN
    DECLARE createSeqStmt VARCHAR(256);
    
    DECLARE dropSeqStmt VARCHAR(256);
    
    -- #(5875276) create sequence cannot be part of txn, it will
    -- be included in AUTONOMOUS_TRANSACTION.
    CALL mds_internal_deleteSequence('MDS_DOC_ID_' || mds_internal_toCharNamePart(partitionID) || '_S');
    
    SET createSeqStmt = 'CREATE SEQUENCE MDS_DOC_ID_' || 
                        COALESCE(mds_internal_toCharNamePart(partitionID), '') || 
                        '_S  START WITH ' || TRIM(B ' ' FROM CHAR(CAST(minDocId AS INTEGER))) || 
                        ' INCREMENT BY 1';
    
    EXECUTE IMMEDIATE createSeqStmt;

    CALL mds_internal_deleteSequence('MDS_CONTENT_ID_' || mds_internal_toCharNamePart(partitionID) || '_S');
    
    SET createSeqStmt = 'CREATE SEQUENCE MDS_CONTENT_ID_' || 
                         mds_internal_toCharNamePart(partitionID) || 
                         '_S  START WITH ' || TRIM(B ' ' FROM CHAR(CAST(minContentId AS INTEGER))) || 
                         ' INCREMENT BY 1';
    
    EXECUTE IMMEDIATE createSeqStmt;
    
    IF (minLineageId IS NOT NULL) THEN
        CALL mds_internal_deleteSequence('MDS_LINEAGE_ID_' || mds_internal_toCharNamePart(partitionID) || '_S');
    
        SET createSeqStmt = 'CREATE SEQUENCE MDS_LINEAGE_ID_' || 
                             mds_internal_toCharNamePart(partitionID) || 
                             '_S  START WITH ' || TRIM(B ' ' FROM CHAR(CAST(minLineageId AS INTEGER))) || 
                             ' INCREMENT BY 1';
    
        EXECUTE IMMEDIATE createSeqStmt;
    END IF;

END
@


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

CREATE PROCEDURE mds_doConcurrencyCheck (docID          DECIMAL(31,0), 
                                         fullPathName   VARCHAR($FULLNAME), 
                                         lowCN          DECIMAL(31,0), 
                                         curVersion     DECIMAL(31,0), 
                                         partitionID    DECIMAL(31,0))
LANGUAGE SQL
SPECIFIC mds_doConcurrencyCheck

BEGIN
    
    DECLARE pDocID DECIMAL(31,0);
    
    DECLARE verToCheck DECIMAL(31,0);

    DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

    DECLARE P_SQLSTATE CHAR(5);

    DECLARE P_LOCK_TIMEOUT   INT DEFAULT -1;

    DECLARE COUNT    SMALLINT DEFAULT 0;

    DECLARE LOCKTIMEOUT_HAPPENED SMALLINT DEFAULT 0;

    DECLARE EXIT HANDLER FOR NOT FOUND 
    BEGIN
        SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;
    
        RESIGNAL SQLSTATE '$ERROR_CONFLICTING_CHANGE';
    END;

    -- Continue handler for lock timeout and deadlock;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT SQLSTATE
            INTO P_SQLSTATE
         FROM sysibm.sysdummy1;

        SET COUNT = COUNT + 1;

        SET LOCKTIMEOUT_HAPPENED = 1;

        IF P_SQLSTATE = '40001' OR
               P_SQLSTATE = '57033' THEN
        BEGIN
            IF (COUNT >= $retries) THEN
            BEGIN
                SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;

                RESIGNAL SQLSTATE '$ERROR_RESOURCE_BUSY';
            END;
            END IF;
        END;
        ELSE
        BEGIN
            SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;

            RESIGNAL;
        END;
        END IF;
    END;

    -- Save curent lock timeout
    SELECT CURRENT LOCK TIMEOUT INTO P_LOCK_TIMEOUT FROM SYSIBM.SYSDUMMY1;

    SET CURRENT LOCK TIMEOUT $lcktimeout;

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
      SET LOCKTIMEOUT_HAPPENED = 0;

      IF (curVersion = -1) THEN 
        SELECT MAX(path_version) INTO verToCheck FROM mds_paths
            WHERE path_docid = docID AND path_low_cn=lowCN
                  AND path_partition_id = partitionID;

        SELECT path_docid INTO pDocID FROM mds_paths
            WHERE path_docid = docID AND path_high_cn IS NULL  
                  AND path_partition_id = partitionID
                  AND NOT EXISTS (
          SELECT path_docid FROM mds_paths
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
         WITH RS USE AND KEEP UPDATE LOCKS;
      ELSE
      BEGIN
          DECLARE EXIT HANDLER FOR NOT FOUND
          BEGIN
              -- We will try to see if it is a conflit change or the resource is locked
              -- by querying path_high_cn = -1.
              SELECT path_docid INTO pDocID FROM mds_paths
                  WHERE path_docid = docID AND 
                      path_version = curVersion AND 
                      path_partition_id = partitionID AND 
                      path_high_cn = $INTXN_CN 
                ORDER BY path_version DESC FETCH FIRST 1 ROW ONLY
                WITH RS USE AND KEEP UPDATE LOCKS;
          END;

          -- Attempting to lock the current version conditional to NULL highCN
          -- is sufficient as it will be populated both when a newer version 
          -- is created (due to save/rename) or when current version
          -- is deleted. A no data found exception indicates concurrency
          SELECT path_docid INTO pDocID FROM mds_paths
            WHERE path_docid = docID AND 
                path_version = curVersion AND 
                path_partition_id = partitionID AND 
                path_high_cn IS NULL 
            WITH RS USE AND KEEP UPDATE LOCKS;
      END;
      END IF;

      UNTIL LOCKTIMEOUT_HAPPENED = 0
    END REPEAT LOCK_RETRIES;

    SET CURRENT LOCK TIMEOUT P_LOCK_TIMEOUT;
END
@

--
-- Delete sequences for the partition. 
--
-- Parameters:
--   partitionID  -  Partition ID.
--

CREATE PROCEDURE mds_deleteSequences (partitionID DECIMAL(31,0) )
LANGUAGE SQL
SPECIFIC mds_deleteSequences

BEGIN
    
    CALL mds_internal_deleteSequence('mds_doc_id_' || 
                                     mds_internal_toCharNamePart(partitionID) || '_s');
    
    CALL mds_internal_deleteSequence('mds_content_id_' || 
                                     mds_internal_toCharNamePart(partitionID) || '_s');
    
    CALL mds_internal_deleteSequence('mds_lineage_id_' || 
                                     mds_internal_toCharNamePart(partitionID) || '_s');
END
@


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

CREATE PROCEDURE mds_internal_createPartition( OUT partitionID     DECIMAL(31,0), 
                                               OUT partitionExists DECIMAL(31,0), 
                                                   partitionName   VARCHAR($PARTITION_NAME))
LANGUAGE SQL
SPECIFIC mds_internal_createPartition

BEGIN
    
    DECLARE createSeqStmt VARCHAR(256);
    DECLARE dropSeqStmt VARCHAR(256);

    DECLARE DUP_OBJECT_EXISTS CONDITION FOR SQLSTATE '42710';

    DECLARE EXIT HANDLER FOR SQLSTATE '23505'
    BEGIN
        -- #(7442627) Partition exists already (possibly because of
        -- a request from another thread), delete the sequences
        -- created and let the caller know it already exists
        CALL mds_deleteSequences(partitionID);
        
        -- #(9233460) Get correct partitionID of the newly created partition.
        SELECT partition_id INTO partitionID FROM mds_partitions
           WHERE partition_name = partitionName;

        SET partitionExists = $INT_TRUE;
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING, NOT FOUND
    BEGIN
      -- If exception happened, we will try to delete created
      -- sequences since the transaction will not be committed.

      CALL mds_deleteSequences(partitionID);
            
      RESIGNAL;
    END;
      
    VALUES NEXT VALUE FOR mds_partition_id_s INTO partitionID;
   
    BEGIN
        DECLARE EXIT HANDLER FOR DUP_OBJECT_EXISTS 
        BEGIN
            CALL mds_internal_deleteSequence('mds_doc_id_' ||  
                          mds_internal_toCharNamePart(partitionID) || '_s');

            EXECUTE IMMEDIATE createSeqStmt;
        END;
    

        -- create a new document ID sequence for this new partition.
        SET createSeqStmt =  'CREATE SEQUENCE mds_doc_id_' ||
                                   mds_internal_toCharNamePart(partitionID) || 
                                   '_s  START WITH 1 INCREMENT BY 1';
        
        EXECUTE IMMEDIATE createSeqStmt;
    END;

    BEGIN
        DECLARE EXIT HANDLER FOR DUP_OBJECT_EXISTS 
        BEGIN
            CALL mds_internal_deleteSequence('mds_content_id_' ||  
                       mds_internal_toCharNamePart(partitionID) || '_s');

            EXECUTE IMMEDIATE createSeqStmt;
        END;
    

        -- create a new document ID sequence for this new partition.
        SET createSeqStmt =  'CREATE SEQUENCE mds_content_id_' ||
                                   mds_internal_toCharNamePart(partitionID) || 
                                   '_s  START WITH 1 INCREMENT BY 1';
        
        EXECUTE IMMEDIATE createSeqStmt;
    END;
    
    BEGIN
        DECLARE EXIT HANDLER FOR DUP_OBJECT_EXISTS 
        BEGIN
            CALL mds_internal_deleteSequence('mds_lineage_id_' ||  
                       mds_internal_toCharNamePart(partitionID) || '_s');

            EXECUTE IMMEDIATE createSeqStmt;
        END;
    

        -- create a new document ID sequence for this new partition.
        SET createSeqStmt =  'CREATE SEQUENCE mds_lineage_id_' ||
                                   mds_internal_toCharNamePart(partitionID) || 
                                   '_s  START WITH 1 INCREMENT BY 1';
        
        EXECUTE IMMEDIATE createSeqStmt;
    END;
    
    
    -- Now create the entry in the partition-table, 
    -- store the partition_last_purge_time as current time to avoid an 
    -- immediate autopurge when the partition is populated.
      
    INSERT INTO mds_partitions(partition_id, 
                               partition_name,
                               partition_last_purge_time)
        VALUES (partitionID,
                partitionName,
                CURRENT TIMESTAMP - CURRENT TIMEZONE);
    
    -- #(5891638) Return value to indicate a new partition create.
    SET partitionExists = $INT_FALSE;    

    RETURN;
END
@


-- Does all the processing for commiting metadata changes made in a
-- transaction. Calling this method will ensure that the commit is always done
-- using a critical section. 
--
-- Parameters
--  commitNumber      Commit Number.
--  partitionID       PartitionID for the repository partition
--  userName          User whose changes are being commited, can be null.
--


CREATE PROCEDURE mds_internal_processCommitCS ( OUT commitNumber      DECIMAL(31,0), 
                                                    partitionID       DECIMAL(31,0), 
                                                    username          VARCHAR($CREATOR)) 
LANGUAGE SQL
SPECIFIC mds_internal_processCommitCS

BEGIN
    
    DECLARE docID      DECIMAL(31,0);

    DECLARE version    DECIMAL(31,0);

    DECLARE depID      DECIMAL(31,0);

    DECLARE labelName  VARCHAR($LABEL_NAME);

    DECLARE C_STMTSTR VARCHAR(512) DEFAULT '';
    
    DECLARE SQLCODE INTEGER DEFAULT 0;

    DECLARE C_FOUND INTEGER DEFAULT 0;
    
    DECLARE C_STMT STATEMENT;
    
    DECLARE c CURSOR FOR C_STMT;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET C_FOUND = SQLCODE;
    
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

    -- Documents, packages that were created,deleted or superceded by new version
    SET C_STMTSTR = 'SELECT PATH_DOCID, PATH_VERSION FROM MDS_PATHS ' ||
                     'WHERE PATH_PARTITION_ID=? AND ' ||
                     'PATH_LOW_CN=$INTXN_CN ' ||
                     'FOR READ ONLY';
    
    PREPARE C_STMT FROM C_STMTSTR;
            
    OPEN c USING partitionID;

    SET C_FOUND = 0;
    FETCH FROM c INTO docID, version;

    WHILE C_FOUND = 0 DO    
        UPDATE MDS_PATHS
          SET PATH_LOW_CN = commitNumber
          WHERE PATH_PARTITION_ID = partitionID AND
                PATH_DOCID = docID AND
                PATH_VERSION = version;            

      SET C_FOUND = 0;
      FETCH FROM c INTO docID, version;
    END WHILE;

    CLOSE c;

    SET C_STMTSTR = 'SELECT PATH_DOCID, PATH_VERSION FROM MDS_PATHS ' ||
                     'WHERE PATH_PARTITION_ID=? AND ' ||
                     'PATH_HIGH_CN=$INTXN_CN ' ||
                     'FOR READ ONLY';
    
    PREPARE C_STMT FROM C_STMTSTR;
            
    OPEN c USING partitionID;

    SET C_FOUND = 0;
    FETCH FROM c INTO docID, version;

    WHILE C_FOUND = 0 DO    
        UPDATE MDS_PATHS
          SET PATH_HIGH_CN = commitNumber
          WHERE PATH_PARTITION_ID = partitionID AND
                PATH_DOCID = docID AND
                PATH_VERSION = version; 

      SET C_FOUND = 0;
      FETCH FROM c INTO docID, version;
    END WHILE;

    CLOSE c;

    -- Dependencies that were created, deleted or superceded by new version
    SET C_STMTSTR = 'SELECT DEP_ID FROM MDS_DEPENDENCIES ' ||
                     'WHERE DEP_PARTITION_ID=? AND ' ||
                     'DEP_LOW_CN=$INTXN_CN ' ||
                     'FOR READ ONLY';
    
    PREPARE C_STMT FROM C_STMTSTR;
            
    OPEN c USING partitionID;

    SET C_FOUND = 0;
    FETCH FROM c INTO depID;

    WHILE C_FOUND = 0 DO    
        UPDATE MDS_DEPENDENCIES
          SET DEP_LOW_CN = commitNumber
          WHERE DEP_ID = depID;            

      SET C_FOUND = 0;
      FETCH FROM c INTO depID;
    END WHILE;

    CLOSE c;

    SET C_STMTSTR = 'SELECT DEP_ID FROM MDS_DEPENDENCIES ' ||
                     'WHERE DEP_PARTITION_ID=? AND ' ||
                     'DEP_HIGH_CN=$INTXN_CN ' ||
                     'FOR READ ONLY';
    
    PREPARE C_STMT FROM C_STMTSTR;
            
    OPEN c USING partitionID;

    SET C_FOUND = 0;
    FETCH FROM c INTO depID;

    WHILE C_FOUND = 0 DO    
        UPDATE MDS_DEPENDENCIES
          SET DEP_HIGH_CN = commitNumber
          WHERE DEP_ID = depID;            

      SET C_FOUND = 0;
      FETCH FROM c INTO depID;
    END WHILE;

    CLOSE c;

    -- Labels created in this transaction
    SET C_STMTSTR = 'SELECT LABEL_NAME FROM MDS_LABELS ' ||
                     'WHERE LABEL_PARTITION_ID=? AND ' ||
                     'LABEL_CN=$INTXN_CN ' ||
                     'FOR READ ONLY';
    
    PREPARE C_STMT FROM C_STMTSTR;
            
    OPEN c USING partitionID;

    SET C_FOUND = 0;
    FETCH FROM c INTO labelName;

    WHILE C_FOUND = 0 DO    
        UPDATE MDS_LABELS
          SET LABEL_CN = commitNumber
          WHERE LABEL_PARTITION_ID = partitionID AND
                LABEL_NAME = labelName;            

      SET C_FOUND = 0;
      FETCH FROM c INTO labelName;
    END WHILE;

    CLOSE c;
END
@


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

CREATE PROCEDURE mds_internal_processCommitNoCS ( OUT   commitNumber      DECIMAL(31,0), 
                                                        partitionID       DECIMAL(31,0), 
                                                        username          VARCHAR($CREATOR),
                                                        commitDBTime      TIMESTAMP,
                                                  OUT   isCSCommit        SMALLINT)
LANGUAGE SQL
SPECIFIC mds_internal_processCommitNoCS

BEGIN

    DECLARE labelName  VARCHAR($LABEL_NAME);

    DECLARE C_STMTSTR VARCHAR(512) DEFAULT '';
    
    DECLARE SQLCODE INTEGER DEFAULT 0;

    DECLARE C_FOUND INTEGER DEFAULT 0;
    
    DECLARE C_STMT STATEMENT;
    
    DECLARE c CURSOR FOR C_STMT;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET C_FOUND = SQLCODE;
    
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

    -- Labels created in this transaction
    SET C_STMTSTR = 'SELECT LABEL_NAME FROM MDS_LABELS ' ||
                     'WHERE LABEL_PARTITION_ID=? AND ' ||
                     'LABEL_CN=$INTXN_CN ' ||
                     'FOR READ ONLY';
    
    PREPARE C_STMT FROM C_STMTSTR;
            
    OPEN c USING partitionID;

    SET C_FOUND = 0;
    FETCH FROM c INTO labelName;

    WHILE C_FOUND = 0 DO    
        
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
            UPDATE MDS_LABELS
              SET LABEL_CN = commitNumber, LABEL_TIME = commitDBTime
              WHERE LABEL_PARTITION_ID = partitionID AND
                    LABEL_NAME = labelName;
        END IF;  

      SET C_FOUND = 0;
      FETCH FROM c INTO labelName;
    END WHILE;

    CLOSE c;
END
@


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

CREATE PROCEDURE mds_processCommitNew ( OUT   commitNumber      DECIMAL(31,0), 
                                              partitionID       DECIMAL(31,0), 
                                              username          VARCHAR($CREATOR), 
                                              autoPurgeInterval INT, 
                                              doPurgeCheck      SMALLINT, 
                                        OUT   purgeRequired     SMALLINT, 
                                        OUT   commitDBTime      TIMESTAMP,
                                        INOUT isCSCommit        SMALLINT)
LANGUAGE SQL
SPECIFIC mds_processCommitNew

BEGIN
    DECLARE systemTime TIMESTAMP;

    -- Store the system time in a local variable
    -- to remove any inaccuracies in using it in the query below
    -- #(5570793) - Store timestamps always as UTC
    SET systemTime = CURRENT TIMESTAMP - CURRENT TIMEZONE;
    
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
@


    
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


CREATE PROCEDURE mds_processCommit ( OUT commitNumber      DECIMAL(31,0), 
                                         partitionID       DECIMAL(31,0), 
                                         username          VARCHAR($CREATOR), 
                                         autoPurgeInterval INT, 
                                         doPurgeCheck      SMALLINT, 
                                     OUT purgeRequired     SMALLINT, 
                                     OUT commitDBTime      TIMESTAMP )
LANGUAGE SQL
SPECIFIC mds_processCommit

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
@



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
--   force        - Specify 0 if concurrent update check should not be done
--

CREATE PROCEDURE mds_deleteDocument (partitionID DECIMAL(31,0), 
                                     docID       DECIMAL(31,0), 
                                     lowCN       DECIMAL(31,0), 
                                     version     DECIMAL(31,0), 
                                     docName     VARCHAR($FULLNAME), 
                                     force       INTEGER)
LANGUAGE SQL
SPECIFIC mds_deleteDocument

BEGIN
    -- placeholder for call to lockDocument
    DECLARE tmpVersNum DECIMAL(31,0);
    
    IF (force = 0) THEN 
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
    UPDATE mds_paths SET path_high_cn=$INTXN_CN, 
                         path_operation=$DELETE_OP
        WHERE path_docid = docid
              AND path_type = '$TYPE_DOCUMENT' AND path_high_cn IS NULL
              AND path_partition_id = partitionID;
    
    -- Delete the dependencies originating from this docuent
    UPDATE mds_dependencies SET dep_high_cn=$INTXN_CN
        WHERE dep_child_docid = docid AND dep_high_cn IS NULL
              AND dep_partition_id = partitionID;
END
@

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

CREATE PROCEDURE mds_internal_deletePartition (partitionID DECIMAL(31,0))
LANGUAGE SQL
SPECIFIC mds_internal_deletePartition

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION, SQLWARNING
    BEGIN
    END;

    DELETE FROM mds_partitions WHERE partition_id = partitionID;
    DELETE FROM mds_paths WHERE path_partition_id = partitionID;
    DELETE FROM mds_dependencies WHERE dep_partition_id = partitionID;
    DELETE FROM mds_streamed_docs WHERE sd_partition_id = partitionID;
    DELETE FROM mds_transactions WHERE txn_partition_id = partitionID;
    DELETE FROM mds_txn_locks WHERE lock_partition_id = partitionID;
    DELETE FROM mds_sandboxes WHERE sb_partition_id = partitionID;
    DELETE FROM mds_labels WHERE label_partition_id = partitionID;
    DELETE FROM mds_depl_lineages WHERE dl_partition_id = partitionID;
    
    CALL mds_deleteSequences(partitionID);
END
@

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

CREATE PROCEDURE mds_getOrCreatePartitionID (OUT partitionID     DECIMAL(31,0), 
                                             OUT partitionExists SMALLINT, 
                                                 partitionName   VARCHAR($PARTITION_NAME))
LANGUAGE SQL
SPECIFIC mds_getOrCreatePartitionID

BEGIN
    
    DECLARE EXIT HANDLER FOR NOT FOUND
    BEGIN
        -- Create sequences in a seperate transaction.
        CALL mds_internal_createPartition(partitionID, partitionExists, partitionName);
    END;
    
    SELECT partition_id INTO partitionID
        FROM mds_partitions
        WHERE partition_name = partitionName;     

    -- #(5891638) Return value to indicate the partition exists.
    SET partitionExists = $INT_TRUE;

    RETURN;
END
@


--
-- Creates an entry in the mds_paths document.
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

CREATE PROCEDURE mds_internal_insertPath ( OUT docID         DECIMAL(31,0), 
                                               partitionID   DECIMAL(31,0), 
                                               documentID    DECIMAL(31,0), 
                                               pathname      VARCHAR($PATH_NAME), 
                                               fullPath      VARCHAR($FULLNAME), 
                                               ownerID       DECIMAL(31,0), 
                                               docType       VARCHAR($PATH_TYPE), 
                                               docElemNSURI  VARCHAR($ELEM_NSURI), 
                                               docElemName   VARCHAR($ELEM_NAME), 
                                               versionNum    DECIMAL(31,0), 
                                               verComment    VARCHAR($VER_COMMENTS), 
                                               xmlversion    VARCHAR($XML_VERSION), 
                                               xmlencoding   VARCHAR($XML_ENCODING), 
                                               mdsGuid       VARCHAR($GUID),
                                               checksum      DECIMAL(31,0) DEFAULT NULL,
                                               lineageID     DECIMAL(31,0) DEFAULT NULL,
                                               moTypeNSURI   VARCHAR($ELEM_NSURI) DEFAULT NULL,
                                               moTypeName    VARCHAR($ELEM_NAME) DEFAULT NULL,
                                               contentType   DECIMAL(31,0) DEFAULT NULL)
LANGUAGE SQL

SPECIFIC mds_internal_insertPath

BEGIN
    DECLARE contentID DECIMAL(31,0);
        
    DECLARE changeType DECIMAL(31,0);
        
    DECLARE sqlStmt   VARCHAR(256);
        
    DECLARE stmt      STATEMENT;

    DECLARE c_stmt    CURSOR FOR stmt;
        
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
    DECLARE EXIT HANDLER FOR SQLSTATE '23505'
    BEGIN
                
        DECLARE cnt DECIMAL(31,0);
                    
        -- Since no data was found, we know this was caused by either (1) or
        -- or (2).  If the following query returns no rows, then this can only
        -- be explained by a corrupt sequence; otherwise, we are dealing with
        -- a name conflict.
        DECLARE EXIT HANDLER FOR NOT FOUND 
        BEGIN 
          SELECT count(*) INTO cnt
            FROM mds_paths
            WHERE
                   path_name = pathname AND
                   path_owner_docid = ownerID AND
                   path_high_cn IS NULL AND
                   path_partition_id = partitionID;
            
            IF (cnt = 0) THEN
                RESIGNAL SQLSTATE '$ERROR_CORRUPT_SEQUENCE';
            ELSE
                RESIGNAL SQLSTATE '$ERROR_DOCUMENT_NAME_CONFLICT';
            END IF;
        END;

        SELECT path_docid INTO docID
            FROM mds_paths
            WHERE path_name = pathname AND
                  path_owner_docid = ownerID AND
                  path_type = docType AND
                  path_high_cn IS NULL AND
                  path_partition_id = partitionID;

        RESIGNAL SQLSTATE '$ERROR_DOCUMENT_NAME_CONFLICT';
            
    END;
        
    SET contentID = NULL;
        
    IF (docType = '$TYPE_DOCUMENT') THEN
        -- Get the next content ID in the given partition.

        SET sqlStmt = 'SELECT NEXT VALUE FOR mds_content_id_' || 
                            mds_internal_toCharNamePart(partitionID) || 
                            '_s FROM SYSIBM.SYSDUMMY1';
            
        PREPARE stmt FROM sqlStmt;
        OPEN c_stmt;
        FETCH c_stmt INTO contentID;
        CLOSE c_stmt;
            
        -- Newer versions of the document should use the same document ID
        IF (documentID = -1) THEN

            SET changeType = $CREATE_OP;
                
            -- Get the next document ID in the given partition.
            SET sqlStmt = 'SELECT NEXT VALUE FOR mds_doc_id_' || 
                                mds_internal_toCharNamePart(partitionID) || 
                                '_s FROM SYSIBM.SYSDUMMY1';

            PREPARE stmt FROM sqlStmt;
            OPEN c_stmt;
            FETCH c_stmt INTO docID;
            CLOSE c_stmt;
        ELSE

            SET changeType = $UPDATE_OP;
            SET docID = documentID;
        END IF;
    ELSE
        -- Get the next document ID for the package in the given partition.
        SET sqlStmt = 'SELECT NEXT VALUE FOR mds_doc_id_' || 
                          mds_internal_toCharNamePart(partitionID) || 
                          '_s FROM SYSIBM.SYSDUMMY1';

        PREPARE stmt FROM sqlStmt;
        OPEN c_stmt;
        FETCH c_stmt INTO docID;
        CLOSE c_stmt;
    END IF;
        
    -- New documents are created with high_cn set to -1, it is
    -- replaced with actual commit number corresponding to the transaction
    -- by BaseDBMSConnection.commit()
    INSERT INTO mds_paths
      (PATH_PARTITION_ID, PATH_NAME, PATH_DOCID, 
       PATH_OWNER_DOCID, PATH_TYPE,
       PATH_DOC_ELEM_NSURI, PATH_DOC_ELEM_NAME,
       PATH_FULLNAME, PATH_GUID,
       PATH_LOW_CN, PATH_HIGH_CN, PATH_OPERATION, PATH_CONTENTID,
       PATH_VERSION, PATH_VER_COMMENT,
       PATH_XML_VERSION, PATH_XML_ENCODING, PATH_CONT_CHECKSUM, PATH_LINEAGE_ID,
       PATH_DOC_MOTYPE_NSURI, PATH_DOC_MOTYPE_NAME, PATH_CONTENT_TYPE)
    VALUES
      (partitionID, pathname, docID, ownerID, docType,
       docElemNSURI, docElemName,
       fullPath, mdsGuid,
       $INTXN_CN, null, changeType, contentID,
       versionNum, verComment,
       xmlversion, xmlencoding, checksum, lineageID,
       moTypeNSURI, moTypeName, contentType);

    RETURN;
END
@



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

CREATE PROCEDURE mds_internal_createPkgImmediate (OUT docID         DECIMAL(31,0),
                                                      partitionID   DECIMAL(31,0), 
                                                      fullPathName  VARCHAR($FULLNAME), 
                                                      pkgLocalName  VARCHAR($FULLNAME), 
                                                      pkgDocID      DECIMAL(31,0), 
                                                      verNum        DECIMAL(31,0)) 
LANGUAGE SQL

SPECIFIC mds_internal_createPkgImmediate

BEGIN    
    SET docID = 0;
    
    CALL mds_internal_insertPath(docID,           -- Returns DOCID for the inserted pkg path.
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
                                 null);           -- GUID

    -- The method is marked as an AUTONOMOUS_TRANSACTION so that
    -- this commit does not affect any changes to the metadata made so far
    -- and to not result in a failure when part of distributed transaction
    --COMMIT;
    
    RETURN;
END
@



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

CREATE PROCEDURE mds_internal_createPackageRecursive (OUT pkgDocID     DECIMAL(31,0),
                                                          partitionID  DECIMAL(31,0), 
                                                          fullPathName VARCHAR($FULLNAME)) 
LANGUAGE SQL

SPECIFIC mds_internal_createPackageRecursive

BEGIN
    DECLARE parentPkgName   VARCHAR($FULLNAME);
    
    DECLARE newVersionNum   DECIMAL(31,0) DEFAULT 1;

    DECLARE strSQL          VARCHAR(256) DEFAULT '';
    
    -- Declared with size of path_fullname to allow long pathname to 
    -- fail with COLWIDTH_EXCEED_ERROR exception
    DECLARE pkgLocalName    VARCHAR($FULLNAME);
    
    DECLARE lastSlashpos    SMALLINT DEFAULT 1.0;
    
    DECLARE C_STMTSTR VARCHAR(512) DEFAULT 
             'SELECT path_docid FROM mds_paths WHERE path_fullname = ? AND path_type = ''$TYPE_PACKAGE'' AND path_partition_id = ? AND path_high_cn IS NULL';
    
    DECLARE C_FOUND INTEGER DEFAULT NULL;
    
    DECLARE SQLCODE INTEGER DEFAULT 0;
    
    DECLARE C_STMT STATEMENT;
    
    DECLARE c CURSOR FOR C_STMT;
    
    PREPARE C_STMT FROM C_STMTSTR;
    
    SET pkgDocID = 0;

    IF( fullPathName = '/' ) THEN
        SET pkgDocID = $ROOT_DOCID;
        RETURN;    
    END IF;
        
    -- Does this package already exist
    OPEN c USING fullPathName, partitionID;
        
    BEGIN
       DECLARE CONTINUE HANDLER FOR NOT FOUND SET C_FOUND = SQLCODE;

       SET C_FOUND = 0;
       FETCH FROM c INTO pkgDocID;
    END;
        
    -- Insert the package if it does not already exist
    IF C_FOUND <> 100 THEN 
        CLOSE c;
        RETURN;
    END IF;
            
    -- #(5508200) - If this is a recreate then continue the version number 
    -- of the logically deleted resource instead of 1 
    SELECT COALESCE(MAX(path_version)+1, 1) INTO newVersionNum
        FROM mds_paths
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
            
    SET pkgLocalName = SUBSTRING(fullPathName, lastSlashpos + 1, CODEUNITS32);

    IF (lastSlashpos > 1) THEN 
                
        SET parentPkgName = SUBSTRING(fullPathName, 1, lastSlashpos - 1, CODEUNITS32);
    ELSE

        -- For example: for /mypkg, pkg is '/' and pkgLocalName is 'mypkg'
        SET parentPkgName = '/';
    END IF;
            
    -- #(6011472) Recursively check existence of parent packages starting
    -- from immediate parent package. This is more efficient than doing
    -- a topdown check as it avoids query for all higher parent packages
    -- once an existing parent is found.
    
    SET strSQL = 'CALL mds_internal_createPackageRecursive(?,?,?)'; 

    PREPARE stmSQL FROM strSQL;

    EXECUTE stmSQL INTO pkgDocID USING partitionID, parentPkgName;
  
    CALL mds_internal_createPkgImmediate(pkgDocID, 
                                         partitionID,
                                         fullPathName,
                                         pkgLocalName,
                                         pkgDocID,
                                         newVersionNum);
        
    CLOSE c;      
      
    RETURN;                                                           
END
@



--
-- Creates an entry in the mds_paths table for the MDS document.
-- The full name of the document must be specified.  Any packages
-- which do not already exist will be created as well.
--
-- Note that absPathName cannot be over 4000 bytes long, otherwise,
-- an "ORA-06502: PL/SQL: numeric or value error: character string 
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

CREATE PROCEDURE mds_internal_createPath (OUT  docID         DECIMAL(31,0),
                                               partitionID   DECIMAL(31,0), 
                                               documentID    DECIMAL(31,0), 
                                               absPathName   VARCHAR($FULLNAME), 
                                               docType       VARCHAR($PATH_TYPE), 
                                               docElemNSURI  VARCHAR($ELEM_NSURI), 
                                               docElemName   VARCHAR($ELEM_NAME), 
                                               versionNum    DECIMAL(31,0), 
                                               verComment    VARCHAR($VER_COMMENTS), 
                                               xmlversion    VARCHAR($XML_VERSION), 
                                               xmlencoding   VARCHAR($XML_ENCODING), 
                                               mdsGuid       VARCHAR($GUID),
                                               checksum      DECIMAL(31,0) DEFAULT NULL,
                                               lineageID     DECIMAL(31,0) DEFAULT NULL,
                                               moTypeNSURI   VARCHAR($ELEM_NSURI) DEFAULT NULL,
                                               moTypeName    VARCHAR($ELEM_NAME) DEFAULT NULL, 
                                               contentType   DECIMAL(31,0) DEFAULT NULL)
LANGUAGE SQL

SPECIFIC mds_internal_createPath 

BEGIN
    
    DECLARE ownerDocID    DECIMAL(31,0) DEFAULT 0;
    
    DECLARE fullPathName  VARCHAR(4000);
    
    DECLARE packageName   VARCHAR($FULLNAME);
    
    -- Declared with size of path_fullname to allow long pathname to 
    -- fail with COLWIDTH_EXCEED_ERROR exception
    DECLARE docName       VARCHAR($FULLNAME);
    
    DECLARE lastSlashpos  INTEGER;

    SET docID = 0;
        
    SET fullPathName = absPathName;
    
    -- Ensure that the pathName starts with a slash
    IF (LOCATE('/', fullPathName, CODEUNITS32) <> 1) THEN
        
        SET docID = -1;
        RETURN;
    END IF;
    
    
    -- #(3403125) Remove the trailing forward slash if any
    IF (LOCATE('/', fullPathName, CHAR_LENGTH(fullPathName,CODEUNITS32), CODEUNITS32) > 0)  THEN

        SET fullPathName = SUBSTRING(fullPathName, 1, CHAR_LENGTH(fullPathName, CODEUNITS32) - 1, CODEUNITS32);
    
    END IF;
    
    SET lastSlashpos = mds_internal_INSTR('/', fullPathName);
    
    SET docName = SUBSTRING(fullPathName, lastSlashpos + 1, CODEUNITS32);
    
    IF (lastSlashpos > 1) THEN 
        
        SET packageName = SUBSTRING(fullPathName, 1, lastSlashpos - 1, CODEUNITS32);
    ELSE

        -- Root level resource Example: /page1.xml or /mypkg
        SET packageName = '/';
    END IF;
    
    -- Create MDS_PATHS entry for the package
    CALL mds_internal_createPackageRecursive(ownerDocID, partitionID, packageName);
    
    -- Now create the MDS_PATHS entry for the document
    CALL mds_internal_insertPath(docId,         -- returns new id for the inserted path.
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

    RETURN;
END
@

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

CREATE PROCEDURE mds_renameDocument (partitionID    DECIMAL(31,0), 
                                     p_oldDocId     DECIMAL(31,0), 
                                     p_fullpath     VARCHAR($FULLNAME), 
                                     p_newName      VARCHAR($FULLNAME), 
                                     p_newDocName   VARCHAR($PATH_NAME), 
                                     p_vercomment   VARCHAR($VER_COMMENTS), 
                                     p_xmlversion   VARCHAR($XML_VERSION), 
                                     p_xmlencoding  VARCHAR($XML_ENCODING), 
                                     p_pkgChange    DECIMAL(31,0) )
LANGUAGE SQL

SPECIFIC mds_renameDocument

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

    DECLARE docID            DECIMAL(31,0);
    DECLARE parentDocID      DECIMAL(31,0);
    DECLARE oldPartnID       DECIMAL(31,0);
    DECLARE oldGuid          VARCHAR($GUID);
    DECLARE oldDocElemName   VARCHAR($ELEM_NAME);
    DECLARE oldDocElemNS     VARCHAR($ELEM_NSURI);
    DECLARE oldContID        DECIMAL(31,0);
    DECLARE oldVerNum        DECIMAL(31,0);
    DECLARE oldXmlVer        VARCHAR($XML_VERSION);
    DECLARE oldXmlEnc        VARCHAR($XML_ENCODING);
    DECLARE tmpVersionNum    DECIMAL(31,0);
    DECLARE oldChkSum        DECIMAL(31,0);
    DECLARE oldMoTypeName    VARCHAR($ELEM_NAME);
    DECLARE oldMoTypeNS      VARCHAR($ELEM_NSURI);
    DECLARE oldContentType   DECIMAL(31,0);

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
        FROM mds_paths WHERE path_docid=p_oldDocId
           AND path_partition_id=partitionID
           AND path_high_cn IS NULL;

    IF p_pkgChange = 1 THEN 
        -- #(8306901) create recursive package
        IF (LOCATE('/', fullPathName, CHAR_LENGTH(fullPathName, CODEUNITS32), CODEUNITS32) > 0)  THEN

            SET fullPathName = SUBSTRING(fullPathName, 1, 
                                         CHAR_LENGTH(fullPathName, CODEUNITS32) - 1, CODEUNITS32);
        END IF;
            
        SET lastSlashpos = mds_internal_INSTR('/', fullPathName);
    
        IF ( lastSlashpos > 1 ) THEN

            SET packageName = SUBSTRING(fullPathName, 1, lastSlashpos - 1, CODEUNITS32);
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
    UPDATE mds_paths SET path_high_cn=$INTXN_CN
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
        FROM mds_paths
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
    INSERT INTO mds_paths
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
@


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
--   force        - Force operation or not ?
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

CREATE PROCEDURE mds_prepareDocumentForInsert ( OUT   newDocID     DECIMAL(31,0), 
                                                INOUT docVersion   DECIMAL(31,0), 
                                                OUT   contID       DECIMAL(31,0), 
                                                      partitionID  DECIMAL(31,0), 
                                                      fullPathName VARCHAR($FULLNAME), 
                                                      pathType     VARCHAR($PATH_TYPE), 
                                                      docElemNSURI VARCHAR($ELEM_NSURI), 
                                                      docElemName  VARCHAR($ELEM_NAME), 
                                                      verComment   VARCHAR($VER_COMMENTS), 
                                                      xmlversion   VARCHAR($XML_VERSION), 
                                                      xmlencoding  VARCHAR($XML_ENCODING), 
                                                      mdsGuid      VARCHAR($GUID), 
                                                      lowCN        DECIMAL(31,0), 
                                                      documentID   DECIMAL(31,0), 
                                                      force        DECIMAL(31,0),
                                                      checksum     DECIMAL(31,0) DEFAULT NULL,
                                                      lineageID    DECIMAL(31,0) DEFAULT NULL,
                                                      moTypeNSURI  VARCHAR($ELEM_NSURI) DEFAULT NULL,
                                                      moTypeName   VARCHAR($ELEM_NAME) DEFAULT NULL,
                                                      contentType  DECIMAL(31,0) DEFAULT NULL)
LANGUAGE SQL
SPECIFIC mds_prepareDocumentForInsert

BEGIN
    
    DECLARE versionNum DECIMAL(31,0);
    DECLARE prevVerLowCN DECIMAL(31,0);
    DECLARE createReq INTEGER;
    
    DECLARE SQLCODE   INT DEFAULT 0;
    DECLARE SQLSTATE  CHAR(5) DEFAULT '00000';
    DECLARE ERRMSG    VARCHAR(100) DEFAULT '';

    DECLARE namePattern VARCHAR($FULLNAME);
    DECLARE patternLength INTEGER;
    SET createReq = documentID;

    IF createReq = -1 THEN 
    BEGIN
        DECLARE cnt DECIMAL(31,0);
            
        -- #(2669626) If the sequence, MDS_DOCUMENT_ID_S, is corrupt (which can
        -- happen if it gets reset), then createPath will raise a NO_DATA_FOUND
        -- exception.
        DECLARE EXIT HANDLER FOR SQLSTATE '$ERROR_CORRUPT_SEQUENCE'
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
                RESIGNAL SQLSTATE '$ERROR_PACKAGE_NAME_CONFLICT';
            END IF;
        END;

        -- Signal Resource busy error if we ran into timeout or deadlock
        DECLARE EXIT HANDLER FOR SQLSTATE '40001', SQLSTATE '57033'
        BEGIN
            SET ERRMSG = 'SQLSTATE: ' ||SQLSTATE ||
                         ',SQLCODE: ' || CHAR(SQLCODE);

            RESIGNAL SQLSTATE '$ERROR_RESOURCE_BUSY' 
                       SET MESSAGE_TEXT = ERRMSG;

        END; 

        -- Check if the document by this GUID already exists. Note: Document name
        -- check happens during createPath() leveraging a unique index
        IF ( mdsGuid IS NOT NULL AND LENGTH(mdsGuid) > 0) THEN
          IF ( LOCATE('/mdssys/sandbox/', fullPathName) > 0 ) THEN
              SET patternLength = LOCATE('/', fullPathName, LENGTH('/mdssys/sandbox/')) + 1;
              SET namePattern = SUBSTR(fullPathName, 1, patternLength) || '%';

              SELECT  count(*)  INTO cnt  FROM mds_paths
              WHERE path_guid = mdsGuid
                    AND path_high_cn IS NULL
                    AND path_partition_id = partitionID 
                    AND path_type = pathType
                    AND path_fullname like namePattern;
          ELSE
              SET namePattern = '/mdssys/sandbox/%';

              SELECT  count(*)  INTO cnt  FROM mds_paths
                WHERE path_guid = mdsGuid
                  AND path_high_cn IS NULL
                  AND path_partition_id = partitionID 
                  AND path_type = pathType
                  AND path_fullname not like namePattern;
          END IF;
          IF ( cnt <> 0 ) THEN
            SIGNAL SQLSTATE '$ERROR_GUID_CONFLICT';
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
              SET patternLength = LOCATE('/', fullPathName, LENGTH('/mdssys/sandbox/')) + 1;
              SET namePattern = SUBSTR(fullPathName, 1, patternLength) || '%';

              SELECT COALESCE(MAX(path_version)+1, versionNum) INTO versionNum 
                FROM mds_paths
                WHERE path_guid = mdsGuid AND 
                      path_high_cn IS NOT NULL AND 
                      path_partition_id = partitionID AND 
                      path_type = pathType AND
                      path_fullname like namePattern;
          ELSE
              SET namePattern = '/mdssys/sandbox/%';

              SELECT COALESCE(MAX(path_version)+1, versionNum) INTO versionNum 
                FROM mds_paths
                WHERE path_guid = mdsGuid AND 
                      path_high_cn IS NOT NULL AND 
                      path_partition_id = partitionID AND 
                      path_type = pathType AND
	              path_fullname not like namePattern;
          END IF;
        ELSE
            SELECT COALESCE(MAX(path_version)+1, versionNum) INTO versionNum 
                FROM mds_paths
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
        IF (force = 0) THEN 
            
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
            -- force=TRUE, so no concurrency check will be performed.
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
            -- #(2669626) If the sequence, MDS_DOCUMENT_ID_S, is corrupt (which can
            -- happen if it gets reset), then createPath will raise a NO_DATA_FOUND
            -- exception.
            DECLARE EXIT HANDLER FOR SQLSTATE '$ERROR_CORRUPT_SEQUENCE'
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
                    RESIGNAL SQLSTATE '$ERROR_PACKAGE_NAME_CONFLICT';
                END IF;
            END;

            -- Signal Resource busy error if we ran into timeout or deadlock
            DECLARE EXIT HANDLER FOR SQLSTATE '40001', SQLSTATE '57033'
            BEGIN
                SET ERRMSG = 'SQLSTATE: ' ||SQLSTATE ||
                             ',SQLCODE: ' || CHAR(SQLCODE);

                RESIGNAL SQLSTATE '$ERROR_RESOURCE_BUSY' 
                           SET MESSAGE_TEXT = ERRMSG;

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
            UPDATE mds_paths SET path_high_cn = $INTXN_CN
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
            UPDATE mds_dependencies SET dep_high_cn=$INTXN_CN
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
@

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

CREATE PROCEDURE mds_createLineageID(  partitionID  DECIMAL(31,0), 
                                       application  VARCHAR($DEPL_NAME), 
                                       module       VARCHAR($DEPL_NAME),
                                       isSeeded     DECIMAL(31,0),
                                    OUT lineageID   DECIMAL(31,0))
LANGUAGE SQL
SPECIFIC mds_createLineage

BEGIN    
    DECLARE sqlStmt   VARCHAR(256);
    DECLARE cnt       DECIMAL(31,0); 
    DECLARE stmt      STATEMENT;
    DECLARE c_stmt    CURSOR FOR stmt;
    
    DECLARE EXIT HANDLER FOR SQLSTATE '23505'
    BEGIN
       -- The exception has occured because of duplicate entries. Raise the 
       -- ERROR_LINEAGE_ALREADY_EXIST exception for the same.
       SIGNAL SQLSTATE '$ERROR_LINEAGE_ALREADY_EXIST';
    END;
    
    SET sqlStmt = 'SELECT NEXT VALUE FOR mds_lineage_id_' || mds_internal_toCharNamePart(partitionID)
                   || '_s FROM SYSIBM.SYSDUMMY1';

    PREPARE stmt FROM sqlStmt;
    OPEN c_stmt;
    FETCH c_stmt INTO lineageID;
    CLOSE c_stmt;
    
    INSERT INTO mds_depl_lineages
      (DL_PARTITION_ID, DL_LINEAGE_ID, DL_APPNAME,
       DL_DEPL_MODULE_NAME, DL_IS_SEEDED)
     VALUES
      (partitionID,
       lineageID,
       application,
       module,
       isSeeded);
    RETURN;
END
@



--COMMIT
--@





