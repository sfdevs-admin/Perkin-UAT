@IsTest
public class B2B_LinkProductsWithResourcesBatchTest {
    
    @IsTest
    static void B2B_LinkProductsWithResourcesBatch_Test() {
        Test.startTest();
        List<Product2> prodList = new List<Product2>();
        List<B2B_Product_Resources__c> resList = new List<B2B_Product_Resources__c>();
        Product2 prod = new Product2(
            Name = 'Test Product',
            B2B_Product_Resources_PDFs__c = '46600014',
            B2B_Product_Resources_Videos__c = '46600015',
            B2B_Links__c = '46600015',
            B2B_Product_Resources_Links__c = '46600015',
            B2B_Default_image__c = '46600015',
            B2B_Videos__c = '46600015',
            B2B_Sales_Org_And_Sales_Status__c = 'ESS0-ZY',
            B2B_SKU__c = 'Test'
        );
        prodList.add( prod );
        insert prodList;

        B2B_Product_Resources__c res = new B2B_Product_Resources__c(
            Link_ID__c = '46600014',
            Active__c = true
        );
        resList.add( res );
         B2B_Product_Resources__c res1 = new B2B_Product_Resources__c(
            Link_ID__c = '46600015',
            Active__c = true
        );
        resList.add( res1 );
        insert resList;

        String query = 'SELECT B2B_Links__c, B2B_Product_Resources_Links__c, B2B_Default_image__c, B2B_Product_Resources_PDFs__c, B2B_Product_Resources_Videos__c, B2B_Videos__c FROM product2 where Is_B2B_Product__c = true';
        B2B_LinkProductsWithResourcesBatch obj = new B2B_LinkProductsWithResourcesBatch( query );
        obj.createCustomExceptionRecord('test error msg');
        Id batchInstanceId = Database.executeBatch(obj, 5);
        Test.stopTest();
        List<B2B_Product_Related_Resources__c> productResources = [SELECT Id, Product__c FROM B2B_Product_Related_Resources__c WHERE Product__c = :prod.Id];
        System.assertNotEquals(0, productResources.size());
    }
}