xquery version "1.0" encoding "Cp1252";
(:: pragma  parameter="$status" type="xs:anyType" ::)
(:: pragma  parameter="$header" type="xs:anyType" ::)
(:: pragma bea:global-element-return element="ns3:ResultStatus" location="../../../VFQA_CSM_Common/Schema/Header.xsd" ::)

declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_CreateCommunicationFinalHeaderResponse/";
declare namespace soapenv = "http://schemas.xmlsoap.org/soap/envelope/";
declare namespace v1 = "http://group.vodafone.com/contract/vho/header/v1";
declare namespace v11="http://group.vodafone.com/contract/vfo/fault/v1";
declare namespace v12="http://group.vodafone.com/schema/common/v1";
declare namespace wsa="http://www.w3.org/2005/08/addressing";

declare function xf:XQ_CreateCommunicationFinalHeaderResponse($status as element(*),
    $header as element(*),$ReasonCode as xs:string,
    $Message as xs:string)
    as element(*) {
        <soapenv:Header>
        <wsa:Action>{data($header/*:Action)}</wsa:Action>
         <wsa:MessageID>{data($header/*:MessageID)}</wsa:MessageID>
         <wsa:To>{data($header/*:To)}</wsa:To>
        <wsa:ReplyTo><wsa:Address>{data($header/*:ReplyTo/*:Address)}</wsa:Address></wsa:ReplyTo>
     <v1:ResultStatus>
        <v11:ReasonCode>{ data($ReasonCode) }</v11:ReasonCode>
        <v11:Message>{data($Message) }</v11:Message> 
     	<v11:Specification>
     	{
     			for $sts in $status/*:Column
     			return
                <v11:Characteristic>
                    <v12:Name>{data($sts/@name)}</v12:Name>
                    <v12:Value>{data($sts)}</v12:Value>
                </v11:Characteristic>
         }
            </v11:Specification>
     </v1:ResultStatus>
     <v1:Correlation>
        <v1:ConversationID>{data($header/*:Correlation/*:ConversationID)}</v1:ConversationID>
     </v1:Correlation>
  </soapenv:Header>
};

declare variable $status as element(*) external;
declare variable $header as element(*) external;
declare variable $Message as xs:string external;
declare variable $ReasonCode as xs:string external;

xf:XQ_CreateCommunicationFinalHeaderResponse($status,
    $header,$ReasonCode,
    $Message)