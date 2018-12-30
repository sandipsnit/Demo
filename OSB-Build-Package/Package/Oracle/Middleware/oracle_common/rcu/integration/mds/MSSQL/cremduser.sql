-- Copyright (c) 2006, 2009, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- cremduser.sql - Create login, db user and schema for MDS on SQL Server
--
-- Note:
--   Create login, user and schema and default_database to the
--   database used by MDS.  This script should be executed using
--   sqlcmd utlity.
--
--   Syntax: sqlcmd -S <server> -U <username> -P <password> -i cremduser.sql
--                -v SCHEMA_USER="<new username>" SCHEMA_PASSWORD="<password>" DATABASE_NAME="<mds db>"
--
--   Examples: sqlcmd -S stada66 -U mds -P x -i cremduser.sql -v SCHEMA_USER="john" SCHEMA_PASSWORD="x" DATABASE_NAME="mds"
--             sqlcmd -S iwinrea22,5561 -U sa -P x -i cremduser.sql -v SCHEMA_USER="john" SCHEMA_PASSWORD="x" DATABASE_NAME="mds"
-- 
-- MODIFIED    (MM/DD/YY)
-- sindla       07/30/09   - Fixed bug #(8738638). 
-- erwang       04/17/07   - Remove unnecessary authorities
-- erwang       12/27/06   - SQL Server Globalization Support
-- erwang       12/08/06   - Refact for rcu
-- erwang       11/15/06   - fix an error in issuing sp_addrolemember
-- erwang       11/09/06   - fix description
-- erwang       11/06/06   - fix an error in grant
-- erwang       09/04/06   - Creation a MDS user
--
go
set nocount on
set implicit_transactions off
go

-- Try to drop all object first
-- :r dropmduser.sql

use $(DATABASE_NAME)
go

declare @login  sysname

select @login = name from sys.server_principals where type = N'S' and name = N'$(SCHEMA_USER)'

IF ( @login IS NULL )
BEGIN
  -- create login
  create login $(SCHEMA_USER) with password = N'$(SCHEMA_PASSWORD)', 
         default_database = $(DATABASE_NAME),
         check_expiration = off, check_policy = off
END
ELSE
BEGIN
  -- change login
  alter login $(SCHEMA_USER) with
         default_database = $(DATABASE_NAME),
         check_expiration = off, check_policy = off
END

go


declare @user  int

select @user = principal_id from sys.database_principals where name = N'$(SCHEMA_USER)' and type = N'S'

IF ( @user IS NULL )
BEGIN
  -- create user
  create user $(SCHEMA_USER) for login $(SCHEMA_USER)
END
go

-- create schema
create schema $(SCHEMA_USER) authorization $(SCHEMA_USER)
go

-- alter db user to a new default_schema
alter user $(SCHEMA_USER) with default_schema = $(SCHEMA_USER)
go

GRANT create table, create view, create procedure, 
create function TO $(SCHEMA_USER)
go


-- Add XA user role
use master
go


-- Create a user mapping at master db.
declare @user  int

select @user = principal_id from sys.database_principals where name = N'$(SCHEMA_USER)' and type = N'S'

IF ( @user IS NULL )
BEGIN
  -- create user
  create user $(SCHEMA_USER) for login $(SCHEMA_USER)
END
go

-- alter db user to use dbo schema
alter user $(SCHEMA_USER) with default_schema = dbo
go

declare @pid   int

select @pid = principal_id from master.sys.database_principals 
where name = N'SqlJDBCXAUser' and type = N'R'

IF ( @pid IS NOT NULL )
BEGIN
    exec sp_addrolemember SqlJDBCXAUser, $(SCHEMA_USER)
END
go



