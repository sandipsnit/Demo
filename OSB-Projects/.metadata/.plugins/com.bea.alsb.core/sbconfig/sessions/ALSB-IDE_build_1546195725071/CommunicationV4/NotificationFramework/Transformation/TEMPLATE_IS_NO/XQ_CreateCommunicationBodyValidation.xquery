<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[xquery version "1.0" encoding "Cp1252";
(:: pragma bea:global-element-parameter parameter="$createCommunicationVBMRequest" element="ns4:CreateCommunicationVBMRequest" location="../../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd" ::)
(:: pragma bea:schema-type-return type="ns3:Validation" location="../../../../VFQA_CSM_Common/Schema/validation.xsd" ::)

declare namespace xf = "http://tempuri.org/CommunicationV3/Transformation/XQ_CreateCommunicationBodyValidation/";
declare namespace ns2 = "urn:un:unece:uncefact:documentation:standard:CoreComponentType:2";
declare namespace ns1 = "http://group.vodafone.com/schema/vbo/technical/communication/v1";
declare namespace ns4 = "http://group.vodafone.com/schema/vbm/technical/communication/v1";
declare namespace ns3 = "http://www.vodafone.qa/egate/commons/validation/v1_0_0";
declare namespace ns0 = "http://group.vodafone.com/schema/extension/vbo/technical/communication/v1";
declare namespace ns5 = "http://group.vodafone.com/schema/common/v1";

declare function xf:XQ_CreateCommunicationBodyValidation($createCommunicationVBMRequest as element(ns4:CreateCommunicationVBMRequest))
    as element() {
        <ns3:Validation>
           <ns3:ValidationErrorList>
    	           {
    	           if(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Type) eq 'SMS')
    	           then 
    	           (
    	             if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority) ne '1') 
                      then
                       <ns3:ValidationError>
                               <ns3:message>Input parameter 'Priority' is not valid</ns3:message>
                      </ns3:ValidationError>
                      else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:DeliveryInd/*:IndicatorString)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:DeliveryInd/*:IndicatorString) ne 'N')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Indicator String' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Name)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Name) ne 'Vodafone')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Sender Name' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName="profileType"][@listAgencyName="Vodafone"])or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName="profileType"][@listAgencyName="Vodafone"]) ne '0')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Category' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:PhoneType)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:PhoneType) ne 'Mobile')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Phone Type' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:SubscriberNumber)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:SubscriberNumber) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Subscriber Number' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'SMS Text' is blank</ns3:message>
                     </ns3:ValidationError>
                    else()
                     )
                    else if(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Type) eq 'EMAIL')
                    then
                    (
                     if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority) ne '1') 
                      then
                       <ns3:ValidationError>
                               <ns3:message>Input parameter 'Priority' is not valid</ns3:message>
                      </ns3:ValidationError>
                      else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Subject)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Subject) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Subject' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:DeliveryInd/*:IndicatorString)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:DeliveryInd/*:IndicatorString) ne 'N')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Indicator String' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName="profileType"][@listAgencyName="Vodafone"])or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName="profileType"][@listAgencyName="Vodafone"]) ne '0')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Category' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Extension/*:Email/*:FullAddress)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Extension/*:Email/*:FullAddress) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Sender Email ID' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Receiver/*:Extension/*:Email/*:FullAddress)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Receiver/*:Extension/*:Email/*:FullAddress) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Receiver Email ID' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Email Body' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Content/*:Type)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Content/*:Type) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Email Content Type' is not valid</ns3:message>
                     </ns3:ValidationError>
                   else()
                   )
                   else if(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Type) eq 'MVA PUSH')
                    then
                    (
                     if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:SentDateTime)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:SentDateTime) eq '') 
                      then
                       <ns3:ValidationError>
                               <ns3:message>Input parameter 'SentDateTime' is not valid</ns3:message>
                      </ns3:ValidationError>
                                      else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority) ne '1') 
                      then
                       <ns3:ValidationError>
                               <ns3:message>Input parameter 'Priority' is not valid</ns3:message>
                      </ns3:ValidationError>
                      else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Subject)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Subject) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Subject' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:DeliveryInd/*:IndicatorString)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:DeliveryInd/*:IndicatorString) ne 'N')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Indicator String' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Type[@listName ="menuModule" and @listAgencyName="Vodafone"])or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Type[@listName ="menuModule" and @listAgencyName="Vodafone"]) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'MenuModule' is not valid</ns3:message>
                     </ns3:ValidationError>
                      else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName="profileType" and @listAgencyName="Vodafone"])or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName="profileType" and @listAgencyName="Vodafone"]) ne '0')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Category' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:PhoneType)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:PhoneType) ne 'Mobile')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Phone Type' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:SubscriberNumber)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:SubscriberNumber) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'MSISDN' is not valid</ns3:message>
                     </ns3:ValidationError>
                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Push Notification Text' is blank</ns3:message>
                     </ns3:ValidationError>
                                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:ShortText)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:ShortText) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Push Notification Title' is blank</ns3:message>
                     </ns3:ValidationError>
                                     else if(empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Content/*:Type)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Content/*:Type) eq '')
                      then
                      <ns3:ValidationError>
                              <ns3:message>Input parameter 'Push Notification Type' is blank</ns3:message>
                     </ns3:ValidationError>
                   else()
                   )
                  else
                 (
                  <ns3:ValidationError>
                             <ns3:message>Input parameter 'Type' is not valid</ns3:message>
                   </ns3:ValidationError>
                  )
                   }
    	</ns3:ValidationErrorList>
    </ns3:Validation>
};

declare variable $createCommunicationVBMRequest as element(ns4:CreateCommunicationVBMRequest) external;

xf:XQ_CreateCommunicationBodyValidation($createCommunicationVBMRequest)]]></con:xquery>
    <con:dependency location="../../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM"/>
    </con:dependency>
    <con:dependency location="../../../../VFQA_CSM_Common/Schema/validation.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/validation"/>
    </con:dependency>
</con:xqueryEntry>