
/*===================================================================*/
-- Copyright (c) 2009, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- WARNING: 
-- These utilities should NOT be used with production code. They are provided
-- as a convenience for debugging/diagnostic purposes.
-- 
-- MDSUTINS.pls - MDS UTILities INternal Specification.
--
-- MODIFIED    (MM/DD/YY)
-- erwang       11/26/12  - #(15917739) Removed user/pwd in modification history
-- erwang       06/04/12  - XbranchMerge erwang_bug-13110517 from main
-- erwang       05/15/12  - #(13110517) Don't expose user/password in the sample
-- rupandey     02/09/09  - #(8218775) Inserted an empty line at the begining of 
--                          this file until rcu fixes #(8215729).
-- rupandey     01/10/09  - Restored some methods from the original. Added 
--                          a new method - listPartitions.
-- enewman      05/16/03  - Creation
--
/*===================================================================*/

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE mds_internal_utils AS


  -----------------------------------------------------------------------------
  ---------------------------- PUBLIC VARIABLES -------------------------------
  -----------------------------------------------------------------------------
  MAX_LINE_SIZE CONSTANT NUMBER := 255;

  -----------------------------------------------------------------------------
  ------------------------------ PUBLIC TYPES ---------------------------------
  -----------------------------------------------------------------------------

  -- Exception raised when document does not exist
  no_such_document EXCEPTION;

  -----------------------------------------------------------------------------
  ---------------------------- PUBLIC FUNCTIONS -------------------------------
  -----------------------------------------------------------------------------

  -- Prints the contents of a package.
  --
  -- For the non-recursive case, this will list the documents,
  -- package files and package directories.
  --
  -- For the recursive case, this will list the document, package files
  -- and empty package directories (i.e. packages which contain no documents
  -- or child packages).
  --
  -- In order to diferentiate documents from package directories, package
  -- directories will end with a '/'.
  --
  -- Parameters:
  --  partitionName- the partition where the package exists
  --  p_path       - The path in which to list the documents.  To specify
  --                 the root directory, use '/'.
  --
  --  p_recursive  - If TRUE, recursively lists the contents of
  --                 sub-directories.  Defaults to FALSE.
  --
  -- To use this from SQL*Plus, do:
  --
  -- (1) set serveroutput on
  --     execute mds_utils.listContents('/oracle/apps/ak');
  --     This will list the contents of the ak directory, without showing
  --     the contents of the sub-directories.
  --
  -- (2) set serveroutput on
  --     execute mds_utils.listContents('/', TRUE);
  --     This will list the contents of the entire repository.
  --     sub-directories.
  --
  PROCEDURE listContents(partitionName  VARCHAR2,
                         p_path         VARCHAR2,                         
                         p_recursive    BOOLEAN DEFAULT FALSE);



  -- Prints the contents of a document to the console.
  --
  -- Parameters:
  --  partitionName - the partition where the document exists
  --  p_document    - the fully qualified document name
  --                  (i.e.  '/oracle/apps/ak/attributeSets')
  --
  --  p_maxLineSize - the maximum size of line.  This defaults to 255 which is
  --                  the maximim allowable size of a line (the 255 limit is
  --                  a limitation of the DBMS_OUPUT package).
  --
  -- Limitations:
  --  Documents larger than 1000000 bytes will fail as DBMS_OUPUT's maximim
  --  buffer is 1000000 bytes.
  --
  -- To use this from SQL*Plus, do:
  --   set serveroutput on format wrapped (this is needed for leading spaces)
  --   set linesize 100
  --   execute mds_utils.printDocument('/oracle/apps/ak/attributeSets', 100);
  --
  -- To create an XML file, you can create the following SQL file:
  --   set feedback off
  --   set serveroutput on format wrapped
  --   set linesize 100
  --   spool (parameter 1)
  --   execute mds_utils.printDocument('(parameter 2)', 100);
  --   spool off
  --
  -- and call the file with:
  --   sqlplus <schema name>/<password> @export.sql 
  --               myxml.xml /oracle/apps/ak/attributeSets
  PROCEDURE printDocument(partitionName VARCHAR2,
                          p_document    VARCHAR2,
			  p_versionNum  NUMBER DEFAULT NULL,		
                          p_maxLineSize NUMBER DEFAULT MAX_LINE_SIZE);

  
  -- List the names of all partitions that currently exist in the repository.
  --
  PROCEDURE listPartitions;


END;
/

COMMIT;
