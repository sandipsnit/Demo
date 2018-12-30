
-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- MDSINSR.sql - MDS T-SQL for Shredded DB Implementation.
--
--
-- MODIFIED   (MM/DD/YY)
-- pwhaley     08/30/12  - #(14916246) bump repos version for purge fix.
-- pwhaley     08/28/12 - XbranchMerge pwhaley_missing_txn_rows from
--                        st_jdevadf_patchset_ias
-- erwang      05/29/12 - XbranchMerge erwang_bug-10122333 from main
-- erwang      05/22/12 - #(1012333) throw NO_DATA_FOUND exception if deleting
--                        a non-exist partition
-- jhsi        10/10/11 - Update repos version to 11.1.1.61.63 for unshredded
--                        xml.
-- erwang      09/06/11 - Bump up repository version to 11.1.1.61.34
-- akrajend    03/01/11 - #(11817738) bump up repos version to 11.1.1.59.73.
-- vyerrama    07/01/10  - XbranchMerge vyerrama_sandbox_guid from main
-- akrajend    02/23/10  - #(9551097) Update repos version for deploy support
--                         11.1.1.56.59.
-- gnagaraj    10/08/09  - XbranchMerge gnagaraj_colsize_changes_bug8859749
--                         from main
-- gnagaraj    10/08/09  - #(8859749) Update repos version to 11.1.1.55.16
-- gnagaraj    08/17/09  - #(8495663) Change repos version to 11.1.1.54.63
-- vyerama     08/14/09  - #(8693111) Init variables for exportDocumentByID
-- rupandey    07/08/09  - #(8576789) Bump repos version. Added additional
--                         parameter to #mds_purgeMetadata.
-- erwang      06/18/09  - Put constant value in one line to workaround rcu
--                         issue
-- pwhaley     06/02/09  - #(8568578) in exportDocumentByID, if the cursor is
--                         open, close it.
-- erwang      03/25/09  - #(8360042) fixed an issue, existed in exporting 
--                         documents, that caused value truncation if the 
--                         value of an attribute has size close to 4000 characters
-- erwang      03/20/09  - #(8352261) increased the size of PATH_NAME AND
--                         PATH_FULLNAME
-- erwang      01/09/09  - #(7675079) Performance enhancement
-- erwang      12/24/08  - #(7650199) Move common Reraise exception code in a macro
--                         variable to be reuse
-- allechen    08/14/08  - #(7330706) Match the errorcodes with MssqlDB class
-- vyerrama    04/22/08  - #(6992480) Fix some case issues
-- vyerrama    03/31/08  - #(6726806) Bumped up the repos version and 
--                         added support for attribute values greater than 4k.
-- abhatt      03/21/08  - #(5891638) make error numbers contiguos
-- gnagaraj    03/17/08  - #(6838583) Purge performance enhancements.
-- gnagaraj    02/13/08  - Remove unused ERROR constants
-- abhatt      11/23/07  - #(6616221) Do not add encoding='' in the XML 
--                         header if encoding is null.
-- pwhaley     11/07/07  - #(6616207) Increase LOCALNAME to 127.
-- pwhaley     11/05/07  - #(5926597) Return transaction commit time;
-- gnagaraj    10/22/07  - #(6508932) Store translations in generic tables
-- gnagaraj    09/27/07  - #(6446544) Increment repos version
-- erwang      08/22/07  - Check if xml_encoding is null
-- pwhaley     08/01/07  - #(6282257) Add mds_trimWhite function.
-- gnagaraj    07/09/07  - #(6165956) Update repos version to 11.0.0.46.11
-- erwang      06/27/07  - #(5919142) Workaround RCU empty string issue.
-- erwang      06/01/07  - #(5675607) Bump MIN_MDS_VERSION to '11.0.0.42.88'
-- erwang      04/17/07  - change column size etc.
-- gnagaraj    01/24/07  - Add ERROR_GUID_CONFLICT
-- erwang      01/17/07  - globalization support.
-- erwang      01/29/07  - Removed code for explicitly setting xml document
--                          encoding to UTF-8.
-- erwang      12/27/06  - Globalization Support
-- cbarrow     01/05/07  - Bump repos version from 11.0.0.42.44 to 11.0.0.42.88
-- erwang      11/22/06  - SQL server concurrency
-- erwang      11/13/06  - Set nocount on to improve peroformance
-- erwang      11/08/06  - Fix some case issues
-- erwang      10/13/06  - Creation based on MDSINSRB.PLS
--
--

go
set nocount on
-- begin transaction mdsinsr
go

-- $Header: jtmds/src/dbschema/sqlserver/mdsinsr.sql /st_jdevadf_patchset_ias/8 2012/08/30 10:35:19 pwhaley Exp $ 
-----------------------------------------------------------------------------
---------------------------- PRIVATE VARIABLES ------------------------------
-----------------------------------------------------------------------------

-- This is used to verify that the repository API and MDS java code are
-- compatible.  REPOS_VERSION should be updated every time repository schema/ 
-- stored procedures are modified to current version of MDS.
--
-- In addition, if MDS java code is not compatible with older repository,
-- MsSqlDB.MIN_SHREDDED_REPOS_VERSION should be changed to this value.
:setvar REPOS_VERSION            "11.1.1.63.92"


-- This is used to verify that the repository API and MDS java code are
-- compatible.  This is the earliest MDS midtier version which is compatible
-- with the repository.
:setvar MIN_MDS_VERSION          "11.1.1.54.33"


-- NEWLINE character NCHAR(10) IS THE SAME AS CHAR(10).
:setvar NEWLINE                  "NCHAR(10)"

-- Maximimum size of XML chunk for processing buffer. 
:setvar MAX_CHUNK_SIZE           32000

-- Maximum size of returned XML chunk.  4000 is the current limitation for SQL Server.
:setvar MAX_RETURN_CHUNK_SIZE    4000

-- Indentation for XML elements
:setvar INDENT_SIZE              3

-- Maximum rows to fetch with bulk bind
:setvar ROWS_TO_FETCH            1000

-- Maximum size for Max and Min Version
:setvar MDS_VERSION              32

-- Each element size for mStack session variable
:setvar STACK_ELEM               128

-- Maxmium Stack Level. #mds_session_varaibles table has to match this value.
:setvar MAX_STACK_LEVEL          100

-- Stack Field Size, which holds the mStack variables. The total size of the stack field 
-- should be larger than STACK_ELEM * MAX_STACK_LEVEL
:setvar STACK_FIELD_SIZE         12800

-- System Defined Error ID.  Definition can be found at sys.messages table.
:setvar LOCK_REQUEST_TIMEOUT     1222
:setvar DUP_VAL_ON_CONSTRAINT    2601
:setvar DUP_VAL_ON_INDEX         2627

-- constant variables define lengths of varchar columns
:setvar COMP_ID                  400
:setvar COMP_COMMENT             4000
:setvar CREATOR                  30
:setvar ELEM_NSURI               800
:setvar ELEM_NAME                127
:setvar FULLNAME                 400
:setvar LOCALNAME                127
:setvar GUID                     36
:setvar NRI                      4000
:setvar PARTITION_NAME           200
:setvar PATH_NAME                256 
:setvar PATH_TYPE                30
:setvar PREFIX                   30
:setvar VALUE                    4000
:setvar VER_COMMENTS             800
:setvar XML_VERSION              10
:setvar XML_ENCODING             60

-- constant variables define some special non varchar types.
:setvar SEQ_TYPE                 NUMERIC(6,0)
:setvar LEVEL_TYPE               NUMERIC(4,0)
:setvar NSID_TYPE                NUMERIC(5,0)

-- Name for session variables 
:setvar PREVIOUS_NAME            "PREVIOUS_NAME"
-- mPreviousLevel
:setvar PREVIOUS_LEVEL           "PREVIOUS_LEVEL"
-- mPreviousValue
:setvar PREVIOUS_VALUE           "PREVIOUS_VALUE"
-- mPreviousComp
:setvar PREVIOUS_COMP            "PREVIOUS_COMP"
-- mIsTagOpen
:setvar IS_TAG_OPEN              "IS_TAG_OPEN"
-- mPartialChunk
:setvar PARTIAL_CHUNK            "PARTIAL_CHUNK"
-- mPartialXLIFFChunk
:setvar PARTIAL_XLIFF_CHUNK      "PARTIAL_XLIFF_CHUNK"
-- mIndex
:setvar INDEX                    "IDNEX"
-- mFormatted
:setvar FORMATTED                "FORMATTED"

-- mStack   
:setvar STACK                    "STACK"

-- mLeftXML
:setvar LEFT_XML_FRAGMENT       "LEFT_XML_FRAGMENT"

-- Debug flag
:setvar DBGPRINT                 "IF 1 = 1 PRINT " 

-- User-defined exceptions.
-- The error code will be encoded in text message of error 50000.  "'" must be 
-- used in define error code.  
-- Must keep these error codes in sync with mdsinc.sql and other scripts.
  
-- External Error Codes to Java layer
:setvar ERROR_DOCUMENT_NAME_CONFLICT  50100
:setvar ERROR_PACKAGE_NAME_CONFLICT   50101
:setvar ERROR_CORRUPT_SEQUENCE        50102
:setvar ERROR_CONFLICTING_CHANGE      50103  
:setvar ERROR_RESOURCE_BUSY           50104
:setvar ERROR_GUID_CONFLICT           50105
:setvar ERROR_RESOURCE_NOT_EXIST      50106
:setvar ERROR_LINEAGE_ALREADY_EXIST   50107
:setvar ERROR_NO_DATA_FOUND           50108

-- Internal Error Codes
:setvar ERROR_CHUNK_SIZE_EXCEEDED     50200
:setvar ERROR_ARRAY_OUT_OF_BOUNDARY   50201

-- Common code for reraise the exception
:setvar RERAISE_MESSAGE_DECLARE     "DECLARE @ErrorMessage NVARCHAR(4000); DECLARE @ErrorSeverity INT; DECLARE @ErrorState INT;" 

:setvar RERAISE_EXCEPTION           "SELECT @ErrorMessage = CASE ERROR_NUMBER() WHEN 50000 THEN ERROR_MESSAGE() ELSE CONVERT(NVARCHAR, ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE() END, @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(); RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState); RETURN;" 

-----------------------------------------------------------------------------
--------------------------- Session Variables Accessors ---------------------
-----------------------------------------------------------------------------

--
-- Get the value that saved at @stack.
--
IF (object_id(N'mds_internal_getStackValue', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_getStackValue;
END
go

create PROCEDURE mds_internal_getStackValue(
    @val              $(MDS_VARCHAR)($(STACK_ELEM)) OUTPUT,
    @seq              $(LEVEL_TYPE),
    @stack            $(MDS_VARCHAR)(MAX) OUTPUT)
AS
BEGIN
  DECLARE @loc        SMALLINT;

  SET NOCOUNT ON;

  IF (@seq < 1 OR @seq > $(MAX_STACK_LEVEL))
  BEGIN
    RAISERROR(N'$(ERROR_ARRAY_OUT_OF_BOUNDARY)', 16, 1);
  END

  SET @loc = (@seq-1) * $(STACK_ELEM) + 1;

  SET @val = SUBSTRING(@stack, @loc, $(STACK_ELEM));  

  SET @val = RTRIM(@val);
  RETURN ;
END
go

--
-- Set the value to @stack.
--
IF (object_id(N'mds_internal_setStackValue', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_setStackValue;
END
go

create PROCEDURE mds_internal_setStackValue(
    @seq              $(LEVEL_TYPE),
    @val              $(MDS_VARCHAR)($(STACK_ELEM)),
    @stack            $(MDS_VARCHAR)(MAX) OUTPUT)
AS
BEGIN
  DECLARE @loc        SMALLINT;
  DECLARE @i          SMALLINT;

  SET NOCOUNT ON;

  IF (@seq < 1 OR @seq > $(MAX_STACK_LEVEL))
  BEGIN
    RAISERROR(N'$(ERROR_ARRAY_OUT_OF_BOUNDARY)', 16, 1);
  END

  IF ( @stack IS NULL )
    SET @stack = N'';
  
  SET @loc = (@seq-1) * $(STACK_ELEM) + 1;

  -- Get the size of @stack include space.
  SET @i = LEN(ISNULL(@stack, '') + N'|') -1;

  -- Expand the stack so we can use STUFF function.
  IF (@i < @loc + $(STACK_ELEM) - 1)
  BEGIN
    SET @stack = @stack + SPACE(@loc +$(STACK_ELEM) - 1 - @i);
  END

  SET @i = LEN(ISNULL(@val, '') + N'|') -1;

  SET @stack = STUFF(@stack, @loc, $(STACK_ELEM), 
                     @val + SPACE($(STACK_ELEM) - @i));

  RETURN;
END
go


--
-- Creates the XML for the new component
--
IF (object_id(N'mds_internal_addComponent', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_addComponent
END
go

create PROCEDURE mds_internal_addComponent(
    @newxml              $(MDS_VARCHAR)(max)                     OUTPUT,
    @compseq             $(SEQ_TYPE),
    @complevel           $(LEVEL_TYPE),
    @compprefix          $(MDS_VARCHAR)($(PREFIX)),
    @complocalname       $(MDS_VARCHAR)($(LOCALNAME)),
    @compvalue           $(MDS_VARCHAR)($(VALUE)),
    @attValues           $(MDS_VARCHAR)(MAX),
    @formatted           TINYINT = 1,
    @prevComp            $(SEQ_TYPE)                             OUTPUT,
    @prevVal             $(MDS_VARCHAR)($(VALUE))                OUTPUT,
    @prevName            $(MDS_VARCHAR)($(LOCALNAME))            OUTPUT,
    @prevLevel           $(LEVEL_TYPE) OUTPUT,
    @isTagOpen           TINYINT OUTPUT,
    @stack               $(MDS_VARCHAR)(MAX)                     OUTPUT)
AS
BEGIN
  SET NOCOUNT ON;

  -- If this is a mixed content element value, then add the element now
  -- This can occur with the following xml:
  -- <a>
  --    first mixed content
  --    <b>
  --      this is not mixed content since b has no children
  --    </b>
  --    and more mixed content of a
  -- </a>
  IF (@compvalue IS NOT NULL) 
              AND (@complocalname IS NULL OR LEN(@complocalname) = 0)
  BEGIN
    -- This is the situation that the value is not the left part of
    -- previous value.  It has a non -1 COMP_LEVEL value.
    SET @newxml = @newxml + @compvalue;

    SELECT @prevLevel = @complevel,
           @prevVal   = NULL,
           @prevName  = NULL;
  END
  ELSE
  BEGIN
    DECLARE @temp      $(MDS_VARCHAR)($(STACK_ELEM));
    DECLARE @currLevel $(LEVEL_TYPE);

    -- This is a true element, so let's add it now
    SET @currLevel = @complevel + 1;
    IF (@compprefix IS NOT NULL AND LEN(@compprefix) > 0)
    BEGIN
      SET @temp = (@compprefix + N':' + @complocalname);
      EXEC mds_internal_setStackValue @currLevel, @temp, @stack OUTPUT;
    END
    ELSE
    BEGIN
      EXEC mds_internal_setStackValue @currLevel, @complocalname, @stack OUTPUT;
    END
      
    IF (@formatted = 1) 
      SET @newxml = @newxml +  SPACE(@complevel*$(INDENT_SIZE));

    SET @currLevel = @complevel+1;
    EXEC mds_internal_getStackValue @temp OUTPUT, @currLevel, @stack OUTPUT;      

    SET @newxml = @newxml + N'<' + @temp + @attValues

    -- Update the state
    SELECT @prevLevel = @complevel,
           @prevComp  = @compseq,
           @prevVal   = @compvalue,
           @prevName  = @complocalname,
           @isTagOpen = 1;
  END
END
go


--
-- Add the XML to the current chunk and raise an exception if the
-- maximum size is exceeded.
--
IF (object_id(N'mds_internal_addXMLtoChunk', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_addXMLtoChunk
END
go

create PROCEDURE mds_internal_addXMLtoChunk(
    @chunk    $(MDS_VARCHAR)(max) OUTPUT,
    @newxml   $(MDS_VARCHAR)(max))
AS
BEGIN
  DECLARE @LEN1          INT;
  DECLARE @LEN2          INT;

  SET NOCOUNT ON;

  -- SQL server LEN() function doesn't count trailing space, we have to work 
  -- around the issue.
  SET @LEN1 = LEN(ISNULL(@newxml, '') + N'|') -1;
  SET @LEN2 = LEN(ISNULL(@chunk, '') + N'|') -1;

  IF ((@LEN1 + @LEN2) > $(MAX_CHUNK_SIZE))
    RAISERROR(N'$(ERROR_CHUNK_SIZE_EXCEEDED)', 16, 1);
  ELSE
    SET @chunk = @chunk + @newxml;
END
go


--
-- Create the XML header for the given document ID
--
IF (object_id(N'mds_internal_addXMLHeader', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_internal_addXMLHeader
END
go

create FUNCTION mds_internal_addXMLHeader(
    @partitionID   NUMERIC,
    @docID         NUMERIC,
    @versionNum    NUMERIC) RETURNS $(MDS_VARCHAR)(256)
AS
BEGIN
  DECLARE @xml_version   $(MDS_VARCHAR)($(XML_VERSION));
  DECLARE @xml_encoding  $(MDS_VARCHAR)($(XML_ENCODING));
  DECLARE @mdsguid       $(MDS_VARCHAR)($(GUID));
  DECLARE @xml_header    $(MDS_VARCHAR)(256);

  -- Get the version and encoding
  SELECT
    @xml_version  = PATH_XML_VERSION, 
    @xml_encoding = PATH_XML_ENCODING, 
    @mdsguid      = PATH_GUID
  FROM
    MDS_PATHS
  WHERE
    PATH_DOCID = @docID AND PATH_VERSION = @versionNum
    AND PATH_PARTITION_ID = @partitionID;

  -- ###
  -- ### #(2424399) Need to be able to retrieve XML_VERSION
  -- ### from the XML file
  -- ###
 
  IF (@xml_version IS NULL OR LEN(@xml_version) = 0)
    SET @xml_version = N'1.0';


  -- Return the xml header
  SET @xml_header = N'<?xml version=''' + @xml_version + N'''';
  
  -- #(6616221) Do not add encoding='' in the XML header if encoding is
  -- null.
  IF (@xml_encoding IS NOT NULL)
    SET @xml_header = @xml_header + N' encoding=''' + @xml_encoding + N'''';
  
  SET @xml_header = @xml_header + N'?>' + NCHAR(10);

  IF @mdsguid IS NOT NULL AND LEN(@mdsguid) > 0  
    SET @xml_header = @xml_header + N'<?oracle.mds.mdsguid ' + @mdsguid +
				    N'?>' + $(NEWLINE);
    
  RETURN @xml_header;
END
go

--
-- Creates the XML for ending a component
--
IF (object_id(N'mds_internal_endComponent', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_endComponent
END
go

create PROCEDURE mds_internal_endComponent(
    @newxml              $(MDS_VARCHAR)(max)                 OUTPUT,
    @compLevel           $(LEVEL_TYPE),
    @formatted           TINYINT = 1,
    @prevComp            $(SEQ_TYPE)                         OUTPUT,
    @prevVal             $(MDS_VARCHAR)($(VALUE))            OUTPUT,
    @prevName            $(MDS_VARCHAR)($(LOCALNAME))        OUTPUT,
    @prevLevel           $(LEVEL_TYPE)                       OUTPUT,
    @isTagOpen           TINYINT                             OUTPUT,
    @stack               $(MDS_VARCHAR)(MAX)                 OUTPUT)
AS
BEGIN
  DECLARE @I         SMALLINT;
  DECLARE @temp      $(MDS_VARCHAR)($(STACK_ELEM));
  DECLARE @valAdded  SMALLINT;

  SET NOCOUNT ON;

  SET @valAdded = 0;

  IF (@prevName IS NULL OR LEN(@prevName) = 0)     
      -- The previous "component" was not really a component, but just an
      -- element value. This can happen with the following xml, in which
      -- we are in the process of adding component b:
      --   <a>
      --      some value
      --      <b>
      --      ...
      --
      -- When adding component b, we don't need to end component a since
      -- it would have been "ended" when the element value was added.
      -- However, since we are starting a new component, we do want to add
      -- a new line.
      SET @newxml = @newxml + $(NEWLINE);
  ELSE IF (@compLevel <= @prevLevel)
  BEGIN
    -- The previous component has no children, so we can end the tag now.
    -- If the previous component had a value, we need to add that as well.
    IF (@prevVal IS NOT NULL AND LEN(@prevVal) <> 0)
    BEGIN
      -- Add the previous value, if any.  This can happen with the following
      -- xml, in which we are about to add component b:
      --   <a attribute1="foo">
      --     some value
      --   </a>
      --   <b>
      --      ...
      -- Here, since "some value" is a real element value, it is saved in
      -- the same row in which the component is defined.  We couldn't add
      -- the value right away, since we add to add all of the attributes
      -- first (like attribute1).  Now, however, since we are done adding
      -- the attributes, we can safely add the element value.
      -- #(5580893) Don't add any formatting if textcontent was found
      SET @valAdded = 1;  
      SET @newxml = @newxml + N'>' + @prevVal;
      SET @prevVal = NULL;
      SET @isTagOpen = 0;
    END
    IF (@isTagOpen = 1)
        -- No element value, so a simple end tag will work
        SET @newxml = @newxml + N'/>' + $(NEWLINE);
    ELSE
    BEGIN
      DECLARE @prevStackLevel  $(LEVEL_TYPE);
      -- Add the end tag (i.e. </a>)
      IF (@valAdded = 0)
        SET @newxml = @newxml + $(NEWLINE);

      IF (@formatted = 1 AND @valAdded = 0)
        SET @newxml = @newxml + SPACE(@prevLevel*$(INDENT_SIZE));

      SET @prevStackLevel = @prevLevel + 1;
      EXEC mds_internal_getStackValue @temp OUTPUT, @prevStackLevel, @stack OUTPUT;      
      SET @newxml = @newxml + N'</' + @temp + N'>' + $(NEWLINE);
    END
  END
  ELSE
  BEGIN
      -- There are potential children to come
      SET @newxml = @newxml + N'>' + $(NEWLINE);
      SET @isTagOpen = 0;
  END

  -- Check if we need to pop any components from the stack
  SET @I = @prevLevel;
  WHILE (@I > @compLevel)
  BEGIN
    IF (@formatted = 1)
      SET @newxml = @newxml + SPACE((@I-1)*$(INDENT_SIZE));
    
    EXEC mds_internal_getStackValue @temp OUTPUT, @I, @stack OUTPUT;
    SET @newxml = @newxml +  N'</' + @temp + N'>' + $(NEWLINE);
    SET @I = @I - 1;
  END
END
go

--
-- Restore all session variables.
--
IF (object_id(N'mds_internal_restoreSessionVariables', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_restoreSessionVariables;
END
go

create PROCEDURE mds_internal_restoreSessionVariables(
    @prevName            $(MDS_VARCHAR)($(LOCALNAME))       OUTPUT,
    @prevLevel           $(LEVEL_TYPE)                      OUTPUT,
    @prevVal             $(MDS_VARCHAR)($(VALUE))           OUTPUT,
    @prevComp            $(SEQ_TYPE)                        OUTPUT,
    @isTagOpen           TINYINT                            OUTPUT,
    @partialChunk        $(MDS_VARCHAR)(MAX)                OUTPUT,
    @formatted           INT                                OUTPUT,
    @stack               $(MDS_VARCHAR)(MAX)                OUTPUT,
    @leftXML             $(MDS_VARCHAR)(MAX)                OUTPUT)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT @prevName = $(PREVIOUS_NAME), @prevLevel = $(PREVIOUS_LEVEL),
         @prevVal = $(PREVIOUS_VALUE), @prevComp = $(PREVIOUS_COMP),
         @isTagOpen = $(IS_TAG_OPEN), @partialChunk = $(PARTIAL_CHUNK),
         @formatted = $(FORMATTED), @stack = $(STACK),
         @leftXML = $(LEFT_XML_FRAGMENT)
    FROM #MDS_SESSION_VARIABLES;
END
go

--
-- Save all session variables
--
IF (object_id(N'mds_internal_saveSessionVariables', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_internal_saveSessionVariables;
END
go

create PROCEDURE mds_internal_saveSessionVariables(
    @prevName            $(MDS_VARCHAR)($(LOCALNAME)),
    @prevLevel           $(LEVEL_TYPE),
    @prevVal             $(MDS_VARCHAR)($(VALUE)),
    @prevComp            $(SEQ_TYPE),
    @isTagOpen           TINYINT,
    @partialChunk        $(MDS_VARCHAR)(max),
    @formatted           INT,
    @stack               $(MDS_VARCHAR)(MAX),
    @leftXML             $(MDS_VARCHAR)(MAX))

AS
BEGIN

  SET NOCOUNT ON;

  UPDATE #MDS_SESSION_VARIABLES
    SET  $(PREVIOUS_NAME) = @prevName, $(PREVIOUS_LEVEL) = @prevLevel,
         $(PREVIOUS_VALUE) = @prevVal, $(PREVIOUS_COMP) = @prevComp,
         $(IS_TAG_OPEN) = @isTagOpen, $(PARTIAL_CHUNK) = @partialChunk,
         $(FORMATTED) = @formatted, $(STACK) = @stack,
         $(LEFT_XML_FRAGMENT) = @leftXML;
END
go

-----------------------------------------------------------------------------
----------------------------- PUBLIC FUNCTIONS ------------------------------
-----------------------------------------------------------------------------
--
-- Export the XML for the document with given PATH_DOCID and pass it
-- back in MAX_RETURN_CHUNK_SIZE chunks.  Each call will try to get 
-- MAX_CHUNK_SIZE, if the retrieved size is larger than MAX_RETURN_CHUNK_SIZE,
-- the overflowed value will be saved in #MDS_SESSION_VARIABLES.PARTIAL_CHUNK.
-- The caller has to retrieve it as well.
--
-- A "single" document is simply a document which is not a package document.
-- See comments for exportDocumentByName for more information.
-- Before make this call, a temp table, #MDS_SESSION_VARIABLES 
-- has to be created and seed using following syntax:

-- It is assumed that one single Element Tag, includes its attributes,
-- cannot excceed 2Gb.  If so, the Element may not be built correct and
-- some parts might be truncatted.

-- Create session temp table to hold scaler session variables.
-- CREATE TABLE #MDS_SESSION_VARIABLES(
        -- mPreviousLevel 
--        $(PREVIOUS_LEVEL)           $(LEVEL_TYPE) NULL,
        -- mPreviousComp
--        $(PREVIOUS_COMP)            $(SEQ_TYPE) NULL,
        -- mIsTagOpen
--        $(IS_TAG_OPEN)              TINYINT DEFAULT 0,
        -- mFormatted
--        $(FORMATTED)                INT DEFAULT 0,
        -- mPreviousName
--        $(PREVIOUS_NAME)            VARCHAR($(LOCALNAME)) NULL,
        -- mPreviousValue
--        $(PREVIOUS_VALUE)           VARCHAR($(VALUE)) NULL,
        -- mPartialChunk
--        $(PARTIAL_CHUNK)            VARCHAR(max) NOT NULL,
        -- mStack 
--        $(STACK)                    VARCHAR(max) NOT NULL
	-- mLeftXML
--        $(LEFT_XML_FRAGMENT)        VARCHAR(max)

--);

  -- Seed the values.
--  INSERT INTO #MDS_SESSION_VARIABLES VALUES(NULL, NULL, 0, 0, NULL, NULL, '', '', NULL, 1);           

  
IF (object_id(N'mds_exportDocumentByID', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_exportDocumentByID
END
go

create PROCEDURE mds_exportDocumentByID(
    @retChunk              $(MDS_VARCHAR)($(MAX_RETURN_CHUNK_SIZE)) OUTPUT,
    @exportFinished        INT  OUTPUT,
    @partitionID           NUMERIC,
    @docID                 NUMERIC,
    @contentID             NUMERIC,
    @versionNum            NUMERIC,
    @isFormatted           INT = 1)
AS
BEGIN
  DECLARE @formatted            TINYINT;
  DECLARE @newxml               $(MDS_VARCHAR)(max);
  DECLARE @chunk                $(MDS_VARCHAR)(max);

  -- Variables holds fetched record.
  DECLARE @rCompSeq             $(SEQ_TYPE);
  DECLARE @rCompPrefix          $(MDS_VARCHAR)($(PREFIX));
  DECLARE @rCompLocalName       $(MDS_VARCHAR)($(LOCALNAME));
  DECLARE @rCompLevel           $(LEVEL_TYPE);
  DECLARE @rCompValue           $(MDS_VARCHAR)($(VALUE));
  DECLARE @rAttValues           $(MDS_VARCHAR)(max);  -- This will be used to save all attributes for the current element.

  -- Session variables, they will be persisted before exist.
  DECLARE @mPreviousName        $(MDS_VARCHAR)($(LOCALNAME));
  DECLARE @mPreviousLevel       $(LEVEL_TYPE);
  DECLARE @mPreviousValue       $(MDS_VARCHAR)($(VALUE));
  DECLARE @mPreviousComp        $(SEQ_TYPE);
  DECLARE @mIsTagOpen           TINYINT;
  DECLARE @mPartialChunk        $(MDS_VARCHAR)(max);
  DECLARE @mFormatted           INT;  
  DECLARE @mStack               $(MDS_VARCHAR)(max);
  DECLARE @mLeftXML             $(MDS_VARCHAR)(max);


  DECLARE @LEN                  INT;

  SET NOCOUNT ON;

  SET @retChunk = N'';
  SET @chunk    = N'';


  IF (@isFormatted = 1)
    SET @formatted = 1;
  ELSE
    SET @formatted = 0;

  IF (@docID IS NOT NULL)
  BEGIN
     SET @mFormatted = @isFormatted;
     SET @mPreviousName = NULL;
     SET @mPreviousLevel = NULL;
     SET @mPreviousValue = NULL;
     SET @mPreviousComp = NULL;
     SET @mIsTagOpen = NULL;
     SET @mPartialChunk = NULL;
     SET @mStack = NULL;
     SET @mLeftXML = NULL;
  END
  ELSE
    -- Restore Session Variables from the table.
    EXEC mds_internal_restoreSessionVariables @mPreviousName OUTPUT, @mPreviousLevel OUTPUT,
                                              @mPreviousValue OUTPUT, @mPreviousComp OUTPUT,
                                              @mIsTagOpen OUTPUT, @mPartialChunk OUTPUT,
                                              @mFormatted OUTPUT, 
                                              @mStack OUTPUT,
			   		      @mLeftXML OUTPUT;

  IF (@mFormatted = 1)
    SET @formatted = 1;
  ELSE
    SET @formatted = 0;

  -- Assume that the document will fit in this $(MAX_RETURN_CHUNK_SIZE) chunk
  SET @exportFinished = 1;
 
  -- Clean the mPartialChunk since it is read by the previous call if any.
  SET @mPartialChunk = N'';

  --
  -- This procedure returns the XML for the specified document.  Since the
  -- XML can be potentially large (greater than 32k) and since, for
  -- performance reasons, we do not want to return more than 32k at a time,
  -- this procedure may need to be called multiple times to retrieve the
  -- entire document.  As such, the "state" of the export is stored in
  -- package variables.
  --
  -- A non-null document indicates that the export process is just
  -- being started, so let's do the necessary initialization.
  --
  IF (@docID IS NOT NULL)
  BEGIN
    DECLARE @cStatus      SMALLINT;
    
    -- Get the XML header
    EXEC @chunk = mds_internal_addXMLHeader @partitionID, @docID, @versionNum;

    -- Initialize the state of the export
    SET @mPreviousLevel = -1;
    SET @mPreviousComp = NULL;
    SET @mStack = N'';
    SET @mLeftXML = N'';

    SELECT @cStatus = CURSOR_STATUS(N'GLOBAL', N'c_document_contents');

    -- Declare the cursor if it is not there.
    IF (@cStatus = -3)
    BEGIN
      -- Cursor to  retrieve all of the components of a document, FOR XML PATH will replace & with &amp;, so we 
      -- need to strip them out since we already done so before putting them in the database.
      DECLARE c_document_contents CURSOR GLOBAL FORWARD_ONLY READ_ONLY FOR
        SELECT
          COMP_SEQ,
          COMP_LEVEL,
          COMP_PREFIX,
          COMP_LOCALNAME,
          COMP_VALUE,
                                           
          -- Add attributes.  Before putting to the database, MDS already entitized the XML significant 
          -- characters in attribute values so only & will appear.
          CASE COMP_LEVEL WHEN -1 THEN '' ELSE REPLACE(ISNULL(o.list, N''), '&amp;', '&') END

        FROM
          MDS_COMPONENTS
          OUTER APPLY
          ( 
            SELECT CASE 
                WHEN ATT_LOCALNAME is NOT NULL THEN 
                  CASE 
                    WHEN ATT_PREFIX IS NOT NULL
                      THEN 
                        CASE 
                          WHEN ATT_VALUE IS NOT NULL THEN
                            -- #(8360042) Has to cast ATT_VALUE to varchar(max) since it might be up to 4000 characters
                            -- long which could cause trucation when appending with other additional characters.
                            N' ' + ATT_PREFIX + N':' + ATT_LOCALNAME + N'="' + CAST(ATT_VALUE as $(MDS_VARCHAR)(max)) + N'"'
                          ELSE
                            N' ' + ATT_PREFIX + N':' + ATT_LOCALNAME + N'="' + ATT_LONG_VALUE + N'"'
                        END
                    ELSE 
                      CASE
                        WHEN ATT_VALUE IS NOT NULL THEN
                          N' ' + ATT_LOCALNAME + N'="' + CAST(ATT_VALUE as $(MDS_VARCHAR)(max)) + N'"'
                        ELSE
                          N' ' + ATT_LOCALNAME + N'="' + ATT_LONG_VALUE + N'"'
                      END
                  END  
                ELSE 
                  CASE 
                    WHEN ATT_VALUE IS NOT NULL THEN
                      CAST(ATT_VALUE as $(MDS_VARCHAR)(max)) + N'"'
                    WHEN ATT_LONG_VALUE IS NOT NULL THEN
                      ATT_LONG_VALUE + N'"'
                    ELSE N''
                  END
               END AS [text()] 
            FROM MDS_ATTRIBUTES 
            WHERE COMP_PARTITION_ID = ATT_PARTITION_ID
                  AND COMP_SEQ = ATT_COMP_SEQ                                      
                  AND COMP_CONTENTID = ATT_CONTENTID
            ORDER BY ATT_COMP_SEQ,
                     ATT_SEQ
            FOR XML PATH('')
          ) o (list)
        WHERE COMP_PARTITION_ID = @partitionID AND
              COMP_CONTENTID = @contentID
        ORDER BY COMP_SEQ;
    END
    ELSE IF (@cStatus <> -1)
      -- #(8568578) The cursor is open (left from partial read) - close it.
      CLOSE GLOBAL c_document_contents;

    -- And open the cursor that will retrieve the documents/packages
    OPEN GLOBAL c_document_contents;
  END

  SET @newxml = @mLeftXML; 
  IF (CURSOR_STATUS(N'GLOBAL', N'c_document_contents') >= 0)
  BEGIN
    BEGIN TRY
      WHILE(1=1)
      BEGIN 
        --
        -- Retrieve the next set of rows if we are currently not in the
        -- middle of processing a fetched set or rows.
        --
        -- Fetch the next set of rows
        IF (@newxml IS NOT NULL AND DATALENGTH(@newxml) > 0) 
        BEGIN
          -- There are some xml fragment left from previous call, we will add it now.

          EXEC mds_internal_addXMLtoChunk @chunk OUTPUT, @newxml;  
          
          -- If the @newxml can fit to the chunk, then we will continue for next element.
          SET @newxml = N'';
        END

        FETCH NEXT FROM c_document_contents
		INTO @rCompSeq, 
                     @rCompLevel, 
                     @rCompPrefix, 
                     @rCompLocalName,
                     @rCompValue, 
                     @rAttValues;       

        -- If no more record found, just close the cursor and return.
        IF (@@FETCH_STATUS <> 0)
        BEGIN          
          CLOSE c_document_contents;
          DEALLOCATE c_document_contents;
          BREAK;
        END
        
        -- We are starting a new component/value, so add the "previous"
        -- component

        IF (@rCompLevel = -1)
        BEGIN
          -- Add the element value.  -1 is a special level
          -- indicating that the element value was too large too fit
          -- in a single 4k chunk.
          IF (@mPreviousValue IS NOT NULL)
          BEGIN
            SET @newxml = @newxml + N'>' + @mPreviousValue;
            SET @mIsTagOpen = 0;
            SET @mPreviousValue = NULL;
          END

          -- This value is part of the previous element value.
          SET @newxml = @newxml + ISNULL(@rCompValue, N'');        
        END
        ELSE
        BEGIN
          -- End the previous component
          IF (@rCompSeq <> 0)
            -- This is not the first element, so close the previous element.
            EXEC mds_internal_endComponent @newxml OUTPUT, 
                                           @rCompLevel, 
                                           @formatted,
                                           @mPreviousComp OUTPUT, 
                                           @mPreviousValue OUTPUT, 
                                           @mPreviousName OUTPUT, 
                                           @mPreviousLevel OUTPUT,  
                                           @mIsTagOpen OUTPUT,
                                           @mStack OUTPUT;             
          
          -- Start building the new component
          EXEC mds_internal_addComponent @newxml OUTPUT,
                                         @rCompSeq, 
                                         @rCompLevel,
                                         @rCompPrefix, 
                                         @rCompLocalName,
                                         @rCompValue, 
                                         @rAttValues,
                                         @formatted, 
                                         @mPreviousComp OUTPUT,
                                         @mPreviousValue OUTPUT, 
                                         @mPreviousName OUTPUT,
                                         @mPreviousLevel OUTPUT, 
                                         @mIsTagOpen OUTPUT,
                                         @mStack OUTPUT;
        END

        -- Append any leftover XML
        EXEC mds_internal_addXMLtoChunk @chunk OUTPUT, @newxml;
        SET @newxml = N'';
      END  -- END LOOP.

      --
      -- We have finished exporting the document.  The only task that remains
      -- it to end the previous component and to unwind the stack
      --
      SET @newxml = N'';

      -- End the previous element
      EXEC mds_internal_endComponent @newxml OUTPUT, 0, @formatted,
                                     @mPreviousComp OUTPUT, @mPreviousValue OUTPUT, 
                                     @mPreviousName OUTPUT, @mPreviousLevel OUTPUT,
                                     @mIsTagOpen OUTPUT,
                                     @mStack OUTPUT;
      EXEC mds_internal_addXMLtoChunk @chunk OUTPUT, @newxml;  

    END TRY
    BEGIN CATCH
      IF ERROR_NUMBER() = 50000 AND 
         ERROR_MESSAGE() = N'$(ERROR_CHUNK_SIZE_EXCEEDED)'
      BEGIN
        DECLARE @newxmllen    INT;

        SET @exportFinished = 0;
 
        -- We don'w know if the @chunk size is larger than $(MAX_RETURN_CHUNK_SIZE),
        -- since the exception can be the situation with an empty @chunk and a large
        -- @newxml

        SET @LEN = LEN(ISNULL(@chunk, '') + N'|') -1;
        SET @newxmllen = LEN(ISNULL(@newxml, '') + N'|') -1;

        IF (@LEN > $(MAX_RETURN_CHUNK_SIZE))
        BEGIN
          SET @retChunk = LEFT(@chunk, $(MAX_RETURN_CHUNK_SIZE));

          IF ( @newxmllen < 2 * $(MAX_RETURN_CHUNK_SIZE) )
          BEGIN
            SET @mPartialChunk = RIGHT(@chunk, @LEN - $(MAX_RETURN_CHUNK_SIZE)) + @newxml;
            SET @mLeftXML = N'';
          END
          ELSE
          BEGIN
            SET @mPartialChunk = RIGHT(@chunk, @LEN - $(MAX_RETURN_CHUNK_SIZE)) + 
                LEFT(@newxml, $(MAX_RETURN_CHUNK_SIZE));
            SET @mLeftXML = RIGHT(@newxml, @newxmllen - $(MAX_RETURN_CHUNK_SIZE));
          END
        END
        ELSE
        BEGIN
          SET @retChunk = @chunk + LEFT(@newxml, $(MAX_RETURN_CHUNK_SIZE) - @LEN);

          IF ( @newxmllen < $(MAX_CHUNK_SIZE) + 2 * $(MAX_RETURN_CHUNK_SIZE) )
          BEGIN
            SET @mPartialChunk = RIGHT(@newxml, @newxmllen + @LEN - $(MAX_RETURN_CHUNK_SIZE));
            SET @mLeftXML = N'';
          END
          ELSE
          BEGIN
            SET @mPartialChunk = SUBSTRING(@newxml, $(MAX_RETURN_CHUNK_SIZE) - @LEN + 1,
                                                                         $(MAX_CHUNK_SIZE));
            SET @mLeftXML = RIGHT(@newxml, @newxmllen - $(MAX_RETURN_CHUNK_SIZE) -
                                           $(MAX_RETURN_CHUNK_SIZE) + @LEN);
          END
        END


        -- Save session variables.
        EXEC mds_internal_saveSessionVariables @mPreviousName, @mPreviousLevel,
                                               @mPreviousValue, @mPreviousComp,
                                               @mIsTagOpen, @mPartialChunk, 
                                               @mFormatted, @mStack,
                                               @mLeftXML;
        RETURN;
      END
      ELSE
      BEGIN
        $(RERAISE_MESSAGE_DECLARE)
        $(RERAISE_EXCEPTION)
      END
    END CATCH
  END

  --
  -- Return the current chunk, and set the mPartialChunk to NULL so that,
  -- when entering this function again, we will know that we have finished
  -- processing the document.
  --
  SET @LEN = LEN(ISNULL(@chunk, '') + N'|') -1;

  IF ( @LEN > $(MAX_RETURN_CHUNK_SIZE) )
  BEGIN
    SET @retChunk = LEFT(@chunk, $(MAX_RETURN_CHUNK_SIZE));
    SET @mPartialChunk = RIGHT(@chunk, @LEN- $(MAX_RETURN_CHUNK_SIZE));
  END
  ELSE
  BEGIN
    SET @retChunk = @chunk;
    SET @mPartialChunk = N'';
  END

  -- Save session variables.  We know that there is no content left in @mLeftXML.
  EXEC mds_internal_saveSessionVariables @mPreviousName, @mPreviousLevel,
                                         @mPreviousValue, @mPreviousComp,
                                         @mIsTagOpen, @mPartialChunk, 
                                         @mFormatted, 
                                         @mStack,
                                         N'';

  RETURN;
END
go


--
-- Export the XML for tip version of a document and pass it back in
-- MAX_RETURN_CHUNK_SIZE chunks.  Each call will try to get 
-- MAX_CHUNK_SIZE, if the retrieved size is larger than MAX_RETURN_CHUNK_SIZE,
-- the overflowed value will be saved in #MDS_SESSION_VARIABLES.PARTIAL_CHUNK.
-- The caller has to retrieve it as well.
--
-- Specifying a document name will initiate the export.  Thereafter, a NULL
-- document name should be passed in until the export is complete.
-- That is, to export an entire document, you should do:
--
-- firstChunk := mds_exportDocumentByName(isDone,
--                                        '/oracle/apps/fnd/mydoc');
-- WHILE (isDone = 0)
--   nextChunk := mds_exportDocumentByName(isDone, NULL);
-- END LOOP;
--
-- Parameters:
--   exportFinished - OUT parameter which indicates whether or not the export
--                    is complete.  1 indicates the entire document is
--                    exported, 0 indicates that there are more chunks
--                    remaining.
--
--   fullName  - the fully qualifued name of the document.  however,
--               after the first chunk of text is exported, a NULL value
--               should be passed in.
--
--   partitionID - the partition where the document exists
--   formatted - a non-zero value indicates that the XML is formatted nicely
--               (i.e. whether or not the elements are indented)
--
-- Returns:
--   The exported XML, in 32k chunks.
--
IF (object_id(N'mds_exportDocumentByName', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_exportDocumentByName
END
go

create PROCEDURE mds_exportDocumentByName(
    @chunk                 $(MDS_VARCHAR)(max) OUTPUT,
    @exportFinished        INT                 OUTPUT,
    @partitionID           NUMERIC,
    @fullName              $(MDS_VARCHAR)($(FULLNAME)),
    @formatted             INT = 1)
AS
BEGIN
  DECLARE @docID        NUMERIC;
  DECLARE @contentID    NUMERIC;
  DECLARE @versionNum   NUMERIC;

  SET NOCOUNT ON;

  --
  -- A non-null fullName indicates that this is the first time this function
  -- is being called for this document.  If so, we need to find the
  -- document ID and start the export process.
  --
  IF (@fullName IS NOT NULL AND LEN(@fullName) > 0)
  BEGIN
    EXEC @docID = mds_getDocumentID @partitionID, @fullName;

    -- Since this method is only used by mds_utils, read the tip version
    SELECT @contentID = PATH_CONTENTID, @versionNum = PATH_VERSION
    FROM MDS_PATHS
    WHERE PATH_DOCID=@docID AND PATH_HIGH_CN IS NULL
    AND PATH_PARTITION_ID=@partitionID;

    IF (@docID = -1)
    BEGIN
      -- Unable to find the document
      -- ###
      -- ### Give error if unable to locate document
      -- ###
      SET @chunk = N'';
      RETURN;
    END

    EXEC mds_exportDocumentByID @chunk OUTPUT, 
                                @exportFinished OUTPUT, 
                                @partitionID, @docID, 
                                @contentID, @versionNum, 
                                @formatted;
  END
  ELSE
  BEGIN
    EXEC mds_exportDocumentByID @chunk OUTPUT, 
                                @exportFinished OUTPUT, 
                                @partitionID, null, null, null;
  END
  RETURN;
END
go


-- Gets the minimun version of MDS with which the repository is
-- compatible.  That is, the actual MDS version must be >= to the
-- minimum version of MDS in order for the repositroy and java code to
-- be compatible.
--
-- Returns:
--   Returns the mimumum version of MDS
--
IF (object_id(N'mds_getMinMDSVersion', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_getMinMDSVersion
END
go

create FUNCTION mds_getMinMDSVersion() RETURNS $(MDS_VARCHAR)($(MDS_VERSION))
AS
BEGIN
  RETURN '$(MIN_MDS_VERSION)';
END
go



--
-- Retrieves the namespace id for the specified uri.  If the namespace
-- does not already exist, it will be created.  No validation occurs on the
-- uri.
--
-- Parameters:
--   namespaceID   - Returns the ID for the uri
--   partitionID   - Partition Id    
--   uri           - uri
--

IF (object_id(N'mds_getNamespaceID', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_getNamespaceID
END
go


create PROCEDURE mds_getNamespaceID(@namespaceID           NUMERIC OUTPUT,
                                    @partitionID           NUMERIC, 
                                    @uri                   $(MDS_VARCHAR)($(NRI)))
AS
BEGIN
  DECLARE @t1 TABLE(NS_ID NUMERIC NOT NULL);

  SET NOCOUNT ON;

  SELECT @namespaceID = NS_ID  
      FROM MDS_NAMESPACES
      WHERE NS_URI = @uri AND
            NS_PARTITION_ID = @partitionID;

  IF @@error = 0 AND @@rowcount = 0
  BEGIN
    INSERT INTO MDS_NAMESPACES(NS_PARTITION_ID, NS_ID, NS_URI)
--             WITH(TABLOCKX)
             OUTPUT INSERTED.NS_ID INTO @t1(NS_ID)
             SELECT @partitionID, ISNULL(MAX(NS_ID),0)+1, @uri
                 FROM MDS_NAMESPACES ;
    SELECT @namespaceID = NS_ID FROM @t1;    
  END
END
go


--
-- Deletes the given partition. If there are any documents in the given
-- partition, this method will delete all those documents.
--
-- Parameters:
--   partitionName - Name of the partition.
--
IF (object_id(N'mds_deletePartition', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_deletePartition
END
go

create PROCEDURE mds_deletePartition(@partitionName $(MDS_VARCHAR)($(PARTITION_NAME)))
AS
BEGIN
  DECLARE @partitionID      NUMERIC;

  SET NOCOUNT ON;

  BEGIN TRY
    SELECT @partitionID = PARTITION_ID FROM MDS_PARTITIONS
    WHERE PARTITION_NAME = @partitionName;

    -- #(1012333) Raise exception if partition doesn't exist. 
    IF (@@error = 0 AND @@rowcount = 0)
    BEGIN
        RAISERROR(N'$(ERROR_NO_DATA_FOUND)', 16, 1);
    END
  
    DELETE MDS_COMPONENTS WITH(ROWLOCK) WHERE COMP_PARTITION_ID = @partitionID;
    DELETE MDS_ATTRIBUTES WITH(ROWLOCK) WHERE ATT_PARTITION_ID = @partitionID;
    DELETE MDS_NAMESPACES WITH(ROWLOCK) WHERE NS_PARTITION_ID = @partitionID;

    EXEC mds_internal_deletePartition @partitionID;

  END TRY
  BEGIN CATCH
    $(RERAISE_MESSAGE_DECLARE)
    $(RERAISE_EXCEPTION)
  END CATCH
END
go
  
--
-- Gets the version of the repository API.  This API version must >= to the
-- java constant CompatibleVersions.MIN_REPOS_VERSION.
--
-- Returns:
--   Returns the version of the repository
--
IF (object_id(N'mds_getRepositoryVersion', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_getRepositoryVersion
END
go

create FUNCTION mds_getRepositoryVersion() RETURNS $(MDS_VARCHAR)($(MDS_VERSION))
AS
BEGIN
  RETURN '$(REPOS_VERSION)';
END
go


--
-- Purges document versions from the shredded content tables.
-- See mds_internal.purgeMetadata() for more details of the purge
-- algorithm.
--
-- Parameters  
--  numVersionsPurged - Out parameter indicating number of versions purged
--  partitionID       - PartitionID for the repository partition
--  purgeCompareTime  - Creation time prior to which versions can be purged
--  isAutoPurge       - 0 if manual purge and 1 if auto-purge
--  commitNumber      - Commit number used for purging path and content tables
--
IF (object_id(N'mds_purgeMetadata', N'P') IS NOT NULL)
BEGIN
  DROP PROCEDURE mds_purgeMetadata
END
go
create  PROCEDURE mds_purgeMetadata(@numVersionsPurged  NUMERIC OUTPUT,
                                    @partitionID        NUMERIC,                          
                                    @purgeCompareTime   DATETIME,
                                    @secondsToLive      NUMERIC,
                                    @isAutoPurge        NUMERIC,
				    @commitNumber       NUMERIC OUTPUT)
AS
BEGIN
  -- This will populate mds_purge_data table with the data for paths
  -- that can be purged
  EXEC mds_internal_purgeMetadata @numVersionsPurged OUTPUT, @partitionID, 
       @purgeCompareTime, @secondsToLive, @isAutoPurge, @commitNumber OUTPUT;

  -- Delete attributes of the purged versions
  DELETE FROM MDS_ATTRIBUTES 
    WHERE ATT_PARTITION_ID = @partitionID
    AND ATT_CONTENTID IN
      (SELECT PPATH_CONTENTID FROM MDS_PURGE_PATHS
        WHERE PPATH_PARTITION_ID = @partitionID);

  -- Delete components of the purged versions
  DELETE FROM MDS_COMPONENTS
    WHERE COMP_PARTITION_ID = @partitionID
    AND COMP_CONTENTID IN
      (SELECT PPATH_CONTENTID FROM MDS_PURGE_PATHS
         WHERE PPATH_PARTITION_ID = @partitionID);
         
  -- Cleanup the purge_paths table since it is a regular table.
  --
  -- Oracle implementation uses a temporary table and the data is deleted
  -- automatically on commit, but we could not use temporary tables for 
  -- SQLServer since the table itself is dropped after the connection
  -- (which would force us to create it in internal_purgeMetadata)
  DELETE FROM MDS_PURGE_PATHS WHERE PPATH_PARTITION_ID = @partitionID;
  
END
go

-- Used in the queryapi. The attr_value column contains both strings and
-- number values in a varchar. In the query api we need to be able to
-- complete number and string comparisions against the values in the column.
-- However if we use to_number() on the column the string values are going to
-- fall over in a big heap and give the invalid number exception.
-- This function allows us to handle this scenario more gracefully.
-- ie   to_number('29') works
-- to_number('sugar') -- in this case return null.
--
IF (object_id(N'mds_toNumber', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_toNumber
END
go

create FUNCTION mds_toNumber(@attribute_value $(MDS_VARCHAR)(100)) RETURNS NUMERIC 
AS
BEGIN
  DECLARE @attribute_value_number    NUMERIC

  IF (@attribute_value IS NULL) OR (ISNUMERIC(@attribute_value) <> 1)
      RETURN NULL;

  RETURN convert(NUMERIC, @attribute_value);
END
go

-- Used in the queryapi. The text condition needs to trim the whitespace
-- (blanks, newlines, carriagereturns and tabs) from the stored text values.
--
IF (object_id(N'mds_trimWhite', N'FN') IS NOT NULL)
BEGIN
  DROP FUNCTION mds_trimWhite
END
go

create FUNCTION mds_trimWhite(@text_value $(MDS_VARCHAR)($(VALUE))) RETURNS $(MDS_VARCHAR)($(VALUE)) 
AS
BEGIN
  DECLARE @start    INT
  DECLARE @end      INT
  DECLARE @nonwhite $(MDS_VARCHAR)(10)
  
  IF @text_value IS NULL
    RETURN NULL;
  
  -- Set nonwhite to not match any whitespace character:
  -- not blank, horizontal tab, new line, carriage return.
  SET @nonwhite = '[^ ' + NCHAR(9) + NCHAR(10) + NCHAR(13) + ']';

  SET @start = PATINDEX('%' + @nonwhite + '%', @text_value);
  IF @start = 0
    RETURN '';      -- text_value is all whitespace.

  SET @end = LEN(@text_value);
  WHILE @end > @start
  BEGIN
    IF SUBSTRING(@text_value, @end, 1) LIKE @nonwhite
      BREAK;
    SET @end = @end - 1;
  END
  
  RETURN SUBSTRING(@text_value, @start, @end - @start + 1);
END
go

-- commit transaction mdsinsr
go
