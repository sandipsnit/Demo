-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- CREMDCMTBS.SQL - Create MDS Tables for SQL Server
-- 
-- MODIFIED    (MM/DD/YY)
-- jhsi         10/10/11   - Added MDS_METADATA_DOCS table and
--                           PATH_CONTENT_TYPE column
-- erwang       08/26/11   - Added MDS_DOC_MOTYPE_NAME and MDS_DOC_MOTYPE_NSURI
--                           to MDS_PATHS table.
-- gnagaraj     12/08/09   - Add depl_lineages table and lineage_id, checksum
--                           columns on paths table for deployment support
-- gnagaraj     10/08/09   - XbranchMerge gnagaraj_colsize_changes_bug8859749
--                           from main
-- abhatt       03/17/10   - Add new column LABEL_TIME for MDS_LABELS table.
-- vyerrama     03/15/10   - Added created by and created on fields to sandbox
--                           table
-- gnagaraj     10/08/09   - #(8859749) Increase dep localref col size
-- vyerrama     08/21/09   - #(8774395) Reduced the size of the sandbox name.
-- erwang       08/17/09   - increase creator, label size
-- rchalava     08/19/09   - #(8798576) Increase the size of LABEL_NAME
-- erwang       03/20/09   - #(8352261) increased the size of PATH_NAME AND
--                           PATH_FULLNAME
-- erwang       12/17/08   - #(7650199) Switch to use SQL Server IDENTITY to 
--                           simulate Oracle Sequence to avoid deadlock
-- gnagaraj     03/17/08   - #(6838583) Add MDS_PURGE_PATHS table
-- vyerrama     12/12/07   - #(6671248) Increased the size of the sandbox
--                           name field.
-- pwhaley      11/07/07   - #(6616207) Remove unused script vars.
-- erwang       06/27/07   - #(5919142) Workaround RCU empty string issue.
-- erwang       04/17/07   - Reduce column size to meet sql server maximum
--                           index size
-- erwang       12/27/06   - Globalization Support for SQL server.
-- erwang       12/10/06   - Remove UNIQUE from MDS_SEQUENCES.
-- erwang       11/07/06   - fix MDS_TXN_LOCKS name
-- erwang       10/12/06   - Added MDS_SEQUENCES etc.
-- erwang       09/08/06   - Creation..
--


go
set nocount on
-- begin transaction cremdcmtbs
go


-- Max. length for developer-defined component names (docName, packageName)
:setvar name 256

-- Max. length for username
:setvar username 64

-- Max. length for partitionName
:setvar partitionName 200

-- Max. length for a local reference (reference to an object within the
-- context of its document)
-- #(8859749) Increase localRef  column size from 127 to 400
:setvar localRef 400

:setvar depRoleName 127


-- Max. length of a full reference (e.g. /oracle/apps/HR/myRegion#myTextItem,
-- /oracle/apps/PO/myPage#myExtendingRegion#inheritedChild)
:setvar fullRef 400

:setvar descr 800


-- Precision for character encoding for the XML to allow all
-- encodings listed at http://www.iana.org/assignments/character-sets
:setvar encoding 60

-- Max length of Namespace URIs
:setvar nsuri 800

-- Max length of element name
:setvar localname 127

-- Max Length of sequence name
:setvar seqName  256

-- Max Length of deployment module name, application name
:setvar deplName  400

-- Create MDS repository tables 
if object_id(N'MDS_PARTITIONS', N'U') IS NOT NULL
begin
    drop table MDS_PARTITIONS
end
go

if object_id(N'MDS_PATHS', N'U') IS NOT NULL
begin
    drop table MDS_PATHS
end
go

if object_id(N'MDS_STREAMED_DOCS', N'U') IS NOT NULL
begin
    drop table MDS_STREAMED_DOCS
end
go

if object_id(N'MDS_METADATA_DOCS', N'U') IS NOT NULL
begin
    drop table MDS_METADATA_DOCS
end
go

if object_id(N'MDS_DEPENDENCIES', N'U') IS NOT NULL
begin
    drop table MDS_DEPENDENCIES
end
go

if object_id(N'MDS_TXN_LOCKS', N'U') IS NOT NULL
begin
    drop table MDS_TXN_LOCKS
end
go

if object_id(N'MDS_LABELS', N'U') IS NOT NULL
begin
    drop table MDS_LABELS
end
go

if object_id(N'MDS_TRANSACTIONS', N'U') IS NOT NULL
begin
    drop table MDS_TRANSACTIONS
end
go

if object_id(N'MDS_DEPL_LINEAGES', N'U') IS NOT NULL
begin
    drop table MDS_DEPL_LINEAGES
end
go

if object_id(N'MDS_SANDBOXES', N'U') IS NOT NULL
begin
    drop table MDS_SANDBOXES
end
go

if object_id(N'MDS_PURGE_PATHS', N'U') IS NOT NULL
begin
    drop table MDS_PURGE_PATHS
end
go


-- Drop All MDS_SEQUENCE_TABLES, which starts with MDS_SEQUENCE_
DECLARE @oName    NVARCHAR(257)
DECLARE @delSql   NVARCHAR(300)

DECLARE C1 CURSOR GLOBAL FORWARD_ONLY READ_ONLY FOR
  select o.name from sys.objects as o , sys.schemas as s 
         where o.schema_id = s.schema_id and 
              s.name = CURRENT_USER and o.type = 'U' and 
              o.name is not null and o.name like 'MDS_SEQUENCE\_%' ESCAPE '\'

open C1

WHILE(1=1)
BEGIN
  FETCH NEXT FROM C1 INTO @oName
       
  IF (@@FETCH_STATUS <> 0)
  BEGIN
    CLOSE C1
    DEALLOCATE C1
    BREAK
  END

  set @delSql = N'drop table ' + @oName

  exec sp_executesql @delSql        
END
go

create table MDS_PARTITIONS (
 PARTITION_ID                   NUMERIC NOT NULL,
 PARTITION_NAME                 $(MDS_VARCHAR)($(partitionName)) NOT NULL,
 PARTITION_LAST_PURGE_TIME      DATETIME
 )
go

create table MDS_PATHS (
  PATH_PARTITION_ID             NUMERIC NOT NULL,
  PATH_NAME                     $(MDS_VARCHAR)($(name)) NOT NULL,
  PATH_DOCID                    NUMERIC NOT NULL,
  PATH_OWNER_DOCID              NUMERIC NOT NULL,
  PATH_FULLNAME                 $(MDS_VARCHAR)($(fullRef)) NOT NULL,  
  PATH_GUID                     $(MDS_VARCHAR)(36),
  PATH_TYPE                     $(MDS_VARCHAR)(30) NOT NULL,
  PATH_LOW_CN                   NUMERIC,
  PATH_HIGH_CN                  NUMERIC,  
  PATH_CONTENTID                NUMERIC,
  PATH_DOC_ELEM_NSURI           $(MDS_VARCHAR)($(nsuri)),
  PATH_DOC_ELEM_NAME            $(MDS_VARCHAR)($(localname)),  
  PATH_VERSION                  NUMERIC,
  PATH_VER_COMMENT              $(MDS_VARCHAR)($(descr)),
  PATH_OPERATION                NUMERIC,
  PATH_XML_VERSION              $(MDS_VARCHAR)(10),
  PATH_XML_ENCODING             $(MDS_VARCHAR)($(encoding)),  
  PATH_CONT_CHECKSUM            NUMERIC,
  PATH_LINEAGE_ID               NUMERIC,
  PATH_DOC_MOTYPE_NSURI         $(MDS_VARCHAR)($(nsuri)),
  PATH_DOC_MOTYPE_NAME          $(MDS_VARCHAR)($(localname)),  
  PATH_CONTENT_TYPE             NUMERIC,  
)
go

create table MDS_TRANSACTIONS (
   TXN_PARTITION_ID             NUMERIC NOT NULL,
   TXN_CN                       NUMERIC NOT NULL,
   TXN_CREATOR                  $(MDS_VARCHAR)($(username)),
   TXN_TIME                     DATETIME NOT NULL
)
go

create table MDS_DEPL_LINEAGES (
  DL_PARTITION_ID             NUMERIC NOT NULL,
  DL_LINEAGE_ID               NUMERIC NOT NULL,
  DL_APPNAME                  $(MDS_VARCHAR)($(deplName)) NOT NULL,
  DL_DEPL_MODULE_NAME         $(MDS_VARCHAR)($(deplName)),
  DL_IS_SEEDED                NUMERIC
  )
go

create table MDS_LABELS (
   LABEL_PARTITION_ID           NUMERIC NOT NULL,
   LABEL_NAME                   $(MDS_VARCHAR)(400) NOT NULL,
   LABEL_DESCR                  $(MDS_VARCHAR)($(descr)),
   LABEL_CN                     NUMERIC NOT NULL,
   LABEL_TIME                   DATETIME
)
go

create table MDS_TXN_LOCKS (
   LOCK_PARTITION_ID            NUMERIC  NOT NULL,
   LOCK_TXN_CN		            NUMERIC  NOT NULL
)
go

create table MDS_STREAMED_DOCS (
   SD_PARTITION_ID              NUMERIC NOT NULL,
   SD_CONTENTID                 NUMERIC NOT NULL,
   SD_CONTENTS                  VARBINARY(MAX) NOT NULL
)
go

create table MDS_METADATA_DOCS (
   MD_PARTITION_ID              NUMERIC NOT NULL,
   MD_CONTENTID                 NUMERIC NOT NULL,
   MD_CONTENTS                  $(MDS_VARCHAR)(MAX) NOT NULL
)
go

create table MDS_DEPENDENCIES (
  DEP_ID                        NUMERIC IDENTITY UNIQUE CLUSTERED NOT NULL,
  DEP_PARTITION_ID              NUMERIC NOT NULL,
  DEP_CHILD_DOCID               NUMERIC NOT NULL,
  DEP_CHILD_LOCALREF            $(MDS_VARCHAR)($(localRef)),
  DEP_PARENT_DOCNAME            $(MDS_VARCHAR)($(fullRef)) NOT NULL,
  DEP_PARENT_LOCALREF           $(MDS_VARCHAR)($(localRef)),
  DEP_TOPARENT_ROLE             $(MDS_VARCHAR)($(depRoleName)),
  DEP_TOCHILD_ROLE              $(MDS_VARCHAR)($(depRoleName)),
  DEP_GUID_REFERENCE            $(MDS_VARCHAR)(1),
  DEP_LOW_CN                    NUMERIC,
  DEP_HIGH_CN                   NUMERIC
)
go

create table MDS_SANDBOXES (
  SB_PARTITION_ID               NUMERIC NOT NULL,
  SB_NAME                       $(MDS_VARCHAR)(255) NOT NULL,
  SB_ML_LABEL                   $(MDS_VARCHAR)(400),
  SB_CREATED_BY                 $(MDS_VARCHAR)($(username)),
  SB_CREATED_ON                 DATETIME
)
go


create table MDS_PURGE_PATHS (
  PPATH_PARTITION_ID             NUMERIC NOT NULL,
  PPATH_LOW_CN                   NUMERIC NOT NULL,
  PPATH_HIGH_CN                  NUMERIC NOT NULL,
  PPATH_CONTENTID                NUMERIC
)
go

-- commit transaction cremdcmtbs
go


