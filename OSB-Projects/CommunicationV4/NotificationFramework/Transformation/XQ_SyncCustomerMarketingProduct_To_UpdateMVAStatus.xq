(:: pragma bea:global-element-parameter parameter="$tbMvaPushDetailsCollection" element="ns1:TbMvaPushDetailsCollection" location="../Schema/GetMVAPushRecord_table.xsd" ::)
(:: pragma bea:global-element-return element="ns0:InputParameters" location="../Schema/UPDATE_STATUS_sp.xsd" ::)

declare namespace ns1 = "http://xmlns.oracle.com/pcbpel/adapter/db/top/GetMVAPushRecord";
declare namespace ns0 = "http://xmlns.oracle.com/pcbpel/adapter/db/sp/UPDATE_STATUS";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_SyncCustomerMarketingProduct_To_UpdateMVAStatus/";

declare function xf:XQ_SyncCustomerMarketingProduct_To_UpdateMVAStatus($tbMvaPushDetailsCollection as element(ns1:TbMvaPushDetailsCollection),
    $Description as xs:string,
    $ReasonCode as xs:string,
    $Message as xs:string)
    as element(ns0:InputParameters) {
        <ns0:InputParameters>
            <ns0:V_TRANSACTION_ID>{ data($tbMvaPushDetailsCollection/ns1:TbMvaPushDetails/ns1:osbTransactionId) }</ns0:V_TRANSACTION_ID>
            <ns0:V_TYPE>MVA PUSH</ns0:V_TYPE>
            <ns0:V_STATUS>{
            let $sts := if(data($ReasonCode) eq '0')
            			then
            				xs:int(2)
            			else
            				xs:int(3)
            return
            	$sts
            
            }</ns0:V_STATUS>
            <ns0:V_STATUS_MESSAGE>{ concat($Message , ',' ,$Description ) }</ns0:V_STATUS_MESSAGE>
          
                    <ns0:V_RETRY_CNT>{ 
			
			 let $retry := if(data($ReasonCode) eq '0')
            			then
            				xs:int(0)
            			else
            				xs:int($tbMvaPushDetailsCollection/ns1:TbMvaPushDetails/ns1:retryCnt) - xs:int(1)
            return
            	$retry
			
			
			 }</ns0:V_RETRY_CNT>
            
        </ns0:InputParameters>
};

declare variable $tbMvaPushDetailsCollection as element(ns1:TbMvaPushDetailsCollection) external;
declare variable $Description as xs:string external;
declare variable $ReasonCode as xs:string external;
declare variable $Message as xs:string external;

xf:XQ_SyncCustomerMarketingProduct_To_UpdateMVAStatus($tbMvaPushDetailsCollection,
    $Description,
    $ReasonCode,
    $Message)