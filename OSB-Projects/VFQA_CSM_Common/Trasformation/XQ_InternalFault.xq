(:: pragma bea:global-element-return element="ns0:ErrorInformation" location="../Schema/ErrorInformation.xsd" ::)
(:: pragma bea:global-element-return element="ns1:Fault" location="../Schema/Fault.xsd" ::)

declare namespace ns2 = "http://group.vodafone.com/schema/common/v1";
declare namespace ns1 = "http://group.vodafone.com/contract/vfo/fault/v1";
declare namespace ns4 = "http://www.w3.org/2005/08/addressing";
declare namespace ns3 = "http://docs.oasis-open.org/wsrf/bf-2";
declare namespace ns5 = "http://www.vodafone.qa/ErrorInformation";
declare namespace xf = "http://tempuri.org/VFQA_CSM_Common/Trasformation/XQ_InternalFault/";

declare function xf:XQ_InternalFault($request as element(ns5:ErrorInformation))
    as element(ns1:Fault) {
        <ns1:Fault>
            <ns3:Timestamp>{ fn:current-dateTime() }</ns3:Timestamp>
           	<ns3:Originator>
                <ns4:Address>{ data($request/*:SystemName) }</ns4:Address>
            </ns3:Originator> 
            <ns3:ErrorCode dialect = "EN">{ data($request/*:ErrorCode) }</ns3:ErrorCode>
            <ns3:Description xml:lang = "EN">{ data($request/*:ErrorDescription) }</ns3:Description>
            <ns1:Name>{ data($request/*:TransactionID) }</ns1:Name>
            <ns1:Severity>{ data($request/*:Severity) }</ns1:Severity>
           	<ns1:Category>{ data($request/*:Category) }</ns1:Category>
            
            {
            	let $resoncode :=  if(starts-with(data($request/*:ErrorCode),"BEA"))
            	
            				  then "EGATE_ERR_500"
                                    
                                    else if(data($request/*:ErrorCode) eq "1001")
            				  
            				  then "1001"

            				  else concat("EGATE_ERR_",data($request/*:ErrorCode))
            				  
                return
            		<ns1:ReasonCode>{ data($resoncode) }</ns1:ReasonCode>
            }
            
            <ns1:Message>{ data($request/*:ErrorDetail) }</ns1:Message>
            
        </ns1:Fault>
};

declare variable $request as element(ns5:ErrorInformation) external;

xf:XQ_InternalFault($request)