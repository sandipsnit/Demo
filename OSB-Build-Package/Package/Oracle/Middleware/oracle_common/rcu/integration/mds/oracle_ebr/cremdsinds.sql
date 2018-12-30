-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- CREMDSINDS.SQL - CREate MDS INDexeS
-- 
-- NOTES
--    This script is replicated from the same file under oracle folder
--    for EBR support.
-- 
-- MODIFIED    (MM/DD/YY)
-- pwhaley      02/24/12   - XbranchMerge pwhaley_bug-12859728 from main
-- pwhaley      02/15/12   - #(12859728) Added MDS_PATHS_N9 MOtype index
-- jhsi         09/16/11   - Added unique index MDS_MD_U1
-- jhsi         06/01/11   - VPD - multitenancy support
-- erwang       04/19/11   - #(10360031) Added MDS_PATHS_N8
-- jhsi         01/18/11   - Replicated for EBR support
-- akrajend     09/14/10   - Added new index for label based read. 
-- gnagaraj     12/03/09   - Index changes for deployment support
-- erwang       02/06/09   - Update MDS_PATHS_N1,MDS_COMPONENTS_N1 and MDS_ATTRIBUTES_N1 
--                           for performance reason
-- vyerrama     12/17/08   - #(7651339) Added two nex indexes on MDS_LARGE_ATTRIBUTES
-- gnagaraj     10/08/08   - #(7442627) Add unique index for mds_partitions
-- gnagaraj     07/08/08   - #(7199149) Adjust partitionID in unique indexes
--                           for multi partition read/write performance
-- gnagaraj     03/11/08   - #(6838583) Add indexes for mds_purge_paths
-- gnagaraj     10/22/07   - #(6508932) Remove MDS_ATTRIBUTES_TRANS table
-- gnagaraj     08/22/07   - #(6357992) Add new index to optimize getChanges() query
-- rupandey     04/26/07   - Disabled index creation for XDB tables.
-- erwang       04/16/07   - #(5998529) Add MDS_PATHS_N5 etc.
-- gnagaraj     02/07/07   - #(5862363) Define unique index for MDS_TXN_LOCKS
-- gnagaraj     02/05/07   - #(5862363) Add PATH_GUID to MDS_PATHS_U2
-- pwhaley      01/25/07   - #(5840250) Adjust indexes for finding dependencies.
-- rupandey     12/15/06   - Not creating index on MDS_XDB_TRANSFORMS. Table removed.
-- gnagaraj     12/01/06   - #(5690942) Define indexes with lowCN&highCN for 
--                           improving transaction performance.
-- abhatt       11/09/06   - #(5508200)Removed path_high_cn from 
--                           MDS_PATHS_U2 and MDS_PATHS_U3
-- rupandey     09/25/06   - Moved Indexes from cremdxdtbs.sql to here.
-- rupandey     09/26/06   - Disabled calls to drop indexes. They would be automatically 
--                           dropped when the table they reference is dropped. Clients
--                           who want to run this script in isolation should first drop
--                           existing indexes, before executing this script.
-- gnagaraj     08/31/06   - Restore unique index for MDS_PATHS
-- rnanda       08/24/06   - Rem fix
-- rnanda       08/17/06   - Commenting MDS_PATHS_GUID index.
-- rnanda       08/14/06   - RCU integration
-- vyerrama     08/06/06   - Added index on MDS_SANDBOXES table.
-- abhatt       07/31/06   - Added index on Transactions table.
-- pwhaley      06/06/02   - More index change for versioning.
-- gnagaraj     05/15/06   - Index changes for versioning.
-- ykosuru      05/24/06   - Remove MDS_PATHS_GUID and update MDS_PATHS_U3 
--                           indexes 
-- rchalava     05/15/06   - Add PARTITION_ID column for all the indexes.
-- ykosuru      02/09/06   - Add index on GUID column 
-- gkonduri     02/07/06   - fix dependencies index problem. 
-- gnagaraj     01/28/06   - Index for streamed documents 
-- gnagaraj     12/13/05   - Dependency storage support.
-- gnagaraj     05/06/05   - Add index for MDS_REFERENCES table.  
-- gnagaraj     03/28/05   - Optimize docID computation storing doc fullpath 
--                           in MDS_PATHS 
-- clowes       02/02/05  -  Index on MDS_ATTRIBUTES(ATT_MDS_REF)
-- enewman      12/01/04  -  Rename to MDS
-- gnagaraj     01/28/03  - #(2768657) Add unique contraint for
--                           JDR_ATTRIBUTES_TRANS_U1
-- enewman      10/30/02  -  Creation. 
--

SET VERIFY OFF

REM Find documents by id
REM #(5840250) Reorder so version is last.
REM drop index MDS_PATHS_U1;
create unique index MDS_PATHS_U1
on MDS_PATHS_T( PATH_DOCID, PATH_PARTITION_ID, PATH_VERSION )
;

REM Find documents by owner
REM drop index MDS_PATHS_U2;
create unique index MDS_PATHS_U2
on MDS_PATHS_T( PATH_OWNER_DOCID, PATH_NAME, PATH_VERSION, PATH_PARTITION_ID, ENTERPRISE_ID, PATH_GUID )
;

REM Find documents by documentname or guid. This is a critical index to
REM ensure good performance for getDocument()
REM drop index MDS_PATHS_U3;
create unique index MDS_PATHS_U3
on MDS_PATHS_T( PATH_FULLNAME, PATH_VERSION, PATH_PARTITION_ID, ENTERPRISE_ID, PATH_GUID )
;

REM Find documents by name
REM drop index MDS_PATHS_N1; 
create index MDS_PATHS_N1
on MDS_PATHS_T( PATH_NAME, PATH_PARTITION_ID, ENTERPRISE_ID, PATH_TYPE, PATH_CONTENTID, PATH_DOC_ELEM_NSURI, PATH_DOC_ELEM_NAME, PATH_GUID )
;

REM #(5690942) - Find documents by lowCN, this is required improving performance
REM of replacing -1 with actual commit number in processCommit()
REM drop index MDS_PATHS_N2; 
create index MDS_PATHS_N2 on MDS_PATHS_T( PATH_LOW_CN, PATH_PARTITION_ID )
;

REM #(5690942) - Find documents by highCN
REM drop index MDS_PATHS_N3; 
create index MDS_PATHS_N3 on MDS_PATHS_T( PATH_HIGH_CN, PATH_PARTITION_ID )
;

REM #(5840250) - Find documents by fullname.
create index MDS_PATHS_N4 on MDS_PATHS_T( PATH_FULLNAME, PATH_HIGH_CN, ENTERPRISE_ID, PATH_PARTITION_ID )
;

REM #(5998529) - Find documents by GUID
create index MDS_PATHS_N5 on MDS_PATHS_T( PATH_PARTITION_ID, ENTERPRISE_ID, PATH_TYPE, PATH_GUID, PATH_HIGH_CN, PATH_LINEAGE_ID )
;

REM #(6357992) - Get changes between two labels during commit processing
REM PATH_PARTITION_ID is first since otherwise the query picks up MDS_PATHS_N5
REM and adding a INDEX hint also does not help avoid it.
create INDEX MDS_PATHS_N6 on MDS_PATHS_T 
	( PATH_PARTITION_ID, PATH_LOW_CN, PATH_HIGH_CN, PATH_OPERATION, PATH_TYPE )
;

REM index to improve snapshot read performance.
REM Find documents by fullname, low_cn and high_cn
create index MDS_PATHS_N7 on MDS_PATHS_T
	( PATH_FULLNAME, PATH_LOW_CN DESC, PATH_HIGH_CN, ENTERPRISE_ID, PATH_PARTITION_ID )
;


REM #(10360031) index for join from ATTRIBUTE or COMPONENT to PATH table.
create index MDS_PATHS_N8 on MDS_PATHS_T
        ( PATH_CONTENTID, PATH_PARTITION_ID )
;

REM #(12859728) index for MOType condition.
create index MDS_PATHS_N9 on MDS_PATHS_T
        ( PATH_DOC_ELEM_NAME, PATH_PARTITION_ID )
;

REM #(6838583) - Indexes for purge
create index MDS_PURGE_PATHS_N1 on MDS_PURGE_PATHS_T
  ( PPATH_CONTENTID, PPATH_PARTITION_ID )
;

create index MDS_PURGE_PATHS_N2 on MDS_PURGE_PATHS_T
  ( PPATH_LOW_CN, PPATH_HIGH_CN, PPATH_PARTITION_ID )
;

REM drop index MDS_SD_U1;
create unique index MDS_SD_U1
on MDS_STREAMED_DOCS_T( SD_CONTENTID, SD_PARTITION_ID )
;

REM drop index MDS_MD_U1;
create unique index MDS_MD_U1
on MDS_METADATA_DOCS_T( MD_CONTENTID, MD_PARTITION_ID )
;

REM #(7442627) Partitions should be unique by name
REM drop index MDS_PARTITIONS_U1;
create unique index MDS_PARTITIONS_U1
on MDS_PARTITIONS_T( PARTITION_NAME )
;

REM Retrieve XML elements in document order
REM drop index MDS_COMPONENTS_U1;
REM #(7199149) partitionID at the end results in SKIP_SCAN when 
REM multiple partitions exist. 
create unique index MDS_COMPONENTS_U1
on MDS_COMPONENTS_T ( COMP_CONTENTID, COMP_PARTITION_ID, COMP_SEQ )
;

REM Find element by type
REM drop index MDS_COMPONENTS_N1; 
create index MDS_COMPONENTS_N1
on MDS_COMPONENTS_T ( COMP_LOCALNAME, COMP_CONTENTID, COMP_PARTITION_ID, ENTERPRISE_ID, COMP_NSID, COMP_SEQ, COMP_ID )
;

REM Find element by id 
REM drop index MDS_COMPONENTS_N2;
create index MDS_COMPONENTS_N2
on MDS_COMPONENTS_T ( COMP_ID, COMP_CONTENTID )
;

REM Put most disciminating COLUMN first (assumes we will be selecting attributes
REM on a per component basis, not for whole document)
REM drop index MDS_ATTRIBUTES_U1;
REM #(7199149) partitionID at the end results in SKIP_SCAN when 
REM multiple partitions exist. 
create unique index MDS_ATTRIBUTES_U1
on MDS_ATTRIBUTES_T( ATT_CONTENTID, ATT_COMP_SEQ, ATT_PARTITION_ID, ATT_SEQ )
;

REM Find attribute by name
REM drop index MDS_ATTRIBUTES_U2; 
create unique index MDS_ATTRIBUTES_U2 on MDS_ATTRIBUTES_T ( ATT_LOCALNAME, ATT_CONTENTID, ATT_PARTITION_ID, ATT_COMP_SEQ, ATT_NSID )
; 

REM Find references to a document or subobject, more indexes will be 
REM added after performance testing
REM #(5840250) reordered.
REM drop index MDS_DEPENDENCIES_N1;
create index MDS_DEPENDENCIES_N1
on MDS_DEPENDENCIES_T ( DEP_PARENT_DOCNAME, DEP_PARENT_LOCALREF, DEP_HIGH_CN, DEP_PARTITION_ID, ENTERPRISE_ID, DEP_TOCHILD_ROLE )
;


REM #(5690942) - Find dependencies by lowCN
REM drop index MDS_DEPENDENCIES_N2; 
create index MDS_DEPENDENCIES_N2 
on MDS_DEPENDENCIES_T( DEP_LOW_CN, DEP_PARTITION_ID )
;

REM #(5690942) - Find dependencies by highCN
REM drop index MDS_DEPENDENCIES_N3; 
create index MDS_DEPENDENCIES_N3
on MDS_DEPENDENCIES_T( DEP_HIGH_CN, DEP_PARTITION_ID )
;

REM #(5840250) - Find dependencies by DOCID
create index MDS_DEPENDENCIES_N4
on MDS_DEPENDENCIES_T( DEP_CHILD_DOCID, DEP_CHILD_LOCALREF, DEP_HIGH_CN,
DEP_PARTITION_ID )
;


REM For help lookup namespace by id or join to MDS_NAMESPACES table .
REM drop index MDS_NAMESPACES_U1;
create unique index MDS_NAMESPACES_U1
on MDS_NAMESPACES_T ( NS_ID, NS_PARTITION_ID )
;

REM Find labels by name. This also enforces unique label names in a given partition.
REM drop index MDS_LABELS_U1;
create unique index MDS_LABELS_U1
on MDS_LABELS_T ( LABEL_PARTITION_ID, ENTERPRISE_ID, LABEL_NAME )
;


REM #(5690942) - Find labels by CN
REM drop index MDS_LABELS_N1; 
create index MDS_LABELS_N1 on MDS_LABELS_T( LABEL_CN, LABEL_PARTITION_ID )
;

REM #(5862363) - Ensure one lock row per partition. This also helps
REM avoid full table scan when generating new commit number
REM drop index MDS_TXN_LOCKS_U1;
create unique index MDS_TXN_LOCKS_U1
on MDS_TXN_LOCKS_T ( LOCK_PARTITION_ID )
;

REM drop index MDS_TRANSACTIONS_U1;
create unique index MDS_TRANSACTIONS_U1
on MDS_TRANSACTIONS_T ( TXN_PARTITION_ID, TXN_CN )
;

REM This enforces unique sandbox names in a partition.
REM drop index MDS_SANDBOXES_UK;
create unique index MDS_SANDBOXES_UK
on MDS_SANDBOXES_T ( SB_PARTITION_ID, ENTERPRISE_ID, SB_NAME )
;

REM Create required indices
REM Find documents by id
REM drop index MDS_XDB_DOCUMENTS_U1;
REM create unique index MDS_XDB_DOCUMENTS_U1
REM on MDS_XDB_DOCUMENTS( XD_CONTENTID, XD_PARTITION_ID )
REM ;

REM Find configured ids by docid and sequence.
REM drop index MDS_XDB_COMPS_U1;
REM create unique index MDS_XDB_COMPS_U1
REM on MDS_XDB_COMPS( COMP_CONTENTID, COMP_SEQ, COMP_PARTITION_ID )
REM ;


REM Put most disciminating COLUMN first (assumes we will be selecting attributes
REM on a per component basis, not for whole document)
REM drop index MDS_LARGE_ATTRIBUTES_U1;
create unique index MDS_LARGE_ATTRIBUTES_U1
on MDS_LARGE_ATTRIBUTES_T( ATT_CONTENTID, ATT_COMP_SEQ, ATT_PARTITION_ID, ATT_SEQ )
;

REM Find attribute by name
REM drop index MDS_LARGE_ATTRIBUTES_N1;
create index MDS_LARGE_ATTRIBUTES_N1
on MDS_LARGE_ATTRIBUTES_T ( ATT_LOCALNAME, ATT_CONTENTID, ATT_PARTITION_ID)
; 


REM Unique constraints
create unique index MDS_DEPL_LINEAGE_U1 
on MDS_DEPL_LINEAGES_T ( DL_LINEAGE_ID, ENTERPRISE_ID, DL_PARTITION_ID )
;

create unique index MDS_DEPL_LINEAGE_U2 
on MDS_DEPL_LINEAGES_T ( DL_APPNAME, DL_DEPL_MODULE_NAME, ENTERPRISE_ID, DL_PARTITION_ID )
;

COMMIT;
