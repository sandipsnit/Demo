(:: pragma bea:global-element-parameter parameter="$sMSRequestPayload1" element="ns2:SMSRequestPayload" location="../Schema/SendSMSIO.xsd" ::)
(:: pragma bea:global-element-return element="ns0:CreateCommunicationVBMRequest" location="../../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd" ::)
(:: pragma bea:global-element-parameter parameter="$retry" element="dvm:dvm" location="../../../../VFQA_CSM_Common/Schema/dvm.xsd" ::)

declare namespace ns5 = "http://group.vodafone.com/schema/extension/vbo/technical/communication/v1";
declare namespace ns0 = "http://group.vodafone.com/schema/vbm/technical/communication/v1";
declare namespace ns2 = "http://www.vfq.techmahindra.com/SMS";
declare namespace ns1 = "urn:un:unece:uncefact:documentation:standard:CoreComponentType:2";
declare namespace xf = "http://tempuri.org/VFQA_CRM_SOAPSubscriber/Transformation/XQ_SMSPayload_To_CreateCommunicationRequest_Req1/";
declare namespace ns4 = "http://group.vodafone.com/schema/common/v1";
declare namespace ns3 = "http://group.vodafone.com/schema/vbo/technical/communication/v1";
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


declare function xf:XQ_SMSPayload_To_CreateCommunicationRequest_Req1($sMSRequestPayload1 as element(ns2:SMSRequestPayload),$targetFormatDVM as element(*))
    as element(ns0:CreateCommunicationVBMRequest) {
        <ns0:CreateCommunicationVBMRequest>
            <ns0:CommunicationVBO>
                <ns3:Parts>
                    <ns3:ContactPoints>
                        <ns3:ContactPoint>
                            <ns3:Telephone>
                            <ns4:PhoneType>Mobile</ns4:PhoneType>
                            <ns4:SubscriberNumber>{ data($sMSRequestPayload1/*:MSISDN) }</ns4:SubscriberNumber>
                            </ns3:Telephone>
                        </ns3:ContactPoint>
                    </ns3:ContactPoints>
                    <ns3:Body>
                        <ns3:Content>
                            <ns4:IDs>
                                <ns4:ID>{ data($sMSRequestPayload1/*:message)}</ns4:ID>
                            </ns4:IDs>
                        </ns3:Content>
                    </ns3:Body>
                    <ns3:Specification>
                   {
                     for $TagParam in  $sMSRequestPayload1/*:TagList/*:TagParam 
                     return 
								if(data($TagParam/*:tagName)='PIN_FLD_PRIMARY_NUMBER') then
 									<ns4:CharacteristicsValue characteristicName = "{data($TagParam/*:tagName)}">
                            			<ns4:Value>{data($sMSRequestPayload1/*:MSISDN)}</ns4:Value>
                        			</ns4:CharacteristicsValue>
								else					 
                    				<ns4:CharacteristicsValue characteristicName = "{data($TagParam/*:tagName)}">
                            			<ns4:Value>{data(local:changeDataFormat(data($TagParam/*:tagValue),data($TagParam/*:tagName),$targetFormatDVM))}</ns4:Value>
                        </ns4:CharacteristicsValue>
                        }
                    </ns3:Specification>
                </ns3:Parts>
            </ns0:CommunicationVBO>
        </ns0:CreateCommunicationVBMRequest>
};

declare variable $sMSRequestPayload1 as element(ns2:SMSRequestPayload) external;
declare variable $targetFormatDVM as element(*) external;

xf:XQ_SMSPayload_To_CreateCommunicationRequest_Req1($sMSRequestPayload1,$targetFormatDVM)