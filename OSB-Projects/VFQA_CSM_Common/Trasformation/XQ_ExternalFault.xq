(:: pragma bea:global-element-parameter parameter="$fault" element="ns0:Fault" location="../Schema/Fault.xsd" ::)
(:: pragma bea:global-element-return element="ns0:Fault" location="../Schema/Fault.xsd" ::)

declare namespace ns2 = "http://docs.oasis-open.org/wsrf/bf-2";
declare namespace ns1 = "http://group.vodafone.com/schema/common/v1";
declare namespace ns3 = "http://www.w3.org/2005/08/addressing";
declare namespace ns0 = "http://group.vodafone.com/contract/vfo/fault/v1";
declare namespace xf = "http://tempuri.org/VFQA_CSM_Common/Trasformation/XQ_ExternalFault/";
declare namespace soapenv = "http://schemas.xmlsoap.org/soap/envelope/";

declare function xf:XQ_ExternalFault($fault as element(ns0:Fault))
    as element(*) {
        <soapenv:Fault>
			<faultcode>soapenv:Server</faultcode>
			<faultstring>An error has been received</faultstring>
			<detail>
				<ns0:Fault>
         			<ns0:ReasonCode>{ data($fault/ns0:ReasonCode) }</ns0:ReasonCode>
         			<ns0:Message>{ data($fault/ns0:Message) }</ns0:Message>     
        		</ns0:Fault>
			</detail>
		</soapenv:Fault>
        
        
};

declare variable $fault as element(ns0:Fault) external;

xf:XQ_ExternalFault($fault)