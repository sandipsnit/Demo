Rem
Rem dropmdsvpd.sql
Rem
Rem Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 
Rem
Rem    NAME
Rem      cremdsvpd.sql - SQL script to drop MDS VPD policy for multitenancy
Rem
Rem    DESCRIPTION
Rem      This script drops read/write VPD policies on all MDS schema tables
Rem      that have enterprise_id defined.
Rem
Rem    NOTES
Rem      The logon user must have execute privilege on dbms_rls in order to
Rem      run this script.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    erwang      09/01/11 - Skip policy creation if VPD is not supported
Rem    jhsi        06/01/11 - Created
Rem


SET VERIFY OFF
SET SERVEROUTPUT ON

REM Drop the VPD policies on MDS tables if exist

DECLARE
    policyName    user_policies.policy_name%TYPE;
    objectName    user_policies.object_name%TYPE;
    vpdAvailable  VARCHAR2(64);
    err_msg       VARCHAR2(1000);
    err_num       NUMBER;
    CURSOR c_get_policies IS SELECT object_name, policy_name
       FROM all_policies WHERE policy_name LIKE 'MDS_%'
       AND object_owner = SYS_CONTEXT('USERENV','SESSION_SCHEMA')
       AND object_name LIKE 'MDS_%';
BEGIN
  BEGIN
      -- Skip policy creation if VPD is not supported.
      SELECT value INTO vpdAvailable FROM v$option
               WHERE parameter = 'Fine-grained access control';
      IF ( vpdAvailable <> 'TRUE' ) THEN
          RETURN;
      END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN;
    WHEN OTHERS THEN
        -- Reraise the exception.
        RAISE;
  END;

  OPEN c_get_policies;
  LOOP
     FETCH c_get_policies INTO objectName, policyName;
     EXIT WHEN c_get_policies%NOTFOUND;
    
     BEGIN
        DBMS_RLS.DROP_POLICY (
      		object_schema    => SYS_CONTEXT('USERENV','SESSION_SCHEMA'),
      		object_name      => objectName,       
      		policy_name      => policyName
     	);
        DBMS_OUTPUT.PUT_LINE('Policy ' || policyName || ' dropped.');
        
     EXCEPTION
        WHEN OTHERS THEN
            err_num := SQLCODE;
            err_msg := SUBSTR(SQLERRM, 1, 1000);
            DBMS_OUTPUT.PUT_LINE('Exception while dropping policy '
                                   || policyName || ' ex = ' || err_msg);
     END;
  END LOOP;
  CLOSE c_get_policies;

  COMMIT;
  
END;
/
