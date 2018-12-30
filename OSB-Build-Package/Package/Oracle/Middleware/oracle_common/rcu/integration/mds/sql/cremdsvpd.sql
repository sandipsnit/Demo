Rem
Rem cremdsvpd.sql
Rem
Rem Copyright (c) 2011, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      cremdsvpd.sql - SQL script to create MDS VPD policy for multitenancy
Rem
Rem    DESCRIPTION
Rem      This script adds read/write VPD policies to all MDS schema tables
Rem      that have enterprise_id defined.
Rem
Rem    NOTES
Rem      The logon user must have execute privilege on dbms_rls in order to
Rem      run this script.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jhsi        11/02/11 - #(13337546) Optimized VPD policies
Rem    jhsi        09/16/11 - Added MDS_METADATA_DOCS table
Rem    erwang      09/01/11 - Skip policy creation if VPD is not supported
Rem    jhsi        06/01/11 - Created
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

Rem Drop the VPD policies if exist 
@@dropmdsvpd


Rem Create the VPD policy on MDS Schema tables 
DECLARE
  schemaName   all_policies.object_owner%TYPE;
  vpdAvailable VARCHAR2(64);
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


  schemaName := SYS_CONTEXT('USERENV','SESSION_SCHEMA');
  -- Add read policies
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_paths',       
    policy_name      => 'mds_paths_read',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdReadPolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'select'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_depl_lineages',       
    policy_name      => 'mds_depl_lineages_read',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdReadPolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'select'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_labels',       
    function_schema  => schemaName,
    policy_name      => 'mds_labels_read',
    policy_function  => 'mds_internal_common.vpdReadPolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'select'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_streamed_docs',       
    policy_name      => 'mds_streamed_docs_read',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdReadPolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'select'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_metadata_docs',       
    policy_name      => 'mds_metadata_docs_read',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdReadPolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'select'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_dependencies',       
    policy_name      => 'mds_dependencies_read',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdReadPolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'select'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_sandboxes',       
    policy_name      => 'mds_sandboxes_read',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdReadPolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'select'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_components',       
    policy_name      => 'mds_components_read',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdReadPolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'select'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_attributes',       
    policy_name      => 'mds_attributes_read',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdReadPolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'select'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_large_attributes',       
    policy_name      => 'mds_large_attributes_read',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdReadPolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'select'
   );
  -- Add write policy
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_paths',       
    policy_name      => 'mds_paths_write',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdWritePolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'update, insert, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_depl_lineages',       
    policy_name      => 'mds_depl_lineages_write',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdWritePolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'update, insert, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_labels',       
    policy_name      => 'mds_labels_write',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdWritePolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'update, insert, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_streamed_docs',       
    policy_name      => 'mds_streamed_docs_write',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdWritePolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'update, insert, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_metadata_docs',       
    policy_name      => 'mds_metadata_docs_write',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdWritePolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'update, insert, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_dependencies',       
    policy_name      => 'mds_dependencies_write',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdWritePolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'update, insert, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_sandboxes',       
    policy_name      => 'mds_sandboxes_write',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdWritePolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'update, insert, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_components',       
    policy_name      => 'mds_components_write',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdWritePolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'update, insert, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_attributes',       
    policy_name      => 'mds_attributes_write',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdWritePolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'update, insert, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => schemaName,      
    object_name      => 'mds_large_attributes',       
    policy_name      => 'mds_large_attributes_write',
    function_schema  => schemaName,
    policy_function  => 'mds_internal_common.vpdWritePolicy',
    policy_type      => dbms_rls.SHARED_STATIC,
    statement_types  => 'update, insert, delete'
   );
END;
/

COMMIT;
