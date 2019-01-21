(:: pragma bea:local-element-parameter parameter="$tbDetails" type="ns0:CreateNotification/TbDetails" location="../WSDL/CreateNotificationRecord.wsdl" ::)
(:: pragma bea:global-element-return element="ns1:TbMvaPushDetailsCollection" location="../Schema/CreateMVAPushRecord_table.xsd" ::)

declare namespace ns1 = "http://xmlns.oracle.com/pcbpel/adapter/db/top/CreateMVAPushRecord";
declare namespace ns0 = "http://vodafone.qa/CreateNotificationRecord/";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_CreateNotificationDetails_To_CreateMVAPushRecord/";

declare function xf:XQ_CreateNotificationDetails_To_CreateMVAPushRecord($tbDetails as element())
    as element(ns1:TbMvaPushDetailsCollection) {
        <ns1:TbMvaPushDetailsCollection>
            <ns1:TbMvaPushDetails>
                <ns1:osbTransactionId>{ data($tbDetails/osbTransactionId) }</ns1:osbTransactionId>
               
                        <ns1:channelTransactionId>{ data($tbDetails/channelTransactionId) }</ns1:channelTransactionId>
              
                <ns1:offerName>{ data($tbDetails/dynamicValues/Column[@name = 'offerName']) }</ns1:offerName>
                <ns1:offerTitle>{ data($tbDetails/dynamicValues/Column[@name = 'offerTitle']) }</ns1:offerTitle>
                <ns1:offerDescription>{ data($tbDetails/dynamicValues/Column[@name = 'offerDescription']) }</ns1:offerDescription>
                
                        <ns1:msisdn>{ data($tbDetails/msisdn) }</ns1:msisdn>
               
                <ns1:menuModuleId>{ data($tbDetails/dynamicValues/Column[@name = 'menuModuleId']) }</ns1:menuModuleId>
               
                        <ns1:channelName>{ data($tbDetails/channelName) }</ns1:channelName>
                
                        <ns1:lang>{ data($tbDetails/lang) }</ns1:lang>
               
                        <ns1:status>{ data($tbDetails/status) }</ns1:status>
                
                        <ns1:statusMessage>{ data($tbDetails/statusMessage) }</ns1:statusMessage>
               
                        <ns1:created>{ data($tbDetails/created) }</ns1:created>
                
                        <ns1:lastUpdated>{ data($tbDetails/lastUpdated) }</ns1:lastUpdated>
                
                        <ns1:notificationId>{ data($tbDetails/notificationId) }</ns1:notificationId>
               
                        <ns1:retryCnt>{ data($tbDetails/retryCnt) }</ns1:retryCnt>
               
                        <ns1:scheduled>{ data($tbDetails/created) }</ns1:scheduled>
               
            </ns1:TbMvaPushDetails>
        </ns1:TbMvaPushDetailsCollection>
};

declare variable $tbDetails as element() external;

xf:XQ_CreateNotificationDetails_To_CreateMVAPushRecord($tbDetails)