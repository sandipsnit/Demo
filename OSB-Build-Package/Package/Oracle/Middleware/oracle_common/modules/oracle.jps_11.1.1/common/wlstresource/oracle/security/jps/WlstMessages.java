/* $Header: jazn/jps/jrf/common/wlstresource/oracle/security/jps/WlstMessages.java /st_entsec_11.1.1.7.0/4 2012/08/31 14:29:05 amitaga Exp $ */

/* Copyright (c) 2009, 2012, Oracle and/or its affiliates. 
All rights reserved. */

/*
   DESCRIPTION
    <short description of component this file declares/defines>

   PRIVATE CLASSES
    <list of private classes defined - with one-line descriptions>

   NOTES
    <other useful comments, qualifications, etc.>

   MODIFIED    (MM/DD/YY)
    amitaga     08/14/12 - message for non existing file
    vaimodi     06/22/12 - XbranchMerge amitaga_opss_key_rollover_cmd from main
    asubbiay    04/24/12 - XbranchMerge asubbiay_bug-13745131 from main
    vigarg      08/07/11 - XbranchMerge vigarg_import_export_cs_key from main
    vigarg      07/25/11 - XbranchMerge vigarg_password_protected_csf from main
    miqi        06/28/11 - XbranchMerge miqi_auditstore_reasso from main
    miqi        01/24/11 - add reassociation messages for audit store
    yiwawang    07/02/10 - added MSG_WLST_INVALID_STORE_TYPE
    dramakri    06/03/10 - Add error messages
    lappanmu    12/16/09 - Added resources for configure id store
    aqin        03/11/10 - Add ps2 upgrade messages.
    vigarg      02/06/09 - Creation
 */

/**
 *  @version $Header: jazn/jps/jrf/common/wlstresource/oracle/security/jps/WlstMessages.java /st_entsec_11.1.1.7.0/4 2012/08/31 14:29:05 amitaga Exp $
 *  @author  vigarg  
 *  @since   release specific (what release of product did this appear in)
 */

package oracle.security.jps;

public interface WlstMessages {
    public static final String MSG_WLST_ADMIN_RESOURCE_NOT_FOUND =  "JPS_06002";
    public static final String MSG_WLST_PRINCIPAL_NOT_FOUND =  "JPS_06001";
    public static final String MSG_WLST_ADMIN_ROLE_NOT_FOUND = "JPS_06000";
    public static final String MSG_WLST_COMMAND_FAILED = "JPS-05999";
    public static final String MSG_WLST_UNKNOWN_REASON = "JPS-05998";
    public static final String MSG_WLST_APP_NOT_FOUND = "JPS-05997";
    public static final String MSG_WLST_CRED_NOT_FOUND = "JPS-05996";
    public static final String MSG_WLST_REQUIRED_ARG_MISSING = "JPS-05995";
    public static final String MSG_WLST_GROUP_ARG_MISSING = "JPS-05994";
    public static final String MSG_WLST_CONFLICTING_ARG = "JPS-05993";
    public static final String MSG_WLST_BOOLEAN_ARG = "JPS-05992";
    public static final String MSG_WLST_POLICY_STORE_REASS_START = "JPS-05991";
    public static final String MSG_WLST_POLICY_STORE_REASS_END = "JPS-05990";
    public static final String MSG_WLST_CRED_STORE_REASS_START = "JPS-05989";
    public static final String MSG_WLST_CRED_STORE_REASS_END = "JPS-05988";
    public static final String MSG_WLST_CONFIG_CHANGE_REASS = "JPS-05987";
    public static final String MSG_WLST_LDAP_SERVER_SETUP_DONE = "JPS-05986";
    public static final String MSG_WLST_LDAP_SCHEMA_SEEDED = "JPS-05985";
    public static final String MSG_WLST_DATA_MIGRATED = "JPS-05984";
    public static final String MSG_WLST_SERVICE_POST_MIGRATION_OK = "JPS-05983";
    public static final String MSG_WLST_JPS_CONFIGURATION_DONE = "JPS-05982";
    public static final String MSG_WLST_FKS_SETPOLICY_DONE = "JPS-05981";
    public static final String MSG_WLST_FKS_DELETEPOLICY_DONE = "JPS-05980";
    public static final String MSG_WLST_FKS_CREATE_KS_DONE = "JPS-05979";
    public static final String MSG_WLST_FKS_DELETE_KS_DONE = "JPS-05978";
    public static final String MSG_WLST_FKS_CHANGE_KS_PWD_DONE = "JPS-05977";
    public static final String MSG_WLST_FKS_CREATE_KP_DONE = "JPS-05976";
    public static final String MSG_WLST_FKS_CREATE_SK_DONE = "JPS-05975";
    public static final String MSG_WLST_FKS_CHANGE_KEY_PWD_DONE = "JPS-05974";
    public static final String MSG_WLST_FKS_CERT_REQ_EXPORTED = "JPS-05973";
    public static final String MSG_WLST_FKS_CERT_REQ_FAILED = "JPS-05972";
    public static final String MSG_WLST_FKS_CERT_EXPORTED = "JPS-05971";
    public static final String MSG_WLST_FKS_CERT_FAILED = "JPS-05970";
    public static final String MSG_WLST_FKS_IMPORT_CERT_DONE = "JPS-05969";
    public static final String MSG_WLST_FKS_DELETE_ENTRY_DONE = "JPS-05968";
    public static final String MSG_WLST_FKS_EXPORT_KS_DONE = "JPS-05967";
    public static final String MSG_WLST_FKS_IMPORT_KS_DONE = "JPS-05966";
    public static final String MSG_WLST_EMPTY_PROP_FILE = "JPS-05965";
    public static final String MSG_WLST_KEY_STORE_REASS_START = "JPS-05964";
    public static final String MSG_WLST_KEY_STORE_REASS_END = "JPS-05963";
    public static final String MSG_WLST_ARG_NOVAL = "JPS-05962";
    public static final String MSG_WLST_ARG_REPEATED = "JPS-05961";
    public static final String MSG_WLST_ARG_UNSUPPORTED = "JPS-05960";
    public static final String MSG_UPGRADE_BEGIN = "JPS-05959";
    public static final String MSG_UPGRADE_END = "JPS-05958";
    public static final String MSG_WLST_INVALID_STORE_TYPE = "JPS-05957";
    public static final String MSG_INVALID_SERVICE_NAME = "JPS-05956";
    public static final String MSG_INVALID_COMMAND_NAME = "JPS-05955";
    public static final String MSG_WLST_XACML_EXPORT_DONE = "JPS-05954";
    public static final String MSG_WLST_AUDIT_STORE_REASS_START = "JPS-05953";
    public static final String MSG_WLST_AUDIT_STORE_REASS_END = "JPS-05952";
    public static final String MSG_WLST_IMPORT_CS_KEY_DONE = "JPS-05951";
    public static final String MSG_WLST_EXPORT_CS_KEY_DONE = "JPS-05950";
    public static final String MSG_WLST_RESTORE_CS_KEY_DONE = "JPS-05949";
    public static final String MSG_WLST_ROLLOVER_KEY_DONE = "JPS-05948";
    public static final String MSG_FILE_NON_EXISTENT = "JPS-05946";
    public static final String MSG_WLST_DATA_REASS_MIGRATED = "JPS-05945";
}

