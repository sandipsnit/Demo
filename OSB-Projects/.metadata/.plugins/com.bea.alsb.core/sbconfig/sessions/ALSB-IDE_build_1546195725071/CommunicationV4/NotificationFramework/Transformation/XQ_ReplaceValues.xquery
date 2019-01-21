<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[(:: pragma bea:global-element-parameter parameter="$createCommunicationVBMRequest" element="ns4:CreateCommunicationVBMRequest" location="../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd" ::)
(:: pragma bea:global-element-parameter parameter="$outputParameters" element="ns6:OutputParameters" location="../Schema/GetNotificationDetails_sp.xsd" ::)
(:: pragma  type="anyType" ::)

declare namespace ns2 = "http://group.vodafone.com/schema/vbo/technical/communication/v1";
declare namespace ns1 = "http://vodafone.qa/CreateNotificationRecord/";
declare namespace ns4 = "http://group.vodafone.com/schema/vbm/technical/communication/v1";
declare namespace ns3 = "urn:un:unece:uncefact:documentation:standard:CoreComponentType:2";
declare namespace ns0 = "http://group.vodafone.com/schema/extension/vbo/technical/communication/v1";
declare namespace ns5 = "http://group.vodafone.com/schema/common/v1";
declare namespace ns6 = "http://xmlns.oracle.com/pcbpel/adapter/db/sp/GetNotificationDetails";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_ReplaceValues/";

declare function xf:XQ_ReplaceValues($createCommunicationVBMRequest as element(ns4:CreateCommunicationVBMRequest),
    $outputParameters as element(ns6:OutputParameters))
    as element(*) {
     <TagList>
	{
	for $Row in $outputParameters/*:V_STATICVALUES/*:Row
	return
     <TagParam>             
		<tagName>{ data($Row/*:Column[@name = "KEY" ]) }</tagName>
		<tagValue>{ data($Row/*:Column[@name = "VALUE" ]) }</tagValue>
	</TagParam>
	}
	{
	for $CharacteristicsValue in $createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Specification/*:CharacteristicsValue
	return
     <TagParam>             
		<tagName>{ data($CharacteristicsValue/@characteristicName) }</tagName>
		<tagValue>{ data($CharacteristicsValue/*:Value) }</tagValue>
	</TagParam>
	}
</TagList>
       
   

};

declare variable $createCommunicationVBMRequest as element(ns4:CreateCommunicationVBMRequest) external;
declare variable $outputParameters as element(ns6:OutputParameters) external;

xf:XQ_ReplaceValues($createCommunicationVBMRequest,
    $outputParameters)]]></con:xquery>
    <con:dependency location="../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM"/>
    </con:dependency>
    <con:dependency location="../Schema/GetNotificationDetails_sp.xsd">
        <con:schema ref="CommunicationV4/NotificationFramework/Schema/GetNotificationDetails_sp"/>
    </con:dependency>
</con:xqueryEntry>