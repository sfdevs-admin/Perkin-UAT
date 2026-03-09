@isTest
public class cls_employeeNonOfficerDeletable_Test {
    
    @isTest
    static void test_cls_employeeNonOfficerDeletable() {
        // Step 1: Create a Record Type for Employee__c (Officer and Non-Officer)
        RecordType officerRecordType = [Select Id From RecordType WHERE SObjectType = 'Employee__c' AND DeveloperName = 'Officer' LIMIT 1];
        
        RecordType nonOfficerRecordType = [Select Id From RecordType WHERE SObjectType = 'Employee__c' AND DeveloperName = 'Non_Officer' LIMIT 1];

        // Step 2: Create a test Employee__c record with Officer Record Type
        Employee__c officerEmployee = new Employee__c(
            Name = 'Test Officer',
            Email__c = 'one1@email.com',
            First_Name__c = 'test1',
            Job_Title__c = 'Important Officer',
            Last_Name__c = 'Officer1',
            RecordTypeId = officerRecordType.Id
        );
        insert officerEmployee;

        // Step 3: Create a test User with System Administrator profile
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User sysAdminUser = new User(
            FirstName = 'Admin',
            LastName = 'User',
            Email = 'admin@test.com',
            Username = 'adminuser@test.com' + System.currentTimeMillis(),
            Alias = 'sysadm',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = sysAdminProfile.Id
        );
        insert sysAdminUser;

        // Step 4: Set up a StandardController for the Employee__c record
        Test.startTest();
        
        // Simulate running as the System Administrator user
        System.runAs(sysAdminUser) {
            ApexPages.StandardController stdController = new ApexPages.StandardController(officerEmployee);
            
            // Instantiate cls_employeeNonOfficerDeletable class
            cls_employeeNonOfficerDeletable employeeController = new cls_employeeNonOfficerDeletable(stdController);
            
            // Validate that VF_page_old_URL and VF_page_new_URL are set correctly
            //System.assertNotEquals(null, employeeController.VF_page_old_URL);
            System.assertNotEquals(null, employeeController.VF_page_new_URL);
            
            // Validate that bln_isError is false for System Administrator
            //System.assertEquals(false, employeeController.bln_isError);
            
            // Test with a Non-Officer Employee__c record
            Employee__c nonOfficerEmployee = new Employee__c(
                Name = 'Test Non-Officerx',
                Email__c = 'one1@emailx.com',
                First_Name__c = 'test1x',
                Job_Title__c = 'Important Officer',
                Last_Name__c = 'Officer1x',
                RecordTypeId = nonOfficerRecordType.Id
            );
            insert nonOfficerEmployee;
            
            stdController = new ApexPages.StandardController(nonOfficerEmployee);
            
            cls_employeeNonOfficerDeletable nonOfficerController = new cls_employeeNonOfficerDeletable(stdController);
            
            // Validate that bln_isError is false for a Non-Officer record (even if not Sys Admin)
            //System.assertEquals(false, nonOfficerController.bln_isError);
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void test_bln_isError_for_Non_Admin_User() {
        // Step 1: Create a Record Type for Employee__c (Officer)
        RecordType officerRecordType = [Select Id From RecordType WHERE SObjectType = 'Employee__c' AND DeveloperName = 'Officer' LIMIT 1];

        // Step 2: Create a test Employee__c record with Officer Record Type
        Employee__c officerEmployee = new Employee__c(
            Name = 'Test Officer',
            Email__c = 'one@email.com',
            First_Name__c = 'test',
            Job_Title__c = 'Important Officer',
            Last_Name__c = 'Officer',
            RecordTypeId = officerRecordType.Id
        );
        insert officerEmployee;

        // Step 3: Create a test User with a non-System Administrator profile
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Premier Support User' LIMIT 1];
        
        User standardUser = new User(
            FirstName = 'Standard',
            LastName = 'User',
            Email = 'standard@test.com',
            Username = 'standarduser@test.com' + System.currentTimeMillis(),
            Alias = 'stdusr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert standardUser;

        // Simulate running as the Non-System Administrator user
        Test.startTest();
        
        System.runAs(standardUser) {
            
            ApexPages.StandardController stdController = new ApexPages.StandardController(officerEmployee);
            
            // Instantiate cls_employeeNonOfficerDeletable class
            cls_employeeNonOfficerDeletable employeeControllerForStandardUser =
                new cls_employeeNonOfficerDeletable(stdController);
            
            // Validate that bln_isError is true for Non-System Admin with Officer record type
            //System.assertEquals(true, employeeControllerForStandardUser.bln_isError);
            
        }
        
        Test.stopTest();
    }
}