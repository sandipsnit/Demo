--    ** THIS SCRIPT HAS BEEN DEPRECATED AND MUST NOT BE EXECUTED **
--    ** IN ANY FUSION DATABASE                                   **
--
--    When working with a Fusion Apps database, the S_ROW_ID table will be
--    automatically created by the Fusion Apps database installation process
--    and there is no requirement to execute this script. 
--    This script is still being provided for developers who will be working
--    with a non Fusion Apps database and doing development / testing with
--    the Middle tier Unique ID Generator.
--
--
-- DESCRIPTION
--    Run the following script to create or update table S_ROW_ID
--    if table new then S_ROW_ID.START_ID and NEXT_ID will be 1e14+1, and MAX_ID will be 1e15-1
--    if NEXT_ID is less then 1e14+1 then NEXT_ID and START_ID will be 1e14+1
--    if MAX_ID is less than 1e15-1 then MAX_ID will be 1e15
--
--    The reason why we use 1e14 is because
--       existing apps are already using ids starting from 1 to probably some number less than 1e14
--       legacy Oracle PL/SQL apps have a max id of 1e15, so we cannot use 1e15+1 or anything larger
--
-- CAUTION
--    Changing the values of vconst_startid and vconst_maxid may break Fusion apps
--    where the id column is NUMBER(15).
--
-- ASSUMPTIONS
--    Table S_ROW_ID does not exists, or exists and has one row in it

declare

   TABLE_ALREADY_EXISTS exception;
   PRAGMA EXCEPTION_INIT (TABLE_ALREADY_EXISTS, -00955);

   v_id Number(38);
   vconst_startid constant Number(38) := 1e14+1;
   vconst_maxid constant Number(38) := 1e15-1;
   sql_stmt Varchar2(16383);

begin
   begin
      sql_stmt := 'create table S_ROW_ID (START_ID Number(38), NEXT_ID Number(38), MAX_ID Number(38), AUX_START_ID Number(38), AUX_MAX_ID Number(38), constraint next_less_than_max check(NEXT_ID<=MAX_ID), constraint start_less_than_next check(START_ID<=NEXT_ID), constraint auxStart_less_than_auxMax check(AUX_START_ID<=AUX_MAX_ID), constraint aux_main_dont_overlap check(START_ID not between AUX_START_ID and AUX_MAX_ID and MAX_ID not between AUX_START_ID and AUX_MAX_ID))';
      execute immediate sql_stmt;
      dbms_output.put_line('CreateUniqueId: table S_ROW_ID created');

      sql_stmt := 'insert into S_ROW_ID VALUES (' || vconst_startid || ', ' || vconst_startid || ', ' || vconst_maxid || ', 0, 0)';
      execute immediate sql_stmt;
      dbms_output.put_line('CreateUniqueId: ' || sql_stmt);

   exception
      when TABLE_ALREADY_EXISTS then
         dbms_output.put_line('CreateUniqueId: table S_ROW_ID already exists');

         sql_stmt := 'lock table S_ROW_ID in exclusive mode';
         execute immediate sql_stmt;
         dbms_output.put_line('CreateUniqueId: ' || sql_stmt);

         sql_stmt := 'select NEXT_ID from S_ROW_ID';
         execute immediate sql_stmt into v_id;
         if v_id < vconst_startid then
            sql_stmt := 'update S_ROW_ID set START_ID = ' || vconst_startid || ', NEXT_ID = ' || vconst_startid;
            execute immediate sql_stmt;
            dbms_output.put_line('CreateUniqueId: ' || sql_stmt);
         end if;

         sql_stmt := 'select MAX_ID from S_ROW_ID';
         execute immediate sql_stmt into v_id;
         if v_id < vconst_startid then
            sql_stmt := 'update S_ROW_ID set MAX_ID = ' || vconst_maxid;
            execute immediate sql_stmt;
            dbms_output.put_line('CreateUniqueId: ' || sql_stmt);
         end if;
   end;

   commit;
   dbms_output.put_line('CreateUniqueId: completed');

exception
   when others then
      rollback;
      raise;
end;

/
