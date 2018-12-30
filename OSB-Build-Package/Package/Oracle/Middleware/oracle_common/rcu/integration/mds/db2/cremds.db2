--
--
-- cremds.db2
--
-- Copyright (c) 2006, 2010, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--    NAME
--     cremds.db2 - create MDS repository.
--
--    DESCRIPTION
--    This file creates the database schema for the repository. This is used
--    by cremds.sh script to create MDS repository using JDBCEngine. 
--
--    NOTES
--
--    MODIFIED   (MM/DD/YY)
--    pwhaley     04/19/10 - #(9585915) XbranchMerge pwhaley_upgmds_db2 from main
--    pwhaley     04/14/10 - #(9584856) Split dropping for upgrade.
--    erwang      12/14/09 - Created
--

-- We know that the current schema is the schema that will be used for MDS.
define IN_TABLESPACE = ""
@

-- drop mds schema objects
!dropmds.db2
!droptabs.db2

-- create mds tables and indexes
!cremdcmtbs.db2

!cremdsrtbs.db2

!cremdsinds.db2

-- create procedures
!mdsinc.db2

!mdsinsr.db2

--commit

