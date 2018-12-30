Rem
Rem $Header: jazn/jps/jrf/common/sql/opss_purge_changelog.sql /main/1 2010/05/24 02:39:57 wilu Exp $
Rem
Rem opss_purge_changelog.sql
Rem
Rem Copyright (c) 2010, Oracle and/or its affiliates. All rights reserved. 
Rem
Rem    NAME
Rem      opss_purge_changelog.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    wilu        05/23/10 - Purge old change log from policy store
Rem    wilu        05/23/10 - Created
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

delete from jps_changelog where createdate < (select(max(createdate) - 1) from jps_changelog);
commit;

