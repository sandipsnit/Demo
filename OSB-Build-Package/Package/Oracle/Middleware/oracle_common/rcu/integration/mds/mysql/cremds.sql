--
--
-- cremds.sql
--
-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--    NAME
--     cremds.sql - create MDS repository.
--
--    DESCRIPTION
--    This file creates the database schema for the repository. This is used
--    by cremds.sh script to create MDS repository using JDBCEngine. 
--
--    NOTES
--
--    MODIFIED   (MM/DD/YY)
--    erwang      03/22/11 - Change delimiter to /
--    erwang      01/13/11 - Created
--

-- drop mds schema objects
source dropmds.sql

source droptabs.sql

-- create mds tables and indexes
source cremdcmtbs.sql

source cremdsrtbs.sql

source cremdsinds.sql

-- create procedures
source mdsinc.sql

source mdsinsr.sql

--commit

