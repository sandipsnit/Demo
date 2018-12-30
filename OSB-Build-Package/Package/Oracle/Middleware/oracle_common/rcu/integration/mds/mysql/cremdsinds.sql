-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- CREMDSINDS.SQL - Create MDS Index for SQL Server.
-- 
-- MODIFIED    (MM/DD/YY)
-- pwhaley      02/24/12   - XbranchMerge pwhaley_bug-12859728 from main
-- pwhaley      02/15/12   - #(12859728) Added MDS_PATHS_N9 MOtype index
-- jhsi         10/11/11   - Added unique index MDS_MD_U1
-- erwang       06/22/11   - #(12600604) modify indexes for index size limitation
-- erwang       06/08/11   - XbranchMerge erwang_bug-10360031 from main
-- erwang       04/19/11   - #(10360031) added MDS_PATHS_N8
-- erwang       04/19/11   - Added MDS_PATHS_N7 to be used by lockDocument
-- erwang       03/22/11   - Change delimiter to /
-- erwang       01/10/11   - Creation
--

-- Find documents by id 
-- #(5840250) reorder to put version last.
create unique  index MDS_PATHS_U1
    on MDS_PATHS( PATH_DOCID, PATH_PARTITION_ID, PATH_VERSION )
/

-- Find documents by owner 
create unique index MDS_PATHS_U2
    on MDS_PATHS( PATH_OWNER_DOCID, PATH_NAME, PATH_VERSION, PATH_PARTITION_ID, PATH_GUID)
/

-- Find documents by documentname or guid. This is a critical index to
-- ensure /od performance for getDocument()
-- #(5998529) Include PATH_TYPE to improve query performance.
create unique index MDS_PATHS_U3
    on MDS_PATHS( PATH_FULLNAME, PATH_VERSION, PATH_PARTITION_ID, PATH_GUID )
/

-- Find documents by name 
create index MDS_PATHS_N1
    on MDS_PATHS( PATH_NAME, PATH_PARTITION_ID)
/


-- #(5690942) - Find documents by lowCN, this is required improving performance
-- of replacing -1 with actual commit number in processCommit()
create index MDS_PATHS_N2 
    on MDS_PATHS( PATH_LOW_CN, PATH_PARTITION_ID )
/


-- #(5690942) - Find documents by highCN
create index MDS_PATHS_N3 
    on MDS_PATHS( PATH_HIGH_CN, PATH_PARTITION_ID )
/


-- #(5840250) - Find documents by fullname.
create index MDS_PATHS_N4 
    on MDS_PATHS( PATH_FULLNAME, PATH_HIGH_CN, PATH_PARTITION_ID)
/


-- #(5998529) - Find documents by guid
create index MDS_PATHS_N5 
    on MDS_PATHS( PATH_PARTITION_ID, PATH_TYPE, PATH_GUID, PATH_HIGH_CN, PATH_LINEAGE_ID )
/


-- #(6357992) - Get changes between two labels during commit processing
-- PATH_PARTITION_ID is first since otherwise the query picks up MDS_PATHS_N5
-- and adding a INDEX hint also does not help avoid it.
create INDEX MDS_PATHS_N6 
  on MDS_PATHS ( PATH_PARTITION_ID, PATH_LOW_CN, PATH_HIGH_CN, PATH_OPERATION, PATH_TYPE )
/

-- Added to be used by lockDocument
CREATE INDEX MDS_PATHS_N7
    ON MDS_PATHS (PATH_DOCID,PATH_PARTITION_ID,PATH_HIGH_CN)
/

-- #(10360031) - Added to help join from ATTR or COMP table to PATH table.
create INDEX MDS_PATHS_N8 
  on MDS_PATHS ( PATH_CONTENTID, PATH_PARTITION_ID )
/

-- #(12859728) Add MOType index for query.
create INDEX MDS_PATHS_N9
  on MDS_PATHS ( PATH_DOC_ELEM_NAME, PATH_PARTITION_ID )
/

-- #(6838583) Optimize purge 
create index MDS_PURGE_PATHS_N1
    on MDS_PURGE_PATHS( PPATH_CONTENTID, PPATH_PARTITION_ID )
/

create index MDS_PURGE_PATHS_N2
    on MDS_PURGE_PATHS( PPATH_LOW_CN, PPATH_HIGH_CN, PPATH_PARTITION_ID )
/


-- Find streamed docs by contentid.
create unique  index MDS_SD_U1
    on MDS_STREAMED_DOCS( SD_CONTENTID, SD_PARTITION_ID )
/


-- Find unshredded docs by contentid.
create unique  index MDS_MD_U1
    on MDS_METADATA_DOCS( MD_CONTENTID, MD_PARTITION_ID )
/


-- Retrieve XML elements in document order
-- #(7199149EM #(7199149) partitionID at the end results in SKIP_SCAN when
-- multiple partitions exist.
create unique index MDS_COMPONENTS_U1
    on MDS_COMPONENTS( COMP_CONTENTID, COMP_PARTITION_ID, COMP_SEQ )
/


-- Find element by type 
create index MDS_COMPONENTS_N1
    on MDS_COMPONENTS ( COMP_LOCALNAME, COMP_CONTENTID, COMP_PARTITION_ID, COMP_NSID, COMP_SEQ, COMP_ID)
/

-- Rem Find element by id 
create index MDS_COMPONENTS_N2
    on MDS_COMPONENTS ( COMP_ID, COMP_CONTENTID )
/

-- Put most disciminating column first (assumes we'll be selecting attributes
-- on a per component basis, not for whole document)
--
-- #(7199149) partitionID at the end results in SKIP_SCAN when
-- multiple partitions exist.
create unique  index MDS_ATTRIBUTES_U1
    on MDS_ATTRIBUTES ( ATT_CONTENTID, ATT_COMP_SEQ, ATT_PARTITION_ID, ATT_SEQ )
/

-- Find attribute by name 
create unique index MDS_ATTRIBUTES_U2
    on MDS_ATTRIBUTES ( ATT_LOCALNAME, ATT_CONTENTID, ATT_PARTITION_ID, ATT_COMP_SEQ, ATT_NSID)
/


-- Find references to a document or subobject, more indexes will be 
-- added after performance testing
--
-- SQL Server Index has maximum size of 768 characters.
-- #(5981139) remove DEP_TOCHILD_ROLE from the index
create index MDS_DEPENDENCIES_N1 
    on MDS_DEPENDENCIES (DEP_PARENT_DOCNAME, 
       DEP_HIGH_CN, DEP_PARTITION_ID,
       DEP_PARENT_LOCALREF)
/


-- #(5690942) - Find dependencies by lowCN
create index MDS_DEPENDENCIES_N2 
        on MDS_DEPENDENCIES( DEP_LOW_CN, DEP_PARTITION_ID )
/


-- #(5690942) - Find dependencies by highCN
create index MDS_DEPENDENCIES_N3 
        on MDS_DEPENDENCIES( DEP_HIGH_CN, DEP_PARTITION_ID )
/


-- #(5840250) - Find dependencies by child.
create index MDS_DEPENDENCIES_N4 
        on MDS_DEPENDENCIES( DEP_CHILD_DOCID, DEP_CHILD_LOCALREF,
           DEP_HIGH_CN, DEP_PARTITION_ID )
/

-- Find name by id and join to NS table by id.
create unique index MDS_NAMESPACES_U1
    on MDS_NAMESPACES (NS_ID, NS_PARTITION_ID )
/

-- Find labels by name. This also enforces unique label names in a given partition.
create unique  index MDS_LABELS_U1
    on MDS_LABELS ( LABEL_PARTITION_ID, LABEL_NAME )
/


-- #(5690942) - Find labels by partition id and cn. 
-- This is also needed for acquiring proper row level lock
-- #(9151698) Make the index as non-unique.
create index MDS_LABELS_N1
    on MDS_LABELS ( LABEL_CN, LABEL_PARTITION_ID)
/

-- This is Unique index is for MDS_TRANSACTIONS.
create unique  index MDS_TRANSACTIONS_U1
   on MDS_TRANSACTIONS ( TXN_PARTITION_ID, TXN_CN )
/

-- Indexes for MDS_DEPL_LINEAGES table
create unique index MDS_DEPL_LINEAGES_U1
   on MDS_DEPL_LINEAGES ( DL_LINEAGE_ID, DL_PARTITION_ID )
/

create unique index MDS_DEPL_LINEAGES_U2
   on MDS_DEPL_LINEAGES ( DL_APPNAME, DL_DEPL_MODULE_NAME, DL_PARTITION_ID )
/   

-- This enforces unique sandbox names in a partition. 
create unique  index MDS_SANDBOXES_UK
  on MDS_SANDBOXES ( SB_PARTITION_ID, SB_NAME )
/

-- This enforces unique partition id in MDS_TXN_LOCKS.
-- SQL server relys on index and key for row level locking. 
-- #(5862363) - This is also required to avoid full table scan 
-- when generating new commit number
create unique  index MDS_TXN_LOCKS_UK
  on MDS_TXN_LOCKS ( LOCK_PARTITION_ID )
/

-- This enforces unique partition id in MDS_PARTITIONS.
-- SQL server relys on index and key for row level locking. 
create unique  index MDS_PARTITIONS_UK
  on MDS_PARTITIONS ( PARTITION_ID )
/


-- #(7442627) Enforce unique partition name in MDS_PARTITIONS.
create unique index MDS_PARTITIONS_U2
  on MDS_PARTITIONS ( PARTITION_NAME )
/

