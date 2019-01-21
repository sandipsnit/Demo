(:: pragma  parameter="$header" type="anyType" ::)
(:: pragma bea:global-element-parameter parameter="$createCommunicationVBMRequest" element="ns3:CreateCommunicationVBMRequest" location="../../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd" ::)
(:: pragma bea:global-element-return element="ns5:TbEmailDetailsCollection" location="../../Schema/CreateEmailRecord_table.xsd" ::)
(:: pragma bea:global-element-parameter parameter="$retry" element="dvm:dvm" location="../../../../VFQA_CSM_Common/Schema/dvm.xsd" ::)

declare namespace ns2 = "urn:un:unece:uncefact:documentation:standard:CoreComponentType:2";
declare namespace ns1 = "http://group.vodafone.com/schema/vbo/technical/communication/v1";
declare namespace ns4 = "http://group.vodafone.com/schema/common/v1";
declare namespace ns3 = "http://group.vodafone.com/schema/vbm/technical/communication/v1";
declare namespace ns0 = "http://group.vodafone.com/schema/extension/vbo/technical/communication/v1";
declare namespace ns5 = "http://xmlns.oracle.com/pcbpel/adapter/db/top/CreateEmailRecord";
declare namespace dvm = "http://xmlns.oracle.com/dvm";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/TEMPLATE_IS_NO/XQ_CreateCommunication_To_CreateEMAILRecord/";

declare function xf:XQ_CreateCommunication_To_CreateEMAILRecord($header as element(*),
    $createCommunicationVBMRequest as element(ns3:CreateCommunicationVBMRequest),$retry as element(dvm:dvm))
    as element(ns5:TbEmailDetailsCollection) {
        <ns5:TbEmailDetailsCollection>
            <ns5:TbEmailDetails>
                <ns5:osbTransactionId>{ fn:substring(fn:replace(fn-bea:uuid(),'-',''),3,26) }</ns5:osbTransactionId>
                <ns5:channelName>{data($header/*:Source/*:System)}</ns5:channelName>
                <ns5:profileId>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName="profileType"][@listAgencyName="Vodafone"])}</ns5:profileId>
                <ns5:priority>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority)}</ns5:priority>
                <ns5:format>{
                let $format := if(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Content/*:Type) eq 'text/html')
                				then
                					'HTML'
                				else
                					'PLAIN_TEXT'
                		return 
                			$format
                }</ns5:format>
                <ns5:recEmailid>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Receiver/*:Extension/*:Email/*:FullAddress)}</ns5:recEmailid>
                <ns5:ccEmailid>{
                    let $rec := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint[*:Type = 'CC']/*:Email/*:FullAddress) , "^\s*$"))
                    				then
                    					''
                    				else
                    					data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint[*:Type = 'CC']/*:Email/*:FullAddress)
                    		return
                    			$rec
                    
                     }</ns5:ccEmailid>
                <ns5:bccEmailid>{ 
                    let $rec := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint[*:Type = 'BCC']/*:Email/*:FullAddress) , "^\s*$"))
                    				then
                    					''
                    				else
                    					data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint[*:Type = 'BCC']/*:Email/*:FullAddress)
                    		return
                    			$rec
                    
                    }</ns5:bccEmailid>
                <ns5:subject>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Subject)}</ns5:subject>
                <ns5:body>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text)}</ns5:body>
                <ns5:senderEmailid>{data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Extension/*:Email/*:FullAddress)}</ns5:senderEmailid>
                <ns5:channelTransactionId>{data($header/*:Correlation/*:ConversationID)}</ns5:channelTransactionId>
                <ns5:notificationId></ns5:notificationId>
                <ns5:status>0</ns5:status>
                <ns5:created>{ fn:current-date() }</ns5:created>
                <ns5:lastUpdated>{ fn:current-date() }</ns5:lastUpdated>
                <ns5:statusMessage>NEW</ns5:statusMessage>
                <ns5:lang>{ data($header/*:Source/*:LanguageCode) }</ns5:lang>
                <ns5:retryCnt>{ data($retry/*:rows/*:row[*:cell[1] = 'EMAIL']/*:cell[2])}</ns5:retryCnt>
            </ns5:TbEmailDetails>
        </ns5:TbEmailDetailsCollection>
};

declare variable $header as element(*) external;
declare variable $createCommunicationVBMRequest as element(ns3:CreateCommunicationVBMRequest) external;
declare variable $retry as element(dvm:dvm) external;

xf:XQ_CreateCommunication_To_CreateEMAILRecord($header,
    $createCommunicationVBMRequest,$retry)