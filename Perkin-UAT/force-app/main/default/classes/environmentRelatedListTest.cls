@isTest
private class environmentRelatedListTest {

    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        // Create a test Case associated with the Account
        Case testCase = new Case(
            Subject = 'Test Case',
            AccountId = testAccount.Id
        );
        insert testCase;

        // Create related INFEnvironmentalData__c records associated with the Account
        INFEnvironmentalData__c envData1 = new INFEnvironmentalData__c(
            Name = 'Environmental Data 1',
            Account__c = testAccount.Id
        );
        INFEnvironmentalData__c envData2 = new INFEnvironmentalData__c(
            Name = 'Environmental Data 2',
            Account__c = testAccount.Id
        );
        insert new List<INFEnvironmentalData__c>{ envData1, envData2 };
    }

    @isTest
    static void testGetEnvrsWithAccountId() {
        // Retrieve the test Case created in the setup
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Create a StandardController instance for the Case
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);

        // Instantiate the environmentRelatedList class
        environmentRelatedList controller = new environmentRelatedList(stdController);

        // Call the getenvrs method and assert that it returns the correct data
        Test.startTest();
        List<INFEnvironmentalData__c> envRecords = controller.getenvrs();
        Test.stopTest();

        System.assertNotEquals(null, envRecords, 'The getenvrs method should return a list of records.');
        System.assertEquals(2, envRecords.size(), 'The getenvrs method should return 2 records.');
    }

    @isTest
    static void testGetEnvrsWithoutAccountId() {
        // Create a Case without an AccountId
        Case caseWithoutAccount = new Case(
            Subject = 'Case Without Account'
        );
        insert caseWithoutAccount;

        // Create a StandardController instance for the Case without an AccountId
        ApexPages.StandardController stdController = new ApexPages.StandardController(caseWithoutAccount);

        // Instantiate the environmentRelatedList class
        environmentRelatedList controller = new environmentRelatedList(stdController);

        // Call the getenvrs method and assert that it returns null
        Test.startTest();
        List<INFEnvironmentalData__c> envRecords = controller.getenvrs();
        Test.stopTest();

        System.assertEquals(null, envRecords, 'The getenvrs method should return null when there is no AccountId.');
    }

    @isTest
    static void testOpenPage() {
        // Retrieve the test Case created in the setup
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Create a StandardController instance for the Case
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);

        // Instantiate the environmentRelatedList class
        environmentRelatedList controller = new environmentRelatedList(stdController);

        // Call the openPage method and assert that it returns the correct PageReference
        Test.startTest();
        PageReference pageRef = controller.openPage();
        Test.stopTest();

        System.assertNotEquals(null, pageRef, 'The openPage method should return a PageReference.');
        System.assertEquals('/a6O/o', pageRef.getUrl(), 'The openPage method should return the correct URL.');
    }
}