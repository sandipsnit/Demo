
/*==================================================================*/
-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- MDSMDINS.pls - MDS metadata services INternal Common Specification
--
-- MODIFIED    (MM/DD/YY)
-- bchandre     09/14/12   - #(14114132) Removed rebuildIndexes
-- jhsi         09/16/11   - Added param contentType to prepareDocForInsert
-- erwang       08/22/11   - Added moTypeName etc. to prepareDocForInsert()
-- rchalava     07/20/11   - Add deprovisionTenant()
-- jhsi         06/06/11   - VPD - multitenancy support
-- gnagaraj     09/01/10   - XbranchMerge gnagaraj_bug-9796578 from main
-- gnagaraj     08/19/10   - #(9796578) Refactor purgeMetadata
-- vyerrama     12/10/09   - Added createLineageID
-- akrajend     03/17/10   - Modified processCommit() to handle commit without
--                           critical section.
-- gnagaraj     03/02/10   - #(9317745) Remove rebuildIndexes()
-- akrajend     01/05/10   - Modify recreateSequence to recreate lineageID
--                           sequence with new lineage value.
-- erwang       03/11/09   - #(8325229) Added toCharNamePart().
-- rupandey     02/09/09   - #(8218775) Inserted an empty line at the begining of 
--                           this file until rcu fixes #(8215729).
-- rupandey     11/03/08   - #(6996938) Added isPurgeRequired().
-- gnagaraj     06/17/08   - #(7038905) Add rebuildIndexes
-- vyerrama     03/31/08   - Merged changes from #(5891638) with #(6726806).
-- abhatt       02/04/08   - #(5891638) Changes requiring repository upgrade
-- gnagaraj     03/17/08   - #(6838583) Add purgeMetadata()
-- gnagaraj     11/08/07   - #(6600202) Add acquireWriteLock()
-- pwhaley      11/01/07   - #(5926597) Return transaction time from
--                           processCommit.
-- abhatt       07/10/07   - #(6135856) Remove lockDocument() procedure spec,
--                           remove MAX_SECONDS_TO_WAIT_FOR_LOCK
-- gnagaraj     07/03/07   - #(6165956) Add new default params to
--                           prepareDocumentForInsert() & deleteDocument()
-- vyerrama     11/21/06   - Added checkDocumentExistence
-- erwang       10/19/06   - Rename getDocumentID() to getDocumentIDByGUID etc.
-- erwang       10/02/06   - Change some functions to procedures
-- gnagaraj     09/05/06   - Support saving type info in mds_paths table
-- abhatt       09/04/06   - Enhanced processCommit to determine if auto purge
--                           is required.
-- jejames      08/04/06   - Refactored deletePartition, introduced
--                           recreateSequences
-- jejames      07/20/06   - Added createNewTransaction and refactored 
--                           processCommit
-- abhatt       06/12/06   - Concurrency Issues Handling
-- rchalava     05/26/06  -  Added deletePartition() method.
-- gnagaraj     05/16/06   - Versioning support
-- gnagaraj     05/16/06   - Created by refactoring MDSMDINS
--
/*==================================================================*/

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE                 mds_internal_common AS

 -----------------------------------------------------------------------------
  ---------------------------- PRIVATE VARIABLES ------------------------------
  -----------------------------------------------------------------------------


  --
  -- Return a list of Path elements that match the given set of patterns.
  -- 
  -- Parameters:
  --	results		- A list of string containing either FOUND OR NOT_FOUND
  --	partitionID	- The partition ID where the documents exist.
  --	patterns	- List of patterns which will be used to filter the
  -- 			  results.
  --
  PROCEDURE checkDocumentExistence(results	OUT mds_stringArray,
				   partitionID 	IN NUMBER,
				   patterns    	IN mds_stringArray);


  --
  -- Delete the package.
  --
  -- Parameters:
  --   return       - -1 if the package was not deleted because it contained 
  --                  documents or sub packages, 0 if the package is 
  --                  successfully deleted.
  --   partitionID  - the partition where the package exists.
  --   pathID       - ID of the package to delete
  --
  PROCEDURE deletePackage(
    result        OUT NUMBER,
    partitionID	      MDS_PATHS.PATH_PARTITION_ID%TYPE,
    pathID            MDS_PATHS.PATH_DOCID%TYPE);


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
  --   force        - Specify 0 if the concurrent update checking should not be
  --                  done.
  --
  PROCEDURE deleteDocument(
    partitionID     MDS_PATHS.PATH_PARTITION_ID%TYPE,
    docID           MDS_PATHS.PATH_DOCID%TYPE,
    lowCN           MDS_PATHS.PATH_LOW_CN%TYPE,
    version         MDS_PATHS.PATH_VERSION%TYPE,
    docName         MDS_PATHS.PATH_FULLNAME%TYPE,
    force           INTEGER);


  --
  -- Helper procedure for Shredded DB specific deprovisionTenant procedure.
  -- NOTE : This package procedure should NOT be directly called from Java code.
  -- Instead, it is internally consumed by the deprovisonTenant procedure
  -- specifically implemented for Shredded DB. This procedure have to be made 
  -- public as Shredded DB specific deprovisionTenant procedure should invoke 
  -- this procedure internally.
  --
  -- Parameters:
  --   partitionID - Partition Id.
  --   tenantID - Enterprise Id.
  PROCEDURE deprovisionTenant(partitionID MDS_PATHS.PATH_PARTITION_ID%TYPE,
                              tenantID MDS_PATHS.ENTERPRISE_ID%TYPE);


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
  --
  PROCEDURE deletePartition(partitionID     MDS_PATHS.PATH_PARTITION_ID%TYPE);


  --
  -- Retrieves the document id for the specified fully qualified path name.
  -- The pathname must begin with a '/' and should look something like:
  --   /oracle/apps/AK/mydocument
  --
  -- Parameters:
  --   partitionID   - the partition where the document exists.
  --   fullPathName  - the fully qualified name of the document
  --   pathType      - the type of the document, either 'DOCUMENT' or 'PACKAGE'
  --                   if no type is specified, and there happens to be a path
  --                   of both 'DOCUMENT' and 'PACKAGE' (which is unlikely),
  --                   then the id of the DOCUMENT will be returned
  --
  -- Returns:
  --   Returns the ID of the path or -1 if no such path exists
  --
  FUNCTION getDocumentID(
    partitionID  NUMBER,
    fullPathName VARCHAR2,
    pathType     VARCHAR2 DEFAULT NULL) RETURN NUMBER;


  --
  -- Retrieves the document id for the specified fully qualified path name.
  -- The pathname must begin with a '/' and should look something like:
  --   /oracle/apps/AK/mydocument
  --
  -- Parameters:
  --   partitionID   - the partition where the document exists.
  --   fullPathName  - the fully qualified name of the document
  --   mdsGuid      -  GUID of the document
  --   pathType      - the type of the document, either 'DOCUMENT' or 'PACKAGE'
  --                   if no type is specified, and there happens to be a path
  --                   of both 'DOCUMENT' and 'PACKAGE' (which is unlikely),
  --                   then the id of the DOCUMENT will be returned
  -- Returns:
  --   Returns the ID of the path or -1 if no such path exists
  --
  FUNCTION getDocumentIDByGUID(
    partitionID  NUMBER,
    fullPathName VARCHAR2,
    mdsGuid      VARCHAR2,
    pathType     VARCHAR2) RETURN NUMBER;

  --
  -- For each document name, retrieve the corresponding document ID.
  -- The document ID for docs[i] is in docIDs[i]
  --
  PROCEDURE getDocumentIDs(
    partitionID IN NUMBER,
    docs   IN   mds_stringArray,
    docIDs OUT  mds_numArray);


  --
  -- Given the document id, find the fully qualified document name
  --
  -- Parameters:
  --   partitionID  - the partition where the document exists.
  --   docID   - the ID of the document
  --
  -- Returns:
  --   the fully qualified document name
  --
  FUNCTION getDocumentName(
    partitionID		NUMBER,
    docID NUMBER) RETURN VARCHAR2;


  --
  -- Gives the partitionID for the given partitionName. If the entry not found,
  -- it will create new entry in MDS_PARTITIONS table and returns the new
  -- partitionID.
  --
  -- Parameters:
  --   partitionID(OUT)  - Returns the ID for the given partition.
  --   partitionExists   - OUT param, value to indicate if partition already 
  --                       exists.
  --   partitionName     - Name of the Repository partition.
  --
  PROCEDURE getOrCreatePartitionID(
                  partitionID OUT MDS_PATHS.PATH_PARTITION_ID%TYPE,
                  partitionExists OUT INTEGER,
                  partitionName VARCHAR2);
  

  --
  -- Recreates Document, Content and Lineage ID sequences with the minimum
  -- documentID, contentID and lineageID set to the values provided as input
  -- parameters.
  --
  -- Parameters:
  --   partitionID  -  Partition ID.
  --   minDocId     -  Minimum Document ID
  --   minContentId -  Minimum Content ID
  --   minLineageId -  Minimum Content ID
  --
  PROCEDURE recreateSequences(partitionID   MDS_PATHS.PATH_PARTITION_ID%TYPE,
                              minDocId      NUMBER,
                              minContentId  NUMBER,
                              minLineageId  NUMBER DEFAULT NULL);

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
  --                  to locate the document.
  --  
  PROCEDURE acquireWriteLock(
    partitionID    MDS_PATHS.PATH_PARTITION_ID%TYPE,
    fullPathName   MDS_PATHS.PATH_FULLNAME%TYPE,
    mdsGuid        MDS_PATHS.PATH_GUID%TYPE DEFAULT NULL);

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
  --   moTypeName   - Top Element Name from base document of this customization document.
  --   motypeNSURI  - NSURI from the base document of this customization document
  --   contentType  - Document content stored as: 0 - Shredded XML
  --                                              1 - BLOB
  --                                              2 - Unshredded XML
  --
  PROCEDURE prepareDocumentForInsert(
    newDocID   OUT mds_paths.path_docid%TYPE,
    docVersion IN OUT mds_paths.PATH_VERSION%TYPE,
    contID     OUT mds_paths.PATH_CONTENTID%TYPE,
    partitionID    NUMBER,
    fullPathName   VARCHAR2,
    pathType       VARCHAR2,
    docElemNSURI   VARCHAR2,
    docElemName    VARCHAR2,
    verComment     VARCHAR2,
    xmlversion     VARCHAR2,
    xmlencoding    VARCHAR2,
    mdsGuid        VARCHAR2,
    lowCN          NUMBER,
    documentID     NUMBER,
    force          INTEGER,
    checksum       NUMBER DEFAULT NULL,
    lineageID      NUMBER DEFAULT NULL,
    moTypeNSURI    VARCHAR2 DEFAULT NULL,
    moTypeName     VARCHAR2 DEFAULT NULL,
    contentType    NUMBER DEFAULT NULL);

  
  --
  -- Check if a lineage entry exists for the given application and module in the
  -- partition. If it exists that value is returned otheriwse a lineage is 
  -- created and returned.
  -- paritionID  - parition id
  -- application - application for which the lineage is required.
  -- module      - module which is part of the application.
  -- isSeeded    - 1 if it represents seeded documents entry, 0 otherwise.
  -- return lineageID
  --
  --
  PROCEDURE createLineageID(partitionID MDS_PATHS.PATH_PARTITION_ID%TYPE,
                                 application VARCHAR2,
                                 module      VARCHAR2,
                                 isSeeded    NUMBER,
                                 lineageID OUT NUMBER);
                                  
                                  
  PROCEDURE doConcurrencyCheck(
    docID        IN    NUMBER,
    fullPathName IN    VARCHAR2,
    lowCN        IN    NUMBER,
    curVersion         INTEGER, 
    partitionID        MDS_PATHS.PATH_PARTITION_ID%TYPE);


    -- Creates a transaction.
    --
    -- Generates an unique commit number and inserts a new transaction 
    -- entry into mds_transactions
    -- Parameters
    --     commitNumber Commit Number.
    --     partitionID  PartitionID for the repository partition
    --     userName     User whose changes are being commited, can be null.
    --
  PROCEDURE createNewTransaction (commitNumber OUT NUMBER,
                                  partitionID      NUMBER,
                                  username         VARCHAR2);


  -- Does all the processing for commiting metadata changes made in a
  -- transaction.
  --
  -- Parameters
  --  commitNumber      Commit Number.
  --  partitionID       PartitionID for the repository partition
  --  userName          User whose changes are being commited, can be null.
  --  autoPurgeInterval Minimum time interval to wait before invoking the next 
  --                    autopurge
  --  doPurgeCheck      Value to indicate whether to do a purge check or not
  --  commitDBTime      OUT parameter, transaction commit time.
  --  isCSCommit        IN OUT parameter. Calling procedure can request whether
  --                    to commit the transaction with critical section ( by 
  --                    specifying value 1) or not (value other than 1) using 
  --                    this parameter. Even if the request is for commit
  --                    without critical section, we may internally commit
  --                    the transaction with critical section if required. The
  --                    out value will always reflect whether the actual commit
  --                    was done with CS (value 1) or not (value -1).
  --
  PROCEDURE processCommitNew(commitNumber  OUT NUMBER,
                             partitionID       NUMBER,
                             username          VARCHAR2,
                             autoPurgeInterval NUMBER,
                             doPurgeCheck      NUMBER,
                             purgeRequired OUT INTEGER,    -- #(5891638)
                             commitDBTime  OUT TIMESTAMP,  -- #(5926597)
                             isCSCommit IN OUT NUMBER);


  -- Does all the processing for commiting metadata changes made in a
  -- transaction. Calling this method will ensure that the commit is always done
  -- using a critical section. This method is maintained for backward
  -- compatibility reasons.
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
  PROCEDURE processCommit(commitNumber  OUT NUMBER,
                          partitionID       NUMBER,
                          username          VARCHAR2,
                          autoPurgeInterval NUMBER,
                          doPurgeCheck      NUMBER,
		          purgeRequired OUT INTEGER,
                          commitDBTime  OUT TIMESTAMP);
                          
  
  -- Checks if the purge interval has elapsed since the last_purge_time.
  -- If so, returns the current DB time (which will cause a purge to be
  -- invoked from java). 
  -- It also updates the last_purge_time for the partition if purge interval
  -- has elapsed as an optimization to avoid parallel purges.
  -- Parameters
  --  partitionID       PartitionID for the repository partition
  --  autoPurgeInterval Minimum time interval to wait before invoking the next 
  --                    autopurge
  --  purgeRequired     OUT parameter 1 purge required.
  --  dbSystimeTime     OUT parameter. DB system time when the last purge occured.
  --
  PROCEDURE isPurgeRequired(partitionID       NUMBER,
                            autoPurgeInterval NUMBER,
                            purgeRequired     OUT INTEGER,
                            dbSystemTime         OUT TIMESTAMP); 


  -- Purges data in in common MDS tables corresponding to the current set 
  -- of purgeable document versions stored in in MDS_PURGE_PATHS table.
  --
  -- NOTE: This method is only expected to be invoked from 
  -- mds_internal_shredded/mds_internal_xdb packages 
  -- 
  -- Parameters
  --  partitionID      PartitionID for the repository partition
  --
  PROCEDURE purgeCommonTables(partitionID NUMBER);

  --
  -- Renames the document with given document id to the new name passed in.
  -- The document with new name will continue to have the docId of the old
  -- document.
  --
  -- Parameters:
  --   partitionID    - the partition where the document exists
  --   p_oldDocId     - document id for doc with old name
  --   p_newName      - the new name of the component/document
  --   p_newDocName   - document name component of the new name
  --   p_vercomment   - Version comment for the renamed document
  --   p_xmlversion   - xml version of the document
  --   p_xmlencoding  - xml encoding of the document
  --   p_pkgChange    - true if package has changed between oldName and new
  --			Name. false otherwise.
  --
  PROCEDURE renameDocument(partitionID     NUMBER,
                           p_oldDocId      INTEGER,
                           p_fullpath      VARCHAR2,
			   p_newName       VARCHAR2,
			   p_newDocName    VARCHAR2,
                           p_vercomment    VARCHAR2,
			   p_xmlversion    VARCHAR2,
			   p_xmlencoding   VARCHAR2,
			   p_pkgChange     INTEGER);


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
FUNCTION toCharNamePart(value  NUMBER) RETURN VARCHAR2;

--
-- A function to generate a predicate to be used in the where clause of any
-- select statements on the MDS schema table with this VPD policy function 
-- specified.
--
-- Parameters:
--   schema_var    - the MDS schema name where this policy applied.
--   table_var     - the MDS table name where this policy applied.
--
-- Returns:
--   The string that will be used for the WHERE predicate clause. 
--
FUNCTION vpdReadPolicy(schema_var IN VARCHAR2,
                       table_var  IN VARCHAR2) 
	RETURN VARCHAR2;

--
-- A function to generate a predicate to be used in the where clause of any
-- insert, update or delete statements on the MDS schema table with this
-- VPD policy function specified.
--
-- Parameters:
--   schema_var    - the MDS schema name where this policy applied.
--   table_var     - the MDS table name where this policy applied.
--
-- Returns:
--   The string that will be used for the WHERE predicate clause. 
--
FUNCTION vpdWritePolicy(schema_var IN VARCHAR2,
                        table_var  IN VARCHAR2) 
	RETURN VARCHAR2;

END;

/
COMMIT;
