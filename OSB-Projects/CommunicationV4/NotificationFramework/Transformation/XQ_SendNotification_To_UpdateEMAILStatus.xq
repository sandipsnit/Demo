(:: pragma bea:global-element-parameter parameter="$sendEmailNotificationResp" element="ns0:SendEmailNotificationResp" location="../Schema/Notification.xsd" ::)
(:: pragma bea:global-element-parameter parameter="$tbEmailDetailsCollection" element="ns1:TbEmailDetailsCollection" location="../Schema/GetEmailRecord_table.xsd" ::)
(:: pragma bea:global-element-return element="ns2:InputParameters" location="../Schema/UPDATE_STATUS_sp.xsd" ::)

declare namespace ns2 = "http://xmlns.oracle.com/pcbpel/adapter/db/sp/UPDATE_STATUS";
declare namespace ns1 = "http://xmlns.oracle.com/pcbpel/adapter/db/top/GetEmailRecord";
declare namespace ns0 = "http://appcon.vfqa.org/notification/SendNotification";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_SendNotification_To_UpdateEMAILStatus/";

declare function xf:XQ_SendNotification_To_UpdateEMAILStatus($sendEmailNotificationResp as element(ns0:SendEmailNotificationResp),
    $tbEmailDetailsCollection as element(ns1:TbEmailDetailsCollection))
    as element(ns2:InputParameters) {
        <ns2:InputParameters>
            <ns2:V_TRANSACTION_ID>{ data($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:osbTransactionId) }</ns2:V_TRANSACTION_ID>
            <ns2:V_TYPE>EMAIL</ns2:V_TYPE>
            <ns2:V_STATUS>{
            let $sts := if(data($sendEmailNotificationResp/ReturnCode) eq '000')
            			then
            				xs:int(2)
            			else
            				xs:int(3)
            return
            	$sts
            
            }</ns2:V_STATUS>
            <ns2:V_STATUS_MESSAGE>{ concat($sendEmailNotificationResp/ReturnDesc,', AppConnectUUID - ',$sendEmailNotificationResp/AppConnectUUID) }</ns2:V_STATUS_MESSAGE>
           
                    <ns2:V_RETRY_CNT>{ 
			
			 let $retry := if(data($sendEmailNotificationResp/ReturnCode) eq '000')
            			then
            				xs:int(0)
            			else
            				xs:int($tbEmailDetailsCollection/ns1:TbEmailDetails/ns1:retryCnt) - xs:int(1)
            return
            	$retry
			
			
			 }</ns2:V_RETRY_CNT>
            
        </ns2:InputParameters>
};

declare variable $sendEmailNotificationResp as element(ns0:SendEmailNotificationResp) external;
declare variable $tbEmailDetailsCollection as element(ns1:TbEmailDetailsCollection) external;

xf:XQ_SendNotification_To_UpdateEMAILStatus($sendEmailNotificationResp,
    $tbEmailDetailsCollection)