--
-- upgmds-rcu.db2
--
-- Copyright (c) 2006, 2010, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--    NAME
--     upgmds-rcu.db2 - RCU script to upgrade MDS repository.
--
--    DESCRIPTION
--    This file upgrades the database schema for the repository. To
--    be used only by RCU.
--
--    NOTES
--
--    MODIFIED   (MM/DD/YY)
--    pwhaley     04/14/10 - #(9584856) Created.
--

-- Use the default tablespace.
define  IN_TABLESPACE = ""
@

-- Upgrade mds tables and sequences.
!upgmds.db2

-- Drop procedures, functions, types, variables, triggers, indexes, etc.
!dropmds.db2

-- Create indexes.
!cremdsinds.db2

-- Create procedures, etc.
!mdsinc.db2

!mdsinsr.db2

