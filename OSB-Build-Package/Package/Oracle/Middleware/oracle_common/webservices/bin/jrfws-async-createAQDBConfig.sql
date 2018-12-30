-- SQL script for creating database user, AQ queue tables and AQ queues required for JRF WS Async services to work with AQ JMS.
-- This script is specifically created for Fusion Applications and that is why Fusion_AQ user and eight domain name prefixes are hard-coded.
-- &&1 - Fusion_AQ user's password.
-- &&2 - Default tablespace name for Fusion_AQ.
-- Example of creating default tablespace by name data: CREATE TABLESPACE data DATAFILE '/scratch/user/fusionaq.dbf' SIZE 100M;

DROP USER Fusion_AQ CASCADE;

GRANT connect, resource, AQ_USER_ROLE TO Fusion_AQ IDENTIFIED BY &&1;
GRANT execute ON sys.dbms_aqadm TO Fusion_AQ;

-- Create default tablespace for the Fusion_AQ user and supply it below
ALTER user Fusion_AQ default tablespace &&2;

connect Fusion_AQ/&&1;

BEGIN
    -- create queue tables for JMS point-to-point (queues) for CRM
    dbms_aqadm.create_queue_table(
        queue_table=> 'CRM_AsyncWS_Request',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );
    dbms_aqadm.create_queue_table(
        queue_table=>'CRM_AsyncWS_Response',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    -- create AQ-JMS queues for CRM
    dbms_aqadm.create_queue(
        queue_name=>'CRM_AsyncWS_Request',
        queue_table=>'CRM_AsyncWS_Request'
    );
    dbms_aqadm.create_queue(
        queue_name=> 'CRM_AsyncWS_Response',
        queue_table=>'CRM_AsyncWS_Response'
    );

    -- start the AQ-JMS queues for CRM
    dbms_aqadm.start_queue(
        queue_name=>'CRM_AsyncWS_Request'
    );

    dbms_aqadm.start_queue(
        queue_name=>'CRM_AsyncWS_Response'
    );

------------------------

 -- create queue tables for JMS point-to-point (queues) for HCM
    dbms_aqadm.create_queue_table(
        queue_table=> 'HCM_AsyncWS_Request',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    dbms_aqadm.create_queue_table(
        queue_table=>'HCM_AsyncWS_Response',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    -- create AQ-JMS queues for HCM

    dbms_aqadm.create_queue(
        queue_name=>'HCM_AsyncWS_Request',
        queue_table=>'HCM_AsyncWS_Request'
    );

    dbms_aqadm.create_queue(
        queue_name=> 'HCM_AsyncWS_Response',
        queue_table=>'HCM_AsyncWS_Response'
    );

    -- start the AQ-JMS queues for HCM

    dbms_aqadm.start_queue(
        queue_name=>'HCM_AsyncWS_Request'
    );

    dbms_aqadm.start_queue(
        queue_name=>'HCM_AsyncWS_Response'
    );


------------------------

 -- create queue tables for JMS point-to-point (queues) for FIN
    dbms_aqadm.create_queue_table(
        queue_table=> 'FIN_AsyncWS_Request',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    dbms_aqadm.create_queue_table(
        queue_table=>'FIN_AsyncWS_Response',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    -- create AQ-JMS queues for FIN

    dbms_aqadm.create_queue(
        queue_name=>'FIN_AsyncWS_Request',
        queue_table=>'FIN_AsyncWS_Request'
    );

    dbms_aqadm.create_queue(
        queue_name=> 'FIN_AsyncWS_Response',
        queue_table=>'FIN_AsyncWS_Response'
    );

    -- start the AQ-JMS queues for FIN

    dbms_aqadm.start_queue(
        queue_name=>'FIN_AsyncWS_Request'
    );

    dbms_aqadm.start_queue(
        queue_name=>'FIN_AsyncWS_Response'
    );

------------------------

 -- create queue tables for JMS point-to-point (queues) for PRC
    dbms_aqadm.create_queue_table(
        queue_table=> 'PRC_AsyncWS_Request',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    dbms_aqadm.create_queue_table(
        queue_table=>'PRC_AsyncWS_Response',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    -- create AQ-JMS queues for PRC

    dbms_aqadm.create_queue(
        queue_name=>'PRC_AsyncWS_Request',
        queue_table=>'PRC_AsyncWS_Request'
    );

    dbms_aqadm.create_queue(
        queue_name=> 'PRC_AsyncWS_Response',
        queue_table=>'PRC_AsyncWS_Response'
    );

    -- start the AQ-JMS queues for PRC

    dbms_aqadm.start_queue(
        queue_name=>'PRC_AsyncWS_Request'
    );

    dbms_aqadm.start_queue(
        queue_name=>'PRC_AsyncWS_Response'
    );

------------------------

 -- create queue tables for JMS point-to-point (queues) for PRJ
    dbms_aqadm.create_queue_table(
        queue_table=> 'PRJ_AsyncWS_Request',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    dbms_aqadm.create_queue_table(
        queue_table=>'PRJ_AsyncWS_Response',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    -- create AQ-JMS queues for PRJ

    dbms_aqadm.create_queue(
        queue_name=>'PRJ_AsyncWS_Request',
        queue_table=>'PRJ_AsyncWS_Request'
    );

    dbms_aqadm.create_queue(
        queue_name=> 'PRJ_AsyncWS_Response',
        queue_table=>'PRJ_AsyncWS_Response'
    );

    -- start the AQ-JMS queues for PRJ

    dbms_aqadm.start_queue(
        queue_name=>'PRJ_AsyncWS_Request'
    );

    dbms_aqadm.start_queue(
        queue_name=>'PRJ_AsyncWS_Response'
    );

------------------------

 -- create queue tables for JMS point-to-point (queues) for SCM
    dbms_aqadm.create_queue_table(
        queue_table=> 'SCM_AsyncWS_Request',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    dbms_aqadm.create_queue_table(
        queue_table=>'SCM_AsyncWS_Response',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    -- create AQ-JMS queues for SCM

    dbms_aqadm.create_queue(
        queue_name=>'SCM_AsyncWS_Request',
        queue_table=>'SCM_AsyncWS_Request'
    );

    dbms_aqadm.create_queue(
        queue_name=> 'SCM_AsyncWS_Response',
        queue_table=>'SCM_AsyncWS_Response'
    );

    -- start the AQ-JMS queues for SCM

    dbms_aqadm.start_queue(
        queue_name=>'SCM_AsyncWS_Request'
    );

    dbms_aqadm.start_queue(
        queue_name=>'SCM_AsyncWS_Response'
    );

------------------------

 -- create queue tables for JMS point-to-point (queues) for COMMON
    dbms_aqadm.create_queue_table(
        queue_table=> 'COMMON_AsyncWS_Request',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    dbms_aqadm.create_queue_table(
        queue_table=>'COMMON_AsyncWS_Response',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    -- create AQ-JMS queues for COMMON

    dbms_aqadm.create_queue(
        queue_name=>'COMMON_AsyncWS_Request',
        queue_table=>'COMMON_AsyncWS_Request'
    );

    dbms_aqadm.create_queue(
        queue_name=> 'COMMON_AsyncWS_Response',
        queue_table=>'COMMON_AsyncWS_Response'
    );

    -- start the AQ-JMS queues for COMMON

    dbms_aqadm.start_queue(
        queue_name=>'COMMON_AsyncWS_Request'
    );

    dbms_aqadm.start_queue(
        queue_name=>'COMMON_AsyncWS_Response'
    );

------------------------

 -- create queue tables for JMS point-to-point (queues) for IC
    dbms_aqadm.create_queue_table(
        queue_table=> 'IC_AsyncWS_Request',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    dbms_aqadm.create_queue_table(
        queue_table=>'IC_AsyncWS_Response',
        queue_payload_type=>'sys.aq$_jms_message',
        multiple_consumers=>false
    );

    -- create AQ-JMS queues for IC

    dbms_aqadm.create_queue(
        queue_name=>'IC_AsyncWS_Request',
        queue_table=>'IC_AsyncWS_Request'
    );

    dbms_aqadm.create_queue(
        queue_name=> 'IC_AsyncWS_Response',
        queue_table=>'IC_AsyncWS_Response'
    );

    -- start the AQ-JMS queues for IC

    dbms_aqadm.start_queue(
        queue_name=>'IC_AsyncWS_Request'
    );

    dbms_aqadm.start_queue(
        queue_name=>'IC_AsyncWS_Response'
    );

END;
/
