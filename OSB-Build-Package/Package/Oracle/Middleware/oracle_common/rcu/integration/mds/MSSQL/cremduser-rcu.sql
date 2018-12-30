--
--
-- cremdusr-rcu.sql
--
-- Copyright (c) 2006, 2009, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--    NAME
--     cremduser-rcu.sql - Create login, db user and schema for MDS on SQL Server
--
--    DESCRIPTION
--    This file creates db user, login and schema for MDS on SQL server. To
--    be used only by RCU.
--
--    MODIFIED   (MM/DD/YY)
--    rupandey   06/24/09 - #(8629927) Removed logic to alter COLLATE and 
--                          READ_COMMITTED_SNAPSHOT values. 
--    erwang     02/07/08 - #(6805261) fixed sysname case issue
--    erwang     04/11/07 - remove database creation
--    erwang     02/01/07 - Created
--

go
SET NOCOUNT ON
go

-- Assign database name which is passed in as V1 to DATABASE_NAE
:SETVAR DATABASE_NAME  $(v1)
go

-- Assign user name which is passed in as V2 to SCHEMA_USER
:SETVAR SCHEMA_USER  $(v2)
go

-- Assign user name which is passed in as V3 to SCHEMA_PASSWORD
:SETVAR SCHEMA_PASSWORD  $(v3)
go


-- Invoke cremduser.sql to create MDS login, user and schema.
:r cremduser.sql
go


