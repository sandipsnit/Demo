<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[(:: pragma bea:global-element-parameter parameter="$sendSMSNotificationResp" element="ns1:SendSMSNotificationResp" location="../Schema/Notification.xsd" ::)
(:: pragma bea:global-element-parameter parameter="$tbSmsDetailsCollection" element="ns0:TbSmsDetailsCollection" location="../Schema/GetSMSRecord_table.xsd" ::)
(:: pragma bea:global-element-return element="ns2:InputParameters" location="../Schema/UPDATE_STATUS_sp.xsd" ::)

declare namespace ns2 = "http://xmlns.oracle.com/pcbpel/adapter/db/sp/UPDATE_STATUS";
declare namespace ns1 = "http://appcon.vfqa.org/notification/SendNotification";
declare namespace ns0 = "http://xmlns.oracle.com/pcbpel/adapter/db/top/GetSMSRecord";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_SendNotification_To_UpdateSMSStatus/";

declare function xf:XQ_SendNotification_To_UpdateSMSStatus($sendSMSNotificationResp as element(ns1:SendSMSNotificationResp),
    $tbSmsDetailsCollection as element(ns0:TbSmsDetailsCollection))
    as element(ns2:InputParameters) {
        <ns2:InputParameters>
            <ns2:V_TRANSACTION_ID>{ data($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:osbTransactionId) }</ns2:V_TRANSACTION_ID>
            <ns2:V_TYPE>SMS</ns2:V_TYPE>
            <ns2:V_STATUS>{
            let $sts := if(data($sendSMSNotificationResp/ReturnCode) eq '000')
            			then
            				xs:int(2)
            			else
            				xs:int(3)
            return
            	$sts
            
            }</ns2:V_STATUS>
            <ns2:V_STATUS_MESSAGE>{ concat($sendSMSNotificationResp/ReturnDesc,', AppConnectUUID - ',$sendSMSNotificationResp/AppConnectUUID) }</ns2:V_STATUS_MESSAGE>
			<ns2:V_RETRY_CNT>{ 
			
			 let $retry := if(data($sendSMSNotificationResp/ReturnCode) eq '000')
            			then
            				xs:int(0)
            			else
            				xs:int($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:retryCnt) - xs:int(1)
            return
            	$retry
			
			
			 }</ns2:V_RETRY_CNT>
            
        </ns2:InputParameters>
};

declare variable $sendSMSNotificationResp as element(ns1:SendSMSNotificationResp) external;
declare variable $tbSmsDetailsCollection as element(ns0:TbSmsDetailsCollection) external;

xf:XQ_SendNotification_To_UpdateSMSStatus($sendSMSNotificationResp,
    $tbSmsDetailsCollection)]]></con:xquery>
    <con:dependency location="../Schema/Notification.xsd">
        <con:schema ref="CommunicationV4/NotificationFramework/Schema/Notification"/>
    </con:dependency>
    <con:dependency location="../Schema/GetSMSRecord_table.xsd">
        <con:schema ref="CommunicationV4/NotificationFramework/Schema/GetSMSRecord_table"/>
    </con:dependency>
    <con:dependency location="../Schema/UPDATE_STATUS_sp.xsd">
        <con:schema ref="CommunicationV4/NotificationFramework/Schema/UPDATE_STATUS_sp"/>
    </con:dependency>
</con:xqueryEntry>