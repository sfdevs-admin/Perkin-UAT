/**
 * Created by tony on 6/16/22.
 */

@isTest
private class SMAX_PS_ContentVersion_UT {

    @isTest static void testFileAttachmentEvents() {

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','MFT');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SMAX_PS_SAP_Notification_ID__c = 'SNOT100101';
        update wo;

        SVMXC__Service_Order__c testWo = [SELECT Id, Name FROM SVMXC__Service_Order__c LIMIT 1];
        System.assertNotEquals(null, testWo, 'Work Order just created should be found');

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test-File-' + testWo.Name + '-Ending-Stuff.TXT';
        cv.PathOnClient = 'test';
        cv.VersionData = EncodingUtil.base64Decode(EncodingUtil.urlEncode('Simple text file test','UTF-8'));
        insert cv;

        // Query cv to get contentDocumentId ????
        ContentVersion testCv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        System.debug('testCv.contentDocumentId: ' + testCv.ContentDocumentId);

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = testCv.ContentDocumentId;
        cdl.LinkedEntityId = testWo.Id;
        //cdl.ShareType = 'I';

        insert cdl;

        cv.VersionData = EncodingUtil.base64Decode(EncodingUtil.urlEncode('UPDATED text file test','UTF-8'));
        update cv;

    }
    
    @isTest
    static void testTruncateLongFileName() {
       
        ContentVersion testCV = new ContentVersion();
        testCV.Title = 'tes' + 't'.repeat(150); 
        testCV.PathOnClient = 'test';
        testCV.VersionData = EncodingUtil.base64Decode(EncodingUtil.urlEncode('Simple text file test','UTF-8'));

        Test.startTest();
        insert testCV;
        Test.stopTest();
        
        Assert.areEqual(153, testCV.Title.length());
        
        ContentVersion updatedCV = [Select Title
                                   from ContentVersion
                                   limit 1];
        
        Assert.areEqual(90, updatedCV.Title.length());
    }
    
    @isTest
    static void testTruncateShortFileName() {
       
        ContentVersion testCV = new ContentVersion();
        testCV.Title = 'tes' + 't'.repeat(50); 
        testCV.PathOnClient = 'test';
        testCV.VersionData = EncodingUtil.base64Decode(EncodingUtil.urlEncode('Simple text file test','UTF-8'));

        Test.startTest();
        insert testCV;
        Test.stopTest();
        
        Assert.areEqual(53, testCV.Title.length());
        
        ContentVersion updatedCV = [Select Title
                                   from ContentVersion
                                   limit 1];
        
        Assert.areEqual(53, updatedCV.Title.length());
    }
    
    @isTest
    static void testTruncateNullFileName() {
       
        ContentVersion testCV = new ContentVersion();
        testCV.Title = null; 
        testCV.PathOnClient = 'test';
        testCV.VersionData = EncodingUtil.base64Decode(EncodingUtil.urlEncode('Simple text file test','UTF-8'));

        Test.startTest();
        insert testCV;
        Test.stopTest();
        
        Assert.areEqual(null, testCV.Title);
        
    }
    
    @isTest
    static void testUpdatingFileName() {
        
        ContentVersion testCV = new ContentVersion();
        testCV.Title = null; 
        testCV.PathOnClient = 'test';
        testCV.VersionData = EncodingUtil.base64Decode(EncodingUtil.urlEncode('Simple text file test','UTF-8'));
		insert testCV;
        
        testCV.Title = 'tes' + 't'.repeat(100); 
        
        Test.startTest();
        update testCV;
        Test.stopTest();
        
        ContentVersion updatedCV = [Select Title
                                   from ContentVersion
                                   limit 1];
        
        Assert.areEqual(90, updatedCV.Title.length());
    }
}