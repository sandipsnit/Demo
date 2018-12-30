
//************************************************************************************************//
// This file is used to define map used on help. Map is an array which contains jspID and helpID  //
// as key-value pair. Each jspID is defined in the jsp pages. HelpID is the url to be called      //
// to show help topic.                                                                            //
//************************************************************************************************//

var helpArray = new Array();
var ix = 0;

//helpArray[ix++] = new Array( "Monitoring_ServerSummary", "monitoringViewDashboardStatistics" );
//helpArray[ix++] = new Array( "Monitoring_ServerDetail", "monitoringViewDashboardStatistics" );
//helpArray[ix++] = new Array( "Monitoring_ViewChart", "monitoringViewDashboardStatistics" );
//helpArray[ix++] = new Array( "Monitoring_ViewGlobalStats", "monitoringViewDashboardStatistics" );
helpArray[ix++] = new Array( "Monitoring_View_Service_Metrics", "monitoringViewServiceMetrics" );
helpArray[ix++] = new Array( "Monitoring_View_Flow_Components_Metrics", "monitoringViewPipelineMetrics" );
helpArray[ix++] = new Array( "Monitoring_View_Operations_Metrics", "monitoringViewOperationsMetrics" );
helpArray[ix++] = new Array( "Monitoring_View_Endpoints_Metrics", "monitoringViewEndpointsMetrics" );
helpArray[ix++] = new Array( "Monitoring_View_Action_Metrics", "monitoringViewActionMetrics" ); 

helpArray[ix++] = new Array( "Services_ViewAllProxyServices", "proxyserviceListandLocateProxyServices" );
helpArray[ix++] = new Array( "Services_ViewAllExternalServices", "businessServiceListandLocateBusinessServices" );
helpArray[ix++] = new Array( "Services_ViewProxyService", "proxyserviceViewProxyServiceConfigurationDetailsPage" );
helpArray[ix++] = new Array( "Services_ViewExternalService", "businessserviceViewBusinessServiceConfigurationDetailsPage" );
helpArray[ix++] = new Array( "Services_ServicesBrowser", "proxyserviceAddProxyService" );
helpArray[ix++] = new Array( "Services_ProxyServiceBinding", "proxyserviceCreateProxyServiceMessageTypeConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceBinding", "bizSvcMessageTypeConfigurationPage" );
helpArray[ix++] = new Array( "Services_CreateProxyService", "proxyserviceCreateProxyServiceGeneralConfigurationPage" );
helpArray[ix++] = new Array( "Services_EditProxyService", "proxyserviceCreateProxyServiceGeneralConfigurationPage" );
helpArray[ix++] = new Array( "Services_CreateExternalService", "bizSvcGeneralConfigurationPage" );
helpArray[ix++] = new Array( "Services_EditExternalService", "bizSvcGeneralConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceSecurity", "proxyserviceMessageLevelSecurityConfiguration" );
helpArray[ix++] = new Array( "Services_ExternalServiceSecurity", "businessServiceAddBusinessService" );
helpArray[ix++] = new Array( "Services_ProxyServiceSelector", "proxyserviceCreateProxyServiceOperationSelectionConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceSelector", "bizSvcSOAPConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceSummary", "proxyserviceCreateProxyServiceSummaryPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceSummary", "bizSvcSummaryPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransport", "proxyserviceCreateProxyServiceTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransport", "bizSvcTransportConfigurationPage" );

helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific",              "proxyserviceCreateProxyServiceTransportSpecificConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_EMAIL",        "proxyserviceCreateProxyServiceEMailTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_FILE",         "proxyserviceCreateProxyServiceFileTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_FTP",          "proxyserviceCreateProxyServiceFTPTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_HTTP",         "proxyserviceCreateProxyServiceHTTPTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_JCA",          "proxyserviceCreateProxyServiceJCATransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_JEJB",         "proxyserviceCreateProxyServiceJEJBTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_JMS",          "proxyserviceCreateProxyServiceJMSTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_SB",           "proxyserviceCreateProxyServiceSBTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_TUXEDO",       "proxyserviceCreateProxyServiceTuxedoTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_MQ",           "proxyserviceCreateProxyServiceMQTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_SFTP",         "proxyserviceCreateProxyServiceSFTPTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_WS",           "proxyserviceCreateProxyServiceWSTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceTransportSpecific_$$CUSTOM$$",   "proxyserviceCreateProxyServiceTransportSpecificConfigurationPage" );
helpArray[ix++] = new Array( "ProxyServices_OperationalSettings",                   "proxyserviceEditOperatonalSettingsPage" );
helpArray[ix++] = new Array( "ProxyServices_PoliciesSummary",                   "proxyserviceViewProxyServicePolicyConfigurationPage" );
helpArray[ix++] = new Array( "ProxyServices_SecuritySummary",                   "proxyserviceViewProxyServiceSecurityConfigurationPage" );
helpArray[ix++] = new Array( "BusinessServices_OperationalSettings",                "bizserviceEditOperatonalSettingsPage" );
helpArray[ix++] = new Array( "Services_ProxyServiceMsgContentHandling",         "proxyserviceCreateProxyServiceMessageContentHandlingPage");
helpArray[ix++] = new Array( "Services_ExternalServiceMsgContentHandling",      "bizSvcMessageContentHandlingConfigurationPage");
helpArray[ix++] = new Array( "BusinessServices_PoliciesSummary",                "businessserviceViewBusinessServicePolicyConfigurationPage" );
helpArray[ix++] = new Array( "BusinessServices_SecuritySummary",                "businessserviceViewBusinessServiceSecurityConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific",           "bizSvcProtocolSpecificTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_BPEL-10G",  "bizSvcBPEL10GTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_DSP",       "bizSvcDSPTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_EJB",       "bizSvcEJBTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_EMAIL",     "bizSvcEMailTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_FILE",      "bizSvcFileTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_FLOW",      "bizSvcFlowTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_FTP",       "bizSvcFTPTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_HTTP",      "bizSvcHTTPTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_JCA",       "bizSvcJCATransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_JEJB",      "bizSvcJEJBTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_JMS",       "bizSvcJMSTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_JPD",       "bizSvcJPDTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_SB",        "bizSvcSBTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_MQ",        "bizSvcMQTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_SFTP",      "bizSvcSFTPTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_SOA-DIRECT", "bizSvcSOADIRECTTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_WS",        "bizSvcWSTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_TUXEDO",    "bizSvcTuxedoTransportConfigurationPage" );
helpArray[ix++] = new Array( "Services_ExternalServiceTransportSpecific_$$CUSTOM$$","bizSvcProtocolSpecificTransportConfigurationPage" );

helpArray[ix++] = new Array( "Services_Operational_Settings", "monitoringConfiguringServices" );

helpArray[ix++] = new Array( "AlertRules_EditRule", "monitoringViewAlertRuleDetails" );
helpArray[ix++] = new Array( "AlertRules_NewRule", "monitoringCreateAlertRule" );
helpArray[ix++] = new Array( "AlertRules_AlertRuleDetails", "monitoringViewAlertRuleDetails" );
helpArray[ix++] = new Array( "AlertRules_ViewAlertRules", "monitoringListandLocateAlertRules" );

helpArray[ix++] = new Array( "Pipelines_EditBranchNode", "proxyserviceAddConditionalBranchNode" );
helpArray[ix++] = new Array( "Pipelines_EditErrorHandler", "proxyserviceEditErrorHandlerPage" );
helpArray[ix++] = new Array( "Pipelines_EditPipelineMain", "proxyserviceEditMessageFlowPage" );
helpArray[ix++] = new Array( "Pipelines_PipelinesTree", "proxyserviceViewandChangeMessageFlow" );

helpArray[ix++] = new Array( "Stages_EditStages", "proxyserviceEditStageConfigurationPage" );

helpArray[ix++] = new Array( "Resources_CreateSchema", "schemasAddSchema" );
helpArray[ix++] = new Array( "Resources_EditSchema", "schemasViewandChangeSchema" );
helpArray[ix++] = new Array( "Resources_EditSchemaRef", "schemasViewUnresolvedSchemaRef" );
helpArray[ix++] = new Array( "Resources_SchemaBrowser", "schemasAddSchema" );
helpArray[ix++] = new Array( "Resources_SchemaDetails", "schemasViewandChangeSchema" );
helpArray[ix++] = new Array( "Resources_ViewAllSchemas", "schemasListandLocateSchemas" );
helpArray[ix++] = new Array( "Resources_ViewSchema", "schemasViewandChangeSchema" );

helpArray[ix++] = new Array( "Resources_CreateWsdl", "wsdlsAddWSDL" );
helpArray[ix++] = new Array( "Resources_EditWsdl", "wsdlsViewandChangeWSDL" );
helpArray[ix++] = new Array( "Resources_EditWsdlRef", "wsdlsResolveWSDL" );
helpArray[ix++] = new Array( "Resources_ViewAllWsdls", "wsdlsListandLocateWSDLs" );
helpArray[ix++] = new Array( "Resources_ViewWsdl", "wsdlsViewandChangeWSDL" );
helpArray[ix++] = new Array( "Resources_WsdlBrowser", "wsdlsAddWSDL" );
helpArray[ix++] = new Array( "Resources_WsdlDetails", "wsdlsViewandChangeWSDL" );

helpArray[ix++] = new Array( "Resources_ViewAllXQs", "xquerytransformationListandLocateXQueryTransforms" );
helpArray[ix++] = new Array( "Resources_ViewXQ", "xquerytransformationViewandChangeTransformation" );
helpArray[ix++] = new Array( "Resources_XQDetails", "xquerytransformationViewandChangeTransformation" );
helpArray[ix++] = new Array( "Resources_CreateXQ", "xquerytransformationAddXQueryTransform" );
helpArray[ix++] = new Array( "Resources_EditXQ", "xquerytransformationViewandChangeTransformation" );

helpArray[ix++] = new Array( "Resources_CreateXslt", "xslttransformationAddXSLTTransform" );
helpArray[ix++] = new Array( "Resources_EditXslt", "xslttransformationViewandChangeXSLTTransform" );
helpArray[ix++] = new Array( "Resources_ViewAllXslts", "xslttransformationListandLocateXSLTTransforms" );
helpArray[ix++] = new Array( "Resources_ViewXslt", "xslttransformationViewandChangeXSLTTransform" );
helpArray[ix++] = new Array( "Resources_XsltDetails", "xslttransformationViewandChangeXSLTTransform" );
helpArray[ix++] = new Array( "Resources_EditXsltRef", "xslttransformationViewingUnresolvedXSLTs" );
helpArray[ix++] = new Array( "Resources_XsltBrowser", "xslttransformationAddXSLTTransform" );

helpArray[ix++] = new Array( "Resources_CreateMfl", "MFLsAddMFL" );
helpArray[ix++] = new Array( "Resources_EditMfl", "MFLsViewandChangeMFL" );
helpArray[ix++] = new Array( "Resources_ViewAllMfls", "MFLsListandLocateMFLs" );
helpArray[ix++] = new Array( "Resources_ViewMfl", "MFLsViewandChangeMFL" );
helpArray[ix++] = new Array( "Resources_MflDetails", "MFLsViewandChangeMFL" );

helpArray[ix++] = new Array( "Resources_EditProvider", "proxyServiceProvidersViewandChangeProxyServiceProvider" );
helpArray[ix++] = new Array( "Resources_NewProvider", "proxyServiceProvidersAddProxyServiceProvider" );
helpArray[ix++] = new Array( "Resources_ViewAllProviders", "proxyServiceProvidersListandLocateProxyServiceProviders" );
helpArray[ix++] = new Array( "Resources_ViewProvider", "proxyServiceProvidersViewandChangeProxyServiceProvider" );
helpArray[ix++] = new Array( "Resources_ProviderBrowser", "proxyServiceProvidersAddProxyServiceProvider" );

helpArray[ix++] = new Array( "Resources_CreateSecurityPolicy", "policiesAddPolicy" );
helpArray[ix++] = new Array( "Resources_EditSecurityPolicy", "policiesViewandChangePolicies" );
helpArray[ix++] = new Array( "Resources_ViewAllSecurityPolicies", "policiesListandLocatePolicies" );
helpArray[ix++] = new Array( "Resources_ViewSecurityPolicy", "policiesViewandChangePolicies" );
helpArray[ix++] = new Array( "Resources_SecurityPolicyBrowser", "policiesAddPolicy" );
helpArray[ix++] = new Array( "Resources_ResourceReference", "projectexplorerViewReferences" );

helpArray[ix++] = new Array( "Projects_ViewAllProjects", "projectexplorerListProjects" );
helpArray[ix++] = new Array( "Projects_ProjectDetail", "projectexplorerViewandEditProject" );
helpArray[ix++] = new Array( "Projects_ProjectReference", "projectexplorerViewReferences" );

helpArray[ix++] = new Array( "Deployment_Export_UpdateExport", "systemadminExportConfigurationData" );
helpArray[ix++] = new Array( "Deployment_Export_ViewExportRepository", "systemadminExportConfigurationData" );
helpArray[ix++] = new Array( "Deployment_Export_ViewExportRepository", "systemadminExportConfigurationData" );
helpArray[ix++] = new Array( "Deployment_Export_EnterExportPassphrase", "systemadminExportSecuritySettings" );
helpArray[ix++] = new Array( "Deployment_Import_ReviewDeploy", "systemadminImportConfigurationData" );
helpArray[ix++] = new Array( "Deployment_Import_ViewDeploymentError", "systemadminImportConfigurationData" );
helpArray[ix++] = new Array( "Deployment_Import_ViewDeploymentResult", "systemadminImportConfigurationData" );
helpArray[ix++] = new Array( "Deployment_Import_CreateImportRepository", "systemadminImportConfigurationData" );
helpArray[ix++] = new Array( "Deployment_Import_ViewImportRepository", "systemadminSelectingResources" );
helpArray[ix++] = new Array( "Deployment_ViewRefs", "systemadminImportConfigurationData" );
helpArray[ix++] = new Array( "Deployment_Import_EnterImportPassphrase", "systemadminImportSecuritySettings" );
helpArray[ix++] = new Array( "Deployment_Import_FinishImport", "systemadminImportSummary" );

helpArray[ix++] = new Array( "UserMgmt_AddGroup", "securityconfigurationAddGroup" );
helpArray[ix++] = new Array( "UserMgmt_AddUser", "securityconfigurationAddUser" );
helpArray[ix++] = new Array( "UserMgmt_EditGroup", "securityconfigurationViewandChangeGroup" );
helpArray[ix++] = new Array( "UserMgmt_EditUser", "securityconfigurationViewandChangeUserDetails" );
helpArray[ix++] = new Array( "UserMgmt_ViewGroup", "securityconfigurationViewandChangeGroup" );
helpArray[ix++] = new Array( "UserMgmt_ViewGroups", "securityconfigurationListandLocateGroups" );
helpArray[ix++] = new Array( "UserMgmt_ViewUser", "securityconfigurationViewandChangeUserDetails" );
helpArray[ix++] = new Array( "UserMgmt_ViewUsers", "securityconfigurationListandLocateUsers" );

helpArray[ix++] = new Array( "CredentialMgmt_ViewCertificate", "securityconfigurationViewCertificateDetails" );

// Transport and Service Atz Policies
helpArray[ix++] = new Array( "SecurityConfiguration_AccessControl_EditTransportAuthorizationPolicies", "securityconfigurationEditTransportAuthorizationPolicies" );
helpArray[ix++] = new Array( "SecurityConfiguration_AccessControl_EditServiceAuthorizationPolicies", "securityconfigurationEditServiceAuthorizationPolicies" );

helpArray[ix++] = new Array( "Resources_ViewAllServiceAccounts", "serviceAccountsListandLocateServiceAccounts" );
helpArray[ix++] = new Array( "Resources_CreateServiceAccount",   "serviceAccountsAddServiceAccount" );
helpArray[ix++] = new Array( "Resources_EditServiceAccount",     "serviceAccountsViewandChangeServiceAccount" );
helpArray[ix++] = new Array( "Resources_ViewServiceAccount",     "serviceAccountsViewandChangeServiceAccount" );

// WLS help topics
helpArray[ix++] = new Array( "WLS_Securitysecurityrealmrolestabletitle", "securityconfigurationListandLocateRoles" );

// Dashboard
helpArray[ix++] = new Array( "Dashboard_AlertDetail" , "monitoringViewAlertDetails" ) ;
helpArray[ix++] = new Array( "Dashboard_AlertsAsBarGraph" , "monitoringLocateAlerts"  ) ;
helpArray[ix++] = new Array( "Dashboard_AlertsAsPieGraph" , "monitoringLocateAlerts") ;
helpArray[ix++] = new Array( "Dashboard_SlaAlertSummary" , "monitoringViewDashboardSLAStatistics") ;
helpArray[ix++] = new Array( "Dashboard_PipelineAlertSummary" , "monitoringViewDashboardPipelineStatistics") ;
helpArray[ix++] = new Array( "Dashboard_AlertSummaryDetail" , "monitoringLocateAlerts") ;
helpArray[ix++] = new Array( "Dashboard_PurgeAlerts" , "monitoringPurgeAlerts") ;
helpArray[ix++] = new Array( "Dashboard_ServerDetail" , "monitoringListandLocateServers") ;
helpArray[ix++] = new Array( "Dashboard_ServerSummary" , "monitoringListandLocateServers"  ) ;
helpArray[ix++] = new Array( "Dashboard_ServerAsBarGraph" , "monitoringListandLocateServers" ) ;
helpArray[ix++] = new Array( "Dashboard_ServerAsPieGraph" , "monitoringListandLocateServers" ) ;
helpArray[ix++] = new Array( "Dashboard_ServiceSummary" , "monitoringListandLocateServices") ;

// WLS help for editing policies for proxy services
helpArray[ix++] = new Array( "WLS_Securitysecurityrealmpoliciestabletitle" , "securityconfigurationListandLocateAccessControls") ;

// Help for pages displayed by clicking links in Change Center

helpArray[ix++] = new Array( "ChangeCenter_View_Changes" , "changecenterViewingChanges") ;
helpArray[ix++] = new Array( "ChangeCenter_View_All_Sessions" , "changecenterViewAllSessions") ;
helpArray[ix++] = new Array( "ChangeCenter_View_Conflicts" , "changecenterViewConflicts") ;
helpArray[ix++] = new Array( "ChangeCenter_View_Task_Details" , "changecenterViewTaskDetails") ;
helpArray[ix++] = new Array( "ChangeCenter_Activate_Session",  "changecenterActivateSession");
helpArray[ix++] = new Array( "ChangeCenter_Purge_Tasks",  "changecenterPurgeTasks"); 

//Help for Message Reporting
helpArray[ix++] = new Array( "Reporting_MessageSummary", "reportingListandLocateMessages" );
helpArray[ix++] = new Array( "Reporting_MessageDetail", "reportingViewMessageDetails" );
helpArray[ix++] = new Array( "Reporting_PurgeMessages", "reportingPurgeMessages" );
helpArray[ix++] = new Array( "Reporting_NoReportingProvider", "reportingListandLocateMessages" );
helpArray[ix++] = new Array( "Reporting_NoPurgingApplication", "reportingPurgeMessages" );
helpArray[ix++] = new Array( "MonitoringConfiguration_EnableMonitoring", "configurationEnablingGlobalSettings" );

// Help for AlerRule Configuration pages
helpArray[ix++] = new Array( "AlertRules_ViewAlertRules",			        "monitoringListandLocateAlertRules");
helpArray[ix++] = new Array( "AlertRules_EditAlertRule_Details",		    "monitoringEditAlertRuleDetails");
helpArray[ix++] = new Array( "AlertRules_EditAlertRule_Actions",		    "monitoringCreateAlertRule") ;
helpArray[ix++] = new Array( "AlertRules_EditAlertRule_ActionSpecific",     "monitoringCreateAlertRule");
helpArray[ix++] = new Array( "AlertRules_EditAlertRule_Conditions",	        "monitoringCreateAlertRule");
helpArray[ix++] = new Array( "AlertRules_EditAlertRule_Summary",		    "monitoringViewAlertRuleDetails");
helpArray[ix++] = new Array( "AlertRules_ViewAlertRule_Summary",		    "monitoringViewAlertRuleDetails");
helpArray[ix++] = new Array( "XQuery_Expression_Builder",		            "proxyservicesCreatingAndEditingInlineExpressions");
helpArray[ix++] = new Array( "XQuery_Condition_Builder",		            "proxyservicesCreatingAndEditingInlineExpressions");
helpArray[ix++] = new Array( "XPath_Expression_Builder",		            "proxyservicesCreatingAndEditingInlineExpressions");
helpArray[ix++] = new Array( "New_XQuery_Variable",		                    "proxyserviceDefineContextVariable");

helpArray[ix++] = new Array( "DashboardConfiguration_RefreshInterval",	  "monitoringChangingDashboardSettings");
helpArray[ix++] = new Array( "WLS_Servermonitoring",	  "monitoringViewServerDetails");
helpArray[ix++] = new Array( "WLS_domainlogmonitoring",	  "monitoringViewServerLogFiles");
helpArray[ix++] = new Array( "Services_ViewTracingStatus",	  "configurationTracingStatus");

//Zipped Resources and Resources from URL
helpArray[ix++] = new Array( "Resources_LoadZippedResources", "projectexplorerLoadZippedResources" );
helpArray[ix++] = new Array( "Resources_LoadUrlResources", "projectexplorerLoadUrlResources" );
helpArray[ix++] = new Array( "Resources_ViewLoadedResources", "projectexplorerReviewLoadedResources" );
helpArray[ix++] = new Array( "Resources_FinishImportResources", "projectexplorerViewImportResults" );
helpArray[ix++] = new Array( "Resources_View_Change_History",  "projectexplorerViewChangeHistory"); 

//Help for UDDI Configuration, Import and Publish pages
helpArray[ix++] = new Array( "UDDIConfiguration_ConfigurationsListing",	  "systemadminRegistryConfiguration");
helpArray[ix++] = new Array( "UDDIConfiguration_EditConfiguration",	      "systemadminConfigChangesRegistry");
helpArray[ix++] = new Array( "UDDIConfiguration_ViewConfiguration",       "systemadminConfigChangesRegistry");
helpArray[ix++] = new Array( "UDDIImport_SelectRegistryPage",	          "systemadminImportFromRegistry");
helpArray[ix++] = new Array( "UDDIImport_SearchBusinessServices",	      "systemadminImportFromRegistry");
helpArray[ix++] = new Array( "UDDIImport_SelectIndividualServices",	      "systemadminImportFromRegistry");
helpArray[ix++] = new Array( "UDDIImport_SelectImportLocation",	          "systemadminImportFromRegistry");
helpArray[ix++] = new Array( "UDDIImport_ReviewImportServices",	          "systemadminImportFromRegistry");
helpArray[ix++] = new Array( "UDDIImport_ImportServicesSummary",	      "systemadminImportFromRegistry");
helpArray[ix++] = new Array( "UDDIPublish_SelectRegistryPage",	          "systemadminPublishToRegistry");
helpArray[ix++] = new Array( "UDDIPublish_PublishServices",	              "systemadminPublishToRegistry");
helpArray[ix++] = new Array( "UDDIPublish_PublishServicesSummary",	      "systemadminPublishToRegistry");
//Auto Import and publish related
helpArray[ix++] = new Array( "UDDIImport_UDDIAutoImportStatus",	      "systemadminAutoImport");
helpArray[ix++] = new Array( "UDDIImport_UDDIAutoImportResult",	      "systemadminAutoImport");
helpArray[ix++] = new Array( "UDDIPublish_UDDIAutoPublishStatus",	  "systemadminAutoPublish");
helpArray[ix++] = new Array( "UDDIPublish_UDDIAutoPublishResult",	  "systemadminAutoPublish");

//Test Console
helpArray[ix++] = new Array( "Test_ServiceRequest",	                  "testingServices");
helpArray[ix++] = new Array( "Test_ServiceResult",	                  "testingServices");
helpArray[ix++] = new Array( "Test_XQueryRequest",	                  "testingResources");
helpArray[ix++] = new Array( "Test_XQueryResult",	                  "testingResources");
helpArray[ix++] = new Array( "Test_XQueryXPathExpressionRequest",	  "testingInlineXQuery");
helpArray[ix++] = new Array( "Test_XQueryXPathExpressionResult",	  "testingInlineXQuery");
helpArray[ix++] = new Array( "Test_XsltRequest",	                  "testingResources");
helpArray[ix++] = new Array( "Test_XsltResult",	                      "testingResources");
helpArray[ix++] = new Array( "Test_MflRequest",	                      "testingResources");
helpArray[ix++] = new Array( "Test_MflResult",	                      "testingResources");
helpArray[ix++] = new Array( "Test_Error",	                          "testing");

//Help for Calendar Module
helpArray[ix++] = new Array( "CalendarMgmt_CreateCalendar", "securityconfigurationCreateCalendar" );
helpArray[ix++] = new Array( "CalendarMgmt_SortRules", "securityconfigurationSortRules" );
helpArray[ix++] = new Array( "CalendarMgmt_ViewAllCalendars", "securityconfigurationViewAllCalendarsr" );
helpArray[ix++] = new Array( "CalendarMgmt_ViewCalendar", "securityconfigurationViewCalendar" );
helpArray[ix++] = new Array( "CalendarMgmt_AddRule", "securityconfigurationAddRule" );
helpArray[ix++] = new Array( "CalendarMgmt_EditRule", "securityconfigurationEditRule" );

//JNDI
helpArray[ix++] = new Array( "SysAdmin_ViewAllJndiProviders",      "systemadminViewAllJNDI" );
helpArray[ix++] = new Array( "SysAdmin_CreateJndiProvider",        "systemadminAddJNDI" );
helpArray[ix++] = new Array( "SysAdmin_EditJndiProvider",          "systemadminEditJNDI" );
helpArray[ix++] = new Array( "SysAdmin_ViewJndiProvider",          "systemadminEditJNDI" );

//SMTP
helpArray[ix++] = new Array( "SysAdmin_ViewAllSmtpServers",      "systemadminViewAllSMTP" );
helpArray[ix++] = new Array( "SysAdmin_CreateSmtpServer",        "systemadminSMTPAdding" );
helpArray[ix++] = new Array( "SysAdmin_EditSmtpServer",          "systemadminEditSMTP" );
helpArray[ix++] = new Array( "SysAdmin_SelectDefaultSmtpServer", "systemadminSMTPDefaultConfig" );
helpArray[ix++] = new Array( "SysAdmin_ViewSmtpServer",          "systemadminEditSMTP" );

//PROXY
helpArray[ix++] = new Array( "SysAdmin_ViewAllProxyServers",      "systemadminViewAllProxy" );
helpArray[ix++] = new Array( "SysAdmin_CreateProxyServer",        "systemadminProxyAdding" );
helpArray[ix++] = new Array( "SysAdmin_EditProxyServer",          "systemadminEditProxy" );
helpArray[ix++] = new Array( "SysAdmin_ViewProxyServer",          "systemadminEditProxy" );

// Archive
helpArray[ix++] = new Array( "Resources_ViewAllArchives", "resourcesViewingAllJars" );
helpArray[ix++] = new Array( "Resources_CreateArchive", "resourcesAddingJAR" );
helpArray[ix++] = new Array( "Resources_EditArchive", "resourcesEditingJAR" );
helpArray[ix++] = new Array( "Resources_ViewArchive", "resourcesEditingJAR" );
helpArray[ix++] = new Array( "Resources_ViewArchiveDependencies", "resourcesEditArchiveDependencies" );
helpArray[ix++] = new Array( "Resources_EditArchiveDependencies", "resourcesEditArchiveDependencies" );

// Alert Destinations
helpArray[ix++] = new Array( "Resources_CreateAlertDestination", "resourceAddAlertDestination" );
helpArray[ix++] = new Array( "Resources_EditAlertDestination", "resourcesEditAlertDestination" );
helpArray[ix++] = new Array( "Resources_ViewAlertDestination", "resourcesEditAlertDestination" );
helpArray[ix++] = new Array( "Resources_ViewAllAlertDestinations", "resourcesViewAllAlertDestinations" );
helpArray[ix++] = new Array( "AlertDestinationTarget_ActionSpecific", "resourcesAlertDestinationTarget_ActionSpecific" );

// Customization
helpArray[ix++] = new Array( "SysAdmin_Find_And_Replace" , "systemadminFindandReplace") ;
helpArray[ix++] = new Array( "SysAdmin_Execute_Customization_File" , "systemadminExecuteCustomizationFiles") ;
helpArray[ix++] = new Array( "SysAdmin_Create_Customization_File" , "systemadminCreateCustomizationFiles") ;
// Global settings
helpArray[ix++] = new Array( "Configuration_Global_Settings" , "configurationEnablingGlobalSettings") ;
// Dashboard Settings
helpArray[ix++] = new Array( "Dashboard_Settings" , "monitoringChangingDashboardSettings") ;
// Use this array to define a folder under help for each localization.
// Whenever a new folder is created for localized help add an entry in this arry.
// Make sure showHelp() is called with one of the indexes defined here.

// Smart Search
helpArray[ix++] = new Array( "SmartSearch_ViewSmartSearch" , "configurationListandLocateSystemResources") ;
helpArray[ix++] = new Array( "SmartSearch_ViewServices" , "configurationFindAllServices") ;
helpArray[ix++] = new Array( "SmartSearch_ViewProxyServices" , "configurationFindProxyServices") ;
helpArray[ix++] = new Array( "SmartSearch_ViewBusinessServices" , "configurationFindBusinessServices") ;
helpArray[ix++] = new Array( "SmartSearch_ViewFlowServices" , "configurationFindSplitJoins") ;  
helpArray[ix++] = new Array( "SmartSearch_ViewAlertDestinations" , "configurationFindAlertDestinations") ;
helpArray[ix++] = new Array( "SmartSearch_ViewSLAAlerts" , "configurationFindSLAAlertRules") ;

// Custom resource
helpArray[ix++] = new Array( "Resources_ViewAllCustomResources_$$CUSTOM$$", "resourcesViewingAllCustomResources" );
helpArray[ix++] = new Array( "Resources_ViewCustomResource_$$CUSTOM$$", "resourcesEditingCustomResource" );
helpArray[ix++] = new Array( "Resources_CreateCustomResource_$$CUSTOM$$", "resourcesAddingCustomResource" );
helpArray[ix++] = new Array( "Resources_EditCustomResource_$$CUSTOM$$", "resourcesEditingCustomResource" );
// Custom resource - MQConnection
helpArray[ix++] = new Array( "Resources_ViewAllCustomResources_MQConnection", "resourcesViewingAllMQConnectionCustomResources" );
helpArray[ix++] = new Array( "Resources_ViewCustomResource_MQConnection", "resourcesEditingMQConnectionCustomResource" );
helpArray[ix++] = new Array( "Resources_CreateCustomResource_MQConnection", "resourcesAddingMQConnectionCustomResource" );
helpArray[ix++] = new Array( "Resources_EditCustomResource_MQConnection", "resourcesEditingMQConnectionCustomResource" );

// Split Join Resource 
helpArray[ix++] = new Array( "Resources_ViewAllFlows", "resourcesViewAllSplitJoins" );
helpArray[ix++] = new Array( "Resources_CreateFlow", "resourcesAddSplitJoins" );
helpArray[ix++] = new Array( "Resources_ViewFlow", "resourcesEditSplitJoins" );
helpArray[ix++] = new Array( "Resources_ViewFlowOpSettings", "resourcesEditSplitJoins" );  // @todo doc team will change html file name
helpArray[ix++] = new Array( "Resources_EditFlow", "resourcesEditSplitJoins" );

// JCA Binding resource

helpArray[ix++] = new Array( "Resources_CreateJca", "jcasAddJCA" );
helpArray[ix++] = new Array( "Resources_EditJca", "jcasViewandChangeJCA" );
helpArray[ix++] = new Array( "Resources_EditJcaRef", "jcasViewandChangeJCA" );
helpArray[ix++] = new Array( "Resources_ViewAllJcas", "jcasListandLocateJCA" );
helpArray[ix++] = new Array( "Resources_ViewJca", "jcasViewandChangeJCA" );

// XML Document resource

helpArray[ix++] = new Array( "Resources_CreateXmlDocument",   "xmlAddXML" );
helpArray[ix++] = new Array( "Resources_EditXmlDocument",     "xmlViewandChangeXML" );
helpArray[ix++] = new Array( "Resources_ViewAllXmlDocuments", "xmlListandLocateXML" );
helpArray[ix++] = new Array( "Resources_ViewXmlDocument",     "xmlViewandChangeXML" );

helpArray[ix++] = new Array( "UserPreferences_ViewUserPreferences", "configurationSettingUserPreferences" );

var localizationArray = new Array();
localizationArray["en"] = new Array("en");
localizationArray["de"] = new Array("de");
localizationArray["es"] = new Array("es");
localizationArray["fr"] = new Array("fr");
localizationArray["it"] = new Array("it");
localizationArray["ja"] = new Array("ja");
localizationArray["ko"] = new Array("ko");
localizationArray["pt"] = new Array("pt_BR");
localizationArray["pt_BR"] = new Array("pt_BR");
localizationArray["zh"] = new Array("zh_CN");
localizationArray["zh_CN"] = new Array("zh_CN");
localizationArray["zh_TW"] = new Array("zh_TW");

// Invoke the help url.
function showHelp(jspId, localizationId) {
    var helpUrl = getHelpUrl(jspId);
    var url = getFullHelpUrl(helpUrl, localizationId);
    if ( isCustomProviderPage(jspId) ) {
        url = getCustomProviderHelpURL(url);
    }
    window.open(url,'HelpWindow');
}

//default page. If no JSPID is found in the helpArray, display the page specified here as the default page.
function getHelpUrl(jspId) {
    var helpUrl = "introOverview";
    var i = getHelpIndex(jspId);
    if (i>=0) {
        helpUrl = helpArray[i][1];
    }
    return helpUrl;
}

function getFullHelpUrl(helpUrl, localizationId) {
    if(localizationArray[localizationId]){
        localizationId = localizationArray[localizationId];
    } else {
        // if there is no launguage found, default it to English
        localizationId = 'en';
    }
    return "help/" + localizationArray[localizationId] + "/" + helpUrl + ".html";
}

function getHelpIndex(jspId) {
    for (var i=0; i<helpArray.length; i++ ) {
        if ( helpArray[i][0] == jspId ){
            break;
         }
    }
    if (i<helpArray.length) {
        return i;
    } else {
        return -1;
    }
}

// These will be used in EditServiceTransportSpecific.jsp
var hasCustomProviderHelp = false;
var fullCustomProviderHelpURL = "";

function isCustomProviderPage(jspId) {
    return jspId.indexOf('$$CUSTOM$$')>=0;
}

function getCustomProviderHelpURL(defaultUrl) {
    if ( hasCustomProviderHelp ) {
        return fullCustomProviderHelpURL;
    } else {
        return defaultUrl;
    }
}

