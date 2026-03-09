/**
 * @description       : 
 * @author            : Abhishek
 * @group             : 
 * @last modified on  : 01-08-2024
 * @last modified by  : Abhishek
**/
@isTest
private with sharing class B2BCartUploadControllerTest {
    
    @TestSetup
    static void setupTestData() 
    {
        B2B_TestDataFactory.initialStorefrontSetup();
    }

    @isTest
    static void getProductIdFromSKUTest() {
        WebStore store = [SELECT Id FROM WebStore limit 1];
        Account acc = [SELECT Id FROM Account limit 1];
        List<String> skuList = new List<String>();
        for(Product2 prod : [SELECT Id,StockKeepingUnit FROM Product2]){
            skuList.add(prod.StockKeepingUnit);
        }
        String effectiveAccountId = ACC.Id ;
        String webStoreId = store.Id ;
        Test.startTest();
        B2BCartUploadController.getProductIdFromSKU(skuList, effectiveAccountId, webStoreId);
        B2BCartUploadController.getProductIdFromSKU(null, null, null);
        B2BCheckProductEntitlement.getProductPrices(webStoreId, effectiveAccountId, skuList);
        Test.stopTest();
    }

}