-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- dropmds.sql - MDS metadata services Drop MDS schema objects.
--
-- NOTE: This script does not drop tables. It is called for
--       both upgrade and create schema operations. See droptabs.sql for
--       the script to drop tables.
--
-- MODIFIED    (MM/DD/YY)
-- erwang       03/22/11  - Change delimiter to /
-- erwang       01/19/11  - Create.
--


drop procedure if exists dropSchemaIndexes
/

-- Drop all indexes under current schemas for current owner
CREATE PROCEDURE dropSchemaIndexes()
BEGIN 

    DECLARE done INT DEFAULT 0;

    DECLARE tabname VARCHAR(64);
    DECLARE indname VARCHAR(64);

    DECLARE c1 CURSOR FOR
        SELECT DISTINCT TABLE_NAME,INDEX_NAME 
              FROM INFORMATION_SCHEMA.STATISTICS
              WHERE INDEX_SCHEMA = SCHEMA()
                    AND INDEX_NAME LIKE 'MDS%'; 

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


