<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[(:: pragma bea:global-element-parameter parameter="$sendCommunicationListVBMRequest" element="ns0:SendCommunicationListVBMRequest" location="../../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd" ::)
(:: pragma bea:global-element-return element="ns0:CreateCommunicationVBMRequest" location="../../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd" ::)
(:: pragma bea:global-element-parameter parameter="$retry" element="dvm:dvm" location="../../../../VFQA_CSM_Common/Schema/dvm.xsd" ::)

declare namespace ns0 = "http://group.vodafone.com/schema/vbm/technical/communication/v1";
declare namespace ns2 = "http://group.vodafone.com/schema/vbo/technical/communication/v1";
declare namespace ns1 = "urn:un:unece:uncefact:documentation:standard:CoreComponentType:2";
declare namespace xf = "http://tempuri.org/VFQA_OSM_JMSSubscriber/Transformation/XQ_SendCommunicationRequest_To_CreateCommunicationRequest_Req/";
declare namespace ns4 = "http://group.vodafone.com/schema/extension/vbo/technical/communication/v1";
declare namespace ns3 = "http://group.vodafone.com/schema/common/v1";
declare namespace dvm = "http://xmlns.oracle.com/dvm";

declare function local:changeDataFormat
  ( $holderName as xs:string,$holderValue as xs:string ,$targetFormatDVM as element(*))  as xs:string  {
    let $format:= data($targetFormatDVM/*:rows/*:row[*:cell[1] =$holderName]/*:cell[2])
    return
     if($format='DateString') then
      substring($holderValue, 1,10)
     else if($format='Numeric') then         
     fn-bea:format-number(xs:double($holderValue),"##,##,##0.00") 
     else 
    $holderValue
  
 } ;


declare function xf:XQ_SendCommunicationRequest_To_CreateCommunicationRequest_Req($sendCommunicationListVBMRequest as element(*),$targetFormatDVM as element(*)
,$accountNumber as xs:string,$accType as xs:string,$SubscriberNumber as xs:string)
    as element(ns0:CreateCommunicationVBMRequest) {
        <ns0:CreateCommunicationVBMRequest>
            <ns0:CommunicationVBO>
                <ns3:Type>{ data($sendCommunicationListVBMRequest/*:Type) }</ns3:Type>
                <ns2:Details>
                    
                    <ns2:Priority>{ data($sendCommunicationListVBMRequest//*:Details/*:Priority) }</ns2:Priority>
                  
                    <ns2:DeliveryInd>
                        <ns1:IndicatorString>{ data($sendCommunicationListVBMRequest//*:Details/*:DeliveryInd/*:IndicatorString) }</ns1:IndicatorString>
                    </ns2:DeliveryInd>
                </ns2:Details>
                <ns2:Roles>
                    <ns2:Sender>
                        <ns3:Name>{ data($sendCommunicationListVBMRequest//*:Roles/*:Sender/*:Name) }</ns3:Name>
                        <ns3:Categories>
                            <ns3:Category listAgencyName = "Vodafone"
                                          listName = "profileType">{ data($sendCommunicationListVBMRequest//*:Roles/*:Sender/*:Categories/*:Category[@listName="profileType" and @listAgencyName="Vodafone"]) }</ns3:Category>
                        </ns3:Categories>
                      </ns2:Sender>
                </ns2:Roles>
                <ns2:Parts>
                    <ns2:ContactPoints>
                  
                        <ns2:ContactPoint>
                            <ns3:IDs>
                                <ns3:ID schemeName = "accountNumber"
                                        schemeAgencyName = "Vodafone">
                                    {
                                        data($accountNumber)
                                    }
							</ns3:ID>
                            </ns3:IDs>
                            <ns3:Type>{ data($accType)}</ns3:Type>
                            <ns2:Telephone>
                                <ns3:PhoneType>Mobile</ns3:PhoneType>
                                <ns3:SubscriberNumber>{ data($SubscriberNumber) }</ns3:SubscriberNumber>
                            </ns2:Telephone>
                        </ns2:ContactPoint>
                      
                    </ns2:ContactPoints>
                    <ns2:Body>
                        
                        <ns2:Content>
                            <ns3:IDs>
                                <ns3:ID>{ data($sendCommunicationListVBMRequest//*:Parts/*:Body/*:Content/*:IDs/*:ID)}</ns3:ID>
                            </ns3:IDs>
                                                       
                        </ns2:Content>
                    </ns2:Body>
                   
                    <ns2:Specification>
                    {
                    for $CharacteristicsValue in  $sendCommunicationListVBMRequest//*:Parts/*:Specification/*:CharacteristicsValue 
                    return 
                    	if(data($CharacteristicsValue/@characteristicName)='PIN_FLD_PRIMARY_NUMBER') then
                    		<ns3:CharacteristicsValue characteristicName = "PIN_FLD_PRIMARY_NUMBER">
                            			<ns3:Value>{ data($SubscriberNumber)}</ns3:Value>
                        </ns3:CharacteristicsValue>
                        else
                    
                        <ns3:CharacteristicsValue characteristicName = "{data($CharacteristicsValue/@characteristicName)}">
                            <ns3:Value>{data(local:changeDataFormat(data($CharacteristicsValue/@characteristicName),data($CharacteristicsValue/*:Value),$targetFormatDVM))}</ns3:Value>
                        </ns3:CharacteristicsValue>
                        }
                    </ns2:Specification>
                </ns2:Parts>
            </ns0:CommunicationVBO>
        </ns0:CreateCommunicationVBMRequest>
};

declare variable $sendCommunicationListVBMRequest as element(*) external;
declare variable $targetFormatDVM as element(*) external;
declare variable $accountNumber as xs:string external;
declare variable $accType as xs:string external;
declare variable $SubscriberNumber as xs:string external;

xf:XQ_SendCommunicationRequest_To_CreateCommunicationRequest_Req($sendCommunicationListVBMRequest,$targetFormatDVM,$accountNumber,$accType,$SubscriberNumber)]]></con:xquery>
    <con:dependency location="../../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM"/>
    </con:dependency>
    <con:dependency location="../../../../VFQA_CSM_Common/Schema/dvm.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/dvm"/>
    </con:dependency>
</con:xqueryEntry>