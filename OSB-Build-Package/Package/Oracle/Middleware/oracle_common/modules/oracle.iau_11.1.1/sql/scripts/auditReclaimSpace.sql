Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/auditReclaimSpace.sql /st_entsec_11.1.1.7.0/2 2012/10/24 23:11:03 rkoul Exp $
Rem
Rem auditReclaimSpace.sql
Rem
Rem Copyright (c) 2012, Oracle and/or its affiliates. All rights reserved. 
Rem
Rem    NAME
Rem      auditReclaimSpace.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       10/24/12 - add shrink cascade for component tables
Rem                         - add sts, soa, xmlpserver
Rem    rkoul       09/28/12 - Creation - bugfix 14471957
Rem

-- row movement
ALTER TABLE IAU_BASE enable row movement;
ALTER TABLE AdminServer enable row movement;
ALTER TABLE DIP enable row movement;
ALTER TABLE JPS enable row movement;
ALTER TABLE OAAM enable row movement;
ALTER TABLE OAM enable row movement;
ALTER TABLE OIF enable row movement;
ALTER TABLE OVD enable row movement;
ALTER TABLE OHSComponent enable row movement;
ALTER TABLE OIDComponent enable row movement;
ALTER TABLE WebCacheComponent enable row movement;
ALTER TABLE OWSM_PM_EJB enable row movement;
ALTER TABLE OWSM_AGENT enable row movement;
ALTER TABLE WS_PolicyAttachment enable row movement;
ALTER TABLE WebServices enable row movement;
ALTER TABLE STS enable row movement;
ALTER TABLE SOA_B2B enable row movement;
ALTER TABLE SOA_HCFP enable row movement;
ALTER TABLE XMLPSERVER enable row movement;
ALTER TABLE IAU_COMMON enable row movement;
ALTER TABLE IAU_CUSTOM enable row movement;

-- shrink space
ALTER TABLE IAU_BASE SHRINK SPACE CASCADE;
ALTER TABLE AdminServer SHRINK SPACE CASCADE;
ALTER TABLE DIP SHRINK SPACE CASCADE;
ALTER TABLE JPS SHRINK SPACE CASCADE;
ALTER TABLE OAAM SHRINK SPACE CASCADE;
ALTER TABLE OAM SHRINK SPACE CASCADE;
ALTER TABLE OIF SHRINK SPACE CASCADE;
ALTER TABLE OVD SHRINK SPACE CASCADE;
ALTER TABLE OHSComponent SHRINK SPACE CASCADE;
ALTER TABLE OIDComponent SHRINK SPACE CASCADE;
ALTER TABLE WebCacheComponent SHRINK SPACE CASCADE;
ALTER TABLE OWSM_PM_EJB SHRINK SPACE CASCADE;
ALTER TABLE OWSM_AGENT SHRINK SPACE CASCADE;
ALTER TABLE WS_PolicyAttachment SHRINK SPACE CASCADE;
ALTER TABLE WebServices SHRINK SPACE CASCADE;
ALTER TABLE STS SHRINK SPACE CASCADE;
ALTER TABLE SOA_B2B SHRINK SPACE CASCADE;
ALTER TABLE SOA_HCFP SHRINK SPACE CASCADE;
ALTER TABLE XMLPSERVER SHRINK SPACE CASCADE;
ALTER TABLE IAU_COMMON SHRINK SPACE CASCADE;
ALTER TABLE IAU_CUSTOM SHRINK SPACE CASCADE;


--custom tables
DECLARE
        row_sql varchar(100);
        shrink_sql varchar(100);
BEGIN

    FOR t IN (SELECT  t.table_name, t.owner FROM  all_tables t where upper(owner) = upper('&&1') AND table_name LIKE 'IAU_CUSTOM_%')
    LOOP
       row_sql := 'ALTER TABLE ' || t.table_name || ' enable row movement';
       EXECUTE IMMEDIATE row_sql;
       shrink_sql := 'ALTER TABLE ' || t.table_name || ' shrink space cascade';
       EXECUTE IMMEDIATE shrink_sql;
    END LOOP;
EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('ERROR!! -- '  || SQLCODE || '--' || sqlerrm );
END;
/

commit;

 
