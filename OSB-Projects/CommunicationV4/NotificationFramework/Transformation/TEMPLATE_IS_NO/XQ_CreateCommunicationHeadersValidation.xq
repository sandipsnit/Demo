xquery version "1.0" encoding "Cp1252";
(:: pragma  parameter="$anyType" type="xs:anyType" ::)
(:: pragma bea:schema-type-return type="ns0:Validation" location="../../../../VFQA_CSM_Common/Schema/validation.xsd" ::)

declare namespace xf = "http://tempuri.org/CommunicationV3/Transformation/XQ_CreateCommunicationHeadersValidation/";
declare namespace ns0 = "http://www.vodafone.qa/egate/commons/validation/v1_0_0";

declare function xf:XQ_CreateCommunicationHeadersValidation($anyType as element(*))
    as element() {
        <ns0:Validation>
            <ValidationErrorList>
                   	{
            
            if (empty($anyType/*:RouteInfo/*:Route/*:Keys/*:Key[@Name="template"]) or data($anyType/*:RouteInfo/*:Route/*:Keys/*:Key[@Name="template"]) ne "NO" or data($anyType/*:RouteInfo/*:Route/*:Keys/*:Key[@Name="template"]) eq "") 
            then
            <ValidationError>
                <message>Input header 'Route Key' is not valid</message>
            </ValidationError>
           
            else if (empty($anyType/*:Correlation/*:ConversationID) or data($anyType/*:Correlation/*:ConversationID) eq "") 
            then
            <ValidationError>
                <message>Input header 'ConversationID' is not valid</message>
            </ValidationError>
            else if (empty($anyType/*:Source/*:System) or data($anyType/*:Source/*:System) eq "") 
            then
            <ValidationError>
                <message>Input header 'Source System' is not valid</message>
            </ValidationError>
            else if (empty($anyType/*:Source/*:Timestamp) or data($anyType/*:Source/*:Timestamp) eq "") 
            then
            <ValidationError>
                <message>Input header 'Source Timestamp' is not valid</message>
            </ValidationError>
            else if (empty($anyType/*:Source/*:LanguageCode) or data($anyType/*:Source/*:LanguageCode) eq "") 
            then
            <ValidationError>
                <message>Input header 'Language Code' is not valid</message>
            </ValidationError>
            else ()
        }
            </ValidationErrorList>
        </ns0:Validation>
};

declare variable $anyType as element(*) external;

xf:XQ_CreateCommunicationHeadersValidation($anyType)