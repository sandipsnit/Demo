--
--
-- cremds-rcu.sql
--
-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--    NAME
--     cremds-rcu.sql - create MDS repository.
--
--    DESCRIPTION
--    This file creates the database schema for the repository. To
--    be used only by RCU.
--
--    NOTES
--
--    MODIFIED   (MM/DD/YY)
--    erwang     03/22/11 - Change delimiter to /
--    erwang     01/14/11 - Created
--

-- We know that the current schema is the schema that will be used for MDS.

-- create mds tables and indexes
source cremdcmtbs.sql

source cremdsrtbs.sql

source cremdsinds.sql

-- create procedures
source mdsinc.sql

source mdsinsr.sql

--commit
--/

