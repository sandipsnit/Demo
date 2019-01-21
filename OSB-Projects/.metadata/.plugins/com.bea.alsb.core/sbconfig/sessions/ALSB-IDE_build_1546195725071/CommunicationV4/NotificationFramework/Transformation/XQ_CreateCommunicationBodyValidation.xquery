<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[(:: pragma bea:global-element-parameter parameter="$createCommunicationVBMRequest" element="ns4:CreateCommunicationVBMRequest" location="../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd" ::)
(:: pragma bea:global-element-parameter parameter="$outputParameters" element="ns6:OutputParameters" location="../Schema/GetNotificationDetails_sp.xsd" ::)
(:: pragma bea:schema-type-return type="ns3:ValidationErrorList" location="../../../VFQA_CSM_Common/Schema/validation.xsd" ::)

declare namespace ns2 = "urn:un:unece:uncefact:documentation:standard:CoreComponentType:2";
declare namespace ns1 = "http://group.vodafone.com/schema/vbo/technical/communication/v1";
declare namespace ns4 = "http://group.vodafone.com/schema/vbm/technical/communication/v1";
declare namespace ns3 = "http://www.vodafone.qa/egate/commons/validation/v1_0_0";
declare namespace ns0 = "http://group.vodafone.com/schema/extension/vbo/technical/communication/v1";
declare namespace ns5 = "http://group.vodafone.com/schema/common/v1";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_CreateCommunicationBodyValidation/";
declare namespace ns6 = "http://xmlns.oracle.com/pcbpel/adapter/db/sp/GetNotificationDetails";

declare function xf:XQ_CreateCommunicationBodyValidation($createCommunicationVBMRequest as element(ns4:CreateCommunicationVBMRequest),
    $outputParameters as element(ns6:OutputParameters),$type as xs:string)
    as element() {
        <ns3:Validation>
        {
         if($type eq "SMS") 
         then
           <ValidationErrorList>
    	           {    	          
    	             if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'SMS_TXT']/*:Column[@name = 'TYPE_VALUE']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'SMS Text' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:SubscriberNumber) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'REC_MSISDN']/*:Column[@name = 'TYPE_VALUE']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'SubscriberNumber' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'SMS']/*:Column[@name = 'ACKNOWLEDGEMENT_FLAG']) , "^\s*$")) 
                      then
		<ValidationError>
			<message>'ACKNOWLEDGEMENT FLAG' is not configured</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:DeliveryInd/*:IndicatorString) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'SMS']/*:Column[@name = 'DELIVERY_FLAG']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'DELIVERY FLAG' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'SMS']/*:Column[@name = 'PRIORITY']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'PRIORITY' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName = "profileType"]) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'SMS']/*:Column[@name = 'PROFILE_ID']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'PROFILE ID' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Name) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'SMS']/*:Column[@name = 'SENDER_NAME']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'SENDER NAME' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'SMS']/*:Column[@name = 'FORMAT']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'FORMAT' is not configured</message>
		</ValidationError>
                  else ()
                   }
	   </ValidationErrorList>
	   else if($type eq "MVA PUSH") 
         then
           <ValidationErrorList>
    	           {    	          
    	             if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:SubscriberNumber) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'REC_MSISDN']/*:Column[@name = 'TYPE_VALUE']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'SubscriberNumber' is not configured or sent</message>
		</ValidationError>
		
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Type[@listName="menuModule"]) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'MENU_MOD_ID']/*:Column[@name = 'TYPE_VALUE']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'Menu Module ID' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:ShortText) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'PUSH_TITLE']/*:Column[@name = 'TYPE_VALUE']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'MVA Push Name or  Title' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'PUSH_TEXT']/*:Column[@name = 'TYPE_VALUE']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'MVA Push Content' is not configured or sent</message>
		</ValidationError>
		
                  else ()
                   }
	   </ValidationErrorList>
	   else if($type eq "EMAIL") 
         then
           <ValidationErrorList>
    	           {    	          
    	        if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'EMAIL']/*:Column[@name = 'PRIORITY']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'PRIORITY' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName = "profileType"]) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'EMAIL']/*:Column[@name = 'PROFILE_ID']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'PROFILE ID' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Subject) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'SBJ']/*:Column[@name = 'TYPE_VALUE']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'Email Subject' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'BDY']/*:Column[@name = 'TYPE_VALUE']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'Email Body' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Extension/*:Email/*:FullAddress) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'EMAIL']/*:Column[@name = 'SENDER_NAME']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'Sender Email ID' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Receiver/*:Extension/*:Email/*:FullAddress) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'REC_EMAILID']/*:Column[@name = 'TYPE_VALUE']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'Receiver Email ID' is not configured or sent</message>
		</ValidationError>
		elseif(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Content/*:Type) , "^\s*$") and matches(data($outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'EMAIL']/*:Column[@name = 'FORMAT']), "^\s*$")) 
                      then
		<ValidationError>
			<message>'Email Content Type' is not configured or sent</message>
		</ValidationError>
                  else ()
                   }
	   </ValidationErrorList>
           else
           <ValidationError>
			<message>Invalid Target Type</message>
		</ValidationError>
           
        }
        </ns3:Validation>
};

declare variable $createCommunicationVBMRequest as element(ns4:CreateCommunicationVBMRequest) external;
declare variable $outputParameters as element(ns6:OutputParameters) external;
declare variable $type as xs:string  external;

xf:XQ_CreateCommunicationBodyValidation($createCommunicationVBMRequest,
    $outputParameters,$type)]]></con:xquery>
    <con:dependency location="../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM"/>
    </con:dependency>
    <con:dependency location="../Schema/GetNotificationDetails_sp.xsd">
        <con:schema ref="CommunicationV4/NotificationFramework/Schema/GetNotificationDetails_sp"/>
    </con:dependency>
    <con:dependency location="../../../VFQA_CSM_Common/Schema/validation.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/validation"/>
    </con:dependency>
</con:xqueryEntry>