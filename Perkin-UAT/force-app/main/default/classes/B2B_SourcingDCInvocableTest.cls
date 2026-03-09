/**
 * @description       : 
 * @author            : Suhail Ahmed T 
 * @group             : 
 * @last modified on  : 02-15-2026
 * @last modified by  : Suhail Ahmed T 
**/
@isTest
public class B2B_SourcingDCInvocableTest {

    @testSetup
    static void setupTestData() {
        // Create Products
        Product2 prod1 = B2B_TestDataFactory.createProduct('Test Product 1', true);
        Product2 prod2 = B2B_TestDataFactory.createProduct('Test Product 2', true);

        // Create B2B_Product_Shipping__c records for both DCs
        B2B_TestDataFactory.createProductShipping(prod1.Id, true);
        B2B_TestDataFactory.createProductShipping(prod2.Id, true);

        B2B_Product_Shipping__c sourcingDcUpdate  =[Select Id, B2B_Sourcing_DC__c from B2B_Product_Shipping__c limit 1];
        sourcingDcUpdate.B2B_Sourcing_DC__c = 'CN11;CNS1';
        update sourcingDcUpdate;  
    }

    @isTest
    static void testGetProductShippingList() {
        // Query product IDs
        List<Id> productIds = new List<Id>();
        for(Product2 p : [SELECT Id FROM Product2 WHERE Name IN ('Test Product 1', 'Test Product 2')]) {
            productIds.add(p.Id);
        }

        B2B_SourcingDCInvocable.Request req = new B2B_SourcingDCInvocable.Request();
        req.sourcingDC = 'CN11;CNS1';
        req.productIdList = new List<String>{
            String.valueOf(productIds[0]),
            String.valueOf(productIds[1])
        };

        Test.startTest();
        List<B2B_SourcingDCInvocable.Response> responses = B2B_SourcingDCInvocable.getProductShippingList(new List<B2B_SourcingDCInvocable.Request>{req});
        Test.stopTest();
        System.assertEquals(1, responses.size(), 'Should return one response');
    }
}