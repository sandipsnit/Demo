--
-- upgmds.sql
--
-- Copyright (c) 2009, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--    NAME
--      upgmds.sql - Script to upgrade MDS schema to the current release.
--
--    DESCRIPTION
--    This script upgrades the MDS schema by applying all the changes
--    to the existing schema. 
--
--    MODIFIED   (MM/DD/YY)
--    jhsi       10/18/11 - Fixed syntax error on alter table MDS_PATHS
--    jhsi       10/10/11 - Added MDS_METADATA_DOCS table and PATH_CONTENT_TYPE
--                          column
--    erwang     08/26/11 - Added PATH_DOC_MOTYPE_NAME and
--                          PATH_DOC_MOTYPE_NSURI
--    vyerrama   03/23/10 - #(9320961) Added sandbox and label table columns.
--    gnagaraj   12/22/09 - Created, based on cremds.sql
--
--

-- Max Length of deployment module name, application name
:setvar deplName  400
go

-- Max Length of MOTYPE NSURI
:setvar moTypeNS 800
go

-- Max Length of MOTYPE Name
:setvar moTypeName 127
go

SET NOCOUNT ON
set implicit_transactions off
-- begin transaction cremds
go

IF (object_id('mds_tmp_getLineageSequenceName', 'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_tmp_getLineageSequenceName
END
go

create FUNCTION mds_tmp_getLineageSequenceName(@partitionID  NUMERIC) RETURNS NVARCHAR(120)
AS
BEGIN  
  DECLARE @strID      NVARCHAR(50);

  SELECT @strID = CASE 
                    WHEN @partitionID IS NULL THEN '' 
                    WHEN @partitionID < 0 THEN 'n' + CONVERT(NVARCHAR, ABS(@partitionID))
                    ELSE CONVERT(NVARCHAR, @partitionID) 
                  END;

  RETURN ( N'MDS_SEQUENCE_LINEAGE_ID_' + @strID);
END
go

IF (object_id(N'mds_tmp_createSequence', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_tmp_createSequence
END
go

create PROCEDURE mds_tmp_createSequence(@seqName       NVARCHAR(120),
                                        @seed          NUMERIC)
AS
BEGIN  
  DECLARE @err     INT;
  DECLARE @rowc    INT;

  SET NOCOUNT ON;

  --If the sequence table doesn't exist, create it.
  if (object_id(@seqName, N'U') IS NULL)
  BEGIN 
      DECLARE @seedStr NVARCHAR(20);
   
      SELECT @seedStr = CONVERT(NVARCHAR, @seed)
    
      EXEC ('CREATE TABLE ' + @seqName +
           '(ID     NUMERIC IDENTITY(' +
           @seedStr +
           ',1) UNIQUE NOT NULL)')
  END
END
go


if object_id(N'MDS_DEPL_LINEAGES', N'U') IS NULL
begin
  -- Apply changes to the tables to support deployment management
  DECLARE @partitionID  NUMERIC;
  DECLARE @seqName      NVARCHAR(120);
  DECLARE @c1           CURSOR;

  ALTER TABLE MDS_PATHS ADD PATH_CONT_CHECKSUM NUMERIC;
  ALTER TABLE MDS_PATHS ADD PATH_LINEAGE_ID NUMERIC;
  -- include sandbox and purge labesl also.
  ALTER TABLE MDS_SANDBOXES ADD SB_CREATED_BY $(MDS_VARCHAR)(200);
  ALTER TABLE MDS_SANDBOXES ADD SB_CREATED_ON DATETIME;
  ALTER TABLE MDS_LABELS ADD LABEL_TIME DATETIME;

  create table MDS_DEPL_LINEAGES (
    DL_PARTITION_ID             NUMERIC NOT NULL,
    DL_LINEAGE_ID               NUMERIC NOT NULL,
    DL_APPNAME                  $(MDS_VARCHAR)($(deplName)) NOT NULL,
    DL_DEPL_MODULE_NAME         $(MDS_VARCHAR)($(deplName)),
    DL_IS_SEEDED                NUMERIC
    );

  -- Create lineage id sequence for all the existing partitions
  SET @c1 = CURSOR LOCAL FORWARD_ONLY KEYSET FOR
                SELECT PARTITION_ID FROM MDS_PARTITIONS;
  open @c1

  WHILE(1=1)
  BEGIN
   FETCH NEXT FROM @c1 INTO @partitionID;
       
    IF (@@FETCH_STATUS <> 0)
    BEGIN
      CLOSE @c1
      DEALLOCATE @c1
      BREAK
    END

   EXEC @seqName = mds_tmp_getLineageSequenceName @partitionID;
   EXEC mds_tmp_createSequence @seqName, 1;
  END
end
go



-- Just double check if MDS_PATHS is there.
if object_id(N'MDS_PATHS', N'U') IS NOT NULL
begin
  DECLARE @cnt      INT;
  DECLARE @objId    INT;

  SET @objId = object_id(N'MDS_PATHS', N'U');

  SET @cnt = 0;

  SELECT @cnt = count(*) FROM sys.all_columns WHERE object_id = @objId AND
           name = 'PATH_DOC_MOTYPE_NAME';

  if ( @cnt = 0 ) 
  begin
      -- The columns are not there, add them.
      ALTER TABLE MDS_PATHS ADD PATH_DOC_MOTYPE_NSURI $(MDS_VARCHAR)($(moTypeNS));
      ALTER TABLE MDS_PATHS ADD PATH_DOC_MOTYPE_NAME $(MDS_VARCHAR)($(moTypeName));
  end

  -- Add PATH_CONTENT_TYPE if they are not in the table.
  SET @cnt = 0;

  SELECT @cnt = count(*) FROM sys.all_columns WHERE object_id = @objId AND
           name = 'PATH_CONTENT_TYPE';

  if ( @cnt = 0 ) 
  begin
      ALTER TABLE MDS_PATHS ADD PATH_CONTENT_TYPE NUMERIC;
  end
end
go

if object_id(N'MDS_METADATA_DOCS', N'U') IS NULL
begin
  create table MDS_METADATA_DOCS (
    MD_PARTITION_ID              NUMERIC NOT NULL,
    MD_CONTENTID                 NUMERIC NOT NULL,
    MD_CONTENTS                  $(MDS_VARCHAR)(MAX) NOT NULL
    );
end
go


DROP FUNCTION mds_tmp_getLineageSequenceName
go

DROP PROCEDURE mds_tmp_createSequence
go

-- Creating the indexes
:r dropmdsinds.sql
:r cremdsinds.sql

-- Creating the package specs
:r mdsinc.sql
:r mdsinsr.sql
go

