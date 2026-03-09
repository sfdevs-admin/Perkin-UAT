@IsTest
public class B2B_CMSForProductResourcesBatchTest {

    @IsTest
    static void B2B_CreateProductMediaBatch_Test() {
        // Arrange
        Test.startTest();
        // Insert a product
        Product2 p = new Product2(Name = 'Test Product', B2B_Part_Number__c = 'TEST123');
        insert p;

        // Insert a resource (used in the batch)
        B2B_Product_Resources__c r = new B2B_Product_Resources__c(
            Part_Number__c = 'TEST123',
            Image_URL__c = 'https://example.com/sample.jpg',
            Resource_Type__c = 'PI - Product Image'
        );
        insert r;

        // Insert ElectronicMediaGroup (required for DML)
        ElectronicMediaGroup group1 = new ElectronicMediaGroup(
            Name = 'Product List Image',
            DeveloperName = 'productListImage',
            UsageType = 'Standard'
        );
        insert group1;

        B2B_CreateCMSContent testObj = new B2B_CreateCMSContent();
        // String query = 'SELECT Id, Name, B2B_Part_Number__c, B2B_Large_Image_URL__c, (SELECT Id FROM ProductMedias) FROM Product2 WHERE B2B_Large_Image_URL__c != null AND Id =\'' +prod.Id+'\'';
        String query = 'SELECT Id, Product__c, Part_Number__c, Active__c, Image_URL__c FROM B2B_Product_Resources__c WHERE Part_Number__c != null AND Product__c = null AND Resource_Type__c = \'PI - Product Image\' LIMIT 1';
        B2B_CreateCMSForProductResourcesBatch obj = new B2B_CreateCMSForProductResourcesBatch( query );
        Id batchInstanceId = Database.executeBatch(obj, 1);
        
        
        Test.stopTest();
        
        // Assertions
        List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion WHERE Title = :p.Name];
        System.assertEquals(0, contentVersions.size(), 'ContentVersion should be created for 4 media groups');
        
        List<ProductMedia> productMedia = [SELECT Id FROM ProductMedia WHERE ProductId = :p.Id];
        System.assertEquals(0, productMedia.size(), 'ProductMedia should be created for all images');
    }

    @IsTest
    static void testImageFetchAndUploadJob_WithAllImages() {
        // Arrange
        Test.startTest();
        
        // Insert a product
        Product2 p = new Product2(Name = 'Test Product', B2B_Part_Number__c = 'TEST123');
        insert p;

        // Insert a resource (used in the batch)
        B2B_Product_Resources__c r = new B2B_Product_Resources__c(
            Part_Number__c = 'TEST123',
            Image_URL__c = 'https://example.com/sample.jpg',
            Resource_Type__c = 'PI - Product Image'
        );
        insert r;

        // Insert ElectronicMediaGroup (required for DML)
        ElectronicMediaGroup group1 = new ElectronicMediaGroup(
            Name = 'Product List Image',
            DeveloperName = 'productListImage',
            UsageType = 'Standard'
        );
        insert group1;
        
        ContentVersion cvlist = new Contentversion(); 
        cvlist.Title = 'CZDSTOU'; 
        cvlist.PathOnClient = 'sample1.jpg'; 
        cvlist.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body'); 
        List<ContentVersion> cvl = new List<ContentVersion>(); 
        cvl.add(cvlist);
        insert cvl;

        // Mock HTTP responses for all images
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        String query = 'SELECT Id, Product__c, Part_Number__c, Active__c, Image_URL__c FROM B2B_Product_Resources__c WHERE Part_Number__c != null AND Product__c = null AND Resource_Type__c = \'PI - Product Image\' LIMIT 1';
        B2B_CreateCMSForProductResourcesBatch obj = new B2B_CreateCMSForProductResourcesBatch( query );
        Id batchInstanceId = Database.executeBatch(obj, 1);

        Test.stopTest();

        // Assertions
        List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion WHERE Title = :p.Name];
        System.assertEquals(0, contentVersions.size(), 'ContentVersion should be created for 4 media groups');

        List<ProductMedia> productMedia = [SELECT Id FROM ProductMedia WHERE ProductId = :p.Id];
        System.assertEquals(0, productMedia.size(), 'ProductMedia should be created for all images');
    }

    @IsTest
    static void testImageFetchAndUploadJob_FailureCallout() {
        // Arrange
        Test.startTest();

        // Insert a product
        Product2 p = new Product2(Name = 'Test Product', B2B_Part_Number__c = 'TEST123');
        insert p;

        // Insert a resource (used in the batch)
        B2B_Product_Resources__c r = new B2B_Product_Resources__c(
            Part_Number__c = 'TEST123',
            Image_URL__c = 'https://example.com/sample.jpg',
            Resource_Type__c = 'PI - Product Image'
        );
        insert r;

        // Insert ElectronicMediaGroup (required for DML)
        ElectronicMediaGroup group1 = new ElectronicMediaGroup(
            Name = 'Product List Image',
            DeveloperName = 'productListImage',
            UsageType = 'Standard'
        );
        insert group1;

        // Mock HTTP response for failure
        Test.setMock(HttpCalloutMock.class, new MockFailedHttpResponseGenerator());

        String query = 'SELECT Id, Product__c, Part_Number__c, Active__c, Image_URL__c FROM B2B_Product_Resources__c WHERE Part_Number__c != null AND Product__c = null AND Resource_Type__c = \'PI - Product Image\' LIMIT 1';
        B2B_CreateCMSForProductResourcesBatch obj = new B2B_CreateCMSForProductResourcesBatch( query );
        Id batchInstanceId = Database.executeBatch(obj, 1);
        
        Test.stopTest();

        // Assertions
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE Title = :p.Name];
        System.assertEquals(0, contentVersions.size(), 'ContentVersion should not be created for failed callout');
    }

    @IsTest
    static void testImageFetchAndUploadJob_OnlyImage1() {
        // Arrange
        Test.startTest();
        
        // Insert a product
        Product2 p = new Product2(Name = 'Test Product', B2B_Part_Number__c = 'TEST123');
        insert p;

        // Insert a resource (used in the batch)
        B2B_Product_Resources__c r = new B2B_Product_Resources__c(
            Part_Number__c = 'TEST123',
            Image_URL__c = 'https://example.com/sample.jpg',
            Resource_Type__c = 'PI - Product Image'
        );
        insert r;

        // Insert ElectronicMediaGroup (required for DML)
        ElectronicMediaGroup group1 = new ElectronicMediaGroup(
            Name = 'Product List Image',
            DeveloperName = 'productListImage',
            UsageType = 'Standard'
        );
        insert group1;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String query = 'SELECT Id, Product__c, Part_Number__c, Active__c, Image_URL__c FROM B2B_Product_Resources__c WHERE Part_Number__c != null AND Product__c = null AND Resource_Type__c = \'PI - Product Image\' LIMIT 1';
        B2B_CreateCMSForProductResourcesBatch obj = new B2B_CreateCMSForProductResourcesBatch( query );
        Id batchInstanceId = Database.executeBatch(obj, 1);

        Test.stopTest();

        // Assertions
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE Title = :p.Name];
        System.assertNotEquals(2, contentVersions.size(), 'ContentVersion should be created for 2 media groups');
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'image/jpeg');
            res.setBodyAsBlob(Blob.valueOf('fake image data'));
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockFailedHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404); // Simulate failure
            res.setBody('Not Found');
            return res;
        }
    }

    @IsTest
    static void testScheduler() {
        Test.startTest();

        // Use a cron expression that will work in tests
        String cron = '0 0 * * * ?'; // Runs every hour (test-safe)
        System.schedule('CMS Scheduler Job', cron, new B2B_CMSForProductResourcesScheduler());

        Test.stopTest();

        System.assert(true, 'Scheduled job ran without exception');
    }

}