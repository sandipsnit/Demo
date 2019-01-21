<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[xquery version "1.0" encoding "Cp1252";
(:: pragma  parameter="$RequestHeader" type="xs:anyType" ::)
(:: pragma  type="xs:anyType" ::)

declare namespace xf = "http://tempuri.org/CommunicationV3/Transformation/XQ_CreateCommunicationResponseHeader/";
declare namespace soapenv = "http://schemas.xmlsoap.org/soap/envelope/";
declare namespace v1 = "http://group.vodafone.com/contract/vho/header/v1";
declare namespace v11="http://group.vodafone.com/contract/vfo/fault/v1";
declare namespace wsa="http://www.w3.org/2005/08/addressing";

declare function xf:XQ_CreateCommunicationResponseHeader($RequestHeader as element(*),
    $ReasonCode as xs:string,
    $Message as xs:string)
    as element(*) {
         <soapenv:Header>
        <wsa:Action>{data($RequestHeader/*:Action)}</wsa:Action>
         <wsa:MessageID>{data($RequestHeader/*:MessageID)}</wsa:MessageID>
         <wsa:To>{data($RequestHeader/*:To)}</wsa:To>
        <wsa:ReplyTo><wsa:Address>{data($RequestHeader/*:ReplyTo/*:Address)}</wsa:Address></wsa:ReplyTo>
     <v1:ResultStatus>
        <v11:ReasonCode>{ data($ReasonCode) }</v11:ReasonCode>
        <v11:Message>{data($Message) }</v11:Message>
     </v1:ResultStatus>
     <v1:Correlation>
        <v1:ConversationID>{data($RequestHeader/*:Correlation/*:ConversationID)}</v1:ConversationID>
     </v1:Correlation>
  </soapenv:Header>
};

declare variable $RequestHeader as element(*) external;
declare variable $ReasonCode as xs:string external;
declare variable $Message as xs:string external;

xf:XQ_CreateCommunicationResponseHeader($RequestHeader,
    $ReasonCode,
    $Message)]]></con:xquery>
</con:xqueryEntry>