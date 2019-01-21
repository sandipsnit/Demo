(:: pragma bea:global-element-return element="ns0:InputParameters" location="../Schema/GetNotificationDetails_sp.xsd" ::)

declare namespace ns0 = "http://xmlns.oracle.com/pcbpel/adapter/db/sp/GetNotificationDetails";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_CreateCommunication_To_GetNotificationDetails/";

declare function xf:XQ_CreateCommunication_To_GetNotificationDetails($template_id as xs:string,
    $lang as xs:string)
    as element(ns0:InputParameters) {
        <ns0:InputParameters>
            <ns0:V_NOTIFICATION_ID>{ $template_id }</ns0:V_NOTIFICATION_ID>
            <ns0:V_LANG>{ $lang }</ns0:V_LANG>
        </ns0:InputParameters>
};

declare variable $template_id as xs:string external;
declare variable $lang as xs:string external;

xf:XQ_CreateCommunication_To_GetNotificationDetails($template_id,
    $lang)