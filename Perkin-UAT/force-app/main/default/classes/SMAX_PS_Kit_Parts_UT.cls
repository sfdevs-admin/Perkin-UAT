/**
 * Created by tony on 12/3/21.
 */

@IsTest(SeeAllData=false)
private class SMAX_PS_Kit_Parts_UT {

    @IsTest
    static void testExplodeWorkDetailKitParts() {

        // create Products and Kit Part Products
        Product2 product1 = SMAX_PS_TestDataFactory.createTestProduct('Prod1', 'PC1', 'PL12', 'Parts');
        Product2 product2 = SMAX_PS_TestDataFactory.createTestProduct('Prod2', 'PC2', 'PL12', 'Parts');
        Product2 kitPartProd1 = SMAX_PS_TestDataFactory.createTestProduct('KitPartProd1', 'KP1', 'PL12', 'Parts');
        Product2 KitPartProd2 = SMAX_PS_TestDataFactory.createTestProduct('KitPartProd2', 'KP2', 'PL12', 'Parts');

        // create Kit Parts
        List<SVMX_PS_Kit_Part__c> kitParts = new List<SVMX_PS_Kit_Part__c>();
        SVMX_PS_Kit_Part__c kitPart1 = new SVMX_PS_Kit_Part__c(
            SVMX_PS_Part__c = kitPartProd1.Id, 
            SVMX_PS_Kit__c = product1.Id, 
            SVMX_PS_Qty__c = 5, 
            SVMX_PS_Delivering_Plant__c = 'FI11'
        );
        kitParts.add(kitPart1);

        SVMX_PS_Kit_Part__c kitPart2 = new SVMX_PS_Kit_Part__c(
            SVMX_PS_Part__c = KitPartProd2.Id, 
            SVMX_PS_Kit__c = product1.Id, 
            SVMX_PS_Qty__c = 3, 
            SVMX_PS_Delivering_Plant__c = 'FI11'
        );
        kitParts.add(kitPart2);
        insert kitParts;

        // create Product Sales
        List<SMAX_PS_ProductSales__c> productSales = new List<SMAX_PS_ProductSales__c>();
        SMAX_PS_ProductSales__c productSales1 = new SMAX_PS_ProductSales__c(
            SMAX_PS_Product__c = product1.Id,
            SMAX_PS_SalesOrg__c = 'US10', 
            SMAX_PS_DeliveringPlant__c = 'FI11'
        );
        productSales.add(productSales1);

        SMAX_PS_ProductSales__c productSales2 = new SMAX_PS_ProductSales__c(
            SMAX_PS_Product__c = product2.Id, 
            SMAX_PS_SalesOrg__c = 'US10', 
            SMAX_PS_DeliveringPlant__c = 'FI11'
        );
        productSales.add(productSales2);
        insert productSales;

        // create an Account
        Account account = SMAX_PS_TestDataFactory.createTestAccount('Acct1', 'TESTX000000001','US');

        // create a Contact
        Contact contact = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', account, 'TESTX00000001A');

        // create a Location
        SVMXC__Site__c location = SMAX_PS_TestDataFactory.createTestLocation(account,'TestLocationSite', '121212','LOC123');
        location.SMAX_PS_MaintenancePlant__c = 'US10';
        update location;

        // create an Installed Product
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456', account, location,'5545333', product1);

        // create User
        User user = SMAX_PS_TestDataFactory.createTestUser('TST1');

        // Create Technician
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam', user, 'TestTech', 'US10', 'LOC123');
        tech.SVMXC__Inventory_Location__c = location.Id;
        update tech;

        // Create Remote Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createRemoteWO(ip, contact);
        wo.SMAX_PS_SalesOrg__c = 'US10';
        wo.SVMXC__Order_Type__c = 'Repair';
        wo.SVMXC__Group_Member__c = tech.Id;
        update wo;


        Test.startTest();

        // create Work Detail Lines - Usage Consumption, Parts
        
        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
        SVMXC__Service_Order_Line__c workDetailLine1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Type__c = 'Parts',
                SVMXC__Product__c = product1.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
		insert workDetailLine1;
        
        SMAX_PS_Kit_Parts.explodeWorkDetailKitParts(new List<SVMXC__Service_Order_Line__c>{workDetailLine1}, null);

        Test.stopTest();

        // Validate two new Kit Part Work Detail Lines were Created and the old Parent Part Work Detail Line was deleted
        /*List<SVMXC__Service_Order_Line__c> testParentKitPartWDLs = [
                SELECT Id, Name, SVMXC__Product__r.Name
                FROM SVMXC__Service_Order_Line__c
                WHERE SVMXC__Product__r.Name = 'Prod%'
        ];
        System.debug('testParentKitPartWDLs: ' + testParentKitPartWDLs);
        System.assertEquals(0, testParentKitPartWDLs.size(), 'There should not be any Parent Kit Part Lines');

        List<SVMXC__Service_Order_Line__c> testKitPartWDLs = [
                SELECT Id, Name, SVMXC__Product__r.Name
                FROM SVMXC__Service_Order_Line__c
                WHERE SVMXC__Product__r.Name LIKE 'KitPartProd%'
        ];
        System.debug('testKitPartWDLs: ' + testKitPartWDLs);
        System.assertEquals(2, testKitPartWDLs.size(), 'There should 2 Kit Part Lines created');*/
    }

    @IsTest(SeeAllData=true) // Required to create Parts Order
    static void testExplodePartsOrderLineKitParts() {

        // create Products and Kit Part Products
        Product2 product1 = SMAX_PS_TestDataFactory.createTestProduct('Prod1', 'PC1', 'PL12', 'Parts');
        Product2 product2 = SMAX_PS_TestDataFactory.createTestProduct('Prod2', 'PC2', 'PL12', 'Parts');
        Product2 kitPartProd1 = SMAX_PS_TestDataFactory.createTestProduct('KitPartProd1', 'KP1', 'PL12', 'Parts');
        Product2 KitPartProd2 = SMAX_PS_TestDataFactory.createTestProduct('KitPartProd2', 'KP2', 'PL12', 'Parts');

        // create Kit Parts
        List<SVMX_PS_Kit_Part__c> kitParts = new List<SVMX_PS_Kit_Part__c>();
        SVMX_PS_Kit_Part__c kitPart1 = new SVMX_PS_Kit_Part__c(
                SVMX_PS_Part__c = kitPartProd1.Id, SVMX_PS_Kit__c = product1.Id, SVMX_PS_Qty__c = 5, SVMX_PS_Delivering_Plant__c = 'FI11'
        );
        kitParts.add(kitPart1);

        SVMX_PS_Kit_Part__c kitPart2 = new SVMX_PS_Kit_Part__c(
                SVMX_PS_Part__c = KitPartProd2.Id, SVMX_PS_Kit__c = product1.Id, SVMX_PS_Qty__c = 3, SVMX_PS_Delivering_Plant__c = 'FI11'
        );
        kitParts.add(kitPart2);
        insert kitParts;

        // create Product Sales
        List<SMAX_PS_ProductSales__c> productSales = new List<SMAX_PS_ProductSales__c>();
        SMAX_PS_ProductSales__c productSales1 = new SMAX_PS_ProductSales__c(
                SMAX_PS_Product__c = product1.Id, SMAX_PS_SalesOrg__c = 'US10', SMAX_PS_DeliveringPlant__c = 'FI11'
        );
        productSales.add(productSales1);

        SMAX_PS_ProductSales__c productSales2 = new SMAX_PS_ProductSales__c(
                SMAX_PS_Product__c = product2.Id, SMAX_PS_SalesOrg__c = 'US10', SMAX_PS_DeliveringPlant__c = 'FI11'
        );
        productSales.add(productSales2);
        insert productSales;

        // create an Account
        Account account = SMAX_PS_TestDataFactory.createTestAccount('Acct1', 'TESTX000000001','US');

        // create a Contact
        Contact contact = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', account, 'TESTX00000001A');

        // create a Location
        SVMXC__Site__c location = SMAX_PS_TestDataFactory.createTestLocation(account,'TestLocationSite', '121212','LOC123');
        location.SMAX_PS_MaintenancePlant__c = 'US10';
        update location;

        // create an Installed Product
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456', account, location,'5545333', product1);

        // create User
        User user = SMAX_PS_TestDataFactory.createTestUser('TST1');

        // Create Technician
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam', user, 'TestTech', 'US10', 'LOC123');
        tech.SVMXC__Inventory_Location__c = location.Id;
        update tech;

        // Create Remote Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createRemoteWO(ip, contact);
        wo.SMAX_PS_SalesOrg__c = 'US10';
        wo.SVMXC__Order_Type__c = 'Repair';
        wo.SVMXC__Group_Member__c = tech.Id;
        update wo;

        // Create Parts Order
        RecordType poReqRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'Request');
        SVMXC__RMA_Shipment_Order__c partsOrder = SMAX_PS_TestDataFactory.createTestPartsOrder(poReqRT, account, contact, location, tech, wo, null, null);
        System.debug('partsOrder: ' + partsOrder);

        Test.startTest();

        // create Parts Order Lines - Usage Consumption, Parts
        RecordType rmaRecType = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Line__c', 'RMA');
        SVMXC__RMA_Shipment_Line__c partsOrderLine1 = SMAX_PS_TestDataFactory.createTestPartsOrderLine(rmaRecType, location, wo, partsOrder, null);
        partsOrderLine1.SVMXC__Product__c = product1.Id;
        update partsOrderLine1;

        Test.stopTest();

        // Validate two new Kit Part Parts Order Lines were Created and the old Parent Part Parts Order Line was deleted
        /*List<SVMXC__RMA_Shipment_Line__c> testParentKitPartPOLs = [
                SELECT Id, Name, SVMXC__Product__r.Name
                FROM SVMXC__RMA_Shipment_Line__c
                WHERE SVMXC__Product__r.Name = 'Prod%'
        ];
        System.debug('testParentKitPartPOLs: ' + testParentKitPartPOLs);
        System.assertEquals(0, testParentKitPartPOLs.size(), 'There should not be any Parent Kit Part Lines');

        List<SVMXC__RMA_Shipment_Line__c> testKitPartPOLs = [
                SELECT Id, Name, SVMXC__Product__r.Name
                FROM SVMXC__RMA_Shipment_Line__c
                WHERE SVMXC__Product__r.Name LIKE 'KitPartProd%'
        ];
        System.debug('testKitPartPOLs: ' + testKitPartPOLs);
        System.assertEquals(2, testKitPartPOLs.size(), 'There should 2 Kit Part Lines created');*/
    }
}