xquery version "1.0" encoding "Cp1252";
(:: pragma  parameter="$osmJMSHeader" type="xs:anyType" ::)
(:: pragma  type="xs:anyType" ::)

declare namespace xf = "http://tempuri.org/PS_VFQA_OSM_JMSSubscriber/Transformation/HeaderGeneration/";

declare function xf:HeaderGeneration($osmJMSHeader as element(*))
    as element(*) {
<soapenv:Header xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v1="http://group.vodafone.com/contract/vho/header/v1" >
	<v1:RouteInfo>
		<v1:Route>
			<v1:Keys>
				<v1:Key Name="template">{upper-case(data($osmJMSHeader/*:user-header[@name="NotificationTemplate"]/@value ))}</v1:Key>
			</v1:Keys>
		</v1:Route>
	</v1:RouteInfo>
	<v1:Correlation>
		<v1:ConversationID>{data($osmJMSHeader/*:user-header[@name="ConversationID"]/@value )}</v1:ConversationID>
	</v1:Correlation>
	<v1:Source>
		<v1:System>{upper-case(data($osmJMSHeader/*:user-header[@name="SourceSystem"]/@value ))}</v1:System>
		<v1:Timestamp>{data($osmJMSHeader/*:user-header[@name="SourceTimestamp"]/@value )}</v1:Timestamp>
		<v1:LanguageCode>{upper-case(data($osmJMSHeader/*:user-header[@name="SourceLanguageCode"]/@value ))}</v1:LanguageCode>
	</v1:Source>
</soapenv:Header>
};

declare variable $osmJMSHeader as element(*) external;
xf:HeaderGeneration($osmJMSHeader)