Rem
Rem $Header: entsec_ldap/java/src/oracle/security/audit/rcu/scripts/auditDeleteData.sql /st_entsec_11.1.1.7.0/2 2012/10/24 23:11:03 rkoul Exp $
Rem
Rem auditDeleteData.sql
Rem
Rem Copyright (c) 2012, Oracle and/or its affiliates. All rights reserved. 
Rem
Rem    NAME
Rem      auditDeleteData.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      Usage: arg1=schema  arg2=number_of_days_prior_to_which_everything_should_be_purged
Rem           : e.g sql>@auditDeleteData.sql DEV_IAU 100
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rkoul       10/24/12 - add SOA, XMLPServer, components
Rem    rkoul       09/28/12 - Creation - bugfix 14471957
Rem

ALTER SESSION SET CURRENT_SCHEMA=&&1;

ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';

delete from IAU_BASE where IAU_TstzOriginating < (systimestamp  - &&2); 
delete from AdminServer where IAU_TstzOriginating < (systimestamp  - &&2); 
delete from DIP where IAU_TstzOriginating < (systimestamp  - &&2); 
delete from JPS where IAU_TstzOriginating < (systimestamp  - &&2); 
delete from OAAM where IAU_TstzOriginating < (systimestamp  - &&2); 
delete from OAM where IAU_TstzOriginating < (systimestamp  - &&2); 
delete from OIF where IAU_TstzOriginating < (systimestamp  - &&2); 
delete from OVD where IAU_TstzOriginating < (systimestamp  - &&2); 
delete from OHSComponent where IAU_TstzOriginating < (systimestamp  - &&2); 
delete from OIDComponent where IAU_TstzOriginating < (systimestamp  - &&2); 
delete from WebCacheComponent where IAU_TstzOriginating < (systimestamp  - &&2);
delete from OWSM_PM_EJB where IAU_TstzOriginating < (systimestamp  - &&2);
delete from OWSM_AGENT where IAU_TstzOriginating < (systimestamp  - &&2);
delete from WS_PolicyAttachment where IAU_TstzOriginating < (systimestamp  - &&2);
delete from WebServices where IAU_TstzOriginating < (systimestamp  - &&2);
delete from STS where IAU_TstzOriginating < (systimestamp  - &&2);
delete from SOA_B2B where IAU_TstzOriginating < (systimestamp  - &&2);
delete from SOA_HCFP where IAU_TstzOriginating < (systimestamp  - &&2);
delete from XMLPSERVER where IAU_TstzOriginating < (systimestamp  - &&2);

--custom tables
delete from IAU_CUSTOM where IAU_ID in (select IAU_ID from IAU_COMMON where IAU_TstzOriginating < (systimestamp  - &&2)); 



DECLARE
        l_count number;
        my_sql varchar(200);
BEGIN

SELECT COUNT(*) INTO l_count FROM IAU_COMMON where IAU_TstzOriginating < ( systimestamp - &&2) ;
IF( l_count > 0 )
THEN
    FOR t IN (SELECT  t.table_name, t.owner FROM  all_tables t where upper(owner) = upper('&&1') AND table_name LIKE 'IAU_CUSTOM_%')
    LOOP
       my_sql := 'delete from ' || t.owner || '.' || t.table_name || ' where IAU_ID in (select IAU_ID from ' || t.owner || '.IAU_COMMON where IAU_TstzOriginating < (systimestamp - &&2))';
                EXECUTE IMMEDIATE my_sql;
        END LOOP;
END iF;
EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('ERROR!! -- '  || SQLCODE || '--' || sqlerrm );
END;
/

-- common table
delete from IAU_COMMON where IAU_TstzOriginating < (systimestamp  - &&2); 


commit;
