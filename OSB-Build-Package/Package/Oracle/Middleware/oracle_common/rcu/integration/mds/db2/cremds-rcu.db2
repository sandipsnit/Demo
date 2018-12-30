--
--
-- cremds-rcu.db2
--
-- Copyright (c) 2006, 2010, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--    NAME
--     cremds-rcu.db2 - create MDS repository.
--
--    DESCRIPTION
--    This file creates the database schema for the repository. To
--    be used only by RCU.
--
--    NOTES
--
--    MODIFIED   (MM/DD/YY)
--    erwang     02/24/10 - Remove calling dropmds.db2
--    erwang     12/15/09 - Remove @ that is not needed after !
--    erwang     08/27/09 - Use $ for defined variable
--    erwang     08/26/09 - Created
--

-- Get DEFAULT_TABLESPACE which is passed in as $1
define  IN_TABLESPACE = "IN $1"
@

-- We know that the current schema is the schema that will be used for MDS.

-- create mds tables and indexes
!cremdcmtbs.db2

!cremdsrtbs.db2

!cremdsinds.db2

-- create procedures
!mdsinc.db2

!mdsinsr.db2

--commit
--@

