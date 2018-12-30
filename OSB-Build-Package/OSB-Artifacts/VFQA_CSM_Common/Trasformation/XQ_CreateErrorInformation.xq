(:: pragma bea:global-element-return element="ns0:ErrorInformation" location="../Schema/ErrorInformation.xsd" ::)

declare namespace ns0 = "http://www.vodafone.qa/ErrorInformation";
declare namespace xf = "http://tempuri.org/VFQA_CSM_Common/Trasformation/XQ_CreateErrorInformation/";

declare function xf:XQ_CreateErrorInformation($TransactionID as xs:string,
    $MSISDN as xs:string,
    $ErrorCode as xs:string,
    $System as xs:string,
    $Description as xs:string,
    $ErrorDetail as xs:string,
    $Severity as xs:string,
    $Category as xs:string)
    as element(ns0:ErrorInformation) {
        <ns0:ErrorInformation>
            <ns0:TransactionID>{ $TransactionID }</ns0:TransactionID>
            <ns0:MSISDN>{ $MSISDN }</ns0:MSISDN>
            <ns0:ErrorCode>{ $ErrorCode }</ns0:ErrorCode>
            <ns0:ErrorDescription>{ $Description }</ns0:ErrorDescription>
            <ns0:SystemName>{ $System }</ns0:SystemName>
            <ns0:Severity>{ $Severity }</ns0:Severity>
            <ns0:Category>{ $Category }</ns0:Category>
            <ns0:ErrorDetail>{ $ErrorDetail }</ns0:ErrorDetail>
        </ns0:ErrorInformation>
};

declare variable $TransactionID as xs:string external;
declare variable $MSISDN as xs:string external;
declare variable $ErrorCode as xs:string external;
declare variable $System as xs:string external;
declare variable $Description as xs:string external;
declare variable $ErrorDetail as xs:string external;
declare variable $Severity as xs:string external;
declare variable $Category as xs:string external;

xf:XQ_CreateErrorInformation($TransactionID,
    $MSISDN,
    $ErrorCode,
    $System,
    $Description,
    $ErrorDetail,
    $Severity,
    $Category)