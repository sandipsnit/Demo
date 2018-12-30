--
-- cremds.sql
--
-- Copyright (c) 2006, 2010, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--    NAME
--      cremds.sql - <one-line expansion of the name>
--
--    DESCRIPTION
--    This file creates the database schema for the repository.
--
--    The user should also have grant to create sequence in order to
--    successfully use the MDS Repository.
--
--    MODIFIED   (MM/DD/YY)
--    gnagaraj   12/22/09 - drop indexes in loop
--    erwang     11/13/06 - Created based on Oracle database implementation.
--
--

go
SET NOCOUNT ON
set implicit_transactions off
-- begin transaction cremds
go

-- Creating the tables and views
:r cremdcmtbs.sql
:r cremdsrtbs.sql

-- Creating the indexes
:r dropmdsinds.sql
:r cremdsinds.sql

-- Creating the package specs
:r mdsinc.sql
:r mdsinsr.sql
go

-- commit transaction cremds
go

