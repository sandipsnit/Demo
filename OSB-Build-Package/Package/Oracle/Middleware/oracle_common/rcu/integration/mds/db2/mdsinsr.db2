-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- MDSINSRB.db2 - MDS INternal Shredded Repository Body
--
--
-- MODIFIED  (MM/DD/YY)
-- erwang     10/19/12 - #(14703842) Using AUTONOMOUS in getNamespaceID()
--                       to commit the inserted NS row. 
-- erwang     10/19/12 - XbranchMerge erwang_bug-14703842 from main
-- erwang     05/29/12 - XbranchMerge erwang_bug-10122333 from main
-- erwang     05/22/12 - #(10122333) throw NOT_FOUND exception if partition
--                       doesn't exist
-- jhsi       10/11/11 - Update repos version to 11.1.1.61.63 for unshredded xml
-- erwang     08/26/11 - Bump up repository version to 11.1.1.61.34
-- akrajend   03/01/11 - #(11817738) bump up repos version to 11.1.1.59.73.
-- erwang     09/22/10 - #(10056819) bump up repos version to 11.1.1.58.30
-- erwang     09/21/10 - XbranchMerge erwang_bug-10056819 from main
-- erwang     09/21/10 - #(10056819) bump up repos version to 11.1.1.57.68
-- vyerrama   07/01/10 - XbranchMerge vyerrama_sandbox_guid from main
-- gnagaraj   05/25/10 - #(9649970) Update repos version to 11.1.1.57.18
-- erwang     04/27/10 - #(9625576) Handled no data situation in
--                       exportDocumentByID()
-- erwang     04/23/10 - Change required repos version to 11.1.1.55.43
-- erwang     04/02/10 - #(9555084) bump up repos version 11.1.1.56.54
-- erwang     03/26/10 - bump up repos to 11.1.1.56.47
-- erwang     03/08/10 - Improve locking timeout issue caused by Auto Purge
-- akrajend   02/23/10 - #(9551097) Update repos version for deploy support
--                       11.1.1.56.59.
-- akrajend   02/23/10 - Update repos version for deploy support 11.1.1.56.42
-- erwang     03/02/10 - Fixed size of function parameters
-- erwang     01/19/10 - bump up repos version 11.1.1.56.06
-- akrajend   01/19/10 - #(9233460) Update repos version to 11.1.1.56.03.
-- erwang     12/30/09 - XbranchMerge erwang_bug-9152916 from main
-- gnagaraj   10/08/09 - XbranchMerge gnagaraj_colsize_changes_bug8859749 from
--                       main
-- erwang     12/03/09 - #(9152916) bump up repos version to 11.1.1.55.74
-- gnagaraj   10/05/09 - #(8859749) Update repos version to 11.1.1.55.16
-- gnagaraj   10/08/09 - #(8859749) Update repos version to 11.1.1.55.11
-- erwang     09/09/09 - Use $ for defined variable
-- erwang     08/21/09 - Change variable substitution syntax
-- pwhaley    08/20/09 - Change the order of purging tables, commit between.
-- erwang     08/17/09 - Increase the size of creator and fullname
-- gnagaraj   08/17/09 - #(8495663) Change repos version to 11.1.1.54.63
-- erwang     07/29/09 - Reduced the size of CLOB to avoid running out of resource.
-- erwang     07/15/09 - Included Paul's change to splite value by character.
-- erwang     07/14/09 - Added Paul's UPPER() and trimWhite() methods
-- erwang     07/13/09 - Creation.
--

-----------------------------------------------------------------------------
---------------------------- PRIVATE VARIABLES ------------------------------
-----------------------------------------------------------------------------

-- This is used to verify that the repository API and MDS java code are
-- compatible.  REPOS_VERSION should be updated every time repository schema/ 
-- stored procedures are modified to current version of MDS.
--
-- In addition, if MDS java code is not compatible with older repository,
-- IbmDb2DB.MIN_SHREDDED_REPOS_VERSION should be changed to this value.

define REPOS_VERSION          = "11.1.1.64.35"
@


-- This is used to verify that the repository API and MDS java code are
-- compatible.  This is the earliest MDS midtier version which is compatible
-- with the repository.
define MIN_MDS_VERSION        = "11.1.1.55.43"
@


-- NEWLINE character CHAR(10) .
define NEWLINE                = "CHR(10)"
@

-- Maximimum size of XML chunk for processing buffer. 
define MAX_CHUNK_SIZE         = 32000
@

-- Maximum size of returned XML chunk.  
define MAX_RETURN_CHUNK_SIZE  = 32000
@

-- Maximum size of returned XML chunk in CODEUNIT32 characters.
-- Should be MAX_RETURN_CHUNK_SIZE / 6.
define MAX_CHUNK_CHARS        = 5333
@

-- Indentation for XML elements
define INDENT_SIZE            = 3
@

-- Maximum rows to fetch with bulk bind
define ROWS_TO_FETCH          = 1000
@

-- Maximum size for Max and Min Version
define MDS_VERSION            = 32
@

-- Each element size for mStack session variable
define STACK_ELEM             = 128
@


-- Maxmium Stack Level. #mds_session_varaibles table has to match this value.
define MAX_STACK_LEVEL        = 100
@

-- System Defined Error ID.  Definition can be found at sys.messages table.
define LOCK_REQUEST_TIMEOUT   = 1222
@
define DUP_VAL_ON_CONSTRAINT  = 2601
@
define DUP_VAL_ON_INDEX       = 2627
@

-- constant variables define lengths of varchar columns
define COMP_ID                = 400
@
define COMP_COMMENT           = 6000
@
define CREATOR                = 240 
@
define ELEM_NSURI             = 800
@
define ELEM_NAME              = 127
@
define FULLNAME               = 1800
@
define LOCALNAME              = 127
@
define GUID                   = 36
@
define NRI                    = 4000
@
define PARTITION_NAME         = 200
@
define PATH_NAME              = 512 
@
define PATH_TYPE              = 30
@
define PREFIX                 = 30
@
define VALUE                  = 6000
@
define LARGE_VALUE            = 1M
@
define LARGE_VALUE_IN_BYTES   = 1000000
@
define VER_COMMENTS           = 800
@
define XML_VERSION            = 10
@
define XML_ENCODING           = 60
@

define XMLPARTS               = 32000
@

-- constant variables define some special non varchar types.
define SEQ_TYPE               = NUMERIC(6,0)
@
define LEVEL_TYPE             = NUMERIC(4,0)
@
define NSID_TYPE              = NUMERIC(5,0)
@

CREATE TYPE CharArray AS VARCHAR($STACK_ELEM) ARRAY[$MAX_STACK_LEVEL]
@

-- Global variables, they will be used by exportDocumentByID

CREATE VARIABLE mPreviousName        VARCHAR($LOCALNAME) DEFAULT NULL
@


CREATE VARIABLE mPreviousLevel       $LEVEL_TYPE DEFAULT -1
@


CREATE VARIABLE mPreviousValue       VARCHAR($VALUE) DEFAULT NULL
@


CREATE VARIABLE mPreviousComp        $SEQ_TYPE DEFAULT -1
@


CREATE VARIABLE mIsTagOpen           SMALLINT DEFAULT 0
@


CREATE VARIABLE mFormatted           INTEGER DEFAULT 0
@


CREATE VARIABLE mPartialChunkTableDefined  SMALLINT DEFAULT 0
@


-- To keep stack array.
CREATE VARIABLE mStackVar            VARCHAR(32000)
@

-- User-defined exceptions.
-- The error code will be encoded in text message of error 50000.  "'" must be 
-- used in define error code.  
-- Must keep these error codes in sync with mdsinc.sql and other scripts.

-- External Error Codes to Java layer
define ERROR_DOCUMENT_NAME_CONFLICT = 50100
@
define ERROR_PACKAGE_NAME_CONFLICT  = 50101
@
define ERROR_CORRUPT_SEQUENCE       = 50102
@
define ERROR_CONFLICTING_CHANGE     = 50103
@
define ERROR_RESOURCE_BUSY          = 50104
@
define ERROR_GUID_CONFLICT          = 50105
@
define ERROR_RESOURCE_NOT_EXIST     = 50106
@
define ERROR_LINEAGE_ALREADY_EXIST  = 90107
@
define ERROR_NO_DATA_FOUND          = 90108
@

-- Internal Error Codes
define ERROR_CHUNK_SIZE_EXCEEDED    = 50200
@
define ERROR_ARRAY_OUT_OF_BOUNDARY  = 50201
@

-----------------------------------------------------------------------------
----------------------------- FUNCTIONS -------------------------------------
-----------------------------------------------------------------------------

-- Initial global temp table
--
create PROCEDURE mds_internal_initialXMLPartialChunkTable()

LANGUAGE SQL
BEGIN
    DECLARE GLOBAL TEMPORARY TABLE 
        session.mds_xml_chunk_data(
                         ID        INTEGER GENERATED ALWAYS AS IDENTITY
                                   ( START WITH 1
                                         ,INCREMENT BY 1
                                         ,CACHE 10 ),
                         PARTIAL_XML_CHUNK  VARCHAR($MAX_CHUNK_SIZE))
        ON COMMIT DELETE ROWS
        NOT LOGGED;

    SET mPartialChunkTableDefined = 1;
END
@

-- Has to be called to so procedures that access the temp table can be created. 
CALL mds_internal_initialXMLPartialChunkTable()
@

-- Gets the minimun version of MDS with which the repository is
-- compatible.  That is, the actual MDS version must be >= to the
-- minimum version of MDS in order for the repositroy and java code to
-- be compatible.
--
-- Returns:
--   Returns the mimumum version of MDS
--
CREATE PROCEDURE mds_getMinMDSVersion(OUT ver VARCHAR(15))
LANGUAGE SQL

SPECIFIC mds_getMinMDSVersion

BEGIN

    SET ver = '$MIN_MDS_VERSION';

END
@



--
-- Gets the version of the repository API.  This API version must >= to the
-- java constant CompatibleVersions.MIN_REPOS_VERSION.
--
-- Returns:
--   Returns the version of the repository
--

CREATE PROCEDURE mds_getRepositoryVersion(OUT ver VARCHAR(15))
LANGUAGE SQL

SPECIFIC mds_getRepositoryVersion

BEGIN

    SET ver = '$REPOS_VERSION';
END
@


--
-- Gets the version and encoding of the repository API.
--
-- Returns:
--   Returns the version and encoding of the repository.
--
CREATE PROCEDURE mds_getReposVersionAndEncoding ( OUT reposVersion VARCHAR(15), 
                                                  OUT dbEncoding   VARCHAR(25))
LANGUAGE SQL

SPECIFIC mds_getReposVersionAndEncoding

BEGIN
   
    SET reposVersion = '$REPOS_VERSION';
    
    -- get the encoding from the database, it returns 'utf8' for unicode.
    select value into dbEncoding from sysibmadm.dbcfg where name = 'codeset';   
END
@


CREATE PROCEDURE mds_internal_initArray(INOUT arr1 CharArray)

LANGUAGE SQL
SPECIFIC mds_internal_initArray
BEGIN
    DECLARE I       SMALLINT DEFAULT 1;
    DECLARE arrSize INTEGER;

    SET arrSize = MAX_CARDINALITY(arr1);
    
    WHILE( I <= arrSize ) DO
        SET arr1[I] = NULL;
        SET I = I + 1;
    END WHILE;
END
@


CREATE PROCEDURE mds_internal_saveStackValues(stack        CharArray)
LANGUAGE SQL

SPECIFIC mds_internal_saveStackValues

BEGIN

    -- Save stack to mStackVar Global Variable.
    DECLARE i     SMALLINT DEFAULT 1;
    DECLARE count SMALLINT;

    SET count = CARDINALITY(stack);
    SET mStackVar = '';

    WHILE(i <= count) DO
        IF ( i > 1 ) THEN
            -- Add comma as seperator
            SET mStackVar = mStackVar || ',';
        END IF;

        SET mStackVar = mStackVar || COALESCE(stack[i],''); 

        SET i = i + 1;
    END WHILE;      
END
@


CREATE PROCEDURE mds_internal_saveXMLPartialChunk(partialChunk   CLOB($LARGE_VALUE),
                                                  cleanTempTable SMALLINT)
LANGUAGE SQL

SPECIFIC mds_internal_saveXMLPartialChunk

BEGIN
    DECLARE LEN      INTEGER;
    DECLARE POS      INTEGER DEFAULT 1;
    DECLARE retChunk VARCHAR($MAX_CHUNK_SIZE);

    IF ( mPartialChunkTableDefined = 0 ) THEN
        CALL mds_internal_initialXMLPartialChunkTable();
    END IF;

    -- Truncate the temp table.
    IF ( cleanTempTable <> 0 ) THEN
        DELETE FROM session.mds_xml_chunk_data; 
    END IF;

    SET LEN = LENGTH(partialChunk, CODEUNITS32);

    -- Split the partialChunk into pieces that will fit in
    -- MAX_CHUNK_SIZE bytes, without splitting any characters.
    -- There doesn't seem to be a function that will split a
    -- CODEUNITS32 string into a given (or slightly smaller) byte
    -- size, so we take the conservative approach of only splitting
    -- off MAX_CHUNK_SIZE/6 characters at a time.
    WHILE (POS <= LEN) DO
        -- Write data to table.

        IF ( (LEN - POS + 1) > $MAX_CHUNK_CHARS ) THEN
            SET retChunk = SUBSTRING(partialChunk, POS, $MAX_CHUNK_CHARS,
                                     CODEUNITS32);
            SET POS = POS + $MAX_CHUNK_CHARS;
        ELSE
            SET retChunk = SUBSTRING(partialChunk, POS, CODEUNITS32);
            SET POS = LEN + 1;
        END IF;
        
        INSERT INTO session.mds_xml_chunk_data(PARTIAL_XML_CHUNK) values(retChunk);
    END WHILE;
END
@


CREATE PROCEDURE mds_internal_restoreStackValues(OUT stack        CharArray)
LANGUAGE SQL

SPECIFIC mds_internal_restoreStackValues

BEGIN

  -- Restore stack value from mStackVar Global Variable.
  DECLARE i     SMALLINT DEFAULT 1;
  DECLARE count SMALLINT;
  DECLARE startPOS     SMALLINT;
  DECLARE sepPOS       SMALLINT;
  DECLARE len          SMALLINT;
  DECLARE elem         VARCHAR($STACK_ELEM);

  SET count = MAX_CARDINALITY(stack);

  CALL mds_internal_initArray(stack);

  SET startPOS = 1;
  SET sepPOS   = -1;  -- Initialize with non 0 value.
    
  WHILE(sepPOS <> 0 AND i <= count) DO
    SET sepPOS = LOCATE(',', mStackVar, startPOS, CODEUNITS32);
    
    IF (sepPOS = 0) THEN
      SET len = CHAR_LENGTH(mStackVar, CODEUNITS32) - startPOS + 1;
    ELSE
      SET len = sepPOS - startPOS;
    END IF;

    SET elem = SUBSTRING(mStackVar, startPOS, len, CODEUNITS32);

    -- set the stack element.
    IF ( LENGTH(elem) = 0 ) THEN
        SET stack[i] = NULL;
    ELSE
        SET stack[i] = elem; 
    END IF;

    -- Shift the position to the right of @sepPOS.
    IF (sepPOS <> 0) THEN
      SET startPOS = sepPOS + 1;
    END IF;
    
    SET i = i + 1;
  END WHILE;
END
@


--
-- Deletes the given partition. If there are any documents in the given
-- partition, this method will delete all those documents.  This procedure
-- will be committed in its own transaction upon success.
--
-- Parameters:
--   partitionName - Name of the partition.
--
CREATE PROCEDURE mds_deletePartition (partitionName VARCHAR($PARTITION_NAME))
LANGUAGE SQL

SPECIFIC mds_deletePartition

BEGIN
    DECLARE partitionID    DECIMAL(31,0);

    BEGIN
        DECLARE EXIT HANDLER FOR NOT FOUND
        BEGIN
            RESIGNAL SQLSTATE '$ERROR_NO_DATA_FOUND';
        END;

        SELECT partition_id INTO partitionID 
              FROM mds_partitions
              WHERE partition_name = partitionName;
    END;
    
    DELETE FROM mds_components WHERE comp_partition_id = partitionID;
    DELETE FROM mds_attributes WHERE att_partition_id = partitionID;
    DELETE FROM mds_namespaces WHERE ns_partition_id = partitionID;

    CALL mds_internal_deletePartition(partitionID);

END
@

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

CREATE PROCEDURE mds_getNamespaceID (OUT namespaceID DECIMAL(31,0), 
                                         partitionID DECIMAL(31,0), 
                                         uri         VARCHAR($NRI))
LANGUAGE SQL

SPECIFIC mds_getNamespaceID

MODIFIES SQL DATA
NOT DETERMINISTIC
AUTONOMOUS 

BEGIN
    DECLARE EXIT HANDLER FOR NOT FOUND
    BEGIN
        DECLARE EXIT HANDLER FOR NOT FOUND
        BEGIN
            -- Get the next ns_id.
            SELECT COALESCE(max(ns_id), 0) + 1
                INTO namespaceID
                FROM mds_namespaces;

            INSERT INTO mds_namespaces(ns_partition_id, ns_id, ns_uri)
                VALUES (partitionID, namespaceID, uri);

            COMMIT;
        END;

        -- This will create an update lock on the key even though the
        -- row doesn't exist.  The SELECT will create a critical section
        -- for inserting a new NS. 
        SELECT ns_id
            INTO namespaceID
            FROM mds_namespaces
            WHERE ns_id = -1 
            WITH RR USE AND KEEP UPDATE LOCKS;

        -- Double check the NS if it is added before
        -- entering the critical section. 
        SELECT ns_id INTO namespaceID
            FROM mds_namespaces
                WHERE ns_uri = uri and
                 ns_partition_id = partitionID;

    END;

    SELECT ns_id INTO namespaceID
           FROM mds_namespaces
             WHERE ns_uri = uri and
                   ns_partition_id = partitionID;

    RETURN;
END
@

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

CREATE PROCEDURE mds_purgeMetadata ( OUT numVersionsPurged DECIMAL(31,0), 
                                         partitionID       DECIMAL(31,0), 
                                         purgeCompareTime  TIMESTAMP, 
                                         secondsToLive     DECIMAL(31,0), 
                                         isAutoPurge       DECIMAL(31,0), 
                                     OUT commitNumber      DECIMAL(31,0))
LANGUAGE SQL

SPECIFIC mds_purgeMetadata

BEGIN
    IF ( mTempTablesDefined = 0 ) THEN
        CALL mds_internal_initialTempTables();
    END IF;

    -- This will populate mds_purge_data table with the data for paths
    -- that can be purged
    CALL mds_internal_purgeMetadata(numVersionsPurged,
                                    partitionID, 
                                    purgeCompareTime,
                                    secondsToLive,
                                    isAutoPurge,    
                                    commitNumber );

    -- Commit the path changes so we free our locks. This should
    -- not cause problems since we will have dangling comp and attr
    -- rows, rather than path rows with missing content.
    COMMIT;

    IF (numVersionsPurged > 0) THEN 
        -- Delete the components first, since reading contents
        -- does an outer join from components to attributes. We
        -- want to acquire our locks in the same order.

        -- Delete components of the purged versions.
        DELETE FROM mds_components
              WHERE comp_partition_id = partitionID
                    AND comp_contentid IN 
                     (SELECT ppath_contentid
                          FROM session.mds_purge_paths
                             WHERE ppath_partition_id = partitionID);
    
        -- Commit the comp changes so we free our locks. This should
        -- not cause problems since we will have dangling attr
        -- rows, rather than path or comp rows with missing content.
        COMMIT;

        -- Delete attributes of the purged versions.
        DELETE  FROM mds_attributes  
              WHERE att_partition_id = partitionid
                    AND att_contentid IN
                     (SELECT ppath_contentid 
                          FROM session.mds_purge_paths p
                             WHERE ppath_partition_id = partitionID);
    END IF;
END
@




-- Used internally to handle exception while converting a character value
-- to numeric.

CREATE PROCEDURE mds_internal_toNumber(OUT rtnVal          DECIMAL(31,0),
                                           attribute_value VARCHAR(100))

LANGUAGE SQL
SPECIFIC mds_internal_toNumber

DETERMINISTIC
NO EXTERNAL ACTION
CONTAINS SQL

BEGIN
    -- Handle for invalid numeric format.
    DECLARE EXIT HANDLER FOR SQLSTATE '22018'
    BEGIN
        SET rtnVal = NULL;
    END;

    SET rtnVal = 0;

    IF (attribute_value IS NULL) THEN
        SET rtnVal = NULL;
        RETURN;
    END IF;
        
    SET rtnVal = DECIMAL(attribute_value);
        
    RETURN;
END
@


-- Used in the queryapi. The attr_value column contains both strings and
-- number values in a varchar2. In the query api we need to be able to
-- complete number and string comparisions against the values in the column.
-- However if we use to_number() on the column the string values are going to
-- fall over in a big heap and give the  ORA-01722: invalid number exception.
-- This function allows us to handle this scenario more gracefully.
-- ie   to_number('29') works
-- to_number('sugar') -- SQLSTATE 22018. in this case return null.
--

CREATE FUNCTION mds_toNumber(attribute_value VARCHAR(100)) 
RETURNS DECIMAL(31,0)

LANGUAGE SQL
SPECIFIC mds_toNumber

DETERMINISTIC
NO EXTERNAL ACTION
CONTAINS SQL

BEGIN ATOMIC

    DECLARE attribute_value_number DECIMAL(31,0);

    CALL mds_internal_toNumber(attribute_value_number,
                               attribute_value);
    
    RETURN attribute_value_number;
END
@


-- Functions used in the queryapi to compare with a CLOB column such as
-- ATTR_LONG_VALUE. Used to avoid SQL errors.
-- Not required in SQLServer.
-- Does the indicated comparison on its operands and returns 1 if true,
-- 0 if false.

CREATE FUNCTION mds_clobEQ (clobVal CLOB(2G), 
                            val2    VARCHAR(6000))
RETURNS SMALLINT
LANGUAGE SQL
SPECIFIC mds_clobEQ
DETERMINISTIC
NO EXTERNAL ACTION
CONTAINS SQL

BEGIN ATOMIC
    DECLARE strVal        VARCHAR(32000);

    IF (OCTET_LENGTH(clobVal) > 32000 ) THEN
        SET strVal = CAST(LEFT(clobVal,32000, OCTETS) AS VARCHAR(32000));
    ELSE
        SET strVal = CAST(clobVal AS VARCHAR(32000));
    END IF;

    IF (strVal = val2) THEN 
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END
@


CREATE FUNCTION mds_clobLT (clobVal CLOB(2G), 
                            val2 VARCHAR(6000) )
RETURNS SMALLINT 
LANGUAGE SQL
SPECIFIC mds_clobLT
DETERMINISTIC
NO EXTERNAL ACTION
CONTAINS SQL

BEGIN ATOMIC
    DECLARE strVal        VARCHAR(32000);

    IF (OCTET_LENGTH(clobVal) > 32000 ) THEN
        SET strVal = CAST(LEFT(clobVal,32000, OCTETS) AS VARCHAR(32000));
    ELSE
        SET strVal = CAST(clobVal AS VARCHAR(32000));
    END IF;

    IF ( strVal < val2 ) THEN
        RETURN 1;    
    ELSE        
        RETURN 0;    
    END IF;
END
@



CREATE FUNCTION mds_clobGT (clobVal CLOB(2G), 
                            val2 VARCHAR(6000) )
RETURNS SMALLINT
LANGUAGE SQL
SPECIFIC mds_clobGT
DETERMINISTIC
NO EXTERNAL ACTION
CONTAINS SQL

BEGIN ATOMIC
    DECLARE strVal        VARCHAR(32000);

    IF (OCTET_LENGTH(clobVal) > 32000 ) THEN
        SET strVal = CAST(LEFT(clobVal,32000, OCTETS) AS VARCHAR(32000));
    ELSE
        SET strVal = CAST(clobVal AS VARCHAR(32000));
    END IF;
    
    IF ( strVal > val2 ) THEN
        RETURN 1;
    
    ELSE
        RETURN 0;    
    END IF;
END
@

CREATE FUNCTION mds_clobNE (clobVal CLOB(2G), 
                            val2 VARCHAR(6000) )
RETURNS SMALLINT 
LANGUAGE SQL
SPECIFIC mds_clobNE 
DETERMINISTIC
NO EXTERNAL ACTION
CONTAINS SQL

BEGIN ATOMIC
    DECLARE strVal        VARCHAR(32000);

    IF (OCTET_LENGTH(clobVal) > 32000 ) THEN
        SET strVal = CAST(LEFT(clobVal,32000, OCTETS) AS VARCHAR(32000));
    ELSE
        SET strVal = CAST(clobVal AS VARCHAR(32000));
    END IF;

    IF ( strVal <> val2 ) THEN
        RETURN 1;    
    ELSE
        RETURN 0;    
    END IF;
END
@

CREATE FUNCTION mds_clobLE (clobVal CLOB(2G), 
                            val2 VARCHAR(6000) )
RETURNS SMALLINT 
LANGUAGE SQL
SPECIFIC mds_clobLE
DETERMINISTIC
NO EXTERNAL ACTION
CONTAINS SQL

BEGIN ATOMIC
    DECLARE strVal        VARCHAR(32000);

    IF (OCTET_LENGTH(clobVal) > 32000 ) THEN
        SET strVal = CAST(LEFT(clobVal,32000, OCTETS) AS VARCHAR(32000));
    ELSE
        SET strVal = CAST(clobVal AS VARCHAR(32000));
    END IF;
    
    IF ( strVal <= val2 ) THEN
        RETURN 1;    
    ELSE        
        RETURN 0;    
    END IF;
END
@


CREATE FUNCTION mds_clobGE (clobVal CLOB(2G), 
                            val2 VARCHAR(6000) )
RETURNS SMALLINT 
LANGUAGE SQL
SPECIFIC mds_clobGE
DETERMINISTIC
NO EXTERNAL ACTION
CONTAINS SQL

BEGIN ATOMIC
    DECLARE strVal        VARCHAR(32000);

    IF (OCTET_LENGTH(clobVal) > 32000 ) THEN
        SET strVal = CAST(LEFT(clobVal,32000, OCTETS) AS VARCHAR(32000));
    ELSE
        SET strVal = CAST(clobVal AS VARCHAR(32000));
    END IF;

    IF ( strVal >= val2 ) THEN
        RETURN 1;    
    ELSE
        RETURN 0;    
    END IF;
END
@

CREATE FUNCTION UPPER (clobVal CLOB(2G))
RETURNS CLOB(2G)
SPECIFIC UPPER
LANGUAGE SQL
BEGIN ATOMIC
    DECLARE strVal        VARCHAR(32000);

    IF ( clobVal IS NULL ) THEN
        RETURN NULL;
    END IF;

    IF (OCTET_LENGTH(clobVal) > 32000 ) THEN
        SET strVal = CAST(LEFT(clobVal,32000, OCTETS) AS VARCHAR(32000));
    ELSE
        SET strVal = CAST(clobVal AS VARCHAR(32000));
    END IF;


    RETURN UPPER(strVal);
END
@

CREATE FUNCTION mds_trimWhite(parm VARCHAR(32000))
RETURNS VARCHAR(32000)
SPECIFIC mds_trimWhite
LANGUAGE SQL
BEGIN ATOMIC
    DECLARE ch VARCHAR(10);
    DECLARE val VARCHAR(32000);
    SET val = parm;
    IF ( val IS NULL ) THEN
        RETURN NULL;
    END IF;
  leftTrim:
    WHILE LENGTH(val, OCTETS) > 0 DO
        SET ch = LEFT(val, 1, CODEUNITS16);
        IF  ch = X'20' OR ch = X'0a' OR ch = X'0d' THEN
            SET val = SUBSTRING(val, 2, CODEUNITS16);
        ELSE
            LEAVE leftTrim;
        END IF;
    END WHILE leftTrim;
  rightTrim:
    WHILE LENGTH(val, OCTETS) > 0 DO
        SET ch = RIGHT(val, 1, CODEUNITS16);
        IF ( ch = X'20' OR ch = X'0a' OR ch = X'0d' )
        THEN
            SET val = LEFT(val, LENGTH(val, CODEUNITS16) - 1,
                               CODEUNITS16);
        ELSE
            LEAVE rightTrim;
        END IF;
    END WHILE rightTrim;
    RETURN val;
END
@

--
-- Creates the XML for the specified attribute
--

create PROCEDURE mds_internal_addAttribute(
    INOUT newxml              CLOB($LARGE_VALUE),
          prefix              VARCHAR($PREFIX),
          localname           VARCHAR($LOCALNAME),
          value               VARCHAR($VALUE),
          largevalue          CLOB($LARGE_VALUE))

LANGUAGE SQL
SPECIFIC internal_addAttribute

BEGIN
    DECLARE evalue            CLOB($LARGE_VALUE);

    IF ( value IS NULL ) THEN
        SET evalue = largevalue;
    ELSE
        SET evalue = CLOB(value);
    END IF;

    -- TODO: need to check if newxml + value exceeds CLOB size.
    IF (localname IS NOT NULL) THEN
        IF (prefix IS NOT NULL) THEN

            SET newxml = newxml || ' ' ||
	  		 prefix || ':' || localname ||  '="' || evalue;
        ELSE
            SET newxml = newxml || ' ' ||
			 localname ||  '="' || evalue ;
        END IF;
    ELSEIF (value IS NOT NULL) THEN
        SET newxml = newxml || evalue;
    END IF;

    IF (localname IS NOT NULL OR value IS NOT NULL) THEN
        SET newxml = newxml || '"';
    END IF;

END
@


--
-- Creates the XML for the new component
--

create PROCEDURE mds_internal_addComponent(
    INOUT newxml              CLOB($LARGE_VALUE),
          compseq             $SEQ_TYPE,
          complevel           $LEVEL_TYPE,
          compprefix          VARCHAR($PREFIX),
          complocalname       VARCHAR($LOCALNAME),
          compvalue           VARCHAR($VALUE),
          attprefix           VARCHAR($PREFIX),
          attlocalname        VARCHAR($LOCALNAME),
          attvalue            VARCHAR($VALUE),
          attLongValue        CLOB($LARGE_VALUE),
          formatted           SMALLINT,
    INOUT prevComp            $SEQ_TYPE,
    INOUT prevVal             VARCHAR($VALUE),
    INOUT prevName            VARCHAR($LOCALNAME),
    INOUT prevLevel           $LEVEL_TYPE,
    INOUT isTagOpen           SMALLINT,
    INOUT stack               CharArray)

LANGUAGE SQL
SPECIFIC mds_internal_addComponent

BEGIN

  -- If this is a mixed content element value, then add the element now
  -- This can occur with the following xml:
  -- <a>
  --    first mixed content
  --    <b>
  --      this is not mixed content since b has no children
  --    </b>
  --    and more mixed content of a
  -- </a>
  IF (compvalue IS NOT NULL) 
              AND (complocalname IS NULL OR LENGTH(complocalname) = 0) THEN
      SET newxml = newxml || compvalue;

      SET prevLevel = complevel;
      SET prevVal   = NULL;
      SET prevName  = NULL;
  ELSE
  BEGIN
      DECLARE temp      VARCHAR($STACK_ELEM);
      DECLARE currLevel $LEVEL_TYPE;

      -- This is a true element, so let's add it now
      SET currLevel = complevel + 1;

      IF (compprefix IS NOT NULL AND LENGTH(compprefix) > 0) THEN
          SET temp = (compprefix || ':' || complocalname);
          SET stack[currLevel] = temp;
      ELSE
          SET stack[currLevel] = complocalname;
      END IF;
      
      IF (formatted = 1) THEN 
          SET newxml = newxml || SPACE(CAST(complevel*$INDENT_SIZE AS SMALLINT));
      END IF;

      SET currLevel = complevel+1;
      SET temp = stack[currLevel];
      SET newxml = newxml || '<' || temp;

      -- Add the 4th-normal attribute (if any) from the attributes table
      CALL mds_internal_addAttribute(newxml, attprefix, 
                                     attlocalname, attvalue, 
                                     attLongValue);

      -- Update the state
      SET prevLevel = complevel;
      SET prevComp  = compseq;
      SET prevVal   = compvalue;
      SET prevName  = complocalname;
      SET isTagOpen = 1;
  END;
  END IF;
END
@


--
-- Add the XML to the current chunk and raise an exception if the
-- maximum size is exceeded.
--

create PROCEDURE mds_internal_addXMLtoChunk(
    INOUT chunk    CLOB,
          newxml   CLOB)

LANGUAGE SQL

SPECIFIC mds_internal_addXMLtoChunk

DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA

BEGIN
  DECLARE LEN1          INTEGER;
  DECLARE LEN2          INTEGER;

  -- Have to count it by byte.
  SET LEN1 = OCTET_LENGTH(newxml);
  SET LEN2 = OCTET_LENGTH(chunk);

  IF ((LEN1 + LEN2) > $MAX_CHUNK_SIZE) THEN
    SIGNAL SQLSTATE '$ERROR_CHUNK_SIZE_EXCEEDED';
  ELSE
    SET chunk = chunk || newxml;
  END IF;
END
@


--
-- Create the XML header for the given document ID
--

create FUNCTION mds_internal_addXMLHeader(
    partitionID   DECIMAL(31,0),
    docID         DECIMAL(31,0),
    versionNum    DECIMAL(31,0)) 

RETURNS VARCHAR(256)

LANGUAGE SQL
SPECIFIC mds_internal_addXMLHeader
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA

BEGIN ATOMIC
  DECLARE xml_version   VARCHAR($XML_VERSION);
  DECLARE xml_encoding  VARCHAR($XML_ENCODING);
  DECLARE mdsguid       VARCHAR($GUID);
  DECLARE xml_header    VARCHAR(256);

  -- Get the version and encoding
  SET (xml_version, xml_encoding, mdsguid) = 
                    (SELECT PATH_XML_VERSION, PATH_XML_ENCODING, PATH_GUID
                           FROM MDS_PATHS
                           WHERE
                               PATH_DOCID = docID AND PATH_VERSION = versionNum
                               AND PATH_PARTITION_ID = partitionID);

  -- ###
  -- ### #(2424399) Need to be able to retrieve XML_VERSION
  -- ### from the XML file
  -- ###
 
  IF (xml_version IS NULL OR LENGTH(xml_version) = 0) THEN
    SET xml_version = '1.0';
  END IF;

  -- Return the xml header
  SET xml_header = '<?xml version=''' || xml_version || '''';
  
  -- #(6616221) Do not add encoding='' in the XML header if encoding is
  -- null.
  IF (xml_encoding IS NOT NULL) THEN
    SET xml_header = xml_header || ' encoding=''' || xml_encoding || '''';
  END IF;
  
  SET xml_header = xml_header || '?>' || CHR(10);

  IF mdsguid IS NOT NULL AND LENGTH(mdsguid) > 0 THEN
    SET xml_header = xml_header || '<?oracle.mds.mdsguid ' || mdsguid || 
				    '?>' || $NEWLINE;
  END IF;
    
  RETURN xml_header;
END
@


--
-- Creates the XML for ending a component
--

create PROCEDURE mds_internal_endComponent(
    INOUT newxml              CLOB,
          compLevel           $LEVEL_TYPE,
          formatted           SMALLINT,
    INOUT prevComp            $SEQ_TYPE,
    INOUT prevVal             CLOB($LARGE_VALUE),
    INOUT prevName            VARCHAR($LOCALNAME),
    INOUT prevLevel           $LEVEL_TYPE,
    INOUT isTagOpen           SMALLINT,
    INOUT stack               CharArray)
LANGUAGE SQL
SPECIFIC mds_internal_endComponent
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA

BEGIN
  DECLARE I         SMALLINT;
  DECLARE temp      VARCHAR($STACK_ELEM);
  DECLARE valAdded  SMALLINT;

  SET valAdded = 0;

  IF (prevName IS NULL OR LENGTH(prevName) = 0) THEN
      -- The previous "component" was not really a component, but just an
      -- element value. This can happen with the following xml, in which
      -- we are in the process of adding component b:
      --   <a>
      --      some value
      --      <b>
      --      ...
      --
      -- When adding component b, we don't need to end component a since
      -- it would have been "ended" when the element value was added.
      -- However, since we are starting a new component, we do want to add
      -- a new line.
      SET newxml = newxml || $NEWLINE;
  ELSEIF (compLevel <= prevLevel) THEN
    -- The previous component has no children, so we can end the tag now.
    -- If the previous component had a value, we need to add that as well.

    IF (prevVal IS NOT NULL AND LENGTH(prevVal) <> 0) THEN
      -- Add the previous value, if any.  This can happen with the following
      -- xml, in which we are about to add component b:
      --   <a attribute1="foo">
      --     some value
      --   </a>
      --   <b>
      --      ...
      -- Here, since "some value" is a real element value, it is saved in
      -- the same row in which the component is defined.  We couldn't add
      -- the value right away, since we add to add all of the attributes
      -- first (like attribute1).  Now, however, since we are done adding
      -- the attributes, we can safely add the element value.
      -- #(5580893) Don't add any formatting if textcontent was found
      SET valAdded = 1;  
      SET newxml = newxml || '>' || prevVal;
      SET prevVal = NULL;
      SET isTagOpen = 0;
    END IF;
    IF (isTagOpen = 1) THEN
        -- No element value, so a simple end tag will work
        SET newxml = newxml || '/>' || $NEWLINE;
    ELSE
    BEGIN
      DECLARE prevStackLevel  $LEVEL_TYPE;
      -- Add the end tag (i.e. </a>)
      IF (valAdded = 0) THEN
        SET newxml = newxml || $NEWLINE;
      END IF;

      IF (formatted = 1 AND valAdded = 0) THEN
        SET newxml = newxml || SPACE(CAST(prevLevel*$INDENT_SIZE AS SMALLINT));
      END IF;

      SET prevStackLevel = prevLevel + 1;
      SET temp = stack[prevStackLevel];
      SET newxml = newxml || '</' || temp || '>' || $NEWLINE;
    END;
    END IF;
  ELSE
      -- There are potential children to come
      SET newxml = newxml || '>' || $NEWLINE;
      SET isTagOpen = 0;
  END IF;

  -- Check if we need to pop any components from the stack
  SET I = prevLevel;
  WHILE (I > compLevel) DO
    IF (formatted = 1) THEN
      SET newxml = newxml || SPACE(CAST((I-1)*$INDENT_SIZE AS SMALLINT));
    END IF;
    
    SET temp = stack[I];
    SET newxml = newxml ||  '</' || temp || '>' || $NEWLINE;
    SET I = I - 1;
  END WHILE;
END
@


--
-- Export the XML for the document with given PATH_DOCID and pass it
-- back in MAX_RETURN_CHUNK_SIZE chunks.  Each call will try to get 
-- MAX_CHUNK_SIZE, if the retrieved size is larger than MAX_RETURN_CHUNK_SIZE,
-- the overflowed value will be saved in #MDS_SESSION_VARIABLES.PARTIAL_CHUNK.
-- The caller has to retrieve it as well.
--
-- A "single" document is simply a document which is not a package document.
-- See comments for exportDocumentByName for more information.
  

create PROCEDURE mds_exportDocumentByID(
    OUT   retChunk             VARCHAR($MAX_RETURN_CHUNK_SIZE),
    OUT   exportFinished       SMALLINT,
          partitionID          DECIMAL(31,0),
          docID                DECIMAL(31,0),
          contentID            DECIMAL(31,0),
          versionNum           DECIMAL(31,0),
          isFormatted          SMALLINT)
LANGUAGE SQL

SPECIFIC mds_exportDocumentByID

MODIFIES SQL DATA

DYNAMIC RESULT SETS 1

BEGIN
  DECLARE newxml               CLOB($LARGE_VALUE);
  DECLARE chunk                CLOB($LARGE_VALUE);
  DECLARE formatted            SMALLINT;

  -- Variables holds fetched record.
  DECLARE rCompSeq             $SEQ_TYPE;
  DECLARE rCompPrefix          VARCHAR($PREFIX);
  DECLARE rCompLocalName       VARCHAR($LOCALNAME);
  DECLARE rCompLevel           $LEVEL_TYPE;
  DECLARE rCompValue           VARCHAR($VALUE);
  DECLARE rAttPrefix           VARCHAR($PREFIX);
  DECLARE rAttLocalName        VARCHAR($LOCALNAME);
  DECLARE rAttValue            VARCHAR($VALUE);
  DECLARE rAttLongValue        CLOB($LARGE_VALUE);

  DECLARE partialChunk         CLOB($LARGE_VALUE);

  -- Session variables, they will be persisted before exit.
  DECLARE mStack               CharArray;

  DECLARE LEN                  INTEGER;

  DECLARE SQLSTATE             CHAR(5);

  -- Declare the cursor.
  -- Cursor to  retrieve all of the components of a document
  DECLARE c_document_contents CURSOR WITH RETURN TO CLIENT FOR
        SELECT
          COMP_SEQ,
          COMP_LEVEL,
          COMP_PREFIX,
          COMP_LOCALNAME,
          COMP_VALUE,
          ATT_PREFIX,
          ATT_LOCALNAME,
          ATT_VALUE,
          ATT_LONG_VALUE
        FROM
          MDS_COMPONENTS LEFT OUTER JOIN MDS_ATTRIBUTES ON 
          COMP_PARTITION_ID = ATT_PARTITION_ID AND
          COMP_CONTENTID = ATT_CONTENTID AND
          COMP_SEQ = ATT_COMP_SEQ
        WHERE
          COMP_PARTITION_ID = partitionID AND
          COMP_CONTENTID = contentID
        ORDER BY
          COMP_SEQ,
          ATT_COMP_SEQ,
          ATT_SEQ
        FOR READ ONLY;

  -- Continue handler for cursor is already declared exception.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '24516'
  BEGIN
      -- Do nothing.
  END;

  DECLARE EXIT HANDLER FOR SQLSTATE '99999'
  BEGIN
  END;
 
  SET retChunk = '';
  SET chunk    = '';

  IF (docID IS NOT NULL) THEN
    SET mFormatted = isFormatted;
  ELSE
    -- Restore Stack values from the global variable.
    CALL mds_internal_restoreStackValues( mStack );
  END IF;

  SET formatted = mFormatted;

  -- Assume that the document will fit in this chunk
  SET exportFinished = 1;
  
  -- The partialChunk should be set to '', since it will be retrieved by the caller.
  SET partialChunk = '';

  --
  -- This procedure returns the XML for the specified document.  Since the
  -- XML can be potentially large (greater than 4k) and since, for
  -- performance reasons, we do not want to return more than 32k at a time,
  -- this procedure may need to be called multiple times to retrieve the
  -- entire document.  As such, the "state" of the export is stored in
  -- package variables.
  --
  -- A non-null document indicates that the export process is just
  -- being started, so let's do the necessary initialization.
  --
  IF (docID IS NOT NULL) THEN
  BEGIN
    -- Get the XML header
    SET chunk = mds_internal_addXMLHeader(partitionID, docID, versionNum);

    -- Initialize the state of the export
    SET mPreviousComp = -1;
    SET mPreviousLevel = -1;
    SET mPreviousValue = NULL;
    SET mPreviousName = NULL;

    -- Initialize mStack.
    CALL mds_internal_initArray(mStack);

    -- Verify that the cursor is closed
    -- ###
    -- ### Not sure what to do here, as the cursor should never be open
    -- ### For now, we'll just close it and cross our fingers
    -- ###
    BEGIN
        -- Exception for cursor is already openned.
        DECLARE CONTINUE HANDLER FOR SQLSTATE '24502', SQLSTATE '24517'
        BEGIN
            CLOSE c_document_contents;

            -- Reopen it.
            OPEN c_document_contents;
        END;
    
        -- And open the cursor that will retrieve the documents/packages
        OPEN c_document_contents;
    END;
  END;
  END IF;

  SET newxml = '';

  BEGIN
      DECLARE CONTINUE HANDLER FOR SQLSTATE '$ERROR_CHUNK_SIZE_EXCEEDED'
      BEGIN
          --SET exportFinished = 0;
 
          IF ( OCTET_LENGTH(retChunk) = 0 ) THEN
              SET LEN = OCTET_LENGTH(chunk);

              IF (LEN > $MAX_RETURN_CHUNK_SIZE) THEN
                  -- Don't split any CODEUNITS32 characters.
                  SET retChunk = LEFT(chunk, $MAX_CHUNK_CHARS, CODEUNITS32);
                  SET LEN = LENGTH(chunk, CODEUNITS32);
                  SET partialChunk = RIGHT(chunk, LEN - $MAX_CHUNK_CHARS,
                                           CODEUNITS32);
                  CALL mds_internal_saveXMLPartialChunk( partialChunk, 1 );
                  CALL mds_internal_saveXMLPartialChunk( newxml, 0 );
              ELSE
                  SET retChunk = chunk;
                  SET partialChunk = newxml;
                  CALL mds_internal_saveXMLPartialChunk( partialChunk, 1 );
              END IF;

              -- Save stack value and left over chunk data.
              --CALL mds_internal_saveStackValues( mStack );
          ELSE
              IF ( OCTET_LENGTH(chunk) + OCTET_LENGTH(newxml) < $LARGE_VALUE_IN_BYTES ) THEN
                  SET chunk = chunk || newxml;

                  CALL mds_internal_saveXMLPartialChunk( chunk, 0 );
              ELSE
                  CALL mds_internal_saveXMLPartialChunk( chunk, 0 );
              
                  -- Save nexml seperately, in case chunk + newxml will exceed the max size.
                  CALL mds_internal_saveXMLPartialChunk( newxml, 0 );
              END IF;
          END IF;
             
          SET newxml = '';
          SET partialChunk = '';
          SET chunk = '';

          -- Exit the routine.
          --SIGNAL SQLSTATE '99999';
      END;

      -- Exit Handler for Cursor is not open. 
      DECLARE EXIT HANDLER FOR SQLSTATE '24501'
      BEGIN
          -- Exit the block.
      END;

      WHILE(1=1) DO
          --
          -- Retrieve the next set of rows if we are currently not in the
          -- middle of processing a fetched set or rows.
          --
          -- Fetch the next set of rows
          FETCH FROM c_document_contents
             INTO rCompSeq, rCompLevel, rCompPrefix, rCompLocalName,
                  rCompValue, rAttPrefix, rAttLocalName, rAttValue,
                  rAttLongValue;
          IF (SQLSTATE <> '00000') THEN
              -- Just close the cursor and leave
              CLOSE c_document_contents;

              GOTO END_COMP;

          END IF;       

          --
          -- There are three different types of situations need to
          -- be handled:
          -- (1) Starting a new component
          -- (2) Adding an attribute to a component
          -- (3) Adding an element value to a component
          --
          IF (rCompSeq <> mPreviousComp) THEN
              -- We are starting a new component/value, so add the "previous"
              -- component

              IF (rCompLevel = -1) THEN
                  -- Add the element value.  -1 is a special level
                  -- indicating that the element value was too large too fit
                  -- in a single 4k chunk.

                  IF (mPreviousValue IS NOT NULL) THEN
                      SET newxml = newxml || '>';
            
                      SET newxml = newxml || mPreviousValue;
                      SET mIsTagOpen = 0;
                      SET mPreviousValue = NULL;
                  END IF;

                  SET newxml = newxml || COALESCE(rCompValue, '');
              ELSE
                  -- End the previous component
                  IF (rCompSeq <> 0) THEN
                      CALL mds_internal_endComponent(newxml, rCompLevel, formatted,
                                                     mPreviousComp, mPreviousValue, 
                                                     mPreviousName, mPreviousLevel,  
                                                     mIsTagOpen, mStack);
                  END IF;
          
                  -- Start building the new component
                  CALL mds_internal_addComponent(newxml,
                                                 rCompSeq, rCompLevel,
                                                 rCompPrefix, rCompLocalName,
                                                 rCompValue, rAttPrefix,
                                                 rAttLocalName, rAttValue,
                                                 rAttLongValue,
                                                 formatted, mPreviousComp,
                                                 mPreviousValue, mPreviousName,
                                                 mPreviousLevel, mIsTagOpen,
                                                 mStack);
              END IF;
          ELSE
              --
              -- This is the same sequence of the previous row, which means
              -- it's only a new attribute, so just add the XML for the attribute
              --
              CALL mds_internal_addAttribute(newxml,
                                             rAttPrefix, 
                                             rAttLocalName,
                                             rAttValue,
                                             rAttLongValue);
          END IF;

          -- Append any leftover XML
          CALL mds_internal_addXMLtoChunk(chunk, newxml);

          SET newxml = '';
      END WHILE;

END_COMP:
      --
      -- We have finished exporting the document.  The only task that remains
      -- it to end the previous component and to unwind the stack
      --
      SET newxml = '';

      -- End the previous element
      CALL mds_internal_endComponent(newxml, 0, formatted,
                                     mPreviousComp, mPreviousValue, 
                                     mPreviousName, mPreviousLevel,
                                     mIsTagOpen,
                                     mStack);
      CALL mds_internal_addXMLtoChunk(chunk, newxml);
  END;

  --
  -- Return the current chunk, and set the partialChunk to NULL so that,
  -- when entering this function again, we will know that we have finished
  -- processing the document.
  --
  IF ( OCTET_LENGTH(retChunk) = 0 ) THEN
      SET LEN = OCTET_LENGTH(chunk);

      IF ( LEN > $MAX_RETURN_CHUNK_SIZE ) THEN
        SET retChunk = LEFT(chunk, $MAX_RETURN_CHUNK_SIZE,OCTETS);
        SET partialChunk = RIGHT(chunk, LEN - $MAX_RETURN_CHUNK_SIZE,OCTETS);
      ELSE
        SET retChunk = chunk;
        SET partialChunk = '';
      END IF;

      -- Save stack value and XML Partial chunk data..
      --CALL mds_internal_saveStackValues(mStack);
      CALL mds_internal_saveXMLPartialChunk(partialChunk, 1);
  ELSE
      CALL mds_internal_saveXMLPartialChunk(chunk, 0);
  END IF;

  RETURN;
END
@


--
-- Export the XML for tip version of a document and pass it back in
-- MAX_RETURN_CHUNK_SIZE chunks.  Each call will try to get 
-- MAX_CHUNK_SIZE, if the retrieved size is larger than MAX_RETURN_CHUNK_SIZE,
-- the overflowed value will be saved in #MDS_SESSION_VARIABLES.PARTIAL_CHUNK.
-- The caller has to retrieve it as well.
--
-- Specifying a document name will initiate the export.  Thereafter, a NULL
-- document name should be passed in until the export is complete.
-- That is, to export an entire document, you should do:
--
-- firstChunk := mds_exportDocumentByName(isDone,
--                                        '/oracle/apps/fnd/mydoc');
-- WHILE (isDone = 0)
--   nextChunk := mds_exportDocumentByName(isDone, NULL);
-- END LOOP;
--
-- Parameters:
--   exportFinished - OUT parameter which indicates whether or not the export
--                    is complete.  1 indicates the entire document is
--                    exported, 0 indicates that there are more chunks
--                    remaining.
--
--   fullName  - the fully qualifued name of the document.  however,
--               after the first chunk of text is exported, a NULL value
--               should be passed in.
--
--   partitionID - the partition where the document exists
--   formatted - a non-zero value indicates that the XML is formatted nicely
--               (i.e. whether or not the elements are indented)
--
-- Returns:
--   The exported XML, in 32k chunks.
--


create PROCEDURE mds_exportDocumentByName(
    INOUT chunk                 VARCHAR($MAX_RETURN_CHUNK_SIZE),
    INOUT exportFinished        SMALLINT,
          partitionID           DECIMAL(31,0),
          fullName              VARCHAR($FULLNAME),
          formatted             SMALLINT)

LANGUAGE SQL

SPECIFIC mds_exportDocumentByName

DYNAMIC RESULT SETS 1

MODIFIES SQL DATA

BEGIN
  DECLARE docID        DECIMAL(31,0);
  DECLARE contentID    DECIMAL(31,0);
  DECLARE versionNum   DECIMAL(31,0);

  --
  -- A non-null fullName indicates that this is the first time this function
  -- is being called for this document.  If so, we need to find the
  -- document ID and start the export process.
  --
  IF (fullName IS NOT NULL AND LENGTH(fullName) > 0) THEN
      CALL mds_getDocumentID(docID, partitionID, fullName, 'DOCUMENT');

      -- Since this method is only used by mds_utils, read the tip version
      SET (contentID, versionNum) = 
                     (SELECT PATH_CONTENTID, PATH_VERSION
                           FROM MDS_PATHS
                           WHERE PATH_DOCID=docID AND PATH_HIGH_CN IS NULL
                                 AND PATH_PARTITION_ID=partitionID);

      IF (docID = -1) THEN
          -- Unable to find the document
          -- ###
          -- ### Give error if unable to locate document
          -- ###
          SET chunk = '';
          RETURN;
      END IF;

      CALL mds_exportDocumentByID(chunk, 
                                  exportFinished, 
                                  partitionID, 
                                  docID, 
                                  contentID, 
                                  versionNum, 
                                  formatted);
  ELSE
      CALL mds_exportDocumentByID(chunk, 
                                  exportFinished, 
                                  partitionID, 
                                  NULL, NULL, NULL, 
                                  formatted);
  END IF;
  RETURN;
END
@

--COMMIT
--@

