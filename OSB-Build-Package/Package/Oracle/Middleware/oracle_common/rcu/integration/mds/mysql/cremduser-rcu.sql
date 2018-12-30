--
--
-- cremdusr-rcu.sql
--
-- Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 
--
--    NAME
--     cremduser-rcu.sql - Create schema for MDS user on MySQL. 
--
--    DESCRIPTION
--    This file creates db schema for MDS on MySQL. To
--    be used only by RCU.
--
--    MODIFIED   (MM/DD/YY)
--    erwang     03/22/11 - Change delimiter to /
--    erwang     01/13/11 - Created
--

-- Assign schema name which is passed in as $1 to SCHEMA_USER
define SCHEMA_NAME=$1;

define SCHEMA_PASSWORD=$2;     

source cremduser.sql

