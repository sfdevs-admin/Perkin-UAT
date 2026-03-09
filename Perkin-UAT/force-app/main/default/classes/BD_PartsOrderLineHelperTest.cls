/**
 * @class BD_PartsOrderLineHelperTest
 * @author Prashant Kumar, Bolt Data Consulting Group
 * @description Test class for class BD_PartsOrderLineHelper
 * 
 * @changelog
 * 23 January 2025 - Prashant Kumar - Created
*/
@isTest
public class BD_PartsOrderLineHelperTest {
    /**
     * @method testUpdateMasterPOLs
     * @author Prashant Kumar, Bolt Data Consulting Group
     * @description Tests method BD_PartsOrderLineHelper.updateMasterPOLs()
     * 
     * @changelog
     * 23 January 2025 - Prashant Kumar - Created
     */
    @isTest(SeeAllData=true)
    public static void testUpdateMasterPOLs(){
        Id shipmentRecordTypeId;
        Id deliveryRecordTypeId;
        Id requestRecordTypeId;
        for(RecordType recordType: [
            SELECT Id, NamespacePrefix, DeveloperName 
            FROM RecordType 
            WHERE SobjectType = 'SVMXC__RMA_Shipment_Order__c'
                AND DeveloperName in ('Shipment', 'Delivery', 'Request')
        ]){
            if(recordType.NamespacePrefix == 'SVMXC'
                && recordType.DeveloperName == 'Shipment'
            ){
                shipmentRecordTypeId = recordType.Id;
            }else if(recordType.NamespacePrefix == null
                && recordType.DeveloperName == 'Delivery'
            ){
                deliveryRecordTypeId = recordType.Id;
            }else if(recordType.NamespacePrefix == null
                && recordType.DeveloperName == 'Request'
            ){
                requestRecordTypeId = recordType.Id;
            }
        }

        SVMXC__RMA_Shipment_Order__c requestPartsOrder = new SVMXC__RMA_Shipment_Order__c();
        requestPartsOrder.RecordTypeId = requestRecordTypeId;
        requestPartsOrder.SMAX_PS_SalesOrg__c = 'TT10';

        insert requestPartsOrder;

        SVMXC__RMA_Shipment_Order__c shipmentPartsOrder = new SVMXC__RMA_Shipment_Order__c();
        shipmentPartsOrder.RecordTypeId = shipmentRecordTypeId;
        shipmentPartsOrder.SVMXC__Master_Order__c = requestPartsOrder.Id;

        SVMXC__RMA_Shipment_Order__c deliveryPartsOrder = new SVMXC__RMA_Shipment_Order__c();
        deliveryPartsOrder.RecordTypeId = deliveryRecordTypeId;
        deliveryPartsOrder.SVMXC__Master_Order__c = requestPartsOrder.Id;

        insert new List<SVMXC__RMA_Shipment_Order__c>{shipmentPartsOrder, deliveryPartsOrder};
        
        Product2 product = SMAX_PS_TestDataFactory.createTestProduct('product_name', 'product_code', '1234');

        SVMXC__RMA_Shipment_Line__c requestPOL = new SVMXC__RMA_Shipment_Line__c();
        requestPOL.SVMXC__RMA_Shipment_Order__c = requestPartsOrder.Id;
        requestPOL.SVMXC__Product__c = product.Id;
        insert requestPOL;

        Test.startTest();
        SVMXC__RMA_Shipment_Line__c shipmentPOL = new SVMXC__RMA_Shipment_Line__c();
        shipmentPOL.SVMXC__RMA_Shipment_Order__c = shipmentPartsOrder.Id;
        shipmentPOL.SVMXC__Product__c = product.Id;
        insert shipmentPOL;

        SVMXC__RMA_Shipment_Line__c updatedRequestPOL = [
            SELECT Id, SVMXC__Line_Status__c
            FROM SVMXC__RMA_Shipment_Line__c
            WHERE Id = :requestPOL.Id
        ];

        System.assertEquals('Received', updatedRequestPOL.SVMXC__Line_Status__c);

        SVMXC__RMA_Shipment_Line__c deliveryPOL = new SVMXC__RMA_Shipment_Line__c();
        deliveryPOL.SVMXC__RMA_Shipment_Order__c = deliveryPartsOrder.Id;
        deliveryPOL.SVMXC__Product__c = product.Id;
        insert deliveryPOL;
        Test.stopTest();
        
        updatedRequestPOL = [
            SELECT Id, SVMXC__Line_Status__c
            FROM SVMXC__RMA_Shipment_Line__c
            WHERE Id = :requestPOL.Id
        ];

        System.assertEquals('Picked', updatedRequestPOL.SVMXC__Line_Status__c);
    }
}