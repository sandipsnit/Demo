<?xml version="1.0" encoding="UTF-8"?>
<con:xqueryEntry xmlns:con="http://www.bea.com/wli/sb/resources/config">
    <con:xquery><![CDATA[(:: pragma bea:global-element-parameter parameter="$tbMvaPushDetailsCollection" element="ns5:TbMvaPushDetailsCollection" location="../Schema/GetMVAPushRecord_table.xsd" ::)
(:: pragma bea:global-element-return element="ns4:SyncCustomerMarketingProductVBMRequest" location="../../../VFQA_CSM_Common/Schema/VBO/CustomerMarketingProduct/CustomerMarketingProductVBM.xsd" ::)

declare namespace ns2 = "urn:un:unece:uncefact:documentation:standard:CoreComponentType:2";
declare namespace ns1 = "http://group.vodafone.com/schema/extension/vbo/customer/customer-marketing-product/v1";
declare namespace ns4 = "http://group.vodafone.com/schema/vbm/customer/customer-marketing-product/v1";
declare namespace ns3 = "http://group.vodafone.com/schema/common/v1";
declare namespace ns0 = "http://group.vodafone.com/schema/vbo/customer/customer-marketing-product/v1";
declare namespace ns5 = "http://xmlns.oracle.com/pcbpel/adapter/db/top/GetMVAPushRecord";
declare namespace xf = "http://tempuri.org/CommunicationV4/NotificationFramework/Transformation/XQ_GetMVAPushRecord_To_SyncCustomerMarketingProduct/";

declare function xf:XQ_GetMVAPushRecord_To_SyncCustomerMarketingProduct($tbMvaPushDetailsCollection as element(ns5:TbMvaPushDetailsCollection))
    as element(ns4:SyncCustomerMarketingProductVBMRequest) {
        <ns4:SyncCustomerMarketingProductVBMRequest>
            <ns4:CustomerMarketingProductVBO>
                <ns3:IDs>
                    <ns3:ID schemeName = "ID"
                            schemeAgencyName = "Vodafone">{ data($tbMvaPushDetailsCollection/ns5:TbMvaPushDetails/ns5:osbTransactionId) }</ns3:ID>
                </ns3:IDs>
                
                        <ns3:Name languageID = "{data($tbMvaPushDetailsCollection/ns5:TbMvaPushDetails/ns5:lang)}">{ data($tbMvaPushDetailsCollection/ns5:TbMvaPushDetails/ns5:offerName) }</ns3:Name>
                
               
                        <ns3:Desc>{ data($tbMvaPushDetailsCollection/ns5:TbMvaPushDetails/ns5:offerDescription) }</ns3:Desc>
                
                <ns3:Created>{ data($tbMvaPushDetailsCollection/ns5:TbMvaPushDetails/ns5:created) }</ns3:Created>
                <ns3:ValidityPeriod>
                    <ns3:FromDate>
                        <ns2:DateString>{ data($tbMvaPushDetailsCollection/ns5:TbMvaPushDetails/ns5:scheduled) }</ns2:DateString>
                    </ns3:FromDate>
                </ns3:ValidityPeriod>
                <ns0:Details>
                   
                            <ns0:DisplayName>{ data($tbMvaPushDetailsCollection/ns5:TbMvaPushDetails/ns5:offerTitle) }</ns0:DisplayName>
                    
                </ns0:Details>
                <ns0:Roles>
                    <ns0:Subscriber>
                        <ns3:IDs>
                            <ns3:ID schemeName = "MSISDN"
                                    schemeAgencyName = "Vodafone">{ data($tbMvaPushDetailsCollection/ns5:TbMvaPushDetails/ns5:msisdn) }</ns3:ID>
                        </ns3:IDs>
                    </ns0:Subscriber>
                </ns0:Roles>
                <ns0:Parts>
                    <ns0:CustomerInteractions>
                        <ns0:CustomerInteraction>
                            <ns3:Type listAgencyName = "Vodafone"
                                      listName = "Menu Module ID">{ data($tbMvaPushDetailsCollection/ns5:TbMvaPushDetails/ns5:menuModuleId) }</ns3:Type>
                            <ns3:Categories>
                                <ns3:Category listAgencyName = "Vodafone"
                                              listName = "Message Type">INFORMATIVE</ns3:Category>
                            </ns3:Categories>
                        </ns0:CustomerInteraction>
                    </ns0:CustomerInteractions>
                </ns0:Parts>
            </ns4:CustomerMarketingProductVBO>
        </ns4:SyncCustomerMarketingProductVBMRequest>
};

declare variable $tbMvaPushDetailsCollection as element(ns5:TbMvaPushDetailsCollection) external;

xf:XQ_GetMVAPushRecord_To_SyncCustomerMarketingProduct($tbMvaPushDetailsCollection)]]></con:xquery>
    <con:dependency location="../Schema/GetMVAPushRecord_table.xsd">
        <con:schema ref="CommunicationV4/NotificationFramework/Schema/GetMVAPushRecord_table"/>
    </con:dependency>
    <con:dependency location="../../../VFQA_CSM_Common/Schema/VBO/CustomerMarketingProduct/CustomerMarketingProductVBM.xsd">
        <con:schema ref="VFQA_CSM_Common/Schema/VBO/CustomerMarketingProduct/CustomerMarketingProductVBM"/>
    </con:dependency>
</con:xqueryEntry>