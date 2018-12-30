-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- droptabs.sql - MDS metadata services Drop MDS table objects.
--
-- NOTE: This is called during schema creation to drop all schema objects that hold
--      user-defined data: tables and sequences. This is not called during upgrades.
--
-- MODIFIED    (MM/DD/YY)
-- erwang      09/30/11 - Fix case issue of @sql variable.
-- erwang      03/22/11 - Change delimiter to /
-- erwang      11/24/10 - Created.
--

-- Make sure that the procedure doesn't exist at this moment
drop procedure if exists dropSchemaTables
/

-- Drop all tables under current schemas.
CREATE PROCEDURE dropSchemaTables()
BEGIN
   DECLARE EXIT HANDLER FOR SQLEXCEPTION 
   BEGIN
   END;

   SET @@group_concat_max_len=16000;
    
   SELECT @sql := concat('drop table ', group_concat(TABLE_NAME))
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE' AND 
              TABLE_SCHEMA = SCHEMA();

   IF @sql IS NOT NULL THEN
       PREPARE dropStmt FROM @sql;

       EXECUTE dropStmt;

       DEALLOCATE PREPARE dropStmt;
   END IF;

END
/

call dropSchemaTables()
/

drop procedure if exists dropSchemaTables
/

