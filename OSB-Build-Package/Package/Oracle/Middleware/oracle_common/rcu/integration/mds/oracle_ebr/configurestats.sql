Rem
Rem configurestats.sql
Rem
Rem Copyright (c) 2011, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      configurestats.sql -  SQL script to configure dbms_stats preferences.
Rem
Rem    DESCRIPTION
Rem      This script sets the dbms_stats preferences on EBR MDS schema tables.
Rem
Rem    NOTES
Rem      Using conditional compilation selection directives ($IF,$ELSE,$END)
Rem      to skip the configuration on Oracle database prior to 11.2.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jhsi        02/20/12 - Conditional compilation of dbms_db_version check
Rem    jhsi        10/24/11 - Created
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

Rem
Rem Disable the histogram collection on PATH_FULLNAME column on MDS_PATHS table
Rem and explicitly lock the bucket size for this column to 1 using features
Rem supported in Oracle database 11.2 to ensure optimal execution plans.
Rem
DECLARE
  schemaName   ALL_USERS.USERNAME%TYPE;
BEGIN
  $IF DBMS_DB_VERSION.VER_LE_10 $THEN
    RETURN;
  $ELSIF DBMS_DB_VERSION.VER_LE_11_1 $THEN
    RETURN;
  $ELSE
    schemaName := SYS_CONTEXT('USERENV','SESSION_SCHEMA');
    DBMS_STATS.DELETE_COLUMN_STATS(
      ownname       => schemaName,
      tabname       =>'MDS_PATHS_T',
      colname       =>'PATH_FULLNAME',
      col_stat_type =>'HISTOGRAM'
    );

    DBMS_STATS.SET_TABLE_PREFS(
      schemaName,
      'MDS_PATHS_T',
      'METHOD_OPT',
      'FOR ALL COLUMNS SIZE AUTO, FOR COLUMNS SIZE 1 PATH_FULLNAME'
    );
  $END
END;
/

COMMIT;
