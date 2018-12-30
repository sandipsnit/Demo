-- Copyright (c) 2006, 2010, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- dropmds.db2 - MDS metadata services Drop MDS schema objects.
--
-- NOTE: This script does not drop tables or sequences. It is called for
--       both upgrade and create schema operations. See droptabs.db2 for
--       the script to drop tables and sequences.
--
-- MODIFIED    (MM/DD/YY)
-- pwhaley      04/19/10 - #(9585915) XbranchMerge pwhaley_upgmds_db2 from main
-- pwhaley      04/14/10 - #(9584856) Split out table, sequence for upgrade.
-- erwang       01/19/10 - Fix an issue in drop indexes created for constraints
-- erwang       12/10/09 - Skip dropping sequences create for Identity
-- erwang       08/31/09 - Remove current_user in query condition
-- erwang       08/06/09  - Added drop triggers 
-- erwang       07/15/09  - Create.
--

-- Drop all procedures and functions under current schemas
CREATE PROCEDURE dropSchemaRoutines()
LANGUAGE SQL
BEGIN ATOMIC
    
    DECLARE CNT INTEGER;
    
    DECLARE execStr     VARCHAR(1000);

    DECLARE rtnName     VARCHAR(128);
    DECLARE rtnType     CHAR(1);

    DECLARE retry       SMALLINT;
    DECLARE triedCount  SMALLINT DEFAULT 0; 

    DECLARE SQLSTATE    CHAR(5); 

    DECLARE c_schema_routines CURSOR FOR 
        SELECT SPECIFICNAME, ROUTINETYPE 
             FROM SYSCAT.ROUTINES 
               WHERE (ROUTINETYPE = 'F' OR ROUTINETYPE = 'P') AND 
                OWNERTYPE = 'U' AND
                ROUTINESCHEMA = CURRENT_SCHEMA AND
                LANGUAGE = 'SQL' and ROUTINENAME != 'dropSchemaRoutines'
        FOR READ ONLY;

    SET retry = 1;

    WHILE ( retry = 1 AND triedCount < 10 ) DO
       
        SET retry = 0;
        SET triedCount = triedCount + 1;

        OPEN c_schema_routines;

        delete_routines:
        WHILE (1=1) DO
            FETCH FROM c_schema_routines INTO rtnName, rtnType;

            IF ( SQLSTATE <> '00000' ) THEN
                CLOSE c_schema_routines;

                LEAVE delete_routines;
            END IF;

            BEGIN
                -- If we cannot delete current function due to 
                -- dependency, we will retry it.
                DECLARE CONTINUE HANDLER FOR SQLSTATE '42893'
                BEGIN
                    SET retry = 1;
                END;

                DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
                BEGIN                    
                END;

                IF ( rtnType = 'F' ) THEN
                    SET execStr = 'drop specific function ' || rtnName;
                ELSE
                    SET execStr = 'drop specific procedure ' || rtnName;
                END IF;

                EXECUTE IMMEDIATE execStr;
            END;
        END WHILE delete_routines;
    END WHILE;
END
@

call dropSchemaRoutines()
@

drop procedure dropSchemaRoutines()
@


-- Drop all types under current schemas for current owner
CREATE PROCEDURE dropSchemaTypes()
LANGUAGE SQL
BEGIN ATOMIC
    
    DECLARE CNT INTEGER;
    
    DECLARE execStr     VARCHAR(1000);

    DECLARE typName     VARCHAR(128);

    DECLARE SQLSTATE    CHAR(5);

    DECLARE c_schema_types CURSOR FOR
        SELECT TYPENAME
          FROM SYSCAT.DATATYPES
          WHERE OWNERTYPE = 'U' AND 
                TYPESCHEMA = CURRENT_SCHEMA
        FOR READ ONLY;

    OPEN c_schema_types;

    delete_loop:
    WHILE (1=1) DO
        FETCH FROM c_schema_types INTO typName;

        IF ( SQLSTATE <> '00000' ) THEN
            CLOSE c_schema_types;

            LEAVE delete_loop;
        END IF;

        SET execStr = 'drop TYPE ' || typName;

        EXECUTE IMMEDIATE execStr;
    END WHILE delete_loop;
END
@

call dropSchemaTypes()
@

drop procedure dropSchemaTypes()
@

-- Drop all indexes under current schemas for current owner
CREATE PROCEDURE dropSchemaIndexes()
LANGUAGE SQL
BEGIN ATOMIC
    
    DECLARE CNT INTEGER;
    
    DECLARE execStr     VARCHAR(1000);

    DECLARE sysRequired SMALLINT;

    DECLARE ndxName     VARCHAR(128);

    DECLARE tabName     VARCHAR(128);

    DECLARE SQLSTATE    CHAR(5);

    DECLARE c_schema_indexes CURSOR FOR
        SELECT INDNAME, TABNAME, SYSTEM_REQUIRED
          FROM SYSCAT.INDEXES
          WHERE OWNERTYPE = 'U' AND
                INDSCHEMA = CURRENT_SCHEMA
        FOR READ ONLY;

    OPEN c_schema_indexes;

    delete_indexes:
    WHILE (1=1) DO
        FETCH FROM c_schema_indexes INTO ndxName, tabName, sysRequired;

        IF ( SQLSTATE <> '00000' ) THEN
            CLOSE c_schema_indexes;

            LEAVE delete_indexes;
        END IF;

        IF ( sysRequired = 0 ) THEN
            SET execStr = 'drop index ' || ndxName;
        ELSE
            SET execStr = 'alter table ' || tabName ||
                          ' drop constraint ' || ndxName;
        END IF;

        EXECUTE IMMEDIATE execStr;
    END WHILE delete_indexes;

END
@

call dropSchemaIndexes()
@

drop procedure dropSchemaIndexes()
@

-- Drop all trigger under current schemas for current owner
CREATE PROCEDURE dropSchemaTriggers()
LANGUAGE SQL
BEGIN ATOMIC
    
    DECLARE CNT INTEGER;
    
    DECLARE execStr     VARCHAR(1000);

    DECLARE trigName    VARCHAR(128);

    DECLARE SQLSTATE    CHAR(5);

    DECLARE c_schema_triggers CURSOR FOR
        SELECT TRIGNAME
          FROM SYSCAT.TRIGGERS
          WHERE OWNERTYPE = 'U' AND 
                TRIGSCHEMA = CURRENT_SCHEMA
        FOR READ ONLY;

    OPEN c_schema_triggers;

    delete_triggers:
    WHILE (1=1) DO
        FETCH FROM c_schema_triggers INTO trigName;

        IF ( SQLSTATE <> '00000' ) THEN
            CLOSE c_schema_triggers;

            LEAVE delete_triggers;
        END IF;

        SET execStr = 'drop trigger ' || trigName;

        EXECUTE IMMEDIATE execStr;
    END WHILE delete_triggers;
END
@

call dropSchemaTriggers()
@

drop procedure dropSchemaTriggers()
@


-- Drop all variables under current schemas for current owner
CREATE PROCEDURE dropSchemaVariables()
LANGUAGE SQL
BEGIN ATOMIC
    
    DECLARE CNT INTEGER;
    
    DECLARE execStr     VARCHAR(1000);

    DECLARE varName     VARCHAR(128);

    DECLARE SQLSTATE    CHAR(5);

    DECLARE c_schema_variables CURSOR FOR
        SELECT VARNAME
          FROM SYSCAT.VARIABLES
          WHERE OWNERTYPE = 'U' AND 
                VARSCHEMA = CURRENT_SCHEMA
        FOR READ ONLY;

    OPEN c_schema_variables;

    delete_loop:
    WHILE (1=1) DO
        FETCH FROM c_schema_variables INTO varName;

        IF ( SQLSTATE <> '00000' ) THEN
            CLOSE c_schema_variables;

            LEAVE delete_loop;
        END IF;

        SET execStr = 'drop variable ' || varName;

        EXECUTE IMMEDIATE execStr;
    END WHILE delete_loop;
END
@

call dropSchemaVariables()
@

drop procedure dropSchemaVariables()
@

--commit
--@
