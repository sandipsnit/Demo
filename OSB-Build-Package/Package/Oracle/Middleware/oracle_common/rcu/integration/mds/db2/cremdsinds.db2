-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- CREMDSINDS.DB2 - CREate MDS INDexeS
-- 
-- MODIFIED    (MM/DD/YY)
-- pwhaley      02/24/12   - XbranchMerge pwhaley_bug-12859728 from main
-- pwhaley      02/15/12   - #(12859728) Added MDS_PATHS_N9 MOtype index
-- jhsi         10/11/11   - Added unique index MDS_MD_U1
-- erwang       06/08/11   - XbranchMerge erwang_bug-10360031 from main
-- erwang       04/19/11   - #(10360031) added MDS_PATHS_N8
-- erwang       03/26/10   - Change back MDS_ATTRIBUTES_U1
-- gnagaraj     12/08/09   - Index changes for deployment support.
-- erwang       03/08/10   - Move partition id to 2nd position in
--                           MDS_ATTRIBUTES_U1 to avoid table lock in
--                           purgeMetadata()
-- erwang       01/19/10   - Added MDS_PATHS_N7 and MDS_DEPENDENCIES_U1
-- erwang       09/09/09   - Comment out the commit at the end
-- erwang       08/17/09   - Change variable substitution syntax
-- erwang       07/15/09   - Create 
--

-- Find documents by id
-- #(5840250) Reorder so version is last.
-- drop index MDS_PATHS_U1;


CREATE UNIQUE INDEX MDS_PATHS_U1
    ON MDS_PATHS(PATH_DOCID,PATH_PARTITION_ID,PATH_VERSION)
@

-- Find documents by owner
-- drop index MDS_PATHS_U2;

CREATE UNIQUE INDEX MDS_PATHS_U2
    ON MDS_PATHS(PATH_OWNER_DOCID,PATH_NAME,PATH_VERSION,PATH_PARTITION_ID,PATH_GUID)
@

-- Find documents by documentname or guid. This is a critical index to
-- ensure good performance for getDocument()
-- drop index MDS_PATHS_U3;

CREATE UNIQUE INDEX MDS_PATHS_U3
    ON MDS_PATHS(PATH_FULLNAME,PATH_VERSION,PATH_PARTITION_ID,PATH_GUID)
@

-- Find documents by name
-- drop index MDS_PATHS_N1; 

CREATE INDEX MDS_PATHS_N1
    ON MDS_PATHS(PATH_NAME,PATH_PARTITION_ID,PATH_TYPE,PATH_CONTENTID)
@

-- #(5690942) - Find documents by lowCN, this is required improving performance
-- of replacing -1 with actual commit number in processCommit()
-- drop index MDS_PATHS_N2; 

CREATE INDEX MDS_PATHS_N2
    ON MDS_PATHS(PATH_LOW_CN,PATH_PARTITION_ID)
@

-- #(5690942) - Find documents by highCN
-- drop index MDS_PATHS_N3; 

CREATE INDEX MDS_PATHS_N3
    ON MDS_PATHS(PATH_HIGH_CN,PATH_PARTITION_ID)
@

-- #(5840250) - Find documents by fullname.

CREATE INDEX MDS_PATHS_N4
    ON MDS_PATHS(PATH_FULLNAME,PATH_HIGH_CN,PATH_PARTITION_ID)
@

-- #(5998529) - Find documents by GUID

CREATE INDEX MDS_PATHS_N5
    ON MDS_PATHS(PATH_PARTITION_ID,PATH_TYPE,PATH_GUID,PATH_HIGH_CN,PATH_LINEAGE_ID)
@

-- #(6357992) - Get changes between two labels during commit processing
-- PATH_PARTITION_ID is first since otherwise the query picks up MDS_PATHS_N5
-- and adding a INDEX hint also does not help avoid it.

CREATE INDEX MDS_PATHS_N6
    ON MDS_PATHS(PATH_PARTITION_ID,PATH_LOW_CN,PATH_HIGH_CN,PATH_OPERATION,PATH_TYPE)
@

-- Added to be used by lockDocument
CREATE INDEX MDS_PATHS_N7
    ON MDS_PATHS(PATH_DOCID,PATH_PARTITION_ID,PATH_HIGH_CN)
@

-- #(10360031) Added to help join from ATTR, COMP tables to PATH table
CREATE INDEX MDS_PATHS_N8
    ON MDS_PATHS(PATH_CONTENTID, PATH_PARTITION_ID)
@

-- #(12859728) Index on root element name for MOType condition.
CREATE INDEX MDS_PATHS_N9
    ON MDS_PATHS(PATH_DOC_ELEM_NAME, PATH_PARTITION_ID)
@

-- #(6838583) - Indexes for purge

--CREATE INDEX MDS_PURGE_PATHS_N1
--    ON MDS_PURGE_PATHS(PPATH_CONTENTID,PPATH_PARTITION_ID)


--CREATE INDEX MDS_PURGE_PATHS_N2
--    ON MDS_PURGE_PATHS(PPATH_LOW_CN,PPATH_HIGH_CN,PPATH_PARTITION_ID)

-- drop index MDS_SD_U1;

CREATE UNIQUE INDEX MDS_SD_U1
    ON MDS_STREAMED_DOCS(SD_CONTENTID,SD_PARTITION_ID)
@

CREATE UNIQUE INDEX MDS_MD_U1
    ON MDS_METADATA_DOCS(MD_CONTENTID,MD_PARTITION_ID)
@

-- #(7442627) Partitions should be unique by name
-- drop index MDS_PARTITIONS_U1;

CREATE UNIQUE INDEX MDS_PARTITIONS_U1
    ON MDS_PARTITIONS(PARTITION_NAME)
@

-- Retrieve XML elements in document order
-- drop index MDS_COMPONENTS_U1;
-- #(7199149) partitionID at the end results in SKIP_SCAN when 
-- multiple partitions exist. 

CREATE UNIQUE INDEX MDS_COMPONENTS_U1
    ON MDS_COMPONENTS(COMP_CONTENTID,COMP_PARTITION_ID,COMP_SEQ)
@

-- Find element by type
-- drop index MDS_COMPONENTS_N1; 

CREATE INDEX MDS_COMPONENTS_N1
    ON MDS_COMPONENTS(COMP_LOCALNAME,COMP_CONTENTID,COMP_PARTITION_ID,COMP_NSID,COMP_SEQ,COMP_ID)
@

-- Find element by id 
-- drop index MDS_COMPONENTS_N2;

CREATE INDEX MDS_COMPONENTS_N2
    ON MDS_COMPONENTS(COMP_ID,COMP_CONTENTID)
@

-- Put most disciminating COLUMN first (assumes we will be selecting attributes
-- on a per component basis, not for whole document)
-- drop index MDS_ATTRIBUTES_U1;
-- #(7199149) partitionID at the end results in SKIP_SCAN when 
-- multiple partitions exist. 

CREATE UNIQUE INDEX MDS_ATTRIBUTES_U1
    ON MDS_ATTRIBUTES(ATT_CONTENTID,ATT_COMP_SEQ,ATT_PARTITION_ID,ATT_SEQ)
@

-- Find attribute by name
-- drop index MDS_ATTRIBUTES_U2; 

CREATE UNIQUE INDEX MDS_ATTRIBUTES_U2
    ON MDS_ATTRIBUTES(ATT_LOCALNAME,ATT_CONTENTID,ATT_PARTITION_ID,ATT_COMP_SEQ,ATT_NSID)
@

-- Find references to a document or subobject, more indexes will be 
-- added after performance testing
-- #(5840250) reordered.
-- drop index MDS_DEPENDENCIES_1;

CREATE INDEX MDS_DEPENDENCIES_1
    ON MDS_DEPENDENCIES(DEP_PARENT_DOCNAME,DEP_PARENT_LOCALREF,DEP_HIGH_CN,DEP_PARTITION_ID,DEP_TOCHILD_ROLE)
@

-- #(5690942) - Find dependencies by lowCN
-- drop index MDS_DEPENDENCIES_2; 

CREATE INDEX MDS_DEPENDENCIES_2
    ON MDS_DEPENDENCIES(DEP_LOW_CN,DEP_PARTITION_ID)
@

-- #(5690942) - Find dependencies by highCN
-- drop index MDS_DEPENDENCIES_3; 

CREATE INDEX MDS_DEPENDENCIES_3
    ON MDS_DEPENDENCIES(DEP_HIGH_CN,DEP_PARTITION_ID)
@

-- #(5840250) - Find dependencies by DOCID

CREATE INDEX MDS_DEPENDENCIES_4
    ON MDS_DEPENDENCIES(DEP_CHILD_DOCID,DEP_CHILD_LOCALREF,DEP_HIGH_CN,DEP_PARTITION_ID)
@

-- For deleting row with a known DEP_ID.
CREATE UNIQUE INDEX MDS_DEPENDENCIES_U1
    ON MDS_DEPENDENCIES(DEP_ID)
@


-- For help lookup namespace by id or join to MDS_NAMESPACES table .
-- drop index MDS_NAMESPACES_U1;

CREATE UNIQUE INDEX MDS_NAMESPACES_U1
    ON MDS_NAMESPACES(NS_ID,NS_PARTITION_ID)
@

-- Find labels by name. This also enforces unique label names in a given partition.
-- drop index MDS_LABELS_U1;

CREATE UNIQUE INDEX MDS_LABELS_U1
    ON MDS_LABELS(LABEL_PARTITION_ID,LABEL_NAME)
@

-- #(5690942) - Find labels by CN
-- drop index MDS_LABELS_N1; 

CREATE INDEX MDS_LABELS_N1
    ON MDS_LABELS(LABEL_CN,LABEL_PARTITION_ID)
@

-- #(5862363) - Ensure one lock row per partition. This also helps
-- avoid full table scan when generating new commit number
-- drop index MDS_TXN_LOCKS_U1;

CREATE UNIQUE INDEX MDS_TXN_LOCKS_U1
    ON MDS_TXN_LOCKS(LOCK_PARTITION_ID)
@

-- drop index MDS_TRANSACTIONS_1;

CREATE UNIQUE INDEX MDS_TRANSACTIONS_1
    ON MDS_TRANSACTIONS(TXN_PARTITION_ID,TXN_CN)
@

-- This enforces unique sandbox names in a partition.
-- drop index MDS_SANDBOXES_UK;

CREATE UNIQUE INDEX MDS_SANDBOXES_UK
    ON MDS_SANDBOXES(SB_PARTITION_ID,SB_NAME)
@

-- Unique constraints
CREATE UNIQUE INDEX MDS_DEPL_LINEAGE_U1
ON MDS_DEPL_LINEAGES (DL_LINEAGE_ID,DL_PARTITION_ID)
@

CREATE UNIQUE INDEX MDS_DEPL_LINEAGE_U2
ON MDS_DEPL_LINEAGES (DL_APPNAME,DL_DEPL_MODULE_NAME,DL_PARTITION_ID)
@

-- Create required indices
-- Find documents by id
-- drop index MDS_XDB_DOCUMENTS_U1;
-- create unique index MDS_XDB_DOCUMENTS_U1
-- on MDS_XDB_DOCUMENTS( XD_CONTENTID, XD_PARTITION_ID )
-- ;
-- Find configured ids by docid and sequence.
-- drop index MDS_XDB_COMPS_U1;
-- create unique index MDS_XDB_COMPS_U1
-- on MDS_XDB_COMPS( COMP_CONTENTID, COMP_SEQ, COMP_PARTITION_ID )
-- ;
-- Put most disciminating COLUMN first (assumes we will be selecting attributes
-- on a per component basis, not for whole document)

--COMMIT
--@

