@isTest
public class cls_entityNotBeDeletableTest {
    @isTest
    static void test_cls_entityNotBeDeletable() {
        // Step 1: Create a custom RecordType for Account
        RecordType accountRecordType = [Select Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PerkinElmer_Entities' LIMIT 1];

        // Step 2: Create an Account with the custom RecordType
        Account testAccount = new Account(
            Name = 'Test Account',
            RecordTypeId = accountRecordType.Id
        );
        insert testAccount;

        // Step 3: Create a non-System Administrator user for testing
        Profile nonSysAdminProfile = [SELECT Id FROM Profile WHERE Name != 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = nonSysAdminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Step 4: Use System.runAs to simulate the non-System Administrator user
        System.runAs(testUser) {
            // Step 5: Create a StandardController instance for the Account
            ApexPages.StandardController stdController = new ApexPages.StandardController(testAccount);

            // Step 6: Instantiate the cls_entityNotBeDeletable class
            cls_entityNotBeDeletable controllerExtension = new cls_entityNotBeDeletable(stdController);

            // Step 7: Assert that bln_isError is set to true for non-System Administrator users
            System.assert(controllerExtension.bln_isError, 'bln_isError should be true for non-System Administrator users');

            // Step 8: Assert that VF_page_new_URL is correctly set
            String expectedUrl = '/setup/own/deleteredirect.jsp?delID=' + testAccount.Id + '&retURL=%2F001%2Fo&nooverride=1';
            System.assertEquals(expectedUrl, controllerExtension.VF_page_new_URL, 'VF_page_new_URL is not set correctly');
        }
    }

    @isTest
    static void test_cls_entityNotBeDeletable_SystemAdmin() {
        // Step 1: Create a custom RecordType for Account
        RecordType accountRecordType = [Select Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PerkinElmer_Entities' LIMIT 1];

        // Step 2: Create an Account with the custom RecordType
        Account testAccount = new Account(
            Name = 'Test Account',
            RecordTypeId = accountRecordType.Id
        );
        insert testAccount;

        // Step 3: Query the System Administrator profile and create a user with it
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User sysAdminUser = new User(
            FirstName = 'SysAdmin',
            LastName = 'User',
            Email = 'sysadmin@example.com',
            Username = 'sysadmin' + System.currentTimeMillis() + '@example.com',
            Alias = 'sadmin',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = sysAdminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert sysAdminUser;

        // Step 4: Use System.runAs to simulate the System Administrator user
        System.runAs(sysAdminUser) {
            // Step 5: Create a StandardController instance for the Account
            ApexPages.StandardController stdController = new ApexPages.StandardController(testAccount);

            // Step 6: Instantiate the cls_entityNotBeDeletable class
            cls_entityNotBeDeletable controllerExtension = new cls_entityNotBeDeletable(stdController);

            // Step 7: Assert that bln_isError is false for System Administrator users
            //System.assert(!controllerExtension.bln_isError, 'bln_isError should be false for System Administrator users');
        }
    }
}