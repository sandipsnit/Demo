-- Copyright (c) 2006, 2010, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- DROPMDS-RCU.DB2 - MDS metadata services Drop MDS schema objects used by RCU
--
-- MODIFIED    (MM/DD/YY)
--    erwang    05/28/10 - XbranchMerge erwang_bug-9708828 from main
--    erwang    05/27/10 - #(9708828) removed extra '@' that causes an exception
--                         from RCU. 
--    pwhaley   04/19/10 - #(9585915) XbranchMerge pwhaley_upgmds_db2 from main
--    pwhaley   04/14/10 - #(9584856) Split dropping for upgrade.
--    erwang    02/24/10 - Don't drop schema and Java 'Drop' action does it
--    erwang    08/27/09 - Use $ for defined variable
--    erwang    08/26/09  - Create.
--
-- Assign schema name which is passed in as $1 to SCHEMA_NAME
define SCHEMA_NAME     =  $1 
@

SET SCHEMA=$SCHEMA_NAME
@

SET PATH=SYSTEM PATH, $SCHEMA_NAME
@

!dropmds.db2

!droptabs.db2

-- Restore current schema
SET SCHEMA=USER
@

-- Restore current path 
SET PATH=SYSTEM PATH, USER
@
--commit
--@

