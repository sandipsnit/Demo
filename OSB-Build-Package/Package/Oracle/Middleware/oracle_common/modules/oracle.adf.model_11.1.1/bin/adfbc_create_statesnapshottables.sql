Rem  Copyright (c) 2011 by Oracle Corporation
Rem
Rem    NAME
Rem      adfbc_create_statesnapshottables.sql - Drop/Create BC4J Snapshot Objects
Rem
Rem    DESCRIPTION
Rem
Rem      This SQL script will create the database objects that BC4J
Rem      requires to support transaction state passivation/activation
Rem      
Rem    COMMAND
Rem      
Rem      @adfbc_create_statesnapshottables.sql PS_TXN PS_TXN_SEQ 50 PCOLL_CONTROL <<TXN_USER_ID>>
Rem
Rem      PS_TXN          - The txn table stores snapshots of pending changes
Rem                        made to BC4J application module instances. The snapshot information
Rem                        is stored as an XML document that encodes the unposted changes in
Rem                        an application module instance. Only pending data changes are
Rem                        stored in the snapshot, along with information about the current
Rem                        state of active iterators (i.e. "current row" pointers information).
Rem                        The value of the COLLID column corresponds to the value returned
Rem                        by the ApplicationModule.passivateState() method.
Rem      PS_TXN_SEQ      - This sequence is used to assign the next
Rem                        persistent snapshot Id for Application Module pending state
Rem                        management.
Rem      50              - The default value with which the sequence will be incremented every time
Rem                        the framework needs a set of ids. The framework will use one id value
Rem                        for each record inserted in the PS_TXN table. A value of 50 would mean
Rem                        that the framework will increment the sequence after inserting 50 snapshots.
Rem      PCOLL_CONTROL   - The  control table maintains the list of
Rem                        the persistent collection storage tables that the BC4J runtime
Rem                        has created and functions as a concurrency control mechanism.
Rem                        When a table named TABNAME is in use for storing some active sessions
Rem                        pending state, the corresponding row in  PCOLL_CONTROL is locked.
Rem      <<TXN_USER_ID>> - The user id to grant permissions to insert/update records in the
Rem                        above objects.
Rem
Rem
Rem    NOTES
Rem
Rem      By default, BC4J will create these objects in the schema of the
Rem      internal database user the first time that the application makes
Rem      a passivation request.  This script is intended for advanced users
Rem      who require more control over the creation and naming of these objects.
Rem
Rem      This script should not be used to perform routine cleanup of the
Rem      BC4J snapshot tables as it may lead to loss of active state.  Please
Rem      see the package defined in $JDEV_HOME/BC4J/bin/bc4jcleanup.sql
Rem      for a set of procedures to cleanup stale snapshot records.
Rem
Rem      The application developer should not modify this script. The BC4J
Rem      runtime framework makes certain assumptions about the structures
Rem      of the snapshot objects.  
Rem
Rem      If the names of the database objects above are customized the
Rem      application developer should be sure to specify these custom names to
Rem      the BC4J runtime framework with the following BC4J properties:
Rem
Rem         jbo.control_table_name - The control table name
Rem         jbo.txn_table_name - The txn table name
Rem         jbo.txn_seq_name - The txn sequence name
Rem
Rem      An application developer may also specify an increment clause for the
Rem      transaction sequence.  If a sequence increment clause has been
Rem      specified then BC4J will use an in-memory cache equal to the
Rem      increment size for txn passivation ids.  This may improve passivation
Rem      performance.  If the sequence increment size is specified the
Rem      application developer should be sure to declare that size to the BC4J
Rem      runtime framework with the following BC4J property:
Rem
Rem      jbo.txn_seq_inc - A postive value indicating the txn sequence size.
Rem
Rem      If the application developer is using the bc4j_cleanup package
Rem      to administer the snapshot objects then the developer should also
Rem      reexecute that package DDL (bc4jcleanup.sql) with the custom
Rem      table name values.
Rem
Rem      Please see the following whitepaper for more information about
Rem      the database object required by BC4J:
Rem
Rem      http://otn.oracle.com/products/jdev/htdocs/bc4j/bc4j_temp_tables.html
Rem
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem     sekorupo   05/23/11 - XbranchMerge sekorupo_bug-12543686 from main
Rem     sekorupo   02/05/11 - XbranchMerge sekorupo_bug-11671838 from main
Rem     jsmiljan   05/02/02 - Creation
Rem     jsmiljan   12/20/03 - Added a storage clause to the transaction table.
Rem                           See performance bug 3241879.
Rem     jsmiljan   01/27/04 - Added an increment by clause to the sequence.
Rem     sekorupo   12/14/10 - Added a reverse index which helps by reducing contention 
Rem                           that can happen when the rate of inserts is high.
Rem     dbajpai    12/14/10 - Add the .sql script to JRF distribution
Rem     sekorupo   12/16/10 - Add procedure for granting permissions to the table
Rem     dbajpai    12/18/10 - Validated and updated the new .sql script to JRF.
Rem     sekorupo   01/29/11 - Create objects using script arguments.

set echo off


CREATE OR REPLACE PROCEDURE adfbc_state_tables_grant_perms (
    p_txntable      IN     VARCHAR2,
    p_txnseq        IN     VARCHAR2,
    p_controltable  IN     VARCHAR2,
    p_username      IN     VARCHAR2
)
IS
BEGIN
  if p_username = sys_context('USERENV', 'CURRENT_USER') then
     dbms_output.put_line('User already has privilege');
     return;
  else
     dbms_output.put_line('Granting permissions to ' || p_username);
     execute immediate 'GRANT SELECT, UPDATE, INSERT, DELETE ON ' || p_txntable ||  ' TO ' || p_username;
     execute immediate 'GRANT SELECT ON ' || p_txnseq ||  ' TO ' || p_username;
     execute immediate 'GRANT SELECT, UPDATE, INSERT, DELETE ON ' || p_controltable ||  ' TO ' || p_username;
  end if;
END;
/

Rem uncomment the following block and comment the next block to prompt the user for the variable values
Rem define def_adfbc_txn_tab_name = PS_TXN
Rem define def_adfbc_txn_seq_name = PS_TXN_SEQ
Rem define def_adfbc_txn_seq_increment = 50
Rem define def_adfbc_control_tab_name = PCOLL_CONTROL
Rem accept adfbc_txn_tab_name default &def_adfbc_txn_tab_name prompt 'Please enter a txn table name [&def_adfbc_txn_tab_name]:  '
Rem accept adfbc_txn_seq_name default &def_adfbc_txn_seq_name prompt 'Please enter a txn sequence name [&def_adfbc_txn_seq_name]:  '
Rem accept adfbc_txn_seq_increment default &def_adfbc_txn_seq_increment prompt 'Please enter a positive txn sequence increment [&def_adfbc_txn_seq_increment]:  '
Rem accept adfbc_control_tab_name default &def_adfbc_control_tab_name prompt 'Please enter a control table name [&def_adfbc_control_tab_name]:  '
Rem accept adfbc_txn_tab_user default &_USER prompt 'Please enter a user to grant permissions for the &adfbc_txn_tab_name [&_USER]: '

define adfbc_txn_tab_name = &1 ;
define adfbc_txn_seq_name = &2 ;
define adfbc_txn_seq_increment = &3 ;
define adfbc_control_tab_name = &4 ;
define adfbc_txn_tab_user = &5 ;

define adfbc_txn_tab_index_suffix = _INDEX ;
define adfbc_pk_suffix = _PK ;

drop table &adfbc_txn_tab_name
/

drop sequence &adfbc_txn_seq_name
/

drop table &adfbc_control_tab_name
/

create table &adfbc_control_tab_name(
     tabname varchar2(128) NOT NULL
   , rowcreatedate date
   , createdate date
   , updatedate date
   , constraint &adfbc_control_tab_name&adfbc_pk_suffix primary key (tabname))
/

create sequence &adfbc_txn_seq_name increment by &adfbc_txn_seq_increment
/

create table &adfbc_txn_tab_name(
     id number(20) NOT NULL
   , parentid number(20)
   , collid number(10)
   , content blob
   , creation_date date DEFAULT sysdate
   , constraint &adfbc_txn_tab_name&adfbc_pk_suffix primary key (collid, id) using index (create index &adfbc_txn_tab_name&adfbc_txn_tab_index_suffix on &adfbc_txn_tab_name (collid, id) reverse))
storage (maxextents unlimited)
lob (content) store as (enable storage in row chunk 4096 cache)
/

call adfbc_state_tables_grant_perms('&adfbc_txn_tab_name', '&adfbc_txn_seq_name', '&adfbc_control_tab_name', '&adfbc_txn_tab_user')
/
drop procedure adfbc_state_tables_grant_perms
/

Rem RCU script utility does not support undefine. So prefixing the names with adfbc and commenting out
Rem the following lines

Rem undefine adfbc_control_tab_name ;
Rem undefine adfbc_txn_tab_name ;
Rem undefine adfbc_txn_seq_name ;
Rem undefine adfbc_txn_seq_increment ;
Rem undefine adfbc_pk_suffix ;
Rem undefine adfbc_txn_tab_index_suffix ;
Rem undefine adfbc_txn_tab_user ;

Rem undefine def_adfbc_txn_tab_name ;
Rem undefine def_adfbc_txn_seq_name ;
Rem undefine def_adfbc_txn_seq_increment ;
Rem undefine def_adfbc_control_tab_name ;
