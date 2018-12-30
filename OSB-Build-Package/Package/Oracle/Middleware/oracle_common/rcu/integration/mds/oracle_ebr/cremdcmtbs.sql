-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- CREMDCMTBS.SQL - CREate MDs CoMmon repository TaBleS
-- 
-- NOTES
--    This script is replicated from the same file under oracle folder
--    for EBR support.
-- 
-- MODIFIED    (MM/DD/YY)
-- jhsi         09/16/11   - Added MDS_METADATA_DOCS view and 
--                           PATH_CONTENT_TYPE column
-- erwang       08/22/11   - Added PATH_DOC_MOTYPE_NAME and
--                           PATH_DOC_MOTYPE_NSURI
-- jhsi         08/16/11   - Added PARTITION_MT_STATE column
-- jhsi         05/27/11   - VPD - multitenancy support
-- jhsi         01/18/11   - Replicated for EBR support
-- vyerrama     03/15/10   - Added created by and created on fields to sandbox
--                           table
-- gnagaraj     12/03/09   - Add depl_lineages table and lineage_id, checksum
--                           columns on paths table for deployment support
-- akrajend     03/17/10   - Added LABELS_TIME column in labels table to support
--                           purging the labels.
-- gnagaraj     10/08/09   - #(8859749) Increase dep localref col size
-- gnagaraj     03/17/08   - #(6838583) Add MDS_PURGE_PATHS table
-- vyerrama     12/12/07   - #(6671248) Increased the size of the sandbox
--                           name field.
-- abhatt       10/10/07   - #(6472532) Remove duplicate localname definition
-- erwang       06/29/07   - #(5986803) check if table exists before drop
-- jhsi         04/05/07   - #(5075746)Remove extra ';' on define encoding
-- abhatt       03/02/07   - Bump up the username column size to 200
-- gnagaraj     02/06/07   - #(5862363) Don't use NOCACHE for sequences
-- abhatt       01/09/07   - Changes to column width for path_name,
--                           path_fullname, and label_name
-- gnagaraj     09/01/06   - Add columns for document QName to MDS_PATHS.
-- abhatt       08/24/06   - Added Purge Time column to partition table.
-- rnanda       08/14/06   - RCU integration.
-- vyerrama     08/06/06   - Added the create tabel sql for MDS_SANDBOXES
-- gnagaraj     06/17/06   - Refactor shredded tables to cremdsrtbs.sql
-- abhatt       15/05/06   - Modified/Added the tables for versioning
-- rchalava     05/10/06   - Repository partition implementation.
-- clowes       04/27/06   - Guid functionality on MDS_DEPENDENCIES 
-- ykosuru      02/09/06   - Add PATH_GUID column 
-- gnagaraj     01/28/06   - Add table for streamed documents.
-- gnagaraj     12/13/05   - Dependency storage support. 
-- gnagaraj     06/15/05   - Increase the size of encoding column to support 
--                           longer encodings 
-- gnagaraj     05/06/05   - Add a table for storing references.
-- gnagaraj     04/19/05   - Add PATH_FULLNAME column to MDS_PATHS to 
--                           optimize docID computation
-- gnagaraj     04/05/05   - Modify the COMP_ID size to work with minimum 
--                           block size.
-- clowes       02/02/05  -  Added ATT_MDS_REF to MDS_ATTRIBUTES for Object
--                           references work
-- enewman      12/01/04  -  Support for generic xml
-- enewman      10/29/02  -  Move indexes to upgmds.sql
-- cbarrow      10/28/02  - #(2637429) Add index on PATH_NAME
-- enewman      06/19/02  - #(2365890) Remove default values
-- enewman      06/18/02  - #(2620444) Add jdr_document_id_s sequence
-- enewman      06/06/02  -  Make ATL_COMP_REF a required column
-- enewman      06/03/02  -  Move type creation to jdrmdstp
-- enewman      05/28/02  -  Add "who" columns to JDR_PATHS
-- enewman      05/24/02  -  Create types needed for customizations
-- cbarrow      04/08/02  -  Correct unique index on JRAD_ATTRIBUTES_TL
-- cbarrow      04/01/02  -  Remove PATH_LANGID, rename ATL_LANGID to ATL_LANG
-- enewman      03/28/02  -  Creation. 
--

SET VERIFY OFF


REM Create MDS repository tables 

DECLARE
    CNT           NUMBER;
BEGIN

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_PARTITIONS_T';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_PARTITIONS_T';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_PATHS_T';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_PATHS_T';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_STREAMED_DOCS_T';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_STREAMED_DOCS_T';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_METADATA_DOCS_T';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_METADATA_DOCS_T';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_DEPENDENCIES_T';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_DEPENDENCIES_T';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_TXN_LOCKS_T';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_TXN_LOCKS_T';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_LABELS_T';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_LABELS_T';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_TRANSACTIONS_T';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_TRANSACTIONS_T';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_DEPL_LINEAGES_T';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_DEPL_LINEAGES_T';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_SANDBOXES_T';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_SANDBOXES_T';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_PURGE_PATHS_T';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_PURGE_PATHS_T';
  END IF;

END;
/


REM Max. length for developer-defined component names (docName, packageName)
define name=400

REM Max. length for username
define username=200

REM Max. length for partitionName
define partitionName=200

REM Max. length for a local reference (reference to an object within the
REM context of its document)
REM #(8859749) Increase localRef column size from 127 to 800
define localRef=800

define depRoleName=127

define deplName=400

REM Max. length of a full reference (e.g. /oracle/apps/HR/myRegion#myTextItem,
REM /oracle/apps/PO/myPage#myExtendingRegion#inheritedChild)
REM Maximum length is specified as 2500 so that in the worst case scenario 
REM {assuming all are multibyte characters which take up 3 bytes} atleast 800 
REM characters can be accomodated.
define fullRef=2500

define descr=800


REM Precision for character encoding for the XML to allow all
REM encodings listed at http://www.iana.org/assignments/character-sets
define encoding=60

REM Max length of Namespace URIs
define nsuri=800

REM Max length of element name
define localname=127


create table MDS_PARTITIONS_T (
 PARTITION_ID                  NUMBER NOT NULL,
 PARTITION_NAME                VARCHAR2(&&partitionName) NOT NULL,
 PARTITION_LAST_PURGE_TIME     TIMESTAMP,
 PARTITION_MT_STATE            NUMBER
 )
;
create or replace editioning view MDS_PARTITIONS as select 
  PARTITION_ID,
  PARTITION_NAME,
  PARTITION_LAST_PURGE_TIME,
  PARTITION_MT_STATE
 from MDS_PARTITIONS_T;

create table MDS_PATHS_T (
  PATH_PARTITION_ID             NUMBER NOT NULL,
  PATH_NAME                     VARCHAR2(&&name) NOT NULL,
  PATH_DOCID                    NUMBER NOT NULL,
  PATH_OWNER_DOCID              NUMBER NOT NULL,
  PATH_FULLNAME                 VARCHAR2(&&fullRef) NOT NULL,  
  PATH_GUID                     VARCHAR2(36),
  PATH_TYPE                     VARCHAR2(30) NOT NULL,
  PATH_LOW_CN                   NUMBER,
  PATH_HIGH_CN                  NUMBER,  
  PATH_CONTENTID                NUMBER,
  PATH_DOC_ELEM_NSURI           VARCHAR2(&&nsuri),
  PATH_DOC_ELEM_NAME            VARCHAR2(&&localname),  
  PATH_VERSION                  NUMBER,
  PATH_VER_COMMENT              VARCHAR2(&&descr),
  PATH_OPERATION                NUMBER,
  PATH_XML_VERSION              VARCHAR2(10),
  PATH_XML_ENCODING             VARCHAR2(&&encoding),  
  PATH_CONT_CHECKSUM            NUMBER,
  PATH_LINEAGE_ID               NUMBER,
  PATH_DOC_MOTYPE_NSURI         VARCHAR2(&&nsuri),
  PATH_DOC_MOTYPE_NAME          VARCHAR2(&&localname),
  PATH_CONTENT_TYPE             NUMBER,
  ENTERPRISE_ID                 NUMBER(18) DEFAULT NVL(SYS_CONTEXT('CLIENTCONTEXT', 'MDS_MT_TENANT_ID'), 0) 
)
;

create or replace editioning view MDS_PATHS as select 
  PATH_PARTITION_ID,
  PATH_NAME,
  PATH_DOCID,
  PATH_OWNER_DOCID,
  PATH_FULLNAME,
  PATH_GUID,
  PATH_TYPE,
  PATH_LOW_CN,
  PATH_HIGH_CN,
  PATH_CONTENTID,
  PATH_DOC_ELEM_NSURI,
  PATH_DOC_ELEM_NAME,
  PATH_VERSION,
  PATH_VER_COMMENT,
  PATH_OPERATION,
  PATH_XML_VERSION,
  PATH_XML_ENCODING,
  PATH_CONT_CHECKSUM,
  PATH_LINEAGE_ID,
  PATH_DOC_MOTYPE_NSURI,
  PATH_DOC_MOTYPE_NAME,
  PATH_CONTENT_TYPE,
  ENTERPRISE_ID
 from MDS_PATHS_T;


create global temporary table MDS_PURGE_PATHS_T (
  PPATH_CONTENTID                NUMBER,
  PPATH_LOW_CN                   NUMBER NOT NULL,
  PPATH_HIGH_CN                  NUMBER NOT NULL,
  PPATH_PARTITION_ID             NUMBER NOT NULL
)ON COMMIT DELETE ROWS;

create or replace editioning view MDS_PURGE_PATHS as select 
  PPATH_CONTENTID,
  PPATH_LOW_CN,
  PPATH_HIGH_CN,
  PPATH_PARTITION_ID
 from MDS_PURGE_PATHS_T;

create table MDS_TRANSACTIONS_T (
   TXN_PARTITION_ID             NUMBER NOT NULL,
   TXN_CN                       NUMBER NOT NULL,
   TXN_CREATOR                  VARCHAR2(&&username),
   TXN_TIME                     TIMESTAMP NOT NULL
)
;

create or replace editioning view MDS_TRANSACTIONS as select 
   TXN_PARTITION_ID,
   TXN_CN,
   TXN_CREATOR,
   TXN_TIME
 from MDS_TRANSACTIONS_T;

create table MDS_DEPL_LINEAGES_T (
  DL_PARTITION_ID             NUMBER NOT NULL, 
  DL_LINEAGE_ID               NUMBER NOT NULL,
  DL_APPNAME                  VARCHAR2(&&deplName) NOT NULL, 
  DL_DEPL_MODULE_NAME         VARCHAR2(&&deplName),
  DL_IS_SEEDED                NUMBER,
  ENTERPRISE_ID               NUMBER(18) DEFAULT NVL(SYS_CONTEXT('CLIENTCONTEXT', 'MDS_MT_TENANT_ID'), 0)
  )
;

create or replace editioning view MDS_DEPL_LINEAGES as select 
  DL_PARTITION_ID,
  DL_LINEAGE_ID,
  DL_APPNAME,
  DL_DEPL_MODULE_NAME,
  DL_IS_SEEDED,
  ENTERPRISE_ID
 from MDS_DEPL_LINEAGES_T;

create table MDS_LABELS_T (
   LABEL_PARTITION_ID           NUMBER NOT NULL,
   LABEL_NAME                   VARCHAR2(1000) NOT NULL,
   LABEL_DESCR                  VARCHAR2(&&descr),
   LABEL_CN                     NUMBER NOT NULL,
   LABEL_TIME                   TIMESTAMP,
   ENTERPRISE_ID                NUMBER(18) DEFAULT NVL(SYS_CONTEXT('CLIENTCONTEXT', 'MDS_MT_TENANT_ID'), 0)
)
;


create or replace editioning view MDS_LABELS as select 
   LABEL_PARTITION_ID,
   LABEL_NAME,
   LABEL_DESCR,
   LABEL_CN,
   LABEL_TIME,
   ENTERPRISE_ID
 from MDS_LABELS_T;


create table MDS_TXN_LOCKS_T (
   LOCK_PARTITION_ID            NUMBER  NOT NULL,
   LOCK_TXN_CN		        NUMBER  NOT NULL
)
;

create or replace editioning view MDS_TXN_LOCKS as select 
   LOCK_PARTITION_ID,
   LOCK_TXN_CN
 from MDS_TXN_LOCKS_T;

create table MDS_STREAMED_DOCS_T (
   SD_PARTITION_ID              NUMBER NOT NULL,
   SD_CONTENTID                 NUMBER NOT NULL,
   SD_CONTENTS                  BLOB NOT NULL,
   ENTERPRISE_ID                NUMBER(18) DEFAULT NVL(SYS_CONTEXT('CLIENTCONTEXT', 'MDS_MT_TENANT_ID'), 0)
)
;

create or replace editioning view MDS_STREAMED_DOCS as select 
   SD_PARTITION_ID,
   SD_CONTENTID,
   SD_CONTENTS,
   ENTERPRISE_ID
 from MDS_STREAMED_DOCS_T;

create table MDS_METADATA_DOCS_T (
   MD_PARTITION_ID              NUMBER NOT NULL,
   MD_CONTENTID                 NUMBER NOT NULL,
   MD_CONTENTS                  CLOB NOT NULL,
   ENTERPRISE_ID                NUMBER(18) DEFAULT NVL(SYS_CONTEXT('CLIENTCONTEXT', 'MDS_MT_TENANT_ID'), 0)
)
;

create or replace editioning view MDS_METADATA_DOCS as select 
   MD_PARTITION_ID,
   MD_CONTENTID,
   MD_CONTENTS,
   ENTERPRISE_ID
 from MDS_METADATA_DOCS_T;

create table MDS_DEPENDENCIES_T (
  DEP_PARTITION_ID              NUMBER NOT NULL,
  DEP_CHILD_DOCID               NUMBER NOT NULL,
  DEP_CHILD_LOCALREF            VARCHAR2(&&localRef),
  DEP_PARENT_DOCNAME            VARCHAR2(&&fullRef) NOT NULL,
  DEP_PARENT_LOCALREF           VARCHAR2(&&localRef),
  DEP_TOPARENT_ROLE             VARCHAR2(&&depRoleName),
  DEP_TOCHILD_ROLE              VARCHAR2(&&depRoleName),
  DEP_GUID_REFERENCE            VARCHAR2(1),
  DEP_LOW_CN                    NUMBER,
  DEP_HIGH_CN                   NUMBER,
  ENTERPRISE_ID                 NUMBER(18) DEFAULT NVL(SYS_CONTEXT('CLIENTCONTEXT', 'MDS_MT_TENANT_ID'), 0)
)
;

create or replace editioning view MDS_DEPENDENCIES as select 
  DEP_PARTITION_ID,
  DEP_CHILD_DOCID,
  DEP_CHILD_LOCALREF,
  DEP_PARENT_DOCNAME,
  DEP_PARENT_LOCALREF,
  DEP_TOPARENT_ROLE,
  DEP_TOCHILD_ROLE,
  DEP_GUID_REFERENCE,
  DEP_LOW_CN,
  DEP_HIGH_CN,
  ENTERPRISE_ID
 from MDS_DEPENDENCIES_T;

create table MDS_SANDBOXES_T (
  SB_PARTITION_ID               NUMBER NOT NULL,
  SB_NAME                       VARCHAR2(800) NOT NULL,
  SB_ML_LABEL                   VARCHAR2(1000),
  SB_CREATED_BY			VARCHAR2(&&username),
  SB_CREATED_ON			TIMESTAMP,
  ENTERPRISE_ID                 NUMBER(18) DEFAULT NVL(SYS_CONTEXT('CLIENTCONTEXT', 'MDS_MT_TENANT_ID'), 0)
)
;

create or replace editioning view MDS_SANDBOXES as select 
  SB_PARTITION_ID,
  SB_NAME,
  SB_ML_LABEL,
  SB_CREATED_BY,
  SB_CREATED_ON,
  ENTERPRISE_ID
 from MDS_SANDBOXES_T;

-- REM Drop all MDS sequences (static and dynamically created)
DECLARE
    seqName       user_sequences.sequence_name%TYPE;
    sqlStmt       VARCHAR2(100);
    err_msg       VARCHAR2(1000);
    err_num       NUMBER;
    CURSOR c_get_seq IS SELECT sequence_name
       FROM user_sequences WHERE sequence_name LIKE 'MDS_%';
BEGIN

  OPEN c_get_seq;
  LOOP
     FETCH c_get_seq INTO seqName;
     EXIT WHEN c_get_seq%NOTFOUND;

     BEGIN
        sqlStmt := 'DROP SEQUENCE ' || seqName;
        EXECUTE IMMEDIATE(sqlStmt);
     EXCEPTION
        WHEN OTHERS THEN
            err_num := SQLCODE;
            err_msg := SUBSTR(SQLERRM, 1, 1000);
            DBMS_OUTPUT.PUT_LINE('Exception while dropping sequence '
                                   || seqName || ' ex = ' || err_msg);
     END;
  END LOOP;
  CLOSE c_get_seq;
END;
/


REM Create sequence for partition IDs
CREATE SEQUENCE MDS_PARTITION_ID_S
  START WITH 1
  INCREMENT BY 1;

COMMIT;
