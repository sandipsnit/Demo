xquery version "1.0" encoding "Cp1252";
(:: pragma  parameter="$anyType1" type="xs:anyType" ::)
(:: pragma  type="xs:anyType" ::)

declare namespace xf = "http://tempuri.org/PS_VFQA_OSM_JMSSubscriber/Transformation/HeaderGeneration/";

declare function xf:HeaderGeneration($requestHeader as element(*),$languageDVM as element(*),$lang as xs:string)
    as element(*) {
<soapenv:Header xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v1="http://group.vodafone.com/contract/vho/header/v1" >
	<v1:RouteInfo>
		<v1:Route>
			<v1:Keys>
				<v1:Key Name="template">YES</v1:Key>
			</v1:Keys>
		</v1:Route>
	</v1:RouteInfo>
	<v1:Correlation>
		<v1:ConversationID>{ data($requestHeader/*:Correlation/*:ConversationID ) }</v1:ConversationID>
	</v1:Correlation>
	<v1:Source>
		<v1:System>{data($requestHeader/*:Source/*:System)}</v1:System>
		<v1:Timestamp>{ fn:current-dateTime() }</v1:Timestamp>
		<v1:LanguageCode>{data($languageDVM/*:rows/*:row[*:cell[1] =$lang]/*:cell[2])}</v1:LanguageCode>
	</v1:Source>
</soapenv:Header>
};

declare variable $requestHeader as element(*) external;
declare variable $languageDVM as element(*)  external;
declare variable $lang as xs:string external;
xf:HeaderGeneration($requestHeader,$languageDVM,$lang)