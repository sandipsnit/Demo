-- Copyright (c) 2009, 2010, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- DROPMDSINDS.SQL - DROP MDS Indexes for SQL Server.
-- 
-- MODIFIED    (MM/DD/YY)
-- gnagaraj     12/21/09   - Creation.
--

DECLARE @indName      NVARCHAR(257)
DECLARE @objName      NVARCHAR(257)
DECLARE @dropIndSql   NVARCHAR(300)
DECLARE C1 CURSOR GLOBAL FORWARD_ONLY READ_ONLY FOR
select name, object_name(object_id) from sys.indexes 
    where name like N'MDS_%' ESCAPE '\'

open C1

WHILE(1=1)
BEGIN
  FETCH NEXT FROM C1 INTO @indName, @objName
       
  IF (@@FETCH_STATUS <> 0)
  BEGIN
    CLOSE C1
    DEALLOCATE C1
    BREAK
  END

  set @dropIndSql = N'drop index ' + @indName + ' on ' + @objName
  exec sp_executesql @dropIndSql        
END
go
