(:: pragma bea:global-element-return element="ns0:InputParameters" location="../Schema/UPDATE_STATUS_sp.xsd" ::)

declare namespace ns0 = "http://xmlns.oracle.com/pcbpel/adapter/db/sp/UPDATE_STATUS";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_UpdateStatus/";

declare function xf:XQ_UpdateStatus($status as xs:integer,
    $retryCount as xs:integer,
    $transactionID as xs:string,
    $type as xs:string,
    $statusMessage as xs:string)
    as element(ns0:InputParameters) {
        <ns0:InputParameters>
            <ns0:V_TRANSACTION_ID>{ $transactionID }</ns0:V_TRANSACTION_ID>
            <ns0:V_TYPE>{ $type }</ns0:V_TYPE>
            <ns0:V_STATUS>{ $status }</ns0:V_STATUS>
            <ns0:V_STATUS_MESSAGE>{ $statusMessage }</ns0:V_STATUS_MESSAGE>
            <ns0:V_RETRY_CNT>{ $retryCount }</ns0:V_RETRY_CNT>
        </ns0:InputParameters>
};

declare variable $status as xs:integer external;
declare variable $retryCount as xs:integer external;
declare variable $transactionID as xs:string external;
declare variable $type as xs:string external;
declare variable $statusMessage as xs:string external;

xf:XQ_UpdateStatus($status,
    $retryCount,
    $transactionID,
    $type,
    $statusMessage)