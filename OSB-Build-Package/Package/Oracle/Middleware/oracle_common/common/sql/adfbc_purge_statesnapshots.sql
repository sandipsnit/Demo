Rem
Rem $Header: $
Rem
Rem  Copyright (c) 2000 by Oracle Corporation
Rem
Rem    NAME
Rem      bc4jcleanup.sql - Utilities to clean temporary BC4J storage
Rem
Rem    DESCRIPTION
Rem
Rem      This package contains procedures to clean out rows
Rem      in the database used by BC4J to store user session state
Rem      and storage used by temporary persistent collections.
Rem
Rem    NOTES
Rem
Rem      You can schedule periodic cleanup of your BC4J temporary
Rem      persistence storage by submitting an invocation of the
Rem      appropriate procedure in this package as a database job.
Rem
Rem      You can use an anonymous PL/SQL block like the following
Rem      to schedule the execution of bc4j_cleanup.session_state()
Rem      to run starting tomorrow at 2:00am and each day thereafter
Rem      to cleanup sessions whose state is over 1 day (1440 minutes) old.
Rem
Rem     SET SERVEROUTPUT ON
Rem     DECLARE
Rem       jobId    BINARY_INTEGER;
Rem       firstRun DATE;
Rem     BEGIN
Rem     -- Start the job tomorrow at 2am
Rem     firstRun := TO_DATE(TO_CHAR(SYSDATE+1,'DD-MON-YYYY')||' 02:00',
Rem                 'DD-MON-YYYY HH24:MI');
Rem
Rem     -- Submit the job, indicating it should repeat once a day
Rem     dbms_job.submit(job       => jobId,
Rem                     -- Run the BC4J Cleanup for Session State
Rem                     -- to cleanup sessions older than 1 day (1440 minutes)
Rem                     what      => 'bc4j_cleanup.session_state(1440);',
Rem                     next_date => firstRun,
Rem                     -- When completed, automatically reschedule
Rem                     -- for 1 day later
Rem                     interval  => 'SYSDATE + 1'
Rem                    );
Rem     dbms_output.put_line('Successfully submitted job. Job Id is '||jobId);
Rem    END;
Rem
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem     jsmiljan   05/02/01 -  Added support for custom snapshot object names
Rem     smuench    12/07/01 -  Update for PColl Changes
Rem     smuench    09/06/00 -  Creation
Rem

define def_control_tab_name = PCOLL_CONTROL
define def_txn_tab_name = PS_TXN
define def_txn_seq_name = PS_TXN_seq

accept control_tab_name default &def_control_tab_name prompt 'Please enter a control table name [&def_control_tab_name]:  '

accept txn_tab_name default &def_txn_tab_name prompt 'Please enter a txn table name [&def_txn_tab_name]:  '

accept txn_seq_name default &def_txn_seq_name prompt 'Please enter a txn sequence name [&def_txn_seq_name]:  '

CREATE OR REPLACE PACKAGE bc4j_cleanup IS
  --
  -- Cleanup application module session state storage for sessions
  -- older than a given date.
  --
  PROCEDURE Session_State( olderThan         DATE  );
  --
  -- Cleanup application module session state storage for sessions
  -- older than a given number of minutes.
  --
  PROCEDURE Session_State( olderThan_minutes INTEGER );
  --
  -- Cleanup persistent collection storage for large-rowset
  -- "spillover" for collections last accessed before a given date
  --
  PROCEDURE Persistent_Collections( olderThan DATE );
  --
  -- Cleanup persistent collection storage for large-rowset
  -- "spillover" for collections last accessed a given number of days ago.
  --
  PROCEDURE Persistent_Collections( olderThan_days NUMBER );
END bc4j_cleanup;
.
/
show errors
CREATE OR REPLACE PACKAGE BODY bc4j_cleanup IS
  row_already_locked EXCEPTION;
  table_not_found    EXCEPTION;
  PRAGMA EXCEPTION_INIT(row_already_locked,-54);
  PRAGMA EXCEPTION_INIT(table_not_found,-942);
  TYPE ref_cursor IS REF CURSOR;
  cur_Rowid               ROWID;
  MINUTES_IN_DAY CONSTANT INTEGER := 1440;
  sessCursorStmt CONSTANT VARCHAR2(80) :=
     'SELECT rowid AS id FROM &txn_tab_name WHERE creation_date < :minDate';
  lockCursorStmt CONSTANT VARCHAR2(80) :=
     'SELECT 2 FROM &txn_tab_name WHERE rowid = :theRowid FOR UPDATE NOWAIT';
  deleteCursorStmt CONSTANT VARCHAR2(80) :=
     'DELETE FROM &txn_tab_name WHERE rowid = :theRowid';
  pcollCursorStmt CONSTANT VARCHAR2(90) :=
     'SELECT rowid AS id FROM &control_tab_name WHERE updatedate < :minDate'||
     ' and tabname <> ''&txn_tab_name''';
  pcollLockCursorStmt CONSTANT VARCHAR2(90) :=
     'SELECT TABNAME FROM &control_tab_name WHERE rowid = :id FOR UPDATE NOWAIT';
  pcollDeleteCursorStmt CONSTANT VARCHAR2(80) :=
     'DELETE FROM &control_tab_name WHERE rowid = :theRowid';
  PROCEDURE Session_State( olderThan DATE  ) IS
    cur_Session ref_cursor;
    cur_Lock    ref_cursor;
    tmpval      NUMBER;
  BEGIN
    OPEN cur_Session FOR sessCursorStmt USING olderThan;
    LOOP
      FETCH cur_Session INTO cur_Rowid;
      EXIT WHEN cur_Session%NOTFOUND;
        BEGIN
          OPEN cur_Lock FOR lockCursorStmt USING cur_Rowid;
          FETCH cur_Lock INTO tmpval;
          CLOSE cur_Lock;
          EXECUTE IMMEDIATE deleteCursorStmt USING cur_Rowid;
          COMMIT;
        EXCEPTION
          WHEN row_already_locked THEN
            CLOSE cur_Lock; -- Just ignore rows that we cannot lock
        END;
    END LOOP;
  EXCEPTION
    WHEN table_not_found THEN
      NULL; -- Ignore if &txn_tab_name table not found
  END;

  PROCEDURE Session_State( olderThan_minutes INTEGER ) IS
  BEGIN
    -- Ignore negative values for olderThan_minutes
    IF olderThan_minutes < 0 THEN
      RETURN;
    END IF;
    Session_State( SYSDATE - olderThan_minutes/MINUTES_IN_DAY );
  END;

  PROCEDURE Persistent_Collections( olderThan DATE ) IS
    cur_PCollControl ref_cursor;
    cur_Lock         ref_cursor;
    spillTableName   VARCHAR2(80);
  BEGIN
    OPEN cur_PCollControl FOR pcollCursorStmt USING olderThan;
    LOOP
      FETCH cur_PCollControl INTO cur_Rowid;
      EXIT WHEN cur_PCollControl%NOTFOUND;
        BEGIN
          -- Lock the "old" PColl Control Row, selecting spill-over table name
          OPEN cur_Lock FOR pcollLockCursorStmt USING cur_Rowid;
          FETCH cur_Lock INTO spillTableName;
          CLOSE cur_Lock;
          -- Delete the row keeping track of temporary spill-over table
          EXECUTE IMMEDIATE pcollDeleteCursorStmt USING cur_Rowid;
          -- Drop the temporary spill-over table
          EXECUTE IMMEDIATE 'drop table "'||spillTableName||'"';
          -- Drop the temporary spill-over table's key table
          EXECUTE IMMEDIATE 'drop table "'||spillTableName||'_ky"';
          COMMIT;
        EXCEPTION
          WHEN row_already_locked THEN
            CLOSE cur_Lock; -- Just ignore rows that we cannot lock
        END;
    END LOOP;
  EXCEPTION
    WHEN table_not_found THEN
      NULL; -- Ignore if &control_tab_name table not found
  END;

  PROCEDURE Persistent_Collections( olderThan_days NUMBER ) IS
  BEGIN
    -- Ignore negative values for olderThan_days
    IF olderThan_days < 0 THEN
      RETURN;
    END IF;
    Persistent_Collections( SYSDATE - olderThan_days );
  END;
END bc4j_cleanup;
.
/
show errors
