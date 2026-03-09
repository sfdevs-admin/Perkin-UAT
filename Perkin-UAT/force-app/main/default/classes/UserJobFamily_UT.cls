@IsTest
public with sharing class UserJobFamily_UT 
{
    @isTest
    public static void testNewUserOldGroup()
    {
        Group oldGroup; // Temp
        try
        {
            oldGroup = [SELECT Id, Name FROM Group WHERE Name = 'Job Family: Service'];
        }
        catch(Exception e) { }

        if (oldGroup == null)
        {
            oldGroup = new Group();
            oldGroup.Name = 'Job Family: Service';
            insert oldGroup;
        }

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User']; 
        User newUser = new User(alias = 'testies', email = 'testiesMail@yahoo.com',
            emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher', lastName = 'Testofferson',
            localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
            PKI_GBL_Job_Family__c = 'Service', username = 'testiesMail@yahoo.com', communityNickname = 'TestieBoi');

        Test.startTest();
        insert newUser;
        Test.stopTest();

        GroupMember testMember;
        try
        {
            testMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :newUser.Id AND GroupId = :oldGroup.Id];
        }
        catch(Exception e) { }

        System.assertNotEquals(testMember,null);
    }

    @isTest
    public static void testNewUserNewGroup()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User']; 
        User newUser = new User(alias = 'testies', email = 'testiesMail@yahoo.com',
            emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher', lastName = 'Testofferson',
            localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
            PKI_GBL_Job_Family__c = 'Service', username = 'testiesMail@yahoo.com', communityNickname = 'TestieBoi');

        Test.startTest();
        insert newUser;
        Test.stopTest();
        
        Group testGroup;
        try
        {
            testGroup = [SELECT Id FROM Group WHERE Name = 'Job Family: Service'];
        }
        catch(Exception e) { }

        System.assertNotEquals(testGroup,null);

        GroupMember testMember;
        try
        {
            testMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :newUser.Id AND GroupId = :testGroup.Id];
        }
        catch(Exception e) { }

        System.assertNotEquals(testMember,null);
        
    }

    // 9/8/21 Tony - ITSVMX-576 User family class code coverage Issue
    @isTest
    public static void testOldUserNoGroup()
    {
        Group oldGroup = new Group();
        oldGroup.Name = 'Job Family: Sales';
        insert oldGroup;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User oldUser = new User(alias = 'testies', email = 'testiesMail@yahoo.com',
                emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher', lastName = 'Testofferson',
                localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
                PKI_GBL_Job_Family__c = 'Sales', username = 'testiesMail@yahoo.com', communityNickname = 'TestieBoi');
        insert oldUser;

        oldUser.PKI_GBL_Job_Family__c = null;

        Test.startTest();
        update oldUser;
        Test.stopTest();

        Group newGroup;
        try
        {
            newGroup = [SELECT Id FROM Group WHERE Name = 'Job Family: Service'];
        }
        catch(Exception e) { }

        System.assertNotEquals(newGroup,null);

        GroupMember newMember;
        try
        {
            newMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :oldUser.Id AND GroupId = :newGroup.Id];
        }
        catch(Exception e) { }

        System.assertEquals(newMember,null);

        GroupMember oldMember;
        try
        {
            oldMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :oldUser.Id AND GroupId = :oldGroup.Id];
        }
        catch(Exception e) { }

        System.assertEquals(oldMember,null);
    }

    @isTest
    public static void testOldUserNewGroup()
    {
        Group oldGroup = new Group();
        oldGroup.Name = 'Job Family: Sales';
        insert oldGroup;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User']; 
        User oldUser = new User(alias = 'testies', email = 'testiesMail@yahoo.com',
            emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher', lastName = 'Testofferson',
            localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
            PKI_GBL_Job_Family__c = 'Sales', username = 'testiesMail@yahoo.com', communityNickname = 'TestieBoi');
        insert oldUser;

        oldUser.PKI_GBL_Job_Family__c = 'Service';

        Test.startTest();
        update oldUser;
        Test.stopTest();
        
        Group newGroup;
        try
        {
            newGroup = [SELECT Id FROM Group WHERE Name = 'Job Family: Service'];
        }
        catch(Exception e) { }

        System.assertNotEquals(newGroup,null);

        GroupMember newMember;
        try
        {
            newMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :oldUser.Id AND GroupId = :newGroup.Id];
        }
        catch(Exception e) { }

        System.assertNotEquals(newMember,null);

        GroupMember oldMember;
        try
        {
            oldMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :oldUser.Id AND GroupId = :oldGroup.Id];
        }
        catch(Exception e) { }      

        System.assertEquals(oldMember,null);
    }

    @isTest
    public static void testMultipleUsers()
    {
        Group oldGroup = new Group();
        oldGroup.Name = 'Job Family: Sales';
        insert oldGroup;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User']; 
        User oldUser = new User(alias = 'testies', email = 'testies1Mail@yahoo.com',
            emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher1', lastName = 'Testofferson1',
            localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
            PKI_GBL_Job_Family__c = 'Sales', username = 'testiesMail1@yahoo.com', communityNickname = 'TestieBoi1');
        User newUser = new User(alias = 'testies', email = 'testiesMail2@yahoo.com',
            emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher2', lastName = 'Testofferson2',
            localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
            PKI_GBL_Job_Family__c = 'Service', username = 'testiesMail2@yahoo.com', communityNickname = 'TestieBoi2');
        User regularUser = new User(alias = 'testies', email = 'testiesMail3@yahoo.com',
            emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher3', lastName = 'Testofferson3',
            localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
            PKI_GBL_Job_Family__c = 'Sales', username = 'testiesMail3@yahoo.com', communityNickname = 'TestieBoi3');
        insert new List<User> { oldUser, regularUser };

        oldUser.PKI_GBL_Job_Family__c = 'Service';

        Test.startTest();
        update oldUser;
        insert newUser;
        Test.stopTest();
        
        Group newGroup;
        try
        {
            newGroup = [SELECT Id FROM Group WHERE Name = 'Job Family: Service'];
        }
        catch(Exception e) { }

        System.assertNotEquals(newGroup,null);

        GroupMember newMember;
        try
        {
            newMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :oldUser.Id AND GroupId = :newGroup.Id];
        }
        catch(Exception e) { }

        System.assertNotEquals(newMember,null);

        GroupMember oldMember;
        try
        {
            oldMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :oldUser.Id AND GroupId = :oldGroup.Id];
        }
        catch(Exception e) { }      

        System.assertEquals(oldMember,null);

        GroupMember testMember;
        try
        {
            testMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :newUser.Id AND GroupId = :newGroup.Id];
        }
        catch(Exception e) { }

        System.assertNotEquals(testMember,null);

        GroupMember regularMember;
        try
        {
            regularMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :regularUser.Id];// AND GroupId = :oldGroup.Id];
        }
        catch(Exception e) { }  

        System.assertNotEquals(regularMember,null);
    }

    @isTest
    public static void testJobFamilyBatch()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User']; 
        User oldUser = new User(alias = 'testies', email = 'testies1Mail@yahoo.com',
            emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher1', lastName = 'Testofferson1',
            localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
            PKI_GBL_Job_Family__c = 'Sales', username = 'testiesMail1@yahoo.com', communityNickname = 'TestieBoi1');
        User newUser = new User(alias = 'testies', email = 'testiesMail2@yahoo.com',
            emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher2', lastName = 'Testofferson2',
            localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
            PKI_GBL_Job_Family__c = 'Service', username = 'testiesMail2@yahoo.com', communityNickname = 'TestieBoi2');
        User regularUser = new User(alias = 'testies', email = 'testiesMail3@yahoo.com',
            emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher3', lastName = 'Testofferson3',
            localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
            PKI_GBL_Job_Family__c = 'Sales', username = 'testiesMail3@yahoo.com', communityNickname = 'TestieBoi3');
        insert new List<User> { oldUser, regularUser, newUser };

        //Group oldGroup = [SELECT Id FROM Group WHERE Name = 'Job Family: Sales'];
        //Group newGroup = [SELECT Id FROM Group WHERE Name = 'Job Family: Service'];
        //GroupMember newMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :newUser.Id AND GroupId = :newGroup.Id];
        //Delete newMember;
        //Delete newGroup;

        Test.startTest();
        UserJobFamily_Batch batchable = new UserJobFamily_Batch();
        Database.executeBatch(batchable);
        Test.stopTest();

        //try
        //{
        //    newGroup = [SELECT Id FROM Group WHERE Name = 'Job Family: Service'];
        //}
        //catch(Exception e) { }

        //System.assertNotEquals(newGroup,null);

        //try
        //{
        //    newMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :newUser.Id AND GroupId = :newGroup.Id];
        //}
        //catch(Exception e) { }

        //System.assertNotEquals(newMember,null);

        //GroupMember oldMember;
        //try
        //{
        //    oldMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :oldUser.Id AND GroupId = :oldGroup.Id];
        //}
        //catch(Exception e) { }      

        //System.assertNotEquals(oldMember,null);

        //GroupMember regularMember;
        //try
        //{
        //    regularMember = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :regularUser.Id AND GroupId = :oldGroup.Id];
        //}
        //catch(Exception e) { }

        //System.assertNotEquals(regularMember,null);
    }
}