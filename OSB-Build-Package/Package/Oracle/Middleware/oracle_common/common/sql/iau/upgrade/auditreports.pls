--
-- $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/auditreports.pls /entsec_11.1.1.4.0_dwg/1 2011/10/25 14:04:18 skalyana Exp $
--
-- auditreports.pls
--
-- Copyright (c) 2010, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--   NAME
--     auditreports.pls - <one-line expansion of the name>
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
--   skalyana    10/13/11 - Fix bug # 11772983 
--   skalyana    08/04/10 - Fix bug # 9816072
--   shiahuan    01/21/10 - PL/SQL stored procedures/functions for audit
--                          reports
--   shiahuan    01/21/10 - Creation
--

create or replace type list_of_components is varray(10) of varchar2(64);
/

create or replace type list_of_events is varray(30) of varchar2(256);
/

create or replace type attribute_value_pairs is varray(40) of varchar2(256);
/

create or replace package auditreports_pkg as

    type general_refcur_type is ref cursor;

    function datasetQuery (p_component_specific_columns varchar2, p_component_specific_table varchar2, p_locale varchar2, p_translate_on varchar2, p_start_time date, p_end_time date, p_time_range integer, p_shown_component_types list_of_components, p_shown_event_types list_of_events, p_shown_event_status integer, p_predicate_on attribute_value_pairs, p_search_by attribute_value_pairs, p_sort_by varchar2, p_order_by varchar2, p_row_limit integer) return general_refcur_type;

    procedure translateByLeftJoin (p_sql_statement in out varchar2, p_locale varchar2, p_translate_on varchar2);

    v_authentication_events varchar2(256) := 'iau_base.iau_eventcategory = ''UserSession'' or iau_base.iau_eventcategory = ''Authentication''';
    v_authorization_events varchar2(256) := 'iau_base.iau_eventcategory = ''Authorization''';

end auditreports_pkg;
/

create or replace package body auditreports_pkg as

    function datasetQuery (p_component_specific_columns varchar2, p_component_specific_table varchar2, p_locale varchar2, p_translate_on varchar2, p_start_time date, p_end_time date, p_time_range integer, p_shown_component_types list_of_components, p_shown_event_types list_of_events, p_shown_event_status integer, p_predicate_on attribute_value_pairs, p_search_by attribute_value_pairs, p_sort_by varchar2, p_order_by varchar2, p_row_limit integer) return general_refcur_type as
        v_counter integer;
        v_rc general_refcur_type;
        v_sql_statement varchar2(32767);

    begin
        v_sql_statement := 'select * from ( ';

-- Compose SELECT Clause --

        v_sql_statement := v_sql_statement || 'select iau_base.*, nvl(iau_base.iau_applicationname, iau_base.iau_componentname) as iau_compappname';

        if (p_component_specific_columns is not null) then
            v_sql_statement := v_sql_statement || ' , ' || p_component_specific_columns;
        end if;

-- Compose FROM Clause --

        v_sql_statement := v_sql_statement || ' from ';

        if (p_locale is not null and p_translate_on is not null) then
            translateByLeftJoin (v_sql_statement, p_locale, p_translate_on);
        end if;

        v_sql_statement := v_sql_statement || ' IAU_Base ';

        if (p_component_specific_table is not null) then
            v_sql_statement := v_sql_statement || ', ' || p_component_specific_table || ' ';
        end if;

-- Compose WHERE Clause --

        if (p_component_specific_table is not null) then
            v_sql_statement := v_sql_statement || 'where iau_base.iau_id = ' || p_component_specific_table || '.iau_id and iau_base.iau_tstzoriginating = ' || p_component_specific_table || '.iau_tstzoriginating ';
        else
            v_sql_statement := v_sql_statement || 'where 1 = 1 ';
        end if;

        if (p_start_time is not null) then
            v_sql_statement := v_sql_statement || ' and iau_base.iau_tstzoriginating > ''' || p_start_time || ''' ';
        end if;

        if (p_end_time is not null) then
            v_sql_statement := v_sql_statement || ' and iau_base.iau_tstzoriginating < ''' || p_end_time || ''' ';
        end if;

        if (p_time_range is not null) then
            v_sql_statement := v_sql_statement || ' and iau_base.iau_tstzoriginating > sysdate - ' || p_time_range / 24 || ' ';
        end if;

        if (p_shown_component_types is not null and p_shown_component_types(1) is not null) then
            v_sql_statement := v_sql_statement || ' and (iau_base.iau_componenttype = ''' || p_shown_component_types(1) || '''';
            v_counter := 2;
            while v_counter <= p_shown_component_types.count loop
                if (p_shown_component_types(v_counter) is not null) then
                    v_sql_statement := v_sql_statement || ' or iau_base.iau_componenttype = ''' || p_shown_component_types(v_counter) || '''';
                end if;
            v_counter := v_counter + 1;
            end loop;
            v_sql_statement := v_sql_statement || ') ';
        end if;

        if (p_shown_event_types is not null) then
            if (p_shown_event_types(1) = 'isAuthentication') then
                v_sql_statement := v_sql_statement || ' and (' || v_authentication_events || ') ';
            elsif (p_shown_event_types(1) = 'isAuthorization') then
                v_sql_statement := v_sql_statement || ' and (' || v_authorization_events || ') ';
            elsif (p_shown_event_types(1) = 'notAuth') then
                v_sql_statement := v_sql_statement || ' and not (' || v_authentication_events || ') and not (' || v_authorization_events || ') ';
            elsif (p_shown_event_types(1) is not null) then
                v_sql_statement := v_sql_statement || ' and (iau_base.iau_eventtype = ''' || p_shown_event_types(1) || '''';
                v_counter := 2;
                while v_counter <= p_shown_event_types.count loop
                    if (p_shown_event_types(v_counter) is not null) then
                        v_sql_statement := v_sql_statement || ' or iau_base.iau_eventtype = ''' || p_shown_event_types(v_counter) || '''';
                    end if;
                v_counter := v_counter + 1;
                end loop;
                v_sql_statement := v_sql_statement || ') ';
            end if;
        end if;

        if (p_shown_event_status is not null) then
            v_sql_statement := v_sql_statement || ' and iau_base.iau_eventstatus = ' || p_shown_event_status || ' ';
        end if;

        if (p_predicate_on is not null) then
            v_counter := 2;
            while v_counter <= p_predicate_on.count loop
                if (p_predicate_on(v_counter) is not null) then
                    v_sql_statement := v_sql_statement || ' and ' || p_predicate_on(v_counter-1) || ' = ''' || p_predicate_on(v_counter) || ''' ';
                end if;
                v_counter := v_counter + 2;
            end loop;
        end if;

        if (p_search_by is not null) then
            v_counter := 2;
            while v_counter <= p_search_by.count loop
                if (p_search_by(v_counter) is not null) then
                    v_sql_statement := v_sql_statement || ' and instr(' || p_search_by(v_counter-1) || ', ''' || p_search_by(v_counter) || ''') > 0 ';
                end if;
                v_counter := v_counter + 2;
            end loop;
        end if;

-- Compose ORDER BY Clause --

        if (p_sort_by in ('iau_base.iau_initiator', 'iau_base.iau_tstzoriginating', 'iau_base.iau_remoteip', 'iau_base.iau_messagetext', 'iau_base.iau_eventtype') and p_order_by in ('asc', 'desc')) then
            v_sql_statement := v_sql_statement || 'order by ' || p_sort_by || ' ' || p_order_by;
        end if;

-- Query Composed --

        v_sql_statement := v_sql_statement || ') where rownum <= ' || nvl(p_row_limit, 1000);

        open v_rc for v_sql_statement;
        return v_rc;
    end datasetQuery;


    procedure translateByLeftJoin (p_sql_statement in out varchar2, p_locale varchar2, p_translate_on varchar2) is
        v_key_type varchar2(10);

    begin
        if (p_translate_on = 'iau_eventtype') then
            v_key_type := 'event';
        elsif (p_translate_on = 'iau_eventcategory') then
            v_key_type := 'category';
        end if;

        p_sql_statement := p_sql_statement || ' (select A.*, nvl(T.iau_disp_name_trans, A.' || p_translate_on || ') as iau_disp_name_trans from iau_base A ' ||
            'left join (select * from iau_disp_names_tl where iau_disp_name_key_type = ''' || v_key_type || ''' and instr(''' || p_locale || ''', iau_locale_str) > 0 ) T ' ||
            'on A.' || p_translate_on || ' = T.iau_disp_name_key and A.iau_componenttype = T.iau_component_type)';
    end translateByLeftJoin;

end auditreports_pkg;
/


grant all on list_of_components to &&1;
grant execute on list_of_components to &&2;
grant execute on list_of_components to &&3;

create or replace synonym &&2..list_of_components for &&1..list_of_components;
create or replace synonym &&3..list_of_components for &&1..list_of_components;

grant all on list_of_events to &&1;
grant execute on list_of_events to &&2;
grant execute on list_of_events to &&3;

create or replace synonym &&2..list_of_events for &&1..list_of_events;
create or replace synonym &&3..list_of_events for &&1..list_of_events;

grant all on attribute_value_pairs to &&1;
grant execute on attribute_value_pairs to &&2;
grant execute on attribute_value_pairs to &&3;

create or replace synonym &&2..attribute_value_pairs for &&1..attribute_value_pairs;
create or replace synonym &&3..attribute_value_pairs for &&1..attribute_value_pairs;

grant all on auditreports_pkg to &&1;
grant execute on auditreports_pkg to &&2;
grant execute on auditreports_pkg to &&3;

create or replace synonym &&2..auditreports_pkg for &&1..auditreports_pkg;
create or replace synonym &&3..auditreports_pkg for &&1..auditreports_pkg;
