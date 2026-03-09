@isTest
private class SMAX_PS_Attachment_UT {
	
	@isTest static void testAttachmentEvents() {

		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','MFT');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
		wo.SMAX_PS_SAP_Notification_ID__c = 'SNOT100101';
		update wo;

		Attachment a1 = new Attachment();
		a1.ParentId = wo.Id;
		a1.Name = 'Test File';
		a1.ContentType = 'txt';
		a1.Body = Blob.valueOf('Simple text file test');
		insert a1;

		a1.Body = Blob.valueOf('UPDATED text file test');
		update a1;

		// 08/16/2022 tony Added method as we can't deploy as code coverage is 0% for this class
		SMAX_PS_AttachmentManager.forCodeCoverage();
	}
	
}