Rem
Rem $Header: adfc/modules/adf-controller-api/bin/adfc_create_save_point_table.sql /st_jdevadf_patchset_ias/1 2011/05/19 12:07:52 mjakobis Exp $
Rem
Rem adfc_create_save_point_table.sql
Rem
Rem Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 
Rem
Rem    NAME
Rem      adfc_create_save_point_table.sql
Rem
Rem    DESCRIPTION
Rem      SQL creation script for ADFc save point table - ORADFCSAVPT
Rem
Rem    COMMAND
Rem      
Rem      @adfc_create_save_point_table.sql <<TXN_USER_ID>>
Rem
Rem      <<TXN_USER_ID>> - The user id to grant permissions to insert/update records in the
Rem                        above objects. For example, FUSION_RUNTIME
Rem

set echo off

CREATE OR REPLACE PROCEDURE save_point_table_grant_perms
(
    p_username      IN     VARCHAR2
)
IS
BEGIN
  if p_username = sys_context('USERENV', 'CURRENT_USER') then
     dbms_output.put_line('User already has privilege');
     return;
  else
     dbms_output.put_line('Granting permissions to ' || p_username);
     execute immediate 'GRANT SELECT, UPDATE, INSERT, DELETE ON ORADFCSAVPT TO ' || p_username;
  end if;
END;
/

Rem uncomment the following block and comment the next block to prompt the user for the username
Rem accept txn_tab_user default &_USER prompt 'Please enter a user to grant permissions for the ORADFCSAVPT [&_USER]: '

define txn_tab_user = &1 ;


Rem drop table ORADFCSAVPT
/

create table ORADFCSAVPT
     (
     SAVE_POINT_ID          varchar2(64) NOT NULL,
     CREATED                date DEFAULT sysdate NOT NULL,
     OWNER_ID               varchar2(64),
     VERSION                varchar2(20),
     DESCRIPTION            varchar2(250),
     EXPIRE_DT              date,
     SAVE_POINT             blob,
     constraint ORADFCSAVPT_PK primary key (SAVE_POINT_ID)
     )
storage (maxextents unlimited) lob (SAVE_POINT) store as (enable storage in row chunk 4096 cache)
/
create index ORADFCSAVPT_F1 on ORADFCSAVPT (OWNER_ID ASC)
/
call save_point_table_grant_perms('&txn_tab_user')
/
drop procedure save_point_table_grant_perms


