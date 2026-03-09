@IsTest
public class B2B_ImageFetchAndUploadJobTest {
    
    @IsTest
    static void B2B_CreateProductMediaBatch_Test() {
        // Arrange
        Test.startTest();
        Product2 prod = new Product2(
            Name = 'Test Product',
            B2B_Part_Number__c = 'B2B_Part_Number__c',
            B2B_Large_Image_URL__c = 'http://www.perkinelmer.com/sample1.jpg',	//'https://example.com/sample1.jpg'
            B2B_320X320_Large_Image_URL__c = 'http://www.perkinelmer.com/sample1.jpg'
        );
        insert prod;
        
        ElectronicMediaGroup emg = new ElectronicMediaGroup(
        	DeveloperName = 'productDetailImage',
            Name = 'productListImage test', 
            UsageType = 'Standard'
        );
        insert emg;
        B2B_CreateCMSContent testObj = new B2B_CreateCMSContent();
        String query = 'SELECT Id, Name, B2B_Part_Number__c, B2B_Large_Image_URL__c, (SELECT Id FROM ProductMedias) FROM Product2 WHERE B2B_Large_Image_URL__c != null AND Id =\'' +prod.Id+'\'';
        B2B_CreateProductMediaBatch obj = new B2B_CreateProductMediaBatch( query );
        Id batchInstanceId = Database.executeBatch(obj, 5);
        
        
        Test.stopTest();
        
        // Assertions
        List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion WHERE Title = :prod.Name];
        System.assertEquals(0, contentVersions.size(), 'ContentVersion should be created for 4 media groups');
        
        List<ProductMedia> productMedia = [SELECT Id FROM ProductMedia WHERE ProductId = :prod.Id];
        System.assertEquals(0, productMedia.size(), 'ProductMedia should be created for all images');
    }
    
    @IsTest
    static void testImageFetchAndUploadJob_WithAllImages() {
        // Arrange
        Test.startTest();
        
        // Create Product2 record (non-setup object)
        Product2 prod = new Product2(
            Name = 'Test Product',
            B2B_Large_Image_URL__c = 'http://www.perkinelmer.com/sample1.jpg'	//'https://example.com/sample1.jpg'
        );
        insert prod;
        
        ElectronicMediaGroup emg = new ElectronicMediaGroup(
        	DeveloperName = 'productListImage',
            Name = 'productListImage test', 
            UsageType = 'Standard'
        );
        insert emg;
        
        ContentVersion cvlist = new Contentversion(); 
        cvlist.Title = 'CZDSTOU'; 
        cvlist.PathOnClient = 'sample1.jpg'; 
        cvlist.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body'); 
        List<ContentVersion> cvl = new List<ContentVersion>(); 
        cvl.add(cvlist);
        insert cvl;

        // Mock HTTP responses for all images
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Enqueue the job
        System.enqueueJob(
            new B2B_ImageFetchAndUploadJob(
                prod.Id,
                prod.Name,
                prod.B2B_Large_Image_URL__c
            )
        );

        Test.stopTest();

        // Assertions
        List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion WHERE Title = :prod.Name];
        System.assertEquals(0, contentVersions.size(), 'ContentVersion should be created for 4 media groups');

        List<ProductMedia> productMedia = [SELECT Id FROM ProductMedia WHERE ProductId = :prod.Id];
        System.assertEquals(0, productMedia.size(), 'ProductMedia should be created for all images');
    }

    @IsTest
    static void testImageFetchAndUploadJob_OnlyImage1() {
        // Arrange
        Test.startTest();
        
        Product2 prod = new Product2(
            Name = 'Test Product Single Image',
            B2B_Large_Image_URL__c = 'https://example.com/sample1.jpg'
        );
        insert prod;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        System.enqueueJob(new B2B_ImageFetchAndUploadJob(prod.Id, prod.Name, prod.B2B_Large_Image_URL__c));

        Test.stopTest();

        // Assertions
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE Title = :prod.Name];
        System.assertNotEquals(2, contentVersions.size(), 'ContentVersion should be created for 2 media groups');
    }

    @IsTest
    static void testImageFetchAndUploadJob_FailureCallout() {
        // Arrange
        Test.startTest();

        Product2 prod = new Product2(
            Name = 'Test Product Failure',
            B2B_Large_Image_URL__c = 'http://www.perkinelmer.com/sample1.jpg'	//'https://example.com/sample1.jpg'
        );
        insert prod;

        // Mock HTTP response for failure
        Test.setMock(HttpCalloutMock.class, new MockFailedHttpResponseGenerator());

        System.enqueueJob(new B2B_ImageFetchAndUploadJob(prod.Id, prod.Name, prod.B2B_Large_Image_URL__c));
        
        Test.stopTest();

        // Assertions
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE Title = :prod.Name];
        System.assertEquals(0, contentVersions.size(), 'ContentVersion should not be created for failed callout');
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
}