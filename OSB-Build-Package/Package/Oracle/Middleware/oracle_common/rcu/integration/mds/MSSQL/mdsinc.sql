
-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- MDSINC.sql - MDS metadata services INternal Common
--
-- Notes:  SQL Server could be configured to be case-sensitive for schema objects,
--         such as table, columna and procedure name.  Please use their exact cases
--         when they are referred in the program.  All table and Column names, defined
--         in MDS, are using Upper case letters.  Procedure and function names use both
--         Upper and Lower case letters.
--
-- MODIFIED    (MM/DD/YY)
-- pwhaley     08/28/12 - XbranchMerge pwhaley_missing_txn_rows from
--                        st_jdevadf_patchset_ias
-- pwhaley     08/08/12 - #(14196246) Don't purge recent transaction rows.
-- jhsi        10/20/11 - Restored fix #(13082724) fixed moTypeName typo
-- erwang      10/11/11 - #(13082724) fixed moTypeName typo
-- jhsi        10/10/11 - Added param contentType to prepareDocForInsert
-- erwang      08/26/11 - Added moTypeName and moTypeNSURI to
--                        prepareDocumentForInsert()
-- vyerrama    02/22/11 - #(11817738) Exclude sandbox docs from purge.
-- vyerrama    07/01/10 - XbranchMerge vyerrama_sandbox_guid from main
-- erwang      06/07/10 - XbranchMerge erwang_bug-9498962 from main
-- erwang      06/01/10 - #(9498962) Added retry upon unique key violation
-- erwang      04/27/10 - #(9625576) Added ERROR_NO_DATA_FOUND exception 
-- akrajend    03/31/10 - #(9551739) Introduce processCommitNew to handle both
--                        critical and non critical section commit
-- rchalava    03/29/10 - Set label creation time in processCommitWithoutCS.
-- akrajend    12/29/09 - #(9151698) Added processCommitWithoutCS.
-- vyerrama    12/10/09 - Added createLineageID
-- erwang      03/02/10 - #(9438558) fix a typo in variable @docIDs in
--                        mds_getDocumentIDs
-- erwang      02/17/10 - XbranchMerge erwang_bug-9377465 from main
-- erwang      02/12/10 - Fix possible security issue by improving boudary situation handling
-- akrajend    01/05/10 - Modify recreateSequence to recreate lineageID
--                        sequence with new lineage value.
-- rchalava    08/19/09 - #(8798576) Increase the size of LABEL_NAME
-- erwang      08/17/09 - Fix typo in drop isPurgeRequired
-- erwang      08/17/09 - Increase the size of creator and label name 
-- pwhaley     08/05/09 - Fix for sandbox deletion changes: ensure new
--                        package version is >= 1.
-- erwang      07/09/09 - Fix an extra comma in the output of getDocumentIDs()
-- rupandey    07/08/09 - #(8576789) added procedure mds_isPurgeRequired. 
--                        Refactored proc mds_processCommit - removed the 
--                        logic to check if purge is required.
-- gnagaraj    06/26/09 - #(8637322) Don't purge mds_txn rows used by labels
-- erwang      06/18/09 - Put constant value in one line to workaround rcu
--                        issue
-- erwang      05/27/09 - Changed to use exists in checking document's
--                        existence
-- erwang      03/26/09 - #(8360103) fixed corrupt sequence error in renaming a document in case a
--                        deleted/renamed document already exists under target package.
-- erwang      03/20/09 - #(8352261) increased the size of PATH_NAME AND
--                        PATH_FULLNAME
-- erwang      03/11/09 - #(8325229) fix possible sql injection
-- pwhaley     01/22/09 - #(7831917) port 6011472 from OracleDB
-- erwang      01/06/09 - Fix txn lock in creating same partition in multiple
--                        threads
-- erwang      12/17/08 - #(7650199) Switch to use SQL Server IDENTITY to simulate Oracle
--                        Sequence to avoid deadlock
-- gnagaraj    10/06/08 - #(7442627) Avoid creating duplicate partitions
-- allechen    08/14/08 - #(7330706) Match the errorcodes with MssqlDB class
-- rupandey    06/12/08 - #(6416307) Optimized SQL in mds_checkDocumentExistence.
-- gnagaraj    06/18/08 - #(7038905) Purge unused transaction rows
-- erwang      06/03/08 - #(7148883) Fixed getOrCreatePartitionID() parameters and java code
--                        mismatch issue.
-- vyerrama    03/31/08 - Merged changes from #(5891638) with #(6726806).
-- abhatt      02/05/08 - #(5891638) Changes requiring repository upgrade
-- gnagaraj    03/17/08 - #(6838583) Purge performance enhancements.
-- gnagaraj    02/13/08 - Remove unused ERROR constants.
-- erwang      12/05/07 - #(6658695) Changed acquireWriteLock() to use
--                        lockDocument()
-- gnagaraj    11/28/07 - #(6600202) Raise exception if document to be locked 
--                        does not exist
-- gnagaraj    11/14/07 - #(6600202) Add acquireWriteLock()
-- pwhaley     11/05/07 - #(5926597) Return transaction commit time.
-- gnagaraj    09/27/07 - #(6446544)Ignore ver leftover by deleteAllVersions()
--                        for computing version number on recreate.
-- gnagaraj    09/12/07 - #(6351111) Avoid parallel purges, fix processCommit
--                        to compute purgeElapse correctly.
-- abhatt      07/12/07 - #(6135856) Remove support for retrying lock 
-- gnagaraj    07/09/07 - #(6165956) Perf fixes: Avoid version queries in
--                        prepareDocumentForInsert()
-- erwang      06/27/07 - #(5919142) Workaround RCU empty string issue.
-- erwang      04/17/07 - change column size etc.
-- gnagaraj    01/24/07 - Perform existence check on create
-- gnagaraj    02/05/07 - #(5862363) Avoid fulltable scan in
--                        prepareDocumentForInsert().
-- erwang      12/27/06 - Globalization Support for SQL server.
-- gnagaraj    01/17/07 - #(5570793) Store transaction time as UTC
-- gnagaraj    01/17/07 - #(5570793) Store transaction time as UTC
-- erwang      12/12/06 - Add checkDocumentExistences
-- erwang      11/27/06 - Remove Isolation level changes and use "READ COMMITTED" with Row Versioning.
-- erwang      11/22/06 - SQL server concurrency
-- gnagaraj    12/11/06 - #(5460992) Serialize commit processing with an
--                        infinite wait.
-- erwang      11/21/06 - Apply changes to MS SQL: changes to continue version number in 
--                        case of document recreate, instead of starting from 1[Bug #5508200]
-- erwang      11/13/06 - Set nocount on to improve peroformance
-- erwang      11/08/06 - Fix some case issues
-- erwang      10/05/06 - Created based on MDSINCB.pls
--

go
set nocount on

-- begin transaction mdsinc
go

-- $Header:
-----------------------------------------------------------------------------
-------------------------------- VARIABLES ----------------------------------
-----------------------------------------------------------------------------
-- Debug flag
:setvar DBGPRINT                       "IF 1 = 1 PRINT " 

-- User-defined exceptions.
-- The error code will be encoded in text message of error 50000.  "'" must be 
-- used in define error code.  
-- The error codes should be kept in sync with mdsinsr.sql and all other scripts 
-- They must also be in sync with errorcode definitions in Java class MssqlDB.

-- External Error Codes to Java layer
:setvar ERROR_DOCUMENT_NAME_CONFLICT  50100
:setvar ERROR_PACKAGE_NAME_CONFLICT   50101
:setvar ERROR_CORRUPT_SEQUENCE        50102
:setvar ERROR_CONFLICTING_CHANGE      50103  
:setvar ERROR_RESOURCE_BUSY           50104
:setvar ERROR_GUID_CONFLICT           50105
:setvar ERROR_RESOURCE_NOT_EXIST      50106
:setvar ERROR_LINEAGE_ALREADY_EXIST   50107


-- Internal Error Codes
:setvar ERROR_CHUNK_SIZE_EXCEEDED     50200
:setvar ERROR_ARRAY_OUT_OF_BOUNDARY   50201
:setvar ERROR_LOCK_TIMEOUT            50202

-- PATH_DOCID of "/" is assumed to be 0
:setvar ROOT_DOCID                    0


-- Enumeration values for PATH_OPERATION values indicating the operation
-- performed on a path (version).
:setvar DELETE_OP                     0
:setvar CREATE_OP                     1
:setvar UPDATE_OP                     2
:setvar RENAME_OP                     3


-- Value used for PATH_HIGH_CN, PATH_LOW_CN when the changes are not yet
-- commited (i.e, in-transaction value). Since no other transaction would
-- see this value (as it is yet uncommited) it is not a problem for all
-- transactions to use this same number as the Commit Number for all CN
-- columns prior to commiting the changes.
-- When the changes are commited, processCommit() replaces this CN value
-- with the commit number generated for that transaction.
:setvar INTXN_CN                     -1

-- Integer constants to denote a true or a false value
:setvar INT_TRUE                     1
:setvar INT_FALSE                   -1

-- constant variables defines the size 
:setvar CREATOR                      64 
:setvar ELEM_NSURI                   800
:setvar ELEM_NAME                    127
:setvar FULLNAME                     400
:setvar GUID                         36
:setvar LABEL_NAME                   400
:setvar PARTITION_NAME               200
:setvar PATH_NAME                    256 
:setvar PATH_TYPE                    30
:setvar VER_COMMENTS                 800
:setvar XML_VERSION                  10
:setvar XML_ENCODING                 60
:setvar DEPL_NAME                    400
:setvar SEQ_NAME                     256

-- System Defined Error ID.  Definition can be found at sys.messages table.
:setvar LOCK_REQUEST_TIMEOUT         1222
:setvar DUP_VAL_ON_CONSTRAINT        2601
:setvar DUP_VAL_ON_INDEX             2627

-- mds will use it to raise MDS exception
:setvar USER_DEFINED_ERROR           50000  

-- Misc 
:setvar MAX_SECONDS_TO_WAIT_FOR_LOCK 10

-- Wait and Retry for update
:setvar DELAY_TIME                   "00:00:01.000"
:setvar RETRY_COUNT                  200
:setvar WITH_NO_WAIT                 "WITH(NOWAIT)"

-- Common code for reraise the exception
:setvar RERAISE_MESSAGE_DECLARE     "DECLARE @ErrorMessage NVARCHAR(4000); DECLARE @ErrorSeverity INT; DECLARE @ErrorState INT;"

:setvar RERAISE_EXCEPTION           "SELECT @ErrorMessage = CASE ERROR_NUMBER() WHEN 50000 THEN ERROR_MESSAGE() ELSE CONVERT(NVARCHAR, ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE() END, @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(); RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); RETURN;" 
-----------------------------------------------------------------------------
----------------------------- PRIVATE FUNCTIONS -----------------------------
-----------------------------------------------------------------------------
--
-- Get string size include trailing space.
-- Parameters
--     @value        String value to be valued.
-- Return INT        size.
--
IF (object_id(N'mds_internal_getLength', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_internal_getLength
END
go

create FUNCTION mds_internal_getLength (@value  $(MDS_VARCHAR)(MAX)) RETURNS INT
AS
BEGIN
  DECLARE @LEN  INT;

  IF (@value IS NULL)
    RETURN 0;

  SET @LEN = LEN(@value + N'|') - 1;

  RETURN @LEN;
END
go

--
-- Generates a unique(within the repository partition) commit number(CN) for
-- the transaction
-- Parameters
--     @commitNumber Commit number.
--     @partitionID  PartitionID for the repository partition
--
IF (object_id(N'mds_internal_generateCommitNumber', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_generateCommitNumber
END
go

create PROCEDURE mds_internal_generateCommitNumber (@commitNumber  NUMERIC OUTPUT,
                                                    @partitionID   NUMERIC)
AS
BEGIN
  DECLARE @err           INT;
  DECLARE @rowc          INT;
  DECLARE @count         TINYINT;
  
  SET NOCOUNT ON;

  SET @count = 0;
  SET @commitNumber = 1; -- Default value if no txn has occured in this parition
    
  BEGIN

    WHILE @count < 3 
    BEGIN
        SET @count = @count + 1;

        -- Return the next commit number after locking the commit number row so
        -- so that no another transaction can commit parallelly
        -- #(5460992) - Use an infinite wait. Using a NOWAIT in a loop
        -- is inefficient and does not help when large number of
        -- transactions are involved.    
        SELECT @commitNumber = LOCK_TXN_CN
          FROM MDS_TXN_LOCKS 
          WITH (READCOMMITTEDLOCK, UPDLOCK, ROWLOCK)
          WHERE LOCK_PARTITION_ID = @partitionID;

        SELECT @err=@@error, @rowc=@@rowcount;

        IF (@err = 0 AND @rowc = 0)
        BEGIN
          -- No txn has occured in this partition, intialize the transaction number
          -- for this partition and lock the row so that no another transaction
          -- can start committing parallelly
          BEGIN TRY
              INSERT INTO MDS_TXN_LOCKS values(@partitionID, @commitNumber);

              SELECT @commitNumber = LOCK_TXN_CN
                FROM MDS_TXN_LOCKS
                WITH (READCOMMITTEDLOCK , UPDLOCK, ROWLOCK)
                WHERE LOCK_PARTITION_ID = @partitionID;
              RETURN;
          END TRY
          BEGIN CATCH
              $(RERAISE_MESSAGE_DECLARE)

              IF (ERROR_NUMBER() <> $(DUP_VAL_ON_INDEX) AND 
                 ERROR_NUMBER() <> $(DUP_VAL_ON_CONSTRAINT)) OR
                 @count > 3
              BEGIN
                  -- Have 3 tries already, rethrow exception.
                  $(RERAISE_EXCEPTION)
              END

              -- Someone may just insert a row, let try again.
              CONTINUE;
     
          END CATCH
        END
    
        -- Bump up the cn number and set the new value to @commitNumber.
        UPDATE MDS_TXN_LOCKS 
          WITH (UPDLOCK, ROWLOCK)
          SET @commitNumber=LOCK_TXN_CN+1,
            LOCK_TXN_CN=LOCK_TXN_CN+1             
          WHERE LOCK_PARTITION_ID=@partitionID;

        RETURN;
    END
  END    
END
go

--
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
IF (object_id(N'mds_checkDocumentExistence', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_checkDocumentExistence
END
go

create PROCEDURE mds_checkDocumentExistence(@results     $(MDS_VARCHAR)(4000) OUTPUT,
         	                            @partitionID NUMERIC,
		                            @patterns    $(MDS_VARCHAR)(4000)) 
AS
BEGIN
  DECLARE @found        $(MDS_VARCHAR)(10);

  DECLARE @startPOS     INT;
  DECLARE @sepPOS       INT;
  DECLARE @len          INT;
  DECLARE @count        INT;
  DECLARE @total_len    INT;
  DECLARE @pattern      $(MDS_VARCHAR)(4000);
  DECLARE @prev         $(MDS_VARCHAR)(10);

  SET NOCOUNT ON;

  -- If it is an empty string, return here.
  IF (@patterns IS NULL OR 
              LEN(@patterns) = 0)
      RETURN;

  SET @startPOS = 1;
  SET @sepPOS   = -1;  -- Initialize with non 0 value.
  SET @results  = N'';
  SET @prev     = N'NOT_FOUND';
  SET @count    =  0;

  SET @total_len = LEN(@patterns);
    
  WHILE (@sepPOS <> 0)
  BEGIN
    SET @sepPOS = CHARINDEX(N',', @patterns, @startPOS);
    
    IF (@sepPOS = 0)
      SET @len = @total_len - @startPOS + 1;
    ELSE
      SET @len = @sepPOS - @startPOS;

    SELECT @pattern = SUBSTRING(@patterns, @startPOS, @len);


    -- #(6416307) This optimization was done to prevent executing queries for
    -- patterns for which no documents would ever be found. The query is executed
    -- for the first pattern in patterns, and subsequent patterns are evaluated for
    -- document matches only if the more general pattern before it resulted
    -- in a successful hit on the database. The ordering in the patterns is very important
    -- since if a more general pattern is not found then there is no need to fire a 
    -- database query. This optimization resulted in significant performance improvement
    -- in PSR tests with a small size PDCache.
    SET @found = N'NOT_FOUND';

    IF ( @count = 0 or @prev = 'FOUND' )
    BEGIN
        SELECT @found = N'FOUND' 
           WHERE EXISTS
             (SELECT PATH_FULLNAME FROM MDS_PATHS
               WHERE PATH_PARTITION_ID = @partitionID
               AND PATH_TYPE= N'DOCUMENT'
	           AND PATH_FULLNAME like @pattern);
        IF (@@error = 0 AND @@rowcount = 0)
            SET @found = N'NOT_FOUND'; 
    END

    -- Append ',' if results already contains values.
    IF (@count > 0)
        SET @results = @results + N',';

    SET @results = @results + @found;
    SET @prev = @found;

    SET @count = @count + 1;

    -- Try to not overflow the results. (LEN('NOT_FOUND') + 1) * 400 = 4000 characters.
    IF (@count >= 400)
      RETURN;
      
    IF (@sepPOS <> 0)
    BEGIN
      -- Shift the position to the right of @sepPOS.
      SET @startPOS = @sepPOS + 1;

      -- If the last character is ',', we will append one 'NOT_FOUND' and set @setPOS to 0.
      IF (@startPOS > @total_len)
      BEGIN
        -- Add ',' and 'NOT_FOUND'.  We know there is value in @results.
        SET @results = @results + N',' + N'NOT_FOUND'; 

        SET @sepPOS = 0;   -- To exit in next loop.
      END
    END
  END
END
go

-- Creates a transaction
--
-- Generates an unique commit number and inserts a new transaction 
-- entry into mds_transactions
-- Parameters
--     @commitNumber Commit Number.
--     @partitionID  PartitionID for the repository partition
--     @userName     User whose changes are being commited, can be null.
--
IF (object_id(N'mds_createNewTransaction', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_createNewTransaction
END
go

create PROCEDURE mds_createNewTransaction (@commitNumber        NUMERIC OUTPUT,
                                           @partitionID         NUMERIC,
                                           @userName            $(MDS_VARCHAR)($(CREATOR)))
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY   
    -- Call mds_internal_generateCommitNumber.
    EXEC mds_internal_generateCommitNumber @commitNumber OUTPUT, @partitionID


    -- Record the creator and time information for this transaction
    -- #(5570793) Store the transaction time as UTC so that it can be compared
    -- with mid-tier time correctly when mid-tier and repository are on different
    -- timezones
    INSERT INTO MDS_TRANSACTIONS
      (TXN_PARTITION_ID, TXN_CN, TXN_CREATOR, TXN_TIME)
       VALUES(@partitionID, @commitNumber, @userName, getUTCDate());
  END TRY
  BEGIN CATCH
    $(RERAISE_MESSAGE_DECLARE)
    $(RERAISE_EXCEPTION)
  END CATCH
    
  RETURN
END
go
  
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
--
-- Parameters
--  @commitNumber      Commit Number.
--  @userName          User whose changes are being commited, can be null.
--  @autoPurgeInterval Minimum time interval to wait before invoking the next 
--                    autopurge
--  @doPurgeCheck      Value to indicate whether to do a purge check or not
--  @currentDBTime     OUT parameter, populated with current system time if
--                     autopurge needs to be invoked, otherwise is set to null
--  @commitDBTime      OUT parameter, transaction commit time
--  isCSCommit         IN OUT parameter. Calling procedure can request whether
--                    to commit the transaction with critical section ( by 
--                    specifying value 1) or not (value as -1) using 
--                    this parameter. Even if the request is for commit
--                    without critical section, we may internally commit
--                    the transaction with critical section if required. The
--                    out value will always reflect whether the actual commit
--                    was done with CS (value 1) or not (value -1).
--
IF (object_id(N'mds_processCommitNew', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_processCommitNew
END
go

create PROCEDURE mds_processCommitNew(
                                   @commitNumber         NUMERIC OUTPUT,
                                   @partitionID          NUMERIC,
                                   @username             $(MDS_VARCHAR)($(CREATOR)),
                                   @autoPurgeInterval    NUMERIC,
                                   @doPurgeCheck         NUMERIC,
                                   @purgeRequired        NUMERIC OUTPUT,
                                   @commitDBTime         DATETIME OUTPUT,
                                   @isCSCommit           NUMERIC OUTPUT)
AS
BEGIN
  DECLARE @systemTime    DATETIME;
  DECLARE @err           INT;
  DECLARE @rowc          INT;

  DECLARE @c             CURSOR;

  DECLARE @docID         NUMERIC;
  DECLARE @version       NUMERIC;
  DECLARE @depID         NUMERIC;
  DECLARE @labelName     $(MDS_VARCHAR)($(LABEL_NAME));

  SET NOCOUNT ON;

  -- Store the system time in a local variable
  -- to remove any inaccuracies in using it in the query below
  -- #(5570793) - Always store timestamps as UTC
  SET @systemTime= getUTCDate();
  -- #(5926597) - Return transaction commit time
  SET @commitDBTime = @systemTime;
  SET @purgeRequired = -1;
  BEGIN TRY

    IF ( @isCSCommit = $(INT_TRUE) )
    BEGIN
     
        -- NOTE: Do any processing before invoking createNewTransaction(),
        --       so that we dont lock the rows in createNewTransaction()
        --       for longer time.

        -- Generates an unique commit number and inserts a new transaction
        -- entry into mds_transactions
        EXEC mds_createNewTransaction @commitNumber OUTPUT,
                                      @partitionID,
                                      @username;
    
        -- #(7650199) Switch to use a cusor to read all committed row and update
        -- one by one.  For SQL server, if a new row is added or an existing is 
        -- updated with PATH_LOW_CN = -1 by another transaction, even if the
        -- change is not committed, UPDATE MDS_PAHTS SET ...
        -- WHERE PATH_LOW_CN = -1 AND ... will be blocked by the newly added
        -- or changed row done by other txn. If two txn add or update documents,
        -- even they are not updating the same document, it may still introduce
        -- deadlock.  Updating through the cursor will only update the rows
        -- that are committed and will reduce the chance to get 
        -- deadlock.  Following changes are based on the same reason.

        -- Documents, packages that were created
        -- UPDATE MDS_PATHS WITH(ROWLOCK)
        --   SET PATH_LOW_CN=@commitNumber
        --   WHERE PATH_LOW_CN=$(INTXN_CN) AND PATH_PARTITION_ID=@partitionID;
    
        SET @c = CURSOR LOCAL FORWARD_ONLY KEYSET FOR
                    SELECT PATH_DOCID, PATH_VERSION
                      FROM MDS_PATHS 
                        WHERE PATH_PARTITION_ID=@partitionID AND 
                              PATH_LOW_CN=$(INTXN_CN)
                    FOR UPDATE OF PATH_LOW_CN;
    
        OPEN @c;
    
        FETCH NEXT FROM @c INTO @docID, @version;
    
        -- @@FETCH_STATUS  0:  a normal row fetched.
        --                -1:  end of list.
        --                -2:  the row is missing or deleted. 
    
        WHILE ( @@FETCH_STATUS != -1 )    
        BEGIN
          -- Make sure that we don't update deleted row.
          IF ( @@FETCH_STATUS != -2 )
            UPDATE MDS_PATHS
              SET PATH_LOW_CN = @commitNumber
              WHERE CURRENT OF @c;            
    
          FETCH NEXT FROM @c INTO @docID, @version;
        END
    
        CLOSE @c;
    
        DEALLOCATE @c;
    
        -- Documents, packages that were deleted or docs superceded by
        -- new version
        -- UPDATE MDS_PATHS WITH(ROWLOCK)
        --  SET PATH_HIGH_CN=@commitNumber
        --  WHERE PATH_HIGH_CN=$(INTXN_CN) AND PATH_PARTITION_ID=@partitionID;
    
        SET @c = CURSOR LOCAL FORWARD_ONLY KEYSET FOR
                    SELECT PATH_DOCID, PATH_VERSION
                      FROM MDS_PATHS 
                        WHERE PATH_PARTITION_ID=@partitionID AND 
                              PATH_HIGH_CN=$(INTXN_CN)
                      FOR UPDATE OF PATH_HIGH_CN;
    
        OPEN @c;
    
        FETCH NEXT FROM @c INTO @docID, @version;
    
        
        WHILE ( @@FETCH_STATUS != -1 )    
        BEGIN
          -- Make sure that we don't update deleted row.
          IF ( @@FETCH_STATUS != -2 )
            UPDATE MDS_PATHS 
              SET PATH_HIGH_CN=@commitNumber
              WHERE CURRENT OF @c;
    
          FETCH NEXT FROM @c INTO @docID, @version;
        END
    
        CLOSE @c;
    
        DEALLOCATE @c;
    
        -- Dependencies that were created
        -- UPDATE MDS_DEPENDENCIES WITH(ROWLOCK)
        --  SET DEP_LOW_CN=@commitNumber
        --   WHERE DEP_LOW_CN=$(INTXN_CN) AND DEP_PARTITION_ID=@partitionID;
    
        SET @c = CURSOR LOCAL FORWARD_ONLY KEYSET FOR
                    SELECT DEP_ID
                      FROM MDS_DEPENDENCIES 
                        WHERE DEP_PARTITION_ID=@partitionID AND 
                              DEP_LOW_CN=$(INTXN_CN)
                        FOR UPDATE OF DEP_LOW_CN;
    
        OPEN @c;
    
        FETCH NEXT FROM @c INTO @depID;
    
        WHILE ( @@FETCH_STATUS != -1 )    
        BEGIN
          -- Make sure that we don't update deleted row.
          IF ( @@FETCH_STATUS != -2 )
            UPDATE MDS_DEPENDENCIES
               SET DEP_LOW_CN=@commitNumber
               WHERE CURRENT OF @c;
    
          FETCH NEXT FROM @c INTO @depID;
        END
    
        CLOSE @c;
    
        DEALLOCATE @c;
    
        -- Dependencies that were deleted or superceded by new version
        -- UPDATE MDS_DEPENDENCIES WITH(ROWLOCK)
        --  SET DEP_HIGH_CN=@commitNumber
        --  WHERE DEP_HIGH_CN=$(INTXN_CN) AND DEP_PARTITION_ID=@partitionID;
    
        SET @c = CURSOR LOCAL FORWARD_ONLY KEYSET FOR
                    SELECT DEP_ID
                      FROM MDS_DEPENDENCIES
                        WHERE DEP_PARTITION_ID=@partitionID AND 
                              DEP_HIGH_CN=$(INTXN_CN)
                        FOR UPDATE OF DEP_HIGH_CN;
    
        OPEN @c;
    
        FETCH NEXT FROM @c INTO @depID;
    
        WHILE ( @@FETCH_STATUS != -1 )    
        BEGIN
          -- Make sure that we don't update deleted row.
          IF ( @@FETCH_STATUS != -2 )
            UPDATE MDS_DEPENDENCIES
               SET DEP_HIGH_CN=@commitNumber
               WHERE CURRENT OF @c;
    
          FETCH NEXT FROM @c INTO @depID;
        END
    
        CLOSE @c;
    
        DEALLOCATE @c;
    
        -- Labels created in this transaction
        -- UPDATE MDS_LABELS WITH(ROWLOCK)
        --  SET LABEL_CN=@commitNumber
        --  WHERE LABEL_CN=$(INTXN_CN) AND LABEL_PARTITION_ID=@partitionID;
    
        SET @c = CURSOR LOCAL FORWARD_ONLY KEYSET FOR
                    SELECT LABEL_NAME 
                      FROM MDS_LABELS
                        WHERE LABEL_PARTITION_ID=@partitionID AND 
                              LABEL_CN=$(INTXN_CN)
                        FOR UPDATE OF LABEL_CN;
    
        OPEN @c;
    
        FETCH NEXT FROM @c INTO @labelName;
    
        WHILE ( @@FETCH_STATUS != -1 )    
        BEGIN
          -- Make sure that we don't update deleted row.
          IF ( @@FETCH_STATUS != -2 )
            UPDATE MDS_LABELS 
              SET LABEL_CN=@commitNumber
              WHERE CURRENT OF @c;
    
          FETCH NEXT FROM @c INTO @labelName;
        END
    
        CLOSE @c;
    
        DEALLOCATE @c;
    END;
    ELSE
    BEGIN
    
        -- No new transaction, just update Labels table with creation time.
        -- For now, labels table is the only one that is processed when not 
        -- using CS and other tables are also handled as no-CS but currently
        -- not required any processing.

        -- Get the latest commit number from the mds_txn_locks table.
        SELECT @commitNumber = LOCK_TXN_CN
          FROM MDS_TXN_LOCKS
          WHERE LOCK_PARTITION_ID = @partitionID;
        
        -- Update the labels created in this transaction
        -- UPDATE MDS_LABELS WITH(ROWLOCK)
        --  SET LABEL_CN=@commitNumber
        --  WHERE LABEL_CN=$(INTXN_CN) AND LABEL_PARTITION_ID=@partitionID;
    
        SET @c = CURSOR LOCAL FORWARD_ONLY KEYSET FOR
                    SELECT LABEL_NAME 
                      FROM MDS_LABELS
                        WHERE LABEL_PARTITION_ID=@partitionID AND 
                              LABEL_CN=$(INTXN_CN)
                        FOR UPDATE OF LABEL_CN, LABEL_TIME;
    
        OPEN @c;
    
        FETCH NEXT FROM @c INTO @labelName;
        
        -- If there are some rows to update, but the commit number is not
        -- available in the txn table, mark the criticalSectionRequired flag
        -- to TRUE and create.
        IF ( @@FETCH_STATUS != -1 AND @commitNumber is NULL )
        BEGIN
            -- It means that no commit number is available for this
            -- partition, but there are some rows to update, Go through critical
            -- section to create a new CN now.
            EXEC mds_createNewTransaction @commitNumber OUTPUT,
                                          @partitionID,
                                          @username;
            
            -- Mark the flag that we commit the transaction with critical
            -- section.                      
            SET @isCSCommit = $(INT_TRUE);
        END
    
        WHILE ( @@FETCH_STATUS != -1 )    
        BEGIN
          -- Make sure that we don't update deleted row.
          IF ( @@FETCH_STATUS != -2 )
          BEGIN
            -- If it is a critical section commit, the txn_time itself will
            -- represent the label creation time. Hence no need to set the label
            -- creation time explicitly in labels table.
            -- If it is a commit without critical section, we need to set the
            -- label creation time explicitly.
            IF ( @isCSCommit = $(INT_TRUE) )
            BEGIN
                UPDATE MDS_LABELS 
                    SET LABEL_CN=@commitNumber
                    WHERE CURRENT OF @c;
            END;
            ELSE
            BEGIN
                -- it is a commit without critical section, we need to set the
                -- label creation time explicitly.
                UPDATE MDS_LABELS 
                    SET LABEL_CN=@commitNumber, LABEL_TIME = @systemTime
                    WHERE CURRENT OF @c;
            END;
          END  
          FETCH NEXT FROM @c INTO @labelName;
        END
        CLOSE @c;
        DEALLOCATE @c;
    END;
  END TRY
  BEGIN CATCH
    $(RERAISE_MESSAGE_DECLARE)
    $(RERAISE_EXCEPTION)
  END CATCH
END
go


-- Does all the processing for commiting metadata changes made in a
-- transaction. Calling this method will ensure that the commit is always done
-- using a critical section. This method is maintained for backward
-- compatibility reasons. This method can be removed when backward 
-- compatibility is no longer an issue.
--
-- Parameters
--  @commitNumber      Commit Number.
--  @userName          User whose changes are being commited, can be null.
--  @autoPurgeInterval Minimum time interval to wait before invoking the next 
--                    autopurge
--  @doPurgeCheck      Value to indicate whether to do a purge check or not
--  @currentDBTime     OUT parameter, populated with current system time if
--                     autopurge needs to be invoked, otherwise is set to null
--  @commitDBTime      OUT parameter, transaction commit time
--
IF (object_id(N'mds_processCommit', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_processCommit
END
go

create PROCEDURE mds_processCommit(
                               @commitNumber         NUMERIC OUTPUT,
                               @partitionID          NUMERIC,
                               @username             $(MDS_VARCHAR)($(CREATOR)),
                               @autoPurgeInterval    NUMERIC,
                               @doPurgeCheck         NUMERIC,
                               @purgeRequired        NUMERIC OUTPUT,
                               @commitDBTime         DATETIME OUTPUT)
AS
BEGIN

  DECLARE @isCSCommit  NUMERIC;

  SET @isCSCommit = $(INT_TRUE);

  EXEC mds_processCommitNew @commitNumber OUTPUT,
                            @partitionID,
                            @username,
                            @autoPurgeInterval,
                            @doPurgeCheck,
                            @purgeRequired OUTPUT,
                            @commitDBTime OUTPUT,
                            @isCSCommit OUTPUT;
END
go


-- Does all the processing for commiting metadata changes made without getting
-- the critical section, i.e. no lock is being acquired in MDS_TXN_LOCKS table.
-- If it finds that the connection needs critical section to commit the 
-- changes, it will not do any processing and will simply return true value
-- for 'criticalSectionRequired' flag.
--
-- It does the following operation as part of this.
--
-- (i) Sets the LABEL_CN to commit number that is most recent, the label
-- can be used to read any content that existed at this CN (including
-- changes in this transaction) or before.
--
-- This method can be removed when backward compatibility is no longer an issue.
--
-- Parameters
--  @criticalSectionRequired      OUT Parameter. 1 if it cannot be proceeded
--                                without critical section.
--  @partitionID                  Numeric value for the partition-id.
--
IF (object_id(N'mds_processCommitWithoutCS', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_processCommitWithoutCS
END
go

create PROCEDURE mds_processCommitWithoutCS(
                                   @criticalSectionRequired  INT OUTPUT,
                                   @partitionID              NUMERIC)
AS
BEGIN
  DECLARE @c             CURSOR;
  DECLARE @commitNumber  NUMERIC;
  DECLARE @labelName     $(MDS_VARCHAR)($(LABEL_NAME));
  DECLARE @systemTime    DATETIME;
  
  SET @commitNumber = NULL;
  SET @labelName = NULL;
  SET @criticalSectionRequired = $(INT_FALSE);
  SET NOCOUNT ON;
  SET @systemTime= getUTCDate();
  
  BEGIN TRY
    
    SELECT @commitNumber = LOCK_TXN_CN
      FROM MDS_TXN_LOCKS
      WHERE LOCK_PARTITION_ID = @partitionID;
    
    -- Update the labels created in this transaction
    -- UPDATE MDS_LABELS WITH(ROWLOCK)
    --  SET LABEL_CN=@commitNumber
    --  WHERE LABEL_CN=$(INTXN_CN) AND LABEL_PARTITION_ID=@partitionID;

    SET @c = CURSOR LOCAL FORWARD_ONLY KEYSET FOR
                SELECT LABEL_NAME 
                  FROM MDS_LABELS
                    WHERE LABEL_PARTITION_ID=@partitionID AND 
                          LABEL_CN=$(INTXN_CN)
                    FOR UPDATE OF LABEL_CN, LABEL_TIME;

    OPEN @c;

    FETCH NEXT FROM @c INTO @labelName;
    
    -- If there are some rows to update, but the commit number is not
    -- available in the txn table, mark the criticalSectionRequired flag
    -- to TRUE and don't do anything else.
    IF ( @@FETCH_STATUS != -1 AND @commitNumber is NULL )
    BEGIN
        SET @criticalSectionRequired = $(INT_TRUE);
        
        -- Clear the cursor and return.
        CLOSE @c;
        DEALLOCATE @c;
        RETURN;
    END

    WHILE ( @@FETCH_STATUS != -1 )    
    BEGIN
      -- Make sure that we don't update deleted row.
      IF ( @@FETCH_STATUS != -2 )
      BEGIN
         UPDATE MDS_LABELS 
              SET LABEL_CN=@commitNumber, LABEL_TIME = @systemTime
              WHERE CURRENT OF @c;
      END  
      FETCH NEXT FROM @c INTO @labelName;
    END
    CLOSE @c;
    DEALLOCATE @c;

  END TRY
  BEGIN CATCH
    $(RERAISE_MESSAGE_DECLARE)
    $(RERAISE_EXCEPTION)
  END CATCH
END
go


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
--  dbSystimeTime     OUT parameter. Current DB system time.
--
IF (object_id(N'mds_isPurgeRequired', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_isPurgeRequired
END
go

create PROCEDURE mds_isPurgeRequired(@partitionID       NUMERIC,
                                     @autoPurgeInterval NUMERIC,
                                     @purgeRequired     NUMERIC OUTPUT,
                                     @dbSystemTime      DATETIME OUTPUT)
AS
BEGIN
  DECLARE @systemTime    DATETIME;
  DECLARE @purgeDBTime   DATETIME;
  -- Store the system time in a local variable
  -- to remove any inaccuracies in using it in the query below
  -- #(5570793) - Always store timestamps as UTC
  SET @systemTime= getUTCDate();
  SET @purgeRequired = 0;
  -- Determine if Auto purge should be invoked or not.
     SELECT @purgeDBTime = @systemTime
          WHERE EXISTS(
            SELECT PARTITION_LAST_PURGE_TIME FROM MDS_PARTITIONS
                    WHERE
                      (DATEDIFF(second, PARTITION_LAST_PURGE_TIME, @systemTime)
                      > @autoPurgeInterval)
                      AND PARTITION_ID = @partitionID);
      IF (@@error = 0 AND @@rowcount = 0)
      BEGIN
          -- No_Data_Found implies that the purge interval has not elapsed hence
          -- the query did not return the current time.
          SET @purgeDBTime = NULL;
      END;
      ELSE
      BEGIN
        -- #(6351111) Update partitions table immediately
        -- to reduce the chances for multiple threads initiating purge 
        -- in parallel
        -- Note that unlike with Oracle DB, we can not commit the
        -- update immediately since there does not seem to be an equivalent
        -- of AUTONOMOUS_TRANSACTION for SQLServer.
        -- This transaction is commited by AutoPurgeThread#isPurgeRequired.
        UPDATE MDS_PARTITIONS WITH(ROWLOCK)
          SET PARTITION_LAST_PURGE_TIME=@systemTime
          WHERE PARTITION_ID=@partitionID;
      END;

      IF ( @purgeDBTime IS NOT NULL )
      BEGIN
        SET @purgeRequired = 1;
        SET @dbSystemTime = @purgeDBTime;
      END;

END
go



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
  --  isAutoPurge       - 0 if manual purge and 1 if auto-purge
 --   commitNumber      - Commit number used for purging path and content tables
  --
IF (object_id(N'mds_internal_purgeMetadata', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_purgeMetadata
END
go

create PROCEDURE mds_internal_purgeMetadata(@numVersionsPurged  NUMERIC OUTPUT,
                                            @partitionID        NUMERIC,                     
                                            @purgeCompareTime   DATETIME,
                                            @secondsToLive      NUMERIC,
                                            @isAutoPurge        NUMERIC, 
                                            @commitNumber       NUMERIC OUTPUT)
AS
BEGIN
  DECLARE @purgeCN NUMERIC;
   
  -- First, find the CN that is closest to the purge time (so that we
  -- don't have to do a full table scan of mds_tranasctions in a subquery)
  SELECT @purgeCN = MAX(TXN_CN) FROM MDS_TRANSACTIONS
     WHERE TXN_PARTITION_ID=@partitionID AND TXN_TIME < @purgeCompareTime;

  SET @commitNumber = @purgeCN;

  -- #(6838583) Populate the mds_purge_data with details of versions that 
  -- qualify for purge
  INSERT INTO MDS_PURGE_PATHS
    (PPATH_CONTENTID, PPATH_LOW_CN, PPATH_HIGH_CN, PPATH_PARTITION_ID)
    (SELECT PATH_CONTENTID, PATH_LOW_CN, PATH_HIGH_CN, PATH_PARTITION_ID
       FROM MDS_PATHS path
       WHERE PATH_LOW_CN <= @purgeCN
         AND PATH_LOW_CN > 0          -- Don't purge non-committed (-1) 
         AND NOT EXISTS               -- Not covered by any label or non-tip
           (SELECT LABEL_CN FROM MDS_LABELS
              WHERE path.PATH_LOW_CN <= LABEL_CN
              AND (path.PATH_HIGH_CN > LABEL_CN OR path.PATH_HIGH_CN IS NULL)
              AND LABEL_PARTITION_ID = path.PATH_PARTITION_ID)
       -- This check is required in the outer query again for not deleting the 
       -- tip when two versions of the document are created in the same
       -- transaction and hence have the same low_cn for the deleted and the
       -- tip version
       AND PATH_HIGH_CN IS NOT NULL
       -- #(11817738) Sandbox apply needs older versions and since sandbox
       -- destroy deletes all sandbox content, no need to purge sandbox documents
       AND PATH_FULLNAME NOT LIKE '/mdssys/sandbox/%'
       AND PATH_PARTITION_ID = @partitionID);

  SELECT @numVersionsPurged = @@rowcount;

  IF ( @numVersionsPurged = 0 )
  BEGIN
    -- Nothing to do if no qualifying paths were found
    RETURN;
  END;

  -- Delete paths
  DELETE FROM MDS_PATHS WHERE PATH_PARTITION_ID = @partitionID AND
    EXISTS
      (SELECT 'x' FROM MDS_PURGE_PATHS
         WHERE PATH_LOW_CN = PPATH_LOW_CN
           AND PATH_HIGH_CN = PPATH_HIGH_CN
           AND PATH_PARTITION_ID = PPATH_PARTITION_ID);  
           
  -- To avoid purging shared content, remove any purge row still whose content
  -- is still referenced by MDS_PATHS
  DELETE FROM MDS_PURGE_PATHS WHERE PPATH_PARTITION_ID = @partitionID AND
    PPATH_CONTENTID IN 
      (SELECT PATH_CONTENTID FROM MDS_PATHS WHERE
        PATH_PARTITION_ID = @partitionID);

  -- Delete Streamed content if any
  DELETE  FROM MDS_STREAMED_DOCS WHERE SD_PARTITION_ID = @partitionID
    AND SD_CONTENTID IN
    (SELECT PPATH_CONTENTID FROM MDS_PURGE_PATHS
      WHERE PPATH_PARTITION_ID = @partitionID);

  -- Delete dependencies if any
  DELETE FROM MDS_DEPENDENCIES WHERE DEP_LOW_CN IN
    (SELECT PPATH_LOW_CN FROM MDS_PURGE_PATHS
      WHERE PPATH_PARTITION_ID = @partitionID);
      
  -- #(7038905) Delete any unused transaction rows
  -- #(14196246) SQLServer's Read-Committed-Snapshot isolation mode
  -- causes problems for this deletion: it will see MDS_TRANSACTIONS rows
  -- that have been committed after the start of the delete, but it
  -- won't see any corresponding MDS_PATHS rows. Fix this by including
  -- a condition on @purgeCN.
  DELETE FROM MDS_TRANSACTIONS
    WITH (ROWLOCK, READPAST)
    WHERE TXN_PARTITION_ID=@partitionID
    AND TXN_CN <= @purgeCN
    AND NOT EXISTS (SELECT 'x' FROM MDS_PATHS
                    WHERE PATH_PARTITION_ID = @partitionID
                    AND PATH_LOW_CN=TXN_CN)
    AND NOT EXISTS (SELECT 'x' FROM MDS_PATHS
                    WHERE PATH_PARTITION_ID = @partitionID
                    AND PATH_HIGH_CN IS NOT NULL AND PATH_HIGH_CN = TXN_CN)
    -- #(8637322) Don't purge mds_txn rows used by labels
    AND NOT EXISTS (SELECT 'x' FROM MDS_LABELS
                    WHERE LABEL_PARTITION_ID = @partitionID
                    AND LABEL_CN = TXN_CN);
    
  -- Purge unused lineage rows
  -- Deferred from PS2 since the lineage could be in use. 
  -- See deployment optimization spec. for details. Need to revisit later.
  -- DELETE FROM MDS_DEPL_LINEAGES WHERE DL_PARTITION_ID=@partitionID
  --  AND NOT EXISTS (SELECT 'x' FROM MDS_PATHS
  --                  WHERE PATH_PARTITION_ID = @partitionID
  --                  AND PATH_LINEAGE_ID=DL_LINEAGE_ID);

  -- Content tables are purged in mds_internal_shredded.purgeMetadata()
  -- from which this procedure is called

  -- Update the purgeTime if it manual purge, for auto-purge it is updated
  -- in processCommit() itself.
  IF ( @isAutoPurge = 0 )
  BEGIN
    UPDATE MDS_PARTITIONS
      SET PARTITION_LAST_PURGE_TIME = getUTCDate()
      WHERE PARTITION_ID = @partitionID;
  END;
END
go
  

--
-- Get the content sequence name.  
--
-- Parameters:
--   @partitionID        - Partition Number.
-- Returns:
--   the name of sequence. 
IF (object_id(N'mds_getContentSequenceName', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_getContentSequenceName
END
go

create FUNCTION mds_getContentSequenceName(@partitionID   NUMERIC) RETURNS $(MDS_VARCHAR)($(SEQ_NAME))
AS
BEGIN  
  DECLARE @strID      $(MDS_VARCHAR)(50);

  SELECT @strID = CASE 
                    WHEN @partitionID IS NULL THEN '' 
                    WHEN @partitionID < 0 THEN 'n' + CONVERT($(MDS_VARCHAR), ABS(@partitionID))
                    ELSE CONVERT($(MDS_VARCHAR), @partitionID) 
                  END;

  RETURN ( N'MDS_SEQUENCE_CONTENT_ID_' + @strID);
END
go


--
-- Get the next sequence number.  
--
-- Parameters:
--   @setNumber OUTPUT - Sequence Number.
--   @seqName          -  Sequence Name.
--
IF (object_id(N'mds_getNextSequence', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_getNextSequence
END
go

create PROCEDURE mds_getNextSequence(@seqNumber    NUMERIC OUTPUT,
                                     @seqName      $(MDS_VARCHAR)($(SEQ_NAME)))
AS
BEGIN  
  DECLARE @seqNo   NUMERIC;
  DECLARE @sql     NVARCHAR(1024);

  SET NOCOUNT ON;

  -- Replace possible ';' with '_' to avoid possible sql injection.
  SET @seqName = REPLACE(@seqName, ';', '_');

  IF (object_id(@seqName, N'U') IS NULL)
  BEGIN
    -- The object doesn't exist.

    SELECT @sql = 'CREATE TABLE ' + @seqName + 
                  '(ID        NUMERIC IDENTITY(1,1) UNIQUE NOT NULL)'
    EXEC (@sql)

  END;


  SELECT @sql = 'INSERT INTO ' + @seqName + ' DEFAULT VALUES'
  EXEC (@sql) 

  -- Get the last identity that is used to insert into the table.
  SELECT @seqNumber=@@IDENTITY

  -- We don't want the table piled up with a lot of records.  
  SELECT @sql = 'DELETE FROM ' + @seqName + ' WHERE ID = ' + 
                    CONVERT($(MDS_VARCHAR), @seqNumber)
  EXEC (@sql) 

  RETURN;
END
go

--
-- Get the doc sequence name.  
--
-- Parameters:
--   @partitionID        - Partition Number.
-- Returns:
--   the name of sequence. 
IF (object_id('mds_getDocSequenceName', 'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_getDocSequenceName
END
go

create FUNCTION mds_getDocSequenceName(@partitionID  NUMERIC) RETURNS $(MDS_VARCHAR)($(SEQ_NAME))
AS
BEGIN  
  DECLARE @strID      $(MDS_VARCHAR)(50);

  SELECT @strID = CASE 
                    WHEN @partitionID IS NULL THEN '' 
                    WHEN @partitionID < 0 THEN 'n' + CONVERT($(MDS_VARCHAR), ABS(@partitionID))
                    ELSE CONVERT($(MDS_VARCHAR), @partitionID) 
                  END;

  RETURN ( N'MDS_SEQUENCE_DOC_ID_' + @strID);
END
go


--
-- Get the lineages sequence name.  
--
-- Parameters:
--   @partitionID        - Partition Number.
-- Returns:
--   the name of sequence. 
-- NOTE: This method is duplicated in upgmds.sql. If you change
-- the implementation, please update upgmds.sql as well
IF (object_id('mds_getLineageSequenceName', 'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_getLineageSequenceName
END
go

create FUNCTION mds_getLineageSequenceName(@partitionID  NUMERIC) RETURNS $(MDS_VARCHAR)($(SEQ_NAME))
AS
BEGIN  
  DECLARE @strID      $(MDS_VARCHAR)(50);

  SELECT @strID = CASE 
                    WHEN @partitionID IS NULL THEN '' 
                    WHEN @partitionID < 0 THEN 'n' + CONVERT($(MDS_VARCHAR), ABS(@partitionID))
                    ELSE CONVERT($(MDS_VARCHAR), @partitionID) 
                  END;

  RETURN ( N'MDS_SEQUENCE_LINEAGE_ID_' + @strID);
END
go


--
-- Creates an entry in the mds_paths document.
--
-- Parameters:
--   @docID        - the document ID for the inserted path.
--   @partitionID  - the partition where the document to be created
--   @documentID   - Document ID of the document being saved.
--   @pathname     - the name of the document/package (not fully qualified)
--   @fullPath     - Fullname for the path to be created
--   @ownerID      - the ID of the owning package
--   @docType      - either 'DOCUMENT', 'TRANSLATION' or 'PACKAGE'
--   @docElemName  - Local name of the document element, null for Non-XML docs
--   @docElemNSURI - NS URI of document element, null for Non-XML docs
--   @versionNum   - Version number, applicable only for DOCUMENTs
--   @xmlversion   - xml version, which can be null for "child" documents
--   @xmlencoding  - xml encoding, which can be null for "child" documents
--   checksum      - checksum for the document content.
--   lineageID     - lineageID for the document if seeded.
--   moTypeNSURI   - Element namespace of the base document for a customization
--                   document.  Null value for a base document or a package.
--   moTypeName    - Element name of the base document for a customization
--                   document.  Null value for a base document or a package.
--   contentType   - Document content stored as: 0 - Shredded XML
--                                               1 - BLOB
--                                               2 - Unshredded XML
--
IF (object_id(N'mds_internal_insertPath', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_insertPath
END
go

create PROCEDURE mds_internal_insertPath(
    @docID                NUMERIC OUTPUT,
    @partitionID          NUMERIC,
    @documentID           NUMERIC,
    @pathname             $(MDS_VARCHAR)($(PATH_NAME)),
    @fullPath             $(MDS_VARCHAR)($(FULLNAME)),
    @ownerID              NUMERIC,
    @docType              $(MDS_VARCHAR)($(PATH_TYPE)),
    @docElemNSURI         $(MDS_VARCHAR)($(ELEM_NSURI)),
    @docElemName          $(MDS_VARCHAR)($(ELEM_NAME)),
    @versionNum           NUMERIC,
    @verComment           $(MDS_VARCHAR)($(VER_COMMENTS)),
    @xmlversion           $(MDS_VARCHAR)($(XML_VERSION)) = NULL,
    @xmlencoding          $(MDS_VARCHAR)($(XML_ENCODING)) = NULL,
    @mdsGuid              $(MDS_VARCHAR)($(GUID)) = NULL,
    @checksum             NUMERIC = NULL,
    @lineageID            NUMERIC = NULL,
    @moTypeNSURI          $(MDS_VARCHAR)($(ELEM_NSURI)) = NULL,
    @moTypeName           $(MDS_VARCHAR)($(ELEM_NAME)) = NULL,
    @contentType          NUMERIC = NULL)
AS
BEGIN
  DECLARE @contentID  NUMERIC;
  DECLARE @sqlStmt    $(MDS_VARCHAR)(256);
  DECLARE @changeType NUMERIC;
  DECLARE @seqName    $(MDS_VARCHAR)($(SEQ_NAME));
  DECLARE @lckTmOut   NUMERIC;

  SET NOCOUNT ON;

  SET @contentID = NULL;   

  IF @docType = N'DOCUMENT'
  BEGIN
    SET @lckTmOut = -2;

    EXEC @seqName = mds_getContentSequenceName @partitionID;
    EXEC mds_getNextSequence @contentID OUTPUT, @seqName;

    -- Newer versions of the document should use the same document ID
    IF ( @documentID = -1 )
    BEGIN
      SET @changeType = $(CREATE_OP);

      -- Get the next document ID in the given partition.
      EXEC @seqName = mds_getDocSequenceName @partitionID ;
      EXEC mds_getNextSequence @docID OUTPUT, @seqName;
    END
    ELSE
    BEGIN
      SET @changeType = $(UPDATE_OP);
      SET @docID = @documentID;
    END
  END
  ELSE
  BEGIN
    SELECT @lckTmOut = @@LOCK_TIMEOUT;

    -- Get the next document ID for the package in the given partition.
    EXEC @seqName = mds_getDocSequenceName @partitionID;
    EXEC mds_getNextSequence @docID OUTPUT, @seqName;      
  END

  BEGIN TRY
    -- New documents are created with high_cn set to -1, it is
    -- replaced with actual commit number corresponding to the transaction
    -- by BaseDBMSConnection.commit()

    IF ( @lckTmOut != -2 )
      SET LOCK_TIMEOUT 5000;

    INSERT INTO MDS_PATHS 
        (PATH_PARTITION_ID, PATH_NAME, PATH_DOCID, PATH_OWNER_DOCID, PATH_TYPE,
         PATH_DOC_ELEM_NSURI, PATH_DOC_ELEM_NAME,
         PATH_FULLNAME, PATH_GUID,
         PATH_LOW_CN, PATH_HIGH_CN, PATH_OPERATION, PATH_CONTENTID,
         PATH_VERSION, PATH_VER_COMMENT,
         PATH_XML_VERSION, PATH_XML_ENCODING, PATH_CONT_CHECKSUM,
         PATH_LINEAGE_ID, PATH_DOC_MOTYPE_NSURI, PATH_DOC_MOTYPE_NAME,
         PATH_CONTENT_TYPE)
      VALUES
        (@partitionID, @pathname, @docID, @ownerID, @docType,
         @docElemNSURI, @docElemName,
         @fullPath, @mdsGuid,
         $(INTXN_CN), null, @changeType, @contentID,
         @versionNum, @verComment,
         @xmlversion, @xmlencoding, @checksum, @lineageID, 
         @moTypeNSURI, @moTypeName, @contentType);

    IF ( @lckTmOut != -2 )
    BEGIN
      SELECT @sqlStmt = 
           'SET LOCK_TIMEOUT ' + CONVERT(NVARCHAR, @lckTmOut);

      EXEC(@sqlStmt);
    END

    RETURN;
  END TRY
  BEGIN CATCH
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
    DECLARE @err    INT;

    SELECT @err = @@error;

    -- Restore back the default TIMEOUT
    IF ( @lckTmOut != -2 )
    BEGIN

      SELECT @sqlStmt = 
           'SET LOCK_TIMEOUT ' + CONVERT(NVARCHAR, @lckTmOut);

      EXEC(@sqlStmt);
    END

    IF @err = $(DUP_VAL_ON_INDEX) OR 
       @err = $(DUP_VAL_ON_CONSTRAINT)
    BEGIN
      -- If this exception was caused by (3), then the following select should
      -- now return the correct docid because the first user will have
      -- finished saving the document.
      DECLARE @cnt   INT;

      SELECT @docID = PATH_DOCID
        FROM MDS_PATHS
        WHERE
            PATH_NAME = @pathname AND
            PATH_OWNER_DOCID = @ownerID AND
            PATH_TYPE = @docType AND
            PATH_HIGH_CN IS NULL AND
            PATH_PARTITION_ID = @partitionID;

      IF (@@error = 0 AND @@rowcount > 0)
      BEGIN        
        IF (@docType = N'DOCUMENT')
          RAISERROR(N'$(ERROR_DOCUMENT_NAME_CONFLICT)', 16, 1);
        ELSE
          RAISERROR(N'$(ERROR_PACKAGE_NAME_CONFLICT)', 16, 1);
        RETURN;
      END

      -- Since no data was found, we know this was caused by either (1) or
      -- or (2).  If the following query returns no rows, then this can only
      -- be explained by a corrupt sequence; otherwise, we are dealing with
      -- a name conflict.
      SELECT @cnt = count(*)
        FROM MDS_PATHS
        WHERE
          PATH_NAME = @pathname AND
          PATH_OWNER_DOCID = @ownerID AND
          PATH_HIGH_CN IS NULL AND
          PATH_PARTITION_ID = @partitionID;
      IF (@cnt = 0)
        RAISERROR(N'$(ERROR_CORRUPT_SEQUENCE)', 16, 1);
      ELSE IF (@docType = N'DOCUMENT')
        RAISERROR(N'$(ERROR_DOCUMENT_NAME_CONFLICT)', 16, 1);
      ELSE
        RAISERROR(N'$(ERROR_PACKAGE_NAME_CONFLICT)', 16, 1);        
    END
    ELSE
    BEGIN
      -- Check if NOWAIT time out
      IF @err = $(LOCK_REQUEST_TIMEOUT) 
      BEGIN
        RAISERROR(N'$(ERROR_LOCK_TIMEOUT)', 16, 1);        
        RETURN;
      END
      ELSE
      BEGIN
        $(RERAISE_MESSAGE_DECLARE)
        $(RERAISE_EXCEPTION)
      END
    END
  END CATCH
END
go


--
-- Return the index of the last occurrence of the first string in the second.
-- This function is like Oracle's INSTR with a negative third operand.
--
-- Parameters:
--   @str1      - String to be found.
--   @str2      - String to search in.
-- Returns:
--   the (one-origin) index of the last occurrence of str1 in str2, or zero
--   if str1 isn't a substring of str2.
IF (object_id('mds_internal_lastIndexOf', 'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_internal_lastIndexOf
END
go

create FUNCTION mds_internal_lastIndexOf(@str1  $(MDS_VARCHAR)(1024),
                                         @str2  $(MDS_VARCHAR)(1024))
                RETURNS INT
AS
BEGIN
  DECLARE @pos      INT;
  DECLARE @prevPos  INT;

  -- Handling special case first.
  IF NULLIF(@str1,'') IS NULL OR
       @str2 IS NULL 
      RETURN 0;

  SET @prevPos = 0;
  SET @pos = CHARINDEX(@str1, @str2);
  WHILE @pos <> 0
  BEGIN
    SET @prevPos = @pos;
    SET @pos = CHARINDEX(@str1, @str2, @prevPos + 1);
  END
  RETURN @prevPos;
END
go


  --
  -- Split a name into parent package and local names.
  -- 
  -- Parameters:
  --   fullPathName - the complete path name of the package
  --
  -- Returns:
  --   the parent package name
  --   the local name
  --

IF (object_id(N'mds_internal_splitName', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_splitName
END
go

create PROCEDURE mds_internal_splitName(
                    @parentPkgName $(MDS_VARCHAR)($(FULLNAME)) OUTPUT,
                    @pkgLocalName  $(MDS_VARCHAR)($(FULLNAME)) OUTPUT,
                    @fullPathName $(MDS_VARCHAR)($(FULLNAME)))
AS
BEGIN
  DECLARE @lastSlashPos  INT;

  IF NULLIF(@fullPathName, '') IS NULL
  BEGIN
      SET @parentPkgName = N'/';
      SET @pkgLocalName = N'';

      RETURN;
  END

  -- Search for the last slash in the name to compute the package and
  -- document name.
  EXEC @lastSlashPos = mds_internal_lastIndexOf N'/', @fullPathName;
  SET @pkgLocalName = SUBSTRING(@fullPathName, @lastSlashPos + 1,
                                LEN(@fullPathName) - @lastSlashPos);

  IF @lastSlashPos > 1
    SET @parentPkgName = SUBSTRING(@fullPathName, 1, @lastSlashPos - 1);
  ELSE
    -- For example: for /mypkg, pkg is '/' and pkgLocalName is 'mypkg'
    SET @parentPkgName = N'/';
END
go


  --
  -- Check if a package exists, returning its docID.
  -- 
  -- Parameters:
  --   partitionID  - the partition where the package is created
  --   fullPathName - the complete path name of the package
  --
  -- Returns:
  --   the ID of the package or -1 if no such package
  --

IF (object_id(N'mds_internal_checkPackage', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_checkPackage
END
go

create PROCEDURE mds_internal_checkPackage(
                                @pkgDocID     INT OUTPUT,
                                @partitionID  INT,
                                @fullPathName $(MDS_VARCHAR)($(FULLNAME)))
AS
BEGIN
  DECLARE @c             CURSOR;

  IF @fullPathName = N'/'
  BEGIN
    SET @pkgDocID = $(ROOT_DOCID);
    RETURN;
  END

  -- Does this package already exist or just added.
  -- @fullPathName and @partitionID are used by cursor c.      
  SET @c = CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
      SELECT PATH_DOCID
      FROM MDS_PATHS
      WHERE PATH_FULLNAME = @fullPathName AND
            PATH_TYPE = N'PACKAGE' AND
            PATH_PARTITION_ID = @partitionID AND
            PATH_HIGH_CN IS NULL;
    
  OPEN @c;
  FETCH NEXT FROM @c INTO @pkgDocID;
    
  IF (@@fetch_status <> 0)     -- Record missing.
    SET @pkgDocID = -1;

  -- Release the cursor resource.
  CLOSE @c;
  DEALLOCATE @c;
END
go


  --
  -- Create a package given the parent docid.
  -- 
  -- Parameters:
  --   partitionID  - the partition where the package is created
  --   fullPathName - the complete path name of the package
  --   parentDocID  - the document ID of the parent package
  --
  -- Returns:
  --   the ID of the created package
  --

IF (object_id(N'mds_internal_createPackage2', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_createPackage2
END
go

create PROCEDURE mds_internal_createPackage2(
                                @pkgDocID     INT OUTPUT,
                                @partitionID  INT,
                                @fullPathName $(MDS_VARCHAR)($(FULLNAME)),
                                @parentDocID  INT)
AS
BEGIN
  DECLARE @err           INT;
  DECLARE @rowc          INT;
  DECLARE @try           INT;
  DECLARE @parentPkgName $(MDS_VARCHAR)($(FULLNAME));
  DECLARE @newVersionNum INT;
  DECLARE @pkgLocalName  $(MDS_VARCHAR)($(FULLNAME));

  -- Declare Message for Reraise Exception
  $(RERAISE_MESSAGE_DECLARE)

  SET NOCOUNT ON;

  -- Try to create it multiple times, since the insert won't wait.
  SET @try = $(RETRY_COUNT);

  WHILE (1=1)
  BEGIN
    BEGIN TRY
      -- #(5508200) - If this is a recreate then continue the version 
      -- number of the logically deleted resource instead of 1
      SET @newVersionNum = 1;
      SELECT @newVersionNum = ISNULL(MAX(PATH_VERSION)+1, 1)
            FROM MDS_PATHS
            WHERE PATH_FULLNAME = @fullPathName AND
              PATH_PARTITION_ID = @partitionID AND
              PATH_TYPE= N'PACKAGE';
      IF @newVersionNum < 1 
      BEGIN
        SET @newVersionNum = 1;
      END
      -- split the package name
      EXEC mds_internal_splitName @parentPkgName OUTPUT,
                                  @pkgLocalName  OUTPUT,
                                  @fullPathName;
      -- try to insert it
      EXEC mds_internal_insertPath
                              @pkgDocID OUTPUT,   -- Returns document ID for the path.
                              @partitionID,
                              -1,                 -- existing docID: treat as create
                              @pkgLocalName,
                              @fullPathName,
                              @pkgDocID,
                              N'PACKAGE',
                              null,               -- Document Element NSURI
                              null,               -- Document Element Name
                              @newVersionNum,     -- Version number
                              null;               -- Version comment :  
    END TRY
    BEGIN CATCH
      -- Check if the error caused by LOCK timeout or 
      -- the path is just added and committed by others.
      IF ( ERROR_NUMBER() = 50000 AND 
              (ERROR_MESSAGE() = N'$(ERROR_LOCK_TIMEOUT)' OR 
              ERROR_MESSAGE() = N'$(ERROR_DOCUMENT_NAME_CONFLICT)' OR 
              ERROR_MESSAGE() = N'$(ERROR_PACKAGE_NAME_CONFLICT)'))  
      BEGIN
        SET @try = @try - 1;

        IF (@try > 0)
        BEGIN
          WAITFOR DELAY '$(DELAY_TIME)';

          -- see if somebody else created it
          EXEC mds_internal_checkPackage @pkgDocID OUTPUT,
                                         @partitionID,
                                         @fullPathName;
          IF @pkgDocID >= 0
          BEGIN
            RETURN; -- beaten to it: return its ID
          END
          CONTINUE; -- try again
        END

        RAISERROR(N'$(ERROR_CONFLICTING_CHANGE)', 16, 1);
        RETURN;
      END
      ELSE
      BEGIN
        $(RERAISE_EXCEPTION)
      END
    END CATCH
    BREAK; -- didn't catch, so insert worked
  END -- WHILE
END
go


--
-- Creates an entry in the mds_paths table for the MDS document.
-- The full name of the document must be specified.  Any packages
-- which do not already exist will be created as well.
--
-- Parameters:
--   docID OUTPUT - the id of the created path.
--   partitionID  - the partition where the document to be created
--   documentID   - the id of the document to be created
--   absPathName  - the complete path name of the document
--   docType      - either 'PACKAGE' or 'DOCUMENT' OR 'TRANSLATION'
--   docElemName  - Local name of the document element, null for Non-XML docs
--   docElemNSURI - NS URI of document element, null for Non-XML docs
--   versionNum   - Version number for the document
--   xmlversion   - xml version
--   xmlencoding  - xml encoding
--   mdsGuid      - GUID for the document
--   checksum     - checksum for the document content.
--   lineageID    - lineageID for the document if seeded.
--   moTypeNSURI   - Element namespace of the base document for a customization
--                   document.  Null value for a base document or a package.
--   moTypeName    - Element name of the base document for a customization
--                   document.  Null value for a base document or a package.
--   contentType  - Document content stored as: 0 - Shredded XML
--                                              1 - BLOB
--                                              2 - Unshredded XML
--
IF (object_id(N'mds_internal_createPath', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_createPath
END
go

create PROCEDURE mds_internal_createPath(
    @docID        NUMERIC OUTPUT,
    @partitionID  NUMERIC,
    @documentID   NUMERIC,
    @absPathName  $(MDS_VARCHAR)($(FULLNAME)),
    @docType      $(MDS_VARCHAR)($(PATH_TYPE)),
    @docElemNSURI $(MDS_VARCHAR)($(ELEM_NSURI)),
    @docElemName  $(MDS_VARCHAR)($(ELEM_NAME)),
    @versionNum   NUMERIC,
    @verComment   $(MDS_VARCHAR)($(VER_COMMENTS)),
    @xmlversion   $(MDS_VARCHAR)($(XML_VERSION)),
    @xmlencoding  $(MDS_VARCHAR)($(XML_ENCODING)),
    @mdsGuid      $(MDS_VARCHAR)($(GUID)) = NULL,
    @checksum     NUMERIC = NULL,
    @lineageID    NUMERIC = NULL,
    @moTypeNSURI  $(MDS_VARCHAR)($(ELEM_NSURI)) = NULL,
    @moTypeName   $(MDS_VARCHAR)($(ELEM_NAME)) = NULL,
    @contentType  NUMERIC = NULL )
AS
BEGIN

  DECLARE @ownerDocID    NUMERIC;
  DECLARE @fullPathName  $(MDS_VARCHAR)($(FULLNAME));
  DECLARE @packageName   $(MDS_VARCHAR)($(FULLNAME));
  DECLARE @docName       $(MDS_VARCHAR)($(FULLNAME));
  DECLARE @parentPkgName $(MDS_VARCHAR)($(FULLNAME));
  DECLARE @parentLocName $(MDS_VARCHAR)($(FULLNAME));
  DECLARE @lastSlashPos  SMALLINT;

  DECLARE @c             CURSOR;

  -- Declare Message for Reraise Exception
  $(RERAISE_MESSAGE_DECLARE)

  SET NOCOUNT ON;

  SET @ownerDocID  = 0;
  SET @docID       = 0;
  SET @fullPathName = @absPathName;

  -- Ensure that the pathName starts with a slash
  IF (CHARINDEX(N'/', @fullPathName) <> 1)
  BEGIN
    SET @docID = -1;
    RETURN;
  END

  -- #(3403125) Remove the trailing forward slash if any
  IF (CHARINDEX(N'/', @fullPathName, LEN(@fullPathName)) > 0)
    SET @fullPathName = SUBSTRING(@fullPathName, 1, LEN(@fullPathName) - 1);

  -- split the name into parent package name and local name
  EXEC mds_internal_splitName @packageName OUTPUT,
                              @docName OUTPUT,
                              @fullPathName;

  -- #(7831917) Work from the bottom up to the root looking for
  -- an existing package.
  SET @parentPkgName = @packageName;
  WHILE 1 = 1
  BEGIN
    EXEC mds_internal_checkPackage @ownerDocID OUTPUT,
                                   @partitionID,
                                   @parentPkgName;
    IF @ownerDocID >= 0
      BREAK; -- found an existing package

    -- split the parent name into its parent and local names.
    EXEC mds_internal_splitName @parentPkgName OUTPUT,
                                @parentLocName OUTPUT,
                                @parentPkgName;
  END -- WHILE looking for existing package

  -- Create any missing packages from child of @parentPkgName
  -- to @packageName. @ownerDocID is docid of @parentPkgName.
  WHILE 1 = 1
  BEGIN
    IF LEN(@parentPkgName) >= LEN(@packageName)
      BREAK; -- done

    -- build the next package name down
    SET @parentPkgName = SUBSTRING(@fullPathName, 1,
          CHARINDEX(N'/', @fullPathName, LEN(@parentPkgName) + 2) - 1);

    -- create the package
    EXEC mds_internal_createPackage2 @ownerDocID OUTPUT,
                                     @partitionID,
                                     @parentPkgName,
                                     @ownerDocID;
  END -- WHILE creating missing packages

  -- Now create the MDS_PATHS entry for the document
  BEGIN TRY
    --
    -- There are no more slashes, which means that all that is left
    -- is the name of document
    --
    EXEC mds_internal_insertPath @docID OUTPUT,    -- returns new id for the inserted path.
                                 @partitionID,
                                 @documentID,
                                 @docName,
                                 @fullPathName,
                                 @ownerDocID,
                                 @docType,
                                 @docElemNSURI,
                                 @docElemName,
                                 @versionNum,
                                 @verComment,
                                 @xmlversion,
                                 @xmlencoding,
                                 @mdsGuid,
                                 @checksum,
                                 @lineageID,
                                 @moTypeNSURI,
                                 @moTypeName,
                                 @contentType;
  END TRY
  BEGIN CATCH        
    $(RERAISE_EXCEPTION)
  END CATCH        
END
go

--
-- Insert the sequence into MDS_SEQUENCES table.  If the row is there,
-- update its value with new seed number.
--
-- Parameters:
--   @seqName  -  Sequence Name.
--   @seed     -  seed number.
--
-- NOTE: This method is duplicated in upgmds.sql. If you change
-- the implementation, please update upgmds.sql as well
--
IF (object_id(N'mds_createSequence', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_createSequence
END
go

create PROCEDURE mds_createSequence(@seqName       $(MDS_VARCHAR)($(SEQ_NAME)),
                                    @seed          NUMERIC)
AS
BEGIN  
  DECLARE @err     INT;
  DECLARE @rowc    INT;

  SET NOCOUNT ON;

  -- Replace possible ';' with '_' to avoid SQL injection.
  set @seqName = REPLACE(@seqName, ';', '_');

  --If the sequence table doesn't exist, create it.
  if (object_id(@seqName, N'U') IS NULL)
  BEGIN 
      DECLARE @seedStr VARCHAR(20);
   
      SELECT @seedStr = CONVERT($(MDS_VARCHAR), @seed)
    
      EXEC ('CREATE TABLE ' + @seqName +
           '(ID     NUMERIC IDENTITY(' +
           @seedStr +
           ',1) UNIQUE NOT NULL)')
  END
END
go

-- Checks if the specified doucment has been concurrently
-- updated/deleted/renamed after the transaction represented by lowCN,
-- raises ERROR_CONFLICTING_CHANGE if so.
--
-- Parameters:
--   @docID        -  PATH_DOCID of the document to be verified
--   @fullPathName -  Fully qualified MDS name of the document
--   @lowCN        -  PATH_LOW_CN beyond which the updates are to be checked
--                    This is the commit number with which the document was
--                    being saved was obtained.
--   version       -  Version of the document being saved/deleted. 
-- #(5891638) move version below lowCN
--   @partitionID  -  Parition ID in which the document exists.
IF (object_id(N'mds_doConcurrencyCheck', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_doConcurrencyCheck
END
go

create PROCEDURE mds_doConcurrencyCheck(
    @docID             NUMERIC,
    @fullPathName      $(MDS_VARCHAR)($(FULLNAME)),
    @lowCN             NUMERIC,
    @curVersion        INT,
    @partitionID       NUMERIC)
AS
BEGIN
  DECLARE @pDocID            NUMERIC;
  DECLARE @pLowCN            NUMERIC;
  DECLARE @maxVer            NUMERIC;

  SET NOCOUNT ON;

  BEGIN TRY
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
    IF ( @curVersion = -1 )
    BEGIN
      SELECT @maxVer = MAX(PATH_VERSION) FROM MDS_PATHS
        WITH(NOWAIT)                   
        WHERE PATH_DOCID = @docID AND PATH_LOW_CN = @lowCN
        AND PATH_PARTITION_ID = @partitionID;

      -- If no record found, we will consider there is a conflict, since
      -- some one may delete the row.
      IF (@@error = 0 AND @@rowcount = 0)
      BEGIN
        RAISERROR(N'$(ERROR_CONFLICTING_CHANGE)', 16, 1);
        RETURN;
      END

      SELECT @pDocID=PATH_DOCID FROM MDS_PATHS
        WITH (READCOMMITTEDLOCK, UPDLOCK, ROWLOCK, NOWAIT) 
        WHERE PATH_DOCID = @docID AND PATH_HIGH_CN IS NULL
        AND PATH_PARTITION_ID = @partitionID
        AND NOT EXISTS (
          SELECT PATH_DOCID FROM MDS_PATHS
          WHERE (PATH_DOCID = @docID OR PATH_FULLNAME =@fullPathName)
          -- Checking highCN is sufficient as it will be populated both when
          -- a new version is created (due to save/rename) or when current version
          -- is deleted. path_high_cn with value -1 are ignored since they were
          -- changes in the same transaction
          AND ( PATH_LOW_CN = @lowCN
          AND ( PATH_HIGH_CN IS NOT NULL AND PATH_HIGH_CN <> $(INTXN_CN) ))
          -- This condition on maxVer used for the workaround described above
          -- should be removed once the temporary versions are avoided
          AND (PATH_VERSION = @maxVer)
          AND PATH_PARTITION_ID = @partitionID);

      -- If no record found, we will consider there is a conflict, since
      -- some one may delete the row.
      IF (@@error = 0 AND @@rowcount = 0)
      BEGIN
        RAISERROR(N'$(ERROR_CONFLICTING_CHANGE)', 16, 1);
        RETURN;
      END
    END    
    ELSE
    BEGIN
      -- Attempting to lock the current version conditional to NULL highCN
      -- is sufficient as it will be populated both when a newee version 
      -- is created (due to save/rename) or when current version
      -- is deleted. A no data found exception indicates concurrency
      SELECT @pDocID=PATH_DOCID FROM MDS_PATHS
        WITH (READCOMMITTEDLOCK, UPDLOCK, ROWLOCK, NOWAIT) 
        WHERE PATH_DOCID = @docID AND 
            PATH_VERSION = @curVersion AND 
            PATH_PARTITION_ID = @partitionID AND 
            PATH_HIGH_CN IS NULL

      -- If no record found, we know there is a conflicting change
      IF (@@error = 0 AND @@rowcount = 0)
      BEGIN
        RAISERROR(N'$(ERROR_CONFLICTING_CHANGE)', 16, 1);
        RETURN;
      END            
    END      
  END TRY
  BEGIN CATCH

     -- In case  of Concurrency issues, exception would occur, else the function
     -- would return without any issues.Further the calling function/procedure
     -- should obtain the Lock on the Document
    IF (@@error = $(LOCK_REQUEST_TIMEOUT))
    BEGIN
      -- Raise an Exception denoting that a resource busy issue has been detected
      RAISERROR(N'$(ERROR_RESOURCE_BUSY)', 16, 1);
      RETURN;
    END
    ELSE
    BEGIN
      $(RERAISE_MESSAGE_DECLARE)
      $(RERAISE_EXCEPTION)
    END
  END CATCH
END
go

  
--
-- Locks the tip version of the document, given a valid docID.
-- If the document is already locked a "RESOURCE_BUSY" exception 
-- will be raised.
--
-- Parameters:
--   @partitionID   - the partition where the document exists
--   @docID         - ID of the document to lock
--
IF (object_id(N'mds_lockDocument', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_lockDocument
END
go

create PROCEDURE mds_lockDocument(
  @partitionID    NUMERIC,
  @docID          NUMERIC
  )
AS
BEGIN
  DECLARE @tmpdocID     NUMERIC;
  DECLARE @cont         TINYINT; 
  DECLARE @err          INT;
  DECLARE @rowc         INT;

  SET NOCOUNT ON;
  
    BEGIN TRY
      SELECT @tmpdocID = PATH_DOCID
        FROM MDS_PATHS
        WITH(READCOMMITTEDLOCK, UPDLOCK, ROWLOCK, NOWAIT)
        WHERE PATH_DOCID = @docID AND PATH_HIGH_CN IS NULL
        AND PATH_PARTITION_ID = @partitionID;

      SET @cont = 0;               
    END TRY
    BEGIN CATCH        
      IF (@@error = $(LOCK_REQUEST_TIMEOUT))
        BEGIN
          RAISERROR(N'$(ERROR_RESOURCE_BUSY)', 16, 1);
          RETURN;
        END
    END CATCH
END
go


--
-- Locks the tip version of the document, given it's name.
-- If the document is already locked a "RESOURCE_BUSY" exception 
-- will be raised.
-- If the document to be locked does not exist 'ERROR_RESOURCE_NOT_EXIST'
-- exception will be raised.
--
-- Parameters:
--   @partitionID   - the partition where the document exists
--   @fullPathName  - Fully qualified name of the document to lock
--
IF (object_id(N'mds_acquireWriteLock', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_acquireWriteLock
END
go

create PROCEDURE mds_acquireWriteLock(
  @partitionID    NUMERIC,
  @fullPathName        $(MDS_VARCHAR)($(FULLNAME)),
  @mdsGuid             $(MDS_VARCHAR)($(GUID)) = NULL
  )
AS
BEGIN
  DECLARE @tmpdocID     NUMERIC;
  DECLARE @rowc         INT;

  SET NOCOUNT ON;
  
  IF ( @mdsGuid IS NOT NULL )
    SELECT @tmpdocID = PATH_DOCID
        FROM MDS_PATHS
        WITH(READCOMMITTED)
        WHERE PATH_GUID = @mdsGuid AND PATH_HIGH_CN IS NULL
        AND PATH_PARTITION_ID = @partitionID;
  ELSE
    SELECT @tmpdocID = PATH_DOCID
        FROM MDS_PATHS
        WITH(READCOMMITTED)
        WHERE PATH_FULLNAME = @fullPathName AND PATH_HIGH_CN IS NULL
        AND PATH_PARTITION_ID = @partitionID;

  IF (@@error = 0 AND @@rowcount = 0)
  BEGIN
      RAISERROR(N'$(ERROR_RESOURCE_NOT_EXIST)', 16, 1);
      RETURN;
  END

  BEGIN TRY
    --#(6658695) Invoke lockDocument() to lock the document, otherwise
    -- we would have locks on different index keys.
    EXEC mds_lockDocument @partitionID, @tmpdocID
  END TRY
  BEGIN CATCH
    $(RERAISE_MESSAGE_DECLARE)
    $(RERAISE_EXCEPTION)
  END CATCH
END
go

--
-- Delete the document logically by marking the document version as
-- not being valid after this transaction
--
-- Parameters:
--   @partitionID  - the partition where the document to be created
--   @docID        - ID of the document to delete
--   @lowCN        - PATH_LOW_CN of the document being deleted, used for
--                  checking concurrent updates on the document
--   version      - Version of the document to be deleted. #(5891638)
--   @docName      - Name of the document, used for concurrent update in the
--                  case it was recreated
--   @force        - Specify 0 if the concurrent update checking should not be
--                  done
--
IF (object_id(N'mds_deleteDocument', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_deleteDocument
END
go

create PROCEDURE mds_deleteDocument(
    @partitionID     NUMERIC,
    @docID           NUMERIC,
    @lowCN           NUMERIC,
    @version         INT,
    @docName         $(MDS_VARCHAR)($(FULLNAME)),
    @force           INT)
AS
BEGIN

  SET NOCOUNT ON;

  BEGIN TRY
    IF (@force = 0)
      -- Check for any Concurrent operations first. If no Concrrency issues are
      -- detected then go ahead and grab the lock, create a new version of the
      -- document.
      EXEC mds_doConcurrencyCheck @docID,         -- DocID of the document.
                                  @docName,       -- Absolute Name of the document.
                                  @lowCN,         -- LowCN of the grabbed document.
                                  @version,       -- Version of doc being deleted
                                  @partitionID;   -- partitionID.
    ELSE
      -- Lock the path before updating it as deleted
      -- deleteDocument would fail with resource_busy exception if somebody
      -- is modifying it or has locked it.
      EXEC mds_lockDocument @partitionID, @docID;


    -- NOTE: Tables updated here should be kept in sync with
    -- prepareDocumentForInsert() obsoleting the previous version

    -- Logically delete the document by marking the HIGH_CN as -1
    -- This will be replaced with the correct commit number in
    -- processCommit()

    UPDATE MDS_PATHS 
      WITH(ROWLOCK)
      SET PATH_HIGH_CN=$(INTXN_CN), PATH_OPERATION=$(DELETE_OP)
      WHERE PATH_DOCID = @docID
         AND PATH_TYPE = N'DOCUMENT' AND PATH_HIGH_CN IS NULL
         AND PATH_PARTITION_ID = @partitionID;

    -- Delete the dependencies originating from this docuent
    UPDATE MDS_DEPENDENCIES SET DEP_HIGH_CN=$(INTXN_CN)
      WHERE DEP_CHILD_DOCID = @docID AND DEP_HIGH_CN IS NULL
        AND DEP_PARTITION_ID = @partitionID;
  END TRY
  BEGIN CATCH
    $(RERAISE_MESSAGE_DECLARE)
    $(RERAISE_EXCEPTION)
  END CATCH
END
go

--
-- Drop Sequence from sequence table.
--
-- Parameters:
--   @seqName     - Sequence Name
--
IF (object_id(N'mds_dropSequence', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_dropSequence
END
go

create PROCEDURE mds_dropSequence(@seqName  $(MDS_VARCHAR)($(SEQ_NAME)))
AS
BEGIN
  SET NOCOUNT ON;

  IF object_id(@seqName, N'U') IS NOT NULL
  BEGIN
      EXEC ('DROP TABLE ' + @seqName);
  END
END
go


--
-- Drops the Document and Content ID sequences for the given
-- partitionID
--
-- Parameters:
--   @partitionID  -  Partition ID.
--
IF (object_id(N'mds_dropSequences', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_dropSequences
END
go

create PROCEDURE mds_dropSequences(@partitionID   NUMERIC)
AS
BEGIN
  DECLARE @seqName $(MDS_VARCHAR)($(SEQ_NAME));

  SET NOCOUNT ON;

  EXEC @seqName = mds_getDocSequenceName @partitionID;
  EXEC mds_dropSequence @seqName;

  EXEC @seqName = mds_getContentSequenceName @partitionID;
  EXEC mds_dropSequence @seqName;
END
go


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
--   @partitionID - Partition Id.
IF (object_id(N'mds_internal_deletePartition', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_deletePartition
END
go

create PROCEDURE mds_internal_deletePartition(@partitionID     NUMERIC)
AS
BEGIN
  DECLARE @nameSeq         $(MDS_VARCHAR)($(SEQ_NAME));

  SET NOCOUNT ON;

  DELETE MDS_PARTITIONS WITH(ROWLOCK) where PARTITION_ID = @partitionID;
  DELETE MDS_PATHS WITH(ROWLOCK) where PATH_PARTITION_ID = @partitionID;
  DELETE MDS_DEPENDENCIES WITH(ROWLOCK) where DEP_PARTITION_ID = @partitionID;
  DELETE MDS_STREAMED_DOCS WITH(ROWLOCK) where SD_PARTITION_ID = @partitionID;

  DELETE MDS_TRANSACTIONS WITH(ROWLOCK) where TXN_PARTITION_ID = @partitionID;
  DELETE MDS_TXN_LOCKS WITH(ROWLOCK) where LOCK_PARTITION_ID = @partitionID;
  DELETE MDS_SANDBOXES WITH(ROWLOCK) where SB_PARTITION_ID = @partitionID;
  DELETE MDS_LABELS WITH(ROWLOCK) where LABEL_PARTITION_ID = @partitionID;  
  DELETE MDS_DEPL_LINEAGES WITH(ROWLOCK) where DL_PARTITION_ID = @partitionID;

  EXEC @nameSeq = mds_getDocSequenceName @partitionID;
  EXEC mds_dropSequence @nameSeq;

  EXEC @nameSeq = mds_getContentSequenceName @partitionID ;
  EXEC mds_dropSequence @nameSeq;
  
  EXEC @nameSeq = mds_getLineageSequenceName @partitionID ;
  EXEC mds_dropSequence @nameSeq;
END
go


--
-- Delete the pacakge.
--
-- Parameters:
--   @result       - -1 if the package was not deleted because it contained 
--                  documents or sub packages, 0 if the package is 
--                  successfully deleted.
--   @partitionID  - the partition where the package exists.
--   @pathID  - ID of the package to delete
--
IF (object_id(N'mds_deletePackage', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_deletePackage
END
go

create PROCEDURE mds_deletePackage(
    @result          NUMERIC OUTPUT,
    @partitionID     NUMERIC,
    @pathID          NUMERIC)
AS
BEGIN
  DECLARE @childCount NUMERIC;

  SET NOCOUNT ON;

  SET @result = 0;

  -- Check if the package is empty, otherwise it should not be deleted
  SELECT @childCount=COUNT(*) FROM MDS_PATHS
    WITH (READUNCOMMITTED)
    WHERE PATH_OWNER_DOCID = @pathID AND PATH_HIGH_CN IS NULL
      AND PATH_PARTITION_ID = @partitionID;

  IF ( @childCount = 0 )
  BEGIN

    UPDATE MDS_PATHS WITH(ROWLOCK)
       SET PATH_HIGH_CN=$(INTXN_CN), PATH_OPERATION=$(DELETE_OP)
       WHERE PATH_DOCID = @pathID
        AND PATH_TYPE = N'PACKAGE' AND PATH_HIGH_CN IS NULL
         AND PATH_PARTITION_ID = @partitionID ;
  END
  ELSE
    SET @result = -1;
  RETURN;
END
go


--
-- Retrieves the document id for the specified fully qualified path name.
-- The pathname must begin with a '/' and should look something like:
--   /mypkg/mysubpkg/mydocument
--
-- Parameters:
--   @partitionID   - the partition where the document exists
--   @fullPathName  - the fully qualified name of the document
--   @pathType      - the type of the document, either 'DOCUMENT' or 'PACKAGE'
--                   if no type is specified, and there happens to be a path
--                   of both 'DOCUMENT' and 'PACKAGE' (which is unlikely),
--                   then the id of the DOCUMENT will be returned
--
-- Returns:
--   Returns the ID of the path or -1 if no such path exists
--
IF (object_id(N'mds_getDocumentID', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_getDocumentID
END
go

create FUNCTION mds_getDocumentID(
    @partitionID  NUMERIC,
    @fullPathName $(MDS_VARCHAR)($(FULLNAME)),
    @pathType     $(MDS_VARCHAR)($(PATH_TYPE)) = NULL) RETURNS NUMERIC
AS
BEGIN
  DECLARE @fullPath    $(MDS_VARCHAR)($(FULLNAME));
  DECLARE @docID       NUMERIC;

  SET @fullPath = @fullPathName;
  SET @docID = -1;

  -- #(3234805) If the document does not start with a forward slash,
  -- then it's an invalid document name
  IF (CHARINDEX(N'/', @fullPathName) <> 1)
  BEGIN
    return (@docID)
  END

  IF ((@fullPathName = N'/') AND ((@pathType IS NULL)
        OR (@pathType = N'PACKAGE'))) 
  BEGIN
    SET @docID = 0
    RETURN (@docID)
  END

  -- #(3403125) Remove the trailing forward slash
  IF (CHARINDEX(N'/', @fullPath, LEN(@fullPath)) > 0)
  BEGIN
    SET @fullPath = SUBSTRING(@fullPath, 1, LEN(@fullPath) - 1)
  END

  IF (@pathType IS NULL )
  BEGIN 
    SELECT @docID = PATH_DOCID
      FROM MDS_PATHS
      WHERE
        PATH_FULLNAME = @fullPath AND PATH_PARTITION_ID = @partitionID
        AND PATH_HIGH_CN IS NULL   
  END
  ELSE
  BEGIN
    SELECT @docID = PATH_DOCID 
      FROM MDS_PATHS
      WHERE
      PATH_FULLNAME = @fullPath AND PATH_TYPE = @pathType
      AND PATH_HIGH_CN IS NULL AND PATH_PARTITION_ID = @partitionID
  END
    
  -- @docID is -1 if no record found.
  RETURN(@docID)
END
go


--
-- Retrieves the document id for the specified fully qualified path name
-- and GUID. The pathname must begin with a '/' and should look something like
--   /mypkg/mysubpkg/mydocument
--
-- Parameters:
--   @partitionID   - the partition where the document exists
--   @fullPathName  - the fully qualified name of the document
--   @mdsGuid	     - the GUID of the document
--   @pathType      - the type of the document, either 'DOCUMENT' or 'PACKAGE'
--                   if no type is specified, and there happens to be a path
--                   of both 'DOCUMENT' and 'PACKAGE' (which is unlikely),
--                   then the id of the DOCUMENT will be returned
--
-- Returns:
--   Returns the ID of the path or -1 if no such path exists
--
IF (object_id(N'mds_getDocumentIDByGUID', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_getDocumentIDByGUID
END
go
  
create FUNCTION mds_getDocumentIDByGUID(
    @partitionID      NUMERIC,
    @fullPathName     $(MDS_VARCHAR)($(FULLNAME)),
    @mdsGuid          $(MDS_VARCHAR)($(GUID)),
    @pathType         $(MDS_VARCHAR)($(PATH_TYPE))) 
RETURNS NUMERIC
AS
BEGIN
  DECLARE @fullPath   $(MDS_VARCHAR)(512);
  DECLARE @docID      NUMERIC;
  DECLARE @hasPath    TINYINT;
  DECLARE @hasType    TINYINT;

  SET @fullPath  = @fullPathName;
  SET @docID     = -1;
  SET @hasPath   = 0;
  SET @hasType   = 0;

  -- fullpath and/or mdsGuid must be non-null
  IF @mdsGuid IS NULL    
    RETURN -1;

  -- #(3234805) If the document does not start with a forward slash,
  -- then it's an invalid document name
  IF (@fullPathName is NOT NULL AND CHARINDEX(N'/', @fullPathName) <> 1)
    RETURN (-1);

  IF ((@fullPathName IS NOT NULL AND @fullPathName = N'/')
       AND ((@pathType IS NULL) OR (@pathType = N'PACKAGE')))
    RETURN (0);

  -- #(3403125) Remove the trailing forward slash
  IF (@fullPath IS NOT NULL AND CHARINDEX(N'/', @fullPath, LEN(@fullPath)) > 0)
    SET @fullPath = SUBSTRING(@fullPath, 1, LEN(@fullPath) - 1);

  IF (@fullPath IS NOT NULL AND LEN(@fullPath) > 0)
    SET @hasPath = 1;
  IF(@pathType IS NOT NULL AND LEN(@pathType) > 0)
    SET @hasType = 1;

  IF (@hasPath = 1 AND @hasType = 1)
  BEGIN
    SELECT @docID=ISNULL(PATH_DOCID,-1) FROM MDS_PATHS WHERE PATH_GUID = @mdsGuid
                 AND PATH_PARTITION_ID = @partitionID AND PATH_HIGH_CN IS NULL
                 AND PATH_FULLNAME = @fullPath AND PATH_TYPE = @pathType;
  END
  ELSE IF (@hasPath = 1 AND @hasType = 0)
  BEGIN
    SELECT @docID=ISNULL(PATH_DOCID,-1) FROM MDS_PATHS WHERE PATH_GUID = @mdsGuid
                  AND PATH_PARTITION_ID = @partitionID AND PATH_HIGH_CN IS NULL
                  AND PATH_FULLNAME = @fullPath;
  END
  ELSE IF (@hasPath = 0 AND @hasType = 1)
  BEGIN
    SELECT @docID=ISNULL(PATH_DOCID,-1) FROM MDS_PATHS WHERE PATH_GUID = @mdsGuid
                  AND PATH_PARTITION_ID = @partitionID AND PATH_HIGH_CN IS NULL
                  AND PATH_TYPE = @pathType;    
  END
  ELSE
  BEGIN
    SELECT @docID=ISNULL(PATH_DOCID,-1) FROM MDS_PATHS WHERE PATH_GUID = @mdsGuid
                  AND PATH_PARTITION_ID = @partitionID AND PATH_HIGH_CN IS NULL;
  END
    
  RETURN (@docID)
END
go


--
-- Retrieves the document id for the specified attributes.  This is
-- typically used when attempting to find the id of a path which is
-- owned by a package document.
--
-- Note that this will return the docID which matches the specified
-- name, ownerID and docType.
--
-- Parameters:
--   @partitionID   - the partition where the document exists
--   @name          - the name of the document (not fully qualified)
--   @ownerID       - the ID of the owning package
--   @docType       - either 'DOCUMENT' or 'PACKAGE'
--
-- Returns:
--   Returns the ID of the path or -1 if no such path exists
--
IF (object_id(N'mds_internal_getDocumentIDByOwnerID', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_internal_getDocumentIDByOwnerID
END
go

CREATE FUNCTION mds_internal_getDocumentIDByOwnerID(
    @partitionID NUMERIC,
    @name        $(MDS_VARCHAR)($(PATH_NAME)),
    @ownerID     NUMERIC,
    @docType     $(MDS_VARCHAR)($(PATH_TYPE))) RETURNS NUMERIC
AS
BEGIN
  DECLARE @docid     NUMERIC;

  SET @docid = -1;

  -- Find the docid for the specified attributes
  SELECT  @docid=PATH_DOCID
    FROM MDS_PATHS
    WHERE
      PATH_NAME = @name AND
      PATH_OWNER_DOCID = @ownerID AND
      PATH_TYPE = @docType AND
      PATH_HIGH_CN IS NULL AND
      PATH_PARTITION_ID = @partitionID;

  RETURN (@docid);
END
go


--
-- For each document name, retrieve the corresponding document ID.
-- The document ID for docs[i] is in docIDs[i].  If no documentID
-- exists for a docs[i], then docIDs[i] = -1.
--
IF (object_id(N'mds_getDocumentIDs', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_getDocumentIDs
END
go

create PROCEDURE mds_getDocumentIDs(@partitionID     NUMERIC,
                                    @docs            $(MDS_VARCHAR)(4000),
                                    @docIDs          $(MDS_VARCHAR)(4000) OUTPUT)
AS
BEGIN
  DECLARE @startPOS     INT;
  DECLARE @sepPOS       INT;
  DECLARE @len          INT;
  DECLARE @docID        NUMERIC;
  DECLARE @fullName     $(MDS_VARCHAR)($(FULLNAME));

  SET NOCOUNT ON;

  IF @docs IS NULL OR
        LEN(@docs) = 0 
  BEGIN
      SET @docIDs = N'';
      RETURN;
  END

  SET @startPOS = 1;
  SET @sepPOS   = -1;  -- Initialize with non 0 value.
  SET @docIDs   = N'';
    
  WHILE(@sepPOS <> 0)
  BEGIN
    SET @sepPOS = CHARINDEX(N',', @docs, @startPOS);
    
    IF (@sepPOS = 0)
      SET @len = LEN(@docs) - @startPOS + 1;
    ELSE
      SET @len = @sepPOS - @startPOS;

    SELECT @fullName = SUBSTRING(@docs, @startPOS, @len);

    EXEC @docID = mds_getDocumentID @partitionID, @fullName, N'DOCUMENT';

    -- Add the ID to @docIDs.
    IF (@startPOS > 1)
      SET @docIDs = @docIDs + N',';

    SET @docIDs = @docIDs + @docID;
      
    -- Shift the position to the right of @sepPOS.
    IF (@sepPOS <> 0)
      SET @startPOS = @sepPOS + 1;
  END
END
go


--
-- Given the document id, find the fully qualified document name
--
-- Parameters:
--   @partitionID   - the partition where the document exists
--   @docID         - the ID of the document
--
-- Returns:
--   the fully qualified document name
--
IF (object_id(N'mds_getDocumentName', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_getDocumentName
END
go

create FUNCTION mds_getDocumentName(
    @partitionID  NUMERIC,
    @docid        NUMERIC) RETURNS $(MDS_VARCHAR)($(FULLNAME))
AS
BEGIN
  DECLARE @name   $(MDS_VARCHAR)($(FULLNAME));

  SET @name = N'';

  SELECT @name=PATH_FULLNAME FROM MDS_PATHS WHERE
      PATH_DOCID = @docid AND PATH_PARTITION_ID = @partitionID
      AND PATH_HIGH_CN IS NULL;
  RETURN (@name);
END
go


--
-- Recreates Document, Content and Lineage ID sequences with the minimum
-- documentID, contentID and lineageID set to the values provided as input
-- parameters.
--
-- Parameters:
--   @partitionID  -  Partition ID.
--   @minDocId     -  Minimum Document ID
--   @minContentId -  Minimum Content ID
--   @minLineageId -  Minimum Lineage ID
--
IF (object_id(N'mds_recreateSequences', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_recreateSequences
END
go

create PROCEDURE mds_recreateSequences(@partitionID    NUMERIC,
                                       @minDocId       NUMERIC,
                                       @minContentId   NUMERIC,
                                       @minLineageId   NUMERIC = NULL)
AS
BEGIN
  DECLARE @seqName $(MDS_VARCHAR)($(SEQ_NAME));

  SET NOCOUNT ON;

  EXEC @seqName = mds_getDocSequenceName @partitionID;
  EXEC mds_dropSequence @seqName;
  EXEC mds_createSequence @seqName, @minDocId;

  EXEC @seqName = mds_getContentSequenceName @partitionID;
  EXEC mds_dropSequence @seqName;
  EXEC mds_createSequence @seqName, @minContentId;
  
  IF (@minLineageId IS NOT NULL)
  BEGIN
    EXEC @seqName = mds_getLineageSequenceName @partitionID;
    EXEC mds_dropSequence @seqName;
    EXEC mds_createSequence @seqName, @minLineageId;
  END
END
go

--
-- Gives the partitionID for the given partitionName. If the entry not found,
-- it will create new entry in MDS_PARTIITONS table and returns the new
-- partitionID.
--
-- Parameters:
--   @partitionID(OUT)       - Returns the ID for the given partition.
--   @partitionExists(OUT)   - OUT param, value to indicate if the partition already
--                             exists.                                
--   @partitionName          - Name of the Repository partition.
--
IF (object_id(N'mds_getOrCreatePartitionID', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_getOrCreatePartitionID
END
go

create PROCEDURE  mds_getOrCreatePartitionID(
                    @partitionID        NUMERIC OUTPUT,
                    @partitionExists    INT OUTPUT,
                    @partitionName      $(MDS_VARCHAR)($(PARTITION_NAME)))
AS
BEGIN
  DECLARE @appLockStat       INT;

  SET NOCOUNT ON;

  -- Initialize with a non existing value.
  SET @appLockStat = -99999;  

  SELECT @partitionID = PARTITION_ID
    FROM MDS_PARTITIONS
    WHERE PARTITION_NAME = @partitionName;

  -- check whether we have record returned.
  IF (@@error = 0 AND @@rowcount > 0)
  BEGIN
     
    SET @partitionExists = $(INT_TRUE);

    RETURN;
  END

  -- Try to apply a application lock on the partitoin name, since we
  -- don't want multiple txn create the same partition.

  EXEC @appLockStat = sp_getapplock @Resource = @partitionName,
                                    @LockMode = 'Exclusive';

  -- Try to query again, since some one may created it.
  SELECT @partitionID = PARTITION_ID
    FROM MDS_PARTITIONS
    WHERE PARTITION_NAME = @partitionName;

  -- check whether we have record returned.
  IF (@@error = 0 AND @@rowcount > 0)
  BEGIN
    -- Unlock the lock
    IF ( @appLockStat >= 0 ) 
    BEGIN
      EXEC sp_releaseapplock @Resource = @partitionName;

      SET @appLockStat = -99999;  
    END

    SET @partitionExists = $(INT_TRUE);

    RETURN;
  END

  -- Now create the entry in the partition-table 
  BEGIN TRY
    -- The partition record doesn't exist, create the partition.
    EXEC mds_getNextSequence @partitionID OUTPUT, N'MDS_SEQUENCE_PARTITION_ID';    

    EXEC mds_recreateSequences @partitionID, 1, 1, 1;

    -- Now create the entry in the partition-table 
    INSERT INTO MDS_PARTITIONS(PARTITION_ID, PARTITION_NAME, 
                               PARTITION_LAST_PURGE_TIME)
        VALUES (@partitionID, @partitionName, getUTCDate());
    SET @partitionExists = $(INT_FALSE);
  END TRY
  BEGIN CATCH
    DECLARE @err    INT;
    SELECT  @err = @@error;
    IF @err = $(DUP_VAL_ON_INDEX) OR 
       @err = $(DUP_VAL_ON_CONSTRAINT)
    BEGIN
      -- #(7442627) Partition exists already (possibly a record 
      -- is added manually or from another function from another txn.).  This
      -- situation will unlikely happen if all partition records are added through
      -- this function with application lock used.  Delete the sequences
      -- created and return the existing partition's ID
      EXEC  mds_dropSequences @partitionID;
      
      SELECT @partitionID = PARTITION_ID
          FROM MDS_PARTITIONS
          WHERE PARTITION_NAME = @partitionName;
      SET @partitionExists = $(INT_TRUE); 

      -- Even though the insert failed and the row can not be inserted
      -- by this txn, the index keys can still be locked by this txn,
      -- we will do a commit here to release the txn.
      BEGIN TRY
        COMMIT;
  
        -- If it is the outmost level commit, we will don't need to
        -- release app lock any more.
        IF ( @@TRANCOUNT = 0 )
          SET @appLockStat = -99999;  
      END TRY
      BEGIN CATCH
        -- Ignore any error in commit.
      END CATCH
    END
    ELSE
    BEGIN
      -- Unlock the lock
      IF ( @appLockStat >= 0 ) 
      BEGIN
        EXEC sp_releaseapplock @Resource = @partitionName;

        SET @appLockStat = -99999;  
      END

      $(RERAISE_MESSAGE_DECLARE)
      $(RERAISE_EXCEPTION)     
    END    
  END CATCH

  -- Unlock the lock
  IF ( @appLockStat >= 0 ) 
    EXEC sp_releaseapplock @Resource = @partitionName;
 
END
go
  

--
-- Performs all steps that are necessary before a top-levle document is
-- saved/updated which includes:
-- (1) If the document already exists, updates the "who" columns in
--     MDS_PATHS and deletes the contents of the document
-- (2) If the document does not exist yet, creates a new entry in the
--     MDS_PATHS table
--
-- Parameters:
--   @newDocID     - the ID of the document or -1 if an error occurred
--   @fullPathName - fully qualified name of the document/package file
--   @pathType     - 'DOCUMENT' for single document or 'PACKAGE' for package
--   @docElemName  - Local name of the document element, null for Non-XML docs
--   @docElemNSURI - NS URI of document element, null for Non-XML docs
--   @xmlversion   - xml version
--   @xmlencoding  - xml encoding
--   @mdsGuid      - the GUID of the document
--   @lowCN        - Low Cn value for the document.
--   @documentID   - The document ID.
--   @force        - Force operation or not ?
--   checksum      - checksum for the document content.
--   lineageID     - lineageID for the document if seeded.
--   moTypeNSURI   - Element namespace of the base document for a customization
--                   document.  Null value for a base document or a package.
--   moTypeName    - Element name of the base document for a customization
--                   document.  Null value for a base document or a package.
--   contentType   - Document content stored as: 0 - Shredded XML
--                                               1 - BLOB
--                                               2 - Unshredded XML
--   #(5891638) Removed curVersion param.
--
IF (object_id(N'mds_prepareDocumentForInsert', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_prepareDocumentForInsert
END
go

create PROCEDURE mds_prepareDocumentForInsert(
    @newDocID            NUMERIC OUTPUT,
    @docVersion          NUMERIC OUTPUT,
    @contID              NUMERIC OUTPUT,
    @partitionID         NUMERIC,
    @fullPathName        $(MDS_VARCHAR)($(FULLNAME)),
    @pathType            $(MDS_VARCHAR)($(PATH_TYPE)),
    @docElemNSURI        $(MDS_VARCHAR)($(ELEM_NSURI)),
    @docElemName         $(MDS_VARCHAR)($(ELEM_NAME)),
    @verComment          $(MDS_VARCHAR)($(VER_COMMENTS)),
    @xmlversion          $(MDS_VARCHAR)($(XML_VERSION)),
    @xmlencoding         $(MDS_VARCHAR)($(XML_ENCODING)),
    @mdsGuid             $(MDS_VARCHAR)($(GUID)),
    @lowCN               NUMERIC,
    @documentID          NUMERIC,
    @force               INT,
    @checksum            NUMERIC = NULL,
    @lineageID           NUMERIC = NULL,
    @moTypeNSURI         $(MDS_VARCHAR)($(ELEM_NSURI)) = NULL,
    @moTypeName          $(MDS_VARCHAR)($(ELEM_NAME)) = NULL,
    @contentType         NUMERIC = NULL)
AS
BEGIN
  DECLARE @versionNum          NUMERIC;
  DECLARE @prevVerLowCN        NUMERIC;
  DECLARE @cnt                 NUMERIC;      
  DECLARE @namePattern		   $(MDS_VARCHAR)($(FULLNAME));

  SET NOCOUNT ON;

  BEGIN TRY
    IF (@documentID = -1)
    BEGIN
      -- Check if the document by this GUID already exists. Note: Document name
      -- check happens during createPath() leveraging a unique index
      IF (@mdsGuid IS NOT NULL)
      BEGIN
	  	IF ( CHARINDEX('/mdssys/sandbox/', @fullPathName ) > 0 )
		BEGIN
			SET @namePattern = (SUBSTRING(@fullPathName,0,
								CHARINDEX('/', @fullPathName, LEN('/mdssys/sandbox/') + 1)) + '%');
			SELECT  @cnt = COUNT(*)  FROM MDS_PATHS
			  WHERE PATH_GUID = @mdsGuid
				AND PATH_HIGH_CN IS NULL
				AND PATH_PARTITION_ID = @partitionID AND PATH_TYPE = @pathType
				AND PATH_FULLNAME LIKE @namePattern;
		END
		ELSE
		BEGIN
			SET @namePattern = '/mdssys/sandbox/%';
			SELECT  @cnt = COUNT(*)  FROM MDS_PATHS
			  WHERE PATH_GUID = @mdsGuid
				AND PATH_HIGH_CN IS NULL
				AND PATH_PARTITION_ID = @partitionID AND PATH_TYPE = @pathType
				AND PATH_FULLNAME NOT LIKE @namePattern;
		END
        IF ( @cnt <> 0 )
          RAISERROR(N'$(ERROR_GUID_CONFLICT)', 16, 1);
      END

      SET @versionNum = 1;
      -- #(5508200) - Ensure a document has unique version number after recreate
      -- Check if an older version already exists, get its version number.
        -- We want the creation to fail(leveraging the unique index) if the 
        -- document already exists hence get the version only deleted documents
        -- (i.e, having path_high_cn as non-null)
        IF ( @mdsGuid IS NOT NULL )
			IF ( CHARINDEX('/mdssys/sandbox/', @fullPathName) > 0 )
			BEGIN
				SET @namePattern = (SUBSTRING(@fullPathName,0,
								CHARINDEX('/', @fullPathName, LEN('/mdssys/sandbox/') + 1)) + '%');
				SELECT @versionNum = ISNULL(MAX(PATH_VERSION)+1, @versionNum)
				FROM MDS_PATHS
				WHERE PATH_GUID = @mdsGuid AND PATH_HIGH_CN IS NOT NULL
				  AND PATH_PARTITION_ID = @partitionID AND 
				  PATH_TYPE = @pathType
				  AND PATH_FULLNAME LIKE @namePattern;
			END
			ELSE
			BEGIN
				SET @namePattern = '/mdssys/sandbox/%';
				SELECT @versionNum = ISNULL(MAX(PATH_VERSION)+1, @versionNum)
				FROM MDS_PATHS
				WHERE PATH_GUID = @mdsGuid AND PATH_HIGH_CN IS NOT NULL
				  AND PATH_PARTITION_ID = @partitionID AND 
				  PATH_TYPE = @pathType
				  AND PATH_FULLNAME NOT LIKE @namePattern;
			END	
      ELSE
        SELECT @versionNum = ISNULL(MAX(PATH_VERSION)+1, @versionNum)
        FROM MDS_PATHS
        WHERE PATH_FULLNAME = @fullPathName AND PATH_HIGH_CN IS NOT NULL
              AND PATH_PARTITION_ID = @partitionID AND PATH_TYPE = @pathType;

      -- #(6446544) deleteAllVersions() would leave behind the tip after 
      -- changing it's path_version to -ve of path_low_cn. If we find this as 
      -- the existing version, we should ignore it and create this version 
      -- with version=1
      IF ( 1 > @versionNum )
          SET @versionNum = 1;


      -- Document does not exist yet, so create it now
      EXEC mds_internal_createPath @newDocID OUTPUT,
                                   @partitionID,
                                   @documentID,
                                   @fullPathName,
                                   @pathType,
                                   @docElemNSURI,
                                   @docElemName,
                                   @versionNum,
                                   @verComment,
                                   @xmlversion,
                                   @xmlencoding,
                                   @mdsGuid,
                                   @checksum,
                                   @lineageID,
                                   @moTypeNSURI,
                                   @moTypeName,
                                   @contentType;
    END
    ELSE
    BEGIN
      IF (@force = 0)
        -- Check for any Concurrent operations first. If no Concrrency issues
        -- are detected then go ahead and grab the lock, create a new version
        -- of the document. If a concurrency issue is detected then an
        -- Exception will be raised in doConcurrencyCheck.
        EXEC mds_doConcurrencyCheck @documentID,    -- DocID of the document.
                                    @fullPathName,  -- Full Path of the document.
                                    @lowCN,         -- LowCN of the grabbed document
                                    @docVersion,  -- Version of the doc being saved
                                    @partitionID;   -- partitionID
      ELSE
        -- Try to obtain lock the current tip version, if somebody is modifying
        -- it or locked it, lockDocument would fail and the newer version should
        -- not be created
        EXEC mds_lockDocument @partitionID, @documentID;

      -- Need to obtain the version through query when force is TRUE since
      -- other versions may have got created after the current version
      IF ( @force <> 0 )
        -- Note that this query would need to be modified when bug#(5862448)
        -- is fixed because the previous version would have high_cn set to 
        -- -1 already when a document is being saved for the second time
        -- in the transaction. A solution is to pass the current version 
        -- number which is already available to the mid-tier. 
        SELECT @versionNum = PATH_VERSION+1
        FROM MDS_PATHS
        WHERE PATH_DOCID = @documentID 
              AND PATH_HIGH_CN IS NULL
              AND PATH_PARTITION_ID = @partitionID;
      ELSE
        -- Since the concurrency check has passed, there can't be
        -- any other changes after the current version, so compute the
        -- new version number as the next to current version.
        SET @versionNum = @docVersion + 1;

              
      EXEC mds_internal_createPath @newDocID OUTPUT,
                                   @partitionID,
                                   @documentID,  
                                   @fullPathName,
                                   @pathType,
                                   @docElemNSURI,
                                   @docElemName,
                                   @versionNum,
                                   @verComment,
                                   @xmlversion,
                                   @xmlencoding,
                                   @mdsGuid,
                                   @checksum,
                                   @lineageID,
                                   @moTypeNSURI,
                                   @moTypeName,
                                   @contentType;
  
      -- Set the high_cn for the previous version to -1, it would be replaced
      -- by the actual commit number for the transaction by
      -- BaseDBMSConnection.commit()

      -- NOTE: List of tables updated done here should be kept in sync with
      -- those in deleteDocument()

      UPDATE MDS_PATHS WITH(ROWLOCK)
        SET PATH_HIGH_CN = $(INTXN_CN) 
        WHERE PATH_DOCID = @newDocID AND PATH_VERSION=(@versionNum-1)
        AND PATH_PARTITION_ID = @partitionID;

      -- When multiple changes are done in a transaction, the depdnecies
      -- for all versions will have the same low_cn. 
      --
      -- We delete all dependencies that are available instead of restricting
      -- to delete dependencies with dep_low_cn=<path_low_cn of prev version>
      -- This is because when a document is renamed the path_low_cn for the 
      -- renamed document changes where as the dependencies are retained
      -- If this renamed document is not updated, we can not find the 
      -- dependencies matching the low_cn of the renamed document version
      UPDATE MDS_DEPENDENCIES WITH(ROWLOCK)
        SET DEP_HIGH_CN=$(INTXN_CN)
        WHERE DEP_CHILD_DOCID = @newDocID
        AND DEP_HIGH_CN IS NULL
        AND DEP_PARTITION_ID = @partitionID;
    END

    -- Set the out variables (version and contentID) so that
    -- the content can be populated from the java code
    SELECT @contID=PATH_CONTENTID from MDS_PATHS
      WHERE PATH_DOCID = @newDocID AND PATH_VERSION=@versionNum
      AND PATH_PARTITION_ID = @partitionID;

    SET @docVersion = @versionNum;
  END TRY
  BEGIN CATCH
    $(RERAISE_MESSAGE_DECLARE)
    $(RERAISE_EXCEPTION)
  END CATCH

  RETURN
END
go


-- Computes the document id for the specified fully qualified path name.
-- without using the PATH_FULLNAME column
--
-- NOTE: This logic is preserved in case we need to support storing the
-- PATH_FULLNAME as an optional configuration.
--
-- Parameters:
--   @partitionID   - the partition where the document exists
--   @fullPathName  - the fully qualified name of the document
--   @pathType      - the type of the document, either 'DOCUMENT' or 'PACKAGE'
--                   if no type is specified, and there happens to be a path
--                   of both 'DOCUMENT' and 'PACKAGE' (which is unlikely),
--                   then the id of the DOCUMENT will be returned
--
-- Returns:
--   Returns the ID of the path or -1 if no such path exists
--
IF (object_id(N'mds_internal_computeDocumentID', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_internal_computeDocumentID
END
go

create FUNCTION mds_internal_computeDocumentID(
    @partitionID    NUMERIC,
    @fullPathName   $(MDS_VARCHAR)($(FULLNAME)),
    @pathType       $(MDS_VARCHAR)($(PATH_TYPE)) = NULL) RETURNS NUMERIC
AS
BEGIN
  DECLARE @fullPath $(MDS_VARCHAR)($(FULLNAME));
  DECLARE @pName    $(MDS_VARCHAR)($(PATH_NAME));
  DECLARE @pType    $(MDS_VARCHAR)($(PATH_TYPE));
  DECLARE @ownerID  NUMERIC; 
  DECLARE @docID    NUMERIC;
  DECLARE @endIdx   INT;
  DECLARE @finished TINYINT;

  SET @ownerID  = 0;
  SET @docID    = -1;
  SET @finished = 0;

  -- #(3234805) If the document does not start with a forward slash,
  -- then it's an invalid document name
  IF (CHARINDEX(N'/', @fullPathName) <> 1)
    RETURN (-1);      

  IF ((@fullPathName = N'/') AND ((@pathType IS NULL)
      OR (@pathType = N'PACKAGE')))
    RETURN (0);     

  -- remove the first forward slash
  SET @endIdx = CHARINDEX(N'/', @fullPathName);
  SET @fullPath = SUBSTRING(@fullPathName, @endIdx + 1, LEN(@fullPathName) - @endIdx);

  -- #(3403125) Remove the trailing forward slash
  IF (CHARINDEX(N'/', @fullPath, LEN(@fullPath)) > 0)
    SET @fullPath = SUBSTRING(@fullPath, 1, LEN(@fullPath) - 1);      

  WHILE (1=1)
  BEGIN
    -- Retrieve the first portion of the path name. For example, if the
    -- fullPath is 'oracle/apps/AK/mydocument, then pName will
    -- be 'oracle'. We are not assuming that the full path begins with
    -- '/oracle/apps'.
    SET @endIdx = CHARINDEX(N'/', @fullPath);
    IF @endIdx = 0
    BEGIN
      SET @endIdx   = LEN(@fullPath);
      SET @pName    = SUBSTRING(@fullPath, 1, @endIdx);
       SET @finished = 1;
    END
    ELSE
    BEGIN
      SET @pName     = SUBSTRING(@fullPath, 1, @endIdx - 1);
      SET @fullPath  = SUBSTRING(@fullPath, @endIdx + 1, LEN(@fullPath)-@endIdx);
    END

    SELECT @docID=PATH_DOCID, @pType=PATH_TYPE
      FROM MDS_PATHS
      WHERE PATH_NAME = @pName AND PATH_OWNER_DOCID = @ownerID
        AND PATH_PARTITION_ID = @partitionID AND PATH_HIGH_CN IS NULL;

    -- If no record found, return -1.
    IF (@@error = 0 AND @@rowcount = 0)
      RETURN (-1);

    IF @finished = 1
    BEGIN
      IF (@pathType IS NULL) OR (@pathType = @pType)
        RETURN (@docID);
      ELSE
            RETURN (-1);          
    END
    SET @ownerID = @docID;
  END
  RETURN @docID;
END
go


--
-- Computes the fully qualified document name for given document id.
--
-- NOTE: This logic is preserved in case we need to support storing the
-- PATH_FULLNAME as an optional configuration.
--
-- Parameters:
--   @partitionID   - the partition where the document exists
--   @docID         - the ID of the document
--
-- Returns:
--   the fully qualified document name
--
IF (object_id(N'mds_internal_computeDocumentName', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_internal_computeDocumentName
END
go

create FUNCTION mds_internal_computeDocumentName(
    @partitionID NUMERIC,
    @docid       NUMERIC) RETURNS $(MDS_VARCHAR)($(FULLNAME))
AS
BEGIN
  DECLARE @name      $(MDS_VARCHAR)($(FULLNAME));
  DECLARE @pathName  $(MDS_VARCHAR)($(PATH_NAME));
  DECLARE @ownerDocID  NUMERIC;

  SELECT @ownerDocID = PATH_OWNER_DOCID, 
         @pathName = PATH_NAME
    FROM MDS_PATHS
    WHERE
      PATH_DOCID = @docid AND
      PATH_PARTITION_ID = @partitionID AND
      PATH_DOCID > 0;

  IF @ownerDocID = 0
    SET @name = N'';
  ELSE
  BEGIN
    EXEC @name = mds_getDocumentName @partitionID, @ownerDocID;
    SET @name = @name + N'/' + @pathName;
  END
             
  RETURN (@name);
END
go


--
-- Renames the document with given document id to the new name passed in.
-- The document with new name will continue to have the docId of the old
-- document.
--
-- Parameters:
--   @partitionID    - the partition where the document exists
--   @p_oldDocId     - document id for doc with old name. Used in step 3.
--   @p_oldName      - the original name of the component/document
--   @p_newName      - the new name of the component/document
--   @p_newDocName   - document name component of the new name
--   @p_vercomment   - Version comment for the renamed document
--   @p_xmlversion   - xml version of the document
--   @p_xmlencoding  - xml encoding of the document
--   @p_pkgChange    - true if package has changed between oldName and new
--			Name. false otherwise.
IF (object_id(N'mds_renameDocument', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_renameDocument
END
go

create PROCEDURE mds_renameDocument(@partitionID     NUMERIC,
                                    @p_oldDocId      INT,
                                    @p_fullpath      $(MDS_VARCHAR)($(FULLNAME)),
                                    @p_newName       $(MDS_VARCHAR)($(FULLNAME)),
                                    @p_newDocName    $(MDS_VARCHAR)($(PATH_NAME)),
	                            @p_vercomment    $(MDS_VARCHAR)($(VER_COMMENTS)),
	                            @p_xmlversion    $(MDS_VARCHAR)($(XML_VERSION)),
	                            @p_xmlencoding   $(MDS_VARCHAR)($(XML_ENCODING)),
	                            @p_pkgChange     INT)
AS

  -- If packageName is changed
  -- 1) Create a new path for newDocName
  -- 2) Delete the document portion of the path created in 1
  -- 3) Update the document portion of old path to refer to the parent path created
  --    in 1.
  -- else
  -- 1) Update oldname with newnames for given oldDocId.
  -- end

  -- all declarations
BEGIN
  DECLARE @docID          NUMERIC;
  DECLARE @parentDocID    NUMERIC;

  DECLARE @oldPartnID     NUMERIC;
  DECLARE @oldGuid        $(MDS_VARCHAR)($(GUID));
  DECLARE @oldDocElemName $(MDS_VARCHAR)($(ELEM_NAME));
  DECLARE @oldDocElemNS   $(MDS_VARCHAR)($(ELEM_NSURI));
  DECLARE @oldContID      NUMERIC;
  DECLARE @oldVerNum      NUMERIC;
  DECLARE @oldXmlVer      $(MDS_VARCHAR)($(XML_VERSION));
  DECLARE @oldXmlEnc      $(MDS_VARCHAR)($(XML_ENCODING));
  DECLARE @oldChkSum      NUMERIC;
  DECLARE @oldMoTypeName  $(MDS_VARCHAR)($(ELEM_NAME));
  DECLARE @oldMoTypeNS    $(MDS_VARCHAR)($(ELEM_NSURI));
  DECLARE @oldContentType NUMERIC;

  SET NOCOUNT ON;

  BEGIN TRY
    -- Lock the old document path before renaming so that it fails with
    -- resource_busy exception if somebody is modifying it or has locked it.
    EXEC mds_lockDocument @partitionID, @p_oldDocId; 

    -- Save the values from the tip document that need to be used for the
    -- renamed document
    SELECT @oldPartnID=PATH_PARTITION_ID, @oldGuid=PATH_GUID, 
           @oldContID=PATH_CONTENTID, @parentDocID=PATH_OWNER_DOCID,
           @oldDocElemName=PATH_DOC_ELEM_NAME, @oldDocElemNS=PATH_DOC_ELEM_NSURI,
           @oldVerNum=PATH_VERSION, @oldXmlVer=PATH_XML_VERSION, 
           @oldXmlEnc=PATH_XML_ENCODING,
           @oldChkSum=PATH_CONT_CHECKSUM,
           @oldMoTypeName=PATH_DOC_MOTYPE_NAME,
           @oldMoTypeNS=PATH_DOC_MOTYPE_NSURI,
           @oldContentType=PATH_CONTENT_TYPE
      FROM MDS_PATHS 
      WHERE PATH_DOCID=@p_oldDocId
            AND PATH_PARTITION_ID=@partitionID
            AND PATH_HIGH_CN IS NULL;

    IF @p_pkgChange = 1
    BEGIN
      DECLARE @saveVerNum      NUMERIC;

      -- We will create all its parent packages by creating a dummy document under the target package, 
      -- and delete the dummy document laterly.
      -- #(8360103) It is possible that there is a deleted/renamed old document in the place.
      -- We need to get the possible largest version# from the deleted/renamed document if it exists.
      -- Otherwise, it will fail to insert the document due to DUP key in index.

      SELECT @saveVerNum = ISNULL(MAX(PATH_VERSION), 1)
        FROM MDS_PATHS
        WHERE  PATH_FULLNAME = @p_newName
               AND PATH_PARTITION_ID = @partitionID
               AND PATH_TYPE= N'DOCUMENT';

      IF ( 1 > @saveVerNum )
        SET @saveVerNum = 1;
      ELSE
        SET @saveVerNum = @saveVerNum + 1;

      EXEC mds_internal_createPath @docID OUTPUT,    -- return doc id of new created path.
                                   @partitionID,
                                   -1,   -- Document ID ,will be -1 in case of create.
                                   @p_newName,
                                   N'DOCUMENT',
                                   @oldDocElemNS,
                                   @oldDocElemName,
                                   @saveVerNum,    -- Version number
                                   null, -- Version comment
                                   @p_xmlversion,
                                   @p_xmlencoding;
 
      SELECT @parentDocID = PATH_OWNER_DOCID
        FROM MDS_PATHS
        WHERE PATH_DOCID = @docID AND PATH_PARTITION_ID = @partitionID
          AND PATH_HIGH_CN IS NULL;

      -- The above path's entry was created only to simulate the creation
      -- of parent packages and can be thrown away now. A new path entry
      -- for the renamed document is inserted below with the path_owner_docid
      -- set to the parent pacakge created by the above SQL.
      DELETE FROM MDS_PATHS WITH(ROWLOCK)
        	WHERE PATH_DOCID = @docID AND PATH_PARTITION_ID = @partitionID;
    END

    -- Mark the current version as old version by setting PATH_HIGH_CN
    -- deleteDocument() is not used for this purpose since the typed
    -- dependencies originating from this document are still valid
    UPDATE MDS_PATHS WITH(ROWLOCK)
      SET PATH_HIGH_CN=$(INTXN_CN)
      WHERE PATH_DOCID = @p_oldDocId
      AND PATH_TYPE = N'DOCUMENT' AND PATH_PARTITION_ID=@partitionID
      AND PATH_HIGH_CN IS NULL;


    -- Select the highest version number for the document identified by the new
    -- name. This is because if there already a document exists which has the
    -- same fullPathName as the newName, get its latest version number and
    -- assign it to the new version being saved.[ofcourse after incrementing it
    -- by 1] bug # 5508200

    SELECT @oldVerNum = ISNULL(MAX(PATH_VERSION), @oldVerNum)
      FROM MDS_PATHS
      WHERE ( PATH_FULLNAME = @p_newName OR PATH_GUID = @oldGuid
        OR PATH_DOCID = @p_oldDocId) AND PATH_PARTITION_ID = @partitionID
        AND PATH_TYPE= N'DOCUMENT';


    -- #(6446544) deleteAllVersions() would leave behind the tip after 
    -- changing it's path_version to -ve of path_low_cn. If we find this as 
    -- the existing version, we should ignore it and create this version 
    -- with version=1
    IF ( 1 > @oldVerNum )
      SET @oldVerNum = 1;

      
    -- Create the renamed document as a new version with the same ContentID
    INSERT INTO MDS_PATHS
       (PATH_PARTITION_ID, PATH_NAME, PATH_FULLNAME, PATH_GUID,
        PATH_DOCID, PATH_OWNER_DOCID,  PATH_TYPE,
        PATH_DOC_ELEM_NSURI, PATH_DOC_ELEM_NAME,
        PATH_LOW_CN, PATH_HIGH_CN, PATH_CONTENTID,
        PATH_VERSION, PATH_VER_COMMENT, PATH_OPERATION,
        PATH_XML_VERSION,PATH_XML_ENCODING,
        PATH_CONT_CHECKSUM, PATH_DOC_MOTYPE_NSURI, PATH_DOC_MOTYPE_NAME,
        PATH_CONTENT_TYPE)
      VALUES
       (@oldPartnID, @p_newDocName, @p_newName, @oldGuid,
        @p_oldDocId, @parentDocID, N'DOCUMENT',
        @oldDocElemNS, @oldDocElemName,
        $(INTXN_CN), null, @oldContID,
        @oldVerNum + 1, null, $(RENAME_OP),
        @oldXmlVer, @oldXmlEnc, @oldChkSum,
        @oldMoTypeNS, @oldMoTypeName, @oldContentType);
  END TRY
  BEGIN CATCH
    $(RERAISE_MESSAGE_DECLARE)
    $(RERAISE_EXCEPTION)
  END CATCH
END
go

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
--

IF (object_id(N'mds_createLineageID', N'P') IS NOT NULL)
BEGIN
 DROP PROCEDURE mds_createLineageID
END
go

CREATE PROCEDURE mds_createLineageID(@partitionID NUMERIC,
                                 @application $(MDS_VARCHAR)($(DEPL_NAME)),
                                 @module      $(MDS_VARCHAR)($(DEPL_NAME)),
                                 @isSeeded    NUMERIC,
                                 @lineageID   NUMERIC OUTPUT)
AS
BEGIN
  DECLARE @linid NUMERIC;
  SET NOCOUNT ON;	
  BEGIN TRY
    DECLARE @seqName $(MDS_VARCHAR)($(SEQ_NAME));
          
    EXEC @seqName = mds_getLineageSequenceName @partitionID;
    EXEC mds_getNextSequence @linid OUTPUT, @seqName;    

    INSERT INTO MDS_DEPL_LINEAGES
         (DL_PARTITION_ID, DL_LINEAGE_ID, DL_APPNAME,
	  DL_DEPL_MODULE_NAME, DL_IS_SEEDED)
    VALUES
         (@partitionID,
          @linid,
          @application,
          @module,
          @isSeeded);
    SET @lineageID = @linid;
  END TRY
  BEGIN CATCH
    DECLARE @err    INT;
    SELECT  @err = @@error;
    IF @err = $(DUP_VAL_ON_INDEX) OR 
       @err = $(DUP_VAL_ON_CONSTRAINT)
    BEGIN
       RAISERROR(N'$(ERROR_LINEAGE_ALREADY_EXIST)', 16, 1);
    END
    ELSE
    BEGIN
      $(RERAISE_MESSAGE_DECLARE)
      $(RERAISE_EXCEPTION)     
    END    
  END CATCH
END;
go

-- commit transaction mdsinc
go
