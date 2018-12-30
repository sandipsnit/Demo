-- Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 
--
--
-- CREMDCMTBS.SQL - CREate MDs CoMmon repository TaBleS
-- 
-- MODIFIED    (MM/DD/YY)
--    jhsi      10/11/11 - Added MDS_METADATA_DOCS table and PATH_CONTENT_TYPE
--                         column
--    erwang    08/28/11 - Added PATH_DOC_MOTYPE_NSURI nad PATH_DOC_MOTYPE_NAME
--                         to MDS_PATHS
--    erwang    06/22/11 - #(12600604) adjust column sizes
--    erwang    03/22/11 - Change delimiter to /
--    erwang    01/10/11 - Creation. 
--

-- Note ';' has to be applied to the next line in define statement.

-- Max. length for developer-defined component names (docName, packageName)
define name=256;

-- Max. length for username
define username=64;
 
-- Max. length for partitionName
define partitionName=200;
 
-- Max. length for a local reference (reference to an object within the
-- context of its document)
define localRef=256;
 
define depRoleName=127;
 

-- Max. length of a full reference (e.g. /oracle/apps/HR/myRegion#myTextItem,
-- /oracle/apps/PO/myPage#myExtendingRegion#inheritedChild)
define fullRef=480;
 
define descr=800;
 
-- Precision for character encoding for the XML to allow all
-- encodings listed at http:/www.iana.org/assignments/character-sets
define encoding=60;
 
-- Max length of Namespace URIs
define nsuri=800;

-- Max length of Label Name
define labName=512;
 
-- Max length of element name
define localname=127;
 
-- Max length of Sandbox Name
define sbName=512;
 
-- Max length of sequence name
define seqName=256;

-- Max length of application and deploy module(MAR) name
define deplName=350;
 
-- Define table parameters 
define tabparams="ENGINE=InnoDB DEFAULT CHARACTER SET=UTF8MB4 DEFAULT COLLATE=UTF8MB4_BIN ROW_FORMAT=DYNAMIC";


create table MDS_PARTITIONS (
  PARTITION_ID                  INT NOT NULL,
  PARTITION_NAME                VARCHAR($name) NOT NULL,
  PARTITION_LAST_PURGE_TIME     TIMESTAMP NULL 
 )
$tabparams 
/


create table MDS_PATHS (
  PATH_PARTITION_ID             INT NOT NULL,
  PATH_NAME                     VARCHAR($name) NOT NULL,
  PATH_DOCID                    BIGINT NOT NULL,
  PATH_OWNER_DOCID              BIGINT NOT NULL,
  PATH_FULLNAME                 VARCHAR($fullRef) NOT NULL,  
  PATH_GUID                     VARCHAR(36),
  PATH_TYPE                     VARCHAR(30) NOT NULL,
  PATH_LOW_CN                   BIGINT,
  PATH_HIGH_CN                  BIGINT,  
  PATH_CONTENTID                BIGINT,
  PATH_DOC_ELEM_NSURI           VARCHAR($nsuri),
  PATH_DOC_ELEM_NAME            VARCHAR($localname),  
  PATH_VERSION                  INT,
  PATH_VER_COMMENT              VARCHAR($descr),
  PATH_OPERATION                SMALLINT,
  PATH_XML_VERSION              VARCHAR(10),
  PATH_XML_ENCODING             VARCHAR($encoding),
  PATH_CONT_CHECKSUM            BIGINT,
  PATH_LINEAGE_ID               BIGINT,
  PATH_DOC_MOTYPE_NSURI         VARCHAR($nsuri),
  PATH_DOC_MOTYPE_NAME          VARCHAR($localname),
  PATH_CONTENT_TYPE             SMALLINT  
)
$tabparams
/


create table MDS_TRANSACTIONS (
  TXN_PARTITION_ID             INT NOT NULL,
  TXN_CN                       BIGINT NOT NULL,
  TXN_CREATOR                  VARCHAR($username),
  TXN_TIME                     TIMESTAMP NOT NULL 
)
$tabparams
/

create table MDS_DEPL_LINEAGES (
  DL_PARTITION_ID             INT NOT NULL,
  DL_LINEAGE_ID               BIGINT NOT NULL,
  DL_APPNAME                  VARCHAR($deplName) NOT NULL,
  DL_DEPL_MODULE_NAME         VARCHAR($deplName),
  DL_IS_SEEDED                SMALLINT
  )
$tabparams
/

create table MDS_LABELS (
  LABEL_PARTITION_ID           INT NOT NULL,
  LABEL_NAME                   VARCHAR($labName) NOT NULL,
  LABEL_DESCR                  VARCHAR($descr),
  LABEL_CN                     BIGINT NOT NULL,
  LABEL_TIME                   TIMESTAMP NULL 
)
$tabparams
/


create table MDS_TXN_LOCKS (
  LOCK_PARTITION_ID            INT  NOT NULL,
  LOCK_TXN_CN		       BIGINT  NOT NULL
)
$tabparams
/


create table MDS_STREAMED_DOCS (
  SD_PARTITION_ID              INT NOT NULL,
  SD_CONTENTID                 BIGINT NOT NULL,
  SD_CONTENTS                  LONGBLOB DEFAULT NULL 
)
$tabparams
/


create table MDS_METADATA_DOCS (
  MD_PARTITION_ID              INT NOT NULL,
  MD_CONTENTID                 BIGINT NOT NULL,
  MD_CONTENTS                  LONGTEXT DEFAULT NULL 
)
$tabparams
/


create table MDS_DEPENDENCIES (
  DEP_ID                        BIGINT NOT NULL AUTO_INCREMENT,
  DEP_PARTITION_ID              INT NOT NULL,
  DEP_CHILD_DOCID               BIGINT NOT NULL,
  DEP_CHILD_LOCALREF            VARCHAR($localRef),
  DEP_PARENT_DOCNAME            VARCHAR($fullRef) NOT NULL,
  DEP_PARENT_LOCALREF           VARCHAR($localRef),
  DEP_TOPARENT_ROLE             VARCHAR($depRoleName),
  DEP_TOCHILD_ROLE              VARCHAR($depRoleName),
  DEP_GUID_REFERENCE            VARCHAR(1),
  DEP_LOW_CN                    BIGINT,
  DEP_HIGH_CN                   BIGINT,
  UNIQUE KEY(DEP_ID)
)
$tabparams
/


create table MDS_SANDBOXES (
  SB_PARTITION_ID               INT NOT NULL,
  SB_NAME                       VARCHAR($sbName) NOT NULL,
  SB_ML_LABEL                   VARCHAR(1000),
  SB_CREATED_BY                 VARCHAR($username),
  SB_CREATED_ON                 TIMESTAMP DEFAULT 0 
)
$tabparams
/


create table MDS_PURGE_PATHS (
  PPATH_PARTITION_ID             INT NOT NULL,
  PPATH_LOW_CN                   BIGINT NOT NULL,
  PPATH_HIGH_CN                  BIGINT NOT NULL,
  PPATH_CONTENTID                BIGINT 
)
$tabparams
/



