@isTest
private class Test_crtl_InlineAccountTeamMemberPage{
    @isTest private static void testClass(){
        Account testaccount = new Account(name='test account');
        insert testaccount ;
        
        Case testCase = new Case(
            AccountId = testAccount.Id,
            Status = 'New',
            Priority = 'High',
            Subject = 'Test Case for Account'
        );
        insert testCase;
        
        User testUser = new User(
            Username = 'testuser65465465465465465@test.com',
            LastName = 'Smith',
            Email = 'testuser@test.com',
            Alias = 'tuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserPermissionsKnowledgeUser = true
        );
        insert testUser;
        
        AccountTeamMember atm = new AccountTeamMember(
            AccountId = testAccount.Id,
            UserId = testUser.Id,
            TeamMemberRole = 'Member'
        );
        insert atm;
        
        AccountTeamMember atm2 = new AccountTeamMember(
            AccountId = testAccount.Id,
            UserId = UserInfo.getuserId(),
            TeamMemberRole = 'Member'
        );
        insert atm2;
        
        AccountShare accountShare = new AccountShare(
            AccountId = testAccount.Id,
            UserOrGroupId = testUser.Id,
            CaseAccessLevel = 'Read',
            AccountAccessLevel = 'Read',
            OpportunityAccessLevel = 'Read'
        );
        insert accountShare;
        
        ApexPages.StandardController sc = new ApexPages.standardController(testaccount);
        crtl_InlineAccountTeamMemberPage controllerclass=new crtl_InlineAccountTeamMemberPage(sc);
        crtl_InlineAccountTeamMemberPage.addMembership(testaccount.id, 'Sales Manager');
        
        System.runAs(testUser) {
        crtl_InlineAccountTeamMemberPage.changeMembershipRole(testaccount.id,'Account Manager'); 
        crtl_InlineAccountTeamMemberPage.removeMembership(testaccount.id);
  
        controllerclass=new crtl_InlineAccountTeamMemberPage(sc);
        crtl_InlineAccountTeamMemberPage.addMembership(testaccount.id, 'Sales Manager');
        List<SelectOption> opts = controllerclass.getalloptions();
             
        }
    }
}