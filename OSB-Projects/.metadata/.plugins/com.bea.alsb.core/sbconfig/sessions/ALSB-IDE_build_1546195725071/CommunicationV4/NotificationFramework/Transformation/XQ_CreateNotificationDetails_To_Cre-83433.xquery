<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[(:: pragma bea:local-element-parameter parameter="$tbDetails" type="ns0:CreateNotification/TbDetails" location="../WSDL/CreateNotificationRecord.wsdl" ::)
(:: pragma bea:global-element-return element="ns1:TbEmailDetailsCollection" location="../Schema/CreateEmailRecord_table.xsd" ::)

declare namespace ns1 = "http://xmlns.oracle.com/pcbpel/adapter/db/top/CreateEmailRecord";
declare namespace ns0 = "http://vodafone.qa/CreateNotificationRecord/";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_CreateNotificationDetails_To_CreateEMAILRecord/";

declare function xf:XQ_CreateNotificationDetails_To_CreateEMAILRecord($tbDetails as element())
    as element(ns1:TbEmailDetailsCollection) {
        <ns1:TbEmailDetailsCollection>
            <ns1:TbEmailDetails>
                <ns1:osbTransactionId>{ data($tbDetails/osbTransactionId) }</ns1:osbTransactionId>
                      <ns1:channelName>{ data($tbDetails/channelName) }</ns1:channelName>
               
                        <ns1:profileId>{ data($tbDetails/profileId) }</ns1:profileId>
               
                        <ns1:priority>{ data($tbDetails/priority) }</ns1:priority>
                
                        <ns1:format>{ data($tbDetails/format) }</ns1:format>
                
                <ns1:recEmailid>{ data($tbDetails/dynamicValues/Column[@name = 'recEmailid']) }</ns1:recEmailid>
                <ns1:ccEmailid>{ data($tbDetails/dynamicValues/Column[@name = 'ccEmailid']) }</ns1:ccEmailid>
                <ns1:bccEmailid>{ data($tbDetails/dynamicValues/Column[@name = 'bccEmailid']) }</ns1:bccEmailid>
                <ns1:subject>{ data($tbDetails/dynamicValues/Column[@name = 'subject']) }</ns1:subject>
                <ns1:body>{ data($tbDetails/dynamicValues/Column[@name = 'body']) }</ns1:body>
                <ns1:senderEmailid>{ data($tbDetails/dynamicValues/Column[@name = 'senderEmailid']) }</ns1:senderEmailid>
                
                        <ns1:channelTransactionId>{ data($tbDetails/channelTransactionId) }</ns1:channelTransactionId>
               
                        <ns1:notificationId>{ data($tbDetails/notificationId) }</ns1:notificationId>
               
                        <ns1:status>{ data($tbDetails/status) }</ns1:status>
               
                        <ns1:created>{ data($tbDetails/created) }</ns1:created>
                
                        <ns1:lastUpdated>{ data($tbDetails/lastUpdated) }</ns1:lastUpdated>
               
                        <ns1:statusMessage>{ data($tbDetails/statusMessage) }</ns1:statusMessage>
               
                        <ns1:lang>{ data($tbDetails/lang) }</ns1:lang>
               
                        <ns1:retryCnt>{ data($tbDetails/retryCnt) }</ns1:retryCnt>
               
            </ns1:TbEmailDetails>
        </ns1:TbEmailDetailsCollection>
};

declare variable $tbDetails as element() external;

xf:XQ_CreateNotificationDetails_To_CreateEMAILRecord($tbDetails)]]></con:xquery>
    <con:dependency location="../WSDL/CreateNotificationRecord.wsdl">
        <con:wsdl ref="CommunicationV4/NotificationFramework/WSDL/CreateNotificationRecord"/>
    </con:dependency>
    <con:dependency location="../Schema/CreateEmailRecord_table.xsd">
        <con:schema ref="CommunicationV4/NotificationFramework/Schema/CreateEmailRecord_table"/>
    </con:dependency>
</con:xqueryEntry>