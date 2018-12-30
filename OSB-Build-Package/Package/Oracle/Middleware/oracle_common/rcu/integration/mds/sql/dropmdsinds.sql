-- Copyright (c) 2009, 2010, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- DROPMDSINDS.SQL - DROP MDS INDexeS
-- 
-- MODIFIED    (MM/DD/YY)
-- gnagaraj     12/03/09   - Add indexes for lineage table
-- akrajend     08/18/09  -  Use MDS_% pattern to drop indexes.
-- gnagaraj     08/17/09  -  Created by refactoring cremdsinds.sql. 
--

SET VERIFY OFF
SET SERVEROUTPUT ON

REM Drop MDS repository indexes

DECLARE
    indexName     user_indexes.index_name%TYPE;
    sqlStmt       VARCHAR2(100);
    err_msg       VARCHAR2(1000);
    err_num       NUMBER;
    CURSOR c_get_indexes IS SELECT index_name
       FROM user_indexes WHERE index_name LIKE 'MDS_%'
       AND table_name LIKE 'MDS_%';
BEGIN
  
  OPEN c_get_indexes;
  LOOP
     FETCH c_get_indexes INTO indexName;
     EXIT WHEN c_get_indexes%NOTFOUND;
    
     BEGIN
        sqlStmt := 'DROP INDEX ' || indexName;
        EXECUTE IMMEDIATE(sqlStmt);
        DBMS_OUTPUT.PUT_LINE('Index ' || indexName || ' dropped.');
        
     EXCEPTION
        WHEN OTHERS THEN
            err_num := SQLCODE;
            err_msg := SUBSTR(SQLERRM, 1, 1000);
            DBMS_OUTPUT.PUT_LINE('Exception while dropping index '
                                   || indexName || ' ex = ' || err_msg);
     END;
  END LOOP;
  CLOSE c_get_indexes;

  COMMIT;
  
END;
/
