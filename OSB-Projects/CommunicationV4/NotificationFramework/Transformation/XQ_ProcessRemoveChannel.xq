(:: pragma bea:global-element-parameter parameter="$outputParameters" element="ns0:OutputParameters" location="../Schema/GetNotificationDetails_sp.xsd" ::)
(:: pragma  parameter="$channels" type="anyType" ::)
(:: pragma bea:global-element-return element="ns0:OutputParameters" location="../Schema/GetNotificationDetails_sp.xsd" ::)

declare namespace ns0 = "http://xmlns.oracle.com/pcbpel/adapter/db/sp/GetNotificationDetails";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_ProcessChannelOverride/";

declare function xf:XQ_ProcessChannelOverride($outputParameters as element(ns0:OutputParameters),
    $channels as element(*))
    as element(ns0:OutputParameters) {
        <ns0:OutputParameters>
        
            <ns0:V_NOTIFICATIONLIST>
                {
                    for $Row in $outputParameters/ns0:V_NOTIFICATIONLIST/ns0:Row[data(ns0:Column[@name='CHANNEL_NAME']) ne data($channels//name)]
                    return
                        <ns0:Row>{ $Row/@* , $Row/node() }</ns0:Row>
                }
            </ns0:V_NOTIFICATIONLIST>
        
            {
                for $V_NOTIFICATIONTEXT in $outputParameters/ns0:V_NOTIFICATIONTEXT
                return
                    <ns0:V_NOTIFICATIONTEXT>{ $V_NOTIFICATIONTEXT/@* , $V_NOTIFICATIONTEXT/node() }</ns0:V_NOTIFICATIONTEXT>
            }
            {
                for $V_STATICVALUES in $outputParameters/ns0:V_STATICVALUES
                return
                    <ns0:V_STATICVALUES>{ $V_STATICVALUES/@* , $V_STATICVALUES/node() }</ns0:V_STATICVALUES>
            }
        </ns0:OutputParameters>
};

declare variable $outputParameters as element(ns0:OutputParameters) external;
declare variable $channels as element(*) external;

xf:XQ_ProcessChannelOverride($outputParameters,
    $channels)