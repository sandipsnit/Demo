<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[(:: pragma  parameter="$VFQANotificationsRequest" type="anyType" ::)
(:: pragma bea:global-element-return element="ns0:CreateCommunicationVBMRequest" location="../../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd" ::)
(:: pragma bea:global-element-parameter parameter="$retry" element="dvm:dvm" location="../../../../VFQA_CSM_Common/Schema/dvm.xsd" ::)

declare namespace ns0 = "http://group.vodafone.com/schema/vbm/technical/communication/v1";
declare namespace ns2 = "http://group.vodafone.com/schema/vbo/technical/communication/v1";
declare namespace ns1 = "urn:un:unece:uncefact:documentation:standard:CoreComponentType:2";
declare namespace xf = "http://tempuri.org/VFQA_BRM_AQSubscriber/Transformation/XQ_VFQANotificationsRequest_To_CreateCommunicationRequest_Req1/";
declare namespace ns4 = "http://group.vodafone.com/schema/extension/vbo/technical/communication/v1";
declare namespace ns3 = "http://group.vodafone.com/schema/common/v1";
declare namespace dvm = "http://xmlns.oracle.com/dvm";
declare namespace functx = "http://www.functx.com";

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



declare function xf:XQ_VFQANotificationsRequest_To_CreateCommunicationRequest_Req1($VFQANotificationsRequest as element(*),$targetFormatDVM as element(*))
    as element(ns0:CreateCommunicationVBMRequest) {
        <ns0:CreateCommunicationVBMRequest>
            <ns0:CommunicationVBO>
  				<ns3:Type>{
  			
						fn:string-join($VFQANotificationsRequest/*:ParamDetails[*:Name = 'PIN_FLD_CHANNEL'] /*:Value,",")
  				}</ns3:Type>
                <ns2:Parts>
                    <ns2:ContactPoints>
                        <ns2:ContactPoint>
                            <ns2:Telephone>
                                <ns3:PhoneType>Mobile</ns3:PhoneType>
                                <ns3:SubscriberNumber>{ data($VFQANotificationsRequest/*:Msisdn) }</ns3:SubscriberNumber>
                            </ns2:Telephone>
                        </ns2:ContactPoint>
                    </ns2:ContactPoints>
                    <ns2:Body>
                        <ns2:Content>
                            <ns3:IDs>
                                <ns3:ID>{ data($VFQANotificationsRequest/*:MsgID) }</ns3:ID>
                            </ns3:IDs>
                        </ns2:Content>
                    </ns2:Body>
                    <ns2:Specification>
                       {
                     for $ParamDetails in  $VFQANotificationsRequest/*:ParamDetails return 
						if(data($ParamDetails/*:Name)='PIN_FLD_PRIMARY_NUMBER') then
 						<ns3:CharacteristicsValue characteristicName = "{data($ParamDetails/*:Name)}">
                            <ns3:Value>{data($VFQANotificationsRequest/*:Msisdn)}</ns3:Value>
                        </ns3:CharacteristicsValue>
						else					 
                    <ns3:CharacteristicsValue characteristicName = "{data($ParamDetails/*:Name)}">
                            <ns3:Value>{data(local:changeDataFormat(data($ParamDetails/*:Name),data($ParamDetails/*:Value),$targetFormatDVM))}</ns3:Value>
                        </ns3:CharacteristicsValue>
                        }
                    </ns2:Specification>
                </ns2:Parts>
            </ns0:CommunicationVBO>
        </ns0:CreateCommunicationVBMRequest>
};

declare variable $VFQANotificationsRequest as element(*) external;
declare variable $targetFormatDVM as element(*) external;

xf:XQ_VFQANotificationsRequest_To_CreateCommunicationRequest_Req1($VFQANotificationsRequest,$targetFormatDVM)]]></con:xquery>
    <con:dependency location="../../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM"/>
    </con:dependency>
    <con:dependency location="../../../../VFQA_CSM_Common/Schema/dvm.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/dvm"/>
    </con:dependency>
</con:xqueryEntry>