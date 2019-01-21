xquery version "1.0" encoding "Cp1252";
(:: pragma  parameter="$header" type="xs:anyType" ::)
(:: pragma bea:schema-type-return type="ns0:Validation" location="../../../VFQA_CSM_Common/Schema/validation.xsd" ::)
(:: pragma bea:global-element-parameter parameter="$createCommunicationVBMRequest1" element="ns5:CreateCommunicationVBMRequest" location="../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd" ::)

declare namespace xf = "http://tempuri.org/CommunicationV3/Transformation/XQ_CreateCommunicationHeadersValidation/";
declare namespace ns0 = "http://www.vodafone.qa/egate/commons/validation/v1_0_0";
declare namespace ns4 = "http://group.vodafone.com/schema/extension/vbo/technical/communication/v1";
declare namespace ns3 = "http://group.vodafone.com/schema/common/v1";
declare namespace ns5 = "http://group.vodafone.com/schema/vbm/technical/communication/v1";
declare namespace ns2 = "http://group.vodafone.com/schema/vbo/technical/communication/v1";
declare namespace ns1 = "urn:un:unece:uncefact:documentation:standard:CoreComponentType:2";

declare function xf:XQ_CreateCommunicationHeadersValidation($header as element(*),$createCommunicationVBMRequest as element(ns5:CreateCommunicationVBMRequest))
    as element() {
        <ns0:Validation>
            <ValidationErrorList>
                   	{                        
            if (empty($header/*:RouteInfo/*:Route/*:Keys/*:Key) or data($header/*:RouteInfo/*:Route/*:Keys/*:Key) eq "") 
            then
            <ValidationError>
                <message>Input header 'Route Key' is not valid</message>
            </ValidationError>
           
            else if (empty($header/*:Correlation/*:ConversationID) or data($header/*:Correlation/*:ConversationID) eq "") 
            then
            <ValidationError>
                <message>Input header 'ConversationID' is not valid</message>
            </ValidationError>
            else if (empty($header/*:Source/*:System) or data($header/*:Source/*:System) eq "") 
            then
            <ValidationError>
                <message>Input header 'Source System' is not valid</message>
            </ValidationError>
            else if (empty($header/*:Source/*:Timestamp) or data($header/*:Source/*:Timestamp) eq "") 
            then
            <ValidationError>
                <message>Input header 'Source Timestamp' is not valid</message>
            </ValidationError>
            else if (empty($header/*:Source/*:LanguageCode) or data($header/*:Source/*:LanguageCode) eq "") 
            then
            <ValidationError>
                <message>Input header 'Language Code' is not valid</message>
            </ValidationError>
            else if (empty($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Content/*:IDs/*:ID)or data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Content/*:IDs/*:ID)  eq  '')
            then
            <ValidationError>
                <message>Input header 'Template ID' is not valid</message>
            </ValidationError>
            else ()
        }
            </ValidationErrorList>
        </ns0:Validation>
};

declare variable $header as element(*) external;
declare variable $createCommunicationVBMRequest as element(ns5:CreateCommunicationVBMRequest) external;

xf:XQ_CreateCommunicationHeadersValidation($header,$createCommunicationVBMRequest)