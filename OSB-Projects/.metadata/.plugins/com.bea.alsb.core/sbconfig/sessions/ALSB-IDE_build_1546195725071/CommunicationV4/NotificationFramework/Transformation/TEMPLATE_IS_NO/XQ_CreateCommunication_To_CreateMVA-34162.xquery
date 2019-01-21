<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[(:: pragma bea:global-element-parameter parameter="$createCommunicationVBMRequest" element="ns4:CreateCommunicationVBMRequest" location="../../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd" ::)
(:: pragma  parameter="$header" type="anyType" ::)
(:: pragma bea:global-element-return element="ns2:TbMvaPushDetailsCollection" location="../../Schema/CreateMVAPushRecord_table.xsd" ::)
(:: pragma bea:global-element-parameter parameter="$retry" element="dvm:dvm" location="../../../../VFQA_CSM_Common/Schema/dvm.xsd" ::)

declare namespace ns2 = "http://xmlns.oracle.com/pcbpel/adapter/db/top/CreateMVAPushRecord";
declare namespace ns1 = "http://group.vodafone.com/schema/vbo/technical/communication/v1";
declare namespace ns4 = "http://group.vodafone.com/schema/vbm/technical/communication/v1";
declare namespace ns3 = "urn:un:unece:uncefact:documentation:standard:CoreComponentType:2";
declare namespace ns0 = "http://group.vodafone.com/schema/extension/vbo/technical/communication/v1";
declare namespace ns5 = "http://group.vodafone.com/schema/common/v1";
declare namespace dvm = "http://xmlns.oracle.com/dvm";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/TEMPLATE_IS_NO/XQ_CreateCommunication_To_CreateMVAPUSHRecord/";

declare function xf:XQ_CreateCommunication_To_CreateMVAPUSHRecord($createCommunicationVBMRequest as element(ns4:CreateCommunicationVBMRequest),
    $header as element(*),$retry as element(dvm:dvm))
    as element(ns2:TbMvaPushDetailsCollection) {
        <ns2:TbMvaPushDetailsCollection>
            <ns2:TbMvaPushDetails>
                <ns2:osbTransactionId>{ fn:substring(fn:replace(fn-bea:uuid(),'-',''),3,26) }</ns2:osbTransactionId>
                <ns2:channelTransactionId>{data($header/*:Correlation/*:ConversationID)}</ns2:channelTransactionId>
                <ns2:offerName>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:ShortText)}</ns2:offerName>
                <ns2:offerTitle>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:ShortText)}</ns2:offerTitle>
                <ns2:offerDescription>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text)}</ns2:offerDescription>
                <ns2:msisdn>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:SubscriberNumber)}</ns2:msisdn>
                <ns2:menuModuleId>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Type[@listName ="menuModule" and @listAgencyName="Vodafone"])}</ns2:menuModuleId>
                <ns2:channelName>{ data($header/*:Source/*:System) }</ns2:channelName>
                <ns2:lang>{ data($header/*:Source/*:LanguageCode) }</ns2:lang>
                <ns2:status>0</ns2:status>
                <ns2:statusMessage>NEW</ns2:statusMessage>
                <ns2:created>{ fn:current-date() }</ns2:created>
                <ns2:lastUpdated>{ fn:current-date() }</ns2:lastUpdated>
                <ns2:notificationId></ns2:notificationId>
                <ns2:retryCnt>{ data($retry/*:rows/*:row[*:cell[1] = 'SMS']/*:cell[2])}</ns2:retryCnt>
                <ns2:scheduled>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:SentDateTime)}</ns2:scheduled>
            </ns2:TbMvaPushDetails>
        </ns2:TbMvaPushDetailsCollection>
};

declare variable $createCommunicationVBMRequest as element(ns4:CreateCommunicationVBMRequest) external;
declare variable $header as element(*) external;
declare variable $retry as element(dvm:dvm) external;

xf:XQ_CreateCommunication_To_CreateMVAPUSHRecord($createCommunicationVBMRequest,
    $header,$retry)]]></con:xquery>
    <con:dependency location="../../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM"/>
    </con:dependency>
    <con:dependency location="../../Schema/CreateMVAPushRecord_table.xsd">
        <con:schema ref="CommunicationV4/NotificationFramework/Schema/CreateMVAPushRecord_table"/>
    </con:dependency>
    <con:dependency location="../../../../VFQA_CSM_Common/Schema/dvm.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/dvm"/>
    </con:dependency>
</con:xqueryEntry>