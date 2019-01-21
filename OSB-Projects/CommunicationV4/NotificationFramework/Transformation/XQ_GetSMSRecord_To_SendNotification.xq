(:: pragma bea:global-element-parameter parameter="$tbSmsDetailsCollection" element="ns0:TbSmsDetailsCollection" location="../Schema/GetSMSRecord_table.xsd" ::)
(:: pragma bea:global-element-return element="ns1:SendSMSNotificationReq" location="../Schema/Notification.xsd" ::)

declare namespace ns1 = "http://appcon.vfqa.org/notification/SendNotification";
declare namespace ns0 = "http://xmlns.oracle.com/pcbpel/adapter/db/top/GetSMSRecord";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_GetSMSRecord_To_SendNotification/";

declare function xf:XQ_GetSMSRecord_To_SendNotification($tbSmsDetailsCollection as element(ns0:TbSmsDetailsCollection))
    as element(ns1:SendSMSNotificationReq) {
        <ns1:SendSMSNotificationReq>
            <MSISDN>{ data($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:msisdn) }</MSISDN>
            <SourceSystem>{ data($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:channelName) }</SourceSystem>
            <DeliveryReportFlag>{
            let $flag := if(data($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:deliveryFlag) = 'Y')
            				then
            					'true'
            				else
            					'false'
            					
            	return
            		$flag
            }</DeliveryReportFlag>
            <AckFlag>{let $flag := if(data($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:acknowledgementFlag) = 'Y')
            				then
            					'true'
            				else
            					'false'
            					
            	return
            		$flag}</AckFlag>
            <ProfileID>{ data($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:profileId) }</ProfileID>
            <SenderTitle>{ data($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:senderName) }</SenderTitle>
            <OSBTransactionID>{ data($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:osbTransactionId) }</OSBTransactionID>
            <Priority>{ data($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:priority) }</Priority>
            <UnicodeFlag>{ 
            let $flag := if(data($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:format) = 'UTF-8')
            				then
            					'true'
            				else
            					'false'
            					
            	return
            		$flag
             }</UnicodeFlag>
            <FlashMsgFlag>false</FlashMsgFlag>
            <SMSText>{ data($tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:smsText) }</SMSText>
            {
                for $notificationId in $tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:notificationId
                return
                    <OSBMessageID>{ data($notificationId) }</OSBMessageID>
            }
            {
                for $accountId in $tbSmsDetailsCollection/ns0:TbSmsDetails/ns0:accountId
                return
                    <AccountID>{ data($accountId) }</AccountID>
            }
        </ns1:SendSMSNotificationReq>
};

declare variable $tbSmsDetailsCollection as element(ns0:TbSmsDetailsCollection) external;

xf:XQ_GetSMSRecord_To_SendNotification($tbSmsDetailsCollection)