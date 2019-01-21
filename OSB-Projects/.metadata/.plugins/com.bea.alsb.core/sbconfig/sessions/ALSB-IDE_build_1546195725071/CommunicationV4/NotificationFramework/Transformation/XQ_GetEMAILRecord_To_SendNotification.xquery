<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[(:: pragma bea:global-element-parameter parameter="$tbEmailDetailsCollection" element="ns1:TbEmailDetailsCollection" location="../Schema/GetEmailRecord_table.xsd" ::)
(:: pragma bea:global-element-return element="ns0:SendEmailNotificationReq" location="../Schema/Notification.xsd" ::)

declare namespace ns1 = "http://xmlns.oracle.com/pcbpel/adapter/db/top/GetEmailRecord";
declare namespace ns0 = "http://appcon.vfqa.org/notification/SendNotification";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_GetEMAILRecord_To_SendNotification/";

declare function xf:XQ_GetEMAILRecord_To_SendNotification($tbEmailDetailsCollection as element(ns1:TbEmailDetailsCollection))
    as element(ns0:SendEmailNotificationReq) {
        <ns0:SendEmailNotificationReq>
            <SenderEmail>{ data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:senderEmailid) }</SenderEmail>
            <Subject>{ data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:subject) }</Subject>
            
            {
            for $recEmailid in fn:tokenize(data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:recEmailid),',')
             return
               <RecipientEmail>{$recEmailid}</RecipientEmail>
            
            }
            {
            for $ccEmailid in fn:tokenize(data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:ccEmailid),',')
             return
               <CCRecipientEmail>{$ccEmailid}</CCRecipientEmail>
            
            }
            {
            for $bccEmailid in fn:tokenize(data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:bccEmailid),',')
             return
               <BCCRecipientEmail>{$bccEmailid}</BCCRecipientEmail>
            
            }

            <SourceSystem>{ data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:channelName) }</SourceSystem>
            <ProfileID>{ data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:profileId) }</ProfileID>
            <Attachment>
                <Name></Name>
                <Content></Content>
            </Attachment>
            <EmailFormat>{ 
let $format := if(data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:format) eq 'HTML')
                      then
                        '1'
                    else
                         '2'
return 
$format }</EmailFormat>
            <OSBTransactionID>{ data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:osbTransactionId) }</OSBTransactionID>
            <PriorityFlag>{ data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:priority) }</PriorityFlag>
            <Body>{ data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:body) }</Body>
            <OSBMessageID>{ data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:notificationId) }</OSBMessageID>
        </ns0:SendEmailNotificationReq>
};

declare variable $tbEmailDetailsCollection as element(ns1:TbEmailDetailsCollection) external;

xf:XQ_GetEMAILRecord_To_SendNotification($tbEmailDetailsCollection)]]></con:xquery>
    <con:dependency location="../Schema/GetEmailRecord_table.xsd">
        <con:schema ref="CommunicationV4/NotificationFramework/Schema/GetEmailRecord_table"/>
    </con:dependency>
    <con:dependency location="../Schema/Notification.xsd">
        <con:schema ref="CommunicationV4/NotificationFramework/Schema/Notification"/>
    </con:dependency>
</con:xqueryEntry>