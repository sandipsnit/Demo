(:: pragma bea:schema-type-parameter parameter="$tbDetails" type="ns0:TbDetails" location="../WSDL/CreateNotificationRecord.wsdl" ::)
(:: pragma bea:global-element-return element="ns1:TbSmsDetailsCollection" location="../Schema/CreateSMSRecord_table.xsd" ::)

declare namespace ns1 = "http://xmlns.oracle.com/pcbpel/adapter/db/top/CreateSMSRecord";
declare namespace ns0 = "http://vodafone.qa/CreateNotificationRecord/";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_CreateNotificationDetails_To_CreateSMSRecord/";

declare function xf:XQ_CreateNotificationDetails_To_CreateSMSRecord($tbDetails as element())
    as element(ns1:TbSmsDetailsCollection) {
        <ns1:TbSmsDetailsCollection>
            <ns1:TbSmsDetails>
                <ns1:osbTransactionId>{ data($tbDetails/osbTransactionId) }</ns1:osbTransactionId>
                <ns1:smsText>{ data($tbDetails/dynamicValues/Column[@name = 'smsText']) }</ns1:smsText>
               
                        <ns1:channelName>{ data($tbDetails/channelName) }</ns1:channelName>
              
                
                        <ns1:msisdn>{ data($tbDetails/msisdn) }</ns1:msisdn>
               
                   
                        <ns1:acknowledgementFlag>{ data($tbDetails/acknowledgementFlag) }</ns1:acknowledgementFlag>
               
                 
                        <ns1:deliveryFlag>{ data($tbDetails/deliveryFlag) }</ns1:deliveryFlag>
               
                        <ns1:profileId>{ data($tbDetails/profileId) }</ns1:profileId>
               
                        <ns1:priority>{ data($tbDetails/priority) }</ns1:priority>
                
                        <ns1:format>{ data($tbDetails/format) }</ns1:format>
               
                        <ns1:notificationId>{ data($tbDetails/notificationId) }</ns1:notificationId>
                
                <ns1:accountId>{ data($tbDetails/dynamicValues/Column[@name = 'accountId']) }</ns1:accountId>
               
                        <ns1:channelTransactionId>{ data($tbDetails/channelTransactionId) }</ns1:channelTransactionId>
                
                <ns1:senderName>{ data($tbDetails/dynamicValues/Column[@name = 'senderName']) }</ns1:senderName>
                
                        <ns1:status>{ data($tbDetails/status) }</ns1:status>
               
                        <ns1:created>{ data($tbDetails/created) }</ns1:created>
             
                
                        <ns1:lastUpdated>{ data($tbDetails/lastUpdated) }</ns1:lastUpdated>
             
                        <ns1:statusMessage>{ data($tbDetails/statusMessage) }</ns1:statusMessage>
               
                        <ns1:lang>{ data($tbDetails/lang) }</ns1:lang>
              
                        <ns1:retryCnt>{ data($tbDetails/retryCnt) }</ns1:retryCnt>
                
            </ns1:TbSmsDetails>
        </ns1:TbSmsDetailsCollection>
};

declare variable $tbDetails as element() external;

xf:XQ_CreateNotificationDetails_To_CreateSMSRecord($tbDetails)