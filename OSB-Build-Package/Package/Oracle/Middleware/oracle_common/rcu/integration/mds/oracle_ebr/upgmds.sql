Rem
Rem
Rem upgmds.sql
Rem
Rem Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      upgmds.sql - SQL script to upgrade MDS repository.
Rem
Rem    DESCRIPTION
Rem    This file upgrades indexes and stored procedures for the MDS
Rem    shredded repository.
Rem
Rem    NOTES
Rem    This script is replicated from the same file under oracle folder
Rem    for EBR support.
Rem    It is required to run upgmdsvpd.sql after running this script
Rem    if any schema table has been modified for adding multitenancy
Rem    support.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    dibhatta    03/07/12 - #(13786597) Created
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

Rem Recreating the package specs
@@../sql/MDSINCS.pls
@@../sql/MDSINSRS.pls
@@../sql/MDSUTINS.pls

Rem Recreating the package bodies
@@../sql/MDSINCB.plb
@@../sql/MDSINSRB.plb
@@../sql/MDSUTINB.plb

Rem Recreate changed indexes.
REM #(12859728) index for MOType condition.

DECLARE
    indexName     user_indexes.index_name%TYPE;
    sqlStmt       VARCHAR2(100);
    err_msg       VARCHAR2(1000);
    err_num       NUMBER;
    CURSOR c_get_indexes IS SELECT index_name
       FROM user_indexes WHERE index_name = 'MDS_PATHS_N9';
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


-- #(12859728) index for root element name (MOType) for query
CREATE INDEX MDS_PATHS_N9 ON MDS_PATHS_T
        ( PATH_DOC_ELEM_NAME, PATH_PARTITION_ID );

COMMIT;


Rem Setting dbms_stats preferences
@@configurestats

Rem If there were any compilations problems this will spit out the 
Rem the errors. uncomment to get errors.
Rem show errors

EXIT;
