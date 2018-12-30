
/*==================================================================*/
-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- MDSMDINS.pls - MDS INternal Shredded Repository Specification
--
-- MODIFIED    (MM/DD/YY)
-- erwang       11/28/12   - Bump up repos version to 11.1.1.64.61
-- bchandre     09/24/12   - #(14114132) Updated repos version to 11.1.1.64.18
-- erwang       06/04/12   - XbranchMerge erwang_bug-13110517 from main
-- erwang       06/04/12   - Updated repos version to 11.1.1.63.14 
-- vyerrama     11/10/11   - Updated repos version to 11.1.1.61.83 for parallel
--                           pkg creation
-- jhsi         09/16/11   - Update repos version to 11.1.1.61.63 for
--                           unshredded xml
-- erwang       09/02/11   - Bump repository version to 11.1.1.61.36
-- jhsi         08/24/11   - #(12914180) Change repos version for multitenancy
-- erwang       08/23/11   - bump up repos version to 11.1.1.61.21
-- rchalava     08/16/11   - Update repos version to 11.1.1.61.15 (reverted
--                           purge paths table changes).
-- vyerrama     07/08/11   - #(12731286) Update repos version to 11.1.1.60.85
-- rchalava     07/20/11   - Add deprovisionTenant()
-- jhsi         06/17/11   - Update version to 11.1.1.60.60 for Multi-tenancy
-- gnagaraj     04/04/11   - XbranchMerge gnagaraj_bug-11770346 from main
-- gnagaraj     04/01/11   - #(11770346) Update repos version to 11.1.1..60.10
-- akrajend     02/28/11   - #(11709515) Bump up the version to 11.1.1.59.67.
-- akrajend     09/14/10   - Added new index for label based read. Change repos
--                           version to 11.1.1.58.22
-- gnagaraj     09/01/10   - XbranchMerge gnagaraj_bug-9796578 from main
-- gnagaraj     08/31/10   - #(9796578) Purge performance optimizations -
--                           Change respos version to 11.1.1.57.81
-- vyerrama     07/01/10   - XbranchMerge vyerrama_sandbox_guid from main
-- akrajend     01/19/10   - #(9551097) Upgrade version for deploy support to
--                           11.1.1.56.59
-- akrajend     01/19/10   - #(9233460) Update repos version to 11.1.1.56.03
-- akrajend     01/13/10   - #(9034016) Update repos version to 11.1.1.55.99
-- gnagaraj     10/08/09   - #(8859749) Update repos version to 11.1.1.55.16
-- gnagaraj     08/17/09   - #(8495663) Change repos version to 11.1.1.54.63
-- jhsi         07/29/09   - Moved REPOS_VERSION from body to spec
-- pwhaley      06/24/09   - #(8619836) Do clob<->clob compares.
-- pwhaley      08/16/08   - #(7316685) Add clob comparison functions.
-- gnagaraj     03/11/08   - #(6838583) Add purgeMetadata()
-- gnagaraj     10/22/07   - #(6508932) Store translations in generic tables
-- abhatt       02/07/07   - Added getReposVersionAndEncoding
-- erwang       10/02/06   - convert some functions to procedures.
-- jejames      08/07/06   - Introduced deletePartition (refactored from
--                         - Common Specification), refactored getNamespaceID
-- gnagaraj     06/17/06   - Renamed pacakge to mds_internal_shredded
-- gnagaraj     05/16/06   - Refactored generic logic to mds_internal_common
-- rchalava     05/26/06   - Added deletePartition() method.
-- rchalava     05/17/06   - Repository partition support.
-- ykosuru      02/09/06   - Add GUID to get and createPath methods 
-- kselvara     01/05/06   - Added rename procdedure
-- gnagaraj     09/22/05   - Add deletePacakge() 
-- gnagaraj     05/31/05   - Rename getMinJRADVersion to getMinMDSVersion 
-- rrason       04/27/05   - Added toNumber() function for query api.
-- gnagaraj     04/19/05   - Optimize docID computation storing doc fullpath 
--                           in MDS_PATHS 
-- gnagaraj     03/10/05   - Expose exportDocumentbyID()
-- enewman      12/20/04   - enewman_support_generic_xml
-- enewman      12/01/04  -  Support for generic xml, JDR->MDS rename 
-- enewman      02/04/04  -  Add refactor()
-- enewman      06/12/03  -  Reduce network traffic for exporting XLIFF
-- enewman      05/30/03  - #(2822216) Performance improvements
-- enewman      05/16/03  -  Add exportXLIFFDocument
-- kaalvare     10/02/02  - #(2605120) Modify lockDocument signature
-- enewman      07/22/02  - #(2424399) Add support for xml version, encoding
-- enewman      07/18/02  -  Add getMinJRADVersion(), getRepositoryVersion()
-- enewman      06/19/02  - #(2424554) Add getVersion()
-- enewman      06/06/02  - #(2365869) Add support for "who" columns
-- enewman      06/06/02  -  Modifications to follow apps coding standards
-- enewman      05/24/02  -  Creating from cremdsapi.sql
--
/*==================================================================*/

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE mds_internal_shredded AS

  -- This is used to verify that the repository API and MDS java code are
  -- compatible.  REPOS_VERSION should be updated every time repository schema/ 
  -- stored procedures are modified to current version of MDS.
  --
  -- In addition, if MDS java code is not compatible with older repository,
  -- OracleDB.MIN_SHREDDED_REPOS_VERSION should be changed to this value.
  REPOS_VERSION    CONSTANT VARCHAR2(32) := '11.1.1.64.61';

  ------------------------------------------------------------------------------
  ---------------------------- PUBLIC PROCEDURES -------------------------------
  ------------------------------------------------------------------------------
  --
  -- Deletes the tenant in the given partition. If there are any documents
  -- associated with the tenant in the given partition, this method will delete 
  -- all those documents. 
  --
  -- Parameters:
  --   partitionId - Partition Id.
  --   tenantId - Enterprise Id.
  --
  PROCEDURE deprovisionTenant(partitionID MDS_PATHS.PATH_PARTITION_ID%TYPE,
                              tenantID MDS_PATHS.ENTERPRISE_ID%TYPE);

  --
  -- Deletes the given partition. If there are any documents in the given
  -- partition, this method will delete all those documents.
  --
  -- Parameters:
  --   partitionName - Name of the partition.
  --
  PROCEDURE deletePartition(partitionName VARCHAR2);


  --
  -- Export the XML for tip version of a document and pass it back in
  -- 32k chunks.  This function will return XML chunks, with a
  -- maximum size of 32k.
  --
  -- Specifying a document name will initiate the export.  Thereafter, a NULL
  -- document name should be passed in until the export is complete.
  -- That is, to export an entire document, you should do:
  --
  -- firstChunk := mds_internal.exportDocumentByName(isDone,
  --                                                 '/oracle/apps/fnd/mydoc');
  -- WHILE (isDone = 0)
  --   nextChunk := mds_internal.exportDocumentByName(isDone, NULL);
  -- END LOOP;
  --
  -- Parameters:
  --   chunk          - OUT The exported XML, in 32 chunks.
  --   exportFinished - OUT parameter which indicates whether or not the export
  --                    is complete.  1 indicates the entire document is
  --                    exported, 0 indicates that there are more chunks
  --                    remaining.
  --
  --   partitionID  - the partition where the document exists.
  --   fullName  - the fully qualifued name of the document.  however,
  --               after the first chunk of text is exported, a NULL value
  --               should be passed in.
  --
  --
  --   formatted - a non-zero value indicates that the XML is formatted nicely
  --               (i.e. whether or not the elements are indented)
  --
  PROCEDURE exportDocumentByName(
    chunk          OUT VARCHAR2,
    exportFinished OUT INTEGER,
    partitionID        NUMBER,
    fullName           VARCHAR2,
    formatted          INTEGER DEFAULT 1);


  --
  -- Export the XML for a document and pass it back in 32k chunks.  This
  -- function will return XML chunks, with a maximum size of 32k.
  --
  -- Specifying a document ID will initiate the export.  Thereafter, a NULL
  -- document ID should be passed in until the export is complete.
  --
  -- Parameters:
  --   chunk          - OUT The exported XML, in 32 chunks.
  --   exportFinished - OUT parameter which indicates whether or not the export
  --                    is complete.  1 indicates the entire document is
  --                    exported, 0 indicates that there are more chunks
  --                    remaining.
  --
  --   docID          - PATH_DOCID of the document, obtained using getDocumentID(),
  --                    however after the first chunk of text is exported,
  --                    a NULL value should be passed in.
  --
  --   partitionID    - the partition where the document exists.
  --   isFormatted    - a non-zero value indicates that the XML is formatted
  --                    nicely (i.e. whether or not the elements are indented)
  --
  PROCEDURE exportDocumentByID(
    chunk          OUT VARCHAR2,
    exportFinished OUT INTEGER,
    partitionID        MDS_PATHS.PATH_PARTITION_ID%TYPE,
    docID              MDS_PATHS.PATH_DOCID%TYPE,
    contentID          MDS_PATHS.PATH_CONTENTID%TYPE,
    versionNum         MDS_PATHS.PATH_VERSION%TYPE,
    isFormatted        INTEGER DEFAULT 1);


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

  PROCEDURE getNamespaceID(namespaceID OUT mds_namespaces.ns_id%TYPE,
                           partitionID     mds_namespaces.ns_partition_id%TYPE,
                           uri             mds_namespaces.ns_uri%TYPE);

  --
  -- Gets the minimun version of MDS with which the repository is
  -- compatible.  That is, the actual MDS version must be >= to the
  -- minimum version of MDS in order for the repositroy and java code to
  -- be compatible.
  --
  -- Returns:
  --   Returns the mimumum version of MDS
  --
  FUNCTION getMinMDSVersion RETURN VARCHAR2;

  --
  -- Gets the version of the repository API.  This API version must >= to the
  -- java constant CompatibleVersions.MIN_REPOS_VERSION.
  --
  -- Returns:
  --   Returns the version of the repository
  --
  FUNCTION getRepositoryVersion RETURN VARCHAR2;

  --
  -- Gets the version and encoding of the repository API. 
  -- 
  -- Returns:
  --   Returns the version and encoding of the repository
  --
  PROCEDURE getReposVersionAndEncoding(reposVersion   OUT VARCHAR2,
                                       dbEncoding     OUT VARCHAR2);

  --
  -- Purges document versions from the repository.
  -- Only those document versions which were created older than secondsToLive,
  -- which are not labeled and are not the tip versions are purged.
  -- 
  -- For all such purgeable versions, this method purges corresponding 
  -- content from base and content tables like mds_paths,
  -- mds_attributes, mds_components, mds_dependencies, mds_streamed_docs etc.
  --
  -- Parameters  
  --  numVersionsPurged - Out parameter indicating number of versions purged
  --  partitionID       - PartitionID for the repository partition
  --  purgeCompareTime  - Creation time prior to which versions can be purged
  --  isAutoPurge       - 0 if manual purge and 1 if auto-purge
  --  commitNumber      - Commit number used for purging path and content tables
  --
  PROCEDURE purgeMetadata(numVersionsPurged  OUT NUMBER,
                          partitionID        NUMBER,
                          purgeCompareTime   TIMESTAMP,
                          secondsToLive      NUMBER,
                          isAutoPurge        NUMBER,      
                          commitNumber       OUT NUMBER);  

  -- Used in the queryapi. The attr_value column contains both strings and
  -- number values in a varchar2. In the query api we need to be able to
  -- complete number and string comparisions against the values in the column.
  -- However if we use to_number() on the column the string values are going to
  -- fall over in a big heap and give the  ORA-01722: invalid number exception.
  -- This function allows us to handle this scenario more gracefully.
  --
  -- Returns:
  --   Returns null if the attr_value is a string else returns the number value.
  --
  FUNCTION toNumber(attribute_value VARCHAR2) RETURN NUMBER;

  -- Functions used in the queryapi to compare with a CLOB column such as
  -- ATTR_LONG_VALUE. Used to avoid ORA-00932 errors.
  -- Not required in SQLServer.
  -- Does the indicated comparison on its operands and returns 1 if true,
  -- 0 if false.
  -- #(8619836): comparisons of CLOB to VARCHAR2 can fail to work as
  -- expected: if the DB charset is multibyte, CLOB will be UCS-2, not
  -- DB charset(!).
  FUNCTION clobEQ(clobVal       CLOB,
                  val2          CLOB) RETURN NUMBER;
  FUNCTION clobLT(clobVal       CLOB,
                  val2          CLOB) RETURN NUMBER;
  FUNCTION clobGT(clobVal       CLOB,
                  val2          CLOB) RETURN NUMBER;
  FUNCTION clobNE(clobVal       CLOB,
                  val2          CLOB) RETURN NUMBER;
  FUNCTION clobLE(clobVal       CLOB,
                  val2          CLOB) RETURN NUMBER;
  FUNCTION clobGE(clobVal       CLOB,
                  val2          CLOB) RETURN NUMBER;
END;
/

COMMIT;
