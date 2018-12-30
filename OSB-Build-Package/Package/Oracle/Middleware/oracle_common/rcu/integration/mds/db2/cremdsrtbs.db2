-- Copyright (c) 2006, 2009, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- CREMDSRTBS.DB2 - CREate MDs Shredded Repository TaBleS
-- 
-- MODIFIED    (MM/DD/YY)
-- gnagaraj     10/08/09   - XbranchMerge gnagaraj_colsize_changes_bug8859749
--                           from main
-- gnagaraj     10/08/09   - #(8859749) Column size changes
-- erwang       08/27/09   - Use $ for defined variable
-- erwang       08/17/09   - Change variable substitution syntax
-- erwang       07/29/09   - Reduced size of LONG_VALUE to avoid resource issue
-- erwang       07/15/09   - Created from refactoring cremdcmtbs.sql 
--

-- Create MDS repository tables 
-- Max. length for developer-defined component names (docName, packageName)
-- #(8859749) Increase local name column size from 127 to 800
-- and NS prefix from 30 to 127
define localName=800
@
define prefix=127
@
-- Max. length for a local reference (reference to an object within the
-- context of its document)
define localRef=800
@
-- Max. length for attribute value
define attrval=6000
@
-- Max. length of a language value (valid xml:lang attribute value)
define lang=8
@
-- Precision for sequence of an element in a document
define xmlSeq=6
@
-- Precision for sequence of an XML attribute inside its element
define attSeq=4
@
-- Precision for internally generated document id
define docid=10
@
-- Precision for internally generated namespace id
define nsid=5
@

create table MDS_NAMESPACES (
   NS_PARTITION_ID              DECIMAL(31,0) NOT NULL,
   NS_ID                        DECIMAL($nsid,0),
   NS_URI                       VARCHAR(4000)
 )
$IN_TABLESPACE
@


create table MDS_COMPONENTS (
  COMP_PARTITION_ID             DECIMAL(31,0) NOT NULL,
  COMP_CONTENTID                DECIMAL(31,0) NOT NULL,
  COMP_SEQ                      DECIMAL($xmlSeq,0) NOT NULL,
  COMP_LEVEL                    DECIMAL(4,0) NOT NULL,
  COMP_NSID                     DECIMAL($nsid,0),
  COMP_PREFIX                   VARCHAR($prefix),
  COMP_LOCALNAME                VARCHAR($localName),
  COMP_VALUE                    VARCHAR(6000),
  COMP_ID                       VARCHAR($localRef),
  COMP_COMMENT                  VARCHAR(6000)
)
$IN_TABLESPACE
@

    
--- ATT_SEQ allows us to sequence the attributes in document order
--- (may not be required)
--- ATT_LONG_VALUE will be populated only if the value of an attribute exceeds
--- 4K
create table MDS_ATTRIBUTES (
  ATT_PARTITION_ID              DECIMAL(31,0) NOT NULL,
  ATT_CONTENTID                 DECIMAL(31,0) NOT NULL,
  ATT_COMP_SEQ                  DECIMAL($xmlSeq,0) NOT NULL,
  ATT_SEQ                       DECIMAL($attSeq,0) NOT NULL,
  ATT_NSID                      DECIMAL($nsid,0),
  ATT_PREFIX                    VARCHAR($prefix),
  ATT_LOCALNAME                 VARCHAR($localName),
  ATT_VALUE                     VARCHAR($attrval),
  ATT_LONG_VALUE		CLOB(1M) DEFAULT NULL
)
$IN_TABLESPACE
@

--COMMIT
--@

