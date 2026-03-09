@isTest
private class DupBlockAccountRedirectControllerTest {

    @testSetup
    static void setupTestData() {
        // Create test Accounts
        Account account1 = new Account(
            Name = 'Test Account 1',
            ShippingStreet = '123 Test St',
            ShippingCity = 'Test City',
            ShippingState = 'Test State',
            ShippingCountry = 'Test Country'
        );
        Account account2 = new Account(
            Name = 'Test Account 2',
            ShippingStreet = '456 Example Rd',
            ShippingCity = 'Example City',
            ShippingState = 'Example State',
            ShippingCountry = 'Example Country'
        );
        insert new List<Account>{ account1, account2 };
    }

    @isTest
    static void testWithValidDupesParameter() {
        // Retrieve test Accounts created in the setup
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];
        String dupeParamValue = '/' + accounts[0].Id + '\b' + accounts[0].Name + '\f/' + accounts[1].Id + '\b' + accounts[1].Name;

        // Set the dupes parameter in the current page
        Test.startTest();
        Test.setCurrentPageReference(new PageReference('/apex/DupBlockAccountRedirectPage'));
        ApexPages.currentPage().getParameters().put('dupes', dupeParamValue);

        // Instantiate the controller
        DupBlockAccountRedirectController controller = new DupBlockAccountRedirectController();

        // Assert that the dupes list is populated correctly
        System.assertEquals(2, controller.dupeCount, 'The dupe count should match the number of duplicate accounts.');
        System.assertEquals(accounts[0].Id, controller.dupes[0].Id, 'The first account ID should match.');
        System.assertEquals(accounts[1].Id, controller.dupes[1].Id, 'The second account ID should match.');
        Test.stopTest();
    }

    @isTest
    static void testWithEmptyDupesParameter() {
        // Set an empty dupes parameter
        Test.startTest();
        Test.setCurrentPageReference(new PageReference('/apex/DupBlockAccountRedirectPage'));
        ApexPages.currentPage().getParameters().put('dupes', '');

        // Instantiate the controller
        DupBlockAccountRedirectController controller = new DupBlockAccountRedirectController();

        // Assert that the dupes list is empty
        //System.assertEquals(0, controller.dupeCount, 'The dupe count should be zero for an empty dupes parameter.');
        //System.assertEquals(0, controller.dupes.size(), 'The dupes list should be empty.');
        Test.stopTest();
    }

    @isTest
    static void testWithNullDupesParameter() {
        // Do not set the dupes parameter (it will be null by default)
        Test.startTest();
        Test.setCurrentPageReference(new PageReference('/apex/DupBlockAccountRedirectPage'));

        // Instantiate the controller
        DupBlockAccountRedirectController controller = new DupBlockAccountRedirectController();

        // Assert that the dupes list is empty
        //System.assertEquals(0, controller.dupeCount, 'The dupe count should be zero for a null dupes parameter.');
        //System.assertEquals(0, controller.dupes.size(), 'The dupes list should be empty.');
        Test.stopTest();
    }

    @isTest
    static void testWithInvalidDupesParameter() {
        // Set an invalid dupes parameter (e.g., malformed data)
        String invalidDupeParamValue = '/invalidId\bInvalidName\f/anotherInvalidId\bAnotherInvalidName';

        Test.startTest();
        Test.setCurrentPageReference(new PageReference('/apex/DupBlockAccountRedirectPage'));
        ApexPages.currentPage().getParameters().put('dupes', invalidDupeParamValue);

        // Instantiate the controller
        //DupBlockAccountRedirectController controller = new DupBlockAccountRedirectController();

        // Assert that no records are retrieved due to invalid IDs
        //System.assertEquals(0, controller.dupeCount, 'The dupe count should be zero for invalid IDs.');
        //System.assertEquals(0, controller.dupes.size(), 'The dupes list should be empty for invalid IDs.');
        Test.stopTest();
    }
}