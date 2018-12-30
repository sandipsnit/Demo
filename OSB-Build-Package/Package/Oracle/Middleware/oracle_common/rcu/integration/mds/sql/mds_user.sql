Rem
Rem $Header: jtmds/src/dbschema/oracle/mds_user.sql /st_jdevadf_patchset_ias/5 2012/10/05 11:12:18 pwhaley Exp $
Rem
Rem mds_user.sql
Rem
Rem Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      mds_user.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    pwhaley     10/04/12 - XbranchMerge pwhaley_bug-14668815 from main
Rem    pwhaley     10/03/12 - #(14668815) Use quotes around password.
Rem    erwang      10/08/10 - #(10135627) Replaced RESOURCE role with
Rem                           individual privileges.
Rem    erwang      10/05/10 - XbranchMerge erwang_bug-10171810 from main
Rem    erwang      10/05/10 - #(10171810) Fixed an Oracle error message referred in comments
Rem    erwang      10/01/10 - XbranchMerge erwang_bug-10150062 from main
Rem    erwang      09/30/10 - #(10150062) Check if public has priviledge to
Rem                           dbms_lob and dbms_output package before granting.
Rem    vyerrama    04/01/10 - #(9207217) Added grants for dbms_lob and dbms_output
Rem    vyerrama    01/27/10 - XbranchMerge vyerrama_bug-9207217 from main
Rem    abhatt      07/10/07 - #(6135856) Remove execute on dbms_lock privilege
Rem    rnanda      08/14/06 - Created
Rem

CREATE USER &&1 IDENTIFIED BY "&&2" DEFAULT TABLESPACE &&3 TEMPORARY TABLESPACE &&4;
GRANT connect TO &&1;
GRANT create type TO &&1;
GRANT create procedure TO &&1;
GRANT create table TO &&1;
GRANT create sequence TO &&1;

-- Grant the user unlimited quota to the tablespace.
ALTER USER &&1 QUOTA unlimited ON &&3;

DECLARE
    cnt           NUMBER;

    package_not_found EXCEPTION;
    PRAGMA EXCEPTION_INIT(package_not_found, -00942);

    insufficient_privs EXCEPTION;
    PRAGMA EXCEPTION_INIT(insufficient_privs, -01031);
BEGIN

    cnt := 0;
    SELECT count(*) INTO cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC'
               AND owner='SYS' AND table_name='DBMS_OUTPUT'
               AND privilege='EXECUTE';
    IF (cnt = 0) THEN
        -- Grant MDS user execute on dbms_output only if PUBLIC
        -- doesn't have the privilege.
        EXECUTE IMMEDIATE 'GRANT execute ON dbms_output TO &&1';
    END IF;

    cnt := 0;
    SELECT count(*) INTO cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC'
               AND owner='SYS' AND table_name='DBMS_LOB'
               AND privilege='EXECUTE';
    IF (cnt = 0) THEN
        -- Grant MDS user execute on dbms_lob only if PUBLIC
        -- doesn't have the privilege.
        EXECUTE IMMEDIATE 'GRANT execute ON dbms_lob TO &&1';
    END IF;
   
    EXCEPTION
       -- If the user doesn't have privilege to access dbms_* package,
       -- database will report that the package cannot be found. RCU
       -- even doesn't throw the exception to the user, since ORA-00942
       -- is an ignored error defined in its global configuration xml
      -- file. 
       WHEN package_not_found THEN
           RAISE insufficient_privs;
       WHEN OTHERS THEN
           RAISE;
END;
/
