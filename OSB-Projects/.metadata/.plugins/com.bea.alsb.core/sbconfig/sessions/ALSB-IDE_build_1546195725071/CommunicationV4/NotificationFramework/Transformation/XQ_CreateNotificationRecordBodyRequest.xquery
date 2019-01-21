<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[(:: pragma bea:global-element-parameter parameter="$createCommunicationVBMRequest" element="ns4:CreateCommunicationVBMRequest" location="../../../VFQA_CSM_Common/Schema/VBO/Communication/V1/CommunicationVBM.xsd" ::)
(:: pragma bea:global-element-parameter parameter="$outputParameters" element="ns6:OutputParameters" location="../Schema/GetNotificationDetails_sp.xsd" ::)
(:: pragma bea:global-element-return element="ns1:CreateNotification" location="../WSDL/CreateNotificationRecord.wsdl" ::)
(:: pragma bea:global-element-parameter parameter="$retry" element="dvm:dvm" location="../../../VFQA_CSM_Common/Schema/dvm.xsd" ::)

declare namespace ns2 = "http://group.vodafone.com/schema/vbo/technical/communication/v1";
declare namespace ns1 = "http://vodafone.qa/CreateNotificationRecord/";
declare namespace ns4 = "http://group.vodafone.com/schema/vbm/technical/communication/v1";
declare namespace ns3 = "urn:un:unece:uncefact:documentation:standard:CoreComponentType:2";
declare namespace ns0 = "http://group.vodafone.com/schema/extension/vbo/technical/communication/v1";
declare namespace ns5 = "http://group.vodafone.com/schema/common/v1";
declare namespace ns6 = "http://xmlns.oracle.com/pcbpel/adapter/db/sp/GetNotificationDetails";
declare namespace dvm = "http://xmlns.oracle.com/dvm";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_CreateNotificationRecordBodyRequest/";

declare function xf:XQ_CreateNotificationRecordBodyRequest($createCommunicationVBMRequest as element(ns4:CreateCommunicationVBMRequest),
    $outputParameters as element(ns6:OutputParameters),$header as element(*),$value as element(*),$retry as element(dvm:dvm))
    as element(ns1:CreateNotification) {
        <ns1:CreateNotification>
            {
                for $Row in $outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'SMS']
                return
                    <TbDetails>
                        <targetType>{ data($Row/*:Column[@name = 'CHANNEL_NAME']) }</targetType>
						<osbTransactionId>{ fn:substring(fn:replace(fn-bea:uuid(),'-',''),3,26) }</osbTransactionId>
                <channelTransactionId>{data($header/*:Correlation/*:ConversationID)}</channelTransactionId>
                <msisdn>
                {
                let $mobile := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:SubscriberNumber) , "^\s*$"))
                				then
                			 data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'REC_MSISDN']/*:Column[@name = 'TYPE_VALUE'])
                			 else
                			 	data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:SubscriberNumber)
                	return
                		 $mobile
                }
                </msisdn>
                <channelName>{data($header/*:Source/*:System)}</channelName>
                <lang>{data($header/*:Source/*:LanguageCode)}</lang>
                <status>0</status>
                <statusMessage>NEW</statusMessage>
                <created>{ fn:current-date() }</created>
                <lastUpdated>{ fn:current-date() }</lastUpdated>
                <notificationId>{ data($Row/*:Column[@name = 'NOTIFICATION_ID']) }</notificationId>
                <retryCnt> { data($retry/*:rows/*:row[*:cell[1] = 'SMS']/*:cell[2])}</retryCnt>
                <profileId>{
                let $profileType := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName = "profileType"]) , "^\s*$"))
                				then
                			 data($Row/*:Column[@name = 'PROFILE_ID'])
                			 else
                			 	data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName = "profileType"])
                	return
                		 $profileType
                }</profileId>
                <priority>{
                let $Priority := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority) , "^\s*$"))
                				then
                			 data($Row/*:Column[@name = 'PRIORITY']) 
                			 else
                			 	data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority)
                	return
                		 $Priority
                }</priority>
                <format>{
                 data($Row/*:Column[@name = 'FORMAT']) 
                }</format>
                <acknowledgementFlag>{ data($Row/*:Column[@name = 'ACKNOWLEDGEMENT_FLAG']) }</acknowledgementFlag>
                <deliveryFlag>{
                let $IndicatorString := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:DeliveryInd/*:IndicatorString) , "^\s*$"))
                				then
                			  data($Row/*:Column[@name = 'DELIVERY_FLAG'])
                			 else
                			 	data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:DeliveryInd/*:IndicatorString)
                	return
                		 $IndicatorString
                }</deliveryFlag>
                <dynamicValues>
                    <Column name = "smsText">{ 
                    let $txt := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text) , "^\s*$"))
                    			then
                    				cus5e:replaceAllString(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'SMS_TXT']/*:Column[@name = 'TYPE_VALUE']),fn-bea:serialize($value))
                    			else
                    				cus5e:replaceAllString(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text),fn-bea:serialize($value))
                    	return
                    		$txt
                     }</Column>
                    <Column name = "senderName">
                    {
                let $Name := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Name) , "^\s*$"))
                				then
                			 data($Row/*:Column[@name = 'SENDER_NAME'])
                			 else
                			 	data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Name)
                	return
                		 $Name
                }</Column>
                 <Column name = "accountId">{ data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:IDs/*:ID[@schemeName = "accountNumber"]) }</Column>
                </dynamicValues>
                </TbDetails>
            }
            {
                for $Row in $outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'EMAIL']
                return
                    <TbDetails>
                       <targetType>{ data($Row/*:Column[@name = 'CHANNEL_NAME']) }</targetType>
						<osbTransactionId>{ fn:substring(fn:replace(fn-bea:uuid(),'-',''),3,26) }</osbTransactionId>
                <channelTransactionId>{data($header/*:Correlation/*:ConversationID)}</channelTransactionId>
                <msisdn></msisdn>
                <channelName>{data($header/*:Source/*:System)}</channelName>
                <lang>{data($header/*:Source/*:LanguageCode)}</lang>
                <status>0</status>
                <statusMessage>NEW</statusMessage>
                <created>{ fn:current-date() }</created>
                <lastUpdated>{ fn:current-date() }</lastUpdated>
                <notificationId>{ data($Row/*:Column[@name = 'NOTIFICATION_ID']) }</notificationId>
                <retryCnt> { data($retry/*:rows/*:row[*:cell[1] = 'EMAIL']/*:cell[2])}</retryCnt>
                <profileId>{
                let $profileType := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName = "profileType"]) , "^\s*$"))
                				then
                			 data($Row/*:Column[@name = 'PROFILE_ID'])
                			 else
                			 	data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Categories/*:Category[@listName = "profileType"])
                	return
                		 $profileType
                }</profileId>
                <priority>{
                let $Priority := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority) , "^\s*$"))
                				then
                			 data($Row/*:Column[@name = 'PRIORITY']) 
                			 else
                			 	data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Priority)
                	return
                		 $Priority
                }</priority>
                <format>{
                let $fmat := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Content/*:Type) , "^\s*$"))
                				then
                					  data($Row/*:Column[@name = 'FORMAT']) 
                				else
                				data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Content/*:Type)
                	return
                			$fmat 
               
                }</format>
                <acknowledgementFlag>{ data($Row/*:Column[@name = 'ACKNOWLEDGEMENT_FLAG']) }</acknowledgementFlag>
                <deliveryFlag>{data($Row/*:Column[@name = 'DELIVERY_FLAG'])
                			
                }</deliveryFlag>
                <dynamicValues>
                    <Column name = "recEmailid">{ 
                    let $rec := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Receiver/*:Extension/*:Email/*:FullAddress) , "^\s*$"))
                    				then
                    					data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'REC_EMAILID']/*:Column[@name = 'TYPE_VALUE'])
                    				else
                    					data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Receiver/*:Extension/*:Email/*:FullAddress)
                    		return
                    			$rec
                    
                    }</Column>
                    <Column name = "ccEmailid">{
                    let $rec := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint[*:Type = 'CC']/*:Email/*:FullAddress) , "^\s*$"))
                    				then
                    					data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'CC_EMAILID']/*:Column[@name = 'TYPE_VALUE'])
                    				else
                    					data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint[*:Type = 'CC']/*:Email/*:FullAddress)
                    		return
                    			$rec
                    
                     }</Column>
                    <Column name = "bccEmailid">
                    { 
                    let $rec := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint[*:Type = 'BCC']/*:Email/*:FullAddress) , "^\s*$"))
                    				then
                    					data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'BCC_EMAILID']/*:Column[@name = 'TYPE_VALUE'])
                    				else
                    					data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint[*:Type = 'BCC']/*:Email/*:FullAddress)
                    		return
                    			$rec
                    
                    }</Column>
                    <Column name = "subject">{
                    let $sub := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Subject) , "^\s*$"))
                    			then
                    				cus5e:replaceAllString(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'SBJ']/*:Column[@name = 'TYPE_VALUE']),fn-bea:serialize($value))
                    			else
                    				cus5e:replaceAllString(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Details/*:Subject),fn-bea:serialize($value))
                    	return
                    		$sub
                    
                     }</Column>
                    <Column name = "body">{ 
                    let $bdy := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text) , "^\s*$"))
                    			then	
                    				cus5e:replaceAllString(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'BDY']/*:Column[@name = 'TYPE_VALUE']),fn-bea:serialize($value))
                    			else
                    				cus5e:replaceAllString(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text),fn-bea:serialize($value))
                    return
                    $bdy 
                    }</Column>
                    <Column name = "senderEmailid">{
                    let $email := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Extension/*:Email/*:FullAddress) , "^\s*$"))
                    				then	
                    					data($Row/*:Column[@name = 'SENDER_NAME'])
                    					else
                     						data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Extension/*:Email/*:FullAddress)
                    		return
                    			$email
                     }</Column>
                </dynamicValues>
                    </TbDetails>
            }
            {
                for $Row in $outputParameters/*:V_NOTIFICATIONLIST/*:Row[data(*:Column[@name = 'CHANNEL_NAME']) = 'MVA PUSH']
                return
                   <TbDetails>
                       <targetType>{ data($Row/*:Column[@name = 'CHANNEL_NAME']) }</targetType>
						<osbTransactionId>{ fn:substring(fn:replace(fn-bea:uuid(),'-',''),3,26) }</osbTransactionId>
                <channelTransactionId>{data($header/*:Correlation/*:ConversationID)}</channelTransactionId>
               <msisdn>
                {
                let $mobile := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:SubscriberNumber) , "^\s*$"))
                				then
                			 data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'REC_MSISDN']/*:Column[@name = 'TYPE_VALUE'])
                			 else
                			 	data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:ContactPoints/*:ContactPoint/*:Telephone/*:SubscriberNumber)
                	return
                		 $mobile
                }
                </msisdn>
                <channelName>{data($header/*:Source/*:System)}</channelName>
                <lang>{data($header/*:Source/*:LanguageCode)}</lang>
                <status>0</status>
                <statusMessage>NEW</statusMessage>
                <created>{ fn:current-date() }</created>
                <lastUpdated>{ fn:current-date() }</lastUpdated>
                <notificationId>{ data($Row/*:Column[@name = 'NOTIFICATION_ID']) }</notificationId>
                <retryCnt> { data($retry/*:rows/*:row[*:cell[1] = 'MVA PUSH']/*:cell[2])}</retryCnt>
                <profileId>{ data($Row/*:Column[@name = 'PROFILE_ID'])}</profileId>
                <priority>{ data($Row/*:Column[@name = 'PRIORITY']) }</priority>
                <format>{ data($Row/*:Column[@name = 'FORMAT'])  }</format>
                <acknowledgementFlag>{ data($Row/*:Column[@name = 'ACKNOWLEDGEMENT_FLAG']) }</acknowledgementFlag>
                <deliveryFlag>{data($Row/*:Column[@name = 'DELIVERY_FLAG']) }</deliveryFlag>
                <dynamicValues>
                    <Column name = "offerName">{
                    
                    let $txt := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:ShortText) , "^\s*$"))
                    				then
                    					cus5e:replaceAllString(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'PUSH_SUBJ']/*:Column[@name = 'TYPE_VALUE']),fn-bea:serialize($value))
                    				else
                    					cus5e:replaceAllString(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:ShortText),fn-bea:serialize($value))
                    		return
                    			$txt
                    
                     }</Column>
                    <Column name = "offerTitle">{
                    
                    let $txt := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:ShortText) , "^\s*$"))
                    				then
                    					cus5e:replaceAllString(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'PUSH_TITLE']/*:Column[@name = 'TYPE_VALUE']),fn-bea:serialize($value))
                    				else
                    					cus5e:replaceAllString(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:ShortText),fn-bea:serialize($value))
                    		return
                    			$txt
                    
                    
                    
                     }</Column>
                    <Column name = "offerDescription">{ 
                    let $desc := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text) , "^\s*$"))
                    				then	
                    				cus5e:replaceAllString(data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'PUSH_TEXT']/*:Column[@name = 'TYPE_VALUE']),fn-bea:serialize($value))
                    				else
                    				cus5e:replaceAllString(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Parts/*:Body/*:Text),fn-bea:serialize($value))
                    		return
                    			$desc	
                    
                    }</Column>
                    <Column name = "menuModuleId">{
                    let $id := if(matches(data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Type[@listName="menuModule"]) , "^\s*$"))
                    			then
                    				data($outputParameters/*:V_NOTIFICATIONTEXT/*:Row[data(*:Column[@name = 'TYPE_ID']) = 'MENU_MOD_ID']/*:Column[@name = 'TYPE_VALUE'])
                    			else
                    				data($createCommunicationVBMRequest/*:CommunicationVBO/*:Roles/*:Sender/*:Type[@listName="menuModule"])
                    				
                    	return
                    		$id
                    			
                     }</Column>
                </dynamicValues>
                    </TbDetails>
            }
        </ns1:CreateNotification>
};

declare variable $createCommunicationVBMRequest as element(ns4:CreateCommunicationVBMRequest) external;
declare variable $outputParameters as element(ns6:OutputParameters) external;
declare variable $header as element(*) external;
declare variable $value as element(*) external;
declare variable $retry as element(dvm:dvm) external;

xf:XQ_CreateNotificationRecordBodyRequest($createCommunicationVBMRequest,
    $outputParameters,$header,$value,$retry)]]></con:xquery>
</con:xqueryEntry>