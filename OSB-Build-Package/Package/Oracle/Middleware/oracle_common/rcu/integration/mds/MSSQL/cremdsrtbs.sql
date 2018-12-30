-- Copyright (c) 2006, 2009, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- CREMDSRTBS.SQL - Create Tabls for Shredded Database for SQL Server.
-- 
-- MODIFIED    (MM/DD/YY)
-- gnagaraj     10/08/09   - XbranchMerge gnagaraj_colsize_changes_bug8859749
--                           from main
-- gnagaraj     09/28/09   - #(8859749) Column size changes
-- vyerrama     03/31/08   - #(6726806) Added ATT_LONG_VALUE column to 
--                           MDS_ATTRIBUTES table to support attribute values 
--                           greater than 4k
-- pwhaley      11/07/07   - #(6616207) Increase localName to match oracle.
-- gnagaraj     10/22/07   - #(6508932) Remove MDS_ATTRIBUTES_TRANS table
-- erwang       06/27/07   - #(5919142) Workaround RCU empty string issue.
-- erwang       04/17/07   - Reduce column size to meet sql server maximum
--                           index size
-- erwang       12/27/06   - Globalization Support
-- erwang       09/04/06   - Creation
--

go
set nocount on
-- begin transaction cremdsrtbs
go

-- Max. length for developer-defined component names (docName, packageName)
:setvar name 60

-- #(8859749) Increase local name column size from 127 to 400
-- and NS prefix size from 30 to 127
:setvar localName 400
:setvar prefix 127

-- Max. length for a local reference (reference to an object within the
-- context of its document)
:setvar localRef 400

-- Max. length for attribute value
:setvar attrval 4000

-- Max. length for component value
:setvar comval 4000


-- Max. length of a language value (valid xml:lang attribute value)
:setvar lang 8

-- Precision for sequence of an element in a document
:setvar xmlSeq 6

-- Precision for sequence of an XML attribute inside its element
:setvar attSeq 4

-- Precision for internally generated document id
:setvar docid 10

-- Precision for internally generated namespace id
:setvar nsid 5


-- Create MDS repository tables  
if object_id(N'MDS_NAMESPACES', N'U') IS NOT NULL
begin
    drop table MDS_NAMESPACES
end
go

if object_id(N'MDS_COMPONENTS', N'U') IS NOT NULL
begin
    drop table MDS_COMPONENTS
end
go

if object_id(N'MDS_ATTRIBUTES', N'U') IS NOT NULL
begin
    drop table MDS_ATTRIBUTES
end
go


create table MDS_NAMESPACES (
  NS_PARTITION_ID              NUMERIC NOT NULL,
  NS_ID                        NUMERIC($(nsid)),
  NS_URI                       $(MDS_VARCHAR)(4000)
)
go


create table MDS_COMPONENTS (
  COMP_PARTITION_ID             NUMERIC NOT NULL,
  COMP_CONTENTID                NUMERIC NOT NULL,
  COMP_SEQ                      NUMERIC($(xmlSeq)) NOT NULL,
  COMP_LEVEL                    NUMERIC(4) NOT NULL,
  COMP_NSID                     NUMERIC($(nsid)),
  COMP_PREFIX                   $(MDS_VARCHAR)($(prefix)),
  COMP_LOCALNAME                $(MDS_VARCHAR)($(localName)),
  COMP_VALUE                    $(MDS_VARCHAR)($(comval)),
  COMP_ID                       $(MDS_VARCHAR)($(localRef)),
  COMP_COMMENT                  $(MDS_VARCHAR)(4000)
)
go


-- ATT_SEQ allows us to sequence the attributes in document order
-- (may not be required)
create table MDS_ATTRIBUTES (
  ATT_PARTITION_ID              NUMERIC NOT NULL,
  ATT_CONTENTID                 NUMERIC NOT NULL,
  ATT_COMP_SEQ                  NUMERIC($(xmlSeq)) NOT NULL,
  ATT_SEQ                       NUMERIC($(attSeq)) NOT NULL,
  ATT_NSID                      NUMERIC($(nsid)),
  ATT_PREFIX                    $(MDS_VARCHAR)($(prefix)),
  ATT_LOCALNAME                 $(MDS_VARCHAR)($(localName)),
  ATT_VALUE                     $(MDS_VARCHAR)($(attrval)),
  ATT_LONG_VALUE                $(MDS_VARCHAR)(MAX)
)
go


-- commit transaction cremdsrtbs
go


