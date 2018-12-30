--
--
-- cremds-rcu.sql
--
-- Copyright (c) 2006, 2007, Oracle. All rights reserved.  
--
--    NAME
--     cremds-rcu.sql - create MDS repository.
--
--    DESCRIPTION
--    This file creates the database schema for the repository. To
--    be used only by RCU.
--
--    NOTES
--    All objects will be created under the schema that is associated with
--    the current login user.  Please make sure the login user is created
--    with correct authorities and associated with correct schema.  You 
--    can either use cremduser.sql to create the user or refer the script
--    to create the user properly.
--
--
--    MODIFIED   (MM/DD/YY)
--    erwang     06/25/07 - #(5919142) workaround emtpy value
--    erwang     12/13/06 - Created
--

go
SET NOCOUNT ON
go

-- Assign database name which is passed in as V1 to DATABASE_NAE
:SETVAR DATABASE_NAME  $(v1)
go

-- Assign unicode prefix which is passed in as V2 to MDS_VARCHAR
:SETVAR MDS_VARCHAR  $(v2)
go

-- Switch to use the database
USE $(DATABASE_NAME)
go

-- Invoke cremds.sql to create MDS repositary objects.
:r cremds.sql
go



