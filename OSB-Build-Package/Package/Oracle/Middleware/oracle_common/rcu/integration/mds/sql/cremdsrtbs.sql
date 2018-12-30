-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- CREMDSRTBS.SQL - CREate MDs Shredded Repository TaBleS
-- 
-- NOTES
--    Any changes made to this script should be replicated to the same file
--    under the oracleebr folder for creating the EBR-enabled schema tables.
--
-- MODIFIED    (MM/DD/YY)
-- jhsi         07/12/11   - VPD - multitenancy support
-- gnagaraj     10/08/09   - XbranchMerge gnagaraj_colsize_changes_bug8859749
--                           from main
-- jhsi         06/20/11   - XbranchMerge jhsi_mds_ebr_schema from main
-- jhsi         01/18/11   - Added notes for replicating any changes to
--                           oracleebr scripts
-- gnagaraj     10/08/09   - #(8859749) Column size changes
-- vyerrama     03/31/08   - #(6726806) Bumped up the repos version and also 
--                           added support for attributes > 4K
-- gnagaraj     10/22/07   - #(6508932) Remove MDS_ATTRIBUTES_TRANS table
-- abhatt       10/10/07   - #(6472532)Bump up localName capacity to 127,
--                           remove 'name' variable.
-- erwang       06/29/07   - #(5986803) check if table exists before drop
-- jejames      08/04/06   - Refactored MDS_NAMESPACES
-- rnanda       08/14/06   - RCU integration
-- gnagaraj     06/17/06   - Created from refactoring cremdcmtbs.sql 
--

SET VERIFY OFF

REM Create MDS repository tables 

DECLARE
    CNT           NUMBER;
BEGIN

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_NAMESPACES';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_NAMESPACES';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_COMPONENTS';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_COMPONENTS';
  END IF;

  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'MDS_ATTRIBUTES';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_ATTRIBUTES';
  END IF;
  
  CNT := 0;
  SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 
                                                         'MDS_LARGE_ATTRIBUTES';

  IF (CNT > 0) THEN
    EXECUTE IMMEDIATE 'drop table MDS_LARGE_ATTRIBUTES';
  END IF;
END;
/

REM Max. length for developer-defined component names (docName, packageName)
REM #(8859749) Increase local name column size from 127 to 800
define localName=800

REM Max. length for a local reference (reference to an object within the
REM context of its document)
define localRef=800

REM #(8859749) Increase NS prefix column size from 30 to 127
define prefix=127

REM Max. length for attribute value
define attrval=4000


REM Max. length of a language value (valid xml:lang attribute value)
define lang=8

REM Precision for sequence of an element in a document
define xmlSeq=6

REM Precision for sequence of an XML attribute inside its element
define attSeq=4

REM Precision for internally generated document id
define docid=10

REM Precision for internally generated namespace id
define nsid=5


create table MDS_NAMESPACES (
  NS_PARTITION_ID             NUMBER NOT NULL,
  NS_ID                        NUMBER(&&nsid),
  NS_URI                       VARCHAR2(4000)
)
;


create table MDS_COMPONENTS (
  COMP_PARTITION_ID             NUMBER NOT NULL,
  COMP_CONTENTID                NUMBER NOT NULL,
  COMP_SEQ                      NUMBER(&&xmlSeq) NOT NULL,
  COMP_LEVEL                    NUMBER(4) NOT NULL,
  COMP_NSID                     NUMBER(&&nsid),
  COMP_PREFIX                   VARCHAR2(&&prefix),
  COMP_LOCALNAME                VARCHAR2(&&localName),
  COMP_VALUE                    VARCHAR2(4000),
  COMP_ID                       VARCHAR2(&&localRef),
  COMP_COMMENT                  VARCHAR2(4000),
  ENTERPRISE_ID                 NUMBER(18) DEFAULT NVL(SYS_CONTEXT('CLIENTCONTEXT', 'MDS_MT_TENANT_ID'), 0)
)
;
    
Rem ATT_SEQ allows us to sequence the attributes in document order
Rem (may not be required)
REM ATT_LONG_VALUE will be populated only if the value of an attribute exceeds
REM 4K
create table MDS_ATTRIBUTES (
  ATT_PARTITION_ID              NUMBER NOT NULL,
  ATT_CONTENTID                 NUMBER NOT NULL,
  ATT_COMP_SEQ                  NUMBER(&&xmlSeq) NOT NULL,
  ATT_SEQ                       NUMBER(&&attSeq) NOT NULL,
  ATT_NSID                      NUMBER(&&nsid),
  ATT_PREFIX                    VARCHAR2(&&prefix),
  ATT_LOCALNAME                 VARCHAR2(&&localName),
  ATT_VALUE                     VARCHAR2(&&attrval),
  IS_LARGE       		VARCHAR2(1) DEFAULT 'N',
  ENTERPRISE_ID                 NUMBER(18) DEFAULT NVL(SYS_CONTEXT('CLIENTCONTEXT', 'MDS_MT_TENANT_ID'), 0)
)
;

create table MDS_LARGE_ATTRIBUTES (
  ATT_PARTITION_ID              NUMBER NOT NULL,
  ATT_CONTENTID                 NUMBER NOT NULL,
  ATT_COMP_SEQ                  NUMBER(&&xmlSeq) NOT NULL,
  ATT_SEQ                       NUMBER(&&attSeq) NOT NULL,
  ATT_NSID                      NUMBER(&&nsid),
  ATT_PREFIX                    VARCHAR2(&&prefix),
  ATT_LOCALNAME                 VARCHAR2(&&localName),
  ATT_LONG_VALUE		CLOB,
  ENTERPRISE_ID                 NUMBER(18) DEFAULT NVL(SYS_CONTEXT('CLIENTCONTEXT', 'MDS_MT_TENANT_ID'), 0)
)
;
COMMIT;
