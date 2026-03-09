@IsTest
private class ContractRenewalUserManagerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test users with unique usernames
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create Active Direct Manager
        User activeManager = new User(
            FirstName = 'Active',
            LastName = 'Manager111',
            Email = 'active.manager@test.com',
            Username = 'active.manager@testcompany' + System.currentTimeMillis() + '.com',
            Alias = 'amgr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true,
            PKITerritory__c = 'NORTH AMERICA'
        );
        insert activeManager;
        
        // Create Inactive Direct Manager
        User inactiveManager = new User(
            FirstName = 'Inactive',
            LastName = 'Manager111',
            Email = 'inactive.manager@test.com',
            Username = 'inactive.manager@testcompany' + System.currentTimeMillis() + '.com',
            Alias = 'imgr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = false,
            PKITerritory__c = 'NORTH AMERICA'
        );
        insert inactiveManager;
    }
    
    // Helper method to get valid picklist values
    private static List<String> getValidTerritories() {
        List<String> territories = new List<String>();
        Schema.DescribeFieldResult fieldResult = User.PKITerritory__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistValues) {
            territories.add(entry.getValue());
        }
        
        return territories;
    }
    
    @IsTest
    static void testActiveUserReturnsActiveUser() {
        // Create active user with territory
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Get a valid territory value
        List<String> validTerritories = getValidTerritories();
        String territory = validTerritories.isEmpty() ? null : validTerritories[0];
        
        User activeUser = new User(
            FirstName = 'Active',
            LastName = 'TestUser111',
            Email = 'active.testuser@test.com',
            Username = 'active.testuser@testcompany' + System.currentTimeMillis() + '.com',
            Alias = 'atest',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true,
            PKITerritory__c = territory
        );
        insert activeUser;

        Test.startTest();
        User testUser = fetchUserById(activeUser.Id);
        Id resultUserId = ContractRenewalUserManager.getSalesRep(testUser.Name, territory);
        Test.stopTest();

        System.assertEquals(activeUser.Id, resultUserId, 'Active user should return their own ID');
    }
    
    @IsTest
    static void testInactiveUserWithActiveDirectManager() {
        User activeManager = [SELECT Id FROM User WHERE FirstName = 'Active' AND LastName = 'Manager111' LIMIT 1];
        String territory = 'NORTH AMERICA';

        // Create inactive user with active direct manager
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User inactiveUser = new User(
            FirstName = 'Inactive',
            LastName = 'TestUser111',
            Email = 'inactive.testuser@test.com',
            Username = 'inactive.testuser@testcompany' + System.currentTimeMillis() + '.com',
            Alias = 'itest',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = false,
            PKITerritory__c = territory,
            Direct_Manager__c = activeManager.Id
        );
        insert inactiveUser;
        
        Test.startTest();
        User testUser = fetchUserById(inactiveUser.Id);
        Id resultUserId = ContractRenewalUserManager.getSalesRep(testUser.Name, territory);
        Test.stopTest();

        System.assertEquals(activeManager.Id, resultUserId,
            'Inactive user with active manager should return manager ID');
    }
    
    @IsTest
    static void testInactiveUserWithInactiveDirectManager() {
        User inactiveManager = [SELECT Id FROM User WHERE FirstName = 'Inactive' AND LastName = 'Manager111' LIMIT 1];
        String territory = 'NORTH AMERICA';

        // Create inactive user with inactive direct manager
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User inactiveUser = new User(
            FirstName = 'Inactive2',
            LastName = 'TestUser',
            Email = 'inactive2.testuser@test.com',
            Username = 'inactive2.testuser@testcompany' + System.currentTimeMillis() + '.com',
            Alias = 'itest2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = false,
            PKITerritory__c = territory,
            Direct_Manager__c = inactiveManager.Id
        );
        insert inactiveUser;
        
        Test.startTest();
        User testUser = fetchUserById(inactiveUser.Id);
        Id resultUserId = ContractRenewalUserManager.getSalesRep(testUser.Name, territory);
        Test.stopTest();
        
        // Should fallback to regional director based on territory
        System.assertNotEquals(null, resultUserId, 'Should return a valid user ID');
    }
    
    @IsTest
    static void testInactiveUserNoDirectManager() {
        String territory = 'NORTH AMERICA';

        // Create inactive user without direct manager
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User inactiveUser = new User(
            FirstName = 'Inactive3',
            LastName = 'TestUser',
            Email = 'inactive3.testuser@test.com',
            Username = 'inactive3.testuser@testcompany' + System.currentTimeMillis() + '.com',
            Alias = 'itest3',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = false,
            PKITerritory__c = territory
        );
        insert inactiveUser;
        
        Test.startTest();
        User testUser = fetchUserById(inactiveUser.Id);
        Id resultUserId = ContractRenewalUserManager.getSalesRep(testUser.Name, territory);
        Test.stopTest();
        
        // Should fallback to regional director based on territory
        System.assertNotEquals(null, resultUserId, 'Should return a valid user ID');
    }
    
    @IsTest
    static void testNullUserId() {
        Test.startTest();
        Id resultUserId = ContractRenewalUserManager.getSalesRep(null, null);
        Test.stopTest();
        
        // Should return current user as fallback
        System.assertEquals(UserInfo.getUserId(), resultUserId, 
            'Null userId should return current user');
    }
    
    @IsTest
    static void testUserWithEmptyTerritory() {
        String territory = 'GREATER CHINA';

        // Create user with empty territory
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User userNoTerritory = new User(
            FirstName = 'NoTerritory',
            LastName = 'TestUser',
            Email = 'noterr.testuser@test.com',
            Username = 'noterr.testuser@testcompany' + System.currentTimeMillis() + '.com',
            Alias = 'nterr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = false
            // PKITerritory__c intentionally left null
        );
        insert userNoTerritory;
        
        Test.startTest();
        User testUser = fetchUserById(userNoTerritory.Id);
        Id resultUserId = ContractRenewalUserManager.getSalesRep(testUser.Name, territory);
        Test.stopTest();
        
        // Should return current user as fallback
        System.assertNotEquals(null, resultUserId, 'Should return a valid user ID');
    }
    
    @IsTest
    static void testUserWithNonMatchingMetadata() {
        // Get a valid territory that likely doesn't have metadata
        List<String> validTerritories = getValidTerritories();
        String territory = null;
        
        // Try to find a territory that's not in our metadata setup
        List<String> metadataTerritories = new List<String>{
            'NORTH AMERICA', 'LATIN AMERICA', 'GREATER CHINA', 'KOSJ', 
            'GREATER INDIA', 'BNL AND NORDICS', 'DACH AND POLAND', 
            'GREATER FRANCE', 'ITALY AND IBERIA', 'UKI'
        };
        
        for (String validTerritory : validTerritories) {
            if (!metadataTerritories.contains(validTerritory)) {
                territory = validTerritory;
                break;
            }
        }
        
        // If all territories match metadata, use one from metadata
        if (territory == null && !validTerritories.isEmpty()) {
            territory = validTerritories[0];
        }
        
        // Create user with territory that might not match metadata
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User userNonMatchingTerritory = new User(
            FirstName = 'NonMatching',
            LastName = 'Territory111',
            Email = 'nonmatching.territory@test.com',
            Username = 'nonmatching.territory@testcompany' + System.currentTimeMillis() + '.com',
            Alias = 'nmatch',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = false,
            PKITerritory__c = territory
        );
        insert userNonMatchingTerritory;
        
        Test.startTest();
        User testUser = fetchUserById(userNonMatchingTerritory.Id);
        Id resultUserId = ContractRenewalUserManager.getSalesRep(testUser.Name, null);
        Test.stopTest();
        
        // Should return current user as fallback when metadata doesn't match
        System.assertNotEquals(null, resultUserId, 'Should return a valid user ID');
    }
    
    static User fetchUserById(Id userId) {
        List<User> users = [
            SELECT Id, Name, IsActive, Direct_Manager__c, PKITerritory__c
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];
        return (users.isEmpty()) ? null : users[0];
    }

    static Renewal_Service_Ownership__mdt fetchRenewalMetadata(String territory) {
        List<Renewal_Service_Ownership__mdt> metadataList = [
            SELECT Regional_Director__c,
                Fx_PKI_Territory__c,
                Final_Point__c,
                Escalation_Point__c
            FROM Renewal_Service_Ownership__mdt
            WHERE Fx_PKI_Territory__c = :territory
            LIMIT 1
        ];
        return (metadataList.isEmpty()) ? null : metadataList[0];
    }

}