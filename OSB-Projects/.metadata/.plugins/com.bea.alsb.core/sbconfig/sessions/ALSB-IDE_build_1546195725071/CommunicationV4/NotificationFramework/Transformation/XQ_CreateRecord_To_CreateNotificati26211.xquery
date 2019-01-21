<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[(:: pragma bea:global-element-return element="ns0:CreateNotificationResponse" location="../WSDL/CreateNotificationRecord.wsdl" ::)

declare namespace ns0 = "http://vodafone.qa/CreateNotificationRecord/";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_CreateRecord_To_CreateNotificationDetails/";

declare function xf:XQ_CreateRecord_To_CreateNotificationDetails($targetType as xs:string,
    $status as xs:string)
    as element(ns0:CreateNotificationResponse) {
        <ns0:CreateNotificationResponse>
            <targetType>{ $targetType }</targetType>
            <status>{ $status }</status>
        </ns0:CreateNotificationResponse>
};

declare variable $targetType as xs:string external;
declare variable $status as xs:string external;

xf:XQ_CreateRecord_To_CreateNotificationDetails($targetType,
    $status)]]></con:xquery>
    <con:dependency location="../WSDL/CreateNotificationRecord.wsdl">
        <con:wsdl ref="CommunicationV4/NotificationFramework/WSDL/CreateNotificationRecord"/>
    </con:dependency>
</con:xqueryEntry>