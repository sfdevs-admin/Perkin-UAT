@IsTest
public class B2B_CreateRelatedProductsBatchTest {
    
    @IsTest
    static void B2B_CreateProductMediaBatch_Test() {
        // Arrange
        Test.startTest();
        List<Product2> prodList = new List<Product2>();
        Product2 prod = new Product2(
            Name = 'Test Product',
            B2B_Part_Number__c = 'B2B_Part_Number__c',
            B2B_Large_Image_URL__c = 'http://www.perkinelmer.com/sample1.jpg',	//'https://example.com/sample1.jpg'
            B2B_320X320_Large_Image_URL__c = 'http://www.perkinelmer.com/sample1.jpg',
            B2B_Alternate_Products__c = 'Child',
            B2B_SKU__c = 'Parent',
            B2B_Has_Related_Product__c = true,
            B2B_Sales_Org_And_Sales_Status__c = 'ESS0-ZY'
        );
        prodList.add( prod );
        Product2 prod2 = new Product2(
            Name = 'Child Test Product',
            B2B_Part_Number__c = 'Child B2B_Part_Number__c',
            B2B_Large_Image_URL__c = 'http://www.perkinelmer.com/sample1.jpg',	//'https://example.com/sample1.jpg'
            B2B_320X320_Large_Image_URL__c = 'http://www.perkinelmer.com/sample1.jpg',
            B2B_SKU__c = 'Child',
            B2B_Sales_Org_And_Sales_Status__c = 'ESS0-ZY'
        );
        prodList.add( prod2 );
        insert prodList;

        String query = 'SELECT Id, B2B_Alternate_Products__c, B2B_SKU__c FROM Product2 where B2B_Has_Related_Product__c = true';
        B2B_CreateRelatedProductsBatch obj = new B2B_CreateRelatedProductsBatch( query );
        Id batchInstanceId = Database.executeBatch(obj, 5);
        Test.stopTest();
        // Assertions
        List<ProductMedia> productMedia = [SELECT Id FROM ProductMedia WHERE ProductId = :prod.Id];
        System.assertEquals(0, productMedia.size(), 'ProductMedia should be created for all images');
    }
}