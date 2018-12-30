Rem
Rem $Header: adfc/modules/adf-controller-api/bin/adfc_cleanup_save_point_table.sql /st_jdevadf_patchset_ias/1 2011/05/19 12:07:52 mjakobis Exp $
Rem
Rem adfc_cleanup_save_point_table.sql
Rem
Rem Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 
Rem
Rem    NAME
Rem      adfc_cleanup_save_point_table.sql
Rem
Rem    DESCRIPTION
Rem      SQL cleanup script for ADFc save point table - ORADFCSAVPT
Rem      This script is basend on bc4jcleabup.sql written by smuench,
Rem      and all the credit should go to him.
Rem
Rem


CREATE OR REPLACE PACKAGE adfc_cleanup IS
  --
  -- Delete save points older than expiration date from ORADFCSAVPT table
  --
  PROCEDURE deleteExpiredSavePoints;
END adfc_cleanup;
.
/
show errors

CREATE OR REPLACE PACKAGE BODY adfc_cleanup IS
  row_already_locked EXCEPTION;
  table_not_found    EXCEPTION;
  PRAGMA EXCEPTION_INIT(row_already_locked,-54);
  PRAGMA EXCEPTION_INIT(table_not_found,-942);
  TYPE ref_cursor IS REF CURSOR;
  cur_Rowid               ROWID;
  savePointCursorStmt CONSTANT VARCHAR2(80) :=
     'SELECT rowid AS id FROM ORADFCSAVPT WHERE EXPIRE_DT <= sysdate';
  lockCursorStmt CONSTANT VARCHAR2(80) :=
     'SELECT rowid FROM ORADFCSAVPT WHERE rowid = :theRowid FOR UPDATE NOWAIT';
  deleteCursorStmt CONSTANT VARCHAR2(80) :=
     'DELETE FROM ORADFCSAVPT WHERE rowid = :theRowid';
     
  PROCEDURE deleteExpiredSavePoints IS
    cur_SavePoint ref_cursor;
    cur_Lock    ref_cursor;
    tmpval      ROWID;
  BEGIN
    OPEN cur_SavePoint FOR savePointCursorStmt;
    LOOP
      FETCH cur_SavePoint INTO cur_Rowid;
      EXIT WHEN cur_SavePoint%NOTFOUND;
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
END adfc_cleanup;

.
/
call adfc_cleanup.deleteExpiredSavePoints()
/
show errors

