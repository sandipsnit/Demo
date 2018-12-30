-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- CREMDSRTBS.SQL - Create Tabls for Shredded Database for SQL Server.
-- 
-- MODIFIED    (MM/DD/YY)
-- erwang       06/22/11   - #(12600604) adjust column sizes
-- erwang       03/22/11   - Change delimiter to /
-- erwang       01/10/11   - Creation
--

-- Note, a ';' is required for define statement, and it has to
-- be in next line.  Otherwise, it will break RCU or prep.pl

-- #(8859749) Increase local name column size from 127 to 320 
-- and NS prefix size from 30 to 127
define localName=320;

define prefix=127;

-- Max. length for a local reference (reference to an object within the
-- context of its document)
define localRef=320;

-- Max. length for attribute value
define attrval=4000;

-- Max. length for component value
define comval=4000;

-- Max. length of a language value (valid xml:lang attribute value)
define lang=INT;

-- Precision for sequence of an element in a document
define xmlSeq=INT;

-- Precision for sequence of an XML attribute inside its element
define attSeq=SMALLINT;

-- Precision for internally generated document id
define docid=INT;

-- Precision for internally generated namespace id
define nsid=INT;

-- Define table parameters 
define tabparams="ENGINE=InnoDB DEFAULT CHARACTER SET=UTF8MB4 DEFAULT COLLATE=UTF8MB4_BIN ROW_FORMAT=DYNAMIC";


create table MDS_NAMESPACES (
  NS_PARTITION_ID              INT NOT NULL,
  NS_ID                        $nsid NOT NULL AUTO_INCREMENT,
  NS_URI                       VARCHAR(4000),
  UNIQUE KEY(NS_ID)
)
$tabparams
/


create table MDS_COMPONENTS (
  COMP_PARTITION_ID             INT NOT NULL,
  COMP_CONTENTID                BIGINT NOT NULL,
  COMP_SEQ                      $xmlSeq NOT NULL,
  COMP_LEVEL                    SMALLINT NOT NULL,
  COMP_NSID                     $nsid,
  COMP_PREFIX                   VARCHAR($prefix),
  COMP_LOCALNAME                VARCHAR($localName),
  COMP_VALUE                    VARCHAR($comval),
  COMP_ID                       VARCHAR($localRef),
  COMP_COMMENT                  VARCHAR(4000)
)
$tabparams
/


-- ATT_SEQ allows us to sequence the attributes in document order
-- (may not be required)
create table MDS_ATTRIBUTES (
  ATT_PARTITION_ID              INT NOT NULL,
  ATT_CONTENTID                 BIGINT NOT NULL,
  ATT_COMP_SEQ                  $xmlSeq NOT NULL,
  ATT_SEQ                       $attSeq NOT NULL,
  ATT_NSID                      $nsid,
  ATT_PREFIX                    VARCHAR($prefix),
  ATT_LOCALNAME                 VARCHAR($localName),
  ATT_VALUE                     VARCHAR($attrval),
  ATT_LONG_VALUE                LONGTEXT DEFAULT NULL 
)
$tabparams
/




