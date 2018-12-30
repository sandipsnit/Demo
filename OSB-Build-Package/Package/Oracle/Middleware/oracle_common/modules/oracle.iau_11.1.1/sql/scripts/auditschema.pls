--
-- $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/auditschema.pls /main/4 2010/01/08 17:09:10 shiahuan Exp $
--
-- auditschema.pls
--
-- Copyright (c) 2009, 2010, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--   NAME
--     auditschema.pls - <one-line expansion of the name>
--
--   DESCRIPTION
--     <short description of component this file declares/defines>
--
--   RETURNS
--
--   NOTES
--     <other useful comments, qualifications, etc.>
--
--   MODIFIED   (MM/DD/YY)
--   shiahuan    11/23/09 - auditschema_pkg
--   shiahuan    11/16/09 - PL/SQL stored procedures/functions for audit schema
--   shiahuan    11/16/09 - Creation
--

create or replace package auditschema_pkg as

    type general_refcur_type is ref cursor;
    type string_table_type is table of varchar2(255);

    function componentTable (p_id integer, p_time varchar2) return general_refcur_type;
    function delimitStr (p_in_str clob, p_delimiter varchar2, p_separator varchar2, p_escape varchar2) return clob;
    function tableExist (p_component_type in out varchar2) return boolean;

end auditschema_pkg;
/


create or replace package body auditschema_pkg as

    function componentTable (p_id integer, p_time varchar2)
        return general_refcur_type
    as
        v_component_type    varchar2(255);
        v_rc general_refcur_type;
        v_sql_statement varchar2(4000);
        v_time    timestamp;

    begin
        v_time := to_timestamp(translate(substr(p_time, 1, 23), 'T', ' '), 'yyyy-mm-dd hh24:mi:ss.ff6');
        select iau_componenttype into v_component_type from iau_base where iau_id = p_id and iau_tstzoriginating = v_time;

        if tableExist(v_component_type) = false then
            v_sql_statement := 'select /*+ index(iau_base event_time_index)*/ iau_id, iau_tstzoriginating from iau_base where iau_id = ' || p_id || ' and iau_tstzoriginating = ' || '''' || v_time || '''';
        else
            v_sql_statement := 'select /*+ index (' || v_component_type || ' ' || v_component_type || '_Index) */ * from ' || upper(v_component_type) || ' where iau_id = ' || p_id || ' and iau_tstzoriginating = ' || '''' || v_time || '''';
        end if;

        open v_rc for v_sql_statement;
        return v_rc;
    end componentTable;


    function delimitStr (p_in_str clob, p_delimiter varchar2, p_separator varchar2, p_escape varchar2)
        return clob
    as
        v_state        integer;
        v_str_len        integer;
        v_each_char        varchar2(2);
        v_temp_str         clob;
        v_out_str         clob;

    begin
        if p_in_str is null then
            return null;
        end if;

        v_state := 0;
        v_str_len := length(p_in_str);

        for i in 1..v_str_len loop
            v_each_char := substr(p_in_str, i, 1);

            if v_state = 0 then
                if v_each_char = p_delimiter then
                    v_out_str := concat(v_out_str, v_temp_str);
                    v_out_str := v_out_str || chr(10);
                    v_temp_str := chr(10);
                elsif v_each_char = p_separator then
                    v_temp_str := v_temp_str || chr(10) || '---------------' || chr(10);
                elsif v_each_char = p_escape then
                    v_state := 1;
                else
                    v_temp_str := concat(v_temp_str, v_each_char);
                end if;
            else
                v_temp_str := concat(v_temp_str, v_each_char);
                v_state := 0;
            end if;
        end loop;

        return v_out_str;
    end delimitStr;


    function tableExist (p_component_type in out varchar2)
        return boolean
    as
        v_table_exists    boolean;
        v_table_name    varchar2(255);
        v_table_names    string_table_type;

    begin
        v_table_exists := false;
        p_component_type := replace(p_component_type, '-', '_');
        select table_name bulk collect into v_table_names from all_tables;
        for i in v_table_names.first .. v_table_names.last loop
            v_table_name := v_table_names(i);
            if v_table_name = upper(p_component_type) or v_table_name = upper(concat(p_component_type, 'Component')) then
                v_table_exists := true;
            end if;
        end loop;
        return v_table_exists;
    end tableExist;

end auditschema_pkg;
/


grant all on auditschema_pkg to &&1;
grant execute on auditschema_pkg to &&2;
grant execute on auditschema_pkg to &&3;

create or replace synonym &&2..auditschema_pkg for &&1..auditschema_pkg;
create or replace synonym &&3..auditschema_pkg for &&1..auditschema_pkg;

