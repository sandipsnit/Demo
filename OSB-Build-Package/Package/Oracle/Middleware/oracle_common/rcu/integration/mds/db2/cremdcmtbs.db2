-- Copyright (c) 2009, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- CREMDCMTBS.DB2 - CREate MDs CoMmon repository TaBleS
-- 
-- MODIFIED    (MM/DD/YY)
--    jhsi      10/11/11 - Added MDS_METADATA_DOCS table and PATH_CONTENT_TYPE
--                         column
--    erwang    08/26/11 - Added PATH_DOC_MOTYPE_NSURI and PATH_DOC_MOTYPE_NAME
--                         to MDS_PATHS
--    erwang    12/30/09 - XbranchMerge erwang_bug-9152916 from main
--    gnagaraj  12/08/09 - Add depl_lineages table and lineage_id, checksum
--                         columns on paths table for deployment support
--    abhatt    03/17/10 - Add new column LABEL_TIME for MDS_LABELS table.
--    vyerrama  03/15/10 - Added created by and created on fields to sandbox
--                         table
--    erwang    12/02/09 - #(9152196) Remove connectionID and add DEP_ID 
--    gnagaraj  10/08/09 - XbranchMerge gnagaraj_colsize_changes_bug8859749
--                         from main
--    gnagaraj  10/08/09 - #(8859749) Increase dep localref col size
--    gnagaraj  10/07/08 - #(8859749) Increase dep localref col size
--    erwang    08/27/09 - Use $ for defined variable
--    erwang    08/24/09 - Change variable substitution syntax
--    vyerrama  08/21/09 - #(8774395) Reduced the size for sandbox name.
--    erwang    08/17/09 - Increase the size of creator and path_fullname
--    erwang    07/29/09 - Added connectionid to PATH, LABEL and DEP tables
--    erwang    07/16/09 - Change fullRef size to 800.
--    erwang    07/15/09 - Creation. 
--

-- Max. length for developer-defined component names (docName, packageName)
define name=512
@
-- Max. length for username
define username=240
@
-- Max. length for partitionName
define partitionName=200
@
-- Max. length for a local reference (reference to an object within the
-- context of its document)
-- #(8859749) Increase localRef column size from 127 to 800
define localRef=800
@
define depRoleName=127
@

-- Max. length of a full reference (e.g. /oracle/apps/HR/myRegion#myTextItem,
-- /oracle/apps/PO/myPage#myExtendingRegion#inheritedChild)
-- Maximum length is specified as 1800 so that in the worst case scenario 
-- {assuming all are multibyte characters which take up 3 bytes} atleast 266 
-- characters can be accomodated.
define fullRef=1800
@
define descr=800
@
-- Precision for character encoding for the XML to allow all
-- encodings listed at http://www.iana.org/assignments/character-sets
define encoding=60
@
-- Max length of Namespace URIs
define nsuri=800
@
-- Max length of element name
define localname=127
@

-- Max length of application and deploy module(MAR) name
define deplName=400
@

create table MDS_PARTITIONS (
  PARTITION_ID                  DECIMAL(31,0) NOT NULL,
  PARTITION_NAME                VARCHAR(200) NOT NULL,
  PARTITION_LAST_PURGE_TIME     TIMESTAMP
 )
$IN_TABLESPACE
@


create table MDS_PATHS (
  PATH_PARTITION_ID             DECIMAL(31,0) NOT NULL,
  PATH_NAME                     VARCHAR($name) NOT NULL,
  PATH_DOCID                    DECIMAL(31,0) NOT NULL,
  PATH_OWNER_DOCID              DECIMAL(31,0) NOT NULL,
  PATH_FULLNAME                 VARCHAR($fullRef) NOT NULL,  
  PATH_GUID                     VARCHAR(36),
  PATH_TYPE                     VARCHAR(30) NOT NULL,
  PATH_LOW_CN                   DECIMAL(31,0),
  PATH_HIGH_CN                  DECIMAL(31,0),  
  PATH_CONTENTID                DECIMAL(31,0),
  PATH_DOC_ELEM_NSURI           VARCHAR($nsuri),
  PATH_DOC_ELEM_NAME            VARCHAR($localname),  
  PATH_VERSION                  DECIMAL(31,0),
  PATH_VER_COMMENT              VARCHAR($descr),
  PATH_OPERATION                DECIMAL(31,0),
  PATH_XML_VERSION              VARCHAR(10),
  PATH_XML_ENCODING             VARCHAR($encoding),
  PATH_CONT_CHECKSUM            DECIMAL(31,0),
  PATH_LINEAGE_ID               DECIMAL(31,0),
  PATH_DOC_MOTYPE_NSURI         VARCHAR($nsuri),
  PATH_DOC_MOTYPE_NAME          VARCHAR($localname),
  PATH_CONTENT_TYPE             DECIMAL(31,0)
)
$IN_TABLESPACE
@


create table MDS_TRANSACTIONS (
  TXN_PARTITION_ID             DECIMAL(31,0) NOT NULL,
  TXN_CN                       DECIMAL(31,0) NOT NULL,
  TXN_CREATOR                  VARCHAR($username),
  TXN_TIME                     TIMESTAMP NOT NULL
)
$IN_TABLESPACE
@

create table MDS_DEPL_LINEAGES (
  DL_PARTITION_ID             DECIMAL(31,0) NOT NULL,
  DL_LINEAGE_ID               DECIMAL(31,0) NOT NULL,
  DL_APPNAME                  VARCHAR($deplName) NOT NULL,
  DL_DEPL_MODULE_NAME         VARCHAR($deplName),
  -- TODO: Reduce length of this to 1
  DL_IS_SEEDED                DECIMAL(31,0)
  )
$IN_TABLESPACE
@

create table MDS_LABELS (
  LABEL_PARTITION_ID           DECIMAL(31,0) NOT NULL,
  LABEL_NAME                   VARCHAR(1000) NOT NULL,
  LABEL_DESCR                  VARCHAR($descr),
  LABEL_CN                     DECIMAL(31,0) NOT NULL,
  LABEL_TIME                   TIMESTAMP
)
$IN_TABLESPACE
@


create table MDS_TXN_LOCKS (
  LOCK_PARTITION_ID            DECIMAL(31,0)  NOT NULL,
  LOCK_TXN_CN		       DECIMAL(31,0)  NOT NULL
)
$IN_TABLESPACE
@


create table MDS_STREAMED_DOCS (
  SD_PARTITION_ID              DECIMAL(31,0) NOT NULL,
  SD_CONTENTID                 DECIMAL(31,0) NOT NULL,
  SD_CONTENTS                  BLOB(2G) DEFAULT EMPTY_BLOB() NOT NULL NOT LOGGED
)
$IN_TABLESPACE
@


create table MDS_METADATA_DOCS (
  MD_PARTITION_ID              DECIMAL(31,0) NOT NULL,
  MD_CONTENTID                 DECIMAL(31,0) NOT NULL,
  MD_CONTENTS                  CLOB(1G) NOT NULL
)
$IN_TABLESPACE
@


create table MDS_DEPENDENCIES (
  DEP_ID                        DECIMAL(31,0) GENERATED ALWAYS AS IDENTITY (START WITH 1),
  DEP_PARTITION_ID              DECIMAL(31,0) NOT NULL,
  DEP_CHILD_DOCID               DECIMAL(31,0) NOT NULL,
  DEP_CHILD_LOCALREF            VARCHAR($localRef),
  DEP_PARENT_DOCNAME            VARCHAR($fullRef) NOT NULL,
  DEP_PARENT_LOCALREF           VARCHAR($localRef),
  DEP_TOPARENT_ROLE             VARCHAR($depRoleName),
  DEP_TOCHILD_ROLE              VARCHAR($depRoleName),
  DEP_GUID_REFERENCE            VARCHAR(1),
  DEP_LOW_CN                    DECIMAL(31,0),
  DEP_HIGH_CN                   DECIMAL(31,0)
)
$IN_TABLESPACE
@


create table MDS_SANDBOXES (
  SB_PARTITION_ID               DECIMAL(31,0) NOT NULL,
  SB_NAME                       VARCHAR(255) NOT NULL,
  SB_ML_LABEL                   VARCHAR(1000),
  SB_CREATED_BY                 VARCHAR($username),
  SB_CREATED_ON                 TIMESTAMP
)
$IN_TABLESPACE
@


--Create sequence for partition IDs

CREATE SEQUENCE MDS_PARTITION_ID_S AS DECIMAL(31,0)
    INCREMENT BY 1
    START WITH 1
@

--COMMIT
--@

