--
--
-- Copyright (c) 2012, Oracle and/or its affiliates. All rights reserved. 
-- All rights reserved. 
--
--    NAME
--      upgmds.sql - SQL script to upgrade MDS repository on MySQL
-- 
--    DESCRIPTION
--     This file upgrades indexes and stored procedures for the MDS
--     repository.
-- 
--    MODIFIED   (MM/DD/YY)
--    dibhatta    03/07/12 - #(13786597) Created
--

-- create procedures
source mdsinc.sql
source mdsinsr.sql
-- #(12859728) Add MOType index for query.

-- Drop any new indexes under current schema.
-- This makes the upgrade idempotent.
drop procedure if exists dropSchemaIndexes
/

CREATE PROCEDURE dropSchemaIndexes()
BEGIN 
    DECLARE done INT DEFAULT 0;
    DECLARE tabname VARCHAR(64);
    DECLARE indname VARCHAR(64);
    DECLARE c1 CURSOR FOR
        SELECT DISTINCT TABLE_NAME,INDEX_NAME 
              FROM INFORMATION_SCHEMA.STATISTICS
              WHERE INDEX_SCHEMA = SCHEMA()
                    AND INDEX_NAME = 'MDS_PATHS_N9'; 
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    OPEN c1;
    FETCH c1 INTO tabname, indname;
    WHILE done = 0 DO 
        SELECT @sql := concat('drop index ', indname, ' on ', tabname);
        PREPARE dropStmt FROM @sql;
        EXECUTE dropStmt;
        DEALLOCATE PREPARE dropStmt;
        FETCH c1 INTO tabname, indname;
    END WHILE;
    CLOSE c1; 
END
/
call dropSchemaIndexes
/
drop procedure dropSchemaIndexes
/

create INDEX MDS_PATHS_N9
  on MDS_PATHS ( PATH_DOC_ELEM_NAME, PATH_PARTITION_ID )
/


