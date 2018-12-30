-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- CREMDSINDS.SQL - Create MDS Index for SQL Server.
-- 
-- MODIFIED    (MM/DD/YY)
-- pwhaley      02/24/12   - XbranchMerge pwhaley_bug-12859728 from main
-- pwhaley      02/15/12   - #(12859728) Added MDS_PATHS_N9 MOtype index
-- dibhatta     02/10/12   - #(13642709) Changed index N7 to N8 
--                           to sync with PS5 for upgrade
-- jhsi         10/10/11   - Added unique index MDS_MD_U1
-- erwang       06/08/11   - XbranchMerge erwang_bug-10360031 from main
-- erwang       04/19/11   - #(10360031) added MDS_PATHS_N8 to help NL join to PATH
-- gnagaraj     12/22/09   - #(9151698) Change MDS_LABELS_U2 to non-unique
-- gnagaraj     12/22/09   - Consolidate dropindex in dropmdsinds.sql
-- gnagaraj     12/08/09   - Index changes for deployment support
-- erwang       03/20/09   - #(8352261) Remove DEP_PARENT_LOCALREF from 
--                           MDS_DEPENDENCIES_N1 since SQL Server has a
--                           maximum size of 900 bytes.
-- erwang       02/06/09   - Update MDS_PATHS_N1, MDS_ATTRIBUTES_N1 AND
--                           MDS_COMPONENTS_N1 for performance reason
-- erwang       12/18/08   - #(7650199) Remove MDS_SEQUENCES_UK.
-- gnagaraj     10/08/08   - #(7442627) Add unique index on partition_name
-- gnagaraj     07/08/08   - #(7199149) Adjust partitionID for multi partition
--                           read/write perf
-- gnagaraj     03/17/08   - #(6838583) Add indexes for mds_purge_paths
-- gnagaraj     10/22/07   - #(6508932) Remove MDS_ATTRIBUTES_TRANS table
-- gnagaraj     08/22/07   - #(6357992) Add new index to optimize getChanges() query
-- erwang       04/17/07   - Take out DEP_TOCHILD_ROLE from
--                           MDS_DEPENDENCIES_N1
-- erwang       04/16/07   - #(5998529) Add MDS_PATHS_N5 etc.
-- pwhaley      02/19/07   - #(5840250) Adjust for finding dependencies.
-- erwang       02/14/07   - RCU support.
-- gnagaraj     02/05/07   - #(5862363) Add PATH_GUID to MDS_PATHS_U2
-- erwang       12/27/06   - Globalization Support
-- erwang       12/05/06   - Added MDS_PARTHTIONS_UK, etc.
-- gnagaraj     12/11/06   - #(5690942) Define indexes with lowCN&highCN for
--                           improving transaction performance.
-- erwang       11/21/06   - Apply changes: removed path_high_cn from
--                           MDS_PATH_U2, MDS_PATH_U3
-- erwang       09/07/06   - Creation
--


go
set nocount on
-- begin transaction cremdsinds
go


-- Find documents by id 
-- #(5840250) reorder to put version last.
create unique clustered index MDS_PATHS_U1
    on MDS_PATHS( PATH_DOCID, PATH_PARTITION_ID, PATH_VERSION )
go



-- Find documents by owner 
create unique index MDS_PATHS_U2
    on MDS_PATHS( PATH_OWNER_DOCID, PATH_NAME, PATH_VERSION, PATH_PARTITION_ID, PATH_GUID)
go

-- Find documents by documentname or guid. This is a critical index to
-- ensure good performance for getDocument()
-- #(5998529) Include PATH_TYPE to improve query performance.
create unique index MDS_PATHS_U3
    on MDS_PATHS( PATH_FULLNAME, PATH_VERSION, PATH_PARTITION_ID, PATH_GUID )
    include (PATH_TYPE)
go

-- Find documents by name 
create index MDS_PATHS_N1
    on MDS_PATHS( PATH_NAME, PATH_PARTITION_ID)
go


-- #(5690942) - Find documents by lowCN, this is required improving performance
-- of replacing -1 with actual commit number in processCommit()
create index MDS_PATHS_N2 
    on MDS_PATHS( PATH_LOW_CN, PATH_PARTITION_ID )
go


-- #(5690942) - Find documents by highCN
create index MDS_PATHS_N3 
    on MDS_PATHS( PATH_HIGH_CN, PATH_PARTITION_ID )
go


-- #(5840250) - Find documents by fullname.
create index MDS_PATHS_N4 
    on MDS_PATHS( PATH_FULLNAME, PATH_HIGH_CN, PATH_PARTITION_ID, PATH_TYPE, PATH_CONTENTID )
     INCLUDE(PATH_DOC_ELEM_NSURI, PATH_DOC_ELEM_NAME, PATH_GUID)
go


-- #(5998529) - Find documents by guid
create index MDS_PATHS_N5 
    on MDS_PATHS( PATH_PARTITION_ID, PATH_TYPE, PATH_GUID, PATH_HIGH_CN, PATH_LINEAGE_ID )
go


-- #(6357992) - Get changes between two labels during commit processing
-- PATH_PARTITION_ID is first since otherwise the query picks up MDS_PATHS_N5
-- and adding a INDEX hint also does not help avoid it.
create INDEX MDS_PATHS_N6 
  on MDS_PATHS ( PATH_PARTITION_ID, PATH_LOW_CN, PATH_HIGH_CN, PATH_OPERATION, PATH_TYPE )
go


-- #(10360031) Added to help join from COMP and ATTR tables to PATH
create INDEX MDS_PATHS_N8 
  on MDS_PATHS ( PATH_CONTENTID, PATH_PARTITION_ID )
go


-- #(12859728) Add MOType index for query.
create INDEX MDS_PATHS_N9
  on MDS_PATHS ( PATH_DOC_ELEM_NAME, PATH_PARTITION_ID )
go


-- #(6838583) Optimize purge 
create index MDS_PURGE_PATHS_N1
    on MDS_PURGE_PATHS( PPATH_CONTENTID, PPATH_PARTITION_ID )
go

create index MDS_PURGE_PATHS_N2
    on MDS_PURGE_PATHS( PPATH_LOW_CN, PPATH_HIGH_CN, PPATH_PARTITION_ID )
go


-- Find streamed docs by contentid.
create unique clustered index MDS_SD_U1
    on MDS_STREAMED_DOCS( SD_CONTENTID, SD_PARTITION_ID )
go


-- Find unshredded docs by contentid.
create unique clustered index MDS_MD_U1
    on MDS_METADATA_DOCS( MD_CONTENTID, MD_PARTITION_ID )
go


-- Retrieve XML elements in document order
-- #(7199149EM #(7199149) partitionID at the end results in SKIP_SCAN when
-- multiple partitions exist.
create unique clustered index MDS_COMPONENTS_U1
    on MDS_COMPONENTS( COMP_CONTENTID, COMP_PARTITION_ID, COMP_SEQ )
go


-- Find element by type 
create index MDS_COMPONENTS_N1
    on MDS_COMPONENTS ( COMP_LOCALNAME, COMP_CONTENTID, COMP_PARTITION_ID, COMP_NSID) INCLUDE(COMP_SEQ, COMP_ID)
go

-- Rem Find element by id 
create index MDS_COMPONENTS_N2
    on MDS_COMPONENTS ( COMP_ID, COMP_CONTENTID )
go

-- Put most disciminating column first (assumes we'll be selecting attributes
-- on a per component basis, not for whole document)
--
-- #(7199149) partitionID at the end results in SKIP_SCAN when
-- multiple partitions exist.
create unique clustered index MDS_ATTRIBUTES_U1
    on MDS_ATTRIBUTES ( ATT_CONTENTID, ATT_COMP_SEQ, ATT_PARTITION_ID, ATT_SEQ )
go

-- Find attribute by name 
create unique index MDS_ATTRIBUTES_U2
    on MDS_ATTRIBUTES ( ATT_LOCALNAME, ATT_CONTENTID, ATT_PARTITION_ID, ATT_COMP_SEQ, ATT_NSID)
go


-- Find references to a document or subobject, more indexes will be 
-- added after performance testing
-- #(5840250) Reorder to put role last, include high_cn.
--
-- SQL Server Index has maximum size of 900 char.
-- #(5981139) remove DEP_TOCHILD_ROLE from the index
-- #(8352261) Change DEP_PARENT_LOCALREF to INCLUDE
create index MDS_DEPENDENCIES_N1 
    on MDS_DEPENDENCIES (DEP_PARENT_DOCNAME, 
       DEP_HIGH_CN, DEP_PARTITION_ID)
       INCLUDE(DEP_PARENT_LOCALREF, DEP_TOCHILD_ROLE)
go


-- #(5690942) - Find dependencies by lowCN
create index MDS_DEPENDENCIES_N2 
        on MDS_DEPENDENCIES( DEP_LOW_CN, DEP_PARTITION_ID )
go


-- #(5690942) - Find dependencies by highCN
create index MDS_DEPENDENCIES_N3 
        on MDS_DEPENDENCIES( DEP_HIGH_CN, DEP_PARTITION_ID )
go


-- #(5840250) - Find dependencies by child.
create index MDS_DEPENDENCIES_N4 
        on MDS_DEPENDENCIES( DEP_CHILD_DOCID, DEP_CHILD_LOCALREF,
           DEP_HIGH_CN, DEP_PARTITION_ID )
go

-- Find name by id and join to NS table by id.
create unique clustered index MDS_NAMESPACES_U1
    on MDS_NAMESPACES (NS_ID, NS_PARTITION_ID )
go

-- Find labels by name. This also enforces unique label names in a given partition.
create unique clustered index MDS_LABELS_U1
    on MDS_LABELS ( LABEL_PARTITION_ID, LABEL_NAME )
go


-- #(5690942) - Find labels by partition id and cn. 
-- This is also needed for acquiring proper row level lock
-- #(9151698) Make the index as non-unique.
create index MDS_LABELS_N1
    on MDS_LABELS ( LABEL_CN, LABEL_PARTITION_ID)
go

-- This is Unique index is for MDS_TRANSACTIONS.
create unique clustered index MDS_TRANSACTIONS_U1
   on MDS_TRANSACTIONS ( TXN_PARTITION_ID, TXN_CN )
go

-- Indexes for MDS_DEPL_LINEAGES table
create unique index MDS_DEPL_LINEAGES_U1
   on MDS_DEPL_LINEAGES ( DL_LINEAGE_ID, DL_PARTITION_ID )
go

create unique clustered index MDS_DEPL_LINEAGES_U2
   on MDS_DEPL_LINEAGES ( DL_APPNAME, DL_DEPL_MODULE_NAME, DL_PARTITION_ID )
go   

-- This enforces unique sandbox names in a partition. 
create unique clustered index MDS_SANDBOXES_UK
  on MDS_SANDBOXES ( SB_PARTITION_ID, SB_NAME )
go

-- This enforces unique partition id in MDS_TXN_LOCKS.
-- SQL server relys on index and key for row level locking. 
-- #(5862363) - This is also required to avoid full table scan 
-- when generating new commit number
create unique clustered index MDS_TXN_LOCKS_UK
  on MDS_TXN_LOCKS ( LOCK_PARTITION_ID )
go

-- This enforces unique partition id in MDS_PARTITIONS.
-- SQL server relys on index and key for row level locking. 
create unique clustered index MDS_PARTITIONS_UK
  on MDS_PARTITIONS ( PARTITION_ID )
go


-- #(7442627) Enforce unique partition name in MDS_PARTITIONS.
create unique index MDS_PARTITIONS_U2
  on MDS_PARTITIONS ( PARTITION_NAME )
go

-- commit transaction cremdsinds
go


