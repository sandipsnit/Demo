--
--
--    create-user.sql
--
-- Copyright (c) 2009, Oracle and/or its affiliates. All rights reserved. 
--
--    NAME
--    create-user.sql - <one-line expansion of the name>
--
--    DESCRIPTION
--    This script is use to create schema in SQL SERVER database.
--    User need to pass following parameters to execute the script: 
--    1. Database Name 2. Schema Name 3. Schema Password.
--    User need to pass the above parameters in the following way:
--    <script_name> -v V1 = <value> -v V2 = <value> -v V3 = <value>
--    where V1, V2 and V3 are teh above 3 parameters.
--
--    NOTES
--    <other useful comments, qualifications, etc.>
--
--    MODIFIED   (MM/DD/YY)
--    rohitgup    04/02/09 - Created
--
--

go
set nocount on
set implicit_transactions off
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

use $(DATABASE_NAME)
go

declare @login  sysname

select @login = name from sys.server_principals where type = 'S' and Name = N'$(SCHEMA_USER)'

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





