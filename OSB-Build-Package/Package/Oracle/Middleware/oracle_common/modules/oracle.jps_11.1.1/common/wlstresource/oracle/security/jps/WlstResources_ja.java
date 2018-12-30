/* $Header: wptg/jazn/jps/jrf/common/wlstresource/oracle/security/jps/WlstResources_ja.java /st_wptg_11.1.1.7.0/8 2012/12/14 09:29:06 gmolloy Exp $ */

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
    amitaga     08/14/12 - message for non existing files
    dpani       08/06/12 - XbranchMerge dpani_bug-14322802 from main
    jishang     07/17/12 - adding admin role not found message
    vaimodi     06/22/12 - XbranchMerge amitaga_opss_key_rollover_cmd from main
    asubbiay    04/24/12 - XbranchMerge asubbiay_bug-13745131 from main
    asubbiay    03/21/12 - Correcting migration message
    amitaga     03/08/12 - message for non-existing file
    amitaga     11/17/11 - message for sync key stores
    divyasin    10/13/11 - Fixed bugs 12947917 & 12919377 by adding FINE
                           logging for progress of migration and patching
                           (artifact count also logged)
    vigarg      10/11/11 - Bug# 13015655 - CHANGEKEYPASSWORD COMMAND DOESN'T
                           SHOW ERROR FOR NON-EXISTING ALIAS
    sourajai    10/03/11 - XbranchMerge sourajai_bug-8462592 from main
    vigarg      08/07/11 - XbranchMerge vigarg_import_export_cs_key from main
    vigarg      07/25/11 - XbranchMerge vigarg_password_protected_csf from main
    miqi        06/28/11 - XbranchMerge miqi_auditstore_reasso from main
    sourajai    09/19/11 - Fixed Bug 10215386 - MESSAGE FROM UPGRADEOPSS()
                           NEEDS TO BE CORRECTED
    miqi        01/24/11 - add reassociation messages for audit store
    amitaga     09/14/10 - remove farm from messages
    amitaga     07/15/10 - update message to make it more generic
    yiwawang    07/02/10 - added MSG_WLST_INVALID_STORE_TYPE
    dramakri    06/03/10 - Add error messages
    yiwawang    05/09/10 - make re-association info generic to ldap and db
    lappanmu    12/16/09 - Adding messages for configureidstore
    aqin        03/11/10 - Add ps2 upgrade messages.
    vigarg      02/02/09 - Creation
 */

/**
 *  @version $Header: wptg/jazn/jps/jrf/common/wlstresource/oracle/security/jps/WlstResources_ja.java /st_wptg_11.1.1.7.0/8 2012/12/14 09:29:06 gmolloy Exp $
 *  @author  vigarg  
 *  @since   release specific (what release of product did this appear in)
 */
package oracle.security.jps;

import java.util.ListResourceBundle;

public class WlstResources_ja extends ListResourceBundle implements WlstMessages {

    public Object[][] getContents() {
        return contents;
    }
    
    static final Object[][] contents =
    { 
        {MSG_WLST_COMMAND_FAILED, "\u30B3\u30DE\u30F3\u30C9\u306B\u5931\u6557\u3057\u307E\u3057\u305F\u3002\u7406\u7531: "},
        {MSG_WLST_UNKNOWN_REASON, "\u4E0D\u660E\u306A\u7406\u7531\u306B\u3088\u308A\u30B3\u30DE\u30F3\u30C9\u306B\u5931\u6557\u3057\u307E\u3057\u305F\u3002\u8A73\u7D30\u306F\u30B9\u30BF\u30C3\u30AF\u30FB\u30C8\u30EC\u30FC\u30B9\u3092\u78BA\u8A8D\u3057\u3066\u304F\u3060\u3055\u3044"},
        {MSG_WLST_APP_NOT_FOUND, "\u30A2\u30D7\u30EA\u30B1\u30FC\u30B7\u30E7\u30F3\u304C\u898B\u3064\u304B\u308A\u307E\u305B\u3093: "},
        {MSG_WLST_ADMIN_ROLE_NOT_FOUND, "\u7BA1\u7406\u30ED\u30FC\u30EB\u304C\u898B\u3064\u304B\u308A\u307E\u305B\u3093: "},
        {MSG_WLST_PRINCIPAL_NOT_FOUND, "\u30D7\u30EA\u30F3\u30B7\u30D1\u30EB\u304C\u898B\u3064\u304B\u308A\u307E\u305B\u3093: "},
        {MSG_WLST_ADMIN_RESOURCE_NOT_FOUND, "\u7BA1\u7406\u30EA\u30BD\u30FC\u30B9\u304C\u898B\u3064\u304B\u308A\u307E\u305B\u3093: "},
        {MSG_WLST_CRED_NOT_FOUND, "\u8CC7\u683C\u8A3C\u660E\u304C\u5B58\u5728\u3057\u306A\u3044\u304B\u3001\u30BF\u30A4\u30D7\u304C\"\u4E00\u822C\"\u306E\u5834\u5408\u306F\u30EA\u30B9\u30C8\u3067\u304D\u307E\u305B\u3093"},
        {MSG_WLST_REQUIRED_ARG_MISSING, "\u6B21\u306E\u5FC5\u9808\u306E\u5F15\u6570\u304C\u6E21\u3055\u308C\u307E\u305B\u3093\u3067\u3057\u305F: "},
        {MSG_WLST_GROUP_ARG_MISSING, "\u6B21\u306E\u30B0\u30EB\u30FC\u30D7\u3067\u6307\u5B9A\u3055\u308C\u3066\u3044\u308B\u5F15\u6570\u304C\u5C11\u306A\u3059\u304E\u307E\u3059: "},
        {MSG_WLST_CONFLICTING_ARG, "\u7AF6\u5408\u3059\u308B\u6B21\u306E\u5F15\u6570\u304C\u6307\u5B9A\u3055\u308C\u307E\u3057\u305F: "},
        {MSG_WLST_BOOLEAN_ARG, "\u6B21\u306E\u5024\u306E1\u3064\u306E\u307F\u3092\u6307\u5B9A\u3059\u308B\u5FC5\u8981\u304C\u3042\u308A\u307E\u3059: true\u3001false"},
        {MSG_WLST_POLICY_STORE_REASS_START, "\u30DD\u30EA\u30B7\u30FC\u30FB\u30B9\u30C8\u30A2\u306E\u518D\u95A2\u9023\u4ED8\u3051\u3092\u958B\u59CB\u3057\u3066\u3044\u307E\u3059\u3002"},
        {MSG_WLST_POLICY_STORE_REASS_END, "\u30DD\u30EA\u30B7\u30FC\u30FB\u30B9\u30C8\u30A2\u306E\u518D\u95A2\u9023\u4ED8\u3051\u304C\u5B8C\u4E86\u3057\u307E\u3057\u305F\u3002"},
        {MSG_WLST_CRED_STORE_REASS_START, "\u8CC7\u683C\u8A3C\u660E\u30B9\u30C8\u30A2\u306E\u518D\u95A2\u9023\u4ED8\u3051\u3092\u958B\u59CB\u3057\u3066\u3044\u307E\u3059"},
        {MSG_WLST_CRED_STORE_REASS_END, "\u8CC7\u683C\u8A3C\u660E\u30B9\u30C8\u30A2\u306E\u518D\u95A2\u9023\u4ED8\u3051\u304C\u5B8C\u4E86\u3057\u307E\u3057\u305F"},
        {MSG_WLST_KEY_STORE_REASS_START, "\u30AD\u30FC\u30B9\u30C8\u30A2\u306E\u518D\u95A2\u9023\u4ED8\u3051\u3092\u958B\u59CB\u3057\u3066\u3044\u307E\u3059"},
        {MSG_WLST_KEY_STORE_REASS_END, "\u30AD\u30FC\u30B9\u30C8\u30A2\u306E\u518D\u95A2\u9023\u4ED8\u3051\u304C\u5B8C\u4E86\u3057\u307E\u3057\u305F"},
        {MSG_WLST_CONFIG_CHANGE_REASS, "JPS\u69CB\u6210\u304C\u5909\u66F4\u3055\u308C\u307E\u3057\u305F\u3002\u30A2\u30D7\u30EA\u30B1\u30FC\u30B7\u30E7\u30F3\u30FB\u30B5\u30FC\u30D0\u30FC\u3092\u518D\u8D77\u52D5\u3057\u3066\u304F\u3060\u3055\u3044\u3002"},
        {MSG_WLST_LDAP_SERVER_SETUP_DONE, "\u30B9\u30C8\u30A2\u3068ServiceConfigurator\u306E\u30BB\u30C3\u30C8\u30A2\u30C3\u30D7\u304C\u5B8C\u4E86\u3057\u307E\u3057\u305F\u3002"},
        {MSG_WLST_LDAP_SCHEMA_SEEDED, "\u30B9\u30AD\u30FC\u30DE\u306F\u30B9\u30C8\u30A2\u306B\u30B7\u30FC\u30C9\u3055\u308C\u3066\u3044\u307E\u3059"},
        {MSG_WLST_DATA_REASS_MIGRATED, "\u30C7\u30FC\u30BF\u306F\u30B9\u30C8\u30A2\u306B\u79FB\u884C\u3055\u308C\u3066\u3044\u307E\u3059\u3002\u79FB\u884C\u4E2D\u306E\u969C\u5BB3\u307E\u305F\u306F\u8B66\u544A\u306F\u3001\u30ED\u30B0\u3092\u78BA\u8A8D\u3057\u3066\u304F\u3060\u3055\u3044\u3002"},
        {MSG_WLST_DATA_MIGRATED, "\u30C7\u30FC\u30BF\u306F\u30B9\u30C8\u30A2\u306B\u79FB\u884C\u3055\u308C\u3066\u3044\u307E\u3059\u3002\u30ED\u30B0\u304C\u6709\u52B9\u306B\u306A\u3063\u3066\u3044\u308B\u5834\u5408\u3001\u969C\u5BB3\u307E\u305F\u306F\u8B66\u544A\u306F\u30ED\u30B0\u3092\u78BA\u8A8D\u3057\u3066\u304F\u3060\u3055\u3044\u3002"},
        {MSG_WLST_SERVICE_POST_MIGRATION_OK, "\u79FB\u884C\u5F8C\u306E\u30B9\u30C8\u30A2\u306E\u30C7\u30FC\u30BF\u306F\u3001\u4F7F\u7528\u53EF\u80FD\u3067\u3042\u308B\u3053\u3068\u304C\u30C6\u30B9\u30C8\u3055\u308C\u307E\u3057\u305F"},
        {MSG_WLST_JPS_CONFIGURATION_DONE, "\u30E1\u30E2\u30EA\u30FC\u5185JPS\u69CB\u6210\u306E\u66F4\u65B0\u304C\u5B8C\u4E86\u3057\u307E\u3057\u305F"},
        {MSG_WLST_FKS_CREATE_KS_DONE, "\u30AD\u30FC\u30B9\u30C8\u30A2\u304C\u4F5C\u6210\u3055\u308C\u307E\u3057\u305F"},
        {MSG_WLST_FKS_DELETE_KS_DONE, "\u30AD\u30FC\u30B9\u30C8\u30A2\u304C\u524A\u9664\u3055\u308C\u307E\u3057\u305F"},
        {MSG_WLST_FKS_CHANGE_KS_PWD_DONE, "\u30AD\u30FC\u30B9\u30C8\u30A2\u306E\u30D1\u30B9\u30EF\u30FC\u30C9\u304C\u5909\u66F4\u3055\u308C\u307E\u3057\u305F"},
        {MSG_WLST_FKS_CREATE_KP_DONE, "\u9375\u30DA\u30A2\u304C\u751F\u6210\u3055\u308C\u307E\u3057\u305F"},
        {MSG_WLST_FKS_CREATE_SK_DONE, "\u79D8\u5BC6\u9375\u304C\u751F\u6210\u3055\u308C\u307E\u3057\u305F"},
        {MSG_WLST_FKS_CHANGE_KEY_PWD_DONE, "\u30AD\u30FC\u30B9\u30C8\u30A2\u306E\u9375\u30D1\u30B9\u30EF\u30FC\u30C9\u304C\u5909\u66F4\u3055\u308C\u307E\u3057\u305F"},
        {MSG_WLST_FKS_CERT_REQ_EXPORTED, "\u8A3C\u660E\u66F8\u30EA\u30AF\u30A8\u30B9\u30C8\u304C\u30A8\u30AF\u30B9\u30DD\u30FC\u30C8\u3055\u308C\u307E\u3057\u305F\u3002"},
        {MSG_WLST_FKS_CERT_REQ_FAILED, "\u8A3C\u660E\u66F8\u30EA\u30AF\u30A8\u30B9\u30C8\u306E\u751F\u6210\u306B\u5931\u6557\u3057\u307E\u3057\u305F\u3002"},
        {MSG_WLST_FKS_CERT_EXPORTED, "\u8A3C\u660E\u66F8\u304C\u30A8\u30AF\u30B9\u30DD\u30FC\u30C8\u3055\u308C\u307E\u3057\u305F\u3002"},
        {MSG_WLST_FKS_CERT_FAILED, "\u8A3C\u660E\u66F8\u306E\u30A8\u30AF\u30B9\u30DD\u30FC\u30C8\u306B\u5931\u6557\u3057\u307E\u3057\u305F\u3002"},
        {MSG_WLST_FKS_IMPORT_CERT_DONE, "\u8A3C\u660E\u66F8\u304C\u30A4\u30F3\u30DD\u30FC\u30C8\u3055\u308C\u307E\u3057\u305F\u3002"},
        {MSG_WLST_FKS_DELETE_ENTRY_DONE, "\u30AD\u30FC\u30B9\u30C8\u30A2\u30FB\u30A8\u30F3\u30C8\u30EA\u304C\u524A\u9664\u3055\u308C\u307E\u3057\u305F\u3002"},
        {MSG_WLST_FKS_EXPORT_KS_DONE, "\u30AD\u30FC\u30B9\u30C8\u30A2\u304C\u30A8\u30AF\u30B9\u30DD\u30FC\u30C8\u3055\u308C\u307E\u3057\u305F\u3002\u30A8\u30F3\u30C8\u30EA\u304C\u30B9\u30AD\u30C3\u30D7\u3055\u308C\u305F\u5834\u5408\u306F\u30ED\u30B0\u3092\u78BA\u8A8D\u3057\u3066\u304F\u3060\u3055\u3044\u3002"},
        {MSG_WLST_FKS_IMPORT_KS_DONE, "\u30AD\u30FC\u30B9\u30C8\u30A2\u304C\u30A4\u30F3\u30DD\u30FC\u30C8\u3055\u308C\u307E\u3057\u305F\u3002\u30A8\u30F3\u30C8\u30EA\u304C\u30B9\u30AD\u30C3\u30D7\u3055\u308C\u305F\u5834\u5408\u306F\u30ED\u30B0\u3092\u78BA\u8A8D\u3057\u3066\u304F\u3060\u3055\u3044\u3002"},
        {MSG_WLST_EMPTY_PROP_FILE, "\u6709\u52B9\u306A\u30D7\u30ED\u30D1\u30C6\u30A3\u30FB\u30D5\u30A1\u30A4\u30EB\u3092\u6307\u5B9A\u3057\u3066\u304F\u3060\u3055\u3044"},
        {MSG_WLST_ARG_NOVAL, "\u6B21\u306E\u5F15\u6570\u306B\u306F\u5024\u304C\u6307\u5B9A\u3055\u308C\u3066\u3044\u307E\u305B\u3093: "},
        {MSG_WLST_ARG_REPEATED, "\u6B21\u306E\u5F15\u6570\u304C\u8907\u6570\u56DE\u7E70\u308A\u8FD4\u3055\u308C\u3066\u3044\u307E\u3059: "},
        {MSG_WLST_ARG_UNSUPPORTED, "\u6B21\u306E\u5F15\u6570\u306F\u30B5\u30DD\u30FC\u30C8\u3055\u308C\u3066\u3044\u307E\u305B\u3093: "},
        {MSG_UPGRADE_BEGIN, "opss\u69CB\u6210\u304A\u3088\u3073\u30BB\u30AD\u30E5\u30EA\u30C6\u30A3\u30FB\u30B9\u30C8\u30A2\u306E\u30A2\u30C3\u30D7\u30B0\u30EC\u30FC\u30C9\u3092\u958B\u59CB\u3057\u3066\u3044\u307E\u3059\u3002"},
        {MSG_UPGRADE_END, "opss\u69CB\u6210\u304A\u3088\u3073\u30BB\u30AD\u30E5\u30EA\u30C6\u30A3\u30FB\u30B9\u30C8\u30A2\u306E\u30A2\u30C3\u30D7\u30B0\u30EC\u30FC\u30C9\u304C\u5B8C\u4E86\u3057\u307E\u3057\u305F\u3002"},
        {MSG_WLST_INVALID_STORE_TYPE, "\u30B9\u30C8\u30A2\u30FB\u30BF\u30A4\u30D7\u304C\u7121\u52B9\u3067\u3059: "},
        {MSG_INVALID_SERVICE_NAME, "\u30B5\u30FC\u30D3\u30B9\u540D\u304C\u7121\u52B9\u3067\u3059"},
        {MSG_INVALID_COMMAND_NAME, "\u30B3\u30DE\u30F3\u30C9\u540D\u304C\u7121\u52B9\u3067\u3059"},
        {MSG_WLST_XACML_EXPORT_DONE, "\u30DD\u30EA\u30B7\u30FC\u304CXACML\u306B\u6B63\u5E38\u306B\u30A8\u30AF\u30B9\u30DD\u30FC\u30C8\u3055\u308C\u307E\u3057\u305F\u3002"},
        {MSG_WLST_AUDIT_STORE_REASS_START, "\u76E3\u67FB\u30B9\u30C8\u30A2\u306E\u518D\u95A2\u9023\u4ED8\u3051\u3092\u958B\u59CB\u3057\u3066\u3044\u307E\u3059"},
        {MSG_WLST_AUDIT_STORE_REASS_END, "\u76E3\u67FB\u30B9\u30C8\u30A2\u306E\u518D\u95A2\u9023\u4ED8\u3051\u304C\u5B8C\u4E86\u3057\u307E\u3057\u305F"},
        {MSG_WLST_IMPORT_CS_KEY_DONE, "\u6697\u53F7\u5316\u9375\u306E\u30A4\u30F3\u30DD\u30FC\u30C8\u304C\u5B8C\u4E86\u3057\u307E\u3057\u305F\u3002ewallet.p12\u30D5\u30A1\u30A4\u30EB\u304C\u3059\u3079\u3066\u306E\u5FC5\u9808\u30C9\u30E1\u30A4\u30F3\u306B\u30A4\u30F3\u30DD\u30FC\u30C8\u3055\u308C\u305F\u3089\u3001\u3053\u306E\u30D5\u30A1\u30A4\u30EB\u3092\u7834\u68C4\u3057\u3066\u304F\u3060\u3055\u3044"},
        {MSG_WLST_EXPORT_CS_KEY_DONE, "\u6697\u53F7\u5316\u9375\u306E\u30A8\u30AF\u30B9\u30DD\u30FC\u30C8\u304C\u5B8C\u4E86\u3057\u307E\u3057\u305F\u3002\u9078\u629E\u3057\u305F\u30D1\u30B9\u30EF\u30FC\u30C9\u306F\u9375\u306E\u30A4\u30F3\u30DD\u30FC\u30C8\u6642\u306B\u5FC5\u8981\u3068\u306A\u308B\u305F\u3081\u3001\u5FD8\u308C\u306A\u3044\u3088\u3046\u306B\u3057\u3066\u304F\u3060\u3055\u3044"},
        {MSG_WLST_RESTORE_CS_KEY_DONE, "\u6697\u53F7\u5316\u9375\u306E\u30EA\u30B9\u30C8\u30A2\u304C\u5B8C\u4E86\u3057\u307E\u3057\u305F\u3002"},
        {MSG_WLST_ROLLOVER_KEY_DONE, "\u6697\u53F7\u5316\u9375\u306E\u30ED\u30FC\u30EB\u30AA\u30FC\u30D0\u30FC\u304C\u5B8C\u4E86\u3057\u307E\u3057\u305F\u3002"},
        {MSG_FILE_NON_EXISTENT, "\u30D5\u30A1\u30A4\u30EB\u30FB\u30D1\u30B9\u304C\u7121\u52B9\u3067\u3059\u3002"},
    };
}
