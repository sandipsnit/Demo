-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--
-- cremduser.sql - Create login, db user and schema for MDS on MySQL 
--
-- Note:
--   For creating a MDS user, please use cremdusr.sh script. 
--
-- MODIFIED    (MM/DD/YY)
-- erwang       05/16/11   - remove output to mydebug
-- erwang       03/22/11   - Change delimiter to /
-- erwang       01/13/11   - Creation
--

set @schema_user='$SCHEMA_NAME';

set @schema_password='$SCHEMA_PASSWORD';

set character_set_connection='utf8mb4';

-- Default to mysql database
use mysql
/

drop procedure if exists mds_execute_sql;

create procedure mds_execute_sql(sqlStmt varchar(256) character set utf8mb4)
language sql
begin
    SET @sql = sqlStmt;

    PREPARE stmt FROM @sql; 

    EXECUTE stmt;

    DEALLOCATE PREPARE stmt;
end
/

drop procedure if exists mds_create_user
/

create procedure mds_create_user(schema_user     varchar(16) character set utf8mb4, 
                                 schema_password varchar(64) character set utf8mb4)
language sql
begin

  set @schema=null, @charset=null,@collate=null;

  select @schema := SCHEMA_NAME, 
         @charset=DEFAULT_CHARACTER_SET_NAME, 
         @collate=DEFAULT_COLLATION_NAME
      from information_schema.schemata 
    where convert(SCHEMA_NAME using utf8mb4) = schema_user;

  IF ( @schema IS NULL ) THEN
    -- create create schema 
    SET @sql = CONCAT('create schema ', schema_user,  
             ' default character set=utf8mb4 default collate=utf8mb4_bin');

    call mds_execute_sql(@sql);
  ELSE
    -- change login
    IF @charset <> 'utf8mb4' OR
         @collate <> 'utf8mb4_bin' THEN

      SET @sql = CONCAT('alter schema ', schema_user,  
           ' default character set=utf8mb4 default collate=utf8mb4_bin');

      call mds_execute_sql(@sql);
    END IF;
  END IF;

  set @count=0;

  -- Create a user who can access to db locally.
  SET @sql = CONCAT('grant all on ', schema_user, '.*', 
           ' to ', schema_user, '@''localhost'' identified by ''', schema_password, '''');

  call mds_execute_sql(@sql);

  SET @sql = CONCAT('grant process on *.*', ' to ', schema_user, '@''localhost''');

  call mds_execute_sql(@sql);

  SET @sql = CONCAT('grant all on ', schema_user, '.*', 
           ' to ', schema_user, '@''%'' identified by ''', schema_password, '''');

  call mds_execute_sql(@sql);

  SET @sql = CONCAT('grant process on *.*', ' to ', schema_user, '@''%''');

  call mds_execute_sql(@sql);

END
/


call mds_create_user(@schema_user, @schema_password)
/

drop procedure if exists mds_create_user
/

drop procedure if exists mds_execute_sql
/
