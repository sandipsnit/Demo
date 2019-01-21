(:: pragma bea:global-element-return element="ns0:CreateNotificationResponse" location="../WSDL/CreateNotificationRecord.wsdl" ::)

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
    $status)